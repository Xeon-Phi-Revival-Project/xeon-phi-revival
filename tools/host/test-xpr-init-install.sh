#!/usr/bin/env bash
# Host-only install/recover test. It stubs micctrl and SSH; no hardware access.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
mkdir -p "$tmp/release/kernel" "$tmp/release/bootstrap" "$tmp/release/payload" \
  "$tmp/release/tools" "$tmp/mpss" "$tmp/bin" "$tmp/home/.ssh"
printf 'kernel\n' > "$tmp/release/kernel/bzImage"
printf 'map\n' > "$tmp/release/kernel/System.map"
printf 'bootstrap\n' > "$tmp/release/bootstrap/xpr-bootstrap.cpio.gz"
printf 'payload\n' > "$tmp/release/payload/xpr-rootfs.cpio.gz"
printf 'Base CPIO /stock/base\nOSimage /stock/kernel /stock/map\nRootDevice Ramfs /stock/mic0.image.gz\n' > "$tmp/mpss/mic0.conf"
ssh-keygen -q -t rsa -b 2048 -N '' -f "$tmp/home/.ssh/id_rsa" -C 'fixture@xpr'

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
  XPR_INIT_BIN_DIR="$tmp/sbin" XPR_INIT_SUDO_BIN_DIR="$tmp/sbin" XPR_INIT_SYSTEMD_DIR="$tmp/systemd" XPR_INIT_TEST_MODE=1)

if ! env "${common_env[@]}" "$repo/tools/host/xpr-init" --install \
  --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" \
  --authorized-key "$tmp/home/.ssh/id_rsa.pub" --identity "$tmp/home/.ssh/id_rsa" > "$tmp/install.out" 2>&1; then
  cat "$tmp/install.out" >&2
  exit 1
fi
test -x "$tmp/sbin/xpr-init"
grep -qx 'XPR_INIT_INSTALL=PASS' "$tmp/install.out"
first_archive_sha=$(sha256sum "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" | awk '{print $1}')
first_release_root=$(sed -n "s/^release_root='\(.*\)'$/\1/p" "$tmp/state/mic0.env")
grep -qx "release_archive_sha='$first_archive_sha'" "$tmp/state/mic0.env"
test "$first_release_root" = "$tmp/state/releases/xpr-os-0.1.0-rc6-$first_archive_sha"
grep -q "$tmp/root/current/xpr-bootstrap.cpio.gz" "$tmp/mpss/mic0.conf"
grep -q 'enable --now xpr-init-handoff@mic0.service' "$tmp/systemctl.log"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --install > "$tmp/reinstall.out"
grep -qx 'XPR_INIT_INSTALL=ALREADY_INSTALLED' "$tmp/reinstall.out"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --status > "$tmp/status.out"
grep -qx 'XPR_INIT_INSTALLED=yes' "$tmp/status.out"
grep -qx "XPR_INIT_RELEASE_ARCHIVE_SHA=$first_archive_sha" "$tmp/status.out"
grep -qx 'XPR_INIT_CONFIG_MODE=XPR' "$tmp/status.out"
grep -qx 'XPR_INIT_HANDOFF_ENABLED=yes' "$tmp/status.out"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > "$tmp/recover.out"
grep -qx 'XPR_INIT_RECOVER=PASS' "$tmp/recover.out"
grep -q 'disable --now xpr-init-handoff@mic0.service' "$tmp/systemctl.log"
cmp "$tmp/mpss/mic0.conf" <(printf 'Base CPIO /stock/base\nOSimage /stock/kernel /stock/map\nRootDevice Ramfs /stock/mic0.image.gz\n')
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > "$tmp/recover2.out"
grep -qx 'XPR_INIT_RECOVER=ALREADY_STOCK' "$tmp/recover2.out"

