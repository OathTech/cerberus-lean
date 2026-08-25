# Arc 17 S2b — THE BOUNDARY-AXIOM ENDGAME + the T4 seam (record)

Worker record, 2026-08-25. Charter:
`2026-08-24_arc17-automation-framework-charter.md`, slice S2b (the
[USER 2026-08-24] "resolve the additional axiom uncertainty" slice),
with the T4 completion folded in per the S2 handoff. Branch
`automation-framework`; this slice's commits: `ef6624ac2` (the axiom
deletions + census end state + boundary-opaque gate), `18926043c`
(the runEffectful no-cone-entry gate), `caa410575` (the evaluator
hypothesis-threading mode; T4 frontier round 1 → 17), plus the docs
commit carrying this record. [AGENT] decisions marked; every quoted
output is verbatim from this session's EXIT-CHECKED runs.

## 1. Per-axiom FINAL DISPOSITIONS (charter deliverable b — executed)

| axiom | disposition | mechanism | evidence |
|---|---|---|---|
| `CerbTags.with_tagDefs` (axiom since arc-4 S1r) | **DELETED as an axiom** | now `opaque … := fun _ f => f ()` — kernel-checked inhabitation witness (the effect-erased meaning: OCaml `Tags.with_tagDefs` returns exactly `f ()` around the set/restore extent); still irreducible (opaque), still `@[implemented_by]`-bound to native/tags.c `cerb_tags_with`; `never_extract` armor added to match `tagDefs` | build green; test_exec 106 zero-movement incl. the 106-sizeof-struct-array obligation test that found the original DCE bug; boundary-opaque gate |
| `CerberusFresh.forceIO` (axiom since arc-5 S2) | **DELETED as an axiom** | now `opaque … := fun f => pure (f ())` (the witness its own docstring always stated); `@[implemented_by]` → native/md5.c `cerb_force_thunk` unchanged | build green; FreshIntTest `testDigestGlobal` (the test that found the original let-sinking bug) in the green unit battery |
| `LemLib.runEffectful` (dep: lem-lean lean-lib) | **RETAINED + GATED** (temporal) | deletion is lem-side surgery, out of this repo/slice's scope; consumers = the ambient theorem family (retires at the S5 purge) + compiled driver paths; NEW tree-wide no-cone-entry gate pins its exact theorem-carrier set (114 names), both directions build-fatal | gate transcript §3; PROOF.md §1 re-justification |

Notes on the conversion (the audit-grade honesty items):

- An `opaque` with an explicit witness is NOT a postulate: the kernel
  checks the witness (consistency by construction — the DAEMON saga
  is why this distinction is load-bearing), while the constant stays
  exactly as irreducible to proofs as the axiom was. Nothing changes
  for the compiler: `@[implemented_by]` takes precedence in both
  forms, so the compiled artifact is the same armor as before. The
  runtime trust surface is exactly where it always was — the
  implemented_by/extern boundary (a declared immovable object).
- The arc-4 S1r phrase "the axiom form survives the DCE that erased
  the opaque form" was re-audited against the decision log: the
  DCE'd form was the LEAN-SIDE set/restore implementation (discarded
  `let`s), not an opaque-with-implemented_by; the fix was the C-side
  whole extent, which this conversion keeps byte-identically.
- Bonus hygiene: the two `unsafe opaque` extern declarations
  (`withTagDefsIO`, `forceThunkIO`) carried witness-less
  synthesized-sorryAx inhabitants that printed `declaration uses
  'sorry'` warnings on every build (pre-existing, invisible to all
  cones/gates). Both now have explicit witnesses; the warnings are
  gone.

## 2. Census end state + gates (charter deliverable c)

- Hand-written axiom census (`check_theorem_axioms.sh`): **2 → 0**,
  fail-closed on any new `^axiom`.
- Generated-tree census: axiom allowlist **EMPTIED** (any axiom in
  any generated file fails); the scanner/copy-pipeline liveness leg
  re-anchored on the two converted opaques (each must be found
  exactly once — the old anchor was the axioms themselves).
- `RelSem/Audit.lean` `allowedAxioms`: shrunk to the classical trio +
  `runEffectful`.
