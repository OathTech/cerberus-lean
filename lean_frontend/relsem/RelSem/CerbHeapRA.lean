/-
  RelSem.CerbHeapRA — arc-16 S2 (2026-08-24): THE CERBMEM HEAP
  RESOURCE. Design record: docs/2026-08-24_arc16-s2-cerbmem-heap-ra.md
  (§1 the Caesium study, §2 the design; the inherit/deviate ledger is
  §1.3).

  Three ghost components over the per-step language's driver_state
  (Caesium's heapG shape, iris-lean vocabulary — all three libraries
  REUSED as-is, reuse discipline point 1):

    * the BYTE map: GenHeap at Address(Int) ↦ CerbMem.AbsByte — the
      library's fractional `a ↦{dq} b` IS our byte points-to;
    * the ALLOC table: ghost_map at AllocId(Int) ↦ CerbMem.Allocation
      (fragment `allocIs` = Caesium's freeable/alive token, deviation
      D1 of the study);
    * the REST cell: ghost_var at the remainder projection `restOf`
      (deviation D5 — our heap sits inside a larger machine state).

  THE TWO-FACES RULE: `CerbMemInterp` (the ONE authoritative map
  bundle + the pure `MemInv`) appears ONLY in the IrisGS instance and
  the adequacy/lifting plumbing; proof-level assertions are
  `pointsTo`/`pointsToBytes`/`allocIs`/`restIs` — footprints, big-ops
  for ranges, never flat ∗-chains (S0 measured the cliffs).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.BI.Lib.GenHeap
import Iris.Instances.Lib.GhostMap
import Iris.Instances.Lib.GhostVar
import Iris.ProgramLogic.WeakestPre
import RelSem.PerStepIris
import RelSem.MemLocal

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.BI Iris.ProgramLogic

/-! ## The TreeMap → ExtTreeMap reflection

    The physical maps are `Std.TreeMap` (structural — two equal-
    content trees can differ); the ghost layer needs the extensional
    quotient. `toExt` is the quotient injection; the get?/insert/erase
    commutations below are what keep ghost updates aligned with the
    physical operations. -/

def toExt {V : Type} (t : Std.TreeMap Int V) :
    Std.ExtTreeMap Int V compare :=
  ⟨Std.ExtDTreeMap.mk t.inner⟩

@[simp] theorem toExt_getElem? {V : Type} (t : Std.TreeMap Int V)
    (k : Int) : (toExt t)[k]? = t[k]? := rfl

theorem toExt_get? {V : Type} (t : Std.TreeMap Int V) (k : Int) :
    Std.PartialMap.get? (M := (Std.ExtTreeMap Int · compare)) (toExt t) k
      = t.get? k := rfl

theorem toExt_insert {V : Type} (t : Std.TreeMap Int V) (k : Int)
    (v : V) :
    toExt (t.insert k v)
      = Std.PartialMap.insert (M := (Std.ExtTreeMap Int · compare))
          (toExt t) k v := by
  apply Std.ExtTreeMap.ext_getElem?
  intro a
  show (t.insert k v)[a]? = ((toExt t).alter k (fun _ => some v))[a]?
  rw [Std.TreeMap.getElem?_insert, Std.ExtTreeMap.getElem?_alter]
  split <;> simp

theorem toExt_erase {V : Type} (t : Std.TreeMap Int V) (k : Int) :
    toExt (t.erase k)
      = Std.PartialMap.delete (M := (Std.ExtTreeMap Int · compare))
          (toExt t) k := by
  apply Std.ExtTreeMap.ext_getElem?
  intro a
  show (t.erase k)[a]? = ((toExt t).alter k (fun _ => none))[a]?
  rw [Std.TreeMap.getElem?_erase, Std.ExtTreeMap.getElem?_alter]
  split <;> simp

/-! ## The state projections -/

/-- The functor carrier both ghost maps share (declared before the
    projections so their SYNTACTIC type is the functor applied — the
    higher-order `H`-unification in the auth notations needs it). -/
abbrev CerbHeapF : Type → Type := (Std.ExtTreeMap Int · compare)

