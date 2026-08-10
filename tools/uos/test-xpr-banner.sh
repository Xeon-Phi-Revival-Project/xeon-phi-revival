#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
banner="$repo_root/src/uos/xpr-banner.txt"

[[ -s "$banner" ]] || { echo "missing XPR-OS banner" >&2; exit 1; }
grep -q 'Xeon Phi Revival K1OM uOS' "$banner"
grep -q 'Xeon-Phi-Revival-Project' "$banner"
LC_ALL=C grep -q '[^ -~]' "$banner" && { echo "banner must remain ASCII" >&2; exit 1; } || true
awk 'length($0) > 78 { exit 1 }' "$banner" || { echo "banner line exceeds 78 columns" >&2; exit 1; }
grep -q $'\033' "$banner" && { echo "banner must not contain terminal escapes" >&2; exit 1; } || true

grep -q 'cat /etc/motd > /dev/console' "$repo_root/src/uos/xpr_rc_root_init.sh"
grep -q 'XPR_SPLASH_DISPLAYED' "$repo_root/src/uos/xpr_rc_root_init.sh"
grep -q 'xpr-banner.txt.*etc/motd' "$repo_root/tools/uos/build-xpr-clean-rootfs.sh"
grep -q 'xpr-banner.txt.*etc/motd' "$repo_root/tools/ubuntu-port/build-k1om-minimal-ubuntu-rootfs.sh"
grep -q 'replace-entry-file.*etc/motd' "$repo_root/tools/release/prepare-xpr-rootfs-payload.sh"

echo "PASS: XPR-OS boot/login banner"
