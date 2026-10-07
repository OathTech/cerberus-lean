# Consumer note for cerberus-sl: the PNVI-ae-udi arc (S0–S4), read before re-pinning

> **PARTLY VERIFIED / PARTLY PREDICTED — a verified scratch-build S5 follows after cerberus-sl's catch-up re-pin.**
> Every item below is marked VERIFIED or PREDICTED, with its source. Your tree at `7a2f9a2` cannot build against
> pre-PNVI mainline (Appendix A), so no edit here was checked inside your tree's own build.

From: the PNVI arc S5 worker [AGENT]. Range: branch `arc/pnvi-ae-udi` (S0–S4, review rounds and arc-end audit fixes,
head `eacb95b7a`, plus this S5 commit) over mainline `1806c5a23`.
Operator ruling for this slice, verbatim: [USER 2026-10-07] "yes, let's do (a)". Option (a) was the orchestrator's
[AGENT] recommendation: this labelled note and a `resolveIota` helper lemma land with the merge; the orchestrator
sends you a heads-up; a VERIFIED S5 scratch build follows once your tree has caught up to pre-PNVI mainline.

Your tree, as measured: cerberus-sl `7a2f9a2` (branch `s9-restart`) pins cerberus-lean `2b51d2a57` (LemLib
`38f87d5`). That is two re-pins behind mainline. All file:line cites below are at `7a2f9a2` and are under
`CerberusIris/CerberusIris/` unless the path says otherwise. They were re-checked read-only with `git grep` on
2026-10-07, and every site the S1–S3 records list is at the line those records give.

Records: design `2026-10-04_pnvi-ae-udi-design.md`; slices `2026-10-05_pnvi-s1-switch-parameter-record.md` (§9 is
the consumer draft), `2026-10-07_pnvi-s2-data-shapes-record.md` (§8, §10), `2026-10-07_pnvi-s3-arms-record.md`
(§10), `2026-10-07_pnvi-s4-lane-record.md` (§9, §11).

## 1. What changed in S0–S4, in consumer terms

- **The `[CerbGlobal.Switches]` parameter (S1).** `class CerbGlobal.Switches where switches : List CerbSwitch`. It
  is an instance-implicit binder placed immediately AFTER `[LemFuel]` on: `drive`, `driver2`, `driver2_lemFuel`,
  `driver_globals`, `drive_nonmemory_steps_aux2` (+`_lemFuel`), `process_core_step2`, `perform_memop_request2`,
  `desugar`, `translate`; `CerbMem.{allocateObject, killM, loadM, eqPtrval, nePtrval, ltPtrval, gtPtrval,
  lePtrval, gePtrval, diffPtrval, ptrfromint, intfromptr, effArrayShiftPtrval, memcpyM, memcmpM, reallocM,
  copyAllocId}`; `CerbCall.driveCall`. The `CerbND` wrapper-defeq theorems gained `(sws : CerbGlobal.Switches)`.
  Positional calls are unchanged. `@`-explicit calls need the instance argument after the fuel argument (§4).
  `CerbSwitch` gained the arm `PNVI (v : PNVIVariant)`, so a consumer `match` on it gains an arm.
- **The default-instance recipe.** The library and the generated tree declare NO instance, by design. A gate bans one
  inside this repository; it never scans your tree. Declare ONE local
  `instance : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩` in a layer module. Default-mode facts then
  elaborate as before and close by `rfl` (`@has_switch ⟨[]⟩ sw = false := rfl`). Renames:
  `CerbGlobal.switches` → `CerbGlobal.defaultSwitches`; `has_switch_eq` and the eight `has_switch_*_eq` →
  `has_switch_default`/`has_switch_nil` and the `has_switch_*_default` family; `is_PNVI_eq` → `is_PNVI_default`;
  `has_strict_pointer_arith_eq` → `has_strict_pointer_arith_default` (S1 record §9).
- **`PNVI_ae_udi` is accepted at the CLI (S4).** `--switches=PNVI_ae_udi` (both forms), alone, runs the PNVI-ae-udi
  memory model. Every other value is refused at the CLI, as is `--iso`. That covers other switch names, plain
  `PNVI`/`PNVI_ae`, mixed lists, R-PNVI-11 (an override in one list) and R-PNVI-12 (an unknown name). Without
  `--switches`, the run's instance is `⟨CerbGlobal.defaultSwitches⟩`.