/-- The ghost byte heap's authoritative image. -/
def bytesOf (ms : CerbMem.MemState) :
    CerbHeapF CerbMem.AbsByte := toExt ms.bytemap

/-- The ghost allocation table's authoritative image. -/
def allocsOf (ms : CerbMem.MemState) :
    CerbHeapF CerbMem.Allocation := toExt ms.allocations

/-- The memory state minus the two ghost-tracked maps. -/
def memRest (ms : CerbMem.MemState) : CerbMem.MemState :=
  { ms with bytemap := Std.TreeMap.empty,
            allocations := Std.TreeMap.empty }

/-- The remainder projection: everything in the driver state except
    the two heap maps (deviation D5; the rest cell owns this). The
    projection is supply-passable by construction — a seed-parametric
    `core_run_state0` is just another value of the remainder
    (effect-threading forward-design constraint honored). -/
def restOf (σ : driver_state) : driver_state :=
  { σ with layout_state := memRest σ.layout_state }

/-! ## The resource class (HeapLangGS template, line for line) -/

class CerbHeapGpreS (GF : BundledGFunctors) extends InvGpreS GF where
  bytes_pre : genHeapPreS Int CerbMem.AbsByte GF CerbHeapF
  alloc_pre : GhostMapG GF Int CerbMem.Allocation CerbHeapF
  rest_pre : GhostVarG GF driver_state

attribute [reducible, instance] CerbHeapGpreS.bytes_pre
attribute [reducible, instance] CerbHeapGpreS.alloc_pre
attribute [reducible, instance] CerbHeapGpreS.rest_pre

class CerbHeapGS (GF : BundledGFunctors) where
  -- not an instance on purpose (HeapLang pattern): avoids diamonds
  -- with IrisGS_gen
  [invGS : InvGS_gen .hasLC GF]
  bytes : genHeapGS Int CerbMem.AbsByte GF CerbHeapF
  [alloc : GhostMapG GF Int CerbMem.Allocation CerbHeapF]
  allocName : GName
  [rest : GhostVarG GF driver_state]
  restName : GName

attribute [reducible, instance] CerbHeapGS.bytes
attribute [reducible, instance] CerbHeapGS.alloc
attribute [reducible, instance] CerbHeapGS.rest

variable {GF : BundledGFunctors}

/-! ## The proof-level assertions (the footprint face) -/

/-- Allocation-table fragment: Caesium's alive/freeable token in one
    (deviation D1): fractional knowledge that allocation `aid` is
    LIVE with record `al`; full ownership is the right to kill. -/
def allocIs [CerbHeapGS GF] (aid : Int) (dq : DFrac)
    (al : CerbMem.Allocation) : IProp GF :=
  (CerbHeapGS.allocName GF) ↪◯MAP[aid]{dq} al

/-- Rest-cell fragment (held in halves: the interpretation keeps one
    half, the prover the other — ghost_var's standard idiom). -/
def restIs [CerbHeapGS GF] (dq : DFrac) (r : driver_state) : IProp GF :=
  (CerbHeapGS.restName GF) ↪VAR{dq} r

/-- The prover-side half fraction. -/
abbrev restHalf : DFrac := .own (1 : Qp).half

/-- Byte-RANGE points-to: the Caesium `heap_mapsto` shape — a big-op
    of per-byte GenHeap points-to over the footprint. NEVER a flat
    ∗-chain in any statement (two-faces rule; ranges in goals stay
    footprint-sized, S0 §5). -/
def pointsToBytes [CerbHeapGS GF] (a : Int) (dq : DFrac)
    (bs : List CerbMem.AbsByte) : IProp GF :=
  iprop([∗list] i ↦ b ∈ bs, ((a + (i : Int)) ↦{dq} b))

@[simp] theorem pointsToBytes_nil [CerbHeapGS GF] {a : Int}
    {dq : DFrac} :
    pointsToBytes (GF := GF) a dq [] ⊣⊢ emp := by
  unfold pointsToBytes
  exact BigSepL.bigSepL_nil

theorem pointsToBytes_cons [CerbHeapGS GF] {a : Int} {dq : DFrac}
    {b : CerbMem.AbsByte} {bs : List CerbMem.AbsByte} :
    pointsToBytes (GF := GF) a dq (b :: bs)
      ⊣⊢ (a ↦{dq} b) ∗ pointsToBytes (a + 1) dq bs := by
  unfold pointsToBytes
  refine BigSepL.bigSepL_cons.trans ?_
  have h0 : a + ((0 : Nat) : Int) = a := by omega
  have hshift :
      (iprop([∗list] k ↦ y ∈ bs, ((a + ((k + 1 : Nat) : Int)) ↦{dq} y))
        : IProp GF)
      = iprop([∗list] k ↦ y ∈ bs, (((a + 1) + (k : Int)) ↦{dq} y)) :=
    BigSepL.bigSepL_eq_of_forall_eq (fun {k x} => by
      rw [show a + ((k + 1 : Nat) : Int) = (a + 1) + (k : Int) by omega])
  rw [h0, hshift]
  exact .rfl

/-! ## The state interpretation (the ONE authoritative face; appears
    only here and in adequacy/lifting plumbing) -/

