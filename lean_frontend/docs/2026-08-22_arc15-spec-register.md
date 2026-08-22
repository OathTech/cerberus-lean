# Arc 15 — THE SPEC-STYLE REGISTER

Status: OPEN (stub created at S0 scaffold; entries begin at S1).
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
