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

**Second pass (same day, coordinator's scope additions):** the fix branch gained two more commits
while the first pass was under way — `a4d72a3fc` (the row-1 pin-site agreement leg
`scripts/check_pin_sites.sh`, its `test_unit.sh` wiring and a VALIDATION.md gate-table row) and
`82862ca74` (this review's P3-1/P3-2 remediations + record notes N-1/N-2/N-4). Sections R-F and
R-G below cover them; the findings list and the verdict are for the FIVE-commit range
`db5e1feb5..82862ca74a2de6b189faf6a9cf22def2efad0c5b` (10 files, +308/−15). The first-pass
sections R-A…R-E are left as written (they describe 088c6e9c5 and remain true of it).

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

## Findings (ranked; status after the THIRD pass, range db5e1feb5..2e88f21c0)

No P1, no P2 in any pass.

Open after the third pass (after-merge):

- **P3-5 — stale plant count in VALIDATION.md's gate-table row:** the row added by `a4d72a3fc`
  says "5 plants"; after `2e88f21c0` the script's SELFTEST OK line, `lean_frontend/CLAUDE.md` and
  `scripts/LADDER.md` all say 8. One-word fix.

Resolved on-branch by the 6th commit `2e88f21c0` (verified in R-H): **P3-3** (every
`lem-lean.git#<fragment>` must equal the full pin; probe A now FAILs; plant P6) and **P3-4**
(the leg is named in LADDER.md row 1 and the CLAUDE.md gate list). New notes **N-9..N-11** in R-H.

Status after the second pass (kept): open then, both from the 4th commit `a4d72a3fc`:

- **P3-3 — `check_pin_sites.sh` README parser: a non-hex fragment is silently skipped.**
  `grep -o 'lem-lean\.git#[0-9a-f]*'` matches ZERO hex characters for `lem-lean.git#<branch>`, the
  `sed 's/.*#//'` leaves an empty hash, and `:56 [[ -z "$h" ]] && continue` drops it. With a valid
  pin line also present, a second occurrence `…lem-lean.git#mdd/lean-backend` (a MOVING pin — worse
  than a wrong hash) passes: probe A below, rc 0. The sole-occurrence case fails closed (P5). Fix
  after merge: match any fragment (`lem-lean\.git#[^[:space:]"'\`)]*`) and require each to be the
  full 40-hex pin, or require the count of `lem-lean.git#` occurrences to equal the count of
  matched hashes; add the plant.
- **P3-4 — the new leg is not named where row 1's legs are enumerated:** `scripts/LADDER.md:43`
  (Tier A row 1's leg list names fork-drift, fixture-freeze, renumber plants, failure-reach …) and
  `lean_frontend/CLAUDE.md:120-152` (the gate list with plant counts) do not mention
  `check_pin_sites.sh`; only VALIDATION.md's gate table has its row. `grep -c check_pin_sites`:
  CLAUDE.md 0, LADDER.md 0, VALIDATION.md 1, README.md 0.

Resolved on-branch by the 5th commit `82862ca74` (verified in R-G): **P3-1** (S31 now passes the
synthetic commit hash directly; no ref, one-line trap), **P3-2** (header :14, refresh template :267,
manifest :401 name the pinned merge-base), **N-1** (the "20" parenthetical), **N-2/N-4** (the record
now states that quotes are verbatim prefixes and that `OLD_GATE` is not a negative control).

Standing notes: **N-3** (dangling objects — now stated in the S31 comment), **N-5** (pre-existing
terse `merge-base` failure), plus new **N-6..N-8** (R-F/R-G).

First-pass findings as originally written (kept for the record; status above):

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

## First-pass VERDICT [AGENT] (range db5e1feb5..088c6e9c5, superseded by the five-commit verdict below)

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
and finish the header/refresh-template wording — plus the notes above.

---

# Second pass — commits `a4d72a3fc` and `82862ca74`

    $ git log --oneline db5e1feb5..82862ca74
    82862ca74 fix(check_fork_drift selftest): S31 passes the synthetic commit hash directly (no shared ref — review P3-1); merge-base wording (P3-2); record notes N-1/N-4
    a4d72a3fc gate(row 1): pin-site agreement leg — manifest lem-pin = Lake rev = three lake-manifests = README pin command (5 plants), wired after the fork-drift gate
    088c6e9c5 docs: M9 fresh-clone newcomer test record — …
    34cbdbcc6 fix(check_fork_drift): compare against the pinned merge-base, not the upstream ref; plant S31 (advanced upstream ref is not drift)
    25ef8a26e docs: the README's opam pin for lem = the Lake LemLib rev (c2a68e79), …

    $ git diff --stat db5e1feb5 82862ca74
     lean_frontend/CLAUDE.md                            |   2 +-
     lean_frontend/README.md                            |   8 +-
     lean_frontend/SUPPORTED.md                         |   2 +-
     lean_frontend/TODO.md                              |   2 +-
     lean_frontend/VALIDATION.md                        |   9 +-
     ...2026-09-25_public-readiness-fresh-clone-test.md | 153 +++++++++++++++++++++
     scripts/check_fork_drift.sh                        |  29 +++-
     scripts/check_pin_sites.sh                         | 100 ++++++++++++++
     scripts/fork_drift_manifest.txt                    |   2 +-
     scripts/test_unit.sh                               |  16 +++
     10 files changed, 308 insertions(+), 15 deletions(-)

What I did for this pass: read `check_pin_sites.sh` (100 lines) and the `test_unit.sh`/VALIDATION
hunks; inspected the real pin sites at `a4d72a3fc` (lakefile `[[require]]` blocks, the three
lake-manifests' LemLib entries, the README's `lem-lean.git#` occurrences, the manifest `lem-pin`);
ran the leg read-only with `--root` against mainline (primary checkout), against my worktree
(site files = fix head) and against the fresh clone; ran its `--selftest` from a temporary
untracked copy in my worktree's `scripts/` (removed afterwards); probed its parsers on scratch
copies of the six files (probes A–E). For the 5th commit: cumulative diff, greps, manifest
non-comment equivalence, read-only raw-hash acceptance in the clone, and a full `--selftest` +
gate of the 5th-commit script in my worktree (provisioned temporarily with a copy of the primary's
gitignored `ocaml_frontend/generated` and `CERB_UPSTREAM_TREE` = the container's
`deps/cerberus-upstream` tree; the two checked-out files were restored to my HEAD and the copy
removed; `git status` clean). No builds; nothing outside my worktree modified except the
selftest's by-design loose objects in the shared store.

## R-F — the 4th commit: `scripts/check_pin_sites.sh` + row-1 wiring + VALIDATION row

**(1) Do the parsers read the sites correctly, fail-closed?** Real site shapes at `a4d72a3fc`:

    lean_frontend/lakefile.toml
    67:[[require]]
    68:name = "LemLib"
    69:git = "https://github.com/OathTech/lem-lean"
    70:rev = "c2a68e79b6369e19f099dfa48767319c1daf19b3"
    71:subDir = "lean-lib"            (the ONLY [[require]] block in the file)
    lake-manifests (name type rev inputRev url):
    lean_frontend/lake-manifest.json                 LemLib git c2a68e79… c2a68e79… https://github.com/OathTech/lem-lean
    lean_frontend/speclab/lake-manifest.json         LemLib git c2a68e79… c2a68e79… https://github.com/OathTech/lem-lean
    tests/mem-scale-probes/micro/lake-manifest.json  LemLib git c2a68e79… c2a68e79… https://github.com/OathTech/lem-lean
    lean_frontend/README.md:93   lem-lean.git#c2a68e79b6369e19f099dfa48767319c1daf19b3   (the only occurrence)
    scripts/fork_drift_manifest.txt:418  lem-pin=c2a68e79b6369e19f099dfa48767319c1daf19b3

- Manifest (:24-26): missing file → FAIL; `lem-pin` must be exactly one full 40-hex value — a
  deleted line (P4) or a DUPLICATED line both fail (probe E, verbatim):

      check_pin_sites: FAIL — manifest [meta] lem-pin is not one full 40-hex commit: 'c2a68e79b6369e19f099dfa48767319c1daf19b3
      c2a68e79b6369e19f099dfa48767319c1daf19b3'

- lakefile (:30-32): `awk '/^\[\[require\]\]/{r=1} r && /^name = "LemLib"/{n=1} r && n && /^rev = "/{…; exit}'`
  — prints the first `rev = "` AFTER the `name = "LemLib"` line; on the real file that is :70.
  Fail-closed but brittle (N-7): a legal TOML reordering with `rev` before `name` reads as
  "no LemLib rev found" (probe D, rc 1); a missing lakefile fails with awk's error text embedded
  (probe C, verbatim):

      check_pin_sites: FAIL — /tmp/dr-pinprobe.IWh7uu/c/lean_frontend/lakefile.toml LemLib rev = awk: fatal: cannot open file `/tmp/dr-pinprobe.IWh7uu/c/lean_frontend/lakefile.toml' for reading: No such file or directory ≠ lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3

  and because `r`/`n` are never reset, a LemLib block WITHOUT `rev` followed by another block WITH
  one would attribute the later rev to LemLib (then almost surely ≠ pin → FAIL; today there is
  exactly one `[[require]]`). Also format-sensitive (`name = ` with single spaces) — a reformat
  fails loud, not silent.
- lake-manifests (:34-49): explicit `-f` check; `python3 json.load`; every package named `LemLib`
  contributes `rev` and `inputRev`, each defaulting to `<none>` (≠ pin → FAIL) when absent; no
  LemLib package or unparsable JSON → empty → FAIL "no LemLib package". Closed.
- README (:53-58): every `lem-lean.git#<hex>` must equal the pin; none → FAIL (P5); an
  ABBREVIATED hash fails (probe B, verbatim):

      check_pin_sites: FAIL — /tmp/dr-pinprobe.IWh7uu/b/lean_frontend/README.md pins lem-lean.git#c2a68e79 ≠ lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 (the README's own rule: equal to lean_frontend/lakefile.toml)

  but a NON-HEX fragment alongside a valid pin is skipped (P3-3; probe A, verbatim — the scratch
  README has :93 `lem-lean.git#c2a68e79…` and an appended :237 `lem-lean.git#mdd/lean-backend`):

      check_pin_sites: OK — lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
      probe A rc=0

- `--root DIR` (:98-99): a nonexistent DIR → `cd` fails → `ROOT=""` → manifest missing → FAIL; a
  missing argument → `set -u` abort (closed, ugly). `check` accumulates `rc` and reports EVERY
  mismatch, not the first. No `2>/dev/null` anywhere in the commit (`git show a4d72a3fc | grep
  '^+.*2>/dev/null'` → none; :30's `2>&1` captures, it does not discard).

**(2) Are the 5 plants non-vacuous?** Each plant checks rc AND a message substring naming the
planted value; a plant whose `sed` misses leaves the copy identical to the P0 control, so it would
return rc 0 → `PLANT FAIL (wanted nonzero)` — premise failure is loud. P1 is the 2026-09-25 defect
exactly (README → `67ec5de7…` against pin `c2a68e79…`; `stale` falls back to zeros if the pin
itself were 67ec5de). My run (temporary untracked copy in my worktree; site files = fix head),
verbatim:

    check_pin_sites: SELFTEST — plants on scratch copies (loud plant banner; nothing in the tree is touched)
      PLANT OK   [P0 unplanted copies] rc=0 -> check_pin_sites: OK — lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
      PLANT OK   [P1 README pin command names another commit (the 2026-09-25 fresh-clone defect)] rc=1 -> check_pin_sites: FAIL — /tmp/tmp.Vkor9OrOGK/readme/lean_frontend/README.md pins lem-lean.git#67ec5de70e02e280bb348a4ba826696b76116732 ≠ lem-pin c2a68e79b636
      PLANT OK   [P2 lakefile LemLib rev differs] rc=1 -> check_pin_sites: FAIL — /tmp/tmp.Vkor9OrOGK/lakefile/lean_frontend/lakefile.toml LemLib rev = 67ec5de70e02e280bb348a4ba826696b76116732 ≠ lem-pin c2a68e79b63
      PLANT OK   [P3 one lake-manifest inputRev differs] rc=1 -> check_pin_sites: FAIL — lean_frontend/speclab/lake-manifest.json LemLib rev/inputRev = 67ec5de70e02e280bb348a4ba826696b76116732 ≠ lem-pin c2a68e79b6369e19f0
      PLANT OK   [P4 manifest lem-pin missing] rc=1 -> check_pin_sites: FAIL — manifest [meta] lem-pin is not one full 40-hex commit: ''
      PLANT OK   [P5 README has no pin command at all] rc=1 -> check_pin_sites: FAIL — /tmp/tmp.Vkor9OrOGK/noreadme/lean_frontend/README.md has no 'lem-lean.git#<hash>' pin command
    check_pin_sites: SELFTEST OK (5 plants red with the declared message, unplanted copies green)
    SELFTEST rc=0

Coverage gaps (N-8): no plant for a lake-manifest `rev` (as opposed to `inputRev`) mismatch —
same loop, same comparison; none for a missing lake-manifest file or a manifest without a LemLib
package (both closed by code); none for a second `lem-lean.git#` occurrence (which would have
caught P3-3). GNU `sed -i` / `0,/re/` forms — Linux-only, like the other gates.

**(3) FAILS on mainline, passes on the fix head.** The script extracted from `a4d72a3fc` to
`/tmp` and run with `--root` (read-only):

    $ bash /tmp/dr-check_pin_sites.sh --root /home/dev/projects/cerberus-lean-proj/cerberus-lean     # HEAD = db5e1feb5
    check_pin_sites: FAIL — /home/dev/projects/cerberus-lean-proj/cerberus-lean/lean_frontend/README.md pins lem-lean.git#67ec5de70e02e280bb348a4ba826696b76116732 ≠ lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 (the README's own rule: equal to lean_frontend/lakefile.toml)
    rc=1
    $ bash /tmp/dr-check_pin_sites.sh --root <my worktree>          # site files = the fix head's
    check_pin_sites: OK — lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
    rc=0
    $ bash /tmp/dr-check_pin_sites.sh --root .tmp/m9-fresh-20260925/cerberus-lean   # 34cbdbcc6
    check_pin_sites: OK — lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
    rc=0

(mainline README:93 = `lem-lean.git#67ec5de70e02e280bb348a4ba826696b76116732`, lakefile rev and
manifest lem-pin = c2a68e79 — the exact defect.)

**Wiring.** `scripts/test_unit.sh` (+16): directly after the fork-drift gate block,
`PIN_SITES_SH="$(dirname "$PURITY_SH")/check_pin_sites.sh"` (`PURITY_SH` is `<scripts dir>/
check_exec_purity.sh`, :10), then `--selftest` and the gate, each `exit 1` on failure. Sub-second.
The 4th commit changes no manifested SURFACE file (`git diff --name-only 088c6e9c5 a4d72a3fc --
<SURFACES>` → empty), so no fork-drift `--refresh` is due.

**Docs.** VALIDATION.md gate table gains one row (accurate: sites, "fresh-clone finding 2026-09-25;
5 plants"). LADDER.md row 1 and `lean_frontend/CLAUDE.md`'s gate list do not name it (P3-4).

**(4) Policy judgement [AGENT] — trust-load-bearing, not cruft.** The property is already
normative in the container practices ("lem-lean pins: `deps/lem-pinned` = opam pin = all cerberus
Lake pins (Lake rev, three lake-manifests, `scripts/fork_drift_manifest.txt` `lem-pin` …)"; "An
arc closes only when branch heads = opam pin = Lake pin"); the leg mechanizes its REPO-side half.
It is load-bearing because the manifest `lem-pin` certifies which lem derived BOTH generated OCaml
trees, the Lake rev / manifests decide which LemLib the generated Lean links against, and the
README line decides which lem a newcomer's reproduction of row 1 uses — a disagreement at any
site makes the "one lem" premise of the trust story false or unreproducible, which is exactly
what happened on 2026-09-25 (a literal newcomer's row 1 red). It complements, not duplicates,
`check_fork_drift.sh`'s lem-pin check (installed `lem -v` vs the manifest; this leg is the WRITTEN
sites vs the manifest). It is cheap (no build, <1 s), plant-tested with the real defect as P1,
fail-closed, and placed inside the existing row-1 caller rather than as a new row or tier — the
two-tier rule's shape. Caveat: it should stay a one-value-agreement check; the README site is
justified only because that line is an executable input carrying its own "Keep this revision
equal to lean_frontend/lakefile.toml" rule, not a licence to lint prose. The container-side
equalities (`deps/lem-pinned`, the opam pin) remain operator-checked (N-8).

## R-G — the 5th commit: P3-1/P3-2 remediation + record notes

Cumulative `git diff 088c6e9c5 82862ca74 -- scripts/check_fork_drift.sh`, the load-bearing hunks
verbatim:

    -PLANTDIR=$(mktemp -d)
    -ADV_REF=refs/plant/advanced-upstream
    -trap 'rm -rf "$PLANTDIR"; if git -C "$ROOT" show-ref --verify -q "$ADV_REF"; then git -C "$ROOT" update-ref -d "$ADV_REF"; fi' EXIT
    +PLANTDIR=$(mktemp -d); trap 'rm -rf "$PLANTDIR"' EXIT
    ...
    -git -C "$ROOT" update-ref "$ADV_REF" "$adv_commit"
    -plant "S31 upstream ref advanced past the pinned merge-base -> OK (not drift)" 0 "$OKMSG" C 0 "$PLANTDIR/m.c" "$ADV_REF" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
    -git -C "$ROOT" update-ref -d "$ADV_REF"
    +plant "S31 upstream ref advanced past the pinned merge-base -> OK (not drift)" 0 "$OKMSG" C 0 "$PLANTDIR/m.c" "$adv_commit" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
    ...
    -# Layer 1 (name-level, <1 s): the SET of files on `git diff upstream/master
    +# Layer 1 (name-level, <1 s): the SET of files on `git diff <pinned merge-base>
    ...
    -            echo "# [files] = oracle-surface files allowed to differ from upstream/master"
    +            echo "# [files] = oracle-surface files allowed to differ from the pinned merge-base (upstream/master only locates it)"

- **No ref is created:** `git show 82862ca74:scripts/check_fork_drift.sh | grep -n -E
  'ADV_REF|update-ref|refs/plant|show-ref'` → nothing. The trap is the original one line (:345).
  `gate()` (:117-321) is untouched by this commit — the diff has no hunk inside it.
- **S31 with a raw hash still reaches the path and is still non-vacuous.** The gate's three uses
  of its ref argument all accept a SHA; read-only in the clone with an existing SHA
  (`upstream/master` = b3e11ea33…):

      $ git rev-parse --verify -q b3e11ea334e95359907d4abf9194f0e7fedc6c6a ; echo rc=$?
      b3e11ea334e95359907d4abf9194f0e7fedc6c6a
      rc=0
      $ git merge-base b3e11ea334e95359907d4abf9194f0e7fedc6c6a HEAD ; echo rc=$?
      b9aeedcb4dd438763b0eef7f95ac19e93875d7de
      rc=0

  The synthetic commit's parent is still `adv_mb` (the pinned merge-base) and its tree still
  changes `frontend/model/cabs.lem`, so under the OLD diff base `git diff "$adv_commit"` would list
  cabs.lem → 86 ≠ 85 → FAIL → PLANT FAIL; under the new base → OK. Unchanged reasoning, one less
  moving part. N-6: `git rev-parse --verify -q` also accepts a syntactically valid but ABSENT
  40-hex (`0123456789abcdef…` → rc 0); with a raw SHA the fail-closed catch is `git merge-base`
  (`fatal: Not a valid commit name …` → `FAIL — git merge-base failed`). Production passes
  `upstream/master`, so no exposure; S31's SHA exists by construction.
- **My independent run of the 5th-commit script** (`--selftest`, then the gate; my worktree
  provisioned as described above; `lem` deliberately not on PATH, so the unplanted line says
  "not cross-checked" — the plants use the fake lem commands), verbatim:

      SELFTEST rc=0
      check_fork_drift: SELFTEST — plants on scratch copies of the manifest and fake prerequisites (loud plant banner; nothing in the tree is touched)
        PLANT OK   [S31 upstream ref advanced past the pinned merge-base -> OK (not drift)] rc=0 -> check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all ha
        UNPLANTED:
          check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin c2a68e79b6369e19f0
      check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins;
      PLANT OK count: 33  PLANT FAIL count: 0
      check_fork_content: OK — 85 source files content/mode-pinned
      check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 (lem not on PATH: not cross-checked))
      GATE rc=0

  Afterwards: `git status --short --branch` → `## audit/fresh-clone-fix-20260925` (clean);
  `git show-ref | grep refs/plant` → none.
- **P3-2 wording:** head :14-15 "the SET of files on `git diff <pinned merge-base> --name-only`";
  :267 the refresh template; `scripts/fork_drift_manifest.txt:401` "`# [files] = oracle-surface
  files allowed to differ from the pinned merge-base (upstream/master only locates it;
  2026-09-25);`". `grep -E 'git diff upstream/master|differ from upstream/master'` → none in either
  file. The manifest change is comment-only: its non-comment lines before and after are 208 each
  and `cmp` reports them identical, so the gate's parsed input is unchanged (confirmed by the
  green gate above with the head's manifest checked out).
- **Record edits:** the N-1 parenthetical ("20 of them in the fork's manifested `[files]` set (32
  inside the gate's SURFACES — the 20 plus the 12 listed below; …") matches my measurement; the
  new method-paragraph lines state that quoted lines are verbatim prefixes cut at a fixed width
  (N-4) and that the `OLD_GATE` run is not a negative control, naming the PART 3 twelve-file red
  as the control (N-2). Both accurate.

## R-E addendum (five-commit range)

`mdd/cerberus-lean` is still `db5e1feb5` = the range base; `db5e1feb5..82862ca74` is a linear
five-commit chain (`a4d72a3fc` is an ancestor of `82862ca74`), so the merge remains ff-only
without a rebase and the record's embedded hashes (`25ef8a26e`, `34cbdbcc6`) stay valid. The
extension adds `scripts/check_pin_sites.sh` (new), `scripts/test_unit.sh` (+16) and a comment
line in `scripts/fork_drift_manifest.txt`; none of these is a manifested SURFACE file (only
`scripts/common.sh` is), so no `--refresh` is due — confirmed by the green gate with the head's
script and manifest. Container behaviour of row 1 changes in exactly two ways: the new pin-site
leg (green on this tree, and it would have been red on mainline for the README line) and S31's
per-run loose objects (no shared ref any more).

## Five-commit VERDICT [AGENT] (range db5e1feb5..82862ca74, superseded by the six-commit verdict below)

No P1, no P2. The gate fix (34cbdbcc6) is the single claimed token in `gate()`, validated on every
path; plant S31 is non-vacuous and, after 82862ca74, creates no shared ref — re-verified by my own
run of the 5th-commit selftest (31 plants, 0 failures, S31 by raw hash) and gate (rc 0), on top of
the fresh-clone runs of the first pass. The two P3s and three notes I raised are resolved on the
branch exactly as described, with the manifest edit proven comment-only. The new row-1 leg
(a4d72a3fc) reads the real site shapes correctly, is fail-closed on missing files/fields/pins,
carries five non-vacuous plants with the actual 2026-09-25 defect as P1, fails on mainline and
passes on the fix head and in the clone, and is wired behind the fork-drift gate with sub-second
cost; my judgement is that it mechanizes an already-normative cross-site pin invariant that is
genuinely trust-load-bearing, not gate cruft. It leaves two after-merge P3s of its own: the README
parser skips a non-hex `lem-lean.git#<branch>` fragment when a valid pin also exists (probe A —
a real if narrow fail-open; one-line grep fix plus a plant), and the leg is not yet named in
LADDER.md row 1 or the CLAUDE.md gate list.

---

# Third pass — commit `2e88f21c0` (P3-3/P3-4 closure)

    $ git log --oneline db5e1feb5..2e88f21c0 | head -1
    2e88f21c0 gate(check_pin_sites): every README pin fragment must equal the full pin (review P3-3, fail-closed); plants P6–P8; leg named in LADDER row 1 and the frontend CLAUDE.md gate list (P3-4)
    $ git show 2e88f21c0 --stat
     lean_frontend/CLAUDE.md    |  2 +-
     scripts/LADDER.md          |  2 +-
     scripts/check_pin_sites.sh | 21 ++++++++++++++-------
    $ git diff --stat db5e1feb5 2e88f21c0 | tail -1
     11 files changed, 317 insertions(+), 17 deletions(-)

`82862ca74` is an ancestor of `2e88f21c0`; `mdd/cerberus-lean` is still `db5e1feb5`; the commit
touches no SURFACE file and adds no `2>/dev/null`.

## R-H — the README fragment parser, the three plants, the two doc mentions

**The new parser** (`scripts/check_pin_sites.sh:54-59` at the head), verbatim:

    readme_frags=$(grep -o 'lem-lean\.git#[^[:space:]"'"'"'`)]*' "$f" | sed 's/.*#//' | sort -u)
    [[ -n "$readme_frags" ]] || { echo "check_pin_sites: FAIL — $f has no 'lem-lean.git#<hash>' pin command" >&2; rc=1; }
    while read -r h; do
        [[ -z "$h" && -z "$readme_frags" ]] && continue
        [[ "$h" == "$pin" ]] || { echo "check_pin_sites: FAIL — $f pins lem-lean.git#$h ≠ lem-pin $pin (the README's own rule: equal to lean_frontend/lakefile.toml)" >&2; rc=1; }
    done <<<"$readme_frags"

The bracket expression, after bash's quote splicing, is `[^[:space:]"'`)]` — the fragment runs to
the first whitespace, double quote, single quote, backtick or `)`; `*` still admits the empty run.
Every fragment must then equal the full 40-hex pin (no hex filter any more).

**The empty-fragment guard.** A bare `lem-lean.git#` (nothing after it) MUST fail: an empty
fragment is not a pin (opam would take the default branch — a moving pin). It does, in both
cases, and the guard is what makes the second one work:

- Sole occurrence: `grep -o` matches `lem-lean.git#`, `sed` leaves an empty line, the command
  substitution strips it, so `readme_frags` is "" → the `-n` check sets `rc=1` ("has no … pin
  command"); the `while` then runs once with `h=""` and BOTH guard conjuncts hold → `continue`
  (no second message). Probe F, verbatim:

      93:lem-lean.git#
      check_pin_sites: FAIL — …/f/lean_frontend/README.md has no 'lem-lean.git#<hash>' pin command
      probe F rc=1

- Beside a valid pin: `sort -u` yields an empty line and the pin; the LEADING newline survives
  the substitution, so `readme_frags` is non-empty, the guard does NOT fire for `h=""`, and the
  empty fragment is compared and fails. Probe G, verbatim:

      check_pin_sites: FAIL — …/g/lean_frontend/README.md pins lem-lean.git# ≠ lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 (the README's own rule: equal to lean_frontend/lakefile.toml)
      probe G rc=1

  (The message reads "pins lem-lean.git# ≠ …" — the empty fragment is visible as nothing after
  the `#`; adequate.)

**P3-3 closed.** My first-pass probe A rerun against the head's script (scratch README with the
valid :93 line plus an appended `…lem-lean.git#mdd/lean-backend --yes`), verbatim:

    check_pin_sites: FAIL — …/a/lean_frontend/README.md pins lem-lean.git#mdd/lean-backend ≠ lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 (the README's own rule: equal to lean_frontend/lakefile.toml)
    probe A rc=1

Edge probes: a clone URL `…/lem-lean.git` WITHOUT `#` beside the valid pin → OK (ignored, as it
should be — not a pin command; probe I rc 0); the valid pin inside a markdown link `(…#<pin>)` →
OK (`)` excluded; probe J rc 0); the valid pin in double quotes → OK (probe K rc 0); the VALID
pin in prose followed by a comma → FAIL "pins lem-lean.git#c2a68e79…, ≠ …" (probe H rc 1) —
fail-closed false red on punctuation (N-11), acceptable for a check whose subject is an
executable line.

**The three plants (non-vacuity).** Each checks rc AND a message naming the planted value; a
`printf`/`sed` that missed would leave the copy identical to P0 → rc 0 → `PLANT FAIL (wanted
nonzero)`. P6 is probe A itself (rc 0 under the 5th-commit parser, so it discriminates the two
versions); P7 appends a second pin command with `$stale`; P8 rewrites the first `"rev": "<pin>"`
of `lean_frontend/lake-manifest.json` (LemLib is that manifest's only package) — closing the
N-8 gaps for a second `lem-lean.git#` occurrence and for `rev` vs `inputRev`. My run (temporary
untracked copy in my worktree's `scripts/`, removed after; `git status` clean), verbatim tail:

      PLANT OK   [P6 a non-hex pin fragment beside the valid pin (review P3-3)] rc=1 -> check_pin_sites: FAIL — /tmp/tmp.n0O7iMBrHs/frag/lean_frontend/README.md pins lem-lean.git#mdd/lean-backend ≠ lem-pin c2a68e79b6369e19f099dfa48767319c1daf19
      PLANT OK   [P7 a second pin command naming another commit] rc=1 -> check_pin_sites: FAIL — /tmp/tmp.n0O7iMBrHs/second/lean_frontend/README.md pins lem-lean.git#67ec5de70e02e280bb348a4ba826696b76116732 ≠ lem-pin c2a68e79b636
      PLANT OK   [P8 one lake-manifest rev (not inputRev) differs] rc=1 -> check_pin_sites: FAIL — lean_frontend/lake-manifest.json LemLib rev/inputRev = 67ec5de70e02e280bb348a4ba826696b76116732 ≠ lem-pin c2a68e79b6369e19f099dfa487
    check_pin_sites: SELFTEST OK (8 plants red with the declared message, unplanted copies green)
    SELFTEST rc=0

(P0–P5 all `PLANT OK` above them; 9 `PLANT OK` lines, 0 `PLANT FAIL`.) The leg on mainline with
the head's script still FAILs on the README line (rc 1, same message as R-F (3)); on the fix
head's site files OK (rc 0).

**The two doc mentions.** `lean_frontend/CLAUDE.md:146` now lists "`check_pin_sites.sh`
(2026-09-25 fresh-clone finding: the lem-lean pin is ONE value at the manifest `lem-pin`, the
Lake rev, the three lake-manifests and the README's newcomer `opam pin` command; 8 plants,
fail-closed)" before `check_fork_drift.sh`; `scripts/LADDER.md:43` row 1 now reads "fork-drift
gate (`check_fork_drift.sh` + `check_pin_sites.sh` (one lem pin at every site: manifest, Lake rev,
3 lake-manifests, README pin command; 8 plants) — oracle-surface manifest + hash-pinned
generated-OCaml deltas)". Both accurate. N-10: the leg is nested inside the "fork-drift gate
(…)" parenthetical, so the trailing "— oracle-surface manifest + …" now reads across both; a
wording nit. **P3-5:** VALIDATION.md's row still says "5 plants" (`grep`: VALIDATION.md "5
plants"; CLAUDE.md "8 plants"; LADDER.md "8 plants"; script "SELFTEST OK (8 plants"). N-9: the
script's header line 9 still says "every `lem-lean.git#<hash>`" while the code now checks every
fragment.

## VERDICT [AGENT] — six-commit range `db5e1feb5..2e88f21c069bc07ae6997fcdc5dba15fd554c237`

No P1, no P2. Everything found in the first two passes is now closed on the branch and
re-verified here: the gate fix is the single validated token in `gate()`; S31 is non-vacuous and
ref-free (my own 5th-commit selftest run: 31 plants, 0 failures); the row-1 pin-site leg reads
the real site shapes, is fail-closed on missing files/fields/pins, and after `2e88f21c0` rejects
every README fragment that is not the full pin — my probe A fails as it must, a bare
`lem-lean.git#` fails both alone and beside a valid pin, URLs without `#` and the link/quote
forms behave correctly — with eight non-vacuous plants (P1 the actual defect, P6 probe A, P8
`rev` alone) green in my run, FAIL on mainline and OK on the fix head; the leg is named in
LADDER.md row 1 and the CLAUDE.md gate list; the range is linear on the unmoved mainline, touches
no oracle-surface file, adds no `2>/dev/null`, and every pin site agrees. One after-merge P3
remains (VALIDATION.md's row says "5 plants" — should be 8) plus three wording notes. From this
reviewer's standpoint the six-commit range is clean for the operator's ff-only merge; merge
authority rests with the operator.
