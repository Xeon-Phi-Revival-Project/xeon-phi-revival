#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  run-minimal-k1om-initramfs-experiment.sh --image FILE --expected-conf-sha SHA [--mic mic0] [--ssh-marker-path PATH]

Boot a tiny K1OM control initramfs through an alternate MPSS config, capture
early console evidence, and restore stock MPSS. The only pass condition is the
fixed marker emitted by the custom init.
USAGE
}

image=""
expected_conf_sha=""
mic="mic0"
run_root="${HOME}/xeon-phi-revival-local/uos-min-init-runs"
boot_polls=24
ssh_marker_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image="${2:-}"; shift 2 ;;
    --expected-conf-sha) expected_conf_sha="${2:-}"; shift 2 ;;
    --mic) mic="${2:-}"; shift 2 ;;
    --run-root) run_root="${2:-}"; shift 2 ;;
    --boot-polls) boot_polls="${2:-}"; shift 2 ;;
    --ssh-marker-path) ssh_marker_path="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$image" && -f "$image" ]] || { usage; exit 2; }
[[ -n "$expected_conf_sha" ]] || { usage; exit 2; }

for cmd in awk cat cp date diff grep gzip mkdir sed sha256sum sleep tee timeout zcat cpio; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required host tool missing: $cmd" >&2; exit 10; }
done

stock_conf="/etc/mpss/$mic.conf"
default_conf="/etc/mpss/default.conf"
timestamp="$(date -u +%Y%m%d-%H%M%S)"
run_dir="$run_root/min-init-${timestamp}"
conf_dir="$run_dir/mpss-conf"
private_image="$run_dir/$(basename "$image")"
private_ramfs="$run_dir/${mic}.min-init.image.gz"
console_log="$run_dir/ttyMIC0-console.log"
evidence="$run_dir/evidence.txt"

mkdir -p "$run_dir"
exec > >(tee "$run_dir/run.log") 2>&1

log() {
  printf '%s\n' "$*"
}

stock_restore() {
  set +e
  log "== stock restore =="
  timeout 45 systemctl stop mpss || true
  sleep 5
  pkill -TERM mpssd || true
  sleep 3
  pkill -KILL mpssd || true
  sleep 2
  micctrl --shutdown "$mic" || true
  sleep 8
  micctrl --reset "$mic" || true
  sleep 15
  micctrl --updateramfs "$mic" || true
  systemctl reset-failed mpss || true
  timeout 120 systemctl start mpss || true
  sleep 8
  if ! micctrl --status 2>/dev/null | grep -q "$mic: online"; then
    micctrl --boot "$mic" || true
  fi
  for i in $(seq 1 24); do
    echo "restore_poll_$i"
    micctrl --status || true
    micctrl --status 2>/dev/null | grep -q "$mic: online" && break
    sleep 5
  done
  {
    echo "stock_conf_sha256=$(sha256sum "$stock_conf" | awk '{print $1}')"
    micctrl --status || true
    systemctl is-active mpss || true
    ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok; cat /proc/1/comm; uname -m' || true
  } | tee "$run_dir/rollback-verify.txt"
}

cat > "$run_dir/rollback-stock.sh" <<EOF
#!/usr/bin/env bash
set +e
timeout 45 systemctl stop mpss || true
sleep 5
pkill -TERM mpssd || true
sleep 3
pkill -KILL mpssd || true
sleep 2
micctrl --shutdown "$mic" || true
sleep 8
micctrl --reset "$mic" || true
sleep 15
micctrl --updateramfs "$mic" || true
systemctl reset-failed mpss || true
timeout 120 systemctl start mpss || true
sleep 8
if ! micctrl --status 2>/dev/null | grep -q "$mic: online"; then micctrl --boot "$mic" || true; fi
for i in \$(seq 1 24); do micctrl --status || true; micctrl --status 2>/dev/null | grep -q "$mic: online" && break; sleep 5; done
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok; cat /proc/1/comm; uname -m' || true
EOF
chmod 0755 "$run_dir/rollback-stock.sh"

trap 'stock_restore >/dev/null 2>&1 || true' EXIT

log "== xpr minimal initramfs experiment =="
date -u
cp -a "$image" "$private_image"
sha256sum "$private_image" > "$run_dir/image.sha256"

actual_conf_sha="$(sha256sum "$stock_conf" | awk '{print $1}')"
log "stock_conf_sha256=$actual_conf_sha"
if [[ "$actual_conf_sha" != "$expected_conf_sha" ]]; then
  echo "stock config hash mismatch; expected $expected_conf_sha" >&2
  exit 11
fi

mkdir -p "$conf_dir"
cp -a /etc/mpss/. "$conf_dir/"
cp -a "$stock_conf" "$run_dir/mic0.conf.stock.backup"
cp -a "$default_conf" "$run_dir/default.conf.stock.backup"

sed -i "s|^Base CPIO .*|Base CPIO $private_image|" "$conf_dir/$mic.conf"
sed -i "s|^RootDevice Ramfs .*|RootDevice Ramfs $private_ramfs|" "$conf_dir/$mic.conf"
if grep -q '^ExtraCommandLine ' "$conf_dir/$mic.conf"; then
  sed -i 's|^ExtraCommandLine .*|ExtraCommandLine "highres=off noautogroup init=/init"|' "$conf_dir/$mic.conf"
else
  echo 'ExtraCommandLine "highres=off noautogroup init=/init"' >> "$conf_dir/$mic.conf"
