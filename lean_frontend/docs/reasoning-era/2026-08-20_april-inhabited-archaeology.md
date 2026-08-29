# April-2026 [Inhabited]-threading archaeology (read-only worker, 2026-08-20)

Operator question: "we already tried this strategy in April — why didn't it
work last time, and will it work this time?"

[USER] Operator recollection (relayed mid-dig): "we built this, it didn't
work *in cerberus*, then we had to roll it back." CONFIRMED by the record,
with one locational correction: the build-fail-rollback all happened in
**lem-lean's tree** (where the cerberus port lived until 2026-04-04 — the
first cerberus-lean frontend commit `6e151b259` says "Port 28 .lem files from
the lem-lean partial port"), so cerberus-lean itself has NO apply/revert
commit pair; its lean_frontend history starts Apr 4, one day AFTER the
rollback (`865d1f9`, Apr 3). The failure sequencing is exactly the operator's
memory: built Mar 6 (`c515e6d`), survived a month of lem's own test suite +
the ppcmem model (`d32d97d`, "ppcmem-model 10/10"), and died on FIRST CONTACT
with the cerberus .lem sources — the rollback ships inside the very commit
titled "Add Cerberus compatibility". **"Works in lem's tests, fails at
cerberus scale/shape" is confirmed** — see §B(0) and the probe requirement
in §D.

Executive answer: **the strategy now proposed (lembugs/2026-08-20_daemon-
inconsistent-axiom.md: failwithI everywhere + threaded `[Inhabited]` binders
on the enclosing generic defs + backend-derived real instances) was never
actually tried in April.** What April tried — twice — was `[Inhabited a]`
constraints on generated Inhabited *instance headers*, in a world where every
generated function was an unconstrained `partial def`. That collided with the
port (verbatim evidence below), was retreated from on 2026-04-03, retried on
2026-04-09 at 20:29 and deleted at 20:37 the same evening as a cost call once
`skip_instances` existed, and "does not require [Inhabited a] typeclass
constraints" was then written into the converged design as a requirement.
Every load-bearing element of that failure is structurally different today.
Verdict: **conditional yes** (§D), with a one-hour arc-8 S0 probe that
reproduces the April experiment on the current tree before any lem work.

All SHAs verifiable in-tree: lem-lean = `/home/dev/projects/cerberus-lean-proj/lem-lean`,
cerberus-lean = `/home/dev/projects/cerberus-lean-proj/cerberus-lean`.

---

## A. What the April mechanism actually was

The constraint threading lived only on **generated Inhabited instance
headers** for parameterized types — never on function signatures. Two lives,
two deaths:

**Life 1 — blanket header constraints (2026-03-06 → 2026-04-03).**
- `9e4f4eb` (Mar 6): first Inhabited instance generation in the Lean backend
  ("mirroring Coq's 'Definition T_default' generation. This ensures default
  values are available for all user-defined types" — the driver: Lean's
  `partial def` requires `Inhabited` of the return type, and April's backend
  emitted `partial def` pervasively).
- `c515e6d` (Mar 6, same day): emits `{a : Type} [Inhabited a]` on **every**
  parameterized instance header. Blanket: every tyvar of every parameterized
  type got the constraint.
- `c7f6159`/`d32d97d` (Mar 8): the constraint *spreads by entanglement* into
  the sorry Ord/SetType/Eq0/Ord0 instances; a special "bare BEq without
  [Inhabited]" variant had to be invented because "Lem-sourced Eq instances
  may not have [Inhabited]" (verbatim code comment). When `deriving BEq, Ord`
  arrived, downstream instances needed `[BEq a] [Ord a]` *in addition to*
  `[Inhabited a]` — a growing constraint calculus maintained by hand in the
  emitter.
