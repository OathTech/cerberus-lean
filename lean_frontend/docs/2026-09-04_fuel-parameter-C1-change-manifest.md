# Fuel-parameter arc, cerberus half, slice C1 — change manifest for refined-cerberus (2026-09-04)

Branch `arc/fuel-parameter-cerberus` (worktree
`worktrees/cerberus-lean-arc/zero-discrepancy`), base mainline
`mdd/cerberus-lean` @ `1b57bcf26`. Record: `2026-09-04_fuel-parameter-C1-record.md`
(the same directory). Lem side: lem-lean `mdd/lean-backend` @ `ecf75b4`
(`doc/lean-backend/2026-09-03_fuel-parameter-design.md` R1–R3,
`2026-09-04_fuel-parameter-record.md`, `2026-09-04_structural-declare-record.md`,
`2026-09-04_fuel-measure-record.md`, `2026-09-04_d2-enablers-record.md`). Author [AGENT] (the C1 worker);
rulings [USER 2026-09-03/04] as quoted in the record §1.

STATUS: the pin bump is DONE on the REAL tree at lem-lean `ecf75b4` (the
D2 enablers). The record's pass-1 blocker (four lem refusals at
`742506d`) is history; nothing below rests on scratch.

## 1. The one fuel: `[LemFuel]`

- `class LemFuel where fuel : Nat` (LemLib). Every fuel'd generated
  function, every definition that (transitively) reaches one, and the
  hand-written seams that reach one take an INSTANCE-IMPLICIT binder
  `[LemFuel]`. Call sites are textually unchanged. There is NO instance
  anywhere in the library, the generated code, the seams, the tests or
  speclab (gate `scripts/check_no_fuel_numerals.sh`); the executable
  builds one from `--fuel N` (`Main.lean`: `letI : LemFuel := ⟨fuel⟩`
  around `runPipeline`; default `defaultFuel = 100000000`, the one fuel
  numeral the repository's Lean text is MEANT to carry — the gate
  `scripts/check_no_fuel_numerals.sh` is a plant-tested speedbump over the
  idiomatic spellings, not a proof: indirection through a non-fuel-named
  constant is not regex-closable (audit M2); the backstop you can rely on
  is the typing — no `LemFuel` instance exists anywhere in the library,
  the generated code or the seams, so every fuel'd function is
  quantifiable at your use site).
- Wrapper shape: `def f [LemFuel] : T := f_lemFuel LemFuel.fuel`;
  `@f ⟨n⟩ = f_lemFuel n` by `rfl` for every `n` (a worker that passes the
  ambient on carries the instance too: `@f ⟨n⟩ = @f_lemFuel ⟨n⟩ n`).
  Every fuel'd callee starts from the FULL ambient, never from its
  caller's remaining counter.
- Census on the real tree (derived, `grep`): 397 `[LemFuel]` binders in
  the generated model + 53 in the hand-written seams; 64 ambient wrappers
  and 3 MEASURED wrappers (67 sentinel `fuel` declares); 67 generated
  `f_lemFuel_zero` lemmas; 147 derived `t.lemSize`/`t.lemSize_auxN`
  structural size functions (every recursive block of generated
  inductives — kernel-computable, axiom-free); 19 `mem.lem`
  `fuel_consumer` declares; `inductive monTrace [LemFuel]` (Cmm_op).

## 2. The consumer-facing surface: what you write now

