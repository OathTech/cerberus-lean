# Arc 9 results — "the workbench": WP tactic library + complex-reasoning slate

Date: 2026-08-21. Branch `arc/wp-tactics` (cerberus-lean only — ZERO
lem-lean commits this arc). Charter:
`docs/2026-08-20_arc9-wp-tactics-charter.md`; decision log:
`docs/2026-08-20_arc9-decision-log.md` (D1-D4); slice records:
`2026-08-20_arc9-s0-survey.md`, `2026-08-20_arc9-s1-design.md` (incl.
the §11 S3 addendum), `2026-08-20_arc9-s2-build.md`,
`2026-08-20_arc9-s3-build.md`.

**Outcome (D4):** the arc closes with THE WORKBENCH as its
deliverable; T5 is PARKED AT EVIDENCE GRADE with a precise resumption
point. Workbench-v2's charter takes T5 completion as its FIRST exit
criterion (§7 below).

## 1. The workbench deliverable (inventory)

### 1.1 L0 — OwnP adoption (iris-lean reuse; commit "S2 1/3")

The hand-rolled state-ghost twin of arc-7 is RETIRED in favor of
upstream `OwnP` (iris-lean #653, taken via the D1 pin bump to head
`34390a0133986385c62bf59a6eb01938945b48ec`). Line delta (derived):
IrisState + IrisRules + IrisAdequacy 456 → 369 lines (current: 96 +
158 + 115); the two ~40-line IPM lifting bodies and the adequacy
alloc/split/defeq-bridge became library calls; retired lemmas
`stateIs_agree`/`stateIs_update` (their Audit pins removed with
in-file reason — the only Audit edit). ACCEPTANCE: every T1-T4 Audit
pin passed UNCHANGED (identical cones). (Sizing reconciliation,
CORRECTED at the pre-merge audit, auditor A F2: D4's "~380→~150" was
an estimate in the D4 text itself — the "~380" traces to the S0
survey's reuse-debt register ("~380 lines of our" arc-7 code, survey
§1.3), but the "~150" has no S2-record source. The MEASURED
accounting is the 456 → 369 above, recorded in the S2 record §1;
this doc's earlier claim that "both accountings are in the S2 record
§1" was wrong for the ~150.)

### 1.2 L1 — the lemma kits (census by file, pin counts)

All under `relsem/RelSem/Kit/`; exactness surface = verbatim
`#print axioms` pins via `#guard_msgs` in `Kit/Audit.lean` (146
lines), imported by `RelSem/Audit.lean` so a plain `lake build`
enforces it. Census at close (derived, this worktree):

| file | lines | pinned public lemmas | contents |
|---|---:|---:|---|
| Kit/AppEq.lean | 41 | (registrations) | 14 `@[app_eq]` law registrations for the Machine.lean spine |
| Kit/Eval.lean | 106 | 6 | eubind/stub/eumapM crossings, liftCore_run_defined, aux2_step/done |
| Kit/Loop.lean | 82 | 4 | `iter_compose` + `iter_compose_from` + `app_fuel_cast` + `fuel_split` |
| Kit/Map.lean | 292 | 18 | lawful-map layer: symCmp TransCmp bridge, FmapBuilt captured-comparator invariant, fmapLookupBy/addBy laws, Int-TreeMap get?/insert laws |
| Kit/Mem.lean | 139 | 5 | mem_alloc/store/load/kill/prefix blocks (computed-RHS, brick-B3 named-hypothesis convention) |
| Kit/Round.lean | 468 | 21 | dnms_round/dnms_terminal glue, advance classes, perform layer (liftMem, perform_create/load/store/kill), ars_* unfolds, draw laws |