- **Death 1: `865d1f9` (Apr 3, "Add Cerberus compatibility")** — the commit
  that first pointed the backend at the real Cerberus model removed the
  constraints. (Locus note: at this date the cerberus port WAS lem-lean's
  workload — cerberus .lem files entered lem-lean's test material the same
  week (`82254e7` "Cerberus test cases", `ae310d9` "merge cerberus files") and
  moved to the cerberus-lean repo only on Apr 4, `6e151b259`.) Verbatim code
  comments introduced by that commit:
  > "Parameterized types: always use sorry to avoid [Inhabited a]
  > constraints. This allows partial functions to compile without needing
  > constraints on their type parameters."
  > "Use unconstrained {a : Type} for parameterized types (no [Inhabited a])"
  and from its commit message: "Unconstrained sorry Ord: bare {a : Type}
  without [Inhabited a] so downstream types can use 'deriving Ord'."

**Life 2 — constrained headers + safe_indirect analysis (Apr 9, 20:29 → 20:37).**
- `f1a6509` (Apr 9 20:29, the `skip_instances` commit) reintroduced it:
  "[Inhabited a] constraints are added to the instance header so `default`
  works for type-variable args", plus a `safe_indirect` constructor analysis
  for parametric mutual blocks.
- **Death 2: `aaf7a64` (Apr 9 20:37 — eight minutes later).** Verbatim commit
  message:
  > "Now that skip_instances provides an escape hatch, the parametric type
  > Inhabited logic no longer needs complex safe_indirect analysis or
  > [Inhabited a] constraint propagation. Parameterized types use nullary
  > constructors when available (e.g. FNil), otherwise sorry. ...
  > Removes ~20 lines of constraint and cross-mutual analysis code."

