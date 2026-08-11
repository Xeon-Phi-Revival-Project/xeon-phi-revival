#!/usr/bin/env bash
# Construct RC5's two project-owned CPIO containers without historical CPIO input.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: build-rc5-containers.sh --busybox FILE --dropbear FILE --eglibc-libdir DIR \
  --libgcc FILE --helpers DIR --module-root DIR --cross-compile PREFIX \
  --kernel-release RELEASE --out-dir DIR [--ledger FILE]

All inputs are individually source-accounted build outputs. This command does
not accept, unpack, or transform a historical bootstrap or final-root CPIO.
EOF
}

busybox= dropbear= eglibc_libdir= libgcc= helpers= module_root= cross_compile=
kernel_release= out_dir= ledger=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --busybox) busybox=$2; shift 2 ;;
    --dropbear) dropbear=$2; shift 2 ;;
    --eglibc-libdir) eglibc_libdir=$2; shift 2 ;;
    --libgcc) libgcc=$2; shift 2 ;;
    --helpers) helpers=$2; shift 2 ;;
    --module-root) module_root=$2; shift 2 ;;
    --cross-compile) cross_compile=$2; shift 2 ;;
    --kernel-release) kernel_release=$2; shift 2 ;;
    --out-dir) out_dir=$2; shift 2 ;;
    --ledger) ledger=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
for value in "$busybox" "$dropbear" "$eglibc_libdir" "$libgcc" "$helpers" "$module_root" "$cross_compile" "$kernel_release" "$out_dir"; do
  [[ -n "$value" ]] || { usage; exit 2; }
done
[[ ! -e "$out_dir" ]] || { echo "refusing to overwrite output: $out_dir" >&2; exit 3; }

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
ledger=${ledger:-"$repo_root/manifests/release/prebuilt-clean-profile.json"}
[[ -f "$ledger" ]] || { echo "missing public component ledger: $ledger" >&2; exit 4; }

mkdir -p "$out_dir"
bash "$repo_root/tools/release/build-public-root.sh" \
  --ledger "$ledger" --busybox "$busybox" --dropbear "$dropbear" \
  --eglibc-libdir "$eglibc_libdir" --libgcc "$libgcc" --helpers "$helpers" \
  --out-dir "$out_dir/final-root"
bash "$repo_root/tools/release/build-bootstrap-root.sh" \
  --ledger "$ledger" --busybox "$busybox" --dropbear "$dropbear" \
  --eglibc-libdir "$eglibc_libdir" --libgcc "$libgcc" --helpers "$helpers" \
  --cross-compile "$cross_compile" --out-dir "$out_dir/bootstrap-root"
bash "$repo_root/tools/kernel/build-public-bootstrap-base.sh" \
  --bootstrap-root "$out_dir/bootstrap-root/xpr-bootstrap-root.cpio.gz" \
  --busybox "$busybox" --early-init "$repo_root/src/uos/xpr_clean_root_early_init.sh" \
  --module-root "$module_root" --kernel-release "$kernel_release" \
  --output "$out_dir/xpr-bootstrap.cpio.gz" --manifest "$out_dir/base-cpio-manifest.json"

{
  printf 'construction_inputs=source-accounted-only\n'
  printf 'private_cpio_inputs=0\n'
  sha256sum "$out_dir/xpr-bootstrap.cpio.gz" "$out_dir/bootstrap-root/xpr-bootstrap-root.cpio.gz" "$out_dir/final-root/xpr-rootfs.cpio.gz"
} > "$out_dir/SHA256SUMS"
echo "RC5_CONTAINER_BUILD=PASS out_dir=$out_dir"
