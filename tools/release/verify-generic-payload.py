#!/usr/bin/env python3
"""Verify that a generic XPR payload contains no pre-authorized SSH key."""
from __future__ import print_function

import argparse
import imp
import os
import sys


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
NEWC = imp.load_source("xpr_newc_archive", os.path.join(ROOT, "tools", "uos", "newc_archive.py"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--payload", required=True)
    args = parser.parse_args()
    raw = open(args.payload, "rb").read()
    plain, trailing, members = NEWC.gunzip(raw)
    if trailing:
        raise RuntimeError("payload has bytes after gzip stream")
    entries, trailer_offset, archive_trailing = NEWC.parse_newc(plain)
    if archive_trailing:
        raise RuntimeError("payload has bytes after newc trailer")
    names = set(entry["name"].decode("utf-8", "replace") for entry in entries)
    forbidden = sorted(name for name in names if name.endswith("/authorized_keys") or name == "authorized_keys")
    if forbidden:
        raise RuntimeError("fixed authorized_keys rejected: " + ", ".join(forbidden))
    for entry in entries:
        if b"BEGIN OPENSSH PRIVATE KEY" in entry["payload"] or b"BEGIN RSA PRIVATE KEY" in entry["payload"]:
            raise RuntimeError("private key material rejected: " + entry["name"].decode("utf-8", "replace"))
    print("NO_FIXED_AUTHORIZED_KEYS=PASS members=%d trailer_offset=%d" % (len(entries), trailer_offset))


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        sys.stderr.write("ERROR: %s\n" % exc)
        sys.exit(2)
