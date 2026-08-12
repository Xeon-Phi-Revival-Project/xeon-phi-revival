# XPR-OS 0.1.0-rc6

XPR-OS 0.1.0-rc6 is the first public precompiled release candidate for Intel
Xeon Phi Knights Corner. It was tested on an Intel Xeon Phi 5110P using CentOS
7.4 and MPSS 3.4.10.

## Start Here

- [Install RC6](../getting-started/installation.md)
- [Supported hardware](../hardware/supported-hardware.md)
- [SSH access](../getting-started/ssh-access.md)
- [Verification and rollback](../getting-started/verifying-xpr-os.md)

## Validated Capabilities

- Project K1OM-compatible kernel and five required MIC modules.
- Project bootstrap and final XPR `/sbin/init` as PID 1.
- micveth networking and Dropbear SSH with deployment-only RSA public-key
  provisioning.
- Native dynamic hello, pthread, and `dlopen` smoke tests.
- Three rollback-protected boots; each returned `mic0` to stock MPSS, SSH, and
  init.

## Downloads

| Asset | SHA-256 |
| --- | --- |
| `xpr-os-0.1.0-rc6.tar.gz` | `94867d9f58c12e7b04dcd0f2a8bfb176054d41b3c8e02f6c584c6efef4124d6c` |
| `xpr-os-0.1.0-rc6-sources.tar.gz` | `bb530e170e9871627903644f52d8271c1f9c3375d4d3bc1d62c0c4eaa60a6558` |

The binary archive contains the source-accounted K1OM artifacts. The paired
source archive provides corresponding source, pinned inputs, build scripts,
and the bounded boot/rollback runner. Neither archive contains Intel MPSS
packages, firmware, stock card-side userspace, extracted sysroots, passwords,
or fixed SSH keys.

## Release Candidate Boundaries

RC6 is genuinely hardware-tested but remains a release candidate. It is tested
on the 5110P path only; other Knights Corner models are untested. Use the
documented verification and rollback flow before relying on it for valuable
hardware or workloads.

For validation and release evidence, see the
[RC6 targeted audit](xpr-os-0.1.0-rc6-targeted-audit.md) and
[RC5 three-boot validation](xpr-os-0.1.0-rc5-validation.md).
