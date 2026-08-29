# The proof-style professor pass — arc-18 breadth campaign proof texts

[AGENT] Independent read-only review, 2026-08-27. Reviewer role: the
grumpy professor (Floyd/Hoare/SL/Iris/RefinedC-BRiCk literature
background), reading the proof TEXTS cold in worktree
`worktrees/cerberus-lean-coherence/lean_frontend/`. No builds run.

Standard applied ([USER] calibration, binding): judge STRUCTURAL
COINCIDENCE with the human correctness argument and LEGIBILITY — not
literal step count. "We don't need to make every example just
verify_fn ; auto — that's probably impossible for more complex
functions. But it's great for simple ones! I'd expect some working
tactics, similar to brick_wp in complex cases." The sin under review
is engine vocabulary leaking into what a reader must understand.

Sample: `relsem/RelSem/T5.lean` (+ engine context `T5Spine.lean`,
`T5Seam.lean`, `T5Inv.lean`), `T6Probe.lean`, `T7.lean`,
`Corpus/C3B.lean`, `Corpus/X7.lean`, `Corpus/E4.lean`,
`Segment.lean`, `SegmentFaces.lean` (tactic entry points),
`relsemcore/RelSem/Threaded.lean`, and the C fixtures in
`tests/verify/`.

All paths below are relative to
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-coherence/lean_frontend/`.

---

## 0. Summary verdict

**PASS-WITH-FINDINGS.**

The statement layer and the rules layer pass the professor test
cleanly — I could tell, cold, exactly what is proved for every file
in the sample, and `Segment.lean` reads as a recognizable (and
honestly-cited) descendant of Floyd cut-point reasoning with
Dijkstra bound functions. The headline proofs are structurally the
blackboard argument: simple programs end in `verify_fn <spec>;
seg_auto` (T6Probe.lean:612-614, E4.lean:418-420), and the loop
programs visibly compose entry / body-invariant / exit through a
once-proved while rule (T7.lean:145-183, C3B.lean:713-746).

The findings: (1) each corpus fixture file carries ~300-500 lines of
copy-pasted harness-spine and builder boilerplate that a cold reader
must wade through to reach the 40 lines of actual content; (2) in
the concrete-input corpus files the "declared invariant" is
circular — its `at_` field is defined as projections of the walk
endpoints themselves, so the declaration formally says "the
invariant at visit k is whatever state the run reached", and the
human-readable content (n = 27 then 2) lives only in comments;
(3) the spelling table (`JoinSpellings`) and several other pieces of
engine vocabulary do appear in user text despite the layer's own
contract that they must not; (4) hypothesis-discharge blocks are
walls of seven-argument projection plumbing that an obvious tactic
should absorb.

None of these findings is unsoundness. All are legibility debt, and
most are cheap to fix because the offending text is stereotyped.

---

## 1. Per-file review

### 1.1 `relsem/RelSem/Segment.lean` — the rules. Grade: **A-**

This is the best file in the sample and it would survive a seminar.

What is GOOD:

- **The judgment is stated in one line and is honest about what it
  is.** `Seg C B s s' := ∃ k, k ≤ B ∧ ∀ fuel, C (fuel + k) s = C
  fuel s'` (Segment.lean:77-78). This is not a Hoare triple — it is
  a budgeted, fuel-relative reachability equation between concrete
  states — and the file does not pretend otherwise for long (see
  ding below). The ∃-round design decision ([F1]) is explained with
  the exact program shape that forces it (branch-in-loop,
  data-dependent per-iteration round counts, Segment.lean:34-40) and
  T7 then demonstrates it. The budget-as-bound-function reading
  ([F7], total correctness where the donors' WP is partial,
  Segment.lean:28-32) is a genuinely nice observation, correctly
  attributed to Dijkstra/Gries.
- **Lineage citations are exemplary.** Floyd 1967, Hoare 1969,
  RefinedC `typed_block` with file and line
  (`deps/refinedc/theories/typing/programs.v:68-73`), BRiCk
  `wp_while_inv` (`stmt.v:467-501`, marked IDEAS-ONLY), each tied to
  the specific mechanism it justifies (Segment.lean:11-32). I
  checked the claims' shapes against my knowledge of those
  developments; the attributions are accurate, not decorative.
