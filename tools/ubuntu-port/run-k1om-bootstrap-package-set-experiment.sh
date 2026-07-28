#!/usr/bin/env bash
set -euo pipefail

tools_dir=""
payload_rootfs="${PAYLOAD_ROOTFS:-/root/xeon-phi-revival-local/uos-rootfs/k1om-demo-python-fixed-20260727-233215}"
mic="mic0"
micdir=""
run_root="/root/xeon-phi-revival-local/ubuntu-port-runs"
expected_conf_sha="${EXPECTED_CONF_SHA:-c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9}"
leave_running=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools-dir) tools_dir="${2:-}"; shift 2 ;;
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --mic) mic="${2:-}"; shift 2 ;;
    --micdir) micdir="${2:-}"; shift 2 ;;
    --run-root) run_root="${2:-}"; shift 2 ;;
    --leave-running) leave_running=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$tools_dir" ]] || { echo "missing --tools-dir" >&2; exit 2; }

micdir="${micdir:-/var/mpss/$mic}"
stock_conf="/etc/mpss/$mic.conf"
run_dir="$run_root/k1om-bootstrap-package-set-$(date -u +%Y%m%d-%H%M%S)"
backup_dir="$run_dir/backups"
created_list="$run_dir/created.list"
mkdir -p "$backup_dir"
exec > >(tee "$run_dir/run.log") 2>&1

log(){ printf '%s\n' "$*"; }
backup_path(){ rel="$1"; if [[ -e "$micdir/$rel" || -L "$micdir/$rel" ]]; then mkdir -p "$backup_dir/$(dirname "$rel")"; cp -a "$micdir/$rel" "$backup_dir/$rel"; else echo "$rel" >> "$created_list"; fi; }
restore_overlay(){ set +e; for rel in etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 etc/profile.d/xeon-phi-revival.sh usr/bin/python usr/bin/python3 opt/xeon-phi-revival var/log/xeon-phi-revival var/lib/dpkg; do rm -rf -- "$micdir/$rel"; [[ -e "$backup_dir/$rel" || -L "$backup_dir/$rel" ]] && { mkdir -p "$micdir/$(dirname "$rel")"; cp -a "$backup_dir/$rel" "$micdir/$rel"; }; done; }
wait_online(){ for i in $(seq 1 18); do log "status_poll_$i"; micctrl --status || true; micctrl --status 2>/dev/null | grep -q "$mic: online" && return 0; sleep 5; done; return 1; }
stock_restore(){ set +e; log "== restore stock =="; restore_overlay; micctrl --shutdown "$mic" || true; sleep 5; micctrl --updateramfs "$mic" || true; systemctl restart mpss || true; sleep 8; micctrl --boot "$mic" || true; wait_online || true; sleep 8; ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; cat /proc/1/comm' || { systemctl restart mpss || true; sleep 8; micctrl --boot "$mic" || true; wait_online || true; sleep 8; ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok_after_retry; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; cat /proc/1/comm'; }; }
trap 'stock_restore >/dev/null 2>&1 || true' EXIT

log "== K1OM bootstrap package set experiment =="
date -u
log "run_dir=$run_dir"
sha="$(sha256sum "$stock_conf" | awk '{print $1}')"
log "active_conf_sha=$sha"
[[ "$sha" == "$expected_conf_sha" ]] || { echo "stock config hash mismatch" >&2; exit 11; }

bash "$tools_dir/build-k1om-bootstrap-packages.sh" --payload-rootfs "$payload_rootfs" --out-dir "$run_dir"
bash "$tools_dir/check-k1om-package-determinism.sh" "$tools_dir" "$payload_rootfs" "$run_dir/determinism"
bash "$tools_dir/index-k1om-local-archive.sh" "$run_dir/repo"
bash "$tools_dir/audit-k1om-package-set.sh" "$run_dir/repo" "$run_dir/audit"
bash "$tools_dir/simulate-k1om-package-install.sh" "$run_dir/repo" "$run_dir/simulated-install"
grep -E '^(Package|Version|Architecture|Filename|SHA256):' "$run_dir/repo/dists/noble/main/binary-k1om/Packages"
cat "$run_dir/determinism/package-determinism-summary.txt"
cat "$run_dir/audit/package-audit-summary.txt"
cat "$run_dir/simulated-install/install-simulation-summary.txt"

