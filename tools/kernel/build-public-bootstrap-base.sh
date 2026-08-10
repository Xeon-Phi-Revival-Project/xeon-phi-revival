#!/usr/bin/env bash
# Build the outer K1OM Base CPIO needed before the staged bootstrap root runs.
set -euo pipefail

usage() {
  echo "usage: $0 --bootstrap-root FILE --busybox FILE --early-init FILE --module-root DIR --kernel-release RELEASE --output FILE --manifest FILE" >&2
}

bootstrap_root= busybox= early_init= module_root= kernel_release= output= manifest=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap-root) bootstrap_root=$2; shift 2 ;;
    --busybox) busybox=$2; shift 2 ;;
    --early-init) early_init=$2; shift 2 ;;
    --module-root) module_root=$2; shift 2 ;;
    --kernel-release) kernel_release=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --manifest) manifest=$2; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$bootstrap_root" && -f "$busybox" && -f "$early_init" && -d "$module_root" && -n "$kernel_release" && -n "$output" && -n "$manifest" ]] || { usage; exit 2; }
[[ "$kernel_release" =~ ^[A-Za-z0-9.+_-]+$ ]] || { echo "invalid kernel release" >&2; exit 2; }
[[ ! -e "$output" && ! -e "$manifest" ]] || { echo "refusing to overwrite output" >&2; exit 2; }

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
readelf -h "$busybox" | grep -q 'Machine:.*Intel K1OM'
readelf -d "$busybox" 2>/dev/null | grep -q NEEDED && { echo "BusyBox must be static" >&2; exit 3; } || true
head -1 "$early_init" | grep -qx '#!/xpr-tools/busybox sh'

modules=(dma/dma_module.ko micscif/ringbuffer.ko micscif/micscif.ko mpssboot/mpssboot.ko vnet/intel_micveth.ko)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/xpr-tools" "$stage/etc" "$stage/proc" "$stage/sys" "$stage/new_root" \
  "$stage/lib/modules/$kernel_release/extra/dma" "$stage/lib/modules/$kernel_release/extra/micscif" \
  "$stage/lib/modules/$kernel_release/extra/mpssboot" "$stage/lib/modules/$kernel_release/extra/vnet"
install -m 0755 "$early_init" "$stage/init"
install -m 0755 "$busybox" "$stage/xpr-tools/busybox"
install -m 0644 "$bootstrap_root" "$stage/xpr-rootfs.cpio.gz"
for relative in "${modules[@]}"; do
  source="$module_root/$relative"
  target="$stage/lib/modules/$kernel_release/extra/$relative"
  [[ -f "$source" ]] || { echo "missing module: $source" >&2; exit 4; }
  readelf -h "$source" | grep -q 'Machine:.*Intel K1OM' || { echo "not K1OM: $source" >&2; exit 4; }
  install -m 0644 "$source" "$target"
done
cat > "$stage/lib/modules/$kernel_release/modules.dep" <<'EOF'
extra/dma/dma_module.ko:
extra/micscif/ringbuffer.ko:
extra/micscif/micscif.ko: extra/micscif/ringbuffer.ko extra/dma/dma_module.ko
extra/mpssboot/mpssboot.ko: extra/micscif/micscif.ko
extra/vnet/intel_micveth.ko: extra/dma/dma_module.ko
EOF
python "$repo_root/tools/release/pack-public-clean-root.py" --root "$stage" --output "$output" --manifest "$manifest"
gzip -t "$output"
