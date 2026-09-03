# FUEL arc — consumer change manifest (for refined-cerberus / cerberus-heaplang)

Date: 2026-09-03. Branch `arc/fuel`. Design: `docs/2026-09-02_fuel-arc-design.md`
(R3; Option C [USER 2026-09-02]); consumer review on record:
`refined-cerberus/worktrees/fuel-design-review/docs/2026-09-02_review-of-cerberus-lean-fuel-arc-design.md`
(ACCEPT + R1-R3). Arc record: `docs/2026-09-03_fuel-arc-record.md`.

This manifest is what the re-pin carries. Every name below is in the
tree at the commit it cites; every statement is quoted from the source
(binder names included). Two commits: **1 = mechanism** (budget
unchanged at the library default), **2 = budget** (`driverFuel` = 10^8
on the coupled driver family). Section 4 states the side condition per
commit.

## 1. Names

| Name | Kind | Where |
|---|---|---|
| `CerbFuel.fuelExhaustedLoc` | `opaque … : CerbLocation.Loc := CerbLocation.Loc.other "lem: fuel exhausted"` — pure, value-carrying, NO `unsafe`/`implemented_by`/`extern`; boundary-opaque census row | `lean_frontend/CerbFuel.lean:42` |
| `CerbFuel.fuelExhaustedMsg` | `def … : String := "lem: fuel exhausted"` — REPORTING-ONLY | `CerbFuel.lean:49` |
| `CerbFuel.driverFuel` | `def … : Nat` — the coupled driver family's budget; the citable side-condition constant (§4) | `CerbFuel.lean:67` |
| `CerbND.fuelExhaustedKill` | `def fuelExhaustedKill {err : Type} : kill_reason err := Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg` | `lean_frontend/CerbND.lean:80` |
| `CerbND.ndDefaultFuel` | `:= CerbFuel.driverFuel` (the runners' budget) | `CerbND.lean:85` |
| `CerbND.drive_lemFuel` | the fuel-parametric shipped pipeline (§3) | `CerbND.lean:446` |
| `CerbND` re-exports | `export CerbFuel (fuelExhaustedLoc fuelExhaustedMsg driverFuel)` — one namespace for the consumer | `CerbND.lean:70` |

The generated fuel-zero arms (nine, Nondeterminism.lean:190/308/311,
Driver.lean:232/347/382, Defacto_memory.lean:806/821/900) read
`| 0 => (ND (fun st => (NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), st)))`
(liftAction: `(fun _ => NDkilled (Error0 …))`; drive_nonmemory_steps_aux2:
`(fun _ => ND (fun st => …))`) — no opaque wrapper. The runner leaves
(`CerbND.runNDFuel`/`runND1Fuel`/`runND1TraceFuel`, fuel 0) are
`[(Killed st0 fuelExhaustedKill, [], st0)]` (trace variant: `([], [...])`).
The former `panic!`-returning-`[]` runner marker is gone.

## 2. Shipped lemmas (all `rfl` unless stated; all in `namespace CerbND`, `lean_frontend/CerbND.lean`)

Binder names are the GENERATED ones (the reader argument is
`_lemReader_tagDefs`, `nd_bind`'s arguments `n`/`f1`, the lifts'
`get2`/`put1`/`liftInfo`/`liftErr`, `find_array_index`'s `ival_`,
`easy_update_mem_value_aux`'s `loc1`), so the statements apply positionally
to the generated workers as they are.

```lean
theorem nd_bind_lemFuel_zero {a b c d e f : Type} (n : ndM f b d a c) (f1 : f → ndM e b d a c) :
    nd_bind_lemFuel 0 n f1 = ND (fun st => (NDkilled fuelExhaustedKill, st))
theorem liftND_lemFuel_zero {a cs err1 err2 info1 info2 st1 st2 : Type}
    (get2 : st2 → st1) (put1 : st2 → st1 → st2) (liftInfo : info1 → info2)
    (liftErr : err1 → err2) (n : ndM a info1 err1 cs st1) :
    liftND_lemFuel 0 get2 put1 liftInfo liftErr n = ND (fun st => (NDkilled fuelExhaustedKill, st))
theorem liftAction_lemFuel_zero {a cs err1 err2 info1 info2 st1 st2 : Type}
    (get2 : st2 → st1) (put1 : st2 → st1 → st2) (liftInfo : info1 → info2)
    (liftErr : err1 → err2) (act : nd_action a info1 err1 cs st1) :
    liftAction_lemFuel 0 get2 put1 liftInfo liftErr act = NDkilled fuelExhaustedKill
theorem print_eval_conv_aux_lemFuel_zero (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (dr_st : driver_state) (th_st : thread_state) (pe : generic_pexpr Unit sym) :
    print_eval_conv_aux_lemFuel 0 _lemReader_tagDefs dr_st th_st pe = ND (fun st => (NDkilled fuelExhaustedKill, st))
theorem drive_nonmemory_steps_aux2_lemFuel_zero (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (acc : Fmap thread_id (List core_step2)) (xs : List Nat) :
    drive_nonmemory_steps_aux2_lemFuel 0 _lemReader_tagDefs acc xs = ND (fun st => (NDkilled fuelExhaustedKill, st))
theorem driver2_lemFuel_zero (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) (with_concurrency : Bool) :
    driver2_lemFuel 0 _lemReader_tagDefs with_concurrency = ND (fun st => (NDkilled fuelExhaustedKill, st))
theorem find_array_index_lemFuel_zero (size : Nat) (i : Nat) (ival_ : integer_value_base) :
    find_array_index_lemFuel 0 size i ival_ = ND (fun st => (NDkilled fuelExhaustedKill, st))
theorem easy_update_mem_value_aux_lemFuel_zero (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (loc1 : CerbLocation.Loc) (is_strong : Bool) (write_ty : ctype) (sh : List shift_path_element)
    (write_mval : impl_mem_value) (current_mval : impl_mem_value) :
    easy_update_mem_value_aux_lemFuel 0 _lemReader_tagDefs loc1 is_strong write_ty sh write_mval current_mval
      = ND (fun st => (NDkilled fuelExhaustedKill, st))
theorem memcmp_load_aux_lemFuel_zero (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (ptrval : impl_pointer_value) (offset : Int) (max_offset : Int) (acc : List impl_mem_value) :
    memcmp_load_aux_lemFuel 0 _lemReader_tagDefs ptrval offset max_offset acc = ND (fun st => (NDkilled fuelExhaustedKill, st))

theorem runNDFuel_zero {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runNDFuel 0 m st0 = [(Killed st0 fuelExhaustedKill, [], st0)]
theorem runND1Fuel_zero {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runND1Fuel 0 m st0 = [(Killed st0 fuelExhaustedKill, [], st0)]
theorem runND1TraceFuel_zero {a info err cs st : Type} (showInfo : info → String) (m : ndM a info err cs st) (st0 : st) :
    runND1TraceFuel showInfo 0 m st0 = ([], [(Killed st0 fuelExhaustedKill, [], st0)])

-- constructor disjointness ONLY — NOT distinctness from a genuine `Error0 loc msg` (none ships; design note §1.3)
theorem fuelExhaustedKill_ne_Undef0 {err : Type} (loc : CerbLocation.Loc) (ubs : List undefined_behaviour) :
    (fuelExhaustedKill : kill_reason err) ≠ Undef0 loc ubs            -- by intro h; cases h
theorem fuelExhaustedKill_ne_Other {err : Type} (e : err) :
    (fuelExhaustedKill : kill_reason err) ≠ Other e                   -- by intro h; cases h

-- wrappers pinned to the budget constant
theorem driverFuel_eq : CerbFuel.driverFuel = 100000000               -- commit 2 (commit 1 carried 1000000)
theorem driver2_wrapper_defeq : driver2 = driver2_lemFuel CerbFuel.driverFuel
theorem print_eval_conv_aux_wrapper_defeq : print_eval_conv_aux = print_eval_conv_aux_lemFuel CerbFuel.driverFuel
theorem drive_nonmemory_steps_aux2_wrapper_defeq : drive_nonmemory_steps_aux2 = drive_nonmemory_steps_aux2_lemFuel CerbFuel.driverFuel
theorem hack_wrapper_defeq : hack = hack_lemFuel CerbFuel.driverFuel
theorem nd_bind_wrapper_defeq {a b c d e f : Type} (n : ndM f b d a c) (f1 : f → ndM e b d a c) :
    nd_bind n f1 = nd_bind_lemFuel CerbFuel.driverFuel n f1          -- FULLY APPLIED (see note)
theorem runND_eq {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runND m st0 = runNDFuel CerbFuel.driverFuel m st0
theorem runND1_eq {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runND1 m st0 = runND1Fuel CerbFuel.driverFuel m st0

-- THE SYNC GUARANTEE (§3)
theorem drive_wrapper_defeq : drive = drive_lemFuel CerbFuel.driverFuel
```

Deviation from the design note's §1.2 text, recorded: `nd_bind_wrapper_defeq`
is stated FULLY APPLIED, not as `@nd_bind = @nd_bind_lemFuel driverFuel` —
the generated `nd_bind` wrapper binds its six implicit type arguments
BEFORE the worker's fuel argument, so the point-free form does not
typecheck as written; the fully-applied form is the same equation at
every instance (and the design's F3 discipline anyway). Three sibling
wrapper `rfl`s (`print_eval_conv_aux`, `drive_nonmemory_steps_aux2`,
`hack`) and `runND1_eq` are shipped beyond the note's list (§4.3
"siblings for the quartet").

## 3. `CerbND.drive_lemFuel` — the fuel-parametric pipeline (consumer R1)

```lean
def drive_lemFuel (fuel : Nat) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))
    (with_concurrency : Bool) (file1 : generic_file (Unit) (core_run_annotation)) (arg_strs : List  String)
    : ndM (driver_result) (step_kind) (driver_error) (mem_constraint (CerbMem.IntegerValue)) (driver_state)
```

The generated `drive` body (Driver.lean, `def  drive`) copied VERBATIM
— binder names, comments, spacing — with exactly ONE substitution:
`( driver2 _lemReader_tagDefs)  with_concurrency` →
`( driver2_lemFuel fuel _lemReader_tagDefs)  with_concurrency`. Fuel is
threaded into the MAIN `driver2` call only; the globals phase inside
`driver_globals` runs at the fixed `driverFuel` (consumer §7: "the
single-parameter form is the one we want"). Pinned by
`drive_wrapper_defeq : drive = drive_lemFuel CerbFuel.driverFuel := rfl`
(kernel-checked; any drift in the generated `drive` breaks it and OUR
build goes red — consumer R2, the pinned-lemma gate is our build of
`CerbND.lean`, plus the `check_theorem_axioms.sh` FUEL leg pinning every
lemma's cone to `[propext, Classical.choice, Quot.sound]`).

`drive_lemFuel 0 …` is NOT the kill term (no `_zero` lemma): setup runs
first at fixed budgets; when it reaches `main`, `driver2_lemFuel 0`
kills and `nd_bind`'s `NDkilled` arm propagates the kill (design §1.6).

## 4. The fuel side condition (consumer R3)

**Every exported statement over the drive cone (`drive`, `driver2`,
`nd_bind`, `runND`) has fuel side condition `CerbFuel.driverFuel`;
every other declaration's side condition remains `lemDefaultFuel`
(= 10^6) verbatim (the L1 opt-in guarantee).** The premise shape is
`k + 2 ≤ CerbFuel.driverFuel`.

| commit | `CerbFuel.driverFuel` | `driverFuel_eq` | generated wrappers |
|---|---|---|---|
| 1 (mechanism) | `1000000` (= `lemDefaultFuel`; the wrappers are still emitted at the library default and are `rfl`-equal to `driverFuel` by unfolding both numerals) | `= 1000000` | `driver2_lemFuel lemDefaultFuel` etc. |
| 2 (budget) | `100000000` (= 10^8) on the coupled six: `driver2`, `drive_nonmemory_steps_aux2`, `print_eval_conv_aux`, `hack`, `nd_bind` (L1 `declare {lean} fuel val X = 100000000`) + `CerbND.ndDefaultFuel` | `= 100000000` | `driver2_lemFuel 100000000` etc. |

The defacto trio (`find_array_index`, `easy_update_mem_value_aux`,
`memcmp_load_aux`) and `liftND`/`liftAction` stay at `lemDefaultFuel`
(design Q4; operand-bounded measures). Their `_zero` lemmas are budget-
independent.

Consumer `rfl`s of the shape `driver2 = driver2_lemFuel lemDefaultFuel`
stop being `rfl` at commit 2 and are re-stated against `driverFuel`
(the shipped `*_wrapper_defeq`).

## 5. The `driveU`-deletion expectation

The consumer's partial-correctness exports (API.lean:77-78,
TotalAdequacy.lean:36-39, PROVISIONAL over `driveU`; 149 `driveU`
references across 10 files at their audit-response-3 head) re-state as

```lean
theorem <program>_certified_shipped (fuel : Nat) … :
  ∀ o ∈ CerbND.runND (CerbND.drive_lemFuel fuel fmapEmpty false file args) dst₀,
    (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2)
```

with `dst₀ := (initial_driver_state sup file fs).1`; the PROVISIONAL
label is removed by the consumer; the total-lane equations keep
`driverFuel` in the side condition. Induction shape (their review §3(ii)):
fuel-zero arm → left disjunct by the `_zero` lemma; `Nat.succ` arm → one
engine round → postcondition or the inductive hypothesis; an exhausted
worker beneath (any of the nine, or the runner) → the same kill → left
disjunct. No distinctness lemma, no `DecidableEq`, no decidable
`isFuelExhaustedKill` is needed or shipped.

## 6. The in-repo exemplar (`lean_frontend/test/Unit/FuelExemplar.lean`)

Shipped, kernel-checked, cone = the standard three (probed):
`FuelExemplar.exemplar_certified_shipped_zero` (the consumer shape at fuel
0 — the kill, by `rfl` evaluation of the fuel-independent setup +
`driver2_lemFuel_zero`) and `FuelExemplar.exemplar_certified_shipped_one`
(the consumer shape at fuel 1 — `Active` with `Specified(42)`, via the
kernel-evaluated closed instance `exemplar_run_one_kernel`: the round's
one opaque read `CerbGlobal.current_execution_mode ()` is exposed with
`driver2_lemFuel.eq_2`, CASED, and each branch closed by `decide +kernel`).
The ∀-fuel statement itself is the slice's STOP-AND-REPORT item (the
file header; arc record): it closes with canon tactics only above the
default heartbeat budget (25 s at `maxHeartbeats 0`; red at 200k/400k/
800k) because the ELABORATOR's evaluation of one driver round on the
open term is ~100× the kernel's — remedies need a ruling.

Practical note for the consumer's own ∀-fuel proofs: the `n+1` case
requires `cases` on `CerbGlobal.current_execution_mode ()` (an `opaque`
seam; both scheduler branches take the same singleton-pick path) —
exactly the consumer's existing DriverCollapse discipline.

## 7. The harness FUEL class (reporting-only; no soundness rests on it)

Both fuel forms are classified by the EXACT printed message
(`scripts/fuel_classify.sh classify_fuel_outcome`, one function shared by
every classifying lane): the typed kill prints `Error {msg: "lem: fuel
exhausted"}` (batch; exit 1) / `result: Killed (error: lem: fuel
exhausted)` (non-batch); a pure-return worker's opaque sentinel prints the
bare `lem: fuel exhausted` on stderr, exit 134. Rows: `FUEL`
(test_exec/csmith, test_cn_coverage), `SKIP_LEAN_FUEL` (gcc ledger),
`LEAN_FUEL` (ci_sweep), measure.sh note `FUEL(kill|panic);`. Fail-noisy,
never agreement; the byte-compare lanes report DIFF/FAIL. Plant:
`scripts/test_fuel_plant.sh`; selftest: `scripts/test_fuel_classifier.sh`.

## 8. Not provided (design §1.5, restated)

Fuel monotonicity for the driver workers; a distinguished exit code;
distinctness from a genuine `Error0`; `DecidableEq`; a
`drive_lemFuel_zero` lemma; the pure-return workers (`hack` + ~58) keep
the panicking opaque `fuelExhausted` sentinel (a PANIC, exit 134, never
a kill — `finalize`'s `hack` leaf is registered in TODO.md).
