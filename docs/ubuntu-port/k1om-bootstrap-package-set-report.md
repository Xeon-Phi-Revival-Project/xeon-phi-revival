# K1OM Bootstrap Package Set Report

Public-safe report for the first multi-package K1OM bootstrap archive.

## Status

Status: passed.

This is not a complete Ubuntu port. It proves that the project can build a
small set of local `Architecture: k1om` packages, index them into a Noble-style
`binary-k1om` archive, install them into MPSS MicDir staging, boot `mic0`, run
basic userland and OS smoke checks, expose dpkg-style package metadata on-card,
and roll back to the stock uOS.

## Package Set

```text
base-files-k1om_0.1.0_k1om.deb
hello-knc-smoke_0.1.0_k1om.deb
python3.5-minimal-k1om_0.1.0_k1om.deb
python3.5-stdlib-k1om_0.1.0_k1om.deb
python3.5-lib-dynload-k1om_0.1.0_k1om.deb
python3.5-smoke-k1om_0.1.0_k1om.deb
xpr-shell-compat_0.1.0_k1om.deb
xpr-busybox-compat_0.1.0_k1om.deb
xpr-pci-tools_0.1.0_k1om.deb
zlib-smoke-k1om_0.1.0_k1om.deb
libtinfo5-k1om_0.1.0_k1om.deb
ncurses-smoke-k1om_0.1.0_k1om.deb
xpr-os-smoke_0.1.0_k1om.deb
xeon-phi-revival-stage2_0.1.0_k1om.deb
```

The packages are `.deb`-structured artifacts built from:

```text
debian-binary
control.tar.gz
data.tar.gz
```

The generated packages are not committed because they include locally supplied
K1OM binaries, Python payload files, and runtime material.

## Private Run

Final Ubuntu-style deterministic, audited, simulated, live passing, and
rollback-verified run:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-230659
```

The same fourteen-package profile was then booted again and intentionally left
active for SSH inspection:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-231941
rollback: /root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-231941/rollback-stock.sh
```

Stock baseline:

```text
/etc/mpss/mic0.conf sha256 c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9
mic0: online
mpss.service: active
```

## Package Hashes

```text
base-files-k1om     fbfad5560b505fae7f7d1977a0b8e9a00408c1ce1b0bc8d76d60ec514913bc5d
hello-knc-smoke     30af9c5556b59abe25fd009adc6af3c8b9461182e13f347d4debd5ea9c87f92b
python3.5-minimal-k1om 8b7108c2caa40b18a911d91c0b0790d3ac4588caddfc06bd658ce68d8e169abc
python3.5-stdlib-k1om 8cabe59ea27bcb003665064f02613fd647457da40b8131720ab5d7f97f0d966a
python3.5-lib-dynload-k1om 4e7f459404480f0ae66318adbead04fc22bb490714a62da0985cb7dc5a6546d7
python3.5-smoke-k1om 50871fc9031cd0e7904a4861601c1b05a22e349fc3c4a3fbec34f60bdabcbb6a
xpr-shell-compat a1edfde8a484b1a809d0f17a25d38acdd74e340d17bf0a0b65ef51a876c25121
xpr-busybox-compat 7c2fae933becc268649e59af18935945a0d2097cb86bc4b0e1dd49746d883475
xpr-pci-tools      5af084cbb54c5d536cb4bd54dfc9b9b2125f95f3427a7a49fa1a0e4e94e6aef3
zlib-smoke-k1om     46aab001aba64cfd10a50b2de7d06a72c4fe26b63d4acb399252661cee14c30e
libtinfo5-k1om      92cefe76971dbd55222c4926fd762bd41df734657b88d5671823e3bf197f7f48
ncurses-smoke-k1om  c39533a3a70d23f465e30133ed0714b8cf8f9540e03b5f7314c7ea5fe921e355
xpr-os-smoke        b6e165ea5d93b1f8b63f8c2ae2da7d395178e320481233d5dc839d34cc976c16
xeon-phi-revival-stage2 255a4f061f57bb6d077217fbeea4ad6b1824f9d972c6d966efe20cd223e53782
```

The package determinism check passed before archive indexing:

```text
status=passed
source_date_epoch=1704067200
package_count=14
checks=same_package_names,same_sha256
details=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-230659/determinism/package-determinism.tsv
```

## Archive Metadata

The local private archive generated:

```text
dists/noble/Release
dists/noble/main/binary-k1om/Packages
dists/noble/main/binary-k1om/Packages.gz
pool/main/*/*/*.deb
```

The `Packages` file recorded all fourteen package names with:

```text
Version: 0.1.0
Architecture: k1om
Filename: pool/main/...
MD5sum: ...
SHA1: ...
SHA256: ...
```

The `Release` file records deterministic `Date`, `MD5Sum`, `SHA1`, and
`SHA256` blocks for both `Packages` and `Packages.gz`.

The package audit passed before installation:

```text
status=passed
package_count=14
checks=release_suite,release_codename,release_architecture,release_hash_blocks,release_packages_hashes,packages_gz_matches_packages,package_source,package_architecture,package_section,package_priority,package_md5sums,packages_filename,packages_md5sum,packages_sha1,packages_sha256,dependencies_satisfied,no_duplicate_paths
ownership_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-230659/audit/package-ownership.tsv
deps_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-230659/audit/package-dependencies.tsv
hash_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-230659/audit/package-hashes.tsv
```

The install simulation also passed before live install:

```text
status=passed
package_count=14
rootfs=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-230659/simulated-install/rootfs
dpkg_status=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260728-230659/simulated-install/rootfs/var/lib/dpkg/status
checks=dependency_order,extract_payloads,dpkg_status,package_file_lists,package_md5sums,package_conffiles,required_bootstrap_paths
```

## Live Result

Observed on `mic0` during the package-set boot:

```text
package_set_ssh_ok
pid1=init
NAME="Xeon Phi Revival Project uOS Profile"
VERSION="0.1.0"
ARCH="k1om"
BASE="stock MPSS uOS"
XPR_PROFILE_KIND=stock-init-handoff-second-stage
XPR_PHASE=bootstrap
dpkg_status_present
14
/bin/ls
/bin/cat
/bin/grep
/bin/sed
/usr/bin/awk
/usr/bin/find
/usr/bin/python3
/usr/bin/python
/usr/bin/pcietool
Abc
3
pcietool_rc=0
python3_plain_rc=0
python_plain_rc=0
```

Second-stage service result:

```text
hello_rc=0
python_rc=0
zlib_rc=0
ncurses_rc=0
os_smoke_rc=0
```

K1OM hello result:

```text
hello from knc
machine=k1om
sizeof(void*)=8
sizeof(long)=8
```

Python result:

```text
python stage2 demo ok
platform=linux
prefix=/opt/xeon-phi-revival
calc=45
```

Zlib result:

```text
zlib version=1.3 result=knc zlib smoke
```

Ncurses result:

```text
ncurses version=ncurses 6.4.20240113
```

## Command and PCI Tooling

The `xpr-busybox-compat` package exposes common BusyBox-backed command
entrypoints under `/opt/xeon-phi-revival/bin`. The live run verified `cat`,
`grep`, `sed`, `awk`, and `find` in addition to the existing `ls`,
`python3`, and `python` entrypoints.

The `xpr-pci-tools` package installs `/usr/bin/pcietool` and a matching
profile-bin symlink. `pcietool list` returned exit code `0` on `mic0`. The
captured output file was empty in this run, so the current result proves the
tool installs and executes but does not yet prove visible PCI device inventory
from inside the card uOS.

## Basic OS Smoke

The `xpr-os-smoke` package verified:

```text
os_smoke_started=1
pid1=init
cwd=/
proc_mount=none /proc proc rw,relatime 0 0
sys_mount=sysfs /sys sysfs rw,relatime 0 0
dev_mount=none /dev tmpfs rw,relatime,mode=755 0 0
tmp_write_test
/tmp/xeon-phi-revival-os-smoke/nested/a/file.txt
/tmp/xeon-phi-revival-os-smoke/write-test.link
/tmp/xeon-phi-revival-os-smoke/write-test.txt
mic0: inet 172.31.1.1/24
os_smoke_done=1
```

This confirms usable `/proc`, `/sys`, `/dev`, writable `/tmp`, symlink
creation, nested directory/file creation, root filesystem inspection, basic
filesystem capacity reporting, card network interface visibility, and service
environment capture.

## Rollback

The runner restored the MicDir overlay and booted stock uOS afterward.

Independent final verification:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
mpss.service active
/etc/mpss/mic0.conf sha256 c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9
final_stock_ok
profile_absent
stage2_log_absent
dpkg_status_absent
pcietool_absent
init
```

## Tools

```text
tools/ubuntu-port/build-k1om-bootstrap-packages.sh
tools/ubuntu-port/check-k1om-package-determinism.sh
tools/ubuntu-port/index-k1om-local-archive.sh
tools/ubuntu-port/audit-k1om-package-set.sh
tools/ubuntu-port/simulate-k1om-package-install.sh
tools/ubuntu-port/install-k1om-profile-deb-to-micdir.sh
tools/ubuntu-port/run-k1om-bootstrap-package-set-experiment.sh
```

## Meaning

The true Ubuntu architecture-port lane now has a working package/archive test
spine:

```text
multiple deterministic k1om package recipes -> local Noble binary-k1om archive with Packages/Packages.gz -> package audit -> simulated dpkg-style install/rootfs -> MicDir install -> boot -> hello/Python/OS smoke -> stock rollback
```

The narrowest next dependency is expanding from smoke payload packages toward
real library/runtime packages with clearer ownership boundaries. `libtinfo5`
has been split out, Python is now separated into interpreter, standard-library,
dynamic-extension, and smoke-script packages, and `xpr-shell-compat` now exposes
basic interactive command entrypoints. `xpr-busybox-compat` adds common command
applets, and `xpr-pci-tools` is the first small project utility package. The
next useful split is turning more smoke payload dependencies into standalone
library/runtime packages, starting with a real shared `libz` package rather
than only the current zlib smoke binary.
