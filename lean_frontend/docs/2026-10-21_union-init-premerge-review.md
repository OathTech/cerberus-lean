# Pre-merge review: fix/union-init-refusal @ f8afa8a1d (one commit over mdd/cerberus-lean e32c16709)

Reviewer: Claude Fable 5.1, fresh and independent; every judgement here is tagged [AGENT 2026-10-21, reviewer].
Worktree read-only: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/union-init-refusal (no edits, no builds, no git state change).
Scratch: /home/dev/projects/cerberus-lean-proj/.tmp/review-uinit/ (probes/ holds 30 C programs, the harness run.sh and per-probe logs).

## 1. Scope and what I ran

Read, in the worktree: the project CLAUDE.md files, `git show f8afa8a1d` (stat and full diff), frontend/model/desugaring_init.lem
(whole file), the generated ocaml_frontend/generated/desugaring_init.ml and lean_frontend/generated/Desugaring_init.lean at the arm,
scripts/check_union_init_refusals.sh, lean_frontend/docs/2026-10-20_union-init-refusal-record.md, CONTRACT.md (row + D11), VALIDATION.md
(the three new entries), SUPPORTED.md, scripts/LADDER.md row 1, scripts/test_unit.sh, the tray draft 59 + INDEX, the consumer note,
scripts/fork_drift_manifest.txt, scripts/check_fork_drift.sh, scripts/failure_reach_register.txt, scripts/check_failure_reach.sh,
scripts/check_failure_reach.py, scripts/failure_census.py, tests/failure-probes/FailureReach.lean, lean_frontend/test/Unit/FuelFormsTool.lean
(the closure entry sets), the retired tests/coverage/union3/union3-003-union-init.c and scripts/exec_coverage_baseline.txt,
frontend/model/cabs_to_ail.lem at :2377-2383 (compound literal), :2709-2721 (anonymous-member splice), :3520-3560 (the E.catch call site),
frontend/model/symbol.lem (identifier equality), lem-lean/lean-lib/LemLib.lean (failwithI, lem_if), lean_frontend/Main.lean:1585-1594,
and the survey record via `git show docs/uncertainty-survey:lean_frontend/docs/2026-10-20_upstream-uncertainty-survey-record.md`.

Commands run (from the worktree root unless stated; CE = /home/dev/projects/cerberus-lean-proj/scripts/ce):

    CE ./scripts/check_union_init_refusals.sh                      # -> witness-run.log: OK (27 cases), rc=0
    CE ./scripts/check_union_init_refusals.sh --selftest           # -> witness-selftest.log: plants 28/27/13/15/14 (= expected), then OK, rc=0
    CE ./scripts/check_fork_drift.sh                               # -> fork-drift.log: layer 1 89 files = manifest; layer 2 31 differing generated files, all hash-pinned; rc=0
    source /home/dev/projects/cerberus-lean-proj/scripts/env.sh; diff -rq "$CERB_UPSTREAM_TREE" ocaml_frontend/generated | sort   # 31 files, desugaring_init.ml among them
    diff /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/ocaml_frontend/generated/desugaring_init.ml ocaml_frontend/generated/desugaring_init.ml
    sha256sum frontend/model/desugaring_init.lem                   # 2ed3aad4cf50… = the manifest's [source-content] row
    SKIP_BUILD=1 CE ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage   # -> row3.log, rc=0:
    #   SUMMARY: total=278 match=223 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0
    #   BASELINE OK
    CE .tmp/review-uinit/probes/run.sh p*.c                        # 30 probes: gcc 13 -std=c11 (exit = return mod 256), oracle --exec --batch --nolibc, Lean --batch on the oracle's --cabs-json, texts compared
    deps/cerberus-upstream/_build/default/backend/driver/main.exe --runtime=deps/cerberus-upstream/_build/install/default --exec --batch --nolibc <probe>   # pristine b9aeedcb4 on 5 probes
    env -u LEAN_ABORT_ON_PANIC lean_frontend/.lake/build/bin/cerberus-lean --batch --runtime=_build/install/default probes/p05_dotted_chain_struct_union.json   # driver refuses (exit 2) without the abort flag
    _build/default/backend/driver/main.exe --runtime=_build/install/default --exec --batch probes/p05_dotted_chain_struct_union.c    # libc mode: the refusal fires too

