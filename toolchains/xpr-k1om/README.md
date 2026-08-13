# XPR K1OM Toolkit

The first XPR K1OM Toolkit is a practical C cross-development layer for
XPR-OS. It is intentionally small: it wraps the historical MPSS K1OM GCC and
binutils, combines them with an XPR runtime sysroot, and rejects accidental
host ELF output.

It does not include the Intel MPSS SDK. A user must separately obtain and
install the tested `mpss-sdk-k1om-3.4.10` package. XPR does not redistribute
its compiler binaries or SDK libraries. The SDK supplies the compiler; an XPR
source-built eglibc stage supplies the headers and CRT objects.

On the tested CentOS 7.4 + MPSS 3.4.10 host:

```bash
tools/toolchain/setup-xpr-k1om-toolkit.sh \
  --release ~/Downloads/xpr-os-0.1.0-rc6.tar.gz \
  --eglibc-stage /path/to/eglibc-k1om/stage
source build/xpr-k1om/env.sh
xpr-gcc examples/k1om/hello.c -o build/hello
xpr-readelf -h build/hello
```

Build the eglibc stage using `tools/release/build-eglibc-k1om-runtime.sh` and
the pinned source inputs documented in `docs/release/eglibc-clean-rebuild.md`.
The setup script extracts the XPR runtime from the public release payload and
copies the stage's headers and CRT/link inputs into a local generated sysroot.
Generated output under `build/xpr-k1om/` is not committed.

Use `tools/toolchain/validate-k1om-elf.sh build/hello` before transfer. The
current scope is C. C++ and package-building are not part of Toolkit v1.
