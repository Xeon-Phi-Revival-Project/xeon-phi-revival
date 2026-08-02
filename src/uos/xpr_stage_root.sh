#!/bin/sh
# Stage a gzip-newc root payload in RAM. PID 1 performs the actual switch.
set -eu

PATH=/bin:/sbin
export PATH

payload=${1:-}
expected=${2:-}
log=/run/xpr-stage-root.log
newroot=/xpr-newroot

mark() {
    printf '%s\n' "$1" >> "$log"
    test -d "$newroot/run" && printf '%s\n' "$1" >> "$newroot/run/xpr-stage-root.log"
    printf '%s\n' "$1" > /dev/kmsg 2>/dev/null || true
}

test -f "$payload" || { mark XPR_PAYLOAD_MISSING; exit 2; }
test "${#expected}" = 64 || { mark XPR_PAYLOAD_HASH_INVALID; exit 2; }
actual=$(sha256sum "$payload" | awk '{print $1}')
test "$actual" = "$expected" || { mark XPR_PAYLOAD_HASH_FAIL; exit 3; }
mark XPR_PAYLOAD_HASH_OK

mkdir -p "$newroot"
# BusyBox switch_root requires NEW_ROOT to be a mount point. Keeping it outside
# /run also lets PID 1 move the bootstrap /run mount into the new root.
mount -t tmpfs -o mode=0755 tmpfs "$newroot" || { mark XPR_NEWROOT_MOUNT_FAIL; exit 4; }
gzip -dc "$payload" | (cd "$newroot" && cpio -idm) || { mark XPR_PAYLOAD_EXTRACT_FAIL; exit 4; }
mark XPR_PAYLOAD_EXTRACT_OK

for path in sbin/init bin/busybox usr/sbin/dropbear usr/bin/xpr-hello usr/bin/xpr-pthread-smoke etc; do
    test -e "$newroot/$path" || { mark "XPR_NEWROOT_MISSING_$path"; exit 5; }
done
test -x "$newroot/sbin/init" || { mark XPR_NEWROOT_INIT_NOT_EXECUTABLE; exit 6; }
test -x "$newroot/bin/busybox" || { mark XPR_NEWROOT_BUSYBOX_NOT_EXECUTABLE; exit 7; }
mkdir -p "$newroot/proc" "$newroot/sys" "$newroot/dev" "$newroot/run" "$newroot/tmp"
chmod 1777 "$newroot/tmp"
printf '%s\n%s\n' "$newroot" "$expected" > /run/xpr-switch-root-request
mark XPR_SWITCH_REQUEST_WRITTEN
