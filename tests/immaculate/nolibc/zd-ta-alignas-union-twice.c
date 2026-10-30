/* merge-base bump stage 1 pin (2026-10-30; pre-merge review P1, record
   docs/2026-10-29_merge-base-bump-stage1-record.md §6b): two _Alignas on one
   declaration whose type is a union apply cabs_to_ail_effect.lem get_alignof's
   closure to the union. At upstream c3ff8c53f Ocaml_implementation.alignof's
   union arm reads the Tags GLOBAL (ocaml_implementation.ml:566), UNSET during
   desugaring: the oracle crashed with Failure("Tags definitions must be set by
   Tags.set_tagDefs before any use") where Lean's one-map wrapper answered 8 (so
   did pristine b9aeedcb4 through alignof_proxy). Upstream 736690a65's one line
   (`Pmap.find tag_sym tagDefs`) closes it; the fork carries it ahead (ruling in
   the record, tray 67). Pinned MATCH | L=Specified(8). */
union U { int x; double y; };
_Alignas(union U) _Alignas(1) char c;
int main(void) { return _Alignof(union U); }
