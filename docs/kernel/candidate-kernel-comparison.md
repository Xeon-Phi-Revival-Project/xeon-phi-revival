# Candidate KNC Kernel Comparison

| Property | Working MPSS kernel | Public 3.5.1 candidate | Reconstruction requirement |
| --- | --- | --- | --- |
| Release | `2.6.38.8+mpss3.4.10` | `2.6.38.8+mpss3.5.1` | reconcile only from evidence |
| Architecture | K1OM | K1OM ELF `vmlinux` built | `ARCH=k1om` build |
| Initramfs | ramfs root | `CONFIG_BLK_DEV_INITRD=y` | required |
| SCIF/vnet | required | kernel source present; not live-tested | required |
| Five module ABI | exact 3.4.10 vermagic | not yet rebuilt | rebuild and compare |

The 3.5.1 candidate is buildable but is not yet a boot candidate. Its release
differs from the installed 3.4.10 kernel, so the five external modules must be
rebuilt and their ABI checked before any bounded RAM-only `micctrl` test.
