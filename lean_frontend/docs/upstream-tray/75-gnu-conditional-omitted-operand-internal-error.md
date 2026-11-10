# The GNU conditional with an omitted operand (`a ?: b`) ends in an internal error; in an integer-constant context the error is an unrelated one (`PEcase, mismatched`)

**Affected:** `frontend/model/translation.lem` @ `c3ff8c53f`, `:2317-2320`:

```
      | A.AilEcond e1 Nothing e3 ->
          (* GNU ?: operator *)
          E.record_error_at loc "TODO: elaboration of ?: operator" >>= fun () ->
          E.return Caux.mk_skip_e
```

and the constant-expression evaluator `frontend/model/mini_pipeline.lem` (which elaborates and runs the expression of an
enumerator, case label, array bound or `_Static_assert`). The shared model: the OCaml backend and our Lean port agree.

## Description

`a ?: b` is a GNU extension, not ISO C; the parser and the Ail typing accept it, and the elaboration records a "TODO"
error and returns a `skip` in the expression's place. Where the expression is evaluated at run time the recorded error
ends the run as an internal error carrying the TODO text. Where it is an integer constant expression, the `skip` is
what gets evaluated: the "unsupported" line is printed and the tool then dies on whatever the surrounding Core does with
a unit value — a message that no longer names the construct.

## Reproducers

```c
int main(void) { int x = 3; return x ?: 4; }
```

```
$ cerberus --nolibc --exec --batch gnu_cond_expr.c
unsupported: gnu_cond_expr.c:1:38:: TODO: elaboration of ?: operator
internal error: gnu_cond_expr.c:1:38:: TODO: elaboration of ?: operator
cerberus: internal error, uncaught exception:
          Failure("internal error: gnu_cond_expr.c:1:38:: TODO: elaboration of ?: operator")
```

```c
enum { E = 3 ?: 4 }; int main(void) { return E; }
```

```
$ cerberus --nolibc --exec --batch gnu_cond_enum.c
unsupported: gnu_cond_enum.c:1:14:: TODO: elaboration of ?: operator
internal error: PEcase, mismatched ==> [gnu_cond_enum.c:1:12-18 (cursor: 1:14)]Unit
cerberus: internal error, uncaught exception:
          Failure("internal error: PEcase, mismatched ==> [gnu_cond_enum.c:1:12-18 (cursor: 1:14)]Unit")
```

(both exit 125; verbatim, 2026-11-10, un-forked upstream binary + runtime @ `c3ff8c53f`.) The other three
integer-constant contexts, first two lines of stderr each, all exit 125:

```c
int main(void) { int x = 3; switch (x) { case (3 ?: 4): return 1; } return 0; }
```
```
unsupported: gnu_cond_case.c:1:47:: TODO: elaboration of ?: operator
internal error: PEcase, mismatched ==> [gnu_cond_case.c:1:47-55]Unit
```
```c
int b[(3 ?: 4)]; int main(void) { return sizeof b / sizeof b[0]; }
```
```
unsupported: gnu_cond_bound.c:1:7:: TODO: elaboration of ?: operator
internal error: PEcase, mismatched ==> [gnu_cond_bound.c:1:7-15]Unit
```
```c
_Static_assert((3 ?: 4) == 3, ""); int main(void) { return 0; }
```
```
unsupported: gnu_cond_sassert.c:1:16:: TODO: elaboration of ?: operator
internal error: TODO error: the driver found less/more than one active execution
```

gcc 13.3.0 (`gcc -std=c11 -w -O0 f.c && ./a.out; echo $?`, 2026-11-10) exits 3, 3, 1, 3 and 0 for the five programs in
the order shown.

## Observed vs expected

- Observed: exit 125 with `cerberus: internal error, uncaught exception` in every context; in the four constant
  contexts the final message is unrelated to the construct.
- Expected: either the extension's value (the first operand if it is nonzero, else the third, the first evaluated
  once), or one located "not supported" diagnostic with a non-internal exit status in every context.

## Impact

The operator is common in Linux-style C (`x ?: default`). The failure is loud in every case measured, never a wrong
value; the cost is the misleading message in constant contexts and the internal-error exit status.

## Proposed remedy (prose; no patch is attached)

Report the unsupported construct as an ordinary located error from the `AilEcond e1 Nothing e3` arm (so that no
placeholder expression is evaluated afterwards), or elaborate it as a `let` of the first operand followed by the
ordinary conditional.

## Fork status (2026-11-10)

Unchanged in both engines (the Lean port: the same final messages, exit 134). The case-label form is pinned as the one
`gap` row of this repository's `tests/address_constants` corpus (`ice_case_cond_gnu`). Reported, not refused in code.
Report 61 carries the earlier note on this arm.

## Classification

**TRUE BUG** as a crash (an internal error where a value or a diagnostic belongs); the feature itself is an
acknowledged TODO.

## Provenance

Found on 2026-10-29 by the fork's compound-assignment slice (report 61's related note) and again by the
address-constants slice of 2026-11-07. Re-run on pristine upstream at `c3ff8c53f`, both fork engines and gcc on
2026-11-10. This draft by Claude (Fable 5.2) under operator direction; the filed issue carries an AI-provenance note
per the tray's policy.
