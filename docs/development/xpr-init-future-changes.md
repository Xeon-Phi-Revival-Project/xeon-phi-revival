# xpr-init Future Changes

This document is a parking lot and implementation roadmap for **future** `xpr-init`
work. It records ideas that have been identified after the successful live
5110P validation so they can be implemented later without losing context or
reopening already-solved design questions.

Nothing in this document should be treated as implemented, supported, or
hardware-validated until the corresponding change is merged and tested.

Current validated baseline:

- Intel Xeon Phi 5110P
- CentOS 7.4 host
- Intel MPSS 3.4.10
- XPR-OS 0.1.0-rc6 runtime
- `xpr-init` automatic bootstrap-to-final-root handoff validated on hardware
- final XPR PID 1, micveth, authenticated SSH, hello/pthread/dlopen smokes: PASS
- `xpr-init --recover` restored stock MPSS and the known baseline configuration
  hash

## Completed: Dedicated RSA Key Generation Fallback

### Idea

If `xpr-init --install` cannot find a compatible RSA public key with a matching
private key, it creates an XPR-specific RSA key pair instead of stopping.

Suggested dedicated key names:

```text
~/.ssh/xpr_os_rsa
~/.ssh/xpr_os_rsa.pub
```

Suggested generation command:

```bash
ssh-keygen -t rsa -b 3072 \
  -f ~/.ssh/xpr_os_rsa \
  -C "XPR-OS Xeon Phi access"
```

### Desired selection behavior

1. Explicit `--authorized-key` / `--identity` wins.
2. If exactly one compatible RSA key pair is discoverable, use it.
3. If multiple compatible RSA candidates exist, list them and stop rather than
   guessing.
4. If no compatible RSA key exists, generate a dedicated XPR key pair.
5. Never overwrite an existing private key.
6. Never copy the private key into XPR-OS.
7. Provision only the public key into deployment-specific bootstrap/final-root
   images.

### Why

This removes one of the remaining first-time-user setup steps while keeping the
legacy `ssh-rsa` compatibility requirement isolated to XPR rather than forcing
users to make RSA their general-purpose SSH identity.

### Evidence

- focused host fixtures cover explicit, zero, one, multiple, reusable, and
  incomplete-key states;
- the live generated key belonged to the invoking test user with `700` `.ssh`,
  `600` private key, and `644` public key;
- automatic handoff, final PID 1, micveth, generated-key SSH, hello, pthread,
  dlopen, and stock recovery passed.

## Priority 2: Host Reboot / Power-Cycle Persistence Validation

### Current design

`xpr-init --install` stores persistent host-side state, including deployment
artifacts, the saved stock MPSS configuration, active XPR MPSS configuration,
and the enabled handoff systemd service. The running card-side XPR-OS instance
is volatile and must be booted again after power loss.

The intended post-reboot behavior is therefore:

```text
host powers on
    -> xpr-init installation/state is still present
    -> handoff service is enabled
    -> operator boots mic0 with normal micctrl reset/wait/boot
    -> handoff service detects bootstrap
    -> final XPR root is entered automatically
```

### Future validation

Perform one explicit cold-host-reboot or full power-cycle test:

1. Start from a known stock baseline.
2. Run `xpr-init --install`.
3. Verify installed state and saved stock hash.
4. Shut down or power-cycle the host.
5. Boot the host normally.
6. Verify `xpr-init --status` still reports the installation.
7. Verify the handoff unit is still enabled/active as designed.
8. Run normal `micctrl --reset mic0`, `--wait`, `--boot`.
9. Confirm automatic handoff reaches final XPR PID 1, networking, and SSH.
10. Run hello/pthread/dlopen smokes.
11. Run `xpr-init --recover`.
12. Verify exact stock MPSS configuration hash and stock SSH/systemd state.

### Documentation outcome if validated

Document clearly that `xpr-init --install` is a persistent host configuration
step and normally does **not** need to be rerun after every host reboot.

Completed on 2026-08-13. A normal reboot preserved XPR host state, the saved
stock backup, deployed artifacts, the active XPR MPSS configuration, and the
enabled handoff unit. No reinstall was required before the documented
reset/wait/boot sequence completed automatic handoff, final SSH, and the three
smokes. The card-side XPR instance remains RAM-resident and must boot again
after host/card power loss; this does not write XPR to card flash.

## Priority 3: First-Run UX and Error Messages

Improve errors so a beginner is told both what went wrong and the exact next
command to use.

Examples:

```text
No XPR-OS release found.
Place xpr-os-0.1.0-rc6.tar.gz in ~/Downloads or run:
  sudo xpr-init --install --release /path/to/xpr-os-0.1.0-rc6.tar.gz
```

```text
Multiple XPR-OS releases found:
  ...
Select one explicitly with --release.
```

```text
No compatible RSA key found.
Generate an XPR-specific key or provide --authorized-key and --identity.
```

Potential additions:

- `--help` examples for the common beginner flow;
- clearer distinction between `--authorized-key` (public key) and `--identity`
  (private key used by host-side SSH);
- more explicit confirmation of selected release/key before installation;
- human-readable success summary after install.

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

## Priority 5: Packaging and Distribution

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

## Priority 6: Additional SSH-Key Compatibility

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

## Priority 7: Repeated Boot / Idempotence Validation

Beyond one reboot persistence test, exercise repeated normal cycles without
rerunning `--install`:

```text
boot XPR -> use -> reset -> boot XPR again -> use -> recover
```

Validate that:

- deployment artifacts remain intact;
- handoff can run more than once across separate card boots;
- no stale bootstrap/final-root state breaks the next boot;
- the original stock backup remains unchanged;
- recovery still restores the exact original configuration.

## Priority 8: Optional Convenience Boot Command (Design Discussion Only)

A future convenience command could potentially perform the normal MPSS
lifecycle for the user, for example:

```text
xpr-init --boot
```

which would internally call reset -> wait -> boot and then wait for the
validated automatic handoff.

This is **not currently recommended as an implementation priority** because the
project deliberately keeps responsibilities clear:

- `xpr-init` = install/integrate/recover XPR host configuration;
- `micctrl` = control Xeon Phi hardware;
- XPR-OS = card-side operating environment.

If such a helper is ever added, it should remain a thin convenience wrapper and
must not obscure or replace `micctrl` semantics.

### Host-start boot investigation

The MPSS init script starts `mpssd` and uses `micctrl --wait`. During the
2026-08-13 reboot validation, `mic0` was nevertheless already online with the
installed XPR kernel when the host returned. The project has not yet isolated
the exact MPSS path responsible for that observed startup boot. No XPR-owned
automatic boot service and no `xpr-init --boot` command were added: a wrapper
would need deterministic state/race handling before it could replace the
documented `micctrl --reset`, `--wait`, and `--boot` lifecycle.

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

- clearer post-install "what happens after a host reboot" messaging;
- optional dedicated XPR SSH config entry for easier `ssh mic0` use;
- improved troubleshooting output for handoff failures;
- structured diagnostic bundle generation for bug reports;
- support for additional KNC cards only after separate hardware validation;
- future integration with a packaged XPR SDK/tooling environment without
  turning `xpr-init` into a general package manager or application launcher.
