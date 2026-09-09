#!/usr/bin/env python
"""Deployment-only SSH host identity and invoking-user alias (Python 2.7/3)."""
from __future__ import print_function

import argparse
import base64
import os
import pwd
import re
import stat
import struct
import subprocess
import sys
import tempfile

TYPE = b"ecdsa-sha2-nistp256"


def field(data, offset):
    if offset + 4 > len(data):
        raise ValueError("truncated SSH field")
    size = struct.unpack(">I", data[offset:offset + 4])[0]
    end = offset + 4 + size
    if end > len(data):
        raise ValueError("truncated SSH field data")
    return data[offset + 4:end], end


def pack(data):
    return struct.pack(">I", len(data)) + data


def dropbear_key(private, public):
    # OpenSSH PROTOCOL.key; Dropbear 2022.83 ecdsa.c:
    # buf_put_ecdsa_priv_key = SSH public fields followed by the scalar mpint.
    lines = private.splitlines()
    if lines[0] != b"-----BEGIN OPENSSH PRIVATE KEY-----" or lines[-1] != b"-----END OPENSSH PRIVATE KEY-----":
        raise ValueError("expected an OpenSSH private key")
    data = base64.b64decode(b"".join(lines[1:-1]))
    if not data.startswith(b"openssh-key-v1\0"):
        raise ValueError("invalid OpenSSH key header")
    offset = 15
    for expected in (b"none", b"none", b""):
        value, offset = field(data, offset)
        if value != expected:
            raise ValueError("only unencrypted deployment host keys are supported")
    if data[offset:offset + 4] != b"\0\0\0\1":
        raise ValueError("expected one host key")
    pub, offset = field(data, offset + 4)
    body, end = field(data, offset)
    if end != len(data) or body[:4] != body[4:8]:
        raise ValueError("invalid private-key container")
    offset = 8
    fields = []
    for unused in range(4):
        value, offset = field(body, offset)
        fields.append(value)
    if fields[0] != TYPE or fields[1] != b"nistp256" or len(fields[2]) != 65 or fields[2][:1] != b"\4":
        raise ValueError("expected an ECDSA P-256 host key")
    scalar = fields[3]
    if not 1 <= len(scalar) <= 33 or ord(scalar[:1]) & 128 or not any(bytearray(scalar)):
        raise ValueError("invalid ECDSA private scalar")
    comment, offset = field(body, offset)
    padding = body[offset:]
    if not padding or padding != bytes(bytearray(range(1, len(padding) + 1))):
        raise ValueError("invalid OpenSSH key padding")
    expected_pub = b"".join(pack(value) for value in fields[:3])
    if pub != expected_pub or base64.b64decode(public.split()[1]) != pub:
        raise ValueError("host public/private identity mismatch")
    return b"".join(pack(value) for value in fields)


def regular(path):
    if os.path.lexists(path):
        info = os.lstat(path)
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_uid != os.geteuid():
            raise ValueError("unsafe SSH file: " + path)


def directory(path):
    if os.path.lexists(path):
        info = os.lstat(path)
        if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.geteuid() or info.st_mode & 0o022:
            raise ValueError("unsafe SSH directory: " + path)
    else:
        os.mkdir(path, 0o700)


