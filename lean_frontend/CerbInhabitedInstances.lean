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

-- Monadic types — needed computable for partial def
-- exceptM: need unconditional computable Inhabited for partial def.
-- DAEMON (noncomputable) breaks partial def compilation.
-- Result/Exception both need their type param to be Inhabited, so we
-- use an axiom-backed instance that's safe (never evaluated at runtime).
private unsafe def exceptM_default {a : Type} {msg : Type} : exceptM a msg := unsafeCast ()
@[implemented_by exceptM_default]
private axiom exceptM_default_safe {a : Type} {msg : Type} : exceptM a msg
instance {a : Type} {msg : Type} : Inhabited (exceptM a msg) where
  default := exceptM_default_safe

-- Same pattern for other monadic types used in partial def
private unsafe def errorM_default {a : Type} : errorM a := unsafeCast ()
@[implemented_by errorM_default]
private axiom errorM_default_safe {a : Type} : errorM a
instance {a : Type} : Inhabited (errorM a) where
  default := errorM_default_safe

private unsafe def t0_default {a : Type} : t0 a := unsafeCast ()
@[implemented_by t0_default]
private axiom t0_default_safe {a : Type} : t0 a
instance {a : Type} : Inhabited (t0 a) where
  default := t0_default_safe

instance {err : Type} : Inhabited (kill_reason err) where
  default := Undef0 default default

private unsafe def nd_status_default {a : Type} {err : Type} {st : Type} : nd_status a err st := unsafeCast ()
@[implemented_by nd_status_default]
private axiom nd_status_default_safe {a : Type} {err : Type} {st : Type} : nd_status a err st
instance {a : Type} {err : Type} {st : Type} : Inhabited (nd_status a err st) where
  default := nd_status_default_safe

private unsafe def nd_action_default {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : nd_action a info err cs st := unsafeCast ()
@[implemented_by nd_action_default]
private axiom nd_action_default_safe {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : nd_action a info err cs st
instance {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : Inhabited (nd_action a info err cs st) where
  default := nd_action_default_safe

private unsafe def ndM_default {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : ndM a info err cs st := unsafeCast ()
@[implemented_by ndM_default]
private axiom ndM_default_safe {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : ndM a info err cs st
instance {a : Type} {info : Type} {err : Type} {cs : Type} {st : Type} : Inhabited (ndM a info err cs st) where
  default := ndM_default_safe

-- AilSyntax sigma — the program record, used as initial empty state
instance {a : Type} : Inhabited (sigma a) where
  default := sigma.mk [] [] [] [] [] fmapEmpty fmapEmpty fmapEmpty [] [] [] [] [] fmapEmpty
