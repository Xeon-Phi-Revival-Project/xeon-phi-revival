#!/usr/bin/env bash
# Build the KNC GCC C driver from the pinned public source archive.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-k1om-gcc.sh --gcc ARCHIVE --gmp ARCHIVE --mpfr ARCHIVE --mpc ARCHIVE \
  --target-tools DIR --sysroot DIR --out DIR [--jobs N] [--keep-work]

Builds the cross C compiler.  A caller that needs a bootstrap libgcc must
first stage libc headers, then build it from this retained GCC build tree.
EOF
}

gcc_archive= gmp_archive= mpfr_archive= mpc_archive= target_tools= sysroot= out= jobs=2 keep_work=no
while [[ $# -gt 0 ]]; do
    case "$1" in
        --gcc) gcc_archive=$2; shift 2 ;;
        --gmp) gmp_archive=$2; shift 2 ;;
        --mpfr) mpfr_archive=$2; shift 2 ;;
        --mpc) mpc_archive=$2; shift 2 ;;
        --target-tools) target_tools=$2; shift 2 ;;
        --sysroot) sysroot=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        --keep-work) keep_work=yes; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
for required in "$gcc_archive" "$gmp_archive" "$mpfr_archive" "$mpc_archive" "$target_tools" "$sysroot" "$out"; do
    [[ -n "$required" ]] || { usage >&2; exit 2; }
done
for archive in "$gcc_archive" "$gmp_archive" "$mpfr_archive" "$mpc_archive"; do
    [[ -f "$archive" ]] || { echo "missing source archive: $archive" >&2; exit 1; }
done
for tool in ar as ld nm objcopy objdump ranlib readelf strip; do
    [[ -x "$target_tools/k1om-mpss-linux-$tool" ]] || {
        echo "missing source-built target tool: $tool" >&2; exit 1;
    }
done
[[ -d "$sysroot" && ! -e "$out" ]] || { echo "invalid sysroot or existing output" >&2; exit 1; }

mkdir -p "$out/work" "$out/build"
if [[ "$keep_work" != yes ]]; then
    trap 'rm -rf "$out/work"' EXIT
fi
for archive in "$gcc_archive" "$gmp_archive" "$mpfr_archive" "$mpc_archive"; do
    tar -C "$out/work" -xf "$archive"
done
gcc_source=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'gcc-*' -print -quit)
gmp_source=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'gmp-*' -print -quit)
mpfr_source=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'mpfr-*' -print -quit)
mpc_source=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'mpc-*' -print -quit)
for source in "$gcc_source" "$gmp_source" "$mpfr_source" "$mpc_source"; do
    [[ -n "$source" ]] || { echo "expected source directory missing" >&2; exit 1; }
done
ln -s "$gmp_source" "$gcc_source/gmp"
ln -s "$mpfr_source" "$gcc_source/mpfr"
ln -s "$mpc_source" "$gcc_source/mpc"

export PATH="$target_tools:$PATH"
pushd "$out/build" >/dev/null
AS_FOR_TARGET="$target_tools/k1om-mpss-linux-as" \
LD_FOR_TARGET="$target_tools/k1om-mpss-linux-ld" \
NM_FOR_TARGET="$target_tools/k1om-mpss-linux-nm" \
AR_FOR_TARGET="$target_tools/k1om-mpss-linux-ar" \
RANLIB_FOR_TARGET="$target_tools/k1om-mpss-linux-ranlib" \
OBJCOPY_FOR_TARGET="$target_tools/k1om-mpss-linux-objcopy" \
OBJDUMP_FOR_TARGET="$target_tools/k1om-mpss-linux-objdump" \
READELF_FOR_TARGET="$target_tools/k1om-mpss-linux-readelf" \
STRIP_FOR_TARGET="$target_tools/k1om-mpss-linux-strip" \
"$gcc_source/configure" --build=x86_64-linux-gnu --host=x86_64-linux-gnu \
    --target=k1om-mpss-linux --prefix="$out/install" --without-headers \
    --enable-languages=c --disable-multilib --disable-bootstrap --disable-nls \
    --disable-libgcov \
    --disable-libssp --disable-libgomp --disable-libmudflap --disable-libitm \
    --disable-libsanitizer --with-as="$target_tools/k1om-mpss-linux-as" \
    --with-ld="$target_tools/k1om-mpss-linux-ld" --with-sysroot="$sysroot" \
    > "$out/configure.log" 2>&1
make -j"$jobs" all-gcc > "$out/build.log" 2>&1
grep -F 'ORIGINAL_AS_FOR_TARGET="' gcc/as | grep -F 'k1om-mpss-linux-as"' >/dev/null || {
    echo "generated target-as wrapper is not bound to KNC binutils" >&2; exit 1;
}
make install-gcc > "$out/install.log" 2>&1
popd >/dev/null

[[ -x "$out/install/bin/k1om-mpss-linux-gcc" ]] || { echo "GCC install missing driver" >&2; exit 1; }
[[ -x "$out/install/libexec/gcc/k1om-mpss-linux/5.1.1/cc1" ]] || {
    echo "GCC install missing cc1" >&2; exit 1;
}
{
    echo "gcc_sha256=$(sha256sum "$gcc_archive" | awk '{print $1}')"
    echo "gmp_sha256=$(sha256sum "$gmp_archive" | awk '{print $1}')"
    echo "mpfr_sha256=$(sha256sum "$mpfr_archive" | awk '{print $1}')"
    echo "mpc_sha256=$(sha256sum "$mpc_archive" | awk '{print $1}')"
    find "$out/install" -type f -print0 | sort -z | xargs -0 sha256sum
} > "$out/SHA256SUMS"
echo XPR_K1OM_GCC=PASS
