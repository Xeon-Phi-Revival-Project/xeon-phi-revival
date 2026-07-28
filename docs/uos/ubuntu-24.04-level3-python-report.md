# Ubuntu 24.04 uOS Level 3 Python Report

Public-safe Python runtime report. Downloaded source archives, build trees,
compiled binaries, temporary Python homes, and raw logs remain local-only.

## Result

Level 3 has begun successfully: CPython ran on `mic0`.

The tested interpreter was CPython 3.5.10, selected as an era-compatible Python
3 target for the MPSS 3.4.10 K1OM GCC/glibc environment. This is not Ubuntu
24.04's Python 3.12, and it is not yet a full Python distribution for the custom
rootfs. It is the first Python proof-of-life for the Ubuntu-derived userland
track.

## Source

- Source: CPython
- Version: `3.5.10`
- URL: `https://www.python.org/ftp/python/3.5.10/Python-3.5.10.tgz`
- SHA256: `3496a0daf51913718a6f10e3eda51fa43634cb6151cb096f312d48bdbeff7d3a`

## Build Path

The first cross-configure attempt failed because CPython 3.5 requires a
host-side Python 3.5 interpreter for the cross build.

The successful path was:

1. Build a private host CPython 3.5.10 on the CentOS MPSS host.
2. Use that host interpreter as `PYTHON_FOR_BUILD`.
3. Cross-configure CPython 3.5.10 for `k1om-mpss-linux`.
4. Build the K1OM `python` executable.
5. Copy the K1OM binary and a temporary `PYTHONHOME` containing the CPython
   `Lib/` tree to `mic0`.
6. Run a minimal script and clean the temporary files from `mic0`.

The K1OM interpreter was verified as:

```text
ELF 64-bit LSB executable
Machine: Intel K1OM
```

## Runtime Result

The first direct binary run failed because the interpreter could not find the
standard-library `encodings` package:

```text
Fatal Python error: Py_Initialize: Unable to get the locale encoding
ImportError: No module named 'encodings'
```

After adding a temporary `PYTHONHOME`, the smoke script ran:

```text
42
```

The smoke script is:

```text
tests/native/python-smoke.py
```

## Interpretation

This is the first real Python proof-of-life on the Xeon Phi 5110P in this
project. The interpreter can start, initialize enough of the standard library to
execute a script, and print output on `mic0`.

Level 3 is not complete yet. The next requirements are:

- package the interpreter, `Lib/`, and needed extension modules into the
  local-only tiny rootfs layout
- record which builtin and extension modules were built
- test imports such as `math`, `zlib`, `os`, `sys`, and `threading`
- decide whether to keep CPython 3.5 as the practical path or attempt a newer
  Python after the dependency/sysroot story improves