Total: **54 exactness pins** over the public kit surface. [CENSUS
CORRECTIONS at the pre-merge audit, auditors B F3 / A F3: Kit/Mem is
139 lines at head, not the stale 133 — the count includes the
`ad1460f59` rebase-integration fix (readonlyStatusForAlloc_none in
mem_alloc_block's proof). Precise file census: SEVEN files under
`Kit/` at head — Audit, AppEq, Eval, Loop, Map, Mem, Round — i.e.
the six content kits tabled above plus `Kit/Audit.lean` (the pin
file); this is what the gate's "Kit files fixture-free OK (7 files)"
tally counts, and reconciles D4's "7 kits/50+ pins" phrasing (7
files, and 50+ was a floor) with this doc's six-kits/54-pins census.]
`iter_compose`/`iter_compose_from` are pinned **axiom-free** ("does
not depend on any axioms"); everything else is within the classical
trio. Provenance tags per the S0 gap matrix (G1-G12): the loop rule
is BUILD-NEW Layer 2 (matrix headline: iris-lean has no loop rule at
our granularity), kits are golean-pattern extraction with brick-wp
organization, OwnP/IPM are iris-lean reuse.

### 1.3 L2 — walker v1 → v3 + the per-stage certificate emitter

`Tactics/AppEqAttr.lean` (126 lines: `app_norm` simp set, `@[app_eq]`
DiscrTree attribute with metavariable-telescope keys,
`@[app_state_atom]`) + `Tactics/AppWalk.lean` (1,589 lines). Capability
ladder, each stage measured on real theorems:

* **v1 (S2):** `app_walk`/`app_walk n`, `app_walk_step`,
  `app_walk_finish`, `app_walk?` (debug, gate-banned). Findings:
  hfuel wildcard fuel-offset unification; `normSpine` bounded
  computed-value normalization; app-crossings are LAWS ONLY (raw-rfl
  fallback banned — measured junk-state synthesis); chain-first
  stepping; per-round fresh heartbeat windows CAPPED at ambient (no
  raise anywhere).
* **v2 (S3 c1, per D2):** `WalkCfg`, `normStateV2` type-aware
  selective state normalization (Fmap/TreeMap opacity +
  `@[app_state_atom]` fixture-name preservation), `app_walk_norm`.
* **v3 engine (S3 c2-c3):** kernel-whnf discovery (`kWhnf` —
  F-S3-5: the elaborator's substitution-based whnf blew the 40G cap
  where the kernel does the same crossing in ~60ms), atom pred inside
  whnf with hoisted closure (F-S3-1: 25s → ~60ms), map-valued result
  blocking split from the discovery lane (F-S3-2), targeted
  `evalScalar` folding (F-S3-3; full `Meta.reduce` banned — measured
  40G trip), cached `approxDepth` (F-S3-4: sizeWithoutSharing
  exponential on shared DAGs), heartbeat LEDGER (F-S3-6: settle the
  global counter after each capped round — accounting parity with the
  per-round-declaration style this replaces, no ambient raise),
  head-filtered assumption (F-S3-7), ctor-pattern computed-value
  normalization lane (F-S3-8).
* **The per-stage certificate emitter (D3 continuation, S3 §8):** the
  root-cause result "STRUCTURE bounds kernel recursion" (10-row
  configuration matrix, S3 §5: every monolithic packaging of a
  create-round certificate trips `(kernel) deep recursion detected`;
  T4's hand proofs pass IDENTICAL content as many small obligations)
  → automate exactly that granularity. Mechanisms landed:
  decide-facts chase-rewrite (`kWhnfWithFacts` — descend to the
  transient `decide P` inside recursor-major positions, discharge
  from context facts via full-transparency matching +
  `decide_eq_true/false`, materialize back via an `Eq.ndrec`
  equality-motive step), ledgered budgets pushed all the way down,
  `sealCtorLeaves` value/leaf sealing (constructor structure stays
  visible to DiscrTree), avatar abstraction for kernel-whnf under
  symbolic variables, raw-`addDecl` certificate fallback (the KERNEL
  is the only checker). Zero TCB surface — everything is engine-side;
  every certificate is an ordinary kernel-checked declaration.

### 1.4 iter_compose family status

`iter_compose` + `iter_compose_from` (Kit/Loop.lean): proved,
pinned AXIOM-FREE, exercised by the fuel algebra
(`app_fuel_cast`/`fuel_split`). The survey's rank-2 extensions
(`iter_compose_var` for per-iteration fuel, `iter_compose_exit` for
early exit) are designed (S1 §1.2/§5 T6/T8) but deliberately NOT
built ahead of a proof that reaches their shape — v2 items.

### 1.5 THE CALIBRATION (S2, the arc's measured headline)

`dnms_chain` (T1's dnms segment) re-proved through kit + walker with
IDENTICAL statement and axiom cone (every Audit pin unchanged). The
proof, verbatim (5 tactic lines, 2 semantic steps — exactly the two
x-sensitive crossings):

```
  app_walk
  app_walk_step (round3 x h1 h2 999996 rsD3 [] 3)
  app_walk
  app_walk_step (round6 x h1 h2 999993 (memD3 x) [meLoad x] 5)
  app_walk
```

The MECHANICAL dnms content (~200 lines of round lemmas, transcribed
intermediate configurations, and the 9-way `.trans` composition) is
now those 5 walker lines: **~200 mechanical lines → 5**. [CORRECTED
at the pre-merge audit, auditor B F1: this doc's earlier headline
"≈700 → 5" conflated the design's ≈700-line dnms-SEGMENT estimate —
which includes the semantic support — with the walker's actual kill;
the S2 record §3 always carried the honest split.] File-level tally
(honest accounting, S2 §3): T1AppEq 1,038 → 862 lines (git numstat
−193/+17) — the retained lines are the SEMANTIC support (memory-op
lemmas, conv-chain ladder, prefix walk) the design assigns to later
migration waves, not to the walker; note the two `app_walk_step`
lines above CONSUME that retained support (`round3`/`round6` are the
semantic steps, retained and fed to the walker). What the walker
promised to kill is dead in-segment: 0 round transcription defs,
0 `.trans` in the dnms proof. Elaboration ~6 s.

### 1.6 The proof-size gate (status: HONEST)

`scripts/check_proof_size.sh` (Tier A via test_unit.sh, fail-closed):
250-line/40-manual-step bars per registered slate file, Kit
fixture-free grep (the mega-lemma counter), `app_walk?` ban.
**T5.lean is registered and PENDING** — the gate prints
`check_proof_size: T5.lean — not present yet (registered, pending)`
and this stays true at close: the bar was never gamed, no
placeholder file was created to green it.

## 2. The T5 climb record (parked at evidence grade)

* **Fixture bank (done-waiting):** T5Fixture.lean (177 lines),
  tests/verify t5_sum fixture + 4 expectation rows (n ∈ {0,1,10,100}
  → Specified(n(n-1)/2)), gated in test_verify (29/29 includes it);
  T5Prefix.lean (617 lines): prefix walk proved, conv-ladder
  portability lemmas generic in env and mem, and the **St-v2 family**.
* **The census instrument:** `t5-probe` (test/Unit/T5ProbeMain.lean,
  a lakefile exe) drives the real generated step_ctx/advance_step
  round by round. Ground truth at n=2: 223 rounds; entry block
  R0-R20; iteration period **79**; loop-head closed forms at St k:
  aid 4+7k, sym seed+2k, eid 2k, ctr 17+72k, tr 4+7k.
* **St-v2 VALIDATED at symbolic n:** the 21-round entry walk's
  synthesized post-state is `Kernel.isDefEq`-equal to `StT5 n 0` —
  the family (env chains, bytemap chains, stuck-seed rs, arena,
  trace) is exactly the computation's own boundary value, at symbolic
  n. The F-T5-1 risk (S2 park) is discharged; two family defects were
  found BY the kernel diff and fixed (§5 errata).
* **The entry theorem is GREEN in ~5 s** (D3 continuation): all 21
  entry rounds mechanical through the emitter, including both CREATE
  and both STORE action rounds end-to-end.
* **Climb position at park:** probe `iter0_probe` clears **44 of the
  79** census rounds of iteration 0 — creates, the n/i/s loads, the
  SYMBOLIC `decide (0 < n)` lt-guard via decide-facts, the concrete
  eq-compare and add-chains, the stores, the post-store tau/eval
  region — at the 40G cap, no aborts, ~10 min wall.
* **The named resumption point:** the loop-back (Esave re-entry)
  region. The round's selection certificate builds (raw-addDecl,
  sealed leaves 84→32/173) and `advance_runstate_tau_misc`'s first
  hypothesis discharges; the next unknown is ONE new Kit law class —
  the **continuation-lambda advance** shape
  (`advance_step tagDefs tid (fun p => …)`). Remaining: ~35 rounds +
  symbolic hbody + exit + composition at a measured ~1 engineering
  hour/round of discovery — exactly the open-ended climbing D3 bans
  and exactly what the v2 slate items (trace/replay,
  context-indexed laws) attack.
* Probe scratch (`ProbeT5S3*.lean`, `scratch/`) intentionally stays
  UNTRACKED — next-session material, reproducible from the S3 record.

## 3. Per-slice gate tallies (verbatim)

S2 commit 2 (see the S2 record §3.4; the arc's per-commit boundary
set was green at every slice commit — tails in the commit messages):

```
Build completed successfully (356 jobs).
Total: 6 passed, 0 failed
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
```

S3 final commit (record §8.5):

```
Build completed successfully (609 jobs).
RelSem statement gate: 16 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
RelSem audit sweep: 2435 declarations across RelSem.* modules, all within the declared axiom boundary (0 recorded sorryAx exceptions)
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
```

S4, post-rebase head (this doc; full battery — commands and full
logs in the S4 commit messages):

```
Build completed successfully (609 jobs).
Total: 7 passed, 0 failed
check_fork_drift: OK — layer 1: 52 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: Kit files fixture-free OK (7 files)
check_proof_size: T5.lean — not present yet (registered, pending)
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
minimal:  SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
coverage: SUMMARY: total=199 match=174 ub_match=12 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=13 cerb_inconsistent=0
debug:    SUMMARY: total=90 match=66 ub_match=18 ub_diff=0 mismatch=1 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=4 cerb_inconsistent=1
float:    SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=0 cerb_inconsistent=0
bytes:    SUMMARY: exec_match=9 neg_pinned=5 fail=0
libc:     SUMMARY: match=7 diff=0
multi_tu: SUMMARY: total=2 match=2 fail=0
elab:     SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
uri:      GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
ci:       SUMMARY: total=242 match=91 ub_match=23 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=110 cerb_inconsistent=18
```

(all check-baseline invocations rc 0 — zero movement everywhere;
parse/core: ALL PASSED. T1-T4 cones enforced in-build at exactly
[propext, runEffectful, Classical.choice, Quot.sound].)

## 4. Decision summary (D1-D4; full text in the decision log)

* **D1 [AGENT]:** iris-lean pin BUMPED to head `34390a0133…` as its
  own early commit + full re-gate (the charter's pre-authorized
  flow); OwnP #653 is the delta's centerpiece.
* **D2 [AGENT]:** S2 boundary verified; the T5 park ACCEPTED as
  design-level (F-T5-1: the blessed St sketch measured FALSE — env
  grows +2 keys/iteration, period 79 not ~30); S1 design AMENDED by
  dated addendum (St-v2 recursive families, walker-v2 type-aware
  normalization); calibration accepted with honest accounting.
* **D3 [AGENT]:** S3 boundary verified; ONE bounded continuation
  authorized for the per-stage certificate emitter (operator
  philosophy quoted in the S3 record §8: clean trust surfaces,
  aggressive optimization outside the TCB); absolute stop rule set.
* **D4 [AGENT]:** the stop-rule trigger was NOT met (no new wall
  class — every wall fell to the emitter design); the session ended
  on CAPACITY. Arc closes per the D3 fallback: workbench = the
  deliverable, T5 parked at evidence grade, v2 takes T5 completion
  as exit criterion 1.

## 5. Census errata + park history (the arc's method result)

**Errata found by measurement, all fixed and committed:**

* the blessed S1 St sketch's constant-`rs` contract falsified by the
  census (F-T5-1) — two Neg-action rewrite rounds per iteration draw
  fresh ids AND bind persistent unit binders (env +2 keys/iter);
* entry env chain has SEVEN inserts (s and i REBOUND by the Esave) —
  found by the k=0 boundary diagnostic, family corrected;
* `arenaL` k=0 carries the entry stores' `Eannot [DA_pos …]` wrapper;
* `FmapCmpIs` → `FmapBuilt` (the tree's CAPTURED comparator is the
  callFinish closure, not the passed one);
* `mem_alloc_block`/`perform_create` generalized over the dead
  `addrOpt` position (opaque `get_with_address` broke DiscrTree
  dispatch); `mem_prefix_block` pref-field correction.

**Park history — two parks, both at evidence grade:**

1. **S2 park (design wall):** the St contract measured false →
   park-don't-improvise → D2 amendment. Cost of NOT grinding: the
   census instrument + closed forms, reused by everything after.
2. **S3 re-park (engine wall) → D3 continuation → capacity park:**
   the kernel-certificate wall measured with a 10-row configuration
   matrix, root-caused (STRUCTURE bounds kernel recursion), solved
   by the emitter; final park is capacity at 44/79 with a named
   next unknown, reproducible in one probe run.

The method result the arc banks: **measure, don't grind** — every
wall this arc produced either a mechanism (emitter, ledger, kernel
engine) or a priced design decision; none produced a transcription
campaign. Doctrine notes for the audit: the heartbeat LEDGER is an
accounting instrument (no ambient raise anywhere, no set_option in
any proof file); the S3 record also carries the T1-indentation
regression root cause and the /tmp write-only incident + transcript
reconstruction, record-grade.

## 6. S4 rebase over the arc-10 merge (close-out mechanics)

Rebased `arc/wp-tactics` (16 commits, old head `30e2ead02`) onto
`mdd/cerberus-lean` @ `56a994469` (the arc-10 merge). Conflicts hit
EXACTLY the arc-10 checklist enumeration: `scripts/test_unit.sh`
(same-hunk UNIT_TESTS + gate tails; resolved as the union —
pp-test + app-walk-test, fork-drift + proof-size);
`lean_frontend/lakefile.toml` and `lake-manifest.json` auto-merged
(iris `34390a0133…` from this branch + LemLib `11d4b4c3cd…` from the
mainline; `[[lean_exe]]` blocks unioned automatically). One
post-rebase integration fix (own commit, `ad1460f59`):
`mem_alloc_block`'s proof gains `readonlyStatusForAlloc_none` to
track arc-10's finding-11 `allocateObject` — statement unchanged.
Regenerated on the new base with the merged opam lem `11d4b4c` (the
stale pre-arc-10 OCaml generated tree tripped the fork-drift gate
exactly as designed; regeneration cleared it). Old→new commit map:

```
0fb68b34a→98cc28725  85bc2dfee→97195f79a  3bf6821c1→970617e8f
c654c86a2→4356e964c  5f7e250ff→97f6d9168  3a470b1df→d122c00fa
fb40ec103→d685de988  5aa4e1248→fbcfca736  2654df80c→89974c5a4
de3c61744→eef1402eb  d1a02c473→b30d828be  7bb957f53→b32694022
b44bbdfbf→22bb6b892  ea0b9db61→65e162efc  2b3a686dd→dfb7143c3
30e2ead02→8f9e53386
```

(the arc records above cite the OLD hashes; this map is the
translation table.) Full post-rebase battery: §3 S4 block.

## 7. Workbench-v2 handoff

* **Exit criterion 1 of v2 = T5 completion**, resuming at §2's named
  point (continuation-lambda advance law first).
* **v2's spine = the survey slate ranks 1-3**
  (`2026-08-21_iris-rules-automation-survey.md` §4, committed at this
  close together with the Lithium source review and the litreview
  brief — v2's S0 inputs): (1) discovery trace + mandatory checked
  replay; (2) finish the pure loop-rule family
  (`iter_compose_var`/`_exit`); (3) context-indexed law
  applicability + typed residuals. Ranks 4-8 stay demand-driven per
  the survey's execution-order note.
* Everything statement-side for T5 is done-waiting (fixture,
  expectations, prefix walk, St-v2 validated, statement shape,
  iter_compose, fuel algebra, proof-size gate row).
* The T6-T10 graded slate (S1 §5) carries over as designed.
* Standing constraints carry over unchanged: statements
  interpreter-only, cones exactly [propext, runEffectful,
  Classical.choice, Quot.sound], heartbeat doctrine (the ledger is
  not a raise), the proof-size bar with its stop-extract-redo loop.

## 8. Adversarial audits (pre-merge, 2026-08-21) — findings + dispositions

Two independent auditors (A: code/soundness lane; B: records lane)
ran the charter-mandated pre-merge audit; the orchestrator
dispositioned every finding and the fixes landed in two commits
(code+gate, then this records batch) BEFORE any merge ask. This
section is a DERIVED summary of the finding list and dispositions
(the auditors' raw reports were session material; tallies here were
re-verified at head where cited).

**Auditor A:**

* **A-F1 (FIXED — code).** `dischargeHyp`'s mkAuxRfl catch in
  `Tactics/AppWalk.lean` wrote a debug repro to a HARDCODED absolute
  worktree path (`.../wp-tactics/scratch/repro.txt`), and an IO
  failure there could mask the original exception. Fix: the repro
  content (fact type + referenced walk const types/bodies) is folded
  into the `dbg_trace` stream — no file IO in the catch, debug lane
  keeps full diagnostics, trace-lane-only (full build + calibration
  green unchanged).
* **A-F2 (FIXED — records).** The §1.1 sizing-reconciliation sentence
  claimed both the "~380→~150" and "456 → 369" accountings live in
  the S2 record §1; the "~150" has no S2-record source (it was a
  D4-text estimate). Rewritten honestly in §1.1; decision-log C1
  item 2.
* **A-F3 (FIXED — records).** Census stales (with B-F3): Kit/Mem is
  139 lines at head (was quoted 133 — stale, predates `ad1460f59`);
  kit-file census stated precisely (7 files = 6 content kits +
  `Kit/Audit.lean`, 54 pins). §1.2 corrected; decision-log C1 item 3.
* **A-F4 (RECORDED — v2 cleanup slate).** Dead lanes, WIP-stale
  docstrings, and unused `normCompute` parameters in the walker:
  accepted as a workbench-v2 cleanup slate item (no behavior change,
  not fixed in the audit window by design — the walker is v2's
  primary work surface).
* **A-F5 (FIXED — gate).** The proof-size gate's debug-surface ban
  covered only `app_walk?`; `app_defeq_diag`, `dnms_kwalk`, and
  `app_walk_norm!` were uncovered. All three are now banned in
  committed (git-tracked) relsem files — none appear in any committed
  proof (T1AppEq/T5Prefix verified clean); untracked Probe*/scratch
  stays exempt via the tracked-file filter; policy recorded in the
  script header; plant-tested both directions (planted tracked hit →
  FAIL rc=1; untracked `app_walk_norm!` in ProbeT5S3.lean → exempt,
  OK rc=0).
* **A-F6 (RECORDED — note).** The walker's kernel-engine couples to
  NAME CONVENTIONS (`walkSt*`/`kwSt*` prefixes, `_aux` suffixes) at
  its avatar/seal filters — a rename would silently change engine
  behavior. Accepted as a recorded coupling (v2's trace/replay item
  is the structural fix; no committed name is currently ambiguous).
* **A-F7 (VERIFIED HONEST).** The heartbeat LEDGER audit came back
  clean: it is accounting-only as claimed — no ambient raise, no
  `set_option maxHeartbeats`/`maxRecDepth` anywhere in proof files.
  Positive finding, no action.

**Auditor B:**

* **B-F1 (FIXED — records).** The calibration headline "≈700 → 5"
  conflated the design's ≈700-line SEGMENT estimate (which includes
  retained semantic support) with the walker's actual kill. Honest
  form (now everywhere the headline propagated — §1.5 here,
  lean_frontend/CLAUDE.md, merge-checklist step 6; decision-log C1
  item 1): the mechanical dnms content ~200 lines → 5 walker lines;
  file-level T1AppEq 1,038 → 862; round3/round6 semantic support
  retained and consumed.
* **B-F2 (FIXED — records).** The S2 record §4.2 census block was
  labeled "(t5-probe … verbatim)" but is a condensed/DERIVED digest
  of a session-scratch instrument run (the committed instruments
  print different formats). Relabeled + annotated per the arc-6
  relabel-don't-rewrite remedy; facts independently reproduced by
  auditor B's re-run (223 rounds, period 79, env dom 26 vs 28).
* **B-F3 (FIXED — records).** Census stales, jointly with A-F3
  (Kit/Mem 139; six-kits/54 vs "7 kits/50+" reconciled precisely).
* **B-F4 (nits; two fixed, two recorded).** (i) FIXED: the S0 survey
  §1.3 OwnP line-cite pair for `OwnPGpreS`/`OwnPGS` was swapped —
  now `OwnP.lean:31/:23` (verified against iris @ 34390a0133:
  OwnPGS at :23, OwnPGpreS at :31). (ii) FIXED: the two S2-record
  heartbeat-timeout quotes dropped the message's set_option-hint
  tail without marking — truncation markers (`[…]`) added.
  (iii) RECORDED: the S0 survey line "`Audit.lean` + `Audit/Kit.lean`
  (1964 lines of exactness pins)" — clarification: 1964 is golean's
  `proofs/Audit.lean` ALONE; `proofs/Audit/Kit.lean` is 639 (2603
  combined; re-counted at deps/golean @ f78138d7). (iv) RECORDED:
  §2's `iter0_probe` "~10 min wall" is CONSERVATIVE — the audit
  re-run completed far faster (~39 s reported); the recorded figure
  was the original discovery-session wall and stands as an upper
  bound.
