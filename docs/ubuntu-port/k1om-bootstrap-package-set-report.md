# K1OM Bootstrap Package Set Report

Public-safe report for the first multi-package K1OM bootstrap archive.

## Status

Status: passed.

This is not a complete Ubuntu port. It proves that the project can build a
small set of local `Architecture: k1om` packages, index them into a Noble-style
`binary-k1om` archive, install them into MPSS MicDir staging, boot `mic0`, run
basic userland and OS smoke checks, expose dpkg-style package metadata on-card,
run project `dpkg`/`apt-get`/`apt-cache` commands against the local archive,
test packaged libc and runtime-library stacks, and roll back to the stock uOS.
It now also packages and runs a CPython 3.12.13 runtime distribution for K1OM.
The latest passing run adds OpenSSL-backed Python 3.12 modules and a packaged
`linux` terminfo entry for fuller curses initialization.

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
libcrypto1.0.0-k1om_0.1.0_k1om.deb
libncurses5-k1om_0.1.0_k1om.deb
libpthread0-k1om_0.1.0_k1om.deb
libreadline6-k1om_0.1.0_k1om.deb
librt1-k1om_0.1.0_k1om.deb
libssl1.0.0-k1om_0.1.0_k1om.deb
libtinfo5-k1om_0.1.0_k1om.deb
libutil1-k1om_0.1.0_k1om.deb
ncurses-base-k1om_0.1.0_k1om.deb
ncurses-smoke-k1om_0.1.0_k1om.deb
python3.5-minimal-k1om_0.1.0_k1om.deb
python3.5-stdlib-k1om_0.1.0_k1om.deb
python3.5-lib-dynload-k1om_0.1.0_k1om.deb
python3.5-smoke-k1om_0.1.0_k1om.deb
python3.12-minimal-k1om_0.1.0_k1om.deb
python3.12-stdlib-k1om_0.1.0_k1om.deb
python3.12-sysconfig-k1om_0.1.0_k1om.deb
python3.12-smoke-k1om_0.1.0_k1om.deb
xpr-shell-compat_0.1.0_k1om.deb
xpr-busybox-compat_0.1.0_k1om.deb
xpr-runtime-libs-smoke_0.1.0_k1om.deb
zlib1g-k1om_0.1.0_k1om.deb
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
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525
```

Stock baseline:

```text
/etc/mpss/mic0.conf sha256 c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9
mic0: online
mpss.service: active
```

## Package Hashes

```text
apt-k1om          c72d4eb37322c028c91d237a60e0854b7053fddfa095b44b839956982cc2daca
base-files-k1om     fbfad5560b505fae7f7d1977a0b8e9a00408c1ce1b0bc8d76d60ec514913bc5d
dpkg-k1om         b6d1cffddb401f24f493c6f246bf47e3e656f6be19477304f68780886dc8b275
hello-knc-smoke     30af9c5556b59abe25fd009adc6af3c8b9461182e13f347d4debd5ea9c87f92b
libc6-k1om        38ec691a040315b6c325f0812a1f98a4cc884f3ac0e77bae08591e909cc338fd
libc-stack-smoke-k1om 77f1310da8db079dbdfad7175ec4c4d673ed973c316fef9c10ff4323a89289bb
libdl2-k1om       db6dfd4dbdd9573cbb860568810e51686e9bcebbfe96237aeb24f894d9290d1e
libgcc1-k1om      62a2c6b3fe4656d56242db879503c71f7ffbd2e0668cb2d0690f0fa406bf6683
libm6-k1om        124e465b94c00c1b7d11e17cf736144e3a708d0e02dd4e1ff503dd8418879b16
libcrypto1.0.0-k1om fb662e4d6ee1ea09b8efcf68d7cd242273283f86f41d5b6a864055d69b8fe895
libncurses5-k1om  e54379c5bc4ed7ff260910f17b83b5d653a41294591aa43607182dc7de83d208
libpthread0-k1om  3d94d016dff72dadc9a782102e926f95ef66f671c6bafd027345705a955b3f7a
libreadline6-k1om 9ea7cc83ab1413fa4658d4b6e8c843236029aac9e84f961bb58ff735953f0387
librt1-k1om       015b68bf011cc10e33d796e4ac053994c3bbbfcf4e31f89632a0fe9e11602b96
libssl1.0.0-k1om  497740826ec5b10ed2dd9aefc75a9911b1dcd91087daec163e85a1bbba125c25
libutil1-k1om     20ed872831f4197baa598844cd5d5981d84faae48adcaff6a3593e4a1c4d87ed
ncurses-base-k1om 95695440dfe33e967ee9663a5702b80788957f5925094c5c4117577e3df7edf2
python3.5-minimal-k1om 8b7108c2caa40b18a911d91c0b0790d3ac4588caddfc06bd658ce68d8e169abc
python3.5-stdlib-k1om 8cabe59ea27bcb003665064f02613fd647457da40b8131720ab5d7f97f0d966a
python3.5-lib-dynload-k1om 4e7f459404480f0ae66318adbead04fc22bb490714a62da0985cb7dc5a6546d7
python3.5-smoke-k1om 50871fc9031cd0e7904a4861601c1b05a22e349fc3c4a3fbec34f60bdabcbb6a
python3.12-minimal-k1om b81642440a0527df52fa94bcae9141c1c05557112d21c3962284fb10c4b9be33
python3.12-stdlib-k1om 9849c3250f311bd66ac5f7033de88f5b875b1ec6c2ece0f0dc54725ae19b2569
python3.12-sysconfig-k1om e1d32c6d8c55f496f609b9356c293a1b6c34789a029eb52c920179760d43fe6a
python3.12-smoke-k1om 6f7dddf602875f03ed999a97b64fc2b2766c26e4390c4ac56fabe5700f2a4db1
xpr-shell-compat a1edfde8a484b1a809d0f17a25d38acdd74e340d17bf0a0b65ef51a876c25121
xpr-busybox-compat 7c2fae933becc268649e59af18935945a0d2097cb86bc4b0e1dd49746d883475
xpr-pci-tools      5af084cbb54c5d536cb4bd54dfc9b9b2125f95f3427a7a49fa1a0e4e94e6aef3
zlib1g-k1om       efd3a71e79e0efb0c0e79709161003a7338f2f6e36d4e707c51a4efbc158f024
xpr-runtime-libs-smoke fe656b015558f212c22f0cd76da90094b4e4ebe3a999ce971d75086d8ef3a0be
zlib-smoke-k1om     168b43a08e4d879a7381ef308a7d152bf4541d42662aff1b3e4d33604d2a17e5
libtinfo5-k1om      92cefe76971dbd55222c4926fd762bd41df734657b88d5671823e3bf197f7f48
ncurses-smoke-k1om  0b6fc8272391f3740e82c056b3e4f4c677f81d1af324394888faa2dca00e7a6a
xpr-os-smoke        b6e165ea5d93b1f8b63f8c2ae2da7d395178e320481233d5dc839d34cc976c16
xeon-phi-revival-stage2 3d6478a9a0a0c620a0b2fe312e5b386b344730e96790112cabff4fec2f216bc1
```

The package determinism check passed before archive indexing:

```text
status=passed
source_date_epoch=1704067200
package_count=35
checks=same_package_names,same_sha256
details=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525/determinism/package-determinism.tsv
```

## Archive Metadata

The local private archive generated:

```text
dists/noble/Release
dists/noble/main/binary-k1om/Packages
dists/noble/main/binary-k1om/Packages.gz
pool/main/*/*/*.deb
```

The `Packages` file recorded all thirty-five package names with:

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
package_count=35
checks=release_suite,release_codename,release_architecture,release_hash_blocks,release_packages_hashes,packages_gz_matches_packages,package_source,package_architecture,package_section,package_priority,package_md5sums,packages_filename,packages_md5sum,packages_sha1,packages_sha256,dependencies_satisfied,no_duplicate_paths
ownership_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525/audit/package-ownership.tsv
deps_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525/audit/package-dependencies.tsv
hash_file=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525/audit/package-hashes.tsv
```

