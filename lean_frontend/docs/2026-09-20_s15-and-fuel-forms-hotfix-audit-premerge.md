# Pre-merge audit — program-data parameters S1.5 (lem-lean `4307dc5..38f87d5` + cerberus `e283bed77..52af8ccf1`) and hotfix `fix/fuel-forms-carriers` (cerberus `e283bed77..5a5579209`; 2026-09-20)

**Ranges, in landing order.** (1) lem-lean `4307dc5..38f87d5` — ONE commit, 12 files (`src/lean_backend.ml` 22 lines changed; `tests/comprehensive/{Makefile,test_fuel_mutual_reader.lem,lean-test/{TestFuelMutualReaderCheck,TestFuelMutualReaderExec,Test_fuel_mutual_reader_lemMeasureProofs}.lean,lean-test/lakefile.lean,negative/neg_fuel_mutual_lifted.lem (DELETED),negative/neg_fuel_mutual_supply.lem,invariance/inv_fuel_mutual_reader.lem}`; `doc/lean-backend/DESIGN.md`; the record `doc/lean-backend/2026-09-20_fuel-mutual-reader-record.md`). (2) cerberus-lean `e283bed77..52af8ccf1` — THREE commits (`e110d7db2` the E-A/D-A charter, `0f5509872` the S1.5 charter, `52af8ccf1` the pin bump + one manifest row + NOTE + the S1.5 record). Confirmed: `git diff --stat e283bed77 52af8ccf1 -- . ':!lean_frontend/docs'` = exactly `lean_frontend/lake-manifest.json | 4`, `lean_frontend/lakefile.toml | 12`, `lean_frontend/speclab/lake-manifest.json | 4`, `scripts/fork_drift_manifest.txt | 10`, `tests/mem-scale-probes/micro/lake-manifest.json | 4` — `5 files changed, 26 insertions(+), 8 deletions(-)`. (3) cerberus-lean `e283bed77..5a5579209` — TWO commits (`faec26faf` the hotfix charter; `5a5579209` the hotfix: `lean_frontend/CLAUDE.md | 6`, `lean_frontend/CerbMem.lean | 128`, `lean_frontend/CerbMem_lemMeasureProofs.lean | 85`, `lean_frontend/VALIDATION.md | 2`, `docs/2026-09-18_seam-hygiene-record.md | 18`, the record `| 736`, `scripts/check_fuel_forms.sh | 98`, `scripts/check_lakefile_roots.sh | 5`, `scripts/failure_reach_register.txt | 7` — `9 files changed, 978 insertions(+), 107 deletions(-)`). The two cerberus ranges touch DISJOINT file sets (*reproduced*: `comm -12` of the two `git diff --name-only` lists → empty) and share the base `e283bed77` = `git merge-base 52af8ccf1 5a5579209` = cerberus mainline `mdd/cerberus-lean` at the time of writing; lem-lean mainline `mdd/lean-backend` = `4307dc5` (the pin's base).
**Heads audited:** lem-lean `38f87d5` as branch `audit/mutual-fuel-readers` in `worktrees/lem-lean-audit/mutual-fuel-readers`; cerberus `52af8ccf1` as `audit/program-data-parameters-S1.5` in `worktrees/cerberus-lean-audit/program-data-parameters-S1.5`; cerberus `5a5579209` as `audit/fuel-forms-carriers` in `worktrees/cerberus-lean-audit/fuel-forms-carriers` (this document is committed here).
**Who:** an INDEPENDENT pre-merge auditor (Claude, Fable 5.1) — [AGENT auditor] throughout. I wrote none of the three ranges. Every claim marked *reproduced* is my own run in the three audit worktrees; quoted outputs are verbatim; tallies are labelled derived. The rulings the ranges implement — [USER 2026-09-19] *"I'm interested in making decisions that are consequential in some way but for the other kinds of decisions, which are really more implementation-focused, I think you can make the calls."*, [USER 2026-09-04] *"we don't change the lem structure for ocaml"*, [USER 2026-09-08] *"we should \*NOT\* be building anything new out-of-policy"*, and the hotfix's option-(d) ruling **[AGENT orchestrator 2026-09-20, under the operator's delegation, flagged to the operator]** — are not questioned here; whether the code and the records implement EXACTLY them is.
**Evidence:** this document IS the record (the brief: commit ONLY the audit document). Scratch — probes, generated Lean, the scratch Lake project, build/sweep/suite/regeneration/gate logs, the scratch old-lem worktree — lives under the three audit worktrees' git-ignored `.tmp/audit/` and is ephemeral (the scratch git worktree `lem-lean-audit/mutual-fuel-readers/.tmp/audit/lem-4307dc5` is removed at the end); every line this document relies on is quoted here.

**What I ran (2026-09-20 ≈ 18:25–19:20 UTC; box load 0.2–4.1; one heavy Lean job at a time; every `lake`/`lean` through `cerberus-lean/scripts/capped`; every cerberus `make`/gate through the container's `scripts/ce`).** Read in order: the S0.5 audit (the format reference), the lem-lean record, the S1.5 record, the S1.5 and E-A/D-A charters, the hotfix charter and record (all 736 lines), then the full diffs of all three ranges and the surrounding code at every cited site (`lean_backend.ml` at `4307dc5`/`38f87d5`/`a618b9c`, `CerbMem.lean`, `CerbMem_lemMeasureProofs.lean`, `check_fuel_forms.sh`, `check_lakefile_roots.sh`, `failure_reach_register.txt`, `impl_mem.ml`, the `.lem` cites). Built `./lem` in the lem-lean audit worktree (`Lem 38f87d5`) and the OLD lem in a scratch `git worktree` at `4307dc5` (`Lem 4307dc5`; the switch's lem is `38f87d5`, so the old one had to be built). *Reproduced:* nine adversarial lem probes (three probe programs + six negatives) generated with the new lem and compiled in a scratch Lake project against `lean-lib` @ `38f87d5` (toolchain `v4.28.0`) — `Build completed successfully (43 jobs)`; the six negatives under BOTH lems; my own old-vs-new sweep over `tests/comprehensive` (58 invocations), `tests/backends` (12), `examples/ppcmem-model`, `examples/cpp`; the full comprehensive suite (`make -C tests/comprehensive lean`, exit 0, wall 371 s); BOTH cerberus generated trees wiped and re-derived at `52af8ccf1` under the OLD lem and under the NEW lem, hashed and diffed (the third byte-identity witness); the fork-drift / lakefile-roots / lem-sync gates at `52af8ccf1`; the F-1 compile failure at the parent-equivalent tree; Probe A (the old proof shape under `Acyclic` alone); at `5a5579209`: `make lean-prelude-src`, `lake build CerberusLean cerberus-lean`, `check_fuel_forms.sh --selftest` (P24 among 25 plants), the gate, `check_failure_reach.sh`, `check_lakefile_roots.sh`, `check_fork_drift.sh`, `#print axioms` of the nine obligations + `reconstructValue_lemFuel_eq_indexed`, Tier A rows 1–12 incl. 4b/4c/6b (`release.py --mode fast`), and three tree-path plants of my own against the hardened gate (P-a/P-b/P-c below); at `52af8ccf1`: the OLD gate with the primed `.lake` and row 1; every gate tail the three records quote checked against the workers' and the orchestrator's evidence files (read-only); the `apply --check` of the hotfix diff onto the S1.5 head; ~60 file:line cites.

## 0. Verdict

