# Build XPR-OS RC From Source

This is the shortest honest path from a clean Git checkout to the current
XPR-OS release-candidate outputs. It covers two different products:

1. A fully public source/metadata archive that contains no boot binaries.
2. A private bootable split-root image assembled from project source plus
   locally supplied K1OM and MPSS-compatible inputs.

The second product is not yet reproducible from this Git repository alone.
The compatibility-kernel source, module source, bootstrap input, and some
userland binaries still require local provenance and redistribution review.
Do not describe a private build as a public-from-source binary release.

## Supported Baseline

The hardware-verified configuration is:

- Intel Xeon Phi 5110P (Knights Corner)
- Dell PowerEdge R730 host
- CentOS 7.4-era userspace
- MPSS 3.4.10 host stack
- `mpss-sdk-k1om-3.4.10-1.x86_64`
- `k1om-mpss-linux-*` compiler and binutils

Other KNC cards and MPSS versions are experimental until they pass the same
boot, SSH, native execution, and rollback checks.

## 1. Check Out The Source

Run this on the Linux MPSS host, not on the card:

```bash
git clone https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival.git
cd xeon-phi-revival
git status --short
git rev-parse HEAD
```

The worktree should be clean. Record the commit in every private build report.

## 2. Build The Public Source Prerelease

This path needs only normal host tools and tracked Git content:

```bash
bash tools/release/audit-source-compliance.sh
mkdir -p /root/xpr-build/public
bash tools/release/package-public-rc.sh \
  --out-dir /root/xpr-build/public \
  --version 0.1.0-local
sha256sum -c /root/xpr-build/public/SHA256SUMS
```

The output is a deterministic source archive, build metadata, and checksums.
It intentionally contains no kernel, modules, initramfs, rootfs, packages,
firmware, Intel SDK/sysroot files, or MPSS payloads.

## 3. Inventory Private Build Inputs

To build a bootable image, obtain these inputs legally and keep them outside
Git:

| Input | Requirement |
| --- | --- |
| K1OM SDK | Working `k1om-mpss-linux-gcc`, `ld`, and `readelf` |
| KNC kernel source | A complete source tree with real `ARCH=k1om` support |
| Kernel configuration | The evidence-backed candidate `.config` |
| Card module source | Source for `ringbuffer`, `dma_module`, `micscif`, `mpssboot`, and `intel_micveth` |
| Bootstrap source pair | Project-compatible bootstrap root CPIO and neighboring Base CPIO |
| Final-root source | Private CPIO containing the selected K1OM runtime and userland |
| Package repository | Optional local `binary-k1om` repository |

The current public release does not download these inputs and does not grant
rights to Intel material. Review
[Compliance Review](compliance-review.md) before sharing generated artifacts.

## 4. Verify The K1OM Toolchain

```bash
source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
command -v k1om-mpss-linux-gcc
command -v k1om-mpss-linux-ld
command -v k1om-mpss-linux-readelf
k1om-mpss-linux-gcc --version
```

Stop if these resolve to ordinary x86-64 tools.

## 5. Build The Compatibility Kernel

Choose private paths for the source, config, and output:

```bash
export XPR_KERNEL_SOURCE=/path/to/k1om-kernel-source
export XPR_KERNEL_CONFIG=/path/to/candidate.config
export XPR_KERNEL_BUILD=/root/xpr-build/kernel

bash tools/kernel/build-compatible-k1om-kernel.sh \
  --source "$XPR_KERNEL_SOURCE" \
  --config "$XPR_KERNEL_CONFIG" \
  --output "$XPR_KERNEL_BUILD" \
  --cross-compile k1om-mpss-linux- \
  --jobs 2
```

The script validates the source shape, builds with `ARCH=k1om`, checks the
resulting `vmlinux` ELF machine, and hashes the kernel outputs. A successful
build is not proof that the source may be redistributed.

## 6. Build The Five Card Modules

```bash
export XPR_MODULE_SOURCE=/path/to/mpss-card-module-source

bash tools/kernel/build-candidate-mpss-modules.sh \
  --kernel-source "$XPR_KERNEL_SOURCE" \
  --kernel-build "$XPR_KERNEL_BUILD" \
  --module-source "$XPR_MODULE_SOURCE" \
  --cross-compile k1om-mpss-linux- \
  --jobs 2
```

The required outputs are:

```text
dma/dma_module.ko
micscif/ringbuffer.ko
micscif/micscif.ko
mpssboot/mpssboot.ko
vnet/intel_micveth.ko
```

