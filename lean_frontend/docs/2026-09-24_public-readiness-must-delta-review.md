# Public-readiness MUST checkpoint — independent delta review

[AGENT — independent delta review, Claude Fable subagent, 2026-09-24]

**Range reviewed:** `e9f9d049f..0a6d59eed` on branch
`cleanup/public-readiness-20260924` (three commits, verbatim
`git log --oneline e9f9d049f..0a6d59eed`):

```text
0a6d59eed M2 M6 M7: document measured newcomer build and current supported scope
abe505d3d M1 M4: remove container environment coupling and pin strict Lem backend
d6618ecb9 M10: untrack evidence archives at HEAD; verify 21 hashes and retained files
```

**Defining review:** lem-lean `07b709e:doc/lean-backend/2026-09-24_public-readiness-review.md`
(ledger M1–M11, S1–S8). **Remediator's records under test:**
`lean_frontend/docs/2026-09-24_public-readiness-remediation.md` and
`lean_frontend/docs/2026-09-24_evidence-archive-untracking.md` — treated as
CLAIMS and re-measured where a cheap measurement exists.

**What I did:** read-only measurement at `0a6d59eed` in an unprimed
worktree (`git show/diff/log/ls-files/ls-tree`, `sha256` recomputation in
Python, `grep`, `wc`, `sed`); read-only `git` queries against the lem-lean
repository at `9bb6c6b` and `deps/lem-pinned`.
**What I did NOT do:** no `lake`, `dune`, `make`, `opam` or `lem`
invocation (charter rule), so every generated-tree / gate-verdict claim
below is marked "orchestrator to confirm"; no process was run with the
remediator's cleanup worktree as cwd; the orchestrator marker
`.tmp/orch-ALL-DONE` was absent at every check during this review, so
R-F compares claims only. Tallies I computed are labelled **derived**.

Grades: **P1** blocks merge; **P2** fix before merge; **P3** after merge;
**N** note.

---

## Findings, most severe first

### F1 — P1 — `[meta] lem-pin=9bb6c6b5` is compared by string equality with an environment-dependent `lem -v` abbreviation; the operator's standard re-pin route is predicted to turn row 1 red on a correct pin

- **Where (at `0a6d59eed`):** `scripts/fork_drift_manifest.txt:400`
  (`lem-pin=9bb6c6b5`); `scripts/check_fork_drift.sh:172-175`:

  ```bash
  live_lem=$("$LEM_CMD" -v | awk '{print $2}') || fail "'$LEM_CMD -v' failed"
  [[ -n "$live_lem" ]] || fail "'$LEM_CMD -v' printed no version"
  if [[ $REFRESH -eq 0 && "$live_lem" != "$pinned_lem" ]]; then
      fail "lem-pin stale: manifest records lem-pin=$pinned_lem, '$LEM_CMD -v' says $live_lem — …"
  ```

  and `--refresh` writes whatever `lem -v` printed
  (`scripts/check_fork_drift.sh:263`: `echo "lem-pin=$live_lem"`).
