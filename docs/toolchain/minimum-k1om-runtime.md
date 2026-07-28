# Minimum K1OM Runtime Set

Public-safe metadata report. No runtime library contents are included.

## Files Checked

- `/lib64/ld-linux-k1om.so.2`: present, symlink -> `ld-2.14.1.so`
- `/lib64/libc.so.6`: present, symlink -> `libc-2.14.1.so`
- `/lib64/libgcc_s.so.1`: present, file
- `/lib64/libpthread.so.0`: present, symlink -> `libpthread-2.14.1.so`
- `/lib64/libm.so.6`: present, symlink -> `libm-2.14.1.so`
- `/lib64/libdl.so.2`: present, symlink -> `libdl-2.14.1.so`
- `/usr/lib64/crt1.o`: missing
- `/usr/lib64/crti.o`: missing
- `/usr/lib64/crtn.o`: missing
- `/lib64/crt1.o`: missing
- `/lib64/crti.o`: missing
- `/lib64/crtn.o`: missing

## Initial Interpretation

- Runtime loader and core shared libraries are runtime components.
- `crt1.o`, `crti.o`, and `crtn.o` are link-time startup objects.
- If startup objects are missing, the stock uOS is not a complete development sysroot by itself.
- Missing unversioned `.so` linker names may also indicate runtime-only contents.

## Observed Passing Binary Dependencies

Collected with `k1om-mpss-linux-readelf` after the MPSS SDK K1OM package was
installed and smoke binaries were run on `mic0`.

| Binary | Link style | Interpreter | `NEEDED` libraries | Result |
| --- | --- | --- | --- | --- |
| `start-exit42` | static, `-nostdlib` | none | none | returned `42` |
| `hello-libc` | dynamic glibc | `/lib64/ld-linux-k1om.so.2` | `libc.so.6` | printed `hello from k1om libc`, returned `0` |
| `hello-knc` | dynamic glibc | `/lib64/ld-linux-k1om.so.2` | `libc.so.6` | reported `machine=k1om`, returned `0` |
| `return-constant` | dynamic glibc | `/lib64/ld-linux-k1om.so.2` | `libc.so.6` | returned `37` |
| `file-io-smoke-test` | dynamic glibc | `/lib64/ld-linux-k1om.so.2` | `libc.so.6` | printed `file io ok`, returned `0` |
| `math-smoke-test` | dynamic glibc plus `-lm` | `/lib64/ld-linux-k1om.so.2` | `libm.so.6`, `libc.so.6` | printed `sqrt=12.0`, returned `0` |
| `thread-smoke-test` | dynamic glibc plus `-pthread` | `/lib64/ld-linux-k1om.so.2` | `libpthread.so.0`, `libc.so.6` | printed `pthread result=123`, returned `0` |
| `vector-smoke-test` | dynamic glibc plus inline zmm asm | `/lib64/ld-linux-k1om.so.2` | `libc.so.6` | printed `vector sum first=11.0 last=11.0`, returned `0` |

## Current Minimum Map

- Freestanding ELF can run without the dynamic loader or libc if linked with an
  explicit entry point and no libc.
- Normal dynamic C programs need:
  - `/lib64/ld-linux-k1om.so.2`
  - `libc.so.6`
- Math programs add:
  - `libm.so.6`
- Pthread programs add:
  - `libpthread.so.0`
- The current zmm inline-assembly vector smoke test adds no shared-library
  dependency beyond libc.

This map is enough to begin small ports and toolchain experiments. It is not yet
enough to claim Python, Java, Doom, OpenMP, SCIF, offload, C++, or
package-manager workloads will run.
