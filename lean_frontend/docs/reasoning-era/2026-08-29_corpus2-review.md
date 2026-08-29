# Corpus-2 review — adversarial professor pass (step 3)

Date: 2026-08-29. Author: [AGENT] adversarial reviewer (fresh eyes; did
not author corpus-2; same role that reviewed corpus-1). READ-ONLY pass,
no Lean builds; oracle runs used as permitted; single write target =
this file. Instruments: the design catechism (§II canonical property,
§III forbidden list incl. the anti-brute-force corollary), the corpus-1
review's dishonest-pass instrument (notes/2026-08-27_target-corpus-
review.md), the frozen corpus-1 discipline, the capability roadmap's
construct table (notes/2026-08-29_capability-roadmap.md §1b), and the
pre-registered uri.c census (lean_frontend/docs/2026-08-27_arc18-r6-
uri-census.md). Under review: notes/2026-08-29_corpus2-draft.md +
notes/corpus2-draft/p16..p23 + the Part-2 shakeout campaign.

Evidence gathered by me, not taken from the draft:

- **Oracle re-runs, all 8** [AGENT, this session, house recipe
  `--exec --batch --nolibc`]: p16–p23 each produced
  `Defined {value: "Specified(0)"}` — the draft's 8/8 claim is
  independently REPRODUCED (not just spot-checked; all eight ran in
  seconds). The corpus-1 H5 disease (unexecuted samples) is absent.
- **Core elaboration inspections** [AGENT, `--pp=core --nolibc`]:
  p16 — `save unwind`/`save fail` are single-text labels; `run fail`
  and `run unwind` sites exist; `fail` genuinely has two in-edges
  (direct `run fail(acc)` + fall-through out of `unwind`'s body into
  the `save fail` block). No tail duplication: the join topology the
  draft claims is real in the elaborated Core.
  p20 — the switch elaborates to an if-dispatch ladder
  (`if c=2 run case_661 …`) + per-case `save` blocks + a `break_653`
  label; case_661's body falls through into `save case_660` with no
  intervening `run break`. **No Ecase/PEcase appears anywhere** (see
  finding C2).
  p17 — `memop(IntFromPtr, …)`, `memop(PtrFromInt, …)`,
  `memop(PtrValidForDeref, …)` all present on the only path: the
  claimed cast-memop vocabulary is real and unavoidable.
  p23 — 10 `unseq` nodes; the two `store`s to a and b sit INSIDE the
  two arms of the outer `unseq` (weak-sequenced within arms,
  unsequenced across): genuine unsequenced side effects on distinct
  objects, exactly as claimed. G8 is not a costume.
  p21 — `member_shift(_, uv, .i/.u)` on a union-typed object +
  union-typed create/store/kill. p22 — `Cfunction` values,
  `cfunction()` memop, `ccall` through a loaded pointer value. p19 —
  a real `glob calls: pointer` section entry.
