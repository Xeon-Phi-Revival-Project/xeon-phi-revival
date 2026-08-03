# Xeon Phi Revival Project

The Xeon Phi Revival Project is an AI-assisted, Codex-driven preservation and engineering effort focused on restoring useful software-development paths for Intel Xeon Phi Knights Corner coprocessors and the K1OM architecture.

The current baseline is a working Intel Xeon Phi 5110P running MPSS 3.4.10, with native K1OM assembly, C, pthread, math, file-I/O, and 512-bit vector smoke tests validated on real hardware.

> [!IMPORTANT]
> **Project temporarily paused - August 2, 2026**
>
> Active development is temporarily paused to preserve the current work and
> conserve development resources. The project is not abandoned. The repository
> remains available for research, review, and future continuation. No active
> XPR-OS release should be assumed; work resumes with durable split-root PID 1
> handoff instrumentation.

## Human Section
Hello, I am @CarlsonDataCenter, and I am the maintainer and overarching manager of this project. I am a high schooler who thought that this would be a fun learning project to try and build back up an old, obscure piece of technology, the Intel Xeon Phi Coprocessor. With the mainstream of AI, I'm able to use Codex to make this project possible, as I know 0 zero code but have a background in hardware, servers, basic shell, etc. This project goes to show how helpful AI can be used, when used rightly. The majority of the code and descriptions are AI-generated, but they are audited by me, and changes I direct are implemented. So, I continue with the project.

## Current Progress

- Intel Xeon Phi 5110P is working under MPSS 3.4.10 with SSH access to `mic0`.
- Native K1OM assembly, C, pthread, math, file-I/O, and vector smoke tests have passed on real hardware.
- Project PID 1 handoff and second-stage uOS profile experiments have passed with verified rollback to the stock uOS.
- The Ubuntu architecture-port lane now has a deterministic `Architecture: k1om` package/archive bootstrap with host-side APT parsing, package audits, simulated installs, live `mic0` smoke tests, and rollback.
- The project has a proven minimal XPR-OS bootstrap, a project-owned PID 1 path, a checksummed full-root payload transfer, and verified rollback to stock MPSS.
- The current release-candidate boundary is the handoff after `XPR_SWITCH_REQUEST_WRITTEN`; full RC PID 1, RC SSH, and RC smoke completion remain unproven.

## Current XPR-OS Status

The project is building an experimental, Ubuntu-derived K1OM uOS for Intel
Xeon Phi Knights Corner coprocessors. The current architecture is:

```text
MPSS host stack and compatible KNC kernel
  -> small project bootstrap and early init
  -> project networking and SSH
  -> checksummed full-root payload
  -> project PID 1 switch_root handoff
```

The bootstrap reaches `mic0` online, accepts SSH, transfers the unchanged
payload with remote byte-count and SHA-256 verification, and extracts it. The
remaining handoff result is not yet conclusive because markers from the old
`/run` may disappear during an immediate root transition before RC SSH becomes
available. This is a research milestone, not a release announcement.

The next justified technical step is to make handoff markers durable across
`switch_root`, then run one bounded alternate-configuration test. See the
[latest experimental boot results](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/main/docs/kernel/experimental-boot-results.md)
and the [main project README](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival).

## What We Are Building

- Public-safe documentation for Xeon Phi 5110P bring-up, MPSS, the stock uOS, and K1OM behavior.
- Repeatable native smoke tests and experiment manifests for proving ABI and runtime assumptions.
- Toolchain research for K1OM compiler, assembler, linker, headers, startup objects, and sysroot requirements.
- Practical software-porting lanes, including Python, Doom, and eventually a new Ubuntu-derived uOS path.
- A clean separation between original open project work and proprietary Intel software that users must obtain under its own terms.

## Keywords And Scope

This organization covers Intel Xeon Phi 5110P and 5100-series Knights Corner
(KNC) coprocessors, the K1OM architecture and ABI, Intel MPSS, native K1OM
compilers and toolchains, Ubuntu-derived uOS development, Python 3.12 on K1OM,
cross-compilation, Linux runtime ports, and reproducible hardware experiments.
The work is also exploring practical software ports such as Doom, while
keeping application work behind the core boot, runtime, and licensing gates.

## Repositories

- [xeon-phi-revival](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival): main project roadmap, docs, public artifacts, tests, and tooling.

Start with the repository's [current status](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/main/docs/status.md),
[getting-started guide](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/main/docs/getting-started-card-to-code.md),
and [public source index](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/main/docs/source-index.md).

## Project Principles

This project treats evidence as the center of gravity. Hardware claims should come from captured output, experiment manifests, and reproducible validation steps. AI tools help accelerate planning, scripting, auditing, and documentation, but real Xeon Phi results are what become project facts.

Intel, Xeon, and Xeon Phi are trademarks of Intel Corporation. This project is unaffiliated with Intel and is not sponsored, endorsed, or supported by Intel.
