# Observed MPSS 3.4.10 KNC Kernel ABI

Read-only observations from the working card:

```text
uname: Linux unknownf48e38c1a578-mic0.home 2.6.38.8+mpss3.4.10 #1 SMP Thu Jan 12 16:38:30 EST 2017 k1om
kernel image SHA-256: ff85fbbcfb2de6cf67be8af27f10d325eecddb29fcd21405bf028ca0be119b1d
System.map SHA-256: e1e901bc5b2a96508ea1bb56ac6d4043e908c82f572f1abd53384a214410b530
```

The boot image is not directly ELF-readable. The card command line requires
ramfs root, `console=hvc0`, vnet DMA addresses, SCIF identity/address fields,
and the MPSS ramoops/memory parameters. A candidate must preserve initramfs
handoff and accept these parameters before any live test.
