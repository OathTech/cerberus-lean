# PNVI arc S1: the switch set as an explicit ambient parameter — slice record (2026-10-05)

Branch `arc/pnvi-switches`, from mainline `mdd/cerberus-lean` = `1806c5a23`.
Worker: Claude Opus 5.5 (agent). Every judgement below that no operator quote
covers is marked [AGENT]. Quoted gate output is verbatim; counts marked
"derived" are mine.

## 0. Ruling, design and brief

- [USER 2026-10-05], recorded verbatim in the design record §1.4: "Re PNVI - agree on
  your recs except for mirroring crashes / obviously wrong behavior. These should be
  refusals surely?" The coordinator read this as accepting design §F.1, option 3: the
  switch set is an instance-implicit `[CerbGlobal.Switches]`, with S0 in lem-lean.
- Governing design: `lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md` (design worktree,
  commit `aa5df9201`): §0, §A (read-site inventory, §A.6), §B.0, §B.3, §B.4, §B.5, §B.7,
  §D.2, §E row S1 and §H.
- The lem mechanism, S0: lem-lean branch `arc/pnvi-switches` at `fc8fbef` (record
  `doc/lean-backend/2026-10-05_instance-reader-record.md`). It is NOT merged.
- The slice is an internals refactor with **zero behaviour change**: the generated OCaml
  is byte-identical, every lane is unchanged, and the default-mode C→Core output is
  unchanged.

## 1. The lem build and the PROVISIONAL pin

This slice is pinned to an unmerged lem commit: `fc8fbef`, the same-name branch pair
`arc/pnvi-switches`. The orchestrator re-points the pin if lem's commit changes after
review.

**The lem used.** I built lem in this worktree's scratch. The shared opam switch, its
`lem` and `deps/lem-pinned` were not touched.

- Clone: `git clone --no-hardlinks …/lem-lean .tmp/lem-fc8fbef`, then
  `git checkout fc8fbef`.
