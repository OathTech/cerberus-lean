# Outcome protocol — checkpoint record

Author: [AGENT 2026-10-20]. Checkpoint A against
`c55e95ee278215446afeb9a74b62b6fd4833bea2`, branch `arc/outcome-protocol`.
Charter: revision 5 of `2026-10-18_codex-charter-outcome-protocol-s1-s2.md`.
Design: revision 3 of `2026-10-20_outcome-protocol-design-v2.md`.

**Current status: pre-merge review fixes recorded; fix-commit re-gate follows.**
D/E closed out at `fb5b4d4a1` after a linear rebase onto `4d46906c9`, with Tier A
19/19 and the full gate 43/43, each with unchanged source and complete selection.
Those are the base candidate's results, not evidence for the fixes below. The
fresh review and its four dispositions are recorded at the end; the focused
re-gate runs on the new commit and its exact results accompany the commit report.
The earlier 31/42 run remains incomplete historical evidence; its interrupted
B7 was unrun. The completed base-candidate sweep ran B7 afresh.

## A — baseline, inventory and fence

**Status at the A commit: PARKED before B, under charter §3.** A records the baseline,
measurements, current contracts and proposed per-site dispositions below. The
charter/design Q7 conflict needs a ruling; the newly identified non-mirror guards
and inventory/fence omissions need an explicit disposition. No implementation
has begun. [AGENT 2026-10-20] Do not start B on an inferred resolution or turn
an unconfirmed upstream attribution into a new production envelope.

The park ended with the dispositions in A.6; checkpoint B is authorized.

This checkpoint changes documentation only. No producer, classifier, reference,
theorem, baseline, register seal, dependency or pin has been changed. The charter,
its reading list, and design revision 3 were read; the inventories below are
from the dispatched tree, not the old design's measurements.

### A.1 Findings and dispositions

1. **Scope conflict: unsupported fixtures.** Charter §0's Q7 summary calls for
   an exec-lane acceptance change, whereas the adopted design §§4.3, 6 Q7 and 9
   defer it, charter §0 narrows lane work to two corrections, and §4 omits
   `test_exec.sh` from the fence. [AGENT 2026-10-20] Recommend correcting that
   summary and retaining the deferral. A clarification was raised before B;
   no exec-lane policy change is authorized by this record.
2. **The execution register is not the complete producer inventory.** The live
   lexical scan finds 122 pure root-seam leaves and one monadic helper leaf;
   only 111 pure leaves have register rows. Eleven additional pure sites are
   listed in A.4. In particular, `CerbFloat.of_string` and
   `CerbLocation.simpleLocation` are separate producer paths from the two
   float/location sites counted in the old inventory. C must cover them to
   make the full hand-written-producer claim. The count of register keys does
   not budget C's source edits.
3. **An inventory mirror is a port guard.** `CerberusImpl.normalise_aliases:180`
   refuses an enum because its type-only interface has no enum map. Upstream
   `Common.normalise_integerType_` instead resolves the enum through
   `typeof_enum`; this is not its mirrored crash arm. [AGENT 2026-10-20]
   Recommend INVARIANT for the port's violated normalization precondition.
   Keep the separate `lookupEnum` failure and upstream post-normalization
   assertions as UPSTREAM_CRASH. No computation or reach classification moves.
4. **Source citations need reconstruction, not copied offsets.** The pinned
   upstream file and this fork's file have different line numbers. For example,
   at upstream `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`, allocator `quomod`
   is line 1253 (not 1258), unknown-function-pointer failure is 1014 (not
   1049), and memcmp's assertion is 2658–2659. An empty UnionDef reaches the
   wildcard `assert false` at 1092–1093, not a match exception. C must use
   immutable revision/path/line/text tuples verified at that revision; the
   historical reference instance retains its historical strings, including
   their obsolete descriptions.
5. **There are two execution-result consumers.** The final printer in
   `Main.runPipeline:1239–1289` preserves typed Error0 through ModelFailure.
   The constant-expression mini-run uses `Mini_pipeline.run_const_expr_driver`
   and consumes its results inside `evalConstantExpressionAux`
   (`frontend/model/mini_pipeline.lem:199–218`). Its catch-all discards a typed
   Error0 other than the special range-error message and raises a generated
   legacy failure. Main also calls `frontendTU` for libc metadata and program
   TUs. This is another loss before emission, not a second ModelFailure
   printer. No `.lem` repair is proposed here; the consumer contract remains
   about emitted records, and no origin may be inferred from this legacy panic.
6. **Test registration has two lists.** `lakefile.toml` defines executables,
   while `scripts/test_unit.sh:16–63` selects those run by Tier A. A new
   standalone B executable needs that selector updated as well. The latter
   file is not explicitly in the charter fence. [AGENT 2026-10-20] Recommend
   naming that small registration edit in the fence; it changes no lane policy.
7. **The step-equality leaves are not uniformly mirrored crashes.**
   `CerbStepInstances:155–169` aborts on eight same-constructor comparisons.
   OCaml compares constructor fields in order: `Step_nd2 [] = Step_nd2 []`
   is true, and unequal thread IDs in `Step_ccall2` compare false before the
   continuation. The same short-circuit issue applies to the leading data
   in with-runstate, tau, action-request, memop-request and fs constructors;
   only spawn-threads has a function as its first field. The pinned
   `frontend/model/core_reduction.lem:110–128` defines those field orders.
   [AGENT 2026-10-20] Recommend INVARIANT for those seven coarse leaves, based
   on the existing call-site invariant that comparisons only involve
   Step_blocked2; retain UPSTREAM_CRASH for spawn-threads' function-first
   equality. Do not alter the failure triggers or claim a C-reachable
   semantic discrepancy. This corrects an attribution premise of Q-A, and
   needs disposition before C rather than a fabricated uniform upstream cite.

Focused native OCaml probe, compiled against the current concrete model's
`Cerb_frontend__Core_reduction` type (no substituted datatype), exit 0:

```text
Step_nd2 [] equality: true
Step_ccall2 different tids: false
Step_with_runstate2 different labels: false
Step_spawn_threads2 equality: Invalid_argument compare: functional value
```

The two corresponding Lean `#eval` probes import `Main` (therefore the shipped
instances); both exit 134 with empty stdout. Their first stderr lines are:

```text
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: BEq core_step2: functional value (Step_nd2)
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: BEq core_step2: functional value (Step_ccall2)
```

Reproduce the OCaml check with the following scratch source, then
`CERB_MEM_MAX=48G scripts/capped ocamlfind ocamlopt -package lem,pprint,zarith
-I _build/default/memory/concrete/.mem_concrete.objs/byte
-I _build/default/memory/concrete/.mem_concrete.objs/native
.tmp/step_equality.ml -o .tmp/step_equality`; run that executable through
`scripts/capped`.

```ocaml
open Cerb_frontend__Core_reduction
let f _ = failwith "the continuation must not run"
let () =
  Printf.printf "Step_nd2 [] equality: %b\n" (Step_nd2 [] = Step_nd2 []);
  Printf.printf "Step_ccall2 different tids: %b\n"
    (Step_ccall2 (0, f) = Step_ccall2 (1, f));
  Printf.printf "Step_with_runstate2 different labels: %b\n"
    (Step_with_runstate2 (RSK_eval "a", f) = Step_with_runstate2 (RSK_eval "b", f));
  try ignore (Step_spawn_threads2 (f, []) = Step_spawn_threads2 (f, [])) with
  | Invalid_argument msg ->
    Printf.printf "Step_spawn_threads2 equality: Invalid_argument %s\n" msg
```

For Lean, evaluate `IO.println ((.Step_nd2 [] : core_step2) == .Step_nd2 [])`,
and separately, after `let f : core_runM thread_state := fun _ => failwithI
"unused continuation"`, evaluate
`IO.println ((.Step_ccall2 0 f : core_step2) == .Step_ccall2 1 f)`.
Use the capped package probe recipe below. These are in-process comparison
witnesses, not a claim that admitted C reaches those comparisons.

### A.2 Checks and current stop forms

Required untouched Tier A, with the inherited charter environment loaded and
`CERB_MEM_MAX=48G scripts/capped python3 scripts/release.py --mode fast
--out .tmp/outcome-protocol-A/tier-a-baseline`: **exit 0**, all 19 commands
passed. The runner printed:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

This is checkpoint-A tier evidence, not final delivery certification. Tier B
and the consumer/adoption work remain for E. No proof was edited, so A has no
changed-proof replay obligation. Baseline warnings are present, not suppressed:
`generated/Symbol.lean:451,485` and `generated/Ctype_aux.lean:443,450` each report
`unused termination_by, function is not recursive` (the diagnostic puts
backticks around `termination_by`). They arise in generated code at the
untouched base; generator repair is outside this no-Lem-change dispatch.

The first launch omitted the environment setup required by the inherited
charter. Its A1 fork-drift self-test failed for missing `CERB_UPSTREAM_TREE`;
it is not a green baseline. A2 passed, then the owned runner was terminated
during A3. Verbatim runner summary, exit 1:

```text
fast: incomplete; 1/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

No source was dirty at interruption. The existing charter environment supplies
the independently generated upstream tree; no shared state was modified and
no prerequisite was skipped. The corrected run uses that environment and
`CERB_MEM_MAX=48G scripts/capped python3 scripts/release.py --mode fast`.

The following samples were run on the untouched source after the green tier.
Numbers are the 16 kinds in the stop-path inventory §4. Stderr cells quote
only the first diagnostic line (the cap cell quotes its witness banner);
stdout cells quote the complete record. Empty opposite streams were checked.
Backtraces are deliberately not copied. Rows 11 and 15 are explicitly
in-process/fault-injected native fixtures; no C-reachable guard is claimed.

| Kind | Witness / extra arguments | Exit | Channel and verbatim diagnostic or record |
|---|---|---|---|
| 1 | `--batch --fuel 0` | 2 | <code>stderr: cerberus-lean: refused — --fuel 0: the fuel must be a positive integer (fuel 0 kills at the first bind: never a verdict; see VALIDATION.md, fuel)</code> |
| 2 | `--batch --fuel` | 1 | <code>stderr: cerberus-lean: --libc/--libc-tu/--call/--call-args/--args/--fuel/--address-space-top/--runtime/--switches require an argument</code> |
| 3 | `int main(void) { asm("nop"); return 0; }` | 1 | <code>stdout: Error {msg: &quot;desugaring failed at .tmp/outcome-protocol-A/asm.c:1:18-28&quot;}</code> |
| 4 | `int open(const char *, int, ...); int main(void) { return open("x", 0); }` | 134 | <code>stderr: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: CerbFS refusal (fail-closed fs-model boundary): open &#x27;x&#x27; oflag 0 mode none — the filesystem is not modelled by this port ([USER 2026-09-28] contract D2: refused in full); answering would differ from, or merely guess at, the oracle&#x27;s SibylFS (CerbFS.lean header; mover: a SibylFS-faithful filesystem model)</code> |
| 5 | `tests/pnvi_refusals/r06-memcpy-symbolic-source.c`, `--switches=PNVI_ae_udi` | 134 | <code>stderr: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: PNVI_ae_udi refusal (unsupported upstream arm): R-PNVI-06: array_shift_ptrval (pure), Prov_symbolic pointer — impl_mem.ml:2254-2255 `failwith &quot;Concrete.array_shift_ptrval found a Prov_symbolic&quot;` — refused, not mirrored (upstream crashes, debug-print arms and self-declared-wrong arms on the PNVI path are loud refusals: design record docs/2026-10-04_pnvi-ae-udi-design.md §G/§H)</code> |
| 6 | `tests/coverage/fmt/fmt-007-f-nan-sign.unsupported.c` | 134 | <code>stderr: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: CerbFloat.formatFixed: refused — printing a NaN with %f is not supported: its text depends on the NaN&#x27;s sign bit, which Lean cannot read (Float.toBits canonicalizes NaNs); CONTRACT.md §3</code> |
| 7 | `tests/minimal/097-null-ptr-arith.undef.c` | 134 | <code>stderr: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: CerbMem.arrayShiftPtrval: TODO(pure shift a null pointer should be undefined behaviour), offset:4</code> |
| 8 | `tests/immaculate/nolibc/ts-memcmp-struct-padding.c` | 1 | <code>stdout: ModelFailure {msg: &quot;Concrete.memcmp: non-integer byte (impl_mem.ml:2658-2659 assert false)&quot;}</code> |
| 9a | `int main(void) { while (1) {} }`, `--fuel 128 --first` | 1 | <code>stdout: Error {msg: &quot;lem: fuel exhausted&quot;}</code> |
| 9b | 192-deep unused expression, `--fuel 128 --first` (recipe below) | 134 | <code>stderr: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted</code> |
| 9c | `fuelExhaustedWith "lem: fuel exhausted" (0 : Nat)` in a Lean probe | 134 | <code>stderr: lem: fuel exhausted</code> |
| 10 | `int main(void) { return 0; }`, `--address-space-top 1` | 1 | <code>stdout: Error {msg: &quot;MerrOther &quot;Concrete.allocator: failed (out of memory)&quot;&quot;}</code> |
| 11 | Direct `eqPtrval` with strict equality enabled (fixture below) | 1 | <code>stdout: Error {msg: &quot;MerrOther &quot;eqPtrval: SW_strict_pointer_equality is set but the strict-equality arm (impl_mem.ml:1860-1861) is not ported — switches are refused (Z-24)&quot;&quot;}</code> |
| 12 | Allocate 256 MiB under a 128 MiB cgroup cap | 137 | <code>stderr: capped: OOM-KILLED (exit 137 — cgroup memory cap CERB_MEM_MAX=128M breached; memory.events oom_kill=1; NOT a pass)</code> |
| 13 | `scripts/capped timeout 0.1 python3 -c "import time; time.sleep(2)"` | 124 | <code>both streams empty</code> |
| 14 | Remove `LEAN_ABORT_ON_PANIC` from the child environment; `--batch` | 2 | <code>stderr: cerberus-lean: refused — LEAN_ABORT_ON_PANIC is not set: a Lean panic! (this port&#x27;s fail-stop mirror of every OCaml failwith/assert/uncaught exception) would print and then CONTINUE with a default value, converting a crash into a verdict; set LEAN_ABORT_ON_PANIC=1 (every harness does: scripts/common.sh run_cerberus_lean; see VALIDATION.md, zero-discrepancy Z2-FL-03)</code> |
| 15 | Scratch Main: force the result list empty, then run its existing printer | 1 | <code>stdout: Error {msg: &quot;cerberus-lean: runND returned no executions&quot;}</code> |
| 16 | `int absent(void); int main(void) { return absent(); }` | 1 | <code>stdout: Error {msg: &quot;ill-formed program: `calling an unknown procedure: Symbol(19, SD_Id(&quot;absent&quot;))&#x27;&quot;}</code> |

The pure-null-shift oracle witness exited 125 with
`Failure("TODO(pure shift a null pointer should be undefined behaviour), offset:4")`.
The memcmp oracle witness also exited 125: the fork's actual assertion is
`impl_mem.ml:2703`, while the immutable upstream citation is 2658–2659.
Allocator OOM returned the same unescaped-inner-quote Error record and exit 1
on both engines. The unknown-procedure Error differed only in the symbol
number (Lean 19, oracle 502), the existing failure-class normalization case.
These are measured failure comparisons, not new semantic agreement claims.

The three fuel captures were passed to the existing
`scripts/fuel_classify.sh` `classify_fuel_outcome`, with their measured status
and output; in the row order 9a/9b/9c it printed:

```text
FUEL:kill
FUEL:panic
FUEL:panic
```

Additional framing/resource controls:

