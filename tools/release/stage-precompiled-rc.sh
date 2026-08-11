#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: stage-precompiled-rc.sh \
  --kernel FILE --system-map FILE --modules-dir DIR \
  --bootstrap FILE --payload FILE \
  --kernel-source FILE --module-source FILE --out-dir DIR \
  --busybox-source FILE --dropbear-source FILE \
  --eglibc-orig FILE --eglibc-debian FILE \
  --gcc-source FILE --gmp-source FILE --mpfr-source FILE --mpc-source FILE \
  [--repository-archive FILE] \
  [--version 0.1.0-rc4] [--revision REV]

Build deterministic private review archives from the exact hardware-tested
XPR-OS artifacts and pinned corresponding-source inputs. This command stages
artifacts for human review; it does not publish or create a Git tag/release.
USAGE
}

version="0.1.0-rc4"
revision="HEAD"
source_date_epoch="${SOURCE_DATE_EPOCH:-1786320000}"
kernel="" system_map="" modules_dir="" bootstrap="" payload=""
kernel_source="" module_source="" repository_archive="" out_dir=""
busybox_source="" dropbear_source="" eglibc_orig="" eglibc_debian=""
gcc_source="" gmp_source="" mpfr_source="" mpc_source=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel) kernel="${2:-}"; shift 2 ;;
    --system-map) system_map="${2:-}"; shift 2 ;;
    --modules-dir) modules_dir="${2:-}"; shift 2 ;;
    --bootstrap) bootstrap="${2:-}"; shift 2 ;;
    --payload) payload="${2:-}"; shift 2 ;;
    --kernel-source) kernel_source="${2:-}"; shift 2 ;;
    --module-source) module_source="${2:-}"; shift 2 ;;
    --busybox-source) busybox_source="${2:-}"; shift 2 ;;
    --dropbear-source) dropbear_source="${2:-}"; shift 2 ;;
    --eglibc-orig) eglibc_orig="${2:-}"; shift 2 ;;
    --eglibc-debian) eglibc_debian="${2:-}"; shift 2 ;;
    --gcc-source) gcc_source="${2:-}"; shift 2 ;;
    --gmp-source) gmp_source="${2:-}"; shift 2 ;;
    --mpfr-source) mpfr_source="${2:-}"; shift 2 ;;
    --mpc-source) mpc_source="${2:-}"; shift 2 ;;
    --repository-archive) repository_archive="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --version) version="${2:-}"; shift 2 ;;
    --revision) revision="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

for value in kernel system_map modules_dir bootstrap payload kernel_source module_source \
  busybox_source dropbear_source eglibc_orig eglibc_debian gcc_source \
  gmp_source mpfr_source mpc_source out_dir; do
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
  [kernel_source]=0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59
  [module_source]=0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54
  [busybox_source]=9b853406da61ffb59eb488495fe99cbb7fb3dd29a31307fcfa9cf070543710ee
  [dropbear_source]=bc5a121ffbc94b5171ad5ebe01be42746d50aa797c9549a4639894a16749443b
  [eglibc_orig]=e5d30be72b702dffae527779af1be755f0dfbf13c171998a04f7265cd4da131f
  [eglibc_debian]=2e0a1d4dfbc8bb666604d6804b9fbd9ce7a1f23b2a5bcb487f5a774d2c557e4c
  [gcc_source]=6538edbd3c309eb7c37bb215c40ef9822c7c015928ff354267eac2178cf5f1e3
  [gmp_source]=936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775
  [mpfr_source]=c7e75a08a8d49d2082e4caee1591a05d11b9d5627514e678f02d66a124bcf2ba
  [mpc_source]=e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4
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
verify_hash kernel_source "$kernel_source"
verify_hash module_source "$module_source"
verify_hash busybox_source "$busybox_source"
verify_hash dropbear_source "$dropbear_source"
verify_hash eglibc_orig "$eglibc_orig"
verify_hash eglibc_debian "$eglibc_debian"
verify_hash gcc_source "$gcc_source"
verify_hash gmp_source "$gmp_source"
verify_hash mpfr_source "$mpfr_source"
verify_hash mpc_source "$mpc_source"
for module in dma_module ringbuffer micscif mpssboot intel_micveth; do
  verify_hash "$module" "$modules_dir/$module.ko"
done

payload_hash="$(sha256sum "$payload" | awk '{print $1}')"

bash tools/release/audit-source-compliance.sh
"$python_bin" tools/release/audit-prebuilt-image.py \
  --cpio "$payload" \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --stage candidate \
  --output /tmp/xpr-prebuilt-audit.json
