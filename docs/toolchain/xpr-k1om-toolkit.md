# XPR K1OM Toolkit

The XPR K1OM Toolkit is the project entry point for practical C cross
development for XPR-OS. It uses a locally supplied MPSS 3.4.10 K1OM SDK for
the historical compiler, binutils, and compiler support objects. A
source-built XPR eglibc stage supplies headers and CRT objects; RC6 supplies
the runtime libraries. No Intel SDK binary is committed or redistributed by
XPR.

## Current State

The prior SDK-CRT host-side setup and static validation passed on the tested
CentOS 7.4 + MPSS 3.4.10 host. The source-built-CRT path below is the required
replacement and awaits the same host and 5110P validation:

```bash
tools/toolchain/build-xpr-k1om-eglibc-stage.sh \
  --source-bundle ~/Downloads/xpr-os-0.1.0-rc6-sources.tar.gz \
  --out build/xpr-k1om-eglibc

tools/toolchain/setup-xpr-k1om-toolkit.sh \
  --release ~/Downloads/xpr-os-0.1.0-rc6.tar.gz \
  --eglibc-stage build/xpr-k1om-eglibc/stage
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
eglibc CRT objects. The toolkit now requires the stage emitted by the tracked
source builder rather than silently substituting an SDK or historical private
CRT path. A live retry is pending while the MPSS host is unreachable.

The next focused toolkit task is to rerun the hello and pthread 5110P
validation with the source-built CRT path. This is runtime/sysroot closure
work, not a new compiler backend or package-manager project.

## Boundary

- Historical compiler required: user-supplied `mpss-sdk-k1om-3.4.10`.
- Compiler: `k1om-mpss-linux-gcc` 4.7.0 (GCC 4.7.0 20110509 experimental).
- Binutils: GNU Binutils 2.22.52.20120302.
- XPR provides: wrapper sources, sysroot assembly tooling, examples, and ELF
  validation.
- C++ is not validated; package building and `xpr-build` are deferred.
