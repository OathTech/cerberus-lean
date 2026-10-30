# Constant-expression sizeof/_Alignof of a struct raises Not_found at c3ff8c53f (regression window b3e11ea33..736690a65)

Draft, 2026-10-30. Report only; upstream has already fixed it (736690a65). Found by the
fork's merge-base bump stage 1 (b9aeedcb4 → c3ff8c53f); recorded for completeness of the
regression window. AI provenance: Claude.

Between `b3e11ea33` (2026-09-19, "moving sizeof/alignof out of the memory interface") and
`736690a65` (2026-09-30, "Removing the global Tags reference") every `sizeof` or `_Alignof`
of a struct or union type inside an integer constant expression dies with an uncaught
`Not_found`:

- `b3e11ea33` makes `core_eval.lem`'s `Civsizeof`/`Civalignof` arms read
  `Implementation.sizeof_ty file.tagDefs ty` (`file` = the running Core file), where the
  previous `Mem.sizeof_ival` read the `Tags` global, which the desugarer populates as tags are
  registered.
- The constant-expression mini-run (`mini_pipeline.lem` `evalIntegerConstantExpressionAux`)
  builds its dummy Core file with `C.tagDefs= Map.empty`, so the lookup
  (`Ocaml_implementation.offsetsof` → `Pmap.find tag_sym tagDefs`) raises.
- `736690a65` changes that line to `C.tagDefs= core_tagDefs` (the translated definitions),
  which closes the window.

Minimal reproducer (LP64: `sizeof(struct S)` = 8, `a` is `int[8]`, `sizeof(a)` = 32):

```c
struct S { int x; int y; };
int main(void) { int a[sizeof(struct S)]; return sizeof(a); }
```

```sh
cerberus --nolibc --exec --batch repro.c
```

- At `b9aeedcb4`: `Defined {value: "Specified(32)", stdout: "", stderr: "", blocked: "false"}`
- At `c3ff8c53f`: `cerberus: internal error, uncaught exception: Not_found / Raised at
  Pmap.find in file "pmap.ml", line 81, characters 10-25`
- At `736690a65` and later: fixed (the mini-run's file carries the tag definitions).

No test in `tests/ci` at `c3ff8c53f` has a struct `sizeof` in an array bound, case label,
enumerator or `_Static_assert`, which is how the window went unnoticed. The fork carries the
one-line part of `736690a65` as a backport while its base is `c3ff8c53f` (the fork's
`tests/minimal/106-sizeof-struct-array.c` is the witness).

## The second half of the window (added 2026-10-30, merge-base bump stage 1 pre-merge review P1)

The same commit range breaks a second entry into the moved layout: `Ocaml_implementation.alignof`'s UNION arm at
`c3ff8c53f` still reads the Tags global (`ocaml_frontend/ocaml_implementation.ml:566`,
`Pmap.find tag_sym (Tags.tagDefs ())`), which `backend/common/pipeline.ml:272` resets before desugaring and
`backend/driver/main.ml:352` sets only after elaboration. Any desugar-time `alignof` of a union-containing type —
two `_Alignas` on one declaration (`cabs_to_ail.lem desugar_alignment_specifiers`) or an aligned redeclaration
(`cabs_to_ail_effect.lem get_compatible_alignment_requirements`), both through `get_alignof` — therefore crashes:

```c
union U { int x; double y; };
_Alignas(union U) _Alignas(1) char c;        /* also: extern _Alignas(union U) char c; twice,
int main(void) { return _Alignof(union U); }    and struct S { char a; union U u; } under _Alignas(struct S) _Alignas(2) */
```
```
cerberus: internal error, uncaught exception:
          Failure("Tags definitions must be set by Tags.set_tagDefs before any use")
```
`b9aeedcb4` answers `Specified(8)` (its desugarer used `alignof_proxy` over a pseudo-map and never touched the
global); 736690a65's one-line change to that arm (`Pmap.find tag_sym tagDefs`) restores the answer (measured on a
patched c3ff8c53f build). The same line also makes elaboration-time `offsetof` over a union-containing struct answer
(`Specified(0)` for the fork's `offsetof-union-member` witness) where every earlier revision crashed in that arm —
the long-standing asymmetry the fork had pinned as a crash pair. Fork status: both lines of 736690a65 carried ahead
(record §2b, §6c); reproducers `tests/immaculate/nolibc/zd-ta-alignas-{union-twice,union-redecl,struct-union-twice}.c`.
