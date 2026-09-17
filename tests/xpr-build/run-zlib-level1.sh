#!/usr/bin/env bash
set -euo pipefail

repo=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
toolkit=${1:?usage: run-zlib-level1.sh UNPACKED_TOOLKIT ZLIB_SOURCE_DIR [BUILD_DIR]}
source_dir=${2:?usage: run-zlib-level1.sh UNPACKED_TOOLKIT ZLIB_SOURCE_DIR [BUILD_DIR]}
build=${3:-"$repo/build/xpr-build-zlib-level1"}

[[ -x "$source_dir/configure" ]] || { echo "zlib source lacks configure" >&2; exit 1; }
[[ ! -e "$build" ]] || { echo "refusing existing build directory: $build" >&2; exit 1; }

"$repo/tools/xpr-build/xpr-build" configure --configure-style plain \
  --toolkit "$toolkit" --source "$source_dir" --build "$build" -- --static
"$repo/tools/xpr-build/xpr-build" make --toolkit "$toolkit" --build "$build"
test -f "$build/libz.a"
"$toolkit/bin/xpr-gcc" -I"$build" -I"$source_dir" \
  "$repo/tests/native/zlib-smoke-test.c" "$build/libz.a" -o "$build/zlib-smoke"
"$repo/tools/xpr-build/xpr-build" inspect --toolkit "$toolkit" "$build/zlib-smoke"
echo "XPR_BUILD_ZLIB_LEVEL1=PASS"
