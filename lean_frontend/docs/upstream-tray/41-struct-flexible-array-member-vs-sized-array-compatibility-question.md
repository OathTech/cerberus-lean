# Question: is `struct S { int n; int a[]; }` INCOMPATIBLE with `struct S { int n; int a[2]; }` across translation units? `Ctype_aux.are_compatible_aux` keeps the flexible array member outside the member list it compares, so the two definitions differ in member COUNT

**Affected (for orientation):** `frontend/model/ctype_aux.lem:95-…` (the `Struct/Struct`
arm of `are_compatible_aux`; `:117` `if List.length xs1 <> List.length xs2 then false`,
then the pairwise member comparison, then the `(flexible_opt1, flexible_opt2)` match
whose `(Just _, Nothing)` / `(Nothing, Just _)` cases are `false`) and
`frontend/model/ctype.lem:76-85` (`flexible_array_member` is a SEPARATE component of
`StructDef`: `StructDef of list (identifier * …) * maybe flexible_array_member`). Checked
against `master` @ `b9aeedcb4`: the cited lines are the merge-base's (the fork's copy of
the arm carries the draft-37 assumed-list parameter, same logic).

## Observation

Two translation units define the same tag with the same two member names; TU 1's last
member is a flexible array member, TU 2's is a sized array of the same element type. A
`struct S` value is returned across the boundary and its FIRST member selected:

```c
/* tu1.c */
struct S { int n; int a[]; };
struct S mk(void) { struct S s; s.n = 7; return s; }
/* tu2.c */
struct S { int n; int a[2]; };
struct S mk(void);
int main(void) { return mk().n; }
```

Verbatim, 2026-09-15 (`--nolibc --exec --batch --mode=exhaustive tu1.c tu2.c`; the case is
`tests/multi_tu_tray/fam-vs-array-return/` in the fork; pristine = upstream `b9aeedcb4`
built with upstream Lem; fork = `arc/semantics-audit-repairs` @ `dbe633ec5`, where
`PEmemberof(struct)` consults `Ctype_aux.are_compatible` — draft 38's remedy):

```
=== pristine upstream
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(533, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}
rc=1
=== fork oracle (are_compatible consulted at member selection; it says INCOMPATIBLE)
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(533, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}
rc=1
=== fork Lean port
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(50, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"}
rc=1
=== gcc -std=c11 -O0 -w tu1.c tu2.c   (note: "the ABI of passing struct with a flexible array member has changed in GCC 4.4")
gcc exit=7
```

On upstream the rejection is the exact-tag guard (draft 38) — compatibility is never
asked. On the fork the guard asks `are_compatible`, which answers FALSE by the mechanism
above: TU 1's definition is `StructDef [n] (Just (FlexibleArrayMember a))`, TU 2's is
`StructDef [n; a] Nothing`; `List.length xs1 <> List.length xs2` (1 ≠ 2) → `false`. Had
the counts matched, the `(Just _, Nothing)` arm of the flexible-member match would also
answer `false`. Contrast: the same program with `int (*p)[]` vs `int (*p)[2]` as the last
member (an incomplete array behind a pointer, an ORDINARY member) is compatible on the
fork and runs to 7 (`tests/multi_tu_tray/arr-incomplete-ptr-return`).

## Question for upstream

C11 §6.2.7#1 requires, for two struct types with the same tag declared in separate
translation units, "a one-to-one correspondence between their members such that each
pair of corresponding members are declared with compatible types"; §6.7.6.2#6 makes an
array of unknown bound compatible with any array of compatible element type; §6.7.2.1#18
introduces the flexible array member as "the last element of a structure … [that] may
have an incomplete array type". Reading `a[]` as a member declared with an incomplete
array type, the two definitions above are compatible and the program is strictly
conforming (gcc links and runs it). Reading the flexible array member as a special
component — as `StructDef` models it — the definitions are not in one-to-one
correspondence. Which reading do the authors intend for `are_compatible_aux`? Is the
member-count test with the FAM held outside the list deliberate (a conservative choice,
as the arm's comment "being conservative here (aka STD compliant)" suggests), or an
artefact of the representation?

## Impact

Minor. Reached only where `Ctype_aux.are_compatible` is consulted on a struct VALUE
crossing translation units (store of such a value under a ctype, `core_aux.lem:200`; on
the fork also member selection). Programs mixing a C99 flexible array member in one TU
with a sized last member in another (the pre-C99 `a[1]` idiom versus `a[]`) are the
exposed shape; struct-by-pointer programs are unaffected.

## Proposed remedy

If the intended answer is "compatible": in the `Struct/Struct` arm, before the count test,
normalise a flexible array member into the member list as `(ident, (attrs, Nothing, qs,
Array elem_ty Nothing))` on BOTH sides (so `int a[]` meets `int a[2]` in the ordinary
`Array/Array` arm, §6.7.6.2#6), or add the two mixed cases to the flexible-member match.
If the intended answer is "incompatible": a comment at the arm stating that a flexible
array member is compared only with a flexible array member, and a diagnostic more
specific than "mismatched tags".

## Classification

**UNCLEAR / QUESTION**, minor — a design reading of §6.2.7#1 for flexible array members;
not a bug claim. The fork makes NO change here (both engines and upstream agree; the
mirror rule); the case is pinned as observed in `tests/multi_tu_tray/fam-vs-array-return`
(LADDER Tier A row 6b).

## Provenance

Found 2026-09-15 while pinning the cross-TU struct-value repair (drafts 38/39) in the
semantics-audit repairs slice (record
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md` §D3; charter §8 item 4
names the question). Observed by the worker (Claude, Fable 5.1) [AGENT], drafted by the
same under operator direction; the filed issue carries an AI-provenance note per the
tray's policy (`INDEX.md`, "Provenance labeling policy"). Related: drafts 37, 38, 39 (the
same compatibility predicate).
