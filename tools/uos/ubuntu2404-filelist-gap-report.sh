#!/usr/bin/env bash
set -euo pipefail

file_list="${1:-}"
manifest="${2:-uos/ubuntu2404/level1-tiny-rootfs-manifest.txt}"
out="${3:-docs/uos/ubuntu-24.04-level1-filelist-report.md}"

if [[ -z "$file_list" || ! -f "$file_list" ]]; then
  echo "usage: $0 STOCK_UOS_FILE_LIST [MANIFEST] [OUT]" >&2
  echo "missing stock uOS file list: ${file_list:-<none>}" >&2
  exit 2
fi

if [[ ! -f "$manifest" ]]; then
  echo "missing manifest: $manifest" >&2
  exit 2
fi

out_dir="${out%/*}"
if [[ "$out_dir" != "$out" ]]; then
  mkdir -p "$out_dir"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

grep -Ev '^\s*(#|$)' "$manifest" | sort -u > "$tmpdir/manifest-paths.txt"

{
  echo "# Ubuntu 24.04 uOS Level 1 File-List Report"
  echo
  echo "Public-safe path metadata report derived from a local stock uOS file list."
  echo "The raw file list should remain local-only until reviewed."
  echo
  echo "## Inputs"
  echo
  echo "- Candidate manifest: \`$manifest\`"
  echo "- Local source: user-supplied stock uOS file list"
  echo
  echo "## Candidate Paths Observed"
  echo
  while IFS= read -r path; do
    rel="${path#/}"
    if grep -Eq "(^|[[:space:]])/?${rel//\//\\/}([[:space:]]|$| -> )" "$file_list"; then
      echo "- \`$path\`"
    fi
  done < "$tmpdir/manifest-paths.txt"
  echo
  echo "## Candidate Paths Not Observed"
  echo
  while IFS= read -r path; do
    rel="${path#/}"
    if ! grep -Eq "(^|[[:space:]])/?${rel//\//\\/}([[:space:]]|$| -> )" "$file_list"; then
      echo "- \`$path\`"
    fi
  done < "$tmpdir/manifest-paths.txt"
  echo
  echo "## Interpretation"
  echo
  echo "- Missing paths may be absent, hidden by file-list format differences, or"
  echo "  intended to be created by the rootfs assembly recipe."
  echo "- This report proves only path evidence; it does not redistribute contents and"
  echo "  does not prove a replacement rootfs boots."
} > "$out"

echo "$out"
