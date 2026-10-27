# Consumer note for cerberus-caesium: the anonymous-member refusal (2026-10-26)

From: the `fix/anonymous-members-refusal` worker [AGENT]. Occasion: the upstream-uncertainty
survey of 2026-10-20 (`docs/2026-10-20_upstream-uncertainty-survey-record.md`, cluster A;
upstream-tray draft 60) found that upstream Cerberus splices an anonymous struct/union member's
members flat into the containing aggregate, so layout, aliasing and brace-elided initialisation
are silently wrong on both engines (25 probes; pristine upstream agrees). [USER 2026-10-20] ruled
that anonymous members are refused in the shared Lem and the upstream report filed — the standing
rule being that where upstream left a case under its own TODO/doubt the fork leaves it as-is or
REFUSES LOUDLY and never answers silently wrong; [USER 2026-10-26] dispatched the slice. Contract
entry D12; witnesses `scripts/check_anonymous_members_refusal.sh` (ladder row 1); record
`docs/2026-10-26_anonymous-members-refusal-record.md`.

Status: on branch `fix/anonymous-members-refusal`, implemented and witnessed on both engines,
focused gates green; Tier A and the full battery per the record; the merge is the orchestrator's.
The behaviour below is what the next re-pin that includes the branch carries.

## What now refuses

A struct-declaration with NO declarator whose type specifier is a tagless struct or union — an
anonymous member, C17 6.7.2.1#13 — anywhere an aggregate is declared:

```c
struct S { int a; union { int b; char c; }; int d; };          /* refuses */
struct T { char a; struct { char b; int c; }; };               /* refuses */
union  U { int x; struct { short lo, hi; }; };                 /* refuses (anonymous struct inside a union) */
struct N { struct { union { int a; char b; }; int c; }; };     /* refuses at the innermost anonymous member */
typedef struct { int a; } A; struct V { A; };                  /* refuses: a typedef'd TAGLESS specifier used bare */
int f(void) { struct L { union { int a; char b; }; int c; } l; /* refuses: block scope */ … }
```

The refusal fires when the containing aggregate's declaration is desugared — whether or not the
type is ever used (an `extern` declaration or a `sizeof` suffices), in any scope, inside a
compound literal's type name too. Nested anonymous members refuse at the innermost one, which
names the kind word in the text.

