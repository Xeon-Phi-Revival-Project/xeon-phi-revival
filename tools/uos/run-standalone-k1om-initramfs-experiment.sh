#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  run-standalone-k1om-initramfs-experiment.sh --image FILE --expected-conf-sha SHA [--mic mic0] [--run-root DIR]

Boot a standalone xpr-uOS K1OM initramfs through MPSS/micctrl using a private
alternate MPSS configuration directory. The experiment never flashes firmware,
never overwrites the stock boot images, captures console/ramoops evidence, and
restores stock MPSS automatically on exit.

Networking and SSH inside the standalone image are out of scope. SSH is used
only after rollback to verify stock uOS recovery.
USAGE
}

image=""
expected_conf_sha=""
mic="mic0"
run_root="${HOME}/xeon-phi-revival-local/uos-standalone-runs"
boot_polls=24

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image="${2:-}"; shift 2 ;;
    --expected-conf-sha) expected_conf_sha="${2:-}"; shift 2 ;;
    --mic) mic="${2:-}"; shift 2 ;;
    --run-root) run_root="${2:-}"; shift 2 ;;
    --boot-polls) boot_polls="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$image" && -f "$image" ]] || { usage; exit 2; }
[[ -n "$expected_conf_sha" ]] || { usage; exit 2; }

for cmd in awk cp date grep gzip mkdir sed sha256sum sleep tee timeout; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required host tool missing: $cmd" >&2; exit 10; }
done

stock_conf="/etc/mpss/$mic.conf"
default_conf="/etc/mpss/default.conf"
micdir="/var/mpss/$mic"
timestamp="$(date -u +%Y%m%d-%H%M%S)"
run_dir="$run_root/standalone-initramfs-${timestamp}"
conf_dir="$run_dir/mpss-conf"
private_image="$run_dir/$(basename "$image")"
private_ramfs="$run_dir/${mic}.standalone.image.gz"
rollback_script="$run_dir/rollback-stock.sh"
console_log="$run_dir/ttyMIC0-console.log"
boot_log="$run_dir/boot.log"

mkdir -p "$run_dir"
exec > >(tee "$boot_log") 2>&1

log() {
  printf '%s\n' "$*"
}

capture_host_state() {
  {
    echo "date_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "mic=$mic"
    echo "stock_conf=$stock_conf"
    echo "stock_conf_sha256=$(sha256sum "$stock_conf" | awk '{print $1}')"
    echo "default_conf_sha256=$(sha256sum "$default_conf" | awk '{print $1}')"
    echo "image=$private_image"
    echo "image_sha256=$(sha256sum "$private_image" | awk '{print $1}')"
    micctrl --status || true
  } > "$run_dir/baseline.txt"
}

stock_boot_and_verify() {
  set +e
  log "== rollback stock MPSS =="
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
  sleep 5
  systemctl reset-failed mpss || true
  timeout 120 systemctl start mpss || true
  sleep 8
  if ! micctrl --status 2>/dev/null | grep -q "$mic: online"; then
    micctrl --boot "$mic" || true
  fi
  for i in $(seq 1 18); do
    log "rollback_status_poll_$i"
    micctrl --status || true
    micctrl --status 2>/dev/null | grep -q "$mic: online" && break
    sleep 5
  done
  sleep 8
  {
    echo "rollback_conf_sha256=$(sha256sum "$stock_conf" | awk '{print $1}')"
    micctrl --status || true
    systemctl is-active mpss || true
    ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=6 "$mic" \
      'echo stock_ssh_ok; cat /proc/1/comm; uname -m' || true
  } | tee "$run_dir/rollback-verify.txt"
}

cat > "$rollback_script" <<EOF
#!/usr/bin/env bash
set +e
micctrl --shutdown "$mic" || true
sleep 5
timeout 120 systemctl restart mpss || true
sleep 8
if ! micctrl --status 2>/dev/null | grep -q "$mic: online"; then
  micctrl --boot "$mic" || true
fi
for i in \$(seq 1 18); do
  micctrl --status || true
  micctrl --status 2>/dev/null | grep -q "$mic: online" && break
  sleep 5
done
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok; cat /proc/1/comm; uname -m' || true
EOF
chmod 0755 "$rollback_script"

trap 'stock_boot_and_verify >/dev/null 2>&1 || true' EXIT

log "== xpr-uOS standalone initramfs experiment =="
date -u
log "run_dir=$run_dir"
log "image=$image"
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
  sed -i 's|^ExtraCommandLine .*|ExtraCommandLine "highres=off noautogroup init=/sbin/init"|' "$conf_dir/$mic.conf"
