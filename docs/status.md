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

The tested end-to-end path is:

```text
xpr-init --install
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
programs, and recovery have all passed on the 5110P baseline above.

A fresh-user-state validation on that existing known-good host also passed
archive auto-discovery, dedicated RSA-key generation, installation, handoff,
smokes, and recovery. It was not a fresh CentOS/MPSS installation; Git was
absent on the tested host, so the guide now lists Git as a host prerequisite for
cloning the current `xpr-init` helper.

The host-side installation files, saved stock configuration, state, and enabled
handoff service persisted through one normal reboot of the tested host. The
XPR-OS instance running on the card is RAM-resident and is lost when card/host
power is removed; XPR is not flashed to the card. After reboot, use the normal
`micctrl --reset`, `--wait`, and `--boot` lifecycle without rerunning
`xpr-init --install`; the persisted handoff service completes the final-root
transition.

## Current User Path

The recommended beginner flow is [Getting Started](getting-started/README.md)
and the [xpr-init guide](getting-started/xpr-init-preview.md). The original
manual RC6 procedure is retained for advanced troubleshooting and learning.

## Active Engineering Tracks

1. **XPR-OS maintenance and release engineering** — preserve the validated RC6 baseline while preparing future improvements cleanly.
2. **xpr-init usability** — dedicated RSA-key generation fallback and
   host-side diagnostics are validated; cold-host-reboot persistence and future
   release packaging remain to be validated.
3. **K1OM toolchain and SDK work** — make practical compilation less dependent on a historical host environment.
4. **Software ports and runtime expansion** — explore useful programs and libraries on the validated K1OM baseline.
5. **Source-package / xpr-build research** — investigate rebuilding normal source packages and dependencies for K1OM; this is future work, not a current package manager.
6. **Hardware preservation** — collect compatibility and recovery evidence on additional Knights Corner cards without generalizing from untested hardware.

## What Is Not Yet Claimed

The project does not currently claim:

- production readiness;
- support for every Knights Corner card;
- Knights Landing compatibility;
- a modern native package repository;
- a modern GCC/LLVM K1OM backend;

Historical blockers, old project plans, and superseded experiments are preserved
under [Research](research/README.md) rather than being mixed into current status.
