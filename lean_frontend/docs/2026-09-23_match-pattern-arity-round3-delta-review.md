# Item 7, closure round 3 — independent pre-merge DELTA review (argument-list arity)

[AGENT — independent delta review, 2026-09-23, Claude Fable subagent chartered by the orchestrator]

**Reviewed range:** `34ac493f9..fda652269` on `fix/match-pattern-arity` (nine commits), of which the DELTA not covered by
the second-round audit (`docs/2026-09-22_match-pattern-arity-rereview.md`, commit `9795c8250`) is: the REBASE replay
(`df85e95b7..b85f5bc83` → `34ac493f9..a92e0ca0f`), `ec02f452d` (charter Addendum A3), `7acc7326b` (round-3 code + tests +
stdlib fix + manifest + records), `fda652269` (record §15.6 + battery evidence). **Head under review:** `fda652269`.
Review worktree: `worktrees/cerberus-lean-audit/item7-round3-review-20260923`, branch `audit/item7-round3-review-20260923`.

**What I did:** read the binding practice docs and the second-round audit first; measured everything cheap — `git
show`/`git diff`/`git range-diff`, per-file interdiffs, `sha256sum` of sources vs the manifest and vs the pristine upstream
checkout (`deps/cerberus-upstream` @ `b9aeedcb4`), sorted-set comparison of the fork-drift manifest, `python3` over the
committed `report.json`, and a sha256 chain from the committed report to the worker's retained lane stdout files (plain
file reads from outside that worktree). **What I did NOT do:** no build of any kind (no `lake`/`dune`/`make`/`lem`/`opam`),
no process with the worker's worktree as cwd, no reading of its `_build`/`.lake`, per the operator's ruling, verbatim:
[USER 2026-09-23] *"I think for this you can run the delta review in a fable subagent. It doesn't require the heavy
rebuild again if nothing has changed."* Consequently, claims that need the built artefacts (the generated Lean/OCaml
delta hashes, the typed-dump byte-identity pins, the libc.co contents) are marked UNVERIFIED-HERE and rest on the committed
evidence plus the orchestrator's independent re-verification (its gate log had not printed `=== ALL DONE` by the time
this document was written: `grep -c '=== ALL DONE' … → 0` at 04:20:52 UTC).

Quoted outputs are verbatim (trimmed with `…` only where marked); tallies I computed are labelled *derived*; every
judgement is [AGENT].

---

## Findings (most severe first)

### F1 — P2: the rebase replay dropped mainline's `moreLinkArgs = ["native/md5.o"]` from the `run-digest-test` stanza

**What.** Mainline `34ac493f9` (the D-S slice, commit `24f19d6f5`) registers `run-digest-test` WITH
`moreLinkArgs = ["native/md5.o"]`. The pre-rebase branch (`b85f5bc83`) added its own `match-pattern-arity-test` stanza WITH
its own `moreLinkArgs` line. The replayed commit `2b035edcc` resolved the `lakefile.toml` conflict by inserting the new
stanza BETWEEN `root = "Unit.RunDigestTest"` and mainline's `moreLinkArgs` line, so at `fda652269` the one surviving
`moreLinkArgs` belongs to `match-pattern-arity-test` and `run-digest-test` has none. Mainline content changed without
intent or record; §14.1 says of this conflict "both sides' additions kept", which is not exact.

**Where.** `lean_frontend/lakefile.toml:319-331` at `fda652269`.

**How verified.**

    $ git show 34ac493f9:lean_frontend/lakefile.toml | sed -n 319,324p
    [[lean_exe]]
    name = "run-digest-test"
    srcDir = "test"
    root = "Unit.RunDigestTest"
    moreLinkArgs = ["native/md5.o"]

    $ git diff 34ac493f9 fda652269 -- lean_frontend/lakefile.toml
    @@ -320,4 +320,12 @@ root = "Unit.EnumDataTest"
     name = "run-digest-test"
     srcDir = "test"
     root = "Unit.RunDigestTest"
    +# match-pattern-arity (2026-09-20, cerberus-sl hidden-state note item 7): match_pattern
    +# and typecheck_pattern fail CLOSED on a tuple-arity mismatch — T1–T3 the consumer's
    +# acceptance facts by rfl (none on mismatch, select_case continues, bindings + order
    +# kept), T4 the negative control, T5 the typechecker's guard (runtime: partial def)
    +[[lean_exe]]
    +name = "match-pattern-arity-test"
    +srcDir = "test"
    +root = "Unit.MatchPatternArityTest"
     moreLinkArgs = ["native/md5.o"]

    $ git show b85f5bc83:lean_frontend/lakefile.toml | grep -n -A6 'name = "enum-data-test"'   (pre-rebase: the new stanza had its OWN line)
    … +moreLinkArgs = ["native/md5.o"]   (range-diff commit 2: pre-rebase `+moreLinkArgs`, replay ` moreLinkArgs` as context)

