# Xeon Phi Revival Project Development Plan

Last updated: 2026-07-20

This document is the development roadmap for new Xeon Phi software work. Keep
the existing troubleshooting record, `xeon_phi_f2_research_summary.md`, as the
hardware and MPSS recovery log. This file is for forward-looking software,
toolchain, runtime, and GitHub project planning.

## Project Identity

- Project name: Xeon Phi Revival Project
- GitHub organization: https://github.com/Xeon-Phi-Revival-Project
- Initial hardware target: Intel Xeon Phi 5110P, Knights Corner PCIe
  coprocessor
- Existing local reference hardware: 71S1P/B1PRQ-7110-family Knights Corner
  coprocessor, currently documented separately because it showed reset/F2
  behavior
- Baseline 5110P public specs from Intel ARK: x100 product family, formerly
  Knights Corner, 60 cores / 240 hardware threads, 1.05 GHz base frequency,
  30 MB L2 cache, 8 GB ECC GDDR5, 16 memory channels, 320 GB/s maximum memory
  bandwidth, 225 W TDP, PCIe 2.0, passive cooling, 64-bit instruction set with
  Intel IMCI extensions, Q4 2012 launch, discontinued/end-of-servicing status.

## Guiding Principles

- Treat this as a preservation and revival project, not just a one-off install.
- Keep troubleshooting history separate from development plans.
- Prefer repeatable scripts over hand-written one-time procedures.
- Preserve logs, checksums, command output, and host/card identity for every
  meaningful test.
- Do not redistribute Intel MPSS packages, firmware, proprietary sysroots, or
  Intel compiler binaries unless redistribution rights are clearly established.
- Public repositories should use a bring-your-own-MPSS model: scripts and
  documentation are public, while users provide their own local MPSS archives.
- Avoid firmware writes, force-flash, recovery flashing, or destructive hardware
  actions unless there is a separate, explicit recovery plan.

## Current Known Context

- Local MPSS material exists for MPSS 3.4.10 and 3.6.1 Linux tarballs.
- Local MPSS 3.8.6 backup material exists from prior work.
- MPSS 3.4.10 and 3.6.1 packages contain `docs/license.txt` and an MPSS license
  RPM.
- The MPSS license supports internal use and limited object-code distribution
  under Intel's EULA for Intel products, but it is not a permissive open-source
  license for publishing Intel's MPSS contents.
- The Archive.org metadata for the MPSS collection is not enough to override the
  package-internal Intel license.
- The prior 71S1P/B1PRQ card repeatedly failed at GDDR training / POST F2 and is
  not the right basis for software bring-up until stable initialization is
  restored.
- The incoming 5110P should be treated as a fresh hardware target and verified
  from first principles.

## Minimum True Ubuntu Port Definition

Do not describe the project output as a true Ubuntu K1OM port until the minimum
base can be rebuilt, installed, tested, and rolled back from public-safe
manifests.

The smallest acceptable true-port target is:

- `k1om` architecture metadata for dpkg/Ubuntu package tooling.
- A local Ubuntu-style archive with `binary-k1om` indexes.
- Ubuntu-source libc/loader runtime packages for `libc6`, `libgcc1`, `libm6`,
  `libpthread0`, `libdl2`, `librt1`, and `libutil1`.
- Real native K1OM `dpkg` installing the essential package set into a clean
  root or isolated target.
- Native K1OM APT updating from the local archive and installing packages
  through real dpkg.
- A coherent root/profile with `/etc/os-release`, package status, `/dev`,
  `/proc`, `/sys`, `/tmp`, basic shell commands, `python3`, and rollback to
  stock MPSS.
- On-card smoke tests for package manager behavior, libc, pthread, Python,
  file I/O, shell commands, and rollback.

Current status: the package-manager and Python/userland lanes are already
substantially proven. The narrowest remaining blocker is replacing the
MPSS-derived runtime dependency with a project-built Ubuntu-source libc/loader
stack; the active eglibc/glibc probe has reached K1OM `libc.so` and `ld.so`,
with `libpthread.so` still unresolved.

## Knowledge Base From Reference Materials

This section captures reusable facts from the local PDFs, Intel community
thread, and local MPSS package inspection. It is a working knowledge base for
the public project, not a substitute for the separate troubleshooting log.

### Local Extracted References

Current searchable reference extracts in this project folder:

```text
k1om-psabi-1.0.extracted.txt
hpc_xeon_phi_book.extracted.txt
intel_xeon_phi_coprocessor_architecture_and_tools_the_rezaur_rahman_1st_ed_pt_20.extracted.txt
intel_xeon_phi_coprocessor_high_performance_programming_james_jeffers_james_rein.extracted.txt
parallel_programming_and_optimization_with_intel_xeon_phi_andrey_vladimirov_ryo_.extracted.txt
327364-001-jul24_djvu.txt
```

Reference roles:

- K1OM psABI: compiler, linker, loader, syscall, calling convention, unwind, and
  ELF details.
- Intel Knights Corner Instruction Set Reference Manual, document 327364-001
  from July 24, 2012: instruction-set, encoding, vector/mask, scalar subset,
  CPUID, and exception-behavior reference for compiler and assembler work.
  Treat the Archive.org copy as reference material only; do not redistribute the
  PDF/text in public repositories unless a separate license review allows it.
- Intel community `lfence` thread: inline assembly portability warning and KNC
  memory-fence guidance.
- Rahman, *Intel Xeon Phi Coprocessor Architecture and Tools*: practical
  architecture, MPSS tools, native execution, Windows/Linux notes, debugging,
  and system software overview.
- Jeffers/Reinders, *Intel Xeon Phi Coprocessor High Performance Programming*:
  MPSS Linux boot process, root filesystem configuration, `micctrl`, SCIF/COI,
  MPI, offload, native execution, and runtime environment details.
- Wang/Zhang/Shen et al., *High-Performance Computing on the Intel Xeon Phi*:
  native-mode examples, SCIF API notes, boot/uOS overview, and historical MPSS
  installation context.
- Colfax, *Parallel Programming and Optimization with Intel Xeon Phi*: practical
  optimization rules, OpenMP/MPI/vectorization examples, thread affinity, MKL,
  and performance tuning.
- Apress GitHub companion repository for Rahman's book:
  reference-only sample source for chapter examples. Do not vendor, copy, or
  base public project code directly on it unless its licensing is reviewed for
  the exact intended use.
- JeffersonLab QPhiX: open-source QCD solver library with Xeon Phi/MIC support.
  Useful as a real-world case study for MIC build options, code generation,
  thread/core tuning, data layout, tests, and performance-oriented project
  structure.