- **Hand simulation**: all 8 main() samples and all 8 theorem
  statements checked at domain boundaries (overflow, INT_MIN edges,
  the p21 conversion range, p22's x+x = INT_MIN exactly-representable
  case, p23's derived 536870910). **No false theorem, no UB hole, no
  wrong sample was found.** This is a materially cleaner draft than
  corpus-1 v1 was at the same stage.

---

## 0. Verdict

**REVISE-THEN-FREEZE.** No program is rejected; no theorem is false;
no sample is wrong; every bound passes the anti-brute-force test
(smallest domain p23 ~2^30, derived from type limits — well past the
corpus-1 gray zone); no ∀ is a finite-sample costume; the exclusions
are genuine adjudications with named triggers; the census boundary
(compositions → capstone) is drawn honestly. The required revisions
are honesty/precision fixes to claims and in-file notes — statement
and documentation changes only, no gates (the anti-gate-grind ruling
applied throughout), no redesigns. The complete list is §4; with it
applied, freeze all 8.

Where it is right, plainly: the corpus-1 lessons were applied by
execution, not claim — samples run (and re-run by me), constants
derived, the all-scalar-input/no-splice design choice eliminates the
entire H9 (wf-degeneration) class at a stroke, and the uri.c-vs-kernel
priority split in §1 is exactly the honest instrument the hunt needed.
p17 and p23 are the strongest rows: both verified at the Core level to
force precisely the vocabulary they claim.

## 1. Dishonest-pass findings (the headline attack)

### C1 — p16/p20: join-ONCE is exercised, not forced; the
"P09-class illegitimate move" framing is wrong in kind

The topology is real (verified above): `fail` is one shared text with
two predecessors. But the dishonest-pass claim ("per-path inlining of
labels would be the P09-class illegitimate move", p16 header; draft
§3) does not survive scrutiny. A proof may step through the shared
label body once per path — 2 visits to a 2-statement body. That cost
is proportional to program structure (paths × label-body size), which
is precisely what catechism §IV.1 permits; it is NOT the P09 move.
P09's inlining dodges a CALL CONTRACT — the V4 deliverable; per-path
label stepping dodges nothing the catechism names. What p16 genuinely
forces: the general-label vocabulary itself (Erun to a non-loop
parameterized label; fall-through ENTRY into a save block — a shape
the loop layer's back-edge labels never produced). What it does not
force: proving the label continuation ONCE and consuming it at both
predecessors (the amortizing segment-rule style). At 2 predecessors
with a trivial body, nothing can force that — the forcing arrives at
uri.c scale, where `done` has ~40 in-edges and per-path duplication
is visibly non-amortizing.

**Fix (text, both files + draft §2/§3):** replace the P09-class
sentence with the honest form: "forces the general-label/fall-through
vocabulary; join-once composition is exercised, not forced, at 2
predecessors — the amortization forcing is uri.c's 40-in-edge `done`,
for which this is the miniature." Optional strengthening (author's
choice, not required): make `fail`'s return value depend on `acc`
(e.g. a cleanup computation) so the shared continuation must be
proved at a symbolic join state covering both predecessors; even
this cannot force join-once at n=2, so the note is the primary fix.

### C2 — p20: "Ecase with SHARED continuations" is factually wrong
about the elaborated shape

Verified: the switch elaborates to an if-dispatch ladder + save/run
labels + a break label — no Ecase node exists in p20's Core. So at
the Core level p20's vocabulary is nearly identical to p16's (labels
+ fall-through + covered if-chains); G5 as a distinct FAMILY is
thinner than the matrix claims, and §2's "no filler" assertion leans
on it. p20 still earns its row: (a) it rehearses the same machinery
from a different, stereotyped elaboration provenance (dispatch
ladder + per-case saves + the zero-body break join label); (b) the
fallthrough is behaviorally forcing — a prover that wrongly treats
the arms as disjoint derives 2→1 and fails against the spec's 2→2.
**Fix (relabel, the corpus-1 H6 pattern):** re-describe G5 as
"switch-provenance dispatch ladder + fall-through at elaborated
labels (G1 at the switch construct)" in §2 and the p20 header; drop
the "Ecase" family name; note the roadmap table's "switch →
PEcase/Ecase chains" line is itself inaccurate for this shape (table
maintenance, same bucket as the p18/p19 flags).

### C3 — p22: devirtualization-by-case-split IS the intended proof;
say so, and record the deferred hard face

My brief's sharpest question ("can the indirect call be devirtualized
statically?") has answer: after `by_cases` on sel, each arm's callee
is a concrete `Cfunction` value — the intended proof IS
devirtualization per arm. The draft's "constant-folding `f` is
impossible at symbolic sel" is technically true and rhetorically
overclaims: the case-split makes it possible per arm, and that is
the design. What p22 genuinely buys (verified in Core, non-trivial
but thin): function-pointer values through a store/load roundtrip
(an fn-ptr-typed CELL — new memRW content), the `cfunction()`
type-compatibility memop, and per-arm FnSpec selection composed with
V4's call rule. Note also that in Core EVERY call is already
ccall-of-a-Cfunction-value (main's direct calls to apply elaborate
identically), so the "indirect call" rule largely rides V4's direct
form. What p22 does NOT touch: the RefinedC binary_search class —
a function pointer arriving as a quantified ARGUMENT carrying a
contract assumption, never resolvable by case-split over a known
set. That is the genuinely new fn-ptr reasoning and it is
UNREACHABLE in this corpus's scalar-harness style (a fn-ptr cannot
enter through the call boundary), so p22's shape is near-maximal
within corpus rules. **Fix (text):** amend the p22 header + §3 to
state the case-split honestly; ADD the symbolic-fn-ptr-argument
class to the recorded deferral list with its named trigger (libxml2
SAX layer / kernel ops tables — the same list that holds symbolic
may-alias).

