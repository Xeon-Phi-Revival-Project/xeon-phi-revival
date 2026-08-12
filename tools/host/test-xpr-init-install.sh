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

env PATH="$tmp/bin:$PATH" HOME="$tmp/home" \
  XPR_INIT_ROOT="$tmp/root" XPR_INIT_STATE_ROOT="$tmp/state" XPR_INIT_MPSS_DIR="$tmp/mpss" XPR_INIT_BIN_DIR="$tmp/sbin" XPR_INIT_TEST_MODE=1 \
  "$repo/tools/host/xpr-init" install --release "$tmp/release" \
  --authorized-key "$tmp/home/.ssh/id_rsa.pub" --identity "$tmp/home/.ssh/id_rsa" > "$tmp/install.out"
test -x "$tmp/sbin/xpr-init"
grep -qx 'XPR_INIT_INSTALL=PASS' "$tmp/install.out"
grep -q "$tmp/root/current/xpr-bootstrap.cpio.gz" "$tmp/mpss/mic0.conf"
env PATH="$tmp/bin:$PATH" HOME="$tmp/home" \
  XPR_INIT_ROOT="$tmp/root" XPR_INIT_STATE_ROOT="$tmp/state" XPR_INIT_MPSS_DIR="$tmp/mpss" XPR_INIT_BIN_DIR="$tmp/sbin" XPR_INIT_TEST_MODE=1 \
  "$repo/tools/host/xpr-init" status > "$tmp/status.out"
grep -qx 'XPR_INIT_INSTALLED=YES' "$tmp/status.out"
env PATH="$tmp/bin:$PATH" HOME="$tmp/home" \
  XPR_INIT_ROOT="$tmp/root" XPR_INIT_STATE_ROOT="$tmp/state" XPR_INIT_MPSS_DIR="$tmp/mpss" XPR_INIT_BIN_DIR="$tmp/sbin" XPR_INIT_TEST_MODE=1 \
  "$repo/tools/host/xpr-init" recover > "$tmp/recover.out"
grep -qx 'XPR_INIT_RECOVER=PASS' "$tmp/recover.out"
cmp "$tmp/mpss/mic0.conf" <(printf 'Base CPIO /stock/base\nOSimage /stock/kernel /stock/map\nRootDevice Ramfs /stock/mic0.image.gz\n')
echo 'XPR_INIT_INSTALL_TEST=PASS'
