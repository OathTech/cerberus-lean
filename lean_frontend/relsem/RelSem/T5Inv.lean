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
-- arc-18 R4: the ∀-k closure rides the segment faces' env-peel
-- discharger (`seg_env_lookup`) + the registered Kit/Map laws
import RelSem.SegmentFaces

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

/-! # Arc-18 R4 — THE ∀-k FAMILY CLOSURE

    The C3b corrected map's items 1–2 on R2's substrate: every field
    of the walks' hypothesis pack (`T5S.BPack`) proved at `St p k`
    for SYMBOLIC k (and symbolic n), so the seam demo's body
    obligations close over the whole harness family. Mechanical peels
    live here (engine-room); the composition and statement stay in
    RelSem/T5.lean (the gated slate file). -/

/-! ## The apartness budget (the T5SeedApart bound's shadow) -/

/-- The supply ceiling every fresh-symbol hash stays below (static
    symbol hashes are ≥ 2⁶⁰). -/
def supplyCeil : Nat := 1152921504606846976

/-! ## Byte roundtrip at symbolic values (the T1AppEq recipe, cloned
    fixture-locally — the C5-retirement file is NOT imported) -/

/-- THE BYTE ROUNDTRIP: 4 little-endian bytes of an int-range integer
    recombine (signed) to the integer. -/
theorem roundtrip5 (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) :
    CerbMem.bytesToInt (i32 x) true = some x := by
  unfold i32 CerbMem.bytesToInt mkByte
  simp only [List.any, Option.isNone, Bool.or_false, CerbMem.bytesToInt.go]
  by_cases hx : x < 0
  · have hy0 : (0:Int) ≤ 4294967296 + x := by omega
    have hy1 : (0:Int) ≤ (4294967296 + x) / 256 := by omega
    have hy2 : (0:Int) ≤ (4294967296 + x) / 65536 := by omega
    have hy3 : (0:Int) ≤ (4294967296 + x) / 16777216 := by omega
    have d1 : (4294967296 + x) / 256 / 256 = (4294967296 + x) / 65536 := by omega
    have d2 : (4294967296 + x) / 65536 / 256 = (4294967296 + x) / 16777216 := by omega
    have d3 : (4294967296 + x) / 16777216 / 256 = 0 := by omega
    simp only [hx, if_true, if_false, reduceIte]
    simp [Int.shiftLeft_eq, Int.shiftRight_eq_div_pow, Int.toNat_of_nonneg hy0,
      Int.toNat_of_nonneg hy1, Int.toNat_of_nonneg hy2, Int.toNat_of_nonneg hy3]
    split <;> refine congrArg some ?_ <;> omega
  · have hx0 : (0:Int) ≤ x := by omega
    have hx1 : (0:Int) ≤ x / 256 := by omega
    have hx2 : (0:Int) ≤ x / 65536 := by omega
    have hx3 : (0:Int) ≤ x / 16777216 := by omega
    have d1 : x / 256 / 256 = x / 65536 := by omega
    have d2 : x / 65536 / 256 = x / 16777216 := by omega
    have d3 : x / 16777216 / 256 = 0 := by omega
    simp only [hx, if_true, if_false, reduceIte]
    simp [Int.shiftLeft_eq, Int.shiftRight_eq_div_pow, Int.toNat_of_nonneg hx0,
      Int.toNat_of_nonneg hx1, Int.toNat_of_nonneg hx2, Int.toNat_of_nonneg hx3]
    split <;> refine congrArg some ?_ <;> omega

/-- reconstructValue on an int-range byte image = the integer (the
    pack's `hrec*` supplier at symbolic values; address-generic). -/
theorem recon_i32 (addr v : Int) (h1 : -2147483648 ≤ v)
    (h2 : v ≤ 2147483647) :
    CerbMem.reconstructValue [] [] addr intCty (i32 v) = mvi v := by
  show CerbMem.reconstructValue_lemFuel (999999+1) _ _ _
    (Ctype [] (Basic (Integer (Signed Int_)))) _ = _
  rw [CerbMem.reconstructValue_lemFuel]
  simp only [CerberusImpl.is_signed_ity]
  rw [show CerbMem.bytesToInt (i32 v) true = some v
    from roundtrip5 v h1 h2]
  simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, i32, mkByte]

