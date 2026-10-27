# Pre-merge review: fix/anonymous-members-refusal (5badfe250, four commits over 704c4e697) — 2026-10-27

Reviewer: Claude Fable 5.1, independent (fresh context; the worker's record, the survey's framing and the
orchestrator's dispositions were read as claims, not as settled). Every judgement below is tagged
[AGENT 2026-10-27, reviewer]. Budget ~45 min. Worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/anonymous-members-refusal` (read-only; the
already-built binaries run on scratch inputs; no lake/dune/make, no lane scripts, no git state change). A full
battery (`release.py --mode full`, started 05:25) was running in the worktree throughout; I did not see its result.

## 1. Scope and what I ran

Read: container `CLAUDE.md`, `lean_frontend/CLAUDE.md`, the charter, the record, the consumer note, the four commit
messages, `git diff 704c4e697..5badfe250` (every file), the witness script in full, the survey record §2.1, tray 60
and INDEX, the union-initializer review (P3-4), `cabs_to_ail.lem` (the arm, the helper, the `E.catch` at :3555),
`cabs_to_ail_effect.lem` `get_anonymous_struct_or_union`, upstream's four `this may be WRONG` sites
(`deps/cerberus-upstream/frontend/model/cabs_to_ail.lem:140-200`, :3244), the generated `cabs_to_ail.ml` and
`Cabs_to_ail.lean`, `LemLib.lean:220-247` (`failwithI`), `Main.lean:1676-1689` (the `LEAN_ABORT_ON_PANIC` start
gate), `check_fork_drift.sh:242-245` (`diff_hash`), `test_ci_sweep.sh` (non-gating, no baseline),
`test_upstream_oracle.py:850-861` (`not_applicable`), the three corpus programs that now refuse.

Ran (verbatim; `WT` = the worktree, `CE` = `/home/dev/projects/cerberus-lean-proj/scripts/ce`):

```
# 28 reviewer probes (14 refusal-class, 4 pre-existing-rejection, 10 must-not-refuse controls), each through
# gcc 13.3 (-std=c11 -w, exit = return mod 256), the oracle and the Lean engine; texts compared when both refuse:
/home/dev/projects/cerberus-lean-proj/.tmp/review-am/run_probes.sh      # -> probes.log; the driver is:
#   gcc -std=c11 -w -o $OUT/$b.gcc $c && $OUT/$b.gcc
#   $CE $WT/_build/default/backend/driver/main.exe --runtime=$WT/_build/install/default --exec --batch --nolibc $c
#   $CE $WT/_build/default/backend/driver/main.exe --runtime=$WT/_build/install/default --cabs-json $c > $b.json
#   (cd $WT && env LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/cerberus-lean --batch --runtime=_build/install/default $b.json)
# the same on r02 WITHOUT --nolibc (oracle rc 125, Lean rc 134, the text present on both)
# the lane's one-file differential on a refusing probe:
SKIP_BUILD=1 $CE ./scripts/test_exec.sh /home/dev/projects/cerberus-lean-proj/.tmp/review-am/probes/r02_anon_union_in_struct.c
# the manifest's layer-2 pin recomputed the gate's way:
diff -u --label upstream/cabs_to_ail.ml --label fork/cabs_to_ail.ml $CERB_UPSTREAM_TREE/cabs_to_ail.ml ocaml_frontend/generated/cabs_to_ail.ml | sha256sum
sha256sum frontend/model/cabs_to_ail.lem
# generated-tree delta against the primary checkout (704c4e697, mdd/cerberus-lean):
diff -rq cerberus-lean/ocaml_frontend/generated $WT/ocaml_frontend/generated ; diff -rq cerberus-lean/lean_frontend/generated $WT/lean_frontend/generated
# independent brace-matching re-scan for anonymous members (comments/strings/preprocessor stripped):
python3 -I .tmp/review-am/scan_anon.py tests lean_frontend/corpus runtime/libc deps/cn/tests/cn deps/libxml2 deps/CN-pKVM-buddy-allocator-case-study
# gcc check of the consumer note's sizeof figures (struct S { union { int b; char c; }; int d; } vs the spliced form)
```

Results (full lines in `.tmp/review-am/probes.log`, raw outputs in `.tmp/review-am/out/`):

| class | probes | gcc | oracle | Lean | texts |
|---|---|---|---|---|---|
| refusal: anonymous struct in struct; union in struct; struct in union; nested (inner union names the kind); typedef'd tagless specifier bare; array of such structs; `const`-qualified anonymous union; cast type name; `_Static_assert(sizeof)` only; typedef'd container; parameter type; anonymous union with array members; the `struct page` idiom (anonymous struct inside anonymous union); `extern` declaration only | r01-r14 | compiles (r05 with a warning) | REFUSE, rc 125, kind word right in every case | REFUSE, rc 134 | IDENTICAL in all 14 |
| pre-existing rejection (not the new refusal): tagged specifier without declarator; tagless `enum { … };`; `_Atomic(union { … });`; a lone `;` in a body | g01-g04 | 1 / 2 / 0 / 3 | rc 1 CV 6.7.2.1#2 ×3; g04 Defined 3 | rc 1 `desugaring failed at …` ×3; g04 Defined 3 | — |
| must not refuse: named member of tagless type (braced; brace-ELIDED struct 321; brace-elided union 21; static elided 321; array elided 531; sizeof/padding 12); `_Static_assert` member; tagless file-scope object; compound literal with named members; tagless enum with declarator | c01-c10 | agree | agree (Defined, same value) | agree | — |

The lane's one-file differential on r02: `SUMMARY: total=1 … cerb_skip=1 …` / `FAILED: zero comparisons happened (all
files skipped) — vacuous run` (the Lean side never runs). Manifest: `fcc8ce5b…` = sha256 of `cabs_to_ail.lem`;
`74b272fa88008bc9…` = the gate's diff-hash of `cabs_to_ail.ml` (both match the two moved rows; no other row moved).
Generated trees vs the mainline primary checkout: exactly `cabs_to_ail.ml` (33 diff lines) and `Cabs_to_ail.lean`
(42), the helper and the arm only (`stExpect_return membrs` → `Cerb_debug.error (…)` / `failwithI (…)`). Corpus
re-scan: 6 files — `parity-probes/probes/anon_struct_union.c`, `gcc-torture/{execute,breakdown/success}/anon-1.c`,
`gcc-torture/{execute,breakdown/not_supported/bitfields}/20030714-1.c`, `suite/desugaring/13-non_anonymous_empty_sdecltors.error.c`;
libc, CN, libxml2, pKVM, `lean_frontend/corpus`: 0 — the record's set exactly (struct-008 is deleted in this tree).
gcc sizeof: 8 for the anonymous-union struct, 12 for the spliced form (the consumer note's figures). Worktree
`git status` clean before and after; the Lean aborts left no core files (apport pattern); my `test_exec`
observation directory under the worktree's `.tmp/scripts/observations/` was removed.

## 2. Findings

No P1.

### P2-1 — The stop form is the crash-shaped wire class, and the lanes cannot tell this refusal from an oracle skip; disclosed, precedent-consistent, but the record did not weigh the third option
- Files: `frontend/model/cabs_to_ail.lem:2746` (`error (anonymous_member_refusal base_ty)`); record §2.2;
  consumer note "On the wire"; container `CLAUDE.md` ("an internal error, assertion or uncaught exception on valid C
  is a crash"); `scripts/test_exec.sh` (classification).
- Claim: on the oracle the refusal is `internal error: <text>` + `cerberus: internal error, uncaught exception:
  Failure(…)`, exit 125, no verdict line; on Lean a `PANIC` + abort, exit 134. By the project's own definitions that
  is the crash wire class, carrying a declared text. `test_exec.sh` classes it `CERB_SKIP` and never runs the Lean
  side (measured above), so in every lane a deliberate fork refusal is indistinguishable from an oracle crash or
  skip; only the witness script pins the class, and the outcome protocol decodes it as legacy/unattributed.
- Evidence: my `test_exec` run; `probes.log`; record §2.2's measurement of form (a) (the port's batch record for a
  `Desugar_NotYetSupported` is `Error {msg: "desugaring failed at <loc>"}` with no reason — corroborated by my gap
  probes' Lean output, which carries no reason either).
- Assessment [AGENT 2026-10-27, reviewer]: the charter's rule ("prefer (a) if both engines render it identically in
  batch and the lanes classify it as a matched frontend refusal; otherwise (b)") was applied correctly on the
  measured facts, and D10/D11 are the same shape; CONTRACT D12, VALIDATION, the consumer note and the migration map
  all say so plainly. What §2.2 does not consider is that (a)'s defect is in the PORT's batch rendering, a small
  hand-written `Main.lean` change (print the cause text in `--batch`), after which D9-style frontend refusals
  (exit 1, attributed on both engines, a real `Error` record for the consumer) would satisfy the charter's rule.
  Not a merge blocker.
- Fix: none required for merge. Record the option in the record §7 and `TODO.md` next to the WP2 mover (a
  Main.lean batch-rendering slice would let D12 — and D11 — migrate to frontend refusals without a `.lem` change
  beyond the one arm).

### P3-1 — Consumer note: the "what now refuses" paragraph mixes two shapes
- File: `lean_frontend/docs/2026-10-26_consumer-note-cerberus-caesium-anonymous-members-refusal.md`, the paragraph
  beginning "Upstream's `desugar_struct_declaration` …": for `struct S { union { int b; char c; }; int d; }` it
  gives `sizeof` 12 vs gcc 8 (right; measured) and then "the brace-elided `{1, 2, 3}` putting the 3 into `c` and
  leaving `d` 0" — that is the an-01 shape (`int a` first). On the stated shape `{1, 2, 3}` splices to b=1, c=2,
  d=3 (wrong vs gcc, but `d` is not 0).
- Fix: say "`{1, 2}` puts the 2 into `c` and leaves `d` 0" or name the an-01 shape.

### P3-2 — The refusal text attributes the defect to upstream's `isAnonymous` prints, which guard a broader class
- Files: `frontend/model/cabs_to_ail.lem:1563-1565` (the text: "under its own 'this may be WRONG ==> anonymous
  Struct/Union' :144/:166/:194/:3244"); CONTRACT.md:103 and D12; the record §0; the three commit messages.
- Claim: those four prints fire on the TAG's `isAnonymous` flag (`deps/cerberus-upstream/frontend/model/cabs_to_ail.lem:142-147,
  :164-169, :192-197, :3242-3247`), set for every tagless specifier — including named members of tagless type and
  file-scope tagless objects, which the slice rightly keeps and which answer RIGHT (c02/c03/c09/c10, brace-elided,
  agree with gcc). The splice arm itself (:2697) carries no TODO; it reads as a deliberate (wrong) upstream reading.
  The outcome is unaffected (a deliberate reading may be refused loudly), and the prints do fire for anonymous
  members, so the sentence is not false; it overstates the link.
- Fix: no text change (it is pinned byte for byte on both engines and in four documents; a change costs a regen and
  a manifest re-pin). Add one sentence to the record §1 stating the precision.

### P3-3 — Stale sentence in the uncertainty corpus README
- File: `tests/parity-probes/uncertainty/README.md:4-6` still says no `scripts/*.sh` references `parity-probes`
  (grep of 2026-10-20); `scripts/check_anonymous_members_refusal.sh:17` now cites the directory in a comment (and
  `scripts/LADDER.md` does too). No lane walks it, which is what the sentence is for.
- Fix: "no lane script walks it; `check_anonymous_members_refusal.sh` and LADDER cite it as a pointer".

### P3-4 — Record §2.2 cites the `E.catch` at pre-edit line numbers
- File: record §2.2 ("cabs_to_ail.lem:3526-3545"); on the committed tree the catch is at :3555-3571. The claim
  itself holds: only `INTERNAL_ERROR (Internal_error_desugaring _)` is caught, everything else is re-raised by
  `E.generic_fail`, and a pure `error` escapes regardless (r08 and the worker's compound-literal witness confirm).
- Fix: correct the line numbers.

### P3-5 — The text's parenthetical is imprecise for the typedef'd-tagless case
- `typedef struct { … } T; struct S { T; }` refuses as "a struct-declaration with no declarator whose type
  specifier is a tagless struct"; the specifier is a typedef name resolving to a tagless struct (r05; gcc accepts
  with a warning). Refusing it is safe (record §2.3 says so). No change; noted for the next text revision.

## 3. Items of interest, dispositioned

- Predicate sound and complete for the class: yes by construction — the one arm (`List.null sdecltors` ∧
  `get_anonymous_struct_or_union = Just _`) is where the splice happened, and every aggregate type passes through
  `desugar_struct_declaration` whatever the context (file/block scope, typedef, cast, parameter, compound literal,
  extern, `sizeof`/`_Static_assert` only, arrays, qualifiers, nested) — 14/14 refuse with the right kind word and
  byte-identical texts. `_Atomic(union {…});` is `Nothing` (upstream's own clang-following TODO) and stays the
  6.7.2.1#2 constraint violation: upstream's judgement, kept.
- Over-refusal: none found — named members of tagless type (incl. brace-ELIDED initializers, the shape the
  `isAnonymous` prints actually guard), `_Static_assert` members, tagless file-scope objects, compound literals,
  tagless enums with a declarator all agree with gcc and the oracle; tagged-no-declarator, tagless enum without a
  declarator and `int;` stay the pre-existing constraint violation on both engines.
- Both engines identical in batch with the claimed exits: yes (125/134, texts identical, with and without `--nolibc`).
  Lean's `failwithI` is a `panic!` behind `implemented_by`/`never_extract`; `Main.lean:1684-1689` refuses to start
  without `LEAN_ABORT_ON_PANIC`, so the fail-open path is closed.
- Every gated corpus measured: the worker's exact run (5567 + 1669 files) is corroborated by my independent scan
  (same 6 remaining files; libc/CN/libxml2/pKVM 0). Dispositions: struct-008 retired with its baseline row and the
  inventory line annotated (the union3-003 shape); `check_union_init_refusals.sh`'s `ctl_anonymous.c` retired with
  re-derived plant counts (28/26/12/15/14 = 14×2 / 14+12 / 12 / 14+1 / 14, checked); gcc-torture `anon-1.c` and the
  suite `.error.c` row live only in `test_ci_sweep.sh`, which is non-gating with no baseline (`:3-7`), so "moves at
  the next deliberate re-record" is right; `execute/` is walked by no lane; the pristine lane's `not_applicable`
  excludes gcc-torture and `tests/suite` (`test_upstream_oracle.py:860-861`), so no registration is owed and
  `upstream_oracle_differences.json` correctly gains no row.
- Manifest re-pin: exactly the `cabs_to_ail.lem` `[source-content]` and `cabs_to_ail.ml` `[expected-semantic]` rows
  plus a dated header note; both hashes recomputed and match.
- CONTRACT/VALIDATION/SUPPORTED/LADDER/consumer note: no overclaim found. The kernel-reach warning is stated plainly
  in all four (consumer note has a named paragraph; CONTRACT D12 and SUPPORTED say every `union { … };` inside a
  struct, kernel-style C included, now refuses). The union-initializer carve-out sentence is replaced in SUPPORTED,
  the D11 CONTRACT row, the VALIDATION D11 bullet and gate row, LADDER row 1 and the script header. Tray 60's
  paragraph sits under "Origin" as the INDEX says. Nothing lists witness scripts in `lean_frontend/CLAUDE.md` or
  README, so no listing is owed. The migration TSV is documentation (no script parses it).
- Record integrity: machine outputs quoted verbatim; derived counts labelled; provenance tags present; no operator
  quotation found. Kernel replay: not owed (no proof module changed; the frontend is `partial`).

## 4. Verdict

**MERGEABLE WITH FIXES** [AGENT 2026-10-27, reviewer] — the fixes are documentation only (P3-1 the consumer note's
mixed example, P3-3 the README sentence, P3-4 the record's line numbers; P3-2/P3-5 as record notes), none touches
code, generated trees, gates or baselines, so they need no re-gate beyond a docs commit. P2-1 is a disclosed design
cost consistent with D10/D11 and the charter's own rule; it asks for a recorded option, not a change. Conditional on
the running full battery being green (see §5).

## 5. Residual uncertainty

- The full battery's result (Tier B row 10 pristine lane after the retirement, csmith, the ci lanes) — running
  during this review, not seen. Tier A on the M2 tree is the record's claim, not re-verified here.
- I did not run the witness script or its self-test (lane scripts were out of scope); my 28 probes and the lane's
  one-file differential are my own measurement of the same claims.
- The rejection of stop form (a) rests on the record's VLA measurement; I corroborated only the port's reason-less
  batch record (gap probes), not the VLA run itself.
- My corpus scanner is a brace-matcher over stripped text; it cannot see macro-generated members. The worker's
  exact per-file run on the oracle covers that for the walked corpora; I did not repeat it.
- The axiom census and `check_failure_reach` are the record's quoted runs (row 1, in the running battery).
