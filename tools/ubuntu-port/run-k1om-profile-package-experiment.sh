#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  run-k1om-profile-package-experiment.sh --tools-dir DIR [options]

Build the first local K1OM bootstrap .deb package, index it in a local archive,
install it into MPSS MicDir, boot mic0, verify the second-stage profile, and
restore stock.

options:
  --payload-rootfs DIR    private payload rootfs
  --mic NAME              default mic0
  --micdir DIR            default /var/mpss/MIC
  --run-root DIR          default /root/xeon-phi-revival-local/ubuntu-port-runs
  --expected-conf-sha SHA expected stock /etc/mpss/MIC.conf SHA-256

Run this on the MPSS host. Outputs are private because the .deb contains
locally supplied K1OM binaries and Python payloads.
USAGE
}

tools_dir=""
payload_rootfs="${PAYLOAD_ROOTFS:-/root/xeon-phi-revival-local/uos-rootfs/k1om-demo-python-fixed-20260727-233215}"
mic="mic0"
micdir=""
run_root="/root/xeon-phi-revival-local/ubuntu-port-runs"
expected_conf_sha="${EXPECTED_CONF_SHA:-c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9}"
connect_timeout=6

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools-dir) tools_dir="${2:-}"; shift 2 ;;
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --mic) mic="${2:-}"; shift 2 ;;
    --micdir) micdir="${2:-}"; shift 2 ;;
    --run-root) run_root="${2:-}"; shift 2 ;;
    --expected-conf-sha) expected_conf_sha="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$tools_dir" ]]; then
  usage
  exit 2
fi

micdir="${micdir:-/var/mpss/$mic}"
stock_conf="/etc/mpss/$mic.conf"
run_dir="$run_root/k1om-profile-package-$(date -u +%Y%m%d-%H%M%S)"
backup_dir="$run_dir/backups"
created_list="$run_dir/created.list"
existed_list="$run_dir/existed.list"
mkdir -p "$backup_dir"
exec > >(tee "$run_dir/run.log") 2>&1

log() { printf '%s\n' "$*"; }

require_path() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    echo "required path missing: $path" >&2
    exit 10
  fi
}

backup_overlay_path() {
  local rel="$1"
  local target="$micdir/$rel"
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$backup_dir/$(dirname "$rel")"
    cp -a "$target" "$backup_dir/$rel"
    printf '%s\n' "$rel" >> "$existed_list"
  else
    printf '%s\n' "$rel" >> "$created_list"
  fi
}

safe_remove_overlay() {
  local rel="$1"
  case "$rel" in
    etc/init.d/xeon-phi-revival-stage2|etc/rc5.d/S78xeon-phi-revival-stage2|opt/xeon-phi-revival|var/log/xeon-phi-revival)
      rm -rf -- "$micdir/$rel"
      ;;
    *)
      echo "refusing to remove unexpected overlay path: $rel" >&2
      ;;
  esac
}

restore_overlay() {
  set +e
  log "== restoring package overlay =="
  if [[ -f "$created_list" ]]; then
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      safe_remove_overlay "$rel"
    done < "$created_list"
  fi
  if [[ -f "$existed_list" ]]; then
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      safe_remove_overlay "$rel"
      mkdir -p "$micdir/$(dirname "$rel")"
      cp -a "$backup_dir/$rel" "$micdir/$rel"
    done < "$existed_list"
  fi
}

wait_online() {
  local label="$1"
  local i
  for ((i = 1; i <= 18; i++)); do
    log "${label}_status_poll_$i"
    micctrl --status || true
    micctrl --status 2>/dev/null | grep -q "$mic: online" && return 0
    sleep 5
  done
  return 1
}

stock_boot_and_verify() {
  set +e
  log "== restore stock boot =="
  restore_overlay
  micctrl --shutdown "$mic" || true
  sleep 5
  micctrl --updateramfs "$mic" || true
  timeout 120 systemctl restart mpss || true
  sleep 8
  if ! micctrl --status 2>/dev/null | grep -q "$mic: online"; then
    micctrl --boot "$mic" || true
  fi
  wait_online restore || true
  sleep 8
  log "== stock verification =="
  micctrl --status || true
  systemctl is-active mpss || true
  sha256sum "$stock_conf" || true
  if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout="$connect_timeout" "$mic" \
      'echo stock_ssh_ok; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; cat /proc/1/comm'; then
    return 0
  fi

  log "== stock verification retry after ready-state boot =="
  timeout 120 systemctl restart mpss || true
  sleep 8
  micctrl --boot "$mic" || true
  wait_online retry || true
  sleep 8
  ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout="$connect_timeout" "$mic" \
    'echo stock_ssh_ok_after_retry; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; cat /proc/1/comm'
}

