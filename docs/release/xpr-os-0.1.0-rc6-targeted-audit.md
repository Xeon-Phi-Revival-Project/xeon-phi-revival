# XPR-OS 0.1.0-rc6 Targeted Independent Audit

## Scope

This is a read-only audit of frozen RC6. It did not rebuild artifacts, alter
MPSS or hardware state, create a tag, or publish a release.

- Freeze commit: `2180d69b910008432f661ddd83f1efb7242486f2`
- RC6 packaging commit: `e6071c51bb640ab639aedf5faf7af30ae79bad26`
- Audit execution: `PARALLEL_LUNA_SUBAGENTS`
- Parent: Terra High
- Luna routing: direct
- Independent passes: `3/3`

## Frozen Artifact Verification

The host-side frozen Build A archives were checked directly. Build A and Build
B compare byte-for-byte equal for both archives.

| Artifact | SHA-256 | Bytes | A/B identity |
| --- | --- | ---: | --- |
| `xpr-os-0.1.0-rc6.tar.gz` | `94867d9f58c12e7b04dcd0f2a8bfb176054d41b3c8e02f6c584c6efef4124d6c` | 20,807,128 | PASS |
| `xpr-os-0.1.0-rc6-sources.tar.gz` | `bb530e170e9871627903644f52d8271c1f9c3375d4d3bc1d62c0c4eaa60a6558` | 362,447,951 | PASS |

## Targeted Results

| Area | Result | Evidence |
| --- | --- | --- |
| Active RC6 metadata | PASS | The shipped release metadata identifies `0.1.0-rc6`; the staging gate requires an explicit version and validates active release state. Historical RC1-RC5 references remain historical records. |
| Private paths and secrets | PASS | Recorded source-package hygiene result is `PRIVATE_BUILD_PATH_LEAKS=0`; direct member-name inspection found no credentials, fixed `authorized_keys`, private-key filenames, OneDrive paths, or release staging paths. |
| Generic SSH authorization | PASS | The generic artifact is key-free; release evidence records `NO_FIXED_AUTHORIZED_KEYS=PASS`. Deployment key provisioning is external to the frozen generic payload. |
| Corresponding source | PASS | The public-source policy retains pinned kernel, module, BusyBox, Dropbear, eglibc, GCC, GMP, MPFR, MPC, and project construction inputs while excluding machine-specific historical evidence. No historical/private CPIO is accepted by the container builder. |
| SPDX 2.3 and release coverage | PASS | Recorded validation is `SPDX_2_3_VALIDATION=PASS`; the generator and validator cover the release, outer Base CPIO, nested bootstrap root, and final payload. |
| Runtime identity | PASS | Kernel, System.map, five modules, outer Base CPIO, nested bootstrap root, and final payload are byte-identical to the RC5 artifact set validated on three rollback-protected boots. |
| Hardware retest | NOT REQUIRED | RC6 does not change runtime artifacts. The validated RC5 identities are preserved exactly. |

## Runtime Identity Cross-Check

| Component | SHA-256 |
| --- | --- |
| Kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| System.map | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` |
| `dma_module.ko` | `af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a` |
| `ringbuffer.ko` | `e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068` |
| `micscif.ko` | `0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2` |
| `mpssboot.ko` | `a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894` |
| `intel_micveth.ko` | `0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60` |
| Outer Base CPIO | `f2ab2ead93fa9a62605ef24984583fb808550cac730d5ac874342ec876283135` |
| Nested bootstrap root | `52be12ffa566909704b96d82bfc84997c1d0b86a7be470efca054f89e7d72e9a` |
| Final root payload | `27df3a3886429a00680869fb4a26a72826b93ab3f0032af62d7ed5d389c1a99d` |

The RC5 validation records three passing boots with final XPR `/sbin/init` as
PID 1, micveth networking, authenticated Dropbear SSH, dynamic hello,
pthread, dlopen, and verified stock rollback after each run.

## Findings

- BLOCKERS: `0`
- NON-BLOCKING: `2`
- RESOLVED: `3`

The non-blocking items are auditability improvements, not false claims in the
frozen artifacts:

1. SPDX records corresponding-source details in `sourceInfo` instead of using
   machine-traversable generated-from relationships for each source component.
2. Component recipes permit reconstruction, but do not mechanically assert
   byte-identical rebuilt output hashes for every runtime component.

## Classification

`READY_FOR_OWNER_RELEASE_DECISION`

No concrete factual RC6 release blocker was identified in the requested scope.
This classification is not a tag, publication, or legal approval.