- Intel Xeon Phi Developer's Quick Start Guide for MPSS 3.4: useful for first
  bring-up details, supported host OS/kernel combinations, native compilation,
  default `mic0` networking, `micnativeloadex`, and MPSS tool inventory.
- Lenovo/IBM Xeon Phi Windows driver pages: useful archive-index references for
  Windows MPSS packages and readmes, but not the first path for Linux native
  KNC/Python/uOS development.
- Seiler et al., *Larrabee: A Many-Core x86 Architecture for Visual
  Computing*, ACM Transactions on Graphics 27(3), Article 18, August 2008:
  useful historical architecture context for the pre-Xeon-Phi/Larrabee lineage,
  especially in-order x86 cores, wide vector processing, coherent cache,
  scatter/gather, software scheduling, and tiled software rendering. Treat as
  background/reference only, not as a direct KNC programming manual.
- IBM Spectrum LSF 10.1 documentation for defining Intel Xeon Phi resources:
  useful as a cluster-scheduler view of MIC cards. It documents resource names
  and metrics such as `nmics`, `mic_ncores*`, `mic_temp*`, `mic_freq*`,
  `mic_freemem*`, `mic_util*`, and `mic_power*`. Use this as inspiration for
  project manifests, monitoring, and future batch-run wrappers, not as a
  requirement to use LSF.
- ACCRE `accre/Intel-Xeon-Phi` GitHub repository: useful as a practical
  cluster-user example set for native, offload, Python/NumPy, R, MATLAB, and
  LAMMPS Phi workflows under SLURM. Treat as reference-only until repository
  licensing is checked; use the ideas and write original scripts.
- Intel Community OpenCL threads: useful for archive-indexing the last known
  KNC/x100 OpenCL path. Multiple forum posts identify deprecated OpenCL Runtime
  14.2 as the last Intel OpenCL runtime with Xeon Phi coprocessor/MIC support,
  with package names such as `opencl_runtime_14.2_x64_4.5.0.8.tgz` and
  `opencl-1.2-intel-mic-4.5.0.8`. Treat as historical/experimental, not a main
  project direction.
- Wikipedia Xeon Phi page and references: useful as an index into product-line
  history and source discovery, but not as a primary technical source. The page
  mixes Knights Ferry, Knights Corner/x100, Knights Landing/x200, and Knights
  Mill details; always reduce claims back to 5110P/KNC-specific Intel ARK,
  datasheet, psABI, instruction-reference, MPSS, or hardware-test evidence.
- Intel Community MIC FAQ and resources posts: useful reminders that KNC is not
  binary-compatible with prior Intel processors in the practical software-stack
  sense, that the programming rule is "scale and vectorize," and that old Intel
  resource indexes named MPSS source downloads, GDB, the K1OM psABI,
  instruction-set reference, compiler methodology, and performance-monitoring
  documents.
- PGI/CUG 2013 paper, *Tesla vs. Xeon Phi vs. Radeon: A Compiler Writer's
  Perspective*: useful compiler-portability background for accelerator
  abstraction, OpenACC/OpenMP-style directive models, and why KNC needs both
  MIMD thread parallelism and SIMD vector parallelism.
- Intel Xeon Phi Coprocessor Datasheet, document 328209-002EN, June 2013:
  useful as a hardware reference for board subsystems, PCIe/power connector
  requirements, passive/active cooling assumptions, SMC-managed sensors,
  thermal shutdown behavior, and SCIF-accessible telemetry.

### External Source-Code Reference Policy

External repositories are not automatically project dependencies.

The Apress companion repository
`Apress/intel-xeon-phi-coprocessor-architecture-tools` should be treated as
reference-only. Its top-level license is not cleanly permissive for all public
revival-project uses, and the repository includes compiled artifacts. Use it to
understand examples, then write original project tests and scripts from scratch.
If any source is ever reused, preserve notices and review the exact file-level
and repository-level license first.

QPhiX is a better model for reusable engineering patterns because it is a real
Xeon Phi-era HPC library with public source, build configuration, tests, and
documented MIC options. Still, treat it as a reference unless the project
explicitly adds it as a dependency after checking its license and dependency
stack.

The Larrabee ACM paper is related because Knights Corner inherited many of the
same design instincts: many simple in-order x86-derived cores, a wide vector
unit, coherent cache, scatter/gather-oriented irregular-data support, and
software-managed scheduling. It is not a substitute for the K1OM psABI, MPSS
docs, or KNC instruction reference because Larrabee was a visual-computing
architecture rather than the shipping Xeon Phi 5110P coprocessor environment.
Use it for design intuition and demo ideas such as tiled renderers, work queues,
and cache-aware software graphics.

### K1OM ABI And Binary Interface

Facts from `k1om-psabi-1.0.pdf`:

- K1OM is a 64-bit System V-style ABI variant for Knights Corner, not normal
  generic `x86_64`.
- ELF uses 64-bit little-endian objects with machine type `EM_K1OM` value 181.
- Linux dynamic linker path is expected to be `/lib64/ld-linux-k1om.so.2`.
- The data model is LP64: pointers and `long` are 8 bytes.
- `long double` storage is 16 bytes, with 80-bit content plus padding.
- KNC has 16 general-purpose registers, 32 512-bit vector registers, and 8
  vector mask registers in the ABI model.
- Integer/pointer arguments follow the familiar System V register order:
  `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9`.
- Vector arguments use `%zmm0` through `%zmm7`.
- Callee-saved general registers are `%rbp`, `%rbx`, and `%r12` through `%r15`.
- `__m512` is 64 bytes and requires 64-byte alignment.
- The stack is 16-byte aligned in normal cases and 64-byte aligned when `__m512`
  values are passed on the stack.
- User code has a 128-byte red zone, but kernel code must not rely on it.
- Syscalls use the `syscall` instruction, with syscall number in `%rax` and
  arguments in `%rdi`, `%rsi`, `%rdx`, `%r10`, `%r8`, and `%r9`.
- DWARF/unwind support includes KNC vector and mask registers, which matters for
  C++, Python extension debugging, thread unwinding, and exception handling.

Project implications:

- Any independent compiler or assembler work must treat K1OM as its own ABI
  target, not merely `x86_64` with wider vectors.
- The first open-toolchain checks should verify `EM_K1OM`, relocation support,
  TLS behavior, dynamic linking, unwind records, and the loader path.
- CPython/native-extension packaging must preserve the correct dynamic loader,
  shared-library search paths, pthread/TLS behavior, and stack alignment.
