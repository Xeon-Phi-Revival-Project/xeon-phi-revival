#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-bootable-k1om-rootfs.sh --source-rootfs DIR --out DIR [--manifest OUT]

Clone a private, already validated K1OM rootfs into a bootable staging tree and
install a project-owned /init suitable for an MPSS ramfs/initramfs experiment.

The source and output trees may contain Intel runtime files and must stay out of
the public repository.
USAGE
}

source_rootfs=""
out_dir=""
manifest=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-rootfs)
      source_rootfs="${2:-}"
      shift 2
      ;;
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --manifest)
      manifest="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$source_rootfs" || -z "$out_dir" ]]; then
  usage
  exit 2
fi

if [[ ! -d "$source_rootfs" ]]; then
  echo "source rootfs does not exist: $source_rootfs" >&2
  exit 3
fi

if [[ -e "$out_dir" && -n "$(find "$out_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "output directory is not empty: $out_dir" >&2
  exit 4
fi

manifest="${manifest:-${out_dir%/}.manifest.tsv}"

mkdir -p "$out_dir"
if command -v rsync >/dev/null 2>&1; then
  rsync -aHAX --numeric-ids "$source_rootfs"/ "$out_dir"/
else
  (cd "$source_rootfs" && tar cpf - .) | (cd "$out_dir" && tar xpf -)
fi

mkdir -p "$out_dir"/{dev,proc,sys,run,tmp,root,usr/share/knc-demo,var/log}
chmod 1777 "$out_dir/tmp"

cat > "$out_dir/usr/share/knc-demo/python-core-pid1.py" <<'PY'
import os
import platform
import sys
import threading

result = []

def worker():
    result.append(42)

t = threading.Thread(target=worker)
t.start()
t.join()

print("python pid1 demo ok")
print("platform=%s" % sys.platform)
print("machine=%s" % platform.machine())
print("cwd=%s" % os.getcwd())
print("thread=%s" % (result[0] if result else "missing"))
PY

cat > "$out_dir/init" <<'INIT'
#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/root
LD_LIBRARY_PATH=/lib64:/usr/lib64:/lib:/usr/lib
export PATH HOME LD_LIBRARY_PATH

log() {
    echo "[xeon-phi-revival-init] $*"
}

shell_forever() {
    log "starting recovery shell; leaving /init alive"
    while true; do
        if [ -c /dev/console ]; then
            /bin/sh -i </dev/console >/dev/console 2>&1
        else
            /bin/sh -i
        fi
        log "recovery shell exited; restarting it"
        sleep 1
    done
}

mkdir -p /dev /proc /sys /run /tmp /root /var/log
chmod 1777 /tmp 2>/dev/null || true

[ -c /dev/console ] || mknod -m 600 /dev/console c 5 1 2>/dev/null || true
[ -c /dev/null ] || mknod -m 666 /dev/null c 1 3 2>/dev/null || true

if [ -c /dev/console ]; then
    exec </dev/console >/dev/console 2>&1
fi

log "project /init started"
log "initial pid=$$"

mount -t proc proc /proc 2>/dev/null || log "proc mount failed or already mounted"
mount -t sysfs sysfs /sys 2>/dev/null || log "sysfs mount failed or already mounted"

if ! grep -q ' /dev ' /proc/mounts 2>/dev/null; then
    mount -t devtmpfs devtmpfs /dev 2>/dev/null || \
        mount -t tmpfs -o mode=0755 tmpfs /dev 2>/dev/null || \
        log "dev mount failed; using static device nodes"
fi

[ -c /dev/console ] || mknod -m 600 /dev/console c 5 1 2>/dev/null || true
[ -c /dev/null ] || mknod -m 666 /dev/null c 1 3 2>/dev/null || true
[ -c /dev/zero ] || mknod -m 666 /dev/zero c 1 5 2>/dev/null || true
[ -c /dev/urandom ] || mknod -m 666 /dev/urandom c 1 9 2>/dev/null || true
[ -c /dev/random ] || mknod -m 666 /dev/random c 1 8 2>/dev/null || true

if [ -c /dev/console ]; then
    exec </dev/console >/dev/console 2>&1
fi

log "uname: $(uname -a 2>/dev/null || echo unavailable)"
log "pid check: $$"
log "environment:"
env | sort
log "mounts:"
cat /proc/mounts 2>/dev/null || log "could not read /proc/mounts"

if [ -x /usr/bin/hello-knc ]; then
    log "running hello-knc"
    /usr/bin/hello-knc || log "hello-knc failed rc=$?"
else
    log "missing /usr/bin/hello-knc"
fi

if [ -x /usr/bin/python3.5 ] && [ -f /usr/share/knc-demo/python-core-pid1.py ]; then
    log "running Python core demo"
    /usr/bin/python3.5 /usr/share/knc-demo/python-core-pid1.py || log "Python core demo failed rc=$?"
else
    log "missing Python core demo components"
fi

shell_forever
INIT

chmod 0755 "$out_dir/init"

for node in \
  "null c 1 3 666" \
  "zero c 1 5 666" \
  "console c 5 1 600" \
  "urandom c 1 9 666" \
  "random c 1 8 666"; do
  set -- $node
  path="$out_dir/dev/$1"
  if [[ ! -e "$path" ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then
      mknod -m "$5" "$path" "$2" "$3" "$4"
    else
      echo "warning: not root; $path will be created by /init at boot" >&2
    fi
  fi
done

mkdir -p "$(dirname "$manifest")"
{
  printf 'path\ttype\tmode\tsize\tsha256\tlink_target\n'
  while IFS= read -r -d '' path; do
    rel="/${path#"$out_dir"/}"
    if [[ -L "$path" ]]; then
      printf '%s\tsymlink\t%s\t0\t\t%s\n' "$rel" "$(stat -c '%a' "$path")" "$(readlink "$path")"
    elif [[ -d "$path" ]]; then
      printf '%s\tdirectory\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path")"
    elif [[ -f "$path" ]]; then
      printf '%s\tfile\t%s\t%s\t%s\t\n' "$rel" "$(stat -c '%a' "$path")" "$(stat -c '%s' "$path")" "$(sha256sum "$path" | awk '{print $1}')"
    else
      printf '%s\tspecial\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path" 2>/dev/null || true)"
    fi
  done < <(find "$out_dir" -mindepth 1 -print0 | sort -z)
} > "$manifest"

echo "rootfs=$out_dir"
echo "manifest=$manifest"
