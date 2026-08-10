# Clean eglibc K1OM Rebuild

This is the source-only reconstruction lane for the public XPR root. It does
not copy the historical runtime and it does not install into MPSS.

## Pinned baseline

The candidate baseline is Ubuntu Trusty's `eglibc 2.19-0ubuntu6.15` source
package:

| Input | SHA-256 |
| --- | --- |
| `eglibc_2.19.orig.tar.xz` | `e5d30be72b702dffae527779af1be755f0dfbf13c171998a04f7265cd4da131f` |
| `eglibc_2.19-0ubuntu6.15.debian.tar.xz` | `2e0a1d4dfbc8bb666604d6804b9fbd9ce7a1f23b2a5bcb487f5a774d2c557e4c` |

`ubuntu-port/k1om/glibc/` is the tracked XPR overlay. It supplies K1OM loader
identity, loader-name, pthread lock handling, and explicit x86-64 LP64 sysdeps
inheritance. The source and overlay are LGPL-covered; the project does not
claim that this candidate is byte-identical to the historical private runtime.

## Rebuild command

On an MPSS host with a user-provided K1OM SDK/sysroot:

```bash
tools/release/build-eglibc-k1om-runtime.sh \
  --orig eglibc_2.19.orig.tar.xz \
  --debian eglibc_2.19-0ubuntu6.15.debian.tar.xz \
  --overlay ubuntu-port/k1om/glibc \
  --sysroot /opt/mpss/3.4.10/sysroots/k1om-mpss-linux \
  --out /private/output/eglibc-k1om \
  --cross-compile /opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux/k1om-mpss-linux-
```

The builder applies the Ubuntu patch series in its recorded order, records all
input hashes and compiler versions, verifies K1OM ELF headers, and emits hashes
for the required loader, libc, pthread, math, dl, rt, and util libraries.

## Current reconstruction result

The 2026-08-09 clean build accepted `k1om-mpss-linux`, configured successfully,
and selected the K1OM LP64 plus x86-64 FPU helper chain. The tracked K1OM
overrides now deliberately separate those two concerns:

- `bits/mathinline.h` prevents the inherited x86 inline math bodies from
  colliding with x86-64 helper selection.
- `math_private.h` retains the upstream x87 fenv support but uses eglibc's
  generic union-based float/double bit accessors instead of x86-64 SSE `movq`
  constraints.
- `wordsize-64` supplies the required LP64 `strtoimax` and related selections.

This advances past `s_scalbnl`, the long-double classification helpers, math,
the affected string and wide-character routines, and the NPTL mutex,
condition-variable, and spinlock compile paths. K1OM selects generic upstream
C implementations only where the inherited x86-64 routine requires unsupported
SSE, conditional-move, xgetbv, or TSX behavior.

The builder now explicitly selects `nptl,ports`; default add-on detection also
enabled the obsolete `libpthread` add-on, which is incompatible with the NPTL
callback ABI. The NPTL-only build reaches the final `libc.so` link. Its first
unresolved symbol was `__strncasecmp`, addressed by the tracked generic K1OM
fallback. The next clean build is the validation point for that final-link fix.

This is a source-level K1OM overlay issue. No binary from the private runtime
was copied into the public profile, and no hardware test is warranted yet.
