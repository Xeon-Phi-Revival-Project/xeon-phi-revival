# First Candidate Kernel Boot Result

Date: 2026-08-02

One bounded RAM-only boot used an alternate MPSS configuration directory. The
active `/etc/mpss/mic0.conf` was not modified.

| Item | Result |
| --- | --- |
| Candidate kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| Candidate Base CPIO | `e458cf6d406a2336c6992853eacfa42796ebe9c34ea8a9a518c0786d56a69433` |
| MPSS image acceptance | passed: `micctrl` reported candidate `bzImage` booting |
| Online transition | failed: remained `booting` through 18 five-second polls |
| Additional candidate boots | none |
| Stock rollback | passed |
| Stock SSH after rollback | passed: `k1om`, PID 1 `init` |
| Stock config SHA-256 | `9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51` |

The experiment reached the kernel-handoff stage but produced no `online`,
network, or SSH evidence for the candidate. The earliest observed failure is
therefore after MPSS accepts the image and before the card-side readiness
handshake completes. No firmware, ROM, flash, persistent card storage, stock
kernel, or stock active MPSS configuration was modified.

Read-only analysis identified a release-directory mismatch: the candidate and
rebuilt modules report `2.6.38.8+mpss3.5.1`, but the tested CPIO placed them
under `2.6.38.8+mpss3.4.10`.

## Corrected Module-Discovery Test

One further bounded RAM-only boot changed only candidate module discovery:
the same candidate kernel used a Base CPIO that adds the rebuilt five-module
set and a minimal `modules.dep` under the candidate's actual
`2.6.38.8+mpss3.5.1` release directory.

| Item | Result |
| --- | --- |
| Candidate kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| Corrected Base CPIO | `7ce52df3fd115984f3ec191abb4a1fb2b336f477797103806b79064c011afe0e` |
| MPSS image acceptance | passed |
| Candidate `online` | passed on poll 4 (about 17 seconds) |
| Host evidence | `MIC 0 Network link is up`; then `booting` to `online` |
| Candidate SSH/PID 1 | not tested before rollback |
| Stock rollback | passed |
| Stock SSH after rollback | passed: `k1om`, PID 1 `init` |
| Stock config SHA-256 | `9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51` |

The initial failure was therefore consistent with the release-directory and
dependency-index mismatch. The next technical step is a single candidate boot
that verifies the already-proven project SSH/PID-1 markers before rollback;
it should not alter the kernel, rootfs, or module set.

## Candidate Project-Root Verification

That bounded verification boot used the same candidate kernel and corrected
Base CPIO, reached `online` on poll 4, and then authenticated to project-built
Dropbear before stock rollback. Its project log reported:

```text
project_ssh_ok
XPR_CLEAN_ROOT_SBIN_INIT_PID1
pid=1
k1om
XPR_HELLO_OK
XPR_PTHREAD_OK
XPR_DROPBEAR_RUNNING
XPR_MPSS_READY_NOTIFIED
```

The SSH server recorded successful public-key authentication from the host.
The candidate therefore reached project `/sbin/init` as PID 1, project
networking/readiness, project Dropbear SSH, and the project hello/pthread
smoke path. The alternate configuration was removed afterward; stock `mic0`
returned to `online`, stock SSH returned `k1om` and PID 1 `init`, and the stock
configuration hash again matched the baseline.

## Three-Boot Repeatability Gate

The unchanged candidate kernel and corrected minimal Base CPIO completed three
valid project-root boots: the project-root verification above and two dedicated
repeat runs at `20260802-044250` and `20260802-044956`. Each run reached
`online`, authenticated to project Dropbear, reported project `/sbin/init` as
PID 1, passed the hello and pthread markers, and then restored stock MPSS.
Every rollback returned stock SSH with `uname -m` `k1om` and the baseline stock
configuration hash. The final stock check reported its normal stock PID 1 as
`systemd`.

The common minimal Base CPIO was `7ce52df3fd115984f3ec191abb4a1fb2b336f477797103806b79064c011afe0e`.
Its compressed size was 29,313,792 bytes; its unpacked newc size was 68,657,588
bytes. The detailed per-boot evidence is recorded in
[candidate-repeatability.md](candidate-repeatability.md).

## Release-Candidate Root Smoke Integration

The first full release-candidate root integration used the same candidate
kernel and module set, but embedded the 0.1 RC root archive and its
project-owned RC `/sbin/init`. The generated Base CPIO was
`8362f1eb93c5c537b3cc640f6d38330dc549fd501affae58a2b3284a8cdc7b31`
(61,978,777 bytes compressed; 101,601,908 bytes unpacked). Static archive
inspection confirmed the outer early init, project root archive, candidate
module directory, and the embedded RC `/sbin/init`, Dropbear, hello, pthread,
APT, and Python files.

