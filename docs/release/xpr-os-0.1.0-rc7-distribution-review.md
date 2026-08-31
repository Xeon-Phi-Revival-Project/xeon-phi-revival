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

Candidate E, SHA-256
`a4b313ad4b696ebdfe8a406da18288d1903933a6d3a12a1a41da1a69f218e0a4`,
passed the complete Intel Xeon Phi 5110P hardware cycle and exact stock
recovery. The completed evidence is recorded separately so the validated
artifact does not change after testing.

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

## Current Decision

`XPR_OS_RC7_CANDIDATE=TECHNICALLY_PASS`. Static audit, live Intel Xeon Phi
5110P validation, Python core validation, and exact stock recovery passed.
Publication remains an owner decision; the standalone toolkit binary remains
excluded under its separate human-review hold.
