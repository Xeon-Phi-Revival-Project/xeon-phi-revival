# Research And Historical Record

This area preserves the technical work that made the current XPR baseline
possible: successful and failed experiments, vendor-era observations, kernel and
module reconstruction, uOS analysis, package/toolchain investigation, and dated
project records.

**Research documents are evidence and learning material, not automatically
current installation instructions.** For the supported user path, use
[Getting Started](../getting-started/README.md) and [Project Status](../status.md).

## Research Map

### Kernel, Modules, And Boot

- [Kernel research index](../kernel/README.md)
- [Compatible kernel reconstruction](../kernel/compatible-kernel-reconstruction.md)
- [Module source audit](../kernel/module-source-audit.md)
- [Experimental boot results](../kernel/experimental-boot-results.md)
- [Bring-up records](../bring-up/README.md)

### uOS, Bootstrap, And Userspace

- [uOS research index](../uos/README.md)
- [Stock MPSS 3.4.10 uOS inventory](../uos/stock-mpss-3.4.10-uos-inventory.md)
- [Ubuntu 24.04 / K1OM uOS research](../uos/ubuntu-24.04-uos-research.md)
- [Ubuntu/K1OM port index](../ubuntu-port/README.md)

### Toolchain And Runtime

- [K1OM toolchain research](../toolchain/README.md)
- [Source Index](../source-index.md)
- [Observed K1OM ELF ABI](../architecture/observed-k1om-elf-abi.md)
- [Reproducibility](../reproducibility.md)

### Historical Project Records

- [Historical project/planning index](history/README.md)
- Dated publication audit, old pause checkpoint, early development plan, and old Wiki/Pages plans are retained there rather than in the active docs root.

### Release And Physical Evidence

- [Release records](../release/README.md)
- [Experiment/release manifests](../../manifests/README.md)
- [Generated evidence artifacts](../../artifacts/README.md)

## How To Read Old Results

A historical document may correctly describe what happened at the time while no
longer representing the current project state. In particular, early 71S1P
failures, manual boot procedures, old private-input concerns, and pre-`xpr-init`
installation workflows should not be generalized into current 5110P guidance.

When a research result is promoted into a current project claim, the current
status/user documentation should point to the underlying evidence. When an
approach is superseded, preserve it here with context instead of rewriting
history.