### C4 — p17: the easy face of PNVI; name it

p17 survives the dishonest-pass test cleanly: the three memops are on
the only path, and the ∀-seed quantification blocks any
concrete-address evaluation route — the proof needs address-generic
expose/recover/deref laws. One honesty line owed: the recovery step
is UNAMBIGUOUS BY CONSTRUCTION (exactly one live, exposed allocation
contains the address), so the row forces the cast-memop vocabulary
but only the easy face of PNVI — multiple exposed candidates,
one-past pointers, dead-allocation recovery, and udi disambiguation
all stay deferred. The header's deferral note should say that
explicitly (it currently defers "address-arithmetic rows", which is
narrower). LP64 dependence (unsigned long = 8 bytes, no truncation)
is fine — house model — but worth one word. ACCEPT with those lines.

### C5 — p18, p19: honest and cheap, as labeled

p18: nothing to dodge (straight-line); the value is the over-fire
shakeout (four defined-wraparound ops with zero UB side conditions)
plus the unsigned eval-law widening, and the draft says exactly that.
One line owed: the row is 32-bit; WireGuard's siphash is u64 — state
that the law class is expected width-generic so the kernel
justification carries. p19: the dishonest route (inline both tick
calls) is the settled P09 situation — note-not-gate, consistent with
the operator's corpus-1 ruling. But see C6: the claimed in-file note
does not exist. Also §4's tier attachment underprices p19 by one
sliver: the `glob` section is real (verified), so the harness
protocol needs glob-INIT stepping + globals in EnvHyp before any
globals-in-contracts work — likely S, but name it.

## 2. Discipline/consistency findings

### C6 — In-file discipline regressions vs frozen corpus-1

- **Missing sample labels, all 8 files**: corpus-1's main() comment
  ("oracle differential sample only — NOT the theorem") was singled
  out by the corpus-1 review as catechism-§V discipline to keep
  verbatim. No corpus-2 file carries it. Add to all 8.
- **p19's claimed in-file anti-inlining note is absent**: draft §3
  says "inlining both calls is the P09 move (in-file note)" — the
  p19 header contains no such note (record-accuracy nit; add the
  note, which also discharges the claim).
- **p20/p21/p23 lack in-file dishonest-pass lines** (p16/p17 have
  them). Corpus-1 practice put them in-file where load-bearing; for
  p20 the C2-corrected line IS load-bearing. Add brief ones.

### C7 — The §4 census-boundary/"distance to all of C" claim is
table-granularity-relative; the table has silent holes

