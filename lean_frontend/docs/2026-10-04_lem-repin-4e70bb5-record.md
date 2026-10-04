# Lem re-pin to `4e70bb5` (lem-lean output niceness, backend hardening, BEq lattice) — record

Branch `arc/lem-repin-4e70bb5` over mainline `9e63218bc`. Worker [AGENT]; decisions are [AGENT] unless marked [USER].

- Authorization: [USER 2026-10-04] "merge it. Then take a look at lem-lean, which has implemented a bunch of QoL
  improvements (see doc/lean-backend/2026-10-03_beq-lattice-cerberus-repin.patch for a draft patch for you)", relayed by
  the orchestrator with the brief for this re-pin.
- The lem pin moves from `77ad4facfc60814a4a3f5d09dc88168ca208b285` to `4e70bb506d962355b7120260d4d176aa2850dcc3`
  (lem-lean `mdd/lean-backend`; 43 commits). The lem-side records are lem-lean `doc/lean-backend/`
  `2026-10-03_output-niceness-arc-plan.md` (layout engine, comments kept, mutual/recursive records as `structure`s),
  `2026-10-03_backend-hardening-record.md` (packages A and C, the BEq-lattice slice, and §8, a draft cerberus-sl note),
  and `2026-10-03_beq-instance-lattice-design.md`. The range also carries the lem upstream tray (docs only).
- Procedure: that of `docs/2026-09-30_lem-repin-77ad4fa-record.md`. lem was built in a detached lem-lean worktree at
  `4e70bb5` (`worktrees/lem-lean-pin-4e70bb5`, nothing committed there); `lem -v` printed
  `Lem lean-backend-v0.1.0-alpha.1-63-g4e70bb5`. It was put first on `PATH`, with `LEMLIB` pointing at its `library/`,
  for the worker's commands only. The shared opam switch (still `Lem lean-backend-v0.1.0-alpha.1-20-g77ad4fa`) and
  `deps/lem-pinned` were not touched; re-pinning them is the orchestrator's step.

## 1. Generated OCaml (the oracle): byte-identical

`make -B prelude-src lean-prelude-src` was run in the fresh worktree first with the switch's lem (`77ad4fa`) and then
with the local lem (`4e70bb5`). `diff -rq` of the two `ocaml_frontend/generated` trees (86 files) and the two
`sibylfs/generated` trees (16 files) was empty, and the OCaml lem-sync stamps were equal
(`gen 0f4c3a42b263c91db6221ca115194786107ecca853ce2854ae4941712231208c`). The baseline Lean stamp also equalled the
committed state (clean `git status` after the baseline generation). **The oracle does not change**, so no fork-drift
layer-2 hash moves. `scripts/check_fork_drift.sh` with the local lem, before the pin edit (verbatim):

```
check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=77ad4facfc60814a4a3f5d09dc88168ca208b285, 'lem -v' says lean-backend-v0.1.0-alpha.1-63-g4e70bb5 — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately
```

and after it (verbatim):

```
check_fork_content: OK — 86 source files content/mode-pinned
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 4e70bb506d962355b7120260d4d176aa2850dcc3 matches lem -v lean-backend-v0.1.0-alpha.1-63-g4e70bb5 (hex prefix))
```

## 2. Generated Lean: what changed, by cause

All 170 lem-generated files of the 219 differ. The 49 hand-written copies are unchanged, except
`CerbCtypeMeasure.lean` (§3). The text grows from 39,604 to 83,664 lines (3.63 to 4.17 MB) over the 170 files.
`diff -r` counts 98,875 changed lines. These counts are derived (scripted tallies), not quoted.

**Method.** An instrument (scratch, not committed) compares each pair of files as token streams, after:
- removing comments;
- normalising whitespace;
- splitting merged `open A B C` lines and merged implicit/instance binder groups (`{a b : T}` → `{a : T} {b : T}`);
- dropping `(`/`)` tokens.

The parenthesis drop makes this an argument about the printer, not a proof of equal parses. lem-lean's declaration
census (Cerberus, macro scopes erased, 0 diff lines at every slice) is the stronger instrument; this one is consistent
with it. Result: **167 files equal under the normalisation; 3 residual (`AilSyntax`, `AilSyntaxAux`, `Cabs`).**

