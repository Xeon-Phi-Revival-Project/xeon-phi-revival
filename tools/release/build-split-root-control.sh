#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: build-split-root-control.sh --bootstrap-source FILE --payload-source FILE --out-dir DIR
                                   [--cross-compile PREFIX]

Build private split-root control artifacts from explicitly supplied private
archives. The output contains a rebuilt bootstrap root, Base CPIO, full-root
payload, checksums, and archive reports. It never accesses MPSS configuration
or boots a card.
USAGE
}

bootstrap_source=""
payload_source=""
out_dir=""
cross_compile="${CROSS_COMPILE:-k1om-mpss-linux-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap-source) bootstrap_source="${2:-}"; shift 2 ;;
    --payload-source) payload_source="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --cross-compile) cross_compile="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

[[ -f "$bootstrap_source" && -f "$payload_source" && -n "$out_dir" ]] || { usage; exit 2; }
[[ ! -e "$out_dir" ]] || { echo "output already exists: $out_dir" >&2; exit 3; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$out_dir"

cc="${cross_compile}gcc"
command -v "$cc" >/dev/null || { echo "missing K1OM compiler: $cc" >&2; exit 10; }
"$cc" -Os -static -s -Wall -Wextra \
  -o "$out_dir/xpr-rc-init" "$repo_root/src/uos/xpr_rc_init_trampoline.c"
readelf -h "$out_dir/xpr-rc-init" | grep -q 'Machine:.*Intel K1OM' || {
  echo "RC init trampoline is not K1OM" >&2; exit 11;
}
if readelf -l "$out_dir/xpr-rc-init" | grep -q 'Requesting program interpreter'; then
  echo "RC init trampoline is not static" >&2; exit 11
fi

"$repo_root/tools/release/prepare-xpr-rootfs-payload.sh" \
  --source "$payload_source" \
  --rc-init "$out_dir/xpr-rc-init" \
  --rc-init-script "$repo_root/src/uos/xpr_rc_root_init.sh" \
  --out-dir "$out_dir/payload"

python "$repo_root/tools/uos/newc_archive.py" \
  --source "$bootstrap_source" \
  --output "$out_dir/xpr-bootstrap-root.cpio.gz" \
  --report "$out_dir/xpr-bootstrap-root.report" \
  --replace-entry-file "sbin/init=$repo_root/src/uos/xpr_clean_root_init.sh" \
  --replace-entry-file "opt/xeon-phi-revival/bin/xpr-stage-root=$repo_root/src/uos/xpr_stage_root.sh" \
  --set-mode sbin/init=0755 \
  --set-mode opt/xeon-phi-revival/bin/xpr-stage-root=0755 \
  --assert-executable sbin/init \
  --assert-executable opt/xeon-phi-revival/bin/xpr-stage-root

python "$repo_root/tools/uos/newc_archive.py" \
  --source "$(dirname "$bootstrap_source")/xpr-bootstrap-base.cpio.gz" \
  --output "$out_dir/xpr-bootstrap-base.cpio.gz" \
  --report "$out_dir/xpr-bootstrap-base.report" \
  --replace-entry-file "xpr-rootfs.cpio.gz=$out_dir/xpr-bootstrap-root.cpio.gz"

grep -q XPR_HANDOFF "$repo_root/src/uos/xpr_clean_root_init.sh"
grep -q XPR_STAGE "$repo_root/src/uos/xpr_stage_root.sh"
grep -q 'XPR_RC_INIT_ENTERED > /dev/console' "$repo_root/src/uos/xpr_rc_root_init.sh"
grep -q XPR_RC_TRAMPOLINE_ENTERED "$repo_root/src/uos/xpr_rc_init_trampoline.c"
gzip -t "$out_dir/xpr-bootstrap-base.cpio.gz"
gzip -t "$out_dir/payload/xpr-rootfs.cpio.gz"
sha256sum "$out_dir/xpr-bootstrap-root.cpio.gz" "$out_dir/xpr-bootstrap-base.cpio.gz" \
  "$out_dir/payload/xpr-rootfs.cpio.gz" > "$out_dir/SHA256SUMS"
wc -c "$out_dir/xpr-bootstrap-root.cpio.gz" "$out_dir/xpr-bootstrap-base.cpio.gz" \
  "$out_dir/payload/xpr-rootfs.cpio.gz" > "$out_dir/SIZES"
printf 'bootstrap_source=%s\npayload_source=%s\n' "$bootstrap_source" "$payload_source" > "$out_dir/inputs.txt"
printf 'out_dir=%s\n' "$out_dir"
