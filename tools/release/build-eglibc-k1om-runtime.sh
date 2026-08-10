#!/bin/bash
# Build the minimal K1OM eglibc runtime from pinned source archives and XPR's overlay.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-eglibc-k1om-runtime.sh --orig ARCHIVE --debian ARCHIVE \
       --overlay DIR --sysroot DIR --out DIR --cross-compile PREFIX [--jobs N]

The output directory must not already exist.  This script never installs into
MPSS or the host root.  ARCHIVE inputs are deliberately explicit so a release
builder can verify them against its source ledger before invoking this script.
EOF
}

orig= debian= overlay= sysroot= out= cross_compile= jobs=2
while [ "$#" -gt 0 ]; do
    case "$1" in
        --orig) orig=$2; shift 2 ;;
        --debian) debian=$2; shift 2 ;;
        --overlay) overlay=$2; shift 2 ;;
        --sysroot) sysroot=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --cross-compile) cross_compile=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in "$orig" "$debian" "$overlay" "$sysroot" "$out" "$cross_compile"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done
[ -f "$orig" ] && [ -f "$debian" ] || { echo "missing eglibc source archive" >&2; exit 1; }
[ -d "$overlay" ] || { echo "missing K1OM overlay: $overlay" >&2; exit 1; }
[ -d "$sysroot/usr/include" ] || { echo "missing sysroot headers: $sysroot/usr/include" >&2; exit 1; }
[ -x "${cross_compile}gcc" ] || { echo "missing compiler: ${cross_compile}gcc" >&2; exit 1; }
[ ! -e "$out" ] || { echo "output already exists: $out" >&2; exit 1; }

mkdir -p "$out/work" "$out/build" "$out/stage"
tar -C "$out/work" -xf "$orig"
source_dir=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'eglibc-*' -print -quit)
[ -n "$source_dir" ] || { echo "eglibc source directory not found" >&2; exit 1; }
tar -C "$source_dir" -xf "$debian"

# Apply the Ubuntu source package patch series in its recorded order.
while IFS= read -r patch_file; do
    patch_file=${patch_file%%#*}
    patch_file=$(printf '%s' "$patch_file" | sed 's/[[:space:]]*$//')
    case "$patch_file" in '') continue ;; esac
    patch -d "$source_dir" -p1 --batch < "$source_dir/debian/patches/$patch_file"
done < "$source_dir/debian/patches/series"

# The overlay uses glibc's native sysdeps paths and is intentionally tracked.
cp -a "$overlay"/. "$source_dir"/

printf 'orig_sha256=%s\n' "$(sha256sum "$orig" | awk '{print $1}')" | tee "$out/build-provenance.txt"
printf 'debian_sha256=%s\n' "$(sha256sum "$debian" | awk '{print $1}')" | tee -a "$out/build-provenance.txt"
printf 'overlay_sha256=%s\n' "$(find "$overlay" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')" | tee -a "$out/build-provenance.txt"
"${cross_compile}gcc" --version | head -n 1 | tee -a "$out/build-provenance.txt"
"${cross_compile}ld" --version | head -n 1 | tee -a "$out/build-provenance.txt"

pushd "$out/build" >/dev/null
BUILD_CC=gcc CC="${cross_compile}gcc" AR="${cross_compile}ar" RANLIB="${cross_compile}ranlib" \
    "$source_dir/configure" --build=x86_64-pc-linux-gnu --host=k1om-mpss-linux \
    --prefix=/usr --with-headers="$sysroot/usr/include" --enable-kernel=2.6.38 \
    --disable-werror > "$out/configure.log" 2>&1
make -j"$jobs" > "$out/build.log" 2>&1
make install DESTDIR="$out/stage" > "$out/install.log" 2>&1
popd >/dev/null

libdir="$out/stage/usr/lib"
[ -d "$libdir" ] || libdir="$out/stage/lib"
for library in ld-linux-k1om.so.2 libc.so.6 libpthread.so.0 libm.so.6 libdl.so.2 librt.so.1 libutil.so.1; do
    [ -e "$libdir/$library" ] || { echo "missing installed runtime library: $library" >&2; exit 1; }
    readelf -h "$libdir/$library" | grep -F 'Machine:                           Intel K1OM'
done
sha256sum "$libdir"/ld-linux-k1om.so.2 "$libdir"/libc.so.6 "$libdir"/libpthread.so.0 \
    "$libdir"/libm.so.6 "$libdir"/libdl.so.2 "$libdir"/librt.so.1 "$libdir"/libutil.so.1 \
    > "$out/runtime-sha256sums.txt"
printf 'runtime_libdir=%s\n' "$libdir" >> "$out/build-provenance.txt"
