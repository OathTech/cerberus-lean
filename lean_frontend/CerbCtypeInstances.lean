/-
  Override instances for mutual recursive types (ctype_, ctype).

  HISTORY (corrected arc-14 S1 F4): pre-arc-10 the Lem backend emitted
  sorry-based BEq/Ord for mutual types, so this file supplied real ones.
  Since arc-10 the backend DERIVES total structural comparisons
  (`ctype.compare_derived`/`ctype_.compare_derived` in generated
  Ctype.lean, OCaml-poly-compare parity) and a real `ctypeEqual`. This
  file's overrides remain because ctype.lem's `ctypeEqual` is the model's
  own ANNOTATION-INSENSITIVE equality (it compares `ty_` only, ignoring
  the annotation list), which is the semantics the pipeline wants for
  BEq — distinct from the derived compare's annotation-SENSITIVE equality.

  BEq stays on `ctypeEqual` (unchanged behavior). Ord is delegated to the
  lawful derived structural order (sem:S4 fix: the previous
  `if ctypeEqual a b then .eq else .lt` was NOT antisymmetric/transitive —
  an unlawful order making any ctype-keyed ordered structure
  insertion-order dependent). NOTE (documented coherence gap): BEq is
  annotation-insensitive while this Ord is annotation-sensitive, so
  `a == b` does not imply `compare a b = .eq` for ctypes differing only
  in annotations. This is acceptable — Std.TreeMap/set keys are ordered
  by Ord alone (lawfulness is what they require), and no consumer relies
  on BEq/Ord coherence for ctype; annotation-bearing ctypes are not used
  as set keys on any differential path (bar-verified zero movement).
-/

import Ctype

-- BEq uses the Lem-generated ctypeEqual function (annotation-insensitive)
instance : BEq ctype where
  beq := ctypeEqual

-- For ctype_, use the ord-based comparison (via Ctype constructor wrapping)
instance : BEq ctype_ where
  beq a b := ctypeEqual (Ctype [] a) (Ctype [] b)

-- Ord instances — the lawful derived structural order (sem:S4). Was an
-- unlawful `if ctypeEqual then .eq else .lt`; now delegates to the
-- generated OCaml-poly-compare-parity comparators.
instance : Ord ctype where
  compare := ctype.compare_derived

instance : Ord ctype_ where
  compare := ctype_.compare_derived

-- Inhabited instances for the mutual types
instance : Inhabited ctype_ where
  default := Void0

instance : Inhabited ctype where
  default := Ctype [] Void0