| Cause (lem-lean slice) | What the tree shows (derived tallies, before → after) |
|---|---|
| Layout engine (output-niceness S3-A) | lines over 200 characters 1,697 → 72; longest line 105,826 → 602 characters; declarations broken over lines, one match arm per line |
| Printer cleanup (S3-B) | redundant parentheses dropped; `open` lines merged; adjacent implicit binders merged; the garbled `Â` (lexer Latin-1 reading of `§`) 472 → 0 occurrences |
| Comments kept (S1) | the `.lem` authors' comments carried into the output; the `/- removed value specification -/` placeholders 1,477 → 0; `/-` openers 5,236 → 4,960 |
| Records in mutual/recursive blocks as `structure`s (S2) | the only token-level change: `AilSyntax.statement` and `Cabs.specifiers` become `structure`s (`^structure` 55 → 57, `^inductive` 295 → 293). Their hand-emitted `@[inline] def T.field` accessors become projections with the same names. Generated construction `statement.mk a b c d` becomes `{ loc := …, desug_info0 := …, attrs := …, node := … }` (`AilSyntax`), and the positional update in `AilSyntaxAux` becomes `{ stmt with desug_info0 := … }` |
| BEq instance lattice | no generated-text change. LemLib's `[Eq0 a] : BEq a` bridge moved below core's `[DecidableEq a] : BEq a`, so `==` at base types now ELABORATES to core's instance. A probe against this build (`#synth BEq Nat` / `Int` / `String`) printed `instBEqOfDecidableEq` three times. lem-lean's census counts 675 Cerberus declarations changed, all explained by the switch |
| Backend hardening A/C | no Cerberus generated-text change (lem-lean record: neither consumer has a field in the affected classes). Package C deletes LemLib definitions; none is referenced in `lean_frontend/` (grep, 0 hits) |
| Instance priorities | unchanged: `(priority := 500)` 1,044 → 1,044, `(priority := low)` 99 → 99 |

## 3. Hand edits

1. **`CerbCtypeMeasure.natEq0_iff`**: lem-lean's drafted patch,
   `doc/lean-backend/2026-10-03_beq-lattice-cerberus-repin.patch`, applied with `git apply` unchanged
   (`git apply --check` clean). The proof is now `show (n1 == n2) = true ↔ n1 = n2; exact beq_iff_eq`, with the
   docstring updated. Its axioms after the patch (probe, verbatim):
   `'CerbCtypeMeasure.natEq0_iff' depends on axioms: [propext, Quot.sound]`.
   The build demanded no other Lean edit:
   - `CabsImport.lean:661`'s positional `specifiers.mk …` builds unchanged against the structure (mirror doctrine: the
     seam builds the same constructor, positionally, as before; no behaviour change).
   - No measure proof needed an edit.
   - No heartbeat or `maxRecDepth` change was made or needed.
   - The slowest modules of the full rebuild were `Main:c.o` 16 s, `Translation:c.o` 7.5 s, `CoreParser:c.o` 7.1 s,
     `Cabs:c.o` 7.0 s and `CerbMem_lemMeasureProofs` 4.1 s; no proof module stood out. There is no like-for-like
     baseline timing, so this is not a comparison.

The other edits are to gate instruments (§4).

## 4. Gate inputs

Three instruments read the generated TEXT and broke on the new layout or comments. Each fix is the minimal
generalisation. Each was plant-tested on scratch copies, with the evidence below.

1. **`scripts/check_exec_purity.sh`** now strips comments before matching. String and char literals are kept
   verbatim, line numbers are preserved, and the stripper fails closed: an unterminated block comment or a stripper
   error is a FAIL.
   - Cause: lem now carries `core_run.lem`'s comment "upstream mints the Load val_sym via `Symbol.fresh ()`" into
     `Core_run.lean:155`. With mainline's script, row 1 was RED (verbatim):
     `PURITY: Core_run.lean:155:   the Load val_sym via \`Symbol.fresh ()\`); the threaded supply above is` /
     `check_exec_purity: 1 finding(s) in the execution slice` / `check_exec_purity: FAIL (enforcing mode)`.
   - Plants (scratch copy of the script and the tree, verbatim verdicts):
     - P1 `def plantP1 := Symbol.fresh ()` → `PURITY: Driver.lean:2860:def plantP1 := Symbol.fresh ()`, rc 1.
     - P2 the string literal `"unsafeBaseIO"` → finding, rc 1.
     - P3 an unterminated `/-` → `check_exec_purity: FAIL — comment stripper failed on lean_frontend/generated/Driver.lean (fail-closed)`, rc 1.
     - P4 code after a closed block comment on the same line, plus a string containing `/-` followed by
       `unsafeBaseIO` on the next line → 2 findings, rc 1.
     - P5 control: forbidden tokens only inside `--` and nested `/- -/` comments → `CLEAN`, rc 0.
     - The `77ad4fa` tree under the new script → `check_exec_purity: CLEAN (11 modules)`.
