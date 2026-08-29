# Draft 09 — ISO-legal address constants combining array subscript + member designator rejected as "not a compile-time constant"

Status: DRAFT, not filed (filing is the operator's call). Classification:
**TRUE BUG** (a C11 §6.6p9 address constant; gcc/clang accept; the
diagnostic cites the checker's own §6.7.9#4 constraint).
Verified against: upstream `master` @ `b9aeedcb4`
(`deps/cerberus-upstream`); fixtures re-run un-forked 2026-08-21
(arc-12 S3, revised per the arc-12 adversarial audit B-F3 to a clean
1-D fixture free of any nested-initializer entanglement).

## Reproducer (1-D, minimal)

`addr_const_member.c`:

```c
struct S { int a; int b; };
static struct S g_arr[2] = {{1,2},{5,3}};
static int *q = &g_arr[1].b;
int main(void) { return *q; }
```

gcc 15 `-std=c11`: compiles clean, returns 3. Upstream cerberus
(`--nolibc --exec --batch`), verbatim, exit code 1:

```
addr_const_member.c:3:17: error: constraint violation: initializer element is not a compile-time constant
static int *q = &g_arr[1].b;
                ^~~~~~~~~~~ 
§6.7.9#4: 
```

## The sharp boundary (all three probed on the same upstream build)

| initializer | upstream verdict |
|---|---|
| `&g_arr[1]` (subscript only) | ACCEPTED — control runs to `Specified(3)` |
| `&g.b` (member only, plain static struct object) | ACCEPTED — `Specified(3)` |
| `&g_arr[1].b` (subscript THEN member) | REJECTED, §6.7.9#4 |

So the static-initializer address-constant classifier handles array
subscripting and (top-level) member selection individually, but not
member selection ON AN ARRAY-ELEMENT base. C11 §6.6p9 defines address
constants as pointers to static-storage objects formed with `&` or via
lvalues using `[]`, `.`, `->`, casts — the combination is squarely
legal.

## Secondary witness (2-D; NOTE the entanglement)

Our original campaign witness used
`static struct S g_arr[2][2] = {{{1,2},{3,4}},{{5,6},{7,8}}};` with
`static int *g_q = &g_arr[1][0].f3;` — same rejection at the same
constraint. It is kept as a secondary data point only: its 2-D braced
initializer sits near the nested-initializer failure class of draft 08
(F-A), so the 1-D fixture above is the one to file (no entanglement;
the auditor-rebuilt control pair isolates exactly one axis).

## Impact

Static pointer-to-member-of-array-element initialization (device
tables, parser tables, linked structures). Same strictness family we
hit independently on libxml2 and a wireguard TU during other
campaigns.

## Proposed remedy

Extend the address-constant classifier used for static initializers
(the §6.7.9#4 check on the desugar path) to accept member selection on
an address-constant base that is itself an array element — i.e. make
the accepted-forms set closed under composition of the §6.6p9
designator operations. We can contribute the fixture + both controls
(minimized, deterministic, native-verified).
