# Union initializers: the desugarer builds every braced union initializer as the FIRST member (its own TODO), and three neighbouring initializer defects it does not record

**Affected:** `frontend/model/desugaring_init.lem` (the live initializer
desugarer; `cabs_to_ail.lem:3527-3528` calls `Desugaring_init.desugar_init`
and `Desugaring_init.constructValue`, while `cabs_to_ail.lem`'s own older
`constructValue_aux` (`:489-550`) is dead code — its call site is commented
out at `:3555`). In `constructValue_aux` (`:555-614`): the Union arm (`:583-599`)
builds `AilEunion tag_sym first_memb_ident (...)` whatever the designators
said, under a level-0 debug print `"constructValue_aux: is WRONG for union
==> always assigning the first member"` (`:590-593`; printed on stderr at the
default debug level on every braced union initializer), and the comment
`(* TODO: this is only correct if the first member was the one initialised *)`
(`:576`, inside the Struct arm's member map — it reads as the Union arm's
note; the dead copy in `cabs_to_ail.lem:528` has it in the Union arm). The
init-map keys are `init_path` lists whose union element is the memberless
`Elem_union` (`:412-416`, `to_init_path` `:441-452`), so by the time the value
is built the designated member is no longer known. Checked against `master`
@ `b9aeedcb4`: `desugaring_init.lem` is byte-identical. The Lean port is
generated from the same `.lem` and answers the same way; the measurements
below are on the pristine upstream build (`b9aeedcb4`) unless stated.

## Description

### (a) The first-member assumption (upstream's TODO)

