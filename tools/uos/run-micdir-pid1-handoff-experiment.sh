#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  run-micdir-pid1-handoff-experiment.sh --phase PHASE [options]

Run a reversible MPSS MicDir /sbin/init handoff experiment on an MPSS host.
The generated init wrapper runs briefly as PID 1, writes public-safe evidence,
optionally runs a tiny payload, then execs stock /sbin/init.sysvinit.

phases:
  marker   write only the PID 1 marker, then hand off
  tiny     write marker plus uname/mount/environment evidence, then hand off
  hello    run /usr/bin/hello-knc from a private payload rootfs, then hand off
  python   run hello-knc and a Python core smoke script from a private payload
           rootfs, then hand off

options:
  --mic NAME              MIC target, default mic0
  --micdir DIR            MPSS MicDir, default /var/mpss/MIC
  --payload-rootfs DIR    private K1OM payload rootfs for hello/python phases
  --run-root DIR          private host output root, default
                          /root/xeon-phi-revival-local/uos-boot-builds
  --expected-conf-sha SHA expected stock /etc/mpss/MIC.conf SHA-256
  --ssh-polls N          capped SSH verification attempts, default 6

This script modifies only the MPSS MicDir overlay, regenerates/boots ramfs via
MPSS, then removes its overlay files and restores stock boot before exiting.
It does not flash firmware and does not overwrite stock MPSS base images.
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
    --mic)
      mic="${2:-}"
      shift 2
      ;;
    --micdir)
      micdir="${2:-}"
      shift 2
      ;;
    --phase)
      phase="${2:-}"
      shift 2
      ;;
    --payload-rootfs)
      payload_rootfs="${2:-}"
      shift 2
      ;;
    --run-root)
      run_root="${2:-}"
      shift 2
      ;;
    --expected-conf-sha)
      expected_conf_sha="${2:-}"
      shift 2
      ;;
    --ssh-polls)
      ssh_polls="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

case "$phase" in
  marker|tiny|hello|python) ;;
  *)
    echo "invalid or missing --phase: $phase" >&2
    usage
    exit 2
    ;;
esac

micdir="${micdir:-/var/mpss/$mic}"
stock_conf="/etc/mpss/$mic.conf"
run_dir="$run_root/micdir-pid1-handoff-${phase}-$(date -u +%Y%m%d-%H%M%S)"
created_list="$run_dir/created.list"
existed_list="$run_dir/existed.list"
backup_dir="$run_dir/backups"
mkdir -p "$backup_dir"
exec > >(tee "$run_dir/run.log") 2>&1

log() {
  printf '%s\n' "$*"
}

require_path() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    echo "required path missing: $path" >&2
    exit 10
  fi
}

bounded_online_wait() {
  local label="$1"
  local polls="${2:-18}"
  local i
  for ((i = 1; i <= polls; i++)); do
    log "${label}_status_poll_$i"
    micctrl --status || true
    if micctrl --status 2>/dev/null | grep -q "$mic: online"; then
      return 0
    fi
    sleep 5
  done
  return 1
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

install_file_overlay() {
  local rel="$1"
  local src="$2"
  backup_overlay_path "$rel"
  mkdir -p "$micdir/$(dirname "$rel")"
  cp -a "$src" "$micdir/$rel"
}

install_dir_overlay() {
  local rel="$1"
  local src="$2"
  backup_overlay_path "$rel"
  rm -rf -- "$micdir/$rel"
  mkdir -p "$micdir/$(dirname "$rel")"
  cp -a "$src" "$micdir/$rel"
}

remove_generated_overlay() {
  local rel="$1"
  case "$rel" in
    sbin/init|etc/issue|usr/bin/hello-knc|usr/bin/python3.5|usr/lib/python3.5|usr/share/knc-demo|usr/share/knc-demo/python-core-pid1.py)
      rm -rf -- "$micdir/$rel"
      ;;
    *)
      echo "refusing to remove unexpected overlay path: $rel" >&2
      ;;
  esac
}

