#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  run-micdir-second-stage-service-experiment.sh --phase PHASE [options]

Run a reversible MPSS MicDir rc5 second-stage service experiment. The service
runs after stock init/sysvinit starts the normal MPSS uOS stack, writes logs
under /var/log/xeon-phi-revival, optionally runs K1OM payloads, and leaves stock
PID 1 untouched.

phases:
  marker   prove the rc5 project service ran
  hello    run /opt/xeon-phi-revival/bin/hello-knc
  python   run hello-knc plus a core Python 3.5 smoke with python3.5 -S
  profile  install the project uOS profile layout and run the python phase

options:
  --mic NAME              MIC target, default mic0
  --micdir DIR            MPSS MicDir, default /var/mpss/MIC
  --payload-rootfs DIR    private K1OM payload rootfs, default:
                          /root/xeon-phi-revival-local/uos-rootfs/k1om-demo-python-fixed-20260727-233215
  --run-root DIR          private host output root, default:
                          /root/xeon-phi-revival-local/uos-boot-builds
  --expected-conf-sha SHA expected stock /etc/mpss/MIC.conf SHA-256
  --ssh-polls N          capped SSH verification attempts, default 6

This script modifies only the MPSS MicDir overlay and restores stock before
exit. It does not flash firmware or overwrite stock MPSS base images.
USAGE
}

mic="mic0"
phase=""
micdir=""
payload_rootfs="${PAYLOAD_ROOTFS:-/root/xeon-phi-revival-local/uos-rootfs/k1om-demo-python-fixed-20260727-233215}"
run_root="/root/xeon-phi-revival-local/uos-boot-builds"
expected_conf_sha="${EXPECTED_CONF_SHA:-c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9}"
ssh_polls=6
connect_timeout=6

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mic) mic="${2:-}"; shift 2 ;;
    --micdir) micdir="${2:-}"; shift 2 ;;
    --phase) phase="${2:-}"; shift 2 ;;
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --run-root) run_root="${2:-}"; shift 2 ;;
    --expected-conf-sha) expected_conf_sha="${2:-}"; shift 2 ;;
    --ssh-polls) ssh_polls="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

case "$phase" in
  marker|hello|python|profile) ;;
  *) echo "invalid or missing --phase: $phase" >&2; usage; exit 2 ;;
esac

micdir="${micdir:-/var/mpss/$mic}"
stock_conf="/etc/mpss/$mic.conf"
run_dir="$run_root/micdir-second-stage-${phase}-$(date -u +%Y%m%d-%H%M%S)"
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
  log "== restoring MicDir second-stage overlay =="
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
      'echo stock_ssh_ok; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; cat /proc/1/comm'; then
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
    'echo stock_ssh_ok_after_retry; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; cat /proc/1/comm'
}

trap 'stock_boot_and_verify >/dev/null 2>&1 || true' EXIT

log "== MicDir second-stage service experiment =="
date -u
log "phase=$phase"
log "run_dir=$run_dir"
log "mic=$mic"
log "micdir=$micdir"
log "payload_rootfs=$payload_rootfs"

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

for rel in etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 opt/xeon-phi-revival var/log/xeon-phi-revival; do
  backup_overlay_path "$rel"
done

mkdir -p "$micdir/etc/init.d" "$micdir/etc/rc5.d" "$micdir/opt/xeon-phi-revival/bin" "$micdir/opt/xeon-phi-revival/lib" "$micdir/opt/xeon-phi-revival/python" "$micdir/opt/xeon-phi-revival/share" "$micdir/var/log/xeon-phi-revival"

if [[ "$phase" == "hello" || "$phase" == "python" || "$phase" == "profile" ]]; then
  require_path "$payload_rootfs/usr/bin/hello-knc"
  cp -a "$payload_rootfs/usr/bin/hello-knc" "$micdir/opt/xeon-phi-revival/bin/hello-knc"
fi

if [[ "$phase" == "python" || "$phase" == "profile" ]]; then
  require_path "$payload_rootfs/usr/bin/python3.5"
  require_path "$payload_rootfs/usr/lib/python3.5"
  cp -a "$payload_rootfs/usr/bin/python3.5" "$micdir/opt/xeon-phi-revival/bin/python3.5"
  cp -a "$payload_rootfs/usr/lib/python3.5" "$micdir/opt/xeon-phi-revival/python/python3.5"
  cat > "$micdir/opt/xeon-phi-revival/share/python-core-stage2.py" <<'PY'
import os
import sys

print("python stage2 demo ok")
print("platform=%s" % sys.platform)
print("cwd=%s" % os.getcwd())
print("prefix=%s" % sys.prefix)
print("calc=%d" % sum(range(10)))
PY
fi

cat > "$micdir/opt/xeon-phi-revival/profile.env" <<EOF
XPR_PROFILE_VERSION=0.1
XPR_PROFILE_KIND=stock-init-handoff-second-stage
XPR_PHASE=$phase
XPR_ROOT=/opt/xeon-phi-revival
EOF

cat > "$micdir/etc/init.d/xeon-phi-revival-stage2" <<'INIT'
#!/bin/sh
PATH=/opt/xeon-phi-revival/bin:/sbin:/bin:/usr/sbin:/usr/bin
XPR_ROOT=/opt/xeon-phi-revival
LOG_DIR=/var/log/xeon-phi-revival
LOG="$LOG_DIR/stage2.log"
mkdir -p "$LOG_DIR"

