#!/bin/bash
set -euo pipefail

usage() {
  echo "usage: $0 --base-cpio FILE --module-root DIR --kernel-release RELEASE --output FILE --report FILE" >&2
}

base_cpio= module_root= kernel_release= output= report=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --base-cpio) base_cpio=$2; shift 2 ;;
    --module-root) module_root=$2; shift 2 ;;
    --kernel-release) kernel_release=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --report) report=$2; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[ -f "$base_cpio" ] && [ -d "$module_root" ] && [ -n "$kernel_release" ] && [ -n "$output" ] && [ -n "$report" ] || { usage; exit 2; }
[[ "$kernel_release" =~ ^[A-Za-z0-9.+_-]+$ ]] || { echo "invalid kernel release" >&2; exit 2; }

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
modules=(dma/dma_module.ko micscif/ringbuffer.ko micscif/micscif.ko mpssboot/mpssboot.ko vnet/intel_micveth.ko)
args=()
metadata_dir=$(mktemp -d)
trap 'rm -rf "$metadata_dir"' EXIT
modules_dep="$metadata_dir/modules.dep"
cat > "$modules_dep" <<EOF
extra/dma/dma_module.ko:
extra/micscif/ringbuffer.ko:
extra/micscif/micscif.ko: extra/micscif/ringbuffer.ko extra/dma/dma_module.ko
extra/mpssboot/mpssboot.ko: extra/micscif/micscif.ko
extra/vnet/intel_micveth.ko: extra/dma/dma_module.ko
EOF
for relative in "${modules[@]}"; do
  module="$module_root/$relative"
  [ -f "$module" ] || { echo "missing module: $module" >&2; exit 1; }
  readelf -h "$module" | grep -q 'Machine:.*Intel K1OM' || { echo "not K1OM: $module" >&2; exit 1; }
  args+=(--add-entry-from "lib/modules/$kernel_release/extra/$relative=$module")
done
python "$repo_root/tools/uos/newc_archive.py" --source "$base_cpio" --output "$output" --report "$report" \
  --add-directory "lib/modules/$kernel_release" \
  --add-directory "lib/modules/$kernel_release/extra" \
  --add-directory "lib/modules/$kernel_release/extra/dma" \
  --add-directory "lib/modules/$kernel_release/extra/micscif" \
  --add-directory "lib/modules/$kernel_release/extra/mpssboot" \
  --add-directory "lib/modules/$kernel_release/extra/vnet" \
  --add-entry-from "lib/modules/$kernel_release/modules.dep=$modules_dep" \
  "${args[@]}"
