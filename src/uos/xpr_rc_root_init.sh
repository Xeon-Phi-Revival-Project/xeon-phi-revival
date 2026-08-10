#!/bin/sh
# Project-owned PID 1 for the full XPR-OS release-candidate root.

PATH=/opt/xeon-phi-revival/bin:/bin:/usr/bin:/usr/sbin
export PATH
umask 0022

handoff_log=/xpr-handoff.log
old_mark() {
    case "${XPR_HANDOFF_FD:-}" in
        ''|*[!0-9]*) ;;
        *) eval "printf '%s\\n' \"\$1\" >&$XPR_HANDOFF_FD" ;;
    esac
}
printf '%s\n' XPR_RC_INIT_ENTERED >> "$handoff_log"
printf 'pid=%s\n' "$$" >> "$handoff_log"
printf '%s\n' XPR_RC_INIT_ENTERED > /dev/console 2>/dev/null || true
printf '%s\n' XPR_RC_INIT_ENTERED > /dev/kmsg 2>/dev/null || true
old_mark XPR_RC_SCRIPT_ENTERED

mark() {
    printf '%s\n' "$1" >> /run/xpr-os-init
    printf '%s\n' "$1" >> "$handoff_log"
    printf 'XPR_RC %s\n' "$1" > /dev/console 2>/dev/null || true
    printf '%s\n' "$1" > /dev/kmsg 2>/dev/null || true
    old_mark "$1"
}

mkdir -p /proc /sys /dev /run /tmp /etc /var/log/xeon-phi-revival
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts 2>/dev/null || true
test -c /dev/console || /bin/busybox mknod -m 600 /dev/console c 5 1
test -c /dev/null || /bin/busybox mknod -m 666 /dev/null c 1 3
test -c /dev/zero || /bin/busybox mknod -m 666 /dev/zero c 1 5
test -c /dev/random || /bin/busybox mknod -m 666 /dev/random c 1 8
test -c /dev/urandom || /bin/busybox mknod -m 666 /dev/urandom c 1 9
# KNC's devtmpfs does not supply ptmx; Dropbear needs the legacy Unix98 node.
test -c /dev/ptmx || /bin/busybox mknod -m 666 /dev/ptmx c 5 2
mount -t tmpfs -o mode=0755 tmpfs /run 2>/dev/null || true
mount -t tmpfs -o mode=1777 tmpfs /tmp 2>/dev/null || chmod 1777 /tmp
hostname xpr-uos

mark XPR_RC_ROOT_SBIN_INIT_PID1
printf 'pid=%s\n' "$$" >> /run/xpr-os-init
uname -m >> /run/xpr-os-init 2>&1 || true
mark XPR_RC_INIT_MOUNTS_READY

if test -r /etc/motd; then
    cat /etc/motd > /dev/console 2>/dev/null || true
    cat /etc/motd >> /run/xpr-os-init 2>/dev/null || true
    mark XPR_SPLASH_DISPLAYED
else
    mark XPR_SPLASH_MISSING
fi

smoke_failed=0
/usr/bin/xpr-hello >> /run/xpr-os-init 2>&1 || { printf '%s\n' XPR_HELLO_FAIL >> /run/xpr-os-init; smoke_failed=1; }
/usr/bin/xpr-pthread-smoke >> /run/xpr-os-init 2>&1 || { printf '%s\n' XPR_PTHREAD_FAIL >> /run/xpr-os-init; smoke_failed=1; }
/usr/bin/xpr-dlopen-smoke >> /run/xpr-os-init 2>&1 || { printf '%s\n' XPR_DLOPEN_FAIL >> /run/xpr-os-init; smoke_failed=1; }
test "$smoke_failed" = 0 && mark XPR_SMOKE_PASS
mark XPR_RC_SMOKES_COMPLETE

/bin/busybox ifconfig mic0 172.31.1.1 netmask 255.255.255.0 mtu 64512 up >> /run/xpr-os-init 2>&1 && {
    mark XPR_NETWORK_READY
} || {
    printf '%s\n' XPR_NETWORK_CONFIG_FAIL >> /run/xpr-os-init
}

# Start the diagnostic endpoint after the virtual interface is configured,
# matching the known-good clean-root service ordering.
if test -x /usr/bin/xpr-statusd; then
    /usr/bin/xpr-statusd >> /run/xpr-os-init 2>&1 &
    statusd_pid=$!
    printf 'statusd_pid=%s\n' "$statusd_pid" >> /run/xpr-os-init
    mark XPR_RC_STATUSD_STARTED
else
    mark XPR_RC_STATUSD_MISSING
fi

mkdir -p /etc/dropbear
# A test-only static probe can replace Dropbear to distinguish port reachability
# from daemon behavior. Normal release images do not include this binary.
if test -x /usr/bin/xpr-port22-probe; then
    /usr/bin/xpr-port22-probe >> /run/xpr-os-init 2>&1 &
    port22_probe_pid=$!
    printf 'port22_probe_pid=%s\n' "$port22_probe_pid" >> /run/xpr-os-init
    mark XPR_PORT22_PROBE_STARTED
else
    # Bind explicitly to the MPSS virtual IPv4 address. Legacy Dropbear defaults
    # are not sufficient evidence that port 22 is reachable from the host.
    /usr/sbin/dropbear -R -F -p 172.31.1.1:22 >> /run/xpr-os-init 2>&1 &
    dropbear_pid=$!
    printf 'dropbear_pid=%s\n' "$dropbear_pid" >> /run/xpr-os-init
    sleep 1
    if kill -0 "$dropbear_pid" 2>/dev/null; then
        mark XPR_DROPBEAR_RUNNING
    else
        mark XPR_DROPBEAR_EXITED
    fi
fi
port22_listening=0
for tcp_table in /proc/net/tcp /proc/net/tcp6; do
    test -r "$tcp_table" || continue
    while IFS= read -r tcp_line; do
        case "$tcp_line" in
            *:0016\ *)
                printf '%s\n' "$tcp_line" >> /run/xpr-os-init
                port22_listening=1
                ;;
        esac
    done < "$tcp_table"
done
test "$port22_listening" = 1 || mark XPR_DROPBEAR_PORT22_NOT_LISTENING
test "$port22_listening" = 1 && mark XPR_SSH_READY

if test -e /sys/class/micnotify/notify/host_notified; then
    printf '%s\n' done > /sys/class/micnotify/notify/host_notified
    mark XPR_MPSS_READY_NOTIFIED
else
    mark XPR_MPSS_READY_PATH_MISSING
fi

if test -x /etc/init.d/xeon-phi-revival-stage2; then
    /etc/init.d/xeon-phi-revival-stage2 start >> /run/xpr-os-init 2>&1 &
    mark XPR_RC_STAGE2_STARTED
fi

while :; do
    sleep 30
done