- NEW **boundary-opaque gate** (DAEMON-gate pattern): each of the two
  names must EXIST, must NOT be an axiom, MUST be an opaque (a plain
  def would let proofs unfold the witness and relate states across
  the effect boundary — the effect-erasure invariant's kernel leg),
  and may never be allowlisted. Fail-closed in all four directions.
- NEW **runEffectful no-cone-entry gate**: the set of RelSem-module
  THEOREMS whose transitive cone contains `runEffectful` is pinned
  EXACTLY (114 registered ambient-family names). Acquisition by an
  unregistered theorem is build-fatal (never merely unpinned); a
  stale entry is build-fatal until deliberately removed. Compiler
  sub-proofs (`_proof_*`) are excluded from the pin with the recorded
  rationale: a sub-proof is referenced by its parent, so the parent's
  cone contains everything the child's does — acquisition always
  surfaces at a named theorem; internal names are also unstable
  across recompiles.

Green-state lines (verbatim):

```
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (195 files: 0 axioms, boundary opaques present, 0 unsafeCast)
info: RelSem/Audit.lean:246:0: RelSem boundary-opaque gate: with_tagDefs/forceIO exist, are opaque (kernel-checked witnesses, not axioms), and are not allowlisted
info: RelSem/Audit.lean:1096:0: runEffectful no-cone gate: carrier set exact (114 registered ambient-family theorems; no acquisition, no stale entries)
```

## 3. Plant transcripts (both directions, rebuild-after-revert)

Census/script plants (exit codes captured):

```
P4a hand-written stray axiom -> check_theorem_axioms: FAIL — hand-written axiom census: found 1 '^axiom' declarations, expected exactly 0 (...)
P4b generated stray axiom  (RC=1) -> FAIL — generated-tree census: axiom declaration(s) found (allowlist is EMPTY since arc-17 S2b ...) / AXIOM CerbDebug.lean:71:plantGenAxiomS2b
P5  opaque renamed         (RC=1) -> FAIL — generated-tree census: converted boundary opaque /CerbTags\.lean:[0-9]+:with_tagDefs/ found 0 times, expected exactly 1 (copy pipeline or scanner drift; fail-closed)
```

In-build plants (each a real relsem build, RC=1; targeted-edit
reverts; full green rebuild after):

```
P1 axiom reintroduced -> error: RelSem boundary-opaque gate: CerbTags.with_tagDefs exists as an AXIOM — ... reintroduction is a build failure, never a re-baseline.
P2 def form           -> error: RelSem boundary-opaque gate: CerbTags.with_tagDefs is neither an axiom nor an opaque — the effect-erasure armor requires the constant to be IRREDUCIBLE ...
P3 allowlisted        -> error: RelSem boundary-opaque gate: CerbTags.with_tagDefs is ALLOWLISTED as an axiom — ... there is no sanctioned path back. Revert.
P6 unregistered carrier theorem -> error: runEffectful no-cone gate FAILED — theorem cone(s) ACQUIRED the residual boundary axiom (acquisition is build-fatal; ...)
P7 registered entry removed while carrying -> same acquisition failure (removal cannot silently shrink the pin)
P8 trio-clean theorem registered -> error: runEffectful no-cone gate: registered carrier(s) no longer carry the axiom (re-founded upstream?) — REMOVE them deliberately, same commit, with the reason
```

Process finding (logged for the audit trail): the first P3 attempt
reverted `Audit.lean` with `git checkout --`, which silently
destroyed the slice's own uncommitted gate — the subsequent P1 run
then "passed" against the gateless file. Caught by line-number drift
in the build log; edits re-applied; ALL plants re-run against the
real gate. Lesson: plant reverts on files carrying uncommitted work
are targeted edits, never `git checkout`.

## 4. THE TAGDEFS SEAM, ONCE (deliverable 1) — design + what shipped

One seam, two consumers, as briefed — with the honest boundary drawn
by the evidence:

(i) **The evaluator hypothesis-threading mode — BUILT** (commit
`caa410575`; the S2-registered M item). `derive_rounds` gains
`assuming h₁ … hₙ`: named Prop binders become a hypothesis pack the
mints consume, producing CONDITIONAL round equations (∀-closed over
the binders; successor defs close over value binders only,
fail-closed on proof leakage). The load-bearing mechanisms, each
measured in after a documented wrong design:

| mechanism | the wall it answers (measured) |
|---|---|
| curated tidy-pattern rewrites (kabstract, head-keyed defeq matching), SUBSTITUTE-FIRST | whnf explodes stuck operands through recursor branches; substitution into dependent (Decidable-proof) positions builds ILL-TYPED junk — probe: post-subst `isDefEq _ 8 = false` |
| THE ATTRIBUTE FENCE: temporary `@[irreducible]` on pattern-head constants for the drive's extent, restored at every exit | a `canUnfold?`-hook fence cannot mirror default unfolding (smart-unfolding/WF gating lives outside it): raw `Acc.rec` towers, 200k-heartbeat death |
| the MATERIALIZED-MEMORY TWIN (`Anchor.memMat`), incremental deltas | one-shot ladder materialization 1.4 s+ vs 4 ms/delta (~350x); twin serves VALUE derivation only and never enters goals (its tree-WF proof terms made kabstract scans ~1.2 s) |
| KERNEL-DEFERRED side-condition finisher (`congrArg` chain + `Eq.refl`, kernel recomputes at addDecl) | the elaborator's lazy defeq on ladder residuals was the budget burn; the kernel is heartbeat-free (the S0 recompute-and-check contract — a wrong residual is a loud addDecl failure naming the round) |
| the RESPELL BRIDGE (proved `congrArg` chain glues law proof to the respelled successor) | hypothesis substitutions are propositional; unglued respells were kernel type mismatches (rT5) |
| groundNorm memoization + `isProofQuick` + the inert continuation-table rule | quadratic re-walks; labeled-continuation fields are program text — materializing them is stdlib-sized |

NO budget bumps anywhere: every wall was answered with design.
The hypothesis-free path is byte-identical by construction (empty
pack; T6's 51-round ground drive re-verified unregressed in the same
build).

(ii) **`with_tagDefs`'s consumer disposition.** The spike survey's
consumer map was re-verified: the ONLY generated call site is
`Mini_pipeline.run_const_expr_driver`, where (on the Lean target) the
table is ALREADY threaded — `tds` is the reader seed for every lifted
callee — and the `with_tagDefs` wrapper exists solely to sync the
AMBIENT global for the hand-written CerbMem reads during the extent
(the arc-2 S6 split-read fix; deleting it re-opens
106-sizeof-struct-array). [AGENT] The extent mechanism therefore
STAYS (it is load-bearing until CerbMem itself is supply-threaded —
the machine-state end state, cmm-arc-adjacent, explicitly out of this
slice); what is DELETED is its axiomhood (§1). This is the honest
reading of "rethreaded to take the table explicitly": the table
already IS explicit on the Lean target; the residual ambient sync is
implementation armor, not a kernel assumption — and it now carries
zero axiomatic content.

`forceIO` likewise: consumers (Main.lean per-TU loop ×3,
FreshIntTest) keep their call sites — the barrier is load-bearing
compiled-side armor — and the axiomhood is deleted (§1).

## 5. T4-threaded: frontier round 1 → 17; PARKED at the arith-minter
    wall (the honest park)

Under the pack `(hap : seed+1 < 229457971439601039)
(htags)(hdig)(hsz)(halign)(hshiftA)(hshiftB)(hunspec)(hszI)(hrecv)`
— every fact derivable from the ambient T4AppEq vocabulary under
`htags`/`intRange x` — the drive from `dRdyT seed x` now mints
**17 rounds mechanically** (classes: runstate/create/tau/store/load;
42–914 ms per round, flat; verbatim tail):

```
[RelSem.roundEval] round 9: runstate (69 ms)
[RelSem.roundEval] round 10: load (114 ms)
[RelSem.roundEval] round 11: runstate (291 ms)
...
[RelSem.roundEval] round 16: runstate (900 ms)
[RelSem.roundEval] round 17: tau (118 ms)
info: derive_rounds RelSem.T4.rT: 17 advancing rounds minted
```

Headlines: the OLD frontier (round 2, the struct create) fell to the
curated `hsz`/`halign` facts; the struct store-unspecified (round 5)
to `hunspec`; the **x-symbolic load of v** (round 10) to the `hrecv`
roundtrip fact — and the S2-registered load-round cost (~7 s in the
t6 probe) fell to **~120 ms** (twin + memoization), killing that
registered item.

**THE NEW MEASURED FRONTIER — round 18, the conv range check on x.**
The eval sticks on Int-comparison DECIDABLE towers over the open x
(`match x + 2147483648 with | ofNat _ => isTrue … | negSucc _ =>
isFalse …`, from the inlined stdlib conv body — dumped verbatim in
the session log). A rewrite cannot fix a stuck constructor-match;
this needs the **ARITH MINTER**: mint `⟨stuck decidable/Bool
spelling⟩ = ⟨verdict⟩` facts from the pack's range hypotheses
(mechanical recipe identified: `Subsingleton (Decidable p)` +
`congrArg` + omega — the same subsystem the anon-seed comparisons
need under `hap`). [AGENT] PARK decision per park-don't-improvise:
the remainder is three enumerable subsystems, each of the same
empirical-campaign class as the ones above, and the slice's charter
exit condition (the axiom story) is fully delivered.

ENUMERATED REMAINDER (registered, priced):

1. THE ARITH MINTER (M) — Int/Nat comparison decidables + Bool
   matches under range/apartness hypotheses; unlocks the conv rounds
   (~R18–24 and the R25–41 twin cycle at literal 7) AND the
   anon-env rounds (seed-vs-static verdicts feeding the Kit/Env
   lookup lemmas — the S4-priced region, its Kit tools already
   landed in S2).
2. The SeqRMW mint branch over `perform_seqrmw` (S–M) — the staging
   (hload/hmid/hrmw/hstore) exists as the S2 law; the rmw-compute
   stage consumes the minter's facts + `hdig` (the fresh draws).
3. Terminal artifacts + the wpK walk + statement discharge (S — the
   T6 template; the walk supplies the pack from the statement's
   hypotheses, discharging the curated facts via the ambient
   T4AppEq lemmas from `htags`/`intRange`).

The ambient T4 (T4EnvHyp route) stands untouched;
`T4ThreadedStatement` (the guarded ∀-seed face) stands landed.

## 6. Spec-lab statement substrate — the scope call (charter
    deliverable a; ASSESSED, registered for S4)