- Intel's old MIC FAQ says Knights Corner binaries are not completely
  compatible with binaries built for earlier Intel processors because KNC
  combines new hardware features, the KNC software stack, KNC vector
  instructions, and four-way multithreading. Treat this as another reason to
  test real `EM_K1OM` binaries instead of assuming generic x86_64 binaries or
  libraries can be reused.

### Knights Corner Instruction Set Reference

Facts from Intel document 327364-001, *Knights Corner Instruction Set
Reference*, July 24, 2012:

- KNC has a 64-bit execution environment similar to Intel 64, but it is still a
  subset and extension, not ordinary desktop/server x86_64.
- KNC adds 32 512-bit vector registers, `zmm0` through `zmm31`.
- KNC adds 8 vector mask registers, `k0` through `k7`; `k0` behaves as the
  no-mask/write-all case for masked vector operations.
- The vector ISA is IMCI-era KNC, not modern AVX-512, even though both expose
  512-bit vector ideas.
- The manual documents gather/scatter, vector prefetch, masked execution,
  swizzles, up-conversion/down-conversion, per-instruction rounding override,
  and suppress-all-exceptions behavior.
- KNC vector floating-point exceptions update MXCSR flags but do not trap,
  because unmasked SIMD floating-point exceptions are forced disabled through
  the DUE MXCSR bit.
- KNC supports most GPR and x87 scalar instructions in 64-bit mode, but not all
  Intel 64 instructions.
- Unsupported scalar/vector families include MMX-register instructions,
  XMM-register instructions, YMM-register instructions, `CMPXCHG16B`,
  `MONITOR`, `MWAIT`, `PAUSE`, `SYSENTER`, and `SYSEXIT`.
- The manual's scalar limitation table lists `CMOV` and x87 conditional move /
  compare forms as unsupported, while its CPUID feature table later describes
  the CMOV feature bit as supported. Treat this as a documentation conflict
  that must be resolved by real hardware tests before compiler assumptions are
  locked in.
- KNC does not implement `SFENCE` or `MFENCE`. The manual recommends fencing
  around certain weakly ordered streaming/non-globally-ordered store patterns,
  but the actual fence sequence must be KNC-safe.
- CPUID feature reporting has quirks; the manual notes POPCNT is supported even
  though its CPUID bit reports unsupported.

Project implications:

- Add a machine-readable KNC instruction/support matrix under
  `docs/knowledge-base/` or `toolchains/open-toolchain/`.
- Build tiny on-card instruction probes before trusting ambiguous manual or
  CPUID behavior, especially for `CMOV`, POPCNT, fences, atomics, and any
  compiler-generated instruction that a generic x86_64 backend may emit.
- Teach the source scanner to flag MMX, XMM/SSE, YMM/AVX, `CMPXCHG16B`,
  `PAUSE`, `SYSENTER`, `SYSEXIT`, `SFENCE`, `MFENCE`, and generic x86_64 inline
  assembly paths.
- For a future compiler/backend, keep instruction selection, assembler
  acceptance, CPUID feature policy, and runtime dispatch separate so KNC quirks
  can be tested and documented independently.
- For Python and Java, this reference matters mostly through dependencies and
  generated code: atomics, OpenSSL/libffi assembly, JITs, spin waits, lock-free
  code, and vectorized native extensions must avoid unsupported instruction
  paths.

### MPSS Licensing Boundary

Facts from local MPSS package inspection:

- MPSS 3.4.10 and 3.6.1 tarballs contain `docs/license.txt` and an
  `mpss-license-*.rpm`.
- The inspected licenses are Intel "Internal Use and Object Code Distribution"
  agreements with EULA terms, not permissive open-source licenses.
- Archive.org metadata is not sufficient permission to republish Intel MPSS
  package contents.
- The local MPSS 3.8.6 backup did not show an obvious license/EULA filename in
  the earlier archive listing, so its license status must not be guessed.
- Vendor driver download pages may link to Intel Registration Center or
  third-party package URLs. Treat those pages as metadata sources unless the
  actual package and license are inspected locally.

Project rule:

- Public repositories should publish scripts, recipes, patch files, metadata,
  checksums, compatibility notes, and logs.
- Public repositories should not include Intel MPSS tarballs, extracted MPSS
  sysroots, Intel uOS images, Intel firmware, Intel compiler binaries, or other
  proprietary payloads unless a separate redistribution review proves that is
  allowed.

### MPSS And uOS Boot Model

Facts from the books:

- Knights Corner coprocessors run a Linux-based coprocessor OS, commonly called
  the uOS or micro OS.
- The card is managed by host-side MPSS, not by a normal PC BIOS/UEFI boot.
- The host driver and `mpssd` daemon prepare the kernel command line and boot
  image.
- `mpssd` writes boot control through `/sys/class/mic/mic*/state`.
- The boot request format includes `boot:linux:<image>`.
- The host driver injects the Linux image into coprocessor memory and tells the
  card to execute it.
- The default Linux image path documented in the MPSS-era material is
  `/lib/firmware/mic/uos.img`.
- The initial RAM disk contains the early tools/modules needed to reach the real
  root filesystem.
- The root filesystem may be built as a RAM image, a static RAM image, NFS,
  SplitNFS, or InitRD-style debug environment depending on MPSS configuration.
- `RamFS` builds and downloads a compressed cpio root filesystem at boot.
- `StaticRamFS` uses a prebuilt image and requires `micctrl updateramfs` when
  changed.
- `NFS` and `SplitNFS` are important for development because they allow a larger
  host-side root tree to be mounted by the coprocessor.
- The initial RAM disk root mode is for debugging and only contains minimal
  tools.

Project implications:

- The Ubuntu 24.04 uOS track should begin with root filesystem experiments, not
  a kernel replacement.
- The safest custom-userland path is likely:

  ```text
  stock MPSS kernel/uOS boot path
  project-built KNC root filesystem tree
  NFS or SplitNFS during development
  later compressed RAM image if needed
  ```

- The project should build rootfs inventory tools before building a replacement
  rootfs.
- The rootfs lane should document `BaseDir`, `CommonDir`, `MicDir`, and
  `Overlay` behavior so project-added files survive MPSS updates without
  modifying Intel-owned base directories.

### Native Execution Workflow

Facts from the books:

- Native execution is Linux-only in the older documented environment. Windows
  MPSS can support offload-style development, but native SSH-style workflows are
  primarily documented for Linux hosts.
- In native mode, the Phi behaves like another small Linux node reachable over
  MPSS virtual networking.
- The basic workflow is:

  ```text
  source Intel compiler environment
  build with icc/icpc/ifort and -mmic
  copy binary to mic0 with scp
  ssh mic0
  run the binary on the card
  ```

