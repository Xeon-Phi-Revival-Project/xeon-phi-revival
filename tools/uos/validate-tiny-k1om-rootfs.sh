#!/usr/bin/env bash
set -euo pipefail

rootfs="${1:-}"
if [[ -z "$rootfs" || ! -d "$rootfs" ]]; then
  echo "usage: $0 ROOTFS" >&2
  exit 2
fi

required=(
  /sbin/init
  /bin/sh
  /bin/bash
  /bin/busybox
  /lib64/ld-linux-k1om.so.2
  /lib64/libc.so.6
  /lib64/libgcc_s.so.1
  /etc/inittab
  /etc/fstab
  /etc/passwd
)

missing=0
for path in "${required[@]}"; do
  if [[ ! -e "$rootfs/${path#/}" && ! -L "$rootfs/${path#/}" ]]; then
    echo "missing $path"
    missing=1
  else
    echo "present $path"
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 10
fi

broken=0
while IFS= read -r -d '' link; do
  target="$(readlink "$link")"
  if [[ "$target" = /* ]]; then
    resolved="$rootfs/${target#/}"
  else
    resolved="$(dirname "$link")/$target"
  fi
  if [[ ! -e "$resolved" && ! -L "$resolved" ]]; then
    echo "broken symlink /${link#"$rootfs"/} -> $target"
    broken=1
  fi
done < <(find "$rootfs" -type l -print0)

if [[ "$broken" -ne 0 ]]; then
  exit 12
fi

if command -v readelf >/dev/null 2>&1; then
  while IFS= read -r -d '' elf; do
    if head -c 4 "$elf" | grep -q $'^\x7fELF'; then
      machine="$(od -An -j18 -N2 -tu2 "$elf" | awk '{print $1}')"
      echo "e_machine ${elf#"$rootfs"}=$machine"
      if [[ "$machine" != "181" ]]; then
        echo "expected K1OM e_machine 181 for $elf" >&2
        exit 11
      fi
    fi
  done < <(find "$rootfs" -type f -print0)
fi

echo "tiny rootfs metadata validation passed"
