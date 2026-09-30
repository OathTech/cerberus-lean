# Pre-merge audit: lem re-pin `c2a68e7` → `77ad4fa` (range `55b04e7a4..ba2e859a9`)

Auditor: a fresh pre-merge auditor [AGENT], on branch `audit/lem-repin-77ad4fa`. Scope as approved,
verbatim: [USER 2026-09-30] "Agree. Let's try to keep the repin tight". The four checks in the brief were
the oracle and pin sites, the gate changes, the proof edits and the records. Rulings under audit: D1
[USER 2026-09-30] "D1: agree"; LP4/OM4 [USER 2026-09-30] "Yes, agree on 1-3. Go ahead".

## Verdict: MERGEABLE WITH FIXES

The fixes needed are documentation only (F1). The code, the gates and the pins are correct. F2 and F3 are
advisory. [AGENT] verdict.

## Findings (by severity)

### F1 (MEDIUM): the `lemSeq` gap statement "every discarded `a` is a debug no-op" is false. One discarded computation is `step_ctx`, and running it at run time is new with this re-pin.

The boundary text makes this claim in four places:

- `lean_frontend/docs/2026-09-30_lem-repin-77ad4fa-record.md:99`: "In Cerberus every such `a` is a debug `print_debug_pure`/`warn` call (a no-op"
- `lean_frontend/VALIDATION.md:1151-1152`: "In Cerberus every such `a` / is a debug `print_debug_pure`/`warn` call (no-op twins, 268 generated"
- `scripts/unsafebaseio_allowlist.txt:31`: "In Cerberus the discarded `a` is a print_debug_pure/warn call (the debug no-op twins) at 268 generated"
- `lean_frontend/docs/2026-09-30_consumer-note-cerberus-sl-lem-repin-77ad4fa.md:27`: "In Cerberus every such `a` is a debug `print_debug_pure`/`warn` no-op (268 sites)."

Measured on the range head's generated tree: 268 `(lemSeq (fun _ =>` sites. The count is correct. The
first-lambda heads, derived by a balanced-paren scan, are:

- `CerbDebug.print_debug_pure` 195 and `CerbDebug.warn` 44;
- `lem_if` 15 (all guard a debug call);
- `CerbDebug.print_debug_located` 6;
- `match` 3, `(setMapBy` 2 (a map of debug prints), `(` 1 (a guarded `warn`);
- `CerbDebug.print_unsupported` 1;
- `List.filter` 1.

The non-debug ones:

- **`Driver.lean:433`**, in `driver2_lemFuel`, the main execution driver (`CerbCall.lean:290`), verbatim:
  `(lemSeq (fun _ =>  List.filter  (fun (p : (Nat ×((Option (thread_id) ×thread_state)))) =>  match p with |  (tid1,  th_info) =>  List.any  ((step_ctx _lemReader_enum_definitions _lemReader_tagDefs)  post_core_dr_st.layout_state …`
  This is `frontend/model/driver.lem:1379` `let _non_blocked_th_sts = List.filter …`, marked "TODO: hackish".
  - It calls `Core_reduction.step_ctx` on the post-step state. No live branch of `driver2` calls `step_ctx` on
    that state (`driver.lem:1384-1438`).
  - `step_ctx` has 10 registered pure-failure rows, 4 of them reach class `UNKNOWN` (`scripts/failure_reach_register.txt`,
    e.g. `( String.append "STUCK ==> " …`).
  - At `c2a68e7` this was an unused `let  _non_blocked_th_sts  := List.filter …` (primary checkout's
    generated `Driver.lean:426`), which the Lean compiler drops. At `77ad4fa` the run time evaluates it on every
    `driver2` iteration, as OCaml does.
  - So the re-pin moves run-time behaviour here towards OCaml. It is also the one place where the D1 gap (fails at
    run time, invisible to the logic) covers a real semantic computation with `UNKNOWN`-reach failures, not a debug
    stub.
  - No lane moved (the record's Tier A lines; the running ladder's A1–A4 PASSED), so nothing observed.
- `Driver.lean:319`: `match CerbGlobal.current_execution_mode () with | none => false | some mode1 => …`. Pure,
  cannot fail.
- `Core_rewrite.lean:294`: `match mop with | DeriveCap _ _ => () | …`. Trivial.

