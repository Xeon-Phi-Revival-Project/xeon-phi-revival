# Ubuntu 24.04 uOS Level 2 zlib Report

Public-safe package rebuild report. Downloaded source archives, build trees,
compiled objects, binaries, and raw logs remain local-only.

## Result

Level 2 has its first passing package proof.

The Ubuntu 24.04 Noble `zlib` source package was downloaded from the official
Ubuntu archive, verified against the `.dsc` SHA256 checksums, patched with the
Ubuntu/Debian patch series, cross-built for K1OM with the MPSS 3.4.10 K1OM SDK,
and tested on `mic0`.

## Source Package

- Source package: `zlib`
- Ubuntu suite: Noble / Ubuntu 24.04 LTS
- Version: `1:1.3.dfsg-3.1ubuntu2`
- Source page: `https://packages.ubuntu.com/source/noble/zlib`
- Archive base: `https://archive.ubuntu.com/ubuntu/pool/main/z/zlib/`

Downloaded files:

| File | SHA256 |
| --- | --- |
| `zlib_1.3.dfsg-3.1ubuntu2.dsc` | `53784a98f595c549aed67b3c35caf5d9783223c7a9e3a5493da4c500809a8bd6` |
| `zlib_1.3.dfsg.orig.tar.xz` | `5eea0322c1c21c75cad3b607ac1c43ff5c71e014b8ac4a34300b5e2b80d02e70` |
| `zlib_1.3.dfsg-3.1ubuntu2.debian.tar.xz` | `645a2ecc2a3c1d263784717ba7f5ad6672261979523461a4d6cdbed217caae59` |

The `.dsc` `Checksums-Sha256` block verified the two source tarballs.

## Build Method

The source was unpacked as:

```text
zlib_1.3.dfsg.orig.tar.xz
zlib_1.3.dfsg-3.1ubuntu2.debian.tar.xz
```

The Debian patch series applied successfully. The package was then configured
for a static library build using:

```text
CC=k1om-mpss-linux-gcc
AR=k1om-mpss-linux-ar
RANLIB=k1om-mpss-linux-ranlib
./configure --prefix=/usr --static
make -j2
```

The build produced `libz.a` and the zlib test programs as K1OM binaries.

## Runtime Smoke Test

The project smoke test is:

```text
tests/native/zlib-smoke-test.c
```

It links against the rebuilt `libz.a`, compresses and decompresses a short
string, checks the result, and prints the zlib runtime version.

`readelf` reported:

```text
Machine: Intel K1OM
```

Runtime result on `mic0`:

```text
zlib version=1.3 result=knc zlib smoke
```

## Interpretation

This is not a full Ubuntu architecture port and not a native `.deb` package
build. It is a narrower but important Level 2 result: a selected Ubuntu 24.04
source package can be rebuilt for K1OM and run on the card.

Next package candidates should stay small and dependency-oriented before moving
toward Python:

- `libffi`
- `ncurses`
- `readline`
- `sqlite3`
- TLS strategy: `openssl` or a smaller alternative
