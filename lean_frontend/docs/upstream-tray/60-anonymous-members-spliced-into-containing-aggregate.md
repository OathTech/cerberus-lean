# Anonymous struct/union members are spliced into the containing aggregate: wrong layout, no aliasing inside an anonymous union, and initializers one slot late

**Affected:** `frontend/model/cabs_to_ail.lem:2709-2719` (`desugar_struct_declaration`: for a struct-declaration
with no declarators, `E.get_anonymous_struct_or_union base_ty` returns the anonymous member's member list and the
arm `E.return membrs` splices those members into the containing aggregate, citing `STD §6.7.2.1#13`); the
initializer-path layer carries upstream's own doubt about the consequence (`Debug.print_debug 2 … "this may be
WRONG ==> anonymous Struct/Union"` at `cabs_to_ail.lem:144-207, :336, :509, :526, :3237, :3282` and
`desugaring_init.lem:572, :588`). Checked at the fork's merge-base `b9aeedcb4` (the pristine binary answers the
same). The Lean port is generated from the same `.lem` and answers the same.

## Description

The members of an anonymous structure or union are members of the containing aggregate for name lookup
(C17 §6.7.2.1#13), but the anonymous member is still one member with its own storage: an anonymous union's
members overlap (§6.7.2.1#16, §6.2.6.1#7) and an anonymous struct is laid out as a struct (its alignment is the
maximum of its members'). Splicing the members flat loses all three. The oracle's own `--pp=ail` for
`struct S { union { int b; char c; }; int d; };` prints

```
struct S {
  signed int b;
  char c;
  signed int d;
};
```

Consequences, measured 2026-10-20 on the fork @ `3ac3ff336` with `scripts/test_exec.sh` (oracle `--nolibc`
exhaustive batch vs the Lean port; both agree on every line; gcc 13 = the standard's answer):

```c
struct S { union { int b; unsigned char c; }; };
int main(void){ struct S s; s.b = 0x01020304; return s.c; }          /* gcc 4 */
```
```text
[1/1] MATCH au-02-alias: VAL:{value: "Unspecified('signed int')", stdout: "", stderr: "", blocked: "false"}
```

```c
struct S { union { int b; char c; }; }; int main(void){ return (int)sizeof(struct S); }   /* gcc 4 */
```
```text
[1/1] MATCH au-01-sizeof: VAL:{value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
```

```c
struct S { int a; union { int b; char c; }; int d; };
int main(void){ struct S s = {1, 2, 3}; return s.a + s.b*10 + s.d*100; }   /* gcc 321: a=1, b=2, d=3 */
```
```text
[1/1] MATCH an-02-elision: VAL:{value: "Specified(21)", stdout: "", stderr: "", blocked: "false"}
```
(the `3` went into `c`, the union's second member, and `d` stayed 0.)

```c
struct S { char a; struct { char b; int c; }; }; int main(void){ return (int)sizeof(struct S); }   /* gcc 12 */
```
```text
[1/1] MATCH ax-01-anon-struct-padding: VAL:{value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
```

Also measured: the offset of the member after an anonymous union (12 for 8), `union U { int x; struct { short lo,
hi; }; }` where both `lo` and `hi` alias the low half, a copy of such a struct leaving the never-written member
unspecified, false `UB081` for a braced initializer of an anonymous member, false `UB036`/unspecified-pointer UB
when the separately stored alias is read. Designated initializers that name the members work, which is why the
common kernel style hides the problem until a `sizeof`, an alias or a brace-elided initializer is reached. The
25 witnesses are `tests/parity-probes/uncertainty/A-anonymous-members/` in the fork
(`an-`, `un-`, `au-`, `ax-`, `ac-` prefixes; the `un-0?-named-*` and `au-05/06` files are the named-union
controls, which are right).

## Expected

An anonymous member desugared as one member (an unnamed identifier) whose type is the anonymous struct/union,
with member access through it resolved by name lookup (§6.7.2.1#13): `sizeof`, `offsetof`, aliasing and the
initializer cursor then follow from the existing struct/union rules. Until then, a diagnostic ("anonymous
members are not supported") rather than a defined answer.

## Origin

Found by the fork's upstream-uncertainty survey (2026-10-20, `lean_frontend/docs/2026-10-20_upstream-uncertainty-survey-record.md`,
cluster A), which probed the `this may be WRONG ==> anonymous` sites. Classification: TRUE BUG (silent wrong
layout and values on both engines and on pristine upstream). Fork plan ([USER 2026-10-20]): refuse anonymous
members in the shared desugaring (both engines, no semantics invented), queued behind the cerberus-caesium
deliveries; the report above describes upstream as it stands.

**Fork-ahead refusal (2026-10-26).** The fork REFUSES since 2026-10-26: `desugar_struct_declaration`'s
`E.return membrs` arm is a Lem `error` in the fork (both engines by generation, one text naming the member's kind,
C17 6.7.2.1#13, the splice site above and that the fork refuses rather than decides; contract D12; witnesses
`scripts/check_anonymous_members_refusal.sh`; record `lean_frontend/docs/2026-10-26_anonymous-members-refusal-record.md`).
This is a refusal, not a fix for upstream: the report stands as written, and the "Expected" section is what the
fork would adopt on re-pin.
