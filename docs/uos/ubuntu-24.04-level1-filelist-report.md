# Ubuntu 24.04 uOS Level 1 File-List Report

Public-safe path metadata report derived from a local stock uOS inventory summary. The raw inventory log remains local-only and ignored.

## Inputs

- Candidate manifest: `uos/ubuntu2404/level1-tiny-rootfs-manifest.txt`
- Local source: ignored stock uOS inventory summary log

## Candidate Files Observed

### `/bin/busybox`

- `-rwsr-xr-x    1 root     root        574408 Jan 12  2017 /bin/busybox`
- `/bin/busybox: setuid ELF 64-bit LSB executable, Intel Xeon Phi coprocessor (k1om), version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.16, stripped`
- `-rwsr-xr-x   1 root     root       574408 Jan 12  2017 bin/busybox`

### `/etc/fstab`

- `-rw-r--r--    1 root     root           113 Jul 27 20:28 /etc/fstab`
- `/etc/fstab: ASCII text`

### `/etc/inittab`

- `-rw-r--r--    1 root     root           844 Jan 12  2017 /etc/inittab`
- `/etc/inittab: ASCII text`

### `/etc/passwd`

- `-rw-r--r--    1 root     root           244 Jul 27 20:28 /etc/passwd`
- `/etc/passwd: ASCII text`

### `/lib64/ld-linux-k1om.so.2`

- `lrwxrwxrwx    1 root     root            12 Dec 31  1969 /lib64/ld-linux-k1om.so.2 -> ld-2.14.1.so`
- `/lib64/ld-linux-k1om.so.2: symbolic link to ld-2.14.1.so'`
- `lrwxrwxrwx   1 root     root           12 Jan 12  2017 lib64/ld-linux-k1om.so.2 -> ld-2.14.1.so`

### `/lib64/libc.so.6`

- `lrwxrwxrwx    1 root     root            14 Dec 31  1969 /lib64/libc.so.6 -> libc-2.14.1.so`
- `/lib64/libc.so.6: symbolic link to libc-2.14.1.so'`
- `lrwxrwxrwx   1 root     root           14 Jan 12  2017 lib64/libc.so.6 -> libc-2.14.1.so`

### `/lib64/libgcc_s.so.1`

- `-rwxr-xr-x   1 root     root        74560 Jan 12  2017 lib64/libgcc_s.so.1`

### `/sbin/init`

- `lrwxrwxrwx    1 root     root            19 Dec 31  1969 /sbin/init -> /sbin/init.sysvinit`
- `/sbin/init: symbolic link to /sbin/init.sysvinit'`

## Directories To Create In A Test Rootfs

- `/dev`
- `/home`
- `/proc`
- `/root`
- `/run`
- `/sys`
- `/tmp`

## Candidate Files Not Yet Observed In This Local Summary

- `/bin/sh`
- `/etc/group`
- `/etc/hosts`
- `/etc/resolv.conf`
- `/lib64/libdl.so.2`
- `/lib64/libm.so.6`
- `/lib64/libpthread.so.0`
- `/usr/bin/hello-knc`

## Interpretation

- The stock uOS inventory has path evidence for the loader, libc, `libgcc_s`, init, BusyBox, and several basic config files needed by the Level 1 candidate.
- Directory creation is part of the replacement-rootfs assembly recipe and is not proved by ELF metadata.
- `/usr/bin/hello-knc` is project-built and should be inserted into a local-only test rootfs during the first boot/chroot experiment.
- The next dependency is a local-only rootfs staging script that copies or links reviewed files into a test tree and writes a public-safe manifest of paths and hashes.