# Minimal Init Control Experiment

Status: live run blocked before custom init evidence.

This experiment is the smallest diagnostic step after the standalone
initramfs blocker. It is intended to distinguish an MPSS/kernel/initramfs
handoff problem from a dynamic BusyBox/eglibc/rootfs startup problem.

## Scope

The control image contains only:

- `/init`;
- `/sbin/init`;
- `/dev/console` and `/dev/null` when created by root;
- minimal empty directories.

It does not include BusyBox, Python, APT, dpkg, networking, SSH, Dropbear, the
full RC rootfs, stock `init.sysvinit`, or stock MPSS card-side userland.

## Init Source

The committed source is:

```text
src/uos/xpr_min_init.c
```

The program writes these fixed markers to stdout, stderr, `/dev/console`,
`/dev/hvc0`, and `/dev/ttyMIC0` if those paths can be opened:

```text
XPR_MIN_INIT_ENTERED
PID=1
XPR_MIN_INIT_IDLE
```

It then idles forever with a simple sleep loop.

## Build Script

```sh
tools/uos/build-minimal-k1om-initramfs.sh --source src/uos/xpr_min_init.c
```

The builder:

- sources the MPSS K1OM SDK environment if required;
- tries static K1OM linking first;
- falls back to a loader-minimal dynamic image only if static linking fails;
- verifies `Machine: Intel K1OM`;
- records the ELF interpreter and dynamic dependencies, if any;
- verifies `/init` and `/sbin/init` exist in the generated cpio;
- records compressed/uncompressed image size;
- emits SHA-256 and a complete manifest.

## Live Runner

```sh
tools/uos/run-minimal-k1om-initramfs-experiment.sh \
  --image <private-build-dir>/xpr-min-init.cpio.gz \
  --expected-conf-sha <sha256-of-/etc/mpss/mic0.conf>
```

The runner:

- uses a private alternate MPSS config directory;
- captures `/dev/ttyMIC0`;
- records `micctrl` state changes, dmesg MIC tail, mpssd logs, and ramoops;
- unpacks/lists both the source image and the MPSS-generated ramfs;
- restores stock MPSS afterward;
- verifies stock SSH and `/proc/1/comm=init` after rollback.

## Pass Criteria

The milestone passes only if host-captured evidence contains:

```text
XPR_MIN_INIT_ENTERED
PID=1
XPR_MIN_INIT_IDLE
```

Networking and SSH inside the experimental image are irrelevant.

## Live Result

Date: 2026-07-30

Latest reviewed commit before this diagnostic:

```text
66ff039 Add standalone K1OM initramfs milestone
```

Private build directory:

```text
/root/xeon-phi-revival-local/uos-min-init-builds/xpr-min-init-20260730-071820
```

Private run directory:

```text
/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-071833
```

The minimal init built successfully as a static K1OM ELF:

```text
link_mode=static
elf_machine=Intel K1OM
elf_interpreter=
dynamic_needed=none
entry=0x400be8
init_sha256=2aa7539c629c19def86f542e9561146ddbd2ae601d4d04c3e6ff629df7af6cba
```

The generated image was:

```text
image=/root/xeon-phi-revival-local/uos-min-init-builds/xpr-min-init-20260730-071820/xpr-min-init.cpio.gz
image_size=516K
compressed_bytes=526011
uncompressed_bytes=1162752
image_sha256=8b0e9ee9e377432be73cc9f9402f51f10782d033c75796220ada3f258f4d6181
manifest_sha256=e5a9dbc852008c7600b6d2d9fffa80c5ff704179f823ad2a38e5688addf2cf3f
```

The exact MPSS-generated ramfs consumed by the boot attempt was:

```text
private_ramfs=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-071833/mic0.min-init.image.gz
private_ramfs_sha256=a475bcdc9cba1c38b8c14ae67511b2dc1df6dd824f1272402819d20d88abc692
compressed_bytes=540280
uncompressed_bytes=1189376
```

Both the source image and the MPSS-processed ramfs contained the expected files:

```text
crw------- dev/console
crw-rw-rw- dev/null
-rwxr-xr-x init
-rwxr-xr-x sbin/init
```

The exact boot command was:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-071833/mpss-conf --boot mic0
```

The alternate config changed only:

```diff
-Base CPIO /usr/share/mpss/boot/initramfs-knightscorner.cpio.gz
+Base CPIO /root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-071833/xpr-min-init.cpio.gz
-RootDevice Ramfs /var/mpss/mic0.image.gz
+RootDevice Ramfs /root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-071833/mic0.min-init.image.gz
+ExtraCommandLine "highres=off noautogroup init=/init"
```

### Captured Console Evidence

The console showed stock shutdown, then early kernel boot text from the
experimental boot. It did not show the fixed init markers:

```text
XPR_MIN_INIT_ENTERED
PID=1
XPR_MIN_INIT_IDLE
```

Relevant early console lines included:

```text
[    4.599073] i8042: Can't read CTR while initializing i8042
[    7.791126] Have you set virtblk file?
[    9.831683] [ pm_scif_init : 344 ]:==> pm_scif_init
```

The host-side state stayed in `booting` until MPSS timed out:

```text
mic0: booting (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
Fail booting MIC 0. Wait time execeed 180 seconds
```

`ramoops-current` and `ramoops-prev` were empty.

### Stock Comparison

The stock MPSS Base CPIO includes these corresponding boot entries:

```text
init
dev/console
etc/inittab
sbin/init
sbin/init.sysvinit
```

The minimal image intentionally omitted `etc/inittab`, `sbin/init.sysvinit`,
and all stock MPSS userland.

## Result

The minimal PID 1 marker was not captured. PID 1 execution is therefore not
proven.

This narrows the blocker:

```text
The failure is not BusyBox startup, Python, package tooling, the dynamic
loader, or eglibc shared-library resolution. A static Intel K1OM init with no
ELF interpreter survived MPSS ramfs generation, but no userspace marker reached
the MIC console and MPSS stayed in booting until timeout.
```

The likely next boundary is the direct `Base CPIO` replacement path itself:
either the stock MPSS kernel does not reach `/init` with this minimal layout, or
the required early MPSS boot/monitor environment must be present before
userspace console evidence becomes visible.

## Rollback

The live command exceeded the client-side timeout while the runner was in stock
restore. A manual bounded recovery completed the same stock path:

```sh
systemctl stop mpss
pkill mpssd
micctrl --shutdown mic0
micctrl --reset mic0
micctrl --updateramfs mic0
systemctl reset-failed mpss
systemctl start mpss
```

Final stock verification passed:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
mpss.service=active
stock_ssh_ok_min_recovery
/proc/1/comm=init
uname -m=k1om
/etc/mpss/mic0.conf sha256=9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
/etc/mpss/default.conf sha256=55a3c946c23481a467cf46c814abafce26a834b1c0dc14126b065c30d9fdfb17
```

## Single Next Step

For the next session, keep the same tiny static init but place it inside a
stock-derived Base CPIO copy by replacing only `/init` and `/sbin/init` in the
stock archive. That will test whether the blocker is the minimal archive layout
versus the project init binary itself.