- `--batch --switches=bogus,,bogus` exits 2, empty stdout, **three** refusal
  lines; duplicate `bogus` is retained. `--batch --args a --args b` exits 2
  with no old refusal prefix:

  ```text
  cerberus-lean: option --args cannot be repeated (as the oracle's command line)
  ```

- The exhaustive/default-fuel infinite-loop run exits 134, empty stdout.
  Its stderr begins with a blank line then `Stack overflow detected. Aborting.`,
  followed by timeout's core-dump diagnostic and the terminal cap wrapper line.
  Stack classification remains deferred. The root-relative `scripts/capped`
  spelling occurs in the actual terminal suffix; the new decoder must admit it
  narrowly as specified, not scan arbitrary payload lines for wrapper text.
- A surviving Python parent whose child allocates 256 MiB under the 128 MiB
  cap exits **0**, but reads `oom_kill 1` from its current group's
  `memory.events` before cleanup. Its wrapper prints:

  ```text
  capped: OOM-KILLED (memory.events oom_kill=1, cap CERB_MEM_MAX=128M; command exit 0 — a descendant was killed by the cap; NOT a clean pass)
  ```

- A Python program doing only `raise SystemExit(137)` exits **137** with
  `oom_kill=0`, and prints the distinct generic KILLED banner. It is not
  positive OOM evidence. `CAPPED_OOM_KILLS` is the wrapper's internal variable,
  populated in `capped_cleanup` before cgroup removal; it is not a new exported
  metadata API. The parent probe found its owned group through
  `/proc/self/cgroup`, then read `/sys/fs/cgroup/<that path>/memory.events`.
  No sidecar/interface change was made.

Reproduction uses the charter's process-local environment setup. From the
worktree root, for each C source above:

```sh
CERB_MEM_MAX=48G scripts/capped timeout 45 opam exec --switch=. -- \
  _build/default/backend/driver/main.exe --runtime="$PWD/_build/install/default" \
  --cabs-json SOURCE > .tmp/probe.json
LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=48G scripts/capped timeout 45 \
  lean_frontend/.lake/build/bin/cerberus-lean --batch --first EXTRA_ARGS \
  --runtime="$PWD/_build/install/default" .tmp/probe.json
```

The stack control omits `--first`; CLI-only rows omit the runtime/input.
Capture stdout/stderr separately and save the actual command status. The oracle
controls use the same runtime and source with `--nolibc --exec --batch
--mode=exhaustive`. Row 9b's source is generated by
`'int unused(void) { return ' + '1 + (' * 192 + '0' + ')' * 192 +
'; }\nint main(void) { return 0; }\n'`.

For ordinary Lean probes, use `import Main`/`import CerbFailProofs` (bare fuel
only needs LemLib) and `#eval show IO Unit from do ...`; from
`lean_frontend/`, run `CERB_MEM_MAX=48G LEAN_ABORT_ON_PANIC=1 ../scripts/capped
lake env ../scripts/lean_probe.sh <absolute-scratch-file>`.
The package environment is needed for the executable's Main module. A first
attempt without it failed to resolve Main; that was a probe setup failure,
not a stop witness. A corrected `do` block and native entry were needed for
row 11; exiting inside `#eval` prevented its captured stdout from being flushed.

Row 11 uses a scratch copy of Main with its old `main` renamed, imports
CerbFailProofs, and gives the fixture the new entry point. It sets `LemFuel := ⟨128⟩`, `CerbGlobal.Switches :=
⟨[.strict_pointer_equality]⟩`, takes
`p := CerbMem.PointerValue.PV .Prov_none (.PVconcrete none 100)`, and observes
`CerbFail.step (CerbMem.eqPtrval CerbLocation.unknown p p)
(CerbMem.initialMemState 65536)`. Its `NDkilled (Other err)` is rendered with
Main's `driverErrorBatchMsg (.DErr_memory err)` in its existing Error shape,
then exits 1. Row 15 copies Main only into scratch and inserts
`let execs := execs.take 0` immediately before `for l in nodeLabels do`; its
normal main is run on the main-returning-zero JSON. This tests the real guard
and printer with injected input to the guard, not production reachability.
A separate empty-ND probe printed `execution-count=0`, exit 0.

Every Lake/Lean/compiler command in these probes is wrapped in
`scripts/capped` with `CERB_MEM_MAX=48G`; only the intentional cap-breach
witnesses reduce the limit to 128M. Both native fixtures use capped
`lake setup-file`'s JSON followed by capped
`lake env lean --setup SETUP --root SCRATCH -c GENERATED_C SOURCE` and
`lake env leanc -O0 -o EXE GENERATED_C @RESPONSE`, then capped execution.
Build the response from `.lake/build/bin/cerberus-lean.rsp`, omit its Main
object, and resolve every inherited package object path inside **this**
worktree (the primed response names the original checkout). Include
`.lake/build/ir/CerbFailProofs.c.o.export` for row 11. The stock interpreter
could not load the existing CerberusFresh native declaration for row 15;
the successful native captures above are the evidence. No build registration
or production source was edited.

Fixture elaboration also exposed existing warnings in Main: deprecated
`List.asString` at 647, unused bindings at 762/1091/1302, and deprecated
`String.trim` at 1686/1744/1745; dependency replay reports deprecated
`String.dropRightWhile` at CerbLocation 225. These were not suppressed.
The quoted native execution records exclude the separately captured compiler
warnings; they do not pretend the compilation log was a batch observation.

### A.3 Reconstruction contracts and proof dependencies

[USER 2026-10-20, charter §0] The operative ruling is the parameterized
reference contract. The design's pending-ruling wording is historical at this
dispatch. No consumer claim of equality to old failure strings survives
silently as equality to newly rendered strings.

Current definitions in `test/Unit/ReconstructLegacyTest.lean` are
`reconstructValueLegacy_lemFuel:60`, its measured wrapper
`reconstructValueLegacy:228`, and the indexed reference
`reconstructValueLegacy_indexed_lemFuel:250`. Each algorithm has six direct
failure messages: unknown function pointer (address-dependent), missing struct,
empty union, recorded member absent, wrong union tag kind, and unsized type.
Their two sets of sites are respectively 113/176/196/218/219/223 and
280/305/322/335/336/340. Fuel leaves are separate and unchanged.

The following abbreviations specify the current statements compactly, without
dropping a quantifier. Let `x = (e, a, u, f, ad, ty, bs)` range over
`EnumDefs × TagDefs × List (Int × identifier) × Funptrmap × Int × ctype ×
List AbsByte`; `n : Nat` and `fo : Address → OverlapResult` are arbitrary.
Write `L n x` for `reconstructValueLegacy_lemFuel n e a u f ad ty bs`,
`J n x` for the indexed reference on the same arguments, `P n x` for
`CerbMem.reconstructValue_lemFuel`, and `A fo n x` for
`@CerbMem.reconstructValueAbst_lemFuel ⟨defaultSwitches⟩ n e a fo u f ad ty bs`.
`b = CerbTagsWf.envBound a ty`; `L₀ x` and `P₀ x` are the measured wrappers.

| Theorem, current line | Current statement |
|---|---|
| `reconstructValueLegacy_lemFuel_eq_indexed`, 347 | `∀ n x, L n x = J n x` |
| `reconstructValueLegacy_eq_indexed`, 377 | `∀ x, L₀ x = J b x` |
| `reconstructValueAbst_default_snd_eq_legacy`, 398 | `∀ fo n x, (A fo n x).2 = L n x` |
| `reconstructValue_lemFuel_eq_legacy`, 462 | `∀ n x, P n x = L n x` |
| `reconstructValue_eq_legacy`, 468 | `∀ x, P₀ x = L₀ x` |
| `loadM_reconstruct_default`, 476 | For every `st,e,a,ad,ty,bs`, the default full measured reconstruction using `findOverlapping st`, `st.lastUsedUnionMembers` and `st.funptrmap`, projected by `.2`, equals `L₀` on those same maps. |
| `reconstructValue_lemFuel_eq_indexed`, 484 | `∀ n x, P n x = J n x` |
| `reconstructValue_eq_indexed`, 492 | `∀ x, P₀ x = J b x` |

These statements cover failure arms too. They have no well-formedness,
non-failure or reachability premise. `foldl_snd_eq:387` supplies the
projection-through-fold lemma; the array proof uses
`CerbMem.chunksOf_eq_range_map:1235`.

C will give both references the same message parameter, retain the reference
equivalence for an arbitrary parameter, and restate the six production-facing
equalities at the production rendering instance. A historical instance must
recover the frozen direct-reference expressions. This historical instantiation
does not freeze every transitive helper's old runtime diagnostics: both
references call the production layout/byte helpers. Headers, runtime success
text, and the cerberus-sl note must describe the actual new claim.

Additional proof families to retain and rebuild:

| Module / current declarations | Statement or dependency to preserve |
|---|---|
| `CerbMemDefaultFacts:44,52,94,103,112,126` | Wrapper unfolding; **whole-pair** default closure independence for arbitrary `fo,fo',n,x`; its fuelled and measured `.2` equations; the same equation under any instance with `inst.switches = defaultSwitches`; `loadM_reconstruct_eq_reconstructValue` at that instance. |
| `CerbMemDefaultFacts:146` | `resolveIota_ok_of_shape`: any successful `(allocId,state)` transfers between preconditions whose OK/FAIL/error shape agrees for every candidate at the state. |
| `CerbMem:1191,1221` | `∀ n e a f v, memValueToBytes_lemFuel n e a f v = memValueToBytes_append_lemFuel n e a f v`, and its `memValueSize v` wrapper. The append reference has two additional diagnostic twins at 1079/1088; migrating only the fast serializer breaks the proof. |
| `CerbMem_lemMeasureProofs:949,1040,1058` | Reconstruction stability at sufficient fuels under the ranked-tag hypotheses, full reconstruction measure sufficiency, and the wrapper corollary. Preserve hypotheses and results. The other layout/serialization sufficiency proofs also depend on changed seams. |
| `CerbMemAccessFacts`, restated by `Unit.MemoryAccessProofs` | `loadM_erasure` and `storeM_erasure`: erasing the observation buffer commutes with the step, preserving its action and erased post-state, plus the existing 15 support/lift facts. |
| `CerbMemAllocatorProofs` | `allocator_below_request_kills` and `allocator_active_sound`; changing the zero-alignment diagnostic must not weaken either statement. |
| `CerbFailProofs` | Generic kill, bind, lift, runner and pipeline propagation remain quantified over messages; no sentinel-inequality theorem is introduced. |

The axiom census's seven reconstruction entries are at
`scripts/check_theorem_axioms.sh:811–817`; the eighth reference corollary is
also inventoried above. The untouched A1 run printed all seven with exactly
`[propext, Classical.choice, Quot.sound]`; the serializer pair and default
bridges were checked in the same census. Its final line was:

```text
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

Keep all existing entries and their allowed axiom set,
and inspect each resulting headline theorem with `#print axioms`. C runs
capped `lake env leanchecker` on every built module whose proofs change,
including `Unit.ReconstructLegacyTest`, `CerbMem`, and any changed proof
carriers above; record module names and exit statuses. A changes no proof and
claims no new theorem or kernel replay. [AGENT 2026-10-20] Estimate the reference
restatement at half to one focused day; exceeding one day triggers the charter
stop condition, not a weakened theorem.

### A.4 Per-site producer disposition

[AGENT 2026-10-20] The tables apply the charter's ruled Q-A policy to the
current source; newly identified guard attributions are recommendations for
review before migration, not additional operator rulings. `U` means UPSTREAM_CRASH, `I` means INVARIANT, `R` means REFUSAL,
and `keep` means no outcome-protocol change to that arm. These are operational
attribution decisions, not reachability proofs. Existing reach claims and
unknowns stay explicit; no unreachability result is inferred from this scan.
All line numbers below refer to the dispatched base. Source witnesses were
read using `git show <revision>:<path>` and the current authoritative Lean
files; generated copies were not edited.

#### CerbMem pure sites (including the serializer reference)

Every line in the following table is a separate leaf unless a range is
explicitly an expression. Upstream citations refer to
`memory/concrete/impl_mem.ml` at
`b9aeedcb4dd438763b0eef7f95ac19e93875d7de`.

