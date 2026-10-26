# Pre-merge review: feature/inner-arg-temps at b2ae427d6 (13 commits over mdd/cerberus-lean 1bb518576)

Reviewer: fresh, independent. All judgements below are [AGENT 2026-10-26, reviewer].
Worktree: `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-feature/inner-arg-temps`.
Scratch: `/home/dev/projects/cerberus-lean-proj/.tmp/review-iat/` (captures, probes, control runtime; ephemeral).

## Verdict

**NOT MERGEABLE at this tip; MERGEABLE WITH FIXES.** The semantic content of the
slice (two exact upstream backports, the driver arms, the printer repair, the loader
detector, the matched-mode lane and its set/sequence contract, the B10.1 register row)
checks out under my own probes. What blocks is the rebase: the branch was moved onto the
landed outcome protocol and the stderr switch-report channel, plus two rebase resolutions,
are incompatible with it. On this exact tip Tier A row 1 (two helper checks), row 14
(the PNVI trust surface), row 15 (the new trust surface) and Tier B row 9 will be red.
These are mechanical fixes (P1-1, P1-2) but they touch the protocol decoder and the
battery must be re-run on the fixed tip; the 44/44 result in the records is for the
pre-rebase tree `c1ec77ddc`, not for the merge candidate.

## Scope and what I ran

Read, in the briefed order: both CLAUDE.md files, the charter and amendments, the slice
record, the I0b record, the five park events (recursive-main park, libc park, transport
record, the 10-22 "completion record" which is the multiplicity park, the 10-23 oracle
park), the 10-23 I3 completion record, the 10-25 close-out, the consumer note, tray
drafts 64/65/66 and the tray-15/INDEX/backport-note diffs, LADDER/VALIDATION/SUPPORTED/
TODO/README diffs, the complete code diff `git diff 1bb518576..b2ae427d6` for the lem
model, both std.core variants, the three printer files, Main.lean, CoreParser.lean,
CerbDriverConfig/CerbQuote/CerbMem, the unit tests, every touched script, the manifest,
the register, the baseline, and all 13 commit messages. I did not run lake/dune/make,
any lane script, or release.py; I ran the built oracle and Lean driver on scratch inputs,
`scripts/libc_prep.sh --jsons` into scratch (to obtain the twelve metadata TUs), gcc,
and imported `observations.py` / `pnvi_lane.py` / `test_upstream_oracle.py` from scratch
Python.

Commands (verbatim, from the worktree root unless noted):

