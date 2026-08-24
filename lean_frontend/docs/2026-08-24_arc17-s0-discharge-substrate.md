# Arc 17 S0 — the discharge-engine substrate (record)

Worker record, 2026-08-24. Charter:
`2026-08-24_arc17-automation-framework-charter.md`, slice S0. Branch
`automation-framework` (off mainline `5b1a3631b`); this slice's build
commit: `ec049e05c` (emitter + discharger + wiring), plus this record.
Design source: the ACL2Lean donor review
(`notes/2026-08-24_acl2lean-donor-review.md`); donor tree read at
`deps/ACL2Lean` @ `5ec2a4b`. [AGENT] decisions marked; every number
below is from this session's builds/probes (probe scratch deleted
before commit, content preserved here — the S4 record's pattern).

## 1. Deliverable (a) — the `derive_state` named-constant emitter

`RelSem/DeriveState.lean` (registered in lakefile roots, RelSemAll,
Audit closure). Donor pattern: `derive_world`
(deps/ACL2Lean/ACL2Lean/Replay/Driver/DevQuery.lean:74-87; review §4)
— a fixture-scale object is minted ONCE as a named top-level constant
(`hints := .abbrev` + `enableRealizationsForConst`, "a concrete
(fast-reducing) def"), goals and statements reference it BY NAME, and
it unfolds only inside kernel `whnf`/`decide` on demand.

Two command forms:

- **`derive_state id (bs…) : ty := t`** (naming form): mints
  `def id` (abbrev hints, realizations, provenance docstring) + the
  equation lemma `id_def : ∀ bs…, id bs… = t` (kernel-checked `rfl`)
  — the `rw`/feeding handle. Generalizes the hand pattern already in
  the tree (S1's `sGlob`, S4's `_thr` ladders).
- **`derive_state_step id (bs…) from m at σ [expecting σ']`** (step
  form): computes `app m σ` ONCE in the meta layer (`whnf` outside
  any goal — the HeapLang-ProofMode architecture named in S3 §7),
  demands an active head `(NDactive v, σnext)` (tagged frontier error
  otherwise, fail-closed), and mints the step equation `wp_step`
  consumes: without `expecting`, a named successor `def id` + 
  `id_app : app m σ = (NDactive v, id bs…)`; with `expecting σ'`,
  only `id : app m σ = (NDactive v, σ')` at the caller's canonical
  spelling. Either way the equation is proved by `rfl` at `addDecl`
  — the KERNEL recomputes and checks; the meta `whnf` is never
  trusted (the donor's recompute-and-check consumer contract, review
  §1).

The donor's frontier-tag mechanism is LIFTED (~15 lines;
Reflect.lean:79-91, review verdict row 2): deliberate frontiers throw
tagged errors (`RelSem.deriveStateFrontier`), classified by tag never
message prefix — the S1 engine's catch-and-classify hook.

DELIBERATE DEVIATIONS from the donor (per the brief, with reasons):

1. **No value-level reflection.** The donor reflects a RUNTIME value
   (SExpr world) to an `Expr`; our states are already Lean terms, so
   the emitter abstracts binders instead — our states are
   seed/argument PARAMETRIC where the donor's worlds are closed.
2. **Command-level emission only** (like `derive_world`), no
   tactic-time minting: under Lean ≥ 4.32 parallel elaboration,
   `addDecl` from inside a tactic has fragile visibility across
   concurrently elaborating theorems. Registered as the reason the
   tactic layer CONSUMES minted equations (via `wp_step`) rather than
   minting mid-proof.
3. **`addAndCompile`** kept donor-exact (states may be referenced by
   compiled test executables), but the equation lemmas are plain
   `addDecl` theorems.

