#!/usr/bin/env bash
# Package the source-built CPython core for a future XPR-OS root integration.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: package-python312-k1om-core.sh --stage DIR --source Python-3.12.13.tar.xz --strip TOOL --out DIR

The stage must be produced by build-python312-k1om.sh.  This creates a
deterministic runtime archive and a corresponding-source archive.  It does not
use MPSS SDK files or historic Python artifacts.
EOF
}

stage= source= strip= out=
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stage) stage=$2; shift 2 ;;
        --source) source=$2; shift 2 ;;
        --strip) strip=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

[[ -d "$stage/usr/bin" && -d "$stage/usr/lib/python3.12" && -f "$source" && -x "$strip" && -n "$out" ]] || {
    usage >&2
    exit 2
}
[[ "$(sha256sum "$source" | awk '{print $1}')" == \
   "c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684" ]] || {
    echo "unexpected CPython source checksum" >&2
    exit 1
}

root=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
command -v xz >/dev/null || { echo "missing xz" >&2; exit 1; }
version=3.12.13
package="xpr-python-$version-k1om-core"
runtime="$out/$package.tar.gz"
sources="$out/$package-sources.tar.xz"
[[ ! -e "$runtime" && ! -e "$sources" ]] || { echo "output already exists" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/$package" "$work/$package-sources/patches" "$work/$package-sources/tools/python"
cp -a "$stage/usr" "$work/$package/"
"$strip" --strip-debug "$work/$package/usr/bin/python3.12"
# CPython's test suite and IDLE fixtures are not required for the RC7 core
# runtime.  Excluding them also keeps historical example paths out of the
# distributable component.
rm -rf "$work/$package/usr/lib/python3.12/test" \
       "$work/$package/usr/lib/python3.12/idlelib"
tar -xOf "$source" Python-$version/LICENSE > "$work/$package/LICENSE"
cat > "$work/$package/README" <<'EOF'
XPR CPython 3.12.13 K1OM Core

Extract this archive at the XPR root.  It provides /usr/bin/python3.12 and the
source-only core standard library at /usr/lib/python3.12.  The runtime assumes
the XPR K1OM loader, EGLIBC, libpthread, and libgcc_s already provided by XPR-OS.
EOF
find "$work/$package" -type f -print0 | sort -z | xargs -0 sha256sum > "$work/$package/manifest.sha256"

cp -a "$source" "$work/$package-sources/"
cp -a "$root/patches/python-3.12-k1om/." "$work/$package-sources/patches/"
cp -a "$root/tools/python/build-python312-k1om.sh" "$root/tools/python/package-python312-k1om-core.sh" \
    "$work/$package-sources/tools/python/"
tar -xOf "$source" Python-$version/LICENSE > "$work/$package-sources/LICENSE"
cat > "$work/$package-sources/SOURCE-MANIFEST.md" <<'EOF'
# XPR CPython 3.12.13 K1OM Core Source Manifest

- CPython source: `Python-3.12.13.tar.xz`
- Upstream URL: `https://www.python.org/ftp/python/3.12.13/Python-3.12.13.tar.xz`
- SHA-256: `c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684`
- License: Python Software Foundation License Version 2.
- XPR changes: `patches/0001-k1om-atomic-fence.patch`
- Build: `tools/python/build-python312-k1om.sh`
- Package: `tools/python/package-python312-k1om-core.sh`

The builder requires the separately source-accounted XPR K1OM toolkit and
creates the runtime stage without MPSS SDK compiler binaries or `/opt/mpss`.
EOF

mkdir -p "$out"
make_archive() {
    local name=$1 archive=$2 compression=$3 list="$work/$1.list" tarball="$work/$1.tar"
    ( cd "$work" && find "$name" -print | LC_ALL=C sort > "$list" )
    tar --no-recursion -C "$work" -T "$list" -cf "$tarball"
    case "$compression" in
        gzip) gzip -n -9 -c "$tarball" > "$archive" ;;
        xz) xz --threads=1 --check=crc64 -6 -c "$tarball" > "$archive" ;;
        *) echo "unknown archive compression: $compression" >&2; exit 1 ;;
    esac
}
make_archive "$package" "$runtime" gzip
make_archive "$package-sources" "$sources" xz
( cd "$out" && sha256sum "$(basename "$runtime")" "$(basename "$sources")" > SHA256SUMS )
echo "PYTHON312_CORE_PACKAGE=PASS"
echo "PYTHON312_CORE_RUNTIME=$runtime"
echo "PYTHON312_CORE_SOURCES=$sources"
