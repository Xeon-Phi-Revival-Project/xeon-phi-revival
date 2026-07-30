# Real Ubuntu Noble dpkg on K1OM

Status: core build and reversible on-card install transaction passed.

Date: 2026-07-29

## Result

Ubuntu Noble `dpkg` source version `1.22.6ubuntu6.6` was cross-built with the
MPSS 3.4.10 K1OM GCC 4.7 toolchain. The resulting core executables are ELF64
Intel K1OM (`EM_K1OM`, machine 181) and depend only on `libc.so.6` because
Ubuntu Noble `libmd` 1.1.0 was linked statically.

The following real dpkg programs built:

- `dpkg`
- `dpkg-deb`
- `dpkg-query`
- `dpkg-divert`
- `dpkg-split`
- `dpkg-statoverride`
- `dpkg-trigger`
- `update-alternatives`

The build is installed side-by-side under
`/opt/xeon-phi-revival/dpkg-real`. It does not replace the project bootstrap
`/usr/bin/dpkg` command.

## Verified On Card

On the Intel Xeon Phi 5110P:

```text
dpkg --version -> 1.22.6 (k1om)
dpkg --print-architecture -> k1om
dpkg-query -W xpr-pci-tools -> xpr-pci-tools 0.1.0
dpkg --audit -> exit 0
dpkg-deb -I xpr-pci-tools_0.1.0_k1om.deb -> passed
dpkg-deb -c xpr-pci-tools_0.1.0_k1om.deb -> passed
```

A fresh database and root under `/tmp/xpr-real-dpkg-root-clean` then completed
a complete reversible transaction:

```text
Selecting previously unselected package xpr-pci-tools.
Preparing to unpack ...
Unpacking xpr-pci-tools (0.1.0) ...
Setting up xpr-pci-tools (0.1.0) ...
Status: install ok installed
```

The expected dependency warnings were retained because the isolated test used
`--force-depends` and intentionally started with an empty database.

A second clean database installed all 36 packages from the project archive,
configured every package, reported 36 installed records, and passed
`dpkg --audit`.

## Port Changes

The target port requires one real dpkg architecture row:

```text
k1om  k1om  k1om  64  little
```

The generic `base-gnu-linux-<cpu> -> <cpu>` tuple mapping already maps this to
the public Debian architecture name `k1om`.

The CentOS 7.4-era build host also needs narrowly scoped Perl 5.16
compatibility changes for build-time scripts. These changes are not target
runtime requirements and are tracked separately from the K1OM architecture
patch.

## Runtime Compatibility

MPSS provides BusyBox 1.19 `tar`, while dpkg invokes GNU tar with `-m` and
`--warning=no-timestamp`. A side-by-side wrapper removes only those unsupported
metadata flags and delegates to `/bin/tar`. This is sufficient for metadata,
contents, unpack, and configure tests of the project's current packages.

GNU tar should eventually replace this compatibility wrapper.

## Migration Boundary

The bootstrap shim's `/var/lib/dpkg/info/*.list` files can contain blank
entries. Real dpkg correctly rejects at least one of those files. Before real
dpkg becomes `/usr/bin/dpkg`, the project must regenerate all file lists from
the package archive into a clean real-dpkg database and verify ownership,
dependencies, and conffile metadata.

The current build has optional compression libraries disabled. Existing
project packages still work through dpkg's subprocess path, but a production
port should build zlib, bzip2, xz, and zstd support and port GNU tar.

## Reproduction

Public tooling and patches:

```text
tools/ubuntu-port/build-dpkg-k1om.sh
ubuntu-port/k1om/patches/dpkg-1.22.6-k1om.patch
ubuntu-port/k1om/patches/dpkg-1.22.6-perl516-build-host.patch
```

Private run:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/dpkg-real-k1om-20260729-191253
/root/xeon-phi-revival-local/ubuntu-port-runs/dpkg-real-k1om-repro-20260729-193803
```

No Ubuntu source archives, Intel sysroots, Intel runtime files, or generated
target binaries are committed.
