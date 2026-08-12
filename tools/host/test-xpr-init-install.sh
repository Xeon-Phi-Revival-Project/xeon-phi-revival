#!/usr/bin/env bash
# Host-only install/recover test. It stubs micctrl and SSH; no hardware access.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/release/kernel" "$tmp/release/bootstrap" "$tmp/release/payload" \
  "$tmp/release/tools" "$tmp/mpss" "$tmp/bin" "$tmp/home/.ssh"
printf 'kernel\n' > "$tmp/release/kernel/bzImage"
printf 'map\n' > "$tmp/release/kernel/System.map"
printf 'bootstrap\n' > "$tmp/release/bootstrap/xpr-bootstrap.cpio.gz"
printf 'payload\n' > "$tmp/release/payload/xpr-rootfs.cpio.gz"
printf 'Base CPIO /stock/base\nOSimage /stock/kernel /stock/map\nRootDevice Ramfs /stock/mic0.image.gz\n' > "$tmp/mpss/mic0.conf"
printf 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1 test@xpr\n' > "$tmp/home/.ssh/id_rsa.pub"
printf 'not-a-real-private-key\n' > "$tmp/home/.ssh/id_rsa"
chmod 600 "$tmp/home/.ssh/id_rsa"

cat > "$tmp/release/tools/provision-authorized-key.py" <<'PY'
#!/usr/bin/env python
import shutil
import sys
args = sys.argv
def value(flag): return args[args.index(flag) + 1]
shutil.copyfile(value('--generic-payload'), value('--output'))
shutil.copyfile(value('--generic-bootstrap'), value('--bootstrap-output'))
open(value('--report'), 'w').write('{}\n')
print('SSH_KEY_PROVISIONING_VALIDATION=PASS')
PY
chmod +x "$tmp/release/tools/provision-authorized-key.py"
printf '0.1.0-rc6\n' > "$tmp/release/VERSION"
(cd "$tmp/release" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
mkdir -p "$tmp/archive-root"
cp -a "$tmp/release" "$tmp/archive-root/xpr-os-0.1.0-rc6"
tar -czf "$tmp/home/Downloads-xpr-os-0.1.0-rc6.tar.gz" -C "$tmp/archive-root" xpr-os-0.1.0-rc6
mkdir -p "$tmp/home/Downloads"
mv "$tmp/home/Downloads-xpr-os-0.1.0-rc6.tar.gz" "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz"
cat > "$tmp/bin/python" <<'EOF'
#!/usr/bin/env bash
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --generic-payload) payload=$2; shift 2 ;;
    --generic-bootstrap) bootstrap=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --bootstrap-output) bootstrap_output=$2; shift 2 ;;
    --report) report=$2; shift 2 ;;
    *) shift ;;
  esac
done
cp "$payload" "$output"
cp "$bootstrap" "$bootstrap_output"
printf '{}\n' > "$report"
EOF
chmod +x "$tmp/bin/python"
cat > "$tmp/bin/micctrl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --status) echo 'mic0: online' ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$tmp/bin/micctrl"
cat > "$tmp/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${XPR_INIT_TEST_LOG:?}"
exit 0
EOF
chmod +x "$tmp/bin/systemctl"

common_env=(PATH="$tmp/bin:$PATH" HOME="$tmp/home" SUDO_USER=xprtest XPR_INIT_TEST_LOG="$tmp/systemctl.log" \
  XPR_INIT_ROOT="$tmp/root" XPR_INIT_STATE_ROOT="$tmp/state" XPR_INIT_MPSS_DIR="$tmp/mpss" \
  XPR_INIT_BIN_DIR="$tmp/sbin" XPR_INIT_SUDO_BIN_DIR="$tmp/sudo-sbin" XPR_INIT_SYSTEMD_DIR="$tmp/systemd" XPR_INIT_TEST_MODE=1)

env "${common_env[@]}" "$repo/tools/host/xpr-init" --install \
  --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" \
  --authorized-key "$tmp/home/.ssh/id_rsa.pub" --identity "$tmp/home/.ssh/id_rsa" > "$tmp/install.out"
test -x "$tmp/sbin/xpr-init"
test -L "$tmp/sudo-sbin/xpr-init"
grep -qx 'XPR_INIT_INSTALL=PASS' "$tmp/install.out"
grep -q "$tmp/root/current/xpr-bootstrap.cpio.gz" "$tmp/mpss/mic0.conf"
grep -q 'enable --now xpr-init-handoff@mic0.service' "$tmp/systemctl.log"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --install > "$tmp/reinstall.out"
grep -qx 'XPR_INIT_INSTALL=ALREADY_INSTALLED' "$tmp/reinstall.out"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --status > "$tmp/status.out"
grep -qx 'Mode: XPR-OS' "$tmp/status.out"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > "$tmp/recover.out"
grep -qx 'XPR_INIT_RECOVER=PASS' "$tmp/recover.out"
grep -q 'disable --now xpr-init-handoff@mic0.service' "$tmp/systemctl.log"
cmp "$tmp/mpss/mic0.conf" <(printf 'Base CPIO /stock/base\nOSimage /stock/kernel /stock/map\nRootDevice Ramfs /stock/mic0.image.gz\n')
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > "$tmp/recover2.out"
grep -qx 'XPR_INIT_RECOVER=ALREADY_STOCK' "$tmp/recover2.out"
# The handoff's archive stream must not use the normal SSH probe's -n option.
grep -q 'local -a payload_ssh_opts=("${ssh_opts\[@\]:1}")' "$repo/tools/host/xpr-init"
grep -q 'ssh "${payload_ssh_opts\[@]}" "$mic" '\''cat > /tmp/xpr-rootfs.cpio.gz'\'' < "$payload"' "$repo/tools/host/xpr-init"
! grep -q 'ssh "${ssh_opts\[@]}" "$mic" '\''cat > /tmp/xpr-rootfs.cpio.gz'\'' < "$payload"' "$repo/tools/host/xpr-init"
echo 'XPR_INIT_INSTALL_TEST=PASS'
