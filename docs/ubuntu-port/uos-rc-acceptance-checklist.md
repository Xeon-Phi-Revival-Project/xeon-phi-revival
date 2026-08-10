# Xeon Phi Revival uOS Release-Candidate Acceptance Checklist

This checklist defines the first usable and reproducible K1OM uOS release
candidate for Intel Xeon Phi Knights Corner cards. It is intentionally
practical: MPSS remains a host prerequisite, while the tested card-side root,
PID 1, networking setup, and SSH service are project controlled.

## Claim Boundary

The RC may be described as:

```text
A minimal Ubuntu-derived K1OM uOS environment for Intel Xeon Phi Knights
Corner, booted through MPSS/MicDir, using a project-built eglibc runtime,
native package management, a coherent root filesystem, Python 3.12, and
reproducible public build and installation procedures.
```

It must not be described as an official Ubuntu, Canonical, or Intel release.
It does not replace firmware or the installed MPSS host driver. The accepted
private build uses a project-built compatibility kernel and rebuilt card-side
modules, produced from source with locally supplied toolchain inputs.

## Required Pass Items

- Reproducibly generated private root filesystem.
- Rootfs archive and SHA-256 report.
- Artifact manifest with source provenance and redistribution classification.
- Project identity in `/etc/os-release`:

```text
NAME="Xeon Phi Revival uOS"
PRETTY_NAME="Xeon Phi Revival K1OM uOS"
ID=xpr-uos
ID_LIKE=ubuntu
VERSION_ID="0.1"
ARCHITECTURE="k1om"
```

- Working `/bin/sh`.
- XPR-OS ASCII identity banner appears on the boot console and interactive SSH
  login without contaminating non-interactive SSH output.
- Basic commands available and tested: `ls`, `cat`, `cp`, `mv`, `rm`, `mkdir`,
  `mount`, `uname`, `ps`, and `env`.
- Usable `/dev`, `/proc`, `/sys`, `/run`, and writable `/tmp`.
- `devpts` is mounted, `/dev/ptmx` is usable, and an interactive SSH shell can
  allocate a PTY.
- Native K1OM package commands: `dpkg`, `dpkg-query`, `dpkg-deb`, `apt-get`,
  and `apt-cache`.
- `dpkg --print-architecture` returns `k1om`.
- `apt-get update` works against the local file repository.
- Local package installation or reinstallation works.
- Python 3.12 runs as `python3`; `python` should also select Python 3.12.
- Python's normal interactive `exit()` and `quit()` helpers are available.
- Python smoke passes core imports, zlib, `_ctypes` calls, and `_ctypes`
  callbacks.
- Pthread-linked native smoke passes.
- zlib smoke passes.
- ncurses smoke passes.
- Networking is visible from the final project root.
- SSH works after boot.
- Final project PID 1 and root identity are visible.
- Reversible MicDir installation preserves and checksums the original MPSS
  configuration.
- Failure path restores stock MPSS.
- Success path verifies rollback to stock MPSS.
- Public rebuild scripts and manifests are committed.
- No proprietary Intel payloads, extracted sysroots, firmware, private rootfs
  images, or uncertain-redistribution binaries are committed.

## Non-Blocking For RC 0.1

The first RC should report these as known limitations rather than blocking the
release candidate unless a core smoke requires them:

- `_ssl`
- `_hashlib`
- network package repositories over HTTPS
- Noble APT 2.8
- firmware replacement
- host-driver replacement
- systemd
- GUI support
- every Python extension module
- optimization work

The following Python modules are desirable and should be accepted when present
in the supplied Python 3.12 root, but the RC may still proceed if they are
reported as optional gaps in the eglibc profile:

- `bz2`
- `lzma`
- `readline`
- `sqlite3`
- `curses`
- `curses.panel`

## Evidence Files

A passing RC run should produce private host-side evidence under a timestamped
directory:

- `build.log`
- `build-summary.txt`
- `release-candidate.yml`
- `artifact-manifest.tsv`
- `k1om-minimal-ubuntu-rootfs-manifest.tsv`
- `k1om-minimal-ubuntu-rootfs-sha256.tsv`
- `xpr-uos-0.1-k1om-rootfs.tar.gz.sha256`
- `uos-rc-smoke.log`
- `rollback.log`

Only public-safe summaries and manifests should be committed.
