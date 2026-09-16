# XPR-OS 0.1.0-rc8 Candidate Validation Checkpoint

This record covers the unpublished candidate built from commit
`0d86b74f39e69088ad95cd87963237659ffee98e`.

## Exact Artifacts

| Artifact | SHA-256 |
| --- | --- |
| `xpr-os-0.1.0-rc8.tar.gz` | `a2ed3b8b8bab4892f5bcb2ed97f24f9b99bf561d85e9afb2d3826845250f0662` |
| `xpr-os-0.1.0-rc8-sources.tar.gz` | `f80f40761a69aa26b151f5c22413db43191faeaeeca3c5a0e95fa4614da4d964` |

The candidate passed archive integrity, SPDX 2.3, license-bundle,
source-policy, generic-payload, and no-fixed-authorized-keys checks before
deployment. Its final root contains CPython 3.12.13 at `/usr/bin/python3.12`
with `python3` and `python` symlinks.

## Targeted Deployment Result

The initial candidate exposed a strict SSH host-key mismatch. The cause was
the Dropbear RSA host-key option being used with the deployment-provisioned
ECDSA P-256 key. Commit `0d86b74` changes the bootstrap and final-root launch
commands to use Dropbear's ECDSA option, `-E`.

The corrected candidate was deployed on the established CentOS 7.4 / MPSS
3.4.10 host with the Intel Xeon Phi 5110P at `mic0`. The strict host-key
mismatch did not recur. The card then remained in MPSS `booting` state and
never exposed bootstrap SSH during the bounded readiness window.

Post-recovery comparison found the Base CPIO used the host's stock release
directory (`2.6.38.8+mpss3.4.10`) instead of the source-built module vermagic
and validated kernel-module directory (`2.6.38.8+mpss3.5.1`). The next
candidate must use the latter. The Base CPIO builder now rejects a requested
release that does not match every module's vermagic. Automatic handoff, final
PID 1, network, SSH, native smoke programs, and Python are not claimed as
passed for this candidate.

## Recovery

`xpr-init --recover` completed. The active stock configuration was restored
exactly:

```text
9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

`mic0` returned online with the stock MPSS image. The temporary handoff unit
was removed.

## Status

`XPR_OS_RC8_CANDIDATE=STATIC_PASS_HARDWARE_BOOT_PENDING`

The next action is a bounded investigation of the MPSS boot boundary using
this exact candidate or a new explicitly revisioned candidate if a concrete
container defect is found. Do not publish or tag RC8 from this checkpoint.
