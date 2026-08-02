#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --base FILE --kernel FILE --map FILE --expected-stock-sha SHA256 [--mic mic0] [--out-root DIR]" >&2
}

base=""; kernel=""; map=""; expected_stock_sha=""; mic="mic0"
out_root="${HOME}/xpr-candidate-kernel-test"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --kernel) kernel="$2"; shift 2 ;;
    --map) map="$2"; shift 2 ;;
    --expected-stock-sha) expected_stock_sha="$2"; shift 2 ;;
    --mic) mic="$2"; shift 2 ;;
    --out-root) out_root="$2"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$base" && -f "$kernel" && -f "$map" && "$expected_stock_sha" =~ ^[0-9a-f]{64}$ ]] || { usage; exit 2; }

stock_conf="/etc/mpss/${mic}.conf"
stamp="$(date -u +%Y%m%d-%H%M%S)"
run="$out_root/base-cpio-control-$stamp"
mkdir -p "$run/conf"
exec > >(tee "$run/run.log") 2>&1

restore_stock() {
  set +e
  echo "XPR_CONTROL_ROLLBACK_BEGIN"
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
    ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
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
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
  "$mic" 'uname -m' | grep -qx k1om
sha256sum "$base" "$kernel" "$map" "$stock_conf" > "$run/input.sha256"
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
    if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 \
      "$mic" 'echo project_ssh_ok; cat /proc/1/comm; cat /run/xpr-os-init' > "$run/project-ssh.txt" 2>&1; then
      project_ssh=1
      break
    fi
    sleep 4
  done
fi
printf 'online=%s\nproject_ssh=%s\n' "$online" "$project_ssh" | tee "$run/summary.txt"
[[ "$online" == 1 && "$project_ssh" == 1 ]]
