# XPR-OS 0.1.0-rc8 Distribution Review

This is an engineering provenance checkpoint for an unpublished candidate. It
is not legal advice or publication authorization.

| Component | Candidate decision | Evidence boundary |
| --- | --- | --- |
| K1OM kernel and five MIC modules | Include | Previously reproduced, hash-pinned source outputs |
| BusyBox and Dropbear | Include | Fresh source-built K1OM inputs |
| eglibc and libgcc | Include | Fresh source-built K1OM runtime inputs |
| XPR bootstrap, final-root, and host tooling | Include | Current tracked project files |
| CPython 3.12.13 core | Include | Pinned source and source-accounted rebuilt package |
| Python 3.5 | Exclude | Static payload audit |
| Intel MPSS SDK binaries | Exclude | Static payload audit |
| Private keys, passwords, and fixed authorization keys | Exclude | Generic-payload and secret audit |
| Standalone XPR K1OM Toolkit binary | Exclude | Separate qualified-review hold |

Candidate `fcb085f` provides hardware evidence in
[`xpr-os-0.1.0-rc8-candidate-fcb085f-validation.md`](xpr-os-0.1.0-rc8-candidate-fcb085f-validation.md).
Its binary and corresponding-source hashes are recorded there. Publication
still requires review of the exact candidate sidecars; this checkpoint does
not itself authorize publication.