@[reducible] def CerbMemInterp [CerbHeapGS GF] (σ : driver_state) :
    IProp GF :=
  iprop(genHeapInterp (bytesOf σ.layout_state) ∗
    ((CerbHeapGS.allocName GF) ↪●MAP allocsOf σ.layout_state) ∗
    ((CerbHeapGS.restName GF) ↪VAR{restHalf} restOf σ) ∗
    ⌜MemInv σ.layout_state⌝)

@[reducible] instance instCerbHeapStateInterp [CerbHeapGS GF] :
    StateInterp driver_state Empty GF where
  stateInterp σ _ _ _ := CerbMemInterp σ

/-- THE IrisGS instance for the per-step language under the heap
    interpretation. NOTE (recorded hazard, design §2.5): this is a
    SECOND interpretation route for `KDriveExpr` beside S1's OwnP one;
    a theorem context selects by class binder ([CerbHeapGS GF] here vs
    [CerbGS .hasLC GF] there) and no file may bind both in one WP
    statement. -/
@[reducible] instance instIrisGSCerbHeap [CerbHeapGS GF] :
    IrisGS_gen .hasLC KDriveExpr GF where
  invGS := CerbHeapGS.invGS
  numLatersPerStep _ := 0
  forkPost _ := iprop(True)
  stateInterp_mono σ ns obs nt := by
    let := @CerbHeapGS.invGS GF _
    iintro $

/-! ## Extraction laws (keep-form: pure fact out, resources back —
    what the lifting skeleton's `Hstep` premises consume) -/

/-- The interpretation carries the memory invariant. -/
theorem interp_meminv [CerbHeapGS GF] {σ : driver_state} :
    CerbMemInterp (GF := GF) σ ⊢
      ⌜MemInv σ.layout_state⌝ ∗ CerbMemInterp σ := by
  unfold CerbMemInterp
  iintro ⟨Hb, Ha, Hr, %Hinv⟩
  iframe Hb Ha Hr
  ipureintro
  exact ⟨Hinv, Hinv⟩

/-- Rest agreement: the prover's half pins the physical remainder. -/
theorem interp_rest_agree [CerbHeapGS GF] {σ : driver_state}
    {dq : DFrac} {r : driver_state} :
    CerbMemInterp (GF := GF) σ ∗ restIs dq r ⊢
      ⌜restOf σ = r⌝ ∗ CerbMemInterp σ ∗ restIs dq r := by
  unfold CerbMemInterp restIs
  iintro ⟨⟨Hb, Ha, Hr, %Hinv⟩, Hfrag⟩
  icombine Hr Hfrag gives %Hag
  iframe Hb Ha Hr Hfrag
  ipureintro
  exact ⟨Hag.2, Hinv⟩

