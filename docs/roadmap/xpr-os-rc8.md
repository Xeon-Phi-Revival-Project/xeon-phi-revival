# XPR-OS RC8 Development Roadmap

RC8 development builds on frozen, published `v0.1.0-rc7`. This is an
engineering roadmap, not a release commitment.

## P0

- Reversible XPR-managed `ssh mic0` routing while retaining `ssh xpr-mic0`.
- Clear final-root readiness and status reporting in `xpr-init`.
- Repair the CPython 3.12.13 runtime layout and `_random` extension support.
- Establish `xpr-build` and validate an external-style level-0 project.
- Build and test the first real upstream library, beginning with zlib.

## P1

- Expand Python extensions from source-accounted dependencies.
- Add transparent package recipes and a composable XPR development prefix.
- Add small, evidence-driven userland conveniences.

## P2 / Stretch

- Build additional modest applications through `xpr-build`.
- Prototype a small package-installation format.
- Research Debian/Ubuntu source-package cross-build viability.
- Document a fresh-host path without overstating validation.

The separately held standalone-toolkit publication question remains outside
RC8 distribution work. No RC8 tag or release is authorized by this roadmap.
