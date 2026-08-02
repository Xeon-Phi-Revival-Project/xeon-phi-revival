# Candidate KNC Kernel Comparison

| Property | Working MPSS kernel | Local 3.8.6 archive | Reconstruction requirement |
| --- | --- | --- | --- |
| Release | `2.6.38.8+mpss3.4.10` | not source available | source tree must expose K1OM |
| Architecture | K1OM | binary payload only | `ARCH=k1om` build |
| Initramfs | ramfs root | unknown | required |
| SCIF/vnet | required | unknown | required |
| Five module ABI | exact 3.4.10 vermagic | no source | rebuild and compare |

No candidate currently qualifies for a build. The next source-search target is
a complete KNC/K1OM kernel tree from MPSS 3.4.x, 3.2, or 3.8, not a binary
archive or generic upstream Linux 2.6.38.
