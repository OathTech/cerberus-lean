# `Ctype_aux.are_compatible_aux` compares an array type's bound with ITSELF: `match (n1_opt, n1_opt)` — `int a[1]` and `int a[2]` are "compatible" wherever the Core-level compatibility predicate is consulted (STD §6.7.6.2#6)

**Affected:** `frontend/model/ctype_aux.lem:80` (upstream `master` @ `b9aeedcb4`), the
`Array/Array` arm of `are_compatible_aux`:

```
    | (Array elem_ty1 n1_opt, Array elem_ty2 n2_opt) ->
        (* STD §6.7.6.2#6 *)
           are_compatible_aux (no_qualifiers, elem_ty1) (no_qualifiers, elem_ty2)
        && match (n1_opt, n1_opt) with
             | (Just n1, Just n2) -> n1 = n2
             | (Just _ , Nothing) -> true
             | (Nothing, Just _ ) -> true
             | (Nothing, Nothing) -> true
           end
```

`(n1_opt, n1_opt)` pairs the FIRST array's bound with itself: the `(Just n1, Just n2)` case
tests `n1 = n1`, so two arrays of compatible element type are always compatible, whatever
their bounds. The Ail-level twin of this predicate,
`frontend/model/ail/ailTypesAux.lem:807-813`, is correct (`match (n1_opt, n2_opt)`), which
is why a SAME-TU redeclaration `int f(int (*p)[2]); int f(int (*p)[1]) {…}` is rejected
(`constraint violation: multiple declarations in the same scope with incompatible types`,
§6.7#4) while the Core-level predicate never sees it.

## Description

`Ctype_aux.are_compatible` is the compatibility predicate of the CORE evaluator, consulted
where a struct VALUE crosses translation units: `memValueFromValue`'s `Struct/OVstruct`
arm (`core_aux.lem:200`, a struct value being stored under a ctype — the return path
`core_run.lem`, and under `--switches=inner_arg_temps` the argument path, see below). With
the typo, `struct S { int a[1]; }` (TU 1) and `struct S { int a[2]; }` (TU 2) are compatible
types, and a `struct S` value built under one definition is accepted under the other — a
silent wrong answer where the standard makes the types incompatible (§6.2.7#1 requires
corresponding members of compatible types; §6.7.6.2#6: "If the two array types are used in
a context which requires them to be compatible, it is undefined behavior if the two size
specifiers evaluate to unequal values" — an incomplete bound is compatible with any bound;
two DIFFERENT constant bounds are not).

Today upstream never shows the wrong answer on the natural reproducer because the
member selection that follows is rejected FIRST by `PEmemberof(struct)`'s exact-tag guard
(draft 38, `core_eval.lem:945-946`) — the typo is masked. Fixing draft 38 by its proposed
remedy (consult `are_compatible` at member selection) UNMASKS this typo: the incompatible
value would then be accepted and the program would run to a value. The two fixes belong
together.

## Reproducer

`tests/multi_tu_tray/arr-1-2-return/` in the fork (two TUs, linked `tu1.c tu2.c`; the
array bounds are the ONLY difference between the two definitions; the value is RETURNED by
value and member-selected):

```c
/* tu1.c */
struct S { int a[1]; };
struct S mk(void) { struct S s; s.a[0] = 7; return s; }
/* tu2.c */
struct S { int a[2]; };
struct S mk(void);
int main(void) { return mk().a[0]; }
```

Twins in the same corpus: `arr-2-2-return` (`int a[2]` in both — compatible, the positive
control), `arr-incomplete-ptr-return` (member `int (*p)[]` vs `int (*p)[2]` — compatible by
§6.7.6.1#2 + §6.7.6.2#6, decided by THIS arm's `(Nothing, Just _)` case), and draft 38's
`node`.

Verbatim runs, 2026-09-15 (`--nolibc --exec --batch --mode=exhaustive tu1.c tu2.c`;
pristine = upstream `b9aeedcb4` built with upstream Lem; fork = `arc/semantics-audit-repairs`
@ `dbe633ec5`, which carries BOTH the one-token fix below and draft 38's consult; Lean = the
fork's port; `gcc -std=c11 -O0 -w`; file
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-evidence/d3-tray-observed.txt`):

```
## arr-1-2-return  (int a[1] vs int a[2], RETURNED — the incompatible case)
pristine:    Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(545, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}  rc=1   (draft 38's guard; compatibility never asked)
fork oracle: Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(545, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}  rc=1   (guard asked are_compatible → false → rejected, now for the right reason)
fork Lean:   Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(63, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"}    rc=1
gcc exit=7   (gcc performs no cross-TU compatibility check; the program has UB by §6.2.7#2)
## arr-2-2-return  (int a[2] in both — compatible)
pristine:    Error {msg: "… mismatched tags: Symbol(558, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}  rc=1   (draft 38)
fork oracle: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}  rc=0
fork Lean:   Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}  rc=0
gcc exit=7
## arr-incomplete-ptr-return  (int (*p)[] vs int (*p)[2] — compatible)
pristine:    Error {msg: "… mismatched tags: Symbol(536, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}  rc=1   (draft 38)
fork oracle: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}  rc=0
fork Lean:   Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}  rc=0
gcc exit=7
```

What the typo alone does (READ from the source, not observed — the fork fixed both defects
in one commit): with draft 38 remedied and this arm unfixed, `are_compatible` on
`arr-1-2-return`'s two types returns `true` (`n1 = n1`), member selection proceeds, and the
program yields `Specified(7)` — an incompatible value silently accepted. The fork's unit
pin of the fixed predicate (`test/Unit/AreCompatibleTest.lean`, exe `are-compatible-test`):
`int[1] vs int[2] = false`, `int[2] vs int[2] = true`, `int[] vs int[2] = true`, and the
two-TU struct pair `struct S{int a[1]} vs struct S{int a[2]} = false`.

## Observed vs expected

Observed (upstream): the predicate answers "compatible" for `int[1]`/`int[2]`; masked on
the natural reproducer by draft 38's guard. Expected: `false` when two constant bounds
differ; `true` when either bound is absent (§6.7.6.2#6) — the Ail-level twin's behaviour.

## Impact

Minor tier: Core-level compatibility only, C-reachable through struct values crossing
translation units on the RETURN path (`memValueFromValue` on the returned value,
`core_run.lem`; and member selection once draft 38 is fixed). In the DEFAULT switch set the
by-value ARGUMENT path is NOT a consult site — see the related observation below — so a
program has to return the struct by value to reach the predicate. Single-TU programs are
untouched (same-TU tags take the `tag1 = tag2` fast path; same-TU redeclarations are
checked at the Ail level by the correct twin).

## Proposed remedy

One token, `frontend/model/ctype_aux.lem:80`:

```
-        && match (n1_opt, n1_opt) with
+        && match (n1_opt, n2_opt) with
```

That is the fork's patch (commit `dbe633ec5`; results on every previously-accepted input of
the fork's Tier A/B corpora unchanged; the same-TU control unchanged).

## Related observations (recorded here rather than as separate drafts)

1. **The by-value ARGUMENT path consults no compatibility in the default switch set.**
   `core_run.lem:947-950` (`Eccall`): unless `Global.SW_inner_arg_temps` is set, each
   by-value argument travels as `Ctype [] (Pointer no_qualifiers ty)` — a pointer to a
   caller-side temporary — so `memValueFromValue`'s `Struct` arm is never reached for it,
   and the callee loads the member through the pointer under ITS definition (offset 0 in
   both layouts). Verbatim (2026-09-15, `tests/multi_tu_tray/arr-1-2-arg`: `int a[1]` vs
   `int a[2]`, `int get(struct S s) { return s.a[0]; }`, caller `s.a[0] = 7; s.a[1] = 8;
   return get(s);`): pristine `Defined {value: "Specified(7)", …}` rc=0; fork oracle the
   same; fork Lean the same; gcc 7. Even `struct S {int a;}` vs `struct S {int b;}` passed by
   value gives `Specified(7)` on both fork engines. So the typo was never observable on
   that path, and neither is its fix; the fork pins these two argument rows as the
   oracle's behaviour (an observed modelling limit, not an endorsement —
   `tests/multi_tu_tray/README.md`).
2. **Under `--switches=inner_arg_temps` the store-side consult IS reached for arguments,
   and rejects with an uncaught exception rather than a diagnostic** (fork oracle, fixed,
   2026-09-15; `core_run.lem:527` `memValueFromValue (Ctype [] (unatomic_ ty)) cval` on the
   store into the parameter temporary):
   ```
   $ cerberus --switches=inner_arg_temps --nolibc --exec --batch --mode=exhaustive tu1.c tu2.c    # arr-1-2-arg
   internal error: can_advance: Step_error2 ==> …/arr-1-2-arg/tu1.c:2:1-39 (cursor: 2:5 - 2:8)the value of a store(struct S) didn't match the lvalue type: Specified((struct S){.a= {7, 8}})
   cerberus: internal error, uncaught exception:
             Failure("internal error: can_advance: Step_error2 ==> …the value of a store(struct S) didn't match the lvalue type: Specified((struct S){.a= {7, 8}})")
   rc=125
   ```
   The compatible twin `arr-2-2-arg` under the same switch: `Defined {value: "Specified(7)",
   …}` rc=0. Compatibility is load-bearing on the argument path under that switch, and the
   fixed predicate is observable there (an incompatible value is now rejected where the
   typo accepted it) — but the rejection is `Failure`/exit 125, the pure-failure class,
   where a `Illformed_program`/UB verdict would be the diagnostic shape (cf. draft 04's
   remedy pattern).

## Classification

**TRUE BUG**, minor (a one-token slip; Core-level compatibility; C-reachable only through
cross-TU struct values; masked on upstream by draft 38 until that is fixed). File together
with 37 and 38: the three are one story about struct values crossing translation units.

## Provenance

Finding 5 of this project's whole-project semantics audit
(`lean_frontend/docs/2026-09-11_whole-project-semantics-audit.md`, 2026-09-11, the
orchestrator's [AGENT] source reading against the Ail twin), repaired in the fork by the
semantics-audit repairs slice (record
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md` §D3; charter D3/D4.1 and
§8 items 1 and 3). The related observations were made by the worker executing that slice
(the charter's own negative expectation for the argument path was withdrawn as an erratum
once the path was read — charter §8). Drafted by Claude (Fable 5.1) under operator
direction; the filed issue carries an AI-provenance note per the tray's policy
(`INDEX.md`, "Provenance labeling policy").

## Fork status (2026-09-15) — FIXED in the fork

Commit `dbe633ec5` on `arc/semantics-audit-repairs` (the one-token fix + draft 38's
consult); `ocaml_frontend/generated/ctype_aux.ml` now reads `match (n1_opt, n2_opt)`; the
fork-drift manifest pins the new generated hash. Pinned by the unit exe
`are-compatible-test` (8 executable assertions) and the corpus `tests/multi_tu_tray/`
(LADDER Tier A row 6b: `arr-1-2-return` rejected, `arr-2-2-return` and
`arr-incomplete-ptr-return` `Specified(7)`).
