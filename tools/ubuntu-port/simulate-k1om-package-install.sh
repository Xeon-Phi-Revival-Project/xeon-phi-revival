#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-}"
out_dir="${2:-}"
if [[ -z "$repo_dir" || -z "$out_dir" || ! -d "$repo_dir" ]]; then
  echo "usage: $0 REPO_DIR OUT_DIR" >&2
  exit 2
fi

rootfs="$out_dir/rootfs"
dpkg_dir="$rootfs/var/lib/dpkg"
info_dir="$dpkg_dir/info"
status_file="$dpkg_dir/status"
summary_file="$out_dir/install-simulation-summary.txt"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

rm -rf "$out_dir"
mkdir -p "$rootfs" "$info_dir" "$(dirname "$status_file")"
: > "$status_file"

declare -A package_deb=()
declare -A package_depends=()
declare -A installed=()

while IFS= read -r -d '' deb; do
  control_tmp="$tmp_root/control-$(basename "$deb" .deb)"
  mkdir -p "$control_tmp"
  (cd "$control_tmp" && ar x "$deb" control.tar.gz)
  control="$(tar -xOzf "$control_tmp/control.tar.gz" ./control)"
  package="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Package" { print $2; exit }')"
  depends="$(printf '%s\n' "$control" | awk -F': ' '$1 == "Depends" { print $2; exit }')"
  [[ -n "$package" ]] || { echo "package without Package field: $deb" >&2; exit 10; }
  package_deb["$package"]="$deb"
  package_depends["$package"]="$depends"
done < <(find "$repo_dir/pool" -type f -name '*.deb' -print0 | sort -z)

dep_is_installed() {
  local dep="$1"
  [[ -n "${installed[$dep]:-}" ]]
}

deps_are_installed() {
  local package="$1"
  local depends="${package_depends[$package]}"
  [[ -n "$depends" ]] || return 0
  IFS=',' read -ra dep_parts <<< "$depends"
  for dep_part in "${dep_parts[@]}"; do
    dep="$(printf '%s\n' "$dep_part" | sed 's/^ *//; s/ *$//; s/ .*//')"
    [[ -z "$dep" ]] || dep_is_installed "$dep" || return 1
  done
  return 0
}

install_package() {
  local package="$1"
  local deb="${package_deb[$package]}"
  local pkg_tmp="$tmp_root/install-$package"
  mkdir -p "$pkg_tmp"
  (cd "$pkg_tmp" && ar x "$deb" control.tar.gz data.tar.gz)
  control="$(tar -xOzf "$pkg_tmp/control.tar.gz" ./control)"
  tar -tzf "$pkg_tmp/control.tar.gz" | grep -qx './md5sums' || { echo "$package missing md5sums" >&2; exit 21; }
  {
    printf '%s\n' "$control" | awk '{ print } /^Package:/ { print "Status: install ok installed" }'
    printf '\n'
  } >> "$status_file"
  tar -tzf "$pkg_tmp/data.tar.gz" | sed 's#^\./#/#' | sort > "$info_dir/$package.list"
  tar -xOzf "$pkg_tmp/control.tar.gz" ./md5sums > "$info_dir/$package.md5sums"
  if tar -tzf "$pkg_tmp/control.tar.gz" | grep -qx './conffiles'; then
    tar -xOzf "$pkg_tmp/control.tar.gz" ./conffiles > "$info_dir/$package.conffiles"
  fi
  tar -xzf "$pkg_tmp/data.tar.gz" -C "$rootfs"
  installed["$package"]=1
}

