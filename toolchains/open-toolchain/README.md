# Open K1OM Toolchain Track

This track investigates whether an open `x86_64-k1om-linux-*` toolchain can be
built or revived.

Initial questions:

- Which upstream binutils versions still contain K1OM awareness?
- Which GCC versions contain or can be patched for K1OM?
- What is the smallest assembler/linker path that can produce a valid K1OM ELF?
- Can a tiny assembly or C runtime smoke test run against the stock MPSS uOS?

Do not assume generic `x86_64-linux-gnu` output is valid for Knights Corner.
K1OM has its own ELF machine identity, psABI details, vector ISA expectations,
and runtime loader path.
