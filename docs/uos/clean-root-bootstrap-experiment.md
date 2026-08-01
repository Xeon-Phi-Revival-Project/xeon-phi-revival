# Clean Root Bootstrap Experiment

Date: 2026-08-01

## Purpose

This experiment tested the smallest project-owned root filesystem that can be
handed to by the project early `/init`. It deliberately excludes Python, APT,
and an SSH daemon. Its only userland payload is a project-built static BusyBox,
project shell PID 1, `os-release`, and static project hello/pthread smoke
programs.

The Base CPIO still supplies the MPSS kernel modules required for host/card
communication. The bootstrap itself invokes only the project-built BusyBox for
its shell, module loader, mount, gzip, cpio, and `switch_root` operations.
No stock root filesystem executable is deliberately copied into the project
root.

## Reproducible Inputs

BusyBox 1.19.4 was built privately from the official BusyBox source archive
with the installed K1OM SDK. The resulting static K1OM ELF had no dynamic
dependencies:

```text
BusyBox SHA-256: 2ebe949a41d20ecc0fb2597eb0556f2316b652af678c5681917f626e9407dd22
BusyBox source archive SHA-256: 9b853406da61ffb59eb488495fe99cbb7fb3dd29a31307fcfa9cf070543710ee
```

The first clean-root archive was:

```text
rootfs cpio SHA-256: 0fc81dd8cb4846a0ee61bbc427bc4e81a7d4f02b6bd4a495fe576bb7cc183b62
compressed bytes: 1,509,442
uncompressed bytes: 3,018,240
```

The alternate Base CPIO was:

```text
SHA-256: 3667c62e30d905ad7da0b5d08ab78a84c99d0179d1a738e8e6142bf15edbfcfe
compressed bytes: 22,964,165
```

It replaces only `/init` and adds these project artifacts before the newc
trailer:

```text
xpr-tools/busybox
xpr-rootfs.cpio.gz
```

## Live Result

One bounded boot used an alternate MPSS configuration and the existing
automatic rollback runner. Before boot, stock SSH, stock Base CPIO hash, and
the stock MPSS configuration hash matched the recorded baseline.

The card stayed in `booting` for all 18 five-second polls. It therefore did
not pass the rootfs test. The generated MPSS ramfs was inspected after the run:
the project `/init`, `xpr-tools/busybox`, and `xpr-rootfs.cpio.gz` all survived
with the expected archive presence and executable BusyBox mode.

Host kernel evidence recorded during the attempt showed `MIC 0 Network link is
up`, so the MPSS virtual-network module path was reached. MPSS nevertheless
did not transition the card to `online` and reset it at the bounded timeout.

This is evidence for a missing project implementation of the MPSS card-side
ready/lifecycle handshake after virtual networking becomes available. It is
not evidence that the archive was dropped or that the Base CPIO parser failed.
The project root PID 1 marker could not be directly recovered because this
intentionally minimal root does not yet include an SSH service or another
independent card-to-host reporting channel.

## Recovery

The runner restored the original configuration automatically. Verification
after the experiment passed:

```text
boot_pass=0
rollback_pass=1
mic0: online
mpss.service: active
stock SSH: k1om
/etc/mpss/mic0.conf SHA-256: 9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

## Next Narrow Step

Map the stock card-side service or binary that signals MPSS readiness after
the virtual link appears, using the stock uOS only as a private reference.
Then implement or replace that one handshake in project-controlled userland
before attempting another clean-root boot. Do not add Python, APT, or broad
packages first.
