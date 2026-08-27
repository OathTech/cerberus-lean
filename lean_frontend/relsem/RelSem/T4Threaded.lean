/-
  RelSem.T4Threaded — arc-18 R5 (2026-08-27): **T4 THROUGH THE
  SEGMENT LAYER** — the guarded ∀-seed struct-member theorem, PROVED
  (the arc-16 S4 park's priced fix, landed; the arc-17 S2/S3
  frontier's honest close).

  THE APARTNESS HYPOTHESIS (visible in the statement, by design): the
  unrestricted ∀-seed T4 statement is FALSE — the arc-16 S4 record's
  P3 collision falsifier is kernel-witnessed: at
  seed = 1680278659536745755 (= `a_529`'s hash number) the freshly
  drawn symbol IS the static `a_529` to the semantics
  (`symbolEquality` ignores the description), so the env insert
  captures the static binding. `T4SeedApart` excludes exactly the
  collision seeds: both fresh draws (`seed`, `seed + 1`) stay BELOW
  every static symbol number in t4File's vocabulary
  (kernel-computable bound; the ambient draw 1048577 satisfies it,
  the falsifier seed violates it). Under the hypothesis every
  anon-vs-static comparison is decided by the Kit/Env apartness
  dischargers — exactly what the R4 `seg_env_lookup` layer and the
  walk engine's omega lanes consume.

  The proof is the house shape: `verify_fn membSpec; seg_auto` over
  the registered equation supply (RelSem/T4Walks.lean — the two-walk
  drive `wa`/`wb`, 44 + 12 rounds, both evaluator mints at OPEN maps
  and OPEN seed under the apartness bound; zero hand-derived
  per-round equations). The driver atom is the ONE-SCRATCH
  MULTI-LAYER shape (`wpk_seq_scratch1p` — the scratch2 pointwise
  interface at one range): the struct object's whole lifetime
  (create / store-unspecified / two member stores through the
  NEG-store transform / read-back / kill) is internal to the
  equation; the errno object rides the frame.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T4Walks

set_option autoImplicit false

namespace RelSem.T4

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit RelSem.T4W
open RelSem.T1 (intRange)

/-! ## Statement data (fuel-opsem faces; first-order executable) -/

/-- T4's pure spec: the result value is the injected integer,
    Specified (read back through the struct member). -/
def t4Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue x

/-! ## The apartness hypothesis (kernel-computable, statement-visible) -/

/-- The minimum static symbol number in t4File's pinned vocabulary
    (derived from the emitted symbol table; every `Symbol "" n _` the
    program text mentions has `n ≥` this literal). -/
def t4MinStaticSym : Nat := 229457971439601039

/-- THE SEED-APARTNESS HYPOTHESIS: both fresh draws of the run
    (`seed`, `seed + 1` — the NEG-store transform's two binders) stay
    below every static symbol number. Decidable, boring, and TRUE of
    the ambient draw (1048577). NECESSITY is kernel-witnessed: the
    arc-16 S4 P3 falsifier — `symbolEquality
    (anon1_thr 1680278659536745755) symA529 = true` — shows the
    unguarded ∀-seed statement is FALSE (the drawn symbol captures
    the static `a_529` binding at that seed), so the guard is the
    honest boundary, not a convenience. -/
def T4SeedApart (seed : Nat) : Prop :=
  seed + 1 < t4MinStaticSym

/-- The threaded harness-environment hypotheses: the ambient
    `T4EnvHyp` minus the supply pin (the seed is now quantified) —
    the tag-table and TU-digest externs at the state the harness
    establishes (hypothesis-pins on opaque externs, exactly the
    ambient discipline). -/
def T4EnvHypThr : Prop :=
  CerbTags.tagDefs () = t4File.tagDefs ∧
  CerberusFresh.digest () = ""

/-! ## THE DRIVER ATOM (the composed segment through
    `driver2_of_seg`) -/

/-- THE DRIVER LOOP at open maps (`@[seg_eq scratch1p]`): the whole
    `driver2` atom characterized by the ready rest + v's footprint;
    the struct scratch's whole lifetime (create, the unspecified
    store, both member stores through the NEG-store transform's fresh
    draws, the read-back, kill) is internal to the equation; the
    errno object rides the frame. -/
@[seg_eq scratch1p]
theorem driver2_o (seed : Nat) (x : Int)
    (henv : T4EnvHypThr) (hap : T4SeedApart seed)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) : ∀ bm am,
    am.get? 0 = some allocV →
    (∀ i : Nat, (hi : i < (i32 x).length) →
      bm.get? (vAddr + (i : Int)) = some ((i32 x)[i])) →
    app (driver2 t4File.tagDefs false) (setMaps (rRdy4 seed) bm am)
      = (NDactive (), t4Fin seed x bm am) := by
  intro bm am halV hb
  rw [mkRdy_align seed bm am]
  refine Seg.driver2_of_seg rfl
    (((t4_run_seg seed x bm am henv.1 henv.2 hap hx1 hx2 halV hb).mono
      ?_ : Seg.SegDone _ lemDefaultFuel _ _)) rfl
  show 44 + 14 ≤ lemDefaultFuel
  rw [show lemDefaultFuel = 999999 + 1 from rfl]
  omega

