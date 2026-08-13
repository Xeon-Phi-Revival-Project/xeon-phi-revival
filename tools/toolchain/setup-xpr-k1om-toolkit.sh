#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
release= eglibc_stage= sdk_root=/opt/mpss/3.4.10 out="$repo_root/build/xpr-k1om"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) release=$2; shift 2 ;;
    --eglibc-stage) eglibc_stage=$2; shift 2 ;;
    --sdk-root) sdk_root=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    -h|--help) echo "usage: setup-xpr-k1om-toolkit.sh --release RC6.tar.gz --eglibc-stage DIR [--sdk-root DIR] [--out DIR]"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$release" && -n "$eglibc_stage" ]] || { echo "--release and --eglibc-stage are required" >&2; exit 2; }
tools="$sdk_root/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux"
for tool in gcc readelf objdump as ld; do
  [[ -x "$tools/k1om-mpss-linux-$tool" ]] || { echo "missing MPSS SDK tool: $tools/k1om-mpss-linux-$tool" >&2; exit 1; }
done
bash "$repo_root/tools/toolchain/build-xpr-k1om-sysroot.sh" --release "$release" --eglibc-stage "$eglibc_stage" --sdk-root "$sdk_root" --out "$out"
mkdir -p "$out/bin"
cp "$repo_root/toolchains/xpr-k1om/bin/xpr-gcc" "$out/bin/xpr-gcc"
cp "$repo_root/toolchains/xpr-k1om/bin/xpr-readelf" "$out/bin/xpr-readelf"
chmod 755 "$out/bin/xpr-gcc" "$out/bin/xpr-readelf"
cat > "$out/config.env" <<EOF
XPR_K1OM_SYSROOT='$out/sysroot'
XPR_K1OM_GCC='$tools/k1om-mpss-linux-gcc'
XPR_K1OM_READELF='$tools/k1om-mpss-linux-readelf'
EOF
cat > "$out/env.sh" <<EOF
export PATH='$out/bin':\$PATH
export XPR_READELF='$out/bin/xpr-readelf'
EOF
echo "XPR_K1OM_TOOLKIT=PASS"
echo "source $out/env.sh"