/-- memValueToBytes at the symbolic int image (the pack's `hi2b*`). -/
theorem i2b_i32 (v : Int) :
    CerbMem.memValueToBytes [] (mvi v) = ([], i32 v) := rfl

/-! ## triF bounds (the loop measure's arithmetic envelope) -/

theorem triF_nonneg (k : Nat) : 0 ≤ triF k := by
  induction k with
  | zero => decide
  | succ k ih => show 0 ≤ triF k + (k : Int); omega

theorem triF_le (k : Nat) (hk : k ≤ 100) : triF k ≤ 4950 := by
  match k with
  | 0 => decide
  | (m + 1) =>
    have hd := triF_double (m + 1)
    have h1 : ((m + 1 : Nat) : Int) ≤ 100 := by omega
    have h2 : (0 : Int) ≤ ((m + 1 : Nat) : Int) - 1 := by omega
    have h3 : ((m + 1 : Nat) : Int) - 1 ≤ 99 := by omega
    have hsq : ((m + 1 : Nat) : Int) * (((m + 1 : Nat) : Int) - 1)
        ≤ 100 * 99 :=
      Int.mul_le_mul h1 h3 h2 (by omega)
    omega

/-! ## Supply families (closed forms; the bounds feed) -/

section SupplyPins
variable (bm : Std.TreeMap Int CerbMem.AbsByte)
  (am : Std.TreeMap Int CerbMem.Allocation)
  (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)

theorem e22_symc :
    (e22 bm am tr aid exc symc ctr).core_run_state0.sym_supply
      = symc := rfl
theorem e22_exc :
    (e22 bm am tr aid exc symc ctr).core_run_state0.excluded_supply
      = exc := rfl
theorem b79_symc :
    (b79 env mem tr aid exc symc ctr n sv iv).core_run_state0.sym_supply
      = symc + 2 := rfl
theorem b79_exc :
    (b79 env mem tr aid exc symc ctr n sv iv).core_run_state0.excluded_supply
      = exc + 2 := rfl
theorem bfirst78_symc :
    (bfirst78 env mem tr aid exc symc ctr n sv iv).core_run_state0.sym_supply
      = symc + 2 := rfl
theorem bfirst78_exc :
    (bfirst78 env mem tr aid exc symc ctr n sv iv).core_run_state0.excluded_supply
      = exc + 2 := rfl

end SupplyPins

theorem St_symc (p : Pm) (k : Nat) :
    (St p k).core_run_state0.sym_supply = p.symc0 + 2 * k := by
  induction k with
  | zero => rfl
  | succ k ih =>
    match k with
    | 0 => simp only [St]; rw [bfirst78_symc, e22_symc]
    | k + 1 =>
      simp only [St]; rw [b79_symc, ih]; omega

theorem St_exc (p : Pm) (k : Nat) :
    (St p k).core_run_state0.excluded_supply = p.exc0 + 2 * k := by
  induction k with
  | zero => rfl
  | succ k ih =>
    match k with
    | 0 => simp only [St]; rw [bfirst78_exc, e22_exc]
    | k + 1 =>
      simp only [St]; rw [b79_exc, ih]; omega

/-! ## Layout scalar families (fpm/lum for the pack; dead/allocs are
    the landed `St_dead`/`St_allocs`) -/

theorem St_fpm (p : Pm) (k : Nat) :
    (St p k).layout_state.funptrmap = [] := by
  match k with
  | 0 => rfl
  | 1 => rfl
  | k + 2 => rfl

theorem St_lum (p : Pm) (k : Nat) :
    (St p k).layout_state.lastUsedUnionMembers = [] := by
  match k with
  | 0 => rfl
  | 1 => rfl
  | k + 2 => rfl

/-! ## The env family: built-ness, lookups (∀ k; the R4 closure of
    the seam demo's `hbuilt`/`hlk*` fields) -/

/-- envStepF preserves the n lookup (skip-only peel: the body chain
    never rebinds n; discharged by the R4-hardened
    `seg_env_lookup` — built-chain threading at the open base). -/
