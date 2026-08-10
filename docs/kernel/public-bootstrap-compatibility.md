# Public Bootstrap Compatibility

This note records the host-only comparison made before the second public-stack
hardware attempt. It does not claim that the resulting Base CPIO has passed
hardware validation.

## Compared Archives

| Archive | SHA-256 | Compressed bytes | Members |
| --- | --- | ---: | ---: |
| Accepted Base CPIO | `42b7560f8dcc277f1d976e40db57668caedb749125e66171281ea8ba755e3bef` | 29,578,142 | 1,802 |
| Incorrect inner-root Base CPIO | `52ed58c3b5980b5ed7cc46cd7c3543331f4881437fa6023984444300056f5620` | 8,212,335 | 76 |
| Reconstructed outer Base CPIO | `bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779` | 9,083,911 | 22 |

The 76-member archive was the staged bootstrap root used directly as an MPSS
Base CPIO. It lacked root `/init`; the accepted archive has an executable
project root `/init` whose interpreter is `/xpr-tools/busybox`.

## Required Pre-Marker Layout

Before `XPR_CLEAN_ROOT_EARLY_INIT_ENTERED`, the accepted project init uses:

- `/init`, mode `0755`, `#!/xpr-tools/busybox sh`;
- `/xpr-tools/busybox`, a static K1OM BusyBox;
- `/xpr-rootfs.cpio.gz`, the staged bootstrap root unpacked after module load;
- `/proc`, `/sys`, `/new_root`, and `/etc` directories;
- `lib/modules/2.6.38.8+mpss3.5.1/modules.dep` and the five K1OM modules:
  `dma_module`, `ringbuffer`, `micscif`, `mpssboot`, and `intel_micveth`.

The corrected outer archive is assembled from that list by
`tools/kernel/build-public-bootstrap-base.sh`. It uses no copied stock root
tree. The nested bootstrap archive remains an explicit input while its full
source/provenance closure is reviewed separately.

## Next Validation

The only justified next hardware change is to replace the prior inner-root
Base CPIO with the reconstructed outer Base CPIO, retaining the same kernel,
five modules, final public payload, and rollback runner. Expected first marker:
`XPR_CLEAN_ROOT_EARLY_INIT_ENTERED`.
