# Ubuntu 24.04 uOS Level 1 Gap Report

Public-safe metadata report. It uses path and ELF dependency metadata only; no Intel uOS file contents are included.

## Inputs

- Inventory CSV: `artifacts/public/uos-elf-inventory.csv`
- Candidate manifest: `uos/ubuntu2404/level1-tiny-rootfs-manifest.txt`

## ELF Paths Present In Public Inventory

- `/bin/busybox`
- `/lib64/libgcc_s.so.1`

## Manifest Paths Not Proven By ELF Inventory

These may still exist in the stock uOS; this report only uses the public ELF inventory, so directories, text config, symlinks, devices, and non-ELF files need a separate file-list check.

- `/bin/sh`
- `/dev`
- `/etc/fstab`
- `/etc/group`
- `/etc/hosts`
- `/etc/inittab`
- `/etc/passwd`
- `/etc/resolv.conf`
- `/home`
- `/lib64/ld-linux-k1om.so.2`
- `/lib64/libc.so.6`
- `/lib64/libdl.so.2`
- `/lib64/libm.so.6`
- `/lib64/libpthread.so.0`
- `/proc`
- `/root`
- `/run`
- `/sbin/init`
- `/sys`
- `/tmp`
- `/usr/bin/hello-knc`

## Library Dependencies Referenced By Candidate ELF Files

- `libc.so.6`
- `libdl.so.2`
- `libtinfo.so.5`

## Initial Interpretation

- The public ELF inventory proves stock K1OM executable metadata for shell and BusyBox candidates.
- The Level 1 rootfs still needs a public-safe file-list check for init, symlinks, config files, directories, device setup, and MPSS integration.
- A boot attempt should use a copy of the stock image or a separate local test image with a documented rollback path.