- `micnativeloadex` can launch a MIC binary from the host and copy dependent
  libraries automatically, which may be useful for smoke tests and demos.
- Native OpenMP binaries often require the MIC-side runtime libraries to be
  present on the card or reachable through `LD_LIBRARY_PATH`.
- Useful environment variables include `LD_LIBRARY_PATH`, `MIC_LD_LIBRARY_PATH`,
  `OFFLOAD_REPORT`, `KMP_AFFINITY`, `MIC_KMP_AFFINITY`, and
  `KMP_PLACE_THREADS`.
- Intel's MPSS 3.4 quick-start guide gives a concrete native OpenMP workflow:
  build with `icc -mmic -vec-report3 -openmp`, copy the binary to `mic0:/tmp`,
  copy `libiomp5.so` if needed, set `LD_LIBRARY_PATH=/tmp` on the card, set
  stack size with `ulimit -s unlimited` if required, then run the binary.
- The same guide documents `micnativeloadex` as a host-side way to copy a native
  MIC binary and library dependencies to a specified coprocessor and execute it.
- Default MPSS virtual network examples in the quick-start guide are `mic0` at
  `172.31.1.1` and host-as-seen-from-card at `172.31.1.254`, with `mic1` using
  the next subnet.

Project implications:

- The first toolchain repository should include both manual `scp`/`ssh` helpers
  and a `micnativeloadex`-based runner if available.
- The smoke-test harness should archive the exact host compiler environment,
  binary type, loader path, library paths, `micctrl` status, and run output.
- Native execution is the right first path for Python and Doom because it avoids
  offload compiler extensions while proving ordinary Linux process behavior.

### MPSS Tools And Safe Bring-Up

Useful tools documented across the materials:

- `micinfo`: inventory, firmware/flash version, coprocessor OS version,
  thermal/SMC details, and hardware identity.
- `miccheck` or `micchek`: health and consistency checks, depending on MPSS
  version naming.
- `micctrl`: boot, shutdown, reset, status, user configuration, rootfs
  configuration, NFS setup, host keys, and RAM filesystem update.
- `micnativeloadex`: launch native MIC binaries and stage dependencies.
- `micsmc`: management/status interface in some MPSS environments.
- `micflash` or `mpssflash`: firmware/flash query and update utilities.

Scheduler/cluster-management references:

- IBM Spectrum LSF models Xeon Phi cards as host-based consumable resources for
  Linux clusters.
- Its documented required resource is `nmics`, the number of MIC devices.
- Optional per-card metrics include core count, temperature, frequency, free
  memory, utilization, and total power.
- LSF's MIC support expects Knights Corner hardware, Intel MPSS 2.1.4982-15 or
  later, and Intel Xeon Phi offload runtime/tools.
- The LSF page notes that checkpoint/restart, preemption, and resource duration
  or decay are not supported for this resource model.

Project implications:

- Add the LSF metric names as a reference schema for future `micinfo`/`micsmc`
  parsers and hardware manifests.
- If the project later builds a small queue/runner for repeated tests, model
  card allocation explicitly: reserve a card, run the job, collect telemetry,
  release the card.
- Do not require LSF for the revival project; local scripts should work first.
- The ACCRE example repository shows a SLURM-style user-facing model: request a
  MIC partition, run native/offload examples, and use Intel MKL automatic
  offload for environments such as Python/NumPy, R, and MATLAB. This is useful
  for documentation patterns, but the exact cluster software stack and hardware
  are site-specific.

Hardware datasheet notes:

- The Xeon Phi coprocessor board includes MIC silicon, GDDR5 memory, an SMC,
  thermal sensors, voltage regulators, PCIe connectivity, and auxiliary power
  connectors.
- The datasheet states that 300 W SKUs need both 2x4 and 2x3 auxiliary power
  connectors in addition to PCIe slot power, while 225 W SKUs may be powered
  through the PCIe connector plus the 2x4 connector.
- Passive SKUs depend on the host/server airflow solution; do not treat a
  passive card as bench-safe without a deliberate cooling plan.
- The SMC can expose telemetry over the host-side SCIF interface, including SMC
  firmware revision, UUID, fan tachometer/PWM data where present, SEL data,
  voltage rail monitoring, discrete temperature sensors, `Tcritical`,
  `Tcontrol`, `Tcurrent`, thermal-throttle duration, inlet/outlet derived
  values, thermal performance status, and the 32-bit POST register.
- The SMC reports sensor states such as normal, upper critical, lower critical,
  and inaccessible.
- A catastrophic thermal shutdown asserts `THERMTRIP_N`; the SMC forces fans to
  full speed where applicable and shuts down voltage regulators. Removing power
  is required to reset the microcontroller to a known start point.

Project implications:

- Hardware manifests should record power-cabling state, passive/active cooling
  arrangement, airflow assumptions, SMC firmware revision, UUID, POST register,
  temperatures, throttle counters, voltage/rail status where available, and
  whether any sensor reports inaccessible.
- Treat telemetry collection as a normal bring-up artifact, not as a later
  nice-to-have.
- Never use ACCRE's cluster node specifications as the 5110P baseline; their
  published production nodes describe 61-core, 1.24 GHz, 15.8 GB Phi cards,
  which are not the same as the incoming 5110P.

MPSS 3.4 quick-start host compatibility notes:

- The guide lists MPSS 3.4-era host targets as RHEL 6.3, 6.4, 6.5, 6.6,
  RHEL 7.0, SLES 11 SP2, and SLES 11 SP3, with specific kernel versions.
- It warns that Red Hat installation may automatically update to a newer kernel,
  which can break use of a prebuilt host driver and require rebuilding the MPSS
  host driver for the active kernel.
- The guide's MPSS/flash table lists MPSS 3.4 with flash version `2.1.02.0390`,
  MPSS 3.3 with `2.1.02.0390`, MPSS 3.2/3.1 with `2.1.03.0386`, and older KNC
  gold/update releases with earlier flash versions.

Safety rules:

- Prefer `micctrl shutdown` where possible instead of reset.
- Treat firmware/flash instructions in books as historical reference until a
  separate recovery plan exists.
- Do not flash, force-flash, erase, or recovery-flash as part of normal
  software development.
- `micinfo`/`miccheck`/status collection is appropriate for baseline capture;
  firmware writes are not.
- Always dynamically discover the card instead of assuming a PCI bus address.
- Treat the quick-start guide's "update flash" install step as historical
  guidance, not an automatic project action. Inventory first; flash only with a
  separate recovery plan.

### SCIF, COI, Networking, And File Access

Facts from the references:

- SCIF abstracts communication over PCIe between the host and MIC node.
- SCIF is symmetric: APIs exist on both host and card sides.
- SCIF supports user-space and kernel-space use, but it is a data-transfer
  service, not a process-control layer.
- COI provides offload process/control infrastructure above the lower transport.
- MPSS virtual Ethernet and TCP/IP are built on top of lower MPSS transport
  layers.
- SSH, `scp`, sockets, NFS, MPI, and related workflows exist because the
  coprocessor has a Linux OS plus MPSS virtual networking.
- NFS is useful for native development because binaries, libraries, and input
  data can live on the host, but it may be slower than copying
  performance-sensitive data into coprocessor RAM.

Project implications:

- Use SSH, `scp`, sockets, and NFS first because they are easier to debug and
  document.
- Investigate SCIF later for high-performance host/card messaging, Doom frame
  streaming, and custom runtime services.
- COI is useful background for offload support, but not required for the first
  native Python or Doom milestone.

### Compiler And Inline Assembly Gotchas

Facts from the Intel community `lfence` thread and books:

- KNC does not support every instruction that normal `x86_64` code may assume.
- In the `lfence` discussion, Intel guidance said a locked atomic operation is a
  full fence, making a following `lfence` redundant in that example.
- KNC is in-order, so many fence patterns from out-of-order x86 code are not
  needed in the same way.
- For handwritten non-globally-ordered stores, the referenced Intel guidance
  suggested a full fence sequence such as a locked add on the stack.
- A compiler memory barrier such as an empty volatile asm with `"memory"`
  clobber is not the same thing as a hardware fence.
- Some projects check only `__x86_64__` and then emit x86_64 inline assembly
  that is invalid on MIC/KNC.
- Protobuf/Supersonic-era porting notes showed that build systems may need to
  recognize `k1om` separately and disable ordinary x64 assembly paths.
- The Colfax material emphasizes that KNC supports IMCI, not AVX-512 as used by
  later Knights Landing and newer CPUs.
- QPhiX documents MIC builds through Autoconf by selecting `--enable-proc=MIC`,
  using Intel MPI compiler wrappers such as `mpiicpc`/`mpiicc`, passing `-mmic`,
  enabling OpenMP, and forcing cross-compile mode with different `--host` and
  `--build` values.
- QPhiX notes that GCC/Clang may need `-Drestrict=__restrict__` for C++ code
  that assumes Intel-style `restrict` handling.
- QPhiX uses generated kernels, which is a useful pattern for KNC: generate
  architecture-specific code from a higher-level description instead of hand
  maintaining every vector variant.

Project implications:

- Add a portability rule to all ports:

  ```text
  x86_64 does not imply KNC-safe assembly
  k1om must be handled as a distinct target
  IMCI is not AVX-512
  ```

- For Python dependencies, watch for inline assembly in OpenSSL, libffi,
  sqlite, compression libraries, atomics, threading primitives, and JIT-related
  code.
- Early CI/build scripts should include a source scanner for suspicious inline
  assembly and target macros.
- The scanner should include a KNC instruction/support denylist and an
  allow/unknown list sourced from document 327364-001 plus hardware probes.
- Add Intel's old performance-monitoring document to the archive/search list if
  it can be found; it may help turn raw PMU counters into useful benchmark
  metrics later.
- Autoconf-based ports should have a documented KNC cross-compile recipe and a
  checked-in `config.site` where possible.
- Code-generation experiments may be a better long-term compiler-adjacent path
  than immediately writing a full compiler backend.

### Performance Rules That Matter

Facts from the optimization references:

- KNC performance depends on both thread-level parallelism and vectorization.
- A single scalar thread is a poor use of the card.
- Each core benefits from multiple hardware threads, especially to hide in-order
  pipeline stalls.
- Compute-bound workloads often benefit from all cores and multiple threads per
  core.
- Memory-bandwidth-bound workloads may do better with fewer threads per core and
  scatter-style affinity.
- 64-byte alignment is a recurring requirement for efficient vector loads,
  stores, DMA-friendly transfers, and avoiding expensive peel/remainder paths.
- Useful optimization techniques include padding to vector length, aligned
  allocation, `restrict`, `#pragma ivdep`, `#pragma vector aligned`,
  vectorization reports, thread affinity, and explicit benchmarking.
- QPhiX exposes practical MIC tuning knobs worth copying as concepts, not code:
  processor selection, SOA length, OpenMP enablement, aligned allocation, block
  sizes, core count, SMT/thread-grid settings, padding factors, precision
  selection, and timing iteration counts.
- QPhiX's README gives concrete Xeon Phi examples such as using MIC mode,
  SOA length 8, block sizes around 4 by 4 for MIC tests, and core counts
  matching the card model, such as 59 for 5110P-class hardware.

Project implications:

- Python itself should be treated as orchestration, not the performance layer.
- High-value Python work is native extension modules that use OpenMP/pthreads
  and vectorized C/C++ kernels.
- Doom should first prove correctness and determinism, then experiment with
  parallel render loops.
- Larrabee's software-rendering paper is a useful conceptual reference for a
  future Doom renderer experiment: split the framebuffer into tiles/bins, keep
  work units large enough to amortize synchronization, and use dynamic work
  scheduling instead of trying to make one scalar render loop magically span all
  cores.
- The PGI compiler-writer paper reinforces the same rule from a portability
  angle: KNC programs must expose both enough independent work to fill cores and
  hardware threads, and enough contiguous/vector-friendly work for 512-bit
  SIMD.
- Benchmarks should report thread count, affinity, data alignment, vectorization
  report status, and whether data is local RAM or NFS-backed.
- Benchmark manifests should also record problem size, blocking shape, SOA/data
  layout, padding choices, precision, and whether kernels were generated or
  handwritten.

### Python Porting Implications

The books do not provide a direct Python port, but they do define the
environment Python must fit into.

Practical Python assumptions:

- Start with native execution on the stock MPSS uOS.
- Build a KNC sysroot from user-provided MPSS locally.
- Cross-build CPython and dependencies with K1OM-aware compiler wrappers.
- Stage Python through NFS or a project overlay before attempting a compact
  boot image.
- Keep dynamic-library paths explicit.
- Disable optional modules first, then restore them one at a time.
- Watch for incorrect `x86_64` assembly assumptions in dependencies.
- Treat Python multiprocessing and threading as tests of Linux process,
  pthread, signal, TLS, filesystem, and memory behavior.

Good first Python milestone:

```text
stock MPSS uOS
native k1om CPython starts
import sys, os, math works
ctypes works if libffi is available
compileall can process the standard library
results and missing modules are archived
```

### OpenCL Runtime Notes