# Cache identity is the archive hash, not only the version/root directory name.
# A changed archive with the same release name must be extracted separately;
# the unchanged archive must safely reuse its existing extraction.
printf 'payload-v2\n' > "$tmp/release/payload/xpr-rootfs.cpio.gz"
(cd "$tmp/release" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
rm -rf "$tmp/archive-root/xpr-os-0.1.0-rc6"
cp -a "$tmp/release" "$tmp/archive-root/xpr-os-0.1.0-rc6"
tar -czf "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" -C "$tmp/archive-root" xpr-os-0.1.0-rc6
second_archive_sha=$(sha256sum "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" | awk '{print $1}')
test "$second_archive_sha" != "$first_archive_sha"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --install \
  --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" \
  --authorized-key "$tmp/home/.ssh/id_rsa.pub" --identity "$tmp/home/.ssh/id_rsa" > "$tmp/cache-changed.out"
second_release_root=$(sed -n "s/^release_root='\(.*\)'$/\1/p" "$tmp/state/mic0.env")
test "$second_release_root" = "$tmp/state/releases/xpr-os-0.1.0-rc6-$second_archive_sha"
test "$second_release_root" != "$first_release_root"
grep -qx 'payload-v2' "$second_release_root/payload/xpr-rootfs.cpio.gz"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > /dev/null
env "${common_env[@]}" "$tmp/sbin/xpr-init" --install \
  --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" \
  --authorized-key "$tmp/home/.ssh/id_rsa.pub" --identity "$tmp/home/.ssh/id_rsa" > "$tmp/cache-reused.out"
third_release_root=$(sed -n "s/^release_root='\(.*\)'$/\1/p" "$tmp/state/mic0.env")
test "$third_release_root" = "$second_release_root"
test "$(find "$tmp/state/releases" -mindepth 1 -maxdepth 1 -type d | wc -l)" = 2
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > /dev/null

# No usable RSA key creates and reuses a dedicated XPR-only key pair.
rm -f "$tmp/home/.ssh/id_rsa" "$tmp/home/.ssh/id_rsa.pub"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --install --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" > "$tmp/generated.out" 2> "$tmp/generated.err"
test -f "$tmp/home/.ssh/xpr_os_rsa"
test -f "$tmp/home/.ssh/xpr_os_rsa.pub"
if [[ $(uname -s) != MINGW* ]]; then
  test "$(stat -c %a "$tmp/home/.ssh/xpr_os_rsa")" = 600
fi
grep -q 'XPR_INIT_RSA_KEY=GENERATED:' "$tmp/generated.err"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > /dev/null
env "${common_env[@]}" "$tmp/sbin/xpr-init" --install --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" > "$tmp/reused.out" 2> "$tmp/reused.err"
grep -q 'XPR_INIT_RSA_KEY=REUSED:' "$tmp/reused.err"
env "${common_env[@]}" "$tmp/sbin/xpr-init" --recover > /dev/null

# Ambiguous conventional keys and incomplete dedicated pairs must fail closed.
rm -f "$tmp/home/.ssh/xpr_os_rsa" "$tmp/home/.ssh/xpr_os_rsa.pub"
ssh-keygen -q -t rsa -b 2048 -N '' -f "$tmp/home/.ssh/one_rsa" -C 'one@xpr'
ssh-keygen -q -t rsa -b 2048 -N '' -f "$tmp/home/.ssh/two_rsa" -C 'two@xpr'
if env "${common_env[@]}" "$tmp/sbin/xpr-init" --install --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" > "$tmp/multiple.out" 2>&1; then
  echo 'multiple RSA keys unexpectedly accepted' >&2; exit 1
fi
grep -q 'multiple RSA public key with matching private key candidates found' "$tmp/multiple.out"
rm -f "$tmp/home/.ssh/one_rsa" "$tmp/home/.ssh/one_rsa.pub" "$tmp/home/.ssh/two_rsa" "$tmp/home/.ssh/two_rsa.pub"
printf 'partial dedicated private key\n' > "$tmp/home/.ssh/xpr_os_rsa"
if env "${common_env[@]}" "$tmp/sbin/xpr-init" --install --release "$tmp/home/Downloads/xpr-os-0.1.0-rc6.tar.gz" > "$tmp/incomplete.out" 2>&1; then
  echo 'incomplete dedicated key unexpectedly accepted' >&2; exit 1
fi
grep -q 'dedicated XPR key state is incomplete' "$tmp/incomplete.out"
# The handoff's archive stream must not use the normal SSH probe's -n option.
grep -q 'local -a payload_ssh_opts=("${ssh_opts\[@\]:1}")' "$repo/tools/host/xpr-init"
grep -q 'ssh "${payload_ssh_opts\[@]}" "$mic" '\''cat > /tmp/xpr-rootfs.cpio.gz'\'' < "$payload"' "$repo/tools/host/xpr-init"
! grep -q 'ssh "${ssh_opts\[@]}" "$mic" '\''cat > /tmp/xpr-rootfs.cpio.gz'\'' < "$payload"' "$repo/tools/host/xpr-init"
echo 'XPR_INIT_ARCHIVE_HASH_BINDING=PASS'
echo 'XPR_INIT_STALE_CACHE_REGRESSION=PASS'
echo 'XPR_INIT_INSTALL_TEST=PASS'
