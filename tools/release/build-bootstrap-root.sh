#!/usr/bin/env bash
# Build the split-root bootstrap filesystem without a historical CPIO input.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: build-bootstrap-root.sh --ledger FILE --busybox FILE --dropbear FILE \
  --eglibc-libdir DIR --libgcc FILE --helpers DIR --cross-compile PREFIX --out-dir DIR

Builds the inner bootstrap root used by the project-owned outer Base CPIO. No
historical bootstrap/root CPIO is accepted or consumed.
EOF
}

ledger= busybox= dropbear= eglibc_libdir= libgcc= helpers= cross_compile= out_dir=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ledger) ledger=$2; shift 2 ;;
    --busybox) busybox=$2; shift 2 ;;
    --dropbear) dropbear=$2; shift 2 ;;
    --eglibc-libdir) eglibc_libdir=$2; shift 2 ;;
    --libgcc) libgcc=$2; shift 2 ;;
    --helpers) helpers=$2; shift 2 ;;
    --cross-compile) cross_compile=$2; shift 2 ;;
    --out-dir) out_dir=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
for value in "$ledger" "$busybox" "$dropbear" "$eglibc_libdir" "$libgcc" "$helpers" "$cross_compile" "$out_dir"; do
  [[ -n "$value" ]] || { usage; exit 2; }
done
[[ ! -e "$out_dir" ]] || { echo "refusing to overwrite output: $out_dir" >&2; exit 3; }
command -v "${cross_compile}gcc" >/dev/null 2>&1 || { echo "missing ${cross_compile}gcc" >&2; exit 4; }

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
mkdir -p "$out_dir"
python "$repo_root/tools/release/build-public-clean-root.py" \
  --ledger "$ledger" --out-root "$out_dir/root" --busybox "$busybox" \
  --dropbear "$dropbear" --eglibc-libdir "$eglibc_libdir" --libgcc "$libgcc" \
  --xpr-bin-dir "$helpers" --init-source "$repo_root/src/uos/xpr_clean_root_init.sh"
install -d -m 0755 "$out_dir/root/opt/xeon-phi-revival/bin"
install -m 0755 "$repo_root/src/uos/xpr_stage_root.sh" "$out_dir/root/opt/xeon-phi-revival/bin/xpr-stage-root"
"${cross_compile}gcc" -Os -static -s -Wall -Wextra -o "$out_dir/root/bin/xpr-switch-root" \
  "$repo_root/src/uos/xpr_switch_root.c"
"${cross_compile}readelf" -h "$out_dir/root/bin/xpr-switch-root" | grep -q 'Machine:.*Intel K1OM'
"${cross_compile}readelf" -l "$out_dir/root/bin/xpr-switch-root" | grep -q 'Requesting program interpreter' && {
  echo "bootstrap switch helper is unexpectedly dynamic" >&2; exit 5;
} || true
python "$repo_root/tools/release/pack-public-clean-root.py" \
  --root "$out_dir/root" --output "$out_dir/xpr-bootstrap-root.cpio.gz" \
  --manifest "$out_dir/bootstrap-manifest.json"
sha256sum "$out_dir/xpr-bootstrap-root.cpio.gz" > "$out_dir/SHA256SUMS"
printf 'construction_inputs=source-accounted-only\nprivate_cpio_inputs=0\n' > "$out_dir/BUILD-INPUTS.txt"
