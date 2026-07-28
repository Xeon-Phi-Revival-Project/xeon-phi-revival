# First Project PID 1 Report

Public-safe report for the first project-controlled K1OM `/init` boot image.
The image and rootfs contain non-redistributable or uncertain-redistribution
runtime files and remain private.

## Objective

Boot the stock MPSS K1OM kernel with a project-owned `/init` process running as
PID 1, while preserving a verified rollback to the stock uOS.

## Current Result

Status: PID 1 activation attempted, blocked before verifiable project PID 1.
A separate stock-MPSS MicDir overlay boot snippet has now succeeded and gives
the project a reliable custom-uOS proof channel.

The private bootable rootfs was assembled from the already passing K1OM
compatibility-demo rootfs.

The first activation sessions did not reach a verifiable project `/init`. Early
attempts failed at MPSS image selection, but a later foreground `mpssd -l -d`
activation path did select alternate `StaticRamFS` images. Stock and repacked
stock images boot through that path. Project-modified PID 1 images are selected
by MPSS but remain in `booting` until timeout, without a project PID 1 marker,
console banner, or card-side monitor connection. Rollback to the stock uOS
succeeded after each bounded attempt.

After those failures, a smaller supported-MPSS customization path was tested:
temporarily inject a project banner and SysV rc5 service through the stock
MicDir overlay at `/var/mpss/mic0`, restart MPSS normally, verify the custom
content on `mic0`, then restore the overlay and restart stock. That path
worked. It does not make project `/init` PID 1; PID 1 remains stock SysV
`init [5]`. It does prove that project-controlled uOS content can boot and run
on the card while preserving a clean rollback.

## Prepared `/init`

The project `/init` does the following:

- writes immediately to `/dev/console` when available
- creates `/dev`, `/proc`, `/sys`, `/run`, `/tmp`, `/root`, and `/var/log`
- mounts `/proc`
- mounts `/sys`
- mounts `devtmpfs` on `/dev`, falling back to `tmpfs`
- creates `/dev/null`, `/dev/zero`, `/dev/console`, `/dev/urandom`, and
  `/dev/random` when required
- sets `PATH`, `HOME`, and `LD_LIBRARY_PATH`
- records `uname -a`, PID, mounts, and environment
- runs `/usr/bin/hello-knc`
- runs `/usr/bin/python3.5 /usr/share/knc-demo/python-core-pid1.py`
- starts a recovery shell and restarts it if it exits

## Image Checks

The private packed image is gzip-compressed SVR4/newc cpio.

```text
image_sha256=ad72f322cb923a7e8970730cd2cbb337c98cc7f409660e232e26667132031188
manifest_sha256=2b7985e613a882c032ea779da181867e130016e135d17e8369858c7d6a563d07
init_sha256=04690d7cdbcff315baaf12c849cf94cfa06eb2d52d4261df55c5a6b5b5927ca4
python_demo_sha256=3ad82d899fdec2fbbc835fd862ef2cc8191db60a40b3ccea40f5e99e7914ecd6
compressed_size=14679629
uncompressed_size=51078656
```

Required entries confirmed in the archive:

```text
.
dev/console
dev/null
dev/random
dev/urandom
dev/zero
init
proc
sys
usr/bin/hello-knc
usr/bin/python3.5
usr/share/knc-demo/python-core-pid1.py
```

Rootfs validation confirmed all checked ELF files are K1OM `e_machine=181` and
that runtime dependencies resolve inside the staged rootfs.

## Activation Attempts

All attempts used stock kernel files and private alternate configuration or
temporary selectors. No firmware operation was run.

### Direct `micctrl --configdir`

The alternate config parsed and `micctrl --updateramfs` produced a private
alternate ramfs:

```text
project_ramfs_sha256=96b560ec337a5f5f4ab92712cfa8f428da13bfdf0ea2ff7923486e1fabf91a10
compressed_size=14802032
uncompressed_size=51099136
```

However, `micctrl --configdir=<alternate-config> --boot mic0` aborted before
boot:

```text
Boot aborted - no configuation file present
```

The card remained in `ready`.

