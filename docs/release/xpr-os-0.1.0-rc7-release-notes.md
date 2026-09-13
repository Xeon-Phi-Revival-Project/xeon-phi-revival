# XPR-OS v0.1.0-rc7

RC6 proved the revived operating environment. RC7 makes that environment more
practical to use by adding source-accounted CPython 3.12.13 and packaging the
`xpr-init` host integration path with an isolated XPR SSH alias. This remains prerelease software
for legacy Intel Xeon Phi hardware.

## Highlights

- CPython 3.12.13 is included and hardware-validated on the Xeon Phi 5110P.
- `xpr-init` provides installation, automatic final-root handoff, status, and
  exact stock recovery.
- The public-clean root uses fresh source-built K1OM runtime inputs.
- First installation configures `ssh xpr-mic0` with a persistent,
  deployment-specific server identity and strict host-key checking.
- Exact candidate validation and reproducibility results accompany the frozen
  archives as external evidence; embedded metadata is not changed after testing.

## Python

Python is installed at `/usr/bin/python3.12`; `python3` and `python` resolve to
that interpreter. The build is source-accounted, reports K1OM, and includes the
core standard-library profile validated for RC7. Hardware tests covered `sys`,
`os`, `pathlib`, `json`, `math`, `threading`, and `platform`, including a real
threaded calculation. Broad optional extension-module support is not claimed.

The known `Could not find platform dependent libraries <exec_prefix>` warning
may appear; the documented core functionality passed despite it.

## Validation

The tested hardware baseline is Intel Xeon Phi 5110P with CentOS 7.4 and MPSS
3.4.10. Exact Candidate G2 passed installation, automatic handoff, native/Python
smokes, plain `ssh xpr-mic0`, card reboot/reuse, reinstall, and exact stock
recovery. See the [G2 validation record](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/v0.1.0-rc7/docs/release/xpr-os-0.1.0-rc7-candidate-g-validation.md).
Testing used an existing working CentOS 7.4 + MPSS 3.4.10 installation.
Fresh host-OS and MPSS installation from scratch was not validated.
The card-only reboot test explicitly rearmed the one-shot handoff service;
automatic card-reset detection is not claimed.

## Reproducibility And Source Accounting

The release set pairs the binary archive with corresponding source, SPDX 2.3,
and notices/licenses. Consult external checksums and validation results for the
exact candidate. Generic archives contain no deployment keys; installation
creates private per-host deployment images instead.

## Host Workflow

Follow the [tested RC7 guide](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/v0.1.0-rc7/docs/getting-started/rc7.md) for artifact
verification, bounded final-root readiness, SSH, Python and recovery. The
reference below is not a substitute for waiting for readiness after boot.

From the extracted binary release directory on the MPSS host, install
`xpr-init`, select the verified binary archive, and use the normal lifecycle.
Replace the example archive path with its actual location:

```bash
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init
sudo xpr-init --install --release /absolute/path/to/xpr-os-0.1.0-rc7.tar.gz
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
# Complete the final-root readiness check in the guide before connecting.
ssh xpr-mic0
# Now on the card:
python3 --version
```

Bare `sudo xpr-init --install` also supports automatic search when exactly one
candidate is found. The explicit path above avoids ambiguity or a release
stored outside the searched locations; it does not disable automatic key setup.

When finished, exit the card shell, then run `sudo xpr-init --recover` on the
MPSS host. After recovery, use normal `ssh mic0`.
Installation preserves the user's normal stock SSH configuration and known-host
records. The XPR alias and its separate `~/.ssh/xpr_os_known_hosts` persist for
reinstallation; the alias must not authenticate stock uOS while stock is active.
The client private key stays on the host. A separate ECDSA P-256 server key is
stored privately under `/var/lib/xpr-init/ssh/mic0` and provisioned into the
RAM-backed deployment roots. Do not share those private deployment images.

## Limitations

- RC7 is a prerelease and is not a modern production-ready Linux distribution.
- Hardware validation currently centers on the tested Xeon Phi 5110P setup.
- Physical-card host control still uses separately obtained MPSS, `micctrl`,
  and `xpr-init`.
- A standalone source-built K1OM toolkit has been technically validated, but
  its separate public release remains held for qualified review. Its binary is
  not an RC7 asset.

## Frozen Release Identity

This release distributes Candidate G2, built from source revision
`079521e895b82fb3ccec2fe0b29cfb3ea0e1bb1d`. Later tagged documentation records
its hardware validation and tested beginner workflow; the artifacts were not
rebuilt after those documentation updates.

Binary SHA-256: `6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c`

Source SHA-256: `9d1261fd42f87697ee84b3cff749487c92bf11eb9eba952fcf6ead3be6df4c4a`

## Artifacts

- `xpr-os-0.1.0-rc7.tar.gz`
- `xpr-os-0.1.0-rc7-sources.tar.gz`
- `xpr-os-0.1.0-rc7.spdx.json`
- `xpr-os-0.1.0-rc7-notices.tar.gz`
- `SHA256SUMS`

Use the external `SHA256SUMS`; an archive cannot embed its own final hash.

Use these five named assets rather than GitHub's automatic source snapshots.
Full sizes and hashes are in the [artifact inventory](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/blob/v0.1.0-rc7/docs/release/xpr-os-0.1.0-rc7-artifact-inventory.md).
The separately held standalone toolkit is not part of this prerelease.