def write(path, data):
    regular(path)
    if os.path.exists(path) and open(path, "rb").read() == data:
        os.chmod(path, 0o600)
        return
    fd, temporary = tempfile.mkstemp(prefix=".xpr-", dir=os.path.dirname(path))
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
        os.rename(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def server(args):
    directory(args.directory)
    key = os.path.join(args.directory, "host_ecdsa")
    regular(key)
    regular(key + ".pub")
    if os.path.exists(key) != os.path.exists(key + ".pub"):
        raise ValueError("incomplete deployment server key pair; refusing replacement")
    if not os.path.exists(key):
        subprocess.check_call(["ssh-keygen", "-q", "-t", "ecdsa", "-b", "256", "-o", "-N", "", "-f", key, "-C", "XPR deployment host"])
    os.chmod(key, 0o600)
    public = b" ".join(subprocess.check_output(["ssh-keygen", "-y", "-P", "", "-f", key]).split()[:2])
    if public.split()[:2] != open(key + ".pub", "rb").read().split()[:2]:
        raise ValueError("deployment server public key does not match private key")
    converted = dropbear_key(open(key, "rb").read(), public)
    write(os.path.join(args.directory, "dropbear_ecdsa_host_key"), converted)
    write(os.path.join(args.directory, "known_hosts"), args.alias.encode("ascii") + b" " + public + b"\n")
    print(public.decode("ascii"))


def quoted(value):
    if any(ord(c) < 32 or ord(c) == 127 for c in value) or any(c in value for c in '"\\%'):
        raise ValueError("unsupported SSH path characters")
    return '"' + value + '"'


def client(args):
    # Never perform privileged writes into an invoking user's mutable home.
    if args.user:
        entry = pwd.getpwnam(args.user)
        if os.geteuid() == 0 and entry.pw_uid != 0:
            os.initgroups(args.user, entry.pw_gid)
            os.setgid(entry.pw_gid)
            os.setuid(entry.pw_uid)
        elif os.geteuid() != entry.pw_uid:
            raise ValueError("SSH setup must run as the invoking user")
        if args.home != entry.pw_dir:
            raise ValueError("invoking home does not match passwd entry")
    ssh_dir = os.path.join(args.home, ".ssh")
    directory(ssh_dir)
    config = os.path.join(ssh_dir, "config")
    known = os.path.join(ssh_dir, "xpr_os_known_hosts")
    regular(config)
    regular(known)
    old = open(config, "rb").read() if os.path.exists(config) else b""
    begin = ("# BEGIN XPR-OS MANAGED SSH " + args.alias + "\n").encode("ascii")
    end = ("# END XPR-OS MANAGED SSH " + args.alias + "\n").encode("ascii")
    remainder = old
    if begin in old or end in old:
        if old.count(begin) != 1 or old.count(end) != 1 or not old.startswith(begin):
            raise ValueError("malformed or relocated XPR SSH block; refusing rewrite")
        remainder = old[len(begin):].split(end, 1)[1]
    if re.search(br"(?im)^\s*Host\s+[^\r\n]*\bxpr-mic[0-9]+\b", remainder):
        raise ValueError("existing unmanaged XPR SSH alias; refusing conflict")
    public = args.host_public_key.encode("ascii")
    if public.split()[0] != TYPE or len(public.split()) != 2:
        raise ValueError("invalid server public key")
    block = ("Host %s\n    HostName %s\n    User root\n"
             "    IdentityFile %s\n    IdentitiesOnly yes\n    BatchMode yes\n"
             "    PasswordAuthentication no\n    StrictHostKeyChecking yes\n"
             "    HostKeyAlias %s\n    HostKeyAlgorithms ecdsa-sha2-nistp256\n"
             "    CheckHostIP no\n    UserKnownHostsFile %s\n"
             "    GlobalKnownHostsFile %s\n    PubkeyAcceptedKeyTypes +ssh-rsa\n"
             "Host *\n" % (args.alias, args.hostname, quoted(args.identity), args.alias,
                            quoted(known), quoted(known))).encode("utf-8")
    updated = begin + block + end + remainder
    fd, temporary = tempfile.mkstemp(prefix=".xpr-check-", dir=ssh_dir)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(updated)
        subprocess.check_output(["ssh", "-G", "-F", temporary, args.alias], stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError:
        raise ValueError("SSH configuration validation failed; original configuration retained")
    finally:
        os.unlink(temporary)
    backup = config + ".pre-xpr"
    if os.path.exists(config) and not os.path.lexists(backup):
        fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "wb") as stream:
            stream.write(old)
    previous = open(known, "rb").read().splitlines(True) if os.path.exists(known) else []
    record = args.alias.encode("ascii") + b" " + public + b"\n"
    previous = [line for line in previous if line.split(None, 1)[:1] != [args.alias.encode("ascii")]]
    retained = b"".join(previous)
    if retained and not retained.endswith(b"\n"):
        retained += b"\n"
    write(known, retained + record)
    write(config, updated)
    print("XPR_SSH_ALIAS=ssh " + args.alias)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("server", "client"))
    parser.add_argument("--alias", required=True)
    parser.add_argument("--directory")
    parser.add_argument("--user")
    parser.add_argument("--home")
    parser.add_argument("--identity")
    parser.add_argument("--hostname")
    parser.add_argument("--host-public-key")
    args = parser.parse_args()
    if not re.match(r"^xpr-mic[0-9]+$", args.alias):
        raise ValueError("unsupported MIC alias")
    if args.mode == "server":
        server(args)
    else:
        if not re.match(r"^[0-9a-fA-F:.]+$", args.hostname):
            raise ValueError("expected a numeric MIC address")
        client(args)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as exc:
        sys.stderr.write("xpr-init SSH setup: %s\n" % exc)
        sys.exit(2)