"$python_bin" tools/release/verify-generic-payload.py --payload "$payload"
SOURCE_DATE_EPOCH="$source_date_epoch" "$python_bin" tools/release/generate-spdx-sbom.py \
  --audit /tmp/xpr-prebuilt-audit.json \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --include-component linux-k1om \
  --include-component mpss-compatible-modules \
  --external-file "linux-k1om:./kernel/bzImage=${expected[kernel]}" \
  --external-file "linux-k1om:./kernel/System.map=${expected[system_map]}" \
  --external-file "mpss-compatible-modules:./modules/dma_module.ko=${expected[dma_module]}" \
  --external-file "mpss-compatible-modules:./modules/ringbuffer.ko=${expected[ringbuffer]}" \
  --external-file "mpss-compatible-modules:./modules/micscif.ko=${expected[micscif]}" \
  --external-file "mpss-compatible-modules:./modules/mpssboot.ko=${expected[mpssboot]}" \
  --external-file "mpss-compatible-modules:./modules/intel_micveth.ko=${expected[intel_micveth]}" \
  --output /tmp/xpr-prebuilt.spdx.json
"$python_bin" tools/release/validate-spdx-2.3.py --input /tmp/xpr-prebuilt.spdx.json
"$python_bin" tools/release/audit-prebuilt-image.py \
  --cpio "$payload" \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --stage candidate \
  --sbom /tmp/xpr-prebuilt.spdx.json \
  --output /tmp/xpr-prebuilt-audit.json

out_dir="$(mkdir -p "$out_dir" && cd "$out_dir" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/xpr-rc4.XXXXXX")"
trap 'rm -rf "$work" /tmp/xpr-prebuilt-audit.json /tmp/xpr-prebuilt.spdx.json' EXIT
binary_root="$work/xpr-os-$version"
source_root="$work/xpr-os-$version-sources"
mkdir -p "$binary_root"/{kernel,modules,bootstrap,payload,tools,docs,manifests,LICENSES} \
         "$source_root"/{sources,repository,manifests}

install -m 0644 "$kernel" "$binary_root/kernel/bzImage"
install -m 0644 "$system_map" "$binary_root/kernel/System.map"
for module in dma_module ringbuffer micscif mpssboot intel_micveth; do
  install -m 0644 "$modules_dir/$module.ko" "$binary_root/modules/$module.ko"
done
install -m 0644 "$bootstrap" "$binary_root/bootstrap/xpr-bootstrap.cpio.gz"
install -m 0644 "$payload" "$binary_root/payload/xpr-rootfs.cpio.gz"
install -m 0755 tools/release/verify-precompiled-rc.sh "$binary_root/tools/verify.sh"
install -m 0755 tools/release/verify-generic-payload.py "$binary_root/tools/verify-generic-payload.py"
install -m 0755 tools/release/provision-xpr-authorized-key.py "$binary_root/tools/provision-authorized-key.py"
install -m 0755 tools/release/validate-spdx-2.3.py "$binary_root/tools/validate-spdx-2.3.py"
install -m 0755 tools/release/validate-license-bundle.py "$binary_root/tools/validate-license-bundle.py"
install -m 0644 LICENSE NOTICE.md "$binary_root/"
install -m 0644 "docs/release/xpr-os-$version-release-notes.md" "$binary_root/README.md"
install -m 0644 docs/release/public-clean-stack-validation.md "$binary_root/docs/"
install -m 0644 docs/release/distribution-review.md "$binary_root/docs/"
install -m 0644 manifests/release/xpr-os-0.1.0-rc1-tested-artifacts.json "$binary_root/manifests/tested-artifacts.json"
install -m 0644 "manifests/release/xpr-os-$version.yml" "$binary_root/manifests/release.yml"
install -m 0644 manifests/release/prebuilt-clean-profile.json "$binary_root/manifests/"
install -m 0644 manifests/release/third-party-notices.json "$binary_root/manifests/"
install -m 0644 /tmp/xpr-prebuilt.spdx.json "$binary_root/manifests/xpr-os.spdx.json"
install -m 0644 "$kernel_source" "$work/kernel-source.tar.gz"
kernel_license_member="$(tar -tzf "$work/kernel-source.tar.gz" | awk '/\/phi-kernel\/COPYING$/ { print; exit }')"
[[ -n "$kernel_license_member" ]] || { echo "kernel COPYING missing" >&2; exit 23; }
tar -xOzf "$work/kernel-source.tar.gz" "$kernel_license_member" > "$binary_root/LICENSES/GPL-2.0-only.txt"
tar -xOjf "$module_source" "$(tar -tjf "$module_source" | awk '/(^|\/)COPYING$/ { print; exit }')" > "$binary_root/LICENSES/MPSS-modules-GPL-2.0-only.txt"
tar -xOjf "$busybox_source" "$(tar -tjf "$busybox_source" | awk '/(^|\/)LICENSE$/ { print; exit }')" > "$binary_root/LICENSES/BusyBox-1.19.4-GPL-2.0-only.txt"
tar -xOJf "$eglibc_orig" "$(tar -tJf "$eglibc_orig" | awk '/(^|\/)COPYING\.LIB$/ { print; exit }')" > "$binary_root/LICENSES/LGPL-2.1-or-later.txt"
tar -xOzf "$gcc_source" "$(tar -tzf "$gcc_source" | awk '/(^|\/)COPYING3$/ { print; exit }')" > "$binary_root/LICENSES/GPL-3.0-only.txt"
tar -xOzf "$gcc_source" "$(tar -tzf "$gcc_source" | awk '/(^|\/)COPYING.RUNTIME$/ { print; exit }')" > "$binary_root/LICENSES/GCC-Runtime-Library-Exception-3.1.txt"
tar -xOjf "$dropbear_source" "$(tar -tjf "$dropbear_source" | awk '/(^|\/)LICENSE$/ { print; exit }')" > "$binary_root/LICENSES/Dropbear-2022.83-LICENSE.txt"
install -m 0644 LICENSE "$binary_root/LICENSES/XPR-MIT.txt"
printf '%s\n' "$version" > "$binary_root/VERSION"
printf 'git_commit=%s\nsource_date_epoch=%s\npublication_status=HUMAN_LEGAL_REVIEW_PENDING\n' \
  "$commit" "$source_date_epoch" > "$binary_root/build-report.txt"
