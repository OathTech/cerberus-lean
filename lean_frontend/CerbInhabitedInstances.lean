/-
  Override Inhabited instances for parametric types where Lem generates sorry.

  The Lem backend can't always find a suitable default for parametric types.
  These overrides provide real defaults using `default` for type parameters,
  which delegates to the caller's Inhabited instance.

  All generated sorry instances use `(priority := low)` so these overrides
  take precedence automatically.
-/

import Exception
import ErrorMonad
import Undefined
import Dlist
import Multiset
import Bimap
import Monadic_parsing
import Nondeterminism
import Cerb_attributes
import AilSyntax
import Cn
import Core
import Core_aux
import Core_reduction
import Core_run_aux

-- Simple wrapper types

instance {a : Type} {msg : Type} [Inhabited a] : Inhabited (exceptM a msg) where
  default := Result default

instance {a : Type} [Inhabited a] : Inhabited (errorM a) where
  default := ErrorM (fun annots => Sum.inr (default, annots))

instance {a : Type} [Inhabited a] : Inhabited (t0 a) where
  default := Defined default

-- Collections

instance {a : Type} : Inhabited (dlist a) where
  default := Dlist id

instance {k : Type} : Inhabited (t2 k) where
  default := Multiset fmapEmpty

instance {a : Type} {b : Type} : Inhabited (bimap a b) where
  default := Bimap fmapEmpty fmapEmpty

-- Monadic/parsing types

instance {a : Type} : Inhabited (parserM a) where
  default := ParserM (fun _ => [])

instance {err : Type} : Inhabited (kill_reason err) where
  default := Undef0 default default

instance {a : Type} {err : Type} {st : Type} [Inhabited a] : Inhabited (nd_status a err st) where
  default := Active default

-- Cerberus attribute decoding

instance {a : Type} [Inhabited a] : Inhabited (cerb_attributes_decoding a) where
  default := CAttr_valid default default

-- AilSyntax sigma (the program record type)

instance {a : Type} : Inhabited (sigma a) where
  default := sigma.mk [] [] [] [] [] fmapEmpty fmapEmpty fmapEmpty [] [] [] [] [] fmapEmpty

-- CN types (all parametric, from cn.lem)

instance {a : Type} {ty : Type} [Inhabited ty] : Inhabited (cn_pred a ty) where
  default := CN_owned default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_resource a ty) where
  default := CN_pred default default default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_assertion a ty) where
  default := CN_assert_exp default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_clause a ty) where
  default := CN_letExpr default default default default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_clauses a ty) where
  default := CN_clause default default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_condition a ty) where
  default := CN_cletResource default default default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_statement_ a ty) where
  default := CN_pack_unpack default default default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_statement a ty) where
  default := CN_statement default default

instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_loop_spec a ty) where
  default := CN_inv default default

instance {a : Type} [Inhabited a] : Inhabited (cn_acc_func a) where
  default := CN_accesses default

-- cn_function: 7 fields
instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_function a ty) where
  default := cn_function.mk default default default default default default default

-- cn_lemma: 6 fields
instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_lemma a ty) where
  default := cn_lemma.mk default default default default default default

-- cn_predicate: 7 fields
instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_predicate a ty) where
  default := cn_predicate.mk default default default default default default default

-- cn_datatype: 4 fields
instance {a : Type} [Inhabited a] : Inhabited (cn_datatype a) where
  default := cn_datatype.mk default default default default

-- cn_type_synonym: 4 fields
instance {a : Type} [Inhabited a] : Inhabited (cn_type_synonym a) where
  default := cn_type_synonym.mk default default default default

-- cn_decl_spec: 4 fields
instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_decl_spec a ty) where
  default := cn_decl_spec.mk default default default default

-- cn_func_spec: 4 fields
instance {a : Type} {ty : Type} [Inhabited a] [Inhabited ty] : Inhabited (cn_func_spec a ty) where
  default := cn_func_spec.mk default default default default

-- Core types (parametric, from core.lem)

instance {sym : Type} [Inhabited sym] : Inhabited (generic_name sym) where
  default := Sym default

instance {bty : Type} [Inhabited bty] : Inhabited (generic_impl_decl bty) where
  default := Def default default

instance {bty : Type} {sym : Type} [Inhabited bty] [Inhabited sym] :
    Inhabited (generic_action_ bty sym) where
  default := Create default default default

instance {a : Type} {bty : Type} {sym : Type} [Inhabited a] [Inhabited bty] [Inhabited sym] :
    Inhabited (generic_action a bty sym) where
  default := Action default default default

instance {a : Type} {bty : Type} {sym : Type} [Inhabited a] [Inhabited bty] [Inhabited sym] :
    Inhabited (generic_paction a bty sym) where
  default := Paction default default

instance {a : Type} {bty : Type} [Inhabited a] [Inhabited bty] :
    Inhabited (generic_fun_map_decl bty a) where
  default := Fun default default default

instance {a : Type} {bty : Type} [Inhabited a] [Inhabited bty] :
    Inhabited (generic_globs a bty) where
  default := GlobalDef default default

instance {bty : Type} {a : Type} [Inhabited bty] [Inhabited a] :
    Inhabited (generic_file bty a) where
  default := generic_file.mk default default default default default default default default default default default

-- Core auxiliary types

instance {a : Type} : Inhabited (collect_saves_state a) where
  default := collect_saves_state.mk fmapEmpty fmapEmpty

instance {a : Type} : Inhabited (m_collect_saves_state a) where
  default := m_collect_saves_state.mk fmapEmpty fmapEmpty

-- Core reduction

instance {a : Type} [Inhabited a] : Inhabited (action_request2 a) where
  default := AllocRequest2 default default default default

-- Core run

instance {a : Type} [Inhabited a] : Inhabited (continuation_element a) where
  default := Kunseq default default default