restore_overlay() {
  set +e
  log "== restoring MicDir overlay =="
  if [[ -f "$created_list" ]]; then
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      remove_generated_overlay "$rel"
    done < "$created_list"
  fi
  if [[ -f "$existed_list" ]]; then
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      remove_generated_overlay "$rel"
      mkdir -p "$micdir/$(dirname "$rel")"
      cp -a "$backup_dir/$rel" "$micdir/$rel"
    done < "$existed_list"
  fi
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
  bounded_online_wait restore 18 || true
  sleep 8
  log "== stock verification =="
  micctrl --status || true
  systemctl is-active mpss || true
  sha256sum "$stock_conf" || true
  if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout="$connect_timeout" "$mic" \
      'echo stock_ssh_ok; test ! -e /project-pid1-handoff-marker.txt && echo handoff_marker_absent; cat /proc/1/comm'; then
    return 0
  fi

  log "== stock verification retry after mic reset =="
  micctrl --reset "$mic" || true
  sleep 12
  timeout 120 systemctl restart mpss || true
  sleep 8
  if ! micctrl --status 2>/dev/null | grep -q "$mic: online"; then
    micctrl --boot "$mic" || true
  fi
  bounded_online_wait reset_restore 18 || true
  sleep 8
  ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout="$connect_timeout" "$mic" \
    'echo stock_ssh_ok_after_reset; test ! -e /project-pid1-handoff-marker.txt && echo handoff_marker_absent; cat /proc/1/comm'
}

trap 'stock_boot_and_verify >/dev/null 2>&1 || true' EXIT

log "== MicDir PID 1 handoff experiment =="
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
  'echo baseline_ssh_ok; test ! -e /project-pid1-handoff-marker.txt && echo no_handoff_marker; cat /proc/1/comm' || true

if [[ "$phase" == "hello" || "$phase" == "python" ]]; then
  require_path "$payload_rootfs/usr/bin/hello-knc"
  install_file_overlay "usr/bin/hello-knc" "$payload_rootfs/usr/bin/hello-knc"
fi

if [[ "$phase" == "python" ]]; then
  require_path "$payload_rootfs/usr/bin/python3.5"
  require_path "$payload_rootfs/usr/lib/python3.5"
  python_demo_src="$payload_rootfs/usr/share/knc-demo/python-core-pid1.py"
  if [[ ! -f "$python_demo_src" ]]; then
    python_demo_src="$run_dir/python-core-pid1.py"
    cat > "$python_demo_src" <<'PY'
import os
import sys

print("python pid1 demo ok")
print("platform=%s" % sys.platform)
print("cwd=%s" % os.getcwd())
print("prefix=%s" % sys.prefix)
print("argv_len=%d" % len(sys.argv))
print("calc=%d" % sum(range(10)))
PY
  fi
  install_file_overlay "usr/bin/python3.5" "$payload_rootfs/usr/bin/python3.5"
  install_dir_overlay "usr/lib/python3.5" "$payload_rootfs/usr/lib/python3.5"
  if [[ -d "$payload_rootfs/usr/share/knc-demo" ]]; then
    install_dir_overlay "usr/share/knc-demo" "$payload_rootfs/usr/share/knc-demo"
  else
    backup_overlay_path "usr/share/knc-demo"
    rm -rf -- "$micdir/usr/share/knc-demo"
    mkdir -p "$micdir/usr/share/knc-demo"
  fi
  cp -a "$python_demo_src" "$micdir/usr/share/knc-demo/python-core-pid1.py"
fi

backup_overlay_path "sbin/init"
backup_overlay_path "etc/issue"

mkdir -p "$micdir/sbin" "$micdir/etc"
cat > "$micdir/sbin/init" <<INIT
#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
PHASE="$phase"
export PATH HOME PHASE
MARKER=/project-pid1-handoff-marker.txt
LOG=/project-pid1-handoff.log

mkdir -p /proc /sys /dev /run /tmp /var/log 2>/dev/null || true
{
  echo "project_pid1_handoff_entered=1"
  echo "project_phase=\$PHASE"
  echo "project_pid=\$\$"
  echo "project_time_utc=\$(date -u 2>/dev/null || echo unknown)"
  echo "project_cmdline=\$(cat /proc/cmdline 2>/dev/null || true)"
} > "\$MARKER" 2>/dev/null || true
{
  echo "[project-pid1-handoff] phase=\$PHASE pid=\$\$"
  cat "\$MARKER" 2>/dev/null || true
} >> "\$LOG" 2>&1 || true

case "\$PHASE" in
  tiny)
    {
      echo "tiny_action_started=1"
      uname -a 2>/dev/null || true
      echo "mounts_before_handoff:"
      cat /proc/mounts 2>/dev/null || true
      echo "environment_before_handoff:"
      env | sort 2>/dev/null || true
    } > /project-pid1-tiny-action.txt 2>&1 || true
    ;;
  hello|python)
    if [ -x /usr/bin/hello-knc ]; then
      /usr/bin/hello-knc > /project-pid1-hello.out 2>&1
      echo "hello_rc=\$?" >> "\$LOG"
    else
      echo "missing /usr/bin/hello-knc" > /project-pid1-hello.out
      echo "hello_rc=127" >> "\$LOG"
    fi
    ;;
