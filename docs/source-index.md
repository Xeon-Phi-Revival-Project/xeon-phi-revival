# Source Index

This page lists useful public references for the Xeon Phi Revival Project.
It is an index, not a redistribution area.

Do not commit Intel MPSS packages, firmware, extracted uOS images, Intel
headers, Intel libraries, copied book text, or locally built K1OM binaries to
this repository. When a source has unclear redistribution rights, use it only
as a local reference under its own terms.

## Hardware And Product References

| Source | Use | Redistribution note |
| --- | --- | --- |
| [Intel Xeon Phi Coprocessor 5110P product page](https://www.intel.com/content/www/us/en/products/sku/71992/intel-xeon-phi-coprocessor-5110p-8gb-1-053-ghz-60-core/specifications.html) | Baseline 5110P facts: 60 cores, 8 GB memory, Knights Corner family, IMCI, discontinued status. | Link only. Do not copy page content beyond short factual notes. |
| [Intel Xeon Phi coprocessor quick-start guide for MPSS 3.4](https://www.intel.com/content/dam/develop/external/us/en/documents/intel-xeon-phi-quick-start-developers-guide-mpss-3-4.pdf) | Host setup model, MPSS workflow, `micctrl`, native/offload development context. | Link only. Do not commit copied PDF content. |
| [Lenovo Intel Xeon Phi drivers page](https://support.lenovo.com/us/en/downloads/ds117299-intel-xeon-phi-drivers) | Vendor driver/support reference for historical MPSS-era systems. | Link only. Verify package terms before downloading or using anything. |

## Toolchain And ABI References

| Source | Use | Redistribution note |
| --- | --- | --- |
| `k1om-psabi-1.0.pdf` | K1OM ABI details: ELF machine, calling convention, registers, relocation behavior. | User-supplied local reference. Do not commit the PDF or large excerpts. |
| Local MPSS 3.4.10 package metadata | Exact package names, hashes, paths, RPM metadata, and tool prefix. | Public repo may contain metadata and reports only. Users must supply MPSS themselves. |
| [Apress source examples for Intel Xeon Phi Coprocessor Architecture and Tools](https://github.com/Apress/intel-xeon-phi-coprocessor-architecture-tools) | Historical code examples and learning reference. | Reference only. Do not copy code into this project without checking license and attribution. |
| [Open-access Apress book page](https://link.springer.com/book/10.1007/978-1-4302-5927-5) | Public book landing page for Rezaur Rahman's Xeon Phi guide. | Link to the publisher page rather than storing copied book content. |

## Ubuntu And Open-Source Package Sources

| Source | Use | Redistribution note |
| --- | --- | --- |
| [Ubuntu Noble zlib source package](https://packages.ubuntu.com/source/noble/zlib) | Ubuntu 24.04 source baseline for K1OM zlib experiments. | Use Ubuntu source package terms; keep generated K1OM artifacts private unless licensing and payload provenance are clear. |
| [Ubuntu Noble ncurses source package](https://packages.ubuntu.com/source/noble/ncurses) | Ubuntu 24.04 source baseline for K1OM ncurses/libtinfo experiments. | Use Ubuntu source package terms; keep generated K1OM artifacts private unless licensing and payload provenance are clear. |
| [Launchpad ncurses source in Noble](https://launchpad.net/ubuntu/noble/+source/ncurses) | Version history, checksums, and Ubuntu publication metadata. | Link only or record small metadata. |
| [QPhiX documentation](https://jeffersonlab.github.io/qphix/) | Example of serious Xeon Phi-era HPC software targeting vectorized kernels. | Reference only unless a future port explicitly follows its license. |

## Known Local-Only Or Restricted Inputs

These are important for reproducing the current private lab result, but they do
not belong in Git:

- MPSS archives, RPMs, firmware, and Intel compiler/runtime packages.
- Extracted stock uOS files and generated `mic0.image.gz` contents.
- Extracted sysroots, K1OM runtime libraries, and Intel headers.
- Locally built `.deb` packages that contain Intel runtime files or K1OM
  binaries.
- Full copied text from commercial books or PDFs.
- Private host logs, screenshots, credentials, serial numbers, and lab IPs
  outside the intentionally documented MPSS virtual network.

The project may publish:

- Original scripts and test source.
- Public-safe package recipes.
- File lists, hashes, and metadata.
- Short factual observations from hardware tests.
- Reproduction steps that require users to provide their own licensed inputs.