`git log -S'root = "Unit.RunDigestTest"' 34ac493f9 -- lean_frontend/lakefile.toml` → `24f19d6f5 Make the run minting digest
explicit state data` (the line is D-S's). No package-level `moreLinkArgs` exists (`lakefile.toml:1-3`: `name`,
`defaultTargets`, `moreLeanArgs` only).

**Failure scenario.** `RunDigestTest` imports `Driver` and `CabsImport`; `CerberusFresh.lean` declares
`@[extern "cerb_md5_hex"]`/`"cerb_digest_get"`/`"cerb_digest_set"`/`"cerb_force_thunk"` backed by `native/md5.o`. If any
module in that closure references those symbols, the exe cannot link without `md5.o`. EMPIRICALLY it did link: the
frozen battery's A1 (`Total: 15 passed, 0 failed`, sha256-verified below) built `run-digest-test` in the worker's
worktree — a worktree created 2026-09-20, before D-S existed, so this exe's FIRST link there was already without the
line — and the previous FAST-GATEs report 15/15 too. So today the loss is latent, not live. It remains an unrecorded
mainline change made by a rebase, exactly the class the record-integrity rule is for. UNVERIFIED-HERE: whether the link
success is because nothing in the closure references the externs, or because the linker tolerated it; I did not build.

**Proposed fix.** Restore `moreLinkArgs = ["native/md5.o"]` under `run-digest-test` (both stanzas carry it, as both
sides intended), re-run `scripts/test_unit.sh run-digest-test match-pattern-arity-test` (a relink, seconds) and correct
§14.1's sentence. If the operator prefers, this is small enough to be a post-merge hotfix — but it should not merge
silently. [AGENT]

### F2 — P3: the record does not disclose that 29 recorded artefacts changed DURING the frozen battery (version-string rebuild after the commit)

**What.** `round3-34ac493f9/report.json` has `source_before == source_after` (head `7acc7326b`, empty diff, clean status)
but `artifacts_before != artifacts_after`: 29 of 1,778 entries differ, all under `_build/install/default/` (the OCaml
`Version` module and everything that embeds it: `main.exe`, `cerb_backend.*`, `mem_concrete.*`, `mem_vip.*`, `libc.co`,
`libc_inner_arg_temps.co`, `libm.co`) plus the two freshness stamps. The stamps explain it: before, `commit ec02f452d… +dirty`
(binaries built from the uncommitted round-3 tree); after, `commit 7acc7326b…` (rebuilt once the lanes' build steps saw the
new `git describe`). The Lean binary hash is identical before/after (`bin 1fcbe914…`); the oracle's is not
(`4f62a322… → 53a6698e…`). The runner reports `artifact_issues: []`. The second-round audit explicitly reported "all 1,778
recorded artifact entries are also equal before/after" for ITS run; §15.6 says nothing about artefacts either way.