theorem envStepF_lkN (env : Fmap sym value) (symc : Nat) (n sv iv : Int)
    (hb : FmapBuilt symCmpO env) (hscB : symc < supplyCeil) :
    fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
        (envStepF env symc n sv iv)
      = fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN env := by
  have hscB' : symc < 1152921504606846976 := hscB
  seg_env_lookup

/-- envStepF pins the s lookup (the chain REBINDS s at the same
    pointer — a hit layer, not a skip to the base). -/
theorem envStepF_lkS (env : Fmap sym value) (symc : Nat) (n sv iv : Int)
    (hb : FmapBuilt symCmpO env) (hscB : symc < supplyCeil) :
    fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS
        (envStepF env symc n sv iv)
      = some (Vobject (OVpointer sPtr)) := by
  have hscB' : symc < 1152921504606846976 := hscB
  seg_env_lookup

/-- envStepF pins the i lookup (rebind hit). -/
theorem envStepF_lkI (env : Fmap sym value) (symc : Nat) (n sv iv : Int)
    (hb : FmapBuilt symCmpO env) (hscB : symc < supplyCeil) :
    fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symI
        (envStepF env symc n sv iv)
      = some (Vobject (OVpointer iPtr)) := by
  have hscB' : symc < 1152921504606846976 := hscB
  seg_env_lookup

theorem St_env_step (p : Pm) (k : Nat) :
    envOf (St p (k + 1))
      = envStepF (envOf (St p k))
          ((St p k).core_run_state0.sym_supply) p.n (triF k) k := by
  match k with
  | 0 => simp only [St]; exact bfirst78_env ..
  | k + 1 => simp only [St]; exact b79_env ..

theorem St_built (p : Pm) (k : Nat) :
    FmapBuilt symCmpO (envOf (St p k)) := by
  induction k with
  | zero => exact rfl
  | succ k ih =>
    rw [St_env_step p k]
    exact envStepF_built _ _ _ _ _ ih

theorem St_lkN (p : Pm) (hsc : p.symc0 + 256 < supplyCeil) (k : Nat)
    (hk : k ≤ 100) :
    fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symN
        (envOf (St p k))
      = some (Vobject (OVpointer nPtr)) := by
  induction k with
  | zero =>
    show fmapLookupBy _ symN (envOf (e22 p.bm p.am p.tr0 p.aid0 p.exc0
      p.symc0 p.ctr0)) = _
    have hscB : p.symc0 < 1152921504606846976 := by
      have : supplyCeil = 1152921504606846976 := rfl
      omega
    seg_env_lookup
  | succ k ih =>
    rw [St_env_step p k]
    rw [envStepF_lkN _ _ _ _ _ (St_built p k)
      (by rw [St_symc]; show _ < supplyCeil
          have : supplyCeil = 1152921504606846976 := rfl
          omega)]
    exact ih (by omega)

theorem St_lkS (p : Pm) (hsc : p.symc0 + 256 < supplyCeil) (k : Nat)
    (hk : k ≤ 100) :
    fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symS
        (envOf (St p k))
      = some (Vobject (OVpointer sPtr)) := by
  match k with
  | 0 =>
    show fmapLookupBy _ symS (envOf (e22 p.bm p.am p.tr0 p.aid0 p.exc0
      p.symc0 p.ctr0)) = _
    have hscB : p.symc0 < 1152921504606846976 := by
      have : supplyCeil = 1152921504606846976 := rfl
      omega
    seg_env_lookup
  | k + 1 =>
    rw [St_env_step p k]
    exact envStepF_lkS _ _ _ _ _ (St_built p k)
      (by rw [St_symc]; show _ < supplyCeil
          have : supplyCeil = 1152921504606846976 := rfl
          omega)

