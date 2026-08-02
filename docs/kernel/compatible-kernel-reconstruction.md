# Experimental Compatible KNC Kernel Reconstruction

This is an independent compatibility reconstruction track. It is not an
MPSS 3.4.10 source reproduction and must not be described as one.

The objective is a source-available K1OM kernel that `micctrl` can boot with
the project Base CPIO, rootfs, five required modules, readiness path, and
virtual networking. The exact-source recovery track remains open.

## Candidate Inventory

The local MPSS 3.8.6 archive was inspected read-only:

```text
archive SHA-256: fce922dd0fc62e0a7f3afb431f870d71679e76d82f2db867cb03c45584f548f3
```

It contains binary `mpss-boot-files` and host-module RPMs, not a KNC kernel
source tree, config, or K1OM patch series. It is rejected as a build baseline.

The local GPLv2 MPSS 3.4.10 module source remains a module candidate only. A
complete source-available KNC kernel tree with real K1OM support is still
required before any build or boot test.
