# Arc 15 — THE SPEC-STYLE REGISTER

Status: CLOSED at S5 (2026-08-23) — final-verdict summary below;
entries S1-E1 … S5-E5 are the record.

## S5 SUMMARY HEAD — the spec-style final verdicts

| Question the lab asked | Verdict (normative for the template) | Evidence |
|---|---|---|
| Readback form | **Form 1 (expected-array + mismatch-index) DEFAULT at every rung**; Form 2 (stdout) kept as diagnostic/witness variant (value grows with structure size; costs unchanged: libc mode + the newline-buffering discipline); boolean verdict legitimate only for genuinely boolean properties, strictly dominated elsewhere | S1-E1, S2-E5, S3-E1, S4 §d |
| Headline quantifier | **model-∀** ([USER] ruling confirmed), with the stream-∀ face STATED (it is what fuzz/replay exercises) and a kernel bridge between them | S1-E2, every rung's `*_sample_model_iff_stream` |
| Codec contract | codecs ship **BOTH laws from day one** (`RoundTrip` + `Canonical`) — the operational-validity bridge needs both; adopted S2, completed to u64 at S5 | S1-E2, S2, S5 |
| Bytes vs structure | **verbatim byte-blaster for buffer-contents properties** (containment story); a structured codec only when the TARGET's contract is structure-level (R3+) | S2-E1 |
| Term pinning | **parametric digit-run zip wherever ≥ 3 instances** (zero marginal cost per sample; derived expected[] is structural — at S5 through a permutation); verbatim pinning the floor for 1-2-instance targets; instance selection deliberate (tie-break rule; derive bytes from the pure encoder, never by hand) | S1-E5, S2-E4, S3-E6, S5 |
| Mutating-structure statements | **full readback equality IN THE STATEMENT; locus/frame decomposition in the pure layer** (proved once per model, the Iris-side framing shape; adds no statement strength) | S4-E1 |
| Plant discipline | predicted indexes from the pure mirror; **blind spots documented + demonstrated green** (and kernel-CHARACTERIZED when cheap — S5's closed-form blind set); malformed-stream arms make every splice a defined program; **plants split by leak class where the shape admits** (broken-leak-free vs broken-leaking) | S2-E5, S3-E5, S4-E5, S5-E2 |
| Wf honesty | closed-program `Wf` surfaces the WHOLE realizable domain (incl. UB corners CN's requires leaves implicit — the R1 finding); capacity ceilings are honest realization bounds, labeled; a full-domain model (S5 swap) makes Wf vacuous and the bridge hypothesis-free | S1-E3, S2-E3, S5 |
| Leak conjunct | outcome-level scalar (final allocation count vs measured driver baseline), LIVE since R3, plant-separating since R4; the oracle-differential leg is the one open limb (priced S, fork-side) | S3, S4-E5 |
| Statement scaling | pinned program terms are **trees of defs** (the hoisting emitter owns chunking); multi-decl TUs pin **per-TU** (symbol-numbering coupling); harness C dialect choices are differential-budget choices (the sequenced-call rule) | S2-E6, S3-E6, S4-E2/E3 |
| Corpus reach | five rungs, six of seven targets straight from deps/cn with specs quoted verbatim; ONE fidelity gap found (CoreParser enum-ctype literal — the pinning path only; exec pipelines carry enums fine), parked priced | S5-E4 |

Charter success criterion 2 (every experiment recorded with verdict
+ reason, abandonments included) — met; the abandoned/parked set is:
file-scope static arrays (S1-E4, documented deviation), Form 2 at
R2/R5 (deliberate skips, recorded), the lookup pinned layer (S5-E4,
parked on a registered gap), structural tree shrinking (S4, byte
shrinker never fired).

Original register header follows (the entry format + running
entries, unchanged).

Charter: `2026-08-22_arc15-spec-lab-charter.md` — this register is the
arc's primary product: a dated record of what fit together, what
fought, and why. Every experiment — including abandoned ones — gets an
entry with a verdict and a reason; silent deletion is forbidden.

Entry format (per experiment):
  * Rung / target / date / worker
  * Styles compared (e.g. Form 1 expected-array vs Form 2 stdout vs
    boolean verdict; model-∀ vs stream-∀ headline)
  * Verdict + reason (kept / abandoned / parked), with the concrete
    objects (theorem names, harness files) cited
  * Register-worthy friction (what fought the template)

## Entries

### S1-E1 — Form 1 (mismatch-index) vs Form 1b (boolean) vs Form 2
(stdout), same property, side by side

Rung/target/date/worker: R1, deps/cn division.c + mod.c,
2026-08-22, [AGENT:arc15-laneA-S1].
Objects: `SpecLab/DivModHarness.lean` (`divmodForm1Template` /
`divmodForm1bTemplate` / `divmodForm2Template` + plant twins);
sweeps: form1 155/155, form1b 155/155, form2 8/8 (libc), plants all
RED (S1 record, verbatim).

Verdict: **Form 1 KEPT as default** (confirming the template note),
Form 1b **legitimate but strictly dominated at this rung**, Form 2
**kept as a diagnostic variant**, with findings:

* Debuggability: the plant demonstration separates them cleanly.
  Form 1 plant returns `Specified(1)` = "first divergence at
  quotient byte 0" — the index alone localized the broken operator.
  Form 1b returns bare `Specified(1)` = "something differs". Form 2's
  plant shows THE WITNESS ITSELF in the observable
  (`stdout: "014,000,..."` vs predicted `"003,000,..."` — you can
  read 7*2=14 off the transcript). Ranking for fault localization:
  Form 2 > Form 1 > Form 1b.
* Vacuity resistance: equal at the statement level (all three
  compare against pure-side-computed expectations; the verdict-
  exclusivity lemma `SpecLabProofs.harnessRunsTo_exclusive` covers
  the Form 1/1b shape). But Form 1b's single bit gives the plant
  test less to PIN (predicted index vs predicted bit) — a silent
  comparator bug that always returns 1-on-any-mismatch-at-wrong-
  position would pass Form 1b's plant and fail Form 1's.
* Cost: Form 2 costs libc mode (slower runs, bigger trust surface:
  libc.co + stdio) AND carries a REAL SUBTLETY FOUND BY THE LANE:
  cerberus's stdout is line-buffered with no exit flush — the first
  Form 2 run produced EMPTY stdout on both pipelines (8/8 red); the
  serialization must end in a newline, and the newline is part of
  the statement (`render3(expected) ++ "\n"`). A spec style whose
  observable depends on buffering discipline is a foot-gun at scale;
  fine as a diagnostic lane, wrong as the default.
* Differential ergonomics: Form 1's scalar verdict diffs in one
  token; Form 2's stdout needs string comparison but doubles as a
  human-readable log. Both lanes agreed byte-identically throughout.

### S1-E2 — model-∀ headline vs stream-∀ lemma (the bridge priced)

Objects: `DivMod.model_forall_iff_stream_forall` (i32, abstract exec
predicate), `DivMod.sample_model_iff_stream` +
`DivMod.fileOfStream_encode` (i8, real exec statements over the
4-stream sample set) — all kernel-checked, cones in SpecLabAudit.

Verdict: **model-∀ as headline confirmed** ([USER] ruling stands);
the stream-∀ face is worth STATING because it is what the fuzz/replay
lane actually exercises. THE MEASURED BRIDGE COST (the experiment's
real finding): with the OPERATIONAL validity form
(`ValidStream s := decodeInput s = some (m, []) ∧ Wf m` — what a
fuzzer checks), the bridge needs BOTH codec canonicity halves:
`decode∘encode = id` (the S0 round-trip contract) for stream→model,
AND `encode∘decode = id` on consumed prefixes (`toU32_ofU32`,
`encode_decode_u32le/_input` — NOT in the S0 contract) for
model→stream. The trivial validity form (`∃ m, s = encodeInput m`)
makes the bridge a tautology but pushes the same proof burden into
every consumer. RECOMMENDATION for the idiom library: codecs should
ship BOTH laws (`RoundTrip` + a `Canonical` contract) from the
start; the second half was ~90 lines of the S1 codec work.

### S1-E3 — Wf honesty vs the CN spec (comparison-column entry)

CN's `division` requires only `y != 0i32`; our closed-program `Wf`
must ALSO exclude `x = INT_MIN ∧ y = -1` (C11 6.5.5p6 — the
elaborated `catch_exceptional_condition` guard makes the instance a
UB program otherwise, which harnesses-are-programs forbids). CN
discharges that corner through its own UB side-conditions, not the
`requires`. Honest comparison: modular contracts state LESS in
`requires` because the verifier carries UB obligations implicitly;
closed-program observation must surface the whole domain in `Wf`.
Recorded as the standing shape of the CN-vs-us column (charter S5).

### S1-E4 — the kernel-instance template family (Form 1u-i8)

Experiments inside the template, all kept, with measured grounds:

* LOOP-FREE UNROLLING (vs the looped production template): oracle
  `--pp=core` sizes, derived: looped-i32 harness 2866 lines; hand
  unrolled i32 probe 1263; **unrolled i8 kernel instance 1262
  (mkHarness form)** vs arc-7 slate fixtures t2=76 / t5=172. The
  loop-free i8 reduction is what keeps a concrete kernel walk
  conceivable at all; the looped template stays the
  differential/production form.
* BLOCK-SCOPE const arrays (vs the design note's file-scope
  `static`): keeps the pinned file's `globs = []`, so the statement
  file term stays in the arc-7 slate shape (the drive prefix walks
  like the T1/T5 prefixes). ABANDONED: file-scope static variant
  (first cut) — globals-init emission + a novel driver_globals walk
  surface for zero statement value. Register rule satisfied: the
  deviation is documented in `i8PreTail`'s docstring.
* i16le RESULT ENCODING (2 bytes per result, vs 1): the i8 family's
  quotient reaches 128 (`(-128)/(-1)`); a 1-byte observation is
  mod-256 and `-128 ≡ 128` collide — the statement would be weaker
  than it reads. The 4-byte expected[] keeps byte-equality ⟺
  value-equality. (Same honesty class as the template note's
  digest-readback rejection.)

### S1-E5 — the parametric statement family (symbolic initializer at
statement level)

`DivModCore.mainParamDecl (c0 c1 e0 e1 e2 e3 : Int)` — ONE pinned
AST term, function of the six spliced literals, derived by the
emitter's digit-run zip over THREE pinned instances and pinned back
to all FOUR dumps (incl. the out-of-trio (-128,-1)) by
speclab-core-test. This is the template note's "instances differ
only in one array initializer" cashed out at the STATEMENT level:
`divmodI8File`/`divmodI8FileOf` quantify the program family without
per-instance modules. SUBTLETY (register-worthy): a two-instance
diff cannot disambiguate parameter sites whose values coincide in
both instances (e1/e3 both (0,255)); the third instance (-6,3) was
CHOSEN to break the tie — instance selection for parametric emission
is a small constraint-solving step, do it deliberately.

### S1-E6 — frictions / abandoned attempts (silent-deletion ban)

* Form 2 first cut: 8/8 RED with empty stdout both sides —
  diagnosed as line-buffering (see S1-E1), fixed by the trailing
  newline; kept. The initial red was the LANE working as designed:
  a model-vs-exec mismatch, not a differential one.
* speclab test-module prefix `Unit.*` collided with the root
  package's CerberusLeanTest lib (Lake resolves imports by
  root-module prefix — the arc-11 rehearsal finding, reproduced):
  shared speclab test modules renamed to `SLUnit.*`.
