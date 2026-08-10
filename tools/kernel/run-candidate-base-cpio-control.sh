#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --base FILE --kernel FILE --map FILE --expected-stock-sha SHA256 [--payload FILE] [--minimal-public-smoke] [--mic mic0] [--out-root DIR] [--leave-running]" >&2
}

base=""; kernel=""; map=""; expected_stock_sha=""; payload=""; mic="mic0"; leave_running=0; minimal_public_smoke=0; completed_success=0
out_root="${HOME}/xpr-candidate-kernel-test"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --kernel) kernel="$2"; shift 2 ;;
    --map) map="$2"; shift 2 ;;
    --expected-stock-sha) expected_stock_sha="$2"; shift 2 ;;
    --payload) payload="$2"; shift 2 ;;
    --minimal-public-smoke) minimal_public_smoke=1; shift ;;
    --mic) mic="$2"; shift 2 ;;
    --out-root) out_root="$2"; shift 2 ;;
    --leave-running) leave_running=1; shift ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$base" && -f "$kernel" && -f "$map" && "$expected_stock_sha" =~ ^[0-9a-f]{64}$ ]] || { usage; exit 2; }
[[ -z "$payload" || -f "$payload" ]] || { usage; exit 2; }

stock_conf="/etc/mpss/${mic}.conf"
stamp="$(date -u +%Y%m%d-%H%M%S)"
run="$out_root/base-cpio-control-$stamp"
mkdir -p "$run/conf"
exec > >(tee "$run/run.log") 2>&1
console_log="$run/ttyMIC0-console.log"
console_pid=""

capture_host_evidence() {
  dmesg | grep -iE 'mic|mpss|knc|k1om|xeon phi|ramoops' | tail -200 > "$run/dmesg-mic-tail.txt" || true
  cat "/proc/mic_ramoops/$mic" > "$run/ramoops-current.txt" 2>/dev/null || true
  cat "/proc/mic_ramoops/${mic}_prev" > "$run/ramoops-prev.txt" 2>/dev/null || true
}

restore_stock() {
  set +e
  if [[ "$leave_running" == 1 && "$completed_success" == 1 ]]; then
    echo "XPR_CONTROL_LEFT_RUNNING"
    return
  fi
  echo "XPR_CONTROL_ROLLBACK_BEGIN"
  if [[ -n "$console_pid" ]]; then
    kill "$console_pid" >/dev/null 2>&1 || true
    wait "$console_pid" >/dev/null 2>&1 || true
  fi
  capture_host_evidence
  timeout 45 systemctl stop mpss || true
  sleep 4
  micctrl --shutdown "$mic" || true
  sleep 6
  micctrl --reset "$mic" || true
  sleep 12
  micctrl --updateramfs "$mic" || true
  timeout 120 systemctl start mpss || true
  for _ in {1..30}; do
    micctrl --status || true
    micctrl --status 2>/dev/null | grep -q "$mic: online" && break
    sleep 5
  done
  for _ in {1..10}; do
    ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=8 \
      "$mic" 'echo stock_ssh_ok; uname -m; cat /proc/1/comm' && break
    sleep 5
  done
  sha256sum "$stock_conf" | tee "$run/stock-config-after.sha256"
  micctrl --status || true
  echo "XPR_CONTROL_ROLLBACK_END"
}
trap restore_stock EXIT

test "$(sha256sum "$stock_conf" | awk '{print $1}')" = "$expected_stock_sha"
micctrl --status | grep -q "$mic: online"
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=8 \
  "$mic" 'uname -m; cat /proc/1/comm' > "$run/stock-preflight.txt"
grep -Eq '^(k1om|x86_64)$' "$run/stock-preflight.txt"
grep -Eq '^(init|systemd|busybox)$' "$run/stock-preflight.txt"
sha256sum "$base" "$kernel" "$map" "$stock_conf" > "$run/input.sha256"
if [[ -n "$payload" ]]; then
  payload_sha=$(sha256sum "$payload" | awk '{print $1}')
  payload_bytes=$(wc -c < "$payload")
  sha256sum "$payload" >> "$run/input.sha256"
fi
cp -a /etc/mpss/. "$run/conf/"
sed -i "s|^Base CPIO .*|Base CPIO $base|" "$run/conf/$mic.conf"
sed -i "s|^OSimage .*|OSimage $kernel $map|" "$run/conf/$mic.conf"
sed -i "s|^RootDevice Ramfs .*|RootDevice Ramfs $run/$mic.image.gz|" "$run/conf/$mic.conf"
diff -u "$stock_conf" "$run/conf/$mic.conf" > "$run/alternate-config.diff" || true

micctrl --shutdown "$mic" || true
for _ in {1..24}; do
  micctrl --status | tee -a "$run/state.log" || true
  micctrl --status 2>/dev/null | grep -q "$mic: ready" && break
  sleep 5
