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
- Hardware compatibility reports with card model, PCI ID, host OS, MPSS
  version, XPR-OS release, command output, and rollback result.
- Public-safe command transcripts and summarized results.
- Package names, versions, hashes, and file-list metadata.
- Reproducible scripts that operate on locally supplied MPSS/toolchain inputs.
- Documentation that separates observed facts from inference.

## Documentation Changes

Use [the documentation map](docs/README.md) to decide whether a change belongs
in a current guide or a historical experiment report. Do not rewrite old
evidence to match a later result. Add a short supersession notice and update
`docs/status.md`, the relevant current guide, and navigation links instead.

Check relative Markdown links and run `git diff --check` before submitting a
documentation-only change. Commands in guides must identify whether they are
host-side, card-side, build-only, or hardware-mutating.

For a user-facing documentation change, also run:

```bash
python3 tools/docs/validate-active-docs.py
```

Before opening a pull request, run the publication audit patterns described in
`docs/publication-audit-20260727.md` if that file exists, and review generated
files for private paths or proprietary payloads.
