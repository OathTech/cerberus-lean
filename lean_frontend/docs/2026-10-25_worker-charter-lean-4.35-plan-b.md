# Worker charter: the Lean 4.35 move, cerberus-lean half (plan B) — 2026-10-25

Branch `arc/lean-4.35` (the same-name pair of lem-lean's landed `arc/lean-4.35`),
worktree `worktrees/cerberus-lean-arc/lean-4.35`, based on mainline `1bb518576`.
Worker: a Fable subagent. Status: ACTIVE from dispatch. The dispatch message says
when the shared opam switch may be touched (see "Precondition").

## Why and what was decided

[USER 2026-10-20] the toolchain moves 4.32.2 → 4.35.0, lem-lean first.
[USER 2026-10-21] the lem-lean half proceeded (landed 2026-10-22: `mdd/lean-backend`
= `e6d8db5`, record `lem-lean/doc/lean-backend/2026-10-21_lean-4.35-record.md`,
review `…/2026-10-22_lem-lean-4.35-premerge-review.md`).
[USER 2026-10-25] the cerberus half is ONE slice done with every other worker
paused, moving the shared opam switch once; in-flight branches rebase afterwards.
A per-worktree lem installation was considered and dropped as over-engineered
[USER 2026-10-25].

Inputs (read whole, first): the scoping record
`lean_frontend/docs/2026-10-20_lean-4.35-scoping-record.md` (§2 what breaks, §4 B,
§5 risks, "Not checked"); the lem-lean record's §9 (plan-B pointers) and §3 (d)
(the 4.35.0 inlining class); its review's P2-1; the container working practices
(`CLAUDE.md` at the container root) and `lean_frontend/CLAUDE.md`.

## Precondition (the only shared mutation)

The opam switch `cerberus-lean/_opam` is shared by every cerberus worktree. Do NOT
run the `deps/lem-pinned` reset or `opam upgrade lem` until the dispatch message
states that every other worker is paused or landed. Everything else in this charter
touches only this worktree.

## Deliverables, in order (commit per checkpoint on green focused checks; Tier A at
## each checkpoint commit; the full battery at close-out)

### P1 — the pin dance (after the precondition)
- `git -C <container>/deps/lem-pinned reset --hard e6d8db5`, then from the primary
  `cerberus-lean/`: `opam upgrade --switch=. --no-depexts lem` (path form; the
  sandbox allows local-source upgrades). Record `lem -v` before and after.
- `lean_frontend/lakefile.toml` LemLib `rev` → `e6d8db5` (the lem mainline HEAD; the
  invariant is branch heads = opam pin = Lake pin); `lake update LemLib` from
  `lean_frontend/`, then `speclab/` and `tests/mem-scale-probes/micro/` (it propagates
  LemLib's `lean-toolchain` = v4.35.0 into `lean_frontend/lean-toolchain` and rewrites
  the manifests to schema 1.3.0; `check_pin_sites.sh` reads only rev/inputRev — run it).
- `scripts/fork_drift_manifest.txt` `lem-pin` (a hex PREFIX of `lem -v`), single-row edit
  + dated NOTE, never `--refresh`; the README pin command; `lean_frontend/CLAUDE.md`,
  `README.md`, `scripts/build_provider_smoke.py` (the 4.32.2 mentions).
- Regenerate both trees (`scripts/ce make clean-prelude-src prelude-src lean-prelude-src`).
  EXPECTED: generated OCaml byte-identical (the fork-drift gate's layer 2 must not move;
  quote it); generated Lean byte-identical (Cerberus has no top-level multi-name
  destructuring let; if a `lemLetRhs_` site appears it carries the one `@[noinline]`
  and nothing else — say so with the diff). Any other generated difference is a
  FINDING (stop and report), not a re-pin.

### P2 — the code repairs (the scoping's §2, confirmed by its trial build)
- Removed `String` functions (`dropRight`, `dropRightWhile`, `Slice.dropRightWhile`,
  `trim`): `CerbFloat.lean:294`, `CerbLocation.lean:225,228` (three calls),
  `Main.lean:1686,1744,1745`, and the test sites the scoping lists (line numbers are
  the scoping's; re-find them).
- `split` no longer rewrites `if decide … = true` with its own hypothesis:
  `Utils_lemMeasureProofs.lean:43,70,97`, `Defacto_memory_lemMeasureProofs.lean:79,143`
  (the scoping's repair sketch: `by_cases h : …` + `simp [h]`, or the `decide_eq_true`
  bridge; kernel-only tactics; no option bumps — a resource-limit need is a finding).
- **`CerbMemAccessFacts.lean:124,127`** — two theorems of `loadM_erasure` leave unsolved
  goals (the strict-reads refusal arm; a contradictory-hypothesis branch `simp_all`
  closed before). TRUST SURFACE: the theorem STATEMENTS must not change; repair the
  proofs only; kernel replay (below) is mandatory; cite the consumer (cerberus-sl,
  cerberus-caesium) names in the record.
- `test/Unit/FuelExemplar.lean:582` — the `rfl` argument (`(rfl : runOne _ _ = _)` or
  `by rfl`).
- The two classes lem-lean's half found that the cerberus seams may also hit:
  `#guard_msgs`/instance-name pins naming `instBEqOfDecidableEq` at `Int` or a
  fixed-width type (now `….instLinearOrderPackage.toBEq`); the `if_neg`/`if_pos`/
  `if_false`/`if_true`/`ite_cond_eq_false` deprecations (fix, never suppress).
- The 14 deprecations "next in line" (scoping §2: `String.get`/`prev`/`mk`,
  `List.asString`, `List.Sublist.cons₂` in CoreParser, CerbDecode, CabsImport,
  CerbCtypeMeasure, FuelExemplar): fix them now if cheap; otherwise list them in
  TODO.md with sites. Warnings are fixed, not suppressed; the generated tree's two
  known warning kinds (lem-lean TODO 54) stay as-is and are re-measured.
- Rebuild everything capped: `lake build CerberusLean cerberus-lean`, every Lake root
  (`scripts/common.sh build_lean`), `speclab`, `make lean-native-obj` (4.35's leanc).

### P3 — the two measurements (lem-lean review P2-1)
- CENSUS: every nullary def in `lean_frontend/generated/` and the hand-written seams
  whose body mentions a `never_extract` constant (the nine B8 `@[never_extract]`
  generated defs, `CerberusFresh.lean`'s seam impls, LemLib's `failwithI`,
  `fuelExhausted(With)`, `Assert_extra.fail` and its other `never_extract` leaves,
  the `scripts/unsafebaseio_allowlist.txt` seams `lemSeqImpl`, `failwithIImpl`,
  `fuelExhaustedWithImpl`), each classified PURE (cost only) or IMPURE SEAM
  (semantics). A nullary caller of an impure seam is a CORRECTNESS finding for the
  re-pin (stop and report), not a cost note.
- COST: the existing timing lanes — the row-1 executable (`core-quote-test`'s measured
  cost, the libc replay of Tier B row 13) — on 4.35.0 against the 4.32.2 figures the
  records carry; a measurement sweep, labelled as such, with the environment stated.

### P4 — TODO 55 and the version-bound comments
- The 128-field runtime limit: on 4.35.0 the lem-lean half found the segfault gone.
  Prove it end-to-end with a witness program through both engines; if gone, lift the
  refusal (fail-closed form kept for the still-failing shapes, if any) and close
  TODO 55 with the witness; if not gone, say so and keep the refusal.
- The `tests/z2-probes/float` and `tests/libc_exec/011` comments that claim 4.32
  truncation become version-bound: re-check `Float.ofScientific` behaviour on 4.35
  (4.33 made it correctly rounded; `float-literal-test` pins 24 bit patterns) and
  correct the comments to what is measured.

### P5 — gates and record
- Row 1; Tier A; the FULL battery (per-command tripwire; the battery as a whole is the
  gate); `check_theorem_axioms.sh` (note the scoping's "Not checked": the 4.31+
  per-proof `native_decide` axiom form now that `Lean.ofReduceBool` is gone — confirm
  the D14 ban still bites, with a plant).
- Kernel replay (named trust gate): `lake env leanchecker` over EVERY module whose
  proofs changed (at least `Utils_lemMeasureProofs`, `Defacto_memory_lemMeasureProofs`,
  `CerbMemAccessFacts`, `Unit.MemoryAccessProofs`, `Unit.FuelExemplar`) and LemLib's
  `LemLibPmapLaws`; quote modules and exit status.
- `lake check --inadvisably-no-sandbox` from `lean_frontend/` (speclab's `path = ".."`
  will not resolve under lake check's sandbox — say what you ran); the real
  `lake check` outside the sandbox is the operator's gate at the claim point. Quote
  `--paranoid` only as what it is (nanoda crashes on this box; four of five accepting
  is not a pass).
- The Core-quoting D3 runner's Lake trace-schema pin (`"2025-09-10"`) against Lake
  5.0.0: check it; a mismatch is a finding with its fix.
- Record `lean_frontend/docs/2026-10-25_lean-4.35-cerberus-record.md`: every change
  file:line, every gate verbatim, the tree-identity evidence, the census and cost
  tables, the kernel replay, the deprecations list, consumer impact. TODO.md updated.
- Consumer notes: cerberus-caesium (builds `lean_frontend` by path through its
  `.cerberus-ws`; its own `lean-toolchain` must move to 4.35.0 at its re-pin; the three
  repair classes to expect in its seams) and cerberus-sl (five `lean-toolchain` files at
  4.32.2; inherits 4.35.0 through `lake update` at its re-pin).

## Non-goals
No emitter change (that is lem-lean's); no semantic change; TODO 56 is its own slice;
the merge-base bump is parked.

## Practices
One coherent commit per checkpoint on green, message states what was verified;
[USER …] only for the operator's rulings, orchestrator text relayed by the operator
is [AGENT …, relayed by the operator]; never quote the operator; never `pgrep -f` or
`pkill`; every lake/lean call through `scripts/capped`; one heavy job at a time; no
push. Park (a committed park record) on any baseline movement, any generated-tree
difference beyond the stated expectation, or any premise of this charter that turns
out wrong.
