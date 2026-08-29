# Harness-era rip-out inventory

STATUS: FINDINGS, NOT ACTIONS. Commissioned [USER 2026-08-29]
("figure out what was off track / needs to be ripped out from the
harness-focused era"), read-only over the committed tree at
`arc/segment-ladder` @ `b7035a195`. Nothing is deleted by this pass;
the paper-logic design (notes/2026-08-30_core-logic-paper.md, in
flight) is the final arbiter and this inventory feeds that
conversation. The operator's stated inclination — "just delete such
off-track work… not sure if that's a rational decision or just
irritation" — is tested item-by-item in §5 with rebuild costs.

THE TEST (from the logic-first rulings): *would the paper logic's
mechanization, or its legitimately-thin application layer, consume
this artifact?* Verdicts: DELETE / EXTRACT-THEN-DELETE /
GENERALIZE-IN-PLACE / KEEP (logic-grade or legitimate application).

SHARPENED TEST for the harness-protocol apparatus [USER 2026-08-29
addendum, mid-pass]: harness proofs are WANTED but done IN the
logic — the harness (incl. `main`) is just a function with a
contract, proved by the ordinary CALL RULE consuming the target's
contract; the ONLY execution-facing artifact is ONE generic ∀-state
adequacy theorem, instantiated at use-time. So each protocol piece
(callK2/callND plumbing, at-init bridges, protocol templates,
verify_fn's statement-shape classifiers) is KEEP/EXTRACT only
insofar as it is THE CALL RULE or THE GENERIC ADEQUACY THEOREM
wearing early clothing; the rest is harness-primacy overbuild →
DELETE. §4f applies this; it moves most of the protocol layer out
of KEEP.

Context that shrinks this inventory: the tree has already survived
THREE purges (the kill-list execution ~18.6k lines; V0's kill basket
~7.2k; V1's whole-state route −4.2k). The deepest harness-era
artifacts (walk engine rooms, ambient slate, concrete-input corpus,
chase machinery) are already gone. What remains classifiable as
harness-era mass is concentrated in three places: the minted
per-program round supply, the per-fixture guard stamps, and the
arc-15 spec-lab family rungs.

Proof-layer size at HEAD (relsem + Kit/RoundEval + speclab proof
side): ≈ 59.5k lines. relsemcore (≈2.2k) is layers 1–2 semantics —
out of rip-out scope by definition.

## 1. KEEP — THE LOGIC (∀-context rules + semantic ground + laws), ≈ 11.5k

| Artifact | Lines | Note |
|---|---|---|
| CStep.lean | 293 | mechanism-C construct package — the rule figure's seed |
| CerbStateStep.lean | 1,608 | per-construct round rules, ∀-state (proto-figure) |
| CerbStateRA.lean | 1,327 | the 7-component interpretation — logic infrastructure |
| CerbStateWP.lean | 698 | op rules at fragment granularity |
| Segment.lean | 562 | the Seg algebra (sequence/iter/while_inv/first_exit) — logic rules |
| CerbStateAdequacy.lean | ~340 of 485 | the GENERAL adequacy face (`cerbSt_adequacy`, any initial state) = the soundness architecture — this IS the "one generic ∀-state adequacy theorem" of the sharpened test, already extracted; the ~145-line at-init harness bridges move to §4f |
| PerStep family (PerStep/Iris/Obs/Call/Tactics/Peel + FuelHooks) | ≈ 1,850 of 1,996 | the language instance + GENERIC reification scaffolding (any program's driver loops); PerStepPeel's callK2-specific harness reification (~150 ln) moves to §4f |
| Kit/* + MemLocal + ConstructLaws + WpGround + DeriveState + LawRegistry + SegReg + SegLoop | ~5,041 | the law library + registry |

Verdict basis: every item is already stated ∀-context (professor
spot-audit signs (b)/(c) CLEAN) or is the semantic scaffolding the
paper logic's soundness will be proved against.

## 2. KEEP — ENGINE (proof-producing automation beneath the logic), ≈ 9.8k

SegStepper (3,272 — with the standing 8-module decomposition note
and two harness-facing corners flagged: the statement-shape
classifier interface and the seg_done protocol handling belong
application-side after F2 fusion), SegRun (1,700 — links/blocks;
the seg_done readout corner is application-facing), SegRoundTac
(461), RoundEval chassis (4,415). The engine is below the logic
line; harness knowledge inside it is confined to the two flagged
corners. No engine item meets the DELETE test — the paper logic's
mechanization consumes all of it.

## 3. KEEP — APPLICATION (the genuinely thin residue), ≈ 4.2k

| Artifact | Lines | Note |
|---|---|---|
| relsemcore/Threaded.lean faces (Cns/Thr forms, ConsistentRun) | (in relsemcore) | the observable face — the FROZEN statements' vocabulary. Note: the statements observe `callND` executions; `callND` itself is layer-1 semantics (the runner), untouched by §4f — what dies there is the PROOF-side protocol, never the observable |
| Statement + fixture data (Corpus*/Slate*/T1File/T1Core/T*Threaded/T5/M1Statement) | ≈ 2,802 | validation-instance data; frozen statements — under the sharpened test these are instantiations of the generic adequacy at harness contracts; the TEXTS are frozen, only their derivation route changes |
| PriorCensus.lean | 121 | statement-layer fail-closed instrument (registered mover) |
| speclab KEPT core: Codec, MkHarness, DivMod\* + CnSeed\* (the two GATING differential lanes' machinery), SpecLabAudit | ≈ 2,300 | the splice machinery the corpus batch-B rows consume + the two gate lanes |

(SegmentFaces and the at-init bridges were classified KEEP here in
draft 1; the sharpened test moves them to §4f.) Under
contracts-primacy the residue above is legitimate: the observable
face and validation instances must exist; the ruling makes them
*downstream*, not absent.

## 4. THE RIP-OUT SET

### 4a. DELETE — the minted per-program round supply, 11,416 lines (the heaviest item)

T1Rounds 1,369 · T2Rounds 1,420 · T3Rounds 1,403 · P01Rounds 2,446
· P02Rounds+A/B/C/D 4,778. Per-program, harness-family-anchored
enumerated step facts — the exact layer mechanism C exists to
retire (the m1 exit proved a program needs ZERO of these).
**The logic-first test fails cleanly: nothing in the paper logic or
the thin application layer consumes per-program round enumerations.**

- **Rebuild cost if ever needed: ≈ 0** — generated
  (`scripts/gen_p02_supply.py` committed per amendment A11) and
  obsolete by design.
- **TIMING CAVEAT (the one place delete-now ≠ delete-rational):
  these files currently back live theorems** (P02Proof imports
  P02Rounds A–D; T1–T3/P01 proofs consume theirs for the not-yet-
  minted round classes). Deleting today un-proves 5 of the 10
  standing theorems. The rational form is the established
  killed-by-registration pattern: **delete per program-class as
  mechanism-C coverage replaces it**, with the construct-package
  completion as each class's trigger. Delete-now would strand
  proved theorems for no gain — this is irritation's one trap.

### 4b. DELETE — committed probe instruments, 489 lines

CStepProbe/CStepProbeP01/CStepProbeP01S (321), M1WalkProbe (50),
T5WalkProbe (118). Dev instruments, regenerable at will, no
consumer. Rebuild ≈ 0. Delete rational at any time (or adopt the
V2Probe convention: delete at slice close, resurrect from git when
needed).

### 4c. DELETE (theorem layer) — the unused spec-lab family rungs, ≈ 7,000 lines

TreeRot rung 3,803 (Core 2,468 + Harness 474 + main 861) ·
ListAppend rung 2,601 · ByteArr rung 1,393 — MINUS their two
codec-bridge theorems each, which are self-referential (nothing
downstream consumes them: their family-∀ target statements died at
V0 kill basket (c); the corpus batch-B rows use their own
CorpusB* encodings, verified by import).

- **Rebuild cost: M per rung** if a future corpus row ever wants a
  tree/list family — but the *pattern* (Codec + MkHarness + the
  DivMod/CnSeed worked instances) is kept, so rebuild = re-stamping
  a kept pattern, not re-derivation.
- **SEPARATE-LEDGER CAVEAT**: the `test_speclab_{bytearr,list,tree}`
  differential lane SCRIPTS are model-validation tests, not proof
  artifacts — the logic-first test does not apply to them. Deleting
  the .lean theorem/harness mass removes what those lanes exercise,
  so the lanes retire with the rungs **as a test-coverage decision**
  (flagged as an operator question, not adjudicated here).

### 4d. EXTRACT-THEN-DELETE — the per-fixture guard stamps, 2,461 lines → extract ≈ 350

P02Guard 1,238 + M1Guard 1,223: each re-stamps the op×side
guard/conv chain template per fixture (professor finding F1 — the
amortization failure). **The extract**: the value-generic ladders
(the op×side compare/verdict characterization, the checked-arith
arm ladders — genuinely file-generic, rule-grade; ≈ 300–400 lines
of general content currently embedded in fixture clothing). These
become figure rules (the F1 guard-minter / file-generic conv
characterization — already the scheduled fix). Extraction price
S–M (scheduled); rebuild-from-scratch M+ — extraction strictly
cheaper. Raw deletion would destroy the general content: the one
clear case where irritation and rationality diverge.

(T5Guard 1,216 is NOT in this set: its anchors are the pending T5
proof's declared facts — reclassified GENERALIZE, consumer = the
bridge slice.)

### 4f. THE HARNESS-PROTOCOL APPARATUS under the sharpened test, ≈ 2,040 lines → extract ≈ 80 + two design inputs

The [USER] addendum's frame: harness = a function with a contract,
proved by THE CALL RULE; execution-facing = ONE generic ∀-state
adequacy theorem instantiated at use-time. Applying "is this piece
exactly one of those two artifacts wearing early clothing?":

| Piece | Lines | Verdict | The extract / trigger |
|---|---|---|---|
| SegmentFaces.lean (verify_fn statement-shape classifiers + dispatch) | ≈ 620 of 698 | **DELETE** | pure harness-primacy overbuild: it exists to reverse-engineer proofs FROM statement shapes — under contracts-primacy the derivation runs the other way (contract → generic adequacy → statement). Trigger: harness-as-function corollary route lands |
| SegmentFaces discharge lemmas (dischargeCns/UBCns) | ≈ 80 | **EXTRACT** | they are the generic-adequacy instantiation pattern wearing tactic clothing — extract = the use-time instantiation recipe (one lemma-shaped pattern) |
| CerbStateAdequacy at-init bridges (kCallHarness\*St_of_wp, Thr+Cns+UB forms) | ≈ 145 | **EXTRACT-THEN-DELETE** | the extract ALREADY EXISTS: `cerbSt_adequacy` (the general face, §1) is the one generic theorem; the at-init specializations are its early clothing. Delete on the re-derivation of the frozen corollaries through generic-adequacy-at-use-time |
| Caller-protocol templates inside proof files (m1_wp/p01_wp/p02_wp/t1/t2/t3 protocol sections, ≈175/program) | ≈ 1,050 | **EXTRACT-THEN-DELETE** | the protocol IS the call rule + the harness function's own body proof, hand-unrolled per program. Extract = design input to THE CALL RULE (V4) — the protocol's argument-injection/return steps are the call rule's premises enumerated. Delete when harness-main is proved by the call rule like any function |
| callK2-specific harness reification (PerStepPeel §callK2 + callK2_obs) | ≈ 150 | **DELETE** | the harness needs no special reification once it is just a program — the generic peel machinery (KEPT, §1) covers it. Trigger: same as above |

Net: the protocol layer that draft 1 kept as "application" is
≈ 95% early-clothing overbuild; the thin layer that survives is
exactly two artifacts — the call rule (to be built at V4, with the
protocol templates as its design input) and the already-existing
generic adequacy theorem plus one instantiation recipe.

### 4e. GENERALIZE-IN-PLACE — the target-function content + demo, ≈ 4,550 lines

T1Proof · T2Proof · T3Proof · P01Proof · P02Proof · M1Proof/M1Body
MINUS their §4f protocol sections (≈ 3,510 remaining: the body
lemmas = the target functions' contracts in embryo) · T5Guard 1,216
· CerbStateDemo 827 (relabel as logic exemplar). Right artifacts,
wrongly quantified: body lemmas anchored at the harness ambient
family (M1Body's opens pull the T1 fixture vocabulary: mr2/al0/bs0
etc.). The fix is the already-scheduled ∀-context generalization
pass (S–M, rides the polish basket); under contracts-primacy each
becomes the function's contract, full stop. Deletion here would
un-prove standing theorems to rebuild the same content — pure loss.

## 5. THE OPERATOR'S RATIONALITY CHECK — summary table

| Class | Lines | Rebuild cost | Delete-now rational? |
|---|---|---|---|
| 4a round supply | 11,416 | ≈ 0 (generated/obsolete) | YES **but on the per-class replacement trigger** — delete-now strands 5 live theorems |
| 4b probes | 489 | ≈ 0 | YES, any time |
| 4c speclab rungs | ≈ 7,000 | M/rung, pattern kept | YES (theorem layer); lanes = separate test-ledger question |
| 4d guard stamps | 2,461 | extract ≈ 350 @ S–M vs M+ rebuild | ONLY AFTER EXTRACT |
| 4f protocol apparatus | ≈ 2,040 | extract ≈ 80 + call-rule design input; generic adequacy already exists | ONLY AFTER the call rule (V4) + generic-adequacy re-derivation — deleting now un-proves every standing corollary |
| 4e target-function content/demo | ≈ 4,550 | would re-prove same theorems | NO — generalize, don't delete |
| **Total rip-out mass** | **≈ 23.4k of ≈ 59.5k proof-layer lines (39%)** | | |

**Adjudication of the inclination**: irritation and the prune
doctrine AGREE on ~21k of the ~23.4k (4a+4b+4c+4f — each with its
replacement trigger). The divergence set is small and precise: (i)
4a's and 4f's *timing* (delete-on-replacement, not delete-now —
every standing theorem's proof or corollary currently routes
through them); (ii) 4d's *extract-first* (~350 lines of rule-grade
content in fixture clothing); (iii) 4e entirely (deletion =
re-proving the same theorems later); (iv) 4c's *lane scripts* (test
ledger, not proof artifacts). Everything else: the inclination is
rational, not irritation — and the sharpened test moved ~1.8k lines
from my draft-1 KEEP into the rational-delete column, i.e. the
operator's instinct was RIGHTER than my first partition.

## 6. ADJACENT FINDINGS (not rip-out, listed for the paper-logic conversation)

- **Docs carrying harness-primacy framing** (reframing headers,
  cheap): the catechism §II (presents the harness/canonical-property
  theorem as "what is a theorem worth proving" — needs the
  contracts-primary re-anchor already pending [USER] bless); the
  frozen corpus doc's acceptance language (amendment pending);
  the capability roadmap (instance-framed acceptance rows); the V0
  record's statement-slate-as-goal framing; PROOF.md §2's
  harness-first narrative. ~5 documents, S total.
- **The statement gate** polices the application layer — correct
  and unchanged under logic-first; the rule figure will need its own
  coverage/soundness gate story (a paper-logic-design question,
  noted only).
- **Remaining V-slices** (arrays/calls/heap summit): logic-first
  NEUTRAL in content (they build rules) — only their acceptance
  lines are corpus-row-framed and need re-pointing to
  figure-rows-plus-corollaries at the paper-logic conversation.
- **SegStepper decomposition** (professor monolith note) unchanged
  by this inventory; the two harness-facing corners move
  application-side when split.

## 7. OPEN QUESTIONS (for the paper-logic conversation)

1. 4c lanes: retire the three non-gating spec-lab differential
   lanes with their rungs, or keep as model-validation coverage of
   the splice machinery? (Test-ledger decision.)
2. 4a trigger granularity: per program-class as mechanism C covers
   it (recommended — matches the killed-by-registration pattern),
   or one deletion at C-completion?
3. Probe-file policy going forward: the V2Probe convention
   (delete-at-close, git-resurrect) as standing rule?
4. Does the paper logic's application chapter absorb the speclab
   Codec/MkHarness layer as-is, or re-derive the splice pattern in
   its own vocabulary first (affects whether 4c deletion waits)?
5. §4f sequencing: the protocol layer's replacement trigger is THE
   CALL RULE (V4) + re-deriving the frozen corollaries through
   generic-adequacy-at-use-time. Should that re-derivation be V4's
   acceptance exhibit (harness-main proved by the call rule, the
   frozen statement falling out as a one-line corollary) — making
   V4 the protocol layer's execution date?
6. verify_fn's fate: under §4f its classifier dies, but agents will
   still want a one-word face for "derive the frozen corollary from
   this contract." Is a thin `derive_corollary` face (generic
   adequacy instantiation only, no shape classification) the
   sanctioned replacement, or is even that unnecessary once the
   corollary is a one-line `exact`?
