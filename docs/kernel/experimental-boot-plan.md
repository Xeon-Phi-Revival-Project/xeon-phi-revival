# Experimental Compatibility Boot Plan

One bounded compatibility boot was performed with an alternate MPSS config
directory, rebuilt five-module Base CPIO, bounded polling, and stock recovery.
The first image reached `booting` but not `online`; the release/module-path
correction then reached `online`. See
[experimental-boot-results.md](experimental-boot-results.md) and
[first-candidate-boot-analysis.md](first-candidate-boot-analysis.md). The
next candidate test, if authorized, must only verify project PID 1 and SSH on
the now-working image before rollback. Any test must preserve the same
firmware, flash, ROM, persistent-storage, and active-stock-config boundaries.
