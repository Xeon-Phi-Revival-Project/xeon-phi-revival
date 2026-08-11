#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: stage-precompiled-rc.sh \
  --kernel FILE --system-map FILE --modules-dir DIR \
  --bootstrap FILE --payload FILE \
  --kernel-source FILE --module-source FILE --out-dir DIR \
  [--repository-archive FILE] \
  [--version 0.1.0-rc3] [--revision REV]

Build deterministic private review archives from the exact hardware-tested
XPR-OS artifacts and pinned corresponding-source inputs. This command stages
artifacts for human review; it does not publish or create a Git tag/release.
USAGE
}

version="0.1.0-rc3"
revision="HEAD"
source_date_epoch="${SOURCE_DATE_EPOCH:-1786320000}"
kernel="" system_map="" modules_dir="" bootstrap="" payload=""
kernel_source="" module_source="" repository_archive="" out_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel) kernel="${2:-}"; shift 2 ;;
    --system-map) system_map="${2:-}"; shift 2 ;;
    --modules-dir) modules_dir="${2:-}"; shift 2 ;;
    --bootstrap) bootstrap="${2:-}"; shift 2 ;;
    --payload) payload="${2:-}"; shift 2 ;;
    --kernel-source) kernel_source="${2:-}"; shift 2 ;;
    --module-source) module_source="${2:-}"; shift 2 ;;
    --repository-archive) repository_archive="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --version) version="${2:-}"; shift 2 ;;
    --revision) revision="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

for value in kernel system_map modules_dir bootstrap payload kernel_source module_source out_dir; do
  [[ -n "${!value}" ]] || { echo "missing --${value//_/-}" >&2; usage; exit 2; }
done
for cmd in tar gzip sha256sum find sort xargs install cp awk grep sed mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required host tool missing: $cmd" >&2; exit 10; }
done
if command -v python3 >/dev/null 2>&1; then
  python_bin=python3
elif command -v python >/dev/null 2>&1; then
  python_bin=python
else
  echo "required Python interpreter missing" >&2
  exit 10
fi

script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
have_git=false
if command -v git >/dev/null 2>&1 && git -C "$script_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  have_git=true
  repo_root="$(git -C "$script_root" rev-parse --show-toplevel)"
else
  repo_root="$script_root"
fi
cd "$repo_root"
if $have_git; then
  git cat-file -e "$revision^{commit}"
  commit="$(git rev-parse "$revision^{commit}")"
  if [[ "$revision" == HEAD ]] && { ! git diff --quiet || ! git diff --cached --quiet; }; then
    echo "refusing to stage from a dirty tracked worktree" >&2
    exit 11
  fi
else
  [[ "$revision" =~ ^[0-9a-f]{40}$ ]] || {
    echo "a full 40-character --revision is required without Git" >&2
    exit 11
  }
  [[ -f "$repository_archive" ]] || {
    echo "--repository-archive is required without Git" >&2
    exit 11
  }
  commit="$revision"
fi

declare -A expected=(
  [kernel]=d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8
  [system_map]=631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6
  [bootstrap]=bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779
  [payload]=e5c25217a5b9a2c60f7caaefce3651dd086b6f0f0d51e88883aa3e9486c7fee7
  [kernel_source]=0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59
  [module_source]=0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54
  [dma_module]=af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a
  [ringbuffer]=e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068
  [micscif]=0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2
  [mpssboot]=a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894
  [intel_micveth]=0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60
)

verify_hash() {
  local id="$1" file="$2" actual
  [[ -f "$file" ]] || { echo "$id input missing: $file" >&2; exit 20; }
  actual="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$actual" == "${expected[$id]}" ]] || {
    echo "$id hash mismatch: expected ${expected[$id]}, got $actual" >&2
    exit 21
  }
}

verify_hash kernel "$kernel"
verify_hash system_map "$system_map"
verify_hash bootstrap "$bootstrap"
verify_hash payload "$payload"
verify_hash kernel_source "$kernel_source"
verify_hash module_source "$module_source"
for module in dma_module ringbuffer micscif mpssboot intel_micveth; do
  verify_hash "$module" "$modules_dir/$module.ko"
done

bash tools/release/audit-source-compliance.sh
"$python_bin" tools/release/audit-prebuilt-image.py \
  --cpio "$payload" \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --stage candidate \
  --output /tmp/xpr-prebuilt-audit.json

