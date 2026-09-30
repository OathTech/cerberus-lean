# Lem re-pin to `77ad4fa` (lem-lean arc/linksem) — record

Branch `arc/lem-repin-77ad4fa` over mainline `55b04e7a4`. Worker [AGENT];
decisions are [AGENT] unless marked [USER].

- Authorization: [USER 2026-09-30] "Great, go ahead with the merge & repin" (lem-lean `arc/linksem` landed on
  `mdd/lean-backend` = `77ad4facfc60814a4a3f5d09dc88168ca208b285`, relayed by the orchestrator).
- Rulings this re-pin depends on, as relayed verbatim in lem-lean `doc/lean-backend/2026-09-28_linksem-findings.md`
  ("Native seams: boundary rulings (2026-09-30)"): D1 [USER 2026-09-30] "D1: agree"; D2 [USER 2026-09-30] "D2: okay,
  agreed"; LP4/OM4 [USER 2026-09-30] "Yes, agree on 1-3. Go ahead".
- The lem-side record, including what each fix does and why: lem-lean `doc/lean-backend/2026-09-28_linksem-findings.md`,
  `2026-09-30_library-parity-coverage.md`, `TODO.md` item 24. The findings file is named after linksem, the project where
  the bugs surfaced; it has no other bearing on Cerberus.
- A measurement pass preceded this one: branch `repin/lem-arc-linksem-20260930`, at lem `66e3cf8`. It was never landed
  and is kept as a record.

## 1. What changed and why

