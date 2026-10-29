# Worker charter: compound assignment with a side-effecting left operand refuses (survey cluster B, tray 61)

Date 2026-10-29. Orchestrator [AGENT]. Branch `fix/compound-assignment-refusal`, worktree
`worktrees/cerberus-lean-fix/compound-assignment-refusal`, base = mainline `mdd/cerberus-lean` `b4a48f635`
(Lean 4.35.0, lem `e6d8db5`).

## Provenance

- [USER 2026-10-20] ruled, for the upstream-uncertainty survey's cluster B (record
  `docs/2026-10-20_upstream-uncertainty-survey-record.md` §2.2, slice shape §3 "Slice 2"): refuse when the left
  operand of a compound assignment has a side effect, and file the one-binding elaboration upstream (tray 61,
  `docs/upstream-tray/61-compound-assignment-duplicates-left-operand.md`). The standing rule applies: upstream's
  judgement stands; a case upstream left under its own TODO is refused loudly, never answered silently wrong.
- [USER 2026-10-29] dispatched this slice, with the ride-alongs in M3.
- Precedents to mirror: the anonymous-members refusal (contract D12, record
  `docs/2026-10-26_anonymous-members-refusal-record.md`, witness `scripts/check_anonymous_members_refusal.sh`) and
  the union-initializer refusal (D11). Read both records first; they fix the shape of the witness script, the
  manifest re-pin, the moved-row disposition and the documentation set.

## The defect