C17 §6.7.9#17 (each brace-enclosed list has a current object; a designation
causes the following initializer to begin initialization of the subobject
the designator describes), #18 (a designator list narrows from the current
object of the closest surrounding brace pair), #19 (initialization occurs
in initializer-list order; a later initializer for the same subobject
overrides an earlier one; all subobjects not initialized explicitly are
initialized implicitly the same as objects that have static storage
duration — for a union that is #10's rule: the first named member, padding
zeroed; C23 §6.7.11#11 keeps "first named member plus padding"). #21 (fewer
initializers than members ⇒ the remainder initialized implicitly) is stated
for aggregates only; a union is not an aggregate (§6.2.5#21). §6.2.6.1#7:
when a value is stored in a member of a union, the bytes that do not
correspond to that member but do correspond to other members take
unspecified values.

So `.c = {1,2,3,4}` on `union U { int i; unsigned char c[4]; }` selects `c`
and the object holds those four bytes. The desugarer instead constructs the
union with member `i`, giving `i` the expression it finds at the union's
init-map key — for the array case nothing (zero), for a scalar second member
the designated expression itself. Every row below is a well-formed C17
program; gcc 13.3.0 (`-std=c11`) gives the value in the gcc column (re-run
2026-10-20); pristine upstream `b9aeedcb4` (`--exec --batch --nolibc`) gives
the value in the upstream column.

| # | declarations | initializer | returns | gcc | upstream `b9aeedcb4` |
|---|---|---|---|---|---|
| 1 | `union U { int i; unsigned char c[4]; };` | `union U u = { .c = {1,2,3,4} };` | `u.c[0]*100 + u.c[3]` | 104 | `Specified(0)` |
| 2 | same | file-scope `union U u = { .c[1] = 7 };` | `u.c[1]*10 + u.c[0]` | 70 | `Specified(0)` |
| 3 | same | automatic `union U u = { .c[3] = 6 };` | `u.c[3]*10 + u.c[0]` | 60 | `Specified(0)` |
| 4 | `union U { int i; struct { int x; int y; } s; };` | `union U u = { .s = { .y = 2 } };` | `u.s.y*10 + u.s.x` | 20 | `Undefined {ub: "UB036_exceptional_condition", …}` |
| 5 | `union U { int a; char c[4]; };` | `union U u = { .a = 42, .c[2] = 1 };` | `u.c[0]*100 + u.c[1]*10 + u.c[2]` | 1 | `Specified(4200)` |
| 6 | same | `union U u = { .c[2] = 1, .a = 42 };` | `u.a` | 42 | `Specified(42)` (right by luck: the last initializer is the first member's) |
| 7 | same | `union U u = { 9, .c[1] = 3 };` | `u.c[0]*10 + u.c[1]` | 3 | `Specified(90)` |
| 8 | `union In { int i; char c[4]; }; union Out { long l; union In in; };` | `union Out o = { .in = { .c[1] = 5 } };` | `o.in.c[1]*10 + o.in.c[0]` | 50 | `Specified(0)` |
| 9 | `union U { int i; char c[4]; };` | `union U a[2] = { [1] = { .c[0] = 9 }, [0] = { .i = 1 } };` | `a[0].i*10 + a[1].c[0]` | 19 | `Specified(10)` |
| 10 | same | `union U u = { .c = "ab" };` | `u.c[0] + u.c[2]*10` | 97 | `Specified(0)` |
| 11 | `union U { long b; int a; };` | `union U u = { .a = 5 };` | `u.a` | 5 | `Specified(5)` (right only because `a`'s bytes overlap `b`'s) |
| 12 | `union U { int i; char c[4]; };` | `(union U){ .c[2] = 8 }` as an rvalue (assigned, passed, or its address taken) | `….c[2]*10` | 80 | `Specified(0)` |

Row 4's UB verdict is the first member `i` being initialised with a struct
expression's zero-init and read back; rows 6 and 11 are correct by accident.
Row 12 is the compound-literal path (`cabs_to_ail.lem:2377-2383`,
`CabsEcompound` → `wip_desugar_initializer_` → the same desugarer).

Reproducer for row 1, verbatim on pristine `b9aeedcb4` (exit 0; the
`(debug 0)` line is the desugarer's own print at the default debug level):

```c
union U { int i; unsigned char c[4]; };
int main(void) { union U u = { .c = {1,2,3,4} }; return u.c[0]*100 + u.c[3]; }
```

```text
(debug 0): constructValue_aux: is WRONG for union ==> always assigning the first member
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```

Forms the desugarer handles correctly (measured, both engines = gcc): a
positional or first-member-designated initializer (`{ 9 }`, `{ .a = 1, .a = 2 }`
→ 2, `{ 9, .a = 2 }` → 2), a first member that is a partially designated
struct (`union U { struct { int x; int y; } s; long b; } u = { .s = { .y = 2 } }`
→ `u.s.y*10 + u.s.x` = 20), a first member that is an array, an array of unions
designated at the first member, `{ 0 }` on a union whose first member is
smaller than another (`union U { char c; int i; } u = { 0 }; return u.i;` →
`Unspecified('signed int')` on both engines, a strict ISO reading), a union
inside a struct initialised positionally or with a first-member designator
(`struct S { union U u; int k; } s = { { 1, 2, 3, 4 }, 7 }` / `{ .u = { .i = 1 },
.k = 7 }` → 71), and an ANONYMOUS union member designated through the
enclosing struct (`struct S { int k; union { int i; unsigned char c[4]; }; } s =
{ .c = {1,2,3,4}, .k = 7 }` → `s.k*10 + s.c[3]` = 74 — a different path, see (c)
below).

### (b) Three neighbouring defects the desugarer has no comment for

**(b1) A struct (or union) VALUE as the initializer of a struct/union
member is rejected.** `interp_initializer_aux`'s `Init_expr` arm
(`desugaring_init.lem:479-506`) always descends to a scalar leaf
(`go_bottom`, under `if false (* is_compound_literal OR string literal *)
then internal_error "TODO: explode the elements"`, `:496-497`), so the
expression lands at the leaf's path and the typechecker rejects it there.
gcc accepts both (5 and 3):

```c
struct T { int t; long l; };
struct S { struct T t; };
int main(void) { struct T x = { 1, 2 }; struct S s = { .t = x, .t.l = 5 }; return (int)s.t.l; }
```

```text
n_struct_from_struct_value.c:3:61: error: constraint violation: initializing 'signed int' with an expression with a non arithmetic type 'struct T'
```

```c
union U { int i; char c[4]; };
int main(void) { union U x = { 3 }; union U a[2] = { x, x }; return a[1].i; }
```

```text
n_union_from_union_value.c:2:54: error: constraint violation: initializing 'signed int' with an expression with a non arithmetic type 'union U'
```

**(b2) A union compound literal with a designator, in the INITIALIZER
position, is the same rejection** (`union U u = (union U){ .c[2] = 8 };` →
`constraint violation: initializing 'signed int' with an expression with a
non arithmetic type 'union U'`; gcc 80), while the same literal assigned,
passed as an argument or address-taken is row 12's silent `Specified(0)`.
The initializer form is (b1)'s rejection applied to a compound literal; the
other forms are (a).

**(b3) A union inside a struct, with the union's member designated inside
its own braces, dies with an uncaught internal error** (the `AilEinvalid`
placeholder reaching `Translation`, draft 08's symptom): gcc 74.

```c
union U { int i; unsigned char c[4]; };
struct S { union U u; int k; };
int main(void) { struct S s = { .u = { .c = {1,2,3,4} }, .k = 7 }; return s.k*10 + s.u.c[3]; }
```

```text
internal error: Translation called on Ail program with an invalid node
cerberus: internal error, uncaught exception:
          Failure("internal error: Translation called on Ail program with an invalid node")
```

Six other union-inside-struct shapes answer correctly (positional
`{ {1,2,3,4}, 7 }`, `{ .u = { 1 }, .k = 7 }`, `{ .u = { .i = 1 }, .k = 7 }`,
with the union as the second member positionally or designated, and at
file scope — all 71, both engines); the failing class is the designated
non-first member inside the inner braces. Cross-reference: draft 08
(nested braced initializers → `AilEinvalid` → uncaught internal error):
the remedy there (report `AilInvalid_desugaring_init_failed` as a diagnostic
instead of `failwith`) would turn this death into a located diagnostic too.

**(b4) A string literal initializing a union's FIRST-member char array is
rejected** (the pre-merge reviewer's probe p12, 2026-10-21): gcc 98; both
engines and pristine `b9aeedcb4` reject, exit 1.

```c
union U { char s[4]; int i; }; int main(void){ union U u = { "abc" }; return u.s[1]; }
```

```text
p12_string_first_member.c:1:52: error: constraint violation: initializing 'char' with an expression with a non arithmetic type 'char*'
```

(Lean: `Error {msg: "typechecking failed at …"}`.) The desugarer's union
arm enters the first member positionally (`go_down_aux`, `:104-106`) and
then treats the literal as the scalar leaf's initializer — (b1)'s descent
again, now on a string literal; the brace-less string form that
`wip_desugar_initializer_` special-cases for a plain char array
(`cabs_to_ail.lem:3446-3450`) is not reached through a union. A noisy
neighbour of (b1), not a silent one.

### (c) Found while measuring: an anonymous union member is flattened into the enclosing struct

`desugar_struct_declaration` (`cabs_to_ail.lem:2713-2720`, "STD §6.7.2.1#13")
returns an anonymous struct/union member's members and the enclosing struct
takes them as its own members — the Ail print of `struct S { int k; union
{ int i; unsigned char c[4]; }; }` is `struct S { signed int k; signed int i;
unsigned char c[4]; }`. §6.7.2.1#13 makes the anonymous member's members
members of the containing structure for NAMING; it does not change the
layout. So `sizeof(struct S)` is 12 (gcc 8) and `i` and `c` do not alias:

```c
struct S { int k; union { int i; unsigned char c[4]; }; };
int main(void) { struct S s = { .c = {1,2,3,4}, .k = 7 }; return sizeof(struct S)*100 + (s.i == 0x04030201 ? 1 : 0); }
```

gcc: 801 (exit status 33); pristine upstream and the Lean port: `Specified(1200)`.
Not an initializer defect (the initializer above is desugared correctly for
the flattened struct — that is why the anonymous-union control in (a) is
right); reported here because the measurement surfaced it and no other draft
carries it. Not changed in the fork by this slice; since 2026-10-20 it is
the subject of tray draft 60 (`60-anonymous-members-spliced-into-containing-aggregate.md`)
and the upstream-uncertainty survey record (`docs/2026-10-20_upstream-uncertainty-survey-record.md`, branch `docs/uncertainty-survey`, §2.1 cluster A), a separate queued slice.

## Expected

(a): the designated member is the one initialised, the object's bytes being
those of that member (C17 §6.7.9#17-19, §6.2.6.1#7). (b1)/(b2): a struct or
union expression initializing a subobject of its own type is accepted and
copied (§6.7.9#13). (b3): a diagnostic or the right value, never an uncaught
exception. (c): the layout of the anonymous member is the union's.

No fix is claimed obvious: the value of the other members' bytes after a
designated initializer (§6.2.6.1#7's unspecified values versus the
zero-initialisation static storage implies for the FIRST named member
only), overriding initializers that name DIFFERENT members of one union in
one list (row 5/6: #19 says the later wins for the same subobject; the
members are different subobjects of the same bytes), and `{ 0 }` on a union
whose first member is smaller than another (#19's implicit initialisation
reaches only the first named member) are each a reading of the standard,
not a mechanical consequence of it.

## Origin

Found 2026-10-20 by the operator (orchestrator) while measuring union
initializers on both fork engines against gcc 13; the table above was
re-measured on pristine `b9aeedcb4` and gcc 13.3.0 on 2026-10-20 by the
slice worker. Drafted by Claude (Fable 5.1) under operator direction;
AI-provenance note per the tray's policy.

Fork-ahead refusal (2026-10-20, not a fix for upstream): under the ruling
that where upstream left a case deliberately to a TODO the fork leaves it or
REFUSES LOUDLY, never answering silently wrong — and, for union initializers
specifically, refuses rather than fixes — the fork's SHARED desugarer
(`desugaring_init.lem` `moveTo_aux`, the Union arm) now dies with an
attributed text on both engines when a member designator names a member of
a union other than the first (every row of table (a) and (b2)'s rvalue
forms, and (b3)'s program, which refuses before the internal error);
contract D11, `scripts/check_union_init_refusals.sh`, record
`lean_frontend/docs/2026-10-20_union-init-refusal-record.md`. (b1), (b2)'s
initializer form, (b4) and (c) are unchanged in the fork.
