# Verify XPR-OS

For RC7, first complete the [readiness check](rc7.md#3-boot-and-wait-for-the-final-root),
then run `ssh xpr-mic0` on the host. RC6 uses its
[separate SSH instructions](ssh-access.md#frozen-rc6).

On the **card**:

```bash
cat /run/xpr-os-init
uname -m
/bin/busybox tr '\000' ' ' </proc/1/cmdline
echo
ip addr
ip route
/usr/bin/xpr-hello
/usr/bin/xpr-pthread-smoke
/usr/bin/xpr-dlopen-smoke
```

Require `XPR_RC_ROOT_SBIN_INIT_PID1` and `XPR_NETWORK_READY`, architecture
`k1om`, and `/sbin/init` in the PID 1 command line. Its shell interpreter may
appear as `/bin/sh`; the markers identify the XPR final-root script.
Expected smoke output is `XPR_HELLO_OK`, `XPR_PTHREAD_OK`, and
`xpr-dlopen-smoke: ok`.

RC7 also provides:

```bash
command -v python3
python3 --version
python3 -c 'import platform; print(platform.machine())'
```

Expected: `/usr/bin/python3`, `Python 3.12.13`, and `k1om`.
See the RC7 guide for a real threading and JSON/file example and the known
nonblocking Python startup warning. Python is not part of frozen RC6.

On the **host**, `sudo xpr-init --status` identifies the selected release hash,
XPR/stock mode, handoff state and recovery availability. An inactive handoff
unit after success is normal; use the final-root markers to determine readiness.
