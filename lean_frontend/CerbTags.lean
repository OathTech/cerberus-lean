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

/-- Whole with-extent (save → set td → apply f → restore) done in C
    (native/tags.c cerb_tags_with), so the set/restore CANNOT be
    dead-code-eliminated by the Lean compiler. The former Lean-side
    implementation (`let _ := unsafeBaseIO (setTagDefsIO td)` around a
    pure `f ()`) had exactly the arc-4 S3b effect-erasure failure: the
    discarded-result lets were DCE'd, so the mini-run's const-expr driver
    saw EMPTY ambient tags (CerbMem.offsetsof: unknown tag on
    `int a[sizeof(struct S)]`; found by the arc-2 Phase-2 obligation
    test 106-sizeof-struct-array.c, empirically confirmed by native-side
    tracing: cerb_tags_set never fired). -/
@[extern "cerb_tags_with"]
unsafe opaque withTagDefsIO {b : Type} : @& TagDefsMap → (@& (Unit → b)) → BaseIO b

/-- Pure wrappers used by hand-written code (Main.lean etc.).
    @[never_extract, noinline] on every impl: without them the compiler may
    cache a closed application (e.g. a reader SEED like 'tagDefs ()' at a
    pipeline entry) as a startup constant — evaluated before any set — or
    CSE-merge sites. Same hazard class as LemLib.runEffectful.
    Soundness invariant (armour + never-discard-writes + no-proof-may-
    relate-across-state): docs/2026-08-22_arc14-effect-erasure-invariant.md
    (arc-14 S1 F5, sem:S17 — the single normative statement). -/
@[never_extract, noinline]
private unsafe def tagDefs_impl (_ : Unit) : TagDefsMap :=
  unsafeBaseIO (tagDefsIO ())

@[never_extract, noinline]
private unsafe def set_tagDefs_impl (v : TagDefsMap) : Unit :=
  unsafeBaseIO (setTagDefsIO v)

@[never_extract, noinline]
private unsafe def with_tagDefs_impl {b : Type} (td : TagDefsMap) (f : Unit → b) : b :=
  unsafeBaseIO (withTagDefsIO td f)

@[never_extract, noinline]
private unsafe def reset_tagDefs_impl (_ : Unit) : Unit :=
  unsafeBaseIO (resetTagDefsIO ())

@[implemented_by tagDefs_impl]
opaque tagDefs : Unit → TagDefsMap
attribute [never_extract] tagDefs

@[implemented_by set_tagDefs_impl]
opaque set_tagDefs : TagDefsMap → Unit

/- `b` pinned to Type (was universe-polymorphic via autoImplicit): the C
   with-extent binding goes through BaseIO, which lives in Type. The lem
   val is `forall 'a` over lem types, which all land in Type. -/
@[implemented_by with_tagDefs_impl]
axiom with_tagDefs {b : Type} : TagDefsMap → (Unit → b) → b

@[implemented_by reset_tagDefs_impl]
opaque reset_tagDefs : Unit → Unit

end CerbTags