done
  micctrl --configdir="$run/conf" --updateramfs "$mic"
  sha256sum "$run/$mic.image.gz" > "$run/final-ramfs.sha256"
  : > "$console_log"
  if [[ -e "/dev/ttyMIC${mic#mic}" ]]; then
    timeout 240 cat "/dev/ttyMIC${mic#mic}" > "$console_log" 2>&1 &
    console_pid=$!
  else
    printf 'XPR_TTYMIC_CONSOLE_MISSING %s\n' "/dev/ttyMIC${mic#mic}" > "$console_log"
  fi
  micctrl --configdir="$run/conf" --boot "$mic"

online=0
for _ in {1..24}; do
  micctrl --status | tee -a "$run/state.log" || true
  if micctrl --status 2>/dev/null | grep -q "$mic: online"; then online=1; break; fi
  sleep 5
done
project_ssh=0
if [[ "$online" == 1 ]]; then
  for _ in {1..12}; do
    if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=8 \
      "$mic" 'echo project_ssh_ok; cat /proc/1/comm; cat /run/xpr-os-init' > "$run/project-ssh.txt" 2>&1; then
      project_ssh=1
      break
    fi
    sleep 4
  done
fi

switched=0
smoke=0
if [[ -n "$payload" && "$project_ssh" == 1 ]]; then
  # BusyBox cat is already proven in the bootstrap; a Dropbear-only root does
  # not necessarily provide the remote scp server command required by OpenSSH.
  ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=12 \
    "$mic" 'cat > /tmp/xpr-rootfs.cpio.gz' < "$payload"
  ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=12 \
    "$mic" "actual_bytes=\$(/bin/busybox wc -c < /tmp/xpr-rootfs.cpio.gz); actual_sha=\$(sha256sum /tmp/xpr-rootfs.cpio.gz | awk '{print \$1}'); test \"\$actual_bytes\" = \"$payload_bytes\" && test \"\$actual_sha\" = \"$payload_sha\""
  (
    for _ in {1..24}; do
      ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=4 \
        "$mic" 'cat /run/xpr-stage-root.log /xpr-handoff.log /xpr-switch-helper.log 2>/dev/null || true' >> "$run/handoff-markers.txt" 2>&1 || true
      sleep 2
    done
  ) &
  marker_poll=$!
  ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=12 \
    "$mic" "/opt/xeon-phi-revival/bin/xpr-stage-root /tmp/xpr-rootfs.cpio.gz $payload_sha" > "$run/stage.txt" 2>&1
  wait "$marker_poll" || true
  for _ in {1..24}; do
    if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=8 \
      "$mic" 'cat /proc/1/comm; uname -m; cat /etc/os-release; grep " /proc " /proc/mounts; grep " /sys " /proc/mounts; test -c /dev/null && echo XPR_DEV_OK; test -w /run && echo XPR_RUN_WRITABLE; test -w /tmp && echo XPR_TMP_WRITABLE; cat /xpr-handoff.log /xpr-switch-helper.log /run/xpr-os-init 2>/dev/null; /usr/bin/xpr-hello; /usr/bin/xpr-pthread-smoke; if test "'"$minimal_public_smoke"'" = 1; then /usr/bin/xpr-dlopen-smoke && echo XPR_DLOPEN_OK; fi' > "$run/post-switch.txt" 2>&1 \
      && grep -Eq '^(init|busybox)$' "$run/post-switch.txt" \
      && grep -qx k1om "$run/post-switch.txt" \
      && grep -q '^ID=xpr-uos$' "$run/post-switch.txt" \
      && grep -q XPR_DEV_OK "$run/post-switch.txt" \
      && grep -q XPR_RUN_WRITABLE "$run/post-switch.txt" \
      && grep -q XPR_TMP_WRITABLE "$run/post-switch.txt" \
      && grep -q XPR_RC_ROOT_SBIN_INIT_PID1 "$run/post-switch.txt" \
      && grep -q XPR_HELLO_OK "$run/post-switch.txt" \
      && grep -q XPR_PTHREAD_OK "$run/post-switch.txt" \
      && { [[ "$minimal_public_smoke" != 1 ]] || grep -q XPR_DLOPEN_OK "$run/post-switch.txt"; }; then
      switched=1
      break
    fi
    sleep 4
  done
fi
if [[ "$switched" == 1 ]]; then
  release_smoke="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ubuntu-port/run-k1om-uos-rc-smoke.sh"
  if [[ "$minimal_public_smoke" == 1 ]]; then
    smoke=1
  elif [[ -x "$release_smoke" ]] \
      && "$release_smoke" --mic "$mic" --out-dir "$run/release-smoke"; then
    smoke=1
  fi
fi
printf 'online=%s\nproject_ssh=%s\nswitched=%s\nsmoke=%s\n' "$online" "$project_ssh" "$switched" "$smoke" | tee "$run/summary.txt"
if [[ -n "$payload" ]]; then
  [[ "$online" == 1 && "$project_ssh" == 1 && "$switched" == 1 && "$smoke" == 1 ]]
else
  [[ "$online" == 1 && "$project_ssh" == 1 ]]
fi
completed_success=1
