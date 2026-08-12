# Glossary

This is the canonical glossary for the Xeon Phi Revival Project. Project-specific
terms describe the **current** architecture; generic systems terms are included
so readers do not need the older duplicate handbook glossary.

## Xeon Phi And XPR Terms

**Intel Xeon Phi** — Intel's manycore accelerator/coprocessor product family.
XPR currently targets the first-generation Knights Corner coprocessor platform,
not Knights Landing.

**Knights Corner (KNC)** — The first-generation Xeon Phi coprocessor platform.
The project's hardware-validated card is an Intel Xeon Phi 5110P.

**Knights Landing (KNL)** — A later Xeon Phi platform with a substantially
different system model. It is not an XPR-OS target.

**K1OM** — The architecture/ABI target used by Knights Corner software. K1OM
binaries are not ordinary x86-64 binaries even though the architecture is
historically related to x86.

**Intel MIC** — “Many Integrated Core,” the historical Intel naming used across
Xeon Phi drivers, modules, interfaces, and MPSS.

**MPSS** — Intel Manycore Platform Software Stack, the historical host/card
software stack used to manage Knights Corner. XPR's validated host baseline uses
MPSS 3.4.10.

**uOS** — The historical small Linux-based operating environment Intel booted on
Knights Corner cards. XPR research preserves and studies its behavior but XPR-OS
is not simply a redistributed Intel uOS image.

**XPR-OS** — The project's revived, source-accounted K1OM Linux operating
environment for Knights Corner.

**xpr-init** — The host-side XPR installer/integration/recovery helper. It
configures an existing working MPSS host for XPR-OS, performs automatic
bootstrap-to-final-root handoff, and can restore the saved stock MPSS
configuration. It does not replace `micctrl`.

**mic0** — The conventional MPSS name for the first Xeon Phi card managed by the
host.

**micctrl** — MPSS's host-side card control utility. XPR continues to use it for
reset/wait/boot lifecycle operations on the tested configuration.

**Base CPIO** — The initial CPIO archive supplied to the KNC boot process. XPR
uses it to satisfy the boot contract and start the project bootstrap.

**initramfs / CPIO** — An early userspace filesystem archive loaded into memory
during Linux boot. CPIO is the archive format commonly used for initramfs data.

**bootstrap** — XPR's temporary early userspace. It brings up the minimum
services needed to receive and verify the final root payload before switching
away from itself.

**split-root boot** — XPR's boot design in which a small bootstrap comes up first
and a larger final root is transferred/activated afterward.

**final root** — The full XPR-OS root filesystem entered after the bootstrap
validates the payload and performs `switch_root`.

**switch_root** — The transition in which PID 1 moves from the bootstrap root to
the final XPR root. Bootstrap SSH is intentionally torn down during this step.

**PID 1** — The first userspace process in a Linux system. Reaching XPR's final
`/sbin/init` as PID 1 is a key proof that the final XPR root is actually running.

**micveth** — The virtual Ethernet interface/path used for host-to-card
networking in the validated XPR/MPSS setup.

**Dropbear** — A compact SSH server/client implementation used by XPR-OS.

**authorized key** — A public SSH key allowed to authenticate to the XPR
deployment. XPR provisions a deployment-specific public key; the private key
stays on the host.

**rollback / recovery** — Returning the host/card to the known stock MPSS
configuration after XPR testing. `xpr-init --recover` is the canonical tested
recovery path for an `xpr-init` installation.

## Build, Toolchain, And ABI Terms

**source code** — Human-readable program text before compilation or
interpretation.

**machine code** — Processor instructions encoded in a form the target CPU can
execute.

**object file** — Compiled code/data that normally still requires linking before
it becomes a complete executable or shared library.

**executable** — A linked program image that can be loaded and run for its target
architecture and ABI.

**library** — Reusable code/data provided to other programs, either linked into
them or loaded separately.

