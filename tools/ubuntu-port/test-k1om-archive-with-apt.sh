#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-}"
out_dir="${2:-}"
if [[ -z "$repo_dir" || -z "$out_dir" || ! -d "$repo_dir" ]]; then
  echo "usage: $0 REPO_DIR OUT_DIR" >&2
  exit 2
fi

command -v apt-get >/dev/null 2>&1 || { echo "apt-get not found" >&2; exit 10; }

repo_dir="$(cd "$repo_dir" && pwd)"
repo_uri="${repo_dir// /%20}"
out_dir="$(mkdir -p "$out_dir" && cd "$out_dir" && pwd)"
apt_root="$out_dir/apt-root"
source_list="$apt_root/etc/apt/sources.list"
source_parts="$apt_root/etc/apt/sources.list.d"
trusted_parts="$apt_root/etc/apt/trusted.gpg.d"
state_lists="$apt_root/var/lib/apt/lists"
cache_archives="$apt_root/var/cache/apt/archives"
summary="$out_dir/apt-sandbox-summary.txt"

rm -rf "$apt_root"
mkdir -p "$source_parts" "$trusted_parts" "$state_lists/partial" "$cache_archives/partial" "$apt_root/etc/apt/preferences.d"

cat > "$source_list" <<EOF
deb [trusted=yes arch=k1om] file:$repo_uri noble main
EOF

apt_opts=(
  -o "APT::Architecture=k1om"
  -o "APT::Architectures::=k1om"
  -o "Dir=$apt_root"
  -o "Dir::Etc::sourcelist=$source_list"
  -o "Dir::Etc::sourceparts=$source_parts"
  -o "Dir::Etc::trustedparts=$trusted_parts"
  -o "Dir::State::lists=$state_lists"
  -o "Dir::Cache::archives=$cache_archives"
  -o "Acquire::Languages=none"
  -o "Acquire::AllowInsecureRepositories=true"
  -o "Acquire::AllowDowngradeToInsecureRepositories=true"
)

apt-get "${apt_opts[@]}" update > "$out_dir/apt-get-update.log" 2>&1

packages_list="$(find "$state_lists" -type f -name '*_binary-k1om_Packages' -print | head -n 1)"
[[ -n "$packages_list" ]] || { echo "APT did not create a binary-k1om Packages list" >&2; exit 20; }

for package in base-files-k1om hello-knc-smoke python3.5-minimal-k1om python3.5-stdlib-k1om python3.5-lib-dynload-k1om python3.5-smoke-k1om xpr-shell-compat xpr-busybox-compat xpr-pci-tools zlib-smoke-k1om libtinfo5-k1om ncurses-smoke-k1om xpr-os-smoke xeon-phi-revival-stage2; do
  grep -q "^Package: $package$" "$packages_list" || { echo "APT list missing package: $package" >&2; exit 30; }
done

apt-cache "${apt_opts[@]}" show base-files-k1om > "$out_dir/apt-cache-show-base-files-k1om.txt"
grep -q '^Architecture: k1om$' "$out_dir/apt-cache-show-base-files-k1om.txt" || { echo "apt-cache show did not preserve Architecture: k1om" >&2; exit 40; }

cat > "$summary" <<EOF
status=passed
repo=$repo_dir
apt_root=$apt_root
packages_list=$packages_list
checks=apt_get_update_file_repo,architecture_k1om,packages_visible,apt_cache_show
EOF

echo "apt_sandbox_summary=$summary"