### Service Environment Selector

Running the MPSS init script with `MPSS_CONFIGDIR=<alternate-config>` did not
select the alternate config because the init script redirected through
`systemctl`; the service booted the stock ramfs instead. SSH showed stock
SysV `init` as PID 1.

### Temporary `/etc/sysconfig/mpss.conf` Selector

Creating a temporary `/etc/sysconfig/mpss.conf` selector did cause MPSS to read
the alternate configuration, but both dynamic `Ramfs` and direct `StaticRamFS`
attempts aborted before boot:

```text
Boot aborted - no configuation file present: File exists
```

The card stayed in `ready`, and the project `/init` banner was never seen on
the console log.

### Foreground `mpssd -l -d` Selector

Local inspection of `/usr/sbin/mpssd --help` showed that the daemon accepts an
alternate configuration directory directly:

```text
mpssd <-l> <--local> <-d configdir> <--directory=configdir>
```

Using a copied MPSS configuration directory and launching foreground `mpssd`
with `-l -d <alternate-config>` successfully selected alternate
`StaticRamFS` paths. The daemon log showed the exact stock kernel and
experimental initrd image being handed to the MIC driver.

Control results:

```text
stock_staticramfs_copy_sha256=0de39e80b49463e2cdd46eb367df1110bbda3ae3af6979d45601e3286f00c67c
stock_staticramfs_control=online
repacked_stock_sha256=f82c8878f39d285fcfffb8ca2f7bd2241135f138ffe65631c92f9e5bad6ad867
repacked_stock_control=online
```

This proves that `StaticRamFS` activation works and that the project packer can
produce a bootable gzip/newc cpio image when the content is otherwise stock.

Project image results:

```text
minimal_project_image_sha256=ad72f322cb923a7e8970730cd2cbb337c98cc7f409660e232e26667132031188
initcmd_project_image_sha256=443e21548eebfbcdbc86332bb48c2b6127d4e82d2ca6792b9a7e1d8aa279d9b5
stockderived_project_image_sha256=3ec14cddaab969626606701811a08fce0eecabbfd2e13d47c817ec8f77cb4aa3
elf_project_pid1_image_sha256=abd594fc6c769bf0f1feebb5a27abcba968d2d1f6978559a004c324a0ee151ea
```

Observed behavior:

- MPSS selected each experimental image path.
- The host-side sysfs `initramfs` value pointed at the experimental image.
- The kernel command line reflected the tested `init=/init` variant when used.
- The card remained in `booting` and eventually reached `boot failed`.
- No project `/init` or ELF PID 1 marker appeared in the console capture.
- A stock-sized native K1OM ELF `/sbin/init` wrapper that immediately execed
  stock `init.sysvinit` let MPSS reach `online`, but it did not produce an
  independent marker proving wrapper execution.

### Rollback

Rollback restored the default selector state: `/etc/sysconfig/mpss.conf` was
absent again.