* The in-build audit twin could not live under `SpecLab/` — the
  grep floor word-bans the proof-layer root names it must SPELL; it
  is its own default-target lib (`SpecLabAudit.lean`), outside the
  scan scope, negative-tested in-build instead. No gate allowlist
  was amended (the governed-escape-hatch rule untouched).
* `mkHarness` attribution comment initially spelled the relsem path
  and tripped the grep floor (comment-insensitive by design);
  reworded. Cheap reminder that grep gates constrain PROSE too.

### S2-E1 — byte-blaster vs structured codec for the same array
property (the containment-story experiment)

Rung/target/date/worker: R2, deps/cn memcpy.c + get_from_arr.c,
2026-08-22, [AGENT:arc15-laneA-S2].
Objects: `SpecLab/ByteArr.lean` §structured-face experiment
(`bytesOfU16s`, `encodeElems_u16_flatten`,
`structured_forall_of_byte_forall`) vs the byte-blaster main line
(`encodeInput` = u16le count + bytes VERBATIM,
`Codec.encodeElems_u8_id`).

Verdict: **verbatim byte-blaster is the right containment idiom at
this rung; structured interpretation bought NOTHING.** The measured
grounds: the structured (u16-element) model-∀ is an INSTANCE of the
byte model-∀ — the subsumption theorem's entire proof is
`fun ws hw => h _ hw` — while going the other way would surrender
odd lengths and non-canonical element boundaries (exactly the
attacker-controlled shapes the containment note cares about). A
structured codec earns its keep only when the TARGET's contract is
itself structure-level (R3's list nodes onward); for buffer-contents
properties, bytes are the statement vocabulary. Supporting law: the
byte-blaster's element layer is the identity (`encodeElems_u8_id`)
— "copy the stream verbatim" is literally the codec.

### S2-E2 — mutator post-state readback vs read-only readback
(the first real post-STATE observation)

Objects: memcpy Form 1 (post-call dst AND src read back — the CN
`srcEnd == srcStart` clause is CHECKED, not assumed) vs getarr Form 1
(ret + post-array readback on a read-only target).

Verdict: **Form 1 on a mutated buffer works unchanged** — the
comparator does not care that the observation is post-state; the only
new ergonomic obligations were (a) the dst CANARY pre-fill (a
mutation-visibility floor: without it, an uninitialized dst readback
would be UB, and a no-op plant could alias garbage) and (b) putting
BOTH post-buffers in the observation so the frame clause (src
unchanged) is part of the same mismatch-index space. What this
teaches R3's builder/comparator: post-state readback generalizes by
CONCATENATING observation segments (prefix + segment layout beats
per-buffer verdicts — one index space localizes across buffers), and
canaries want to be template constants with a REGISTERED collision
blind spot (S2-E5) rather than per-instance values (which would
break the parametric-zip sharing).

### S2-E3 — CN-vs-us comparison column (R2 entries)

* memcpy: CN's requires/ensures are ownership + functional content
  (`srcEnd == srcStart`, `each k. dstEnd[k] == srcStart[k]`); our Wf
  adds what CN never states — the CAPACITY bound (length ≤ 16, the
  template's buffers) — because closed-program observation must
  realize the arrays it quantifies over. Modular contracts quantify
  n free; we pay a concrete-N ceiling (proof register S2-N) for
  runnability + differential grounding.
* get_from_arr: CN's `ensures` is OWNERSHIP-ONLY — it does not
  constrain the returned value at all. Our statement is STRICTLY
  STRONGER functionally (ret == arr[4] ∧ array unchanged, both
  checked bytes-for-bytes). Honest note both ways: CN could state
  the value trivially and chose not to (the file tests ownership
  machinery); but this is the first corpus point where the
  closed-program harness spec EXCEEDS the CN spec's functional
  content rather than mirroring it.

### S2-E4 — parametric zip with SHARED sites vs verbatim pinning;
the production/kernel-template unification

* The S1 production/kernel-instance split COLLAPSES at R2: the
  TARGET loops, so a loop-free harness buys no walk (T5 tech gates
  either way) — one looped block-scope template serves the
  differential lanes AND the pinned statements (memcpy_a..c pins are
  literally the sweep's programs). The S1-E4 block-scope rule
  reconfirmed (globs = [] on all 8 fixtures).
* memcpy's expected[] REPEATS choices[] (healthy dst' = src' =
  stream), so the 9 varying literal sites map to THREE parameters —
  the zip generalization (`zipParamWith`, coinciding sites share a
  parameter) makes the derived-ness of expected[] STRUCTURAL in the
  statement term: `memcpyMainParamDecl c0 c1 c2` cannot state a
  non-derived expected. Instance selection was trivial here (any
  three distinct byte triples); the S1-E5 tie-break lesson did not
  bite.
* getarr mains pinned VERBATIM (2 instances, no zip) as the
  contrasting style: cheaper to build (no table), but each new
  sample costs a full pinned decl (~250KB module text at this
  Core size) vs the parametric family's ZERO marginal cost per
  sample. Verdict: parametric-zip wins wherever ≥3 instances exist;
  verbatim pinning is the right floor for 1-2 instance targets.

### S2-E5 — plant blind spots, the malformed-stream arm, and
length-0 (documented-negative-space entries)

* The off-by-one plant is INVISIBLE at n = 0 (loop body empty both
  ways) and at bs[0] = canary (42); the wrong-index plant is
  invisible at bs[3] = bs[4]. All three blind spots are DOCUMENTED
  and demonstrated as green-with-predicted-0 twins in the --plant
  lane (pure-side `plantVerdict` predicts 0; both pipelines agree)
  — a plant lane that HIDES its blind spots is a vacuity risk of
  its own. Plant sample selection must avoid the blind set (lane
  uses bs[0] ∈ {1, 255}).
* Verdict space grew a MALFORMED arm (254): the harness is total on
  EVERY splice (prefix/capacity checks before any array access), so
  harnesses-are-programs holds for arbitrary raw streams, and the
  malformed twins are differentially exercised (4 cases, both
  pipelines 254).
* LENGTH 0 IS A LIVE INSTANCE, not an excluded case: the S0
  empty-initializer caveat is closed BY CODEC DESIGN — the u16le
  count prefix keeps both choices[] (`{0, 0}`) and expected[]
  (`{0, 0}`) nonempty at n = 0. Swept, fuzzed (fuzz draws length
  0..16), planted (blind-spot twin), and green both pipelines.
* Form 2 was deliberately NOT built at R2: S1-E1 already graded it
  a diagnostic variant (and found the trailing-newline discipline);
  R2 adds no new stdout-shaped question — skipping recorded here
  per the silent-deletion ban.

### S2-E6 — frictions (register-worthy)

* THE CODE-GENERATOR DEPTH WALL: the R2 pinned terms (memcpy main =
  1,920 Core lines) exceed Lean's code-generator recursion depth as
  single defs — the S1 emission style hit its ceiling one rung up.
  Budget bumps being banned (heartbeat doctrine; also this worker's
  scoping), the emitter grew a HOISTING pass: any Expr subterm over
  a NORMALIZED-length threshold (digit runs weigh 1, so decisions
  are literal-independent and the zip instances split identically)
  becomes its own def; composition is definitional; the gate's
  param pins re-flatten the composition and byte-compare against
  fresh parses. Divmod emission re-verified byte-identical
  (threshold ∞ path). This is the R2 statement-scaling finding: AT
  SCALE, PINNED TERMS ARE TREES OF DEFS, and the emitter owns the
  chunking.
* `i++` in harness loops surfaces `seq_rmw` in Core — one new
  emitter constructor (SeqRMW), loudly discovered per the fidelity
  contract.
* The generated module silences linter.unusedVariables (parametric
  helpers bind c0 c1 c2 uniformly; helpers without sites don't
  reference them) — cosmetic, generated-file-local, noted per the
  no-silent-config rule.

### S3-E1 — comparator-in-C vs serialize-then-judge-in-Lean, same
list property (the charter-named R3 head-to-head)

Rung/target/date/worker: R3, deps/cn append.c IntList_append,
2026-08-22, [AGENT:arc15-laneA-S3].
Objects: `appendTemplate` (Form 1: C comparator, verdict =
mismatch index) vs `appendForm2Template` (Form 2: C serializes the
walked result to stdout, the JUDGE is the Lean/pure side — statement
asserts `stdout = render3(expectedBytes m) ++ "\n"`). Lanes: Form 1
sweep 125/125 + fuzz 150; Form 2 6/6 byte-identical stdout (both
pipelines vs pure render).

Verdict: **Form 1 stays the default at the heap rung; Form 2's value
grows with structure size but its costs are unchanged.** Findings:

* Statement weight: Form 1's claim is one scalar (`Specified(0)`),
  with the shared comparator + `verdictOf_eq_zero_iff` carrying the
  equality meaning; Form 2's claim is a string equation whose RHS is
  a pure render — arguably the more direct "serialize-then-judge"
  reading (the C carries NO judgment at all, so the harness C is
  simpler: no expected[] consultation in the verdict path), but the
  trust surface grows (libc mode: libc.co + stdio + the S1-E1
  newline discipline).
* Localization: Form 1's index localizes in one token (elem plant →
  `Specified(3)` = element 0's low byte); Form 2 shows THE WITNESS
  (the whole serialized list, human-readable decimal) — at R3 sizes
  (14-66 obs bytes) that witness is genuinely readable in the batch
  log, which it wasn't for scalars. Diagnostic ranking unchanged
  from S1-E1 (Form 2 > Form 1 > boolean), default unchanged.
* The judge's location is the real axis: comparator-in-C keeps the
  differential observable tiny and nolibc; judge-in-Lean moves the
  comparison INTO the statement (good: less C to audit per family;
  bad: the stdout observable depends on libc buffering discipline).
  For the CN warm-up slate: Form 1 default, Form 2 as the diagnostic
  lane exactly as S1 graded it.

### S3-E2 — the builder/walker/comparator idiom trio + the
build-only harness (builder correctness as a program)

Objects: `buildPhases` / `walkSerialize` / `teardownResult`
(template-composable C fragments — ListAppendHarness composes all
five templates from them by plain `++` of literals), and
`buildOnlyTemplate` (builder + walker, NO call: `expected =
choices`, the builder-walker round trip through the heap made a
runnable program; pinned as `BuildOnlyStatement`, gate-checked
Specified(0) + leak-checked at baseline).

Verdict: **kept — the R3 idiom library shape.** The build-only
harness is the cheap trick of the rung: it turns "builder
correctness" (an obligation about heap states that the
statement-TCB rightly cannot mention) into an ordinary harness
statement (`expected[] = choices[]`), giving the builder its own
plant surface and its own leak conjunct with ZERO new statement
vocabulary. The walker's CAP GUARD (253 overlong arm) is what keeps
every plant variant total (a cyclic plant cannot hang the harness).
Register rule: the walk cap (16) and the 252 allocator-refusal arm
are model-side unreachable, documented as totality arms, exercised
never in healthy lanes (their absence from the sweep logs is by
design; the malformed lane exercises 254 on both pipelines).

### S3-E3 — the pointer-selection idiom prototype (the R4 on-ramp)

Objects: `appendAtTemplate` + `AtInput`/`atModelFn` (stream = u8
walk index k ++ the two-list layout; validity k < |xs|); lane `--at`
10/10 both pipelines (front/middle/back indexes, boundary heads,
k=7 deep walk).

Verdict: **the interior-pointer pattern works exactly as the
template note designed it** — choices select a PATH, the harness
walks its own built structure and hands the target the interior
pointer it arrives at; pointer VALUES never appear in the stream;
teardown partitions cleanly (k prefix nodes + the result walk, no
double-free because append reuses suffix nodes). Model face is
`drop k xs ++ ys` — pure, first-order. This is the R4 (tree
rotation, path-selected subtree argument) mechanism, prototyped
differentially; pinning it as a statement family is deliberately
deferred to R4 (where the path selection is the POINT of the rung).

### S3-E4 — CN-vs-us comparison column (R3 entry) + the corpus
walker gap

* IntList_append: CN's requires/ensures are the two IntList
  resources + `L3 == append(L1, L2)` — the postcondition IS a pure
  recursive function, and our model collapse (`modelFn = xs ++ ys`,
  `append_is_model = rfl`) mirrors it directly: the R3 comparison
  is the closest yet (CN's seq datatype ≅ List Int, CN's append ≅
  List.append). Our Wf again adds what CN never states: the
  capacity bounds (8/8, the closed-program realization ceiling) and
  the i32 range CN carries in its datatype (`i32 head`).
* What we state BEYOND CN at this rung: interpreter-only
  LEAK-FREEDOM (final allocation map at driver baseline after
  teardown). CN's ownership discipline makes leak-freedom implicit
  in the resource accounting (returning `take L3 = IntList(return)`
  means exactly the result's cells are owned); our closed-program
  form states it as an outcome-level scalar. Honest note: CN gets
  it per-function and modularly; we get it per-program and
  observably.
* CORPUS GAP (selection reasoning, recorded): deps/cn/tests/cn has
  NO read-only list walker with functional content (list_rev01's
  predicate yields only a length; reverse/mergesort are mutators).
  The read-only-walker slot of the R3 charter line is filled by the
  harness's own serializer (idiom library), not a corpus target.

### S3-E5 — plant signatures, blind spots, and the negative-space
arms (R3)

* STRUCTURAL breaks land in the LENGTH ARM: the wrong-link plant's
  serialized count diverges before any content index, so its
  verdict is 255 (not 1+i) — measured in the S3 probes and pinned.
  The register lesson: at heap rungs the mismatch-index space
  splits into a STRUCTURE signature (length arm) and a CONTENT
  signature (1+i), and plant prediction must model both
  (`linkPlantVerdict` returns 255 via the same shared verdictOf).
* Blind spots documented + demonstrated as predicted-green twins:
  wrong-link at xs = [] and |xs| = 1 (the singleton case makes
  `xs->tail = ys` CORRECT — a plant that is accidentally right, the
  sharpest vacuity trap of the rung); wrong-element at xs = [].
  Plant sample selection avoids the blind set (|xs| = 2, 3).
* The wrong-element plant uses `^ 1` (not `+ 1`): INT_MAX + 1 would
  make the plant a UB program — harnesses-are-programs binds PLANTS
  too. Pure face: `xorOne` (evens up, odds down, incl. negatives),
  `xorOne_inRange`, and `xorOne_ne` (the low wire byte always
  flips — the plant cannot hide behind the codec).
* Malformed arms (254) extended to the two-list layout: short first
  list, over-cap count, missing second prefix, trailing junk — all
  four differentially exercised.
* THE CAPACITY-CORNER CATCH (lane working as designed): the first
  build-only sweep went red at (8,8) — a real out[] overrun (66 <
  68 build-only observation bytes), caught because the sweep
  includes the capacity corner; both pipelines refused
  identically. Fixed (out[68]); the S2-E5 lesson (sweep the
  corners) re-confirmed with a live catch.

### S3-E6 — frictions (register-worthy)

* SYMBOL-NUMBERING COUPLING: a TU's fresh symbol numbers depend on
  the WHOLE TU — the build-only main's different structure shifts
  the (textually identical) target's internal symbols, so the
  build-only dump's target must be pinned from ITS OWN dump
  (`intListAppendBuildDecl`), and cross-dump target-identity
  assertions hold only across structurally identical mains
  (a/b/d/c). Pinning multi-decl TUs = pinning per-TU, not per-decl.
* The R3 dumps reach `all_values_representable_in` (pointer
  conversion checks) — not in the divmod std closure; discovered by
  the loud unknown-function error, added to the pinned closure
  (+ malloc_proxy/free_proxy). The fail-closed closure discipline
  worked as designed.
* AMBIENT TAG STATE: the first speclab rung with structs hits the
  with_tagDefs boundary — the gate exe must install
  `CerbTags.setTagDefsIO f.tagDefs` before running (Main.lean
  set/reset pattern; relsem T4 precedent). The STATEMENTS are
  unaffected (the axiom is part of the declared boundary; cones
  unchanged).
* VALUE-aliasing vs POINTER-aliasing honesty: the sweep's ys = xs
  shapes are value-aliasing only — the two-builder codec CANNOT
  express pointer aliasing (xs and ys sharing nodes), which is a
  REAL gap vs CN's separation discipline (where non-aliasing is a
  resource fact, and aliased calls are simply outside the spec).
  Register note for the escape-hatch ledger: aliased-input append
  is UB-adjacent territory the harness family deliberately does not
  quantify over.
* My first d/b instance byte patterns were mis-derived by hand
  (hex arithmetic); the zip's unknown-triple error caught both
  instantly. Instance selection for parametric emission remains "do
  it deliberately" (S1-E5), now with: derive the bytes from the
  pure encoder, never by hand.

### S4-E1 — "rest of the tree unchanged", stated two ways (the
rotation-specific spec question)

