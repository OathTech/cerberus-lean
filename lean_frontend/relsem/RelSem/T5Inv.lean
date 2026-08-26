/-
  RelSem.T5Inv — arc-18 C3b (2026-08-26): THE T5 INVARIANT FAMILY.

  The loop invariant over the builder pack — the C3 record §3.5 item
  4's human-content exhibit, LANDED AT THE FAMILY LAYER:

  * `triF` — the loop measure (s's value at the k-th head) with its
    kernel-checked closed form `triF_closed` (the spec's n*(n-1)/2).
  * `St p k` — the k-th loop-head state: `St p 0` is the ENTRY walk's
    endpoint; `St p 1` the first-iteration walk's endpoint (the
    STORED loop head every `run while_531` reaches); `St p (k+2)`
    iterates the body walk's endpoint at its own components. The
    family IS the walk's own step, indexed — every component a
    projection of the previous member.
  * THE ALIGNMENT RFLS (`St0_align`, `St_align` via `bfirst_align` /
    `b79_align'`): every family member is DEFINITIONALLY a loop-head
    builder state at its own components — the walks' ∀-fuel relative
    chains (`bfirst78_chainrel`, `b_chainrel`, the terminal
    `bx_chainrel`/`bxzero_chainrel`) therefore instantiate at every
    St member. This is the composition feed for iter_compose
    (Kit/Loop — Floyd-Hoare at the equation calculus).
  * Component invariants (∀ k): allocation table, dead list, supply
    arithmetic (`St_allocs`/`St_dead`/`St_aid`); the memory step
    `memStep` (the walk's own double store, defeq-pinned by
    `b79_mem`/`bfirst78_mem` — note the respelled funptrmap/
    lastUsedUnionMembers fields, the pack's `hfpm`/`hlum` baked into
    the walk states) with the SL read-over-step laws
    (`memStep_rdN/rdS/rdI` — frame + hit at the byte level); the env
    step `envStepF` (projection-defined, never spelled) with the
    27-layer built-chain (`envStepF_built`, term-mode through the
    generated-instance bridge `envBeq`/`addBy_builtG` — the R-S2-1
    instance-implicit lesson).

  REMAINING to T5-the-theorem (the C3b record's corrected map): env
  LOOKUP peels ∀-k (hit/skip through the 27-layer chain), the
  remaining pack-fact family lemmas, hbody + iter_compose assembly,
  the exit/terminal composition + fuel algebra, the harness spine at
  open maps, a wpk_seq_scratch2-class walk rule, adequacy + the
  guarded ∀-seed statement.

  House rules: no sorry, no axioms. Under the in-build audit.
-/
import RelSem.T5Walks
import RelSem.Kit.Loop
import RelSem.Kit.Env

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit RelSem.T5W
open Lem_Basic_classes (ordCompare)

/-! ## The loop measure -/

/-- The triangular family: `s`'s value at the k-th loop head
    (sum of 0..k-1). -/
def triF : Nat → Int
  | 0 => 0
  | k + 1 => triF k + k

theorem triF_double (k : Nat) : 2 * triF k = (k : Int) * ((k : Int) - 1) := by
  induction k with
  | zero => decide
  | succ k ih =>
    have hc : (((k + 1 : Nat)) : Int) = (k : Int) + 1 := by omega
    show 2 * (triF k + (k : Int)) = _
    rw [hc, Int.add_sub_cancel, Int.add_mul, Int.one_mul, Int.mul_add,
      ih, Int.mul_sub, Int.mul_one]
    generalize (k : Int) * (k : Int) = K
    omega

/-- The closed form the spec quotes. -/
theorem triF_closed (n : Int) (hn : 0 ≤ n) :
    triF n.toNat = n * (n - 1) / 2 := by
  have hd := triF_double n.toNat
  rw [Int.toNat_of_nonneg hn] at hd
  generalize hA : n * (n - 1) = A at hd ⊢
  omega

/-! ## Component accessors (total; defaults never fire on walk
    emissions — the alignment rfls are the loud check) -/

def envOf (σ : driver_state) : Fmap sym value :=
  match (thOf σ).env with
  | e :: _ => e
  | [] => fmapEmpty

/-! ## Per-walk projection laws (one cheap rfl each, at open binders —
    the family's step lemmas ride these; St itself is brecOn-opaque
    at open indices) -/

