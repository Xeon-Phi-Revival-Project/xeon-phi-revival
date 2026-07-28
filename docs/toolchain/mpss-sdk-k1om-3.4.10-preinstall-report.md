# MPSS SDK K1OM 3.4.10 Preinstallation Report

This is a preinstallation report only. The package was not installed, extracted,
or executed.

## Package Identity

- Full filename: `mpss-sdk-k1om-3.4.10-1.x86_64.rpm`
- Local RPM path inspected:
  `<local-mpss-extract>/mpss-3.4.10/mpss-sdk-k1om-3.4.10-1.x86_64.rpm`
- Local archive path on Windows:
  `<local-mpss-archive>/mpss-3.4.10-linux.tar`
- Local archive SHA-256:
  `0C09C891FE320442D9B183DC6889F566B3D47BBDC008D2BB3446DA4FA5105CC5`
- RPM SHA-256:
  `982ba69037f3c4e2728d5bf0b038fead163a4c10db1d8a53f33e14a2afe0f401`

## Provenance

The RPM was inspected from the locally supplied MPSS 3.4.10 archive that had
already been extracted on the CentOS host.

Package header URL:

- `http://software.intel.com/xeonphi`

Local archive metadata also records an Internet Archive item named
`mpss-intel`, uploaded as `MPSS_Intel.zip`, with creator metadata set to
`Intel Corporation`. That archive metadata is not treated as a license grant or
as cryptographic authenticity proof. The package's own RPM metadata is the main
local provenance signal.

## RPM Header

- Name: `mpss-sdk-k1om`
- Version: `3.4.10`
- Release: `1`
- Architecture: `x86_64`
- Group: `base`
- License field: `various`
- Source RPM: `mpss-sdk-k1om-3.4.10-1.src.rpm`
- Build date: `Thu 12 Jan 2017 04:59:02 PM EST`
- Build host: `sid-bld24.pdx.intel.com`
- Packager: `Intel Corporation`
- Relocations: not relocatable
- Installed size from RPM header: `488903494`
- Summary: SDK package for MPSS on Intel MIC co-processors
- Description: self-contained cross-toolchain for building programs for K1OM
  coprocessors running MPSS.

## Signature And Digests

`rpm --checksig -v` reported:

- Header signature: `Header V4 DSA/SHA1 Signature, key ID d910a4f1: NOKEY`
- Header SHA1 digest: OK
- MD5 digest: OK

Interpretation:

- The RPM contains a signature header with Intel-looking package metadata.
- The local host does not have the public key imported, so RPM cannot verify the
  signature chain.
- Authenticity is plausible but not fully verified until the signing key is
  validated from a trusted source.

## Requirements, Provides, Conflicts

Required packages/capabilities from `rpm -qRp`:

- `/bin/sh`
- `rpmlib(PartialHardlinkSets) <= 4.0.4-1`

Provided capabilities from `rpm -qp --provides`:

- `mpss-sdk-k1om = 3.4.10-1`

Conflicts:

- No declared conflicts were reported.

Obsoletes:

- No declared obsoletes were reported.

Host impact interpretation:

- The package installs under `/opt/mpss/3.4.10`, not over `/usr/bin/gcc`.
- No direct conflict with existing host GCC was declared.
- It version-matches the currently running MPSS 3.4.10 stack.

## Scripts, Triggers, Configuration

Postinstall script:

```sh
# mpss-sdk-k1om - postinst
#!/bin/sh
if [ x"$D" = "x" ]; then
	[ -x /sbin/ldconfig ] && /sbin/ldconfig
fi
```

Triggers:

- No trigger scripts were reported.

Configuration impact:

- The only reported postinstall action is `/sbin/ldconfig` when not installing
  into an alternate root.
- No service enablement, firmware operation, module loading, or MPSS
  reconfiguration script was reported.

## Installation Paths

Primary paths:

