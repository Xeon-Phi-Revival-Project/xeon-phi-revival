#!/usr/bin/env bash
set -euo pipefail

tools_dir="${1:-}"
payload_rootfs="${2:-}"
out_dir="${3:-}"
runtime_root="${4:-${K1OM_RUNTIME_ROOT:-}}"
python312_root="${5:-${K1OM_PYTHON312_ROOT:-}}"
libffi_root="${6:-${K1OM_LIBFFI_ROOT:-}}"
libc_root="${K1OM_LIBC_ROOT:-}"
if [[ -z "$tools_dir" || -z "$payload_rootfs" || -z "$out_dir" ]]; then
  echo "usage: $0 TOOLS_DIR PAYLOAD_ROOTFS OUT_DIR [RUNTIME_ROOT] [PYTHON312_ROOT] [LIBFFI_ROOT]" >&2
  echo "optional env: K1OM_LIBC_ROOT" >&2
  exit 2
fi

first="$out_dir/first"
second="$out_dir/second"
mkdir -p "$out_dir"
rm -rf "$first" "$second"

build_args=(--payload-rootfs "$payload_rootfs")
if [[ -n "$libc_root" ]]; then
  build_args+=(--libc-root "$libc_root")
fi
if [[ -n "$runtime_root" ]]; then
  build_args+=(--runtime-root "$runtime_root")
fi
if [[ -n "$python312_root" ]]; then
  build_args+=(--python312-root "$python312_root")
fi
if [[ -n "$libffi_root" ]]; then
  build_args+=(--libffi-root "$libffi_root")
fi
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1704067200}" bash "$tools_dir/build-k1om-bootstrap-packages.sh" "${build_args[@]}" --out-dir "$first"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1704067200}" bash "$tools_dir/build-k1om-bootstrap-packages.sh" "${build_args[@]}" --out-dir "$second"

find "$first/repo/pool" -type f -name '*.deb' -printf '%P\n' | LC_ALL=C sort > "$out_dir/first-files.txt"
find "$second/repo/pool" -type f -name '*.deb' -printf '%P\n' | LC_ALL=C sort > "$out_dir/second-files.txt"
cmp "$out_dir/first-files.txt" "$out_dir/second-files.txt"

: > "$out_dir/package-determinism.tsv"
while IFS= read -r rel; do
  first_hash="$(sha256sum "$first/repo/pool/$rel" | awk '{print $1}')"
  second_hash="$(sha256sum "$second/repo/pool/$rel" | awk '{print $1}')"
  printf '%s\t%s\t%s\n' "$rel" "$first_hash" "$second_hash" >> "$out_dir/package-determinism.tsv"
  [[ "$first_hash" == "$second_hash" ]] || { echo "hash mismatch: $rel" >&2; exit 10; }
done < "$out_dir/first-files.txt"

cat > "$out_dir/package-determinism-summary.txt" <<EOF
status=passed
source_date_epoch=${SOURCE_DATE_EPOCH:-1704067200}
package_count=$(wc -l < "$out_dir/first-files.txt")
checks=same_package_names,same_sha256
details=$out_dir/package-determinism.tsv
EOF

echo "determinism_summary=$out_dir/package-determinism-summary.txt"