printf 'payload_sha256=%s\n' "$payload_hash" >> "$binary_root/build-report.txt"

install -m 0644 "$kernel_source" "$source_root/sources/solros-bda6ce.tar.gz"
install -m 0644 "$module_source" "$source_root/sources/mpss-modules-3.4.10.tar.bz2"
install -m 0644 "$busybox_source" "$source_root/sources/busybox-1.19.4.tar.bz2"
install -m 0644 "$dropbear_source" "$source_root/sources/dropbear-2022.83.tar.bz2"
install -m 0644 "$eglibc_orig" "$source_root/sources/eglibc_2.19.orig.tar.xz"
install -m 0644 "$eglibc_debian" "$source_root/sources/eglibc_2.19-0ubuntu6.15.debian.tar.xz"
install -m 0644 "$gcc_source" "$source_root/sources/gcc-5.1.1-knc-af7cc04.tar.gz"
install -m 0644 "$gmp_source" "$source_root/sources/gmp-4.3.2.tar.bz2"
install -m 0644 "$mpfr_source" "$source_root/sources/mpfr-2.4.2.tar.bz2"
install -m 0644 "$mpc_source" "$source_root/sources/mpc-0.8.1.tar.gz"
if $have_git; then
  git -c core.autocrlf=false archive --format=tar --prefix="repository/" -o "$work/repository.tar" "$commit"
else
  cp "$repository_archive" "$work/repository.tar"
  first_member="$(tar -tf "$work/repository.tar" | sed -n '1p')"
  [[ "$first_member" == repository/* ]] || {
    echo "repository archive must use a repository/ prefix" >&2
    exit 22
  }
fi
tar -xf "$work/repository.tar" -C "$source_root"
"$python_bin" tools/release/validate-release-source-integrity.py \
  --root "$source_root/repository" \
  --config configs/kernel/k1om-solros-tested.config=20f240d00b033c1a0e14ffc8d2023533552adc4040ac0deff3404c79f1f12479 \
  --config configs/busybox/k1om-1.19.4.config=15e366d935d4171070590039b1085e5818954e78fd8c00a39bffa9b88c6191df
install -m 0644 manifests/release/k1om-tested-kernel-reproduction.json "$source_root/manifests/"
install -m 0644 manifests/release/mpss-modules-3.4.10-source-map.json "$source_root/manifests/"
install -m 0644 manifests/release/mpss-modules-3.4.10-clean-dependencies.json "$source_root/manifests/"
install -m 0644 /tmp/xpr-prebuilt.spdx.json "$source_root/manifests/xpr-os.spdx.json"

(cd "$source_root" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)

source_archive="$out_dir/xpr-os-$version-sources.tar.gz"
"$python_bin" tools/release/create-deterministic-tar.py \
  --root "$source_root" --output "$work/source.tar" --mtime "$source_date_epoch"
gzip -n -9 -c "$work/source.tar" > "$source_archive"
source_hash="$(sha256sum "$source_archive" | awk '{print $1}')"
printf 'source_archive=xpr-os-%s-sources.tar.gz\nsource_archive_sha256=%s\n' "$version" "$source_hash" > "$binary_root/SOURCE-BUNDLE.txt"
(cd "$binary_root" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
"$python_bin" tools/release/validate-license-bundle.py --root "$binary_root"
binary_archive="$out_dir/xpr-os-$version.tar.gz"
"$python_bin" tools/release/create-deterministic-tar.py \
  --root "$binary_root" --output "$work/binary.tar" --mtime "$source_date_epoch"
gzip -n -9 -c "$work/binary.tar" > "$binary_archive"

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
