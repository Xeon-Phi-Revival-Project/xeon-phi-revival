# Experimental Compatibility Boot Plan

One bounded compatibility boot was performed with an alternate MPSS config
directory, rebuilt five-module Base CPIO, bounded polling, and stock recovery.
The first image reached `booting` but not `online`; the release/module-path
correction then reached `online`, project PID 1, project Dropbear SSH, and the
project hello/pthread smoke path. See
[experimental-boot-results.md](experimental-boot-results.md) and
[first-candidate-boot-analysis.md](first-candidate-boot-analysis.md). That
unchanged small image has since passed three bounded boots; see
[candidate-repeatability.md](candidate-repeatability.md). The first full
release-candidate root archive did not reach userspace. The next candidate test
first isolated the image-size and root-unpack boundary. Both controls passed;
see [rc-root-isolation-controls.md](rc-root-isolation-controls.md). The next
candidate test should replace only the known-good clean root's `/sbin/init`
with the RC init script, retaining its static shell and project SSH path. It
must not retry the full RC root unchanged. Any test must preserve the same
firmware, flash, ROM, persistent-storage, and active-stock-config boundaries.
