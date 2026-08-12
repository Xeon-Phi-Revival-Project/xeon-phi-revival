# XPR-OS Glossary

- **Xeon Phi:** Intel's manycore accelerator product family.
- **Knights Corner (KNC):** the first Xeon Phi generation targeted by XPR-OS.
- **K1OM:** the native Knights Corner instruction-set and ABI target.
- **MIC:** Intel's Many Integrated Core terminology for Xeon Phi software.
- **MPSS:** Intel Manycore Platform Software Stack, the historical host-side
  management stack required by the tested RC6 path.
- **uOS:** the small Linux-based operating environment traditionally run on a
  Knights Corner card.
- **XPR-OS:** the Xeon Phi Revival project's K1OM boot and userspace
  environment.
- **Kernel:** the program that controls hardware and starts the operating
  environment.
- **Kernel module:** a loadable extension for a specific kernel, such as the
  MIC transport modules used by XPR-OS.
- **initramfs / CPIO:** an early boot filesystem stored as a CPIO archive,
  commonly compressed with gzip.
- **Base CPIO:** XPR-OS's outer early-boot CPIO container.
- **Bootstrap:** the small first userspace that prepares the card for the final
  XPR root.
- **PID 1:** the first userspace process. XPR-OS validates its final `/sbin/init`
  as PID 1.
- **switch_root:** the transition from bootstrap filesystem to final root.
- **SCIF:** a MIC communication facility; it is part of the historical KNC
  software environment.
- **micveth:** MPSS virtual Ethernet used for host-to-card networking.
- **sysroot:** a target filesystem tree used while cross-compiling.
- **cross-compiler / toolchain:** compiler, assembler, linker, headers, and
  libraries used to build K1OM programs from an x86-64 host.
- **vermagic:** kernel-module metadata describing the kernel build it expects.
- **Dropbear:** the lightweight SSH server used in the validated XPR-OS path.
- **corresponding source:** source, changes, configuration, and build material
  supplied for a distributed binary under applicable licenses.
- **reproducible build:** a build designed to recreate the same artifact from
  declared inputs.

