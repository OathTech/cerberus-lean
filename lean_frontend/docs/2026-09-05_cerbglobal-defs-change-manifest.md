# CerbGlobal as plain definitions — change manifest for refined-cerberus (2026-09-05)

Branch `arc/cerbglobal-defs` (base mainline `mdd/cerberus-lean` @ `928aa1e76`,
the merged fuel-parameter C3). Record: `2026-09-05_cerbglobal-defs-record.md`
(same directory). Author [AGENT] (the slice worker). Lake pin UNCHANGED
(LemLib `d4ba548d084ff393126f04d90f18a72c3000aa88`); no `.lem` change; the
generated tree is byte-identical to the C3 head except the seam's own copy
`generated/CerbGlobal.lean`.

## 1. What changed (one file of the semantics, one test)

`lean_frontend/CerbGlobal.lean`: the eleven configuration/switch reads that
were `opaque … @[implemented_by]` wrappers over two process `IO.Ref`s — refs
nothing ever wrote — are plain `def`s of the default configuration. NAMES
AND TYPES ARE UNCHANGED:

| Name | Type | Is now (unfolds to) |
|---|---|---|
| `CerbGlobal.backend_name` | `Unit → String` | `"Driver"` |
| `CerbGlobal.current_execution_mode` | `Unit → Option ExecutionMode` | `none` |
| `CerbGlobal.using_concurrency` | `Unit → Bool` | `false` |
| `CerbGlobal.isDefacto` | `Unit → Bool` | `false` |
| `CerbGlobal.isPermissive` | `Unit → Bool` | `false` |
| `CerbGlobal.isAgnostic` | `Unit → Bool` | `false` |
| `CerbGlobal.isIgnoreBitfields` | `Unit → Bool` | `false` |
| `CerbGlobal.has_switch` | `CerbSwitch → Bool` | `false` (for every argument: `switches.any (· == sw)` over `def switches : List CerbSwitch := []`) |
| `CerbGlobal.is_CHERI` | `Unit → Bool` | `false` (`has_switch .cheri`) |
| `CerbGlobal.is_PNVI` | `Unit → Bool` | `false` |
| `CerbGlobal.has_strict_pointer_arith` | `Unit → Bool` | `false` |

New, citable (all `rfl`):

```lean
theorem CerbGlobal.backend_name_eq : backend_name () = "Driver"
theorem CerbGlobal.current_execution_mode_eq : current_execution_mode () = none
theorem CerbGlobal.using_concurrency_eq : using_concurrency () = false
theorem CerbGlobal.isDefacto_eq : isDefacto () = false
theorem CerbGlobal.isPermissive_eq : isPermissive () = false
theorem CerbGlobal.isAgnostic_eq : isAgnostic () = false
theorem CerbGlobal.isIgnoreBitfields_eq : isIgnoreBitfields () = false
theorem CerbGlobal.has_switch_eq (sw : CerbSwitch) : has_switch sw = false
theorem CerbGlobal.is_CHERI_eq : is_CHERI () = false
theorem CerbGlobal.is_PNVI_eq : is_PNVI () = false
theorem CerbGlobal.has_strict_pointer_arith_eq : has_strict_pointer_arith () = false
```

Also new: `def CerbGlobal.conf : CerbConf := {}` and `def CerbGlobal.switches
: List CerbSwitch := []` (the values the reads project; `CerbConf`,
`ExecutionMode`, `CerbSwitch` are unchanged). DELETED (all were `private`
or `unsafe`, so nothing of yours can have named them): `confRef`,
`switchesRef`, `getConf`, the eleven `*_impl`.

The only value that moved: `backend_name ()` was `"cerberus-lean"` at
runtime (never provable), is `"Driver"` (the oracle driver's, `main.ml:124`).
Every read of it in the model is `== "Cn"` / `== "Bmc"` (record §2), so no
export's meaning changes.

## 2. What you may now do

- **`killM` / `ptrfromint`** (your `free` rule's referent, `Heap.lean:826-834`;
  the Z1 reads your README's switch-independence argument did not know
  about): `if CerbGlobal.has_switch .forbid_nullptr_free then …`, `if
  CerbGlobal.has_switch .zap_dead_pointers then …`, `if CerbGlobal.is_PNVI
  () then …` each close by `simp only [CerbGlobal.has_switch_eq,
  CerbGlobal.is_PNVI_eq, Bool.false_eq_true, ↓reduceIte]` (or `rw [… ];
  rw [if_neg (fun h => Bool.noConfusion h)]`, or `decide` on the test).
  Your `README.md:585-600` premise ("the Lean `CerbMem` references no
  `CerbGlobal` constant") should be restated as "every `CerbGlobal` read in
  `CerbMem` unfolds to its default (`has_switch_eq`, `is_PNVI_eq`)".
- **`driver2_done`** (`DriverCollapse.lean:64`, `cases hmode` at `:709`): drop
  the `cases`; `rw [CerbGlobal.current_execution_mode_eq]` then
  `rw [if_neg (fun h => Bool.noConfusion h)]` and keep the exhaustive arm
  only — the in-repo exemplar's exact change
  (`test/Unit/FuelExemplar.lean`, `driver2_done`).
- **`core_thread_step2`** (`Core_run.lean:424`, `has_switch .inner_arg_temps`):
  `CerbGlobal.has_switch_eq` closes the test if you ever step through
  `main`'s call.
- Nothing is opaque in `CerbGlobal` any more; the boundary-opaque census
  (`scripts/check_theorem_axioms.sh` OPAQUE_WANT) is 15 rows — the digest
  boundary (7), `CerbUtils` (4), `CerberusImpl` enum registry (2),
  `CerbMem.beqMemValueSafe`, `CerbFuel.fuelExhaustedLoc`.

## 3. What did NOT change

- No generated module's text (the reads are the same applications of the
  same names); no `drive`/`driver2` signature; no lem pin; no `.lem`.
- `current_execution_mode () = none` is what the binary always computed;
  the oracle's `--mode` is the declared Z2-G-01 instrument (record §2.1).
- Step 2 — the configuration as a reader-lifted PARAMETER of `drive`
  (like `tagDefs`), so a theorem quantifies over switch settings — is a
  later, separately chartered slice; `using_concurrency`'s parameterisation
  is `feature/concurrency`'s. Until then, "every export holds under every
  switch setting" means "under the default configuration, stated".
