#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: verify-precompiled-rc.sh --archive FILE --version VERSION [--expected-commit SHA]" >&2
}

archive="" version="" expected_commit=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive) archive="${2:-}"; shift 2 ;;
    --version) version="${2:-}"; shift 2 ;;
    --expected-commit) expected_commit="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done
[[ -f "$archive" && -n "$version" ]] || { usage; exit 2; }
for cmd in tar gzip sha256sum grep find mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required tool missing: $cmd" >&2; exit 10; }
done

tmp="$(mktemp -d "${TMPDIR:-/tmp}/xpr-verify.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
gzip -t "$archive"
tar -xzf "$archive" -C "$tmp"
root="$tmp/xpr-os-$version"
[[ -d "$root" ]] || { echo "release root missing" >&2; exit 20; }

required=(
  VERSION LICENSE NOTICE.md SHA256SUMS README.md build-report.txt
  kernel/bzImage kernel/System.map
  modules/dma_module.ko modules/ringbuffer.ko modules/micscif.ko
  modules/mpssboot.ko modules/intel_micveth.ko
  bootstrap/xpr-bootstrap.cpio.gz payload/xpr-rootfs.cpio.gz
  tools/verify.sh tools/verify-generic-payload.py tools/provision-authorized-key.py
  tools/validate-spdx-2.3.py tools/validate-license-bundle.py tools/uos/newc_archive.py
  manifests/tested-artifacts.json manifests/release.yml manifests/prebuilt-clean-profile.json
  manifests/third-party-notices.json manifests/xpr-os.spdx.json SOURCE-BUNDLE.txt
  LICENSES/GPL-2.0-only.txt LICENSES/LGPL-2.1-or-later.txt
  LICENSES/GPL-3.0-only.txt LICENSES/GCC-Runtime-Library-Exception-3.1.txt
  LICENSES/Dropbear-2022.83-LICENSE.txt LICENSES/BusyBox-1.19.4-GPL-2.0-only.txt
  LICENSES/MPSS-modules-GPL-2.0-only.txt LICENSES/XPR-MIT.txt
)
for path in "${required[@]}"; do
  [[ -e "$root/$path" ]] || { echo "required release member missing: $path" >&2; exit 21; }
done
[[ "$(cat "$root/VERSION")" == "$version" ]] || { echo "VERSION mismatch" >&2; exit 22; }
python_bin=""
if command -v python3 >/dev/null 2>&1; then python_bin=python3; elif command -v python >/dev/null 2>&1; then python_bin=python; else echo "Python missing" >&2; exit 10; fi
"$python_bin" "$root/tools/validate-spdx-2.3.py" --input "$root/manifests/xpr-os.spdx.json"
"$python_bin" "$root/tools/validate-license-bundle.py" --root "$root"
"$python_bin" "$root/tools/verify-generic-payload.py" --payload "$root/payload/xpr-rootfs.cpio.gz"
(cd "$root" && sha256sum -c SHA256SUMS)

declare -A expected=(
  [kernel/bzImage]=d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8
  [kernel/System.map]=631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6
  [bootstrap/xpr-bootstrap.cpio.gz]=bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779
  [modules/dma_module.ko]=af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a
  [modules/ringbuffer.ko]=e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068
  [modules/micscif.ko]=0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2
  [modules/mpssboot.ko]=a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894
  [modules/intel_micveth.ko]=0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60
)
for path in "${!expected[@]}"; do
  printf '%s  %s\n' "${expected[$path]}" "$root/$path" | sha256sum -c -
done

grep -Eq '^source_archive=xpr-os-[0-9][^[:space:]]*-sources\.tar\.gz$' "$root/SOURCE-BUNDLE.txt" || {
  echo "source archive pairing missing" >&2; exit 23;
}
grep -Eq '^source_archive_sha256=[0-9a-f]{64}$' "$root/SOURCE-BUNDLE.txt" || {
  echo "source archive pairing hash missing" >&2; exit 23;
}

if [[ -n "$expected_commit" ]]; then
  grep -Fxq "git_commit=$expected_commit" "$root/build-report.txt" || {
    echo "release commit mismatch" >&2; exit 23;
  }
fi

if find "$root" -type f \( -name '*.key' -o -name '*.pem' -o -name 'id_rsa*' -o -name 'id_ed25519*' -o -name authorized_keys \) -print -quit | grep -q .; then
  echo "secret-like file found in release" >&2
  exit 24
fi
secret_pattern='BEGIN (RSA |OPENSSH )?PRIVATE KEY'
secret_pattern="${secret_pattern}"'|XPR_MPSS_PASSWORD|SSH_.*PRIVATE'
secret_pattern="${secret_pattern}"'|PRIVATE_KEY|PASSWORD[[:space:]]*[:=]'
if grep -RIlE "$secret_pattern" "$root" | grep -q .; then
  echo "secret pattern found in release" >&2
  exit 25
fi
if find "$root" -type f \( -name '*.rpm' -o -name '*.deb' -o -name '*.rom' -o -name '*.fw' \) -print -quit | grep -q .; then
  echo "prohibited package or firmware found in release" >&2
  exit 26
fi

echo "PRECOMPILED_RC_VERIFY=PASS"
echo "publication_status=HUMAN_LEGAL_REVIEW_PENDING"