Not run (outside my constraints or budget): check_failure_reach.sh (builds a scratch Lake package), Tier A/Tier B, the 1285-file csmith sweep.

## 2. Probe results (my own programs; full logs in probes/)

Refused on BOTH engines, exit 125 / 134, texts byte-identical (my harness compares from the HEAD constant to end of line):
p03 anonymous struct inside a union `{ .b = 2 }` (gcc 2, pristine 2 — see P3-2), p04 anonymous union inside a union `{ .c = {1,2,3,4} }` (gcc 4),
p05 dotted chain through a struct `{ .u.c = 65 }` (gcc 65), p06 array-element chain `{ [1].c = 66 }` (gcc 66), p10 static local (gcc 65),
p13 typedef'd tagless union — text says "first (an unnamed union: designator .c, first member i)" (gcc 65), p14 compound literal as a call argument (gcc 3),
p15 address-taken compound literal (gcc 3), p17 second member of the same type (gcc 5, pristine 5), p20 unused file-scope object (gcc 0),
p29 second-then-first override `{ .c = 7, .i = 300 }` (gcc 44 = 300 mod 256, pristine 300: right by luck, now refused — same class as tray row 6).

Agreeing with gcc on both engines (controls): p07 `.t.y` into a first-member struct (30), p08 brace elision into a first-member struct (21),
p09 array of unions elided (21), p11 union-in-union positional (5), p16 `{ .i = 1, 2 }` excess element (1), p18/p19 union second in a struct,
positional and after a designator (65 / 64), p22 `{ { 7 } }` (7), p24 `.u.i` chain then `.k` (17), p25 first member a union, chained (9),
p26 array designator inside a first-member array (70), p27 `{ 0 }` on a pointer-first union (1), p28 elided union then two members (37).

Not refused and silently wrong on both engines, all the anonymous-union-in-struct layout class (tray 59 (c), survey §2.1 cluster A):
p01 `struct S { union { int i; unsigned char c[4]; }; } s = { .c = {1,2,3,4} }; return s.i & 0xff;` gcc 1, engines 0 (pristine 0);
p30 `{ .i = 0x01020304 }; return s.c[0]` gcc 4, engines 0; p23 positional, read the other member: gcc 4, engines 0; p02 sizeof: gcc 4, engines 8.

Both engines reject loudly (not the slice's class): p12 string literal for a FIRST-member char array of a union `union U { char s[4]; int i; } u = { "abc" }`
— oracle (and pristine) `constraint violation: initializing 'char' with an expression with a non arithmetic type 'char*'`, Lean `typechecking failed`,
exit 1 (gcc 98); p21 `{ }` is a parse error on the oracle (gcc accepts as an extension).

## 3. Findings

### P2-1 — SUPPORTED.md overclaims the refused class by omitting the anonymous-union carve-out
- File: lean_frontend/SUPPORTED.md:27 (Domain row): "a braced union initializer whose member designator names a member other than the first is
  refused by both engines where upstream's desugarer silently builds the first member".
- Claim: as written this is false for anonymous union members. p01 is a braced initializer whose member designator (`.c`) names a non-first
  union member; neither engine refuses, and `s.i` reads 0 where gcc reads 1 — silently wrong, exit 0. The engines never reach the Union arm because
  cabs_to_ail.lem:2713-2719 splices the anonymous member's members into the enclosing struct.
- The record (§2.3), CONTRACT D11 (both the row and the decision), the tray (59 (c)) and the consumer note all disclose this; SUPPORTED — the
  consumer-facing profile — does not, and it is the one a downstream reader checks.
- Fix (one clause): append to the SUPPORTED sentence "(anonymous union members, which upstream splices into the enclosing struct, are outside this
  refusal and remain silently wrong on layout — tray 59 (c), queued as a separate slice)".

