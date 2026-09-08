/-
  CerbCoreMeasure — the executable FUEL MEASURE of the context-search mutual
  block `get_ctx` / `get_ctx_unseq_aux` (frontend/model/core_reduction.lem:523-602),
  as a NAMED, ORDINARY DEFINITION over the generated Core types.

  THE MECHANISM (lem-lean `declare {lean} fuel_measure val f = `μ``,
  src/lean_backend.ml:644-716; design [USER 2026-09-04] "we maintain the lem
  structure, and we get additional properties we want without any trust
  decrease"): the fuel WORKER `f_lemFuel` is generated exactly as before; the
  fuel-free WRAPPER instantiates the worker's counter from `μ`, a Lean
  expression over the function's own parameters — `def get_ctx g :=
  get_ctx_lemFuel (CerbCoreMeasure.getCtxBound (Sum.inl g)) g` — and the
  companion obligation `get_ctx_measure_sufficient : μ ≤ lemFuel →
  get_ctx_lemFuel lemFuel g = get_ctx g` is stated in the generated
  Core_reduction_auxiliary.lean and proved by hand in
  Core_reduction_lemMeasureProofs.lean. Lem's measure validator (FM-free,
  lean_backend.ml:706-716, :949) admits exactly: the parameters, `lemSize`
  of a parameter, and QUALIFIED HELPER DEFINITIONS "in a Lean module the
  generated module imports via `declare {lean} extra_import`" — this module
  is that helper module (core_reduction.lem carries the `extra_import`), and
  `getCtxBound` is that qualified definition. It replaces the first landing's
  Lean `macro` of the same term (docs/2026-09-07_fuel-measure-cost-record.md
  §D3 and "Landing improvements"): a macro hides a lambda behind a name the
  validator cannot see into, which evades the validator's intent; a `def`
  is what the validator was written to accept.

  WHY THIS MEASURE (fuel-measure-cost arc, D2 attribution, record §D2): the
  C3 measure `generic_expr.lemSize g + 1` sized the WHOLE arena on every
  driver step — 45 %/39 % of CPU samples on `sa_csmith_369/371`, the two
  csmith rows that fell from MATCH to TIMEOUT at 15 s. The context search
  visits at most ONE child per node, so its call depth is bounded by a walk
  down that spine, never by the arena's size. The bound below is the call
  DEPTH of the mutual block, one unit per worker frame:

    get_ctx (Expr _ node)          — core_reduction.lem:524-588
      Ewseq/Esseq _ e1 _  → get_ctx e1   (:546-561: the LEFT operand only)
      Ebound e            → get_ctx e    (:562-568)
      Eannot _ e          → get_ctx e    (:580-585; the nested-Eannot stop
                                          arm :578-579 is counted too —
                                          conservative, never short)
      Eunseq es           → get_ctx_unseq_aux _ [] [] es   (:542-546)
      every other arm     → no recursive call (:525-541, :569-577, :586-587)
    get_ctx_unseq_aux _ _ _ (e :: es2)   — core_reduction.lem:590-602
      → get_ctx e (:599-600) and get_ctx_unseq_aux _ _ _ es2 (:595, :601)

  The `is_irreducible` tests that PRUNE calls at run time are ignored (the
  bound counts every call the code CAN make); the two workers share ONE
  counter, so every cross-call must strictly decrease the callee's bound
  below the caller's — `getCtxBound_child_lt` — and the bound is positive
  (`getCtxBound_pos`), so the wrapper always enters the `Nat.succ` arm.

  STRUCTURAL, NOT WELL-FOUNDED: the recursion is by structural recursion over
  the nested inductive block (`generic_expr`/`generic_expr_`/`List generic_expr`,
  Lean ≥ 4.12 nested structural recursion), so it is kernel-reducible by
  `rfl` on a concrete term (the consumer's `FuelExemplar.round_done` reduces
  `get_ctx (mk_value_e v)` by `rfl`) and compiles to a direct recursion —
  no `WellFounded.fix`, no erased rank, no unrolled entry frame.

  MIRROR-OCAML NOTE: a Lean-target reasoning artifact; no OCaml text
  corresponds (fuel is a Lean-target artifact; the OCaml `get_ctx` is the
  unbounded `let rec`). `getCtxNext` is a proof SPECIFICATION only (the
  possible recursive calls, as a list); the wrappers execute `getCtxBound`.
-/

import Core
import Core_run_aux

set_option autoImplicit false

namespace CerbCoreMeasure

/-- The two kinds of calls in the context-search mutual block: `get_ctx g`
    on an expression (`Sum.inl g`) and `get_ctx_unseq_aux _ _ _ lemTail` on
    an `Eunseq` operand list (`Sum.inr lemTail`; `lemTail` is the hoisted
    `function` scrutinee, lem d4ba548). The annotation instance is the
    driver's `core_run_annotation` (core_run_aux.lem:18), hence the
    `Core_run_aux` import. -/
abbrev GetCtxState := Sum (generic_expr core_run_annotation Unit sym)
  (List (generic_expr core_run_annotation Unit sym))

mutual
/-- Call-depth bound of `get_ctx e`: the bound of its node. -/
def exprBound : generic_expr core_run_annotation Unit sym → Nat
  | .Expr _ node => nodeBound node
/-- Call-depth bound of `get_ctx (Expr _ node)`: one frame, plus the bound of
    the single child the search may descend into (core_reduction.lem:542-585);
    one frame alone for every arm that returns `[(CTX, expr)]`. -/
def nodeBound : generic_expr_ core_run_annotation Unit sym → Nat
  | .Eunseq es => listBound es + 1
  | .Ewseq _ e _ => exprBound e + 1
  | .Esseq _ e _ => exprBound e + 1
  | .Ebound e => exprBound e + 1
  | .Eannot _ e => exprBound e + 1
  | _ => 1
/-- Call-depth bound of `get_ctx_unseq_aux _ _ _ l`: one frame, plus the
    larger of the head's `get_ctx` bound and the tail's own
    (core_reduction.lem:590-602). -/
def listBound : List (generic_expr core_run_annotation Unit sym) → Nat
  | [] => 1
  | e :: es => max (exprBound e) (listBound es) + 1
end

/-- THE MEASURE of both `fuel_measure` declares (core_reduction.lem:1527-1528):
    `getCtxBound (Sum.inl g)` for `get_ctx`, `getCtxBound (Sum.inr lemTail)`
    for `get_ctx_unseq_aux`. -/
def getCtxBound : GetCtxState → Nat
  | .inl e => exprBound e
  | .inr es => listBound es

/-- The possible recursive calls of a state — the proof SPECIFICATION the
    stability proof descends along (`getCtxBound_child_lt`). Sequences
    search only their left operand; continuations and pure-expression
    payloads never cause a recursive call to either worker. -/
def getCtxNext : GetCtxState → List GetCtxState
  | .inl (.Expr _ (.Eunseq es)) => [.inr es]
  | .inl (.Expr _ (.Ewseq _ e _)) => [.inl e]
  | .inl (.Expr _ (.Esseq _ e _)) => [.inl e]
  | .inl (.Expr _ (.Ebound e)) => [.inl e]
  | .inl (.Expr _ (.Eannot _ e)) => [.inl e]
  | .inl _ => []
  | .inr [] => []
  | .inr (e :: es) => [.inl e, .inr es]

theorem nodeBound_pos (node : generic_expr_ core_run_annotation Unit sym) : 0 < nodeBound node := by
  cases node <;> simp only [nodeBound] <;> omega

theorem exprBound_pos (e : generic_expr core_run_annotation Unit sym) : 0 < exprBound e := by
  obtain ⟨_, node⟩ := e
  simp only [exprBound]
  exact nodeBound_pos node

theorem listBound_pos (l : List (generic_expr core_run_annotation Unit sym)) : 0 < listBound l := by
  cases l <;> simp only [listBound] <;> omega

/-- The bound is positive: the fuel-free wrapper always enters the worker's
    `Nat.succ` arm. -/
theorem getCtxBound_pos (x : GetCtxState) : 0 < getCtxBound x := by
  cases x with
  | inl e => exact exprBound_pos e
  | inr es => exact listBound_pos es

/-- Every possible recursive call strictly decreases the bound: the callee's
    bound is below the caller's, so one shared counter, decremented once per
    frame, suffices for the whole block. -/
theorem getCtxBound_child_lt (x y : GetCtxState) (h : y ∈ getCtxNext x) :
    getCtxBound y < getCtxBound x := by
  cases x with
  | inl e =>
    obtain ⟨annot, node⟩ := e
    cases node <;> simp only [getCtxNext, List.mem_singleton, List.not_mem_nil] at h
    all_goals first
      | contradiction
      | (subst y; simp only [getCtxBound, exprBound, nodeBound]; omega)
  | inr es =>
    cases es with
    | nil => simp [getCtxNext] at h
    | cons e es =>
      simp only [getCtxNext, List.mem_cons, List.not_mem_nil, or_false] at h
      rcases h with h | h <;> subst y <;> simp only [getCtxBound, listBound] <;> omega

end CerbCoreMeasure
