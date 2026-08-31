#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: build-k1om-dropbear.sh --source-dir DIR --out FILE [--cross-compile PREFIX] [--link-mode static|dynamic] [--runtime-prefix DIR] [--work-root DIR]

Build a static K1OM Dropbear server from a locally supplied upstream source
tree. The source tree and output remain outside the repository.
USAGE
}

source_dir=""
out=""
work_root="${HOME}/xeon-phi-revival-local/dropbear-builds"
link_mode="static"
runtime_prefix=""
cross_compile="k1om-mpss-linux-"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir) source_dir="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    --cross-compile) cross_compile="${2:-}"; shift 2 ;;
    --link-mode) link_mode="${2:-}"; shift 2 ;;
    --runtime-prefix) runtime_prefix="${2:-}"; shift 2 ;;
    --work-root) work_root="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

[[ -f "$source_dir/configure" && -n "$out" ]] || { usage; exit 2; }
[[ "$link_mode" == static || "$link_mode" == dynamic ]] || { echo "invalid link mode: $link_mode" >&2; exit 3; }
if [[ -n "$runtime_prefix" ]]; then
  [[ "$link_mode" == dynamic && -f "$runtime_prefix/include/stdio.h" && -f "$runtime_prefix/lib64/crt1.o" && -f "$runtime_prefix/lib/ld-2.19.so" ]] || {
    echo "runtime prefix must provide include/, lib64/crt1.o, and lib/ld-2.19.so for a dynamic build" >&2
    exit 4
  }
fi
if ! command -v "${cross_compile}gcc" >/dev/null 2>&1 && [[ "$cross_compile" == "k1om-mpss-linux-" && -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
fi
command -v "${cross_compile}gcc" >/dev/null 2>&1 || { echo "K1OM compiler unavailable" >&2; exit 10; }

run_dir="$work_root/dropbear-$(date -u +%Y%m%d-%H%M%S)"
build_dir="$run_dir/source"
mkdir -p "$run_dir" "$(dirname "$out")"
cp -a "$source_dir" "$build_dir"
(
  cd "$build_dir"
  make distclean > /dev/null 2>&1 || true
  configure_args=(--host=k1om-mpss-linux)
  [[ "$link_mode" == static ]] && configure_args+=(--enable-static)
  configure_cflags=""
  configure_ldflags=""
  if [[ "$link_mode" == dynamic ]]; then
    configure_cflags="-fPIC"
    # The project runtime is intentionally self-contained under /lib64.
    configure_ldflags="-Wl,-rpath,/lib64"
    if [[ -n "$runtime_prefix" ]]; then
      configure_cflags+=" -isystem $runtime_prefix/include"
      configure_ldflags+=" -B$runtime_prefix/lib64 -L$runtime_prefix/lib -Wl,--dynamic-linker,/lib64/ld-linux-k1om.so.2"
    fi
  fi
  CC="${cross_compile}gcc" CFLAGS="$configure_cflags" LDFLAGS="$configure_ldflags" ./configure "${configure_args[@]}" \
    --disable-zlib --disable-syslog --disable-utmp --disable-utmpx \
    --disable-wtmp --disable-wtmpx --disable-pututline --disable-pututxline \
    --disable-lastlog --disable-loginfunc > "$run_dir/configure.log" 2>&1
  make PROGRAMS=dropbear -j2 > "$run_dir/build.log" 2>&1
)
"${cross_compile}readelf" -h "$build_dir/dropbear" | grep -q 'Machine:.*Intel K1OM' || { echo "Dropbear is not K1OM" >&2; exit 11; }
if [[ "$link_mode" == static ]]; then
  "${cross_compile}readelf" -d "$build_dir/dropbear" 2>/dev/null | grep -q NEEDED && { echo "Dropbear is not static" >&2; exit 12; } || true
else
  "${cross_compile}readelf" -d "$build_dir/dropbear" 2>/dev/null | grep -q 'Shared library: \[libc.so.6\]' || { echo "dynamic Dropbear is missing libc dependency" >&2; exit 13; }
  "${cross_compile}readelf" -d "$build_dir/dropbear" 2>/dev/null | grep -Eq '(RPATH|RUNPATH).*\[/lib64\]' || { echo "dynamic Dropbear is missing /lib64 runtime path" >&2; exit 14; }
  if [[ -n "$runtime_prefix" ]]; then
    "${cross_compile}readelf" --version-info "$build_dir/dropbear" 2>/dev/null | grep -q 'GLIBC_2.14' && { echo "Dropbear still depends on SDK GLIBC_2.14" >&2; exit 15; }
  fi
fi
cp -a "$build_dir/dropbear" "$out"
sha256sum "$out" > "$run_dir/SHA256SUMS"
printf 'dropbear=%s\nsha256=%s\nlink_mode=%s\n' "$out" "$(awk '{print $1}' "$run_dir/SHA256SUMS")" "$link_mode"