/-- Allocation lookup: a fragment pins the physical table entry. -/
theorem interp_alloc_lookup [CerbHeapGS GF] {σ : driver_state}
    {aid : Int} {dq : DFrac} {al : CerbMem.Allocation} :
    CerbMemInterp (GF := GF) σ ∗ allocIs aid dq al ⊢
      ⌜σ.layout_state.allocations.get? aid = some al⌝ ∗
        CerbMemInterp σ ∗ allocIs aid dq al := by
  unfold CerbMemInterp allocIs
  iintro ⟨⟨Hb, Ha, Hr, %Hinv⟩, Hfrag⟩
  icombine Ha Hfrag gives %Hlk
  iframe Hb Ha Hr Hfrag
  ipureintro
  refine ⟨?_, Hinv⟩
  rw [← toExt_get? σ.layout_state.allocations aid]
  exact Hlk

/-- Byte lookup, single cell. -/
theorem interp_byte_lookup [CerbHeapGS GF] {σ : driver_state}
    {a : Int} {dq : DFrac} {b : CerbMem.AbsByte} :
    CerbMemInterp (GF := GF) σ ∗ (a ↦{dq} b) ⊢
      ⌜σ.layout_state.bytemap.get? a = some b⌝ ∗
        CerbMemInterp σ ∗ (a ↦{dq} b) := by
  unfold CerbMemInterp genHeapInterp pointsTo
  iintro ⟨⟨⟨%m, %Hdom, Hσ, Hm⟩, Ha, Hr, %Hinv⟩, Hpt⟩
  icombine Hσ Hpt gives %Hlk
  iframe Ha Hr Hpt
  isplitl []
  · ipureintro
    rw [← toExt_get? σ.layout_state.bytemap a]
    exact Hlk
  isplitl [Hσ Hm]
  · iexists m
    iframe Hσ Hm
    ipureintro
    exact Hdom
  · ipureintro
    exact Hinv

/-- Byte lookup over a RANGE: the pointwise facts the physical
    locality lemmas (`readBytesFrom_of_pointwise`) consume. -/
theorem interp_bytes_lookup [CerbHeapGS GF] {σ : driver_state}
    {a : Int} {dq : DFrac} {bs : List CerbMem.AbsByte} :
    CerbMemInterp (GF := GF) σ ∗ pointsToBytes a dq bs ⊢
      ⌜∀ i : Nat, (hi : i < bs.length) →
          σ.layout_state.bytemap.get? (a + (i : Int)) = some bs[i]⌝ ∗
        CerbMemInterp σ ∗ pointsToBytes a dq bs := by
  induction bs generalizing a with
  | nil =>
    iintro ⟨Hi, Hp⟩
    iframe Hi Hp
    ipureintro
    intro i hi
    cases hi
  | cons b bs ih =>
    iintro ⟨Hi, Hp⟩
    icases pointsToBytes_cons.mp $$ Hp with ⟨Hb, Hbs⟩
    icases interp_byte_lookup $$ [$Hi $Hb] with ⟨%H0, Hi, Hb⟩
    icases ih $$ [$Hi $Hbs] with ⟨%Hrest, Hi, Hbs⟩
    iframe Hi
    icases pointsToBytes_cons.mpr $$ [$Hb $Hbs] with Hp
    iframe Hp
    ipureintro
    intro i hi
    cases i with
    | zero => simpa using H0
    | succ j =>
      have hj : j < bs.length := by
        simpa [Nat.succ_lt_succ_iff] using hi
      have := Hrest j hj
      rw [show a + ((j + 1 : Nat) : Int) = (a + 1) + (j : Int) by omega]
      simpa using this

/-! ## Ghost transport: the physical writes' ghost images -/

/-- `writeList`'s image on the extensional side. -/
def extWriteList (m : CerbHeapF CerbMem.AbsByte) (a : Int) :
    List CerbMem.AbsByte → CerbHeapF CerbMem.AbsByte
  | [] => m
  | b :: bs =>
      extWriteList (Std.PartialMap.insert (M := CerbHeapF) m a b)
        (a + 1) bs

theorem toExt_writeList (t : Std.TreeMap Int CerbMem.AbsByte) (a : Int)
    (bs : List CerbMem.AbsByte) :
    toExt (writeList t a bs) = extWriteList (toExt t) a bs := by
  induction bs generalizing t a with
  | nil => rfl
  | cons b bs ih =>
    show toExt (writeList (t.insert a b) (a + 1) bs) = _
    rw [ih, toExt_insert]
    rfl

