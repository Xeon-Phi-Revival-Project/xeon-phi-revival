# Xeon Phi Revival

The Xeon Phi Revival Project is a community preservation and engineering effort
focused on restoring usable software-development support for Intel Xeon Phi
Knights Corner coprocessors. The project has successfully compiled and executed
native K1OM assembly, C, pthread, math, file-I/O, and 512-bit vector test
programs on an Intel Xeon Phi 5110P running MPSS 3.4.10.

## What This Is

Intel Xeon Phi Knights Corner cards are PCIe coprocessors, not ordinary host
CPUs. They run a small Linux-based uOS on K1OM cores and are managed by Intel
MPSS from an x86-64 host.

K1OM is the Knights Corner native ISA/ABI target. It is not normal x86-64, even
though many tools display ELF64 containers. Native card binaries must report
`Machine: Intel K1OM` and ELF machine value `181`.

## Proven Baseline

Current verified hardware and software baseline:

- Card: Intel Xeon Phi 5110P / 5100 series
- Host: Dell PowerEdge R730
- Host OS: CentOS 7.4.1708
- MPSS: 3.4.10
- Toolchain package: `mpss-sdk-k1om-3.4.10-1.x86_64`
- Tool prefix: `k1om-mpss-linux-*`
- Card state: `mic0` online with SSH working

Verified native runs:

- Freestanding `_start` K1OM ELF returned exit code `42`.
- Dynamically linked K1OM libc hello-world printed `hello from k1om libc`.
- Native C smoke test reported `machine=k1om`, 64-bit pointers, and 64-bit
  longs.
- File I/O, `libm`, pthread creation/join, normal return codes, and zmm vector
  instructions were tested on the card.
- Disassembly of the vector smoke test confirmed `vbroadcastsd`, `vaddpd`, and
  `vmovapd`.

## Current Goals

- Preserve public-safe knowledge about Knights Corner, K1OM, MPSS, and the uOS
  runtime.
- Build small, repeatable native test programs that prove specific runtime and
  ABI behavior.
- Map the minimum runtime and sysroot pieces needed for ports.
- Explore practical ports such as Python and Doom after the C/runtime baseline
  is well understood.
- Keep proprietary Intel payloads, firmware, extracted sysroots, and unclear
  third-party materials out of the repository.

## Repository Structure

- `docs/`: public-safe architecture, uOS, hardware, and toolchain notes.
- `tests/`: original K1OM smoke-test source code.
- `tools/`: original helper scripts for metadata collection and validation.
- `toolchains/`: notes and scripts for Intel MIC and open-toolchain lanes.
- `uos/`: scripts and notes for inventorying locally supplied uOS contents.
- `experiments/`: native run harnesses.
- `manifests/`: hardware and experiment manifests.
- `artifacts/public/`: public-safe generated metadata only.

## Bring Your Own MPSS

This repository does not redistribute Intel MPSS packages, Intel compiler
installers, firmware, extracted sysroots, stock uOS images, Intel headers, Intel
libraries, or copied Intel documentation.

Users must obtain any required Intel software under its applicable terms. The
project documentation may refer to package names, versions, hashes, paths, and
ELF metadata, but those references are not redistributions of the underlying
software.

## Status

Phase 1 is complete: a real Xeon Phi 5110P moved from PCIe enumeration and MPSS
bring-up to repeatable native K1OM program execution.

The next milestone is to use the passing libc, file-I/O, `libm`, pthread, and
zmm-vector baseline to start Python and Doom feasibility lanes.

## Independence

This is experimental preservation work. Intel, Xeon, and Xeon Phi are trademarks
of Intel Corporation. This project is unaffiliated with Intel and is not
sponsored, endorsed, or supported by Intel.

## License

No project license has been selected yet. Until a license is added, do not
assume permission to reuse original project code or documentation beyond normal
GitHub viewing and forking behavior. Any future project license will apply only
to original project work, not to Intel software or third-party components.