The stock MPSS service then booted the stock uOS successfully:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
PID 1 COMMAND init
stock-rollback-ssh-ok
```

The stock kernel, stock base initramfs, and stock MPSS config hashes still match
the baseline. The generated `/var/mpss/mic0.image.gz` hash changed because MPSS
regenerated the stock ramfs during service rollback.

### MicDir Overlay Custom Boot Snippet

A bounded MicDir overlay experiment was run after the PID 1 attempts:

```text
run_dir=/root/xeon-phi-revival-local/uos-boot-builds/micdir-overlay-proof-20260728-064840
active_conf_sha=c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9
issue_sha256=f8f134eb88d331a823f542188356358968979630cb96c5fd9fde99d37bd4d2bf
snippet_sha256=6bbf26eca6f16655bb49a2a797a1546921d328a06a3b85540492a4c0d6f0b17e
```

Temporary host overlay files:

```text
/var/mpss/mic0/etc/issue
/var/mpss/mic0/etc/init.d/xeon-phi-revival-snippet
/var/mpss/mic0/etc/rc5.d/S79xeon-phi-revival-snippet
```

Observed on `mic0` after MPSS reported `online`:

```text
ssh_custom_ok
Xeon Phi Revival Project MicDir overlay custom uOS snippet booted
PID 1 COMMAND init [5]
/etc/rc5.d/S79xeon-phi-revival-snippet -> ../init.d/xeon-phi-revival-snippet
[xeon-phi-revival-snippet] MicDir overlay custom boot snippet ran at Tue Jul 28 06:49:47 UTC 2026
```

Rollback restored the exact stock `/etc/mpss/mic0.conf` hash, restarted MPSS,
verified stock SSH, verified the stock `/etc/issue`, and confirmed
`/project-boot-snippet.txt` was absent.

## Blocker

The host-side MPSS image selection path is now understood well enough for
bounded experiments: foreground `mpssd -l -d <configdir>` can select a private
`StaticRamFS` image without overwriting stock files.

The current blocker is the card-side early userspace handoff. Stock and
repacked-stock images boot, but images with project PID 1 changes stall before
verifiable project output or monitor connection.

The MicDir overlay path is the first successful custom uOS execution channel.
The narrowest next dependency for the original PID 1 objective is to reuse what
was learned from that proof channel: keep stock MPSS dynamic ramfs generation
and stock init behavior as intact as possible, then introduce a tiny native
K1OM PID 1 handoff that only performs one observable action and execs stock
init.

Do not expand the Python-in-boot image again until the smaller PID 1 proof is
repeatable. The Python payload likely belongs in a second-stage delivery after
the stock MPSS monitor/network stack is up, or in a later boot image once the
PID 1 proof channel is reliable.

## Previous Activation Procedure

Do not run this procedure without explicit approval.

Prepare an alternate MPSS configuration directory:

```sh
PROJECT_IMAGE="<private-build-dir>/image/k1om-project-pid1.cpio.gz"
PROJECT_CONF="<private-build-dir>/mpss-conf"
PROJECT_RAMFS="<private-build-dir>/mic0.project-pid1.image.gz"

mkdir -p "$PROJECT_CONF"
cp -a /etc/mpss/. "$PROJECT_CONF/"
sed -i "s|^Base CPIO .*|Base CPIO $PROJECT_IMAGE|" "$PROJECT_CONF/mic0.conf"
sed -i "s|^RootDevice Ramfs .*|RootDevice Ramfs $PROJECT_RAMFS|" "$PROJECT_CONF/mic0.conf"
micctrl --configdir="$PROJECT_CONF" --config mic0
```

Activate only `mic0`:

```sh
micctrl --shutdown mic0 || true
micctrl --wait mic0 || true
micctrl --configdir="$PROJECT_CONF" --updateramfs mic0
micctrl --configdir="$PROJECT_CONF" --boot mic0
micctrl --wait mic0
micctrl --status
```

Capture evidence:

```sh
dmesg | grep -iE 'mic|mpss|k1om|knc|xeon phi' | tail -160
tail -160 /var/log/mpssd
cat /proc/mic_ramoops/mic0 2>/dev/null || true
cat /proc/mic_ramoops/mic0_prev 2>/dev/null || true
timeout 20 cat /dev/ttyMIC0
ssh -o BatchMode=yes mic0 'ps -p 1 -o pid,ppid,comm,args; mount; /usr/bin/hello-knc; /usr/bin/python3.5 /usr/share/knc-demo/python-core-pid1.py' || true
```

Rollback to stock:

```sh
micctrl --shutdown mic0 || true
micctrl --wait mic0 || true
systemctl restart mpss
micctrl --wait mic0
micctrl --status
ssh -o BatchMode=yes mic0 'uname -a; ps -p 1 -o pid,ppid,comm,args; cat /proc/cmdline'
```

## Pass Criteria

The first PID 1 boot passes only if all of these are true:

- PID 1 is project-controlled `/init`
- `/proc` is mounted
- `/sys` is mounted
- `/dev` is usable
- `hello-knc` passes
- Python core test passes
- console or shell access is available
- rollback to stock succeeds
- stock uOS boots normally afterward

This milestone has not passed. The prepared image exists and stock rollback is
verified, but project `/init` has not yet run as PID 1.
