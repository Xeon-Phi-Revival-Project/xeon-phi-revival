# RC8 Engineering Progress

## Baseline

- `v0.1.0-rc7` is frozen and published at binary SHA-256
  `6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c`.
- Development starts from `5ae45ec1670bc21e99a5da9f536119acbf864ff3`.
- The standalone toolkit remains `HOLD_HUMAN_REVIEW` for its separate KNC
  binutils source-distribution issue and is not an RC8 release component.

## Completed

- Phase 0 baseline and RC8 roadmap started.

## Current Work

- Phase 1: extend the bounded XPR SSH configuration to make `ssh mic0` route
  to the active XPR deployment, while preserving `ssh xpr-mic0` and removing
  only the managed override during recovery.
- Phase 2: add explicit runtime-state reporting and a bounded `--wait-ready`
  path that reports final-root readiness before directing users to SSH.
- Phase 3 Python diagnosis: RC7 omitted the `lib-dynload` exec-prefix
  landmark and did not build `_random`; the RC8 core profile now records both
  corrections for the next clean source build.
- Phase 4: initial `xpr-build` prototype added. It consumes an unpacked
  source-accounted toolkit, isolates target tools/pkg-config, and supports
  configure, make, DESTDIR stage, and target ELF inspection.
- Phase 5: a small external-style configure/Make/install project and runner
  are tracked for the first real toolkit-host validation.
- A host-only `xpr-build` contract fixture now proves controlled environment,
  configure, make, inspection, and DESTDIR staging without substituting it for
  a K1OM compiler or card test.
- The CentOS 7.4 / MPSS 3.4.10 host fixture passed with the current RC8
  installer and helper pair. It verifies managed SSH-config installation,
  stock-alias preservation, and exact managed-block removal on recovery.
- A live 5110P RC7 deployment using the RC8 host helper reached
  `FINAL_ROOT_READY`; both `ssh mic0` and `ssh xpr-mic0` authenticated to the
  final XPR root without manual SSH options. Recovery restored the exact stock
  `mic0.conf` baseline and left `mic0` online.
- The internal toolchain was rebuilt from the accounted KNC binutils, GCC,
  eglibc, and libgcc sources. The init/fini regression fixture passed as K1OM.
  A packaging defect in the GCC fixed-header composition was corrected so the
  staged target `limits.h` reports `MB_LEN_MAX=16` while retaining GCC's fixed
  definitions.
- The real level-zero external project built with the reconstructed toolkit.
  Its K1OM executable and `DESTDIR` staged copy both hash to
  `aac4e3b8b72b7009901c4e41ebf8fbf586d4700e1422c8b915f1cb9f98d97e13`.
- `xpr-init --install` was exercised from its installed path. It now avoids
  copying `xpr-ssh-setup.py` onto itself when the helper is already installed.

## Current Limits

- The CentOS host lacks the `scp` client and its configured CentOS 7 package
  repositories are unavailable, so the live alias check could not exercise
  SCP. This is a host prerequisite limitation, not an `xpr-init` failure:
  `ssh mic0` and `ssh xpr-mic0` both passed.
- `xpr-build` has passed its controlled host fixture only. A real K1OM build
  and a real level-zero K1OM build have passed; card execution remains blocked
  by the current bootstrap SSH host-key mismatch below.
- The September 15 bounded hardware cycle reached `BOOTSTRAP_READY`, but the
  automatic handoff rejected the bootstrap server under strict host-key
  checking. The observed ECDSA fingerprint did not match the deployment key
  recorded in `/var/lib/xpr-init/ssh/mic0/known_hosts`. This occurs before
  payload transfer and before `xpr-stage-root`; it is an `xpr-init` deployment
  key-provisioning/bootstrapping defect, not a level-zero binary result.

## Validation Notes

- Python syntax and shell syntax checks pass for the updated host helpers.
- The full host fixture is a Linux/MPSS-host fixture. Git for Windows cannot
  model its ownership/mode contract: its `install -d -m 700` step fails with
  `Permission denied` before installer logic. Run it on the supported CentOS
  host before marking Phase 1 hardware-validated.
- `EXEC_PREFIX_ROOT_CAUSE=IDENTIFIED`: no staged `lib-dynload` directory.
- `PYTHON312_EXTENSION_BASELINE=RECORDED`: `_random` was neither static nor
  installed dynamically in the minimal RC7 profile.
- `XPR_BUILD_LEVEL0_CANDIDATE=HOST_PASS`: the current source snapshot built an
  external-style level-0 project on the Linux build host with the internal
  source-built K1OM toolkit. Its SHA-256 is
  `aac4e3b8b72b7009901c4e41ebf8fbf586d4700e1422c8b915f1cb9f98d97e13`;
  `xpr-validate` reported Intel K1OM and the XPR dynamic loader.
- `XPR_BUILD_LEVEL0_5110P=PASS`: that exact binary was streamed over the
  validated SSH path to the immutable RC8 candidate, matched its host SHA-256
  on-card, and printed `xpr-build level-0 K1OM program`. `scp` is absent from
  the intentionally minimal root, so the documented-compatible SSH stream
  transfer was used. Recovery then restored the exact stock MPSS hash.
- `XPR_BUILD_ZLIB_LEVEL1=PASS`: pinned Ubuntu Noble zlib 1.3 source was built
  through the `xpr-build` plain-configure mode as `libz.a`; the K1OM smoke
  executable SHA-256 `29b349b7df5dcee805414824fbcbc01a2045a0fd90489aeca8a94f956f4c1f1a`
  matched on the 5110P and printed `zlib version=1.3 result=knc zlib smoke`.
  Recovery restored the exact stock MPSS hash.
- `RC8_HOST_FIXTURE=PASS`.
- `RC8_MIC0_XPR_LOGIN=PASS`.
- `RC8_XPR_MIC0_ALIAS=PASS`.
- `RC8_MIC0_SCP=HOST_PREREQUISITE_MISSING`.
- `RC8_MIC0_STOCK_RECOVERY=PASS`.
- `TOOLKIT_WRAPPER_FIX=PASS`.
- `EGLIBC_INITFINI_DETECTION=PASS`.
- `XPR_BUILD_LEVEL0_CONFIGURE=PASS`.
- `XPR_BUILD_LEVEL0_BUILD=PASS`.
- `XPR_BUILD_LEVEL0_K1OM=PASS`.
- `RC8_XPR_BOOTSTRAP_HOST_KEY=PASS` on the corrected `fcb085f` candidate.
- `STOCK_TRUST_PRESERVED=PASS`.

## RESUME STATE

- LAST_COMPLETED_PHASE=RC8 hardware candidate validation
- CURRENT_HEAD=fcb085f plus validation evidence pending commit
- HARDWARE_STATE=stock MPSS recovered; mic0 online
- CURRENT_BLOCKER=release-sidecar review remains before any publication decision
- NEXT_EXACT_ACTION=perform a release-engineering review of the immutable fcb085f candidate; do not rebuild or retest it without a concrete defect
- IMPORTANT_PATHS=tools/host/xpr-init,tools/host/xpr-ssh-setup.py,tools/host/test-xpr-init-install.sh
- IMPORTANT_HASHES=RC7 binary 6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c
- DO_NOT_REPEAT=RC7 release/publication audit; do not alter frozen RC7 assets or tag
