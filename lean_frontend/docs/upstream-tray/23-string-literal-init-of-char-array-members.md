# String literals cannot initialise `char`-array MEMBERS or ELEMENTS: `char a[2][3] = {"ab", "cd"}` and `struct { char c[3]; } w = {{"ab"}}` are rejected

**Affected:** `frontend/model/desugaring_init.lem:461-471` (`interp_initializer_aux`,
`Cabs.Init_expr` arm: `if false (* is_compound_literal OR string literal *)
then internal_error "TODO: explode the elements" else (* NOTE: we dealing
with a scalar, so we go down to a leaf *) go_bottom …`), which sends a
string literal that appears INSIDE an initializer list down to the first
`char` leaf; `frontend/model/ail/genTyping.lem:167-183`
(`well_typed_assignment`, §6.5.16.1#1: a `char` scalar initialised from a
`char*` expression → `throw NotArithmetic`). Checked against `master` @
`b9aeedcb4`: `desugaring_init.lem` is byte-identical; `genTyping.lem`
differs only by two Lean-target `declare` lines (master's line numbers
used).

## Description

C11 §6.7.9#14 lets a string literal initialise "an array of character
type" wherever such an array is the current object — a top-level array
(`char s[3] = "abc"`), an element of an array of arrays, or a member of a
struct — and §6.7.9#20 lets the braces around it be elided. Cerberus
handles only the top-level form. Inside an initializer list the
`Init_expr` arm of `interp_initializer_aux` has the sub-aggregate case
stubbed out:

```
      if false (* is_compound_literal OR string literal *) then
        internal_error "TODO: explode the elements"
      else
        (* NOTE: we dealing with a scalar, so we go down to a leaf *)
        go_bottom tagDefs pos >>= fun pos ->
```

(desugaring_init.lem:461-465, verbatim) so the literal `"ab"` is assigned
to the first `char` of the sub-array, and Ail typing rejects a `char*`
initialising a `char` as a constraint violation (§6.5.16.1#1 bullet 1 via
`well_typed_assignment`). Every shape we tried rejects: struct member
with and without inner braces, member followed by another member, nested
struct, 2-D array, array of structs.

## Reproducers

`tests/noodle-probes/elab/elab_string_member_init.c`:

```c
char a[2][3] = {"ab", "cd"};
int main(void) { return a[1][0]; }
```

`tests/noodle-probes/elab/elab_string_struct_member_init.c`:

```c
struct W { char c[3]; } w = {{"ab"}};
int main(void) { return w.c[1]; }
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive elab_string_member_init.c
tests/noodle-probes/elab/elab_string_member_init.c:5:17: error: constraint violation: initializing 'char' with an expression with a non arithmetic type 'char*'
char a[2][3] = {"ab", "cd"};
                ^~~~ 
§6.7.9#11, sentence 2: 
11   The initializer for a scalar shall be a single expression, optionally enclosed in braces. The
     initial value of the object is that of the expression (after conversion); the same type
     constraints and conversions as for simple assignment apply, taking the type of the scalar
     to be the unqualified version of its declared type.

§6.5.16.1#1, bullet 1: 
1   One of the following shall hold:112)
    -- the left operand has atomic, qualified, or unqualified arithmetic type, and the right has

$ cerberus --nolibc --exec --batch --mode=exhaustive elab_string_struct_member_init.c
tests/noodle-probes/elab/elab_string_struct_member_init.c:4:31: error: constraint violation: initializing 'char' with an expression with a non arithmetic type 'char*'
struct W { char c[3]; } w = {{"ab"}};
                              ^~~~ 
```

(verbatim heads, exit 1, 2026-09-05, un-forked upstream binary + runtime
@ `b9aeedcb4`; the fork's oracle at `928aa1e76` prints the same
diagnostics; our Lean port, which runs the same desugaring, rejects with
`Error {msg: "typechecking failed at …:5:17-21"}` / `…:4:31-35`.)

```
$ gcc -std=c11 -O0 elab_string_member_init.c && ./a.out; echo $?
99
$ gcc -std=c11 -O0 elab_string_struct_member_init.c && ./a.out; echo $?
98
```

(gcc 13.3.0; verbatim 2026-09-05.) Control: `char s[3] = "abc"` and the
other top-level forms in `elab/elab_string_init_sizing.c` are accepted and
agree with gcc.

## Observed vs expected

- Observed: constraint violation ("initializing 'char' with … 'char*'")
  for a string literal that initialises a character array which is an
  element or a member.
- Expected: accepted per §6.7.9#14 (+#20 for the brace-elided form);
  values 99 / 98.

## Impact

`char names[][8] = {"alpha", "beta", …}` and `struct { char tag[4]; … }
x = {"ABC", …}` are among the most common initialiser idioms in C; every
translation unit containing one is refused before execution. In our
sweep of the upstream CI corpus this is a plausible slice of the
oracle-rejected files, and it is a hard block on real-world sources
(tables of strings).

## Proposed remedy

Implement the stubbed branch: in the `Init_expr` arm, when the
expression is a string literal (`AilEstr`) and the current position's
type (after `go_down` into the sub-aggregate if the literal sits where a
sub-aggregate starts, §6.7.9#20) is an array of character type, consume
the literal at THAT subobject — fill its elements from the string's
bytes (and the implicit NUL where it fits, §6.7.9#14 sentence 2) exactly
as the top-level path does — and advance the cursor past the array,
instead of descending to the first scalar leaf. Wide string literals and
`wchar_t`/`charN_t` arrays are the same rule (§6.7.9#15). The comment's
own wording ("explode the elements") is the intended fix.

## Classification

**TRUE BUG.** The code marks the case as a `TODO` guarded by `if false`,
i.e. the omission is known, but the observable consequence — a
constraint-violation diagnostic on a strictly-conforming, ubiquitous
idiom — is a wrong answer rather than a declared limitation, and the
diagnostic misattributes the cause (§6.7.9#11 does not apply: the
initialiser is for an array, not a scalar).

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding E4); both engines reject (shared desugaring), gcc accepts.
Re-verified 2026-09-05 on the un-forked upstream binary + runtime @
`b9aeedcb4`, the fork's oracle and the Lean port (lines above verbatim).
Localisation and this draft by Claude (Fable 5.1) under operator
direction; the filed issue carries an AI-provenance note per the tray's
policy.