OpenCL is a secondary compatibility/demo lane, not the main revival path.

Known references:

- Intel Community answers identify OpenCL Runtime 14.2 as the latest deprecated
  Intel OpenCL runtime that supports Knights Corner/Xeon Phi x100 MIC
  coprocessors.
- The concrete package names seen in old threads are
  `opencl_runtime_14.2_x64_4.5.0.8.tgz` and
  `opencl-1.2-intel-mic-4.5.0.8`.
- A 2016 Intel Community answer says the `opencl-1.2-intel-mic-4.5.0.8` RPM was
  the MIC package normally installed for OpenCL 1.2 on Xeon Phi.
- The OpenCL runtime was reported as OpenCL 1.2-era support; later Intel SDKs
  generally saw only the host CPU for KNC.
- One Intel Community answer says OpenCL Runtime 14.2 was validated with MPSS
  3.3. Other release-note mirrors mention MPSS 3.2 or 3.2.3, so treat the exact
  MPSS compatibility as something to test in an isolated environment.
- OpenCL samples may need to check for `CL_DEVICE_TYPE_ACCELERATOR`, not just
  GPU or CPU devices, to see the MIC.

Project implications:

- Do not build the main Python/Doom/compiler plan around OpenCL.
- If a copy of `opencl_runtime_14.2_x64_4.5.0.8.tgz` is found, inspect its
  license/EULA before adding any public-project instructions beyond
  bring-your-own-runtime metadata.
- Add OpenCL to the archive index as a legacy optional runtime with package
  name, expected RPM names, MPSS compatibility notes, and known failure modes.
- A useful demo would be a tiny `clinfo`/device-enumeration probe plus one
  simple kernel, archived with `micinfo`, MPSS version, ICD files, library
  paths, and whether the MIC appears as `CL_DEVICE_TYPE_ACCELERATOR`.

### Java/JVM Implications

The references did not show a direct Java/OpenJDK path.

Practical Java assumptions:

- Java is likely harder than Python because a JVM brings a larger runtime,
  signal handling, threading, atomics, memory model, JIT/interpreter choices,
  and more architecture-specific code.
- A realistic first JVM experiment would be an interpreter-only or zero/JIT-less
  path, not a full optimizing JIT.
- Java should come after C smoke tests, Python, and rootfs/package staging are
  understood.

### Doom Porting Implications

The references do not discuss Doom directly, but they support a practical Doom
path:

- Build a native KNC Linux Doom port first.
- Prefer a small portable C source port such as DoomGeneric.
- Use Freedoom for redistributable test data.
- Start with headless timedemo/checksum mode.
- Avoid audio and direct display at the first milestone.
- Render into an in-memory frame buffer and stream frames to the host later over
  sockets, SSH pipe, or eventually SCIF.
- Use Doom as a real runtime test for file I/O, memory allocation, deterministic
  CPU execution, timing, and optional parallel rendering.

## Proposed GitHub Structure

Start with one public monorepo in the Xeon Phi Revival Project organization:

```text
xeon-phi-revival
```

Reasoning:

- The early work shares too much infrastructure to split immediately.
- Toolchain setup, MPSS import, sysroot generation, run harnesses, ABI tests,
  Python, Doom, and uOS experiments all depend on the same baseline.
- A monorepo makes it easier to keep manifests, logs, docs, and scripts in sync.
- Separate repositories can be split out later after the interfaces stabilize.

Initial monorepo layout:

```text
docs/
  knowledge-base/
  bring-up/
  licensing/
  hardware/
  uos/

manifests/
  experiments/
  hardware/
  mpss/
  sysroots/

tools/
  mpss-import/
  sysroot/
  deploy/
  runners/
  source-scan/

tests/
  abi/
  smoke/
  runtime/
  performance/

ports/
  python/
  doom/

uos/
  inventory/
  rootfs/
  ubuntu-compat/

toolchains/
  intel-mic/
  open-toolchain/
```

### Four Technical Lanes

The monorepo should keep work separated into four lanes:

1. Hardware and MPSS bring-up

   Scope:
   - passive card inventory
   - safe MPSS initialization
   - `micinfo`, `micctrl`, logs, and boot status
   - host compatibility notes
   - firmware/flash inventory only unless separately authorized

2. Toolchain and ABI validation

   Scope:
   - sysroot extraction from user-provided MPSS
   - compiler wrappers and CMake/toolchain files
   - native `k1om` smoke tests
   - ABI tests for ELF, loader, calling convention, TLS, signals, pthreads,
     dynamic linking, stack alignment, and unwind behavior
   - independent GCC/binutils/LLVM investigation after the Intel-toolchain path
     can run real tests

3. Runtime and application ports

   Scope:
   - CPython port
   - dependency recipes
   - native extension examples
   - Doom/Freedoom demo
   - small benchmark and runtime probes

4. uOS and userland research

   Scope:
   - stock uOS inventory
   - rootfs overlays
   - NFS/SplitNFS development roots
   - Ubuntu-compatible userland experiments
   - Ubuntu-derived package rebuilds
   - true Ubuntu port investigation only after lower levels work

### First-Class Deliverables

Do not treat tests and logs as side effects. They are project outputs.

Required deliverables:

- ABI test suite under `tests/abi/`.
- Smoke test suite under `tests/smoke/`.
- Runtime behavior tests under `tests/runtime/`.
- Experiment manifests under `manifests/experiments/`.
- Hardware manifests under `manifests/hardware/`.
- MPSS archive manifests under `manifests/mpss/`.
- Sysroot manifests under `manifests/sysroots/`.
- A source scanner for accidental generic-`x86_64` inline assembly assumptions.
- A KNC instruction/support matrix covering known-supported, known-unsupported,
  and hardware-probe-required instructions.
- Reproducible run logs for each important hardware/software milestone.

Every meaningful experiment should have a small manifest:

```yaml
id: 2026-07-20-example
hardware: 5110P-or-other-card-id
host_os: unset
mpss_version: unset
kernel: unset
toolchain: unset
sysroot: unset
action: unset
expected_result: unset
actual_result: unset
artifacts:
  - unset
safe_to_repeat: true
notes: unset
```

### Future Split-Out Repository Names

### `knc-toolchain-lab`

Future split-out repository for build infrastructure and smoke tests.

Scope:
- MPSS archive importer
- MIC/KNC sysroot extraction scripts
- compiler wrapper scripts
- CMake/toolchain files
- SSH deployment helpers
- native C/C++ smoke tests
- OpenMP, pthread, math, file I/O, dynamic loading, and timing tests

This should stay inside the monorepo first because Python, Doom, and other ports
all need the same toolchain and run harness.