for rel in etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 etc/profile.d/xeon-phi-revival.sh usr/bin/python usr/bin/python3 opt/xeon-phi-revival var/log/xeon-phi-revival var/lib/dpkg; do backup_path "$rel"; done
for deb in $(find "$run_dir/repo/pool" -type f -name '*.deb' | sort); do
  bash "$tools_dir/install-k1om-profile-deb-to-micdir.sh" --deb "$deb" --micdir "$micdir"
done
mkdir -p "$micdir/var/lib"
cp -a "$run_dir/simulated-install/rootfs/var/lib/dpkg" "$micdir/var/lib/dpkg"

systemctl restart mpss || true
wait_online || true
sleep 12
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo package_set_ssh_ok; cat /proc/1/comm; cat /etc/xeon-phi-revival-release; cat /opt/xeon-phi-revival/profile.env; echo ===dpkg===; test -f /var/lib/dpkg/status && echo dpkg_status_present; grep -c "^Package:" /var/lib/dpkg/status; echo ===shell===; command -v ls; command -v python3; command -v python; python3 -c 1; echo python3_plain_rc=$?; python -c 1; echo python_plain_rc=$?; python3 -S /opt/xeon-phi-revival/share/python-core-stage2.py; python -S /opt/xeon-phi-revival/share/python-core-stage2.py; echo ===stage2===; cat /var/log/xeon-phi-revival/stage2.log; echo ===hello===; cat /var/log/xeon-phi-revival/hello-knc.out; echo ===python===; cat /var/log/xeon-phi-revival/python-core.out; echo ===zlib===; cat /var/log/xeon-phi-revival/zlib-smoke.out; echo ===ncurses===; cat /var/log/xeon-phi-revival/ncurses-smoke.out; echo ===os===; cat /var/log/xeon-phi-revival/os-smoke.out' | tee "$run_dir/custom-verify.txt"
grep -q 'package_set_ssh_ok' "$run_dir/custom-verify.txt"
grep -q 'dpkg_status_present' "$run_dir/custom-verify.txt"
grep -q '/bin/ls' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/python3' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/python' "$run_dir/custom-verify.txt"
grep -q 'python3_plain_rc=0' "$run_dir/custom-verify.txt"
grep -q 'python_plain_rc=0' "$run_dir/custom-verify.txt"
grep -q 'hello_rc=0' "$run_dir/custom-verify.txt"
grep -q 'python_rc=0' "$run_dir/custom-verify.txt"
grep -q 'zlib_rc=0' "$run_dir/custom-verify.txt"
grep -q 'ncurses_rc=0' "$run_dir/custom-verify.txt"
grep -q 'os_smoke_rc=0' "$run_dir/custom-verify.txt"
grep -q 'os_smoke_done=1' "$run_dir/custom-verify.txt"

cat > "$run_dir/rollback-stock.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
mic="$mic"
micdir="$micdir"
backup_dir="$backup_dir"
for rel in etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 etc/profile.d/xeon-phi-revival.sh usr/bin/python usr/bin/python3 opt/xeon-phi-revival var/log/xeon-phi-revival var/lib/dpkg; do
  rm -rf -- "\$micdir/\$rel"
  if [[ -e "\$backup_dir/\$rel" || -L "\$backup_dir/\$rel" ]]; then
    mkdir -p "\$micdir/\$(dirname "\$rel")"
    cp -a "\$backup_dir/\$rel" "\$micdir/\$rel"
  fi
done
micctrl --shutdown "\$mic" || true
sleep 5
micctrl --updateramfs "\$mic" || true
systemctl restart mpss || true
sleep 8
micctrl --boot "\$mic" || true
for i in \$(seq 1 18); do
  micctrl --status || true
  micctrl --status 2>/dev/null | grep -q "\$mic: online" && break
  sleep 5
done
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "\$mic" 'echo stock_ssh_ok; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; test ! -f /var/lib/dpkg/status && echo dpkg_status_absent; test ! -e /usr/bin/python3 && echo python3_absent; test ! -e /etc/profile.d/xeon-phi-revival.sh && echo profiled_absent; cat /proc/1/comm'
EOF
chmod 0755 "$run_dir/rollback-stock.sh"

if [[ "$leave_running" -eq 1 ]]; then
  trap - EXIT
  log "PASS: bootstrap package set is running and left active for inspection"
  log "rollback_command=$run_dir/rollback-stock.sh"
  log "ssh_command=ssh $mic"
  exit 0
fi

trap - EXIT
stock_restore
log "PASS: bootstrap package set ran hello, python, and OS smoke then rolled back"
