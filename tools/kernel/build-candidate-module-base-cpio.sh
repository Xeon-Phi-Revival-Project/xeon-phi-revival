#!/bin/bash
set -euo pipefail

usage() {
  echo "usage: $0 --base-cpio FILE --module-root DIR --output FILE --report FILE" >&2
}

base_cpio= module_root= output= report=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --base-cpio) base_cpio=$2; shift 2 ;;
    --module-root) module_root=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --report) report=$2; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[ -f "$base_cpio" ] && [ -d "$module_root" ] && [ -n "$output" ] && [ -n "$report" ] || { usage; exit 2; }

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
modules=(dma/dma_module.ko micscif/ringbuffer.ko micscif/micscif.ko mpssboot/mpssboot.ko vnet/intel_micveth.ko)
args=()
for relative in "${modules[@]}"; do
  module="$module_root/$relative"
  [ -f "$module" ] || { echo "missing module: $module" >&2; exit 1; }
  readelf -h "$module" | grep -q 'Machine:.*Intel K1OM' || { echo "not K1OM: $module" >&2; exit 1; }
  args+=(--replace-entry-file "lib/modules/2.6.38.8+mpss3.4.10/extra/$relative=$module")
done
python "$repo_root/tools/uos/newc_archive.py" --source "$base_cpio" --output "$output" --report "$report" "${args[@]}"
