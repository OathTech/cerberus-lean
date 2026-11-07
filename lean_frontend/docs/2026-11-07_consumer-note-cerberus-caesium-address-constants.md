# Consumer note for cerberus-caesium: static initializers that now desugar (2026-11-07)

From: the `fix/address-constants` worker [AGENT]. Record `docs/2026-11-07_address-constants-record.md`; witness
`scripts/check_address_constants.sh` (ladder row 1, 234 programs); upstream-tray report 09 (28 and 29 merged into
it) is the filing; contract D17.

Status: on branch `fix/address-constants`, fixed, witnessed on both engines, every moved row dispositioned with gcc 13
`-std=c11 -pedantic-errors` as the referee; Tier A, the full battery and the merge are the orchestrator's. The
behaviour below is what the next re-pin that includes the branch carries.

## What changed

The desugarer's constant-expression predicates (`frontend/model/cabs_to_ail.lem`: `is_arithmetic_constant_expression`,
`is_lvalue_to_static_object`, `is_address_constant`, and the `_Generic`/compound-literal arms of
`is_integer_constant_expression`), which decide C17 6.7.9#4 for every static or thread storage-duration initializer,
now implement 6.6#3-#9 arm by arm (every arm cites its clause). Both engines by generation: the OCaml oracle and the
Lean engine desugar the same Ail the same way.

Initializers that were REJECTED with `constraint violation: initializer element is not a compile-time constant` (the
Lean engine: `Error {msg: "desugaring failed at …"}`) and now desugar and run, at gcc's values:

- `&arr[i].field`, `&arr[i].inner.x`, `&arr[i].member_array[k]`, `&matrix[i][j]`, `&(*(p)).m` for any chain of `[]`,
  `.`, `->`, `*` and pointer casts over a static object (`&((struct S *)&gs)->b`, `(int *)((char *)&ga + 8)`);
- the decay of a static array in any of those positions (`gs.arr`, `gs.arr + 1`, `arr_of_structs[1].arr + 2`,
  `matrix[1]`, `*(matrix + 1)`, `*&ga`) and of a function designator under `*` (`*f`, `**f`, `*&f`);
- `"literal" + k`, `&"literal"[k]`, `(char *)"literal" + k`, concatenated literals plus an offset (also inside struct
  and array initializers);
- `cond ? a : b` and `_Generic(…)` in a static initializer, over integers, floating constants or address constants,
  including a dead branch with a division by zero, a shift by a negative count or a signed overflow, and a controlling
  expression that is a variable or a call (not evaluated);
- `(char *)&g + 4` and every address constant ± integer constant expression through pointer casts (a UB055 verdict
  before);
- `_Generic(…)` in an enumerator, a case label, a file-scope array bound or a `_Static_assert` (an internal error
  before, on both engines).

Initializers that were ACCEPTED and now report the 6.7.9#4 constraint violation (gcc rejects each with `initializer
element is not constant`):

- the comma operator (`static int a = (1, 2);`, `static double d = (1.0, 3.0);`, `static int *p = (0, &g);`);
- `&local` / `&param` in a block-scope `static` initializer (an internal error in the Ail typing before);
- a value read: `*&g`, `gs.b`, a pointer member's value, `(long)g`, `(int *)g`;
- a pointer VARIABLE under `*`, `[]` or `->`: `&*gp`, `&gp[0]`, `&gsp->b`, `gsp->arr + 2`, `gp` itself;
- `&tls` of a `_Thread_local` object (6.2.4#4: thread storage duration is not static storage duration).

Unchanged, declared (the record §2.4, the filing's open questions): `&(int){3}` (a compound literal's static storage
at file scope, 6.5.2.5#5), `"hello"[1]` and `*"hello"` as VALUES, a `const` object's value (`static const int k = 3;
static int a = k;`) stay rejected as upstream rejects them (gcc folds them, 6.6#10); `(long)&g`, `(int)&g`, `(long)ga`,
`&g == &g`, pointer differences, the `offsetof` idiom and `(int *)16` stay accepted as upstream accepts them; an
unevaluated `?:` branch or an unselected `_Generic` association that is not itself a constant expression (`1 ? 3 :
f()`, `_Generic(1, int: 3, default: g)`) is rejected (too strict, never fail-open: the association is selected during
the Ail typing, after the predicate); the GNU `?:` is a constraint violation in an initializer and still crashes both
engines in the integer-constant contexts (TODO).

## What this means for your clone and your corpora

- Your RefinedC-style clone of the frontend, if it carries pristine's predicates, now disagrees with the fork on the
  forms above: the fork accepts where the clone rejects (every listed form) and rejects where the clone accepts (the
  comma, `&local`, the value reads). The arms are 6.6's list, not a reading of ours; the patch in tray 09 applies to
  `c3ff8c53f` cleanly if you want the same predicates.
- A translation unit of yours that was refused at desugaring for a static table (`&table[i].field`, `"prefix" + N`,
  a `?:`-built constant) is now elaborated; its Core is what the elaboration of the same initializer by the existing
  paths gives (no evaluator or memory-model change: the predicates only decide the constraint). A unit that relied
  on the comma or on `&local` in a static initializer is now refused.
- The Ail/Core of programs accepted before and after is unchanged (a 7413-file `--pp=core` sweep of every corpus the
  lanes walk: 11 rows moved, every one listed in the record §4, none from accepted to rejected except the comma class
  the standard forbids); the libc Core dumps and quotation pins did not move.
- No seam, proof module, fuel form or reader signature changed: the three predicates are `partial def`s of a module
  outside the exec cone, the mutual block adds no `failwithI` site, the failure-reach register is unchanged (238 =
  238), kernel replay is not owed.
- A desugar-time typing call was added for the decay forms (`gs.arr`-shaped expressions in a static-initializer
  position only, in `GenTyping.CTXsizeof`, the same call the `sizeof` desugaring makes); an ill-typed such expression
  reports the typing's own error at desugaring rather than at the Ail typing.
- One pristine-register row (`ci/0268-address-invalid-type.error.c`, `int x = &1;`): both engines reject; the
  diagnostic is now the desugarer's constraint instead of the typing's "cannot take address of an rvalue".
