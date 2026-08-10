# XPR-OS 0.1.0-rc1

XPR-OS 0.1.0-rc1 is the first source and bring-your-own-MPSS prerelease of the
Xeon Phi Revival Project's experimental Ubuntu-derived K1OM uOS.

The private reference build passed on an Intel Xeon Phi 5110P with MPSS 3.4.10:

- project compatibility kernel and rebuilt card-side modules;
- project bootstrap and checksummed split-root handoff;
- final project root and PID 1;
- micveth and final-root Dropbear SSH;
- native K1OM hello and pthread tests;
- Python 3.12.13 and `ctypes`;
- native dpkg and local-file APT, including package reinstallation;
- reproducible image hashes and verified stock rollback.

This prerelease intentionally contains no prebuilt kernel, module, initramfs,
rootfs, package archive, Intel MPSS payload, firmware, or SDK/sysroot file.
Users must provide legally obtained MPSS/K1OM inputs locally and build private
artifacts with the repository tools.

The full private smoke passed once for the exact package-complete payload. The
same architecture also completed three consecutive earlier boots. Only the
Xeon Phi 5110P configuration is currently validated.

This is not an official Ubuntu, Canonical, or Intel release. It is a prerelease
for preservation, testing, and continued engineering work.
