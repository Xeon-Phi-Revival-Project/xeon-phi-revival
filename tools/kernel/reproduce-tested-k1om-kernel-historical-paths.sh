#!/bin/bash
# Rebuild from public source while privately recreating the validated Kbuild paths.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: reproduce-tested-k1om-kernel-historical-paths.sh --source-archive FILE \
       --cross-compile PREFIX --work-root DIR [--jobs N]

The build executes in a private mount namespace. It bind-mounts staged public
source and a fresh output directory over the historical /root/xpr-kernel-* paths
without changing the preserved host directories.
EOF
}

source_archive=
cross_compile=
work_root=
jobs=2
while [ "$#" -gt 0 ]; do
    case "$1" in
        --source-archive) source_archive=$2; shift 2 ;;
        --cross-compile) cross_compile=$2; shift 2 ;;
        --work-root) work_root=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[ -n "$source_archive" ] && [ -n "$cross_compile" ] && [ -n "$work_root" ] || {
    usage >&2; exit 2;
}

work_root=$(cd "$work_root" && pwd)
stage_source="$work_root/xpr-kernel-historical-source"
stage_output="$work_root/xpr-kernel-historical-output"
[ ! -e "$stage_source" ] || { echo "staged source already exists: $stage_source" >&2; exit 1; }
[ ! -e "$stage_output" ] || { echo "staged output already exists: $stage_output" >&2; exit 1; }

extract_dir=$(mktemp -d "$work_root/.xpr-kernel-extract.XXXXXX")
source_makefile=$(tar -tf "$source_archive" | awk '/\/phi-kernel\/Makefile$/ && !found { print; found=1 } END { exit !found }')
[ -n "$source_makefile" ] || { echo "Solros archive does not contain phi-kernel/Makefile" >&2; exit 1; }
tar -xf "$source_archive" -C "$extract_dir"
source_tree="$extract_dir/${source_makefile%/Makefile}"
[ -f "$source_tree/Makefile" ] || { echo "extracted kernel source is incomplete" >&2; exit 1; }
mv "$(dirname "$source_tree")" "$stage_source"
rm -rf "$extract_dir"
mkdir "$stage_output"

script_dir=$(cd "$(dirname "$0")" && pwd)
builder="$script_dir/reproduce-tested-k1om-kernel.sh"
unshare -m bash -c '
    set -euo pipefail
    mount --make-rprivate /
    mount --bind "$1" /root/xpr-kernel-candidate-solros
    mount --bind "$2" /root/xpr-kernel-candidate-solros-build-validated
    exec "$3" --source-archive "$4" --cross-compile "$5" --work-root /root \
        --jobs "$6" --use-existing-source --use-existing-output
' bash "$stage_source" "$stage_output" "$builder" "$source_archive" "$cross_compile" "$jobs"
