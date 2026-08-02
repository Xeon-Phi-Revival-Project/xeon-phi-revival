#!/bin/bash
# Build externally supplied MPSS module sources against a K1OM kernel build.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-candidate-mpss-modules.sh --kernel-source DIR --kernel-build DIR \
       --module-source DIR --cross-compile PREFIX [--jobs N]

The inputs remain external. This script does not install or load modules and
does not interact with MPSS or micctrl.
EOF
}

kernel_source=
kernel_build=
module_source=
cross_compile=
jobs=2

while [ "$#" -gt 0 ]; do
    case "$1" in
        --kernel-source) kernel_source=$2; shift 2 ;;
        --kernel-build) kernel_build=$2; shift 2 ;;
        --module-source) module_source=$2; shift 2 ;;
        --cross-compile) cross_compile=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in "$kernel_source" "$kernel_build" "$module_source" "$cross_compile"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done

[ -f "$kernel_source/Makefile" ] || { echo "missing kernel source" >&2; exit 1; }
[ -f "$kernel_build/.config" ] || { echo "missing kernel build config" >&2; exit 1; }
[ -f "$kernel_build/Module.symvers" ] || { echo "missing kernel Module.symvers" >&2; exit 1; }
[ -f "$module_source/Kbuild" ] || { echo "missing module Kbuild" >&2; exit 1; }
[ -x "${cross_compile}gcc" ] || { echo "missing compiler: ${cross_compile}gcc" >&2; exit 1; }

make -C "$kernel_source" -j"$jobs" ARCH=k1om CROSS_COMPILE="$cross_compile" \
    O="$kernel_build" M="$module_source" MIC_CARD_ARCH=k1om modules

required_modules=(
    dma/dma_module.ko
    micscif/ringbuffer.ko
    micscif/micscif.ko
    mpssboot/mpssboot.ko
    vnet/intel_micveth.ko
)
for module in "${required_modules[@]}"; do
    [ -f "$module_source/$module" ] || { echo "missing built module: $module" >&2; exit 1; }
    readelf -h "$module_source/$module" | grep -F 'Machine:                           Intel K1OM'
done

sha256sum "${required_modules[@]/#/$module_source/}"
