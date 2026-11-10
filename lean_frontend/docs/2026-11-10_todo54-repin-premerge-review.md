# Pre-merge review: `arc/todo54-repin` (the lem TODO 54 re-pin), 2026-11-10

Reviewer [AGENT], independent of the worker. Under review: branch `arc/todo54-repin` at `c4a8327c8` (M1 `4d4801eae`,
M2 `aa4c9869f`, M3 `c4a8327c8`) over mainline `a5ff9d42e`; charter `docs/2026-11-10_worker-charter-todo54-repin.md`,
record `docs/2026-11-10_todo54-repin-record.md`. All runs in the branch's worktree, 2026-11-10, Lean through
`scripts/capped` at `CERB_MEM_MAX=32G`, one heavy job at a time, 1-minute load 1.5 to 3.5. The "previous generation"
is the primary checkout's on-disk trees and `.lake` build (read only, at `a5ff9d42e`, lem `e6d8db5`). Quoted machine
output is verbatim; counts labelled derived come from my own scripts (scratch, deleted), not from the worker's.

## Verdict

**No blocking finding. Mergeable after the P2 items are fixed or ruled on.** The technical substance of the re-pin
is sound and I could confirm it more strongly than the record claims: the regenerated Lean tree is reproducible from
the pinned lem, differs from the previous generation in exactly the three recorded shapes, every renamed binder is one
Lean's own linter had reported unreferenced, and all 36,226 constants of the 228 root modules (and all 5,278 of
LemLib) are unchanged up to binder names. The lane change does not open a false-green path that I could find. What is
wrong is in the record and the documents: the micro-package finding is presented as new and dated from the wrong
commits when it is an already-registered item (F1), the adopted lem range's LemLib delta is not recorded and the
consumer notes' "only" claim is overstated (F2, F3), stale prose was left in files and rows the branch itself edits
(F4, F5), and part of the new selftest does not exercise the code it says it does (F6).

## What I confirmed (not findings)

- **Pins.** `scripts/check_pin_sites.sh`: `check_pin_sites: OK — lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 at
  every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)`. `lem -v` =
  `Lem lean-backend-v0.1.0-alpha.1-88-g2220010`; `deps/lem-pinned`, the Lake package checkout and lem-lean
  `mdd/lean-backend` are all `2220010bc25f0c5682d8200f016e786ee66d65c6`; `lean-toolchain` equal in both packages.
  The adopted range `e6d8db5..2220010` is TODO 54 plus two one-line TODO log commits (`3f48fc2`, `b154377`, docs only).
- **Generated OCaml identical.** `diff -rq` of `ocaml_frontend/generated/` against the primary checkout: empty, 86
  files each side.
- **The generated Lean tree is what the pinned lem produces.** I re-ran `scripts/ce make lean-prelude-src` over a
  snapshot: rc 0, `diff -r` of the snapshot against the result empty (the tree is uncommitted, so this is what ties
  the built `.olean` files to the pin). A following `lake build CerberusLean cerberus-lean CerberusLeanTest` rebuilt
  nothing: `Build completed successfully (436 jobs).`, 0 `Built` lines, 0 warnings.
- **The delta, token level (derived, my own classifier: whole-file token streams after setting aside removed
  `termination_by structural <name>` lines, compared position by position).** 229 files each side, 52 differ, none
  added or removed; totals `{'T': 147, 'R': 601, 'I': 75}`; no other token change, no token-count change, no added
  `termination_by`. Equal to the record's table.
- **No rename can change meaning (three independent legs).** (a) For each of the 52 modules, the set of (line,
  column) positions of my 676 renamed or blanked binders EQUALS the set of positions at which the old build's stored
  Lake log carries Lean's `Variable name … is not explicitly referenced` warning, and the removed clause lines equal
  the `unused termination_by` warning lines: every renamed binder is one Lean itself resolved no reference to, so no
  reference can have been re-bound to an outer name. (b) Capture the other way: in 7 sites the new name `_x` already
  occurred elsewhere in the same file (`Annot` `_loc1`; `Cabs_to_ail` `_qs` twice; `Core_aux` `_pats`; `Core_rewrite`
  `_pe` twice; `Core_run_aux` `_cont`); read each: separate match arms whose bodies do not mention the name. (c) A
  probe importing all 228 root modules from the old and from the new build printed, per constant, the binder-name-
  insensitive hash of its type and of its value, its universe parameters, kind, safety and reducibility hint: 36,226
  lines each side, `diff` empty. The same over LemLib's 32 modules: 5,278 lines each side, `diff` empty. (A 64-bit
  hash comparison is evidence, not a kernel proof of equality.) The probe also counts 0 `axiom` constants.
