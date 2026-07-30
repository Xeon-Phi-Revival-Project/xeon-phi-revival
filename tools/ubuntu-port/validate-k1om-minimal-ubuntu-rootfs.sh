#!/usr/bin/env bash
set -euo pipefail

rootfs="${1:-}"
if [[ -z "$rootfs" || ! -d "$rootfs" ]]; then
  echo "usage: $0 ROOTFS" >&2
  exit 2
fi

required=(
  /etc/os-release
  /etc/lsb-release
  /etc/passwd
  /etc/group
  /etc/hostname
  /etc/hosts
  /etc/profile
  /etc/apt/sources.list
  /var/lib/dpkg/status
  /var/lib/dpkg/info/base-files-k1om.list
  /bin/sh
  /bin/ls
  /usr/bin/python3
  /usr/bin/python3.12
  /usr/bin/dpkg
  /usr/bin/dpkg-query
  /usr/bin/dpkg-deb
  /usr/bin/apt-get
  /usr/bin/apt-cache
  /usr/bin/pcietool
  /opt/xeon-phi-revival/bin/hello-knc
  /opt/xeon-phi-revival/share/python312-smoke.py
  /opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2
  /opt/xeon-phi-revival/lib64/libc.so.6
  /lib64/ld-linux-k1om.so.2
  /lib64/libc.so.6
  /dev/null
  /dev/zero
  /dev/console
  /proc
  /sys
  /tmp
  /root
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
[[ "$missing" -eq 0 ]] || exit 10

grep -q '^ID=xpr-uos$' "$rootfs/etc/os-release" || { echo "os-release missing ID=xpr-uos" >&2; exit 11; }
grep -q '^ID_LIKE=ubuntu$' "$rootfs/etc/os-release" || { echo "os-release missing ID_LIKE=ubuntu" >&2; exit 11; }
grep -Eq '^VERSION_CODENAME="?noble"?$' "$rootfs/etc/os-release" || { echo "os-release missing noble codename" >&2; exit 12; }
grep -Eq '^XPR_ARCH="?k1om"?$' "$rootfs/etc/os-release" || { echo "os-release missing XPR_ARCH k1om marker" >&2; exit 13; }
grep -q '^deb \[trusted=yes arch=k1om\] file:/opt/xeon-phi-revival/repo noble main$' "$rootfs/etc/apt/sources.list" || { echo "sources.list does not point at local k1om archive" >&2; exit 14; }
grep -q '^Package: python3.12-minimal-k1om$' "$rootfs/var/lib/dpkg/status" || { echo "dpkg status missing python3.12-minimal-k1om" >&2; exit 15; }

if [[ ! -L "$rootfs/usr/bin/python3" ]]; then
  echo "/usr/bin/python3 should be a minimal-rootfs symlink to python3.12" >&2
  exit 16
fi
[[ "$(readlink "$rootfs/usr/bin/python3")" == "python3.12" ]] || { echo "/usr/bin/python3 does not point to python3.12" >&2; exit 17; }

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
[[ "$broken" -eq 0 ]] || exit 18

if command -v readelf >/dev/null 2>&1; then
  elf_status=0
  while IFS= read -r -d '' elf; do
    if ! head -c 4 "$elf" | grep -q $'^\x7fELF'; then
      continue
    fi
    machine="$(od -An -j18 -N2 -tu2 "$elf" | awk '{print $1}')"
    rel="/${elf#"$rootfs"/}"
    echo "e_machine $rel=$machine"
    if [[ "$machine" != "181" ]]; then
      echo "expected K1OM e_machine 181 for $rel" >&2
      elf_status=1
    fi
    while IFS= read -r lib; do
      [[ -z "$lib" ]] && continue
      found=0
      for base in /lib64 /usr/lib64 /opt/xeon-phi-revival/lib64; do
        if [[ -e "$rootfs$base/$lib" || -L "$rootfs$base/$lib" ]]; then
          found=1
          break
        fi
      done
      if [[ "$found" -eq 0 ]]; then
        echo "missing runtime dependency for $rel: $lib" >&2
        elf_status=1
      fi
    done < <(readelf -d "$elf" 2>/dev/null | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p')
  done < <(find "$rootfs" -type f -print0)
  [[ "$elf_status" -eq 0 ]] || exit 19
else
  echo "readelf not found; skipping ELF validation" >&2
fi

echo "minimal Ubuntu-shaped K1OM rootfs validation passed"
