#!/usr/bin/env bash
set -euo pipefail

inventory_csv="${1:-artifacts/public/uos-elf-inventory.csv}"
manifest="${2:-uos/ubuntu2404/level1-tiny-rootfs-manifest.txt}"
out="${3:-docs/uos/ubuntu-24.04-level1-gap-report.md}"

if [[ ! -f "$inventory_csv" ]]; then
  echo "missing inventory CSV: $inventory_csv" >&2
  exit 2
fi

if [[ ! -f "$manifest" ]]; then
  echo "missing manifest: $manifest" >&2
  exit 2
fi

out_dir="${out%/*}"
if [[ "$out_dir" != "$out" ]]; then
  mkdir -p "$out_dir"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

tail -n +2 "$inventory_csv" | cut -d, -f1 | sort -u > "$tmpdir/elf-paths.txt"
grep -Ev '^\s*(#|$)' "$manifest" | sort -u > "$tmpdir/manifest-paths.txt"

{
  echo "# Ubuntu 24.04 uOS Level 1 Gap Report"
  echo
  echo "Public-safe metadata report. It uses path and ELF dependency metadata only;"
  echo "no Intel uOS file contents are included."
  echo
  echo "## Inputs"
  echo
  echo "- Inventory CSV: \`$inventory_csv\`"
  echo "- Candidate manifest: \`$manifest\`"
  echo
  echo "## ELF Paths Present In Public Inventory"
  echo
  while IFS= read -r path; do
    if grep -Fxq "$path" "$tmpdir/elf-paths.txt"; then
      echo "- \`$path\`"
    fi
  done < "$tmpdir/manifest-paths.txt"
  echo
  echo "## Manifest Paths Not Proven By ELF Inventory"
  echo
  echo "These may still exist in the stock uOS; this report only uses the public"
  echo "ELF inventory, so directories, text config, symlinks, devices, and non-ELF"
  echo "files need a separate file-list check."
  echo
  while IFS= read -r path; do
    if ! grep -Fxq "$path" "$tmpdir/elf-paths.txt"; then
      echo "- \`$path\`"
    fi
  done < "$tmpdir/manifest-paths.txt"
  echo
  echo "## Library Dependencies Referenced By Candidate ELF Files"
  echo
  awk -F, '
    NR == 1 { next }
    $1 == "/bin/busybox" || $1 == "/bin/bash" {
      split($10, libs, ";")
      for (i in libs) {
        if (libs[i] != "") seen[libs[i]] = 1
      }
    }
    END {
      for (lib in seen) print "- `" lib "`"
    }
  ' "$inventory_csv" | sort
  echo
  echo "## Initial Interpretation"
  echo
  echo "- The public ELF inventory proves stock K1OM executable metadata for shell"
  echo "  and BusyBox candidates."
  echo "- The Level 1 rootfs still needs a public-safe file-list check for init,"
  echo "  symlinks, config files, directories, device setup, and MPSS integration."
  echo "- A boot attempt should use a copy of the stock image or a separate local"
  echo "  test image with a documented rollback path."
} > "$out"

echo "$out"
