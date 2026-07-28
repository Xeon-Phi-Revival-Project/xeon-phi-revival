#!/usr/bin/env bash
set -euo pipefail

rootfs="${1:-}"
if [[ -z "$rootfs" || ! -d "$rootfs" ]]; then
  echo "usage: $0 ROOTFS" >&2
  exit 2
fi

required_paths=(
  /init
  /bin/sh
  /usr/bin/hello-knc
  /usr/bin/python3.5
  /usr/share/knc-demo/python-core-pid1.py
  /lib64/ld-linux-k1om.so.2
  /lib64/libc.so.6
)

missing=0
for path in "${required_paths[@]}"; do
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

if [[ ! -x "$rootfs/init" ]]; then
  echo "/init is not executable" >&2
  exit 11
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

if ! command -v readelf >/dev/null 2>&1; then
  echo "readelf not found; cannot validate ELF machine or dependencies" >&2
  exit 13
fi

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
    for base in /lib64 /usr/lib64 /lib /usr/lib; do
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

if [[ "$elf_status" -ne 0 ]]; then
  exit 14
fi

echo "bootable K1OM rootfs validation passed"