2. **`scripts/gen_fuel_parametricity.py`** now reads wrapper and worker heads that span lines. The type may not
   contain `:=`, so a match cannot cross into another definition.
   - Cause: the layout engine breaks long heads. The script found 3 of the 14 wrappers and its vacuity guard fired
     (verbatim): `gen_fuel_parametricity: only 3 wrappers found — is lean_frontend/generated regenerated? (vacuity guard)`.
   - After the fix, `--check` passes, and `--emit` reproduces the 14 committed `example` lines of
     `TotalityProofTest.lean` Part 1 byte for byte.
   - Plants: the `77ad4fa` tree passes (`OK (14 …)`). A new multi-line wrapper `plantW` gives
     `FAIL — fuel'd wrapper(s) in the tree with NO parametricity pin …: plantW`. Renaming the pinned multi-line
     wrapper `simplify_integer_value_base` gives both the missing-pin and the stale-pin FAIL.
3. **`scripts/check_failure_reach.sh` selftest plants P1/P2/P6/P7.** Their premises quoted the old one-line text.
   - Without the fix, the plants failed their premises, loudly (verbatim):
     `PLANT FAIL [P1 premise]: no 'def  valueFromPexpr ' line in generated/Core_aux.lean`,
     `PLANT FAIL [P6 premise]: the plant could not be applied (see above)`, the same for P7, and
     `check_failure_reach: SELFTEST FAILED (5)`.
   - The premises are now whitespace- and parenthesis-robust: P1 finds the one `| _ => none` arm of `valueFromPexpr`
     (asserted unique; line count kept), P2 adds a premise check, and P6/P7 use regexes.
   - All seven plants are RED with their declared messages again (row 1 lines below).
