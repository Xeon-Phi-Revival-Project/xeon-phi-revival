#!/usr/bin/env bash
# Build the MPSS 3.8.6 GPL KNC binutils source needed for IMCI instructions.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-k1om-binutils.sh --source ARCHIVE --sysroot DIR --out DIR [--jobs N]

ARCHIVE must be the public MPSS 3.8.6 nested source archive:
binutils-2.22+mpss3.8.6.tar.bz2
EOF
}

source_archive= sysroot= out= jobs=2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source) source_archive=$2; shift 2 ;;
        --sysroot) sysroot=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

[[ -f "$source_archive" && -d "$sysroot" && -n "$out" ]] || { usage >&2; exit 2; }
[[ ! -e "$out" ]] || { echo "output already exists: $out" >&2; exit 1; }

expected_sha256=0e498581badb505bd2639bc1f75debe9299212fb50e8eee5deb40631a78abd9c
actual_sha256=$(sha256sum "$source_archive" | awk '{print $1}')
[[ "$actual_sha256" == "$expected_sha256" ]] || {
    echo "unexpected KNC binutils source hash: $actual_sha256" >&2; exit 1;
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -C "$work" -xjf "$source_archive"
source_dir=$(find "$work" -mindepth 1 -maxdepth 1 -type d -name 'binutils-2.22+mpss3.8.6' -print -quit)
[[ -f "$source_dir/COPYING" && -f "$source_dir/gas/config/tc-i386.c" ]] || {
    echo "archive does not contain the expected KNC binutils source" >&2; exit 1;
}

mkdir -p "$out/build" "$out/install"
pushd "$out/build" >/dev/null
"$source_dir/configure" --prefix="$out/install" --enable-targets=all \
    --with-sysroot="$sysroot" --disable-nls --disable-werror > "$out/configure.log" 2>&1
# The old source unconditionally tries to regenerate optional manuals.  The
# compiler tools themselves do not require Texinfo, so disable only that step.
make -j"$jobs" MAKEINFO=true all-gas all-ld all-binutils > "$out/build.log" 2>&1
make MAKEINFO=true install-gas install-ld install-binutils > "$out/install.log" 2>&1
popd >/dev/null

mkdir -p "$out/target-tools"
declare -A tools=(
    [as]=as [ld]=ld [ar]=ar [nm]=nm [objcopy]=objcopy [objdump]=objdump
    [ranlib]=ranlib [readelf]=readelf [strip]=strip
)
for name in "${!tools[@]}"; do
    tool="$out/install/bin/${tools[$name]}"
    [[ -x "$tool" ]] || { echo "missing installed tool: $tool" >&2; exit 1; }
    ln -s "$out/install/bin/${tools[$name]}" "$out/target-tools/k1om-mpss-linux-$name"
done

printf 'kmov %%eax, %%k1\nvpackstorelq %%zmm0, (%%rax)\nret\n' > "$out/imci.s"
"$out/install/bin/as" --64 -march=k1om -o "$out/imci.o" "$out/imci.s"
"$out/install/bin/ld" --sysroot="$sysroot" -m elf_k1om -o "$out/imci" "$out/imci.o"
"$out/install/bin/readelf" -h "$out/imci" | grep -F 'Machine:                           Intel K1OM'
"$out/install/bin/objdump" -d "$out/imci" | grep -F 'vpackstorelq'
{
    echo "source_sha256=$actual_sha256"
    echo "sysroot=$sysroot"
    find "$out/install" -type f -print0 | sort -z | xargs -0 sha256sum
} > "$out/SHA256SUMS"
echo "XPR_K1OM_BINUTILS=PASS"
