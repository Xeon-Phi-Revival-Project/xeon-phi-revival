# Clean K1OM libgcc Rebuild

The public runtime uses a source-built `libgcc_s.so.1`; it does not reuse the
byte-identical MPSS SDK copy retained only for private diagnostic comparison.

## Pinned candidate

- Source: `apc-llc/gcc-5.1.1-knc` commit
  `af7cc04cef723da3166f0d6f1539f02525fe5a93`
- Downloaded source archive SHA-256:
  `6538edbd3c309eb7c37bb215c40ef9822c7c015928ff354267eac2178cf5f1e3`
- GCC license: GPL-3.0-or-later with GCC Runtime Library Exception 3.1.

This is a source-available KNC candidate, not a claim that it is the exact
Intel MPSS compiler source. A human review must confirm the source-bundle and
redistribution treatment before a prebuilt release.

## Rebuild

Use authoritative source archives for GMP 4.3.2, MPFR 2.4.2, and MPC 0.8.1,
the source-built eglibc stage, and user-supplied MPSS target binutils:

```bash
tools/release/build-k1om-libgcc.sh \
  --gcc gcc-5.1.1-knc-af7cc04.tar.gz \
  --gmp gmp-4.3.2.tar.bz2 \
  --mpfr mpfr-2.4.2.tar.bz2 \
  --mpc mpc-0.8.1.tar.gz \
  --crt-dir /private/eglibc-stage/usr/lib \
  --sysroot /private/eglibc-stage \
  --target-tools /opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux \
  --out /private/libgcc-k1om
```

The K1OM binutils directory must be on `PATH` during configure. Otherwise GCC
5.1.1 creates a generated `nm` wrapper with an empty
`ORIGINAL_NM_FOR_TARGET`; its map rule then attempts `exec -p`. The builder
enforces the correct wrapper before it installs the runtime.

The resulting file is
`install/k1om-mpss-linux/lib64/libgcc_s.so.1`. The initial source build has
K1OM ELF machine type, SONAME `libgcc_s.so.1`, a single `libc.so.6`
dependency, and standard `_Unwind_*` exports. It still needs integration and
on-card validation with the source-built eglibc runtime.
