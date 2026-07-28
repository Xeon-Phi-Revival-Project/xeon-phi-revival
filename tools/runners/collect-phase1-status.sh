#!/usr/bin/env bash
set -euo pipefail

echo "=== host ==="
hostname
cat /etc/centos-release 2>/dev/null || true
uname -a

echo "=== mpss ==="
systemctl is-enabled mpss.service 2>&1 || true
systemctl is-active mpss.service 2>&1 || true
micctrl --status 2>&1 || true

echo "=== pci ==="
lspci -Dnnd 8086:2250 || true
lspci -nnk -s 82:00.0 || true

echo "=== micinfo ==="
micinfo 2>&1 | sed -n '1,120p' || true

echo "=== mic ssh ==="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 mic0 'hostname; uname -a; id' 2>&1 || true
