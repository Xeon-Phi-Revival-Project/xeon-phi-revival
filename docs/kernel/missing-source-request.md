# Corresponding Source Request: MPSS 3.4.10 KNC Boot Kernel

## Requested Material

Please provide the complete corresponding source for:

```text
binary package: mpss-boot-files-3.4.10-1.glibc2.12.x86_64
source RPM:     glibc2.12pkg-mpss-boot-files-3.4.10-1.glibc2.12.src.rpm
kernel release: 2.6.38.8+mpss3.4.10
```

The requested source should include the KNC/K1OM Linux kernel tree, exact
configuration, MPSS patch series, packaging/spec files, build instructions,
and generated-header procedure needed to build the boot kernel. It should also
identify the source/configuration needed to build the companion card modules.

## Provenance

The installed RPM identifies Intel's historical Xeon Phi software URL, reports
GPLv2, and names the source RPM above. The package was built by Intel on
`sid-bld24.pdx.intel.com` on 2017-01-12.

## Why It Is Needed

The Xeon Phi Revival Project has independently implemented its card userspace
but cannot responsibly distribute the remaining KNC kernel or modules without
verifiable corresponding source and license compliance material.