theorem St_lkI (p : Pm) (hsc : p.symc0 + 256 < supplyCeil) (k : Nat)
    (hk : k ≤ 100) :
    fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) symI
        (envOf (St p k))
      = some (Vobject (OVpointer iPtr)) := by
  match k with
  | 0 =>
    show fmapLookupBy _ symI (envOf (e22 p.bm p.am p.tr0 p.aid0 p.exc0
      p.symc0 p.ctr0)) = _
    have hscB : p.symc0 < 1152921504606846976 := by
      have : supplyCeil = 1152921504606846976 := rfl
      omega
    seg_env_lookup
  | k + 1 =>
    rw [St_env_step p k]
    exact envStepF_lkI _ _ _ _ _ (St_built p k)
      (by rw [St_symc]; show _ < supplyCeil
          have : supplyCeil = 1152921504606846976 := rfl
          omega)

/-! ## The byte family, pointwise (the pack's `hrd*` + the scratch2
    rule's `hFout`/`hFin*` suppliers). The e22 base ladder is exposed
    by its canonical tidy pin (kernel-checked against the minted
    field-by-field emission). -/

theorem sAddr_eq : sAddr = (281474976710640 : Int) := rfl
theorem iAddr_eq : iAddr = (281474976710636 : Int) := rfl
theorem nAddr_eq : nAddr = (281474976710648 : Int) := rfl
theorem uninit4_len :
    (List.replicate 4 uninitB).length = 4 := rfl

/-- e22's layout in the canonical alloc-store-ladder spelling
    (kernel-checked against the minted field-by-field emission). -/
theorem e22_mem (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) :
    (e22 bm am tr aid exc symc ctr).layout_state
      = CerbMem.writeBytesTo
          { CerbMem.writeBytesTo
              { CerbMem.writeBytesTo
                  { CerbMem.writeBytesTo
                      { CerbMem.initialMemState with
                        nextAllocId := 3, lastAddress := sAddr,
                        allocations := am.insert 2 allocS, bytemap := bm }
                      sAddr (List.replicate 4 uninitB) with
                    funptrmap := [] }
                  sAddr (i32 0) with
                nextAllocId := 4, lastAddress := iAddr,
                allocations := (am.insert 2 allocS).insert 3 allocI }
              iAddr (List.replicate 4 uninitB) with
            funptrmap := [] }
          iAddr (i32 0) := rfl

/-- e22's bytemap as a writeList ladder over the harness map. -/
theorem e22_bytemap (bm : Std.TreeMap Int CerbMem.AbsByte)
    (am : Std.TreeMap Int CerbMem.Allocation)
    (tr : List trace_event) (aid exc symc ctr : Nat) :
    (e22 bm am tr aid exc symc ctr).layout_state.bytemap
      = writeList (writeList (writeList (writeList bm
          sAddr (List.replicate 4 uninitB)) sAddr (i32 0))
          iAddr (List.replicate 4 uninitB)) iAddr (i32 0) := by
  rw [e22_mem]
  simp only [writeBytesTo_eq]

/-- memStep's bytemap as a writeList ladder. -/
theorem memStep_bytemap (mem : CerbMem.MemState) (sv iv : Int) :
    (memStep mem sv iv).bytemap
      = writeList (writeList mem.bytemap sAddr (i32 (sv + iv)))
          iAddr (i32 (iv + 1)) := by
  unfold memStep
  simp only [writeBytesTo_eq]

/-- The family's one-step memory law at the head index. -/
theorem St_mem_step (p : Pm) (k : Nat) :
    (St p (k + 1)).layout_state
      = memStep (St p k).layout_state (triF k) (k : Int) := by
  match k with
  | 0 => simp only [St]; exact bfirst78_mem ..
  | k + 1 => simp only [St]; exact b79_mem ..

/-- Out-of-range keys of the k-th head's bytemap read the harness
    map (the frame face of the family). -/
theorem St_bm_out (p : Pm) (k : Nat) (a : Int)
    (hs : ¬(sAddr ≤ a ∧ a < sAddr + 4))
    (hi : ¬(iAddr ≤ a ∧ a < iAddr + 4)) :
    (St p k).layout_state.bytemap.get? a = p.bm.get? a := by
  have h1 := sAddr_eq
  have h2 := iAddr_eq
  induction k with
  | zero =>
    show (e22 p.bm p.am p.tr0 p.aid0 p.exc0 p.symc0
      p.ctr0).layout_state.bytemap.get? a = _
    rw [e22_bytemap,
      writeList_get?_notin _ _ _ _ (by rw [i32_len]; omega),
      writeList_get?_notin _ _ _ _ (by rw [uninit4_len]; omega),
      writeList_get?_notin _ _ _ _ (by rw [i32_len]; omega),
      writeList_get?_notin _ _ _ _ (by rw [uninit4_len]; omega)]
  | succ k ih =>
    rw [St_mem_step p k, memStep_bytemap,
      writeList_get?_notin _ _ _ _ (by rw [i32_len]; omega),
      writeList_get?_notin _ _ _ _ (by rw [i32_len]; omega)]
    exact ih

