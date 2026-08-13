# Standalone Toolkit Source-Build Checkpoint

This checkpoint records a bounded attempt to remove the MPSS SDK from the
K1OM compiler path. It is not a standalone toolkit release.

## Proven Host-Only Results

On the tested CentOS 7.4 build host, using a controlled environment with no
`/opt/mpss` path:

- GNU binutils 2.35.2 built from the official source archive
  (`dcd5b0416e7b0a9b24bed76cd8c6c132526805761863150a26d016415b8bdc7b`).
- Its linker exposed `elf_k1om` and produced an ELF64 object with
  `Machine: Intel K1OM` for a basic assembly probe.
- The public KNC GCC 5.1.1 source at
  `apc-llc/gcc-5.1.1-knc` commit
  `af7cc04cef723da3166f0d6f1539f02525fe5a93` built its C driver. The pinned
  source archive hash is
  `6538edbd3c309eb7c37bb215c40ef9822c7c015928ff354267eac2178cf5f1e3`.
- That compiler, the project-built eglibc sysroot, and the existing
  source-built XPR libgcc artifacts linked a dynamic hello program without an
  `/opt/mpss` reference. Static inspection reported `Intel K1OM`, requested
  `/lib64/ld-linux-k1om.so.2`, and depended on `libc.so.6`.

This proves a useful source-built driver path for a narrow non-IMCI C program.
It does **not** prove a redistributable standalone toolkit.

## Blocking Source Gap

The generic GNU binutils source above retains K1OM ELF/BFD and linker-emulation
support but does not encode Knights Corner IMCI instructions. An explicit
`kmov %eax, %k1` probe fails, and GCC-generated KNC code using `vpackstorelq`
also fails in that assembler.

The public KNC GCC tree's own README requires K1OM-targeted MPSS assembler and
linker tools. The historical MPSS source layout describes a separate patched
`binutils.tar.xz`, but the available MPSS 3.4.10 installation media and local
source cache do not contain that archive. No SDK binary was copied into this
experiment.

Until an authoritative, redistributable patched K1OM binutils source archive
is recovered and pinned, XPR cannot truthfully ship a fully source-rebuildable
standalone prebuilt toolkit. In particular, the target `libgcc` rebuild reaches
KNC instructions that generic binutils cannot assemble.

## Next Exact Action

Recover the MPSS-era GPL `binutils.tar.xz` (or an equivalent authoritative
patched K1OM binutils source tree), record its revision and license evidence,
and repeat these two gates before packaging:

1. assemble representative IMCI instructions with the source-built assembler;
2. build `libgcc_s` from the pinned GCC source with that assembler.

Only then should the project create a standalone toolkit artifact or make an
MPSS-free compilation claim.

## References

- [GNU Binutils](https://www.sourceware.org/binutils/)
- [KNC GCC source](https://github.com/apc-llc/gcc-5.1.1-knc)
- [Intel Community source-package description](https://community.intel.com/t5/Software-Archive/Clarifying-MPSS-source-code-package/td-p/943880)
