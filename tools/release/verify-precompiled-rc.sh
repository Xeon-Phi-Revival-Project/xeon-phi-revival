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
  tools/verify.sh manifests/tested-artifacts.json manifests/release.yml
)
for path in "${required[@]}"; do
  [[ -e "$root/$path" ]] || { echo "required release member missing: $path" >&2; exit 21; }
done
[[ "$(cat "$root/VERSION")" == "$version" ]] || { echo "VERSION mismatch" >&2; exit 22; }
(cd "$root" && sha256sum -c SHA256SUMS)

declare -A expected=(
  [kernel/bzImage]=d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8
  [kernel/System.map]=631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6
  [bootstrap/xpr-bootstrap.cpio.gz]=bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779
  [payload/xpr-rootfs.cpio.gz]=e5c25217a5b9a2c60f7caaefce3651dd086b6f0f0d51e88883aa3e9486c7fee7
  [modules/dma_module.ko]=af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a
  [modules/ringbuffer.ko]=e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068
  [modules/micscif.ko]=0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2
  [modules/mpssboot.ko]=a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894
  [modules/intel_micveth.ko]=0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60
)
for path in "${!expected[@]}"; do
  printf '%s  %s\n' "${expected[$path]}" "$root/$path" | sha256sum -c -
done

if [[ -n "$expected_commit" ]]; then
  grep -Fxq "git_commit=$expected_commit" "$root/build-report.txt" || {
    echo "release commit mismatch" >&2; exit 23;
  }
fi

if find "$root" -type f \( -name '*.key' -o -name '*.pem' -o -name 'id_rsa*' -o -name 'id_ed25519*' -o -name authorized_keys \) -print -quit | grep -q .; then
  echo "secret-like file found in release" >&2
  exit 24
fi
if grep -RIlE '(BEGIN (RSA |OPENSSH )?PRIVATE KEY|XPR_MPSS_PASSWORD|SSH_PRIVATE_KEY|PASSWORD=)' "$root" | grep -q .; then
  echo "secret pattern found in release" >&2
  exit 25
fi
if find "$root" -type f \( -name '*.rpm' -o -name '*.deb' -o -name '*.rom' -o -name '*.fw' \) -print -quit | grep -q .; then
  echo "prohibited package or firmware found in release" >&2
  exit 26
fi

echo "PRECOMPILED_RC_VERIFY=PASS"
echo "publication_status=HUMAN_LEGAL_REVIEW_PENDING"
