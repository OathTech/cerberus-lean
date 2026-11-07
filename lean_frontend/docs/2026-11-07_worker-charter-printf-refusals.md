# Worker charter: the formatter's unparsed and crashing conversions refuse; `%jd` and `snprintf`'s return fixed (tray 26, 16; audit §4 items 1, 3, 10)

Date 2026-11-07. Orchestrator [AGENT]. Branch `fix/printf-refusals`, worktree
`worktrees/cerberus-lean-fix/printf-refusals`, base = mainline `mdd/cerberus-lean` `1e5f2cbca`
(merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`). One of three slices running in parallel
(the others: address constants in the desugarer's constant-expression predicates; the oracle half-mirrors in
`decode.ml`/`impl_mem.ml`): touch nothing outside this slice's mechanism (`frontend/model/formatted.lem`, its
witnesses, pins and documents), and keep every shared-document edit (CONTRACT, VALIDATION, LADDER, TODO, the
manifest NOTE, the migration map, the register, the tray INDEX) an appended entry in a section named for this
slice, so the orchestrator's rebase onto the other landings stays mechanical.

## Provenance

- Tray drafts `docs/upstream-tray/26-printf-star-width-crash.md` (TRUE BUG, crash on legal input) and
  `16-snprintf-truncation-return-length.md` (TRUE BUG); the true-bug audit of 2026-11-04 (orchestrator's scratch
  `/home/dev/projects/cerberus-lean-proj/.tmp/truebug-audit/2026-11-04_true-bug-audit.md`, read-only: rows 16, 26, 27
  and §4 items 1, 3, 10 with Appendix B's probes `probes/B2/pf_*.c`, `probes/B/pf_percent_n.c`).
- [USER 2026-11-04] the fix pass in the audited order; the bar (container working-practices doc): a fork fix
  only where the standard is very clear or a consumer is blocked, no invented semantics, otherwise a declared
  refusal and a filing; the vicinity rule: fix the mechanism's neighbourhood, probe it, refuse or file what is a
  judgement call. [USER 2026-11-07] this slice dispatched, in parallel with two others.
- Precedents for the shapes: the compound-assignment record (`docs/2026-10-29_compound-assignment-refusal-record.md`,
  a Lem-level declared refusal with the D11/D12/D13 `error` form and the outcome-protocol legacy class) and the
  stdio record (`docs/2026-11-05_stdio-exit-flush-record.md`, a libc-mode witness in row 1 run from the project
  root, the libc re-pin recipe).

## The defects (all in `frontend/model/formatted.lem` at the base; both engines by generation; gcc 13 the referee)

1. **Unparsed floating conversions answer a false UB.** The conversion-specifier type lists only `CS_f`, with
   `CS_F | CS_e | CS_E | CS_g | CS_G | CS_a | CS_A` commented out (`:40`), and the parser has `char #'f'` only
   (`:143`); `LM_L` is commented out too (`:32`, `:133`). A conforming `printf("%e", 3.5)` (likewise `%g`, `%a`,
   `%E`, `%G`, `%A`, `%Lf`) is reported as `Undefined {ub: "Invalid_format[[%e]\n]"}` on both engines and
   pristine (gcc prints `3.500000e+00`). A silently wrong verdict on valid C.
2. **`%*d` and `%.*d` crash.** `| Just FW_asterisk -> assert_false "TODO: FW_asterisk"` (`:253`) and
   `| Just (P_asterisk) -> error "TODO: Formatted.convert, * prec"` (`:453`, `:613`, `:672`): oracle exit 125
   `Failure("internal error: TODO: formatted.lem 6")`-class, Lean abort 134 (tray 26).
3. **`%n` crashes** (`:725-726` `error "WIP: Formatted.convert, CS_n"`) and **`%ls` crashes** (the `CS_s` arm's
   `error ("WIP, Formatted => CS_s, ty <> Pointer ==> …")` when the argument is a `wchar_t *`): audit §4 item 10.
4. **`%jd`/`%ju` answer a false UB153b.** `| Just LM_j -> (Just (Implementation.is_signed_or_unsigned Ctype.Intmax_t), …)`
   (`:559-560`): the argument's type is the alias (`long` on this implementation) and the exact-type test fails
   (gcc prints `-7`); the same family as the rank fix (an alias compared unnormalised).
5. **`snprintf` returns the truncated length** (tray 16; the audit's row 16: `List.length cs'` of the truncated
   output, around `:789-791` at the tip) where 7.21.6.5#3 requires the length that would have been written.
- NOT in scope: `%x`/`%X`/`%o` with an `int` argument → UB153b (tray 27): the strict 7.21.6.1#9 reading is
  upstream's defensible judgement; it stays a loud verdict and is filed, not changed (the audit's REFUSE-AND-FILE).

## M1: the refusals and the two fixes (shared Lem, both engines by generation)

- Items 1-3 become DECLARED REFUSALS in the D11/D12/D13 form (`error` with one attributed text per class, the
  outcome-protocol legacy class, the migration map's UNMIGRATED line each): the parser accepts the full
  conversion-specifier and length-modifier syntax of 7.21.6.1#3-#8 (so `%e`, `%g`, `%a`, their capitals, `L`,
  `%n`, `%ls`, `*` widths and precisions PARSE), and the conversion stage refuses the unimplemented ones with a
  text that names the conversion, the clause, upstream's TODO and the tray number; a format the parser cannot
  parse at all stays the `Invalid_format` UB (that is the standard's rule for a malformed format: 7.21.6.1#9).
  Why refusals and not implementations: the floating formatting of `%e`/`%g`/`%a` is a chunk of well-specified
  work (a later slice: queue it in TODO with a size); a refusal is the honest interim and never a wrong answer.
  `%*d`/`%.*d`: if the argument-driven width and precision can be implemented in the existing `convert` with
  the obvious loads (an `int` argument consumed before the value, 7.21.6.1#5, a negative width = `-` flag plus
  the magnitude, a negative precision = omitted), do it as a clear-standard fix instead of a refusal, with the
  witnesses; say which you did and why.
- Item 4: compare the `LM_j` argument's type after `Implementation.normalise_integerType` on both sides (the
  alias table; the rank slice's precedent); the same check for every length modifier that names a macro type
  (`z`, `t`: `size_t`/`ptrdiff_t` — measure whether they are already right through `is_compatible_with_size_t`,
  and make `j`/`z`/`t` uniform if the vicinity probe shows a sibling).
- Item 5: `snprintf` returns the full would-be length (7.21.6.5#3); `vsnprintf` the same; `sprintf` unaffected.
- The usual: `make prelude-src lean-prelude-src`, both engines rebuilt, the generated delta confined to
  `Formatted` (read it on both targets), the libc Core text re-pinned if the library's own `printf` family moves
  (it is compiled from the same Lem? no: the formatter is the Lem model the Core `printf` builtin runs; check
  whether `libc.core` changes at all and say so), the manifest's `formatted` rows single-row edited with a dated
  NOTE (never `--refresh`), the failure-reach register and stop-site metadata moving as the gates decide (new
  pure `error` sites in the formatter: register them with their reach class), fuel forms unchanged unless a
  measured worker's cone changes (then say so; a proof change means kernel replay).

## M2: the vicinity, the witnesses, the moved rows

- Probe the whole formatter on both engines, pristine and gcc: every conversion specifier × every length
  modifier × flags (`-`, `+`, space, `#`, `0`) × width/precision forms (literal, `*`, negative via `*`), the
  argument-type matrix (`int`, `long`, `long long`, `intmax_t`, `size_t`, `ptrdiff_t`, `unsigned` forms, `double`,
  `long double`, `char *`, `wchar_t *`, `void *`), `%%`, `%c` with `int`, `%s` with a precision, `%p`, `%hhd`,
  `%hd`; `printf`, `fprintf(stderr, …)`, `snprintf` with truncation and with size 0, `sprintf`; return values.
  Every sibling wrong on conforming input or crashing on legal input is fixed if the standard is clear (and the
  implementation small), refused otherwise, or filed; tray 27's class stays as is and is recorded.
- Witness script `scripts/check_printf_refusals.sh` in ladder row 1 (the stdio script's shape, libc mode, run
  from the project root; the refusals' texts pinned whole on both engines; the fixed rows pinned to gcc's lines;
  pristine the negative control; plants with derived counts; the total pinned).
- Measure every gated corpus for moved rows (the libc-mode lanes, the immaculate libc corpus, the csmith corpus
  — its final `printf("checksum = %X\n", …)` is the shape to watch — the ci sweep, the pristine lane): a row
  that moves from a crash to a refusal is a class move (scoreboard rows at the next deliberate re-record, gated
  rows retired or re-recorded with the reason); a row that moves from a false UB to gcc's value is the fix; a
  new fork-versus-pristine difference is a register row in the honest class with pristine's line quoted.

## M3: documentation and the filings

- CONTRACT (D16: the formatter's declared refusals and the two fixes, the legacy stop form stated plainly;
  the §4.1 witness sentence), VALIDATION (the witness row), SUPPORTED (the printf conversions supported /
  refused, as a table), LADDER row 1, TODO (26 and 16 DONE; the floating-conversion implementation queued with a
  size; the audit's §4 items 1, 3, 10 closed; tray 27 left as filed), the migration map, trays 26 and 16
  rewritten as the filings to send (reproducers, clauses, the locus at `c3ff8c53f`, the patch for the two fixes,
  the refusals described), a new tray entry for the unparsed floating conversions (a false UB on valid C) and
  the INDEX rows, consumer notes for cerberus-caesium and cerberus-sl (what now refuses, what changed value),
  the record `docs/2026-11-07_printf-refusals-record.md`.

## Gates and process

- You run the focused gates yourself (the witness with its selftest and plants from the project root,
  `check_fork_drift.sh` with `--selftest`, `check_failure_reach.sh`, `check_pin_sites.sh`, `test_stops.py` and the
  stop-policy plants, `libc_prep.sh --check` if the library's text moved, the one-file differentials, the corpus
  measurements, the pristine lane tier-b). Quote last lines verbatim.
- You do NOT run `release.py` and start no poller, waiter, gate script or sleep loop; runs longer than a few
  minutes go through the harness's background execution. The orchestrator runs Tier A after M1, the full battery
  on the M3 tip, and Tier A on the close-out; M2's witness is covered by your focused run and the battery. No tree
  edit while an orchestrator run is in flight; one heavy job at a time, 1-minute load below 12 (two other workers
  share the box: check before every build or sweep, and keep sweeps to one worker process).
- Every lake/lean invocation through `scripts/capped` (`CERB_MEM_MAX=32G`); every make/dune/opam/lane command
  through `/home/dev/projects/cerberus-lean-proj/scripts/ce`. Never `pgrep -f`/`pkill`. No network. `/tmp` is
  unreadable: scratch under the worktree's `.tmp/`, deleted at slice end. Never quote the operator; provenance
  tags on every decision; machine outputs verbatim, derived tallies labelled. Never commit on a mainline; nothing
  pushed. Kernel replay is owed if a proof module changes. A blocker the charter does not resolve is a committed
  park record (`docs/2026-11-07_printf-refusals-park.md`) and a stop. The grind tripwire: a single build or sweep
  approaching an hour is a stop-and-report.
- Report format at the end: commit hashes with one line each, `git diff --stat 1e5f2cbca..HEAD`, every gate's
  last lines verbatim, the vicinity findings table, the moved rows, and what could not be done.
