# RC Root Size Analysis

The retained passing Base CPIO control and the failing static-BusyBox RC Base
CPIO have the same 1,802 members, symlink count, hardlink-candidate count,
maximum pathname length, and large-file count. The only material outer-archive
difference is the nested `xpr-rootfs.cpio.gz` payload.

| Input | SHA-256 | Compressed | Unpacked | Result |
| --- | --- | ---: | ---: | --- |
| Passing clean control | `2d552afaf86622d37319e835752e97dcfe486d05fae8b0189acdc6ff5283d78c` | 29,316,685 | 68,769,532 | project boot previously passed |
| Failing static-BusyBox RC | `b28da0f987acb1c36346df3f144e97a784afd7f6e1f7ebb348edce43484f9bb6` | 62,892,746 | 102,514,876 | remained `booting` |

The nested clean root is 5,804,258 compressed bytes, 16,057,344 unpacked
bytes, and 54 members. The RC nested root is 39,661,537 compressed bytes,
129,369,364 unpacked bytes, and 3,107 members.

## Synthetic Size Control

The most informative generated control appended deterministic incompressible
padding to the passing Base CPIO, leaving its project root, early init, and
module layout unchanged.

| Control | SHA-256 | Compressed | Unpacked | Candidate result |
| --- | --- | ---: | ---: | --- |
| 102 MiB hash padding | `2f3a920cbcbfe00ec59a39ad145510269a415cb574aa59a84e3b7d4ec6a5d0ca` | 67,514,239 | 106,954,752 | `online` on poll 6 |

MPSS generated the final ramfs
`12e025882bbe6b9a4b7a2e66156c4b6b293bba742e1e010875a5019f5aba9668`,
and the candidate reached `online`. Its one-shot SSH check was too early to
prove project SSH, so this control is not a new repeatability claim. Automatic
rollback restored stock `mic0` online, stock SSH (`k1om`, PID 1 `systemd`),
and the baseline stock configuration hash.

## Decision

`CONTENT_GROUP_BLOCKER` is the current provisional decision. The full RC
failure does not follow a simple Base CPIO compressed-size, unpacked-size, or
member-count limit. The next and final permitted isolation control masks the
Python runtime group inside the nested RC root while retaining the rest of the
RC content and the proven outer boot path.
