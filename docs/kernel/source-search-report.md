# MPSS 3.4.10 Corresponding-Source Search

Date: 2026-08-01

## Locations Searched

- repository source and documentation;
- local MPSS archive `/root/mpss-3.4.10-linux.tar`;
- extracted local MPSS source-RPM area;
- local driver re-inspection archives;
- `/opt`, `/root`, and yum cache locations on the MPSS host;
- configured package repository metadata.

## Results

The local module source RPM and tarball described in
`source-package-provenance.md` were found. No source RPM or source tree for
`glibc2.12pkg-mpss-boot-files-3.4.10-1.glibc2.12`, the KNC kernel, its config,
or its K1OM patch series was found.

## Blocker

The project can audit and potentially build the module source candidate only
after obtaining the exact compatible KNC kernel source and configuration. It
must not ship the local kernel or modules until that correspondence is proven.
