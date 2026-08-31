/-
  Tag definitions — the TYPE only.
  Corresponds to: ocaml_frontend/tags.ml (the oracle keeps its mutable
  Tags module; the Lean side no longer has one).

  Effect-retirement C1 (charter section 4, [USER 2026-08-31] ruling):
  the mutable tag-definition GLOBAL is retired on the Lean target — the
  linked table is passed as a VALUE end to end:
  - the load→seed loop in Main is closed (drive/callND receive
    `runFile.tagDefs` directly);
  - the model reads stay reader-lifted (`_lemReader_tagDefs`, arc-1);
  - the hand-written memory model (CerbMem) receives the table via the
    `reader_consumer` mechanism (mem.lem, charter section 4.2) as an
    explicit leading argument;
  - the const-expr mini-run's whole-extent (`with_tagDefs`) is the
    plain application on Lean (ctype_aux.lem lem body; the reader_seed
    `run_const_expr_driver` carries the value) — the C extent
    (native/tags.c cerb_tags_with), the IO externs, and the
    with_tagDefs kernel-checked opaque + witness machinery are DELETED.
-/

import Ctype

namespace CerbTags

abbrev TagDefsMap := Fmap sym (CerbLocation.Loc × tag_definition)

/-- Fail-closed stub backing ctype_aux.lem's `tagDefs` target-coverage
    rep. The reader mechanism rewrites every applied `tagDefs ()` site
    to the `_lemReader_tagDefs` parameter, so this constant is never
    emitted at an applied call site; if it ever runs, that is a
    reader-lifting defect — panic loudly. -/
def tagDefsUnreachable (_ : Unit) : TagDefsMap :=
  panic! "CerbTags.tagDefsUnreachable: applied tagDefs () site survived reader lifting"

end CerbTags