MPSS generated its final ramfs image
`7605e1051cfc51aec9c3d8280cf1b6e1582f48021cf0ba518831cd04ac295259`, but
the card remained `booting` through the bounded 24-poll wait. Host logs showed
the virtual network link, but no `booting` to `online` transition. Therefore
the RC `/sbin/init`, SSH, and release smoke suite did not execute and are not
claimed as passing on the candidate kernel. Automatic rollback restored stock
MPSS, stock SSH, and the exact baseline configuration hash.

Two follow-up controls eliminated that size correlation as the primary cause:
one matched the large outer Base CPIO size with an inert outer member and
reached `online`; the other matched the nested RC root archive size with inert
data inside the known-good clean root and reached project SSH. See
[rc-root-isolation-controls.md](rc-root-isolation-controls.md). The remaining
failure boundary is after the RC root becomes active and before its readiness
notification. Do not retry the full RC root unchanged.

Later controls proved the RC init itself and its SSH path after restoring the
missing random-device nodes. A full RC root still failed before userspace,
while a clean-root archive at the same 127,552,616-byte unpacked workload
passed project SSH. The remaining boundary is full-root early userspace,
currently narrowed to its dynamic BusyBox shell/runtime. See
[rc-root-isolation-controls.md](rc-root-isolation-controls.md).

## Static BusyBox Retry

After stale generated experiment output was removed, the retry used a full RC
image with only the RC BusyBox replaced by the previously proven static
BusyBox. The project input image SHA-256 was
`b28da0f987acb1c36346df3f144e97a784afd7f6e1f7ebb348edce43484f9bb6`.

MPSS generated the final ramfs successfully, but the candidate remained
`booting` through the complete bounded 24-poll window. Project init, SSH, and
the smoke suite did not execute. Automatic rollback verified stock `mic0`
online, stock SSH (`k1om`, PID 1 `init`), and the exact baseline MPSS
configuration hash. Replacing dynamic BusyBox alone did not resolve the
full-RC boot boundary.

## Synthetic Size Boundary Control

The first post-static-BusyBox control added deterministic incompressible
padding to the passing Base CPIO until it was 106,954,752 unpacked bytes and
67,514,239 compressed bytes, both larger than the failing RC Base CPIO. MPSS
generated the image and candidate `mic0` reached `online` on poll 6. The
single SSH attempt occurred before Dropbear was proven ready, so no project
SSH claim is made. Automatic rollback restored stock online, stock SSH, and
the exact configuration hash.

The full RC failure is therefore content- or nested-root-layout-specific, not
a simple compressed or unpacked Base CPIO ceiling.

## Python Runtime Content Control

The final bounded control masked 2,764 Python-runtime members inside the full
RC nested root without changing their paths, metadata, member count, or
unpacked sizes. The resulting 122,956,868-byte outer Base CPIO still remained
`booting` through all 24 polls. No project PID 1 or SSH evidence appeared.
Rollback restored stock online, stock SSH, and the baseline configuration hash.

The direct full-RC path is now classified as a non-Python nested-root content
or handoff blocker. RC1 should use the proven small bootstrap plus a verified
post-boot full-root payload instead of a single large Base CPIO.

## Split-Root Bootstrap Test

The first split-root test booted the new small bootstrap to candidate `online`
and project SSH, then failed before payload staging because the bootstrap did
not contain the remote `scp` command expected by host OpenSSH SCP:

```text
sh: scp: not found
```

No root transition was attempted. Automatic rollback restored stock online,
stock SSH, and the exact baseline configuration hash. The transport fix is to
stream the payload through the already-proven SSH shell into BusyBox `cat`,
which requires no additional card-side binary.

## SSH-Stream Split-Root Validation

One bounded candidate boot validated the corrected SSH-stream transport. The
bootstrap Base CPIO was
`2ace3585f45a74c5d2acdc586f42dbfab04a8061f581ef5de733680412fbe45a`.
The full root payload was
`daee16a969824cf9a06568c9a9eca9fe7951c224b805bf1cce07c94dd3330d04`
(39,661,537 bytes compressed; 129,369,364 bytes unpacked; 3,107 members).
MPSS generated final ramfs
`253a5634d40aceaa8de623c065a0618616d60beef070b5819747345415b123ef`.

Candidate `mic0` reached `online`; bootstrap project SSH authenticated and
reported project PID 1, `k1om`, the hello/pthread markers, and MPSS readiness.
The binary-clean SSH transfer passed its exact byte-count and SHA-256 gate.
The staging command then decompressed and extracted the payload successfully
(`252675 blocks`). The subsequent bounded post-switch SSH polling produced no
output, so no project-root PID 1, RC SSH, or RC smoke result is claimed.

