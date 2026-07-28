# Intel MIC Compiler Track

The fastest path to the first native smoke tests is Intel Composer XE with
Knights Corner support, using `icc -mmic` / `icpc -mmic`.

Do not commit Intel compiler installers, RPMs, licenses, or proprietary runtime
payloads here. This repository should only contain install notes, wrapper
scripts, detection scripts, and manifests.

Current CentOS host state:

- Host GCC and G++ are installed for build helpers.
- Installed host build tools include binutils headers, CMake, autotools,
  bison, flex, libtool, and related devel packages.
- MPSS 3.4.10 is installed.
- `mpss-sdk-k1om-3.4.10-1.x86_64` is installed and validates the GCC/binutils
  K1OM lane.
- No Intel `icc` / `icpc` compiler is currently installed.
- No `x86_64-k1om-linux-gcc` alternate-prefix toolchain is currently installed.
- The working MPSS SDK prefix is `k1om-mpss-linux-*`.

Host tool versions observed after setup:

- GCC/G++: 4.8.5, Red Hat 4.8.5-16
- binutils: 2.25.1-32.base.el7_4.2
- CMake: 2.8.12.2
- Autoconf: 2.69
- Automake: 1.13.4
- Bison: 3.0.4
- Flex: 2.5.37

The runner at `tools/runners/run-hello-knc.sh` will use:

1. `KNC_CC` when explicitly set.
2. `icc -mmic` if `icc` is available.
3. `x86_64-k1om-linux-gcc` if available.
4. `k1om-mpss-linux-gcc` if the MPSS SDK environment is sourced.

## Intel Composer Reference Lane

Intel Composer XE is no longer required for the first native K1OM milestone,
but it remains useful as a historical reference compiler if a user-supplied,
properly licensed copy is available. Once available on the CentOS host, test:

```bash
source /opt/intel/bin/compilervars.sh intel64
icc -mmic -v
tools/runners/run-hello-knc.sh
```

Without Intel Composer, continue the MPSS SDK and open-toolchain tracks.
