# Candidate Module ABI Comparison

| Module | Stock SHA-256 | Rebuilt SHA-256 | Rebuilt vermagic | Dependency closure |
| --- | --- | --- | --- | --- |
| `dma_module` | `854a1c0c9629a3197aa740fb5b17e69429816f71a6b2a54493f78d5b2495cc5b` | `0c04e0457d479778cec34a3d7944dbf4b070cd7ed11c181de4b9b6d35f39ff00` | `2.6.38.8+mpss3.5.1 SMP mod_unload` | 34 kernel exports |
| `ringbuffer` | `cdccf83f6ad47ce1e644ffd3bfd178c2c13e85885110749ccbaf0669e2b1b413` | `ed596f727af411f98415796bef911b4f3a00e00eb811ff92c42e7799737c9c12` | `2.6.38.8+mpss3.5.1 SMP mod_unload` | 2 kernel exports |
| `micscif` | `bd2426ab71667969fb89f5e99d9d0d12a7eebd49cba2a8003b9514b5f15692a2` | `d4cd1a2e38dae2a51edab9048b0bf738039b186081bd9f88c93e008d798640ce` | `2.6.38.8+mpss3.5.1 SMP mod_unload` | 118 kernel, 25 module exports |
| `mpssboot` | `51b8560005efe971b3dc07e77cab18735c2107672e6f00d08e92dd38421c8dbb` | `d1ec47a39290c8fc0065f8e7f622afdb7d885a8a7b4c932224c561f8087ee869` | `2.6.38.8+mpss3.5.1 SMP mod_unload` | 12 kernel, 5 module exports |
| `intel_micveth` | `3051467bbb86df31f55fa6233844a8830be012918de6b84b05b3d73e9035cad2` | `731a3d0242b9fe2088c8db1d75ee74ffc1886c7f8bb79a53cee5733c652c224a` | `2.6.38.8+mpss3.5.1 SMP mod_unload` | 63 kernel, 6 module exports |

The rebuilt dependency graph exactly matches stock:
`mpssboot -> micscif -> ringbuffer,dma_module` and
`intel_micveth -> dma_module`. The offline analyzer found zero unresolved,
renamed, or non-exported rebuilt-module references.

Run [inspect-candidate-module-abi.sh](../../tools/kernel/inspect-candidate-module-abi.sh)
against external stock, rebuilt, and kernel-build paths for the complete
per-symbol report.