```sh
# backport exactness: hunk lines of the upstream commits vs the slice's hunks; witnesses byte-equal
diff <(git diff f10329b44^ f10329b44 -- frontend/model/translation.lem | grep '^[+-]' | grep -v '^[+-][+-]') <(git diff 1bb518576 b2ae427d6 -- frontend/model/translation.lem | grep '^[+-]' | grep -v '^[+-][+-]')
for f in frontend/model/translation_aux.lem runtime/libcore/std.core runtime/libcore/std_inner_arg_temps.core; do diff <(git diff 3230aa494^ 3230aa494 -- $f | grep '^[+-]' | grep -v '^[+-][+-]') <(git diff 1bb518576 b2ae427d6 -- $f | grep '^[+-]' | grep -v '^[+-][+-]'); done
git diff --stat f10329b44:tests/ci/0344-ptr-to-_Bool-param.c b2ae427d6:tests/ci/0344-ptr-to-_Bool-param.c   # (and the three other witness/expected files)
# pre-rebase vs post-rebase diff-of-diffs
diff <(git diff e32c16709 refs/snapshots/inner-arg-temps-prerebase-20261026 -- lean_frontend/Main.lean | grep '^[+-]' | grep -v '^[+-][+-]') <(git diff 1bb518576 9756f6a60 -- lean_frontend/Main.lean | grep '^[+-]' | grep -v '^[+-][+-]')   # (also LADDER.md, check_cabs_json_utf8.sh, check_runtime_resolution.sh)
# what a completed run puts on each stream, and the rebased helpers' shape
LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=4G ./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean --batch --runtime=_build/install/default tests/fixtures/001-return-literal/cabs.json > .tmp/review-iat/cap/fx001.stdout 2> .tmp/review-iat/cap/fx001.stderr
bash -c 'set -uo pipefail; W=.tmp/review-iat/cap; OUT=$(cat "$W/fx001.stdout" "$W/fx001.stderr"); [[ "$OUT" != "Defined {value: \"Specified(42)\", stdout: \"\", stderr: \"\", blocked: \"false\"}" ]] && echo "OUT mismatch"; [[ "$ERR" != "cerberus-lean switches: []" ]]'
# B10.1 causal control: fork binary, scratch runtime copy, std.core swapped to the mainline (pre-I0b) text
cp -rL _build/install/default/lib/cerberus-lib/runtime .tmp/review-iat/ctl/pfx/lib/cerberus-lib/
NO_COLOR=1 TERM=dumb CERB_MEM_MAX=4G ./scripts/capped timeout 60s _build/default/backend/driver/main.exe --runtime=.tmp/review-iat/ctl/pfx --exec --batch --nolibc tests/immaculate/nolibc/zd-z2fl03-nan-to-int.c   # once with the current std.core, once after: git show 1bb518576:runtime/libcore/std.core > .tmp/review-iat/ctl/pfx/lib/cerberus-lib/runtime/libcore/std.core
(cd scripts && python3 -I -c "import sys,hashlib; sys.path.insert(0,'.'); from test_upstream_oracle import project_diagnostics; ...")   # sha256 of project_diagnostics(stderr) for both captures
# codec on real captures: default, switched, both dump/mode mismatches, --call under the switch, a planted parameter rebinding, a good switched libc run
scripts/ce scripts/libc_prep.sh --jsons .tmp/review-iat/meta > .tmp/review-iat/meta/paths.txt
LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=4G ./scripts/capped timeout 300s lean_frontend/.lake/build/bin/cerberus-lean --batch --runtime=_build/install/default --switches=inner_arg_temps --libc tests/libc/libc.core --libc-tu … tests/fixtures/001-return-literal/cabs.json   # (and the other five variants; captures under .tmp/review-iat/stops/)
(cd scripts && python3 -I -c "import sys; sys.path.insert(0,'.'); import observations as obs; from pnvi_lane import classify_side; ...")   # decode_stop / parse / classify_side on each capture prefix
# own C probes: oracle --cabs-json, oracle --exec --batch --mode=exhaustive [--switches=inner_arg_temps], Lean --batch [--switches=inner_arg_temps], gcc -std=c11 -Wall -Wextra -O0
# (.tmp/review-iat/probes/p1..p7; verdict multisets compared per mode; see "Probes" below)
# Normal-mode _fav sweep: oracle --nolibc --pp=core over tests/minimal/*.c + the probes, grep '_fav[0-9]'
# symbol-number census of both libc dumps
_build/default/backend/driver/main.exe --runtime=_build/install/default [--switches=inner_arg_temps] --nolibc -d5 --pp=core --pp_core_out=.tmp/review-iat/d5/<variant>.d5.core _build/default/runtime/libc/<variant>.co
python3 -I .tmp/review-iat/scripts/name_numbers.py .tmp/review-iat/d5/<variant>.d5.core
python3 -I .tmp/review-iat/scripts/dup_binders.py tests/libc/<variant>.core
# manifest / pin hashes vs tree
sha256sum ocaml_frontend/pprinters/pp_core.ml ocaml_frontend/pprinters/pp_symbol.ml ocaml_frontend/pprinters/pp_symbol.mli frontend/model/translation.lem frontend/model/translation_aux.lem runtime/libcore/std.core runtime/libcore/std_inner_arg_temps.core tests/libc/libc.core tests/libc/libc_inner_arg_temps.core
```

## Findings

### P1-1. On the rebased tip, every completed Lean run is INVALID to the landed stop decoder: rows 14 and 15 (both trust surfaces) and B9 are red