theorem bytesOf_writeBytesTo (ms : CerbMem.MemState) (a : Int)
    (bs : List CerbMem.AbsByte) :
    bytesOf (CerbMem.writeBytesTo ms a bs)
      = extWriteList (bytesOf ms) a bs := by
  rw [writeBytesTo_eq]
  exact toExt_writeList ms.bytemap a bs

theorem allocsOf_writeBytesTo (ms : CerbMem.MemState) (a : Int)
    (bs : List CerbMem.AbsByte) :
    allocsOf (CerbMem.writeBytesTo ms a bs) = allocsOf ms := by
  rw [writeBytesTo_eq]
  rfl

theorem memRest_writeBytesTo (ms : CerbMem.MemState) (a : Int)
    (bs : List CerbMem.AbsByte) :
    memRest (CerbMem.writeBytesTo ms a bs) = memRest ms := by
  rw [writeBytesTo_eq]
  rfl

theorem restOf_store (σ : driver_state) (a : Int)
    (bs : List CerbMem.AbsByte) :
    restOf { σ with layout_state :=
        CerbMem.writeBytesTo σ.layout_state a bs } = restOf σ := by
  unfold restOf
  rw [memRest_writeBytesTo]

/-! ## Ghost updates, byte layer (per-byte GenHeap moves under the
    big-op; the induction the two-faces rule pays for ONCE) -/

/-- Full-fraction range overwrite. -/
theorem bytes_update_ghost [CerbHeapGS GF]
    {m : CerbHeapF CerbMem.AbsByte} {a : Int}
    (new : List CerbMem.AbsByte) {old : List CerbMem.AbsByte}
    (hlen : new.length = old.length) :
    (genHeapInterp (GF := GF) m ∗ pointsToBytes a (.own 1) old) ⊢ |==>
      (genHeapInterp (extWriteList m a new)
        ∗ pointsToBytes a (.own 1) new) := by
  induction old generalizing m a new with
  | nil =>
    cases new with
    | nil =>
      simp only [extWriteList]
      iintro ⟨Hi, Hp⟩
      imodintro
      iframe Hi Hp
    | cons nb new => cases hlen
  | cons b old ih =>
    cases new with
    | nil => cases hlen
    | cons nb new =>
      simp only [extWriteList]
      iintro ⟨Hi, Hp⟩
      icases pointsToBytes_cons.1 $$ Hp with ⟨Hb, Hbs⟩
      imod genHeap_update (v₂ := nb) $$ [$Hi $Hb] with ⟨Hi, Hb⟩
      imod ih new (by simpa using hlen) $$ [$Hi $Hbs] with ⟨Hi, Hbs⟩
      imodintro
      iframe Hi
      iapply pointsToBytes_cons.2 $$ [$Hb $Hbs]

/-- `writeSeq`'s image on the extensional side (arc-18 R2: the write1
    walk rule's ladder). -/
def extWriteSeq (m : CerbHeapF CerbMem.AbsByte) (a : Int) :
    List (List CerbMem.AbsByte) → CerbHeapF CerbMem.AbsByte
  | [] => m
  | w :: ws => extWriteSeq (extWriteList m a w) a ws

theorem toExt_writeSeq (t : Std.TreeMap Int CerbMem.AbsByte) (a : Int)
    (ws : List (List CerbMem.AbsByte)) :
    toExt (writeSeq t a ws) = extWriteSeq (toExt t) a ws := by
  induction ws generalizing t with
  | nil => rfl
  | cons w ws ih =>
    show toExt (writeSeq (writeList t a w) a ws) = _
    rw [ih, toExt_writeList]
    rfl

/-- Full-fraction SEQUENTIAL range overwrite (`bytes_update_ghost`
    folded over a write ladder — the loop atom's ghost move, arc-18
    R2). The fragment lands at the LAST write's image. -/
