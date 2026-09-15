# `PEmemberof(struct)` rejects a struct VALUE that crossed a translation-unit boundary: "mismatched tags" for two compatible definitions of the same struct (exact tag identity where STD §6.2.7#1 compatibility is what the program relies on)

**Affected:** `frontend/model/core_eval.lem:945-946` (the `PEmemberof(struct)` arm of
`eval_pexpr`; `:954-955` is the union twin): the member selection compares the ctype's
tag `tag_sym` with the value's tag `tag_sym'` by symbol equality and fails with
`Illformed_program "PEmemberof(struct) ==> mismatched tags: …"` when they differ.
A struct value produced in one translation unit carries THAT unit's tag symbol; the
same struct defined in a second unit has a different symbol. Reached whenever a struct
value returned (or otherwise passed by value) across TUs is member-selected. Checked
against `master` @ `b9aeedcb4`: the cited `.lem` lines are the merge-base's.

## Description

Two translation units each define `struct node { int v; struct node *next; }`; a
function in TU 1 returns a `struct node` by value; TU 2 selects `.v` on the result.
Strictly conforming C: the two definitions are compatible (C11 §6.2.7#1) and the
program's value is 7. Cerberus's Core evaluator identifies struct types by TAG SYMBOL
at member selection, so the value tagged by TU 1's `node` is rejected under TU 2's
`node` type. (Upstream does not reach this check today: it first recurses forever in
`Ctype_aux.are_compatible` on the same input — draft 37. The fork fixed that; this is
the next failure on the same reproducer.)

## Reproducer

`tests/failure-probes/cross_tu_node/node_a.c` + `node_b.c` (draft 37's; two TUs, the
struct defined in both, a `struct node` value returned across the boundary and
member-selected):

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
$ cerberus --nolibc --exec --batch --mode=exhaustive node_a.c node_b.c      # fork, are_compatible fixed
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(531, SD_Id("node")) vs Symbol(502, SD_Id("node"))'"}
rc=1
$ cerberus-lean --batch node_a.json node_b.json                              # the fork's Lean port, same
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(48, SD_Id("node")) vs Symbol(19, SD_Id("node"))'"}
rc=1
$ <pristine upstream b9aeedcb4>  ... node_a.c node_b.c                       # never gets here
rc=124 (60 s)
```

(verbatim, 2026-09-10; gcc: exit 7; the single-TU control `node_single_control.c`
gives `Specified(7)` on both fork engines.)

## Observed vs expected

Observed: `Illformed_program`, exit 1, for a strictly conforming program (on the fork;
non-termination on upstream). Expected: `Specified(7)`.

## Impact

Any program that passes a struct by value across translation units and then selects a
member of it. Multi-TU struct-by-pointer programs are unaffected (pointer member
selection goes through the memory model's tag lookup, not this arm); struct-by-value
across TUs is the exposed shape.

## Proposed remedy

At `PEmemberof`, accept the value when its tag is COMPATIBLE with the type's tag
(`Ctype_aux.are_compatible` on the two `Struct` ctypes — the check `memValueFromValue`
already performs when storing such a value, core_aux.lem:200), or retag struct values
at the TU boundary (call return / by-value argument) to the receiving TU's definition.
The former is the smaller change and keeps the single point of truth for compatibility.

## Classification

**TRUE BUG / LIMITATION** of multi-TU support (strictly conforming input rejected as
ill-formed). Not a modelling choice: the standard makes the two definitions compatible
and the interpreter already has the compatibility check; it is simply not consulted at
member selection.

## Provenance

Exposed by the fork's fix of draft 37 (are-compatible-assumed-set slice, record
`lean_frontend/docs/2026-09-10_are-compatible-assumed-set-record.md`): once
`are_compatible` terminates on the reproducer, this guard is the next thing it hits.
First observed by the Codex agent executing that slice (its D1 stop, recorded there),
localised and drafted by Claude (Fable 5.1) under operator direction; the filed issue
carries an AI-provenance note per the tray's policy. File together with 37.

## Fork status (2026-09-15) — FIXED in the fork; the patch is the `.lem` diff

[AGENT 2026-09-15] Landed on `arc/semantics-audit-repairs` at `dbe633ec5` (record
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md` §D3; charter
`…/2026-09-11_codex-charter-semantics-audit-repairs.md` D3), together with draft 39's
one-token fix of `Ctype_aux.are_compatible_aux`: the remedy's FIRST form — member
selection consults the compatibility predicate the store side already consults
(`memValueFromValue`, core_aux.lem:200), and only when the tags differ (equal tags never
reach it; single-TU programs pay nothing). The patch for upstream is this hunk of
`frontend/model/core_eval.lem` (the 10-line comment block above it is fork-side
provenance):

```
           | Just (Vobject (OVstruct tag_sym' xs)) ->
-              if tag_sym <> tag_sym' then
+              if tag_sym <> tag_sym' && not (Ctype_aux.are_compatible
+                                               (Ctype.no_qualifiers, Ctype.Ctype [] (Ctype.Struct tag_sym))
+                                               (Ctype.no_qualifiers, Ctype.Ctype [] (Ctype.Struct tag_sym'))) then
                 EU.fail $ Illformed_program ("PEmemberof(struct) ==> mismatched tags: " ^ show tag_sym ^ " vs " ^ show tag_sym')
```

The union arm (`:952-953`) is NOT changed — the "union twin" (`lean_frontend/TODO.md`,
"Semantics-audit repairs"): a `union U` value crossing TUs would still be rejected by exact
tag identity there and in `memValueFromValue`'s union arm (core_aux.lem:204-208).

Verbatim runs on the reproducer (its program is now the corpus case
`tests/multi_tu_tray/node/`, LADDER Tier A row 6b; fork oracle bin `e40ae8e3…` at the D3
head, Lean `e36af96d…`, pristine upstream `b9aeedcb4` = the independent-oracle-v2 build;
2026-09-15):

```
=== fork oracle: cerberus --nolibc --exec --batch --mode=exhaustive tu1.c tu2.c
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
rc=0
=== Lean: cerberus-lean --batch tu1.json tu2.json (cabs-json via the fork oracle)
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
rc=0
=== pristine upstream: same flags
rc=124 (60 s; draft 37's non-termination)
=== gcc -std=c11 -O0 -w
gcc exit=7
```

The compatible twins with array members (`tests/multi_tu_tray/arr-2-2-return`,
`arr-incomplete-ptr-return`) likewise run to `Specified(7)` on both fork engines, and
pristine upstream rejects them at this guard (`Error {msg: "ill-formed program:
\`PEmemberof(struct) ==> mismatched tags: Symbol(558, SD_Id("S")) vs Symbol(502, …"}` rc 1;
`Symbol(536, …)` for the incomplete-pointer twin) — the guard is reached there because
`are_compatible` terminates on non-recursive structs. The INCOMPATIBLE twin
`arr-1-2-return` (`int a[1]` vs `int a[2]`) is rejected by the fixed fork with the same
message — now for the right reason (draft 39). Results on every single-TU program are
unchanged; the fork's Tier A/B corpora moved nowhere (record §D3).