Rung/target/date/worker: R4, rotate_right (fresh authorship),
2026-08-23, [AGENT:arc15-laneA-S4].
Objects: Way 1 = the Form 1 statement family (observation =
`encodeTree (rotateAt tree path)`, full-tree readback equality —
`RotateSampleStatement` and friends); Way 2 = the kernel decomposition
pair `TreeRot.rotateAt_as_replace` (rotation = replace the locus
subtree by its rotation — unconditional, off-shape both sides
identity) + `TreeRot.rotateAt_frame` (every subtree on a path
DIVERGING from the rotation path is untouched — the frame clause as a
pure theorem over `subtreeAt`), ~63 code lines, cones [propext] /
[propext, Quot.sound].

Verdict: **Way 1 stays THE STATEMENT; Way 2 is pure-layer/proof
vocabulary — and that division is exactly right.** Grounds:

* Way 1 keeps the observation-channel discipline intact: one wire
  vocabulary, one mismatch-index space (the S2-E2 lesson), zero locus
  vocabulary in the statement, and the statement never mentions
  memory. It is also what the differential/fuzz lanes actually run.
* Way 2 as a STATEMENT would need `subtreeAt`/`replaceAt` in
  statement vocabulary plus a ∀ over diverging paths — heavier to
  read, and its frame half asserts nothing the full readback doesn't
  already imply (kernel-checked: the decomposition is DERIVABLE from
  the model, so stating it buys no strength, only surface).
