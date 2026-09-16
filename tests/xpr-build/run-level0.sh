#!/usr/bin/env bash
set -euo pipefail

repo=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
toolkit=${1:?usage: run-level0.sh UNPACKED_TOOLKIT [BUILD_DIR]}
build=${2:-"$repo/build/xpr-build-level0"}
stage="$build/stage"
[[ ! -e "$build" ]] || { echo "refusing existing build directory: $build" >&2; exit 1; }
"$repo/tools/xpr-build/xpr-build" configure --toolkit "$toolkit" \
  --source "$repo/tests/xpr-build/level0" --build "$build"
"$repo/tools/xpr-build/xpr-build" make --toolkit "$toolkit" --build "$build"
"$repo/tools/xpr-build/xpr-build" inspect --toolkit "$toolkit" "$build/xpr-build-level0"
"$repo/tools/xpr-build/xpr-build" stage --toolkit "$toolkit" --build "$build" --destdir "$stage"
test -x "$stage/usr/bin/xpr-build-level0"
echo "XPR_BUILD_LEVEL0_BUILD=PASS"
echo "XPR_BUILD_LEVEL0_K1OM=PASS"
