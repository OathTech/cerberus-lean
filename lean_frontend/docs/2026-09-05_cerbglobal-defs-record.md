# Reasoning-artifact audit, instance A step 1 — the switch/config surface as plain definitions (2026-09-05)

Branch `arc/cerbglobal-defs` (worktree `worktrees/cerberus-lean-arc/zero-discrepancy`),
from mainline `mdd/cerberus-lean` @ `928aa1e76` (the merged fuel-parameter
C3). Charter (the orchestrator's brief): audit `docs/2026-09-03_reasoning-
artifact-audit.md` §2.A "Step 1 (S, a deletion, zero behaviour change)" and
§4 item 1 — every `CerbGlobal` read that was an `opaque … implemented_by`
wrapper over an `IO.Ref` nothing ever wrote becomes a plain `def` of the
default configuration; the refs and the `unsafe` plumbing are deleted; names
and types are unchanged (no generated-code change); the census rows leave the
pins; behaviour identical, proved by the full battery at zero movement.
Worker [AGENT]; every quoted output is verbatim from this worktree
(`.tmp/cg/` logs, ephemeral, deleted at slice end); tallies marked "derived"
are derived. Nothing merged, nothing pushed; lem pins untouched (lem-lean
`d4ba548` everywhere); the primary checkout, `deps/`, `lem-lean/`, the other
worktrees untouched.

## 0. Summary — READ THIS FIRST

- `lean_frontend/CerbGlobal.lean`: the two `IO.Ref`s (`confRef`,
  `switchesRef`), `getConf`, the eleven `unsafe … _impl` readers and the
  eleven `@[implemented_by] opaque` wrappers are DELETED. In their place:
  `def conf : CerbConf := {}` (the driver's defaults, cited field by field
  to `backend/driver/main.ml` / `util/cerb_global.ml`), `def switches :
  List CerbSwitch := []` (`Switches.internal_ref = ref []`), and the eleven
  names as plain `def`s over them, plus eleven `rfl` lemmas
  (`has_switch_eq (sw) : has_switch sw = false`,
  `current_execution_mode_eq : current_execution_mode () = none`, …). The
  file has zero `unsafe`/`opaque`/`implemented_by`/`unsafeBaseIO` sites.
- ONE default value moved, provably without effect: `backendName`
  `"cerberus-lean"` → `"Driver"` (the oracle's, main.ml:124). Every read
  of `backend_name ()` in the model is an equality test against `"Cn"` or
  `"Bmc"` (§2, census); neither string ever matched, neither matches now.
  Every other default is the value the deleted refs held (§2).
- `current_execution_mode` stays `none` — NOT a value this port's CLI
  chooses: `--first` is the explicit `firstTrace` argument `Main` threads
  to the runner choice (`CerbND.runND1` vs `runND`, `Main.lean:967`) and
  never flowed into the ref. Whether `--first` should read as `Random`
  (the oracle's `--mode=random` default, main.ml:438-441) is deferred to
  step 2, where the read becomes a parameter (§2.1, §7).
- Census: `scripts/unsafebaseio_allowlist.txt` PIN rows 66 → 37 (the 29
  CerbGlobal rows: 11 IMPLBY + 4 UNSAFEBASEIO + 14 UNSAFEDECL, retired
  with the reason in-file), its four CerbGlobal KEEP rows retired;
  `check_theorem_axioms.sh` OPAQUE_WANT 26 → 15 (the 11 CerbGlobal rows).
  Both populations moved DOWN only; nothing moved up anywhere (§4).
- `test/Unit/FuelExemplar.lean` `driver2_done`: the `cases hmode` on the
  opaque scheduler-mode read (two arms, one unreachable) is a `rw
  [CerbGlobal.current_execution_mode_eq]` + `if_neg`; kernel-only, no
  option bump (§3).
- Battery on fresh stamped binaries: Tier A + Tier B — ZERO movement (§5).
- Consumer (refined-cerberus): the switch-independence argument of
  `cerberus-heaplang/README.md:585-600` is TRUE again at this head, now by
  unfolding rather than by absence; `driver2_done`'s `cases` can go. Change
  manifest: `2026-09-05_cerbglobal-defs-change-manifest.md` (§6).
- Not done / for the operator: §7. Commits: §8.

## 1. The premise, measured before the change

The audit's load-bearing fact (§2.A: "nothing ever WRITES these refs") was
re-verified on this head before any edit:

- No setter: `grep -n 'confRef\|switchesRef' lean_frontend/*.lean
  lean_frontend/test/Unit/*.lean lean_frontend/speclab/**/*.lean` — the only
  hits are the two definitions and their two reads inside
  `CerbGlobal.lean` (`getConf`, `has_switch_impl`). `Main.lean` names
  `CerbGlobal` once, in the Z-24 refusal text (`Main.lean:1084`: "CerbGlobal's
  switch set is permanently empty").
- The CLI refuses every flag that would set one (`Main.refuseFlag`,
  `Main.lean:1081-1091`; Z-24 record §Z-24: `--switches=…`, `--concurrency`,
  any `--mode`, exit 2).
- Reads in the generated tree at this head (derived, `grep -o
  'CerbGlobal\.[A-Za-z_]*' lean_frontend/generated/*.lean | sort | uniq -c`,
  the seam's own copy excluded): `is_CHERI` 32, `isAgnostic` 12,
  `backend_name` 9, `has_switch` 9, `has_strict_pointer_arith` 4,
  `is_PNVI` 4, `using_concurrency` 4, `isPermissive` 3,
  `current_execution_mode` 2, `isDefacto` 1, `isIgnoreBitfields` 1 (plus
  the type names `CerbSwitch` 8, `ExecutionMode` 4). Exec-cone sites as the
  audit lists them: `Core_run.lean:424` (`has_switch .inner_arg_temps`),
  `Driver.lean:317,425` (`current_execution_mode`), `CerbMem.lean:2167,
  2212` (`has_switch .forbid_nullptr_free` / `.zap_dead_pointers` in
  `killM`), `CerbMem.lean:2630` (`is_PNVI` in `ptrfromint`),
  `Core_run_aux.lean:451,463,472,484` (`using_concurrency`).

## 2. Each read → its default, with the OCaml cite

The oracle's configuration is written ONCE, by the driver:
`set_cerb_conf ~backend_name:"Driver" ~exec exec_mode ~concurrency QuoteStd
~defacto ~permissive ~agnostic ~ignore_bitfields` (`backend/driver/main.ml:124`;
`util/cerb_global.ml:35-43` builds the record; the readers are
`cerb_global.ml:45-64`). The switch list is `Switches.internal_ref = ref []`
(`ocaml_frontend/switches.ml:47-48`), written only by `Switches.set` /
`set_iso_switches` from `--switches` / `--iso` (`main.ml:129-143`; the CHERI
build variant prepends "CHERI" itself at `:130-136` — not this build).

| Lean read (name and type unchanged) | Was (`opaque`, `implemented_by` a ref read) | Now (`def`) | Value | OCaml twin and the default's origin |
|---|---|---|---|---|
| `backend_name : Unit → String` | `getConf.backendName` = `"cerberus-lean"` | `conf.backendName` | `"Driver"` | `Cerb_global.backend_name` (cerb_global.ml:45-46); `~backend_name:"Driver"` main.ml:124. MOVED (see below) |
| `current_execution_mode : Unit → Option ExecutionMode` | `getConf.execMode` = `none` | `conf.execMode` | `none` | `Cerb_global.current_execution_mode` (:63-64); `exec_mode_opt = if exec then Some exec_mode else None` (:36), `--mode` default `Random` (main.ml:438-441). Z2-G-01 instrument, unchanged — §2.1 |
| `using_concurrency : Unit → Bool` | `getConf.concurrency` = `false` | `conf.concurrency` | `false` | `Cerb_global.concurrency_mode` (:48-49); `--concurrency` `Arg.flag` main.ml:496-498 (refused here, Z-24) |
| `isDefacto : Unit → Bool` | `getConf.defacto` = `false` | `conf.defacto` | `false` | `Cerb_global.isDefacto` (:51-52); `--defacto` flag main.ml:515-517 |
| `isPermissive : Unit → Bool` | `getConf.permissive` = `false` | `conf.permissive` | `false` | `Cerb_global.isPermissive` (:54-55); `--permissive` flag main.ml:519-521 |
| `isAgnostic : Unit → Bool` | `getConf.agnostic` = `false` | `conf.agnostic` | `false` | `Cerb_global.isAgnostic` (:57-58); `--agnostic` flag main.ml:421-424 |
| `isIgnoreBitfields : Unit → Bool` | `getConf.ignoreBitfields` = `false` | `conf.ignoreBitfields` | `false` | `Cerb_global.isIgnoreBitfields` (:60-61); `--dignore-bitfields` flag main.ml:426-432 |
| `has_switch : CerbSwitch → Bool` | `(unsafeBaseIO switchesRef.get).any (· == sw)` over `[]` | `switches.any (· == sw)` over `def switches := []` | `false` for every `sw` | `Switches.has_switch sw = List.mem sw !internal_ref` (switches.ml:54-55); `internal_ref = ref []` (:47-48) |
| `is_CHERI : Unit → Bool` | `has_switch_impl .cheri` | `has_switch .cheri` | `false` | `Switches.is_CHERI` = `List.exists (function SW_CHERI …) !internal_ref` (:153-154) |
| `is_PNVI : Unit → Bool` | literal `false` | literal `false` | `false` | `Switches.is_PNVI` = `List.exists (function SW_PNVI _ …) !internal_ref` (:156-157) over `[]`; `SW_PNVI` is outside the lem subset (`global.lem:64-71`) |
| `has_strict_pointer_arith : Unit → Bool` | literal `false` | literal `false` | `false` | `Switches.has_strict_pointer_arith` = ``has_switch (SW_pointer_arith `STRICT)`` (:159-160) over `[]`; outside the lem subset |

`CerbConf` (the record type, `cerb_global.ml:18-28`'s subset the lem model
reads) is KEPT as the value type step 2's parameter will have; `conf : CerbConf
:= {}` is its defaults. `ExecutionMode` and `CerbSwitch` are unchanged
(the `no_integer_provenance` Z2-G-02 instrument note included).

**The one moved default, `backendName`.** The deleted ref's default was
`"cerberus-lean"`; the oracle's value is `"Driver"` (main.ml:124). Every
read of `backend_name ()` in the model is an equality test — the complete
set, from the `.lem` (`grep -n 'backend_name' frontend/model/*.lem`):
`cabs_to_ail_effect.lem:676` (`= "Cn"`), `translation_effect.lem:231`
(`= "Cn"`), `translation.lem:409, 1732, 1741` (`= "Cn"`), `core_aux.lem:552-553`
(`let backend = … in if backend = "Cn" || backend = "Bmc"`); the generated
Lean agrees (derived: `grep -oE 'CerbGlobal\.backend_name +\(\) +== +"[A-Za-z]*"'`
→ 8 × `== "Cn"` in `Cabs_to_ail_effect`/`Translation_effect`/`Translation`;
`Core_aux.lean:384` `backend == "Cn"`, `backend == "Bmc"`). No read prints,
stores or otherwise inspects the string. Hence `"cerberus-lean"` and
`"Driver"` are indistinguishable to the model; the value is now the
oracle's (mirror doctrine), and the battery confirms (§5).

### 2.1 `current_execution_mode` — confirmed NOT a CLI-chosen value here

The brief's rule: if the mode is chosen at the CLI it must stay a driver
parameter, never a constant. Checked in `Main.lean`: the port's trace
selection `--first` is parsed into `firstTrace : Bool`
(`Main.lean:792, 1304`) and threaded EXPLICITLY to the runner choice —
`if firstTrace then CerbND.runND1 driverAction drSt else …` (`Main.lean:967`);
it never wrote `confRef.execMode`, which no code path ever wrote (§1). So
the value the binary has always computed for `Global.current_execution_mode
()` is `none`, in both `--first` and exhaustive runs; the `def` states that.
The oracle's value differs by lane (`Some Exhaustive` under the exec lanes'
`--mode=exhaustive`; `Some Random` under the single-trace lanes' bare
default) — the DECLARED Z2-G-01 instrument (Z2 record; the in-file note is
kept): the one live exec-cone read, `driver.lem:1380` (`if
Global.current_execution_mode () = Just Global.Random then …`), takes the
same branch for `none` and `Some Exhaustive`; `driver.lem:748`'s
`_execution_mode_is_random` is an unused binding. Making `--first` read
as `Random` would CHANGE the branch taken in the single-trace lanes — a
behaviour change outside this step, and moot once step 2 makes the read a
parameter the driver supplies. Recorded as a step-2 question (§7), not
decided here.

## 3. The exemplar (`test/Unit/FuelExemplar.lean`)

`driver2_done` (the scheduler round at counter `fl + 1`) had, at the
`driver.lem:1380` test,

```lean
    cases hmode : maybeEqualBy (fun x y => x == y)
        (CerbGlobal.current_execution_mode ())
        (some CerbGlobal.ExecutionMode.random) with
    | true => … (bindExhaustive arm) …
    | false => rw [if_neg (fun h => Bool.noConfusion h)] …
```

— both arms proved, the `true` arm being one the binary can never take.
Now:

```lean
    rw [CerbGlobal.current_execution_mode_eq]
    rw [if_neg (fun h => Bool.noConfusion h)]
    … (the former `false` arm, unchanged)
```

Kernel-only (`rw`/`rfl`), no option bump; `fuel-exemplar-test` builds and
the FUEL leg of `check_theorem_axioms.sh` reports its cones unchanged
(§5.1). The header comment is updated (the round library entry and the
"DIAGNOSIS" paragraph no longer describe the read as opaque).

## 4. Census: rows retired (populations move DOWN only)

`scripts/unsafebaseio_allowlist.txt`:

- KEEP rows retired (4): `confRef`, `switchesRef`, `getConf`,
  `has_switch_impl` (class `temporal(post-arc-parameter-plumbing-slice)`),
  with the retirement note in the file's "retired 2026-09-05" section.
  KEEP rows 11 → 7 (derived, `grep -c KEEP`).
- PIN rows retired (29 = 11 IMPLBY + 4 UNSAFEBASEIO + 14 UNSAFEDECL, all
  `lean_frontend/CerbGlobal.lean`, count 2 each — the hand-written file
  and its `generated/` copy): PIN rows 66 → 37 (derived, `grep -c '^PIN '`).
- The header's comment-mention list drops `CerbGlobal.lean:51` (the file
  no longer mentions `unsafeBaseIO` even in a comment); the Q4 class
  comment for CerbGlobal reads "NO rows since 2026-09-05".

`scripts/check_theorem_axioms.sh` `OPAQUE_WANT`: the 11 `CerbGlobal.lean:*`
rows deleted (26 → 15), with the history comment. Any `opaque` reappearing
in `CerbGlobal.lean` now fails the census as UNREGISTERED, by design.
`scripts/check_exec_purity.sh`'s boundary comment updated (no code change).

Before (the C3 record's verbatim, same head `928aa1e76`, §6.1 there):

```
check_theorem_axioms: generated-tree census OK (205 files: 0 axioms, boundary-opaque population = the 26 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (321 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
```

After: §5.1 (the same two lines at 15 and 37).

No population moved up: the gate is a both-directions pin, so an
unregistered new site anywhere would have failed naming itself; the run is
green (§5.1).

## 5. Battery — fresh stamped binaries, zero movement

Binaries: oracle unchanged (no OCaml/`.lem` change; stamp `bin 28fb2198…`
verified by `tools/check_driver_fresh.sh --check` before the slice, rc 0);
Lean rebuilt by `scripts/common.sh build_lean` under `CERB_MEM_MAX=32G`
(`Build completed successfully (271 jobs)`; stamp `bin 00edd6fd…, src
e9f05dfb…`). Lanes SERIAL, each rc checked explicitly; box under external
load (the primary checkout's refresh; load average 31–57 during the runs)
— relevant only to the wall-clock-sensitive gcc row (Tier B 7), read per
its caveat.

### 5.1 Tier A row 1 — `./scripts/test_unit.sh` (rc=0, checked explicitly: `test_unit rc=0`)

```
check_handwritten_sync: OK (35 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
✓ effects-proof-test PASSED
✓ totality-proof-test PASSED
Done: 292 passed, 0 failed
✓ core-parser-test PASSED
✓ fresh-int-test PASSED
✓ pp-test PASSED
FuelExemplar: exemplar_certified_shipped_forall (∀ fuel over the shipped `@drive ⟨fuel⟩`; the consumer's §6 shape, symbolic round library) — kernel-checked at compile time
FuelExemplar: exemplar_certified_shipped_zero (fuel 0 → the runner's distinguished kill) — kernel-checked at compile time
FuelExemplar: exemplar_killed_at_one (fuel 1 → the kill at the first memory operation; fuels ≥ 2 deliver Specified(42)) — kernel-checked at compile time
✓ fuel-exemplar-test PASSED
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (205 files: 0 axioms, boundary-opaque population = the 15 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (321 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 37 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 35 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: FUEL arc leg OK (34 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 fuel_measure sufficiency obligations (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (282 files scanned comment-stripped — generated 205, hand-written+test 42, LemLib 35; 0 sorry tokens)
test_fuel_classifier: 18 fixtures, ALL OK
check_no_fuel_numerals: OK (286 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
check_lakefile_roots: OK (204 roots = 204 generated modules + the exe root Main; 85 auxiliary modules all built)
check_fuel_forms: OK (81 fuel'd workers: 47 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 15 reachable-AMBIENT = the 15 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: lean OK (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen e48450a7c3ef435844a6de36180fa1a473126c3bf0a5a8a1e1f23b0bea740218)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
test_unit rc=0
```

The census lines to read against §4: `boundary-opaque population = the 15
registered rows` (was 26) and `seam population = the 37 pinned … rows`
(was 66). The lem-sync stamps (`gen 295e4f82…` OCaml, `gen e48450a7…`
Lean) are the C3 head's — no `.lem` output moved. The no-fuel-numerals
and fuel-forms gates are unchanged (same lines as the C3 record).

### 5.2 Tier A rows 2–11 and Tier B rows 1–8 — rc per lane (serial; `.tmp/cg/tierA_summary.txt`, `tierB_summary.txt`, verbatim)

```
LANE [./scripts/test_exec.sh --check-baseline] rc=0 wall=35s
LANE [./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage] rc=0 wall=57s
LANE [./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug] rc=0 wall=28s
LANE [./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float] rc=0 wall=22s
LANE [./scripts/test_bytes.sh] rc=0 wall=6s
LANE [./scripts/test_libc_exec.sh] rc=0 wall=42s
LANE [./scripts/test_multi_tu.sh] rc=0 wall=4s
LANE [./scripts/test_parse.sh] rc=0 wall=20s
LANE [./scripts/test_core.sh] rc=0 wall=20s
LANE [./scripts/test_elab.sh] rc=0 wall=24s
LANE [./scripts/test_libxml2_uri.sh] rc=0 wall=12s
LANE [./scripts/test_cn_coverage.sh --check-baseline] rc=0 wall=28s
LANE [./scripts/test_libxml2.sh] rc=0 wall=1033s
LANE [./scripts/test_parse.sh tests/ci] rc=0 wall=47s
LANE [./scripts/test_core.sh tests/ci] rc=0 wall=44s
LANE [./scripts/test_verify.sh] rc=0 wall=90s
LANE [./scripts/test_immaculate.sh] rc=0 wall=83s
LANE [./scripts/test_speclab.sh --selftest] rc=0 wall=110s
LANE [./scripts/test_speclab.sh --plant] rc=0 wall=4s
LANE [./scripts/test_speclab_divmod.sh --gate] rc=0 wall=13s
LANE [./scripts/test_speclab_bytearr.sh --gate] rc=0 wall=11s
LANE [./scripts/test_speclab_list.sh --gate] rc=0 wall=11s
LANE [./scripts/test_speclab_tree.sh --gate] rc=0 wall=13s
LANE [./scripts/test_speclab_seed.sh --gate] rc=0 wall=11s
LANE [./scripts/test_gcc_oracle.sh --check-baseline] rc=0 wall=1459s
LANE [./scripts/test_hang_plant.sh] rc=0 wall=13s
LANE [./scripts/test_kill_plant.sh] rc=0 wall=219s
LANE [./scripts/test_fuel_plant.sh] rc=0 wall=6s
```

Verdict lines, verbatim from each lane's log (the C3 record §6 has the same
lines at the same numbers — derived comparison: every count equal):

| Lane | Verdict |
|---|---|
| A2 exec minimal | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A3 exec coverage | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4 exec debug | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4b exec float | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4c bytes | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| A5 libc_exec | `SUMMARY: match=11 diff=0` / `ALL MATCH RECORDED BASELINE` |
| A6 multi_tu | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| A7 parse | `Cerberus parse: 106 ok, 0 failed` / `Lean parse:     106 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal)` / `Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A8 core | `Total:          106` / `Cerberus --pp:  106 ok, 0 failed` / `Lean parse:     106 ok, 0 failed` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A9 elab | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` (the recorded state) |
| A10 uri | `[ocaml-nolibc] exit=1: Error {msg: "ill-formed program: `+"`"+r`calling an unknown procedure: Symbol(1451, SD_Id("memset"))'"}` / `[lean-nolibc] exit=1 wall=0:01.13 maxRSS=234004kB: Error {msg: "ill-formed program: `+"`"+r`calling an unknown procedure: Symbol(968, SD_Id("memset"))'"}` / `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| A11 cn_coverage | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |
| B1 libxml2 | `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED` |
| B2 parse ci | `Cerberus parse: 247 ok, 3 failed` / `Lean parse:     128 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal)` / `Lean front end: 117 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 2 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   51% (of cerberus successes)` / `ALL PASSED` |
| B3 core ci | `Total:          250` / `Cerberus --pp:  128 ok, 122 failed` / `Lean parse:     128 ok, 0 failed` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| B4 verify | `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)` |
| B5 immaculate | `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store …` |
| B6a speclab --selftest | `test_speclab: PASS (both pipelines agree on Specified(0))` |
| B6b speclab --plant | `test_speclab: PASS (both pipelines agree on Specified(2))` |
| B6c divmod | `CoreGateTest: ALL PASSED` / `test_speclab_divmod: PASS (--gate)` |
| B6d bytearr | `ByteArrGateTest: ALL PASSED` / `test_speclab_bytearr: PASS (--gate)` |
| B6e list | `ListGateTest: ALL PASSED` / `test_speclab_list: PASS (--gate)` |
| B6f tree | `TreeGateTest: ALL PASSED` / `test_speclab_tree: PASS (--gate)` |
| B6g seed | `SeedGateTest: ALL PASSED` / `test_speclab_seed: PASS (--gate)` |
| B7 gcc | `SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1` / `Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle lane OK` (= the C3 quiet-box re-run row for row; the load caveat did not fire: load average fell to ~12 during this lane) |
| B8a hang plant | `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)` |
| B8b kill plant | `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)` |
| B8c fuel plant | `test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)` |

Final stamps (`tools/check_driver_fresh.sh --check`, rc 0, after the last
lane): `oracle OK (bin eff14bc4…, src 7f1a0c0a…)`, `lean OK (bin 00edd6fd…,
src e9f05dfb…)`.

### 5.3 Observation (not a movement): the oracle binary was relinked from unchanged sources

Before the slice `--check` reported `oracle OK (bin 28fb2198…, src
7f1a0c0a…)`. The first lane's `build_cerberus` (`dune build
backend/driver/main.exe …`, incremental) relinked `main.exe` at 06:56:26
and re-recorded `oracle OK (bin eff14bc4…, src 7f1a0c0a…)` — the SAME
source hash (no OCaml or `.lem` file changed in this slice; the lem-sync
stamps are unchanged). Every subsequent lane ran on `eff14bc4…`. The source
set the stamp hashes is unchanged, so the freshness gate's guarantee
("the binary corresponds to its sources") holds throughout; the relink
itself is dune's incremental decision on an input outside the hashed set
— the likely one is the SHARED opam switch (`_opam` → the primary
checkout's), whose `lib/cerberus-lib` and `stublibs` are rewritten by
every `dune install cerberus-lib` from any checkout (the primary's refresh
was running concurrently; this worktree's own lanes rewrote them at 07:03).
Recorded because a binary hash moving without a source change is exactly
the class the stamp exists to make visible; no lane moved. If the operator
wants it closed, the fix is outside this slice (the stamp's source set
does not cover the switch; the worktree recipe shares it by design).


## 6. Consumer note (refined-cerberus)

- The switch-independence argument (`cerberus-heaplang/README.md:585-600`:
  "the Lean `CerbMem` references no `CerbGlobal` constant, so
  `loadM`/`storeM`/`allocateObject`/`eqPtrval` are switch-independent by
  construction") was FALSE at mainline since Z1 (`killM` reads
  `has_switch .forbid_nullptr_free` / `.zap_dead_pointers`; `ptrfromint`
  reads `is_PNVI ()`). It is TRUE again at this head, with a different
  proof: the reads exist and UNFOLD — `CerbGlobal.has_switch_eq sw :
  has_switch sw = false`, `CerbGlobal.is_PNVI_eq : is_PNVI () = false`,
  both `rfl`; a `simp only [CerbGlobal.has_switch_eq, CerbGlobal.is_PNVI_eq,
  Bool.false_eq_true, ↓reduceIte]` (or `decide`) closes each switch test.
- `driver2_done`'s `cases` on the scheduler-mode read (their
  `DriverCollapse.lean:64, 709`) becomes `rw
  [CerbGlobal.current_execution_mode_eq]` + `if_neg` — exactly the
  in-repo exemplar's change (§3).
- Names and types are unchanged; nothing in the generated tree moved (the
  Lean tree differs from the C3 head ONLY in `generated/CerbGlobal.lean`,
  the seam's copy). Change manifest with the full lemma list:
  `2026-09-05_cerbglobal-defs-change-manifest.md`.

## 7. Not done / for the operator

1. **Step 2** (the configuration as a reader-lifted parameter like
   `tagDefs`, `declare {lean} reader val` on the `Global.*` reads in
   `global.lem`) is NOT this slice; it is the named mover of the former
   allowlist class. Per `docs/2026-09-04_concurrency-scoping.md` §4 (the
   concurrency branch's worktree copy; the file is not on mainline), "the
   feature branch OWNS A-step-2 for `using_concurrency` only; A step 1 for
   the rest stays sequential" — so `using_concurrency`'s parameterisation
   belongs to `feature/concurrency`; for step 1 it is the constant `false`
   (the oracle's `--concurrency` flag default; refused here, Z-24). The
   remaining ten reads' step 2 is a sequential slice to charter (§2.A
   "Step 2 (M)").
2. **`current_execution_mode` under `--first`** (§2.1): a step-2 question
   — whether the single-trace runner should supply `some .random` (the
   oracle's `--mode=random` default) to `driver.lem:1380`. Behaviour-
   changing; not decided here.
3. **Merge-conflict note**: `feature/concurrency` has edited
   `test/Unit/FuelExemplar.lean` (48+/18−, derived from its worktree's
   `git diff 928aa1e76 --stat`); this slice's edit there is the
   `driver2_done` hunk + two header sentences. Their rebase will meet it.
4. The audit doc §2.A itself is a dated record and is not edited; the
   status pointer lives in `TODO.md` (the effect-retirement item) and
   `VALIDATION.md` (the trust-boundary list and the gate row).

## 8. Commits

1. `016b2a6ea` — "CerbGlobal: the switch/config surface becomes plain defs
   of the default configuration (reasoning-artifact audit A, step 1)":
   `lean_frontend/CerbGlobal.lean`, `lean_frontend/test/Unit/FuelExemplar.lean`,
   `scripts/unsafebaseio_allowlist.txt`, `scripts/check_theorem_axioms.sh`,
   `scripts/check_exec_purity.sh` (comment), `lean_frontend/VALIDATION.md`,
   `lean_frontend/CLAUDE.md`, `lean_frontend/TODO.md` — committed after the
   full battery above (§5) was green on this exact tree (the working tree
   at commit time = the tree the battery ran on; `git status` showed only
   these eight files modified plus the two untracked docs).
2. (this commit) — the record and the consumer change manifest
   (`2026-09-05_cerbglobal-defs-record.md`,
   `2026-09-05_cerbglobal-defs-change-manifest.md`). Docs only.

Nothing merged; nothing pushed; `mdd/cerberus-lean` and `master` untouched.
The `.tmp/cg/` logs are deleted at slice end (everything quoted above is
in this record).
