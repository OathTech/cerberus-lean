# Arc 17 S2 — the memory-round evaluator, the env algebra, T4 (record)

Worker record, 2026-08-25. Charter:
`2026-08-24_arc17-automation-framework-charter.md`, slice S2 (expanded
by the S1 handoff, S1 record §8). Branch `automation-framework` (off
`e4e59ff72`, the S1 record commit); this slice's commits: `7a3babe54`
(the capped KILL banner, micro-item), `41d0c7429` (the round
evaluator + the completed t6 probe), `c7aa3bec2` (the ordered-map env
algebra), `c7afa99f1` (the guarded T4 statement + the seq_rmw law +
the T4 park), plus this record. Lineages (charter/brief-named):
HeapLang-ProofMode symbolic stepping (the evaluator), canonical
finite-map reasoning via Std.TreeMap's lemma suite (the env algebra).
[AGENT] decisions marked; every number is from this session's
EXIT-CHECKED runs (the S1 §4.4 lesson applied throughout — including
one live catch: the D14 grep-ban tripping on this session's own log
files inside the scanned tree, fixed by relocating the logs, gates
re-run green).

## 1. Deliverable 1 — THE LAW-DRIVEN ROUND EVALUATOR
   (`RelSem/RoundEval.lean`, 952 lines; the S1-registered input #1)

`derive_rounds id (bs…) using td tid from σ0 [upto N]`: the round
loop. Per round: classify by cheap whnf of the S1 `stepAt` discovery
composite; mint the successor + its step equation through the
REGISTERED LAWS —

- memory rounds (create/store/load/kill) through
  `advance_action_request` ∘ `perform_*` ∘ `mem_*_block`, the law
  chain elaborated against the round equation with the successor a
  metavariable, so the successor is ASSEMBLED from the laws'
  computed-RHS shapes (writeBytesTo-form memory) — never whnf'd;
- tau/runstate rounds through `advance_tau_misc` /
  `advance_runstate_eval` / `advance_runstate_tau_misc`;
- at the terminal: the whole dnms chain, the scheduler offer
  (`Laws.ndct_offer1`), the named final state, and the one-iteration
  driver equation (`Laws.driver2_done`) — all emitted by the same
  command.

Fail-closed: tagged frontiers (the S0 `frontierTag`) on unregistered
step/request classes, non-ground positions (the env-algebra/apartness
boundary), non-state-preserving request draws; `hasSorry` checks on
every elaborated proof (a postponed side-condition tactic failing
inside `elabTermEnsuringType` yields sorryAx SILENTLY — measured this
slice, now build-fatal in the emitter); kernel recompute-and-check at
every addDecl (the S0 donor contract).

### 1.1 The four accretion channels (each measured, each killed)

The wall was never one thing. Four successive spelling architectures
each reproduced the SAME per-round cost doubling until the actual
channel was found:

| # | channel | measurement | fix |
|---|---------|-------------|-----|
| 1 | raw-whnf successors inline the whole state history | S1's original wall: 64 G cgroup kill on the first store round | law-chain elaboration; successors from law RHS shapes |
| 2 | free unification assigns UNREDUCED whnf leftovers to law args (giant alloc-base cascades, lazy byte lists) | elaborator type-mismatch walls; `alignDown` left as an add/div tree | ground literals pre-evaluated (`groundNorm` fixpoint normalizer — plain `Meta.reduce`'s single top-down pass misses literal folding) and supplied EXPLICITLY |
| 3 | the `assoc_adjust` thread-table spine chains through every predecessor | +1 embedded thread record per round; 26 ms → 2.2 s by round 11, heartbeat wall at 12 — through ALL of: law-shaped successors, payload normalization, flat records | THE ANCHOR DISCIPLINE: the loop tracks the driver-state components as exprs and every minted body is a flat 11-field record over base names + literals (the fixtures' `mkDr` idiom, mechanized); fail-closed check that no minted body references its predecessor constant |
| 4 | one shared per-command heartbeat budget for N rounds | round 18 crossing 200k cumulative heartbeats at flat ~80 ms/round | `withCurrHeartbeats` per round mint — budget SCOPING at the default value, not a raise (the loop is sugar for one command per round; a single round exceeding the default still fails loudly) |

Two further measured walls inside the side-condition layer: (a) the
elaborator's lazy defeq wedges on compound div/mul literal arithmetic
(`alignDown`) — and so does plain kernel rfl (~65 s then deep
recursion); the working discharge is the arc-9 fixture recipe made
mechanical — rewrite the (match-forced, cheap) `lastAddress`
projection to its literal, then kernel `decide` on the CLOSED
arithmetic; (b) LCNF compilation of successor defs hit its own
heartbeat budget — round successors are proof-layer names, so the
emitter uses plain `addDecl` (no codegen).

### 1.2 THE T6 PROBE: COMPLETED — the S1 acceptance verdict flips to
    PASSED

`RelSem/T6Probe.lean` (309 lines) un-parked and landed:

- ONE `derive_rounds` command mints the ENTIRE run: **51 advancing
  dnms rounds + terminal** (classes: 1 create, 1 store, 4 loads,
  1 kill, 44 tau/runstate) and emits `r_chain`, `r_ndct`, `r_fin`,
  `r_driver`. (The S1 record's "44 advancing driver rounds" was the
  compiled runner's census; the dnms-level count is 51 — derived
  labels differ, the kernel-checked chain is the arbiter.)
- The memory-state ladder respelled in the Kit laws' computed-RHS
  `writeBytesTo` form — the S1-recorded `hout` heartbeat crossers
  (S1 §4.2 / input 5) dissolve, as predicted.
- Caller-protocol stages: one-line instantiations of the S1 construct
  laws (`inject_ptr_arg1`, `callND_errno`, `driver_update_ts`) with
  rfl/decide side conditions.
- The WP walk `t6_wpK_thr`: **15 tactic lines** (iintro + 11
  `wp_step`s + wp_done + ipureintro + exact).
- Statements: `T6Threaded` (∀-seed `CallHarnessAdequateThr` face) +
  `T6Threaded_ubFree`. Statement gate 25 → 27.
- ACCOUNTING at the charter bar: **zero fixture-specific
  derived-equation lemmas** — the per-fixture text is DATA plus law
  instantiations; every driver round is an evaluator mint.
  [AGENT] The outcome-set companion (`T6ThreadedOutcomes`) is
  deliberately absent — priced (one app-eq stage composition), noted
  in the Audit slate-list comment.

Probe numbers (session, exit-checked):

```
derive_rounds RelSem.T6.r: 51 advancing rounds minted
derive_rounds RelSem.T6.r: terminal reached after 51 rounds; emitted
  RelSem.T6.r_chain, RelSem.T6.r_ndct, RelSem.T6.r_fin, RelSem.T6.r_driver
per-round mint wall (flat; NO growth): tau/runstate 35–190 ms,
  create 42–69 ms, store 55–655 ms, kill 131 ms, loads 6.9–7.1 s
  (readBytesFrom/reconstructValue ground evaluation — the next
  optimization target, registered)
module build (full file incl. drive + walk + statements): 33 s
```

Cones (VERBATIM, session probe; Audit-pinned build-fatally):

```
'RelSem.T6.T6Threaded' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T6.T6Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T6.t6_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T6.r_chain' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T6.r_driver' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Comparative headline: the store round that killed a 64 G cgroup under
raw whnf (S1 §4.2) mints in **~55–655 ms** through the law chain.

## 2. Deliverable 2 — THE ORDERED-MAP ENV ALGEBRA
   (`RelSem/Kit/Env.lean`, 292 lines; fixture-free, Kit-scanned)

- LAWFULNESS, hypothesis-free: `lemCmpToOrd_symEnvCmp_eq_model` —
  the generated env comparator closure equals a lexicographic model
  (`compareLex`/`compareOn` over String × Nat), giving a real
  `Std.TransCmp` instance. Two load-bearing discoveries, recorded
  in-file: (a) `digest_compare` is an HONEST String comparison (a
  real definition, not the opaque extern the stuck-form discipline
  guards — that guard is about `digest ()`, the ambient READ); (b)
  `ordCompare`'s equality resolves through the Eq0→BEq bridge to
  `symbolEquality` — description-INSENSITIVE, the very mechanism of
  the S4 collision falsifier, and exactly what makes the comparator
  a total preorder (with the derived structural `BEq sym` it would
  NOT be).
- THE FMAP LAYER: rfl-grade unfolds + the payoff lemmas
  `fmapLookupBy_addBy_mk` / `_addBy_empty` / `_addBy_apart` /
  `_addBy_self` (via `Std.TreeMap.getElem?_insert`): a lookup walks
  PAST a symbolic-key insert by the comparator verdict — the
  S4-diagnosed kernel-stuck comparison dissolves into a discharged
  side condition.
- APARTNESS DISCHARGERS: `lemCmpToOrd_symEnvCmp_same_digest` (same
  digest ⇒ compare by number), `symEnvCmp_LT_of_num_lt` /
  `_GT_of_num_gt` / `_ne_eq_of_num_ne` — the exact facts the
  `T4SeedApart` guard feeds.
- HONESTY NOTE (in-file): rep-level insert commutation is FALSE at
  this implementation (insertion sequence counters); the charter's
  "ordered-insert normal form" is delivered at the LOOKUP level,
  where it is the complete story.

wp_ground memo stats on the apartness population (VERBATIM; 16
distinct props — comparator verdicts at ambient-seed-class literals
vs static hashes + a number-gap fact):

```
bench mode=core props=16 reps=1 calls=16 elapsed=6ms
bench mode=core props=16 reps=150 calls=2400 elapsed=14ms
bench mode=memo props=16 reps=150 calls=2400 elapsed=7ms
bench mode=memo props=16 reps=150 calls=2400 elapsed=6ms
wp_ground stats: calls=4800 hits=4784 failures=0 cached=16
```

Reading (same honesty as S0 §2.1): the apartness side conditions ARE
kernel-computable through the decide engine — zero failures, its
design target holds on this population; the memo's effect is real but
marginal at these sizes.

Cones (VERBATIM, pinned): `lemCmpToOrd_symEnvCmp_eq_model`,
`fmapLookupBy_addBy_mk`, `fmapLookupBy_addBy_apart`,
`symEnvCmp_LT_of_num_lt` — each
`[propext, Classical.choice, Quot.sound]`.

## 3. Deliverable 3 — T4: statement LANDED, seq_rmw law LANDED, the
   bulk PARKED at a NEW measured frontier

### 3.1 Landed (`RelSem/T4Threaded.lean`, in build, green; +
    `Kit/Round.lean`)

- **The seq_rmw construct law** (`perform_seqrmw` +
  `ars_seqrmw_unfold`, Kit/Round): the S1-registered census gap (122
  occurrences / 34 files). Load, the runstate RMW compute — the
  supply-reading stage whose output hypotheses are what Kit/Env
  discharges at open seed — store, trace/thread update; S1
  output-recast discipline. Cone pinned trio-exact (Kit/Audit).
- **The apartness hypothesis, statement-visible**:

  ```lean
  def t4MinStaticSym : Nat := 229457971439601039
  def T4SeedApart (seed : Nat) : Prop := seed + 1 < t4MinStaticSym
  def T4EnvHypThr : Prop :=
    CerbTags.tagDefs () = t4File.tagDefs ∧
    CerberusFresh.digest () = ""
  def T4ThreadedStatement : Prop :=
    T4EnvHypThr →
    ∀ (seed : Nat), T4SeedApart seed →
    ∀ x : Int, intRange x →
      CallHarnessAdequateThr seed t4File.tagDefs t4File "memb"
        [intValue x] t4Fs (t4Spec x)
  ```

  Kernel-computable; the ambient draw 1048577 satisfies it; the
  docstring cites the arc-16 S4 P3 collision falsifier (seed
  1680278659536745755 = `a_529`'s hash, which VIOLATES the guard) as
  the kernel-witnessed necessity.
- The threaded ladder (writeBytesTo memories, minted stages) + the
  evaluator drive to its frontier.

### 3.2 The NEW measured frontier (the honest park)

The evaluator drive from `dRdyT` mints round 1 and STOPS at round 2 —
**the struct create**: `sizeofCtype/alignofCtype structSCty` consult
the tag-table extern, so the round's ground arithmetic is not
kernel-computable without `htags`, and the evaluator is
hypothesis-free BY DESIGN (its mints are unconditional equations).
This is DISTINCT from the S4 collision diagnosis: T4's memory rounds
are HYPOTHESIS-CARRYING (struct layout) on top of the
apartness-carrying env rounds. `T4Threaded` (the theorem) is
therefore NOT landed this slice; the ambient T4 stands untouched.

THE ENUMERATED REMAINING WORK (registered, priced):

1. Evaluator hypothesis-threading mode — a binder-context the law
   mints may consume (htags/hdig/apartness), turning conditional
   rounds into conditional equations; M. (Forward-design note: the
   effect-axiom TEMPORAL plan — tagDefs modeled in machine state —
   would DISSOLVE the htags conjunct entirely; the evaluator
   extension must not make that threading harder.)
2. The ~35 anon-round twins through Kit/Env (the arc-16 S4 §2 price,
   unchanged — but its prerequisite machinery now EXISTS: the
   apartness dischargers + lookup lemmas are exactly the per-round
   feeds).

## 4. Micro-item — the capped KILL banner (commit `7a3babe54`)

`scripts/capped`: on child exit 137/143, an unmissable
`capped: KILLED (exit N — cgroup/OOM or signal; NOT a pass)` block on
stderr, all three run paths, exit code propagated unchanged.
Plant-tested this session (5 plants, transient commands): SIGKILL →
banner + 137; SIGTERM → banner + 143; cgroup 100M OOM → banner + 137;
clean pass and exit-7 failure → no banner, codes preserved.

## 5. Validation (verbatim, at `c7afa99f1`; every run exit-checked)

```
Build completed successfully (391 jobs).
info: RelSem/Audit.lean:...: RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
info: RelSem/Audit.lean:...: RelSem statement gate: 27 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
Total: 7 passed, 0 failed
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
check_proof_size: Kit + ConstructLaws files fixture-free OK (9 files)
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
```

Sweep re-baselines (provenance comments at each pin): 4128 → 4361
(RoundEval + completed t6) → 4410 (Kit/Env) → 4438 (T4Threaded +
seq_rmw). Statement gate 25 → 27 (T6 family; `t6File`/`t6Fs`
allowlisted, same class as the t1–t4 rows). Axiom censuses untouched
(2 declared-boundary hand-written axioms); no new sorries; freeze
gate 8/8 throughout. NO budget bumps anywhere (the per-round
`withCurrHeartbeats` is budget scoping at the default value,
documented in RoundEval with its rationale; heartbeat pressures were
answered with design changes — the anchor discipline — never
raises).

## 6. Down-pressure register rows

| item | value |
|---|---|
| t6 WP proof body | 15 tactic lines |
| t6 fixture equation LEMMAS | 0 (charter bar met) |
| t6 fixture DATA | statement + syms + addresses + writeBytesTo ladder + 2 stage-law instantiations (~140 lines) |
| t6 rounds minted mechanically | 51/51 + terminal artifacts (chain/ndct/fin/driver all emitted) |
| t6 module elaboration | 33 s (loads dominate: 4 × ~7 s) |
| env-algebra library | 292 lines, reusable, fixture-free |
| T4 threaded | statement + guard landed; theorem parked (frontier §3.2) |

## 7. Registered items (consolidated; S2b/S3 handoff)

1. T4 completion = evaluator hypothesis-threading mode (M) + the ~35
   anon-round twins via Kit/Env (§3.2) — the S4 price with its tools
   now landed.
2. Load-round mint cost (~7 s each: `readBytesFrom` /
   `reconstructValue` ground evaluation over writeBytesTo layers) —
   S-priced normalization target inside `groundNorm`.
3. `T6ThreadedOutcomes` (outcome-set companion) — one app-eq stage
   composition; S.
4. The S1-registered memop round laws (unchanged; libxml2 road).
5. T5/S3 note: the evaluator's chain emission is round-walk-shaped by
   design (bounded runs); T5-by-invariant (charter S3) remains the
   loop story — the evaluator contributes the BODY-step equations its
   invariant proof consumes.
6. Session-hygiene lesson (logged): scratch logs must live OUTSIDE
   the scanned trees — the D14 grep-ban caught this session's own
   logs (fail-closed working as designed; relocated, gates re-run).
