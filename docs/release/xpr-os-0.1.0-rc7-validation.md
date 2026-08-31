# XPR-OS 0.1.0-rc7 Candidate Validation

This record covers the immutable 0.1.0-rc7 candidate assembled from commit
`1a2518afae704f9c352912cd99e8f4fca2b63ddb`. It records completed build and
static gates plus the exact reason live validation could not begin. It is not
a publication approval.

## Artifacts

| Artifact | Size | SHA-256 |
| --- | ---: | --- |
| `xpr-os-0.1.0-rc7.tar.gz` | 21,701,018 bytes | `930f55baa433aab9ad61a8326aca1a42323c819e3253e071ffc4736219723a0a` |
| `xpr-os-0.1.0-rc7-sources.tar.gz` | 383,310,989 bytes | `c06b569042f63305fc2988078961995d5d77a5af24c904857d6cafbfbcefd22d` |
| `SHA256SUMS` |  | `fdb39c5b585c1e5b19eb38985db6d999d468f0c30a9e7d7e4c74941dd7d88984` |

Two clean staging runs produced byte-identical binary archives, source
archives, and checksum files.

`RC7_REPRODUCIBILITY=PASS`

## Source-Built Root Inputs

| Input | SHA-256 |
| --- | --- |
| BusyBox | `f639cc8fa89b987e2392e484a4643fcabd80beefc76041b3fda55885831a277c` |
| Dropbear | `c941a97aed036ac6a00b6dd9cd18b092af27a06990372b3d5ca3c22245a3927a` |
| `ld-linux-k1om.so.2` | `da8d17f746dbd34934f94bfd4eb8e33702501d62b0959528c672a94aed7f56c6` |
| `libc.so.6` | `e1c5c22ee0a37a3ccdd5bc472ec3f3b5688a06943a79b7f9df154f454e349626` |
| `libpthread.so.0` | `4a7dbd34d9bac478f808c81491d8cb4f79449d7e50fc3dcb7e4f19bd50372424` |
| `libm.so.6` | `ad35aa054edc8978a8a62051b499236a4aa7c61df0dbf126e8eb763c9d79eb7d` |
| `libdl.so.2` | `2e6f7952b06417029cc9bb5ec11fc20a7b4e8c98e8bbf988c0271006ea1df98c` |
| `librt.so.1` | `bc05e371a69abcbf226a904cc83d08d4d5786d51d59370972576331399d49737` |
| `libutil.so.1` | `78a9e9e2aea84c3e768bb7eb6a2be6daaaa35ff3db0abbb5aa30608a6b81edb0` |
| `libgcc_s.so.1` | `727e0b9bc413ccfad67f98b36b4b0bb42c43ba39c5f8823c2540e27c9e733a58` |
| `xpr-hello` | `0f1f4841031350eae3bec6cf18517a2ba786d8a7897a62fbdf928670cd162582` |
| `xpr-pthread-smoke` | `3c66d2f0fa462fabfb4ec1f6bcaa3b0f67c3d967547b95bb7e87da3212c99df3` |
| `xpr-dlopen-smoke` | `9193fa26b75ad8de4bfacbf4ebedec64feaebd6982385c2cb78c64ad46a712cc` |
| `xpr-statusd` | `6b3c31584e3e61f81ca43c4d84eed150daadae8870ba74eb5bf17f8bcc06cd1c` |

All target ELF inputs report `Machine: Intel K1OM`. The generated container
hashes are:

- inner bootstrap: `211c7516cd2692fca522ded3371a3b79caaa8ec09b7eb03d9f4ab6a68242252d`
- outer bootstrap: `1803714acda300c68332fae6b988369092b2285c8ad79334a643f237761cddf2`
- final payload: `1da95173c23fd708afd65d521cbe61a05429f784ffda9172177b39f316524994`

`PUBLIC_ROOT_INPUTS=PASS`

`PUBLIC_ROOT_BUILD=PASS`

## Python Integration

The root contains `/usr/bin/python3.12`, `/usr/bin/python3`, `/usr/bin/python`,
and `/usr/lib/python3.12`. The Python executable hash is
`259b2a33523ab8581cb70648c88f3a0b1be8f285eb2b21c42a60addf27c2a211`.
The integrated runtime is the previously hardware-validated CPython 3.12.13
core package.

## Static Release Gates

- source release compliance: PASS
- public source policy: PASS
- private build path leaks: 0
- payload audit: PASS, 771 files
- fixed `authorized_keys`: 0
- private keys: 0
- universal administrator keys: 0
- Python 3.5 payload: 0
- MPSS SDK binary payload: 0
- standalone toolkit binary: 0
- SPDX 2.3 validation: PASS, 9 packages and 60 files
- license bundle validation: PASS
- release-version consistency: PASS
- archive checksum verification: PASS
- precompiled release verification: PASS

The archive includes source and license accounting for CPython 3.12.13. Its
active metadata accurately remains `hardware-validation-pending`.

`RC7_CONTAMINATION_AUDIT=PASS`

## Hardware Preflight

On the established CentOS 7.4 and MPSS 3.4.10 host:

- active `/etc/mpss/mic0.conf` SHA-256 matched the stock baseline:
  `9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`
- MPSS was active;
- the `mic` kernel module was loaded;
- no Xeon Phi function appeared in PCI enumeration;
- `/sys/class/mic` contained no device; and
- `micctrl --status` failed with `mic0: State failed - non existent MIC device`.

`xpr-init` reported stock mode with no active XPR installation. Because the
hardware prerequisite failed, the candidate was not installed and no reset,
boot, handoff, runtime smoke, or recovery cycle was attempted. The host
therefore remained at the exact stock configuration.

`RC7_5110P_BOOT=BLOCKED_HARDWARE_UNAVAILABLE`

`RC7_RECOVERY=NOT_REQUIRED_NO_INSTALL`

## Decision

`XPR_OS_RC7_CANDIDATE=BLOCKED_HARDWARE_UNAVAILABLE`

The candidate is source-accounted, reproducible, statically validated, and
ready for its final live cycle. Publication remains blocked until the 5110P is
visible on the established host and this exact binary archive passes install,
automatic handoff, PID 1, micveth, SSH, hello, pthread, `dlopen`, Python core,
and exact stock-recovery validation.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`
