#!/usr/bin/env bash
set -euo pipefail

script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if command -v git >/dev/null 2>&1 && git -C "$script_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repo_root="$(git -C "$script_root" rev-parse --show-toplevel)"
  list_files() { git ls-files; }
else
  repo_root="$script_root"
  list_files() { find . -type f -print | sed 's#^./##' | LC_ALL=C sort; }
fi
cd "$repo_root"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for path in LICENSE NOTICE.md LICENSES/LGPL-2.1-or-later.txt docs/release/compliance-review.md; do
  [[ -f "$path" ]] || fail "required compliance file is missing: $path"
done

grep -q 'GNU LESSER GENERAL PUBLIC LICENSE' LICENSES/LGPL-2.1-or-later.txt || fail "LGPL text is incomplete"
grep -q 'Version 2.1' LICENSES/LGPL-2.1-or-later.txt || fail "LGPL version marker is missing"

mapfile -t overlay_files < <(list_files | grep '^ubuntu-port/k1om/glibc/' | grep -E '\.(c|h|S)$')
[[ "${#overlay_files[@]}" -gt 0 ]] || fail "no tracked eglibc overlay files were found"
for path in "${overlay_files[@]}"; do
  head -c 512 "$path" | grep -q 'SPDX-License-Identifier: LGPL-2.1-or-later' || \
    fail "eglibc overlay lacks LGPL SPDX marker: $path"
done

forbidden='(^|/)(private|stock-uos|sysroot|k1om-sysroot|mpss-packages)(/|$)|\.(rpm|deb|ko|bin|img|rom|fw|elf|o|a|so([.][0-9]+)*)$'
bad="$(list_files | grep -Ei "$forbidden" || true)"
[[ -z "$bad" ]] || fail "tracked private/binary payloads: $bad"

for marker in Intel Canonical LGPL-2.1-or-later; do
  grep -q "$marker" NOTICE.md || fail "NOTICE.md lacks required marker: $marker"
done

echo "PASS: required compliance files=4"
echo "PASS: LGPL overlay files=${#overlay_files[@]}"
echo "PASS: no tracked private or binary payloads"
echo "PASS: source release compliance boundary"

# The source/BYO-MPSS lane intentionally remains distinct from a public binary
# lane. A candidate prebuilt image must be checked with audit-prebuilt-image.py
# and manifests/release/prebuilt-clean-profile.json; do not relax this audit.