- **Named arguments.** The Π-binder names of every constant's type, old against new: 180 constants differ, every
  difference of the form `x` → `_x` (four are an equation lemma's hygiene-suffixed `annot1_1` → `_annot1`). The 61
  that are source definitions are exactly the consumer notes' 61 rows with exactly their 80 parameters (compared
  mechanically, no mismatch). The other 119 are F3.
- **Warning census (derived from the `.trace` files).** Primary (before): 606 traces, 911 warnings. Worktree (after):
  root package 541 traces, speclab 83, LemLib 66 (690), 0 warnings and 0 errors; every root-package `lib/lean` trace's
  command line carries `-DwarningAsError=true`; no `.olean` without a source in the root build. Equal to the record.
- **Kernel replay.** From `lean_frontend/`, `scripts/ce ../scripts/capped lake env leanchecker <modules>`:
  the 30 owed modules (17 `*_lemMeasureProofs`, the nine proof seams, `CerbMemAccessFacts`, `CerbMemDefaultFacts`,
  `Unit.MemoryAccessProofs`, `Unit.FuelExemplar`): `leanchecker exit=0` (17 s). Negative control, a module that does
  not exist: `uncaught exception: Could not find any oleans for: NoSuchModuleXyz`, exit 1. The 52 changed generated
  modules plus the 86 `*_auxiliary` carriers (138): `leanchecker exit=0`.
- **Lane baseline.** `git diff --numstat a5ff9d42e..HEAD -- tests/inner_arg_temps/baseline.json` = `2 2`: the two
  rows `corpus/p07_list_sum`, `corpus/p08_list_reverse`; 188 rows before and after; the new hash `082663a812d6` is
  `side_hash(('RESOURCE', 'KILL|TIMEOUT'))` (recomputed), the old `8aae6f4ef8b6` that of `('RESOURCE', 'KILL')`.
- `tools/check_handwritten_sync.sh` OK (57 files); `scripts/check_lakefile_roots.sh` OK (228 roots).
- Commits: three, each ending with the required trailer; M3 documents only; nothing on a mainline.

## Findings

### F1 (P2, record integrity): the micro-package finding is not new, and its dating in the record is wrong

Record §0 (F1), §6 and the new `TODO.md` lines say `tests/mem-scale-probes/micro` was "found during this re-pin" and
argue it predates the branch because "`Micro.lean` was last edited at `537641a34` (2026-10-25), before the last
commit that touched `EnumDefs` in `CerbMem.lean` (`bb62d0017`, 2026-10-29)". Against history:

- `git log -- tests/mem-scale-probes/micro/Micro.lean`: last change `24af7239b` (2026-09-17). `537641a34`
  (2026-10-26) touched only that package's `lake-manifest.json` and `lean-toolchain`.
