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

## Consumer note (refined-cerberus) — change manifest [AGENT orchestrator]

- The seven `CerbMem` arms (allocator alignment 0, requested-address
  allocation, dead static free, function-pointer array shift, non-integer
  memcmp byte, noninitial `va_list`, CHERI `call_intrinsic`) now denote
  `NDkilled (Error0 CerbFail.modelFailStopLoc msg)` where they denoted
  `panic!` — i.e. the `Inhabited` default in the logic. A theorem about a run
  through one of these arms was about a garbage inhabitant; it is now about a
  typed kill. No existing constant changed its signature.
- New: `CerbFail.modelFailStopLoc` (pure opaque, boundary census row 16),
  `CerbFail.failStopKill`, `CerbFail.failStopND`, `CerbMem.failStopMem`;
  kernel-checked propagation lemmas `CerbFail.{bind,lift,liftMem,run,run1,
  runTrace,pipeline}_preserves` and `failStopKill_ne_undef`/`_ne_other`
  (`CerbFailProofs.lean`); `zero_precedes` states that at fuel 0 the fuel
  kill precedes the model stop.
- Observation: the batch protocol gains the record `ModelFailure {msg: "…"}`
  (exit 1 for a single stop); the codec refuses it as semantic agreement in
  every lane (`docs/2026-09-05_observation-contract.md`, C-TF1 section).
- Unchanged: every baseline, the fuel census (57/13/5/6), the pure-failure
  register (233), all `.lem`, all generated code.

## Orchestrator review (2026-09-08) — verdict, findings, boundary battery

[AGENT orchestrator], a separate author from the Codex agent that executed
the slice.

### Verdict

