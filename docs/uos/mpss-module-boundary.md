# MPSS Module Boundary

Date: 2026-08-01

## Input

The current stock kernel is `2.6.38.8+mpss3.4.10`. MPSS modules remain local,
user-supplied inputs and are not committed or redistributed.

Live module metadata establishes this dependency graph:

```text
mpssboot -> micscif -> ringbuffer,dma_module
intel_micveth -> dma_module
michvc -> ringbuffer
micras -> micscif
pm_scif -> micscif
```

`mpssboot` supplies the `micnotify` readiness path. `intel_micveth` supplies
the MPSS virtual network. `michvc` supplies the hvc virtual console. `micscif`
is the SCIF transport dependency of `mpssboot`; `ringbuffer` and `dma_module`
are transitive dependencies. `mic_virtblk` is a block driver and `ramoops` is
panic logging.

## Verified Omissions

The project early init now omits `mic_virtblk`, `ramoops`, and `micras`.
Each incremental omission boot reached project PID 1, `online`, project SSH,
hello, pthread, and stock rollback:

```text
module                     Base CPIO SHA-256
mic_virtblk                61cb6f8fc0b9d85878d6c666a98bc6d47e85759fbacc7097bf66659fbf6fc927
ramoops (after mic_virtblk) 621aeb48860d0bce52faa405c30ddaf6b6e8894c009942a336cabc8edc6e0026
micras (after both)        6a2901b43f0293795886117ae1ae304a1d3f1089ace321af22e62b2c0c7a9393
```

All three runs reported `boot_pass=1`, `ssh_file_pass=1`,
`tcp_marker_pass=1`, and `rollback_pass=1`.

## Completed Boundary

`pm_scif` is not loaded by the project early init and is not a declared
dependency of `micscif`; the existing project boot series therefore exercises
the path without it. A separate bounded boot omitted `michvc` and passed with
Base CPIO SHA-256:

```text
a46651029b884e7df7506d059612a55884a7efa70dbcf7fd59caf3736e579c53
```

That run reached online, project TCP status, project SSH, hello, pthread, and
stock rollback. HVC console output was intentionally not required: project SSH
and the TCP status service remain sufficient diagnostics for this headless
release path.

The verified required module bundle is now only:

```text
ringbuffer.ko
dma_module.ko
micscif.ko
mpssboot.ko
intel_micveth.ko
```

The bundle builder must validate module version, K1OM architecture, hashes,
and this dependency graph. `mic_virtblk`, `ramoops`, `micras`, `michvc`, and
`pm_scif` are excluded from the minimal project boot image.
