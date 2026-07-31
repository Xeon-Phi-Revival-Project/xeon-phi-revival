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

## Stock-Derived Follow-Up

The focused builder for that exact next step is:

```sh
tools/uos/build-stockderived-min-k1om-initramfs.sh \
  --source src/uos/xpr_min_init.c
```

It creates a private image by unpacking the stock MPSS Base CPIO and replacing
only:

```text
/init
/sbin/init
```

It intentionally leaves stock `/sbin/init.sysvinit`, `/etc/inittab`, and the
rest of the stock Base CPIO present so the live test can isolate whether the
previous failure was caused by the minimal archive layout. The generated image
contains stock MPSS userspace and must not be published.

## Stock-Derived Live Result

Date: 2026-07-30

Private build directory:

```text
/root/xeon-phi-revival-local/uos-min-init-builds/xpr-min-init-stockderived-20260730-073726
```

Private run directory:

```text
/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-073805
```

The stock-derived diagnostic image was built by unpacking:

```text
/usr/share/mpss/boot/initramfs-knightscorner.cpio.gz
stock_cpio_sha256=44ecb9b0dbfbe9c5d880cbfe85fe53b65b000e1b66d6c1e779821f4e36923acd
```

Only these paths were replaced:

```text
/init
/sbin/init
```

The original stock `/sbin/init` was a symlink to `/sbin/init.sysvinit`. The
stock-derived diagnostic left these stock paths present:

```text
/sbin/init.sysvinit
/etc/inittab
```

The replacement init remained the same static K1OM ELF:

```text
link_mode=static
elf_machine=Intel K1OM
elf_interpreter=
init_sha256=2aa7539c629c19def86f542e9561146ddbd2ae601d4d04c3e6ff629df7af6cba
```

Generated image:

```text
image=/root/xeon-phi-revival-local/uos-min-init-builds/xpr-min-init-stockderived-20260730-073726/xpr-min-init-stockderived.cpio.gz
image_size=20M
compressed_bytes=20934054
uncompressed_bytes=54844928
image_sha256=e23146753423bf58e9865fcf2f7bf49aa0560d01d56df08c61278d274b7fa2a1
manifest_sha256=4a1a3c29436b2df1c0bf4e784e7cfc53be248780234f7113e56b92bc85d60920
```

