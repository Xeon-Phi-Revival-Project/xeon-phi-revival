#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-eglibc-linked-smoke-payloads.sh \
    --eglibc-build DIR \
    --eglibc-prefix DIR \
    --source-dir DIR \
    --payload-rootfs DIR \
    --zlib-build DIR \
    --ncurses-build DIR \
    [--sysroot DIR]

Rebuild hello-knc, zlib-smoke, and ncurses-smoke so they request the runtime
loader path used by the K1OM bootstrap packages:

  /opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2

The payload rootfs is modified in place. It should be a private staging copy,
not a stock uOS tree.
USAGE
}

eglibc_build=""
eglibc_prefix=""
source_dir=""
payload_rootfs=""
zlib_build=""
ncurses_build=""
sysroot="${K1OM_SYSROOT:-/opt/mpss/3.4.10/sysroots/k1om-mpss-linux}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --eglibc-build) eglibc_build="${2:-}"; shift 2 ;;
    --eglibc-prefix) eglibc_prefix="${2:-}"; shift 2 ;;
    --source-dir) source_dir="${2:-}"; shift 2 ;;
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --zlib-build) zlib_build="${2:-}"; shift 2 ;;
    --ncurses-build) ncurses_build="${2:-}"; shift 2 ;;
    --sysroot) sysroot="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

for value in "$eglibc_build" "$eglibc_prefix" "$source_dir" "$payload_rootfs" "$zlib_build" "$ncurses_build" "$sysroot"; do
  [[ -n "$value" ]] || { usage; exit 2; }
done

for path in \
  "$eglibc_build/csu/crt1.o" \
  "$eglibc_build/csu/crti.o" \
  "$eglibc_build/csu/crtn.o" \
  "$eglibc_build/libc.so.6" \
  "$eglibc_build/libc_nonshared.a" \
  "$eglibc_build/elf/ld.so" \
  "$eglibc_prefix/include/stdio.h" \
  "$source_dir/hello-knc.c" \
  "$source_dir/zlib-smoke-test.c" \
  "$source_dir/ncurses-smoke-test.c" \
  "$zlib_build/zlib.h" \
  "$zlib_build/libz.a" \
  "$ncurses_build/include/curses.h" \
  "$ncurses_build/lib/libncursesw.a" \
  "$ncurses_build/lib/libtinfow.a"; do
  [[ -e "$path" || -L "$path" ]] || { echo "required path missing: $path" >&2; exit 10; }
done

command -v k1om-mpss-linux-gcc >/dev/null 2>&1 || {
  echo "k1om-mpss-linux-gcc is not in PATH; source the MPSS SDK environment first" >&2
  exit 11
}

build_dir="${payload_rootfs%/}/../eglibc-linked-build"
mkdir -p "$build_dir" "$payload_rootfs/usr/bin"

crtbegin="$(k1om-mpss-linux-gcc --print-file-name=crtbegin.o)"
crtend="$(k1om-mpss-linux-gcc --print-file-name=crtend.o)"

compile_common=(
  -std=gnu99
  -O2
  -g
  --sysroot="$sysroot"
  -isystem "$eglibc_prefix/include"
)

link_common=(
  -nostdlib
  -nostartfiles
  --sysroot="$sysroot"
)

link_tail=(
  -Wl,-dynamic-linker=/opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2
  -Wl,-rpath,/opt/xeon-phi-revival/lib64
  -Wl,-rpath-link,"$eglibc_build:$eglibc_build/math:$eglibc_build/nptl:$eglibc_build/dlfcn:$eglibc_build/rt:$eglibc_build/login"
  -Wl,--start-group
  "$eglibc_build/libc.so.6"
  "$eglibc_build/libc_nonshared.a"
  -Wl,--as-needed
  "$eglibc_build/elf/ld.so"
  -Wl,--no-as-needed
  -Wl,--end-group
  -lgcc
  "$crtend"
  "$eglibc_build/csu/crtn.o"
)

link_binary() {
  local out="$1"
  shift
  k1om-mpss-linux-gcc "${link_common[@]}" -o "$out" \
    "$eglibc_build/csu/crt1.o" \
    "$eglibc_build/csu/crti.o" \
    "$crtbegin" \
    "$@" \
    "${link_tail[@]}"
}

k1om-mpss-linux-gcc "${compile_common[@]}" \
  -c "$source_dir/hello-knc.c" \
  -o "$build_dir/hello-knc.o"
link_binary "$build_dir/hello-knc" "$build_dir/hello-knc.o"
install -m 0755 "$build_dir/hello-knc" "$payload_rootfs/usr/bin/hello-knc"

k1om-mpss-linux-gcc "${compile_common[@]}" -I "$zlib_build" \
  -c "$source_dir/zlib-smoke-test.c" \
  -o "$build_dir/zlib-smoke.o"
link_binary "$build_dir/zlib-smoke" "$build_dir/zlib-smoke.o" "$zlib_build/libz.a"
install -m 0755 "$build_dir/zlib-smoke" "$payload_rootfs/usr/bin/zlib-smoke"

k1om-mpss-linux-gcc "${compile_common[@]}" \
  -I "$ncurses_build/include" \
  -I "$ncurses_build/ncurses" \
  -c "$source_dir/ncurses-smoke-test.c" \
  -o "$build_dir/ncurses-smoke.o"
link_binary "$build_dir/ncurses-smoke" \
  "$build_dir/ncurses-smoke.o" \
  "$ncurses_build/lib/libncursesw.a" \
  "$ncurses_build/lib/libtinfow.a"
install -m 0755 "$build_dir/ncurses-smoke" "$payload_rootfs/usr/bin/ncurses-smoke"

for bin in hello-knc zlib-smoke ncurses-smoke; do
  readelf -h "$payload_rootfs/usr/bin/$bin" | grep -q 'Machine:.*Intel K1OM'
  readelf -l "$payload_rootfs/usr/bin/$bin" | grep -q '/opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2'
  file "$payload_rootfs/usr/bin/$bin"
done
