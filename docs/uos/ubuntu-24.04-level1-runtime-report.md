# Ubuntu 24.04 uOS Level 1 Runtime Report

Public-safe runtime report. Private staged rootfs contents, archives, and raw
logs remain local-only.

## Result

Level 1 passed for a reversible chroot-style runtime test.

The test did not replace the stock MPSS boot image. The stock MPSS kernel and
uOS remained the active boot path. A tiny K1OM rootfs was staged into a
timestamped local-only directory on the MPSS host, copied temporarily to `/tmp`
on `mic0`, tested with `chroot`, and removed from the card after the run.

## Staged Rootfs Contents

The staged rootfs was assembled from a local stock MPSS 3.4.10 uOS extraction
plus the project-built `hello-knc` binary.

Metadata validation proved:

- required paths were present:
  - `/sbin/init`
  - `/bin/sh`
  - `/bin/bash`
  - `/bin/busybox`
  - `/lib64/ld-linux-k1om.so.2`
  - `/lib64/libc.so.6`
  - `/lib64/libgcc_s.so.1`
  - `/etc/inittab`
  - `/etc/fstab`
  - `/etc/passwd`
- symlink targets closed inside the staged rootfs
- checked ELF files reported `e_machine=181`
- the generated public-safe manifest had 38 rows

Checked K1OM ELF files included:

- `/usr/bin/hello-knc`
- `/bin/bash`
- `/bin/busybox`
- `/sbin/init.sysvinit`
- `/lib64/ld-2.14.1.so`
- `/lib64/libc-2.14.1.so`
- `/lib64/libdl-2.14.1.so`
- `/lib64/libgcc_s.so.1`
- `/lib64/libm-2.14.1.so`
- `/lib64/libpthread-2.14.1.so`
- `/lib64/libtinfo.so.5.9`

## Runtime Checks

Inside `mic0`, the staged rootfs was extracted under `/tmp` and tested with
`chroot`.

Passing checks:

```text
chroot /tmp/tiny-k1om-level1 /bin/busybox echo tiny-rootfs-busybox-ok
tiny-rootfs-busybox-ok
```

```text
chroot /tmp/tiny-k1om-level1 /usr/bin/hello-knc
hello from knc
sysname=Linux
release=2.6.38.8+mpss3.4.10
machine=k1om
sizeof(void*)=8
sizeof(long)=8
```

The shell also executed a script from the staged rootfs that called
`/bin/busybox`.

## Interpretation

Level 1 is complete enough to open Level 2. The project now has evidence that a
small custom K1OM rootfs can execute basic commands under the stock MPSS kernel
using a reversible chroot test.

This does not yet prove that the tiny rootfs can replace the stock initramfs or
boot as PID 1. That should remain a separate copy-based boot-image experiment.