No discarded arm contains a failure token textually (scan for `failwith|fuelExhausted|panic`: 0).

**Fix:** reword the four places to say "238 direct debug calls plus 30 other discarded computations, all
debug or pure except `driver2`'s `_non_blocked_th_sts` (`driver.lem:1379`), which evaluates `step_ctx` at run
time". Note in the record that this computation now runs at run time, where it did not before. [AGENT]
recommendation: bring this to the operator's attention, because D1 was relayed to cerberus-sl on the "debug
only" characterisation. The ruling itself is general (lem-lean findings "Native seams"), so it is not in
question.

### F2 (LOW, advisory): a failure directly inside a discarded `lemSeq` arm is classified as an ordinary LAMBDA-BODY

`scripts/check_failure_reach.sh:205` (witness C6) fixes `(lemSeq (fun _ =>  (failwithI  "x" : Nat)) (fun _ =>  n))` as
`LAMBDA-BODY`.

Such a site is logically discarded but forced at run time: the same logic/run-time split that the DISCARDABLE
class exists to flag. It is not fail-open, because a new site is still RED as unregistered. But the reviewer
would see an ordinary class, not a boundary signal. There are 0 such sites today (measured). A distinct class
could be added when TODO 24 lands, or never. No action required for this merge.

### F3 (LOW): record §1 overstates "The lem OCaml backend and the OCaml library are unchanged"

`lean_frontend/docs/2026-09-30_lem-repin-77ad4fa-record.md:20-21`. In `c2a68e7..77ad4fa`, `src/initial_env.ml`
changed. It is target-shared code: `read_target_constants` now raises `Fatal_error` where it used to fall back
`with _ -> NameSet.empty`. It changes no output when the constants file exists. The `library/*.lem` changes I
checked (`word.lem`, `string_extra.lem`) are `declare lean target_rep` only. The oracle claim rests on the
byte-identity measurement, which holds (below), so this is a wording fix: "no OCaml-output-affecting change".

## Out of scope (not findings)

- `SC-CONCURRENCY.md:494` still names Lem `c2a68e79…`. It is a dated "Observed 2026-09-29" line, not a pin site.
- `scripts/failure_reach_register.txt` rows 110-112 (`beqCoreStep2`) cite "Driver.lean:425 (generated driver2)".
  This is an advisory line number and was already off by one at mainline (426). The use is now at `Driver.lean:433`.
- The then/else walk-back crosses declaration headers (pre-existing, recorded in the record §6). I reproduced it
  below; it predates the range.

## What I verified

1. **Oracle unchanged.** `diff -rq` of `ocaml_frontend/generated` (86 files) and `sibylfs/generated` (16) between the
   primary checkout (generated 2026-09-27, before `77ad4fa` existed: commit date 2026-09-30 22:36) and the arc
   worktree (generated 2026-09-30 22:39): both `IDENTICAL`. The OCaml lem-sync stamps are equal in both (`src ea7c8e85…`,
   `gen 0da22cf8…`). The fork-drift manifest diff changes only `lem-pin` plus a note; no layer-2 hash moved.
2. **Pin sites.** Lakefile rev, all three manifests (rev and inputRev), `fork_drift_manifest.txt` `lem-pin`, and the
   README pin command and NOTICE/LICENSE links are all `77ad4facfc60814a4a3f5d09dc88168ca208b285`. No other tracked
   lakefile or manifest requires LemLib. `./scripts/check_pin_sites.sh` in my worktree printed:
   `check_pin_sites: OK — lem-pin 77ad4facfc60814a4a3f5d09dc88168ca208b285 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)`.
   `deps/lem-pinned` HEAD is `77ad4fa…`, and `lem -v` gives `Lem lean-backend-v0.1.0-alpha.1-20-g77ad4fa`. `77ad4fa` is on lem-lean `mdd/lean-backend`.
3. **Allowlist.** The diff only adds rows: one `temporal(lem-lean TODO 24: failure-monad translation)` survivor row
   (Q4 class vocabulary), comments, and exactly three `PIN` rows (`IMPLBY`/`UNSAFEBASEIO`/`UNSAFEDECL … lemSeqImpl 1`).
   `PIN` rows go from 16 to 19, which matches the gate's "19 pinned path-qualified counted rows". Nothing was widened or removed.
   LemLib at `77ad4fa` has `private unsafe def lemSeqImpl` using `unsafeBaseIO` and `@[implemented_by lemSeqImpl] def lemSeq … := b ()`.
   No `@[extern]` remains. `lemSetExitOnPanic` never existed at `c2a68e7`, so no row is owed. This matches D1(a)/(b).