out_dir="$(mkdir -p "$out_dir" && cd "$out_dir" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/xpr-rc3.XXXXXX")"
trap 'rm -rf "$work" /tmp/xpr-prebuilt-audit.json' EXIT
binary_root="$work/xpr-os-$version"
source_root="$work/xpr-os-$version-sources"
mkdir -p "$binary_root"/{kernel,modules,bootstrap,payload,tools,docs,manifests} \
         "$source_root"/{sources,repository,manifests}

install -m 0644 "$kernel" "$binary_root/kernel/bzImage"
install -m 0644 "$system_map" "$binary_root/kernel/System.map"
for module in dma_module ringbuffer micscif mpssboot intel_micveth; do
  install -m 0644 "$modules_dir/$module.ko" "$binary_root/modules/$module.ko"
done
install -m 0644 "$bootstrap" "$binary_root/bootstrap/xpr-bootstrap.cpio.gz"
install -m 0644 "$payload" "$binary_root/payload/xpr-rootfs.cpio.gz"
install -m 0755 tools/release/verify-precompiled-rc.sh "$binary_root/tools/verify.sh"
install -m 0644 LICENSE NOTICE.md "$binary_root/"
install -m 0644 docs/release/xpr-os-0.1.0-rc3-release-notes.md "$binary_root/README.md"
install -m 0644 docs/release/public-clean-stack-validation.md "$binary_root/docs/"
install -m 0644 docs/release/distribution-review.md "$binary_root/docs/"
install -m 0644 manifests/release/xpr-os-0.1.0-rc1-tested-artifacts.json "$binary_root/manifests/tested-artifacts.json"
install -m 0644 manifests/release/xpr-os-0.1.0-rc3.yml "$binary_root/manifests/release.yml"
printf '%s\n' "$version" > "$binary_root/VERSION"
printf 'git_commit=%s\nsource_date_epoch=%s\npublication_status=HUMAN_LEGAL_REVIEW_PENDING\n' \
  "$commit" "$source_date_epoch" > "$binary_root/build-report.txt"

install -m 0644 "$kernel_source" "$source_root/sources/solros-bda6ce.tar.gz"
install -m 0644 "$module_source" "$source_root/sources/mpss-modules-3.4.10.tar.bz2"
if $have_git; then
  git archive --format=tar --prefix="repository/" -o "$work/repository.tar" "$commit"
else
  cp "$repository_archive" "$work/repository.tar"
  first_member="$(tar -tf "$work/repository.tar" | sed -n '1p')"
  [[ "$first_member" == repository/* ]] || {
    echo "repository archive must use a repository/ prefix" >&2
    exit 22
  }
fi
tar -xf "$work/repository.tar" -C "$source_root"
install -m 0644 manifests/release/k1om-tested-kernel-reproduction.json "$source_root/manifests/"
install -m 0644 manifests/release/mpss-modules-3.4.10-source-map.json "$source_root/manifests/"
install -m 0644 manifests/release/mpss-modules-3.4.10-clean-dependencies.json "$source_root/manifests/"

(cd "$binary_root" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
(cd "$source_root" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)

binary_archive="$out_dir/xpr-os-$version.tar.gz"
source_archive="$out_dir/xpr-os-$version-sources.tar.gz"
tar --sort=name --mtime="@$source_date_epoch" --owner=0 --group=0 --numeric-owner -C "$work" -cf - "xpr-os-$version" | gzip -n -9 > "$binary_archive"
tar --sort=name --mtime="@$source_date_epoch" --owner=0 --group=0 --numeric-owner -C "$work" -cf - "xpr-os-$version-sources" | gzip -n -9 > "$source_archive"

bash tools/release/verify-precompiled-rc.sh \
  --archive "$binary_archive" --version "$version" --expected-commit "$commit"
(cd "$out_dir" && sha256sum "$(basename "$binary_archive")" "$(basename "$source_archive")" > SHA256SUMS)
(cd "$out_dir" && sha256sum -c SHA256SUMS)

cat <<EOF
status=STAGED_HUMAN_LEGAL_REVIEW_PENDING
binary_archive=$binary_archive
source_archive=$source_archive
checksums=$out_dir/SHA256SUMS
commit=$commit
EOF