/-- The s range of the k-th head reads the loop measure's image. -/
theorem St_bm_s (p : Pm) (k : Nat) (i : Nat) (hi : i < 4) :
    (St p k).layout_state.bytemap.get? (sAddr + (i : Int))
      = (i32 (triF k))[i]? := by
  have h1 := sAddr_eq
  have h2 := iAddr_eq
  induction k with
  | zero =>
    show (e22 p.bm p.am p.tr0 p.aid0 p.exc0 p.symc0
      p.ctr0).layout_state.bytemap.get? _ = _
    rw [e22_bytemap,
      writeList_get?_notin _ _ _ _ (by rw [i32_len]; omega),
      writeList_get?_notin _ _ _ _ (by rw [uninit4_len]; omega),
      writeList_get?_in _ _ _ _ (by omega) (by rw [i32_len]; omega)]
    show (i32 0)[((sAddr + (i : Int)) - sAddr).toNat]? = _
    congr 1
    omega
  | succ k ih =>
    rw [St_mem_step p k, memStep_bytemap,
      writeList_get?_notin _ _ _ _ (by rw [i32_len]; omega),
      writeList_get?_in _ _ _ _ (by omega) (by rw [i32_len]; omega)]
    show (i32 (triF k + (k : Int)))[((sAddr + (i : Int)) - sAddr).toNat]?
      = (i32 (triF (k + 1)))[i]?
    congr 1
    omega

/-- The i range of the k-th head reads the counter's image. -/
theorem St_bm_i (p : Pm) (k : Nat) (i : Nat) (hi : i < 4) :
    (St p k).layout_state.bytemap.get? (iAddr + (i : Int))
      = (i32 (k : Int))[i]? := by
  have h1 := sAddr_eq
  have h2 := iAddr_eq
  induction k with
  | zero =>
    show (e22 p.bm p.am p.tr0 p.aid0 p.exc0 p.symc0
      p.ctr0).layout_state.bytemap.get? _ = _
    rw [e22_bytemap,
      writeList_get?_in _ _ _ _ (by omega) (by rw [i32_len]; omega)]
    show (i32 0)[((iAddr + (i : Int)) - iAddr).toNat]? = _
    congr 1
    omega
  | succ k ih =>
    rw [St_mem_step p k, memStep_bytemap,
      writeList_get?_in _ _ _ _ (by omega) (by rw [i32_len]; omega)]
    show (i32 ((k : Int) + 1))[((iAddr + (i : Int)) - iAddr).toNat]?
      = (i32 (((k + 1 : Nat)) : Int))[i]?
    have hc : (((k + 1 : Nat)) : Int) = (k : Int) + 1 := by omega
    rw [hc]
    congr 1
    omega

/-! ## The readBytesFrom faces (the pack's `hrd*`) -/

