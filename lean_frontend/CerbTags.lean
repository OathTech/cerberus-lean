/-
  Global mutable tag definitions state.
  Corresponds to: ocaml_frontend/tags.ml

  Uses C extern functions returning BaseIO to prevent Lean's CSE.
  The Lem `effectful` annotation wraps call sites in `runEffectful`.
-/

import Ctype

namespace CerbTags

abbrev TagDefsMap := Fmap sym (CerbLocation.Loc × tag_definition)

/-- IO-returning versions used by generated code via effectful target_rep -/
@[extern "cerb_tags_get"]
opaque tagDefsIO : @& Unit → BaseIO TagDefsMap

@[extern "cerb_tags_set"]
opaque setTagDefsIO : @& TagDefsMap → BaseIO Unit

@[extern "cerb_tags_reset"]
opaque resetTagDefsIO : @& Unit → BaseIO Unit

/-- Pure wrappers used by hand-written code (Main.lean etc.).
    @[never_extract, noinline] on every impl: without them the compiler may
    cache a closed application (e.g. a reader SEED like 'tagDefs ()' at a
    pipeline entry) as a startup constant — evaluated before any set — or
    CSE-merge sites. Same hazard class as LemLib.runEffectful. -/
@[never_extract, noinline]
private unsafe def tagDefs_impl (_ : Unit) : TagDefsMap :=
  unsafeBaseIO (tagDefsIO ())

@[never_extract, noinline]
private unsafe def set_tagDefs_impl (v : TagDefsMap) : Unit :=
  unsafeBaseIO (setTagDefsIO v)

set_option autoImplicit true in
@[never_extract, noinline]
private unsafe def with_tagDefs_impl (td : TagDefsMap) (f : Unit → b) : b :=
  let saved := unsafeBaseIO (tagDefsIO ())
  let _ := unsafeBaseIO (setTagDefsIO td)
  let ret := f ()
  let _ := unsafeBaseIO (setTagDefsIO saved)
  ret

@[never_extract, noinline]
private unsafe def reset_tagDefs_impl (_ : Unit) : Unit :=
  unsafeBaseIO (resetTagDefsIO ())

@[implemented_by tagDefs_impl]
opaque tagDefs : Unit → TagDefsMap
attribute [never_extract] tagDefs

@[implemented_by set_tagDefs_impl]
opaque set_tagDefs : TagDefsMap → Unit

set_option autoImplicit true in
@[implemented_by with_tagDefs_impl]
axiom with_tagDefs : TagDefsMap → (Unit → b) → b

@[implemented_by reset_tagDefs_impl]
opaque reset_tagDefs : Unit → Unit

end CerbTags
