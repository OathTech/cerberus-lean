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
