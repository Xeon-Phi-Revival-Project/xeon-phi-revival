# Standalone Toolkit Source-Build Checkpoint

This checkpoint records source closure for the KNC compiler path. It is not a
standalone toolkit release.

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

## Recovered KNC Binutils Source

The public Internet Archive copy of Intel MPSS 3.8.6 provides a source release
whose MD5 matches the archive metadata. Its SHA-256 is
`2550f10c32cc28ed90049c1fe67eccf4f29a9f2a9991fa0d90f18d86d8db7d70`.
The nested `mpss-3.8.6/src/binutils-2.22+mpss3.8.6.tar.bz2` source archive has
SHA-256
`0e498581badb505bd2639bc1f75debe9299212fb50e8eee5deb40631a78abd9c`.

That archive contains GPL license material, K1OM BFD/linker support, and the
KNC assembler opcode implementation. Built with the source-built XPR sysroot,
it successfully assembles and disassembles both `kmov` and `vpackstorelq`, then
links an ELF64 `Intel K1OM` probe. `tools/toolchain/build-k1om-binutils.sh`
pins the nested source hash and fails closed if it differs.

The KNC GCC 5.1.1 C driver was rebuilt with explicit source-built target tools.
Passing only a target-tool directory on `PATH` is insufficient: GCC 5.1.1
otherwise emits empty `ORIGINAL_AS_FOR_TARGET` and `ORIGINAL_NM_FOR_TARGET`
wrapper values. The updated libgcc builder passes absolute `*_FOR_TARGET`
values during configure and asserts the generated wrappers are bound correctly.

With the public KNC binutils, public Linux UAPI headers, source-built eglibc
sysroot, and GCC source, the host build produced:

- `libgcc.a`;
- `libgcc_s.so.1` with SHA-256
  `c79bfa2961f3702000fce933d3b77667f7ab989eb86c9748003df262bf95a73c`,
  ELF64 `Intel K1OM`, and SONAME `libgcc_s.so.1`;
- a dynamic K1OM hello with SHA-256
  `d1008c856c986316082e0da5f4da08f0fe9cc59f2f5115d3e4da2ba87cf0ccb9`,
  interpreter `/lib64/ld-linux-k1om.so.2`, and `libc.so.6` as its dynamic
  dependency.

No `/opt/mpss` or MPSS SDK path appeared in either the compile or link trace.
This closes the assembler/source-accounting blocker; it does **not** yet prove
a redistributable standalone toolkit, modern-host support, or 5110P execution
of this newly built artifact.

## Next Exact Action

Use the recorded source builders to produce a relocatable toolkit candidate,
then validate it on a modern Linux host without MPSS and execute binaries from
that candidate on the 5110P. Only after those gates and a release-level license
review may XPR make an MPSS-free toolkit distribution claim.

## References

- [GNU Binutils](https://www.sourceware.org/binutils/)
- [KNC GCC source](https://github.com/apc-llc/gcc-5.1.1-knc)
- [Intel Community source-package description](https://community.intel.com/t5/Software-Archive/Clarifying-MPSS-source-code-package/td-p/943880)
- [Archived MPSS 3.8.6 source release](https://archive.org/details/intel-mpss-3.8.6)