- **lem-lean `4307dc5..38f87d5`: MERGEABLE.** No MAJOR, no MINOR. The backend change is exactly the three-line guard deletion plus two comment rewordings (§2.1 (a)); `a618b9c`'s own diff shows the sibling-call rewrite ALREADY re-injected reader binders when the guard was introduced (*"a lifted worker also re-injects its reader binders (arc 3, B1/B2)"*), so the record's one-sentence account — a scope cut, not a technical obstacle — is borne out by the code of that commit, not only its message. My five adversarial probe classes (i)–(v) plus a sixth (bare sibling as a HOF argument) emit and pin as claimed (§2.1 (b)); the deleted negative is refused by the old lem and accepted by the new; the four remaining refusals (supply × mutual in both shapes, `reader_seed` × mutual, the fuel and `fuel_measure` all-or-none) fire identically under both lems with readers present (§2.1 (d)); my suite run and my sweep reproduce the record's every tail and count (§2.1 (c)); `lean-lib/` is byte-identical.
- **cerberus `e283bed77..52af8ccf1`: MERGE-WITH-FIXES** (one MINOR, docs-only, no re-gate). The pin bump is byte-inert by my third witness — both trees WIPED and re-derived under `Lem 4307dc5` and under `Lem 38f87d5`: `305 = 305` files, hash-list diff EMPTY, sibylfs `16 = 16`, stamps identical, and equal to the worker's `gen-before` AND `gen-after` hash sets (§2.2); the fork-drift gate is green at the head with `lem-pin 38f87d5 = lem -v`. Every gate tail the record quotes resolves in `.tmp/s15/` (§2.3). **M1:** the record §7.2 quotes the row-1 verdict `check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …)` — a verdict the hotfix proved VACUOUS on nine obligations (F-1; the hotfix record §0 names "S1.5 Part B" among the vacuous runs and its evidence file `.tmp/s15/release-fast/A1/stdout:695/698` is that very line) — and carries no erratum, while the landing order puts this record on the mainline BEFORE the hotfix. Fix: one dated erratum paragraph in the S1.5 record (or the operator's explicit waiver on the ground that the hotfix record §0 names the run).
- **cerberus `e283bed77..5a5579209`: MERGE-WITH-FIXES** (two MINOR, record wording; no code, register, baseline or pin moves; no re-gate). F-1 reproduced verbatim at the parent-equivalent tree; the hardened gate builds every module it imports and P24 plants the F-1 state; my own tree-path plants show the stale-`.olean`-over-uncompilable-source state cannot survive the gate (Lake's failed rebuild removes the old `.olean`; a different COMPILING source is rebuilt before import) (§2.4); the two restated arms are behaviour-identical on the defined domain by case analysis, the `impl_mem.ml` cites are exact to the line, the twin equation closes (§2.5); all nine obligation statements are character-identical to the parent's through `:=`, kernel-only tactics, no option bumps, every cone = the standard trio, `fuel_hypotheses.txt` byte-unchanged (§2.6); the register's three moved/new rows derive the tally exactly and their classes follow the register's rules (§2.7); Probe A reproduced (§2.8); Tier A at the head: `15/16`, A1 red on the environment's lem-pin line ALONE, rows 2–12 at their recorded tails (§2.9). **M2:** the record §1.3's option-(b) residual — *"today the `Cerb*Proofs` modules the unit exes import … and nothing else; DERIVED from the roots list"* — is wrong: `CerbConcurrency` is a Lake root imported by NO module under `generated/`, `test/` or `speclab/`, built by nothing under option (b) (its `.olean` dates 2026-08-22) — a live instance of the F-1 class the record says has no other member. **M3:** the record §5 describes `lean_frontend/CLAUDE.md` rows in option-(a) wording (*"built by `build_lean` (every root, 2026-09-20)"*, *"The `common.sh` row: `build_lean` builds EVERY Lake root + the exe"*) that the COMMITTED file does not contain — the committed row says option (b) and the `common.sh` row is untouched; the VALIDATION.md blockquote there is a paraphrase presented as a quote.

## 1. Findings

Grades: MAJOR = a trust gap, a hidden real difference, or a ruling not implemented; MINOR = a fail-open shape, an overclaim/misquote in a normative document or record, or an unclaimed change, each with a small fix; NOTE = precision, process, or a residual the merge need not wait for. Severities are [AGENT auditor] judgments.

### M1 — MINOR (range 2) — the S1.5 record quotes a row-1 gate verdict now known to be vacuous, with no erratum, and lands first

**Where:** `lean_frontend/docs/2026-09-20_program-data-parameters-S1.5-record.md` §7.2 Row 1: *"`check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED … 12 of them under a hypothesis …)`"*; §0: *"Tier A green (§7)"*; the commit message of `52af8ccf1`: *"Tier A rows 1-12 incl. 4b/4c/6b: 16/16 passed"*.
**Reproduction** (*reproduced*, read-only): the worker's `.tmp/s15/release-fast/A1/stdout:695` and `:698` are exactly that OK line, produced in the arc worktree at `52af8ccf1`; at that head `lean_frontend/CerbMem_lemMeasureProofs.lean` does NOT compile (my §2.8 F-1 reproduction at the parent-equivalent tree: `error: generated/CerbMem_lemMeasureProofs.lean:921:8: Tactic `rewrite` failed` / `:1016:18`), so the verdict rested on a stale pre-H1 `.olean` — the hotfix record §0: *"Records in this tree whose row-1 claims rest on it: … The S1.5 Part B record is on its own branch, not in this tree"*. The seam-hygiene record received a dated §12 erratum in the hotfix; the S1.5 record — unlanded, and first in the landing order — received none.
**Why it matters:** "the repo is the record"; the merge would land a record stating a gate verdict the same landing sequence knows to be vacuous on six `fuel_hypotheses.txt` rows and three seam obligations, unmarked in the file itself.
**Fix:** a docs-only erratum paragraph in the S1.5 record (the seam-hygiene §12 wording fits: *the `check_fuel_forms: OK` of §7.2 certified nine obligations from a pre-H1 artifact; every other line of the verdict stands; repaired by hotfix `fix/fuel-forms-carriers`*), or the operator's explicit waiver. No source, generated file, pin or manifest moves; no re-gate.

### M2 — MINOR (range 3) — the option-(b) residual is not "nothing else": `CerbConcurrency` is a Lake root imported by nothing and built by no gate or exe

**Where:** hotfix record §1.3: *"What (b) leaves open: a Lake root that NO gate imports (today the `Cerb*Proofs` modules the unit exes import — they are built by `test_unit.sh`'s `lake build <exe>` — and nothing else; DERIVED from the roots list) could still go stale unnoticed by `build_lean`'s consumers."*; §6 follow-up (a).
**Reproduction** (*reproduced*, at `5a5579209`): the `CerberusLean` roots array of `lakefile.toml` (comment-stripped) has 123 entries; for each root I looked for an `import <root>` line in every `.lean` under `lean_frontend/generated`, `lean_frontend/test`, `lean_frontend/speclab` (`.lake` excluded), and excluded `ENTRY_MODULES` and the gate's carrier set (`generated/*_auxiliary.lean`, `generated/*_lemMeasureProofs.lean`, 100 modules). Result:
```
roots (comment-stripped): 123
== roots imported by NO module under generated/ test/ speclab/, not ENTRY, not a carrier ==
  ORPHAN-ROOT: CerbConcurrency
== importers of CerbConcurrency anywhere (incl. tests/, docs) ==
== is CerbConcurrency in the exe closure? (lake query) ==
-rw-rw-r-- 1 dev dev 9536 2026-08-22 18:03:26.170876191 +0000 .lake/build/lib/lean/CerbConcurrency.olean
```
(the two "importers" greps printed nothing). `CerbConcurrency.lean` is a hand-written seam ("Concurrency stubs", the declared boundary), a Lake root (`lakefile.toml`), listed in `handwritten_copy.manifest`, imported by nothing; under option (b) only `lake build CerberusLean` builds it, and nothing in the lanes runs that. Its `.olean` has not been rebuilt since 2026-08-22 (Lake's hash traces say it is up to date — the source has not changed — so today it is NOT stale; the point is that nothing would notice if it were).
**Why it matters:** the record's sentence is the justification for accepting (b); it says the residual class is empty except for modules a lane already builds. It is not empty. The trust impact today is low (no obligation is certified from `CerbConcurrency`; it states stubs), but it is exactly the F-1 shape — a root that can stop compiling with no lane noticing — and the record says the shape does not exist.
**Fix:** one sentence in §1.3 naming `CerbConcurrency` (and the derivation: roots minus importers minus entries minus carriers), and its name in the §6 follow-up (a) as the second reason for taking option (a). Docs-only.

### M3 — MINOR (range 3) — the record §5 describes `lean_frontend/CLAUDE.md` rows the commit does not contain (option-(a) wording after (a) was reverted)

**Where:** hotfix record §5, *"`lean_frontend/CLAUDE.md` — applied: … the `CerbMem_lemMeasureProofs.lean` row becomes: '… A Lake root nothing imports: built by `build_lean` (every root, 2026-09-20) and by the fuel-forms gate itself. …'. The `common.sh` row: '`build_lean` builds EVERY Lake root + the exe'"*; and *"`VALIDATION.md:729` … inserted …:"* followed by a blockquote.
**Reproduction** (*reproduced*, `git diff e283bed77 5a5579209 -- lean_frontend/CLAUDE.md lean_frontend/VALIDATION.md`): the committed `CerbMem_lemMeasureProofs.lean` row reads *"A Lake root NOTHING imports: built by the fuel-forms gate itself (H1, every carrier it imports; `build_lean` builds only the exe's closure — option (b), the hotfix record §1.3)"*; the `common.sh` row of the Scripts table is UNCHANGED (`| `scripts/common.sh` | Shared helpers (build, run, paths) |`); the CLAUDE.md diff is three hunks (the `fuel-forms-tool` bullet, "24 plants" → "25 plants … P24", the proofs row) — no `common.sh` hunk. The committed VALIDATION.md insertion reads *"**the gate BUILDS every module it imports before importing it** (hotfix `fix/fuel-forms-carriers` 2026-09-20, finding F-1 — `docs/2026-09-20_fuel-forms-carriers-hotfix-record.md`: `lake build` of the exec entries and every `*_auxiliary`/`*_lemMeasureProofs` carrier, and the selftest's scratch decoys compiled from source — fail-closed, the FAIL naming the module; until then a carrier's `.olean` was imported AS FOUND, and `CerbMem_lemMeasureProofs`' pre-seam-hygiene artifact certified nine obligations vacuously from 2026-09-19 to 2026-09-20)"* — the same substance as the record's blockquote, different words.
**Why it matters:** the record's §5 is its account of what the commit did to the shop-window docs; it describes the option-(a) state the worker reverted (§1.3, §4.2 run 1). The COMMITTED docs are right; the record is wrong about them.
**Fix:** rewrite §5's CLAUDE.md paragraph to the committed rows (option (b) wording; no `common.sh` row change) and mark the VALIDATION.md quotation as a paraphrase or replace it with the committed text. Docs-only.

### N1 — NOTE (range 3) — the register's new/moved rows cite base-tree line numbers for the load site

`scripts/failure_reach_register.txt`'s new row: *"Shadowed besides: doLoad computes sizeofCtype tagDefs ty BEFORE reconstructValue (CerbMem.lean:2398-2404)"*; the record §3.4 *"`loadM tagDefs loc ty pv` (`CerbMem.lean:2389`)"*. At the sealed head `5a5579209` (*reproduced*) `def loadM` is `:2419`, `let size := sizeofCtype tagDefs ty` `:2429`, the `reconstructValue …` call `:2434` — the arms grew the file by 30 lines above the load site. The arm cites in the same rows (`:1123`, `:1155-1165`, `:1166`) ARE head numbers. The ordering claim itself holds (`size` is bound before `mv`). A cite frame inconsistency inside a sealed row; not misleading in substance.

### N2 — NOTE (range 3) — the record §3.4 describes a concrete reach route for the recorded-member leaf whose row stays `UNKNOWN`

The moved row (`"CerbMem.reconstructValue: recorded union member not in Unio…`) keeps `reach=UNKNOWN`, *"needs a memory well-formedness invariant … model-shape, no theorem"* — permitted by the register's rules (UNKNOWN = no invariant cite, no witness). But §3.4 (iii) itself states the route: *"is FALSE under type punning (store a member of `union U1` at `a`, load `union U2` at `a`): upstream's own reaction there is `assert false` (impl_mem.ml:1085-1090)"*. A witness program under `tests/failure-probes/reach/` of that shape would make the row `REACHABLE` (both-crash, the oracle's `assert false` vs Lean's `failwithI`) — the more informative class. Not blocking (the register's rules are met; a witness is a follow-up probe, and writing one is outside this slice's fence).

### N3 — NOTE (range 3) — "no consumer-visible change" (§3.5 (d)) is imprecise: the DEFINITION changed

`reconstructValue_lemFuel`'s struct/union arms are restated; behaviour on the defined domain is identical (§2.5), but the kernel term is different, so any consumer unfolding those arms sees the guard/the moved match. cerberus-sl (`/home/dev/projects/cerberus-sl`, read-only; pin `CERBERUS_LEAN_COMMIT="e64819de7e…"`, older than `e283bed77`) unfolds `reconstructValue_lemFuel` by `simp only [reconstructValue, CerbTagsWf.envBound, reconstructValue_lemFuel, …]` in six proofs (`Repr.lean:246,383,406,412,464,574`) — all on the Integer/pointer arms, which the `match` on a concrete ctype constructor reduces past the struct/union arms — and states `HeapModel.Decodes` over `reconstructValue` for scalar cells (`HeapModel.lean:234-238`); no `MVstruct`/`MVunion`/`Struct`/`Union0` reasoning about `reconstructValue` exists there (*reproduced*: grep → none). So no consumer proof is affected today; the sentence should say "no signature or hypothesis change; the struct/union arm TERMS change (a consumer unfolding them sees the guard)", and the cerberus-sl re-pin note practice ([USER 2026-09-16]: re-pin notes go to cerberus-sl) wants one line naming the two arms.

### N4 — NOTE (range 2) — record precision: "eleven-line comment paragraph"; the §6 wipe lines are transcript, not log

(i) §4 and §8 E2: *"an eleven-line comment paragraph"* — the `lakefile.toml` diff adds TEN `#` lines + the `rev` line (*reproduced*: `+#` lines 10, `+rev` 1; `12 +++++++++++-`). (ii) §6's *"`clean rc=0`"*, *"`gone: ocaml_frontend/generated` / `gone: sibylfs/generated` / `gone: lean_frontend/generated` / `ocaml stamp removed by clean`"*, *"`make rc=0 wall=41s`"* are NOT in `.tmp/s15/wipe.log` (which holds only the `scripts/ce` env banner) nor in `regen.log` (which holds the recipe's `[LEM]`/`[STAMP]`/`check_lem_sync: recorded …` lines) — terminal lines (the S0.5 audit's N7 class). The OUTCOME is witnessed: `gen-before.sha256`/`gen-after.sha256` 305 = 305 rows, sorted-by-path `diff` EMPTY (*reproduced*), and my own wiped derivations (§2.2).

### N5 — NOTE (ranges 2, 3) — primed worktrees carry stale `.lake` state; the S1.5 head's row 1 in mine FAILS on the fuel-forms gate loudly, not vacuously

Both my cerberus audit worktrees arrived with `CerbMem_lemMeasureProofs.olean` ABSENT (only its 2026-09-15 `.hash`/`.trace`), `.lake/packages/LemLib` at `4307dc5` while the S1.5 manifest says `38f87d5` (Lake re-cloned on the first build: `info: LemLib: URL has changed; deleting … cloning again` / `checking out revision '38f87d5…'`), and the hotfix worktree's `generated/` copies stale vs its hand-written files (priming copied the primary's tree; `make lean-prelude-src` fixed it). My `lake build CerberusLean cerberus-lean` at `5a5579209` rebuilt 208 targets. At `52af8ccf1` the OLD gate in my worktree (*reproduced*, §2.3): `fuel-forms-tool: importing 104 modules` / `uncaught exception: unknown module prefix 'CerbMem_lemMeasureProofs'` / `check_fuel_forms: FAIL — the classifier tool failed (fail-closed)` — fail-closed by the accident of the primed state (the orchestrator's F-1 reproduction had deleted the primary's `.olean` before priming); the VACUOUS pass needs a pre-H1 `.olean` present, which the arc worktree had. The hotfix record §6 already files the priming hazard as a container follow-up; recorded here as the observed state the brief asked for.

### N6 — NOTE (range 3) — small cite/comment residuals

(i) Charter §0: *"imported by NOTHING — `grep -rn "import CerbMem_lemMeasureProofs" lean_frontend` → none"* — the grep DOES hit `lean_frontend/docs/2026-09-07_fuel-measure-cost-MeasureAudit.lean:2` (a docs probe; not a Lake root; nothing in `scripts/`, `tools/`, `lakefile.toml` or the `Makefile` runs it — *reproduced*); the claim holds for the build. (ii) `scripts/test_unit.sh:224` still says *"--selftest (24 plants …)"* — the record §6 notes it (outside the fence unless the invocation changes). (iii) `.lake/build/lib/lean/Core_unstruct_auxiliary.olean` (2026-08-25) has no source — the record §0's orphan, confirmed.

### N7 — NOTE (range 1) — the `reader_seed` × mutual refusal has no shipped probe; it fires with fuel and readers present

The lem-lean record §7 says so (out of fence). *Reproduced* (`neg_seed_mutual.lem`: a fuel'd, reader-lifted truly-mutual pair with `declare {lean} reader_seed val sping`), both lems: `Error: Lean backend: reader_seed in a mutual block (unsupported; the mutual partner would escape lifting)` — the refusal at `:4505-4507`… no: at the `reader_seed` arm of `seed_info` (`lean_backend.ml:4503-4508`, *"reader_seed on a multi-clause or mutual definition"* is the multi-clause text; the mutual text above is what fires). A follow-up probe, when the fence next opens.

## 2. The scope items — what I did, verbatim outputs, verdict

### 2.1 lem-lean `4307dc5..38f87d5` (scope A)

**(a) The backend change, by reading** (`git show 38f87d5 -- src/lean_backend.ml`, *reproduced*): two hunks. Hunk 1 (`@@ -4440,8 +4440,15 @@`) rewords the emission comment (*"single-clause, non-mutual, non-instance, not reader-lifted (extend on need …)"* → *"single-clause, non-instance. Composes with truly-mutual blocks (arc 3, B2) and with reader lifting — INCLUDING inside a mutual block … Fail closed on the remaining unsupported combinations: supply x truly-mutual, reader_seed x mutual, anything inside an instance."*). Hunk 2 (`@@ -4601,15 +4608,18 @@`) deletes exactly
```
-                     | Some _ when is_truly_mutual && lifted ->
-                       raise (Reporting_basic.err_general true (locn_of_clause_group g)
-                         "Lean backend: 'declare {lean} fuel val' in a mutual block combined with reader lifting (unsupported; extend when needed)")
```
and rewords the "fuel x reader composes (arc 3, B1)" comment (adds the per-member mutual sentence). No other line of the file moves; `git diff --stat 4307dc5 38f87d5 -- lean-lib` → empty (*reproduced*). **Guard deletion + comments only: confirmed.**

**`a618b9c` and the record's one sentence.** `git show a618b9c` (*reproduced*): *"Lean backend: fuel composes with mutual blocks (arc 3, B2)"*, 2026-08-18, 5 files; its message: *"All-or-none guard per mutual block (a non-fuel'd member would reset the fuel via the wrapper); fuel'd-mutual x reader-lifting stays fail-closed."*; its diff NARROWS `| Some _ when is_truly_mutual ->` / `"… in a mutual block (unsupported)"` to `| Some _ when is_truly_mutual && lifted ->` / `"… combined with reader lifting (unsupported; extend when needed)"`, and — decisive for the judgement — the SAME diff's sibling-call rewrite already reads
```
+              | Some w ->
+                (* Self- or cross-member call inside a fuel'd block: recurse
+                   on the decremented fuel binder; a lifted worker also
+                   re-injects its reader binders (arc 3, B1/B2). *)
                 let readers =
                   if !lean_reader_binder then reader_args_output () else emp in
                 Output.flat [from_string "("; from_string w;
                              from_string " lemFuel"; readers; from_string ")"]
```
— the composition's mechanism was in place when the guard was written. The record §2's *"a scope cut, not a technical obstacle"* and its list of the generic sites (`:4652` `St.reader_binder := lifted`; `:4741-4747` the wrapper's reader arrows; `:4834-4866` `reader_binders`/`reader_args` between `inhabited_binder_output ()` and `arg_binders`; `:4905-4918` the `_zero` lemma's `reader_binder_output ()`; `:5958-5972` the `St.fuel_workers` rewrite; `:1192-1201` one `(defined, used)` per `Val_def`, `:1215` `union defined`) all resolve at `38f87d5` (*reproduced* by `sed -n`). **Judgement: accurate.**

**(b) Adversarial probes** (all under `lem-lean-audit/mutual-fuel-readers/.tmp/audit/probes/`; generated with the NEW `./lem -wl ign -lean -outdir gen <file>` — `rc=0` each; compiled in a scratch Lake project `require LemLib from "../../../../lean-lib"`, `leanprover/lean4:v4.28.0`, `-DautoImplicit=false`, `scripts/capped lake build`; the consumer rep `AuditImpl.consume (amb : Nat) (y : Nat) : Nat := amb * 100 + y`). Build tail, verbatim (`build_probes.log`, then the re-run with probe (vi) added):
```
info: ProbeCheck.lean:55:0: 'ta' depends on axioms: [propext]
info: ProbeCheck.lean:56:0: 'gping' depends on axioms: [propext]
info: ProbeCheck.lean:57:0: 'hping' does not depend on any axioms
info: ProbeCheck.lean:58:0: 'mev3' depends on axioms: [propext, Classical.choice, Quot.sound]
info: ProbeCheck.lean:59:0: 'mev3_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
info: ProbeCheck.lean:60:0: 'msum3_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
Build completed successfully (40 jobs).
rc=0 END 2026-09-20T18:41:57Z
```
```
info: ProbeCheckB.lean:19:0: 'wping' depends on axioms: [propext]
Build completed successfully (43 jobs).
```
Every `example` below elaborated in those builds.

*(i) only one member reads the reader* — a THREE-member block `ta`/`tb`/`tc` where only the MIDDLE member reads `amb`. Generated:
```
mutual
 def  ta_lemFuel (lemFuel : Nat) (_lemReader_amb : Nat)  (n : Nat)  : Nat := match lemFuel with
  | 0 => (901)
  | Nat.succ lemFuel => ( if  n  ==   0 then   10  else (tb_lemFuel lemFuel _lemReader_amb)  (n  -   1))
def  tb_lemFuel (lemFuel : Nat) (_lemReader_amb : Nat)  (n : Nat)  : Nat := match lemFuel with
  | 0 => (902)
  | Nat.succ lemFuel => ( if  n  ==   0 then _lemReader_amb  else (tc_lemFuel lemFuel _lemReader_amb)  (n  -   1))
def  tc_lemFuel (lemFuel : Nat) (_lemReader_amb : Nat)  (n : Nat)  : Nat := match lemFuel with
  | 0 => (903)
  | Nat.succ lemFuel => ( if  n  ==   0 then   30  else (ta_lemFuel lemFuel _lemReader_amb)  (n  -   1))
end
```
Pins: `ta_lemFuel (lemFuel := 100) (_lemReader_amb := 7) (n := 1) = 7`, `@ta ⟨100⟩ 7 2 = 30`, `@tc ⟨100⟩ 9 2 = 9` (two hops to the reading member), `@ta ⟨2⟩ 7 5 = 903` (the third member's sentinel at counter 0), `tc_lemFuel 0 a n = 903 := tc_lemFuel_zero a n`, `@tb ⟨n⟩ = tb_lemFuel n := rfl`. All-or-none through three members, the non-reading members thread the value. **Holds.**

*(ii) a member calls a fuel-lifted callee AND a sibling in one body* — `rdown` fuel'd and reader-lifted; `gping n = if n = 0 then rdown (amb ()) else rdown 1 + gpong (n - 1)`. Generated:
```
mutual
 def  gping_lemFuel [LemFuel] (lemFuel : Nat) (_lemReader_amb : Nat)  (n : Nat)  : Nat := match lemFuel with
  | 0 => (961)
  | Nat.succ lemFuel => ( if  n  ==   0 then ( rdown _lemReader_amb)  (_lemReader_amb)  else ( rdown _lemReader_amb) (  1)  + (gpong_lemFuel lemFuel _lemReader_amb)  (n  -   1))
def  gpong_lemFuel [LemFuel] (lemFuel : Nat) (_lemReader_amb : Nat)  (n : Nat)  : Nat := match lemFuel with
  | 0 => (962)
  | Nat.succ lemFuel => ( if  n  ==   0 then   1  else (gping_lemFuel lemFuel _lemReader_amb)  (n  -   1))
end
```
— the callee goes through its WRAPPER `(rdown _lemReader_amb)` (the FULL ambient, `[LemFuel]` on the workers), the sibling through `(gpong_lemFuel lemFuel _lemReader_amb)` (the decremented counter), both in one body. Pins: `@gping ⟨100⟩ 3 0 = 3`, `@gping ⟨100⟩ 3 1 = 4`, `@gping ⟨2⟩ 3 1 = 4` (the callee at the full ambient 2 succeeds while the sibling runs at 1), `@gping ⟨1⟩ 3 1 = 1933` (= 971 + 962: the callee exhausts at 1, the sibling at 0), `@gping ⟨n⟩ = @gping_lemFuel ⟨n⟩ n := rfl`, `@gping_lemFuel ⟨5⟩ 0 a n = 961 := @gping_lemFuel_zero ⟨5⟩ a n`. **Holds.**

*(iii)+(v) `fuel_measure` on a mutual block with THREE readers, an extra own parameter, and a single-def measured comparator.* Readers `gamma`, `alpha : unit -> nat`, `beta : unit -> string`; `mev3 k l`/`modd3 k l` measured `List.length l + 1`; `msum3 k l` the single-def comparator. Generated wrapper, `_zero` lemma and obligation (the auxiliary file):
```
def mev3 (_lemReader_alpha : Nat) (_lemReader_beta : String) (_lemReader_gamma : Nat) ( k : Nat) ( l : List (Nat)) : Bool := mev3_lemFuel (List.length l + 1) _lemReader_alpha _lemReader_beta _lemReader_gamma  k  l
theorem mev3_lemFuel_zero (_lemReader_alpha : Nat) (_lemReader_beta : String) (_lemReader_gamma : Nat) ( k : Nat) ( l : List (Nat)) :
    mev3_lemFuel 0 _lemReader_alpha _lemReader_beta _lemReader_gamma  k  l = (false) := rfl
```
```
theorem mev3_measure_sufficient (_lemReader_alpha : Nat) (_lemReader_beta : String) (_lemReader_gamma : Nat) ( k : Nat) ( l : List (Nat)) (lemFuel : Nat) (lemMeasureLe : (List.length l + 1) ≤ lemFuel) :
    mev3_lemFuel lemFuel _lemReader_alpha _lemReader_beta _lemReader_gamma  k  l = mev3 _lemReader_alpha _lemReader_beta _lemReader_gamma  k  l :=
  Probe_m_lemMeasureProofs.mev3_measure_sufficient _lemReader_alpha _lemReader_beta _lemReader_gamma  k  l lemFuel lemMeasureLe
theorem msum3_measure_sufficient (_lemReader_alpha : Nat) (_lemReader_beta : String) (_lemReader_gamma : Nat) ( k : Nat) ( l : List (Nat)) (lemFuel : Nat) (lemMeasureLe : (List.length l + 1) ≤ lemFuel) :
    msum3_lemFuel lemFuel _lemReader_alpha _lemReader_beta _lemReader_gamma  k  l = msum3 _lemReader_alpha _lemReader_beta _lemReader_gamma  k  l :=
```
The binder order — sorted readers, own parameters, `lemFuel`, `lemMeasureLe` — is IDENTICAL between the mutual `mev3`/`modd3` obligations and the single-def `msum3`; the `_zero` lemmas carry all three readers plus the own parameters; the sibling call passes `lemFuel` and all three readers (`(modd3_lemFuel lemFuel _lemReader_alpha _lemReader_beta _lemReader_gamma)  k  xs`). I wrote the three proofs (`Probe_m_lemMeasureProofs.lean`: one joint induction on the list generalizing the two fuels for the pair — the shipped template with three inert reader parameters and `k` — and one for `msum3`; kernel-only tactics) and pinned: `mev3_lemFuel (lemFuel := 10) (_lemReader_alpha := 2) (_lemReader_beta := "abc") (_lemReader_gamma := 5) (k := 3) (l := [1, 2]) = true`, `mev3 2 "abc" 5 3 [1, 2] = true` (alpha + k = gamma), `mev3 2 "abc" 6 3 [1, 2] = false`, `mev3 2 "abc" 5 3 [1] = true` (`|beta| = k` in the sibling's base case), `mev3 2 "ab" 5 3 [1] = false`, `msum3 2 "abc" 5 3 [10, 20] = 43`, `mev3_lemFuel 1 2 "abc" 5 3 [1, 2] = true` (below the measure: the sibling's sentinel), the obligation applied at the measure, the `_zero` lemma applied, and `msum3_measure_sufficient` stated with the mutual pair's binder order (elaborates: the orders agree). **Holds; matches the single-def case.**

*(iv) a member calling a `reader_consumer` inside a lambda, and partially applied (HOF)* — `hping l = … List.foldl (fun acc y -> acc + consume y) 0 l + hpong xs`, `hpong l = … List.length (List.map consume xs) + hping xs`. Generated:
```
 def  hping_lemFuel (lemFuel : Nat) (_lemReader_amb : Nat)  (l : List (Nat))  : Nat := match lemFuel with
  | 0 => (951)
  | Nat.succ lemFuel => ( match  l with  |  [] =>   0 |  x  ::  xs =>  List.foldl  (fun (acc : Nat) (y : Nat) =>  acc  + ( AuditImpl.consume _lemReader_amb)  y) (  0)  l  + (hpong_lemFuel lemFuel _lemReader_amb)  xs )
def  hpong_lemFuel (lemFuel : Nat) (_lemReader_amb : Nat)  (l : List (Nat))  : Nat := match lemFuel with
  | 0 => (952)
  | Nat.succ lemFuel => ( match  l with  |  [] =>   1 |  _  ::  xs =>  List.length  (List.map ( AuditImpl.consume _lemReader_amb)  xs)  + (hping_lemFuel lemFuel _lemReader_amb)  xs )
```
Pins: `@hping ⟨100⟩ 7 [1, 2] = 1403`, `@hping ⟨100⟩ 0 [1, 2] = 3`, `@hpong ⟨100⟩ 7 [5, 6] = 708`, `@hping ⟨2⟩ 7 [1, 2] = 2354` (= 1403 + the sibling hop reaching `hping` at counter 0 = 951; my first pin said 1403 — my arithmetic error, corrected before the build), `hpong_lemFuel 0 a l = 952 := hpong_lemFuel_zero a l`. **Holds.**

*(vi) extra: a BARE sibling reference as a HOF argument, and a lifted non-fuel'd helper called from a member* — `wping l = … List.foldl (+) 0 (List.map wpong l) + wping xs`, `helper n = amb () + n`. Generated: `List.map (wpong_lemFuel lemFuel _lemReader_amb)  l` and `( helper _lemReader_amb) (  0)` — the bare sibling is rewritten to a partial application carrying the decremented counter and the reader. Pins: `@wping ⟨100⟩ 7 [] = 7`, `@wpong ⟨100⟩ 7 0 = 8`, `@wping ⟨100⟩ 7 [0] = 15`, `@wping ⟨100⟩ 7 [1] = 22`, `@wping ⟨1⟩ 7 [0] = 1883` (the mapped sibling runs at counter 0 → 942; + `wping` at 0 → 941). **Holds.**

**(c) The suite and the sweep — reproduced.** `scripts/ce make -C tests/comprehensive lean` in the lem-lean audit worktree (`.tmp/audit/suite.log`, 1465 lines): `SUITE START 2026-09-20T18:45:09Z … lem=Lem 38f87d5`; `61: === Generation: 56 passed, 0 failed, 0 skipped ===`; `1222: Build completed successfully (173 jobs).`; the axiom lines `868-871` (`'rping' depends on axioms: [propext]`, `'fping' … [propext]`, `'rmev' … [propext]`, `'rmev_measure_sufficient' … [propext, Quot.sound]`) and `348-349` (the two `Test_fuel_mutual_reader_lemMeasureProofs.*_measure_sufficient` … `[propext, Quot.sound]`); `1224/1226` the two panic legs; `1229 single-evaluation: OK`; `1231 OK: compiled draw sequences hold`; `1233 OK: compiled consumer injection holds`; `1235 OK: compiled N-ary seed injection holds`; `1237/1239` the two fuel legs; `1241:   OK: compiled fuel x reader x mutual composition holds`; `1278:   OK (rejected as declared): negative/neg_fuel_mutual_supply.lem`; `1348:   OK: inv_fuel_mutual_reader.lem (7 artifacts byte-identical across ocaml/hol/isa/coq)`; `1461:   OK: 11 proofs modules scanned; no sorry/admit/axiom/native_decide/bv_decide token`; `1463:   OK: 260 files scanned; no lemDefaultFuel, no LemFuel instance, no literal fuel (F1-F5)`; `1465: SUITE EXIT=0 2026-09-20T18:51:20Z` (derived wall 371 s). Derived counts (awk): `rejected=101 parity=26 bothfail=6 xfail=4 FAIL=4 inv_OK=10` = the record §5's 101 / 26 / 6 / 4 (each `FAIL` paired with its `XFAIL`) / 10. `ls negative/neg_*.lem | wc -l` → `101`. My sweep (`.tmp/audit/sweep.log`; OLD = the scratch-built `Lem 4307dc5`, NEW = `./lem` `Lem 38f87d5`; the worker's corpora and invocations, logs outside the diffed trees):
```
== exit-code comparison (old vs new); mismatches and both-nonzero:
  NONZERO on both: ./backends/coq_test.log old=1 new=1
  EXIT MISMATCH ./comprehensive/test_fuel_mutual_reader.log: old=1 new=0
  NONZERO on both: ./cpp.log old=1 new=1
== per-corpus diff -r (generated trees only):
  comprehensive: DIFFERS (old 118 / new 120 files) —
Only in …/.tmp/audit/sweep/new/comprehensive/test_fuel_mutual_reader: Test_fuel_mutual_reader_auxiliary.lean
Only in …/.tmp/audit/sweep/new/comprehensive/test_fuel_mutual_reader: Test_fuel_mutual_reader.lean
  backends: IDENTICAL (old 22 files / new 22 files)
  ppcmem-model: IDENTICAL (old 20 files / new 20 files)
  cpp: IDENTICAL (old 0 files / new 0 files)
== invocations: comprehensive=58 backends=12
== old lem on test_fuel_mutual_reader.lem (verbatim):
File "test_fuel_mutual_reader.lem", line 83, character 18 to line 83, character 74
  Error: Lean backend: 'declare {lean} fuel val' in a mutual block combined with reader lifting (unsupported; extend when needed)
  original input: "match l with | [] -> amb () = 0 | _ :: xs -> rmodd xs end"
```
= the record §4 exactly. Both witnesses (worker `.tmp/sweep.log`, orchestrator `.tmp/orch-sweep/`) are thereby confirmed rather than merely accepted. **Byte-inert everywhere but the new test.**

**(d) The negatives, under BOTH lems** (*reproduced*, `.tmp/audit/probes/neg/`; `-wl ign -lean`):
- the DELETED `neg_fuel_mutual_lifted.lem` (`git show 4307dc5:…`): OLD → `File "neg_fuel_mutual_lifted.lem", line 11, character 23 to line 11, character 69` / `Error: Lean backend: 'declare {lean} fuel val' in a mutual block combined with reader lifting (unsupported; extend when needed)` / `original input: "if n = neg_env () then 0 else neg_rpong (n - 1)"`, `rc=1`; NEW → `rc=0`. Its EXPECT text no longer exists in the backend: deletion justified.
- `neg_fuel_mutual_supply.lem`: BOTH lems → `Error: Lean backend: supply lifting in a (truly) mutual block (unsupported; extend when needed — acyclic rec-and blocks de-mutualize and thread fine)` at `line 17, character 19 to line 17, character 58`, `rc=1` — the remaining refusal, pinned on the FUEL'D shape (the old lem refuses it identically: the pin is of a pre-existing refusal, as the record says). `neg_supply_mutual.lem` (un-fuel'd): identical text on both.
- my `neg_seed_mutual.lem` (`reader_seed` on a member of a fuel'd, reader-lifted pair): both → `Error: Lean backend: reader_seed in a mutual block (unsupported; the mutual partner would escape lifting)` (N7).
- my `neg_partial_fuel_readers.lem` (one member fuel'd, readers present): both → `Error: Lean backend: fuel in a mutual block requires EVERY member to carry a 'declare {lean} fuel val' (all-or-none)`.
- my `neg_partial_measure_readers.lem` (one member measured, readers present): both → `Error: Lean backend: 'declare {lean} fuel_measure val' in a mutual block requires EVERY member to carry it (FM-mutual, all-or-none: the members share one counter)`.
**The guard's neighbours still fire with readers; only the guard is gone.**

**(e) Records vs evidence.** The lem-lean record §5 vs the worker's `.tmp/suite_a2.log` (1406 lines; read with `awk` — this shell's `grep` is ugrep honouring `.gitignore`, so it returns nothing under `.tmp/`): `61: === Generation: 56 passed, 0 failed, 0 skipped ===`; `1161: Build completed successfully (173 jobs).`; `1157-1160` the four `TestFuelMutualReaderCheck` axiom lines and `503-504` the two proofs-module lines, character-identical to §5; `1163/1165` panic legs; `1167-1168` tuple-once; `1170/1172/1174` draws/consumer/N-ary; `1176/1178` fuel legs; `1180 OK: compiled fuel x reader x mutual composition holds`; `1217` and `1271` the two supply negatives; `1287` the invariance line; `1400` 11 proofs modules; `1402` 260 files; `1404 SUITE wall=357s`; `1406 SUITE_DONE rc=0`; derived 101/26/6/4/4, 10 invariance OK. **All resolve.** The S1.5 record §3's cites of the orchestrator's log (`.tmp/s15/orch-partA-suite.log`, 1407 lines, `cmp`-identical to the lem-lean worktree's `.tmp/orch-suite.log`): `4: === lem -v: Lem 38f87d5 ===`, `64: === Generation: 56 passed …`, `1164: Build completed successfully (173 jobs).`, `1182-1183` the phase banner + OK, `1220` the supply negative, `1290` the invariance line, `1407: === SUITE EXIT=0 ===`, `1403/1405` the no-sorry/no-fuel lines; derived 101/26/6/4. `orch-partA-sweep-logs-only/c-old.test_fuel_mutual_reader.log` = the pinned refusal (after the env banner). **All resolve.** `scripts/ce make` in my worktree: `rc=0`, `Lem 38f87d5`; the five `lean_backend.ml` mentions in the build log are compile commands, no warning — the record §3.1's "zero warnings attributed to `lean_backend.ml`" holds.

### 2.2 cerberus `e283bed77..52af8ccf1` — the pin bump and byte identity (scope B (a), (b))

**(a) Files.** Non-doc diff = exactly the four Lake pin files + the manifest (header). `rev`/`inputRev` = `38f87d5fa6b29ec90edfa457faba8a309e32c118` at all six occurrences in the three manifests, `rev` in `lakefile.toml`; the manifest diff = an 8-line dated NOTE at the top + `-lem-pin=4307dc5`/`+lem-pin=38f87d5`, nothing else (`10 +++++++++-` = 9 insertions, 1 deletion; *reproduced*). The two charters are docs. The NOTE's content ("both generated trees re-derived from WIPED trees under Lem 38f87d5 equal the Lem 4307dc5 snapshot … 305 files = … 86 + … 219; sibylfs 16 … layer-2 set unchanged (25 …). Not a --refresh") matches the facts below.

**(b) Byte identity — the third witness** (*reproduced* at `52af8ccf1`, `.tmp/audit/regen/regen.log`; the OLD lem via a one-line wrapper `exec …/.tmp/audit/lem-4307dc5/lem "$@"` placed first on `PATH` inside `scripts/ce bash -c` (`which lem` → the wrapper), then the switch's lem; each pass `make clean-prelude-src clean-sibylfs-src && rm -rf lean_frontend/generated` (existence-checked) then `make prelude-src lean-prelude-src`, then `find ocaml_frontend/generated lean_frontend/generated -type f | LC_ALL=C sort | xargs sha256sum`):
```
START 2026-09-20T18:34:59Z HEAD=52af8ccf1 load=0.19 0.35 0.39
== [OLD] wipe + regenerate under lem 4307dc5 (wrapper first on PATH) ==
which lem: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/program-data-parameters-S1.5/.tmp/audit/regen/wrap/lem
Lem 4307dc5
clean rc=0
gone: ocaml_frontend/generated
gone: sibylfs/generated
gone: lean_frontend/generated
old regen rc=0 2026-09-20T18:35:36Z
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
old: 305 files; sibylfs 16
== [NEW] wipe + regenerate under the switch lem ==
which lem: /home/dev/projects/cerberus-lean-proj/cerberus-lean/_opam/bin/lem
Lem 38f87d5
clean rc=0
gone: ocaml_frontend/generated
gone: sibylfs/generated
gone: lean_frontend/generated
new regen rc=0 2026-09-20T18:36:14Z
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
new: 305 files; sibylfs 16
== diff old vs new trees ==
diff rc=0
== diff old vs new sibylfs ==
diff rc=0
== stamps ==
ocaml stamp diff rc=0
lean stamp diff rc=0
== vs worker gen-after.sha256 (hash set) ==
diff rc=0
== vs worker gen-before.sha256 (hash set) ==
diff rc=0
== lem-sync checks (no re-record) ==
check_lem_sync: OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
check_lem_sync: lean OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
END 2026-09-20T18:36:14Z
```
Then at the same head (*reproduced*): `check_fork_content: OK — 76 source files content/mode-pinned` / `check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)` and `check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules all built)` (the pre-hotfix wording). The two existing witnesses: the worker's `gen-before.sha256` = `gen-after.sha256` (305 = 305 rows, sorted-by-path `diff` EMPTY; sibylfs 16 = 16) and the orchestrator's sweep are consistent with mine (both hash SETS equal to my old- and new-lem derivations). **Verdict: the pin bump is byte-inert on this tree, by three independent derivations; the stamps and the fork-drift/lakefile-roots gates are green at the head.**

### 2.3 cerberus `e283bed77..52af8ccf1` — record vs evidence; row 1 at this head (scope B (c), (d))

**§3 boundary + suite**: §2.1 (e). **§4**: the pin triple (*reproduced*, read-only): `deps/lem-pinned` HEAD `38f87d5fa6b29ec90edfa457faba8a309e32c118` on `cerberus-pin`; `opam pin list --switch=.` → `lem.2026-05-01    git  git+file:///home/dev/projects/cerberus-lean-proj/deps/lem-pinned#cerberus-pin`; `scripts/ce lem -v` → `Lem 38f87d5`; the four files carry the full hash; the re-cloned package in my worktree → `rev-parse HEAD` `38f87d5fa6b29ec90edfa457faba8a309e32c118`; lem-lean `mutual-fuel-readers` = `38f87d5`, `mdd/lean-backend` = `4307dc5` ("NOT yet true" — as the record says); `git diff --stat 4307dc5 38f87d5 -- lean-lib` → empty. **§6**: `gen-before`/`gen-after` 305/305, sorted `diff` empty, sibylfs 16/16 (*reproduced*); the wipe/clean lines are transcript (N4). **§7.1** vs `.tmp/s15/build_b4.log`: `5: check_driver_fresh: recorded oracle stamp (bin f104ce768a106d71e03917b06afe138a1fc2f58ac6e157053db3ebf05cfd352c, src 2b8b576816681316ce0c0b690dc78a63f813ac8a7391f976bdf4684a18f47634)`; `7: ✔ [232/285] Built LemLib.Machine_word:c.o (260ms)`; `9: Build completed successfully (285 jobs).`; `10: check_driver_fresh: recorded lean stamp (bin 8e9f7fb1a1c99ef9a8ea05fcdddc8fa5f7cc961f1644a3680306699534595729, src 453fe3a1a85395c41e4575022610693ce832be825eeef85d114e27fe3cb69257)`; `11: build_cerberus+build_lean rc=0 wall=11s`; `build_b4_speclab.log:2824-2825: Build completed successfully (148 jobs).` / `speclab lake build rc=0 wall=0s`; the Lean binary hash `8e9f7fb1…` = the S0.5 record §6's (the S0.5 audit quotes it). **§7.2** vs `.tmp/s15/release-fast/`: `summary.txt` = `fast: incomplete; 16/16 selected commands completed successfully.` / `Source unchanged: False. Complete tier selection: True.`; `A1/stdout:483 Total: 12 passed, 0 failed`, `:580` axioms OK, `:581` sorry OK, `:651` no-fuel-numerals OK, `:660` lakefile-roots OK, `:695/:698 check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …` (M1), `:696` SELFTEST OK (24 plants), `:711 check_failure_reach: OK (233 …`, `:712` totality CLEAN, `:713-714` lem-sync OK/lean OK, `:736 check_fork_drift: OK — … lem-pin 38f8…`, `:737` fixture-freeze OK, `:750` renumber-plants OK; every lane's SUMMARY/verdict line (A2 `total=113 match=90 ub_match=18 …`/`BASELINE OK`; A3 `total=212 match=183 ub_match=16`; A4 `total=90 match=66 ub_match=20`; A4b `total=93 match=93`; A4c `exec_match=9 neg_pinned=5 fail=0`/`ALL AT COMMITTED EXPECTEDS`; A5 `match=12 diff=0`/`ALL MATCH RECORDED BASELINE`; A6 `total=2 match=2`; A6b `total=7 match=7`; A7 `8/8 passed`, the cabs bytes probe line, `ALL PASSED`; A8 `Success rate:   100% (of cerberus successes)`; A9 `total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0`; A10 `GATE PASS: … (16/16)`; A11 `total=213 match=207 ub_match=6 …`/`BASELINE OK (213 entries, exact match)`; A12.1/A12.2 `EXPECT OK    18 pinned rows = 18 observed cases, every token identical` + the SELFTEST/OK lines) = the record §7.2 verbatim. **Every quoted line resolves; the row-1 fuel-forms line is the vacuous one (M1).** Errata E1–E3: E1 (`0f5509872` is the parent of `52af8ccf1`, *reproduced*) ✓; E2 says "eleven-line" (N4) ✓ otherwise; E3 ✓.

**Row 1 at `52af8ccf1` in my primed worktree** (*reproduced*, after the wiped regeneration of §2.2; `.tmp/audit/row1/`): the OLD `check_fuel_forms.sh` — `fuel-forms-tool: importing 104 modules` / `uncaught exception: unknown module prefix 'CerbMem_lemMeasureProofs'` / `check_fuel_forms: FAIL — the classifier tool failed (fail-closed); diagnostics tail:`, `EXIT=1` (the `.olean` is ABSENT in the primed `.lake`: N5). `test_unit.sh` at this head (`.tmp/audit/row1/test_unit.log`, `EXIT=1` at 19:11:03): `check_handwritten_sync: OK (49 …)`, `Total: 12 passed, 0 failed`, `check_exec_purity: CLEAN (11 modules)`, `check_theorem_axioms: OK (…)`, `check_sorry_token: OK (318 files …)`, `check_no_fuel_numerals: OK (325 files …)`, `check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules all built)`, then `check_fuel_forms: FAIL — the classifier tool failed (fail-closed); diagnostics tail:` / `test_unit: fuel-forms gate SELFTEST FAILED` (the runner exits at the first red gate). The gates after it, run directly on the same tree: `check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; …)`, `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`, `check_fork_content: OK — 76 source files content/mode-pinned` / `check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)`, `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)`, `check_lem_sync: OK (src 037dee26…, gen 08b84774…)` / `check_lem_sync: lean OK (src 037dee26…, gen cd499eab…)`, `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)` — all `EXIT=0`. The F-1 module itself at this tree (its `CerbMem_lemMeasureProofs.lean` and `CerbMem.lean` are `cmp`-identical to `e283bed77`'s): §2.8. **Honest state: row 1 is NOT green at this head in a primed worktree — the fuel-forms gate fails (loudly, here); it passed vacuously only where a pre-H1 `.olean` was present. Everything else in row 1 that ran is green; fork-drift, lakefile-roots and lem-sync green (§2.2).**

### 2.4 The hotfix — F-1 and the hardened gate (scope C (a), (b))

**(a) F-1 at the parent** (*reproduced* at the S1.5 head, whose `CerbMem_lemMeasureProofs.lean` and `CerbMem.lean` are byte-identical to `e283bed77`'s — `cmp` against `git show e283bed77:…` → identical; `.tmp/audit/f1/repro-F1.log`; `scripts/ce ../scripts/capped lake build CerbMem_lemMeasureProofs` from `lean_frontend/`):
```
START 2026-09-20T18:37:41Z HEAD=52af8ccf1
proofs module == parent e283bed77 version
CerbMem.lean == parent e283bed77 version
info: LemLib: URL has changed; deleting '…/program-data-parameters-S1.5/lean_frontend/.lake/packages/LemLib' and cloning again
info: LemLib: cloning https://github.com/OathTech/lem-lean
info: LemLib: checking out revision '38f87d5fa6b29ec90edfa457faba8a309e32c118'
✖ [81/81] Building CerbMem_lemMeasureProofs (2.0s)
error: generated/CerbMem_lemMeasureProofs.lean:921:8: Tactic `rewrite` failed: Did not find an occurrence of the pattern
  panicWithPosWithDecl ?m ?d ?l ?c ?msg
in the target expression
  x ∈ (failwithI "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)").fst
error: generated/CerbMem_lemMeasureProofs.lean:1016:18: Tactic `rewrite` failed: Did not find an occurrence of the pattern
  panicWithPosWithDecl ?m ?d ?l ?c ?msg
in the target expression
  MemValue.MVunion t
      (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").fst
error: Lean exited with code 1
Some required targets logged failures:
- CerbMem_lemMeasureProofs
error: build failed
EXIT=1
END 2026-09-20T18:39:55Z
```
(the 80 dependencies replayed after the LemLib re-clone; only this module built) = the charter §0 and the record §0 character-for-character. Nothing imports the module in the build (N6 (i)); `git show e283bed77:scripts/check_fuel_forms.sh:96-104` builds only `fuel-forms-tool` and then runs it on `Driver CerbCall CerbND Main $aux`, and `test/Unit/FuelFormsTool.lean:376` is `let env ← importModules imports {} 0 (loadExts := true)` — the `.olean`s as found. `fce1de9f8` (2026-09-19 01:34:23 +0000, *reproduced*) is where exactly the two leaves moved (`-    | none => panic! "CerbMem.offsetsof: unknown tag …"` → `+    | none => failwithI …`; the recorded-member leaf in both twins); the module's last prior edit is `49e98d9cf` (2026-09-05 19:10). **The finding is real and dated correctly.**

**(b) The hardened gate, by reading** (`git diff e283bed77 5a5579209 -- scripts/check_fuel_forms.sh`): `ENTRY_MODULES="Driver CerbCall CerbND Main"` (one definition for the build and the tool's argument list); `table_of_tree` runs `"$CAPPED" lake build $ENTRY_MODULES $aux` into `${log}.build` BEFORE anything else, and on failure prints `check_fuel_forms: FAIL — obligation carrier / entry module(s) did not compile from source: <the "- X" lines after "Some required targets logged failures:"> …` to stderr with the tail; then compiles each `FUELFORMS_EXTRA_MODULES` decoy from source (`lake env lean --root=… -o …`) — FAIL naming the module on error; then builds and runs the tool as before; the three FAIL diagnostics moved to stderr (the function's stdout is the table). The selftest's per-plant compile loops are deleted (the gate now compiles the decoys); **P24** compiles `FuelFormsPlantStaleCarrier` from a CORRECT source, records the `.olean`'s `stat -c '%s %Y'`, overwrites the source with `theorem CerbMem.plantStaleCarrier_broken : (1 : Nat) = 2 := rfl`, runs `table_of_tree` with it as an extra, and passes only if `rc != 0` AND the output matches `check_fuel_forms: FAIL — extra module \`FuelFormsPlantStaleCarrier\` .* did not compile from source` AND the `.olean` is non-empty with the SAME size and mtime. The SELFTEST OK line says 25 plants. The trap cleans `${LOG}.build`. `check_lakefile_roots.sh`: the OK line's "all built" → "listed as roots — names only; every carrier is built by check_fuel_forms.sh" with a comment (the gate builds nothing — true: `run_gate` only compares name sets).

**The gate at the head** (*reproduced*, `5a5579209`, after `make lean-prelude-src` (`check_handwritten_sync: OK (49 …)`) and `lake build CerberusLean cerberus-lean` (`Build completed successfully (395 jobs).`, rc 0, 18:52:07 → 18:53:00, 208 targets rebuilt; `⚠ [248/395] Built CerbMem (2.4s)`, `✔ [333/395] Built CerbMem_lemMeasureProofs (4.2s)`); `.tmp/audit/gates/chain.log`):
```
=== check_fuel_forms.sh --selftest ===
EXIT=0
  PLANT OK   [P24 carrier with a stale-valid .olean and a source that no longer compiles (F-1 in-plant): the gate FAILS naming the module; the stale .olean untouched] -> check_fuel_forms: FAIL — extra module `FuelFormsPlantStaleCarrier` (FUELFORMS_EXTRA_PATH=/home/dev/projects/cerberus-lean-proj/.tmp/tmp.0eQpoLWm9T) did not co…
  UNPLANTED:
    check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: SELFTEST OK (25 plants with the declared label — …)
PLANT OK lines=28 PLANT FAIL lines=0
=== check_fuel_forms.sh ===
EXIT=0
check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (…
```
(28 `PLANT OK` lines = 25 plants + P12's second line + the P10/P11 premise lines, as the record §4.0.1 derives.) **Population 81/62/13/0/6: confirmed.**

**Trying to defeat P24 — three tree-path plants of my own** (*reproduced*, `.tmp/audit/gates/plants.sh` + `plant-*.log`; carrier `Ctype_lemMeasureProofs`, the `generated/` copy edited, restored from the hand-written file at the end; run AFTER Tier A on the clean tree):
```
PLANTS START 2026-09-20T19:07:05Z
premise: generated copy == hand-written
premise olean: 1077192 1789893530
=== P-a: uncompilable source over a fresh .olean ===
P-a gate EXIT=1 (expect 1)
   check_fuel_forms: FAIL — obligation carrier / entry module(s) did not compile from source: Ctype_lemMeasureProofs (the gate imports nothing it has not just built — F-1, 2026-09-20; log tail fol…
   - Ctype_lemMeasureProofs
   check_fuel_forms: FAIL — the classifier tool failed (fail-closed); diagnostics tail:
   - Ctype_lemMeasureProofs
stat: cannot statx 'lean_frontend/.lake/build/lib/lean/Ctype_lemMeasureProofs.olean': No such file or directory
=== P-b: DIFFERENT compiling source, no rebuild ===
P-b gate EXIT=0 (expect 0)
   check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (…
olean before= after=1078096 1789931227 -> REBUILT by the gate (the stale-olean state did not survive)
=== P-c: touch only ===
restore gate EXIT=0
P-c gate EXIT=0 (expect 0)
olean before=1077192 1789931233 after=1077192 1789931233
=== restore + verify ===
restored: generated copy == hand-written
handwritten sync rc=0
final gate EXIT=0 (expect 0)
   check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (…
PLANTS END 2026-09-20T19:07:23Z
```
Reading: (P-a) the real-tree F-1 state — a fresh, valid `.olean` and a source that no longer compiles — FAILS the gate naming the carrier, and Lake's failed rebuild REMOVES the old `.olean` (so the stale artifact cannot even linger for a later import); (P-b) the state the brief asked about — a source that COMPILES but whose `.olean` is stale — is rebuilt by the gate before the import (the `.olean` changed size: `1077192` → `1078096`, carrying the planted theorem), so it cannot be imported stale; (P-c) a touch without a content change is (correctly) not a rebuild — Lake's traces are content hashes. The residual I could construct: NONE for carriers and entries (the gate's `lake build` decides by source+dependency hashes); the extras path (`lean -o` over the SAME path) always recompiles. What remains outside the gate's reach is the class M2 names — a root that is neither an entry, a carrier, nor imported by any of them (`CerbConcurrency`), and a hand-written file edited without `make lean-prelude-src` (the handwritten-sync gate's job, which runs first in row 1). **Is the stale-valid-`.olean`-over-uncompilable-source state now impossible for what the gate certifies? Yes — by Lake's trace check for carriers/entries and by unconditional recompilation for extras; both shown live.**

### 2.5 The two restated arms (scope C (c))

**By reading** (`git diff e283bed77 5a5579209 -- lean_frontend/CerbMem.lean`, *reproduced*): the diff is the Struct and Union0 arms of `reconstructValue_lemFuel` (`:1104-1166` at the head), the SAME two arms of `reconstructValue_indexed_lemFuel` (`:1247-1280`), one sentence in the twin's header comment, nothing else (the record §3.6 rebase note's line ranges — Struct `1104–1135`, Union0 `1136–1166`; twin `1247–1261`, `1262–1280` — are exact: the arm heads are at `:1104`, `:1136`, `:1167` (`| _ =>`), `:1247`, `:1262`, `:1281`).

*Struct arm.* OLD: `let (offs, _) := offsetsof ambient ambient tagSym (ignoreFlexible := true)` then the fold. NEW: `match CerbTagsWf.lookupEntry ambient tagSym with | none => failwithI "CerbMem.reconstructValue: unknown struct tag (…impl_mem.ml:1067/1073)" | some _ => <the old body verbatim>`. `offsetsof_lemFuel` (`CerbMem.lean:424-430`, *reproduced*) begins `match CerbTagsWf.lookupEntry tagDefs tagSym with | none => failwithI "CerbMem.offsetsof: unknown tag …"` on its SECOND argument, and the arm passes `ambient ambient` — so the new guard is literally the lookup `offsetsof` performs first. Case `some _`: the bodies are identical text → identical values. Case `none`: OLD evaluated `offsetsof` (strict `let`), whose first act is that `failwithI` → at runtime the kill fires there, and the fold over `(failwithI …).fst` is never reached; NEW kills at the guard. Same input class, same kill, one frame earlier; the TEXT differs (an allowed discrepancy class). **Behaviour-identical on the defined domain; on failing inputs the same kill one frame earlier.**
*Union arm.* OLD: `let (membIdent, membTy) := match unionmap.find? … with | none => (firstIdent, firstTy) | some (_, membr) => match membrs.find? … with | some (i, (_, _, _, t)) => (i, t) | none => failwithI …` then ONE recursive call on `membTy`. NEW: the two `find?` matches moved outward; `none`/`some-found` each build `.MVunion tagSym <ident> (reconstructValue_lemFuel … <ty> (bytes.take (sizeofCtype ambient <ty>)))` with the SAME `<ident>`/`<ty>` the old `let` selected (`firstIdent`/`firstTy`, `membIdent`/`membTy`), and the not-found case IS the `failwithI`. Case analysis: for each of the three branches the old and new terms compute the same value (the old `let` pattern-match was strict, so its `failwithI` also fired before the recursion). **Identical; the leaf is now the whole result.** The pre-existing `empty UnionDef` and `not a UnionDef` leaves are untouched.
*Mirror-OCaml cites* (`memory/concrete/impl_mem.ml`, *reproduced* by `sed -n 1060,1100p`): `1065 | Struct tag_sym ->`, `1067 let (bs1, bs2) = L.split_at (Z.to_int (sizeof cty)) bs in`, `1068-1072` the fold with `pad` (the mirrored quirk), `1073 … (fst (offsetsof ~ignore_flexible:true (Tags.tagDefs ()) tag_sym)) in`, `1075 (taint, MVstruct (tag_sym, List.rev rev_xs), bs2)`, `1076 | Union tag_sym ->`, `1081 else (match Pmap.find tag_sym (Tags.tagDefs ()) with`, `1082 | _, UnionDef ((first_membr_def :: _) as membrs) ->`, `1084-1086 match IntMap.find_opt addr unionmap with | None -> first_membr_def`, `1088 match List.find_opt (fun z -> Symbol.instance_Basic_classes_Eq_Symbol_identifier_dict.isEqual_method (fst z) membr) membrs with`, `1089-1090 | None -> assert false`, `1093 let (taint, mval, _ ) = self membr_ty bs1 in`, `1094 (taint, MVunion (tag_sym, membr_ident, mval), bs2)`, `1096 assert false`. Every cite in the new comments (`:1065-1075`, `:1069-1072`, `:1067/1073`, `:1076-1096`, `:1084-1086`, `:1088`, `:1089-1090`, `:1093`, `:1094`) is exact to the line; the OCaml raises (`Not_found` inside `sizeof`/`offsetsof`, `assert false`) before computing anything of the struct/member — the whole-result leaf is the better mirror, as the ruling says.
*The twin.* `#print axioms CerbMem.reconstructValue_lemFuel_eq_indexed` → `[propext, Classical.choice, Quot.sound]`; `#check` → `∀ (lemFuel : Nat) (ambient : …) (unionmap …) (funptrmap …) (addr …) (ty …) (bytes …), reconstructValue_lemFuel … = reconstructValue_indexed_lemFuel …` (*reproduced*, `.tmp/audit/gates/axioms.log`) — the equivalence lemma still closes at the head. *The lanes:* §2.9 (rows 2–12 at their recorded tails).

### 2.6 The restored `Reconstruct` proofs (scope C (d))

**Statements.** I extracted each of the nine obligations from `theorem <name>` through the line containing `:=` at `e283bed77` and at `5a5579209` and diffed (*reproduced*, `.tmp/audit/stmts_{parent,head}.txt`): `parent statement blocks: 9; head: 9` / `NINE OBLIGATION STATEMENTS: IDENTICAL (through :=)`. Row 6 at the head, verbatim:
```
theorem reconstructValue_measure_sufficient (ambient : CerbTags.TagDefsMap) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.envBound ambient ty ≤ lemFuel) :
    reconstructValue_lemFuel lemFuel ambient unionmap funptrmap addr ty bytes =
      reconstructValue ambient unionmap funptrmap addr ty bytes := by
```
The `theorem` lines that DO change are exactly `panic_eq_default` (deleted), `pot_default` (deleted) and the helper `offsetsof_types` (gains `(v : Entry) (hl : lookup tagDefs t = some v)` and drops the `∃ v, lookup tagDefs t = some v ∧` from its conclusion) — none is an obligation. **Proof shape** (by reading the diff): `offsetsof_types`' unknown-tag arm → `rename_i heq; simp [lookup, heq] at hl`; `reconstructValue_stable_aux`'s Struct arm → `split` on the new guard, `rfl` on the leaf, `obtain ⟨s, v⟩`/`lookup_of_entry heq` in the `some` arm and the OLD fold argument with `offsetsof_types … v hl`; the union arm's not-found case → `rfl`; the two `simp only` no-ops removed. Tactics: `split`, `rfl`, `simp`/`simp only`, `rw`, `omega`, `obtain`, `rename_i`, `exact`, `to_congr` (the C2 toolbox macro from `CerbMeasureLemmas`) — kernel-only; `grep -n 'set_option\|maxRecDepth\|maxHeartbeats\|native_decide\|bv_decide\|sorry\|admit'` on the head module → only `28:set_option autoImplicit false` (pre-existing) and one `decide` inside a `def`'s filter predicate (`:160`, pre-existing, not a proof tactic). **Axiom census** (*reproduced*, `lake env lean` on a probe importing the module):
```
'CerbMem.typeofMval_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.unqualifyAndUnatomic_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memValueToBytes_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.alignofCtype_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.sizeofCtype_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memberAlign_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.offsetsofMembers_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.offsetsof_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.reconstructValue_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
```
`git diff --stat e283bed77 5a5579209 -- scripts/fuel_hypotheses.txt scripts/common.sh scripts/test_unit.sh` → empty (*reproduced*): the register, `common.sh` and the unit runner are byte-unchanged. **All as claimed.**

### 2.7 The failure-reach register reseal (scope C (e))

`git diff e283bed77 5a5579209 -- scripts/failure_reach_register.txt` (*reproduced*) = the tally line + ONE new row + TWO moved rows (`7 +-` = 4 insertions, 3 deletions). Derived tally check: sites 233 → 234 (+1 new) ✓; exec 231 → 232 ✓; reviewed-TAIL 179 → 181 (+1 new TAIL, +1 the recorded-member row NON-TAIL/LET-BOUND → TAIL) ✓; reviewed-NON-TAIL 54 → 53 ✓; UNREACHABLE-BY-INVARIANT 166 → 167 (+1 new) ✓; REACHABLE 48, UNKNOWN 19, discardable 0 unchanged ✓ — every number the record §3.6 gives. Row texts against the register's header rules (*"Reach classes are REVIEWED CLAIMS … an invariant NAME with a .lem/.lean cite, or a witness program …"*): the NEW row (`unknown struct tag`, `STMT-NEWLINE`/`TAIL`/`UNREACHABLE-BY-INVARIANT`) names the invariant — *"typing: a load's ctype is complete — lvalue conversion of an incomplete non-array type is UB020 (STD §6.3.2.1#2) and halts typing, and is_complete makes a Struct tag complete only when it is in tag_definitions (= core_tagDefs = tagDefs); same invariant as the `CerbMem.offsetsof: unknown tag` row"* — with cites `ail/genTyping.lem:1819-1826; ail/ailTypesAux.lem:222-262; translation.lem:4245`, all of which resolve (*reproduced*: `genTyping.lem:1819-1826` is the lvalue-conversion branch ending in `E.undef (Loc.locOf ty) Undefined.UB020_nonarray_incomplete_lvalue_conversion`; `ailTypesAux.lem:222` `let rec is_complete sigm ty =` with the `Struct` arm's `Nothing -> false` at `:260-261`; `translation.lem:4245` `let core_tagDefs = translate_tag_definitions sigm.A.tag_definitions in`); it is the same class as the existing `offsetsof: unknown tag` row (`UNREACHABLE-BY-INVARIANT`, *"typing: offsetof/sizeof require a complete struct type …"*), and its shadowing sentence holds at the head (`loadM`'s `doLoad` binds `size := sizeofCtype tagDefs ty` at `:2429` before `reconstructValue` at `:2434` — N1 for the cite). The MOVED recorded-member row: live `LET-BOUND → STMT-NEWLINE` and reviewed `NON-TAIL/LET-BOUND → TAIL` are what the new shape IS (the leaf is the whole `MVunion` result — `CerbMem.lean:1165`); reach `UNKNOWN` kept with its justification unchanged — permitted (N2 on the better class). The MOVED not-a-UnionDef row: live class only, reviewed `TAIL`/`UNREACHABLE-BY-INVARIANT` unchanged, the stale "classifier picked the inner match" note retired — correct (the inner `let` is gone; `:1166`). The seals were regenerated by `--reseal` (the record's recipe) and the gate at the head reads `check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; …); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=167 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)` (*reproduced*). The worker's pre-review run (`.tmp/ffc/failure-reach-1.log`) names exactly the three sites (`NEW … CerbMem.lean:1123 …`, `POSITION CLASS CHANGED … :1165 …`, `… :1166 …`). **A reviewed reseal, not a blind re-record.**

### 2.8 The option-(d) ruling's premise — Probe A (scope C (f))

*Reproduced* at the S1.5 head (its `CerbMem.lean` = the parent's): `ProbeA.lean` = `git show e283bed77:lean_frontend/CerbMem_lemMeasureProofs.lean` with line 921 (`· rw [panic_eq_default] at hx; cases hx`) replaced by `· skip` and the four lines `1016-1019` of the union arm's not-found case (`rw [panic_eq_default]` … `rw [key _ _ _ _ _ (by rw [h1]; omega)]`) replaced by `skip`; `scripts/ce ../scripts/capped lake env lean ../.tmp/audit/probe/ProbeA.lean` → `EXIT=1`, exactly two errors:
```
../.tmp/audit/probe/ProbeA.lean:921:2: error: unsolved goals
case h_1
n : Nat
ambient tagDefs : CerbTags.TagDefsMap
t : sym
flag : Bool
x : identifier × ctype × Nat
x✝ : Option (sym × Entry)
heq✝ : lookupEntry tagDefs t = none
hx : x ∈ (failwithI "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)").fst
⊢ ∃ v, lookup tagDefs t = some v ∧ x.snd.fst ∈ memberTypes v.snd
```
and at `:1015:12` the `case h_2` goal `⊢ MemValue.MVunion t (failwithI "…recorded union member…").fst (reconstructValue_lemFuel f ambient unionmap funptrmap addr (failwithI "…").snd (List.take (sizeofCtype ambient (failwithI "…").snd) bytes)) = MemValue.MVunion t … (reconstructValue_lemFuel g …)` — the record §3.1's A1 and A2 residuals (modulo hypothesis names). The record's unprovability argument (a proof term valid for the opaque `failwithI` would be valid under any interpretation of it; an interpretation exists under which the `f`-vs-`g` equation is false) is sound as stated — it rests on `failwithI` having no kernel equations in the environment, which the seam-hygiene `opaque-failure-test` pins. The worker's `.tmp/ffc/probe/` logs: `ProbeA.log` 2 errors (`:922:2`, `:1014:12`), `ProbeB.log` 1 error (`:1063:12`), `ProbeC.log` 0 errors with `'CerbMem.reconstructValue_measure_sufficient'' depends on axioms: [propext, Classical.choice, Quot.sound]` — as §3.1–§3.3 say. **The premise holds: under `Acyclic` alone the old shape does not prove; the two leaves were the only obstacles, and (d) removes them without touching the hypothesis.**

### 2.9 Tier A on the hotfix head (scope C (g))

*Reproduced* (`.tmp/audit/gates/release-fast/`, `scripts/ce python3 scripts/release.py --mode fast --out …`, 18:54 → 19:03):
```
fast: failed; 15/16 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
FAILED A1 (230.0s)
PASSED A2 (35.4s)
PASSED A3 (51.4s)
PASSED A4 (23.4s)
PASSED A4b (24.7s)
PASSED A4c (3.1s)
PASSED A5 (24.1s)
PASSED A6 (2.3s)
PASSED A6b (3.7s)
PASSED A7 (10.6s)
PASSED A8 (8.8s)
PASSED A9 (17.1s)
PASSED A10 (17.4s)
PASSED A11 (57.9s)
PASSED A12.1 (4.8s)
PASSED A12.2 (4.4s)
```
`A1/stdout`: `1: check_handwritten_sync: OK (49 …)`, `483: Total: 12 passed, 0 failed`, `580 check_theorem_axioms: OK (…)`, `581 check_sorry_token: OK (318 files …)`, `651 check_no_fuel_numerals: OK (325 files …)`, `660 check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)`, `693 PLANT OK [P24 …]`, `697 check_fuel_forms: SELFTEST OK (25 plants …)`, `699 check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …)`, `712 check_failure_reach: OK (234 …)`, `713 check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`, `714-715` lem-sync OK / lean OK, `717-731` the fork-drift plants S1–S14 all `PLANT OK`, then
```
  PLANT FAIL [unplanted gate is not green]:
      check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=4307dc5, 'lem -v' says 38f87d5 — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately
check_fork_drift: SELFTEST FAILED (1)
test_unit: fork-drift gate SELFTEST FAILED
```
— the ENVIRONMENT (the shared switch's lem is S1.5's, the hotfix's manifest still says `4307dc5`; expected, documented in the record §4.2, clears when range 2 lands and range 3 is rebased). No other FAIL in A1. Run directly on the same tree: `check_fork_drift.sh` → ONLY that line, `EXIT=1` (the content layer is clean — no `check_fork_content: FAIL`). Lanes: A2 `SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`; A3 `total=212 match=183 ub_match=16 … cerb_skip=13`; A4 `total=90 match=66 ub_match=20 … cerb_skip=4`; A4b `total=93 match=93 …`; A4c `SUMMARY: exec_match=9 neg_pinned=5 fail=0` / `ALL AT COMMITTED EXPECTEDS`; A5 `SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED BASELINE`; A6 `total=2 match=2 fail=0` / `ALL PASSED`; A6b `total=7 match=7 fail=0`; A7 `batch diagnostic producers: 8/8 passed` / `ALL PASSED`; A8 `Success rate:   100% (of cerberus successes)` / `ALL PASSED`; A9 `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0`; A10 `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)`; A11 `total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 …` / `BASELINE OK (213 entries, exact match)`; A12.1 `EXPECT OK    18 pinned rows = 18 observed cases, every token identical` / `test_address_space: SELFTEST OK (14 plants — …)`; A12.2 `EXPECT OK    18 pinned rows …` / `test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; …)`. = the record §4.2 run 2 and the worker's `.tmp/ffc/release-fast-final/` line for line (*reproduced*, read-only); the orchestrator's `.tmp/orch/row1.log` (839 lines): `=== ROW1 EXIT=1 ===` after the same lem-pin `PLANT FAIL`, then `=== ROW 4c ===` … `ALL AT COMMITTED EXPECTEDS` / `=== ROW 4c EXIT=0 ===`, `=== ROW 12 ===` … `test_address_space: OK (18 cases …)` / `EXIT=0`, `=== ROW 2 ===` … `BASELINE OK` / `EXIT=0`. **Zero lane movement; row 1 green on every gate the slice can affect; the one red line is the environment's.**

### 2.10 Docs integrity and provenance (scope C (h), (i))

**The seam-hygiene §12 erratum**: appended after §11 (`+18` lines, nothing above changed — *reproduced* by the diff), dated `[AGENT 2026-09-20]`, names the sections whose verdicts were vacuous (§2.6, §4.4, §5.5/§5.6, §10.3), the mechanism, what stands (*"Every other line of those verdicts stands, and the slice's core claim (no behaviour change) is unaffected"*), and the repair; *"the sections above are left as written"*. **Accurate, not history-rewriting.** `VALIDATION.md`'s `check_fuel_forms.sh` row and `lean_frontend/CLAUDE.md`'s two rows describe the committed gate (option (b) wording) — the COMMITTED text is right; the record's description of it is not (M3). **Provenance:** the hotfix charter marks `[USER 2026-09-19]` (delegation) and `[USER 2026-09-08]` (quoted verbatim, character-identical to the S1.5/E-A charters and the lem-lean record: *"we should \*NOT\* be building anything new out-of-policy"*); the record's ruling line reads *"**Ruling [AGENT orchestrator 2026-09-20, under the operator's delegation, flagged to the operator]: option (d)**"* and the commit message *"Ruling [AGENT orchestrator, under the operator's delegation, flagged to the operator]: option (d)"* — no [USER] is claimed for it; the §12 erratum is `[AGENT 2026-09-20]`; the record's §3.5 analysis is labelled *"[AGENT] analysis, no recommendation is binding"*. The S1.5 record/charter and the lem-lean record cite `[USER 2026-09-19]`, `[USER 2026-09-04]` (*"we don't change the lem structure for ocaml"*, identical in all four documents that quote it), `[USER 2026-09-08]` consistently; the manifest NOTE and the lakefile trail are `[AGENT; single row + this NOTE, the S0.5 practice]`. **Consistent; no [USER]/[AGENT] confusion found.**

### 2.11 Cross-cutting (scope D)

- **[USER 2026-09-08] — no new out-of-policy surface.** lem-lean: a guard deletion, tests (kernel `decide`/`rfl` pins on concrete values, one joint stability proof in the C2 template), probes, docs. cerberus S1.5: pins, one manifest row, docs. Hotfix: a gate hardening + one plant, two def arms restated, existing proofs restored under the SAME hypothesis, three register rows, docs — no new enumeration/literal/semantics-evaluation proof, no new artefact surface. **Holds** (by reading every diff).
- **Landing order.** The two cerberus ranges are file-disjoint (header) and `git diff e283bed77 5a5579209 | git apply --check` onto the `52af8ccf1` tree → clean (*reproduced*; no commit, no tree change). After range 2 lands, the hotfix's only red row-1 line (the manifest's `lem-pin=4307dc5` vs the switch's `38f87d5`) is resolved by range 2's manifest row, so the rebased hotfix's row 1 is expected fully green — the re-gate after the rebase is the orchestrator's (not run here: N/A until the rebase exists).
- **The `build_lean` option-(b) fallback and the `common.sh` content pin.** `scripts/fork_drift_manifest.txt:423` = `100755 77f5ab3a841446962926185d3db8c0e3853fada26ff7708fdd3b47dcab0c3413 scripts/common.sh` (*reproduced*; `:346` lists it under `[files]`); the worker's discovery run shows `check_fork_content: FAIL — source-content drift inside reviewed file(s):` / `scripts/common.sh: expected ('100755', '77f5ab3a…'), actual ('100755', 'dccc9211…')` (`.tmp/ffc/release-fast/A1/stdout:718-719`); `.tmp/ffc/working-tree.patch` holds the reverted hunk (`lake build cerberus-lean` → `lake build CerberusLean cerberus-lean` with its comment). The fence reasoning is right (the manifest is on the forbidden list; a content re-pin is a deliberate manifest refresh needing review) and the follow-up is correctly scoped as two hunks — with ONE amendment (M2): its justification should name `CerbConcurrency` as the live orphan root the follow-up would cover, since the record's premise that (b) leaves "nothing else" open is false. Cost as measured by the worker (`build-all-roots-1/2.log`: `Build completed successfully (395 jobs).` 09:12:38 → 09:12:55 with 58 targets built, then 09:12:55 → 09:12:56 with 0 built) is seconds; on my primed tree the first pass rebuilt 208 targets in 53 s.

## 3. Verified clean (checked and found correct; by my own reproduction unless marked "by reading")

- Range fences: lem-lean = the 12 files of the charter's Part A fence (the `neg_fuel_mutual_lifted.lem` deletion included), `lean-lib` empty; S1.5 non-doc = the five files; hotfix = the charter's fence + the ruling's extension (`CerbMem.lean` two arms in both twins, the register via the recipe, `check_lakefile_roots.sh` one line) — nothing outside; `fuel_hypotheses.txt`, `common.sh`, `test_unit.sh` untouched.
- The lem-lean record's cited backend sites at `38f87d5` and `4307dc5` (`:1192-1201`, `:1215`, `:4440-4446`, `:4503-4508`, `:4568-4574`, `:4648-4656`, `:4738-4750`, `:4834-4870`, `:4903-4920`, `:5958-5972`) — all as described.
- The shipped `test_fuel_mutual_reader.lem` pins' arithmetic re-derived by hand (`@rping ⟨3⟩ 7 3 = 992`, `⟨4⟩ → 991`, `⟨5⟩ → 0`; `fping ⟨8⟩ 7 2 = 0` needs exactly 8 frames of `cdown 7`, `⟨7⟩ → 971`; `oping`/`opong` 7/9/1/7; `rmev`/`rmodd` on `[]`, `[1]`, `[1,2]`; `rmev_lemFuel 1 5 [1,2] = true` = the sibling's sentinel).
- The S1.5 record §4's `be1cebe36`-shaped four-file bump, the manifest NOTE's every factual clause, the record §8 errata E1/E3, §9 "exactly six files" (`git show --stat 52af8ccf1` → 6 files); `52af8ccf1`'s parent is `0f5509872`.
- The hotfix record §0's window (`fce1de9f8` 2026-09-19 01:34 → 2026-09-20), the module's last edit `49e98d9cf` (2026-09-05), the orphan `Core_unstruct_auxiliary.olean` (2026-08-25, no source), §1.1–§1.3's evidence files (`repro-F1.log` `✖ [81/81]` + the two errors; `gate-unrepaired.log` FAIL naming the module twice; `selftest.log` 28 `PLANT OK` + the row-6 `UNPLANTED` red with partition `61/13/1/6`; `build-all-roots-1/2`; `build-h2.log`), §3.6's `build-d.log` (`⚠ [253/395] Built CerbMem (1.7s)`, `✔ [336/395] Built CerbMem_lemMeasureProofs (3.0s)`, `395 jobs`, `EXIT=0`), `gate-d.log` (62/13/0/6), `failure-reach-1/2.log` — every quoted line resolves, character for character.
- The hotfix's fence arithmetic in the register (`sites=234 exec=232 …`), the `check_lakefile_roots.sh` wording change (the gate indeed builds nothing: `run_gate` compares name sets — by reading), `test_unit.sh` unchanged (the gate invoked as today).
- `handwritten_copy.manifest:64` lists the module; `lakefile.toml` lists it as a root (`:178` at the base, `:188` at `52af8ccf1` after the 10-line trail paragraph).
- At `52af8ccf1` the primed worktree's `CerbMem_lemMeasureProofs.lean` and `CerbMem.lean` are byte-identical to `e283bed77`'s (the range touches neither), so my F-1 and Probe A reproductions there are reproductions at the parent.
- Nothing in either cerberus range changes a `.lem`, a baseline, an expectation file, a pin file outside the four, or `.gitignore`.

## 4. What I did not check

- Rows 2–12 at the S1.5 head (`52af8ccf1`) were not re-run by me (the worker's `.tmp/s15/release-fast/` tails verified verbatim; the pin bump moves no Lean artefact — `lean-lib` byte-identical, the binary hash equal to S0.5's); at that head I ran the byte-identity derivations, fork-drift, lakefile-roots, lem-sync, the old fuel-forms gate and row 1 (§2.3).
- Rows 2–12 at the hotfix head WERE re-run (§2.9); Tier B was not chartered for any range and was not run.
- I did not rebuild the OCaml engine at either cerberus head (`build_cerberus`); the oracle stamps are the workers'. Tier A's lanes at the hotfix head ran against the primed `_build` (the S1.5 head's OCaml tree is byte-identical to the base by §2.2).
- The rebased hotfix (range 3 on top of range 2) does not exist yet; its row 1 is expected fully green (the lem-pin line resolves) but that is a prediction, not a measurement — the orchestrator's re-gate after the rebase.
- The lem-lean record's Part A boundary lines (`git -C deps/lem-pinned reset --hard …`, `make rebuild-lem` → `[LEM] installed Lem 38f87d5`, `lake update LemLib`'s four `info:` lines) beyond their outcomes (the pin triple, §2.3).
- The origins of the [USER 2026-09-04] and [USER 2026-09-08] quotes beyond the documents' mutual citation.
- The H3 probes B and C (I reproduced A, the ruling's premise; B/C are the priced alternatives, verified against the worker's logs only).
- cerberus-sl beyond the read-only grep of §N3 (whether their pin will move, and when, is their call; no re-pin note exists in either cerberus range for the restated arms).
- A type-punning witness for N2 (not written — outside every fence here).

## 5. Provenance

[AGENT auditor] throughout; no [USER] ruling is created or revised here. Quotations marked `[USER …]` are copied from the charters/records. All measurements 2026-09-20 ≈ 18:25–19:20 UTC in the three audit worktrees (lem-lean at `38f87d5`, `./lem` built 18:28; the scratch old lem at `4307dc5` built 18:30; cerberus S1.5 at `52af8ccf1`, regenerated 18:35–18:36; cerberus hotfix at `5a5579209`, regenerated 18:45, built 18:52–18:53, gated 18:54–19:07), box load recorded in the logs. Scratch under the worktrees' `.tmp/audit/` (git-ignored) may be deleted; the scratch git worktree `.tmp/audit/lem-4307dc5` is removed after this commit; everything this document relies on is quoted above. Nothing was pushed, merged or committed on any mainline or worker branch; `deps/lem-pinned`, the shared switch, the primary checkouts, the worker worktrees (read-only) and cerberus-sl were not touched; `make rebuild-lem` was not run; no opam command beyond a read-only `opam pin list`.
