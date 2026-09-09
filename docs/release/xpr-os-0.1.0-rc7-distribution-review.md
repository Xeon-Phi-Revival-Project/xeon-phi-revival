# XPR-OS 0.1.0-rc7 Distribution Review

This document describes the 0.1.0-rc7 package candidate. It is engineering
provenance material, not legal advice, publication approval, or a public
release announcement.

## Candidate State

The candidate uses the hash-pinned, previously validated K1OM kernel and five
MIC modules. Its bootstrap and final root are newly constructed from the
current source-built BusyBox, Dropbear, eglibc, libgcc, and XPR helper inputs.
The final root includes the exact hardware-validated CPython 3.12.13 core
package and the current project-owned `xpr-init` host integration tool.

Candidate G preserves Candidate F's generic runtime and adds project-owned SSH
alias/host-key provisioning tooling. Candidate F remains historical evidence;
Candidate G2 passed its own hardware and recovery validation. Exact results and
hashes are recorded externally without changing the archive after testing.

## Distribution Boundary

The binary candidate contains source-accounted kernel, module, bootstrap,
root-payload, Python, and host-integration artifacts. The paired source archive
contains the pinned corresponding-source material, project build scripts,
configs, patches, license texts, notices, and SPDX metadata.

Intel MPSS host software, firmware, SDK binaries, stock uOS contents, private
historical CPIO inputs, fixed authorization keys, passwords, and private keys
are not included. The separately prepared standalone K1OM toolkit binary is
also excluded while its source-distribution terms remain under qualified human
review.

## Component Decisions

| Component | Source/accounting | RC7 decision |
| --- | --- | --- |
| XPR K1OM kernel | Exact reproduced, hash-pinned kernel source and config | Include |
| Five MIC modules | Mapped MPSS 3.4.10 source, build inputs, and hashes | Include |
| BusyBox 1.19.4 | Fresh source build with tracked configuration | Include |
| Dropbear 2022.83 | Fresh source build with deployment-key provisioning | Include |
| eglibc runtime | Fresh source build from pinned source and XPR overlay | Include |
| `libgcc_s.so.1` | GCC 5.1.1 KNC source build; Runtime Library Exception included | Include |
| XPR bootstrap and final-root files | Current tracked XPR scripts, configuration, and helpers | Include |
| `xpr-init` | Current tracked host integration source | Include |
| CPython 3.12.13 core | Official hash-pinned source, tracked K1OM patches, validated package | Include |
| Python 3.5 | Not present | Exclude |
| Intel MPSS SDK binary payload | Not present | Exclude |
| Private or universal credentials | Not present | Exclude |
| Standalone XPR K1OM Toolkit binary | Technically validated; separate KNC-binutils terms review open | Hold human review; exclude |

## Current Decision

This repository review records the completed Candidate G2 validation; the
immutable archive retains its pre-validation review. The external exact-candidate
audit, hardware and recovery record, and checksums passed. Owner publication
authorization remains required. See the
[G2 record](xpr-os-0.1.0-rc7-candidate-g-validation.md).
The corresponding-source, SPDX, notices, checksum, and reproducibility gates
also passed. Publication remains an owner decision; the standalone toolkit
binary remains excluded under its separate human-review hold.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`
