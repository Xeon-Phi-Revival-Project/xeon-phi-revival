# K1OM Compatibility Demo Report

Public-safe demo report. Private rootfs contents, archives, binaries, and raw
logs remain local-only.

## Result

The project now has a fuller K1OM compatibility demo running under the stock
MPSS kernel through a reversible chroot test on `mic0`.

The demo rootfs includes:

- stock MPSS K1OM loader and runtime libraries
- `hello-knc`
- Ubuntu-source `zlib` smoke binary
- Ubuntu-source `ncurses` smoke binary
- CPython 3.5.10 K1OM interpreter
- CPython `Lib/` tree
- K1OM CPython extension modules for `math` and `zlib`

The rootfs was copied temporarily to `/tmp` on `mic0`, tested with `chroot`, and
removed after the run. The stock MPSS boot image was not replaced.

## Runtime Results

The K1OM ELF checks passed for the staged executable/runtime files:

- `/usr/bin/hello-knc`
- `/usr/bin/python3.5`
- `/usr/bin/zlib-smoke`
- `/usr/bin/ncurses-smoke`
- `/bin/bash`
- `/bin/busybox`
- `/sbin/init.sysvinit`
- dynamic loader and stock runtime libraries

Runtime output:

```text
hello from knc
machine=k1om
sizeof(void*)=8
sizeof(long)=8
```

```text
zlib version=1.3 result=knc zlib smoke
```

```text
ncurses version=ncurses 6.4.20240113
```

```text
python demo ok
platform=linux
cwd=/
thread=42
```

```text
math=12.0
zlib=knc
```

## Integration Findings

The first Python rootfs attempt failed because the interpreter's dynamic
dependencies were incomplete. Adding stock K1OM `libutil.so.1` and `librt.so.1`
closed the loader dependencies.

The next Python attempt failed because the demo rootfs had an empty `/dev`.
Creating temporary device nodes for `/dev/null`, `/dev/zero`, and
`/dev/urandom` inside the test rootfs allowed CPython to initialize.

The `zlib` CPython extension required a PIC rebuild of the Ubuntu-source zlib
static library. The `math` extension required linking CPython's
`Modules/_math.c` support object to provide `_Py_log1p`.

## Remaining Gaps

This is a strong compatibility demo, not a complete operating system port.

Still missing:

- booting the rootfs as PID 1
- persistent `/dev`, `/proc`, and `/sys` setup from init scripts
- SSH/networking inside the custom rootfs
- `_sqlite3`, `_ctypes`, and `_curses` CPython extension modules
- package-manager metadata
- true Ubuntu archive integration
