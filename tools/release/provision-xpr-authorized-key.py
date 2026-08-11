#!/usr/bin/env python3
"""Create a deployment-only XPR payload containing one operator SSH public key."""
from __future__ import print_function

import argparse
import gzip
import hashlib
import imp
import json
import os
import re
import sys


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
NEWC_CANDIDATES = (
    os.path.join(SCRIPT_DIR, "uos", "newc_archive.py"),
    os.path.join(SCRIPT_DIR, "..", "uos", "newc_archive.py"),
    os.path.join(SCRIPT_DIR, "..", "..", "tools", "uos", "newc_archive.py"),
)
MODULE_PATH = next((os.path.abspath(path) for path in NEWC_CANDIDATES if os.path.isfile(path)), None)
if MODULE_PATH is None:
    raise RuntimeError("newc_archive.py is not available beside this provisioner")
NEWC = imp.load_source("xpr_newc_archive", MODULE_PATH)
KEY_TYPES = set(("ssh-rsa", "ssh-ed25519"))
PRIVATE_MARKERS = (b"BEGIN OPENSSH PRIVATE KEY", b"BEGIN RSA PRIVATE KEY", b"BEGIN PRIVATE KEY")


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_public_key(path):
    if not os.path.isfile(path):
        raise RuntimeError("authorized key must be a regular file")
    if os.path.getsize(path) == 0 or os.path.getsize(path) > 16384:
        raise RuntimeError("authorized key size is invalid")
    data = open(path, "rb").read()
    if any(marker in data for marker in PRIVATE_MARKERS):
        raise RuntimeError("private key material is not accepted")
    if b"\r" in data:
        raise RuntimeError("authorized key must use a single LF-terminated line")
    lines = data.splitlines()
    if len(lines) != 1 or not lines[0]:
        raise RuntimeError("authorized key must contain exactly one non-empty line")
    try:
        text = lines[0].decode("ascii")
    except UnicodeDecodeError:
        raise RuntimeError("authorized key must be ASCII OpenSSH text")
    fields = text.split()
    if len(fields) not in (2, 3) or fields[0] not in KEY_TYPES:
        raise RuntimeError("unsupported OpenSSH public key format")
    if not re.match(r"^[A-Za-z0-9+/]+={0,2}$", fields[1]):
        raise RuntimeError("invalid OpenSSH public key encoding")
    return lines[0] + b"\n", fields[0]


def write_gzip(path, plain):
    with open(path, "wb") as handle:
        try:
            stream = gzip.GzipFile(filename="", mode="wb", fileobj=handle, mtime=0)
        except TypeError:
            stream = gzip.GzipFile(filename="", mode="wb", fileobj=handle)
        try:
            stream.write(plain)
        finally:
            stream.close()
    with open(path, "r+b") as handle:
        handle.seek(4)
        handle.write(b"\0\0\0\0")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generic-payload", required=True)
    parser.add_argument("--authorized-key", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    if os.path.exists(args.output) or os.path.exists(args.report):
        raise RuntimeError("refusing to overwrite deployment output or report")
    key, key_type = read_public_key(args.authorized_key)
    compressed = open(args.generic_payload, "rb").read()
    plain, trailing, members = NEWC.gunzip(compressed)
    if trailing:
        raise RuntimeError("generic payload has bytes after the gzip stream")
    entries, trailer_offset, archive_trailing = NEWC.parse_newc(plain)
    if archive_trailing:
        raise RuntimeError("generic payload has bytes after the newc trailer")
    names = set(entry["name"].decode("ascii") for entry in entries)
    if "root/.ssh/authorized_keys" in names:
        raise RuntimeError("generic payload already contains authorized_keys")
    if "root/.ssh" in names:
        raise RuntimeError("generic payload already contains root/.ssh")
    if "root" not in names:
        raise RuntimeError("generic payload lacks root directory")
    NEWC.append_entry(entries, "root/.ssh", 0o040700, b"")
    NEWC.append_entry(entries, "root/.ssh/authorized_keys", 0o100600, key)
    deployment_plain = NEWC.serialize(entries, b"")
    write_gzip(args.output, deployment_plain)
    report = {
        "schema": "xpr-deployment-key-provisioning-v1",
        "generic_payload_sha256": sha256(compressed),
        "generic_payload_bytes": len(compressed),
        "deployment_payload_sha256": sha256(open(args.output, "rb").read()),
        "deployment_payload_bytes": os.path.getsize(args.output),
        "key_sha256": sha256(key),
        "key_type": key_type,
        "generic_authorized_keys_present": False,
        "installed_authorized_keys_path": "/root/.ssh/authorized_keys",
        "installed_authorized_keys_mode": "0600",
        "installed_ssh_directory_mode": "0700",
        "gzip_members": members,
        "source_trailer_offset": trailer_offset,
    }
    with open(args.report, "w") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("SSH_KEY_PROVISIONING_VALIDATION=PASS key_type=%s deployment_payload_sha256=%s" %
          (key_type, report["deployment_payload_sha256"]))


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        sys.stderr.write("ERROR: %s\n" % exc)
        sys.exit(2)
