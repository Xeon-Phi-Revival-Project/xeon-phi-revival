# KNC Kernel Source Audit

Date: 2026-08-01

## Target

The verified lab kernel reports release `2.6.38.8+mpss3.4.10` and is loaded
by MPSS 3.4.10 through `micctrl`. The installed package metadata identifies
the boot payload package as `mpss-boot-files-3.4.10-1.glibc2.12.x86_64` with a
`GPLv2` license field.

## Audit Result

No corresponding kernel source tree, K1OM configuration, patch series, build
manifest, or source RPM was present in this repository or among the locally
inspected MPSS inputs. The stock kernel image is therefore a local-only
compatibility input, not a project-built or publication-cleared artifact.

`GPLv2` package metadata is evidence that corresponding source may be
obtainable from the distributor; it is not evidence that this project has
obtained, verified, or may publish the binary. A compatible source release
must provide the exact configuration and K1OM/MPSS patch set before an XPR
kernel build can be claimed.

## Required To Proceed

Obtain a legally accessible corresponding source release for MPSS 3.4.10,
including the kernel configuration and all KNC-specific patches, then verify
that it builds the observed kernel ABI and is accepted by the host driver.