| Lean site / line(s) | Disposition / checked upstream basis |
|---|---|
| `targetPtrSize` 436 | U; complete pointer-size requirement, 1159–1163 (also 154–158). |
| `offsetsof` 531 | U; `Pmap.find` at 100. |
| `sizeofCtype` 559, 560, 562 | U each; void/incomplete array/function assertion, 134–135. |
| `sizeofCtype` 566, 570 | U each; missing integer/float size, 136–148. |
| `sizeofCtype` 594 | U; union lookup/kind failure, 172–175. |
| `alignofCtype` 612, 614 | U each; void/function assertions, 198–199 and 216–218. |
| `alignofCtype` 618, 622 | U each; missing integer/float alignment, 200–212. |
| `alignofCtype` 643, 654 | U each; struct/union lookup/kind failures, 228–231 and 254–257. |
| `intToBytes` 721 | U; print-then-assert, 1105–1109. Keep omission of tool-debug output. |
| `bytesToInt` 736, 737 | U each; empty/oversized byte lists, 742–745. |
| `splitBytesProv` 781 | U; empty list, 432–434. |
| `memValueToBytes_lemFuel` 951, 963 | U each; repr's size reads, 1145–1156, through sizeof's failures at 136–148. |
| `memValueToBytes_append_lemFuel` 1079, 1088 | U each, **outside register**; same messages as the production serializer for the equality theorem. |
| `reconstructValueAbst` 1330 | U; missing function pointer, 1009–1014. |
| `reconstructValueAbst` 1419 | U; struct reconstruction's sizeof/offsetsof lookups, 1062–1070 and 100. |
| `reconstructValueAbst` 1439 | U; empty union falls to assertion, 1078–1093; correct the current detail's exception description. |
| `reconstructValueAbst` 1461 | U; recorded member missing, 1085–1087. Reach remains UNKNOWN. |
| `reconstructValueAbst` 1462 | U; wrong union tag kind, 1092–1093. |
| `reconstructValueAbst` 1466 | U; unknown-size type assertion, 943–948. |
| `typeofMval` 1529 | U; empty-array assertion, 1125–1127. |
| `casePtrval` 1616 | U; device half of wildcard failure, 1808–1814; symbolic half remains refusal below. |
| `maxIval` 1649, 1658 | U each; missing size and residual enum, 2401–2402 and 2398–2399. |
| `minIval` 1675, 1677 | U each; missing size and residual enum, 2430–2435. |
| `concurReadIval` 1688 | U, **outside register**; 2361–2362. |
| `integerDiv_t` 1727 | U; unguarded `Z.div` in pointer difference, 1967 (not op_ival's guarded IntDiv arm). |
| `integerRem_t` 1733 | U; 2481–2482. |
| `integerRem_f` 1740 | U; 2483–2484. |
| `opIval` 1777 | U; negative `Z.pow` argument, 2485–2490. |
| `offsetofIval` 1793 | U; missing member, 2193–2201. |
| `arrayShiftPtrval` 1975, 1976 | U each; null and function-pointer failures, 2214–2219. |
| `memberShiftPtrval` 1999 | U; function-pointer failure, 2239–2240. |
| `bytefromint` 2011, `intfrombyte` 2019 | U each; byte-range assertions, 2775–2780. |
| `deriveCap` 2238, `capAssignValue` 2240, `nullCap` 2242, `ptrTIntValue` 2244 | U each; corresponding CHERI-only assertions, 2175–2185. |
| `cheriPointerHashPrintf` 2246 | I, **outside register**; the concrete model has no body to attribute as a mirrored exception. Guard the port's non-CHERI concrete-model assumption. |
| `getIntrinsicTypeSpec` 2248 | U, **outside register**; 2187–2188. |

#### Other pure root seams

| File and individual sites | Disposition |
|---|---|
| `CerbDecode` 41; 121,127,132,144,146,151 | U each: empty integer constant and six character-decoder arms. Pinned `ocaml_frontend/decode.ml`: 18,166–167,171,185,197,163,199 respectively; the lone-backslash path at 121 has an old detail incorrectly naming 199–200. |
| `CerberusImpl` 78,116,165,224,226 | U each: enum lookup, unresolved-enum sign test, absent N-width alias, residual base type, residual integer type. Pinned `ocaml_frontend/ocaml_implementation.ml`: 144–150,95–96,39–44/155–160,190–195,197–202. |
| `CerberusImpl` 180 | I: `normalise_aliases` requires prior enum resolution (A.1 finding 3). |
| `CerberusImpl` 65 | I, **outside register**: applied enum-registry call survived reader lifting. |
| `CerbFloat` 438 | U: non-finite float-to-integer conversion, `Z.of_float` at 2554 in the pinned memory model. |
| `CerbFloat` 308 | U, **outside register**: malformed literal parsing; concrete `str_fval` delegates to `float_of_string` at 2523–2524. The defacto helper also exists at `util/cerb_floating.ml:8–16`. |
| `CerbUtils` 107,117,126,143 | U each: ctz zero, bswap16/32 range, bswap64 overflow. Pinned `ocaml_frontend/ocaml_gcc_builtins.ml:5,15,22,30`; bswap64 carries existing **draft 12**, not a filed issue. |
| `CerbUtils` 53 | I, **outside register**: reaching the unsupported old stepper's random-integer seam violates the admitted-driver assumption; its PRNG counterpart is not a mirrored crash. Do not attribute the live generated stepper's separate failure to this leaf. |
| `CerbLocation` 174 | U: outer bounding box on no regions; pinned `util/cerb_location.ml:103–106`. |
| `CerbLocation` 306 | U, **outside register**: batch simple-location printer's `List.hd`, same upstream file 489–491. |
| `CerbStepInstances` 155,157,159,161,163,167,169 | I recommended: seven coarse equality guards (ccall, with-runstate, tau, action-request, memop-request, fs, nd). Earlier unequal data or an empty list can avoid OCaml's closure exception; see finding 7. |
| `CerbStepInstances` 165 | U: spawn-threads equality compares the function first. |
| `CerbStepInstances` 204 | I, **outside register**: the same-tag ordering fallback is not uniformly an upstream crash (some constructors contain ordinary data). Preserve the existing unreachable-comparison guard rather than claiming every payload is functional. |
| `CerbFunMapInstances` 84 | I: phantom value-comparison requirement reached; upstream can compare the data fields. |
| `CoreParser` 2416 | I: `scanStep` fuel exhausted; caller supplies input length + 1. This is not RESOURCE fuel. |
| `Main` 70 | I: `loadCoreImpl` received an implementation key that parsing should already have validated. |
| `CerbTags` 34 | I, **outside register**: applied tag-registry call survived reader lifting. This is presently a transparent `panic!`, not a LemLib panic. C must use the existing `failwithI` atom for the admitted panic adapter, with no new opaque atom. |

The derived classification for the **122 pure root-seam leaves** is
71 U / 35 R / 16 I under these proposed dispositions. The monadic `pnviRefuseM`
helper at `CerbMem:2266` is the 123rd lexical leaf, serving two refusal
call sites below. Test/reference failure sites are inventoried separately;
these are source-leaf counts, not execution counts or register-row counts.

#### Existing refusals and driver admission

| Producer sites | Disposition |
|---|---|
| `CerbFS` mkdir110, open112, close114, write116, read118, pwrite120, pread122, rename124, umask126, chmod128, chdir130, chown132, link134, readlink136, symlink138, rmdir140, truncate142, unlink144, lseek146, stat148, lstat150, opendir152, readdir154, rewinddir156, closedir158 | R/fs at all 25 sites; preserve pure signatures and refusal mechanism, encode dynamic arguments as data. |
| `CerbMem` combineProv377/378 (R01), provsOfBytes807 (R01b), findOverlapping873 (R02) and889 (R03), lookupIota2336 (R04), reconstruct1349 (R05), arrayShift1973 (R06), casePtrval1606 (R07) | R/pnvi at all nine pure sites, retaining the exact R-PNVI item as structured data. |
| `CerbMem` diffPtrval3248 (R08), effArrayShift3496 (R10), through helper2266 | R/pnvi, existing memM panic; not a typed Error verdict. R09 is the default-path typed mirror below. |
| `CerbFloat` formatFixed356 | R/float-format; preserve the NaN explanation. |
| `Main` decodeCabsJson311; refuseRuntime553; refuseLibraryLocations617; printUndefinedLine647; refuseFlag1385; refuseSwitches1457; refuseSwitchesParseCore1489; startup1516; fuel1651/1655; address-space1668/1672 | Existing attributed exit-2 refusals migrate through the appropriate fixed boundary. Check all read paths: input file, stdin, libc metadata; runtime argument/environment; library import; frontend and final-batch UB printing. Preflight final-batch UB payloads before headers or records. |
| `Main` repeated args1596, switches1607/1624 | Existing exit-2 admission refusals have no old `refused` prefix. Include them in driver migration with preserved status and detail, using existing `cli`/`switches` boundaries; no new exit-1 conversion. |
| `Main` judgeSwitches1481 | I on CLI, exit 2, if the nonreturning refusal returns. |
| `Main` runPipeline1253 | Existing declared zero-execution Error remains Error under the design's ordinary-Error constraint; it is not quietly relabeled an attributed invariant. No C-reachable witness is claimed. |
| Main's exit-1 usage paths; shared asm/front-end rejection; parser/link errors; ordinary memory/driver Error; exact fuel; allocator `oomKill` | Keep existing meaning and channels. These are not newly attributed REFUSALs. |

#### Nine typed stops and twelve switch kills

| CerbMem site | Disposition |
|---|---|
| allocator2514 | U; zero-alignment `quomod` failure, upstream1253. |
| allocateObject2542 | U; requested-address failure, upstream1295. |
| killM2668 | U; dead static allocation, upstream1532. |
| storeM2998 | I; successful resolution and the subsequent lookup disagree on the allocation map. |
| effArrayShift3465 | U; function-pointer failure, upstream2253–2254. |
| effArrayShift3551 | I; symbolic pointer survived an earlier exhaustive symbolic arm. |
| memcmp3617 | U; non-integer byte, upstream2658–2659. |
| vaList3813 | U; noninitial va_list, upstream2760. |
| callIntrinsic3832 | U; concrete-model CHERI assertion, upstream2190–2191. |
| allocateObject2553; killM2647,2683; loadM2861 | R/switches: zero-initialization, two zap paths, strict reads. |
| eqPtrval3084; lt3115, gt3127, le3137, ge3147 | R/switches: strict equality and four strict relational paths. |
| diffPtrval3193; effArrayShift3471,3529 | R/switches: permissive difference and two strict-arithmetic paths. |

Keep all seven MonadicFailstop exact-message pins meaningful at the new
structured values, including status/state/absorption controls. Keep
PnviArmsTest's eleven refusal witnesses and its positive controls. Update the
three CLI witness scripts and their negative stubs together, the three fuel
CLI assertions at `scripts/test_fuel_plant.sh:220–227`, and the positive
ModelFailure plant in `test_observation_lanes.py:63`; retain an envelope-less
negative for the new decoder. Detail-substring checks in `scripts/test_address_space.sh:258–263` survive if their
detail substrings survive. Other lanes' legacy codec plants must not be
silently converted into new decoder-positive fixtures.

#### Q-A B, C and D arms that stay mirrored

| Arm, current Lean location | Disposition / upstream basis |
|---|---|
| Ill-typed store2956 | Keep ordinary Error, without the tool-debug print; upstream1673–1681. |
| Atomic member access, load2887/2904 and store2987/3015 | Keep UB and omitted tool diagnostics; no new stop. |
| Function-pointer reconstruction1325–1328; `caseFunsymOpt`1619–1626 | Keep both defined map-hit arms; upstream1009–1012 and1816–1825. The missing-pointer failure migrates independently. |
| ptrfromint device-range arm3347 onward | Keep upstream2165–2173. |
| killM device2619 | Keep successful return; upstream1474–1476. |
| Reconstruction null function pointer and null object pointer1318–1338 | Keep both; upstream1005–1007 and1017–1019. |
| loadM Bool-trap logic2816 onward | Keep; upstream1577–1588. |
| isWellAlignedPtrval3270 | Keep type handling; upstream2065–2070. |
| memberShiftPtrval null arm1978 onward | Keep; upstream2232–2238. |
| intfromptr3383 | Keep conversion behavior; upstream2438–2459. |
| maxIval Bool1654 | Keep unsigned maximum; upstream2385–2387. |
| typeofMval array arm1518 onward | Keep first-element type selection; upstream1128–1131. |

The latter nine rows include ten defined TODO arms (the reconstruction row
contains two, and the list begins with ptrfromint). The binary64 representation
comment is not an eleventh decision. Generated failures remain outside C:
128 register rows, envelope-less and origin-unattributed; no `.lem` or Lem-pin
edit is authorized.

### A.5 Register, consumer paths and implementation fence

The lexical inventory is reproducible with the existing
`failure_census.census(path, root)` over `lean_frontend/*.lean` (authoritative
root files only). It reports 123 leaves: 122 `pure_or_unresolved` and one
`monadic_ascribed`. Live register seals and tallies were checked with
`check_failure_reach.read_register`/`seal_of`; the baseline's live census also
rebuilds declaration ownership and dependency evidence. Measured summary:

```text
register 239 handwritten 111 generated 128 refusal keys 35 remaining 76 valid seals True
```

C needs old-to-new keys for the affected 111 hand-written register rows, not
new invented entries for every out-of-closure helper. Recompute the actual
census after migration; retain evidence for any changed ownership, positions
or reach. The two existing unresolved owners remain an explicit register fact.
No automatic classification/reseal of an unknown site is authorized here.

The producer/consumer paths checked are:

- Pure seam → existing LemLib runtime abort → stderr panic; no exception
  transformer can recover its evaluated-but-unemitted earlier branches.
- Typed memory stop → `failStopKill` / `failStopMem` → `liftMem` and ND binds →
  first/exhaustive runner → final ModelFailure printer. `CerbFailProofs`
  pins these lift/absorption shapes. A separate mini-run consumer is finding 5.
- Driver admission → stderr and status 2; switch lists are scanned before
  exit, whereas repeated-option checks are distinct parser paths.
- Existing capture plumbing saves stdout/stderr/status. Its merged display
  is not the new decoder's input. `observations.parse` and
  `failure_message` are existing comparison APIs, not an all-causes API.
- PNVI currently checks resource evidence before crash/refusal parsing;
  immaculate does so in shell `verdict` before calling the codec. D must
  insert invariant detection in **both** paths before those early returns.
  PNVI's current bare-137-as-KILL policy is the expressly deferred divergence.
- Exec/gcc/CI/CN use `observation_model_failure` and existing comparison paths;
  their policies are not rerouted by B or D. Fuel classification currently
  recognizes the translation panic, but searches merged text; only the new
  decoder's exact-frame contract is promised by this mission.
- Caesium's handoff is `differential.py`'s raw capture before truncation;
  E must demonstrate its actual capture/suffix shapes and retain all emitted
  records, not all evaluated causes. The separate stepper harness is not a
  substitute. The existing provider-side sl note names default reconstruction,
  fuel, OOM and kill-lift compatibility; E rechecks actual consumer use before
  making an adoption claim.

The fence matches the current paths for CerbStop's future root module and
manifest/Lake registration; all listed producer seams; MonadicFailstop,
PnviArmsTest and the reconstruction/proof carriers; the three CLI witness
scripts; fuel CLI pins; observations and its two test modules; PNVI/immaculate;
the register, census entries, and documentation. Two omissions need explicit
recognition: the unlisted producer leaves in A.4 (including CerbTags), and the
unit-suite selector in finding 6. A new core test can alternatively be exercised
through an existing selected executable; silently leaving it outside Tier A is
not acceptable. These are compatibility dependencies, not new lane policies.

Preserve the exclusion of capture plumbing (`capped`, `common.sh`,
`observations.sh`), `.lem`, Lem pins, dependencies and external consumer trees.
Charter §4 mentions a conditional `common.sh` repin inherited from the earlier
charter; design §5 excludes the capture change and this mission has no need for
it. An implementation requiring such a change must report it before proceeding.
The exec-lane Q7 discrepancy remains the outstanding scope ruling in A.1;
this record does not silently grant the excluded policy change.

Existing trust limit, unchanged: the pure adapter depends on LemLib's
`@[implemented_by]`/unsafe runtime boundary and `LEAN_ABORT_ON_PANIC=1`;
logical `failwithI` remains opaque rather than a distinguished structural
outcome. The current `CerbTags` guard is transparent `panic!`. The baseline
axiom census does not prove those runtime mechanisms sound, and no new opaque
atom or axiom is proposed. A changes no trusted code.

No proof-work estimate or source scan in A establishes a new correctness
theorem. Sentinel collision, pure-abort behavior, legacy generated failures,
and the emitted-record limitation remain stated limits owned by the named
structural-outcome work.

### A.6 Accepted dispositions and continuation

[AGENT 2026-10-20, orchestrator disposition relayed by the operator] Checkpoint A
is accepted; the seven findings are settled as follows. These replace the
pending recommendations in A.1 without erasing the original measurements.

| Finding | Disposition for implementation |
|---|---|
| 1 | Correct the orchestrator's Q7 summary error: the `.unsupported.c` admitted-REFUSAL policy stays deferred under v2 §9. |
| 2 | Include all eleven additional pure sites in C, for the measured 122 pure root-seam leaves. |
| 3 | Classify `CerberusImpl.normalise_aliases`'s enum guard (A-base line 180) as INVARIANT. |
| 4 | Reconstruct upstream citations at the immutable pinned revision; preserve historical reference strings in their historical instance. |
| 5 | State the constant-expression mini-run's metadata loss alongside the pure-abort limit in v2 §1.2. No `.lem` change; lost attribution is not inferred. |
| 6 | Add `scripts/test_unit.sh` to the charter fence for test registration. |
| 7 | Use INVARIANT for the seven coarse step-equality guards and the ordering guard (A-base line 204); spawn-threads' function-first comparison remains UPSTREAM_CRASH. |

The same relayed disposition includes C's seam hygiene for `CerbTags` (A-base
line 34): replace the transparent panic with the existing `failwithI` boundary
and supply its register row. No failure condition or opaque atom is added.

## B — structured codec, adapters and capture decoder

**Status: B complete; focused checks and Tier A passed.** No production producer or
lane has switched formats. C remains the producer migration; D remains the two
lane corrections. The register and all existing theorem/census entries are
unchanged in B.

[AGENT 2026-10-20] Metadata validity is carried by Lean values: nonempty text,
revision/path/line constraints and tray constraints are checked before a Stop
can be built. `CerbStop.Failure` excludes refusals from the typed-kill adapter.
The core owns JSON encoding/decoding and the CLI adapters; `CerbMem.stopMem`
and `CerbMem.refuseM` connect it to the existing kill/panic mechanisms. Pure
producers will retain their visible `failwithI` application in C. No opaque
atom, axiom, new resource class, or fallback class was added.

`scripts/observations.py` now exports `parse_stop` and `decode_stop` alongside
the unchanged legacy comparison APIs. `parse_stop` returns None for absence
and raises ProtocolError for a malformed reserved envelope. `decode_stop`
returns `StopDecode(stops, legacy_panics, fuel, problems)` and retains earlier
metadata beside later problems. Its dataclasses preserve all constructor fields,
channel, execution index and source position (one-based line, zero-based byte
offset). Unheaded batch executions have index 0. Collection order is stdout
record order followed by stderr record order; separate streams supply no shared
chronology. Legacy payloads remain bytes and receive no upstream attribution.

