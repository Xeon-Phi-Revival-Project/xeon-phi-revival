# XPR-OS Historical Pause Record

Status: Historical record; development resumed August 8, 2026
Pause recorded: 2026-08-02

This document preserves the prior pause decision only. Active project status,
current evidence, and the execution checklist are in [Project Status](status.md).

## Reason for the historical pause

The August 2 pause was logistical: the available Codex usage quota was nearly
exhausted. The project was not abandoned and was not judged infeasible.

## Project goal

Develop XPR-OS, an independently developed open-source Linux uOS/userspace for Intel Xeon Phi Knights Corner K1OM hardware.

The intended deployment model is:

- users install Intel MPSS on the host;
- users download an XPR-OS card-side image;
- MPSS and micctrl load and boot the image;
- users connect through the MPSS virtual network and SSH;
- MPSS initially remains responsible for the host driver, firmware, stock KNC kernel, and boot transport.

## Confirmed achievements

- Project-controlled code has executed as PID 1 after switch_root.
- A project PID 1 wrapper successfully recorded execution and handed off to the preserved stock init.
- The card reached online after that wrapper test.
- Stock MPSS rollback and stock SSH recovery have been repeatedly verified.
- Project-built K1OM eglibc runtime components work.
- K1OM hello and pthread smoke programs work in the validated environment.
- Python 3.12 has been built for K1OM.
- dpkg and an APT-compatible package path have been demonstrated.
- A coherent private XPR uOS release-candidate rootfs has passed live smoke testing.
- Standalone and minimal-init initramfs build and experiment tooling exists.

## Historical blocker

A fully project-controlled early Base CPIO/initramfs has not yet reached project /init on live hardware. Modified images remain in the mic0 "booting" state without producing expected project-init markers.

Latest size-matched attempt:

- commit: `985946529a6c6d27b2b9afe3deada19866814e24`
- image SHA-256: `e87e4b50b26a2ded51ee1c0402f1a6546212a6bfb3acb105c17a6ef3c796f030`
- uncompressed CPIO size: 53,688,320 bytes
- CPIO member count: 1,787

The archive matched the observed stock uncompressed size and member count exactly, but mic0 still remained in "booting." Total uncompressed size and member count are therefore ruled out as the immediate cause.

Recovery passed:

- mic0 online;
- mpss.service active;
- stock SSH working;
- uname -m returned k1om;
- stock PID 1 was systemd.

## Important distinction

The project has proven that project-controlled code can run as PID 1 after the stock early /init performs switch_root.

The unresolved problem is the earlier Base CPIO bootstrap or archive-generation path, not whether K1OM can execute a project-controlled PID 1.

## Exact resume point

Perform one no-op stock Base CPIO reconstruction control:

1. unpack the stock MPSS Base CPIO;
2. change no files;
3. repack it using the project archive-generation process;
4. perform one bounded live boot attempt;
5. determine whether unpacking and repacking alone causes the failure.

Interpretation:

- if the no-op rebuild fails, investigate serialization, metadata, ordering, hard links, alignment, trailer placement, and compression;
- if it boots, compare it against the smallest failing /init modification.

Do not resume full-rootfs, networking, SSH replacement, or package-expansion work until this control is complete.

## Redistribution status

Current generated images remain private and must not be published because they still include or depend on local or MPSS-derived files, including:

- stock-derived BusyBox;
- MPSS SDK lineage libgcc_s.so.1;
- runtime binaries that still require complete source and license packaging.

## Resume checklist

- verify repository HEAD and remote state;
- verify stock MPSS boot;
- verify stock SSH;
- read this status document;
- perform only the no-op CPIO rebuild control;
- use bounded waits and automatic rollback;
- record the result before any follow-up experiment.
