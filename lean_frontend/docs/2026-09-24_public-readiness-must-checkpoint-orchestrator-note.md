# Public-readiness MUST checkpoint — orchestrator's verification, review adjudication and merge plan

2026-09-24. Author: the orchestrator [AGENT]. Repo of record for the cross-repo note: cerberus-lean (the
worked example); the lem-lean side is referenced by commit. Nothing in this note is a merge; every merge
below happens ff-only on the operator's explicit per-merge sign-off.

## 0. Provenance and scope

- [USER 2026-09-24] "I think now our cerberus-sl customer is happy, we should do a cleanup round and
  announce the lean backend publicly. I'm going to send off a codex agent to review the whole project and
  check we are in good state for this." → the public-readiness REVIEW (Codex), lem-lean
  `doc/lean-backend/2026-09-24_public-readiness-review.md` (commit 07b709e): 11 MUST (M1–M11), 8 SHOULD,
  verdict "not ready to announce from the current documentation and newcomer instructions; ready for a
  bounded cleanup round leading to an early alpha announcement". The orchestrator verified every citation
  it could reach and agreed with the verdict; adjustments recorded in chat and carried into the remediation
  ledger by the remediator (M1 split into M1a MUST / M1b SHOULD; M4 fixed in code as well as text; S9 =
  `check_exec_totality.sh` ENFORCE default; S10 = fork-drift portable prerequisites; S11 = qualified
  core-name import case).
- [USER 2026-09-24] "Must checkpoint achieved, can you send off reviewers, and prepare a report?" → this
  note; two independent Claude Fable delta reviewers chartered (§3); the orchestrator's own gates (§2).
- [USER 2026-09-24] "Can you write this up as a note. FYI, I have concluded the concurrency branch
  prototype has failed, and I'm working on a remediation. But that dependency should be considered dead
  for now." → §5.

## 1. The heads under review

| Repo | Branch | Head | Base (mainline) | Commits | Non-documentation footprint |
|---|---|---|---|---|---|
| lem-lean | `cleanup/public-readiness-20260924` | `9bb6c6b` | `mdd/lean-backend` @ `38f87d5` | 07b709e (the review doc), 1235498 (M1 M4 M8), 9bb6c6b (M3 M5 M11) | `src/lean_backend.ml` (refuse `sorry` target reps: function reps incl. applied/parameterised, declared type reps), `scripts/capped` (NEW, repository-local cap wrapper), `tests/comprehensive/Makefile` + `parity/run.sh` (no container-absolute defaults; `lean-generate` now fails closed), 4 negative fixtures, `test_target_reps.lem`, `LICENSE`, `lean-lib/NOTICE.md`; `lean-lib/LemLib.lean` changed in COMMENTS only (notices) — LemLib code identical |
| cerberus-lean | `cleanup/public-readiness-20260924` | `0a6d59eed` | `mdd/cerberus-lean` @ `e9f9d049f` | d6618ecb9 (M10), abe505d3d (M1 M4 + re-pin), 0a6d59eed (M2 M6 M7) | `scripts/common.sh` (no `GIT_CONFIG_GLOBAL` requirement; `lem`-on-PATH check), `scripts/capped` (no ancestor `env.sh` discovery), `frontend/concurrency/cmm_csem.lem` (23 `sorry` reps → `LemUnsupported.Cmm.*` markers), the re-pin to lem-lean `9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4` at five sites (`lakefile.toml`, three `lake-manifest.json`, `fork_drift_manifest.txt` `lem-pin=9bb6c6b5`), 21 evidence tarballs untracked at HEAD (21,888,265 bytes; history untouched), NEW `lean_frontend/SUPPORTED.md` |

Both heads are fast-forwards of their mainlines. The remediator worked in its own worktrees with an OWNED
copy of the opam switch (lem pinned there from the GitHub URL, redirected locally); the shared switch and
`deps/lem-pinned` (still `38f87d5`) were not touched.

## 2. The orchestrator's independent gates (verbatim tails)

