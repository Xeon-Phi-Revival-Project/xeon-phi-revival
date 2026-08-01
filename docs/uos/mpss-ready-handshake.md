# MPSS Ready Handshake

Date: 2026-08-01

## Finding

The stock card changes from `booting` to `online` after its final lifecycle
script performs two actions:

1. load the MPSS-supplied `mpssboot` kernel module;
2. write `done` to `/sys/class/micnotify/notify/host_notified`.

This was established read-only from the stock card's lifecycle configuration,
module state, and sysfs interface. The stock `mpssd` daemon is a separate
SCIF-based management service; it is not required for the observed online
transition.

## Project Replacement

The project early init loads `mpssboot` before `switch_root`, while the MPSS
module tree is still available. The project root `/sbin/init` then:

1. configures the documented StaticPair `mic0` address;
2. starts a static project status endpoint on TCP port `31337`;
3. writes `done` to the `micnotify` sysfs attribute;
4. records `XPR_MPSS_READY_NOTIFIED`.

The project implementation was written independently. No stock init script or
card-side executable is copied into the project rootfs.

`mpssboot.ko` remains an external MPSS kernel module supplied by the user's
local installation. It is not redistributed or committed. The current Base
CPIO also still contains the local MPSS module tree required before
`switch_root`; this milestone proves a project-owned root and lifecycle path,
not yet a Base CPIO containing only project-owned files.

## Live Evidence

One generated image was used for three consecutive bounded experiments:

```text
Base CPIO SHA-256: 7c1436630f32d87ff52970f8301efa1b543e6c004a3edebb43c9cfe6f0e83330
Root archive SHA-256: 2da83d13e5895577a046bd119f50b6f99c3046c605028138d1e867e4182520c7
```

Every run reached `mic0: online` and returned this project-owned TCP evidence:

```text
XPR_CLEAN_ROOT_READY
XPR_MPSS_READY_NOTIFIED
```

Each run restored the stock MPSS configuration. The original configuration
hash remained:

```text
9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

After the final run, stock `mic0` was online, MPSS was active, and stock SSH
again reported `k1om` with stock `init` as PID 1.

## SSH Follow-On

The first project-owned SSH boot is documented in
`docs/uos/clean-root-ssh-experiment.md`. The clean root reached project
`/sbin/init` as PID 1, configured the MPSS virtual interface, started
project-built Dropbear, accepted public-key authentication, and returned the
project status log over SSH before stock rollback succeeded.

Three consecutive boots have now passed the project SSH and stock rollback
checks. The remaining early-boot boundary is the local MPSS module tree still
provided by the Base CPIO before the project early init performs
`switch_root`. Do not add Python or package-management payloads to this boot
lane first.