theorem bytes_update_seq_ghost [CerbHeapGS GF]
    {m : CerbHeapF CerbMem.AbsByte} {a : Int}
    (ws : List (List CerbMem.AbsByte)) {old : List CerbMem.AbsByte}
    (hlens : ∀ w ∈ ws, w.length = old.length) :
    (genHeapInterp (GF := GF) m ∗ pointsToBytes a (.own 1) old) ⊢ |==>
      (genHeapInterp (extWriteSeq m a ws)
        ∗ pointsToBytes a (.own 1) (ws.getLastD old)) := by
  induction ws generalizing m old with
  | nil =>
    simp only [extWriteSeq, List.getLastD_nil]
    iintro ⟨Hi, Hp⟩
    imodintro
    iframe Hi Hp
  | cons w ws ih =>
    have hlw : w.length = old.length := hlens w (List.mem_cons_self ..)
    simp only [extWriteSeq, List.getLastD_cons]
    iintro ⟨Hi, Hp⟩
    imod bytes_update_ghost w hlw $$ [$Hi $Hp] with ⟨Hi, Hp⟩
    imod (ih (old := w)
      (fun w' hw' => (hlens w' (List.mem_cons_of_mem _ hw')).trans
        hlw.symm)) $$ [$Hi $Hp] with ⟨Hi, Hp⟩
    imodintro
    iframe Hi Hp

/-- Fresh-range allocation (the metaToken byproduct is dropped —
    deviation D6's neighborhood: we do not use GenHeap's meta). -/
theorem bytes_alloc_ghost [CerbHeapGS GF]
    {m : CerbHeapF CerbMem.AbsByte} {a : Int}
    (bs : List CerbMem.AbsByte)
    (hfresh : ∀ i : Nat, i < bs.length →
      Std.PartialMap.get? (M := CerbHeapF) m (a + (i : Int)) = none) :
    genHeapInterp (GF := GF) m ⊢ |==>
      (genHeapInterp (extWriteList m a bs)
        ∗ pointsToBytes a (.own 1) bs) := by
  induction bs generalizing m a with
  | nil =>
    simp only [extWriteList]
    iintro Hi
    imodintro
    iframe Hi
    iapply pointsToBytes_nil.2
    iempintro
  | cons b bs ih =>
    simp only [extWriteList]
    iintro Hi
    have h0 : Std.PartialMap.get? (M := CerbHeapF) m a = none := by
      have := hfresh 0 (by simp)
      simpa using this
    imod genHeap_alloc h0 (v := b) $$ Hi with ⟨Hi, Hb, Htok⟩
    iclear Htok
    have hfresh' : ∀ i : Nat, i < bs.length →
        Std.PartialMap.get? (M := CerbHeapF)
          (Std.PartialMap.insert (M := CerbHeapF) m a b)
          ((a + 1) + (i : Int)) = none := by
      intro i hi
      rw [Std.LawfulPartialMap.get?_insert_ne (by omega)]
      have := hfresh (i + 1) (by simpa using hi)
      rw [show a + ((i + 1 : Nat) : Int) = (a + 1) + (i : Int) by omega]
        at this
      exact this
    imod ih hfresh' $$ Hi with ⟨Hi, Hbs⟩
    imodintro
    iframe Hi
    iapply pointsToBytes_cons.2 $$ [$Hb $Hbs]

/-! ## The op-level interpretation updates (one per memory operation;
    the WP rules' `Hstep` update legs) -/

/-- Congruence helper: rewrite an interpretation at transported
    component images (dodges projection-of-literal pattern matching). -/
