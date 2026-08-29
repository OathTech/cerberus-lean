# V3a2 — the loop-theorems continuation: m1 EXIT CLAIMED, the mint classes landed, T5 STOPPED at the consistency-bridge wall

Date: 2026-08-29. Worker: V3a-CONTINUATION (arc/segment-ladder,
started at 9c250ff4d). Work order: the V3a record's §6 priced
frontier verbatim (docs/2026-08-29_v3a-loops-mechC.md). Status:
**exit (a) DONE; exits (b)/(c) PARKED at a wall of NEW KIND** —
this record is the park record and the stop signal
(park-ends-slice).

Commits this slice: 75bf2f339 (engine: ground-redex prong + leaf
dispatch), 4aca489bd (m1 PROVED), 3ab5a0ee9 (item ii links/minters +
crossings + the two decide fixes), bd4a50395 (the REBIND class),
41916a060 (item iii NEG minting + T5Guard) + this record.

---

## 1. Exit (a) CLAIMED — m1 (sgn) proved, the PERF-2 tightened exit

`RelSem.M1.m1_proved : M1Statement` (RelSem/M1Body.lean), at the
frozen registered statement, bridged by `verify_fn`, caller protocol
`m1_wp`, body by the construct-package walk. **Cone exactly
{propext, Classical.choice, Quot.sound}**, pinned in-build
(Audit.lean row).

Against the pre-registration (committed at f2d7d42b1, BEFORE the
construct-set extension): bound ≤ 6 registered facts at k = 2.
**Delivered: 5** — four branch-side guard anchors (m1g1T/m1g1F at
the first branch, m1g2T/m1g2F at the second; data-quantified,
path-conditioned by the `by_cases` hypotheses) + one value/trace/
counter-quantified terminal offer (`m1term`, one fact for all three
arms). Zero generated per-round facts: the walk is 83 rounds across
the branch tree (10 to branch 1; 18 then-arm; 22 to branch 2; 16/17
final arms), 79 discharged by MINTED instances of the once-proved
construct characterizations, 4 by the anchors, terminals by the
quantified offer through `seg_done`.

Proof shape (the professor reading): protocol, walk,
`by_cases hlt : x < 0`, walk, coda; `by_cases hgt : 0 < x`, walk,
two codas. Each coda's postcondition is one `rw [if_pos/if_neg]`.

Timing lane: M1Guard + M1Body rebuild 35.2 s wall / 2.2 GB peak
(capped 48G). Tier A: `./scripts/test_unit.sh` exit 0 at this head
(log: container `.v3a-logs/c-test-unit-final.log`).

## 2. Work-order items — delivery state

