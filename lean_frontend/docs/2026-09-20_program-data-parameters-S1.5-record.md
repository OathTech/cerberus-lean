# Program-data parameters — S1.5 record: fuel'd truly-mutual blocks compose with reader lifting; the cerberus re-pin (2026-09-20)

**Status:** Part B (cerberus-lean) of the S1.5 charter
(`2026-09-20_charter-program-data-parameters-S1.5.md`), done by the E-A worker [AGENT] on
`arc/program-data-parameters` in `worktrees/cerberus-lean-arc/program-data-parameters` at the
orchestrator's re-launch (head `0f5509872` = `e110d7db2` + the S1.5 charter; the working tree held only
the untracked E-A record draft — the Stage A lem edits had been saved to `.tmp/eada/stageA.patch` and
reverted). Part A (lem-lean) is cited from its record; the orchestrator boundary is quoted from the
re-launch message and the copied logs. Every quoted output is verbatim; tallies marked derived are
derived. Nothing pushed; no lem-lean, `deps/lem-pinned`, opam or machine-global change by this worker.

## 0. Summary

The pin moves `4307dc5 → 38f87d5` (lem-lean `mutual-fuel-readers` Part A: the `a618b9c` scope-cut guard
deleted; fuel'd truly-mutual blocks now emit with the reader binders). On this tree the bump is
INVISIBLE by construction (no fuel'd mutual block is reader-lifted at the current `.lem`) and verified:
both generated trees re-derived from WIPED trees under `Lem 38f87d5` are byte-identical to the
`Lem 4307dc5` snapshot (305 = 305 files, sibylfs 16 = 16, hash-list diffs EMPTY), both lem-sync stamps
unchanged, build green, Tier A green (§7). One commit: the four Lake pin files, the fork-drift manifest
row + NOTE, this record. Then E-A Phase 1 resumes (the Stage A patch re-applied) — the `are_compatible`
blocks generate at this pin.

## 1. Rulings honoured

- [USER 2026-09-19] delegation (implementation-focused calls); [USER 2026-09-04] *"we don't change the
  lem structure for ocaml"* — the `are_compatible` blocks need the enum map on both targets, so the
  backend composed the mechanisms (Part A); no `.lem` reshaping. [USER 2026-09-08] nothing new out of
  policy — a guard deletion, tests, docs, pins.
- Charter §0 standing constraints: `deps/lem-pinned` and `make rebuild-lem` were the ORCHESTRATOR's
  steps (§3); this worker touched only the Part B fence (the four pin files, the manifest row + NOTE,
  this record).

## 2. Part A (lem-lean `mutual-fuel-readers` @ `38f87d5fa6b29ec90edfa457faba8a309e32c118`; cited from `doc/lean-backend/2026-09-20_fuel-mutual-reader-record.md` at that commit, now `deps/lem-pinned` HEAD)

- One commit on `4307dc5`: `src/lean_backend.ml` — the guard at `:4604-4606` deleted, two comments
  reworded, nothing else (`git diff --stat`: `22 +-`); tests `tests/comprehensive/test_fuel_mutual_reader.lem`
  + `lean-test/TestFuelMutualReader{Check,Exec}.lean` + `Test_fuel_mutual_reader_lemMeasureProofs.lean`,
  lakefile roots/exe, Makefile phase `lean-fuel-mutual-reader`; `negative/neg_fuel_mutual_lifted.lem`
  DELETED (its EXPECT text no longer exists), `negative/neg_fuel_mutual_supply.lem` added;
  `invariance/inv_fuel_mutual_reader.lem`; DESIGN.md composition sentences. `lean-lib/` untouched
  (`git diff --stat 4307dc5 -- lean-lib` → empty).
- The original gap, in the Part A record's words (§2 there): `a618b9c` "Lean backend: fuel composes with
  mutual blocks (arc 3, B2)" (2026-08-18) NARROWED the earlier "fuel val in a mutual block (unsupported)"
  refusal to "… combined with reader lifting (unsupported; extend when needed)" — *"a scope cut, not a
  technical obstacle"*: B2 built fuel × mutual and B1 fuel × reader for single defs, and their
  composition was left fail-closed for want of a consumer. It holds trivially now because every piece of
  the fuel'd emission is generic in the per-member `lifted` flag (worker binder, point-free wrapper's
  `reader_arrows`, measured wrapper's and obligation's `reader_binders`/`reader_args`, the `_zero`
  lemma's reader output, the sibling-call rewrite `(sibling_lemFuel lemFuel <readers>)`), and all-or-none
  lifting of a mutual block is structural in the reader prepass. No fixpoint, LemLib or grammar change
  (S1 not triggered).
- Remaining composition gaps, probed and KEPT refused: supply lifting in a truly-mutual block
  (`neg_fuel_mutual_supply.lem`, `neg_supply_mutual.lem`); `reader_seed` in a mutual block (no probe; out
  of fence — noted there).
- Forward pointer stated there: E-A Phase 1 restates `AilTypesAux_lemMeasureProofs.lean` and
  `Ctype_aux_lemMeasureProofs.lean` (their obligations gain the three reader binders in the generic
  position; proofs = the joint induction with inert reader parameters).

## 3. Orchestrator boundary (quoted; logs copied for this record to `.tmp/s15/orch-partA-suite.log`, `.tmp/s15/orch-partA-sweep-logs-only/`)

From the re-launch message [AGENT orchestrator], verbatim where quoted: lem-lean `mutual-fuel-readers` @
`38f87d5fa6b29ec90edfa457faba8a309e32c118` ("one commit on 4307dc5; `git diff --stat 4307dc5 -- lean-lib`
empty"); the orchestrator's independent suite re-run and `-outdir` sweep: "comprehensive identical
except the new test (pinned refusal: `Error: Lean backend: 'declare {lean} fuel val' in a mutual block
combined with reader lifting (unsupported; extend when needed)`), backends 22/22, ppcmem 20/20 identical,
cpp refused on both (pre-existing)"; the pin move: "`git -C deps/lem-pinned reset --hard 38f87d5…` →
`HEAD is now at 38f87d5 …` (only the three untracked opam stamps were dirty before and after);
`scripts/ce make rebuild-lem` → `⊘ removed lem.2026-05-01 / ∗ installed lem.2026-05-01 / [LEM] installed
Lem 38f87d5`; `scripts/ce lem -v` → `Lem 38f87d5`; `opam pin list --switch=.` → `lem.2026-05-01 git
git+file:///…/deps/lem-pinned#cerberus-pin`".

Re-read by this worker from the copied suite log (`.tmp/s15/orch-partA-suite.log`, 1407 lines,
`=== ORCH S1.5 RE-RUN 2026-09-20T07:32:47Z ===`, `=== lem -v: Lem 38f87d5 ===`), verbatim with line
numbers: `:64 === Generation: 56 passed, 0 failed, 0 skipped ===`; `:1164 Build completed successfully
(173 jobs).`; `:1182-1183 === fuel x reader x mutual (compiled): readers reach every member of a fuel'd
mutual block === / OK: compiled fuel x reader x mutual composition holds`; `:1220 OK (rejected as
declared): negative/neg_fuel_mutual_supply.lem`; `:1290 OK: inv_fuel_mutual_reader.lem (7 artifacts
byte-identical across ocaml/hol/isa/coq)`; `:1407 === SUITE EXIT=0 ===`; derived counts over the log:
101 `OK (rejected as declared)`, parity `26 OK: parity`, `6 OK: both fail`, `4 XFAIL`; the tails
`OK: 11 proofs modules scanned; no sorry/admit/axiom/native_decide/bv_decide token` and `OK: 260 files
scanned; no lemDefaultFuel, no LemFuel instance, no literal fuel (F1-F5)`.

Local confirmation at Part B start: `scripts/ce lem -v` → `Lem 38f87d5`; `git -C deps/lem-pinned log
--oneline -2` → `38f87d5 Lean backend: fuel'd truly-mutual blocks compose with reader lifting
(program-data-parameters S1.5, Part A)` / `4307dc5 N-ary reader_seed: …`; `git -C deps/lem-pinned
status --short` → `?? ocaml-lib/install_lem`, `?? ocaml-lib/install_num`, `?? ocaml-lib/install_zarith`
(the three opam stamps, as stated). The A0 before-snapshot: `.tmp/s15/gen-before.sha256` (305 rows:
`lean_frontend/generated` 219 + `ocaml_frontend/generated` 86 [derived]) and
`.tmp/s15/gen-before-sibylfs.sha256` (16 rows), taken by the Part A worker under `Lem 4307dc5` from a
wiped derivation at the clean tree.

## 4. B1 — the Lake pin bump, and the pin triple after it

`lean_frontend/lakefile.toml` `rev` → `38f87d5fa6b29ec90edfa457faba8a309e32c118` with an eleven-line
comment paragraph in the existing trail (S0.5 style; charter erratum: "one row" understates it); then,
each through `scripts/ce … scripts/capped`: `lake update LemLib` in `lean_frontend/` — verbatim:

```
info: LemLib: URL has changed; deleting '/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/program-data-parameters/lean_frontend/.lake/packages/LemLib' and cloning again
info: LemLib: cloning https://github.com/OathTech/lem-lean
info: LemLib: checking out revision '38f87d5fa6b29ec90edfa457faba8a309e32c118'
info: toolchain not updated; already up-to-date
```
(0.66 s wall), then in `lean_frontend/speclab/` and `tests/mem-scale-probes/micro/` (`info: toolchain not
updated; already up-to-date` each) — the three `lake-manifest.json` moved by Lake, not by hand.
`git diff --stat` after B1 = exactly `be1cebe36`'s four files:
```
 lean_frontend/lake-manifest.json                |  4 ++--
 lean_frontend/lakefile.toml                     | 12 +++++++++++-
 lean_frontend/speclab/lake-manifest.json        |  4 ++--
 tests/mem-scale-probes/micro/lake-manifest.json |  4 ++--
 4 files changed, 17 insertions(+), 7 deletions(-)
```
Every `"rev"`/`"inputRev"` in the three manifests = `38f87d5fa6b29ec90edfa457faba8a309e32c118` (six
occurrences; no `4307dc5` left). Fetched package: `git -C lean_frontend/.lake/packages/LemLib rev-parse
HEAD` → `38f87d5fa6b29ec90edfa457faba8a309e32c118`. `lean-lib` identity: `git -C deps/lem-pinned diff
--stat 4307dc5 38f87d5fa6b29ec90edfa457faba8a309e32c118 -- lean-lib` → empty (rc 0); `diff -r
lean_frontend/.lake/packages/LemLib/lean-lib deps/lem-pinned/lean-lib` → identical.

**The pin triple after the move:** `deps/lem-pinned` HEAD `38f87d5fa6b29ec90edfa457faba8a309e32c118`
(branch `cerberus-pin`) = opam pin target (`lem.2026-05-01 git git+file:///…/deps/lem-pinned#cerberus-pin`,
`lem -v` → `Lem 38f87d5`) = Lake `LemLib` rev in the four files = lem-lean branch `mutual-fuel-readers`
head = `scripts/fork_drift_manifest.txt` `[meta] lem-pin=38f87d5` (§5). **NOT yet true:** lem-lean
mainline `mdd/lean-backend` is still `4307dc5` — the pin dance's remaining steps are the lem-lean
pre-merge audit ask + ff-only merge of `mutual-fuel-readers` (then the pin equals the merged mainline
head), and cerberus's own ff-only merge of this branch on sign-off.

## 5. B2 — the fork-drift manifest (single row + one NOTE; never `--refresh`)

`scripts/fork_drift_manifest.txt`: `[meta]` `lem-pin=4307dc5` → `lem-pin=38f87d5` and one dated NOTE at
the top of the header (`git diff --stat`: `1 file changed, 9 insertions(+), 1 deletion(-)` — the 8-line
NOTE + the one row; `git diff | grep '^[-+]lem-pin'` → `-lem-pin=4307dc5` / `+lem-pin=38f87d5`). The
gate's verdict at this pin is in §7 (row 1's `check_fork_drift: OK … lem-pin 38f87d5 = lem -v`).

## 6. B3 — byte identity of both generated trees under `Lem 38f87d5` (WIPED derivation)

**A first attempt was NOT a wiped derivation and is discarded** (recorded for honesty): the two lem-sync
stamps were copied into one directory under the same file name, `cp` refused the second, the `&&` chain
skipped the wipe, and `make prelude-src lean-prelude-src` ran on the un-wiped trees (`make rc=0
wall=18s`: the OCaml step a timestamp no-op — the S0.5 lesson). Its outputs are superseded by the run
below; nothing from it is claimed.

The wiped derivation (`.tmp/s15/wipe.log`, `.tmp/s15/regen.log`): stamps saved as
`.tmp/s15/stamps-before/{ocaml,lean}_lem_sync.sha256`; `scripts/ce make clean-prelude-src
clean-sibylfs-src` → `clean rc=0`; `rm -rf lean_frontend/generated`; existence check → `gone:
ocaml_frontend/generated` / `gone: sibylfs/generated` / `gone: lean_frontend/generated` / `ocaml stamp
removed by clean`. Then `scripts/ce make prelude-src lean-prelude-src` → `make rc=0 wall=41s`, the
recipe's own lines:

```
[LEM] generating files in [ocaml_frontend/generated] (log in [ocaml_frontend/lem.log])
[STAMP] recording lem-sync content stamp
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
[LEM] generating files in [sibylfs/generated] (log in [sibylfs/lem.log])
[LEM] generating Lean files in [lean_frontend/generated] (log in [lean_frontend/lem.log])
check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
[STAMP] recording Lean lem-sync content stamp
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
```

Hashes: `sha256sum ocaml_frontend/generated/*.ml lean_frontend/generated/*.lean >
.tmp/s15/gen-after.sha256`; `sha256sum sibylfs/generated/* > .tmp/s15/gen-after-sibylfs.sha256`.
**`before: 305 files; after: 305 files`; `sibylfs before: 16; after: 16`; `diff` (sorted by path) of
`gen-before.sha256` vs `gen-after.sha256` → EMPTY (identical); sibylfs diff → EMPTY (identical).**
Lem-sync checks WITHOUT any extra `--record` (the recipe's own recording is the only one):
```
check_lem_sync: OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
check_lem_sync: lean OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
```
and the recorded stamps `cmp` byte-identical to the pre-wipe copies (`ocaml stamp content identical`,
`lean stamp content identical`). Stop rule S2 not triggered.

## 7. B4 — build and Tier A

### 7.1 Build (`DUNE_CACHE=disabled scripts/ce bash -c 'source scripts/common.sh && build_cerberus && build_lean'`, then `scripts/ce ../../scripts/capped lake build` in `lean_frontend/speclab`; `.tmp/s15/build_b4*.log`)

`check_driver_fresh: recorded oracle stamp (bin f104ce768a106d71e03917b06afe138a1fc2f58ac6e157053db3ebf05cfd352c, src 2b8b576816681316ce0c0b690dc78a63f813ac8a7391f976bdf4684a18f47634)`;
`Build completed successfully (285 jobs).`; `check_driver_fresh: recorded lean stamp (bin 8e9f7fb1a1c99ef9a8ea05fcdddc8fa5f7cc961f1644a3680306699534595729, src 453fe3a1a85395c41e4575022610693ce832be825eeef85d114e27fe3cb69257)`;
**`build_cerberus+build_lean rc=0 wall=11s`** (Lake replayed the unchanged modules; the re-cloned LemLib's
few `:c.o` artifacts rebuilt — `✔ [232/285] Built LemLib.Machine_word:c.o (260ms)`); speclab `Build
completed successfully (148 jobs).` `rc=0 wall=0s`; `TOTAL wall=11s`. The Lean binary hash
(`8e9f7fb1…`) equals the S0.5 record §6's — the same sources compile to the same binary across the pin.

### 7.2 Tier A rows 1–12 incl. 4b/4c/6b (`scripts/ce python3 scripts/release.py --mode fast --out .tmp/s15/release-fast`)

Runner: `PASSED A1 (215.6s)`, `A2 (28.9s)`, `A3 (53.0s)`, `A4 (22.8s)`, `A4b (24.3s)`, `A4c (3.1s)`,
`A5 (22.4s)`, `A6 (2.2s)`, `A6b (3.6s)`, `A7 (10.7s)`, `A8 (9.2s)`, `A9 (17.1s)`, `A10 (17.0s)`,
`A11 (58.3s)`, `A12.1 (4.9s)`, `A12.2 (4.5s)`; `summary.txt`: `fast: incomplete; 16/16 selected commands
completed successfully.` / `Source unchanged: False. Complete tier selection: True.` / `Release
certification: incomplete: reporting/adoption/audit exits require separate evidence.` ("Source
unchanged: False" = the uncommitted pin/manifest/record edits of this Part B, as at S0.5; "incomplete"
is the runner's standing wording for the non-Tier-A obligations). Evidence dir `.tmp/s15/release-fast/`
(per-row `stdout`/`stderr`/`observations`). Tails, verbatim:

- **Row 1** (`test_unit.sh`): `Total: 12 passed, 0 failed`; `check_theorem_axioms: OK (effect-retirement C2
  bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)`; `check_sorry_token: OK (318
  files scanned comment-stripped — generated 219, hand-written+test 64, LemLib 35; 0 sorry tokens)`;
  `check_no_fuel_numerals: OK (325 files scanned comment-stripped; …)` + `SELFTEST OK (26 plants …)`;
  `check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules
  all built)`; `check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED … 12 of them under a hypothesis …)`;
  `check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec
  dependency closure + 2 unresolved-owner; …); position classes unchanged; 0 DISCARDABLE; …)`;
  `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`;
  `check_lem_sync: OK (src 037dee26…, gen 08b84774…)` / `check_lem_sync: lean OK (src 037dee26…, gen
  cd499eab…)`; **`check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale
  canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base
  b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)`** (+ its 14-plant selftest, S1–S3/S11
  quoted green); `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)`;
  `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)`.
- **Row 2** (`tests/minimal`): `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`.
- **Row 3** (`tests/coverage`): `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`.
- **Row 4** (`tests/debug`): `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`.
- **Row 4b** (`tests/float`): `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`.
- **Row 4c** (`test_bytes.sh`): `SUMMARY: exec_match=9 neg_pinned=5 fail=0` / `ALL AT COMMITTED EXPECTEDS`.
- **Row 5** (`test_libc_exec.sh`): `SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED BASELINE`.
- **Row 6** (`test_multi_tu.sh`): `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED`.
- **Row 6b** (tray): `SUMMARY: total=7 match=7 fail=0` / `ALL PASSED`.
- **Row 7** (`test_parse.sh`): `batch diagnostic producers: 8/8 passed` / `cabs bytes probe: 128 raw bytes
  0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)` / `ALL PASSED`.
- **Row 8** (`test_core.sh`): `Lean parse:     113 ok, 0 failed` / `Success rate:   100% (of cerberus
  successes)` / `ALL PASSED`.
- **Row 9** (`test_elab.sh`): `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0` (the recorded
  same/diff state).
- **Row 10** (`test_libxml2_uri.sh`): `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE
  PASS: all lane expectations pinned-green + baseline unchanged (16/16)`.
- **Row 11** (`test_cn_coverage.sh --check-baseline`): `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0
  reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0
  lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact
  match)`.
- **Row 12** (`test_address_space.sh --selftest`; `test_address_space.sh`): `EXPECT OK    18 pinned rows =
  18 observed cases, every token identical` / `test_address_space: SELFTEST OK (14 plants — …)`;
  `test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork
  observation = its pinned row in expectations.txt)`.

ZERO movement on every lane (stop rule S2 not triggered).

## 8. Charter errata

| # | Charter text | Fact |
|---|---|---|
| S1.5-E1 | Part B: "on `arc/program-data-parameters` (head `e110d7db2` …)" | at the re-launch the head was **`0f5509872`** — the S1.5 charter's own commit on the branch; Part B's commit sits on it |
| S1.5-E2 | §2 Part B "B1 … the four files"; S0.5 audit N2 precedent | the `lakefile.toml` change is the `rev` plus an eleven-line trail paragraph (not one row); the three manifests move 4 lines each |
| S1.5-E3 | (procedure) "a WIPED derivation — `make prelude-src` alone is a timestamp no-op" | confirmed the hard way (§6): a skipped wipe produced a green-looking 18 s no-op; the record keeps the discarded attempt visible |

## 9. Commit and worktree state

ONE commit on `0f5509872` — exactly six files: `lean_frontend/lakefile.toml`,
`lean_frontend/lake-manifest.json`, `lean_frontend/speclab/lake-manifest.json`,
`tests/mem-scale-probes/micro/lake-manifest.json`, `scripts/fork_drift_manifest.txt`, this record (its
hash is quoted in the Part B report and in the E-A record). `git status --short` after it: only the
untracked E-A record draft (`lean_frontend/docs/2026-09-20_program-data-parameters-EA-DA-record.md`).
Evidence under `.tmp/s15/` is ephemeral (deleted at slice end; the verbatim lines above are the record).
Next, without a boundary wait (the orchestrator's re-launch instruction): `git apply .tmp/eada/stageA.patch`
and E-A Phase 1 continues under its charter with the extended fence.

## Erratum [AGENT 2026-09-20] — the `check_fuel_forms: OK` line quoted in §7.2 was a VACUOUS verdict

The Tier A row-1 tail quoted above, `check_fuel_forms: OK (81 fuel'd
workers: 62 MEASURED … 12 of them under a hypothesis …)`, is a verbatim
quote of what the gate printed at this head — and the verdict it states
was vacuous on nine obligations (the six `CerbMem` rows of
`scripts/fuel_hypotheses.txt:60-65` and the three hand-written seam
obligations): `lean_frontend/CerbMem_lemMeasureProofs.lean` had not
compiled since seam-hygiene H1 (`fce1de9f8`, 2026-09-19), no step of
row 1 rebuilt it (a Lake root imported by nothing), and
`scripts/check_fuel_forms.sh` imported its pre-H1 `.olean` as found.
Finding F-1, found by the E-A Phase 1 worker on 2026-09-20 and repaired by
the hotfix `fix/fuel-forms-carriers` (record
`docs/2026-09-20_fuel-forms-carriers-hotfix-record.md` §0: the gate now
builds every module it imports, plant P24), which lands immediately after
this range. Every OTHER verdict quoted in §7 stands: the pin bump moved
no source, and the byte-identity witness (§6, B3) is independent of the
gate (section cite corrected at landing — audit delta re-read N8). Raised by the combined pre-merge audit
(`docs/2026-09-20_s15-and-fuel-forms-hotfix-audit-premerge.md` M1); this
paragraph is that audit's fix, committed on `fix/s15-record-erratum` from
`52af8ccf1` so that it lands WITH the range.
