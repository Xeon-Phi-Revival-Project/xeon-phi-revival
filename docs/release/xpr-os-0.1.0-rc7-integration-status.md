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

The first blocking rebuild is eglibc 2.19 configure: its K1OM target linker
probe fails with `Need linker with .init_array/.fini_array support.` The
source-built compiler and binutils are identified as GCC 5.1.1 and GNU ld
2.22.52.20120302. BusyBox reaches its final link but cannot find `-lgcc_s`, as
expected before a fresh eglibc/libgcc build exists. Therefore no current
source-built eglibc runtime, libgcc, BusyBox, Dropbear, or helper input set is
available for `build-public-root.sh`.

Reusing a historical root tree or CPIO as the RC7 payload input would violate
the public-clean root policy. Resolve the source-built KNC linker
`.init_array/.fini_array` capability discrepancy, rebuild eglibc and libgcc,
then rebuild BusyBox, Dropbear, and helpers before invoking
`build-public-root.sh --python-root` on the extracted validated CPython package.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

The standalone toolkit binary remains excluded from a public RC7 artifact
while its separate KNC binutils source-distribution review is held.
