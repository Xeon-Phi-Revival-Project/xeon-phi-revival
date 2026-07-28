#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  install-k1om-profile-deb-to-micdir.sh --deb FILE --micdir DIR

Extract a locally built K1OM profile .deb into an MPSS MicDir staging tree.
This is a bootstrap installer for private experiments, not a dpkg replacement.
USAGE
}

deb=""
micdir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deb) deb="${2:-}"; shift 2 ;;
    --micdir) micdir="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$deb" || -z "$micdir" ]]; then
  usage
  exit 2
fi
if [[ ! -f "$deb" ]]; then
  echo "deb missing: $deb" >&2
  exit 10
fi
if [[ ! -d "$micdir" ]]; then
  echo "micdir missing: $micdir" >&2
  exit 11
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
(cd "$tmp" && ar x "$deb" control.tar.gz data.tar.gz debian-binary)
grep -qx '2.0' "$tmp/debian-binary"
mkdir -p "$micdir"
tar -xzf "$tmp/data.tar.gz" -C "$micdir"
echo "installed=$deb"
echo "micdir=$micdir"
