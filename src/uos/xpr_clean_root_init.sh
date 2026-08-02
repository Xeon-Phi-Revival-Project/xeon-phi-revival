#!/bin/sh
# Resident project-owned PID 1 for the first clean-root K1OM experiment.

PATH=/bin:/sbin
export PATH
umask 0022

mkdir -p /proc /sys /dev /run /tmp /etc
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
test -c /dev/console || mknod -m 600 /dev/console c 5 1
test -c /dev/null || mknod -m 666 /dev/null c 1 3
test -c /dev/zero || mknod -m 666 /dev/zero c 1 5
test -c /dev/random || mknod -m 666 /dev/random c 1 8
test -c /dev/urandom || mknod -m 666 /dev/urandom c 1 9
mount -t tmpfs -o mode=0755 tmpfs /run 2>/dev/null || true
mount -t tmpfs -o mode=1777 tmpfs /tmp 2>/dev/null || chmod 1777 /tmp
hostname xpr-uos

printf '%s\n' XPR_CLEAN_ROOT_SBIN_INIT_PID1 > /run/xpr-os-init
printf 'pid=%s\n' "$$" >> /run/xpr-os-init
uname -m >> /run/xpr-os-init 2>&1 || true
printf '%s\n' XPR_CLEAN_ROOT_SBIN_INIT_PID1 > /dev/kmsg 2>/dev/null || true

/usr/bin/xpr-hello >> /run/xpr-os-init 2>&1 || printf '%s\n' XPR_HELLO_FAIL >> /run/xpr-os-init
/usr/bin/xpr-pthread-smoke >> /run/xpr-os-init 2>&1 || printf '%s\n' XPR_PTHREAD_FAIL >> /run/xpr-os-init

# This first project root targets the StaticPair values documented in mic0.conf.
ifconfig mic0 172.31.1.1 netmask 255.255.255.0 mtu 64512 up >> /run/xpr-os-init 2>&1 || {
    printf '%s\n' XPR_NETWORK_CONFIG_FAIL >> /run/xpr-os-init
}
/usr/bin/xpr-statusd >> /run/xpr-os-init 2>&1 &
statusd_pid=$!
printf 'statusd_pid=%s\n' "$statusd_pid" >> /run/xpr-os-init
mkdir -p /etc/dropbear
/usr/sbin/dropbear -R -F -p 22 >> /run/xpr-os-init 2>&1 &
dropbear_pid=$!
printf 'dropbear_pid=%s\n' "$dropbear_pid" >> /run/xpr-os-init
sleep 1
if kill -0 "$dropbear_pid" 2>/dev/null; then
    printf '%s\n' XPR_DROPBEAR_RUNNING >> /run/xpr-os-init
else
    printf '%s\n' XPR_DROPBEAR_EXITED >> /run/xpr-os-init
fi

if test -e /sys/class/micnotify/notify/host_notified; then
    printf '%s\n' done > /sys/class/micnotify/notify/host_notified
    printf '%s\n' XPR_MPSS_READY_NOTIFIED >> /run/xpr-os-init
    printf '%s\n' XPR_MPSS_READY_NOTIFIED > /dev/kmsg 2>/dev/null || true
else
    printf '%s\n' XPR_MPSS_READY_PATH_MISSING >> /run/xpr-os-init
fi

while :; do
    if test -f /run/xpr-switch-root-request; then
        newroot=$(sed -n '1p' /run/xpr-switch-root-request 2>/dev/null || true)
        requested_sha=$(sed -n '2p' /run/xpr-switch-root-request 2>/dev/null || true)
        if test "$newroot" = /run/xpr-newroot && test "${#requested_sha}" = 64 && test -x "$newroot/sbin/init"; then
            printf '%s\n' XPR_SWITCH_ROOT_BEGIN >> /run/xpr-stage-root.log
            mount --move /proc "$newroot/proc" 2>/dev/null || true
            mount --move /sys "$newroot/sys" 2>/dev/null || true
            mount --move /dev "$newroot/dev" 2>/dev/null || true
            exec switch_root "$newroot" /sbin/init
        fi
        printf '%s\n' XPR_SWITCH_ROOT_REQUEST_REJECTED >> /run/xpr-stage-root.log
        rm -f /run/xpr-switch-root-request
    fi
    sleep 30
done
