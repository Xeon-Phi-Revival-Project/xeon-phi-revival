#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-}"
out_dir="${2:-}"
if [[ -z "$repo_dir" || -z "$out_dir" || ! -d "$repo_dir" ]]; then
  echo "usage: $0 REPO_DIR OUT_DIR" >&2
  exit 2
fi

packages_file="$repo_dir/dists/noble/main/binary-k1om/Packages"
packages_gz_file="$repo_dir/dists/noble/main/binary-k1om/Packages.gz"
release_file="$repo_dir/dists/noble/Release"
ownership_file="$out_dir/package-ownership.tsv"
deps_file="$out_dir/package-dependencies.tsv"
hash_file="$out_dir/package-hashes.tsv"
summary_file="$out_dir/package-audit-summary.txt"
mkdir -p "$out_dir"

[[ -f "$packages_file" ]] || { echo "missing Packages file: $packages_file" >&2; exit 10; }
[[ -f "$packages_gz_file" ]] || { echo "missing Packages.gz file: $packages_gz_file" >&2; exit 18; }
[[ -f "$release_file" ]] || { echo "missing Release file: $release_file" >&2; exit 11; }
grep -q '^Architectures: k1om$' "$release_file" || { echo "Release does not advertise Architectures: k1om" >&2; exit 12; }
grep -q '^Suite: noble$' "$release_file" || { echo "Release does not advertise Suite: noble" >&2; exit 13; }
grep -q '^Codename: noble$' "$release_file" || { echo "Release does not advertise Codename: noble" >&2; exit 14; }
grep -q '^MD5Sum:$' "$release_file" || { echo "Release missing MD5Sum block" >&2; exit 15; }
grep -q '^SHA1:$' "$release_file" || { echo "Release missing SHA1 block" >&2; exit 16; }
grep -q '^SHA256:$' "$release_file" || { echo "Release missing SHA256 block" >&2; exit 17; }
cmp <(gzip -dc "$packages_gz_file") "$packages_file" || { echo "Packages.gz does not decompress to Packages" >&2; exit 19; }
packages_rel="main/binary-k1om/Packages"
packages_gz_rel="main/binary-k1om/Packages.gz"
packages_size="$(stat -c '%s' "$packages_file")"
packages_gz_size="$(stat -c '%s' "$packages_gz_file")"
packages_md5="$(md5sum "$packages_file" | awk '{print $1}')"
packages_sha1="$(sha1sum "$packages_file" | awk '{print $1}')"
packages_sha256="$(sha256sum "$packages_file" | awk '{print $1}')"
packages_gz_md5="$(md5sum "$packages_gz_file" | awk '{print $1}')"
packages_gz_sha1="$(sha1sum "$packages_gz_file" | awk '{print $1}')"
packages_gz_sha256="$(sha256sum "$packages_gz_file" | awk '{print $1}')"
grep -q " $packages_md5 $packages_size $packages_rel$" "$release_file" || { echo "Release has wrong MD5 for Packages" >&2; exit 34; }
grep -q " $packages_sha1 $packages_size $packages_rel$" "$release_file" || { echo "Release has wrong SHA1 for Packages" >&2; exit 35; }
grep -q " $packages_sha256 $packages_size $packages_rel$" "$release_file" || { echo "Release has wrong SHA256 for Packages" >&2; exit 36; }
grep -q " $packages_gz_md5 $packages_gz_size $packages_gz_rel$" "$release_file" || { echo "Release has wrong MD5 for Packages.gz" >&2; exit 37; }
grep -q " $packages_gz_sha1 $packages_gz_size $packages_gz_rel$" "$release_file" || { echo "Release has wrong SHA1 for Packages.gz" >&2; exit 38; }
grep -q " $packages_gz_sha256 $packages_gz_size $packages_gz_rel$" "$release_file" || { echo "Release has wrong SHA256 for Packages.gz" >&2; exit 39; }

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

: > "$ownership_file"
: > "$deps_file"
: > "$hash_file"

declare -A seen_packages=()
declare -A package_files=()
declare -A package_depends=()