trap 'stock_boot_and_verify >/dev/null 2>&1 || true' EXIT

log "== K1OM profile package experiment =="
date -u
log "run_dir=$run_dir"
log "tools_dir=$tools_dir"
log "payload_rootfs=$payload_rootfs"
log "mic=$mic"
log "micdir=$micdir"

for tool in build-k1om-profile-deb.sh index-k1om-local-archive.sh install-k1om-profile-deb-to-micdir.sh; do
  require_path "$tools_dir/$tool"
done
require_path "$payload_rootfs"
require_path "$micdir"
require_path "$stock_conf"

actual_conf_sha="$(sha256sum "$stock_conf" | awk '{print $1}')"
log "active_conf_sha=$actual_conf_sha"
if [[ -n "$expected_conf_sha" && "$actual_conf_sha" != "$expected_conf_sha" ]]; then
  echo "stock config hash mismatch; expected $expected_conf_sha" >&2
  exit 11
fi

log "== baseline =="
micctrl --status || true
systemctl is-active mpss || true
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout="$connect_timeout" "$mic" \
  'echo baseline_ssh_ok; test ! -e /var/log/xeon-phi-revival/stage2.log && echo no_stage2_log; cat /proc/1/comm' || true

log "== build local k1om profile deb =="
bash "$tools_dir/build-k1om-profile-deb.sh" --payload-rootfs "$payload_rootfs" --out-dir "$run_dir"
bash "$tools_dir/index-k1om-local-archive.sh" "$run_dir/repo"
deb="$(find "$run_dir/repo/pool" -type f -name 'xeon-phi-revival-profile_*_k1om.deb' | sort | tail -1)"
require_path "$deb"
log "deb=$deb"
log "packages_file=$run_dir/repo/dists/noble/main/binary-k1om/Packages"
grep -E '^(Package|Version|Architecture|Filename|SHA256):' "$run_dir/repo/dists/noble/main/binary-k1om/Packages"

for rel in etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 opt/xeon-phi-revival var/log/xeon-phi-revival; do
  backup_overlay_path "$rel"
done

log "== install package into MicDir =="
bash "$tools_dir/install-k1om-profile-deb-to-micdir.sh" --deb "$deb" --micdir "$micdir"
for key_path in \
  "$micdir/opt/xeon-phi-revival" \
  "$micdir/opt/xeon-phi-revival/bin" \
  "$micdir/opt/xeon-phi-revival/python" \
  "$micdir/opt/xeon-phi-revival/share" \
  "$micdir/etc/init.d/xeon-phi-revival-stage2" \
  "$micdir/etc/rc5.d/S78xeon-phi-revival-stage2"; do
  [[ -e "$key_path" || -L "$key_path" ]] && ls -ld "$key_path"
done

log "== restart MPSS with package-installed profile =="
timeout 120 systemctl restart mpss || true
wait_online custom || true
sleep 12

log "== verify package-installed profile =="
custom_ok=0
for i in 1 2 3 4; do
  log "ssh_poll_$i"
  if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout="$connect_timeout" "$mic" \
      'echo package_profile_ssh_ok; cat /proc/1/comm; echo ===profile===; cat /opt/xeon-phi-revival/profile.env; echo ===stage2-log===; cat /var/log/xeon-phi-revival/stage2.log; echo ===hello===; cat /var/log/xeon-phi-revival/hello-knc.out; echo ===python===; cat /var/log/xeon-phi-revival/python-core.out'; then
    custom_ok=1
    break
  fi
  sleep 6
done
if [[ "$custom_ok" != "1" ]]; then
  echo "package-installed profile verification failed" >&2
  exit 20
fi

verify_log="$run_dir/custom-verify.txt"
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout="$connect_timeout" "$mic" \
  'cat /opt/xeon-phi-revival/profile.env; echo ===stage2===; cat /var/log/xeon-phi-revival/stage2.log; echo ===hello===; cat /var/log/xeon-phi-revival/hello-knc.out; echo ===python===; cat /var/log/xeon-phi-revival/python-core.out' > "$verify_log"

grep -q 'XPR_PROFILE_KIND=stock-init-handoff-second-stage' "$verify_log"
grep -q 'hello_rc=0' "$verify_log"
grep -q 'python_rc=0' "$verify_log"
grep -q 'machine=k1om' "$verify_log"
grep -q 'python stage2 demo ok' "$verify_log"

trap - EXIT
if stock_boot_and_verify; then
  log "PASS: package-built K1OM profile installed, ran, and rolled back"
  exit 0
fi

echo "package profile passed, but stock rollback verification failed" >&2
exit 30
