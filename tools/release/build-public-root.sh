#!/usr/bin/env bash
# Build a final XPR root/payload only from source-accounted build outputs.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: build-public-root.sh --ledger FILE --busybox FILE --dropbear FILE \
  --eglibc-libdir DIR --libgcc FILE --helpers DIR --out-dir DIR [--python-root DIR]

No historical root CPIO is accepted or consumed. Each input must be an explicit
source-built public component selected by the release ledger.
EOF
}

ledger= busybox= dropbear= eglibc_libdir= libgcc= helpers= out_dir= python_root=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ledger) ledger=$2; shift 2 ;;
    --busybox) busybox=$2; shift 2 ;;
    --dropbear) dropbear=$2; shift 2 ;;
    --eglibc-libdir) eglibc_libdir=$2; shift 2 ;;
    --libgcc) libgcc=$2; shift 2 ;;
    --helpers) helpers=$2; shift 2 ;;
    --out-dir) out_dir=$2; shift 2 ;;
    --python-root) python_root=$2; shift 2 ;;
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
[[ -z "$python_root" || -d "$python_root" ]] || { echo "Python root is not a directory" >&2; exit 3; }

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
python_bin="${PYTHON_BIN:-/usr/bin/python2.7}"
command -v "$python_bin" >/dev/null 2>&1 || { echo "missing host Python with argparse: $python_bin" >&2; exit 5; }
"$python_bin" -c 'import argparse' || { echo "host Python lacks argparse: $python_bin" >&2; exit 5; }
mkdir -p "$out_dir"
args=(--ledger "$ledger" --out-root "$out_dir/root" --busybox "$busybox" \
  --dropbear "$dropbear" --eglibc-libdir "$eglibc_libdir" --libgcc "$libgcc" \
  --xpr-bin-dir "$helpers" --init-source "$repo_root/src/uos/xpr_rc_root_init.sh")
if [[ -n "$python_root" ]]; then
  args+=(--python-root "$python_root")
fi
"$python_bin" "$repo_root/tools/release/build-public-clean-root.py" "${args[@]}"
"$python_bin" "$repo_root/tools/release/pack-public-clean-root.py" \
  --root "$out_dir/root" --output "$out_dir/xpr-rootfs.cpio.gz" \
  --manifest "$out_dir/payload-manifest.json"
sha256sum "$out_dir/xpr-rootfs.cpio.gz" > "$out_dir/SHA256SUMS"
printf 'construction_inputs=source-accounted-only\nprivate_cpio_inputs=0\n' > "$out_dir/BUILD-INPUTS.txt"
