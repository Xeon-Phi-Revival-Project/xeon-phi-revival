# Ubuntu 24.04 uOS Lab

This directory contains public-safe notes and scripts for the Ubuntu 24.04 uOS
research track.

The local experiment target is a K1OM root filesystem assembled from
license-reviewed project outputs and user-supplied MPSS runtime files. The
private rootfs contents must not be committed here.

## First Target

Build and test a tiny K1OM rootfs before adding Ubuntu-derived package work:

```text
init
shell
basic tools
loader and core libraries
hello-knc
logs
```

The staging helper is:

```bash
bash tools/uos/stage-tiny-k1om-rootfs.sh \
  --stock-rootfs "$HOME/xeon-phi-revival-local/uos-rootfs/stock-mpss-3.4.10" \
  --out "$HOME/xeon-phi-revival-local/uos-rootfs/tiny-k1om-level1" \
  --hello-knc "$HOME/xeon-phi-revival-work/build/smoke/hello-knc"
```

Validate the staged metadata with:

```bash
bash tools/uos/validate-tiny-k1om-rootfs.sh \
  "$HOME/xeon-phi-revival-local/uos-rootfs/tiny-k1om-level1"
```

## Local-Only Inputs

Expected private inputs, all ignored by `.gitignore`:

- stock MPSS uOS extraction
- MPSS SDK sysroot/runtime files
- locally built K1OM binaries
- test rootfs images
- boot logs with host-specific addresses or credentials

## Public Outputs

Safe outputs can include:

- manifests
- file names and paths
- dependency graphs
- hashes
- build recipes
- failure matrices
- sanitized boot summaries

## Level 2 Gate

Do not begin Ubuntu 24.04 source-package rebuilds until Level 1 has either:

- run basic K1OM commands from the staged tiny rootfs, or
- produced a precise blocker explaining why the staged rootfs cannot be tested
  under the stock MPSS boot model yet.
