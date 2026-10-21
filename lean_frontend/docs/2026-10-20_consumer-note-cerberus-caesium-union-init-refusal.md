# Consumer note for cerberus-caesium: the union-initializer refusal (2026-10-20)

From: the `fix/union-init-refusal` worker [AGENT]. Occasion: the orchestrator's 2026-10-20
measurement of union initializers against gcc 13 (upstream-tray draft 59). [USER 2026-10-20]
ruled, as for the item-G refusals (our note of the same date), that where upstream Cerberus left
a case deliberately to a TODO the fork either leaves it as-is or REFUSES LOUDLY — the run dies
with a declared unsupported outcome — never inventing a verdict and never answering silently
wrong; and, for union initializers specifically, that the fork refuses rather than fixes
("refuse until it hurts"). Contract entry D11; witnesses `scripts/check_union_init_refusals.sh`
(ladder row 1); record `docs/2026-10-20_union-init-refusal-record.md`.

Status: on branch `fix/union-init-refusal`, implemented and witnessed on both engines, focused
gates green; Tier A/B and the merge are the orchestrator's. One gated Tier A row was literally a
refused case (`tests/coverage/union3/union3-003-union-init.c`, `{ .c = 'A' }` with `c` the second
member, right before only by representation overlap); [USER 2026-10-20] ruled it retired with its
baseline row, the witness script carrying its shape. The behaviour below is what the next re-pin
that includes the branch carries.

## What now refuses

Upstream's LIVE initializer desugarer, `frontend/model/desugaring_init.lem` (reached from
`cabs_to_ail.lem:3527-3528`; `cabs_to_ail.lem`'s own `constructValue` is dead code), builds EVERY
braced union initializer as the FIRST member, whatever the designators say — its
`constructValue_aux` carries upstream's `TODO: this is only correct if the first member was the
one initialised` and prints `constructValue_aux: is WRONG for union ==> always assigning the
first member` at the default debug level; the init-map key for a union position, `Elem_union`,
has no member identity. So `union U { int i; unsigned char c[4]; } u = { .c = {1,2,3,4} }` gave
`u.c[0]*100 + u.c[3]` = 0 on both engines (gcc 104); draft 59 (a) has twelve such rows.

Now the SHARED desugarer refuses, in `moveTo_aux`'s Union arm (the one place the designated
member is decidable), whenever a member designator on a union names a member other than the
first: at any depth, in any storage class, in arrays of unions, nested unions, compound literals
(`(union U){ .c[2] = 8 }` in any position) and a union inside a struct (`{ .u = { .c = … }, .k =
7 }`, which used to die with draft 08's `invalid node` internal error and now refuses first).
A Lem `error` becomes `Cerb_debug.error` in the oracle and `failwithI` in Lean, so the text is
one string by generation (the member names as the C source spells them; the union's tag name
from its symbol description — `an unnamed union` for a tagless one):

```text
Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); C17 6.7.9#17-19 (a designator selects the member to initialize, in list order; subobjects not initialized explicitly are initialized implicitly); upstream's desugaring_init.lem constructValue_aux builds every braced union initializer as the FIRST member whatever the designators say ('TODO: this is only correct if the first member was the one initialised' b9aeedcb4 :576; 'constructValue_aux: is WRONG for union ==> always assigning the first member' :592) - the fork refuses rather than decides (item U, 2026-10-20)
```

On the wire: the oracle prints `internal error: <text>` and dies on the uncaught exception
`Failure("internal error: <text>")` + an OCaml backtrace, exit 125; the Lean engine aborts under
`LEAN_ABORT_ON_PANIC=1` with `PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: <text>` on
stderr, exit 134 (`--batch` prints nothing else). It fires during desugaring, before typing and
before any execution — a never-called function's initializer refuses too. Lean site: the
generated `Desugaring_init.moveTo_aux` / `Desugaring_init.union_designator_refusal`
(`lean_frontend/generated/Desugaring_init.lean`); oracle site: the generated
`ocaml_frontend/generated/desugaring_init.ml`, both from the one `.lem`.

The predicate is a single test — "a member designator on a union naming a non-first member".
A list that mixes positional and designated elements is silently wrong only when it contains
such a designator; `{ 9, .a = 2 }` and `{ .a = 1, .a = 2 }` answer 2 on both engines as gcc does
and are controls, not refusals.

## What does not change

Agreeing with the oracle, witnessed as controls: positional initializers (`{ 9 }`), first-member
designators (`{ .i = 258 }`, twice, in static storage, when the first member is an array
(`union V { unsigned char c[4]; int i; } v = { .c = {1,2,3,4} }` → 104) or a partially designated
struct), arrays of unions designated at the first member, `{ 0 }` on a union whose first member
is smaller than another (`union U { char c; int i; } u = { 0 }; return u.i;` →
`Unspecified('signed int')` on both — a strict ISO reading, kept), an ANONYMOUS union member
inside a struct designated through the struct (`struct S { int k; union { int i; unsigned char
c[4]; }; } s = { .c = {1,2,3,4}, .k = 7 }` → 74: upstream splices the anonymous member's members
into the enclosing struct, so `.c` resolves through `find_struct_member`, never reaching the
union arm), a union inside a struct initialised positionally or at its first member (71), and
member assignment after declaration.

Declared gaps, NOT refused, reported in draft 59 (b)/(c) and unchanged on both engines: a
struct or union VALUE as a member initializer (`struct S s = { .t = x, .t.l = 5 }`,
`union U a[2] = { x, x }`) and a designated union compound literal in the initializer position
(`union U u = (union U){ .c[2] = 8 }`) are constraint violations (`initializing 'signed int'
with an expression with a non arithmetic type …`; Lean `Error {msg: "typechecking failed at
…"}`, exit 1) where gcc accepts; an anonymous union member is flattened into the enclosing
struct's LAYOUT (`sizeof(struct S)` 12 where gcc has 8; `s.i` and `s.c` do not alias) — found
while measuring, outside this refusal's scope: anonymous union members are NOT reached by the
refusal (`struct S { union { int i; unsigned char c[4]; }; } s = { .c = {1,2,3,4} }` still
answers silently wrong on both engines), a known class that remains until the queued
anonymous-members slice lands (the upstream-uncertainty survey record (`docs/2026-10-20_upstream-uncertainty-survey-record.md`, branch `docs/uncertainty-survey`, §2.1 cluster A; tray 60)).

## If your harness runs union-initializing programs

Any program whose braced initializer names a non-first union member now dies in the desugarer
of both engines with the text above (exit 125 / 134) instead of a verdict. The texts are
pre-envelope, as the item-G ones are; the outcome-protocol design pass will move them into its
envelope. The witness script matches them as substrings by its `HEAD`/`TAIL` constants.
