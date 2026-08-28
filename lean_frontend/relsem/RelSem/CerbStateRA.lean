/-
  RelSem.CerbStateRA — V1 (2026-08-28): THE DECOMPOSED MACHINE-STATE
  RESOURCE (the assertion layer; infrastructure plan component B).

  Replaces the arc-16 S2 `restIs` design (ONE ghost pin of the whole
  non-heap machine at a concrete state — the flaw that made locals
  unframeable and every proof concrete): Iris owns the machine-state
  components SEPARATELY, so an assertion can own one local
  symbolically while a step moves another component, the frame rule
  carrying everything untouched.

  Components (lineage per mechanism, canon-first):

    * BYTES    — GenHeap at Address(Int) ↦ CerbMem.AbsByte
                 (unchanged from S2; HeapLang gen_heap).
    * ALLOCS   — ghost_map at AllocId(Int) ↦ CerbMem.Allocation
                 (unchanged; Caesium freeable/alive token).
    * ENV      — ghost_map at SymNumber(Int) ↦ (sym × value): PER-CELL
                 local ownership `envIs x dq v` with SYMBOLIC v.
                 Lineage: gmap-authoritative locals view (RefinedC
                 locals-as-locations `l ◁ₗ ty` is the heap-allocated
                 analogue; for env-list machines the auth map is tied
                 to the physical env by a LOOKUP-LEVEL COHERENCE
                 invariant — the classical logical-view-of-physical-
                 state simulation move). See ENV COHERENCE below.
    * CTL      — ghost_var halves at the control-and-misc remainder
                 `ctlOf σ` (arena/stack/labels/trace/fs/…; env frames
                 spine-preserved but content-ERASED, supplies zeroed,
                 layout dropped). The exclusive control token —
                 the standard control-in-Iris move (ghost_var halves,
                 HeapLang idiom); the old rest cell, shrunk.
    * SUPPLY   — ghost_var halves at the four fresh-supply counters
                 (aligns with the V0 `ConsistentRun` formulation: the
                 sym-supply window is readable off this component).
    * MEMREST  — ghost_var halves at the memory-model residual
                 `memRestOf σ` (funptrmap, lastAddress, nextAllocId,
                 deadAllocations, …): the S2 study's deviation D5
                 refined — heap ops now pin ONLY memory components,
                 never the machine remainder.

  ENV COHERENCE (the design finding of this slice, recorded in the V1
  record): a projection-based per-cell env auth (gen_heap's exact-
  image pattern) is unprovable over LemLib's `Fmap` — the type carries
  captured comparator closures and no representation invariant, so no
  faithful cell-level projection exists for arbitrary values. Instead
  the interpretation holds an EXISTENTIALLY quantified auth map `e`
  tied to the physical env by lookups only:

      EnvCoh σ e :=
        ∀ n c, get? e n = some c →
          symNum c.1 = n ∧ envLookup σ c.1 = some c.2

  A fragment `envIs x dq v` therefore yields the pure fact
  `envLookup σ x = some v` (what step derivations consume), and env
  updates re-establish coherence POINTWISE from number-apartness — the
  Kit/Env lookup-through-insert suite (arc-17 S2) is the load-bearing
  lemma stock. Cells are born at adequacy time (the chosen initial
  tracked set) or by the env-write update; mid-run tracking-birth of
  an unowned cell needs negative domain information and is a V2
  design item (documented honest gap).

  Scope note: coherence speaks about the HEAD thread's scope stack
  (`thread0Env`) — the singleton-pool discipline every harness state
  satisfies; the cmm arc owns the multi-thread generalization.

  THE TWO-FACES RULE (S2 doctrine, unchanged): `CerbStInterp` (the
  authoritative bundle + pure invariants) appears ONLY in the IrisGS
  instance and adequacy/lifting plumbing; proof-level assertions are
  footprints (`envIs`/`pointsToBytes`/`allocIs`/`ctlIs`/`supIs`/
  `mrestIs`), never flat ∗-chains.

  Transitional twin note: this module lands BESIDE RelSem/CerbHeapRA
  (the exit-ramp discipline — never a flag-day rewrite); the shared
  pure layer (toExt, bytesOf, allocsOf, extWriteList, …) is duplicated
  here verbatim with provenance, and the old route is deleted at V1's
  close once the new adequacy is green.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.BI.Lib.GenHeap
import Iris.Instances.Lib.GhostMap
import Iris.Instances.Lib.GhostVar
import Iris.ProgramLogic.WeakestPre
import RelSem.PerStepIris
import RelSem.MemLocal
import RelSem.Kit.Map

set_option autoImplicit false

namespace RelSem
namespace CerbSt

open Iris Iris.BI Iris.ProgramLogic
open RelSem.Cerb

/-! ## The TreeMap → ExtTreeMap reflection (twin of CerbHeapRA's —
    the physical maps are structural, the ghost layer extensional) -/

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

/-- The shared extensional functor carrier (declared before the
    projections so their SYNTACTIC type is the functor applied). -/
abbrev CerbStF : Type → Type := (Std.ExtTreeMap Int · compare)

/-- The ghost byte heap's authoritative image. -/
def bytesOf (ms : CerbMem.MemState) : CerbStF CerbMem.AbsByte :=
  toExt ms.bytemap

/-- The ghost allocation table's authoritative image. -/
def allocsOf (ms : CerbMem.MemState) : CerbStF CerbMem.Allocation :=
  toExt ms.allocations

/-- The MEMORY-MODEL RESIDUAL: the memory state minus the two
    ghost-tracked maps (funptrmap, lastUsedUnionMembers, lastAddress,
    nextAllocId, deadAllocations, …). -/
def memRestOf (σ : driver_state) : CerbMem.MemState :=
  { σ.layout_state with bytemap := Std.TreeMap.empty,
                        allocations := Std.TreeMap.empty }

/-- The four fresh-supply counters, as their own component. -/
structure Supplies where
  tid : Nat
  aid : Nat
  exc : Nat
  symc : Nat
  deriving BEq, Repr

def suppliesOf (σ : driver_state) : Supplies :=
  { tid := σ.core_run_state0.tid_supply,
    aid := σ.core_run_state0.aid_supply,
    exc := σ.core_run_state0.excluded_supply,
    symc := σ.core_run_state0.sym_supply }

