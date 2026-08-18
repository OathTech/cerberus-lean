/-
  Override Inhabited instances for types where we need computable defaults
  that are better than DAEMON.

  With the DAEMON fallback (noncomputable, priority := low), most types
  don't need overrides. We only provide overrides here for types where:
  1. The default is actually used at runtime (not just for partial def)
  2. We can construct a real value without depending on noncomputable types
-/

import Bimap
import Multiset
import Dlist
import Monadic_parsing
import AilSyntax
import Exception
import ErrorMonad
import Undefined
import Nondeterminism

-- Collections — used at runtime (e.g. empty initial state)

instance {a : Type} {b : Type} : Inhabited (bimap a b) where
  default := Bimap fmapEmpty fmapEmpty

instance {k : Type} : Inhabited (t2 k) where
  default := Multiset fmapEmpty

instance {a : Type} : Inhabited (dlist a) where
  default := Dlist id

instance {a : Type} : Inhabited (parserM a) where
  default := ParserM (fun _ => [])

-- Monadic types — needed computable for partial def.
-- Arc-2 S5d: the former axiom-backed instances (six unconditional axioms,
-- each False-implying for empty parameters — flagged by the pre-merge
-- audit) are replaced by REAL values wherever a constructor with
-- concrete-typed arguments exists, and by [Inhabited]-bounded instances
-- otherwise. Bounded instances resolve at the concrete instantiations
-- partial defs actually use; a failure to resolve is a visible compile
-- error at the def, never a hidden inconsistency.

instance {err : Type} : Inhabited (kill_reason err) where
  default := Undef0 default default

instance {a : Type} {msg : Type} [Inhabited msg] : Inhabited (exceptM a msg) where
  default := Exception default

instance {a : Type} : Inhabited (errorM a) where
  default := ErrorM (fun _ => Sum.inl default)

instance {a : Type} : Inhabited (t0 a) where
  default := Undef default []

instance {a : Type} {err : Type} {st : Type} [Inhabited st] : Inhabited (nd_status a err st) where
  default := Killed default default

instance {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : Inhabited (nd_action a info err cs st) where
  default := NDkilled default

instance {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : Inhabited (ndM a info err cs st) where
  default := ND (fun st => (NDkilled default, st))

-- AilSyntax sigma — the program record, used as initial empty state
instance {a : Type} : Inhabited (sigma a) where
  default := sigma.mk [] [] [] [] [] fmapEmpty fmapEmpty fmapEmpty [] [] [] [] [] fmapEmpty