* Way 2 reads BETTER as the human explanation of what rotation does
  ("the locus rotates, the remainder is untouched") and as future
  proof machinery — `rotateAt_frame` is precisely the shape a
  representation-predicate/framing proof (P2, Iris party in the back)
  wants, and CN-style modular contracts get it for free from
  ownership. Register rule for the template note: full readback in
  the statement; locus/frame decomposition in the pure layer, proved
  once per modelFn.

### S4-E2 — THE SEQUENCED-CALL RULE (exhaustive-mode ND economy;
measured, idiom-library rule)

The FIRST R4 instance blew a 120s oracle timeout at 6 nodes. Bisect
(verbatim counts): a single `*link = rotate_right(*link);` statement
makes the oracle's exhaustive mode enumerate 3 EXECUTIONS (the
assignment's LHS lvalue walk is unsequenced with the RHS call); the
leaf-tree harness showed 3 executions from that one site, and the
per-site factor compounds — the 6-node instance never finished.
Landing the call in a plain local first
(`newsub = rotate_right(*link); *link = newsub;`) restores ONE
execution; the fixed 6-node instance runs in 0.07s oracle-side. Same
class inside the builder: `t->left = build_tree(...)` became
`lch = build_tree(...); t->left = lch;`.

RULE (harness idiom library): a call result always lands in a plain
local before any member/deref store. Member stores whose RHS is a
simple load (`t->left = l->right`) are FINE (measured — the TARGET C
stays boring and untouched). The S3 append harness complied BY
ACCIDENT (its C99 initializer style `struct int_list *new_tail =
IntList_append(...)` is exactly the landed-local form); R4's C89
declaration style exposed the trap. Register-worthy consequence: the
harness template's C dialect choices are DIFFERENTIAL-BUDGET choices,
not style.

