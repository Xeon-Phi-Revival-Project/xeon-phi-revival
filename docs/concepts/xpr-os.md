# What Is XPR-OS?

XPR-OS is a project-built K1OM boot and userspace environment for Intel Xeon
Phi Knights Corner cards. It starts from a separately supplied MPSS host path,
then boots project-owned kernel/modules/bootstrap material, transfers a final
XPR root, and runs project `/sbin/init` as PID 1.

It is not an Intel product, an official Ubuntu release, or a replacement for
the host MPSS driver. Its goal is a useful, documented, reversible environment
for preserving and using KNC hardware.

