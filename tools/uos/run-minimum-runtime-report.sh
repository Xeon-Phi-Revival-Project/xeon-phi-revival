#!/usr/bin/env bash
set -euo pipefail

rootfs="${1:-${UOS_PRIVATE_ROOTFS:-}}"
if [[ -z "${rootfs}" ]]; then
  echo "usage: $0 /private/path/to/extracted-rootfs" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "${repo_root}/tools/uos/minimum_runtime_report.py" \
  --rootfs "${rootfs}" \
  --out "${repo_root}/docs/toolchain/minimum-k1om-runtime.md"