section Proj
variable (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)

theorem b79_allocs :
    (b79 env mem tr aid exc symc ctr n sv iv).layout_state.allocations
      = mem.allocations := rfl
theorem b79_dead :
    (b79 env mem tr aid exc symc ctr n sv iv).layout_state.deadAllocations
      = mem.deadAllocations := rfl
theorem e22_aid (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr0 : List trace_event) (aid0 exc0 symc0 ctr0 : Nat) :
    (e22 bm am tr0 aid0 exc0 symc0 ctr0).core_run_state0.aid_supply
      = aid0 + 4 := rfl

theorem b79_aid :
    (b79 env mem tr aid exc symc ctr n sv iv).core_run_state0.aid_supply
      = aid + 7 := rfl
theorem bfirst78_allocs :
    (bfirst78 env mem tr aid exc symc ctr n sv iv).layout_state.allocations
      = mem.allocations := rfl
theorem bfirst78_dead :
    (bfirst78 env mem tr aid exc symc ctr n sv iv).layout_state.deadAllocations
      = mem.deadAllocations := rfl
theorem bfirst78_aid :
    (bfirst78 env mem tr aid exc symc ctr n sv iv).core_run_state0.aid_supply
      = aid + 7 := rfl

/-- The first-iteration endpoint is a STORED-shape loop head (the
    b79_align twin — isolated). -/
theorem bfirst_align :
    bfirst78 env mem tr aid exc symc ctr n sv iv
      = mkLH (envOf (bfirst78 env mem tr aid exc symc ctr n sv iv))
          (bfirst78 env mem tr aid exc symc ctr n sv iv).layout_state
          (bfirst78 env mem tr aid exc symc ctr n sv iv).trace
          (bfirst78 env mem tr aid exc symc ctr n sv iv).core_run_state0.aid_supply
          (bfirst78 env mem tr aid exc symc ctr n sv iv).core_run_state0.excluded_supply
          (bfirst78 env mem tr aid exc symc ctr n sv iv).core_run_state0.sym_supply
          (bfirst78 env mem tr aid exc symc ctr n sv iv).dr_step_counter := rfl

/-- The body endpoint is a STORED-shape loop head (re-proved here at
    the projection spelling). -/
theorem b79_align' :
    b79 env mem tr aid exc symc ctr n sv iv
      = mkLH (envOf (b79 env mem tr aid exc symc ctr n sv iv))
          (b79 env mem tr aid exc symc ctr n sv iv).layout_state
          (b79 env mem tr aid exc symc ctr n sv iv).trace
          (b79 env mem tr aid exc symc ctr n sv iv).core_run_state0.aid_supply
          (b79 env mem tr aid exc symc ctr n sv iv).core_run_state0.excluded_supply
          (b79 env mem tr aid exc symc ctr n sv iv).core_run_state0.sym_supply
          (b79 env mem tr aid exc symc ctr n sv iv).dr_step_counter := rfl

end Proj

/-- The harness-side parameters the family closes over: the open heap
    maps, the entry trace/supplies, and the loop bound. -/
structure Pm where
  bm : Std.TreeMap Int CerbMem.AbsByte
  am : Std.TreeMap Int CerbMem.Allocation
  tr0 : List trace_event
  aid0 : Nat
  exc0 : Nat
  symc0 : Nat
  ctr0 : Nat
  n : Int

/-! ## THE INVARIANT FAMILY: the k-th loop-head state.

    `St p 0` is the entry walk's endpoint (the ENTRY-spelled loop
    head); `St p 1` the first-iteration body walk's endpoint (the
    STORED loop head every `run while_531` reaches); `St p (k+2)`
    iterates the body walk's endpoint at the (k+1)-th components with
    `s = triF (k+1)`, `i = k+1`. Every component is a projection of
    the previous state — the family IS the walk's own step,
    indexed. -/
