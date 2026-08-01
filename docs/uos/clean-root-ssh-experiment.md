# Clean-Root SSH Experiment

Date: 2026-08-01

## Scope

This experiment proves the first project-root SSH path after the clean-root
handoff. It uses the existing reversible MPSS alternate-configuration lane.
It does not modify firmware, persistent card storage, the stock kernel, or the
active `/etc/mpss/mic0.conf` configuration.

The project root contains a project-built static BusyBox, project-built smoke
programs, a project-built `xpr-statusd`, a project-built eglibc runtime, and a
locally built Dropbear server. Dropbear is built from a separately obtained
upstream source archive and is not committed as a binary. The build takes an
operator-supplied public `authorized_keys` file; no keys are stored in Git.

The initial dynamic Dropbear build used the MPSS SDK libc ABI and failed with
an exact `GLIBC_2.14` symbol-version mismatch against the project eglibc
runtime. The final build explicitly uses the project eglibc headers, startup
objects, loader, and runtime libraries, and records `/lib64` as its runtime
search path.

## Verified First Boot

Generated private artifacts:

```text
Dropbear SHA-256: a25ed7ee4b04222cd1c9e0a5ca3827fb7b25bca110edce4cf31669f63e3decd2
Root archive SHA-256: a7639f4be726eef87945dfa92c073f174b0bebf90813c75cf86ea226f98011e4
Base CPIO SHA-256: 44c0f2f634a0f513ede47ae135b7a5c005c448463459a2c1ec9420b77e21e758
```

The bounded experiment booted the Base CPIO through an alternate `micctrl
--configdir` configuration and produced all required results:

```text
boot_pass=1
ssh_file_pass=1
tcp_marker_pass=1
rollback_pass=1
```

The project SSH session authenticated the supplied `root` public key and
retrieved `/run/xpr-os-init`, which recorded:

```text
XPR_CLEAN_ROOT_SBIN_INIT_PID1
pid=1
k1om
XPR_HELLO_OK
XPR_PTHREAD_OK
XPR_DROPBEAR_RUNNING
XPR_MPSS_READY_NOTIFIED
```

The same Base CPIO completed three consecutive, independently reset bounded
boots. Each run returned the same `boot_pass=1`, `ssh_file_pass=1`,
`tcp_marker_pass=1`, and `rollback_pass=1` result:

```text
20260801-164721
20260801-165156
20260801-165528
```

After the final experiment, stock `mic0` returned to `online`, MPSS was
active, stock SSH succeeded, and `/etc/mpss/mic0.conf` remained SHA-256:

```text
9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

## Result and Boundary

The project-root networking and SSH lane is repeatable through the supported
MPSS Base CPIO mechanism. This does not yet make the complete early Base CPIO
project-owned: it still provides the local MPSS kernel-module tree required by
the independent project early init before `switch_root`.

Generated images, public keys, host keys, local eglibc stages, and private logs
remain outside version control. The next technical step is to reduce and map
the inherited early Base CPIO module dependency without changing firmware or
persistent card storage.
