#!/bin/bash
# Build static-inspection probes against a source-built XPR K1OM runtime root.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: validate-k1om-public-runtime.sh --root DIR --headers DIR --crt-dir DIR \
       --linker-dir DIR --libgcc-dir DIR --cross-compile PREFIX --source-dir DIR --out DIR

This does not execute K1OM binaries. It creates three dynamic probes and
checks their ELF interpreter and dependency metadata.
EOF
}

root= headers= crt_dir= linker_dir= libgcc_dir= cross_compile= source_dir= out=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root) root=$2; shift 2 ;;
        --headers) headers=$2; shift 2 ;;
        --crt-dir) crt_dir=$2; shift 2 ;;
        --linker-dir) linker_dir=$2; shift 2 ;;
        --libgcc-dir) libgcc_dir=$2; shift 2 ;;
        --cross-compile) cross_compile=$2; shift 2 ;;
        --source-dir) source_dir=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in "$root" "$headers" "$crt_dir" "$linker_dir" "$libgcc_dir" "$cross_compile" "$source_dir" "$out"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done
[ -d "$root" ] && [ -d "$headers" ] && [ -d "$crt_dir" ] && [ -d "$linker_dir" ] && [ -d "$libgcc_dir" ] || {
    echo "missing root, headers, CRT, linker, or libgcc directory" >&2; exit 1;
}
[ -x "${cross_compile}gcc" ] && [ -x "${cross_compile}readelf" ] || {
    echo "missing K1OM compiler or readelf" >&2; exit 1;
}
[ ! -e "$out" ] || { echo "output already exists: $out" >&2; exit 1; }
for path in "$root/lib64/ld-linux-k1om.so.2" "$root/lib64/libc.so.6" \
            "$root/lib64/libpthread.so.0" "$root/lib64/libdl.so.2" \
            "$root/lib64/libm.so.6" "$root/lib64/libgcc_s.so.1" \
            "$root/lib64/libnss_files.so.2" "$root/etc/nsswitch.conf" \
            "$root/etc/passwd" "$root/etc/shells" "$root/bin/sh" \
            "$crt_dir/crt1.o" "$crt_dir/crti.o" "$crt_dir/crtn.o"; do
    [ -e "$path" ] || { echo "required runtime input is missing: $path" >&2; exit 1; }
done
grep -qx 'passwd: files' "$root/etc/nsswitch.conf"
grep -qx 'group: files' "$root/etc/nsswitch.conf"
grep -qx 'shadow: files' "$root/etc/nsswitch.conf"
grep -q '^root:[^:]*:0:0:[^:]*:/root:/bin/sh$' "$root/etc/passwd"
grep -qx '/bin/sh' "$root/etc/shells"

mkdir -p "$out"
# The public root intentionally excludes development-only linker scripts and
# nonshared archives. Stage them in a disposable sysroot for this link check.
sysroot="$out/sysroot"
mkdir -p "$sysroot/usr/lib"
ln -s "$root/lib64" "$sysroot/lib64"
ln -s lib64 "$sysroot/lib"
for object in libc_nonshared.a libpthread_nonshared.a; do
    [ -f "$linker_dir/$object" ] && cp "$linker_dir/$object" "$sysroot/usr/lib/$object"
done
common=("--sysroot=$sysroot" -isystem "$headers" -B"$crt_dir" -B"$libgcc_dir"
        -L"$linker_dir" -L"$root/lib64" -Wl,--dynamic-linker=/lib64/ld-linux-k1om.so.2
        -Wl,-rpath,/lib64 -Wl,--no-as-needed)
"${cross_compile}gcc" "${common[@]}" -o "$out/hello" "$source_dir/xpr_hello.c" -lgcc_s
"${cross_compile}gcc" "${common[@]}" -pthread -o "$out/pthread" "$source_dir/xpr_pthread_smoke.c" -lgcc_s
"${cross_compile}gcc" "${common[@]}" -o "$out/dlopen" "$source_dir/xpr_dlopen_smoke.c" -ldl -lgcc_s

for binary in "$out/hello" "$out/pthread" "$out/dlopen"; do
    "${cross_compile}readelf" -h "$binary" | grep -F 'Machine:                           Intel K1OM'
    "${cross_compile}readelf" -l "$binary" | grep -F 'Requesting program interpreter: /lib64/ld-linux-k1om.so.2'
    "${cross_compile}readelf" -d "$binary" | grep -F 'Library rpath: [/lib64]'
    "${cross_compile}readelf" -d "$binary" | grep -F 'Shared library: [libc.so.6]'
    "${cross_compile}readelf" -d "$binary" | grep -F 'Shared library: [libgcc_s.so.1]'
done
"${cross_compile}readelf" -d "$out/pthread" | grep -F 'Shared library: [libpthread.so.0]'
"${cross_compile}readelf" -d "$out/dlopen" | grep -F 'Shared library: [libdl.so.2]'

{
    printf 'root=%s\n' "$root"
    sha256sum "$root/lib64/ld-linux-k1om.so.2" "$root/lib64/libc.so.6" \
        "$root/lib64/libpthread.so.0" "$root/lib64/libdl.so.2" \
        "$root/lib64/libm.so.6" "$root/lib64/libgcc_s.so.1" \
        "$root/lib64/libnss_files.so.2"
    for binary in "$out/hello" "$out/pthread" "$out/dlopen"; do
        printf '\n[%s]\n' "$(basename "$binary")"
        "${cross_compile}readelf" -l "$binary" | grep 'Requesting program interpreter'
        "${cross_compile}readelf" -d "$binary" | grep -E 'NEEDED|RPATH|RUNPATH'
    done
} > "$out/runtime-validation-report.txt"
printf 'PASS: output=%s\n' "$out"
