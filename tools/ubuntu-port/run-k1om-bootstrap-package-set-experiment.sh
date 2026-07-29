#!/usr/bin/env bash
set -euo pipefail

tools_dir=""
payload_rootfs="${PAYLOAD_ROOTFS:-/root/xeon-phi-revival-local/uos-rootfs/k1om-demo-python-fixed-20260727-233215}"
runtime_root="${K1OM_RUNTIME_ROOT:-/root/xeon-phi-revival-local/uos-boot-builds/repacked-stock-control-20260728-050610/rootfs}"
python312_root="${K1OM_PYTHON312_ROOT:-/root/xeon-phi-revival-local/ubuntu2404-level3/cpython-3.12.13-probe-20260729-001250/cross-ipv6off/Python-3.12.13}"
mic="mic0"
micdir=""
run_root="/root/xeon-phi-revival-local/ubuntu-port-runs"
expected_conf_sha="${EXPECTED_CONF_SHA:-c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9}"
leave_running=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools-dir) tools_dir="${2:-}"; shift 2 ;;
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --runtime-root) runtime_root="${2:-}"; shift 2 ;;
    --python312-root) python312_root="${2:-}"; shift 2 ;;
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
restore_overlay(){ set +e; for rel in etc/apt etc/dpkg etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 etc/profile.d/xeon-phi-revival.sh usr/bin/apt-cache usr/bin/apt-get usr/bin/dpkg usr/bin/pcietool usr/bin/python usr/bin/python3 usr/bin/python3.12 opt/xeon-phi-revival var/cache/apt var/lib/apt var/log/xeon-phi-revival var/lib/dpkg; do rm -rf -- "$micdir/$rel"; [[ -e "$backup_dir/$rel" || -L "$backup_dir/$rel" ]] && { mkdir -p "$micdir/$(dirname "$rel")"; cp -a "$backup_dir/$rel" "$micdir/$rel"; }; done; }
wait_online(){ for i in $(seq 1 18); do log "status_poll_$i"; micctrl --status || true; micctrl --status 2>/dev/null | grep -q "$mic: online" && return 0; sleep 5; done; return 1; }
stock_restore(){ set +e; log "== restore stock =="; restore_overlay; micctrl --shutdown "$mic" || true; sleep 5; micctrl --updateramfs "$mic" || true; systemctl restart mpss || true; sleep 8; micctrl --boot "$mic" || true; wait_online || true; sleep 8; ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; cat /proc/1/comm' || { systemctl restart mpss || true; sleep 8; micctrl --boot "$mic" || true; wait_online || true; sleep 8; ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo stock_ssh_ok_after_retry; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; cat /proc/1/comm'; }; }
trap 'stock_restore >/dev/null 2>&1 || true' EXIT

log "== K1OM bootstrap package set experiment =="
date -u
log "run_dir=$run_dir"
sha="$(sha256sum "$stock_conf" | awk '{print $1}')"
log "active_conf_sha=$sha"
[[ "$sha" == "$expected_conf_sha" ]] || { echo "stock config hash mismatch" >&2; exit 11; }

build_args=(--payload-rootfs "$payload_rootfs")
if [[ -n "$runtime_root" && -d "$runtime_root" ]]; then
  build_args+=(--runtime-root "$runtime_root")
fi
if [[ -n "$python312_root" && -d "$python312_root" ]]; then
  build_args+=(--python312-root "$python312_root")
fi
bash "$tools_dir/build-k1om-bootstrap-packages.sh" "${build_args[@]}" --out-dir "$run_dir"
bash "$tools_dir/check-k1om-package-determinism.sh" "$tools_dir" "$payload_rootfs" "$run_dir/determinism" "${runtime_root:-}" "${python312_root:-}"
bash "$tools_dir/index-k1om-local-archive.sh" "$run_dir/repo"
bash "$tools_dir/audit-k1om-package-set.sh" "$run_dir/repo" "$run_dir/audit"
bash "$tools_dir/simulate-k1om-package-install.sh" "$run_dir/repo" "$run_dir/simulated-install"
grep -E '^(Package|Version|Architecture|Filename|SHA256):' "$run_dir/repo/dists/noble/main/binary-k1om/Packages"
cat "$run_dir/determinism/package-determinism-summary.txt"
cat "$run_dir/audit/package-audit-summary.txt"
cat "$run_dir/simulated-install/install-simulation-summary.txt"

for rel in etc/apt etc/dpkg etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 etc/profile.d/xeon-phi-revival.sh usr/bin/apt-cache usr/bin/apt-get usr/bin/dpkg usr/bin/pcietool usr/bin/python usr/bin/python3 usr/bin/python3.12 opt/xeon-phi-revival var/cache/apt var/lib/apt var/log/xeon-phi-revival var/lib/dpkg; do backup_path "$rel"; done
for deb in $(find "$run_dir/repo/pool" -type f -name '*.deb' | sort); do
  bash "$tools_dir/install-k1om-profile-deb-to-micdir.sh" --deb "$deb" --micdir "$micdir"