- **How verified:** lem's version string is baked at build time from
  `git describe --dirty --always` (lem-lean `9bb6c6b:Makefile:4`
  `LEMVERSION:=$(shell git describe --dirty --always 2>/dev/null || echo $(LEMRELEASE))`,
  `src/main.ml:333` prints `"Lem " ^ Version.v`). `git describe --always`
  uses the auto-scaled abbreviation length, which depends on the object
  count of the clone that builds lem. Measured, read-only, in the lem-lean
  repository (`deps/lem-pinned` is a worktree of it, so an in-tree build
  there bakes exactly this):

  ```text
  $ git -C …/lem-lean describe --always 9bb6c6b
  9bb6c6b
  $ git -C …/lem-lean describe --always --abbrev=8 9bb6c6b
  9bb6c6b5
  $ git -C …/lem-lean config --get core.abbrev      # (unset, rc=1)
  $ git -C …/lem-lean tag -l | wc -l
  0
  $ git -C …/lem-lean count-objects -v | grep -E "^(count|in-pack)"
  count: 1714
  in-pack: 10272
  ```

  The remediator's opam-built lem (cloned through the redirected public
  URL) printed `Lem 9bb6c6b5` (8 chars; remediation record, "One Lem
  re-pin", verbatim) and the manifest was hand-set to that string
  ("`lem-pin=9bb6c6b5` matches the executable's measured abbreviation").
  The mainline convention up to now was 7 chars (`lem-pin=38f87d5` at
  `e9f9d049f`; `deps/lem-pinned` is still at `38f87d5`, measured
  `git -C deps/lem-pinned rev-parse --short HEAD` = `38f87d5`).
- **Failure scenario:** the merge order (R-H) is lem-lean `9bb6c6b` lands
  → operator re-pins `deps/lem-pinned` to `9bb6c6b` and runs
  `make rebuild-lem` → that lem prints `Lem 9bb6c6b` (7) → the mandated
  re-gate of this head runs `check_fork_drift` → `lem-pin stale: manifest
  records lem-pin=9bb6c6b5, 'lem -v' says 9bb6c6b` → row 1
  (`test_unit.sh`) RED on a correct pin; the head cannot be gated green in
  the operator's environment and therefore cannot be merged under the
  gate rule. Secondary scenario: the first tag placed on lem-lean (an
  announcement tag is plausible) changes `git describe` to
  `<tag>-<n>-g<hash>` and reddens every future gate regardless of length.
  I could not run `lem -v` (charter), so the 7-char prediction is by
  measurement of `git describe` alone; the orchestrator's brief reports
  an in-tree `make` printing `Lem 9bb6c6b`, which agrees.
- **One-line fix (recommended, A):** pin the full hash
  (`lem-pin=9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4`, single `[meta]`
  line edit + dated NOTE, no `--refresh`) and make the gate compare by
  prefix: normalise `live_lem` with `sed -E 's/-dirty$//; s/^.*-g//'`,
  require `[[ $live =~ ^[0-9a-f]{7,40}$ ]]` (else FAIL — vacuity stays
  loud), then accept iff `[[ "$pinned_lem" == "$live"* ]]`. The S9 plant
  (`Lem deadbee`, `:337`) still refuses; the `lem-ok` fake (`:336`) prints
  the pinned string and still passes; add two admit plants (7-char and
  `tag-1-g9bb6c6b5` forms) and one refuse plant (non-hex). Because
  `scripts/check_fork_drift.sh` is NOT itself a manifest `[files]` row
  (verified: the only manifest mention is the comment at line 264), the
  script edit needs no manifest row. Re-run row 1 only. **Stopgap (B, not
  recommended):** after the operator's re-pin, set `lem-pin=` to whatever
  their `lem -v` prints — this keeps the gate untouched but perpetuates
  the fragility and would fail the remediator's/orchestrator's 8-char
  lem.

### F2 — P2 — the untracking record carries no provenance label and does not quote the operator's [USER 2026-09-06] retention ruling that authorises the drop

- **Where:** `lean_frontend/docs/2026-09-24_evidence-archive-untracking.md`
  (whole file, 43 lines).
- **How verified:** `grep -n "USER" …/2026-09-24_evidence-archive-untracking.md`
  → no output; the file has no `[AGENT]`/`[USER]` tag at all. The
  ruling exists verbatim at `lean_frontend/docs/2026-09-05_master-plan.md:105-107`:

  > **[USER 2026-09-06]** — the validation-foundations landing rulings (evidence
  > archives, concurrency ordering, retained rulings):
  >
  > > "Agree on all points, and particularly on cleaning up the evidence archives. These should not be git committed, and will not be pushed. I don't actually hold strong value in such data which could be recreated, so I am fine dropping large files like this. The important thing is that runs can be reconstructed. …"

  and `.gitignore:79-87` already quotes it and ignores
  `lean_frontend/docs/**/*.tar.gz|*.tar.zst|*.tar` — i.e. the 21 archives at
  the base were tracked against the standing rule, and after `d6618ecb9`
  the ignore rule prevents re-adding them (`.gitignore` unchanged in the
  range, verified R-A).
- **Failure scenario:** a public reader sees 21 files removed by an
  unlabelled record with no operator authorisation cited; the project's
  provenance doctrine (container CLAUDE.md, "Record integrity") requires
  decisions to carry `[AGENT]`/`[USER]`. The review's M10 asked for
  removal "under an agreed retention policy" — the policy is this ruling
  and the record should say so.
- **One-line fix:** add a header line
  `[AGENT] under [USER 2026-09-06] "… These should not be git committed, and will not be pushed. … The important thing is that runs can be reconstructed."`
  (quote from `2026-09-05_master-plan.md:107`). Docs-only; no re-gate.

### F3 — P3 — the 23 `LemUnsupported.Cmm.*` markers have no in-file explanation

- **Where:** `frontend/concurrency/cmm_csem.lem:663,667,682,687,1302,1498,1600,1749,1868,2024,2113,2213,2380,2496,2546,2552,2598,2747,2752,3036,3280,3284,3418` (the 23 `declare lean target_rep function … = \`LemUnsupported.Cmm.<name>\`` lines).
- **How verified:** `grep -n "FORK\|LemUnsupported\|sorry\|lean" frontend/concurrency/cmm_csem.lem | grep -v "declare lean target_rep function"`
  returns only `{ocaml; lean}` / `~{ocaml;lean}` target annotations — no
  comment names the marker namespace, the reason (every marked function
  is `let {hol; isabelle; tex} …`, i.e. never a Lean definition), or the
  contract (lem-lean `9bb6c6b:doc/lean-backend/DESIGN.md:397-411`: a
  reference to a `LemUnsupported.` name from a non-library module is
  refused at generation time; `LemLib.lean:1594-1611` defines no `Cmm`
  entries, so a rendered reference would also fail to elaborate). The
  fork-drift manifest header (lines 3-7) and `SUPPORTED.md:25` carry the
  explanation instead.
- **Failure scenario:** a maintainer or upstream reader of `cmm_csem.lem`
  cannot tell from the file that these are deliberate refusal markers
  rather than dangling names (mirror-OCaml doctrine: divergence documented
  in-code as deliberate).
- **One-line fix:** one FORK comment above line 663 stating the above;
  `cmm_csem.lem` is a manifest `[source-content]` row, so this is a second
  single-row hash edit + NOTE (no `--refresh`), then row 1.

### F4 — P3 — residual container coupling outside the newcomer recipe (classified below); `scripts/ci_lean.sh` is the one hard requirement a public reader can reach from the front pages

- **Where / how verified:** `grep -rn "scripts/ce\|scripts/env.sh\|cerberus-lean-proj\|/home/dev" scripts/ tools/ Makefile lean_frontend/*.md README.md`
  plus `grep -rn GIT_CONFIG_GLOBAL scripts/ Makefile lean_frontend/*.md README.md`
  at `0a6d59eed`. Classification (all verbatim hits):

  | Hit | Class | Note |
  |---|---|---|
  | `scripts/ci_lean.sh:12-14` `if [[ -z "${GIT_CONFIG_GLOBAL:-}" ]]; then echo "Lean CI prerequisite missing: project-scoped Git configuration (GIT_CONFIG_GLOBAL)"` | **hard requirement**, public-reachable: `scripts/LADDER.md:11` "The CI entry is `bash scripts/ci_lean.sh`", LADDER is linked from `lean_frontend/README.md:122` | contradicts M1's "Offline Git redirects are optional, never a prerequisite" (`common.sh:53`, message `:55`); not in the review's M1 cite list; S3/S10 territory |
  | `scripts/measure_csmith_cpu.py:167-168` `if not os.environ.get("GIT_CONFIG_GLOBAL"): raise ValueError("source the container scripts/env.sh first")` (+ docstring `:4`) | hard requirement in a Tier-C instrument | not on any public page |
  | `scripts/check_fork_drift.sh:111` absolute fallback `/home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/ocaml_frontend/generated`; `:140` help `git remote add upstream /home/dev/projects/cerberus-lean-proj/deps/mirrors/cerberus.git`; `:248` `(source scripts/env.sh)` | fallback path + diagnostic help | the gate is fail-closed without an `upstream` ref and pristine tree, so row 1 is not runnable from a fresh clone without setup the public pages do not describe; the remediation record schedules this as S10 |
  | `tools/check_lem_sync.sh:147,163`, `tools/check_handwritten_sync.sh:80`, `tools/check_driver_fresh.sh:158` `source scripts/env.sh   # or scripts/ce` | diagnostic help text printed on failure | stale for public users; S10 |
  | `scripts/test_kill_plant.sh:28`, `test_fuel_plant.sh:26`, `test_hang_plant.sh:22` `(needs env: scripts/ce …)`; `scripts/ensure_independent_oracle.py:18` | usage comments | S10 |
  | `scripts/LADDER.md:68` `scripts/ce python3 scripts/ensure_independent_oracle.py` … "the container's `new-worktree.sh`" | dated/normative tier doc | S8 |
  | `Makefile:327-341` `rebuild-lem` comment + target: "opam-pinned in the LOCAL switch to the container worktree deps/lem-pinned" | maintainer target, comment container-coupled (grep-invisible: says `deps/lem-pinned`, `container CLAUDE.md`) | `lean_frontend/CLAUDE.md` dropped the `make rebuild-lem` instructions in this range while the target remains |
  | `lean_frontend/CLAUDE.md:327` "No parent `scripts/env.sh`, private Git redirects or container `deps/` worktree is a prerequisite." | negative statement (new text) | fine |

  `README.md`, `lean_frontend/README.md`, `SUPPORTED.md`, `DESIGN.md`,
  `VALIDATION.md`: zero hits.
- **Failure scenario:** newcomer follows README → LADDER → `bash
  scripts/ci_lean.sh` and is stopped by a container-only prerequisite
  with no public remediation text.
- **One-line fix:** drop the `GIT_CONFIG_GLOBAL` block from `ci_lean.sh`
  (its `lem`/`dune`/`lake` tool checks already fail closed), and fold the
  rest into S10 as the record plans.

### F5 — P3 — `SUPPORTED.md` does not name the differential corpora / modes inline and has no issue-reporting route

- **Where:** `lean_frontend/SUPPORTED.md:19,25,32-38`.
- **How verified:** read in full. It names the minimal baseline (113 =
  90/18/5, correct) and the pristine register (7 rows, correct) and
  says "the six named fast differential lanes in its record"; it does not
  list `minimal/coverage/debug/float/bytes/libc-exec`, does not say
  `--nolibc` vs libc lanes, and the issue route lives only in
  `lean_frontend/README.md:115-118`.
- **One-line fix:** one sentence naming the six lanes and the two libc
  modes, one link line to the fork issue tracker.

### F6 — N — retirement date of `refined-cerberus`

`SUPPORTED.md:43` "(operator scope, 2026-09-24)". The dated ruling is
`lean_frontend/docs/2026-09-16_charter-allocator-soundness-address-bound.md:28`
`[USER 2026-09-16]: "cerberus-sl is our main upstream customer at the moment. I retired refined-cerberus (it got too messy)."`
Cite that date.

### F7 — N — `lem-pin` convention changed silently from 7 to 8 characters

`38f87d5` → `9bb6c6b5`. The manifest header NOTE (line 1) records the
re-pin as `38f87d5 -> 9bb6c6b583…` but not that the `[meta]` format
changed; F1's fix (full hash + prefix compare) subsumes this.

### F8 — N — the "86 OCaml / 219 Lean files byte-identical" claim is a derived comparison — orchestrator to confirm

Basis in the record (verbatim): "The following derived comparison reads
the earlier review scratch clone at the exact base, compares file names
and SHA256 bytes" → `{"tree": "ocaml_frontend/generated", "old_files": 86, "new_files": 86, "missing": [], "added": [], "changed": []}` and the
same shape for `lean_frontend/generated` (219). Neither tree is tracked
(`git ls-tree -r e9f9d049f -- lean_frontend/generated ocaml_frontend/generated`
→ 0 files each), so I cannot check it. The primary checkout at
`e9f9d049f` holds trees generated under `38f87d5`; regenerating under
`9bb6c6b` and diffing is the confirmation. Consistency evidence in
favour: the base's `check_sorry_token` reports 0 `sorry` tokens over 219
generated files while the base `.lem` had 23 `` `sorry` `` reps, so those
reps were never rendered at the base either (R-C).

### F9 — N — opam flags in the README recipe not re-verified by me

`opam switch create . ocaml-base-compiler.5.4.0 --no-switch --no-install`
and `opam pin add --switch=. lem git+https://…#9bb6c6b5… --yes`: the
remediator cites "opam 2.1.5 local help, 2026-09-24". `opam` invocation is
barred by my charter; unverified by me. Everything else in the recipe is
checked in R-E(i).

### F10 — N — R-F closed by the addendum (second commit)

`test -f <cleanup>/.tmp/orch-ALL-DONE` → absent at every check while the
findings above were formed; the marker appeared before the first commit
and the comparison is in "R-F addendum" at the end of this record. Result:
every claimed row-1 and six-lane verdict line agrees verbatim; the
orchestrator's run used the same 8-character lem (F1 not exercised) and
contains no generated-tree-vs-base comparison (F8 still open).

---

## R-A — M10 untracking (`d6618ecb9`)

`git show --name-status --format= d6618ecb9`: 21 `D` lines, all
`lean_frontend/docs/…/*.tar.gz`, plus
`A lean_frontend/docs/2026-09-24_evidence-archive-untracking.md`;
`22 files changed, 43 insertions(+)`. No `.tar.zst` existed at the base
(`git ls-tree -r --name-only e9f9d049f | grep -E '\.tar\.(gz|zst)$|\.tgz$'`
→ 21, all `.tar.gz`). At `0a6d59eed` no archive is tracked anywhere.

Hash recomputation — for each inventory row, `git show e9f9d049f:<path>`
piped to SHA256 and byte count (Python, derived):

```text
doc rows: 21
deleted in commit: 21
doc set == deleted set: True
hash+size matches: 21 of 21 ; total bytes (derived): 21888265
```

(all 21 rows `OK`, sizes equal; the record's "21 archives; 21,888,265
bytes" agrees.)

Retained per directory (`git ls-files`, derived counts base → head):
`2026-09-19_concurrency-design-assessment-evidence` 47 → 46 (README.md,
SHA256SUMS, probes, scripts kept); `2026-09-20_enum-premerge-audit-evidence`
100 → 96 (README.md, SHA256SUMS, logs, JSON kept);
`2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence` 115 → 107
(README.md, SHA256SUMS, `verify_evidence.py`, `retain_evidence.py` kept);
`2026-09-22_match-pattern-arity-rereview-evidence` 13 → 9 and
`2026-09-22_run-digest-audit-evidence` 13 → 9 (README.md, SHA256SUMS,
`verify_evidence.py`, reports kept). Every difference equals that
directory's archive count. `git diff --name-status e9f9d049f 0a6d59eed | grep '^D' | grep -v '\.tar\.gz$'`
→ empty (no non-archive deletion in the range).

`git diff --stat e9f9d049f 0a6d59eed -- .gitignore lean_frontend/.gitignore`
→ empty. `.gitignore:85-87` already ignores
`lean_frontend/docs/**/*.tar.gz`, `*.tar.zst`, `*.tar`.

Record statements: "history is unchanged" (line 5, verbatim: "Their
working files and previous commits remain available; history is
unchanged.") and "The operator reports that they were already pushed.
Publication cannot be undone by untracking them, and this cleanup makes
no such claim." — both present. The `[USER 2026-09-06]` ruling is NOT
quoted and the record has no provenance tag → **F2**.

## R-B — M1 scripts (`abe505d3d`)

`scripts/common.sh` hunk (verbatim, the only hunk):

```diff
-if [[ -z "${GIT_CONFIG_GLOBAL:-}" ]] || ! command -v lem >/dev/null 2>&1; then
-    echo "env not loaded: run via scripts/ce or source scripts/env.sh" >&2
+# Public builds need the fork Lem executable in the active opam environment.
+# Offline Git redirects are optional, never a prerequisite for a normal clone.
+if ! command -v lem >/dev/null 2>&1; then
+    echo "lem not found: follow lean_frontend/README.md and run this command with opam exec --switch=. --" >&2
     exit 2
```

`scripts/capped`: exactly one hunk `@@ -16,28 +16,9 @@` (diffstat
`25 +---` = 3 insertions / 22 deletions), deleting the whole
"env self-load" block (the `CERB_PROJ`/`GIT_CONFIG_GLOBAL` test, the
ancestor walk for `scripts/env.sh`, the `source`, and the one-line
"no scripts/env.sh found" note) and adding a three-line comment. No other
line of `capped` changes. The loud fallbacks are still present at
`0a6d59eed`: `:66 "capped: CERB_MEM_MAX=none — running UNCAPPED (explicit opt-out)"`,
`:144 "capped: WARNING — systemd-run NOT FOUND; running UNCAPPED"`, and
the cgroup-direct-then-`systemd-run --user --scope` order at `:100-148`
matches the README's new description.

Residual coupling grep: classified in **F4**. Public front pages
(`README.md`, `lean_frontend/{README,SUPPORTED,DESIGN,VALIDATION}.md`)
have zero hits.

## R-C — M4 `cmm_csem.lem`

Is `cmm_csem` in the Lean generation set? **Yes.** `Makefile:165`
`LEM_CONC = cmm_csem.lem cmm_op.lem linux.lem`; `:189-190`
`LEM_SRC_NOT_RENAMED = … $(addprefix frontend/concurrency/, $(LEM_CONC))`;
`:201` `LEM_SRC_LEAN = $(filter-out frontend/model/core_unstruct.lem,$(LEM_SRC))`
(only `core_unstruct` is filtered); `:352-354` passes `$(LEM_SRC_LEAN)` to
`lem … -lean`. `lean_frontend/lakefile.toml:90` lists
`"Cmm_csem", "Cmm_csem_auxiliary"` among `CerberusLean` roots and
`check_lakefile_roots.sh` enforces roots = generated set both ways, so the
generated `Cmm_csem.lean` IS compiled. `lean_frontend/generated/` is not
tracked (0 files at base and head), so I cannot show the module.

Do the names resolve? They are not meant to: every one of the 23 marked
functions is defined only for `{hol; isabelle; tex}` (diff context,
e.g. `:664 let {hol; isabelle; tex} observable_filter X = …`), so the Lean
target has no definition and the `target_rep` name is rendered only at
Lean-target use sites, of which there are none (the callers —
`single_thread_behaviour` etc. — are themselves `{hol; isabelle; tex}`).
That is why the base had 23 `` `sorry` `` reps and 0 `sorry` tokens in 219
generated files, and why the new names can leave the tree byte-identical
(F8, orchestrator to confirm). The contract for the namespace is lem-lean
`9bb6c6b:doc/lean-backend/DESIGN.md:397-411` ("**Unsupported constructs
are refused at generation time, by a library-side marker.** … the backend
… refuses any reference to it from a non-library module with an error
naming the constant or type"); `LemLib.lean:1594-1611` defines no `Cmm`
member, so a rendered reference would also be an unknown identifier. Two
backstops, both loud. Verdict: **not P1**; in-file documentation absent →
**F3**. The 24th `declare lean target_rep function` in the file
(`:655 statically_satisfied = \`CerbConcurrency.statically_satisfied\``)
maps to the hand-written stub `lean_frontend/CerbConcurrency.lean` (exists).

Diff shape: `git show abe505d3d -- frontend/concurrency/cmm_csem.lem` →
23 hunks, each exactly one `-declare … = \`sorry\`` / `+declare … =
\`LemUnsupported.Cmm.<same name>\`` pair (46 lines, matches the range
diffstat `46 +++----`). `git grep -n '\`sorry\`' 0a6d59eed -- '*.lem'` →
only the historical comment `frontend/concurrency/cmm_op.lem:18`.

Manifest: `diff <(git show e9f9d049f:scripts/fork_drift_manifest.txt | sort) <(git show 0a6d59eed:scripts/fork_drift_manifest.txt | sort)`
(derived, sorted-set) shows exactly: the `cmm_csem.lem` row
`01e3dac3… → e2ac087f…`, the `common.sh` row `008b5ade… → 0f02d01c…`,
`lem-pin=38f87d5 → lem-pin=9bb6c6b5`, and seven added `#` header lines
(the dated NOTE, `[AGENT; single reviewed source-content rows]`, the two
old→new hashes). Nothing else moved (594 → 601 lines). No `--refresh`
(header retained; the NOTE says so).

## R-D — the re-pin

All five sites at `0a6d59eed` (verbatim `grep -n`):

```text
lean_frontend/lakefile.toml:67:rev = "9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4"
lean_frontend/lake-manifest.json:8:   "rev": "9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4",
lean_frontend/lake-manifest.json:11:   "inputRev": "9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4",
lean_frontend/speclab/lake-manifest.json:15:   "rev": "9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4",
lean_frontend/speclab/lake-manifest.json:18:   "inputRev": "9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4",
tests/mem-scale-probes/micro/lake-manifest.json:15:   "rev": "9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4",
tests/mem-scale-probes/micro/lake-manifest.json:18:   "inputRev": "9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4",
scripts/fork_drift_manifest.txt:400:lem-pin=9bb6c6b5
```

`git ls-files | grep lake-manifest.json` → exactly the three above (the
record's "three, not four" is correct). No `38f87d5` remains outside
dated comments/records (`git grep -n 38f87d5 0a6d59eed -- . ':!lean_frontend/docs/2026-*'`
→ only the lakefile history comment `:51` and manifest NOTE lines).
Byte-identity claim: **F8**. Fragility: **F1**; convention change: **F7**.

## R-E — docs (`0a6d59eed`)

(i) **Newcomer recipe** (`lean_frontend/README.md:82-101`), checked step
by step: clone `--branch mdd/cerberus-lean` ✓ (M9 fetchability marked
UNVERIFIED-OFFLINE in the README itself); local switch with
`--no-switch --no-install` (F9: not re-verified by me); `opam pin add
… lem git+https://github.com/OathTech/lem-lean.git#9bb6c6b5…` BEFORE
`opam install --deps-only ./cerberus-lib.opam ./cerberus.opam` ✓ (order
prevents upstream lem; `cerberus-lib.opam:30 "lem" {>= "2020-06-03"}` is
satisfied by the fork's `lem.2026-05-01`); `make prelude-src`, `dune build
backend/driver/main.exe cerberus-lib.install`, `dune install --prefix
"$PWD/_build/local-install" cerberus-lib` ✓ (`scripts/common.sh:211`
installs to the same local prefix, so the lanes agree with the recipe),
`dune build cerberus.install` ✓ (libc.co); `opam exec … make
lean-prelude-src` ✓; `CERB_MEM_MAX=32G opam exec --switch=. --
./scripts/capped make lean-native-obj` ✓ (needs `lake env` on PATH — elan
is a stated prerequisite; `lean_frontend/lean-toolchain` =
`leanprover/lean4:v4.32.2` ✓ matches the README); `lake build
CerberusLean cerberus-lean` ✓ (`lakefile.toml:71` lib `CerberusLean`,
`:204` exe `cerberus-lean`); final `LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=32G
opam exec --switch=. -- ./scripts/test_exec.sh tests/minimal/001-return-literal.c`
✓ (file exists; `common.sh` requires only `lem` on PATH and GNU
`/usr/bin/time`, `:382,:443-445`, which the README lists). Order is
runnable. Prerequisite text: "package files constrain Dune to `>= 3.21.0 & < 3.24.0`"
— `cerberus-lib.opam:23` exactly; `cerberus.opam:23` says `>= "3.15.0"`
but depends on `cerberus-lib`, so the effective constraint is as stated.
The measured script in the record differs from the public recipe only by
`--force`, `env -u GIT_CONFIG_GLOBAL`, and the local `build-env.sh`
(disclosed in the record).

(ii) **Counts.** `scripts/exec_baseline.txt` (derived): 115 lines, 2
comment lines, statuses `90 MATCH / 18 UB_MATCH / 5 CERB_SKIP`, total
113 ✓ (README `:156-157`, SUPPORTED `:32-34`, VALIDATION `:622`).
`scripts/upstream_oracle_differences.json`: `schema 2`, `cases` = 7 keys,
all `shared-model-fix`: `multi_tu_tray/{node,arr-2-2-return,arr-incomplete-ptr-return}`,
`minimal/{112,113}-allocator-exhausted-single-request[-overlap].c`,
`immaculate/nolibc/tray44-allocator-exhausted-single-request[-overlap]` ✓
(VALIDATION `:148-154` describes exactly these; SUPPORTED `:34-36` "seven
case rows … not seven distinct defects" ✓). Root `README.md:7`: "on the
documented differential lanes" — "every corpus in the tree" is gone ✓.

(iii) **Arity / registers / opaques / profile.** `lean_frontend/Main.lean:1045`
`initial_driver_state supply addressSpaceTop (runDigest tunits) runFile fsState`
= 5 arguments = `sup top digest file fs`; DESIGN `:114,:166-167` and
VALIDATION `:905` now show that ✓ (`frontend/model/driver.lem:1539,1544`
agree). `scripts/fuel_forms_pending.txt`: 56 lines, **0** non-comment rows
✓ ("The pending fuel register is empty", DESIGN `:121`). `scripts/fuel_hypotheses.txt`:
12 rows ✓ ("12 under hypotheses"). Boundary-opaque population:
`scripts/check_theorem_axioms.sh` `OPAQUE_WANT` has **10** quoted entries
(7 `CerberusFresh`, `CerbUtils.lean:bounded_integer`,
`CerbFuel.lean:fuelExhaustedLoc`, `CerbFail.lean:modelFailStopLoc`) ✓
(VALIDATION `:734` "10 registered rows", `:1069` "10 rows at e9f9d049f";
the allowlist's own comment `:38` "12 -> 10" agrees; note the population
is pinned in the gate script, the allowlist pins PIN rows — 19 — which
VALIDATION describes separately). September 6 profile: `SUPPORTED.md:7`
"This is the current profile; the dated September 6 profile is history";
`README.md:25` and `VALIDATION.md:24` now link `SUPPORTED.md`;
`docs/2026-09-06_supported-profile.md` untouched (empty diffstat) ✓.

(iv) **SUPPORTED.md.** Configuration: `:25` "Default sequential
concrete-memory configuration, recorded LP64/libc assumptions, explicit
fuel and address-space parameters … Concurrency/weak memory is not
implemented by this profile … Filesystem operations are bounded by
`CerbFS` refusals" ✓ (`CerbConcurrency.lean`, `CerbFS.lean` exist).
Limits: declared boundary `:21`, fuel `:22` (81 = 62 + 13 + 6, 0 pending
— matches the record's `check_fuel_forms` line and the registers), failure
classes `:24`, native seams `:21,:23` ✓; "four Lem parity XFAILs remain
(two string cases, two deliberate numeric differences)" — lem-lean
`9bb6c6b:tests/comprehensive/parity/expected_failures.txt` has 4 rows:
`p_str_bytes`, `p_str_escapes`, `f_int_of_big_num`, `f_int32_overflow` ✓.
Over-claim grep over all ADDED doc lines in the range for
`verified|by construction|axiom-free|proven|guarantee|all C|every corpus|equivalent`
(negations filtered): no hit. Missing inline lane names / issue route →
**F5**; `[USER 2026-09-24]` customer-acceptance quote (`:14`) is operator
chat I cannot source; it is consistent with the defining review's
"The operator reports that the downstream customer has accepted the
semantics" and is labelled as reported, not measured ✓. Retirement date →
**F6**.

(v) **`lean_frontend/CLAUDE.md`** (`:325-336`): replaces the
`deps/lem-pinned` + `make rebuild-lem` procedure with "install the chosen
immutable revision into an owned local switch, update the Lake
revision/manifests and fork-drift metadata, regenerate both trees … run
the required ladder gates"; consistent with the new `common.sh`/`capped`.
The `Makefile` `rebuild-lem` target and its container comment remain
(F4 row); the container CLAUDE.md still prescribes that route for the
operator — no conflict, but the two documents now describe different
re-pin procedures for different audiences without saying so (N, folded
into F4).

(vi) **Dated records.** `git diff --name-status e9f9d049f 0a6d59eed -- lean_frontend/docs/ | grep -v '\.tar\.gz$'`
→ only `A …/2026-09-24_evidence-archive-untracking.md` and
`A …/2026-09-24_public-readiness-remediation.md` ✓.

## R-F — gates claimed (remediator's claims, verbatim from the record)

Row 1 (owned-TMPDIR rerun): "**exit 0**, all 15 executables and all
following gates passed" with

```text
Total: 15 passed, 0 failed
check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 9bb6c6b5 = lem -v)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
```

Six lanes (each "exit 0", `SKIP_BUILD=1`, `env -u GIT_CONFIG_GLOBAL`):

```text
minimal:   SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s) / BASELINE OK
coverage:  SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
debug:     SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
float:     SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
bytes:     SUMMARY: exec_match=9 neg_pinned=5 fail=0 / ALL AT COMMITTED EXPECTEDS
libc-exec: SUMMARY: match=12 diff=0 / ALL MATCH RECORDED BASELINE
```

(The record gives each lane's full tail and a raw-log SHA256; the
"/"-joined form above is my trimming of the same lines.) Note the row-1
line `lem-pin 9bb6c6b5 = lem -v` documents that the remediator's lem
printed 8 characters — the environment F1 depends on.
Orchestrator comparison: see the addendum below (second commit).

## R-G — policy

`git diff --stat e9f9d049f 0a6d59eed -- 'scripts/*baseline*' 'scripts/*register*' 'tests/immaculate/*baseline*' 'scripts/*allowlist*' 'scripts/*pending*' 'scripts/*.json' 'scripts/*.txt'`
→ `scripts/fork_drift_manifest.txt | 13 ++++++++++---` only ✓. Files
changed in the range with a `.lean/.ml/.c/.h` suffix: none; `.lem`: only
`cmm_csem.lem` ✓ (no new theorem, exe or gate; `lakefile.toml` diff is the
`rev` line + a 3-line comment). `git diff … -- scripts/ Makefile | grep '^+.*2>/dev/null'`
→ none added (the pre-existing `2>/dev/null` sites in `capped:100-127`
are cgroup bookkeeping, not build steps, and are untouched) ✓. Dated
records untouched ✓ (R-E vi).

## R-H — merge readiness

`git merge-base --is-ancestor e9f9d049f 0a6d59eed` → exit 0 (yes; the
branch is a fast-forward of the mainline head). Required order, per the
two-repo pin dance: (1) lem-lean `cleanup/public-readiness-20260924` @
`9bb6c6b` lands ff-only on `mdd/lean-backend` after its own delta review
and per-merge sign-off; (2) the operator re-pins
`deps/lem-pinned` to `9bb6c6b` (`git -C deps/lem-pinned reset --hard
9bb6c6b`; it is at `38f87d5` now) and rebuilds lem (`make rebuild-lem` /
`opam upgrade --switch=. --no-depexts lem`), then regenerates both trees;
(3) this branch is re-gated in that environment (row 1 + the six lanes at
minimum) — **F1 predicts row 1 RED at this step until fixed** — and only
then merged ff-only on explicit per-merge sign-off. Publication of the
lem revision must precede any announcement that quotes the recipe (the
record says so; M9 remains UNVERIFIED-OFFLINE).

---

## VERDICT

[AGENT] The range does what its three commit messages say and nothing
else: 21 archives (all 21 hashes and sizes re-derived and equal) leave
the index with inventories and recipes intact and `.gitignore` already
enforcing the rule; the container coupling is removed from `common.sh`
and `capped` with no other behavioural change; the 23 `sorry` reps become
reserved-namespace refusal markers on functions that never reach the Lean
target; all five pin sites agree on `9bb6c6b583…`; no baseline, register,
theorem, exe or gate is added or rewritten; only the two new dated records
are touched; the front pages' changed numbers (113 = 90/18/5; 7 register
rows; 5-argument `initial_driver_state`; empty pending register; 10
opaques; 12 hypotheses; 4 parity XFAILs; Lean 4.32.2; Dune bound) are all
true at `0a6d59eed`, and no added sentence over-claims. One defect blocks
in the operator's standard flow: the manifest's `lem-pin=9bb6c6b5` is a
string compared for equality against an abbreviation that this repository
measurably produces as `9bb6c6b` (F1) — the fix is a single-hunk gate
change plus a one-line pin edit and a row-1 rerun, after which I see
nothing else that should hold the merge; F2 (quote the ruling) should
ride along as docs-only. The generated-tree byte-identity and the six-lane
verdicts are the orchestrator's to confirm; merge authority rests with the
operator.

---

## R-F addendum — comparison with the orchestrator's gate log (second commit)

[AGENT] Read after `<cleanup worktree>/.tmp/orch-ALL-DONE` appeared;
source `<cleanup worktree>/.tmp/orch-gates.log` (5758 lines), read-only
with an absolute path, nothing else in that tree touched. Verbatim lines,
trimmed to the verdict-bearing ones:

```text
=== ORCH CERBERUS CLEANUP GATES 2026-09-24T21:23:08Z head=0a6d59eed status_lines=0 ===
lem: Lem 9bb6c6b5 at /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-cleanup-public-readiness-20260924/_opam/bin/lem
=== STEP A: prelude-src + dune --force + local install + cerberus.install 21:23:08 ===
make: Nothing to be done for 'prelude-src'.
=== PRELUDE_SRC EXIT=0 ===
=== DUNE_BUILD EXIT=0 ===
=== DUNE_INSTALL EXIT=0 ===
=== CERBERUS_INSTALL EXIT=0 ===
=== STEP B: lean-prelude-src + lean-native-obj + lake build (capped 32G) 21:23:40 ===
[LEM] generating Lean files in [lean_frontend/generated] (log in [lean_frontend/lem.log])
=== LEAN_PRELUDE_SRC EXIT=0 ===
=== LEAN_NATIVE_OBJ EXIT=0 ===
=== LAKE_BUILD EXIT=0 ===
=== STEP C: row 1 (test_unit.sh) 21:24:12 ===
Total: 15 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 10 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (321 files scanned comment-stripped — generated 219, hand-written+test 67, LemLib 35; 0 sorry tokens)
check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_fork_drift: SELFTEST OK (14 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; unplanted gate green)
check_fork_content: OK — 84 source files content/mode-pinned
check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 9bb6c6b5 = lem -v)
=== ROW1 EXIT=0 ===
=== STEP D1: lanes 21:28:31 ===
=== scripts/test_exec.sh --check-baseline ===
SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== EXIT=0 ===
=== scripts/test_multi_tu.sh ===
SUMMARY: total=2 match=2 fail=0
=== EXIT=0 ===
=== scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray ===
SUMMARY: total=7 match=7 fail=0
=== EXIT=0 ===
=== scripts/test_address_space.sh ===
=== EXIT=0 ===
=== STEP D2: lanes 21:29:19 ===
=== scripts/test_immaculate.sh ===
=== EXIT=0 ===
=== scripts/test_libc_exec.sh ===
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
=== EXIT=0 ===
=== scripts/test_bytes.sh ===
SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
=== EXIT=0 ===
=== scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float ===
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
=== EXIT=0 ===
=== scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug ===
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
=== EXIT=0 ===
=== scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage ===
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
=== EXIT=0 ===
=== ALL DONE (cerberus gates) 2026-09-24T21:32:49Z ===
```

**Agreement (claim vs. orchestrator), line by line:** row 1 `Total: 15
passed, 0 failed`, `check_exec_purity`, `check_theorem_axioms … OK`,
`check_sorry_token`, `check_fuel_forms` partition, `check_exec_totality`,
`check_fork_content`, `check_fork_drift … lem-pin 9bb6c6b5 = lem -v` —
identical text. The six MUST lanes — minimal `113/90/18/5`, coverage
`212/183/16/13`, debug `90/66/20/4`, float `93/93/0/0`, bytes `9/5/0`,
libc-exec `12/0` — identical `SUMMARY` lines and identical closing
verdicts (`BASELINE OK` ×4, `ALL AT COMMITTED EXPECTEDS`, `ALL MATCH
RECORDED BASELINE`), every step `EXIT=0`. **No disagreement.** The
orchestrator additionally ran `test_multi_tu.sh` (2/2), the
`multi_tu_tray` failure-class projection (7/7), `test_address_space.sh` and
`test_immaculate.sh`, all `EXIT=0` — beyond the record's MUST set.

**What the log does and does not settle:**

1. The orchestrator's `lem` is the remediator's owned-switch binary and
   prints `Lem 9bb6c6b5` (line 2). **F1 is therefore not exercised** by
   this run; it remains a prediction for the operator's `deps/lem-pinned`
   route, where `git describe --always 9bb6c6b` yields `9bb6c6b`.
2. `make: Nothing to be done for 'prelude-src'` — the OCaml generated tree
   was not re-derived in this run, and the log contains no
   generated-tree-vs-base comparison (grep for old_files/changed/identical
   over the log: none). **F8 stays open** (orchestrator to confirm by a
   separate diff against the `e9f9d049f`/`38f87d5` trees, e.g. the primary
   checkout's).
3. The Lean tree WAS regenerated under `9bb6c6b` (`[LEM] generating Lean
   files …`, `LEAN_PRELUDE_SRC EXIT=0`), compiled (`LAKE_BUILD EXIT=0`,
   `Cmm_csem` is a root), and row 1 passed on it with `0 sorry tokens` over
   219 generated files. A rendered `LemUnsupported.Cmm.*` reference would
   have failed either lem's generation-time refusal or Lean elaboration;
   this is direct evidence, independent of F8, that the 23 markers never
   surface — confirming R-C's "not P1".
4. `head=0a6d59eed status_lines=0`: the gated tree was the reviewed head
   with a clean status.

**VERDICT update:** unchanged in substance. The six-lane and row-1 claims
are now independently confirmed by the orchestrator's log; F1 (P1 in the
operator's standard re-pin route) and F2 (P2, docs-only) still stand
before merge; F8 still awaits a tree diff.

---

## Closure delta (second pass) — `0a6d59eed..c13a105`

[AGENT — second pass, Claude Fable subagent, 2026-09-25 (UTC); same rules:
no builds, read-only measurement from the audit worktree; the cleanup
worktree's `.tmp/orch-gates-closure.log` read by absolute path only.]

Range (verbatim `git log --oneline 0a6d59eed..c13a105`):

```text
c13a10541 MUST closure F2/F6: retain provenance and record final-pin gate results
603c9b69b MUST closure F1/F3: validate full Lem pins and explain excluded CMM reps
```

`git diff --name-status 0a6d59eed c13a105`: `cmm_csem.lem`,
`lean_frontend/README.md`, `SUPPORTED.md`, the untracking record (M),
NEW `docs/2026-09-24_public-readiness-closure.md`, the three
`lake-manifest.json`, `lakefile.toml`, `scripts/check_fork_drift.sh`,
`scripts/fork_drift_manifest.txt` — nothing else. `c13a10541` touches only
`SUPPORTED.md`, the untracking record and the new closure record, so
`603c9b69b` is the implementation head the records cite.
`git merge-base --is-ancestor e9f9d049f c13a105` → yes; `0a6d59eed` → yes.

### (1) `check_fork_drift.sh` — F1 fix, verified against the spec

Diff `0a6d59eed..c13a105` (+62/−x, four hunks in the gate and one in the
self-test). Gate logic at `c13a105`:

```bash
[[ "$pinned_lem" =~ ^[0-9a-f]{40}$ ]] || fail "manifest [meta] lem-pin must be exactly one full 40-hex commit"
…
live_prefix=${live_lem%-dirty}
if [[ "$live_prefix" =~ ^[0-9a-f]{7,40}$ ]]; then
    :
elif [[ "$live_prefix" =~ ^[^[:space:]]+-[0-9]+-g([0-9a-f]{7,40})$ ]]; then
    live_prefix=${BASH_REMATCH[1]}
else
    fail "malformed lem version: '$live_lem' (need 7–40 hex digits or a hash-bearing git describe version)"
fi
if [[ "$pinned_lem" != "$live_prefix"* ]]; then
    fail "lem-pin stale: manifest records lem-pin=$pinned_lem, '$LEM_CMD -v' says $live_lem — …"
fi
lem_note="lem-pin $pinned_lem matches lem -v $live_lem (hex prefix)"
```

Checked: manifest value must be exactly 40 hex (a duplicated `lem-pin=`
line yields a two-line value and also fails this regex — S28); `lem -v`'s
second word accepted as a 7–40 hex prefix, bare or as `<tag>-<n>-g<hash>`,
one trailing `-dirty` stripped; REFUSED when not a prefix (stale), when the
manifest is not 40-hex, and when unparseable. The prefix test is a glob
against a value already validated as hex, so no metacharacter risk.

**Behaviour changes beyond the comparison itself (all inside F1's remit,
report them so "no other behaviour changed" is not over-read):**
(i) the stale check now also applies under `--refresh` — the former
`$REFRESH -eq 0 &&` guard is gone — and `--refresh` writes
`lem-pin=$pinned_lem` (preserving the reviewed full pin) instead of
`lem-pin=$live_lem`; the header recipe step 3 now says "set [meta] lem-pin
to the reviewed full 40-hex commit, then run --refresh"; (ii) the 40-hex
validation runs in gate mode too, so any manifest still carrying an
abbreviated pin fails closed; (iii) the OK-note text changed from
`lem-pin X = lem -v` to `lem-pin X matches lem -v Y (hex prefix)` — no
consumer parses it (`git grep "= lem -v\|lem_note" c13a105 -- scripts tools
lean_frontend/*.md scripts/LADDER.md` → only the script itself). Layers
1–3 and the prerequisite handling have no hunks. `2>/dev/null` added: 0.

**Self-test plants** (16 new, S15–S30, plus an S29 detail check; 30 total):
admit — S15 seven hex, S16 eight hex, S17 `lean-backend-v0.1.0-alpha.1-12-g<9 hex>`,
S18 `<7 hex>-dirty`, S19 `v0.1-0-g<40 hex>-dirty`, S29 `--refresh` with a
7-hex lem (rc 0, "manifest REFRESHED") + detail "refresh preserved the full
manifest pin"; refuse — S20 `2026-09-24` (non-hex), S21 bare tag, S22 six
hex, S23 41 hex, S24 `v0.1-nope-g<7 hex>` (malformed describe), S25
`v0.1-1-gdeadbee` (stale), S26 8-hex manifest pin, S27 `not-a-commit`
manifest pin, S28 duplicated manifest pin, S30 `--refresh` with the stale
fake (rc≠0, "lem-pin stale"); pre-existing S9 (`Lem deadbee` stale) and S10
(missing line) retained; the `lem-ok` control (`:336`) prints the full
40-hex pin, so bare-40-hex admit is exercised by every green control plant.
[AGENT] Coverage judged complete against the spec. Unplanted shapes, none
load-bearing: a bare 8+-hex value matching in the first 7 characters and
differing later (`6b20bfd1…`) — refused by the prefix glob but not planted;
upper-case hex — refused as malformed (fail-closed); lem's `LEMRELEASE`
fallback when built without git (`lem -v` prints a date) — refused as
malformed, i.e. a tarball-built lem cannot pass this gate (fail-closed;
worth a line in the fork-drift help text, SHOULD block).

**Exercised on the operator's route (orchestrator's closure run, verbatim
from `.tmp/orch-gates-closure.log`, in progress at the time of writing):**

```text
=== ORCH CERBERUS CLOSURE GATES 2026-09-25T00:32:05Z head=c13a10541 status_lines=0 — lem on PATH = in-tree 6b20bfd (7-char describe) ===
lem: Lem 6b20bfd at /home/dev/projects/cerberus-lean-proj/worktrees/lem-lean-cleanup-public-readiness-20260924/lem
check_fork_drift: SELFTEST OK (30 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 6b20bfd02de924d078725efa96c6675115b8b17a matches lem -v 6b20bfd (hex prefix))
=== ROW1 EXIT=0 ===
```

(`git -C lem-lean describe --always 6b20bfd` → `6b20bfd`, the same 7-char
form.) **F1 CLOSED.**

### (2) The closure re-pin

All five sites at `c13a105` = `6b20bfd02de924d078725efa96c6675115b8b17a`:
`lakefile.toml:70`, `lake-manifest.json:8,11`, `speclab/lake-manifest.json:15,18`,
`tests/mem-scale-probes/micro/lake-manifest.json:15,18`,
`fork_drift_manifest.txt:409` (full 40-hex). `9bb6c6b` survives only in the
dated history NOTE (`manifest:8`) and dated records. Sorted-set diff of the
manifest `0a6d59eed..c13a105` (derived): the `lem-pin=` line; the
`cmm_csem.lem` `[source-content]` row `e2ac087f… → 53b16ced…`; ONE NEW
`[expected-cosmetic]` row `e0a1740dc4f5a18b91e7d6cc7cde9d5f4189e74ab9ed2c2217fdc8c4dac9a185 cmm_csem.ml`
(cosmetic rows 9 → 10, semantic 20 → 20, layer-2 count 29 → 30 — declared
in the NOTE); seven header NOTE lines (`# Public-readiness closure F1/F3,
2026-09-24 [AGENT; base 0a6d59eed].`, `# Final closure Lem pin: 6b20bfd0…`,
the cosmetic-row explanation, `# No existing generated-diff pin is
refreshed.`, the closure-record pointer); and three edited `[meta]` comment
lines (`:406-408`: "Closure F1 (2026-09-24; base 0a6d59eed): full 40-hex
pin, checked by validated version prefix. Set the reviewed full pin before
--refresh; refresh preserves it."). Nothing else moved; header retained →
no `--refresh`. Cumulatively vs `e9f9d049f` the only additional row is the
first pass's `common.sh` hash. The orchestrator's expectation "lem-pin +
NOTE + the two source-content rows" therefore needs one amendment: the
propagated-comment cosmetic row is also present, legitimately.
`lakefile.toml` gains a three-line dated comment naming the closure.

### (3) The `cmm_csem.lem` comment

```lem
(* FORK F3 (2026-09-24; base 0a6d59eed): the 23 LemUnsupported.Cmm.* reps below
   belong to {hol; isabelle; tex}-only definitions, which Lean never renders.
   They provide no Lean implementation or concurrency support. *)
```

Replaces exactly three blank lines at `:659-661` (net zero lines; every
later `.lem` line number is unchanged, which is why the generated Lean —
which embeds source locations — can stay byte-identical). Accurate: 23 ✓,
`{hol; isabelle; tex}`-only ✓ (verified for all 23 in the first pass),
never rendered ✓, no Lean implementation / concurrency ✓. **Omits the
refused-`sorry` rationale** (lem ≥ `9bb6c6b` refuses `sorry` reps at
generation time, M4) and the namespace contract (a Lean reference to a
`LemUnsupported.` name is refused at generation). **F3 substantially
closed; N residue** — a reworded third line ("lem refuses `sorry` reps; any
Lean reference is refused at generation") would fit without shifting lines.

### (4) Records and front pages

Untracking record: append-only "Closure addendum — provenance
(2026-09-24)", tagged `[AGENT]`, quoting `[USER 2026-09-06]` — the excerpt
(308 bytes, ending "…runs can be reconstructed.") is a byte-exact substring
of `2026-09-05_master-plan.md:107` (checked by script); "the archives had
already been pushed … already-pushed mainline and its history have not been
rewritten" present. **F2 CLOSED.** `SUPPORTED.md:44-47`: "retired on
2026-09-16. Source: [USER 2026-09-16] "cerberus-sl is our main upstream
customer at the moment. I retired refined-cerberus (it got too messy)."" —
byte-exact substring of the 2026-09-16 charter record. **F6 CLOSED.**
Other `SUPPORTED.md` changes: header now "Checked 2026-09-24 against
Cerberus `603c9b69b…` and Lem `6b20bfd0…`" + closure-record link — true
(`c13a105` is docs-only over `603c9b69b`); "the closure also checks
multi-TU, the multi-TU tray, address-space and immaculate lanes, as
recorded above" — true per the closure record, though "above" means the
linked record, not this page (wording, N). `lean_frontend/README.md`: only
the `opam pin add …#6b20bfd0…` line changed; the closure record reports the
full recipe re-run at that pin ("final-build exit 0", `Specified(42)` with
MATCH) — orchestrator's log to confirm.

**F11 — P3 (new) — five front pages still name `abe505d3d` as the
implementation checked:** `README.md:14`, `lean_frontend/README.md:3`,
`DESIGN.md:3`, `VALIDATION.md:3`, `CLAUDE.md:329`, while the README's own
recipe now pins `6b20bfd0…` (changed by `603c9b69b`) and `SUPPORTED.md`
cites `603c9b69b`. Historically true statements, but the README header now
mis-describes the head its recipe belongs to. Fix: one-line edit each to
`603c9b69b` (or "checked at abe505d3d; closure 603c9b69b"); docs-only.

### (5) Generated trees and lem-lean delta

The OCaml file that gained a comment is `ocaml_frontend/generated/cmm_csem.ml`
(closure record: "Of 86 OCaml files, only `cmm_csem.ml` differs: the
three-line FORK explanation replaces three blank lines"). Comment-only is
forced by the source delta: the `.lem` change is a `(* … *)` comment in
place of blank lines and lem's OCaml backend carries source comments into
the `.ml`; the fork-drift layer 2 pins that file's diff-against-pristine
hash (`e0a1740d…`), which the orchestrator's 7-char run just re-derived and
matched ("30 differing generated files, all hash-pinned"). Neither tree is
tracked, so byte-identity of the 219 Lean files vs `0a6d59eed` remains the
remediator's derived claim pending the orchestrator's hash re-derivation
(Lean regeneration + `LAKE_BUILD` + row 1 green in the closure log is the
consistency evidence). lem-lean `9bb6c6b..6b20bfd` = `292db8b` (src
`lean_backend.ml` +4: two further `sorry` refusals for inline backend
types, plus three test fixtures) and `6b20bfd` (docs only, verified by
`diff --stat`) — a strictly stronger refusal that cannot change output for
a consumer with zero `sorry` reps, consistent with the 219-identical claim.

### Policy re-check for the closure range

Baselines/registers: only `fork_drift_manifest.txt`; `.lean/.ml/.c/.h`
changed: none; `2>/dev/null` added in `scripts/ Makefile tools/`: 0; dated
records: only the cleanup's own two 2026-09-24 records touched (one
append-only, one new); `ci_lean.sh` unchanged (F4 stays SHOULD, as the
closure record states).

## VERDICT (second pass)

[AGENT] The closure does what it says and closes the blocking finding: F1
is fixed as specified (full 40-hex manifest pin, validated 7–40 hex prefix
with describe/`-dirty` handling, fail-closed on malformed input, 16 new
plants) and is confirmed on the operator's route by the orchestrator's run
with a 7-character in-tree lem — `check_fork_drift: OK … lem-pin 6b20bfd0…
matches lem -v 6b20bfd (hex prefix)`, `ROW1 EXIT=0`; F2 and F6 are closed
with byte-exact quotes; F3 is closed up to a wording residue. The re-pin is
consistent at all five sites; the only manifest movement beyond the pin and
NOTE is the `cmm_csem.lem` content row and the declared cosmetic row for
its propagated OCaml comment; no baseline, gate semantics outside F1, or
dated record moved. Open: F11 (P3, stale `abe505d3d` cites on five front
pages), F4/F5 (P3, SHOULD block), F8 (orchestrator's tree-hash
re-derivation, in progress). **No P1 or P2 remains open** on `c13a105`.
Merge order unchanged: lem-lean `6b20bfd` first (ff), the operator's
`deps/lem-pinned` re-pin to `6b20bfd` + rebuild, then `c13a105` re-gated in
that environment (the closure run is that environment's shape) and merged
ff-only on explicit per-merge sign-off. Merge authority rests with the
operator.

### Closure-run addendum — the orchestrator's `c13a105` gates completed

[AGENT] `<cleanup worktree>/.tmp/orch-ALL-DONE` present; source
`.tmp/orch-gates-closure.log` (5830 lines), read by absolute path only.
Verbatim, trimmed to verdict-bearing lines:

```text
=== ORCH CERBERUS CLOSURE GATES 2026-09-25T00:32:05Z head=c13a10541 status_lines=0 — lem on PATH = in-tree 6b20bfd (7-char describe) ===
=== STEP A 00:32:05 ===
Makefile:11: *** "Compilation requires [dune].".  Stop.
=== PRELUDE_SRC EXIT=2 ===
=== STEP A (retry; PATH prepended INSIDE opam exec) 00:32:40 ===
=== PRELUDE_SRC EXIT=0 ===
=== STEP A2: WIPE both generated trees, re-derive with the 7-char lem 00:33:07 ===
Lem 6b20bfd
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src b2a78090bb9617fa5067c54145df8d775669571e30f0c9629539031975dc6e16, gen b79e328e77aa6c784c2ef260b341c98c473a35bf1e1d1523b73680949ba41d9e)
=== PRELUDE_SRC EXIT=0 ===
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src b2a78090bb9617fa5067c54145df8d775669571e30f0c9629539031975dc6e16, gen f4893e95ac3462defae87f737580b172f4e4e1cf35941d5be07edd82c8df808e)
=== LEAN_PRELUDE_SRC EXIT=0 ===
--- generated OCaml vs the primary checkout (mainline e9f9d049f) tree ---
Files ocaml_frontend/generated/cmm_csem.ml and /home/dev/projects/cerberus-lean-proj/cerberus-lean/ocaml_frontend/generated/cmm_csem.ml differ
--- diff ocaml_frontend/generated/cmm_csem.ml ---
829,831c829,831
< 
< 
< 
---
> (* FORK F3 (2026-09-24; base 0a6d59eed): the 23 LemUnsupported.Cmm.* reps below
>    belong to {hol; isabelle; tex}-only definitions, which Lean never renders.
>    They provide no Lean implementation or concurrency support. *)
=== DUNE_BUILD EXIT=0 ===
=== DUNE_INSTALL EXIT=0 ===
=== CERBERUS_INSTALL EXIT=0 ===
=== LEAN_NATIVE_OBJ EXIT=0 ===
=== LAKE_BUILD EXIT=0 ===
=== STEP C: row 1 with the 7-char lem on PATH 00:34:20 ===
Total: 15 passed, 0 failed
check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 6b20bfd02de924d078725efa96c6675115b8b17a matches lem -v 6b20bfd (hex prefix))
=== ROW1 EXIT=0 ===
=== scripts/test_exec.sh --check-baseline ===
SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
=== EXIT=0 ===
=== scripts/test_multi_tu.sh ===
SUMMARY: total=2 match=2 fail=0
ALL PASSED
=== EXIT=0 ===
=== scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray ===
SUMMARY: total=7 match=7 fail=0
ALL PASSED
=== EXIT=0 ===
=== scripts/test_address_space.sh ===
test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
=== EXIT=0 ===
=== scripts/test_immaculate.sh ===
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
=== EXIT=0 ===
=== scripts/test_libc_exec.sh ===
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
=== EXIT=0 ===
=== scripts/test_bytes.sh ===
SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
=== EXIT=0 ===
=== scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float ===
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
=== EXIT=0 ===
=== scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug ===
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
=== EXIT=0 ===
=== scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage ===
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
=== EXIT=0 ===
=== ALL DONE (cerberus closure gates) 2026-09-25T00:42:40Z ===
```

**Comparison with the closure record's claims:** every row-1 line and every
lane `SUMMARY`/closing verdict quoted in
`docs/2026-09-24_public-readiness-closure.md` is reproduced verbatim by the
orchestrator's run (minimal, coverage, debug, float, bytes, libc-exec,
multi-tu, multi-tu-tray, address-space, immaculate); `ROW1 EXIT=0`; the
fork-drift line carries the 7-character `lem -v 6b20bfd` — the operator's
route. **No disagreement.** The first `STEP A` attempt died at
`Makefile:11 … Compilation requires [dune]` (PATH order inside `opam exec`),
an orchestrator-environment slip corrected by the retry, not a head defect.

**F8 status.** The orchestrator WIPED both generated trees and re-derived
them with the 7-char lem (`STEP A2`). OCaml vs the primary checkout's
mainline (`e9f9d049f`, generated under `38f87d5`): exactly one `Files …
differ` line in the whole log — `ocaml_frontend/generated/cmm_csem.ml`
lines 829–831, three blank lines replaced by the three-line FORK comment —
**comment-only, confirmed**; the corresponding manifest cosmetic row hashed
and matched at layer 2 ("30 differing generated files, all hash-pinned").
The log has no explicit Lean-tree-vs-base diff, but the Lean `lem_sync`
generated-output stamp recorded here (`gen f4893e95ac3462defae87f737580b172f4e4e1cf35941d5be07edd82c8df808e`)
is identical to the one recorded by the orchestrator's first run at
`0a6d59eed` under lem `9bb6c6b5` (`.tmp/orch-gates.log` line 30, same
`gen` value), while the `src` stamp moved (`a508392d… → b2a78090…`, the
`.lem` comment) and the OCaml `gen` stamp moved (`77527ca7… → b79e328e…`,
the one commented file) — exactly the pattern the remediator's "219 Lean
files byte-identical; only `cmm_csem.ml` differs" claim predicts (derived
by me from the two logs' stamp lines; the stamp's coverage is
`tools/check_lem_sync.sh`'s). **F8 CLOSED for OCaml by direct diff;
closed for Lean by stamp identity.**

**Final status of the ledger on `c13a105`:** F1 CLOSED (confirmed on the
7-char route), F2 CLOSED, F3 closed with an N wording residue, F6 CLOSED,
F8 CLOSED, F10 CLOSED; open: F4, F5, F11 (all P3, SHOULD block), F7/F9 (N).
**No P1 or P2 open.** Merge authority rests with the operator.
