# RC7 Guide Validation: 2026-09-13

Starting repository revision: `c2e48bdfb1c9ff9fe13638de94220425204072a9`.
The documentation changes are external to the immutable G2 release archives.
No kernel, Python, installer or archive content changed.

## Test Scope

The new [RC7 guide](../getting-started/rc7.md) was tested from a newly created
Downloads directory and fresh archive extraction on the existing CentOS 7.4 /
MPSS 3.4.10 / Intel Xeon Phi 5110P host. Its existing root user, compatible RSA
pair, persistent XPR server identity and recovered installation history were
preserved. This was not a fresh OS installation, new-user identity generation,
or MPSS prerequisite installation test. G2 remains owner-provided, not public.

The literal guide command blocks supplied checksum verification, install,
reset/wait/boot, readiness polling and card-side commands. A surrounding harness
used fail-fast execution and an EXIT recovery trap; ordinary user installs do
not automatically recover. SSH received the card block on stdin without extra
SSH options; a terminal was not allocated. Interactive terminal ergonomics
were not tested. No manual handoff or trust bypass was used.

The [hardware transcript](xpr-os-0.1.0-rc7-guide-hardware.txt) has SHA-256
`091bbae4d3ecab60d1d61f1084b0b8fe459acc080a8061172a77265e079a488a`.
The private Downloads prefix is normalized to `CANDIDATE_DIRECTORY` where
present; command results and artifact hashes are retained.

## Exact Artifacts

- Binary SHA-256: `6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c`
- Source SHA-256: `9d1261fd42f87697ee84b3cff749487c92bf11eb9eba952fcf6ead3be6df4c4a`
- All four assets passed the existing external `SHA256SUMS` on the host.
- Python card SHA-256 matched the validated package:
  `259b2a33523ab8581cb70648c88f3a0b1be8f285eb2b21c42a60addf27c2a211`.

## Results

| Step | Result |
| --- | --- |
| Stock preflight: online, SSH, K1OM, exact config | PASS |
| Packaged installer, sudo path, explicit archive selection | PASS |
| Reset/wait/boot and automatic final-root handoff | PASS |
| Documented bounded readiness loop | PASS, 104 seconds after boot returned |
| Plain `ssh xpr-mic0`, no password or host-key warning | PASS |
| Final PID1 marker, networking and mounts markers | PASS |
| hello, pthread, dlopen | PASS |
| `command -v python3` | PASS, `/usr/bin/python3` |
| Python 3.12.13, K1OM, threading, JSON/file operations | PASS |
| xpr-init status and recovery availability | PASS |
| Recovery, stock online and normal `ssh mic0` | PASS |
| Stock known-hosts preserved byte-for-byte | PASS |

Final stock configuration SHA-256:
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.
Stock PID 1 was `/sbin/init.sysvinit`; architecture was `k1om`.
The host/card were left in stock mode.

## Documentation Corrections

- Separate unpublished RC7 packaged installation from the pinned RC6 helper.
- Explain automatic RSA selection/generation and isolated `ssh xpr-mic0`.
- Verify artifacts, use an explicit archive path, and wait for final-root markers.
- Mark host versus card commands, user-controlled recovery and RAM persistence.
- Use `command -v`, not absent `which`, and state actual dlopen output.
- Explain the unchanged Python `<exec_prefix>` warning and core-only scope.
- Keep card-only reset rearming and toolkit publication hold explicit.

The local active-doc validator and whitespace checks pass. This checks links
and required text, not a fresh CentOS/MPSS deployment.

## Independent Release-Readiness Review

A directly routed GPT-5.6 Luna Medium reviewer (Turing,
`01a09bbc-30b3-7de0-8740-9df238b67396`) completed a read-only engineering
compliance review after the live test. Verdict: `PASS_ENGINEERING_REVIEW`.
No concrete release-compliance blocker was identified for the RC7 OS set.

The reviewer checked the four exact assets, sizes and external/internal
checksums; source mappings for the kernel, five modules, BusyBox, Dropbear,
eglibc, libgcc, CPython and XPR tooling; SPDX 2.3 relationships and custom license
references; and the 11 license/notice files against the sidecar. It confirmed
embedded/external SPDX identity, the historical source-snapshot boundary,
candidate/hardware binding, guide test results and publication restrictions.
Held toolkit binaries, SDK/firmware payload, credentials and Python 3.5 remain
excluded from the binary release. Legitimate accounted OS binaries are shipped.

This was not qualified legal advice, an independent source rebuild, or an
additional hardware test by the reviewer. The lead ran the hardware commands;
Luna reviewed the resulting evidence. Existing failed-install partial-state
and failure-injection coverage limitations remain nonblocking and disclosed.

The toolkit's separate KNC binutils source-distribution interpretation was
neither cleared nor automatically applied to the OS. Owner authorization,
final tag selection and public release approval are still outstanding.

```text
RC7_GUIDE_WORKFLOW=PASS
RC7_GUIDE_RECOVERY=PASS
LUNA_RELEASE_REVIEW=PASS_ENGINEERING_REVIEW
RC7_PUBLICATION_PREP=PASS
TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW
RC7_PUBLICATION=AWAITING_OWNER_AUTHORIZATION
```

No release artifact was rebuilt, no tag was created and no public asset was
uploaded. These documentation/evidence updates do not replace G2's archives.
