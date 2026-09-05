# `"hello" + 1` (a string literal plus an integer constant) is not accepted as an address constant in a static initialiser

**Affected:** `frontend/model/cabs_to_ail.lem:894-925`
(`is_address_constant`: null pointer constants, identifiers of static
arrays and function designators, `&` of an lvalue to a static object,
casts — no string-literal arm), `:934-960`
(`is_initializer_constant_expression_or_string_literal`: a BARE string
literal is accepted by the `| AilEstr _ -> E.return true` arm, but the
`AilEbinary e1 (Arithmetic Add) e2` / `Sub` arms require
`is_address_constant` of the pointer operand, which is false for a
literal); the raise sites `frontend/model/desugaring_init.lem:449-457` and
`cabs_to_ail.lem:3385-3387`. Checked against `master` @ `b9aeedcb4`:
`desugaring_init.lem` byte-identical; `cabs_to_ail.lem` differs from
master only by Lean-target `declare` lines outside the cited regions
(master's line numbers).

## Description

C11 §6.6#7: an initializer constant expression may be "an address
constant for a complete object type plus or minus an integer constant
expression"; §6.6#9: "An address constant is a null pointer, a pointer
to an lvalue designating an object of static storage duration, or a
pointer to a function designator; it shall be created explicitly using
the unary `&` operator or an integer constant cast to pointer type, or
implicitly by the use of an expression of array or function type." A
string literal is an lvalue array of static storage duration (§6.4.5#6),
so `"hello"` decays to an address constant and `"hello" + 1` is a valid
initializer.

`is_initializer_constant_expression_or_string_literal` handles the bare
literal (its last arm), and the `Add`/`Sub` arms handle
`array_identifier + k` and `&obj + k` through `is_address_constant`
(:894-925) — but `is_address_constant` has no `AilEstr` arm, so the
literal-plus-offset form falls through to `false`. Controls that ARE
accepted: `static int *q = arr + 2;` and `&arr[1]`
(`elab/elab_const_expr_static_init.c`, all engines agree).

## Reproducer

`tests/noodle-probes/elab/elab_addr_const_string_plus.c`:

```c
static const char *s = "hello" + 1;
int main(void) { return *s; }
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive elab_addr_const_string_plus.c   # exit 1
tests/noodle-probes/elab/elab_addr_const_string_plus.c:6:24: error: constraint violation: initializer element is not a compile-time constant
static const char *s = "hello" + 1;
                       ~~~~~~~~^~~ 
§6.7.9#4: 
4   All the expressions in an initializer for an object that has static or thread storage duration
    shall be constant expressions or string literals.
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`;
the fork's oracle at `928aa1e76` prints the same; our Lean port rejects
with `Error {msg: "desugaring failed at …:6:24-35 (cursor: 6:32)"}`.)

```
$ gcc -std=c11 -O0 elab_addr_const_string_plus.c && ./a.out; echo $?
101
```

(gcc 13.3.0; verbatim 2026-09-05 — `'e'`.)

## Observed vs expected

- Observed: constraint violation for `"literal" + integer-constant`.
- Expected: accepted (§6.6#7 with §6.6#9); `*s == 'e'`.

## Impact

Less common than the companion `?:` case, but the same idiom family
(`static const char *name = "prefix-" + N;`, pointer tables into a
string literal) is refused before execution. This report is adjacent to
tray 09 (`&arr[i].field` rejected): both are gaps in the address-constant
predicate rather than in the evaluator.

## Proposed remedy

Add a string-literal arm to `is_address_constant`:

```
    | AnnotatedExpression () _ _ (AilEstr _) ->
        (* STD §6.6#9: a string literal is an lvalue of array type with
           static storage duration; it decays to an address constant *)
        E.return true
```

With that arm the existing `Add`/`Sub` arms of
`is_initializer_constant_expression_or_string_literal` accept
`"hello" + 1` and `"hello" - 0` with no further change; the bare-literal
arm there becomes redundant but harmless. (Wide string literals are the
same case.)

## Classification

**TRUE BUG.** The predicate implements §6.6#9's enumeration and omits one
of its listed forms (an expression of array type — the literal); the
bare-literal special case in the caller shows the intent to accept
literals.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding E5); both engines reject (shared desugaring), gcc accepts.
Re-verified 2026-09-05 on the un-forked upstream binary + runtime @
`b9aeedcb4`, the fork's oracle and the Lean port (lines above verbatim).
Localisation and this draft by Claude (Fable 5.1) under operator
direction; the filed issue carries an AI-provenance note per the tray's
policy.
