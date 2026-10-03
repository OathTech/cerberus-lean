# Pre-merge audit: `fix/mirror-upstream-d38-alignas` (`d6c548847..958964423`), 2026-10-03

Auditor: Claude (Opus 5.5), a fresh pre-merge auditor briefed by the orchestrator. Worktree
`worktrees/cerberus-lean-audit/mirror-upstream-d38`, branch `audit/mirror-upstream-d38-alignas`.
Scope approved by the operator, verbatim: [USER 2026-10-03] "Yes, go ahead with the audit as
proposed". The range has 3 commits: `6bdb59006` (revert draft 38), `3bd1623d9` (`_Alignas`
completeness check), `958964423` (VALIDATION §3b). Slice record:
`lean_frontend/docs/2026-10-03_mirror-upstream-d38-alignas-record.md`.

Box discipline: no builds. Probes ran one at a time under
`cerberus-lean/scripts/capped` (`CERB_MEM_MAX=4G`, 30 s `timeout`). They used the binaries
already built in the slice worktree `worktrees/cerberus-lean-fix/mirror-upstream-d38-alignas`
and its pristine build `.validation-foundations/independent-oracle-v2` (`b9aeedcb4`). That worktree
was never written to. Its full ladder (`.tmp/m38-full.log`) was running throughout.

## Verdict

**MERGEABLE WITH FIXES** [AGENT]. The code and every pin are what the rulings ask for, and I
re-measured them. The one required fix is documentation only (F1): three sentences say `node` is
the only pristine-side timeout the register admits. Task 2 made that false.

## Findings (ranked)

### F1 (LOW, must fix: doc/register accuracy). "Only pristine-side incomplete" is stale after task 2

Task 2 added `coverage/alignas/alignas-001-self-char.c` to the register with
`"upstream": {"status": 124, …}`. That row's own rationale ends: "A pristine-side timeout is
admitted only through this cited class." Three texts in the slice still say `node` is the only one:

- `scripts/upstream_oracle_differences.json:11` (the `multi_tu_tray/node` rationale, rewritten in
  `6bdb59006`): "Class shared-model-fix (draft 37 alone): the ONLY pristine-side incomplete this
  register admits".
- `lean_frontend/VALIDATION.md:559` (in the hunk rewritten by this slice): "30 s bound — the ONLY
  pristine-side incomplete the register admits)."
- `scripts/LADDER.md:82` (row 10, edited by this slice): "a ONE-sided pristine timeout is admitted
  only through a cited resource/shared-model-fix row (today: `multi_tu_tray/node`, draft 37)".

`tests/multi_tu_tray/README.md:34` says "the one pristine-side timeout the register admits". That
is also untrue register-wide, though its context is the tray.

The lane's behaviour is right: any cited row admits a one-sided pristine 124. Only the prose is
wrong. Fix: name both rows (`multi_tu_tray/node`, draft 37; `coverage/alignas/alignas-001`,
draft 47), or drop the "only" claim. Editing the rationale changes no signature.

### F2 (INFO, declared gap). No gate pins the Lean refusal on `alignas-001..003`