### `knc-python`

Future split-out repository for CPython build and runtime packaging for Knights
Corner.

Scope:
- CPython 2.7 proof-of-life if useful
- CPython 3.4/3.5 primary target
- `config.site` files for cross-compilation
- dependency recipes for zlib, bzip2, libffi, sqlite, readline, and OpenSSL if
  needed
- deployment layout for `/opt/knc-python`
- tests for `math`, `os`, `ctypes`, imports, bytecode compilation, threads, and
  multiprocessing

Longer-term scope:
- NumPy
- native extension examples
- OpenMP-backed Python extension templates

### `knc-doom`

Future split-out repository for a public demo and runtime stress test.

Scope:
- DoomGeneric or another compact portable Doom source port
- Freedoom-based public test path
- headless timedemo mode first
- host-side display streaming later
- optional parallel renderer experiments
- experimental Ubuntu 24.04-derived uOS/userland research

The first goal is not direct video output from the card. The first goal is to
prove that the Phi can load WAD data, run deterministic game ticks, render into
a buffer, and report a stable timedemo/checksum.

### `mpss-notes`

Future split-out repository for a documentation-only knowledge base.

Scope:
- compatible hosts and operating systems
- MPSS version matrix
- firmware/stepping notes
- card identification
- cooling and power requirements
- known failure modes
- safe diagnostic commands
- links and checksums for historical resources where appropriate

Do not store Intel MPSS archives here unless a redistribution review says it is
allowed.

### `archive-index`

Future split-out repository for a metadata-only index of historical software and
documentation.

Scope:
- file names
- sizes
- hashes
- source URLs
- license notes
- extraction notes
- whether a file is redistributable, unknown, or local-only

This repository should avoid uploading proprietary binaries.

## First Bring-Up Plan For The 5110P

### Hardware Intake

- Photograph the card before install.
- Record model, serial labels, stepping labels, memory markings if visible, and
  cooling configuration.
- Confirm passive cooling airflow before power-on.
- Confirm host PCIe slot power and supplemental power cabling.
- Use a controlled host configuration instead of changing the storage/server
  environment blindly.

### Passive Enumeration

Before loading MPSS aggressively:

- Boot host.
- Confirm PCI enumeration with a dynamic query, not a stale bus address.
- Capture `lspci -Dnnd 8086:225c` or equivalent.
- Capture full PCI config details.
- Capture host OS, kernel, BIOS settings, and PCIe link width/speed.

### MPSS Initialization

Only after passive enumeration looks stable:

- Install or select the MPSS version matched to the host.
- Load the `mic` module.
- Start MPSS.
- Capture `micctrl --status`, `micinfo`, kernel log excerpts, and MPSS logs.
- Success condition: `mic0` reaches `online`/`ready`, SSH works, and files can
  be copied to the card.

### First Native Program

Build and run:

```text
hello-knc
pthreads-smoke
openmp-smoke
math-smoke
file-io-smoke
abi-elf-smoke
abi-loader-smoke
abi-tls-smoke
abi-signal-smoke
abi-dlopen-smoke
```

The first milestone is:

```text
Host builds hello-knc
Host copies hello-knc to mic0
mic0 runs hello-knc
Run output and environment details are archived
```

Every first-bring-up run should produce an experiment manifest under
`manifests/experiments/` and a hardware manifest under `manifests/hardware/`.
The manifest is part of the result, not cleanup paperwork.

## Ubuntu 24.04 uOS Research Track

This is an ambitious research track: try to build a newer Ubuntu-derived user
operating system environment for Knights Corner. Treat it as exploratory until
the stock MPSS uOS boot path is fully understood and a working 5110P baseline is
captured.

### Goal

Investigate whether an Ubuntu 24.04-derived root filesystem, package set, or
userland can run on the Xeon Phi coprocessor as a replacement or companion to
the stock MPSS uOS.

The first realistic target is not a full normal Ubuntu boot. The first target is:

```text
MPSS boots a known-good kernel/uOS path
an Ubuntu-derived k1om userland tree is assembled locally
basic binaries run inside that environment
Python and package dependencies can be built against it
```

### Ubuntu Success Definitions

Keep these three targets separate so the research track stays measurable.

Ubuntu-compatible:

- A KNC root filesystem follows familiar Ubuntu filesystem conventions where
  useful.
- Project-built binaries and libraries use Ubuntu-like paths and package naming
  where practical.
- It does not claim to be Ubuntu and does not require Ubuntu's package manager
  to work natively.
- This is the first reasonable target.

Ubuntu-derived:

- Selected Ubuntu 24.04 source packages are rebuilt for `k1om`.
- The resulting userland uses project-built KNC binaries and libraries, not
  copied amd64 Ubuntu packages.
- Package provenance, patches, build flags, and failures are documented.
- This is the Python/rootfs research target.

True Ubuntu port:

- A real Ubuntu architecture port exists for KNC-like `k1om`, with coherent
  archive metadata, toolchain support, libc/runtime integration, package
  rebuilds, and boot/userland integration.
- This likely requires substantial distro engineering and may never be practical.
- Treat this as a long-term research question, not a near-term milestone.

### Current Architecture-Port Checkpoint

As of 2026-07-29:

- Ubuntu Noble dpkg `1.22.6ubuntu6.6` builds reproducibly for K1OM and has
  completed a full 36-package isolated transaction on the 5110P.
- Ubuntu APT `1.0.1ubuntu2.24` builds as a native local-file compatibility
  bridge and has driven real dpkg through the same archive.
- CPython 3.12.13, libffi callbacks, SQLite, compression, curses, and OpenSSL
  modules pass in the packaged K1OM profile.
- Noble APT `2.8.3` is blocked by the MPSS K1OM compiler's lack of C++17.
- The active loader and libc remain MPSS-derived, so the result is still an
  Ubuntu-derived bootstrap distribution rather than a true Ubuntu port.

The next two distribution dependencies are a modern K1OM C++ toolchain and an
Ubuntu-source libc build that can run on the MPSS 2.6.38 kernel.

### Constraints To Prove

- Knights Corner is not normal x86_64; Ubuntu 24.04 does not ship a native KNC
  architecture port.
- The stock MPSS uOS uses a KNC-specific kernel, boot image, filesystem layout,
  and host-driven boot process.
- A modern Ubuntu 24.04 userland cannot simply be copied onto the card unless
  every executable and library is built for the MIC/KNC target.
- The kernel question is separate from the userland question. Replacing the
  root filesystem may be easier than replacing the KNC kernel.