noncomputable def St (p : Pm) : Nat → driver_state
  | 0 => e22 p.bm p.am p.tr0 p.aid0 p.exc0 p.symc0 p.ctr0
  | 1 =>
    let σ := St p 0
    bfirst78 (envOf σ) σ.layout_state σ.trace
      σ.core_run_state0.aid_supply σ.core_run_state0.excluded_supply
      σ.core_run_state0.sym_supply σ.dr_step_counter p.n (triF 0) 0
  | (k + 2) =>
    let σ := St p (k + 1)
    b79 (envOf σ) σ.layout_state σ.trace
      σ.core_run_state0.aid_supply σ.core_run_state0.excluded_supply
      σ.core_run_state0.sym_supply σ.dr_step_counter p.n (triF (k + 1))
      (k + 1)

/-! ## The alignment rfls: every family member is a loop-head builder
    state at its own components -/

theorem St0_align (p : Pm) :
    St p 0
      = mkLH1 (envOf (St p 0)) (St p 0).layout_state (St p 0).trace
          (St p 0).core_run_state0.aid_supply
          (St p 0).core_run_state0.excluded_supply
          (St p 0).core_run_state0.sym_supply
          (St p 0).dr_step_counter := rfl

theorem St_align (p : Pm) (k : Nat) :
    St p (k + 1)
      = mkLH (envOf (St p (k + 1))) (St p (k + 1)).layout_state
          (St p (k + 1)).trace
          (St p (k + 1)).core_run_state0.aid_supply
          (St p (k + 1)).core_run_state0.excluded_supply
          (St p (k + 1)).core_run_state0.sym_supply
          (St p (k + 1)).dr_step_counter := by
  match k with
  | 0 => simp only [St]; exact bfirst_align ..
  | k + 1 => simp only [St]; exact b79_align' ..

/-! ## Component lemma smokes (the ∀-k invariant conjuncts) -/

theorem St_allocs (p : Pm) (k : Nat) :
    (St p k).layout_state.allocations
      = (p.am.insert 2 allocS).insert 3 allocI := by
  induction k with
  | zero => rfl
  | succ k ih =>
    match k with
    | 0 => simp only [St]; rw [bfirst78_allocs]; exact ih
    | k + 1 => simp only [St]; rw [b79_allocs]; exact ih

theorem St_dead (p : Pm) (k : Nat) :
    (St p k).layout_state.deadAllocations = [] := by
  induction k with
  | zero => rfl
  | succ k ih =>
    match k with
    | 0 => simp only [St]; rw [bfirst78_dead]; exact ih
    | k + 1 => simp only [St]; rw [b79_dead]; exact ih

theorem St_aid (p : Pm) (k : Nat) :
    (St p k).core_run_state0.aid_supply = p.aid0 + 4 + 7 * k := by
  induction k with
  | zero => rfl
  | succ k ih =>
    match k with
    | 0 => simp only [St]; rw [bfirst78_aid, e22_aid]
    | k + 1 => simp only [St]; rw [b79_aid, ih]; simp [Nat.mul_succ, Nat.add_assoc]


/-! ## The memory step (projection-defined; the peel layer) -/

