/-
  RelSem.TotalizationSmoke — thread-B lem totalization (2026-08-29).

  PROOF-LAYER SMOKE for the are_compatible totalization (record:
  docs/2026-08-29_threadB-totalization.md). Before this slice,
  `AilTypesAux.are_compatible` was a generated `partial def` —
  kernel-opaque: no whnf, no rfl, NO PROVABLE LAW (the V2/R6 root
  cause, docs/2026-08-27_arc18-r6-breadth-campaign.md §4.2, which
  blocked every two-function program at the call rule). It is now a
  plain def over a fuel worker (`declare {lean} fuel val`,
  frontend/model/ail/ailTypesAux.lem), so the kernel computes it and
  its unfolding equations fire. These lemmas are the DEMONSTRATION
  ARTIFACT the V4 call rules will consume — machinery smoke, not
  verification results (the ground points below are labeled as such;
  the quantified congruence law is the headline).

  Everything here closes by `rfl`; measured axiom cones (lean_probe,
  2026-08-29) are EXACTLY the classical trio
  {propext, Classical.choice, Quot.sound} — the project's pinned cone.
-/
import AilTypesAux
import RelSem.Threaded

set_option autoImplicit false

namespace RelSem.TotalizationSmoke

/-- The wrapper is kernel-transparent over the fuel worker (was: opaque
    partial-def constant with no equations at all). -/
theorem are_compatible_eq_fuel :
    are_compatible = are_compatible_lemFuel lemDefaultFuel := rfl

/-- QUANTIFIED unfolding law (the previously-unprovable class): pointer
    compatibility peels to referenced-type compatibility at one fuel
    step, for ALL qualifiers/annotations/referenced types. This is the
    equation shape the V4 call rule consumes at each internal call's
    are_compatible side condition. -/
theorem are_compatible_pointer_peel
    (n : Nat) (q1 q2 rq1 rq2 : qualifiers) (a1 a2 : List annot)
    (rt1 rt2 : ctype) :
    are_compatible_lemFuel (n + 1)
        (q1, Ctype a1 (Pointer rq1 rt1)) (q2, Ctype a2 (Pointer rq2 rt2))
      = (qualifiersEqual q1 q2
          && are_compatible_lemFuel n (rq1, rt1) (rq2, rt2)) := rfl

/-- Ground evaluation point (machinery smoke, NOT a verification
    result): the kernel now closes a concrete are_compatible call by
    computation — the exact side-condition discharge mode of the call
    rule. Impossible before totalization (partial def ⇒ no whnf). -/
theorem are_compatible_signed_int_ground :
    are_compatible (no_qualifiers, signed_int) (no_qualifiers, signed_int)
      = true := rfl

/-- Ground point through the mutual partner (params lists), exercising
    the cross-member fuel rewrite: a two-parameter prototype agrees
    with itself. Machinery smoke, NOT a verification result. -/
theorem are_compatible_params_ground :
    are_compatible_params
        [(no_qualifiers, signed_int, false), (no_qualifiers, unsigned_int, false)]
        [(no_qualifiers, signed_int, false), (no_qualifiers, unsigned_int, false)]
      = true := rfl

/-! ## runEffectful census item 1 — the seeded initial state bridge

The generated Lean-target-only `initial_core_run_state_seeded`
(frontend/model/core_run_aux.lem, thread-B slice; effect-spike route,
branch effect-spike @ 7f4100a5c) and the hand twin
`RelSem.Cerb.initial_core_run_state_threaded` (relsemcore
RelSem/Threaded.lean) MUST agree — per the no-internal-trust-gaps
doctrine that agreement is a THEOREM, not a mirror comment. -/

theorem initial_core_run_state_threaded_eq_seeded :
    RelSem.Cerb.initial_core_run_state_threaded
      = initial_core_run_state_seeded := rfl

end RelSem.TotalizationSmoke
