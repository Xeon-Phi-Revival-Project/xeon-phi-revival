#!/usr/bin/env bash
set -euo pipefail

initramfs="${1:-${UOS_INITRAMFS:-/usr/share/mpss/boot/initramfs-2.6.38+mpss3.4.10-knightscorner.cpio.gz}}"
out_dir="${2:-${UOS_PRIVATE_ROOTFS:-${XEON_PHI_LOCAL_ROOT:-${HOME}/xeon-phi-revival-local}/uos-rootfs/stock-mpss-3.4.10}}"

if [[ ! -f "${initramfs}" ]]; then
  echo "initramfs not found: ${initramfs}" >&2
  exit 2
fi

mkdir -p "${out_dir}"
if [[ -n "$(find "${out_dir}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "output directory is not empty: ${out_dir}" >&2
  echo "refusing to overwrite private rootfs" >&2
  exit 3
fi

gzip -cd "${initramfs}" | (cd "${out_dir}" && cpio -idmu --quiet)
echo "${out_dir}"
