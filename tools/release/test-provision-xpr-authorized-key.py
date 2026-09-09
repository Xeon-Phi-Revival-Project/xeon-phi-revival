#!/usr/bin/env python3
"""Regression tests for strict deployment-key validation."""
from __future__ import print_function

import base64
import importlib.util
import os
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("xpr_provision", os.path.join(HERE, "provision-xpr-authorized-key.py"))
PROVISION = importlib.util.module_from_spec(spec)
spec.loader.exec_module(PROVISION)


def string(data):
    return len(data).to_bytes(4, "big") + data


def rsa_blob(extra=b""):
    return string(b"ssh-rsa") + string(b"\x01\x00\x01") + string(b"\x01" + b"\x01" * 128) + extra


def record(blob, comment=b"operator"):
    return b"ssh-rsa " + base64.b64encode(blob) + b" " + comment + b"\n"


def assert_case(label, payload, accepted):
    fd, path = tempfile.mkstemp(prefix="xpr-key-")
    try:
        os.write(fd, payload)
        os.close(fd)
        fd = None
        try:
            PROVISION.read_public_key(path)
            result = True
        except RuntimeError:
            result = False
        if result != accepted:
            raise AssertionError("%s expected accepted=%s" % (label, accepted))
    finally:
        if fd is not None:
            os.close(fd)
        os.unlink(path)


def main():
    valid = rsa_blob()
    cases = (
        ("valid-rsa", record(valid), True),
        ("empty", b"", False),
        ("whitespace", b" \n", False),
        ("text", b"hello\n", False),
        ("invalid-base64", b"ssh-rsa !!!\n", False),
        ("wrong-wire-type", b"ssh-rsa " + base64.b64encode(string(b"ssh-ed25519") + string(b"x" * 32)) + b"\n", False),
        ("truncated", record(valid[:-1]), False),
        ("bad-length", b"ssh-rsa " + base64.b64encode(b"\0\0\xff\xffssh-rsa") + b"\n", False),
        ("garbage", record(valid + b"garbage"), False),
        ("private-openssh", b"-----BEGIN OPENSSH PRIVATE KEY-----\n", False),
        ("private-pem", b"-----BEGIN PRIVATE KEY-----\n", False),
        ("multiline", record(valid) + record(valid), False),
        ("unsupported", b"ssh-ed25519 " + base64.b64encode(string(b"ssh-ed25519") + string(b"x" * 32)) + b"\n", False),
        ("oversized", b"ssh-rsa " + b"A" * 17000 + b"\n", False),
    )
    for label, payload, accepted in cases:
        assert_case(label, payload, accepted)
    print("SSH_KEY_NEGATIVE_VALIDATION=PASS cases=%d" % len(cases))
    host_key = b"deployment-fixture-not-a-real-private-key"
    for mode in (0o040700, 0o120777):
        entries = [PROVISION.NEWC.new_entry("root", 0o040700, b""),
                   PROVISION.NEWC.new_entry("etc/dropbear", mode, b""),
                   PROVISION.NEWC.new_entry("TRAILER!!!", 0, b"")]
        generic = PROVISION.gzip_bytes(PROVISION.NEWC.serialize(entries, b""))
        try:
            deployed, unused, unused2 = PROVISION.provision_payload(generic, record(valid), "fixture", host_key)
        except RuntimeError:
            assert mode == 0o120777
            continue
        assert mode == 0o040700
        plain, unused, unused2 = PROVISION.NEWC.gunzip(deployed)
        result, unused, unused2 = PROVISION.NEWC.parse_newc(plain)
        hosts = [e for e in result if e["name"] == b"etc/dropbear/dropbear_ecdsa_host_key"]
        assert len(hosts) == 1 and hosts[0]["fields"][1] == 0o100600
        assert hosts[0]["payload"] == host_key
        assert PROVISION.NEWC.serialize(entries, b"") == PROVISION.NEWC.gunzip(generic)[0]
    print("SSH_HOST_KEY_PROVISIONING_TESTS=PASS")


if __name__ == "__main__":
    main()
