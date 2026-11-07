# Worker charter: the three half-mirrors closed on the oracle's side (tray 10, 11, 13)

Date 2026-11-07. Orchestrator [AGENT]. Branch `fix/half-mirrors-oracle`, worktree
`worktrees/cerberus-lean-fix/half-mirrors-oracle`, base = mainline `mdd/cerberus-lean` `1e5f2cbca`
(merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`). One of three slices running in parallel (the
others: the formatter's refusals in `formatted.lem`; the address constants in `cabs_to_ail.lem`): touch nothing
outside this slice's mechanism (`ocaml_frontend/decode.ml`, `memory/concrete/impl_mem.ml`, the matching
hand-written Lean seams' comments, their witnesses, pins and documents), and keep every shared-document edit
(CONTRACT, VALIDATION, LADDER, TODO, the manifest NOTE, the register, the tray INDEX) an appended entry in a
section named for this slice, so the orchestrator's rebase onto the other landings stays mechanical.

## Provenance

- Tray drafts `docs/upstream-tray/10-decode-rejects-question-escape.md`, `11-escaped-char-octal-roundtrip-corruption.md`,
  `13-memcmp-hugesize-overflow-crash.md` (all TRUE BUG; 10, 11 and 13 "Sent: communicated privately" per the
  INDEX); the true-bug audit of 2026-11-04 (`/home/dev/projects/cerberus-lean-proj/.tmp/truebug-audit/2026-11-04_true-bug-audit.md`,
  read-only: rows 10, 11, 13 and their Appendix B probes): all three are HALF-MIRRORED — the Lean engine answers
  correctly (documented "Lean-right divergences" in `lean_frontend/CerbDecode.lean`'s header, `CerbMem.lean`'s
  memcmp loop, VALIDATION's divergence register), while the fork's own OCaml oracle still crashes or corrupts,
  so the standing rule of zero Lean-versus-OCaml behavioural discrepancies is unmet on them.
- [USER 2026-11-04] the fix pass in the audited order; the bar: a fork fix only where the standard is very clear
  or a consumer is blocked, no invented semantics; the vicinity rule. [USER 2026-11-07] dispatched in parallel.
  The mirror-OCaml doctrine (container working-practices doc): hand-written seams mirror the OCaml with cites
  or document the divergence; here the OCaml side is wrong and the Lean side right, so the oracle moves to the
  Lean side's behaviour and the divergence entries retire.

## The defects (oracle only; the Lean side is the reference; gcc 13 the referee)

1. **`'\?'` crashes the decoder** (10): `ocaml_frontend/decode.ml:146-197` has no `"\\?"` arm and the octal
   validator (`:191`, `48 <= n && n <= 56`) rejects it: oracle exit 125 `Failure("decode_character_constant,
   started like an octal constant, but failed: ?")`; the Lean engine decodes 63 (6.4.4.4#4: `\?` is a simple
   escape sequence); the `"\?"` string form the same.
2. **The escape round trip corrupts stored characters** (11): `decode.ml:220-221` `let escaped_char c =
   Char.escaped c` emits OCaml's escaping (`\127` for 127), which the octal reader then mis-decodes
   (127 → 87); the Lean side emits `\xNN` and round-trips (gcc 127). A silently wrong value in libc mode
   (`snprintf`/string storage paths through `store_chars_in_array`).
3. **`memcmp` with a huge size crashes** (13): `memory/concrete/impl_mem.ml` `Concrete.memcmp` (tip
   `:2503-2504`, fork `:2585-2586`) converts the size with `Z.to_int` (`Z.Overflow`); the Lean side's checked
   loop reports `UB_CERB002a_out_of_bound_load` (the right verdict: the read runs out of bounds first).
- Read each tray draft's text and status (Sent) and the audit's row: the filings carry the mechanism; the fork
  now carries the fix as well.

## M1: the three oracle fixes (hand-written OCaml; the Lean side unchanged)

- 10: add the `\?` arm to the decoder's escape table (6.4.4.4#4), in both the character-constant and the
  string-literal paths; the Lean side's `CerbDecode.lean` table is the reference, arm for arm (read it: if the
  Lean table has any other arm the OCaml lacks, or vice versa, that is a sibling to settle the same way).
- 11: make `escaped_char` emit an escaping the reader round-trips (the `\xNN` form the Lean side emits, or store
  the code directly where the printer feeds the reader), so every byte 0-255 round-trips; measure all 256.
- 13: count on `Z` (or guard the conversion with the bound check first) so the oracle reports the out-of-bound
  load exactly as the Lean side does, with the same UB id and location; the same for every sibling site that
  converts a `size_t` argument with `Z.to_int` in `impl_mem.ml` (`memset`, `memcpy`, `memmove`, `realloc`,
  `calloc`: the audit found them correct, verify and say why).
