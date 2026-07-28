# Contributing

This project accepts public-safe preservation notes, original scripts, original
test programs, manifests, and metadata reports.

Do not submit:

- Intel MPSS RPMs, tarballs, ISOs, firmware, or extracted sysroots.
- Intel compiler installers or licensed runtime payloads.
- Copied Intel documentation, book excerpts, or proprietary source files.
- Statically linked binaries that may embed redistributability-unclear runtime
  code.
- SSH keys, credentials, private hostnames, serial numbers, or private lab
  network details.

Good contributions include:

- Original source code for small K1OM tests.
- Public-safe command transcripts and summarized results.
- Package names, versions, hashes, and file-list metadata.
- Reproducible scripts that operate on locally supplied MPSS/toolchain inputs.
- Documentation that separates observed facts from inference.

Before opening a pull request, run the publication audit patterns described in
`docs/publication-audit-20260727.md` if that file exists, and review generated
files for private paths or proprietary payloads.
