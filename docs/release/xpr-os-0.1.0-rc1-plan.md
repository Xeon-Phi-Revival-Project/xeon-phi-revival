# XPR-OS 0.1.0 RC1 Plan

## Release Architecture

`SPLIT_PAYLOAD_REQUIRED` for RC1.

The reproducible boot artifact remains the proven small candidate Base CPIO
and project root. The full Ubuntu-derived root is a separately checksummed
payload supplied only after project networking and SSH are available.

```text
boot/xpr-bootstrap.cpio.gz -> candidate online -> project SSH
payload/xpr-rootfs.cpio.gz -> host transfer -> hash verification -> switch_root
```

The release workflow will remain one host-side command: build the bootstrap,
boot through the existing alternate MicDir configuration, wait for the project
readiness marker, transfer the local payload, verify its SHA-256 on-card, and
request the project root switch. It does not require firmware changes,
persistent card storage, internet access, or embedding the full root in Base
CPIO.

## Evidence Boundary

The small bootstrap path has three passing boots with project PID 1, MPSS
readiness, networking, Dropbear SSH, hello, pthread, and rollback. The direct
large-root path failed with both a static BusyBox and a Python-runtime-masked
root, while a larger synthetic Base CPIO reached `online`. See
[RC root size analysis](../kernel/rc-root-size-analysis.md).

## Next Implementation

The implementation now consists of a gzip-newc payload preparer, a bootstrap
`xpr-stage-root` command, and a PID 1 request handler. The host runner accepts
an optional payload, streams it through the proven SSH shell into BusyBox
`cat`, invokes staging, and waits for the RC PID 1 marker before its existing
rollback trap.

Static validation confirms payload gzip/newc integrity and required paths. The
first bounded hardware test reached bootstrap online and SSH but found that the
minimal card root has no remote `scp` command. The exact next validation is a
single SSH-stream payload transfer, followed by checksum, staging, PID 1
`switch_root`, RC SSH, smoke tests, and rollback.
