# K1OM Bootstrap Package Set Report

Public-safe report for the first multi-package K1OM bootstrap archive.

## Status

Status: passed.

This is not a complete Ubuntu port. It proves that the project can build a
small set of local `Architecture: k1om` packages, index them into a Noble-style
`binary-k1om` archive, install them into MPSS MicDir staging, boot `mic0`, run
basic userland and OS smoke checks, expose dpkg-style package metadata on-card,
run project `dpkg`/`apt-get`/`apt-cache` commands against the local archive,
test a packaged libc stack, and roll back to the stock uOS.

## Package Set

```text
apt-k1om_0.1.0_k1om.deb
base-files-k1om_0.1.0_k1om.deb
dpkg-k1om_0.1.0_k1om.deb
hello-knc-smoke_0.1.0_k1om.deb
libc6-k1om_0.1.0_k1om.deb
libc-stack-smoke-k1om_0.1.0_k1om.deb
libdl2-k1om_0.1.0_k1om.deb
libgcc1-k1om_0.1.0_k1om.deb
libm6-k1om_0.1.0_k1om.deb
libpthread0-k1om_0.1.0_k1om.deb
librt1-k1om_0.1.0_k1om.deb
libtinfo5-k1om_0.1.0_k1om.deb
libutil1-k1om_0.1.0_k1om.deb
ncurses-smoke-k1om_0.1.0_k1om.deb
python3.5-minimal-k1om_0.1.0_k1om.deb
python3.5-stdlib-k1om_0.1.0_k1om.deb
python3.5-lib-dynload-k1om_0.1.0_k1om.deb
python3.5-smoke-k1om_0.1.0_k1om.deb
xpr-shell-compat_0.1.0_k1om.deb
xpr-busybox-compat_0.1.0_k1om.deb
zlib-smoke-k1om_0.1.0_k1om.deb
xpr-pci-tools_0.1.0_k1om.deb
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
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356
```

Stock baseline:

```text
/etc/mpss/mic0.conf sha256 c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9
mic0: online
mpss.service: active
```

## Package Hashes

```text
apt-k1om          779cd2043086cd5c913679c0e88075d9ae7940ad734e4ce3eeb27f83d93f0664
base-files-k1om     fbfad5560b505fae7f7d1977a0b8e9a00408c1ce1b0bc8d76d60ec514913bc5d
dpkg-k1om         ed0e589fa7616d57a76f4602f6fb644a1c4aaa75623827afcf9cf7be163f3dd2
hello-knc-smoke     30af9c5556b59abe25fd009adc6af3c8b9461182e13f347d4debd5ea9c87f92b
libc6-k1om        38ec691a040315b6c325f0812a1f98a4cc884f3ac0e77bae08591e909cc338fd
libc-stack-smoke-k1om 77f1310da8db079dbdfad7175ec4c4d673ed973c316fef9c10ff4323a89289bb
libdl2-k1om       db6dfd4dbdd9573cbb860568810e51686e9bcebbfe96237aeb24f894d9290d1e
libgcc1-k1om      62a2c6b3fe4656d56242db879503c71f7ffbd2e0668cb2d0690f0fa406bf6683
libm6-k1om        124e465b94c00c1b7d11e17cf736144e3a708d0e02dd4e1ff503dd8418879b16
libpthread0-k1om  3d94d016dff72dadc9a782102e926f95ef66f671c6bafd027345705a955b3f7a
librt1-k1om       015b68bf011cc10e33d796e4ac053994c3bbbfcf4e31f89632a0fe9e11602b96
libutil1-k1om     20ed872831f4197baa598844cd5d5981d84faae48adcaff6a3593e4a1c4d87ed
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
xeon-phi-revival-stage2 240c486ab1a8e66b7a84bf3c1c3f1b71b585f36c39621356f9123a2673c8fb1d
```

The package determinism check passed before archive indexing:

```text
status=passed
source_date_epoch=1704067200
package_count=24
checks=same_package_names,same_sha256
details=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356/determinism/package-determinism.tsv
```

## Archive Metadata

The local private archive generated:

```text
dists/noble/Release
dists/noble/main/binary-k1om/Packages
dists/noble/main/binary-k1om/Packages.gz
pool/main/*/*/*.deb
```

The `Packages` file recorded all twenty-four package names with:

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
package_count=24
checks=release_suite,release_codename,release_architecture,release_hash_blocks,release_packages_hashes,packages_gz_matches_packages,package_source,package_architecture,package_section,package_priority,package_md5sums,packages_filename,packages_md5sum,packages_sha1,packages_sha256,dependencies_satisfied,no_duplicate_paths
ownership_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356/audit/package-ownership.tsv
deps_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356/audit/package-dependencies.tsv
hash_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356/audit/package-hashes.tsv
```

The install simulation also passed before live install:

```text
status=passed
package_count=24
rootfs=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356/simulated-install/rootfs
dpkg_status=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-000356/simulated-install/rootfs/var/lib/dpkg/status
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
24
/usr/bin/dpkg
/usr/bin/apt-get
/usr/bin/apt-cache
Debian dpkg bootstrap-compatible project implementation for k1om 0.1.0
apt-get bootstrap-compatible project implementation for k1om 0.1.0
apt-cache bootstrap-compatible project implementation for k1om 0.1.0
apt_update_rc=0
apt_install_rc=0
loader_present
libc_present
hello_loader_direct_rc=0
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
libc_stack_rc=0
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

Packaged libc-stack result:

```text
libc_stack_started=1
loader=/opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2
hello_loader_rc=0
python_libc_stack_ok
python_loader_rc=0
libc_stack_done=1
```

## Package Manager Shim

The `dpkg-k1om` package installs a project bootstrap-compatible `dpkg`
implementation at `/usr/bin/dpkg`. During the live run it reported package
status, listed package files, and installed packages from local `.deb`
artifacts. The `apt-k1om` package installs project `apt-get` and `apt-cache`
shims at `/usr/bin/apt-get` and `/usr/bin/apt-cache`, with a local
`file:/opt/xeon-phi-revival/repo noble main` source list.

The live run verified:

```text
dpkg -l | grep xpr-pci-tools
dpkg -s xpr-pci-tools -> Status: install ok installed
dpkg -L xpr-pci-tools -> /usr/bin/pcietool
apt-get update -> apt_update_rc=0
apt-cache show xpr-pci-tools -> Architecture: k1om
apt-get install --reinstall xpr-pci-tools -> apt_install_rc=0
```

These tools are intentionally minimal project shims, not a complete Debian
`dpkg`/APT implementation.

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
dpkg_absent
apt_get_absent
apt_cache_absent
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

The narrowest next dependency has moved from package/archive mechanics to
manager compatibility and larger userland staging. `dpkg-k1om` and `apt-k1om`
prove basic package-manager commands can exist and operate on-card, but they
are intentionally small shims. The libc runtime stack is now split into
standalone packages under the project prefix. The next useful work is making
the package-manager behavior stricter, then packaging additional Ubuntu-source
libraries and a smaller Python 3.12 runtime in a way that does not destabilize
MPSS boot.