**static linking** — Copying required library code into an output binary during
the link step.

**dynamic linking** — Resolving shared-library dependencies at program load time
or runtime instead of copying all library code into the executable.

**compiler** — A tool that translates source code into target object/machine
code.

**assembler** — A tool that translates assembly-language source into object
code.

**linker** — A tool that combines object files/libraries, resolves symbols and
relocations, and produces executables or libraries.

**toolchain** — The compiler, assembler, linker, binary utilities, headers,
runtime pieces, and supporting build tools needed to produce software for a
target.

**ABI (Application Binary Interface)** — The binary-level rules that compiled
code must follow: calling conventions, object format details, data layout,
symbol conventions, relocation behavior, and related runtime contracts.

**API (Application Programming Interface)** — The source-level interface a
programmer uses to interact with a library or service. An API is not the same as
an ABI.

**ISA (Instruction Set Architecture)** — The processor's instruction and
architectural programming model.

**ELF** — Executable and Linkable Format, the executable/object/shared-library
container format used by Linux and K1OM software.

**sysroot** — A directory tree representing the target system's headers,
libraries, and other build inputs so a host compiler can build for that target.

**cross-compilation** — Building software on one architecture/system for a
different target. XPR toolchain work commonly means building on an x86-64 host
for K1OM.

**runtime** — Libraries and support components required by compiled software
while it executes. For XPR this includes K1OM-compatible libc/libgcc and related
pieces.

**glibc / eglibc** — GNU C Library and its historical Embedded GLIBC derivative.
Historical K1OM software used an eglibc-derived runtime; XPR tracks exact source
and binary provenance rather than treating the name alone as proof.

**libgcc_s** — GCC's shared low-level runtime support library used by many
compiled programs.

**pthread** — POSIX threads support. XPR includes a native K1OM pthread smoke
program as a runtime validation point.

**dlopen** — A POSIX/Linux dynamic-loader interface for loading a shared object
at runtime. XPR uses a `dlopen` smoke test to validate dynamic runtime behavior.

**build system** — The scripts/rules/tools that turn source inputs into outputs,
for example Makefiles and project-specific build scripts.

**Kbuild** — The Linux kernel's build framework used for the kernel and modules.

**kernel module** — Loadable kernel code, conventionally a `.ko` file on Linux.
XPR rebuilt five MIC modules required by its validated KNC path.

## Operating-System Terms

**kernel** — The privileged core of the operating system responsible for
processes, memory, devices, filesystems, networking, and system calls.

**userspace** — Programs and libraries running outside the kernel.

**kernelspace** — Privileged execution context belonging to the kernel.

**root filesystem** — The filesystem tree mounted at `/` from which normal
userspace runs.

**init** — The program started by the kernel as PID 1 to initialize userspace.

**system call (syscall)** — A controlled interface used by userspace programs to
request kernel services.

**driver** — Software that controls or exposes hardware to the operating system.

**firmware** — Software stored on or closely associated with hardware, distinct
from the host/card Linux userspace in normal XPR discussions.

**DMA (Direct Memory Access)** — Hardware-assisted data transfer that can move
data without the CPU copying each byte directly.

**interrupt** — A hardware/software signal that causes a processor to service an
event.

## Reproducibility And Provenance Terms

**corresponding source** — The source material needed to correspond to a shipped
binary under the applicable licensing/source obligations. This is related to,
but not identical with, deterministic reproducibility.

**deterministic / reproducible build** — A build designed so controlled inputs
produce the same output, ideally byte-for-byte. XPR treats this as an engineering
and auditability goal.

**provenance** — Evidence showing where a source/binary/component came from and
how it maps into the project.

**source archive** — A release artifact containing the source/build material
paired with a binary release where applicable.

**prerelease / release candidate (RC)** — A public milestone that is not yet
presented as a stable production release. XPR-OS 0.1.0-rc6 is a release
candidate.