The install simulation also passed before live install:

```text
status=passed
package_count=35
rootfs=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525/simulated-install/rootfs
dpkg_status=/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525/simulated-install/rootfs/var/lib/dpkg/status
checks=dependency_order,extract_payloads,dpkg_status,package_file_lists,package_md5sums,package_conffiles,required_bootstrap_paths,dpkg_deb_entrypoint
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
35
/usr/bin/dpkg
/usr/bin/dpkg-query
/usr/bin/dpkg-deb
/usr/bin/apt-get
/usr/bin/apt-cache
Debian dpkg bootstrap-compatible project implementation for k1om 0.1.0
Debian dpkg-deb bootstrap-compatible project implementation for k1om 0.1.0
apt-get bootstrap-compatible project implementation for k1om 0.1.0
apt-cache bootstrap-compatible project implementation for k1om 0.1.0
dpkg_audit_rc=0
apt_update_rc=0
apt_install_rc=0
loader_present
libc_present
libz_present
libncurses_present
libreadline_present
libssl_present
libcrypto_present
hello_loader_direct_rc=0
/bin/ls
/bin/cat
/bin/grep
/bin/sed
/usr/bin/awk
/usr/bin/find
/usr/bin/python3
/usr/bin/python
/usr/bin/python3.12
/usr/bin/pcietool
Abc
3
pcietool_rc=0
python3_plain_rc=0
python_plain_rc=0
python312_version_rc=0
python312_direct_rc=0
```