/-! ## The terminal readout (the harness's `nd_get` + finalize) -/

/-- The finalize readout at the fixed final rest: the exit value. -/
theorem rDone4_readout (seed : Nat) (x : Int)
    (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation) :
    (finalize t4File.tagDefs "callND"
      (setMaps (rDone4 seed x) bm am)).dres_core_value = vD4 x := rfl

/-- The harness terminal's readout at the fixed final rest: the
    composed run returns exactly the injected integer. -/
@[seg_post]
theorem t4_post_o (seed : Nat) (x : Int) : ∀ bm am,
    ∃ r : driver_result,
      (Outcome.value (finalize t4File.tagDefs "callND"
          (setMaps (rDone4 seed x) bm am)) : DriveVal)
        = Outcome.value r ∧ t4Spec x r :=
  fun bm am => ⟨_, rfl, rDone4_readout seed x bm am⟩

/-! ## THE FnSpec + THE GUARDED STATEMENT -/

/-- T4's FnSpec ([F9]): `memb(x) = Specified x` for range x, under
    the guarded face (REDUCIBLE — the faces unify against the
    byte-stable statement text). The ∀-x INPUT FAMILY: `A = Int`. -/
abbrev membSpec : Seg.FnSpec Int :=
  { fname := "memb", args := fun x => [intValue x],
    pre := intRange,
    guard := fun seed => T4EnvHypThr ∧ T4SeedApart seed,
    post := t4Spec }

/-- THE T4 THREADED HEADLINE STATEMENT (fuel opsem only): under the
    threaded harness-environment hypotheses and the SEED-APARTNESS
    GUARD — visible, kernel-computable, with its necessity
    kernel-witnessed by the S4 P3 collision falsifier (see
    `T4SeedApart`) — every outcome of `callND(memb, [intValue x])`
    from the seed-parametric initial state is `Active r` with
    `r.dres_core_value = intValue x`. STRICTLY STRONGER than the
    ambient `T4Statement` (which pins the single ambient draw). -/
def T4ThreadedStatement : Prop :=
  T4EnvHypThr →
  ∀ (seed : Nat), T4SeedApart seed →
  ∀ x : Int, intRange x →
    CallHarnessAdequateThr seed t4File.tagDefs t4File "memb"
      [intValue x] t4Fs (t4Spec x)

/-- **T4 THREADED** (cone exactly the classical trio): the
    struct-member exit-criterion target at the guarded ∀-seed house
    form, THROUGH THE SEGMENT LAYER — a two-line proof. -/
theorem T4Threaded : T4ThreadedStatement := by
  verify_fn membSpec
  seg_auto

/-- **T4 THREADED UB-freedom** (same route). -/
theorem T4Threaded_ubFree :
    T4EnvHypThr →
    ∀ (seed : Nat), T4SeedApart seed →
      ∀ x : Int, intRange x →
        CallHarnessUBFreeThr seed t4File.tagDefs t4File "memb"
          [intValue x] t4Fs := by
  verify_fn membSpec
  seg_auto

end RelSem.T4
