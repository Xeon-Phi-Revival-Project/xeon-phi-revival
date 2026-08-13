#!/usr/bin/env bash
# Construct a local K1OM development sysroot from public XPR runtime payload
# plus explicitly user-supplied MPSS SDK development inputs.
set -euo pipefail

usage() {
  cat <<'EOF'
usage: build-xpr-k1om-sysroot.sh --release RC6.tar.gz --eglibc-stage DIR [--sdk-root DIR] --out DIR
EOF
}

release= eglibc_stage= sdk_root= out=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) release=$2; shift 2 ;;
    --eglibc-stage) eglibc_stage=$2; shift 2 ;;
    --sdk-root) sdk_root=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ -n "$release" && -n "$eglibc_stage" && -n "$out" ]] || { usage >&2; exit 2; }
[[ -f "$release" ]] || { echo "release not found: $release" >&2; exit 1; }
sdk_root=${sdk_root:-/opt/mpss/3.4.10}
sdk_tools="$sdk_root/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux"
[[ -d "$eglibc_stage/usr/include" ]] || { echo "missing source-built eglibc headers: $eglibc_stage/usr/include" >&2; exit 1; }
for path in "$sdk_tools/k1om-mpss-linux-gcc" "$sdk_tools/k1om-mpss-linux-readelf"; do
  [[ -e "$path" ]] || { echo "missing MPSS SDK tool: $path" >&2; exit 1; }
done
eglibc_libdir="$eglibc_stage/usr/lib"
[[ -d "$eglibc_libdir" ]] || eglibc_libdir="$eglibc_stage/lib"
for item in crt1.o crti.o crtn.o libc_nonshared.a libpthread_nonshared.a \
            libc.so libpthread.so libm.so libdl.so librt.so libutil.so; do
  [[ -e "$eglibc_libdir/$item" ]] || {
    echo "source-built eglibc stage is missing: $eglibc_libdir/$item" >&2; exit 1;
  }
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
# eglibc's installed linker scripts name /usr/lib/*.a.  K1OM uses the LP64
# lib64 directory, so keep the script-visible path inside this sysroot.
ln -s lib64 "$out/sysroot/usr/lib"
cp -a "$eglibc_stage/usr/include/." "$out/sysroot/usr/include/"
for item in crt1.o Scrt1.o Mcrt1.o gcrt1.o crti.o crtn.o libc_nonshared.a libpthread_nonshared.a; do
  [[ -e "$eglibc_libdir/$item" ]] && cp -a "$eglibc_libdir/$item" "$out/sysroot/usr/lib64/"
done
for item in libc.so libpthread.so libm.so libdl.so librt.so libutil.so; do
  cp -a "$eglibc_libdir/$item" "$out/sysroot/usr/lib64/"
done
for item in crtbegin.o crtbeginS.o crtend.o crtendS.o libgcc.a; do
  compiler_item=$("$sdk_tools/k1om-mpss-linux-gcc" --print-file-name="$item")
  [[ -f "$compiler_item" ]] || { echo "MPSS compiler support input is missing: $item" >&2; exit 1; }
  cp -a "$compiler_item" "$out/sysroot/usr/lib64/"
done

{
  echo "release=$(readlink -f "$release")"
  echo "sdk_root=$(readlink -f "$sdk_root")"
  echo "eglibc_stage=$(readlink -f "$eglibc_stage")"
  echo "runtime_source=public RC6 payload"
  echo "headers_and_crt_source=source-built XPR eglibc stage"
  echo "compiler=$sdk_tools/k1om-mpss-linux-gcc"
  sha256sum "$release"
  find "$out/sysroot" -type f -print0 | sort -z | xargs -0 sha256sum
} > "$out/metadata/SHA256SUMS"
printf 'XPR_K1OM_SYSROOT=PASS\nXPR_K1OM_SYSROOT=%s\n' "$out/sysroot"
