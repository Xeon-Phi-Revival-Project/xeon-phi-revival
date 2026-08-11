# XPR-OS 0.1.0-rc5 Blocker Closure

RC5 is prepared for the next independent audit. RC4 artifacts and audit
history are unchanged.

| RC4 blocker | RC5 status | Evidence |
| --- | --- | --- |
| Stale release metadata | PASS | Generated metadata is versioned `0.1.0-rc5`; `validate-release-consistency.py` rejects stale release identities and wrong hardware-validation state. |
| Weak SSH public-key validation | PASS | The deployment provisioner accepts only a structurally valid single RSA key, verifies the SSH wire format, and the 14-case negative suite passes. Deployment applies the key to both the nested bootstrap root and final payload without modifying generic artifacts. |
| Private CPIO construction dependency | PASS | `build-rc5-containers.sh` builds the inner bootstrap root, outer Base CPIO, and final payload from explicit source-accounted build outputs. The host reconstruction recorded `private_cpio_inputs=0`; no historical CPIO is accepted by the constructor. |
| Incomplete release SPDX coverage | PASS | SPDX 2.3 now describes the top-level XPR release, contains the shipped Base CPIO and final payload, and models the nested bootstrap root container. The release coverage validator checks all three relationships and hashes. |

The generic artifacts are key-free, and deployment-only artifacts are generated
locally from one supplied public key. RC5 passed three rollback-protected boots;
see [RC5 Validation](xpr-os-0.1.0-rc5-validation.md). Publication remains
blocked until the requested independent RC5 audit and owner decision complete.

## Frozen Candidate

The frozen candidate was built twice from commit
`46cc833c9334dcfd4c11dee97c4447015f4f93f0`. Both binary archives and both
source archives were byte-identical.

| Artifact | SHA-256 | Bytes |
| --- | --- | ---: |
| `xpr-os-0.1.0-rc5.tar.gz` | `6f0c868afca16c5db68fb487af0b8dfddfc9d90c74ac521f1a069d5b466dcb0f` | 20,810,358 |
| `xpr-os-0.1.0-rc5-sources.tar.gz` | `cdef35366d3f11d83190bf1b4c7edcd03f42bb6cbb8ca19a0dc09f5dd3f4155e` | 362,611,469 |

The generic archive verifies as hardware-validation-passed and remains
`HUMAN_LEGAL_REVIEW_PENDING`. Its required external build prerequisite is the
separately obtained MPSS 3.4.10 K1OM host toolchain; no MPSS payload or sysroot
is included. Status: `RC5_FROZEN_FOR_MULTIAGENT_AUDIT`.
