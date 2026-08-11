#!/usr/bin/env python3
"""Verify a staged release's self-describing artifact manifest."""
from __future__ import print_function

import argparse
import hashlib
import json
import os
import re
import sys


def digest(path):
    value = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def fail(message):
    sys.stderr.write("RELEASE_ARTIFACT_VALIDATION=FAIL %s\n" % message)
    return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--expected-commit")
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    manifest_path = os.path.join(root, "manifests", "tested-artifacts.json")
    try:
        manifest = json.load(open(manifest_path))
    except (IOError, ValueError) as exc:
        return fail("invalid tested-artifacts manifest: %s" % exc)
    if manifest.get("schema") != "xpr-tested-artifact-freeze-v2":
        return fail("unexpected tested-artifacts schema")
    if manifest.get("release_version") != args.version:
        return fail("tested-artifacts version mismatch")
    if manifest.get("status") not in ("hardware-validation-pending", "hardware-validation-passed"):
        return fail("invalid hardware-validation status")
    commit = manifest.get("repository_commit", "")
    if not re.match(r"^[0-9a-f]{40}$", commit):
        return fail("invalid repository commit")
    if args.expected_commit and commit != args.expected_commit:
        return fail("repository commit mismatch")
    ids = set()
    for item in manifest.get("artifacts", []):
        identity, relative, expected = item.get("id"), item.get("path"), item.get("sha256")
        if not identity or identity in ids or not relative or relative.startswith("/") or ".." in relative.split("/"):
            return fail("invalid artifact manifest entry")
        ids.add(identity)
        if not re.match(r"^[0-9a-f]{64}$", expected):
            return fail("invalid hash for " + identity)
        candidate = os.path.join(root, *relative.split("/"))
        if not os.path.isfile(candidate):
            return fail("artifact missing: " + relative)
        if digest(candidate) != expected:
            return fail("artifact hash mismatch: " + relative)
    required = set(("kernel", "system-map", "base-cpio", "final-root-payload",
                    "dma-module", "ringbuffer-module", "micscif-module", "mpssboot-module",
                    "intel-micveth-module"))
    if ids != required:
        return fail("artifact manifest set is incomplete")
    print("RELEASE_ARTIFACT_VALIDATION=PASS version=%s status=%s artifacts=%d" %
          (args.version, manifest["status"], len(ids)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
