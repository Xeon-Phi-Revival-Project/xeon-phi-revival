# Xeon Phi Revival Project

The Xeon Phi Revival Project is an AI-assisted, Codex-driven preservation and engineering effort focused on restoring useful software-development paths for Intel Xeon Phi Knights Corner coprocessors and the K1OM architecture.

The current baseline is a working Intel Xeon Phi 5110P running MPSS 3.4.10, with native K1OM assembly, C, pthread, math, file-I/O, and 512-bit vector smoke tests validated on real hardware.

## Human Section
Hello, I am @CarlsonDataCenter, and I am the maintainer and overarching manager of this project. I am a high schooler who thought that this would be a fun learning project to try and build back up an old, obscure piece of technology, the Intel Xeon Phi Coprocessor. With the mainstream of AI, I'm able to use Codex to make this project possible, as I know 0 zero code but have a background in hardware, servers, basic shell, etc. This project goes to show how helpful AI can be used, when used rightly. The majority of the code and descriptions are AI-generated, but they are audited by me, and changes I direct are implemented. So, I continue with the project.

## What We Are Building

- Public-safe documentation for Xeon Phi 5110P bring-up, MPSS, the stock uOS, and K1OM behavior.
- Repeatable native smoke tests and experiment manifests for proving ABI and runtime assumptions.
- Toolchain research for K1OM compiler, assembler, linker, headers, startup objects, and sysroot requirements.
- Practical software-porting lanes, including Python, Doom, and eventually a new Ubuntu-derived uOS path.
- A clean separation between original open project work and proprietary Intel software that users must obtain under its own terms.

## Repositories

- [xeon-phi-revival](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival): main project roadmap, docs, public artifacts, tests, and tooling.

## Project Principles

This project treats evidence as the center of gravity. Hardware claims should come from captured output, experiment manifests, and reproducible validation steps. AI tools help accelerate planning, scripting, auditing, and documentation, but real Xeon Phi results are what become project facts.

Intel, Xeon, and Xeon Phi are trademarks of Intel Corporation. This project is unaffiliated with Intel and is not sponsored, endorsed, or supported by Intel.
