# Release-hygiene record (2026-09-02)

STATUS: worker record; branch `fix/release-hygiene`, base mainline
`90e341db2` (the post-RelSem-prune head). NOT merged, NOT pushed.
Provenance: the item rulings are [USER 2026-09-02] ("The rest all look
good as recommended"; "(7) this repo has now migrated to
OathTech/lem-lean"); the readings, wordings and gate designs are
[AGENT] (orchestrator brief + this worker), operator-overridable.
Quoted outputs are verbatim; tallies marked derived are derived.

Input: the read-only release-quality sweep of 2026-09-02 at `2c7c9347b`
(leftover reasoning-era traces, stale shop-window statements, dangling
references, fail-open `.gitignore` entries, fallen follow-ups). Every
cite below was re-located on the current tree (the prune had shifted
some line numbers). Governing standards: container CLAUDE.md working
practices; `README/DESIGN/VALIDATION/TODO.md`;
`docs/2026-08-31_semantics-first-split.md`;
`docs/2026-09-02_relsem-prune-record.md` (read first; nothing the prune
did is redone here).

## 0. Dispositions by group (one commit each)

| Group | Commit | Disposition | Gate (own) |
|---|---|---|---|
| G1 junk + .gitignore | `e4d74adf4` | `lean_frontend/.r6e`, `.r6err` deleted; `.gitignore` loses `lean_frontend/lembugs/` (bug-report home hidden from `git status` — fail-open), `/lean_frontend/docs/papers/` (dir does not exist; an ignore hides, it does not refuse), `.v2-study-scratch/` (dead container-era name) | `git check-ignore` on the three paths -> nothing (rc 1); the 2 tracked lembugs reports stay tracked; a probe file under lembugs/ shows as `??` |
| G2 restore specs | `4cef6bba3` | four park-tag notes restored VERBATIM with a 3-line provenance header (§1); every dangling `notes/` cite repointed or made self-contained | fork-drift OK; float BASELINE OK; immaculate at baseline; uri 16/16 (§1) |
| G3 shop-window truth | `977c1ac4b` | lem pin recipe (CLAUDE.md + Makefile `rebuild-lem`), ROADMAP pointer, proof-test framing, TODO prototype item deleted / A-road pointer / union-sizeof "no draft yet", README 106/106 exact statement, LADDER Tier B gcc GATE + plant rows + Tier C ci-sweep row + Instruments table, VALIDATION §2/§4, INDEX filing order incl. 17/18, gcc-lane header | `make -n rebuild-lem` parses under the env; `bash -n`; the gcc lane runs as a Tier B gate in §6 |
| G9 attribution | `f69d7854f` | `THIRD_PARTY_FILES.md` entry for `lean_frontend/native/md5.c` (§4) | n/a (docs) |
| G7 loose threads | `9bd503a9e` | TODO.md registrations (§5); trust-basket §9 closing note | n/a (docs) |
| G8 URL migration | `7d32dec14` | `lakefile.toml` + 3 `lake-manifest.json` -> `https://github.com/OathTech/lem-lean`, rev `045dcb0` unchanged; `deps/gitconfig` NOT changed (per brief) | capped `lake build` in all 3 packages resolves via the redirect; LemLib package tree sha256 before = after (§3) |
| G5 park CN-0 exporter | `b4a7cc4d6` | `--cn-spec-json` + `cn_spec_json.ml` + lane + 13 fixtures removed; `lean_export/dune` back to pre-CN-0; manifest layer-1 re-recorded surgically; design record kept with "PARKED" note | oracle rebuilt `DUNE_CACHE=disabled`; fork-drift OK (layer 1: 72 -> 71); exec minimal / cn_coverage / bytes at baseline (§2) |
| G6 .lem comment scrub | `2fb824008` | five totality-declare comments rewritten in opsem terms | both generated trees BYTE-IDENTICAL -> no layer-2 move (§2) |
| G4 reframe instruments | `25ec98d6d` | ~25 comment sites rewritten; `target_corpus.sha256` -> `fixture_corpus.sha256` (commit coherence: §7) | copy gate + Lean rebuild; Tier A `test_unit`; `test_verify` 117/117; 7 speclab lanes |
| audit response | `ee2a23bfa` | pre-merge audit F2 (lem-lean cite path reverted to `doc/notes/…`), F4 (gcc-lane load caveat, 3 places), Tier-B enforcement sentence (LADDER + VALIDATION §4); docs + one lane-header comment | `bash -n`; test_unit + fixture-freeze at the tip (§6) |
| record | (this commit) | this file | — |

## 1. G2 — the restored specs and their provenance

Ruled [USER 2026-09-02] item 1 ("restore the four park-tag spec notes —
YES"). Source: tag `park/reasoning-era-20260831`, path
`lean_frontend/docs/reasoning-era/<name>` (these were container-side
notes at the time; the park commit `39f3a64a4` is their first commit
anywhere — there is no earlier in-repo history to restore from).
Restored to `lean_frontend/docs/<name>` VERBATIM (`git show <tag>:<path>`
piped to the file) with a three-line `>` provenance header plus one
blank separator line prepended (restored-from / why / record pointer;
the body is byte-identical from line 5 on):

| Restored file | Lines (body) | Live citers (repointed) |
|---|---|---|
| `2026-08-21_fork-drift-review.md` | 372 | `scripts/check_fork_drift.sh` :3, :102, :147; `scripts/fork_drift_manifest.txt` :3 (header comment); `scripts/test_unit.sh` :128 |
| `2026-08-21_grumpy-audit-cerberus-semantics.md` | 453 | `scripts/test_immaculate.sh` :7–9 + the emitted baseline header :238; `tests/immaculate/baseline.txt` :19 |
| `2026-08-20_prototype-test-migration-survey.md` | 355 | `scripts/exec_float_baseline.txt` :5 (§4.1); `scripts/test_ci_sweep.sh` :9 (§3.4/§6 item 4) |
| `2026-08-21_upstream-oracle-build.md` | 144 | `tests/csmith_findings/README.md` :43 (two cites) |

Hash questions the brief raised, answered by reading the gates:
`check_fork_drift.sh`'s `section()` parser skips `#` lines, so the
manifest header is NOT hashed — the header cite was edited in place, no
re-record. `test_immaculate.sh` reads its baseline skipping `#` lines
(the compare loop `[[ "$name" == \#* ]] && continue`), so the baseline
comment was edited in place and identically in the script's
`--record-baseline` emitter (the two stay in sync). `test_exec.sh`
skips `#` lines when reading baselines (`:268`, `:761`).

Contradiction check (a STOP condition if any restored spec contradicted
the gate citing it) — none:
- fork-drift review §6 specifies exactly the two-layer gate as built
  (name-level manifest; hash-pinned generated diffs; refresh recipe).
  Its `[expected-cosmetic]` "strip comments then diff to empty" leg is
  documented in the gate header as verified at manifest time and
  subsumed by the hash pin at gate time — a declared implementation
  choice, not a contradiction.
- grumpy audit G1–G6 (ltPtrval/gtPtrval; memcpy/memcmp; realloc; GCC
  builtins; decode_character_constant; CoreParser hash) = the
  immaculate finding→row map exactly.
- survey §4.1 (69-file float corpus, upstream float-mul caveat) = the
  float baseline header's provenance and caveat.
- upstream-oracle-build's UB010 confirmation + caveats (a)/(b) match
  the csmith README's qualifier text verbatim in substance.

Made self-contained instead (spec lost or parked by design): the
libxml2 probe note (`notes/2026-08-19_libxml2-probe.md`) is in NO commit
(not on the park tag either) — `scripts/libxml2_prep.sh`,
`scripts/test_libxml2_uri.sh`, `tests/libxml2/config/config.h` now say
so and carry the recipe/datapoint statement themselves; the
harness-statement-template is PARKED deliberately — speclab
`Codec.lean`/`MkHarness.lean` cite it by tag path with "parked" stated;
likewise the parked lem-backend grumpy register (test_immaculate) and
the wireguard scoping note (csmith README).

Gate, verbatim (SKIP_BUILD=1 on the stamped binaries):

```
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
OK: lane matches the committed post-S1 baseline (mostly MATCH; the intended non-MATCH rows: g5-decode-question ORACLE_CRASH/L=63 and g5-escape-roundtrip DIFF/L=127 are oracle-wrong — upstream-tray #10/#11 — and g6 is TRIPWIRE).
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
```

## 2. G5 + G6 — the oracle-side changes and the fork-drift manifest

### G5 (ruled PARK, [USER 2026-09-02] item 2)

Removed: `backend/lean_export/cn_spec_json.ml`; the `cn_spec_json`
flag, its `Term` application and its branch in `backend/driver/main.ml`
(the cabs-json comment "mirrors the cn_spec_json parse-only path below"
reworded); `cerberus-lib.c_parser` from `backend/lean_export/dune`
(added by the CN-0 commit `1bd65e295` for the exporter alone; verified:
`cabs_json.ml` does not reference `C_parser`, and the dune file is now
byte-identical to its pre-CN-0 form); `scripts/test_cn_spec_export.sh`;
`tests/cn_spec_export/` (13 files). `docs/2026-08-24_cn0-spec-export.md`
kept with a one-line PARKED note; archaeology pointer = mainline
`90e341db2`. Residual references (`git grep -i -E
'cn_spec_json|cn-spec-json|cn_spec_export'` outside `lean_frontend/docs`,
`parsers/`, `ocaml_frontend/` — the latter two are upstream's own
`CN_SPEC` token / `dtree_of_cn_spec`, unrelated): only the manifest
header note and two baseline headers (`exec_ci_baseline.txt:33`,
`exec_debug_baseline.txt:20`) that cite the path as HISTORY of the
2026-09-01 cabs-json fix, each now saying the exporter was removed.

Fork-drift manifest (`scripts/fork_drift_manifest.txt`): layer-1
file-set change, one `[files]` line removed. Re-recorded SURGICALLY —
as every prior refresh on this tree was (`0780445a6`, `d0f730c25`):
the gate's `--refresh` rewrites the file with a generic 6-line header
and would drop the documented history notes. Justification is in the
header (the CN-0 note rewritten as a PARKED note). No lem-generated
module is involved, so no `[expected-*]` hash moved.

### G6 (the .lem comments) — NO layer-2 re-pin was needed

The brief anticipated (from the prune record's hazard: a free-standing
lem comment attached to a `~{ocaml}` def IS emitted into the OCaml
output) that the layer-2 hashes would move. Measured instead: the five
edited comments sit immediately above `declare {lean} …` blocks
(Lean-target-only declares), and lem emits NOTHING for them into either
target — `grep -n 'Totality declares\|call-graph escapee'` over
`ocaml_frontend/generated/*.ml` and `lean_frontend/generated/*.lean`
was already empty BEFORE the edit. Procedure and evidence:

1. Snapshot both generated trees (`cp -r` to ephemeral `.tmp/rh/`).
2. Edit the five comments (text only; no declare/def touched).
3. `make prelude-src` + `make lean-prelude-src` (stamps re-recorded by
   the recipes).
4. `diff -rq <snapshot> ocaml_frontend/generated` -> empty, `diff-rc=0`;
   `diff -rq <snapshot> lean_frontend/generated` -> empty, `diff-rc=0`.
   The lem-sync GEN hashes are unchanged (OCaml
   `295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100`,
   Lean `4b8aed263705b39285a021407028a225fc6c7edd72fac3d7f5daaa8b7b619a43`
   — NOTE (audit F3): that Lean value was taken over a generated/ tree
   primed from the primary checkout, which still carries the two retired
   files `CerbCoreInstances.lean`/`CerbInhabitedInstances.lean` (194
   files; verified in the primary at record time, same stamp value). The
   REPRODUCIBLE value after wipe-then-regenerate (`rm -rf
   lean_frontend/generated && make lean-prelude-src`, measured here) is
   `51921bc15b1ca1a69138a9cf4e41fdf9f548e3bffbbf908eb4b8e62295a6c2c3`
   over 192 files, neither retired file present; the two trees differ in
   nothing else (`diff -rq` vs the primary: only the two extra files, plus
   the G4 seam copies). The recipe is NOT fixed here — TODO.md registers
   the wipe (§5); the identity argument for G6 stands unchanged: the
   pre/post snapshots were compared directly);
   only the SRC hash moved
   (`74d6ad887e7a7941968bc64478005f73dc0878f1426c125039c8cc1cae2d8f00`
   -> `a8beac761d80bfc0f71f841eb5e67d31babab0bf6c22fbc5f1963580ee356dcf`).
5. Oracle rebuilt `DUNE_CACHE=disabled` + Lean rebuilt (binary hash
   unchanged `f8457573039f685c5d2541c3301923ffc8fc2bac784f416cf4608100ab5da367`),
   stamps re-recorded.

So the "comments-only OCaml diff" the brief asked to quote is the empty
diff: there is no OCaml text change at all, and the layer-2 pins stand
untouched. The STOP condition (any non-comment OCaml text change) did
not arise. Gate, verbatim:

```
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_lem_sync: OK (src a8beac761d80bfc0f71f841eb5e67d31babab0bf6c22fbc5f1963580ee356dcf, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: lean OK (src a8beac761d80bfc0f71f841eb5e67d31babab0bf6c22fbc5f1963580ee356dcf, gen 4b8aed263705b39285a021407028a225fc6c7edd72fac3d7f5daaa8b7b619a43)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

(G5's own gate, same shape: `check_fork_drift: OK — layer 1: 71 …`;
`cerberus --help | grep -c cn-spec-json` -> `0`; exec minimal
`BASELINE OK`; `BASELINE OK (213 entries, exact match)`;
`SUMMARY: exec_match=9 neg_pinned=5 fail=0`.)

## 3. G8 — URL migration evidence

`lakefile.toml` `git = "https://github.com/OathTech/lem-lean"` and the
`url` field of `lean_frontend/lake-manifest.json`,
`lean_frontend/speclab/lake-manifest.json`,
`tests/mem-scale-probes/micro/lake-manifest.json`; `rev` unchanged
`045dcb0d57a171eb4fb3a6eb5abe288c227270ce`. `deps/gitconfig` redirects
both spellings already (verified by reading it; NOT modified). Gate
(all capped, `CERB_MEM_MAX=32G`): `lake build` in the three packages —
root `Build completed successfully (356 jobs)`, speclab `(137 jobs)`,
micro `(134 jobs)`. LemLib package copy identity: sha256 over
`.lake/packages/LemLib` (non-`.git`, non-`.lake` files, sorted) before
= after = `abcfa6a9d4df344d1781bc2560b5e4cdcae08b39ed303063535e7e1e926a304a`;
HEAD `045dcb0d…`. Correction (audit F5): Lake did NOT rewrite the
package's configured `origin` (it is still
`https://github.com/septract/lem-lean`); `git remote -v` under the project
env DISPLAYS it as `/home/dev/projects/cerberus-lean-proj/lem-lean` because
that is what the `insteadOf` redirect does to the displayed URL —
resolution, not a config change. The Lean driver binary was unaffected (rebuilt
once because the freshness source hash covers the lakefile; identical
binary hash `f8457573039f…`).

## 4. G9 — md5.c attribution

Provenance from the file header + `git log --follow`: born in commit
`8c4fbdd8b` ("Arc 5 S2: real per-TU digests — native MD5 mirroring
Cerb_fresh/Digest"), one commit, no import. The code is a compact
single-shot RFC 1321 implementation (Wikipedia-pseudocode shape:
`g = (5*i+1) & 15` …), NOT the RSA Data Security reference code (no
`MD5_CTX`, `MD5Init/Update/Final`, `FF/GG/HH/II`, no RSA notice); the
T table and rotation amounts are the algorithm's published constants.
Entry written accordingly under this repository's BSD 2-clause LICENSE.
Nothing was unclear enough to flag.

## 5. G7 — registrations (TODO.md) and the trust-basket close

Registered with cites/movers/prices: Tier-C ci-sweep re-record (14 of
15 TSVs are the 2026-08-22 run — derived from `git log -1` per file:
`8663f1f79`/`406560515`; only `tcc.tsv` at `de574fbc8`); CerbFS
real-fs mover + served-pattern probe family (trust-basket §7 F1/F3);
clean Lake packaging (forward-assessment F4.1); the third Lake manifest
folded into the package-set-pin item; the generated-dir wipe in the
regen recipe (fail-open shape: a lingering file is stamped as
legitimate output); the lem-side "refuse a sorry target_rep"
cross-referenced to `lem-lean/doc/lean-backend/TODO.md` item 2. The
two C1-manifest/adoption-record fuel-row errata were deliberately NOT
added (fuel arc). `docs/2026-08-31_trust-basket.md` §9: the 4-row gcc
regeneration the record left UN-applied was applied as mainline
`df63018e3` (4 ins / 4 del, the exact enumerated set).

## 6. Close-out battery (Tier A + Tier B incl. the gcc lane as a gate)

Run on the final tree's freshly stamped binaries (Lean
`d96c586ec337…` after the G4 rebuild; oracle built `DUNE_CACHE=disabled`
at G6 as `5706133a948c…` — at record time the stamp check reads
`check_driver_fresh: oracle OK (bin af77833095a0…, src f441f4aebad9…)`:
same source hash, a relinked binary — `tools/gen_version.ml` embeds
`git describe --dirty` and a lane's dune invocation relinks; the
generated-tree identity + the src hash are the witness, as the prune
record noted), `SKIP_BUILD=1` (the freshness gates verify both stamps
on entry), one sequential ephemeral runner
under `.tmp/rh/` (deleted at slice end). Lane final lines verbatim:

```
test_unit:            Total: 5 passed, 0 failed … test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
test_exec minimal:    SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_exec coverage:   SUMMARY: total=199 match=174 ub_match=12 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_exec debug:      SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_exec float:      SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0 / BASELINE OK
test_bytes:           SUMMARY: exec_match=9 neg_pinned=5 fail=0 / ALL AT COMMITTED EXPECTEDS
test_libc_exec:       SUMMARY: match=7 diff=0 / ALL MATCH RECORDED BASELINE
test_multi_tu:        SUMMARY: total=2 match=2 fail=0 / ALL PASSED
test_parse:           Total: 106 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_core:            Total: 106 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_elab:            SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0  (rc 0: the recorded same/diff state)
test_libxml2_uri:     GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
test_cn_coverage:     BASELINE OK (213 entries, exact match)
test_libxml2:         SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each) / ALL PASSED
test_parse tests/ci:  Total: 250 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_core tests/ci:   Total: 250 / Success rate: 100% (of cerberus successes) / ALL PASSED
test_verify:          test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)
test_immaculate:      OK: lane matches the committed post-S1 baseline (mostly MATCH; the intended non-MATCH rows: g5-decode-question ORACLE_CRASH/L=63 and g5-escape-roundtrip DIFF/L=127 are oracle-wrong — upstream-tray #10/#11 — and g6 is TRIPWIRE).
test_speclab --selftest: test_speclab: PASS (both pipelines agree on Specified(0))
test_speclab --plant:    test_speclab: PASS (both pipelines agree on Specified(2))
test_speclab_divmod --gate:  CoreGateTest: ALL PASSED / test_speclab_divmod: PASS (--gate)
test_speclab_bytearr --gate: ByteArrGateTest: ALL PASSED / test_speclab_bytearr: PASS (--gate)
test_speclab_list --gate:    ListGateTest: ALL PASSED / test_speclab_list: PASS (--gate)
test_speclab_tree --gate:    TreeGateTest: ALL PASSED / test_speclab_tree: PASS (--gate)
test_speclab_seed --gate:    SeedGateTest: ALL PASSED / test_speclab_seed: PASS (--gate)
test_gcc_oracle --check-baseline (Tier B GATE, ruled 2026-09-02):
  SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9
  Baseline check: 0 regression(s), 0 improvement(s)
  gcc second-oracle lane OK
test_hang_plant:      test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
test_kill_plant:      test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
```

Every lane rc 0 (the runner prints `LANE FAILED: <name>` on any nonzero
rc; none printed). No baseline moved. Wall time (derived from the
runner's own timestamps): `BATTERY START 2026-09-02T20:46:39Z` ->
`BATTERY DONE 2026-09-02T21:26:43Z`, ~40 min for Tier A + Tier B
including the ~24-min gcc lane and the two plant batteries — a
standing differential battery on stamped binaries, under the ~1 h
tripwire (noted for the orchestrator; no advance justification was
needed). Tier C (ci-sweep, csmith full pass) was not run at this slice:
this slice changed no semantics (both generated trees byte-identical,
§2), and the Tier C scoreboards are registered for re-record in
TODO.md (§5).

The battery ran at tree `aab587062b6b1b72a0cb7f51eafeb228d388f71c` (=
G4's tree, unchanged by the two history re-creations in §7, verified by
`git rev-parse HEAD^{tree}`). Since then only the audit-response commit
`ee2a23bfa` and this record touched the tree: docs plus a comment-only
block in `scripts/test_gcc_oracle.sh`'s header (`bash -n` clean; no
executable line changed). Close-out at the tip (§7): `test_unit.sh` +
`check_fixture_freeze.sh` re-run green after a wipe-then-regenerate of
`lean_frontend/generated` and a Lean rebuild; the rest of the audited
battery stands on the tree-identity argument.

Close-out at the tip, verbatim (after `rm -rf lean_frontend/generated &&
make lean-prelude-src` + `build_lean`; Lean binary hash UNCHANGED
`d96c586ec3376f8f320e7f50743b73f48c93c7364fe9b380986dab12b6ae9883` —
the two retired files were never compiled into it; the generated-tree
census moves 194 -> 192 files and the ratchet scan 289 -> 287 for the
same reason):

```
check_handwritten_sync: OK (22 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
Total: 5 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: generated-tree census OK (192 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (287 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src a8beac761d80bfc0f71f841eb5e67d31babab0bf6c22fbc5f1963580ee356dcf, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: lean OK (src a8beac761d80bfc0f71f841eb5e67d31babab0bf6c22fbc5f1963580ee356dcf, gen 51921bc15b1ca1a69138a9cf4e41fdf9f548e3bffbbf908eb4b8e62295a6c2c3)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
```

## 7. Remaining reasoning-era hits (non-doc tracked files)

`git grep -n -i -E '\bslate\b|adequacy|relsem|catechism|\bOMKT\b|seal engine|space credit|boot context' -- ':!lean_frontend/docs' ':!lean_frontend/lembugs'`
at the final tree (word-bounded `slate`: the unbounded pattern matches
`translate`; word-bounded `OMKT` likewise). Every hit is a ruled keep
per the prune record's residue classes ((a) a pointer to a record's
filename, (b) a "removed 2026-09-02" note, (d) `CerbCall.lean`'s HISTORY
paragraph):

| Hit | Class | Justification |
|---|---|---|
| `lean_frontend/CLAUDE.md:30-31` | (b) | "NO second semantics package: the reasoning-era `RelSemCore` lib was removed 2026-09-02" + record/tag pointer |
| `lean_frontend/CLAUDE.md:230` | (b) | `CerbCall.lean` row: "Relocated 2026-09-02 from the removed `relsemcore/`" |
| `lean_frontend/CerbCall.lean:43-47` | (d) | the seam's HISTORY paragraph (former name, relocation, record) |
| `lean_frontend/CerbND.lean:20` | (a) | park-tag path of the Q1-amended totalization ruling's record (`…/2026-08-19_relsem-spike.md`) — rewritten in G4 to state the tag |
| `lean_frontend/DESIGN.md:143-144` | (b) | "(`RelSemCore`) was removed from mainline on 2026-09-02 … (`docs/2026-09-02_relsem-prune-record.md`)" |
| `scripts/check_theorem_axioms.sh:40-41, :507` | (b) | "2026-09-02 RelSem prune: … relsemcore/, is gone too"; "formerly lean_frontend/relsemcore/**, removed 2026-09-02" |

Zero hits for `slate`, `adequacy`, `catechism`, `OMKT`, `seal engine`,
`space credit`, `boot context`; also zero for `theorem objects`,
`check_proof_size`, and `notes/20…` (the dangling-cite pattern).
`lean_frontend/lembugs/2026-08-20_daemon-inconsistent-axiom.md` (a dated
bug record, excluded above as the prune did) still names RelSem as
history.

Commit-coherence note (two history re-creations, local only — the branch
was never pushed, so no public-visible history changed):

1. The `git mv scripts/target_corpus.sha256 scripts/fixture_corpus.sha256`
   had been staged before the G6 commit and landed there; G5/G6/G4 were
   re-created (cherry-pick, `git mv` back in G6, forward in G4, amend) so
   the rename sits in G4 where its message describes it.
2. Found by the pre-merge audit (F1, MUST): the 15 CN-0 deletions
   (`backend/lean_export/cn_spec_json.ml`, `scripts/test_cn_spec_export.sh`,
   `tests/cn_spec_export/*`) had been staged (`git rm`) before the G8
   commit and landed THERE ("19 files changed, 7 insertions, 21194
   deletions"), leaving G8's tree unbuildable (`main.ml:288: Unbound
   module Lean_export.Cn_spec_json`) and G5 touching only 6 files.
   Re-created G8 -> record from G7 `9bd503a9e`: G8 with the 15 files
   restored (`7d32dec14`, 4 files changed), G5 with the 15 deletions
   (`b4a7cc4d6`, 21 files changed), G6 `2fb824008`, G4 `25ec98d6d`;
   messages corrected. Tree identity: G4 tree
   `aab587062b6b1b72a0cb7f51eafeb228d388f71c` before = after; the record
   tip tree `ce7ab387ba732664aea8f1fcff00f533da4151b0` before = after
   (measured with `git rev-parse HEAD^{tree}` at each step). Every
   re-created commit builds — each was `git archive`d into a scratch dir,
   `make prelude-src` run there, and the oracle built
   `DUNE_CACHE=disabled dune build --root . backend/driver/main.exe`:

   ```
   ### G8 7d32dec14 (tree 9d6cd057c)   prelude-src rc=0   dune build --root . backend/driver/main.exe rc=0   (main.exe 49438672 bytes — still carries the exporter)
   ### G5 b4a7cc4d6 (tree 28b43e9ed)   prelude-src rc=0   dune build --root . backend/driver/main.exe rc=0   (main.exe 49026480 bytes)
   ### G6 2fb824008 (tree 5cd5e1a60)   prelude-src rc=0   dune build --root . backend/driver/main.exe rc=0   (main.exe 49026480 bytes)
   ### G4 25ec98d6d (tree aab587062)   prelude-src rc=0   dune build --root . backend/driver/main.exe rc=0   (main.exe 49026480 bytes)
   ```
   (`--root .` because the scratch dirs live under the worktree's
   ignored `.tmp/`, which dune would otherwise fold into the enclosing
   workspace; scratch dirs deleted at slice end.)

   The final tracked tree then moved ONLY by the audit-response commit
   `ee2a23bfa` (F2/F4/enforcement, docs + one comment block) and this
   record: tree at `ee2a23bfa` = `3800514f72eeb28dbd8c7d2aef3edf06ade4593e`; this record commit adds exactly one file on top of it.

## 8. Worktree / branch state at record time

Branch `fix/release-hygiene` off `90e341db2`, worktree
`worktrees/cerberus-lean-fix/release-hygiene`; the eleven commits listed
in §0 (nine groups + the audit response + this record). NOT merged, NOT pushed. Ephemeral runner
dirs `.tmp/rh/` and `.tmp/audit/` deleted at slice end (their logs are
quoted above). The
pre-merge audit ASK is the orchestrator's, per working practices.
