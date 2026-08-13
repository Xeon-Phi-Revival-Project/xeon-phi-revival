#!/usr/bin/env bash
# Rebuild the standalone XPR K1OM toolkit from the paired source bundle.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-standalone-xpr-k1om-toolkit.sh --sources DIR --out DIR [--jobs N]

SOURCES is the extracted xpr-k1om-toolkit-0.1.0-sources tree.  No MPSS SDK
input is accepted or required. Host C compiler, make, tar, patch, bison, flex,
and standard development libraries are normal bootstrap prerequisites.
EOF
}

sources= out= jobs=2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sources) sources=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
[[ -d "$sources" && -n "$out" && ! -e "$out" ]] || { usage >&2; exit 2; }
repo="$sources/repository"
inputs="$sources/upstream"
for file in gcc-5.1.1-knc-af7cc04.tar.gz gmp-4.3.2.tar.bz2 mpfr-2.4.2.tar.bz2 \
            mpc-0.8.1.tar.gz binutils-2.22+mpss3.8.6.tar.bz2 \
            eglibc_2.19.orig.tar.xz eglibc_2.19-0ubuntu6.15.debian.tar.xz solros-bda6ce.tar.gz; do
    [[ -f "$inputs/$file" ]] || { echo "source bundle missing $file" >&2; exit 1; }
done
[[ -f "$repo/tools/toolchain/build-k1om-gcc.sh" ]] || { echo "source bundle lacks build scripts" >&2; exit 1; }

mkdir -p "$out/headers-work" "$out/linux-headers/usr" "$out/bootstrap-sysroot/usr/include"
tar -C "$out/headers-work" -xzf "$inputs/solros-bda6ce.tar.gz"
# The Solros source bundle contains both host and Phi kernels.  The XPR
# sysroot needs the K1OM-facing UAPI headers from phi-kernel, not its wrapper.
linux_source=$(find "$out/headers-work" -type f -path '*/phi-kernel/Makefile' -printf '%h\n' -quit)
[[ -n "$linux_source" ]] || { echo "Solros source lacks phi-kernel headers" >&2; exit 1; }
make -C "$linux_source" ARCH=x86 INSTALL_HDR_PATH="$out/linux-headers/usr" headers_install > "$out/linux-headers.log" 2>&1
cp -a "$out/linux-headers/usr/include/." "$out/bootstrap-sysroot/usr/include/"

bash "$repo/tools/toolchain/build-k1om-binutils.sh" \
    --source "$inputs/binutils-2.22+mpss3.8.6.tar.bz2" --sysroot "$out/bootstrap-sysroot" \
    --out "$out/binutils" --jobs "$jobs"
bash "$repo/tools/toolchain/build-k1om-gcc.sh" \
    --gcc "$inputs/gcc-5.1.1-knc-af7cc04.tar.gz" --gmp "$inputs/gmp-4.3.2.tar.bz2" \
    --mpfr "$inputs/mpfr-2.4.2.tar.bz2" --mpc "$inputs/mpc-0.8.1.tar.gz" \
    --target-tools "$out/binutils/target-tools" --sysroot "$out/bootstrap-sysroot" \
    --out "$out/gcc" --jobs "$jobs" --keep-work
bash "$repo/tools/release/build-eglibc-k1om-bootstrap-headers.sh" \
    --orig "$inputs/eglibc_2.19.orig.tar.xz" --debian "$inputs/eglibc_2.19-0ubuntu6.15.debian.tar.xz" \
    --overlay "$repo/ubuntu-port/k1om/glibc" --linux-headers "$out/linux-headers/usr/include" \
    --gcc-build "$out/gcc/build" --target-tools "$out/binutils/target-tools" \
    --out "$out/eglibc-bootstrap-headers"
cp -a "$out/eglibc-bootstrap-headers/usr/include/." "$out/bootstrap-sysroot/usr/include/"
pushd "$out/gcc/build" >/dev/null
make configure-target-libgcc >> "$out/gcc/build.log" 2>&1
make -C k1om-mpss-linux/libgcc libgcc.a >> "$out/gcc/build.log" 2>&1
gcc_version=$("$out/gcc/install/bin/k1om-mpss-linux-gcc" -dumpversion)
install -D -m 0644 k1om-mpss-linux/libgcc/libgcc.a \
    "$out/gcc/install/lib/gcc/k1om-mpss-linux/$gcc_version/libgcc.a"
popd >/dev/null
mkdir -p "$out/cross/bin"
ln -s "$out/gcc/install/bin/k1om-mpss-linux-gcc" "$out/cross/bin/k1om-mpss-linux-gcc"
for tool in ar as ld nm ranlib readelf; do
    ln -s "$out/binutils/target-tools/k1om-mpss-linux-$tool" "$out/cross/bin/k1om-mpss-linux-$tool"
done
bash "$repo/tools/release/build-eglibc-k1om-runtime.sh" \
    --orig "$inputs/eglibc_2.19.orig.tar.xz" --debian "$inputs/eglibc_2.19-0ubuntu6.15.debian.tar.xz" \
    --overlay "$repo/ubuntu-port/k1om/glibc" --sysroot "$out/linux-headers" \
    --out "$out/eglibc" --cross-compile "$out/cross/bin/k1om-mpss-linux-" --jobs "$jobs"
bash "$repo/tools/release/build-k1om-libgcc.sh" \
    --gcc "$inputs/gcc-5.1.1-knc-af7cc04.tar.gz" --gmp "$inputs/gmp-4.3.2.tar.bz2" \
    --mpfr "$inputs/mpfr-2.4.2.tar.bz2" --mpc "$inputs/mpc-0.8.1.tar.gz" \
    --crt-dir "$out/eglibc/stage/usr/lib" --sysroot "$out/eglibc/stage" \
    --linux-headers "$out/linux-headers/usr/include" --target-tools "$out/binutils/target-tools" \
    --out "$out/libgcc" --jobs "$jobs"
bash "$repo/tools/toolchain/package-standalone-xpr-k1om-toolkit.sh" \
    --gcc-prefix "$out/gcc/install" --binutils-prefix "$out/binutils/install" \
    --eglibc-stage "$out/eglibc/stage" --libgcc-dir "$out/libgcc/install/k1om-mpss-linux/lib64" \
    --examples "$repo/examples/k1om" --out "$out/package"
echo XPR_STANDALONE_TOOLKIT_REBUILD=PASS
