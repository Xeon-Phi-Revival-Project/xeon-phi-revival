# XPR K1OM Toolkit

The first XPR K1OM Toolkit is a practical C cross-development layer for
XPR-OS. It is intentionally small: it wraps the historical MPSS K1OM GCC and
binutils, combines them with an XPR runtime sysroot, and rejects accidental
host ELF output.

It does not include the Intel MPSS SDK. A user must separately obtain and
install the tested `mpss-sdk-k1om-3.4.10` package. XPR does not redistribute
its compiler binaries, headers, CRT objects, or SDK libraries.

On the tested CentOS 7.4 + MPSS 3.4.10 host:

```bash
tools/toolchain/setup-xpr-k1om-toolkit.sh \
  --release ~/Downloads/xpr-os-0.1.0-rc6.tar.gz
source build/xpr-k1om/env.sh
xpr-gcc examples/k1om/hello.c -o build/hello
xpr-readelf -h build/hello
```

The setup script extracts only the XPR runtime files required for normal
dynamic C programs from the public release payload. It copies development-only
headers and CRT/link inputs from the locally supplied MPSS SDK into a local
generated sysroot. Generated output under `build/xpr-k1om/` is not committed.

Use `tools/toolchain/validate-k1om-elf.sh build/hello` before transfer. The
current scope is C. C++ and package-building are not part of Toolkit v1.
