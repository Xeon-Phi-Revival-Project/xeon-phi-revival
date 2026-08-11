#!/usr/bin/env python3
"""Generate a compact SPDX 2.3 JSON SBOM from an XPR image audit and ledger."""
import argparse
import datetime
import io
import json
import os


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", required=True)
    parser.add_argument("--ledger", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--include-component", action="append", default=[])
    parser.add_argument("--external-file", action="append", default=[],
                        help="COMPONENT:PATH=SHA256 for a release file outside the audited root")
    args = parser.parse_args()
    audit = json.load(io.open(args.audit, encoding="utf-8"))
    ledger = json.load(io.open(args.ledger, encoding="utf-8"))
    used = set(row.get("component") for row in audit.get("inventory", []) if row.get("component"))
    used.update(args.include_component)
    packages = []
    for item in ledger.get("components", []):
        if item.get("id") not in used:
            continue
        packages.append({"SPDXID": item["spdx_id"], "name": item["id"],
                         "versionInfo": item["version"], "downloadLocation": item["source_url"],
                         "licenseConcluded": item["license"], "licenseDeclared": item["license"],
                         "copyrightText": "NOASSERTION", "supplier": "NOASSERTION"})
    files = []
    relationships = []
    component_spdx = dict((item.get("id"), item.get("spdx_id"))
                          for item in ledger.get("components", []))
    for row in audit.get("inventory", []):
        if row.get("component"):
            file_id = "SPDXRef-File-" + row["sha256"][:16]
            files.append({"SPDXID": file_id, "fileName": "." + row["path"],
                          "checksums": [{"algorithm": "SHA256", "checksumValue": row["sha256"]}],
                          "licenseConcluded": "NOASSERTION", "copyrightText": "NOASSERTION"})
            relationships.append({"spdxElementId": component_spdx[row["component"]],
                                  "relationshipType": "CONTAINS", "relatedSpdxElement": file_id})
    for value in args.external_file:
        try:
            component, remainder = value.split(":", 1)
            path, sha256 = remainder.rsplit("=", 1)
        except ValueError:
            parser.error("invalid --external-file, expected COMPONENT:PATH=SHA256")
        if component not in component_spdx or len(sha256) != 64:
            parser.error("invalid component or SHA256 in --external-file: " + value)
        file_id = "SPDXRef-File-" + sha256[:16]
        files.append({"SPDXID": file_id, "fileName": path,
                      "checksums": [{"algorithm": "SHA256", "checksumValue": sha256}],
                      "licenseConcluded": "NOASSERTION", "copyrightText": "NOASSERTION"})
        relationships.append({"spdxElementId": component_spdx[component],
                              "relationshipType": "CONTAINS", "relatedSpdxElement": file_id})
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    created = (datetime.datetime.utcfromtimestamp(int(epoch)) if epoch else
               datetime.datetime.utcnow()).replace(microsecond=0).isoformat() + "Z"
    doc = {"spdxVersion": "SPDX-2.3", "dataLicense": "CC0-1.0", "SPDXID": "SPDXRef-DOCUMENT",
           "name": "xpr-k1om-uos-prebuilt", "documentNamespace": "https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/spdx/" + audit.get("artifact", {}).get("sha256", "rootfs"),
           "creationInfo": {"created": created, "creators": ["Tool: xpr generate-spdx-sbom.py"]},
           "packages": packages, "files": files, "relationships": relationships}
    with open(args.output, "w") as handle:
        json.dump(doc, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("SPDX packages=%d files=%d output=%s" % (len(packages), len(files), args.output))


if __name__ == "__main__":
    main()
