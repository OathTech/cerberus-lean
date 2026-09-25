# Public-readiness M9 — the fresh-clone newcomer test (2026-09-25)

Orchestrator [AGENT], run OUTSIDE the sandbox with network, on the operator's instruction:
[USER 2026-09-25] "Pushed, you can run the test (v. important!)" (after "Okay, you're running outside the sandbox, you
should be able to do the M9 network checks. We won't do automated issue creation (re 1). For (4), this sounds fine").
Method: brand-new directory outside every checkout, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
GIT_TERMINAL_PROMPT=0`, `git -c credential.helper=` — no container env, no redirects, no credentials; every command is
the PUBLIC README's own line, in its order; a NEW local opam switch per repository (authorised). Logs (ephemeral, in the
container's `.tmp/m9-fresh-20260925/`): `lem-quickstart.log`, `cerberus-recipe.log`, `cerberus-fix-test.log`.
Quoted lines are verbatim PREFIXES: long lines were cut at a fixed width and end without a marker (review N-4).
The `OLD_GATE` run in `cerberus-fix-test.log` is NOT a negative control (the copied script resolved its root to the
scratch directory and failed for "missing upstream ref"); the negative control is the twelve-file NEW DRIFT quoted below.

## Public state (anonymous `ls-remote`, verbatim)

    ref: refs/heads/mdd/lean-backend	HEAD                                 (OathTech/lem-lean)
    c2a68e79b6369e19f099dfa48767319c1daf19b3	refs/heads/mdd/lean-backend
    ref: refs/heads/mdd/cerberus-lean	HEAD                                (OathTech/cerberus-lean)
    db5e1feb54226a6335aa89d0824aa9e313314020	refs/heads/mdd/cerberus-lean

Default branches are the fork branches. Fresh anonymous clones: lem-lean 13 MB, cerberus-lean 106 MB (seconds each).
The cerberus lakefile's LemLib pin `c2a68e79…` is PRESENT in the public lem-lean clone and an ancestor of its
`mdd/lean-backend`. Public tags: cerberus-lean three `park/*` record tags; lem-lean none. Upstream: rems-project/lem
`master` = fork `master` (3802cb0, zero behind); rems-project/cerberus `master` = b3e11ea33, 9 commits past the fork's
merge-base b9aeedcb4, 34 files changed, 20 of them in the fork's manifested `[files]` set (32 inside the gate's SURFACES — the 20 plus the 12 listed below; an upstream-PR integration risk, not
an announcement blocker; every front page cites b9aeedcb4 as the reference correctly).

## lem-lean quickstart (`doc/lean-backend/README.md`, literal) — GREEN

    
    === SWITCH_CREATE EXIT=0 17:33:57 ===
    === PIN_ADD EXIT=0 17:34:27 ===
    === MAKE EXIT=0 17:34:49 ===
    === LEAN_LIBS EXIT=0 17:34:51 ===
    Lem c2a68e7
    === LEM_GEN EXIT=0 ===
    === DEMO_LAKE_BUILD EXIT=0 17:35:30 ===
    === COMPREHENSIVE EXIT=0 17:41:24 ===
    === NONLEAN_REGRESS EXIT=0 17:43:10 ===

Demo client (verbatim): `info: Check.lean:3:0: 42` / `Build completed successfully (35 jobs).` — the kernel-checked
`example : double 21 = 42 := rfl` compiled. Comprehensive suite (verbatim):

    === Generation: 56 passed, 0 failed, 0 skipped ===
    nonlean-regress: OK (893 artifact rows, 216 exit rows, 9 emitters, byte-identical to golden)
      OK: 11 proofs modules scanned; no sorry/admit/axiom/native_decide/bv_decide token
      OK: 260 files scanned; no lemDefaultFuel, no LemFuel instance, no literal fuel (F1-F5)
    test_failure_admission: OK (registered probe with compiler failure is red, not XFAIL)
    test_version: OK (untagged, exact annotated tag, dirty tag, post-tag, archive fallback)

Derived: 107 negative probes rejected as declared; parity 4 FAIL lines = the 4 registered XFAILs. Wall time: 17:32:52 -> 17:43:10 UTC.

## cerberus-lean recipe (`lean_frontend/README.md`, literal) — smoke GREEN, row 1 RED twice (two defects found)

    === SWITCH_CREATE EXIT=0 17:45:07 ===
    === PIN_ADD EXIT=0 17:45:40 ===
    === DEPS_INSTALL EXIT=0 17:46:09 ===
    Lem 67ec5de7
    === PRELUDE_SRC EXIT=0 17:46:27 ===
    === DUNE_BUILD EXIT=0 17:46:36 ===
    === DUNE_INSTALL EXIT=0 ===
    === CERBERUS_INSTALL EXIT=0 17:46:37 ===
    === LEAN_PRELUDE_SRC EXIT=0 ===
    info: LemLib: cloning https://github.com/OathTech/lem-lean
    === LEAN_NATIVE_OBJ EXIT=0 ===
    === LAKE_BUILD EXIT=0 17:49:42 ===
    [1/1] MATCH 001-return-literal: VAL:{value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
    === SMOKE EXIT=0 17:49:44 ===
    Lem c2a68e79
    === PRELUDE_SRC EXIT=0 ===

Lake fetched LemLib from `https://github.com/OathTech/lem-lean` at `c2a68e79b6369e19f099dfa48767319c1daf19b3`.
Wall time for the literal smoke: 17:44:01 -> 17:49:44 UTC.

**Defect 1 (mine, from the sweep): README pin line ≠ Lake pin.** `lean_frontend/README.md:93` said
`opam pin add … lem-lean.git#67ec5de…` while the lakefile pins `c2a68e79…`. Following it literally, then the published
fork-drift provisioning (`VALIDATION.md` block, literal — `git fetch upstream master`, clone upstream at the manifest's
`merge-base`, `make prelude-src` there, `CERB_UPSTREAM_TREE`), row 1 failed, verbatim:

    check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=c2a68e79b6369e19f099dfa48767319c1daf19b3, 'lem -v' says 67ec5de7 — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately
    === ROW1 (literal pin 67ec5de7) EXIT=1 17:54:55 ===

Fix: commit 25ef8a26e (README pin command + NOTICE/LICENSE links at `c2a68e79…`; the five "checked against Lem
67ec5de" lines name the landed pin). `Total: 15 passed, 0 failed` held throughout — only the gate failed.

**Defect 2 (latent gate defect, exposed only by a fresh clone): the fork-drift gate diffed against the upstream REF, not
the pinned merge-base.** With the corrected pin (`opam pin add … #c2a68e79…`, rebuilt), verbatim:

    Lem c2a68e79
    check_fork_drift: FAIL — oracle-surface file set drifted from the manifest.
    --- files on the live diff but not in the manifest (NEW DRIFT):
        frontend/model/cabs.lem
        frontend/model/constraint.lem
        frontend/model/errors.lem
        memory/vip/common.ml
        ocaml_frontend/ail_analysis.ml
        ocaml_frontend/pprinters/pp_ail.ml
        ocaml_frontend/pprinters/pp_ail_ast.ml
        ocaml_frontend/pprinters/pp_cabs.ml
        ocaml_frontend/pprinters/pp_errors.ml
        parsers/c/c_parser.mly
        parsers/c/c_parser_error.messages
        util/cerb_floating.ml
    === ROW1 (pin c2a68e79) EXIT=1 17:59:16 ===

Those twelve are exactly upstream's changes since the merge-base: the published recipe fetches CURRENT upstream master
(b3e11ea33) and `check_fork_drift.sh:191` ran `git diff "$UPSTREAM_REF"` — the ref itself — while validating the
merge-base separately. In this container `upstream/master` had never been re-fetched (= the merge-base), which masked
the defect in every gate run since the gate was written. Fix: commit 34cbdbcc6 — layer 1 diffs against `$live_mb`
(the validated, pinned merge-base); header text; plant S31 (a temporary ref `refs/plant/advanced-upstream` at a
synthetic commit on top of the merge-base changing `frontend/model/cabs.lem`; expected OK; ref deleted after and by
the EXIT trap; 31 plants); `VALIDATION.md` provisioning paragraph states the comparison base.

The README's six small lanes were green throughout (before the gate fix; they do not depend on it), verbatim:

    SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsisten
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: exec_match=9 neg_pinned=5 fail=0
    ALL AT COMMITTED EXPECTEDS
    SUMMARY: match=12 diff=0
    ALL MATCH RECORDED BASELINE

## The fix, verified in the same fresh clone (upstream/master really ahead of the merge-base)

`git fetch` of the fix branch into the clone, `git checkout` (6 files, +39/−13; no rebuild needed), then:

      PLANT OK   [S31 upstream ref advanced past the pinned merge-base -> OK (not drift)] rc=0 -> check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no dupl
    check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-list
    check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b
    Total: 15 passed, 0 failed
    check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/t
    test_version: OK (untagged, exact annotated tag, dirty tag, post-tag, archive fallback)
    test_exec_totality: OK (8 plants and 2 clean controls)
    === ROW1 EXIT=0 18:09:37 ===

`git show-ref refs/plant/advanced-upstream` after the self-test: nothing (the temporary ref is gone). The old gate's
red on this clone (the twelve-file NEW DRIFT above) is the negative control for plant S31.

## Verdict [AGENT]

Both published recipes install and build from a fresh anonymous public clone with network: lem-lean's quickstart is
green end to end; cerberus-lean's smoke, unit executables and six small lanes are green, and its row 1 is green once
the two defects above are fixed (commits 25ef8a26e + 34cbdbcc6, branch `docs/public-readiness-pin-citation-fix`). Until
those land and are pushed, a newcomer's row 1 is red at the fork-drift gate. Operator items unchanged: the GitHub
"Issue creation is restricted" setting (no automated issue creation, per the operator), the ISO-fix register's
"filed upstream" criterion, tags and wording. A final literal rerun from a brand-new clone after the push is the last
exit of M9.
