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

## Current Limits

- The CentOS host lacks the `scp` client and its configured CentOS 7 package
  repositories are unavailable, so the live alias check could not exercise
  SCP. This is a host prerequisite limitation, not an `xpr-init` failure:
  `ssh mic0` and `ssh xpr-mic0` both passed.
- `xpr-build` has passed its controlled host fixture only. A real K1OM build
  still requires reconstructing an unpacked source-built toolkit on a Linux
  host; that work has not been substituted with a synthetic fixture.

## Validation Notes

- Python syntax and shell syntax checks pass for the updated host helpers.
- The full host fixture is a Linux/MPSS-host fixture. Git for Windows cannot
  model its ownership/mode contract: its `install -d -m 700` step fails with
  `Permission denied` before installer logic. Run it on the supported CentOS
  host before marking Phase 1 hardware-validated.
- `EXEC_PREFIX_ROOT_CAUSE=IDENTIFIED`: no staged `lib-dynload` directory.
- `PYTHON312_EXTENSION_BASELINE=RECORDED`: `_random` was neither static nor
  installed dynamically in the minimal RC7 profile.
- `XPR_BUILD_PROTOTYPE=IMPLEMENTED_PENDING_LEVEL0`: no target toolkit is
  currently unpacked in this Windows workspace; level-0 needs the Linux build
  host's source-built toolkit and a real external-style project.
- `RC8_HOST_FIXTURE=PASS`.
- `RC8_MIC0_XPR_LOGIN=PASS`.
- `RC8_XPR_MIC0_ALIAS=PASS`.
- `RC8_MIC0_SCP=HOST_PREREQUISITE_MISSING`.
- `RC8_MIC0_STOCK_RECOVERY=PASS`.
- `STOCK_TRUST_PRESERVED=PASS`.

## RESUME STATE

- LAST_COMPLETED_PHASE=4
- CURRENT_HEAD=1850bf39b2f98fb10ab68bb2774e3ea9ca094c28
- HARDWARE_STATE=stock MPSS recovered; mic0 online
- CURRENT_BLOCKER=source-built standalone toolkit is not reconstructed on a Linux host for a real xpr-build level-0 test
- NEXT_EXACT_ACTION=reconstruct the source-built toolkit from accounted inputs on a Linux host with sufficient disk, then run tests/xpr-build/run-level0.sh and transfer the resulting K1OM binary for 5110P validation
- IMPORTANT_PATHS=tools/host/xpr-init,tools/host/xpr-ssh-setup.py,tools/host/test-xpr-init-install.sh
- IMPORTANT_HASHES=RC7 binary 6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c
- DO_NOT_REPEAT=RC7 release/publication audit; do not alter frozen RC7 assets or tag
