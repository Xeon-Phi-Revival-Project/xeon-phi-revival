#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  boot-k1om-uos-rc-micdir.sh --tools-dir DIR --payload-rootfs DIR --libc-root DIR --runtime-root DIR --python312-root DIR --libffi-root DIR [--mic mic0] [--run-root DIR]

Build, install, boot, smoke-test, and roll back a reversible Xeon Phi Revival
K1OM uOS release-candidate profile through the proven MPSS MicDir lane.
USAGE
}

tools_dir=""
payload_rootfs=""
libc_root=""
runtime_root=""
python312_root=""
libffi_root=""
mic="mic0"
run_root="/root/xeon-phi-revival-local/uos-rc-live-runs"
expected_conf_sha="${EXPECTED_CONF_SHA:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools-dir) tools_dir="${2:-}"; shift 2 ;;
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --libc-root) libc_root="${2:-}"; shift 2 ;;
    --runtime-root) runtime_root="${2:-}"; shift 2 ;;
    --python312-root) python312_root="${2:-}"; shift 2 ;;
    --libffi-root) libffi_root="${2:-}"; shift 2 ;;
    --mic) mic="${2:-}"; shift 2 ;;
    --run-root) run_root="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$tools_dir" && -d "$tools_dir" ]] || { echo "missing --tools-dir" >&2; exit 2; }
for path in "$payload_rootfs" "$libc_root" "$runtime_root" "$python312_root" "$libffi_root"; do
  [[ -n "$path" && -d "$path" ]] || { echo "required input directory missing: $path" >&2; exit 2; }
done
[[ -n "$expected_conf_sha" ]] || { echo "EXPECTED_CONF_SHA must be set before live boot" >&2; exit 3; }

run_dir="$run_root/xpr-uos-rc-live-$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$run_dir"
exec > >(tee "$run_dir/boot.log") 2>&1

rollback_cmd=""
cleanup() {
  set +e
  if [[ -n "$rollback_cmd" && -x "$rollback_cmd" ]]; then
    "$rollback_cmd" | tee "$run_dir/rollback-from-trap.log"
  fi
}
trap cleanup EXIT

echo "== Xeon Phi Revival K1OM uOS RC live boot =="
date -u
echo "run_dir=$run_dir"

EXPECTED_CONF_SHA="$expected_conf_sha" bash "$tools_dir/run-k1om-bootstrap-package-set-experiment.sh" \
  --tools-dir "$tools_dir" \
  --payload-rootfs "$payload_rootfs" \
  --libc-root "$libc_root" \
  --runtime-root "$runtime_root" \
  --python312-root "$python312_root" \
  --libffi-root "$libffi_root" \
  --mic "$mic" \
  --run-root "$run_dir" \
  --leave-running

package_run="$(find "$run_dir" -maxdepth 1 -type d -name 'k1om-bootstrap-package-set-*' | sort | tail -1)"
[[ -n "$package_run" && -x "$package_run/rollback-stock.sh" ]] || { echo "rollback script missing under $run_dir" >&2; exit 30; }
rollback_cmd="$package_run/rollback-stock.sh"

bash "$tools_dir/run-k1om-uos-rc-smoke.sh" --mic "$mic" --out-dir "$run_dir/release-smoke"

trap - EXIT
"$rollback_cmd" | tee "$run_dir/rollback.log"

grep -q 'stock_ssh_ok' "$run_dir/rollback.log"
grep -q 'profile_absent' "$run_dir/rollback.log"
grep -q 'init' "$run_dir/rollback.log"

cat > "$run_dir/live-rc-summary.txt" <<EOF
status=passed
run_dir=$run_dir
package_run=$package_run
smoke_log=$run_dir/release-smoke/uos-rc-smoke.log
rollback_log=$run_dir/rollback.log
ssh=passed
package_install=passed
rollback=passed
EOF

cat "$run_dir/live-rc-summary.txt"
