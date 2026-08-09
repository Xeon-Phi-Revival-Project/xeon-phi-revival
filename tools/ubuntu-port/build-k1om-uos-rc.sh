#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-k1om-uos-rc.sh --payload-rootfs DIR --libc-root DIR --runtime-root DIR --python312-root DIR --libffi-root DIR --stock-rootfs DIR [--sysroot DIR] [--out-root DIR] [--version V]

Build a private Xeon Phi Revival K1OM uOS release-candidate artifact set from
locally supplied MPSS/K1OM inputs. The generated rootfs and archive are private
unless redistribution review proves every payload inside can be redistributed.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
payload_rootfs=""
libc_root=""
runtime_root=""
python312_root=""
libffi_root=""
sysroot="${K1OM_SYSROOT:-/opt/mpss/3.4.10/sysroots/k1om-mpss-linux}"
stock_rootfs=""
out_root="/root/xeon-phi-revival-local/uos-rc-builds"
version="0.1.0"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --libc-root) libc_root="${2:-}"; shift 2 ;;
    --runtime-root) runtime_root="${2:-}"; shift 2 ;;
    --python312-root) python312_root="${2:-}"; shift 2 ;;
    --libffi-root) libffi_root="${2:-}"; shift 2 ;;
    --sysroot) sysroot="${2:-}"; shift 2 ;;
    --stock-rootfs) stock_rootfs="${2:-}"; shift 2 ;;
    --out-root) out_root="${2:-}"; shift 2 ;;
    --version) version="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

require_dir() {
  local label="$1" path="$2"
  [[ -n "$path" && -d "$path" ]] || { echo "$label missing or not a directory: $path" >&2; exit 10; }
}

require_file() {
  local label="$1" path="$2"
  [[ -e "$path" || -L "$path" ]] || { echo "$label missing: $path" >&2; exit 11; }
}

for cmd in bash tar gzip sha256sum find sort awk sed ar cp mkdir rm chmod ln du stat; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required host tool missing: $cmd" >&2; exit 12; }
done

require_dir "payload rootfs" "$payload_rootfs"
require_dir "eglibc root" "$libc_root"
require_dir "runtime root" "$runtime_root"
require_dir "Python 3.12 root" "$python312_root"
require_dir "libffi root" "$libffi_root"
require_dir "stock rootfs" "$stock_rootfs"
require_dir "K1OM sysroot" "$sysroot"
require_file "stock BusyBox" "$stock_rootfs/bin/busybox"

require_file "K1OM SDK libgcc" "$sysroot/lib64/libgcc_s.so.1"
if [[ -e "$libc_root/lib64/ld-linux-k1om.so.2" || -L "$libc_root/lib64/ld-linux-k1om.so.2" ]]; then
  libc_libdir="$libc_root/lib64"
elif [[ -e "$libc_root/lib/ld-linux-k1om.so.2" || -L "$libc_root/lib/ld-linux-k1om.so.2" ]]; then
  libc_libdir="$libc_root/lib"
else
  echo "eglibc root does not contain ld-linux-k1om.so.2 under lib64 or lib: $libc_root" >&2
  exit 14
fi
for lib in ld-linux-k1om.so.2 libc.so.6 libpthread.so.0 libm.so.6 libdl.so.2 librt.so.1 libutil.so.1; do
  require_file "eglibc runtime $lib" "$libc_libdir/$lib"
done

run_dir="$out_root/xpr-uos-rc-$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$run_dir"
exec > >(tee "$run_dir/build.log") 2>&1

echo "== Xeon Phi Revival K1OM uOS RC build =="
date -u
echo "run_dir=$run_dir"
echo "source_date_epoch=$source_date_epoch"

bash "$script_dir/build-k1om-bootstrap-packages.sh" \
  --payload-rootfs "$payload_rootfs" \
  --sysroot "$sysroot" \
  --libc-root "$libc_root" \
  --runtime-root "$runtime_root" \
  --python312-root "$python312_root" \
  --libffi-root "$libffi_root" \
  --version "$version" \
  --out-dir "$run_dir/packages"

K1OM_LIBC_ROOT="$libc_root" bash "$script_dir/check-k1om-package-determinism.sh" \
  "$script_dir" "$payload_rootfs" "$run_dir/determinism" "$runtime_root" "$python312_root" "$libffi_root"
bash "$script_dir/index-k1om-local-archive.sh" "$run_dir/packages/repo"
bash "$script_dir/audit-k1om-package-set.sh" "$run_dir/packages/repo" "$run_dir/audit"
bash "$script_dir/simulate-k1om-package-install.sh" "$run_dir/packages/repo" "$run_dir/simulated-install"

bash "$script_dir/build-k1om-minimal-ubuntu-rootfs.sh" \
  --package-rootfs "$run_dir/simulated-install/rootfs" \
  --package-repo "$run_dir/packages/repo" \
  --stock-rootfs "$stock_rootfs" \
  --out-dir "$run_dir/rootfs"
bash "$script_dir/validate-k1om-minimal-ubuntu-rootfs.sh" "$run_dir/rootfs/rootfs"

archive="$run_dir/xpr-uos-0.1-k1om-rootfs.tar.gz"
(cd "$run_dir/rootfs/rootfs" && find . -print0 | sort -z | tar --null --no-recursion --numeric-owner --owner=0 --group=0 --mtime="@$source_date_epoch" -T - -czf "$archive")
sha256sum "$archive" > "$archive.sha256"

{
  echo "artifact	path	sha256	classification	redistribution"
  while IFS= read -r -d '' file; do
    rel="${file#"$run_dir/"}"
    sha="$(sha256sum "$file" | awk '{print $1}')"
    case "$rel" in
      packages/repo/pool/*|rootfs/rootfs/*|*.tar.gz)
        class="generated-private-payload"
        redist="review-required"
        ;;
      *)
        class="public-safe-metadata"
        redist="redistributable"
        ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\n' "$(basename "$file")" "$rel" "$sha" "$class" "$redist"
  done < <(find "$run_dir" -type f -print0 | sort -z)
} > "$run_dir/artifact-manifest.tsv"

cat > "$run_dir/release-candidate.yml" <<EOF
id: xpr-uos-0.1-k1om-rc
status: built-private
architecture: k1om
identity: xpr-uos
derived_from: Ubuntu 24.04 Noble source/package metadata
run_dir: $run_dir
rootfs: $run_dir/rootfs/rootfs
rootfs_archive: $archive
rootfs_archive_sha256: $(awk '{print $1}' "$archive.sha256")
package_repo: $run_dir/packages/repo
package_count: $(find "$run_dir/packages/repo/pool" -type f -name '*.deb' | wc -l)
artifact_manifest: $run_dir/artifact-manifest.tsv
redistribution: review-required-before-public-binary-release
locally_supplied_inputs:
  payload_rootfs: $payload_rootfs
  sysroot: $sysroot
  libc_root: $libc_root
  runtime_root: $runtime_root
  python312_root: $python312_root
  libffi_root: $libffi_root
EOF

cat > "$run_dir/build-summary.txt" <<EOF
status=built
run_dir=$run_dir
rootfs=$run_dir/rootfs/rootfs
rootfs_archive=$archive
rootfs_archive_sha256=$(awk '{print $1}' "$archive.sha256")
package_repo=$run_dir/packages/repo
artifact_manifest=$run_dir/artifact-manifest.tsv
release_candidate_manifest=$run_dir/release-candidate.yml
note=Do not publish generated binaries/rootfs until redistribution review is complete.
EOF

cat "$run_dir/build-summary.txt"
