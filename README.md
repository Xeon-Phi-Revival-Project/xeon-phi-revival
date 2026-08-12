# XPR-OS

XPR-OS is an open-source Linux boot environment for reviving Intel Xeon Phi
Knights Corner (KNC/K1OM) coprocessors.

It gives a Knights Corner card a project-built kernel, bootstrap, userspace,
networking, and SSH environment while keeping Intel MPSS, firmware, and stock
card-side software outside the distribution. The current public release is
hardware-tested on an Intel Xeon Phi 5110P.

> [!IMPORTANT]
> **Latest release:** [XPR-OS 0.1.0-rc6](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6)
> is a prerelease, not a stable 1.0 release. It was tested on one 5110P using
> CentOS 7.4 and MPSS 3.4.10. Other Knights Corner models are untested.

## What Works In RC6

- A project-built K1OM-compatible kernel and five required MIC modules.
- Project bootstrap and final XPR `/sbin/init` running as PID 1.
- Source-built runtime, micveth networking, and Dropbear SSH.
- Deployment-specific RSA public-key provisioning; no universal login key is
  present in the generic release.
- Native dynamic hello, pthread, and `dlopen` tests.
- Three rollback-protected 5110P boots, each restoring stock MPSS afterward.
- Deterministic binary and corresponding-source archives with SPDX, license,
  and notice metadata.

## Quick Start

This is the shortest supported route for the tested configuration. Run these
commands on the **MPSS host**, as `root` or through `sudo`.

1. Confirm your card and MPSS baseline:

   ```bash
   micctrl --status
   ssh mic0 'uname -m; cat /proc/1/comm'
   ```

   The tested baseline reports `mic0: online`, `k1om`, and `init`.

2. Download both RC6 assets from the
   [release page](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6),
   then verify them:

   ```bash
   sha256sum xpr-os-0.1.0-rc6.tar.gz xpr-os-0.1.0-rc6-sources.tar.gz
   ```

   Compare against the hashes in the release notes or the
   [installation guide](docs/getting-started/installation.md).

3. Follow the single end-to-end guide:
   [Installing XPR-OS on a Xeon Phi 5110P](docs/getting-started/installation.md).
   It covers extraction, RSA key provisioning, the bounded boot runner, SSH,
   verification, and rollback.

## Documentation

| I want to... | Read |
| --- | --- |
| Install RC6 on the tested 5110P path | [Getting Started](docs/getting-started/README.md) |
| Check whether my hardware is supported | [Supported Hardware](docs/hardware/supported-hardware.md) |
| Connect through SSH | [SSH Access](docs/getting-started/ssh-access.md) |
| Verify a running XPR-OS system | [Verification](docs/getting-started/verifying-xpr-os.md) |
| Return to stock MPSS | [Rollback](docs/getting-started/rollback.md) |
| Diagnose a problem safely | [Troubleshooting](docs/troubleshooting/README.md) |
| Understand KNC, K1OM, MPSS, and the boot path | [Concepts](docs/concepts/README.md) |
| Build or study the project | [Development](docs/development/README.md) |
| Find terms quickly | [Glossary](docs/glossary.md) |
| Read release validation and audit evidence | [Release Documentation](docs/release/README.md) |

## Why This Exists

Knights Corner cards relied on the Intel Manycore Platform Software Stack
(MPSS), whose ecosystem is now historical. XPR-OS preserves a practical path
to boot and use a K1OM environment without redistributing Intel MPSS packages,
firmware, extracted sysroots, or stock card-side userspace.

XPR-OS does **not** flash firmware or alter persistent card storage. Its tested
workflow uses a reversible RAM-only boot path and verifies recovery to the
stock MPSS environment after each run.

## Support Status

| Category | Status |
| --- | --- |
| Intel Xeon Phi 5110P | Tested with RC6 evidence |
| Other Knights Corner cards | Possibly compatible, not tested by this project |
| Knights Landing / Knights Mill | Not a target; different architecture and software stack |
| Intel MPSS host software | Required separately; not included |
| Stable production support | Not claimed; RC6 is a release candidate |

## Contributing And Research

Contributions are welcome for documentation, hardware reports, K1OM tests,
toolchain work, and reproducible build improvements. Start with
[CONTRIBUTING.md](CONTRIBUTING.md). Historical investigation is preserved in
[Research](docs/research/README.md); it is valuable evidence, but it is not the
current installation path.

## License And Boundaries

Project-authored material is MIT-licensed. Third-party material retains its
own licenses. The release requires a separately obtained MPSS 3.4.10 host
installation; it does not include Intel firmware, MPSS packages, card-side
MPSS userspace, extracted Intel sysroots, credentials, or fixed SSH keys.

See [Release Documentation](docs/release/README.md) and
[Source Index](docs/source-index.md) for details.
