# Standalone K1OM Initramfs Live Report

Date: 2026-07-30

## Scope

This report covers the first narrow standalone Option B uOS attempt: build and
boot a project-controlled K1OM initramfs that keeps a resident project
`/sbin/init` as PID 1 and does not hand off to stock `init.sysvinit`.

Networking, SSH inside the experimental image, Dropbear, APT expansion, and
additional application ports were intentionally out of scope.

## Latest Commit Reviewed

```text
45aba46 Document uOS release licensing options
```

The repository was clean before this milestone started.

## Build Artifact

Private build directory on the MPSS host:

```text
/root/xeon-phi-revival-local/uos-standalone-builds/xpr-uos-standalone-pid1-20260730-063258
```

Generated image:

```text
/root/xeon-phi-revival-local/uos-standalone-builds/xpr-uos-standalone-pid1-20260730-063258/xpr-uos-standalone-pid1.cpio.gz
```

Image details:

```text
compressed_size=6.7M
compressed_bytes=6925547
uncompressed_bytes=19940352
sha256=2236666f322c41eb76f24f16074256bb08e75491a5e0d12f2d324896afa668ab
manifest_sha256=227021903e68b8fa0845a50f648075845c47cb1cc75e137d9858823ae9526d5e
manifest_entries=151
```

The generated private MPSS ramfs from the live run was:

```text
/root/xeon-phi-revival-local/uos-standalone-runs/standalone-initramfs-20260730-063322/mic0.standalone.image.gz
sha256=4ad3046d3afc3ce666b4c021c8849dfaae4bd1d5215276ed34acc3acb01509a6
compressed_bytes=6992111
uncompressed_bytes=19966976
```

## Image Contents

The standalone rootfs includes:

- project-controlled `/sbin/init`;
- `/init` symlink to `/sbin/init`;
- `/bin/busybox` and BusyBox-backed core command links;
- `/etc/os-release`;
- `/dev`, `/proc`, `/sys`, `/run`, `/tmp`;
- `/opt/xeon-phi-revival/bin/hello-knc`;
- `/opt/xeon-phi-revival/bin/pthread-smoke`;
- project eglibc runtime libraries under `/opt/xeon-phi-revival/lib64`;
- `/lib64` symlinks to the project runtime library directory.

The init script is designed to mount `/proc` and `/sys`, prepare `/dev`, mount
tmpfs on `/run` and `/tmp`, set hostname, run bounded shell/filesystem/device,
hello, and pthread checks, report whether `init.sysvinit` is present, reap
children, and idle forever.

## Inherited Local Inputs

The image is private and not public-safe. It still inherits:

- `/bin/busybox` from the current private RC rootfs, which is treated as
  stock/local-input derived until rebuilt or replaced;
- `libgcc_s.so.1` from the local MPSS K1OM SDK lineage;
- working project/Ubuntu-source runtime libraries that still need complete
  binary-release source/license packaging.

It explicitly does not include:

- stock `/sbin/init.sysvinit`;
- stock card-side MPSS service scripts;
- SSH/network startup payloads.

## Stock Baseline

Before the experiment:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
/etc/mpss/mic0.conf sha256=9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
/etc/mpss/default.conf sha256=55a3c946c23481a467cf46c814abafce26a834b1c0dc14126b065c30d9fdfb17
```

## Boot Commands

The runner created a private alternate MPSS config under:

```text
/root/xeon-phi-revival-local/uos-standalone-runs/standalone-initramfs-20260730-063322/mpss-conf
```

The active private config changed only:

```diff
-Base CPIO /usr/share/mpss/boot/initramfs-knightscorner.cpio.gz
+Base CPIO /root/xeon-phi-revival-local/uos-standalone-runs/standalone-initramfs-20260730-063322/xpr-uos-standalone-pid1.cpio.gz
-RootDevice Ramfs /var/mpss/mic0.image.gz
+RootDevice Ramfs /root/xeon-phi-revival-local/uos-standalone-runs/standalone-initramfs-20260730-063322/mic0.standalone.image.gz
+ExtraCommandLine "highres=off noautogroup init=/sbin/init"
```

The first boot command was:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-standalone-runs/standalone-initramfs-20260730-063322/mpss-conf --boot mic0
```

That attempt returned:

```text
Boot failed - card state shutdown
```

A second bounded attempt was made from a clean `ready` state using the same
private config:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-standalone-runs/standalone-initramfs-20260730-063322/mpss-conf --boot mic0
```

The second attempt entered `booting` but produced no project init console
banner and no `BOOT_RESULT` evidence.

## On-Card Evidence

No successful on-card project evidence was captured.

The expected strings were absent from both console captures:

- `resident_pid=1`
- `ID=xpr-uos`
- `machine=k1om`
- `CHECK_RC:hello:0`
- `CHECK_RC:pthread:0`
- `STOCK_INIT_SYSVINIT_PRESENT=0`
- `RESIDENT_IDLE=1`

The card stayed in:

```text
mic0: booting (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
```

until the bounded wait expired.

## Result

Standalone resident PID 1 did not pass.

Observed blocker:

```text
MPSS/micctrl can generate a private ramfs from the standalone cpio image and
attempt to boot it, but the card never emits the project init banner, never
reaches the resident PID 1 smoke checks, and remains in booting until rollback.
```

This is narrower than the earlier stock-init handoff result. The project has a
valid standalone image artifact, but the current direct `Base CPIO` /
alternate-config boot path has not yet proven that the stock kernel reaches
project `/sbin/init`.

## Rollback

The first runner rollback succeeded immediately. The second manual retry left
MPSS in `boot failed` with `mpss.service` failed, so recovery used the stronger
stock path now folded back into the runner:

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
stock_ssh_ok_recovery
/proc/1/comm=init
uname -m=k1om
/etc/mpss/mic0.conf sha256=9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

## Preserved Logs

Private logs remain on the MPSS host under:

```text
/root/xeon-phi-revival-local/uos-standalone-runs/standalone-initramfs-20260730-063322
```

Important files:

- `boot.log`
- `baseline.txt`
- `boot-command.txt`
- `ttyMIC0-console.log`
- `ttyMIC0-console-retry-ready.log`
- `standalone-evidence.txt`
- `final-mic-status.txt`
- `dmesg-mic-tail.txt`
- `mpssd-tail.txt`
- `rollback-verify.txt`
- `rollback-verify-retry-ready.txt`
- `recovery-stock-*.log`
- `standalone-summary.txt`

## Next Step

The next narrow step is to reduce the standalone boot path further: build a
tiny control initramfs containing only a statically linked or loader-minimal
K1OM init that writes directly to `/dev/console` and idles. That will separate
an MPSS/kernel/initramfs handoff problem from a dynamic BusyBox/eglibc startup
problem before adding the full rootfs back.
