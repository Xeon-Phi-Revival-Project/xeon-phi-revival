#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-}"
if [[ -z "$repo_dir" || ! -d "$repo_dir" ]]; then
  echo "usage: $0 REPO_DIR" >&2
  exit 2
fi

packages_file="$repo_dir/dists/noble/main/binary-k1om/Packages"
packages_gz_file="$repo_dir/dists/noble/main/binary-k1om/Packages.gz"
release_file="$repo_dir/dists/noble/Release"
mkdir -p "$(dirname "$packages_file")" "$(dirname "$release_file")"
: > "$packages_file"

while IFS= read -r -d '' deb; do
  tmp="$(mktemp -d)"
  (cd "$tmp" && ar x "$deb" control.tar.gz)
  control="$(tar -xOzf "$tmp/control.tar.gz" ./control)"
  size="$(stat -c '%s' "$deb")"
  md5sum_value="$(md5sum "$deb" | awk '{print $1}')"
  sha1="$(sha1sum "$deb" | awk '{print $1}')"
  sha256="$(sha256sum "$deb" | awk '{print $1}')"
  rel="${deb#"$repo_dir"/}"
  {
    printf '%s\n' "$control"
    printf 'Filename: %s\n' "$rel"
    printf 'Size: %s\n' "$size"
    printf 'MD5sum: %s\n' "$md5sum_value"
    printf 'SHA1: %s\n' "$sha1"
    printf 'SHA256: %s\n\n' "$sha256"
  } >> "$packages_file"
  rm -rf "$tmp"
done < <(find "$repo_dir/pool" -type f -name '*.deb' -print0 2>/dev/null | sort -z)

gzip -n -c "$packages_file" > "$packages_gz_file"
packages_size="$(stat -c '%s' "$packages_file")"
packages_md5="$(md5sum "$packages_file" | awk '{print $1}')"
packages_sha1="$(sha1sum "$packages_file" | awk '{print $1}')"
packages_sha256="$(sha256sum "$packages_file" | awk '{print $1}')"
packages_gz_size="$(stat -c '%s' "$packages_gz_file")"
packages_gz_md5="$(md5sum "$packages_gz_file" | awk '{print $1}')"
packages_gz_sha1="$(sha1sum "$packages_gz_file" | awk '{print $1}')"
packages_gz_sha256="$(sha256sum "$packages_gz_file" | awk '{print $1}')"
release_date="$(date -u -d "@${SOURCE_DATE_EPOCH:-1704067200}" '+%a, %d %b %Y %H:%M:%S UTC')"
cat > "$release_file" <<EOF
Origin: Xeon Phi Revival Project
Label: Xeon Phi Revival K1OM Bootstrap
Suite: noble
Codename: noble
Architectures: k1om
Components: main
Date: $release_date
Description: Local unsigned K1OM bootstrap archive
MD5Sum:
 $packages_md5 $packages_size main/binary-k1om/Packages
 $packages_gz_md5 $packages_gz_size main/binary-k1om/Packages.gz
SHA1:
 $packages_sha1 $packages_size main/binary-k1om/Packages
 $packages_gz_sha1 $packages_gz_size main/binary-k1om/Packages.gz
SHA256:
 $packages_sha256 $packages_size main/binary-k1om/Packages
 $packages_gz_sha256 $packages_gz_size main/binary-k1om/Packages.gz
EOF

echo "packages=$packages_file"
echo "packages_gz=$packages_gz_file"
echo "release=$release_file"