Validate their K1OM ELF identity, vermagic, dependencies, and unresolved
symbols before putting them in a Base CPIO. See
[Candidate Module Build](../kernel/candidate-module-build.md).

## 7. Assemble The Split Root

The current assembler expects a prepared bootstrap source pair and a final-root
source CPIO. The Base CPIO must be named `xpr-bootstrap-base.cpio.gz` beside
the bootstrap source archive.

```bash
export XPR_BOOTSTRAP_SOURCE=/path/to/xpr-bootstrap-root-source.cpio.gz
export XPR_PAYLOAD_SOURCE=/path/to/full-root-source.cpio.gz
export XPR_PACKAGE_REPO=/path/to/packages/repo
export XPR_SPLIT_BUILD=/root/xpr-build/split-root

bash tools/release/build-split-root-control.sh \
  --bootstrap-source "$XPR_BOOTSTRAP_SOURCE" \
  --payload-source "$XPR_PAYLOAD_SOURCE" \
  --package-repo "$XPR_PACKAGE_REPO" \
  --out-dir "$XPR_SPLIT_BUILD"
```

This compiles the project switch helper and final-init trampoline, injects the
current project init and banner, reconstructs the bootstrap and payload,
validates K1OM/static helper properties, and emits `SHA256SUMS`, `SIZES`, and
archive reports. It does not modify MPSS or boot the card.

If no package repository is available, omit `--package-repo`; package-manager
smoke checks will not represent the accepted RC configuration.

## 8. Review Before Hardware Use

Record and inspect:

```bash
sha256sum \
  "$XPR_KERNEL_BUILD/arch/x86/boot/bzImage" \
  "$XPR_KERNEL_BUILD/System.map" \
  "$XPR_SPLIT_BUILD/xpr-bootstrap-base.cpio.gz" \
  "$XPR_SPLIT_BUILD/payload/xpr-rootfs.cpio.gz"
cat "$XPR_SPLIT_BUILD/SIZES"
cat "$XPR_SPLIT_BUILD/SHA256SUMS"
```

Also verify the active stock MPSS configuration hash and stock SSH before any
boot. Do not continue if the expected stock hash is unknown.

## 9. Run The Bounded Hardware Test

Use the existing runner with an alternate MPSS configuration:

```bash
bash tools/kernel/run-candidate-base-cpio-control.sh \
  --base "$XPR_SPLIT_BUILD/xpr-bootstrap-base.cpio.gz" \
  --kernel "$XPR_KERNEL_BUILD/arch/x86/boot/bzImage" \
  --map "$XPR_KERNEL_BUILD/System.map" \
  --payload "$XPR_SPLIT_BUILD/payload/xpr-rootfs.cpio.gz" \
  --expected-stock-sha YOUR_RECORDED_STOCK_CONFIG_SHA256 \
  --out-root /root/xpr-build/hardware-runs
```

By default the runner performs bounded polling, executes the release smoke
suite, and restores stock MPSS through its exit trap. Use `--leave-running`
only for an attended inspection session; it suppresses rollback only after all
required checks pass.

## 10. Required Success Evidence

A build is not an RC merely because files were produced. Require:

- `XPR_RC_ROOT_SBIN_INIT_PID1`
- `uname -m` equals `k1om`
- `ID=xpr-uos`
- final-root micveth and Dropbear SSH
- native hello and pthread success
- dpkg/APT local-repository checks
- Python 3.12, `ctypes`, and `python_exit_helper`
- usable `/proc`, `/sys`, `/dev`, `/run`, `/tmp`, and interactive PTYs
- stock rollback, stock SSH, and exact stock configuration hash restoration

See the [RC Acceptance Checklist](../ubuntu-port/uos-rc-acceptance-checklist.md)
for the complete gate.

## Current Reproducibility Gap

The repository has deterministic assemblers and a proven hardware path, but it
does not yet provide a single public command that recreates every accepted
binary from redistributable source. The highest-value remaining build work is:

1. Pin and publish permissible corresponding source, configs, and patches for
   the compatibility kernel and modules.
2. Rebuild or remove lineage-uncertain BusyBox, `libgcc_s`, and userland inputs.
3. Generate a complete provenance manifest and SPDX-style SBOM.
4. Rebuild the exact publishable artifact and rerun the full hardware and
   rollback suite.

Until those gates pass, publish the source/BYO-MPSS archive and keep private
boot images local.