done
mkdir -p "$micdir/var/lib"
rm -rf "$micdir/var/lib/dpkg"
cp -a "$run_dir/simulated-install/rootfs/var/lib/dpkg" "$micdir/var/lib/dpkg"
mkdir -p "$micdir/opt/xeon-phi-revival"
cp -a "$run_dir/repo" "$micdir/opt/xeon-phi-revival/repo"

systemctl restart mpss || true
wait_online || true
sleep 12
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'echo package_set_ssh_ok; cat /proc/1/comm; cat /etc/xeon-phi-revival-release; cat /opt/xeon-phi-revival/profile.env; echo ===dpkg===; test -f /var/lib/dpkg/status && echo dpkg_status_present; grep -c "^Package:" /var/lib/dpkg/status; command -v dpkg; command -v apt-get; command -v apt-cache; dpkg --version; apt-get --version; apt-cache --version; dpkg -l | grep xpr-pci-tools; dpkg -s xpr-pci-tools | grep "Status: install ok installed"; dpkg -L xpr-pci-tools | grep "/usr/bin/pcietool"; dpkg -S /usr/bin/pcietool | grep xpr-pci-tools; apt-get update; echo apt_update_rc=$?; apt-cache show xpr-pci-tools | grep "Architecture: k1om"; apt-get install --reinstall xpr-pci-tools; echo apt_install_rc=$?; echo ===libc-stack-direct===; test -x /opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2 && echo loader_present; test -e /opt/xeon-phi-revival/lib64/libc.so.6 && echo libc_present; test -e /opt/xeon-phi-revival/lib64/libz.so.1 && echo libz_present; test -e /opt/xeon-phi-revival/lib64/libncurses.so.5 && echo libncurses_present; test -e /opt/xeon-phi-revival/lib64/libreadline.so.6 && echo libreadline_present; test -e /opt/xeon-phi-revival/lib64/libssl.so.1.0.0 && echo libssl_present; test -e /opt/xeon-phi-revival/lib64/libcrypto.so.1.0.0 && echo libcrypto_present; /opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2 --library-path /opt/xeon-phi-revival/lib64 /opt/xeon-phi-revival/bin/hello-knc >/var/log/xeon-phi-revival/hello-loader.out 2>&1; echo hello_loader_direct_rc=$?; echo ===shell===; command -v ls; command -v cat; command -v grep; command -v sed; command -v awk; command -v find; command -v python3; command -v python; command -v python3.12 || true; command -v pcietool; cat /etc/xeon-phi-revival-release | grep "Xeon Phi"; printf "abc\n" | sed "s/a/A/" | grep Abc; printf "1 2\n" | awk "{print \$1+\$2}"; find /opt/xeon-phi-revival -maxdepth 1 -type d | grep "/opt/xeon-phi-revival"; pcietool list > /var/log/xeon-phi-revival/pcietool.out; echo pcietool_rc=$?; python3 -c 1; echo python3_plain_rc=$?; python -c 1; echo python_plain_rc=$?; if command -v python3.12 >/dev/null 2>&1; then python3.12 -c "import sys; print(sys.version.split()[0])"; echo python312_version_rc=$?; python3.12 /opt/xeon-phi-revival/share/python312-smoke.py; echo python312_direct_rc=$?; fi; python3 -S /opt/xeon-phi-revival/share/python-core-stage2.py; python -S /opt/xeon-phi-revival/share/python-core-stage2.py; echo ===stage2===; cat /var/log/xeon-phi-revival/stage2.log; echo ===hello-loader===; cat /var/log/xeon-phi-revival/hello-loader.out; echo ===hello===; cat /var/log/xeon-phi-revival/hello-knc.out; echo ===python===; cat /var/log/xeon-phi-revival/python-core.out; echo ===python312===; cat /var/log/xeon-phi-revival/python312-smoke.out 2>/dev/null || true; echo ===libc-stack===; cat /var/log/xeon-phi-revival/libc-stack-smoke.out; echo ===runtime-libs===; cat /var/log/xeon-phi-revival/runtime-libs-smoke.out 2>/dev/null || true; echo ===zlib===; cat /var/log/xeon-phi-revival/zlib-smoke.out; echo ===ncurses===; cat /var/log/xeon-phi-revival/ncurses-smoke.out; echo ===pci===; cat /var/log/xeon-phi-revival/pcietool.out; echo ===os===; cat /var/log/xeon-phi-revival/os-smoke.out' | tee "$run_dir/custom-verify.txt"
grep -q 'package_set_ssh_ok' "$run_dir/custom-verify.txt"
grep -q 'dpkg_status_present' "$run_dir/custom-verify.txt"
grep -q '/bin/ls' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/python3' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/python' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/pcietool' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/dpkg' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/apt-get' "$run_dir/custom-verify.txt"
grep -q '/usr/bin/apt-cache' "$run_dir/custom-verify.txt"
grep -q 'apt_update_rc=0' "$run_dir/custom-verify.txt"
grep -q 'apt_install_rc=0' "$run_dir/custom-verify.txt"
grep -q 'loader_present' "$run_dir/custom-verify.txt"
grep -q 'libc_present' "$run_dir/custom-verify.txt"
if [[ -n "$runtime_root" && -d "$runtime_root" ]]; then
  grep -q 'libz_present' "$run_dir/custom-verify.txt"
  grep -q 'libncurses_present' "$run_dir/custom-verify.txt"
  grep -q 'libreadline_present' "$run_dir/custom-verify.txt"
  grep -q 'libssl_present' "$run_dir/custom-verify.txt"
  grep -q 'libcrypto_present' "$run_dir/custom-verify.txt"
  ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'apt-get install --reinstall xpr-runtime-libs-smoke; echo apt_runtime_install_rc=$?' | tee "$run_dir/runtime-apt-verify.txt"
  grep -q 'apt_runtime_install_rc=0' "$run_dir/runtime-apt-verify.txt"
  grep -q 'runtime_libs_rc=0' "$run_dir/custom-verify.txt"
  grep -q 'runtime_libs_done=1' "$run_dir/custom-verify.txt"
