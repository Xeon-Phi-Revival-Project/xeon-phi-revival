# Project Status

The Xeon Phi Revival Project is **active**.

The current public XPR-OS milestone is **XPR-OS 0.1.0-rc6**. RC6 is a frozen
prerelease. The host-side `xpr-init` workflow was developed and hardware-
validated after the RC6 archives were published, so the current helper comes
from the repository rather than from the frozen RC6 release archive.

## Hardware-Validated Baseline

The project's strongest current evidence is for:

- Intel Xeon Phi **5110P** (Knights Corner / K1OM)
- CentOS 7.4 host
- Intel MPSS 3.4.10
- device `mic0`

Other Knights Corner models and other host configurations may work, but they are
not yet project-validated. Knights Landing is a different platform and is not an
XPR-OS target.

## XPR-OS RC6: Validated

The released runtime has demonstrated on real 5110P hardware:

- a project-built K1OM-compatible Linux kernel;
- five rebuilt MIC modules;
- project-controlled bootstrap and split-root handoff;
- final XPR `/sbin/init` as PID 1;
- micveth networking;
- Dropbear SSH with deployment-specific RSA public-key authentication;
- native dynamic hello, pthread, and `dlopen` smoke programs;
- deterministic release construction and corresponding-source records; and
- rollback-protected validation that restored the known stock MPSS baseline.

RC6 remains a prerelease, not a modern general-purpose distribution and not a
claim of support for every Xeon Phi.

## xpr-init: Validated On The Tested Baseline

`xpr-init` is the host-side installation, integration, automatic handoff, and
recovery helper. It does not replace MPSS or `micctrl`.

The tested first-install path is:

```text
xpr-init --install
  -> archive auto-discovery
  -> existing RSA key selection or dedicated RSA-key generation
  -> micctrl reset / wait / boot
  -> bootstrap SSH
  -> verified payload transfer
  -> switch_root
  -> final XPR PID 1
  -> micveth + authenticated final SSH
  -> xpr-init --recover
  -> exact stock MPSS configuration restored
```

Automatic bootstrap-to-final-root handoff, final SSH, the three runtime smoke
programs, and recovery have all passed on the 5110P baseline above. Dedicated
RSA-key generation was also live-tested with an isolated invoking user; the
private key remained host-only.

A fresh-user-state validation on that existing known-good host passed archive
auto-discovery, dedicated RSA-key generation, installation, handoff, smokes,
and recovery. It was not a fresh CentOS/MPSS installation. The literal beginner
flow exposed one host prerequisite gap: Git was absent, so the guide now lists
`sudo yum install -y git` for the tested CentOS host when needed.

## Reboot Persistence: Validated

The host-side installation files, saved stock configuration, state, active XPR
MPSS configuration, and enabled handoff service persisted through a normal
reboot of the tested host. Reinstalling XPR with `xpr-init --install` was **not**
required.

After that reboot, `mic0` was observed already online with the installed XPR
kernel, and the persisted handoff path successfully reached final XPR PID 1,
micveth, generated-key SSH, and all three runtime smoke programs. No XPR-owned
automatic card-boot service and no `xpr-init --boot` command were added.

The project has not yet isolated the exact MPSS startup path responsible for the
observed post-reboot card boot, so that behavior is recorded as evidence for the
tested CentOS 7.4 + MPSS 3.4.10 system rather than generalized to every MPSS
host. The normal `micctrl --reset`, `--wait`, and `--boot` lifecycle remains the
explicit fallback when `mic0` is not already online with XPR.

The card-side XPR instance remains RAM-resident and is not flashed permanently
to the Xeon Phi. Host-side configuration persistence and card-side runtime
persistence are separate properties.

## Current User Path

The recommended beginner flow is [Getting Started](getting-started/README.md)
and the [xpr-init guide](getting-started/xpr-init-preview.md). The original
manual RC6 procedure is retained for advanced troubleshooting and learning.

## Active Engineering Tracks

1. **XPR-OS maintenance and release engineering** — RC7 Candidate E is technically validated on the 5110P with source-built runtime inputs and CPython 3.12.13; preserve its exact hash while the owner handles final publication metadata and release decision.
2. **xpr-init packaging and polish** — key generation, status/diagnostics, fresh-user flow, and reboot persistence are validated on the tested baseline; the current helper is included in the staged RC7 candidate.
3. **K1OM toolchain and SDK work**: the standalone XPR K1OM Toolkit is technically validated for MPSS-free compilation and real 5110P execution. Public binary distribution remains held for qualified review of the recovered KNC binutils source-distribution terms.
4. **Software ports and runtime expansion** — explore useful programs and libraries on the validated K1OM baseline.
5. **Source-package / xpr-build research** — investigate rebuilding normal source packages and dependencies for K1OM; this is future work, not a current package manager.
6. **Hardware preservation** — collect compatibility and recovery evidence on additional Knights Corner cards without generalizing from untested hardware.

## What Is Not Yet Claimed

The project does not currently claim:

- production readiness;
- support for every Knights Corner card;
- Knights Landing compatibility;
- a literal fresh CentOS 7.4 + MPSS 3.4.10 installation validation;
- identical automatic card-start behavior on every MPSS host;
- a modern native package repository; or
- a modern GCC/LLVM K1OM backend.

Historical blockers, old project plans, and superseded experiments are preserved
under [Research](research/README.md) rather than being mixed into current status.