case "$1" in
  start)
    PHASE="${XPR_PHASE:-unknown}"
    if [ -f "$XPR_ROOT/profile.env" ]; then
      . "$XPR_ROOT/profile.env"
      PHASE="${XPR_PHASE:-$PHASE}"
    fi
    {
      echo "[stage2] start"
      echo "phase=$PHASE"
      echo "pid=$$"
      date -u 2>/dev/null || true
      uname -a 2>/dev/null || true
      echo "pid1=$(cat /proc/1/comm 2>/dev/null || true)"
      echo "network:"
      ip addr show mic0 2>/dev/null || ifconfig mic0 2>/dev/null || true
    } >> "$LOG" 2>&1

    if [ "$PHASE" = "hello" ] || [ "$PHASE" = "python" ] || [ "$PHASE" = "profile" ]; then
      if [ -x "$XPR_ROOT/bin/hello-knc" ]; then
        "$XPR_ROOT/bin/hello-knc" > "$LOG_DIR/hello-knc.out" 2>&1
        echo "hello_rc=$?" >> "$LOG"
      else
        echo "hello_rc=127" >> "$LOG"
      fi
    fi

    if [ "$PHASE" = "python" ] || [ "$PHASE" = "profile" ]; then
      if [ -x "$XPR_ROOT/bin/python3.5" ]; then
        PYTHONHOME="$XPR_ROOT" PYTHONPATH="$XPR_ROOT/python/python3.5" \
          "$XPR_ROOT/bin/python3.5" -S "$XPR_ROOT/share/python-core-stage2.py" \
          > "$LOG_DIR/python-core.out" 2>&1
        echo "python_rc=$?" >> "$LOG"
      else
        echo "python_rc=127" >> "$LOG"
      fi
    fi
    echo "[stage2] done" >> "$LOG"
    ;;
  stop)
    echo "[stage2] stop" >> "$LOG" 2>/dev/null || true
    ;;
esac
exit 0
INIT
chmod 0755 "$micdir/etc/init.d/xeon-phi-revival-stage2"
ln -sfn ../init.d/xeon-phi-revival-stage2 "$micdir/etc/rc5.d/S78xeon-phi-revival-stage2"

log "== installed overlay hashes =="
for key_path in \
  "$micdir/opt/xeon-phi-revival" \
  "$micdir/opt/xeon-phi-revival/bin" \
  "$micdir/opt/xeon-phi-revival/lib" \
  "$micdir/opt/xeon-phi-revival/python" \
  "$micdir/opt/xeon-phi-revival/share" \
  "$micdir/etc/init.d/xeon-phi-revival-stage2" \
  "$micdir/etc/rc5.d/S78xeon-phi-revival-stage2"; do
  [[ -e "$key_path" || -L "$key_path" ]] && ls -ld "$key_path"
done
for key_file in \
  "$micdir/etc/init.d/xeon-phi-revival-stage2" \
  "$micdir/opt/xeon-phi-revival/profile.env" \
  "$micdir/opt/xeon-phi-revival/bin/hello-knc" \
  "$micdir/opt/xeon-phi-revival/bin/python3.5" \
  "$micdir/opt/xeon-phi-revival/share/python-core-stage2.py"; do
  [[ -f "$key_file" ]] && sha256sum "$key_file"
done

log "== restart MPSS with second-stage service overlay =="
timeout 120 systemctl restart mpss || true
wait_online custom || true
sleep 12

log "== bounded second-stage verification =="
custom_ok=0
for ((i = 1; i <= ssh_polls; i++)); do
  log "ssh_poll_$i"
  if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout="$connect_timeout" "$mic" \
      'echo stage2_ssh_ok; cat /proc/1/comm; echo ===profile===; cat /opt/xeon-phi-revival/profile.env 2>/dev/null || true; echo ===stage2-log===; cat /var/log/xeon-phi-revival/stage2.log; echo ===hello===; cat /var/log/xeon-phi-revival/hello-knc.out 2>/dev/null || true; echo ===python===; cat /var/log/xeon-phi-revival/python-core.out 2>/dev/null || true'; then
    custom_ok=1
    break
  fi
  sleep 6
done

if [[ "$custom_ok" != "1" ]]; then
  echo "second-stage verification failed" >&2
  exit 20
fi

verify_log="$run_dir/custom-verify.txt"
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout="$connect_timeout" "$mic" \
  'cat /var/log/xeon-phi-revival/stage2.log; echo ===hello===; cat /var/log/xeon-phi-revival/hello-knc.out 2>/dev/null || true; echo ===python===; cat /var/log/xeon-phi-revival/python-core.out 2>/dev/null || true' > "$verify_log"

grep -q '\[stage2\] start' "$verify_log"
case "$phase" in
  marker)
    grep -q 'phase=marker' "$verify_log"
    ;;
  hello)
    grep -q 'hello_rc=0' "$verify_log"
    grep -q 'machine=k1om' "$verify_log"
    ;;
  python|profile)
    grep -q 'hello_rc=0' "$verify_log"
    grep -q 'python_rc=0' "$verify_log"
    grep -q 'python stage2 demo ok' "$verify_log"
    ;;
esac

trap - EXIT
if stock_boot_and_verify; then
  log "PASS: second-stage phase $phase verified and stock rollback verified"
  exit 0
fi

echo "phase $phase passed, but stock rollback verification failed" >&2
exit 30
