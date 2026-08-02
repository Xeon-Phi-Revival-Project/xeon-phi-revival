# Next Source Recovery Actions

1. Request the exact SRPM from Intel or the current rights holder using
   `missing-source-request.md`.
2. Ask former MPSS distribution mirrors, HPC centers, and institutional
   archive maintainers for the exact SRPM filename and repodata path.
3. If a candidate archive is supplied, hash and inventory it without executing
   scripts; require the KNC kernel tree, config, and patch series before build.
4. Do not substitute generic Linux 2.6.38, later MPSS releases, or Linux 4.x
   module ports for the observed `2.6.38.8+mpss3.4.10` ABI.
