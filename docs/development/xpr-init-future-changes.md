# xpr-init Future Changes

This document is a parking lot and implementation roadmap for **future** `xpr-init`
work. It records ideas identified after live 5110P validation so they can be
implemented later without losing context or reopening already-solved design
questions.

Nothing in this document should be treated as implemented, supported, or
hardware-validated until the corresponding change is merged and tested.

Current validated baseline:

- Intel Xeon Phi 5110P
- CentOS 7.4 host
- Intel MPSS 3.4.10
- XPR-OS 0.1.0-rc6 runtime
- `xpr-init` automatic bootstrap-to-final-root handoff validated on hardware
- dedicated RSA-key generation validated on hardware
- fresh-user-state install flow validated on the existing known-good host
- one normal host reboot persistence cycle validated
- final XPR PID 1, micveth, authenticated SSH, hello/pthread/dlopen smokes: PASS
- `xpr-init --recover` repeatedly restored stock MPSS and the known baseline
  configuration hash

## Completed: Dedicated RSA Key Generation Fallback

If `xpr-init --install` cannot find a compatible RSA public key with a matching
private key, it creates an XPR-specific RSA key pair instead of stopping.

Dedicated key names:

```text
~/.ssh/xpr_os_rsa
~/.ssh/xpr_os_rsa.pub
```

Selection behavior:

1. Explicit `--authorized-key` / `--identity` wins.
2. If exactly one compatible RSA key pair is discoverable, use it.
3. If multiple compatible RSA candidates exist, list them and stop rather than
   guessing.
4. If no compatible RSA key exists, generate a dedicated XPR key pair.
5. Never overwrite an existing private key.
6. Never copy the private key into XPR-OS.
7. Provision only the public key into deployment-specific bootstrap/final-root
   images.

Evidence:

- focused host fixtures cover explicit, zero, one, multiple, reusable, and
  incomplete-key states;
- the live generated key belonged to the invoking test user with `700` `.ssh`,
  `600` private key, and `644` public key;
- automatic handoff, final PID 1, micveth, generated-key SSH, hello, pthread,
  dlopen, and stock recovery passed.

## Completed: Host Reboot Persistence Validation

`xpr-init --install` stores persistent host-side state, including deployment
artifacts, the saved stock MPSS configuration, active XPR MPSS configuration,
and the enabled handoff systemd service. The running card-side XPR-OS instance
is volatile and is not flashed to the card.

A normal reboot of the tested CentOS 7.4 + MPSS 3.4.10 host validated that:

- XPR host state persisted;
- `/opt/xpr-os` deployment artifacts persisted;
- the saved stock backup persisted unchanged;
- the active XPR MPSS configuration persisted;
- the handoff unit remained installed and enabled;
- `xpr-init --install` did not need to be rerun;
- final XPR PID 1, micveth, generated-key SSH, and all three runtime smokes
  passed after the reboot; and
- `xpr-init --recover` again restored the exact known stock configuration hash
  and stock SSH state.

### Observed host-start behavior

When the host returned from the validated reboot, `mic0` was already reported
online with the installed XPR kernel. No XPR-owned automatic card-boot wrapper
and no `xpr-init --boot` command had been installed.

The project has not yet isolated the exact MPSS startup path responsible for
that observed boot. Therefore the correct claim is:

> On the tested CentOS 7.4 + MPSS 3.4.10 host, `mic0` was observed online with
> the XPR kernel after reboot and the persisted handoff path completed
> successfully.

Do not generalize that into a guarantee that every MPSS host automatically boots
`mic0`. If the card is not online with XPR, the normal `micctrl --reset`,
`--wait`, and `--boot` lifecycle remains the explicit fallback.

## Completed: Fresh-User-State Validation

A fresh-user-state test was performed on the existing known-good CentOS 7.4 +
MPSS 3.4.10 host. It was intentionally **not** described as a literal fresh-OS
installation.

The test exercised:

- a first-use repository/helper path;
- RC6 archive auto-discovery;
- an isolated invoking user with no compatible RSA key;
- automatic dedicated RSA-key generation;
- no-argument `xpr-init --install`;
- normal hardware boot/handoff;
- final authenticated SSH;
- hello/pthread/dlopen smokes; and
- exact stock recovery.

The only concrete beginner documentation gap found was that Git was absent from
the host, causing the literal `git clone` step to fail. The tested CentOS guide
now documents `sudo yum install -y git` when Git is missing.

