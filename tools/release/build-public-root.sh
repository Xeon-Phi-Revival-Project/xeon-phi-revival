#!/usr/bin/env bash
# Build a final XPR root/payload only from source-accounted build outputs.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: build-public-root.sh --ledger FILE --busybox FILE --dropbear FILE \
  --eglibc-libdir DIR --libgcc FILE --helpers DIR --out-dir DIR

No historical root CPIO is accepted or consumed. Each input must be an explicit
source-built public component selected by the release ledger.
EOF
}

ledger= busybox= dropbear= eglibc_libdir= libgcc= helpers= out_dir=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ledger) ledger=$2; shift 2 ;;
    --busybox) busybox=$2; shift 2 ;;
    --dropbear) dropbear=$2; shift 2 ;;
    --eglibc-libdir) eglibc_libdir=$2; shift 2 ;;
    --libgcc) libgcc=$2; shift 2 ;;
    --helpers) helpers=$2; shift 2 ;;
    --out-dir) out_dir=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
for value in "$ledger" "$busybox" "$dropbear" "$eglibc_libdir" "$libgcc" "$helpers" "$out_dir"; do
  [[ -n "$value" ]] || { usage; exit 2; }
done
[[ -f "$ledger" && -f "$busybox" && -f "$dropbear" && -d "$eglibc_libdir" && -f "$libgcc" && -d "$helpers" ]] || {
  echo "one or more source-accounted root inputs are missing" >&2; exit 3;
}
[[ ! -e "$out_dir" ]] || { echo "refusing to overwrite output: $out_dir" >&2; exit 4; }

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
mkdir -p "$out_dir"
python "$repo_root/tools/release/build-public-clean-root.py" \
  --ledger "$ledger" --out-root "$out_dir/root" --busybox "$busybox" \
  --dropbear "$dropbear" --eglibc-libdir "$eglibc_libdir" --libgcc "$libgcc" \
  --xpr-bin-dir "$helpers" --init-source "$repo_root/src/uos/xpr_rc_root_init.sh"
python "$repo_root/tools/release/pack-public-clean-root.py" \
  --root "$out_dir/root" --output "$out_dir/xpr-rootfs.cpio.gz" \
  --manifest "$out_dir/payload-manifest.json"
sha256sum "$out_dir/xpr-rootfs.cpio.gz" > "$out_dir/SHA256SUMS"
printf 'construction_inputs=source-accounted-only\nprivate_cpio_inputs=0\n' > "$out_dir/BUILD-INPUTS.txt"