`scripts/exec_coverage_baseline.txt` records the three cases as `CERB_SKIP`, so the exec lane
never samples Lean on them. The pristine lane compares fork against pristine only. The slice
declares this itself (VALIDATION §3: "The record's three-engine table is the evidence for that; no
pinned lane row covers it."). I re-measured it (below), and Lean refuses at the oracle's
location. A future front-end-reject pin, like `test_bytes.sh`'s, would make it a gate. This does
not block the merge.

### F3 (INFO, comment wording). "The same check as AilEalignof's"

`frontend/model/cabs_to_ail.lem` (`desugar_alignment_specifier`, `AS_type` arm) tests
`AilTypesAux.is_function ty` and then `E.is_incomplete ty`. Upstream's `AilEalignof`
(`deps/cerberus-upstream/frontend/model/ail/genTyping.lem:1538-1545`) tests the same condition,
`if AAux.is_function ty || AAux.is_incomplete sigm ty`. It also runs `wf_lvalue sigm qs ty`,
the `E.add` standard annotations and `with_cursor_from (locOf ty) loc`, which the new arm does not.
The condition and the constraint constructor match, so this is the completeness check only, as
ruled. "Same check" is accurate about the condition but not the surrounding steps. No change is
required.

### Out of range (not a slice finding)

`lean_frontend/VALIDATION.md:818` still gives the row-10 corpus as "855 cases". The slice's own
runs give 996 cases after task 1 and 1000 after task 2. This text predates the range.

## What I verified

### 1. Revert fidelity

- `diff deps/cerberus-upstream/frontend/model/core_eval.lem frontend/model/core_eval.lem`: the
  only output is `1200a1201,1232`. Lines 1-1200 are byte-identical to pristine, including both
  `PEmemberof` arms. The 32 appended lines are Lean-only `declare {lean} fuel` /
  `fuel_measure` declares for `pull_constrained`, `step_eval_pexpr`, `eval_pexpr_aux2` and
  `eval_pexpr_aux_broken`, with their comments. They have no OCaml effect.
- `sha256(frontend/model/core_eval.lem)` = `e1fc98edcbfe16b0…`. This equals
  `git show dbe633ec5~1:frontend/model/core_eval.lem | sha256sum`, the pre-D3 pin. The value at
  `d6c548847` was `4ade27ce…`. Both match the manifest note.
- The generated `core_eval.ml` in the slice worktree (both `ocaml_frontend/generated/` and
  `_build/default/…`) is `cmp`-identical to `deps/cerberus-upstream/ocaml_frontend/generated/core_eval.ml`.
  Its sha256 `0265df0c…` also equals the independent pristine build's (upstream Lem `3802cb0`),
  per the manifest `generated.files["core_eval.ml"]` and the file itself. Its layer-2 delta hash is
  `e3b0c442…` (the empty diff), so removing the `core_eval.ml` manifest row is correct.
- The generated Lean `Core_eval.lean` struct arm has no `are_compatible` call. Its two
  `are_compatible` occurrences are the `PEare_compatible` arms, which upstream has too
  (`core_eval.lem:305,1090-1103`).
- Drafts 37/39 are untouched: `git diff --stat d6c548847..958964423 -- frontend/model/ctype_aux.lem`
  is empty, and the file's last commit is still `dbe633ec5`.

### 2. `_Alignas`

- The only `.lem` change besides `core_eval.lem` is the `AS_type` arm of
  `desugar_alignment_specifier` (+19/−2). `sha256(frontend/model/cabs_to_ail.lem)` =
  `d16c0201…`, which is `git show cf4af48f8:frontend/model/cabs_to_ail.lem | sha256sum`.
- `diff upstream/ctype_aux.lem fork/ctype_aux.lem` shows:
  - Lean-only material: `extra_import`s; the C1 comment plus `with_tagDefs`, whose OCaml target is
    redirected to `Tags.with_tagDefs`; the `lean target_rep` and `reader` declares for `tagDefs`;
    and the trailing fuel / `fuel_measure` declares.
  - Draft 37: the `assumed` list threaded through `are_compatible_aux`, with
    `if List.elem (tag1, tag2) assumed then true else` at both tag arms.
  - Draft 39: `(n1_opt, n1_opt)` → `(n1_opt, n2_opt)`.

  Nothing else differs. Both `(*TODO alignment*)` placeholders are intact, at fork
  `ctype_aux.lem:141,184` (upstream `:120,162`).
- Leak grep for `member_alignment|equivalent_member_alignments|identical_alignment_specifiers|member_alignment_specifiers_supported`:
  - over the audit worktree tree (excluding `.git`/`.lake`/`_opam`): only
    `lean_frontend/docs/2026-10-03_mirror-upstream-d38-alignas-record.md:288-289`, the "NOT TAKEN"
    list;
  - over the slice worktree's generated trees (`ocaml_frontend/generated`,
    `_build/default/ocaml_frontend/generated`, `lean_frontend/generated`): no hits.
  - `tests/multi_tu_tray/` has no `align-*` cases.
- Fork-drift pins, recomputed with the gate's own formula
  (`diff -u --label upstream/F --label fork/F … | sha256sum`, `check_fork_drift.sh:243-244`):

  | file | delta hash | manifest |
  |---|---|---|
  | `cabs_to_ail.ml` | `18f2c651a024f90e…` | `18f2c651…` |
  | `ctype_aux.ml` | `977ee22d68c7527e…` | `977ee22d…`, unchanged |
  | `core_eval.ml` | `e3b0c442…` | row removed |

  `diff -rq` between the two generated trees lists 30 files, matching "Layer 2 stays at 30".
- Reachability spot-check. `tests/immaculate/nolibc/d3-s3-alignas-enum.c`
  (`_Alignas(enum E) int i`) is the only corpus file outside `tests/coverage/alignas/` that uses
  `_Alignas` with a tag type in a member. It still gives `Defined {value: "Specified(7)", …}` rc 0
  on fork, Lean and pristine (stdout sha `aac62ecb…` on all three).

### 3. Moved rows, re-measured (2026-10-03, single probes, capped)

Invocations follow `scripts/test_multi_tu.sh:150-193` and `scripts/test_upstream_oracle.py:349-402,888-898`:

- **fork:** `main.exe --runtime=<slice>/_build/install/default --exec --batch --nolibc --mode=exhaustive`;
- **pristine:** the manifest's `oracle.path` and `runtime.root`, under the manifest `environment`;
- **Lean:** the fork's `--cabs-json` per TU, then `cerberus-lean --batch` with
  `CERB_INSTALL_PREFIX=<slice>/_build/install/default LEAN_ABORT_ON_PANIC=1`.

