# XPR-OS 0.1.0-rc7 Integration Status

## CPython layout reconciliation

`tools/release/build-public-clean-root.py` now consumes the validated CPython
3.12.13 core package layout directly:

- `/usr/bin/python3.12`
- `/usr/bin/python3` -> `python3.12`
- `/usr/bin/python` -> `python3.12`
- `/usr/lib/python3.12`

The historical `/opt/xeon-phi-revival/lib/python3.12` integration path is not
used by the public-clean root builder.  The release ledger maps this component
to the pinned CPython source, tracked build/package scripts, and the
corresponding-source component archive.

## Candidate status

`XPR_OS_RC7_CANDIDATE=BLOCKED_PUBLIC_ROOT_REBUILD`

No RC7 archive was created or hardware-tested in this checkpoint. The active
CentOS host retains the validated CPython package and RC6 archive but not a
current public-root input set. A bounded reconstruction attempt used the
pinned BusyBox, Dropbear, eglibc, GCC, binutils, and Linux-source inputs with
the source-built GCC 5.1.1/KNC-binutils toolkit, not an MPSS SDK binary.

The original blocker was eglibc 2.19 configure reporting `Need linker with
.init_array/.fini_array support.` The source-built compiler and binutils are
GCC 5.1.1 and GNU ld 2.22.52.20120302.

The root cause is a wrapper misdetection, not a binutils deficiency. The
original `xpr-gcc` appended `-lgcc_s` unconditionally, including when eglibc
uses `-static -nostartfiles -nostdlib`. The fresh bootstrap has no libgcc yet,
so the link failed before eglibc could inspect its `INIT_ARRAY` section.

`tools/release/fixtures/k1om-initfini-probe.c`, linked with the source-built
GCC/binutils without default libraries, produces a genuine Intel K1OM ELF with
both `INIT_ARRAY` and `FINI_ARRAY` sections. The wrapper now honors explicit
`-nostdlib` and `-nodefaultlibs`. Re-running the clean eglibc configure with
that behavior reports `.preinit_array/.init_array/.fini_array support... yes`
and continues through later target checks.

`EGLIBC_CONFIGURE_INITFINI=PASS`

No full eglibc build was started in this checkpoint. A fresh eglibc runtime,
libgcc, BusyBox, Dropbear, and helper input set is still required before
`build-public-root.sh` can construct RC7.

Reusing a historical root tree or CPIO as the RC7 payload input would violate
the public-clean root policy. Rebuild eglibc and libgcc with the corrected
wrapper behavior, then rebuild BusyBox, Dropbear, and helpers before invoking
`build-public-root.sh --python-root` on the extracted validated CPython package.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

The standalone toolkit binary remains excluded from a public RC7 artifact
while its separate KNC binutils source-distribution review is held.
