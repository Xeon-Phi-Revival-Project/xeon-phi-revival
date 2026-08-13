# xpr-init RSA Validation, 2026-08-12

Tested hardware: Intel Xeon Phi 5110P, CentOS 7.4 host, Intel MPSS 3.4.10,
`mic0`. The test began from the verified stock configuration hash
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.

## Host Fixtures

`tools/host/test-xpr-init-install.sh` passed. It covers explicit, zero, one,
multiple, reusable, and incomplete key states; install/reinstall/recovery;
status output; and the payload-stdin regression check.

## Live Generated-Key Flow

A fresh disposable invoking user with an empty `.ssh` directory ran
`xpr-init --install`. The helper generated:

```text
/home/xprkeylive/.ssh/xpr_os_rsa
/home/xprkeylive/.ssh/xpr_os_rsa.pub
```

The generated `.ssh` directory was owned by the invoking user with mode `700`;
the private key was mode `600`; and the public key was mode `644`. Neither key
appeared under the installed XPR artifacts. The private key was used only by
the host to authenticate to the deployment.

The documented `micctrl --reset`, `--wait`, and `--boot` sequence passed.
Automatic handoff reached final XPR PID 1, micveth, authenticated SSH with the
generated key, `xpr-hello`, `xpr-pthread-smoke`, and `xpr-dlopen-smoke`.

`xpr-init --recover` restored the exact stock configuration hash. `mic0`
returned online; stock SSH reported `k1om` and PID 1 `init`.

## Fresh-User-State Validation

This was a fresh-user-state validation on the existing known-good CentOS 7.4 +
MPSS 3.4.10 host, not a fresh CentOS/MPSS installation. Recovery had removed
the active XPR state and handoff unit while preserving historical recovered
state and deployment artifacts. A new isolated user had one RC6 archive in
`~/Downloads` and no RSA keys.

The literal `git clone` command could not run because Git was absent from the
tested host. This was the only beginner documentation gap found; the guide now
states the tested CentOS command to install Git. To avoid silently installing
extra host packages during validation, an exact copy of the current helper was
placed in an isolated test tree instead. The no-argument install then passed
archive discovery, generated the dedicated RSA key, completed automatic
handoff, final SSH, and all three smoke programs. Recovery again restored the
exact stock hash and stock SSH.

## Cold-Reboot Validation

PASS. After one normal host reboot, the saved XPR state, stock backup, deployed
files, active XPR MPSS configuration, and enabled handoff unit all persisted.
No reinstall was run or required.

When the host returned, `mic0` was already reported online using the installed
XPR kernel. No XPR-owned automatic boot wrapper and no `xpr-init --boot` command
had been added. The exact MPSS startup path responsible for that observed card
boot was not isolated during this validation and is therefore not generalized
to other MPSS hosts.

For conservative lifecycle coverage, the documented reset/wait/boot sequence
was still exercised during the validation. The persisted handoff service then
reached final XPR PID 1, micveth, generated-key SSH, `xpr-hello`,
`xpr-pthread-smoke`, and `xpr-dlopen-smoke` again.

Recovery after the reboot test restored the exact stock configuration hash
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51` and
stock SSH (`k1om`, PID 1 `init`).

## Validated Claims

For the tested 5110P + CentOS 7.4 + MPSS 3.4.10 baseline, the evidence supports
all of the following:

- `xpr-init` can perform a no-argument first-use install when release discovery
  is unambiguous;
- a dedicated RSA key pair is generated safely when no compatible RSA key is
  present;
- the generated private key remains host-only;
- automatic bootstrap-to-final-root handoff works;
- final PID 1, micveth, authenticated SSH, and the three runtime smokes work;
- host-side XPR installation/state persists through a normal reboot;
- reinstalling XPR after that reboot is unnecessary;
- `mic0` was observed online with the XPR kernel after that reboot on this host;
  and
- recovery repeatedly restores the exact known stock MPSS configuration and
  stock runtime state.

The validation does not establish a literal fresh CentOS/MPSS installation, nor
does it prove identical automatic card-start behavior on other MPSS hosts.
