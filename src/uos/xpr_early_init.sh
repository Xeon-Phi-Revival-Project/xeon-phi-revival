#!/bin/sh
# Project-authored early K1OM init for a reversible MPSS Base CPIO experiment.

PATH=/sbin:/usr/sbin:/bin:/usr/bin
export PATH
umask 0022
exec >/dev/kmsg 2>&1

mark() {
    printf '%s\n' "$1" > /etc/xpr-early-init
}

load_module() {
    /sbin/modprobe "$@" || mark "XPR_EARLY_INIT_MODULE_FAIL:$1"
}

mkdir -p /proc /sys /etc/modules-load.d /etc/modprobe.d /new_root
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mark XPR_EARLY_INIT_ENTERED

# MPSS passes these values from the kernel command line as /init environment.
load_module michvc ${vcons_hdr_addr:+vcons_hdr_addr=$vcons_hdr_addr}
load_module intel_micveth ${vnet:+vnet=$vnet} ${vnet_addr:+vnet_addr=$vnet_addr} ${vnet_num_buffers:+vnet_num_buffers=$vnet_num_buffers}
load_module micscif ${p2p:+p2p=$p2p} ${p2p_proxy:+p2p_proxy=$p2p_proxy} ${p2p_proxy_thresh:+p2p_proxy_thresh=$p2p_proxy_thresh} ${numa_node:+numa_node=$numa_node} ${scif_id:+scif_id=$scif_id} ${scif_addr:+scif_addr=$scif_addr} ${reg_cache:+reg_cache=$reg_cache} ${ulimit:+ulimit=$ulimit} ${huge_page:+huge_page=$huge_page} ${pm_qos_cpu_dma_lat:+pm_qos_cpu_dma_lat=$pm_qos_cpu_dma_lat}
load_module mic_virtblk ${virtio_addr:+virtio_addr=$virtio_addr}
load_module ramoops ${ramoops_size:+mem_size=$ramoops_size} ${ramoops_addr:+mem_address=$ramoops_addr}
load_module micras

mount -t tmpfs none /new_root -o mode=0755,size=85%
find . -xdev -path ./new_root -prune -o -path ./RPMs-to-install -prune -o -print | /bin/cpio -m -p /new_root
printf '%s\n' XPR_EARLY_INIT_ROOT_READY > /new_root/etc/xpr-early-init

rm -f /new_root/sbin/init
cat > /new_root/sbin/init <<'XPR_PROJECT_SBIN_INIT'
#!/bin/sh
printf '%s\n' XPR > /etc/xpr-project-sbin-init
printf '%s\n' XPR_PROJECT_SBIN_INIT_PID1 >> /etc/xpr-project-sbin-init
printf 'pid=%s\n' "$$" >> /etc/xpr-project-sbin-init
exec /sbin/init.sysvinit
XPR_PROJECT_SBIN_INIT
chmod 0755 /new_root/sbin/init

exec /sbin/switch_root /new_root /sbin/init
