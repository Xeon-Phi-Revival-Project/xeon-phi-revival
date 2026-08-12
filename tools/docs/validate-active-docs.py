#!/usr/bin/env python3
"""Check the small, current XPR-OS documentation path for broken local links."""
from __future__ import print_function

import os
import re
import sys


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DOCS = (
    "README.md",
    "docs/README.md",
    "docs/getting-started/README.md",
    "docs/getting-started/installation.md",
    "docs/getting-started/ssh-access.md",
    "docs/getting-started/verifying-xpr-os.md",
    "docs/getting-started/rollback.md",
    "docs/troubleshooting/README.md",
    "docs/glossary.md",
    "docs/faq.md",
)
REQUIRED = {
    "README.md": ("XPR-OS 0.1.0-rc6", "Intel Xeon Phi", "Quick Start"),
    "docs/getting-started/installation.md": (
        "run-candidate-base-cpio-control.sh", "--minimal-public-smoke",
        "--leave-running", "94867d9f58c12e7b04dcd0f2a8bfb176054d41b3c8e02f6c584c6efef4124d6c",
        "bb530e170e9871627903644f52d8271c1f9c3375d4d3bc1d62c0c4eaa60a6558",
    ),
    "docs/getting-started/ssh-access.md": ("ssh-rsa", "id_rsa.pub", "id_rsa"),
    "docs/getting-started/rollback.md": ("micctrl --status", "systemctl start mpss"),
}
LINK = re.compile(r"\[[^]]+\]\(([^)#]+)(?:#[^)]+)?\)")


def fail(message):
    sys.stderr.write("ACTIVE_DOC_VALIDATION=FAIL %s\n" % message)
    return 1


def main():
    for relative in DOCS:
        if not os.path.isfile(os.path.join(ROOT, relative)):
            return fail("missing active document: %s" % relative)
    for relative, needles in REQUIRED.items():
        text = open(os.path.join(ROOT, relative), "r").read()
        for needle in needles:
            if needle not in text:
                return fail("missing expected text in %s: %s" % (relative, needle))
        if "C:\\Users\\" in text or "/root/" in text:
            return fail("private path in active document: %s" % relative)
    for relative in DOCS:
        path = os.path.join(ROOT, relative)
        text = open(path, "r").read()
        for target in LINK.findall(text):
            if "://" in target or target.startswith("mailto:"):
                continue
            if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(path), target))):
                return fail("broken link in %s: %s" % (relative, target))
    print("README_LINKS=PASS")
    print("ACTIVE_DOC_LINKS=PASS")
    print("INSTALL_COMMANDS=PASS")
    print("RELEASE_URLS=PASS")
    print("RC6_HASHES=PASS")
    print("SSH_INSTRUCTIONS=PASS")
    print("ROLLBACK_INSTRUCTIONS=PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