No stop scan examines ordinary Error contents or escaped program streams.
Fuel is recognized only in its three specified positions. Missing LF,
malformed/duplicate/missing execution framing, wrong channels/statuses, invalid
escapes and unexpected tails are problems. Complete stops survive those problems;
their presence does not validate the capture. Host banners and exit statuses
do not manufacture resource evidence in this API.

### B.1 Wrapper-spacing finding and ruling

The first native conformance run failed two subtests (`pure` and `refuse-m`),
exit 1. Both actual adapters emitted a valid envelope and exited 134, but Bash
placed padding between `Aborted` and `(core dumped)` in the final wrapper line.
The design's original regex allowed exactly one space there. The pure probe's
verbatim suffix was:

```text
/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/outcome-protocol/scripts/capped: line 36: 180302 Aborted                 (core dumped) "$@"
```

The monadic probe had the same spacing (PID 180773). The diagnostic is emitted
by Bash around `run_reporting_kills` (`scripts/capped:36–38`), not a new banner
written by the wrapper. Implementation paused under charter §3 and the mismatch
was raised before changing the rule.

[USER 2026-10-20] Permit one or more spaces before the optional core-dump marker
and resume B. Keep the existing terminal position, path alternatives, ordering
and cardinality restrictions. This changes neither panic origin nor resource
attribution. V2 §4.1 and the new decoder now use that narrow amendment; the
legacy `ABORT_WRAPPER` and its callers are unchanged. The focused suite includes
the padded spelling and rejects tabs, duplicated suffixes and reversed ordering.

### B.2 Focused checks and reproduction

Use the charter environment, sync with `make lean-prelude-src`, and wrap every
build/probe in `CERB_MEM_MAX=48G scripts/capped` (`../scripts/capped` from the
Lean package). No dependency, `.lem` source or pin changed.

| Check | Result |
|---|---|
| From `lean_frontend`: `lake build stop-test` | Exit 0. |
| Native `.lake/build/bin/stop-test` | Exit 0: `stop-test: round-trips, absence/malformed and typed adapters passed`. |
| `python3 scripts/test_stops.py` | Exit 0, 16 Python test methods. |
| `python3 scripts/test_observations.py` | Exit 0, all 25 existing test methods. |
| `python3 scripts/test_stops.py --lean-bin lean_frontend/.lake/build/bin/stop-test` | Exit 0, 19 methods after the ruled spacing amendment. Shared corpus: 123 cases (23 valid, 3 absent, 97 malformed), all agree between Lean and Python. |
| From `lean_frontend`: `lake env leanchecker CerbStop Unit.StopTest CerbMem CerbFailProofs` | Exit 0, no diagnostics. |

The native conformance suite captures both CLI adapters (exit 2), the typed
adapter's ModelFailure (exit 1), the visible pure `failwithI` application and
the monadic refusal (both exit 134). It sets `LEAN_ABORT_ON_PANIC=1`, `NO_COLOR=1`
and `TERM=dumb` and suppresses core-file creation only in its own child process.
The tests preserve control characters, Unicode, literal escaped backslashes,
optional empty items, full upstream/tray metadata, duplicate occurrences and
execution indices. Negative cases cover unknown schemas, objects/duplicate
fields, invalid Unicode escapes, injection through data, mixed fuel/stops,
legacy ambiguity, malformed tails and wrong channels/statuses.

Lake's dependency rebuild replays existing generated/dependency warnings;
neither new module (`CerbStop`, `Unit.StopTest`) emits a warning. No warning
was suppressed. No existing proof statement changed, no axiom-census entry was
dropped, and no runtime round-trip test is represented as a general kernel
theorem about the JSON parsers or the unsafe abort boundary.

Both registration points include the tests: Lake defines `stop-test`, and
`scripts/test_unit.sh` builds/runs it and the Python conformance suite in Tier A.
This closes the registration omission identified in A without adding a new
lane or changing capture infrastructure.

### B.3 Checkpoint gate

After the focused checks and the authorized suffix fix, the complete command
`CERB_MEM_MAX=48G scripts/capped python3 scripts/release.py --mode fast
--out .tmp/outcome-protocol-B/tier-a` exited **0**. Verbatim final summary:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

A1 included the new native and cross-language tests and the existing axiom
census. The latter retained all seven reconstruction entries and reported:

```text
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

The live failure-reach check still reports 239 sealed rows, 237 in the exec
dependency closure plus two unresolved owners, unchanged position classes,
zero DISCARDABLE, and reach counts 173 UNREACHABLE-BY-INVARIANT / 44 REACHABLE /
22 UNKNOWN. The root lexical census is 122 pure and two monadic leaves; the
second monadic leaf is the new, not-yet-called refusal adapter. No register row
or baseline was modified. The final PNVI baseline matched all 164 rows.

This is B's checkpoint gate, not completion of the consumer delivery. Tier B
and the migration/adoption evidence remain scheduled for the later checkpoints.
Scratch captures/build logs are ephemeral; the committed tests and commands
above reproduce the evidence. No merge, push, dependency or machine-global
change was made.

## C — producer migration

**Current status: COMPLETE.** C.5 resolves the adapter ruling; C.7 records the
production proof checks; C.8 records the passing complete Tier A. The earlier
park results below remain historical failures, not successful validation.

**Status at the park-record commit: PARKED under charter §3; C.2 required a ruling.** [AGENT 2026-10-20]
Stop production migration at the adapter/erasure incompatibility. The earlier
register-scope park is resolved by C.1. The producer/test/reference edits remain
uncommitted on the branch while the independent adapter finding awaits a ruling.
B remains the latest completed checkpoint. This documentation-only park record
does not certify C: the production build is RED, the full C axiom census and
production kernel replay have not run, and Tier A failed as recorded in C.4.
A passing Tier A remains required before a completed C checkpoint commit.

### C.1 CerbTags register scope and reference check

[AGENT 2026-10-20, orchestrator, relayed by the operator] The register continues
to cover the execution dependency closure under its existing gate. A known site
outside both execution and frontend closures belongs neither in a counted row
nor in the register preamble. Retain and convert a still-referenced coverage
stub, documenting it here; delete it only if the reference check finds no use.

`CerbTags.tagDefsUnreachable` remains the Lean target representation of
`tagDefs` in `frontend/model/ctype_aux.lem:35`; the adjacent reader declaration
is at line 36. The reader transformation replaces applied model reads with the
reader parameter, so the coverage declaration is still needed even though no
applied reference survives in the generated model. Keep the definition and the
conversion: old token `panic!` at B's `lean_frontend/CerbTags.lean:34`, new token
`failwithI` at the candidate's line 35, with an INVARIANT envelope. No register
row/preamble or gate modification is made for this site.

Reference check, from the worktree root:

```sh
git grep -n tagDefsUnreachable -- ':!lean_frontend/docs' ':!lean_frontend/CLAUDE.md'
grep -Rn tagDefsUnreachable lean_frontend/generated
```

Besides the target declaration and the definition/copied definition, the hits
are explanatory comments in `frontend/model/implementation.lem:44`,
`lean_frontend/CerberusImpl.lean:64` and their generated copies. No test or
generated applied call was found. The fresh kernel dependency census identifies
the owner and reports `exec_dependency: false`, `frontend_dependency: false`.
At this scope check, the 239-row register passed its unchanged checker. Reproduce the fresh
dependency check with capped `scripts/check_failure_reach.sh`; the separate
lexical census still includes this leaf in C's complete hand-written inventory.

### C.2 New finding: whole-monad refusal loses the load erasure interface

The twelve switch-only kills were migrated through B's `refuseM`, as specified
by design §2.3 and charter §0. In particular, the candidate's
`lean_frontend/CerbMem.lean:2880` applies the opaque refusal monad to `st0` in
the `strict_reads` branch. The unchanged public theorem
`CerbMem.loadM_erasure` (`CerbMemAccessFacts.lean:122`) quantifies over an
arbitrary switch set. Its proof now fails; its restatement
`MemoryAccessProofs.load_erasure:73` consequently cannot rebuild. The axiom
census still names the seam theorem at `scripts/check_theorem_axioms.sh:832`.

Reproduction from `lean_frontend`, after the required source-copy sync:

```sh
CERB_MEM_MAX=48G ../scripts/capped lake build +CerbMemAccessFacts
```

Exit **1**. Verbatim diagnostic and representative remaining goal:

```text
error: generated/CerbMemAccessFacts.lean:127:11: unsolved goals
h✝ : CerbGlobal.has_switch CerbGlobal.CerbSwitch.strict_reads = true
⊢ ((f✝ st1✝).fst, stopObserving (f✝ st1✝).snd) = f✝ (stopObserving st1✝)
```

Here `ND f✝` is the matched result of `refuseM`. Its definition is
`failwithI (CerbStop.render (.refusal refusal)) : memM a`. The pinned LemLib
exports no equation for that opaque application. In particular it supplies no
observation-erasure law for `f✝`. Erasure is false for general monads: a monad
that always writes `observations := some []` is a counterexample. A scratch
kernel proof checks this counterexample; this is not a claim that the opaque
constant itself is inconsistent or that a native run returned that state.

[AGENT 2026-10-20, recommendation pending ruling] Preserve the public erasure
statement and change only the new switch adapter's failure ascription to a
kill reason inside a fixed killed node:

```lean
def refusalCandidate {a : Type} (r : CerbStop.Refusal) : CerbMem.memM a :=
  ND fun s => (NDkilled (failwithI (CerbStop.render (.refusal r))), s)
```

This uses the same existing opaque failure atom and runtime panic frame, adds
no ordinary Error/ModelFailure refusal and fixes the returned state to the
input state. Its node is provably never active. The proposal changes the ruled
whole-monad ascription, so charter §3 requires a ruling before production
adoption. It leaves the existing PNVI adapter unchanged. If authorized, rerun
the failure census/position classification for the adapter's newly pure leaf
and apply the existing register scope and sealing rules; no gate exception is
proposed. Restricting the public theorem to `strict_reads = false` is a distinct
consumer-contract weakening and has not been adopted.

The scratch candidate's erasure equation is proved by `rfl`, and exclusion of
an active node by constructor disjointness. Each of those theorems and the
arbitrary-monad counterexample reports only the standard three axioms. The
scratch module was compiled through capped `lake env lean`, then replayed from
`lean_frontend` with the following command: exit **0**, no replay diagnostics.
This is probe evidence, not the required production-module replay.

```sh
CERB_MEM_MAX=48G ../scripts/capped lake env bash -c \
  'LEAN_PATH="../.tmp/outcome-protocol-C:$LEAN_PATH" leanchecker RefusalErasureProbe'
```

The candidate was also compiled to native C and linked against the built
provider objects. Two calls used a dynamic refusal item: one inspected only
the ND constructor and discarded the reason; the other inspected the reason.
Under `LEAN_ABORT_ON_PANIC=1`, `NO_COLOR=1`, `TERM=dumb`, with core files disabled
in the probe process, both captures were passed to `decode_stop`:

```text
discard: exit=134 stdout=b'' stops=1 problems=0
force: exit=134 stdout=b'' stops=1 problems=0
```

Both payloads were REFUSAL/switches with the chosen item. No candidate adapter
has been installed in production. These probes establish the narrow proposed
repair's equations and observed panic behavior; they do not complete C's tests.

### C.3 Validation status at the adapter finding

The focused producer build and reconstruction, monadic-failstop and PNVI-arm
executables passed. The three migrated CLI witness scripts passed after fixing
their separate-capture plumbing. The Python decoder suite passed 17 methods.
The register check passed with 239 rows and unchanged reach counts. These are
focused results, not a replacement for C's gates.

The PNVI self-test's unplanted control failed when its build reached the
`CerbMemAccessFacts` error above. The earlier temporary register-scope park
interrupted the remaining self-test; its exit was **143**, not a pass. No
semantic-verdict movement has been measured by the completed checks, but the
failed control prevents a successful lane claim. Remaining witness runs,
complete axiom census, production kernel replay and a passing Tier A await a
resolution and a rebuilt candidate. D's two policy corrections and E's consumer
delivery remain future work.

### C.4 Gate before the park-record commit

The full scheduled Tier A was run on the unchanged blocked candidate before
this documentation-only commit:

```sh
CERB_MEM_MAX=48G scripts/capped python3 scripts/release.py --mode fast \
  --out .tmp/outcome-protocol-C/tier-a-park
```

Exit **1**, elapsed approximately **4 minutes 57 seconds**. Verbatim summary:

```text
fast: failed; 0/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Every selected command reported `CerbMemAccessFacts` as a failed required build
target. A1 stopped at `memory-access-test`. The PNVI self-test's unplanted
control failed; some negative plants rejected their bad drivers, but baseline
plants could not obtain the control manifest. The suite ended
`test_pnvi: SELFTEST FAILED (3)`. These results are failures, not baseline
movements or successful differential comparisons. No acceptance rule, theorem
quantifier or baseline was changed to turn them green.

No producer, reference, axiom-census entry or register edit is included in this
park commit. The in-progress source is also preserved by the local snapshot ref
`refs/snapshots/outcome-protocol-C-20261020-1792521155` (created at the earlier
interruption, including the new metadata module). The scratch probes and logs
remain ephemeral. The finding reproduces from the candidate with the focused
build above; no dependency, `.lem` source, pin, gate, baseline or machine-global
state was changed to bypass it. No merge or push was performed.


### C.5 Ruled adapter and fresh register classification

[AGENT 2026-10-20, orchestrator, relayed by the operator] Resolve C.2 with a
fixed killed node whose opaque refusal reason is rendered before construction;
return the input memory state. Keep the public all-switch load-erasure statement.
An arbitrary opaque monad admits no general observation-erasure equation, whereas
this fixed node/state pair commutes with erasure by reflexivity. The existing
runtime abort remains at node construction. Design v2 §2.3 records the dated
amendment. Charter success item 1 does not prescribe a whole-monad ascription,
so that item requires no wording change.

[AGENT 2026-10-20] Put the pure leaf in the monomorphic helper
`CerbMem.refusalKill : CerbStop.Refusal → kill_reason mem_error` and use it in
`refuseM`. Unfolding the helper gives the ruled adapter exactly. The existing
hand-written census uses the enclosing declaration's result type; putting the
leaf directly inside the `memM` declaration would retain a monadic census
classification. This layout exposes the actual pure reason without changing the
census, position classifier, register scope or gate. `loadM_erasure` keeps its
statement and adds `refuseM` to its initial unfold. Unused simp arguments in the
touched proof module are removed without changing any theorem statement.

The source comparison also corrects an analogy used during the ruling. At
`3ac3ff336:lean_frontend/CerbMem.lean`, `pnviRefuseM` (line 2266) is still an
opaque whole-monad application. The item G allocator refusal (line 2553) has a
fixed killed node/state pair but ascribes its opaque failure to the String
inside `failStopKill`. The new adapter has the latter's fixed node/state shape,
with failure at the `kill_reason` type. It does not have the existing PNVI
adapter's ascription. No newer mainline producer was imported into this
checkpoint's dispatched base.

Before rebuilding, the dirty tracked and untracked source was preserved without
moving the branch or its index at
`refs/snapshots/outcome-protocol-C-resume-20261020-1792522883`
(`c2147e31d3c461d3e69d4185d49bbc7523915deb`). The generated copies were then
synchronized with capped `make lean-prelude-src` before the capped Lake build.
The complete producer/proof build succeeded (312 jobs); the old failed builds
in C.2–C.4 remain failed historical evidence.

