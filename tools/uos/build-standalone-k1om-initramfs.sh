#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-standalone-k1om-initramfs.sh --source-rootfs DIR [--out-root DIR] [--name NAME]

Build a private standalone xpr-uOS K1OM initramfs from an already validated
local RC rootfs. The generated image is intended for a resident project PID 1
experiment: it does not install, call, or exec stock init.sysvinit.

The source rootfs and generated image can contain local MPSS/K1OM-derived
payloads. Keep them out of Git.
USAGE
}

source_rootfs=""
out_root="${HOME}/xeon-phi-revival-local/uos-standalone-builds"
name="xpr-uos-standalone-pid1"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-rootfs) source_rootfs="${2:-}"; shift 2 ;;
    --out-root) out_root="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$source_rootfs" && -d "$source_rootfs" ]] || { usage; exit 2; }

for cmd in awk chmod cpio date du file find gzip mkdir readlink rm sed sha256sum sort stat tar; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required host tool missing: $cmd" >&2; exit 10; }
done

require_path() {
  local label="$1" path="$2"
  [[ -e "$path" || -L "$path" ]] || { echo "$label missing: $path" >&2; exit 11; }
}

require_path "BusyBox" "$source_rootfs/bin/busybox"
require_path "os-release" "$source_rootfs/etc/os-release"
require_path "hello smoke" "$source_rootfs/opt/xeon-phi-revival/bin/hello-knc"
for lib in ld-linux-k1om.so.2 libc.so.6 libpthread.so.0 libm.so.6 libdl.so.2 librt.so.1 libutil.so.1 libgcc_s.so.1; do
  require_path "runtime $lib" "$source_rootfs/opt/xeon-phi-revival/lib64/$lib"
done

timestamp="$(date -u +%Y%m%d-%H%M%S)"
run_dir="$out_root/${name}-${timestamp}"
rootfs="$run_dir/rootfs"
image="$run_dir/${name}.cpio.gz"
manifest="$run_dir/${name}.manifest.tsv"
hashes="$run_dir/SHA256SUMS"
summary="$run_dir/build-summary.txt"

mkdir -p "$rootfs"
exec > >(tee "$run_dir/build.log") 2>&1

echo "== xpr-uOS standalone K1OM initramfs build =="
date -u
echo "source_rootfs=$source_rootfs"
echo "run_dir=$run_dir"
echo "source_date_epoch=$source_date_epoch"

mkdir -p "$rootfs"/{bin,sbin,etc,dev,proc,sys,run,tmp,root,var/log,opt/xeon-phi-revival}
chmod 0755 "$rootfs"/{bin,sbin,etc,dev,proc,sys,root,var,opt,opt/xeon-phi-revival}
chmod 1777 "$rootfs/tmp"
chmod 0755 "$rootfs/run"

cp -a "$source_rootfs/bin/busybox" "$rootfs/bin/busybox"
chmod 0755 "$rootfs/bin/busybox"

for applet in sh ash cat chmod chown cp date df dmesg du echo env false find grep head hostname id kill ln ls mkdir mount mv pidof printf ps pwd readlink rm sed sleep sort stat tail tee test touch true umount uname wc mknod sync; do
  ln -s busybox "$rootfs/bin/$applet"
done

cp -a "$source_rootfs/etc/os-release" "$rootfs/etc/os-release"
cat > "$rootfs/etc/issue" <<'EOF'
Xeon Phi Revival standalone xpr-uOS resident PID 1
EOF

mkdir -p "$rootfs/opt/xeon-phi-revival/bin" "$rootfs/opt/xeon-phi-revival/lib64"
cp -a "$source_rootfs/opt/xeon-phi-revival/bin/hello-knc" "$rootfs/opt/xeon-phi-revival/bin/hello-knc"
cp -a "$source_rootfs/opt/xeon-phi-revival/lib64/." "$rootfs/opt/xeon-phi-revival/lib64/"

mkdir -p "$rootfs/lib64"
for item in "$rootfs/opt/xeon-phi-revival/lib64/"*; do
  base="$(basename "$item")"
  ln -s "../opt/xeon-phi-revival/lib64/$base" "$rootfs/lib64/$base"
done

cat > "$run_dir/pthread-smoke.c" <<'C'
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static void *worker(void *arg) {
    int *value = (int *)arg;
    *value = 42;
    return arg;
}

