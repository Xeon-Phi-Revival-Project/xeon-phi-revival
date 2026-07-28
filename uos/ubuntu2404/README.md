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