else
  echo 'ExtraCommandLine "highres=off noautogroup init=/sbin/init"' >> "$conf_dir/$mic.conf"
fi

capture_host_state
log "== alternate config diff =="
diff -u "$stock_conf" "$conf_dir/$mic.conf" || true

log "== start console capture =="
: > "$console_log"
timeout 210 cat /dev/ttyMIC0 > "$console_log" 2>&1 &
console_pid=$!

log "== activate standalone image =="
micctrl --shutdown "$mic" || true
for i in $(seq 1 24); do
  log "preboot_ready_poll_$i"
  micctrl --status || true
  micctrl --status 2>/dev/null | grep -q "$mic: ready" && break
  sleep 5
done
micctrl --configdir="$conf_dir" --updateramfs "$mic"
sha256sum "$private_ramfs" > "$run_dir/private-ramfs.sha256"
gzip -l "$private_ramfs" > "$run_dir/private-ramfs.gzip.txt" 2>&1 || true

boot_command="micctrl --configdir=$conf_dir --boot $mic"
echo "$boot_command" > "$run_dir/boot-command.txt"
log "boot_command=$boot_command"
micctrl --configdir="$conf_dir" --boot "$mic" || true

for i in $(seq 1 "$boot_polls"); do
  log "standalone_status_poll_$i"
  micctrl --status || true
  if grep -q 'BOOT_RESULT=' "$console_log" 2>/dev/null; then
    break
  fi
  sleep 5
done

sleep 5
kill "$console_pid" >/dev/null 2>&1 || true
wait "$console_pid" >/dev/null 2>&1 || true

log "== host evidence capture =="
micctrl --status | tee "$run_dir/final-mic-status.txt" || true
dmesg | grep -iE 'mic|mpss|knc|k1om|xeon phi' | tail -200 > "$run_dir/dmesg-mic-tail.txt" || true
tail -200 /var/log/mpssd > "$run_dir/mpssd-tail.txt" 2>/dev/null || true
cat /proc/mic_ramoops/"$mic" > "$run_dir/ramoops-current.txt" 2>/dev/null || true
cat /proc/mic_ramoops/"${mic}_prev" > "$run_dir/ramoops-prev.txt" 2>/dev/null || true

evidence="$run_dir/standalone-evidence.txt"
{
  echo "== console =="
  cat "$console_log"
  echo "== ramoops-current =="
  cat "$run_dir/ramoops-current.txt" 2>/dev/null || true
  echo "== ramoops-prev =="
  cat "$run_dir/ramoops-prev.txt" 2>/dev/null || true
} > "$evidence"

standalone_pass=1
grep -q 'resident_pid=1' "$evidence" || standalone_pass=0
grep -q 'STOCK_INIT_SYSVINIT_PRESENT=0' "$evidence" || standalone_pass=0
grep -q '^ID=xpr-uos' "$evidence" || standalone_pass=0
grep -q 'machine=k1om' "$evidence" || standalone_pass=0
grep -q ' /proc ' "$evidence" || standalone_pass=0
grep -q ' /sys ' "$evidence" || standalone_pass=0
grep -q ' /run ' "$evidence" || standalone_pass=0
grep -q ' /tmp ' "$evidence" || standalone_pass=0
grep -q 'CHECK_RC:sh_basic:0' "$evidence" || standalone_pass=0
grep -q 'CHECK_RC:fs_basic:0' "$evidence" || standalone_pass=0
grep -q 'CHECK_RC:dev_basic:0' "$evidence" || standalone_pass=0
grep -q 'CHECK_RC:hello:0' "$evidence" || standalone_pass=0
grep -q 'CHECK_RC:pthread:0' "$evidence" || standalone_pass=0
grep -q 'RESIDENT_IDLE=1' "$evidence" || standalone_pass=0

log "== rollback after standalone attempt =="
trap - EXIT
stock_boot_and_verify

rollback_pass=1
grep -q 'stock_ssh_ok' "$run_dir/rollback-verify.txt" || rollback_pass=0
grep -q '^init$' "$run_dir/rollback-verify.txt" || rollback_pass=0

{
  echo "standalone_pass=$standalone_pass"
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
} | tee "$run_dir/standalone-summary.txt"

if [[ "$standalone_pass" == "1" && "$rollback_pass" == "1" ]]; then
  log "PASS: standalone resident PID 1 passed and rollback verified"
  exit 0
fi

echo "standalone experiment did not pass; logs preserved in $run_dir" >&2
exit 20