- `/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux`
- `/opt/mpss/3.4.10/site-config-k1om-mpss-linux`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux`
- `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux`

The package is self-contained under `/opt/mpss/3.4.10`.

## Tool Prefix

Observed tool prefix:

- `k1om-mpss-linux-`

Not observed as the primary prefix:

- `x86_64-k1om-linux-`

Important paths:

- `.../usr/bin/k1om-mpss-linux/k1om-mpss-linux-gcc`
- `.../usr/bin/k1om-mpss-linux/k1om-mpss-linux-g++`
- `.../usr/bin/k1om-mpss-linux/k1om-mpss-linux-as`
- `.../usr/bin/k1om-mpss-linux/k1om-mpss-linux-ld`
- `.../usr/bin/k1om-mpss-linux/k1om-mpss-linux-objdump`
- `.../usr/bin/k1om-mpss-linux/k1om-mpss-linux-readelf`

## Environment Exposure

Environment files:

- `/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux`
- `/opt/mpss/3.4.10/site-config-k1om-mpss-linux`

Relevant internal symlinks include:

- GCC libexec `as` -> `k1om-mpss-linux-as`
- GCC libexec `gcc` -> `k1om-mpss-linux-gcc`
- GCC libexec `ld` -> `k1om-mpss-linux-ld`

The tools should not be assumed visible on `PATH` until the environment script
is sourced or the tool directory is added explicitly.

## Complete Grouped File Lists

Complete public-safe RPM file-list metadata is stored under:

- `artifacts/public/preinstall/mpss-sdk-k1om-3.4.10/file-list.txt`
- `artifacts/public/preinstall/mpss-sdk-k1om-3.4.10/file-list-verbose.txt`
- `artifacts/public/preinstall/mpss-sdk-k1om-3.4.10/grouped/`

Group counts:

- Environment scripts: 2
- Compiler tools: 4
- Binutils/debug tools: 16
- Startup objects: 7
- Headers: 1865
- Libraries: 424
- Documentation/debug source/man pages: 3575
- Other sysroot files: 2132
- Total files: 8025

Grouped files:

- `grouped/environment.txt`
- `grouped/compiler.txt`
- `grouped/binutils.txt`
- `grouped/startup-objects.txt`
- `grouped/headers.txt`
- `grouped/libraries.txt`
- `grouped/documentation.txt`
- `grouped/other.txt`

## Key Group Contents

Compiler:

- `k1om-mpss-linux-cpp`
- `k1om-mpss-linux-g++`
- `k1om-mpss-linux-gcc`
- `k1om-mpss-linux-gcov`

Binutils/debug tools:

- `k1om-mpss-linux-addr2line`
- `k1om-mpss-linux-ar`
- `k1om-mpss-linux-as`
- `k1om-mpss-linux-c++filt`
- `k1om-mpss-linux-elfedit`
- `k1om-mpss-linux-gprof`
- `k1om-mpss-linux-ld`
- `k1om-mpss-linux-ld.bfd`
- `k1om-mpss-linux-nm`
- `k1om-mpss-linux-objcopy`
- `k1om-mpss-linux-objdump`
- `k1om-mpss-linux-ranlib`
- `k1om-mpss-linux-readelf`
- `k1om-mpss-linux-size`
- `k1om-mpss-linux-strings`
- `k1om-mpss-linux-strip`

Startup objects:

- `Mcrt1.o`
- `Scrt1.o`
- `crt1.o`
- `crti.o`
- `crtn.o`
- `gcrt1.o`
- `crtfastmath.o`

GCC support libraries:

- Includes `libgcc.a`, `libgcc_eh.a`, `libgcc_s.so`, and `libgcc_s.so.1`.
- Includes `libstdc++.a`, `libstdc++.so`, `libstdc++.so.6`, and
  `libstdc++.so.6.0.16`.
- No `libgomp` or obvious OpenMP runtime was observed in this package.

Runtime libraries:

- Includes K1OM loader/runtime libraries such as `ld-linux-k1om.so.2`,
  `libc.so.6`, `libpthread.so.0`, `libm.so.6`, and `libdl.so.2`.
- Also includes host-side SDK runtime under `x86_64-mpsssdk-linux`.

## Authenticity Assessment

Appears official and version-matched:

- Packager is `Intel Corporation`.
- Build host is `sid-bld24.pdx.intel.com`.
- URL points to Intel Xeon Phi software.
- Version is exactly `3.4.10`, matching the running MPSS stack.
- It provides the expected K1OM SDK sysroot and `k1om-mpss-linux-*` tools.

Remaining caveat:

- RPM signature cannot be fully verified on the current host because the signing
  key is not imported: `NOKEY`.

## Prepared Install Commands

Do not run these without explicit approval.

```sh
sudo rpm -Uvh <local-mpss-extract>/mpss-3.4.10/mpss-sdk-k1om-3.4.10-1.x86_64.rpm
```

More cautious metadata-first command:

```sh
sudo rpm -Uvh --test <local-mpss-extract>/mpss-3.4.10/mpss-sdk-k1om-3.4.10-1.x86_64.rpm
```

Expected package name after install:

```sh
rpm -q mpss-sdk-k1om
```

Prepared rollback:

```sh
sudo rpm -e mpss-sdk-k1om
sudo /sbin/ldconfig
```

## Prepared Validation Sequence

Do not execute on `mic0` without explicit approval.

After installation only:

```sh
source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
bash toolchains/detect-k1om-toolchain.sh
```

Print versions:

```sh
k1om-mpss-linux-gcc --version
k1om-mpss-linux-as --version
k1om-mpss-linux-ld --version
k1om-mpss-linux-objdump --version
k1om-mpss-linux-readelf --version
```

Assemble and link the freestanding `_start` test:

```sh
mkdir -p build/k1om-sdk-validation
k1om-mpss-linux-gcc -c tests/native/start-exit42.S -o build/k1om-sdk-validation/start-exit42.o
k1om-mpss-linux-ld -nostdlib -e _start -o build/k1om-sdk-validation/start-exit42 build/k1om-sdk-validation/start-exit42.o
```

Verify K1OM ELF:

```sh
file build/k1om-sdk-validation/start-exit42
k1om-mpss-linux-readelf -h build/k1om-sdk-validation/start-exit42
k1om-mpss-linux-readelf -l build/k1om-sdk-validation/start-exit42
od -An -j18 -N2 -tu2 build/k1om-sdk-validation/start-exit42
```

The `od` result must be `181`.

Prepared scripted validation:

```sh
bash tools/runners/validate-k1om-sdk-install.sh
```

The existing harness must remain dry-run unless explicitly approved:

```sh
bash experiments/run-native-k1om-test.sh --binary build/k1om-sdk-validation/start-exit42
```

Running the binary on `mic0` would require a separate explicit approval and
`--execute`.
