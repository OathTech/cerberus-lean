# Response to the whole-project release-gate audit (2026-09-05)

Orchestrator [AGENT] response to
[`2026-09-05_whole-project-release-gate-audit.md`](2026-09-05_whole-project-release-gate-audit.md)
(Codex [AGENT]). Sections: §1 independent verification of the audit's
premises (measured on this box, mainline `9a7f7ad31` / lem `f6542f8`);
§2 grading; §3 the operator's rulings on the four decisions the audit
raised, verbatim; §4 the resulting corrections to the master plan
(`2026-09-05_master-plan.md`, revision 2); §5 what was dispatched.

## 1. Verification of premises (orchestrator, 2026-09-05)

| Finding | Check performed | Result |
|---|---|---|
| F1 | re-ran the audit's saved binaries in `.review-evidence/2026-09-05/` | Lean: prints `1`, exit 0 under `LEAN_ABORT_ON_PANIC=1`; OCaml: `Fatal error: exception Failure("review discarded failure")`, exit 2. Mechanism confirmed at `lem-lean/lean-lib/LemLib.lean` (`failwithI` = opaque over `default`; an unused `let` zeta-reduces away). CONFIRMED |
| F2 | re-ran `scripts/check_fuel_forms.sh` with `FUELFORMS_EXTRA_MODULES=ReviewFuelDecoy` | exit 0, `83 fuel'd workers: 55 MEASURED … 14 ABSORBING`; unmodified run `81 … 54 … 13`. Source: `obligationShape` never requires the worker's non-fuel arguments to be the wrapper's binders; the ABSORBING branch inspects only the `_zero` lemma's RHS constants. CONFIRMED |
| F3 | read `scripts/test_exec.sh` extractor | `Defined {value: "…"` only; stdout/stderr fields inside Defined lines are discarded (the header already records this as Z-72). CONFIRMED (known, owed by Z4) |
| F4 | ran `scripts/check_fork_drift.sh` under `LANG=en_US.UTF-8` and under `LC_ALL=C` | OK under en_US (every battery to date ran in this locale); FAIL under C (manifest `[files]` in locale order, live list in byte order). Missing `upstream/master` ref → `exit 0` (script lines 62–70). Layer 1 is name-only for hand-written oracle files. `lem-pin=af5df71` line stale. CONFIRMED — the gate is locale-dependent and its skip is fail-open |
| F5 | `grep -rl cerberus-upstream scripts tools` | only `check_fork_drift.sh` (layer 2 tree hashes); no pristine-vs-fork EXECUTION lane exists. CONFIRMED |
| F6 | existing record `lem-lean/doc/lean-backend/2026-09-03_string-representation-design.md` + 2 XFAIL parity rows | known; priority change only |
| F7 | `CerberusImpl.lean` enum `IO.Ref`, `CerberusFresh.lean` digest, `CerbMem.lean` MemValue BEq | known (reasoning-artifact audit B/C/D/G); priority change only |
| F8 | `generated/Driver.lean:433–440` | `hack_lemFuel … : value` — PURE. The master plan §3.3 row "they are monadic/partial" was WRONG. CONFIRMED |
| F9 | `refined-cerberus/scripts/semantics-pin.env`; grep | pin `f95ef8d9c317…`; 10 `.lean` files still name `lemDefaultFuel`/`driverFuel`. CONFIRMED |
| F10 | plan-level | no measurement applicable |

Three claims in the master plan (revision 1) are falsified by the above
and corrected in §4: "stdout bytes" as a whole-line property of the main
lane; "OCaml generated tree byte-identical to upstream's lem output"
(truth: identical file set, 22 REVIEWED deltas, 11 semantic + 11
cosmetic); `hack` "monadic/partial".

## 2. Grading [AGENT]

- **F1 — MAJOR, class known, reachability from C not yet shown.** The
  typed-failure design (R2) deferred the pure-failure transform; the new
  fact is an executable demonstration that a register cannot be closure.
  Rule reading resolved by the operator (§3.1): a discarded pure
  `failwith` IS a discrepancy (kind-1).
- **F2 — MAJOR gate-strength gap, not a semantics defect.** Both decoys
  entered via the plant hook and are unreachable; production obligation
  statements are lem-generated. Fix is S. The ABSORBING label is to be
  read "kill at zero" until propagation is proved (monotonicity is the
  registered deferral, lem TODO 13).
- **F3 — confirmed, known, owed.** Instrument-first reordering accepted.
- **F4 — MAJOR by the house rules** (environment-dependent gate; fail-open
  skip). Same class as the lem `nonlean-regress` locale defect fixed
  2026-09-04. Fix is S; manifest re-sort is order-only.
- **F5 — accepted as a lane to build (M).** Its "architectural direction"
  (no shared-`.lem` changes for Lean plumbing) is already the standing
  rule; the spike to move existing reviewed shims into the backend is
  DECLINED under prune-don't-merge (the shims are reviewed and pinned).
- **F6, F7 — accepted as critical-path moves;** facts unchanged.
- **F8 — accepted;** the three-property split (no invented value /
  stability under more fuel / sufficiency) is adopted as vocabulary; the
  `hack` row is corrected.
- **F9, F10 — operator decisions;** see §3.
- Audit's own scope limits (no Tier A/B/C run, no concurrency, no
  fresh noodler) are honestly stated and accepted as such.
- Numbering note: the audit's "goals (1)–(4)" are the operator's brief to
  the auditor, not VALIDATION.md's four aims; both numberings are kept
  as written, this note is the crosswalk.

