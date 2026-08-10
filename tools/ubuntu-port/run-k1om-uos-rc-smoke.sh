#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  run-k1om-uos-rc-smoke.sh [--mic mic0] --out-dir DIR

Run the release-candidate smoke test against an already booted K1OM card.
Uses bounded SSH options and writes public-safe command output to OUT_DIR.
USAGE
}

mic="mic0"
out_dir=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mic) mic="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done
[[ -n "$out_dir" ]] || { usage; exit 2; }
mkdir -p "$out_dir"

ssh_opts=(-o BatchMode=yes -o ConnectTimeout=6 -o ConnectionAttempts=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
log="$out_dir/uos-rc-smoke.log"

ssh "${ssh_opts[@]}" "$mic" 'cat > /tmp/xpr-uos-rc-smoke.sh && chmod 0755 /tmp/xpr-uos-rc-smoke.sh && /tmp/xpr-uos-rc-smoke.sh' <<'REMOTE' | tee "$log"
#!/bin/sh
set -u
fail=0
pass(){ echo "PASS:$1"; }
check(){ label="$1"; shift; if "$@"; then pass "$label"; else echo "FAIL:$label"; fail=1; fi; }

echo "== identity =="
uname -a
cat /etc/os-release
check uname_machine_k1om test "$(uname -m)" = "k1om"
check os_id_xpr grep -q '^ID=xpr-uos$' /etc/os-release
check motd_xpr_os grep -q 'Xeon Phi Revival K1OM uOS' /etc/motd
check splash_boot_marker grep -q 'XPR_SPLASH_DISPLAYED' /run/xpr-os-init
check os_like_ubuntu grep -q '^ID_LIKE=ubuntu$' /etc/os-release
check os_arch_k1om grep -q '^ARCHITECTURE="k1om"$' /etc/os-release
check pid1_visible test -n "$(cat /proc/1/comm 2>/dev/null)"

echo "== shell and commands =="
check sh_command /bin/sh -c 'echo sh-ok'
for cmd in ls cat cp mv rm mkdir mount uname ps env; do
  check "cmd_$cmd" command -v "$cmd"
done
mkdir -p /tmp/xpr-rc-smoke-dir
echo a > /tmp/xpr-rc-smoke-a
cp /tmp/xpr-rc-smoke-a /tmp/xpr-rc-smoke-b
mv /tmp/xpr-rc-smoke-b /tmp/xpr-rc-smoke-c
cat /tmp/xpr-rc-smoke-c | grep -q a && pass file_ops
rm -f /tmp/xpr-rc-smoke-a /tmp/xpr-rc-smoke-c
rm -rf /tmp/xpr-rc-smoke-dir

echo "== filesystems =="
check proc_dir test -d /proc
check sys_dir test -d /sys
check dev_dir test -d /dev
mkdir -p /run /tmp
chmod 1777 /tmp
check run_dir test -d /run
check tmp_writable /bin/sh -c 'echo tmp-ok > /tmp/xpr-rc-write && rm /tmp/xpr-rc-write'
check proc_mounted /bin/sh -c 'mount | grep " /proc " >/dev/null'
check sys_mounted /bin/sh -c 'mount | grep " /sys " >/dev/null'
check dev_null test -e /dev/null

echo "== package manager =="
check dpkg_arch /bin/sh -c 'test "$(dpkg --print-architecture)" = k1om'
check dpkg_query dpkg-query -W xpr-pci-tools
check dpkg_deb command -v dpkg-deb
check apt_update apt-get update
check apt_cache apt-cache show xpr-pci-tools
check apt_reinstall apt-get install --reinstall xpr-pci-tools

echo "== runtime =="
check loader test -x /opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2
check libc test -e /opt/xeon-phi-revival/lib64/libc.so.6
check libpthread test -e /opt/xeon-phi-revival/lib64/libpthread.so.0
check hello_loader /opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2 --library-path /opt/xeon-phi-revival/lib64 /opt/xeon-phi-revival/bin/hello-knc
check stage2_log grep -q '\[stage2\] done' /var/log/xeon-phi-revival/stage2.log
check hello_stage2 grep -q 'hello_rc=0' /var/log/xeon-phi-revival/stage2.log
check pthread_stack grep -q 'libc_stack_rc=0' /var/log/xeon-phi-revival/stage2.log
check zlib_stage2 grep -q 'zlib_rc=0' /var/log/xeon-phi-revival/stage2.log
check ncurses_stage2 grep -q 'ncurses_rc=0' /var/log/xeon-phi-revival/stage2.log

echo "== python =="
python3 --version
python --version
check python3_exec python3 -c 'print("python3-ok")'
check python_default python -c 'import sys; print(sys.version.split()[0])'
check python312_smoke python3.12 /opt/xeon-phi-revival/share/python312-smoke.py
check ctypes_call python3 -c 'import ctypes; libc=ctypes.CDLL(None); f=libc.strlen; f.argtypes=[ctypes.c_char_p]; f.restype=ctypes.c_size_t; raise SystemExit(0 if f(b"phi")==3 else 1)'
check ctypes_callback python3 -c 'import ctypes; C=ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int, ctypes.c_int); cb=C(lambda a,b:a+b); raise SystemExit(0 if cb(19,23)==42 else 1)'
check zlib_import python3 -c 'import zlib; assert zlib.decompress(zlib.compress(b"x")) == b"x"'
python3 - <<'PYOPT'
mods = ["bz2", "lzma", "readline", "sqlite3", "curses", "curses.panel"]
for mod in mods:
    try:
        __import__(mod)
        print("OPTIONAL_PASS:%s" % mod)
    except Exception as exc:
        print("OPTIONAL_GAP:%s:%s:%s" % (mod, exc.__class__.__name__, exc))
PYOPT

echo "== network =="
if ip addr show 2>/dev/null || ifconfig -a 2>/dev/null || /bin/busybox ifconfig -a 2>/dev/null; then
  pass network_visibility
else
  echo "FAIL:network_visibility"
  fail=1
fi
pass ssh_available

exit "$fail"
REMOTE

grep -q 'PASS:ssh_available' "$log"
grep -q 'PASS:uname_machine_k1om' "$log"
grep -q 'PASS:os_id_xpr' "$log"
grep -q 'PASS:apt_update' "$log"
grep -q 'PASS:apt_reinstall' "$log"
grep -q 'PASS:python312_smoke' "$log"
grep -q 'PASS:ctypes_call' "$log"
grep -q 'PASS:ctypes_callback' "$log"
grep -q 'PASS:pthread_stack' "$log"
grep -q 'PASS:network_visibility' "$log"
if grep -q '^FAIL:' "$log"; then
  echo "release smoke failed; see $log" >&2
  exit 20
fi
echo "release_smoke=passed"
echo "log=$log"
