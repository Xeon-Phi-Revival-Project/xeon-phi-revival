# First Project PID 1 Report

Public-safe report for the first project-controlled K1OM `/init` boot image.
The image and rootfs contain non-redistributable or uncertain-redistribution
runtime files and remain private.

## Objective

Boot the stock MPSS K1OM kernel with a project-owned `/init` process running as
PID 1, while preserving a verified rollback to the stock uOS.

## Current Result

Status: project PID 1 handoff passed; full resident project init remains open.
A stock-MPSS MicDir overlay boot snippet also succeeded and gives the project a
reliable custom-uOS proof channel.

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

A later MicDir handoff test temporarily replaced `/sbin/init` itself. The
project init wrapper ran as PID 1, wrote an observable marker, and then execed
stock `/sbin/init.sysvinit`. SSH came up through the normal stock runlevel-5
path and verified the marker. This is the first verified custom PID 1 execution
event. It is a handoff proof, not a resident project init.

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

### MicDir PID 1 Handoff Proof

A persistent shell-as-`/sbin/init` variant was tried first. It reached MPSS
`online`, but SSH did not come up in six bounded checks. Stock recovery
required removing the overlay, regenerating stock ramfs, and running a normal
`micctrl --reset` before stock SSH returned.

The next variant used a smaller handoff wrapper: replace `/sbin/init` through
MicDir, write one marker as PID 1, then `exec /sbin/init.sysvinit`.

```text
run_dir=/root/xeon-phi-revival-local/uos-boot-builds/micdir-pid1-handoff-20260728-070556
active_conf_sha=c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9
init_sha256=a9a363cdd22f13f0f31890effb0c82983332f25a79cef7f27b049d205ef02ae3
issue_sha256=405a39009bc4b0ef026933fa02da4375300fa687984054a85d38b47bb5151ea6
```

Temporary host overlay files:

```text
/var/mpss/mic0/sbin/init
/var/mpss/mic0/etc/issue
```

Observed on `mic0` after the handoff and stock runlevel-5 startup:

```text
custom_handoff_ssh_ok
Xeon Phi Revival Project PID 1 handoff init overlay booted
PID 1 COMMAND init.sysvinit init [5]
project_pid1_handoff_entered=1
project_pid=1
[project-pid1-handoff] execing /sbin/init.sysvinit
```

The observed mount state after stock startup included `/proc`, `/sys`, and
`/dev`. The marker timestamp was `Thu Jan 1 00:00:06 UTC 1970`, which is
expected at this early boot point before time synchronization.

Rollback removed the MicDir overlay files and restored stock. The immediate
trap cleanup left `mic0` in `ready`, so a bounded recovery step restarted MPSS
and booted `mic0`. Final stock verification showed:

```text
stock_after_handoff_final_ssh_ok
Intel MIC Platform Software Stack (Built by Poky 7.0) 3.4.10 \n \l
handoff_marker_absent
pid1_marker_absent
PID 1 COMMAND init [5]
mic0: online
```

### Phased PID 1 Handoff Ladder

The handoff proof was turned into a reusable MPSS-host runner:

```text
tools/uos/run-micdir-pid1-handoff-experiment.sh
```

The runner uses the stock dynamic MPSS ramfs path and temporarily overlays
`/sbin/init` through `/var/mpss/mic0`. Each phase caps SSH checks, verifies the
custom marker, removes overlay files, regenerates stock ramfs, and verifies
stock SSH again.

Completed phases:

```text
marker_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-pid1-handoff-marker-20260728-144628
marker_result=passed
marker_evidence=project_phase=marker, project_pid=1, init.sysvinit after handoff

tiny_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-pid1-handoff-tiny-20260728-145530
tiny_result=passed
tiny_init_sha256=ca9d2aae13bf3ecbb35a3820008d61fdaaffd2ba31ff5c6d89c72ffd09dd8f5b
tiny_issue_sha256=6b8bfc23a13dfb2f6b3545183658e00f752e771fc1a0673f3f708b95699bc669
tiny_evidence=tiny_action_started=1, early uname and environment captured

hello_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-pid1-handoff-hello-20260728-150247
hello_result=passed
hello_init_sha256=fc484c59e0309f4482a5890e5d66012dbe9c1852ec0e4fdd3496bcf8680f5896
hello_issue_sha256=5229173faa21739fec3a5e605e4afcc341c0e24beeb7022844aea278a1c270f2
hello_evidence=hello_rc=0, machine=k1om, sizeof(void*)=8, sizeof(long)=8

python_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-pid1-handoff-python-20260728-153357
python_result=passed
python_init_sha256=1db0b3fe8d6ff8028b63d0d323f887f0705c338ab0e615e515617da54d064e31
python_issue_sha256=4b8c719a32c3f0d38c2a4a566fbb065cb567e233c1444b5731174fb3d907d4fd
python_evidence=hello_rc=0, python_rc=0, python pid1 demo ok, platform=linux, calc=45
```

Python notes:

- The first Python attempt stopped before activation because the private
  payload rootfs did not include `usr/share/knc-demo/python-core-pid1.py`.
- The runner now generates that demo file when needed.
- A normal Python startup failed because `site.py` wanted `_sysconfigdata`.
- A `python3.5 -S` run with the original generated demo then failed because
  `platform` imports `subprocess`, which wanted `_posixsubprocess`.
- The passing early-boot Python phase is deliberately core-only: `sys`, `os`,
  arithmetic, and cwd/prefix reporting. Extension-module expansion belongs in a
  second-stage userland lane after stock init has brought the card fully online.

## Blocker

The host-side MPSS image selection path is now understood well enough for
bounded experiments: foreground `mpssd -l -d <configdir>` can select a private
`StaticRamFS` image without overwriting stock files.

The card-side PID 1 handoff blocker is cleared for the minimal wrapper case.
The remaining blocker is resident custom init ownership: a shell PID 1 that
tried to run stock rc scripts directly reached MPSS `online` but did not bring
SSH up, so the stock init/MPSS monitor startup semantics are not yet duplicated
well enough.

The MicDir overlay path is the first successful custom uOS execution channel,
and the `/sbin/init` handoff wrapper is the first verified custom PID 1
execution event. The phased handoff ladder has now shown that a tiny project
PID 1 can run marker, tiny environment capture, `hello-knc`, and core Python
before handing off to stock init.

The current design decision is to prefer stock-init handoff plus second-stage
project services for the next uOS lane. That preserves MPSS monitor/network
startup while still giving the project a controlled PID 1 preflight point. Full
resident init replacement stays open, but it should wait until the stock
`init.sysvinit` and MPSS service semantics are mapped more completely.

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

## Full Resident Init Pass Criteria

The full resident project init milestone passes only if all of these are true:

- PID 1 is project-controlled `/init`
- `/proc` is mounted
- `/sys` is mounted
- `/dev` is usable
- `hello-knc` passes
- Python core test passes
- console or shell access is available
- rollback to stock succeeds
- stock uOS boots normally afterward

This full resident milestone has not passed. The prepared `/init` image exists
and stock rollback is verified, but that `/init` image has not yet run as a
resident PID 1 with `hello-knc` and Python core tests.

The narrower `/sbin/init` handoff milestone has passed: a project-controlled
init wrapper ran as PID 1, wrote a marker with `project_pid=1`, execed stock
`init.sysvinit`, ran marker/tiny/`hello-knc`/core-Python phases, preserved
stock SSH startup, and rolled back to stock after each phase.
