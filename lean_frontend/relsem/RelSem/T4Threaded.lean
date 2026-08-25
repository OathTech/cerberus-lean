/-
  RelSem.T4Threaded — arc-17 S2 (2026-08-25): T4 AT THE GUARDED ∀-SEED
  STATE (charter S2 deliverable 3; the arc-16 S4 park's priced fix).

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
  dischargers — the ordered-map algebra this statement waited for.

  The run: driven by the S2 round evaluator (RelSem/RoundEval.lean)
  from the ready state; rounds the evaluator cannot mint (env-lookup
  evals at open seed) are law-derived by hand through Kit/Env.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.PerStepTactics
import RelSem.DeriveState
import RelSem.RoundEval
import RelSem.ConstructLaws
import RelSem.Kit.Env
import RelSem.T4Defs
import RelSem.T1AppEq
import RelSem.T4

set_option autoImplicit false

namespace RelSem.T4

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open RelSem.T1 (mkByte uninitByte intRange)
open Lem_Basic_classes (ordCompare)
open Iris Iris.ProgramLogic Iris.BI

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

/-! ## The threaded fixture data (writeBytesTo-form ladder — the Kit
    laws' computed-RHS spellings, the T6 idiom) -/

/-- Memory after the argument allocation (mem_alloc_block RHS form). -/
def memArgAllocT : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState with
      nextAllocId := 1, lastAddress := vAddr,
      allocations := Std.TreeMap.empty.insert 0 allocV }
    vAddr (List.replicate 4 uninitByte)

/-- Memory after the argument injection. -/
def memInjT (x : Int) : CerbMem.MemState :=
  CerbMem.writeBytesTo { memArgAllocT with funptrmap := [] } vAddr
    [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]

/-- Memory after the errno allocation. -/
def memErrAllocT (x : Int) : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { memInjT x with
      nextAllocId := 2, lastAddress := errAddr,
      allocations := (Std.TreeMap.empty.insert 0 allocV).insert 1 allocErr }
    errAddr (List.replicate 4 uninitByte)

/-- Memory after the errno block (the pre-run memory). -/
def memRdyT (x : Int) : CerbMem.MemState :=
  CerbMem.writeBytesTo { memErrAllocT x with funptrmap := [] } errAddr
    [mkByte 0 0, mkByte 0 1, mkByte 0 2, mkByte 0 3]

/-- `memb`'s Core body, projected from the emitted declaration. -/
def membBody : generic_expr core_run_annotation Unit sym :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) membT4Sym
      t4File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

/-- The ready thread. -/
def thRdyT : thread_state :=
  { arena := membBody,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal [(membT4Sym, CerbLocation.other "RelSem.callND")],
    env := [fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) symV
      (Vobject (OVpointer vPtr)) fmapEmpty],
    current_proc_opt := some membT4Sym }

/-! ## The named-state ladder (minted) -/

/-- Stage 1: driver_globals (t4 has none). -/
derive_state_step dGT (seed : Nat)
  from (driver_globals t4File.tagDefs false t4File)
  at (initial_driver_state_threaded seed t4File t4Fs)

derive_state_step kResT (seed : Nat)
  from (resolveFunSym (dGT seed).core_file "memb")
  at (dGT seed) expecting (dGT seed)

derive_state_step kBodyT (seed : Nat)
  from (lookupFunBody (dGT seed).core_file membT4Sym)
  at (dGT seed) expecting (dGT seed)

derive_state_step kTysT (seed : Nat)
  from (lookupParamTys (dGT seed).core_file membT4Sym)
  at (dGT seed) expecting (dGT seed)

/-- Post-injection driver state. -/
derive_state dInjT (seed : Nat) (x : Int) : driver_state :=
  { dGT seed with layout_state := memInjT x }

/-- Post-errno driver state. -/
derive_state dErrT (seed : Nat) (x : Int) : driver_state :=
  { dGT seed with layout_state := memRdyT x }

/-- The ready state — the driver loop's starting point. -/
derive_state dRdyT (seed : Nat) (x : Int) : driver_state :=
  { dErrT seed x with
    core_state0 := update_thread_state 0 thRdyT (dErrT seed x).core_state0 }

