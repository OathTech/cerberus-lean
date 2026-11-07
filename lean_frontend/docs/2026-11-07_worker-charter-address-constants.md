# Worker charter: the constant-expression predicates accept every §6.6 form the standard lists (tray 09, 28, 29; audit §4 items 7, 16, 17)

Date 2026-11-07. Orchestrator [AGENT]. Branch `fix/address-constants`, worktree
`worktrees/cerberus-lean-fix/address-constants`, base = mainline `mdd/cerberus-lean` `1e5f2cbca`
(merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`). One of three slices running in parallel (the
others: the formatter's refusals in `formatted.lem`; the oracle half-mirrors in `decode.ml`/`impl_mem.ml`):
touch nothing outside this slice's mechanism (`frontend/model/cabs_to_ail.lem`'s constant-expression predicates,
their witnesses, pins and documents), and keep every shared-document edit (CONTRACT, VALIDATION, LADDER, TODO,
the manifest NOTE, the migration map, the register, the tray INDEX) an appended entry in a section named for
this slice, so the orchestrator's rebase onto the other landings stays mechanical.

## Provenance

- Tray drafts `docs/upstream-tray/09-address-constant-member-rejected.md`, `28-conditional-in-static-initializer.md`,
  `29-string-literal-address-constant.md` (all TRUE BUG, over-strict rejections of conforming programs); the
  true-bug audit of 2026-11-04 (`/home/dev/projects/cerberus-lean-proj/.tmp/truebug-audit/2026-11-04_true-bug-audit.md`,
  read-only: rows 09, 28, 29 and §4 items 7, 16, 17 with Appendix B's `probes/D/ac_*.c` and `ce_*.c`).
- [USER 2026-11-04] the fix pass in the audited order; the bar: a fork fix only where the standard is very clear
  or a consumer is blocked, no invented semantics; the vicinity rule. [USER 2026-11-07] dispatched in parallel.
- Precedents: the compound-assignment and rank records for the slice shape; the `_Alignas` mirror record
  (`docs/2026-10-03_mirror-upstream-d38-alignas-record.md`) for a desugarer predicate change.

## The defects (at the base; both engines by generation; pristine the same; gcc 13 the referee)

The desugarer decides whether an initializer is a constant expression with three predicates in
`frontend/model/cabs_to_ail.lem`: `is_lvalue_to_static_object` (tip `:925-964`), `is_address_constant`
(`:966-1000`), `is_arithmetic_constant_expression`. Each lacks arms the standard's §6.6 explicitly permits, so
conforming static initializers are rejected with `constraint violation: initializer element is not a compile-time
constant` (the Lean engine: `desugaring failed at …`):
- `&arr[i].field` (09): `AilEmemberof e _` recurses into `e = AilEunary Indirection (g_arr + 1)` and there is no
  `Indirection` arm (6.6#9: an address constant may be created by the unary `&`, by array-subscripting, member
  access and indirection applied to an object of static storage duration).
- `cond ? a : b` in a static initializer (28): `is_arithmetic_constant_expression` has no `AilEcond` arm (6.6#3,
  #6); `_Generic(…)` likewise rejected (audit §4 item 17; 6.6 does not forbid a generic selection).
- `"hello" + 1` (29): `is_address_constant` has no `AilEstr` arm (6.6#9: a string literal is an lvalue of static
  storage duration; upstream `6b65dc04f` added `AilEstr -> true` to `is_lvalue_to_static_object` only).
- The audit's six sibling forms (§4 item 7): `(char *)&g`, `1 ? &a : &b`, `&g.a[2]`, `g.a` (an array that
  decays to a pointer constant), `g.a + 1`, `(char *)&g + 4` (today a UB055 verdict on a valid program).
- The reverse defect (audit §4 item 16): a comma operator in a static initializer is ACCEPTED (both engines
  answer; gcc rejects): 6.6#3 forbids the comma operator in a constant expression except inside an unevaluated
  operand. Fail-open on a constraint violation; the fix is the diagnostic gcc gives.

## M1: the predicates (shared Lem, both engines by generation)

- Extend the three predicates with exactly the forms 6.6#3-#9 list, and nothing else: unary `&` of an lvalue to
  a static object through any chain of `[]`, `.`, `->`, `*` and casts to pointer type (6.6#9); the
  array-to-pointer decay of a static array (6.3.2.1#3 with 6.6#9); a string literal as a static object; `?:`
  and `_Generic` with constant operands (6.6#3); pointer constant ± integer constant (6.6#9, 6.5.6); and the
  comma operator REJECTED as the constraint violation (6.6#3), with upstream's diagnostic text shape. Every arm
  carries its clause in a comment. Where a form's status under 6.6 is a judgement call (6.6#10: an
  implementation may accept other forms of constant expressions), do NOT accept it: leave upstream's rejection and
  record the question in the record and the filing.
- The predicate must not accept what the standard rejects: measure gcc's `-pedantic-errors` verdicts for every
  witness and pin them; a form gcc accepts under 6.6#10 only is not a model for the fork.
- The usual mechanics: regeneration, both engines rebuilt, the generated delta confined to `Cabs_to_ail`
  (both targets read), the manifest's `cabs_to_ail` rows single-row edited with a dated NOTE (never
  `--refresh`), the failure-reach register and stop sites as the gates decide, fuel forms unchanged unless a
  measured worker changes (a proof change means kernel replay; the desugarer's workers are fuel'd: check which
  predicate is a fuel'd worker and whether its measure is affected).

## M2: the vicinity, the witnesses, the moved rows

- Probe the whole §6.6 table on both engines, pristine and gcc (`-std=c11 -pedantic-errors`): integer constant
  expressions (every operator, casts, `sizeof`, `_Alignof`, enumerators, character constants, floating constants
  cast to integer, `_Generic`, `?:`, the forbidden operators: assignment, increment, function call, comma;
  unevaluated operands of `sizeof` containing them), arithmetic constant expressions, address constants (every
  chain shape above, null pointer constants, function designators, string literals, compound literals of static
  duration (6.6#9 "address constant for an object type" — the compound-literal case is a judgement area: record
  it), casts between pointer types, integer-to-pointer casts (an implementation choice: record), plus the
  initializer contexts: `static` locals, file-scope objects, array bounds, `case` labels, enumerators, bit-field
  widths, `_Static_assert`. Every sibling wrong on conforming input (rejected or accepted against the standard)
  is fixed if the standard is clear, otherwise refused or filed.
- Witness script `scripts/check_address_constants.sh` in ladder row 1 (the rank script's shape: nolibc, both
  engines' batch lines pinned to gcc's values on the accepted forms, the rejections pinned as both engines'
  diagnostics with gcc's rejection beside, pristine the negative control, plants, the total pinned).
- Measure every gated corpus for moved rows (the coverage/ci/csmith/gcc-torture corpora have many static
  initializers): a rejected program that now runs is the fix (dispositioned by gcc's output); a program that
  ran and is now rejected must be the comma case or a finding; the pristine lane's new differences as register
  rows in the honest class.

## M3: documentation and the filings

- CONTRACT (D17: the §6.6 forms accepted and rejected, with clauses), VALIDATION (the witness row), SUPPORTED,
  LADDER row 1, TODO (09/28/29 DONE; the audit's §4 items 7/16/17 closed; the judgement-area forms listed as
  open questions), trays 09, 28 and 29 rewritten as the filings to send (reproducers, clauses, the locus at
  `c3ff8c53f`, the patch) and merged into one if they share the patch, the INDEX rows, consumer notes for
  cerberus-caesium and cerberus-sl (static initializers that now desugar), the record
  `docs/2026-11-07_address-constants-record.md`.

## Gates and process

- You run the focused gates yourself (the witness with its selftest and plants, `check_fork_drift.sh` with
  `--selftest`, `check_failure_reach.sh`, `check_pin_sites.sh`, `test_stops.py`, the one-file differentials, the
  corpus measurements, the pristine lane tier-b). Quote last lines verbatim.
- You do NOT run `release.py` and start no poller, waiter, gate script or sleep loop; runs longer than a few
  minutes go through the harness's background execution. The orchestrator runs Tier A after M1, the full battery
  on the M3 tip, and Tier A on the close-out. No tree edit while an orchestrator run is in flight; one heavy job
  at a time, 1-minute load below 12 (two other workers share the box: check before every build or sweep, and
  keep sweeps to one worker process).
- Every lake/lean invocation through `scripts/capped` (`CERB_MEM_MAX=32G`); every make/dune/opam/lane command
  through `/home/dev/projects/cerberus-lean-proj/scripts/ce`. Never `pgrep -f`/`pkill`. No network. `/tmp` is
  unreadable: scratch under the worktree's `.tmp/`, deleted at slice end. Never quote the operator; provenance
  tags on every decision; machine outputs verbatim, derived tallies labelled. Never commit on a mainline; nothing
  pushed. Kernel replay is owed if a proof module changes. A blocker the charter does not resolve is a committed
  park record (`docs/2026-11-07_address-constants-park.md`) and a stop. The grind tripwire: a single build or
  sweep approaching an hour is a stop-and-report.
- Report format at the end: commit hashes with one line each, `git diff --stat 1e5f2cbca..HEAD`, every gate's
  last lines verbatim, the vicinity findings table, the moved rows, and what could not be done.