theorem CerbMemInterp_congr [CerbHeapGS GF] {σ' : driver_state}
    {B : CerbHeapF CerbMem.AbsByte} {A : CerbHeapF CerbMem.Allocation}
    {R : driver_state}
    (hb : bytesOf σ'.layout_state = B)
    (ha : allocsOf σ'.layout_state = A)
    (hr : restOf σ' = R) :
    CerbMemInterp (GF := GF) σ'
      = iprop(genHeapInterp B ∗
          ((CerbHeapGS.allocName GF) ↪●MAP A) ∗
          ((CerbHeapGS.restName GF) ↪VAR{restHalf} R) ∗
          ⌜MemInv σ'.layout_state⌝) := by
  subst hb; subst ha; subst hr; rfl

/-- STORE: full-fraction range overwrite on already mapped keys;
    allocation table, rest cell and invariant pass through. -/
theorem interp_store_update [CerbHeapGS GF] {σ : driver_state}
    {a : Int} (new : List CerbMem.AbsByte) {old : List CerbMem.AbsByte}
    (hlen : new.length = old.length)
    (hold : ∀ i : Nat, (hi : i < old.length) →
      σ.layout_state.bytemap.get? (a + (i : Int)) = some old[i]) :
    CerbMemInterp (GF := GF) σ ∗ pointsToBytes a (.own 1) old ⊢ |==>
      (CerbMemInterp { σ with layout_state :=
          CerbMem.writeBytesTo σ.layout_state a new }
        ∗ pointsToBytes a (.own 1) new) := by
  rw [CerbMemInterp_congr
    (σ' := { σ with layout_state :=
      CerbMem.writeBytesTo σ.layout_state a new })
    (bytesOf_writeBytesTo σ.layout_state a new)
    (allocsOf_writeBytesTo σ.layout_state a new)
    (restOf_store σ a new)]
  unfold CerbMemInterp
  iintro ⟨⟨Hb, Ha, Hr, %Hinv⟩, Hp⟩
  imod bytes_update_ghost new hlen $$ [$Hb $Hp] with ⟨Hb, Hp⟩
  imodintro
  iframe Hb Ha Hr Hp
  ipureintro
  exact Hinv.store hlen hold

/-- The rest image after a fresh-object allocation. -/
def restAlloc (σ : driver_state) (a : Int) : driver_state :=
  { σ with layout_state :=
      { memRest σ.layout_state with
        nextAllocId := σ.layout_state.nextAllocId + 1,
        lastAddress := a } }

/-- ALLOCATE (`mem_alloc_block`'s post-state, `initOpt = none`):
    consumes the prover's rest half (the bump counters move),
    produces the fresh allocation fragment and the uninitialized
    range points-to at the model's deterministic address (study
    deviation D4). -/
theorem interp_alloc_update [CerbHeapGS GF] {σ : driver_state}
    {r : driver_state} {pref : prefix0} {ty : ctype} {alignN : Int}
    {sz : Nat} {a : Int}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (σ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    CerbMemInterp (GF := GF) σ ∗ restIs restHalf r ⊢ |==>
      (CerbMemInterp { σ with layout_state := (CerbMem.writeBytesTo
            ({ σ.layout_state with
              nextAllocId := σ.layout_state.nextAllocId + 1,
              lastAddress := a,
              allocations := σ.layout_state.allocations.insert
                σ.layout_state.nextAllocId
                { base := a, size := sz, ty := some ty, prefix_ := pref } })
            a (List.replicate sz
                { prov := .Prov_none, copyOffset := none, value := none })) }
        ∗ restIs restHalf (restAlloc σ a)
        ∗ allocIs σ.layout_state.nextAllocId (.own 1)
            { base := a, size := sz, ty := some ty, prefix_ := pref }
        ∗ pointsToBytes a (.own 1)
            (List.replicate sz
              { prov := .Prov_none, copyOffset := none, value := none })) := by
  have hrange : a + sz ≤ σ.layout_state.lastAddress :=
    alloc_range_le haddr hnz
  rw [CerbMemInterp_congr
    (σ' := { σ with layout_state := (CerbMem.writeBytesTo
        ({ σ.layout_state with
          nextAllocId := σ.layout_state.nextAllocId + 1,
          lastAddress := a,
          allocations := σ.layout_state.allocations.insert
            σ.layout_state.nextAllocId
            { base := a, size := sz, ty := some ty, prefix_ := pref } })
        a (List.replicate sz
            { prov := .Prov_none, copyOffset := none, value := none })) })
    (B := extWriteList (bytesOf σ.layout_state) a
      (List.replicate sz
        { prov := .Prov_none, copyOffset := none, value := none }))
    (A := Std.PartialMap.insert (M := CerbHeapF)
      (allocsOf σ.layout_state) σ.layout_state.nextAllocId
      { base := a, size := sz, ty := some ty, prefix_ := pref })
    (R := restAlloc σ a)
    (by rw [bytesOf_writeBytesTo]; rfl)
    (by rw [allocsOf_writeBytesTo]; exact toExt_insert ..)
    (by unfold restOf restAlloc; rw [memRest_writeBytesTo]; rfl)]
  unfold CerbMemInterp restIs allocIs
  iintro ⟨⟨Hb, Ha, Hr, %Hinv⟩, Hrest⟩
  have hfreshA : Std.PartialMap.get? (M := CerbHeapF)
      (allocsOf σ.layout_state) σ.layout_state.nextAllocId = none := by
    unfold allocsOf
    rw [toExt_get?]
    exact Hinv.next_fresh
  have hfreshB : ∀ i : Nat,
      i < (List.replicate sz
        ({ prov := .Prov_none, copyOffset := none, value := none }
          : CerbMem.AbsByte)).length →
      Std.PartialMap.get? (M := CerbHeapF) (bytesOf σ.layout_state)
        (a + (i : Int)) = none := by
    intro i hi
    unfold bytesOf
    rw [toExt_get?]
    refine Hinv.bytemap_below_none ?_
    simp only [List.length_replicate] at hi
    omega
  imod bytes_alloc_ghost _ hfreshB $$ Hb with ⟨Hb, Hpts⟩
  imod ghost_map_insert _ _ hfreshA $$ Ha with ⟨Ha, Hfrag⟩
  imod ghost_var_update_halves (restAlloc σ a) _ _ _ $$ Hr Hrest
    with ⟨Hr, Hrest⟩
  imodintro
  iframe Hb Ha Hr Hrest Hfrag Hpts
  ipureintro
  exact Hinv.alloc hsz haddr hnz

/-- The rest image after a kill. -/
def restKill (σ : driver_state) (aid : Int) : driver_state :=
  { σ with layout_state :=
      { memRest σ.layout_state with
        deadAllocations := aid :: σ.layout_state.deadAllocations } }

/-- KILL (`mem_kill_block`'s post-state): consumes the full-fraction
    allocation fragment (= Caesium's freeable) and the rest half (the
    dead list moves). Byte points-to for the range is NOT consumed —
    the physical model keeps the bytes (study deviation D2); safety
    of later access rests on `allocIs` being gone. -/
theorem interp_kill_update [CerbHeapGS GF] {σ : driver_state}
    {r : driver_state} {aid : Int} {al : CerbMem.Allocation} :
    CerbMemInterp (GF := GF) σ ∗ restIs restHalf r
        ∗ allocIs aid (.own 1) al ⊢ |==>
      (CerbMemInterp { σ with layout_state :=
          { σ.layout_state with
            deadAllocations := aid :: σ.layout_state.deadAllocations,
            allocations := σ.layout_state.allocations.erase aid } }
        ∗ restIs restHalf (restKill σ aid)) := by
  rw [CerbMemInterp_congr
    (σ' := { σ with layout_state :=
      { σ.layout_state with
        deadAllocations := aid :: σ.layout_state.deadAllocations,
        allocations := σ.layout_state.allocations.erase aid } })
    (B := bytesOf σ.layout_state)
    (A := Std.PartialMap.delete (M := CerbHeapF)
      (allocsOf σ.layout_state) aid)
    (R := restKill σ aid)
    rfl
    (toExt_erase ..)
    (by unfold restOf restKill; rfl)]
  unfold CerbMemInterp restIs allocIs
  iintro ⟨⟨Hb, Ha, Hr, %Hinv⟩, Hrest, Hfrag⟩
  icombine Ha Hfrag gives %Hlk
  have hget : σ.layout_state.allocations.get? aid = some al := by
    rw [← toExt_get? σ.layout_state.allocations aid]
    exact Hlk
  imod ghost_map_delete _ _ $$ Ha Hfrag with Ha
  imod ghost_var_update_halves (restKill σ aid) _ _ _ $$ Hr Hrest
    with ⟨Hr, Hrest⟩
  imodintro
  iframe Hb Ha Hr Hrest
  ipureintro
  exact Hinv.kill hget

end Cerb
end RelSem
