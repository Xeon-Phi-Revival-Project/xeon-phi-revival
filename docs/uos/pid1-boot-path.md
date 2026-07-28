# Project PID 1 Boot Path

Public-safe boot-path map for the first project-controlled K1OM `/init`
experiment. Stock MPSS files were inspected read-only and were not modified.

## Active MPSS State

- Host MPSS packages: MPSS `3.4.10`
- Card state at capture: `mic0: online`
- Active card kernel image selected by MPSS:
  `/usr/share/mpss/boot/bzImage-knightscorner`
- Kernel symlink target:
  `/usr/share/mpss/boot/bzImage-2.6.38+mpss3.4.10-knightscorner`
- Active System.map:
  `/usr/share/mpss/boot/System.map-knightscorner`
- System.map symlink target:
  `/usr/share/mpss/boot/System.map-2.6.38+mpss3.4.10-knightscorner`
- Base initramfs/rootfs input:
  `/usr/share/mpss/boot/initramfs-knightscorner.cpio.gz`
- Base initramfs symlink target:
  `/usr/share/mpss/boot/initramfs-2.6.38+mpss3.4.10-knightscorner.cpio.gz`
- Generated active card ramfs:
  `/var/mpss/mic0.image.gz`
- MPSS daemon: `/usr/sbin/mpssd`

## Active Configuration Files

MPSS is using the default configuration directory:

```text
/etc/mpss
```

No `/etc/sysconfig/mpss.conf` override was present at capture time.

The active files are:

- `/etc/mpss/default.conf`
- `/etc/mpss/mic0.conf`

The relevant active directives are:

```text
CommonDir /var/mpss/common
ShutdownTimeout 300
CrashDump /var/crash/mic 16
Console "hvc0"
ExtraCommandLine "highres=off noautogroup"
Base CPIO /usr/share/mpss/boot/initramfs-knightscorner.cpio.gz
MicDir /var/mpss/mic0
OSimage /usr/share/mpss/boot/bzImage-knightscorner /usr/share/mpss/boot/System.map-knightscorner
BootOnStart Enabled
RootDevice Ramfs /var/mpss/mic0.image.gz
PowerManagement "cpufreq_on;corec6_on;pc3_on;pc6_on"
Cgroup memory=disabled
```

Host-specific hostname, IP, and MAC fields are intentionally omitted from this
public document. They are not required to reproduce the PID 1 image build.

## Formats

- Kernel image: Linux x86 boot executable `bzImage`,
  `2.6.38.8+mpss3.4.10`
- Base rootfs/initramfs compression: gzip
- Base archive format after decompression: ASCII cpio archive,
  SVR4/newc with no CRC
- Generated card ramfs compression: gzip
- Generated card ramfs archive format after decompression: ASCII cpio archive,
  SVR4/newc with no CRC

The stock base archive gzip metadata reports:

```text
compressed=20482311
uncompressed=53687296
```

The active generated card image gzip metadata reports:

```text
compressed=20651449
uncompressed=53707776
```

## Kernel Command Line

The running stock card reported this `/proc/cmdline`:

```text
card=0 vnet=dma scif_id=1 scif_addr=0xbffb8ddec0 vnet_addr=0xbffdd44118 vcons_hdr_addr=0x9ffb2ca780 virtio_addr=0xbff8a81120 mem=8192M ramoops_size=16384 ramoops_addr=0xbff1b58000 p2p=1 p2p_proxy=1 etc_comp=-23 reg_cache=1 ulimit=0 huge_page=1 crashkernel=1M@80M quiet root=ramfs console=hvc0 cgroup_disable=memory highres=off noautogroup micpm=cpufreq_on;corec6_on;pc3_on;pc6_on
```

The project PID 1 image must therefore assume:

- root filesystem is a ramfs/initramfs-style cpio image
- console is `hvc0`
- `/init` console output should go to `/dev/console`
- networking may not exist unless MPSS overlays bring it up

## Timeout And Logs

The only explicit timeout found in active MPSS config is:

```text
ShutdownTimeout 300
```

No explicit card boot timeout directive was found in `/etc/mpss`.

Observed stock boot logging from the host showed MPSS waiting at 5, 10, and 15
seconds, with the stock card transitioning from `booting` to `online` after
roughly 19 seconds in the captured boot.

Useful host-side log/console surfaces:

- `dmesg`
- `/var/log/mpssd`
- `/dev/ttyMIC0`
- `/proc/mic_ramoops/mic0`
- `/proc/mic_ramoops/mic0_prev`

## Experimental Direction

The first project PID 1 experiment must not change the stock kernel. It should
boot the existing stock kernel with an alternate ramfs image selected through an
alternate MPSS config directory, then roll back to the default `/etc/mpss`
configuration afterward.
