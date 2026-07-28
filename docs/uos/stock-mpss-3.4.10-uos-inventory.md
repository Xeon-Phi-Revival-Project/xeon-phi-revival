# Stock MPSS 3.4.10 uOS Inventory

This note records public-safe facts from a local inventory of the stock MPSS
3.4.10 Knights Corner uOS environment. Raw uOS images, extracted filesystems,
hash lists, and proprietary binaries remain local-only.

## Inventory Run

- Host: private CentOS MPSS host
- Host kernel: `3.10.0-693.el7.x86_64`
- MPSS state: `mic0: online`
- Raw local archive:
  local-only private uOS inventory archive

## Boot Artifacts

Observed under `/usr/share/mpss/boot`:

- `bzImage-2.6.38+mpss3.4.10-knightscorner`
- `initramfs-2.6.38+mpss3.4.10-knightscorner.cpio.gz`
- `System.map-2.6.38+mpss3.4.10-knightscorner`
- `rasmm-kernel.knightscorner-ab.elf`
- `rasmm-kernel.knightscorner-c.elf`
- `rasmm-kernel.from-eeprom.elf`

The initramfs listing contains 1,787 entries.

## Live Card Kernel

`uname -a` on `mic0`:

```text
Linux mic0.local 2.6.38.8+mpss3.4.10 #1 SMP Thu Jan 12 16:38:30 EST 2017 k1om GNU/Linux
```

The kernel command line includes:

```text
root=ramfs console=hvc0 cgroup_disable=memory highres=off noautogroup
```

It also includes MPSS-provided addresses and options for SCIF, VNET, ramoops,
p2p, huge pages, crash kernel, and MIC power management.

## Userland Facts

Initial public-safe observations:

- `/sbin/init` is a symlink to `/sbin/init.sysvinit`.
- `/bin/busybox` is a setuid dynamically linked K1OM ELF.
- `/bin/sh` points to `/bin/bash` in the initramfs.
- The dynamic loader path is `/lib64/ld-linux-k1om.so.2`.
- `/lib64/ld-linux-k1om.so.2` points to `ld-2.14.1.so`.
- `/lib64/libc.so.6` points to `libc-2.14.1.so`.
- `/etc/inittab`, `/etc/fstab`, `/etc/passwd`, and
  `/etc/ssh/sshd_config` are present.
- BusyBox supplies many standard commands through symlinks.
- No compiler or Python runtime was found in the first visible inventory.

## Reverse-Engineering Direction

Near-term work should stay observational:

1. Convert initramfs listings into package/component groups.
2. Map required boot files, init scripts, SSH setup, network setup, and loader
   assumptions.
3. Identify the minimal files needed for `hello-knc`.
4. Build a local sysroot from user-supplied MPSS, but keep it ignored.
5. Only after the stock uOS is understood, attempt tiny rootfs overlays.