Row-by-row against roadmap §1b, the delta claim CHECKS OUT: goto
(p16), ptr↔int (p17), unsigned-ring (honestly split out of "covered
class"), globals/statics (honestly flagged as a missing table row),
switch richness (p20 — correctly not claimed as closing the P15-owned
row), unions (p21 — precision nit: what is exercised is
memberof/member_shift at union type + union-typed create/store/kill,
not the PEunion ctor; say "union member vocabulary"), function
pointers (p22), Eunseq/End proof-side (p23); floats/varargs/
symbolic-may-alias excluded with rationale; concurrency ruled. BUT
"no unowned construct row" is true only at the TABLE's row
granularity, and the table itself omits at least: **bitfields**
(uri.c has none — census §9 — but kernel code uses them pervasively;
the kernel-priority logic that promoted p18/p19 applies), **64-bit
ring arithmetic** (C5), and enums (cheap, elaborate to ints). Fix:
one sentence scoping the claim to the table + flag bitfields/u64/
enums for the table's maintenance exactly as the draft already
flagged the wraparound and globals rows. No new program demanded
(corpus-as-scope-fence stands); the flag keeps the boundary honest.

### C8 — Priority honesty: verified

- p16 MINIMUM-2: census-verified (E3 = 90 goto sites, 10 labels,
  rank-9 idiom). p17/p18/p19 MINIMUM-2 by kernel demand: real —
  pKVM address arithmetic, pKVM/WireGuard hash rings, module-static
  state are all genuine kernel-target staples, and p18/p19 are
  corpus-1 §6's own deferral notes re-adjudicated under the [USER]
  hunt mandate — a legitimate promotion, correctly recorded as such.
  Note for the freeze text: MINIMUM-2 thereby means "minimum for the
  TARGET SLATE (uri.c OR kernel)", a broader criterion than
  corpus-1's uri.c-graduation MINIMUM — the draft's §1 split makes
  this visible; keep it visible in the manifest labels.
- EXPLORATORY labels honest, including p23's "nothing near-term"
  self-report.
- All three exclusions are adjudications, not convenience: each
  names a trigger (floats — a demanding target, with the tests/float
  differential lane covering the semantics leg; varargs —
  snprintf-as-contracted-primitive at the capstone, matching the
  census's own "outside near-term proof reach" for its only 2 sites;
  symbolic may-alias — corpus-1 H6's recorded deferral, unchanged).
  CONFIRM all three.

### C9 — V-dependency map: right, with two slivers

p19/p22 = V4+: correct (plus C5's glob-init sliver on p19). p21 =
V3b-adjacent: fair — union member views ride the PEmember_shift
machinery, and the non-punning per-path discipline keeps the memory
face simple; note the whole-union `store(…, Unspecified('union
uv'))` init (verified in Core) touches memRW at union type, slightly
more than "field views". p16/p20 "EARLY, cheapest new capability":
plausible — the save/run + REBIND classes exist; fall-through entry
into a save and the forward-run shape are the only new segLink
content; this is a claim about the engine that the first attachment
will test, and it is priced as such. p23 = its own ND-rule class,
cmm-adjacent: correct and honestly flagged; with 2 interleavings the
minimal machinery is an unseq-split rule + same-outcome join —
2-case enumeration here is structural, not forbidden.

## 3. Part 2 — the shakeout campaign

Assessment: the campaign is well-conceived and correctly scoped as
NOT-new-capability, with the finding discipline (bug report, never
grind) and the [F5] halt mechanism carried over intact. Findings:

- **Count nit**: header says "~13"; the table is s01–s14 = 14 (the
  draft's own Part-2 title and my brief both say 14). Fix.
- **Covered-vocabulary audit**: s01–s08, s11, s12 are clean covered
  vocabulary. **s09 (via_ptr)** is the one row most likely to hit
  un-landed vocabulary (a store whose target address is a LOADED
  pointer value — pointer-valued cells feeding store addresses);
  that is acceptable — it is exactly what a shakeout is for — but
  label it in the table as the intended frontier probe alongside
  s10, so an over-budget result there is read as the expected
  finding, not a campaign failure. s13/s14 correctly labeled
  post-bridge (consistent with the roadmap's B1 gate). Nothing
  smuggles an unbuilt V3b/V4/V5 feature.
- **s10 frame-shake and s11 infeasible-path: genuinely sharp.** s10
  (arms write different cells, both read after the join) is the
  cleanest per-arm-footprint reconciliation test available at
  covered vocabulary. s11 is better than it looks: closing the two
  infeasible paths cheaply requires BOTH contradiction pruning AND
  frame-preservation of the predicate's operands through the first
  arm — two engine properties, one program. Keep both exactly.
- **Budget rule needs the [F5] form**: rule 1 ("≤6 registered facts,
  user text at the m1 shape") is loop-free-calibrated; s13/s14 need
  the census-plan phrasing "spec + invariant declarations + ≤6
  manual steps" so invariants (legitimate human content per the
  catechism) are not counted against the step budget. Halt rule (2
  consecutive over-budget) consistent with [F5]. Fix rule 1's text.
- **B2 acceptance measurement is NOT yet well-defined.** "Near-free"
  has no number and "run (or re-run)" leaves the baseline ambiguous.
  Fix: the measurement is a BEFORE/AFTER PAIR — first run in the
  A2→A3 gap (rule 6 already permits it) or accepted first-run costs
  as baseline; re-run after the basket; recorded quantities pinned
  per program (manual steps, registered facts, guard-template lines,
  wall-clock); the basket's acceptance = the delta on exactly the
  components B2 claims (guard minter → guard-template lines ~0;
  coda fusion → coda transcription steps ~0) plus a stated absolute
  post-basket budget for the m1 class. Without this pinning the
  "doubles as acceptance" claim is unfalsifiable.
- **Relation to the R6 census-plan tiers unstated**: the shakeout
  list overlaps the pre-registered R6 corpus plan's EASY/EDGE
  territory (e1–e5/x1–x7, uri-census doc). One line should
  adjudicate the relation (complement/supersede) so there is exactly
  one campaign registry — this is the coherence arc; leave one
  route.

## 4. Per-program verdicts and the complete revision list

| # | Verdict | Required revision (all text/statement-level) |
|---|---|---|
| p16 goto_ladder | **ACCEPT** | C1 honesty rewrite of the dishonest-pass note (join-once exercised-not-forced; drop "P09-class"); C6 sample label |
| p17 ptr_roundtrip | **ACCEPT** | C4 easy-face-of-PNVI line in the deferral note; LP64 word; C6 sample label |
| p18 wrap_mix | **ACCEPT** | C5 width-generality line (u64 expectation); C6 sample label |
| p19 static_tick | **ACCEPT** | C6 add the claimed-but-absent in-file anti-inlining note; C5/§4 name the glob-init protocol sliver; sample label |
| p20 switch_fall | **ACCEPT** | C2 relabel (no Ecase — dispatch ladder + labels; G5 = G1-at-switch); in-file dishonest-pass line (fallthrough behaviorally forcing, join-once not); sample label |
| p21 union_pick | **ACCEPT** | §4 precision: "union member vocabulary (memberof/member_shift + union-typed create/store)", not "PEunion"; in-file dishonest-pass line; sample label |
| p22 fnptr_apply | **ACCEPT** | C3 honest devirtualization framing; add symbolic-fn-ptr-argument class to the deferral list with SAX/ops-table trigger; sample label |
| p23 unseq_pair | **ACCEPT** | none structural (Core-verified genuine unseq; keep the honest price flag); in-file dishonest-pass line; sample label |

Draft-level revisions: C2 (§2 G5 relabel + "no filler" wording), C7
(§4 table-granularity scoping + bitfields/u64/enums maintenance
flags), C8 note on the MINIMUM-2 criterion broadening, C9's two
pricing slivers, Part-2 fixes (count 14; [F5] budget form; the B2
before/after measurement pinned; R6-plan relation line; s09 frontier
label). Freeze obligations mirror corpus-1's: re-run all 8 samples
at freeze (my 8/8 re-run stands as this review's evidence, not as
the freeze run), constants inventory already complete (§3 checked —
every constant derived or spec content; no undercount found).

## 5. The draft's four operator questions — recommendations

1. **Freeze scope**: agree with the draft — **all 8, one review, one
   freeze**, with the MINIMUM-2/EXPLORATORY class labels carried in
   the manifest. The annex split would add process without content;
   §4's tier attachment already sequences the build-out.
2. **The exclusions**: **confirm all three** as recorded decisions
   (C8: each is a genuine adjudication with a named future trigger).
   Record C3's addition (symbolic-fn-ptr-argument) alongside them.
3. **p23**: **keep in corpus-2.** The Core inspection strengthens
   the draft's case: the unseq with unsequenced stores is real,
   sequential, C11-defined, and the smallest possible statement of
   proof-side ND — freezing it converts the ND-rule gap from an
   invisible absence into a priced target; the cmm arc inherits it
   as warm-up either way. The honest price flag stays in the frozen
   text.
4. **Numbering/mechanics**: **yes** — p16–p23 extend the corpus-1
   manifest under the same hash gate and README terms, with the
   corpus-1 freeze obligations applied (sample re-run at freeze;
   the C6 labels landed before hashing).

## 6. Bottom line

REVISE-THEN-FREEZE, revisions entirely textual. The hunt did its job:
every tail construct now has a program, an exclusion rationale, or a
ruling (at table granularity — C7 flags the table's own holes), the
priority instrument is honest, and the two rows I attacked hardest
(p17, p23) are the two that verified most cleanly at the Core level.
The corpus-1 review found a false theorem, a wrong sample, and a
∀-costume; this review found none of those — the pipeline's
discipline transfer is visible. The residual weaknesses are
overclaimed FORCING language at the two label-join rows (C1/C2) and
a thin-but-real sliver at p22 (C3) — all fixable in an afternoon of
edits, none touching a single program's C text except optionally
p16's continuation.
