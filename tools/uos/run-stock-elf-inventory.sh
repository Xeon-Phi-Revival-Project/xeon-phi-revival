#!/usr/bin/env bash
set -euo pipefail

rootfs="${1:-${UOS_PRIVATE_ROOTFS:-}}"
out_public="${2:-${UOS_PUBLIC_OUT:-artifacts/public}}"

if [[ -z "${rootfs}" ]]; then
  echo "usage: $0 /private/path/to/extracted-rootfs [public-output-dir]" >&2
  echo "or set UOS_PRIVATE_ROOTFS" >&2
  exit 2
fi

if [[ ! -d "${rootfs}" ]]; then
  echo "rootfs directory not found: ${rootfs}" >&2
  exit 3
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "${repo_root}/${out_public}" "${repo_root}/docs/uos"

python3 "${repo_root}/tools/uos/elf_inventory.py" \
  --rootfs "${rootfs}" \
  --csv "${repo_root}/${out_public}/uos-elf-inventory.csv" \
  --graph "${repo_root}/${out_public}/uos-dependency-graph.json" \
  --md "${repo_root}/docs/uos/stock-uos-elf-inventory.md" \
  --deps-md "${repo_root}/docs/uos/stock-uos-library-dependencies.md"
