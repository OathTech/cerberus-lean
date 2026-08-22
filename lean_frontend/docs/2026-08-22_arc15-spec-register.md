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
