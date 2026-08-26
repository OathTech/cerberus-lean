# Arc-18 C3 — THE IDENTITY LAW + the round-44 wall's deletion (record)

Slice C3 of the coherence arc
(`docs/2026-08-25_arc18-coherence-charter.md`, blessed [USER
2026-08-25]). Worker: [AGENT], worktree `cerberus-lean-coherence`,
branch `coherence`, base `dcde495fc` (C2). Two commits, each fully
gated (relsem + speclab capped builds with all in-build gates,
`test_unit.sh` "Total: 7 passed, 0 failed", `test_verify.sh`
"35 passed, 0 failed", every pre-existing cone pin byte-stable;
driver paths untouched throughout, so the differential baselines are
unaffected by construction — test_verify's oracle differentials
re-ran green at every commit). A mid-slice session restart
(box-level, not for cause) was recovered per the resumption
discipline: every green state below was RE-VERIFIED fresh,
exit-checked, after the restart. Quoted outputs are verbatim.

HEADLINE VERDICTS (honest): **deliverable 1, THE PULL_CONSTRAINED
IDENTITY LAW, is LANDED** — proved once, registered, sub-trio cones
(§1). **The arc-17 S3 round-44 wall is EMPIRICALLY DELETED** — the
T5 body walk, which the S3 record parked at 43/≈72 rounds against
the constraint-set crossing, now mints 50+ rounds THROUGH the park
site and emits the ∀-fuel relative chain, all kernel-checked (§3).
**T5 the theorem is NOT LANDED** (the proof-size gate's T5 row
REMAINS PENDING): the walk's next frontier is measured and named
(§3.4) and the completion remainder is enumerated (§3.5).
**T4-threaded is NOT COMPLETED** (R5 remains OPEN): the anon-env
region's fence-over-materialized route was re-measured failing under
the C3 engine, and the viable route is adjudicated (§4).

## 1. THE PULL_CONSTRAINED IDENTITY LAW (deliverable 1 — landed)

Commit `293bc9d05`. The arc-17 S3 record §3.4's priced mechanism
("a LAW, not a lane"), landed in `relsem/RelSem/Kit/Eval.lean`:

* **`pullSpine`** — the structural mirror of generated
  Core_eval.lean's `pull_constrained_lemFuel` at CONSTRAINT-FREE
  pexprs: fuel-indexed, fail-closed `Option`; `some peP` iff the
  traversal completes within fuel and meets no `PEconstrained` node.
  Mirrors the generated rebuild discipline exactly (verified by the
  per-arm proofs): wrap nodes re-annotated `[]`; list children
  (wrap_list/pull_helper positions) kept VERBATIM — the generated
  `pull_helper`'s `Sum.inr` arm keeps the ORIGINAL `pe`, a
  non-obvious asymmetry the mirror-and-prove discipline caught.
* **The law** (both faces `@[step_law]`-registered, kind `evalPull`,
  variants `fuel`/`wrapper`, lineage sentences on both):

  ```
  pull_constrained_spine : ∀ fuel pe peP n,
      pullSpine fuel pe = some peP →
      pull_constrained_lemFuel fuel n pe = peP
  pull_constrained_id (n) : pullSpine lemDefaultFuel pe = some peP →
      pull_constrained n pe = peP
  ```

  Proof: fuel induction, 29-arm case analysis against the generated
  per-arm equations (`split`-based match reduction; `pull_helper_id`
  via the `foldl_inr_of_step` accumulator invariant). ~430 lines in
  Kit/Eval, kernel-checked, no tactic debt.
* **Cones, pinned VERBATIM in Kit/Audit.lean — SUB-trio**:
  `pull_constrained_spine`/`pull_constrained_id`/
  `pullSpine_notConstrained`: `[propext, Quot.sound]`;
  `pull_helper_id`: `[propext]`. No `Classical.choice` anywhere.
