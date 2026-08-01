#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: build-xpr-clean-root-base-cpio.sh --stock-base FILE --busybox FILE --rootfs-image FILE --out FILE --report FILE

Replace Base CPIO /init with the project bootstrap and add only the static
project BusyBox plus project rootfs archive required for the clean-root test.
USAGE
}

stock_base=""; busybox=""; rootfs_image=""; out=""; report=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stock-base) stock_base="${2:-}"; shift 2 ;;
    --busybox) busybox="${2:-}"; shift 2 ;;
    --rootfs-image) rootfs_image="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    --report) report="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$stock_base" && -f "$busybox" && -f "$rootfs_image" && -n "$out" && -n "$report" ]] || { usage; exit 2; }
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readelf -h "$busybox" | grep -q 'Machine:.*Intel K1OM' || { echo "BusyBox is not K1OM" >&2; exit 10; }
readelf -d "$busybox" 2>/dev/null | grep -q NEEDED && { echo "BusyBox is not static" >&2; exit 11; } || true
python "$repo_root/tools/uos/newc_archive.py" \
  --source "$stock_base" --output "$out" --report "$report" \
  --replace-entry init --replace-entry-from "$repo_root/src/uos/xpr_clean_root_early_init.sh" \
  --add-directory xpr-tools \
  --add-entry-from xpr-tools/busybox="$busybox" \
  --add-entry-from xpr-rootfs.cpio.gz="$rootfs_image"