**How verified** (python3 over the committed report; paths abbreviated `<F>` = the worker's worktree):

    artifact entries before/after: 1778 1778
    differing artifact entries: 29
     - _build/default/backend/driver/main.exe
        before: {'sha256': '4f62a32271f5485eff3ca8c449622b66491296d9bb2997cacea771ab44fae182'}
        after : {'sha256': '53a6698e136defee00ec236bc23886a9a54bdec0887957604dd2ecb148e9c4a4'}
     - _build/install/default/lib/cerberus-lib/frontend/version.ml
        before: {'sha256': '5cdf9ab0aaa043f271165e82a661d0fdc4132769a57b5f3c49f390e807294e40'}
        after : {'sha256': '6d0a4b02e64ce2caa4e809d71d735de1039de1ea9a0e727e3a02c653377ddec6'}
     - _build/install/default/lib/cerberus/runtime/libc/libc.co
        before: {'sha256': '6635d5e5ccd745c1f91fa312014f743c3cb22905016e0c3b6f379125e38f4a4f'}
        after : {'sha256': '538a335ca6895d8a67745e1144b599905ed2a0f4aa36d027431871e3fbce76fe'}
     - driver_fresh.oracle.sha256
        before: {'sha256': '25e973d5…', 'text': 'commit ec02f452db9112e114eb3cdb0da95ab950df9684 +dirty\nbin 4f62a32271f5485eff3ca8c449622b66491296d9bb2997cacea771ab44fae…'}
        after : {'sha256': '1c552bc1…', 'text': 'commit 7acc7326b00bdc80c5ee01d3f1184bc3235468ee\nbin 53a6698e136defee00ec236bc23886a9a54bdec0887957604dd2ecb148e9c4a4\nsrc…'}
    (the other 25 rows: cerb_backend.{cma,cmxa,cmxs}, cerb_backend__Pipeline.{cmt,cmx}, cerb_frontend__Version.{cmi,cmo,cmt,cmx,o} ×3 dirs,
     mem_concrete.{a,cma,cmxa,cmxs}, mem_vip.{a,cma,cmxa,cmxs}, libc_inner_arg_temps.co, libm.co, driver_fresh.lean.sha256)

**Failure scenario.** None found for correctness — the source identity is the trust anchor and it is clean and equal. The
gap is record integrity: lanes before the rebuild ran an oracle stamped `ec02f452d +dirty`, lanes after ran one stamped
`7acc7326b`; the record's "tree frozen" is true of the source, not of the install tree. UNVERIFIED-HERE that the
`libc.co` change is the version header only (it embeds `cerb:git-…` per `libc_prep`'s informational line).

**Proposed fix.** One sentence in §15.6 disclosing the 29 install-tree artefacts and the stamp transition (a docs-only
addition; commit D is the natural place). [AGENT]

### F3 — P3: the round-3 `ccall` predicate accepts ANY `CoreTyping_TODO` message starting with `"ccall"`

**Where.** `lean_frontend/test/Unit/MatchPatternArityTest.lean:495` at `fda652269`:

    | Exception (_, CORE_TYPING (CoreTyping_TODO t)) => ctx == "ccall" && (t.startsWith "ccall")

**Why it matters.** The arm's pre-existing error `"ccall to a variadic C procedure must at least have a list of pointers as
last argument"` (core_typing.lem `:1758` post-change) also starts with `ccall`, so the two variadic rejection rows would
also PASS if the guard were absent and that older error fired. On the actual inputs it cannot fire (`ccallVarE n` always
has the bundle, so `List.dest_init` is `Just`), and the exact messages are printed in `got` and quoted in the record
(§15.3: `CoreTyping_TODO "ccall to a variadic C procedure: fixed-argument list of a different arity …"`), so the evidence
as recorded is sound. The predicate is looser than the `MismatchExpected` rows' exact-match. **Fix:** match the two exact
strings. [AGENT]

### F4 — P3: two small record inaccuracies in §15.2b / §14.1

- §15.2b: "no corpus program calls them (grep over `tests/` empty)" — `git grep -c -i -E 'pread|pwrite' fda652269 -- tests/`
  → `tests/z2-probes/fs/README.md:1` (a note about the Lean FS model's `fs_pwrite`, not a Core caller). The substantive
  claim (no caller) stands; the wording "empty" does not. The load-bearing claim — `git show fda652269:tests/libc/libc.core
  | grep -c -i 'pread\|pwrite'` → `0` — holds.
- §14.1 "both sides' additions kept" for `lakefile.toml` — see F1.

### N — neutral notes

- N1. **Battery head vs record commit.** The battery ran on `7acc7326b` (`source_before.head = source_after.head =
  7acc7326b00bdc80c5ee01d3f1184bc3235468ee`, `status: ""`, `diff_sha256 = e3b0c442…` = sha256 of the empty string).
  `fda652269` is docs-only: `git show --stat fda652269` → the record (`59 +-`), `report.json` (`19920 +`), `summary.txt`
  (`3 +`); nothing else. So the battery covers the reviewed head's product content exactly.
- N2. **The KNOWN GAP** (raised with the worker before this review; commit D pending): `.tmp/mpa/r3/core/` holds
  `run-fixed-short.core` (`save loop … (i: integer := 1) in if i < 2 then run loop() else …` — pre-fix the zero-actual
  shortage keeps `i := 1` and the program loops), `fun-long.core` (`f(1,2,3)`), `proc-long.core` (`pcall(f,1,2,3)`),
  `proc-short.core` (`pcall(f,1)`); none is quoted in §15.1/§15.4. Not re-raised as new; commit D will be checked for
  docs-only + accuracy when its hash arrives.
- N3. The generated trees (`lean_frontend/generated/`, `ocaml_frontend/generated/`) are NOT committed (`git ls-files
  lean_frontend/generated | wc -l` → `0`; `.gitignore:22`). The generated-delta pins (`core_typing.ml d98638c6…`,
  `core_run.ml d9fb64b8…`, `core_reduction.ml bad2eba7…`) are therefore UNVERIFIED-HERE; the committed A1 stdout (sha256-
  verified) shows `check_fork_drift: OK — layer 1: 84 … layer 2: 29 differing generated files, all hash-pinned`, and the
  orchestrator's re-verification regenerates and re-checks them.
- N4. `partial def eraseP`/`eraseE` (the structural erasers the fit checks use) are round-1 helpers extended by round 3;
  they are test-side only (the totality gate scans generated modules + `CerbND`). No `decide`/`native_decide`/`sorry`/
  `bv_decide`/`ofReduce*` anywhere in the test file (`grep -n -E 'native_decide|bv_decide|ofReduce|sorry|\bdecide\b'` → no hits).
- N5. The new `core_run.lem` comment cites its let-form sites as `:885/:1463`; those lines are the `| Nothing ->` heads and
  the `SEU.runE (Exception.fail (Illformed_program "Elet: …"))`/`"Ewseq: …"` payloads are on `:886/:1464`. Same shape, off by
  one line; harmless.
- N6. The manifest gained one blank line (`:386`, in the header just before `[meta]`); the gate is green (84/29). Cosmetic.
- N7. Sandbox note for the operator (required by the harness hook): a first scratch attempt under `/tmp/<mktemp>` was
  denied (that path is write-only here); `nono why --self --path /tmp/item7r3rev.2MU7kN/m_before.txt --op read` printed,
  verbatim: `nono: Configuration parse error: sandbox state path drifted at reload: serialized resolved=/dev/pts/8, actual
  resolved=/dev/null`. No change is needed — `/tmp/claude-1000` is readwrite and was used instead.

---

## R-A — Rebase fidelity

`git range-diff --no-color df85e95b7..b85f5bc83 34ac493f9..a92e0ca0f` (evidence dirs excluded): commits 1, 4, 5 are `=`
(identical); commits 2 and 3 are `!`. Per-file interdiff (my script: strip `index`/hunk headers, compare
`git diff df85e95b7 b85f5bc83 -- f` with `git diff 34ac493f9 a92e0ca0f -- f`), verbatim:

    identical: frontend/model/core_aux.lem
    identical: frontend/model/core_reduction.lem
    identical: frontend/model/core_run.lem
    identical: frontend/model/core_typing.lem
    identical: lean_frontend/Core_aux_lemMeasureProofs.lean
    identical: lean_frontend/docs/2026-09-20_charter-match-pattern-arity.md
    identical: lean_frontend/docs/2026-09-20_match-pattern-arity-record.md
    identical: lean_frontend/docs/upstream-tray/45-core-match-pattern-truncating-zip-arity.md
    identical: lean_frontend/docs/upstream-tray/INDEX.md
    RESIDUAL: lean_frontend/lakefile.toml
    identical: lean_frontend/test/Unit/MatchPatternArityTest.lean
    identical: lean_frontend/TODO.md
    identical: scripts/failure_reach_register.txt
    RESIDUAL: scripts/fork_drift_manifest.txt
    RESIDUAL: scripts/test_unit.sh

The three residuals, classified:
- `scripts/test_unit.sh` — expected: the `"run-digest-test"` entry + comment appear as context between `enum-data-test` and
  `match-pattern-arity-test` (`git diff b85f5bc83 a92e0ca0f -- scripts/test_unit.sh` shows exactly the two D-S lines).
- `scripts/fork_drift_manifest.txt` — expected: the `INTEGRATION 2026-09-23` NOTE; `core_run.lem` pin re-based on
  mainline's `d60d1916…` → combined `f1842550…` (was `1427069b… → 73ba87a3…`); `core_run.ml` `1bcc3642… → 1553e2a8…`
  (was `7d4e9c99… → ab8326bb…`); D-S context hashes (`core_run_aux.lem/.ml`, `implementation.ml`, `symbol.ml`,
  `mini_pipeline.ml`, `translation_effect.ml`). `core_typing`'s pins are the E-A-combined values unchanged from the
  previous audit (`eeed68c8… → fe75fa37…`, `acef776c… → a7674e2f…`); `core_reduction.lem` `cf062e7a…` identical both sides.
- `lean_frontend/lakefile.toml` — NOT the expected "both exes registered" residual alone: see **F1**.

The parent's expectation listed `TODO.md` and "the test's digest arguments" as residuals; measured, both replay
IDENTICALLY (the D-S TODO section and the D-S `core_run_state` field are absorbed by `default`/context, not by branch edits).

## R-B — Round-3 code (`git show 7acc7326b -- frontend/model/`)

Hunks: `core_reduction.lem` 1, `core_run.lem` 1, `core_typing.lem` 7 — every hunk is a guard (plus the variadic zip's
operand `pes → xs`); no other behavioural change in the three files. For each of the seven typing arms the guard is the
FIRST expression under the `Just (…)`/signature binding and PRECEDES the zip; the test is `List.length <formals> <>
List.length <actuals>` (both directions); the else-branch is the pre-existing zip+`E.mapM` verbatim — under equal
lengths a length-preserving map, so the SAME argument list in the SAME order is rebuilt. Constructors: `MismatchExpected
"PEcall" (BTy_tuple bTys) "argument list of a different arity"` (`:766-773` infer; `:1180-1185` check, parenthesised
after `guard_match … >>`), `"memop()"` (`:1705-1712`), `"proc"` (`:1806-1812`), `"run"` (`:1882-1891`); the two `Eccall`
arms use the arm's own pre-existing `CoreTyping_TODO` (`:1759-1770` variadic, `:1776-1780` fixed). NO new
`core_typing_cause` constructor (the delta touches only the three `.lem` files; `git diff --name-status a92e0ca0f
fda652269` lists no `errors.lem`/`core_typing_aux.lem`).

Variadic `Eccall` (`:1741-1770`): `List.dest_init pes` → `Just (xs, last_pe)` FIRST; the guard is `List.length params <>
List.length xs` (fixed prefix only); the zip is now `(List.zip params xs)` (was `pes`); `last_pe` is typechecked
separately as before and appended (`pes' ++ [last_pe']`). The other remaining `List.zip params pes` at `:1794` is inside
the pre-existing `(* else match callconv with … *)` comment (`:1781-1795`). Cited pre-fix line numbers re-checked at
`b85f5bc83`: `sed -n '766p;1174p;1696p;1746p;1752p;1780p;1855p'` → all seven print a `List.zip` line of the named arm;
`core_reduction.lem:1468-1473` and `core_run.lem:1563-1565` print the two `Erun` zips.

Erun runtime guards: `core_reduction.lem:1469-1476` — inside `Step_with_runstate2 (RSK_eval "Erun") begin SEU.read … >>=
function | Nothing -> error … | Just (sym_bTys, cont_expr) -> if List.length sym_bTys <> List.length pes then
SEU.runEU (EU.fail (Errors.Illformed_program "Erun: the argument list does not fit the continuation's parameters")) else
E.foldlM …` — the check precedes the fold that performs `full_eval_pexpr'` and `update_env`; the payload is the same
`SEU.runEU (EU.fail (Errors.Illformed_program …))` as the let-form sites `:362`/`:418` (`TAU_WITH_RUNSTATE "Elet" (SEU.runEU
(EU.fail (Errors.Illformed_program "Elet: the pattern didn't match pe1")))`; here the `TAU_WITH_RUNSTATE` wrapper is the
enclosing `Step_with_runstate2` — the same channel). `core_run.lem:1564-1569` — `if … then SEU.runE (Exception.fail
(Illformed_program "Erun: …")) else let cont_expr' = List.foldl … unsafe_subst_sym_expr …` — precedes the substitution
fold; same shape as `:886`/`:1464` (`SEU.runE (Exception.fail (Illformed_program "Elet: …"))`). Both directions in both.

Generated Lean: not committed (N3); the guards' visibility in `Core_typing.lean` etc. is UNVERIFIED-HERE. The unit test's
33 round-3 rows execute the generated definitions (`typecheck_pexpr`/`infer_pexpr`/`typecheck_expr`, `step_ctx`,
`core_thread_step2`) and all PASS in the sha256-verified A1 stdout, which is the executable witness that the generated code
carries the guards.

## R-C — Stdlib fix (`git show 7acc7326b -- runtime/libcore/`)

Exactly two declarations + one FORK comment per file, nothing else (hunks `@@ -615,8 +615,9 @@` and `@@ -571,8 +571,9 @@`:
`-builtin pwrite (integer, [integer], integer)`/`-builtin pread (integer, pointer, integer)` → `+-- FORK 2026-09-23 …` +
the two four-formal lines). Byte-identity to upstream BEFORE the change, verbatim:

    -- std.core
    ea62fd0ade7a84ade72dbbf22169aa6e819a1a08c5297509ad38fec130a5d060  -            (git show 34ac493f9:runtime/libcore/std.core)
    ea62fd0ade7a84ade72dbbf22169aa6e819a1a08c5297509ad38fec130a5d060  /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/runtime/libcore/std.core
       post (fda652269):
    6f78799f7d7ad93d2dcccd9487004e0e5f742f550f691825c1af878ee9278d11  -
    -- std_inner_arg_temps.core
    baea41cdd170d7f23a446205f5f7679090eac0a9190670b4815eb556862fc6e5  -
    baea41cdd170d7f23a446205f5f7679090eac0a9190670b4815eb556862fc6e5  /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/runtime/libcore/std_inner_arg_temps.core
       post (fda652269):
    7eb4628819de61b5ca997209df88f09545553606f8d8305e530b954093820850  -

(`deps/cerberus-upstream` HEAD = `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` = the manifest's `merge-base`.) Call sites at
`fda652269` pass four: `std.core:674 pcall(<builtin_pwrite>, fd, cs, size, off)`, `:687 pcall(<builtin_pread>, fd, buf, size,
off)`; `std_inner_arg_temps.core:619/:628` likewise. Both runtime arms consume four: `core_reduction_aux.lem:218-236`
(`[Vobject (OVinteger fd_ival); Vlist _ buf_cvals; Vobject (OVinteger size_ival); Vobject (OVinteger off_ival)] -> …
FS_PWRITE fd buf size off | _ -> error "pwrite"`, and the `pread` twin `… FS_PREAD fd bufptr size off | _ -> error "pread"`)
and `core_run.lem:1269-1287` (the same two matches, `Step_fs th_st $ FS_PWRITE …`/`FS_PREAD …`). The tray subsection
describes it accurately as an upstream bug (three formals vs four-value call sites and arms; `runtime/libc/dune` indeed
builds `libc.co libc_inner_arg_temps.co` from both stdlib files — `(targets libc.co libc_inner_arg_temps.co) (deps …
../libcore/std.core ../libcore/std_inner_arg_temps.core …)`). The pin claim holds: `git show fda652269:tests/libc/libc.core |
grep -c -i 'pread\|pwrite'` → `0`. `runtime` is in `check_fork_drift.sh`'s SURFACES (`:89 … sibylfs runtime`), hence the two
new `[files]` + `[source-content]` rows (R-E). UNVERIFIED-HERE: that the rebuilt `libc.co` carries four-argument calls
(needs the build; §15.2b quotes `libc_prep: OK … d93b99cd…` and the rebuild at 01:35:16).

## R-D — Tests (`MatchPatternArityTest.lean`, round-3 section, `+160/-3`)

- GENERATED definitions, not re-implementations: `tP3`/`iP3`/`tE3` call `typecheck_pexpr`/`infer_pexpr`/`typecheck_expr`
  (imports `Core_typing`); `reductionErun` calls `Core_reduction.step_ctx` and pattern-matches the single
  `Step_with_runstate2 (RSK_eval "Erun") m`, running `m runStR4`; `coreRunErun` calls `Core_run.core_thread_step2` and
  matches `Step_tau "Erun" _ m`. Both engines' `Erun`: yes.
- Both directions + zero-actual boundary: the `grid` runs `n ∈ {0,1,2,3}` for a 1-formal `fun` (checking AND inference),
  `proc`, `run`, `memop (Va_end)`, fixed `ccall int(int)`; `n = 0` is the shortage boundary, `n ∈ {2,3}` surplus. R4: 3
  actuals (with `PEerror "surplus"`) / 1 actual / 2 actuals against a 2-parameter label in both engines.
- Fitting controls assert STRUCTURE, not "no error": `keptP`/`keptE` erase the typed result's annotation (`eraseP`/`eraseE`,
  extended with `PEcall`/`PEerror`/`Eproc`/`Erun`/`Ememop`/`Eccall` arms) and compare `== some <input>`; the R4 fits assert
  `.bound true (some Vtrue) (some Vfalse)` (arena = body, both bindings) and `pe == substitutedBody`.
- Variadic `ccall` control: `ccallVarE 1` fit (kept), `ccallVarE 0`/`ccallVarE 2` rejected (see F3 on the predicate).
- No `native_decide`/`decide`/`sorry`; `partial` only on the two round-1 erasers (N4). No fuel/bound numeral: `main` takes
  the fuel from `argv` (`let some fuel := args.head?.bind String.toNat?`), `scripts/test_unit.sh:91` supplies `test_args=(17)`
  (pre-existing since round 1). The `import Core_eval` is round-1 (the `PElet` route), not new.
- Recorded outcome (A1 stdout, sha256 `53b2eb76…` = `report.json`): `Total: 15 passed, 0 failed`; §15.3 lists all 33
  round-3 rows `PASS`.

## R-E — Records

- **§15.1/§15.4** engine rows are quoted from the worker's `.tmp/mpa/r3/prefix-fork*.log`/`postfix-fork.log`; I did not
  re-run them (marker absent); the KNOWN GAP (N2) stands. Line-number cites checked: the seven zips, both runtime zips,
  `:1742` (`E.fail loc (CoreTyping_TODO "ccall to a variadic C procedure must at least have a list of pointers as last
  argument")` at `ec02f452d`), `core_reduction_aux.lem:218-236`, `core_run.lem:1269-1287`, `std.core:618-619`,
  `std_inner_arg_temps.core:574-575` (pre-change positions) — all exact.
- **Rulings verbatim**: [USER 2026-09-23] *"Yes, we will roll R3 / R4 into this as a closure. The digest fix landed on
  main"* and [USER 2026-09-23] *"Yeah, we shoudl fix and file to the tray, per our rule that unambiguous bugs get fixes"*
  appear identically in the charter Addendum A3, record §15 provenance/§15.2b, the tray, TODO.md and the manifest NOTE.
- **N3 closed**: the §7 sentence ("a `.core` input with a mismatched arity now fails Core typing on both fork engines",
  old `:274-275`) is replaced by the exact enforced set (tuple patterns/expressions/`unseq`/`par`; the seven argument-list
  arms; both engines' let-forms and `Erun` at runtime), with the refuted sentence quoted and attributed to N3 — accurate
  against the code. The `Core_aux_lemMeasureProofs.lean` change is comment-only: every changed line begins with `--`; over
  the WHOLE range `git diff 34ac493f9 fda652269 -- lean_frontend/Core_aux_lemMeasureProofs.lean | grep -n '^[+-]\s*\(theorem\|
  lemma\|def\|instance\|abbrev\|structure\|inductive\)'` → no hits. TODO.md deferral (iv) is struck and converted, R4 named.
- **Manifest** (`ec02f452d` → `7acc7326b`, 568 → 594 lines, sorted-set comparison), lines ONLY in before, verbatim:

      100644 cf062e7a0ce3872dd6c7a843207f9205ae8c8c39a7824e2714ac75e22640f052 frontend/model/core_reduction.lem
      100644 f184255014782cc6f8e527c7715249ab60b44abadc02a02fc29bbdfe02ed9170 frontend/model/core_run.lem
      100644 fe75fa375b50c6cdb3713e1e876173cf3e7cdd26918256032d50b1b1e75451d1 frontend/model/core_typing.lem
      1553e2a81e10b96bf0d349577c6e814ad4b53005c988f67f4b12dc6fcbda7ebe core_run.ml
      1c95fd93b067730026f2c9cfde1d1551d0872192f691a6067654bf9ee44395d5 core_reduction.ml
      a7674e2f7375a400582675aa54325cad4172c61601d5d8a06535c9e72c079c00 core_typing.ml

  lines ONLY in after (data rows; the 21 `#` NOTE lines and one blank line omitted here):

      100644 5288a8d8c9c348b8e76458e952eaae9d4e4b1f47f8471b59249ffd04a2d33e37 frontend/model/core_typing.lem
      100644 6824c7754ca3790bb0da30cef02e0a97185bebeca4a37a960d253e6ed75757e1 frontend/model/core_run.lem
      100644 6f78799f7d7ad93d2dcccd9487004e0e5f742f550f691825c1af878ee9278d11 runtime/libcore/std.core
      100644 7eb4628819de61b5ca997209df88f09545553606f8d8305e530b954093820850 runtime/libcore/std_inner_arg_temps.core
      100644 d909e2338157a6d9903abd9e608e87345aa9a68cf1611d07d8327b30fce8719a frontend/model/core_reduction.lem
      bad2eba7e2838b9a7c224bbbd2b1569ecf9f93a09760630a57f751539ee37e47 core_reduction.ml
      d98638c6cd2da684c37fe5685679683280a7233083e53cb988cd44047f4c8262 core_typing.ml
      d9fb64b8e630459b702f48590327ba060b9883f2e8dcb8aee2a4b6973117977c core_run.ml
      runtime/libcore/std.core
      runtime/libcore/std_inner_arg_temps.core

  = exactly 3 lem source re-pins + 3 generated-delta re-pins + 2 `[files]` rows + 2 `[source-content]` rows + NOTEs (two
  dated NOTEs: the round-3 one and the pread/pwrite one) + one blank line (N6). *Derived*: 594 − 568 = 26 = 32 added − 6
  removed. Every re-pinned SOURCE hash recomputed from `git show fda652269:<file> | sha256sum` EQUALS its manifest row
  (`core_typing.lem 5288a8d8…` row 516, `core_run.lem 6824c775…` row 514, `core_reduction.lem d909e233…` row 511,
  `std.core 6f78799f…` row 558, `std_inner_arg_temps.core 7eb46288…` row 559). Section counts at `7acc7326b` (*derived*):
  `[files]` 84 (82 + 2), `[source-content]` 84, `[expected-semantic]` 20 + `[expected-cosmetic]` 9 = 29 differing generated
  files — matching the gate's `84 … 29`. `[meta]`: `merge-base=b9aeedcb4…`, `lem-pin=38f87d5`. The manifest is unchanged by
  `fda652269`.
- **Failure register**: `git diff --stat ec02f452d fda652269 -- scripts/failure_reach_register.txt` → empty; at `fda652269`
  266 lines, 240 non-comment lines = the tab-separated column header (`file definition token msg scope position …`) + 239
  data rows (*derived*: `grep -v '^#' | grep -c -E '^(generated|lean_frontend|frontend|…)'` → `239`), tally
  `sites=239 exec=237 unresolved-owner=2 … UNREACHABLE-BY-INVARIANT=170 REACHABLE=48 UNKNOWN=21 discardable=0`; A1 stdout
  (sha256-verified): `check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly …)`. Every new failure
  in the round-3 hunks is monadic — `E.fail loc (MismatchExpected …)` ×5, `E.fail loc (CoreTyping_TODO …)` ×2,
  `SEU.runEU (EU.fail (Errors.Illformed_program …))`, `SEU.runE (Exception.fail (Illformed_program …))` — no `error`/`failwithI`
  added (the `error ("Erun couldn't resolve label…")` in the same match is pre-existing).

## R-F — Evidence integrity

`summary.txt` (verbatim):

    full: passed; 39/39 selected commands completed successfully.
    Source unchanged: True. Complete tier selection: True.
    Release certification: incomplete: reporting/adoption/audit exits require separate evidence.

`report.json`: `mode: 'full'`, `status: 'passed'`, `source_unchanged: True`, 39 lanes all `passed`, `unrun` = the eight
Tier-C reporting instruments (C1–C8), `started_utc 20260923T023529.025920Z` → `finished_utc 2026-09-23T03:58:20.370683+00:00`
(*derived*: 82.9 min), `source_before`/`source_after` both `{"branch": "fix/match-pattern-arity", "diff_sha256":
"e3b0c442…", "head": "7acc7326b00bdc80c5ee01d3f1184bc3235468ee", "status": "", "untracked_sha256": {}}`;
`external_inputs_before == external_inputs_after`; artefacts: see F2. The lane `stdout` fields are PATHS into the worker's
`.tmp/mpa/r3/full/<lane>/stdout` with committed `stdout_sha256`; I hashed the retained files (plain reads) — all match —
and extracted the lines §15.6 quotes:

    [A1] stdout file exists; sha256 match: True (53b2eb7684a4e451…)
        A1| Total: 15 passed, 0 failed
        A1| check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)
    [B10.1] stdout file exists; sha256 match: True (88ef6a8b4aab3ab8…)
        B10.1| Independent oracle: passed; {'semantic_agreement': 835, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; …
    [B10.2] stdout file exists; sha256 match: True (b83b0ce4fdd07cbe…)
        B10.2| Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; …
    [B12] stdout file exists; sha256 match: True (38303a59989a39b1…)
        B12| Independent oracle: passed; {'semantic_agreement': 4}; …
    [B7] stdout file exists; sha256 match: True (9bbbcc497f7a6894…)
        B7| Baseline check: 0 regression(s), 0 improvement(s)
    ([B7].summaries in report.json: "SUMMARY: total=2014 compared=1929 agree=1917 agree_nd=0 triaged=12 disagree=0 …", "Baseline check: 0 regression(s), 0 improvement(s)")

So §15.6's quotations are verbatim AND anchored to the committed hashes. The reviewed head recorded = `7acc7326b`; the
record commit `fda652269` is docs-only (N1).

## R-G — Proofs

No `*_lemMeasureProofs.lean` STATEMENT changed anywhere in `34ac493f9..fda652269` (only `Core_aux_lemMeasureProofs.lean`
moved: `+28` lines = the round-1 case splits already audited + the round-3 comment). Banned-token grep over the delta's
ADDED non-doc lines (`sorry|axiom|partial|maxRecDepth|maxHeartbeats|native_decide|bv_decide|ofReduce|2>/dev/null|decide`):
one hit, the word "axioms" inside the test's final `IO.println` string. No new axiom/`sorry`/`partial`/option bump.

## R-H — Policy

- Nothing new out of policy: no new gate, no new `lean_exe` (the existing exe is extended), no new `core_typing_cause`
  constructor, no new pure failure leaf (register unchanged), no theorem, no numeral. [USER 2026-09-04] "we don't change
  the lem structure for ocaml" — untouched (guards only). No changed scripts in the delta, hence no `2>/dev/null` question.
- Fence classification of every file in `a92e0ca0f..fda652269`: `frontend/model/{core_typing,core_run,core_reduction}.lem`,
  `Core_aux_lemMeasureProofs.lean` (comment), `MatchPatternArityTest.lean`, `TODO.md`, charter, record, tray 45,
  `fork_drift_manifest.txt`, the closure-evidence dir — INSIDE Addendum A3's fence; `runtime/libcore/{std,
  std_inner_arg_temps}.core` — inside the widened fence ([USER 2026-09-23] ruling); `2026-09-22_match-pattern-arity-rereview*`
  (`9795c8250`) — the auditor's own commit, fast-forwarded, not worker work; `lakefile.toml`/`test_unit.sh` — changed by the
  REBASE only ("only for the rebase" is allowed; see F1 for the content).

## R-I — Merge readiness

`git merge-base --is-ancestor 34ac493f9 fda652269` → exit 0 (ff-able; `mdd/cerberus-lean` checkout is parked at
`34ac493f989bbf3bd3954bba0ba1d05c018e269c`). Pins unchanged by the whole range: `git diff 34ac493f9 fda652269 --
lean_frontend/lake-manifest.json lean_frontend/speclab/lake-manifest.json tests/mem-scale-probes/micro/lake-manifest.json
lean_frontend/lean-toolchain lean_frontend/speclab/lakefile.toml` → empty; `lake-manifest.json` LemLib `"inputRev":
"38f87d5fa6b29ec90edfa457faba8a309e32c118"`; manifest `[meta] lem-pin=38f87d5`; A1: `lem-pin 38f87d5 = lem -v`.

Optional post-marker items (gate-log verdict lines, 2–4 witness probes vs §15.4): NOT done — the marker was absent when
this was written; to be appended in a second commit if it appears before this review closes, together with the commit-D
check.

---

## VERDICT

[AGENT] **Merge-ready after the listed P2 (F1).** The round-3 delta does what Addendum A3 rules: the seven typing arms
and both engines' `Erun` guard the argument count before the zip/evaluation/substitution, both directions, through
existing monadic channels, with no new constructor, leaf, gate, exe, theorem or numeral; the stdlib fix is exactly the two
declarations per file under the operator's verbatim ruling, both files were byte-identical to upstream before it, and the
libc dump pin is unaffected; the manifest moves exactly the expected rows and every source pin recomputes; the records'
line cites, counts and rulings check, N3 is closed accurately, and the frozen battery's certification lines are verbatim
and hash-anchored to the committed report on the exact product content of the reviewed head. The one thing that should
not merge silently is the rebase's unrecorded removal of mainline's `moreLinkArgs` line from `run-digest-test` (F1) —
a one-line restore plus a row-1 relink, or an explicit operator acceptance as a post-merge hotfix; F2–F4 are docs/test
tightenings that can ride on commit D or follow. Merge authority rests with the operator; this document is a review, not
a sign-off.