/-- Env erasure at one thread: the scope-stack SPINE is preserved
    (frame count — what `update_env`'s list matching consumes), the
    frame contents are dropped. Values live in the env ghost map. -/
def eraseThreadEnv (th : thread_state) : thread_state :=
  { th with env := th.env.map (fun _ => fmapEmpty) }

def eraseEnvs (cs : core_state) : core_state :=
  { cs with thread_states :=
      (cs.thread_states.map
        (fun p => (p.1, (p.2.1, eraseThreadEnv p.2.2)))) }

/-- THE CONTROL PROJECTION: everything except env contents, supplies,
    and memory. `layout_state` is pinned to the fixed initial value
    (carries no σ-information); supplies are zeroed; env frames are
    spine-erased. Supply-passable by construction (the effect-
    threading forward-design constraint: a seed-parametric
    `core_run_state0` differs only in the zeroed supply fields). -/
def ctlOf (σ : driver_state) : driver_state :=
  { σ with
      core_state0 := eraseEnvs σ.core_state0,
      core_run_state0 := { σ.core_run_state0 with
        tid_supply := 0, aid_supply := 0, excluded_supply := 0,
        sym_supply := 0 },
      layout_state := CerbMem.initialMemState }

/-! ## The env view -/

/-- A tracked env cell: the FULL symbol (digest included — the ghost
    key is the number alone, so the cell carries the sym to pin the
    digest) and its value. -/
abbrev EnvCell : Type := sym × value

/-- The ghost env key: the symbol's number. -/
def symNum : sym → Int
  | .Symbol _ n _ => (n : Int)

/-- The head thread's scope stack (singleton-pool discipline; see the
    header's scope note). -/
def thread0Env (σ : driver_state) : List (Fmap sym value) :=
  match σ.core_state0.thread_states with
  | p :: _ => p.2.2.env
  | [] => []

/-- The physical lookup the interpreter itself performs
    (generated/Core_aux.lean `lookup_env`, innermost frame first). -/
def envLookup (σ : driver_state) (x : sym) : Option value :=
  lookup_env x (thread0Env σ)

/-- ENV COHERENCE: every tracked cell's key is its symbol's number and
    its value is what the interpreter's own lookup returns. (One
    direction only: untracked cells are unconstrained — nobody owns
    them.) -/
def EnvCoh (σ : driver_state) (e : CerbStF EnvCell) : Prop :=
  ∀ (n : Int) (c : EnvCell),
    Std.PartialMap.get? (M := CerbStF) e n = some c →
    symNum c.1 = n ∧ envLookup σ c.1 = some c.2

/-- Coherence transports along lookup-monotone env moves (new binds
    may appear; every already-bound cell keeps its value). -/
