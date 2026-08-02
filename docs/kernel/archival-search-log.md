# KNC Kernel Archival Search Log

Date: 2026-08-01

| Query / source | Result | Disposition |
| --- | --- | --- |
| Local RPM header | `glibc2.12pkg-mpss-boot-files-3.4.10-1.glibc2.12.src.rpm` | Exact expected source name recorded. |
| Local MPSS archive/cache | No boot-files source RPM, kernel tree, config, or patch series | Rejected as incomplete. |
| Internet Archive exact filename | Zero metadata results | No archival lead. |
| Internet Archive `mpss-3.4.10` | Zero metadata results | No archival lead. |
| GitHub code search | Authentication required | Not a negative source result; unauthenticated endpoint cannot search code. |
| GitHub repository search | Public `mpss-modules` repositories found | Rejected: Linux 4.1/4.2 ports, MPSS 3.4.6, and MPSS 3.8.x are not the exact KNC kernel source. |
| Supplied Xeon Phi books and K1OM psABI | MPSS administration, ABI, and host-support material | Useful context only; no boot-files SRPM URL, KNC kernel tree, config, patch series, or GPL source-offer found. |

The local GPLv2 `mpss-modules-3.4.10` source remains the only exact-version
source candidate found. It does not contain the KNC kernel source or config.

The supplied books are not copied into this repository and are not treated as
source-distribution evidence. They support the existing historical MPSS/K1OM
documentation but do not unblock a project-built kernel.
