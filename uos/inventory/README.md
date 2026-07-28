# Stock uOS Inventory

This directory contains scripts for inventorying the stock MPSS Knights Corner
uOS environment.

The output is local evidence, not automatically public source. File lists,
hashes, and behavior summaries are useful for compatibility work; extracted
Intel uOS images, root filesystems, firmware, and proprietary binaries should
stay out of the public repository unless a separate license review says
otherwise.

Run on the CentOS MPSS host:

```bash
bash uos/inventory/collect-stock-uos-inventory.sh
```

Expected local outputs include:

- boot image names and hashes
- generated `mic0` root filesystem file list
- generated `mic0` root filesystem hashes
- live `mic0` kernel, mount, process, CPU, memory, and network inventory