`frontend/model/translation.lem:2505-2531`, `| A.AilEcompoundAssign e1 aop e2 ->` under upstream's own
`(* TODO: this elaboration is wrong because it duplicates any side-effect in E1 *)`: the arm rewrites `e1 op= e2`
to `AilEassign e1 (AilEbinary (AilErvalue e1) aop e2)`, so `e1` is elaborated twice. With an increment, a call or a
comma in the lvalue the second copy is a second side effect: `a[g()] += 4` calls `g` twice (survey probe
`cb-02-lhs-call-index`, both engines answer 24 where gcc gives 14); `a[i++] += 5` is reported as UB035 (false:
C17 6.5.16#3 sequences the update after both value computations, 6.5.16.2#3 says E1 is evaluated once). Pristine
upstream `b9aeedcb4` answers the same. Probes: `tests/parity-probes/uncertainty/B-compound-assignment/` (14 files,
classifications in the survey table).

## M1: the refusal in the shared Lem (both engines by generation)

- A syntactic predicate on `e1` (the survey's §3 "Slice 2" names the constructors: the four `AilEunary`
  increment/decrement forms, `AilEassign`, `AilEcompoundAssign`, `AilEbinary _ Comma _`, and every `AilEcall`,
  anywhere inside `e1`, including inside subscripts, member accesses, derefs and casts). A call is a side effect by
  construction (the second elaborated copy runs it again), so `ca-04-call-lvalue` becomes a refusal even though its
  call is pure: that is the intended over-approximation ("refuse until it hurts"); record it. Decide and record
  whether a `volatile`-qualified lvalue read counts (measure what the two elaborated copies actually do with a
  volatile object before deciding; be slow to call it obvious).
- The refusal mechanism is the arm's own precedent, `E.record_error_at loc "…"` (the GNU `?:` arm at
  `translation.lem:2318-2321`; `translation_effect.lem:250-257`). MEASURE its batch rendering on both engines
  before writing a line of documentation. The orchestrator's measurement on the landed mainline for the `?:`
  precedent: the oracle prints `unsupported: <file>:<line>:<col>:: <text>` on stderr and then an
  `internal error: …` line, exit 125; the Lean engine panics (exit 134 under the harness's abort flag);
  `scripts/test_exec.sh` classes the row `CERB_SKIP` and runs no comparison. So this is the legacy crash-shaped
  stop form, as D11/D12, not a D9-style exit-1 refusal: say so plainly everywhere the stop form is described, and
  check how `scripts/observations.py` classifies the `unsupported:` stderr line (a plain stderr line is an
  "unrecognized diagnostic" problem in the PNVI and immaculate lanes unless admitted; find how the `?:` rows are
  handled today and do the same, with a plant). If measurement shows the mechanism cannot carry an attributed text
  on both engines identically, PARK with the measurement rather than improvising a different mechanism.
- One text, byte-identical on both engines after the location prefix: it names the construct (compound assignment
  whose left operand contains a side effect), the standard (C17 6.5.16#3, 6.5.16.2#3), upstream's TODO
  (`translation.lem:2506` at `b9aeedcb4`), what goes wrong (the lvalue's side effect runs twice; a false UB035),
  and the rationale (the fork refuses rather than decides; survey cluster B, tray 61, 2026-10-29).
- Manifest: single-row edits of exactly the `translation` rows (`[source-content]` `translation.lem`,
  `[expected-semantic]` `translation.ml`) with a dated NOTE; never `--refresh`. Regenerate both trees and confirm
  the generated delta is the arm only.

## M2: witnesses, moved rows

- `scripts/check_compound_assignment_refusal.sh` in ladder row 1, the D12 script's shape: refusals (the survey's
  side-effecting probes `ca-02, ca-03, ca-05, ca-06, cb-02, cb-03, cb-04, cb-08` and `ca-04`, plus your own shapes:
  pre-increment, a call nested two levels deep, a comma in a member's subscript, a compound literal lvalue, an
  assignment in a cast's operand, each `op=` operator at least once), controls that must NOT refuse (`ca-01, cb-01,
  cb-06, cb-07`, plain `a[i] += 1`, `*p += 1`, `s.v |= 4`, `a[f] <<= 2` with `f` a variable, a side effect only in
  `e2`), the pre-existing rejection `cb-05-bitfield-postinc` unchanged; whole texts pinned including the location;
  both engines agree; plants that make every count go loud.
- Measure every gated corpus for moved rows before and after (Tier A row 3 coverage, the Tier B rows, the csmith
  corpus and the ci-sweep scoreboard; the D12 record §3 lists the sweep). The survey expects 0 gated rows to
  move; verify it. A gated program that now refuses is retired with its baseline row per the D12 precedent; a
  scoreboard-only row is named in TODO for the next deliberate re-record. Pristine-lane registrations only if a
  row genuinely moves there.

## M3: documentation and the ride-alongs

- CONTRACT: entry D13 next to D11/D12 (the legacy stop form stated plainly, the batch-rendering follow-up option
  cross-referenced); the migration map `docs/2026-10-20_outcome-protocol-register-migration.tsv` gains the
  UNMIGRATED line for the new site and its summary line counts it; VALIDATION's witness table; SUPPORTED;
  LADDER row 1; tray 61 updated to "refused in the fork since 2026-10-29" with the INDEX line; consumer note for
  cerberus-caesium (`docs/2026-10-29_consumer-note-cerberus-caesium-compound-assignment-refusal.md`, the D12
  note's shape); TODO: this item marked DONE; the `_Bool`-from-fractional-float item marked DONE (upstream
  `3230aa494` was backported by the inner_arg_temps landing with CI witness 0343, see
  `docs/2026-10-21_codex-charter-inner-arg-temps.md` and the IAT record); the survey section's header no longer
  says the items are queued behind the caesium deliveries (all three have landed).
- Ride-along (a), [USER 2026-10-20], [USER 2026-10-29] dispatched here: the float profile documentation, no code
  (survey §2.4, tray 32): SUPPORTED.md and CONTRACT D6 state `sizeof(float) == sizeof(double) ==
  sizeof(long double) == 8`, all binary64, `_Alignof(long double) == 8`; tray 32 gains the `float.h`
  contradiction (`FLT_MANT_DIG 24` / `LDBL_MANT_DIG 64` against 53-bit values, `FLT_EPSILON` absent). The shipped
  `runtime/libc/include/float.h` is NOT edited. Measure what you state (probe both engines).
- Ride-along (b), one line: `docs/2026-10-26_anonymous-members-refusal-record.md` §8 says the 15-minute battery
  waiter was presumably reaped. It was not: it stayed alive for 26 hours, blocked, because its running-battery
  check counted any shell whose command text contained the runner's name (its own wrapper, the other slice's gate
  shells, later the orchestrator's runs), and it was killed on 2026-10-28. Correct the note, tagged
  [AGENT 2026-10-28, orchestrator].
- Record `docs/2026-10-29_compound-assignment-refusal-record.md`: measurements verbatim, the predicate and its
  over-approximations, the stop-form measurement, moved rows, the gates' last lines, dispositions.

## Gates and process (the part that changed after the last two slices)

- You run the focused gates yourself: the witness with its selftest and plants, `check_fork_drift.sh` with
  `--selftest`, `check_failure_reach.sh`, `check_pin_sites.sh`, `test_stops.py`, the stop-policy plants, the
  one-file differentials, the corpus measurements. Quote last lines verbatim.
- You do NOT run `release.py` (no Tier A, no full battery) and you start NO poller, waiter, gate script or sleep
  loop of any kind. When a milestone is ready, commit it and report to the orchestrator; the orchestrator runs
  Tier A and the full battery, keeps the evidence, and sends you the verbatim lines for the record. Tree edits
  never happen while an orchestrator run is in flight; the orchestrator tells you when a run starts and ends.
- Any run of yours longer than a few minutes goes through the harness's background execution, nothing else.
- One coherent commit per milestone, message stating what was verified; never on a mainline; nothing pushed.
- Kernel replay is owed only if a proof module changes (none is expected).
- Never `pgrep -f`/`pkill`; kill only PIDs you started after checking them. No network. `/tmp` is unreadable:
  scratch under the worktree's `.tmp/`, deleted at slice end. Never quote the operator; provenance tags on every
  decision ([USER]/[AGENT] with dates); machine outputs verbatim, derived tallies labelled derived.
- A blocker you cannot resolve within the charter is a committed PARK record (`docs/2026-10-29_compound-assignment-park.md`)
  and a stop; a committed park ends the slice.
- Report format at the end: commit hashes with one line each, `git diff --stat b4a48f635..HEAD`, every gate's last
  lines verbatim, the moved rows, the refusal texts, what could not be done.
