# XPR-OS 0.1.0-rc5 Validation

RC5 was validated on an Intel Xeon Phi 5110P through the existing CentOS 7.4
era MPSS 3.4.10 host path. All runs used the same source-accounted generic
artifacts and a deployment-only copy carrying one operator RSA public key.

## Frozen Generic Inputs

| Artifact | SHA-256 |
| --- | --- |
| Kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| System.map | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` |
| Outer Base CPIO | `f2ab2ead93fa9a62605ef24984583fb808550cac730d5ac874342ec876283135` |
| Nested bootstrap root | `52be12ffa566909704b96d82bfc84997c1d0b86a7be470efca054f89e7d72e9a` |
| Generic final payload | `27df3a3886429a00680869fb4a26a72826b93ab3f0032af62d7ed5d389c1a99d` |

The deployment-only artifacts were `a5853a3d98db6be55b0eeaa0030161d5a5a13050d293c2c28df4f42f65fcd6cb`
(Base CPIO) and `982fdc9bfdf1f9ab931251632dfd936ff827d0fc5b9ebde51cfd341a25ef56eb`
(final payload). They were generated from the generic pair by the strict
provisioner with an operator public key and are not release artifacts.

## Three-Boot Gate

| Run | Result | Evidence |
| --- | --- | --- |
| 1 | PASS | `online=1`, `project_ssh=1`, `switched=1`, `smoke=1` |
| 2 | PASS | `online=1`, `project_ssh=1`, `switched=1`, `smoke=1` |
| 3 | PASS | `online=1`, `project_ssh=1`, `switched=1`, `smoke=1` |

Each run captured final-root markers for `XPR_SWITCH_ROOT_EXEC`,
`XPR_RC_INIT_ENTERED`, `XPR_RC_ROOT_SBIN_INIT_PID1`, `XPR_NETWORK_READY`, and
`XPR_SSH_READY`. Final-root smoke checks passed `XPR_HELLO_OK`,
`XPR_PTHREAD_OK`, and `XPR_DLOPEN_OK`; `/dev`, `/run`, and `/tmp` checks also
passed.

Every rollback restored `mic0` online, stock SSH, stock `k1om`/`init`, and the
stock MPSS configuration SHA-256
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.

This is technical validation, not publication approval. RC5 remains frozen for
an independent audit and owner release decision.
