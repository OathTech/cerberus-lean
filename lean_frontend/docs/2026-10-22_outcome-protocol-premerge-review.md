# Outcome protocol — fresh pre-merge review

Reviewer: [AGENT 2026-10-22, reviewer]. Candidate: `arc/outcome-protocol` at
`fb5b4d4a1` (six commits over mainline `mdd/cerberus-lean` `4d46906c9`), worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/outcome-protocol`.
Read-only review: no tracked file edited, no lake/dune/make build, no lane script,
no `release.py`, no git state change. Scratch under
`/home/dev/projects/cerberus-lean-proj/.tmp/review-op/` (delete when done).

## Verdict

**MERGEABLE WITH FIXES.** The core, the migration and the proof-contract
resolution are sound and honestly recorded; every earlier NOT READY finding is
closed as ruled. One P2 defect in the two corrected lanes (they ignore the new
decoder's `problems`, so a malformed or envelope-less stop silently becomes the
coarse `CRASH` token and can `MATCH` a pinned oracle crash) contradicts the
design's own absent-versus-malformed rule and should be fixed before the merge,
with the lanes re-run. The P3s are record/test-coverage hygiene.

## Scope and what I ran

Read, in the briefed order: the design (rev 3 + amendments), the record (A–E,
parks, dispositions, integration, close-out), the migration TSV, the charter
(rev 6), the earlier NOT READY review (`2026-10-20_outcome-protocol-v2-review.md`),
`CerbStop.lean`, `CerbStopSites.lean`, the diffs of `CerbMem.lean`,
`CerbMemAccessFacts.lean`, `Main.lean`, every other seam, `observations.py`,
`test_stops.py`, `StopTest.lean`, `ReconstructLegacyTest.lean` (declaration
level), `pnvi_lane.py`, `test_immaculate.sh`, `test_observation_lanes.py`,
`test_pnvi.sh`, the three CLI witness scripts, `test_fuel_plant.sh`,
`check_theorem_axioms.sh`, CONTRACT/VALIDATION/LADDER, both consumer notes and
the two item-G/union-init note amendments, and the six commit messages.

Commands run (from the worktree root unless stated; scratch paths abbreviated
`$R=/home/dev/projects/cerberus-lean-proj/.tmp/review-op`):

```sh
git log --oneline 4d46906c9..fb5b4d4a1; git diff 4d46906c9..fb5b4d4a1 --stat
git diff 4d46906c9..fb5b4d4a1 -- <each file above>
git diff 4d46906c9..fb5b4d4a1 -- 'lean_frontend/*.lean' 'lean_frontend/test/*' | grep -E '^\+' | grep -E 'partial |sorry|native_decide|bv_decide|set_option|nolint|implemented_by|unsafe|maxHeartbeats|maxRecDepth|ofReduce'
grep -nE 'failwithI "|failwithI s!"|failStopMem "|failStopKill "|failStopND "|panic!' lean_frontend/*.lean
python3 -I $R/check_cites2.py        # every CerbStopSites citation vs `git show b9aeedcb4dd438763b0eef7f95ac19e93875d7de:<path>`
# bridge + driver on scratch C (Defined, unspecified read, UB, two-execution memcmp, refused switches, --fuel 0, no file, --iso):
/home/dev/projects/cerberus-lean-proj/scripts/ce opam exec --switch=. -- _build/default/backend/driver/main.exe --runtime="$PWD/_build/install/default" --cabs-json $R/c/<prog>.c > $R/c/<prog>.json
LEAN_ABORT_ON_PANIC=1 NO_COLOR=1 TERM=dumb timeout 60 lean_frontend/.lake/build/bin/cerberus-lean --batch [--first] [--switches=…|--fuel 0|--iso] --runtime="$PWD/_build/install/default" $R/c/<prog>.json
python3 $R/probe_decode.py           # decode_stop on those captures; pnvi_lane.classify_side on seven edge captures
bash $R/immaculate-functions.sh …    # test_immaculate.sh's verdict/classify + common.sh is_cap_kill extracted (same method as test_observation_lanes.stop_policy_plants) on the same edge captures
# the design's mixed pure/typed program, both modes (same recipe)
LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/stop-test {"",render,refuse,invariant-cli,typed,pure,refuse-m}
PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_stops.py --lean-bin lean_frontend/.lake/build/bin/stop-test   # 21 tests OK
PYTHONDONTWRITEBYTECODE=1 python3 scripts/test_observations.py                                              # 25 tests OK
git for-each-ref refs/snapshots; git status --porcelain; cmp lean_frontend/CerbStop{,Sites}.lean lean_frontend/generated/…
git -C /home/dev/projects/cerberus-caesium diff --stat ea75d1f8e…..HEAD -- scripts/differential.py scripts/env.sh   # empty
sha256sum /usr/local/bin/capped       # c4a2cc97… = the record's E.1 hash
```

Not run (battery-owned or explicitly off-limits): `release.py`, any lane script,
`lake env leanchecker`, `#print axioms`, `test_observation_lanes.py`, the
`--consumer-demo` (it invokes `lake env lean --run`).

## Findings

### P2-1 — The two corrected lanes ignore `decoded.problems`; a malformed or envelope-less stop is silently the coarse `CRASH` token and can `MATCH` a pinned oracle crash

- **Where.** `scripts/pnvi_lane.py:126–154` (`classify_side`): `decoded.problems`
  is consulted only inside `if decoded.stops:` (:144–145). `scripts/test_immaculate.sh:96–115`
  (`verdict`): the Python hook prints only `INVARIANT` / the legacy diagnostic;
  `decoded.problems` is never read, then the pre-existing `tokens --policy immaculate`
  path (:126) maps the record to `CRASH`.
- **Claim.** Design §4.2 (lines 427–443): "A malformed reserved prefix always
  produces a problem and must not take the absent branch … an absent envelope on
  ModelFailure is a missing-envelope problem … A caller must inspect problems and
  all cause collections." The two lanes are the only callers this delivery
  corrects, and they take the absent branch for exactly these shapes. Practically:
  after C every hand-written typed kill carries an envelope, so an envelope-less
  `ModelFailure` can only be a producer regression, and the immaculate lane would
  not see it.
- **Evidence** (my harness, extracted classifier functions, oracle token `CRASH`):

  ```text
  IMMACULATE malformed-reserved-panic  LEAN_TOKEN=CRASH  -> MATCH   (no diagnostic)
  IMMACULATE malformed-reserved-model  LEAN_TOKEN=CRASH  -> MATCH   (no diagnostic)
  IMMACULATE envelope-less-model       LEAN_TOKEN=CRASH  -> MATCH   (no diagnostic)
  IMMACULATE legacy-panic              LEAN_TOKEN=CRASH  -> MATCH   + "legacy, origin unattributed" (by design)
  IMMACULATE invariant-model           LEAN_TOKEN=INVARIANT -> INVARIANT (correct)
  PNVI malformed-reserved-panic  decode: stops=0 problems=['unknown version or non-array stop'] -> ('CRASH', 'cerberus-lean stop ["2",…]')
  PNVI malformed-reserved-model  -> INVALID (by the OLD codec's batch policy, not by the new decoder)
  PNVI envelope-less-model       -> INVALID (same)
  ```

  Inputs: a LemLib panic frame whose payload is `cerberus-lean stop ["2","INVARIANT",…]`
  (exit 134, trace), `ModelFailure {msg: "cerberus-lean stop [broken"}` (exit 1),
  `ModelFailure {msg: "old message"}` (exit 1). The immaculate baseline row is
  `MATCH | L=CRASH` with no message hash, so the row stays green. In PNVI the
  BOTH_FAIL Lean-side hash pin would catch a *changed* message on a *pinned* row;
  the classifier itself still takes the absent branch.
- **Fix.** `pnvi_lane.classify_side`: after the existing resource early returns
  (to leave the documented deferred 137/124/FUEL policy untouched) and before
  `obs.parse`, add `if decoded.problems: return ('INVALID', 'stop protocol: ' + …)`
  unconditionally (not nested under `decoded.stops`). `test_immaculate.sh verdict`:
  have the Python hook also print `INVALID` when `decoded.problems` is non-empty,
  checked after the INVARIANT line and before `is_cap_kill` or, if the OOM token
  must keep precedence, immediately after it. Add the three shapes above to
  `test_observation_lanes.stop_policy_plants` as RED plants (today the matrix has
  only INVARIANT, ordinary, OOM and legacy controls). Then re-run rows 14 (PNVI)
  and B5 (immaculate) plus B9 on the fixed source: I verified that ordinary
  Defined/Undefined/Error, two-execution and CLI captures decode with zero
  problems, but I could not re-run the lanes to prove no real-row capture trips
  the stricter rule.

### P3-1 — PNVI's INVARIANT veto is plant-tested only at function level; no `test_pnvi.sh --selftest` entry-point plant

- **Where.** `scripts/test_pnvi.sh:107–127` (only the existing stubs were
  format-migrated); `scripts/test_observation_lanes.py:94–163` (the 40-pair matrix
  calls `pnvi_lane.classify_side`/`classify_row` directly; the real-lane
  `crash-invariant` plant exists for immaculate only).
- **Claim.** The record and design say "the two lane plants must make INVARIANT
  RED regardless of oracle output"; immaculate has a real entry-point plant
  (`FAIL: INVARIANT in g2-memcmp-uninit (oracle CRASH)`), PNVI does not, so a
  future refactor of the lane's row loop (e.g. one that bypasses `classify_row`
  for pinned rows) would not be caught by a plant.
- **Fix.** Add a `lean-invariant` stub to the PNVI self-test (emit a valid
  INVARIANT ModelFailure for one litmus row) and assert the lane exits RED naming
  the row.

### P3-2 — Two upstream citation ranges include a blank line; the record's "all 76 matched" holds only under containment

- **Where.** `lean_frontend/CerbStopSites.lean:235–237` (`intfrombyte`, cited
  2778–2780; line 2778 of `impl_mem.ml@b9aeedcb` is blank) and `:339–341`
  (`stepSpawnEquality`, cited 110–128; line 128 of `core_reduction.lem@b9aeedcb`
  is blank). Record §C.6: "Every excerpt was compared … at its declared range; all
  76 matched."
- **Evidence.** `check_cites2.py`: 76 citations found; 74 equal their range
  modulo indentation; the two above equal the range minus one blank line.
- **Fix.** Narrow the two ranges (2779–2780; 110–127), or state in C.6 that the
  check is "text contained in range". Cosmetic; no attribution is wrong.

### P3-3 — The producer-migration commit has no body

- **Where.** `5f8fd8d7e outcome protocol C: migrate producers; Tier A and kernel replay pass`
  (subject only; likewise `b289be2e6`). Working practice: "message states what
  was verified". The subject does name the gates, so this is minor; the record
  carries the detail. No fix needed unless the orchestrator wants the ff'd
  history self-describing (a reword before the ff would be the only way).

## Items of interest, checked

- **Kernel-compatibility contract.** `CerbMemAccessFacts.lean:122` `loadM_erasure`
  and `:150` `storeM_erasure` statements are byte-unchanged; only the proof adds
  `refuseM` to the unfold and drops unused simp arguments. `CerbMemAllocatorProofs`,
  `CerbMemDefaultFacts`, `*_lemMeasureProofs` and `Unit.FuelExemplar` are not in
  the diff (statements unchanged). The reconstruction contract is implemented as
  ruled: both references take `ReconstructionDiagnostics` first; the six
  production equations are restated at `productionDiagnostics` with all original
  quantifiers (`ReconstructLegacyTest.lean` diff lines 292–600); the historical
  instance is proved equal to private frozen copies (`historical_linear_recovers`,
  `historical_indexed_recovers`) and both are added to the axiom census. The
  consumer-facing claim is renamed in the module header, LADDER row 1,
  VALIDATION W2 and the sl note. I did not re-run `leanchecker`/`#print axioms`
  (battery-owned).
- **`refuseM` soundness.** `CerbMem.lean:2276–2283`: `refusalKill r = failwithI (render …) : kill_reason mem_error`,
  `refuseM r = ND fun s => (NDkilled (refusalKill r), s)`. Node shape and state
  are identical to the pre-migration `kill (Other (MerrOther …))` /
  `(NDkilled (Other …), st)` at all twelve sites (same `ND fun st => (NDkilled _, st)` as
  generated `kill`, `Nondeterminism.lean:402`). The kill reason changes from an
  ordinary `Other` Error (exit 1, an ordinary-looking verdict for a refused
  switch) to an opaque abort (exit 134, REFUSAL) — a strict fail-closed
  improvement and the ruled Q4. Kernel-side the reason is the `Inhabited` default
  (`Undef0 default default`, `Nondeterminism.lean:40–41`), as for every other
  `failwithI` leaf; erasure holds by reflexivity because the node does not
  depend on `s`. All twelve callers are CLI-refused switches (Z-24), so the arm is
  config-dead for the driver; in-process callers (cerberus-sl) are told in the
  note. `stop-test refuse-m` aborts at construction (134) even when only the
  constructor is matched — confirmed.
- **Is `CerbStop.render` the only thing a consumer parses?** No, and the design
  says so: the consumer also needs the outer ModelFailure escape, the LemLib
  panic header, batch framing and the two wrapper suffixes; `decode_stop`
  packages all of them. Fine for a Python consumer; a non-Python consumer would
  need to reimplement §4.1.
- **Fail-open check on legacy/unattributed.** A legacy entry requires a validated
  frame (exact header, empty stdout, exit 134, admitted tail) and is a failure
  class, never a verdict — it cannot hide a wrong answer. Both lanes print the
  "origin unattributed" diagnostic. The adjacent hole is P2-1 (malformed/absent
  envelopes are not legacy and are nevertheless coarse-CRASHed by the lanes).
- **Lane corrections plant-tested?** INVARIANT precedence over resource/status
  and the oracle: yes, 40-pair matrix on the real functions plus the real
  immaculate entry-point plant; PNVI lacks an entry-point plant (P3-1).
  Legacy ≠ SHARED_CRASH: yes (`crash-legacy` plant asserts the diagnostic and
  the absence of `SHARED_CRASH`).
- **Decoder behaviour on real captures.** Defined (exit 0, `--first` and
  exhaustive), unspecified read, single Undefined (exit 1), two-execution
  ModelFailure batch (exit 0), one/three switch refusals (empty element retained
  as item `""`), `--fuel 0`, `--iso` (boundary `switches`), usage error (exit 1 →
  one `unrecognized diagnostic` problem, no fabricated stop): all as specified,
  zero problems on every valid shape. The mixed pure/typed program reproduces
  the record exactly: `--first` → exit 1, one ModelFailure, one UPSTREAM_CRASH
  `CerbMem.memcmpByte`; exhaustive → exit 134, empty stdout, one REFUSAL
  `fs/open`, zero ModelFailures. `FUEL_RECORD` is anchored both ends, so a
  refusal detail cannot be misread as fuel by PNVI's retained merged-text search.
- **Three unmigrated raw refusals.** `CerbMem.lean:2581` (allocator alignment),
  `:3694` (memcpy overlap) and the generated `Desugaring_init.moveTo_aux` are
  the only remaining non-envelope hand-written leaves (grep). The interim class
  (legacy/unattributed) is correct: the frozen 13-boundary vocabulary has no
  honest memory-model boundary, and inventing one would change the schema. The
  movers are named consistently in the TSV header, CONTRACT D10 row, VALIDATION
  §4, both item-G/union-init notes and the Caesium family table. The register
  gate is untouched by them (both are `monadic_ascribed` buckets, as explained).
  `test_unmigrated_refusal_text_is_unattributed` covers the decoder side.
- **Verification claims.** Reproducible on this tree: the 21-test codec suite,
  the 25-test observation suite, all seven `stop-test` modes, the CLI/driver
  captures and the mixed witness (above). The installed wrapper SHA matches the
  record (`c4a2cc97…`), cerberus-sl HEAD matches (`68832d9`), and cerberus-caesium
  has moved 119 commits past the recorded `ea75d1f8` with `scripts/differential.py`
  and `scripts/env.sh` byte-unchanged, so the 36-capture demonstration still
  describes the actual consumer runner. The two C snapshot refs and the
  integration snapshot are gone as the close-out says; the worktree is clean;
  `CerbStop{,Sites}` generated copies are identical to the hand-written roots.
  Not independently re-run: Tier A 19/19, full 43/43, the 25-module replay, the
  axiom probes — the queued battery is the gate for those.
- **Overclaim scan.** The record, design, CONTRACT and both notes consistently
  say "emitted records only", "diagnostic metadata, not authentication", "no
  adoption claimed", and name the deferred items (§9) and the PNVI 137
  divergence. The one soft spot is C.6's "all 76 matched" (P3-2). The closed
  earlier findings (P1 reconstruction, P2 emitted-only, P2 capped suffix, P3 fuel
  CLI assertions) are each implemented and ruled, and `test_fuel_plant.sh:220–240`
  now checks boundary/item through the decoder as required.
- **Banned constructs.** No `partial`, `sorry`, `native_decide`, `bv_decide`,
  `set_option`, `nolint`, `implemented_by`, `unsafe`, heartbeat/recdepth bumps or
  `2>/dev/null` added in the slice (the only grep hit is a comment in
  `StopTest.lean`). `CerbTags.tagDefsUnreachable` moved from transparent `panic!`
  to the existing `failwithI` boundary as ruled. No `.lem`, Lem pin or
  `common.sh`/`capped` change.

## Residual uncertainty

- I could not run the lanes or the battery; P2-1's fix must be validated by
  re-running rows 14, B5 and B9 (my probes show ordinary captures decode clean,
  which makes a false RED unlikely but not excluded).
- Kernel replay and axiom censuses are taken from the record; the queued battery
  (A1) re-establishes the censuses, and the replay command is quoted in the
  record for the orchestrator to repeat.
- INVARIANT remains projected to coarse crash/skip classes in exec, gcc, CI and
  CN lanes (declared deferral, design §9); the merge does not make those lanes
  invariant-aware.
- The immaculate `MATCH | L=CRASH` rows carry no Lean-side message hash, so any
  future change of a Lean crash's text on those 18 rows is invisible to that
  lane by construction (pre-existing, out of this slice's scope, but it is why
  P2-1 matters there more than in PNVI).