- **The refusals R-PNVI-01…-12.** Some arms are ones upstream itself leaves as crashes, debug prints or self-declared
  wrong code. On the PNVI-ae-udi path these are REFUSED, never mirrored: `PNVI_ae_udi refusal (unsupported upstream
  arm): R-PNVI-nn: …`, exit 134 (`CONTRACT.md` row; S3 record §2). None is reachable at the default instance.
  R-PNVI-09 is a default-path site and stays a mirrored fail-stop (design §H.1).
- **The `reconstructValue` wrapper (S2).** `CerbMem.reconstructValue`/`reconstructValue_lemFuel` keep their names and
  types. They are now NON-recursive wrappers: `(@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel
  enumDefs ambient noOverlapping unionmap funptrmap addr ty bytes).2`. The recursion lives in
  `reconstructValueAbst(_lemFuel)` (taint × value, with the overlap closure). `loadM`'s term now carries
  `(reconstructValueAbst … (findOverlapping st) …).2` and `exposeOnLoad`. `MemState.iotaMap` is now
  `Std.TreeMap Int IotaEntry` (you mention it 0 times). Four `reconstructValue_*indexed*`/`_stable_aux` names
  left `CerbMem` (you mention them 0 times).
- **`CerbMemDefaultFacts` (theorem-only module; import it beside `CerbMem`).** It holds the bridges from S2's review
  fix F1: `reconstructValue_lemFuel_unfold` (`rfl`), `reconstructValueAbst_lemFuel_default_closure`,
  `reconstructValueAbst_lemFuel_default_snd`, `reconstructValueAbst_default_snd`, `reconstructValueAbst_snd_of_default
  (h : inst.switches = CerbGlobal.defaultSwitches)` (your instance: `h := rfl`), and
  `loadM_reconstruct_eq_reconstructValue h st …`, the exact `loadM` subterm rewritten to `reconstructValue …`.
  **New in this S5 commit:**

  ```lean
  theorem CerbMem.resolveIota_ok_of_shape (p p' : IotaPrecondFn) {s : MemState}
      (hshape : ∀ z, (p z s).toOption.map (· matches .OK) = (p' z s).toOption.map (· matches .OK))
      {iota : SymbolicStorageInstanceId} {r : StorageInstanceId × MemState}
      (h : resolveIota p iota s = .ok r) : resolveIota p' iota s = .ok r
  ```

  A successful iota resolution transfers to any precondition with the same OK / FAIL / error shape at that state.
  This is what a `Prov_symbolic` arm's location independence needs: the location reaches only the precondition's
  failure payloads. It is kernel-checked, its cone is `[propext, Classical.choice, Quot.sound]`, and it is pinned in
  `check_theorem_axioms.sh`'s mem-scale leg. In `CerbMem` itself (S3): `exposeOnLoad` (+`_default`, `_of_default`,
  `_lastUsed`), `IotaPrecondFn`, `getAllocationE`, `findOverlapping_lastUsed`, `findOverlapping_congr`,
  `resolveIota_lastUsed`, `mkIval_defaultSwitches`, `is_PNVI_defaultSwitches`.
- **No memory-operation signature change beyond the binder.** `storeM`, `allocateRegion`, `validForDerefPtrval`,
  `alignofIval`, `initial_driver_state`, `initialMemState`, `CerbND.runNDFuel`/`runND`/`runND1` and
  `fuelExhaustedKill` are unchanged, as are `MemState`'s other fields, the run digest and the enum reader. Several
  bodies changed: `killM`, `loadM`, `storeM`, `eqPtrval`, `diffPtrval`, `validForDerefPtrval`, `ptrfromint`,
  `intfromptr`, `effArrayShiftPtrval`, `combineProv`, `arrayShiftPtrval`, `casePtrval`. `loadM`/`storeM`/`killM`
  gained a `Prov_symbolic` arm with `resolveIota`, which adds `split` levels to fixed-depth chains (S3 record §10).

## 2. Default mode is bit-identical

- No `.lem` change after S1. The generated OCaml is byte-identical. Row 1's `check_lem_sync` prints the same
  generated-tree hashes in S1–S4 (S4 record §9 item 1). Fork-drift layer 2 is unchanged.
