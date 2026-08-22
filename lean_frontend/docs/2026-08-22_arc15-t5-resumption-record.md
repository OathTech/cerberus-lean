# Arc-15 Lane B — the T5 resumption (R-S2-1 executed; climb 3/79 → 13/79; the R13 wall named)

Date: 2026-08-22. Branch: `arc/t5-landing` (worktree
`worktrees/cerberus-lean-arc/workbench-v2`, rebased base = mainline
`db7c82f49`; ancestor check `fc1c8c147 ∈ db7c82f49` verified before
branching). Provenance: [AGENT:arc15-laneB] throughout. All builds
through `scripts/ce` + `scripts/capped`; no heartbeat/maxRecDepth
bumps anywhere (every budget in this record is a walker-internal
LEDGERED sub-cap, chosen lower than or equal to the ambient window).

Commits: `82290a510` (R-S2-1 batch), `a947b59b7` (13/79 batch).
Probe scratch (untracked, arc-11 §9 policy): the six `ProbeT5S4*.lean`
files (S4c updated: renumbering rename + the fact ladder; duplicates
superseded by T5Iter removed; imports `RelSem.T5Iter`), new
`ProbeT5S5.lean` (minimal kernel-isDefEq experiments), outputs
`scratch/probet5s4c-r1.out` … `r19.out`.

## 1. R-S2-1 — what it turned out to be, and its resolution

The register said "sealed step_m closures capture abstraction avatars
(emitter coherence)". The kDiffTrace instrument (new, §3) localized
the kernel-FALSE to a single leaf, and the true face is sharper:

**`fmapAddBy`'s `[BEq α]` INSTANCE-IMPLICIT diverged between the
fixture family and the generated code.** `update_env_aux` is
`{a} [MapKeyType a]`-generic (generated Core_aux.lean:861), so its
insert resolves `BEq a` to the `Lem_Map` blanket
`instBEqOfMapKeyType` (comparator-EQ beq — SD-insensitive; at
concrete `sym` the chain is
`instBEqOfMapKeyType (instMapKeyTypeOfSetType instSetTypeSym_1)`),
while the fixture's `eIns`, elaborated at concrete `sym`, silently
picked the derived `instBEqSym` (prio 1000, SD-SENSITIVE — exactly
the divergence the LemLib Fmap docstring warns about,
LemLib.lean:436-441). The two are genuinely non-defeq — Lean's own
error text at the fix site confirms it verbatim:

```
synthesized type class instance is not definitionally equal to expression inferred by typing rules, synthesized
  instBEqSym
inferred
  Lem_Map.instBEqOfMapKeyType
```

At concrete k both spellings EVALUATE away (why every k=0 walk was
blind to it); at symbolic j the stuck insert exposes the raw
instance terms — exactly the arc-11 S2 §6 "kernel isDefEq returns
FALSE, not error" measurement. The "sealed/avatar" attribution was
the park's best guess from outside; the avatars were incidental.

**Fix (committed):** `T5Prefix.eIns` pins the generated call site's
instances explicitly (`eInsMK`/`eInsBEq` abbrevs); T5Iter's three
helper lemmas pass the instance explicitly (`@fmapAddBy_built …
eInsBEq …`). Kit/Map's laws were already `[BEq α]`-generic — no law
changes. Audit sweep pin deliberately re-baselined 3348 → 3356
(reason comment at the pin). Fixture-independence held: no pinned
Core dumps or fixtures were touched (the renumbering-compatible
design promise of the register entry).

**Result:** the historic round-4 blocker (`RSK_eval "eval operands
of Load"`) FIRES; both R-S2-2 routes unblock (§4).

## 2. Prerequisite work (mechanics steps 1-2)

* Rebuild on `db7c82f49`: prelude-src, oracle dune build +
  `cerberus-lib.install` + `cerberus.install` + dune install,
  lean-prelude-src, lean-native-obj, capped root build (367 jobs),
  capped relsem build (363 jobs). lem-sync gate GREEN on first run
  (no stale trees). `test_unit.sh`: `Total: 7 passed, 0 failed`.
* Probe scratch updated for the arc-13 renumbering: ProbeT5S4c's
  symbol references shifted +30 (`symA502→symA532` … via two-pass
  sed; the map read off the arc-13 T5Iter re-pin diff). `seedT5 =
  1048577` unchanged. ProbeT5S4/S4b need no rename (no symbol refs).

