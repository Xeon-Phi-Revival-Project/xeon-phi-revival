# Experimental Compatibility Boot Plan

One bounded compatibility boot was performed with an alternate MPSS config
directory, rebuilt five-module Base CPIO, bounded polling, and stock recovery.
It reached `booting` but not `online`; see
[experimental-boot-results.md](experimental-boot-results.md). Do not repeat it
automatically. Any future test must preserve the same firmware, flash, ROM,
persistent-storage, and active-stock-config boundaries.
