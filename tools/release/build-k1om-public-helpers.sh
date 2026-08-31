#!/bin/bash
# Build the minimal project-owned dynamic helpers for a public K1OM root.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-k1om-public-helpers.sh --root DIR --headers DIR --crt-dir DIR \
       --linker-dir DIR --linux-headers DIR --libgcc-dir DIR --cross-compile PREFIX --source-dir DIR --out DIR
EOF
}

root= headers= crt_dir= linker_dir= linux_headers= libgcc_dir= cross_compile= source_dir= out=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root) root=$2; shift 2 ;;
        --headers) headers=$2; shift 2 ;;
        --crt-dir) crt_dir=$2; shift 2 ;;
        --linker-dir) linker_dir=$2; shift 2 ;;
        --linux-headers) linux_headers=$2; shift 2 ;;
        --libgcc-dir) libgcc_dir=$2; shift 2 ;;
        --cross-compile) cross_compile=$2; shift 2 ;;
        --source-dir) source_dir=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
for required in "$root" "$headers" "$crt_dir" "$linker_dir" "$linux_headers" "$libgcc_dir" "$cross_compile" "$source_dir" "$out"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done
[ -d "$root" ] && [ -d "$headers" ] && [ -d "$crt_dir" ] && [ -d "$linker_dir" ] && [ -d "$linux_headers" ] && [ -d "$libgcc_dir" ] || exit 1
[ -x "${cross_compile}gcc" ] && [ -x "${cross_compile}readelf" ] || exit 1
[ ! -e "$out" ] || { echo "output already exists: $out" >&2; exit 1; }

mkdir -p "$out/sysroot/usr/lib"
cp -a "$root/lib64" "$out/sysroot/lib64"
ln -s lib64 "$out/sysroot/lib"
cp -a "$linux_headers"/. "$out/sysroot/usr/include"/
for object in libc_nonshared.a libpthread_nonshared.a; do
    [ -f "$linker_dir/$object" ] && cp "$linker_dir/$object" "$out/sysroot/usr/lib/$object"
done
common=("--sysroot=$out/sysroot" -isystem "$headers" -B"$crt_dir" -B"$libgcc_dir"
        -L"$linker_dir" -L"$root/lib64" -Wl,--dynamic-linker=/lib64/ld-linux-k1om.so.2
        -Wl,-rpath,/lib64 -Wl,--no-as-needed)
"${cross_compile}gcc" "${common[@]}" -o "$out/xpr-hello" "$source_dir/xpr_hello.c" -lgcc_s
"${cross_compile}gcc" "${common[@]}" -pthread -o "$out/xpr-pthread-smoke" "$source_dir/xpr_pthread_smoke.c" -lgcc_s
"${cross_compile}gcc" "${common[@]}" -o "$out/xpr-dlopen-smoke" "$source_dir/xpr_dlopen_smoke.c" -ldl -lgcc_s
"${cross_compile}gcc" "${common[@]}" -o "$out/xpr-statusd" "$source_dir/xpr_statusd.c" -lgcc_s

for binary in "$out"/xpr-*; do
    "${cross_compile}readelf" -h "$binary" | grep -F 'Machine:                           Intel K1OM'
    "${cross_compile}readelf" -l "$binary" | grep -F 'Requesting program interpreter: /lib64/ld-linux-k1om.so.2'
    "${cross_compile}readelf" -d "$binary" | grep -F 'Shared library: [libc.so.6]'
done
sha256sum "$out"/xpr-hello "$out"/xpr-pthread-smoke "$out"/xpr-dlopen-smoke "$out"/xpr-statusd > "$out/SHA256SUMS"
