# Experimental Compatibility Boot Plan

One bounded compatibility boot was performed with an alternate MPSS config
directory, rebuilt five-module Base CPIO, bounded polling, and stock recovery.
The first image reached `booting` but not `online`; the release/module-path
correction then reached `online`, project PID 1, project Dropbear SSH, and the
project hello/pthread smoke path. See
[experimental-boot-results.md](experimental-boot-results.md) and
[first-candidate-boot-analysis.md](first-candidate-boot-analysis.md). The
next candidate test, if authorized, should be a repeatability run of this
unchanged image. Any test must preserve the same firmware, flash, ROM,
persistent-storage, and active-stock-config boundaries.
