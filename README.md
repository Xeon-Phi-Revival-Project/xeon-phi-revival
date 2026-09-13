# Xeon Phi Revival Project

[![XPR-OS prerelease](https://img.shields.io/badge/XPR--OS-0.1.0--rc7-blue)](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc7)
[![License](https://img.shields.io/github/license/Xeon-Phi-Revival-Project/xeon-phi-revival)](LICENSE)
[![Tested hardware](https://img.shields.io/badge/tested-Xeon%20Phi%205110P-2ea44f)](docs/hardware/supported-hardware.md)

**A preservation and software-revival project for Intel Xeon Phi Knights Corner
(KNC/K1OM) coprocessors.** We are rebuilding practical ways to boot, program,
study and use this historical Intel MIC platform through source-accounted
software, reproducible work and real-hardware evidence.

## Current Prerelease: XPR-OS 0.1.0-rc7

[XPR-OS RC7](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc7)
is a revived Linux operating environment for Knights Corner. It includes:

- A project-built K1OM kernel, five MIC modules, bootstrap and final XPR uOS.
- Packaged `xpr-init` for deployment, automatic handoff, status and stock recovery.
- Plain `ssh xpr-mic0` with deployment-specific authentication and isolated trust.
- Source-accounted **CPython 3.12.13 core**.
- Corresponding source, SPDX, notices and checksums. Independent G2 staging
  produced byte-identical binary and source archives.

The validated target is **Intel Xeon Phi 5110P**, using an existing working
**CentOS 7.4 + Intel MPSS 3.4.10** host. Fresh host-OS/MPSS installation from
scratch was not validated. Other KNC models are not yet project-tested.
This is an experimental prerelease, not a modern production Linux distribution.

## Quick Start: Try XPR-OS

1. Check [hardware requirements](docs/hardware/supported-hardware.md) and establish
   working [stock MPSS boot and SSH](docs/getting-started/mpss-setup.md).
2. Download the five named [RC7 release assets](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc7).
   Install from `xpr-os-0.1.0-rc7.tar.gz`, not the source archive.
3. Follow the [RC7 installation and use guide](docs/getting-started/rc7.md):
   verify checksums, extract the archive, install its `xpr-init`, and select
   that archive explicitly.

After installing the packaged command, the host workflow is:

```bash
sudo xpr-init --install --release /absolute/path/to/xpr-os-0.1.0-rc7.tar.gz
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
# Complete the guide's final-root readiness check before connecting.
ssh xpr-mic0
# Now on the card:
python3 --version
```

Bare `sudo xpr-init --install` can search automatically when exactly one release
is found. The guide explains search locations, explicit paths and RSA key
selection/generation. No shared root password or universal key is supplied.

When finished, **exit the card shell**, then on the host:

```bash
sudo xpr-init --recover
ssh mic0
```

XPR and stock SSH identities remain separate. Normal installations do not
automatically roll back after a test timer: use XPR until you choose recovery.
Card-side files are RAM-resident and lost on reset. No firmware flashing occurs.
See the guide for card-only reboot rearming and [recovery details](docs/getting-started/rollback.md).

Published **XPR-OS 0.1.0-rc6** remains unchanged. Its
[older pinned-installer workflow](docs/getting-started/xpr-init-preview.md#frozen-rc6-workflow)
is separate; do not combine RC6 with the current RC7 installer.

## Beyond The OS

| Track | Purpose | Current boundary |
| --- | --- | --- |
| XPR-OS | Revived K1OM boot and Linux userspace | RC7 validated on 5110P |
| K1OM toolchain | Source-built compiler, binutils, ABI and sysroot work | Technically validated; separate publication hold, not bundled in RC7 |
| Software ports | Practical applications on the revived runtime | Python 3.12.13 core included; broader ports remain experimental |
| Hardware preservation | Bring-up, cooling, MPSS behavior and recovery | Evidence-led, model-specific testing |
| Historical research | Intel MIC, KNC, uOS and toolchain knowledge | Preserved separately from current instructions |

- [Documentation](docs/README.md)
- [Concepts](docs/concepts/README.md)
- [Development](docs/development/README.md)
- [Historical research](docs/research/README.md)
- [Release evidence and inventory](docs/release/xpr-os-0.1.0-rc7-candidate-g-validation.md)
- [Contributing](CONTRIBUTING.md)

## Important Boundaries

MPSS is obtained separately and remains the validated physical-card host-control
stack. XPR does not replace its host driver or `micctrl`.

Python's documented core operations pass, but optional-extension coverage is
not complete. The known `<exec_prefix>` warning may appear; see the guide.
The standalone toolkit binary is excluded from RC7 pending qualified review
of its separate KNC-binutils source-distribution terms.

Project-authored material is MIT-licensed; third-party components retain their
licenses and notices. See [Source Index](docs/source-index.md).
No private credentials, Intel firmware or MPSS SDK binaries ship in RC7.

The project is AI-assisted, but claims require source/build evidence and actual
hardware tests. XPR is independent of, and not endorsed by, Intel.
