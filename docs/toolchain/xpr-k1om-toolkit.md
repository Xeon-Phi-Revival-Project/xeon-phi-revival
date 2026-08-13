# XPR K1OM Toolkit

The XPR K1OM Toolkit is XPR's C cross-development environment for XPR-OS on
Knights Corner. The standalone candidate contains source-built K1OM GCC 5.1.1,
KNC binutils, XPR eglibc headers/CRT/runtime, and K1OM libgcc. It does not use
an Intel MPSS SDK or `/opt/mpss` to compile programs.

## Current Validation

The staged `0.1.0` candidate was unpacked and used on a modern Linux 6.12
x86-64 host with no `/opt/mpss`. It built and validated:

- `hello.c`;
- `pthread.c` with `-pthread`;
- `libc-smoke.c`.

All outputs were dynamic `Intel K1OM` ELFs using
`/lib64/ld-linux-k1om.so.2` and `libgcc_s.so.1`. The exact binaries were then
copied unchanged to the tested Xeon Phi 5110P running XPR-OS RC6. They printed:

```text
Hello from XPR-OS on K1OM
XPR toolkit pthread result=123
XPR libc smoke 42
```

The detailed evidence is in
[standalone-toolkit-validation-2026-08-13.md](standalone-toolkit-validation-2026-08-13.md).

## Candidate Usage

After unpacking a standalone toolkit candidate on an executable Linux
filesystem:

```bash
cd xpr-k1om-toolkit-0.1.0-linux-x86_64
source env.sh
xpr-gcc examples/hello.c -o hello
xpr-validate hello
xpr-gcc examples/pthread.c -pthread -o pthread
```

`./bin/xpr-gcc` also works without sourcing `env.sh`. The toolkit's wrappers
select their bundled compiler, KNC binutils, and XPR sysroot; callers should
not supply `--sysroot` or an internal target triple for normal C programs.

Transfer a resulting executable to a running XPR-OS system with the current
host-control workflow and execute it from the final XPR root. The toolkit
does not replace MPSS/micctrl/xpr-init for physical card control.

## Provenance Boundary

- GCC: `apc-llc/gcc-5.1.1-knc` commit
  `af7cc04cef723da3166f0d6f1539f02525fe5a93`.
- KNC binutils: public MPSS 3.8.6 source archive,
  `binutils-2.22+mpss3.8.6.tar.bz2` SHA-256
  `0e498581badb505bd2639bc1f75debe9299212fb50e8eee5deb40631a78abd9c`.
- Sysroot: XPR's pinned eglibc 2.19 source package plus the tracked K1OM
  overlay and public Linux UAPI headers.
- libgcc: rebuilt from the same pinned GCC source against that sysroot.

No Intel MPSS SDK binary belongs in the standalone package. Corresponding
source, notices, SPDX, and final release packaging remain a separate release
gate; the current candidate is not published.

## Boundaries

Validated scope is compact dynamic C programs. C++, Python, package building,
`xpr-build`, LLVM, and a modern GCC backend are not part of Toolkit v1.
