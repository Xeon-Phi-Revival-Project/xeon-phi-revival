# Build XPR-OS RC From Source

This is the shortest honest path from the paired source archive to the current
XPR-OS release-candidate outputs. It covers two different products:

1. A fully public source/metadata archive that contains no boot binaries.
2. A bootable split-root image assembled from source-accounted source archives,
   project recipes, and a separately obtained MPSS K1OM toolchain.

The generated bootstrap and final-root CPIO containers have no historical CPIO
input. The host toolchain remains an external prerequisite and is not included
in a public archive.

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
| BusyBox, Dropbear, eglibc, GCC sources | The pinned archives from the paired source bundle |
| XPR configs and overlays | The paired source bundle's `repository/` tree |
| Public Linux headers | Exported from the pinned Solros source before building the runtime |

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

## 7. Build Source-Accounted Components And Containers

First build BusyBox, the eglibc runtime, libgcc, Dropbear, and XPR helpers from
the pinned source archives with the repository recipes. Their output paths are
explicit build inputs to the container constructor; no private CPIO is accepted.

After those component builders have completed, construct both the inner
bootstrap root, outer Base CPIO, and final root/payload:

```bash
bash tools/release/build-rc5-containers.sh \
  --busybox /root/xpr-build/busybox/busybox \
  --dropbear /root/xpr-build/dropbear/dropbear \
  --eglibc-libdir /root/xpr-build/eglibc/stage/lib \
  --libgcc /root/xpr-build/libgcc/install/k1om-mpss-linux/lib64/libgcc_s.so.1 \
  --helpers /root/xpr-build/helpers \
  --module-root /root/xpr-build/modules \
  --cross-compile k1om-mpss-linux- \
  --kernel-release 2.6.38.8+mpss3.5.1 \
  --out-dir /root/xpr-build/containers
```

The command writes `final-root/xpr-rootfs.cpio.gz`,
`bootstrap-root/xpr-bootstrap-root.cpio.gz`, and `xpr-bootstrap.cpio.gz` with
`private_cpio_inputs=0` in `SHA256SUMS`. It does not modify MPSS or boot the
card.

## 8. Create Deployment-Only SSH Artifacts

The generic Base CPIO and final payload intentionally contain no SSH key. For a
local deployment, provide one operator-owned RSA public key. This produces two
keyed files outside the release archive: a Base CPIO whose nested bootstrap
root can accept the initial SSH connection, and a final payload with the same
key for the post-`switch_root` Dropbear server.

```bash
python tools/release/provision-xpr-authorized-key.py \
  --generic-bootstrap /root/xpr-build/containers/xpr-bootstrap.cpio.gz \
  --bootstrap-output /root/xpr-build/deploy/xpr-bootstrap.cpio.gz \
  --generic-payload /root/xpr-build/containers/final-root/xpr-rootfs.cpio.gz \
  --authorized-key ~/.ssh/id_rsa.pub \
  --output /root/xpr-build/deploy/xpr-rootfs.cpio.gz \
  --report /root/xpr-build/deploy/key-provisioning.json
```

Only a single structurally valid `ssh-rsa` public-key record is accepted. The
tool rejects private-key files, malformed Base64, malformed SSH wire data,
unsupported algorithms, and multi-line input.

## 9. Review Before Hardware Use

Record and inspect:

```bash
sha256sum \
  "$XPR_KERNEL_BUILD/arch/x86/boot/bzImage" \
  "$XPR_KERNEL_BUILD/System.map" \
  "/root/xpr-build/containers/xpr-bootstrap.cpio.gz" \
  "/root/xpr-build/containers/final-root/xpr-rootfs.cpio.gz"
cat "/root/xpr-build/containers/SHA256SUMS"
```

Also verify the active stock MPSS configuration hash and stock SSH before any
boot. Do not continue if the expected stock hash is unknown.

## 10. Run The Bounded Hardware Test

Use the existing runner with an alternate MPSS configuration:

```bash
bash tools/kernel/run-candidate-base-cpio-control.sh \
  --base /root/xpr-build/deploy/xpr-bootstrap.cpio.gz \
  --kernel "$XPR_KERNEL_BUILD/arch/x86/boot/bzImage" \
  --map "$XPR_KERNEL_BUILD/System.map" \
  --payload /root/xpr-build/deploy/xpr-rootfs.cpio.gz \
  --expected-stock-sha YOUR_RECORDED_STOCK_CONFIG_SHA256 \
  --out-root /root/xpr-build/hardware-runs
```

By default the runner performs bounded polling, executes the release smoke
suite, and restores stock MPSS through its exit trap. Use `--leave-running`
only for an attended inspection session; it suppresses rollback only after all
required checks pass.

## 11. Required Success Evidence

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

## RC5 Validation Status

RC5 container construction is source-accounted and rejects private historical
CPIO inputs. It remains an unpublished candidate until its exact generated
container hashes complete the bounded hardware, rollback, and independent
review gates.
