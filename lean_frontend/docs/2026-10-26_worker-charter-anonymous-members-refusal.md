# Worker charter: refuse anonymous struct/union members (survey cluster A) — 2026-10-26

Branch `fix/anonymous-members-refusal`, worktree
`worktrees/cerberus-lean-fix/anonymous-members-refusal`, based on mainline `704c4e697`
(Lean 4.35.0, lem `e6d8db5`). Worker: a Fable subagent. Status: ACTIVE from dispatch.
A second slice (`feature/quotation-hygiene`) runs in parallel: see "Box rules".

## Why and what was decided

- The upstream-uncertainty survey (`lean_frontend/docs/2026-10-20_upstream-uncertainty-
  survey-record.md`, §2.1 cluster A; tray draft
  `docs/upstream-tray/60-anonymous-members-spliced-into-containing-aggregate.md`): upstream
  Cerberus splices an anonymous struct/union member's members into the containing
  aggregate (`frontend/model/cabs_to_ail.lem:2709-2719`, `desugar_struct_declaration`: a
  struct-declaration with no declarators whose type is an anonymous struct/union
  specifier returns `membrs`). Consequences, measured on both engines and reproduced on
  pristine upstream: wrong `sizeof` and offsets, no aliasing between an anonymous union's
  members, brace-elided initializers after an anonymous union one slot late, false UB
  verdicts (25 silent-wrong probes). Kernel-style C uses this everywhere.
- [USER 2026-10-20] refuse in the shared Lem and file upstream; no silently wrong
  answer is tolerated; upstream's judgement stands (this is a TODO-marked doubt upstream
  itself prints: "this may be WRONG ==> anonymous"), so the fork REFUSES rather than
  implements the feature. [USER 2026-10-26] run now, in parallel with quotation hygiene.
- Precedents to follow: item G (`lean_frontend/docs/2026-10-20_item-g-refusals-record.md`)
  and the union-initializer refusal (`2026-10-20_union-init-refusal-record.md`, its review
  `2026-10-21_union-init-premerge-review.md`): one shared-Lem stop, both engines by
  generation, a witness script with plants wired into row 1, a contract entry, the
  manifest re-pin, the retirement of gated controls of the superseded stance with their
  baseline rows, a tray update, a consumer note, a record.

Read first: the container `CLAUDE.md`, `lean_frontend/CLAUDE.md`, the survey record §2.1
and §3 slice 1, tray 60, the two precedent records and the union-initializer review, the
probes under `tests/parity-probes/uncertainty/A-anonymous-members/` (the survey's 25+
programs with their gcc/engine results), and `frontend/model/cabs_to_ail.lem:2700-2730`.

## Deliverables (commit per checkpoint on green focused checks; Tier A at each commit;
## the full battery at close-out)

### M1 — the refusal in the shared Lem
- Predicate: in `desugar_struct_declaration`, the arm `List.null sdecltors` with
  `get_anonymous_struct_or_union base_ty = Just membrs` (C17 6.7.2.1#13: an anonymous
  member). Replace the splice with a declared refusal. Choose the stop form deliberately
  and say why in the record: (a) a frontend refusal `E.fail loc (Errors.Desugar_NotYetSupported
  "anonymous struct/union member (C17 6.7.2.1#13): upstream splices its members into
  the containing aggregate, which changes layout, aliasing and initialisation; refused
  rather than decided")` — surfaces as the oracle's "feature not yet supported" error and
  the port's `Error` record, both loud and attributed, like VLAs; or (b) `error` (an
  internal-error stop, exit 125 / panic 134, the union-initializer form). Prefer (a) if
  both engines render it identically in batch and the lanes classify it as a matched
  frontend refusal; otherwise (b). Both engines come from the one Lem text: no mirror.
- Check that the refusal cannot be bypassed: a named-tag anonymous member
  (`struct { int a; } ;` with a tag but no declarator), nested anonymous members, an
  anonymous member in a union, typedef'd anonymous specifiers — probe each.
- The generated-OCaml delta is in `cabs_to_ail.ml` (layer 2): re-pin its
  `[expected-semantic]` row and `cabs_to_ail.lem`'s `[source-content]` row with a dated
  NOTE, never `--refresh`.

### M2 — witnesses and gates
- `scripts/check_anonymous_members_refusal.sh`, wired into row 1: refusal witnesses from
  the survey (at least an-01, un-06, au-02, au-08, ax-01, ac-01 and one nested case),
  controls that must still answer (named unions un-01/un-02, au-05/au-06, a named
  struct inside a struct, a union with named members only), byte-identical texts on both
  engines (or the identical Error record), exit codes pinned, five plants in the item-G
  shape (answer, lean-answer, refuse-all, lean-other-text, no-abort).
- The gated row that moves: `tests/coverage/struct/struct-008-anon-struct.c` (Tier A row
  3, baseline MATCH: the shape that happens to work by designated initialisation). Retire
  it with its baseline row, as the item-G controls and union3-003 were ([USER 2026-10-20]
  precedent: a MATCH on a case the fork now refuses is not evidence), and keep its shape
  as a refusal witness. Measure every other gated corpus for anonymous members before
  committing (the survey's reach figures: `tests/gcc-torture/execute/anon-1.c` and its
  breakdown copy in the Tier B/C pristine lanes, the parity probe, a `.error.c` suite row)
  and register every row that moves in the pristine-oracle lanes exactly (the
  inner_arg_temps B10.1 precedent), never blindly. Any OTHER baseline movement is a park.
- Also update the union-initializer SUPPORTED carve-out sentence: the anonymous-union gap
  it names is now a refusal.

### M3 — docs, record, consumer note, tray
- CONTRACT.md entry D12 (the refusal, its predicate, the precedent chain); VALIDATION.md
  §3 and the inventory/gate table; SUPPORTED.md Domain row; LADDER row 1; tray 60 updated
  ("the fork REFUSES since 2026-10-26; the report stands"); INDEX row; consumer note for
  cerberus-caesium (`docs/2026-10-26_consumer-note-cerberus-caesium-anonymous-members-
  refusal.md`: what refuses, the exact texts, the exit codes, the stop class under the
  outcome protocol — a frontend refusal `Error` record or a legacy stop, say which —, the
  retired control, kernel-reach warning: every `union { … };` inside a struct now refuses,
  which is the point); the record
  `lean_frontend/docs/2026-10-26_anonymous-members-refusal-record.md` with every gate
  verbatim. TODO.md: close the queued entry.

### Close-out
Tier A; the full battery; no proof module changes expected (if one does, kernel replay).

## STOP conditions (a committed park record, then wait)
The splice site is not where the survey says; the refusal would move any gated row other
than struct-008 and the pristine-lane rows named above; the two engines do not render the
refusal identically; any premise of this charter turns out wrong.

## Box rules and practices
Another worker (`feature/quotation-hygiene`) runs in parallel. Before any Tier A or
battery: `uptime` 1-minute load below 8 AND no other `release.py` running (check
`ps -u dev -o args | grep -c '[r]elease.py'` is 0); otherwise wait and retry every two
minutes. Capped builds may overlap. Every lake/lean call through `scripts/capped`.
One coherent commit per checkpoint; provenance tags ([USER …] only for the operator's
rulings; relayed orchestrator text `[AGENT …, relayed by the operator]`); never quote
the operator; never `pgrep -f`/`pkill`; no push.
