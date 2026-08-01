#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: run-stock-base-cpio-control.sh --image FILE --expected-conf-sha SHA [--mic mic0] [--boot-polls 18] [--expect-console TEXT] [--expect-ssh-path PATH] [--expect-ssh-file PATH --expect-ssh-text TEXT] [--expect-tcp-port PORT] [--expect-tcp-text TEXT]

Boot a byte-preserving stock Base CPIO reconstruction through an alternate MPSS
configuration, capture bounded evidence, and restore the stock configuration.
USAGE
}

image=""
expected_conf_sha=""
mic="mic0"
boot_polls=18
expect_console=""
expect_ssh_path=""
expect_ssh_file=""
expect_ssh_text=""
expect_tcp_port=""
expect_tcp_text=""
run_root="${HOME}/xeon-phi-revival-local/stock-cpio-control-runs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image="${2:-}"; shift 2 ;;
    --expected-conf-sha) expected_conf_sha="${2:-}"; shift 2 ;;
    --mic) mic="${2:-}"; shift 2 ;;
    --boot-polls) boot_polls="${2:-}"; shift 2 ;;
    --expect-console) expect_console="${2:-}"; shift 2 ;;
    --expect-ssh-path) expect_ssh_path="${2:-}"; shift 2 ;;
    --expect-ssh-file) expect_ssh_file="${2:-}"; shift 2 ;;
    --expect-ssh-text) expect_ssh_text="${2:-}"; shift 2 ;;
    --expect-tcp-port) expect_tcp_port="${2:-}"; shift 2 ;;
    --expect-tcp-text) expect_tcp_text="${2:-}"; shift 2 ;;
    --run-root) run_root="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

[[ -f "$image" && -n "$expected_conf_sha" ]] || { usage; exit 2; }
[[ -z "$expect_ssh_path" || "$expect_ssh_path" =~ ^/[A-Za-z0-9._/-]+$ ]] || { echo "invalid SSH marker path" >&2; exit 2; }
[[ -z "$expect_ssh_file" || "$expect_ssh_file" =~ ^/[A-Za-z0-9._/-]+$ ]] || { echo "invalid SSH marker file" >&2; exit 2; }
[[ -z "$expect_ssh_file" || -n "$expect_ssh_text" ]] || { echo "SSH text is required with SSH file" >&2; exit 2; }
[[ -z "$expect_tcp_port" || "$expect_tcp_port" =~ ^[0-9]+$ ]] || { echo "invalid TCP port" >&2; exit 2; }
[[ -z "$expect_tcp_port" || -n "$expect_tcp_text" ]] || { echo "TCP text is required with TCP port" >&2; exit 2; }
for cmd in awk cat cp date diff grep gzip mkdir sed sha256sum sleep tee timeout zcat cpio; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "missing host tool: $cmd" >&2; exit 10; }
done

stock_conf="/etc/mpss/${mic}.conf"
default_conf="/etc/mpss/default.conf"
timestamp="$(date -u +%Y%m%d-%H%M%S)"
run_dir="${run_root}/stock-cpio-control-${timestamp}"
conf_dir="${run_dir}/mpss-conf"
private_image="${run_dir}/$(basename "$image")"
private_ramfs="${run_dir}/${mic}.control.image.gz"
console_log="${run_dir}/ttyMIC0-console.log"
mkdir -p "$run_dir"
exec > >(tee "${run_dir}/run.log") 2>&1

restore_stock() {
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
  for i in $(seq 1 24); do
    micctrl --status || true
    micctrl --status 2>/dev/null | grep -q "${mic}: online" && break
    sleep 5
  done
  stock_ssh_ok=0
  for i in $(seq 1 8); do
    if ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok; uname -m; cat /proc/1/comm'; then
      stock_ssh_ok=1
      break
    fi
    sleep 5
  done
  {
    echo "stock_conf_sha256=$(sha256sum "$stock_conf" | awk '{print $1}')"
    echo "stock_ssh_ready=${stock_ssh_ok}"
    micctrl --status || true
    systemctl is-active mpss || true
  } > "${run_dir}/rollback-verify.txt"
}

trap 'restore_stock >/dev/null 2>&1 || true' EXIT
actual_conf_sha="$(sha256sum "$stock_conf" | awk '{print $1}')"
[[ "$actual_conf_sha" == "$expected_conf_sha" ]] || { echo "stock config hash mismatch" >&2; exit 11; }
micctrl --status | grep -q "${mic}: online" || { echo "stock card is not online" >&2; exit 12; }
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'uname -m' | grep -qx k1om || { echo "stock SSH preflight failed" >&2; exit 13; }

