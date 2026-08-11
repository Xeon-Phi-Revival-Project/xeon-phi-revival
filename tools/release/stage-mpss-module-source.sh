#!/bin/bash
# Stage complete corresponding source for the five shipped K1OM modules.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: stage-mpss-module-source.sh --source-archive FILE \
       --dependency-manifest FILE --out-dir DIR

The source archive must be supplied locally. The output contains source and
metadata only; no module binaries or MPSS runtime payloads are accepted.
EOF
}

source_archive=
dependency_manifest=
out_dir=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --source-archive) source_archive=$2; shift 2 ;;
        --dependency-manifest) dependency_manifest=$2; shift 2 ;;
        --out-dir) out_dir=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in "$source_archive" "$dependency_manifest" "$out_dir"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done
[ -f "$source_archive" ] || { echo "missing source archive" >&2; exit 1; }
[ -f "$dependency_manifest" ] || { echo "missing dependency manifest" >&2; exit 1; }
[ ! -e "$out_dir" ] || { echo "output already exists: $out_dir" >&2; exit 1; }

readonly archive_sha=0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54
readonly copying_sha=8177f97513213526df2cf6184d8ff986c675afb514d4e68a404010521b880643
actual=$(sha256sum "$source_archive" | awk '{print $1}')
[ "$actual" = "$archive_sha" ] || { echo "source archive hash mismatch" >&2; exit 1; }

repo_root=$(git rev-parse --show-toplevel)
mkdir -p "$out_dir/source" "$out_dir/metadata" "$out_dir/build"
tar -xjf "$source_archive" -C "$out_dir/source"

[ -f "$out_dir/source/COPYING" ] || { echo "source archive lacks COPYING" >&2; exit 1; }
actual=$(sha256sum "$out_dir/source/COPYING" | awk '{print $1}')
[ "$actual" = "$copying_sha" ] || { echo "COPYING hash mismatch" >&2; exit 1; }

bad=$(find "$out_dir/source" -type f \( -name '*.ko' -o -name '*.o' \
    -o -name '*.a' -o -name '*.so' -o -name '*.rpm' -o -name '*.deb' \) -print)
[ -z "$bad" ] || { echo "binary files found in source archive: $bad" >&2; exit 1; }

cp "$dependency_manifest" "$out_dir/metadata/clean-dependencies.json"
cp "$repo_root/manifests/release/mpss-modules-3.4.10-source-map.json" \
    "$out_dir/metadata/source-map.json"
cp "$repo_root/tools/kernel/build-candidate-mpss-modules.sh" \
    "$out_dir/build/build-candidate-mpss-modules.sh"
cp "$repo_root/docs/kernel/module-source-audit.md" \
    "$out_dir/metadata/module-source-audit.md"

cat > "$out_dir/README.md" <<'EOF'
# XPR K1OM module corresponding source

This directory contains the complete hash-verified `mpss-modules-3.4.10`
source archive contents used for the five XPR-OS K1OM modules. The dependency
manifest maps each tested binary to its implementation files and to kernel,
generated, and toolchain dependencies. Build the sources against the separately
supplied, exactly mapped Solros K1OM kernel source/build tree using the included
script. See `source/COPYING` and the per-file evidence in the manifests.
EOF

(cd "$out_dir" && find . -type f ! -name SHA256SUMS -print0 | sort -z \
    | xargs -0 sha256sum > SHA256SUMS)
echo "PASS: staged complete module corresponding source: $out_dir"
