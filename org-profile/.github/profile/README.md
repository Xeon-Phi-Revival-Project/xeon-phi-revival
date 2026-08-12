# Xeon Phi Revival Project

**Open-source preservation, software revival, and practical K1OM development
for Intel Xeon Phi Knights Corner coprocessors.**

The project combines hardware bring-up, K1OM ABI and toolchain work,
project-built userspace, software-port experiments, and public-safe historical
research. Its first public XPR-OS release candidate has been tested on an Intel
Xeon Phi 5110P.

## Human Section
Hello, I am @CarlsonDataCenter, and I am the maintainer and overarching manager of this project. I am a high schooler who thought that this would be a fun learning project to try and build back up an old, obscure piece of technology, the Intel Xeon Phi Coprocessor. With the mainstream of AI, I'm able to use Codex to make this project possible, as I know 0 zero code but have a background in hardware, servers, basic shell, etc. This project goes to show how helpful AI can be used, when used rightly. The majority of the code and descriptions are AI-generated, but they are audited by me, and changes I direct are implemented. So, I continue with the project.

## Current Milestone: XPR-OS RC6

[XPR-OS 0.1.0-rc6](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6)
is the project's first public release candidate for Intel Xeon Phi Knights
Corner. It is a prerelease, not a stable release.

The tested 5110P path proves:

- Project K1OM-compatible kernel, five MIC modules, bootstrap, and final root.
- Final XPR `/sbin/init` as PID 1.
- micveth networking and authenticated Dropbear SSH with a user-supplied RSA
  public key.
- Native dynamic hello, pthread, and `dlopen` smoke tests.
- Three rollback-protected boots, each restoring stock MPSS, SSH, and init.

Intel Xeon Phi 5110P is the only hardware model tested by this project so far.
Other Knights Corner cards may be compatible but are untested. Knights Landing
is a different platform and is not an XPR-OS target.

## Project Tracks

| Track | Focus |
| --- | --- |
| **XPR-OS** | Project-built K1OM boot environment and Linux userspace |
| **K1OM tooling** | Compiler, linker, ABI, sysroot, and runtime research |
| **Software ports** | Python, Doom, and other practical K1OM programs |
| **Hardware preservation** | MPSS bring-up, thermal behavior, recovery, and compatibility evidence |
| **Research archive** | KNC/uOS, kernel, module, and release-engineering records |

## Start Here

- [Install XPR-OS RC6](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/main/docs/getting-started/installation.md)
- [Check supported hardware](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/main/docs/hardware/supported-hardware.md)
- [Read the current project documentation](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/tree/main/docs)
- [Explore historical research](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/tree/main/docs/research)
- [Contribute](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/main/CONTRIBUTING.md)

## Repositories

- [xeon-phi-revival](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival): main source repository, documentation, XPR-OS release, tests, and research record.

## Project Principles

This project treats evidence as the center of gravity. Hardware claims should
come from captured output, experiment manifests, and reproducible validation
steps. AI tools help accelerate planning, scripting, auditing, and
documentation, but real Xeon Phi results are what become project facts.

Intel, Xeon, and Xeon Phi are trademarks of Intel Corporation. This project is
unaffiliated with Intel and is not sponsored, endorsed, or supported by Intel.
