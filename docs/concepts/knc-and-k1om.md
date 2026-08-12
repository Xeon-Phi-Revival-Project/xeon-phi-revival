# Knights Corner And K1OM

Knights Corner is the first Intel Xeon Phi generation. It is a PCIe
coprocessor managed by an x86-64 host, not an ordinary x86-64 CPU.

K1OM is its native ISA and ABI. A native executable should report `Intel K1OM`
in its ELF header and is not expected to run on the host CPU. Knights Landing
and later Xeon Phi products are different architectures.

