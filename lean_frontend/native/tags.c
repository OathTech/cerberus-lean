/* Tag definitions for CerbTags — mutable global via C extern
   tagDefsIO : Unit → BaseIO TagDefsMap
   setTagDefsIO : TagDefsMap → BaseIO Unit
   withTagDefsIO : TagDefsMap → (Unit → b) → BaseIO b
   resetTagDefsIO : Unit → BaseIO Unit

   Calling convention (Lean ≥ 4.29 new code generator): the RealWorld token is
   erased, so BaseIO externs receive only their explicit arguments and return
   the result value DIRECTLY (no lean_io_result_mk_ok wrapper).

   DOCUMENTED-DELIBERATE DIVERGENCES from ocaml_frontend/tags.ml
   (audit-2 C5; kept, with reasons — mirroring either would need a full
   corpus re-run for zero benefit on any live path):

   * set OVERWRITES; OCaml set_tagDefs is set-ONCE (a second set raises
     Failure "Tags definitions can be set only once", tags.ml:9-13;
     reset clears the once-flag, tags.ml:6-7). Kept because (a) the only
     Lean-side set site is Main.lean (setTagDefsIO after an explicit
     resetTagDefsIO — the exact discipline the OCaml flag polices is
     already followed by construction), and (b) with_tagDefs below
     assigns directly in BOTH implementations (tags.ml:22-27 bypasses
     the flag too), so a faithful mirror needs a once-flag here that the
     with-extent must bypass — added crash surface guarding a call
     pattern that does not exist.

   * get on UNSET returns the empty map (lean_box(0)); OCaml tagDefs ()
     raises Failure "Tags definitions must be set by Tags.set_tagDefs
     before any use" (tags.ml:15-20). Kept because a pre-set read is
     still LOUD downstream — struct/union layout on an empty map panics
     at first use (CerbMem.offsetsof "unknown tag", exactly how the
     arc-4 S3b set_tagDefs-DCE bug surfaced) — while an abort from
     inside a C extern (lean_panic/abort) is a harsher failure mode than
     OCaml's catchable Failure and would also kill legitimately
     tag-free early paths (self-test/parse-only modes) that never set
     the global. */
#include <lean/lean.h>

static lean_object* cerb_tag_defs = NULL;

LEAN_EXPORT lean_obj_res cerb_tags_get(b_lean_obj_arg unit) {
    if (cerb_tag_defs == NULL) {
        return lean_box(0);
    }
    lean_inc(cerb_tag_defs);
    return cerb_tag_defs;
}

LEAN_EXPORT lean_obj_res cerb_tags_set(b_lean_obj_arg v) {
    if (cerb_tag_defs != NULL) {
        lean_dec(cerb_tag_defs);
    }
    lean_inc(v);
    cerb_tag_defs = v;
    return lean_box(0);
}

LEAN_EXPORT lean_obj_res cerb_tags_with(b_lean_obj_arg td, b_lean_obj_arg f) {
    lean_object* saved = cerb_tag_defs;
    if (saved != NULL) lean_inc(saved);

    lean_inc(td);
    if (cerb_tag_defs != NULL) lean_dec(cerb_tag_defs);
    cerb_tag_defs = td;

    lean_inc(f);
    lean_object* result = lean_apply_1(f, lean_box(0));

    if (cerb_tag_defs != NULL) lean_dec(cerb_tag_defs);
    cerb_tag_defs = saved;

    return result;
}

LEAN_EXPORT lean_obj_res cerb_tags_reset(b_lean_obj_arg unit) {
    if (cerb_tag_defs != NULL) {
        lean_dec(cerb_tag_defs);
        cerb_tag_defs = NULL;
    }
    return lean_box(0);
}