The fresh dependency census finds `CerbMem.refusalKill` in the execution closure;
its pure leaf is TAIL. Its new row is UNREACHABLE-BY-INVARIANT under the admitted
driver switch sets: each of the twelve callers requires a switch outside both
`defaultSwitches = []` and the admitted singleton PNVI-ae-udi set. The ordinary
register check initially rejected the missing row, then passed after adding and
sealing it under the unchanged rules. The separate reference check in C.1 still
keeps `tagDefsUnreachable` outside the register, with no preamble entry.

### C.6 Producer coverage and migration map

The 122 original pure leaves are migrated: 71 UPSTREAM_CRASH, 35 REFUSAL and
16 INVARIANT. The new adapter adds one pure REFUSAL leaf, for 123 current pure
leaves (71/36/16); the existing monadic PNVI helper also renders its refusal.
The A dispositions are retained, including the seven coarse step-equality
guards, the enum guard, alias-normalisation guard, parser-fuel guard, driver
implementation guard, function-map guard and the transparent Tags stub. The
Tags stub now uses `failwithI`, as recorded in C.1. All pure failures keep that
visible head; no new opaque atom or alternate failure mechanism was added.

`CerbStopSites` centralises the nonempty metadata, including 76 cited source
ranges across the six pinned upstream files. Every excerpt was compared to
`git show b9aeedcb4dd438763b0eef7f95ac19e93875d7de:<path>` at its declared
range. The original claim that all 76 matched exactly was too strong: the
pre-merge review measured **74/76 exact modulo indentation** at `fb5b4d4a1`.
The other two excerpts were contained in their ranges with one extra blank line:
`intfrombyte` cited 2778–2780 instead of 2779–2780, and `stepSpawnEquality`
cited 110–128 instead of 110–127. The review fix narrows those ranges; a fresh
comparison against the pinned files gives **76/76 exact modulo indentation**.
Historical explanatory strings are retained even when an old embedded line
reference differs from the reconstructed citation.
The bswap64 tray remains explicitly a draft. No inferred upstream origin is
used for the annotated invariant guards.

The nine typed sites keep their killed-node and failure-time state shapes:
allocator alignment, requested-address allocation, dead-static kill,
resolved-store absence, function-pointer shift, impossible symbolic shift,
memcmp byte, va-list index and intrinsic call. Their structured Failure input
admits only UPSTREAM_CRASH or INVARIANT. The twelve switch-only arms use the
fixed-node refusal adapter. Driver refusal collection emits one envelope per
switch element (including repeated or empty elements), then exits once with
2. Existing usage errors keep exit 1. The batch UB preflight refuses before
printing partial result records.

The immediate tests migrate with the producers: all seven `MonadicFailstop`
pins, `PnviArmsTest`, the CLI/runtime/Cabs-UTF8 witnesses and their negative
stubs, the three fuel CLI assertions, the observation-lane structured-crash
positive plant and the envelope-less negative controls. The existing
address-space detail-substring checks survive because their explanations stay.
PNVI refusal recognition and its self-test stubs decode the new producer
format; this is format compatibility at the existing classification point.
D's invariant precedence and unattributed-panic policy corrections remain for D.

The [register migration map](2026-10-20_outcome-protocol-register-migration.tsv)
pairs the 111 affected existing hand-written rows by owner, old/new source line
and old/new seal against B (`bd545c706`). Their full old/new keys are recoverable
from that revision and this commit using the seals. Their recomputed position
and reach classes are unchanged. It also records the newly added adapter row;
all 128 generated rows are unchanged. The eleven original pure leaves outside
register scope remain in the lexical inventory without invented register rows.
The current check reports:

```text
240 pure failure sites = the 240 register rows exactly
238 in the exec dependency closure + 2 unresolved-owner
position classes unchanged; 0 DISCARDABLE
reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=44 UNKNOWN=22
```

The full checker output additionally confirms every row's seal and the tally
line. Reproduce with capped `scripts/check_failure_reach.sh`; it rebuilds the
dependency instrument and reruns the source census.

### C.7 Reconstruction and consumer-facing proof contracts

The ruled diagnostic parameter is implemented in both the linear and indexed
references. `historicalDiagnostics` recovers the old frozen reference bodies;
`productionDiagnostics` uses the renderer at the production sites. The
reference-to-reference equations quantify over diagnostics. Each of the six
production compatibility equations retains its prior input quantifiers and
uses the production diagnostic instance. No failure arm is removed by a new
precondition. The two frozen bodies were compared to B after normalising only
comments, whitespace and their recursive names; both matched.

The test header, theorem descriptions, production reconstruction comments,
CLAUDE's current test catalogue and VALIDATION's W2 description name this changed
claim. The catalogue correction changes no standing working practice. The
[cerberus-sl handoff](2026-10-20_consumer-note-cerberus-sl-outcome-protocol.md)
explains the explicit reference argument, the historical/production distinction
and the remaining emitted-record limits. It makes no consumer adoption claim.
`CerbMemDefaultFacts` retains its public statements; `CerbMemAccessFacts` and
`MemoryAccessProofs` retain their all-switch erasure statements. The seven
existing reconstruction axiom-census entries remain and the two historical
recovery theorems are added.


The final memory-access rebuild exits **0** (257 jobs), with no remaining
`CerbMemAccessFacts` warnings. No linter option or resource limit was raised to
repair the proof. The new metadata and reconstruction test also build without
warnings. Existing warnings in generated/dependency code remain outside this
producer/proof repair; no warning was suppressed by this checkpoint.

Production kernel replay, from `lean_frontend` with `CERB_MEM_MAX=48G`, was:

```sh
../scripts/capped lake env leanchecker \
  CerbStopSites CerbDecode CerbFS CerbFloat CerbFunMapInstances CerbLocation \
  CerbMem CerbMemAccessFacts CerbStepInstances CerbTags CerbUtils CerberusImpl \
  CoreParser CerbMemDefaultFacts CerbFailProofs Unit.MemoryAccessProofs
for module in Main Unit.ReconstructLegacyTest Unit.PnviArmsTest Unit.MonadicFailstop; do
  ../scripts/capped lake env leanchecker "$module" || exit "$?"
done
```

**Exit 0 for each of the five invocations**, covering all 20 named modules;
`leanchecker` emitted no diagnostics. The executable modules are replayed
separately because importing several executable roots into one Lean environment
collides at their global `main` declarations. An initial supplementary scratch
axiom probe failed on that collision; it was corrected without changing any
production source or theorem.

A supplementary `#print axioms` probe imports `CerbMemAccessFacts`,
`CerbMemDefaultFacts`, `Unit.MemoryAccessProofs`, `Unit.ReconstructLegacyTest`
and `CerbStopSites`. It prints every named theorem in the four proof modules
and `CerbStopSites.appendText`: **53 declarations, exit 0**, exact name set
checked, only the standard three axioms (or none). Long axiom lists wrap across
lines; the result check parses complete lists, not a count of output lines.
Representative verbatim output:

```text
'CerbMem.loadM_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
'MemoryAccessProofs.load_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
'ReconstructLegacyTest.historical_linear_recovers' depends on axioms: [propext, Classical.choice, Quot.sound]
'ReconstructLegacyTest.historical_indexed_recovers' depends on axioms: [propext, Classical.choice, Quot.sound]
'ReconstructLegacyTest.reconstructValue_lemFuel_eq_legacy' depends on axioms: [propext, Classical.choice, Quot.sound]
```

### C.8 Final focused results and checkpoint gate

The final production adapter was compiled in a native scratch probe, using
`CerbMem.refuseM` rather than the C.2 candidate. One call observes just the ND
constructor and discards the reason; the other inspects the reason. Both use a
dynamic refusal item, `LEAN_ABORT_ON_PANIC=1`, `NO_COLOR=1`, `TERM=dumb`, and
process-local disabled core dumps. The separate capped captures decoded as:

```text
discard: exit=134 stdout=b'' stops=1 problems=0
force: exit=134 stdout=b'' stops=1 problems=0
```

Both decoded stops are REFUSAL/switches, with the corresponding dynamic item.
The production adapter's erasure equation also compiles by `rfl` in the scratch
module and prints only the standard three axioms. Its separate capped
`lake env leanchecker ProductionRefusalProbe` replay (with the scratch directory
added to `LEAN_PATH`) also exits **0**, without diagnostics. This native evidence checks
the operational abort; it does not turn a native-panic property into a theorem.
A minimal native reproduction uses this `main` after `import CerbFailProofs`:

```lean
def main (args : List String) : IO UInt32 := do
  let item := args.headD "probe"
  let m := CerbMem.refuseM (a := Unit) (CerbMem.switchRefusal item "production adapter probe")
  match args with
  | ["discard"] =>
    match (CerbFail.step m (CerbMem.initialMemState 65536)).1 with
    | .NDkilled _ => IO.println "RETURNED A KILL WITHOUT FORCING ITS REASON"
    | _ => IO.println "RETURNED A NON-KILL"
  | _ =>
    match (CerbFail.step m (CerbMem.initialMemState 65536)).1 with
    | .NDkilled (.Error0 _ msg) => IO.println msg
    | .NDkilled (.Undef0 _ _) => IO.println "RETURNED UNDEFINED"
    | .NDkilled (.Other _) => IO.println "RETURNED OTHER"
    | _ => IO.println "RETURNED A NON-KILL"
  pure 1
```

Compile under capped `lake env lean -c` and `lake env leanc`. For linking, copy
`.lake/build/bin/monadic-failstop-test.rsp` into `.tmp/` and replace its first
object (the test entry module) with this probe's object, retaining the existing
provider/native/runtime objects. Run the resulting executable through
`scripts/capped` with arguments `discard` and `force`, then use `decode_stop`
on the original separate stdout/stderr bytes and exit status. No probe artifact
is part of the committed source.

The focused checks also passed: reconstruction **18/18** runtime controls;
monadic failstop **23 checks** at each of fuels 2 and 17; PNVI arms **37/37**
runtime checks with their compile-time pins; the Python/Lean codec suite
**20 tests**; all fuel plants, including the three migrated CLI assertions;
and the selected real-lane plant suite:

```sh
CERB_MEM_MAX=48G scripts/capped python3 scripts/test_observation_lanes.py \
  --lane exec --lane multi_tu --lane immaculate \
  --out .tmp/outcome-protocol-C/observation-lanes-final
```

Exit **0**; verbatim final line:

```text
observation lane plants: 25/25 passed
```


The complete scheduled Tier A then ran on the final source:

```sh
CERB_MEM_MAX=48G scripts/capped python3 scripts/release.py --mode fast \
  --out .tmp/outcome-protocol-C/tier-a-final
```

Exit **0**, elapsed **31 minutes 3 seconds**. Verbatim summary:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

A1 includes the full `scripts/check_theorem_axioms.sh` gate, exit **0**. Its
seven existing reconstruction entries are retained and the two historical
recovery entries are included. Verbatim census summaries:

```text
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (226 files: 0 axioms, boundary-opaque population = the 9 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (432 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 19 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: mem-scale S1 leg OK (37 C1/C3 + PNVI-S2 wrapper equality + CerbMemDefaultFacts bridge + CerbMemAccessFacts erasure theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

The existing registered runtime opaque/extern boundaries remain; this is not a
claim that the provider has none. No opaque atom, axiom, `sorry`, non-kernel
proof method, `unsafe` declaration or kernel-check bypass was introduced.

A1 also rebuilt the failure-reach instrument and passed all register plants and
the final unplanted census. Verbatim final check:

```text
check_failure_reach: OK (240 pure failure sites = the 240 register rows exactly (238 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
```

The three immediate witness scripts passed in A1: the CLI's 24 refusal cases,
placement/repetition cases and real PNVI agreement control; runtime resolution's
17 witnesses and both negative stubs; Cabs UTF-8's 9 witnesses and both negative
stubs. A12 passed both the address-space self-test and the unplanted lane,
confirming that the retained detail substrings still satisfy its checks. A13's
paired memory-access grid passed. The PNVI self-test passed its real control,
10 engine plants and 7 baseline plants. The final full lane reported:

```text
SUMMARY: rows=164 AGREE=152 AGREE-FIRST=3 BOTH_FAIL=2 REFUSAL=7 | switch vs default (oracle): litmus:same=27,changed=17 minimal:same=111,changed=2 pkvm:same=1,changed=3 witness:same=0,changed=3
pnvi_lane: BASELINE OK (164 rows = the baseline, classes, oracle hashes and BOTH_FAIL/RESOURCE lean hashes exact)
```

No semantic verdict or committed baseline moved. No `.lem`, dependency, Lem
pin, register gate or machine-global state was changed. C completes producer
migration and its immediate proof/witness work; D's two classifier corrections
and E's complete consumer demonstration/Tier B remain outstanding. This is not
an external consumer-adoption or complete release claim. No merge or push was
performed. Scratch captures and probe artifacts are ephemeral; the source,
conclusions, reproduction commands and migration map are the committed result.


### C.9 Missing migration-commit body, supplied after review

[AGENT 2026-10-22] Commit `5f8fd8d7e` has only its subject. The following is
the body it should have carried, reconstructed from C.6–C.8's recorded checks
for use in the landing note. It records the C-time evidence, not a new run;
no commit is amended or history rewritten.

```text
Migrate the nine typed kills, all 122 inventoried pure leaves and the existing
pure/monadic/driver refusals to structured stops. Use the ruled fixed killed-node
adapter for the twelve switch-only refusals, preserving the public erasure
contracts. Switch rejection emits one envelope per element before one exit.
Update the immediate pins, CLI/PNVI witnesses and register key/seal map together.

Parameterise both reconstruction references over their diagnostics; prove
historical recovery separately and restate production equality at the renderer.
Retain the existing axiom-census entries and add both historical-recovery names.

Verified: Tier A 19/19, exit 0, unchanged source and complete selection;
kernel replay of 20 modules in five invocations, all exit 0; supplementary
axiom probes of 53 declarations, only the standard three or empty cones;
full retained axiom census and failure-reach gate, 240 exact sealed rows;
25/25 selected observation plants; the CLI/runtime/Cabs-UTF8 witnesses;
PNVI self-test and 164-row baseline, with no semantic verdict or baseline move.
```

## D — two lane corrections

[AGENT 2026-10-20] Keep the existing coarse negative-test CRASH pins and their
hashes; emit an explicit legacy/origin-unattributed diagnostic when the new
parser recognizes an envelope-less panic. Those pins do not establish a shared
origin or semantic agreement. No other lane's comparison or resource policy is
changed.

`pnvi_lane.classify_side` inspects every decoded stop before its resource exits;
an invariant becomes INVALID even with fuel, a bad tail or host-failure status.
`classify_row` retains that invariant explanation before inspecting the oracle.
The immaculate classifier similarly inspects Lean captures before its OOM/crash
projection. An invariant exits the lane before either baseline comparison or
baseline recording, independently of the oracle token. The ordinary Error and
verdict comparisons, PNVI refusal registration and resource direction rules stay
as before.

Focused reproduction (from the prepared provider root):

```sh
python3 scripts/test_observation_lanes.py --stop-policy-only \
  --out .tmp/outcome-protocol-DE/policy
CERB_MEM_MAX=48G scripts/capped python3 scripts/test_observation_lanes.py \
  --lane immaculate --plant crash-invariant --plant crash-legacy \
  --plant crash-model --out .tmp/outcome-protocol-DE/lane-plants
```

The first command exited **0**, with the actual Python and shell classifier
functions tested on eight capture shapes against five oracle outcomes. Verbatim:

```text
STOP POLICY: 40 invariant/oracle pairs RED in both classifiers; legacy origin unattributed
```

The shapes are typed, panic, CLI, mixed upstream/invariant/fuel, malformed tail,
status 124, bare 137 and positive OOM diagnostic. The oracle cases include a
verdict, crash, resource and invalid capture. The real-lane plants additionally
exercise the unconditional invariant veto against the existing oracle-crash row
`g2-memcmp-uninit`, and the structured-upstream and legacy controls. The existing
plant runner can select named plants to avoid rerunning unrelated full pipelines
during development; its default still runs the complete suite, including the
focused classifier matrix. No new release gate is introduced.

## E — consumer handoff and close-out

Read-only consumer checks found clean trees at:

- cerberus-caesium `7d23b26413b50d406a6e0963f81775cb04045da0`;
- cerberus-sl `68832d914227a29c37df381d3e83ad274147e24c`.

Caesium's `scripts/differential.py` still has `run` at 148, `parse_driver` at
547, `run_driver` at 573 and `driver_summary` at 735. Its capture is separate
stdout/stderr with replacement decoding, then ModelFailure-to-Error conversion,
five-line/500-character truncation and resource/crash summary early returns.
The provider patch recipe must still decode raw bytes first. Neither consumer
was modified or re-pinned; no adoption is claimed.

**Finding E.1 — the installed cap wrapper has a second terminal suffix shape.**
Design v2 §4.1 freezes the provider's `scripts/capped` suffix. Caesium's exported
`cap` function (`scripts/env.sh:65`) selects the installed wrapper when present.
On this host it is `/usr/local/bin/capped`; its `cgroup_direct` function runs a
subshell at lines 161–165, rather than the provider wrapper's direct `"$@"`.
Bash prints that entire subshell as the abort diagnostic. This is distinct from
the spacing amendment already made in B.

A read-only extraction of the consumer's actual `run` function invoked the
candidate `stop-test pure` through that exported cap function and `timeout 45`.
The result was exit **134**, empty stdout, one retained UPSTREAM_CRASH, and:

```text
StopProblem(channel='panic', position=SourcePosition(line=12, offset=1346), reason='unexpected diagnostic after panic frame')
```

The terminal diagnostic in that probe was:

```text
/usr/local/bin/capped: line 147: 62164 Aborted                 ( { echo "$BASHPID" > "$cg/cgroup.procs"; } 2> /dev/null || { echo "$prog: could not move into $cg: refusing to run uncapped" 1>&2; exit 4; }; exec env CAPPED_STATE=1 CAPPED_MEM_MAX="$MEM" "$0" "$@" )
```

The preceding line was `timeout: the monitored command dumped core`. This
wrapper path/command has not been admitted by the decoder. Metadata survives
beside the problem; that does not turn the capture into a clean decode.

[AGENT 2026-10-20] Recommend one additional terminal alternative for this
source-checked wrapper form, with the subshell text matched literally, only the
wrapper prefix/line/PID and Bash padding variable, and the existing ordering and
one-suffix cardinality retained. Reject any changed command or appended material.
This requires a design ruling under charter §3; it is not a general shell-banner
parser or a host-origin guarantee. The ruling was subsequently supplied as recorded below.

The design's mixed pure/typed C program was also remeasured through this actual
consumer runner (fresh Cabs, default fuel). First-trace mode returned **1**, one
ModelFailure and one clean UPSTREAM_CRASH at `CerbMem.memcmpByte`, with the pinned
upstream `memory/concrete/impl_mem.ml:2658–2659` citation. Exhaustive mode returned
**134**, empty stdout, **zero emitted ModelFailures**, and one REFUSAL with
boundary `fs`, item `open`, mover `a SibylFS-faithful filesystem model`; it has
the same terminal-suffix problem. This is the stated loss **before emission**:
the decoder cannot recover the typed branch discarded by the later pure abort.
It does not claim that the typed branch was never evaluated.


### E.1 Wrapper disposition

[USER 2026-10-20] Admit the narrow installed-wrapper terminal alternative and
continue D/E, preserving suffix ordering/cardinality and rejecting altered
commands. The design's dated §4.1 amendment states the exact accepted language;
`STOP_INSTALLED_ABORT_WRAPPER` implements it with a regex-escaped literal command.
It does not change the schema, host-resource policy or other lane parsers.

The installed wrapper read for this check had SHA-256
`c4a2cc978c1112ea70799d5bb88b76b2af8584792596d25e8024574da62a8f41`.
The decoder tests cover both real wrapper forms, optional core-dump spelling,
changed command/exit, a wrong basename, tabs, duplicate/mixed suffixes, reversed
timeout order and appended garbage. Earlier metadata remains available on each
malformed tail; only the exact authorized form becomes clean.

### E.2 Consumer demonstration

The read-only prototype extracts Caesium's current `run` function with Python's
AST and removes only `text=True, errors="replace"` from its subprocess call.
It uses the actual exported `cap` function and its timeout arrangement, keeps the
four-result tuple, and sends the complete byte streams to `decode_stop` before
any consumer parsing or truncation. No consumer source file is executed for
setup side effects or edited. The reproducible provider test is:

```sh
CERB_MEM_MAX=48G scripts/capped python3 scripts/test_stops.py \
  --consumer-demo /path/to/cerberus-caesium \
  --out .tmp/outcome-protocol-DE/consumer
```

Exit **0**; verbatim summary:

```text
CONSUMER DEMO: 22 captures passed; emitted records only; no external adoption
```

There are fourteen native adapter/driver captures and eight explicitly labelled
transport fixtures. They cover all three stop constructors on their admitted
channels, two switch refusals in one invocation, both panic fuel frames, the
exact fuel kill, a real generated legacy panic, the mixed pure/typed C witness,
three emitted typed causes with execution indexes `[0, 1, 2]`, verdict/stop and
stop/fuel batches, a valid stop followed by a malformed reserved envelope,
invalid cross-channel causes retained beside a problem, and detail/program-data/
ordinary-Error injections. REFUSAL is not an admitted ModelFailure class; the
clean mixed batch therefore combines UPSTREAM_CRASH and INVARIANT, while the
cross-channel fixture deliberately remains invalid. Tests assert complete
metadata equality for adapter and fixture envelopes, pinned source/tray fields
for the actual memcmp producer, and filesystem boundary/item/mover/see fields.

Verbatim mixed-program results after the suffix amendment:

```text
mixed-first: exit=1 stops=1 fuel=0 legacy=0 problems=0
mixed-exhaustive: exit=134 stops=1 fuel=0 legacy=0 problems=0
```

The first stdout has exactly one ModelFailure; exhaustive stdout is empty,
with **zero emitted ModelFailures**. The complete emitted cause collection is
therefore one upstream stop versus one refusal, respectively, not a recovered
list of every explored cause. This limitation is repeated in the handoff.

The first-delivery family table and the actionable patch recipe are in
[the Caesium handoff](2026-10-20_consumer-note-cerberus-caesium-outcome-protocol.md).
The companion [SL note](2026-10-20_consumer-note-cerberus-sl-outcome-protocol.md)
retains the changed reconstruction contract and the unchanged fuel/OOM/kill
interfaces. Neither note claims an external build or adoption.


### E.3 SL compatibility and proof boundary

The consumer's current definitions were re-read at the pinned HEAD above;
[its handoff](2026-10-20_consumer-note-cerberus-sl-outcome-protocol.md) records
the source locations, unchanged aliases and the three scratch probe statements.
No production Lean source or proof module changes in D/E. The existing C kernel
replays remain the evidence for the migrated proof modules; the complete axiom
census runs again in the scheduled Tier A/B checks.

The initial scratch compile omitted `--root`, failed before elaboration, and
left no olean for the attempted replay (both exit 1). The corrected commands,
from `lean_frontend`, were:

```sh
CERB_MEM_MAX=48G ../scripts/capped lake env lean \
  --root=../.tmp/outcome-protocol-DE \
  -o ../.tmp/outcome-protocol-DE/OutcomeSlProbe.olean \
  ../.tmp/outcome-protocol-DE/OutcomeSlProbe.lean
CERB_MEM_MAX=48G ../scripts/capped lake env bash -c \
  'export LEAN_PATH="$1:$LEAN_PATH"; exec leanchecker OutcomeSlProbe' \
  _ "$PWD/../.tmp/outcome-protocol-DE"
```

Compile exit **0**, kernel replay exit **0**. Verbatim census:

```text
'OutcomeSlProbe.fuel' does not depend on any axioms
'OutcomeSlProbe.oom' does not depend on any axioms
'OutcomeSlProbe.model' does not depend on any axioms
```

The existing unit selector comment still described equality to pre-S2 text;
that stale description is corrected to productionDiagnostics plus separate
historical recovery. No theorem statement or census entry is changed here.
The LADDER unit row now names the twentieth executable (`stop-test`) and codec
suite, and the register row records C's measured 240 rows. Membership is unchanged.

### D/E focused validation and final gates

The real immaculate plants exited **0**. Verbatim output:

```text
PLANT OK   immaculate: crash-model
PLANT OK   immaculate: crash-invariant
PLANT OK   immaculate: crash-legacy
observation lane plants: 3/3 passed
```

These deliberately altered streams are plant outcomes, not moved semantic
verdicts. No committed baseline has been edited. The final scheduled runs below
check both full lane baselines and the unchanged source snapshot.


The initial extracted-function harness had a test defect: it omitted
`is_cap_kill`, so its legacy control printed a shell command-not-found error
and still reported success. That was an invalid legacy control, not a clean
pass. The invariant matrix returned before that helper, and the real lane
plants used the actual helper. The harness now extracts the production helper
and its shared regex too, requires empty stderr on invariant/ordinary/OOM
controls, and requires exactly the expected legacy diagnostic on the legacy
control. The corrected focused run exited **0**, verbatim:

```text
STOP POLICY: 40 invariant/oracle pairs RED in both classifiers; ordinary/OOM/legacy controls passed
```

Tier A preflight command:

```sh
CERB_MEM_MAX=48G scripts/capped python3 scripts/release.py --mode fast \
  --out .tmp/outcome-protocol-DE/tier-a
```

Exit **0**; verbatim summary:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The 164-row PNVI baseline is unchanged: 152 AGREE, 3 AGREE-FIRST, 2 BOTH_FAIL
and 7 REFUSAL, with all class/oracle/Lean hashes exact. Every other Tier A
baseline also passed without a re-record. The only subsequent code edit before
Tier B is the focused test-harness repair above; the full run repeats Tier A
and runs the corrected plant suite on the final source.

### D/E tripwire park — full gate incomplete

[AGENT 2026-10-20] Apply charter §3's one-hour tripwire to the aggregate
invocation while its intended scope is unresolved. The requested full runner
selects A and B together; its own timeout is per command. Recommend applying
the tripwire to each ladder command, retaining a stop when any one command
approaches one hour, so the required aggregate certification can finish. That
clarification was requested before dispatch and remained unanswered at the
stop point; no broader timing authorization is inferred.

[AGENT 2026-10-20, relayed by the operator] The orchestrator clarified the
previously unspecified scope: the approximately one-hour tripwire applies to
one build/proof pass, measured per ladder command. The full validation sweep
normally takes longer overall and requires no exceptional time authorization.
The interrupted B7 counts as unrun for certification, never as a passed row.

[USER 2026-10-20] Await integration dispatch before rebasing or running the
next full battery. Prepare the incoming changes read-only, retain the C
snapshot refs until close-out, then rebase without merge commits and validate
the integrated tree. There is no permission to push.

The exact full command was:

```sh
CERB_MEM_MAX=48G scripts/capped python3 scripts/release.py --mode full \
  --out .tmp/outcome-protocol-DE/tier-b
```

It ran from 21:37:09 to 22:32:11 UTC on 2026-10-20 (55 minutes 2 seconds).
The verified owned runner received SIGINT at the tripwire. Exit **1**;
verbatim summary:

```text
full: incomplete; 31/42 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

All nineteen A commands passed again on the final code, followed by B1–B5 and
all seven B6 commands. PNVI's 164 rows and immaculate's complete baseline were
unchanged; no baseline file was edited and no semantic verdict movement was
observed in the completed checks. Lake replayed the already documented
generated/dependency warnings; none was suppressed. No D/E production proof
module changed, and no additional production kernel-replay claim is made.

B7 was interrupted after 762.250 seconds, with 868 of 2030 GCC cases printed.
That prefix is not a passed GCC baseline check. The runner marked B7
`incomplete`, reason `runner interrupted by signal 2`; its owned command was
killed during cleanup (exit status -9). `containment_cleaned` was true, the
command cgroup was absent afterward, and `artifact_issues` was empty. B8.1–B8.4,
B9, B10.1–B10.2, B11.1–B11.2 and B12 were not reached. The longest completed
command was B1 at 684.034 seconds; no individual command approached an hour.

The corrected focused policy plants and three real immaculate plants passed
as quoted above, but they do not substitute for the unreached full B9 suite.
Likewise A1's register gate does not complete the separate B11 selection.

After interruption, all twelve modified files and the new Caesium handoff
were preserved in a temporary snapshot before any park edits. This commit
preserves the implementation, the approved wrapper amendment and both consumer
handoffs. The temporary D/E snapshot and reconstructible D/E scratch outputs
are removed once that source is committed. The two C snapshot refs remain
until actual close-out:

- `refs/snapshots/outcome-protocol-C-20261020-1792521155`
- `refs/snapshots/outcome-protocol-C-resume-20261020-1792522883`

Remaining work is integration dispatch, the rebase and focused checks, Tier A,
a complete full run on the integrated code with its quoted result, deletion
of those C refs recorded in the close-out commit message, and the close-out
commit before the fresh pre-merge review. No external adoption, merge or push
is claimed.

### Integration preparation — read-only comparison, before dispatch

Prepared at outcome-protocol HEAD `9d8e12d984c4bccfce04d7dd6f995c9ec609c3c4`.
The compared immutable revisions are base
`c55e95ee278215446afeb9a74b62b6fd4833bea2`, item-G mainline
`3ac3ff3366ff0c8614f107d46bb169fe76997630`, and `feature/core-quote` at
`f69504b2a9ab03842ba5ab7ebcd8c27c76d6abc3` (nine commits above item G).
These are preparation inputs, not a claim that the quotation branch has
landed. Re-resolve the authorized mainline at dispatch.

The requested comparison was run for both incoming revisions:

```sh
git diff c55e95ee2..3ac3ff336 -- lean_frontend/CerbMem.lean \
  lean_frontend/Main.lean scripts/failure_reach_register.txt \
  scripts/test_unit.sh scripts/LADDER.md lean_frontend/VALIDATION.md
git diff c55e95ee2..feature/core-quote -- lean_frontend/CerbMem.lean \
  lean_frontend/Main.lean scripts/failure_reach_register.txt \
  scripts/test_unit.sh scripts/LADDER.md lean_frontend/VALIDATION.md
```

The full changed-path sets, adjacent proof/witness changes, and exact source
definitions were also inspected. No rebase, source implementation edit,
regeneration, Lean invocation or validation battery was performed during this
preparation. Only this record is edited, to travel with the next validated
integration commit.

#### Tree findings and the item-G disposition

1. **The two incoming leaves have different shapes.** At item-G mainline,
   `CerbMem.lean:2553` has
   `NDkilled (CerbFail.failStopKill (failwithI (alignmentRefusal align sz)))`.
   At `:3666`, `memcpyM` instead has the whole-monad application
   `failwithI (memcpyOverlapRefusal region a1 a2 size_n)`. The quotation branch
   does not change either body. Preparation must not assume two fixed killed
   nodes, or infer an erasure law for the whole-monad value.
2. **Item G added no failure-register rows.** The register blob is identical
   at the base and both incoming refs:
   `046c43e57144db2263886bd886b0fba5c41d2a0b`. Neither owner has a row. A read-only
   probe fed each Git blob to the existing `failure_census.census` using an
   in-memory `Path.read_text` substitute. Its verbatim result was:

   ```text
   3ac3ff336 CerbMem.allocator 2553 monadic_ascribed failwithI
   3ac3ff336 CerbMem.memcpyM 3666 monadic_ascribed failwithI
   feature/core-quote CerbMem.allocator 2553 monadic_ascribed failwithI
   feature/core-quote CerbMem.memcpyM 3666 monadic_ascribed failwithI
   ```

   The lexical census uses a hand-written declaration's `memM` return type
   (`scripts/failure_census.py:105`), including for the nested allocator leaf.
   This explains the bucket; it is not a proof of the inner leaf's type or
   reachability. Do not invent two incoming rows or alter the gate. Recompute
   the actual census, position and reach classes after integration; the TSV
   must describe measured key/seal changes, not an assumed row increment.
3. **The frozen boundary vocabulary has no memory-model category.** Design
   v2 §2 and `CerbStop.Boundary` admit thirteen values. `runtime` describes
   runtime-library provisioning, `address-space-arg` the CLI bound, and `cli`
   argument admission; none honestly describes these two semantic-operation
   refusals. Inventing a boundary or repurposing one would change the schema.

[AGENT 2026-10-20] Use the permitted unmigrated disposition for both new item-G
leaves at this integration. Preserve their predicates, priority, abort channel
and historical diagnostics; do not label them UPSTREAM_CRASH or assign a false
REFUSAL boundary. Register their protocol status in the inventory below and
carry the limit into the integrated family table and consumer handoff. Named
mover: **memory-model refusal metadata extension**, under the
[structural-outcome plan's WP2](2026-09-16_lean-only-outcomes-implementation-plan.md),
which must settle the boundary vocabulary, both producers, their exact-text
witnesses and consumer decoding together. This choice follows the schema
inspection and supersedes the initial working suggestion to migrate them
immediately. It does not alter item G's declared refusal semantics.

| Site and checked source | Interaction with this branch | Prepared resolution / protocol status |
|---|---|---|
| `allocator` alignment-zero arm, incoming `CerbMem.lean:2543`, ours `:2542` | Existing typed kill migrated through `CerbStopSites.allocatorAlignment` | Retain its UPSTREAM_CRASH envelope and incoming ordering: OOM, zero alignment, invalid nonzero alignment, ordinary allocation. The new refusal must not replace the zero-alignment crash. |
| New `allocator` invalid-alignment leaf, incoming `:2553`; text helper `alignmentRefusal:2488` | Absent from C's 122-leaf inventory; incoming fixed killed node has an opaque String message | **UNMIGRATED**, named mover above. A validated emitted frame yields legacy/unattributed metadata through `decode_stop`, not a REFUSAL object. Preserve the hypothesis-free allocator theorem. |
| New `memcpyM` overlap leaf, incoming `:3666`; predicate `memcpyOverlap:3634`, text helper `memcpyOverlapRefusal:3644` | Absent from C's inventory; incoming whole-monad failure, not our `refuseM` adapter | **UNMIGRATED**, same mover. Preserve allocation/device cases, ordering before accesses, and the documented mixed-provenance residual. Do not rewrite this incoming value's proof contract by analogy with C.2. |
| `integerRem_t`, ours `CerbMem.lean:1739–1740`, `CerbStopSites.integerRemTrunc` | Not edited by item G, but its unchanged zero-alignment witness now consumes our structured panic | Keep UPSTREAM_CRASH. The witness's original detail substring survives the envelope; check it with the actual integrated driver. |

The two unmigrated sites remain declared refusals in CONTRACT D10 but are
**not distinguishable as REFUSAL by the generic wire API** at this delivery.
Their text must not become a decoder heuristic. The consumer handoff must
name this gap, rather than claim all hand-written stops have attribution.
At integration, qualify the incoming CONTRACT D10/consumer-note promise of
envelope migration with this explicit follow-up; it is not completed here.
The dedicated `check_item_g_refusals.sh` still compares the old texts and exits
125/134. Its actual final inventory is nine refusal programs (six memcpy,
three alignment), nine verdict controls and one crash control; several incoming
summary descriptions still say four memcpy/eight controls. Align the touched
descriptions with the script, without weakening its five negative plants.

#### Prepared resolutions beyond the two new leaves

[AGENT 2026-10-20] Integrate both branches' behavior explicitly; do not resolve
overlapping files by taking one side wholesale. The following is the proposed
resolution and focused verification inventory, awaiting dispatch.

| Surface | Resolution and check |
|---|---|
| `Main.refuseLibraryLocations` | Keep the incoming resolved-directory guard and all three failure paths (runtime directory resolution, source directory resolution, foreign resolved directory). Route its local refusal helper through the existing library-location envelope, preserving exit 2, the source item, explanation and canonical quotation convention. Preserve the documented relative-runtime divergence and fixture-001 witness; do not restore the older literal comparison. |
| `Main.refuseFlag`, `judgeSwitches`, pipeline | Keep quotation flags/options and early quotation return, plus our per-element switch envelopes, invariant fallback and batch UB prevalidation on execution paths. Include both `CerbQuote` and `CerbStopSites` imports. |
| New quotation CLI refusals | Incoming `Main.lean:1659,1664,1789,1796,1854` are five new exit-2 admission refusals. Use the existing `cli` boundary with the responsible option and quotation-specific mover; retain explanatory substrings. Missing path/libc usage errors remain exit 1. Printer `Except` errors remain quotation `Error` records, outside the semantic-stop guarantee. Exercise duplicates, incompatible modes, identical output paths and missing user TU; assert no output file is published on refusal. |
| Runtime and quotation witnesses | Combine our separate stdout/stderr capture and decoder assertions in `check_runtime_resolution.sh` with the incoming classifier-divergence/execution controls. Recheck the quotation runner's wrong-cwd and no-user-TU controls (`test/CoreQuote/CoreQuoteRoundTrip.py:163–167,209–212`); their explanation checks survive envelope rendering. The historical CLI smoke probe is unwired and does not replace current focused checks. |
| Item-G proofs and all C proof modules | Preserve incoming `CerbMemAllocatorProofs.allocator_active_sound` and `Unit.FuelExemplar.allocator_errno` repairs. Rebuild the affected dependency cones, retain the reconstruction diagnostic parameter contract and all census entries, then replay changed proof modules plus the C proof set; quote exits and axiom results. No reduction in public statements. |
| Lake/copy/unit registration | Union `CerbQuote` and its support libraries/executable with `CerbStop`, `CerbStopSites` and `stop-test`; retain both manifest entries and both test registrations. Row 1 should describe 21 unit executables, subject to the merged executable list. Keep the Python codec suite in ordinary row 1 and the quotation-only Tier B mode's early return. |
| Ladder and validation documents | Preserve item-G witnesses and baseline retirements, quotation instrument limits and row B13, and D's two lane corrections/CONTRACT §1 outcome vocabulary. The existing parser reports 19 A commands and **43 full commands** on the quotation branch, versus 42 on item-G mainline. Re-enumerate the final table; never use the old count as a selection limit. |
| Failure register and migration TSV | Preserve the C key/seal mappings as history and reconcile final line/owner/key mappings against fresh census and dependency results. The two new monadic buckets do not justify fabricated pure rows. If a new pure helper becomes necessary later, classify and seal it through the existing rules. No preamble or gate exception. |
| Tray INDEX and source citations | Keep incoming drafts 56/57 dispositions and draft 58 in order. No row 59 exists in the inspected refs, and this branch has no INDEX delta from the base. Recheck at dispatch instead of pre-resolving a nonexistent 58/59 collision. Pinned upstream citations stay at their immutable revision; recompute moving fork/source line references that are touched. |
| Baselines and fork inputs | Item G already retires `mem4-020-memcpy-overlap.c` from the coverage baseline and `009-aligned-alloc-3` from libc's baseline, with witnesses replacing those controls. Carry those incoming, explained removals and its fork-drift pin; do not restore stale rows or call the inherited removals an outcome-protocol verdict movement. Any additional movement stops integration. |

The changed-path intersection is five files against item-G mainline and eleven
against quotation. Besides the anticipated sites, it includes `CONTRACT.md`,
`CerbLocation.lean` (guard documentation), `CLAUDE.md` (both existing practice
descriptions), the copy manifest, Lake registration and the runtime witness
script. Incoming allocator/FuelExemplar proof changes require checks even though
they do not textually conflict. README/SUPPORTED, quotation tests and its native
instrument boundary must survive the rebase unchanged except for explicitly
required stop-interface compatibility.

At dispatch, preserve this pending record before the rebase, resolve the actual
landing tip, and use linear history. After focused integration checks and proof
gates, run Tier A, then the complete `release.py --mode full` selection on the
final source under `scripts/capped`. The per-command tripwire applies; total
sweep time does not trigger it. Treat old B7 as unrun. Quote the new complete
result, recheck consumer heads/capture demonstrations on that tree, remove the
two C refs with expected-value checks, and name those deletions in the close-out
commit message. No merge commit, push, or external-adoption claim is authorized.


## Integration and close-out — 2026-10-21

### Dispatch and resolution audit

[AGENT 2026-10-21, orchestrator direction relayed by the operator] Integrate
onto mainline `4d46906c97c7493343f9cbb7c992b8d5abb8244a` with linear history,
retaining the quotation, D10/D11 refusal, survey and landing changes. Keep the
three incoming refusal sites unmigrated with named movers; complete focused
checks, Tier A and all 43 commands of the full gate before close-out. The
per-command timing clarification in the preceding park section applies.

The old mission tip was `9d8e12d984c4bccfce04d7dd6f995c9ec609c3c4`, based
on `c55e95ee278215446afeb9a74b62b6fd4833bea2`. Before rebasing, an isolated
index captured the pending preparation record and all tracked/untracked work
in `refs/snapshots/outcome-protocol-integration-20261021`. The two C snapshot
refs were retained. The five replayed commits ended at `71bc1e4a5`, with no
merge commit. A per-file comparison of the two mission diffs, removing only
hunk coordinates and blob-index lines, printed:

```text
RESOLUTION_DIFF lean_frontend/Main.lean
RESOLUTION_DIFF scripts/LADDER.md
INCOMING_IDENTICAL frontend/model/desugaring_init.lem True
INCOMING_IDENTICAL scripts/fork_drift_manifest.txt True
INCOMING_IDENTICAL lean_frontend/TODO.md True
INCOMING_IDENTICAL lean_frontend/SUPPORTED.md True
MERGES none
```

Reproduce with `git diff --unified=0 c55e95ee2..9d8e12d98 -- <file>` against
`git diff --unified=0 4d46906c9..71bc1e4a5 -- <file>`, for the old mission's
changed-path list, excluding `index ` and `@@` lines. The Main difference is
the incoming resolved-directory helper: its three refusal paths now use the
existing library-location envelope, retaining the realpath checks, source item,
explanation and canonical quotation convention. The other Main change merely
retains the quotation flags in the help text. LADDER row 1 unions both sets of
registrations and witnesses (21 executables), with the production-reference
claim retained. CerbMem's manual conflict resolution preserves OOM → zero
alignment → invalid nonzero alignment → ordinary allocation; its mission
patch is byte-identical after hunk-coordinate removal. Incoming allocator and
FuelExemplar proof repairs survive intact.

The post-rebase compatibility changes are separate from that resolution-only
audit: five incoming quotation admission paths acquire the existing `.cli`
REFUSAL envelope, retaining their predicates, explanations, exit 2 and no-output
behavior. Missing-argument usage errors remain exit 1. No quotation semantics,
printer error, wire boundary, opaque atom, shared Lem source or pin changes.

[AGENT 2026-10-21] Keep the raw D10/D11 diagnostic bodies. The frozen schema
has no honest memory-model boundary for D10, and D11's producer is in shared
Lem outside this mission's edit scope. The protocol migration map explicitly
lists both D10 leaves and `Desugaring_init.moveTo_aux`'s union `error` as
UNMIGRATED, with **memory-model refusal metadata extension** and
**shared-desugarer refusal mapping** respectively under structural-outcome WP2.
Those entries are protocol inventory, not rows or exceptions in the execution
failure register. The generic API treats validated frames as legacy/unattributed;
`parse_stop` returns absence for the raw text. No heuristic promotes a declared
refusal's prose to INVARIANT, REFUSAL or upstream attribution.

The actual quotation landing includes tray rows 58–63. They are retained;
no new tray row is added and reserved 64 is untouched. The incoming manifest
is retained byte-for-byte, including the shared union source rows and NOTE.
The TODO survey and supported-surface description are retained. Both generated
trees are rebuilt from the existing pinned toolchain; Dune stages the runtime
inside this worktree, never into the shared opam switch.

### Inherited baseline changes

No mission baseline row differs from `4d46906c9`. The three upstream-base
retirements are carried with their original purpose and replacement witnesses:

| Retired row | Reason and retained check |
|---|---|
| coverage `mem4-020-memcpy-overlap.c MATCH` | D10 now refuses overlapping copies; its backward-copy shape is in `check_item_g_refusals.sh`. |
| libc `009-aligned-alloc-3 MATCH` | D10 refuses non-power-of-two alignment; the same invalid alignment and valid arithmetic controls are in that witness script. |
| coverage `union3-003-union-init.c MATCH` | D11 refuses a second-member designator; the union witness script carries this shape and unchanged first-member controls. |

These are incoming mainline dispositions, not newly accepted semantic movements.
The item-G witness inventory is six memcpy and three alignment refusals, nine
verdict controls and one zero-alignment crash control, with all five plants.
Touched LADDER/CONTRACT/VALIDATION summaries now match those actual calls.

### Focused validation and consumer recheck

The consumer heads were rechecked read-only: Caesium
`ea75d1f8e15e930e446dac827bc715d32bf51a5e` and SL
`68832d914227a29c37df381d3e83ad274147e24c`, both clean. Caesium advanced from
the earlier demonstration head, but `scripts/differential.py` and
`scripts/env.sh` are byte-unchanged between those heads. Its cited capture and
summary definitions retain their line positions. SL's `oomOutcome`, `liftKill`
and fuel/adequacy uses are unchanged at the previously cited locations.
No consumer file is edited and no adoption or external build is claimed.

The added Python unmigrated-text test initially omitted the backtrace separator
while expecting a separately stripped wrapper; the decoder correctly retained
that line in the legacy continuation. The test now supplies the real backtrace
shape. The corrected pure-Python run passed all 18 tests. This changes no decoder
rule and makes no attribution claim from a raw refusal string.


Both `make prelude-src lean-prelude-src` and the worktree-local OCaml/Lean
build exited **0** under `scripts/capped`, `CERB_MEM_MAX=48G`. The build
finished with `Build completed successfully (406 jobs).` The focused seven
native executables passed: stop, MonadicFailstop, MemoryAccess, reconstruction,
PnviArms, allocator soundness and FuelExemplar. The actual kernel replay was:

```sh
# from lean_frontend, with CERB_MEM_MAX=48G
../scripts/capped lake env leanchecker \
  CerbStop CerbStopSites CerbDecode CerbFS CerbFloat CerbFunMapInstances \
  CerbLocation CerbMem CerbMemAccessFacts CerbStepInstances CerbTags CerbUtils \
  CerberusImpl CoreParser CerbMemDefaultFacts CerbFailProofs \
  CerbMemAllocatorProofs Unit.MemoryAccessProofs
for module in Main Unit.ReconstructLegacyTest Unit.PnviArmsTest \
    Unit.MonadicFailstop Unit.FuelExemplar Unit.StopTest Unit.AllocatorSoundnessTest; do
  ../scripts/capped lake env leanchecker "$module" || exit "$?"
done
```

**Exit 0 for the shared invocation and for each of the seven separate
executable-module invocations** (25 modules total); no replay diagnostics.
The separate environments avoid executable `main` collisions. This includes
the incoming allocator/FuelExemplar proof repairs as well as C's proof set.
A supplementary `#print axioms` probe checked all 55 public theorems in
`CerbMemAccessFacts`, `CerbMemDefaultFacts`, `Unit.MemoryAccessProofs`,
`Unit.ReconstructLegacyTest`, `CerbMemAllocatorProofs` and
`CerbStopSites.appendText`, plus a separate FuelExemplar probe. Exact printed
name sets and complete wrapped axiom lists were checked. Both probes exited 0;
all cones are empty or subsets of the standard three. Representative output:

```text
'CerbMem.loadM_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
'MemoryAccessProofs.load_erasure' depends on axioms: [propext, Classical.choice, Quot.sound]
'ReconstructLegacyTest.historical_linear_recovers' depends on axioms: [propext, Classical.choice, Quot.sound]
'ReconstructLegacyTest.historical_indexed_recovers' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.allocator_active_sound' depends on axioms: [propext, Classical.choice, Quot.sound]
'FuelExemplar.allocator_errno' depends on axioms: [propext, Classical.choice, Quot.sound]
'FuelExemplar.exemplar_certified_shipped_forall' depends on axioms: [propext, Classical.choice, Quot.sound]
```

No census entry was removed. No proof statement was weakened at integration.
The provider retains its registered opaque/extern runtime boundary; these
checks do not prove native abort or shared-origin attribution. Existing
compiler deprecation warnings in generated/dependency and inherited source
remain visible; this integration added no suppression.

The SL scratch probe described in E.3 was reconstructed from the current
consumer definitions and compiled with an explicit scratch root. Compile and
`lake env leanchecker OutcomeSlProbe` each exited **0**, with the same three
verbatim empty-axiom results as E.3. The generated `liftAction_lemFuel` still
preserves Error0's location/string and lifts Other through the supplied error
map (`Nondeterminism.lean:535–540`); `oomKill` remains at `CerbMem.lean:2492`.

Focused codec and policy commands, each under the cap, exited 0:

```text
Ran 21 tests in 2.473s

OK
STOP POLICY: 40 invariant/oracle pairs RED in both classifiers; ordinary/OOM/legacy controls passed
```

The first command was `python3 scripts/test_stops.py --lean-bin
lean_frontend/.lake/build/bin/stop-test`; the second was
`python3 scripts/test_observation_lanes.py --stop-policy-only`. Native outputs
were decoded independently by Python, including the frozen schema negatives.


The real immaculate entry-point plants (`--lane immaculate --plant crash-model
--plant crash-invariant --plant crash-legacy`) passed **3/3**, exit 0. Runtime
resolution (`check_runtime_resolution.sh --selftest`) passed **23 witnesses**,
including the relative-runtime classification/execution controls and served
UB-location divergence pin. Item G (`check_item_g_refusals.sh --selftest`) passed
**19 cases and five plants**; union initializers
(`check_union_init_refusals.sh --selftest`) passed **27 cases and five plants**.
Both preserved the existing raw diagnostic text, oracle 125 / Lean 134, and
all unchanged controls. No newly observed semantic verdict movement.

The rebuilt register gate exited **0**, without any register or gate edit:

```text
check_failure_reach: instrument built + census taken in 7 s (FAILURE_REACH rows 26754, FAILURE_RANGE rows 11779; counts: {"generated:monadic_ascribed":264,"generated:pure_or_unresolved":545,"handwritten:monadic_ascribed":3,"handwritten:pure_or_unresolved":123})
check_failure_reach: OK (240 pure failure sites = the 240 register rows exactly (238 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
```

All 112 sealed destinations in C's migration TSV were matched to the new
census by full register key and seal. The only destination line shift is
Main's unresolved pure guard, 71 → 72 (incoming import); that column is
updated. Old columns retain C's provenance. All destination seals, positions
and reviewed reach classes are unchanged, so no reseal is necessary.

The additional D10 leaves are measured at `CerbMem.allocator:2581` and
`CerbMem.memcpyM:3694`, both in the census's `monadic_ascribed` bucket and
execution closure. As noted in preparation, allocator's nested String leaf
inherits that lexical bucket from its `memM` declaration; this is not a type
proof. The D11 shared source is `desugaring_init.lem:395`, generated as
`Desugaring_init.lean:658`, owner `moveTo_aux`, a state-to-`exceptM` ascription.
Its census bucket is also `monadic_ascribed`; both dependency bits are false.
`moveTo_aux` is a generated `partial def` (`:559`), so these kernel-closure
bits are not a compiled call graph or an unreachability claim (the instrument
explicitly states this limitation). The real consumer capture below executes
that refusal. No pure register row, preamble exception or class heuristic is
added for any of the three sites.

The refreshed Caesium demonstration passed **36 captures**, exit **0**:
28 actual runner captures (including nine quotation refusal cases, two retained
usage errors and the three incoming raw refusals), plus eight labelled transport
fixtures. All five quotation admission paths emit the expected CLI boundary/item,
exit 2 with empty stdout, and publish no output. Usage errors still exit 1 and
are unrecognized diagnostics, without fabricated stop attribution. Selected
verbatim results:

```text
mixed-first: exit=1 stops=1 fuel=0 legacy=0 problems=0
mixed-exhaustive: exit=134 stops=1 fuel=0 legacy=0 problems=0
driver-union-refusal: exit=134 stops=0 fuel=0 legacy=1 problems=0
driver-alignment-refusal: exit=134 stops=0 fuel=0 legacy=1 problems=0
driver-overlap-refusal: exit=134 stops=0 fuel=0 legacy=1 problems=0
fixture-mixed-emitted: exit=0 stops=3 fuel=0 legacy=0 problems=0
CONSUMER DEMO: 36 captures passed; emitted records only; no external adoption
```

The mixed exhaustive run's stdout is asserted empty, with **zero emitted
ModelFailures**, while the first-mode run emits exactly one. This is loss
before emission, not decoder loss. Every raw D10/D11 payload is also passed to
`parse_stop`, which returns absence; the validated frame yields one legacy
panic, no INVARIANT/REFUSAL object, no guessed upstream origin. The mixed emitted
fixture retains all three causes and execution indices. No consumer adoption
is claimed.

### Release gates on the integrated source

The ladder parser reports **19 Tier A commands and 43 full commands**.
At the pre-gate load check, `uptime` reported:

```text
 22:34:42 up 12 days, 22:48,  ? user,  load average: 6.39, 3.57, 2.26
```

The gates ran one at a time, with `CERB_MEM_MAX=48G`, `TMPDIR` under this worktree's
`.tmp`, and the established local toolchain environment. No overrides or
subset selection. Both commands below use `scripts/capped`; the full command's
normal per-lane timeout remains 3600 seconds. The earlier aggregate timing
interruption remains an incomplete historical run; it supplies no pass for B7.


### Completed close-out — 2026-10-22

[AGENT 2026-10-22] D/E is complete as a provider candidate for the fresh
pre-merge review. No merge, push, consumer re-pin or external adoption has
occurred. The protocol's stated limits and named structural-outcome mover
remain; a green release sweep does not prove upstream attribution or recover
stops lost before emission.

After loading the documented local toolchain environment, the executed gates
were (from the repository root):

```sh
export CERB_MEM_MAX=48G TMPDIR="$PWD/.tmp" LEAN_ABORT_ON_PANIC=1
scripts/capped python3 scripts/release.py --mode fast \
  --out .tmp/outcome-protocol-integration/tier-a
scripts/capped python3 scripts/release.py --mode full \
  --out .tmp/outcome-protocol-integration/tier-full
```

Each process exited **0**. Tier A ran on 2026-10-21 from 22:37:43 to 23:04:41
UTC. Immediately before the full sweep, `uptime` reported:

```text
 23:05:51 up 12 days, 23:19,  ? user,  load average: 2.98, 5.05, 6.24
```

The full sweep ran from 2026-10-21 23:05:51 to 2026-10-22 01:16:43 UTC
(2 h 10 m 51 s). Its longest individual command was B9, **2451.014 seconds**;
no ladder command crossed the one-hour tripwire clarified in the park section.
Only one of this agent's heavy commands ran at a time. Neither gate used a
subset or an override. Both reports have `artifact_issues: []`,
`source_unchanged: true`, `selection_complete: true`; all selected commands
have exit status 0. Verbatim summaries:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

```text
full: passed; 43/43 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The release-certification line is the runner's separate reporting/adoption/audit
status, not a failed selected command. This record supplies the provider
report; external adoption is not claimed and the independent pre-merge review
is still outstanding. The earlier 31/42 run and its unrun B7 remain historical
incomplete evidence, not inputs to these pass counts.

The full gate's A1 ran the retained axiom census without removing any entry.
Verbatim output:

```text
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (227 files: 0 axioms, boundary-opaque population = the 9 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (441 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 19 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 55 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: mem-scale S1 leg OK (37 C1/C3 + PNVI-S2 wrapper equality + CerbMemDefaultFacts bridge + CerbMemAccessFacts erasure theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

The 25-module replay and supplementary theorem probes above preceded these
gates and all exited 0. B13 additionally elaborated and compared both libc and
linked quotations, checked the aliases/refusals, and replayed both generated
literal modules. Selected verbatim B13 output:

```text
Libc-kernel-replay: exit 0, 1.85s
LibcLiteral leanchecker: 1.80 seconds; 825032 KB peak RSS; exit 0
Linked-kernel-replay: exit 0, 1.84s
LinkedLiteral leanchecker: 1.80 seconds; 824804 KB peak RSS; exit 0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Total: 1 passed, 0 failed
```

B9 completed `observation lane plants: 95/95 passed`, including the structured
upstream crash, INVARIANT and envelope-less legacy plants. B7 was freshly run
to completion (1533.6 seconds), with this verbatim summary:

```text
SUMMARY: total=2030 compared=1934 agree=1918 agree_nd=0 triaged=16 disagree=0 o2_agree=197 skip_gcc_compile=4 skip_gcc_stdout=2 skip_lean_crash=18 skip_lean_fail=14 skip_lean_timeout=11 skip_ub=47 triaged_addr=14 triaged_float=1 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

Those skip counts, including 11 Lean timeouts, remain explicit exclusions;
they are not semantic agreements. B10.1 independently compared 997 rows:
950 semantic agreements, 37 matching failures, eight reviewed differences and
two interface agreements. B12 compared all four libxml2 character-validation
slices with semantic agreement. No new semantic verdict movement or baseline
edit was accepted.

The final audit preserves the incoming shared union source, fork-drift
manifest, survey TODO, SUPPORTED text and tray index, as well as every
baseline. No `.lem`, dependency, Lem pin or register-gate exception was
introduced. The rebase-only patch comparison remains the one recorded above;
post-rebase quotation admission compatibility edits are separately described
and were included in both gates. After the full runner finished, only these
close-out descriptions and the two handoff statuses changed. `git diff --check`
passed.

The two C preservation refs are removed at close-out, with their exact names
also recorded in the close-out commit message:

- `refs/snapshots/outcome-protocol-C-20261020-1792521155`
- `refs/snapshots/outcome-protocol-C-resume-20261020-1792522883`

Their producer work is in the linear history. The additional pre-rebase
integration snapshot is removed after this close-out is committed. This
agent's reconstructible integration scratch under
`.tmp/outcome-protocol-integration/` is then deleted; commands and conclusions
remain here. The worktree and built artifacts stay available for the fresh
reviewer.


## Pre-merge review corrections — 2026-10-22

[AGENT 2026-10-22, orchestrator disposition relayed by the operator] Apply the
three fixes from the [fresh pre-merge review](2026-10-22_outcome-protocol-premerge-review.md)
and supply the missing checkpoint-C commit body in this record. Keep the gated
history intact, add one fix commit above `fb5b4d4a1`, then validate that commit.
The unaffected full-battery rows retain the base candidate's evidence; the
changed classifier instruments require the focused re-gate below.

| Finding | Disposition |
|---|---|
| P2-1 | Both Lean-side classifiers now make non-empty `decode_stop.problems` INVALID after their retained resource early returns, independently of `decoded.stops`. A decoded INVARIANT still wins first. Malformed reserved panic, malformed reserved ModelFailure and envelope-less ModelFailure each have RED plants against five oracle classes. The immaculate hook emits the protocol reason when it selects INVALID. The policy matrix also keeps resource-precedence, ordinary-output and legacy-panic controls. Design §4.2 states the caller rule. |
| P3-1 | `test_pnvi.sh --selftest` has a `lean-invariant` stub on `litmus/provenance_basic_using_uintptr_t_global_yx`, a pinned oracle-crash row. It uses the real lane entry point and requires nonzero exit with that row named as INVALID and the INVARIANT site in the explanation. Other rows use the real engine. |
| P3-2 | `intfrombyte` now cites 2779–2780 and `stepSpawnEquality` 110–127. The pinned-source comparison reproduced 74/76 exact ranges on the reviewed candidate and 76/76 after narrowing, modulo indentation. C.6 corrects the original overclaim; the excerpt text and classification do not change. |
| P3-3 | C.9 supplies the absent body for `5f8fd8d7e`, including its actual verification. No gated commit was amended. |

The review file is copied unchanged into `docs/` in this fix commit. Its probes
remain review scratch, not committed evidence dumps. No decoder schema,
producer semantics, baseline, resource convention or other lane is changed.
The two citation bounds change diagnostic metadata and their `by decide`
refinements; they require a refreshed generated copy/build. Public theorem
statements, reference contracts and census entries are retained.

[AGENT 2026-10-22] The queued orchestrator battery uses this same worktree at
`fb5b4d4a1`. Prepare the fix under ignored `.tmp/` while it runs; do not change
tracked source, HEAD or generated build inputs until its log records completion.
Start the fix's heavy checks only after `release rc=` is present and `uptime`
shows load below 6. Run one heavy command at a time.

The queued battery completed at 06:39:15 UTC on 2026-10-22 with `release rc=0`,
43/43 commands, unchanged source and complete selection. The worktree remained
clean at `fb5b4d4a1` until then. At application, `uptime` reported a one-minute
load of 1.48; each prepared source hash matched the reviewed tree. The review
copy is byte-identical to the supplied file.

Before the fix commit, the focused policy command exited 0 with this output:

```text
STOP POLICY: 40 invariant/oracle and 15 malformed/oracle pairs RED in both classifiers; ordinary/resource/legacy controls passed
```

The existing Python codec suite (18 tests) and observation suite (25 tests)
also exited 0. These focused results do not replace the post-commit re-gate.

`release.py --list` identifies row 14 as **A14.1** (`test_pnvi.sh --selftest`)
and **A14.2** (`test_pnvi.sh`), so `--lane A14` selects both. The affected
full-mode selection is four commands, not a new full 43-command sweep.
`test_immaculate.sh` has no `--selftest` option; its entry-point self-test is
`test_observation_lanes.py --lane immaculate` (also included in B9).

After the commit, from the prepared repository root, with all commands under
`scripts/capped`, `CERB_MEM_MAX=48G`, and `TMPDIR` under this worktree's `.tmp`:

```sh
python3 scripts/release.py --mode fast \
  --out .tmp/outcome-protocol-review-fix/tier-a
python3 scripts/release.py --mode full --lane A14 --lane B5 --lane B9 \
  --out .tmp/outcome-protocol-review-fix/affected
scripts/test_pnvi.sh --selftest
python3 scripts/test_observation_lanes.py --lane immaculate \
  --out .tmp/outcome-protocol-review-fix/immaculate-selftest
```

The cheap policy matrix and codec tests precede the gates. After Tier A rebuilds
the changed metadata module, replay `CerbStopSites` with capped
`lake env leanchecker` from `lean_frontend`; Tier A retains the full axiom census.
The fix commit is the object validated, so its record specifies these commands
without claiming their later results. The completion report must quote both
runner summaries and the self-test/replay exits. A subset's
`Complete tier selection: False` is expected and must not be described as a
complete full-mode pass. Stop on any real semantic verdict movement; do not
re-pin a baseline to accept it. No merge, push or external adoption.