remaining=("${!package_deb[@]}")
while [[ ${#remaining[@]} -gt 0 ]]; do
  progressed=0
  declare -a next=()
  for package in "${remaining[@]}"; do
    if deps_are_installed "$package"; then
      install_package "$package"
      progressed=1
    else
      next+=("$package")
    fi
  done
  [[ "$progressed" -eq 1 ]] || {
    printf 'dependency cycle or missing package among: %s\n' "${remaining[*]}" >&2
    exit 20
  }
  [[ ${#next[@]} -gt 0 ]] || break
  remaining=("${next[@]}")
done

for required in \
  "$rootfs/etc/xeon-phi-revival-release" \
  "$rootfs/opt/xeon-phi-revival/profile.env" \
  "$rootfs/opt/xeon-phi-revival/bin/hello-knc" \
  "$rootfs/opt/xeon-phi-revival/bin/python3.5" \
  "$rootfs/opt/xeon-phi-revival/bin/python3" \
  "$rootfs/opt/xeon-phi-revival/bin/python" \
  "$rootfs/opt/xeon-phi-revival/lib/python3.5" \
  "$rootfs/opt/xeon-phi-revival/lib/python3.5/lib-dynload" \
  "$rootfs/opt/xeon-phi-revival/share/python-core-stage2.py" \
  "$rootfs/usr/bin/python3" \
  "$rootfs/usr/bin/python" \
  "$rootfs/etc/profile.d/xeon-phi-revival.sh" \
  "$rootfs/opt/xeon-phi-revival/bin/cat" \
  "$rootfs/opt/xeon-phi-revival/bin/grep" \
  "$rootfs/opt/xeon-phi-revival/bin/sed" \
  "$rootfs/opt/xeon-phi-revival/bin/awk" \
  "$rootfs/opt/xeon-phi-revival/bin/find" \
  "$rootfs/opt/xeon-phi-revival/bin/pcietool" \
  "$rootfs/usr/bin/pcietool" \
  "$rootfs/usr/bin/dpkg" \
  "$rootfs/usr/bin/dpkg-deb" \
  "$rootfs/usr/bin/apt-get" \
  "$rootfs/usr/bin/apt-cache" \
  "$rootfs/opt/xeon-phi-revival/bin/dpkg" \
  "$rootfs/opt/xeon-phi-revival/bin/dpkg-deb" \
  "$rootfs/opt/xeon-phi-revival/bin/apt-get" \
  "$rootfs/opt/xeon-phi-revival/bin/apt-cache" \
  "$rootfs/etc/apt/sources.list" \
  "$rootfs/var/lib/apt/lists/partial" \
  "$rootfs/var/cache/apt/archives/partial" \
  "$rootfs/opt/xeon-phi-revival/lib64/ld-linux-k1om.so.2" \
  "$rootfs/opt/xeon-phi-revival/lib64/libc.so.6" \
  "$rootfs/opt/xeon-phi-revival/lib64/libgcc_s.so.1" \
  "$rootfs/opt/xeon-phi-revival/lib64/libm.so.6" \
  "$rootfs/opt/xeon-phi-revival/lib64/libpthread.so.0" \
  "$rootfs/opt/xeon-phi-revival/lib64/libdl.so.2" \
  "$rootfs/opt/xeon-phi-revival/lib64/librt.so.1" \
  "$rootfs/opt/xeon-phi-revival/lib64/libutil.so.1" \
  "$rootfs/opt/xeon-phi-revival/bin/libc-stack-smoke.sh" \
  "$rootfs/usr/share/terminfo/l/linux" \
  "$rootfs/etc/terminfo/l/linux" \
  "$rootfs/opt/xeon-phi-revival/bin/zlib-smoke" \
  "$rootfs/opt/xeon-phi-revival/bin/ncurses-smoke" \
  "$rootfs/opt/xeon-phi-revival/lib64/libtinfo.so.5" \
  "$rootfs/opt/xeon-phi-revival/bin/os-smoke.sh" \
  "$rootfs/etc/init.d/xeon-phi-revival-stage2" \
  "$rootfs/etc/rc5.d/S78xeon-phi-revival-stage2" \
  "$status_file" \
  "$info_dir/base-files-k1om.conffiles" \
  "$info_dir/base-files-k1om.md5sums" \
  "$info_dir/hello-knc-smoke.md5sums" \
  "$info_dir/python3.5-minimal-k1om.md5sums" \
  "$info_dir/python3.5-stdlib-k1om.md5sums" \
  "$info_dir/python3.5-lib-dynload-k1om.md5sums" \
  "$info_dir/python3.5-smoke-k1om.md5sums" \
  "$info_dir/xpr-shell-compat.conffiles" \
  "$info_dir/xpr-shell-compat.md5sums" \
  "$info_dir/xpr-busybox-compat.md5sums" \
  "$info_dir/xpr-pci-tools.md5sums" \
  "$info_dir/dpkg-k1om.conffiles" \
  "$info_dir/dpkg-k1om.md5sums" \
  "$info_dir/apt-k1om.conffiles" \
  "$info_dir/apt-k1om.md5sums" \
  "$info_dir/libc6-k1om.md5sums" \
  "$info_dir/libgcc1-k1om.md5sums" \
  "$info_dir/libm6-k1om.md5sums" \
  "$info_dir/libpthread0-k1om.md5sums" \
  "$info_dir/libdl2-k1om.md5sums" \
  "$info_dir/librt1-k1om.md5sums" \
  "$info_dir/libutil1-k1om.md5sums" \
  "$info_dir/libc-stack-smoke-k1om.md5sums" \
  "$info_dir/ncurses-base-k1om.conffiles" \
  "$info_dir/ncurses-base-k1om.md5sums" \
  "$info_dir/zlib-smoke-k1om.md5sums" \
  "$info_dir/libtinfo5-k1om.md5sums" \
  "$info_dir/ncurses-smoke-k1om.md5sums" \
  "$info_dir/xpr-os-smoke.md5sums" \
  "$info_dir/xeon-phi-revival-stage2.conffiles" \
  "$info_dir/xeon-phi-revival-stage2.md5sums"; do
  [[ -e "$required" || -L "$required" ]] || { echo "missing simulated install output: $required" >&2; exit 30; }
done

if grep -q '^Package: zlib1g-k1om$' "$status_file"; then
  for required in \
    "$rootfs/opt/xeon-phi-revival/lib64/libz.so.1" \
    "$rootfs/opt/xeon-phi-revival/lib64/libz.so.1.2.6" \
    "$rootfs/opt/xeon-phi-revival/lib64/libncurses.so.5" \
    "$rootfs/opt/xeon-phi-revival/lib64/libncurses.so.5.9" \
    "$rootfs/opt/xeon-phi-revival/lib64/libreadline.so.6" \
    "$rootfs/opt/xeon-phi-revival/lib64/libreadline.so.6.2" \
    "$rootfs/opt/xeon-phi-revival/lib64/libssl.so.1.0.0" \
    "$rootfs/opt/xeon-phi-revival/lib64/libcrypto.so.1.0.0" \
    "$rootfs/opt/xeon-phi-revival/bin/runtime-libs-smoke.sh" \
    "$info_dir/zlib1g-k1om.md5sums" \
    "$info_dir/libncurses5-k1om.md5sums" \
    "$info_dir/libreadline6-k1om.md5sums" \
    "$info_dir/libssl1.0.0-k1om.md5sums" \
    "$info_dir/libcrypto1.0.0-k1om.md5sums" \
    "$info_dir/xpr-runtime-libs-smoke.md5sums"; do
    [[ -e "$required" || -L "$required" ]] || { echo "missing simulated runtime-library output: $required" >&2; exit 31; }
  done
fi

if grep -q '^Package: python3.12-minimal-k1om$' "$status_file"; then
  for required in \
    "$rootfs/opt/xeon-phi-revival/bin/python3.12" \
    "$rootfs/usr/bin/python3.12" \
    "$rootfs/opt/xeon-phi-revival/lib/python3.12/encodings" \
    "$rootfs/opt/xeon-phi-revival/lib/python3.12/importlib" \
    "$rootfs/opt/xeon-phi-revival/lib/python3.12/json" \
    "$rootfs/opt/xeon-phi-revival/lib/python3.12/asyncio" \
    "$rootfs/opt/xeon-phi-revival/lib/python3.12/xml" \
    "$rootfs/opt/xeon-phi-revival/lib/python3.12/zoneinfo" \
    "$rootfs/opt/xeon-phi-revival/lib/python3.12/_sysconfigdata__linux_x86_64-linux-gnu.py" \
    "$rootfs/opt/xeon-phi-revival/share/python312-smoke.py" \
    "$rootfs/opt/xeon-phi-revival/bin/python312-smoke.sh" \
    "$info_dir/python3.12-minimal-k1om.md5sums" \
    "$info_dir/python3.12-stdlib-k1om.md5sums" \
    "$info_dir/python3.12-sysconfig-k1om.md5sums" \
    "$info_dir/python3.12-smoke-k1om.md5sums"; do
    [[ -e "$required" || -L "$required" ]] || { echo "missing simulated python3.12 output: $required" >&2; exit 32; }
  done
fi

cat > "$summary_file" <<EOF
status=passed
repo=$repo_dir
rootfs=$rootfs
dpkg_status=$status_file
package_count=${#installed[@]}
info_dir=$info_dir
checks=dependency_order,extract_payloads,dpkg_status,package_file_lists,package_md5sums,package_conffiles,required_bootstrap_paths,dpkg_deb_entrypoint
EOF

echo "install_simulation_summary=$summary_file"
echo "simulated_rootfs=$rootfs"
echo "dpkg_status=$status_file"
