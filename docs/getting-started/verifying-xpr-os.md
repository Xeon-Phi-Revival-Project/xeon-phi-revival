# Verifying A Running XPR-OS System

Run these commands after connecting to `mic0`. They prove that the final XPR
root, not merely the bootstrap, is running.

```bash
cat /proc/1/comm
cat /run/xpr-os-init
uname -m
cat /etc/os-release
ip addr
ip route
/usr/bin/xpr-hello
/usr/bin/xpr-pthread-smoke
/usr/bin/xpr-dlopen-smoke
```

Expected evidence includes:

- `init` or `busybox` as the final PID 1 process, plus
  `XPR_RC_ROOT_SBIN_INIT_PID1` in `/run/xpr-os-init`.
- `k1om` from `uname -m` and `ID=xpr-uos` in `/etc/os-release`.
- A micveth interface and a usable route.
- `XPR_HELLO_OK`, `XPR_PTHREAD_OK`, and `XPR_DLOPEN_OK` from the native probes.

From the **MPSS host**, confirm the same SSH path is usable:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa mic0 'uname -m; cat /proc/1/comm'
```

Each check has a specific purpose: PID 1 proves the final root handoff,
networking proves micveth, and the three probes exercise the public dynamic
runtime, threads, and dynamic loading.