4. **Classifier.**
   - The C1–C7 witnesses pass with the new `failure_position.py`. With mainline's (`55b04e7a4`) they fail C1–C5
     (`OTHER-IF`, `OTHER-IF`, `ARGUMENT`, `LAMBDA-BODY`, `LAMBDA-BODY`), so they are not vacuous. C6 and C7 are controls.
   - P6 on a scratch copy of the real `Formatted.lean`: the baseline is `TAIL`. A one-site rename still gives `TAIL`
     (via `then-branch, let-body, let-body`), which confirms the worker's first P6 was vacuous. The all-sites rename
     gives `OTHER-IF`, so the fix works.
   - P7 (`lemSeqX`) gives `LAMBDA-BODY`.
   - My own plants on `hack_lemFuel` all read `LAMBDA-BODY`, as they should: continuation binder `fun u =>`;
     `failwithI` placed in the discarded first lambda; a third lambda argument (`lemSeq a (fun _ => ()) cont`);
     head `lemSeq'`.
5. **Register.** The `step_fs_proc` row is re-keyed (`… := (fun (` → `… : String `, seal `870ea9e4…` → `644d4975…`).
   It keeps `EXEC LAMBDA-BODY NON-TAIL/LAMBDA-BODY UNREACHABLE-BY-INVARIANT` and the review text, byte-identical.
   The `valueFromMemValue` row only moved; its content and seal are identical.
6. **Proofs.** Both edits add `lemSeq` to a `simp only` set. The Driver edit also drops `CerbDebug.print_debug_pure`,
   and `hack_lemFuel`'s only debug site is now a `lemSeq` head (`Driver.lean:480`). The generated proof copies are byte-equal to the sources.
7. **Records.**
   - The quotes of D1, D2 and LP4/OM4 match lem-lean `doc/lean-backend/2026-09-28_linksem-findings.md:536-537,577` verbatim.
   - SUPPORTED's "ten Lem parity XFAILs (two string, five ruled, three open: A5 twice and A1-R)" matches
     `tests/comprehensive/parity/expected_failures.txt` at `77ad4fa` (10 rows: 2 `fix`, 5 `ruled`, 3 `open`). The old "four" matches `c2a68e7`.
   - Derived tallies I re-counted match: `lem_if` 0 → 1146, `never_extract` 11 → 20, `lemFunctionalBeq` 0 → 65,
     and 65 lem-generated files differing (my 78 differing files = 65 + 13 stale hand-written copies in the primary checkout).
   - The consumer note's cerberus-sl citations (`Env.lean:51`, `DriverGlobals.lean:90,201`, at cerberus-sl `6157ca1`)
     quote the old shape as stated. No cerberus-sl `.lean` file names `lemFailStop`/`lemSetExitOnPanic`.
8. **Running ladder (read-only).** The ladder runs with the switch lem at `77ad4fa`. Its A1 stdout
   (`.tmp/release/20260930T233945.159350Z/A1`) has the same verdict lines as the record §5, including
   `check_failure_reach: SELFTEST OK (7 plants …` and
   `check_fork_drift: OK — … lem-pin 77ad4facfc60814a4a3f5d09dc88168ca208b285 matches lem -v lean-backend-v0.1.0-alpha.1-20-g77ad4fa (hex p…`.
   A1–A4 were `PASSED` when I finished.

## What I could not verify

- The ladder had not reached `=== RELEASE EXIT` (A4b was running at 23:46Z). Rows after A4 are unobserved here and are
  the orchestrator's to re-verify.
- The plants P1–P7 themselves were not run end to end: my worktree has no build, and building was barred while
  the ladder ran. I tested them at classifier level on copies of the arc worktree's generated files; the ladder's
  A1 ran the real selftest.
- I did not rebuild the proofs (no builds). Their correctness rests on the arc build (record §3) and the ladder's A1.
- I did not re-derive the oracle with a `c2a68e7` lem binary: the switch was already upgraded. Byte-identity is shown
  against an earlier independent generation, not a controlled A/B.
