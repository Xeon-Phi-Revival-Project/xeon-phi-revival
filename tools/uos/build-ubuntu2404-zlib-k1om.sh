#!/usr/bin/env bash
set -euo pipefail

version="1.3.dfsg-3.1ubuntu2"
base_url="https://archive.ubuntu.com/ubuntu/pool/main/z/zlib"
work_root="${1:-${XEON_PHI_LOCAL_ROOT:-${HOME}/xeon-phi-revival-local}/ubuntu2404-level2}"
work="${work_root}/zlib-${version}-$(date +%Y%m%d-%H%M%S)"
env_script="${K1OM_ENV_SCRIPT:-/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux}"

mkdir -p "$work"
cd "$work"

for file in \
  "zlib_${version}.dsc" \
  "zlib_1.3.dfsg.orig.tar.xz" \
  "zlib_${version}.debian.tar.xz"; do
  curl -fsSLO "${base_url}/${file}"
done

sha256sum \
  "zlib_${version}.dsc" \
  "zlib_1.3.dfsg.orig.tar.xz" \
  "zlib_${version}.debian.tar.xz" > downloaded.sha256

sed -n '/Checksums-Sha256:/,/Files:/p' "zlib_${version}.dsc" |
  grep 'tar.xz' |
  while read -r sha _size file; do
    printf '%s  %s\n' "$sha" "$file"
  done > expected.sha256

sha256sum -c expected.sha256

mkdir src
cd src
tar -xf "../zlib_1.3.dfsg.orig.tar.xz" --strip-components=1
tar -xf "../zlib_${version}.debian.tar.xz"

if [[ -f debian/patches/series ]]; then
  while IFS= read -r patch_name; do
    case "$patch_name" in
      ""|"#"*) continue ;;
    esac
    patch -p1 < "debian/patches/$patch_name"
  done < debian/patches/series
fi

if [[ -f "$env_script" ]]; then
  # shellcheck disable=SC1090
  source "$env_script"
fi

export CC=k1om-mpss-linux-gcc
export AR=k1om-mpss-linux-ar
export RANLIB=k1om-mpss-linux-ranlib

./configure --prefix=/usr --static
make -j"${JOBS:-2}"

echo "work=$work"
echo "libz=$work/src/libz.a"