### S4-E3 — the recursive idiom trio + per-TU pinning at six procs
(the template's demonstration-of-completeness rung)

* The R3 in-main iterative builder/walker does not extend to trees;
  the R4 trio is RECURSIVE HELPER PROCEDURES (scan_tree /
  build_tree / serialize_tree / free_tree) — the first speclab
  harness with procs beyond target+main. The S3
  validate-before-build discipline survives recursion (scan_tree
  allocates nothing; malformed input never allocates), and the
  serializer's cap guard (253 arm) now doubles as CYCLE protection —
  a cycle-creating target variant is counted out at 32 nodes, never
  a hang, and teardown runs only on serializer-validated trees.
* The S3 symbol-numbering-coupling finding bites PER HELPER: the
  root/deep/build TUs (structurally different mains) are pinned
  WHOLE from their own dumps — 6 decls each, `TUSyms` symbol sets
  per TU in the file assembly; the plant TUs share the healthy
  helper numbering (byte-identical, ASSERTED at emission with a loud
  error). Cost of a verbatim path instance: ~6 pinned decls ≈ 600
  module lines; the module is 2.5k lines / 6.0 MB, ~90 s capped
  compile — the S2-E6 "pinned terms are trees of defs" finding now
  at TU scale.
* THE POINTER-SELECTION STATEMENT FAMILY (S3-E3 promoted): the path
  is model + stream data (`Input.path`, in-stream after the tree
  code); the parametric family carries its path in choices[], and
  `RotatePathSampleStatement` pins two further paths (root [],
  depth-2 [l,l]) as verbatim instances — path selection is now
  statement-level, not harness configuration. The C mechanism is the
  parent-link walk (`struct node **link`), handing the target the
  interior pointer and storing the returned subtree root back
  through the link exactly as a real caller would.
* Documented deviation (S1-E4 register rule): the spliced arrays are
  block-scope but NOT `const` this rung — helper procs take
  `unsigned char *`, and a const-qualified pointee would drag
  pointer-to-const qualifiers into hand-pinned funinfo for zero
  statement value; nothing writes the arrays.

### S4-E4 — fresh authorship + the CN comparison column (R4 entry)

* CORPUS REASONING (recorded per the charter): deps/cn/tests/cn has
  NO rotation target (searched 2026-08-23: zero `rotate` hits; the
  tree family is tree_rev01.c — a mirror mutator on
  `struct tree_node {int v; *left; *right}` — and tree16/* 16-ary
  trees). rotate_right is therefore FRESH AUTHORSHIP (the operator's
  worked example); the struct shape follows the corpus
  int-binary-tree reference (tree_rev01.c), per the charter's shape
  note. The harness header records an informal CN-style contract
  (`requires take T = Tree(t); ensures take T2 = Tree(return);
  T2 == rotate_right_spec(T)`) as the comparison-column anchor.
* The CN-vs-us column therefore INVERTS at this rung: there is no CN
  spec to mirror — the harness statement IS the only spec, and the
  things R1-R3 recorded as "beyond CN" (capacity Wf, leak conjunct,
  closed-program observation) are here the whole story. What a CN
  treatment would add back: shape-parametric ∀ via the Tree
  predicate's recursion (our registered wall) and modular framing
  (our Way-2 pure lemmas).

### S4-E5 — plant signatures: THE LEAK-CLASS SEPARATION

* The two charter plants split the failure space on BOTH observables
  for the first time: the WRONG-CHILD-SWAP plant is a content/
  structure break with NO leak (verdict 7 = the locus val's first
  wire byte; final allocations = baseline — `swapPlant_size` is the
  pure face), while the DROPPED-SUBTREE plant is a structural break
  in the 255 length arm AND leaks exactly the orphaned middle
  subtree (baseline + 1 at the pinned instance; `dropPlant_size` /
  `orphanedAt`). A verdict-only harness family could not tell a
  leak-free break from a leaking one — the leak conjunct's value is
  DEMONSTRATED, not asserted.
* Blind spots documented + demonstrated as predicted-green twins:
  swap at the self-similar locus `node a (node a L L) L` (swap =
  rotation there — kernel-checkable coincidence class) and at every
  off-shape locus (both plants keep the target's guards); drop when
  the locus's `l->right` is already null (`t->left = 0` IS the
  healthy assignment) and at off-shape paths. Plant sample selection
  avoids the blind set; the blind spots ride the --plant lane as
  green twins per the S2-E5 rule.
* Malformed arms extended to the recursive code: truncated children,
  bad presence byte, missing path count, path over cap, bad path
  bit, trailing junk, and the 32-node over-capacity spine — all at
  254, both pipelines, no allocation (scan-before-build).

### S4-E6 — frictions (register-worthy)

* THE CAPACITY CORNER WAS INITIALLY FAKE: `completeT 4` is a
  4-LEVEL tree (15 nodes), not the 31-node cap — a levels-vs-edges
  confusion; caught during probing when the longest sweep sample
  printed only 15 nodes. Fixed to `completeT 5` (= exactly capN =
  31 nodes, depth-4-in-edges, with a depth-4 path). The S3-E5
  "sweep the corners" lesson now has a corollary: VERIFY the corner
  is the corner (the sweep set's max should be computed against the
  cap, not assumed).
* `emitTreeTU` first emitted `{pfx}MainSym` twice (explicitly + via
  emitDeclH) — caught by Lean's duplicate-declaration error at
  first compile; harmless class, but a reminder that the emitter's
  per-TU plan composes helper emitters that each own their naming.
* Sandbox note re-confirmed: /tmp is write-only under the nono
  profile (S0 note); scratch stays under the worktree
  (`.s4-probes/`, deleted before the batch-3 commit).

### S5-E1 — the amortization measurement (the seed rung's primary
deliverable)

Rung/target/date/worker: R5, deps/cn swap_pair.c + cn_inline.c
lookup_size_shift, 2026-08-23, [AGENT:arc15-laneA-S5].
Objects: the whole `SpecLab/CnSeed*` family + `test_speclab_seed.sh`;
measurement detail in the S5 record.

Verdict: **a new CN target is now a ~half-hour, zero-new-idiom
exercise.** Measured: BOTH targets — probes to committed
green-battery batch — in 31.5 min wall (timestamps in-session),
with ZERO new codec definitions, ZERO new harness idioms, ZERO new
pp surfaces (one impl-constant table row), the S2 comparator law and
S1 refutation schema consumed as-is (the schema's fourth
rung-independent transfer at 8 lines), and the 16-param zip table
costing 3 lines. The un-amortized remainder: per-target harness C
(~60 lines each, line-for-line adaptations), funinfo/closure pinning
(one new std decl + the first impl0 entry), fixture dumps. Compare:
R1-R4 were full slices of 3 batches each. The library thesis of the
charter — the ladder pays for the corpus — is MEASURED, not argued.

### S5-E2 — the kernel-characterized plant blind set (a new plant
grade)

Objects: `CnSeed.swapPlant_blind_iff` (verdict 0 ⟺ a = b; 11 lines
via `ByteArr.verdictOf_eq_zero_iff` + u64 wire injectivity), the
`--plant` diagonal twin.

Verdict: **where the blind set has a closed form, prove it.** The
S2-E5 rule (document + demonstrate blind spots) gets a third grade
above "demonstrated": CHARACTERIZED — the plant's discriminating
power is itself a kernel theorem, so plant-sample selection is
provably outside the blind set rather than believed so. Cheap here
because the comparator law reduces it to codec injectivity; worth
attempting wherever that reduction exists (byte-image models).

### S5-E3 — CN-vs-us comparison column (R5 entries)

Full treatment in `2026-08-23_arc15-s5-cn-comparison.md` §3.5. Register
kernel: swap_pair's `ensures` is functional post-state content and
collapses to `⟨rfl, rfl⟩` on the model (collapse datapoint 4); our
Wf is VACUOUS (full u64 domain) where CN still needs ownership
`requires`; CN's `/*@ trusted; @*/` main is exactly the closed
program we check. lookup's `cn_function` is the modelFn idea with
the arrow REVERSED (CN derives the spec function from the body and
trusts the translation; we author the model independently and check
it by execution — different trust shapes, both stated); cn_inline's
second contract (`f: return < 1000`) has a one-`decide` pure mirror
(`f_model_lt_1000`), collapse datapoint 5.

### S5-E4 — THE COREPARSER ENUM-CTYPE GAP (the rung's finding;
parked-priced)

Objects: tests/speclab/lookup_*.core (committed reproducers), the
minimal repro pair in the S5 record (switch-only parses; + enum
parameter refuses: `parse error: offset 0: expected 'builtin', got
'proc'` — the ctype-literal grammar has no `enum TAG` arm).

Verdict: **the first corpus construct whose oracle dump the pinning
path cannot re-parse is C's most ordinary enum** — surfaced by
instantiating real corpus code, invisible to every prior lane (the
cabs-json exec path carries enums natively; lookup's differential
lanes are all green, incl. non-enumerator values through the
int→enum conversion). Disposition per park-don't-improvise
(CoreParser.lean is semantics surface, outside the S5 worker's write
scope; the S3 leak-oracle-leg precedent): lookup's pinned statement
layer is PARKED, its lanes stay green, the fixtures + the 2-param
zip plan stay committed. PRICE S (a ctype-grammar arm + re-run the
emitter). The lab's purpose realized: gaps found by real code, filed
with reproducers and prices.

### S5-E5 — frictions (register-worthy)

* The swap dumps' `wrapI_add`/`wrapI_mul`/
  `catch_exceptional_condition_*` tokens are BUILT-IN pexpr forms
  (PEwrapI/PEcatch…, parsed by suffix), NOT std.core calls — a
  10-minute false trail during the unknown-function chase; the real
  missing decl was `ctype_width` (u64 shift bound checks). Noted so
  the next closure chase greps the parser's special forms first.
* FIRST NONEMPTY impl0 in a pinned family: `<bits_in_byte> = 8`
  (ctype_width's multiplier), hand-pinned from the gcc LP64 impl
  file, behaviorally gated — the T1File-era "impl0 := fmapEmpty"
  convention ends at R5; future rungs touching width-generic std
  code should expect impl closure entries.
* The junk expected-splice convention (`junkExpected`, S2) bit once
  more: an empty `expected[]` fallback renders `{ }` — invalid C
  pre-C23 (the S0 caveat); the raw-stream lane caught it on first
  run. The convention is now uniform across all five rungs.
* Naming collision avoided by prefix: TreeRot already owns
  `SwapPlant*` names (its wrong-child-swap plant); the R5 pair-swap
  family uses `pairSwap*`/`CnSeed.Swap*` namespacing — cross-rung
  name hygiene is now a real concern at five rungs and worth a
  convention row in any future speclab style note.
