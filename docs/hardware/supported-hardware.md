# Supported Intel Xeon Phi Hardware

| Hardware | Status | Evidence |
| --- | --- | --- |
| Intel Xeon Phi 5110P (Knights Corner) | Tested | RC6 preserves the three-boot validated RC5 runtime set |
| Other Knights Corner / KNC cards | Untested | No project claim yet |
| Knights Landing / KNL | Not a target | Different architecture and software model |

The tested host was CentOS 7.4 with MPSS 3.4.10 on a Dell PowerEdge R730. This
is a tested configuration, not a universal compatibility guarantee. KNC cards
are passive accelerators in many systems; provide suitable airflow before
running workloads.