Environment: the remediator's worktrees, foreground steps, one heavy job on the box at a time, every Lean
invocation under `scripts/capped` with `CERB_MEM_MAX=32G`; cerberus with the remediator's owned switch
(`lem -v` = `Lem 9bb6c6b5`); lem-lean with an in-tree `make` of `9bb6c6b` (`./lem -v` = `Lem 9bb6c6b` —
note the SEVEN-character abbreviation, §3 F1). Logs: `<worktree>/.tmp/orch-gates.log` (ephemeral).

cerberus-lean `0a6d59eed` (21:23–21:32 UTC; `git status` clean before and after):

    === PRELUDE_SRC EXIT=0 === / === DUNE_BUILD EXIT=0 === (dune build --force) / === DUNE_INSTALL EXIT=0 === / === CERBERUS_INSTALL EXIT=0 ===
    === LEAN_PRELUDE_SRC EXIT=0 === / === LEAN_NATIVE_OBJ EXIT=0 === / Build completed successfully (395 jobs). === LAKE_BUILD EXIT=0 ===
    Total: 15 passed, 0 failed
    check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
    check_sorry_token: OK (321 files scanned comment-stripped — generated 219, hand-written+test 67, LemLib 35; 0 sorry tokens)
    check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …
    check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; …
    check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
    check_lem_sync: OK (src a508392d093469425673fbda6d8ee3b409b656d71aaf1413180a0f224bff39bb, gen 77527ca73a3c79a836a7027062cc38aa1252c1e1c553d0a5c8d60a1d6ef8aa38)
    check_lem_sync: lean OK (src a508392d…, gen f4893e95ac3462defae87f737580b172f4e4e1cf35941d5be07edd82c8df808e)
    check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (… lem-pin 9bb6c6b5 = lem -v)
    === ROW1 EXIT=0 ===
    SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)   BASELINE OK
    SUMMARY: total=2 match=2 fail=0   ALL PASSED        SUMMARY: total=7 match=7 fail=0   ALL PASSED
    test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins …
    SUMMARY: match=12 diff=0   ALL MATCH RECORDED BASELINE
    SUMMARY: exec_match=9 neg_pinned=5 fail=0   ALL AT COMMITTED EXPECTEDS
    SUMMARY: total=93 match=93 … (tests/float)   Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=90 match=66 ub_match=20 … cerb_skip=4 … (tests/debug)   Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=212 match=183 ub_match=16 … cerb_skip=13 … (tests/coverage)   Baseline check: 0 regression(s), 0 improvement(s)

The generated-tree hashes (`gen 77527ca7…` OCaml, `gen f4893e95…` Lean) are IDENTICAL to mainline
`e9f9d049f`'s: the new lem changes no generated code; only the lem SOURCE hash moved (`cmm_csem.lem`).

lem-lean `9bb6c6b` (21:32–21:43 UTC; `git status` clean after):

    nonlean-regress: OK (893 artifact rows, 216 exit rows, 9 emitters, byte-identical to golden)
    === Generation: 56 passed, 0 failed, 0 skipped ===   Build completed successfully (173 jobs).
    OK (rejected as declared): negative/neg_target_rep_sorry.lem / …_applied.lem / …_parameter.lem / …_type.lem
    OK (leg 1): panic prints the Incomplete Pattern message, then continues with default   OK (leg 2): fail-stops (exit 134) under LEAN_ABORT_ON_PANIC=1
    OK: compiled draw sequences hold / consumer injection holds / N-ary seed injection holds / fuel x reader x mutual composition holds
    === LEAN_TARGET EXIT=0 ===
    OK: 11 proofs modules scanned; no sorry/admit/axiom/native_decide/bv_decide token
    OK: 260 files scanned; no lemDefaultFuel, no LemFuel instance, no literal fuel (F1-F5)
    === FINAL_LEGS EXIT=0 ===

Parity: the only `FAIL` lines are the four registered expected failures (`f_int32_overflow`,
`f_int_of_big_num`, `p_str_bytes`, `p_str_escapes`), each immediately followed by its `XFAIL (expected,
registered)` line — 4 = 4 (derived count).

