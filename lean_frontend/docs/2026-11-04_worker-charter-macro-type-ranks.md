# Worker charter: the macro integer types get their implementation rank (tray 20; cerberus-caesium filing 05)

Date 2026-11-04. Orchestrator [AGENT]. Branch `fix/macro-type-ranks`, worktree
`worktrees/cerberus-lean-fix/macro-type-ranks`, base = mainline `mdd/cerberus-lean` `a126c9f39`
(merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`).

## Provenance

- The defect is the fork's own tray draft `docs/upstream-tray/20-size-t-integer-rank-uac.md` (found 2026-09-03,
  classified TRUE BUG, never filed, never fixed), rediscovered by cerberus-caesium on 2026-11-04 as their filing
  draft `docs/upstream-tray/05-cerberus-size-t-usual-arithmetic-conversion.md` (in their repository, branch
  `tray/size-t-usual-arithmetic-20261104`, commit `e416f83f4`; read it: it localises the translation side
  precisely). It blocks their libxml2 `xmlBufShrink` refinement.
- [USER 2026-11-04] approved the fix as proposed: a fork fix of an upstream mistake, mirrored on both engines by
  generation, registered as a fork-ahead delta of the first kind (the fork's own fix, filed upstream), with the
  filing for the operator to send. The bar for fork fixes ([USER 2026-11-04], container working-practices doc):
  only where the standard's intent is very clear or a consumer is genuinely blocked; here both hold (C17 6.3.1.1#1:
  a typedef has the rank of its type; 7.19#2: `size_t` is an unsigned integer type). The fork does not invent
  semantics: anything in this mechanism that is a judgement call is refused and filed, not decided.
- [USER 2026-11-04] the vicinity rule: a true bug is treated as a symptom of an under-developed feature; the fix
  covers the mechanism, not the one case, and the neighbouring cases are probed and either fixed under the same
  clear-standard reading, refused, or filed.

## The defect (verified 2026-11-04 on the landed mainline, both engines identical, gcc 13 the referee)

`size_t x = (size_t)1 << 32; return x == 0;` answers 1 (gcc 0); `return 0 != x;` answers 0 (gcc 1);
`(x > 0) + 2*(x + 0 == x) + 4*(x * 1 == x)` answers 0 (gcc 7). Cerberus keeps `Size_t` (and `Ptrdiff_t`,
`Wchar_t`, `Wint_t`, the `Intptr_t`/`IntN_t`/... families under `Signed`/`Unsigned`) as its own
`integerType` constructors. `AilTypesAux.lt_integer_rank` (`frontend/model/ail/ailTypesAux.lem:461-543`) ranks
only the standard types in `lt_integer_rank_ISO` and ends in `| _ -> (* TODO: this is probably wrong for macro
types *) false` (:527-529); `eq_integer_rank` (:457-459, with `eq_integer_rank_base` :434-453 and upstream's own
`TODO: K this looks wrong` at :456) does not equate a macro type with its alias either. So in the Core
translation's `usual_arithmetic_conversion_aux` (`frontend/model/translation.lem`, the bullets by rank) the pair
(`size_t`, `int`) fails every rank branch and reaches the last resort, which converts both operands to `unsigned
int` whenever `all_values_representable_in(size_t, int)` is false: `size_t` arithmetic and comparisons against
the `int` family compute at 32 bits. The Ail type checker's own `usual_arithmetic_integer` has non-standard
`Size_t`-wins arms ahead of the bullets (:675-731), so the typing says `size_t` while the translation narrows;
RefinedC takes the typing, which is why the consumer's clone and the driver disagree. The implementation already
knows the aliases: `Implementation.normalise_integerType` (`implementation.lem:67-70`; OCaml
`Ocaml_implementation.normalise_integerType`, Lean `CerberusImpl.normalise_integerType`, a reader consumer over
the enum map) maps `Size_t → Unsigned Long`, `Ptrdiff_t → Signed Long`, `Wchar_t`/`Wint_t → Signed Int_`, the
`IntN_t` families through `aux_ibty`; `le_integer_range` (:292-295) and `are_compatible` (:792-796) use it,
`lt_integer_rank`/`eq_integer_rank` do not. Upstream's tip (`ae70925fc`) carries the same arms.

## M1: the fix in the shared Lem (both engines by generation)

- In `lt_integer_rank` and `eq_integer_rank`, normalise both operands through
  `Implementation.normalise_integerType` before the ISO comparison, so every type the implementation defines gets
  the rank of its alias (the CHERI `Intptr_t` special case stays as upstream wrote it, under `Global.is_CHERI ()`).
  Then make the ISO catch-all `error` (loud) instead of `false`: after normalisation only the standard types reach
  it, and a future unranked type must fail loudly, never silently convert. Check what the normalisation does with
  an `Enum` (it resolves to the compatible type through the enum map: C17 6.7.2.2#4, the right rank) and with
  `Char`/`Bool`/`Ptraddr_t` (identity), and that `eq_integer_rank_base`'s Char arms still hold after normalisation.
- On the Lean side nothing is hand-written for this: the normalisation is a declared reader consumer, so the
  generated `lt_integer_rank`/`eq_integer_rank` gain the enum-map reader by lem's reader lifting; let the
  generation do it and read the generated delta (both trees) to confirm it is the two functions and their callers'
  reader threading only. The fuel/measure census, the failure-reach register (a new pure `error` site in the exec
  cone: register it with its reach class) and the stop-site metadata move accordingly.
- Leave the Ail type checker's `usual_arithmetic_integer` and its NON-STD arms untouched (the consumer's RefinedC
  parity depends on the typing as it is), and `le_integer_range`'s fail-closed macro arms untouched unless the
  vicinity probe shows a reachable crash there (then a refusal or a filed fix, by the bar above). Do NOT adopt the
  consumer's alternative (copying the typing's `Size_t`-wins arms into the translation): it fixes the `int` case
  but hard-codes a non-standard rule for `size_t` against `long long`; the record says why.
- Manifest: single-row edits of exactly the `ailTypesAux` rows (`[source-content]` and `[expected-semantic]`),
  dated NOTE registering the fork-ahead delta of the first kind with the standard's clauses and the tray number;
  never `--refresh`.

## M2: the vicinity, the witnesses, the moved rows

- Probe the whole mechanism before and after M1, both engines, pristine at the cut (the standing build under
  `.validation-foundations/independent-oracle-v2`, or `deps/cerberus-upstream`'s built oracle) and gcc: every
  macro type against every standard type in both operand orders, through `+ - * / % == != < <= > >= & | ^ << >>`
  and the conditional operator, with values at and beyond 2^31 and 2^32; the `Intptr_t`/`Uintptr_t`,
  `IntN_t`/`Int_leastN_t`/`Int_fastN_t`/`Intmax_t` families and `wchar_t`/`wint_t`; integer promotion of the
  macro types (`+x`, `~x`, shifts); `_Generic` and compatibility (the survey's cluster K probes,
  `tests/parity-probes/uncertainty/K-size_t-ranks/`, must keep their answers); enums as operands; and the
  consumer's three programs. Every sibling that answers differently from gcc on conforming input or crashes on
  legal input is fixed if it falls under the same clear-standard reading, otherwise refused loudly or filed, by
  the bar above; each is recorded with its reproducer.
- Witness script `scripts/check_macro_type_ranks.sh` in ladder row 1 (the D12/D13 scripts' shape): the matrix
  above as pinned agreements with gcc's values on both engines (tray 20's `tests/noodle-probes/int/int_size_t_uac_rank.c`
  included, with gcc's line as the expected output), the cluster K probes as controls, plants that make every count
  loud.
- Measure every gated corpus for moved rows before and after (Tier A rows, the Tier B rows, the libxml2 lanes,
  which use `size_t` heavily, the csmith corpus, the ci sweep, the pristine lane: a row where the fork now
  differs from pristine is a new `shared-model-fix` entry in `scripts/upstream_oracle_differences.json` with
  pristine's wrong value quoted). A gated row that moves is upstream's mistake being fixed (dispositioned with
  gcc's value as the referee) or a finding; never a silent re-record.

## M3: documentation and the filing

- CONTRACT (the fork-ahead delta named in §4.1's list; D6-style statement of the rule), VALIDATION (the witness
  row), SUPPORTED, LADDER row 1, TODO (tray 20 and the survey's cluster K line corrected: the survey marked the
  cluster correct having probed only compatibility and `_Generic`), tray 20 rewritten as the filing to send:
  the reproducer, the standard's clauses, the locus at `c3ff8c53f` (line numbers re-cited), the fix as a patch
  against upstream (the normalised rank functions), merged with the consumer's draft's translation-side analysis
  and credited; the INDEX row to "Draft; fixed in the fork (fork-ahead delta), to be filed". Consumer note for
  cerberus-caesium (`docs/2026-11-04_consumer-note-cerberus-caesium-macro-type-ranks.md`: what changes for their
  clone's comparison with the driver, their witnesses w24/w25 expected to move from `DISAGREE/value` to agreement)
  and a short one for cerberus-sl. The record `docs/2026-11-04_macro-type-ranks-record.md`.

## Gates and process

- You run the focused gates yourself: the witness with its selftest and plants, `check_fork_drift.sh` with
  `--selftest`, `check_failure_reach.sh`, `check_pin_sites.sh`, `test_stops.py`, the one-file differentials, the
  corpus measurements, the pristine lane tier-b (`scripts/test_upstream_oracle.sh`, as the bump record §5 ran it).
  Quote last lines verbatim.
- You do NOT run `release.py` and you start no poller, waiter, gate script or sleep loop; runs longer than a few
  minutes go through the harness's background execution. At each milestone commit on your focused gates and
  report; the orchestrator runs Tier A (M1, M2) and the full battery (M3), keeps the evidence and sends the lines.
  No tree edit while an orchestrator run is in flight. One heavy job at a time; 1-minute load below 12 first.
- Every lake/lean invocation through `scripts/capped` (`CERB_MEM_MAX=32G`); every make/dune/opam/lane command
  through `/home/dev/projects/cerberus-lean-proj/scripts/ce`. Never `pgrep -f`/`pkill`. No network. `/tmp` is
  unreadable: scratch under the worktree's `.tmp/`, deleted at slice end. Never quote the operator; provenance
  tags on every decision; machine outputs verbatim, derived tallies labelled. Never commit on a mainline; nothing
  pushed. Kernel replay is owed only if a proof module changes. A blocker the charter does not resolve is a
  committed park record (`docs/2026-11-04_macro-type-ranks-park.md`) and a stop. The grind tripwire: a single
  build or sweep approaching an hour is a stop-and-report.
- Report format at the end: commit hashes with one line each, `git diff --stat a126c9f39..HEAD`, every gate's last
  lines verbatim, the vicinity findings table, the moved rows, and what could not be done.