### P3-2 — The record's "refuses nothing the desugarer handles correctly" is not true for an anonymous struct inside a union, and the text misnames C's first member there
- Files: lean_frontend/docs/2026-10-20_union-init-refusal-record.md:130-131 (§2.3: "the one predicate covers the mixing clause without refusing a form
  the desugarer handles correctly"); frontend/model/desugaring_init.lem:321 (the text "first member <first_str>").
- Evidence: p03 `union U { struct { int a; int b; }; char c; } u = { .b = 2 }; return u.b;` — gcc 2, pristine b9aeedcb4 `Specified(2)` (right by
  aliasing: the spliced `a`/`b`/`c` all sit at offset 0 of the union), the fork refuses with "(union U: designator .b, first member a)". In C the
  first member is the anonymous struct and `.b` designates inside it; "first member a" is upstream's spliced member list, not the C program's.
- Disposition: the refusal is the safe outcome (the anonymous-member class is itself silently wrong and the survey proposes refusing it, tray 60), so
  no code change is asked for. Fix: add the case to the record §2.3 (a form caught beyond the class, with its gcc/pristine values) and, if the
  text is ever revised (the outcome-protocol migration), say "first member in upstream's member list".

### P3-3 — Tray INDEX parenthetical went stale in the rebase
- File: lean_frontend/docs/upstream-tray/INDEX.md:31: "(2026-10-20, Draft; the orchestrator assigned this number, 58 is not in this tray)".
- Evidence: INDEX.md:26 ("Report 58 (2026-10-20, Draft): the oracle's literal library-location test…") and the table row for 58 exist on the
  rebased branch. Fix: delete "58 is not in this tray" (keep "the orchestrator assigned this number" if wanted).

### P3-4 — Register wording: the stated evidence for "no register row" is not the evidence; the classification itself is right by the register's own definition
- File: record §5 (:299-302): "the census's pure-site count did not move".
- Evidence: scripts/check_failure_reach.py:113 skips every site without `exec_dependency`; the count can never move for a frontend-closure site, so
  "did not move" shows nothing. What does show it: the gate's "NEW pure exec-closure site" check (check_failure_reach.py:259) stayed green on the
  changed tree (record §5 quotes it). The closure is the drive cone (`entries`, lean_frontend/test/Unit/FuelFormsTool.lean:109); `desugar` is in the
  informational `frontEntries` column (:112). Precedent is consistent: generated/Cabs_to_ail.lean has 63 and generated/Desugaring_init.lean 8
  `failwithI` sites (the new one included) and the register has 0 rows for either — frontend pure failures have never been registered; the Lean driver
  running the desugarer at execution time is covered by the witness script, which is this slice's register for the site. Fix: reword §5 to cite the
  NEW-site check rather than the count. (That there is no frontend-closure register at all is a standing gap outside this slice.)

### P3-5 — Process: the brief's STOP condition was crossed and ratified after the fact
- File: record §2.1 (:83-91): the generated OCaml differs from upstream in desugaring_init.ml, literally the brief's STOP condition; the worker
  "treated the condition as written against a wrong premise rather than as a reason to stop", then reported; the orchestrator ratified
  ([AGENT 2026-10-20, orchestrator]). The record is candid and the provenance is right; the premise was indeed wrong (cabs_to_ail.lem:3555's call to
  its own constructValue is commented out). No code consequence. Noted because the practices make a STOP a stop; the ratification should stay visible
  in the landing note.

### P3-6 — Manifest row out of byte order; a neighbouring noisy-wrong case not filed
- scripts/fork_drift_manifest.txt:643: the new [source-content] row sits between cabs_to_ail_effect.lem and cerb_attributes.lem; the gate is
  set-based (LC_ALL=C sort) so it passes; fold into the next --refresh.
- p12 (a string literal initializing a union's FIRST-member char array) is rejected by both engines and pristine where gcc accepts: a noisy-wrong
  neighbour of tray 59 (b1) (the survey's ax-08 is the single-member-struct twin). Suggest a (b4) line in draft 59.

## 4. Claims checked and found true

- Predicate sound and complete for the class as stated (a member designator on a model-level union naming a non-first member): the only non-positional
  route into a union member is moveTo_aux's Desig_member arm (desugaring_init.lem:380-401); positional traversal always enters the first member
  (go_down_aux :104-106); constructValue_aux :583-599 builds the first member from key `Elem_union`. My probes agree at every depth/storage class/
  literal position; identifier equality is string-only on both sides (symbol.lem:13-19; the generated Lean compares `str1 == str2`); `lem_if` is a
  macro over `ite` (LemLib.lean:137-141), so the failwithI arm is lazy (the controls prove it).
- Byte-identical texts and outcome classes: oracle `internal error: <text>` + uncaught Failure, exit 125; Lean PANIC line, exit 134; identical on
  the 14 witnesses and my 11 refused probes, including the "an unnamed union" spelling. Without LEAN_ABORT_ON_PANIC the driver refuses to start
  (exit 2, Main.lean:1591-1594), so "message without death" cannot occur. The refusal also fires in libc mode (oracle checked).
- Manifest re-pin: gate OK (89 files, 31 pinned deltas); raw `diff -rq` = 31 = 21 [expected-semantic] + 10 [expected-cosmetic]; the commit changes
  no existing hash and adds exactly the three rows; the desugaring_init.ml delta is the helper and the arm (plus the comments); the .lem sha256
  matches its [source-content] row. "Layer 2 moved only by desugaring_init.ml" is true.
- Retirement: the user ruled it; the baseline row is removed and the inventory line annotated (n=7 -> 6, MATCH 5 -> 4, derived, consistent);
  row 3 re-run here: SUMMARY: total=278 match=223 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK. The shape is a witness (w_coverage_union3_003_shape.c). Right disposition under the stated principle
  (a MATCH by representation overlap is not evidence).
- The E.catch at cabs_to_ail.lem:3526-3545 turns monadic INTERNAL_ERRORs into AilEinvalid; a pure Lem `error` escapes it, so the choice of `error`
  over `E.fail` is the one that guarantees a death (and row 13's "invalid node" now refuses first) — the record's argument holds.
- Provenance: [USER] rulings paraphrased, not quoted; "refuse until it hurts" is the practices doc's own phrase; worker choices [AGENT]; the
  orchestrator's ratification [AGENT, orchestrator]. Consistent with the survey record (same day), which assigns the anonymous-member class to a
  separate slice (its §2.1 cluster A), so the split between this slice and that one is coherent.

## 5. Verdict

[AGENT 2026-10-21, reviewer] MERGEABLE WITH FIXES. The code change is correct, minimal and witnessed on both engines; the gates I could run are
green; the retirement is consistent. The fixes are documentation only: P2-1 (one clause in SUPPORTED.md, worth doing before the ff because
SUPPORTED is what a consumer reads), P3-3 (stale INDEX parenthetical), and the record wording of P3-2/P3-4 at the author's discretion.

## 6. Residual uncertainty

- check_failure_reach.sh not re-run here (it needs a scratch lake build); the "no new exec-closure site" claim rests on the record's quoted green
  run plus the register's definition (§3, P3-4).
- The interdiff claim ("the slice's diff is otherwise unchanged" by the rebase) is unverifiable: the pre-rebase commit has no surviving ref.
- The corpus sweep (39 + 1285 + deps + libc: exactly one refused program) is not re-measured; row 3 and the survey record corroborate it for
  tests/coverage, nothing here corroborates the csmith figure.
- Tier A and Tier B after the retirement/rebase are, as the record says, still to be run at the boundary.
