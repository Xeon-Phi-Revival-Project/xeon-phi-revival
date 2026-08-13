#!/bin/bash
# Build a K1OM libgcc runtime from a pinned GCC source archive.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-k1om-libgcc.sh --gcc ARCHIVE --gmp ARCHIVE --mpfr ARCHIVE --mpc ARCHIVE \
       --crt-dir DIR --sysroot DIR --linux-headers DIR --target-tools DIR --out DIR [--jobs N]

All inputs are explicit. CRT objects must come from the source-built eglibc
stage; the script never copies a runtime object from MPSS into its output.
EOF
}

gcc_archive= gmp_archive= mpfr_archive= mpc_archive=
crt_dir= sysroot= linux_headers= target_tools= out= jobs=2
while [ "$#" -gt 0 ]; do
    case "$1" in
        --gcc) gcc_archive=$2; shift 2 ;;
        --gmp) gmp_archive=$2; shift 2 ;;
        --mpfr) mpfr_archive=$2; shift 2 ;;
        --mpc) mpc_archive=$2; shift 2 ;;
        --crt-dir) crt_dir=$2; shift 2 ;;
        --sysroot) sysroot=$2; shift 2 ;;
        --linux-headers) linux_headers=$2; shift 2 ;;
        --target-tools) target_tools=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in "$gcc_archive" "$gmp_archive" "$mpfr_archive" "$mpc_archive" "$crt_dir" "$sysroot" "$linux_headers" "$target_tools" "$out"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done
for archive in "$gcc_archive" "$gmp_archive" "$mpfr_archive" "$mpc_archive"; do
    [ -f "$archive" ] || { echo "missing source archive: $archive" >&2; exit 1; }
done
[ -d "$crt_dir" ] || { echo "missing source-built CRT directory: $crt_dir" >&2; exit 1; }
[ -d "$sysroot/usr/include" ] && [ -d "$sysroot/lib" ] || {
    echo "sysroot must be a source-built eglibc stage with headers and runtime libraries" >&2; exit 1;
}
case "$sysroot" in
    /opt/mpss/*) echo "MPSS sysroots are forbidden: use the source-built eglibc stage" >&2; exit 1 ;;
esac
[ -f "$linux_headers/linux/errno.h" ] || { echo "missing public Linux UAPI headers" >&2; exit 1; }
for tool in ar as ld nm objcopy objdump ranlib readelf strip; do
    [ -x "$target_tools/k1om-mpss-linux-$tool" ] || {
        echo "missing target tool: $target_tools/k1om-mpss-linux-$tool" >&2; exit 1;
    }
done
[ ! -e "$out" ] || { echo "output already exists: $out" >&2; exit 1; }

mkdir -p "$out/work" "$out/build" "$out/install/k1om-mpss-linux/lib" "$out/sysroot"
trap 'rm -rf "$out/work"' EXIT
cp -a "$sysroot"/. "$out/sysroot"/
cp -a "$linux_headers"/. "$out/sysroot/usr/include"/
tar -C "$out/work" -xf "$gcc_archive"
tar -C "$out/work" -xf "$gmp_archive"
tar -C "$out/work" -xf "$mpfr_archive"
tar -C "$out/work" -xf "$mpc_archive"

source_dir=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'gcc-*' -print -quit)
gmp_dir=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'gmp-*' -print -quit)
mpfr_dir=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'mpfr-*' -print -quit)
mpc_dir=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'mpc-*' -print -quit)
for directory in "$source_dir" "$gmp_dir" "$mpfr_dir" "$mpc_dir"; do
    [ -n "$directory" ] || { echo "source extraction did not yield an expected directory" >&2; exit 1; }
done
ln -s "$gmp_dir" "$source_dir/gmp"
ln -s "$mpfr_dir" "$source_dir/mpfr"
ln -s "$mpc_dir" "$source_dir/mpc"

# libgcc_s links through the target prefix. Supply only the newly-built eglibc
# CRT objects there; they are build inputs, not release payload files.
for object in crt1.o crti.o crtn.o; do
    [ -f "$crt_dir/$object" ] || { echo "missing source-built CRT object: $object" >&2; exit 1; }
    cp "$crt_dir/$object" "$out/install/k1om-mpss-linux/lib/$object"
done

printf 'gcc_sha256=%s\n' "$(sha256sum "$gcc_archive" | awk '{print $1}')" > "$out/build-provenance.txt"
printf 'gmp_sha256=%s\n' "$(sha256sum "$gmp_archive" | awk '{print $1}')" >> "$out/build-provenance.txt"
printf 'mpfr_sha256=%s\n' "$(sha256sum "$mpfr_archive" | awk '{print $1}')" >> "$out/build-provenance.txt"
printf 'mpc_sha256=%s\n' "$(sha256sum "$mpc_archive" | awk '{print $1}')" >> "$out/build-provenance.txt"
printf 'crt_dir=%s\n' "$crt_dir" >> "$out/build-provenance.txt"
printf 'sysroot=%s\n' "$sysroot" >> "$out/build-provenance.txt"
printf 'linux_headers=%s\n' "$linux_headers" >> "$out/build-provenance.txt"

# GCC 5.1.1's generated as/nm wrappers need absolute ORIGINAL_*_FOR_TARGET
# values.  PATH discovery alone leaves those values empty and makes wrappers
# execute `-p` instead of the selected target tool.
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
"$source_dir/configure" --build=x86_64-linux-gnu --host=x86_64-linux-gnu \
    --target=k1om-mpss-linux --prefix="$out/install" \
    --enable-languages=c --enable-shared --enable-threads=posix \
    --disable-multilib --disable-bootstrap --disable-libssp --disable-libgomp \
    --disable-libmudflap --disable-libitm --disable-libsanitizer --disable-nls \
    --with-system-zlib --with-as="$target_tools/k1om-mpss-linux-as" \
    --with-ld="$target_tools/k1om-mpss-linux-ld" --with-sysroot="$out/sysroot" \
    > "$out/configure.log" 2>&1
make -j"$jobs" all-gcc all-target-libgcc > "$out/build.log" 2>&1
grep -F 'ORIGINAL_NM_FOR_TARGET="' gcc/nm | grep -F 'k1om-mpss-linux-nm"' > /dev/null || {
    echo "generated target-nm wrapper is not bound to k1om-mpss-linux-nm" >&2; exit 1;
}
grep -F 'ORIGINAL_AS_FOR_TARGET="' gcc/as | grep -F 'k1om-mpss-linux-as"' > /dev/null || {
    echo "generated target-as wrapper is not bound to k1om-mpss-linux-as" >&2; exit 1;
}
make install-target-libgcc > "$out/install.log" 2>&1
popd >/dev/null

runtime="$out/install/k1om-mpss-linux/lib64/libgcc_s.so.1"
[ -f "$runtime" ] || { echo "missing installed libgcc_s.so.1" >&2; exit 1; }
"$target_tools/k1om-mpss-linux-readelf" -h "$runtime" | grep -F 'Machine:                           Intel K1OM'
"$target_tools/k1om-mpss-linux-readelf" -d "$runtime" | grep -F 'Library soname: [libgcc_s.so.1]'
"$target_tools/k1om-mpss-linux-nm" -D "$runtime" | grep -F '_Unwind_RaiseException'
sha256sum "$runtime" > "$out/libgcc-runtime-sha256sums.txt"
printf 'runtime=%s\n' "$runtime" >> "$out/build-provenance.txt"
