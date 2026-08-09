#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: build-split-root-control.sh --bootstrap-source FILE --payload-source FILE --out-dir DIR
                                   [--package-repo DIR]
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
package_repo=""
cross_compile="${CROSS_COMPILE:-k1om-mpss-linux-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bootstrap-source) bootstrap_source="${2:-}"; shift 2 ;;
    --payload-source) payload_source="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --package-repo) package_repo="${2:-}"; shift 2 ;;
    --cross-compile) cross_compile="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

[[ -f "$bootstrap_source" && -f "$payload_source" && -n "$out_dir" ]] || { usage; exit 2; }
[[ -z "$package_repo" || -d "$package_repo" ]] || { echo "package repo not found: $package_repo" >&2; exit 2; }
[[ ! -e "$out_dir" ]] || { echo "output already exists: $out_dir" >&2; exit 3; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$out_dir"

cc_name="${cross_compile}gcc"
cc="$(command -v "$cc_name" 2>/dev/null || true)"
if [[ -z "$cc" ]] \
    && [[ "$cross_compile" == "k1om-mpss-linux-" ]] \
    && [[ -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  host_path="$PATH"
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
  cc="$(command -v "$cc_name" 2>/dev/null || true)"
  PATH="$host_path"
  export PATH
fi
[[ -x "$cc" ]] || { echo "missing K1OM compiler: $cc_name" >&2; exit 10; }
"$cc" -Os -static -s -Wall -Wextra \
  -o "$out_dir/xpr-rc-init" "$repo_root/src/uos/xpr_rc_init_trampoline.c"
"$cc" -Os -static -s -Wall -Wextra \
  -o "$out_dir/xpr-switch-root" "$repo_root/src/uos/xpr_switch_root.c"
for binary in "$out_dir/xpr-rc-init" "$out_dir/xpr-switch-root"; do
  readelf -h "$binary" | grep -q 'Machine:.*Intel K1OM' || {
    echo "project init helper is not K1OM: $binary" >&2; exit 11;
  }
  if readelf -l "$binary" | grep -q 'Requesting program interpreter'; then
    echo "project init helper is not static: $binary" >&2; exit 11
  fi
done

payload_args=(
  --source "$payload_source"
  --rc-init "$out_dir/xpr-rc-init"
  --rc-init-script "$repo_root/src/uos/xpr_rc_root_init.sh"
  --out-dir "$out_dir/payload"
)
[[ -z "$package_repo" ]] || payload_args+=(--package-repo "$package_repo")
"$repo_root/tools/release/prepare-xpr-rootfs-payload.sh" "${payload_args[@]}"

python "$repo_root/tools/uos/newc_archive.py" \
  --source "$bootstrap_source" \
  --output "$out_dir/xpr-bootstrap-root.cpio.gz" \
  --report "$out_dir/xpr-bootstrap-root.report" \
  --replace-entry-file "sbin/init=$repo_root/src/uos/xpr_clean_root_init.sh" \
  --replace-entry-file "opt/xeon-phi-revival/bin/xpr-stage-root=$repo_root/src/uos/xpr_stage_root.sh" \
  --add-entry-from "bin/xpr-switch-root=$out_dir/xpr-switch-root" \
  --set-mode sbin/init=0755 \
  --set-mode opt/xeon-phi-revival/bin/xpr-stage-root=0755 \
  --assert-executable sbin/init \
  --assert-executable opt/xeon-phi-revival/bin/xpr-stage-root \
  --assert-executable bin/xpr-switch-root

python "$repo_root/tools/uos/newc_archive.py" \
  --source "$(dirname "$bootstrap_source")/xpr-bootstrap-base.cpio.gz" \
  --output "$out_dir/xpr-bootstrap-base.cpio.gz" \
  --report "$out_dir/xpr-bootstrap-base.report" \
  --replace-entry-file "xpr-rootfs.cpio.gz=$out_dir/xpr-bootstrap-root.cpio.gz"

grep -q XPR_HANDOFF "$repo_root/src/uos/xpr_clean_root_init.sh"
grep -q XPR_STAGE "$repo_root/src/uos/xpr_stage_root.sh"
grep -q 'XPR_RC_INIT_ENTERED > /dev/console' "$repo_root/src/uos/xpr_rc_root_init.sh"
grep -q XPR_RC_TRAMPOLINE_ENTERED "$repo_root/src/uos/xpr_rc_init_trampoline.c"
grep -q XPR_SWITCH_HELPER_ENTERED "$repo_root/src/uos/xpr_switch_root.c"
gzip -t "$out_dir/xpr-bootstrap-base.cpio.gz"
gzip -t "$out_dir/payload/xpr-rootfs.cpio.gz"
sha256sum "$out_dir/xpr-bootstrap-root.cpio.gz" "$out_dir/xpr-bootstrap-base.cpio.gz" \
  "$out_dir/payload/xpr-rootfs.cpio.gz" > "$out_dir/SHA256SUMS"
wc -c "$out_dir/xpr-bootstrap-root.cpio.gz" "$out_dir/xpr-bootstrap-base.cpio.gz" \
  "$out_dir/payload/xpr-rootfs.cpio.gz" > "$out_dir/SIZES"
printf 'bootstrap_source=%s\npayload_source=%s\npackage_repo=%s\n' \
  "$bootstrap_source" "$payload_source" "${package_repo:-none}" > "$out_dir/inputs.txt"
printf 'out_dir=%s\n' "$out_dir"
