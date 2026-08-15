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

`XPR_OS_RC7_CANDIDATE=BLOCKED_PREBUILD_INPUTS_UNAVAILABLE`

No RC7 archive was created or hardware-tested in this checkpoint.  The active
CentOS host retains the validated CPython package and RC6 archive, but no
current source-built public-root input set is available outside historical
archive trees: BusyBox, Dropbear, eglibc runtime, libgcc, and XPR smoke-helper
build outputs are required by `tools/release/build-public-root.sh`.

Reusing a historical root tree or CPIO as the RC7 payload input would violate
the public-clean root policy.  Rebuild those five declared inputs with the
tracked release builders, then invoke `build-public-root.sh --python-root` on
the extracted validated CPython package before staging the new RC7 candidate.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

The standalone toolkit binary remains excluded from a public RC7 artifact
while its separate KNC binutils source-distribution review is held.
