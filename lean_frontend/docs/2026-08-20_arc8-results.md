# Arc-8 results: DAEMON elimination ("the consistent boundary") [AGENT:S4]

Date: 2026-08-20. Branch pair `arc/daemon-elim` (CERB + LEM). Charter:
`docs/2026-08-20_arc8-daemon-charter.md`; decisions D1–D7 + R1 in
`docs/2026-08-20_arc8-decision-log.md`; lem-side design + implementation
record in lem-lean `doc/notes/2026-08-20_arc8-inhabited-threading-design.md`;
work order CLOSED: `lembugs/2026-08-20_daemon-inconsistent-axiom.md`
(RESOLVED header added this slice).

Verbatim-transcript doctrine: quoted blocks are literal tool output
(sourced from the cited worker commit messages and the S4 re-runs);
derived tallies are labeled DERIVED.

## Headline

`axiom DAEMON : ∀ {α : Type}, α` — the logically INCONSISTENT axiom
(arc-7 audit-1 F1: `(DAEMON : Empty)` proves `False`, kernel-verified)
— and `DAEMON1`, their `@[implemented_by]` impls, and legacy `failwith`
are DELETED from LemLib and absent from the entire generated tree.
**T1–T4 (and every substrate pin in RelSem/Audit.lean) are now exactly
`[propext, runEffectful, Classical.choice, Quot.sound]` —
UNCONDITIONAL kernel certificates. The arc-7 "modulo the
unreachable-marker meta-assumption" qualifier is gone.** The first
TEMPORAL boundary-list mover has been executed, with fail-closed
absence gates making reintroduction a build failure forever after.
Zero movement across the full differential surface.

## Per-slice record

### S0 — cerberus-scale probe census (CERB `b513d28bc`, docs-only)

Record: `docs/2026-08-20_arc8-s0-probe-census.md`. All three designed
probe legs green plus the exploratory full ablation of every generated
`default := DAEMON` fallback (55 in the pristine tree): entire
tree-wide demand = 8 h-shaped monadic partial defs + 31 value-level
sites, discharged by 12 in-module real instances for 11 types,
converging green in 5 monotone rounds; the April class-1 killer
([Inhabited] leaking into partial-def signatures) did not recur, and
the census identified the mechanical reason (Lean 4.32.2's partial-def
Nonempty checker uses parameter witnesses + local instances).
Instance-method failwith census: 0. Verdict D1: **GO**, with conditions
carried into S1/S2. Orchestrator independently re-verified (both S0
commits docs-only, worktrees clean, test_unit re-run rc 0).
CENSUS ERRATA: see D6 below — the Class-T/M partition was partly wrong;
the design note's S2 record is the corrected reference.

### S1 — backend derives real Inhabited instances (LEM `446e799`)

lem's Lean backend: tier-2 types now get one bounded real instance PER
usable constructor (`[Inhabited tv]` bounds computed from field
analysis; first at default priority, rest `(priority := low)` — the
LemLib Sum precedent), planned in declaration order by
`lean_inhabited_prepass`, emitted in the type's own module. FAIL-CLOSED
(charter durability req 2): no usable constructor → NO instance, no
fallback; a backend-visible demand is a generation-time error naming
the type and both escape hatches. DAEMON no longer emitted in any
Inhabited instance. Comprehensive tests incl. not-in-corpus shapes +
negative probes (neg_inhabited_underivable pins the VERBATIM error;
neg_inhabited_fn_codomain). Verbatim from the S1 commit (lem side):

```
=== Generation: 36 passed, 0 failed, 0 skipped ===
Build completed successfully (105 jobs).
```

Cerberus scale (same slice, checkout lem per D2): `default := DAEMON`
count in generated/ 55 → 0 (measured); all 17 census-demanded types
carry derived instances; verbatim:

```
Build completed successfully (275 jobs).
Build completed successfully (227 jobs).
Total: 5 passed, 0 failed
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
```

(zero differential movement). Regeneration diff vs the mainline-lem
tree: 20 files — 15 exactly the DAEMON-fallback files, 5 fresh-name
index churn only (DERIVED tally, from the S1 commit). Orchestrator
boundary (D3): independently re-ran unit rc 0 + exec rc 0,
SUMMARY verbatim-matched; rule-4 interpretation ratified; two
pre-existing sorry-emission paths flagged → folded into S2 (D4).

### S2 — failwithI + selective [Inhabited] threading (LEM `0549d36`)

