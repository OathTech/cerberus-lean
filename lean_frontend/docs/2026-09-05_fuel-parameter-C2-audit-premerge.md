# Pre-merge audit — fuel-parameter arc, cerberus slice C2 (2026-09-05)

Auditor [AGENT] (independent of the C2 worker and the orchestrator). Range
audited: `753644005..5c9f5cba2` on `arc/fuel-parameter-C2` (6 commits:
`bd8e9c75c`, `e2bbacfc1`, `b64748d52`, `b25ea0aac`, `75240ce01`,
`5c9f5cba2`), read and probed in the worker's worktree
`worktrees/cerberus-lean-arc/zero-discrepancy` (read + run only; nothing
edited there). This document lives on `audit/c2-premerge` (worktree
`worktrees/cerberus-lean-audit/c2-premerge`, cut at the C2 head); the
audit's scratch (`.tmp/audit/`) is ephemeral. Every quoted output is
verbatim from this machine on 2026-09-05; tallies I computed are labelled
DERIVED. Nothing merged, nothing pushed. Findings are claims — each carries
its evidence so the orchestrator can re-verify.

Grading key (the brief's): MAJOR = a `.lem` body change / an OCaml output
change / a reachable ambient worker not in the pending register (fail-open)
/ a non-absorbing "absorbing" payload / an obligation off the contract or
not for all inputs / an axiom outside the trio / a gate that cannot go red
/ an undisclosed red commit. MINOR / NOTE below that.

## 0. Verdict

**MERGE-WITH-FIXES — no MAJOR.** Every MAJOR criterion was checked and
none fires: the `.lem` diff is declare lines + comments only; the OCaml
generated tree is byte-identical to the mainline's (independent
comparison, §1); all 41 measured obligations are the contract's statement,
quantified over every input (the four keep-binder ones over `[LemFuel]`
too), with cones ⊆ {propext, Classical.choice, Quot.sound} (gate + direct
probe, §3); the four re-payloaded sentinels are genuinely absorbing under
`exception_undef_bind` / `stExceptUndef_bind` / `nd_bind_lemFuel`, and
every DIRECT match site on their results propagates `Error` to a kill
(§4); the 21 reachable ambient workers are exactly the register (§5); the
two red commits are the two the record confesses and no other commit's
claim exceeds what its diff could run (§6); the head is green on Tier A +
Tier B (orchestrator's battery, §7).

The fixes asked for are MINOR — one gate-soundness hole (M1: the MEASURED
test checks the obligation's name and axioms but not its type; plant
shown green on a `True`-typed decoy), one gate-script discipline item
(M2), one record-accuracy item (M3) — listed in §9 with the evidence.
None changes a definition, a proof, or a lane baseline.

## 1. `.lem` discipline and OCaml byte identity

**`.lem` diff** (`git diff 753644005..5c9f5cba2 -- frontend/`, read in
full): eight files, and every `+`/`-` line is either a `declare {lean}
…` line or an OCaml comment `(* … *)`. DERIVED count of the added
`declare {lean} fuel_measure val` lines: core_aux 17, core_eval 2,
core_reduction 1, core_run_aux 4, defacto_memory 4, defacto_memory_aux 4,
utils 3 = **35** (the record's 35). Changed `declare {lean} fuel val`
payload lines: `eval_pexpr_aux2`, `eval_pexpr_aux_broken` (core_eval),
`full_eval_pexpr` (core_reduction), `load_character_array_aux` (formatted)
= **4**. No `let`, `val`, type or `open` line moved. `declare {lean}` is
Lean-target-only by lem's semantics, so the OCaml backend's input is
unchanged by construction.

**Byte identity, independently.** The brief's method ("compare against
the mainline's committed tree via `git show 753644005:…`") is not
available: `ocaml_frontend/generated/` is gitignored (`.gitignore:20`) and
so is `ocaml_frontend/lem_sync.sha256` — neither exists in ANY commit
(`git ls-tree 753644005 ocaml_frontend/generated` → 0 entries). The
record's own §5 evidence is a `diff -rq` against a snapshot in the
worker's ephemeral `.tmp/c2/`, which is gone. I therefore compared against
the PRIMARY checkout, which is parked on mainline `753644005`
(`git -C cerberus-lean rev-parse HEAD` = `7536440057648d…`, branch
`mdd/cerberus-lean`) and carries its own generated tree stamped from the
mainline's `.lem` text:

```
$ cat cerberus-lean/ocaml_frontend/lem_sync.sha256
src 03c176935c3e37a0f5b9a00192796ddf42dd6bd09ebf3bb3a41c028c25f8f10c
gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100
$ cat worktrees/cerberus-lean-arc/zero-discrepancy/ocaml_frontend/lem_sync.sha256
src 928a08cd72f10e899385191821266f915008a499c4033de8b44893b9fcac2e8a
gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100
$ diff -rq cerberus-lean/ocaml_frontend/generated worktrees/cerberus-lean-arc/zero-discrepancy/ocaml_frontend/generated && echo 'DIFF-RQ: IDENTICAL'
DIFF-RQ: IDENTICAL
```

86 files in each tree (DERIVED `ls | wc -l`). The `src` stamps differ
(the `.lem` text moved: the declares), the `gen` stamps agree, and the
full-tree `diff -rq` is empty: the OCaml generated tree at C2 is
byte-identical to the mainline's. Nothing was regenerated for this check.

NOTE N1 (record/method): the record §5 states byte identity against an
ephemeral snapshot; a future record should cite a reproducible comparand
(the primary's stamped tree, as here, or commit the `gen` stamp).

## 2. The (A)/(B)/(C) gate — `check_fuel_forms.sh` + `FuelFormsTool.lean`

Read in full (`scripts/check_fuel_forms.sh` 113 lines,
`lean_frontend/test/Unit/FuelFormsTool.lean` 189 lines).

**Reachability.** `closure env entries` is the transitive
`ConstantInfo.getUsedConstantsAsSet` closure (types + values) from
`drive`, `initial_driver_state`, `CerbND.runND/runND1/runND1Trace`,
`CerbCall.driveCall`, extended at every node by the node's
`Lean.Elab.Structural/WF.eqnInfoExt` mutual block (F-C2-6). This is the
kernel's view of the definitions: it does not descend through `opaque`
constants (`@[implemented_by]` targets, `partial def` bodies,
`@[extern]`). Is that sound for THIS claim? I enumerated every such
boundary in the ban surface — the axiom-census PIN set in
`scripts/unsafebaseio_allowlist.txt` (`PIN IMPLBY/UNSAFEDECL/EXTERN`,
enforced both ways by `check_theorem_axioms.sh`) — and read each target:

| boundary (implemented_by / extern / unsafe) | body | fuel'd call hidden? |
|---|---|---|
| `CerbGlobal.*_impl` ×11 (`backend_name`, `has_switch`, `isDefacto`, …) | `IO.Ref` reads / constants | none |
| `CerberusFresh.digest_impl`, `digestPure`, `md5Hex`, `digestIO`, `setDigestIO` | md5 of a string, IO refs | none |
| `CerberusFresh.forceIO_impl` / `forceThunkIO` | runs the thunk `f : Unit → b` it is GIVEN — the thunk is a kernel-visible argument at the call site, so its constants are in the caller's cone | none hidden |
| `CerberusImpl.typeof_enum_impl`, `register_enum_impl` | enum-registry ref | none |
| `CerbUtils.begin/end_timing_impl`, `STD_impl`, `boundedIntegerImpl`, `logRef`, `timingStackRef` | refs / `pure lo` | none |
| `CerbMem.beqMemValueImpl` (`CerbMem.lean:223-236`) | structural `==`; `ctype` `==` is `CerbCtypeInstances.lean:30` `beq := ctypeEqual` | `ctypeEqual` is MEASURED (fuel-free) — no ambient call |
| LemLib `failwithIImpl`, `fuelExhaustedWithImpl` | panics | none |
| `CabsImport.partial def jsonTo*` ×20+ | front-end JSON import; not on the drive cone | n/a |

So no fuel'd worker is reached through an opaque seam the closure does not
traverse; the (C) verdicts stand. NOTE N2: the record §7 and the script
header cite `check_exec_totality` as the guard that no `partial`/
`opaque`/`implemented_by` boundary exists on the drive cone's generated
modules — that gate scans ONLY `partial def/instance`
(`check_exec_totality.sh:130`); the `opaque`/`implemented_by`/`extern`
coverage actually comes from the axiom-census PIN set above. The claim is
true; the cited guard is the wrong one for two of the three keywords.

**MEASURED.** The tool looks up `Name.str w.getPrefix (f ++
"_measure_sufficient")` — i.e. the FULLY QUALIFIED obligation in the
worker's own namespace (`CerbMem.typeofMval_lemFuel` →
`CerbMem.typeofMval_measure_sufficient`; a generated root-namespace worker
→ the root-namespace generated obligation in `<Module>_auxiliary`). A
same-suffix theorem in another namespace does not satisfy it (the
`proof=` column that searches by suffix is informational). The
brief's evasion question is answered: qualified, yes. BUT the tool checks
only that the constant EXISTS and what axioms its cone uses — it never
inspects the constant's TYPE. For the 38 generated obligations the type is
lem's (`<Module>_auxiliary` applies the hand-written proof at the exact
generated statement, so a wrong-typed proof fails the BUILD); for
hand-written seams (the 3 `CerbMem` rows today, any future one) nothing
but review enforces the shape. Plant (§2.1 below): a scratch module
declaring `theorem CerbMem.sizeofCtype_measure_sufficient : True :=
trivial` flips the PENDING worker `CerbMem.sizeofCtype_lemFuel` to
MEASURED in the tool's table. In the current tree the POLICY still goes
red — but only because that worker is a register row (the stale-pin
check), i.e. by accident of the register, not by the MEASURED test. A NEW
hand-written ambient worker with a `True`-typed same-name theorem would
read MEASURED and green. → **MINOR M1** (fix: the tool should check the
obligation's conclusion is `<worker> lemFuel xs… = <wrapper> xs…` with a
`_ ≤ lemFuel` hypothesis — head symbols suffice; ~15 lines).

**ABSORBING.** `hasAtom && hasHead && !hasSentinel` over the `_zero`
lemma's RHS constants: atom ∈ {`CerbFuel.fuelExhaustedLoc`,
`CerbND.fuelExhaustedKill`}, head ∈ {`nd_action.NDkilled`,
`nd_status.Killed`, `t0.Error`}, no `fuelExhausted`/`fuelExhaustedWith`/
`failwithI`/`panic`/`panicCore`. It is a constant-set test, not tied to
the worker's monad: an RHS such as `if c then NDkilled (Error0 atom …)
else v` or `some (Error atom …)` in an `Option` monad would also pass.
No such payload exists in the tree (all 13 RHSs read, §4), so this is a
gate-design NOTE, not a live gap → **NOTE N3** (fix: require the RHS to
be literally an application of the head, i.e. `rhs.getAppFn` — or the
`ND (fun st => (NDkilled …, st))` / `fun st => Result (Error …, st)`
shapes — rather than "mentions").

**Absorbing in the monad — checked at the binds.** Verbatim:

```
generated/Exception_undefined.lean:46-47
def  exception_undef_bind … (m : exceptM (t0 c) b) (f : c → exceptM (t0 a) b)  : exceptM (t0 a) b :=
  match  m with  |  Result ( Defined  z) =>  f  z |  Result ( Undef  loc1  ubs) =>  except_return  (undef  loc1  ubs) |  Result ( Error  loc1  str) =>  except_return  (error0  loc1  str) |  Exception  err =>  fail0  err