Exact boot command:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-073805/mpss-conf --boot mic0
```

The MPSS-generated ramfs consumed by the boot attempt contained:

```text
dev/console
etc/inittab
init
sbin/init
sbin/init.sysvinit
```

The generated ramfs hash was:

```text
private_ramfs=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-073805/mic0.min-init.image.gz
private_ramfs_sha256=bc95b4598acb77255947dfe82762f6ce1d7e0a336eab8087cd345b8b17cfb37b
compressed_bytes=21112458
uncompressed_bytes=54871552
```

Console output again reached early kernel/MPSS text but did not include the
minimal init markers:

```text
XPR_MIN_INIT_ENTERED
PID=1
XPR_MIN_INIT_IDLE
```

The card remained in:

```text
mic0: booting (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
```

until the bounded wait ended. `marker_pass=0`.

Rollback passed:

```text
stock_conf_sha256=9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
mpss.service=active
stock_ssh_ok
/proc/1/comm=init
uname -m=k1om
```

### Updated Blocker

The stock-derived test rules out the minimal archive layout as the primary
blocker. The stock Base CPIO layout, stock `/etc/inittab`, stock
`/sbin/init.sysvinit`, and stock device nodes were present, but replacing
`/init` and `/sbin/init` with a static K1OM ELF still produced no userspace
marker.

The likely blocker is now earlier or more specific:

```text
The MPSS/KNC boot path may not use the Base CPIO /init in the way a normal
Linux initramfs does, or it may require the stock init wrapper behavior before
console-visible userspace output and monitor handoff occur.
```

The next diagnostic should inspect the stock `/init` wrapper semantics and test
a stock-derived image that preserves `/init` while replacing only
`/sbin/init` or only `/sbin/init.sysvinit`, one at a time.

## One-At-A-Time Stock Init Boundary Results

Date: 2026-07-30

Latest reviewed commit before these diagnostics:

```text
2e1a2fb Test stock-derived minimal K1OM init image
```

The stock Base CPIO init boundary was identified as:

```text
/init: POSIX shell script, 3946 bytes
/sbin/init: symlink to /sbin/init.sysvinit
/sbin/init.sysvinit: dynamic K1OM ELF, 34744 bytes
/etc/inittab: present
stock /init sha256=cd0c4b87f31a5d595567a3013fd9f735c1e7dc58d920a1e0e4b315706f1999c6
```

Only the first lines of stock `/init` were inspected. The file is a shell
wrapper that sets an early `PATH` and prepares the card filesystem before later
init handling.

### Preserve `/init`, Replace Only `/sbin/init`

Private build directory:

```text
/root/xeon-phi-revival-local/uos-min-init-builds/xpr-min-init-stock-sbin-init-20260730-145819
```

Private run directory:

```text
/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-150009
```

Replacement mode:

```text
replace_mode=sbin-init
```

The generated image preserved stock `/init`, stock `/sbin/init.sysvinit`, and
stock `/etc/inittab`, but replaced `/sbin/init` with the static marker binary:

```text
link_mode=static
elf_machine=Intel K1OM
elf_interpreter=
init_sha256=2aa7539c629c19def86f542e9561146ddbd2ae601d4d04c3e6ff629df7af6cba
image_sha256=a987d18982702afa1462e0263ff5592735ee1c9f43d9ec7d5765230ecf100867
compressed_bytes=20672076
uncompressed_bytes=54267904
```

Exact boot command:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-150009/mpss-conf --boot mic0
```

The MPSS-generated ramfs consumed by the boot attempt contained:

```text
etc/inittab
init
sbin/init
sbin/init.sysvinit
sbin/telinit -> init
```

No marker was captured:

```text
marker_pass=0
```

Rollback passed:

```text
rollback_pass=1
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
mpss.service=active
stock_ssh_ok
/proc/1/comm=init
uname -m=k1om
```

### Preserve `/init` and `/sbin/init`, Replace Only `/sbin/init.sysvinit`

Private build directory:

```text
/root/xeon-phi-revival-local/uos-min-init-builds/xpr-min-init-stock-sysvinit-20260730-150545
```

Private run directory:

```text
/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-150719
```

Replacement mode:

```text
replace_mode=sbin-init-sysvinit
```

The generated image preserved stock `/init`, preserved `/sbin/init` as a
symlink to `/sbin/init.sysvinit`, preserved stock `/etc/inittab`, and replaced
only `/sbin/init.sysvinit` with the static marker binary:

```text
link_mode=static
elf_machine=Intel K1OM
elf_interpreter=
init_sha256=2aa7539c629c19def86f542e9561146ddbd2ae601d4d04c3e6ff629df7af6cba
image_sha256=e9e3bbdb76314f7aab754d3c0198e5abd15344aaa0ed6000817811718f12b6a8
compressed_bytes=20653257
uncompressed_bytes=54233088
```

Exact boot command:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-150719/mpss-conf --boot mic0
```

The MPSS-generated ramfs consumed by the boot attempt contained:

```text
etc/inittab
init
sbin/init -> /sbin/init.sysvinit
sbin/init.sysvinit
sbin/telinit -> init
```

No marker was captured:

```text
marker_pass=0
```

Rollback passed:

```text
rollback_pass=1
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
mpss.service=active
stock_ssh_ok
/proc/1/comm=init
uname -m=k1om
```

### Boundary Conclusion

These two runs rule out both of the simple stock init boundary replacements:

```text
preserve stock /init, replace /sbin/init only
preserve stock /init and /sbin/init symlink, replace /sbin/init.sysvinit only
```

In both cases the replacement static K1OM ELF survived into the exact
MPSS-generated ramfs, but the marker did not appear and the card remained in
`booting` until the bounded wait ended.

The current narrow blocker is:

```text
The stock /init wrapper is not reaching the replaced init boundary in this
alternate Base CPIO boot lane, or the failure happens before userspace marker
output becomes visible on the host-captured MIC console.
```

## Stock `/init` Instrumentation Result

Date: 2026-07-30

Latest reviewed commit before this diagnostic:

```text
1a5765e Test stock init boundary replacements
```

The stock-derived builder gained a focused mode:

```sh
tools/uos/build-stockderived-min-k1om-initramfs.sh \
  --replace instrument-stock-init \
  --name xpr-stock-init-instrumented-file
```

This mode preserves stock `/sbin/init`, stock `/sbin/init.sysvinit`, stock
`/etc/inittab`, and the rest of the stock Base CPIO. It changes only `/init`
by inserting a small marker block immediately after the shebang, then continues
into the original stock script body.

The marker block writes to early console paths and also records file-backed
evidence:

```text
/xpr-stock-init-marker.txt
/tmp/xpr-stock-init-marker.txt
```

Private build directory:

```text
/root/xeon-phi-revival-local/uos-min-init-builds/xpr-stock-init-instrumented-file-20260730-153854
```

The generated image was:

```text
image=/root/xeon-phi-revival-local/uos-min-init-builds/xpr-stock-init-instrumented-file-20260730-153854/xpr-stock-init-instrumented-file.cpio.gz
image_sha256=852b2d04841e1c99d90ce4e6fd4f42167bd4241d54535dffd23edec55fb0a0a4
compressed_bytes=20408824
uncompressed_bytes=53688320
init_sha256=e555b0cee3d4b580311fec2a4a90d6fde8d7c1926d53e2d07fac19e912c7a2dd
link_mode=stock-shell-script
elf_machine=script
stock_cpio_sha256=44ecb9b0dbfbe9c5d880cbfe85fe53b65b000e1b66d6c1e779821f4e36923acd
```

Private run directory:

```text
/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-153931
```

Exact boot command:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-153931/mpss-conf --boot mic0
```

The card reached `online` during the experimental boot:

```text
boot_poll_5
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
```

The runner then used bounded SSH to read the marker file before rollback. This
proved that the stock `/init` wrapper executed as PID 1:

```text
ssh_marker_probe
XPR_MIN_INIT_ENTERED
PID=1
XPR_MIN_INIT_IDLE
```

Summary result:

```text
marker_pass=1
rollback_pass=1
private_ramfs_sha256=6aaf5803886bb4ed6913ba408d6f4db36f4721aa6238f35325f69a3319bc5694
```

Final stock verification passed:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
stock_ssh_ok
/proc/1/comm=init
uname -m=k1om
```

### Updated Boundary Conclusion

This proves the alternate Base CPIO boot lane does execute stock `/init` as PID
1 when the stock wrapper behavior is preserved. The earlier static-ELF
replacement failures are therefore not a generic MPSS/kernel/initramfs handoff
failure.

The current narrow blocker is:

```text
Stock /init runs, but replacing its later handoff target with a static K1OM
marker prevents successful userspace transition. The next boundary is inside
the stock /init wrapper's handoff logic and expected environment before it
execs stock init.sysvinit.
```

The single next technical step for a later session is to instrument the stock
`/init` wrapper around its final exec/handoff point, preserving stock behavior,
so the exact branch and arguments used to start `init.sysvinit` can be recorded
without replacing that target.

## Stock `/init` Handoff Instrumentation Result

Date: 2026-07-30

Latest reviewed commit before this diagnostic:

```text
b300ec5 Prove stock init executes in Base CPIO lane
```

The stock `/init` wrapper handoff line was identified as:

```text
exec /sbin/switch_root /new_root /sbin/init
```

The stock-derived builder gained a focused mode:

```sh
tools/uos/build-stockderived-min-k1om-initramfs.sh \
  --replace instrument-stock-handoff \
  --name xpr-stock-init-handoff
```

This mode preserves stock `/sbin/init`, stock `/sbin/init.sysvinit`, stock
`/etc/inittab`, and the original handoff `exec`. It changes only `/init` by
inserting a marker block immediately before the `switch_root` handoff.

The marker is written both to early output paths and to the future switched
root:

```text
/new_root/xpr-stock-init-handoff.txt
```

Private build directory:

```text
/root/xeon-phi-revival-local/uos-min-init-builds/xpr-stock-init-handoff-20260730-155529
```

The generated private image was:

```text
image=/root/xeon-phi-revival-local/uos-min-init-builds/xpr-stock-init-handoff-20260730-155529/xpr-stock-init-handoff.cpio.gz
image_sha256=5698d1048defe115191375ee8303e5fea87c57cc519f0bd3ca6615bb0f0e11c3
compressed_bytes=20408820
uncompressed_bytes=53688320
init_sha256=25511376470c96c8d26a33b4348439a5472f346ee91076725210bd23d8e13f79
link_mode=stock-shell-script
elf_machine=script
stock_cpio_sha256=44ecb9b0dbfbe9c5d880cbfe85fe53b65b000e1b66d6c1e779821f4e36923acd
```

Private run directory:

```text
/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-155606
```

Exact boot command:

```sh
micctrl --configdir=/root/xeon-phi-revival-local/uos-min-init-runs/min-init-20260730-155606/mpss-conf --boot mic0
```

The card reached `online` during the experimental boot:

```text
boot_poll_5
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
```

The marker was recovered over SSH before rollback from the switched root as
`/xpr-stock-init-handoff.txt`:

```text
ssh_marker_probe
XPR_MIN_INIT_ENTERED
XPR_STOCK_INIT_HANDOFF
PID=1
CMD=/sbin/switch_root /new_root /sbin/init
XPR_MIN_INIT_IDLE
```

Summary result:

```text
marker_pass=1
rollback_pass=1
private_ramfs_sha256=3292a4cfaaeae3d12bfe8a7e4b6576da8126e6a111330410da255963b8240263
```

Final stock verification passed:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
stock_ssh_ok
/proc/1/comm=init
uname -m=k1om
```

### Updated Handoff Conclusion

This proves the alternate Base CPIO path reaches stock `/init` as PID 1 and
continues all the way to the stock `switch_root` handoff:

```text
/init PID 1 -> /sbin/switch_root /new_root /sbin/init
```

Because replacing `/sbin/init` or `/sbin/init.sysvinit` inside the Base CPIO
did not work, while preserving the stock `switch_root` handoff did work, the
next likely boundary is the switched root itself. The replacement attempts were
made in the Base CPIO, but stock `/init` hands off to `/new_root/sbin/init`.

The single next technical step for a later session is to inspect how
`/new_root` is assembled and test a reversible replacement or wrapper at:

```text
/new_root/sbin/init
```

That should be done without replacing stock firmware, kernel, or the active
host MPSS configuration.

## `/new_root` Inventory Result

Date: 2026-07-30

Latest reviewed commit before this diagnostic:

```text
13af4b4 Trace stock init switch_root handoff
```

The stock-derived builder now has a narrow inspection mode:

```sh
tools/uos/build-stockderived-min-k1om-initramfs.sh \
  --replace instrument-new-root-inventory \
  --name xpr-new-root-inventory
```

It changes only the private Base CPIO copy of stock `/init`. Immediately before
the proven stock handoff, it writes a bounded metadata-only inventory to
`/new_root/xpr-new-root-inventory.txt` and then preserves the original command:

```text
exec /sbin/switch_root /new_root /sbin/init
```

Private build directory:

```text
/root/xeon-phi-revival-local/uos-min-init-builds/xpr-new-root-inventory-20260730-210445
```

The generated private image was:

```text
image=/root/xeon-phi-revival-local/uos-min-init-builds/xpr-new-root-inventory-20260730-210445/xpr-new-root-inventory.cpio.gz
image_sha256=2108e58acdde6d4ac7c604f59387144141aa52a6e0e9569c900752d5f36af06f
compressed_bytes=20408409
uncompressed_bytes=53688320
init_sha256=17b05c863f69d5910d718ecc70ece0b699745a9ed730c6ce3e570d07a062167d
link_mode=stock-shell-script
elf_machine=script
stock_cpio_sha256=44ecb9b0dbfbe9c5d880cbfe85fe53b65b000e1b66d6c1e779821f4e36923acd
```

The bounded experiment booted to `online` and recovered the inventory over SSH
before restoring stock. The relevant on-card evidence was:

```text
XPR_MIN_INIT_ENTERED
XPR_NEW_ROOT_INVENTORY
PID=1
PWD=/
drwxr-xr-x ... /new_root
drwxr-xr-x ... /new_root/sbin
lrwxrwxrwx ... /new_root/sbin/init -> /sbin/init.sysvinit
-rwxr-xr-x ... /new_root/sbin/init.sysvinit
rootfs on / type rootfs (rw)
none on /proc type proc (rw,relatime)
none on /new_root type tmpfs (rw,relatime,size=6699996k,mode=755)
XPR_MIN_INIT_IDLE
```

The stock initramfs lacks `stat`, so no ownership or device metadata beyond the
listed modes was captured. The result is still sufficient to identify the
insertion point: `/new_root` is the root switched into by stock `/init`, and
the executable run there is `/new_root/sbin/init.sysvinit` through the
`/new_root/sbin/init` absolute symlink.

After automatic recovery, the host verified:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
ssh 172.31.1.1: uname -m=k1om
ssh 172.31.1.1: /proc/1/comm=init
```

### Updated Handoff Conclusion

The first distributable-uOS insertion point is now verified at the filesystem
level. A later, separate experiment can install a temporary wrapper at
`/new_root/sbin/init` that records execution and `exec`s the preserved stock
`/sbin/init.sysvinit`. That test is intentionally out of scope for this
mapping-only milestone.

## `/new_root/sbin/init` Wrapper Result

Date: 2026-07-30

Latest reviewed commit before this diagnostic:

```text
cb7054f Map stock new_root handoff target
```

The stock-derived builder gained the focused mode:

```sh
tools/uos/build-stockderived-min-k1om-initramfs.sh \
  --replace instrument-new-root-init-wrapper \
  --name xpr-new-root-init-wrapper
```

Immediately before stock `/init` runs `switch_root`, the private experimental
copy renames only the switched-root binary:

```text
/new_root/sbin/init.sysvinit
  -> /new_root/sbin/init.sysvinit.xpr-stock
```

It then writes a POSIX-shell wrapper at the original path. The existing
`/new_root/sbin/init -> /sbin/init.sysvinit` link therefore starts the wrapper
as PID 1 after `switch_root`; the wrapper writes a marker and executes the
preserved stock binary. No active MPSS file or persistent stock card-side file
is modified.

Private build output:

```text
image=/root/xeon-phi-revival-local/uos-min-init-builds/xpr-new-root-init-wrapper-20260730-233916/xpr-new-root-init-wrapper.cpio.gz
image_sha256=fd2da35d9fd56b0ab777128fbbfb5c1fb11756c4f9b70a7ae8e94f1f0f193628
compressed_bytes=20408720
uncompressed_bytes=53688320
init_sha256=b58b07c7159731b608e254c838da728220ce9540fcb683d68bc74864e55fc30d
stock_cpio_sha256=44ecb9b0dbfbe9c5d880cbfe85fe53b65b000e1b66d6c1e779821f4e36923acd
redistribution=private-stock-derived-do-not-publish
```

The boot reached `online`, and SSH recovered the post-`switch_root` marker:

```text
XPR_MIN_INIT_ENTERED
XPR_NEW_ROOT_INIT_WRAPPER
PID=1
STOCK_INIT=/sbin/init.sysvinit.xpr-stock
XPR_MIN_INIT_IDLE
```

This proves a project-controlled executable can run as PID 1 in the switched
root and safely hand control back to the stock init binary. The stock rollback
was verified directly afterward:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
ssh 172.31.1.1: uname -m=k1om
ssh 172.31.1.1: /proc/1/comm=init
```

### Smallest Fully Project-Built Boot Boundary

Read-only inspection of the stock `/init` showed it mounts a tmpfs at
`/new_root`, copies the assembled initramfs tree there, then runs:

```text
exec /sbin/switch_root /new_root /sbin/init
```

The private MPSS-generated Ramfs is a complete filesystem archive containing
`/init`, `/sbin/init`, `/sbin/init.sysvinit`, and `/bin/sh`. Therefore the
smallest next standalone milestone is not a new kernel or firmware path. It is
a project-built Ramfs containing the project rootfs and a project `/init` that
mounts the required pseudo-filesystems and switches into the project root.
MPSS remains only the host-side kernel and Ramfs loader.

That standalone Ramfs must be built solely from project-owned or
redistribution-cleared files; it must not copy the stock init, stock shell, or
stock card-side utility tree. This is the next session's boundary and was not
booted in this wrapper experiment.

## Project Handoff Bootstrap Attempts

Date: 2026-07-31

Two bounded, reversible attempts tested project userspace while retaining the
proven stock Base-CPIO bootstrap.

Attempt one staged the complete project root under `/xpr-project-root` and
modified stock `/init` to overlay it onto `/new_root` immediately before the
unchanged `switch_root` command:

```text
image=xpr-project-root-handoff.cpio.gz
image_sha256=333f73208f4ceb18ca26b0ec2f75a5cb29bcebaf51af9cb03afcb040ac018d7d
compressed_bytes=27332635
```

Attempt two reduced that payload to only the project `/sbin/init` script under
`/xpr-project-init`, replacing only `/new_root/sbin/init` immediately before
the unchanged handoff:

```text
image=xpr-project-init-handoff.cpio.gz
image_sha256=68c829bb7003b19bac0f35acb7176f07c6b2f72d5a9229e34ddbd49f0173dc70
compressed_bytes=20409961
```

Neither image reached stock `/init` or the project handoff logic. The expected
`XPR_PROJECT_ROOT_STAGED`, `XPR_PROJECT_INIT_STAGED`, `BOOT_START`, and
`RESIDENT_IDLE=1` markers were absent. In both cases the 72-line console ended
at the same early kernel point:

```text
[    7.741221] Have you set virtblk file?
[    9.793972] [ pm_scif_init : 344 ]:==> pm_scif_init
```

This is earlier than the stock-init and switched-root wrapper milestones that
previously passed. The newly added project payload changes the MPSS-generated
boot image in a way that prevents the kernel from reaching Base-CPIO `/init`.
It is not yet evidence of a project shell, runtime, or `switch_root` failure.

After the second attempt, stock recovery was verified directly:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
systemctl is-active mpss=active
ssh 172.31.1.1: uname -m=k1om
ssh 172.31.1.1: /proc/1/comm=init
```

The next investigation must compare the exact MPSS-generated ramfs layout and
metadata for a passing stock-derived wrapper image against these two failing
payload-bearing images before another boot is attempted.

## Embedded Project Init Size-Boundary Test

Date: 2026-07-31

The project init was embedded directly inside the existing stock `/init` file.
At runtime, stock `/init` would write it to `/new_root/sbin/init` and retain
the original `switch_root` command. This image added no archive members:

```text
stock CPIO entries=1787
embedded-project-init CPIO entries=1787
```

Static inspection confirmed the embedded script contained direct console
markers before the project init body:

```text
XPR_PROJECT_INIT_ENTERED
PID=$$
```

The resulting private image was:

```text
image=xpr-embedded-project-init.cpio.gz
image_sha256=f2c54d562a5b9a054c975f80a2ab6f4ef74ab4b4ba67cdf09e048d4411661b17
compressed_bytes=20409820
uncompressed_bytes=53691392
```

It again stopped before Base-CPIO `/init`; no `XPR_PROJECT_INIT_ENTERED`,
`XPR_PROJECT_INIT_STAGED`, `BOOT_START`, or `RESIDENT_IDLE=1` marker appeared.
The early console ending matched the prior failures:

```text
[    7.741221] Have you set virtblk file?
[    9.793972] [ pm_scif_init : 344 ]:==> pm_scif_init
```

This rules out the added-path hypothesis. The strongest current correlation is
the uncompressed ramfs size. The last passing stock-wrapper image was
53,688,320 bytes; this image and the small extra-path project-init image were
both 53,691,392 bytes, exactly 3,072 bytes larger. The complete project-root
attempt was larger still at 73,630,208 bytes. This is a working hypothesis,
not a proven MPSS limit.

Stock recovery after the test was verified directly:

```text
mic0: online (mode: linux image: /usr/share/mpss/boot/bzImage-knightscorner)
systemctl is-active mpss=active
ssh 172.31.1.1: uname -m=k1om
ssh 172.31.1.1: /proc/1/comm=init
```

That size hypothesis was tested by the follow-up below. Matching the known
stock size did not allow the project marker to appear, so size reduction is no
longer the next investigation.

## Size-Matched Follow-Up

Date: 2026-07-31

The follow-up preserved the stock archive member count and reduced an unused
localized GnuPG help file by 3,072 bytes. The resulting embedded-project-init
image matched the known passing stock archive exactly:

```text
commit=985946529a6c6d27b2b9afe3deada19866814e24
image_sha256=e87e4b50b26a2ded51ee1c0402f1a6546212a6bfb3acb105c17a6ef3c796f030
uncompressed_bytes=53688320
cpio_members=1787
```

The bounded live attempt still left `mic0` in `booting` and produced no
project-init marker. Automatic recovery passed: MPSS became active, `mic0`
returned online, stock SSH returned `k1om`, and stock PID 1 was `systemd`.
Matching total archive size and member count is therefore not the immediate
cause. The next control is the no-op stock unpack/repack experiment.