- `memValueToBytes`/`reconstructValue` took `EnumDefs` at `3ad477462` (2026-09-20), not `bb62d0017`.
- The item is ALREADY in `lean_frontend/TODO.md` (the entry beginning "`tests/mem-scale-probes/micro` … has not
  built since 2026-09-20 — found at the Lean 4.35 move", about 25 lines below the lines this branch adds), with the
  same five error sites, the right commits and "Needs a ruling".

The conclusion (broken on the base, not caused by the re-pin; `CerbMem.lean` and `Micro.lean` untouched on the branch,
verified) is right; the evidence given for it is not, and the branch adds a second, contradicting TODO entry and
asks the orchestrator for a decision that is already queued. Fix: correct §6 and replace the added TODO sentence by
a pointer to the existing entry. I confirm no ladder row or gate BUILDS the package: `check_pin_sites.sh` reads its
manifest, `release.py` lists its three config files as inputs, `build_provider_smoke.py` reads its manifest;
LADDER and VALIDATION list it as a Tier C instrument. (I did not rebuild the base to reproduce the error.)

### F2 (P2): the LemLib runtime changed in the adopted range and neither the record nor the notes say so

`git diff e6d8db5..2220010 -- lean-lib` in lem-lean: four binder renames in `List_extra.lean` (`head`, `tail`),
`Word.lean` (`integerFromBitSeq`), `Machine_word.lean` (`size_itself (x : itself a)` → `(_x : itself a)`), and
`moreLeanArgs := #["-DwarningAsError=true"]` on the LemLib package. The record describes the generated tree's delta
only; "No definition's type, body, name … changed" in the notes is true of LemLib too (my probe: 5,278 constants
hash-identical), but one signature parameter outside the notes' table is renamed
(`Lem_Machine_word.size_itself`, `x` → `_x`; no use in this repository), and a consumer now compiles LemLib with
warnings as errors as well. Add a paragraph to the record and one row or sentence to each note.

### F3 (P3): "only signature parameters are reachable" is overstated

The notes say named arguments reach only the 80 signature parameters. Equation lemmas, matchers and splitters bind a
definition's PATTERN variables as ∀-binders, and those are named-argument reachable too: 119 such constants already
materialised in this build changed binder names (derived: 105 `f.eq_N`, 6 `match_N`, 3 `splitter`, 5 others; e.g.
`to_pure_lemFuel.eq_7` `annot1` → `_annot1`, `unatomic.eq_2` `annots1` → `_annots1`), and a consumer generates more
on demand. The 61/80 table itself is exact. Unlikely to bite; the sentence should say "signature parameters, and
the pattern variables bound by a definition's equation lemmas".

### F4 (P2): stale current-pin prose left in public documents the slice was chartered to keep consistent

`lean_frontend/README.md:8` says "the current pin `2d3a492` is on `mdd/lean-backend`"; `lean_frontend/SUPPORTED.md:4`
says "the current pin `2d3a492` itself is PROVISIONAL — the head of the unmerged lem-lean branch". Both were already
stale (two re-pins old) and the worker reported them rather than hiding them, which is right; but M1 edits
`README.md` (line 104) and gives `lean_frontend/CLAUDE.md` the corrected sentence, and leaves the same sentence wrong
in the two documents a newcomer reads first. SUPPORTED's "provisional, unmerged" is a false statement about the
supported profile. Fix on this branch (same wording as the CLAUDE.md line) or get a ruling to defer. Related, not
this branch's: `scripts/build_provider_smoke.py:26` hard-codes `LEM_REV = 'f6542f8e…'` (a 2026-09 pin) and is not a
site `check_pin_sites.sh` knows; the fork-drift manifest's header still describes the pristine upstream tree as made
"with the SAME lem e6d8db5" (true and harmless while the generated OCaml is identical; the upstream tree was not
regenerated at `2220010`, so identity there is inferred, not measured).

### F5 (P2): the row count "186" in text M2 edits

M2 rewrites LADDER row 15 and the adjacent VALIDATION paragraph and leaves "186 rows" in both
(`scripts/LADDER.md:61`; `lean_frontend/VALIDATION.md:1423`, which the record does not list). The lane runs and the
baseline pins 188 (the gate's own line; `baseline.json` has 188 rows on the base as well). Two one-word fixes;
the per-class enumeration beside each (113 + 10 + 16 + 42 + 3 + 2 = 186) needs re-deriving from the population, not
just the total.

### F6 (P3): two of the new selftest claims are not carried by the plants (mutation-tested)

I ran `SKIP_BUILD=1 ./scripts/test_inner_arg_temps.sh --selftest` on the committed script (control: rc 0,
`SELFTEST OK (… the resource-kind plants; outcome failures)`) and on five single-edit mutants, restoring the file by
`git checkout` after each:

| Mutant | Selftest | Reading |
|---|---|---|
| `LOAD_KINDS` also contains `FUEL` | rc 1, `resource-kind plant: a KILL baseline row accepted a FUEL stop` | caught |
| `Runner.row`'s `normal_status` hashes back to `side_hash` (M2's second edit undone) | rc 0 | NOT caught |
| the kind-pinning-baseline refusal in `check_baseline` deleted | rc 0 | NOT caught |
| `baseline_class` drops the direction (`RESOURCE lean:…` spelled `RESOURCE oracle:…`) | rc 0 | NOT caught |
| `--record-baseline` writes unprojected rows | rc 0 | NOT caught |

None of the four survivors is a false-green path in the gate: the first and the last make the real lane RED (a
flake again, or a refused baseline), the refusal is redundant with the row comparison (an old-format baseline fails
either way, which is also why its plant cannot tell the two apart), and the direction stays pinned by the two side
hashes (and `RESOURCE lean` cannot reach a gate baseline at all). But the selftest comment says the plant rows "are
built by the functions `Runner.row` uses": they are built by a local helper `resource_row` that duplicates the row
assembly, so the edit in `Runner.row` that the flake fix depends on is untested, and "a kind-pinning baseline
rejected" does not test the refusal. Either route the plant through the real assembly (factor the `normal_status`
construction into a function both call) and assert the refusal's message, or soften the two claims.

### F7 (P3): what merging KILL and TIMEOUT gives up

What can now pass that used to fail: on the two `RESOURCE oracle` rows, an engine (either mode, including the Lean
side and the Normal controls) that changes from exhausting 4G to running out the 30 s clock, or back. That includes
a real behavioural change of that shape (a state-space blow-up becoming a non-allocating hang). Nothing else: a
completed observation, an Error, a crash, FUEL, a Lean-only resource outcome and a changed row set are all still red
(the first four by hash, checked by reading and by the caught mutant). Before the change the same event was red but
indistinguishable from load, so the lost signal is weak; I consider the trade right. Two notes: the pre-existing
cross-mode helper `same_failure` treats ANY two resource outcomes as equal, FUEL included, so the baseline is now
stricter than the cross-mode rule it cites; and nothing reports a row whose observed kind differs from the last
recording, so a persistent drift is silent (the row line prints the kind; an informational line would be cheap).
The record says plainly that the flake itself was not reproduced; agreed, the plants cover the comparison only.