The lem pin moves from `c2a68e7` to `77ad4fa`. That range carries Lean-backend correctness fixes, LemLib changes and a
LemLib toolchain move from Lean 4.28 to 4.32.2 (Cerberus's toolchain). The lem OCaml backend and the OCaml library are
unchanged. The only OCaml-library difference is two comments in the generated `ocaml-lib/lem_word.ml`: the switch's
installed library was compared byte-for-byte against the branch build.

Generation used lem built in the lem worktree at `77ad4fa`, which reports
`Lem lean-backend-v0.1.0-alpha.1-20-g77ad4fa`. It was scoped by `PATH` and `LEMLIB` for these commands only. The
shared opam switch (still `Lem c2a68e7`) and `deps/lem-pinned` were not touched; the orchestrator re-pins the switch
afterwards.

### 1.1 Generated OCaml (the oracle): byte-identical

`make -B prelude-src` was run from the same sources with the switch's lem (`c2a68e7`) and with lem `77ad4fa`. Both
`ocaml_frontend/generated` (86 files) and `sibylfs/generated` came out byte-identical (`diff -rq` empty), and the OCaml
lem-sync stamps are equal. The baseline tree also equals a fresh mainline `55b04e7a4` worktree's generation. **The
oracle does not change**, so no fork-drift layer-2 hash moves.

### 1.2 Generated Lean

65 lem-generated files of 219 differ, plus the two hand-written proof copies (§2). The diff is 3,767 changed lines. All
counts below are tallies over the whole tree, before → after; they are derived, not quoted:

| Fix (lem-lean record) | Before → after |
|---|---|
| B13 `lem_if` (lem's Bool `if`; the same kernel term as `if`) | `lem_if` 0 → 1146, plain `if` −1146 |
| B15/B15b `lemSeq` (strict `let _ = e1 in e2` and unused `let`s) | `lemSeq` 0 → 268 sites; `match CerbDebug.… with \| () =>` 241 → 0 |
| A1 comparison dictionaries threaded; function fields compared like OCaml | failing "comparison residual" instances 722 → 0; `instance (priority := 50)` 217 → 0; `(priority := low)` 203 → 98; derived `compare_derived` 114 → 135; `lemFunctionalBeq`/`lemFunctionalCompare` 0 → 65 each; `[Ord a]` binders +67, `[BEq a]` binders +47 |
| B8 `@[never_extract]` on nullary polymorphic definitions | `never_extract` 11 → 20 |
| B11 annotated `let`s | `let x : T :=` 69 → 239 |
| B14/B15 empty-list ascription (the general rule, landed after review) | `([] : T)` 9 → 903 |
| (none named) import lines reordered in 13 files | sets unchanged |

The 21 types that gained derived comparisons are `action_request`, `action_request2`, `action_step`, `core_step`,
`core_step2`, `desugaring_init_funcs`, `dlist`, `errorM`, `fault_setgen`, `implementation`, `memory_model`,
`memory_model_fp`, `named_predicate_tree`, `named_predicate_tree_fp`, `nd_action`, `ndM`, `one_step`, `parserM`,
`pre_execution`, `translation_stdlib` and `type_predicate`. Before A1, any comparison at these types failed through a
fallback instance. Now a comparison fails only when it reaches a closure (`lemFunctionalBeq`/`lemFunctionalCompare` fail
with "compare: functional value", as OCaml does).

The measurement pass at lem `66e3cf8` had the same tree minus the empty-list rule. The `66e3cf8 → 77ad4fa` delta on this
tree is **exactly 701 added `([] : T)` ascriptions in 38 files**: stripping every `([] : T)` from both sides leaves no
difference. The tree builds with them (§3).

Behaviour: none of the lanes in §4 moved (exact baseline agreement everywhere). A csmith A/B at `66e3cf8`
(`--max 200`, repin vs mainline) gave identical statuses and 0 regressions. It also gave Lean CPU 33.52 s vs 37.44 s over
the 97 matched inputs, with the unchanged oracle moving by the same factor (×0.881, load 6 → 41): no measurable cost.

## 2. Hand edits

The two measure proofs that unfold through B15 sites:

- `Core_run_aux_lemMeasureProofs.lean:97`: `simp (disch := size_lt) only [add_to_asw_lemFuel, key, lemSeq]`.
- `Driver_lemMeasureProofs.lean:69`: `simp only [hack_lemFuel, lemSeq, step_eval_pexpr, …]`, with
  `CerbDebug.print_debug_pure` dropped. It is unused once `lemSeq` discards the call, and Lean's unusedSimpArgs linter
  names it.

Without these edits the build fails (measured at `66e3cf8`, same shapes):
`Core_run_aux_lemMeasureProofs.lean:100:26: Tactic \`introN\` failed: There are no additional binders or \`let\` bindings in the goal to introduce`
(also at :105, :109, :113) and `Driver_lemMeasureProofs.lean:68:11: unsolved goals`. The build demanded no other edit.

## 3. Build

All builds used the capped Lean build (32G). They were the OCaml oracle, the `cerberus-lib` local install,
`cerberus.install`, `lean-native-obj`, `lake build CerberusLean cerberus-lean` giving
`Build completed successfully (395 jobs).`, and speclab giving `Build completed successfully (148 jobs).`

## 4. Gate changes and their rulings

1. **Pin sites** → `77ad4facfc60814a4a3f5d09dc88168ca208b285`:
   - `lean_frontend/lakefile.toml` (rev, plus a provenance comment);
   - the three lake-manifests (rev and inputRev);
   - `scripts/fork_drift_manifest.txt` `[meta] lem-pin` (plus a note);
   - `lean_frontend/README.md` (the opam pin command and the NOTICE/LICENSE links);
   - the "pinned Lem mainline is c2a68e79 …" parentheticals in `README.md`, `CLAUDE.md`, `SUPPORTED.md`, `TODO.md`
     and `VALIDATION.md`, which now point here.

   Ruling: [USER 2026-09-30] "Great, go ahead with the merge & repin".
2. **Native boundary: `lemSeqImpl` is TEMPORARY.** It is the `implemented_by` body of the transparent
   `lemSeq a b := b ()`: the kernel and proofs see `b ()`, while at run time `a ()` is forced first (`IO.mkRef` under
   `unsafeBaseIO`), mirroring OCaml's strict `let`. The gap: a failure or non-termination in the discarded `a` is visible
   at run time and invisible to the logic. In Cerberus every such `a` is a debug `print_debug_pure`/`warn` call (a no-op
   twin), at 268 sites.
   - Ruling: D1 [USER 2026-09-30] "D1: agree", i.e. D1(a) accepted onto the boundary list as temporary, not permanent.
   - Mover: lem-lean TODO item 24, the failure-monad translation, which deletes the seam.
   - `scripts/unsafebaseio_allowlist.txt` gains a survivor row `lemSeqImpl temporal(lem-lean TODO 24: failure-monad
     translation)`, a Q4-class note, and three `PIN` rows (IMPLBY / UNSAFEBASEIO / UNSAFEDECL, COUNT 1). VALIDATION §3
     lists it; SUPPORTED and README mention it.
   - D1(b) removed LemLib's `@[extern] lemSetExitOnPanic`, so there is no row for it. Before the allowlist rows, the
     gate reported (verbatim, at `66e3cf8`, where the extern still existed):
     `check_theorem_axioms: FAIL — C2 ratchet leg 3: implemented_by/unsafe/unsafeBaseIO/extern census row(s) not matching the pinned population …`
     followed by `IMPLBY/UNSAFEBASEIO/UNSAFEDECL lem-lean/lean-lib/LemLib.lean lemSeqImpl 1`.
3. **Failure-position classifier** (`scripts/failure_position.py`, [AGENT]).
   - `lem_if` is classified as `if`: its arms climb to it, and its condition is SCRUTINEE.
   - The continuation lambda of `lemSeq (fun _ => e1) (fun _ => e2)` takes the position of the whole application; the
     discarded first lambda stays LAMBDA-BODY.
   - Without this change the gate is RED on the new tree: a revert check with mainline's classifier gave 10
     `POSITION CLASS CHANGED` rows and `check_failure_reach: FAIL —`.
   - The selftest gains plants P6 (every `lem_if` of `Formatted.lean` renamed to `lem_iff`: the registered TAIL arm of
     `showNonNegativeWithBasis` reads OTHER-IF, RED) and P7 (`hack_lemFuel`'s `lemSeq` head renamed to `lemSeqX`: the
     registered TAIL continuation reads LAMBDA-BODY, RED).
   - It also gains witnesses C1–C7 on synthetic sources: `lem_if` arms and condition, the `lemSeq` continuation (also
     inside a `lem_if` arm), and two controls.
   - Two defects were found while writing P6 and fixed in the plant. First, a one-site rename was VACUOUS: the classifier's
     `then`/`else` walk-back does not stop at declaration headers, so an earlier `lem_if` in the file satisfied it. This
     walk-back imprecision predates the re-pin, applies to plain `if` too, and is recorded, not changed. Second, a
     premise heredoc's failure went unnoticed. Plant premises are now fail-closed.
4. **Failure-reach register** (`scripts/failure_reach_register.txt`): regenerated with `check_failure_reach.sh --emit`
   (seeded from the register) and `check_failure_reach.py --reseal`.
   - One key moved because of B11. `step_fs_proc`'s key `… let forceIntegerFromIntegerValue := (fun (` became
     `… let forceIntegerFromIntegerValue : String `. The position class (LAMBDA-BODY), the reach class
     (UNREACHABLE-BY-INVARIANT) and the review are unchanged.
   - One row moved position, because emit orders rows by line.

## 5. Verbatim gate lines

Everything below was run with the local lem `77ad4fa` on `PATH`, the tree at commit 4/5 (`458f4876d`), and memory cap 32G.

Row 1 (`./scripts/test_unit.sh`, rc 0):

```
Total: 16 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: C2 ratchet OK (415 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 19 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (323 files scanned comment-stripped — generated 219, hand-written+test 69, LemLib 35; 0 sorry tokens)
check_failure_reach: SELFTEST OK (7 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation — 7 classifier witnesses (lem_if arms/condition, lemSeq continuation, controls) and the unplanted register green)
check_failure_reach: OK (230 pure failure sites = the 230 register rows exactly (228 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=170 REACHABLE=39 UNKNOWN=21; every row sealed; tally line consistent)
check_lem_sync: OK (src ea7c8e8524f09709dc8f178275a41264ff1145b0c64a55837a78d1cb1beeb4a7, gen 0da22cf8da699b428cd14b66c7d86300b321d2d05bba10fd82ed5d6b559bed66)
check_lem_sync: lean OK (src ea7c8e8524f09709dc8f178275a41264ff1145b0c64a55837a78d1cb1beeb4a7, gen 0759bb578364239e80ac6bc0c82b7b5a1c08200fb2f420a93d93441e6b30e49d)
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 77ad4facfc60814a4a3f5d09dc88168ca208b285 matches lem -v lean-backend-v0.1.0-alpha.1-20-g77ad4fa (hex prefix))
check_pin_sites: OK — lem-pin 77ad4facfc60814a4a3f5d09dc88168ca208b285 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
```

Tier A (every row rc 0), plus `test_immaculate.sh` (Tier B row 5, run on request):

```
[2]  exec          Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[3]  coverage      Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[4]  debug         Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[4b] float         Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
[4c] bytes         SUMMARY: exec_match=9 neg_pinned=5 fail=0 / ALL AT COMMITTED EXPECTEDS
[5]  libc_exec     SUMMARY: match=43 diff=0 / ALL MATCH RECORDED BASELINE
[6]  multi_tu      SUMMARY: total=8 match=8 fail=0 / ALL PASSED
[6b] tray          SUMMARY: total=7 match=7 fail=0 / ALL PASSED
[7]  parse         batch diagnostic producers: 8/8 passed / ALL PASSED
[8]  core          Lean parse:     113 ok, 0 failed / ALL PASSED
[9]  elab          SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
[10] libxml2_uri   GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
[11] cn_coverage   SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 / BASELINE OK (213 entries, exact match)
[12] address space test_address_space: SELFTEST OK (14 plants — …) / test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
[13] memory access PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls
[B5] immaculate    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

The elab row is reporting-mode. `same=108 diff=5` equals the state recorded in `docs/sc-wp0-evidence/`.

## 6. Open, not done here

- **The switch and `deps/lem-pinned`.** Re-pinning them to `77ad4fa` is the orchestrator's step. After it, the gates
  must be rerun with the switch's lem: the fork-drift gate cross-checks the `lem -v` found on `PATH`.
- **Walk-back imprecision (pre-existing).** The failure-position classifier's `then`/`else` walk-back crosses declaration
  headers (§4.3). It matters only for a branch with no `if` of its own, which parsed Lean does not have.
- **The seam's mover.** `lemSeqImpl` leaves the boundary list when lem-lean TODO 24 (the failure-monad translation)
  lands.
- **Consumer.** The note for cerberus-sl is `2026-09-30_consumer-note-cerberus-sl-lem-repin-77ad4fa.md`.
