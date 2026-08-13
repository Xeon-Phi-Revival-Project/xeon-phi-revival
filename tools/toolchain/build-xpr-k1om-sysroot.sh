#!/usr/bin/env bash
# Construct a local K1OM development sysroot from public XPR runtime payload
# plus explicitly user-supplied MPSS SDK development inputs.
set -euo pipefail

usage() {
  cat <<'EOF'
usage: build-xpr-k1om-sysroot.sh --release RC6.tar.gz [--sdk-root DIR] --out DIR
EOF
}

release= sdk_root= out=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) release=$2; shift 2 ;;
    --sdk-root) sdk_root=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ -n "$release" && -n "$out" ]] || { usage >&2; exit 2; }
[[ -f "$release" ]] || { echo "release not found: $release" >&2; exit 1; }
sdk_root=${sdk_root:-/opt/mpss/3.4.10}
sdk_sysroot="$sdk_root/sysroots/k1om-mpss-linux"
sdk_tools="$sdk_root/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux"
for path in "$sdk_sysroot/usr/include" "$sdk_sysroot/usr/lib64/crt1.o" \
            "$sdk_tools/k1om-mpss-linux-gcc" "$sdk_tools/k1om-mpss-linux-readelf"; do
  [[ -e "$path" ]] || { echo "missing MPSS SDK input: $path" >&2; exit 1; }
done
[[ ! -e "$out" ]] || { echo "output already exists: $out" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -xzf "$release" -C "$work"
release_root=$(find "$work" -mindepth 1 -maxdepth 1 -type d -name 'xpr-os-*' -print -quit)
[[ -n "$release_root" && -f "$release_root/payload/xpr-rootfs.cpio.gz" ]] || {
  echo "release does not contain an XPR root payload" >&2; exit 1;
}
mkdir -p "$work/root"
(cd "$work/root" && gzip -cd "$release_root/payload/xpr-rootfs.cpio.gz" | cpio -idm --quiet)
for path in lib64/ld-linux-k1om.so.2 lib64/libc.so.6 lib64/libpthread.so.0 \
            lib64/libm.so.6 lib64/libdl.so.2 lib64/librt.so.1 lib64/libutil.so.1 \
            lib64/libgcc_s.so.1; do
  [[ -e "$work/root/$path" ]] || { echo "XPR payload missing runtime: $path" >&2; exit 1; }
done

mkdir -p "$out/sysroot/usr/include" "$out/sysroot/usr/lib64" "$out/metadata"
cp -a "$work/root/lib64" "$out/sysroot/lib64"
ln -s lib64 "$out/sysroot/lib"
cp -a "$sdk_sysroot/usr/include/." "$out/sysroot/usr/include/"
for item in crt1.o Scrt1.o Mcrt1.o gcrt1.o crti.o crtn.o libc_nonshared.a libpthread_nonshared.a; do
  [[ -e "$sdk_sysroot/usr/lib64/$item" ]] && cp -a "$sdk_sysroot/usr/lib64/$item" "$out/sysroot/usr/lib64/"
done
for item in libc.so libpthread.so libm.so libdl.so librt.so libutil.so; do
  [[ -e "$sdk_sysroot/usr/lib64/$item" ]] && cp -a "$sdk_sysroot/usr/lib64/$item" "$out/sysroot/usr/lib64/"
done
for item in crtbegin.o crtbeginS.o crtend.o crtendS.o libgcc.a; do
  compiler_item=$("$sdk_tools/k1om-mpss-linux-gcc" --print-file-name="$item")
  [[ -f "$compiler_item" ]] || { echo "MPSS compiler support input is missing: $item" >&2; exit 1; }
  cp -a "$compiler_item" "$out/sysroot/usr/lib64/"
done

{
  echo "release=$(readlink -f "$release")"
  echo "sdk_root=$(readlink -f "$sdk_root")"
  echo "runtime_source=public RC6 payload"
  echo "headers_and_crt_source=user-supplied MPSS SDK"
  echo "compiler=$sdk_tools/k1om-mpss-linux-gcc"
  sha256sum "$release"
  find "$out/sysroot" -type f -print0 | sort -z | xargs -0 sha256sum
} > "$out/metadata/SHA256SUMS"
printf 'XPR_K1OM_SYSROOT=PASS\nXPR_K1OM_SYSROOT=%s\n' "$out/sysroot"
