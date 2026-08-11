# XPR-OS 0.1.0-rc3 Review Report

Date: 2026-08-10  
Status: `AUTOMATED_CHECKS_PASS_HUMAN_LEGAL_REVIEW_PENDING`

## Exact Candidate

- Build commit: `3009614426d59cb5f1eaac899a950aeff3c6de2d`
- Binary archive: `xpr-os-0.1.0-rc3.tar.gz`
  - SHA-256: `9ce4ec5a9a6f14252cf5eb0f6859d4908fcfb48845b78f65ccb6d7108d7f36a1`
  - Size: `20,408,216` bytes
- Source archive: `xpr-os-0.1.0-rc3-sources.tar.gz`
  - SHA-256: `4d7c52690fb7983ae263f129c7bd4a6b2387c0636b384dbb60d3be19d555403a`
  - Size: `362,581,454` bytes

Two independent CentOS 7 packaging runs produced identical bytes for both
archives. This external follow-up records the hashes without placing a source
archive's own hash inside itself. The package verifier passed after clean
extraction in both runs.

## Automated Gates

- Source compliance: pass
- Public final-root audit: 78 files, 0 errors
- SPDX 2.3 generation: 7 packages, 24 files
- SPDX-backed final-root audit: pass
- Frozen kernel/module/bootstrap/payload hashes: pass
- Secret, key, firmware, RPM, and DEB checks: pass
- Complete member `SHA256SUMS`: pass
- Binary and source archive reproducibility: pass
- Three identical hardware boots: pass
- Final project PID 1, micveth, final-root SSH: pass
- Native hello, pthread, and `dlopen`: pass
- Stock rollback after every boot: pass

No hardware run was repeated during packaging. The kernel in the archive is
byte-identical to the kernel used in the three validated boots.

## Human Decision Required

A qualified reviewer must answer both questions before publication:

1. Do the archive-level GPLv2 `COPYING` and direct per-file GPLv2 grants support
   distribution of the five K1OM module binaries with the staged complete
   corresponding source and mapped kernel/toolchain dependencies?
2. Do the exact archives and included notices satisfy the applicable GPL,
   LGPL, GCC Runtime Library Exception, and permissive-license obligations?

No `v0.1.0-rc3` tag or GitHub prerelease has been created.