4. **`scripts/failure_reach_register.txt`** regenerated with `check_failure_reach.sh --emit` (seeded from the
   register), with the banner line stripped, then `check_failure_reach.py --reseal`.
   - 11 keys moved: the 60-character message window now reaches different text after the failure message (comments
     in place of `/- removed value specification -/`, a different next declaration, `) )` → `))`). The seed's join
     key did not match them, so they were emitted UNREVIEWED.
   - Their reviews were carried 1:1 from the 11 rows that went stale (`translate_errno`; `process_impl_proc`;
     `step_fs_proc` ×5; `subst_wait_stack`; `Formatted.convert` ×3). Each pair has the same file, kernel owner,
     token, failure-message string and live position class.
   - The two `Formatted.convert` rows with the same message were told apart by source order. Old lines 490
     (`| none => 1`, REACHABLE) and 494 (`| none => /- STD §… -/ 6`, UNREACHABLE-BY-INVARIANT) map to new lines 874
     and 1063, which have the same arms.
   - Result: every column except `msg` and `seal` is unchanged as a multiset (scripted diff, empty), and the header
     and tally line are identical. 154 of the 233 rows keep their message text exactly; the others differ by spacing
     or parentheses only and were matched by the seed key.
   - The live classifier reports every position class unchanged, so `scripts/failure_position.py` needed no change:
     no new shapes.
   - Not changed (finding F2): `need`/`cite` texts that quote generated LINE numbers (e.g. `Driver.lean:575`,
     Formatted's `:490`) now point at positions in the `77ad4fa` layout.
5. **`scripts/unsafebaseio_allowlist.txt`**: unchanged. LemLib's native seams at `4e70bb5` are still `failwithIImpl`,
   `fuelExhaustedWithImpl` and `lemSeqImpl` (grep of `implemented_by`/`unsafeBaseIO`/`@[extern]` in `lean-lib/`), and
   the C2 ratchet passes with the same 19 pinned rows.

## 5. Pin sites

Every site is `4e70bb506d962355b7120260d4d176aa2850dcc3`:
- `lean_frontend/lakefile.toml` (rev, plus a provenance comment);
- `lean_frontend/lake-manifest.json`, `lean_frontend/speclab/lake-manifest.json` and
  `tests/mem-scale-probes/micro/lake-manifest.json` (rev and inputRev);
- `scripts/fork_drift_manifest.txt` `[meta] lem-pin` (plus a NOTE, no `--refresh`);
- `lean_frontend/README.md` (the opam pin command and the NOTICE/LICENSE links);
- the "Lem pin has since moved" parentheticals of `README.md`, `CLAUDE.md`, `SUPPORTED.md`, `TODO.md` and
  `VALIDATION.md`, which now point here.

`check_pin_sites: OK — lem-pin 4e70bb506d962355b7120260d4d176aa2850dcc3 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)`.

## 6. Build

Everything used the local lem `4e70bb5` on `PATH` and `CERB_MEM_MAX=32G`. The builds:
- the OCaml driver and `cerberus-lib.install`;
- `dune install --prefix _build/local-install cerberus-lib`;
- `cerberus.install`;
- `capped make lean-native-obj`;
- `capped lake build CerberusLean cerberus-lean` → `Build completed successfully (395 jobs).` (full rebuild: the
  LemLib checkout was re-cloned at the new rev);
- speclab `capped lake build` → `Build completed successfully (148 jobs).`

## 7. Verbatim gate lines

The tree is commit `111ae6df5` (pins + seam + gate inputs). The local lem `4e70bb5` was first on `PATH` (the runner
log prints `Lem lean-backend-v0.1.0-alpha.1-63-g4e70bb5` and its path). Tier A ran as
`python3 scripts/release.py --mode fast` (evidence `.tmp/release/repin-4e70bb5-tierA-2`, local).

- **Tier A: every row PASSED.** The runner printed `fast: incomplete; 17/17 selected commands completed successfully.`
  and `Source unchanged: False.` The only source change was this re-pin's untracked consumer note, created in
  `lean_frontend/docs/` during the run; `report.json` `source_after.status` is
  `?? lean_frontend/docs/2026-10-04_consumer-note-cerberus-sl-lem-repin-4e70bb5.md`, with HEAD and the diff hash
  unchanged.
- An earlier Tier A run (`repin-4e70bb5-tierA`) was wrapped in `opam exec --switch=.`, which put the switch's lem
  (`77ad4fa`) first on `PATH`. A1 then FAILED on the fork-drift selftest's lem cross-check, as designed (verbatim):
  `check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=4e70bb5…, 'lem -v' says lean-backend-v0.1.0-alpha.1-20-g77ad4fa …`.
  That was a worker setup error, not a tree finding; A2–A13 passed in that run too.

Row 1 (`A1`, `./scripts/test_unit.sh`, PASSED 292.7 s):

```
Total: 16 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: C2 ratchet OK (415 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 19 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (323 files scanned comment-stripped — generated 219, hand-written+test 69, LemLib 35; 0 sorry tokens)
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
check_failure_reach: SELFTEST OK (7 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation — 7 classifier witnesses (lem_if arms/condition, lemSeq continuation, controls) and the unplanted register green)
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=172 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_lem_sync: OK (src 53fbab70e2459a84f6404d4ecac2a596d57f0677c37635f497e37c02b8744545, gen 0f4c3a42b263c91db6221ca115194786107ecca853ce2854ae4941712231208c)
check_lem_sync: lean OK (src 53fbab70e2459a84f6404d4ecac2a596d57f0677c37635f497e37c02b8744545, gen 644265ed8c1e20036d62414759a946988e5ef744436ff4a475d0e5b92f855b92)
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 4e70bb506d962355b7120260d4d176aa2850dcc3 matches lem -v lean-backend-v0.1.0-alpha.1-63-g4e70bb5 (hex prefix))
check_pin_sites: OK — lem-pin 4e70bb506d962355b7120260d4d176aa2850dcc3 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
```

Tier A rows 2–13:

```
[2]  exec          SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[3]  coverage      SUMMARY: total=280 match=225 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[4]  debug         SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[4b] float         SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[4c] bytes         SUMMARY: exec_match=9 neg_pinned=5 fail=0 / ALL AT COMMITTED EXPECTEDS
[5]  libc_exec     SUMMARY: match=43 diff=0 / ALL MATCH RECORDED BASELINE
[6]  multi_tu      SUMMARY: total=8 match=8 fail=0 / ALL PASSED
[6b] tray          SUMMARY: total=7 match=7 fail=0 / ALL PASSED
[7]  parse         Lean parse:     113 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal) / batch diagnostic producers: 8/8 passed / ALL PASSED
[8]  core          Lean parse:     113 ok, 0 failed / ALL PASSED
[9]  elab          SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
[10] libxml2_uri   GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
[11] cn_coverage   SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 / BASELINE OK (213 entries, exact match)
[12] address space test_address_space: SELFTEST OK (14 plants — …) / test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
[13] memory access PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls
```

The elab row is reporting-mode; `same=108 diff=5` is the state recorded at the previous re-pin.

The Tier B rows the brief named ran as `release.py --mode full --lane B5 --lane B10 --lane B7` (evidence
`.tmp/release/repin-4e70bb5-B5-B10-B7`). The runner printed `full: incomplete; 4/4 selected commands completed
successfully.` and `Source unchanged: True.`

```
[B5]  immaculate      OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF, R7 zd-ta-alignas-huge-{sizeof,union-alignof,desugar} ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
[B7]  gcc oracle      SUMMARY: total=2030 compared=1934 agree=1918 agree_nd=0 triaged=16 disagree=0 o2_agree=197 skip_gcc_compile=4 skip_gcc_stdout=2 skip_lean_crash=18 skip_lean_fail=14 skip_lean_timeout=11 skip_ub=47 triaged_addr=14 triaged_float=1 triaged_ub=1 / Baseline check: 0 regression(s), 0 improvement(s) / gcc second-oracle lane OK
[B10.1] upstream oracle Independent oracle: passed; {'semantic_agreement': 953, 'matching_failure': 37, 'reviewed_difference': 8, 'interface_agreement': 2}; …/B10.1/independent-oracle/report.json
[B10.2] its plants    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; …/B10.2/independent-oracle/report.json
```

The B10.1 verdict and the B7 SUMMARY equal those recorded at mainline's `_Alignas` landing
(`docs/2026-10-03_mirror-upstream-d38-alignas-record.md`). The oracle side cannot move (§1). No lane moved: there is
no Lean-vs-oracle disagreement to report.

## 8. Findings and open items

- **F1 (instrument class).** Three text-reading gate instruments assumed lem's old one-line, comment-free output
  (§4.1–4.3). Each failed LOUDLY: a false RED, a vacuity guard and premise asserts. None failed silently, so the
  fail-closed design held. They are generalised and plant-tested here. Any other text-reading tool outside the gate
  set (ad-hoc greps in docs, the evidence scripts of older records) may carry the same assumption.
- **F2 (register citations).** `failure_reach_register.txt`'s `need`/`cite` columns quote generated line numbers in
  the `77ad4fa` layout; all of them are now stale as positions. The keys and classes are correct. Re-deriving the
  citations is a review pass over 233 rows, not done here ([AGENT]: keep the re-pin tight).
- **The switch and `deps/lem-pinned`.** Re-pinning them to `4e70bb5` is the orchestrator's step. After it, row 1 must
  be rerun with the switch's lem, because the fork-drift gate cross-checks the `lem -v` found on `PATH`.
- **Consumer.** The note for cerberus-sl is `docs/2026-10-04_consumer-note-cerberus-sl-lem-repin-4e70bb5.md`.
  - The BEq lattice breaks eight cerberus-sl proof sites; read-only grep at cerberus-sl `b2dfedd` confirms lem-lean's
    §8 table.
  - The relied-on list (VALIDATION §3b) is untouched. None of its five behaviours sits in a module whose tokens
    changed (only `AilSyntax`, `AilSyntaxAux`, `Cabs` did), and none of its seams was edited.
- **Not done here.** Cache-disabled OCaml validation (`DUNE_CACHE=disabled --force`) was not run: the generated OCaml
  is byte-identical and no build rule changed. Tier B rows other than B5/B7/B10 and the pre-merge audit are also
  outstanding.