## 3. Engine batch (all in `Tactics/AppWalk.lean` + `WalkTrace.lean`; engineRev 3 → 4)

* **kDiffTrace** (R-S2-3 register item, partially discharged): a
  trace-lane bounded kernel diff — argwise descent on shared heads,
  lambda-descent with a shared fresh local (domains kernel-checked
  first), `pp.explicit` leaf printing — wired into the eq-fact
  chase's KFALSE-miss path. This is the instrument that found the
  instance leaf. Trace lanes only; no proof surface.
* **addRawAuxThm**: the raw seal fallback (shared by
  `mkAuxRfl`/`mkAuxThmRobust`) now closes LEVEL mvars — fresh level
  params on the declaration side, the ORIGINAL mvars at the
  reference site — after the round seal died with `(kernel)
  declaration has metavariables` (6 surviving universe mvars; the
  expr-mvar guard alone was not closure).
* **Bridge-aux eq-fact certificates**: the chase's fact-rewrite
  certificate is now an explicit kernel-checked bridge aux
  (`e1 = fact-lhs` by rfl) composed with the fact by `Eq.trans` —
  the old defeq TYPE-HINT form defeated the elaborator re-check at
  round-seal time (`Application type mismatch: hlk513`).
* **SECOND-CHANCE FACTS STAGE** in `dischargeHyp`: the chase-rewrite
  route re-runs under its OWN fresh window after the computed-value
  lane misses — measured: the lane's window died inside a ~30s
  KERNEL whnf (kernel time is heartbeat-free, uncappable) before the
  facts route ever ran.
* **normCompute sub-cap (20k)**: fact-needing crossings trip fast to
  the kernel fallback + facts pipeline (give-up-keeps-compact-
  spelling), instead of grinding the candidate window.
* **Measured-and-reverted**: a seal-transparent chase ENTRY (unseal
  + aux-rfl bridge). It dies with `(kernel) deep recursion detected`
  — see §5, the new wall.

## 4. The climb — position and the validated R-S2-2 route

Rounds (symbolic-j hbody succ block, `StT5 n (j+1) → StT5 n (j+2)`,
79 census rounds):

* park (arc-11): **3/79** (stuck `fuel + 76`);
* after R-S2-1: **5/79** (stuck `fuel + 74`) — round 4 = the
  historic blocker, fired on the hlk513-class facts;
* after the fact ladder + second-chance stage: **13/79** (stuck
  `fuel + 66`).

**R-S2-2 is RESOLVED-BY-VALIDATION as pure fact supply — no engine
lane needed for the spelling half**: with `eIns` coherent, ordinary
context facts stated at the family spelling kernel-match the walk's
own interstitial envs mid-chase. The ladder pattern (all proved from
committed T5Iter machinery — `lookup_eIns_ne`/`lookup_eIns_eq` +
`eIns_built` chains + `symCmpO_ne_of_id (by decide)`; unitSym skips
via `hdig`/`hseed` + the slate bound by `omega`):

```
hpI1      lookup symI  over [a543]                      (a542's bind)
hpA543_2  lookup a543  over [a543,a542]                 (load-x operand)
hpA542_3  lookup a542  over [..a545]                    (load-i operand)
hpA544_4/hpA545_4  guard operands over [..a544]
hpA537_6/hpA538_6  PEcase operands over [..a537]
hpI8/hpS9 …        memory-phase reads
hpA555_10/hpA556_11/hpA550_12/hpA551_12  load/add operands
hpA549_14/hpA557_14  store-s operands
hpI15/hpA564_16/hpA559_18/hpA560_18      i-increment phase
hpA558_20/hpA565_20/hpA21/hpS22          store-i + Esave rebinds
```

Chase HITs measured this session: `hlkN`, `hlk513`, `hpI1`,
`hlk512`, `hpA544_4`, `hpA545_4` (rounds 4-13 consumed them; the
deeper ladder entries are staged in the probe for the rounds past
R13). Promotion plan: once the full iteration walks, the ladder
migrates from probe `have`s into a committed T5Iter wave-2 family
(one lemma per prefix class, exactly the T5Iter style).

## 5. THE NEW WALL — R13 (`fuel + 66`), named for the resumption

**Exact goal state at the park:**

```
⊢ app (drive_nonmemory_steps_aux2_lemFuel (fuel + 66) t5File.tagDefs fmapEmpty [0]) (walkSt_aux✝ n j)
    = app (dnms5 fuel fmapEmpty [0]) (StT5 n (j + 2))
```