| You had | You write now | Note |
|---|---|---|
| `CerbND.drive_lemFuel fuel tds conc file args` (the hand-written mirror) | `@drive ⟨fuel⟩ tds conc file args` (the GENERATED `drive [LemFuel]`) | the mirror and its sync theorem `CerbND.drive_wrapper_defeq` are DELETED: the generated `drive` IS the fuel-parametric pipeline |
| `CerbND.runND m st` (at `ndDefaultFuel`) | `@CerbND.runND _ _ _ _ _ ⟨n⟩ m st` (binder order `{a info err cs st} [LemFuel]`), or under `letI`/an ambient instance just `CerbND.runND m st` | `CerbND.runND_eq (n) : @runND a info err cs st ⟨n⟩ m st0 = runNDFuel n m st0 := rfl`; same for `runND1`/`runND1_eq`, `runND1Trace`/`runND1Trace_eq` (`{info a err cs st}` order) |
| `driver2 = driver2_lemFuel CerbFuel.driverFuel` (`driver2_wrapper_defeq`) | `driver2_wrapper_defeq (n) : @driver2 ⟨n⟩ = @driver2_lemFuel ⟨n⟩ n := rfl` | likewise `print_eval_conv_aux_wrapper_defeq`, `drive_nonmemory_steps_aux2_wrapper_defeq`, `hack_wrapper_defeq` (workers carry the instance); `nd_bind_wrapper_defeq {a b c d e f} (n) : @nd_bind a b c d e f ⟨n⟩ = @nd_bind_lemFuel a b c d e f n`, NEW `liftND_wrapper_defeq`, `liftAction_wrapper_defeq` (leaf workers, no instance) |
| `CerbND.nd_bind_lemFuel_zero`, `liftND_…`, `liftAction_…`, `print_eval_conv_aux_…`, `drive_nonmemory_steps_aux2_…`, `driver2_…`, `find_array_index_…`, `easy_update_mem_value_aux_…`, `memcmp_load_aux_…` (`_lemFuel_zero`, in `CerbND`) | the GENERATED lemmas of the same base names in the ROOT namespace: `nd_bind_lemFuel_zero`, `liftND_lemFuel_zero`, `liftAction_lemFuel_zero` (Nondeterminism.lean), `print_eval_conv_aux_lemFuel_zero`, `drive_nonmemory_steps_aux2_lemFuel_zero`, `driver2_lemFuel_zero` (Driver.lean), `find_array_index_lemFuel_zero`, `easy_update_mem_value_aux_lemFuel_zero`, `memcmp_load_aux_lemFuel_zero` (Defacto_memory.lean) — RHS spelled `ND (fun st => (NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), st))`; bridge `CerbND.fuelExhaustedKill_eq : (fuelExhaustedKill : kill_reason err) = Error0 fuelExhaustedLoc fuelExhaustedMsg := rfl` | `driver2_lemFuel_zero` and the other ambient-passing workers' lemmas carry `[LemFuel]`; `liftAction_lemFuel_zero` ascribes the codomain (lem fuel-measure record §2.4); every other fuel'd function has one too (64) |
| `CerbFuel.driverFuel` (10^8), `CerbND.driverFuel_eq`, `CerbND.ndDefaultFuel`, LemLib `lemDefaultFuel` (10^6) | nothing — quantify. `Main.defaultFuel` is the harness default, not a semantic constant (no theorem may depend on it; the gate forbids naming a fuel numeral anywhere else) | DELETED |
| hypotheses `potential e ≤ lemDefaultFuel` (your ~60 sites) | `∀ [LemFuel], potential e ≤ LemFuel.fuel → step_eval_pexpr … e = r` — equivalently `∀ n, potential e ≤ n → @step_eval_pexpr ⟨n⟩ … e = r`; for a closed executable `letI : LemFuel := ⟨n⟩`; the shipped-constant version is the corollary at `⟨100000000⟩` | lem fuel-parameter record §6.7 verbatim restatement; the two constants (10^8 driver family, 10^6 the rest) collapse to ONE hypothesis variable; the worker-level form `f_lemFuel n …` is unchanged |
| `CerbMem.sizeofCtype ambient ty`, `alignofCtype`, `offsetsof`, `offsetsofMembers`, `memberAlign`, `memValueToBytes`, `reconstructValue`, `typeofMval`, `ctypeMemCompatible` (at `lemDefaultFuel`) | the same names with a leading `[LemFuel]`; `X_lemFuel LemFuel.fuel …` inside; `memValueToBytes_eq_append`, `reconstructValue_eq_indexed` take `[LemFuel]` and read `… = X_…_lemFuel LemFuel.fuel …` | the hand-written workers `memValueToBytes_lemFuel`, `memValueToBytes_append_lemFuel`, `reconstructValue_lemFuel`, `reconstructValue_indexed_lemFuel` take `[LemFuel]` as well (they call the ambient wrappers of their siblings — the generated design's "callee starts from the full ambient") |
| `CerbMem.allocateObject`, `allocateRegion`, `loadM`, `storeM`, `memcpyM`, `memcmpM`, `reallocM`, `nePtrval`, `copyAllocId`, `sizeofIval`, `alignofIval`, `offsetofIval`, `arrayShiftPtrval`, `memberShiftPtrval`, `effArrayShiftPtrval`, `effMemberShiftPtrval`, `diffPtrval`, `isWellAlignedPtrval`, `validForDerefPtrval`, `isWithinDevice`, `isAtomicMemberAccess` | `[LemFuel]` added (leading) | the `mem.lem` reps among them (19) are `declare {lean} fuel_consumer`, so their generated callers are fuel-lifted; call sites unchanged |
| `CerbCall.driveCall tds file fname args` | `[LemFuel]` added (also `allocErrno`, `callFinish`) | |
| speclab `*File`/`*FileOf*` constructors (`divmodI8File`, `memcpyI3File`, …) and the gate tests' `runFile*` | `[LemFuel]` added — `convert_file [LemFuel]` (its `convert_expr` passes the ambient on) | the gate binaries take `--fuel N` (REQUIRED; the lane scripts pass `CERB_TEST_FUEL`, scripts/common.sh — a test-suite choice outside the scanned Lean text) |
| `tests/immaculate/illtyped-store.lean` (in-Lean probe), `tests/mem-scale-probes/micro/Micro.lean` (instrument) | both take `--fuel N` (required) on their command line; `runStore [LemFuel]`, `run [LemFuel]` | the pattern for any in-tree Lean consumer of the memory model: no in-binary default, the caller chooses |
| `ctypeEqual c c0`, `eq_core_base_type b1 b2`, `fake_mem_value_eq m1 m2` (fuel'd at `lemDefaultFuel`; the `Eq0` instances of `ctype`/`core_base_type`/`impl_mem_value`) | UNCHANGED SIGNATURES, now MEASURED: `def ctypeEqual (c c0 : ctype) : Bool := ctypeEqual_lemFuel (ctype.lemSize c) c c0` etc. — NO fuel binder, fuel-free for every caller, the kernel computes them on closed terms (`decide`/`rfl`); their `Eq0` instances are fuel-free | the sufficiency theorems (generated statement + hand-written proof; cones ⊆ the standard three): `ctypeEqual_measure_sufficient (c c0) (lemFuel) (h : ctype.lemSize c ≤ lemFuel) : ctypeEqual_lemFuel lemFuel c c0 = ctypeEqual c c0` (Ctype_auxiliary.lean / `Ctype_lemMeasureProofs`), `eq_core_base_type_measure_sufficient` (Core_auxiliary / `Core_lemMeasureProofs`), `fake_mem_value_eq_measure_sufficient` (Defacto_memory_aux_auxiliary / `Defacto_memory_aux_lemMeasureProofs`); `f_lemFuel_zero` still holds for each worker. The derived sizes are `ctype.lemSize`, `ctype_.lemSize`, `ctype_.lemSize_aux1`, `core_base_type.lemSize`, `core_base_type.lemSize_aux1`, `impl_mem_value.lemSize`, … (147 in all; every constructor counts 1, a list field `length + Σ`, leaves 0) |
| `monStep`/`monTrace` (Cmm_op) | `inductive monTrace [LemFuel] : pre_execution → incState → incState → Prop` — the relation takes the ambient as an inductive PARAMETER (`@monTrace ⟨n⟩ pre x z`) | concurrency model; a declared boundary, unchanged in meaning |
| `initial_driver_state sup file fs` (generated) | `[LemFuel]` (it reaches `collect_saves`) — `@initial_driver_state ⟨n⟩ …` | your `dst₀`-style cold starts need the instance |
| `FuelExemplar.exemplar_certified_shipped_forall (fuel)` over `drive_lemFuel fuel` | the same name over `run fuel := @CerbND.runND _ _ _ _ _ ⟨fuel⟩ (@drive ⟨fuel⟩ …) (@dst₀ ⟨fuel⟩ 0)`; `exemplar_certified_shipped_zero`; `exemplar_killed_at_one` (NEW: at fuel 1 the first memory operation's `liftMem` is the kill — one ambient fuel, no separate setup budget); `exemplar_certified_shipped_one`/`exemplar_run_one_kernel` DELETED | the ∀-theorem: fuels 0 and 1 kill, every fuel ≥ 2 delivers `Specified(42)` (record §4.3) |

## 3. What C2 changes next (so you do not chase moving names)

- The MEASURED wrappers (lem fuel-measure record §6.2: 38 rows) lose the
  `[LemFuel]` binder and become fuel-FREE for callers (`def f (xs…) :=
  f_lemFuel (<measure>) xs…`, kernel-computable), each with a generated
  `f_measure_sufficient` obligation proved in a hand-written
  `<Module>_lemMeasureProofs.lean`. Their consumers' binders disappear
  with them wherever no other fuel'd callee remains. Five keep the binder
  because their bodies pass the ambient on (`convert_expr`,
  `memValueFromValue`, `step_eval_pexpr`, `easy_update_mem_value_aux`,
  `memcmp_load_aux`).
- The hand-written `CerbMem` layout/(de)serialisation entries get the
  design's shape by hand (measured where the recursion is on the data;
  ambient where it is a tag lookup) — record §6 of the lem fuel-measure
  record, seam work list item 2.
- The (B) family (`nd_bind`, `liftND`, `liftAction`, the driver loops,
  `full_eval_pexpr`, `eval_pexpr_aux2/_broken`, `load_character_array_aux`)
  stays ambient; the absorbing-payload check and monotonicity are the
  typed-failure pass (`2026-09-04_fuel-parameter-consumer-review-response.md`).
- The remaining 35 measured rows and the residue classification — the
  three measured here are the template (record §3.5).
