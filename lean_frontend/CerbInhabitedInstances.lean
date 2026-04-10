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

-- Collections — used at runtime (e.g. empty initial state)

instance {a : Type} {b : Type} : Inhabited (bimap a b) where
  default := Bimap fmapEmpty fmapEmpty

instance {k : Type} : Inhabited (t2 k) where
  default := Multiset fmapEmpty

instance {a : Type} : Inhabited (dlist a) where
  default := Dlist id

instance {a : Type} : Inhabited (parserM a) where
  default := ParserM (fun _ => [])

-- AilSyntax sigma — the program record, used as initial empty state
instance {a : Type} : Inhabited (sigma a) where
  default := sigma.mk [] [] [] [] [] fmapEmpty fmapEmpty fmapEmpty [] [] [] [] [] fmapEmpty
