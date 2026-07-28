# K1OM Ubuntu Port Lab

This directory contains public-safe metadata and tooling for an experimental
Ubuntu architecture port targeting Intel Xeon Phi Knights Corner / K1OM.

This is not a finished Ubuntu port. It is the bootstrap lane for turning the
working K1OM userland experiments into reproducible package and archive
metadata.

## Architecture Sketch

- Architecture name: `k1om`
- Practical compiler tuple: `k1om-mpss-linux-gnu`
- Loader: `/lib64/ld-linux-k1om.so.2`
- ELF machine: `EM_K1OM` / `181`
- ABI: LP64

## Contents

- `dpkg/`: proposed dpkg architecture metadata overlays.
- `repo-skeleton/`: local archive layout skeleton.
- `package-status.tsv`: source package status matrix.

No binary packages, MPSS files, sysroots, firmware, or uOS payloads belong here.