| Item | Priced | State |
|------|--------|-------|
| (i) guard-anchor machinery | M-S | **DONE** — hypothesis-fed anchors at syntax cut points; kernel-evaluation guard doctrine held (new GROUND-REDEX prong: closed + consult-free payloads only; never at symbolic guard/conv/case redexes) |
| (ii) link_store/create/kill + minters | M | **DONE** — links in SegRun.lean, minters in SegStepper.lean; firing measured (T5 prologue creates/stores mint end-to-end) |
| (iii) NEG-transform supply-draw class | M | **DONE to minting** — supply-delta classifier, `link_ctl_sup` + `link_ctl_sup_draw`, pinned-draw template minting; the T5 NEG-rewrite round MINTS. Final consumption blocked by §4's wall |
| (iv) loop assembly (SegStep.iter + first_exit) | S-M | **PARTIAL** — T5 loop-guard anchors landed (T5Guard.lean: t5gT/t5gF quantified over (iv, nv) at the walk-extracted 654-line guard arena); assembly blocked behind the wall |
| (v) P11 %-chain | S-M | **NOT STARTED** (sequenced after T5 assembly; its full exit shares the wall — P11's loop body draws too) |

Unenumerated class found and landed (deviation reported mid-slice,
orchestrator CONTINUE disposition): the **REBIND class** — label
jumps (`save`/`run L(i,s)`) re-bind existing env keys at their
current values; lookup-preserving respell below the link layer
(`rebind_pres` + `wpk_seq_ctl_env1/2_lk` +
`link_ctl_rebind1/2`); the birth links refusing these rounds was
fail-closed behavior working correctly.

## 3. Engine findings (for the register)

- **Two unchecked-decide soundness bugs, fixed** (orchestrator-
  flagged for this section): `MVarId.assign` is unchecked and
  `Meta.mkDecideProof` does not evaluate — an ill-typed
  `decide (s ≠ s) = true` proof was built and CAUGHT BY THE KERNEL
  at declaration add (the fail-closed pattern holding). Fix: the Ne
  dispatch and `buildNotMem` now kernel-verify `decide ty = true`
  BEFORE building; a refuted freshness now throws naming the rebind
  class.
- **Ground-redex prong needs consult-freedom**: closedness alone let
  the kernel chase env lookups at open envs (16–32 G runaway); the
  prong requires no PEsym/PEmemop/PEcfunction in the payload.
- **Uncached Expr traversals are exponential on DAG-shared kernel
  terms**: two sites (`containsFVar` filter, `hasAnyFVar`) replaced
  with single-pass `Lean.collectFVars`.
- **Per-command stream capture**: `lean` buffers a command's output
  until completion — killed runs print NOTHING (every "impossible"
  missing print). Instrument: direct-file-append `segdbg`, env-gated
  by `SEGDBG_LIVE`.
- **Literal-plus-provenance-pin**: elaborator defeq on file-lookup
  projections OOMs (32 G); paste extracted literals + `seg_pin_eq`
  (kernel-checked equation command, SegRoundTac.lean).
- **Structural replaceProj over kabstract**: drawn-id spellings
  deep-normalized (chaseAstDeep) then abstracted structurally;
  kabstract's defeq search was the grind.
- crossExceptM: `whnfCore` won't δ-unfold `except_bind` — one forced
  `unfoldDefinition?` breaks the Result↔except_bind alternation.

## 4. THE WALL (new KIND) — the consistency-conditioned bridge gap

T5 walk state (probe RelSem/T5WalkProbe.lean, committed instrument;
170 s / 2.5 GB): prologue **34/34 minted** to the loop guard; guard-F
arm (n ≤ 0) **31 rounds to TERMINAL** — the complete path mints;
guard-T arm mints **through the NEG-rewrite draw round** (item iii
firing) and STOPS at the drawn symbol's wseq env-bind.

The stop is not volume; it is a missing adequacy mechanism:

1. The frozen `T5ThreadedStatement` is a **Cns face**
   (`CallHarnessAdequateCns`, conditioned on `ConsistentRun` —
   relsemcore Threaded.lean §CONSISTENCY).
2. The ONLY landed bridge, `callHarnessAdequateCns_of_thrAll`
   (CerbStateAdequacy.lean), **discards the consistency hypothesis**:
   it requires the UNCONDITIONAL ∀-seed Thr face.
3. The unconditional ∀-seed WP for T5 is **unprovable**: the loop
   body draws symbols at open supplies; drawn ids are seed-symbolic
   (`seed + k`, digest "") and a capturing seed shadows program
   bindings — the arc-16 S4 T4 diagnosis ("unrestricted ∀-seed T4 is
   FALSE, hash-collision capture") reproduced on T5's critical path.
   Concretely: the birth link's freshness premise (drawn num ∉
   ledger literals) is seed-symbolic vs literal hashes —
   undischargeable, and genuinely false at capturing seeds.
4. Every alternative route re-encounters it (analyzed this slice):
   ghost birth needs ledger freshness; a "silent birth" (ledger
   append, no cell) still needs non-shadowing for EnvCoh
   preservation — the same apartness; a whole-complex block fact
   still contains the bind in its interior.

Therefore T5 (and P11, and un-parked T4) need a **genuinely
conditioned bridge**: a proof-layer guarded family (the seed-indexed
`FnSpec.guard` slot survives for exactly this — V0 note,
Segment.lean:402) plus a NEW adequacy theorem transporting
guarded-Thr families to the Cns face. Candidate designs, neither
started (design sign-off wanted):

- **(A) draw-bound route**: guarded WP under window-apartness
  `[seed, seed+B)` with B = the path's draw count; the bridge must
  connect ConsistentRun's actual-window apartness to B-apartness via
  a clean-control-flow argument (consistent ⇒ the run follows the
  clean path ⇒ draws exactly B), which itself should fall out of the
  guarded walk with a strengthened conclusion (final sym_supply =
  seed + B). Shares all machinery with the arc-18 C3 T4-apartness
  item; looks enumerated but is adequacy-layer construction with
  real design freedom.
- **(B) observation-extended transport**: a harness variant whose
  done-value carries the final supply, so runs' posts can be
  conditioned. Deeper surgery on the reified language's value type;
  likely rejected.

The V3a record's hazard line anticipated this without pricing it
("the NEG rounds draw fresh symbols at open supplies — the arc-16
spike's threading territory"). It is the T4-apartness M-item
(arc-18 charter C3) surfacing as a hard dependency of T5's exit.
Per the standing condition ("a wall of KIND, not volume →
stop-and-report"), this slice STOPS HERE; the close report carries
the measurements.

## 5. Price accounting + doctrine compliance

Priced M+M+M+S-M+S-M; delivered (i)(ii)(iii) in full, (iv) partial,
(v) unstarted, plus the unenumerated REBIND class (approved
mid-slice). Exit (a) done inside the envelope; (b)/(c) parked at the
wall, not pushed. No heartbeat/recursion budget raises beyond the
slice-standard walk-file `maxHeartbeats 2000000` (V3a base
convention). No build over the tripwire (longest single artifact:
the T5 probe at ~3 min; full relsem package well under). Logs at
container `.v3a-logs/`; no probe litter in-repo (T5WalkProbe.lean is
a committed instrument).

## 6. Registered heartbeat bumps (pre-merge audit, 2026-08-29)

[AGENT, closing the pre-merge audit's MINOR-3] Two committed proof
sites carry `set_option maxHeartbeats 8000000`, above the
slice-standard walk-file 2000000, and were UNREGISTERED until this
audit (a doctrine violation: bumps are by-definition defects —
register entry + expected remover):

- `relsem/RelSem/T2Proof.lean:46` (`t2_wp`) — introduced with the
  V2 T2 proof (commit `88c363c38`, 2026-08-28).
- `relsem/RelSem/T3Proof.lean:46` (`t3_wp`) — introduced with the
  V2 T3 proof (commit `055a1834b`, 2026-08-28).

Both bumps predate this slice (§5's "no raises" line describes the
V3a2 slice itself and stands). The proofs ride the bumps today —
they are NOT removed here, only registered.

EXPECTED REMOVER: the segment-stepper repricing. Precedent: the V2b
P01 retrofit (commit `62056e7cb`, 2026-08-28) removed P01Proof's
identical 8000000 bump by rerouting the body walk through `seg_run`
(per-ROUND heartbeat isolation — fresh count per round, walk cost
scaling with round count, no global raise) and repriced T1. T2/T3's
WPs still ride the pre-stepper linear round chains; the same
retrofit removes both bumps.
