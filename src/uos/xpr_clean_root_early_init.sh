#!/xpr-tools/busybox sh
# Project-authored bootstrap for a clean, project-owned K1OM root filesystem.

BB=/xpr-tools/busybox
umask 0022

mark() {
    printf '%s\n' "$1" > /etc/xpr-clean-root-early-init
}

load_module() {
    "$BB" modprobe "$@" || mark "XPR_CLEAN_ROOT_MODULE_FAIL:$1"
}

"$BB" mkdir -p /proc /sys /new_root /etc
"$BB" mount -t proc proc /proc 2>/dev/null || true
"$BB" mount -t sysfs sysfs /sys 2>/dev/null || true
mark XPR_CLEAN_ROOT_EARLY_INIT_ENTERED

# These values are supplied by MPSS through the kernel command line.
load_module michvc ${vcons_hdr_addr:+vcons_hdr_addr=$vcons_hdr_addr}
load_module intel_micveth ${vnet:+vnet=$vnet} ${vnet_addr:+vnet_addr=$vnet_addr} ${vnet_num_buffers:+vnet_num_buffers=$vnet_num_buffers}
load_module micscif ${p2p:+p2p=$p2p} ${p2p_proxy:+p2p_proxy=$p2p_proxy} ${p2p_proxy_thresh:+p2p_proxy_thresh=$p2p_proxy_thresh} ${numa_node:+numa_node=$numa_node} ${scif_id:+scif_id=$scif_id} ${scif_addr:+scif_addr=$scif_addr} ${reg_cache:+reg_cache=$reg_cache} ${ulimit:+ulimit=$ulimit} ${huge_page:+huge_page=$huge_page} ${pm_qos_cpu_dma_lat:+pm_qos_cpu_dma_lat=$pm_qos_cpu_dma_lat}
load_module mic_virtblk ${virtio_addr:+virtio_addr=$virtio_addr}
load_module ramoops ${ramoops_size:+mem_size=$ramoops_size} ${ramoops_addr:+mem_address=$ramoops_addr}
load_module micras
# Load this before switch_root while MPSS supplies the module tree. Project PID
# 1 performs the host notification after the clean-root handoff.
load_module mpssboot

"$BB" mount -t tmpfs none /new_root -o mode=0755,size=85% || {
    mark XPR_CLEAN_ROOT_TMPFS_FAIL
    exec "$BB" sh
}

"$BB" gzip -dc /xpr-rootfs.cpio.gz | (cd /new_root && "$BB" cpio -idm) || {
    mark XPR_CLEAN_ROOT_UNPACK_FAIL
    exec "$BB" sh
}
test -x /new_root/sbin/init || {
    mark XPR_CLEAN_ROOT_INIT_MISSING
    exec "$BB" sh
}
printf '%s\n' XPR_CLEAN_ROOT_READY > /new_root/etc/xpr-clean-root-early-init
exec "$BB" switch_root /new_root /sbin/init
