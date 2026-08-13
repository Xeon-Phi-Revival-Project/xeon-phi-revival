# xpr-init Future Changes

This document is the parking lot and implementation roadmap for **future**
`xpr-init` work. The core install, handoff, recovery, dedicated-key, status,
fresh-user-state, and reboot-persistence paths are now validated on the project
baseline, so this file focuses on the improvements that remain rather than
reopening already-solved work.

Nothing under **Future Priorities** should be treated as implemented, supported,
or hardware-validated until the corresponding change is merged and tested.

## Validated Baseline

Current strongest evidence:

- Intel Xeon Phi 5110P
- CentOS 7.4 host
- Intel MPSS 3.4.10
- XPR-OS 0.1.0-rc6 runtime
- `xpr-init` no-argument install and archive auto-discovery: PASS
- dedicated RSA-key generation: PASS
- automatic bootstrap-to-final-root handoff: PASS
- final XPR PID 1, micveth, authenticated SSH: PASS
- hello/pthread/dlopen smokes: PASS
- fresh-user-state flow on the existing known-good host: PASS
- normal host reboot persistence: PASS
- `xpr-init --recover` repeatedly restored stock MPSS and the exact known
  configuration hash

The validated stock `mic0.conf` SHA256 is:

```text
9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

On the tested reboot, `mic0` was observed already online with the installed XPR
kernel after the host returned. No XPR-owned automatic boot wrapper or
`xpr-init --boot` command was present. The exact MPSS startup path responsible
for that observed card boot has not yet been isolated, so it must not be
generalized to every MPSS host.

## Completed Work

The following formerly parked items are implemented and validated sufficiently
to move out of the active backlog:

### Dedicated RSA key generation

If no compatible RSA key pair is available, `xpr-init` creates:

```text
~/.ssh/xpr_os_rsa
~/.ssh/xpr_os_rsa.pub
```

The invoking user owns the key pair, the private key remains host-only, and only
the public key is provisioned into deployment-specific XPR images. Explicit
`--authorized-key` / `--identity` selection still wins, one unambiguous existing
compatible RSA key may be reused, and ambiguous or incomplete key states fail
safely.

### Status improvements

`xpr-init --status` reports installed release/state, active configuration mode,
saved/current configuration hashes, handoff-unit state, public-key information,
recovery availability, and `micctrl` state without printing private-key
material or changing card state.

### Fresh-user-state validation

A first-use-style run on the existing known-good CentOS 7.4 + MPSS 3.4.10 host
validated archive auto-discovery, automatic dedicated-key generation,
no-argument install, handoff, SSH, runtime smokes, and exact stock recovery. It
was not a literal fresh CentOS/MPSS installation. The only concrete beginner
documentation gap found was missing Git, which is now documented.

### Host reboot persistence

Host-side XPR state, `/opt/xpr-os` artifacts, stock backup, active XPR MPSS
configuration, and the enabled handoff unit survived a normal host reboot. No
reinstall was required. The post-reboot XPR path and subsequent exact stock
recovery both passed.

---

# Future Priorities

## Priority 1: SSH Config Integration

### Goal

Make the normal user and developer experience:

```bash
ssh mic0
scp hello mic0:
```

instead of requiring the generated-key path on every command:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/xpr_os_rsa mic0
```

This is especially useful now that XPR has an installation tool and is gaining
a K1OM development toolkit: repeated `ssh` and `scp` commands should not require
users to remember XPR-specific identity flags.

### Proposed design

When `xpr-init` installs or generates a dedicated XPR identity, optionally add a
small XPR-managed SSH configuration entry for the invoking user.

Conceptually:

```sshconfig
Host mic0
    IdentityFile ~/.ssh/xpr_os_rsa
    IdentitiesOnly yes
```

If additional legacy RSA compatibility options are actually required by a
supported client, add only the minimum options proven necessary by testing.
Do not add broad insecure SSH settings merely for convenience.

### Safety requirements

- modify the invoking user's SSH configuration, never `/root/.ssh/config`
  merely because `xpr-init` runs under `sudo`;
- preserve existing user SSH configuration exactly outside an XPR-owned block
  or include file;
- never overwrite an existing unrelated `Host mic0` entry silently;
- never expose or copy the private key;
- preserve sane `~/.ssh` / config permissions and ownership;
- repeated `xpr-init --install` must be idempotent;
- recovery must have explicitly defined semantics before implementation:
  either preserve the harmless connection profile or remove only the exact
  XPR-managed entry, never unrelated user configuration;
- an explicit user-provided `--identity` must remain respected;
- if an existing compatible RSA key was reused instead of `xpr_os_rsa`, the
  generated SSH entry must point to the actual matching private key;
- if configuration is ambiguous, stop with a useful explanation rather than
  editing around it.

### Preferred implementation shape

Prefer one of these, based on what the tested OpenSSH version supports cleanly:

1. a clearly delimited XPR-managed block in `~/.ssh/config`; or
2. a dedicated XPR include such as `~/.ssh/config.d/xpr-os.conf` when include
   behavior is available and validated.

Do not assume newer OpenSSH `Include` behavior exists on the CentOS 7 baseline
without checking it first.

A managed block should contain a stable marker so future installs/recovery can
identify exactly what belongs to XPR.

### Validation

Host fixtures should cover at least:

- no existing SSH config;
- existing unrelated SSH config;
- pre-existing `Host mic0` conflict;
- generated XPR RSA identity;
- reused existing compatible identity;
- explicit `--identity`;
- repeated install/idempotence;
- recovery behavior;
- invoking-user ownership under `sudo`.

