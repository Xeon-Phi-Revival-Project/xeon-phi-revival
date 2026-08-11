#!/usr/bin/env python3
"""Create a deployment-only XPR payload containing one operator SSH public key."""
from __future__ import print_function

import argparse
import base64
import gzip
import hashlib
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
try:
    from importlib import util as importlib_util
except ImportError:  # CentOS 7's system Python is 2.7.
    import imp
    NEWC = imp.load_source("xpr_newc_archive", MODULE_PATH)
else:
    spec = importlib_util.spec_from_file_location("xpr_newc_archive", MODULE_PATH)
    NEWC = importlib_util.module_from_spec(spec)
    spec.loader.exec_module(NEWC)
# RC5 deliberately supports only the RSA form proven with the project Dropbear
# build. Do not advertise an algorithm unless the release validation covers it.
KEY_TYPES = set(("ssh-rsa",))
PRIVATE_MARKERS = (b"BEGIN OPENSSH PRIVATE KEY", b"BEGIN RSA PRIVATE KEY", b"BEGIN PRIVATE KEY")


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def _u32(data, offset):
    if offset + 4 > len(data):
        raise RuntimeError("truncated SSH wire-format length")
    return ((ord(data[offset:offset + 1]) << 24) |
            (ord(data[offset + 1:offset + 2]) << 16) |
            (ord(data[offset + 2:offset + 3]) << 8) |
            ord(data[offset + 3:offset + 4])), offset + 4


def _string(data, offset, field):
    length, offset = _u32(data, offset)
    if length > len(data) - offset:
        raise RuntimeError("truncated SSH wire-format %s" % field)
    return data[offset:offset + length], offset + length


def _positive_mpint(data, field, minimum_bytes=1, maximum_bytes=8192):
    if len(data) < minimum_bytes or len(data) > maximum_bytes:
        raise RuntimeError("invalid SSH RSA %s length" % field)
    if data == b"\0" * len(data):
        raise RuntimeError("SSH RSA %s must be non-zero" % field)
    # RFC 4251 mpint: a leading zero is only valid when preserving positivity.
    if len(data) > 1 and data[:1] == b"\0" and not (ord(data[1:2]) & 0x80):
        raise RuntimeError("non-canonical SSH RSA %s" % field)
    if data[:1] != b"\0" and (ord(data[:1]) & 0x80):
        raise RuntimeError("negative SSH RSA %s" % field)


def validate_public_key_blob(key_type, encoded):
    try:
        blob = base64.b64decode(encoded.encode("ascii"))
    except (TypeError, ValueError):
        raise RuntimeError("invalid OpenSSH public key base64")
    if not blob or len(blob) > 16384:
        raise RuntimeError("invalid OpenSSH public key blob size")
    wire_type, offset = _string(blob, 0, "key type")
    try:
        wire_type = wire_type.decode("ascii")
    except UnicodeDecodeError:
        raise RuntimeError("non-ASCII SSH wire-format key type")
    if wire_type != key_type:
        raise RuntimeError("declared and wire-format SSH key types differ")
    if key_type == "ssh-rsa":
        exponent, offset = _string(blob, offset, "RSA exponent")
        modulus, offset = _string(blob, offset, "RSA modulus")
        _positive_mpint(exponent, "exponent", maximum_bytes=8)
        _positive_mpint(modulus, "modulus", minimum_bytes=128)
        value = 0
        for octet in bytearray(exponent):
            value = (value << 8) | octet
        if value < 3 or value % 2 == 0:
            raise RuntimeError("invalid SSH RSA exponent")
    else:
        raise RuntimeError("unsupported OpenSSH public key type")
    if offset != len(blob):
        raise RuntimeError("unexpected trailing SSH wire-format data")


def read_public_key(path):
    if not os.path.isfile(path):
        raise RuntimeError("authorized key must be a regular file")
    if os.path.getsize(path) == 0 or os.path.getsize(path) > 16384:
        raise RuntimeError("authorized key size is invalid")
    data = open(path, "rb").read()
    if any(marker in data for marker in PRIVATE_MARKERS):
        raise RuntimeError("private key material is not accepted")
    if b"\r" in data or not data.endswith(b"\n"):
        raise RuntimeError("authorized key must use a single LF-terminated line")
    lines = data.splitlines()
    if len(lines) != 1 or not lines[0]:
        raise RuntimeError("authorized key must contain exactly one non-empty line")
    try:
        text = lines[0].decode("ascii")
    except UnicodeDecodeError:
        raise RuntimeError("authorized key must be ASCII OpenSSH text")
    fields = text.split(None, 2)
    if len(fields) not in (2, 3) or fields[0] not in KEY_TYPES:
        raise RuntimeError("unsupported OpenSSH public key format")
    if not re.match(r"^[A-Za-z0-9+/]+={0,2}$", fields[1]):
        raise RuntimeError("invalid OpenSSH public key encoding")
    if len(fields) == 3 and any(ord(character) < 0x20 or ord(character) == 0x7f for character in fields[2]):
        raise RuntimeError("invalid OpenSSH public key comment")
    validate_public_key_blob(fields[0], fields[1])
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


