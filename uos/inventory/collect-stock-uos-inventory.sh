#!/usr/bin/env bash
set -euo pipefail

out_dir="${1:-${XEON_PHI_LOCAL_ROOT:-${HOME}/xeon-phi-revival-local}/uos-inventory/$(date +%Y%m%d-%H%M%S)}"
mkdir -p "${out_dir}"

boot_dir="/usr/share/mpss/boot"
mic_root="/var/mpss/mic0"

echo "writing inventory to ${out_dir}"

{
  echo "date=$(date -Is)"
  echo "host=$(hostname)"
  echo "kernel=$(uname -r)"
  echo "mpss_status=$(micctrl --status 2>&1 | tr '\n' ' ')"
  echo "boot_dir=${boot_dir}"
  echo "mic_root=${mic_root}"
} > "${out_dir}/summary.env"

find "${boot_dir}" -maxdepth 1 -type f -printf '%p\t%s\n' | sort > "${out_dir}/boot-files.tsv"
sha256sum "${boot_dir}"/* > "${out_dir}/boot-files.sha256" 2>/dev/null || true

initramfs="$(find "${boot_dir}" -maxdepth 1 -type f -name 'initramfs-*knightscorner*.cpio.gz' | sort | head -1)"
if [[ -n "${initramfs}" ]]; then
  gzip -cd "${initramfs}" | cpio -itv > "${out_dir}/initramfs-filelist.txt" 2> "${out_dir}/initramfs-cpio.stderr" || true
fi

if [[ -d "${mic_root}" ]]; then
  find "${mic_root}" -xdev -printf '%M\t%u\t%g\t%s\t%p -> %l\n' | sort > "${out_dir}/mic0-rootfs-filelist.txt"
  find "${mic_root}" -xdev -type f -print0 | xargs -0 sha256sum > "${out_dir}/mic0-rootfs-files.sha256" 2>/dev/null || true
  find "${mic_root}" -xdev -type f -exec file {} + > "${out_dir}/mic0-rootfs-file-types.txt" 2>/dev/null || true
fi

ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 mic0 '
  echo "=== uname ==="
  uname -a
  echo "=== mounts ==="
  mount
  echo "=== cpuinfo head ==="
  sed -n "1,120p" /proc/cpuinfo
  echo "=== meminfo ==="
  sed -n "1,80p" /proc/meminfo
  echo "=== cmdline ==="
  cat /proc/cmdline
  echo "=== modules ==="
  lsmod 2>/dev/null || true
  echo "=== processes ==="
  ps w 2>/dev/null || ps
  echo "=== network ==="
  ifconfig -a 2>/dev/null || ip addr 2>/dev/null || true
  echo "=== key files ==="
  for p in /sbin/init /bin/busybox /lib64/ld-linux-k1om.so.2 /lib64/libc.so.6 /etc/inittab /etc/passwd /etc/fstab /etc/ssh/sshd_config; do
    if [ -e "$p" ]; then
      ls -l "$p"
      file "$p" 2>/dev/null || true
    else
      echo "missing $p"
    fi
  done
' > "${out_dir}/mic0-live-inventory.txt" 2>&1 || true

tar -C "$(dirname "${out_dir}")" -czf "${out_dir}.tar.gz" "$(basename "${out_dir}")"
echo "archive=${out_dir}.tar.gz"
