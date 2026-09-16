# Record — Lean-only outcomes, S0 checkpoint: probes and prototypes (charter `2026-09-16_charter-lean-only-outcomes-S0-checkpoint.md`; run 2026-09-16)

**Branch:** `arc/lean-only-outcomes-S0` (worktree `worktrees/cerberus-lean-arc/lean-only-outcomes-S0`), on the mainline `mdd/cerberus-lean` = `721b1c2c7`; HEAD at launch `7e4c23709` (the charter). **Worker:** a Claude Fable 5.1 subagent in fresh context ([USER 2026-09-11] "launch them as claude fable class subagents"). **Nature:** a PROTOTYPE branch — every `.lem`/OCaml/Lean edit here is a probe that does NOT land; this record and the protocol addendum are what the orchestrator cherry-picks. **Provenance:** quoted outputs are verbatim; derived tallies are labelled; judgments are [AGENT]; operator words only as the charter §0 quotes them. Evidence directory: `2026-09-16_lean-only-outcomes-S0-checkpoint-evidence/` (plain text).

This record is written INCREMENTALLY — each deliverable's evidence is appended as soon as it exists and committed with that deliverable, so a killed session leaves a self-describing branch.

Launch state (verbatim): `bash tools/check_driver_fresh.sh --check` →
```
check_driver_fresh: oracle OK (bin 7336b2e35e761cd553dcd196e944da00bcd981a0a2c512d10926c3bb91723478, src 98ad48b592a222a21e4619c5ce03652fc6a44c0a67c6b02cb222e1d40b1c701d)
check_driver_fresh: lean OK (bin 5f6dfacf25852e7eedb386345ee641317eb03448688cd768974332962a2aa2ab, src c805823c3a54a24e82398a2ca27ea2018416ef873ceaca4d03091f9603a1086a)
```
`git status --porcelain` empty; `scripts/ce lem -v` → `Lem f6542f8`.

## 0. Reading-list verification — where the tree and the charter differ [AGENT]

Every §1 fact touched was re-read in the tree before use (2026-09-16). Differences found:

1. **Charter §1 row 2, "`kill_reason`'s default is `Error0 default default`" — WRONG as written.** The generated `Nondeterminism.lean:65-70` emits the PRIMARY instance `instance {err : Type} : Inhabited (kill_reason err) where default := Undef0 default default` at default priority with NO bound (`Undef0`'s fields `Loc`/`List` are unconditionally inhabitable, so it is the first USABLE constructor), then `Error0 default default` and `[Inhabited err] → Other default` at `low`. The primary always wins. Kernel fact on the mainline artifacts (probe `…-evidence/S0_1_ProbeBefore.lean`, output verbatim in `…/S0_1_probe_before.txt`): `(default : kill_reason err) = Undef0 default default` by `rfl` and `(default : t0 a) = Error default default` by `rfl`, both `does not depend on any axioms`. Consequence for the hazard: appending `Stopped` at `low` priority cannot change `kill_reason`'s default (a `low` instance never beats the unconstrained primary); the hazard is confined to `t0` at an UNCONSTRAINED payload (where only `low` instances compete and Lean prefers the LAST declared). The review's finding 1 stands for `t0`; its "has the same exposure" sentence about `kill_reason` and the charter's row are corrected here. Observed after the extension in S0.1(a) below.
2. **`lean_frontend/CLAUDE.md` "`declare {lean} skip_instances type T` … `ctype.lem` — ctype_/ctype"** — there is NO live `skip_instances` declare anywhere in `frontend/` (`grep -rn skip_instances frontend/` → only the NOTE at `core_reduction.lem:144` saying it is NOT used). `CerbCtypeInstances.lean` overrides by priority/declaration order via `extra_import`, not by `skip_instances`. So the S0.1 candidate is the FIRST use of `skip_instances` in this repo; the only in-repo precedent is the lem-lean test `tests/comprehensive/test_instances.lem:177-178` (`skip_me`).
3. **Hand-written OCaml matching the kill constructors** is wider than the charter's `driver_ocaml.ml:37-182, :217` cite: `backend/common/driver_ocaml.ml:173-182` (batch), `:214-220` (a COMMENTED-OUT block inside `drive`), `:281, :306, :309` (the human printer in `drive`), and `backend/common/smt.ml:616-620` (`Tkilled` rendering in the graph dumper). `backend/ocaml/runtime/rt_ocaml.ml:298-308` matches `Undefined.t` but its `dune` is entirely commented out (dormant, like `interactive_driver.ml`/`cerbcore.ml`). Classified in S0.2.
4. **The Makefile's lem invocation passes `-wl_pat_exh warn`** (`Makefile:222, :349`): lem's OWN exhaustiveness check is a warning written to `ocaml_frontend/lem.log` / `lean_frontend/lem.log` (the recipe prints the log only on lem failure). Observed in S0.2.

Facts verified as stated: `nondeterminism.lem:24-27` and `undefined.lem:1424-1427` (the two types); `nondeterminism.lem:255-270` live, `:297-543` a comment; `exception_undefined.lem:12-22, :31-34`; `state_exception_undefined.lem:15-25, :31-34, :38-48`; `driver.lem:145-160, :178-186, :412-444, :1453-1460, :1910-1913`; `formatted.lem:412, :485, :744, :836`; `core_run.lem:165, :1380`; `ocaml_frontend/dune:7` (`-w @8…`), `backend/common/dune:5-7` (`-w -27`, excludes `cerbcore interactive_driver`); the 13 `fuel` declares; `Main.lean:1070-1087`; `observations.py:40-51, 107-143, 178-184`; `fuel_classify.sh:47-56`; `FuelFormsTool.lean:306-308`; `handwritten_copy.manifest` (48 files); lem `f6542f8`.

## S0.1 — The default-policy probe

**Probe edits (this branch only; do not land).** `frontend/model/interp_stop.lem` (new; `open import Pervasives` only): `type unsupported_feature = UF_filesystem | UF_concurrency | UF_switches`, `type interp_stop = Exhausted | FailStop of string | Unsupported of unsupported_feature * string`. `undefined.lem:4` `import Interp_stop`, `:1429` `| Stopped of Interp_stop.interp_stop` on `type t`; `nondeterminism.lem:15` `import Interp_stop`, `:29` `| Stopped of Interp_stop.interp_stop` on `type kill_reason`. `Makefile:140` adds `interp_stop.lem` to `LEM_PRELUDE` (before `LEM_CABS`, which holds `undefined.lem`: lem resolves imports in list order); `lean_frontend/lakefile.toml:109` adds the roots `"Interp_stop", "Interp_stop_auxiliary"` (the `check_lakefile_roots` requirement).

**Regeneration, both targets, pinned lem `f6542f8`** (`.tmp/s01a-regen2.log`, verbatim key lines):
```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src f888eac9310a4190883dfa0c4f1dced21834f66a693ec546bc40e86cf2f7b9f0, gen 5dc044e8f0acbc47024d6a246365f73fb1e0c303d782795a11dbb4ccc05035ea)
prelude-src rc=0 dur=18s
check_handwritten_sync: OK (48 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src f888eac9310a4190883dfa0c4f1dced21834f66a693ec546bc40e86cf2f7b9f0, gen 7392493f240fd849d94b1d2b178ed64df57e6a3b8766f28ef858bb9d395af7e9)
lean-prelude-src rc=0 dur=20s
```
Lem renames: `Warning: renaming 'Stopped' to 'Stopped0' for target ocaml` / `for target lean` at `nondeterminism.lem:29` — so the pure channel's constructor is `Stopped` and the kill channel's is `Stopped0` on BOTH targets (the review's probe fact, confirmed on production). Gotcha for S1 [AGENT]: lem re-encodes non-ASCII bytes in `.lem` comments (a `§` in my first header came out as bytes `c3 82 c2 a7` in both generated files) — keep `.lem` comments ASCII.

### S0.1(a) — the hazard on the PRODUCTION types (observed)

Generated instances, verbatim (`…-evidence/S0_1_generated_after_a.txt` has the full excerpts; the OCaml side there too):
```
-- lean_frontend/generated/Interp_stop.lean
instance : Inhabited (interp_stop) where
  default := Exhausted
-- lean_frontend/generated/Undefined.lean
instance {a : Type} [Inhabited a] : Inhabited (t0 a) where
  default := Defined default
instance (priority := low) {a : Type} : Inhabited (t0 a) where
  default := Undef default default
instance (priority := low) {a : Type} : Inhabited (t0 a) where
  default := Error default default
instance (priority := low) {a : Type} : Inhabited (t0 a) where
  default := Stopped default
-- lean_frontend/generated/Nondeterminism.lean
instance {err : Type} : Inhabited (kill_reason err) where
  default := Undef0 default default
instance (priority := low) {err : Type} : Inhabited (kill_reason err) where
  default := Error0 default default
instance (priority := low) {err : Type} [Inhabited err] : Inhabited (kill_reason err) where
  default := Other default
instance (priority := low) {err : Type} : Inhabited (kill_reason err) where
  default := Stopped0 default
```
`lake build Interp_stop Undefined Nondeterminism` (capped, 48G): `Build completed successfully (42 jobs).` in 6 s. Kernel facts (probe `…-evidence/S0_1_ProbeAfterA.lean`, output verbatim in `…/S0_1_probe_after_a.txt`):
```
'afterA_t0_default_is_stopped_exhausted' does not depend on any axioms      -- (default : t0 a) = Stopped Exhausted := rfl
'afterA_kill_reason_default_is_undef0' does not depend on any axioms        -- (default : kill_reason err) = Undef0 default default := rfl
'afterA_t0_nat_default_is_defined' does not depend on any axioms            -- (default : t0 Nat) = Defined 0 := rfl
'afterA_interp_stop_default' does not depend on any axioms                  -- (default : interp_stop) = Exhausted := rfl
```
**The hazard is REPRODUCED on the production `Undefined.t`**: at an unconstrained payload the derived default becomes `Stopped Exhausted`. It does NOT reach `kill_reason` (record §0 item 1: the unconstrained primary `Undef0 default default` wins at every instantiation) and it does not reach `t0` at a concrete inhabited payload (`Defined default` wins). [AGENT] The exposure is therefore exactly: every `failwithI`/`L_undefined` site of type `t0 α` inside a definition polymorphic in `α` with no `[Inhabited α]` binder — the backend threads `[Inhabited tv]` binders through definitions whose failure sites sit at bare-tyvar positions (`lean_backend.ml` arc-8 S2), so which pure sites actually elaborate against the unconstrained fallback is a census question for S1 (the failure-reach register keys them).

### S0.1(b) — the `skip_instances` candidate (observed: FAILS)

**Applied:** `interp_stop.lem`: `declare {lean} skip_instances type interp_stop`; new seam `lean_frontend/CerbStopInstances.lean` (manifest + Lake root; hand-written OCaml-parity `BEq`/`Ord` — rank `Exhausted < FailStop < Unsupported`, fields left-to-right — and the `SetType`/`Eq0`/`Ord0` trio at priority 500, deliberately NO `Inhabited interp_stop`); `undefined.lem:8` `declare {lean} extra_import `CerbStopInstances``. `unsupported_feature` kept its derived instances (not `skip_instances`; duplicates would only be redundant same-priority instances — a deviation from the charter's "for interp_stop and unsupported_feature", [AGENT]).

**Regeneration:** both targets `rc=0` (19 s / 21 s; `check_handwritten_sync: OK (49 hand-written files …)`). **No generation-time `Inhabited` demand fired**: `lean_frontend/lem.log` has no line mentioning `interp_stop` or `Inhabited` (evidence `…/S0_1_candidate_b_failure.txt`, last block).

**What the backend emitted** (verbatim): `generated/Interp_stop.lean` lost the `Inhabited` instance and the 500-trio for `interp_stop` but KEPT `deriving BEq, Ord` on the inductive; `generated/Undefined.lean:1863-1864` and the `kill_reason` block STILL contain
```
instance (priority := low) {a : Type} : Inhabited (t0 a) where
  default := Stopped default
…
instance (priority := low) {err : Type} : Inhabited (kill_reason err) where
  default := Stopped0 default
```
**Lean build** (`lake build Interp_stop CerbStopInstances Undefined Nondeterminism`, capped 48G, `rc=1`, 5 s), verbatim:
```
✔ [40/43] Built Interp_stop (205ms)
✔ [41/43] Built CerbStopInstances (168ms)
✖ [42/43] Building Undefined (4.0s)
error: generated/Undefined.lean:1864:21: failed to synthesize instance of type class
  Inhabited interp_stop

Hint: Adding the command `deriving instance Inhabited for interp_stop` may allow Lean to derive the missing instance.
error: Lean exited with code 1
```
So the two `rfl` pins the charter expected (`Error default default` / `Undef0 default default` under the candidate) could NOT be stated: the cone does not build. The `Undef0` pin holds regardless (S0.1(a)); the `t0` pin is the one the candidate was to deliver and does not.

**Why, precisely** [AGENT, from the read-only backend source at `f6542f8`]: the tier-2 plan (`lean_backend.ml:1513-1522`) admits a constructor when `derive_fields_bounds` succeeds on every field; for a field of type `Typ_app interp_stop` (`:1466-1471`) it looks the path up in the Inhabited CENSUS; the prepass (`:1580-1582`) builds `active` by FILTERING OUT every type for which `skip_inhabited_for_type_env` holds (`:1535-1543`: `skip_instances` for Lean, `Te_abbrev`, or a Lean `target_rep`) and records NOTHING for it — so the lookup returns `None`, and `:1471` falls through to `lean_builtin_inhabited_entries` (`:474-478`) whose default for any head not `either`/`vector` is `[[]]`: "assume an unconditional instance exists … if it is wrong, Lean reports a loud 'failed to synthesize' error at the emitted instance" (its own comment, `:466-473`). That is exactly what was observed: the constructor is treated as USABLE, the fallback instance is emitted, and the failure surfaces at Lean build time, not at generation time (`inhabited_demand_check`, `:7185-7193`, only fires on a census entry `Inh_none`, never on an ABSENT one). Consequences: (i) `skip_instances` cannot express "not a default candidate" — the SAME code path makes a `declare lean target_rep type interp_stop` fail identically (`skip_inhabited_for_type_env` is true for it too; code-derived, not run); (ii) there is no honest encoding within the existing mechanisms either: a type is census-`Inh_none` only when NO constructor has derivable fields, which for a type that must be constructible means every constructor carries an underivable (self-referential) field — i.e. no values — so every in-model trick is an epicycle of the kind [USER 2026-09-16] warned against; (iii) a second discrepancy against `lem-lean/doc/lean-backend/DESIGN.md:494` ("suppress all instance generation for `t`"): `skip_instances` leaves the `deriving BEq, Ord` clause in place (also true of the lem-lean precedent `tests/comprehensive/Test_instances.lean:1210-1214`, `skip_me … deriving BEq, Ord`), so a hand-written `BEq`/`Ord` pair DUPLICATES the derived one (the later-declared one wins in importing modules). Neither finding is fixed here (charter §3: lem-lean is read-only); both go to the lem-lean side.

### S0.1(c) — the minimal backend declare (sketch; NOT implemented)

The policy "an administrative stop is never a default value" needs the census to hold a NEGATIVE entry for `interp_stop`. Minimal declare, mirroring `skip_instances`' plumbing exactly:

`declare {lean} inhabited_exclude type interp_stop` — semantics: (1) `lean_inhabited_prepass` records the type as `Inh_none` in the census (one `inhabited_census_add path name Inh_none` for excluded types, alongside the `active` filter at `lean_backend.ml:1580-1582`) and emits NO `Inhabited` instance for it (its other derived instances unaffected — so no seam, no duplicate `BEq`/`Ord`); (2) by the EXISTING rule `:1469` (`Some (_, Inh_none) -> []` → the constructor is unusable), every constructor with an `interp_stop` field — `Stopped`, `Stopped0` — drops out of the tier-2 plan and both outcome types keep today's defaults (`Error default default` / `Undef0 default default`); (3) by the EXISTING `inhabited_demand_check` (`:7185-7193`), any backend-visible demand for a default of `interp_stop` (a `failwithI` at that type) is a GENERATION-TIME error naming the type — fail-closed, and the intended behaviour (a stop must be constructed explicitly or not at all). Plumbing: a `Targetset` flag on the type definition like `Types.type_skip_instances`, the parser keyword, one prepass branch, a `tests/comprehensive` reproducer + a `lean-test` pin that `(default : t a) = <the pre-existing fallback>` — [AGENT] estimate: a small lem-lean slice (tens of lines), the scoping note R1.3's "paired slice"; no cerberus-side workaround exists. Alternative rejected [AGENT]: changing `skip_instances` itself to record `Inh_none` would break every user that hand-writes `Inhabited` for a skipped type (there are none in this repo, record §0 item 2, but lem-lean's tests assume the current meaning) and conflates two intents.

**Configuration for S0.2/S0.3:** the tree is returned to (a) — `skip_instances` and the `extra_import` withdrawn (a comment in `interp_stop.lem:17-24` records why), the seam `CerbStopInstances.lean` kept in the tree as the record's artifact (manifest + root, imported by nothing) — so both targets build and the default hazard is PRESENT on `t0`. `test/Unit/StopDefaultsTest.lean` (lean_exe `stop-defaults-test`, added to `scripts/test_unit.sh`'s list) pins the OBSERVED state with the hazard theorem first; S1 flips that theorem to `Error default default` once the backend declare exists.

**S0.1 verdict [AGENT]:** the default policy that works is "exclude `interp_stop` from the Inhabited census by a backend declare"; no policy expressible with today's `lem f6542f8` keeps `Undefined.t`'s default at `Error default default` once `Stopped of interp_stop` is appended. Per charter §3's stop rules this is "needing a lem-lean change to proceed" for S1 — RECORDED, not made; S0.2–S0.6 proceed on configuration (a) as the charter's §2 allows (S0.2 needs only that both targets build).

## S0.2 — The compiler-discovered propagation inventory

**Method as run [AGENT].** Each OCaml pass = edit the `.lem`/OCaml sites the compiler had just named → `make prelude-src` (17-39 s) → `dune build backend/driver/main.exe cerberus-lib.install` (0-5 s; dune's digest tracking recompiles only modules whose generated text changed). The OCaml compiler stops at the first failing MODULE and dune does not attempt its dependents, so the inventory came out module by module — the charter's "one at a time" at module granularity, every arm compiler-forced (evidence `…/S0_2_ocaml_pass1.txt` … `pass6-8.txt`, verbatim). Nothing was added ahead of the compiler. Lem's own `-wl_pat_exh warn` (`Makefile:222/:349`) had already listed 13 sites in `lem.log` on both targets (`…/S0_2_lem_missing_arms.txt`); the compiler confirmed exactly those 13 in generated OCaml and added the hand-written OCaml the lem check cannot see.

**How each target treats a `.lem` match lacking the new arm** (`…/S0_2_lem_rendering_of_missing_arm.txt`, verbatim there):
- **OCaml target:** lem emits the match as written — non-exhaustive — and `ocaml_frontend/dune:7`'s `-w @8…` makes it an ERROR (`Error (warning 8 [partial-match]): this pattern-matching is not exhaustive. Here is an example of a case that is not matched: Stopped _`). **Correction to the charter §1 / review §4:** `backend/common` is fatal on warning 8 TOO — its stanza `(flags (:standard -w -27))` only disables 27, and dune's dev profile gives `:standard` = `-warn-error +a` (`dune printenv backend/common`, verbatim: `(flags (-short-paths -keep-locs -warn-error +a -bin-annot))`); the driver_ocaml.ml sites were reported as `Error (warning 8 …)`, not warnings.
- **Lean target:** lem's pattern compiler ADDS a wildcard arm, e.g. `generated/Undefined.lean` `def bind2`: `… |  Stopped  _ =>  (failwithI "Incomplete Pattern at File \"frontend/model/undefined.lem\", line 1436, character 3 to line 1440, character 3" : t0 b)`. So **the Lean build does NOT fail on a missing `.lem` arm**: it compiles a runtime `failwithI` (a panic message, then the `Inhabited` default of the result type). [AGENT] In configuration (a) that default at an unconstrained `t0 b` is `Stopped Exhausted` (S0.1(a)) — a missing arm would turn ANY stop (a `FailStop`, an `Unsupported`) into a panic line plus an EXHAUSTION value. Consequence for S1: the OCaml build is the only compiler that enforces the `.lem` arms; lem's `lem.log` warnings are the cross-check (S1 should grep `lem.log` for `missing patterns` mentioning `Stopped` and fail on any hit — a cheap gate).

### The compiler-forced inventory (generated OCaml; every arm also removes the Lean-side `failwithI` wildcard)

| # | pass | `.lem` site (after the edit) | arm added (verbatim) | kind |
|---|---|---|---|---|
| 1 | 1 | `undefined.lem:1439` (`bind`) | `\| Stopped s -> Stopped s` | propagation |
| 2 | 1 | `undefined.lem:1465` (`fmap`) | `\| Stopped s -> Stopped s` | propagation |
| 3 | 2 | `exception_undefined.lem:20-21` (`exception_undef_bind`) | `\| Exception.Result (Undefined.Stopped s) -> Exception.return (Undefined.Stopped s)` | propagation |
| 4 | 2 | `nondeterminism.lem:268-269` (`liftAction`, the live one) | `\| Stopped s -> Stopped s` | propagation |
| 5 | 3 | `state_exception_undefined.lem:23-24` (`stExceptUndef_bind`) | `\| Exception.Result (Undefined.Stopped s, st') -> State_exception.return (Undefined.Stopped s) st'` | propagation (state kept) |
| 6 | 3 | `state_exception_undefined.lem:48-49` (`runEU`) | `\| Exception.Result (Undefined.Stopped s) -> Exception.Result (Undefined.Stopped s, st)` | propagation (state kept) |
| 7 | 3 | `formatted.lem:506-507` (`convert`) | `\| Right (U.Stopped s) -> Mem.return (Right (U.Stopped s))` | propagation |
| 8 | 3 | `formatted.lem:778-779` (`printf_aux`) | `\| Right (U.Stopped s) -> Mem.return $ Right (U.Stopped s)` | propagation |
| 9 | 4 | `driver.lem:161-162` (`print_eval_conv_aux`) | `\| Exception.Result (Undefined.Stopped st) -> ND.return (Right (Undefined.Stopped st))` | propagation |
| 10 | 4 | `driver.lem:189-190` (`liftCore_run`) | `\| U.Stopped st -> ND.kill (ND.Stopped st)` | LIFT (pure channel → kill channel) |
| 11 | 4 | `driver.lem:422-423` (`FS_PRINTF`) | `\| Right (Undefined.Stopped st) -> ND.kill (ND.Stopped st)` | lift |
| 12 | 4 | `driver.lem:445-446` (`FS_VPRINTF`) | same | lift |
| 13 | 4 | `driver.lem:457-458` (`FS_VSNPRINTF`) | same | lift |

Derived tally: 13 arms in 6 `.lem` files — 9 propagation, 4 lifts (`liftCore_run` + the three formatted-I/O results) — equal to lem's own 13 warnings and to the review's "fourteen candidate arms in six files" minus one (the review counted `formatted.lem:836`'s wildcard, which the compiler cannot force — below). Every arm is dead in OCaml (no OCaml code constructs `Stopped`/`Stopped0`); every arm is a single line of the constructor's own shape, no other body text changed.

### Hand-written OCaml the compiler forced (fork side)

| pass | file:site | what | classification |
|---|---|---|---|
| 4 | `ocaml_frontend/rewriters/core_peval.ml:527-528, :578-579, :720-721` (three `match eval_pexpr … with` in the Core partial evaluator; module of the `cerb_frontend` LIBRARY via `(include_subdirs unqualified)`, so compiled under `-w @8` even though its only USER is `backend/playground/main.ml`, an executable our recipe does not build) | `\| Right (Stopped _) -> Traverse (* … DEAD arm … conservative, like Left *)` ×3 | **NOT in the charter's or the review's inventory** — compiler-discovered. Dead; `Traverse` (= "do not rewrite", the `Left err` arm's choice) is the conservative reading [AGENT]; S1 may prefer `error` — unobservable either way |
| 5 | `backend/common/driver_ocaml.ml:160-185` (`batch_drive`'s result conversion) and `:244-310` (`drive`'s human printer) | a `Stopped of { stop: Interp_stop.interp_stop; stderr: string }` variant on `batch_output` (`:37-47`), `string_of_unsupported_feature`/`string_of_interp_stop_record` (`:49-61`, the S0.4 spellings `Exhausted {}` / `ModelFailure {msg: "…"}` / `Unsupported {feature: "…", msg: "…"}`), a printer arm in `string_of_batch_output` (batch/json/charon branches), the `batch_drive` arm `\| ND.Killed (dr_st, ND.Stopped0 stop) -> … Stopped { stop; stderr }`, and the `drive` arm `\| (ND.Killed (_, ND.Stopped0 stop), _, _) -> print_endline (… "INTERPRETER STOP: " ^ …)` | ERRORS (not warnings — see above); all dead |
| 7 | `backend/common/driver_ocaml.mli:18-22` | the same variant on the interface's `batch_output` | compiler-forced (interface mismatch: "An extra constructor, Stopped, is provided in the first declaration") — a file no inventory named |

Dormant (not compiler-covered — listed, not edited): `backend/common/interactive_driver.ml:130-134`, `cerbcore.ml:57` (both excluded by `backend/common/dune:6`); `backend/common/smt.ml:616-620` (`Tkilled r`, excluded: `smt smt_wrapper` on the same line — the charter's cite of it as live is corrected); `backend/ocaml/runtime/rt_ocaml.ml:298-308` (its `dune` is entirely commented out); `frontend/model/core_run_effect.lem` (18 constructor arms) and `frontend/concurrency/nondeterminism.lem` (2) — neither is in `LEM_SRC` (`Makefile:137-190`); `driver_ocaml.ml:214-220` (inside a comment). None of these compiles today; S1 should not count them as covered and need not edit them.

**OCaml build:** pass 8 `dune build rc=0` (`_build/default/backend/driver/main.exe` rebuilt 19:44 UTC).

### The wildcards the compiler cannot see (hand-classified; census in `…/S0_2_wildcard_census.txt`)

Method: every `| _ ->` in the six files with its nearest match head (36 catch-alls), every catch-all within 12 lines after a `Defined` arm, and a constructor-arm grep over all `.lem`. Of the 36, exactly TWO scrutinise one of the two outcome types (every other catch-all is on `natFromInteger fd`, `tsk`/`rsk` step kinds, `parse format frmt`, `valueFromPexpr`, `args`, `cspec`, … — verified head by head):

| site | text | class | argument |
|---|---|---|---|
| `formatted.lem:840-841` (`vsnprintf`: `printf_aux … >>= function \| Right (U.Defined cs) -> … \| _ -> error "TODO: snprintf()"`) | catch-all over `either err (U.t (list char))`: covers `Left _`, `Right (U.Undef …)`, `Right (U.Error …)` AND now `Right (U.Stopped _)` | **SWALLOWS** — converts a stop (and, today already, a UB/error) into the pure `error "TODO: snprintf()"` (an OCaml `failwith` / Lean `failwithI`). Exhaustive after the extension → invisible to warning 8 (the review's §4 point, confirmed). | S1 decision: add `\| Right (U.Stopped s) -> Mem.return (Right (U.Stopped s))` BEFORE the wildcard (mechanically possible; a body change in a shared file, dead in OCaml) — [AGENT] recommended, since the wildcard's `error` is a fail-STOP of the model, and letting a structural stop be re-encoded as a pure failure defeats the constructor's purpose; the pre-existing swallowing of `Undef`/`Error` there is upstream's behaviour and STAYS (mirror). |
| `driver.lem:1453-1460` (`hack`: `match step_eval_pexpr … with \| Result (Defined pexpr') -> … \| _ -> error ("Driver.hack, UNDEF/ERROR:" ^ …)`) | catch-all over `exceptM (U.t pexpr) …`; `hack` returns a bare `value` | **NO-ARM-POSSIBLE** — pure-valued: there is no outcome type to carry a stop. `hack` is itself fuel'd with the value sentinel `fuelExhausted Vunit` (`driver.lem:1913`) and MEASURED under the `IsValuePexpr` shape hypothesis (`fuel_hypotheses.txt`; seam `CerbCoreShape.lean`; the `prepare_exit` invariant `driver.lem:1309-1316`). | Reachability of a `Stopped` here: the scrutinee is `step_eval_pexpr`, whose Lean zero case is `fuelExhausted (Result (Undef Loc.unknown []))` (`core_eval.lem:1239`) — a value sentinel, NOT a `Stopped`; `step_eval_pexpr` is MEASURED (`lemSize pexpr1`), so under its measure it never exhausts, and the only pure-channel `Stopped` producers after S1 are `eval_pexpr_aux2`/`eval_pexpr_aux_broken`/`full_eval_pexpr` (`core_eval.lem:1241,1243`; `core_reduction.lem:1552`), which `step_eval_pexpr` does not call ([AGENT] from the call graph; S1 to confirm with `lean_references`). Classification: **UNREACHABLE under the measure hypothesis** — the same effect-lifting obligation the parked pure-failure twin owns; the wildcard's existing `error` for `Undef`/`Error` stays (mirror). |

No other wildcard on the two types exists in the live `.lem` sources ([AGENT] derived from the census; the `Left err`/`Exception err` arms are not catch-alls for stops).

**`git diff --stat` of the S0.2 edits** (verbatim):
```
 backend/common/driver_ocaml.ml               | 46 ++++++++++++++++++++++++++++
 backend/common/driver_ocaml.mli              |  2 ++
 frontend/model/driver.lem                    | 10 ++++++
 frontend/model/exception_undefined.lem       |  2 ++
 frontend/model/formatted.lem                 |  4 +++
 frontend/model/nondeterminism.lem            |  2 ++
 frontend/model/state_exception_undefined.lem |  4 +++
 frontend/model/undefined.lem                 |  2 ++
 ocaml_frontend/rewriters/core_peval.ml       |  6 ++++
 9 files changed, 78 insertions(+)
```

### The Lean side (compiler-forced) and the S0.2 acceptance

`make lean-prelude-src` (18 s) then `lake build CerberusLean cerberus-lean` (capped 48G): **rc=1 in 41 s wall** — every generated module rebuilt (398 jobs; `Undefined` 5.2 s, `GenTyping` 9.2 s, `Translation` 8.9 s, `Core_run` 3.1 s, `Driver` 1.6 s — `…/S0_2_lean_build1_main_errors.txt`); the ONLY errors are the two hand-written printers (verbatim):
```
error: Main.lean:1069:10: Missing cases:
(Stopped0 Exhausted)
(Stopped0 (FailStop (String.ofByteArray (ByteArray.mk (Array.mk _)) (ByteArray.IsValidUTF8.intro _ _))))
(Stopped0 (Unsupported UF_filesystem (String.ofByteArray (ByteArray.mk (Array.mk _)) (ByteArray.IsValidUTF8.intro _ _))))
(Stopped0 (Unsupported UF_concurrency (String.ofByteArray (ByteArray.mk (Array.mk _)) (ByteArray.IsValidUTF8.intro _ _))))
(Stopped0 (Unsupported UF_switches (String.ofByteArray (ByteArray.mk (Array.mk _)) (ByteArray.IsValidUTF8.intro _ _))))
error: Main.lean:1102:10: Missing cases:
(… the same five …)
```
So on the Lean side the compiler enforces exhaustiveness exactly where the match is HAND-WRITTEN (Lean's `match` has no implicit wildcard); the generated matches never reached the compiler (lem's `failwithI` wildcard, above). Arms added (`…/S0_2_lean_build3_and_main_arms.txt`): helpers `unsupportedFeatureName`/`stopBatchRecord`/`stopHumanText` before `runPipeline` (`Main.lean:864-886`), the batch arm `| .Stopped0 stop => IO.println (stopBatchRecord stop)` (`:1105-1107`; records `Exhausted {}` / `ModelFailure {msg: "…"}` via `CerbFail.batchRecord` / `Unsupported {feature: "…", msg: "…"}` through `CerbEscape.text`) and the human arm `| .Stopped0 stop => IO.println s!"  result: Killed (interpreter stop — {stopHumanText stop})"` (`:1138-1139`; no `Loc` line — a stop has none). Rebuild: `Build completed successfully (398 jobs).` rc=0 in 19 s. Hand-written Lean OUTSIDE the built libraries that matches `kill_reason` and will need the same arm in S1: the five speclab gate tests `speclab/test/SLUnit/{ByteArr,Seed,List,Tree,Core}GateTest.lean` (`| Undef0 _ _ … | Error0 _ msg … | Other …`, ~line 50-61 each) — not built by this recipe; listed, not edited.

**Rebuild durations observed (S1's cost estimate):** `.lem`→OCaml regeneration 17-39 s; `.lem`→Lean regeneration 18-21 s; `dune build` after a core-type change 1-5 s per pass (digest-tracked); the FULL Lean rebuild after the core-type change 41 s wall; Main-only 19 s. The charter's "budget for long Lean rebuilds" was not needed on this machine; no pass approached the tripwire.

**Acceptance, observed:** both targets build (`dune build rc=0`; `lake build CerberusLean cerberus-lean` → `Build completed successfully (398 jobs).`); parity sanity on `tests/minimal/001-return-literal.c` — Lean `Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}` rc=0, oracle the same line; Lean at `--fuel 1` still prints `Error {msg: "lem: fuel exhausted"}` rc=1 (the 13 declares are untouched in this prototype — S1b's work). Gates expected to move (`…/S0_2_gates_and_sanity.txt`): `check_fork_drift.sh` rc=1 — `FAIL — oracle-surface file set drifted from the manifest`, NEW DRIFT `frontend/model/exception_undefined.lem`, `frontend/model/interp_stop.lem`, `frontend/model/undefined.lem`, `ocaml_frontend/rewriters/core_peval.ml` (layer 1 stops there; the content pins of the already-manifested `driver.lem`/`nondeterminism.lem`/`formatted.lem`/`state_exception_undefined.lem`/`driver_ocaml.ml(i)` would move too) — so S1's manifest refresh touches at least these 4 new rows + 6 re-pins + the layer-2 hunk hashes of `undefined.ml`, `nondeterminism.ml`, `exception_undefined.ml`, `state_exception_undefined.ml`, `formatted.ml`, `driver.ml`, `interp_stop.ml` (new). Not "fixed" here (charter §3).
`check_fuel_forms.sh` on the prototype: rc=0 (verbatim: `check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)`) — GREEN, because the 13 sentinel declares still spell `Error0 CerbFuel.fuelExhaustedLoc …`; it goes red at S1b when they are re-spelled `Stopped Exhausted`, and `FuelFormsTool.lean:306-307` (`absorbingHeads`, `fuelAtoms`) must learn the new shape first (S0.4).

## S0.3 — The traversal prototype (production `EU.mapM` / `SEU.mapM`)

Probe module `…-evidence/S0_3_Traversal.lean` (imports the branch-built generated `State_exception_undefined`, hence `Exception_undefined`, `Undefined`, `State_exception`, `Exception`; no `.lem` changed for this deliverable); elaborated with `../scripts/lean_probe.sh` under the cap, rc=0; every theorem's axiom cone ⊆ `[propext, Quot.sound]` (output verbatim in `…/S0_3_probe_output.txt`; the 38 lines flagged there are linter notes about redundant simp arguments, not errors).

### (a) The current layering, on the production combinators (observed, kernel-checked)

The generated production definitions (verbatim shape): `stExceptUndef_mapM f xs = stExpect_bind (stExpect_mapM f xs) (fun us => stExpect_return (mapM1 (fun x => x) us))` with `stExpect_mapM` a `lemListFoldr` of `stExpect_bind`s over `List.map f xs` (outer collect, left to right, threading state) and `mapM1 id = sequence0` the inner `bind2` fold (first non-`Defined` wins); `exception_undef_mapM` likewise over `except_mapM`/`except_sequence`. Element functions with a stop at position 0:
```
def stopThenWrite : Nat → Nat → exceptM (t0 Nat × Nat) String
  | 0, s => Result (Stopped Exhausted, s)  | x, s => Result (Defined x, s + 1)
def stopThenRaise : Nat → Nat → exceptM (t0 Nat × Nat) String
  | 0, s => Result (Stopped Exhausted, s)  | _, _ => Exception "later"
```
| theorem | statement | meaning |
|---|---|---|
| `seu_state_changes_after_stop` | `stExceptUndef_mapM stopThenWrite [0, 1] 0 = Result (Stopped Exhausted, 1)` | element 1 RAN after the stop; the stop carries the LATER state (1, not 0) |
| `seu_stop_replaced_by_later_exception` | `stExceptUndef_mapM stopThenRaise [0, 1] 0 = Exception "later"` | a later outer exception REPLACES the stop |
| `eu_stop_replaced_by_later_exception` | `exception_undef_mapM euStopThenRaise [0, 1] = Exception "later"` | the same on `EU.mapM` |
| `seu_state_changes_after_undef` | `stExceptUndef_mapM undefThenWrite [0, 1] 0 = Result (Undef Loc.unknown [], 1)` | the SAME behaviour for a legacy `Undef` — upstream's semantics (run all, then fold) |
| `seu_undef_replaced_by_later_exception` | `stExceptUndef_mapM undefThenRaise [0, 1] 0 = Exception "later"` | idem: a later exception replaces a UB |

The review's two counterexamples hold on the production combinators, and the mirror's own semantics for `Undef`/`Error` is exactly the same shape (the last two rows) — it MUST stay (zero execution discrepancies), which is why the candidate below touches only the `Stopped` case.

### (b) The candidate `mapM'` — halt collection at the first stop, change nothing else

```
def collectS f : List d → s → exceptM (List (t0 a) × s) msg
  | [], st => Result ([], st)
  | x :: xs, st => match f x st with
    | Exception e => Exception e
    | Result (Stopped sp, st') => Result ([Stopped sp], st')        -- HALT: later elements are not run
    | Result (u, st') => match collectS f xs st' with | Exception e => Exception e | Result (us, st'') => Result (u :: us, st'')
def mapM' f xs := stExpect_bind (collectS f xs) (fun us => stExpect_return (mapM1 (fun x => x) us))
```
i.e. the production layering with the collector replaced by one that halts at a stop; the inner fold is the production `mapM1 id`, so the legacy precedence (first non-`Defined` wins, `Undef`/`Error` do not halt collection) is untouched.

| theorem | statement | role |
|---|---|---|
| `collectS_eq_stExpect_mapM` | `(∀ x st, NoStopS (f x st)) → collectS f xs = stExpect_mapM f xs` (function equality, by induction; `NoStopS r := ∀ sp st', r ≠ Result (Stopped sp, st')`) | the collector is conservative |
| **`mapM'_eq_mapM`** | `(∀ x st, NoStopS (f x st)) → mapM' f xs = stExceptUndef_mapM f xs` | **THE CONSERVATIVITY LAW** (the charter's `(∀ x ∈ xs, noStop (f x)) → mapM' f xs = mapM f xs`, quantified over all states) |
| `collectS_append` | collection over `xs ++ zs` = the prefix's outcomes followed by the suffix's, when the prefix produced no stop | the append lemma |
| `sequence0_defined_then_stop` | `(∀ u ∈ us, ∃ v, u = Defined v) → sequence0 (us ++ [Stopped sp]) = Stopped sp` | the inner fold yields the stop after an all-`Defined` prefix |
| **`mapM'_stops`** | `collectS f xs st = Result (us, st1) → (∀ u ∈ us, ∃ v, u = Defined v) → f x st1 = Result (Stopped sp, st2) → ∀ ys, mapM' f (xs ++ x :: ys) st = Result (Stopped sp, st2)` | **THE STOP THEOREM**: for EVERY continuation `ys` the result is the stop with the state right after element k — so no later element runs, no later state update reaches the result, no later outer exception replaces it |
| `mapM'_stopThenWrite` | `mapM' stopThenWrite [0, 1] 0 = Result (Stopped Exhausted, 0)` | state AT the stop (contrast `= …, 1` in (a)) |
| `mapM'_stopThenRaise` | `mapM' stopThenRaise [0, 1] 0 = Result (Stopped Exhausted, 0)` | the later exception does not replace it (contrast `Exception "later"` in (a)) |
| `mapM'_undefThenWrite` / `mapM'_undefThenRaise` | `= Result (Undef Loc.unknown [], 1)` / `= Exception "later"` | legacy behaviour IDENTICAL to (a) |

Not stated (deliberately): a claim about a stop met AFTER an earlier `Undef`/`Error` in the same traversal — the candidate keeps collecting through legacy failures (as production does) and the inner fold then makes the EARLIER failure win, exactly as production would if the stop were an `Error`. [AGENT] That is the conservative reading of "identical accumulation policy on all legacy cases"; the alternative (a stop ALWAYS wins) would change which legacy failure is reported when both occur and is not recommended.

### (c) Where production traversals can meet a stop

Producers of the pure-channel sentinel after S1 (`Stopped Exhausted`; today `Result (Error fuelExhaustedLoc …)`): the three ABSORBING pure workers `eval_pexpr_aux2`, `eval_pexpr_aux_broken` (`core_eval.lem:1241,1243`; no `fuel_measure` line exists for either) and `full_eval_pexpr` (`core_reduction.lem:1552`). Their wrappers: `core_run.lem:174-178` `E.eval_pexpr = SEU.runEU (Core_eval.eval_pexpr_aux_broken …)`, `:181-183` `E.eval_pexpr2 = SEU.runEU (Core_eval.eval_pexpr_aux2 …)`; `core_reduction.lem:43-54` `E.eval_pexpr2` (the same worker), `:60-66` `full_eval_pexpr` (loops on `E.eval_pexpr2`), `:1097-1100` the local `eval_pexpr` (on `E.eval_pexpr2`), `:1104-1105` `full_eval_pexpr'`.

| traversal | element | can element k stop? | today (`Undef`/`Error` from element k lets k+1 run?) |
|---|---|---|---|
| `core_run.lem:1380` `SEU.mapM (E.eval_pexpr …) pes` (Ememop arguments) | `eval_pexpr_aux_broken` via `runEU` — ABSORBING | **YES** (`Result (Stopped Exhausted, st)` at fuel 0) | yes — `seu_state_changes_after_undef` is exactly this combinator; STAYS |
| `core_reduction.lem:321` `E.mapM eval_pexpr pes` (`one_step`, bound at `:1462` to the `:1097` `eval_pexpr` = `E.eval_pexpr2`) | `eval_pexpr_aux2` — ABSORBING | **YES** | yes; STAYS |
| `core_reduction.lem:1357, :1393, :1409` `E.mapM full_eval_pexpr' pes` (`E.mapM = SEU.mapM`, `:31`) | `full_eval_pexpr` — ABSORBING | **YES** | yes; STAYS |
| `core_reduction.lem:445` `E.mapM (fun (sym, (bTy, pe)) -> …)` | body to be read in S1 (an `E.eval_pexpr2`-based lambda by position) | likely YES [AGENT, unverified] | yes; STAYS |
| `core_run.lem:165` `SEU.runEU (EU.mapM (Core_eval.step_eval_pexpr 0 …) pes)` | `step_eval_pexpr` — MEASURED (`lemSize pexpr1`; its zero case is the VALUE sentinel `fuelExhausted (Result (Undef Loc.unknown []))`, not an exhaustion outcome) | **NO** under the measure (the sufficiency obligation is proved; the worker cannot reach its zero case from the wrapper) | yes; STAYS |
| `core_eval.lem:608, 770, 799, 857, 977` `EU.mapM self pes` inside `step_eval_pexpr` | `self` = the measured worker | NO (same argument) | yes; STAYS |
| `core_run.lem:1513` `SEU.foldM`, `core_reduction.lem:1435` `E.foldlM`, `state_exception_undefined.lem` `sequence`/`filterM`/`foldM` | `bind`-based, no collect-then-fold layering | a stop halts them already (the `bind` arm of S0.2 #5): NO repair needed | — |

So the imprecision is live at ≥ 4 production sites, all `SEU.mapM` (directly or through the `E.mapM` alias), all with an ABSORBING element; the `EU.mapM` sites cannot meet a stop under the measure hypotheses (repairing `EU.mapM` too is harmless and keeps the two combinators uniform).

### Recommendation [AGENT]: (b), as a SHARED-BODY change with the conservativity law as its rationale — subject to an operator ruling

Evidence for (b) over (a): under (a), at `core_run.lem:1380` an `Exhausted` in argument k followed by an `Exception` in argument k+1 becomes, through `liftCore_run` (`driver.lem:184-186`), `ND.Other (DErr_core_run err)` — an EXHAUSTION reported as a model error, invisible to `NoFuel`/`DriverSafeCtl` and to the `Exhausted {}` record (the review's finding, now with the production path); and the state carried by a stop is the state after later, pointless work. Under (b) `mapM'_stops` gives the stop, at its state, unconditionally on the continuation, while `mapM'_eq_mapM` gives zero movement on every legacy traversal (the differential lanes cannot see it, by theorem).

The `.lem` shape of (b): rewrite the BODIES of `stExceptUndef_mapM` (`state_exception_undefined.lem:31-34`) and `exception_undef_mapM` (`exception_undefined.lem:31-34`) as `collectS`-style recursive collectors (the `Stopped` arm halting), keeping the inner `Undefined.mapM id` fold. Upstream visibility: this is a SHARED BODY change (both targets; a new `Stopped` arm inside a restructured `mapM`), so under the scoping note's doctrine (iii) it needs its own correctness rationale and an operator ruling — the rationale is `mapM'_eq_mapM` (the OCaml behaviour on every input is unchanged, since OCaml constructs no `Stopped`; on the Lean side every legacy traversal is unchanged by theorem). The Lean-only alternative — `declare lean target_rep function stExceptUndef_mapM = `CerbStopTraversal.mapM'`` with the hand-written module carrying the theorems — keeps the OCaml text byte-identical but HIDES the divergence in a target_rep (the property the scoping note rejected in Option C) and makes the generated `_zero`/measure machinery see a hand-written combinator; [AGENT] not recommended, listed for the ruling. A blanket short-circuit rewrite (bind-based `mapM`) is NOT proposed: `seu_state_changes_after_undef` shows it would change legacy behaviour.

Cost of (b) for S1 [AGENT]: two `.lem` bodies (≈ 12 lines each, dead arm in OCaml), two generated-OCaml files whose hunk hashes move (`state_exception_undefined.ml`, `exception_undefined.ml` — already moving for the arms), the theorems above transplanted from the probe onto the generated names (they are stated against the generated combinators already; only `collectS` becomes the generated collector), and a `termination_argument`/`structural` declare for the new structural recursion (the collector recurses on the list — `declare {lean} structural val …` or `automatic`).

## S0.4 — The wire-protocol policy

Draft addendum written: [`2026-09-16_observation-contract-addendum-stops.md`](2026-09-16_observation-contract-addendum-stops.md). Its content, in one paragraph: three record spellings, one per stop kind (`Exhausted {}`; `ModelFailure {msg: "…"}` as today via `CerbFail.batchRecord`; `Unsupported {feature: "filesystem|concurrency|switches", msg: "…"}`), produced by casing on the constructor (the prototype's `Main.lean` arms and the fork oracle's dead-arm printer spell the same bytes); the incomplete-run rule (any stop record anywhere in a batch → INCOMPLETE regardless of exit status and other `Defined` lines; exit policy unchanged, OCaml-parity); the classifier table naming EVERY script and gate S1 changes with its current line cite — `observations.py` (`FUEL_RECORD :49-52`, `parse :308-319`, `token :113-114`, `reference :117-127`, `model_failure/evidence :139-141/:168-171`, completion gate `:332-336`, `refusal :178-184` unchanged, `compare :385-395`), `test_observations.py`, `fuel_classify.sh:47-49` + its selftest `test_fuel_classifier.sh:35-71` (three cases FLIP), the five lanes' `classify_fuel_outcome` call sites and their crash-kind greps (`test_exec.sh:627-631/:653`, `test_gcc_oracle.sh:448-451`, `test_ci_sweep.sh:286-290`, `test_cn_coverage.sh:388-395`, `measure.sh:137-150`), `test_immaculate.sh:114`, the two plants (`test_fuel_plant.sh:20-45` gains a `stub_legacy` NEGATIVE; `test_failstop_plant.sh` gains an `Unsupported` stub), `Main.lean:1076-1079/:1108-1109` (the `BEq Loc` tests go), the two atoms + `check_theorem_axioms.sh:187-204` rows, `FuelFormsTool.lean:306-308/:434-440` (recognise `Stopped Exhausted` EXACTLY; `FailStop`/`Unsupported` zero cases RED — two new `check_fuel_forms.sh --selftest` plants), the 13 declares + `CerbND.lean` runner leaves, and the fork-drift manifest rows from S0.2; the legacy-text rule (no compatibility alias; an ordinary `Error {msg: "lem: fuel exhausted"}` stays ordinary; no legacy decoder recommended — no committed baseline holds a FUEL row); pure exhaustion PANICS keep `FUEL:panic`/crash classes; adversarial payloads through `CerbEscape.text` + whole-line `fullmatch` + a closed `feature` alternation; the CLI `refuseFlag` (exit 2, admission) and `observations.refusal` unchanged and stated so. **Acceptance:** every script/gate S1 touches is named with a cite in the addendum's §3 table (derived tally: 22 rows).

Observed inputs to the addendum (this branch): the prototype printers' output shapes are the addendum's spellings by construction (`Main.lean` `stopBatchRecord`; `driver_ocaml.ml` `string_of_interp_stop_record`); today's exhaustion line `Error {msg: "lem: fuel exhausted"}` at `--fuel 1` (S0.2 sanity) is the line the rule retires.

## S0.5 — The consumer statement scan (read-only; refined-cerberus @ `6be4b82`)

Method: `grep -rn` over `refined-cerberus/**/*.lean` (excluding `.lake/`) for the sentinel names (`fuelExhaustedLoc`, `modelFailStopLoc`, `fuelExhaustedKill`, `fuelExhaustedMsg`, `failStopKill`), for constructor arms of the two outcome types (`Defined|Undef|Error|Undef0|Error0|Other` at arm position), and for instance demands (`Inhabited`, `BEq (`, `Ord (`, `deriving`, `instance`) naming `kill_reason`/`t0`/`nd_status`/`nd_action`/`ndM`; then the proof scripts around each hit were read. Nothing in their tree was edited. Classes: MIGRATES-MECHANICALLY (the statement holds or is re-typed by the alias with no proof change), NEEDS-RESTATEMENT (text must change), UNAFFECTED.

| where (`cerberus-heaplang/CerberusHeapLang/…`) | what | class | note |
|---|---|---|---|
| `Heap.lean:1521-1528` `runOne_mem_bind_zero` | STATEMENT spells the old term literally: `runOne (nd_bind m f) σ = (NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), σ)`; proof `unfold nd_bind; rw [hfuel, nd_bind_lemFuel_zero]; rfl` | **NEEDS-RESTATEMENT** | the charter's one literal spelling (confirmed the only one); becomes `NDkilled CerbND.fuelExhaustedKill` (or `Stopped0 Exhausted`); the proof is unchanged if the alias is definitionally the generated arm |
| `DriverCollapse.lean:111-116` `runOne_bind_zero` (`rw [nd_bind, hzero]; rfl`), `:118-124` `runOne_liftMem_zero` (`unfold liftMem liftND; rw [hzero]; rfl`), `:126-…` `runOne_liftMem_one`, `:3347-3350` `loop_zero_exhausts … := rfl`, `:3357-3366` `loop_step_done_exhaust` | statements name `CerbND.fuelExhaustedKill`; the `rfl`s close ONLY because the alias is DEFINITIONALLY the generated `_zero` arm's value (`NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg)` today) | **MIGRATES-MECHANICALLY under one condition** | S1 must define `CerbND.fuelExhaustedKill := Stopped0 Exhausted` — byte-for-byte the value the regenerated `nd_bind_lemFuel_zero`/`liftND_lemFuel_zero`/`drive_nonmemory_steps_aux2_lemFuel_zero` arms produce — so these `rfl`s survive; this is the "definitional unfolding" dependence the charter asked for (4 proofs incl. Heap.lean:1525's); nothing in their tree states the OLD equality `fuelExhaustedKill = Error0 …` as a theorem |
| `Adequacy.lean:945-960` `DriverSafeCtl` (`… = (NDkilled CerbND.fuelExhaustedKill, dst')) ∨ …`), `:1003`; `ProdEntry.lean:513, :535, :635, :846, :868, :1029`; `EvenOddExhibit.lean:670`; `FibRecExhibit.lean:821`; `DivergeExhibit.lean:140` | statements with `Killed dst' CerbND.fuelExhaustedKill` / `NDkilled CerbND.fuelExhaustedKill` | MIGRATES-MECHANICALLY (same condition) | `DriverSafeCtl`'s exhaustion disjunct names the alias only; S1c adds the review §6 NEGATIVE checks — `Killed dst' (Stopped0 (FailStop m)) ≠ Killed dst' fuelExhaustedKill` and the `Unsupported` twin — which become `noConfusion` one-liners |
| `API.lean:63, :95`; `Adequacy.lean:18, :913, :937`; `DriverCollapse.lean:3341`; `LoopExhibit.lean:27`; `DivergeExhibit.lean:17, :127`; `Audit.lean:65` | prose/doc comments naming `CerbND.fuelExhaustedKill` | UNAFFECTED (name kept) | — |
| `Round.lean:1085-1093` `runOne_liftMem_killed`, `:1118-1120` `ars_store_killed`, `:1136-1138` `ars_load_killed`, `:1157-1159` `ars_create_killed`, `:1175-1177` `ars_kill_killed`, `:1196-1198` `ars_alloc_killed`, `:7498-7500` `ars_seq_rmw_load_killed`, `:7538-7540` `ars_seq_rmw_store_killed` | eight theorem STATEMENTS contain `match r with \| Undef0 l ubs => Undef0 l ubs \| Error0 l s => Error0 l s \| Other err => Other (DErr_memory err)` over `r : kill_reason mem_error` — their restatement of `liftAction`'s reason map; proofs end `cases r <;> rfl` (`:1105`) | **NEEDS-RESTATEMENT** (mechanical) | after the extension each `match` is NON-EXHAUSTIVE (Lean: `Missing cases: Stopped0 _`); add `\| Stopped0 s => Stopped0 s` (mirroring S0.2 arm #4); `cases r <;> rfl` then covers it unchanged |
| `Round.lean:7552-7554` `private def seqRmwMemoryReason : kill_reason mem_error → kill_reason driver_error` | the same 3-arm map as a def | NEEDS-RESTATEMENT (mechanical) | + one arm |
| `Soundness.lean:130-134` and `:198-206` (`dischargeStep`: `match m rs with \| Result (Defined th', _) => .next th' σ \| Result (Undef l ubs, _) => .killed (Undef0 l ubs) \| Result (Error l s, _) => .killed (Error0 l s) \| Exception _ => .offFragment`) | matches on `exceptM (t0 thread_state × core_run_state) …` — the consumer's projection of `liftCore_run` | **NEEDS-RESTATEMENT** (a design choice) | non-exhaustive after the extension; the mirror of `liftCore_run`'s S0.2 arm #10 is `\| Result (Stopped s, _) => .killed (Stopped0 s)`; whether their `StepOutcome` wants a distinct `.stopped` arm is theirs to decide |
| `Soundness.lean:8595-8597` `stExceptUndef_bind_apply` | a theorem restating the SEU `bind`'s arms | NEEDS-RESTATEMENT (mechanical) | + the `Stopped` arm (mirrors S0.2 arm #5) |
| `Round.lean:289-296` (the `panic` constructor: `∃ … (inst : Inhabited (core_run_state → exceptM (t0 d × core_run_state) core_run_cause)) …`) | an `Inhabited` DEMAND on a function type whose codomain contains `t0 d` at a BOUND `d` — the review's "inferred instances can depend on representations without naming the constant" | UNAFFECTED as a statement — FLAGGED | the inhabitant is whatever `failwithI` used at the generated panic site; under S0.1(a)'s hazard that value is `fun _ => Result (Stopped Exhausted, …)`-shaped, i.e. a PANIC would denote EXHAUSTION to any theorem that unfolds the default — a second reason the default policy (S0.1(c)) must land BEFORE the consumer builds against S1 |
| `Round.lean:210-211`, `DivergeExhibit.lean:210-211` (`(default : driver_state)`, `(default : core_state)`), `Heap.lean:1675` (`(default : Mem)`), `Heap.lean:2236` (`deriving Inhabited` on a consumer type) | other `Inhabited` uses | UNAFFECTED | none reaches `t0`/`kill_reason` at an unconstrained payload ([AGENT], by the types' fields); no `BEq`/`Ord` demand on the outcome types exists in their tree (grep: 0 hits) |
| `docs/FUEL.md:247-248` ("`fuelExhaustedKill` is `Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg`"), `:255-259` (table rows spelling `Result (Error fuelExhaustedLoc fuelExhaustedMsg)`), 32 other `.md` files naming the alias | contract prose | FUEL.md NEEDS-RESTATEMENT (text); the rest UNAFFECTED | their re-pin item |

Derived tallies: 27 Lean mentions of the sentinel names — 1 literal old term (NEEDS-RESTATEMENT), 18 alias uses in statements/proofs (MIGRATES-MECHANICALLY under the definitional-alias condition; 4 of them `rfl`-dependent), 8 prose (UNAFFECTED). Constructor matches on the two types — 12 blocks (9 in `Round.lean`, 3 in `Soundness.lean`; 34 arms today), every one NON-EXHAUSTIVE after the extension: NEEDS-RESTATEMENT, mechanical except `dischargeStep`'s outcome choice. Instance demands on the outcome types — 0 named; 1 function-typed `Inhabited` existential flagged. [AGENT] The scoping note's "one literal spelling … small, mechanical" is confirmed for the sentinel, but the constructor-match census (12 blocks) is the larger, previously uncounted consumer cost — the review's caution vindicated in a different place than it expected.

## S0.6 — What the probes settled, what remains for the operator, and the S1 charter shape

Branch state at close: commits `1663357bf` (S0.1) → `4f2a95666` (S0.2) → `6020f8f56` (S0.3) → `0148fb966` (S0.4) → `af1d068ea` (S0.5) → this commit (S0.6), on `7e4c23709` (charter) on the mainline `721b1c2c7`; `git status --porcelain` empty at each commit. Evidence directory: 22 plain-text files, 128 KB (`du -sh`). Gates on the prototype at close: `check_fork_drift.sh` RED (expected; S0.2), `check_fuel_forms.sh` GREEN (declares untouched), `check_driver_fresh --check` not re-recorded (the binaries were rebuilt; stamps are not touched by a prototype), no baseline re-recorded, no protected register touched, no lem-lean/deps/primary/other-worktree edit. No pass approached the tripwire (longest single pass: the 41 s full Lean rebuild).

### Decisions the probes SETTLED (observed or proved)

1. **The generated-default hazard is real on the production `Undefined.t` and confined there.** `(default : t0 a) = Stopped Exhausted` by `rfl` after the extension; `kill_reason`'s default stays `Undef0 default default` (its primary instance is unconstrained), and `t0` at a concrete inhabited payload stays `Defined default` (S0.1(a)).
2. **`skip_instances` cannot express the default policy** — the backend assumes an unconditional `Inhabited` for a census-absent type and emits the `Stopped default` fallback; the failure is a loud Lean `failed to synthesize` at the generated instance, not a generation error; `declare lean target_rep type` shares the code path; no in-model encoding is honest (S0.1(b)). **S1 needs a lem-lean declare first** — the R1.3 fallback (`inhabited_exclude type t`, sketched in S0.1(c): census `Inh_none`, everything else by existing rules) — as a PAIRED lem-lean slice before S1a. Bonus finding for the lem-lean side: `skip_instances` leaves `deriving BEq, Ord` in place, contra `DESIGN.md:494`.
3. **The compiler-forced arm inventory is 13 `.lem` arms in 6 files (9 propagation, 4 lifts), = lem's own warning list**, plus hand-written OCaml nobody had inventoried: `ocaml_frontend/rewriters/core_peval.ml` (3, under the fatal flag) and `backend/common/driver_ocaml.ml` + `.mli` (a variant, printer arms, batch/human arms) — and `backend/common` IS fatal on warning 8 (dev profile). Dormant files enumerated. Only TWO wildcards on the two types exist: `vsnprintf`'s (SWALLOWS — S1 adds the arm before it) and `hack`'s (NO-ARM-POSSIBLE; unreachable under the measure hypothesis) (S0.2).
4. **On the Lean target a missing `.lem` arm does NOT fail the build**: lem emits a `failwithI "Incomplete Pattern …"` wildcard whose fallback value at an unconstrained `t0` is the derived default — under the hazard, `Stopped Exhausted`. The OCaml build is the only compiler enforcing the `.lem` arms; S1 adds a `lem.log` `missing patterns … Stopped` grep as a cheap gate (S0.2).
5. **The traversal counterexamples hold on the production combinators, and the legacy `Undef`/`Error` behave identically** (upstream's run-all-then-fold, which the mirror keeps). The candidate `collectS`/`mapM'` satisfies the conservativity law `mapM'_eq_mapM` and the stop theorem `mapM'_stops`, kernel-checked with axioms ⊆ {propext, Quot.sound}; stops CAN arise in element k at `core_run.lem:1380` and `core_reduction.lem:321/1357/1393/1409` (ABSORBING elements), NOT at `core_run.lem:165` (MEASURED element); `bind`-based folds need no repair (S0.3).
6. **The wire protocol**: three spellings, the incomplete-run rule, 22 classifier/plant/gate rows with cites, the legacy-text rule, panics unchanged, `refuseFlag` unchanged (S0.4, the addendum).
7. **The consumer cost** is one literal term + 18 alias uses (mechanical under the definitional-alias condition) + **12 constructor-match blocks** (the uncounted part) + FUEL.md text; no `BEq`/`Ord` demand on the outcome types; one function-typed `Inhabited` existential flagged (S0.5).
8. **Rebuild costs**: regeneration 17-39 s per target; `dune build` 0-5 s per pass; the FULL Lean rebuild after a core-type change 41 s wall on this machine (S0.2) — S1 needs no long-build justification.
9. **Both engines agree on the sanity program after the extension** (`Defined {value: "Specified(42)", …}` on both; Lean `--fuel 1` still prints the old exhaustion line because the 13 declares are S1b's).

### Decisions that REMAIN for the operator (with the worker's recommendation and its evidence)

| # | decision | recommendation [AGENT] | evidence |
|---|---|---|---|
| R1 | **Authorise the paired lem-lean slice** adding `declare {lean} inhabited_exclude type t` (S0.1(c)) before S1a — a backend change the scoping note R1.3 anticipated as the fallback | YES; it is the only mechanism that keeps `Undefined.t`'s default at `Error default default` and makes any default-demand on `interp_stop` a generation-time error (fail-closed); tens of lines, template = `skip_instances`' plumbing | S0.1(b) verbatim failure; `lean_backend.ml:466-478, :1471, :1535-1543, :1580-1582, :7185-7193`; the consumer's `Round.lean:292` demand shows why a silent default matters |
| R2 | **Traversal policy: (b)**, as a SHARED-BODY change of `stExceptUndef_mapM`/`exception_undef_mapM` (dead `Stopped` arm inside a restructured collector), rationale = `mapM'_eq_mapM` | (b) shared-body, visible to upstream and compiler-checked on both targets; NOT the Lean-only `target_rep` variant (hides the divergence — the property the scoping note rejected in C); NOT a blanket short-circuit (`seu_state_changes_after_undef` shows it changes legacy behaviour) | S0.3 theorems; the `ND.Other (DErr_core_run …)` disguise of an exhaustion under (a) at `core_run.lem:1380` via `driver.lem:184-186` |
| R3 | **`vsnprintf`'s wildcard** (`formatted.lem:840`): add the `Stopped` propagation arm before `\| _ -> error "TODO: snprintf()"` (a shared-body line, dead in OCaml) or leave the swallow | add the arm (a structural stop must not be re-encoded as a pure `failwithI`); the pre-existing swallow of `Undef`/`Error` there stays (mirror) | S0.2 wildcard table |
| R4 | **`core_peval.ml`'s dead arms**: `Traverse` (conservative) or `error` | `Traverse`; unobservable either way (no OCaml code constructs `Stopped`) | S0.2 |
| R5 | **Policy name in `observations.py`**: keep `model-failure` as the opt-in policy for all stop kinds or rename to `stop` | rename to `stop` (one policy for the incomplete class), keeping `immaculate` | addendum §3 |
| R6 | **Legacy decoder**: none (recommended) or an explicit `--legacy-fuel-text` | none — no committed baseline holds a FUEL row | addendum §4 |
| R7 | **`dischargeStep`'s outcome for a stop** (consumer) | theirs: `.killed (Stopped0 s)` mirrors `liftCore_run`; relay with the S0.5 table | S0.5 |
| R8 | **Sequencing**: the lem-lean declare (R1) → re-pin → S1a (types + 13 arms + `core_peval`/`driver_ocaml(i)` + the R2 bodies + the R3 arm) → S1b (declares, runners, `CerbFuel`/`CerbFail`/`CerbND`/proofs, printers, codec, plants, `FuelFormsTool`, atoms deleted) → S1c (battery + pristine lane + consumer build) — one implementation branch, one landing | as the review §9 / R1.5, with R1 inserted first | this record |

### Open questions written into the record (nobody could answer them in-run)

- Q1. Does the operator accept the shared-body form of (b) (R2) under doctrine (iii), with `mapM'_eq_mapM` as the correctness rationale? (Charter: "a shared-body change — which needs its own ruling".)
- Q2. `core_reduction.lem:445`'s `E.mapM` lambda body was not read (S0.3 table marks it "likely YES, unverified") — S1a reads it.
- Q3. `Round.lean:292`'s function-typed `Inhabited` existential: does any consumer theorem UNFOLD that inhabitant's value? (The scan found none; a consumer build against S1 answers it.)
- Q4. lem-lean's `skip_instances` leaving `deriving BEq, Ord` in place — a doc bug (`DESIGN.md:494`) or a behaviour bug? For the lem-lean side to decide; not blocking.
- Q5. The charter's §1 facts corrected here (`kill_reason`'s default = `Undef0`; `backend/common` fatal on warning 8; `smt.ml` dormant; `ctype.lem` has no `skip_instances`) — for the orchestrator's errata list.

### Proposed S1 charter shape [AGENT]

**Pre-S1 (paired lem-lean slice, own charter):** `declare {lean} inhabited_exclude type t` — prepass census `Inh_none` + no `Inhabited` emission for `t`; reproducer `tests/comprehensive/test_inhabited_exclude.lem` + a `lean-test` pin `(default : t a) = <pre-existing fallback>`; `DESIGN.md` row; the two-repo pin dance (`deps/lem-pinned` → `make rebuild-lem` → Lake `LemLib` rev). Exit: `(default : t0 a) = Error default default` by `rfl` with `Stopped` appended, in cerberus-lean's tree.

**S1 deliverables (one branch, one landing; S1a/S1b/S1c as R1.5):**
- **S1a — representation and transport.** `interp_stop.lem` (as in this prototype, ASCII comments) with `declare {lean} inhabited_exclude type interp_stop`; `Stopped of interp_stop` on both types; the 13 arms VERBATIM from the S0.2 table; `core_peval.ml` ×3, `driver_ocaml.ml` + `.mli` (this prototype's text); the R2 bodies in `state_exception_undefined.lem`/`exception_undefined.lem` with a `structural`/`automatic` declare; the R3 arm; `Makefile` `LEM_PRELUDE`, Lake roots (`Interp_stop`, `Interp_stop_auxiliary`), `handwritten_copy.manifest` for any new seam; `check_fork_drift` manifest refresh (Tier-B recipe) with the rows in S0.2's acceptance. Gates: both targets build; `lem.log` has no `missing patterns … Stopped`; the `_zero` lemmas regenerate; `stop-defaults-test` pins `Error default default` (the flipped theorem) + `Undef0 default default` + `Defined 0`; the S0.3 theorems transplanted onto the generated collectors (`mapM'_eq_mapM` becomes the OLD-vs-NEW combinator equality under `NoStopS`, stated against a frozen copy of the old body — the parser-progress-measure slice's `_old` pattern); direct constructor probes.
- **S1b — migrate producers and consumers.** The 13 declares → `Stopped0 Exhausted` / `Result (Stopped Exhausted)`; `CerbND.fuelExhaustedKill := Stopped0 Exhausted` (definitionally the arms' value — the consumer's `rfl`s depend on it, S0.5); `CerbFail.failStopKill msg := Stopped0 (FailStop msg)`; the runner leaves; `CerbFailProofs`/`CerbNDFuelProofs` (`NoFuel` stays exhaustion-specific; distinctness lemmas → `noConfusion`); DELETE `CerbFuel.fuelExhaustedLoc`, `CerbFail.modelFailStopLoc`, the two `OPAQUE_WANT` rows (16 → 14), the parametricity text; `Main.lean` printers (this prototype's arms; the `BEq Loc` tests deleted); the addendum's 22 rows (codec, classifier + selftest, five lanes' greps, `test_immaculate`, the two plants + `stub_legacy` + the `Unsupported` stub, `FuelFormsTool` exact-`Exhausted` recognition + two `check_fuel_forms --selftest` decoys); the five speclab gate tests' arms; `VALIDATION.md` §1(b)/(c), §7, §9; `DESIGN.md`; fuel-arc design §1.3 and typed-failure Group M marked superseded; a tray draft "`Stopped of interp_stop`" for upstream.
- **S1c — validate.** Tier A + Tier B battery (`scripts/LADDER.md`), the pristine oracle lane, drift review of every generated hunk (all dead code), the consumer built against the candidate in an isolated checkout (Heap, partial and total adequacy) with the S0.5 table as its work list and the `DriverSafeCtl` negative checks added; zero existing-row movement is the gate.

**Fence:** `frontend/model/{interp_stop,undefined,nondeterminism,exception_undefined,state_exception_undefined,formatted,driver,core_eval,core_reduction,defacto_memory}.lem` (types, arms, bodies of R2/R3, the 13 declares only); `ocaml_frontend/rewriters/core_peval.ml`; `backend/common/driver_ocaml.ml{,i}`; `lean_frontend/{CerbFuel,CerbFail,CerbND,CerbFailProofs,CerbNDFuelProofs,Main}.lean`, a new `CerbStop.lean` if S2 needs helpers above ND; `test/Unit/{StopDefaultsTest,FuelFormsTool,MonadicFailstop}.lean` + a `StopTraversalTest.lean` carrying the S0.3 theorems; `scripts/{observations.py,test_observations.py,fuel_classify.sh,test_fuel_classifier.sh,test_fuel_plant.sh,test_failstop_plant.sh,check_fuel_forms.sh,check_theorem_axioms.sh,fork_drift_manifest.txt,test_unit.sh}` + the lane greps named in the addendum; `Makefile`, `lakefile.toml`, `handwritten_copy.manifest`; docs. NOT: `fuel_forms_pending.txt`, `fuel_hypotheses.txt`, `failure_reach_register.txt`, `upstream_oracle_differences.json`, any baseline, lem-lean (except the pre-S1 paired slice).

**Acceptance (the review §10 table, adopted):** each stop through pure bind, exception bind, state bind and both channel conversions → same reason, continuation not run, failure-time state; each stop through the ND lifts and all three runners → no ordinary-error mapper called, order and multiplicity preserved; early stop + later state update / outer exception in a traversal → the R2 policy (`mapM'_stops`); legacy UB/error + later action → unchanged (`seu_state_changes_after_undef`); generic and concrete `Inhabited` demands → no default exhaustion (`stop-defaults-test`); zero observer budget over a fail-stop → exhaustion keeps its precedence; small vs sufficient fuel on a terminating example → explicit exhaustion / unchanged result; `Defined` + a stop in a batch → incomplete; ordinary errors and escaped output with marker text → never a structural stop; forged old locations, adversarial text, malformed records → no reclassification / escaping / rejection; pure panic, OOM, timeout, signal controls → failures; `DriverSafeCtl`-shaped conclusion → only exhaustion admissible, fail-stop and unsupported excluded.

**Proof list (the review §6, adopted):** separation (`noConfusion` on `interp_stop` and on the two `Stopped` constructors vs `Undef`/`Error`/`Other`), absorption (the `_zero` lemmas + `bind` does not call its continuation after a stop), state (`liftCore_run`'s run state, `liftMem`'s memory — the consumer's `runOne_liftMem_killed` family already states it), traversal (`mapM'_stops`, `mapM'_eq_mapM`), observation (the three runners report the same reason; order and multiplicity), conservativity (the S0.3 laws + `old_bind_preserved`-style embeddings for every altered adapter). `NoFuel` stays exhaustion-specific; `DriverSafeCtl` admits exhaustion only.
