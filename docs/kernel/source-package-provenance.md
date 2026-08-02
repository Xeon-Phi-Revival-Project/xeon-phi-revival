# MPSS 3.4.10 Source Package Provenance

Date: 2026-08-01

## Installed Binary Mapping

The installed boot package identifies its expected corresponding source RPM:

```text
binary:    mpss-boot-files-3.4.10-1.glibc2.12.x86_64
source RPM: glibc2.12pkg-mpss-boot-files-3.4.10-1.glibc2.12.src.rpm
license:   GPLv2
URL:       http://software.intel.com/xeonphi
```

That source RPM is not present in the local MPSS archive/cache. The configured
CentOS repositories contain no enabled source repository and cannot resolve
their legacy mirror metadata.

## Found Module Source Candidate

The local MPSS 3.4.10 archive contains:

```text
mpss-modules-3.4.10-1.src.rpm
SHA-256: 35ed5f3e3fd0e317e2d067d756b4f2b64722e59048961dab840fe8a38b9a3c4e

mpss-modules-3.4.10.tar.bz2
SHA-256: 0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54
license: GPLv2
vendor: Intel Corporation
build host: sid-bld24.pdx.intel.com
build date: 2017-01-12
```

Its inventory includes `mpssboot/mpssboot.c`, `mpssboot/Kbuild`,
`micscif/` sources and Kbuild metadata, `vnet/micveth*.c`, DMA source, shared
MIC headers, and a top-level Makefile. This is a credible corresponding-source
candidate for the five required module interfaces, subject to an exact build
and ABI comparison.

It does not include the KNC kernel source, `.config`, or K1OM kernel patch
series required to build those modules for `2.6.38.8+mpss3.4.10`.