- **The composition section (§2) is textbook.** `Seg.of_chain`,
  `mono`, `refl`, `trans` (the sequence rule, budgets add,
  Segment.lean:120-129), `trans_done`, `SegDone.run` (discharge at
  concrete fuel, Segment.lean:145-150), `Seg.iter`
  (Segment.lean:161-172), `Seg.while_inv` (Segment.lean:180-184).
  Every proof is three to ten lines of Nat arithmetic. A professor
  can check §2 completely in ten minutes. This is what "proved once"
  should look like.
- **`Summary.consume` (Segment.lean:488-495) is the Hoare procedure
  rule and is recognizable as such.** The [F9] `FnSpec`
  promotion-compatibility note (Segment.lean:384-390) is design
  writing of unusual clarity.

What is NOT good:

- **`InvMap.while_inv`'s map lookup is dead.** The hypothesis is
  literally named `_hfind` (Segment.lean:301) and neither `M` nor
  `_hfind` is consumed by the proof (Segment.lean:303-304 is just
  `Seg.while_inv n hbody hexit`). The docstring says "`hfind` pins
  the obligations to the DECLARED map (RefinedC: `typed_block`
  resolved through `Q`)" — but in RefinedC the gmap is load-bearing
  (the judgment for `goto b` genuinely resolves through it); here it
  is a costume. A cold reader notices the underscore immediately and
  concludes the `InvMap` type (Segment.lean:262) currently adds
  vocabulary, not logic. Either make lookup load-bearing (e.g. the
  derived obligations only exist for found entries, and `seg_auto`
  resolves labels through the map) or drop the map until it is.
