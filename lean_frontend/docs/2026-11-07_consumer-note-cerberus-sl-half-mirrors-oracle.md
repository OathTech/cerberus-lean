# Consumer note for cerberus-sl: the three oracle half-mirrors are closed on the OCaml side (2026-11-07)

From: the `fix/half-mirrors-oracle` worker [AGENT]. Record `docs/2026-11-07_half-mirrors-oracle-record.md`; witness
`scripts/check_half_mirrors.sh` (ladder row 1); trays 10, 11 and 13 ("Sent; fixed in the fork"); contract D18.

What moved, in one paragraph: three defects of the fork's own OCaml oracle that the Lean engine never had (the
true-bug audit's "half-mirrors": the Lean engine answered right under the ISO-fix register rows R1/R2/R3, the oracle
crashed or corrupted) are fixed on the OCaml side, hand-written OCaml only — no Lem change, no generated delta, no proof
change, the Lean edits are comments: (10) `ocaml_frontend/decode.ml` decodes the simple escape `\?` (C17 6.4.4.4#1, #4:
63) in character constants and string literals of every prefix, where it died on an uncaught Failure; (11) `decode.ml`'s
`escaped_char` mirrors `CerbDecode.escaped_char` arm for arm, so the `vsnprintf` builtin's store behind
`snprintf`/`sprintf`/`vsprintf`/`vsnprintf` writes every byte 0..255 unchanged (C17 7.21.6.1#8), where the oracle stored
127 as 87 and 200 as 128 and crashed on 19 and 199; (13) `memory/concrete/impl_mem.ml`'s `memcmp` counts on `Z`, so
`memcmp(a, b, (size_t)-1)` reports the checked load's `UB_CERB002a_out_of_bound_load` at the call where the oracle died
on `Z.Overflow`. The Lean engine's answers are unchanged on every program; the two engines now agree byte for byte on the
three classes (witness `scripts/check_half_mirrors.sh`, 41 programs, row 1). The ISO-fix register rows R1/R2/R3 are
RETIRED; the `-- ISO-fix register Rn` markers in `CerbDecode.lean`/`CerbMem.lean` stay as historical notes.

What this means for a pin of the fork at or after this branch:

- Nothing in the Lean semantics moved: no `.lean` definition, no generated module, no proof, no reader signature, no
  fuel form, no failure-reach row (238 = 238) changed. A pin that consumes the Lean engine alone sees identical
  outputs; a kernel replay is not owed and was not run.
- The ORACLE's outputs moved on exactly the three classes, so any differential expectation you keep against the fork's
  OCaml oracle moves there: a libc-mode program that stores a byte outside 32..126 through the `snprintf` family now
  reads it back unchanged (it read 87, 128, … or died with rc 125); a program with `\?` in any character constant or
  string literal now runs (it died with rc 125); `memcmp` with a size beyond OCaml's 63-bit `int` reports
  `Undefined {ub: "UB_CERB002a_out_of_bound_load", …}` at the call (it died with rc 125). Every other oracle answer is
  unchanged: the gated corpora moved only on the six immaculate pins (`g5-decode-question`,
  `zd-e2-ptr-string-literals`, `g5-escape-roundtrip`, `zd-r2-highbyte`, `zd-r2-crash-digit9`, `s4b-memcmp-hugesize`,
  now `MATCH`); the libc_exec, pnvi, coverage, ci and csmith corpora carry no program reaching the three mechanisms
  (a trigger census: no `\?`, no `snprintf` family storing a byte outside 32..126, no `memcmp` with a size beyond
  `int`), and the lanes confirm it (record §4).
- The fork-drift manifest gained `ocaml_frontend/decode.ml` (it was byte-identical to pristine) and re-pinned
  `memory/concrete/impl_mem.ml`; if your `semantics-pin.env` re-derives the oracle surface, those two rows move. The
  pristine-difference register gained the six immaculate rows as `shared-model-fix` (pristine's crash or wrong value
  quoted; `zd-r2-crash-digit9` moved from `diagnostic-text` to that class).
- Declared, unchanged, pinned as gap controls: universal character names (`\u00e9`, `\U0001F600`), multi-character
  constants and raw non-ASCII bytes in constants still CRASH both engines identically (tray 63's crash-to-refusal
  item owns that decoder site; UCNs join it); a negative `wchar_t` store still crashes both (tray 62); `'\0123'` is
  read as one four-digit octal escape (83; gcc 51) on both engines; out-of-range escapes (`'\400'`, `'\x100'`) wrap
  silently on both engines as gcc `-w` does.
