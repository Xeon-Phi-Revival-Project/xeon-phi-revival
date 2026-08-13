# XPR K1OM Toolkit

The XPR K1OM Toolkit is the project entry point for practical C cross
development for XPR-OS. It uses a locally supplied MPSS 3.4.10 K1OM SDK for
the historical compiler, binutils, headers, and compiler support objects. It
extracts the XPR runtime libraries from the public RC6 payload into a local
sysroot. No Intel SDK binary is committed or redistributed by XPR.

## Current State

Host-side setup and static validation pass on the tested CentOS 7.4 + MPSS
3.4.10 host:

```bash
tools/toolchain/setup-xpr-k1om-toolkit.sh \
  --release ~/Downloads/xpr-os-0.1.0-rc6.tar.gz
source build/xpr-k1om/env.sh
xpr-gcc examples/k1om/hello.c -o build/hello
tools/toolchain/validate-k1om-elf.sh build/hello
```

This produces an Intel K1OM dynamic ELF with interpreter
`/lib64/ld-linux-k1om.so.2`, XPR `/lib64` RPATH, and no host-library path in
dynamic metadata. `examples/k1om/pthread.c` also compiles and links.

## Current Blocker

This is **not yet a supported live compiler workflow**. On the real 5110P,
binaries linked with the MPSS SDK CRT objects exit successfully but do not emit
the expected `puts` output. The known-good RC6 helpers use the project-built
eglibc CRT objects; those objects were supplied through a historical private
build-stage path and are not yet a declared public toolkit input. XPR will not
silently substitute that private path or claim live toolkit execution until a
source-accounted CRT construction path is exposed.

The next focused toolkit task is to make the project-built CRT/startup objects
reproducibly available to `build-xpr-k1om-sysroot.sh`, then repeat the same
hello and pthread 5110P validation. This is runtime/sysroot closure work, not
a new compiler backend or package-manager project.

## Boundary

- Historical compiler required: user-supplied `mpss-sdk-k1om-3.4.10`.
- Compiler: `k1om-mpss-linux-gcc` 4.7.0 (GCC 4.7.0 20110509 experimental).
- Binutils: GNU Binutils 2.22.52.20120302.
- XPR provides: wrapper sources, sysroot assembly tooling, examples, and ELF
  validation.
- C++ is not validated; package building and `xpr-build` are deferred.