- Without `--switches`, the instance value is `CerbGlobal.defaultSwitches`, as in S1–S3 (S4 record §9 item 2).
- Every Tier A lane is at its committed baseline on each slice. That includes A9 (C→Core elaboration):
  `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0`, the five recorded DIFF rows (S1 record §7, S2
  record, S3 record §8.2, S4 record §8.2 and §9 item 3). Your C→Core corpus check should therefore not move
  [AGENT prediction; your corpus check is S5's to run].
- The inverse plant P4 shows the default lanes do see the parameter (S4 record §5.2).
- The S4 PNVI lane (`scripts/test_pnvi.sh`, LADDER row 14) covers the non-default mode. It is not evidence about
  default mode.

## 3. Catch-up debt that is NOT PNVI (your decision to make)

Your `7a2f9a2` does not build against pre-PNVI mainline `1806c5a23`. This was measured by the previous S5 attempt
(Appendix A): 25 of 210 CerberusIris modules built. The causes are mainline changes that landed after your pin
`2b51d2a57`, already announced in earlier notes. How and when to absorb them is your decision. These cites are
CARRIED OVER from that run's error lines; this run did not rebuild your tree.

| Group | Earlier note | Sites at `7a2f9a2` (failing lines) | Nature |
|---|---|---|---|
| lem `==` change (core BEq lattice) | `2026-10-04_consumer-note-cerberus-sl-lem-repin-4e70bb5.md` | `Lang.lean:178`, `EvalArms.lean:1599`, `Repr.lean:31`, `Call.lean:182` (mechanical: `beq_iff_eq`/`beq_self_eq_true`); `Env.lean:31`, `:59` (still failing after the mechanical edit) | mostly mechanical |
| SC WP0 access receipts | `2026-09-26_consumer-note-cerberus-sl-sc-wp0.md` | `MemLoc.lean:26`, `:35`; `HeapModel.lean:394`, `:418`. These lemmas need a `σ.observations = none` hypothesis threaded through ~30 files | non-mechanical |
| `lemSeq` wrapping (lem re-pin `77ad4fa`) | `2026-09-30_consumer-note-cerberus-sl-lem-repin-77ad4fa.md` | `EvalBig.lean:225`, `:234`, `:262`, `:291` | non-mechanical |

An observation from this run [AGENT]: in a probe that copies `MemLoc.lean`'s `loadM_loc_indep` against the arc
head, `recordAccess loc …` appears in the SUCCESS state. So without an observations hypothesis that theorem is
false as stated whenever capture is enabled, not merely unproved. This is the SC WP0 group, not PNVI.

## 4. The PNVI edits, per file

Status key:
- **VERIFIED (prev)**: verified by the previous S5 attempt at the arc head, carried over. No commit or log
  survives; the orchestrator's brief is the source.
- **VERIFIED (probe, this run)**: your theorem text, verbatim, plus your `ndRun` and the local instance, elaborated
  against this tree in a scratch probe. It was not elaborated inside your module, which cannot build yet.
- **PREDICTED**: taken from the S1–S3 records' consumer sections; "unverified" where the records give no edit text.

One row per cerberus-sl file:

| File | Sites at `7a2f9a2` | Status |
|---|---|---|
| `Lang.lean` | after `:77` (`open Lem_Basic_classes`): add `instance instSwitchesDefault : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩`. Without it `Lang` fails 20 ways | VERIFIED (prev) |
| `HeapModel.lean` | `:314` `simp only [reconstructValue, CerbTagsWf.envBound, reconstructValue_lemFuel]` → `simp only [reconstructValue, CerbTagsWf.envBound, reconstructValue_lemFuel, reconstructValueAbst_lemFuel]` | VERIFIED (prev) |
| `HeapModel.lean` | `:382` `simp [CerbGlobal.has_switch, CerbGlobal.switches, List.any_nil]` → `simp [CerbGlobal.has_switch, CerbGlobal.Switches.switches, CerbGlobal.defaultSwitches, List.any_nil]` | VERIFIED (prev) |
| `HeapModel.lean` | `loadM_active_nontrap` (proof `:365-397`, `:425`): after `unfold loadM`, `rw [loadM_reconstruct_eq_reconstructValue rfl, exposeOnLoad_of_default rfl]` (or `simp only` with them) before `generalize hmv : reconstructValue …`, plus S1's switch facts (S3 record §10). Entangled with the SC group at `:394`/`:418` | PREDICTED |
| `MemLoc.lean` | `:16` `killM_loc_indep` (failing at `:18`): see the before/after below; needs `import CerbMemDefaultFacts` (here or in `Lang`) | VERIFIED (probe, this run) |
| `MemLoc.lean` | `:23` `loadM_loc_indep`, `:32` `storeM_loc_indep`: their `Prov_symbolic` arms carry `resolveIota` with a `loc`-bearing precondition, so the same `resolveIota_ok_of_shape` step should apply once the SC hypothesis is in place | PREDICTED, unverified (blocked by the SC group; Appendix B) |
| `HeapModelKill.lean` | `:31` `CerbGlobal.switches` → `CerbGlobal.Switches.switches, CerbGlobal.defaultSwitches` (the same edit as `HeapModel.lean:382`) | PREDICTED |
| `Memory/Transitions.lean` | `:62`: the same edit | PREDICTED |
| `PtrEqModel.lean` | `:34` `has_switch_strict_pointer_equality … := rfl` holds under the local instance (S1 probe); `:21`, `:32` comments name `CerbGlobal.switches` → rename; `:105`, `:114`, `:121`, `:140` `@CerbMem.nePtrval inst …` → `@CerbMem.nePtrval inst _ …` (or `⟨CerbGlobal.defaultSwitches⟩`); `:35-90` (`eqPtrval_loc_indep` and four more) elaborate unchanged (S3 replica, MEASURED) | PREDICTED |
| `PrimOutcome.lean` | `:482`, `:494`, `:525`, `:555`, `:613`, `:677`, `:686` `@CerbMem.nePtrval inst …` → insert ` _` after `inst` | PREDICTED |
| `PtrEqExamples.lean` | `:94`, `:99`, `:104` `@CerbMem.nePtrval ⟨1⟩ default …` / `⟨0⟩ default …`: `default` would now be taken as the Switches argument (a type error) → `@CerbMem.nePtrval ⟨1⟩ _ default …` | PREDICTED |
| `RoundThread.lean` | `:41` (two) `@CerbMem.loadM i₁ eds …` → `@CerbMem.loadM i₁ _ eds …`; `:81`, `:82` `@CerbMem.allocateObject i₁ eds …` → `i₁ _ eds` | PREDICTED |
| `RunBuild.lean` | `:65` `@driver_globals ⟨m + 2⟩ P.enumDefs …` → `⟨m + 2⟩ _ P.enumDefs`; `:75` `@CerbMem.allocateObject ⟨m + 2⟩ …` → `⟨m + 2⟩ _ …` (`@CerbMem.alignofIval` on the same line is unchanged); `:223`, `:224` `allocateObject i₁/i₂` → `i₁ _`/`i₂ _` | PREDICTED |
| `DriverLoop.lean` | `:693`, `:886` `@driver_globals ⟨…⟩` and `:703` `@CerbMem.allocateObject ⟨m + 2⟩` → insert ` _` after the fuel argument | PREDICTED |
| `PtrRepr.lean` | `:105`, `:183`: add `reconstructValueAbst_lemFuel` to the `simp only [reconstructValue, CerbTagsWf.envBound, reconstructValue_lemFuel, …]` set (the edit verified at `HeapModel.lean:314`); where an arm consults the switch set, also `CerbMem.mkIval_defaultSwitches` / `CerbMem.is_PNVI_defaultSwitches`, possibly `ite_false`/`Bool.false_eq_true` (S2 record §8) | PREDICTED |
| `Repr.lean` | `:251`, `:506`, `:529`, `:535`, `:588`, `:743`, `:887`, `:900`: the same simp-set edit; `:887` (object-pointer arm, which also rewrites `splitBytesProv … = (p, x)`) additionally needs `CerbMem.is_PNVI_defaultSwitches`; `:836` `splitBytesProv_ptrImage` states `.1` only, so no impact is predicted; `:882` quantifies `.2` existentially, so impact is predicted only if the proof reduces the whole pair | PREDICTED |
| `UnseqReads.lean` | `:162` `loadM_result_lastUsed`: S3 replica gives `(deterministic) timeout at whnf`; adding `findOverlapping_lastUsed`/`resolveIota_lastUsed` to the 9-deep `split` chain still timed out. Restructure like `load_erasure` (`test/Unit/MemoryAccessProofs.lean`): split on the pointer first, `rw [resolveIota_lastUsed …]`, field lemmas, no blind chain (S3 record §10). No exact text exists yet. `:151` `loadM_lastUsed_only` is in the SC group | PREDICTED, unverified |
| `ExecInv.lean` | `:352` `loadM_fp_read`: elaborates unchanged (S3 replica, MEASURED) | PREDICTED (no edit) |
| `probes/2026-09-18_hidden_panic_default.lean` (repo root) | `:26` `has_switch_all … := rfl`: holds once the file sees a local instance | PREDICTED |

Counts (derived from this table): 4 VERIFIED items (3 VERIFIED (prev), 1 VERIFIED (probe, this run)) and 15 PREDICTED
rows, 3 of them marked unverified or no-edit. The `@`-explicit sites number 25 in 6 files (S1 record §9): PtrEqModel 4,
PrimOutcome 7, PtrEqExamples 3, RoundThread 4, RunBuild 4, DriverLoop 3. The `reconstructValue` simp lines number
11 (S2 record §8): `HeapModel.lean:314` (VERIFIED), `PtrRepr.lean` 2, `Repr.lean` 8. The other `@`-explicit
occurrence, `probes/capture_probe.lean:4` `#check @frontendTU`, needs no edit.

**`killM_loc_indep` (`MemLoc.lean:16-21`), VERIFIED (probe, this run).**
This is not a whole-file check of `MemLoc`.

Before:

```lean
  unfold ndRun CerbMem.killM at h ⊢
  simp only at h ⊢
  split at h <;> (try split at h) <;> (try split at h) <;> (try split at h) <;> (try split at h) <;> simp_all
```

After (plus `import CerbMemDefaultFacts`):

```lean
  unfold ndRun CerbMem.killM at h ⊢
  simp only at h ⊢
  split at h <;> (try split at h) <;> (try split at h) <;> (try split at h) <;> (try split at h) <;>
    first
    | (simp_all; done)
    | (rename_i hr _
       rw [CerbMem.resolveIota_ok_of_shape _ _ (fun z => by
             simp only [CerbMem.getAllocationE]
             cases σ.deadAllocations.contains z <;> cases σ.allocations.get? z <;> simp <;> first | rfl | (split <;> rfl)) hr]
       simp_all)
```

The probe was `.tmp/` in this worktree, now deleted. It imported `CerbMem` and `CerbMemDefaultFacts` (the built
module), restated your `ndRun` (`Lang.lean:717`), declared the local instance, and contained the theorem verbatim
with the "after" proof. It printed:

```
'CerbMem.resolveIota_ok_of_shape' depends on axioms: [propext, Classical.choice, Quot.sound]
'killM_loc_indep' depends on axioms: [propext, Classical.choice, Quot.sound]
```

With the "before" proof, the same probe fails with `error: unsolved goals` / `case h_2.isFalse`. The stuck goal is
the symbolic arm: `heq✝ : CerbMem.resolveIota (fun z s => … loc …) iota✝ σ = Except.ok (allocId✝, st1✝)` against a
goal `match CerbMem.resolveIota (fun z s => … loc' …) iota✝ σ with …`. Caveats [AGENT]:
- `rename_i hr _` depends on the hypothesis order your `split` chain produces.
- The bare `simp` in the shape proof depends on your ambient simp set.
- Both held in the probe. Your build is the check.

## 5. The declaration-change set

The changed-declaration set (frozen fingerprints whose terms now carry the instance, `reconstructValueAbst`,
`findOverlapping`, `exposeOnLoad` or the `Prov_symbolic` arms) cannot be derived until your tree builds against
the new pin. The VERIFIED S5 scratch build derives it from your freeze tooling once your catch-up re-pin has
landed. Nothing in this note is a fingerprint prediction.

## 6. Advisories

- **`partial def` is kernel-opaque.** Parts of the frontend's desugar/translate cone are `partial def` (e.g.
  `Translation.translate_expression` and five more in `generated/Translation.lean`, nine in
  `generated/Desugaring_init.lean`, as of this commit), and the kernel cannot unfold them. So "facts by `rfl` at the
  default instance" hold only through fuel'd or structural code (the memory model, the driver's fuel'd step
  functions). They never reduce through a `partial def` body. This is unchanged by PNVI, but it bounds what the
  default-instance recipe gives you.
