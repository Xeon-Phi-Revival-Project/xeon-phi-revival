#!/usr/bin/env python3
"""Append deterministic padding to a gzip-compressed newc initramfs."""

import argparse
import gzip
import hashlib
import os
import struct

MAGIC = b"070701"
HEADER = 110
TRAILER = b"TRAILER!!!"


def align4(value):
    return (value + 3) & ~3


def payload(length, pattern):
    if pattern == "zero":
        return b"\0" * length
    chunks, counter = [], 0
    while length > 0:
        chunk = hashlib.sha256(("xpr-padding-%08d" % counter).encode("ascii")).digest()
        chunks.append(chunk[:min(length, len(chunk))])
        length -= len(chunks[-1])
        counter += 1
    return b"".join(chunks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--target-unpacked-bytes", type=int, required=True)
    parser.add_argument("--pattern", choices=("zero", "hash"), required=True)
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()
    compressed = open(args.source, "rb").read()
    with gzip.GzipFile(args.source, "rb") as source_gzip:
        plain = source_gzip.read()
    trailer = plain.rfind(MAGIC + b"00000000")
    if trailer < 0 or TRAILER not in plain[trailer:trailer + HEADER + 64]:
        raise ValueError("TRAILER!!! entry not found")
    name = ("xpr-padding/%s.bin" % args.pattern).encode("ascii")
    prefix = align4(HEADER + len(name) + 1)
    needed = args.target_unpacked_bytes - len(plain) - prefix
    if needed < 0:
        raise ValueError("target is smaller than source")
    needed -= needed % 4
    header_values = (0, 0o100644, 0, 0, 1, 0, needed, 0, 0, 0, 0, len(name) + 1, 0)
    header = MAGIC + b"".join(("%08X" % value).encode("ascii") for value in header_values)
    entry = header + name + b"\0"
    entry += b"\0" * (align4(len(entry)) - len(entry))
    entry += payload(needed, args.pattern)
    entry += b"\0" * (align4(len(entry)) - len(entry))
    result = plain[:trailer] + entry + plain[trailer:]
    with open(args.output, "wb") as handle:
        with gzip.GzipFile(filename="", mode="wb", fileobj=handle, mtime=0, compresslevel=9) as gz:
            gz.write(result)
    with open(args.manifest, "w") as handle:
        handle.write("source_sha256=%s\n" % hashlib.sha256(compressed).hexdigest())
        handle.write("output_sha256=%s\n" % hashlib.sha256(open(args.output, "rb").read()).hexdigest())
        handle.write("pattern=%s\npadding_bytes=%d\nunpacked_bytes=%d\ncompressed_bytes=%d\n" %
                     (args.pattern, needed, len(result), os.path.getsize(args.output)))


if __name__ == "__main__":
    main()
