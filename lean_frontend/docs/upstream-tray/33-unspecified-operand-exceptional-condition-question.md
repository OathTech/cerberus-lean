# Question: an unspecified operand of signed `+` is classified as `UB036_exceptional_condition` — which UB (if any) is intended for `(x & 0) + 3` with indeterminate `x`?

**Affected:** `frontend/model/translation.lem:2165-2171` (the additive
operators' elaborated `case`: the catch-all arm for "either operand
unspecified" is `Caux.mk_unspecified_pe result_ty` for an unsigned result
type and `Caux.mk_undef_exceptional_condition loc` for a signed one, with
the comment "Otherwise it is undef, since the addition may overflow");
`frontend/model/core_aux.lem:476-478` (`mk_undef_exceptional_condition` =
`undef(<<UB036_exceptional_condition>>)`, §6.5#5); the same shape at
`translation.lem:2068-2075` (multiplicative), `:1683-1690` (shifts).
Checked against `master` @ `b9aeedcb4`: both files differ from master
only by Lean-target `declare` lines outside the cited regions (master's
line numbers).

## Description

The elaboration of a binary arithmetic operator on `loaded integer`
operands pattern-matches `(Specified, Specified)` and otherwise falls to
a catch-all. For UNSIGNED result types the catch-all yields an
unspecified value (the operand's indeterminacy propagates); for SIGNED
result types it yields `UB036_exceptional_condition`, on the stated
grounds that the addition "may overflow". The verbatim elaborated Core
for the reproducer (`--pp=core`, upstream binary, 2026-09-05):

```
        case (a_515, a_516) of
          | (Specified(a_517: integer), Specified(a_518: integer)) =>
              Specified(catch_exceptional_condition_add('signed int', __conv_int__('signed int', a_517), __conv_int__('signed int', a_518)))
          | _: (loaded integer,loaded integer) =>
              undef(<<UB036_exceptional_condition>>)
        end
```

So `(x & 0) + 3` with indeterminate `x` — where `x & 0` is elaborated to
an unspecified value (the bitwise operators' catch-all is `Unspecified`
regardless of signedness) — is reported as an exceptional condition at
the `+`, although the only values the left operand can take are 0 and
the addition cannot overflow.

We are not sure this is a bug; it may be a deliberate over-approximation.
The two readings we can see:

- (a) **ISO C11 §6.3.2.1#2**: `x` is an automatic object whose address
  is never taken and is read while indeterminate — the READ is undefined
  behaviour. Under this reading the program is UB, but the UB is at `x`'s
  read and should carry a §6.3.2.1 code, not `UB036` at the `+` (Cerberus
  has such codes elsewhere: e.g. `UB_CERB004_unspecified__conditional` for
  an unspecified controlling expression). The `&` arm's `Unspecified`
  result and the `+` arm's UB036 are then two different answers to the
  same question inside one expression.
- (b) **unspecified values flow** (the model's general stance: reads of
  indeterminate objects yield `Unspecified`, and most operators propagate
  it): then a signed `+` with an unspecified operand should also produce
  an unspecified value, and report UB036 only if the operand's VALUE could
  make the operation overflow — which the current catch-all cannot know,
  so it over-approximates to UB.

## Reproducer

`tests/noodle-probes/misc/misc_unspec_absorbed.c`:

```c
int main(void) { int x; return (x & 0) + 3; }
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive misc_unspec_absorbed.c
Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<4:32--4:43>"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`;
the fork's oracle at `928aa1e76` and our Lean port print the identical
line; gcc 13.3.0 returns 3, which is not a referee for a program that may
be UB.) Companion probes: `misc/misc_unspec_in_condition.c` (indeterminate
controlling expression → `UB_CERB004_unspecified__conditional`, all
engines agree) and `misc/misc_unspec_struct_member.c` (an unwritten member
of an addressed struct reads as `Unspecified('signed int')`, no UB).

## The question

Which is intended: that indeterminate automatic reads are UB per
§6.3.2.1#2 (then the code and location should say so, uniformly across
operators), or that unspecified values propagate (then the signed-`+`
catch-all should produce `Unspecified(result_ty)` like the unsigned and
bitwise arms, with UB036 reserved for a demonstrable overflow)? Either
answer is fine for our port — we mirror the current behaviour — but the
current mix (UB036 at the `+`, `Unspecified` at the `&`) does not match
either reading, and the report location points at the addition rather
than at the indeterminate read.

## Classification

**UNCLEAR — question.** No wrong answer is asserted; the request is for
a stated rule so that downstream tools (and our port's documentation) can
describe what an `Unspecified` operand means under signed arithmetic.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
observation O6). Re-verified 2026-09-05 on the un-forked upstream binary
+ runtime @ `b9aeedcb4`, the fork's oracle and the Lean port (line above
verbatim); the elaborated Core is from the upstream binary's `--pp=core`
on the same date. Analysis and this draft by Claude (Fable 5.1) under
operator direction; the filed issue carries an AI-provenance note per the
tray's policy.
