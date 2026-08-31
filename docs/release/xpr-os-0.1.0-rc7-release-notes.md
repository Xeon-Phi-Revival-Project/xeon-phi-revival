# XPR-OS v0.1.0-rc7

RC6 proved the revived operating environment. RC7 makes that environment more
practical to use by adding source-accounted CPython 3.12.13 and packaging the
validated `xpr-init` host integration path. This remains prerelease software
for legacy Intel Xeon Phi hardware.

## Highlights

- CPython 3.12.13 is included and hardware-validated on the Xeon Phi 5110P.
- `xpr-init` provides installation, automatic final-root handoff, status, and
  exact stock recovery.
- The public-clean root uses fresh source-built K1OM runtime inputs.
- A second clean staging produced byte-identical binary and source archives.
- The exact candidate passed final PID 1, networking, SSH, native runtime, and
  Python validation on real hardware.

## Python

Python is installed at `/usr/bin/python3.12`; `python3` and `python` resolve to
that interpreter. The build is source-accounted, reports K1OM, and includes the
core standard-library profile validated for RC7. Hardware tests covered `sys`,
`os`, `pathlib`, `json`, `math`, `threading`, and `platform`, including a real
threaded calculation. Broad optional extension-module support is not claimed.

## Validation

The exact binary archive listed below was tested on an Intel Xeon Phi 5110P
using CentOS 7.4 and MPSS 3.4.10. Automatic handoff reached the final XPR
`/sbin/init` as PID 1, micveth became ready, authenticated Dropbear SSH worked,
and the hello, pthread, and `dlopen` regression programs passed. Python 3.12.13
and its core/threading smoke passed. `xpr-init --recover` restored the exact
stock configuration hash and stock SSH; the recovered stock image used PID 1
`/sbin/init.sysvinit`.

## Reproducibility And Source Accounting

The second staging was byte-identical. The release set includes corresponding
source, a validated SPDX 2.3 SBOM, and a notices/license bundle. Static audits
found no Python 3.5 payload, MPSS SDK binary payload, private keys, or universal
administrator credentials.

## Host Workflow

After extracting the binary archive, install `xpr-init`, run its install step,
and use the normal MPSS lifecycle:

```bash
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init
sudo xpr-init --install
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
ssh mic0
python3 --version
```

Return to stock MPSS with `sudo xpr-init --recover`.

## Limitations

- RC7 is a prerelease and is not a modern production-ready Linux distribution.
- Hardware validation currently centers on the tested Xeon Phi 5110P setup.
- Physical-card host control still uses separately obtained MPSS, `micctrl`,
  and `xpr-init`.
- A standalone source-built K1OM toolkit has been technically validated, but
  its separate public release remains held for qualified review. Its binary is
  not an RC7 asset.

## Artifacts

- `xpr-os-0.1.0-rc7.tar.gz`
  - SHA-256: `a4b313ad4b696ebdfe8a406da18288d1903933a6d3a12a1a41da1a69f218e0a4`
- `xpr-os-0.1.0-rc7-sources.tar.gz`
  - SHA-256: `79bd109d097e105229266db7095f355fb17d431fe1f3310f8369621e475f61ad`
- `xpr-os-0.1.0-rc7.spdx.json`
  - SHA-256: `eb09d81c6ce10841724dd2a742832d551c30fca322fb1efbe57fd2434177cab8`
- `xpr-os-0.1.0-rc7-notices.tar.gz`
  - SHA-256: `5a76f612f09445d9af14a00dc5ee79f6ebe69a87350a07e0de49f139b2ebb924`
- `SHA256SUMS`
  - SHA-256: `484dea684a1ad695f525dcf788520387b470f265649c84d8b0dfb9aa17171e7d`

Publication and tagging remain subject to owner authorization.
