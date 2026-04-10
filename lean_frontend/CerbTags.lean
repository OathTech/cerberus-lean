/-
  Global mutable tag definitions state.
  Corresponds to: ocaml_frontend/tags.ml
  Reference: lean-c-semantics uses explicit TypeEnv parameter instead.

  Uses unsafe mutable IO.Ref + axiom + @[implemented_by],
  same pattern as CerbGlobal.
-/

import Ctype

namespace CerbTags

abbrev TagDefsMap := Fmap sym (CerbLocation.Loc × tag_definition)

private unsafe def tagDefsRef : IO.Ref (Bool × Option TagDefsMap) :=
  unsafeBaseIO (IO.mkRef (false, none))

private unsafe def tagDefs_impl (_ : Unit) : TagDefsMap :=
  match unsafeBaseIO tagDefsRef.get with
  | (_, some v) => v
  | (_, none) => fmapEmpty  -- empty rather than panic, for init safety

private unsafe def set_tagDefs_impl (v : TagDefsMap) : Unit :=
  unsafeBaseIO (tagDefsRef.set (true, some v))

set_option autoImplicit true in
private unsafe def with_tagDefs_impl (td : TagDefsMap) (f : Unit → b) : b :=
  let saved := unsafeBaseIO tagDefsRef.get
  let _ := unsafeBaseIO (tagDefsRef.set (true, some td))
  let ret := f ()
  let _ := unsafeBaseIO (tagDefsRef.set saved)
  ret

private unsafe def reset_tagDefs_impl (_ : Unit) : Unit :=
  unsafeBaseIO (tagDefsRef.set (false, none))

@[implemented_by tagDefs_impl]
opaque tagDefs : Unit → TagDefsMap

@[implemented_by set_tagDefs_impl]
opaque set_tagDefs : TagDefsMap → Unit

set_option autoImplicit true in
@[implemented_by with_tagDefs_impl]
axiom with_tagDefs : TagDefsMap → (Unit → b) → b

@[implemented_by reset_tagDefs_impl]
opaque reset_tagDefs : Unit → Unit

end CerbTags