theorem i32_get (v : Int) (i : Nat) (hi : i < 4) :
    (i32 v)[i]? = some ((i32 v)[i]'(by rw [show (i32 v).length = 4 from rfl]; omega)) :=
  List.getElem?_eq_getElem (by rw [show (i32 v).length = 4 from rfl]; omega)

theorem St_rdN (p : Pm)
    (hb : ∀ i : Nat, (hi : i < 4) →
      p.bm.get? (nAddr + (i : Int)) = (i32 p.n)[i]?)
    (k : Nat) :
    CerbMem.readBytesFrom (St p k).layout_state nAddr 4 = i32 p.n := by
  refine readBytesFrom_of_pointwise (by rfl) ?_
  intro i hi
  have hi4 : i < 4 := by rw [show (i32 p.n).length = 4 from rfl] at hi; omega
  rw [St_bm_out p k _
    (by rw [sAddr_eq, nAddr_eq]; omega)
    (by rw [iAddr_eq, nAddr_eq]; omega),
    hb i hi4]
  exact i32_get p.n i hi4

theorem St_rdS (p : Pm) (k : Nat) :
    CerbMem.readBytesFrom (St p k).layout_state sAddr 4
      = i32 (triF k) := by
  refine readBytesFrom_of_pointwise (by rfl) ?_
  intro i hi
  have hi4 : i < 4 := by rw [show (i32 (triF k)).length = 4 from rfl] at hi; omega
  rw [St_bm_s p k i hi4]
  exact i32_get _ i hi4

theorem St_rdI (p : Pm) (k : Nat) :
    CerbMem.readBytesFrom (St p k).layout_state iAddr 4
      = i32 (k : Int) := by
  refine readBytesFrom_of_pointwise (by rfl) ?_
  intro i hi
  have hi4 : i < 4 := by rw [show (i32 ((k : Nat) : Int)).length = 4 from rfl] at hi; omega
  rw [St_bm_i p k i hi4]
  exact i32_get _ i hi4

/-! ## Allocation-table + dead-list faces (the pack's `hal*`/`hdd*`) -/

theorem St_alN (p : Pm) (ham : p.am.get? 0 = some allocN) (k : Nat) :
    (St p k).layout_state.allocations.get? 0 = some allocN := by
  rw [St_allocs,
    tmInt_get?_insert_ne _ _ (by omega),
    tmInt_get?_insert_ne _ _ (by omega)]
  exact ham

theorem St_alS (p : Pm) (k : Nat) :
    (St p k).layout_state.allocations.get? 2 = some allocS := by
  rw [St_allocs, tmInt_get?_insert_ne _ _ (by omega)]
  exact tmInt_get?_insert_self _ _ _

theorem St_alI (p : Pm) (k : Nat) :
    (St p k).layout_state.allocations.get? 3 = some allocI := by
  rw [St_allocs]
  exact tmInt_get?_insert_self _ _ _

theorem St_dd (p : Pm) (k : Nat) (x : Int) :
    (St p k).layout_state.deadAllocations.contains x = false := by
  rw [St_dead]
  rfl

/-! ## Map-independence of the rest (the driver-atom rule's fixed-ρ'
    feed): the k-th head's REST — everything but the two heap maps —
    does not depend on the harness maps. Every step is a kernel rfl
    (the builders consume their state arguments only through
    rest-visible projections; probe-verified), so the induction is
    rfl + IH-rewrites. -/

/-- The family's parameters at zeroed heap maps (the canonical
    representative the fixed rest is defined at). -/
def zeroP (p : Pm) : Pm :=
  { p with bm := Std.TreeMap.empty, am := Std.TreeMap.empty }

