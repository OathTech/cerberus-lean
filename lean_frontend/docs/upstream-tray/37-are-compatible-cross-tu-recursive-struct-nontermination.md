# `Ctype_aux.are_compatible` never terminates on a self-referential struct defined in two translation units (STD §6.2.7#1 structural compatibility recurses through pointer members with no "assumed compatible" set)

**Affected:** `frontend/model/ctype_aux.lem:69-192` (`are_compatible_aux` and
its mutual `are_compatible_params_aux`/`are_compatible_params`; entry
`are_compatible` `:194`): the `Struct/Struct` arm (`:95-136`) — for two tags
NOT from the same translation unit (`:98`, `Symbol.from_same_translation_unit`
= digest equality, `symbol.lem:274`) with the same name, it looks both
definitions up (`:109`) and recurses into every member pair (`:120`); the
`Pointer/Pointer` arm (`:92`) recurses into the pointee types; the
`Union/Union` arm (`:137-176`) is the same shape; the `Function/Function` arm
recurses into the return and parameter types (`:85-87`, `:177-193`). Exec-path
caller: `core_aux.lem:182-184` (`memValueFromValue`, the `Struct`/`OVstruct`
arm — every store of a struct VALUE compares the ctype's tag with the value's).
Checked against `master` @ `b9aeedcb4`: the cited `.lem` files are the
merge-base's (our fork adds Lean-only `declare` lines at the top of
`ctype_aux.lem`, shifting its numbering; the code lines are identical).

## Description

Structural compatibility of two struct types from different translation units
is decided recursively on their member types. A struct whose member points to
its own type — a linked-list node, the most ordinary C shape there is —
yields the recursion `node/node → members → Pointer/Pointer → node/node → …`:
the two TUs' `struct node` definitions are compared, their `next` members are
compared, which compares the two `struct node` types again, and so on. The
function has no memo of the pairs it is already comparing (the standard's own
device for recursive types — C11 §6.2.7#1's rule is well-founded only because
the two tags are taken as compatible while their members are examined; the
usual implementation is an "assumed compatible" set or a depth cut at the
tags), so it never returns. Nothing about the program is unusual: both TUs
are strictly conforming, the struct is complete in both, and the value that
triggers the comparison is a plain by-value parameter.

## Reproducers

`tests/failure-probes/cross_tu_node/node_a.c` + `node_b.c` (two TUs; the
struct defined in both, a `struct node` value passed by value across the TU
boundary):

```c
/* node_a.c */
struct node { int v; struct node *next; };
struct node ident(struct node n) { return n; }
/* node_b.c */
struct node { int v; struct node *next; };
struct node ident(struct node n);
int main(void) { struct node n; n.v = 7; n.next = 0; return ident(n).v; }
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive node_a.c node_b.c
--- [fork oracle 2-TU cross_tu_node] rc=124 elapsed=60s
--- [upstream oracle 2-TU cross_tu_node] rc=124 elapsed=60s
--- [lean 2-TU cross_tu_node (default fuel)] rc=134 elapsed=3s
Stack overflow detected. Aborting.
```

