# Public-Clean Root Builder

`tools/release/build-public-clean-root.py` is separate from the historical RC
and its Ubuntu/package builders. It never accepts a stock rootfs, MPSS sysroot,
package archive, firmware path, or prior payload as an input.

It starts from project-owned init/configuration and accepts only explicit,
ledger-classified component files. The result is intentionally not bootable
until the required kernel, modules, libc, and runtime components have complete
corresponding-source evidence.

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
candidates; the default `publication` stage still rejects them. Do not use this
root for a hardware boot yet: it lacks the independently reconstructed kernel,
modules, and libc/runtime stack.
