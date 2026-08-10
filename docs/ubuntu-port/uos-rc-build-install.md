# Building And Booting The K1OM uOS RC

This document records the release-candidate build lanes. It assumes a
compatible Knights Corner card, a working MPSS 3.4.x host, and locally supplied
K1OM SDK/runtime inputs. It does not download or redistribute proprietary Intel
payloads.

## Current Split-Root Lane

The accepted 0.1.0-rc1 path is assembled with
`tools/release/build-split-root-control.sh`, prepares the final payload with
`tools/release/prepare-xpr-rootfs-payload.sh`, and uses the bounded candidate
runner documented by the kernel experiment reports. It boots a project-built
compatibility kernel and bootstrap, transfers the final payload over bootstrap
SSH, verifies its size and SHA-256, and enters the final root through the
project static switch helper and init trampoline.

The exact local source, toolchain, module, key, and payload paths are private
host inputs and are intentionally not hard-coded as portable defaults. Every
live run must use an alternate MPSS configuration, bounded polling, an active
rollback trap, and the expected stock configuration hash.

The older MicDir profile flow below remains useful for rebuilding the package
set, but it is no longer the authoritative final-root boot result.

## Supported Hardware

Current live validation is on an Intel Xeon Phi 5110P / Knights Corner card
attached to a Dell PowerEdge R730 host running CentOS with MPSS 3.4.10.
Other x100/KNC cards may work, but must be treated as unverified until their
MPSS boot, SSH, thermals, and rollback behavior pass the same smoke tests.

## Required Local Inputs

The scripts require paths to locally supplied or locally built inputs:

- MPSS K1OM sysroot, usually `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux`.
- Locally extracted stock MPSS uOS rootfs used only as a private input for
  required stock-compatible files such as `/bin/busybox`.
- Eglibc 2.19 K1OM runtime root containing `ld-linux-k1om.so.2`, `libc.so.6`,
  `libpthread.so.0`, `libm.so.6`, `libdl.so.2`, `librt.so.1`, and
  `libutil.so.1`.
- Rebuilt eglibc-linked smoke payload root.
- Runtime-library root for zlib, ncurses, readline, and related smokes.
- CPython 3.12.13 K1OM root.
- Eglibc-linked libffi root for `_ctypes`.

These inputs are not committed because they may contain locally supplied MPSS
material or binaries whose redistribution status has not been reviewed.

## Legacy MicDir Profile Build

Run on the MPSS host:

```bash
tools/ubuntu-port/build-k1om-uos-rc.sh \
  --payload-rootfs /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/payload-rootfs \
  --libc-root /opt/xeon-phi-revival/eglibc-2.19 \
  --runtime-root /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/runtime-root-stockpaths \
  --python312-root /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/python312-eglibc-root \
  --libffi-root /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/libffi-eglibc-prefix/lib64 \
  --stock-rootfs /root/xeon-phi-revival-local/uos-boot-builds/repacked-stock-control-20260728-050610/rootfs
```

The command validates host tools and local inputs, builds the package set,
indexes the local `binary-k1om` archive, audits packages, simulates install,
assembles a coherent rootfs, validates it, creates a private rootfs archive,
and emits checksums and manifests.

## Legacy MicDir Reversible Boot And Smoke Test

Before live boot, set the expected hash for the active MPSS config:

```bash
export EXPECTED_CONF_SHA=9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

Then run:

```bash
tools/ubuntu-port/boot-k1om-uos-rc-micdir.sh \
  --tools-dir tools/ubuntu-port \
  --payload-rootfs /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/payload-rootfs \
  --libc-root /opt/xeon-phi-revival/eglibc-2.19 \
  --runtime-root /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/runtime-root-stockpaths \
  --python312-root /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/python312-eglibc-root \
  --libffi-root /root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/libffi-eglibc-prefix/lib64
```

The boot command uses the existing MicDir package installation path, leaves the
RC profile active only long enough to run `run-k1om-uos-rc-smoke.sh`, then runs
the generated rollback script and verifies stock MPSS recovery.

## Recovery

Every live run creates a timestamped private run directory containing a
`rollback-stock.sh` script generated from the backups taken before overlaying
MicDir. If the boot command exits early, its trap attempts to run that rollback.

Manual recovery path:

```bash
/path/to/run/k1om-bootstrap-package-set-*/rollback-stock.sh
micctrl --status
ssh -o ConnectTimeout=6 -o ConnectionAttempts=1 mic0 'cat /proc/1/comm'
```

Expected stock result:

```text
stock_ssh_ok
profile_absent
stage2_log_absent
init
```

## Redistribution

The repository may contain project scripts, public-safe manifests, and source
patches with their original licenses. It must not contain Intel MPSS SDK files,
stock uOS contents, firmware, private rootfs images, generated K1OM binaries,
or archives whose redistribution rights have not been reviewed.

Use `tools/release/package-public-rc.sh` to create the public source/metadata
prerelease archive. It packages tracked Git content only and rejects common
binary/private payload patterns. `tools/ubuntu-port/package-k1om-uos-rc-release.sh`
remains available for private-build metadata; by default it also excludes the
generated rootfs.
