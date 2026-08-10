# Public-Clean Stack Hardware Validation

Date: 2026-08-10  
Status: `TECHNICALLY_VALIDATED_NOT_PUBLISHABLE`

The source-accounted public-clean XPR-OS stack completed three consecutive
rollback-protected boots on the tested Intel Xeon Phi 5110P path:

- Host: Dell PowerEdge R730, CentOS 7.4.1708, MPSS 3.4.10
- Kernel: `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8`
- System.map: `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6`
- Outer Base CPIO: `bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779`
- Public final-root payload: `e5c25217a5b9a2c60f7caaefce3651dd086b6f0f0d51e88883aa3e9486c7fee7`
- Stock configuration baseline: `9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`

The payload contains source-built BusyBox, eglibc including
`libnss_files.so.2`, source-built `libgcc_s`, Dropbear, project helpers, and
static `newc` character-device entries. Its root and archive provenance audits
both reported zero errors.

## Three-Boot Gate

| Run | Online | Bootstrap SSH | Final root / PID 1 | Final-root SSH | Smoke | Rollback |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | pass | pass | pass | pass | pass | pass |
| 2 | pass | pass | pass | pass | pass | pass |
| 3 | pass | pass | pass | pass | pass | pass |

Every run captured `XPR_SWITCH_ROOT_EXEC`, `XPR_RC_INIT_ENTERED`,
`XPR_RC_ROOT_SBIN_INIT_PID1`, `XPR_DEV_NULL_READY`, `XPR_NETWORK_READY`,
`XPR_SSH_READY`, and `XPR_SMOKE_PASS`. The final root authenticated the
operator key, ran as PID 1, and passed dynamic hello, pthread, and `dlopen`
smokes. Each rollback restored stock `mic0` online state, stock SSH, stock PID
1, and the exact baseline configuration hash.

## Release Boundary

This is real-hardware technical evidence, not publication approval. A public
prebuilt RC remains blocked until the compatibility kernel and five required
card-side modules have complete corresponding-source/provenance bundles and
the final binary artifact completes human legal review. Do not distribute the
private hardware artifacts named above.
