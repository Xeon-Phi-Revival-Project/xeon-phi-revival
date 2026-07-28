#!/usr/bin/env bash
set -euo pipefail

out="${1:-ubuntu-port/k1om/repo-skeleton}"

mkdir -p \
  "$out/dists/noble/main/binary-k1om" \
  "$out/dists/noble/main/source" \
  "$out/pool/main"

cat > "$out/dists/noble/main/binary-k1om/Packages" <<'EOF'
# Placeholder Packages file for the experimental K1OM Ubuntu port.
# Real package stanzas must be generated from locally built K1OM .deb files.
EOF

gzip -n -c "$out/dists/noble/main/binary-k1om/Packages" > \
  "$out/dists/noble/main/binary-k1om/Packages.gz"

cat > "$out/dists/noble/main/source/Sources" <<'EOF'
# Placeholder Sources file for the experimental K1OM Ubuntu port.
# Real source stanzas must record Ubuntu source provenance and local patches.
EOF

gzip -n -c "$out/dists/noble/main/source/Sources" > \
  "$out/dists/noble/main/source/Sources.gz"

cat > "$out/dists/noble/Release" <<'EOF'
Origin: Xeon Phi Revival Project
Label: Xeon Phi Revival K1OM Port Lab
Suite: noble
Codename: noble
Architectures: k1om source
Components: main
Description: Experimental metadata skeleton for a K1OM Ubuntu architecture port
EOF

echo "$out"