- **The queued S5 verified run.** After your catch-up re-pin to pre-PNVI mainline, a scratch build of your tree at
  the PNVI pin will turn the PREDICTED rows of §4 into VERIFIED or corrected ones. It will also derive §5 and run
  your corpus check. Expect it as a separate note.
- **Reasoning under `PNVI_ae_udi`.** Facts under the switch are stated at `@… ⟨[.PNVI .AE_UDI]⟩`, or by binding
  `[CerbGlobal.Switches]` in a theorem as `[LemFuel]` is bound. Design §F.11 lists what this implementation does
  NOT provide for that:
  - (a) the iota map's well-formedness invariant;
  - (b) exposure monotonicity;
  - (c) a specification of `findOverlapping`, with its order-dependent truncation;
  - (d) the `msum "pointer equality"` fork, which becomes pervasive under the switch (your `PtrEqModel.lean:21-26`
    limitation);
  - (e) the state dependence of the reconstruction through the closure;
  - (f) a different Core shape under the switch.

  The R-PNVI-nn refusals are loud refusals, not semantics. A proof that reaches one proves nothing about upstream's
  arm.

## Appendix A: the previous S5 scratch build (CARRIED OVER, not observed by this run)

Source: the orchestrator's brief for this slice, summarising the earlier S5 attempt. That attempt's scratch tree
and logs were deleted; no verbatim error lines survive.

