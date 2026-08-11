#!/usr/bin/env python3
"""Fail closed when the staged binary release lacks its declared notices."""
from __future__ import print_function

import argparse
import json
import os
import re
import sys


def fail(message):
    print("LICENSE_BUNDLE_ERROR=" + message, file=sys.stderr)
    return 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--notices", default="manifests/third-party-notices.json")
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    notices_path = os.path.join(root, args.notices)
    if not os.path.isfile(notices_path):
        return fail("missing notice manifest: " + args.notices)
    with open(notices_path, "r") as handle:
        notices = json.load(handle)
    errors = []
    for component in notices.get("components", []):
        license_paths = [item.strip() for item in component.get("license_file", "").split(";")]
        for license_path in license_paths:
            candidate = os.path.join(root, license_path)
            if not license_path or not os.path.isfile(candidate) or os.path.getsize(candidate) == 0:
                errors.append(component.get("component", "unknown") + ": " + license_path)
    notice = os.path.join(root, "NOTICE.md")
    if not os.path.isfile(notice):
        errors.append("NOTICE.md missing")
    else:
        text = open(notice, "r").read()
        for referenced in re.findall(r"LICENSES/[A-Za-z0-9._+-]+", text):
            if not os.path.isfile(os.path.join(root, referenced)):
                errors.append("NOTICE.md references missing " + referenced)
    if errors:
        for error in errors:
            print("LICENSE_BUNDLE_ERROR=" + error, file=sys.stderr)
        return 1
    print("LICENSE_BUNDLE_VALIDATION=PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
