#!/usr/bin/env bash
set -euo pipefail

echo "=== host tools ==="
for tool in gcc g++ make ld as ar objdump readelf cmake autoconf automake bison flex libtool; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%-28s %s\n' "$tool" "$(command -v "$tool")"
  else
    printf '%-28s missing\n' "$tool"
  fi
done

echo "=== knc tools ==="
for tool in icc icpc x86_64-k1om-linux-gcc x86_64-k1om-linux-as x86_64-k1om-linux-ld x86_64-k1om-linux-objdump; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%-28s %s\n' "$tool" "$(command -v "$tool")"
  else
    printf '%-28s missing\n' "$tool"
  fi
done
