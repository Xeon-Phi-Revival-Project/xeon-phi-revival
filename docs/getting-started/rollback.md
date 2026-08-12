# Returning To Stock MPSS

Rollback means returning `mic0` to the original MPSS configuration and stock
card userspace. XPR-OS does not flash firmware or change persistent card
storage.

The canonical runner normally rolls back automatically when it exits. If you
used `--leave-running`, end the session and use the generated runner logs to
perform recovery. On the **MPSS host**, inspect the most recent run directory:

```bash
ls -dt "$HOME"/xpr-candidate-kernel-test/base-cpio-control-* | head -n 1
```

The runner's exit trap invokes its tested stock restore sequence. If recovery
was interrupted, do not improvise a firmware operation. First restore normal
MPSS service and confirm:

```bash
systemctl start mpss
micctrl --status
ssh mic0 'uname -m; cat /proc/1/comm'
sha256sum /etc/mpss/mic0.conf
```

Expected: `mic0: online`, stock `k1om`, `init`, and the configuration hash
saved before the XPR-OS run. If that does not occur, stop and collect the run
directory, `micctrl --status`, and MPSS service output before changing any
firmware or persistent settings.

