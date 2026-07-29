# K1OM APT Sandbox Report

Public-safe report for the first host-side APT parser test of the local K1OM
archive.

## Status

Status: passed.

This was a harmless offline APT test. It did not install packages, execute K1OM
payloads, modify system APT state, touch `mic0`, or change MPSS configuration.

## Input

The test used metadata copied from the current package-manager/libc package set
run:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356/repo
```

The private archive was copied into an ignored local scratch directory:

```text
build/private/k1om-apt-repo-20260729-000356
```

The scratch directory is not committed.

## Tool

```text
tools/ubuntu-port/test-k1om-archive-with-apt.sh
```

The tool creates a private APT root with its own source list, state directory,
list directory, and cache directory. It forces:

```text
APT::Architecture=k1om
APT::Architectures::=k1om
```

The source is a local trusted `file:` repository:

```text
deb [trusted=yes arch=k1om] file:... noble main
```

## Result

Run output:

```text
status=passed
checks=apt_get_update_file_repo,architecture_k1om,packages_visible,apt_cache_show
```

APT read:

```text
dists/noble/Release
dists/noble/main/binary-k1om/Packages.gz
```

`apt-cache show base-files-k1om` reported:

```text
Package: base-files-k1om
Source: xeon-phi-revival-bootstrap
Version: 0.1.0
Architecture: k1om
Section: base
Priority: optional
Filename: pool/main/b/base-files-k1om/base-files-k1om_0.1.0_k1om.deb
SHA256: fbfad5560b505fae7f7d1977a0b8e9a00408c1ce1b0bc8d76d60ec514913bc5d
```

## Meaning

APT can parse the project archive as a local `noble/main/binary-k1om` repository
when forced to use `k1om` as the architecture. This does not mean the packages
can be installed by a real K1OM `dpkg` on-card yet. It does mean the repository
metadata is close enough for host-side APT index tests.

The passing archive currently contains twenty-four packages:

```text
apt-k1om
base-files-k1om
dpkg-k1om
hello-knc-smoke
libc6-k1om
libc-stack-smoke-k1om
libdl2-k1om
libgcc1-k1om
libm6-k1om
libpthread0-k1om
librt1-k1om
libtinfo5-k1om
libutil1-k1om
ncurses-smoke-k1om
python3.5-minimal-k1om
python3.5-stdlib-k1om
python3.5-lib-dynload-k1om
python3.5-smoke-k1om
xpr-shell-compat
xpr-busybox-compat
zlib-smoke-k1om
xpr-pci-tools
xpr-os-smoke
xeon-phi-revival-stage2
```

## Next Dependency

Expand the package set toward a larger K1OM rootfs while keeping the same gates:

```text
deterministic package build
APT parser test
package audit
simulated dpkg-style install
MicDir boot smoke
stock rollback
```
