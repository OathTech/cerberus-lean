# `?:` in a static-storage initialiser is rejected as "initializer element is not a compile-time constant"

**Affected:** `frontend/model/cabs_to_ail.lem:794-843`
(`is_arithmetic_constant_expression`: no `AilEcond` arm — the conditional
operator falls to `| _ -> E.return false`), `:934-960`
(`is_initializer_constant_expression_or_string_literal`, which calls it
for §6.6#7 bullets 1-3); `frontend/model/desugaring_init.lem:449-457`
(`interp_initializer_aux`: a `false` from that predicate with static or
thread storage → `Constraint.IllegalStorageClassStaticOrThreadInitializer`,
§6.7.9#4); the same raise at `cabs_to_ail.lem:3385-3387`. Checked against
`master` @ `b9aeedcb4`: `desugaring_init.lem` byte-identical;
`cabs_to_ail.lem` differs from master only by Lean-target `declare` lines
outside the cited regions (master's line numbers).

## Description

C11 §6.6#3 lists the operators a constant expression may NOT contain
(assignment, increment/decrement, function call, comma — "except when
they are contained within a subexpression that is not evaluated"); the
conditional operator is allowed, and §6.6#6 defines integer constant
expressions over "integer constants, enumeration constants, character
constants, sizeof … and floating constants that are the immediate
operands of casts" combined with any permitted operator.

Cerberus has two constant-expression predicates. `is_integer_constant_expression`
(used for enumerators, array sizes and `case` labels) has `AilEcond`
arms (cabs_to_ail.lem:727-740), so `?:` works there — probe
`elab/elab_const_expr_ternary_contexts.c`, all engines 10. The
initializer path uses `is_arithmetic_constant_expression` instead
(:794-843), whose `match` covers constants, identifiers (as lvalues),
unary and binary operators, `sizeof`/`_Alignof`/`offsetof` and arithmetic
casts — and has no conditional arm, so every `?:` in a static or
thread-storage initialiser is a constraint violation.

## Reproducer

`tests/noodle-probes/elab/elab_const_expr_ternary_init.c`:

```c
static int a = (3 > 2) ? 10 : 20;
int main(void) { return a; }
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive elab_const_expr_ternary_init.c   # exit 1
tests/noodle-probes/elab/elab_const_expr_ternary_init.c:5:16: error: constraint violation: initializer element is not a compile-time constant
static int a = (3 > 2) ? 10 : 20;
               ~~~~~~~~^~~~~~~~~ 
§6.7.9#4: 
4   All the expressions in an initializer for an object that has static or thread storage duration
    shall be constant expressions or string literals.
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`;
the fork's oracle at `928aa1e76` prints the same; our Lean port, running
the same desugaring, rejects with `Error {msg: "desugaring failed at
…:5:16-33 (cursor: 5:24)"}`.)

```
$ gcc -std=c11 -O0 elab_const_expr_ternary_init.c && ./a.out; echo $?
10
```

(gcc 13.3.0; verbatim 2026-09-05.) `1 ? 10 : 20` and a block-scope
`static` behave the same way on Cerberus.

## Observed vs expected

- Observed: constraint violation (§6.7.9#4 cited) for a conditional
  operator over integer constants.
- Expected: accepted; `a == 10`.

## Impact

`static const int N = cond ? A : B;` and macro-generated initialisers
(`#define MAX(a,b) ((a)>(b)?(a):(b))` used in a static table) are common;
each such translation unit is refused before execution.

## Proposed remedy

Add the conditional arm to `is_arithmetic_constant_expression`, mirroring
the existing one in `is_integer_constant_expression` (:727-740):

```
    | AilEcond e1 e2_opt e3 ->
        is_arithmetic_constant_expression is_lvalue e1 >>= fun b1 ->
        (match e2_opt with Just e2 -> is_arithmetic_constant_expression is_lvalue e2 | Nothing -> E.return true end) >>= fun b2 ->
        is_arithmetic_constant_expression is_lvalue e3 >>= fun b3 ->
        E.return (b1 && b2 && b3)
```

(The `is_integer_constant_expression` arm's own `TODO: this is too
strict, it is allowed for the dead branch to not be a constant` applies
here as well — §6.6#3's "except when … not evaluated" — but the
all-constant form is the common case and the current behaviour rejects
even that.) The same predicate is also where a string-literal base for
address arithmetic is missing (companion report on `"hello" + 1`).

## Classification

**TRUE BUG.** Two predicates for one standard notion disagree; the
missing arm is an omission (no comment), and the consequence is a
constraint-violation diagnostic on strictly-conforming code.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding E3); both engines reject (shared desugaring), gcc accepts.
Re-verified 2026-09-05 on the un-forked upstream binary + runtime @
`b9aeedcb4`, the fork's oracle and the Lean port (lines above verbatim).
Localisation and this draft by Claude (Fable 5.1) under operator
direction; the filed issue carries an AI-provenance note per the tray's
policy.