/-- One iteration's memory effect: store s := sv+iv, store i := iv+1
    (the walk's own ladder, tidied). -/
def memStep (mem : CerbMem.MemState) (sv iv : Int) : CerbMem.MemState :=
  CerbMem.writeBytesTo
    (CerbMem.writeBytesTo
      { mem with funptrmap := [], lastUsedUnionMembers := [] }
      sAddr (i32 (sv + iv))) iAddr (i32 (iv + 1))

section MemProj
variable (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)

theorem b79_mem :
    (b79 env mem tr aid exc symc ctr n sv iv).layout_state
      = memStep mem sv iv := rfl

theorem bfirst78_mem :
    (bfirst78 env mem tr aid exc symc ctr n sv iv).layout_state
      = memStep mem sv iv := rfl

end MemProj

/-! ## Read-over-step lemmas (the SL frame/hit laws at the family) -/

theorem i32_len (v : Int) : (i32 v).length = 4 := rfl

theorem memStep_rdN (mem : CerbMem.MemState) (sv iv w : Int)
    (h : CerbMem.readBytesFrom mem nAddr 4 = i32 w) :
    CerbMem.readBytesFrom (memStep mem sv iv) nAddr 4 = i32 w := by
  unfold memStep
  rw [Kit.readBytesFrom_writeBytesTo_disjoint (by left; rw [i32_len]; decide),
    Kit.readBytesFrom_writeBytesTo_disjoint (by left; rw [i32_len]; decide),
    Kit.readBytesFrom_congr_bytemap
      (m1 := { mem with funptrmap := [], lastUsedUnionMembers := [] })
      (m2 := mem) rfl, h]

theorem memStep_rdS (mem : CerbMem.MemState) (sv iv : Int) :
    CerbMem.readBytesFrom (memStep mem sv iv) sAddr 4 = i32 (sv + iv) := by
  unfold memStep
  rw [Kit.readBytesFrom_writeBytesTo_disjoint (by left; rw [i32_len]; decide),
    Kit.readBytesFrom_writeBytesTo_hit (by rw [i32_len])]

theorem memStep_rdI (mem : CerbMem.MemState) (sv iv : Int) :
    CerbMem.readBytesFrom (memStep mem sv iv) iAddr 4 = i32 (iv + 1) := by
  unfold memStep
  rw [Kit.readBytesFrom_writeBytesTo_hit (by rw [i32_len])]

/-! ## The env step (projection-defined; apply-peeled — the chain is
    never spelled) -/

noncomputable def envStepF (e : Fmap sym value) (symc : Nat)
    (n sv iv : Int) : Fmap sym value :=
  envOf (b79 e CerbMem.initialMemState [] 0 0 symc 0 n sv iv)

section EnvProj
variable (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)

theorem b79_env :
    envOf (b79 env mem tr aid exc symc ctr n sv iv)
      = envStepF env symc n sv iv := rfl

theorem bfirst78_env :
    envOf (bfirst78 env mem tr aid exc symc ctr n sv iv)
      = envStepF env symc n sv iv := rfl

end EnvProj

/-- The generated BEq instance the walk's env chain captured (the
    R-S2-1 instance-implicit lesson: synthesis picks `instBEqSym`,
    the emitted spelling is the map-key comparator's). -/
def envBeq : BEq sym :=
  ⟨fun x y => match Lem_Map.mapKeyCompare x y with
    | LemOrdering.EQ => true
    | _ => false⟩

/-- `fmapAddBy_built` at the generated instance. -/
theorem addBy_builtG {c : sym → sym → Ordering}
    {pcmp : sym → sym → LemOrdering} {k : sym} {v : value}
    {m : Fmap sym value} (h : FmapBuilt c m) :
    FmapBuilt c (@fmapAddBy sym value envBeq pcmp k v m) :=
  @Kit.fmapAddBy_built sym value envBeq c pcmp k v m h

theorem envStepF_built (e : Fmap sym value) (symc : Nat) (n sv iv : Int)
    (hb : FmapBuilt symCmpO e) :
    FmapBuilt symCmpO (envStepF e symc n sv iv) :=
  -- 27 chain layers (the walk's per-iteration env block); term-mode
  -- `exact` defeq-unfolds the projection spelling
  addBy_builtG (addBy_builtG (addBy_builtG (addBy_builtG (addBy_builtG
    (addBy_builtG (addBy_builtG (addBy_builtG (addBy_builtG
    (addBy_builtG (addBy_builtG (addBy_builtG (addBy_builtG
    (addBy_builtG (addBy_builtG (addBy_builtG (addBy_builtG
    (addBy_builtG (addBy_builtG (addBy_builtG (addBy_builtG
    (addBy_builtG (addBy_builtG (addBy_builtG (addBy_builtG
    (addBy_builtG (addBy_builtG hb))))))))))))))))))))))))))

end RelSem.T5
