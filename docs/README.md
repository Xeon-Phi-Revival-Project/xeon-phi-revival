# Documentation

This index separates current instructions from historical experiment records.
Start with the pages in **Current Guides**. Reports under the technical sections
preserve what was known at the time and may describe blockers that were solved
later.

## Current Guides

| Goal | Document |
| --- | --- |
| Install a card and run native K1OM code | [From Card To Code](getting-started-card-to-code.md) |
| Understand the latest verified state | [Project Status](status.md) |
| Build the public source RC or a private BYO-MPSS image | [Build XPR-OS RC From Source](release/build-xpr-os-rc-from-source.md) |
| Build and boot using the current lab scripts | [RC Build And Boot Reference](ubuntu-port/uos-rc-build-install.md) |
| Recover stock MPSS after an experiment | [Stock Rollback Baseline](uos/stock-rollback-baseline.md) |
| Check release licensing and redistribution boundaries | [Compliance Review](release/compliance-review.md) |
| Find public upstream sources without redistributing them | [Source Index](source-index.md) |
| Contribute safely | [Contributing](../CONTRIBUTING.md) |

## Release Evidence

- [XPR-OS 0.1 RC live report](ubuntu-port/xpr-uos-0.1-rc-live-report.md)
- [RC acceptance checklist](ubuntu-port/uos-rc-acceptance-checklist.md)
- [RC2 release notes](release/xpr-os-0.1.0-rc2-release-notes.md)
- [License review](release/xpr-uos-0.1-license-review.md)
- [Kernel and module redistribution boundary](kernel/redistribution-boundary.md)

## Technical References

| Area | Recommended entry point |
| --- | --- |
| K1OM ABI | [Observed K1OM ELF ABI](architecture/observed-k1om-elf-abi.md) |
| Toolchain | [Minimum K1OM Runtime](toolchain/minimum-k1om-runtime.md) |
| Kernel reconstruction | [Compatible Kernel Reconstruction](kernel/compatible-kernel-reconstruction.md) |
| Ubuntu-derived userland | [True Ubuntu Port Readiness](ubuntu-port/true-ubuntu-port-readiness.md) |
| MPSS boot path | [PID 1 Boot Path](uos/pid1-boot-path.md) |
| Hardware baseline | [5110P, R730, CentOS 7.4](hardware/5110p-r730-centos74.md) |
| Terminology | [Glossary](handbook/glossary.md) |

## Historical Reports

The `docs/kernel/`, `docs/uos/`, and `docs/ubuntu-port/` directories contain
dated experiment reports. They are retained because failed approaches, hashes,
rollback evidence, and intermediate boundaries are useful preservation data.
When a historical report conflicts with [Project Status](status.md), the status
page and the newest live report are authoritative for current capability.
