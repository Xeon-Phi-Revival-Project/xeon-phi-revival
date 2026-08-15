# CPython 3.12.13 K1OM Core Component Ledger

This ledger covers only the RC7-oriented CPython core component. Optional
historical dependency lanes are not part of this package.

| Component | Source identity | License | Binary decision | Evidence |
| --- | --- | --- | --- | --- |
| CPython | `Python-3.12.13.tar.xz`, SHA-256 `c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684`, Python.org | PSF-2.0 | Build and ship K1OM core runtime | Source archive, `LICENSE`, build and package helpers in corresponding-source archive |
| XPR K1OM patch | `patches/python-3.12-k1om/0001-k1om-atomic-fence.patch` | CPython's PSF-2.0 context | Apply during target build | K1OM fence and `PY_SSIZE_T_MAX` compatibility adjustments |
| XPR build/package helpers | `tools/python/*.sh` | Project repository license | Ship as source | Explicit GCC/binutils/sysroot inputs and deterministic packaging |
| XPR EGLIBC/libgcc runtime | Existing XPR-OS runtime, not copied into this component | Existing XPR runtime accounting | Runtime prerequisite, not bundled | Python ELF needs `libpthread.so.0`, `libgcc_s.so.1`, and `libc.so.6` |

The core package contains no MPSS SDK binary payload and no Python 3.5 payload.
The K1OM toolkit used to build it remains separately source-accounted; its
publication-review status is not a claim about this CPython component.
