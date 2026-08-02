#!/bin/bash
# Build an externally supplied K1OM kernel candidate out of tree.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-compatible-k1om-kernel.sh --source DIR --config FILE --output DIR \
       --cross-compile PREFIX [--source-archive FILE] [--jobs N] \
       [--build-timestamp TEXT] [--build-user TEXT] [--build-host TEXT]

All source, config, and output paths are external inputs. The script neither
downloads source nor installs, boots, or configures MPSS.
EOF
}

source_dir=
config_file=
output_dir=
cross_compile=
source_archive=
jobs=2
build_timestamp=
build_user=
build_host=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --source) source_dir=$2; shift 2 ;;
        --config) config_file=$2; shift 2 ;;
        --output) output_dir=$2; shift 2 ;;
        --cross-compile) cross_compile=$2; shift 2 ;;
        --source-archive) source_archive=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        --build-timestamp) build_timestamp=$2; shift 2 ;;
        --build-user) build_user=$2; shift 2 ;;
        --build-host) build_host=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in "$source_dir" "$config_file" "$output_dir" "$cross_compile"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done

[ -f "$source_dir/Makefile" ] || { echo "missing kernel Makefile" >&2; exit 1; }
[ -f "$source_dir/arch/x86/Kconfig" ] || { echo "missing x86 Kconfig" >&2; exit 1; }
[ -f "$config_file" ] || { echo "missing config: $config_file" >&2; exit 1; }
[ -x "${cross_compile}gcc" ] || { echo "missing compiler: ${cross_compile}gcc" >&2; exit 1; }
[ ! -e "$output_dir" ] || { echo "output already exists: $output_dir" >&2; exit 1; }

mkdir -p "$output_dir"
cp "$config_file" "$output_dir/.config"

echo "source=$(readlink -f "$source_dir")"
echo "config_sha256=$(sha256sum "$config_file" | awk '{print $1}')"
if [ -n "$source_archive" ]; then
    [ -f "$source_archive" ] || { echo "missing source archive: $source_archive" >&2; exit 1; }
    echo "source_archive_sha256=$(sha256sum "$source_archive" | awk '{print $1}')"
fi
"${cross_compile}gcc" --version | head -n 1
"${cross_compile}ld" --version | head -n 1

build_env=(env "KBUILD_BUILD_VERSION=1")
[ -z "$build_timestamp" ] || build_env+=("KBUILD_BUILD_TIMESTAMP=$build_timestamp")
[ -z "$build_user" ] || build_env+=("KBUILD_BUILD_USER=$build_user")
[ -z "$build_host" ] || build_env+=("KBUILD_BUILD_HOST=$build_host")

set +e
yes "" | "${build_env[@]}" make -C "$source_dir" ARCH=k1om CROSS_COMPILE="$cross_compile" O="$output_dir" oldconfig
config_status=${PIPESTATUS[1]}
set -e
[ "$config_status" -eq 0 ] || { echo "oldconfig failed: $config_status" >&2; exit "$config_status"; }

"${build_env[@]}" make -C "$source_dir" -j"$jobs" ARCH=k1om CROSS_COMPILE="$cross_compile" O="$output_dir" bzImage

image="$output_dir/arch/x86/boot/bzImage"
vmlinux="$output_dir/vmlinux"
system_map="$output_dir/System.map"
[ -f "$image" ] && [ -f "$vmlinux" ] && [ -f "$system_map" ]
readelf -h "$vmlinux" | grep -F 'Machine:                           Intel K1OM'
sha256sum "$image" "$vmlinux" "$system_map" "$output_dir/.config"