Implementation notes banked for S1 (collision knowledge): anonymous
optional groups (`("expecting " term)?`) parse but do NOT bind in
`elab` headers — the clause needs its own named `syntax` node; an
equation mentioning the minted constant must be built AFTER `addDecl`
(`mkEq` infers the constant's type); `bracketedBinder` is reachable
only via its registered parser alias (the `F`-suffixed def refuses
codegen).

### 1.1 Wiring into the S3 tactic layer

`RelSem/PerStepTactics.lean` imports the emitter and documents the
contract: minted `…_app`/`expecting`-mode equations feed `wp_step`
directly (the named-state feeding path — the S3-measured cheap
regime); goals ride state NAMES, never inlined records or projection
chains. No tactic-shape changes were needed — `wp_step` was already
the feeding path; the emitter is its SUPPLY SIDE (that was the S3
park's fix #1, priced in the donor review §9 item 2).

### 1.2 The T1Threaded re-elaboration (S4 fixture through the emitter)

`RelSem/T1Threaded.lean`'s state ladder (`rsD3_thr`, `rsR6_thr`,
`drDone_thr`) re-emitted through `derive_state` — names and
definition bodies byte-identical, so every downstream proof, the
statement gate's vocabulary allowlist (`drDone_thr` rows), and the
statement spellings are untouched.

- Elaboration time: **1.1 s → 1.1 s** (forced rebuilds, lake module
  line, two runs each side; matches the S4 record's 1.1 s).
- Goal-state sizes: unchanged by construction — goals mention the
  same constant names; only the definition MECHANISM changed
  (regular-hint hand `def` → abbrev-hint emitted def + `_def` lemma).
- New lemma cones (VERBATIM, session probe; Audit-pinned
  build-fatally):

```
'RelSem.T1.rsD3_thr_def' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.rsR6_thr_def' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.drDone_thr_def' depends on axioms: [propext, Classical.choice, Quot.sound]
```

- The threaded family's committed cones re-probed unchanged
  (VERBATIM): `T1Threaded`, `T1Threaded_ubFree`, `T1ThreadedOutcomes`
  each `[propext, Classical.choice, Quot.sound]`.

### 1.3 The k9-cliff probe (the S3 park's measured shape)

Probe pair on the S3 record §5 configuration (T1 through `callK`,
`t1_wpK_tac`'s statement byte-identical; the killed 10 GB end-to-end
attempt was NOT re-run, per the brief — this is the small
representative):

- **BEFORE** (the S3 config: the `k9_update` feed replaced by
  `wp_pures`, so stage 9 self-computes and the repeat then attacks
  the loop atom at an inlined state): **killed at ~151 s wall, twice,
  consistent** (exit 143 under `CERB_MEM_MAX=48G` capped; no
  heartbeat-timeout message reached the log before the kill —
  consistent with the S3 profile for this shape: heartbeat timeout
  inside one `whnf` at ~10.4 GB RSS isolated, > 64 G full-module).
  S3 recorded the same configuration as "> 120 s"; confirmed.
- **AFTER** (the emitter path: stage 9's equation MINTED by
  `derive_state_step … expecting (mkDr th0 (memD3 x) rsD3 [] 0)` and
  fed to `wp_step`; everything else identical): the WHOLE file —
  mint + kernel recheck + the full 8-line T1 WP walk — elaborates in
  **~1.5 s wall** (`lake lean`, includes lake overhead). Cones
  quartet, identical to the committed ambient `t1_wpK_tac` pin
  (`runEffectful` enters through the quoted ambient harness
  substrate, as everywhere on the ambient T1 route).
- Refinement of the S3 attribution [AGENT, measured]: a SINGLE
  `wp_pure1` for stage 9 followed by the `driver2_iter` feed
  elaborates clean in ~1.6 s — the raw projection→named defeq bridge
  at stage 9 is affordable in isolation; the dominant cost in the
  BEFORE configuration is the `repeat`'s attempted self-computing
  step ON THE LOOP ATOM, whose activation `whnf` inlines the state
  into the loop body (the compute-forward regime exactly). The
  discipline stands either way: stay in the named regime — minted
  equations step name → name and the repeat never meets the loop
  atom unarmed.

Verdict against the brief: "a state which previously forced whnf
inlining now rides its name" — demonstrated: killed-at-151 s → 1.5 s
on the same statement, with the stage-9 equation now MECHANICALLY
minted (no hand `subst`/`rfl` lemma authoring, no knowledge of the
successor's spelling needed beyond naming the canonical target).

## 2. Deliverable (b) — the memoized ground-fact discharger

`RelSem/WpGround.lean`. Donor LIFT, near-verbatim (~100 lines with
docs): `proveByDecide` + memo cache
(deps/ACL2Lean/ACL2Lean/Replay/Driver/Reflect.lean:93-120; review §2
+ verdict row 1). Kept donor-exact: kernel decision only
(`synthInstance` the `Decidable` instance, `whnf` at transparency
`.all` on `decide p inst`, demand literal `Bool.true`, emit
`of_decide_eq_true p inst (Eq.refl true)` — the kernel recomputes at
type-checking); NOT heuristic (no simp set, no search); memo keyed on
the whole Prop `Expr` (structural `==`, pointer-eq fast path);
successes-only cached. Ban-compliant: no `ofReduce*`, no native
evaluation; D14 grep-ban and the cone gates stay green.

Deviations (recorded): (1) cache STATISTICS
(calls/hits/failures, `#wp_ground_stats`) — the donor keeps none;
our budget doctrine wants the instrument; (2) the tactic face
`wp_ground` guards on CLOSED goals (fvars/mvars fail fast) so
`first`-chains fall through to `assumption` for hypothesis-shaped
side conditions.

Wiring: `wp_side` (the side-condition entry of
`wp_load`/`wp_store`/`wp_alloc`/`wp_kill` and future laws) is now
`assumption | wp_ground | rfl`. The old trailing bare `decide` is
subsumed (kernel decide + memo behind the guard). Exercised across
the S3/S4 population by the full rebuild: `two_alloc_frame_tac`
(hypothesis-fed side conditions → `assumption` path) and the
tactic-face examples on concrete layout facts (below) all green.

### 2.1 Micro-benchmark (donor-analogue numbers, honestly sized)

Population: six S3/S4-class kernel-computable side conditions at
concrete T1 vocabulary (`ctypeMemCompatible`, `isInBounds` ×2,
`isAtomicMemberAccess`, `Kit.isBoolTy` — `wp_load`'s `hnotbool` —
`sizeofCtype`). Bench harness called
`proveGroundCore`/`proveGround` directly in `TermElabM` (verbatim
output):

```
bench mode=core props=6 reps=1 calls=6 elapsed=3ms (stats: calls=0 hits=0 failures=0)
bench mode=core props=6 reps=600 calls=3600 elapsed=13ms (stats: calls=0 hits=0 failures=0)
bench mode=memo props=6 reps=600 calls=3600 elapsed=9ms (stats: calls=3600 hits=3594 failures=0)
bench mode=memo props=6 reps=600 calls=3600 elapsed=7ms (stats: calls=7200 hits=7194 failures=0)
wp_ground stats: calls=7204 hits=7198 failures=0 cached=6
```

(The final stats row includes 4 `wp_side`-tactic-face example
discharges — all cache hits.)

HONEST READING [AGENT]: at 3,600 calls the donor measured ≈ 3.4 s
pre-memo; our analogue population costs 13 ms pre-memo — today's
side conditions are byte-level ground facts that kernel-whnf in
microseconds, and `MetaM`'s own whnf/instance caches already absorb
in-context repetition. The memo's measured effect here is real but
marginal (13 → 9/7 ms). The port is DONOR-SHAPED INSURANCE, priced
at ~zero: the population it exists for is S2's apartness/ordered-map
side conditions and S1's per-construct law side conditions at scale,
where repeat pressure across many rule applications in one module is
the donor's measured regime. If that population also proves
kernel-trivial, the memo stays as free correctness (successes-only,
keyed on the exact Prop).

## 3. Deliverable (c) — THE AUTOMATION-TRACE FORMAT SPEC (spec only)

Design section for part 2's engine; no implementation this slice
([AGENT]: a parser stub with no producer or consumer would be dead
code under the professor-clean standard — S1 implements against this
spec). Donor format: the s-expression proof-log event stream at three
nested granularities (review §1; the surviving log
`acl2_samples/pattern-tests/p8-clausify-detail.proof-log`;
`ACL2Lean/ProofLogTypes.lean`). Adopted contract, adapted
deliberately:

### 3.1 Orientation (the donor's ratified invariants, ours now)

1. **PROOF-PRODUCING, never a verified checker.** The engine emits
   ordinary kernel-checked proof terms; the trace is an AUDIT/REPLAY
   artifact beside them, never a trust carrier. NO monolithic
   `Derivation` inductive with one global soundness theorem — the
   donor's L1 invariant plus its verified-rewriter → proof-producing
   pivot (project-history ch. 1–2) is the earned evidence, from a
   far simpler logic than ours. Any future fragment wanting a
   deep-embedded checker needs post-exhaustion justification under
   canon-first.
2. **Record the CHOICE, not the derivation.** Every atom names the
   rule applied, the position, and the instantiation — enough for a
   consumer to RECOMPUTE the instance and equality-check it against
   the record (the donor's "the checker does no inference";
   `NodeCore/Congruence.lean:343-357`'s emission-gap hard-fail is
   the model). Missing information is fixed by MORE EMISSION at the
   producer, never by consumer-side search.
3. **Fail-closed with TYPED frontiers.** Every stuck point is a
   tagged event (tag taxonomy below), classified by TAG, never by
   message-string prefix. The `frontierTag` mechanism landed in
   `RelSem/DeriveState.lean` this slice is the shared carrier.
4. **No fuel in atoms.** The donor pushes fuel-robustness into the
   statement shape (`∃N ∀f≥N`) so certificates carry no fuel
   arithmetic; our analogue is already in place — the runner
   observation algebra states everything at `F ≤ lemDefaultFuel`
   (S3 §2.2) and states/laws are fuel-silent. A trace atom carrying
   a fuel number is a format violation.

### 3.2 Carrier and provenance

- **Lean-native structured events** (an ordinary inductive in the S1
  registry module), with a JSON-lines serialization face for
  tooling. DEVIATION from the donor's s-expression text stream, with
  reason: their certificate crosses a FOREIGN-ORACLE boundary
  (instrumented ACL2 → Lean), which forces a textual interchange
  format plus the whole authenticity apparatus (hash sidecars,
  provenance pins). Our producer and consumer are both in-repo Lean;
  authenticity collapses to code review (review §6 "Breaks"), so the
  interchange face is secondary and the typed in-memory stream is
  primary.
- **Provenance header event** (donor §1 item 4, trimmed to our
  setting): producer identity = repo commit + engine module name; no
  hash sidecars.
- Size discipline: atoms reference states, laws, and equations BY
  NAME (the derive_state discipline makes this possible — a state
  name is the compression); the donor accepted verbose text
  (5.7 KB/trivial theorem) and never measured size pressure — with
  name references we expect strictly less.

### 3.3 Granularities (donor's development/clause/rewrite-step,
     mapped)

1. **Per-WP-step** (≈ donor clause level): one event per step of the
   walk — `{goalId, parentId, lawName, joint}` where `joint`
   locates the head atom in the peeled spine (`dnmsK`/`driver2K`
   position). Events link into a tree by goalId lineage exactly as
   the donor's clause-id lineage ("the inverse of `waterfall1-lst`");
   unlinkable structure hard-fails reconstruction.
2. **Per-law-application** (≈ donor rewrite-step level): the
   hypothesis instantiation of the law fired — each fed equation BY
   NAME plus its binder instantiation (the `:SUBST` analogue), the
   before/after state NAMES (`:LHS`/`:RHS` analogue at state
   granularity). For emitter-minted equations the name itself
   carries provenance (its docstring records the emitting command).
3. **Per-side-condition** (≈ the donor's verdict-only-leaf
   carve-out, which is RATIFIED there and adopted here with the same
   scope discipline): one event per `wp_side` disposition —
   `assumption h | ground | rfl` — with the Prop (pretty form +
   structural key) for `ground`. The consumer closes a `ground` leaf
   by its OWN kernel decide (recompute, never trust the recorded
   verdict); using a leaf event to shortcut a RECORDED step is
   forbidden, exactly the donor's carve-out boundary
   (`docs/plans/2026-06-09_direct-proof-emission.md`).

### 3.4 Frontier taxonomy (initial; tags, extensible by S1)

`unknown-construct` (no registered law for the discovered round
class), `non-active-head` (ND/killed head where a deterministic step
was requested — the derive_state_step frontier), `side-condition`
(wp_side exhausted), `state-spelling` (fed equation's state ≠ goal's
state name), `registry-gap` (construct known, hypothesis unsupplied).
Each is fail-closed: the engine stops with the tagged event; a
frontiered goal is a visible hole, never a silent skip or a sorry.

### 3.5 Replay contract

`replay(trace, statement)` re-runs the engine with search DISABLED,
feeding each recorded choice in order: it must either reach the same
QED (same statement, kernel-checked afresh — the proof term is
REBUILT, not deserialized) or stop at a typed frontier naming the
divergence (emission gap ⇒ fix the producer). Replay never invents
an equation, never falls back to search. This is the arc-11
`app_walk` record→replay + fingerprint-mismatch genre (its E10 lane
is the in-house precedent) restated against the donor's contract;
the chase-era emitter itself stays frozen and purge-bound — S1
implements fresh.

### 3.6 How the S1 rule registry emits it

Each registered construct law carries its trace-atom schema (law
name + hypothesis slots + joint pattern); the registry's application
wrapper emits the per-step and per-law events around the ordinary
`iapply`; `wp_side` emits disposition events. Emission is
OPTION-GATED, off by default in committed proofs (an instrument, not
a proof dependency — traces never enter any cone by construction,
since the proof term is the same with emission on or off).

## 4. Validation (verbatim, at `ec049e05c`)

```
info: RelSem/Audit.lean:184:0: RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
info: RelSem/Audit.lean:555:0: RelSem statement gate: 25 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
Build completed successfully (386 jobs).
Total: 7 passed, 0 failed
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
```

Sweep re-baselined 4050 → 4108 (arc-17 S0: DeriveState + WpGround
join the closure + 3 `_def` lemmas; provenance comment at the pin).
Statement gate untouched at 25 (no statement changes; `drDone_thr`
vocabulary rows unchanged — same constant names). No budget bumps,
no new axioms, no sorries; freeze gate green throughout (no chase
surface touched). Derived tally (labeled): +58 sweep declarations =
the two modules' meta code + parser/elab machinery + 3 emitted
lemmas.

## 5. Walls, parks, what S1 needs

- NO new walls hit; nothing parked this slice. The S3
  compute-forward park stands (its BEFORE configuration re-confirmed
  at ~151 s/kill), now with the measured refinement of §1.3: the
  cliff's dominant cost is the self-computing attempt on the LOOP
  atom, not the stage-level projection bridge.
- WHAT S1 GETS FROM S0: (1) the emitter as the fixture-independent
  way to name state ladders and mint step equations — S1's
  construct-law derivations should mint intermediate states through
  it rather than hand-writing `def`s, and its `expecting` mode is the
  mechanical replacement for k9_update-class hand lemmas; (2)
  `wp_ground` as the side-condition engine its laws' kernel-computable
  hypotheses discharge through (`wp_side` is already rewired); (3)
  the frontier-tag carrier for its engine's fail-closed
  classification; (4) the trace format spec (§3) its registry must
  emit against — the atom schemas belong IN the registry entries from
  day one; (5) the elab-collision notes in §1 (optional-group
  binding, addDecl ordering, parser aliases) — paid once here.
- Registered smallness caveat [AGENT]: the emitter's step form
  handles DETERMINISTIC active steps only (the `NDactive` frontier is
  tagged, deliberate); ND nodes stay law territory (`KStep.seq_nd`
  granularity limits, S3 §2.3) — S1 should not widen the emitter, it
  should register laws.
