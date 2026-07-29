#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-libffi-k1om.sh --source-dir DIR --patch FILE --out-dir DIR [--prefix DIR]

Build libffi 3.4.6 for K1OM from a separately obtained source tree. The script
does not download source or Intel tools. It expects the MPSS cross environment
to be installed locally.
USAGE
}

source_dir=""
patch_file=""
out_dir=""
prefix=""
toolchain_env="${K1OM_TOOLCHAIN_ENV:-/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir) source_dir="${2:-}"; shift 2 ;;
    --patch) patch_file="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --prefix) prefix="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -d "$source_dir" && ( -f "$source_dir/configure" || -f "$source_dir/configure.ac" ) ]] || { usage; exit 2; }
[[ -f "$patch_file" ]] || { usage; exit 2; }
[[ -n "$out_dir" ]] || { usage; exit 2; }
[[ -f "$toolchain_env" ]] || { echo "toolchain environment missing: $toolchain_env" >&2; exit 3; }

prefix="${prefix:-$out_dir/prefix}"
work="$out_dir/libffi-src"
build="$out_dir/build"
rm -rf "$out_dir"
mkdir -p "$out_dir"
(cd "$source_dir" && tar -cf - .) | (mkdir -p "$work" && cd "$work" && tar -xf -)
(cd "$work" && patch -p1 < "$patch_file")
if [[ ! -x "$work/configure" ]]; then
  (cd "$work" && ./autogen.sh)
fi
[[ -x "$work/configure" ]] || { echo "failed to generate configure" >&2; exit 4; }

# The MPSS SDK identifies as K1OM but libffi 3.4.6's config.sub predates that
# tuple. Configure the compatible x86-64 backend with the K1OM compiler, then
# restrict the generated target object list to the two patched Unix64 objects.
source "$toolchain_env"
target_sysroot="${OECORE_TARGET_SYSROOT:?MPSS environment did not set OECORE_TARGET_SYSROOT}"
mkdir -p "$build"
cd "$build"
CC=k1om-mpss-linux-gcc \
CPP=k1om-mpss-linux-cpp \
AR=k1om-mpss-linux-ar \
RANLIB=k1om-mpss-linux-ranlib \
CFLAGS="-m64 --sysroot=$target_sysroot -O2 -fexceptions" \
CPPFLAGS="-m64 --sysroot=$target_sysroot" \
LDFLAGS="--sysroot=$target_sysroot" \
  "$work/configure" \
    --host=x86_64-k1om-linux-gnu \
    --build=x86_64-pc-linux-gnu \
    --prefix="$prefix" \
    --disable-docs

sed -i \
  's#^TARGET_OBJ =.*#TARGET_OBJ = src/x86/ffi64.lo src/x86/unix64.lo#' \
  Makefile
grep -q '^TARGET_OBJ = src/x86/ffi64.lo src/x86/unix64.lo$' Makefile
make -j"${JOBS:-2}" libffi.la
make install

readelf -h .libs/libffi.so.8.1.4 | grep -q 'Machine:.*Intel K1OM'
sha256sum .libs/libffi.a .libs/libffi.so.8.1.4 > "$out_dir/sha256sums.txt"
cat > "$out_dir/build-summary.txt" <<EOF
status=passed
source_dir=$source_dir
patch=$patch_file
build_dir=$build
prefix=$prefix
machine=Intel K1OM
static_library=$build/.libs/libffi.a
shared_library=$build/.libs/libffi.so.8.1.4
EOF
cat "$out_dir/build-summary.txt"