generated/State_exception_undefined.lean:49-50
def  stExceptUndef_bind … : e → exceptM ((t0 b ×a)) c :=  fun (st : e) =>
  match  m  st with  |  Result  (Defined  z,  st') =>  f  z  st' |  Result  (Undef  loc1  ubs,  st') =>  stExpect_return  (undef  loc1  ubs)  st' |  Result  (Error  loc1  str,  st') =>  stExpect_return  (error0  loc1  str)  st' |  Exception  err => …
generated/Nondeterminism.lean:210-212  (nd_bind_lemFuel, the succ arm)
  … |  (NDkilled  r,  st') =>  (NDkilled  r, st') | …
```

`Result (Error …)` never runs the continuation under either undefined-monad
bind; `NDkilled` is re-emitted unchanged by `nd_bind`. The direct
(non-bind) consumers of the re-payloaded functions' results are in §4.

**Policy and plants.** RED on: a reachable AMBIENT row not in the
register; a register row that is not a reachable ambient row (both
directions); a MEASURED row whose `axioms=` is not `ok` or that carries
`BAD[`; no `FUEL_FORMS_SUMMARY` line; vacuity (< 60 / < 30 / < 10). The
tool itself exits 1 on a missing entry constant or < 30 workers. Five
plants on a scratch copy of the table (`--selftest`, re-run by me after
the battery, §2.1). Two discipline notes on the script → **MINOR M2**:
`table_of_tree` runs `lake build fuel-forms-tool >/dev/null 2>&1` and the
tool with `2>/dev/null` — fail-closed via the exit code and the summary
line, but the diagnostics of a failing build/tool are discarded (CLAUDE.md:
"Never `2>/dev/null` an install/build step"); and `policy` counts
`n_unr`/`n_pend` from the table without asserting `n_all = n_meas + n_abs
+ n_pend + n_unr` (a row with an unexpected form string would be silently
uncounted — today none exists).

### 2.1 Plants and evasion, re-run after the battery

`scripts/check_fuel_forms.sh --selftest` (worker's worktree, after `=== DONE`, 9.4 s wall), verbatim:

```
check_fuel_forms: SELFTEST — plants on a scratch copy of the classification table (loud plant banner; nothing in the tree is touched)
  PLANT OK   [P1 measured->ambient reachable (step_eval_pexpr)] -> check_fuel_forms: FAIL — fuel'd worker(s) REACHABLE from drive with an opaque (fail-open) exhaustion, not in /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/zero-discrepancy/scripts/fuel_forms_pending.txt:
  PLANT OK   [P2 stale pending pin (hack removed from the table)] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
  PLANT OK   [P3 measured obligation with sorryAx in its cone] -> check_fuel_forms: FAIL — measured obligation(s) with an axiom cone outside [propext, Classical.choice, Quot.sound] (or no proof constant):
  PLANT OK   [P4 truncated table] -> check_fuel_forms: FAIL — no FUEL_FORMS_SUMMARY line (the tool did not complete; fail-closed)
  PLANT OK   [P5 phantom register row] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
  UNPLANTED:
    check_fuel_forms: OK (81 fuel'd workers: 41 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 21 reachable-AMBIENT = the 21 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_fuel_forms: SELFTEST OK (5 plants red with the declared label; unplanted table green)
```

**The raw table** (the tool run directly with the gate's module list, saved
to the audit scratch), summary line verbatim:
`FUEL_FORMS_SUMMARY	workers=81	measured=41	absorbing=13	ambient_reachable=21	ambient_unreachable=6	closure_size=10398`.
DERIVED from it: the reachable-AMBIENT set is EXACTLY the register's 21
first fields (`diff` of the two sorted lists empty: `REGISTER ==
REACHABLE-AMBIENT SET`); the 6 unreachable ambient are
`CerbMem.memValueToBytes_append_lemFuel CerbMem.reconstructValue_indexed_lemFuel
list_unfoldr_aux_lemFuel mkUnspec_lemFuel simplify_integer_value_base_lemFuel
zeros_aux_lemFuel` (the record's six); the 13 ABSORBING are the record's
13 (12 `yes`, `eval_pexpr_aux_broken_lemFuel` `no`); MEASURED 21 `yes`
+ 20 `no`. The 21 = the record §2 table's 18 generated M rows marked
`yes` (DERIVED: `awk` over the table's form and reach columns —
`add_to_asw ctypeEqual in_pattern subst_wait loadedValueFromMemValue
memValueFromValue subst_sym_pexpr subst_sym_expr subst_pattern_val
unsafe_subst_sym_pexpr unsafe_subst_sym_expr subst_pattern match_pattern
collect_saves_aux update_env_aux has_ccall pull_constrained
step_eval_pexpr`) + the 3 `CerbMem` seams — row for row the tool's `yes`
list. The record's TALLY line under the table says "M 38 … 20
drive-reachable": its own table has 18 → NOTE N7 (arithmetic in a derived
tally; nothing red/green depends on it). Every MEASURED row reads
`axioms=ok`. Rows the brief asked
about, verbatim:

```
FUEL_FORM	are_compatible_lemFuel	AMBIENT	yes/front	zero=are_compatible_lemFuel_zero rhs-consts=[fuelExhausted, Bool, Bool.false]
FUEL_FORM	simplify_integer_value_base_lemFuel	AMBIENT	no/-	zero=simplify_integer_value_base_lemFuel_zero rhs-consts=[Sum.inr, Int, integer_value_base]
FUEL_FORM	CerbMem.sizeofCtype_lemFuel	AMBIENT	yes/-	no _zero lemma
```

**The evasion plant (M1).** A scratch module OUTSIDE the tree
(`.tmp/audit/evasion/AuditEvasion.lean`: `import CerbMem` +
`theorem CerbMem.sizeofCtype_measure_sufficient : True := trivial`),
compiled with the toolchain's `lean --root=… -o …` against the worker's
`LEAN_PATH`, then the tool run with that module appended to the gate's
list (`LEAN_PATH` extended by the scratch dir; nothing in the tree
touched). Verbatim:

```
FUEL_FORM	CerbMem.sizeofCtype_lemFuel	MEASURED	yes/-	obligation=CerbMem.sizeofCtype_measure_sufficient axioms=ok
FUEL_FORMS_SUMMARY	workers=81	measured=42	absorbing=13	ambient_reachable=20	ambient_unreachable=6	closure_size=10398
```

The script's `policy` function on that table, with the tree's register:
`check_fuel_forms: FAIL — pending register row(s) no longer a reachable
ambient worker (stale pin; edit the register):` / `CerbMem.sizeofCtype_lemFuel`
(rc 1 — red, but by the register, not by the MEASURED test). With the
register row removed — the "new hand-written ambient worker with a
decoy theorem" case — `check_fuel_forms: OK (81 fuel'd workers: 42
MEASURED (every obligation + proof cone ⊆ the standard three), 13
ABSORBING, 20 reachable-AMBIENT = the 20 rows of fuel_forms_pending.txt
exactly, 6 ambient unreachable from the drive cone)` (rc 0 — GREEN on a
`True`-typed "obligation"). The fully-qualified-name check the brief asked
about IS in place (a root-namespace `sizeofCtype_measure_sufficient` would
not have matched); the TYPE is what is unchecked.

## 3. Obligations

**Statements (all 41).** Every generated obligation in
`generated/*_auxiliary.lean` (DERIVED count by module: Core_aux 17,
Defacto_memory_aux 5, Core_run_aux 4, Defacto_memory 4, Utils 3,
Core_eval 2, Core_reduction 1, Ctype 1, Core 1 = 38) has the contract
shape `theorem f_measure_sufficient (xs…) (lemFuel : Nat) (lemMeasureLe :
<measure> ≤ lemFuel) : f_lemFuel lemFuel xs… = f xs… :=
<Module>_lemMeasureProofs.f_measure_sufficient xs… lemFuel lemMeasureLe`,
binders mirrored from the wrapper (type parameters, `[Eq0 a]`,
`[MapKeyType a]`, `_lemReader_tagDefs`). Since the auxiliary applies the
hand-written constant at exactly this type, a proof with an extra
hypothesis, a different measure, or a different function could not have
built — and the tree builds (`Build completed successfully (373 jobs)` in
the record; the orchestrator's battery rebuilt it, §7). The three
hand-written `CerbMem` obligations (`CerbMem_lemMeasureProofs.lean`,
read in full) are the same shape by hand:

```
theorem typeofMval_measure_sufficient (mval : MemValue) (lemFuel : Nat)
    (lemMeasureLe : memValueSize mval ≤ lemFuel) :
    typeofMval_lemFuel lemFuel mval = typeofMval mval
theorem unqualifyAndUnatomic_measure_sufficient (cty : ctype) (lemFuel : Nat)
    (lemMeasureLe : ctype.lemSize cty ≤ lemFuel) :
    unqualifyAndUnatomic_lemFuel lemFuel cty = unqualifyAndUnatomic cty
theorem memValueToBytes_measure_sufficient [LemFuel] (ambient : CerbTags.TagDefsMap) (funptrmap : Funptrmap)
    (val_ : MemValue) (lemFuel : Nat) (lemMeasureLe : memValueSize val_ ≤ lemFuel) :
    memValueToBytes_lemFuel lemFuel ambient funptrmap val_ = memValueToBytes ambient funptrmap val_
```

and the wrappers are `typeofMval mval := typeofMval_lemFuel (memValueSize
mval) mval`, `unqualifyAndUnatomic cty := unqualifyAndUnatomic_lemFuel
(ctype.lemSize cty) cty`, `memValueToBytes [LemFuel] … val_ :=
memValueToBytes_lemFuel (memValueSize val_) …` (`CerbMem.lean` diff) — so
`f x = f_lemFuel (μ x) x` by `rfl` as the contract requires.

**The four keep-binder wrappers** (`memValueFromValue`, `step_eval_pexpr`,
`easy_update_mem_value_aux`, `memcmp_load_aux`) plus the seam
`memValueToBytes`: the obligation and the stability lemma carry
`[LemFuel]` as an instance-implicit binder, i.e. `∀ inst : LemFuel`, and
the equation is between `f_lemFuel lemFuel …` and `f …` at the SAME
instance — so the worker's OWN counter is bounded by the measure while the
ambient callee (`are_compatible0`, `CerbMem.sizeofIval`/…, `mkUnspec`/
`simplify_integer_value_base`, `impl_load`, the layout oracle) reads the
full ambient on both sides; that is exactly the ruling "each fuel'd call
starts from the FULL ambient". The stability lemmas quantify over both
fuels and every parameter (`step_eval_pexpr_stable_aux [LemFuel] (k :
Nat) : ∀ td n loc1 pcl ce env1 mso file1 hc e (f g : Nat), …`,
`Core_eval_lemMeasureProofs.lean:125-129`; `memValueFromValue_stable_aux
[LemFuel] (k) : ∀ td ty1 cval (f g), …`, `Core_aux_lemMeasureProofs.lean:
166-169`; `easy_update_mem_value_aux_stable_aux`, `memcmp_load_aux_stable_aux`
likewise, `Defacto_memory_lemMeasureProofs.lean:91-94, 126-129`).

**Forbidden tokens** — `grep -n 'set_option\|sorry\|native_decide\|
decide\b\|admit\|^axiom\|axiom \|unsafe\|partial\|implemented_by\|
ofReduce\|bv_decide\|maxRecDepth\|maxHeartbeats'` over the 10
`*_lemMeasureProofs.lean` + `CerbMeasureLemmas.lean`: the only
`set_option` is `set_option autoImplicit false` (hygiene, not a bump —
one per module); `decide` occurs only as `absurd h (by decide)` on a
closed `Nat` goal ×4 in `Defacto_memory_aux_lemMeasureProofs.lean:111,
140,169,198` (the kernel `Decidable` evaluation, not `native_decide`);
`unsafe`/`partial` occur only inside identifiers
(`unsafe_subst_sym_pexpr…`) and doc text; no `sorry`, `admit`, `axiom`.
`to_congr` (`CerbMeasureLemmas.lean:231-247`) is `iterate 12 (all_goals
(try to_congr_step))` over `apply lmap_congr | … | congr 1` — plain
kernel-checked tactic steps. The `by decide` sites are not a gate concern
(the kernel evaluates `Nat.decEq`), noted only because the brief asked.

**Axiom cones.** The gate probes all 41 (`collectAxioms` on the
obligation, which is transitive through the delegated proof) — its OK
line is quoted in §2.1. Direct probe on five (three seams/keep-binders
the brief named plus two), after the battery:

```
$ lake env lean .tmp/audit/axprobe.lean     (imports Core_aux_auxiliary, Core_eval_auxiliary, Defacto_memory_auxiliary, CerbMem_lemMeasureProofs)
'memValueFromValue_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'step_eval_pexpr_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memValueToBytes_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.typeofMval_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'memcmp_load_aux_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
@memValueFromValue_measure_sufficient : ∀ [inst : LemFuel]
  (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) (ty1 : ctype) (cval : value) (lemFuel : Nat),
  ty1.lemSize ≤ lemFuel →
    memValueFromValue_lemFuel lemFuel _lemReader_tagDefs ty1 cval = memValueFromValue _lemReader_tagDefs ty1 cval
@CerbMem.memValueToBytes_measure_sufficient : ∀ [inst : LemFuel] (ambient : CerbTags.TagDefsMap)
  (funptrmap : CerbMem.Funptrmap) (val_ : CerbMem.MemValue) (lemFuel : Nat),
  CerbMem.memValueSize val_ ≤ lemFuel →
    CerbMem.memValueToBytes_lemFuel lemFuel ambient funptrmap val_ = CerbMem.memValueToBytes ambient funptrmap val_
```

The `#check` lines show the `[LemFuel]` quantification of the keep-binder
statements as elaborated (`∀ [inst : LemFuel] …`).

## 4. Absorbing payloads (the four re-payloaded rows)

The generated `_zero` statements (read in `generated/Core_eval.lean`,
`Core_reduction.lean`, `Formatted.lean`; the record §3 quotes them
verbatim and they match). Direct (non-bind) consumers of each function's
result, every one read:

| function | consumers of its result | Error handling |
|---|---|---|
| `eval_pexpr_aux2` | `Driver.lean:271` direct `match` (in `print_eval_conv_aux`); `Core_run.lean:169,172` via `runEU` (→ `Result (Error …, st)`) under `stExceptUndef_bind`; `Core_reduction.lean:86` via `runEU` | `Driver.lean:271`: `\| Result ( Error loc1 err) => nd_return (Sum.inr (Error loc1 err))` — the `t0.Error` travels as a value to `Driver.lean:286`'s `\| Error loc1 str => kill (Error0 loc1 str)`; `runEU` maps `Result (Error…)` to `Result (Error…, st)` (`State_exception_undefined.lean:57`), absorbed by `stExceptUndef_bind` |
| `full_eval_pexpr` | `Core_reduction.lean` `full_eval_pexpr'` — every use is the FIRST argument of `stExceptUndef_bind`/`stExceptUndef_mapM` (SeqRMW, Eccall, Eproc, Efs, Eif, Elet/Ewseq folds) or is passed as the `full_eval_pexpr1` parameter of `step_action` (`:434`), `process_impl_proc` (`:488`), `one_step0` (`:357`) — inside those, every use is again under `stExceptUndef_bind` (read: Create/CreateReadOnly/Store/Load/Alloc/Kill arms; Epure/Elet/Eif arms; the impl-proc arms) | absorbed at the bind; `stExceptUndef_run` result → `Driver.lean:286` `kill (Error0 …)` |
| `eval_pexpr_aux_broken` | `Core_eval.lean:182` (`eval_pexpr`: `\| Result z => Sum.inr z`), `Core_run.lean:165` via `runEU` | unreachable from `drive` (gate `no`); `Sum.inr (Error …)` is a `t0` value the (front-end/Core_run) caller matches — not on the drive cone, recorded for completeness |
| `load_character_array_aux` | `Formatted.lean:460` (its own recursion under `nd_bind`), `:476` (`load_character_array`: `nd_bind … (fun ptrval' => load_character_array_aux …)`) | `NDkilled` re-emitted by `nd_bind_lemFuel` (`Nondeterminism.lean:212`); the runner leaves `Killed` |

The remaining nine (B) rows (`nd_bind`, `liftND`, `liftAction`, `driver2`,
`drive_nonmemory_steps_aux2`, `print_eval_conv_aux`, the three `CerbND`
runners) are unchanged from C1 (`git show 753644005:lean_frontend/CerbND.lean`
already has `runNDFuel_zero`/`runND1Fuel_zero`/`runND1TraceFuel_zero` at
`:334-340`; the Driver/Nondeterminism payloads are the C1 ND kill).

**Runtime probe at a tiny `--fuel`** (after the battery; the driver reads
`--fuel N` after the mode flag; `LEAN_ABORT_ON_PANIC=1` as the lanes):

Probe programs (audit scratch; cabs-json by the worker's fresh oracle
binary; oracle reference `Defined {value: "Specified(0)", …}` for all):
`pexpr_short.c` (`return x - 1`), `pexpr_chain10.c` (`x+…+x` 10 terms
`- 10`), `pexpr_chain.c` (40 terms `- 40`), `printf_short.c`
(`printf("%s\n", "abc")`), `printf_str.c` (a 62-char string). The Lean
driver `--batch --fuel N <json>` under `LEAN_ABORT_ON_PANIC=1` (the lanes'
setting); one line per run, `exit=` and the verdict/stderr, verbatim
(backtraces cut):

```
pexpr_short  fuel=1..20   exit=1   Error {msg: "lem: fuel exhausted"}
pexpr_short  fuel=30..120 exit=0   Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
pexpr_chain10 fuel=8      exit=1   Error {msg: "lem: fuel exhausted"}
pexpr_chain10 fuel=10..30 exit=134 lem: fuel exhausted backtrace: …
pexpr_chain10 fuel=40..80 exit=1   Error {msg: "lem: fuel exhausted"}
pexpr_chain10 fuel=100..200 exit=0 Defined {value: "Specified(0)", …}
pexpr_chain  fuel=1..8    exit=1   Error {msg: "lem: fuel exhausted"}
pexpr_chain  fuel=10..120 exit=134 lem: fuel exhausted backtrace: …
pexpr_chain  fuel=150,200 exit=1   Error {msg: "lem: fuel exhausted"}
pexpr_chain  fuel=300..2000 exit=0 Defined {value: "Specified(0)", …}
printf_short fuel=5       exit=134 lem: fuel exhausted backtrace: …
printf_short fuel=8..30   exit=1   Error {msg: "lem: fuel exhausted"}
printf_str   fuel=5       exit=134 lem: fuel exhausted backtrace: …
printf_str   fuel=10..75  exit=1   Error {msg: "lem: fuel exhausted"}
printf_str   fuel=77..200 exit=0   Defined {value: "Specified(0)", stdout: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ\n", …}
(default fuel: all five exit=0 with the oracle's verdict)
```

Reading (inference labelled as such): (i) at NO fuel does any run print a
VALUE other than the oracle's — every sub-threshold run is the kill
(`Error {msg: "lem: fuel exhausted"}`, exit 1: an ABSORBING row's kill
reaching the runner) or the panic (exit 134: an AMBIENT register row's
`fuelExhausted`, loud under the flag). (ii) The kill band above the panic
band scales with the expression (10 terms: 40–80; 40 terms: 150–200) —
the step-until-value loops (`full_eval_pexpr`, class (B)) exhausting into
`Result (Error …)` → `kill (Error0 …)`, as §4's table says; the `printf`
kill band's upper edge tracks the string length (4 chars: > 30 still
killed; 62 chars: killed to 75, value at 77) — `load_character_array_aux`
walking the bytes under `nd_bind`, exhausting into the ND kill (its new
payload; the OLD payload `nd_return []` would have printed an EMPTY string
and exit 0 here). (iii) The panic bands (`pexpr_chain*` 10–30/10–120,
`printf_*` at 5) are AMBIENT register rows — by the gate every reachable
ambient worker is one; the scaling with the expression's term count
points at the pure step loops `to_pure`/`hack`, the `printf` one at
`many`/`many1` (the format parser) — the driver has no debug flag to name
the site, so this attribution is inference, not measurement. (iv) Without
`LEAN_ABORT_ON_PANIC=1` the binary REFUSES at startup (`exit=2
cerberus-lean: refused — LEAN_ABORT_ON_PANIC is not set: …`, the Z1
refusal) — so the in-process fail-open of the pending rows is a consumer
(refined-cerberus) matter exactly as the record and the typed-failure
ruling state, not a binary one.

OCaml output unchanged: §1 (the payloads are `declare {lean}` lines).

## 5. Pending register (`scripts/fuel_forms_pending.txt`, 21 rows)

Read in full: 21 non-comment rows, each `<worker> <class> <reason>`;
classes `tag-lookup` ×9, `point-free` ×6, `pure-loop` (`hack`),
`opaque-arg` ×2 (`to_pure`/`to_pures`), `parser` ×2, `precondition` ×1.
Spot-checks against the generated code:

- `hack_lemFuel` (`generated/Driver.lean:436`): `match step_eval_pexpr … 0
  … pexpr1 with | Result (Defined pexpr') => (match valueFromPexpr pexpr'
  with | some cval => cval | none => hack_lemFuel lemFuel … pexpr') | _ =>
  failwithI "Driver.hack, UNDEF/ERROR: …"` — codomain is the pure Core
  `value`; no absorbing element exists → not (B) without a lem body change
  (D-C2-4). Reason correct. (Its inner `step_eval_pexpr` is MEASURED, so
  the only opaque exhaustion is `hack`'s own.)
- `to_pure_lemFuel` (`generated/Core_aux.lean:592-594`): `to_pure_aux :=
  fun pat pe1 e2 => match subst_pattern pat pe1 e2 with | some e =>
  to_pure_lemFuel lemFuel e | …` — the recursion argument is
  `subst_pattern`'s RESULT; `subst_pattern_val`'s ill-typed arm is
  `failwithI "WIP: Core_aux.subst_pattern_val ==> ctor= …"` and
  `failwithI` is `@[implemented_by failwithIImpl, never_extract] opaque
  failwithI … := default` (`LemLib.lean:176-177`) — no size fact about an
  opaque constant's value is provable. Reason correct (F-C2-3).
- `showNonNegativeWithBasis_aux_lemFuel` (`generated/Formatted.lean`):
  `match lemNatDiv n b, lemNatMod n b with | r, d => if r == 0 then … else
  showNonNegativeWithBasis_aux_lemFuel lemFuel (…) useUpper b r`;
  `def lemNatDiv (a b : Nat) : Nat := if b == 0 then lemDivByZero else a / b`,
  `lemDivByZero := failwithI "Division_by_zero"` (`LemLib.lean:1381-1391`).
  At `b = 0` the next argument is opaque; at `b = 1`, `r = n` and the
  recursion never reaches 0 (both fuels exhaust to the same constant
  payload). Reason correct (F-C2-7); the stated precondition `b ≥ 2`
  matches the callers (8/10/16).
- `many_lemFuel` (`generated/Monadic_parsing.lean`): `| 0 => fuelExhausted
  (ParserM (fun _ => []))`; the recursion is inside `ParserM (fun cs => …
  many1_lemFuel lemFuel p …)` — the depth is `cs`'s length, a lambda-bound
  variable, not a parameter; the parser zero `[]` is also the ordinary
  failure. Reason correct (D-C2-5).

Fail-closed both ways: plants P2 (a register row whose worker leaves the
table → "stale pin") and P5 (a phantom row → "stale pin") re-run red in
§2.1; P1 (a reachable worker flipped to AMBIENT → "REACHABLE from drive
with an opaque (fail-open) exhaustion") covers the other direction.

## 6. Commit discipline (F-C2-8)

The six commit messages read against `git show --stat`:

| commit | files | verification claimed | consistent with the diff? |
|---|---|---|---|
| `bd8e9c75c` 1/n | 8 `.lem` + 7 proof modules + `CerbMeasureLemmas` + `CerbMem` + manifest/lakefile + `TotalityProofTest` (20 files) | OCaml byte identity; `lake build` 372 jobs; `test_unit.sh` green; oracle stamp; exec minimal `BASELINE OK` (record §12) | yes — the fuel-forms gate did not yet exist, so "test_unit.sh green" is the C1 gate set; nothing in the diff could have made a then-existing gate red that the message hides |
| `e2bbacfc1` 2/n | gate + tool + register + `test_unit.sh` wiring + `check_theorem_axioms.sh` note (6 files) | message: `--selftest` 5 plants + OK — **RED at the axiom-cone gate** (`unsafe def main`), confessed in 2b and the record | the confessed red |
| `b64748d52` 2b/n | `FuelFormsTool.lean` 1 line | `check_theorem_axioms` OK, `check_fuel_forms` OK, `test_unit.sh` rc 0 | plausible for a one-line `unsafe` removal |
| `b25ea0aac` 3/n | `CerbMem.lean`, `CerbMem_lemMeasureProofs.lean`, `CerbMeasureLemmas`, `Defacto_memory_lemMeasureProofs`, manifest/lakefile, `check_fuel_forms.sh`, register 24→21 (8 files) | `lake build` 373; exec minimal `BASELINE OK` — **RED at the fuel-forms gate** (the 3 seam workers read AMBIENT-reachable and were no longer register rows), confessed in 3b and the record | the confessed red — and its MECHANISM is right: removing three register rows while the gate could not see their obligations is exactly the "new reachable ambient" red the gate is designed to give |
| `75240ce01` 3b/n | `check_fuel_forms.sh` (+6/−2: import `*_lemMeasureProofs`) | `--selftest` 5 plants + `OK (81 … 41 … 13 … 21 …)`; `test_unit.sh` rc 0 (checked explicitly) | yes |
| `5c9f5cba2` 4/n | docs only (5 files) | "the battery of §6 on the 3b head; docs-only" | yes (no code) |

No commit beyond the two confessed claims a green it could not have had.
The FINAL head is green on every gate: the orchestrator's battery (§7)
ran `test_unit.sh` (rc 0) and every Tier A/B lane on this head with fresh
stamped binaries. Bisect caveat stands as the record says (§12 last
paragraph). NOTE N4: 1/n's record row says "`test_unit.sh` green" without
saying which gate set — the pre-C2 one; harmless, but a claim should name
its gate list when the gate list is about to change in the same slice.

## 7. Lanes (after the battery; verbatim)

**The orchestrator's battery** (`.tmp/c2-reverify.log`, this head,
fresh stamps `check_driver_fresh: oracle OK (bin b92ea46aceb2…, src
754ef1e991de…)` / `lean OK (bin 797d1383ba69…, src 0760dd53cd77…)`):

All 25 entries `rc=0` (DERIVED from the log's `=== <lane>` / `--- rc=`
pairs): `check_driver_fresh --check`, `test_unit.sh`, `test_exec.sh
--check-baseline` (minimal), `…exec_coverage_baseline.txt tests/coverage`,
`…exec_debug_baseline.txt tests/debug`, `…exec_float_baseline.txt
tests/float`, `test_bytes.sh`, `test_libc_exec.sh`, `test_multi_tu.sh`,
`test_parse.sh`, `test_core.sh`, `test_elab.sh`, `test_libxml2_uri.sh`,
`test_cn_coverage.sh --check-baseline`, `test_parse.sh tests/ci`,
`test_core.sh tests/ci`, `test_verify.sh`, `test_immaculate.sh`,
`test_speclab.sh --selftest`, `test_speclab.sh --plant`,
`test_hang_plant.sh`, `test_kill_plant.sh`, `test_fuel_plant.sh`,
`test_libxml2.sh`, `test_gcc_oracle.sh --check-baseline`; then `=== DONE`.
Key lines verbatim:

```
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0   / BASELINE OK
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0  / BASELINE OK
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0     / BASELINE OK
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0      / BASELINE OK
SUMMARY: exec_match=9 neg_pinned=5 fail=0
SUMMARY: match=11 diff=0 / ALL MATCH RECORDED BASELINE
SUMMARY: total=2 match=2 fail=0 / ALL PASSED
Success rate:   100% (of cerberus successes) / ALL PASSED            (parse, core; parse ci, core ci)
SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0           (elab)
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 / BASELINE OK (213 entries, exact match)
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
test_speclab: PASS (both pipelines agree on Specified(0))  /  test_speclab: PASS (both pipelines agree on Specified(2))
test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each) / ALL PASSED                    (libxml2)
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1 / gcc second-oracle lane OK
```

Every number equals the record §6's (zero movement vs C1; the record's
lines were the worker's run, these the orchestrator's). Not in the
orchestrator's battery: the five `test_speclab_<g>.sh --gate` rows the
record §6.2 lists (B6c–g) — worker-run only; I did not run them (not
among the lanes named for me).

**Re-run by me, serially, after `=== DONE`:**

```
$ ./scripts/test_unit.sh                       (1:48 wall)        rc=0
Total: 6 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (279 files scanned comment-stripped — generated 204, hand-written+test 41, LemLib 34; 0 sorry tokens)
check_no_fuel_numerals: OK (284 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
gen_fuel_parametricity: OK (29 ambient fuel wrappers in the generated tree = the 29 pins of TotalityProofTest.lean Part 1, both directions)
check_lakefile_roots: OK (203 roots = 203 generated modules + the exe root Main; 85 auxiliary modules all built)
check_fuel_forms: SELFTEST OK (5 plants red with the declared label; unplanted table green)
check_fuel_forms: OK (81 fuel'd workers: 41 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 21 reachable-AMBIENT = the 21 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
$ ./scripts/test_verify.sh                     (40 s wall)        rc=0
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
$ ./scripts/test_immaculate.sh                 (52 s wall)        rc=0
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

Three of the unit lane's gate lines differ from the record §6/§7's quotes
for "this head": the record has `check_lakefile_roots: OK (202 roots …)`,
`check_no_fuel_numerals: OK (281 files …)`, `check_sorry_token: OK (276
files …)`; the head reads 203 / 284 / 279. The delta is the 3/n commit's
`CerbMem_lemMeasureProofs.lean` (+1 root, +3 scanned files: hand-written +
generated copy + …). The record's own sentence — row 1 "ran on this head
BEFORE the last two commits' verification" — says the quotes predate 3/n;
they are verbatim of an EARLIER tree, presented under a head-battery
heading. Nothing was red at either state; this is record accuracy →
**MINOR M3**.

## 8. Record and manifest — reproduced numbers

- **Disposition tally 41/13/6/21 = 81**: the gate's OK line (§2.1) reads
  `81 fuel'd workers: 41 MEASURED … 13 ABSORBING … 21 reachable-AMBIENT …
  6 ambient unreachable`. Reproduced.
- **Binder counts** (DERIVED, comment-stripped: `--` lines and nested
  `/- -/` blocks removed, then `[LemFuel]` occurrences), mainline tree =
  the primary checkout at `753644005` (its Lean generated tree stamped
  `src 03c17693…`), C2 tree = the worker's worktree:
  - generated model (every `generated/*.lean` NOT in
    `handwritten_copy.manifest`): **397 → 298** (record: 397 → 298).
  - hand-written seams `CerbCall` 3 → 3, `CerbMem` **39 → 36**, `CerbND`
    3 → 3, `Main` 3 → 3 = **48 → 45** (record: 48 → 45; `CerbMem.lean`
    39 → 36). Reproduced. (A first pass that stripped only `--` comments
    read 52 → 49 — the `[LemFuel]` mentions inside `/- -/` doc blocks;
    the record's "comment-stripped" rule is the right one.)
  - ambient generated wrappers (`^def f … := f_lemFuel LemFuel.fuel`, in
    non-hand-written generated files): **64 → 29** (record 64 → 29;
    `gen_fuel_parametricity: OK (29 …)` in the battery).
- **Manifest's fuel-free list** (§2 first row, 31 names) vs the measured
  set minus the four keep-binder ones: the 35 C2 declares minus
  {`memValueFromValue`, `step_eval_pexpr`, `easy_update_mem_value_aux`,
  `memcmp_load_aux`} = 31 names; the manifest lists exactly those 31
  (checked name by name against §1's `.lem` diff). Reproduced. (C1's
  three — `ctypeEqual`, `eq_core_base_type`, `fake_mem_value_eq` — were
  already fuel-free and are correctly not in the "changed for you" row.)
- **The three findings for the orchestrator's eye**: (i) "35 remaining"
  was 37 — the lem table's 38 M rows include `fake_mem_value_eq` and
  exclude `ctypeEqual`/`eq_core_base_type`; 38 − 1 = 37 candidates, 35
  proved, 2 (`to_pure`/`to_pures`) pending — consistent with the `.lem`
  diff (35 declares, `to_pure`/`to_pures` keep only `fuel val`). (ii)
  `mkListFromTo_aux`'s measure `Int.toNat (max2 + 1 - i) + 1` in the
  `.lem` (the lem table's `max2 - i` was one short; the record quotes the
  `omega` failure) — the committed measure is the corrected one; the
  obligation is the backstop, as designed (lem fuel-measure record N1).
  (iii) `are_compatible` (AilTypesAux) drive-reachable via
  `step_eval_pexpr`'s `PEare_compatible` arm — the gate table gives it
  `yes` and it is a register row (`are_compatible_lemFuel point-free …
  reached via step_eval_pexpr PEare_compatible`). Stated correctly.

## 9. Findings

No MAJOR.

**MINOR**

- **M1 — the MEASURED test checks the obligation's NAME and axioms, not its
  TYPE** (`FuelFormsTool.lean`, `if let some _ := env.find? obl then form
  := "MEASURED"`). Evidence: §2.1 plant — a scratch module with
  `theorem CerbMem.sizeofCtype_measure_sufficient : True := trivial` makes
  the tool print `CerbMem.sizeofCtype_lemFuel MEASURED`. The generated
  rows are type-checked by construction in `<Module>_auxiliary`; the
  hand-written rows are not. Fix: check `obl`'s type — after
  `stripForalls`, an `Eq` whose LHS head is the worker and RHS head is the
  wrapper (`baseName w`), with a `≤ lemFuel` hypothesis present; add a
  plant.
- **M2 — gate-script discipline**: `check_fuel_forms.sh:42-43` discards
  the build's and the tool's stderr (`>/dev/null 2>&1`, `2>/dev/null`) —
  fail-closed (exit code + summary line), but "never `2>/dev/null` an
  install/build step"; and `policy` does not assert the four form counts
  sum to `n_all`. Fix: capture stderr to the temp file and print it on
  failure; add the sum check.
- **M3 — record §6/§7 quotes three Tier A row-1 gate lines from a
  pre-3/n tree under the head's battery** (`202 roots` / `281 files` /
  `276 files`; the head: 203 / 284 / 279 — §7). Verbatim, but of another
  tree state than the heading claims. Fix: re-quote from the head's
  `test_unit.sh` (the orchestrator's log has it) or label the row's
  provenance.

**NOTE**

- **N1** — record §5's byte-identity comparand is an ephemeral snapshot;
  cite the primary's stamped tree (§1) or commit the `gen` stamp.
- **N2** — `check_exec_totality` scans only `partial`; the
  `opaque`/`implemented_by`/`extern` coverage the record/script cite it
  for is actually the axiom-census PIN set (§2). True claim, wrong cite.
- **N3** — ABSORBING is a "mentions" test over the RHS's constants, not a
  head-shape test (§2). No live payload exploits it.
- **N4** — commit 1/n's "test_unit.sh green" is the pre-C2 gate set (§6).
- **N5** — the orchestrator's re-verify oracle binary hash (`b92ea46a…`)
  differs from the record's (`b1cc0bd9…`) at the same `src` stamp
  (`754ef1e9…`): the OCaml build is not bit-reproducible here; the Lean
  binary hash (`797d1383…`) is identical. Not a finding about C2; the
  stamps' `src` fields are the load-bearing ones.
- **N6** — the fuel probes (§4) show a REACHABLE register row exhausting
  as a loud panic on a 10-term pure arithmetic chain at fuels 10–30 (a
  40-term chain: 10–120): the pending rows are not exotic — `to_pure`/
  `hack`-class loops fire on trivial programs at small fuels. Not a C2
  defect (declared, registered, D-C2-3/4), but the operator's D-C2
  decisions are on the everyday path, not a corner.
- **N7** — record §2's tally line "M 38 (… 20 drive-reachable)" does not
  match its own table (18 generated M rows with reach `yes`; the tool: 18
  + the 3 seams = 21). A derived-tally slip; fix the number.

## 10. Not checked

- The 38 generated proofs' tactic bodies were not re-read line by line
  (the statements, binders, forbidden tokens and cones were; the build and
  the auxiliary's exact-type application are the mechanical check).
- lem-lean side: nothing moved (`ecf75b4`); not re-verified beyond
  `git -C deps/lem-pinned log -1`.
- The mem-scale sweep and csmith shards (not in the battery; not asked).
- refined-cerberus's consumption of the manifest (theirs).

## 11. Provenance

[AGENT] (this auditor): every reading, probe, tally and grade above.
[USER 2026-09-04] rulings as relayed in the brief and the record §1 were
the grading frame; no ruling was made or altered here. Nothing merged,
nothing pushed; the worker's worktree was not edited.