- After each fix the two engines agree byte for byte on the witnesses; the "Lean-right divergence" comments in
  `CerbDecode.lean` and `CerbMem.lean` are rewritten as "both engines, since 2026-11-07" with the cites (the
  only Lean edits: comments; no semantics change; the handwritten-sync gate and the stamps move with them).
- The manifest: `decode.ml` and `impl_mem.ml` are `[source-content]` rows (and `[files]`): single-row edits with
  a dated NOTE registering the fork-ahead deltas (the fork's own fixes, filed in 10/11/13), never `--refresh`.
  No Lem change, no generated delta, no proof change (confirm: no kernel replay owed).

## M2: the vicinity, the witnesses, the moved rows

- Probe the whole decoding and memory-size vicinity on both engines, pristine and gcc: every simple escape
  (`\'`, `\"`, `\?`, `\\`, `\a`, `\b`, `\f`, `\n`, `\r`, `\t`, `\v`), octal escapes of one to three digits
  including `\0` and values above 255 (a constraint violation: 6.4.4.4#9, pin both engines' diagnostics),
  hexadecimal escapes of several lengths, universal character names (`\u`, `\U`: the audit found a crash — a
  sibling to settle as a declared refusal if the implementation is not small, since UCNs need the execution
  character set), multi-character constants (tray 63's class: leave as the crash-to-refusal slice's item,
  record), wide characters and strings, the round trip of every byte through `snprintf`/`strcpy` storage;
  `memcmp`/`memcpy`/`memmove`/`memset`/`strncmp`/`strncpy` with sizes 0, 1, `SIZE_MAX`, `SIZE_MAX/2`,
  `2^31`, `2^32`, and with pointers to the same object, adjacent objects, null.
- Witness script `scripts/check_half_mirrors.sh` in ladder row 1 (the stdio script's shape for the libc-mode
  rows, the rank script's for nolibc; both engines' batch lines pinned to gcc's; pristine the negative control
  on the three fixed classes; plants; the total pinned).
- Measure every gated corpus for moved rows: the rows where the oracle crashed and the Lean side answered were
  CERB_SKIP or divergence rows in the lanes (the immaculate baseline's `L=…` rows, the libc_exec lane, the
  pnvi lane, the csmith and ci corpora): each moves to agreement and is dispositioned by gcc; the ISO-fix and
  divergence registers lose their rows for 10/11/13 (VALIDATION §2); the pristine lane gains register rows in
  the `shared-model-fix` class? NO — these are oracle-side (OCaml) fixes: find the class the register uses for
  a fork-oracle fix of a hand-written OCaml file (the item-G and allocator precedents) and use it, with
  pristine's crash quoted.

## M3: documentation and the filings

- CONTRACT (D18: the three classes now answered identically by both engines; the retired divergences),
  VALIDATION (§2's divergence register rows retired; the witness row), SUPPORTED, LADDER row 1, TODO (10/11/13
  DONE), the trays 10/11/13 updated: status "Sent; fixed in the fork" with the patch against upstream's text
  (`git apply --check` on pristine quoted), the INDEX rows, consumer notes for cerberus-caesium and cerberus-sl
  (the oracle's outputs that moved), the record `docs/2026-11-07_half-mirrors-oracle-record.md`.

## Gates and process

- You run the focused gates yourself (the witness with its selftest and plants from the project root,
  `check_fork_drift.sh` with `--selftest`, `check_failure_reach.sh`, `check_pin_sites.sh`, `check_handwritten_sync`,
  `test_stops.py`, the one-file differentials, the corpus measurements, the pristine lane tier-b). Quote last
  lines verbatim.
- You do NOT run `release.py` and start no poller, waiter, gate script or sleep loop; runs longer than a few
  minutes go through the harness's background execution. The orchestrator runs Tier A after M1, the full battery
  on the M3 tip, and Tier A on the close-out. No tree edit while an orchestrator run is in flight; one heavy job
  at a time, 1-minute load below 12 (two other workers share the box: check before every build or sweep, and
  keep sweeps to one worker process).
- Every lake/lean invocation through `scripts/capped` (`CERB_MEM_MAX=32G`); every make/dune/opam/lane command
  through `/home/dev/projects/cerberus-lean-proj/scripts/ce`. Never `pgrep -f`/`pkill`. No network. `/tmp` is
  unreadable: scratch under the worktree's `.tmp/`, deleted at slice end. Never quote the operator; provenance
  tags on every decision; machine outputs verbatim, derived tallies labelled. Never commit on a mainline; nothing
  pushed. A blocker the charter does not resolve is a committed park record
  (`docs/2026-11-07_half-mirrors-oracle-park.md`) and a stop. The grind tripwire: a single build or sweep
  approaching an hour is a stop-and-report.
- Report format at the end: commit hashes with one line each, `git diff --stat 1e5f2cbca..HEAD`, every gate's
  last lines verbatim, the vicinity findings table, the moved rows, and what could not be done.