### F8 (P3): what `-DwarningAsError=true` covers

It is a package-level `moreLeanArgs` of the root package, beside `-DautoImplicit=false`: it reaches every
`lean_lib`/`lean_exe` module of that package (generated, hand-written copies, `test/`), also when the package is
built as speclab's or a consumer's dependency, and it enters the module traces (all 257 rebuilt, confirmed). It does
NOT cover: speclab's own 36 modules (speclab's lakefile is unchanged; they have 0 stored warnings today but a new
one would not fail the build — the charter's "tests and speclab included" is met as a measurement, not as an
enforcement); `tests/mem-scale-probes/micro` (does not build); files compiled outside `lake build` by
`scripts/lean_probe.sh` (`lake setup-file` + `lean --setup`: gate decoys and ad-hoc probes) as far as I can tell
from the script, not measured; C compilation of `native/`. LemLib is covered by its own package flag at the new pin.
Suggest adding the flag to `speclab/lakefile.toml` in this slice or logging it in TODO; and the working-practices
doc should name the flag as the standing zero-warning mechanism (there is no separate gate, which is right).

### F9 (P3): smaller record points

- §2 says the pre-re-pin trees were snapshots of the worktree's primed copies; the snapshot is gone, so the record's
  classification is not reproducible from the branch alone. It is reproducible against the primary checkout until
  that is regenerated at the landing (which is how I did it); say so, or keep the classifier script in `scripts/`.
- §6 dates `537641a34` 2026-10-25; its commit date is 2026-10-26.
- The `lake env` runs print `info: LemLib: remote URL changed` (local path → GitHub URL) in the package checkout:
  harmless, a side effect of the redirect, worth knowing when reading logs.

## What I ran (last lines verbatim)

```
$ scripts/check_pin_sites.sh
check_pin_sites: OK — lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
$ scripts/ce make lean-prelude-src        (then diff -r snapshot generated/: empty)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 24f50a9239c8dd7546e609258e9935a5ed9c3cdf4c3514f4c1583f90ffc733b8, gen 39044865920c0b3a21665fbf76e802234a7d6bd3314ba23fe39ba5e270ebe1ff)
$ scripts/ce ../scripts/capped lake build CerberusLean cerberus-lean CerberusLeanTest      (lean_frontend/)
Build completed successfully (436 jobs).
$ scripts/ce ../scripts/capped lake env leanchecker <the 30 owed modules>
leanchecker exit=0
$ scripts/ce ../scripts/capped lake env leanchecker NoSuchModuleXyz
uncaught exception: Could not find any oleans for: NoSuchModuleXyz
$ scripts/ce ../scripts/capped lake env leanchecker <52 changed + 86 auxiliary>
leanchecker exit=0
$ tools/check_handwritten_sync.sh
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
$ scripts/ce scripts/check_lakefile_roots.sh
check_lakefile_roots: OK (228 roots = 228 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
$ SKIP_BUILD=1 scripts/ce ./scripts/test_inner_arg_temps.sh --selftest        (committed script)
SELFTEST OK (control; both stripped-switch stubs; Normal-only main/libc mutations; both dump/mode plants; both binder plants; printer collision; sequence/set controls; five baseline plants; the resource-kind plants; outcome failures)
```

Derived (my scripts): token classification `{'T': 147, 'R': 601, 'I': 75}` over 52 files, linter-position sets equal
in all 52; constant probes 36,226 / 36,226 and 5,278 / 5,278 lines, `diff` empty; Π-binder names changed on 180
constants (61 definitions with 80 parameters + 119 derived constants) and on 1 LemLib constant; traces 606 / 911
warnings before, 541 + 83 + 66 / 0 after.

## Not done

`scripts/release.py`, Tier A/B, `--gate` of the lane (a 6-minute run the orchestrator's battery repeats), the other
row-1 gates the record quotes (`check_fork_drift.sh`, `check_fuel_forms.sh`, `check_failure_reach.sh`,
`check_theorem_axioms.sh`, `check_exec_totality.sh`, `libc_prep.sh --check`, the CoreQuote legs): not re-run by me,
so those lines rest on the worker's record until the orchestrator's battery. `lake check` not run. The base tree
was not rebuilt; the micro package was not built. No consumer repository was built against the branch.