esac

if [ "\$PHASE" = "python" ]; then
  export PYTHONHOME=/usr
  export PYTHONPATH=/usr/lib/python3.5
  if [ -x /usr/bin/python3.5 ] && [ -f /usr/share/knc-demo/python-core-pid1.py ]; then
    /usr/bin/python3.5 -S /usr/share/knc-demo/python-core-pid1.py > /project-pid1-python.out 2>&1
    echo "python_rc=\$?" >> "\$LOG"
  else
    echo "missing python core payload" > /project-pid1-python.out
    echo "python_rc=127" >> "\$LOG"
  fi
fi

echo "[project-pid1-handoff] execing /sbin/init.sysvinit" >> "\$LOG" 2>&1 || true
cat "\$MARKER" > /dev/console 2>/dev/null || true
cat "\$MARKER" > /dev/hvc0 2>/dev/null || true
exec /sbin/init.sysvinit "\$@"
echo "[project-pid1-handoff] exec failed rc=\$?" >> "\$LOG" 2>&1 || true
while true; do sleep 60; done
INIT
chmod 0755 "$micdir/sbin/init"

cat > "$micdir/etc/issue" <<ISSUE
Xeon Phi Revival Project PID 1 handoff phase $phase booted
Intel MIC Platform Software Stack (Built by Poky 7.0) 3.4.10 \\n \\l
ISSUE
chmod 0644 "$micdir/etc/issue"

log "== installed overlay hashes =="
sha256sum "$micdir/sbin/init" "$micdir/etc/issue"
find "$micdir" -maxdepth 4 \( -path "$micdir/sbin/init" -o -path "$micdir/etc/issue" -o -path "$micdir/usr/bin/hello-knc" -o -path "$micdir/usr/bin/python3.5" -o -path "$micdir/usr/lib/python3.5" -o -path "$micdir/usr/share/knc-demo" \) -printf '%M %p -> %l\n' 2>/dev/null || true

log "== restart MPSS with handoff overlay =="
timeout 120 systemctl restart mpss || true
bounded_online_wait custom 18 || true
sleep 8

log "== bounded custom verification =="
custom_ok=0
for ((i = 1; i <= ssh_polls; i++)); do
  log "ssh_poll_$i"
  if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout="$connect_timeout" "$mic" \
      'echo custom_handoff_ssh_ok; cat /etc/issue; cat /project-pid1-handoff-marker.txt; echo ===pid1===; cat /proc/1/comm; echo ===log===; cat /project-pid1-handoff.log; echo ===tiny===; cat /project-pid1-tiny-action.txt 2>/dev/null || true; echo ===hello===; cat /project-pid1-hello.out 2>/dev/null || true; echo ===python===; cat /project-pid1-python.out 2>/dev/null || true'; then
    custom_ok=1
    break
  fi
  sleep 6
done

if [[ "$custom_ok" != "1" ]]; then
  echo "custom verification failed" >&2
  exit 20
fi

verify_log="$run_dir/custom-verify.txt"
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout="$connect_timeout" "$mic" \
  'cat /project-pid1-handoff-marker.txt; echo ===log===; cat /project-pid1-handoff.log; echo ===tiny===; cat /project-pid1-tiny-action.txt 2>/dev/null || true; echo ===hello===; cat /project-pid1-hello.out 2>/dev/null || true; echo ===python===; cat /project-pid1-python.out 2>/dev/null || true' > "$verify_log"

grep -q 'project_pid=1' "$verify_log"
grep -q 'execing /sbin/init.sysvinit' "$verify_log"
case "$phase" in
  tiny)
    grep -q 'tiny_action_started=1' "$verify_log"
    ;;
  hello)
    grep -q 'hello_rc=0' "$verify_log"
    grep -Eq 'machine=k1om|hello from k1om|sizeof\(void\*\)=8' "$verify_log"
    ;;
  python)
    grep -q 'hello_rc=0' "$verify_log"
    grep -q 'python_rc=0' "$verify_log"
    grep -Eq 'python pid1 demo ok|thread=42|platform=' "$verify_log"
    ;;
esac

log "== restore stock after successful custom phase =="
trap - EXIT
if stock_boot_and_verify; then
  log "PASS: phase $phase verified and stock rollback verified"
  exit 0
fi

echo "phase $phase passed, but stock rollback verification failed" >&2
exit 30