- Where: `lean_frontend/Main.lean:2019-2020` (the stderr report emission);
  `scripts/observations.py:761` (`decode_stop`: any stderr line in the non-panic branch
  that is not a stop envelope is `problem('stderr', …, 'unrecognized diagnostic or
  unreviewed panic origin')`); `scripts/pnvi_lane.py:146-147` (`classify_side`: any
  decoder problem on a Lean capture returns `('INVALID', 'stop protocol: …')`);
  `scripts/inner_arg_temps_lane.py:269,287` (imports and uses that `classify_side`);
  `scripts/test_observation_lanes.py:48-52` (the slice's `switch_report` plant appends the
  report to the positive control's stderr).
- Claim: the slice's report channel ("completed runs print `cerberus-lean switches: […]`
  on stderr", chosen on 2026-10-21 against the pre-protocol mainline) is incompatible
  with the outcome protocol that landed on mainline on 2026-10-22 (commits a5b7f1f2d …
  c2a161ae4, "reject malformed stops in both lanes"). The protocol treats stderr as a
  structured channel: a line that is neither a stop envelope nor a reviewed panic frame is
  a protocol problem, and both switch lanes map a problem to INVALID. The post-rebase
  adaptation commit b2ae427d6 verified only the sync gate, the build,
  `check_cli_refusals.sh` and `test_stops.py`, none of which decodes a completed run.
- Evidence (my run, this tip): `classify_side` on the capture of a default-mode run of
  fixture 001 (exit 0, stdout the single Defined line, stderr exactly
  `cerberus-lean switches: []`) returns
  `INVALID stop protocol: [StopProblem(channel='stderr', position=SourcePosition(line=1, offset=0), reason='unrecognized diagnostic or unreviewed panic origin')]`;
  identically for the switched run and for a good switched libc run (`libcok`). The
  `--call` refusal decodes cleanly as `CLI_REFUSAL` (boundary `cli`, item `--call`). Since
  `test_pnvi.sh` classifies every Lean capture through the same function
  (`pnvi_lane.py:302`), row 14 is red on this tip even though the slice touches nothing
  PNVI; row 15 is red for the same reason; the B9 control variant that plants the report
  on real captures will assert INVALID where it expects the good outcome.
- Fix: make the report a recognized, reviewed line of the protocol rather than an
  unrecognized one. In `decode_stop`'s non-panic stderr branch
  (`observations.py:752-761`) accept exactly `^cerberus-lean switches: \[[A-Za-z_,]*\]$`
  (record it on the `StopDecode`, e.g. a `reports` list, and keep it out of `problems`);
  require it to appear at most once and never before a panic frame or on stdout (plant
  both); document the line in CONTRACT.md/VALIDATION.md's stop-protocol section and in
  `test_stops.py`. Alternatively, drop the stderr report and keep only the quotation
  header, which is what the consumer actually reads. Either way re-run row 1, 14, 15 and
  B9 on the fixed tip before any merge.

### P1-2. Two row-1 helpers were mis-resolved in the rebase: `ERR` unbound under `set -u`, and `OUT` merges the report into the verdict

- Where: `scripts/check_runtime_resolution.sh:95-104` (`lean()` writes both streams to
  files and sets `OUT=$(cat "$W/stdout" "$W/stderr")`, never `ERR`) versus `:107`
  (`expect_line` asserts `"$ERR" != 'cerberus-lean switches: []'` and `"$OUT" != "$2"`);
  `scripts/check_cabs_json_utf8.sh:84-87` (same `lean()`) versus `:108` (`control` asserts
  `"$OUT" == "$o" && "$ERR" == 'cerberus-lean switches: []'`). Both scripts run under
  `set -uo pipefail` (`:32`, `:25`).
- Claim: pre-rebase the slice split the capture (`OUT` = stdout, `ERR` = stderr) and the
  assertions were consistent; the rebase kept mainline's merged `lean()` (which now feeds
  the mainline `check_refusal` helper from the files) but also kept the slice's `ERR`
  assertions. On this tip the first control aborts the script with
  `ERR: unbound variable`; even with `ERR` set, `OUT` now ends with the report line so
  every exact-line control fails. Both scripts are members of Tier A row 1
  (`scripts/test_unit.sh:461,474`). The adaptation commit's claim that these two files
  changed "only at the resolutions … the switch texts carried into them" is not borne out.
- Evidence: the diff-of-diffs (pre-rebase slice diff vs post-rebase slice diff) shows the
  split-capture hunk present pre-rebase and absent post-rebase for both files; my shell
  simulation of the rebased `lean()`/`expect_line` under `set -u` prints
  `OUT mismatch (merged streams)` and then dies with `bash: line 1: ERR: unbound variable`.