- The dynamic loader, glibc version, pthreads, TLS, signals, `/proc`, `/sys`,
  networking, SSH, and MPSS integration all need individual proof.

### Phased Plan

1. Archive the stock working uOS environment once the 5110P reaches `ready`.
2. Extract the stock uOS filesystem and document its boot layout.
3. Identify the kernel, init, modules, libraries, SSH setup, network config, and
   MPSS-specific files needed for a minimal boot.
4. Build a tiny replacement root filesystem first, not Ubuntu:

   ```text
   init
   busybox or equivalent basic tools
   shell
   networking
   SSH or a serial/logging substitute
   hello-knc
   ```

5. Add Ubuntu 24.04-inspired structure only after the tiny root filesystem boots
   or chroots cleanly.
6. Build selected Ubuntu-source packages for KNC using the project sysroot and
   toolchain.
7. Attempt a staged userland:

   ```text
   stock MPSS kernel
   project-built KNC rootfs
   Ubuntu 24.04 package recipes where practical
   ```

8. Only after that, investigate whether a newer kernel is feasible. This should
   be treated as a separate research project.

### Repository Placement

Start this inside the monorepo under:

```text
uos/
```

If it grows enough to deserve a separate repository later, split it into:

```text
knc-uos-lab
```

Scope:

- stock uOS inventory tools
- rootfs assembly scripts
- package cross-build recipes
- boot image construction notes
- bring-up logs
- failure matrix
- no redistributed Intel uOS images, firmware, or MPSS payloads

### Success Levels

Level 0:

```text
Stock MPSS uOS inventory is captured and reproducible
```

Level 1:

```text
Custom minimal KNC rootfs can run basic commands under the stock MPSS boot model
```

Level 2:

```text
Ubuntu 24.04-source packages can be cross-built for KNC and run in the custom rootfs
```

Level 3:

```text
Python runs from the custom Ubuntu-derived userland
```

Level 4:

```text
A mostly self-hosted Ubuntu-like KNC userland exists, with documented limitations
```

Level 5:

```text
True Ubuntu architecture-port feasibility is demonstrated or rejected with evidence
```

### Safety Boundary

Do not replace a known-good card boot path until the stock image, configuration,
and logs are archived. Do not perform firmware writes or flash recovery as part
of this track. uOS work should be reversible: copy a test image, boot it, collect
logs, and return to the stock MPSS image if it fails.

## Python Port Plan

### Target

Start with CPython 3.4 or 3.5 as the practical target. Python 2.7 can be used as
a short proof-of-life if it builds faster, but it should not be the long-term
target.

### Build Strategy

- Use MPSS to produce a local MIC sysroot.
- Keep the sysroot local and ignored by Git.
- Build dependencies from source against the MIC sysroot.
- Use cross-compilation answers through `config.site`.
- Disable optional modules first, then add them back one at a time.
- Deploy a self-contained tree to the card.

Initial dependency order:

```text
zlib
bzip2
libffi
sqlite
readline
OpenSSL only if needed
CPython
```

Initial Python success tests:

```text
python -c "print('hello from mic')"
python -c "import sys, os, math"
python -c "import ctypes"
python -m compileall Lib
```

### Performance Model

Python on Knights Corner should be treated as orchestration. The Phi's value
comes from many threads and vectorized native code, not fast scalar Python.

Useful pattern:

```text
Python control code
  calls native KNC extension modules
    use OpenMP / pthreads / vectorized kernels
```

## Compiler And Toolchain Plan

### Practical Track

Use Intel's existing MIC-era tooling where available to prove the runtime model.

Goals:
- build native C programs
- build C libraries
- build CPython
- package a local development flow

### Independent/Open Track

Investigate how far open tooling can go without relying on abandoned Intel
compiler pieces.

Areas to evaluate:
- binutils support for KNC object files
- GCC `k1om` target viability
- LLVM backend feasibility
- assembler support for IMCI instructions
- linker and dynamic loader behavior
- ABI, TLS, pthreads, signals, and shared libraries

This track should start after the practical track can run and test binaries on
real hardware.

## Doom Port Plan

Doom is a good public demo because it is compact, recognizable, and stresses a
useful set of runtime features.

First target:
- DoomGeneric or similarly portable C source
- Freedoom WAD for redistributable testing
- headless timedemo/checksum mode
- no audio
- no direct card display

Second target:
- render frames on the Phi into a buffer
- stream frames to a host viewer over socket, SSH pipe, or SCIF if practical

Possible later experiments:
- parallel column renderer
- parallel span/visplane renderer
- SIMD fixed-point math
- multi-demo benchmark runner

## Public Release Policy

Public repos may include:
- scripts
- patches for open-source projects
- documentation
- checksums
- test logs
- generated source code owned by the project
- small original test programs

Public repos should not include by default:
- Intel MPSS tarballs
- extracted MPSS sysroots
- Intel firmware images
- Intel compiler binaries
- files whose license status is unknown

## Near-Term Task List

- Create the initial `xeon-phi-revival` monorepo in the GitHub organization.
- Add README with project goals, four technical lanes, and bring-your-own-MPSS
  licensing boundary.
- Add `.gitignore` entries for local MPSS archives, sysroots, build outputs, and
  logs.
- Add an MPSS license-discovery note based on local `docs/license.txt`.
- Add a host/card intake checklist.
- Add first smoke-test source files.
- Add first ABI test source files.
- Add experiment manifest templates.
- Add hardware, MPSS, and sysroot manifest templates.
- Add initial deployment/run helper scripts.
- Add a `uos/` research note or subdirectory for Ubuntu-compatible,
  Ubuntu-derived, and true Ubuntu-port experiments once the stock 5110P baseline
  is captured.
- When the 5110P arrives, run passive enumeration before any flash or invasive
  operation.
- If the 5110P reaches `ready`, capture the first working baseline immediately
  before changing versions or configuration.

## Open Questions

- Which host will be used for the 5110P bring-up?
- Which MPSS version should be the first baseline for the 5110P?
- Is the Intel MIC compiler available locally or only MPSS?
- Should project branding include a simple logo/banner for public GitHub pages?
- Which future split-out repositories should be created after the monorepo
  proves stable interfaces?
- Which Ubuntu target is most valuable to demonstrate publicly first:
  Ubuntu-compatible, Ubuntu-derived, or true Ubuntu-port feasibility?

## Definition Of First Success

The first real software success is not Python. It is this:

```text
5110P reaches ready
SSH to mic0 works
hello-knc runs natively on the card
build/run steps are documented and repeatable
the public repo contains no Intel proprietary payloads
```

After that, Python, Doom, NumPy, and compiler work become tractable engineering
projects instead of speculation.