Evidence: `HarnessRunsTo` is copied per family (6 files, 55
references) and quotes `CerbND.runND (drive …) (initial_driver_state
…)` — the AMBIENT initial state; 19 `initial_driver_state` quotes;
15 proved lemmas in `speclab/proofs` consume the statements; 46
statements under the SpecLabAudit gate. Moving to the threaded state
CASCADES: (a) `initial_driver_state_threaded` lives in the relsem
package, which the SpecLab STATEMENT lib must not import (the
two-part-design one-way seam) — the threaded initial state needs a
root/semantics-side home first; (b) every family's statement def,
every consuming lemma, and the full pin surface re-lands; (c) the S4
family-∀ slice re-lands exactly these statements anyway. [AGENT] Per
the charter's own prune-thinking note, REGISTERED FOR S4 with price
M: thread the seed in the same rewrite that upgrades sample-∀ →
family-∀, prerequisite = a statement-layer threaded-initial-state
def reachable from the SpecLab lib (the supply-passable
forward-design constraint keeps this a mirror-def, S).

## 7. PROOF.md §1 rewrite (deliverable d) + §3 currency

§1's "declared boundary axioms — exactly three … scheduled for
elimination" is REWRITTEN to the achieved state: zero axioms in this
repository (the two conversions, with their witnesses and the
boundary-opaque gate named); `runEffectful` as the single residual —
where it lives, why it remains (temporal, lem-side mover, purge
retirement), and the two gates that guarantee no theorem acquires it
silently; the threaded family's trio-exact cones vs the ambient
quartet, stated exactly; and the standing implemented_by/extern
boundary as where runtime trust actually lives. §3 re-read for
currency (the professor re-review habit): the threaded-family
re-proof and T4's guarded statement are now stated; the stale
chase/stepper pointer in "Not yet proved" is replaced by the arc-17
framework + post-mortem pointers. CLAUDE.md's boundary line and
TODO.md's "kill the effect axioms" item updated to match.

