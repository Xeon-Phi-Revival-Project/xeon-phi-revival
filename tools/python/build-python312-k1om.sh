#!/usr/bin/env bash
# Build a minimal CPython 3.12.13 K1OM runtime from official source.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-python312-k1om.sh --source Python-3.12.13.tar.xz --toolkit DIR --out DIR [--jobs N]

TOOLKIT is a source-accounted XPR K1OM toolkit tree. The build creates a host
bootstrap Python and a K1OM target build without an MPSS SDK or /opt/mpss.
The initial profile deliberately builds CPython core plus the stdlib source;
optional third-party extension modules are added by separate accounted lanes.
EOF
}

source_archive=
toolkit=
out=
jobs=2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source) source_archive=$2; shift 2 ;;
        --toolkit) toolkit=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

[[ -f "$source_archive" && -d "$toolkit" && -n "$out" && ! -e "$out" ]] || {
    usage >&2
    exit 2
}
[[ "$(sha256sum "$source_archive" | awk '{print $1}')" == \
   "c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684" ]] || {
    echo "unexpected CPython source checksum" >&2
    exit 1
}
# A host may happen to have MPSS installed for card control. This builder never
# adds it to PATH or to compiler/sysroot inputs; the toolkit is complete.
export PATH="$toolkit/bin:/usr/bin:/bin"
for path in "$toolkit/bin/xpr-gcc" "$toolkit/bin/xpr-ar" "$toolkit/bin/xpr-ranlib"; do
    [[ -x "$path" ]] || { echo "toolkit missing $path" >&2; exit 1; }
done

root=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
patch="$root/patches/python-3.12-k1om/0001-k1om-atomic-fence.patch"
[[ -f "$patch" ]] || { echo "missing K1OM patch" >&2; exit 1; }

mkdir -p "$out"
tar -C "$out" -xf "$source_archive"
mv "$out/Python-3.12.13" "$out/host-src"
cp -a "$out/host-src" "$out/target-src"
patch -d "$out/target-src" -p1 < "$patch"

mkdir "$out/host-build"
pushd "$out/host-build" >/dev/null
"$out/host-src/configure" --without-ensurepip > configure.log 2>&1
make -j"$jobs" python > make-python.log 2>&1
host_python="$out/host-build/python"
"$host_python" --version
popd >/dev/null

mkdir "$out/target-build"
pushd "$out/target-build" >/dev/null
export CC="$toolkit/bin/xpr-gcc"
export AR="$toolkit/bin/xpr-ar"
export RANLIB="$toolkit/bin/xpr-ranlib"
export READELF="$toolkit/bin/xpr-readelf"
export ac_cv_file__dev_ptmx=yes
export ac_cv_file__dev_ptc=no
# Cross configuration cannot execute the target probe.  K1OM EGLIBC does not
# provide the BSD-only chflags(2); prevent configure from enabling that code.
export ac_cv_func_chflags=no
"$out/target-src/configure" \
    --build=x86_64-pc-linux-gnu \
    --host=k1om-mpss-linux \
    --with-build-python="$host_python" \
    --disable-ipv6 \
    --without-ensurepip \
    --prefix=/usr > configure.log 2>&1
make -j"$jobs" python > make-python.log 2>&1
"$toolkit/bin/xpr-validate" python
mkdir -p "$out/stage/usr/bin" "$out/stage/usr/lib/python3.12"
install -m 0755 python "$out/stage/usr/bin/python3.12"
ln -s python3.12 "$out/stage/usr/bin/python3"
ln -s python3.12 "$out/stage/usr/bin/python"
cp -a "$out/target-src/Lib/." "$out/stage/usr/lib/python3.12/"
find "$out/stage/usr/lib/python3.12" -type d -name __pycache__ -prune -exec rm -rf {} +
popd >/dev/null

echo "PYTHON312_CORE_BUILD=PASS"