fi

{
  echo "date_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "mic=$mic"
  echo "stock_conf_sha256=$actual_conf_sha"
  echo "default_conf_sha256=$(sha256sum "$default_conf" | awk '{print $1}')"
  echo "image=$private_image"
  echo "image_sha256=$(awk '{print $1}' "$run_dir/image.sha256")"
  micctrl --status || true
} > "$run_dir/baseline.txt"

log "== alternate config diff =="
diff -u "$stock_conf" "$conf_dir/$mic.conf" || true

log "== source cpio listing =="
zcat "$private_image" | cpio -itv > "$run_dir/source-image.cpio-listing.txt" 2>&1
grep -E '(^| )init$|sbin/init$|dev/console$' "$run_dir/source-image.cpio-listing.txt" || true

log "== shutdown to ready =="
micctrl --shutdown "$mic" || true
for i in $(seq 1 24); do
  log "ready_poll_$i"
  micctrl --status || true
  micctrl --status 2>/dev/null | grep -q "$mic: ready" && break
  sleep 5
done

log "== generate private ramfs =="
micctrl --configdir="$conf_dir" --updateramfs "$mic"
sha256sum "$private_ramfs" > "$run_dir/private-ramfs.sha256"
gzip -l "$private_ramfs" > "$run_dir/private-ramfs.gzip.txt" 2>&1 || true
zcat "$private_ramfs" | cpio -itv > "$run_dir/private-ramfs.cpio-listing.txt" 2>&1 || true
grep -E '(^| )init$|sbin/init$|dev/console$' "$run_dir/private-ramfs.cpio-listing.txt" || true

: > "$console_log"
timeout 180 cat /dev/ttyMIC0 > "$console_log" 2>&1 &
console_pid=$!

boot_command="micctrl --configdir=$conf_dir --boot $mic"
echo "$boot_command" > "$run_dir/boot-command.txt"
log "boot_command=$boot_command"
micctrl --configdir="$conf_dir" --boot "$mic" || true

for i in $(seq 1 "$boot_polls"); do
  log "boot_poll_$i"
  micctrl --status || true
  if grep -q 'XPR_MIN_INIT_IDLE' "$console_log" 2>/dev/null; then
    break
  fi
  sleep 5
done
sleep 5
kill "$console_pid" >/dev/null 2>&1 || true
wait "$console_pid" >/dev/null 2>&1 || true

if [[ -n "$ssh_marker_path" ]]; then
  {
    echo "== ssh-marker =="
    micctrl --status || true
    ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=6 "$mic" \
      "echo ssh_marker_probe; cat '$ssh_marker_path'; test -f /tmp/xpr-stock-init-marker.txt && cat /tmp/xpr-stock-init-marker.txt || true" || true
  } > "$run_dir/ssh-marker.txt" 2>&1
fi

micctrl --status > "$run_dir/final-mic-status.txt" 2>&1 || true
dmesg | grep -iE 'mic|mpss|knc|k1om|xeon phi' | tail -200 > "$run_dir/dmesg-mic-tail.txt" || true
tail -200 /var/log/mpssd > "$run_dir/mpssd-tail.txt" 2>/dev/null || true
cat /proc/mic_ramoops/"$mic" > "$run_dir/ramoops-current.txt" 2>/dev/null || true
cat /proc/mic_ramoops/"${mic}_prev" > "$run_dir/ramoops-prev.txt" 2>/dev/null || true

{
  echo "== console =="
  cat "$console_log"
  echo "== ramoops-current =="
  cat "$run_dir/ramoops-current.txt" 2>/dev/null || true
  echo "== ramoops-prev =="
  cat "$run_dir/ramoops-prev.txt" 2>/dev/null || true
  if [[ -n "$ssh_marker_path" ]]; then
    echo "== ssh-marker =="
    cat "$run_dir/ssh-marker.txt" 2>/dev/null || true
  fi
} > "$evidence"

marker_pass=0
if grep -q 'XPR_MIN_INIT_ENTERED' "$evidence" && grep -q 'PID=1' "$evidence" && grep -q 'XPR_MIN_INIT_IDLE' "$evidence"; then
  marker_pass=1
fi

trap - EXIT
stock_restore

rollback_pass=0
if grep -q 'stock_ssh_ok' "$run_dir/rollback-verify.txt" && grep -q '^init$' "$run_dir/rollback-verify.txt"; then
  rollback_pass=1
fi

{
  echo "marker_pass=$marker_pass"
  echo "rollback_pass=$rollback_pass"
  echo "run_dir=$run_dir"
  echo "image=$private_image"
  echo "image_sha256=$(awk '{print $1}' "$run_dir/image.sha256")"
  echo "private_ramfs=$private_ramfs"
  echo "private_ramfs_sha256=$(awk '{print $1}' "$run_dir/private-ramfs.sha256" 2>/dev/null || true)"
  echo "boot_command=$boot_command"
  echo "console_log=$console_log"
  echo "evidence=$evidence"
  echo "rollback_verify=$run_dir/rollback-verify.txt"
} | tee "$run_dir/summary.txt"

if [[ "$marker_pass" == "1" && "$rollback_pass" == "1" ]]; then
  log "PASS: minimal PID 1 marker captured and rollback verified"
  exit 0
fi

echo "minimal initramfs experiment did not pass; logs preserved in $run_dir" >&2
exit 20