## 8. Validation (verbatim, at the slice head; every run exit-checked)

```
Build completed successfully (367 jobs).   [root]
Build completed successfully (391 jobs).   [relsem; all 5 gate lines print]
Build completed successfully (143 jobs).   [speclab; 46 statements clean]
Total: 7 passed, 0 failed                  [test_unit]
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0   [test_exec, zero movement]
```

Sweep re-baselines (provenance at the pin): 4438 → 4439 (the
no-cone gate's registered list) → 4552 (the hypothesis engine + the
T4 drive's 17 rounds — the sweep line is the trio-cleanliness
witness for the conditional equations). Statement gate steady at 27;
no new sorries; lem-sync + fork-drift green inside the unit battery;
OCaml side untouched.

## 9. Registered items (S2b close; S3 handoff)

1. T4 completion = the arith minter (M) + SeqRMW branch (S–M) +
   terminal/walk/statement (S) — §5; all prerequisites landed.
2. Spec-lab substrate threading — registered for S4 (M + S
   prerequisite), §6.
3. `runEffectful` deletion — lem-side surgery (a lem arc; the
   no-cone gate + purge retirement bound it meanwhile).
4. The load-round cost item (S2 record §7.2) — CLOSED (twin +
   memoization; 7 s → ~120 ms).
5. S3 (T5-by-invariant) note: the hypothesis engine's conditional
   equations are exactly the body-step feeds the invariant proof
   consumes; nothing in this slice's machinery assumes bounded runs
   beyond the evaluator's existing design.