## 3. The two independent delta reviews and the orchestrator's adjudication

lem-lean: Claude Fable reviewer, commit `f2fd0f0` on `audit/public-readiness-must-20260924`
(`doc/lean-backend/2026-09-24_public-readiness-must-delta-review.md`). Verdict, verbatim: "Merge-ready as is,
pending the orchestrator's independent green gate on 9bb6c6b" — that gate is §2. No P1/P2.

cerberus-lean: Claude Fable reviewer, commits `ef811bbd9` + `d83d1121a` on `audit/public-readiness-must-20260924`
(`lean_frontend/docs/2026-09-24_public-readiness-must-delta-review.md`). Its addendum compared the orchestrator's
gate log with every claimed verdict line: no disagreement.

| Finding | Grade | Orchestrator's position [AGENT] |
|---|---|---|
| cerberus F1: `lem-pin=9bb6c6b5` is string-compared (`check_fork_drift.sh:172-175`) with `lem -v`'s second word; lem bakes its version from `git describe --dirty --always` (lem-lean `Makefile:4`), whose abbreviation length varies with the repository (`9bb6c6b` in-tree, `9bb6c6b5` in the remediator's opam clone) and would gain `-dirty`/tag suffixes | P1 | AGREE — reproduced: the orchestrator's in-tree build prints `Lem 9bb6c6b`. The operator's standard re-pin route (`deps/lem-pinned` reset + `make rebuild-lem`) is predicted to turn row 1 red on a CORRECT pin. Fix before merge: pin the FULL hash, compare by hex prefix (≥7) after stripping any describe suffix, plant-test refuse + admit; rerun row 1. |
| cerberus F2: `2026-09-24_evidence-archive-untracking.md` has no [AGENT]/[USER] tag and does not quote the [USER 2026-09-06] retention ruling verbatim | P2 | AGREE — docs-only; also state that mainline had already been pushed with the blobs (history is not rewritten). |
| cerberus F3: no in-file FORK comment on the 23 `LemUnsupported.Cmm.*` markers | P3 | AGREE — add the comment (the markers are never rendered: those functions are `{hol; isabelle; tex}`-only, which is why the Lean build passes). |
| cerberus F4: residual container coupling — `scripts/ci_lean.sh:12-14` hard-requires `GIT_CONFIG_GLOBAL` and is named by `LADDER.md:11`; `check_fork_drift.sh` absolute fallback + private-mirror help; `tools/check_*.sh` help text | P3 | AGREE — SHOULD block (S10 already covers fork-drift; add `ci_lean.sh`). |
| cerberus F5: `SUPPORTED.md` does not name the lanes/modes inline, no issue link | P3 | AGREE — SHOULD block. |
| cerberus F6: `SUPPORTED.md:43` dates the refined-cerberus retirement 2026-09-24; the ruling is [USER 2026-09-16] | N | AGREE — fix with F2. |
| cerberus F8: "86 OCaml / 219 Lean generated files byte-identical" was the remediator's derived JSON comparison | N | CONFIRMED by the orchestrator: identical lem-sync `gen` hashes on both trees (§2). |
| lem-lean F1: an inline backend TYPE `` `sorry` `` (`Typ_backend`, `lean_backend.ml:7175`/`:7226`) still renders unchecked; expression form and declared type reps are refused | P3 | AGREE — close now while the pin is moving anyway (same trimmed-`"sorry"` refusal at the two type render sites + a negative fixture). |
| lem-lean F2: the lem-pin string comparison (same defect as cerberus F1, seen from the lem side) | P3 | = cerberus F1. |
| lem-lean F3: remediation record says "three excluded CMM reps"; measured 23 | P3 | AGREE — appended erratum, never a rewrite. |
| lem-lean F4: record cites two operator rulings without [USER] tags/verbatim quotes | P3 | AGREE — appended addendum quoting them. |
| lem-lean F5: `test_target_reps.lem` dropped the `process_val` let-rec rep (the `def_trans.ml:245` trigger) rather than replacing it | P3 | AGREE — replace with a concrete rep or state the drop. |
| lem-lean F6–F10 | N | Noted; F7 (document `CERB_MEM_MAX` defaults/`none`/`CERB_JOB_CGROUP`) and F8 (root README cites `38f87d5` for a file that did not exist there) go to the SHOULD block. |

