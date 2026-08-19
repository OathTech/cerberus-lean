/-
  CerbFunMapInstances.lean — hand-written SetType instance for
  `generic_fun_map_decl` (arc-7 S2, 2026-08-19; mechanism = the arc-4
  S1a priority-override precedent, CerbStepInstances.lean).

  Why: the Lem Lean backend emits a low-priority sorry-fallback
  `Lem_Basic_classes.SetType (generic_fun_map_decl bty a)` (generated
  Core.lean, `setElemCompare _ _ := sorry`) because the type's `Proc`
  arm carries `generic_expr 'a 'bty Symbol.sym` — a payload the backend
  cannot derive a comparator for. That sorried instance is picked up by
  `Core_aux.collect_labeled_continuations_NEW`, whose call
  `Lem_Map_extra.fold` DEMANDS `[SetType v]` in its SIGNATURE, and so
  `sorryAx` sat in the cone of `initial_driver_state` (and of every
  RelSem def mentioning `initConfig` — the arc-7 D3 ARC-BLOCKING
  finding: the exit theorem mentions initConfig).

  THE REQUIREMENT IS PHANTOM at the only live site:
  `Lem_Map_extra.fold` (LemLib/Map_extra.lean:36) is
      setFold (fun (k,v) r => f k v r) (fmapElements m) v1
  — a foldr over the map's spine list; neither `setFold` nor
  `fmapElements` touches `setElemCompare`. The instance is required,
  never applied. (Same on the OCaml side: lem's `Map_extra.fold` is
  target_rep'd to `Pmap.fold`; no value comparator exists there at all.)

  Semantics of the override (OCaml polymorphic-compare parity, honest at
  the reachable depth):
    - different constructors → tag order. All four constructors are
      OCaml BLOCK constructors (each carries fields), so polymorphic
      `compare` orders them by declaration order in core.lem:351-355:
      Fun < Proc < ProcDecl < BuiltinDecl. Mirrored exactly.
    - same constructor → failwithI (honest-loud, opaque). OCaml compare
      would recurse into the fields (Core exprs are pure data, it would
      normally SUCCEED) — a full hand-written structural comparator over
      the generic_pexpr/generic_expr mutual family is NOT reproduced
      here because no call site can reach it (phantom requirement,
      above); if one ever does, it fails loudly instead of silently
      diverging from OCaml. RECORDED DEVIATION, same class as the
      CerbStepInstances.lean same-tag panic arms.

  Import mechanism: `declare {lean} extra_import` in core_aux.lem (the
  use-site module), exactly the driver.lem/CerbStepInstances precedent —
  `skip_instances` on the TYPE was rejected for the same reason as
  arc-4 S1a: it also suppresses the real low-priority Inhabited/BEq/Ord
  instances that Core.lean itself and downstream generated modules rely
  on, which this file cannot all replace without an import cycle. Any
  NEW generated module that demands `SetType (generic_fun_map_decl …)`
  must also extra_import this file, or it will silently get the sorry
  fallback again — the RelSem in-build audit (fail-closed on sorryAx)
  and check_theorem_axioms.sh are the tripwires.
-/
import Core

set_option autoImplicit false

/-- Declaration-order tag (core.lem:351-355; = OCaml block tag). -/
private def funMapDeclTag {bty a : Type} : generic_fun_map_decl bty a → Nat
  | .Fun _ _ _ => 0
  | .Proc _ _ _ _ _ => 1
  | .ProcDecl _ _ _ => 2
  | .BuiltinDecl _ _ _ => 3

instance {bty : Type} {a : Type} :
    Lem_Basic_classes.SetType (generic_fun_map_decl bty a) where
  setElemCompare x y :=
    let tx := funMapDeclTag x
    let ty := funMapDeclTag y
    if tx < ty then LemOrdering.LT
    else if ty < tx then LemOrdering.GT
    else
      -- Same constructor: OCaml would compare fields structurally; no
      -- call site can reach this (phantom requirement — file header).
      (failwithI "SetType generic_fun_map_decl: same-constructor compare \
                  (phantom instance requirement reached — see \
                  CerbFunMapInstances.lean)" : LemOrdering)
