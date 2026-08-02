# First Candidate Boot Analysis

## Evidence

The one RAM-only candidate boot used kernel
`d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8`
and Base CPIO `e458cf6d406a2336c6992853eacfa42796ebe9c34ea8a9a518c0786d56a69433`.
MPSS accepted the candidate image and reported `booting` for 18 five-second
polls. It did not report a network-link transition or `online` state.

The candidate kernel and rebuilt modules identify as
`2.6.38.8+mpss3.5.1`. The tested Base CPIO instead placed all rebuilt modules
under `lib/modules/2.6.38.8+mpss3.4.10`. Project early init invokes
`modprobe`, which resolves its index under the running kernel release.

## Classification

The last positive stage is MPSS host-side image acceptance and reset-to-booting.
The first missing stage is card-side module loading followed by the virtual
network/readiness handshake. This is a module-discovery integration failure
hypothesis, not proof of a kernel execution failure.

## Corrected Bounded Test

The corrected image used Base CPIO
`7ce52df3fd115984f3ec191abb4a1fb2b336f477797103806b79064c011afe0e`.
It added the five rebuilt modules below `lib/modules/2.6.38.8+mpss3.5.1/`
and supplied a matching minimal `modules.dep`. The old 3.4.10 tree remained
inherited but inactive for the candidate release.

MPSS booted the candidate image and reached `online` on the fourth five-second
poll. Host dmesg recorded `MIC 0 Network link is up` followed by
`mic0: Transition from state booting to online`. Stock rollback then restored
the baseline configuration and SSH service.

This proves candidate kernel handoff through module discovery, virtual
networking, and the host readiness transition. It does not prove project SSH,
project PID 1, or application smoke tests, because the test intentionally
rolled back immediately after `online`.
