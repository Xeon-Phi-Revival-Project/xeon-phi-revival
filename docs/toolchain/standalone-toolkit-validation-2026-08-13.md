# Standalone Toolkit Validation - 2026-08-13

## Candidate

- Archive: `xpr-k1om-toolkit-0.1.0-linux-x86_64.tar.xz`
- SHA-256: `8227898056918423beab850b4daddd01423e88e75332698f636720d4b6fd6cc2`
- Size: approximately 95 MiB.

The staging builder used only source-built GCC, KNC binutils, eglibc, and
libgcc outputs. Its ELF scan found no embedded `/opt/mpss` or `mpss-sdk` path.

## Toolchain Inputs

- GCC KNC: `apc-llc/gcc-5.1.1-knc` commit
  `af7cc04cef723da3166f0d6f1539f02525fe5a93`; source archive SHA-256
  `6538edbd3c309eb7c37bb215c40ef9822c7c015928ff354267eac2178cf5f1e3`.
- KNC binutils 2.22 + MPSS 3.8.6: source archive SHA-256
  `0e498581badb505bd2639bc1f75debe9299212fb50e8eee5deb40631a78abd9c`.
- eglibc: 2.19 original source SHA-256
  `e5d30be72b702dffae527779af1be755f0dfbf13c171998a04f7265cd4da131f`
  plus Debian source archive SHA-256
  `2e0a1d4dfbc8bb666604d6804b9fbd9ce7a1f23b2a5bcb487f5a774d2c557e4c`.

`tools/release/build-eglibc-k1om-runtime.sh` completed with the source-built
GCC/binutils after binding all target tools explicitly, normalizing copied
overlay CRLF, and disabling the resolver's unsupported SSP path through
`libc_cv_ssp=no`. `tools/release/build-k1om-libgcc.sh` then rebuilt
`libgcc.a` and `libgcc_s.so.1` against that stage.

## Modern Host Test

The exact archive was unpacked on TrueNAS SCALE, Linux 6.12.15 x86-64.
`/opt/mpss` did not exist. TrueNAS mounts `/home` and `/tmp` `noexec`, so the
archive was finally unpacked in its executable `/var/tmp`; this is host mount
policy, not a toolkit dependency.

The following commands passed:

```bash
./bin/xpr-gcc examples/hello.c -o hello
./bin/xpr-gcc examples/pthread.c -pthread -o pthread
./bin/xpr-gcc examples/libc-smoke.c -o libc-smoke
./bin/xpr-validate hello
./bin/xpr-validate pthread
./bin/xpr-validate libc-smoke
```

All three outputs reported `Machine: Intel K1OM`, interpreter
`/lib64/ld-linux-k1om.so.2`, and `NEEDED libgcc_s.so.1`.

| Binary | SHA-256 |
| --- | --- |
| hello | `911ea265347ed19a7c52ff5e45b7c1d93aa5f69acf82a59d4882321c45a2b5c4` |
| pthread | `a84ce798d98722a13adc2096031708b895b0f67c6a3bebdd962bc33e53011047` |
| libc-smoke | `627d29c04c3320b4f1646c070b96c3c22153fed7aaa06707b6ee314d85dffffb` |

## 5110P Test

The same three files were copied, without rebuilding, to the final XPR-OS
RC6 root on the validated Intel Xeon Phi 5110P. Card-side SHA-256 values
matched the table exactly. Execution passed:

```text
Hello from XPR-OS on K1OM
XPR toolkit pthread result=123
XPR libc smoke 42
```

The bounded test used the existing XPR RC6/xpr-init path only for card boot
and transport. It did not use MPSS or an SDK to compile any test binary.
Recovery restored stock `mic0.conf` SHA-256
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`;
the card returned online with stock `k1om` and `init`.

## Release Status

Technical standalone compilation and 5110P execution are proven. This is not
a public toolkit release: corresponding-source packaging, SPDX, notices, and
the release-level license/provenance review are still required before any
publication decision.