theorem EnvCoh.mono {σ σ' : driver_state} {e : CerbStF EnvCell}
    (h : EnvCoh σ e)
    (henv : ∀ x v, envLookup σ x = some v → envLookup σ' x = some v) :
    EnvCoh σ' e := by
  intro n c hc
  obtain ⟨h1, h2⟩ := h n c hc
  exact ⟨h1, henv _ _ h2⟩

/-- Coherence is invariant under core_state0-preserving moves. -/
theorem envLookup_of_core_eq {σ σ' : driver_state}
    (h : σ'.core_state0 = σ.core_state0) :
    ∀ x, envLookup σ' x = envLookup σ x := by
  intro x
  unfold envLookup thread0Env
  rw [h]

/-! ## The env well-formedness invariant.

    MIRROR (structural, with attribution — operator directive
    2026-08-28): Caesium's `heap_state_ctx` carries the PURE physical
    invariant inside the state interpretation
    (deps/refinedc/theories/caesium/ghost_state.v:189-193:
    `⌜heap_state_invariant st⌝ ∗ heap_ctx … ∗ alloc_meta_ctx … ∗
    alloc_alive_ctx …`) — our `MemInv` and `EnvWf` conjuncts are the
    same move. THE CERBERUS DELTA (the retrofitting-locality work):
    Caesium's physical maps are stdpp `gmap`s, so their auth images
    are EXACT projections (`to_heapUR := fmap to_heap_cellR`,
    ghost_state.v:39-49) and no map well-formedness is needed;
    Cerberus's env frames are LemLib `Fmap`s carrying CAPTURED
    COMPARATOR CLOSURES — lookup-through-insert reasoning is only
    sound for frames whose captured comparator is the canonical sym
    order, so the interpretation must carry that as an invariant.
    `EnvWf` says exactly this: every frame of the head thread's scope
    stack is empty or built at `Kit.symCmpO` (the arc-18 `FmapBuilt`
    invariant, here promoted from per-instance hypothesis to
    interpretation conjunct). -/

/-- A well-formed env frame: empty, or built at the canonical sym
    comparator. -/
def EnvWfFrame (f : Fmap sym value) : Prop :=
  f = Fmap.empty ∨ RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO f

/-- Env well-formedness of a state (head thread's scope stack; the
    singleton-pool scope note applies). -/
def EnvWf (σ : driver_state) : Prop :=
  ∀ f ∈ thread0Env σ, EnvWfFrame f

theorem EnvWf_of_core_eq {σ σ' : driver_state}
    (h : σ'.core_state0 = σ.core_state0) (hwf : EnvWf σ) : EnvWf σ' := by
  intro f hf
  refine hwf f ?_
  unfold thread0Env at hf ⊢
  rw [h] at hf
  exact hf

/-! ## THE ENV DOMAIN LEDGER (V2 — the tracking-birth design).

    Mid-run tracking-birth of an env cell (`ghost_map_insert` into the
    coherence auth) needs NEGATIVE domain information: no symbol with
    the newborn's NUMBER may be physically bound, else the insert is
    unsound against a frame holding that cell. The footprint cannot
    supply this (V1's documented honest gap; coherence is
    one-directional). Resolution: a LEDGER — an exclusive ghost cell
    (halves) holding an OVERAPPROXIMATION `d : List Int` of the bound
    symbol numbers, tied to the physical env by the pure invariant
    `EnvDom σ d` (bound ⇒ listed) riding the interpretation. The
    prover's half makes freshness DECIDABLE (`symNum x ∉ d`), and the
    birth rule's frame-preserving update mints the cell — the exact
    gen_heap alloc-fresh shape (HeapLang `wp_alloc`: lastAddress-style
    ledger + freshness side condition ⇒ mint), transplanted from
    addresses to symbol numbers. The ledger only ever GROWS (pops
    remove bindings, which preserves an overapproximation); stale
    entries cost only re-birth capability, never soundness. -/

/-- The ledger invariant: every physically bound symbol's number is
    listed (one direction — the ledger overapproximates). -/
def EnvDom (σ : driver_state) (d : List Int) : Prop :=
  ∀ (z : sym) (v : value), envLookup σ z = some v → symNum z ∈ d

theorem EnvDom.of_env_eq {σ σ' : driver_state} {d : List Int}
    (h : EnvDom σ d) (henv : thread0Env σ' = thread0Env σ) :
    EnvDom σ' d := by
  intro z v hz
  refine h z v ?_
  rw [show envLookup σ' z = envLookup σ z from by
    unfold envLookup; rw [henv]] at hz
  exact hz

/-- No-thread states have empty ledgers (the initial harness face). -/
theorem EnvDom_of_no_threads {σ : driver_state}
    (h : thread0Env σ = []) : EnvDom σ [] := by
  intro z v hz
  unfold envLookup at hz
  rw [h] at hz
  cases hz

/-! ## The resource classes (HeapLangGS template) -/

class CerbStGpreS (GF : BundledGFunctors) extends InvGpreS GF where
  bytes_pre : genHeapPreS Int CerbMem.AbsByte GF CerbStF
  alloc_pre : GhostMapG GF Int CerbMem.Allocation CerbStF
  env_pre : GhostMapG GF Int EnvCell CerbStF
  ctl_pre : GhostVarG GF driver_state
  sup_pre : GhostVarG GF Supplies
  mrest_pre : GhostVarG GF CerbMem.MemState
  dom_pre : GhostVarG GF (List Int)

attribute [reducible, instance] CerbStGpreS.bytes_pre
attribute [reducible, instance] CerbStGpreS.alloc_pre
attribute [reducible, instance] CerbStGpreS.env_pre
attribute [reducible, instance] CerbStGpreS.ctl_pre
attribute [reducible, instance] CerbStGpreS.sup_pre
attribute [reducible, instance] CerbStGpreS.mrest_pre
attribute [reducible, instance] CerbStGpreS.dom_pre

class CerbStGS (GF : BundledGFunctors) where
  -- not an instance on purpose (HeapLang pattern): avoids diamonds
  [invGS : InvGS_gen .hasLC GF]
  bytes : genHeapGS Int CerbMem.AbsByte GF CerbStF
  [alloc : GhostMapG GF Int CerbMem.Allocation CerbStF]
  allocName : GName
  [envG : GhostMapG GF Int EnvCell CerbStF]
  envName : GName
  [ctlG : GhostVarG GF driver_state]
  ctlName : GName
  [supG : GhostVarG GF Supplies]
  supName : GName
  [mrestG : GhostVarG GF CerbMem.MemState]
  mrestName : GName
  [domG : GhostVarG GF (List Int)]
  domName : GName

attribute [reducible, instance] CerbStGS.bytes
attribute [reducible, instance] CerbStGS.alloc
attribute [reducible, instance] CerbStGS.envG
attribute [reducible, instance] CerbStGS.ctlG
attribute [reducible, instance] CerbStGS.supG
attribute [reducible, instance] CerbStGS.mrestG
attribute [reducible, instance] CerbStGS.domG

variable {GF : BundledGFunctors}

/-! ## The proof-level assertions (the footprint face) -/

/-- The prover-side half fraction of the exclusive components. -/
abbrev stHalf : DFrac := .own (1 : Qp).half

/-- The control token (halves: the interpretation keeps one half, the
    prover the other). -/
def ctlIs [CerbStGS GF] (dq : DFrac) (c : driver_state) : IProp GF :=
  (CerbStGS.ctlName GF) ↪VAR{dq} c

/-- The supply-counter component. -/
def supIs [CerbStGS GF] (dq : DFrac) (s : Supplies) : IProp GF :=
  (CerbStGS.supName GF) ↪VAR{dq} s

/-- The memory-model residual component. -/
def mrestIs [CerbStGS GF] (dq : DFrac) (mr : CerbMem.MemState) :
    IProp GF :=
  (CerbStGS.mrestName GF) ↪VAR{dq} mr

/-- THE DOMAIN LEDGER token (halves): the bound-symbol-number
    overapproximation the birth rule consults. -/
def domIs [CerbStGS GF] (dq : DFrac) (d : List Int) : IProp GF :=
  (CerbStGS.domName GF) ↪VAR{dq} d

/-- ENV POINTS-TO: ownership of ONE local, value SYMBOLIC. The cell
    carries the full symbol; the ghost key is its number. -/
def envIs [CerbStGS GF] (x : sym) (dq : DFrac) (v : value) : IProp GF :=
  (CerbStGS.envName GF) ↪◯MAP[symNum x]{dq} ((x, v) : EnvCell)

/-- Allocation-table fragment (unchanged shape from S2). -/
def allocIs [CerbStGS GF] (aid : Int) (dq : DFrac)
    (al : CerbMem.Allocation) : IProp GF :=
  (CerbStGS.allocName GF) ↪◯MAP[aid]{dq} al

/-- Byte-RANGE points-to (unchanged shape from S2). -/
def pointsToBytes [CerbStGS GF] (a : Int) (dq : DFrac)
    (bs : List CerbMem.AbsByte) : IProp GF :=
  iprop([∗list] i ↦ b ∈ bs, ((a + (i : Int)) ↦{dq} b))

@[simp] theorem pointsToBytes_nil [CerbStGS GF] {a : Int}
    {dq : DFrac} :
    pointsToBytes (GF := GF) a dq [] ⊣⊢ emp := by
  unfold pointsToBytes
  exact BigSepL.bigSepL_nil

theorem pointsToBytes_cons [CerbStGS GF] {a : Int} {dq : DFrac}
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

/-! ## The state interpretation (the ONE authoritative face) -/

@[reducible] def CerbStInterp [CerbStGS GF] (σ : driver_state) :
    IProp GF :=
  iprop(genHeapInterp (bytesOf σ.layout_state) ∗
    ((CerbStGS.allocName GF) ↪●MAP allocsOf σ.layout_state) ∗
    (∃ e : CerbStF EnvCell,
      ((CerbStGS.envName GF) ↪●MAP e) ∗ ⌜EnvCoh σ e⌝) ∗
    (∃ d : List Int,
      ((CerbStGS.domName GF) ↪VAR{stHalf} d) ∗ ⌜EnvDom σ d⌝) ∗
    ((CerbStGS.ctlName GF) ↪VAR{stHalf} ctlOf σ) ∗
    ((CerbStGS.supName GF) ↪VAR{stHalf} suppliesOf σ) ∗
    ((CerbStGS.mrestName GF) ↪VAR{stHalf} memRestOf σ) ∗
    ⌜MemInv σ.layout_state⌝ ∗ ⌜EnvWf σ⌝)

@[reducible] instance instCerbStStateInterp [CerbStGS GF] :
    StateInterp driver_state Empty GF where
  stateInterp σ _ _ _ := CerbStInterp σ

/-- THE IrisGS instance for the per-step language under the decomposed
    interpretation. Route-selection hazard (S2 note, carried): a
    theorem context selects the interpretation by class binder
    ([CerbStGS GF]); no file may bind two interpretation classes in
    one WP statement (gate-enforced). -/
@[reducible] instance instIrisGSCerbSt [CerbStGS GF] :
    IrisGS_gen .hasLC KDriveExpr GF where
  invGS := CerbStGS.invGS
  numLatersPerStep _ := 0
  forkPost _ := iprop(True)
  stateInterp_mono σ ns obs nt := by
    let := @CerbStGS.invGS GF _
    iintro $

/-! ## Extraction laws (pure fact out, resources back) -/

/-- The interpretation carries the memory invariant. -/
theorem interp_meminv [CerbStGS GF] {σ : driver_state} :
    CerbStInterp (GF := GF) σ ⊢
      ⌜MemInv σ.layout_state⌝ ∗ CerbStInterp σ := by
  unfold CerbStInterp
  iintro ⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩
  iframe Hb Ha He Hd Hc Hs Hm
  ipureintro
  exact ⟨Hinv, Hinv, Hwf⟩

/-- The interpretation carries env well-formedness (the Caesium
    `heap_state_invariant`-conjunct move, ghost_state.v:189-193). -/
theorem interp_envwf [CerbStGS GF] {σ : driver_state} :
    CerbStInterp (GF := GF) σ ⊢
      ⌜EnvWf σ⌝ ∗ CerbStInterp σ := by
  unfold CerbStInterp
  iintro ⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩
  iframe Hb Ha He Hd Hc Hs Hm
  ipureintro
  exact ⟨Hwf, Hinv, Hwf⟩

/-- Control agreement: the prover's token pins the control image. -/
theorem interp_ctl_agree [CerbStGS GF] {σ : driver_state}
    {dq : DFrac} {c : driver_state} :
    CerbStInterp (GF := GF) σ ∗ ctlIs dq c ⊢
      ⌜ctlOf σ = c⌝ ∗ CerbStInterp σ ∗ ctlIs dq c := by
  unfold CerbStInterp ctlIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hfrag⟩
  icombine Hc Hfrag gives %Hag
  iframe Hb Ha He Hd Hc Hs Hm Hfrag
  ipureintro
  exact ⟨Hag.2, Hinv, Hwf⟩

/-- Supply agreement. -/
theorem interp_sup_agree [CerbStGS GF] {σ : driver_state}
    {dq : DFrac} {s : Supplies} :
    CerbStInterp (GF := GF) σ ∗ supIs dq s ⊢
      ⌜suppliesOf σ = s⌝ ∗ CerbStInterp σ ∗ supIs dq s := by
  unfold CerbStInterp supIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hfrag⟩
  icombine Hs Hfrag gives %Hag
  iframe Hb Ha He Hd Hc Hs Hm Hfrag
  ipureintro
  exact ⟨Hag.2, Hinv, Hwf⟩

/-- Memory-residual agreement. -/
theorem interp_mrest_agree [CerbStGS GF] {σ : driver_state}
    {dq : DFrac} {mr : CerbMem.MemState} :
    CerbStInterp (GF := GF) σ ∗ mrestIs dq mr ⊢
      ⌜memRestOf σ = mr⌝ ∗ CerbStInterp σ ∗ mrestIs dq mr := by
  unfold CerbStInterp mrestIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hfrag⟩
  icombine Hm Hfrag gives %Hag
  iframe Hb Ha He Hd Hc Hs Hm Hfrag
  ipureintro
  exact ⟨Hag.2, Hinv, Hwf⟩

/-- ENV LOOKUP: a cell fragment yields the interpreter's own lookup
    fact — the pure premise every step derivation consumes. -/
theorem interp_env_lookup [CerbStGS GF] {σ : driver_state}
    {x : sym} {dq : DFrac} {v : value} :
    CerbStInterp (GF := GF) σ ∗ envIs x dq v ⊢
      ⌜envLookup σ x = some v⌝ ∗ CerbStInterp σ ∗ envIs x dq v := by
  unfold CerbStInterp envIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hfrag⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icombine He Hfrag gives %Hlk
  iframe Hb Ha Hd Hc Hs Hm Hfrag
  isplitl []
  · ipureintro
    exact (Hcoh _ _ Hlk).2
  isplitl [He]
  · iexists e
    iframe He
    ipureintro
    exact Hcoh
  · ipureintro
    exact ⟨Hinv, Hwf⟩

/-- Allocation lookup (unchanged shape from S2). -/
theorem interp_alloc_lookup [CerbStGS GF] {σ : driver_state}
    {aid : Int} {dq : DFrac} {al : CerbMem.Allocation} :
    CerbStInterp (GF := GF) σ ∗ allocIs aid dq al ⊢
      ⌜σ.layout_state.allocations.get? aid = some al⌝ ∗
        CerbStInterp σ ∗ allocIs aid dq al := by
  unfold CerbStInterp allocIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hfrag⟩
  icombine Ha Hfrag gives %Hlk
  iframe Hb Ha He Hd Hc Hs Hm Hfrag
  ipureintro
  refine ⟨?_, Hinv, Hwf⟩
  rw [← toExt_get? σ.layout_state.allocations aid]
  exact Hlk

/-- Byte lookup, single cell (unchanged shape from S2). -/
theorem interp_byte_lookup [CerbStGS GF] {σ : driver_state}
    {a : Int} {dq : DFrac} {b : CerbMem.AbsByte} :
    CerbStInterp (GF := GF) σ ∗ (a ↦{dq} b) ⊢
      ⌜σ.layout_state.bytemap.get? a = some b⌝ ∗
        CerbStInterp σ ∗ (a ↦{dq} b) := by
  unfold CerbStInterp genHeapInterp pointsTo
  iintro ⟨⟨⟨%m, %Hdom, Hσ, Hm2⟩, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hpt⟩
  icombine Hσ Hpt gives %Hlk
  iframe Ha He Hd Hc Hs Hm Hpt
  isplitl []
  · ipureintro
    rw [← toExt_get? σ.layout_state.bytemap a]
    exact Hlk
  isplitl [Hσ Hm2]
  · iexists m
    iframe Hσ Hm2
    ipureintro
    exact Hdom
  · ipureintro
    exact ⟨Hinv, Hwf⟩

/-- Byte lookup over a RANGE (what `readBytesFrom_of_pointwise`
    consumes; unchanged shape from S2). -/
theorem interp_bytes_lookup [CerbStGS GF] {σ : driver_state}
    {a : Int} {dq : DFrac} {bs : List CerbMem.AbsByte} :
    CerbStInterp (GF := GF) σ ∗ pointsToBytes a dq bs ⊢
      ⌜∀ i : Nat, (hi : i < bs.length) →
          σ.layout_state.bytemap.get? (a + (i : Int)) = some bs[i]⌝ ∗
        CerbStInterp σ ∗ pointsToBytes a dq bs := by
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

/-! ## Ghost transport: the physical writes' ghost images (twin of
    CerbHeapRA's byte layer, verbatim modulo the class binder) -/

def extWriteList (m : CerbStF CerbMem.AbsByte) (a : Int) :
    List CerbMem.AbsByte → CerbStF CerbMem.AbsByte
  | [] => m
  | b :: bs =>
      extWriteList (Std.PartialMap.insert (M := CerbStF) m a b)
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

theorem memRestOf_store (σ : driver_state) (a : Int)
    (bs : List CerbMem.AbsByte) :
    memRestOf { σ with layout_state :=
        CerbMem.writeBytesTo σ.layout_state a bs } = memRestOf σ := by
  unfold memRestOf
  rw [writeBytesTo_eq]

/-- ctl ignores the layout entirely: any layout-only move is
    ctl-invisible. -/
theorem ctlOf_layout {σ : driver_state} (ms : CerbMem.MemState) :
    ctlOf { σ with layout_state := ms } = ctlOf σ := rfl

theorem suppliesOf_layout {σ : driver_state} (ms : CerbMem.MemState) :
    suppliesOf { σ with layout_state := ms } = suppliesOf σ := rfl

theorem envLookup_layout {σ : driver_state} (ms : CerbMem.MemState) :
    ∀ x, envLookup { σ with layout_state := ms } x = envLookup σ x :=
  envLookup_of_core_eq rfl

/-! ## Ghost updates, byte layer -/

/-- Full-fraction range overwrite. -/
theorem bytes_update_ghost [CerbStGS GF]
    {m : CerbStF CerbMem.AbsByte} {a : Int}
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

/-- Fresh-range allocation. -/
theorem bytes_alloc_ghost [CerbStGS GF]
    {m : CerbStF CerbMem.AbsByte} {a : Int}
    (bs : List CerbMem.AbsByte)
    (hfresh : ∀ i : Nat, i < bs.length →
      Std.PartialMap.get? (M := CerbStF) m (a + (i : Int)) = none) :
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
    have h0 : Std.PartialMap.get? (M := CerbStF) m a = none := by
      have := hfresh 0 (by simp)
      simpa using this
    imod genHeap_alloc h0 (v := b) $$ Hi with ⟨Hi, Hb, Htok⟩
    iclear Htok
    have hfresh' : ∀ i : Nat, i < bs.length →
        Std.PartialMap.get? (M := CerbStF)
          (Std.PartialMap.insert (M := CerbStF) m a b)
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

/-! ## The interpretation moves (one per step class; the WP rules'
    `Hupd` legs) -/

/-- Congruence helper: rewrite an interpretation at transported
    component images. -/
theorem CerbStInterp_congr [CerbStGS GF] {σ' : driver_state}
    {B : CerbStF CerbMem.AbsByte} {A : CerbStF CerbMem.Allocation}
    {C : driver_state} {S : Supplies} {MR : CerbMem.MemState}
    (hb : bytesOf σ'.layout_state = B)
    (ha : allocsOf σ'.layout_state = A)
    (hc : ctlOf σ' = C)
    (hs : suppliesOf σ' = S)
    (hmr : memRestOf σ' = MR) :
    CerbStInterp (GF := GF) σ'
      = iprop(genHeapInterp B ∗
          ((CerbStGS.allocName GF) ↪●MAP A) ∗
          (∃ e : CerbStF EnvCell,
            ((CerbStGS.envName GF) ↪●MAP e) ∗ ⌜EnvCoh σ' e⌝) ∗
          (∃ d : List Int,
            ((CerbStGS.domName GF) ↪VAR{stHalf} d) ∗ ⌜EnvDom σ' d⌝) ∗
          ((CerbStGS.ctlName GF) ↪VAR{stHalf} C) ∗
          ((CerbStGS.supName GF) ↪VAR{stHalf} S) ∗
          ((CerbStGS.mrestName GF) ↪VAR{stHalf} MR) ∗
          ⌜MemInv σ'.layout_state⌝ ∗ ⌜EnvWf σ'⌝) := by
  subst hb; subst ha; subst hc; subst hs; subst hmr; rfl

/-- CONTROL MOVE (layout untouched, supplies untouched, env
    lookup-monotone): consumes the control token, updates it; every
    env fragment, byte fragment, allocation fragment, the supply and
    memory-residual components ALL ride the frame. The step class of
    the machine's pure/tau rounds. -/
theorem interp_ctl_move [CerbStGS GF] {σ σ' : driver_state}
    (hlay : σ'.layout_state = σ.layout_state)
    (hsup : suppliesOf σ' = suppliesOf σ)
    (henvT : thread0Env σ' = thread0Env σ) :
    CerbStInterp (GF := GF) σ ∗ ctlIs stHalf (ctlOf σ) ⊢ |==>
      (CerbStInterp σ' ∗ ctlIs stHalf (ctlOf σ')) := by
  have henvL : ∀ x, envLookup σ' x = envLookup σ x := by
    intro x; unfold envLookup; rw [henvT]
  rw [CerbStInterp_congr (σ' := σ')
    (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
    (C := ctlOf σ') (S := suppliesOf σ) (MR := memRestOf σ)
    (by rw [hlay]) (by rw [hlay]) rfl hsup
    (by unfold memRestOf; rw [hlay])]
  unfold CerbStInterp ctlIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hfrag⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d, Hd, %Hdom⟩
  imod ghost_var_update_halves (ctlOf σ') _ _ _ $$ Hc Hfrag
    with ⟨Hc, Hfrag⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hfrag
  isplitl [He]
  · iexists e
    iframe He
    ipureintro
    exact Hcoh.mono (fun x v h => (henvL x).trans h)
  isplitl [Hd]
  · iexists d
    iframe Hd
    ipureintro
    exact Hdom.of_env_eq henvT
  · ipureintro
    rw [hlay]
    exact ⟨Hinv, fun f hf => Hwf f (by rwa [henvT] at hf)⟩

/-- CONTROL + SUPPLY MOVE: as `interp_ctl_move`, for steps that also
    draw from the supplies (both tokens consumed and updated). -/
theorem interp_ctl_sup_move [CerbStGS GF] {σ σ' : driver_state}
    (hlay : σ'.layout_state = σ.layout_state)
    (henvT : thread0Env σ' = thread0Env σ) :
    CerbStInterp (GF := GF) σ ∗ ctlIs stHalf (ctlOf σ)
        ∗ supIs stHalf (suppliesOf σ) ⊢ |==>
      (CerbStInterp σ' ∗ ctlIs stHalf (ctlOf σ')
        ∗ supIs stHalf (suppliesOf σ')) := by
  have henvL : ∀ x, envLookup σ' x = envLookup σ x := by
    intro x; unfold envLookup; rw [henvT]
  rw [CerbStInterp_congr (σ' := σ')
    (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
    (C := ctlOf σ') (S := suppliesOf σ') (MR := memRestOf σ)
    (by rw [hlay]) (by rw [hlay]) rfl rfl
    (by unfold memRestOf; rw [hlay])]
  unfold CerbStInterp ctlIs supIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hcf, Hsf⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d, Hd, %Hdom⟩
  imod ghost_var_update_halves (ctlOf σ') _ _ _ $$ Hc Hcf
    with ⟨Hc, Hcf⟩
  imod ghost_var_update_halves (suppliesOf σ') _ _ _ $$ Hs Hsf
    with ⟨Hs, Hsf⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hcf Hsf
  isplitl [He]
  · iexists e
    iframe He
    ipureintro
    exact Hcoh.mono (fun x v h => (henvL x).trans h)
  isplitl [Hd]
  · iexists d
    iframe Hd
    ipureintro
    exact Hdom.of_env_eq henvT
  · ipureintro
    rw [hlay]
    exact ⟨Hinv, fun f hf => Hwf f (by rwa [henvT] at hf)⟩

/-- CONTROL + SUPPLY MOVE at LOOKUP-POINTWISE env equality (the
    frame-CREATING step class — the globals stage installs an empty
    frame: the spine changes, every lookup is unchanged). -/
theorem interp_ctl_sup_move_lk [CerbStGS GF] {σ σ' : driver_state}
    (hlay : σ'.layout_state = σ.layout_state)
    (henvL : ∀ z, envLookup σ' z = envLookup σ z)
    (hwfp : EnvWf σ → EnvWf σ') :
    CerbStInterp (GF := GF) σ ∗ ctlIs stHalf (ctlOf σ)
        ∗ supIs stHalf (suppliesOf σ) ⊢ |==>
      (CerbStInterp σ' ∗ ctlIs stHalf (ctlOf σ')
        ∗ supIs stHalf (suppliesOf σ')) := by
  rw [CerbStInterp_congr (σ' := σ')
    (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
    (C := ctlOf σ') (S := suppliesOf σ') (MR := memRestOf σ)
    (by rw [hlay]) (by rw [hlay]) rfl rfl
    (by unfold memRestOf; rw [hlay])]
  unfold CerbStInterp ctlIs supIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hcf, Hsf⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d, Hd, %Hdom⟩
  imod ghost_var_update_halves (ctlOf σ') _ _ _ $$ Hc Hcf
    with ⟨Hc, Hcf⟩
  imod ghost_var_update_halves (suppliesOf σ') _ _ _ $$ Hs Hsf
    with ⟨Hs, Hsf⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hcf Hsf
  isplitl [He]
  · iexists e
    iframe He
    ipureintro
    exact Hcoh.mono (fun x v h => (henvL x).trans h)
  isplitl [Hd]
  · iexists d
    iframe Hd
    ipureintro
    intro z v hz
    exact Hdom z v ((henvL z).symm.trans hz)
  · ipureintro
    rw [hlay]
    exact ⟨Hinv, hwfp Hwf⟩

/-- ENV WRITE (the new capability's update leg): a step rebinds the
    owned cell `x` to `vNew`, every OTHER cell is preserved by
    NUMBER-APARTNESS (`hpres`); the control token moves; the owned
    fragment is updated in place. Every other env fragment survives
    by frame — a fragment at number n ≠ symNum x is untouched. -/
theorem interp_env_write [CerbStGS GF] {σ σ' : driver_state}
    (x : sym) {vOld vNew : value}
    (hlay : σ'.layout_state = σ.layout_state)
    (hsup : suppliesOf σ' = suppliesOf σ)
    (hnew : envLookup σ' x = some vNew)
    (hpres : ∀ y v, symNum y ≠ symNum x →
      envLookup σ y = some v → envLookup σ' y = some v)
    (hbound : ∀ y v, envLookup σ' y = some v →
      ∃ v₀, envLookup σ y = some v₀)
    (hwfp : EnvWf σ → EnvWf σ') :
    CerbStInterp (GF := GF) σ ∗ ctlIs stHalf (ctlOf σ)
        ∗ envIs x (.own 1) vOld ⊢ |==>
      (CerbStInterp σ' ∗ ctlIs stHalf (ctlOf σ')
        ∗ envIs x (.own 1) vNew) := by
  rw [CerbStInterp_congr (σ' := σ')
    (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
    (C := ctlOf σ') (S := suppliesOf σ) (MR := memRestOf σ)
    (by rw [hlay]) (by rw [hlay]) rfl hsup
    (by unfold memRestOf; rw [hlay])]
  unfold CerbStInterp ctlIs envIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hcf, Hef⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d, Hd, %Hdom⟩
  icombine He Hef gives %Hlk
  imod ghost_var_update_halves (ctlOf σ') _ _ _ $$ Hc Hcf
    with ⟨Hc, Hcf⟩
  imod ghost_map_update ((x, vNew) : EnvCell) $$ He Hef
    with ⟨He, Hef⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hcf Hef
  isplitl [He]
  · iexists (Std.PartialMap.insert (M := CerbStF) e (symNum x)
      ((x, vNew) : EnvCell))
    iframe He
    ipureintro
    intro n c hc
    by_cases hn : n = symNum x
    · subst hn
      rw [Std.LawfulPartialMap.get?_insert_eq rfl] at hc
      cases hc
      exact ⟨rfl, hnew⟩
    · rw [Std.LawfulPartialMap.get?_insert_ne
        (fun h => hn h.symm)] at hc
      obtain ⟨h1, h2⟩ := Hcoh n c hc
      refine ⟨h1, hpres _ _ ?_ h2⟩
      rw [h1]
      exact hn
  isplitl [Hd]
  · iexists d
    iframe Hd
    ipureintro
    intro z v hz
    obtain ⟨v₀, hv₀⟩ := hbound z v hz
    exact Hdom z v₀ hv₀
  · ipureintro
    rw [hlay]
    exact ⟨Hinv, hwfp Hwf⟩

/-- STORE (memory-only step): full-fraction range overwrite on mapped
    keys; the residual is READ (any fraction) but does not move; ctl,
    supply, env all pass through UNTOUCHED — a heap write no longer
    pins the machine. -/
theorem interp_store_update [CerbStGS GF] {σ : driver_state}
    {a : Int} (new : List CerbMem.AbsByte) {old : List CerbMem.AbsByte}
    (hlen : new.length = old.length)
    (hold : ∀ i : Nat, (hi : i < old.length) →
      σ.layout_state.bytemap.get? (a + (i : Int)) = some old[i]) :
    CerbStInterp (GF := GF) σ ∗ pointsToBytes a (.own 1) old ⊢ |==>
      (CerbStInterp { σ with layout_state :=
          CerbMem.writeBytesTo σ.layout_state a new }
        ∗ pointsToBytes a (.own 1) new) := by
  rw [CerbStInterp_congr
    (σ' := { σ with layout_state :=
      CerbMem.writeBytesTo σ.layout_state a new })
    (bytesOf_writeBytesTo σ.layout_state a new)
    (allocsOf_writeBytesTo σ.layout_state a new)
    (ctlOf_layout _) (suppliesOf_layout _)
    (memRestOf_store σ a new)]
  unfold CerbStInterp
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hp⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d, Hd, %Hdom⟩
  imod bytes_update_ghost new hlen $$ [$Hb $Hp] with ⟨Hb, Hp⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hp
  isplitl [He]
  · iexists e
    iframe He
    ipureintro
    exact Hcoh.mono (fun x v h => by rwa [envLookup_layout])
  isplitl [Hd]
  · iexists d
    iframe Hd
    ipureintro
    exact Hdom.of_env_eq rfl
  · ipureintro
    exact ⟨Hinv.store hlen hold, EnvWf_of_core_eq rfl Hwf⟩

/-- The residual image after a fresh-object allocation. -/
def mrAlloc (mr : CerbMem.MemState) (a : Int) : CerbMem.MemState :=
  { mr with nextAllocId := mr.nextAllocId + 1, lastAddress := a }

/-- ALLOCATE: consumes the residual half (the bump counters move),
    mints the allocation fragment and the uninitialized range
    points-to. ctl, supply, env pass through untouched — an
    allocation no longer pins the machine remainder. -/
theorem interp_alloc_update [CerbStGS GF] {σ : driver_state}
    {mr : CerbMem.MemState} {pref : prefix0} {ty : ctype}
    {alignN : Int} {sz : Nat} {a : Int}
    (hmr : memRestOf σ = mr)
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (σ.layout_state.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    CerbStInterp (GF := GF) σ ∗ mrestIs stHalf mr ⊢ |==>
      (CerbStInterp { σ with layout_state := (CerbMem.writeBytesTo
            ({ σ.layout_state with
              nextAllocId := σ.layout_state.nextAllocId + 1,
              lastAddress := a,
              allocations := σ.layout_state.allocations.insert
                σ.layout_state.nextAllocId
                { base := a, size := sz, ty := some ty, prefix_ := pref } })
            a (List.replicate sz
                { prov := .Prov_none, copyOffset := none, value := none })) }
        ∗ mrestIs stHalf (mrAlloc mr a)
        ∗ allocIs σ.layout_state.nextAllocId (.own 1)
            { base := a, size := sz, ty := some ty, prefix_ := pref }
        ∗ pointsToBytes a (.own 1)
            (List.replicate sz
              { prov := .Prov_none, copyOffset := none, value := none })) := by
  rw [CerbStInterp_congr
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
    (A := Std.PartialMap.insert (M := CerbStF)
      (allocsOf σ.layout_state) σ.layout_state.nextAllocId
      { base := a, size := sz, ty := some ty, prefix_ := pref })
    (C := ctlOf σ) (S := suppliesOf σ) (MR := mrAlloc mr a)
    (by rw [bytesOf_writeBytesTo]; rfl)
    (by rw [allocsOf_writeBytesTo]; exact toExt_insert ..)
    rfl rfl
    (by subst hmr; unfold memRestOf mrAlloc; rw [writeBytesTo_eq])]
  have hrange : a + sz ≤ σ.layout_state.lastAddress :=
    alloc_range_le haddr hnz
  unfold CerbStInterp mrestIs allocIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hmf⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d, Hd, %Hdom⟩
  have hfreshA : Std.PartialMap.get? (M := CerbStF)
      (allocsOf σ.layout_state) σ.layout_state.nextAllocId = none := by
    unfold allocsOf
    rw [toExt_get?]
    exact Hinv.next_fresh
  have hfreshB : ∀ i : Nat,
      i < (List.replicate sz
        ({ prov := .Prov_none, copyOffset := none, value := none }
          : CerbMem.AbsByte)).length →
      Std.PartialMap.get? (M := CerbStF) (bytesOf σ.layout_state)
        (a + (i : Int)) = none := by
    intro i hi
    unfold bytesOf
    rw [toExt_get?]
    refine Hinv.bytemap_below_none ?_
    simp only [List.length_replicate] at hi
    omega
  imod bytes_alloc_ghost _ hfreshB $$ Hb with ⟨Hb, Hpts⟩
  imod ghost_map_insert _ _ hfreshA $$ Ha with ⟨Ha, Hfrag⟩
  imod ghost_var_update_halves (mrAlloc mr a) _ _ _ $$ Hm Hmf
    with ⟨Hm, Hmf⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hmf Hfrag Hpts
  isplitl [He]
  · iexists e
    iframe He
    ipureintro
    exact Hcoh.mono (fun x v h => by rwa [envLookup_layout])
  isplitl [Hd]
  · iexists d
    iframe Hd
    ipureintro
    exact Hdom.of_env_eq rfl
  · ipureintro
    exact ⟨Hinv.alloc hsz haddr hnz, EnvWf_of_core_eq rfl Hwf⟩

/-- The residual image after a kill. -/
def mrKill (mr : CerbMem.MemState) (aid : Int) : CerbMem.MemState :=
  { mr with deadAllocations := aid :: mr.deadAllocations }

/-- KILL: consumes the full allocation fragment (the freeable token)
    and the residual half (the dead list moves); the byte points-to
    stays with the prover as dead capital (S2 deviation D2). ctl,
    supply, env untouched. -/
theorem interp_kill_update [CerbStGS GF] {σ : driver_state}
    {mr : CerbMem.MemState} {aid : Int} {al : CerbMem.Allocation}
    (hmr : memRestOf σ = mr) :
    CerbStInterp (GF := GF) σ ∗ mrestIs stHalf mr
        ∗ allocIs aid (.own 1) al ⊢ |==>
      (CerbStInterp { σ with layout_state :=
          { σ.layout_state with
            deadAllocations := aid :: σ.layout_state.deadAllocations,
            allocations := σ.layout_state.allocations.erase aid } }
        ∗ mrestIs stHalf (mrKill mr aid)) := by
  rw [CerbStInterp_congr
    (σ' := { σ with layout_state :=
      { σ.layout_state with
        deadAllocations := aid :: σ.layout_state.deadAllocations,
        allocations := σ.layout_state.allocations.erase aid } })
    (B := bytesOf σ.layout_state)
    (A := Std.PartialMap.delete (M := CerbStF)
      (allocsOf σ.layout_state) aid)
    (C := ctlOf σ) (S := suppliesOf σ) (MR := mrKill mr aid)
    rfl
    (toExt_erase ..)
    rfl rfl
    (by subst hmr; unfold memRestOf mrKill; rfl)]
  unfold CerbStInterp mrestIs allocIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hmf, Hfrag⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d, Hd, %Hdom⟩
  icombine Ha Hfrag gives %Hlk
  have hget : σ.layout_state.allocations.get? aid = some al := by
    rw [← toExt_get? σ.layout_state.allocations aid]
    exact Hlk
  imod ghost_map_delete _ _ $$ Ha Hfrag with Ha
  imod ghost_var_update_halves (mrKill mr aid) _ _ _ $$ Hm Hmf
    with ⟨Hm, Hmf⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hmf
  isplitl [He]
  · iexists e
    iframe He
    ipureintro
    exact Hcoh.mono (fun x v h => by rwa [envLookup_layout])
  isplitl [Hd]
  · iexists d
    iframe Hd
    ipureintro
    exact Hdom.of_env_eq rfl
  · ipureintro
    exact ⟨Hinv.kill hget, EnvWf_of_core_eq rfl Hwf⟩


/-! ## THE BIRTH MOVES (V2 — the ledger's raison d'être).

    A step that BINDS a previously-unbound symbol needs a
    coherence-auth insert, which needs `get? e (symNum x) = none` —
    NEGATIVE information. The ledger supplies it: `symNum x ∉ d` +
    `EnvDom σ d` ⇒ no symbol numbered `symNum x` is bound ⇒ (by
    one-directional coherence) no tracked cell at that key. The move
    mints the cell and extends the ledger — the gen_heap alloc-fresh
    shape (HeapLang `wp_alloc`), transplanted to symbol numbers. -/

/-- Ledger agreement: the prover's half pins the interpretation's. -/
theorem interp_dom_agree [CerbStGS GF] {σ : driver_state}
    {dq : DFrac} {d : List Int} :
    CerbStInterp (GF := GF) σ ∗ domIs dq d ⊢
      ⌜EnvDom σ d⌝ ∗ CerbStInterp σ ∗ domIs dq d := by
  unfold CerbStInterp domIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hfrag⟩
  icases Hd with ⟨%d₀, Hd, %Hdom⟩
  icombine Hd Hfrag gives %Hag
  iframe Hb Ha He Hc Hs Hm Hfrag
  isplitl []
  · ipureintro
    exact Hag.2 ▸ Hdom
  isplitl [Hd]
  · iexists d₀
    iframe Hd
    ipureintro
    exact Hdom
  · ipureintro
    exact ⟨Hinv, Hwf⟩

/-- The freshness payoff, pure form: an unlisted number has no tracked
    cell (used inside the birth moves). -/
theorem envAuth_fresh_of_dom {σ : driver_state} {e : CerbStF EnvCell}
    {d : List Int} {n : Int}
    (hcoh : EnvCoh σ e) (hdom : EnvDom σ d) (hfresh : n ∉ d) :
    Std.PartialMap.get? (M := CerbStF) e n = none := by
  cases heq : Std.PartialMap.get? (M := CerbStF) e n with
  | none => rfl
  | some c =>
    obtain ⟨h1, h2⟩ := hcoh n c heq
    exact absurd (h1 ▸ hdom c.1 c.2 h2) hfresh

/-- BIRTH of ONE cell: a control step that binds the fresh symbol `x`
    (all previous bindings preserved; the newborn is the only
    addition). Mints `envIs x 1 vNew`; extends the ledger. -/
theorem interp_ctl_dom_birth1 [CerbStGS GF] {σ σ' : driver_state}
    (x : sym) {vNew : value} {d : List Int}
    (hlay : σ'.layout_state = σ.layout_state)
    (hsup : suppliesOf σ' = suppliesOf σ)
    (hfresh : symNum x ∉ d)
    (hnew : envLookup σ' x = some vNew)
    (hpres : ∀ z v, envLookup σ z = some v → envLookup σ' z = some v)
    (hrev : ∀ z v, envLookup σ' z = some v →
      (∃ v₀, envLookup σ z = some v₀) ∨ symNum z = symNum x)
    (hwfp : EnvWf σ → EnvWf σ') :
    CerbStInterp (GF := GF) σ ∗ ctlIs stHalf (ctlOf σ)
        ∗ domIs stHalf d ⊢ |==>
      (CerbStInterp σ' ∗ ctlIs stHalf (ctlOf σ')
        ∗ domIs stHalf (symNum x :: d) ∗ envIs x (.own 1) vNew) := by
  rw [CerbStInterp_congr (σ' := σ')
    (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
    (C := ctlOf σ') (S := suppliesOf σ) (MR := memRestOf σ)
    (by rw [hlay]) (by rw [hlay]) rfl hsup
    (by unfold memRestOf; rw [hlay])]
  unfold CerbStInterp ctlIs domIs envIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hcf, Hdf⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d₀, Hd, %Hdom⟩
  icombine Hd Hdf gives %Hag
  have hd' : d = d₀ := Hag.2.symm
  subst hd'
  have hnone : Std.PartialMap.get? (M := CerbStF) e (symNum x) = none :=
    envAuth_fresh_of_dom Hcoh Hdom hfresh
  imod ghost_var_update_halves (ctlOf σ') _ _ _ $$ Hc Hcf
    with ⟨Hc, Hcf⟩
  imod ghost_var_update_halves (symNum x :: d) _ _ _ $$ Hd Hdf
    with ⟨Hd, Hdf⟩
  imod ghost_map_insert _ _ hnone $$ He with ⟨He, Hef⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hcf Hd Hdf Hef
  isplitl [He]
  · iexists (Std.PartialMap.insert (M := CerbStF) e (symNum x)
      ((x, vNew) : EnvCell))
    iframe He
    ipureintro
    intro n c hc
    by_cases hn : n = symNum x
    · subst hn
      rw [Std.LawfulPartialMap.get?_insert_eq rfl] at hc
      cases hc
      exact ⟨rfl, hnew⟩
    · rw [Std.LawfulPartialMap.get?_insert_ne
        (fun h => hn h.symm)] at hc
      obtain ⟨h1, h2⟩ := Hcoh n c hc
      exact ⟨h1, hpres _ _ h2⟩
  · ipureintro
    refine ⟨?_, by rw [hlay]; exact Hinv, hwfp Hwf⟩
    intro z v hz
    rcases hrev z v hz with ⟨v₀, hv₀⟩ | hzx
    · exact List.mem_cons_of_mem _ (Hdom z v₀ hv₀)
    · rw [hzx]; exact List.mem_cons_self ..

/-- BIRTH of TWO cells in one step (the pair-pattern bind — one tau
    round binds both components of a `weak (a, b) = unseq(…)` let). -/
theorem interp_ctl_dom_birth2 [CerbStGS GF] {σ σ' : driver_state}
    (x₁ x₂ : sym) {v₁ v₂ : value} {d : List Int}
    (hlay : σ'.layout_state = σ.layout_state)
    (hsup : suppliesOf σ' = suppliesOf σ)
    (hfresh₁ : symNum x₁ ∉ d) (hfresh₂ : symNum x₂ ∉ d)
    (hne : symNum x₁ ≠ symNum x₂)
    (hnew₁ : envLookup σ' x₁ = some v₁)
    (hnew₂ : envLookup σ' x₂ = some v₂)
    (hpres : ∀ z v, envLookup σ z = some v → envLookup σ' z = some v)
    (hrev : ∀ z v, envLookup σ' z = some v →
      (∃ v₀, envLookup σ z = some v₀) ∨ symNum z = symNum x₁ ∨
        symNum z = symNum x₂)
    (hwfp : EnvWf σ → EnvWf σ') :
    CerbStInterp (GF := GF) σ ∗ ctlIs stHalf (ctlOf σ)
        ∗ domIs stHalf d ⊢ |==>
      (CerbStInterp σ' ∗ ctlIs stHalf (ctlOf σ')
        ∗ domIs stHalf (symNum x₁ :: symNum x₂ :: d)
        ∗ envIs x₁ (.own 1) v₁ ∗ envIs x₂ (.own 1) v₂) := by
  rw [CerbStInterp_congr (σ' := σ')
    (B := bytesOf σ.layout_state) (A := allocsOf σ.layout_state)
    (C := ctlOf σ') (S := suppliesOf σ) (MR := memRestOf σ)
    (by rw [hlay]) (by rw [hlay]) rfl hsup
    (by unfold memRestOf; rw [hlay])]
  unfold CerbStInterp ctlIs domIs envIs
  iintro ⟨⟨Hb, Ha, He, Hd, Hc, Hs, Hm, %Hinv, %Hwf⟩, Hcf, Hdf⟩
  icases He with ⟨%e, He, %Hcoh⟩
  icases Hd with ⟨%d₀, Hd, %Hdom⟩
  icombine Hd Hdf gives %Hag
  have hd' : d = d₀ := Hag.2.symm
  subst hd'
  have hnone₁ : Std.PartialMap.get? (M := CerbStF) e (symNum x₁)
      = none := envAuth_fresh_of_dom Hcoh Hdom hfresh₁
  have hnone₂ : Std.PartialMap.get? (M := CerbStF) e (symNum x₂)
      = none := envAuth_fresh_of_dom Hcoh Hdom hfresh₂
  imod ghost_var_update_halves (ctlOf σ') _ _ _ $$ Hc Hcf
    with ⟨Hc, Hcf⟩
  imod ghost_var_update_halves (symNum x₁ :: symNum x₂ :: d) _ _ _
    $$ Hd Hdf with ⟨Hd, Hdf⟩
  imod ghost_map_insert _ _ hnone₂ $$ He with ⟨He, Hef₂⟩
  have hnone₁' : Std.PartialMap.get?
      (M := CerbStF) (Std.PartialMap.insert (M := CerbStF) e
        (symNum x₂) ((x₂, v₂) : EnvCell)) (symNum x₁) = none := by
    rw [Std.LawfulPartialMap.get?_insert_ne (fun h => hne h.symm)]
    exact hnone₁
  imod ghost_map_insert _ _ hnone₁' $$ He with ⟨He, Hef₁⟩
  imodintro
  iframe Hb Ha Hc Hs Hm Hcf Hd Hdf Hef₁ Hef₂
  isplitl [He]
  · iexists (Std.PartialMap.insert (M := CerbStF)
      (Std.PartialMap.insert (M := CerbStF) e (symNum x₂)
        ((x₂, v₂) : EnvCell)) (symNum x₁) ((x₁, v₁) : EnvCell))
    iframe He
    ipureintro
    intro n c hc
    by_cases hn₁ : n = symNum x₁
    · subst hn₁
      rw [Std.LawfulPartialMap.get?_insert_eq rfl] at hc
      cases hc
      exact ⟨rfl, hnew₁⟩
    · rw [Std.LawfulPartialMap.get?_insert_ne
        (fun h => hn₁ h.symm)] at hc
      by_cases hn₂ : n = symNum x₂
      · subst hn₂
        rw [Std.LawfulPartialMap.get?_insert_eq rfl] at hc
        cases hc
        exact ⟨rfl, hnew₂⟩
      · rw [Std.LawfulPartialMap.get?_insert_ne
          (fun h => hn₂ h.symm)] at hc
        obtain ⟨h1, h2⟩ := Hcoh n c hc
        exact ⟨h1, hpres _ _ h2⟩
  · ipureintro
    refine ⟨?_, by rw [hlay]; exact Hinv, hwfp Hwf⟩
    intro z v hz
    rcases hrev z v hz with ⟨v₀, hv₀⟩ | hzx | hzx
    · exact List.mem_cons_of_mem _
        (List.mem_cons_of_mem _ (Hdom z v₀ hv₀))
    · rw [hzx]; exact List.mem_cons_self ..
    · rw [hzx]
      exact List.mem_cons_of_mem _ (List.mem_cons_self ..)

end CerbSt
end RelSem
