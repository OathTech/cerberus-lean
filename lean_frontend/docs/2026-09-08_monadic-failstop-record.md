# C-TF1: handwritten monadic fail-stops

Base: `c24e78c66` on `mdd/cerberus-lean`; work branch `arc/monadic-failstop`.

[USER] After the fuel work landed elsewhere, the user approved the proposed
C-TF1 slice with “Great, go ahead and execute.” Scope follows the typed-failure
design's R1 (2026-09-05, decision 4) and the parked pure-twin design's explicit
independence ruling (2026-09-07 §8).

[AGENT] Exactly seven `panic!` arms in `CerbMem` now use the existing ND kill
channel: allocator alignment zero, requested-address allocation, dead static
free, function-pointer array shift, non-integer memcmp byte, noninitial
va_list, and CHERI call_intrinsic. Original messages, guards and successful
paths are retained. Alignment zero remains the recorded pending-decision
refusal; no C support or policy decision is inferred. No Lem source, generated
monadic body, pure failure, fuel worker, or concurrency implementation changes.

`CerbFail.failStopKill` is `Error0 modelFailStopLoc msg`; `failStopND` is
`kill` at that reason. The one new pure value-carrying opaque follows CerbFuel
and is registered in the boundary census (15 → 16). It has no native binding,
unsafe body, axiom declaration or new proof assumption. Kernel proofs are
uniform in the atom, including propagation through bind, liftND/liftMem and
all three runners, state at failure, and the composed shipped runND/bind/liftMem
path. Bind and runner require one frame; liftND requires two (one for liftND,
one for liftAction). The composed result is quantified over the caller's
fuel `n + 2`. The zero case retains the fuel-exhaustion contract. No inequality
between the two opaque location atoms is claimed.

Reporting uses a distinct `ModelFailure` record with escaped UTF-8 payload,
not the draft §2.5 ordinary-Error prefix. This implements the approved failure
vocabulary while avoiding an ordinary diagnostic being reclassified by its
text. Complete captures, original exits and framing are checked before a
crash classification. Mixed completed executions containing a model stop are
failures, never semantic agreement. FUEL, timeout, OOM and fatal suffixes take
precedence. The observation contract documents the explicit parser policies.

The dedicated executable exercises all seven arms at caller-supplied fuel 2
and 17, successful neighboring operations, ordinary UB/error controls, and
memcmp's load-state update surviving a later failure. call_intrinsic has no
successful arm. These are executable witnesses, not C reachability proofs;
the generic propagation contracts are kernel-checked separately. Codec tests
include all byte values, UTF-8, ordinary-message and program-output lookalikes,
framing, truncated/suffixed records, multi-execution failures, and resource/fuel
precedence. Real lane plants check each crash family and ordinary Error
controls; immaculate plants replace just the existing memcmp crash witness.

## Validation and interruption recovery

[AGENT] All **35/35 required Tier A+B commands passed**, with exit 0 and
cleaned containment for each completed command, across two runs on identical
sources and external inputs. All **63 tracked files whose names contain
`baseline` are byte-identical** to the pre-change snapshot. No baseline or
instrument re-record is needed.

Before full validation, both generated trees were re-derived. The OCaml build
ran with `DUNE_CACHE=disabled` and `dune build --force`; all Lean library roots
and the driver were built under `scripts/capped`. A development unit
attempt encountered stale copied auxiliary oleans (the existing `hack`
proof names were absent); rebuilding every library root resolved it without
changing those sources or weakening any gate. The targeted unit suite and all
11 new lane-plant checks then passed.

The full run used `CERB_MEM_MAX=48G`, `DUNE_CACHE=disabled`, the prepared
`.validation-foundations/independent-oracle-v2/manifest.json`, and:

```sh
python3 scripts/release.py --mode full --lane-timeout 3300 \
  --out .tmp/monadic-failstop/full
```

[USER] The run was accidentally killed and the user requested resumption.
The runner recorded SIGTERM during B7, after 25 completed commands and after
GCC row 1684/1963. That incomplete B7 is **not counted**. Its guardian also
reported incomplete cleanup; before restarting, inspection confirmed that
both its process group and its cgroup were gone. Source identity and external
inputs still equaled the original run's, with no artifact issues. GCC was
rerun in full, followed by the nine commands not yet run:

```sh
python3 scripts/release.py --mode full --lane B7 --lane B8 --lane B9 \
  --lane B10 --lane B11 --lane-timeout 3300 \
  --out .tmp/monadic-failstop/resume
```