theorem St_rest_indep (p : Pm) (k : Nat) :
    restOf (St p k) = restOf (St (zeroP p) k) := by
  induction k with
  | zero => rfl
  | succ k ih =>
    match k, ih with
    | 0, ih =>
      simp only [St]
      calc restOf (bfirst78 (envOf (St p 0)) (St p 0).layout_state
            (St p 0).trace (St p 0).core_run_state0.aid_supply
            (St p 0).core_run_state0.excluded_supply
            (St p 0).core_run_state0.sym_supply (St p 0).dr_step_counter
            p.n (triF 0) 0)
          = restOf (bfirst78 (envOf (restOf (St p 0)))
            (restOf (St p 0)).layout_state (restOf (St p 0)).trace
            (restOf (St p 0)).core_run_state0.aid_supply
            (restOf (St p 0)).core_run_state0.excluded_supply
            (restOf (St p 0)).core_run_state0.sym_supply
            (restOf (St p 0)).dr_step_counter p.n (triF 0) 0) := rfl
        _ = restOf (bfirst78 (envOf (restOf (St (zeroP p) 0)))
            (restOf (St (zeroP p) 0)).layout_state
            (restOf (St (zeroP p) 0)).trace
            (restOf (St (zeroP p) 0)).core_run_state0.aid_supply
            (restOf (St (zeroP p) 0)).core_run_state0.excluded_supply
            (restOf (St (zeroP p) 0)).core_run_state0.sym_supply
            (restOf (St (zeroP p) 0)).dr_step_counter p.n (triF 0) 0) := by
            rw [ih]
        _ = _ := rfl
    | (k + 1), ih =>
      simp only [St]
      calc restOf (b79 (envOf (St p (k + 1))) (St p (k + 1)).layout_state
            (St p (k + 1)).trace (St p (k + 1)).core_run_state0.aid_supply
            (St p (k + 1)).core_run_state0.excluded_supply
            (St p (k + 1)).core_run_state0.sym_supply
            (St p (k + 1)).dr_step_counter p.n (triF (k + 1)) (k + 1))
          = restOf (b79 (envOf (restOf (St p (k + 1))))
            (restOf (St p (k + 1))).layout_state
            (restOf (St p (k + 1))).trace
            (restOf (St p (k + 1))).core_run_state0.aid_supply
            (restOf (St p (k + 1))).core_run_state0.excluded_supply
            (restOf (St p (k + 1))).core_run_state0.sym_supply
            (restOf (St p (k + 1))).dr_step_counter
            p.n (triF (k + 1)) (k + 1)) := rfl
        _ = restOf (b79 (envOf (restOf (St (zeroP p) (k + 1))))
            (restOf (St (zeroP p) (k + 1))).layout_state
            (restOf (St (zeroP p) (k + 1))).trace
            (restOf (St (zeroP p) (k + 1))).core_run_state0.aid_supply
            (restOf (St (zeroP p) (k + 1))).core_run_state0.excluded_supply
            (restOf (St (zeroP p) (k + 1))).core_run_state0.sym_supply
            (restOf (St (zeroP p) (k + 1))).dr_step_counter
            p.n (triF (k + 1)) (k + 1)) := by
            rw [ih]
        _ = _ := rfl

/-! ## The exit endpoints (the composition's terminal leg; the twin
    spellings route by trip count exactly as the seam's `St` does) -/

/-- The exit endpoint from the k-th head, STORED spelling (every
    n ≥ 1 exit). -/
noncomputable def exitAt (p : Pm) (k : Nat) : driver_state :=
  bx44 (envOf (St p k)) (St p k).layout_state (St p k).trace
    (St p k).core_run_state0.aid_supply
    (St p k).core_run_state0.excluded_supply
    (St p k).core_run_state0.sym_supply (St p k).dr_step_counter
    p.n (triF k) (k : Int)

/-- The exit endpoint from the entry-spelled head (the n = 0 exit). -/
noncomputable def exitAt0 (p : Pm) : driver_state :=
  bxzero43 (envOf (St p 0)) (St p 0).layout_state (St p 0).trace
    (St p 0).core_run_state0.aid_supply
    (St p 0).core_run_state0.excluded_supply
    (St p 0).core_run_state0.sym_supply (St p 0).dr_step_counter
    p.n (triF 0) 0

/-- THE FINAL STATE of the composed run (pre-`prepare_exit`): the
    exit endpoint at the trip count. -/
noncomputable def stFin (p : Pm) : driver_state :=
  match p.n.toNat with
  | 0 => exitAt0 p
  | m + 1 => exitAt p (m + 1)

theorem bx44_of_rest (σ : driver_state) (n sv iv : Int) :
    restOf (bx44 (envOf σ) σ.layout_state σ.trace
      σ.core_run_state0.aid_supply σ.core_run_state0.excluded_supply
      σ.core_run_state0.sym_supply σ.dr_step_counter n sv iv)
    = restOf (bx44 (envOf (restOf σ)) (restOf σ).layout_state
      (restOf σ).trace (restOf σ).core_run_state0.aid_supply
      (restOf σ).core_run_state0.excluded_supply
      (restOf σ).core_run_state0.sym_supply
      (restOf σ).dr_step_counter n sv iv) := rfl

