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

Hardware validation of the assembled candidate is pending. Any completed
validation is recorded separately against the exact immutable archive hash so
that release evidence does not change the artifact it describes.

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

`RC7_CANDIDATE_PENDING_HARDWARE_VALIDATION` applies until the exact archive
passes the static audit, live Intel Xeon Phi 5110P validation, and stock
recovery gates. The candidate must not be tagged or published before the owner
reviews the completed evidence.
