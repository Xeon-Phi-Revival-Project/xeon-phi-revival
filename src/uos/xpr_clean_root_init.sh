#!/bin/sh
# Resident project-owned PID 1 for the first clean-root K1OM experiment.

PATH=/bin:/sbin
export PATH
umask 0022

mkdir -p /proc /sys /dev /run /tmp /etc
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs -o mode=0755 tmpfs /run 2>/dev/null || true
mount -t tmpfs -o mode=1777 tmpfs /tmp 2>/dev/null || chmod 1777 /tmp
hostname xpr-uos

printf '%s\n' XPR_CLEAN_ROOT_SBIN_INIT_PID1 > /run/xpr-os-init
printf 'pid=%s\n' "$$" >> /run/xpr-os-init
uname -m >> /run/xpr-os-init 2>&1 || true
printf '%s\n' XPR_CLEAN_ROOT_SBIN_INIT_PID1 > /dev/kmsg 2>/dev/null || true

/usr/bin/xpr-hello >> /run/xpr-os-init 2>&1 || printf '%s\n' XPR_HELLO_FAIL >> /run/xpr-os-init
/usr/bin/xpr-pthread-smoke >> /run/xpr-os-init 2>&1 || printf '%s\n' XPR_PTHREAD_FAIL >> /run/xpr-os-init

while :; do
    sleep 30
done
