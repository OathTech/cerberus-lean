# Typed failure outcomes — design note R0 (DRAFT for the operator's scope review, 2026-09-05)

Status: DRAFT R0, read-only design pass. Nothing implemented; nothing
merged; nothing pushed. Branch `docs/typed-failure-design` (worktree
`worktrees/cerberus-lean-docs/typed-failure-design`) = mainline
`mdd/cerberus-lean` @ `928aa1e76`. The generated tree was read from the
primary checkout `cerberus-lean/lean_frontend/generated/` at the SAME
commit (`git -C cerberus-lean rev-parse --short HEAD` → `928aa1e76`,
branch `mdd/cerberus-lean`); lem-lean at `mdd/lean-backend` (`deps/
lem-pinned` = the Lake pin, per the container CLAUDE.md). Author: [AGENT]
(design worker). Every count below is DERIVED from the grep commands
quoted in §1.0 unless marked verbatim; every "unreachable" claim names
the invariant it rests on; every decision is the operator's (§6).

## 0. The question and the ruling

**The defect.** In-process, a `panic!` or `LemLib.failwithI` site
DENOTES a value of its return type — `panic!` the `Inhabited` default
(kernel-transparent: `= default` by `rfl`, as the consumer measured,
refined-cerberus `cerberus-heaplang/ARCHITECTURE.md:454-456`), `failwithI`
an `opaque` inhabitant (`lem-lean/lean-lib/LemLib.lean:176-177`, no
equations). A theorem about `drive` on an input that reaches such a site
is therefore about that value, not about the oracle's crash. The binary
is guarded (`Main.lean:1094-1110` refuses to start without
`LEAN_ABORT_ON_PANIC`; Z2-FL-03), but the consumer calls `drive`
in-process and never sees the flag.

**The ruling** ([USER 2026-09-03], `docs/2026-09-03_typed-failure-outcomes-ruling.md`, verbatim):

> "Re the judgement, yes, I think we should structure this so that
> *consumers* of the semantics get the property we care about, i.e
> conformance to the ocaml oracle. This means we should fail-closed into
> the correct behavior. Understood re the design change, we should
> schedule this (can it wait for the current set of fixes to land?)"

Rulings in force that bound the design:

- **Referent = the logical semantics** (`docs/2026-09-03_logical-semantics-referent-ruling.md`): KIND-1 fail-stops (a `failwith`/`assert`/lem `error` the MODEL writes deliberately) are mirrored; KIND-2 OCaml-execution artifacts (`Z.Overflow`, `Division_by_zero` from a missing guard, host-int conversions, polymorphic compare raising) are not — Lean implements the logical meaning, the case is logged and pinned.
- **Interim rule Z1–Z3** (ruling doc): one-sided oracle crashes are mirrored as `panic!` carrying the OCaml text (Q4), never as a memory-monad `Error` — "a typed `Error` verdict is a different failure CLASS from a tool crash (charter §1.2(a)), so the correct typed outcome does not exist yet; inventing it per site is the design pass."
- **Consumer requirement (A)/(B)/(C)** (refined-cerberus `docs/2026-09-04_review-of-fuel-parameter-design.md` §2): on the execution path an exhaustion must be ABSORBING (a typed outcome the monad's `bind` propagates), ABSENT, or unreachable — "an opaque-default exhaustion on the execution path is a silent fail-open under the project's own rule". The same sentence applies verbatim to every failure site; the fuel arc made it mechanical for fuel'd workers (`scripts/check_fuel_forms.sh`).
- **Brief constraints** ([USER 2026-09-04], relayed): "we don't change the lem structure for ocaml" — Lean-only declares are fine, `.lem` bodies and the OCaml output are not touched; "stick to our brief" — no mirror model.
- **The template**: the fuel arc's Option C — an `opaque` atom with a value (`CerbFuel.fuelExhaustedLoc`, `CerbFuel.lean:54`), the kill `Error0 fuelExhaustedLoc msg` in the ND monad, `Result (Error fuelExhaustedLoc msg, st)` in the pexpr evaluator's state-exception monad, runner leaves that return the same kill (`CerbND.lean:98, :117-132`); soundness by parametricity in the opaque, no distinctness lemma (`docs/2026-09-02_fuel-arc-design.md` §1.3, options table §2).

**What the pass must deliver** (the brief): every failure site on the
execution path becomes (i) a typed ABSORBING outcome the enclosing monad
propagates, or (ii) is proven unreachable (gate-checked), or (iii) — the
pure case — gets a design that changes neither `.lem` bodies nor the
OCaml output and builds no mirror model. Kind-1 sites must become (i) or
(ii); feature refusals (class (c)) are the right outcome and are typed
as a kill; instruments stay instruments.

## 1. The census

### 1.0 Method and the grep commands (verbatim)

Hand-written seams (this worktree, `lean_frontend/`):

```
grep -n "panic!\|failwithI\|refusal" lean_frontend/*.lean
grep -c "panic!" lean_frontend/*.lean        # 130 lines incl. comments
grep -c "failwithI" lean_frontend/*.lean     # 19 lines incl. comments
```

Code arms were separated from comment/string lines by reading each
match (§1.1 lists every code arm by line). Enclosing definitions and
their return types were located with an `awk` pass that tracks the last
`def`/`instance` header before each match (the same method the
reasoning-artifact audit used).

Generated tree (primary checkout, same commit; the worktree has no
`generated/`):

```
cd cerberus-lean/lean_frontend/generated
grep -c failwithI *.lean                                   # lines, per module
cat *.lean | grep -o failwithI | wc -l                     # 1536 occurrences
cat *.lean | grep -o 'failwithI "Lean backend: comparison residual' | wc -l   # 714
cat *.lean | grep -o -i 'failwithI *"[^"]*incomplete[^"]*"' | wc -l           # 39
grep -o 'failwithI *\(([^)]*)\|"[^"]*"\) *: *[A-Za-z_.]*' <module>.lean       # ascribed type head per site
```

Generated definitions are one line each, so LINE counts under-count;
every generated figure below is an OCCURRENCE count unless it says
"lines". The exec cone is taken at MODULE level from the totality gate's
list (`scripts/check_exec_totality.sh:64-68`, `EXEC_MODULES`: Core_run,
Core_reduction, Core_eval, Driver, Core_run_aux, Core_aux, Defacto_memory,
Defacto_memory_aux, Ctype_aux, Nondeterminism, Mem_aux, Utils, Annot,
Ctype, Core, State_exception_undefined, State, State_exception,
Translation_aux, Cerb_attributes, Formatted, Monadic_parsing) plus the
modules those import that carry failure sites. The KERNEL constant
closure of `drive` — the fuel-forms gate's definition of reachability
(C2 record §7) — is finer than this and is what the gate of §3 will
compute; it could not be run in this plain worktree (no build), so
reach below is module-level and labelled as such.

### 1.1 Hand-written seams — every code arm, by line

**Derived totals: 118 `panic!` code arms + 10 `failwithI` code arms =
128 hand-written failure sites** (130 `panic!` lines minus 12
comment/string mentions: `CerbMem.lean:1239, :2971`; `CerbFS.lean:26,
:84, :86` + one further header line; `CerbFloat.lean:89, :168, :299`;
`Main.lean:1096, :1109`; `CerbND.lean:55`; 19 `failwithI` lines minus 9
comment mentions).

**1.1.a Monadic — inside `memM` (= `ndM a String mem_error (mem_constraint IntegerValue) MemState`, `CerbMem.lean:1977`); absorbing element `kill (Error0 loc msg)` = `ND (fun st => (NDkilled (Error0 …), st))`, propagated by `nd_bind`, lifted into the driver by `liftMem`/`liftND` with `Error0 loc str` passed through unchanged (`generated/Nondeterminism.lean` liftND: `| Error0 loc1 str => Error0 loc1 str`; `generated/Driver.lean:255`).** 7 arms:

| site | OCaml | kind | note |
|---|---|---|---|
| `CerbMem.lean:2075` `allocator` align = 0 | `quomod` `Division_by_zero` impl_mem.ml:1252 | 2 | PENDING-DECISION refusal (Z2 §10.1); the pass types whatever Z3/Z4 leave |
| `:2105` `allocateObject` `req_addr_opt = some _` | `failwith "TODO: cerb::with_address() …"` :1293-1295 | 1 | fork-only attribute |
| `:2198` `killM` static kill of a dead allocation | `failwith "Concrete: FREE was called on a dead allocation"` :1531-1532 | 1 | reachable only via tray-19 / `with_address` (in-code note) |
| `:2686` `effArrayShiftPtrval` PVfunction | `failwith` :2252-2253 | 1 | |
| `:2756` `memcmpM` non-integer byte | `assert false` :2658-2659 | 1 | |
| `:2945` `vaList` index ≠ 0 | `assert (n = 0)` :2760 | 1 | |
| `:2964` `callIntrinsic` | `assert false (* CHERI only *)` :2190-2191 | refusal (c) | CHERI |

(`:2971` is a comment.) These 7 are the ONLY hand-written sites whose
enclosing definition is monadic.

**1.1.b Pure — the enclosing definition has no monad.** 111 `panic!`
arms (75 outside `CerbFS`, 36 in it — §1.1.c) + 10 `failwithI` arms. Grouped by the invariant that would make
each unreachable:

*(P-layout) The layout oracle — `Nat`-valued, tag-lookup fuel'd workers
(the fuel gate's pending rows `sizeofCtype`/`alignofCtype`/`offsetsof`):*
`CerbMem.lean:411` (unknown tag), `:439/:440/:442` (Void / incomplete
array / function type — impl_mem.ml:134-135 `assert false`), `:446/:450`
(implementation incomplete), `:474` (Union tag not a UnionDef),
`:492/:494/:498/:502/:517/:527` (alignof mirror arms). Callers: every
`memM` allocation/load/store and `Core_eval`'s `PEsizeof`. Invariant:
Core well-typedness (`sizeof`/`alignof` applied to a complete object type
whose tags are defined) + a complete `implementation` (the `none` arms:
`CerberusImpl.sizeof_ity`/`precision_ity` total on the LP64 record —
`CerberusImpl.lean:169-181` is itself a site, see P-impl).

*(P-bytes) Byte/value conversions — memory-model internal invariants:*
`:581` `intToBytes` range/width (`assert false` :1105-1109), `:596/:597`
`bytesToInt` `[]`/`> 16` (:742-745), `:637` `splitBytesProv []`,
`:683/:695/:806/:815` `memValueToBytes(_append)` impl-incomplete arms,
`:1029/:1166` `reconstructValue(_indexed)` unknown function pointer,
`:1098/:1108/:1112/:1205/:1213/:1217` reconstruct-union arms (empty
UnionDef / member not in UnionDef / tag not a UnionDef), `:1281`
`typeofMval` `MVarray []`, `:1744/:1752` `bytefromint`/`intfrombyte` range
(:2776, :2780 asserts). Invariant: the consumer's own acceptance goal 3
(global memory well-formedness: byte lists have `sizeof` length,
function-pointer table consistency, union member records) — refined-cerberus
`docs/DECISIONS.md` "THE DEMO'S ACCEPTANCE GOALS" (3).

*(P-ptr) Pointer-value case analysis:* `:273/:274` `combineProv`
Prov_symbolic, `:1361` `casePtrval` (impl_mem.ml:1814 `failwith
"case_ptrval"`; REACHABLE from C — `device_funptr_call.c`, Z2-M-02),
`:1533` `offsetofIval` invalid member, `:1706/:1708/:1709`
`arrayShiftPtrval` Prov_symbolic / null / PVfunction (:2203-2221; the
null arm is `"TODO(pure shift a null pointer should be undefined
behaviour)"` — the model's own note that the logical meaning is UB),
`:1732` `memberShiftPtrval` PVfunction (:2239-2240). Invariant: for
Prov_symbolic — the symbolic mode is never entered (matched mode; a
config fact, see P-cfg); for `casePtrval`/null-shift — NONE: these are
reachable model fail-stops on well-formed inputs (the oracle crashes).

*(P-ival) Integer-value arithmetic:* `:1395/:1423` `maxIval`/`minIval`
implementation incomplete, `:1404/:1425` Enum after `typeof_enum`
(`assert false`, unreachable because `typeof_enum` never returns an Enum
— the arm is dead by the registry's construction, not by the kernel),
`:1436` `concurReadIval` (`failwith "TODO: concurRead_ival"` :2361-2362;
reachable only under concurrency — P-cfg), `:1517` `opIval IntExp`
negative exponent (KIND 2; declared unreachable behind the shift guards,
Z2 §2.10).

*(P-cfg) Feature refusals, class (c), pure-typed:* CHERI intrinsics
`:1963/:1965/:1967/:1969/:1971/:1973` (`deriveCap`, `capAssignValue`,
`nullCap`, `ptrTIntValue`, `cheriPointerHashPrintf`,
`getIntrinsicTypeSpec`; impl_mem.ml:2175-2191 `assert false (* CHERI
only *)`). Invariant: `CerbGlobal.is_CHERI () = false`. Today that is an
`opaque` over a process ref (`CerbGlobal.lean:151-152`), so the deadness
is NOT kernel-visible; the reasoning-artifact audit's item 1 (2.A Step 1:
eleven `CerbGlobal` opaques → `def`s of the default configuration) makes
every such arm `if false then …` — kernel-dead by `simp`. Same class:
`concurReadIval` (`using_concurrency`), Prov_symbolic arms (execution
mode).

*(P-impl) The implementation record:* `CerberusImpl.lean:142` `aux_ibty`
width ∉ {8,16,32,64} (`Option.get None` on the model's own alias table —
"ambiguous" kind, Z2 §10.2), `:179/:181` `sizeof_ity` un-normalised arms
(`assert false` ocaml_implementation.ml:188-200; unreachable after
`normalise_integerType`, a structural fact about `sizeof_ity`'s own body
— provable), `:69` `typeof_enum_impl` unregistered tag (INSIDE the
`unsafe` implementation of the census-pinned `opaque typeof_enum`,
`CerberusImpl.lean:55-74`: the panic is hidden behind an opaque the kernel
closure cannot see through — the reasoning-artifact audit's MAJOR 2.C;
its remedy, the enum table as a value, removes the arm).

*(P-float) `CerbFloat.lean:183` `of_string` unparsable (Cerb_floating
`Failure`), `:307` `truncToInt` nan/inf (`Z.of_float` `Z.Overflow` —
KIND 2 by the referent ruling; the Z2-FL-03 witness `(int)NaN`; REACHABLE
from C; ISO 6.3.1.4#1 makes the conversion UB, which is a monadic
outcome the pure `ivfromfloat` interface of `mem.lem` cannot express —
see §2.3).*

*(P-decode) `CerbDecode.lean:41` empty constant (KIND 2, refusal, fork-only
reach; Z2 §10.3), `:121/:127/:132/:144/:146/:151` `decode_character_constant`
invalid constants (decode.ml:162-200 `failwith`; kind 1; reachable only
from the desugarer — front-end, off the drive cone: `decode_*` is called
by `Cabs_to_ail`).*

*(P-builtin) `CerbUtils.lean:136` `ctz` zero (ocaml_gcc_builtins.ml:5
`assert`), `:146/:155` `bswap16/32` out of range (:15, :22 asserts), `:172`
`bswap64` `Z.to_int64` overflow (:30 — KIND 2 shape; recorded as
mirrored). Reachable from C via `__builtin_ctz(0)` (UB in GCC's
documentation; the model's `assert` is its fail-stop).*

*(P-loc) `CerbLocation.lean:133` `outerBbox []` (cerb_location.ml:109-110
`assert false`), `:239` `simpleLocation` `.regions []` (`hd` — `Loc_regions
[]` is refused at construction by `CabsImport.jsonToLoc`, Z2-L-02: the
invariant is "no `Loc.regions []` is ever built", a constructor
discipline, not a theorem).*

*(P-cmp) The hand-written comparison residuals — `Bool`/`Ordering`/
`LemOrdering`-valued instance methods:* `CerbStepInstances.lean:155-169`
(8 `failwithI` arms of `beqCoreStep2`, same-constructor closure-carrying
steps), `:204` (`compareCoreStep2` same-tag non-comparable),
`CerbFunMapInstances.lean:84` (`SetType generic_fun_map_decl`
same-constructor). They mirror OCaml's polymorphic compare RAISING on
closures — an OCaml-runtime behaviour with no logical meaning in lem (the
referent ruling's kind 2 in shape; the correct Lean answer is a refusal,
not a value). Invariant: the driver compares `core_step2` values only at
nullary/`Step_error2` shapes (`Driver.can_advance`, the `==` uses the
header of `CerbStepInstances.lean:66-79` enumerates: Driver is the only
importer); `CerbFunMapInstances` header: "no call site can reach this
(phantom instance requirement)".

*(P-instr) Instruments and by-construction guards:* `CoreParser.lean:2413`
`scanStep` fuel = input length + 1 (a parser tripwire, not a model site),
`Main.lean:69` `loadCoreImpl` (unreachable: `pImplConstant` already
validated the lexeme at parse time — `CoreParser.pDefDecl`/`pFunDecl`;
the in-code note), `CerbTags.lean:34` `tagDefsUnreachable` (a reader-lifting
tripwire: "applied tagDefs () site survived reader lifting").

**1.1.c Refusals (class (c)) — `CerbFS`.** 36 `panic!` arms in the 25
`fs_*` entry points (`CerbFS.lean:229-519`; op-by-op table in the header
`:23-83`, copied in the Z1 record §6). Enclosing type `FsState × Sum FsError _`
— PURE; the driver's `drive_fs_step` wraps each result with `return3`
into `ndM` (`generated/Driver.lean:301-304`). The header's deliberate
choice (`:84-90`): "`panic!`, not an FsError (an FsError becomes errno +
−1 through driver.lem store_error and the C program can absorb it —
still a wrong answer)". So these are refusals whose CORRECT typed outcome
is a kill at the `drive_fs_step` frame, one call above the pure site —
which no in-brief mechanism reaches: the frame is generated from
`driver.lem` and the pure `fs_*` signatures are `fs.lem`'s. Until P1
(§2.3) they are P5-opaque REFUSAL-c register rows, not typed kills.

### 1.2 Generated tree — census by class

**Whole tree (derived): 1536 `failwithI` occurrences on 1029 lines in 57
modules; 714 are the backend's comparison residuals; 39 are
incomplete-pattern arms; 783 are explicit lem `error`/`failwith`/library
failure sites.** `panic!` occurs in NO generated module (the 11 files
`grep -c panic!` reports are byte-identical copies of the hand-written
seams staged into `generated/`). `fromJustI` (`LemLib.lean:226-232`, a
real `def` whose `none` leaf is `failwithI`) occurs 13 times in the
exec-cone modules (Core_eval 6, Driver 1, Core_aux 2, Ctype_aux 2,
Defacto_memory 2).

**1.2.a Per-module occurrence table (exec-cone modules and the failure-carrying modules they import).** Columns: total / comparison-residual / non-residual.

| module | total | residual | non-residual | note |
|---|---|---|---|---|
| Core_run | 93 | 20 | 73 | `core_thread_step2 : … → List core_step2` is PURE (`Core_run.lean:424`, return type `List (core_step)`) — its 46 `core_step2`-ascribed + 11 `List`-ascribed sites are pure values inside a pure function called from the driver's ND frame |
| Core_reduction | 90 | 40 | 50 | 15 sites ascribed `core_run_state → exceptM …` (the `stExceptM` unfolding, `State_exception.lean:40-41`) = MONADIC; 10 `action_step`, 4 `one_step`, 6 `core_step2` = pure data |
| Core_eval | 23 | 0 | 23 | 10 ascribed `exceptM` (the evaluator's `exceptM (t0 …) core_run_cause`) = MONADIC; 4 `IntegerValue`, rest pure |
| Driver | 27 | 0 | 27 | 16 ascribed `ndM` = MONADIC; `finalize : … → driver_result` is PURE (`Driver.lean:469`; `to_pure … | none => failwithI`, mirroring driver.lem:1477); `hack`'s zero payload `fuelExhausted Vunit` (`Driver.lean:436-440`, `hack_lemFuel_zero`) |
| Core_run_aux | 30 | 16 | 14 | 4 ascribed `exceptM (… × stack a) core_run_cause` (`pop_stack`, `pop_continuation_element`, `push_continuation_element`, `append_to_current_continuation`, `Core_run_aux.lean:292-304`): MONADIC but the value type is not `t0`, so NO `Loc` channel (see §2.2); 6 `generic_expr_` + 4 `stack` pure |
| Core_aux | 39 | 16 | 23 | all pure (`objectValueFromMemValue`, `loadedValueFromMemValue`, `valueFromMemValue`, `mk_tuple_pat/pe []`, `zeros`, `update_env`, `to_pure Eannot/Eexcluded`, `seq_rmw with_forward`) |
| Ctype_aux | 9 | 0 | 9 | pure (`get_*Def*` tag lookups, `are_compatible_aux`) |
| Nondeterminism | 42 | 36 | 6 | `log`/`mplus`/`msum []`/`pick []`/`nd_mem`/`warns_if_no_active_ex` — lem's own `error "ND2.…"` stubs (`frontend/model/nondeterminism.lem:124, :134, :140`); `msum`/`pick` ascribed `ndM` = MONADIC (3); `nd_mem`/`warns_if_no_active_ex` polymorphic `a`; `mplus`/`log` never called from Driver (0 uses — kernel-unreachable) |
| Formatted | 25 | 0 | 25 | 13 ascribed `ndM` (printf engine in the driver monad) = MONADIC; 12 pure (`showNonNegativeWithBasis`, `charFromDigit`, `load_character_array` arms) |
| Translation_aux | 31 | 10 | 21 | front-end (gate-listed for totality; not on the drive cone) |
| Utils | 6 | 0 | 6 | `fromJust`, `fromLeft/Right`, `foldl2`, `list_index_update` — library, polymorphic `a` |
| Annot / Ctype | 2 / 2 | 0 | 2 / 2 | `get_marker` duplicates; `mk_ctype_atomic` invalid inner, `ptraddr_t` CHERI |
| Core / Cerb_attributes / Monadic_parsing | 124 / 8 / 10 | all | 0 | residual instances only |
| Defacto_memory / _aux | 66 / 15 | 0 | 66 / 15 | NOT drive-reachable (C2 finding F-C2-4: `mem.lem`'s reps are `CerbMem`) |
| Mem_aux, State*, State_exception_undefined | 0 | | | |
| *imported by the above:* | | | | |
| Mem_common | 31 | 28 | 3 | `derive_intrinsic_signature` (CHERI intrinsics) |
| IntegerImpl | 51 | 10 | 41 | `min_integer_range`/`min_implementation_*` TODO arms (Wchar_t/Size_t/Ptrdiff_t/…): the `min_implementation` records are NOT the impl in use (`Implementation.integerImpl` reads `CerberusImpl`) — reach is a kernel-closure question |
| Implementation | 8 | 0 | 8 | `is_signed_or_unsigned` TODO arms, `is_compatible_with_size_t/ptrdiff_t`, `integerImpl` precision `none` |
| AilTypesAux | 21 | 0 | 21 | typing helpers; `are_compatible` IS drive-reachable (C2 F-C2-5), its `failwithI` arms (`le_integer_range` Ptraddr_t, `is_complete`, `make_composite`, …) ride along; 1 `errorM` |
| Core_linking | 13 | 0 | 13 | the `link` entry (exec entry, not `drive`); `free_*` Linux-atomic arms, `safe_map_union`, `merge_globs` |
| Builtins | 2 | 0 | 2 | `translate_errno`, `encode_memory_order NA` |
| Undefined | 9 | 8 | 1 | `stringFromUndefined_behaviour` |
| Exception / ErrorMonad / Dlist / Multiset / Bimap | 8/10/10/8/8 | all | 0 | residual only |
| Core_reduction_aux | 34 | 0 | 34 | `step_fs_proc`: 27 `fs_oper`-ascribed argument-shape arms (`failwithI "pread" : fs_oper` etc.) + `charFromMValue`/`forceIntegerFromIntegerValue` error closures |
| Cmm_csem / Cmm_op | 97 / 2 | 60 / 0 | 37 / 2 | the concurrency model; ALL 39 incomplete-pattern arms of the tree live here (`Cmm_csem` 37, `Cmm_op` 2); imported by Driver/Core_run/Core_reduction for types; `Driver.perform_action_request2` refuses at `with_concurrency` (`Driver.lean:320`) |

Derived sums: the 22 gate-listed modules carry 642 occurrences (280
residual, 362 non-residual, + 13 `fromJustI` wrappers); the 15 imported
modules 312 (150 residual, 162 non-residual).

**1.2.b Ascribed-type partition of the non-residual sites** (the 20
modules above that are on or adjacent to the drive cone, excluding
Defacto*/Cmm*/Core/Cerb_attributes/Monadic_parsing — 404 non-residual
occurrences; 330 of them carry a literal message and a parsable
ascription; the 74 others are non-literal-message sites such as
`forceIntegerFromIntegerValue errmsg` and are pure by inspection of the
samples):

- **MONADIC-ascribed: 64** — `ndM` 32 (Driver 16, Formatted 13,
  Nondeterminism 3), `exceptM` 15 (Core_eval 10, Core_run_aux 4,
  Core_linking 1), `core_run_state → exceptM …` (= `stExceptM`) 16
  (Core_reduction 15, Core_run 1), `errorM` 1 (AilTypesAux).
- **PURE-ascribed: 266 + 74 = ~340** — heads `core_step2` 52, `Bool` 36,
  `Nat` 29, `fs_oper` 27, `List` 18, `Option` 14, `Pset` 10 (Core_linking),
  `action_step` 10, `generic_expr_` 6, `MemValue` 5, polymorphic `a` 5,
  `stack` 4, `one_step` 4, `IntegerValue` 4, `Int` 3, `ctype` 3, and 14
  singletons.

**1.2.c Three structural facts the census establishes.**

1. **No generated failure site is kernel-transparent.** Every one is
   `failwithI` (opaque). The transparent-default class (`panic!`) exists
   ONLY in the hand-written seams (118 arms). Two kernel behaviours
   coexist today; the consumer documents both (`ARCHITECTURE.md:444-466`).
2. **Incomplete-pattern residue is absent from the exec cone.** The 39
   `"Incomplete Pattern at …"` arms (lem `patterns.ml:1594, :1644`,
   emitted as `failwithI` by `lean_backend.ml:3501-3523`) are all in
   `Cmm_csem`/`Cmm_op`. Every exec-cone failure site is an EXPLICIT lem
   `error`/`failwith`/`Assert_extra` call — the model's deliberate
   fail-stop, i.e. kind 1 by default — or a comparison residual.
3. **The dominant generated shape is "pure site inside a monadic
   caller".** `core_thread_step2` (pure, `List core_step2`), `step_action`
   (`action_step`), `one_step`, `finalize` (`driver_result`),
   `step_fs_proc` (`fs_oper`) hold ~150 of the ~340 pure sites; each is
   called from an ND or state-exception frame one or two calls up. The
   lem authors wrote many of them as `failwith` with the note
   `"TODO(use the error the monad)"` / `"TODO(use the core_runM)"`
   (Core_reduction: 4 such messages) — the model intended a typed cause.

### 1.3 The four groups (the brief's partition), with derived counts

| group | hand-written | generated (exec-cone + imported, non-residual) | outcome owed |
|---|---|---|---|
| **M — monadic** (`ndM`/`memM`/`stExceptUndefM`/`exceptM`-with-`t0`) | 7 (`memM`) | 64 − 5 (the 4 `exceptM`-non-`t0` stack ops + `errorM`) = 59 | (i) typed absorbing outcome |
| **M′ — monadic without a `Loc` channel** (`exceptM X core_run_cause`, X ≠ `t0`; `errorM`) | 0 | 5 | §2.2 — a decision |
| **P — pure** | 111 `panic!` − 36 CerbFS = 75, + 10 `failwithI` = 85 | ~340 | (ii)/(iii) — §2.3 |
| **C — refusals, class (c)** | 36 (CerbFS) + 7 CHERI + `concurReadIval` + `with_address` — the last 9 are already counted in M/P by type | Linux atomics / CHERI / concurrency / printf-gap arms inside P and M (≈ 60 by message: `WIP: Linux*`, `CompareExchange*`, `CHERI`, `concurrency`, `TODO: Formatted.convert, * prec`, `%lc`, `Ptraddr_t`) | typed as a kill (M), kernel-dead (P-cfg), or registered REFUSAL-c (CerbFS, until P1) |
| **I — instruments / by-construction** | 3 | 0 | stay; register |
| **R — comparison residuals** | 10 | 714 tree-wide, 280 in gate-listed modules | refusal-class; per-instance reachability (§2.4) |

## 2. Mechanisms

### 2.1 Group M — the distinguished model fail-stop outcome (recommendation: DO; the fuel arc's Option C, second atom)

**The outcome.** `lean_frontend/CerbFail.lean` (new, hand-written):

- `opaque modelFailStopLoc : CerbLocation.Loc := CerbLocation.Loc.other "model fail-stop"` — a pure census-pinned opaque WITH a value (the `CerbFuel.fuelExhaustedLoc` shape, `CerbFuel.lean:40-54`; the boundary-opaque census `check_theorem_axioms.sh` pins the population both directions, VALIDATION.md:148).
- `def failStopKill {err} (msg : String) : kill_reason err := Error0 modelFailStopLoc msg`.
- `def failStopND {…} (msg) : ndM a info err cs st := kill (failStopKill msg)` — the ND absorbing element (`Nondeterminism.lean:255-256`); `nd_bind` never runs the continuation on `NDkilled`; `liftND`/`liftMem` pass `Error0 loc str` through unchanged; the runners report it as `Killed st (Error0 modelFailStopLoc msg)`.
- `def failStopST {a bs} (msg) : stExceptUndefM a bs core_run_cause := fun st => Result (Error modelFailStopLoc msg, st)` and `def failStopExcept {a} (msg) : exceptM (t0 a) core_run_cause := Result (Error modelFailStopLoc msg)` — the evaluator-monad forms the fuel arc already uses for `full_eval_pexpr`/`eval_pexpr_aux2` (C2 record §3, verbatim `_zero` RHS `Result (Error CerbFuel.fuelExhaustedLoc …, st)`); `stExceptUndef_bind` returns the error without running the continuation; `liftCore_run` maps `Error loc str → kill (Error0 loc str)` (`generated/Driver.lean:286`).
- `def failStopMem (msg) : memM a := kill (failStopKill msg)` for the 7 hand-written `memM` sites.

The message is the OCaml text (Q4 preserved); it is REPORTING-only,
exactly as `fuelExhaustedMsg` is (`CerbFuel.lean:56-61`). Trust rests on
the atom: every theorem is uniform in `modelFailStopLoc`, so an
acceptance-shaped statement "every outcome is good, or `Killed _
fuelExhaustedKill`, or `Killed _ (Error0 modelFailStopLoc _)`" holds
under the reading where the atom is a location no model term denotes,
and a program that genuinely kills makes it unprovable, not false
(fuel-arc design §1.3, adopted unchanged; no distinctness lemma ships,
`≠ Undef0`/`≠ Other` free by constructor disjointness). Forgeability: a
Core `error("model fail-stop", pe)` yields `Error0 <its loc> "…"`, a
different term (§1.3's corollary).

**Why a SECOND atom rather than reusing `fuelExhaustedLoc`.** The
consumer's partial statement distinguishes EXHAUSTED (retry at larger
fuel) from everything else; a model fail-stop does not go away at larger
fuel. Two atoms keep the two left disjuncts separable in the acceptance
shape and let the harness classify FUEL and FAILSTOP separately (§2.5).
Cost: one more census row. Alternative rejected: one atom + a message
tag (reporting-only strings must not carry trust — fuel-arc §1.3).

**Hand-written sites (7 `memM` arms): mechanical edit**, `panic! "t"` →
`failStopMem "t"` (`CerbMem.lean:2075, :2105, :2198, :2686, :2756, :2945,
:2964`). Execution: the binary prints `Error {msg: "…"}` exit 1 instead
of `PANIC` exit 134 — a movement ONLY on rows where the oracle crashes;
the harness classifier (§2.5) keeps those rows in the CRASH class.

**Generated sites (59): a Lean-only lem declare — Route A of the lem
fuel-parameter record §5 / TODO row 13, restricted to what this pass
needs.** The backend already ASCRIBES every failure site with its type
(`lean_backend.ml:2953-2965`: `(failwithI <msg> : <site type>)`;
`:3517-3523` for incomplete patterns). Proposed declare:

```
declare {lean} failure_outcome type ND.ndM = `CerbFail.failStopND`
declare {lean} failure_outcome type State_exception_undefined.stExceptUndefM = `CerbFail.failStopST`
declare {lean} failure_outcome type Exception.exceptM = `CerbFail.failStopExcept`   -- t0-valued only, see M′
```

Emission rule: at a failure site whose ascribed type's head (BEFORE
lem's abbreviation expansion; with a second matcher for the expanded
`st → exceptM ((t0 a × st)) msg` shape, since `stExceptM` arrives
expanded — 16 sites show `core_run_state → …` as the head) is a declared
monad, emit `(<outcome> <msg> : <site type>)` instead of `(failwithI <msg>
: <site type>)`. Everything else is unchanged: `.lem` bodies untouched,
OCaml output byte-identical by construction (the declare is
`{lean}`-scoped, like every row of lem DESIGN.md's table :483-500), call
sites unchanged, signatures unchanged. The `[Inhabited]` threading for
those sites becomes unnecessary but harmless (the pre-pass records
failure sites renderer-independently, `lean_backend.ml:3510-3513`; a
follow-up may drop the binder where no opaque site remains).

Interplay with the fuel gate: the four C2 absorbing payload declares
(`full_eval_pexpr`, `eval_pexpr_aux2`, `eval_pexpr_aux_broken`,
`load_character_array_aux`) already state `Result (Error
CerbFuel.fuelExhaustedLoc …)`/`NDkilled (Error0 fuelExhaustedLoc …)`;
`FuelFormsTool`'s ABSORBING test (mentions the fuel atom under an
absorbing head, none of `failwithI`/`panic`) is unaffected. The new
gate (§3) recognises both atoms.

**Which of the 59 are kind 1 vs class (c).** By message (derived):
class (c) refusals — Driver `"TODO: perform_action_request2 ==>
concurrency"`, `"CONCURRENCY IS BROKEN"`, `"TODO: Step_fs2"`,
`"driver_fs_step: stdin not supported yet."`, Formatted `"TODO:
Formatted.convert, * prec"`, `"NOT YET SUPPORTED: %lc"`, `"WIP: …CS_n"`,
`"…CS_s with length modifier"`, `"TODO: snprintf()"`, `"TODO:
vsnprintf(), symbolic value"`; kind-1 model fail-stops — Driver `"ERROR
(in Driver, global init didn't evaluate to value)"`, `"Driver.prepare_exit
==> failed to find the initial thread"`, `"vprintf trying to output in
the stdin"`, `"va_start"`, Core_eval `"Core_eval.call_function, called
on a Proc/ProcDecl/BuiltinDecl"`, `"…PEcfunction expects a pointer"`,
`"…PEunion found a StructDef"`, Nondeterminism `"ND2.msum []"`, `"ND2.pick(…),
empty list"`, Core_reduction's 15 `stExceptM` sites (`"…Eif didn't
evaluated to a boolean"`, `"Eccall illtyped first operand"`, `"break_at_sseq,
Cbound"`, `"…Erun outside of a proc"`, …). Both classes get the SAME
outcome (a refusal IS a fail-stop the model chose); the class is
recorded in the register (§3) for the consumer's reading, not in the
term.

**Price.** lem side S–M (one declare form, type-head match at two
renderers, tests: a comprehensive-suite `.lem` with a failing site in
each monad + the negative probe for an undeclared head; the OCaml
byte-identity gate); cerberus side S (`CerbFail.lean`, 3 declare lines
in `frontend/model/{nondeterminism,state_exception_undefined,exception}.lem`
— Lean-only lines next to the existing `fuel` declares, 7 seam edits,
`Main` printing, the classifier, the census row); consumer S (one new
disjunct + the `_eq` bridge lemma, their induction template unchanged —
they said the same of the fuel kill, fuel-arc §7 verbatim ACK).
**Trust impact:** execution unchanged on every non-crashing input BY
CONSTRUCTION (the rewrite touches only arms whose runtime today is a
panic); the battery is the check that no other row moves; the crash-row
movement (PANIC 134 → classified kill) is enumerated in advance from the
immaculate lane's `SKIP_LEAN_CRASH`/`MATCH | L=CRASH` rows.

### 2.2 Group M′ — monadic sites without a `Loc` channel (5 sites; recommendation: PENDING + an operator question)

`Core_run_aux.pop_stack`/`pop_continuation_element`/
`push_continuation_element`/`append_to_current_continuation` (`:292-304`,
message `"… ==> Stack_cons2"`) return `exceptM X core_run_cause` with `X`
a stack/continuation pair, not `t0`; the only failure channel is
`core_run_cause` (`Errors.lean:364-375`: `Illformed_program s |
Found_empty_stack s | Reached_end_of_proc | Unknown_impl |
Unresolved_symbol loc sym`) — no `Loc` to hold the atom; a reserved
STRING would be the fuel arc's rejected design A′ (forgeable,
convention-based; options table §2). `AilTypesAux.lvalue_conversion`'s
`errorM` site is front-end typing (off the drive cone). Options: (a) a
one-constructor `.lem` addition to `core_run_cause` (`Model_fail_stop of
string`) — the OCaml text moves, `driver_ocaml.ml`'s exhaustive matches
need an arm, fork-drift manifest entry; it is also what the lem authors'
`TODO(use the error monad)` notes ask for; OUT OF BRIEF unless the
operator admits it (§6 Q2); (b) leave as `failwithI`, register PENDING
with the invariant "`Stack_cons2` frames are the fs-continuation shape
and these four are never applied to them on the sequential path" — the
invariant is a code-reading claim, not kernel-checked; (c) route through
`Found_empty_stack msg` — changes the failure class to a genuine
Core-run error, indistinguishable from the model's own use; rejected.
Recommendation: (b) now; (a) is the operator's call.

### 2.3 Group P — pure sites (the hard case)

Four candidate mechanisms, assessed against the brief's constraints
(no `.lem` body change, OCaml byte-identical, no mirror model):

**P1 — failure lifting through the pure call graph (a Lean-only
exception-monad transform).** The backend already has one transform of
exactly this shape: `declare {lean} supply` rewrites every function that
transitively draws into a state-passing one (DESIGN.md §4 of this repo;
lem DESIGN.md table). A `failure` transform would give every function
that transitively reaches a pure failure site the return type `Except
FailStop α` (or `Option`), rewrite call sites into binds, and turn the
site into `.error msg`; at the monadic frontier (`liftCore_run`, the ND
frames) the `.error` becomes the §2.1 kill. Correct BY CONSTRUCTION:
every pure failure becomes the typed outcome; the oracle's crash and the
Lean kill coincide on every input. Blast radius: the signature of every
function on the path from a pure site to a monadic frame — for
`core_thread_step2`/`step_action`/`one_step`/`finalize`/`sizeofCtype`/
`reconstructValue`/`valueFromMemValue` that is most of the exec cone;
every consumer export over `CerbMem` layout/value functions re-types;
the hand-written seams re-type by hand (`CerbMem`'s pure interface
functions mirror `mem.lem`'s pure signatures — `sizeof`, `ivfromfloat`,
`array_shift_ptrval`, `case_ptrval` are pure in the lem INTERFACE, so the
Lean seam would carry an `Except` the OCaml does not). The consumer's
objection to per-signature threading (their fuel review §1) was that
fuel is a parameter and should be ambient; a failure channel is a
genuine result, so the objection does not transfer verbatim — but the
re-typing cost does (they thread `TagDefs` 223 times, audit 2.C). Price
L (lem M–L: the transform + tests; cerberus L: seams + every measured
wrapper's obligation restated; consumer L: every export). Trust:
execution unchanged by construction; the battery confirms. Shares
instrumentation with fuel monotonicity Route B (lem TODO 13: "a second
instrumented copy of every worker") — if both are wanted, one arc.

**P2 — Lean-only `Option`-typing of the failure SITE only** (the brief's
candidate "making pure functions' failure sites `Option`-typed on the
Lean target only"): this IS P1 — a site's `Option` has to be consumed by
its caller, which must then return `Option`, and so on to the monadic
frame. There is no local version. Rejected as a separate option.

**P3 — hypothesis-carrying unreachability (the consumer's current
practice, made explicit and registered).** Each pure site is registered
with the INVARIANT under which it is not reached (§1.1.b's groups:
P-layout/P-bytes → Core well-typedness + memory well-formedness;
P-cfg → the configuration defaults; P-impl → structural facts about the
implementation record; P-cmp → the driver's comparison discipline;
P-instr → construction). The consumer's theorems already carry these as
premises ("The rules' premises keep proved programs away from them",
`ARCHITECTURE.md:456-459`; `create_atomic`'s `hsz : 0 < sizeofCtype …`).
What this pass adds: (a) the register — every pure site on the drive
cone named with its invariant class and mover, gate-pinned both
directions (§3); (b) the hygiene step P5 below; (c) for P-cfg, KERNEL
deadness once `CerbGlobal`'s eleven opaques become `def`s of the default
configuration (reasoning-artifact audit item 1, S, zero behaviour
change) — then `is_CHERI () = false` reduces and the CHERI/concurrency/
symbolic arms are `simp`-dead, which the gate can CHECK (a `decide`/`simp`
probe per arm, or the kernel closure of the arm's enclosing constant
after `simp` — registered as a PROVEN-UNREACHABLE row with the lemma
name); (d) for P-impl `sizeof_ity`'s un-normalised arms: a kernel lemma
`normalise_integerType ity ∈ normalised → …` (S, hand-written) — a
PROVEN-UNREACHABLE row. What P3 does NOT deliver: a theorem that an
export's run reaches no pure site — that needs a reachability witness,
i.e. P1's instrumentation. Honest statement for the consumer: pure sites
remain hypothesis-guarded, the hypotheses are now enumerated and pinned,
and the `= default` transparency is gone (P5). Price S (register +
gate) + S (2.A Step 1) + S (the two lemmas). Trust: zero execution
change (nothing on the path moves).

**P4 — leave the binary-level refusal as the only guard.** Rejected by
the ruling: the property owed is oracle conformance of the DEFINITIONS;
`LEAN_ABORT_ON_PANIC` guards the binary and is invisible in-process
(ruling doc, reading; reasoning-artifact audit §3 "Q3 to the letter").
It STAYS as the harness guard until group P is closed (the panics still
exist at runtime), but it is not a mechanism of this pass.

**P5 — hygiene: every hand-written `panic!` that is not converted by
§2.1 becomes `failwithI`** (111 arms, the 36 `CerbFS` refusals included; `[Inhabited α]` is already in scope
at each — `panic!` needs it too). Effect: the kernel-transparent
`= default by rfl` class disappears; every failure site in the tree is
then the same opaque family (the consumer's `ARCHITECTURE.md:462-466`
distinction collapses to one line). Runtime: identical panic, same exit
134, message loses the `PANIC at <Decl> <file>:<line>` prefix in favour
of `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: <msg>` — the
lanes classify on exit ≥ 128 + a PANIC line, not on the position
(exception class (a), message text). Not a typed outcome — an
opacity upgrade: with an opaque payload a theorem `drive p = Defined v`
on a crash path is stuck on the opaque wherever the run inspects the
value; it can still be PROVED where the value is discarded (`let _ :=
sizeofCtype Void; …`), so P5 narrows the false-theorem surface without
closing it. Price S. Zero execution change.

**Recommendation for P:** P5 + P3 in this pass (S+S+S); P1 as a named,
priced follow-up arc for the operator's decision (§6 Q1), scheduled with
lem TODO 13 Route B if fuel monotonicity is also wanted generated.

**A note on kind 2 inside P.** `truncToInt` nan/inf (P-float), the
`bswap64` `to_int64` overflow, the null-pointer `array_shift`
("should be undefined behaviour" in the model's own text), `allocator`
align 0, `decode_integer_constant ""`, `opIval IntExp`: the referent
ruling makes the logical meaning (UB, or "no meaning" → refusal) the
target, and several of these are REACHABLE from C. Where the logical
meaning is UB, the correct outcome is a `kill (Undef0 …)` — a MONADIC
outcome — but the site sits in a PURE `mem.lem` interface function
(`ivfromfloat`, `array_shift_ptrval`). The pure interface cannot express
it without a `.lem` change (or P1 with a UB-carrying failure type).
These are Z3/Z4 census rows first (the decision what the meaning IS),
and this pass's register rows second; the typed-outcome pass must not
pre-empt the zero-discrepancy decision by typing an artifact as a model
fail-stop.

### 2.4 Group R — the comparison residuals (recommendation: register by instance; reachability is the kernel's)

714 residual instance methods tree-wide (`lean_backend.ml:4567-4577`,
"comparison residual: <class> (<type>): type carries function-typed
fields"), 280 in gate-listed modules, + 10 hand-written. They are
refusals of a comparison lem leaves undefined on function types (the
OCaml raises at runtime — kind 2 in origin, refusal in the right
outcome). Their enclosing constants are INSTANCE methods; whether any is
in `drive`'s kernel closure is exactly what the C2 gate's constant
closure answers (the header of `CerbStepInstances.lean:66-79` argues
Driver's `==` on `core_step2` is the only live use, and it is a
hand-written instance overriding the residual). Mechanism: the §3 gate
lists every residual-bodied constant in the closure; each must be a
register row of class RESIDUAL with the discipline named (e.g. "`Driver`
compares steps only at `Step_blocked2`/`Step_error2`", `Driver.lean:349
can_advance`), or be shown unreachable by the closure. No conversion:
`Bool`/`Ordering` have no absorbing element and the P1 transform would
have to re-type `BEq` itself. Price S.

### 2.5 The harness and `Main`

`Main` prints a kill `Error0 loc msg` as `Error {msg: "<msg>"}` (the
FUEL classifier reads that line: `scripts/fuel_classify.sh`
`FUEL_KILL_BATCH_LINE='Error {msg: "lem: fuel exhausted"}'`). For the
new outcome, `Main` prints `Error {msg: "cerberus-lean: model fail-stop
— <msg>"}` (the prefix is reporting-only; at runtime the compiled opaque
has its value, so `Main` may also test `loc` against the atom — a
runtime test, not a proof fact) and exits 1; a sibling
`scripts/failstop_classify.sh` yields `FAILSTOP:kill`; every lane that
classifies FUEL classifies FAILSTOP the same way and maps it to the
CRASH class (today a both-crash row is `MATCH | L=CRASH`; it stays
MATCH). Plants: (1) a unit exe returning the kill → `FAILSTOP:kill`; (2)
a genuine `PEerror` with the same text → also `FAILSTOP:kill` — the
documented reporting-only limit, identical to fuel's. Baseline movement
enumerated in advance: every immaculate/gcc/ci row currently
`SKIP_LEAN_CRASH`/`LEAN_CRASH`/`L=CRASH` whose Lean side is a converted
site changes label (not class); zero movement elsewhere is the
acceptance criterion (ruling doc "Trust surface").

## 3. The gate — `check_failure_forms.sh` (fail-closed; plants)

Extends the C2 pattern (`scripts/check_fuel_forms.sh` +
`test/Unit/FuelFormsTool.lean`) rather than adding a second tool:
`FuelFormsTool` grows a second table, or a sibling `FailureFormsTool`
shares its reachability code (the kernel constant closure of `drive`,
`initial_driver_state`, the three runners, `CerbCall.driveCall`, closed
under mutual blocks via `eqnInfoExt` — C2 §7, F-C2-6).

**Unit of classification: the CONSTANT** (the kernel has no notion of a
site). For every constant in the closure, collect its used-constant set
and classify:

- **TYPED** — references `CerbFail.failStop*` (or the fuel atom's
  absorbing forms) and none of the opaque failure primitives. Goal state
  for group M; no register row.
- **OPAQUE-FAILING** — references any of `LemLib.failwithI`,
  `LemLib.fuelExhaustedWith` (already the fuel gate's business; excluded
  here to keep the partitions disjoint), the private `lemDivByZero`
  (through `lemNatDiv`/`lemIntDiv`/…, `LemLib.lean:1381-1407, :1582-1584`),
  Lean's `panic`/`panicCore`/`panicWithPosWithDecl`. RED unless it is a
  row of `scripts/failure_forms_pending.txt` with a class ∈ {REFUSAL-c
  (the guard named), INVARIANT (the invariant named: WF-CORE / WF-MEM /
  CONFIG / IMPL / CONSTRUCTION), KIND2-PENDING (the Z row), RESIDUAL,
  INSTRUMENT} and a mover; a register row that is no longer
  reachable-opaque is RED (stale pin) — the register moves only by
  explicit edit, both directions (the C2 discipline verbatim).
- **PROVEN-UNREACHABLE** — a row whose named lemma exists in the
  environment, has the declared shape (e.g. `∀ …, is_CHERI () = false →
  …` or the `sizeof_ity` normalisation lemma) and an axiom cone ⊆ the
  standard three; the row is then green without being pending.

**Source legs** (comment-stripped, the census scripts' stripper):
zero `panic!` in the exec cone's hand-written seams after P5 (a pin,
both directions: the count is 0, not "≤ N"); the boundary-opaque census
gains `CerbFail.modelFailStopLoc` exactly once (existing gate, existing
plant); no `failwithI` under a declared monad head in the generated tree
(a regex over the ascription: `failwithI [^:]*: *\(ndM\|memM\|stExceptUndefM\|exceptM (t0\)` must be empty — the lem-side declare's effect, checked cerberus-side).

**Vacuity guards:** ≥ 40 typed constants, ≥ 20 register rows, the
partition sums to the closure's failure-referencing count; the tool
fails closed on a missing entry constant or an absent summary line.

**Plants (`--selftest`, on a scratch copy of the table; nothing in the
tree touched):** P1 a typed constant re-labelled opaque-failing and not
registered → RED naming it; P2 a stale register row → RED; P3 a
PROVEN-UNREACHABLE row whose lemma has `sorryAx` in its cone → RED; P4 a
truncated table → RED; P5 a decoy lemma of type `True` under the right
name → RED (the C2 M1 decoy shape); P6 (source leg) a `panic!` planted in
a scratch copy of `CerbMem.lean` → RED; P7 (lem leg, in lem-lean's
comprehensive suite) a failure site under a declared monad head that
still renders `failwithI` → RED. Plant-tested vacuity per the working
practices; the gate is a TRUST property (the consumer's (A)/(B)/(C) for
failures), so it is a hard gate, not a speedbump.

**Known limit (stated in the script, as C2 §7 does):** the closure stops
at `opaque`/`implemented_by`/`extern` boundaries — the census-pinned
population. ONE of those hides a panic today: `typeof_enum_impl`
(`CerberusImpl.lean:62-70`); the gate cannot see it; the reasoning-artifact
audit's 2.C remedy (the enum table as a value) removes it, and the
register carries it as INVARIANT/CONFIG with 2.C as the mover until then.

## 4. Sequencing

**Where things stand (2026-09-05).** Z1 and Z2 merged; the fuel arc's
cerberus half C1–C3 merged (`928aa1e76`); Z3 and Z4 have NOT run (no
`*Z3*`/`*Z4*` record exists in `lean_frontend/docs/`; the ruling's
sequencing was Z1 → Z2 fix phase → Z3 → Z4 → this pass). lem TODO row 18
(declare consolidation, [USER 2026-09-04] "definitely worth doing before
we get to stable") is scheduled after the cerberus fuel half — i.e. now
— and before the upstream lem submission. The whole-project trust-surface
risk map ([USER 2026-09-05], `TODO.md:356-372`) runs after Z4 and the
fuel close-out, before the fresh-noodler exit test.

**Dependencies.**

1. **Z3/Z4 before the cerberus conversion slice.** Z3/Z4 add kind-1
   mirrors (new `panic!` arms, by the interim rule) and dispose kind-2
   rows (converting failures into model outcomes or declared refusals).
   Converting before them would redo the census and re-touch the same
   `CerbMem`/`Main` hunks (the ruling's reasons 1–2 still hold). The
   interim rule (mirror as `panic!` with the OCaml text) STAYS for Z3 so
   the later conversion is mechanical — with one amendment worth ruling
   now: new kind-1 arms inside `memM` may be written directly as the
   typed kill once `CerbFail.lean` exists (§6 Q6).
2. **The lem declare (§2.1, Route A) is independent of Z3/Z4** — it
   touches lem-lean only — but it is NEW DECLARE VOCABULARY under the
   consolidation freeze (TODO 18; C3 record §8 item 1 already deferred a
   vocabulary request for the same reason). Two orderings: (a)
   consolidate first, then add `failure_outcome` as a member of the
   TERMINATION/outcome family in the consolidated grammar (no rename
   churn; the pass's cerberus slice waits for both); (b) add it now
   under the current grammar and rename at consolidation (one more
   Lean-only line rename in the cerberus pin bump). The consumer re-pins
   once per lem bump; (a) saves a re-pin. Recommendation: (a), because
   Z3/Z4 gate the cerberus slice anyway (§6 Q3).
3. **Bundle the reasoning-artifact audit's items 1 and 5** (2.A Step 1
   `CerbGlobal` defs — S, zero behaviour change; 2.C the enum registry as
   a value — M, a `.lem`/`TagDefs` change the audit says to "schedule
   with the typed-failure pass, which otherwise has to invent an outcome
   for the unregistered arm that this change makes unreachable"). Item 1
   is what makes group P-cfg kernel-dead (§2.3 P3(c)); item 5 removes
   the one panic the gate cannot see (§3). Whether 2.C's `TagDefs`-type
   change is in brief is the operator's (§6 Q5).
4. **The risk map.** This pass MOVES the trust surface (a second opaque
   atom on the boundary census; generated Lean text changes at 59 sites;
   the harness classifier; crash-row labels). Either the risk map runs
   after this pass (its baseline the 2026-08-31 split, this pass one of
   the enumerated movements — cleanest), or it runs before and this pass
   gets its own delta audit. Recommendation: after (§6 Q4).

**Proposed slice plan (for the operator to cut).**

| slice | content | repo | price | gate |
|---|---|---|---|---|
| L1 | lem: `failure_outcome` declare (in the consolidated grammar, or standalone) + comprehensive-suite cases + negative probe + OCaml byte-identity | lem-lean | S–M | tests/comprehensive, `check_no_fuel_numerals`, byte-identity |
| C0 | cerberus: `CerbFail.lean`; `Main` printing; `failstop_classify.sh`; baseline movement enumeration (dry run: which rows relabel) | cerberus | S | census row; classifier plants |
| C1 | cerberus: the 3 declare lines + regen; the 7 `memM` seam edits; P5 hygiene (111 `panic!` → `failwithI`); `check_failure_forms.sh` + register (every pure/residual row with class + invariant + mover) | cerberus | M | full battery (zero movement off the crash rows), the new gate + plants, fuel gate unchanged |
| C2 | the two PROVEN-UNREACHABLE lemmas (`sizeof_ity` normalisation; P-cfg deadness after 2.A Step 1) | cerberus | S | gate rows flip pending → proven |
| R | consumer second design review before C1's merge (the fuel-arc practice); their contract restated (§5) | refined-cerberus | S | — |
| P1? | failure-lifting transform (with fuel Route B if wanted) | lem-lean + cerberus + consumer | L | new arc, own charter |

## 5. The consumer contract change

**What becomes non-PROVISIONAL / what changes in their exports.**

- Acceptance shape gains one disjunct: for every fuel and every
  well-formed input, `runND (drive …)`'s outcomes are each `Defined`-good,
  or `Killed _ fuelExhaustedKill`, or `Killed _ (Error0 modelFailStopLoc
  _)`, or a genuine model kill (UB / Core-run error / memory error) — with
  the third disjunct's `_zero`-style bridge lemma `failStopKill_eq :
  failStopKill msg = Error0 modelFailStopLoc msg := rfl` and the free
  disjointness `≠ Undef0`, `≠ Other`. Their induction template
  (fuel-arc §1.3 quote) consumes the new disjunct the same way it
  consumes exhaustion: an engine round that reaches a converted site
  yields the kill; nothing is absorbed. Fuel monotonicity of converted
  functions is unaffected: the outcome is absorbing in the same monads
  the fuel kill is.
- Their `panic!`-arm disclosure (`ARCHITECTURE.md` §3, KOI A5; README
  "61 arms at this pin, 40 in CerbMem") shrinks to: zero `panic!` arms;
  N register rows of opaque `failwithI` pure sites, each with its
  invariant class — the same premises they already state (WF-CORE,
  WF-MEM, the empty-tagDefs/extern configuration) — and the sentence
  "no theorem states that an export's run reaches none" stays TRUE for
  group P until P1 (the register makes the set finite and named; the
  `= default by rfl` reading is gone).
- The `CerbMem` API: the 7 `memM` sites' TYPES are unchanged (a kill is
  already in `memM`'s codomain); the pure functions' types are unchanged
  (P5 changes bodies only). `drive`'s signature is unchanged. Change
  manifest: `CerbFail.*` new; `Main`'s batch line for the new kill; no
  deletions.
- Their `LEAN_ABORT_ON_PANIC`-independence: an in-process consumer never
  needed the flag; after this pass the converted sites are values the
  kernel classifies, and the unconverted (pure) sites are opaque and
  registered. The binary keeps the refusal until group P is closed.
- The exception classes ([USER 2026-09-03] (a) text / (b) resource / (c)
  missing feature) are unchanged; a typed fail-stop is the same class
  as the crash it mirrors, reported in a different exit form.

## 6. Open questions for the operator (only genuine ones)

1. **Group P's end state.** Accept hypothesis-carrying pure sites
   permanently (P3 + P5: registered, opaque, premise-guarded — the
   consumer's current practice made mechanical), or schedule the
   failure-lifting transform P1 (L; re-types most exec-cone signatures
   and every consumer export; correct by construction; shares
   instrumentation with fuel monotonicity Route B)? The brief's "we don't
   change the lem structure for ocaml" is satisfied by both (P1 is a
   Lean-only transform); the consumer's re-typing cost is P1's price.
   Note that the 36 `CerbFS` refusals become typed kills ONLY under P1
   (§1.1.c); under P3/P5 they stay opaque refusals.
2. **Group M′ (4 stack-op sites + `errorM`).** Admit a one-constructor
   `.lem` change to `core_run_cause` (OCaml text moves; fixes the model's
   own `TODO(use the error monad)`) — a tray-worthy upstream fix — or keep
   them PENDING under a code-reading invariant?
3. **Declare vocabulary vs consolidation (lem TODO 18).** Design
   `failure_outcome` inside the consolidated grammar first (my
   recommendation; no churn; Z3/Z4 gate the cerberus slice anyway), or
   add it now and rename later?
4. **Risk map ordering.** Run the whole-project risk map AFTER this pass
   (this pass an enumerated movement) — my recommendation — or before,
   with this pass audited as a delta?
5. **Bundling the reasoning-artifact audit's items 1 (2.A Step 1,
   `CerbGlobal` defs, S) and 5 (2.C enum registry as a value, M, touches
   `TagDefs`/desugar types).** Item 1 is what makes the CHERI/concurrency/
   symbolic arms kernel-dead; item 5 removes the one panic behind an
   opaque. Is 2.C in this pass's brief, or its own slice?
6. **Interim-rule amendment for Z3.** May new kind-1 mirrors inside
   `memM` be written directly as the typed kill once `CerbFail.lean`
   lands (C0 before Z3), so Z3 does not add arms this pass immediately
   rewrites? Or keep Q4's `panic!` form for Z3 and convert all at C1?
7. **Kind-2 pure sites reachable from C** (`truncToInt` nan/inf, the null
   `array_shift`, `bswap64` overflow): their logical meaning is UB or a
   refusal — a MONADIC outcome the pure `mem.lem` interface cannot
   express without P1 or a `.lem` interface change. Confirm these are
   Z3/Z4 rows (the meaning) that this pass only REGISTERS, and that a
   `.lem` interface change is out of brief.

## 7. Provenance

[USER 2026-09-03]: the typed-failure ruling (§0, verbatim), the
logical-semantics referent ruling (kind 1 / kind 2), the exception
classes, the no-magic-values general form. [USER 2026-09-04]: "we don't
change the lem structure for ocaml", "stick to our brief" (relayed by the
orchestrator in this brief), the declare-consolidation ruling (lem TODO
18). [USER 2026-09-05]: the whole-project risk map (TODO.md:356-372).
[USER 2026-09-02]: fuel-arc Option C (the opaque-atom template).
Consumer statements: refined-cerberus `docs/2026-09-04_review-of-fuel-parameter-design.md`
§2 ((A)/(B)/(C), the "silent fail-open" sentence), `docs/DECISIONS.md`
(PROVISIONAL rule 2026-09-02; the demo's acceptance goals; the 61-arm
disclosure 2026-09-04), `cerberus-heaplang/ARCHITECTURE.md:249-251,
:444-466`, `README.md:588-597`. Prior records used as inputs: the Z1
record (Z2-FL-03, the refusals), the Z2 record §2.10 (the kind table) and
§7, the C2 record §3/§7/§8/§9 (absorbing payloads, the gate, F-C2-3/7,
D-C2-3/6), the lem fuel-parameter record §5 and TODO rows 13/17/18, the
lem `DESIGN.md` (:277-305 Inhabited derivation and comparison residuals;
:483-500 the declare table), the reasoning-artifact audit (§1 the lens,
§2.C, §3, §4 items 1 and 5), `DESIGN.md` §4, `VALIDATION.md` §5 and the
"Known, LOUD limits". Code read: every hand-written seam listed in §1.1;
`generated/` at `928aa1e76` (primary checkout); `lem-lean/lean-lib/LemLib.lean`
(:152-232, :1376-1407, :1582-1584); `lem-lean/src/_build/lean_backend.ml`
(:2953-2965, :3501-3523, :4567-4577); `lem-lean/src/patterns.ml` (:1594,
:1644); `frontend/model/{driver,nondeterminism}.lem` (:1477; :124, :134,
:140). All counts DERIVED by the §1.0 commands; nothing here was decided
by the author — every recommendation is marked as such and every
decision is in §6.


## R1 — operator ruling on scope (2026-09-05)

[USER 2026-09-05], on the orchestrator's proposed split ("the monadic
group's typed absorbing outcomes now, the pure group's register and gate
as the interim with the large transform decided after the risk map"):
"Decision 4: yes agree, this seems the lowest risk approach".

Applied [AGENT]: (1) MONADIC group — the seven hand-written `memM` failure
sites become the memory monad's error (the driver already turns it into
the kill) in a cerberus slice after C4/Z3 land (no lem change); the 59
generated monadic sites' Lean-only `failure_outcome` declare is DESIGNED
INSIDE the declare-consolidation pass (lem TODO 18) rather than added as
an eleventh form now — lowest-risk ordering (§6 Q3 resolved this way).
(2) PURE group — interim only: `panic!` → loud `failwithI` hygiene in the
seams, a pinned register of every pure failure site by its invariant
class, and the fail-closed `check_failure_forms` gate (§3); the
failure-lifting transform (§2, L) is decided after the trust-surface risk
map. (3) §6 Q2 (M′ `.lem` constructor change): NOT admitted — lem edits
are against the rules ([USER 2026-09-05] on the concurrency branch's F2);
M′ stays pending under its named invariant. Q1/Q4–Q7 as recommended in
§6 unless the operator says otherwise.