def gzip_bytes(plain):
    from io import BytesIO
    output = BytesIO()
    try:
        stream = gzip.GzipFile(filename="", mode="wb", fileobj=output, mtime=0)
    except TypeError:
        stream = gzip.GzipFile(filename="", mode="wb", fileobj=output)
    try:
        stream.write(plain)
    finally:
        stream.close()
    data = output.getvalue()
    return data[:4] + b"\0\0\0\0" + data[8:]


def provision_payload(compressed, key, label):
    plain, trailing, members = NEWC.gunzip(compressed)
    if trailing:
        raise RuntimeError("%s has bytes after the gzip stream" % label)
    entries, trailer_offset, archive_trailing = NEWC.parse_newc(plain)
    if archive_trailing:
        raise RuntimeError("%s has bytes after the newc trailer" % label)
    names = set(entry["name"].decode("ascii") for entry in entries)
    if "root/.ssh/authorized_keys" in names or "root/.ssh" in names:
        raise RuntimeError("%s already contains root SSH authorization" % label)
    if "root" not in names:
        raise RuntimeError("%s lacks root directory" % label)
    NEWC.append_entry(entries, "root/.ssh", 0o040700, b"")
    NEWC.append_entry(entries, "root/.ssh/authorized_keys", 0o100600, key)
    return gzip_bytes(NEWC.serialize(entries, b"")), members, trailer_offset


def provision_bootstrap(compressed, key):
    plain, trailing, members = NEWC.gunzip(compressed)
    if trailing:
        raise RuntimeError("generic bootstrap has bytes after the gzip stream")
    entries, trailer_offset, archive_trailing = NEWC.parse_newc(plain)
    if archive_trailing:
        raise RuntimeError("generic bootstrap has bytes after the newc trailer")
    matches = [entry for entry in entries if entry["name"] == b"xpr-rootfs.cpio.gz"]
    if len(matches) != 1:
        raise RuntimeError("generic bootstrap lacks exactly one nested xpr-rootfs.cpio.gz")
    nested, nested_members, nested_trailer = provision_payload(matches[0]["payload"], key, "nested bootstrap root")
    NEWC.replace_payload(matches[0], nested)
    return gzip_bytes(NEWC.serialize(entries, b"")), members, trailer_offset, nested_members, nested_trailer


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generic-payload", required=True)
    parser.add_argument("--authorized-key", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--generic-bootstrap", help="generic outer Base CPIO to provision for bootstrap SSH")
    parser.add_argument("--bootstrap-output", help="deployment-only outer Base CPIO output")
    args = parser.parse_args()
    if os.path.exists(args.output) or os.path.exists(args.report):
        raise RuntimeError("refusing to overwrite deployment output or report")
    if bool(args.generic_bootstrap) != bool(args.bootstrap_output):
        raise RuntimeError("--generic-bootstrap and --bootstrap-output must be supplied together")
    if args.bootstrap_output and os.path.exists(args.bootstrap_output):
        raise RuntimeError("refusing to overwrite deployment bootstrap output")
    key, key_type = read_public_key(args.authorized_key)
    compressed = open(args.generic_payload, "rb").read()
    deployment_payload, members, trailer_offset = provision_payload(compressed, key, "generic payload")
    open(args.output, "wb").write(deployment_payload)
    report = {
        "schema": "xpr-deployment-key-provisioning-v1",
        "generic_payload_sha256": sha256(compressed),
        "generic_payload_bytes": len(compressed),
        "deployment_payload_sha256": sha256(deployment_payload),
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
    if args.generic_bootstrap:
        bootstrap = open(args.generic_bootstrap, "rb").read()
        deployment_bootstrap, outer_members, outer_trailer, nested_members, nested_trailer = provision_bootstrap(bootstrap, key)
        open(args.bootstrap_output, "wb").write(deployment_bootstrap)
        report.update({
            "generic_bootstrap_sha256": sha256(bootstrap),
            "deployment_bootstrap_sha256": sha256(deployment_bootstrap),
            "deployment_bootstrap_bytes": len(deployment_bootstrap),
            "bootstrap_outer_gzip_members": outer_members,
            "bootstrap_outer_trailer_offset": outer_trailer,
            "bootstrap_nested_gzip_members": nested_members,
            "bootstrap_nested_trailer_offset": nested_trailer,
        })
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