Live 5110P validation should prove, using the installed/generated configuration:

```bash
ssh mic0
scp <small-file> mic0:
```

without supplying `-i` or `IdentitiesOnly` manually.

Do not promote `ssh mic0` as the default README command until the live test
passes.

## Priority 2: First-Run UX and Success Summary

Most of the first-run path is now hardware-validated. Continue improving it only
when concrete friction appears.

Reasonable small improvements include:

- useful `--help` examples for the beginner flow;
- clearer distinction between `--authorized-key` and `--identity`;
- concise confirmation of the selected release and identity before install;
- a short post-install success summary explaining the next action;
- after SSH-config integration is validated, tell the user the exact simple
  command to connect.

Avoid turning `xpr-init` into an interactive wizard unless real user experience
shows that is needed.

## Priority 3: Packaging And Distribution

`xpr-init` was developed after the frozen RC6 archives, so current users obtain
RC6 separately and install the helper from the repository.

A future XPR release should consider making `xpr-init` a first-class host-tools
component so a new user does not need two separate acquisition paths.

Possible forms:

- include `xpr-init` in the next release structure;
- provide a small host-tools archive;
- provide an RPM for the tested CentOS/MPSS path if it can be produced cleanly
  and reproducibly;
- retain a standalone script path for transparency and recovery.

Any packaging must preserve the separation between XPR project artifacts and
separately obtained Intel MPSS components.

## Priority 4: Repeated Boot / Idempotence Coverage

Additional normal card cycles can strengthen robustness evidence:

```text
boot XPR -> use -> reset -> boot XPR again -> use -> recover
```

Validate that:

- deployment artifacts remain intact;
- handoff succeeds across multiple card boots;
- no stale bootstrap/final-root state breaks subsequent boots;
- the original stock backup remains unchanged; and
- recovery still restores the exact original configuration.

This is useful robustness coverage, not a blocker for the validated first-use
lifecycle.

## Priority 5: Better Failure Diagnostics

Future troubleshooting improvements may include:

- clearer handoff-stage failure reporting;
- a compact diagnostic bundle for bug reports;
- relevant `xpr-init --status` state, service state, hashes, and short logs;
- explicit separation of host configuration failure, MPSS/card-state failure,
  bootstrap failure, transfer failure, switch-root transition, and final-root
  failure.

Diagnostic tooling must not collect private SSH keys, passwords, or unrelated
host data.

## Priority 6: Additional SSH-Key Compatibility

RSA is the current hardware-validated compatibility path. Additional key types,
especially Ed25519, may be investigated if the project Dropbear build and the
legacy host-side SSH stack support them reliably.

Before claiming another key type:

- confirm card-side Dropbear support;
- confirm host-side client support on the tested baseline;
- test bootstrap and final-root authentication;
- test any SSH-config integration with the new key type; and
- retain RSA as a compatibility path unless evidence justifies otherwise.

Do not remove a validated compatibility path merely because a newer key type is
preferred on modern systems.

## Priority 7: Understand Host-Start `mic0` Boot Behavior

The validated reboot observed `mic0` online with the XPR kernel after host
startup even though XPR installed no separate auto-boot wrapper.

A future focused investigation may identify the exact MPSS path responsible:

- service/init ordering;
- `mpssd` behavior;
- MPSS scripts/configuration;
- journal evidence;
- card state before and after service startup.

The purpose is to understand and document existing behavior, not to add another
boot layer unnecessarily.

Until this is understood, do not create a competing XPR auto-boot service.

## Optional: `xpr-init --boot`

A convenience command could eventually wrap the normal MPSS lifecycle:

```text
xpr-init --boot
```

This remains a design discussion only. It should be implemented only if it
reduces real user errors after host-start behavior is understood.

The responsibility boundary remains:

- `xpr-init` = install/integrate/recover XPR host configuration;
- `micctrl` = Xeon Phi hardware control;
- XPR-OS = card-side operating environment.

Any future `--boot` must remain a thin orchestration layer around `micctrl`, not
replace MPSS hardware-control semantics.

## Future XPR Toolkit Integration

As the XPR K1OM Toolkit matures, `xpr-init` may expose only the small amount of
connection/runtime information needed for a smooth developer workflow.

Examples might include:

- making the validated `ssh mic0` / `scp ... mic0:` profile available;
- reporting the active card hostname/address in machine-readable status output;
- allowing toolkit scripts to discover the installed identity safely without
  parsing private data.

Do **not** turn `xpr-init` into a compiler driver, SDK manager, package manager,
or application launcher. Those responsibilities belong to the XPR K1OM Toolkit
and future `xpr-build` work.

# Implementation Rules For Future Codex Passes

When resuming this backlog with Codex:

- sync to current repository HEAD first;
- do not modify frozen RC6 assets or retag RC6;
- preserve the original stock backup and rollback guarantees;
- keep changes narrow and separately testable;
- add host fixture coverage before or alongside live hardware testing;
- distinguish HOST-ONLY TESTED from LIVE 5110P TESTED;
- do not promote new behavior in beginner docs until live validation passes;
- preserve invoking-user ownership/paths when running under `sudo`;
- never expose private-key material;
- stop when evidence diverges instead of stacking speculative fixes;
- keep toolchain/xpr-build implementation separate from `xpr-init` changes.

# Ideas Not Yet Scheduled

Use this section only for ideas that are not mature enough to be priorities.

- support for additional KNC cards after separate hardware validation;
- optional richer machine-readable status output for external tooling;
- future integration with a packaged XPR SDK/toolkit without making `xpr-init`
  a general software-management command.
