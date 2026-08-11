# XPR-OS 0.1.0-rc6 Review Report

## Scope

RC6 closes the two concrete RC5 audit findings without changing runtime
artifacts. It is frozen for a targeted independent audit and is not a GitHub
release, tag, or owner publication decision.

- Starting repository commit: `452ee12940b90ffd3410d319f825e46556949f16`
- RC6 packaging commit: `e6071c51bb640ab639aedf5faf7af30ae79bad26`
- Hardware retest required: `NO`

## Frozen Archives

| Artifact | SHA-256 | Bytes | Build A/B |
| --- | --- | ---: | --- |
| `xpr-os-0.1.0-rc6.tar.gz` | `94867d9f58c12e7b04dcd0f2a8bfb176054d41b3c8e02f6c584c6efef4124d6c` | 20,807,128 | identical |
| `xpr-os-0.1.0-rc6-sources.tar.gz` | `bb530e170e9871627903644f52d8271c1f9c3375d4d3bc1d62c0c4eaa60a6558` | 362,447,951 | identical |

## RC5 Blocker Closure

| RC5 blocker | Status | Evidence |
| --- | --- | --- |
| Stale active release material | PASS | RC6 release notes, distribution review, manifest, and generated archive metadata identify `0.1.0-rc6`. `validate-release-consistency.py` now checks the shipped distribution review and reports `ACTIVE_RELEASE_METADATA=PASS` and `RELEASE_VERSION_CONSISTENCY=PASS`. Both package entry points require an explicit `--version`. |
| Private absolute build-path leakage | PASS | The public-source policy excludes machine-specific historical reports and experiment material without deleting it from Git. The extracted RC6 source archive reports `PRIVATE_BUILD_PATH_LEAKS=0`. Required configs, kernel/module recipes, container constructors, source archives, and license material remain present. |

## Runtime Identity With RC5

| Component | RC5 SHA-256 | RC6 SHA-256 | Identical |
| --- | --- | --- | --- |
| Compatibility kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` | yes |
| System.map | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` | yes |
| `dma_module.ko` | `af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a` | `af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a` | yes |
| `ringbuffer.ko` | `e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068` | `e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068` | yes |
| `micscif.ko` | `0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2` | `0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2` | yes |
| `mpssboot.ko` | `a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894` | `a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894` | yes |
| `intel_micveth.ko` | `0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60` | `0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60` | yes |
| Outer Base CPIO | `f2ab2ead93fa9a62605ef24984583fb808550cac730d5ac874342ec876283135` | `f2ab2ead93fa9a62605ef24984583fb808550cac730d5ac874342ec876283135` | yes |
| Nested bootstrap root | `52be12ffa566909704b96d82bfc84997c1d0b86a7be470efca054f89e7d72e9a` | `52be12ffa566909704b96d82bfc84997c1d0b86a7be470efca054f89e7d72e9a` | yes |
| Final root payload | `27df3a3886429a00680869fb4a26a72826b93ab3f0032af62d7ed5d389c1a99d` | `27df3a3886429a00680869fb4a26a72826b93ab3f0032af62d7ed5d389c1a99d` | yes |

The identical final payload preserves the RC5 BusyBox, Dropbear, source-built
runtime libraries, and helper programs. The identical payload and outer Base
CPIO preserve their complete runtime content without a new hardware run.

## Archive and Source Gates

- `ACTIVE_RELEASE_METADATA=PASS`
- `PRIVATE_BUILD_PATH_LEAKS=0`
- `SPDX_2_3_VALIDATION=PASS`
- `LICENSE_BUNDLE_VALIDATION=PASS`
- `NO_FIXED_AUTHORIZED_KEYS=PASS`
- `RELEASE_ARTIFACT_VALIDATION=PASS`
- `SOURCE_CONFIG_INTEGRITY=PASS` for kernel and BusyBox configs
- `PRECOMPILED_RC_VERIFY=PASS`

The source archive retains the pinned kernel, module, BusyBox, Dropbear,
eglibc, GCC, GMP, MPFR, and MPC inputs, plus the required project build and
container-construction files. No historical/private CPIO input is required.

## Freeze State

`RC6_FROZEN_FOR_TARGETED_AUDIT`

The candidate has not been tagged, published, or uploaded. The next action is
a short independent audit of these exact hashes.