Every failure site emits axiom-free `LemLib.failwithI` (type-ascribed;
applied, multi-arg, and point-free alike); legacy failwith never
emitted. `lean_failwith_thread_prepass` adds `[Inhabited tv]`
instance-implicit binders to exactly the defs whose failure sites sit
at bare-tyvar positions, to a monotone fixpoint over the call graph —
ZERO call-site edits. Whole-invocation analysis pre-pass
(`lean_analysis_prepass_all`) flagged and ratified as D5. D4 executed:
BOTH backend sorry-emission paths eliminated (opaque types fail-closed
tier-2; `default_value`'s tyvar-sorry renderer DELETED). Guards:
tyvar-failwith-in-instance-method and phantom-tyvar demands are
generation-time errors (negative probes neg_failwith_instance_method,
neg_failwith_phantom). Verbatim (lem side):

```
=== Generation: 37 passed, 0 failed, 0 skipped ===
```

all 7 negative probes "OK (rejected as declared)", 553 PASS lines in
the suite log (DERIVED count), 0 FAIL. Cerberus scale (same slice):

```
Build completed successfully (275 jobs).
'driver2' depends on axioms: [propext, Classical.choice, Quot.sound]
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
```

— the driver2 cone DAEMON-FREE with DAEMON still declared (threading +
derivation alone evicted it), zero movement. One CERB hand edit
required: relsem/RelSem/Machine.lean `app_pick_singleton` gains
`[Inhabited S]` (pick's threaded signature; committed in S3). Regenerated-
tree greps: 0 non-failwithI failwith in code, 0 DAEMON in code, 0
`default := sorry`. Orchestrator boundary (bce31df10): independently
re-verified unit rc 0 (driver2 DAEMON-free pre-deletion), exec rc 0
byte-identical, LEM commit coherent.

**Census-errata story (D6, "pass right, census wrong"):** S2's computed
binder set = all 16 S0 Class-T defs + 7 library defs (CORRECTED from
"6" per auditor B F2 — the full set: Assert_extra.fail,
List_extra.head, List_extra.foldl1, List_extra.foldr1,
List_extra.findNonPure, Map_extra.find0, Maybe_extra.fromJust) + 13 extra
cerberus defs the census had classified M or missed. Root causes,
each recorded in the design-note S2 record: ndM's actual S1 instance
is `[Inhabited st]`-bounded (leg (a) had probed a hand-written
UNCONDITIONAL instance); the partial-def checker's strategy-2
reasoning does not apply to term-level instance synthesis at failwithI
sites; exceptM's Result-side bound reaches value-position tyvars; and
DEPTH-2 propagation exists (Core_typing defs inherit binders via
`Utils.fromJust`) — the census's "caller depth ≤ 1" claim was measured
only on the probed subset. All callers concrete; green build + zero
movement. **The design note's S2 record, not the census's Class
partition, is the corrected reference** (S3/S4 records cite it).

### S3 — deletion, regeneration, re-pin, absence gates (LEM `9d220e4`, CERB `f147aad91`)

LemLib deletes DAEMON, DAEMON1, DAEMON_impl, DAEMON1_impl, and legacy
`failwith`, with a history note banning any axiom-valued/unsafeCast
inhabitant reintroduction. CERB re-pins LemLib to `9d220e49ee1a` and
fully regenerates. RelSem/Audit.lean: DAEMON dropped from
allowedAxioms; the arc-7 DAEMON1 tripwire + entry-vector census walk
replaced by the fail-closed ABSENCE GATE (build fails if any constant
named DAEMON/DAEMON1 exists anywhere in the environment or is
allowlisted — scope note: "the environment" = the audit module's
import closure, per the auditor-B-F1 correction under durability req 3
below); all 84 curated pins (DERIVED count, corrected from "83"
per auditor B F3) re-baselined VERBATIM from a fresh probe. check_theorem_axioms.sh: the arc-3 D9 "DAEMON allowed in
driver2" allowance REMOVED — DAEMON unconditionally fatal in every
probed cone. Hand instance files retired to shells (fully removed in
S4, below). Verbatim from the S3 commit (all zero movement):

```
Total: 5 passed, 0 failed
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
```

Full differential surface at the S3 head (statuses verbatim from the
S3 commit message; one row per gate):

| Surface | Result (verbatim fragment) |
|---|---|
| lake build (default targets, capped) | rc 0 (597 jobs, in-build gates green) |
| test_unit.sh | `Total: 5 passed, 0 failed`, driver2 cone DAEMON-free |
| test_exec.sh tests/minimal | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0` BASELINE OK |
| test_exec.sh coverage | `total=199 mismatch=3` BASELINE OK, `0 regression(s), 0 improvement(s)` |
| test_exec.sh debug | `total=90 mismatch=1` BASELINE OK, `0 regression(s), 0 improvement(s)` |
| test_exec.sh tests/ci | `total=242 mismatch=4` BASELINE OK, `0 regression(s), 0 improvement(s)` |
| test_core.sh | 106/106 ALL PASSED |
| test_parse.sh | ALL PASSED |
| test_verify.sh | `29 passed, 0 failed` |
| test_multi_tu.sh | `total=2 match=2` |
| test_libc_exec.sh | `match=7 diff=0` |
| test_libxml2_uri.sh | `GATE PASS ... (16/16)` |
| test_libxml2.sh slice 00 | `total=1 match=1 fail=0 (points: 1354)` |

ZERO movement everywhere — the behavior-neutrality bar (charter S3)
holds. Panic semantics, stated accurately (wording corrected per
auditor A N2): failwithI IS a Lean `panic!` — under the harness
discipline (LEAN_ABORT_ON_PANIC=1, scripts/common.sh) it aborts; as a
plain library call it prints the panic message and continues with the
Inhabited default. Derived defaults are observable only post-panic —
or were, silently, at the L_undefined sites auditor A F1 found (now
fixed; see "Adversarial audits" below). No derived default is
observable in any differential. Orchestrator boundary (D7):
independently re-ran capped default build rc 0 (597 jobs, absence gate
+ audit sweep green), unit 5/5, verify 29/29, exec byte-identical;
LEM/CERB commits coherent, worktrees clean.

### S4 — close-out (this slice; CERB `fc7c5b0eb` + the docs commit)

**Plumbing removal (S3 parked item 1) — EXECUTED.** The 7
`declare {lean} extra_import CerbCoreInstances` declares removed from
frontend/model/{core_aux,core_eval,core_reduction,core_run_aux,driver,
formatted,translation_aux}.lem (declares-only; byte-exact reverse of
the arc-7 S5c 2fc699515 hunks); the two instance-free shells
CerbCoreInstances.lean / CerbInhabitedInstances.lean deleted (grep
first: ZERO references anywhere in generated/, hand files, relsem, or
tests — incl. the arc-2-era CerbInhabitedInstances, whose instances
were retired at S3); Makefile LEAN_HANDWRITTEN, lakefile.toml roots,
and Main.lean import cleaned (the sync gate parses LEAN_HANDWRITTEN,
so its list followed automatically: 21 files). Regenerated with the
checkout lem (D2) and re-gated; verbatim from the S4 runs:

```
Build completed successfully (593 jobs).
RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
RelSem statement gate: 16 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
RelSem audit sweep: 2141 declarations across RelSem.* modules, all within the declared axiom boundary (0 recorded sorryAx exceptions)
test_unit: sync gate OK (21 hand-written files byte-identical to generated/)
Total: 5 passed, 0 failed
'driver2' depends on axioms: [propext, Classical.choice, Quot.sound]
check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
```

(all rc 0; exec SUMMARY byte-identical to the S3 baseline. 597 → 593
jobs is the removal of the two shell modules from the two build
closures — DERIVED explanation.)

**Records:** lembugs entry RESOLVED; lean_frontend/CLAUDE.md de-staled
(lem-mechanism block now describes derivation + threading + fail-closed
path + absence gates; shell rows removed; arc-8 pipeline line); arc-7
results doc: one terminal addendum line (nothing rewritten). Merge
checklist: `docs/2026-08-20_arc8-merge-checklist.md`. LEM side: one
docs-only close-out commit (`47a6b24`, design-note close-out pointer;
lean-lib byte-identical to `9d220e4` — the checklist's pin-dance step 4
covers the resulting head-vs-pin delta).

## Boundary-list update

- **DAEMON TEMPORAL entry: mover EXECUTED, entry REMOVED.** The arc-7
  declared-boundary entry "DAEMON instance fallbacks (C-tier lem fix
  planned)" is closed: expected mover = this arc; the forward-design
  obligation is discharged by deletion. Its enforcement successor is
  the ABSENCE pair: the in-build RelSem absence gate + the
  check_theorem_axioms.sh arc-8 S3 bar (DAEMON unconditionally fatal).
- **Hand-written axiom census: still exactly 2** — `with_tagDefs`,
  `forceIO` (S4 verbatim: `check_theorem_axioms: hand-written axiom
  census OK (2 declared-boundary axioms)`). No new axiom, sorry, or
  opaque fallback anywhere.
- Remaining PERMANENT boundary entries unchanged (OCaml oracle, native
  C externs incl. runEffectful, kernel/compiler). Remaining TEMPORAL
  entries unchanged (concurrency/cmm stubs, upstream-bug mirrors, pp
  placeholders) — each still carries its mover.

## The durability contract (charter reqs 1–3, as landed)

1. **Mechanism, not patch:** derivation + threading are general
   backend passes computed from analysis (nothing hardcoded), fixpoint
   over the call graph, exercised in tests/comprehensive on shapes NOT
   in today's corpus.
2. **Fail-closed, no opaque fallback:** a type with no derivable
   Inhabited instance gets NO instance; any backend-visible demand on
   it is a LOUD GENERATION-TIME ERROR naming the type and the escape
   hatches (`skip_instances` + hand target_rep) — negative-probed
   (neg_inhabited_underivable pins the verbatim message). The backend
   can no longer emit sorry or any axiom-valued inhabitant anywhere
   (D4). Underivable-type failures are never silent and never deferred
   to Lean elaboration of downstream consumers.
3. **Permanent absence gates** (scope statement corrected per auditor
   B F1 — the original "environment scan" wording overstated the
   in-build gate's reach): in-build (Audit.lean, fail-closed, covers
   allowlist regressions) scans the IMPORT CLOSURE of the audited
   roots plus the probed cones — NOT every generated file; full-tree
   absence over lean_frontend/generated/ is enforced by the
   NAME-INDEPENDENT tree-wide axiom census added to
   check_theorem_axioms.sh (this audit-fix commit): every
   generated/*.lean is lexer-scanned for `axiom` declarations
   (allowlist exactly the two declared boundary axioms
   CerbTags.with_tagDefs / CerberusFresh.forceIO, each required
   present exactly once) and for `unsafeCast` (banned outright, no
   allowlist); missing dir / empty scan = FAIL. Script-level cone
   probes (check_theorem_axioms.sh) unchanged. Reintroduction =
   build/gate failure.

## Register items (dispositions at close)

- **R1 — `deriving BEq, Ord` fails on Sum-typed constructor fields**
  (LemLib lacks `Ord (Sum α β)`): pre-existing, surfaced by S1's ebox
  test, orthogonal to this arc. REGISTERED as a lem C-tier item,
  adjacent to the expr-family sorried-BEq item.
- **S2 residual: set-comprehension unsupported-feature `(sorry …)`
  stub** in lean_backend.ml (unreachable for the corpus): pre-existing,
  REGISTERED (C-tier). Not an Inhabited/default path.
- **S2 residual: polymorphic Let_defs emit no tyvar binders**
  (pre-existing shape limitation, unreachable-loud): REGISTERED
  (design-note S2 record).
- **S2 residual: BEq/Ord/SetType/Eq0/Ord0 `:= sorry` comparison
  bodies**: the pre-existing R1-class C-tier item, unchanged this arc.
- **User-written `sorry` target_rep pass-through** (sole corpus use:
  cmm_op concurrency stubs): the standing TEMPORAL boundary, unchanged.
- **S3 parked item 1 — extra_import plumbing removal:** EXECUTED this
  slice (CERB `fc7c5b0eb`).
- **S3 parked item 2 — lakefile LemLib pin comment** (mid-arc pin to
  `9d220e49ee1a` documented in-file): merge-checklist step (ff-only
  merge preserves the hash; comment-only update).
- **T5 (stretch):** NOT taken — parked again per the charter's
  park-clause (pricing stands in the arc-7 results doc).
- **Mirror-doctrine register — L_undefined rendering divergence
  (auditor A F1): CLOSED-BY-FIX.** The Lean backend rendered the
  L_undefined literal (pattern compiler's incomplete-match arm) as a
  silent bare `default`, diverging from the OCaml backend's raise —
  `failwith m` (src/backend.ml:864, `const_undefined` in module Ocaml
  at src/backend.ml:830). Undocumented divergence = defect as such
  (no differential failure required). FIXED in lem-lean `237867b`:
  L_undefined now emits an ascribed
  `(failwithI "<Incomplete Pattern at ...>" : tau)` with the same
  message OCaml raises; OCaml file:line citations in-code; panic-path
  pinned in tests/comprehensive (`lean-panic` target). 16 generated
  lines (15 Cmm_csem.lean, 1 Cmm_op.lean; 39 arm occurrences — all in
  today-unreachable concurrency modules) regenerated; zero
  differential movement (see "Adversarial audits" below).

## Adversarial audits (2026-08-20, post-close; dispositions executed in the audit-fix commits)

Two adversarial audits ran against the closed arc. Findings and
dispositions (evidence quotes summarized — DERIVED, not verbatim,
except where marked):

- **F1 (auditor A, MAJOR) — L_undefined emits silent `default`:
  FIXED** in lem-lean `237867b` (backend rendering → failwithI with
  the OCaml-mirrored message + comprehensive panic-path pin; the
  threading pre-pass was verified renderer-independent, so binder
  demand is unchanged) and validated at cerberus scale in this
  commit's regeneration: former bare-default incomplete-pattern
  sites 16 lines/39 arms → failwithI (grep: 0 `default /- Incomplete`
  remain), capped exe + default-target builds rc 0, test_unit 5/5,
  exec minimal SUMMARY byte-identical (zero movement), test_verify
  29/29. Register entry above (CLOSED-BY-FIX). Note the sites are in
  concurrency modules unreachable today — the fix is
  doctrine-driven, not differential-driven.
- **F1 (auditor B, MAJOR) — the in-build absence gate does not cover
  the full generated tree** (its "ANYWHERE in the environment"
  docstring overstated scope: the elaboration environment = the
  audit module's import closure; a generated file outside it, e.g.
  Core_indet.lean, was gate-invisible): **FIXED** in this commit —
  (1) NAME-INDEPENDENT tree-wide axiom census + unsafeCast ban over
  ALL of lean_frontend/generated/ added to check_theorem_axioms.sh
  (fail-closed; allowlist exactly with_tagDefs + forceIO, each
  required exactly once), negative-tested by planting
  `axiom SNEAKY : ∀ {α : Type}, α` in generated/Core_indet.lean
  (auditor B's exact vector) and an `unsafeCast` def — both runs
  FAILED (rc 1) with the planted lines named, plants reverted
  content-verified (md5), gate re-run green (verbatim outputs in
  this commit's message); (2) the overstated wording corrected in
  Audit.lean's docstring/comments and in durability req 3 above.
- **F2 (auditor B) — library binder set is 7 defs, not 6:**
  CORRECTED in the S2 census-errata paragraph above and in the
  lem-lean design note (full enumeration in both).
- **F3 (auditor B) — curated pin count is 84, not 83:** CORRECTED
  above (labeled DERIVED).
- **F4 (auditor B):** record-only — the merge checklist already
  flags the fallback in question as a deviation; no further action.
- **N2 (auditor A) — loose wording "failwithI panics before any
  default value escapes":** CORRECTED here (S3 behavior-neutrality
  paragraph) and in the design note: failwithI = Lean `panic!` —
  aborts under LEAN_ABORT_ON_PANIC=1; prints and continues with
  default as a plain library call; derived defaults observable only
  post-panic or at the (now-fixed) L_undefined sites.
- **N3 (auditor A):** PARTIALLY MITIGATED by the new
  name-independent generated-tree census (any `axiom` declaration in
  any generated file now fails the gate regardless of its name);
  residual: the in-build DAEMON/DAEMON1 leg remains name-based
  within its closure, and axioms living outside generated/,
  lean_frontend hand files, and every probed/audited cone (e.g. a
  hypothetical unused declaration inside the LemLib package) are
  still only caught when they enter a cone. Noted, not gated.
- **N4 (auditor A):** no action — already documented in-code and in
  the design note.

1. DAEMON/DAEMON1 absent from LemLib + generated tree, absence gates
   negative-tested; hand-axiom census exactly 2 — **MET**.
2. T1–T4 cones exactly `[propext, runEffectful, Classical.choice,
   Quot.sound]`; Audit.lean pins updated; statement gate green —
   **MET** (S3 + S4 verbatim above).
3. Full gate green at every commit, differential surface ZERO
   movement — **MET** (S3 table; S4 re-runs).
4. Mechanism general + fail-closed with negative probes and named-type
   errors — **MET** (S1/S2; durability contract above).
5. lem-suite green always paired with cerberus-scale validation —
   **MET** (every slice; no lem-only green claims).
6. Records complete, April requirement 8 revoked with provenance,
   pins aligned at close, merge checklist ready, mainlines untouched —
   **MET modulo the merge itself** (pins align at the pin dance;
   checklist prepared; merge is operator-gated).

Post-merge (orchestrator): container CLAUDE.md / ROADMAP updates,
including moving the arcs line and removing the DAEMON qualifier from
the container boundary-list prose.
