# K1OM Bootstrap Package Report

Public-safe report for the first working package-built K1OM profile artifact.

## Status

Status: passed.

This is the first working package/archive milestone for the K1OM Ubuntu-port
lane. It is not a complete Ubuntu port. It proves that a local `k1om`
architecture package can be built, indexed, installed into MPSS MicDir staging,
booted on `mic0`, and rolled back.

## Package

```text
Package: xeon-phi-revival-profile
Version: 0.1.0
Architecture: k1om
Format: .deb structure built from debian-binary, control.tar.gz, data.tar.gz
```

Public metadata lives at:

```text
ubuntu-port/k1om/packages/xeon-phi-revival-profile/control
```

Private package output:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-profile-package-20260728-164608/repo/pool/main/x/xeon-phi-revival-profile/xeon-phi-revival-profile_0.1.0_k1om.deb
```

Private package SHA-256:

```text
8d35d386b06fc0727b67fe31c2e98b4ee5374ba4a49e9fa1cffe5abb7bd22740
```

The package is not committed because it contains locally supplied K1OM binaries
and Python payload files.

## Local Archive

The experiment generated:

```text
dists/noble/Release
dists/noble/main/binary-k1om/Packages
pool/main/x/xeon-phi-revival-profile/xeon-phi-revival-profile_0.1.0_k1om.deb
```

The `Packages` stanza included:

```text
Package: xeon-phi-revival-profile
Version: 0.1.0
Architecture: k1om
Filename: pool/main/x/xeon-phi-revival-profile/xeon-phi-revival-profile_0.1.0_k1om.deb
SHA256: 8d35d386b06fc0727b67fe31c2e98b4ee5374ba4a49e9fa1cffe5abb7bd22740
```

## Tools

```text
tools/ubuntu-port/build-k1om-profile-deb.sh
tools/ubuntu-port/index-k1om-local-archive.sh
tools/ubuntu-port/install-k1om-profile-deb-to-micdir.sh
tools/ubuntu-port/run-k1om-profile-package-experiment.sh
```

These tools are public-safe recipes. The artifacts they generate are private
unless built only from redistributable sources.

## Live Result

Run:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-profile-package-20260728-164608
```

Observed on `mic0`:

```text
package_profile_ssh_ok
XPR_PROFILE_VERSION=0.1.0
XPR_PROFILE_KIND=stock-init-handoff-second-stage
XPR_PHASE=profile
pid1=init
hello_rc=0
python_rc=0
machine=k1om
python stage2 demo ok
prefix=/opt/xeon-phi-revival
```

Rollback verification:

```text
stock_ssh_ok_after_retry
stage2_log_absent
profile_absent
init
```

## Meaning

The project now has a working package-built bridge:

```text
k1om package metadata -> local unsigned archive -> MicDir staging install -> stock MPSS boot -> project profile service
```

The next Ubuntu-port step is to add more package recipes and dependency metadata
around this working install target: `base-files-k1om`, `zlib`, `ncurses`,
`python3.5-core`, and a smoke-test package.

