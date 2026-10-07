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
(Re-pointed to `2d3a492` on 2026-10-05, §11.)

**MERGE ORDER (pre-merge audit L2, 2026-10-06): DO NOT MERGE this branch until lem-lean
`2d3a492` is on `mdd/lean-backend` and `deps/lem-pinned` plus the shared opam lem are moved
to it (the two-repo pin dance); a re-gate in the standard environment must then be green.**
The same sentence stands beside the LemLib rev in `lean_frontend/lakefile.toml` and in the
fork-drift manifest NOTE.

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
   - NEW `scripts/check_switches_instance.sh`, wired into row 1 (§4) — superseded by §14
     (withdrawn 2026-10-07, replaced by rule W1 of `scripts/check_no_fuel_numerals.sh`);
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

The instance gate's count is 109 (§4). (Superseded by §14: that gate was withdrawn on
2026-10-07; the count is historical.)

**No inductive relation reaches a switch read.** lem would refuse that loudly, as an S0
limitation; the generation ran clean.

**Signatures NOT changed**, because they read no switch:

- `initial_driver_state`, `initialMemState`, `CerbND.runNDFuel` and every runner wrapper;
- `storeM`, `allocateRegion`, `validForDerefPtrval`, `isWellAlignedPtrval`;
- `reconstructValue` (that is S2);
- `CerbMem.MemState`.

## 4. Gates

### 4.1 The instance gate `scripts/check_switches_instance.sh` (design §D.2 P5/P8)

> **Superseded by §14 (proportionality revision, 2026-10-07):** this gate was withdrawn as gate cruft and replaced by rule W1 of `scripts/check_no_fuel_numerals.sh`; the text below is kept as the historical record.

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

### 4.1a The instance gate hardened (pre-merge audit L1, 2026-10-06)

> **Superseded by §14 (proportionality revision, 2026-10-07):** this gate was withdrawn as gate cruft and replaced by rule W1 of `scripts/check_no_fuel_numerals.sh`; the text below is kept as the historical record.

The audit found S1–S3 evadable: an alias (`abbrev MySw := CerbGlobal.Switches; instance :
MySw := ⟨[]⟩`), a `class … extends … Switches` with an instance, and a production `def x :
CerbGlobal.Switches where …` (or a multi-line header) were all GREEN; and P8b passed
trivially, because the gate never scanned `.tmp/` at all. The fix [AGENT, within the
round the operator approved on 2026-10-06 — [USER 2026-10-06] "Yes, sounds good, go ahead",
quoted in §12]:

- **Whitelist, not blacklist (S7).** Every occurrence of the token `Switches` in the scanned
  text (comments stripped; strings kept) must sit in one of five positions: W1 an
  instance-implicit binder `[(x :) (CerbGlobal.)Switches]`; W2 an explicit binder
  `(x … : (CerbGlobal.)Switches)`; W3 the projection `Switches.switches`; W4 the one
  `class Switches where` (exactly once in `CerbGlobal.lean` and once in its generated copy);
  W5 a typed value `… : (CerbGlobal.)Switches` followed by `:=`, `where` or `|`. Anything
  else is RED — so an alias body, an `extends`, an ascription `(v : Switches)`, a name
  literal, a string, a `«Switches»` spelling are all caught without having been foreseen.
- **Labelled classes of the non-whitelisted uses.** S4 an alias (the token in the body of an
  `abbrev`/`def`/`opaque`/`notation`/`macro`/`syntax`/`macro_rules`/`elab`), S5 an
  `extends`, S7 the rest. Aliases and extensions are banned EVERYWHERE, tests included.
