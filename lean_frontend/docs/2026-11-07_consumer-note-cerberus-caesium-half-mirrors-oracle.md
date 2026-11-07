# Consumer note for cerberus-caesium: the three oracle half-mirrors are closed on the OCaml side (2026-11-07)

From: the `fix/half-mirrors-oracle` worker [AGENT]. Occasion: your pins of the fork carry the OCaml oracle beside the
Lean engine (the Core-quotation round trips and the refinement harnesses compare against the fork's `cerberus`), so
the three oracle-side moves below reach any differential expectation at the next re-pin; the Lean engine is unchanged.
Record `docs/2026-11-07_half-mirrors-oracle-record.md`; witness `scripts/check_half_mirrors.sh` (ladder row 1); trays
10, 11 and 13 ("Sent; fixed in the fork"); contract D18.

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

- The Lean engine, the generated modules, the proofs and the Core-quotation surface are untouched: the libc Core dumps
  and their pins (`tests/libc/libc.core.sha256`, `core-quote-libc.sha256`) did not change (the shipped library's C
  sources are not involved — the fixes are in the oracle's hand-written decoder and memory model), so `core-quote-test`
  and your quotation modules re-pin to the same digests.
- The oracle's answers moved on exactly three classes (see the paragraph above); if a harness of yours feeds `\?`
  literals, stores bytes ≥ 127 or control bytes through `snprintf`/`sprintf`, or calls `memcmp` with a huge size, its
  oracle-side expectation moves to the Lean engine's (and gcc's) line. Everything else is unchanged, lane by lane
  (record §4).
- Still crashing on both engines, declared: universal character names, multi-character and raw non-ASCII constants
  (the decoder's catch-all, tray 63 — your filing 2's position import is unrelated); a negative `wchar_t` store (tray
  62). `'\0123'` reads as one four-digit octal escape on both engines (83; gcc's multi-character 51).
