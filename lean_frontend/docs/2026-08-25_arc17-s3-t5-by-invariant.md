# Arc 17 S3 — THE ARITH MINTER, the T4 close-out, T5 BY INVARIANT (record)

Worker record, 2026-08-25. Charter:
`2026-08-24_arc17-automation-framework-charter.md` slice S3, expanded
by the S2b handoff (S2b record §5's enumerated T4 remainder + §9's
S3 notes). Branch `automation-framework`; slice commits: `7af6ad483`
(the arith minter + T4 frontier 17 → 22), `7155a57be` (the
builder-walk engine + dual-mode substitution safety), plus the docs
commit carrying this record. [AGENT] decisions marked; every quoted
output is verbatim from EXIT-CHECKED runs of this session.

HEADLINE VERDICTS (honest): the ARITH MINTER is BUILT and delivers
(deliverable 1 ✓); T4-threaded's frontier moved 17 → 22 and the
anon-env region is PARKED as a measured NEW WALL CLASS per the
standing stop clause (deliverable 2: partial, diagnosis complete);
T5-BY-INVARIANT is NOT LANDED — the invariant-route INFRASTRUCTURE
is built end-to-end (relative chains, the builder pattern, the
verdict-closure lanes) and the body walk reached 43 of ~72 rounds at
FULLY SYMBOLIC components before parking at a measured
representation-level wall (the constraint-set dedup), with the
correctly-shaped next mechanism identified and priced (deliverable
3: infrastructure + measured frontier, proof unlanded; the
proof-size gate's T5 row REMAINS PENDING).

## 1. Deliverable 1 — THE ARITH MINTER (built; the S2b-identified
   recipe, plus what the recipe turned out to need)

Commit `7af6ad483`. The S2b frontier diagnosis named the recipe —
"mint `⟨stuck decidable/Bool spelling⟩ = ⟨verdict⟩` facts from the
pack's range hypotheses (`Subsingleton (Decidable p)` + congrArg +
omega)" — and the recipe held, with the load-bearing engineering
turning out to live in the SUBSTITUTION SAFETY, not the verdicts:

| mechanism | what it answers (measured this slice) |
|---|---|
| verdict bridges `dec_eq_isTrue/isFalse` (proof irrelevance: every `Decidable p` inhabitant equals the dictated one) | the tower-to-verdict equation, kernel-cheap; `Subsingleton` not even needed |
| side facts as NAMED theorems (`_hfs<i>`), minimal telescopes | an omega certificate can contain the very tower it decides — inlining it made every substitution re-insert its own pattern (+6 objs/pass, unbounded — measured); ground facts referenced with the full telescope dragged Prop binders into successor defs (kernel fvar rejection — measured) |
| omega for open side facts, kernel decide for ground (the S0 donor contract) | the two verdict sources; both kernel-recomputed at addDecl |
| THE ARITH REFOLD (`foldArith`): op-constant folds (`Int.add a b` → `a + b`, `Int.ofNat` raw-literals → `OfNat`/`Nat.cast` notation, `Nat.le/lt` → classes) + MATCHER refold (Int-typed matcher apps `isDefEq`-probed against the op table at their own scrutinees) | omega ATOMIZES every raw spelling (measured: `Int.add x c > 0` fails where `x + c > 0` succeeds; raw `Int.ofNat` fails at literal AND cast positions); whnf smears stuck operands into constructor matches omega cannot read |
| `Int.NonNeg` bridges | omega treats `NonNeg` as an opaque atom (measured); `0 ≤ a` is `NonNeg (a - 0)` only definitionally |
| Bool lanes: `Nat.ble/blt/beq` + the Lem comparator family `natLtb/natLteb/natGteb/intLtb/intLteb/intGtb/intGteb` (decide-coercions; bridges are `decide_eq_true/false` at the folded spelling) | the spellings symbol-comparator chains and conv guards bottom out in |
| the decide-shape lane (`decide q = lit` towers, identity-matcher debris unwrapping, registry-headed scrutinees) | the OUTER tower over a decide must be minted atomically — see the guard row |
| SYNTACTIC substitution (`Core.transform` + `Expr.abstract`) for minted patterns | kabstract's defeq walks on tower-sized patterns blew the heartbeat budget (measured: 20 s+); minted patterns are harvested from the very term being rewritten |
| THE TYPE-CHECK GUARD on minted substitution | the same logical tower occurs in defeq-VARIANT spellings inside dependent motive/branch-type positions; a partial structural replacement builds an ill-typed term the KERNEL rejects (measured: the round-18 `Bool.decEq` cluster). The guard refuses; the decide-shape/tower lanes then mint the ENCLOSING cluster, which substitutes atomically |
| the `.all` DIG (smart-unfolding-OFF whnf, memoized, fence-guarded) | smart unfolding hides comparison towers INSIDE folded definitions at every transparency (measured: `DTreeMap` internals, `Lem_List.elem` chains) |
| CHAIN EXACTNESS in the proof engine (`proveHypEq`): every normalization hop carried by its own kernel-deferred `Eq.refl` bridge; full subst/normalize alternation | mkEqTrans's implicit midpoint gluing was kernel-rejected at builder states; the S2b-era early break left later stuck sites unnormalized (both measured) |
| PHASE-LEVEL BUDGET SCOPING (every meta-operation its own default-value scope) | the mint-pass count scales with a round's tower population; the round-level scope of S2 died at ~3 passes regardless of content. Budget SCOPING at the default value — no maxHeartbeats change anywhere |
| THE ENV-LOOKUP LANE (Kit/Map's captured-comparator laws `fmapLookupBy_addBy_eq/ne` + `FmapBuilt` chains, instances taken from the TERM's spelling) | lookups over `fmapAddBy` chains at seed-symbolic keys; the R-S2-1 instance-implicit-divergence lesson re-measured (synthesis picks a different `BEq` than the generated call site captured) |
| ITERATIVE BOOL-TOWER CLOSURE (`closeBoolTower`: whnf hops ⊕ inner-verdict substitutions ⊕ registry-direct bridges ⊕ dig hops, all exactness-bridged) | the dynamic-annotation race checks — `cond`/`Bool.and` towers over exclusion-id comparisons mixing many stuck decidables; single-substitution fallbacks cannot close them |

