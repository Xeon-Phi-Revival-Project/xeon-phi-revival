#!/usr/bin/env bash
# Diagnostic equivalent of xpr-gcc for explicit -nostdlib configure probes.
set -euo pipefail

root=${XPR_K1OM_TOOLKIT_ROOT:?set XPR_K1OM_TOOLKIT_ROOT}
exec env GCC_EXEC_PREFIX="$root/libexec/gcc/" "$root/libexec/k1om-mpss-linux-gcc" \
  -B"$root/libexec/gcc/k1om-mpss-linux/5.1.1" -B"$root/lib/gcc/k1om-mpss-linux/5.1.1" -B"$root/libexec" \
  --sysroot="$root/sysroot" -isystem "$root/sysroot/usr/include" \
  -L"$root/sysroot/usr/lib64" -L"$root/sysroot/lib64" \
  -Wl,--dynamic-linker=/lib64/ld-linux-k1om.so.2 -Wl,-rpath,/lib64 \
  -Wl,--no-as-needed "$@"
