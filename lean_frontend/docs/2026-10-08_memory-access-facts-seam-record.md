# The memory-access-facts seam: SC WP0 erasure lemmas as a citable library module — slice record (2026-10-08)

Branch `seam/memory-access-facts`, from mainline `fd110ea30`. Worker: Claude Opus 5.5 (agent). Every
judgement no operator quote covers is marked [AGENT]. Quoted gate output is verbatim; counts marked
"derived" are mine. No `.lem`, generated code or semantics changed; the lem used is the pin `4e70bb5`.

Commits: the seam (with this record), then the register signature transcription (§5) as a separate commit.

## 0. Provenance

- Consumer ask (c) from cerberus-sl (their record: DECISIONS C3.399): they restate the SC WP0 access receipts
  as one heap-well-formedness clause, `quiet : σ.observations = none`, and want to cite our load/store erasure
  lemmas by name instead of re-deriving them. Queued in the landing note `fd110ea30` ("promote the load/store
  erasure lemmas to a citable library seam (their ask (c))").
- Operator: [USER 2026-10-08] "Yes go ahead".

## 1. What moved

The lemmas lived in `test/Unit/MemoryAccessProofs.lean`, a test module a consumer cannot import. They now
live in the theorem-only seam `lean_frontend/CerbMemAccessFacts.lean` (module `CerbMemAccessFacts`, namespace
`CerbMem`), on the `CerbMemDefaultFacts` precedent: no `def`, kernel-only tactics, no option bumps, a
documented header listing the exported names. It imports `CerbMem` and `CerbFailProofs` (the latter for
`CerbFail.step`).

| Seam name (`CerbMem.`) | Old test name | Statement (one line) |
|---|---|---|
| `loadM_erasure` | `load_erasure` | `((step (loadM es ts l t p) s).1, stopObserving (step (loadM es ts l t p) s).2) = step (loadM es ts l t p) (stopObserving s)` |
| `storeM_erasure` | `store_erasure` | the same for `storeM es ts l t locking p v` |
| `stopObserving_recordAccess` | `stop_recordAccess` | `stopObserving (recordAccess … s) = stopObserving s` |
| `recordAccess_stopObserving` | `disabled_recordAccess` | `recordAccess … (stopObserving s) = stopObserving s` |
| `recordAccess_of_observations_none` | `recordAccess_off` | `s.observations = none → recordAccess … s = s` |
| `stopObserving_lastUsed` | `stop_lastUsed` | `stopObserving { s with lastUsed := u } = { stopObserving s with lastUsed := u }` |
| `stopObserving_observations` | `stop_obs` | `(stopObserving s).observations = none` |
| `stopObserving_deadAllocations` | `stop_dead` | `(stopObserving s).deadAllocations = s.deadAllocations` |
| `stopObserving_allocations` | `stop_allocs` | `(stopObserving s).allocations = s.allocations` |
| `stopObserving_bytemap` | `stop_bytemap` | `(stopObserving s).bytemap = s.bytemap` |
| `stopObserving_lastUsedUnionMembers` | `stop_union` | `(stopObserving s).lastUsedUnionMembers = s.lastUsedUnionMembers` |
| `stopObserving_funptrmap` | `stop_funptr` | `(stopObserving s).funptrmap = s.funptrmap` |
| `findOverlapping_stopObserving` | `stop_fo` | `findOverlapping (stopObserving s) = findOverlapping s` |
| `stopObserving_exposeOnLoad` | `stop_exposeOnLoad` | `stopObserving (exposeOnLoad t s) = exposeOnLoad t (stopObserving s)` |
| `exposeOnLoad_observations` | `exposeOnLoad_obs` | `(exposeOnLoad t s).observations = s.observations` |
| `resolveIota_stopObserving` | `stop_resolve` | for `p` blind to the buffer, `resolveIota p iota (stopObserving s)` = the result on `s` with its state erased |
| `liftND_returned_state` | `lift_returned_state` | `(step (liftND_lemFuel (n + 1) get put info err m) s).2 = put s (step m (get s)).2` |

[AGENT] Naming: `<primitive>_erasure` for the two main facts; `stopObserving_<field>` / `<op>_stopObserving`
for the lemmas, following Mathlib's `f_g` convention for "f applied to g". `liftND_returned_state` sits in
`CerbMem` too, so one namespace covers all of it, although it is generic over `liftND`.

[AGENT] I moved all 17 theorems, not a subset. The two erasure proofs use 13 of the others as simp lemmas.
The consumer named every one of them. The only `def` in the old module, `eraseNode`, stays in the test,
because a seam has no `def`s.

## 2. Statement identity (evidence)

Two independent checks.

1. **Kernel.** The test module keeps every old name with its old statement TEXT. Each one is now proved by
   the seam theorem's term (e.g. `theorem load_erasure … := CerbMem.loadM_erasure es ts l t p s`). The kernel
   accepts each proof, so each old statement is definitionally the seam statement (`memory-access-test`
   builds green in row 1, §4).
2. **Text.** `.tmp/stmts.py` (scratch, deleted) took every `theorem … :=` statement from the pre-move file
   (`git show fd110ea30:lean_frontend/test/Unit/MemoryAccessProofs.lean`) and from the seam,
   whitespace-normalised, and applied the rename map. Its one allowed rewrite was
   `eraseNode (X)` → `((X).1, stopObserving (X).2)`, which is the body of `eraseNode`. Output (verbatim):

   ```
   IDENTICAL loadM_erasure
   IDENTICAL storeM_erasure
   IDENTICAL stopObserving_recordAccess
   IDENTICAL recordAccess_stopObserving
   IDENTICAL recordAccess_of_observations_none
   IDENTICAL stopObserving_lastUsed
   IDENTICAL stopObserving_observations
   IDENTICAL stopObserving_deadAllocations
   IDENTICAL stopObserving_allocations
   IDENTICAL stopObserving_bytemap
   IDENTICAL stopObserving_lastUsedUnionMembers
   IDENTICAL stopObserving_funptrmap
   IDENTICAL findOverlapping_stopObserving
   IDENTICAL stopObserving_exposeOnLoad
   IDENTICAL exposeOnLoad_observations
   IDENTICAL resolveIota_stopObserving
   IDENTICAL liftND_returned_state
   17 17
   ```

   The same comparison between the old and new test module, without renaming: `True 17 / 17 test statements
   textually identical (whitespace-normalised)`. The raw diff of the two main statements is the only textual
   change (verbatim `diff` output):

   ```
   < theorem load_erasure [LemFuel] [CerbGlobal.Switches] (es ts l t p s) :
   <     eraseNode (step (loadM es ts l t p) s) =
   ---
   > theorem loadM_erasure [LemFuel] [CerbGlobal.Switches] (es ts l t p s) :
   >     ((step (loadM es ts l t p) s).1, stopObserving (step (loadM es ts l t p) s).2) =
   ```
   ```
   < theorem store_erasure [LemFuel] (es ts l t locking p v s) :
   <     eraseNode (step (storeM es ts l t locking p v) s) =
   ---
   > theorem storeM_erasure [LemFuel] (es ts l t locking p v s) :
   >     ((step (storeM es ts l t locking p v) s).1, stopObserving (step (storeM es ts l t locking p v) s).2) =
   ```

The proof scripts moved unchanged, apart from the renamed lemma names in their simp sets. The old
`unfold eraseNode` step is dropped, because the seam statement is already unfolded. The old proofs produce
the same goal after that step. The unused-simp-argument linter warnings (10) come with the scripts.
[AGENT] I left them as they are so the move stays a pure move.

## 3. Wiring

- `handwritten_copy.manifest`: `CerbMemAccessFacts.lean` (after `CerbMemDefaultFacts.lean`); the copy is in
  `generated/` via `make lean-prelude-src`.
- `lakefile.toml`: a Lake root next to `CerbMemDefaultFacts`, as the precedent is.
- Row 1 compiles it: `Unit.MemoryAccessProofs` imports it, and `memory-access-test` (in `test_unit.sh`'s list)
  imports that module.
- `scripts/check_theorem_axioms.sh` mem-scale leg: all 17 names are pinned next to the `CerbMemDefaultFacts`
  pins, and the probe imports `CerbMemAccessFacts`. The leg's existing fail-closed check (exactly one probe
  line per name) and its exact allowlist `[propext, Classical.choice, Quot.sound]` are unchanged. The count
  went from 18 to 35 (derived: 18 + 17).
- W2 (`check_no_fuel_numerals.sh`) is unchanged: the seam names no `reconstructValue` wrapper.
- [AGENT] `scripts/test_memory_access.py` (row 13) now also hashes `lean_frontend/CerbMemAccessFacts.lean` in
  its report's `sources` provenance. The proofs that row cites now live there. This is a provenance list
  only; no verdict logic changed. Row 13 was not run (Tier A not required by the brief); it was
  syntax-checked with `py_compile`.
- Docs: `lean_frontend/CLAUDE.md` has a key-files row and an amended `memory-access-test` entry.
  `VALIDATION.md` row 13's description now names the seam. `scripts/LADDER.md` row 1 names the seam and the
  new cones. [AGENT] `VALIDATION.md` mentions `CerbMemDefaultFacts` only in W2's exclusion, and this seam is
  not excluded. `CONTRACT.md` does not mention `CerbMemDefaultFacts`, so neither file needed any other
  mention.

## 4. Gates (verbatim)

The worktree's primed `generated/` trees were stale against mainline. The first row-1 run failed only at
the lem-sync gate (`CERB_LEM_SYNC_STALE: ocaml_frontend/generated/ is not content-in-sync …`). That run's
seam pins were green; the failure came from priming, not from this change. I re-derived both trees, which
touches only the worktree: `make lean-prelude-src`, then `make clean-prelude-src prelude-src`. Then I rebuilt
the OCaml side per the README (`dune build backend/driver/main.exe cerberus-lib.install`, worktree-local
`dune install`, `dune build cerberus.install`).

Capped full Lean build (`cd lean_frontend && ../scripts/capped lake build`):
```
Build completed successfully (399 jobs).
```

Row 1 (`./scripts/test_unit.sh`, second run, rc=0):
```
check_handwritten_sync: OK (51 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
✓ memory-access-test PASSED
Total: 18 passed, 0 failed
'CerbMem.loadM_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.storeM_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_recordAccess' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.recordAccess_stopObserving' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.recordAccess_of_observations_none' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_lastUsed' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_observations' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_deadAllocations' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_allocations' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_bytemap' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_lastUsedUnionMembers' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_funptrmap' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.findOverlapping_stopObserving' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.stopObserving_exposeOnLoad' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.exposeOnLoad_observations' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.resolveIota_stopObserving' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.liftND_returned_state' depends on axioms: [propext]
check_theorem_axioms: mem-scale S1 leg OK (35 C1/C3 + PNVI-S2 wrapper equality + CerbMemDefaultFacts bridge + CerbMemAccessFacts erasure theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
```

Note: the rfl field lemmas report the full three-axiom cone. `#print axioms` collects through the
constants in the statement (`MemState`'s field types), not through the proof alone.

`./scripts/check_fuel_forms.sh` (after §5's edit, rc=0):
```
check_fuel_forms: OK (81 fuel'd workers: 63 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 5 ambient unreachable from the drive cone)
```

Not run: Tier A, as the brief allows. The change is theorem-only plus a test import, and default semantics
are untouched. [AGENT] No new plant on the axiom pins. The per-name fail-closed check is the leg's existing
mechanism, and I did not modify it; the new names only extend its list.

## 5. Housekeeping: `scripts/fuel_hypotheses.txt` rows 6–7 (separate commit)

The register's header said rows 6 (`CerbMem.reconstructValue_lemFuel`) and 7
(`CerbMem.reconstructValueAbst_lemFuel`) were waiting for the PNVI arc's audit signature. The arc-end auditor
gave it, as recorded in the mainline landing note `fd110ea30` (verbatim): "the auditor 'would sign both'
scripts/fuel_hypotheses.txt rows 6-7 — recorded here as the auditor signature for those rows".

Change, signature text only:
- The header's PENDING block now records the signature and quotes the landing note.
- Row 6's reviewer field keeps the 2026-09-05 signature, now marked as covering the pre-S2 proof. It adds
  `[AGENT auditor, PNVI arc-end audit 47348c07e..b4e7a136f; recorded in landing note fd110ea30, 2026-10-07]
  SIGNED (the S2-restated proof)`.
- Row 7's reviewer field adds the same signature before `[USER] sign-off at merge`.

That follows the register's convention (`[AGENT auditor <date>, audit <ref>] SIGNED; [USER] sign-off at
merge`) and its procedure: the auditor signs, and the operator's merge "yes" is the final signature
([USER 2026-10-07] "Go ahead and merge, agree re (2)", the same landing note). The worker transcribes; it
does not sign. No worker, hypothesis or invariant field changed; `check_fuel_forms.sh` is green (§4).
