#!/bin/bash
# Stage source-built eglibc headers needed before the initial K1OM libgcc.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-eglibc-k1om-bootstrap-headers.sh --orig ARCHIVE --debian ARCHIVE \
       --overlay DIR --linux-headers DIR --gcc-build DIR --target-tools DIR --out DIR
EOF
}

orig= debian= overlay= linux_headers= gcc_build= target_tools= out=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --orig) orig=$2; shift 2 ;;
        --debian) debian=$2; shift 2 ;;
        --overlay) overlay=$2; shift 2 ;;
        --linux-headers) linux_headers=$2; shift 2 ;;
        --gcc-build) gcc_build=$2; shift 2 ;;
        --target-tools) target_tools=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
for required in "$orig" "$debian" "$overlay" "$linux_headers" "$gcc_build" "$target_tools" "$out"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done
[ -f "$orig" ] && [ -f "$debian" ] && [ -d "$overlay" ] || exit 1
[ -f "$linux_headers/linux/errno.h" ] || { echo "missing Linux headers" >&2; exit 1; }
[ -x "$gcc_build/gcc/xgcc" ] || { echo "missing stage-one xgcc" >&2; exit 1; }
[ ! -e "$out" ] || { echo "output already exists: $out" >&2; exit 1; }

mkdir -p "$out/work" "$out/build" "$out/usr/include"
trap 'rm -rf "$out/work"' EXIT
tar -C "$out/work" -xf "$orig"
source_dir=$(find "$out/work" -mindepth 1 -maxdepth 1 -type d -name 'eglibc-*' -print -quit)
[ -n "$source_dir" ] || exit 1
tar -C "$source_dir" -xf "$debian"
while IFS= read -r patch_file; do
    patch_file=${patch_file%%#*}
    patch_file=$(printf '%s' "$patch_file" | sed 's/[[:space:]]*$//')
    [ -n "$patch_file" ] || continue
    patch -d "$source_dir" -p1 --batch < "$source_dir/debian/patches/$patch_file"
done < "$source_dir/debian/patches/series"
cp -a "$overlay"/. "$source_dir"/
while IFS= read -r -d '' overlay_file; do
    sed -i 's/\r$//' "$source_dir/${overlay_file#"$overlay"/}"
done < <(find "$overlay" -type f -print0)

export PATH="$target_tools:$PATH"
cross_cc="$gcc_build/gcc/xgcc -B$gcc_build/gcc/"
pushd "$out/build" >/dev/null
BUILD_CC=gcc CC="$cross_cc" AR="$target_tools/k1om-mpss-linux-ar" \
    AS="$target_tools/k1om-mpss-linux-as" LD="$target_tools/k1om-mpss-linux-ld" \
    NM="$target_tools/k1om-mpss-linux-nm" RANLIB="$target_tools/k1om-mpss-linux-ranlib" \
    READELF="$target_tools/k1om-mpss-linux-readelf" libc_cv_forced_unwind=yes \
    libc_cv_ssp=no CFLAGS="-O2 -fno-stack-protector" \
    "$source_dir/configure" --build=x86_64-pc-linux-gnu --host=k1om-mpss-linux \
    --prefix=/usr --with-headers="$linux_headers" --enable-kernel=2.6.38 \
    --enable-add-ons=nptl,ports --disable-werror > "$out/configure.log" 2>&1
make install-headers install_root="$out" > "$out/install-headers.log" 2>&1
popd >/dev/null
[ -f "$out/usr/include/stdio.h" ] || { echo "eglibc bootstrap stdio.h missing" >&2; exit 1; }
echo XPR_EGLIBC_BOOTSTRAP_HEADERS=PASS