- **Names collected repo-wide (S6, S2).** The names of S4 aliases, S5 extensions, and
  switch-set values declared in a header (`def sw₀ : CerbGlobal.Switches := …`, today exactly
  one: `test/Unit/FuelExemplar.lean`'s `sw₀`) are collected; an `instance` whose head or body
  names one (`instance : MySw := …`, `instance := sw₀`) is RED (S6), and so is an instance
  attribute naming one in any file (S2's new arm).
- **Production vs test made explicit (S3).** The scan roots are one table in the gate,
  each marked `prod`, `test` or `lemlib` (`SWITCHES_GATE_LIST=1` prints it). S3 is now
  position-based (W5 in a `prod` file), so `where` forms and multi-line headers are caught;
  D4 is kept — a W5 value in a `test` file is allowed (but cannot become an instance: S2/S6).
- **P8b made a real test of the scoping rule.** On a scratch COPY of the scan set: (i) a
  consumer-style Lake package with its own instance under the copy's `.tmp/` leaves the copy
  GREEN; (ii) the gate's root/file list is asserted non-empty and to contain nothing under
  `.tmp/` and not the consumer file; (iii) the same file copied under `lean_frontend/test/`
  turns the copy RED with S1 — so (i) is not vacuous.
- **Residual limit — REVISED by the delta audit's B-1 (2026-10-06, §4.1b); the current
  statement is §4.1b's, which this bullet now repeats.** The gate reads text. It cannot see a
  TYPED instance, or a value, whose class is stated without spelling the token `Switches` or
  a collected alias name: a meta-level name assembled from strings (`Name.mkStr …
  ("Swit" ++ "ches")`, or a command elaborated from a string), a type recovered by
  elaboration from a signature (`instance : type_of% … := …` and projections of it), or any
  of these outside the scan roots. (The L1 round also listed "an untyped `instance := e`
  whose `e` is not a collected name"; since B-1 every untyped instance and every instance
  attribute is RED in every root, S8, so that item is closed.) Those are review discipline.
  The backstop is the typing: a lifted definition with no instance in scope does not
  elaborate, and the consumer statement form is `@f ⟨sw⟩`. One known false-positive
  direction, accepted fail-closed: an instance that merely TAKES `[CerbGlobal.Switches]` as
  a binder in its head is RED under S1 (none exists).

`check_switches_instance.sh --selftest`, verbatim (run on the final tree of the L1 round —
SUPERSEDED by §4.1b's run, kept as the record of that round):

```
check_switches_instance: SELFTEST — planting on scratch copies (loud plant banner; nothing in the tree is touched)
  PLANT OK   [P5/P8a instance in a seam] ->   S1 lean_frontend/CerbND.lean:423: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in generated/] ->   S1 lean_frontend/generated/Driver.lean:2871: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in test/] ->   S1 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in speclab/] ->   S1 lean_frontend/speclab/test/SLUnit/CoreGateTest.lean:159: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [S2 instance attribute] ->   S2 lean_frontend/CerbMem.lean:3259: an instance attribute in a file that names Switches
  PLANT OK   [S3 production letI outside Main] ->   S3 lean_frontend/CerbCall.lean:322: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw4 := (letI : CerbGlobal.Switches := ⟨[]⟩; (0 : Nat))
  PLANT OK   [S3 production named default] ->   S3 lean_frontend/generated/Translation.lean:6194: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw5 : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩
  PLANT OK   [L1a abbrev alias + instance at the alias] ->   S4 lean_frontend/CerbND.lean:423: `abbrev MySw` — an alias of the switch-set class (its body names Switches)
               +   S6 lean_frontend/CerbND.lean:424: an instance naming alias `MySw` (lean_frontend/CerbND.lean:423)
  PLANT OK   [L1a @[reducible] def alias in test/ (aliases banned in tests too)] ->   S4 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: `def MySw2` — an alias of the switch-set class (its body names Switches)
  PLANT OK   [L1a guillemet-spelled alias] ->   S4 lean_frontend/CerbMem.lean:3259: `abbrev MySw3` — an alias of the switch-set class (its body names Switches)
  PLANT OK   [L1a alias in one file, its instance in another (no Switches token there)] ->   S4 lean_frontend/CerbCall.lean:322: `abbrev MySw4` — an alias of the switch-set class (its body names Switches)
               +   S6 lean_frontend/generated/Driver.lean:2871: an instance naming alias `MySw4` (lean_frontend/CerbCall.lean:322)
  PLANT OK   [L1a notation alias] ->   S4 lean_frontend/CerbND.lean:423: `notation MySwN` — an alias of the switch-set class (its body names Switches)
  PLANT OK   [L1b class extends Switches + instance] ->   S5 lean_frontend/CerbND.lean:423: `class MyCls extends … Switches` — an extension of the switch-set class
               +   S6 lean_frontend/CerbND.lean:424: an instance naming class `MyCls` extending Switches (lean_frontend/CerbND.lean:423)
  PLANT OK   [L1b structure extends Switches in test/] ->   S5 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: `structure MyStr extends … Switches` — an extension of the switch-set class
  PLANT OK   [L1c production def … where] ->   S3 lean_frontend/generated/Translation.lean:6194: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw6 : CerbGlobal.Switches where
  PLANT OK   [L1c production multi-line abbrev header] ->   S3 lean_frontend/CerbCall.lean:323: a production value/local instance of the switch-set class outside Main.lean's entry: : CerbGlobal.Switches :=
  PLANT OK   [L1c production value in speclab/SpecLab] ->   S3 lean_frontend/speclab/SpecLab/DivModHarness.lean:428: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw8 : CerbGlobal.Switches := ⟨[]⟩
  PLANT OK   [S6 untyped instance of a (D4-allowed) test value] ->   S6 lean_frontend/test/Unit/TotalityProofTest.lean:122: an instance naming switch-set value `plantV` (lean_frontend/test/Unit/OpaqueFailureTest.lean:192)
  PLANT OK   [S2 attribute on a test value from a file without the token] ->   S2 lean_frontend/test/Unit/AreCompatibleTest.lean:69: an instance attribute naming switch-set value `plantV2` (lean_frontend/test/Unit/OpaqueFailureTest.lean:192)
  PLANT OK   [S7 ascription-typed untyped instance] ->   S7 lean_frontend/CerbND.lean:423: an unrecognised use of the switch-set class (not a binder/projection/typed value): … CerbND⏎⏎instance := (⟨[]⟩ : CerbGlobal.Switches)⏎…
  PLANT OK   [S7 name literal in a macro body] ->   S7 lean_frontend/CerbND.lean:423: an unrecognised use of the switch-set class (not a binder/projection/typed value): …ontract⏎⏎end CerbND⏎⏎#eval ``CerbGlobal.Switches⏎…
  PLANT OK   [S7 the token in a string] ->   S7 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: an unrecognised use of the switch-set class (not a binder/projection/typed value): … return 0⏎⏎#eval IO.println "CerbGlobal.Switches"⏎…
  PLANT OK   [S7 a second class Switches outside CerbGlobal.lean (W4 is CerbGlobal-only)] ->   S7 lean_frontend/CerbND.lean:423: an unrecognised use of the switch-set class (not a binder/projection/typed value): …fl⏎⏎end FuelContract⏎⏎end CerbND⏎⏎class Switches where⏎  switches : …
  CONTROL OK [unplanted scratch copy] -> check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
  PLANT OK   [P8b consumer direction] (i) out-of-root consumer package with its own instance: GREEN -> check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
               (ii) root list excludes .tmp/: 8 roots, 367 files, none under .tmp/
               (iii) same file under lean_frontend/test/: RED ->   S1 lean_frontend/test/ConsumerScoped/ConsumerPlant.lean:2: an instance declaration of the switch-set class (a hidden default)
  REVERTED (real tree):
check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
check_switches_instance: SELFTEST OK (23 plants RED with their labels, unplanted control GREEN, consumer-direction plant P8b (i)-(iii) OK, real tree GREEN)
```

### 4.1b The instance gate, second hardening (delta audit B-1, 2026-10-06)

> **Superseded by §14 (proportionality revision, 2026-10-07):** this gate was withdrawn as gate cruft and replaced by rule W1 of `scripts/check_no_fuel_numerals.sh`; the text below is kept as the historical record.

The delta audit of §4.1a reproduced three evasions on a scratch copy, each GREEN (rc 0):
(i) a test-root instance with a blank line before its type (`instance plantI⏎⏎    :
CerbGlobal.Switches := ⟨[]⟩`); (ii) a test-root instance head longer than the 400-character
window; (iii) a test value defined INDENTED inside a namespace, made an instance from another
file by `attribute [local instance] PX.plantV` or `instance := PX.plantV`. The cause: test
roots allow W5, so S1 rested on `head_cut` alone (400-character window, cut at a blank line),
and name collection only saw declarations at column 0. Before changing anything I re-ran each
evasion against the pre-fix script (`cd97a049a`) on a scratch copy: all GREEN, confirming the
finding; a `where`-clause value made an instance (`instance := plantH.plantW`) was GREEN too.
The fix [AGENT, within the round the operator approved: [USER 2026-10-06] "Yes, do (1) as
recommended" — §13]:

- **Commands found by keyword (all rules).** A command starts at a line whose first token,
  after ANY indentation and modifiers, is a command keyword or `@[`; the command enclosing an
  offset is found by scanning BACK to the nearest such start. There is no fixed window and no
  column-0 rule. Commands, `instance` keywords and attributes are searched in the text with
  string CONTENTS blanked (no command lives in a string; the token scan for S7 still keeps
  strings). Without the blanking, four `"… instance …"` strings in speclab were misread as
  instances.
- **S1 by two independent rules, in EVERY root.** (a) The head runs from the keyword to the
  first `:=`/`where` outside brackets, with no length window and no blank-line cut; an
  unterminated head runs on, which is fail-closed. If it names `Switches`, S1. (b) A W5 token
  whose enclosing command's keyword is `instance`, and which is the command's own type (no
  `:=`/`where`/local binder before it in the command), is S1. I checked each rule alone on
  scratch copies, by disabling the other: each turns (i) and (ii) RED.
- **Names collected at any indentation (S6, S2).** `def plantV : CerbGlobal.Switches := …`
  inside `namespace PX` is now collected, and `PX.plantV` matches. S6/S2 segments run to the
  next command start, with no 2000-character cap. An `@[instance]` alone on its line extends
  to the end of the next command.
- **S8: untyped instances and instance attributes are closed outright, in every root.** An
  instance with no `:` outside brackets in its head (`instance := e`, `instance foo := e`)
  and ANY instance attribute (`@[instance]`, `attribute [instance]`/`[local instance]`/
  `[scoped instance]`) are RED whatever they name. These are the two ways to make a value an
  instance without stating the class, so this closes the `where`-clause case and any value
  whose name the collector misses. The real scan set has zero of either, measured 2026-10-06
  over all 367 files, LemLib included. Decision [AGENT]: a legitimate future use (for example
  LemLib adding `attribute [local instance]`) then needs an explicit, reviewed change to the
  gate. That is loud friction, accepted as fail-closed.
- **Residual limit (now stated as follows, in the script header, §4.1a and the VALIDATION.md
  row).** The gate reads text. It cannot see a TYPED instance, or a value, whose class is
  stated without spelling the token `Switches` or a collected alias name: a meta-level name
  assembled from strings (`Name.mkStr … ("Swit" ++ "ches")`), a command elaborated from a
  string (`run_cmd`/`elab`), or a type recovered by elaboration from a signature
  (`instance : type_of% … := …` and projections of it). Nor can it see anything outside the
  scan roots. Two consequences of finding commands by keyword: a command keyword missing from
  the list merely extends the previous command, so S6 segments run longer (fail-closed); a
  line inside a term that starts with a listed keyword (`open … in`) shortens an S6 segment,
  which matters only for a typed instance whose type already escapes S1/S6 (the case above).
  These are review discipline. The backstop is the typing: a lifted definition with no
  instance in scope does not elaborate, and the consumer statement form is `@f ⟨sw⟩`.
  Accepted false positive, fail-closed: an instance that merely TAKES `[CerbGlobal.Switches]`
  as a head binder is RED under S1(a) (none exists).
- **Plants.** 7 new, 30 in all. B-1(i), B-1(ii), B-1(iii) in both forms (attribute: S2+S8;
  untyped instance: S6+S8), an indented typed instance inside a namespace (S1), and the
  `where`-clause value as an untyped instance and as an attribute (S8). The 23 earlier plants
  stay RED under their labels, and the real tree stays GREEN with the same summary line as
  before (367 files, 1 test-side named value, 109 binders), so there are no new false
  positives on the real tree. Gate time on the real tree: about 5.0 s, up from 3.7 s (derived,
  one `time` run each).

`check_switches_instance.sh --selftest`, verbatim (final script of this round):

```
check_switches_instance: SELFTEST — planting on scratch copies (loud plant banner; nothing in the tree is touched)
  PLANT OK   [P5/P8a instance in a seam] ->   S1 lean_frontend/CerbND.lean:423: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in generated/] ->   S1 lean_frontend/generated/Driver.lean:2871: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in test/] ->   S1 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [P8a instance in speclab/] ->   S1 lean_frontend/speclab/test/SLUnit/CoreGateTest.lean:159: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [S2 instance attribute] ->   S2 lean_frontend/CerbMem.lean:3259: an instance attribute in a file that names Switches
  PLANT OK   [S3 production letI outside Main] ->   S3 lean_frontend/CerbCall.lean:322: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw4 := (letI : CerbGlobal.Switches := ⟨[]⟩; (0 : Nat))
  PLANT OK   [S3 production named default] ->   S3 lean_frontend/generated/Translation.lean:6194: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw5 : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩
  PLANT OK   [L1a abbrev alias + instance at the alias] ->   S4 lean_frontend/CerbND.lean:423: `abbrev MySw` — an alias of the switch-set class (its body names Switches)
               +   S6 lean_frontend/CerbND.lean:424: an instance naming alias `MySw` (lean_frontend/CerbND.lean:423)
  PLANT OK   [L1a @[reducible] def alias in test/ (aliases banned in tests too)] ->   S4 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: `def MySw2` — an alias of the switch-set class (its body names Switches)
  PLANT OK   [L1a guillemet-spelled alias] ->   S4 lean_frontend/CerbMem.lean:3259: `abbrev MySw3` — an alias of the switch-set class (its body names Switches)
  PLANT OK   [L1a alias in one file, its instance in another (no Switches token there)] ->   S4 lean_frontend/CerbCall.lean:322: `abbrev MySw4` — an alias of the switch-set class (its body names Switches)
               +   S6 lean_frontend/generated/Driver.lean:2871: an instance naming alias `MySw4` (lean_frontend/CerbCall.lean:322)
  PLANT OK   [L1a notation alias] ->   S4 lean_frontend/CerbND.lean:423: `notation MySwN` — an alias of the switch-set class (its body names Switches)
  PLANT OK   [L1b class extends Switches + instance] ->   S5 lean_frontend/CerbND.lean:423: `class MyCls extends … Switches` — an extension of the switch-set class
               +   S6 lean_frontend/CerbND.lean:424: an instance naming class `MyCls` extending Switches (lean_frontend/CerbND.lean:423)
  PLANT OK   [L1b structure extends Switches in test/] ->   S5 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: `structure MyStr extends … Switches` — an extension of the switch-set class
  PLANT OK   [L1c production def … where] ->   S3 lean_frontend/generated/Translation.lean:6194: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw6 : CerbGlobal.Switches where
  PLANT OK   [L1c production multi-line abbrev header] ->   S3 lean_frontend/CerbCall.lean:323: a production value/local instance of the switch-set class outside Main.lean's entry: : CerbGlobal.Switches :=
  PLANT OK   [L1c production value in speclab/SpecLab] ->   S3 lean_frontend/speclab/SpecLab/DivModHarness.lean:428: a production value/local instance of the switch-set class outside Main.lean's entry: def plantSw8 : CerbGlobal.Switches := ⟨[]⟩
  PLANT OK   [S6 untyped instance of a (D4-allowed) test value] ->   S6 lean_frontend/test/Unit/TotalityProofTest.lean:122: an instance naming switch-set value `plantV` (lean_frontend/test/Unit/OpaqueFailureTest.lean:192)
  PLANT OK   [S2 attribute on a test value from a file without the token] ->   S2 lean_frontend/test/Unit/AreCompatibleTest.lean:69: an instance attribute naming switch-set value `plantV2` (lean_frontend/test/Unit/OpaqueFailureTest.lean:192)
  PLANT OK   [S7 ascription-typed untyped instance] ->   S7 lean_frontend/CerbND.lean:423: an unrecognised use of the switch-set class (not a binder/projection/typed value): … CerbND⏎⏎instance := (⟨[]⟩ : CerbGlobal.Switches)⏎…
  PLANT OK   [S7 name literal in a macro body] ->   S7 lean_frontend/CerbND.lean:423: an unrecognised use of the switch-set class (not a binder/projection/typed value): …ontract⏎⏎end CerbND⏎⏎#eval ``CerbGlobal.Switches⏎…
  PLANT OK   [S7 the token in a string] ->   S7 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: an unrecognised use of the switch-set class (not a binder/projection/typed value): … return 0⏎⏎#eval IO.println "CerbGlobal.Switches"⏎…
  PLANT OK   [S7 a second class Switches outside CerbGlobal.lean (W4 is CerbGlobal-only)] ->   S7 lean_frontend/CerbND.lean:423: an unrecognised use of the switch-set class (not a binder/projection/typed value): …fl⏎⏎end FuelContract⏎⏎end CerbND⏎⏎class Switches where⏎  switches : …
  PLANT OK   [B-1(i) test instance with a blank line before its type] ->   S1 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [B-1(ii) test instance head longer than 400 characters] ->   S1 lean_frontend/test/Unit/OpaqueFailureTest.lean:192: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [B-1(iii) indented test value in a namespace, local-instance attribute from another file] ->   S2 lean_frontend/test/Unit/AreCompatibleTest.lean:69: an instance attribute naming switch-set value `plantV` (lean_frontend/test/Unit/OpaqueFailureTest.lean:193)
               +   S8 lean_frontend/test/Unit/AreCompatibleTest.lean:69: an instance ATTRIBUTE (`@[instance]`/`attribute [… instance …]`) — banned in every root
  PLANT OK   [B-1(iii) indented test value in a namespace, untyped instance from another file] ->   S6 lean_frontend/test/Unit/TotalityProofTest.lean:122: an instance naming switch-set value `plantV` (lean_frontend/test/Unit/OpaqueFailureTest.lean:193)
               +   S8 lean_frontend/test/Unit/TotalityProofTest.lean:122: an UNTYPED instance (`instance … := e`) — banned in every root (its class is not stated)
  PLANT OK   [B-1 indented typed instance inside a namespace in test/] ->   S1 lean_frontend/test/Unit/OpaqueFailureTest.lean:193: an instance declaration of the switch-set class (a hidden default)
  PLANT OK   [S8 untyped instance of a where-clause value (no collected name)] ->   S8 lean_frontend/test/Unit/TotalityProofTest.lean:122: an UNTYPED instance (`instance … := e`) — banned in every root (its class is not stated)
  PLANT OK   [S8 instance attribute on a where-clause value (no collected name)] ->   S8 lean_frontend/test/Unit/AreCompatibleTest.lean:69: an instance ATTRIBUTE (`@[instance]`/`attribute [… instance …]`) — banned in every root
  CONTROL OK [unplanted scratch copy] -> check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
  PLANT OK   [P8b consumer direction] (i) out-of-root consumer package with its own instance: GREEN -> check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
               (ii) root list excludes .tmp/: 8 roots, 367 files, none under .tmp/
               (iii) same file under lean_frontend/test/: RED ->   S1 lean_frontend/test/ConsumerScoped/ConsumerPlant.lean:2: an instance declaration of the switch-set class (a hidden default)
  REVERTED (real tree):
check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
check_switches_instance: SELFTEST OK (30 plants RED with their labels, unplanted control GREEN, consumer-direction plant P8b (i)-(iii) OK, real tree GREEN)
```

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
`CLAUDE.md`, `VALIDATION.md`, `LADDER.md`) were edited while the run was in progress.

**Re-run on the committed tree** (`de759fb0b`, clean worktree, same lem). Verbatim tail,
12:01 wall, rc 0:

```
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The lanes' own verdict lines, verbatim from the run's evidence directory (deleted at slice
end; the orchestrator re-runs):

```
A2   Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK
A3   Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK
A4   Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK
A4b  Baseline check: 0 regression(s), 0 improvement(s)  /  BASELINE OK
A4c  SUMMARY: exec_match=9 neg_pinned=5 fail=0  /  ALL AT COMMITTED EXPECTEDS
A5   SUMMARY: match=43 diff=0  /  ALL MATCH RECORDED BASELINE
A6   SUMMARY: total=8 match=8 fail=0  /  ALL PASSED
A6b  SUMMARY: total=7 match=7 fail=0  /  ALL PASSED
A7   ALL PASSED
A8   Success rate:   100% (of cerberus successes)  /  ALL PASSED
A9   SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
A10  GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
A11  BASELINE OK (213 entries, exact match)
A12.2 test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
A13  PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls
```

(The two `/`-joined lines per row are the lane's last two output lines; the row labels are
mine.)

- A9 is the reporting-mode C→Core differential. `same=108 diff=5` is the recorded state:
  `docs/2026-10-03_total-arith-and-bookkeeping-record.md:696` has the identical SUMMARY
  line.
- Its 5 DIFF rows are the recorded ones: 073, 074, 098, 112, 113.
- So the default-mode Lean elaboration is unchanged against the unchanged oracle.

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
fuel one.** Their 25 sites in 6 CerberusIris files (derived from grep; corrected by the
pre-merge audit's S5 count finding, 2026-10-06 — an earlier wording said "25 sites in 7
files"). Re-verified read-only on 2026-10-06 at cerberus-sl HEAD `94d38b1` and at `e8b3692`
(identical, `.lake` excluded): `DriverLoop.lean` 3, `PrimOutcome.lean` 7, `PtrEqExamples.lean` 3,
`PtrEqModel.lean` 4, `RoundThread.lean` 4 (line 41 carries TWO `@CerbMem.loadM`), `RunBuild.lean` 4.
The only other `@`-explicit lifted-function occurrence in their tree is the harmless
`probes/capture_probe.lean:4` `#check @frontendTU` (a `#check`, not a site to fix):

- `PtrEqModel.lean:105, 114, 121, 140` and `PrimOutcome.lean:482, 494, 525, 555, 613,
  677, 686`: `@CerbMem.nePtrval inst …`;
- `PtrEqExamples.lean:94, 99, 104`: `@CerbMem.nePtrval ⟨1⟩ default …`, where `default`
  would now be taken as the Switches argument — a type error;
- `RoundThread.lean:41` (two occurrences): `@CerbMem.loadM i₁ …`;
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

## 11. Re-point fc8fbef → 2d3a492 (2026-10-05, still PROVISIONAL)

**MERGE ORDER (pre-merge audit L2, 2026-10-06): DO NOT MERGE this branch until lem-lean
`2d3a492` is on `mdd/lean-backend` and `deps/lem-pinned` plus the shared opam lem are moved
to it (the two-repo pin dance); a re-gate in the standard environment must then be green.**
The same sentence stands beside the LemLib rev in `lean_frontend/lakefile.toml` and in the
fork-drift manifest NOTE.

The orchestrator re-pointed the provisional pin after the lem-lean S0 review fix round.
The work was done by an agent (Claude Opus 5.5) following the orchestrator's re-point brief.
The new pin, `2d3a492758cb23dc4e417f2961983d25b36ce130`, is lem-lean `arc/pnvi-switches`, "Instance readers:
review fixes F1-F7". It adds generation-time refusals (IR-body, IR-inline, IR-type free tyvars,
IR-class last-component aliases), keeps source spacing in the human printers, and adds a test gate
and docs. It is still UNMERGED.

**The lem used.**
- Built the same way as in §1: `git clone --no-hardlinks …/lem-lean .tmp/lem-2d3a492`,
  `git checkout 2d3a492`, then root `make` under `scripts/ce`.
- `lem -v`, verbatim: `Lem lean-backend-v0.1.0-alpha.1-65-g2d3a492` (not `-dirty`; the clone's
  `git status --short` is empty).
- The `.tmp/cel` wrapper now points at this clone (PATH + `LEMLIB`). `.tmp/lem-fc8fbef` is deleted.
  The lem-lean worktree's binary, `deps/lem-pinned` and the shared opam switch were not used or touched.
- `git diff --stat fc8fbef 2d3a492 -- lean-lib library` is empty, so LemLib and lem's library
  are unchanged.

**Pin sites**, all moved to `2d3a492758cb23dc4e417f2961983d25b36ce130`:
- `lean_frontend/lakefile.toml`: the rev, plus a re-point comment;
- the three lake-manifests, through capped `lake update LemLib` in each package (offline through
  `deps/gitconfig`; only the rev/inputRev lines changed);
- `scripts/fork_drift_manifest.txt` `[meta] lem-pin`, with a dated NOTE that amends the
  provisional-pin NOTE (no `--refresh`);
- `lean_frontend/README.md`: the opam pin command and the NOTICE/LICENSE links;
- the "Lem pin has since moved" parentheticals of `README.md`, `CLAUDE.md`, `SUPPORTED.md`, `TODO.md`
  and `VALIDATION.md`.

```
check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
```

**Byte-identity.** Before the re-point, both generated trees (made with lem `fc8fbef`) were copied
aside. Both were then regenerated with lem `2d3a492` (`make clean-prelude-src && make prelude-src`;
`make lean-prelude-src`). Verbatim, `diff -r` of each pre-copy against the regenerated tree printed
nothing, and then:

```
LEAN_GENERATED_BYTE_IDENTICAL
OCAML_GENERATED_BYTE_IDENTICAL
```

That covers 221 and 86 files respectively. The lem-sync generated hashes are unchanged:
OCaml `gen c1bb429a…`, Lean `gen aa49e3bf…`.

**Rebuild.**
- OCaml, cache-disabled: `DUNE_CACHE=disabled dune build --force backend/driver/main.exe
  cerberus-lib.install`, `dune install --prefix _build/local-install cerberus-lib`, and
  `dune build --force cerberus.install`. rc 0.
- Native objects: `scripts/capped make lean-native-obj`, rc 0 (capped this time).
- Lean: `scripts/capped lake build` in `lean_frontend` (397 jobs) and in `speclab` (148 jobs). Both rc 0.

**Row 1** (`scripts/test_unit.sh`, rc 0, 6:23 wall). Verbatim selected verdict lines:

```
Total: 16 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance of CerbGlobal.Switches; the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
```

**Tier A** (`python3 scripts/release.py --mode fast`, rc 0). This ran on the re-pointed tree
before this section and the commit were written. Verbatim tail:

```
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Every row PASSED: A1 to A13, including A4b, A4c, A6b, A12.1 and A12.2. The lane verdict lines
are identical to §7.1's. A9 is again `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0`,
with the same 5 DIFF rows (073, 074, 098, 112, 113). The evidence directory is scratch and was
deleted at slice end.


## 12. Pre-merge audit fix round (2026-10-06)

Approval: [USER 2026-10-06] "Yes, sounds good, go ahead". That was the operator's answer to the
orchestrator's [AGENT] proposal to fix L1–L4 and the S5 count now (scripts and docs only,
re-gated with row 1 + Tier A) and to defer L5 to slice S4. Worker: Claude Opus 5.5 (agent). Scripts and docs only — no Lean
source, generated code or `.lem` changed, so row 1 + Tier A is the re-gate.

| Finding | Disposition |
|---|---|
| L1 the instance gate can be evaded; P8b vacuous | FIXED — §4.1a (whitelist S7, aliases S4, `extends` S5, alias/value instances S6, S2 widened, S3 position-based incl. `where`/multi-line, explicit prod/test root table; P8b (i)–(iii); 23 plants each RED with its label; residual limit stated) |
| L2 no explicit merge-order sentence | FIXED — §1, §11, the `lakefile.toml` comment beside the LemLib rev, the fork-drift manifest NOTE |
| L3 "the last is PROVISIONAL" reads as `4e70bb5` | FIXED — `README.md`, `CLAUDE.md`, `SUPPORTED.md`, `TODO.md`, `VALIDATION.md` now read "(via `77ad4fa` and `4e70bb5`, both merged; the current pin `2d3a492` itself is PROVISIONAL — …)" |
| L4 `gen_fuel_parametricity.py` | FIXED — selftest plant E1 for the fail-closed `emit()` branch ("worker binds [X] which its wrapper does not") + an emit-side control and `--emit` on the real tree; the module and `wrappers()` docstrings describe the worker-binder text and the in-order, by-class instance arguments (the stale boolean "worker-carries-fuel" wording is gone) |
| S5 count | FIXED — §9: 25 sites in 6 CerberusIris files (`RoundThread.lean:41` has two); the 7th file is only `probes/capture_probe.lean:4 #check @frontendTU`. Re-verified read-only (`.lake` excluded) at cerberus-sl `94d38b1` and `e8b3692`, identical |
| L5 CLI diagnostics and cites | DEFERRED to S4 (the [AGENT] proposal the operator answered "Yes, sounds good, go ahead", 2026-10-06) — below |

**L5, deferred to slice S4 (in the orchestrator's [AGENT] proposal approved by [USER 2026-10-06] "Yes, sounds good, go ahead").** Three items:

1. the generic "unknown flag" text under `--parse-core`, or with `--switches` before `--batch`;
2. a repeated unknown switch name labelled "override";
3. inconsistent `main.ml` cites: the `is_CHERI` doc says `:130-136`, `Main.lean:1422` says
   `:133-140`, the actual span is `main.ml:134-137`.

Decision [AGENT]: the two cite fixes of item 3 are comment-only, but they sit in
`CerbGlobal.lean` and `Main.lean`, hand-written seams compiled into the binary (the sync gate
copies them into `generated/`), so editing them is a rebuild-relevant change. This round is
scripts-and-docs only, so they are left for S4 together with items 1 and 2.

`gen_fuel_parametricity.py --selftest`, verbatim (final tree of this round):

```
gen_fuel_parametricity: SELFTEST — planting on scratch copies of generated/Driver.lean (loud plant banner; nothing in the tree is touched)
  PLANT OK   [G1 new multi-line wrapper (strict pattern)] rc=1 -> gen_fuel_parametricity: FAIL — fuel'd wrapper(s) in the tree with NO parametricity pin in TotalityProofTest.lean: plantG1
  PLANT OK   [G2 RHS broken over lines] rc=1 -> Driver.lean:2874: `LemFuel.fuel` outside the right-hand side of any counted wrapper (a wrapper in a shape the strict pattern does not read?)
  PLANT OK   [G3 double space in the RHS] rc=1 -> Driver.lean:2872: `LemFuel.fuel` outside the right-hand side of any counted wrapper (a wrapper in a shape the strict pattern does not read?)
  PLANT OK   [G6 attribute before def] rc=1 -> Driver.lean:2872: `LemFuel.fuel` outside the right-hand side of any counted wrapper (a wrapper in a shape the strict pattern does not read?)
  PLANT OK   [G7 RHS in parentheses] rc=1 -> Driver.lean:2872: `LemFuel.fuel` outside the right-hand side of any counted wrapper (a wrapper in a shape the strict pattern does not read?)
  PLANT OK   [G8 counted wrapper inside a block comment] rc=1 -> Driver.lean:2873: counted wrapper plantG8 has no `LemFuel.fuel` outside comments
  PLANT OK   [control: unplanted scratch copy] rc=0 -> gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
  PLANT OK   [E1 worker binds an instance class its wrapper does not] rc=1 -> gen_fuel_parametricity: Driver: worker plantE1_lemFuel binds [CerbGlobal.Switches], which its wrapper does not (fail-closed)
  PLANT OK   [emit control: unplanted scratch copy] rc=0 -> -- 14 ambient wrappers (generated by scripts/gen_fuel_parametricity.py --emit from the generated tree; scripts/gen_fuel_parametricity.py --check pins this SET in test_unit.sh)
  REVERTED (real tree):
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
gen_fuel_parametricity: --emit on the real tree OK (14 examples)
gen_fuel_parametricity: SELFTEST OK (6 --check plants + 1 --emit plant with the declared FAIL, both unplanted controls OK, real tree OK)
```

**Gated tree.** Both gates ran on commit `f028a3f48c4c3033b899d7f5a1a39ad7222f3af8` (the
fix-round commit before this record-only amend; the amend adds only this paragraph and the
two blocks below to this record — no script, doc, lakefile or manifest byte differs), with
this worktree's private lem `2d3a492` first on `PATH` (`.tmp/cel`), not the standard
environment (L2: the standard-environment re-gate comes after the pin dance).

Row 1 (`.tmp/cel ./scripts/test_unit.sh`, rc 0). Verbatim selected verdict lines (each
distinct line once; the `rc=` line is the wrapper's):

```
Total: 16 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
check_switches_instance: SELFTEST OK (23 plants RED with their labels, unplanted control GREEN, consumer-direction plant P8b (i)-(iii) OK, real tree GREEN)
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
gen_fuel_parametricity: SELFTEST OK (6 --check plants + 1 --emit plant with the declared FAIL, both unplanted controls OK, real tree OK)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
rc=0
```

Tier A (`.tmp/cel python3 scripts/release.py --mode fast`, rc 0). Verbatim row verdicts (the 17
per-row `PASSED` lines joined onto one line — the joining is mine) and
tail:

```
PASSED A1 (455.8s) PASSED A2 (36.0s) PASSED A3 (89.1s) PASSED A4 (26.6s) PASSED A4b (53.3s) PASSED A4c (8.2s) PASSED A5 (220.8s) PASSED A6 (12.9s) PASSED A6b (13.9s) PASSED A7 (37.2s) PASSED A8 (28.2s) PASSED A9 (63.5s) PASSED A10 (52.3s) PASSED A11 (182.7s) PASSED A12.1 (7.9s) PASSED A12.2 (7.0s) PASSED A13 (2.1s)
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```


## 13. Delta-audit fix round (2026-10-06)

Approval: [USER 2026-10-06] "Yes, do (1) as recommended". Option (1) was the orchestrator's
[AGENT] recommendation: fix B-1 and B-2, re-gate with row 1 + Tier A, then a quick delta
review. Worker: Claude Opus 5.5 (agent). Scripts and docs only. No Lean source, generated
code or `.lem` changed.

| Finding | Disposition |
|---|---|
| B-1 (medium) the instance gate is evadable in test roots | FIXED — §4.1b (commands by keyword at any indentation; S1 by head with no window/blank-line cut AND by W5-in-`instance` in every root; names collected at any indentation; S8 bans untyped instances and instance attributes in every root; 7 new plants, 30 in all; residual limit restated in the header, §4.1a and the VALIDATION.md row) |
| B-2 (provenance) §12 tagged a paraphrase [USER] | FIXED — §12 now quotes [USER 2026-10-06] "Yes, sounds good, go ahead" and labels the proposal it answered as the orchestrator's [AGENT] proposal; the two "(operator 2026-10-06)" attributions of the L5 deferral and §4.1a's "[AGENT, within the operator's 2026-10-06 approval]" now cite the same quote. I grepped this record for every other [USER] tag: the only one is §0's, and it is verbatim (it matches the design record §1.4, line 126) |


Files changed: `scripts/check_switches_instance.sh` (logic, plants, header), this record (§4.1a
residual bullet + approval cite, the new §4.1b, §12 provenance, §13), `lean_frontend/VALIDATION.md`
(the gate's row: S1/S6/S8, 30 plants, the residual limit) and `lean_frontend/CLAUDE.md` (the
gate's one-line summary: 30 plants, S8).

**Gated tree.** Row 1 and Tier A both ran on commit `e43c0d59de0ed626cb5a6a623eb394f22a8a9316`,
the fix-round commit before this record-only amend. The amend adds only this paragraph and the
two blocks below to this record; no script, doc, lakefile or manifest byte differs. Both runs
used this worktree's private lem `2d3a492` first on `PATH` (`.tmp/cel`), not the standard
environment (L2: the standard-environment re-gate comes after the pin dance). The selftest in
§4.1b ran on the same script bytes.

Row 1 (`.tmp/cel ./scripts/test_unit.sh`, rc 0). Verbatim selected verdict lines (each
distinct line once; the `rc=` line is the wrapper's):

```
Total: 16 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_switches_instance: OK (367 files scanned: 293 production, 39 test, 35 LemLib; no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; 1 test-side named value(s); the one entry instance is Main.lean's letI; 109 generated [CerbGlobal.Switches] binders)
check_switches_instance: SELFTEST OK (30 plants RED with their labels, unplanted control GREEN, consumer-direction plant P8b (i)-(iii) OK, real tree GREEN)
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
gen_fuel_parametricity: SELFTEST OK (6 --check plants + 1 --emit plant with the declared FAIL, both unplanted controls OK, real tree OK)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
rc=0
```

Tier A (`.tmp/cel python3 scripts/release.py --mode fast`, rc 0). Verbatim row verdicts (the 17
per-row `PASSED` lines joined onto one line — the joining is mine) and tail:

```
PASSED A1 (675.4s) PASSED A2 (31.6s) PASSED A3 (74.6s) PASSED A4 (23.9s) PASSED A4b (25.7s) PASSED A4c (3.3s) PASSED A5 (105.5s) PASSED A6 (4.1s) PASSED A6b (3.8s) PASSED A7 (11.2s) PASSED A8 (9.6s) PASSED A9 (17.9s) PASSED A10 (18.7s) PASSED A11 (62.2s) PASSED A12.1 (5.6s) PASSED A12.2 (4.6s) PASSED A13 (1.5s)
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

A9 is again `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0` (from the run's A9
stdout). The evidence directory is scratch and was deleted at the end of the slice.

## 14. Proportionality revision (2026-10-07)

Rulings, verbatim:

- [USER 2026-10-07] "This sounds like a classic case of 'gate cruft' - we don't want our gates
  to be adversarially robust unless they are trust surfaces. Can you revisit and figure out what
  is actually proportionate?"
- On the orchestrator's proposal: [USER 2026-10-07] "Great, go ahead as proposed".

The proposal it approved was the orchestrator's [AGENT] assessment: "no `CerbGlobal.Switches`
instance in our tree" is a discipline point, not a trust property. `Main` supplies the set with
`letI`, and Lean prefers a local instance over any global one, so a stray library instance cannot
change what any lane runs or validates. The only risk is an accidental instance that a consumer
silently picks up because it forgot its own; cerberus-sl declares its own. The precedent is
`scripts/check_no_fuel_numerals.sh`, which handles the identical `LemFuel` concern with the
simple text pattern F2 and a couple of plants.

Worker: Claude Opus 5.5 (agent). What changed:

- **Withdrawn as gate cruft:** the elaborate instance gate `scripts/check_switches_instance.sh`
  (rules S1–S8, 30 plants plus the consumer-direction plant P8b; §4.1, §4.1a, §4.1b) is
  DELETED, together with its row-1 wiring in `scripts/test_unit.sh`, its LADDER.md row-1 mention
  and its VALIDATION.md row.
- **Replacement:** one plain-text rule, **W1**, in `scripts/check_no_fuel_numerals.sh`, over that
  script's existing comment-stripped roots (seams, `generated/`, `test/`, `speclab/`,
  `tests/**/*.lean`): an `instance` declaration whose same-line header names `Switches` is RED.
  The pattern is `(^|[^A-Za-z0-9_.])instance\b[^:]*:[^=]*\bSwitches\b`. Main.lean's
  `letI : CerbGlobal.Switches := …` is not an `instance` declaration, and its line is allowlisted
  anyway. A cheap vacuity guard was added in that script's style: `class Switches` must be seen in
  the scan set [AGENT]. Three plants were added to `--selftest`: an instance in a seam
  (`CerbND.lean`), one in the generated tree (`generated/Utils.lean`, `where` form) and a
  `local instance` in a unit test (`test/Unit/FuelExemplar.lean`). The selftest total is now 29.
  The script's shared failure line now reads "forbidden shape found" instead of "fuel numeral
  shape found", since W1 is not a fuel shape [AGENT].
- **Scope, stated plainly** in the script header, the VALIDATION.md row, `lean_frontend/CLAUDE.md`
  and `scripts/test_unit.sh`: W1 is a speedbump against accidental default `CerbGlobal.Switches`
  instances. It is not adversarially robust. The backstop is that Main's local instance wins for
  every lane, plus review.
- **Doc comment** on `class Switches` (`lean_frontend/CerbGlobal.lean`): "Never declare an
  instance of this class in this repository; the entry point (`Main`) supplies it with `letI`;
  consumers declare their own." The comments in `CerbGlobal.lean`, `Main.lean` and
  `test/Unit/FuelExemplar.lean` that cited the deleted script now cite rule W1. These are
  comment-only Lean changes, copied to `generated/` by the hand-written copy manifest. The
  handwritten-sync gate is green, and Lean was rebuilt, capped.
- **Out of scope by design, not fixed.** The delta-review findings on §4.1b: F1 (a raw-string
  desync of the comment stripper), F2 (a `_`-typed instance) and N1 (the residual mismatch
  between the stated and the actual closure). Also the earlier L1 evasions: aliases and
  `extends`. W1 does not catch any of these, by design. A speedbump targets accidents, not
  evasion [AGENT, per the ruling above].
- §4.1, §4.1a and §4.1b each carry a one-line pointer to this section. Their text is unchanged
  history. §12/§13's dispositions of L1 and B-1 ("FIXED") stand as records of those rounds; this
  section supersedes them.
- Everything else from the earlier rounds is kept as it was: the DO-NOT-MERGE lines, the wording
  fixes, the S5 count, the provenance fixes and the `gen_fuel_parametricity.py` E1 plant.

**Gated tree.** The `--selftest`, row 1 and Tier A all ran on commit
`8633917a06fc02288f5677341f910642ea4dc081`, the revision commit before this record-only amend
(the selftest ran on the working tree just before that commit, with byte-identical script and
Lean files). The amend adds only this paragraph and the three blocks below to this record; no
script, Lean, doc, lakefile or manifest byte differs. Every run used this worktree's private lem
`2d3a492` first on `PATH` (`.tmp/cel`), not the standard environment (L2: the
standard-environment re-gate comes after the pin dance).

`scripts/check_no_fuel_numerals.sh --selftest` (rc 0), verbatim tail (the `rc=` line is the wrapper's;
row 1 below re-ran the same selftest on the commit itself, with the same verdict line):

```
  PLANT OK   [W1 local switch-set instance in a unit test] -> check_no_fuel_numerals: FAIL (W1): forbidden shape found:
  KNOWN GAP  [M2 E5 indirection via a non-fuel-named constant] -> stays GREEN (not regex-closable; review discipline + the [LemFuel] typing backstop)
  REVERTED (unplanted scratch copy):
  check_no_fuel_numerals: OK (332 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3), no switch-set instance declaration (W1); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
check_no_fuel_numerals: SELFTEST OK (29 plants red with the declared label — F1-F6, A1-A3 and W1; E5 indirection a recorded known gap; unplanted set green)
rc=0
```

Row 1 (`.tmp/cel ./scripts/test_unit.sh`, rc 0). Verbatim selected verdict lines (each
distinct line once; the `rc=` line is the wrapper's). No `check_switches_instance` line appears:
the gate is gone:

```
check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
Total: 16 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_no_fuel_numerals: SELFTEST OK (29 plants red with the declared label — F1-F6, A1-A3 and W1; E5 indirection a recorded known gap; unplanted set green)
check_no_fuel_numerals: OK (332 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3), no switch-set instance declaration (W1); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
gen_fuel_parametricity: SELFTEST OK (6 --check plants + 1 --emit plant with the declared FAIL, both unplanted controls OK, real tree OK)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
rc=0
```

Tier A (`.tmp/cel python3 scripts/release.py --mode fast`, rc 0). Verbatim row verdicts (the 17
per-row `PASSED` lines joined onto one line; the joining is mine) and tail:

```
PASSED A1 (358.1s) PASSED A2 (32.8s) PASSED A3 (75.1s) PASSED A4 (24.8s) PASSED A4b (25.6s) PASSED A4c (3.3s) PASSED A5 (108.2s) PASSED A6 (4.2s) PASSED A6b (3.8s) PASSED A7 (11.3s) PASSED A8 (9.9s) PASSED A9 (18.5s) PASSED A10 (19.2s) PASSED A11 (63.0s) PASSED A12.1 (5.2s) PASSED A12.2 (4.8s) PASSED A13 (1.6s)
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

The evidence directory is scratch and was deleted at the end of the slice.
