# Publication Audit 2026-07-27

Pre-stage audit for the first public Xeon Phi Revival repository history.
No files were staged, committed, tagged, pushed, or published during this audit.

## Repository State

- Git repository already exists locally.
- Current branch before commit prep: `master`.
- Commit history: none.
- Remote: none configured.
- Preferred public repository:
  `Xeon-Phi-Revival-Project/xeon-phi-revival`.
- Read-only GitHub API check for that exact repository returned `404 Not Found`.

## Proposed Inclusion Set

Include original project work and public-safe metadata:

- `README.md`
- `.gitignore`
- `.gitattributes`
- `NOTICE.md`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `docs/`
- `tests/`
- `tools/`
- `toolchains/`
- `uos/`
- `experiments/`
- `manifests/`
- `artifacts/public/`
- `xeon_phi_revival_development_plan.md`

Candidate count after ignore rules: 88 files.

## Required File Status

- `README.md`: present.
- `.gitignore`: present and tightened for public boundary.
- `.gitattributes`: present to keep scripts, source files, docs, and manifests
  LF-normalized.
- `NOTICE.md`: present.
- `CONTRIBUTING.md`: present.
- `SECURITY.md`: present.
- `LICENSE`: present, MIT License for original project work.

## Exclusion Set

Excluded by `.gitignore` and not intended for public history:

- MPSS tarballs and binary fragments:
  - `mpss-*.tar`
  - `mpss-*.tar.*`
  - `MPSS_*.bin`
- Firmware or firmware-adjacent payloads:
  - `EXT_*.rom.smc`
- Extracted or inspected Intel payloads:
  - `mpss-src-inspect/`
  - `mpss-doc-extract/`
- Extracted/copyrighted book or public-document text:
  - `*.extracted.txt`
  - `327364-001-jul24_djvu.txt`
  - `apress-xeon-phi-source-scan/`
- Raw logs, screenshots, Redfish inventory, and one-off operational scripts:
  - `*.log`
  - `vnc-*.bmp`
  - `idrac-redfish-inventory.json`
  - `remote_*.sh`
  - `build_patched_*.sh`
- Build outputs and executable payloads:
  - `build/`
  - `dist/`
  - `out/`
  - `*.o`
  - `*.out`
  - `*.exe`
  - `*.so*`
  - `*.elf`

## Sanitization Performed

- Replaced private Windows archive path with `<local-mpss-archive>`.
- Replaced `/root/...` MPSS extract paths with `<local-mpss-extract>`.
- Replaced `/root/xeon-phi-revival-local` with `<local-private-workdir>`.
- Removed public lab host IP from hardware docs/manifests.
- Replaced `micinfo` serial value with `omitted-public`.
- Replaced raw MIC hostname with `mic0.local`.
- Removed the superseded vector placeholder run report from publication
  candidates, keeping the real zmm-vector report instead.
- Changed script defaults from `/root/...` to `$HOME`/environment-variable
  based local paths.

## Audit Findings

Secret/private-data search covered candidate files for:

- `password`, `passwd`
- `secret`
- `token`
- `authorization`
- `bearer`
- private key markers
- SSH public-key markers
- private LAN IP patterns
- Windows absolute paths
- `/root/` paths
- known lab passwords
- observed card serial pattern
- raw MIC hostnames

Remaining hits after sanitization are considered public-safe metadata:

- `passwd` appears in stock uOS file names such as `/usr/bin/passwd.shadow` and
  SDK file-list entries such as `yppasswd.h`.
- `token` appears in SDK file-list entries such as `token.py` and
  `locfile-token.h`.
- `mic0` appears as technical target/device context and is intentionally kept.
- MPSS virtual addresses `172.31.1.1` and `172.31.1.254` are intentionally kept
  because they document default MPSS card/host networking.

No candidate binary files with NUL bytes were detected.

## Validation Results

Passed:

- Git Bash `bash -n` syntax check for 13 shell scripts.
- JSON parsing for 1 JSON file with PowerShell `ConvertFrom-Json`.
- Stale blocker search found no remaining claims that native K1OM compilation
  or `hello-knc` execution is blocked.
- Referenced native-run report files exist.
- Public candidate file set contains no RPMs, tarballs, firmware images,
  extracted sysroots, shared libraries, object files, executables, screenshots,
  or copied PDF/book payloads.

Not run:

- Python syntax checks. The only discovered Python executables were Windows
  Store shims and were not usable.
- YAML parser validation. No local YAML parser was available without installing
  additional tooling.

## Legal Boundary

Publication candidates contain original scripts, original tests, original
documentation, manifests, hashes, file-list metadata, ELF observations,
dependency metadata, and short disassembly evidence from project-written test
programs.

Publication candidates do not intentionally include Intel RPMs, Intel firmware,
Intel compilers, stock uOS images, extracted sysroots, Intel libraries, Intel
headers, copied Intel documentation, or compiled K1OM binaries.

## Proposed Commit Structure

Recommended single first milestone commit:

```text
Validate native K1OM execution on Xeon Phi 5110P
```

Recommended annotated tag after commit:

```text
v0.1.0-native-k1om-baseline
```

Tag message:

```text
First verified native K1OM development baseline on an Intel Xeon Phi 5110P using MPSS SDK 3.4.10.
```

## Proposed GitHub Repository

- Owner: `Xeon-Phi-Revival-Project`
- Repository: `xeon-phi-revival`
- Visibility: public, only after explicit approval.
- Description:
  `Preservation, tooling, documentation, and experimental software development for Intel Xeon Phi Knights Corner and K1OM.`

## Current Blockers

1. Optionally install or expose a local Python/YAML parser if full syntax
   validation is required before the first commit.
2. Wait for explicit approval before staging, committing, creating a GitHub
   repository, tagging, or pushing.