**Accepted and landed with documentation fixes only.** The slice is exactly
the R1 scope ruled [USER 2026-09-05] ("yes agree, this seems the lowest risk
approach"): the seven hand-written `memM` fail-stop arms now denote the
memory monad's own kill, `NDkilled (Error0 CerbFail.modelFailStopLoc msg)`,
where they denoted `panic!` (the `Inhabited` default in the logic); the
messages, guards and success paths are unchanged; propagation is proved
through `nd_bind`, `liftND`/`liftMem`, all three runners and the composed
shipped path, with cones in the standard three; the observation layer gains
one record kind (`ModelFailure {msg: …}`, exit 1) that no lane can read as
agreement; no `.lem`, generated file, baseline, register or pin changed (63
baseline files byte-identical; fuel census 57/13/5/6; failure-reach register
233; fork-drift layer 2 = 22). Codex's own 35/35 A+B coverage was honest
about its interruption and resume.

### Findings (none blocking)

| # | Finding | Disposition |
|---|---|---|
| F1 | `VALIDATION.md` did not describe the new both-fail pair (Lean typed fail-stop exit 1 vs oracle uncaught exception exit 125) under class (a), nor the second pure value-carrying opaque on the boundary-opaque census (16 rows). | Fixed here: §1 (a) paragraph and §9 note. |
| F2 | No consumer change note: the seven arms' LOGICAL denotation changed from a garbage inhabitant to a typed kill — a consumer-visible improvement that refined-cerberus should know when re-pinning. | Fixed here: "Consumer note" section above. |
| F3 | Design note, not a defect: `CerbFail.modelFailStopLoc` is an `opaque` mirroring the C1 Option-C precedent (`CerbFuel.fuelExhaustedLoc`). Under the reasoning-artifact lens a transparent `def Loc.other "model fail-stop"` would be kernel-decidable against every program location and would remove two boundary rows; consumers cannot prove inequalities against an opaque. | TODO row (operator decision; deviates from the ruled precedent, so not changed here). |
| F4 | Two escapers now coexist: `CerbFail.escapeMessage` escapes per UTF-8 byte (correct `String.escaped` mirror); `Main.batchEscape` per codepoint (the registered P0 finding). | TODO row: unify on the per-byte one. |
| F5 | The immaculate pin label `L=CRASH` now also covers the typed fail-stop (exit 1) under the lane's reviewed coarse crash policy — accurate as "both engines fail-stop", but the label is coarser than the observation. | TODO row: rename in a justified re-record if it misleads. |
| F6 | The master plan's step-3 row was edited to a status line by the executing agent — acceptable as a pointer; no ordering or ruling text changed. | Accepted. |

### Boundary battery on `a4d5214e5` (independent of the agent's runs)

Cache-disabled rebuild in this worktree, then the LADDER Tier A + Tier B
battery, the fail-stop plant, the failure-reach gate, the pristine-oracle
lanes and the gcc lane (quiet box). Every LANE rc=0. The single non-zero
step is the orchestrator's own script: its `build_independent_oracle.py`
call refused an output directory that the executing agent had already
prepared in this worktree (`FileExistsError … independent-oracle-v2`) — a
harness precondition, not a lane; both pristine-oracle lanes then ran
against that prepared manifest and passed. Verbatim `=== lane` / `--- rc=`:

```
=== bash tools/check_driver_fresh.sh --check  rc=0
=== ./scripts/test_unit.sh  rc=0
=== ./scripts/test_exec.sh --check-baseline  rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage  rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug  rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float  rc=0
=== ./scripts/test_bytes.sh  rc=0
=== ./scripts/test_libc_exec.sh  rc=0
=== ./scripts/test_multi_tu.sh  rc=0
=== ./scripts/test_parse.sh  rc=0
=== ./scripts/test_core.sh  rc=0
=== ./scripts/test_elab.sh  rc=0
=== ./scripts/test_libxml2_uri.sh  rc=0
=== ./scripts/test_cn_coverage.sh --check-baseline  rc=0
=== ./scripts/test_parse.sh tests/ci  rc=0
=== ./scripts/test_core.sh tests/ci  rc=0
=== ./scripts/test_verify.sh  rc=0
=== ./scripts/test_immaculate.sh  rc=0
=== ./scripts/test_speclab.sh --selftest  rc=0
=== ./scripts/test_speclab.sh --plant  rc=0
=== ./scripts/test_hang_plant.sh  rc=0
=== ./scripts/test_kill_plant.sh  rc=0
=== ./scripts/test_fuel_plant.sh  rc=0
=== ./scripts/test_failstop_plant.sh  rc=0
=== ./scripts/test_libxml2.sh  rc=0
=== python3 scripts/test_observation_lanes.py  rc=0
=== ./scripts/check_failure_reach.sh --selftest  rc=0
=== ./scripts/check_failure_reach.sh  rc=0
=== independent oracle build  rc=1
=== python3 scripts/test_upstream_oracle.py  rc=0
=== python3 scripts/test_upstream_oracle.py --plant  rc=0
=== ./scripts/test_gcc_oracle.sh --check-baseline  rc=0
```

Verdict lines, verbatim:

```
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/scripts/exec_baseline.txt
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/scripts/exec_coverage_baseline.txt
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/scripts/exec_debug_baseline.txt
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/scripts/exec_float_baseline.txt
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: exec_match=9 neg_pinned=5 fail=0
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
Raw observation evidence (kept on failure or under CERB_OBSERVATION_DIR; removed on exit 0): /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/.tmp/scripts/observations/test_multi_tu.oawHLsSggI
SUMMARY: total=2 match=2 fail=0
Total:          106
Total:          106
SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0
Checking against baseline (exact match, fail-closed both directions): /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/tests/cn_coverage/baseline.txt
BASELINE OK (213 entries, exact match)
Total:          250
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
test_speclab [selftest] /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/.tmp/scripts/speclab.rclW8ylJbH/identity.c
test_speclab [plant] /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/.tmp/scripts/speclab.PqUeYNQXuh/plant.c
PLANT OK   [classifier fail-closed]: HARNESS ERROR: time record /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/.tmp/scripts/hang-plant.yJPnIUehl2/does-not-exist.time missing
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
=== ./scripts/test_failstop_plant.sh
test_failstop_plant: PASS (11 class and rejection checks)
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
observation lane plants: 93/93 passed
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
FileExistsError: [Errno 17] File exists: '/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/.validation-foundations/independent-oracle-v2'
Independent oracle: passed; {'semantic_agreement': 709, 'reviewed_difference': 1, 'matching_failure': 11, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/.tmp/upstream-oracle-gkelcwn1/report.json
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/.tmp/upstream-oracle-79e2s0z4/report.json
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/monadic-failstop/scripts/gcc_oracle_baseline.txt
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

Derived: zero baseline movement in every baseline lane; the boundary-opaque
census reads 16; gcc `agree=1873 disagree=0`; pristine oracle 709 / 1 / 11 / 2
+ plant rejected; immaculate `OK: lane matches the committed baseline` with
`g2-memcmp-uninit` still `MATCH O[CRASH] L[CRASH]` — the Lean side now the
typed `ModelFailure` record, the oracle side its uncaught exception.
