#!/usr/bin/env python3
"""Reject a staged release that carries stale release identity or status text."""
from __future__ import print_function

import argparse
import io
import os
import re
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--expect-validation", choices=("pending", "passed"), required=True)
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    candidates = ("VERSION", "README.md", "build-report.txt", "SOURCE-BUNDLE.txt",
                  "manifests/tested-artifacts.json", "manifests/release.yml")
    errors = []
    for relative in candidates:
        path = os.path.join(root, *relative.split("/"))
        if not os.path.isfile(path):
            errors.append("required metadata member missing: " + relative)
            continue
        text = io.open(path, encoding="utf-8").read()
        if relative == "VERSION" and text.strip() != args.version:
            errors.append("VERSION does not equal requested release version")
        stale = re.findall(r"0\.1\.0-rc[0-9]+", text)
        if any(value != args.version for value in stale):
            errors.append("stale release identity in " + relative)
    expected = "hardware-validation-" + args.expect_validation
    tested = os.path.join(root, "manifests", "tested-artifacts.json")
    if os.path.isfile(tested) and expected not in io.open(tested, encoding="utf-8").read():
        errors.append("tested-artifacts validation state mismatch")
    release_text = io.open(os.path.join(root, "README.md"), encoding="utf-8").read() if os.path.isfile(os.path.join(root, "README.md")) else ""
    if args.expect_validation == "passed" and re.search(r"hardware (?:validation |gate )pending", release_text, re.I):
        errors.append("validated release still claims hardware validation pending")
    if errors:
        for error in errors:
            sys.stderr.write("RELEASE_VERSION_CONSISTENCY=FAIL %s\n" % error)
        return 1
    print("RELEASE_VERSION_CONSISTENCY=PASS version=%s validation=%s" %
          (args.version, args.expect_validation))
    return 0


if __name__ == "__main__":
    sys.exit(main())