/-! ## THE DRIVER RUN — frontier 17 → 22 (arc-17 S3, THE ARITH
    MINTER; was: the S2b frontier at round 18)

    Arc-17 S3: the S2b-identified ARITH MINTER is BUILT (RoundEval —
    the Decidable/Bool verdict lanes over pack-bounded binders:
    `dec_eq_isTrue/False` proof-irrelevance bridges + omega side
    facts emitted as NAMED theorems, kernel decide for ground cases,
    the arith refold for omega's vocabulary, the decide-shape lane
    for dependent tower clusters, the type-check guard on verdict
    substitution, and the `.all` dig for smart-unfolding-hidden
    towers). Under the pack below the drive now mints TWENTY-TWO
    rounds mechanically: the round-18/19 conv RANGE CHECKS on the
    open x mint through exactly the identified recipe (the towers
    `match x + 2147483648 with | ofNat _ => isTrue … | negSucc _ =>
    isFalse …` become registered verdicts backed by `hrng1`/`hrng2`
    via omega), and the round-20 struct-member STORE of the
    x-symbolic value mints through `hi2b` (the int-store byte image,
    rfl-derivable).

    THE S3 MEASURED WALL — ROUND 23, the ANON-ENV REGION (parked;
    the S3 record carries the full diagnosis): resolving
    `PEsym anon1` at ∀-seed forces lookups through env maps that the
    earlier rounds MATERIALIZED into raw `Std.DTreeMap.Internal`
    trees; the seed-vs-static comparison towers hide INSIDE folded
    tree operations (smart unfolding refuses stuck-match unfolds at
    every transparency), and every mechanical route measured is
    either representation-level combat with the tree internals (the
    `.all` dig — repeated collisions with `._f` WF-auxiliary
    spellings; the trick-filter prong-2 tell) or an `fmapAddBy/
    fmapLookupBy` fence that breaks the evaluator's ground-defeq
    spine (classification, law unification, chain rfl side
    conditions — all measured). This is a NEW wall class beyond the
    S2b enumeration: the verdicts themselves mint fine; the
    CONSUMING spellings are not law-shaped and cannot be made
    law-shaped without a representation-level env model. DESIGN
    MOVERS (registered): an abstract env layer above the tree
    representation (the typed-view direction), or the effect-state
    threading that keeps anon draws out of comparator maps entirely
    (the [USER] machine-state end state). The ambient T4 (T4EnvHyp
    route) stands untouched; `T4ThreadedStatement` stands landed. -/

derive_rounds rT (seed : Nat) (x : Int)
  (hap : seed + 1 < 229457971439601039)
  (htags : CerbTags.tagDefs () = t4File.tagDefs)
  (hdig : CerberusFresh.digest () = "")
  -- the curated layout-fact vocabulary (each DERIVABLE from htags via
  -- the ambient T4AppEq facts — discharged at the final theorem):
  (hsz : CerbMem.sizeofCtype structSCty = 8)
  (halign : CerbMem.alignofIval structSCty
    = CerbMem.IntegerValue.IV .Prov_none 4)
  (hshiftA : CerbMem.memberShiftPtrval sPtr structSSym
    (Identifier CerbLocation.Loc.unknown "a") = sPtr)
  (hshiftB : CerbMem.memberShiftPtrval sPtr structSSym
    (Identifier CerbLocation.Loc.unknown "b") = bPtr)
  (hunspec : CerbMem.memValueToBytes [] (.MVunspecified structSCty)
    = ([], [CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
            CerbMem.paddingByte, CerbMem.paddingByte, CerbMem.paddingByte,
            CerbMem.paddingByte, CerbMem.paddingByte]))
  (hszI : CerbMem.sizeofCtype (Ctype [] (Basic (Integer (Signed Int_)))) = 4)
  -- x range (the conv checks' omega ammunition; intRange x at the
  -- statement):
  (hrng1 : -2147483648 ≤ x) (hrng2 : x ≤ 2147483647)
  -- x-symbolic value facts (the loads' byte roundtrips + the store's
  -- byte image — derivable from the ambient T4AppEq facts under
  -- intRange x):
  (hrecv : CerbMem.reconstructValue [] [] vAddr
    (Ctype [] (Basic (Integer (Signed Int_))))
    [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]
    = CerbMem.MemValue.MVinteger (Signed Int_)
        (CerbMem.IntegerValue.IV .Prov_none x))
  (hi2b : CerbMem.memValueToBytes []
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none x))
    = ([], [mkByte x 0, mkByte x 1, mkByte x 2, mkByte x 3]))
  assuming hap htags hdig hsz halign hshiftA hshiftB hunspec hszI hrng1 hrng2 hrecv hi2b
  using (t4File.tagDefs) 0 from (dRdyT seed x) upto 22

/-! ## THE GUARDED STATEMENT (landed; its theorem is the enumerated
    remaining work above) -/

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

end RelSem.T4
