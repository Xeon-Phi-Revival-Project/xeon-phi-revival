# XPR K1OM Toolkit

The XPR K1OM Toolkit is the project entry point for practical C cross
development for XPR-OS. It uses a locally supplied MPSS 3.4.10 K1OM SDK for
the historical compiler, binutils, and compiler support objects. A
source-built XPR eglibc stage supplies headers and CRT objects; RC6 supplies
the runtime libraries. No Intel SDK binary is committed or redistributed by
XPR.

## Current State

The source-built-CRT path below passed host-side setup, K1OM ELF validation,
and live execution on the tested CentOS 7.4 + MPSS 3.4.10 host and Xeon Phi
5110P:

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

## Validated Scope

The 5110P executed the source-built-CRT `hello` and `pthread` examples from
the final XPR root. The former printed `Hello from XPR-OS on K1OM`; the latter
printed `XPR toolkit pthread result=123`. The SDK CRT path remains rejected:
it previously produced binaries that exited successfully but emitted no
stdio output. The toolkit does not silently substitute it.

This validates C development for these compact dynamic programs. C++,
package building, `xpr-build`, and a modern compiler backend remain out of
scope.

## Boundary

- Historical compiler required: user-supplied `mpss-sdk-k1om-3.4.10`.
- Compiler: `k1om-mpss-linux-gcc` 4.7.0 (GCC 4.7.0 20110509 experimental).
- Binutils: GNU Binutils 2.22.52.20120302.
- XPR provides: wrapper sources, sysroot assembly tooling, examples, and ELF
  validation.
- C++ is not validated; package building and `xpr-build` are deferred.