Second-stage service result:

```text
hello_rc=0
python_rc=0
zlib_rc=0
ncurses_rc=0
libc_stack_rc=0
runtime_libs_rc=0
python312_rc=0
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

Python 3.12 package result:

```text
/usr/bin/python3.12
3.12.13
python312_package_smoke_ok
linux
k1om
knc-zlib
cpython-312-k1om-linux-gnu
bz2=bz-ok
lzma=lzma-ok
readline=True
sqlite3=42:3.45.1
curses=2.2
curses_panel=True
curses_cols=80
curses_lines=24/25
ssl=OpenSSL 3.0.13 30 Jan 2024
hashlib_openssl=2d711642
ctypes=skipped
python312_direct_rc=0
python312_rc=0
```

The Python 3.12 smoke exercised:

```text
array
asyncio import
binascii
contextvars
csv
datetime
decimal
hashlib.sha256
json
math
pathlib
pickle
queue
random
readline
socket
sqlite3
statistics
struct
sysconfig
threading
unicodedata
xml.etree.ElementTree
xml.parsers.expat
bz2
curses
curses.panel
lzma
zlib
zoneinfo
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

Packaged runtime-library result:

```text
runtime_libs_started=1
present=libz.so.1
present=libz.so.1.2.6
present=libncurses.so.5
present=libncurses.so.5.9
present=libtinfo.so.5
present=libreadline.so.6
present=libreadline.so.6.2
present=libssl.so.1.0.0
present=libcrypto.so.1.0.0
runtime_libs_done=1
```

## Package Manager Shim

The `dpkg-k1om` package installs a project bootstrap-compatible `dpkg`
implementation at `/usr/bin/dpkg`. During the live run it reported package
status, listed package files, and installed packages from local `.deb`
artifacts. The `apt-k1om` package installs project `apt-get` and `apt-cache`
shims at `/usr/bin/apt-get` and `/usr/bin/apt-cache`, with a local
`file:/opt/xeon-phi-revival/repo noble main` source list.

The final package-set run also verified `dpkg-deb`, `dpkg --audit`,
`dpkg --get-selections`, `apt-cache pkgnames`, `apt-cache depends`,
`apt-cache search`, and `apt-get download`.

The live run verified:

