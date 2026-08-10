# XPR-OS 0.1.0-rc2

XPR-OS 0.1.0-rc2 is a source-compliance correction to RC1. It contains no new
prebuilt operating-system image and makes no new hardware claims.

Changes from RC1:

- includes the complete LGPL 2.1 license text required by the tracked eglibc
  overlay sources;
- marks all six eglibc overlay files as `LGPL-2.1-or-later`;
- adds an automated source-release compliance audit;
- documents per-component binary redistribution decisions;
- adds a binary-component provenance manifest template;
- changes generated product identity to `Xeon Phi Revival K1OM uOS` to keep
  Ubuntu references factual rather than using the trademark in the title;
- preserves explicit Intel and Canonical non-endorsement notices.

The private reference image's previously documented final-root, PID 1,
networking, SSH, native execution, package-manager, reproducibility, and
rollback results remain unchanged.

This prerelease still contains source, metadata, and BYO-MPSS tooling only. It
does not include a kernel, modules, initramfs, rootfs, package archive, Intel
MPSS payload, firmware, or SDK/sysroot file. The current private binary image
must not be published until the component actions in
`docs/release/compliance-review.md` are complete and reviewed by a human.