theorem bxzero43_of_rest (σ : driver_state) (n sv iv : Int) :
    restOf (bxzero43 (envOf σ) σ.layout_state σ.trace
      σ.core_run_state0.aid_supply σ.core_run_state0.excluded_supply
      σ.core_run_state0.sym_supply σ.dr_step_counter n sv iv)
    = restOf (bxzero43 (envOf (restOf σ)) (restOf σ).layout_state
      (restOf σ).trace (restOf σ).core_run_state0.aid_supply
      (restOf σ).core_run_state0.excluded_supply
      (restOf σ).core_run_state0.sym_supply
      (restOf σ).dr_step_counter n sv iv) := rfl

theorem exitAt_rest_indep (p : Pm) (k : Nat) :
    restOf (exitAt p k) = restOf (exitAt (zeroP p) k) := by
  unfold exitAt
  rw [bx44_of_rest, St_rest_indep p k, ← bx44_of_rest,
    show (zeroP p).n = p.n from rfl]

theorem exitAt0_rest_indep (p : Pm) :
    restOf (exitAt0 p) = restOf (exitAt0 (zeroP p)) := by
  unfold exitAt0
  rw [bxzero43_of_rest, St_rest_indep p 0, ← bxzero43_of_rest,
    show (zeroP p).n = p.n from rfl]

theorem stFin_rest_indep (p : Pm) :
    restOf (stFin p) = restOf (stFin (zeroP p)) := by
  unfold stFin
  rw [show (zeroP p).n = p.n from rfl]
  cases hN : p.n.toNat with
  | zero => exact exitAt0_rest_indep p
  | succ m => exact exitAt_rest_indep p (m + 1)

/-! ## The exit endpoint's layout faces (the scratch2 rule's
    pointwise/allocation feed at the final state) -/

section ExitLayout
variable (env : Fmap sym value) (mem : CerbMem.MemState)
  (tr : List trace_event) (aid exc symc ctr : Nat) (n sv iv : Int)

theorem bx44_layout :
    (bx44 env mem tr aid exc symc ctr n sv iv).layout_state
      = { mem with
          allocations := (mem.allocations.erase 3).erase 2,
          deadAllocations := 2 :: 3 :: mem.deadAllocations,
          funptrmap := [], lastUsedUnionMembers := [] } := rfl

theorem bxzero43_layout :
    (bxzero43 env mem tr aid exc symc ctr n sv iv).layout_state
      = { mem with
          allocations := (mem.allocations.erase 3).erase 2,
          deadAllocations := 2 :: 3 :: mem.deadAllocations,
          funptrmap := [], lastUsedUnionMembers := [] } := rfl

end ExitLayout

/-- The final state's layout, uniformly across the twin exits (the
    match routes; both spellings kill i then s over the head
    layout). -/
theorem stFin_layout (p : Pm) :
    (stFin p).layout_state
      = { (St p p.n.toNat).layout_state with
          allocations :=
            (((St p p.n.toNat).layout_state.allocations.erase 3).erase 2),
          deadAllocations :=
            2 :: 3 :: (St p p.n.toNat).layout_state.deadAllocations,
          funptrmap := [], lastUsedUnionMembers := [] } := by
  unfold stFin
  cases hN : p.n.toNat with
  | zero =>
    show (exitAt0 p).layout_state = _
    rw [show exitAt0 p = bxzero43 (envOf (St p 0))
        (St p 0).layout_state (St p 0).trace
        (St p 0).core_run_state0.aid_supply
        (St p 0).core_run_state0.excluded_supply
        (St p 0).core_run_state0.sym_supply (St p 0).dr_step_counter
        p.n (triF 0) 0 from rfl, bxzero43_layout]
  | succ m =>
    show (exitAt p (m + 1)).layout_state = _
    rw [show exitAt p (m + 1) = bx44 (envOf (St p (m + 1)))
        (St p (m + 1)).layout_state (St p (m + 1)).trace
        (St p (m + 1)).core_run_state0.aid_supply
        (St p (m + 1)).core_run_state0.excluded_supply
        (St p (m + 1)).core_run_state0.sym_supply
        (St p (m + 1)).dr_step_counter
        p.n (triF (m + 1)) ((m + 1 : Nat) : Int) from rfl, bx44_layout]

end RelSem.T5
