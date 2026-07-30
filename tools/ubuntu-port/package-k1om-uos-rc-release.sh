#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  package-k1om-uos-rc-release.sh --build-dir DIR --out-dir DIR [--include-private-payloads-i-understand]

Prepare release metadata for an eventual downloadable uOS RC. By default this
does not copy private binaries/rootfs archives; it emits manifests that separate
redistributable project metadata from payloads requiring licensing review.
USAGE
}

build_dir=""
out_dir=""
include_private=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-dir) build_dir="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --include-private-payloads-i-understand) include_private=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done
[[ -n "$build_dir" && -d "$build_dir" && -n "$out_dir" ]] || { usage; exit 2; }

mkdir -p "$out_dir"
cp -a "$build_dir/release-candidate.yml" "$out_dir/release-candidate.yml"
cp -a "$build_dir/artifact-manifest.tsv" "$out_dir/artifact-manifest.tsv"
sha256sum "$out_dir/release-candidate.yml" "$out_dir/artifact-manifest.tsv" > "$out_dir/SHA256SUMS"

cat > "$out_dir/redistribution-review.tsv" <<'EOF'
class	decision
project scripts and docs	redistributable under repository license
Ubuntu/GNU source-derived patches	review source package license before binary release
locally built K1OM binaries	review required before redistribution
Intel MPSS SDK/sysroot/uOS/firmware/userland	must be supplied locally; do not redistribute from this repository
private rootfs archives	do not publish until every payload has a recorded redistribution decision
EOF

if [[ "$include_private" -eq 1 ]]; then
  cp -a "$build_dir/xpr-uos-0.1-k1om-rootfs.tar.gz" "$out_dir/"
  cp -a "$build_dir/xpr-uos-0.1-k1om-rootfs.tar.gz.sha256" "$out_dir/"
  echo "PRIVATE_PAYLOADS_INCLUDED=1" > "$out_dir/PRIVATE-PAYLOAD-WARNING.txt"
else
  cat > "$out_dir/README.txt" <<'EOF'
This directory intentionally contains metadata only. The generated K1OM rootfs
archive is excluded until redistribution review is complete. Rebuild locally
with tools/ubuntu-port/build-k1om-uos-rc.sh and locally supplied MPSS/K1OM
inputs.
EOF
fi

echo "release_metadata=$out_dir"