- Build: root `make`, run under `scripts/ce` (the opam switch's OCaml 5.4.0).
- `lem -v`, verbatim: `Lem lean-backend-v0.1.0-alpha.1-64-gfc8fbef` (not `-dirty`).
- Use: a scratch wrapper put `.tmp/lem-fc8fbef/bin` first on `PATH` and set
  `LEMLIB=.tmp/lem-fc8fbef/library`, in that one command's environment only.
  - The Makefile finds lem by `command -v lem`.
  - The clone has no `make install`, so lem's library fallback
    (`<argv0 dir>/library`) would miss. `LEMLIB` is set explicitly.
  - The clone's `library/` (35 files) is byte-identical to the opam switch's
    `share/lem/library` (`cmp`, derived).

**Pin sites**, all `fc8fbefece6e9861920bc1ca335e662e9a80ecbb`:

- `lean_frontend/lakefile.toml`: the rev, plus a provenance comment;
- the three lake-manifests, rev and inputRev. Lake re-cloned LemLib offline through
  `deps/gitconfig`; only the rev lines changed;
- `scripts/fork_drift_manifest.txt` `[meta] lem-pin`, with a dated NOTE and no `--refresh`;
- `lean_frontend/README.md`: the opam pin command and the NOTICE/LICENSE links. These
  point at an UNPUSHED commit until lem-lean is published;
- the "Lem pin has since moved" parentheticals of `README.md`, `CLAUDE.md`,
  `SUPPORTED.md`, `TODO.md` and `VALIDATION.md`, each marked PROVISIONAL.

LemLib (`lean-lib/`) is byte-identical between `4e70bb5` and `fc8fbef`
(`git diff --stat 4e70bb5 fc8fbef -- lean-lib` is empty).

## 2. What changed

1. **`CerbGlobal.lean`** (the class, the default, the readers):
   - `class Switches where switches : List CerbSwitch`.
   - `def defaultSwitches : List CerbSwitch := []`, renamed from `CerbGlobal.switches`
     (switches.ml:47-48 `internal_ref = ref []`; FORCED by OCaml, not a magic value).
   - `has_switch [Switches] sw`, `is_PNVI [Switches] ()` and
     `has_strict_pointer_arith [Switches] ()` read `Switches.switches`, mirroring
     switches.ml:54-55, :156-157 and :159-160.
   - `is_CHERI` is the BUILD CONSTANT `false` (design §B.4.1, accepted §F.9). It used to be
     `has_switch .cheri` over `[]`, so its value is unchanged.
   - `PNVIVariant` (`PLAIN | AE | AE_UDI`), and `CerbSwitch.PNVI (v)` APPENDED after
     `zero_initialised`. The derived `Inhabited` default stays `.strict_reads`, pinned.
   - The header records the deliberate divergence of MECHANISM: a global on OCaml, a
     parameter on Lean (the `tagDefs` precedent).
2. **`frontend/model/lean_switches.lem`** (NEW, Lean-only; deviation D1):
   - `val switches : unit -> list cerb_switch`, declared
     `declare {lean} reader val switches = instance `CerbGlobal.Switches.switches``.
   - Its Lean target_rep is the projection itself, which typechecks only where an
     instance is in scope.
   - `reader_consumer … = instance switches` for `Global.has_switch`, `Global.is_PNVI`,
     `Global.has_strict_pointer_arith`, and the 17 `Mem.*` vals whose `CerbMem` bodies
     read the set (listed in §3).
   - `Makefile`: `LEM_SRC_LEAN += LEM_SRC_LEAN_ONLY`, and `lean-prelude-src` depends on
     `LEM_SRC_LEAN`.
   - `lakefile.toml` gains the roots `Lean_switches` and `Lean_switches_auxiliary`.
3. **`CerbMem.lean`**: 17 definitions bind `[CerbGlobal.Switches]` after `[LemFuel]` (§3).
   The H2 header now describes the parameter.
4. **Hand-written callers.** These bind `[CerbGlobal.Switches]`:
   - `CerbCall.lean`: `allocErrno`, `callFinish`, `driveCall`;
   - `Main.lean`: `frontendTU`, `loadLibc`, `runPipeline`.

   `CerbND.lean`'s `driver2_wrapper_defeq` and `drive_nonmemory_steps_aux2_wrapper_defeq`
   now quantify `(sws : CerbGlobal.Switches)`.
5. **`Main.lean` — the CLI.** `--switches` is PARSED in both of cmdliner's forms,
   `--switches=V` and `--switches V` (main.ml:589-591, `opt (list string)`).
   - Every value is REFUSED, with exit 2. Each element gets one line with its own reason:
     every oracle switch name class (switches.ml:60-102), an unknown name, an override
     and the empty value. The oracle is fail-open on unknown names and overrides
     (switches.ml:136-141); the refusal names R-PNVI-11/12 (design §G R20).
   - A repeated option is refused as cmdliner refuses it ("cannot be repeated", the
     `--args` precedent).
   - `--iso` gets its own attributed reason. It used to fall through as "unknown flag".
   - The run's instance is supplied beside the fuel instance, on the one line:
     `let code ← (letI : LemFuel := ⟨fuel⟩; letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩; runPipeline …`.
   - The old `--switches` branch of `refuseFlag` is gone. `check_no_fuel_numerals.sh`'s
     allowlisted line follows the new text.
6. **Tests and speclab.** They supply the default explicitly, never through an instance:
   - `letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩` in the exe entries of
     `MonadicFailstop`, `MatchPatternArityTest` (2 functions) and `MemoryAccess`.
   - `@mainAt ⟨fuel⟩ ⟨CerbGlobal.defaultSwitches⟩` in the five speclab gate tests, whose
     runners bind `[CerbGlobal.Switches]`.
   - `FuelExemplar`: a named `def sw₀ : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩`,
     inserted positionally after the fuel instance at its 16 `@f ⟨…⟩` sites
     (`@drive ⟨n⟩ sw₀ …`). `errnoAction`, `setupTail`, `s₁` and `S₁` bind the class.
   - `MemoryAccessProofs.load_erasure` now holds for EVERY switch set
     (`[CerbGlobal.Switches]`; its proof is unchanged).
   - `TotalityProofTest` Part 1 was regenerated (§5).
7. **Gates**:
   - NEW `scripts/check_switches_instance.sh`, wired into row 1 (§4);
   - `scripts/gen_fuel_parametricity.py` emits instance binders in binder order (§5);
   - `scripts/check_cli_refusals.sh` pins 23 refusals and 4 repeated-option refusals (§4);
   - the failure-reach register's reason text for the three `Prov_symbolic` rows (§6).

## 3. Read sites — how each reads the parameter

These are MEASURED: comment-stripped counts over this tree before the change. The design
counted 16 `CerbMem` reads (13 + 3). The code has **15** (12 `has_switch` + 3 `is_PNVI`);
the 16th in the design's grep was a doc-comment mention (derived).

**Generated (14 sites, excluding the 32 `is_CHERI` build constants).** Each emits
`CerbGlobal.has_switch` / `is_PNVI` / `has_strict_pointer_arith`, which now read
`Switches.switches`. The enclosing definition binds `[CerbGlobal.Switches]` through lem's
lifting (`translate_expression` etc. — call sites textually unchanged):

| Site (this tree) | Owner | Read |
|---|---|---|
| `Mini_pipeline.lean:168` | `evalConstantExpressionAux` | `has_switch .inner_arg_temps` |
| `Core_run.lean:1733, 1772` | `core_thread_step2` | `has_switch .inner_arg_temps` ×2 |
| `Formatted.lean:1182` | `convert` | `has_switch .permissive_printf` |
| `Translation.lean:3013/3016, 3220/3223` | `translate_expression` | `has_strict_pointer_arith () ∨ is_CHERI () ∨ is_PNVI ()` ×2 |
| `Translation.lean:3994, 4271` | `translate_expression` | `has_strict_pointer_arith ()` (+ `is_PNVI ()` at :4272) |
| `Translation.lean:5783, 5851, 5873` | `translate_program` | `has_switch .inner_arg_temps` ×3 |

**Hand-written (`CerbMem.lean`, 15 reads in 12 definitions).** Each definition binds
`[CerbGlobal.Switches]`; its lem val is a `reader_consumer … = instance switches`:

| Definition | Read(s) (impl_mem.ml arm) |
|---|---|
| `allocateObject` | `has_switch .zero_initialised` |
| `killM` | `has_switch .forbid_nullptr_free`, `has_switch .zap_dead_pointers` |
| `loadM` | `has_switch .strict_reads` |
| `eqPtrval` | `has_switch .strict_pointer_equality` |
| `ltPtrval` `gtPtrval` `lePtrval` `gePtrval` | `has_switch .strict_pointer_relationals` (one each) |
| `diffPtrval` | `has_switch (.pointer_arith .PERMISSIVE)` |
| `ptrfromint` | `is_PNVI ()` |
| `intfromptr` | `is_PNVI ()` |
| `effArrayShiftPtrval` | `has_switch (.pointer_arith .STRICT)`, `is_PNVI ()`, `has_switch (.pointer_arith .PERMISSIVE)` |

These also bind it **transitively**: `nePtrval` (through `eqPtrval`), `memcpyM`, `memcmpM`,
`reallocM` and `copyAllocId`. Their vals are consumers too. Seventeen `Mem.*` consumers in
all.

**The lifted cone (MEASURED: `[CerbGlobal.Switches]` binder occurrences per generated
module).**

- Generated modules:
  - `Cabs_to_ail` 50 (`desugar` and the desugarer, through the const-expression mini-run);
  - `Driver` 16 (`drive`, `driver2`, `driver_globals`, `drive_nonmemory_steps_aux2`,
    `perform_memop_request2`, `process_core_step2`, …);
  - `Formatted` 10;
  - `Translation` 5 (`translate_expression`, `wrapped_translate_expression`,
    `translate_stmt`, `translate_program`, `translate`);
  - `Mini_pipeline` 4;
  - `Core_run` 1.
- Seam copies: `CerbMem` 18 (17 definitions + 1 doc line), `CerbCall` 3, `Main` 3,
  `CerbGlobal` 2, `CerbND` 1, `Lean_switches` 3 (comments).

The instance gate's count is 109 (§4).

**No inductive relation reaches a switch read.** lem would refuse that loudly, as an S0
limitation; the generation ran clean.

**Signatures NOT changed**, because they read no switch:

- `initial_driver_state`, `initialMemState`, `CerbND.runNDFuel` and every runner wrapper;
- `storeM`, `allocateRegion`, `validForDerefPtrval`, `isWellAlignedPtrval`;
- `reconstructValue` (that is S2);
- `CerbMem.MemState`.

## 4. Gates

### 4.1 The instance gate `scripts/check_switches_instance.sh` (design §D.2 P5/P8)

**Scope.** THIS repository only:

- `lean_frontend/*.lean`, `generated/`, `test/`, `speclab/` and `tests/**/*.lean`
  (`.lake` excluded);
- plus the consumed LemLib copy.

**Forbidden.** Over the comment-stripped text:

- S1: an `instance` declaration whose head names `Switches`. The head is cut at a `:=` or
  `where` OUTSIDE brackets, so `(priority := low)` does not hide it. A first draft cut at
  any `:=`, and its own plant caught that.
- S2: an instance attribute in a file naming `Switches`.
- S3: in PRODUCTION text (the seams, generated code and `speclab/SpecLab`), a local instance
  or named value of the class, other than Main's allowlisted line.

**Decision on tests [AGENT].** Tests MAY build an explicit value (`letI …`, `sw₀`). That is
a visible choice at the use, as the tests choose their fuel. It is never an instance
anything resolves to implicitly.

**Vacuity guards:**

- at least 150 files scanned;
- the class is present;
- Main's line is seen in both copies;
- at least one generated binder;
- LemLib is present.

Verbatim (row 1):

```
check_switches_instance: SELFTEST OK (7 plants RED with their labels, unplanted control GREEN, consumer-direction plant GREEN, real tree GREEN)
check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance of CerbGlobal.Switches; the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
```

**Plants, verbatim from the selftest:**

```
  PLANT OK   [P5/P8a instance in a seam] ->   S1 lean_frontend/CerbND.lean:423: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in generated/] ->   S1 lean_frontend/generated/Driver.lean:2871: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in test/] ->   S1 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in speclab/] ->   S1 lean_frontend/speclab/test/SLUnit/CoreGateTest.lean:159: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [S2 instance attribute] ->   S2 lean_frontend/CerbMem.lean:3259: an instance attribute in a file that names Switches
```

- The two S3 plants (a production `letI` in `CerbCall`, and a named default in generated
  `Translation`) are also RED.
- **P8b, the consumer direction.** A consumer-style Lake package under `.tmp/` (a path
  dependency on `lean_frontend`, its own `instance : CerbGlobal.Switches`) leaves the gate
  GREEN.

### 4.2 CLI refusals (`scripts/check_cli_refusals.sh`, row 1)

```
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
```

The pre-existing `--switches=PNVI_ae_udi` pin ("semantics switches") passes unchanged. The
message is now per element:

```
cerberus-lean: refused — --switches=PNVI_ae_udi: semantics switches are not supported by this port yet — `PNVI_ae_udi`: the PNVI-ae-udi provenance model (switches.ml:82-83, SW_PNVI `AE_UDI) is being ported (the PNVI arc: the switch set became a parameter of the semantics in slice S1; the ae-udi memory arms are not implemented yet), so the oracle's answer under it cannot be matched (e.g. it turns an integer→pointer UB043 into a value) (see VALIDATION.md, zero-discrepancy Z-24)
```

### 4.3 Row 1 and Tier A

Row 1 (`scripts/test_unit.sh`, run with this worktree's lem first on `PATH`), rc 0, 5:40
wall. The verdict lines are verbatim; the long ones are cut where the log cuts them:

```
Total: 16 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (325 files scanned comment-stripped — generated 221, hand-written+test 69, LemLib 35; 0 sorry tokens)
check_no_fuel_numerals: OK (332 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
gen_fuel_parametricity: SELFTEST OK (6 plants with the declared FAIL, unplanted control OK, real tree OK)
check_lakefile_roots: OK (220 roots = 220 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_fork_content: OK — 88 source files content/mode-pinned
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin fc8fbefece6e9861920bc1ca335e662e
check_pin_sites: OK — lem-pin fc8fbefece6e9861920bc1ca335e662e9a80ecbb at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
```

Tier A (`python3 scripts/release.py --mode fast`): §7.

## 5. Lemmas

**`CerbGlobal.lean`.** Every statement is closed by kernel `rfl`:

- `defaultSwitches_eq : defaultSwitches = []`;
- `has_switch_default (sw) : @has_switch ⟨defaultSwitches⟩ sw = false`;
- `has_switch_nil (sw) : @has_switch ⟨[]⟩ sw = false`;
- one per switch, all at `⟨[]⟩`: `has_switch_{strict_reads, forbid_nullptr_free,
  zap_dead_pointers, inner_arg_temps, permissive_printf, no_integer_provenance, cheri,
  strict_pointer_equality, strict_pointer_relationals, pointer_arith_permissive,
  pointer_arith_strict, zero_initialised}_default` and `has_switch_PNVI_default (v)`;
- `is_PNVI_default`, `has_strict_pointer_arith_default`;
- `is_CHERI_eq`, unchanged.

These REPLACE `has_switch_eq`, the eight `has_switch_*_eq` lemmas, `is_PNVI_eq` and
`has_strict_pointer_arith_eq`. Those were statements about the constant set, which no
longer exists.

**`opaque-failure-test`.**

- The H2 facts are restated at `⟨[]⟩`, with three more switches. `gt_ptrval`'s arm
  reduction at `⟨[]⟩` is kept.
- New POSITIVE CONTROLS show the reads see the parameter, so the default pins are not
  vacuous:
  - `@is_PNVI ⟨[.PNVI .AE_UDI]⟩ () = true`;
  - `@has_switch ⟨[.PNVI .AE_UDI]⟩ (.PNVI .AE_UDI) = true`;
  - `@has_switch ⟨[.PNVI .AE_UDI]⟩ (.PNVI .AE) = false`;
  - `@has_strict_pointer_arith ⟨[.pointer_arith .STRICT]⟩ () = true`.
- `is_CHERI () = false` independent of the set.

**Fuel parametricity.** `gen_fuel_parametricity.py` read instance binders as "the
non-`LemFuel` ones go before `⟨n⟩`". With the instance reader AFTER `[LemFuel]` (S0 binder
order) it would have emitted ill-typed pins. It now emits binders in order and maps the
worker's instance arguments by class. Three pins changed, e.g.:

```
example [i1 : CerbGlobal.Switches] (n : Nat) : @driver2 ⟨n⟩ i1 = @driver2_lemFuel ⟨n⟩ i1 n := rfl
```

The other 11 lines are byte-identical to before. The set check's regex accepts arguments
after `⟨n⟩`. Its selftest passes (6 plants, row 1).

## 6. The failure-reach register (design §A.6, §F.10)

The three `Prov_symbolic` rows (`CerbMem.combineProv` ×2, `CerbMem.arrayShiftPtrval`;
register lines 66, 67, 105, the design's "rows 64/65/103") said: "Prov_symbolic arises only
in the symbolic execution mode".

- That is WRONG: `Prov_symbolic` is minted by the PNVI arms in the CONCRETE model
  (impl_mem.ml:280-290, `ptrfromint`'s `is_PNVI` arm).
- The `need` text now says that, and that this port constructs `Prov_symbolic` nowhere.
  Every occurrence in `CerbMem` is a pattern, and `ptrfromint`'s PNVI arm is a loud kill.
  The run's set is `defaultSwitches`. The `cite` names `ptrfromint`, `Main.refuseSwitches`
  and this record.
- The reach class stays UNREACHABLE-BY-INVARIANT; the census did not change it.
- `check_failure_reach.py --reseal`: "resealed 233 rows". The seal covers
  file/definition/token/msg/scope/position/reach, not the `need`/`cite` text, so every seal
  and the tally are unchanged.
- `diff` against the pre-edit register: exactly those 3 lines (6 diff lines, derived).
- Gate: `check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly …)`.

## 7. Zero-change evidence

1. **Generated OCaml: byte-identical.**
   - The OCaml generation list (`LEM_SRC`) and every `.lem` file it reads are unchanged.
     `lean_switches.lem` is Lean-only.
   - `ocaml_frontend/generated` (86 files), regenerated with lem `fc8fbef` after the
     change, versus the tree generated before any edit: `diff -r` empty
     (`OCAML_BYTE_IDENTICAL`).
   - Against the opam lem `4e70bb5`'s output on the same sources: `diff -r` empty
     (`IDENTICAL_TO_OPAM_4e70bb5_OUTPUT`).
   - Whole-tree sha256 of both: `9ad44dba791832791fbffa3f1be642308155e2e378d70550642f65ce00fac98a`.
   - The lem-sync generated hash is unchanged: `gen c1bb429a…` before and after.
   - Fork-drift: layer 2 "30 differing generated files, all hash-pinned", unmoved.
2. **OCaml rebuild.** Cache-disabled (`DUNE_CACHE=disabled dune build --force
   backend/driver/main.exe cerberus-lib.install`), then `dune install --prefix
   _build/local-install cerberus-lib` and `dune build --force cerberus.install`. rc 0.
3. **Lanes.** Tier A (§7.1). Every lane at its committed baseline is the lane-result
   evidence. Rows 8 (`test_core.sh`) and 9 (`test_elab.sh`) check the Lean C→Core output
   against the unchanged oracle at its recorded state, so a moved default elaboration
   would show there.
4. **Default facts by `rfl`** (§5): at `⟨[]⟩` every switch test is `false`, so every
   lifted definition reduces to its pre-change body.

### 7.1 Tier A

**First run, on the UNCOMMITTED tree.** Verbatim tail of
`python3 scripts/release.py --mode fast` (12:09 wall):

```
fast: incomplete; 17/17 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Every row PASSED: A1, A2, A3, A4, A4b, A4c, A5, A6, A6b, A7, A8, A9, A10, A11, A12.1,
A12.2 and A13. "Source unchanged: False" is because documentation files (this record,
`CLAUDE.md`, `VALIDATION.md`, `LADDER.md`) were edited while the run was in progress. The
re-run on the committed tree follows.

## 8. Deviations from the brief and the design

- **D1 [AGENT] — the reader and its consumers live in a NEW Lean-only lem file, not in
  `global.lem`. `has_switch`/`is_PNVI`/`has_strict_pointer_arith` are NOT shared lem
  bodies.**
  - Measured: any lem `val`, and any `let` with an OCaml target_rep, is emitted into the
    generated OCaml as a comment. A scratch copy of `global.lem` with
    `val switches`, a shared `has_switch2` body under an OCaml target_rep, and a
    `let {lean}` definition generated:

    ```
    > (*val switches: unit -> list cerb_switch*)
    >
    > (*val has_switch2: cerb_switch -> bool*)
    > (*let has_switch2 sw:bool=  List.elem
    >   instance_Basic_classes_Eq_var_dict sw (switches ())*)
    ```

    (`let {lean}` emitted nothing.) The brief's two requirements — shared bodies in
    `global.lem`, and byte-identical generated OCaml — therefore conflict.
  - I kept the hard invariant. The readers stay hand-written in `CerbGlobal.lean`,
    mirroring switches.ml with line cites, and become instance consumers.
  - `declare` lines emit nothing, and lem accepts consumer declarations naming another
    module's constants (measured on a two-module scratch). So the anchor `val switches`
    and all consumer declarations sit in `frontend/model/lean_switches.lem`, which is in
    the Lean generation list only. That is the mirror image of `core_unstruct.lem`, which
    is OCaml-only.
  - Cost: a new frontend file and a Makefile change. Both are oracle-surface layer-1/3
    rows (NOTE in the manifest), but the generated OCaml does not move.
  - The alternative — `val switches` in `global.lem` — would make `lem_global.ml` a new
    layer-2 cosmetic row.
- **D2 [AGENT] — no lem-side `SW_PNVI` constructor.** The lem `cerb_switch` type is
  emitted into `lem_global.ml` as a local OCaml type, so a new constructor changes the
  generated OCaml. No lem code needs it: `is_PNVI` is the only PNVI reader, and it is
  hand-written. `CerbSwitch.PNVI` exists on Lean only.
- **D3 [AGENT] — the read-site count is 15 in `CerbMem` (29 in all), not 16 (30).** See §3.
- **D4 [AGENT] — tests may build explicit `letI`/named values of the class.** The gate bans
  instance DECLARATIONS everywhere in this repository, and production values outside
  Main's line (§4.1). The brief's wording "except Main's letI" is read as "no instance
  anything resolves to implicitly". The tests must supply some value to run the default
  pipeline, as they do for fuel.
- **D5 — extras inside the slice's surface:**
  - `--iso`'s own reason;
  - R-PNVI-11/12 names in the override and unknown-name messages;
  - `load_erasure` generalised to every switch set;
  - `gen_fuel_parametricity.py`'s binder-order fix, which S1 forced.
- **Process note.** `make lean-native-obj` was run once WITHOUT `scripts/capped`. It is a
  `leanc` C compile of `native/*.c` plus one `lake env printenv LEAN_SYSROOT`; no Lean
  elaboration. The CLAUDE.md recipe caps it, so this was a slip against the "never
  uncapped" rule. Every other lake/lean invocation was capped.
- **Not touched:**
  - `tests/provider-smoke` and `scripts/build_provider_smoke.py`. They already pin an
    older lem (`f6542f8`) and are out of every tier.
  - `tests/mem-scale-probes/micro`, which names no lifted function; only its manifest
    rev moved.

## 9. Draft consumer note for S5 (cerberus-sl-visible changes) — DRAFT, not sent

Measured read-only against cerberus-sl HEAD `e8b3692` (their tree pins an older
cerberus-lean; S5 does the authoritative scratch build and the line-for-line prediction).

**Renamed or removed:**

- `CerbGlobal.switches` → `CerbGlobal.defaultSwitches`. Their sites:
  - `HeapModel.lean:382`, `HeapModelKill.lean:31`, `Memory/Transitions.lean:62`: in
    `simp [CerbGlobal.has_switch, CerbGlobal.switches, List.any_nil]`;
  - `PtrEqModel.lean:21, 32`: comments.
- `CerbGlobal.has_switch_eq` and the eight `has_switch_*_eq` → `has_switch_default` /
  `has_switch_nil` and the `has_switch_*_default` family, at `⟨[]⟩`. Likewise
  `is_PNVI_eq` → `is_PNVI_default`, and `has_strict_pointer_arith_eq` →
  `has_strict_pointer_arith_default`.

**New:**

- `CerbGlobal.Switches` (class), `CerbGlobal.PNVIVariant`, and `CerbSwitch.PNVI v`. A
  consumer `match` on `CerbSwitch` gains an arm.

**The default-instance recipe.**

- Declare ONE local `instance : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩` in a
  layer module. Their facts then elaborate as before and close by `rfl`.
  - Example: `has_switch .strict_pointer_equality = false := rfl` at `PtrEqModel.lean:34`,
    and `probes/…hidden_panic_default.lean:26`.
  - The `simp` lines become
    `simp [CerbGlobal.has_switch, CerbGlobal.Switches.switches, CerbGlobal.defaultSwitches, List.any_nil]`
    or plain `rfl`.
- Measured in this tree: `example : @has_switch ⟨[]⟩ .strict_reads = false := rfl` and the
  arm reduction `@CerbMem.gtPtrval ⟨[]⟩ loc … = memReturn …` by `rfl` (opaque-failure-test).
- Measured with a scratch consumer-style probe (`scripts/lean_probe.sh`, deleted).
  Importing `CerbMem` and `Driver` and declaring that one instance, these all elaborate:
  - `has_switch .strict_pointer_equality = false := rfl`;
  - the `simp [CerbGlobal.has_switch, CerbGlobal.Switches.switches, CerbGlobal.defaultSwitches]`
    form;
  - `@CerbMem.nePtrval ⟨n⟩ _ loc p q = @CerbMem.nePtrval ⟨n⟩ ⟨CerbGlobal.defaultSwitches⟩ loc p q := rfl`
    (the `_` at the switch-set position is synthesised);
  - the positional `CerbMem.nePtrval loc p q`.

  A planted false `… = true := rfl` in the same probe was reported as an error, so the
  probe is not vacuous.

**Signatures that gained `[CerbGlobal.Switches]` immediately AFTER `[LemFuel]`:**

- `drive`, `driver2`, `driver2_lemFuel`, `driver_globals`, `drive_nonmemory_steps_aux2`
  (+`_lemFuel`), `process_core_step2`, `perform_memop_request2`, `desugar`, `translate`;
- `CerbMem.{allocateObject, killM, loadM, eqPtrval, nePtrval, ltPtrval, gtPtrval, lePtrval,
  gePtrval, diffPtrval, ptrfromint, intfromptr, effArrayShiftPtrval, memcpyM, memcmpM,
  reallocM, copyAllocId}`;
- `CerbCall.driveCall`;
- the `CerbND` wrapper-defeq theorems, which gained `(sws : CerbGlobal.Switches)`.

Positional calls are unchanged. **`@`-explicit calls need the instance argument after the
fuel one.** Their 25 sites (derived from grep):

- `PtrEqModel.lean:105, 114, 121, 140` and `PrimOutcome.lean:482, 494, 525, 555, 613,
  677, 686`: `@CerbMem.nePtrval inst …`;
- `PtrEqExamples.lean:94, 99, 104`: `@CerbMem.nePtrval ⟨1⟩ default …`, where `default`
  would now be taken as the Switches argument — a type error;
- `RoundThread.lean:41`: `@CerbMem.loadM i₁ …`;
- `RoundThread.lean:81-82` and `RunBuild.lean:223-224`: `@CerbMem.allocateObject i₁ …`;
- `DriverLoop.lean:693, 703, 886` and `RunBuild.lean:65, 75`: `@driver_globals ⟨m + 2⟩ …`
  and `@CerbMem.allocateObject ⟨m + 2⟩ …`.

Each takes ` _` (synthesised from their local instance) or `⟨CerbGlobal.defaultSwitches⟩`
after the fuel argument.

**Not changed:**

- `initial_driver_state`, `initialMemState`, `CerbND.runNDFuel`/`runND`/`runND1`,
  `fuelExhaustedKill`;
- `storeM`, `allocateRegion`, `validForDerefPtrval`, `alignofIval`;
- `reconstructValue`/`_lemFuel` (S2's), `MemState`, the run digest and the enum reader.

**Freeze.** The elaborated terms of every frozen declaration that mentions a lifted
function now carry the instance. S5 measures the fingerprint drift on the scratch build.

**Default bit-identity.** The generated OCaml is byte-identical, and the default-mode lanes
are at baseline (§7).

## 10. Not done (S1 scope)

- No PNVI arm and no refusal of §G. That is S3.
- No `reconstructValue` wrapper. That is S2.
- No lane; no CONTRACT/VALIDATION rewrite of the "Semantics switches" text. That is S4.
- No message to cerberus-sl.
- No full ladder: the orchestrator runs Tier B.