while IFS= read -r -d '' deb; do
  pkg_tmp="$tmp_root/$(basename "$deb" .deb)"
  mkdir -p "$pkg_tmp"
  (cd "$pkg_tmp" && ar x "$deb" control.tar.gz data.tar.gz)
  control="$(tar -xOzf "$pkg_tmp/control.tar.gz" ./control)"
  package="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Package" { print $2; exit }')"
  source="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Source" { print $2; exit }')"
  version="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Version" { print $2; exit }')"
  arch="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Architecture" { print $2; exit }')"
  section="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Section" { print $2; exit }')"
  priority="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Priority" { print $2; exit }')"
  depends="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Depends" { print $2; exit }')"
  [[ -n "$package" ]] || { echo "package without Package field: $deb" >&2; exit 20; }
  [[ "$source" == "xeon-phi-revival-bootstrap" ]] || { echo "$package has unexpected Source field: $source" >&2; exit 24; }
  [[ -n "$version" ]] || { echo "$package missing Version" >&2; exit 25; }
  [[ "$arch" == "k1om" ]] || { echo "$package has unexpected architecture: $arch" >&2; exit 21; }
  [[ -n "$section" ]] || { echo "$package missing Section" >&2; exit 26; }
  [[ "$priority" == "optional" ]] || { echo "$package has unexpected Priority: $priority" >&2; exit 27; }
  tar -tzf "$pkg_tmp/control.tar.gz" | grep -qx './md5sums' || { echo "$package missing md5sums control member" >&2; exit 28; }
  seen_packages["$package"]=1
  package_files["$package"]="$deb"
  package_depends["$package"]="$depends"
  printf '%s\t%s\t%s\t%s\n' "$package" "$version" "$arch" "$depends" >> "$deps_file"
  sha256="$(sha256sum "$deb" | awk '{print $1}')"
  md5sum_value="$(md5sum "$deb" | awk '{print $1}')"
  sha1="$(sha1sum "$deb" | awk '{print $1}')"
  rel="${deb#"$repo_dir"/}"
  grep -q "^Filename: $rel$" "$packages_file" || { echo "Packages missing Filename for $rel" >&2; exit 22; }
  grep -q "^MD5sum: $md5sum_value$" "$packages_file" || { echo "Packages has wrong MD5sum for $rel" >&2; exit 32; }
  grep -q "^SHA1: $sha1$" "$packages_file" || { echo "Packages has wrong SHA1 for $rel" >&2; exit 33; }
  grep -q "^SHA256: $sha256$" "$packages_file" || { echo "Packages has wrong SHA256 for $rel" >&2; exit 23; }
  printf '%s\t%s\t%s\n' "$package" "$rel" "$sha256" >> "$hash_file"
  tar -tzf "$pkg_tmp/data.tar.gz" | sed 's#^\./##' | awk -v package="$package" 'NF { print package "\t/" $0 }' >> "$ownership_file"
done < <(find "$repo_dir/pool" -type f -name '*.deb' -print0 | sort -z)

for package in "${!package_depends[@]}"; do
  depends="${package_depends[$package]}"
  [[ -n "$depends" ]] || continue
  IFS=',' read -ra dep_parts <<< "$depends"
  for dep_part in "${dep_parts[@]}"; do
    dep="$(printf '%s\n' "$dep_part" | sed 's/^ *//; s/ *$//; s/ .*//')"
    [[ -n "$dep" ]] || continue
    [[ -n "${seen_packages[$dep]:-}" ]] || { echo "$package depends on missing package: $dep" >&2; exit 30; }
  done
done

duplicate_paths="$(awk -F'\t' '$2 !~ /\/$/ { print $2 }' "$ownership_file" | sort | uniq -d)"
if [[ -n "$duplicate_paths" ]]; then
  {
    echo "duplicate path ownership detected:"
    printf '%s\n' "$duplicate_paths"
  } >&2
  exit 31
fi

cat > "$summary_file" <<EOF
status=passed
repo=$repo_dir
packages_file=$packages_file
release_file=$release_file
package_count=${#seen_packages[@]}
ownership_file=$ownership_file
deps_file=$deps_file
hash_file=$hash_file
checks=release_suite,release_codename,release_architecture,release_hash_blocks,release_packages_hashes,packages_gz_matches_packages,package_source,package_architecture,package_section,package_priority,package_md5sums,packages_filename,packages_md5sum,packages_sha1,packages_sha256,dependencies_satisfied,no_duplicate_paths
EOF

echo "audit_summary=$summary_file"
echo "ownership=$ownership_file"
echo "dependencies=$deps_file"
echo "hashes=$hash_file"
