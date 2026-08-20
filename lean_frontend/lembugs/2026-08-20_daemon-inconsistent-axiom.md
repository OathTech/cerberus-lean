# DAEMON is an inconsistent axiom — TOP C-tier lem item [AGENT:S5c]

Date: 2026-08-20 (arc-7 audit-1 F1, BLOCKER-class; filed as the lem-lane
register item with the consistent-design sketch). Lem is UNTOUCHED this
arc — this file is the work order for the next time the pin moves.

## The defect

`lem-lean/lean-lib/LemLib.lean:26`:

```lean
@[implemented_by DAEMON_impl] axiom DAEMON : ∀ {α : Type}, α
```

is LOGICALLY INCONSISTENT: `(DAEMON : Empty)` proves `False`.
Kernel-verified reproducer (audit-1's daemon_false probe, re-run
2026-08-20 by S5c; output verbatim):

```
'daemon_false' depends on axioms: [DAEMON]
```

for

```lean
import LemLib
theorem daemon_false : False := (DAEMON : Empty).elim
#print axioms daemon_false
```

(exit 0 — the kernel ACCEPTS a proof of False from DAEMON alone).
`DAEMON1 : ∀ {α : Type 1}, α` (LemLib.lean:27) has the same defect one
universe up.

Consequence: any theorem whose axiom cone carries DAEMON is
kernel-checked only MODULO the meta-assumption that generated code uses
DAEMON solely as an unreachable-inhabitant marker — the kernel itself
certifies nothing for such a cone, since everything is derivable in an
inconsistent theory. The cerberus-side honesty package (RelSem/Audit.lean
boundary entry + the arc-7 results addendum) records this; the FIX is
lem-side.

## Current entry vectors (cerberus-lean, post arc-7 S5c eviction)

Kernel-walked leaf census of the T1–T4 slate cones (each leaf's VALUE
references DAEMON directly):

1. `LemLib.failwith` (`def failwith {α} (_ : String) : α := DAEMON`,
   LemLib.lean:176) — reached via 7 polymorphic generated functions:
   `foldl2`, `map2_` (Utils), `msum`, `pick` (Nondeterminism),
   `subst_pattern_val`, `update_env_aux` (Core_aux),
   `subst_wait_stack` (Core_run_aux). `pick` is on EVERY driver cone.
2. `instInhabitedAction_request2` (generated Core_reduction) — the
   backend's `(priority := low) … default := DAEMON` Inhabited
   fallback, demanded by `step_ctx` IN THE SAME MODULE, so the
   cerberus-side extra_import/priority-override eviction mechanism
   (arc-4 S1a; applied 2026-08-20 to evict the 8 other fallback
   leaves via CerbCoreInstances.lean) cannot reach it.

## The consistent design (sketch)

There is NO consistent single axiom of type `∀ {α : Type}, α` — that
type is uninhabited (it IS False at `α := Empty`). The replacement must
be per-type, not universal:

1. **failwith → failwithI everywhere.** The backend already emits
   `failwithI {α} [Inhabited α] (msg : String) : α := default` (opaque,
   arc-2 S5) at ground-typed sites. The C-tier item: emit failwithI at
   ALL sites, threading an `[Inhabited α]` binder through the enclosing
   generic function when the site's type is a type variable (lem knows
   the call graph; the binder requirement propagates exactly like lem's
   existing class constraints). Callers at concrete types then discharge
   the instance with REAL values.
2. **Inhabited fallbacks → derived real instances.** For each generated
   type, emit a real `Inhabited` instance where derivable: nullary or
   concrete-leaf constructor → unconditional instance; constructors
   needing type-parameter values → `[Inhabited param]`-bounded instance
   (the CerbInhabitedInstances/CerbCoreInstances patterns, generated
   instead of hand-written). Types with no derivable instance get NO
   instance — a use site that demands one becomes a VISIBLE compile
   error, never a hidden inconsistency.
3. **Delete DAEMON and DAEMON1** once (1)+(2) leave zero references.
   The @[implemented_by unsafeCast] runtime trick disappears with them;
   `failwithI`'s opaque-default implementation already provides the
   runtime behavior (panic-free unreachable default).

Acceptance test for the mover: the RelSem in-build audit's slate pins
drop DAEMON ("cones = [propext, runEffectful, Classical.choice,
Quot.sound]"), and the RelSem/Audit.lean DAEMON boundary entry +
tripwire are removed in the same commit.

## Priority

TOP of the C-tier lem queue (ahead of expr-family sorried BEq and
column-0 continuation emission): it is the only item that qualifies the
meaning of "kernel-checked" for the program's headline theorems.