## 3. Operator rulings [USER 2026-09-05], verbatim

Asked as four decisions plus two yes/no items; answered:

> "(1) agree, the aim should be to provide the most faithful C
> semantics, per the intent of the authors, (2) unsure, this feels like
> it does touch the trust surface because it increases the gap between
> 'obviously right' and what Lean does. Is there a route where we prove
> the two are equivalent? (3) agree on the first, and the second depends
> on how the refined-cerberus project evolves, (4) I think you're right,
> the matrix may come later but for now we mostly inherit trust from
> Cerberus-upstream
>
> yes on the two other items"

Interpretation [AGENT]:

1. **F1 rule reading — kind-1.** A deliberate model `failwith` in a pure
   position that Lean discards is a discrepancy; the referent for
   faithfulness is the AUTHORS' INTENT of the C semantics, not the
   accident of any one target's evaluation order. (Supersedes any
   reading of the referent ruling under which a discarded pure failure
   is an OCaml execution artifact.)
2. **P2 pure-failure lifting — NOT authorized as proposed.** Concern: a
   generator transform widens the gap between the obviously-right mirror
   of the lem text and the Lean that runs. Question posed: a route that
   PROVES the two equivalent. Answer in the chat record and §4 item C:
   the correspondence route (mirror stays the reference; a lifted model
   sits behind a per-function kernel-checked correspondence theorem,
   the fuel-sufficiency pattern) — design note before any dispatch;
   census first.
3. **F9 — consumer adoption IS a release exit** (re-pin + proofs through
   against the current interface). C-source integration examples:
   deferred to refined-cerberus's evolution; not a cerberus-lean exit.
4. **F10 — release-profile statement: yes. Standards coverage matrix:
   later;** trust is inherited from Cerberus upstream (aim 1) for now.
5. **Yes:** land the audit verbatim (this branch) and run the P0
   instrument slice (F2 + F3 + F4).

## 4. Master plan revision 2 (deltas to `2026-09-05_master-plan.md`)

Corrections (errors of fact):
- §0 "whole-line verdicts incl. UB location, stderr, stdout bytes" →
  whole-line UB verdicts incl. location and stderr (Z1 lanes); stdout
  bytes are compared in the bytes/csmith/gcc lanes ONLY; the main lane's
  Defined lines compare the value token (Z-72, F3).
- §0 "OCaml generated tree byte-identical to upstream's lem output" →
  identical FILE SET; 22 reviewed content deltas (11 expected-semantic,
  11 expected-cosmetic), hash-pinned.
- §3.3 `hack`/`many`/`many1` row → `hack : … → value` and its caller
  `finalize : … → driver_result` are PURE; `many`/`many1` are parser
  combinators, also pure-typed. Route: F1's correspondence route or a
  checked precondition; NOT a monadic `failure_outcome`.

Sequencing (replaces §5):
1. **P0 instruments** (dispatched, §5): F4 locale + fail-open + order-only
   manifest re-sort + stale metadata; F2 checker (positional argument
   correspondence, `_zero` LHS check, axiom cones on absorbing lemmas,
   the two decoys + the audit's listed plants); F3 Defined-line widening
   with plants, affected-baseline re-record in a dedicated commit, every
   newly exposed row triaged as a finding.
2. **Risk map baseline NOW** (independent auditor), repeated after the
   surgery. Release-profile statement written alongside it (one
   contract: supported / refused / upstream defect / open port bug).
3. **Census (S)**: pure `failwith`/`failwithI` sites on the exec cone in
   discardable positions (unused lets, unused arguments, tuple
   components, ignored results). Output decides F1's blocker status.
4. **C: correspondence design note** for pure failure (if the census is
   non-empty) — the mirror `f` stays the reference model; a lifted
   `f_exc : … → Except Failure α` is generated alongside; per-function
   theorem `f_exc xs = .ok v → f xs = v` (kernel-checked, generated
   statement, proof by a generic homomorphism tactic with hand fallback,
   exactly the fuel-sufficiency pattern); the failure direction is
   differential-tested against OCaml (it is not statable in the mirror).
   Reviewed WITH the operator before dispatch; it also fixes the
   failure family of the lem declare consolidation (L1), so L1's
   vocabulary freezes after it.
5. **L1 consolidation** (lem) ∥ **C-TF1 monadic seam slice** (cerberus),
   both after item 4's note.
6. **F5 lane (M)**: pristine `deps/cerberus-upstream` binary vs fork
   oracle over the Tier A corpora; content-pin the hand-written oracle
   deltas.
7. **C-Z4 remainder**, F6 exposure trace (cerberus side, S) + L4 (lem),
   F7 instances (C-B, C-C, digest) on the critical path.
8. **Consumer adoption exit (F9)**: refined-cerberus re-pin + proofs
   through; their C-source scope is theirs.
9. **Risk map (repeat) → fresh noodler → stable-profile claim.**

Stable definition (§1) amended: add "the release profile is written and
every row in it has evidence; the consumer's re-pin is green" and drop
"lem declares consolidated" as a stability criterion (it is an upstream-
submission criterion, L7).

## 5. Dispatched

- P0 instrument slice: worker on `arc/p0-instruments` (worktree
  `worktrees/cerberus-lean-arc/p0-instruments`), off `9a7f7ad31`.
  Boundary: no semantics, no `.lem`, no baseline movement except the F3
  re-record in its own commit with per-row triage.
- Ephemeral: `.review-evidence/2026-09-05/` (6.8 MB of the audit's
  scratch, container root) is deleted once this branch is merged; the
  durable evidence is the committed directory.
