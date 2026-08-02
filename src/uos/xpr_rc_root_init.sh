#!/bin/sh
# Project-owned PID 1 for the full xpr-uOS release-candidate root.
# Prepared for integration; not yet executed on the candidate-kernel path.

PATH=/opt/xeon-phi-revival/bin:/bin:/usr/bin:/usr/sbin
export PATH
umask 0022

mkdir -p /proc /sys /dev /run /tmp /etc /var/log/xeon-phi-revival
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
test -c /dev/console || /bin/busybox mknod -m 600 /dev/console c 5 1
test -c /dev/null || /bin/busybox mknod -m 666 /dev/null c 1 3
mount -t tmpfs -o mode=0755 tmpfs /run 2>/dev/null || true
mount -t tmpfs -o mode=1777 tmpfs /tmp 2>/dev/null || chmod 1777 /tmp
hostname xpr-uos

printf '%s\n' XPR_RC_ROOT_SBIN_INIT_PID1 > /run/xpr-os-init
printf 'pid=%s\n' "$$" >> /run/xpr-os-init
uname -m >> /run/xpr-os-init 2>&1 || true

/usr/bin/xpr-hello >> /run/xpr-os-init 2>&1 || printf '%s\n' XPR_HELLO_FAIL >> /run/xpr-os-init
/usr/bin/xpr-pthread-smoke >> /run/xpr-os-init 2>&1 || printf '%s\n' XPR_PTHREAD_FAIL >> /run/xpr-os-init

/bin/busybox ifconfig mic0 172.31.1.1 netmask 255.255.255.0 mtu 64512 up >> /run/xpr-os-init 2>&1 || {
    printf '%s\n' XPR_NETWORK_CONFIG_FAIL >> /run/xpr-os-init
}
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
else
    printf '%s\n' XPR_MPSS_READY_PATH_MISSING >> /run/xpr-os-init
fi

/etc/init.d/xeon-phi-revival-stage2 start >> /run/xpr-os-init 2>&1 &
printf '%s\n' XPR_RC_STAGE2_STARTED >> /run/xpr-os-init

while :; do
    sleep 30
done
