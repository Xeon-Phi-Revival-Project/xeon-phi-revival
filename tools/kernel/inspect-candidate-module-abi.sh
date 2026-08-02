#!/bin/bash
# Compare five stock MPSS modules with candidate-kernel rebuilds offline.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: inspect-candidate-module-abi.sh --stock-extra DIR --rebuilt-root DIR \
       --kernel-build DIR --output DIR --target-binutils-prefix PREFIX

Inputs and report output remain external. The script performs no module load,
MPSS operation, or hardware access.
EOF
}

stock_extra=
rebuilt_root=
kernel_build=
output_dir=
binutils_prefix=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --stock-extra) stock_extra=$2; shift 2 ;;
        --rebuilt-root) rebuilt_root=$2; shift 2 ;;
        --kernel-build) kernel_build=$2; shift 2 ;;
        --output) output_dir=$2; shift 2 ;;
        --target-binutils-prefix) binutils_prefix=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in "$stock_extra" "$rebuilt_root" "$kernel_build" "$output_dir" "$binutils_prefix"; do
    [ -n "$required" ] || { usage >&2; exit 2; }
done

[ -d "$stock_extra" ] || { echo "missing stock module root" >&2; exit 1; }
[ -d "$rebuilt_root" ] || { echo "missing rebuilt module root" >&2; exit 1; }
[ -f "$kernel_build/Module.symvers" ] || { echo "missing candidate Module.symvers" >&2; exit 1; }
[ -f "$rebuilt_root/Module.symvers" ] || { echo "missing rebuilt module Module.symvers" >&2; exit 1; }
[ ! -e "$output_dir" ] || { echo "output already exists: $output_dir" >&2; exit 1; }
[ -x "${binutils_prefix}nm" ] || { echo "missing target nm" >&2; exit 1; }
[ -x "${binutils_prefix}readelf" ] || { echo "missing target readelf" >&2; exit 1; }

mkdir -p "$output_dir/modules"
kernel_exports="$output_dir/candidate-kernel-exports.txt"
awk 'NF >= 2 { print $2 }' "$kernel_build/Module.symvers" | sort -u > "$kernel_exports"

declare -A rebuilt_exports=()
modules=(
    'dma/dma_module.ko'
    'micscif/ringbuffer.ko'
    'micscif/micscif.ko'
    'mpssboot/mpssboot.ko'
    'vnet/intel_micveth.ko'
)

for relative in "${modules[@]}"; do
    rebuilt="$rebuilt_root/$relative"
    [ -f "$rebuilt" ] || { echo "missing rebuilt module: $rebuilt" >&2; exit 1; }
    module_name=${relative##*/}
    module_name=${module_name%.ko}
    awk -v module="$module_name" '$3 ~ ("/" module "$") { print $2 }' \
        "$rebuilt_root/Module.symvers" | sort -u > "$output_dir/modules/${relative//\//_}.exports.txt"
    while IFS= read -r symbol; do
        [ -z "$symbol" ] || rebuilt_exports["$symbol"]=1
    done < "$output_dir/modules/${relative//\//_}.exports.txt"
done

printf 'module\tstock_sha256\trebuilt_sha256\tstock_vermagic\trebuilt_vermagic\tstock_depends\trebuilt_depends\tundefined_total\tkernel_exports\tmodule_exports\tkernel_nonexport\tabsent\n' \
    > "$output_dir/summary.tsv"

for relative in "${modules[@]}"; do
    stock="$stock_extra/$relative"
    rebuilt="$rebuilt_root/$relative"
    name=${relative//\//_}
    [ -f "$stock" ] || { echo "missing stock module: $stock" >&2; exit 1; }

    "${binutils_prefix}readelf" -h "$stock" > "$output_dir/modules/$name.stock.elf-header.txt"
    "${binutils_prefix}readelf" -h "$rebuilt" > "$output_dir/modules/$name.rebuilt.elf-header.txt"
    grep -F 'Machine:                           Intel K1OM' "$output_dir/modules/$name.stock.elf-header.txt" >/dev/null
    grep -F 'Machine:                           Intel K1OM' "$output_dir/modules/$name.rebuilt.elf-header.txt" >/dev/null
    "${binutils_prefix}readelf" -S "$stock" > "$output_dir/modules/$name.stock.sections.txt"
    "${binutils_prefix}readelf" -S "$rebuilt" > "$output_dir/modules/$name.rebuilt.sections.txt"
    modinfo "$stock" > "$output_dir/modules/$name.stock.modinfo.txt"
    modinfo "$rebuilt" > "$output_dir/modules/$name.rebuilt.modinfo.txt"
    "${binutils_prefix}nm" -u "$stock" | awk '{print $NF}' | sort -u > "$output_dir/modules/$name.stock.undefined.txt"
    "${binutils_prefix}nm" -u "$rebuilt" | awk '{print $NF}' | sort -u > "$output_dir/modules/$name.rebuilt.undefined.txt"
    "${binutils_prefix}nm" -g --defined-only "$stock" > "$output_dir/modules/$name.stock.defined.txt"
    "${binutils_prefix}nm" -g --defined-only "$rebuilt" > "$output_dir/modules/$name.rebuilt.defined.txt"
    : > "$output_dir/modules/$name.rebuilt.symbol-classification.tsv"

    kernel_count=0
    module_count=0
    nonexport_count=0
    absent_count=0
    while IFS= read -r symbol; do
        [ -n "$symbol" ] || continue
        if grep -Fxq "$symbol" "$kernel_exports"; then
            class=kernel_export
            kernel_count=$((kernel_count + 1))
        elif [ -n "${rebuilt_exports[$symbol]+set}" ]; then
            class=rebuilt_module_export
            module_count=$((module_count + 1))
        elif grep -Eq "[[:space:]]$symbol$" "$kernel_build/System.map"; then
            class=kernel_nonexport
            nonexport_count=$((nonexport_count + 1))
        else
            class=absent
            absent_count=$((absent_count + 1))
        fi
        printf '%s\t%s\n' "$symbol" "$class" >> "$output_dir/modules/$name.rebuilt.symbol-classification.tsv"
    done < "$output_dir/modules/$name.rebuilt.undefined.txt"

    stock_sha=$(sha256sum "$stock" | awk '{print $1}')
    rebuilt_sha=$(sha256sum "$rebuilt" | awk '{print $1}')
    stock_vermagic=$(modinfo -F vermagic "$stock")
    rebuilt_vermagic=$(modinfo -F vermagic "$rebuilt")
    stock_depends=$(modinfo -F depends "$stock")
    rebuilt_depends=$(modinfo -F depends "$rebuilt")
    undefined_total=$(wc -l < "$output_dir/modules/$name.rebuilt.undefined.txt" | tr -d ' ')
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$relative" "$stock_sha" "$rebuilt_sha" "$stock_vermagic" "$rebuilt_vermagic" \
        "$stock_depends" "$rebuilt_depends" "$undefined_total" "$kernel_count" \
        "$module_count" "$nonexport_count" "$absent_count" >> "$output_dir/summary.tsv"
done

if awk -F '\t' 'NR > 1 && ($11 != 0 || $12 != 0) { exit 1 }' "$output_dir/summary.tsv"; then
    echo 'STATIC_SYMBOL_CLOSURE=PASS'
else
    echo 'STATIC_SYMBOL_CLOSURE=BLOCKED' >&2
    exit 1
fi