cp -a "$image" "$private_image"
sha256sum "$private_image" "$stock_conf" "$default_conf" > "${run_dir}/baseline.sha256"
mkdir -p "$conf_dir"
cp -a /etc/mpss/. "$conf_dir/"
sed -i "s|^Base CPIO .*|Base CPIO $private_image|" "${conf_dir}/${mic}.conf"
sed -i "s|^RootDevice Ramfs .*|RootDevice Ramfs $private_ramfs|" "${conf_dir}/${mic}.conf"
echo "micctrl --configdir=${conf_dir} --boot ${mic}" > "${run_dir}/boot-command.txt"
diff -u "$stock_conf" "${conf_dir}/${mic}.conf" > "${run_dir}/alternate-config.diff" || true
zcat "$private_image" | cpio -itv > "${run_dir}/source-image.cpio-listing.txt" 2>&1

micctrl --shutdown "$mic" || true
for i in $(seq 1 24); do
  micctrl --status || true
  micctrl --status 2>/dev/null | grep -q "${mic}: ready" && break
  sleep 5
done
micctrl --configdir="$conf_dir" --updateramfs "$mic"
sha256sum "$private_ramfs" > "${run_dir}/private-ramfs.sha256"
zcat "$private_ramfs" | cpio -itv > "${run_dir}/private-ramfs.cpio-listing.txt" 2>&1 || true
: > "$console_log"
timeout 150 cat /dev/ttyMIC0 > "$console_log" 2>&1 &
console_pid=$!
micctrl --configdir="$conf_dir" --boot "$mic" || true
boot_pass=0
for i in $(seq 1 "$boot_polls"); do
  micctrl --status | tee -a "${run_dir}/boot-status.log" || true
  if micctrl --status 2>/dev/null | grep -q "${mic}: online"; then
    boot_pass=1
    break
  fi
  sleep 5
done
marker_pass=1
if [[ -n "$expect_console" ]] && ! grep -qF "$expect_console" "$console_log"; then
  marker_pass=0
fi
kill "$console_pid" >/dev/null 2>&1 || true
wait "$console_pid" >/dev/null 2>&1 || true
{
  micctrl --status || true
  ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo experiment_ssh_ok; uname -m; cat /proc/1/comm' || true
} > "${run_dir}/experiment-verify.txt"
ssh_marker_pass=1
if [[ -n "$expect_ssh_path" ]]; then
  if ! ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" "test -f '$expect_ssh_path' && test \"\$(head -n 1 '$expect_ssh_path')\" = XPR"; then
    ssh_marker_pass=0
  fi
fi
ssh_file_pass=1
if [[ -n "$expect_ssh_file" ]]; then
  ssh_file_output="$(ssh -n -l root -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 "$mic" "cat '$expect_ssh_file'" 2>/dev/null || true)"
  printf '%s\n' "$ssh_file_output" > "${run_dir}/ssh-file-marker.txt"
  [[ "$ssh_file_output" == *"$expect_ssh_text"* ]] || ssh_file_pass=0
fi
tcp_marker_pass=1
if [[ -n "$expect_tcp_port" ]]; then
  tcp_output="$(timeout 8 bash -c "exec 3<>/dev/tcp/172.31.1.1/${expect_tcp_port}; cat <&3" 2>/dev/null || true)"
  printf '%s\n' "$tcp_output" > "${run_dir}/tcp-marker.txt"
  [[ "$tcp_output" == *"$expect_tcp_text"* ]] || tcp_marker_pass=0
fi
trap - EXIT
restore_stock
rollback_pass=0
grep -q 'stock_ssh_ready=1' "${run_dir}/rollback-verify.txt" && grep -q "${mic}: online" "${run_dir}/rollback-verify.txt" && rollback_pass=1
{
  echo "boot_pass=${boot_pass}"
  echo "marker_pass=${marker_pass}"
  echo "ssh_marker_pass=${ssh_marker_pass}"
  echo "ssh_file_pass=${ssh_file_pass}"
  echo "tcp_marker_pass=${tcp_marker_pass}"
  echo "rollback_pass=${rollback_pass}"
  echo "run_dir=${run_dir}"
  echo "image_sha256=$(sha256sum "$private_image" | awk '{print $1}')"
  echo "boot_command=$(cat "${run_dir}/boot-command.txt")"
} | tee "${run_dir}/summary.txt"
[[ "$boot_pass" == 1 && "$marker_pass" == 1 && "$ssh_marker_pass" == 1 && "$ssh_file_pass" == 1 && "$tcp_marker_pass" == 1 && "$rollback_pass" == 1 ]] || exit 20
