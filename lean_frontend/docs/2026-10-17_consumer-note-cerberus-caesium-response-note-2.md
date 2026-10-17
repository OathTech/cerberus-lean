# Response to cerberus-caesium's note 2 (2026-10-17)

Status: RESPONSE NOTE [AGENT], written on the mainline at `f5303eda5` after the operator read the note
(`cerberus-caesium/.tmp/filings/2026-10-17_cerberus-lean-note-2.md`, W3's run of the pinned driver over
cerberus-lean's test suite) and ruled on its items ([USER 2026-10-17]). Items are the note's letters.
Every claim below was checked against this tree; the two live checks (items C and E) were run on
2026-10-17 with the fork oracle `git-cerberus-lean-v0.1.0-alpha.1-156-gf5303eda5` and the Lean engine at
the same commit.

## The common thread

Items A2 to A7, C and D are all places where the Lean engine stops exactly where the OCaml oracle stops.
For every message in A the matching `failwith` or `assert false` is in upstream's own source: the
null-shift TODO (`memory/concrete/impl_mem.ml:2258-2261`), `case_ptrval` (`:1858`), the character-constant
decoder (`ocaml_frontend/decode.ml`, the same message), and the printf, atomics and elaboration TODOs in the
shared Lem model that both engines run. The lanes record them as both-crash rows; the failure-reach
register (`scripts/failure_reach_register.txt`) carries each site with its reach class, and the stop-paths
inventory (`docs/2026-10-08_stop-paths-inventory.md`) maps the whole population. So the panics are the
mirror doctrine at work, not the Lean engine failing where upstream answers.

What the note really lacks is the ability to tell three things apart on the wire: a mirrored upstream
crash, a declared refusal, and a genuine semantics failure. Today all three arrive as exit 134 plus a
LemLib PANIC line and differ only by message prefix. That is question Q-B of the inventory. Its answer, an
outcome protocol (one helper, one message grammar naming the class and the boundary, one exit-code table,
one classifier in the shared codec), was scoped and launched as a design pass on 2026-10-17
([USER 2026-10-17] agreed; design note to follow as `docs/2026-10-17_outcome-protocol-design.md`). Typed
outcomes at pure sites stay with the queued lem failure-monad arc (lem-lean TODO 24).

## Item by item

| Item | Finding | Disposition |
|---|---|---|
| A1 null-pointer shift | Oracle crashes identically (`impl_mem.ml:2258`); upstream-tray draft 04 already reports it | Mirrored; no fork-ahead fix ([USER 2026-10-17]: an unambiguous tool defect but not a wrong answer; the crash is upstream's) |
| A2 `%` by zero | Mirrored, ruled 2026-10-03 (`docs/2026-10-03_total-arith-and-bookkeeping-record.md`) | Note only, as the filing says |
| A3 atomics TODOs | Shared model `failwith`s (register rows 175-179); SC work parked | Known |
| A4 elaboration seams | Shared model `failwith`s both engines run (`break_at_sseq` register row 183, UNKNOWN reach) | Known; an upstream-shaped fix |
| A5 printf and float | Shared model TODOs (register rows 253-256); `truncToInt` mirrors `Z.Overflow`; `formatFixed` is already a declared refusal | Known; the protocol will make the refusal classifiable |
| A6 character constants | Mirrored `failwith` (`decode.ml`) | Known |
| A7 `casePtrval` | Mirrored `failwith` (`impl_mem.ml:1858`) | Known |
| B stack overflow | Known backlog item (TODO, Stack overflow vs fuel, M); the stack-ceiling design (`docs/2026-08-31_stack-ceiling-design.md`) was parked after characterisation; the process stack is the binding bound before fuel | New witness, no new fact |
| C error tests | The claim is partly wrong: the oracle also internal-errors (exit 125, uncaught exception) on all four tests located, verified 2026-10-17 (`tests/ci/0258-array-function-type.error.c`, `tests/ci/0270-invalid-compound-literal.error.c`, `tests/suite/desugaring/20-enum_incomplete.error.c`, `tests/suite/parsing/multiple_decls.fail.c`); the Lean panics mirror them | Mirrored, not Lean-only |
| D memcmp padding | Mirrored `assert false`; already a typed ModelFailure (`CerbMem.lean` `failStopMem`) | Note only |
| E UB088 | Reading confirmed: `translation.lem:4471` emits the undef at the brace unconditionally (the use-dependent form is commented out upstream); both engines report UB088 for a discarded call too (two witnesses, `UB_MATCH`); upstream-tray draft 55 | Mirrored; no fork-ahead fix ([USER 2026-10-17]: a deliberate stricter reading, not an obviously wrong implementation); the comparison's attribution was right |

Not located in this tree: `gcc_torture/breakdown/not_std_compliant/builtins/builtin_types_compatible_p`
(item C); its message (`get_current_return_type`) is a shared-model `failwith` like A4's.

## Follow-ups on this side

- The parse lane (`scripts/test_parse.sh`) classes a `failwithI` panic on an intended-error input as
  INTERNAL_ERROR_EXPECTED only for the `.error.c` suffix; `multiple_decls.fail.c` therefore reads as a
  Lean failure although the oracle internal-errors too. A small lane fix, not in this note.
- The outcome protocol design pass (above).

## Not filed

The note's own "Not filed here" items are agreed: indeterminate sequencing of side effects within one
expression is C11's rule, and the null-pointer-constant printing is RefinedC's frontend.
