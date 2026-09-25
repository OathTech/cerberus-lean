# Delta review — the M9 fresh-clone fix range (2026-09-25)

[AGENT — independent delta review, Claude Fable subagent, 2026-09-25]. Chartered by the
orchestrator after [USER 2026-09-25] "Great, agree on the reviewer, agree on the merge, agree on
M9 exit". Merge authority rests with the operator; this record is input to that decision.

**Range:** `db5e1feb5..088c6e9c5` on `audit/fresh-clone-fix-20260925` (= the orchestrator's
`docs/public-readiness-pin-citation-fix`, both at `088c6e9c56d5ef7a6bee9264cb0b931229a884ca`):

    088c6e9c5 docs: M9 fresh-clone newcomer test record — both public recipes green from anonymous clones; two defects found and fixed on this branch (README pin line; fork-drift gate diffed against the upstream ref)
    34cbdbcc6 fix(check_fork_drift): compare against the pinned merge-base, not the upstream ref; plant S31 (advanced upstream ref is not drift)
    25ef8a26e docs: the README's opam pin for lem = the Lake LemLib rev (c2a68e79), NOTICE/LICENSE links at that rev; the "checked against Lem 67ec5de" lines name the landed pin

    $ git diff --stat db5e1feb5..088c6e9c5
     lean_frontend/CLAUDE.md                            |   2 +-
     lean_frontend/README.md                            |   8 +-
     lean_frontend/SUPPORTED.md                         |   2 +-
     lean_frontend/TODO.md                              |   2 +-
     lean_frontend/VALIDATION.md                        |   8 +-
     ...2026-09-25_public-readiness-fresh-clone-test.md | 150 +++++++++++++++++++++
     scripts/check_fork_drift.sh                        |  30 ++++-
     7 files changed, 189 insertions(+), 13 deletions(-)

**What I did:** read the three commits hunk by hunk and the whole current
`scripts/check_fork_drift.sh` + `scripts/check_fork_content.py`; read the record and traced its
quoted lines to the three ephemeral logs in `.tmp/m9-fresh-20260925/`; in the fresh anonymous
clone (`upstream/master` = b3e11ea33, nine commits past the pinned merge-base b9aeedcb4) I
reproduced the old layer-1 computation read-only with plain `git diff`/`comm`, and ran the two
permitted commands (`check_fork_drift.sh` and `--selftest`) with `CERB_UPSTREAM_TREE` set;
checked the public lem-lean clone for the linked files at the pinned rev; checked the primary
checkout's `upstream/master` reflog (read-only). **What I did not do:** no builds anywhere
(no lake/dune/make/opam install); nothing modified outside this worktree; the clone's tree
was not edited (the `--selftest` run there writes only the temporary ref and three loose
objects, as designed); the old script was not executed (its ROOT resolution needs it in place;
the negative control is reproduced by the equivalent git commands instead).

## Findings (ranked)

No P1, no P2.

- **P3-1 — S31's temporary ref lives in the SHARED ref namespace.** From a worktree
  `refs/plant/advanced-upstream` resolves to the common dir
  (`cerberus-lean/.git/refs/plant/advanced-upstream`), and `scripts/test_unit.sh:325` runs
  `--selftest` on every invocation. Two `test_unit.sh` runs in two worktrees of one repo race on
  one ref name: the loser can see "missing upstream ref" (its ref deleted by the other's
  `update-ref -d` or EXIT trap) — a FALSE RED. No false green is reachable (reasoned in R-B).
  Remedy after merge: `refs/worktree/plant/advanced-upstream` (the per-worktree namespace,
  `git rev-parse --git-path` confirms it lands under `.git/worktrees/<name>/refs/worktree/`), or
  pass `$adv_commit` directly (the gate treats its argument as a rev: `rev-parse --verify`,
  `merge-base`, `diff` all accept a SHA).
