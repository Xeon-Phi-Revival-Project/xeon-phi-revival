#!/usr/bin/env bash
# Validate that a CPython K1OM core package contains no legacy or SDK payload.
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 PACKAGE.tar.xz" >&2; exit 2; }
package=$1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -C "$work" -xJf "$package"
root=$(find "$work" -mindepth 1 -maxdepth 1 -type d -print -quit)
python=$(find "$root" -path '*/usr/bin/python3.12' -type f -print -quit)
[[ -n "$python" ]] || { echo "missing python3.12" >&2; exit 1; }
readelf -h "$python" | grep -F 'Machine:                           Intel K1OM' >/dev/null
if grep -R -a -n -E '/opt/mpss|mpss-sdk|python3\.5|/root/|/home/' "$root"; then
    echo "package contamination found" >&2
    exit 1
fi
echo 'PYTHON312_MPSS_BINARY_PAYLOAD=0'
echo 'PYTHON35_PAYLOAD=0'
echo 'PYTHON312_CORE_CONTAMINATION_AUDIT=PASS'
