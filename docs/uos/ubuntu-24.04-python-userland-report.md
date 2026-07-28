# Ubuntu 24.04 uOS Python Userland Report

Public-safe Python userland report. Private rootfs trees, CPython build trees,
compiled binaries, and raw logs remain local-only.

## Result

The Ubuntu-derived Python userland has its first working K1OM demo.

CPython 3.5.10 runs inside the demo rootfs on `mic0` with:

- standard-library `Lib/`
- core imports: `os`, `sys`, `threading`
- extension import: `zlib`
- extension import: `math`

The current interpreter is not Ubuntu 24.04's Python 3.12. It is an
era-compatible Python 3 target used to prove the K1OM userland model before
attempting a newer interpreter.

## Passing Smoke Tests

Core Python:

```text
python demo ok
platform=linux
cwd=/
thread=42
```

Math and zlib:

```text
math=12.0
zlib=knc
```

Extended import status:

```text
math=ok
zlib=ok
sqlite3=fail:ImportError:No module named '_sqlite3'
_ctypes=fail:ImportError:No module named '_ctypes'
curses=fail:ImportError:No module named '_curses'
```

## Extension Module Notes

`zlib`:

- Ubuntu 24.04 Noble zlib source was rebuilt with `-fPIC`.
- `Modules/zlibmodule.c` was linked into a K1OM CPython extension module.
- Import and compress/decompress runtime test passed.

`math`:

- `Modules/mathmodule.c` alone linked but failed at runtime with missing
  `_Py_log1p`.
- Rebuilding the extension with `Modules/_math.c` fixed the missing symbol.
- Import and `sqrt(144)` runtime test passed.

## Next Python Userland Work

The narrow next targets are:

- build `_sqlite3` after resolving the SQLite `tclsh` source-generation issue
- build `_ctypes` after resolving the libffi Autoconf 2.71+ issue
- build `_curses` only after the `setupterm()` runtime issue is understood
- create a repeatable Python rootfs packaging script
- decide whether CPython 3.6+ is feasible with MPSS GCC 4.7, or whether CPython
  3.5 remains the practical KNC target