* **What it deletes, by construction**: the concrete memory model
  never emits `PEconstrained`, so every eval-crossing of
  `pull_constrained` in every walk is this identity — the
  constraint-set plumbing (and its symbolic value comparisons, the
  S3 record's `setElemCompare` diagnosis) is never entered. The
  engine consumes the law through the `mintPull` lane (registry
  query, kind `evalPull`; side condition = the `pullSpine`
  computation as a kernel-deferred refl — structural,
  symbolic-leaf-safe).
* Gate re-registrations in the landing commit: census 55 → 57;
  sweep 4914 → 5090 (provenance comments at the pins).

HONEST ATTRIBUTION NOTE: the empirical wall-fall (§3) needed the
identity law PLUS two further laws PLUS a substitution-safety
hardening series (§2) — the S3 diagnosis named the pull crossing as
the round-44 stop, and deleting it exposed the adjacent frontiers in
the same round's neighborhood, each of which fell to the same
law-shaped treatment.

## 2. The companion laws + the engine hardening (commit `70771b5d0`)

**LAWS** (census 57 → 60, provenance at the pin):

| law | kind/variant | content |
|---|---|---|
| `conv_int_signed_range` (Kit/Eval) | evalArith/conv | `mk_conv_int (Signed Int_) (IV pn v) = IV Prov_none v` at in-range `v` — the round-35 conv tower is the identity at in-range operands (lineage: conditional rewriting at the semantic boundary; proved by simp+omega against generated Core_eval) |
| `catch_add_signed_range` (Kit/Eval) | evalArith/catchAdd | `mk_call_catch_exceptional_condition (Signed Int_) IOpAdd (IV p1 a) (IV p2 b) = some (IV (combineProv p1 p2) (a+b))` at in-range `a+b` — the UB036 guard's in-range arm |
| `fmapLookupBy_empty` (Kit/Map) | envMap/empty | the empty-map lookup base case (the core_extern wrapper at freshly-drawn symbols under the env fence; definitional) |

Consumers: `mintConvArith` (range premises discharged by the verdict
engine/omega over the pack; a conv-through-operand congr composition
handles the Core `catch(conv a, conv b)` spelling) and the envMap
empty branch of the env lane — all REGISTRY-QUERY appliers (R4:
zero semantic knowledge in engine code).

**ENGINE HARDENING** (each row a named, measured defect; engine-size
baseline re-derived 4809 → 5207 with per-module provenance in
`scripts/engine_size_baseline.txt`):

| mechanism | the measured defect it removes |
|---|---|
| `substDecSafeCore` position discipline: proofs opaque; binder-TYPE/motive/instance slots frozen; data-typed patterns replaceable at value positions | verdict/data substitutions into dependent type slots built elaborator-accepted, KERNEL-REJECTED mixtures (measured: the T5 round-14 guard — a minor premise annotated at a verdict-substituted `decide` instance while the enclosing rec's Prop kept the original spelling); data rewrites (conv/catch results) previously never fired at general positions |
| ORIGINAL-SPELLING verdicts (`mintDecidable`/`closeBoolTower`/`propVerdict`): `isTrue p0 (cast pf)` at the term's quoted Prop `p0`, side fact stated at the normalized `p` omega consumed, kernel-deferred cast between | verdicts typed at normalized spellings substituted into positions quoting the original — defeq-variant mixing, kernel reject |
| checked abstraction at the three `closeBoolTower`/`propVerdict` sites | raw `abstractExact` abstracted occurrences inside dependent motives |
| `ofNatify` at the env-apartness discharge ONLY (the C1-registered seed, applied at exactly its predicted frontier) | quoted-AST symbol digests reach apartness goals as raw `Expr.lit` numerals — omega ATOMS (`symc ≠ 16900879642891266615` unprovable); global application measurably perturbed the verdict population, hence the scoping |
| glue-round `_hfind` theorems (`MintedRound.hfindName`) + the `option_eq_some_getD` payload-blind bridge | chain pieces for discovery-glue rounds carried kernel-deferred refls that would re-run a PACK-DEPENDENT discovery in the kernel (impossible); the `isSome` route's endpoint discards the verdict-substituted payload |
| chain PREFIX CHECKPOINTS (every 12 pieces, named kernel-checked prefix lemmas, accumulator restarts from the lemma application) | a 50-round single-declaration chain exceeded one kernel work unit (30 fit) — windowed kernel work, no budget touched |
| phase-scoping (thNorm/glue/hstep/chain-accumulation) | unscoped whnf/inferType units at round-44-class state sizes; all scoping at the DEFAULT budget value — no maxHeartbeats/maxRecDepth value changed anywhere |

Fence vocabulary for the T5 walk (probe-side `fencing` token, no
engine default changed): `fmapAddBy CerbMem.writeBytesTo mkByte
mk_conv_int mk_call_catch_exceptional_condition mk_wrapI` — the
pack's tidy spellings and the law-shaped conv/catch heads stay
folded; the fenced-ground escape still computes closed instances.

**REGRESSION ATTESTATION**: the committed T4Threaded (22-round) and
T6Probe (51-round + terminal) drives re-elaborate UNCHANGED through
the hardened engine (the full relsem build is the instrument);
census 60 and sweep 5265 are the only pin movements, both
provenance-commented; every cone pin byte-stable.

## 3. THE ROUND-44 WALL: DELETED (T5's substrate — the walk verdict)

### 3.1 The instrument

The preserved S3 probe (`.arc17-probe-scratch/ProbeT5Body.lean` →
this slice's working copy, preserved at
`.arc18-c3-probe-scratch/ProbeT5C3.lean`): the T5 BODY WALK from the
loop-head BUILDER `mkLH env mem tr aid exc symc ctr` — every varying
component a FREE BINDER, all behavior from the 28-hypothesis pack
(env lookups, allocation records, byte reads, roundtrips, store
images, arithmetic bounds, the loop guard `iv < n`) — at fully
symbolic seed/n/sv/iv, in builder+chain mode.

### 3.2 The session's frontier ladder (each wall named, fixed, and
    permanently cleared — measured)

| frontier | round | fix |
|---|---|---|
| pack byte-spelling explosion (mkByte unfolded into Fin-proof debris; Prop fvars leaked into successor defs) | 5 | `fencing mkByte` (spelling preservation — the fence's designed use) |
| guard-verdict dependent-position mixture (kernel reject at b14_app) | 14 | the position discipline + binder-type freeze + original-spelling verdicts |
| conv/catch arithmetic tower cascade (301+ diverging substitution passes) | 35 | the evalArith LAWS + `mintConvArith` (the tower's semantic content as once-proved laws) |
| the s-STORE at symbolic sv+iv | 43 | fell mechanically once 35 fell ("store (930 ms)") |
| **THE S3 PARK SITE: post-store discovery — race analysis + the pull_constrained crossing** | **44** | the identity law + `mintPull` + the closure machinery (classification 34 s, minted; glue `_hfind`) |
| fresh-symbol env lookups (`Symbol "" symc SD_None` through the core_extern wrapper) | 46 | `fmapLookupBy_empty` (envMap/empty) |
| static-key apartness at raw-literal digests | 50 | `ofNatify` at the apartness discharge (the C1 seed's predicted frontier) |

### 3.3 The verdict, verbatim (re-verified fresh post-restart,
    exit 0)

```
derive_rounds RelSem.T5S3.b: 50 advancing rounds minted; classes: [runstate, …]
derive_rounds RelSem.T5S3.b: relative chain RelSem.T5S3.b_chainrel emitted (50 rounds, terminal=false)
```

`b_chainrel : ∀ fuel, app (dnms (fuel + 50) …) (mkLH …) = app (dnms
fuel …) (b50 …)` — the iter_compose feed shape, kernel-checked with
windowed prefix lemmas. The S3 comparison: S3 reached 43/≈72 with
round 44 GENUINELY UNDECIDED ("no verdict lane can decide it and no
rewrite can skip it"); the C3 walk passes 44 as an ordinary minted
round. The ENTRY walk also re-ran green on the C3 engine
(`ProbeT5Entry.lean`: "21 advancing rounds minted" + `e5_chainrel`
emitted at symbolic seed/n — the S3 e5 reconstruction, first run).

### 3.4 The NEXT frontier (measured; the walk's park point)

At `upto 80`, round 56 — the FIRST POST-STORE LOAD (the i-increment's
load of `i` across the round-43 write layer) — fails at addDecl: the
`mem_load_block` `hdead` side condition
(`(b55 …).layout_state.deadAllocations.contains 3 = false`) is
discharged by `hyp_norm_side` as a kernel-deferred refl that the
kernel cannot compute (the layout is the FENCED write ladder over the
free `mem`; the fact lives in the pack as `hdd3` plus the registered
projection laws, but the side-condition chain's pattern scan misses
the folded-successor spelling — kabstract's defeq walk is blocked by
the very fence that keeps the spelling law-shaped). This is an
ENUMERABLE side-condition-routing item (the projection-normalization
hop before pattern scan in `proveHypEqBld`), not a new wall class —
but it is engine-frontier work, and the slice's budget assessment
(§6) parks here rather than iterate further.

### 3.5 T5 completion remainder (enumerated, updated from S3 §3.6)

1. ~~the pull_constrained identity law~~ — DONE (this slice).
2. the round-56 side-condition routing item (§3.4, S) + body walk to
   the loop-closing Erun (~72; expected mechanical after 56).
3. the exit walk (condition-false at `iv = n`; the guard verdict
   flips polarity — the minter handles isFalse) + terminal chain.
4. the invariant family `StF` (recursive memory/trace families over
   the entry state; pack-fact derivations ∀ i via the memRW laws —
   the T1 `round3_o` pointwise-fact pattern) + entry alignment.
5. `iter_compose` composition + fuel algebra + the harness spine at
   symbolic n (T1Threaded's open-equation recipe verbatim) + a
   `wpk_seq_scratch2`-class walk rule (driver atom reading n's
   footprint with BOTH s and i scratch lifetimes inside — the T3
   scratch pattern doubled) + adequacy + the guarded ∀-seed
   statement.
6. the proof-size gate T5 row flip — **REMAINS PENDING** (honest:
   `check_proof_size: T5.lean — not present yet (registered,
   pending)`).

### 3.6 The open-memory-mode adjudication (the C2 handoff item)

ADJUDICATED AND DEMONSTRATED: the PACK-FED open-memory route — the
builder walk with memory as a free binder and reads as pack facts —
IS the open-memory equation supply, now proven at 50-round scale
(strictly more general than ∀ bm am: the whole MemState is free).
The T6 DIVIDEND: T6's migration off the OwnP exemption can ride this
route today (write T6's pack — 14-ish facts — and re-drive in
builder mode; the C2 record's "T1 pattern verbatim" recipe then
applies). The fully-automatic law-resolved minting mode (no pack; map
reads through registered read-over-write laws alone) remains arc-19
territory as the C2 record priced it.

## 4. T4-threaded (deliverable 3 — NOT completed; the route
    adjudicated)

The committed 22-round drive re-verifies green under the C3 engine
(regression attestation, §2). The round-23 anon-env wall: the
S3-measured route (b) — `fencing fmapAddBy` over the MATERIALIZED
`dRdyT` state — was re-tested on the C3 engine
(`.arc18-c3-probe-scratch/ProbeT4C3.lean`, builder + fence, upto 30):
**fails at round 2 with a maxRecDepth blowup** (verbatim: "maximum
recursion depth has been reached") — the fence starves the
ground-defeq spine exactly as S3 measured, now as recursion depth
rather than classification failure. No maxRecDepth bump was taken
(the ban).

ADJUDICATED ROUTE (for the record): T4's completion follows the T5
BUILDER ARCHITECTURE — a ready-state builder (`mkT4Rdy env mem …`)
with env free and lookup facts in the pack (T4 is loop-free, so no
invariant family is needed; the anon-vs-static apartness dischargers
exist in Kit/Env, and the `ofNatify` respell now covers raw-literal
digests). That is a T4Defs build-out plus one walk campaign — priced
M — not attempted in this slice's remaining budget. **R5 therefore
REMAINS OPEN** (`T4ThreadedStatement` stays off the statement gate's
slate until its theorem lands); the contracts doc's R5 row is
annotated with this state in this slice's closing commit.

## 5. Validation (verbatim; every run exit-checked, strictly serial
    per the operator's OOM caution)

```
Build completed successfully (400 jobs).          [relsem, post-restart fresh]
info: … step_law census: 60 laws [advance 4, construct 9, envAlg 3, envMap 4, evalArith 2, evalPull 2, heapWP 4, heapWalk 8, loop 2, memBlock 5, memRW 7, perform 5, roundGlue 3, wpSeq 2]
info: … RelSem audit sweep: 5265 declarations …
Build completed successfully (143 jobs).          [speclab]
Total: 7 passed, 0 failed                          [test_unit]
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
```

One instrument note: the D14 grep-ban gate correctly tripped on this
worker's own session LOG DIRECTORY placed inside the relsem tree
(the logs quote the gate's banner); the logs were moved out
(container `.c3-logs/`) and the gate re-ran clean — a reminder that
the gate's scan surface includes untracked files by design.

## 6. Commits, park, and the C4/continuation handoff

| commit | content |
|---|---|
| `293bc9d05` | THE PULL_CONSTRAINED IDENTITY LAW (mirror + both faces + registration + census/sweep re-pins + sub-trio cone pins) |
| `70771b5d0` | THE ROUND-44 WALL FALLS — evalArith/envMap laws + lanes + the substitution-safety hardening + chain checkpoints + engine re-baseline + census/sweep re-pins |
| (this) | the C3 record + the contracts-doc R5 annotation |

**PARK** [AGENT, per the calibrated stop clauses]: deliverable 1 is
landed; deliverables 2 and 3 park at measured, enumerated frontiers
(§3.4/§3.5 item 2 for T5; §4's route for T4) after two green
commits. The walk no longer degenerates — the automation carries it
— but the remaining T5 ladder (items 2–6) plus the T4 build-out are
multi-day scope beyond this session's budget, and the park record is
the stop signal. Probes preserved read-only at container
`.arc18-c3-probe-scratch/` (T5 body, T5 entry, T4); session logs at
container `.c3-logs/`.

For the continuation (C3', or folded into C4/C5 sequencing at the
orchestrator's discretion): items are strictly ordered — the
round-56 routing item unlocks the full body; everything after is the
S3 §3.6 ladder with the wall rows now GONE. The down-pressure story
so far: zero hand-derived per-round equations anywhere in the C3
work — every round of the 50 is an evaluator mint; the walls fell to
five REGISTERED laws and named engine disciplines, not to fixture
text.