fi
grep -q 'hello_loader_direct_rc=0' "$run_dir/custom-verify.txt"
grep -q 'pcietool_rc=0' "$run_dir/custom-verify.txt"
grep -q 'python3_plain_rc=0' "$run_dir/custom-verify.txt"
grep -q 'python_plain_rc=0' "$run_dir/custom-verify.txt"
if [[ -n "$python312_root" && -d "$python312_root" ]]; then
  grep -q '/usr/bin/python3.12' "$run_dir/custom-verify.txt"
  grep -q 'python312_version_rc=0' "$run_dir/custom-verify.txt"
  grep -q 'python312_direct_rc=0' "$run_dir/custom-verify.txt"
  grep -q 'python312_rc=0' "$run_dir/custom-verify.txt"
  grep -q 'python312_package_smoke_ok' "$run_dir/custom-verify.txt"
  ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "$mic" 'apt-get install --reinstall python3.12-smoke-k1om; echo apt_python312_install_rc=$?' | tee "$run_dir/python312-apt-verify.txt"
  grep -q 'apt_python312_install_rc=0' "$run_dir/python312-apt-verify.txt"
fi
grep -q 'hello_rc=0' "$run_dir/custom-verify.txt"
grep -q 'python_rc=0' "$run_dir/custom-verify.txt"
grep -q 'zlib_rc=0' "$run_dir/custom-verify.txt"
grep -q 'ncurses_rc=0' "$run_dir/custom-verify.txt"
grep -q 'libc_stack_rc=0' "$run_dir/custom-verify.txt"
grep -q 'libc_stack_done=1' "$run_dir/custom-verify.txt"
grep -q 'os_smoke_rc=0' "$run_dir/custom-verify.txt"
grep -q 'os_smoke_done=1' "$run_dir/custom-verify.txt"

cat > "$run_dir/rollback-stock.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
mic="$mic"
micdir="$micdir"
backup_dir="$backup_dir"
for rel in etc/apt etc/dpkg etc/init.d/xeon-phi-revival-stage2 etc/rc5.d/S78xeon-phi-revival-stage2 etc/profile.d/xeon-phi-revival.sh usr/bin/apt-cache usr/bin/apt-get usr/bin/dpkg usr/bin/pcietool usr/bin/python usr/bin/python3 usr/bin/python3.12 opt/xeon-phi-revival var/cache/apt var/lib/apt var/log/xeon-phi-revival var/lib/dpkg; do
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
ssh -n -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 "\$mic" 'echo stock_ssh_ok; test ! -e /opt/xeon-phi-revival/profile.env && echo profile_absent; test ! -e /var/log/xeon-phi-revival/stage2.log && echo stage2_log_absent; test ! -f /var/lib/dpkg/status && echo dpkg_status_absent; test ! -e /usr/bin/python3 && echo python3_absent; test ! -e /usr/bin/python3.12 && echo python312_absent; test ! -e /usr/bin/pcietool && echo pcietool_absent; test ! -e /usr/bin/dpkg && echo dpkg_absent; test ! -e /usr/bin/apt-get && echo apt_get_absent; test ! -e /usr/bin/apt-cache && echo apt_cache_absent; test ! -e /etc/profile.d/xeon-phi-revival.sh && echo profiled_absent; cat /proc/1/comm'
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
