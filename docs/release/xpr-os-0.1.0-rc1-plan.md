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
first bounded hardware test found that the minimal card root has no remote
`scp` command; the subsequent binary-clean SSH-stream test corrected that
transport and passed its byte-count, SHA-256, and extraction gates. Bootstrap
online, project SSH, and readiness also passed in that run.

The instrumented handoff test identified the earliest failed stage: after a
valid transfer and extraction, `xpr-stage-root` rejected the unpacked root
because `/sbin/init` was not executable. It therefore never wrote the switch
request; PID 1, `switch_root`, and RC services were not involved.

The corrected payload test passed its archive-mode assertion and extracted
`/sbin/init` validation. It then stopped before request creation because the
minimal bootstrap root does not provide the `chmod` BusyBox applet required by
`xpr-stage-root` to prepare the new root. The next bounded test must add only
that bootstrap applet, rebuild the bootstrap Base CPIO, and retain the same
corrected payload. No kernel, module, transport, or RC-service change is
currently justified.

That test added `chmod` successfully and reached
`XPR_SWITCH_REQUEST_WRITTEN` and `XPR_SWITCH_REQUEST_SEEN`. PID 1 then
rejected the request before new-root revalidation because its mount check uses
`grep`, which is the next missing bootstrap BusyBox applet. The exact next
change is therefore to add only `grep` to the bootstrap applet list and repeat
one bounded test with the unchanged payload.

The grep-enabled test passed request creation and candidate bootstrap checks,
but produced no durable marker after `XPR_SWITCH_REQUEST_WRITTEN` and no RC
SSH evidence. The next session must improve persistence of the handoff marker
across the root transition before making another functional change; no further
applet, payload, kernel, module, or transport change is justified by this run.