Nothing in either review is disputed.

## 4. Sequencing hazard (both reviewers; the orchestrator agrees)

`frontend/concurrency/cmm_csem.lem` is in cerberus-lean's `LEM_SRC_LEAN`. The new lem REFUSES its 23 `sorry`
target reps, so cerberus MAINLINE (`e9f9d049f`) cannot regenerate against lem `9bb6c6b` until the cerberus
cleanup branch (which replaces them) lands. Consequence for the merge day: the lem-lean ff, the shared-switch
re-pin and the cerberus ff must run back to back, and no other worktree may regenerate in that window (a
worktree on an older cerberus head regenerating against the new switch lem would fail at `cmm_csem.lem`).

## 5. Concurrency prototype — operator ruling

[USER 2026-09-24] verbatim: "FYI, I have concluded the concurrency branch prototype has failed, and I'm working
on a remediation. But that dependency should be considered dead for now."

Consequences [AGENT]: (i) the announcement's supported profile (`SUPPORTED.md`) already excludes concurrency;
the SHOULD block must make sure no current-facing page presents `arc/sc-prototype` / `feature/concurrency` as
live or pending work — they are parked records (the review's inventory classification "keep as parked/design
record" stands); (ii) nothing in the readiness cleanup depends on or waits for the concurrency work; (iii) the
remediation the operator is working on is outside this cleanup's scope and will be chartered separately;
(iv) the 44.9 MB `2026-09-21_sc-prototype-evidence` archive blob lives on other refs only (review §C) — not
in mainline history; no action here.

## 6. Plan from here

1. Closure commits by the remediator on both cleanup branches: cerberus F1 (gate prefix comparison + full-hash
   pin + plants), F2, F3, F6; lem-lean F1 (type render sites), F3, F4, F5. The lem-lean head moves, so the
   cerberus branch re-pins to the new hash at its five sites. Gates as in §2 after every code change.
2. The orchestrator re-gates both closure heads independently; the two reviewers take a short second pass
   over the closure deltas (the pre-merge audit ask for these merges — the operator may trim it).
3. Merges, each on the operator's explicit yes: (a) lem-lean ff-only; (b) the SHARED-SWITCH re-pin
   (`deps/lem-pinned` reset to the merged lem commit + `make rebuild-lem`) — a separately authorised action
   because it affects every checkout on the box, executed back to back with (c); (c) re-gate the cerberus
   branch against the switch's lem; (d) cerberus ff-only. Other sessions warned not to regenerate during (b)–(d).
4. Then the SHOULD block (S1, S3–S11, plus the P3/N items above), the operator's M9 network checks with the
   FINAL pins (`ls-remote`, fresh public clone, `cat-file -e` of the pinned lem commit), the fresh-clone recipe
   walk outside this container, and the prerelease tags (`lean-backend-v0.1.0-alpha.1`,
   `cerberus-lean-v0.1.0-alpha.1`, operator's naming call). No push, tag or announcement is performed by agents.
5. Hygiene at the end of the SHOULD block: retire the two review scratch clones (`worktrees/readiness-*`),
   the four audit worktrees of this round and the review worktree; branches stay as records.

## 7. Open decisions for the operator

- Confirm the merge sequence in §6.3 and, at that moment, authorise the shared-switch re-pin.
- Accept the reviewers' second pass on the closure deltas as the pre-merge audit for these two merges, or ask
  for more.
- M10 history: the orchestrator recommends NO history rewrite (already-pushed mainline; consumer pins).
- Tag names and the announcement wording (the review §E offers root fork notes and an announcement scope).

## 8. Closure heads (2026-09-25) — verified, reviewed, ready for the merge asks

Closure commits by the remediator: lem-lean `cleanup/public-readiness-20260924` → `6b20bfd02de924d078725efa96c6675115b8b17a`
(292db8b: refuse inline backend TYPE `sorry` at the two `Typ_backend` render sites + two negative fixtures + the
`process_val` let-rec rep restored; 6b20bfd: record appendices — 3→23 erratum, [USER] rulings quoted); cerberus-lean
`cleanup/public-readiness-20260924` → `c13a1054133b49c954fe27ac4c1b4e33a418c51f` (603c9b69b: `check_fork_drift.sh`
compares `lem -v` as a 7–40 hex PREFIX of a mandatory full-40-hex `lem-pin=`, `-dirty`/describe forms handled, plants
S15–S30; re-pin to 6b20bfd at all five sites; `cmm_csem.lem` FORK comment; c13a10541: provenance + retirement-date fixes,
closure record). Both fast-forward their mainlines; both worktrees clean.

Orchestrator's independent gates on the closure heads (verbatim; logs `<worktree>/.tmp/orch-gates-closure.log`):

- cerberus `c13a105`, generated trees WIPED and re-derived with an in-tree lem whose version string is the
  SEVEN-character `Lem 6b20bfd` (the operator's route; PATH-first inside `opam exec`):
  `check_lem_sync: lean OK (… gen f4893e95ac3462defae87f737580b172f4e4e1cf35941d5be07edd82c8df808e)` = mainline's Lean gen
  hash (219 files identical); OCaml `gen b79e328e…` ≠ mainline: `diff -rq` against the primary's tree = exactly
  `ocaml_frontend/generated/cmm_csem.ml`, three blank lines → the FORK comment (comment-only, confirmed);
  `Total: 15 passed, 0 failed`; `check_failure_reach: OK (239 …`; `check_fork_drift: SELFTEST OK (30 plants …`;
  `check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest … layer 2: 30 differing generated files, all
  hash-pinned … lem-pin 6b20bfd02de924d078725efa96c6675115b8b17a matches lem -v 6b20bfd (hex prefix)`; `ROW1 EXIT=0`;
  ten lanes all `EXIT=0` (minimal 113 = 90/18/5 `Baseline check: 0 regression(s), 0 improvement(s)`; multi-TU 2/2 and
  7/7; address space 18; immaculate at baseline; libc 12/12; bytes 9 + 5; float 93/93; debug 90; coverage 212).
  The F1 fix is thereby exercised on the exact route the review predicted would fail.
- lem-lean `6b20bfd` (in-tree `make`, `./lem -v` = `Lem 6b20bfd`): `nonlean-regress: OK (893 artifact rows, 216 exit
  rows, 9 emitters, byte-identical to golden)`; comprehensive `Generation: 56 passed, 0 failed, 0 skipped`, `Build completed
  successfully (173 jobs)`, 107 negative probes `OK (rejected as declared)` incl. `neg_inline_type_sorry.lem`,
  `neg_inline_relation_type_sorry.lem` and the four `neg_target_rep_sorry*`; panic/supply/reader/fuel legs OK;
  `LEAN_TARGET EXIT=0`; parity: 4 `FAIL` = the 4 registered XFAILs; `OK: 11 proofs modules scanned; no
  sorry/admit/axiom/native_decide/bv_decide token`; `OK: 260 files scanned; no lemDefaultFuel …`; `FINAL_LEGS EXIT=0`.

Reviewers' second passes (Claude Fable): lem-lean `0df91ca` on `audit/public-readiness-must-20260924` — "Merge-ready as
is at 6b20bfd", no P1/P2/P3 (notes C1: an UNUSED parenthesised `TYR_subst` `sorry` type rep is refused only at a use
site — emission-time fail-closed holds; C2 wording); cerberus `c3e2070b4` on `audit/public-readiness-must-20260924` —
"No P1 or P2 remains open on c13a105"; F1/F2/F3/F6/F8 CLOSED; new F11 P3 (five front pages still cite `abe505d3d` as
the checked implementation while the recipe pins `6b20bfd`) → SHOULD block with F4, F5. Both reviewers quote the
orchestrator's closure logs and report no disagreement with any gate line.

[USER 2026-09-25] (during this checkpoint): "I'm going to ask them to pick up the SHOULD-level work on new branches off
the current final heads" — SHOULD branches start at 6b20bfd / c13a105 in NEW worktrees; their merges queue behind the
two MUST merges.

Merge asks (each a separate explicit yes): (1) lem-lean `mdd/lean-backend` 38f87d5 → 6b20bfd, ff-only; (2) the
shared-switch re-pin — `git -C deps/lem-pinned reset --hard 6b20bfd` + `make rebuild-lem` — authorised separately at
that moment (it changes every checkout's lem; no other worktree may regenerate until (4) lands); (3) re-gate
`c13a105` against the switch's lem (row 1 at minimum; fork-drift must read the switch's `lem -v`); (4) cerberus-lean
`mdd/cerberus-lean` e9f9d049f → c13a105, ff-only; then this note's docs branch ff. Landing notes quote the sign-offs.

## 9. Landed (2026-09-25) — the MUST checkpoint on both mainlines; post-landing verification

Executed on [USER 2026-09-25] "Go ahead with merge as planned" (details + verbatim step-2/step-3 lines in the cerberus
closure record's "Landing" section): lem-lean `mdd/lean-backend` 38f87d5 -> 6b20bfd (ff); `deps/lem-pinned` -> 6b20bfd;
`make rebuild-lem` -> `[LEM] installed Lem 6b20bfd`; re-gate of c13a105 under the switch's lem green; cerberus
`mdd/cerberus-lean` e9f9d049f -> 3dd6d1f71 (ff: c13a105 + landing note) -> 27c7ff717 (this note, rebased and ff'd).

Post-landing verification of the primary checkout at 27c7ff717 with the switch's lem (`Lem 6b20bfd`), generated trees
WIPED and re-derived (03:14–03:26 UTC; tree clean before and after), verbatim:

    check_lem_sync: OK (src b2a78090bb9617fa5067c54145df8d775669571e30f0c9629539031975dc6e16, gen b79e328e77aa6c784c2ef260b341c98c473a35bf1e1d1523b73680949ba41d9e)
    check_lem_sync: lean OK (src b2a78090…, gen f4893e95ac3462defae87f737580b172f4e4e1cf35941d5be07edd82c8df808e)
    === REGEN EXIT=0 === / === BUILD_CERBERUS EXIT=0 === / Build completed successfully (395 jobs). === BUILD_LEAN EXIT=0 ===
    Total: 15 passed, 0 failed
    check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …
    check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly …
    check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest … layer 2: 30 differing generated files, all hash-pinned (… lem-pin 6b20bfd02de924d078725efa96c6675115b8b17a matches lem -v 6b20bfd (hex prefix))
    === ROW1 EXIT=0 ===
    SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 … cerb_skip=5 …   Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=2 match=2 fail=0   SUMMARY: total=7 match=7 fail=0   test_address_space: OK (18 cases …)
    OK: lane matches the committed baseline …   SUMMARY: match=12 diff=0   SUMMARY: exec_match=9 neg_pinned=5 fail=0
    SUMMARY: total=93 match=93 … (float)   SUMMARY: total=90 match=66 ub_match=20 … (debug)   SUMMARY: total=212 match=183 ub_match=16 … (coverage) — each Baseline check: 0 regression(s), 0 improvement(s)
    === ALL DONE (post-landing) 2026-09-25T03:26:11Z ===

Pins: lem-lean mainline = deps/lem-pinned = switch lem (prefix) = Lake rev = 3 lake-manifests = fork-drift lem-pin =
6b20bfd02de924d078725efa96c6675115b8b17a. Not pushed; no tag. Next: the SHOULD block review ([USER 2026-09-25] "the
other agent has completed the SHOULD remediation. Review it as you did with the MUST").
