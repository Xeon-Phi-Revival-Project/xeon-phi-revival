# Xeon Phi Revival Project

[![Latest release](https://img.shields.io/github/v/release/Xeon-Phi-Revival-Project/xeon-phi-revival?include_prereleases&label=XPR-OS)](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6)
[![License](https://img.shields.io/github/license/Xeon-Phi-Revival-Project/xeon-phi-revival)](LICENSE)
[![Tested hardware](https://img.shields.io/badge/tested-Xeon%20Phi%205110P-2ea44f)](docs/hardware/supported-hardware.md)

**A preservation and software-revival project for Intel Xeon Phi Knights Corner
(KNC/K1OM) coprocessors.** We are rebuilding practical paths to boot, program,
study, and use this historical manycore platform with public, reproducible,
and evidence-led tooling.

> **Current milestone:** [XPR-OS 0.1.0-rc6](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6)
> is the first public release candidate. Its project-built K1OM runtime was
> tested on an Intel Xeon Phi 5110P. It remains a prerelease, and other KNC
> models are not yet project-tested.

## What This Project Covers

| Track | Purpose | Current state |
| --- | --- | --- |
| **XPR-OS** | A project-built K1OM boot and Linux userspace environment | RC6 published and hardware-tested on 5110P |
| **K1OM tools** | Native compilers, binutils, ABI, sysroot, and runtime research | Active research and reproducibility work |
| **Software ports** | Practical K1OM applications such as Python and Doom | Experimental, built on the runtime baseline |
| **Hardware preservation** | Bring-up, cooling, MPSS behavior, and recovery evidence | 5110P baseline documented |
| **Historical research** | KNC, uOS, kernel, module, and release-engineering records | Preserved and clearly indexed |

## Start Here

### Quick Start: Try XPR-OS

1. Check the [tested hardware and host requirements](docs/hardware/supported-hardware.md).
2. Install or verify [MPSS 3.4.10 on the host](docs/getting-started/mpss-setup.md).
3. Download [XPR-OS 0.1.0-rc6](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6). Put the binary archive (`xpr-os-0.1.0-rc6.tar.gz`) in your normal Downloads folder or note its path.
4. Get the current repository and install the validated `xpr-init` host helper. `xpr-init` was validated after RC6 was frozen, so it is **not** contained in the RC6 release archives:

   ```bash
   git clone https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival.git
   cd xeon-phi-revival
   sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
   sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init
   sudo xpr-init --install
   sudo micctrl --reset mic0
   sudo micctrl --wait mic0
   sudo micctrl --boot mic0
   ssh mic0
   ```

   When finished, restore stock MPSS with `sudo xpr-init --recover`.
   See the [xpr-init guide](docs/getting-started/xpr-init-preview.md) for
   prerequisites, auto-discovery, and explicit release/key options.

The tested path uses a separately obtained MPSS 3.4.10 host installation. It
does not flash firmware or modify persistent card storage, and it has a
[documented rollback path](docs/getting-started/rollback.md).

### I want to learn or contribute

| Goal | Read |
| --- | --- |
| Understand Knights Corner, K1OM, and MPSS | [Concepts](docs/concepts/README.md) |
| Compile and run native K1OM code | [From Card To Code](docs/getting-started-card-to-code.md) |
| Build or study XPR-OS | [Development](docs/development/README.md) |
| Browse preserved technical evidence | [Research](docs/research/README.md) |
| Report hardware results or contribute docs/code | [Contributing](CONTRIBUTING.md) |

## XPR-OS RC6 At A Glance

- Project K1OM-compatible kernel and five required MIC modules.
- Project bootstrap and final XPR `/sbin/init` as PID 1.
- micveth networking, Dropbear SSH, and deployment-specific RSA key handling.
- Native dynamic hello, pthread, and `dlopen` validation.
- Three rollback-protected 5110P boots, restoring stock MPSS each time.
- Deterministic binary and corresponding-source archives with SPDX, notices,
  and release metadata.

Read [Getting Started](docs/getting-started/README.md) for the user path and
[Release Documentation](docs/release/README.md) for validation evidence.

## Project Principles

```text
Evidence before assumptions.
Rollback before risky hardware changes.
Open project work separated from proprietary Intel components.
Historical research preserved, but never confused with current instructions.
```

The project is AI-assisted and Codex-driven, but hardware claims are accepted
only when real-card evidence and repeatable validation support them.

## Important Boundaries

Intel MPSS host software, firmware, stock card-side userspace, compiler
installers, and extracted sysroots are **not** redistributed here. Users obtain
required Intel material separately under its applicable terms. XPR-OS is not
affiliated with, endorsed by, or supported by Intel.

Project-authored material is MIT-licensed; third-party material retains its own
licenses. See [Source Index](docs/source-index.md) and
[Release Documentation](docs/release/README.md).