**Convergence (Apr 9–10): DAEMON.** `e9553e9` (declare inhabited overrides) →
`e8dadf7` (sorry → `axiom DAEMON` for monomorphic fallbacks, "no init code,
no panic") → `89cb334` (DAEMON uniformly, DAEMON1 for Type 1) → `8648411`
(computable via `@[implemented_by unsafeCast]` — "fixes the incompatibility
with partial def (which requires computable Inhabited)"). The design note
written that day, lem-lean `doc/notes/2026-04-09_inhabited_design.md`, line 8,
codifies the requirement the fallback must satisfy:
> "Does not require `[Inhabited a]` typeclass constraints"
Cerberus-side same 48h: `1c57adf9e` (Apr 9: CerbInhabitedInstances born as
"overrides for all 40 sorry Inhabited defaults"), `1fb3942cc` (Apr 9: first
successful execution ever, + skip_instances for the noncomputable-cascade
types), `796b6fc56` (Apr 10: computable DAEMON wired through).

**What was never tried:** threading `[Inhabited a]` binders through generated
*def signatures* (backend pre-pass or lem-class based). The nearest approach —
arc-2 §14 option A, `failwith [Inhabited α] := default` with call sites
unchanged — was proposed 2026-08-18 and **withdrawn before trial** by the
arc-2 archaeology (§15 of cerberus-lean
`lean_frontend/docs/2026-08-18_effects-totality-design.md`): "A re-enters the
abandoned mechanism... closing their compile errors means re-implementing the
deleted machinery." That withdrawal produced the failwithI ground/tyvar split
instead (§16/§17) — i.e., the current tree deliberately *deferred* the tyvar
half rather than testing it.

## B. Why it failed / was abandoned — classified

**(0) The scale/shape finding ([USER]-prompted, confirmed): the mechanism
passed lem's test suite and failed only on cerberus contact.** Timeline
evidence: constraints in from Mar 6 (`c515e6d`); the whole lem comprehensive
suite + the ppcmem model built green under them for ~4 weeks (`d32d97d` Mar 8
"ppcmem-model 10/10", the Mar 9–10 coverage waves); first generation from the
cerberus .lem sources (working trees, Apr 3) → constraints removed the same
day (`865d1f9`). No error transcript survives, but `865d1f9` pins the
cerberus-shape failure classes as a **regression test**
(`tests/comprehensive/test_parameterized_instances.lem`, verbatim comments):
  1. > "Inhabited instance should use sorry without [Inhabited a] constraint,
     > so that partial functions returning this type compile."
     — the recursive-function class: every lem `let rec` over the
     parameterized Core/Cabs/Ail AST families becomes a Lean `partial def`,
     which demands `Inhabited` of its (parameterized) return type; under a
     constrained instance that demand becomes `[Inhabited a]` **on the def's
     own unconstrained signature**. Cerberus is wall-to-wall exactly this
     shape (generic_expr/generic_pexpr et al. are all multi-tyvar); lem's
     own suite and ppcmem had almost none of it.
  2. > "The sorry-based Ord instance on container 'a should NOT require
     > [Inhabited a], so that wrapper can use deriving BEq/Ord successfully."
     — the deriving-entanglement class: downstream `deriving BEq, Ord` on
     types *containing* parameterized types cannot supply the `[Inhabited a]`
     the base instances demanded.
Why this matters for arc 8: **a lem-suite-only probe is structurally unable
to reveal this failure mode** — the arc-8 first probe must run at cerberus
scale/shape (see §D).

Cerberus-lean-side negative results (searched, absent — recorded so nobody
re-digs): no revert/rollback/backout commits Feb–Jul 2026 (grep of all
branches incl. spike/relsem and the arc/* heads); no commit ever added a
generated file containing `[Inhabited ` signatures (pickaxe over
lean_frontend/generated, all branches); no April-era dead branches
(branch -a: the arc/* branches are all August); lembugs/ did not exist until
2026-08-19 (consistent with §15's doc-rot note). The apply-and-fail lived in
uncommitted Apr 3–4 working trees against the pre-`865d1f9` lem.

**(1) Technical failure — Life 1 only, and it is the real one.** Constrained
instance headers create `[Inhabited a]` *demands at use sites*: any
`partial def f {a : Type} ... : m a` (and in April essentially every
generated function was a `partial def`) needs `Inhabited (m a)`, which under
a constrained instance requires `[Inhabited a]` **on `f`'s own signature** —
and the backend had no mechanism to put it there, nor to propagate it to
`f`'s polymorphic callers. The `865d1f9` comment is the surviving verbatim
statement of the failure class: constraints on instances prevented "partial
functions to compile without needing constraints on their type parameters."
Secondary technical failure: instance-chain entanglement (Ord needs
Inhabited; deriving-based instances need `[BEq a] [Ord a]` too; hand-written
lem Eq instances carry neither). No error transcript survives; the
fine-grained mechanics in this paragraph are **reconstruction from the code
shape and comments, labeled as such** — but the direction (instances
constrained, defs not, port fails to compile) is stated in the record.

**(2) Cost judgment — Life 2.** The 8-minute Apr-9 revert records **no
compile failure at all**. Its stated reason is simplification: skip_instances
existed as the escape hatch, so ~20 lines of "complex safe_indirect analysis
[and] constraint propagation" were not worth keeping for the fallback path.
This was a complexity/ownership call made mid-crisis (the same session was
fighting init-time sorry panics — see below), not a recorded defeat of the
mechanism.

**(3) Interaction failures — the April backend was missing everything the
mechanism needed.** In April there was: no fuel totalization (hence `partial
def` everywhere ⇒ the Inhabited demand surface was *every partial def's
return type*, hundreds of sites — not just failure sites); no
failwithI/ground_rep classification (every `failwith` bottomed out in the
fallback instances); no `extra_import` (arrived `389a370`, Apr 11 — so hand
instances **could not even be wired into generated modules**; CerbInhabited-
Instances was an import leaf from birth); no reader machinery, no gates, no
differential baselines — indeed no working executable until `1fb3942cc`
mid-churn. Separately, the init-time-panic class (da293cd: "Inhabited sorry
on mutual types panics at module init (eager eval)") pushed the whole search
toward "generates no init code" — i.e., toward an axiom — rather than toward
making constraints work.

## C. What is different now — differential table

| # | April failure ingredient | State then | State now (2026-08-20) | Bears on the failure mode? |
|---|---|---|---|---|
| 1 | Instance infrastructure | None until mid-crisis; no way to import hand instances into generated modules | `CerbInhabitedInstances.lean` (arc-2 S5d: real bounded/unconditional monadic instances — ndM/nd_action unconditional, exceptM `[Inhabited msg]`-bounded) + `CerbCoreInstances.lean` (arc-7 S5c: 8/9 DAEMON fallback leaves evicted from slate cones, kernel-walked census verbatim in arc7-results) + `extra_import` wiring proven in 7 modules | YES — the hand corpus is an existence proof of the instance *designs* the backend would derive |
| 2 | Demand surface | Every `partial def` return type (blanket; hundreds of demands, unenumerated) | Exec slice fuel-totalized (empty partial allowlist); 232+ ground sites already on constraint-free `failwithI`; residue measured today: **73 bare-`failwith` occurrences in ~53 enclosing polymorphic defs across 14 generated files** (S5c kernel walk: only **7** functions + 1 same-module instance on the T1–T4 cones). CAVEAT: **318 `partial def`s remain** in the non-totalized generated modules (CoreParser 97, Cabs_to_ail 50, CabsImport 37, GenTyping 14, ...) — each still demands `Inhabited` of its return type, i.e. April failure class 1 is *reduced and localized*, not extinct (see risk 6) | YES for the failwith half; PARTIAL for the partial-def half — must be measured by the probe |
| 3 | Signature-touching pass machinery | Nonexistent; constraints were hand-woven into the instance emitter | Reader-lifting pre-pass (lean_backend.ml:105–200): fixpoint over the call graph, monotone lifted set, fail-closed instance-method guard — the proven template. [Inhabited] threading is strictly *easier*: instance-implicit binders mean **zero call-site edits at concrete types** (reader lift had to rewrite every call site) | YES — the missing mechanism now has a working precedent |
| 4 | Regression detection | First-ever executable run happened mid-churn; no gates | Totality/purity/axiom-cone/sync gates, Tier A ladder, differential baselines, in-build RelSem Audit.lean | YES — an April-style breakage would be caught in one gate run, not discovered as mystery panics |
| 5 | Toolchain | Lean ~4.26-era | Lean 4.32.2 | MINOR — instance resolution was never the recorded failure mode; do not lean on this |
| 6 | Motivation & shape of the plan | Blanket constraints as a *fallback convenience*; skip_instances made them optional | DAEMON is a kernel-verified **inconsistent axiom** (audit-1 F1 BLOCKER, `daemon_false` probe) — the mover is correctness of "kernel-checked"; the sketch is *selective* (binders only where a failwith-reaching site's type has free tyvars) + per-type derived instances, explicitly noting "NO single axiom over all `Type` can be consistent" | YES — different mechanism, different scope, different reason |

**A measurement the sketch needs (made today):** most of the ~53 legacy defs
do **not** need binder threading at all. The syntactic ground test (`no free
tyvars in the site type`, lean_backend.ml:1886–1894) is conservative:
`msum`/`pick`'s failure sites are at `ndM a info err cs st`, for which an
**unconditional** real instance already exists (CerbInhabitedInstances:59–63)
— resolution never touches `a`. Same for most exceptM/errorM-headed sites
(Core_linking, Core_run_aux, Translation_effect, Cabs_to_ail_effect...).
Those need only (i) classification relaxation or per-type derived instances
and (ii) in-module availability (the import-circularity limit: the hand file
imports Nondeterminism, so Nondeterminism's own sites can't see it — the
`instInhabitedAction_request2` precedent). The **true bare-tyvar class**
(`def f {a} ... : a := failwith ...`) is roughly **20–25 defs** (estimated
from today's def listing: nd_mem, warns_if_no_active_ex, log, insupported,
illTypedAil, fromLeft/fromRight, ~9 Defacto_memory `impl_*` daemon stubs,
Scope_table register/destroy/current/return_scope, Utils helpers,
typecheck_expr) — mostly leaf stubs; only these propagate binders to
polymorphic callers.

**Residual risks (honest list):**
1. **Instance-method sites.** Binders cannot be added to instance methods
   (the reader-lift limitation, lean_backend.ml:1109 fail-closed guard). If
   any legacy failwith sits inside a generated `instance`, it stays legacy or
   needs another mechanism. Un-censused — probe item.
2. **Function-field / higher-order storage.** A def that gains `[Inhabited a]`
   and is then stored point-free in a record field of plain function type
   leaves an unresolvable instance metavariable when `a` is undetermined.
   Fail-closed (compile error), but could force per-site reclassification.
3. **Transitive-closure size.** Unmeasured. If a bare-tyvar def's polymorphic
   callers reach widely-used combinators, churn grows. Expected small (the
   stubs are leaves), but this is exactly what the probe measures.
4. **Backend-derived instances are a hard prerequisite, and they are where
   the *actual* April technical difficulty lived** (safe constructor
   selection for parametric/mutual types — the safe_indirect problem).
   Mitigation: the CerbCoreInstances/CerbInhabitedInstances corpus is a
   ground-truth oracle for what correct answers look like on precisely the
   hard types (generic_expr family, ndM family), and "no derivable instance ⇒
   emit NO instance, visible compile error" (the sketch's rule 2) replaces
   April's sorry/DAEMON with fail-closed.
5. **Target neutrality.** Doing this as a lem *source-level* class constraint
   on `failwith` would leak into the Coq/HOL/Isabelle backends. It must be a
   Lean-backend pre-pass (reader-lift style) — more OCaml work than the
   lembug sketch's phrasing ("propagates exactly like lem's existing class
   constraints") suggests, though the generated code already routinely
   carries lem-class binders (`[MapKeyType b] [SetType b]`, `[Constraints cs]
   [Show info]`), so emission itself is established.
6. **The 318 residual partial defs (April class 1, localized).** Deleting the
   low-priority DAEMON fallback means every remaining `partial def` must
   resolve `Inhabited` of its return type against REAL instances. Where the
   real derived instance is `[Inhabited param]`-bounded and the enclosing
   partial def is polymorphic in that param, the April class-1 demand
   reappears and must be answered by the same threading pre-pass (or by an
   unconditional nullary-ctor instance for that type, or by totalizing the
   def). Un-censused: how many of the 318 are polymorphic with bounded-
   instance return types (the desugar-phase monads are largely concrete-
   state, so the expectation is few — but this is expectation, not
   measurement). The probe measures it.

## D. Verdict

**Conditional YES — the recorded April failure mode is structurally absent
from the proposed mechanism.** Load-bearing reasons:
1. April never tested signature threading; what failed was blanket
   instance-header constraints against a universe of unconstrained partial
   defs, plus a mid-crisis cost call. The historical "requirement" (design
   note line 8) was a requirement on the *fallback design of April*, not a
   discovered impossibility.
2. That universe is gone: totalization + failwithI reduced the demand
   surface from every partial def to ~53 enumerable defs, the majority
   dischargeable with zero threading via already-existing (or derivable)
   real instances.
3. The pass machinery pattern exists (reader lifting) and the threading
   variant is easier (instance-implicit ⇒ no call-site edits).
4. The gate net converts any April-style breakage from a mystery into a
   red gate line.

Conditions attached: (a) backend-derived real Inhabited instances must land
with the threading (same-module sites — msum/pick, action_request2 — are
unreachable by the eviction mechanism); (b) instance-method and
function-field sites censused before commitment, and either empty or
explicitly parked with a mechanism; (c) Lean-scoped backend pass, not a lem
source constraint; (d) the first probe runs at CERBERUS scale — see below.

**Arc-8 S0 probe — MUST be cerberus-scale (the §B(0) lesson is binding):**
the April mechanism was green in lem's comprehensive suite and ppcmem for a
month and died in hours on cerberus contact — the failure lives in shapes
(multi-tyvar mutual AST families, recursive functions over them, deriving
chains over parameterized containers) that lem's suite does not contain. So
the S5b-style pattern ("probes in lem's comprehensive suite ... BEFORE
touching cerberus") is NOT sufficient here as the first evidence; an
S5b-style lem-suite lane is fine later as the regression net, but the
go/no-go probe is on the real generated tree. Cheapest form (~1 hour, no lem
changes, hand-edit `generated/` in a worktree, build via
`../scripts/capped lake build cerberus-lean`):
1. Paste an in-module real `Inhabited (ndM ...)` instance above
   `msum`/`pick` in `generated/Nondeterminism.lean` (simulating a
   backend-derived instance) and switch their `failwith` to `failwithI` —
   tests the same-module + monadic-site class (the class the eviction
   mechanism could not reach).
2. Add `[Inhabited a]` binders + `failwithI` to 3 representative bare-tyvar
   defs — one leaf stub (`nd_mem` or `illTypedAil`), one Defacto_memory
   `impl_*` stub, one with known polymorphic callers (`fromLeft`/`fromRight`
   in Utils) — every downstream elaboration error IS the transitive demand
   set, enumerated by the compiler on the real codebase.
3. The April-class-1 leg (new, per the operator's recollection + risk 6):
   pick 2–3 polymorphic `partial def`s from the non-totalized modules
   (Cabs_to_ail / GenTyping / Core_typing) whose return types are
   parameterized, DELETE the low-priority DAEMON fallback instances their
   returns currently resolve to (comment them out in the generated file),
   supply bounded real instances instead, and see whether the partial defs
   still elaborate or now demand binders — this is the literal April
   experiment re-run on today's tree.
4. Grep-census: legacy `failwith` occurrences inside `instance` blocks and
   in point-free/field positions (risks 1–2); count of polymorphic partial
   defs with parameterized return types (risk 6 denominator).
Success = green build (or failures only at enumerable polymorphic callers)
⇒ commit the arc. Failure ⇒ the error list is the exact residue that
defeated April, now named per-def. This is the same experiment whose
April-era run produced the `865d1f9` retreat; a green run at cerberus scale
— the scale April never passed — is direct evidence the world has changed.

## Source index (all verified this session)

- lem-lean commits: 9e4f4eb, c515e6d, c7f6159, d32d97d, 865d1f9, da293cd,
  29166af, 711e390, 6ff237d, f1a6509 (20:29), aaf7a64 (20:37), e9553e9,
  e8dadf7, 89cb334, 8648411, 389a370
- lem-lean `doc/notes/2026-04-09_inhabited_design.md` (the requirement, line 8)
- cerberus-lean commits: 1c57adf9e, 1fb3942cc, 796b6fc56, 808cb3e1b
- cerberus-lean `lean_frontend/docs/2026-08-18_effects-totality-design.md`
  §14–§17, §19 (arc-2 archaeology, withdrawal of option A, S5c split, audit
  correction that failwithI sites still consume DAEMON fallbacks in-module)
- cerberus-lean `lean_frontend/docs/2026-08-20_arc7-results.md` audit
  addendum (F1 kernel census: 10 → 2 DAEMON referencers; verbatim probes)
- cerberus-lean `lean_frontend/lembugs/2026-08-20_daemon-inconsistent-axiom.md`
  (the C-tier design sketch this note assesses)
- lem-lean `src/lean_backend.ml` (reader pre-pass :105–200; ground/failwithI
  classification :1873–1894), `lean-lib/LemLib.lean` (:26–27 DAEMON,
  :115–147 failwithI/fuelExhaustedWith "April-2026 requirement" comments)
- cerberus-lean `lean_frontend/CerbInhabitedInstances.lean`,
  `CerbCoreInstances.lean`
- lem-lean `tests/comprehensive/test_parameterized_instances.lem` @ 865d1f9
  (the regression test pinning the two cerberus-shape failure classes)
- cerberus-lean `6e151b259` (Apr 4: "Port 28 .lem files from the lem-lean
  partial port" — locates the March/early-April cerberus workload in
  lem-lean's tree); negative searches: no revert commits Feb–Jul, no
  `[Inhabited ` pickaxe hits in lean_frontend/generated history, no
  April-era branches
- Measured today: 73 bare `failwith` occurrences / ~53 enclosing defs / 14
  files (generated tree); 56 `default := DAEMON` fallback instances (Cn 20,
  Core 14, AilSyntax 5, Nondeterminism 4, ...); 318 residual `partial def`s
  in non-totalized generated modules (CoreParser 97, Cabs_to_ail 50,
  CabsImport 37, GenTyping 14, ...); toolchain `leanprover/lean4:v4.32.2`.
