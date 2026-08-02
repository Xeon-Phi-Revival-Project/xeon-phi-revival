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
