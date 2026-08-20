# Arc 7 results: Layer 2 + first adequacy ("the bridge")

Companion to the charter (2026-08-19_arc7-layer2-charter.md), decision
log D1–D9 (provenance-tagged), the S3/S4 worker records
(2026-08-20_arc7-s3-layer2-slate.md, 2026-08-20_arc7-s4-iris-coupling.md;
S1/S0, S2 and S5a are recorded in their commit messages — 0dd436db5,
d84fb08b9, e7c4d5fd0/ec8036910/bab651a16, 5b007a549/59e3ef350/8b799e036),
and the spike record (2026-08-19_relsem-spike.md).

## Headline

**The program's first novel theorems: T1–T4 — ∀-quantified,
interpreter-only, kernel-checked statements about real compiled C
programs — PROVED through the full Iris weakest-precondition route and
discharged by an in-repo adequacy theorem.** T4 (struct member
write/read, the charter's exit criterion) included. Every statement
instantiates the charter's template

    ∀ args, P args → every outcome of run(compile(f), inject args)
                      is Specified (s args)   [in particular: no UB]

concretely: `T?Statement` quantifies the arguments as Lean integers,
carries the range precondition (T2's no-signed-overflow precondition
was FORCED by the UB obligation, exactly as the slate table predicted),
and concludes `CallHarnessAdequate` — a Prop over **the production
runner only** (`CerbND.runND` on `callND` over the pinned compiled Core
term): no Iris, no relational layer, no `Step` in any statement
(mechanized: the in-build statement-TCB gate). The exit-criterion
statement, verbatim (RelSem/T4.lean):

```lean
def T4Statement : Prop :=
  T4EnvHyp →
  ∀ x : Int, intRange x →
    CallHarnessAdequate t4File.tagDefs t4File "memb"
      [intValue x] t4Fs (t4Spec x)

theorem T4 : T4Statement := ...
```

**T4EnvHyp, honestly:** T4's struct layout and fresh-binder transform
read three process-global externs the kernel cannot see through — the
tag-definitions global (`with_tagDefs`), the TU-digest global and the
fresh-int supply (both via `runEffectful`). `T4EnvHyp` hypothesizes
exactly the state the harness establishes (`CerbTags.tagDefs () =
t4File.tagDefs`; digest `""`; sym-supply seed `1048577` — [CORRECTED
2026-08-20, S5c/audit-1 F3: this is the SECOND process draw, not the
first: native/fresh_int.c is post-increment from 1<<20, so the first
draw is 1048576, consumed by Main's startup floor probe; the seed
drawn by `initial_core_run_state` is 1048577. Gate-witnessed
first-in-process by test_verify's t4-env-witness probe]). This is the
DECLARED
census boundary made **visible in the statement** instead of hidden in
an axiom cone: a reader sees precisely which environment facts the
theorem assumes, and the concrete harness (Main `--call` under
`setTagDefsIO`) establishes them. T1–T3 need no such hypotheses. The
pattern is the standing template for future struct/fresh-drawing
fixtures (D9).

Every slate cone is exactly `[DAEMON, propext, runEffectful,
Classical.choice, Quot.sound]` — classical trio + the two declared
LemLib boundary axioms — pinned exactly and build-enforced in
relsem/RelSem/Audit.lean (sweep at close: 2142 declarations, 0 sorryAx
exceptions). **DAEMON, honestly (S5c, audit-1 F1 — this qualifier is
part of the headline):** `axiom DAEMON : ∀ {α : Type}, α` is, AS
DECLARED, a logically INCONSISTENT axiom — `(DAEMON : Empty)` proves
`False`, kernel-verified (addendum below, probe quoted verbatim). A
cone carrying DAEMON is therefore kernel-checked only MODULO a
meta-assumption the kernel cannot state: that the generated code uses
DAEMON solely as an unreachable-inhabitant marker. The S5c kernel-walked
census reduced the entry vectors from 10 leaves to 2 (LemLib `failwith`
via 7 polymorphic generated callers incl. `pick`;
`instInhabitedAction_request2`, a same-module fallback) — both
STRUCTURAL until the C-tier lem redesign, which is now the TOP C-tier
item (temporal boundary, maximum-priority mover;
lembugs/2026-08-20_daemon-inconsistent-axiom.md). The DAEMON-free pins
(runND_sound, the adequacy layer, etc.) carry no such qualifier.
Proofs at DEFAULT elaborator budgets throughout (D8-clean
by grep). T5 (bounded loop) is parked with pricing, which the charter
explicitly allows (bar: "T5 proved-or-parked-with-pricing").

Substrate riders: CerbND totalized (the operator's Q1 AMENDED ruling —
the executable runner IS the proof object; arc-2's declared
RunNDActiveSound seam now PROVED), CerbMem's 9 exec-path functions
totalized, 5 more generated modules totalized (arc-3 F8 residue), the
D3 sorryAx evicted, toolchain bumped 4.29.0 → 4.32.2 on full gate
evidence with zero movement, iris-lean coupled as a Lake dep
contributing ZERO axioms to the pure coupling layer.

## Slice ledger

| slice | result |
|---|---|
| S1/S0 | branch assembly (spike/relsem rebased in — 9 commits, LIVE input per plan) + in-build RelSem axiom audit (golean pattern; sweep-last lesson encoded); TOOLCHAIN BUMP 4.29.0 → 4.32.2 ADOPTED on full gate evidence, zero movement (option (ii) fallback assessed: iris-lean v4.29.1 lacks GenHeap — degraded, moot); batteries → v4.32.0 (iris-vendored rev, offline); compiler delta registered (column-0 continuation parse) with fix-forward; ARC-BLOCKING sorryAx finding registered + pinned fail-closed (D3) |
| S2 | CerbND TOTALIZED (runNDFuel + wrappers; loud panic-at-exhaustion, proof-transparent — the D4 transparency asymmetry, endorsed); runner soundness PROVED against the production runner (runND_sound, runNDActiveSound — spike RunNDT deleted in favor of the real artifact); totality gate extended over hand-written CerbND.lean (both copies, fail-closed); D3 sorryAx EVICTED (CerbFunMapInstances.lean, phantom SetType requirement — audit exceptions 5 → 0) |
| S3 | symbolic-argument harness (callND/callConfig; caller protocol read off the real elaborated Core — int params by pointer); T1–T5 fixtures + test_verify.sh (23/23; T2's UB036 overflow rows recorded); trace evidence: every slate run is ONE ND node → the by-need work is the APP-EQUATION layer, not Step arms; fuel-erasure + reachability lemma layer (behaviors_active_iff etc., 30 FuelHooks); zero escalation events |
| S4 | rule-library INVENTORY FIRST (reuse-vs-build table R1–R10); iris-lean Lake dep @ 79dab15; language instance; StateInterp = full-driver-state ghost_var (the SC slot instantiation, slot documented); wp_app_active/killed + wp_callND; **THE ADEQUACY THEOREM proved, fallback NOT taken**; T1 through the full WP route conditional on T1AppEq; term-emission instrument (kernel-transparent pinned program terms + byte drift gate); escalation events: CerbMem exec-path totalization (9 fns); F8 residue enumerated + priced (the S5 gating item) |
| S5a | the F8 fuel sweep (declares-only .lem changes; totality gate 11 → 16 generated modules + CerbND, 0 allowlisted); T1 UNCONDITIONAL via the compositional app-equation chain (post-OOM: no whole-run reductions, default budgets); THE SLATE CLIMB — T2 (15 rounds), T3 (23), T4 (56, exit criterion) UNCONDITIONAL through the fixture-generic SlateWP bridge; T5 PARKED with pricing; the in-build statement-TCB gate (negative-tested); drift gate grown to 22 concrete points on the assembled theorem objects |
| S5b | close-out prep (this doc, de-stale, merge checklist); the two adversarial audits follow |

## Success conditions vs the charter (one by one)

1. **The slate** — MET. T1–T3 + T4 (exit criterion) proved,
   kernel-checked, through the WP route (D5 ruling: the direct route is
   cross-check scaffolding only — both routes exist for each theorem);
   T1 landed first as the plumbing validator (S4/S5a); every statement
   Iris/RelSem-free by the MECHANIZED in-build statement gate
   (RelSem/Audit.lean, negative-tested in-build on t1_wp: "12 slate
   statements fuel-opsem-clean" — DERIVED quote, whitespace-normalized;
   the literal output had a five-space run from a wrapped string
   literal, and the gate now reports 16 statements after the S5c
   rebuild — see the addendum); axiom cones exactly classical trio +
   declared boundary, pinned exactly, build-enforced; D14 gate green
   throughout. T5 parked-with-pricing — the charter bar
   ("proved-or-parked-with-pricing") is met on its parked leg; pricing
   below.
2. **CerbND totalized** — MET. Totality gate extended over it (S2, both
   copies, negative-tested); runner soundness in-repo
   (RelSem/RunND.lean: runND_sound, runNDActiveSound, behaviors_*_iff);
   hand-written axiom census still exactly 2 (with_tagDefs, forceIO —
   gate-enforced). Zero movement: Tier A green at EVERY commit (unit
   incl. sync/census/purity/totality/axiom-cone gates; minimal,
   coverage, debug baselines rc 0; libc_exec 7/7; multi_tu 2/2; parse
   ALL; core 106/106; elab recorded state; uri GATE PASS 16/16), plus
   battery slices at the S0/S2 boundaries and chvalid_battery_00 (1354
   points ALL PASSED) at the S5a close; test_verify 23/23 from S3 on.
   The tests/ci reporting sweep is not in Tier A and was not re-run
   mid-arc; it is listed in the merge checklist's post-merge
   certification (derived note, per LADDER.md placement).
3. **In-build axiom audit** — MET. relsem/RelSem/Audit.lean (S1),
   golean pattern: exhaustive module-of-origin sweep over every
   RelSem.* constant, build-failing outside the declared boundary,
   exact `#guard_msgs` pins on every load-bearing theorem, sweep as the
   file's last element, RelSem in defaultTargets (plain `lake build`
   runs it). Negative-tested at install; its fail-closed stale-exception
   tripwire fired as designed at the S2 eviction.
4. **Parametricity + slot documentation** — MET. Layer 3 consumes only
   the ExecModel interface (statement shapes are
   `ExecModel.Adequate`/`.UBFree` at `callConfig`; the adequacy
   conclusion is `CallAdequate` = `seqModel.Adequate`); the Language
   coupling is per-model BY DESIGN (the forward-design contract: the
   adequacy SHAPE is model-generic, S4 record §2); the StateInterp slot
   is parameterized and documented against the concurrency
   forward-design constraints (S4 record §3), with gen_heap catalogued
   as the Q4-refinement fill.
5. **Toolchain decision documented with gate evidence** — MET. Bump
   adopted on the full gate net (commit 0dd436db5 quotes the evidence
   verbatim: unit, all baselines rc 0, uri 16/16, battery 00+01, parse/
   core/elab); one compiler-delta register entry (column-0 continuation
   parse; principled fix = lem backend never emits column-0
   continuations — lem-lean follow-on); rebuild discipline recorded
   (make lean-prelude-src + make lean-native-obj — leanc changed).
6. **Records / audits / gate-green / checklist / mainlines** —
   Records complete (D-log D1–D9 provenance-tagged; verbatim-quote rule
   observed); arc branch `arc/layer2` gate-green at head; merge
   checklist ready (2026-08-20_arc7-merge-checklist.md); mainlines
   untouched. **Audits: 2 adversarial, IN PROGRESS at close-prep** —
   dispositions land in an addendum to this doc; the arc is not
   closeable before they do.

## Doctrine ledger (what landed this arc, and where enforced)

- **D14 ban** (standing since arc 6): enforced this arc by
  check_theorem_axioms.sh (grep leg now scans lean_frontend/relsem/;
  ofReduce* always-fatal in every probed cone) AND by the new in-build
  RelSem audit's exact pins (an ofReduce* axiom cannot enter a pinned
  cone unnoticed). The golean in-build Audit.lean pattern — the arc-7
  adoption item — is now LIVE (charter success condition 3).
- **The statement-TCB gate** (new, S5a): slate statements must mention
  no Iris-rooted constant and none of Step/Steps/CsSem/DSteps/stateIs;
  in-build, build-failing, negative-tested in-build (t1_wp must be and
  is rejected). RelSem/Audit.lean.
- **capped / never-uncapped** (D7 [USER-prompted], from the S5a OOM
  session kill): `scripts/capped` (cgroup MemoryMax via systemd-run,
  default 64G, CERB_MEM_MAX override, `=none` loud opt-out;
  breach-kill verified rc 137). Rules standing in the container
  CLAUDE.md: never run lake/lean uncapped; #eval-first; monolithic
  whole-run rfl/decide on driver executions BANNED as a proof method —
  build the compositional equation-lemma chain instead (S5a's T1–T4
  chains are the existence proof that this works).
- **Heartbeat-hacking doctrine** (D8 [USER]): elaborator-budget raises
  are by-definition defects unless investigated and agreed; codified in
  the container CLAUDE.md; enforced by audit grep — D9 verified ZERO
  budget bumps in relsem/ by grep.
- **Verbatim-transcript rule** (standing since arc 6): observed — gate
  outputs in commits/records are literal; derived tallies labeled (as
  in success condition 2 above).

## Register movements

**OUT (fixed / discharged this arc):**

- Arc-2 declared seam `RunNDActiveSound` — PROVED (S2; a standing IOU
  closed).
- D3 sorryAx finding (sorried generated SetType instance via
  Lem_Map_extra.fold's PHANTOM instance requirement) — EVICTED (S2,
  CerbFunMapInstances.lean; audit exceptions 5 → 0).
- Arc-4 G3 declared-boundary item, CerbND leg — DISCHARGED: CerbND
  totalized and inside the totality gate; `partial` may not return.
- Arc-4 G3, CerbMem leg — PARTIALLY discharged: the 9 exec-path
  functions totalized (S4 escalation event 1: memberAlign,
  offsetsofMembers, offsetsof, sizeofCtype, alignofCtype,
  memValueToBytes, reconstructValue, typeofMval,
  unqualifyAndUnatomic); only `stringFromMemValue` (pp-only) remains
  partial, plus panic! sites; CerbMem.lean is still outside the gate's
  scan (scanner extension is mechanical — priced).
- Arc-3 F8 (call-graph escapees) — PARTIALLY discharged (S5a,
  declares-only): **Utils, Annot, Ctype, Core,
  State_exception_undefined joined the totality gate** (now 16
  generated modules + hand-written CerbND, 0 allowlisted). Remaining
  F8 residue outside the slate path stays open.

**IN (new entries):**

- **The OOM incident + mitigation** (D7): a whole-driver-run rfl probe
  (maxHeartbeats 8000000) ate the 125G box and killed the session.
  Mitigation landed (scripts/capped + the three standing rules).
  Residual register item: none for the mechanism itself; the lesson is
  doctrine (above).
- **expr-family sorried BEq instance** (D9): C-tier lem item — the lem
  backend emits a sorried BEq for the expr family; surfaced during
  S5a. Lem-lean follow-on (NOT this arc's pin; lem untouched).
- **Compiler-delta / column-0 emission** (S0): lem's Lean backend can
  emit column-0 continuation arguments mid-definition; 4.32's parser
  rejects them. Fixed-forward this arc by a token-neutral .lem
  reindent; principled fix = lem backend never emits column-0
  continuations. C-tier lem-lean item.
- **The T4EnvHyp pattern** (D9, banked as the standing pattern):
  process-global externs surface as explicit statement hypotheses —
  reuse for every future struct/fresh-drawing fixture.
- **Lake lib-root wiring gotcha** (D9, recipe note): a module absent
  from its lib root builds green without being elaborated — a
  false-positive green until imported. Check roots when adding proof
  modules.
- **CoreParser totalization** (S4): parked — the term-emission
  instrument made it non-blocking; statement-side nicety.
- **Term-emission growth** (S4/S5a): whole-linked-file emission (full
  stdlib + main + function-pointer values) for T5-at-scale and
  libxml2-scale statements.
- **gen_heap-over-heapOf** (S4): the Q4 granularity refinement's first
  work item; entry points catalogued (S4 record §0.1) — a parameter
  fill of the documented slot.
- **iris-lean mirror** (D6): deps/mirrors/iris-lean.git needed at the
  next network window (recorded in deps/gitconfig too).
- **T5** (D9): parked with pricing (below).

## Pins at close

Single-repo arc: lem-lean UNTOUCHED (zero commits; zero model-.lem
semantic changes — the arc's .lem edits are declares-only: totality
annotations, `extra_import` declares (core_aux.lem CerbFunMapInstances
at S2; seven more for CerbCoreInstances at S5c, audit-response), and
one token-neutral reindent, all cerberus-side). LemLib
pin: Lake manifest `bd7e2eb` = deps/lem-pinned `bd7e2eb` = opam pin —
unchanged from the arc-6 close, verified at S5b. New pins this arc:
iris `79dab154a` + Qq `38d591e77` + batteries `023ce7d62` (v4.32.0),
all resolved offline via deps/gitconfig redirects. Toolchain:
leanprover/lean4:v4.32.2.

## Arc-8 pricing

1. **T5** (bounded-loop sum) — ONE SESSION: fuel induction over a
   ~30-round loop block with a (i, sum i) state-family invariant; the
   machinery (SlateWP bridge, request-arm unfolds, byte-roundtrip
   lemmas) all exists; the induction scaffold is the only new object.
   Its fixture, oracle dump, assembled t5File and 4 concrete
   expectation rows are already in-repo and drift-gated.
2. **gen_heap granularity refinement (Q4)**: finer Step + gen_heap over
   heapOf as the StateInterp fill; moves points-to/frame/loop reasoning
   up to WP level. Entry points catalogued; slot designed for exactly
   this swap.
3. **libxml2 chvalid-predicate slate entry (charter stretch "S")**: one
   chvalid predicate, ∀ code point, vs the range tables — needs
   whole-linked-file term emission (register item above) + the
   established harness.
4. **Concurrency arc tray** (banked notes + spike docs + survey): cmm
   instance = new Language coupling + StateInterp fill under the SAME
   adequacy shape — the forward-design constraint held all arc.
5. **pp-placeholder text class** (arc-6 carry: 3 ci non-agreements +
   mem3-004).
6. **Register burn-down**: read-only allocations (finding 11,
   corpus-forced, top of queue since arc 6); stack-ceiling guard;
   remaining F8 residue; CerbMem gate-scan extension; CoreParser
   totalization (parked).
7. **Lem C-tier items** (lem-lean, next time the pin moves): expr-BEq
   sorried instance; column-0 continuation emission; DAEMON instance
   fallbacks (standing temporal-boundary mover).

## Audit-dispositions addendum (S5c, 2026-08-20)

Two adversarial audits ran at close-prep (success condition 6's open
item). Their findings, as scoped to the S5c audit-response worker by
the orchestrator: audit 1 (proof layer/process) filed F1–F6 with F1 a
BLOCKER; audit 2 (records/instruments) filed the record-integrity and
instrument findings below and re-ran the tests/ci sweep (closing the
derived notes in success conditions 2 and 5). Per the orchestrator's
brief, the audits' remaining probes — beyond the filed findings —
surfaced nothing actionable (relayed summary, not a quote). Every
finding is fixed-or-recorded below; validation for the batch: full
Tier A + test_verify (29/29, now incl. the F3 witness + F6 provenance
checks) + battery slice 00 + the ci sweep, all rc 0 at the S5c head.

### Audit-1 F1 — THE DAEMON BLOCKER (resolved by eviction + honest rewording)

**The finding (auditor, kernel-verified; S5c re-ran the probe):**
`axiom DAEMON : ∀ {α : Type}, α` (LemLib.lean:26) is logically
INCONSISTENT — every T1–T4 cone carries it, so "kernel-checked" was
overclaiming. The daemon_false probe, S5c re-run 2026-08-20 (source +
output verbatim; exit 0):

```lean
import LemLib
theorem daemon_false : False := (DAEMON : Empty).elim
#print axioms daemon_false
```

```
'daemon_false' depends on axioms: [DAEMON]
```

**Diagnosis (S5c, kernel-walked leaf enumeration over the T1–T4 cones
— constants whose type/value DIRECTLY references DAEMON; probe output
verbatim, pre-eviction):**

```
cone size (constants visited): 4320
DAEMON direct referencers in the union T1-T4 cone: 10
LEAF failwith   [LemLib]
    referenced-by (7): [foldl2._f, map2_._f, msum, pick, subst_pattern_val_lemFuel._f, subst_wait_stack._f, update_env_aux_lemFuel._f]
LEAF instInhabitedAction_request2   [Core_reduction]
    referenced-by (2): [instInhabitedAction_step, step_ctx]
LEAF instInhabitedDlist   [Dlist]
    referenced-by (1): [instInhabitedIo_state]
LEAF instInhabitedExceptM   [Exception]
    referenced-by (5): [call_function, one_step0, process_impl_proc, step_ctx, step_eval_pexpr_lemFuel._f]
LEAF instInhabitedGeneric_expr   [Core]
    referenced-by (1): [instInhabitedThread_state]
LEAF instInhabitedGeneric_expr_   [Core]
    referenced-by (1): [add_to_asw_lemFuel._f]
LEAF instInhabitedGeneric_pattern   [Core]
    referenced-by (1): [mk_tuple_pat]
LEAF instInhabitedGeneric_pexpr   [Core]
    referenced-by (2): [finalize, mk_stdcall]
LEAF instInhabitedGeneric_pexpr_   [Core]
    referenced-by (1): [pull_constrained_lemFuel._f]
LEAF instInhabitedNdM   [Nondeterminism]
    referenced-by (8): [advance_step, drive_fs_step, driver_globals, perform_action_request2, perform_memop_request2, print_eval_conv_aux_lemFuel._f, process_core_step2, vsnprintf]
```

Classification: 8 of the 9 Inhabited fallbacks EVICTABLE (real
instances + import wiring); `failwith` STRUCTURAL (its value IS
DAEMON; poly-typed sites need the C-tier lem redesign);
`instInhabitedAction_request2` STRUCTURAL-this-arc (its use site
`step_ctx` is in the SAME generated module — the extra_import
mechanism cannot reach it).

**Eviction executed:** lean_frontend/CerbCoreInstances.lean (real
Inhabited instances for the generic Core AST families — honest total
constructions; imports CerbInhabitedInstances, whose arc-2 real
monadic instances were already in-tree but not wired into the
use-site modules) + `declare {lean} extra_import` in seven .lem files
(core_aux, core_eval, core_reduction, core_run_aux, driver,
translation_aux, formatted — declares-only, arc-4 S1a mechanism) +
regen + rebuild. Post-eviction probe (verbatim):

```
cone size (constants visited): 4324
DAEMON direct referencers in the union T1-T4 cone: 2
LEAF failwith   [LemLib]
    referenced-by (7): [foldl2._f, map2_._f, msum, pick, subst_pattern_val_lemFuel._f, subst_wait_stack._f, update_env_aux_lemFuel._f]
LEAF instInhabitedAction_request2   [Core_reduction]
    referenced-by (2): [instInhabitedAction_step, step_ctx]
```

(per-theorem walk: each of T1/T2/T3/T4 and each `_ubFree` cone shows
exactly `#[failwith, instInhabitedAction_request2]`). Zero movement:
full Tier A + battery slice green post-regen.

**Structural residue ⇒ the honest-rewording package (mandatory,
executed):** DAEMON remains on every slate cone via `failwith`
(reached through `pick`, the ND scheduler on every driver run), so the
F1 target ("cones = [propext, runEffectful, Classical.choice,
Quot.sound]") is NOT achievable this arc. Accordingly: (a) the
headline above now carries the DAEMON-honesty qualifier as part of the
claim; (b) RelSem/Audit.lean's boundary entry is the
DAEMON-INCONSISTENCY TRIPWIRE (verbatim-class honesty + the leaf
census + a build-failing DAEMON1-stays-un-allowlisted check); (c) the
container CLAUDE.md doctrine bullet gained the same statement; (d) the
lem-lane register item is filed with the consistent-design sketch
(lembugs/2026-08-20_daemon-inconsistent-axiom.md: failwith→failwithI
with threaded `[Inhabited]` binders + derived real instances; NO
single axiom over all `Type` can be consistent for this purpose) as
the TOP C-tier lem item — the temporal boundary's maximum-priority
mover.

**Final T1–T4 cones (unchanged by design — the pins are the record;
Audit.lean asserts each of these EXACTLY, build-failing):**
`T1/T1_direct/T1_ubFree/T1Outcomes`, `T2/…`, `T3/…`, `T4/…` all depend
on axioms `[DAEMON, propext, runEffectful, Classical.choice,
Quot.sound]` — now read under the honesty qualifier above.

### Audit-1 F2 — statement-TCB wrapper hole (fixed, both halves)

The gate's constant walk unfolded only one level and only T?-prefixed
Prop defs, so `CallUBFree` (= `seqModel.UBFree` — a relational-layer
object) sat INSIDE the T?_ubFree statements unseen. Fixed: (a) the
gate walk is now TRANSITIVE through every RelSem-rooted Prop-family
def, with a small positive allowlist of harness-surface/fixture-data
names (fail-closed: new statement vocabulary must be allowlisted
deliberately) and seqModel/DStep/ExecModel added to the banned exact
list; (b) the in-tree instance is fixed — `CallHarnessUBFree`
(RelSem/Call.lean) is the CerbND-shaped UB-freedom headline (no
outcome the production runner enumerates is an `Undef0` kill), and
all four `T?_ubFree` are RESTATED to conclude it (WP route intact:
WP ⇒ `CallUBFree` ⇒ discharge `callHarnessUBFree_of_ubFree`; a
direct-route twin `callHarnessUBFree_of_app_active` exists as
cross-check per D5); (c) the wrapper-hole probe is a PERMANENT
in-build negative test (`wrapperHole_thm` — the gate must surface
`seqModel` THROUGH a Prop-def wrapper, else the build fails), joining
the kept t1_wp negative test. Gate line at the S5c head (verbatim):

```
info: relsem/RelSem/Audit.lean:565:0: RelSem statement gate: 16 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
```

The leaf census itself is ENFORCED in-build (a census drift fails the
build); at the S5c head (verbatim):

```
info: relsem/RelSem/Audit.lean:442:0: RelSem DAEMON census: 2 entry vectors on the slate cones, exactly as pinned (#[failwith, instInhabitedAction_request2])
```

### Audit-1 F3 — T4EnvHyp fresh-draw value (corrected + gate-witnessed)

Truth established against native/fresh_int.c and by first-in-process
probe: the counter is POST-increment from CERB_FRESH_BASE = 1<<20, so
the FIRST process draw is 1048576 — consumed by Main's startup floor
probe (Main.lean "Sym non-escape floor assertion") — and the
sym-supply seed drawn by `initial_core_run_state` is the SECOND draw,
1048577. The proof's value (1048577) was RIGHT; the docstrings'
"first fresh draw / start-of-process value" description was WRONG and
is corrected (RelSem/T4.lean header + T4EnvHyp docstring + the
headline above). The transform's anon binders 1048577/1048578 are
supply increments, not further draws (no "third draw" exists). The
witness probe `t4-env-witness` (its own exe BY DESIGN — draw ordering
is its subject; module-init evaluation of the AppEq modules' closed
initial-state constants would shift the counter, so its import
closure mirrors Main's) now runs inside test_verify; first run
(verbatim):

```
ok   first process draw = 1048576 (got 1048576; post-increment from 1<<20)
ok   tag global: sizeof(struct S) = 8
ok   tag global: alignof(struct S) = 4
ok   tag global: struct S member offsets a=+0, b=+4 (got (some 0), (some 4))
ok   digest () = "" (got "")
ok   initial_driver_state sym-supply seed = 1048577 (got 1048577; the SECOND process draw)
ok   t4 memb(11) on the witnessed state = {Active Specified(11)}
T4EnvWitnessTest: ALL PASSED
```

### Audit-1 F4 — capped compliance (fixed)

`scripts/capped` gained a loud portability fallback (systemd-run
absent ⇒ two WARNING lines, proceed uncapped); routed through capped:
common.sh `build_lean`, test_unit.sh's per-exe `lake build`,
check_theorem_axioms.sh's two `lake env lean` probes, and the
Makefile `lean-build` target.

### Audit-1 F5 — outcome-set companions (exported)

`T?Outcomes : T?OutcomesStatement` (T4's under `T4EnvHyp`) are now
named theorems: `runND (callND …) (initial_driver_state …) =
[(Active (finalize … (drDone …)), [], drDone …)]` — "outcomes =
{Specified(·)}" literally, as a set equation on the fuel opsem. All
four are statement-gated (slate list 12 → 16) and Audit-pinned
exactly.

### Audit-1 F6 — pin provenance (gated)

test_verify.sh now re-derives each tests/verify/*.core from its .c
fixture via the oracle (`--nolibc --pp=core`) and byte-compares
against the pin, fail-closed (5/5 byte-identical at install).

### Audit-2 — record integrity + instruments (all dispositioned)

* **The ci re-run (closes the derived notes in success conditions 2
  and 5):** S5c re-ran the sweep at the audit-response head; outputs
  verbatim:

```
Total:          250
Cerberus parse: 128 ok, 122 failed
Lean parse:     128 ok, 0 failed
```

  (`./scripts/test_parse.sh tests/ci`, rc 0; test_core.sh tests/ci
  identical shape: `Cerberus --pp:  128 ok, 122 failed` /
  `Lean parse:     128 ok, 0 failed`, rc 0), and

```
SUMMARY: total=242 match=88 ub_match=22 ub_diff=0 mismatch=4 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=110 cerb_inconsistent=18

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/layer2/scripts/exec_ci_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

  (`./scripts/test_exec.sh --check-baseline=scripts/exec_ci_baseline.txt
  tests/ci`, rc 0 — the arc-6 scoreboard state, zero movement through
  the toolchain bump, the totalizations, AND the S5c instance
  eviction).
* **Statement-gate string-literal gap (audit-2 F2 class):** the
  wrapped string literals produced a five-space run in the gate's
  output; D9 and this doc quoted it single-spaced as if verbatim.
  Fixed the literals (string gaps); the D9 quote is relabeled DERIVED
  by a dated correction note appended to the decision log (history
  unrewritten), and this doc's success-condition-1 quote is marked
  DERIVED above. Pre-fix literal line, for the record (verbatim):

```
info: relsem/RelSem/Audit.lean:408:0: RelSem statement gate: 12 slate statements     fuel-opsem-clean (negative test: t1_wp correctly rejected)
```

* **D2's 5-vs-9 spike-commit count:** corrected by a dated appended
  note in the decision log (9 commits, verified by `git log`).
* **Arc-4 results stale boundary entry:** the CerbND "partial runND"
  declared-boundary line now carries a one-line SUPERSEDED pointer to
  this doc (arc-7 S2 totalization).
* **"Pins at close" completeness:** the sentence now names the
  extra_import declares among the arc's .lem edits (S2's
  CerbFunMapInstances + S5c's seven CerbCoreInstances lines).

### S5c validation at the audit-response head

Full Tier A (unit 5/5 + all gates incl. totality "16 generated
modules + hand-written CerbND, 0 allowlisted" and the D14/axiom-cone
checks; minimal/coverage/debug baselines rc 0; libc_exec; multi_tu;
parse ALL; core 106/106; elab recorded state; uri GATE PASS 16/16) +
test_verify 29/29 (5 fixtures + 5 pin-provenance + 18 harness points
+ t4-env-witness) + chvalid_battery_00 `MATCH … 1354 points` + the
tests/ci sweep above — every command rc 0, all through
scripts/capped where lake/lean is invoked.
