#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-apt-k1om-bridge.sh \
    --apt-source-dir DIR \
    --zlib-source-dir DIR \
    --config-aux-dir DIR \
    --patch FILE \
    --out-dir DIR

Build the file-repository compatibility bridge from Ubuntu APT
1.0.1ubuntu2.24 and Ubuntu Noble zlib for K1OM. The caller must supply
verified source trees and config.sub/config.guess files. The script does not
download, install, deploy, or execute target binaries.
USAGE
}

apt_source=""
zlib_source=""
config_aux=""
patch_file=""
out_dir=""
toolchain_root="${K1OM_TOOLCHAIN_ROOT:-/opt/mpss/3.4.10}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apt-source-dir) apt_source="${2:-}"; shift 2 ;;
    --zlib-source-dir) zlib_source="${2:-}"; shift 2 ;;
    --config-aux-dir) config_aux="${2:-}"; shift 2 ;;
    --patch) patch_file="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -d "$apt_source" && -x "$apt_source/configure" ]] || { usage; exit 2; }
[[ -d "$zlib_source" && -x "$zlib_source/configure" ]] || { usage; exit 2; }
[[ -f "$config_aux/config.sub" && -f "$config_aux/config.guess" ]] || {
  usage
  exit 2
}
[[ -f "$patch_file" && -n "$out_dir" ]] || { usage; exit 2; }

tool_bin="$toolchain_root/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux"
cc="$tool_bin/k1om-mpss-linux-gcc"
cxx="$tool_bin/k1om-mpss-linux-g++"
readelf="$tool_bin/k1om-mpss-linux-readelf"
[[ -x "$cc" && -x "$cxx" && -x "$readelf" ]] || {
  echo "MPSS K1OM toolchain not found under $toolchain_root" >&2
  exit 3
}

rm -rf "$out_dir"
mkdir -p "$out_dir/source" "$out_dir/build" "$out_dir/prefix" \
  "$out_dir/stage" "$out_dir/host-bin"
apt_work="$out_dir/source/apt"
zlib_work="$out_dir/source/zlib"
(cd "$apt_source" && tar -cf - .) |
  (mkdir -p "$apt_work" && cd "$apt_work" && tar -xf -)
(cd "$zlib_source" && tar -cf - .) |
  (mkdir -p "$zlib_work" && cd "$zlib_work" && tar -xf -)

cp -a "$config_aux/config.sub" "$apt_work/buildlib/config.sub"
cp -a "$config_aux/config.guess" "$apt_work/buildlib/config.guess"
(cd "$apt_work" && patch -p1 < "$patch_file")

cat > "$out_dir/host-bin/dpkg-architecture" <<'HOST_ARCH'
#!/bin/sh
echo k1om
HOST_ARCH
cat > "$out_dir/host-bin/dpkg-vendor" <<'HOST_VENDOR'
#!/bin/sh
case "$*" in
  *Vendor*) echo Ubuntu ;;
  *) exit 1 ;;
esac
HOST_VENDOR
chmod 0755 "$out_dir/host-bin/dpkg-architecture" \
  "$out_dir/host-bin/dpkg-vendor"

export PATH="$out_dir/host-bin:$tool_bin:$PATH"

zlib_prefix="$out_dir/prefix/zlib"
mkdir -p "$out_dir/build/zlib"
(
  cd "$out_dir/build/zlib"
  CC=k1om-mpss-linux-gcc \
  AR=k1om-mpss-linux-ar \
  RANLIB=k1om-mpss-linux-ranlib \
    "$zlib_work/configure" --static --prefix="$zlib_prefix"
  make -j"${JOBS:-2}" \
    CFLAGS="-O3 -fPIC -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN"
  make install
)

if readelf -r "$zlib_prefix/lib/libz.a" | grep -q 'R_X86_64_32 '; then
  echo "zlib archive contains non-PIC relocations" >&2
  exit 4
fi

apt_prefix="/opt/xeon-phi-revival/apt-real"
mkdir -p "$out_dir/build/apt"
(
  cd "$out_dir/build/apt"
  CC=k1om-mpss-linux-gcc \
  CXX=k1om-mpss-linux-g++ \
  AR=k1om-mpss-linux-ar \
  RANLIB=k1om-mpss-linux-ranlib \
  CXXFLAGS="-O2 -std=gnu++0x" \
  CPPFLAGS="-I$zlib_prefix/include" \
  LDFLAGS="-L$zlib_prefix/lib" \
  LIBS="-lz" \
    "$apt_work/configure" \
      --build=x86_64-redhat-linux-gnu \
      --host=x86_64-k1om-linux-gnu \
      --prefix="$apt_prefix" \
      --without-libiconv-prefix \
      --without-libintl-prefix
  make -j"${JOBS:-2}"
)

build_bin="$out_dir/build/apt/bin"
stage_root="$out_dir/stage$apt_prefix"
mkdir -p "$stage_root/bin" "$stage_root/lib/apt/methods" \
  "$stage_root/lib/apt/solvers" "$stage_root/etc/apt/apt.conf.d" \
  "$stage_root/etc/apt/preferences.d" "$stage_root/etc/apt/sources.list.d" \
  "$stage_root/var/lib/apt/lists/partial" \
  "$stage_root/var/cache/apt/archives/partial" "$stage_root/var/log/apt"

for name in apt apt-cache apt-config apt-get apt-mark; do
  cp -a "$build_bin/$name" "$stage_root/bin/"
done
cp -a "$build_bin"/libapt-pkg.so* "$build_bin"/libapt-inst.so* \
  "$build_bin"/libapt-private.so* "$stage_root/lib/"
for name in copy file gzip gpgv rred; do
  cp -a "$build_bin/methods/$name" "$stage_root/lib/apt/methods/"
done
cp -a "$build_bin/apt-internal-solver" \
  "$stage_root/lib/apt/solvers/internal"

printf '%s\n' 'Acquire::Languages "none";' \
  > "$stage_root/etc/apt/apt.conf.d/00xpr-minimal"
printf '%s\n' \
  'deb [trusted=yes arch=k1om] file:/opt/xeon-phi-revival/repo noble main' \
  > "$stage_root/etc/apt/sources.list"

: > "$out_dir/elf-audit.tsv"
while IFS= read -r file; do
  if file -L "$file" | grep -q ELF; then
    "$readelf" -h "$file" | grep -q 'Machine:.*Intel K1OM'
    printf '%s\tIntel K1OM\n' "${file#"$out_dir/stage"}" \
      >> "$out_dir/elf-audit.tsv"
  fi
done < <(find "$stage_root" -type f | sort)

find "$stage_root" -type f -print0 |
  sort -z |
  xargs -0 sha256sum > "$out_dir/sha256sums.txt"

cat > "$out_dir/build-summary.txt" <<EOF
status=passed
architecture=k1om
apt_version=1.0.1ubuntu2.24
zlib_version=1.3
prefix=$apt_prefix
https_method=disabled
supported_repository=file
stage=$out_dir/stage
EOF
cat "$out_dir/build-summary.txt"
