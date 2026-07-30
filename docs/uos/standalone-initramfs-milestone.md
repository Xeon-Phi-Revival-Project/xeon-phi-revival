# Standalone K1OM Initramfs Milestone

This milestone is the first narrow step from the stock-init handoff RC toward a
standalone Option B uOS. It intentionally excludes networking, SSH inside the
experimental image, Dropbear, APT expansion, compiler modernization, and extra
application ports.

## Goal

Boot the stock MPSS Knights Corner kernel with a project-generated
gzip-compressed `newc` cpio image that contains a resident project
`/sbin/init`. The init must remain PID 1 and must not exec stock
`init.sysvinit`.

## Build

Run on the MPSS host with a private, already validated RC rootfs:

```sh
tools/uos/build-standalone-k1om-initramfs.sh \
  --source-rootfs /root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/rootfs/rootfs
```

The builder emits a timestamped private directory under:

```text
/root/xeon-phi-revival-local/uos-standalone-builds/
```

Outputs include:

- standalone rootfs tree;
- `xpr-uos-standalone-pid1.cpio.gz`;
- SHA-256 file;
- complete file manifest;
- build summary;
- inherited local input notes.

Do not commit the generated image, rootfs, or binaries.

## Live Test

Run on the MPSS host only after recording the current stock config hash:

```sh
tools/uos/run-standalone-k1om-initramfs-experiment.sh \
  --image <private-build-dir>/xpr-uos-standalone-pid1.cpio.gz \
  --expected-conf-sha <sha256-of-/etc/mpss/mic0.conf>
```

The runner uses an alternate MPSS config directory, changes only that private
copy, points `Base CPIO` and `RootDevice Ramfs` at private paths, captures
`/dev/ttyMIC0`, collects host logs and ramoops, then restores stock MPSS.

## Pass Criteria

- project init logs `resident_pid=1`;
- `init.sysvinit` is absent;
- `/etc/os-release` reports `ID=xpr-uos`;
- `uname -m` reports `k1om`;
- `/proc`, `/sys`, `/dev`, `/run`, and `/tmp` are usable;
- `/bin/sh` and essential BusyBox-backed commands run;
- `hello-knc` exits successfully;
- pthread create/join smoke exits successfully;
- init reaches `RESIDENT_IDLE=1`;
- rollback restores stock MPSS and stock SSH.

## Current Local-Only Inputs

The first standalone image is still private. It inherits these local-only or
redistribution-review payloads from the current RC:

- `/bin/busybox`, currently copied from the local RC rootfs and still treated
  as stock/local-input derived;
- `libgcc_s.so.1`, currently traced to the local MPSS K1OM SDK;
- project/Ubuntu-source runtime libraries that are working but not yet packaged
  with full public binary-release source/license compliance material.

The standalone image must not include stock `init.sysvinit`, stock card-side
MPSS service scripts, SSH startup payloads, firmware, stock kernels, or MPSS
RPMs.

## Current Live Result

The first generated standalone image built successfully but did not reach
resident project PID 1 on live hardware. See
`docs/uos/standalone-initramfs-live-report.md`.

The precise blocker is now the direct standalone initramfs handoff path:
MPSS/micctrl generated and attempted to boot the private ramfs, but no project
init console banner appeared and `mic0` remained in `booting` until rollback.
Stock MPSS recovery and SSH were verified afterward.