The runner reports remain unmodified: the first is `incomplete` because it
was interrupted; the second is `incomplete` because it deliberately selected
a subset (all 10 selected commands passed). This record claims complete
**A+B command coverage**, not a single uninterrupted runner certification or
a customer-ready release. Reporting, adoption and independent review exits
remain separate. Reconciliation checked the exact 35-member set, each command
(including the runner's evidence-only `--out` additions), zero exits, cleaned
containment, identical source identities before/after both runs, identical
external inputs, identical build/runtime artifacts at the handoff, and zero
artifact issues. The final edits after validation are documentation only.

Raw evidence remains under `.tmp/monadic-failstop/{full,resume}`. The checked
coverage inventory is `.tmp/monadic-failstop/coverage.json`. Report SHA-256s:

- `full/report.json`: `f9a01cc8bc6aed17b3028652a76fc7ef6a0e415dfba20acae59529b9a956ce5b`
- `resume/report.json`: `0b9e97607409d0a5c62620e7d3d33a2eb66d63a3c9c8abacb674a02d14b344ee`

| Lane | Evidence run | Seconds | Exit |
|---|---|---:|---:|
| A1 | full | 174.9 | 0 |
| A2 | full | 34.3 | 0 |
| A3 | full | 67.7 | 0 |
| A4 | full | 30.2 | 0 |
| A4b | full | 26.0 | 0 |
| A4c | full | 4.6 | 0 |
| A5 | full | 30.1 | 0 |
| A6 | full | 2.2 | 0 |
| A7 | full | 9.7 | 0 |
| A8 | full | 8.7 | 0 |
| A9 | full | 16.4 | 0 |
| A10 | full | 16.8 | 0 |
| A11 | full | 60.1 | 0 |
| B1 | full | 629.1 | 0 |
| B2 | full | 23.3 | 0 |
| B3 | full | 15.4 | 0 |
| B4 | full | 46.5 | 0 |
| B5 | full | 63.4 | 0 |
| B6.1 | full | 167.2 | 0 |
| B6.2 | full | 2.3 | 0 |
| B6.3 | full | 9.9 | 0 |
| B6.4 | full | 9.1 | 0 |
| B6.5 | full | 10.2 | 0 |
| B6.6 | full | 10.4 | 0 |
| B6.7 | full | 9.1 | 0 |
| B7 | resume | 1336.9 | 0 |
| B8.1 | resume | 13.5 | 0 |
| B8.2 | resume | 217.5 | 0 |
| B8.3 | resume | 6.6 | 0 |
| B8.4 | resume | 16.1 | 0 |
| B9 | resume | 1245.6 | 0 |
| B10.1 | resume | 63.0 | 0 |
| B10.2 | resume | 1.3 | 0 |
| B11.1 | resume | 14.7 | 0 |
| B11.2 | resume | 6.6 | 0 |

The new unit executable passed 18 checks at each supplied fuel (2 and 17).
All 12 new kernel contract cones are within the standard three axioms; the
census reports zero axiom declarations and exactly 16 registered opaques.
The fuel census remains 81 workers (57 measured, 13 absorbing, 5 reachable
pending, 6 outside the drive cone; 10 reviewed hypotheses). All 233 pure
failure-register rows remain unchanged, with zero DISCARDABLE sites.

The resumed GCC lane completed all 1,963 rows:

```text
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

The observation plants passed **93/93**, including the new immaculate
`crash-model` and `crash-model-suffix` cases. The independent upstream lane
reported 709 semantic agreements, one reviewed difference, 11 matching
failures and two interface agreements. Its real unexpected-verdict plant was
rejected after its positive control passed.

Two real C witnesses from the initial full run's B5 are retained in its raw
captures. `g2-memcmp-uninit` exits 1 with empty engine stderr and:

```text
ModelFailure {msg: "Concrete.memcmp: non-integer byte (impl_mem.ml:2658-2659 assert false)"}
```

Its lane verdict is unchanged:

```text
  MATCH          g2-memcmp-uninit      O[CRASH] L[CRASH]
```

`zd-z2m01-aligned-alloc-zero-zero` likewise exits 1 with a `ModelFailure`
record containing the original pending-decision refusal; the em dash and
section sign are represented by their escaped UTF-8 bytes. Its existing crash
pin is unchanged. These are coarse negative pins, not successful C execution
or a new alignment policy.

C-TF1 is complete on `arc/monadic-failstop`. The pure-failure twin remains
parked; no Lem or concurrency change is included. No merge or push has been
performed; those require their own review and authorization.