This isolates the current blocker to the transition after successful staging:
the existing evidence cannot distinguish a missing switch request, failed
`switch_root`, or failed/unreachable RC init. It is not a bootstrap boot,
networking, SSH transport, payload-integrity, or payload-extraction failure.
The next single change is durable handoff instrumentation in the bootstrap PID
1 path, emitting request-seen, pre-`switch_root`, exec-failure, and
project-root-init-entered markers to an early output path before another boot.

Automatic rollback completed: stock `mic0` returned `online`, stock SSH
reported `k1om` and PID 1 `init`, and the stock MPSS configuration hash matched
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.

## Instrumented Split-Root Handoff Result

The one instrumented boot used candidate Base CPIO
`d96d944381bfcc660ae7c9f3fb452f3cce6e2321032696dba342e28396fe67ec` and
generated MPSS ramfs
`f96bf5d782e799f195480d37cc59a478436e22d49d1a11149775b0fe561278f0`.
The unchanged payload SHA-256 was
`daee16a969824cf9a06568c9a9eca9fe7951c224b805bf1cce07c94dd3330d04`.

Candidate online and bootstrap SSH passed. The transfer integrity gate passed,
then the staging log recorded:

```text
XPR_PAYLOAD_HASH_OK
XPR_PAYLOAD_EXTRACT_OK
XPR_NEWROOT_INIT_NOT_EXECUTABLE
```

The last durable marker is `XPR_NEWROOT_INIT_NOT_EXECUTABLE`; the first missing
marker is `XPR_SWITCH_REQUEST_WRITTEN`. No request reached bootstrap PID 1, so
`switch_root`, RC init, RC networking, RC Dropbear, RC SSH, hello, and pthread
were not attempted in the staged root. The mounted-new-root and BusyBox move
instrumentation did not execute.

The exact blocker is payload CPIO metadata: its extracted `/sbin/init` lacks
the executable mode required by `xpr-stage-root`. The next change is to rebuild
only the payload archive with `/sbin/init` mode `0755`, add a build-time CPIO
mode assertion for that path, update its hash, and repeat one bounded test.
Automatic rollback passed: stock mic0 was online, stock SSH reported `k1om`
and PID 1 `systemd`, and the baseline configuration hash was restored.

## Corrected Payload-Mode Split-Root Result

The corrected payload was
`16132314df70f3fda5febca9dcfff8a5c61e044426d66998f7e55bdb2073a697`
(39,661,535 bytes). Archive assertions and a local extraction confirmed
`sbin/init` mode `0755`; BusyBox, Dropbear, hello, and pthread executable
modes also passed. The candidate used the unchanged instrumented bootstrap
`d96d944381bfcc660ae7c9f3fb452f3cce6e2321032696dba342e28396fe67ec` and
generated ramfs `eaee8bf7780fd885a024b602f8128e716fc21af1d845c9f43a457a1939e1be4b`.

Candidate online, bootstrap SSH, payload transfer, remote byte/SHA checks,
payload hash, extraction, and init executable validation passed. The last
durable marker was `XPR_PAYLOAD_EXTRACT_OK`; the first missing marker was
`XPR_SWITCH_REQUEST_WRITTEN`. The exact stage command failure was:

```text
/opt/xeon-phi-revival/bin/xpr-stage-root: line 38: chmod: not found
```

With `set -e`, that is exit status 127 before request creation. This is
`NEWROOT_VALIDATION_FAILED`, specifically a missing bootstrap BusyBox `chmod`
applet, not a payload-mode, switch-root, RC-init, network, SSH, hello, or
pthread failure. The next exact fix is to add the `chmod` BusyBox symlink to
the bootstrap rootfs builder, rebuild only the bootstrap Base CPIO, and repeat
one bounded test with the same corrected payload. Rollback again restored
stock online, stock SSH (`k1om`, PID 1 `systemd`), and the baseline MPSS
configuration hash.

## Chmod-Enabled Split-Root Result

The bootstrap Base CPIO with the requested applet was
`79b882aeab1ceff540d74d15f1b887339c7624a7d285d3c6336b6523acb49eba`.
Static inspection confirmed `bin/chmod -> busybox`; the corrected payload
remained unchanged at
`16132314df70f3fda5febca9dcfff8a5c61e044426d66998f7e55bdb2073a697`.

The bounded test reached candidate `online`, bootstrap SSH, payload transfer,
remote byte/SHA verification, extraction, and
`XPR_SWITCH_REQUEST_WRITTEN`. Bootstrap PID 1 then saw the request, but the
marker sequence ended with:

```text
XPR_SWITCH_REQUEST_SEEN
XPR_SWITCH_ROOT_REQUEST_REJECTED
```

The first missing marker is `XPR_NEWROOT_REVALIDATED`; `switch_root`, RC PID 1,
RC SSH, hello, and pthread were not reached. The exact remaining blocker is
bootstrap PID 1's mount validation: `xpr_clean_root_init.sh` invokes `grep`
against `/proc/mounts`, but the bootstrap BusyBox applet list still lacks the
`grep` symlink. Classification: `NEWROOT_VALIDATION_FAILED`.

Rollback restored stock `mic0` online, stock SSH with `k1om` and PID 1
`systemd`, and configuration hash
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.

## Grep-Enabled Split-Root Result

The bootstrap Base CPIO with both required applets was
`8d91da09faa76587637f60b24adbb84356c0fd85c1a76629cd9c092cdd95ea0a`.
Static inspection confirmed `bin/chmod -> busybox` and `bin/grep -> busybox`;
the corrected payload remained
`16132314df70f3fda5febca9dcfff8a5c61e044426d66998f7e55bdb2073a697`.

The bounded test reached candidate `online`, bootstrap SSH, payload transfer,
remote byte/SHA verification, extraction, and
`XPR_SWITCH_REQUEST_WRITTEN`. No later durable handoff marker was retrieved;
the marker poll observed no `XPR_SWITCH_REQUEST_SEEN`,
`XPR_NEWROOT_REVALIDATED`, or pre-switch marker. RC SSH and RC smoke tests
returned no evidence. The narrow classification is
`SWITCH_REQUEST_NOT_SEEN` from the available host evidence, with the important
limitation that an immediate post-request root transition could have hidden the
old `/run` marker before RC SSH became available. No claim of successful
`switch_root` or RC PID 1 is made.

Rollback passed: stock `mic0` returned online, stock SSH reported `k1om` and
PID 1 `systemd`, and the baseline configuration hash was restored.

## Durable-Handoff Split-Root Result

Date: 2026-08-08

This bounded alternate-configuration test used the current durable-handoff
instrumentation. The rebuilt bootstrap and payload were constructed from the
previously proven private inputs with the current project bootstrap init,
staging script, and RC init. Static preflight verified that the bootstrap and
staging scripts reference `/xpr-handoff.log`, the payload RC init emits
`XPR_RC_INIT_ENTERED`, and the stock configuration matched its baseline before
boot.

| Item | Result |
| --- | --- |
| Candidate kernel | `0450c4370fb9c023c5229274d9a7a5cc02b8a37838c3220a0c714fc602cb2505` |
| Candidate map | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` |
| Durable bootstrap Base CPIO | `9f38d90a27227657d61c8325416707696a7ee1a644a6d4f13d588e9eba9ae0f9` (29,316,692 bytes) |
| Durable final-root payload | `97734a5ec3135a2d7bcda038a0dba0904390ce927479186c9cedf2e718fe5e20` (39,661,571 bytes) |
| Generated MPSS ramfs | `ca41782948e9883f9266fd9f4ffc3d28b2df7f263858c6938fa8ac29be34c98a` |
| Candidate online | passed |
| Bootstrap SSH and payload SHA-256 gate | passed |
| Staging command | archive extraction printed `252675 blocks` |
| Last recovered durable marker | `XPR_PAYLOAD_HASH_OK` |
| `XPR_SWITCH_ROOT_EXEC` | not recovered |
| `XPR_RC_INIT_ENTERED` | not recovered |
| `XPR_RC_ROOT_SBIN_INIT_PID1` | not recovered |

After extraction completed, the card lost SSH and entered a reset transition
before the host recovered an extraction-complete, switch-request, or
post-switch marker. The evidence therefore does **not** prove that PID 1 saw
the request, that `switch_root` executed, or that the RC init started. The
first unrecovered stage is the pre-switch path after archive extraction.

The runner exited and stock recovery was then verified: `mic0` was `online`
with `/usr/share/mpss/boot/bzImage-knightscorner`, the configuration hash was
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`, and
SSH to the card address succeeded with stock PID 1 `systemd`. No firmware,
flash, persistent card storage, or active stock configuration was modified.

The minimal next experiment is not another functional handoff change. The
bounded runner now captures `/dev/ttyMIC0`, a MIC-focused host `dmesg` tail,
and available ramoops files before rollback. Repeat once with unchanged kernel,
modules, bootstrap, and payload; use those artifacts only to identify the
earliest reset-visible stage.