## Priority: First-Run UX and Error Messages

Most of the first-run path is now hardware-validated. Future work here should be
triggered by concrete user friction rather than speculative redesign.

Potential small improvements:

- `--help` examples for the common beginner flow;
- clearer distinction between `--authorized-key` (public key) and `--identity`
  (private key used by host-side SSH);
- more explicit confirmation of selected release/key before installation;
- concise human-readable success summary after install.

## Completed: Status Improvements

`--status` now reports:

- whether the handoff systemd unit is enabled and running;
- installed release path and version;
- whether the active `/etc/mpss/mic0.conf` still points to XPR artifacts;
- whether the saved stock backup hash still verifies;
- saved/current configuration hashes and mode;
- public-key hash and recovery availability; and
- `micctrl` state.

It remains non-destructive and does not require an online card to report
host-side state.

## Priority: Packaging and Distribution

`xpr-init` was developed after the frozen RC6 archives were published, so users
currently obtain RC6 separately and install the current helper from the GitHub
repository.

For a future XPR release, consider making `xpr-init` an explicit release
component so a new user does not need two separate acquisition paths.

Possible forms:

- include `xpr-init` in the next source/binary release structure;
- provide a small host-tools archive/package;
- provide an RPM for the tested CentOS/MPSS host path if that can be done
  cleanly and reproducibly;
- retain a plain standalone script path for transparency and recovery.

Any packaging work must preserve the existing separation between XPR-OS
project artifacts and separately obtained Intel MPSS components.

## Priority: Additional SSH-Key Compatibility

RSA is currently the hardware-validated compatibility path. Future work may
investigate additional key types, especially Ed25519, if the project Dropbear
build and the legacy host-side SSH stack can support them reliably.

Requirements before claiming support:

- confirm card-side Dropbear build capability;
- confirm host-side client behavior on the tested legacy environment;
- test bootstrap and final-root authentication;
- retain RSA as a compatibility option unless there is a strong reason not to.

Do not remove the currently validated RSA path merely because a newer key type
works on a development host.

## Priority: Repeated Boot / Idempotence Validation

Beyond the validated reboot and reinstall/recovery fixtures, additional repeated
card cycles could still be exercised without rerunning `--install`:

```text
boot XPR -> use -> reset -> boot XPR again -> use -> recover
```

Validate that:

- deployment artifacts remain intact;
- handoff can run more than once across separate card boots;
- no stale bootstrap/final-root state breaks the next boot;
- the original stock backup remains unchanged; and
- recovery still restores the exact original configuration.

This is additional robustness coverage, not a blocker for the currently
validated first-use lifecycle.

## Optional Convenience Boot Command (Design Discussion Only)

A future convenience command could potentially perform the normal MPSS
lifecycle for the user, for example:

```text
xpr-init --boot
```

This is **not currently recommended as an implementation priority**. The tested
host already returned from reboot with `mic0` online using the XPR kernel, and
adding another boot layer without understanding the exact MPSS startup path
could introduce redundant state handling or races.

The responsibility boundary remains:

- `xpr-init` = install/integrate/recover XPR host configuration;
- `micctrl` = control Xeon Phi hardware;
- XPR-OS = card-side operating environment.

If a helper is ever added, it should remain a thin convenience wrapper and must
not obscure or replace `micctrl` semantics.

## Implementation Rules For Future Codex Passes

When resuming this backlog with Codex:

- sync to the current repository HEAD first;
- do not modify frozen RC6 assets or retag RC6;
- preserve the original stock backup and rollback guarantees;
- keep changes narrow and separately testable;
- add host fixture coverage before or alongside live hardware testing;
- distinguish HOST-ONLY TESTED from LIVE 5110P TESTED;
- do not promote new behavior in beginner docs until the relevant live test
  passes;
- stop when evidence diverges instead of stacking speculative fixes;
- avoid unrelated toolchain/xpr-build work in the same pass.

## Ideas Not Yet Scheduled

Use this section as a lightweight parking lot for additional `xpr-init` ideas
before implementation details are decided.

- optional dedicated XPR SSH config entry for easier `ssh mic0` use;
- improved troubleshooting output for handoff failures;
- structured diagnostic bundle generation for bug reports;
- support for additional KNC cards only after separate hardware validation;
- future integration with a packaged XPR SDK/tooling environment without
  turning `xpr-init` into a general package manager or application launcher.
