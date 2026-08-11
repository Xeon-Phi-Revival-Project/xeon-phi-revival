# XPR-OS 0.1.0-rc6 Distribution Review

This document describes the current RC6 package candidate. It is engineering
provenance material, not legal advice, a publication approval, or a GitHub
release.

## Candidate State

RC6 preserves the exact RC5 runtime artifact set that passed three identical
rollback-protected deployments on the tested Intel Xeon Phi 5110P path. RC6
changes only public release metadata and source-package document membership.
The paired review report records the runtime hash identity table and confirms
whether a hardware retest is required.

## Distribution Boundary

The binary candidate includes source-accounted kernel, module, bootstrap, and
root-payload artifacts only for targeted review. The paired source archive
contains the pinned corresponding source archives, project build scripts,
configs, license texts, notices, and SPDX metadata.

Intel MPSS host software, firmware, SDK payloads, stock uOS contents, and
extracted sysroots are not included. The generic candidate contains no private
key, password, credential, or fixed `authorized_keys` file.

## Current Decision

`RC6_FROZEN_FOR_TARGETED_AUDIT` applies only after the RC6 package build and
validation gates complete. RC6 must not be tagged, published, or described as
a generally available download until the targeted audit and owner publication
decision are complete.