`NO_COLOR=1 TERM=dumb` on all three.

My first Lean attempt passed `--runtime` after `--batch` and was refused (Z-24, canonical
position). The lane's own mechanism is `CERB_INSTALL_PREFIX` (`common.sh:340`), so I used that.

Results. Stdout is verbatim; `Time spent` trailers are omitted.

```
[fork node] rc=1 stdout_sha=a5e73a6c5488
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(531, SD_Id("node")) vs Symbol(502, SD_Id("node"))'"}
[lean node] rc=1 stdout_sha=7f7edc52b846
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(48, SD_Id("node")) vs Symbol(19, SD_Id("node"))'"}
[pristine node] rc=124 stdout_sha=e3b0c44298fc
[fork arr-2-2-return] rc=1 stdout_sha=f23535f5c012
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(558, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}
[lean arr-2-2-return] rc=1 stdout_sha=7a2e201ed24d
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(76, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"}
[pristine arr-2-2-return] rc=1 stdout_sha=f23535f5c012
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(558, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}
[fork arr-incomplete-ptr-return] rc=1 stdout_sha=5f02936e5679
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(536, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}
[lean arr-incomplete-ptr-return] rc=1 stdout_sha=7c304d3e5937
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(53, SD_Id("S")) vs Symbol(19, SD_Id("S"))'"}
[pristine arr-incomplete-ptr-return] rc=1 stdout_sha=5f02936e5679
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(536, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}
```

Derived from the lines above:

- Fork and pristine are byte-equal on `arr-2-2-return` and `arr-incomplete-ptr-return`. Their
  stdout shas, `f23535f5…` and `5f02936e…`, are exactly the `upstream` signatures of the two
  register rows the slice deleted, so deleting those rows is correct.
- On `node`, the fork side `1 / a5e73a6c… / e3b0c442…` (projected stderr computed with the lane's
  own `project_diagnostics`) equals the rewritten register row. The pristine side
  `124 / e3b0c442… / e3b0c442…` equals the row's `upstream` signature.
- Lean differs from the fork only in symbol numbers, which is what row 6b's `failure-class`
  projection elides.

These match the record's §1.4 table, symbol numbers included.

The `_Alignas` witnesses, verbatim. Stderr is shown to the first line; the rest is the source
line, a caret and the §6.5.3.4#1 text.

```
[fork alignas-001-self-char] rc=1 stdout_sha=e3b0c44298fc
tests/coverage/alignas/alignas-001-self-char.c:6:36: error: constraint violation: invalid application of '_Alignof' to an incomplete type 'struct A'
[lean alignas-001-self-char] rc=1 stdout_sha=163d53928a94
Error {msg: "desugaring failed at tests/coverage/alignas/alignas-001-self-char.c:6:36-37"}
[pristine alignas-001-self-char] rc=124 stdout_sha=e3b0c44298fc
[fork alignas-002-fwd-char] rc=1 stdout_sha=e3b0c44298fc
tests/coverage/alignas/alignas-002-fwd-char.c:6:38: error: constraint violation: invalid application of '_Alignof' to an incomplete type 'struct Fwd'
[lean alignas-002-fwd-char] rc=1 stdout_sha=a281af3ddcb5
Error {msg: "desugaring failed at tests/coverage/alignas/alignas-002-fwd-char.c:6:38-39"}
[pristine alignas-002-fwd-char] rc=125 stdout_sha=e3b0c44298fc
cerberus: internal error, uncaught exception:
          Not_found
[fork alignas-003-self-int] rc=1 stdout_sha=e3b0c44298fc
tests/coverage/alignas/alignas-003-self-int.c:5:35: error: constraint violation: invalid application of '_Alignof' to an incomplete type 'struct A'
[lean alignas-003-self-int] rc=1 stdout_sha=accd0c0ab1cf
Error {msg: "desugaring failed at tests/coverage/alignas/alignas-003-self-int.c:5:35-36"}
[pristine alignas-003-self-int] rc=125 stdout_sha=e3b0c44298fc
cerberus: internal error, uncaught exception:
          Not_found
[fork alignas-004-complete-control] rc=0 stdout_sha=18062ceef44b
Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
[lean alignas-004-complete-control] rc=0 stdout_sha=18062ceef44b
Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
[pristine alignas-004-complete-control] rc=0 stdout_sha=18062ceef44b
Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
```

Projected-stderr shas came from the lane's `project_diagnostics`, imported from
`scripts/test_upstream_oracle.py`. They equal all three new register rows on both sides:

| side | 001 | 002 | 003 |
|---|---|---|---|
| fork | `ddcfc8c9…` | `6220abb7…` | `f52fb05c…` |
| pristine | `e3b0c442…` | `a99db77e…` | `a81fc0c4…` |

Statuses: fork 1/1/1; pristine 124/125/125.

The other moved items:

- **Exec coverage baseline.** The four new rows (3 `CERB_SKIP`, 1 `MATCH`) agree with the probes:
  the oracle has no batch verdict on 001-003, and 004 agrees.
- **gcc ledger.** It does not move, and should not: `test_gcc_oracle.sh:179` walks
  `tests/minimal tests/debug tests/float tests/immaculate/nolibc`, not `tests/coverage`.
- **LADDER row 10 plant.** The plant now withholds `minimal/112-…` instead of `arr-2-2-return`.
  This follows from `test_upstream_oracle.py:930-938`: it takes the first `shared-model-fix` row
  whose pristine status is not incomplete, in corpus order, and `minimal` comes first. The
  remaining such rows are the four allocator rows, plus 002/003 (rc 125, a crash, not
  incomplete).
- **Row-10 counts.** The record gives 996 cases after task 1 (2 moved to `semantic_agreement`) and
  1000 after task 2 (+1 agreement, +3 `reviewed_difference`). The arithmetic is consistent with
  the register: 5 rows, then 8.
- **Docs.** The tray README, drafts 38/39/47, INDEX and TODO edits describe the measured state.
  Drafts 38/39 keep their historical sections, labelled as such.

### 4. VALIDATION §3b

- The table has exactly five rows, which name:
  - `--address-space-top` with `Interface.AdmittedTop`;
  - the run digest with `AdequacyG.adequacy_wp_G`'s `rs.sym_digest = P.digest`;
  - the enum reader;
  - the tuple-arity matcher with `RoundThread.pick_complete` / `pcall_complete`;
  - `CerbND.runNDFuel` / `fuelExhaustedKill` with `Interface.oomOutcome`.
- The cited records exist:
  - `docs/2026-09-17_address-space-bound-part-two-record.md`;
  - `2026-09-22_run-digest-as-state-record.md`;
  - `2026-09-20_program-data-parameters-EA-DA-record.md`;
  - `2026-09-20_match-pattern-arity-record.md`.
- The cited code exists: the unit exes `enum-data-test` and `match-pattern-arity-test`
  (`lean_frontend/lakefile.toml:323,339`), `CerbND.fuelExhaustedKill` / `runNDFuel`
  (`lean_frontend/CerbND.lean:98,117`), and the OOM text (`memory/concrete/impl_mem.ml:1291,1296`).
- In cerberus-sl `12d247c`, read-only `git grep`, every consumer name occurs in `*.lean` files.
  For example, `AdmittedTop` in 82 files, `adequacy_wp_G` in 8 and `pick_complete` in 7.
- The slice touches none of the five. Its non-doc files are only `cabs_to_ail.lem`,
  `core_eval.lem`, the exec-coverage baseline, the fork-drift manifest, the register and the four
  `alignas` tests. `git diff` +/- lines over `frontend scripts tests` contain none of
  `runNDFuel|sym_digest|address_space_top|enum_definitions|match_pattern|typecheck_pattern|fuelExhausted|oomOutcome`.
- Corroboration of "cerberus-sl does not rely on cross-TU `PEmemberof`", at grep level:
  - cerberus-sl's `PEmemberof` hits (8 files) are all structural: substitution, erasure, children
    and `pull_constrained` cases.
  - No hit is a lemma about the evaluation arm's tag guard.
  - Its pin `2b51d2a57` contains D3, so the claim is the material one.
  - cerberus-sl refuses `_Alignas` members at `recon` (`Corpus/Capture/Recon.lean:258`,
    `Recon/IR.lean:57`), so the new completeness check cannot reach its programs.

## What I could not verify

- **The full ladder at `958964423`.** It was still running in the slice worktree during this
  audit: Tier A 17 `PASSED`, 0 `FAILED`, at `RUN B1` when last read. Its verdict is not observed
  here and must be read from `.tmp/m38-full.log` before the merge.
- **Fork-binary freshness against `958964423`.** I did not run `tools/check_driver_fresh.sh` (no
  builds, no writes in the slice worktree). Two things support freshness:
  - every probe reproduced the committed register signatures;
  - task 3 (`958964423`) is docs-only.
- **The pristine-oracle lane and its plants.** I did not re-run them in full. I re-measured only
  the 7 cases above, plus the d3 enum witness.
- **gcc columns.** I took them from the record; I did not run gcc.
- **cerberus-sl's statement.** I can only corroborate it at grep level, not prove it.

## Scratch

Probe scratch was `worktrees/cerberus-lean-audit/mirror-upstream-d38/.tmp/audit/`. It was deleted
before this commit.
