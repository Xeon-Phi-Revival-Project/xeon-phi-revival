# Installing MPSS 3.4.10 For XPR-OS

XPR-OS RC6 uses the Intel MPSS host driver and `micctrl` boot mechanism. MPSS
is a separate Intel product and is **not** included in this repository or the
RC6 release. Obtain it yourself and accept its license before installing it.

This page documents the tested MPSS generation: **3.4.10** on a CentOS 7-era
host. The project-tested host was CentOS 7.4. The MPSS host driver must match
your running host kernel; do not install a module RPM built for a different
kernel release.

## 1. Inspect The Installer First

On the **host**, unpack your separately obtained MPSS 3.4.10 distribution:

```bash
mkdir -p ~/mpss-install
tar -xf /path/to/mpss-3.4.10-linux.tar -C ~/mpss-install
cd ~/mpss-install/mpss-3.4.10
less docs/license.txt
uname -r
find modules -maxdepth 1 -type f -name 'mpss-modules-*.rpm' -printf '%f\n'
```

Choose the `mpss-modules-...rpm` file whose kernel-release portion matches
`uname -r` exactly. If no matching module package exists, stop here. Booting
XPR-OS requires a working MPSS host driver; do not force-install a mismatched
kernel module.

## 2. Dry-Run The Core Package Install

The MPSS 3.4.10 archive contains the host core, daemon, management tools, boot
files, SCIF library, license package, and a kernel-matched host driver. Define
the matching driver explicitly:

```bash
cd ~/mpss-install/mpss-3.4.10
driver_rpm=modules/mpss-modules-<your-running-kernel>-3.4.10-1.x86_64.rpm

sudo rpm -Uvh --test \
  mpss-license-3.4.10-1.glibc2.12.x86_64.rpm \
  libscif0-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-core-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-daemon-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-micmgmt-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-boot-files-3.4.10-1.glibc2.12.x86_64.rpm \
  "$driver_rpm"
```

Replace only the placeholder in `driver_rpm`; do not copy a kernel version from
an example. Resolve dependency errors using your supported CentOS-era package
sources before doing the real installation.

## 3. Install And Start MPSS

After the dry run succeeds, repeat the command without `--test`:

```bash
sudo rpm -Uvh \
  mpss-license-3.4.10-1.glibc2.12.x86_64.rpm \
  libscif0-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-core-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-daemon-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-micmgmt-3.4.10-1.glibc2.12.x86_64.rpm \
  mpss-boot-files-3.4.10-1.glibc2.12.x86_64.rpm \
  "$driver_rpm"

sudo systemctl enable --now mpss
micctrl --status
micinfo
```

Expected result: `mic0: online`. Then check stock card SSH:

```bash
ssh mic0 'uname -m; cat /proc/1/comm'
```

Expected result: `k1om` and `init`. Only proceed to XPR-OS after this baseline
works. For optional K1OM compiler work, see the separate
[SDK preinstallation report](../toolchain/mpss-sdk-k1om-3.4.10-preinstall-report.md).

