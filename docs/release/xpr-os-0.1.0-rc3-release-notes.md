# XPR-OS 0.1.0-rc3 Review Candidate

Status: **private staging only; human legal review pending**

This candidate packages the exact source-accounted K1OM artifacts that passed
three consecutive boots on an Intel Xeon Phi 5110P. It is not an official
Ubuntu, Intel, or Canonical release and has not been published.

## Validated Behavior

- Project kernel and five K1OM modules boot through MPSS 3.4.10.
- The project final root runs project `/sbin/init` as PID 1.
- `micveth`, final-root Dropbear SSH, dynamic hello, pthread, and `dlopen`
  probes pass.
- Each bounded test restores stock MPSS state and SSH.

## Host Requirement

The user must separately obtain and install Intel MPSS 3.4.10 on a compatible
Linux host. The archive does not contain Intel firmware, MPSS packages, or
stock card-side userspace.

## Verification

From the extracted archive:

```sh
sha256sum -c SHA256SUMS
./tools/verify.sh --archive ../xpr-os-0.1.0-rc3.tar.gz --version 0.1.0-rc3
```

The verifier checks the complete member checksum list, the frozen hardware-
tested artifact hashes, prohibited package/firmware types, and common secret
patterns.

## Publication Gate

Automated technical and provenance checks pass. Publication remains blocked
until a qualified human confirms the GPLv2 distribution analysis for the five
module binaries and reviews the exact staged source and binary archives.