Upstream's `desugar_struct_declaration` (`frontend/model/cabs_to_ail.lem`; pristine b9aeedcb4
:2697) answered this arm with the anonymous member's member list, i.e. `struct S { union { int b;
char c; }; int d; }` desugared to `struct S { int b; char c; int d; }` (the oracle's own
`--pp=ail` shows it). The anonymous member lost its own storage: `sizeof(struct S)` 12 where gcc
has 8, no aliasing between `b` and `c`, the brace-elided `{1, 2}` putting the 2 into `c` and
leaving `d` 0 (on the survey's an-01 shape, `int a` first, `{1, 2, 3}` puts the 3 into `c`), and false
UB081/UB036/pointer-equality verdicts on valid programs. Designated
initializers naming the members (`{ .d = 3, .b = 2, .a = 1 }`) were the one shape that answered
right, by name lookup alone — which is why kernel-style code hid the problem until a `sizeof`, an
alias or an elided initializer was reached.

Now the SHARED desugarer's arm is a Lem `error`, so the text is one string by generation
(`Cerb_debug.error` in the oracle, `failwithI` in Lean); the kind word comes from the member's
own type (`struct` or `union`):

```text
Cabs_to_ail.desugar_struct_declaration: refused - anonymous union member (a struct-declaration with no declarator whose type specifier is a tagless union; C17 6.7.2.1#13); upstream splices its members into the containing aggregate's member list ('STD 6.7.2.1#13 ... E.return membrs' b9aeedcb4 :2697, under its own 'this may be WRONG ==> anonymous Struct/Union' :144/:166/:194/:3244), which changes layout, aliasing and initialisation (wrong sizeof and offsets, no aliasing between an anonymous union's members, brace-elided initializers one slot late, false UB verdicts) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)
```

(for an anonymous struct: `... refused - anonymous struct member (a struct-declaration with no
declarator whose type specifier is a tagless struct; C17 6.7.2.1#13); ...`, the rest identical.)

On the wire — the same shape as D11, the union-initializer refusal:

- the oracle prints `internal error: <text>` on stderr and dies on the uncaught exception
  `Failure("internal error: <text>")` with an OCaml backtrace, **exit 125**; in `--batch` no
  verdict line is printed;
- the Lean engine aborts under `LEAN_ABORT_ON_PANIC=1` with
  `PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: <text>` on stderr, **exit 134**
  (`--batch` prints nothing else; without the abort flag the driver refuses to start, exit 2).
- `--cabs-json` succeeds: the refusal is in the desugarer, after Cabs, so a consumer that imports
  Cabs JSON and runs the Lean pipeline sees the panic at `desugar`, before typing and execution.

**Stop class under the outcome protocol** (`docs/2026-10-20_consumer-note-cerberus-caesium-outcome-protocol.md`):
a LEGACY stop, origin unattributed — NOT a frontend-refusal `Error` record and NOT a migrated
`CerbStop` `REFUSAL`. The validated panic frame decodes as legacy/unattributed, exactly as the
D11 union-initializer stop and the D10 memory-model refusals do; the migration map
(`docs/2026-10-20_outcome-protocol-register-migration.tsv`) lists the site as UNMIGRATED under
the same shared-desugarer mapping mover (structural-outcome WP2). Why not the frontend-refusal
record shape (`E.fail loc (Desugar_NotYetSupported …)`, the VLA/asm form, exit 1): measured on
the port, that form's `--batch` record is only `Error {msg: "desugaring failed at <loc>"}` — the
reason text is not carried, so the two engines would not render the refusal identically and the
Lean side would be unattributed; the lanes also class an exit-1 oracle as `CERB_SKIP`, not a
matched refusal. The `error` form carries the full attributed text on both engines byte for
byte [AGENT 2026-10-26].

Lean site: the generated `Cabs_to_ail.desugar_struct_declaration` /
`Cabs_to_ail.anonymous_member_refusal` (`lean_frontend/generated/Cabs_to_ail.lean`); oracle site:
the generated `ocaml_frontend/generated/cabs_to_ail.ml`, both from the one `.lem`. No
hand-written seam changed; no proof module changed.

## What does not change

Agreeing with the oracle, witnessed as controls: the same programs with NAMED members —
`struct S { int a; union { int b; char c; } u; int d; }` elided or braced (321), `sizeof` (4),
aliasing through `s.u` (4), a named single-member union, a named struct inside a struct (`struct
{ int b, c; } u;`), a union with named members only used as a named struct member, a plain union,
a tagless TYPE with a declarator (`struct { int x; } named;`) and a tagless file-scope union
object (`union { int a; char b; } g;`, `tests/ci/0308`'s shape). Already-noisy upstream
rejections stay as they were, exit 1 on both engines: a TAGGED struct without a declarator inside
a struct (`struct T { int x; };`), a typedef'd TAGGED specifier used bare, and `int;` — all
`constraint violation: non-anonymous struct/union must contain a declarator list` (6.7.2.1#2) on
the oracle, `Error {msg: "desugaring failed at …"}` on Lean.

## Retired control; kernel reach

- `tests/coverage/struct/struct-008-anon-struct.c` (Tier A row 3, baseline MATCH 12: an anonymous
  struct's members read by name) is RETIRED with its baseline row — the item-G/union3-003
  precedent: a MATCH on a case the fork now refuses is not evidence; its shape is a witness of
  `scripts/check_anonymous_members_refusal.sh`. The union-initializer script's anonymous-union
  control (`struct S { int k; union { int i; unsigned char c[4]; }; } s = { .c = {1,2,3,4}, .k =
  7 }`, 74 on both engines before, `s.i` silently 0 where gcc reads 1 — the carve-out D11's
  SUPPORTED sentence used to name) is retired likewise; that gap is closed by this refusal.
- **Kernel-reach warning, which is the point:** every `union { … };` and `struct { … };` inside a
  struct — `struct page`, `sk_buff`, the pKVM-style "`union { struct { … }; … };`" idiom — now
  refuses in both engines, before typing. A consumer whose C uses the idiom gets the stop above at
  the aggregate's declaration, not a wrong `sizeof` or a false UB verdict. Rewriting the member as
  a NAMED one (`union { … } u;` and `s.u.b`) is the only way through until upstream implements the
  feature (tray 60's "Expected"); the fork does not implement it.

## Measurement (what moved)

Every corpus the lanes walk was run on the new oracle (5567 non-csmith files including the libc
sources, the CN and pKVM sources; 1669 csmith programs through the lane's materialization): exactly
five programs refuse — the retired `struct-008`, the parity-detective probe
`tests/parity-probes/probes/anon_struct_union.c` (not a gate), and three ci-sweep scoreboard rows
(no baseline): `gcc-torture/execute/anon-1.c` with its `breakdown/success` copy, and
`suite/desugaring/13-non_anonymous_empty_sdecltors.error.c`, whose first line `struct T1 {
struct{int x;}; };` is itself an anonymous member (its class moves from `CERB_REJECT` to the
refusal at the scoreboard's next deliberate re-record). The libc desugars unchanged (`libc.co`
restaged); csmith 0.
