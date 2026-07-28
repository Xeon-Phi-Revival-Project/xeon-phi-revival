# Security Policy

## Reporting Security Issues

Do not publish credentials, private keys, private hostnames, serial numbers, or
private lab network details in issues, pull requests, discussions, or commits.

If you find a security issue in project scripts or documentation, open a GitHub
security advisory if the repository has that feature enabled. If advisories are
not available yet, contact the repository maintainers through a private channel
before publishing exploit details.

## Scope

In scope:

- Project-authored scripts and test programs.
- Documentation that could accidentally expose private operational details.
- Publication-boundary problems such as proprietary payloads or secrets in
  manifests.

Out of scope:

- Security support for Intel MPSS, Intel compilers, firmware, or stock uOS
  components.
- Vulnerabilities in third-party software that this project does not ship.

This is experimental preservation work for legacy hardware. Treat all scripts as
lab tools and review them before running on production systems.