- **One overclaim:** "the segment judgment is a triple at the
  equation calculus" (Segment.lean:17-19). It is not; it is an
  equation. The triple shape only emerges per-site when fixtures
  bolt pre-hypotheses onto chain lemmas. The honest sentence is two
  paragraphs down (§1's own text is fine); delete the triple claim.
- **"No new assertion DSL" (Segment.lean:45-48) has a cost the file
  does not admit:** because segment pre/posts are "the existing
  footprint vocabulary", loop preconditions in fixtures are raw
  byte-map and TreeMap facts (see the BPack finding, §1.2 below),
  not points-to assertions. The frame story ("rides the
  CerbMemInterp footprint discipline") is asserted here but is only
  checkable at the WP layer, which the segment-layer reader never
  sees.

Answering the brief's question (d) directly: yes, `Segment.lean`
reads as a recognizable program logic to someone who knows the
literature — specifically as Floyd's original formulation
(assertions at cut points of a flowgraph, verification conditions on
paths between them) plus bound functions, deliberately below the
Hoare-assertion level. The one place it postures above its actual
station (the decorative `InvMap`) is exactly the place a referee
would strike.

### 1.2 `relsem/RelSem/T5.lean` — the flagship. Grade: **B+**
(statement A, proof shape A-, leakage B-)

(a) STATEMENT: excellent. Reading only lines 33-112 I know
everything: the C program is quoted in the spec's docstring ("for
the C loop `for (i = 0; i < n; i++) s += i`", T5.lean:36-37); the
spec is `r.dres_core_value = intValue (n * (n - 1) / 2)`
(T5.lean:38-39); the quantifiers are explicit and honest
(`T5EnvHypThr → ∀ seed, T5SeedApart seed → ∀ n, 0 ≤ n ≤ 100 → …`,
T5.lean:89-94); the guard hypotheses are each explained in one
comprehensible sentence (T5.lean:41-48). `CallHarnessAdequateThr`
resolves (relsemcore/RelSem/Threaded.lean:107-117) to a
self-contained, fuel-opsem-only membership statement over the
production runner — no Iris, no engine. The ∀-n input family is
correctly flagged as the point ("the trip count is SYMBOLIC … the
loop induction lives in the once-proved rule", T5.lean:9-12).

(b) PROOF SHAPE: the headline proof is `verify_fn sumSpec; seg_auto`
(T5.lean:100-102), and the invariant that feeds it has REAL
assertion content — `triF` with kernel-checked closed form
`triF_closed` (T5Inv.lean:61-83) is precisely the s = k(k-1)/2 a
human writes on the blackboard, and `t5At`/`t5SeamInv`
(T5Seam.lean:61-72) declare it once at the loop label. Of the whole
sample, T5 is the only ∀-input loop, and it is the one place the
invariant machinery earns its keep rather than wearing it.

(c) LEAKAGE, named:

- `t5_post_o` (T5.lean:67-80) is engine text in the flagship file: a
  reader hits `rDone5`, `setMaps`, `finalize … "callND"`, free `bm
  am` map binders, and `@[seg_post]` before they reach the theorem.
  The mathematical content is one line (`triF n.toNat = n*(n-1)/2`,
  already proved as `triF_closed`); the rest is registry feed and
  belongs in T5Spine with the other `@[seg_*]` supply.
- The header (T5.lean:14-20) narrates the engine: "registered walk
  chains over the ∀-k pack closure", "[F3] normalizer",
  "`driver2_of_seg` through the once-proved `wpk_seq_scratch2`".
  Useful to the maintainer; noise to the reader the file elsewhere
  addresses. Two sentences of it (the invariant and "one declared
  invariant, derived obligations, two-line proof") are the right
  header.
- `T5SeedApart` hardcodes `1152921504606846976` (T5.lean:48). The
  named constant exists (`supplyCeil`, T5Inv.lean:351, with
  `supplyCeil_eq` at T5Spine.lean:44). If statement-TCB hygiene
  forbids importing it, define the named constant statement-side;
  a bare 2^60 numeral in a headline hypothesis is exactly the kind
  of thing a referee circles. (The accompanying comment — 2 draws
  per iteration, ≤ 100 iterations, plus slack, below every static
  hash ≥ 2^60 — is good; the reader can even check the fixture's
  hash literals against 2^60. But see §3 item 5.)
- One layer down, `T5Seam.BPack` (T5Seam.lean:89-131) is the real
  precondition of the loop body: 27 fields, including
  `readBytesFrom`/`reconstructValue`/`memValueToBytes` byte-level
  facts and TreeMap lookups. In separation-logic vocabulary this is
  three points-tos and three pure bounds. This is the strongest
  single piece of evidence that the missing assertion layer is now
  the binding constraint (see §2.3).

### 1.3 `relsem/RelSem/T6Probe.lean` — the simple-case exemplar.
Grade: **C+** (headline theorems A; the file as a proof text C)

The calibration says a simple program should read as spec + auto.
The theorems do: `t6Spec` is one line (T6Probe.lean:74-75),
`pickSpec` is a four-line record (T6Probe.lean:594-597), and
`T6Threaded` is `verify_fn pickSpec; seg_auto`
(T6Probe.lean:612-614), unconditional ∀-seed. If the file were 80
lines it would be an A.

It is 640 lines, and the reader must pass through:

- A history chronicle as the header (T6Probe.lean:1-45): S1's parked
  wall, the 64 G cap, "recorded heartbeat crossers on the `hout`
  recast direction (S1 record §4.2, input 5)" (T6Probe.lean:83-86).
  This is arc archaeology, which the project's own shop-window
  doctrine banishes from front docs — proof texts deserve the same
  rule.
- THREE routes retained side by side: the ground drive
  (T6Probe.lean:260), the open drive (T6Probe.lean:321-330), and a
  piecewise-chain smoke (T6Probe.lean:624-639), each with a
  `derive_rounds` clause whose `fencing …`/`assuming …`/`upto 60
  chain builder` vocabulary is defined nowhere a reader is pointed
  to. An acceptance-probe file may legitimately be a museum; then it
  should not also be the exemplar the corpus recipe cites
  (E4.lean:9, "the T6Probe open-memory route verbatim").
- Raw fuel arithmetic in a user-facing proof: `ro_chainrel … 999947`
  (T6Probe.lean:386) and `show app (driver2_lemFuel (999999+1) …)`
  (T6Probe.lean:397). The number 999947 is unexplained (it is
  evidently defaultFuel minus the mint's round count, but the reader
  must reverse-engineer that). T7 shows this is already solved —
  `driver2_of_seg` exists precisely so that "no per-fixture fuel
  arithmetic" (T7.lean:206-220, Segment.lean:313-315) — yet the
  exemplar still does it by hand.
- Symbol-hash literals as fixture data: `Symbol ""
  16562859848569467201 (SD_Id "x")` (T6Probe.lean:89), 15-digit
  address literals (T6Probe.lean:91-92). Data, yes — but data that
  should be minted next to the drift gate, not hand-maintained in a
  proof text.

(b) coincidence: for a concrete-input branch program the human
argument is "evaluate it"; the ground/open drives are that, so the
degenerate coincidence holds. Nothing in the file states the branch
fact (10 > 5, or whichever guard fires); the reader learns the
answer is 7 from the spec and trusts the mint. Acceptable for
concrete instances; worth noting because the same absence recurs in
E4.

### 1.4 `relsem/RelSem/T7.lean` — branch-in-loop. Grade: **B+**

The best loop EXHIBIT in the sample. `t7_run_seg` (T7.lean:145-183)
is the proof I would show a class: entry segment (95 rounds), body
obligation by cases on the visit index with the even/odd arms'
different budgets composed by `.mono` into the uniform bound
(T7.lean:161-175 — this is [F1] doing real work, exactly the case
`iter_compose` cannot state), exit segment, all joined by
`hentry.trans_done (InvMap.while_inv …)` (T7.lean:183-185). The
budget arithmetic `95 + (94 * 2 + 35)` is visible and meaningful.
Statement layer same quality as T5 (T7.lean:32-49, 227-231).

Findings:

- **The invariant is a trajectory, not an assertion.** `at7`
  (T7.lean:78-84) is `compOf (h1 …)`, `compOf (h2 …)`, `compOf (h3
  …)` — projections of the walk endpoints. The header's claim ("at
  the k-th loop-head visit, n's object holds the k-th value of the
  run's decrement sequence 4, 3, 0", T7.lean:56-58) is TRUE but
  appears formally nowhere in the declaration; the values 4, 3, 0
  are recoverable only by unfolding the walks. See §2.2 — this is
  the sample's central conceptual finding.
- **The `StAlign` section (T7.lean:116-139) is term wrangling.**
  `St1_eq` applies `bEven72_align` at seven explicit projections of
  `h1` — thirteen lines to say "the family member is the walk
  endpoint". Same shape three times here, five times in C3B, and
  the identical `atComps` helper is re-defined per fixture
  (C3B.lean:513-519, X7.lean:457-463). One layer-side lemma
  (`align_atComps`, say) or a `seg_align` minter would delete all
  of it.
- The spelling table is declared in user text with both slots equal
  (`spell7`, T7.lean:63-66) — see §2.1.
- `t7Offer`'s type (T7.lean:105-110) drags the full
  `nd_action (Fmap thread_id (List core_step2)) step_kind …`
  signature into the reader's face; an abbreviation
  (`DoneOffer v σ`) exists in all but name (`DSegDone`,
  Segment.lean:339-342) and should be used.

### 1.5 `relsem/RelSem/Corpus/C3B.lean` — the census loop.
Grade: **B-**

This matters most, because it was written at breadth by the recipe,
not by the layer's author for show — it is the preview of what a
thousand-program corpus reads like.

GOOD: the file has the same clean spine as T7 — spec + guard
(C3B.lean:634-643), one invariant map entry (C3B.lean:667-677),
`c3b_run_seg` with visible entry/body/exit composition and budget
`49 + (48 * 1 + 35)` (C3B.lean:713-746), driver atom through
`driver2_of_seg` with no fuel arithmetic (C3B.lean:767-779),
two-line headline (C3B.lean:802-804). The house pattern replicated
faithfully at breadth is itself evidence the design transfers.

NOT good:

- **The engine:content ratio.** Of 815 lines, the human-content core
  (spec, invariant declaration, `c3b_run_seg`, headline) is ~120
  lines. The other ~700 are: fixture data with hash literals
  (C3B.lean:41-42), THREE `derive_rounds` clauses with ten-item
  hypothesis lists and `fencing` clauses naming engine internals
  (`mk_call_catch_exceptional_condition`, C3B.lean:158-214), the
  mkRdy/mkLH builders — 20 and 28 lines of raw `driver_state`
  record literal each (C3B.lean:105-153), and the k-stage harness
  spine k1_o…k9_o + address facts + errno block
  (C3B.lean:279-423) which is byte-for-byte the T6/E4/X7 text
  modulo the fixture's names. A reader checking THIS file must
  re-read 300 lines they have read three times before, and must
  diff by eye to trust nothing changed. That is the definition of
  boilerplate that should be minted (the SegmentFaces header even
  registers "engine-side minting is the registered arc-19 frontier",
  SegmentFaces.lean:24-25 — this review's data says that frontier is
  now the binding legibility constraint at breadth).
- **Discharge plumbing walls.** `seg_body0`/`seg_exit`
  (C3B.lean:550-626) instantiate the walk chains at seven explicit
  projections, with a fourteen-line `halign` rewrite
  (C3B.lean:601-614) and side goals like `case xscB => show seed + 2
  < 1152921504606846976; omega` (C3B.lean:624). Every one of these
  case blocks is mechanical; a `seg_obligation` tactic consuming the
  registered chain and the alignment rfls should leave nothing here.
- **The trajectory-invariant again**: `atC3B` (C3B.lean:660-664) is
  `compOf (h1 …)` / `compOf (h2 …)`; "value trajectory 27, 2"
  (C3B.lean:14-15) is comment-only. The rfl pins that carry the
  actual content (`e49_mem`: memory = write of `i32 27`,
  C3B.lean:446-448; `b48_mem`: write of `i32 2`, C3B.lean:451-454)
  are good and readable — they are the closest thing in the file to
  the human sentence "n holds 27, then 2" — but they are labeled
  "Obligation feeds", not surfaced as the invariant.

### 1.6 `relsem/RelSem/Corpus/X7.lean` — return-inside-loop.
Grade: **B-**

The design point lands: early return = the exit segment consumes the
return arm from a loop head instead of the guard-false path, with
ZERO interior iterations — `hbody` is vacuous by `omega`
(X7.lean:614-616) and the budget is `73 + (1 * 0 + 51)`
(X7.lean:608). That the multi-exit edge case needed NO new rule is a
genuine credit to the ∃-round judgment, and the file says so
plainly (X7.lean:4-9). The honest degenerate invariant (`atX7 | _ =>
compOf h1`, X7.lean:560-563) is fine.

Same debits as C3B, same magnitude: ~550 of 689 lines are the
replicated spine/builders/mint clauses; `spellX7` with equal slots
(X7.lean:547-549); the `seg_exit` projection wall
(X7.lean:494-528). Additionally the terminal offer is spelled inline
as the raw `NDactive (fmapAddBy defaultCompare 0 [Step_done2 …] …)`
tuple TWICE (X7.lean:501-505 and via `x7Offer`, X7.lean:582-588)
where `DSegDone` exists to hide exactly that.

### 1.7 `relsem/RelSem/Corpus/E4.lean` — the easy program.
Grade: **B-**

`is_digit(53) = 1`, no loop, plain ∀-seed with no guard — and the
file correctly EXPLAINS why no guard ("no loop ⇒ no fresh draws ⇒ no
digest/apartness guard", E4.lean:13-14): that is exactly the kind of
sentence a professor wants. Headline: spec + `verify_fn digitSpec;
seg_auto` (E4.lean:402-420). By the calibration, the easy tier
delivers its contract at the theorem level.

But 431 lines for a two-line C predicate, of which ~370 are the
same spine/mint text as T6 (E4.lean:157-301, 339-348), plus the
hand-rolled driver atom with the unexplained `999943`
(E4.lean:383) and `driver2_lemFuel (999999+1)` (E4.lean:392-393) —
the T6 pre-`driver2_of_seg` idiom copied AFTER the better idiom
existed (T7/C3B/X7 use `driver2_of_seg`; the read1 shape evidently
lacked a segment-side discharge and fell back). Also noteworthy:
nowhere does the file state 48 ≤ 53 ≤ 57 — the short-circuit
range-check reasoning that IS the program is entirely inside the
mint. For a concrete instance "evaluate" is a legitimate human
argument, so this passes; but it means the easy tier currently
demonstrates evaluation, not reasoning, and a reader should not be
told otherwise.

### 1.8 `relsemcore/RelSem/Threaded.lean` — the statement forms.
Grade: **A**

`CallHarnessAdequateThr` (Threaded.lean:107-117) is a model
statement face: membership in the production runner's enumeration,
threaded initial state with the seed an explicit parameter, ∃ r,
Active ∧ spec. The seed-quantification honesty note
(Threaded.lean:33-43: unrestricted ∀-seed is FALSE for some shapes,
so the face parameterizes and each client chooses) is precisely the
kind of scar-tissue documentation that makes a statement layer
trustworthy. The ambient bridge lemmas are cleanly quarantined and
labeled as deliberately impure (Threaded.lean:180-216). No findings.

### 1.9 `relsem/RelSem/SegmentFaces.lean` (context only — the two
tactics). Not graded as user text.

Read to judge whether `verify_fn; seg_auto` is an honest black box.
It is at the right altitude: `verify_fn` is bridge-only ("one
refine, no logic", SegmentFaces.lean:5-8; the five statement shapes
enumerated at SegmentFaces.lean:761-784), and `seg_auto` claims
"the meta layer shapes claims, never certifies them", with
undispatchable atoms a loud fail-closed error
(SegmentFaces.lean:16-19). Two remarks: (i) the shape classifier
(`classifyStmt`, SegmentFaces.lean:729-759) infers the statement
form from binder domains (Prop/Nat/Int positions) — brittle-looking
but fail-noisy, acceptable; (ii) the local-hypothesis search and
probe-budget machinery (SegmentFaces.lean:119-208) is real
metaprogramming a reviewer of the TCB story must read — but the
kernel checks the emitted terms, so it stays outside what the
proof-text reader must trust. Consistent with the brick-wp
calibration.

---

## 2. Cross-cutting findings

### 2.1 The spelling table does NOT belong in user text — and the
layer's own contract agrees

`Segment.lean` §3 promises "twin-builder vocabulary never reaches
the user surface" (Segment.lean:203-205), and `T5Seam.lean`
demonstrates the mechanism honestly (one declaration, both
spellings routed by index, `t5SeamInv_St_eq` kernel-checked,
T5Seam.lean:81-83). But every fixture in the sample WRITES the
spelling table by hand — `spell7` (T7.lean:63-66), `spellC3B`
(C3B.lean:647-649), `spellX7` (X7.lean:547-549) — and in all three
corpus cases both slots are the SAME builder, i.e. the user is made
to answer a question about the compiler's continuation
representation whose answer is "no seam here". Worse, declaring the
table requires first hand-writing `mkLH`, a 28-line `driver_state`
record literal (C3B.lean:127-153). The fall-in/stored distinction is
a measured compilation artifact ([F3], the C3b seam); it is exactly
the kind of fact the engine knows and the human does not. Verdict:
the spelling table is engine data. Default it (stored = entry unless
the mint detects the seam), mint the builders, and let only genuine
two-spelling programs surface anything — and even then as a derived
object, not user-authored text.

### 2.2 The corpus "invariant" is a trajectory, and the declaration
is circular — the sharpest finding

In T7/C3B/X7 the declared invariant's content field is
`at_ k := compOf (h_k …)` — projections of the very walk endpoints
the obligations then re-prove the run passes through
(T7.lean:78-84, C3B.lean:660-664, X7.lean:560-563). Formally the
declaration says: "the assertion at visit k is: being the state the
run reaches at visit k." That is the strongest-postcondition
trajectory, not an invariant; it constrains nothing and documents
nothing, and every human-meaningful fact ("n holds 4, 3, 0";
"value trajectory 27, 2") lives in comments (T7.lean:56-58,
C3B.lean:14-15) or in adjacent rfl pins labeled as feeds
(C3B.lean:446-454). For CONCRETE-input programs this is honest —
the human argument for `lead_digit(273)` genuinely is "run it: 273,
27, 2" — and the machinery correctly degenerates to symbolic
evaluation with checkpoints. But then the files should say
"checkpoint states", not "THE INVARIANT (the one human artifact)"
(C3B.lean:630): the vocabulary claims Floyd-Hoare content the
formal object does not carry. Only T5 has a real invariant — `triF`
with its closed form (T5Inv.lean:61-83), where `at_` is built from
`p.n`, `triF k`, `k` — and there the machinery visibly pays off.
Combined with the dead `_hfind` (Segment.lean:301, §1.1), the
current corpus reading is: Floyd/RefinedC costume over concrete
state chaining, with one genuine invariant instance (T5) proving
the costume can become the real garment. The fix is cheap and
mostly presentational: make `at_` carry the VALUES (the readable
equalities), derive the state family from values + minted builders,
and let concrete fixtures declare `values := [273, 27, 2]`.

### 2.3 The missing assertion layer is now the binding constraint

`BPack` (T5Seam.lean:89-131): 27 fields of byte-map reads,
`reconstructValue`/`memValueToBytes` roundtrips, TreeMap lookups,
dead-list checks, funptrmap emptiness — this is the loop body's
precondition, and in any SL-style vocabulary it is `n ↦ n_v ∗ s ↦
sv ∗ i ↦ iv` plus four pure bounds. The `derive_rounds` hypothesis
lists (ten items, C3B.lean:178-191) are the same story. The
"no new assertion DSL" decision (Segment.lean:45-48) was right for
bring-up; at breadth it is the direct cause of the largest
signature-level illegibility in the sample. The project already
owns the target vocabulary (points-to at the WP layer,
CerbHeapWalk); the segment layer needs a thin assertion record
(points-to + alloc-live + pure) that ELABORATES to today's raw
facts, so signatures read as assertions while the engine keeps its
map facts.

### 2.4 What is GOOD across the sample (said once, deliberately)

- Statement faces are uniformly self-contained, fuel-opsem-only,
  quantifier-honest, with the C program quoted or named at the top
  of every file. I never once had to open the engine to learn WHAT
  was proved. This is the hard part and it is done.
- The UB-freedom twin accompanying every headline, by the same
  route, is exactly the boring-spec doctrine paying off.
- The two working tactics have honest, narrow contracts and
  fail-closed behavior — brick-wp calibration met.
- The ∃-round budget design is a real, cleanly-motivated
  contribution of the layer, and X7 (multi-exit for free) plus T7
  (uneven arms) demonstrate it the way a paper would.
- Lineage discipline in `Segment.lean` is the best I have seen in
  this project's texts.

---

## 3. Places where, reading cold, I could NOT reconstruct why a
step is sound

1. **Every `derive_rounds` product.** The fixture files use
   `e_chainrel`, `ro_chainrel`, `e49`, `ro51`, `b48` with no
   statement visible at the use site and no pointer to where the
   minted lemma's statement can be READ (the R1 contract §6 is
   cited by number only, T6Probe.lean:38). I infer the ∀-fuel
   relative chain shape from `Seg.of_chain`'s type; a cold reader
   should not have to. One doc-comment on the `derive_rounds`
   command (or a `#print`-style emitted summary) naming the shape
   of what `NAME_chainrel`/`NAMEk` denote would fix this.
2. **The fuel literals `999947`/`999943`** (T6Probe.lean:386,
   E4.lean:383) and `driver2_lemFuel (999999+1)`
   (T6Probe.lean:397, E4.lean:392): the arithmetic relating them to
   `lemDefaultFuel` and the mint's round count is nowhere stated.
   `driver2_of_seg` (Segment.lean:351-369) eliminates the pattern;
   the read1 shape should get the same treatment.
3. **`CanonAt` soundness** (Segment.lean:324-331): the claim that
   harness continuations consume the state only through rest
   projections ("`wpk_seq_get`'s contract") is a comment; at the
   fixture (`@[seg_canon] … := rfl`, C3B.lean:286-288) nothing
   shows the reader which rule enforces it. I trust it because the
   kernel checks the composed term; I cannot RECONSTRUCT it from
   the sampled text.
4. **`seg_env_lookup`** appearing as a terminal tactic in case
   blocks (C3B.lean:569, 619; X7.lean:521) — undefined in any
   sampled file, un-commented at use. Evidently the env-peel
   discharger (SegmentFaces §2b); a one-line comment at first use
   per file, or a name that reads as what it proves, is needed.
5. **The apartness ⇒ no-collision step.** The guard says fresh
   draws "stay below every static symbol hash (≥ 2^60)"
   (T5.lean:44-47); the fixture's hash literals are checkable by
   eye against 2^60, but WHERE the walk consumes `hscB`/`hexcB` to
   avert capture — the actual collision-freedom argument the T4
   diagnosis made load-bearing — is invisible from the fixture
   text. A pointer from the guard definition to the one lemma that
   consumes it would close the loop.

---

## 4. Grades

| File | (a) Statement | (b) Structure | (c) Leakage | Overall |
|---|---|---|---|---|
| Segment.lean (rules; graded as (d)) | — | — | — | **A-** |
| Threaded.lean (statement forms) | A | — | A | **A** |
| T5.lean (+ engine context) | A | A- | B- | **B+** |
| T7.lean | A | A- | B- | **B+** |
| T6Probe.lean | A | B (headline A) | C | **C+** |
| C3B.lean | A- | B+ | C+ | **B-** |
| X7.lean | A- | B+ | C+ | **B-** |
| E4.lean | A | B | C+ | **B-** |

**Overall: PASS-WITH-FINDINGS** against the operator's test. The
reasoning style is interpretable: statements are readable cold, the
rules are a legible and honestly-cited program logic, simple
programs end in spec + auto, and loop proofs visibly carry the
Floyd shape. It is not yet CLEAN: the corpus reader pays a
~5:1 boilerplate tax per fixture, the "invariant" vocabulary
overclaims for concrete-input programs, and a specific list of
engine identifiers (builders, spelling tables, fuel literals,
hash literals, projection walls, `fencing` clauses) still sits in
what a reader must scroll through.

## 5. Top 3 improvements, ranked by legibility-per-effort

1. **Mint the harness spine and builders.** k1_o…k9_o, the
   address/errno facts, memArgAlloc…memD3, mkRdy/mkLH, and the
   alignment rfls are byte-identical across T6/E4/X7/C3B modulo
   (file, fname, symbol, arg). One command (`derive_harness_spine
   c3bFile "lead_digit" symN (intValue 273)`) deletes ~300 lines
   per fixture — at breadth (a thousand programs) this is the
   whole ballgame, and the SegmentFaces header already registers
   engine-side minting as the arc-19 frontier. Highest value,
   fully stereotyped, zero new theory.
2. **Make the invariant declaration carry the values, and derive
   the rest.** `at_` should state the human content (`values k`,
   with the readable equalities: n ↦ 27 then 2; s = triF k, i = k);
   the state family, the spelling table (defaulted equal, seam
   auto-detected), and the alignment lemmas become derived/minted
   objects. Simultaneously either make `InvMap.find?` load-bearing
   in `while_inv` or drop the map. This converts the sample's
   central conceptual finding (§2.2) into the layer's central
   advertisement, at modest cost.
3. **Absorb the discharge plumbing into one tactic and name the
   numerals.** A `seg_obligation` step that instantiates a
   registered chain at a family member (applying the alignment,
   projecting components, and closing the `hscB`-style bound goals
   via the named `supplyCeil`) empties the 30-line case walls in
   seg_body0/seg_exit/StAlign across every fixture; `supplyCeil`
   (or `2^60`) replaces `1152921504606846976` in every guard and
   side goal. Cheaper than 1 and 2; do it first if sequencing by
   effort.

(Runner-up, larger effort: the thin assertion record over
points-to/alloc/pure that elaborates to BPack and the
`derive_rounds` hypothesis lists — §2.3. It is the right end state
but costs real design; 1-3 are harvestable now.)

## 6. Sharpest single criticism

The corpus files' "ONE declared invariant — the one human artifact"
is, formally, no artifact at all: `at_ k := compOf (walk-endpoint
k)` defines the invariant as "whatever state the run reached", the
map lookup that supposedly pins it is a dead `_hfind`, and the
actual human content — 273, 27, 2 — exists only in comments. The
machinery is sound and the presentation layer is genuinely close,
but until the declaration states values and the map is load-bearing,
the Floyd/RefinedC vocabulary on the corpus tier is a costume worn
by symbolic evaluation — and a grumpy professor will say so in
public. T5 proves the costume fits the real garment; make the
corpus wear it.