int main(void) {
    pthread_t thread;
    int value = 0;
    void *ret = 0;
    if (pthread_create(&thread, 0, worker, &value) != 0) {
        puts("pthread_create failed");
        return 2;
    }
    if (pthread_join(thread, &ret) != 0) {
        puts("pthread_join failed");
        return 3;
    }
    printf("pthread smoke ok value=%d ret_match=%d pid=%ld\n", value, ret == &value, (long)getpid());
    return (value == 42 && ret == &value) ? 0 : 4;
}
C

if ! command -v k1om-mpss-linux-gcc >/dev/null 2>&1 && [[ -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  # The MPSS SDK keeps the K1OM cross tools outside root's default PATH.
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
fi

if command -v k1om-mpss-linux-gcc >/dev/null 2>&1; then
  k1om-mpss-linux-gcc -O2 "$run_dir/pthread-smoke.c" -o "$rootfs/opt/xeon-phi-revival/bin/pthread-smoke" -lpthread
else
  echo "warning: k1om-mpss-linux-gcc not in PATH; pthread smoke binary will be absent" >&2
fi

cat > "$rootfs/sbin/init" <<'INIT'
#!/bin/sh

PATH=/bin:/sbin:/opt/xeon-phi-revival/bin
HOME=/root
LD_LIBRARY_PATH=/lib64:/opt/xeon-phi-revival/lib64
export PATH HOME LD_LIBRARY_PATH

LOG=/run/xpr-uos-standalone-init.log
PERSIST_LOG=/var/log/xpr-uos-standalone-init.log

console_setup() {
    [ -d /dev ] || mkdir -p /dev
    [ -c /dev/console ] || /bin/busybox mknod -m 600 /dev/console c 5 1 2>/dev/null || true
    [ -c /dev/null ] || /bin/busybox mknod -m 666 /dev/null c 1 3 2>/dev/null || true
    [ -c /dev/zero ] || /bin/busybox mknod -m 666 /dev/zero c 1 5 2>/dev/null || true
    [ -c /dev/random ] || /bin/busybox mknod -m 666 /dev/random c 1 8 2>/dev/null || true
    [ -c /dev/urandom ] || /bin/busybox mknod -m 666 /dev/urandom c 1 9 2>/dev/null || true
    if [ -c /dev/console ]; then
        exec </dev/console >/dev/console 2>&1
    fi
}

log() {
    echo "[xpr-uos-standalone] $*"
    echo "[xpr-uos-standalone] $*" >> "$LOG" 2>/dev/null || true
    echo "[xpr-uos-standalone] $*" >> "$PERSIST_LOG" 2>/dev/null || true
}

run_check() {
    name="$1"
    shift
    log "CHECK_START:$name"
    "$@" >> "$LOG" 2>&1
    rc=$?
    cat "$LOG" >/dev/console 2>/dev/null || true
    log "CHECK_RC:$name:$rc"
    return "$rc"
}

reap_children() {
    while true; do
        wait 2>/dev/null || break
    done
}

console_setup
mkdir -p /proc /sys /run /tmp /var/log /root
chmod 1777 /tmp 2>/dev/null || true

mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t tmpfs -o mode=0755 tmpfs /run 2>/dev/null || true
mount -t tmpfs -o mode=1777 tmpfs /tmp 2>/dev/null || true
console_setup

: > "$LOG" 2>/dev/null || true
: > "$PERSIST_LOG" 2>/dev/null || true

hostname xpr-uos-k1om 2>/dev/null || true

log "BOOT_START"
log "resident_pid=$$"
log "proc1_comm=$(cat /proc/1/comm 2>/dev/null || echo unavailable)"
log "cmdline=$(cat /proc/cmdline 2>/dev/null || true)"
log "uname=$(uname -a 2>/dev/null || true)"
log "machine=$(uname -m 2>/dev/null || true)"
log "hostname=$(hostname 2>/dev/null || true)"
log "os_release_begin"
cat /etc/os-release 2>/dev/null | tee -a "$LOG" >/dev/console 2>/dev/null || true
log "os_release_end"
log "mounts_begin"
cat /proc/mounts 2>/dev/null | tee -a "$LOG" >/dev/console 2>/dev/null || true
log "mounts_end"

fail=0
run_check sh_basic /bin/sh -c 'echo sh_ok; command -v ls; ls /; cat /etc/os-release | grep "^ID=xpr-uos"; test "$(uname -m)" = "k1om"' || fail=1
run_check fs_basic /bin/sh -c 'touch /tmp/xpr-test; test -f /tmp/xpr-test; mkdir -p /run/xpr-test; echo run_tmp_ok' || fail=1
run_check dev_basic /bin/sh -c 'test -c /dev/null; test -c /dev/console; echo dev_ok >/dev/null; echo dev_nodes_ok' || fail=1
run_check hello /opt/xeon-phi-revival/bin/hello-knc || fail=1
if [ -x /opt/xeon-phi-revival/bin/pthread-smoke ]; then
    run_check pthread /opt/xeon-phi-revival/bin/pthread-smoke || fail=1
else
    log "CHECK_RC:pthread:127"
    fail=1
fi

if pidof init.sysvinit >/dev/null 2>&1; then
    log "STOCK_INIT_SYSVINIT_PRESENT=1"
    fail=1
else
    log "STOCK_INIT_SYSVINIT_PRESENT=0"
fi

log "BOOT_RESULT=$([ "$fail" -eq 0 ] && echo PASS || echo FAIL)"
log "RESIDENT_IDLE=1"
sync 2>/dev/null || true

while true; do
    reap_children
    sleep 5 &
    wait $! 2>/dev/null || true
done
INIT
chmod 0755 "$rootfs/sbin/init"
ln -s sbin/init "$rootfs/init"

if [[ "$(id -u)" -eq 0 ]]; then
  for node in \
    "null c 1 3 666" \
    "zero c 1 5 666" \
    "console c 5 1 600" \
    "urandom c 1 9 666" \
    "random c 1 8 666"; do
    set -- $node
    /bin/mknod -m "$5" "$rootfs/dev/$1" "$2" "$3" "$4" 2>/dev/null || true
  done
fi

echo "== validating standalone rootfs inputs =="
file "$rootfs/bin/busybox" "$rootfs/opt/xeon-phi-revival/bin/hello-knc" "$rootfs/opt/xeon-phi-revival/bin/pthread-smoke" 2>/dev/null || true

(
  cd "$rootfs"
  find . -print0 | sort -z | cpio --null -o -H newc 2>"$run_dir/cpio.stderr" | gzip -9n > "$image"
)

{
  printf 'path\ttype\tmode\tsize\tsha256\tlink_target\n'
  while IFS= read -r -d '' path; do
    rel="/${path#"$rootfs"/}"
    if [[ -L "$path" ]]; then
      printf '%s\tsymlink\t%s\t0\t\t%s\n' "$rel" "$(stat -c '%a' "$path")" "$(readlink "$path")"
    elif [[ -d "$path" ]]; then
      printf '%s\tdirectory\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path")"
    elif [[ -f "$path" ]]; then
      printf '%s\tfile\t%s\t%s\t%s\t\n' "$rel" "$(stat -c '%a' "$path")" "$(stat -c '%s' "$path")" "$(sha256sum "$path" | awk '{print $1}')"
    else
      printf '%s\tspecial\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path" 2>/dev/null || true)"
    fi
  done < <(find "$rootfs" -mindepth 1 -print0 | sort -z)
} > "$manifest"

sha256sum "$image" "$manifest" > "$hashes"
du -h "$image" "$rootfs" > "$run_dir/size.txt"

cat > "$run_dir/inherited-local-inputs.txt" <<EOF
source_rootfs=$source_rootfs
remaining_stock_or_byo_payloads:
- /bin/busybox copied from the current private RC rootfs; that RC rootfs currently traces BusyBox to stock/local inputs and is not public-safe.
- /opt/xeon-phi-revival/lib64/libgcc_s.so.1 traces to the local MPSS K1OM SDK in the current RC.
- Other /opt/xeon-phi-revival runtime libraries are project/Ubuntu-source build outputs but remain private until source/license packaging is complete.
explicitly_not_included:
- stock /sbin/init.sysvinit
- stock MPSS card-side service scripts
- SSH/network startup payloads
EOF

cat > "$summary" <<EOF
status=built
run_dir=$run_dir
rootfs=$rootfs
image=$image
image_sha256=$(awk -v img="$image" '$2 == img {print $1}' "$hashes")
manifest=$manifest
hashes=$hashes
size=$(du -h "$image" | awk '{print $1}')
inherited_inputs=$run_dir/inherited-local-inputs.txt
EOF

cat "$summary"
gzip -l "$image" || true
