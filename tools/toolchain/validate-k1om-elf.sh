#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 1 ]] || { echo "usage: validate-k1om-elf.sh BINARY" >&2; exit 2; }
binary=$1
[[ -f "$binary" ]] || { echo "binary not found: $binary" >&2; exit 1; }
readelf_bin=${XPR_READELF:-readelf}
"$readelf_bin" -h "$binary" | grep -F 'Machine:                           Intel K1OM'
"$readelf_bin" -l "$binary" | grep -F 'Requesting program interpreter: /lib64/ld-linux-k1om.so.2'
"$readelf_bin" -d "$binary" | grep -F 'Shared library: [libgcc_s.so.1]'
if "$readelf_bin" -d "$binary" | grep -E '/opt/mpss|/usr/lib64|x86_64' >/dev/null; then
  echo "host or SDK runtime path leaked into dynamic metadata" >&2
  exit 1
fi
echo "XPR_K1OM_ELF=PASS"
