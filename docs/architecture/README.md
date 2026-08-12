# XPR-OS Architecture

XPR-OS has a small host-to-card boot chain:

1. MPSS host tooling and driver, supplied separately.
2. Project K1OM compatibility kernel and five MIC modules.
3. Project outer Base CPIO and nested bootstrap root.
4. A checksummed final public root payload.
5. Project `/sbin/init` as PID 1, micveth, Dropbear, and the K1OM runtime.

For an approachable overview, see [Boot Process](../concepts/boot-process.md).
For detailed evidence, use [kernel reconstruction](../kernel/compatible-kernel-reconstruction.md),
[module build](../kernel/candidate-module-build.md), and
[public clean stack validation](../release/public-clean-stack-validation.md).

