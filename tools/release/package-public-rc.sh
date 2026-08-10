#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: package-public-rc.sh --out-dir DIR [--revision REV] [--version VERSION]

Create a deterministic source/metadata XPR-OS prerelease archive from tracked
Git content. This command never includes private boot images or untracked local
inputs.
USAGE
}

out_dir=""
revision="HEAD"
version="0.1.0-rc1"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --revision) revision="${2:-}"; shift 2 ;;
    --version) version="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$out_dir" ]] || { usage; exit 2; }
for cmd in git tar gzip sha256sum awk grep mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "required host tool missing: $cmd" >&2
    exit 10
  }
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
git cat-file -e "$revision^{commit}"
commit="$(git rev-parse "$revision^{commit}")"

if [[ "$revision" == "HEAD" ]] &&
   { ! git diff --quiet || ! git diff --cached --quiet; }; then
  echo "refusing to package a dirty tracked worktree" >&2
  exit 11
fi

mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
archive="$out_dir/xpr-os-$version-source.tar.gz"
metadata="$out_dir/xpr-os-$version-build-metadata.txt"
checksums="$out_dir/SHA256SUMS"
tmp_tar="$(mktemp "${TMPDIR:-/tmp}/xpr-os-rc.XXXXXX.tar")"
tmp_list="$(mktemp "${TMPDIR:-/tmp}/xpr-os-rc.XXXXXX.list")"
trap 'rm -f "$tmp_tar" "$tmp_list"' EXIT

git archive --format=tar --prefix="xpr-os-$version/" -o "$tmp_tar" "$commit"
tar -tf "$tmp_tar" > "$tmp_list"

forbidden='\.(rpm|deb|ko|bin|img|rom|fw|elf|o|a|so([.][0-9]+)*)$|(^|/)(private|stock-uos|sysroot|k1om-sysroot|mpss-packages|artifacts/private)/'
if grep -Eiq "$forbidden" "$tmp_list"; then
  echo "archive audit rejected a private/binary payload:" >&2
  grep -Ei "$forbidden" "$tmp_list" >&2
  exit 12
fi

gzip -n -9 -c "$tmp_tar" > "$archive"
cat > "$metadata" <<EOF
name=XPR-OS
version=$version
release_kind=source-metadata-byo-mpss-prerelease
git_commit=$commit
source_date_epoch=$source_date_epoch
archive=$(basename "$archive")
tracked_members=$(wc -l < "$tmp_list" | awk '{print $1}')
private_binary_payloads_included=0
intel_mpss_payloads_included=0
redistribution_boundary=locally-built boot images and MPSS inputs are excluded
EOF

(cd "$out_dir" && sha256sum "$(basename "$archive")" "$(basename "$metadata")" > "$(basename "$checksums")")
(cd "$out_dir" && sha256sum -c "$(basename "$checksums")")

echo "archive=$archive"
echo "metadata=$metadata"
echo "checksums=$checksums"
echo "commit=$commit"
