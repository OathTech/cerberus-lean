# Arc 7 / S3 — Layer 2 to slate strength (worker record)

Date: 2026-08-20. Provenance: [AGENT:S3] unless marked. Commits:
`3a184648d` (harness + fixtures), `a3b4c4112` (Step coverage by need),
`cb9b8d3c7` (fuel-erasure + reachability layer).

## 1. The symbolic-argument harness (RelSem/Call.lean)

`callND tagDefs file1 fname args : driverM driver_result` — the
`drive` (Driver.lean:500) generalization, two substitutions:

1. startup symbol resolved from the designated NAME over `file.funs`
   (`SD_Id` match; no-match and ambiguity are explicit `kill`s);
2. `prepare_main_args` replaced by the general CALLER PROTOCOL:
   under the Normal calling convention the elaborator compiles
   `int f(int x)` to a Core proc whose parameter is a POINTER — the
   call site allocates at the parameter's C type, stores the converted
   value, passes the pointer (verified on the elaborated Core of
   tests/verify/t1_id.c: `create(Ivalignof('signed int'),…)` +
   `store(…, conv_loaded_int(…))` at the call site, `proc id
   (x: pointer)`). `injectArg` reproduces it exactly: pointer-typed
   params (`BTy_object OTy_pointer`) get `CerbMem.allocateObject` at
   the funinfo-declared ctype + `CerbMem.storeM` of
   `memValueFromValue tagDefs ty v`; non-pointer params pass the value
   through. Fidelity note: the call-site `conv_int` range conversion is
   NOT reproduced — an injected integer must fit the parameter type
   (exactly the slate's range precondition `P args`); an ill-typed
   value is an explicit `kill`, never a silent coercion.

`callConfig tagDefs file1 fname args fs : DriveConfig` — the
`initConfig` generalization. QUANTIFICATION ENTERS HERE: the slate's
`∀ x : Int` binds `args := [intValue x]`
(`intValue n = Vloaded (LVspecified (OVinteger (integerIval n)))`);
arguments are data of the statement, never constants of the program.

PARAMETRICITY HELD: `callConfig` is a `seqModel` configuration; every
statement shape (`CallAdequate`, `CallUBFree`) is
`ExecModel.Adequate`/`.UBFree` at `callConfig`; Layer 3 consumes the
interface only. ONE ARTIFACT: `cerberus-lean --call f --call-args
n,…` runs `CerbND.runND` on this same `callND` (Main.lean), so the
concrete differential exercises the exact object the theorems
quantify.

Staged into combinator-sized defs for the S4/S5 proof walk:
`resolveFunSym`, `lookupFunBody`, `lookupParamTys`, `injectArg(s)`,
`callFinish`.

## 2. Fixtures + concrete differential (tests/verify, scripts/test_verify.sh)

T1 `id` / T2 `add` / T3 `roundtrip` / T4 `memb` (struct S member
write/read — the exit-criterion target) / T5 `sum` (bounded loop);
each `.c` also carries a concrete `main`. All five verified end-to-end
BEFORE any harness code (pipeline: `cerberus --cabs-json` →
`cerberus-lean --batch`).

`./scripts/test_verify.sh` (fail-closed; suggested ladder placement:
reporting instrument until the orchestrator promotes it): 5/5
main-mode differentials byte-equal vs the OCaml oracle
(`--nolibc --exec --batch --mode=exhaustive`), and 18/18 harness
concrete points vs the recorded pure spec
(tests/verify/expectations.txt), including the T2 spec-discovery rows:
`add(2147483647,1)` and `add(-2147483648,-1)` → `UB036_exceptional_condition`
(the UB-freedom obligation that FORCES the no-signed-overflow
precondition, exactly as the charter's slate table predicted).

## 3. Step coverage by need — the trace evidence and the finding

Instrument: `cerberus-lean --trace-nodes [--call …]`
(`CerbND.runND1Trace`, fuel-totalized branch-0 runner returning the
ND-node labels crossed).

EVIDENCE: every T1-T5 execution — main mode and call mode — crosses
exactly ONE ND-tree node: `NDactive` (`NDkilled` on the T2 overflow
instance). Causes in the generated code: `nd_bind` collapses ACTIVE
heads inside one `app` unfolding (Nondeterminism.lean:169), and `pick`
on a SINGLETON candidate list builds `NDactive`, not `NDnd`
(Nondeterminism.lean:257) — the driver loop's
`pick (SK_misc ["driver 2"]) tid_steps` always sees a singleton on a
single-threaded run. Cross-check: the exhaustive runner prints exactly
one execution per fixture (no `EXECUTION k:` headers).

FINDING [AGENT:S3]: no new `Step` ARMS are needed for T1-T5 — the
7-rule relation is node-kind-complete and these runs traverse exactly
`active`/`killed`. The by-need work is the APP-EQUATION layer
(Machine.lean § Coverage-by-need): state-combinator equations
(`app_nd_return/kill/nd_get/nd_put/nd_update/nd_read/print_debug/
nd_guard_true/false`, all rfl), `app_pick_singleton` (the keystone),
kill propagation (`app_bindFuel_killed`/`app_bind_killed`/
`step_bind_killed`; `liftKill` + `app_liftFuel_killed`/
`app_liftND_killed`; driver-level `liftMem_step_killed` in
Cerberus.lean), and done-inversion (`step_done_inv`,
`step_done_value_inv`, `step_done_killed_inv`).

Escalation-rule log: NO escalation events — every proof in this slice
is rfl, one simp-rewrite, or a two-arm cases; nothing case-bashed,
no missing rule encountered.

## 4. Fuel erasure + reachability (the slate's last mile)

Terminal-head outcome-set characterization (RunND.lean; DAEMON-free,
[propext]-grade): `runNDFuel_active/killed` (the enumeration is the
SAME singleton at EVERY positive fuel), `runND_active/killed` (default
budget), `behaviors_active_iff/killed_iff` (∃-fuel extraction =
default budget = exhaustive verdict set, exactly). Model face
(Cerberus.lean): `seqModel_behavior_running_active_iff/_killed_iff`.

callConfig corollaries (Call.lean) — the shapes S5's adequacy
discharge consumes:

* `callReaches` — `(Active r,tr,st') ∈ runND (callND …) init →
  DSteps (callConfig …) ⟨done (value r), st'⟩` (runND_sound at the
  harness);
* `callOutcomes_sound` — every seqModel behavior of `callConfig` is
  Steps-reachable;
* `callAdequate_of_reach` — relational coverage ⇒ `CallAdequate`;
* `callHarnessAdequate_of_adequate` — `CallAdequate` at the
  value-shaped spec ⇒ the CerbND-shaped headline
  (`CallHarnessAdequate`, statement-TCB: fuel opsem only);
* direct-computation route: `callAdequate_of_app_active`,
  `callUBFree_of_app_active`, `callHarnessAdequate_of_app_active` —
  ONE ∀-quantified `app` equation ⇒ every slate statement shape.

Fuel-hook inventory (RelSem/FuelHooks.lean, 30 rfl wrapper-defeq
theorems; enumeration method + off-path exclusions in the file
header): spine `nd_bind`/`liftND`/`liftAction`; Driver
`drive_nonmemory_steps_aux2` (+ `driver2`, `step_eval_pexpr` hooks
already in Cerberus.lean; `runND` hook in RunND.lean); Core_eval
`eval_pexpr_aux2`, `pull_constrained`; Core_reduction
`full_eval_pexpr`, `get_ctx`, `get_ctx_unseq_aux`, `has_ccall`,
`one_step_unseq_aux`; Core_aux `match_pattern`, `in_pattern`,
`subst_pattern(_val)`, `subst_sym_(p)expr`, `unsafe_subst_*`,
`update_env_aux`, `find_labeled_continuation(2_aux)`,
`(m_)collect_saves_aux`, `to_pure(s)`, `loadedValueFromMemValue`,
`memValueFromValue`, `zeros_aux`.

## 5. Axiom discipline (pins in RelSem/Audit.lean, exact sets)

DAEMON-free layer: `runND_active/killed`, `behaviors_*_iff`
([propext]); `step_done_inv`, `ofStatus_value_inv`,
`nd_bind_wrapper_defeq` (axiom-free); `seqModel_behavior_running_*`
(classical trio). Substrate-mentioning (DAEMON [+ runEffectful via
`initial_driver_state`] through the QUOTED generated bodies, the
standing D3 disposition — no relsem source names them):
`callReaches`, `callOutcomes_sound`, `callAdequate_of_reach`,
`callHarnessAdequate_of_adequate`, `call*_of_app_active`,
`liftMem_step_active/killed`, `app_pick_singleton` (DAEMON via pick's
compiled failwith fallback). Sweep: 378 declarations, boundary held,
0 sorryAx exceptions.

## 6. Validation (zero movement)

Tier A green at each commit: unit 4/4 (sync gate 22 files, census 2,
purity/totality CLEAN, D14 grep, theorem-axiom cones), exec baselines
minimal/coverage/debug `BASELINE OK` 0 regressions, libc_exec 7/7,
multi_tu 2/2, parse ALL, core ALL, elab 103/3 recorded state,
uri 16/16 GATE PASS; `lake build` (all targets incl. the in-build
audit) green; test_verify 23/23. Tier B chvalid battery run
belt-and-braces at slice end (result recorded in the S3 report).

## 7. Handles for S4/S5

* Slate statement template instance (T1 shape):
  `∀ x : Int, intRange x → CallHarnessAdequate tagDefs F "id"
  [intValue x] fs (fun r => r.dres_core_value = intValue x)` — where
  `F` is t1_id's compiled Core file value; discharge via
  `callHarnessAdequate_of_app_active` from the ∀-quantified app
  equation, or via the WP route through
  `callAdequate_of_reach`/`callHarnessAdequate_of_adequate`.
* The app equation is computed with: bind congruence
  (`app_bind_active`/`_killed`), lens (`app_liftND_active`/`_killed`),
  state combinators, `app_pick_singleton`, and the FuelHooks to move
  onto fuel-generic workers where induction is needed (driver2's loop).
* OPEN (priced for S4): no per-iteration loop lemma for `driver2` yet
  (T5's arm) — the loop is fuel'd binds with active heads, so each
  iteration is app-computation, not Step-multiplicity; if the T5 proof
  wants an invariant-style rule it belongs at the app/WP level.