- **P3-2 — stale wording still names `upstream/master` as the diff base**, comment-only:
  `scripts/check_fork_drift.sh:14-15` ("the SET of files on `git diff upstream/master
  --name-only`"), `:267` (the `--refresh`-emitted manifest header "allowed to differ from
  upstream/master") and its committed copy `scripts/fork_drift_manifest.txt:401`. The header
  hunk at :24-28 was updated; these were not. `section()` skips `#` lines, so no gate effect.
- **N-1 — the record's "20 of them on the fork's oracle surface" needs its reading spelled out.**
  Measured: 32 of upstream's 34 changed files lie under the gate's SURFACES; 20 of those are in
  the fork's manifested `[files]` (both sides changed — the integration-risk set) and the other
  12 are exactly the NEW DRIFT list. "20" is right for "in the fork's manifested surface set";
  a parenthetical would remove the ambiguity.
- **N-2 — `cerberus-fix-test.log:2-4` "OLD_GATE EXIT=1 (expected nonzero)" is NOT a valid
  negative control** (it failed with "missing upstream ref 'upstream/master'" — the copied old
  script resolved ROOT outside the clone). The record does not cite it; its negative control is
  PART 3 of `cerberus-recipe.log` (:6207-6221), which I reproduced read-only (R-C).
- **N-3 — dangling objects.** Each `--selftest` leaves one dangling commit in the shared object
  store (the blob and tree are content-identical across runs and dedupe); harmless,
  `git gc --prune`-collectable. Three dangling commits observed in the clone after my run.
- **N-4 — prefix-truncated quotes without a marker.** The record's §"The fix" and lane lines
  are cut at a fixed width mid-token ("no dupl", "inside-list", "b9aeedcb4dd438763b",
  "cerb_inconsistent="); each is a verbatim PREFIX of its log line (all traced), but a reader
  cannot tell they are cut. Suggest an explicit `…`.
- **N-5 — pre-existing, unchanged by the range:** `git merge-base` with no common ancestor
  (unrelated ref, shallow clone) fails with the terse "git merge-base failed"; the layer-1
  `git diff` at :197 has no `|| fail`, but a failure yields a live set that cannot equal the
  85-row manifest, so the gate still FAILS (closed by construction, not by design).

## R-A — the gate fix (`git show 34cbdbcc6 -- scripts/check_fork_drift.sh`)

**(1) Hunk accounting — five hunks:**

| hunk | lines (new) | what | in `gate()`? |
|---|---|---|---|
| 1 | 23-31 | header comment: "upstream/master only LOCATES the merge-base; every comparison is against the pinned merge-base commit" | no |
| 2 | 191-198 | comment + `git diff "$UPSTREAM_REF"` → `git diff "$live_mb"` | **yes — the only behavioural change** |
| 3 | 345-347 | selftest: `PLANTDIR`, `ADV_REF=refs/plant/advanced-upstream`, EXIT trap deletes the ref | selftest only |
| 4 | 416-429 | selftest: plant S31 | selftest only |
| 5 | 495 | SELFTEST OK text 30 → 31 plants | selftest only |

Verbatim hunk 2 (the change):

    -    live_files=$( { git -C "$ROOT" diff "$UPSTREAM_REF" --name-only -- "${SURFACES[@]}";
    +    live_files=$( { git -C "$ROOT" diff "$live_mb" --name-only -- "${SURFACES[@]}";
                        git -C "$ROOT" ls-files --others --exclude-standard -- "${SURFACES[@]}"; } | sort -u)

**(2) `$live_mb` is defined and validated before use on every path.** Current script, verbatim:

    154	    local pinned_mb live_mb pinned_lem live_lem live_prefix
    155	    pinned_mb=$(section meta | sed -n 's/^merge-base=//p')
    156	    [[ -n "$pinned_mb" ]] || fail "manifest has no [meta] merge-base= line"
    ...
    161	    live_mb=$(git -C "$ROOT" merge-base "$UPSTREAM_REF" HEAD) || fail "git merge-base failed"
    162	    if [[ "$live_mb" != "$pinned_mb" ]]; then
    163	        fail "merge-base moved: manifest pins $pinned_mb, live is $live_mb — $UPSTREAM_REF or the fork history changed; run the refresh recipe (deliberate commit) after re-review"
    164	    fi
    ...
    197	    live_files=$( { git -C "$ROOT" diff "$live_mb" --name-only -- "${SURFACES[@]}";

`gate()` is straight-line from :133 to :197; `REFRESH` first branches at :200, so `gate`
(`... 0`, :328), `--refresh` (`... 1`, :332) and every selftest plant (`gate "$@"` in a subshell,
:360-362) all pass :161-164 before :197. The dev-skip opt-in exits at :140 only when the ref is
MISSING — before `$live_mb` exists and before any diff; with the ref present, dev-skip changes
nothing until layer 2 (:235). `set -u` is on; `live_mb` is declared `local` at :154 and assigned
at :161, so no unbound-variable path exists. At :197 the commit named by `$live_mb` necessarily
exists locally (it is the computed merge-base) and equals the pinned one.

**(3) Nothing else compares against the moving ref.** Occurrences of `$UPSTREAM_REF` in
`gate()`: :133 (`rev-parse --verify` — existence), :134-142 (messages), :161 (`merge-base` —
location), :163 (message). `scripts/check_fork_content.py` (90 lines) takes the path list on
stdin and hashes `--root/<name>` from the working tree — no git, no ref:

    64:        names = sys.stdin.read().splitlines()
    69:        live = {name: identity(args.root / name) for name in sorted(names)}

Layer 2 (:242-318) diffs the two generated TREES; no ref involved.

**(4) `--refresh` records merge-base-relative files:** the same `live_files` (:197) is written
at :278 (`[files]`) and piped to `--emit` at :280 (`[source-content]`); `merge-base=$live_mb` at
:275. Consistent.

**(5) Failure modes.** (a) Upstream force-push / merge-base moved: the merge-base check
(:161-164) runs BEFORE the diff (:197) → `FAIL — merge-base moved: manifest pins …, live is …`.
(b) `upstream/master` missing: :133-143 unchanged; plant S6 still passes (below). (c) The pinned
merge-base commit absent locally: `git merge-base` returns whatever common ancestor exists
locally (≠ pinned) → "merge-base moved" naming both hashes; with NO common ancestor (unrelated
ref, shallow clone) → rc 1 → `FAIL — git merge-base failed` (terse; pre-existing; N-5). The new
line :197 cannot itself hit a missing object.

## R-B — plant S31

Verbatim (current :416-429):

    adv_mb=$(awk '/^\[meta\]/{s=1;next} /^\[/{s=0} s && /^merge-base=/{sub(/^merge-base=/,""); print}' "$MANIFEST_DEFAULT")
    adv_blob=$(printf 'plant S31: upstream advanced past the merge-base\n' | git -C "$ROOT" hash-object -w --stdin)
    adv_tree=$(GIT_INDEX_FILE="$PLANTDIR/adv.idx" git -C "$ROOT" read-tree "$adv_mb" \
               && GIT_INDEX_FILE="$PLANTDIR/adv.idx" git -C "$ROOT" update-index --add --cacheinfo "100644,$adv_blob,frontend/model/cabs.lem" \
               && GIT_INDEX_FILE="$PLANTDIR/adv.idx" git -C "$ROOT" write-tree)
    adv_commit=$(GIT_AUTHOR_NAME=plant GIT_AUTHOR_EMAIL=plant@localhost GIT_COMMITTER_NAME=plant GIT_COMMITTER_EMAIL=plant@localhost \
                 git -C "$ROOT" commit-tree "$adv_tree" -p "$adv_mb" -m "plant S31: upstream advanced past the merge-base")
    git -C "$ROOT" update-ref "$ADV_REF" "$adv_commit"
    plant "S31 upstream ref advanced past the pinned merge-base -> OK (not drift)" 0 "$OKMSG" C 0 "$PLANTDIR/m.c" "$ADV_REF" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
    git -C "$ROOT" update-ref -d "$ADV_REF"

- **Reaches the new code path.** The synthetic commit's parent is the pinned merge-base, so
  `merge-base(ADV_REF, HEAD)` = the pinned one (the fork HEAD descends from it; the synthetic
  commit is not an ancestor of HEAD) → :162 passes → :197 diffs against it → 85 files → OK.
- **Non-vacuous under the old code.** `frontend/model/cabs.lem` is under SURFACE `frontend`,
  is NOT in the manifest (`grep -n cabs.lem scripts/fork_drift_manifest.txt` → rc 1), and is
  byte-identical at HEAD and the merge-base (`git diff --quiet b9aeedcb4 HEAD --
  frontend/model/cabs.lem` → identical, in the clone). Old code: `git diff refs/plant/advanced-
  upstream --name-only` includes cabs.lem → 86 ≠ 85 → `FAIL — … drifted` → plant wants rc 0 +
  OKMSG → PLANT FAIL. The negative control on the real clone is the same mechanism with twelve
  files (R-C).
- **Ref lifecycle.** Created with `update-ref` (:427), deleted at :429 AND by the EXIT trap
  (:347, verbatim):

      trap 'rm -rf "$PLANTDIR"; if git -C "$ROOT" show-ref --verify -q "$ADV_REF"; then git -C "$ROOT" update-ref -d "$ADV_REF"; fi' EXIT

  Single-quoted (expands at fire time); `ROOT` (:89), `PLANTDIR` (:345), `ADV_REF` (:346) are
  all set before the trap is installed. Plants run `gate` inside `( … )` (:360-362), so `fail`'s
  `exit 1` ends only the subshell and the selftest continues; the top-level exits are :496/:498
  and the `exit 1` at :445, all of which fire the trap. A `SIGKILL` between :427 and :429 leaves
  the ref; the next run's `update-ref` overwrites it and its trap removes it (self-healing).
  Failure of any of :421-426 leaves `adv_commit` empty → `update-ref` refuses → the plant sees
  "missing upstream ref" → rc 1 ≠ 0 → PLANT FAIL (closed).
- **Shared namespace (P3-1).** From this worktree:

      $ git rev-parse --git-dir --git-common-dir
      /home/dev/projects/cerberus-lean-proj/cerberus-lean/.git/worktrees/fresh-clone-fix-20260925
      /home/dev/projects/cerberus-lean-proj/cerberus-lean/.git
      $ git rev-parse --git-path refs/plant/advanced-upstream
      /home/dev/projects/cerberus-lean-proj/cerberus-lean/.git/refs/plant/advanced-upstream
      $ git rev-parse --git-path refs/worktree/plant/x
      /home/dev/projects/cerberus-lean-proj/cerberus-lean/.git/worktrees/fresh-clone-fix-20260925/refs/worktree/plant/x

  False-green analysis: if worktree B overwrites A's ref with B's synthetic commit, A's plant
  either sees an identical construction (same pinned merge-base → OK, and the plant's premise
  still holds) or a different merge-base → "merge-base moved" → FAIL; deletion → "missing
  upstream ref" → FAIL. Only false reds are reachable. No leftover ref in the shared store now
  (`git show-ref | grep refs/plant` → none).
- **Objects:** `hash-object -w`, `write-tree`, `commit-tree` write three loose objects that are
  unreachable after the ref deletion (N-3). In the clone after the orchestrator's run(s) and mine:

      dangling commit bd5730d8363782a8881419d36d3b977698ad046f
      dangling commit 498342b33e24ea17ec5663235ac5ac6717a8ab77
      dangling commit 4e78bf937d7412aa338b00c3250151b13f66453f

- **`GIT_INDEX_FILE`** is `$PLANTDIR/adv.idx`; `mktemp -d` yields an absolute path (the plant
  output shows `/tmp/tmp.RWgXiCzEwd/…`), so `git -C "$ROOT"` cannot mis-resolve it. `read-tree`
  of a commit-ish and the comma form of `--cacheinfo` are fine on git 2.43.0.
- **Author identity** is supplied via `GIT_{AUTHOR,COMMITTER}_{NAME,EMAIL}`; the clone has no
  identity (`git config --local user.name` → rc 1) and the orchestrator ran with
  `GIT_CONFIG_GLOBAL=/dev/null`; both their run and mine show `PLANT OK [S31 …]`.
- **Count:** `grep -c -E '^(plant|version_plant) "S[0-9]+'` → 31; labels S1…S31 each once.

**My selftest run in the clone** (`CERB_UPSTREAM_TREE=$PWD/.validation-foundations/fork-drift-
upstream/ocaml_frontend/generated`, `opam exec --switch=. -- ./scripts/check_fork_drift.sh
--selftest`), verbatim tail:

      PLANT OK   [S6 missing upstream ref -> FAIL (not a skip)] rc=1 -> check_fork_drift: FAIL — missing upstream ref 'plant/no-such-ref' (fail-closed; the development opt-in is CERB_FORK_DRIFT_DEV_SKIP=1)
      PLANT OK   [S31 upstream ref advanced past the pinned merge-base -> OK (not drift)] rc=0 -> check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef
      PLANT OK   [S7 missing upstream generated tree -> FAIL (not a skip)] rc=1 -> check_fork_drift: FAIL — layer 2 prerequisite missing (fail-closed; the development opt-in is CERB_FORK_DRIFT_DEV_SKIP=1): upstream pristine tree not found (set CERB_UPSTREAM_TREE; see lean_frontend
    ...
      UNPLANTED:
        check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 matches lem -v c2a68e79 (hex prefix))
    check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)

31 `PLANT OK` lines for S1–S31 plus the S4/S29 detail checks; zero `PLANT FAIL`. Afterwards
`git show-ref refs/plant/advanced-upstream` → rc 1 (absent). Before my run it was also absent
(checked first), confirming the record's :139 claim independently of the log (which does not
contain that `show-ref`).

**The gate itself in the clone** (upstream/master = b3e11ea33, ahead of the merge-base), verbatim:

    check_fork_content: OK — 85 source files content/mode-pinned
    check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 matches lem -v c2a68e79 (hex prefix))
    GATE rc=0

## R-C — docs

**25ef8a26e.** README pin command = lakefile rev:

    lean_frontend/lakefile.toml:70:rev = "c2a68e79b6369e19f099dfa48767319c1daf19b3"
    lean_frontend/README.md:93:opam pin add --switch=. lem git+https://github.com/OathTech/lem-lean.git#c2a68e79b6369e19f099dfa48767319c1daf19b3 --yes

NOTICE/LICENSE links resolve at that rev in the public lem-lean clone
(`.tmp/m9-fresh-20260925/lem-lean`): `git cat-file -e c2a68e79…:lean-lib/NOTICE.md` → EXISTS;
`…:LICENSE` → EXISTS (there is no top-level `NOTICE.md` nor `lean-lib/LICENSE` — the README links
the two that exist). c2a68e79 is `origin/mdd/lean-backend` there and `merge-base --is-ancestor`
holds. The five "checked against Lem 67ec5de" annotations ("the pinned Lem mainline is
`c2a68e79…`, ahead of the checked revision by comments and records only") are TRUE:

    $ git -C lem-lean diff --stat 67ec5de c2a68e7
     ...026-09-24_public-readiness-must-delta-review.md | 611 +++++++++++++++++++++
     .../2026-09-25_public-readiness-followup.md        |  10 +
     ...6-09-25_public-readiness-should-delta-review.md | 252 +++++++++
     lean-lib/LemLib.lean                               |   9 +-
     lean-lib/NOTICE.md                                 |   2 +
     5 files changed, 883 insertions(+), 1 deletion(-)

The `LemLib.lean` hunk is entirely inside the `/- … -/` doc comment above
`@[never_extract] def fuelExhausted` (the attribute line is unchanged context). Five sites
annotated: `README.md:4`, `SUPPORTED.md:4`, `CLAUDE.md:5`, `TODO.md:10`, `VALIDATION.md:4` —
`grep -rn 67ec5de` over the six front docs finds exactly those five, all carrying the annotation.

**VALIDATION.md paragraph (34cbdbcc6)** — "The gate compares the fork against the PINNED
merge-base commit (`merge-base=` in `scripts/fork_drift_manifest.txt`), which `upstream/master`
only serves to locate and validate; fetching a newer upstream master is therefore not drift" —
matches :161-164/:197 exactly. It sits directly under the provisioning block whose
`git fetch upstream master:refs/remotes/upstream/master` line is what exposed the defect.

**The record (088c6e9c5) — traceability.** Every quoted line I checked is verbatim in a log
(line numbers are the logs'; the record's truncated lines are verbatim prefixes, N-4):

| record line | log:line |
|---|---|
| :77 `check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=c2a68e79…, 'lem -v' says 67ec5de7 …` | `cerberus-recipe.log:3199` |
| :78 `=== ROW1 (literal pin 67ec5de7) EXIT=1 17:54:55 ===` | `cerberus-recipe.log:3243` |
| :87-:100 `check_fork_drift: FAIL — oracle-surface file set drifted from the manifest.` + the twelve files | `cerberus-recipe.log:6207-6220` (the "no longer on the live diff" list at :6221 is EMPTY) |
| :101 `=== ROW1 (pin c2a68e79) EXIT=1 17:59:16 ===` | `cerberus-recipe.log:7399` |
| :64/:65 smoke MATCH / `=== SMOKE EXIT=0 17:49:44 ===` | `cerberus-recipe.log:3149`, `:3176` |
| :113 `SUMMARY: total=113 match=90 ub_match=18 …` / :123-:124 | `cerberus-recipe.log:7555`, `:8157-8158` |
| :130 `PLANT OK   [S31 …] rc=0 -> check_fork_drift: OK — layer 1: 85 …` | `cerberus-fix-test.log:912` |
| :131 `check_fork_drift: SELFTEST OK (31 plants …` | `cerberus-fix-test.log:941` |
| :132 `check_fork_drift: OK — layer 1: 85 … (merge-base b9aeedcb4dd438763b` | `cerberus-fix-test.log:943` (row-1 gate; also :940 indented UNPLANTED) |
| :133-:137 `Total: 15 passed, 0 failed` / `check_failure_reach: OK (239 …` / `test_exec_totality: OK (8 plants and 2 clean controls)` / `=== ROW1 EXIT=0 18:09:37 ===` | `cerberus-fix-test.log:575`, `:888`, `:900`, `:958` |
| :28-:36 the eight lem-quickstart EXIT lines; :41-:46 the six suite lines; :32 `Lem c2a68e7`; :38 demo lines | `lem-quickstart.log:27, 59, 2288, 2309, 2313, 2371, 3852, 3855; 2433, 3854, 3848, 3850, 2375, 2374; 2310; 2369-2370` |

Derived claims checked: :128 "6 files, +39/−13" → `git diff --stat db5e1feb5 34cbdbcc6` =
`6 files changed, 39 insertions(+), 13 deletions(-)`; :21 "9 commits past the fork's merge-base
b9aeedcb4, 34 files changed" → `rev-list --count` = 9, `diff --name-only | wc -l` = 34; "20 of
them on the fork's oracle surface" → 20 = |upstream-changed ∩ manifest `[files]`| (N-1);
:105 "In this container `upstream/master` had never been re-fetched" → the primary's reflog has
exactly one entry, `b9aeedcb4 refs/remotes/upstream/master@{2026-08-21 11:50:14 +0000}: fetch
upstream: storing head`, and `rev-parse upstream/master` = b9aeedcb4 = the pinned merge-base.

**The negative control.** The record's :139-140 "The old gate's red on this clone (the
twelve-file NEW DRIFT above) is the negative control for plant S31" points at PART 3
(`cerberus-recipe.log:6207-6221`), NOT at the `OLD_GATE` attempt in `cerberus-fix-test.log:2-4`
(which failed for the wrong reason — N-2 — and is correctly not relied upon). I reproduced the
old layer-1 computation read-only in the clone (the gate's SURFACES array, `git diff
upstream/master --name-only -- … ; ls-files --others …`, `sort -u`, `comm -23` against the
manifest `[files]`):

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
    --- manifest-only under old code:
    (empty)

— exactly the record's twelve; and (upstream-changed surface files) \ manifest = 12 as well, so
"Those twelve are exactly upstream's changes since the merge-base" (:103) holds. The NEW
computation (`git diff b9aeedcb4 …`) gives 85 files and `cmp` against the manifest set reports
`NEW live set == manifest set`.

## R-D — policy

- No new gate or executable: S31 is one more plant inside the existing `--selftest`; no new
  script, no new lake target.
- Fail-closed and non-vacuous: S31 expects rc 0 AND the OK message; it fails under the old diff
  base (R-B) and on any construction failure.
- No `2>/dev/null` added: `git show 34cbdbcc6 -- scripts/check_fork_drift.sh | grep -E
  '^\+.*/dev/null'` → nothing. The trap's `show-ref --verify -q` is a quiet flag, not a redirect;
  its only role is to decide whether to delete.
- Provenance: the record opens with [USER 2026-09-25] quotes and closes with a labelled
  `## Verdict [AGENT]`; the two fix commits state the finding that motivated them.
- Dated records: `git diff --stat db5e1feb5..088c6e9c5 -- lean_frontend/docs/` touches only the
  new `2026-09-25_public-readiness-fresh-clone-test.md` (150 insertions, 0 deletions).

## R-E — merge readiness

- `git merge-base --is-ancestor db5e1feb5 088c6e9c5` → yes; `mdd/cerberus-lean` =
  `db5e1feb54226a6335aa89d0824aa9e313314020` = the range base, so the merge is ff-only WITHOUT a
  rebase — which matters because the record embeds the sibling hashes `25ef8a26e` and `34cbdbcc6`
  (a rebase would invalidate them).
- The range is `scripts/check_fork_drift.sh` + five front docs + one new dated record; no
  generated tree, manifest, Lake or opam pin moves; `check_fork_drift.sh` is not itself a
  manifested surface file (SURFACES lists only `scripts/common.sh`), so no `--refresh` is due —
  confirmed by the green gate in the clone on the fixed script.
- **Behaviour-neutral in the container:** the primary's `upstream/master` is b9aeedcb4 = the
  pinned merge-base, so `git diff upstream/master` and `git diff "$live_mb"` are the same
  comparison there — identical `live_files`, identical verdicts. The one new container-side
  side effect is S31's transient shared ref plus three loose objects per selftest run (P3-1,
  N-3); neither can turn a red green.

## VERDICT [AGENT]

The behavioural change is exactly the one claimed — one token in `gate()`, layer 1's diff base
`"$UPSTREAM_REF"` → `"$live_mb"`, where `$live_mb` is computed and validated equal to the pinned
merge-base on every path before use, the merge-base-moved check still runs first, `--refresh`
now records the same merge-base-relative set, and `check_fork_content.py` never touched a ref.
Plant S31 reaches the new path and is non-vacuous under the old code; the temporary ref is
removed on both the normal and the trap path; the fix is verified green in the fresh clone
whose `upstream/master` really is nine commits ahead (gate and 31-plant selftest, rerun by me).
The docs commit's pin equals the lakefile rev, the linked files exist at that rev in the public
clone, and the "comments and records only" annotation is literally true. The record's quotes
trace to the logs and its negative control is the valid PART 3 red, not the mis-resolved
`OLD_GATE` attempt. No P1/P2. Two P3s to take after merge — put S31's ref in the per-worktree
namespace (or pass the SHA) to remove a false-red race between concurrent worktree selftests,
and finish the header/refresh-template wording — plus the notes above. From this reviewer's
standpoint the range is ready for the operator's ff-only merge decision.
