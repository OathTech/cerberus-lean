/* Tag definitions for CerbTags — mutable global via C extern
   tagDefsIO : Unit → BaseIO TagDefsMap
   setTagDefsIO : TagDefsMap → BaseIO Unit
   withTagDefsIO : TagDefsMap → (Unit → b) → BaseIO b
   resetTagDefsIO : Unit → BaseIO Unit */
#include <lean/lean.h>

static lean_object* cerb_tag_defs = NULL;

LEAN_EXPORT lean_obj_res cerb_tags_get(b_lean_obj_arg unit, lean_obj_arg rw) {
    if (cerb_tag_defs == NULL) {
        return lean_io_result_mk_ok(lean_box(0));
    }
    lean_inc(cerb_tag_defs);
    return lean_io_result_mk_ok(cerb_tag_defs);
}

LEAN_EXPORT lean_obj_res cerb_tags_set(b_lean_obj_arg v, lean_obj_arg rw) {
    if (cerb_tag_defs != NULL) {
        lean_dec(cerb_tag_defs);
    }
    lean_inc(v);
    cerb_tag_defs = v;
    return lean_io_result_mk_ok(lean_box(0));
}

LEAN_EXPORT lean_obj_res cerb_tags_with(b_lean_obj_arg td, b_lean_obj_arg f, lean_obj_arg rw) {
    lean_object* saved = cerb_tag_defs;
    if (saved != NULL) lean_inc(saved);

    lean_inc(td);
    if (cerb_tag_defs != NULL) lean_dec(cerb_tag_defs);
    cerb_tag_defs = td;

    lean_inc(f);
    lean_object* result = lean_apply_1(f, lean_box(0));

    if (cerb_tag_defs != NULL) lean_dec(cerb_tag_defs);
    cerb_tag_defs = saved;

    return lean_io_result_mk_ok(result);
}

LEAN_EXPORT lean_obj_res cerb_tags_reset(b_lean_obj_arg unit, lean_obj_arg rw) {
    if (cerb_tag_defs != NULL) {
        lean_dec(cerb_tag_defs);
        cerb_tag_defs = NULL;
    }
    return lean_io_result_mk_ok(lean_box(0));
}
