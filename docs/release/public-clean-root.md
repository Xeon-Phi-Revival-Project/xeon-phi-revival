# Public-Clean Root Builder

`tools/release/build-public-clean-root.py` is separate from the historical RC
and its Ubuntu/package builders. It never accepts a stock rootfs, MPSS sysroot,
package archive, firmware path, or prior payload as an input.

It starts from project-owned init/configuration and accepts only explicit,
ledger-classified component files. The result remains a candidate until the
kernel/module boundary and final-root hardware gates are complete.

The root accepts source-built runtime inputs only through explicit arguments:

```bash
python tools/release/build-public-clean-root.py \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --busybox /private/build/busybox \
  --dropbear /private/build/dropbear \
  --eglibc-libdir /private/eglibc-stage/lib \
  --libgcc /private/libgcc-install/k1om-mpss-linux/lib64/libgcc_s.so.1 \
  --out-root /private/xpr-public-clean-root
```

The builder requires the loader, libc, pthread, math, dl, rt, util, crypt, and
`libnss_files.so.2` SONAME files from a fresh eglibc stage. `libcrypt.so.1` is
included because the dynamic Dropbear candidate requires it. The builder also
creates a files-only NSS policy and `/etc/shells` so Dropbear can resolve the
public-key-only root account before it reads `authorized_keys`.

Example private build workspace invocation:

```bash
python tools/release/build-public-clean-root.py \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --busybox /private/build/busybox \
  --dropbear /private/build/dropbear \
  --out-root /private/xpr-public-clean-root

python tools/release/audit-prebuilt-image.py \
  --rootfs /private/xpr-public-clean-root \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --stage candidate \
  --output /private/xpr-public-clean-audit.json
```

`--stage candidate` permits only components explicitly marked as technical
candidates; the default `publication` stage still rejects them. This root has
completed the three-boot hardware validation gate with the independently
rebuilt runtime, kernel, and module test artifacts. It is still not publishable
until the kernel/module corresponding-source and human-review gates pass.