with the R13 crossing (dnms_round's advance premise):

```
app (advance_step t5File.tagDefs 0 (Step_with_runstate2 (RSK_eval "Epure") (walkVal_aux✝ n j))) (walkSt_aux✝ n j)
```

= the "Epure" eval of `PEcase (Ctuple [PEsym a_537, PEsym a_538]) …`
(the loop guard's conv-chain case split).

**The wall class is a KERNEL LIMIT, not a missing fact** (this is
what the arc-11 record did not anticipate — its item 3 assumed all
remaining rounds were "designed classes"):

1. `Kernel.whnf` on the crossing ERRORS (`deep recursion detected`)
   — the eval body under the seal is too deep for the kernel's
   recursion guard, while the ELABORATOR reduces it in ~30s
   (heartbeat-free kernel time dominated; uncappable — measured via
   the sub-cap failing to bite).
2. Every certificate shape tried that materializes the unsealed
   body in a DECLARATION STATEMENT dies in kernel typechecking with
   the same `deep recursion` (the reverted unseal-bridge
   experiment: `mkAuxRfl e0 (unsealed e)` — the kernel must
   typecheck the deep term itself, independent of the defeq).
3. Therefore the chase cannot progress at R13 with the current
   certificate shapes: the kernel engine refuses the form, and
   elaborator-computed reductions cannot be certified monolithically.

**The named next move — SEAL-THROUGH-THE-CHASE**: the chase must
emit CHECKPOINTED SEALS as it reduces — periodically sealing the
current (deep, partially-reduced) form's leaves/whole as aux
DEFINITIONS so that (a) every certificate statement stays shallow
(references seal constants), and (b) each kernel obligation's
reduction distance (seal_k → seal_{k+1}) stays inside the kernel's
recursion guard. This is the existing per-stage emitter philosophy
(arc-9 D3: name-every-big-term) pushed INTO kWhnfWithFacts's
levels. Design notes:

* the elaborator drives discovery (it can reduce these forms); the
  kernel checks seal-to-seal deltas only;
* `sealCtorLeaves` handles ctor spines today; the chase needs a
  non-ctor variant (seal a match/rec-stuck form whole, then state
  the next chase step against the seal constant);
* the level-mvar closure (addRawAuxThm) and the bridge-aux
  certificate shape from this session are prerequisites already in
  place;
* expected side benefit: the ~30s/round R13-class recompute cost
  drops on replay (seals persist per walk).

Secondary register items from this session:

* **R15-1**: kDiffTrace prints misaligned junk when both sides are
  `Fmap.rec` of DIFFERENT operations (lookup vs insert — motives
  differ); guard on the motive argument before descending.
* **R15-2**: eq-fact MISS cost grows with the fact count × chase
  depth (each kernel isDefEq re-reduces the fact LHS); a key-based
  prefilter (compare the lookup KEY's reduced literal) would cut
  most of it. Not yet binding at 13/79 (~1.5s/fired round).
* **R15-3**: the probe's duplicated family lemmas were removed in
  favor of `import RelSem.T5Iter`; ProbeT5S3*/S4/S4b still carry
  pre-renumbering context in comments (content-harmless).

## 6. Verbatim tallies (at `a947b59b7`)

```
Build completed successfully (363 jobs).
Total: 7 passed, 0 failed
check_lem_sync: OK (src e51f885203ccdb8e83aa379e7e1ff3372598759c5b8e216ded6554f0d6181105, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 58 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: T5.lean — not present yet (registered, pending)
check_proof_size: OK
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
```

Flagship cones: `entry5_walk` + the T5Iter family re-elaborated
in-build under the pinned instance and the rev-4 engine at every
build above; their exactness pins (`[propext, runEffectful,
Classical.choice, Quot.sound]`) are in-build (Audit.lean, A-F1
pins) and would have failed the build on any drift. The T5 gate row
remains honestly PENDING.

## 7. Distance-to-landed (honest)

T5 landed = the iteration theorem (79/79 at symbolic j) + exit +
post + `iter_compose` composition + the statement, gate row flipped.
This session: the two named blockers (R-S2-1, R-S2-2) fell; the
climb moved 3/79 → 13/79; the remaining distance is gated on ONE
new engine capability (seal-through-the-chase) plus the mechanical
fact-ladder grind (~66 rounds, fact classes already patterned), then
exit/post/composition (designed, unstarted). The wall is precisely
characterized with reproducers; no improvisation was attempted past
the third engine experiment (park-don't-improvise).
