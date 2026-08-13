#!/usr/bin/env bash
# Build the source-accounted eglibc development stage required by Toolkit v1.
set -euo pipefail

usage() {
  cat <<'EOF'
usage: build-xpr-k1om-eglibc-stage.sh --source-bundle RC6-sources.tar.gz [--sdk-root DIR] --out DIR [--jobs N]
EOF
}

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
source_bundle= sdk_root=/opt/mpss/3.4.10 out= jobs=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-bundle) source_bundle=$2; shift 2 ;;
    --sdk-root) sdk_root=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    --jobs) jobs=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done
[[ -n "$source_bundle" && -n "$out" ]] || { usage >&2; exit 2; }
[[ -f "$source_bundle" ]] || { echo "source bundle not found: $source_bundle" >&2; exit 1; }
[[ ! -e "$out" ]] || { echo "output already exists: $out" >&2; exit 1; }

expected=bb530e170e9871627903644f52d8271c1f9c3375d4d3bc1d62c0c4eaa60a6558
actual=$(sha256sum "$source_bundle" | awk '{print $1}')
[[ "$actual" == "$expected" ]] || {
  echo "unexpected RC6 source-bundle hash: $actual" >&2; exit 1;
}
tools="$sdk_root/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux"
[[ -x "$tools/k1om-mpss-linux-gcc" ]] || { echo "missing MPSS SDK compiler: $tools/k1om-mpss-linux-gcc" >&2; exit 1; }
[[ -d "$sdk_root/sysroots/k1om-mpss-linux/usr/include" ]] || { echo "missing MPSS SDK sysroot headers" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -xzf "$source_bundle" -C "$work"
source_root=$(find "$work" -mindepth 1 -maxdepth 1 -type d -name 'xpr-os-*-sources' -print -quit)
[[ -n "$source_root" ]] || { echo "RC6 source bundle layout is invalid" >&2; exit 1; }
sources="$source_root/sources"
for input in eglibc_2.19.orig.tar.xz eglibc_2.19-0ubuntu6.15.debian.tar.xz; do
  [[ -f "$sources/$input" ]] || { echo "RC6 source bundle is missing: sources/$input" >&2; exit 1; }
done

bash "$repo_root/tools/release/build-eglibc-k1om-runtime.sh" \
  --orig "$sources/eglibc_2.19.orig.tar.xz" \
  --debian "$sources/eglibc_2.19-0ubuntu6.15.debian.tar.xz" \
  --overlay "$repo_root/ubuntu-port/k1om/glibc" \
  --sysroot "$sdk_root/sysroots/k1om-mpss-linux" \
  --out "$out" \
  --cross-compile "$tools/k1om-mpss-linux-" \
  --jobs "$jobs"

printf 'XPR_K1OM_EGLIBC_STAGE=PASS\nXPR_K1OM_EGLIBC_STAGE=%s/stage\n' "$out"