- Build: cerberus-sl `7a2f9a2` against pre-PNVI mainline `1806c5a23`.
- Result: **25 of 210** CerberusIris modules built.
- Failing roots: `CerberusIris.MemLoc`, `CerberusIris.HeapModel`, `CerberusIris.Env`, `CerberusIris.EvalBig`.
  Everything else was skipped behind them.
- Causes per file:line: the three catch-up groups of §3.

## Appendix B: this run's own observations (OBSERVED, probe-level only)

This run did NOT rebuild any part of your tree. It ran scratch probes in this worktree's `.tmp/` (deleted). Each
probe holds copies of your `MemLoc.lean` theorems (verbatim statements and proofs), your `ndRun` and the local
instance, elaborated against the arc head. So the lines below are probe-file positions, not your modules'
per-module errors.

- `killM_loc_indep` with your current proof (the instance edit only): `error: unsolved goals`, one case,
  `case h_2.isFalse` (the `Prov_symbolic` arm; §4). With the "after" proof: elaborates, cone as quoted in §4.
- `loadM_loc_indep` and `storeM_loc_indep` with your current proofs, verbatim error lines from the probe:

  ```
  ../.tmp/probe5.lean:77:79: error: unsolved goals
  ../.tmp/probe5.lean:86:87: error: unsolved goals
  ```

  These two errors carry 33 unsolved cases in total (a derived count of `case` lines). The `loadM` goals show
  `recordAccess loc LoadAccess …` in the result state (the SC group). Two of the `loadM` cases, and many `storeM`
  goals (24 `resolveIota` mentions), also contain `resolveIota` (the PNVI symbolic arm).
- One timeboxed attempt at `loadM_loc_indep` [AGENT]: add `(hobs : σ.observations = none)`, unfold `recordAccess`
  and `exposeOnLoad` in `simp_all`, and use the §4 helper step. It still left 10 failing branches, some without
  `resolveIota`. It was not pursued: the SC hypothesis threading is your decision (§3).

## Addendum (2026-10-07): a fourth catch-up group, reported by cerberus-sl [consumer statement, their DECISIONS C3.389]

cerberus-sl's own re-pin sizing found a cause group our scratch build never reached: the zero-divisor
fail-stops of `d751c12ef` (the total-arith slice) change their frozen `integer{Div,Rem}_t_eq` statements, which
gain a `b ≠ 0` hypothesis. Also from their sizing: pre-PNVI mainline `1806c5a23` is not primable by their setup
script, so their step-1 target is mainline `47348c07e` (catch-up + the S1 switches binder) and step 2 this arc;
they will absorb the SC WP0 access receipts as one heap-well-formedness clause (`σ.observations = none`). Their
sizing note: `/home/dev/projects/cerberus-sl/.tmp/orch/2026-10-07_s9-repin-sizing.md` (their tree).