- Fix: in both `lean()` functions set `OUT=$(<"$W/stdout"); ERR=$(<"$W/stderr")` (the
  `check_refusal` helpers already read the files, so the split is safe); re-run both with
  `--selftest`. `check_asm_refusal.sh` kept its split (`LOUT`/`LERR`) and
  `check_union_init_refusals.sh` / `check_item_g_refusals.sh` project the first verdict
  line out of a merged capture, so those are unaffected (not run; read).

### P2-1. The records claim COMPLETE / 44-of-44 for a tree that is not the merge candidate

- Where: `lean_frontend/docs/2026-10-21_codex-charter-inner-arg-temps.md:5` ("COMPLETE on
  the feature branch, full battery passed 2026-10-26"); the 10-25 close-out §Validation;
  the consumer note's first paragraph; `b2ae427d6`'s message says the battery is queued.
- Claim: the 44/44 run was on `c1ec77ddc` (base `e32c16709`). The candidate `b2ae427d6`
  sits on `1bb518576`, which added the outcome protocol, the union-initializer refusal and
  the survey; its own validation is four focused checks. Per P1-1/P1-2 the candidate
  cannot pass as it stands. The charter/close-out status lines read as if the candidate is
  validated.
- Fix: after the fixes, add a dated post-rebase paragraph to the close-out (commit, what
  changed in the rebase, the fresh battery summary verbatim) and point the charter status
  at it; until then the status is "complete pre-rebase; re-validation pending".

### P2-2. The two envelope-less libc refusals are followed by the switch report, and the shipped decoder classifies them as protocol problems, not refusals

- Where: `lean_frontend/Main.lean:885` (`R-IAT-LIBC-SYMBOL-LOSS`), `:918`
  (`IncompatibleCallingConvention`), both `IO.eprintln` + `return .error 2`, after which
  `:2019-2020` prints the report unconditionally; consumer note lines 53-63.
- Evidence: captures `mismatch`, `mismatch2`, `detector` all exit 2 with empty stdout and
  stderr = the refusal line followed by `cerberus-lean switches: [inner_arg_temps]` (or
  `[]`); `decode_stop` reports two `unrecognized diagnostic` problems each;
  `classify_side` → INVALID. The consumer note says the texts are plain stderr with "NO
  envelope" and to match by prefix, but does not say a trailing report line follows, nor
  that the project's own codec will not decode them as refusals.
- Fix: do not print the report after an in-pipeline refusal (gate `:2019` on `code == 0 ||
  code == 1`, or move the report before the exit-2 returns); state in the consumer note
  that these two refusals decode as protocol problems until the `libc` boundary exists
  (TODO.md already names the mover). The envelope-less declaration itself is correctly
  made and the texts are stable (both directions of the dump/mode mismatch name the first
  offending proc `difftime` and the mode; the detector names proc and binder).

### P2-3. Fail-closed transport is not established: the two checks close one shape; both dumps still contain same-named distinct symbols inside procs

- Where: `ocaml_frontend/pprinters/pp_symbol.ml:25-37,58` and `pp_core.ml:790` (per-proc
  collision check: only `SD_FunArgValue` spelling vs bare `SD_Id`/`SD_ObjectAddress`);
  `lean_frontend/CoreParser.lean:2378` (`checkParameterBinders`: only a body binder equal
  to a formal parameter); `lean_frontend/VALIDATION.md:1110` ("Transport still assumes
  different symbols live together have different printed names within a procedure").
- Evidence: printing both `.co` libraries at `-d5` (names as `name{n}`) and grouping by
  name per proc, distinct symbols share a bare name in 7 procs of the variant dump
  (`rev_listFromStr_aux: shifted{330,333}`, `rev_listFromArray_aux: shifted`,
  `decfloat: carry{24539,24545,24555}, tmp{…}`, `div/ldiv/lldiv: div/ldiv/lldiv` twice,
  `vfscanf: tmp{35125,35129}`) and in 10 procs of the Normal dump (the same plus the
  `*_proxy`/`*_procy` `dir_ptr` pairs). None is a parameter rebinding (both detectors
  stay silent, correctly, and `dup_binders.py` finds 0 parameter rebindings), so the
  ordinary dump conflates these by name-interning exactly as tray 65 describes. Whether
  any pair is live together I have not established; the 42-row lane being green in both
  modes says the tested behaviours are unaffected, and this is pre-existing in Normal.
- Assessment: the printer fix is sound for its target (SD_FunArgValue is minted only under
  the switch, `translation.lem:4364-4366,4381`; the prelude creates an object for every
  parameter, `:4426-4447`, so every pristine-printed inner_arg_temps proc with parameters
  trips the loader detector); the Normal-output identity claim holds (0 `_fav` hits over
  120 Normal `--pp=core` outputs; the Normal dump pin and the 52 captured outputs are
  unchanged by hash); the loader cannot over-refuse legal C in any walked corpus because
  user programs never travel as text and both committed dumps load. But "fail-closed
  transport" is a claim the records avoid and the code does not deliver.
- Fix (cheap speedbump, this slice or the queued transport slice): add the `-d5` census to
  `scripts/libc_prep.sh --check` for both variants and fail (or at least print and pin)
  when a bare name maps to more than one symbol number within a proc; the current list
  above would be the reviewed register. The principled fix (numbering every named symbol)
  is already queued in TODO.md.

### P2-4. The fuzzing deliverable is six single-trace comparisons; the committed 1669-file csmith corpus was not used

- Where: `lean_frontend/docs/2026-10-23_inner-arg-temps-closeout-record.md:139-184`;
  `scripts/inner_arg_temps_lane.py:447-479` (`--fuzz` generates fresh seeds);
  `tests/csmith/{small_arrays,small_int_arith,small_mix}` (470 + 1192 + 7 files, the
  Tier C `test_csmith_corpus.sh` population, known to pass the frontend).
- Claim: the charter put a fuzzing round in scope; the round ran 32 fresh seeds of which
  26 fail before execution on both engines in both modes (honestly classified in the
  record), leaving 6 switched comparisons and 6 cross-mode set checks. That is not a
  measurement of the mode. The in-tree corpus exists for exactly this purpose and would
  have given hundreds of executions at the same cost.
- Fix: run the lane's `--fuzz` logic over `tests/csmith/*` under the switch (a
  `--csmith-corpus` population or a Tier C row), record size/time/classes; discrepancies
  are findings as the charter says. Not a merge blocker; the record does not overclaim.

### P3-1. Record file names do not match their contents; the brief counted four parks, the branch has five

- `2026-10-22_inner-arg-temps-completion-record.md` is the multiplicity PARK (its title says
  so); `2026-10-23_inner-arg-temps-closeout-record.md` is the I3 completion record; the
  real close-out is the 10-25 file; the transport record is also a park (the strerror
  acceptance-criterion park). Five park events: recursive-main, libc symbol loss,
  strerror/transport, multiplicity, B10.1. Fix: rename or add a one-line "this file is …"
  header to each; update the charter's cross-reference text accordingly.

### P3-2. Minor text/code inconsistencies

- `lean_frontend/Main.lean:2008` still says "the ONE instance of the switch set" while
  `:1988` builds a second anonymous instance (`@resolveRuntime ⟨switchSet⟩`). Harmless
  (rule W1 greps declared instances), but the comment is now wrong.
- `lean_frontend/Main.lean:202` `libcSymNameOpt` still returns `some s` for
  `SD_FunArgValue` while its doc comment (`:197-200`) says such symbols are not joined;
  dead arm or stale comment, pick one.
- Consumer note `:22` says "Completed runs report … on stderr"; `--pp-core` runs are
  completed runs and are deliberately excluded (`Main.lean:2019`). Say so.
- `scripts/check_cli_refusals.sh:178` replaced the precise "24 refusals pinned: …" OK
  line with prose; the count was useful review evidence.
- Tier A cost: row 15 measured 374-515 s (the record's own numbers) against the "a few
  minutes" placement rationale of row 14; worth a sentence in LADDER row 15.

## What checked out (so the orchestrator need not re-derive it)

- Backports exact: the `+`/`-` lines of `f10329b44` (translation.lem) and `3230aa494`
  (translation_aux.lem, both std.core variants) are identical to the slice's hunks; the
  four witness/expected files are byte-equal to upstream's; `tests/tests.sh` adds the two
  CI names (upstream's intervening `0342` is absent because the fork is at `b9aeedcb4`,
  correct). Manifest `[source-content]` rows for the seven pinned files and both libc
  content pins match the tree by sha256.
- B10.1 register row: exactly one new entry, both signatures bound. With the production
  fork binary and a scratch runtime copy whose `std.core` is swapped to the mainline
  (pre-I0b, upstream-identical) text, `project_diagnostics` of stderr hashes to the
  register's pristine signature `a8aed81e…`; with the current `std.core` it hashes to the
  fork signature `0f7a88b7…`; the projected diff is exactly the two
  `Core_eval.step_eval_pexpr` frames. (Without `NO_COLOR=1 TERM=dumb` the hashes differ
  because of ANSI codes; the lanes set both.)
- Lane contract: `same_sequence` compares the full ordered `full` token tuples from
  `classify_side` within a mode (`inner_arg_temps_lane.py:105-107,300-303`);
  `same_observation_set` compares sets of complete `full` tokens (value, stdout, stderr,
  blocked, Error/UB payloads) on the oracle across modes (`:110-112`). For exhaustive
  rows a multiplicity difference cannot hide an outcome: set equality on complete
  observations is reachability; only path counts are dropped. For `first`-mode rows the
  cross-mode check is a single-trace coincidence (fail-closed, may spuriously flag). The
  baseline pins sorted distinct tokens (`:115-118`), weaker than the PNVI lane's pin by
  design and stated. My probe p4 (`k(s(1), s(2))`) shows the shape: 20+20 observations
  Normal, 1+1 switched, same two outcomes, engines equal within each mode.
- Probes (all exhaustive nolibc, both engines, both modes, gcc 13.3.0): p1 `_Bool`
  parameters via a function pointer with a pointer argument, a fractional float and a null
  pointer (31; 2310 Normal interleavings vs 3 switched); p2 struct by value modified in the
  callee (92); p3 parameter address escaping through recursion (6); p4 unsequenced
  arguments (15/24); p5 parameter writes (912); p6 block-local shadowing of a parameter
  (9); p7 returning a parameter's address (0 on Cerberus; gcc exits 1 because gcc nulls a
  returned local address, not a semantics disagreement). All four-way agreements.
- Normal-mode output identity: 0 `_fav` in 120 Normal `--pp=core` outputs;
  `SD_FunArgValue` is only ever minted under the switch (lem grep); the Normal dump pin is
  unchanged.
- Post-rebase resolutions other than P1-2: Main.lean carries the slice's texts into the
  protocol's `CerbStop.render (.refusal (driverRefusal …))` structure correctly; the
  `--call` refusal as a `cli`/`--call` REFUSAL envelope decodes cleanly (`CLI_REFUSAL`);
  LADDER row 1 carries only the 292→297 parser-check count.
- Recursive-main correction and limits are stated plainly in the consumer note, SUPPORTED
  and README; tray 64/65/66 and the tray-15 status are consistent with the code.
- Witness programs (`tests/inner_arg_temps/*.c`) match their recorded expectations in my
  reading; the baseline has 186 rows (137/41/6/2), the eight non-agreement rows are the
  registered ones, 039 carries its Normal citation.

## Residual uncertainty

- I did not run `test_unit.sh`, either switch lane, B9 or the battery (forbidden by the
  brief); P1-1 rests on `classify_side` applied to my own captures of this tip's driver
  and on reading `test_pnvi.sh`/`pnvi_lane.py`/`test_observation_lanes.py`; P1-2 on
  reading the scripts plus a shell simulation. The queued battery will show both.
- P2-3's name-sharing list is a static census; I did not trace liveness of the shared
  names, so I cannot say whether any current libc behaviour is mis-transported, only that
  the stated assumption is not checked and is violated syntactically.
- The 44/44 pre-rebase result, the 186-row sweep and the fuzzing figures I could not
  reproduce; the records are internally consistent and the baseline/ledger artifacts match
  what they describe.
- Scratch left under `/home/dev/projects/cerberus-lean-proj/.tmp/review-iat/` (captures,
  the pre-I0b scratch runtime, `-d5` dumps ~190k lines, probes); delete when the
  orchestrator has read this.