```text
dpkg -l | grep xpr-pci-tools
dpkg -s xpr-pci-tools -> Status: install ok installed
dpkg -L xpr-pci-tools -> /usr/bin/pcietool
dpkg --audit -> dpkg_audit_rc=0
dpkg --get-selections -> xpr-pci-tools install
dpkg-deb -f xpr-pci-tools_0.1.0_k1om.deb Package -> xpr-pci-tools
dpkg-deb -c xpr-pci-tools_0.1.0_k1om.deb -> /usr/bin/pcietool
apt-get update -> apt_update_rc=0
apt-cache show xpr-pci-tools -> Architecture: k1om
apt-cache pkgnames python3.12 -> python3.12-minimal-k1om
apt-cache depends python3.12-smoke-k1om -> python3.12-minimal-k1om
apt-cache search pci -> xpr-pci-tools
apt-get download xpr-pci-tools -> xpr-pci-tools_0.1.0_k1om.deb
apt-get install --reinstall xpr-pci-tools -> apt_install_rc=0
apt-get install --reinstall xpr-runtime-libs-smoke -> apt_runtime_install_rc=0
apt-get install --reinstall python3.12-smoke-k1om -> apt_python312_install_rc=0
```

These tools are intentionally minimal project shims, not a complete Debian
`dpkg`/APT implementation.

## Minimal Ubuntu-Shaped Rootfs

The package simulation can now be assembled into a private minimal
Ubuntu-shaped rootfs:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-minimal-rootfs-toolcheck-20260729-174425/minimal-rootfs/rootfs
```

The validation passed for Ubuntu identity files, `/etc/apt/sources.list`,
`/var/lib/dpkg/status`, `/bin/sh`, `/bin/ls`, `/usr/bin/python3`,
`/usr/bin/python3.12`, `dpkg`, `dpkg-query`, `dpkg-deb`, `apt-get`,
`apt-cache`, `pcietool`, required device nodes, `/proc`, `/sys`, symlink
integrity, and ELF machine checks. Every detected ELF in that private rootfs
validated as K1OM `e_machine=181`. The generated rootfs remains private because
it may contain locally supplied MPSS runtime payloads and K1OM binaries.

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
python312_absent
python312_bin_absent
python312_smoke_absent
pcietool_absent
dpkg_absent
apt_get_absent
dpkg_deb_absent
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
tools/ubuntu-port/build-k1om-minimal-ubuntu-rootfs.sh
tools/ubuntu-port/validate-k1om-minimal-ubuntu-rootfs.sh
tools/ubuntu-port/install-k1om-profile-deb-to-micdir.sh
tools/ubuntu-port/run-k1om-bootstrap-package-set-experiment.sh
```

## Meaning

The true Ubuntu architecture-port lane now has a working package/archive test
spine:

```text
multiple deterministic k1om package recipes -> local Noble binary-k1om archive with Packages/Packages.gz -> package audit -> simulated dpkg-style install/rootfs -> MicDir install -> boot -> hello/Python/OS smoke -> stock rollback
```

The current package lane now has a bootstrap Ubuntu-shaped Python distribution
for K1OM. `dpkg-k1om` and `apt-k1om` remain intentionally small project shims,
but the package/archive spine can now carry a modern CPython runtime through
deterministic package builds, archive indexing, audit, simulated install,
MicDir boot, live package-manager reinstall, and stock rollback.

The package set has since expanded to 36 packages with `libffi8-k1om`.
The real K1OM backend passes standalone `ffi_call`, floating-point, aggregate,
and closure tests. Packaged Python 3.12 passes `ctypes.CDLL(None).strlen(...)`
and `CFUNCTYPE` callbacks, and both generic `python3` and `python` commands now
select Python 3.12.13.

Python is no longer the narrowest dependency. The next boundary is replacing
the project dpkg/APT shims with real Ubuntu builds and resolving whether a
modern Ubuntu libc can support the stock MPSS 2.6.38 kernel. See
`docs/ubuntu-port/k1om-libffi-ctypes-report.md`.
