#!/usr/bin/env python3
"""Fail-closed structural validation for the XPR Toolkit SPDX 2.3 document."""

import argparse
import json
import re
import sys


def fail(message):
    print("SPDX_2_3_VALIDATION=FAIL: " + message, file=sys.stderr)
    raise SystemExit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("sbom")
    parser.add_argument("--toolkit-sha256", required=True)
    args = parser.parse_args()
    with open(args.sbom, encoding="utf-8") as handle:
        document = json.load(handle)
    if document.get("spdxVersion") != "SPDX-2.3":
        fail("spdxVersion is not SPDX-2.3")
    if document.get("dataLicense") != "CC0-1.0":
        fail("dataLicense is not CC0-1.0")
    if not document.get("creationInfo", {}).get("creators"):
        fail("missing creationInfo creators")
    ids = {"SPDXRef-DOCUMENT"}
    for section in ("packages", "files"):
        for item in document.get(section, []):
            item_id = item.get("SPDXID")
            if not item_id or item_id in ids:
                fail("missing or duplicate SPDXID")
            ids.add(item_id)
            if section == "packages":
                for key in ("name", "downloadLocation", "licenseConcluded", "licenseDeclared"):
                    if not item.get(key):
                        fail("package missing " + key)
            else:
                if not item.get("fileName") or not item.get("checksums"):
                    fail("file missing name or checksum")
    archive = next((item for item in document.get("files", [])
                    if item.get("SPDXID") == "SPDXRef-ReleaseArchive"), None)
    if archive is None:
        fail("release archive file is not modeled")
    values = {entry.get("checksumValue", "").lower() for entry in archive.get("checksums", [])
              if entry.get("algorithm") == "SHA256"}
    if args.toolkit_sha256.lower() not in values:
        fail("release archive hash does not match candidate")
    for relationship in document.get("relationships", []):
        if relationship.get("spdxElementId") not in ids or relationship.get("relatedSpdxElement") not in ids:
            fail("relationship refers to an unknown SPDXID")
        if not re.fullmatch(r"[A-Z_]+", relationship.get("relationshipType", "")):
            fail("invalid relationship type")
    print("SPDX_2_3_VALIDATION=PASS")


if __name__ == "__main__":
    main()