Verdict-side lineages (canon-first): omega (Presburger; the
canonical engine), kernel decide (the S0 ACL2Lean donor contract),
proof irrelevance (the verdict bridges), conditional rewriting (the
hypothesis-mode framing). The substitution-safety mechanisms are
engineering under the proof-scaling philosophy: kernel-checked
steps, aggressive meta-machinery, statements untouched.

## 2. Deliverable 2 — T4-threaded: frontier 17 → 22; the anon-env
   region PARKED as a NEW WALL CLASS (the stop clause exercised)

Commit `7af6ad483`. Under the S2b pack + `hrng1/hrng2` (the intRange
conjuncts) + `hi2b` (the int-store byte image):

- Rounds 18/19 — the conv RANGE CHECKS on open x — mint through
  exactly the S2b-identified recipe (towers → registered verdicts,
  omega-backed by the range hypotheses).
- Round 20 — the x-symbolic struct-member STORE — mints through
  `hi2b` (758 ms). Rounds 21–22 tau.
- Committed drive: `derive_rounds rT … upto 22` GREEN in
  `RelSem/T4Threaded.lean` (33 s module build);
  `derive_rounds RelSem.T4.rT: 22 advancing rounds minted` verbatim.

THE ROUND-23 WALL (measured, three architectures): resolving
`PEsym anon1` at ∀-seed walks env maps the earlier rounds
MATERIALIZED into raw `Std.DTreeMap.Internal` trees.
(a) Verdict-minting into the trees: the comparison towers hide
inside folded tree operations (smart unfolding refuses stuck-match
unfolds at every transparency); the `.all` dig exposed them but the
chase went through `._f` WF-auxiliary spellings and
projection-headed partial applications — representation-level
combat, the trick-filter prong-2 tell.
(b) An `fmapAddBy`/`fmapLookupBy` attribute fence (keeping the
spellings law-shaped for the Kit/Env–Kit/Map lookup laws): breaks
the evaluator's ground-defeq spine — classification, law
unification, and chain `rfl` side conditions all measured failing.
(c) Curated pack facts at the materialized spellings: the spellings
quote round-minted constants, so the facts cannot be stated in the
pack's (pre-drive) binder scope.
This is a NEW wall class beyond the S2b enumeration ("seed-vs-static
verdicts feeding the Kit/Env lookup lemmas" — the verdicts mint
fine; the CONSUMING spellings are not law-shaped and cannot be made
law-shaped without a representation-level env model). [AGENT] parked
per the standing stop clause. DESIGN MOVERS (registered): an
abstract env layer above the tree representation (the typed-view
direction of the parity ledger), or the effect-state threading that
keeps anon draws out of comparator maps entirely (the [USER]
machine-state end state — this wall is fresh evidence for "kill
this sooner rather than later"). `T4ThreadedStatement` stands
landed; the ambient T4 stands untouched.

## 3. Deliverable 3 — T5 BY INVARIANT (in progress)

### 3.1 The relative-chain evaluator mode (the iter_compose feed)

`derive_rounds … chain` emits `<id>_chainrel`:
`∀ fuel, app (dnms (fuel + N) …) σ0 = app (dnms fuel …) σN` (partial
mode) or `… = (NDactive offer, σN)` (terminal mode) — the dnms laws
were already fuel-relative, so the chain is `dnms_round`/
`dnms_terminal` compositions at symbolic fuel offsets. Smoke: T6's
51-round terminal chain + a 5-round partial chain, cones trio,
consumed at ∀-fuel in-place.

### 3.2 THE BUILDER PATTERN (the walk architecture that works)

The T5 body walk runs from `mkLH env mem tr aid exc symc ctr` — a
loop-head BUILDER whose varying components are FREE BINDERS — with
ALL component behavior supplied by the hypothesis pack (env lookups,
allocation records, dead-set membership, byte reads, roundtrips,
store images, arithmetic bounds, the loop guard `iv < n`). Nothing
is materialized (a free variable cannot be unfolded), the exit
bridge to the recursively-defined invariant family becomes
definitional in the data components, and the walk is
fixture-independent up to the pack. Supporting evaluator changes:
literal-field anchoring for record-constant σ0; layer-by-layer
writeBytesTo materialization; the discovery GLUE (laws elaborated
against the DISCOVERED step, glued to the `stepAt` face by a
kernel-deferred — or pack-proved — discovery equation, removing
stepAt from every elaborator unification); hyp-aware classification
(step_ctx READS layout_state — the S3-record open question,
answered by measurement: the dynamic-annotation race checks).

### 3.3 Walk progress (measured; probe scratch retired, content here)

- ENTRY: 21 rounds from `dRdy5 seed n` at symbolic n, GREEN, with
  the relative chain emitted
  (`derive_rounds RelSem.T5S3.e5: 21 advancing rounds minted` +
  `relative chain RelSem.T5S3.e5_chainrel emitted (21 rounds,
  terminal=false)`, verbatim). The loop-head state was dumped and
  characterized (annotated `whileBody` arena; fully-materialized
  ground entry env with static keys only; the 12-layer writeBytesTo
  memory; supplies `aid=4, exc=0, sym=seed`).
- BODY (from the builder `mkLH env mem tr aid exc symc ctr` with a
  23-hypothesis pack): 43 of ≈72 rounds minted at fully-symbolic
  components — the condition loads (n and i, via the pack's
  read/roundtrip facts), the conv guards on the loaded values
  (minter verdicts from the range hypotheses), the s-load, the
  `sv + iv` arithmetic, and the s-STORE (the store-byte image fact)
  — with env-lane hits/skips at the freshly-bound locals and the
  unitSym-class draws, and per-conv verdict mints. Per-round mint
  0.3–6.5 s.

### 3.4 THE ROUND-44 WALL (the walk campaign's measured stop)

The post-store DISCOVERY (`step_ctx` — which reads `layout_state`,
answering the S3-record's open question by measurement) runs the
dynamic-annotation RACE ANALYSIS: the store left `DA_neg exc [] (FP
W sAddr 4)`-annotations, and the next step's admissibility folds
`combine_dyn_annotations`/`.any` chains of footprint-overlap checks
guarded by EXCLUSION-ID membership (`Lem_List.elem exc [exc]`,
`id == exc`-comparisons at the free `exc`). The closure machinery
(§1's last row) drove most of it — the towers close through
registry bridges, refl fast paths, recursive scrutinee closure and
dig hops — but the analysis bottoms out in the ND CONSTRAINT-SET
plumbing: `pull_constrained` set operations DEDUPLICATE result
pexprs by VALUE comparison (`Lem_Basic_classes.setElemCompare iv 0`
— comparing the loaded loop counter against another result value),
which at symbolic values is GENUINELY UNDECIDED and sits on the
evaluation spine (the set's representation depends on it even
though the run's observable behavior does not). No verdict lane can
decide it and no rewrite can skip it. [AGENT] PARKED per
park-don't-improvise. THE CORRECTLY-SHAPED FIX (registered, S1-class
construct-law work, priced S–M): a `pull_constrained`-IDENTITY law —
the concrete memory model never emits constraints, so
pull_constrained at constraint-free pexprs is the identity; proved
once, registered as an evaluator law, it removes the whole
constraint-set plumbing (and its value comparisons) from every walk.
This is a LAW, not a lane — exactly the boundary between the
minter's job (decidable side facts) and the equation supply's (the
charter's S1 frontier).

### 3.5 The dual-mode resolution (a measured both-ways regression)

Wiring the builder mechanisms into the shared evaluator initially
REGRESSED the committed T4 drive (round-5 offsetsof cluster: the
fenced-head ground escape computed `hunspec`'s own lhs into
offsetsof towers; the position-safe substitution changed round-18's
verdict placement; the exactness-bridged chains altered round-5's
side-condition proofs — kernel rejections, each isolated by
bisection). Resolution: `derive_rounds … builder` — builder walks
get the new mechanisms; materialized-state drives keep the
committed S2b/minter semantics EXACTLY. T4's 22-round drive
re-verified green in SYNC mode (no deferred kernel checks) after
the split.

### 3.6 T5 verdict, the measurement, and what remains

- T5 IS NOT LANDED. The proof-size gate's T5 row remains PENDING
  (`check_proof_size: T5.lean — not present yet (registered,
  pending)` — verbatim, unchanged).
- The chase-era comparison the brief asks for, stated honestly: the
  walk route attempted T5 three times and never landed it, with the
  final attempt reaching 13/79 body rounds at the R13
  kernel-unfold-order wall (arc-15 record) — an unbounded
  navigation-shape ladder. The invariant route's body walk reached
  43/≈72 rounds at FULLY SYMBOLIC components (seed, n, and the
  loop-carried values — strictly more general than the walk route's
  pinned-seed family), with every wall it met dissolved by a
  REUSABLE mechanism (a lane, a law shape, a safety discipline) up
  to the constraint-set dedup — which is itself a once-proved-law
  shape, not a per-fixture ladder. No T5-specific equation was
  hand-derived anywhere. The comparison of ROUTES stands even with
  the proof unlanded: the remaining work is enumerable (one
  construct law + ~29 body rounds expected mechanical + the exit
  walk + the family transcription + the iter_compose composition +
  the wpK walk), where the chase era's remainder was
  non-enumerable by its own post-mortem.
- REMAINING WORK to land T5 (registered, in dependency order):
  1. the `pull_constrained` identity law (S–M; unblocks round 44+);
  2. body walk completion + the i-store + the Erun jump (expected
     mechanical; the Erun classification needs the ground labeled
     lookup, present in the builder);
  3. the exit walk (condition-false at `iv = n`) with terminal
     relative chain;
  4. the family transcription (`StF` from the minted spellings; the
     exit bridge definitional by the builder design) + entry
     alignment (annotated-arena iteration 0);
  5. `iter_compose` composition + fuel algebra + `ndct_offer1`/
     `driver2_done` + the wpK walk + the ∀-seed statement (T4-style
     `T5SeedApart` guard + `hdig`; the T6 template);
  6. the gate-row flip.

## 4. Validation (verbatim, at `7155a57be`; every run exit-checked)

```
Build completed successfully (391 jobs).          [relsem]
info: RelSem/Audit.lean:217:0: RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
info: RelSem/Audit.lean:246:0: RelSem boundary-opaque gate: with_tagDefs/forceIO exist, are opaque (kernel-checked witnesses, not axioms), and are not allowlisted
info: RelSem/Audit.lean:632:0: RelSem statement gate: 27 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
info: RelSem/Audit.lean:1096:0: runEffectful no-cone gate: carrier set exact (114 registered ambient-family theorems; no acquisition, no stale entries)
info: RelSem/Audit.lean:1214:0: RelSem audit sweep: 4712 declarations (module-of-origin root RelSem, within RelSem.Audit's import closure — NOT the whole tree), all within the declared axiom boundary (0 recorded sorryAx exceptions)
Build completed successfully (143 jobs).          [speclab]
info: SpecLabAudit.lean:106:0: speclab statement-TCB gate: 46 statements clean; wrapper-hole negative test detecting
Total: 7 passed, 0 failed                          [test_unit]
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
```

Sweep re-baselines (provenance comments at the pin): 4552 → 4646
(the minter + T4 rounds 18–22) → 4712 (the builder-walk engine +
bridge lemmas + the re-minted T4 fact population). Statement gate
steady at 27; axiom censuses untouched (0 hand-written); no new
sorries; NO maxHeartbeats/maxRecDepth value changed anywhere (all
budget work is SCOPING at the default value, documented in-file with
the S2 rationale).

## 5. Registered items (S3 close; S4/S5 handoff)

1. T5 completion ladder — §3.6 (the pull_constrained law first).
2. T4 anon-env region — §2's design movers (the typed-view env
   layer, or the effect-state threading — fresh evidence for the
   [USER] "sooner rather than later" ruling).
3. The proof-size gate's T5 row — PENDING, unchanged.
4. Probe scratch (ProbeT5S3/ProbeT5Body/ProbeT4S3 + minor) deleted
   before commit; this record preserves the content (the S4-record
   pattern).
5. The `builder`/`chain`/`fencing` tokens are documented in
   RoundEval's header notes; T4/T6 drives are byte-compatible with
   the committed S2b semantics (verified by the dual-mode bisect).