(verbatim, 2026-09-08; `timeout 60s`, no output on either — the un-forked
upstream binary + runtime @ `b9aeedcb4`, `deps/cerberus-upstream`, and the
fork's oracle at `94f339eb4`+; gcc: exit 7.) Control
`node_single_control.c` — the SAME struct, function and call in ONE
translation unit — terminates on both (`Defined {value: "Specified(7)", …}`,
0.05 s): the same-TU fast path (`ctype_aux.lem:98-99`, `tag1 = tag2`) never
enters the members; only the cross-TU path recurses. First recorded by our
fuel-parameter C4 pre-merge audit (2026-09-05, §5.1: both oracles `rc=124`
at 60 s; the Lean port at the default fuel dies by NATIVE STACK OVERFLOW —
`Stack overflow detected. Aborting.`, rc=134, ~3 s; re-run 2026-09-08 on this
tree's driver, the third line above — the recursion is not tail-recursive and
the 8 MB stack goes long before any fuel bound: the recursion is genuinely
unbounded, not merely slow; `--fuel` cannot pin it to the fuel'd recursion).

## Observed vs expected

- Observed: non-termination (both oracles killed by the 60 s timeout; the
  OCaml process would eventually die of `Stack_overflow`).
- Expected: `Specified(7)` — the two `struct node` types are compatible
  (§6.2.7#1: same tag, one-to-one members with compatible types and the same
  names; the pointer members' targets are the types being compared, which the
  rule takes as compatible).

## Impact

Every multi-TU program that passes or stores a struct VALUE of a recursive
type across a translation-unit boundary (linked lists, trees, any
self-referential record shared through a header) cannot be executed: the
interpreter hangs at the first such store. Single-TU programs are unaffected
(the same-TU fast path). For our Lean port the pending register still carries
the three `ctype_aux` fuel'd workers (`scripts/fuel_forms_pending.txt`, the
deep-reference block): no hypothesis the frontend guarantees bounds this
recursion — the sufficient one (a rank descending through ALL references,
pointers included) is exactly what legal C violates — so the rows cannot be
closed by a measure; they are closed only by fixing the recursion here.

## Proposed remedy

Carry an "assumed compatible" set of tag pairs through `are_compatible_aux`
(the third component of `env`, say `assumed : set (Symbol.sym * Symbol.sym)`):
in the `Struct/Struct` and `Union/Union` cross-TU arms, if `(tag1, tag2) ∈
assumed` return `true`; otherwise recurse into the members with `(tag1, tag2)`
added. This is the standard's own reading of §6.2.7#1 for recursive types (and
what every compiler's type-compatibility check does), terminates because the
set can only grow to the finite number of tag pairs, and returns the same
answer on every terminating input (the members are still compared once).
Alternatively a per-call depth bound at the tag arms, but the set is the
faithful device.

## Classification

**TRUE BUG** (non-termination on strictly conforming input; the code's own
`TODO: being conservative here (aka STD compliant)` at `:97` marks the arm as
provisional). Not a modelling choice: the standard's rule is well-founded on
these inputs and the interpreter's implementation of it is not.

## Provenance

Found by the fuel-parameter arc's attempt to give `are_compatible_aux` a
data measure (C4 record `lean_frontend/docs/2026-09-05_fuel-parameter-C4-record.md`
§7 F-C4-1: by-value acyclicity does not bound it), reproduced by the C4
pre-merge audit (§5.1) and re-run 2026-09-08 on both oracles (lines above
verbatim) for the fuel-pending close-out
(`lean_frontend/docs/2026-09-08_fuel-pending-closeout-record.md` D3).
Localisation and this draft by Claude (Fable 5.1) under operator direction;
the filed issue carries an AI-provenance note per the tray's policy.

## Fork status (2026-09-10) — FIXED in the fork; the patch is the `.lem` diff

[AGENT 2026-09-10] Landed on the fork's mainline candidate `arc/are-compatible-assumed-set`
(record `lean_frontend/docs/2026-09-10_are-compatible-assumed-set-record.md`): the
remedy above, with a LIST rather than a set (`assumed : list (Symbol.sym * Symbol.sym)`,
`List.elem`; a set is equivalent — the list keeps the fork's Lean proofs on core
list laws). `env` is now the triple `(tagDefs1, tagDefs2, assumed)`; the entry passes
`(tagDefs, tagDefs, [])`; in the cross-TU `Struct/Struct` and `Union/Union` arms,
after the same-name test and before the two lookups, `if List.elem (tag1, tag2)
assumed then true else …`, and the member comparisons (including the flexible array
member) run with `(tag1, tag2) :: assumed`; every other recursive call passes the
current list unchanged (a path-set, never returned). The patch for upstream is the
`frontend/model/ctype_aux.lem` diff of that record's D1 commit, minus its Lean-only
`declare {lean} …` lines. Results on every previously-terminating input are unchanged
(argument in the record); the fork's Tier A/B corpora moved nowhere.

The reproducer no longer hangs on the fork, and exposes the NEXT cross-TU limitation
(draft 38): both fork engines now reach `core_eval.lem:946`'s exact-tag guard in
`PEmemberof(struct)` when the returned `struct node` value (tagged by TU 1) is
member-selected under TU 2's type. Verbatim, 2026-09-10 (fork oracle and Lean at the
record's D2 state; pristine upstream `b9aeedcb4` + lem `3802cb0`):

```
=== fork-oracle: cerberus --nolibc --exec --batch --mode=exhaustive node_a.c node_b.c
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(531, SD_Id("node")) vs Symbol(502, SD_Id("node"))'"}
rc=1 elapsed=.037669325s
=== lean: cerberus-lean --batch node_a.json node_b.json (cabs-json via the fork oracle)
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(48, SD_Id("node")) vs Symbol(19, SD_Id("node"))'"}
rc=1 elapsed=.033639341s
=== pristine upstream oracle (b9aeedcb4 + lem 3802cb0): same flags
rc=124 elapsed=60.105290299s
=== single-TU control (fork oracle / lean)
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
rc=0
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
rc=0
```

So upstream's behaviour on this input is: non-termination here, then (once fixed) the
draft-38 rejection. Both drafts should be filed together.
