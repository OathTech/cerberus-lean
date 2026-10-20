# Outcome protocol — checkpoint record

Author: [AGENT 2026-10-20]. Checkpoint A against
`c55e95ee278215446afeb9a74b62b6fd4833bea2`, branch `arc/outcome-protocol`.
Charter: revision 5 of `2026-10-18_codex-charter-outcome-protocol-s1-s2.md`.
Design: revision 3 of `2026-10-20_outcome-protocol-design-v2.md`.

## A — baseline, inventory and fence

**Status: PARKED before B, under charter §3.** A records the baseline,
measurements, current contracts and proposed per-site dispositions below. The
charter/design Q7 conflict needs a ruling; the newly identified non-mirror guards
and inventory/fence omissions need an explicit disposition. No implementation
has begun. [AGENT 2026-10-20] Do not start B on an inferred resolution or turn
an unconfirmed upstream attribution into a new production envelope.

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
