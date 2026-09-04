# Fuel-parameter arc, cerberus half, slice C1 — record (2026-09-04)

Branch `arc/fuel-parameter-cerberus` (worktree
`worktrees/cerberus-lean-arc/zero-discrepancy`), base mainline
`mdd/cerberus-lean` @ `1b57bcf26`. Worker [AGENT] (the C1 worker); every
decision below is [AGENT] unless marked; every quoted output is verbatim
from this tree (derived tallies are labelled). Consumer manifest:
`2026-09-04_fuel-parameter-C1-change-manifest.md`. Lem side: lem-lean
`mdd/lean-backend` @ `742506d` (`deps/lem-pinned` = opam `lem` = the
same commit — the pin dance's lem-lean half, done by the orchestrator
before this slice). Nothing merged, nothing pushed.

## 0. Summary — READ THIS FIRST

- Two passes. PASS 1 (lem `742506d`): the pin bump was BLOCKED at the
  mainline sources by four lem refusals the brief had not anticipated —
  the three fuel'd equalities used as `Eq` instance methods
  (`ctype.lem:183` `ctypeEqual`, `core.lem:91` `eq_core_base_type`,
  `defacto_memory_aux.lem:38` `fake_mem_value_eq`) and the `monStep`
  indreln rule (`cmm_op.lem:580`); the whole change set was built and
  measured on a SCRATCH tree and parked uncommitted on
  `wip/fuel-parameter-C1-scratch` (`b0f718eda`, kept as history). §2.3
  keeps that measurement. PASS 2 (lem `ecf75b4`, the D2 enablers:
  backend-derived `t.lemSize` structural sizes, `lemSize x` fuel
  measures, fuel-lifted `inductive R [LemFuel]`): the REAL tree generates
  with THREE one-line Lean-only `fuel_measure` declares and nothing for
  `monStep`; the three sufficiency obligations are proved by hand
  (§3.5); every gate and the whole battery run on the real, stamped tree
  (§5, §11). The scratch evidence is superseded wherever this record says
  "real tree".
- The OCaml generated tree is BYTE-IDENTICAL to the pre-arc (lem
  `3c88f0d`) snapshot after every `.lem` edit (§2.2) — and so is the
  oracle BINARY (`bin 4b00af5c…` from two independent cache-disabled
  builds).
- Seams (§3): `driverFuel`, `ndDefaultFuel`, the nine hand-written
  `_zero` duplicates, the budget pins and the `drive_lemFuel` mirror are
  DELETED; `runND`/`runND1`/`runND1Trace`, `CerbCall.driveCall`, 12
  `CerbMem` wrappers + 4 workers + 21 further entries and
  `Main.runPipeline`/`frontendTU`/`loadLibc` take `[LemFuel]`; `--fuel N`
  (default `defaultFuel = 100000000`, the ONE numeral) builds the
  instance once; 19 `mem.lem` reps are `fuel_consumer`; `ctypeEqual`,
  `eq_core_base_type`, `fake_mem_value_eq` are MEASURED (fuel-free for
  callers, kernel-computable; §3.5).
- Gates/tests (§4): `totality-proof-test` = fuel parametricity for all 64
  ambient wrappers (∀ n, rfl); `FuelExemplar` over `@drive ⟨fuel⟩`
  (∀ fuel; a Lean 4.32.2 finding on div/mod folding at a symbolic fuel,
  §4.3); NEW gates `check_no_fuel_numerals.sh` (F1–F6, 13 plants) and
  `check_lakefile_roots.sh` (3 plants), both in `test_unit.sh`; the axiom
  gate's FUEL leg re-pinned (31 names incl. the 3 obligations).
- Battery on the real tree at the default fuel (§11): ZERO baseline
  movement, Tier A + Tier B, the plant batteries included; the design's
  own csmith test agrees with the oracle at the default and at 10^9.
- Commits: §12.

## 1. Rulings in force (verbatim, as relayed by the orchestrator)

[USER 2026-09-03/04]: fuel "is an execution parameter that 'doesn't
matter' … a parameter which can be chosen as 10^8 or any other value
when calling the interpreter"; "Any and all magic values that are
hardcoded and can't be quantified over are definitionally bugs (unless
they mirror lem or ISO-C design choices)"; "we don't change the lem
structure for ocaml" — cerberus's `.lem` BODIES are not restructured
(Lean-only declares are fine); the semantics is a reasoning artifact for
the consumer (refined-cerberus consumes `drive` in-process). Zero
Lean-vs-oracle execution discrepancies is the standing rule; fuel
exhaustion is the accepted resource exception because the fuel is the
caller's.

## 2. Pin bump

### 2.1 Pin evidence

- opam (done before the slice by the orchestrator): `lem -v` → `Lem
  742506d`; `opam show --switch=. lem -f source-hash` →
  `742506d49ef92abb1ccbd7107c1fe9695b3612a6`.
- Lake: `lean_frontend/lakefile.toml` `rev` `3c88f0d7…` →
  `742506d49ef92abb1ccbd7107c1fe9695b3612a6` (comment records the bump);
  `lake update LemLib` (capped, `CERB_MEM_MAX=32G`) in `lean_frontend`,
  verbatim: `info: LemLib: URL has changed; deleting
  '…/lean_frontend/.lake/packages/LemLib' and cloning again` / `info:
  LemLib: cloning https://github.com/OathTech/lem-lean` / `info: LemLib:
  checking out revision '742506d49ef92abb1ccbd7107c1fe9695b3612a6'`;
  then in `lean_frontend/speclab` and `tests/mem-scale-probes/micro`
  (shared package store; `info: toolchain not updated; already
  up-to-date`). All three `lake-manifest.json` now read `"rev":
  "742506d49ef92abb1ccbd7107c1fe9695b3612a6"` / `"inputRev":
  "742506d49ef92abb1ccbd7107c1fe9695b3612a6"`.
- Two-repo invariant: lem-lean `mdd/lean-backend` head = `deps/lem-pinned`
  HEAD = opam source-hash = the three Lake `rev`/`inputRev` = `742506d`.

### 2.2 The refusal, the deletion, the OCaml byte-identity proof

Pre-bump snapshot: `ocaml_frontend/generated` (86 files) + stamp, verified
`check_lem_sync: OK (src 4f2e089b39d5b371973513b3350f81d1b89871976f77df9ba4a25da3421d0c54,
gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)`,
copied to `.tmp/prebump/` (also `sibylfs/generated`).

`make lean-prelude-src` on the unmodified sources with lem `742506d`,
verbatim (lem stops at the first syntax error; the four driver.lem lines
carry the same form):

```
File "frontend/model/nondeterminism.lem", line 574, character 1 to line 574, character 43
  Syntax error: the numeric fuel-budget form 'declare {lean} fuel val f = N' was removed (fuel-parameter arc, 2026-09-04): a per-declaration fuel literal is a magic value -- [USER 2026-09-03] "any and all magic values that are hardcoded and can't be quantified over are definitionally bugs"; fuel is a parameter of the generated code (the [LemFuel] instance), chosen by the caller at the entry point. Keep only the sentinel form: declare {lean} fuel val f = `sentinel`
make: *** [Makefile:352: lean-prelude-src] Error 1
```

Deleted: `frontend/model/driver.lem:1910-1918` (the 5-line "FUEL arc
budget commit" comment + the four `declare {lean} fuel val X = 100000000`
lines for `print_eval_conv_aux`, `drive_nonmemory_steps_aux2`, `driver2`,
`hack`) and `frontend/model/nondeterminism.lem:569-574` (the 5-line
comment + `declare {lean} fuel val nd_bind = 100000000`). The comments
went WITH the declares: a `{lean}` declare swallows the comment before it
on the OCaml target (lem fuel-parameter record §6.2's quirk), so keeping
the comment would have moved OCaml text. The sentinel declares on the
same five vals stay.

`rm -rf lean_frontend/generated && make clean-prelude-src prelude-src`
with lem `742506d`, verbatim: `check_lem_sync: recorded
ocaml_frontend/lem_sync.sha256 (src 59093551d4cefefccc0d1920d9885ab65a17c924c8c27fe93427b93490609cf8,
gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)` —
the `gen` hash is UNCHANGED; `diff -rq .tmp/prebump/ocaml_generated
ocaml_frontend/generated` printed nothing: `OCAML GENERATED TREE
BYTE-IDENTICAL (86 files)`; `SIBYLFS GENERATED BYTE-IDENTICAL`. After the
19 `fuel_consumer` declares were added to `mem.lem` (§3.4) the same
check: `check_lem_sync: recorded … (src 7f149c25aba15c14a9281a67c54a606ab34aff67bc17accb92ae6c0f206047b1,
gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)` /
`OCAML GENERATED TREE BYTE-IDENTICAL after mem.lem fuel_consumer declares`.

Oracle rebuilt cache-disabled (`DUNE_CACHE=disabled build_cerberus`):
`check_driver_fresh: recorded oracle stamp (bin 4b00af5cab3dd39f88de3140f358fbe4dc9a0ae6227ffb4dc5dde3dbb48e808c,
src 372e7bb86c88d37cb6221b5689b1b53d4391b4302b6701545277924ff97a1779)`.
NOTE on the brief's "the oracle binary's SOURCE hash must be unchanged":
that stamp's source set INCLUDES `frontend/**/*.lem`
(`tools/check_driver_fresh.sh` `oracle_src_hash`), so it MOVES whenever a
`.lem` line moves — by construction, not as a finding (it was
`c9c1a706…` at the previous bump). The invariant that holds and matters
is the generated tree's byte identity + the unchanged lem-sync `gen`
hash above; the oracle binary hash moved (`b364239e…` → `4b00af5c…`)
because the fresh cache-disabled dune build relinks — the OCaml SOURCES
it compiled are byte-identical.

### 2.3 PASS 1 — four more refusals at lem `742506d` (measured, not predicted; RESOLVED in pass 2, §2.5)

With the five lines deleted, `make lean-prelude-src` refuses again,
verbatim:

```
File "frontend/model/ctype.lem", line 183, character 14 to line 183, character 23
  Error: Lean backend: fuel'd (or fuel-lifted) call inside an instance method (unsupported: instance fields cannot take the [LemFuel] binder)
  original input: "ctypeEqual"
make: *** [Makefile:352: lean-prelude-src] Error 1
```

The cascade was measured on scratch copies of `frontend/` (`.tmp/scratch/cascade.sh`;
each stage adds the lem-lean dry-run patch for the previous refusal —
structural-declare record §6 "D2 demonstration": the `List.all (uncurry
…) (zip …)`/`listEqualBy` traversal rewritten as an explicit sibling and
both declared `structural`; the `monStep` rule removed), first error
line per stage (verbatim, condensed):

| stage | sources | lem exit | first refusal |
|---|---|---|---|
| S0 | worktree `frontend/` (numeric declares deleted, nothing else) | 1 | `ctype.lem:183` `ctypeEqual` — "fuel'd (or fuel-lifted) call inside an instance method" |
| S1 | + `ctype.lem` sibling rewrite | 1 | `core.lem:91` `eq_core_base_type` — same message |
| S2 | + `core.lem` sibling rewrite | 1 | `cmm_op.lem:580` `monStep pre y` — "fuel'd (or fuel-lifted) definition referenced outside a fuel scope — an application — where no [LemFuel] instance is in scope (instance methods, indreln rules, lemmas/asserts cannot take the ambient fuel …)" |
| S3b | + `monStep` rule removed (dma NOT patched) | 1 | `defacto_memory_aux.lem:38` `fake_mem_value_eq` — the instance-method message |
| S4 | + `defacto_memory_aux.lem` sibling rewrite = the full scratch patch | 0 | — (193 files generated) |

(`cmm_op.lem` is processed before `defacto_memory_aux.lem`, so S2 and
S3 both stop at `monStep`; S3b isolates the fourth site.) Exactly four
sites; each is a Lean-only refusal (the OCaml target is unaffected by
any of them).

Why none of the four has a sanctioned C1 remedy at lem `742506d`
[AGENT reading of the lem-lean records; the operator decides §9]:
- `fake_mem_value_eq` IS resolvable by the C2 mechanism without any
  `.lem` body change: `declare {lean} fuel_measure val fake_mem_value_eq =
  \`CerbMeasureMem.mvSize mval1\`` (fuel-measure record §6.2 row 54;
  cross-module measure over `impl_mem_value` from `Defacto_memory_types`)
  + the seam `CerbMeasureMem.lean` + the obligation proof module
  `Defacto_memory_aux_lemMeasureProofs.lean`. That is C2 scope (seam +
  obligation proof), pulled forward.
- `ctypeEqual` and `eq_core_base_type` are the SAME-MODULE case
  (fuel-measure record §6.2 rows 9/67, lem-lean TODO row 15): the
  measure must be a computable size over `ctype`/`core_base_type`, types
  defined in the module being generated, so no hand-written Lean module
  can provide it (import cycle) and Lean's `sizeOf` is noncomputable
  (refused, FM-sizeOf). The only mechanisms that work today are the
  sibling rewrite (changes the `.lem` body AND the OCaml text — new
  OCaml functions; forbidden by the R3 ruling and by the brief's
  byte-identity requirement) or a backend change (TODO 15: a
  backend-derived `t_lemSize`; or instance-level `[LemFuel]`, the fuel
  record's D2 option (ii)).
- `monStep`: an indreln premise referencing the fuel-lifted `monStep`
  function; "the indreln rule cannot take a binder at all: the
  concurrency model's problem to restate" (fuel record §9 D2) — a backend
  answer (an `inductive monTrace [LemFuel]`) or a model restatement, both
  outside this slice.

### 2.4 PASS 1 — the scratch tree (development instrument; superseded by §2.5)

`.tmp/scratch/mkscratch.py` copies `frontend/` and applies the S4 patch
with one-hit assertions; `.tmp/scratch/gen.sh` runs the Makefile's
`lean-prelude-src` recipe verbatim on the copy into
`lean_frontend/generated/` and copies the hand-written seams
(`check_handwritten_sync: OK (23 hand-written files …)`), recording NO
Lean lem-sync stamp (the tree is not derivable from `frontend/`;
`tools/check_lem_sync.sh --check-lean` stays RED — §5.1). Every Lean
build, gate and lane below ran on this tree; the three scratch-structural
equalities render `termination_by structural` (verbatim heads in the
structural-declare record §6). The census (derived, `grep`, this tree):
396 `[LemFuel]` binders in 24 generated model modules (+53 in the seams);
64 ambient wrappers `:= f_lemFuel LemFuel.fuel` (67 sentinel declares −
the 3 scratch-structural); 64 generated `theorem f_lemFuel_zero`; 0
`lemDefaultFuel`; 0 literal fuels (§4.4 gate).

### 2.5 PASS 2 — the real tree at lem `ecf75b4`

The D2 enablers (lem-lean `doc/lean-backend/2026-09-04_d2-enablers-record.md`
§2: every recursive block of generated inductives gets a backend-derived
structural size `t.lemSize` in its own module; a `fuel_measure` payload
may read `lemSize x` for a parameter `x`; an indreln block whose premises
reach the ambient renders `inductive R [LemFuel]`). Applied here, exactly
the enablers record's §4.5 checklist:

- `frontend/model/ctype.lem:436` ``declare {lean} fuel_measure val ctypeEqual = `lemSize c` ``,
  `core.lem:477` ``… val eq_core_base_type = `lemSize bTy1` ``,
  `defacto_memory_aux.lem:473` ``… val fake_mem_value_eq = `lemSize mval1` ``
  — each directly after its sentinel declare, each with an explanatory
  comment (swallowed by the following `{lean}` declare on OCaml). Nothing
  for `monStep`: the backend emits `inductive monTrace  [LemFuel]`
  (`Cmm_op.lean`) from the unchanged source.
- opam `lem -v` → `Lem ecf75b4` (`deps/lem-pinned` = `ecf75b4`, moved by
  the orchestrator); `lakefile.toml` `rev` →
  `ecf75b4172b1f5b9838eb8bcda5928c5b05dee9b`; `lake update LemLib` in
  `lean_frontend` (`info: LemLib: checking out revision
  'ecf75b4172b1f5b9838eb8bcda5928c5b05dee9b'`), `speclab`, `micro`; all
  three manifests at that rev.
- `rm -rf lean_frontend/generated && make clean-prelude-src prelude-src`:
  `check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 03c176935c3e37a0f5b9a00192796ddf42dd6bd09ebf3bb3a41c028c25f8f10c,
  gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)`
  — the `gen` hash is the pre-arc one; `diff -rq .tmp/prebump/ocaml_generated
  ocaml_frontend/generated` empty: **`OCAML GENERATED TREE BYTE-IDENTICAL
  (86 files) vs the pre-bump lem 3c88f0d snapshot`**, `SIBYLFS-IDENTICAL`.
- `make lean-prelude-src lean-native-obj`, verbatim tail: `[LEM]
  generating Lean files in [lean_frontend/generated] …` / `[COPY] 23
  hand-written Lean files …` / `check_handwritten_sync: OK (23 hand-written
  files byte-identical to lean_frontend/generated/; …)` / `check_lem_sync:
  recorded lean_frontend/lem_sync.sha256 (src 03c17693…, gen
  d1931404d27d3004cd8305c3d2d7fea770f3da3de075d9dbe168a513f3280ecb)` /
  `[LEANC] compiling lean_frontend/native objects` — generation SUCCEEDS
  on the real sources (22 s). The three measured wrappers, verbatim:
  `Ctype.lean:442: def ctypeEqual (c : ctype) (c0 : ctype) : Bool :=
  ctypeEqual_lemFuel (ctype.lemSize c) c c0`; `Core.lean: def
  eq_core_base_type ( bTy1 : core_base_type) ( bTy2 : core_base_type) :
  Bool := eq_core_base_type_lemFuel (core_base_type.lemSize bTy1)  bTy1
  bTy2`; `Defacto_memory_aux.lean: def fake_mem_value_eq ( mval1 :
  impl_mem_value) ( mval2 : impl_mem_value) : Bool :=
  fake_mem_value_eq_lemFuel (impl_mem_value.lemSize mval1)  mval1  mval2`;
  their `Eq0` instances render `isEqual := ctypeEqual` etc. — NO fuel
  binder, fuel-free for every caller.
- Oracle rebuilt `DUNE_CACHE=disabled`: `check_driver_fresh: recorded
  oracle stamp (bin 4b00af5cab3dd39f88de3140f358fbe4dc9a0ae6227ffb4dc5dde3dbb48e808c,
  src 7c9a3b9dbc6d1cbc124dd986ef3239d5159456128138b3df116e1e77bd210b09)`
  — the SAME binary hash as pass 1's cache-disabled build (`bin
  4b00af5c…`): byte-identical OCaml sources give a bit-identical
  executable; the `src` stamp moves with the `.lem` text by construction
  (§2.2's note).
- Census of the real tree (derived, `grep`, 170 generated model files
  excluding the 26 seam copies): 397 `[LemFuel]` binders (the scratch
  tree's 396 + `monTrace`'s parameter), 64 ambient wrappers
  `:= f_lemFuel LemFuel.fuel`, 3 measured wrappers, 67 generated
  `theorem f_lemFuel_zero` (one per sentinel declare), 147 derived
  `*.lemSize*` definitions, 3 `*_measure_sufficient` obligation theorems
  (in `Ctype_auxiliary.lean:45`, `Core_auxiliary.lean:65`,
  `Defacto_memory_aux_auxiliary.lean:37`, each delegating to
  `<Module>_lemMeasureProofs.<name>_measure_sufficient`), 1 `inductive
  monTrace  [LemFuel]`. The pass-1 full build of this tree failed on
  exactly the three auxiliary shells (`unknown module prefix
  'Ctype_lemMeasureProofs'` etc.) — the fuel-measure slice's fail-closed
  design — and on nothing else; with the proofs (§3.5) the whole tree
  builds: `Build completed successfully (384 jobs).` (lib + driver + the
  6 unit exes), speclab `Build completed successfully (301 jobs).`, micro
  `Build completed successfully (136 jobs).`

## 3. Seams and driver (the lem record §6 work list, re-located at this head)

All cites are the files as edited (`git diff` is the authoritative text).

| # | File / site | Change | Mirrors / contract |
|---|---|---|---|
| 1 | `CerbFuel.lean` | `driverFuel` (10^8) and its doc DELETED; header restated (fuel is the `[LemFuel]` parameter; the deleted constants named). `fuelExhaustedLoc` (opaque, census-pinned) and `fuelExhaustedMsg` unchanged | the atom and message are the exhaustion OUTCOME, fuel-independent |
| 2 | `CerbND.lean` | `ndDefaultFuel` DELETED; `export CerbFuel (fuelExhaustedLoc fuelExhaustedMsg)`; `runND`/`runND1`/`runND1Trace` take `[LemFuel]` and start at `LemFuel.fuel` (workers `runNDFuel`/`runND1Fuel`/`runND1TraceFuel` unchanged); the nine hand-written `*_lemFuel_zero` theorems DELETED — generated: `nd_bind_lemFuel_zero`, `liftND_lemFuel_zero`, `liftAction_lemFuel_zero` (Nondeterminism.lean:194/318/323), `print_eval_conv_aux_lemFuel_zero`, `drive_nonmemory_steps_aux2_lemFuel_zero`, `driver2_lemFuel_zero` (Driver.lean), `find_array_index_lemFuel_zero`, `easy_update_mem_value_aux_lemFuel_zero`, `memcmp_load_aux_lemFuel_zero` (Defacto_memory.lean); NEW `fuelExhaustedKill_eq` (the one-delta bridge to the generated spelling); runner leaves and the two disjointness lemmas kept; `driverFuel_eq` DELETED; `driver2/print_eval_conv_aux/drive_nonmemory_steps_aux2/hack_wrapper_defeq (n) : @X ⟨n⟩ = @X_lemFuel ⟨n⟩ n := rfl`; `nd_bind_wrapper_defeq (n) : @nd_bind a b c d e f ⟨n⟩ = @nd_bind_lemFuel a b c d e f n := rfl` + NEW `liftND_wrapper_defeq`, `liftAction_wrapper_defeq`; `runND_eq/runND1_eq/runND1Trace_eq (n) : @runND a info err cs st ⟨n⟩ m st0 = runNDFuel n m st0 := rfl`; the `DriveMirror` section — `drive_lemFuel` (the hand-written ~10 KB mirror) and `drive_wrapper_defeq` — DELETED: the generated `drive [LemFuel]` (Driver.lean:563) is the fuel-parametric pipeline | consumer-facing rename: `CerbND.drive_lemFuel fuel …` → `@drive ⟨fuel⟩ …` (manifest §2) |
| 3 | `CerbMem.lean` | the 12 `X_lemFuel lemDefaultFuel` wrappers (`memberAlign`, `offsetsofMembers`, `offsetsof`, `sizeofCtype`, `alignofCtype`, `memValueToBytes`, `reconstructValue`, `typeofMval`, `unqualifyAndUnatomic` + the theorems `memValueToBytes_eq_append`, `reconstructValue_eq_indexed`, and `ctypeMemCompatible`) take `[LemFuel]` and read `LemFuel.fuel`; the header comment (line ~323) restated. CASCADE found by the build (each `failed to synthesize instance of type class LemFuel` at a generated copy line mapped to its enclosing def): the hand-written workers `memValueToBytes_lemFuel`, `memValueToBytes_append_lemFuel`, `reconstructValue_lemFuel`, `reconstructValue_indexed_lemFuel` and the theorems `memValueToBytes_lemFuel_eq_append`, `reconstructValue_lemFuel_eq_indexed` (they call the AMBIENT wrappers of their siblings), then `sizeofIval`, `alignofIval`, `offsetofIval`, `arrayShiftPtrval`, `memberShiftPtrval`, `effArrayShiftPtrval`, `effMemberShiftPtrval`, `isWithinDevice`, `isAtomicMemberAccess`, `loadM`, `storeM`, `diffPtrval`, `isWellAlignedPtrval`, `validForDerefPtrval`, and the 7 `nd_bind` hosts `allocateObject`, `allocateRegion`, `nePtrval`, `memcpyM`, `memcmpM`, `reallocM`, `copyAllocId` — 40 `[LemFuel]` binders in the file (derived) | every binder is forced by a fuel'd callee (the build is the fixpoint; nothing was added speculatively) |
| 4 | `frontend/model/mem.lem` | `declare {lean} fuel_consumer val X` for the 19 reps whose `CerbMem` implementations now take `[LemFuel]`: `allocate_object`, `allocate_region`, `load`, `store`, `ne_ptrval`, `diff_ptrval`, `validForDeref_ptrval`, `isWellAligned_ptrval`, `array_shift_ptrval`, `member_shift_ptrval`, `eff_array_shift_ptrval`, `eff_member_shift_ptrval`, `memcpy`, `memcmp`, `realloc`, `copy_alloc_id`, `offsetof_ival`, `sizeof_ival`, `alignof_ival` (one explanatory comment before the first, swallowed by it on OCaml) — the set is exactly `join(CerbMem [LemFuel] defs, mem.lem lean target_reps)`; the first build without them failed closed at `generated/Translation.lean:509: failed to synthesize instance of type class LemFuel` (a generated caller of a rep); with them the fuel lifting added 57 binders (391 → 448 on the tree at that point, derived) | Lean-only declares; OCaml byte-identical (§2.2) |
| 5 | `CerbCall.lean` | `allocErrno`, `callFinish`, `driveCall` take `[LemFuel]` | they use `nd_bind`/`driver2` |
| 6 | `Main.lean` | `def defaultFuel : Nat := 100000000  -- FUEL-DEFAULT (the one allowed fuel numeral)` with its doc; `--fuel N` parsed in the positional scan (same class as `--libc`/`--call`; `["--fuel"]` → "require an argument", exit 1); `0` → `cerberus-lean: refused — --fuel 0: the fuel must be a positive integer (fuel 0 kills at the first bind: never a verdict; see VALIDATION.md, fuel)`, exit 2; non-numeral → `refused — --fuel abc: not a decimal numeral (…default 100000000…)`, exit 2; `refuseFlag`'s accepted-list text gains `--fuel <N>`; `runPipeline`, `frontendTU`, `loadLibc` take `[LemFuel]`; the ONE instantiation: `let code ← (letI : LemFuel := ⟨fuel⟩; runPipeline …)`. Measured on `tests/minimal/001-return-literal.c` (§4.5) | |
| 7 | `speclab/` | `SpecLab/*Files.lean`: 20 `*File`/`*FileOf*` constructors (+ `junkFile`) take `[LemFuel]` (`convert_file [LemFuel]`); the five `SLUnit/*GateTest.lean`: `runFile*`/`checkRun*` take `[LemFuel]`, `main` → `mainAt [LemFuel]` + a new `main (args)` that REQUIRES `--fuel N` (NEW `SLUnit/Fuel.lean` `fuelFromArgs`: absent/0/non-numeral → exit 2); the five `test_speclab_*.sh` pass `--fuel "$CERB_TEST_FUEL"`; `scripts/common.sh` defines `CERB_TEST_FUEL="${CERB_TEST_FUEL:-100000000}"` (a test-suite choice, outside the scanned Lean text — [USER 2026-09-03] "Defaults that are chosen eg. in test suites are fine") | the gate binaries: `CoreGateTest: ALL PASSED` … `SeedGateTest: ALL PASSED` at `--fuel 100000000`; without: `gate test: refused — usage: <gate-test> --fuel <N> …`, rc 2 |
| 8 | `lakefile.toml` | pin (`742506d` in pass 1, `ecf75b4` in pass 2) + comment; the three `*_lemMeasureProofs` roots (row 9) | |
| 9 | `frontend/model/{ctype,core,defacto_memory_aux}.lem` + `lean_frontend/{Ctype,Core,Defacto_memory_aux}_lemMeasureProofs.lean` (NEW, pass 2) | the three `fuel_measure` declares (§2.5) and their obligation proofs (§3.5); `handwritten_copy.manifest` lists the three proof modules; `lakefile.toml` roots gain them (the generated `*_auxiliary.lean` shells import them) | Lean-only; OCaml byte-identical |

### 3.5 The three `fuel_measure` obligation proofs (pass 2; the first three of C2's 38)

Each `<Module>_lemMeasureProofs.lean` proves exactly the theorem the
generated `<Module>_auxiliary.lean` states and delegates
(`ctypeEqual_measure_sufficient (c c0 : ctype) (lemFuel : Nat)
(lemMeasureLe : ctype.lemSize c ≤ lemFuel) : ctypeEqual_lemFuel lemFuel c
c0 = ctypeEqual c c0`, and likewise for `eq_core_base_type` over
`core_base_type.lemSize bTy1` and `fake_mem_value_eq` over
`impl_mem_value.lemSize mval1`). Shape = lem-lean's template
`tests/comprehensive/lean-test/Test_lem_size_lemMeasureProofs.lean`
(`tm_eq`): a fuel-STABILITY lemma by strong induction on the derived size
(`f_lemFuel f x y = f_lemFuel g x y` for every `f, g ≥ lemSize x`), the
child strictly below the parent over the derived list helper
(`ctype_.lemSize_aux1`, `core_base_type.lemSize_aux1`,
`impl_pointer_value.lemSize_aux3`), the traversal congruent in the
per-element function (`List.all` after `LemLibTheorems.lemListZip_eq`;
`listEqualBy` by its own induction), and the obligation as the instance
`f := lemSize x`. Kernel-only tactics (`cases`/`rcases`, `simp only`,
`omega`, `rw`, `congr`); NO option bumps anywhere. Two shapes worth
noting for the 35 to come: the worker's NESTED patterns
(`MVinteger _ (IV _ (IVconcrete n))`, `Function (qs, ty) …`) leave the
matcher stuck until the inner constructors/tuples are exposed
(`rcases … with ⟨⟨q1, t1⟩, ps1, bb1⟩ …`; `cases iv1 <;> cases iv2 <;>
rfl`), and every constructor counts ≥ 1 so the `f = 0` cases are `omega`.
Axiom cones, verbatim from `check_theorem_axioms.sh`'s FUEL leg (the
generated statements and the hand-written proofs both probed):

```
'Ctype_lemMeasureProofs.ctypeEqual_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Core_lemMeasureProofs.eq_core_base_type_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Defacto_memory_aux_lemMeasureProofs.fake_mem_value_eq_measure_sufficient' depends on axioms: [propext, Quot.sound]
'ctypeEqual_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'eq_core_base_type_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'fake_mem_value_eq_measure_sufficient' depends on axioms: [propext, Quot.sound]
```

Grep for the deleted names over `lean_frontend/`, `scripts/`, `tests/`
(excluding `docs/`): zero code occurrences remain (`check_no_fuel_numerals`
F1 covers `lemDefaultFuel|driverFuel|ndDefaultFuel` in the Lean text;
`scripts/check_theorem_axioms.sh`'s list is re-pinned, §4.4).

## 4. Gates and tests

### 4.1 `test/Unit/TotalityProofTest.lean` — fuel parametricity of every wrapper

Part 1 regenerated from the generated tree (`.tmp`-scratch generator
reading every `def f … [LemFuel] : … := f_lemFuel LemFuel.fuel` line and
its worker head): 64 `example`s of the shape `example {a b : Type} [i1 :
Eq0 a] (n : Nat) : @f a b i1 ⟨n⟩ = @f_lemFuel a b i1 n := rfl`, with
`⟨n⟩ n` on the right for the 26 workers that carry the instance
(`driver2`, the substitution family, …). Part 2's wrapper example reads
`@has_ccall a b c ⟨Nat.succ f⟩ (Expr an (Epure pe)) = false := rfl`.
`EffectsProofTest.lean`: `example (n : Nat) : @zeros_aux a ⟨n⟩ =
@zeros_aux_lemFuel a n := rfl`. Both build; `✓ effects-proof-test
PASSED` / `✓ totality-proof-test PASSED`.

### 4.2 `test/Unit/FuelExemplar.lean` — the ∀-fuel theorem over `@drive ⟨fuel⟩`

Restated over `run n := @CerbND.runND _ _ _ _ _ ⟨n⟩ (@drive ⟨n⟩ fmapEmpty
false exemplarFile ["cmdname"]) (@dst₀ ⟨n⟩ 0)` (ONE instance for runner,
pipeline and cold start — Main's shape exactly). Shipped:
`exemplar_certified_shipped_forall (fuel)` (the consumer's §6 shape),
`exemplar_certified_shipped_zero` (fuel 0: the runner leaf),
`exemplar_killed_at_one` (fuel `Nat.succ 0`: the errno allocation's
`liftMem` — `liftND_lemFuel 1` → `liftAction_lemFuel 0` — is the kill,
by `rfl` on the concrete setup prefix). The round library is restated at
a SYMBOLIC positive ambient fuel (`runOne_bind_active {k} … (@nd_bind … ⟨Nat.succ k⟩ …)`,
`runOne_liftMem_active` at `⟨Nat.succ (Nat.succ k)⟩`, `loop_step_done`,
`process_done`, `driver2_done`, `finalize_done` with `@… ⟨Nat.succ k⟩`);
`S₁` is the engine's setup stages composed at the ambient instance
(`driver_globals`, then the errno stage's text and the arena park) and is
CHECKED against the generated `drive` by `drive_after_setup`'s per-bind
`rfl`s. The theorem's proof: `cases fuel` → 0 (leaf) / `Nat.succ 0`
(kill at errno) / `Nat.succ (Nat.succ k)` (setup split + `round_done` +
`finalize_done` → `Specified(42)`). NO heartbeat/maxRecDepth option
anywhere (checked: none in the file). Deleted:
`exemplar_certified_shipped_one` (Active at fuel 1 described the old
split budgets — at one ambient fuel, fuel 1 kills) and the kernel
witness `exemplar_run_one_kernel` (a closed Active instance needs a fuel
≥ 2 written as a numeral in the test text, which the gate forbids; the
∀-theorem's `Nat.succ (Nat.succ k)` case gives the Active result list for
every such fuel symbolically). `✓ fuel-exemplar-test PASSED`.

### 4.3 FINDING (Lean 4.32.2): div/mod do not fold on a symbolic-fuel divisor

Found while restating the exemplar: the errno stage did not evaluate by
`rfl` at a symbolic ambient fuel although every fuel'd function involved
does (`@CerbMem.alignofIval ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty signed_int
= CerbMem.integerIval 4 := rfl` holds). Bisected to the memory model's
`allocator` (`z / align`, `z % align`). Minimal reproducer (scratch probe
`Probe9.lean`, `def f : Nat → Nat | 0 => 0 | _+1 => 4`, `variable (k :
Nat)`), verbatim outcome per line:

```
example : f (Nat.succ k) = 4 := rfl                    -- OK
example : (8 : Nat) / f 5 = 2 := rfl                   -- OK (literal argument)
example : (8 : Nat) / f (Nat.succ k) = 2 := rfl        -- Type mismatch
example : (8 : Nat) / f (k + 1) = 2 := rfl             -- Type mismatch
example : (8 : Nat) % f (Nat.succ k) = 0 := rfl        -- Type mismatch
example : (8 : Nat) - f (Nat.succ k) = 4 := rfl        -- OK
example : (8 : Nat) * f (Nat.succ k) = 32 := rfl       -- OK
example : (8 : Nat) + f (Nat.succ k) = 12 := rfl       -- OK
example : Nat.beq 4 (f (Nat.succ k)) = true := rfl     -- OK
example : (8 : Int) / (f (Nat.succ k) : Int) = 2 := rfl -- Type mismatch
example : (8 : Nat) / f (Nat.succ k) = 2 := by simp [f]              -- OK
example : (8 : Nat) / f (Nat.succ k) = 2 := by show 8 / 4 = 2; rfl   -- OK
```

and, via a `MetaM` probe: `whnf (f (Nat.succ k)) = 4 [isLit=true]` but
`whnf (Nat.div 8 (f (Nat.succ k))) = Nat.div 8 (f k.succ)`, `reduceNat?
= <not-available>` — the `Nat.div`/`Nat.mod` literal folding does not
whnf its arguments, and the (well-founded, irreducible) definitions do
not unfold otherwise. Consequence for proofs at a symbolic fuel: a
divisor that is a fuel'd computation must be rewritten to its value first
(the exemplar's `alignofIval_signed_int` + `rw` before the errno step;
`setupTail` writes the alignment as its value). Consequence for C2: once
the layout family is measured/structural (no fuel counter in
`sizeofCtype`/`alignofCtype`), the divisor is fuel-free again and the
rewrite can go. Not a defect of this repository; recorded for the
upstream tray as a candidate (Lean core) — not filed by this slice.

### 4.4 Gates

- NEW `scripts/check_no_fuel_numerals.sh` (in `test_unit.sh`, selftest
  first): scans `lean_frontend/*.lean`, `generated/*.lean`, `test/**`,
  `speclab/**` (no `.lake`) comment-stripped for F1
  `lemDefaultFuel|driverFuel|ndDefaultFuel`, F2 `instance … : LemFuel`,
  F3 `_lemFuel <positive numeral>` (parenthesised too), F4 `LemFuel :=
  ⟨…⟩` / `LemFuel.mk <num>`, F5 `⟨<numeral>⟩`, F6 a fuel-named
  `def|abbrev|let|letI` defined as a numeral; allowlist by EXACT line
  content in `Main.lean` only: `def defaultFuel : Nat := 100000000` and
  the `let code ← (letI : LemFuel := ⟨fuel⟩; runPipeline …` line (each
  seen twice: hand-written + generated copy); vacuity guards (≥150 files;
  a `_lemFuel` worker seen). Verbatim on the tree: `check_no_fuel_numerals:
  OK (258 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel,
  no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites
  seen: 4 of 4 (hand-written + generated copy))`. Plants
  (`--selftest`, on a scratch COPY of the scan set), verbatim:

  ```
  check_no_fuel_numerals: SELFTEST — planting F1-F6 into a scratch copy of the scan set (loud plant banner; nothing in the tree is touched)
    PLANT OK   [F1 deleted default named in code] -> check_no_fuel_numerals: FAIL (F1): fuel numeral shape found:
    PLANT OK   [F1 deleted driverFuel in a seam] -> check_no_fuel_numerals: FAIL (F1): fuel numeral shape found:
    PLANT OK   [F2 global instance] -> check_no_fuel_numerals: FAIL (F2): fuel numeral shape found:
    PLANT OK   [F2 global instance (where)] -> check_no_fuel_numerals: FAIL (F2): fuel numeral shape found:
    PLANT OK   [F3 worker at a literal fuel] -> check_no_fuel_numerals: FAIL (F3): fuel numeral shape found:
    PLANT OK   [F3 parenthesised literal] -> check_no_fuel_numerals: FAIL (F3): fuel numeral shape found:
    PLANT OK   [F4 LemFuel.mk numeral] -> check_no_fuel_numerals: FAIL (F4): fuel numeral shape found:
    PLANT OK   [F4 letI outside Main] -> check_no_fuel_numerals: FAIL (F4): fuel numeral shape found:
    PLANT OK   [F5 anonymous-constructor literal] -> check_no_fuel_numerals: FAIL (F5): fuel numeral shape found:
    PLANT OK   [F6 fuel-named numeral constant] -> check_no_fuel_numerals: FAIL (F6): fuel numeral shape found:
    PLANT OK   [F6 in a speclab gate test] -> check_no_fuel_numerals: FAIL (F6): fuel numeral shape found:
    PLANT OK   [F6 in a generated copy of Main] -> check_no_fuel_numerals: FAIL (F6): fuel numeral shape found:
    REVERTED (unplanted scratch copy):
    check_no_fuel_numerals: OK (258 files scanned …)
  check_no_fuel_numerals: SELFTEST OK (12 plants red with the declared label; unplanted set green)
  ```

  (Later in the slice the scan set gained `tests/**/*.lean` — F-C1-3 — and a
  13th plant, `F5 in an immaculate Lean probe`; the final line reads `OK (261
  files scanned …)` / `SELFTEST OK (13 plants …)`.) (Before the exemplar was rewritten the gate correctly flagged the old
  file's `budget_succ : CerbFuel.driverFuel = …` (F1) and `drive_lemFuel
  1` (F3) — a live catch on the way, not a plant.)
- NEW `scripts/check_lakefile_roots.sh` (in `test_unit.sh`, selftest
  first; lem fuel-measure record §6.4 item 8 / audit M5): every
  `generated/*.lean` except the exe root `Main` is a root of the
  `CerberusLean` lib and every root exists. Verbatim:
  `check_lakefile_roots: OK (192 roots = 192 generated modules + the exe
  root Main; 85 auxiliary modules all built)`; plants: `PLANT OK
  [dropped root Core_aux_auxiliary] -> check_lakefile_roots: FAIL —
  generated module(s) NOT a Lake root (their obligations would never
  build):` / `PLANT OK [phantom root Phantom_auxiliary] -> … FAIL — Lake
  root(s) with no generated module:` / `PLANT OK [unrooted generated
  Orphan_auxiliary] -> …` / `check_lakefile_roots: SELFTEST OK (3
  plants red, baseline green)`.
- `scripts/check_theorem_axioms.sh` FUEL leg re-pinned: the 9 GENERATED
  `_zero` names (root namespace) + `CerbND.fuelExhaustedKill_eq` + the
  runner leaves + disjointness + the 10 parametricity pins + the 3
  exemplar theorems + (pass 2) the 3 obligation statements and their 3
  proofs (34 names; the probe imports the three `*_auxiliary` shells; `drive_lemFuel`, `driverFuel_eq`,
  `drive_wrapper_defeq`, the deleted exemplar instances out). Verbatim:
  `check_theorem_axioms: FUEL arc leg OK (28 contract lemmas — 9 generated
  _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel
  exemplar and its instances, every cone ⊆ [propext, Classical.choice,
  Quot.sound])`; the other legs unchanged: `generated-tree census OK (193
  files: 0 axioms, boundary-opaque population = the 26 registered rows
  exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)`, `C2
  ratchet OK (295 files scanned recursively: 0 axioms, 0 runEffectful,
  seam population = the 66 pinned path-qualified counted rows exactly …)`
  (291 → 295 files: the LemLib copy at `742506d` — no re-pin needed, the
  counts are not pinned), `C2 entry census OK (9 entries …)`, `mem-scale
  S1 leg OK (6 …)`.
- `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND,
  0 allowlisted)`; `check_exec_purity: CLEAN (11 modules)`;
  `check_sorry_token: OK (256 files scanned comment-stripped — generated
  193, hand-written+test 29, LemLib 34; 0 sorry tokens)`;
  `test_fuel_classifier: 18 fixtures, ALL OK`. No ratchet population moved
  (the opaque census 26, the seam population 66, the entry set 9: all
  unchanged — nothing to re-pin).
- `scripts/test_fuel_plant.sh`: NEW leg — the REAL driver through a
  `CERB_LEAN_BIN_OVERRIDE` stub that splices `--fuel 1` after the mode
  flag must read FUEL in `test_exec.sh` (measured: `FUEL:panic, exit
  134` — at fuel 1 the FRONT END's pure fuel'd workers exhaust before any
  ND kill; the regex accepts both sub-kinds), the same program at the
  default MATCH; `--fuel 0`/`--fuel abc` refused exit 2; `--fuel` before
  the mode flag refused (the mode flag is then out of position — the
  positional contract); `--fuel` without an argument exit 1. Result: §5.2
  row 8c.

### 4.5 The driver, measured (`tests/minimal/001-return-literal.c`, cabs-json from the fresh oracle)

```
== default:           Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}   rc=0
== --fuel 1:          lem: fuel exhausted   (+ backtrace)                                            rc=134
== --fuel 2:          lem: fuel exhausted                                                           rc=134
== --fuel 3:          lem: fuel exhausted                                                           rc=134
== --fuel 0:          cerberus-lean: refused — --fuel 0: the fuel must be a positive integer (fuel 0 kills at the first bind: never a verdict; see VALIDATION.md, fuel)   rc=2
== --fuel abc:        cerberus-lean: refused — --fuel abc: not a decimal numeral (the fuel is a positive integer; default 100000000; see VALIDATION.md, fuel)   rc=2
== --fuel 5 --batch:  cerberus-lean: refused — --batch: known flag out of its canonical position (…)   rc=2
== --batch f --fuel:  cerberus-lean: --libc/--libc-tu/--call/--call-args/--args/--fuel require an argument   rc=1
== --fuel 1000000000: Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}   rc=0
```

(At fuels 1–3 the exhaustion is the PANIC form of a pure-return front-end
worker — the desugar/elaboration stages run before the ND runner; the
exemplar's fuel-1 KILL is for a pre-built Core file that skips the front
end.)

## 5. Battery (REAL tree, pass 2; fresh stamped binaries; default fuel)

Freshness stamps: oracle `bin 4b00af5c… src 7c9a3b9d…` (§2.5); Lean
`check_driver_fresh: recorded lean stamp` on the real build. Lem-sync:
OCaml `check_lem_sync: OK (src 03c17693…, gen 295e4f82…)`; Lean
`check_lem_sync: lean OK (src 03c17693…, gen d1931404…)`. Every lane under
`SKIP_BUILD=1` on those stamps (the SKIP path's freshness + lem-sync
checks all passed — the pass-1 refusals are gone with the real stamp).
Serial, 19:20–20:06 UTC. (Pass 1's scratch-tree battery, which read
identically row for row, is superseded and not repeated here.)

### 5.1 Tier A — every row rc 0

| Row | Verbatim |
|---|---|
| 1 `test_unit.sh` | `✓ effects-proof-test PASSED` `✓ totality-proof-test PASSED` `✓ core-parser-test PASSED` `✓ fresh-int-test PASSED` `✓ pp-test PASSED` `✓ fuel-exemplar-test PASSED` / `Total: 6 passed, 0 failed`; `check_exec_purity: CLEAN (11 modules)`; `check_theorem_axioms: … generated-tree census OK (196 files: 0 axioms, boundary-opaque population = the 26 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)` … `FUEL arc leg OK (34 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 fuel_measure sufficiency obligations (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])` / `check_theorem_axioms: OK (…)`; `check_sorry_token: OK (262 files scanned comment-stripped — generated 196, hand-written+test 32, LemLib 34; 0 sorry tokens)`; `test_fuel_classifier: 18 fixtures, ALL OK`; `check_no_fuel_numerals: SELFTEST OK (13 plants red with the declared label; unplanted set green)` + `OK (267 files scanned comment-stripped; … (F1-F6); allowed Main.lean sites seen: 4 of 4 …)`; `check_lakefile_roots: SELFTEST OK (3 plants red, baseline green)` + `OK (195 roots = 195 generated modules + the exe root Main; 85 auxiliary modules all built)`; `check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)`; `check_lem_sync: OK` + `lean OK`; `check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)`; `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)`; `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)` |
| 2 minimal | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 3 coverage | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 4 debug | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 4b float | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| 4c bytes | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` / `ALL AT COMMITTED EXPECTEDS` |
| 5 libc_exec | `SUMMARY: match=11 diff=0` / `ALL MATCH RECORDED BASELINE` |
| 6 multi_tu | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| 7 parse | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| 8 core | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| 9 elab | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` (the recorded state; rc 0) |
| 10 libxml2 uri | `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| 11 cn_coverage | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |

### 5.2 Tier B — every row rc 0

| Row | Verbatim |
|---|---|
| 1 `test_libxml2.sh` | `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED` (19:33–19:44 UTC) |
| 2 parse tests/ci | `Lean parse:     128 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal)` / `ALL PASSED` (the lane's classified `REJECTED (exit 1): Undefined {ub: …}` rows counted out of its "Success rate") |
| 3 core tests/ci | `Lean parse:     128 ok, 0 failed` / `ALL PASSED` |
| 4 verify | `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)` |
| 5 immaculate | `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-L…` (the in-Lean probe `illtyped-store` reads `KILL` with `--fuel $CERB_TEST_FUEL`, F-C1-3) |
| 6 speclab | `test_speclab: PASS (both pipelines agree on Specified(0))`; `test_speclab: PASS (both pipelines agree on Specified(2))`; `CoreGateTest: ALL PASSED` / `test_speclab_divmod: PASS (--gate)`; `ByteArrGateTest: ALL PASSED` / `test_speclab_bytearr: PASS (--gate)`; `ListGateTest: ALL PASSED` / `test_speclab_list: PASS (--gate)`; `TreeGateTest: ALL PASSED` / `test_speclab_tree: PASS (--gate)`; `SeedGateTest: ALL PASSED` / `test_speclab_seed: PASS (--gate)` |
| 7 gcc second oracle | `SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 …` / `Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle lane OK` (19:44–20:05 UTC) |
| 8 plants | `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)`; `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)`; `test_fuel_plant`: the classifier legs as before PLUS the new real-driver leg — `PLANT OK   [exec/real driver at --fuel 1 -> FUEL]: [1/1] FUEL 001-return-literal (FUEL:panic, exit 134): lem: fuel exhausted` / `PLANT OK   [exec/real driver at the default fuel -> MATCH]: [1/1] MATCH 001-return-literal: VAL:Specified(42)` / `PLANT OK   [--fuel 0 refused, exit 2]: cerberus-lean: refused — --fuel 0: …` / `PLANT OK   [--fuel abc refused, exit 2]: …` / `PLANT OK   [--fuel before the mode flag refused (positional contract)]` / `PLANT OK   [--fuel without an argument refused]` / `test_fuel_plant: ALL PLANTS OK (…)` |

ZERO baseline movement, both tiers; no instrument commit; `git status`
after the battery shows only the slice's own files. The fuel-parametric
tree behaves identically at the default fuel — by construction, now
measured on the real tree.

### 5.3 Findings on the way (none is a baseline movement)

- F-C1-1: the pass-1 blocker, §2.3 — RESOLVED by lem `ecf75b4` (§2.5).
- F-C1-2 (Lean 4.32.2 div/mod folding at a symbolic fuel): §4.3.
- F-C1-3: two in-tree Lean consumers of the memory model OUTSIDE
  `lean_frontend/` reached fuel and needed the instance — the immaculate
  in-Lean probe `tests/immaculate/illtyped-store.lean` (`storeM`) and the
  mem-scale instrument `tests/mem-scale-probes/micro/Micro.lean`
  (`memValueToBytes`, `reconstructValue`). Both now take `--fuel N` from
  their command line (required; the lane passes `$CERB_TEST_FUEL`; the
  micro instrument is run by hand); `check_no_fuel_numerals.sh` scans
  `tests/**/*.lean` too. The lem record's §6 work list had no row for
  either (its grep was over `lean_frontend/`).
- F-C1-4 (measured, not a defect): at `--fuel 1..3` the driver's FRONT
  END exhausts first (pure-return workers — the panic form, exit 134),
  so "tiny fuel → FUEL:kill" as the brief phrased it is "tiny fuel → FUEL
  (panic sub-kind)"; the exemplar's fuel-1 KILL is for a pre-built Core
  file that skips the front end.
- F-C1-5 (brief premise, corrected by measurement): `sia_csmith_477.c` /
  `sia_csmith_769.c` do NOT "exhaust today" at the default fuel — at the
  10^8 budget the committed baselines already read `sia_csmith_477.c
  TIMEOUT` and `sia_csmith_769.c MATCH` (`scripts/exec_csmith_corpus_baseline.txt:1177/1469`;
  gcc ledger `AGREE` for both). They exhausted at the 10^6 era (fuel-arc
  record §5). §6.

## 6. The design's own test — the two csmith rows at a larger fuel (real tree)

Materialised as the corpus lane does (`#define CSMITH_MINIMAL` +
`csmith_cerberus.h` shim), oracle `--nolibc --exec --batch
--mode=exhaustive`, Lean `--batch` from the oracle's cabs-json, 600 s
timeout each, Lean under `scripts/capped` at 4G. Verbatim:

```
=== sia_csmith_477 oracle (--exec --batch --mode=exhaustive --nolibc, 600 s)
Defined {value: "Specified(132)", stdout: "", stderr: "", blocked: "false"}
oracle wall=6.36s maxrss=216768kB exit=0
=== sia_csmith_477 lean --batch  (600 s, cap 4G)
Defined {value: "Specified(132)", stdout: "", stderr: "", blocked: "false"}
lean wall=19.02s maxrss=1233244kB exit=0
=== sia_csmith_477 lean --batch --fuel 1000000000 (600 s, cap 4G)
Defined {value: "Specified(132)", stdout: "", stderr: "", blocked: "false"}
lean wall=19.24s maxrss=1232232kB exit=0
=== sia_csmith_769 oracle (--exec --batch --mode=exhaustive --nolibc, 600 s)
Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
oracle wall=3.73s maxrss=123860kB exit=0
=== sia_csmith_769 lean --batch  (600 s, cap 4G)
Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
lean wall=9.82s maxrss=617096kB exit=0
=== sia_csmith_769 lean --batch --fuel 1000000000 (600 s, cap 4G)
Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
lean wall=9.77s maxrss=616480kB exit=0
```

Both complete and AGREE with the oracle at the default fuel and at 10^9;
the fuel argument costs nothing measurable. `sia_csmith_477`'s 19 s is
why the corpus lane's committed row reads `TIMEOUT` (the lane's 15 s
per-test limit) — not a fuel matter (F-C1-5). NOT re-baselined.

## 7. Ratchet censuses

No PINNED population moved, so nothing was re-pinned: the boundary-opaque
census (26 rows, `CerbFuel.fuelExhaustedLoc` included), the seam
population (66 rows), the exec-entry set (9), the totality allowlist
(empty, 22 modules + CerbND), the exec-purity slice (11 modules), the
fork-drift manifest (71 files / 22 pinned deltas), the fixture freeze
(16). The only pinned LIST that changed is the axiom gate's `FUEL_THMS`
(§4.4: 34 names — the deleted ones out; the generated `_zero` names, the
parametricity pins and the three obligation statements + proofs in) — a
consequence of the deletions the brief ordered and of the three
obligations, not a census movement. Unpinned COUNTS that moved, with the
reason: generated-tree census 193 → 196 files (the three proof modules'
copies); `check_sorry_token` 256 → 262 files (generated 193 → 196: the proof
copies; hand-written+test 29 → 32: the three proof modules; LemLib 34);
`check_no_fuel_numerals` 258 → 267 files (+`tests/**/*.lean`, +3 proofs);
`check_lakefile_roots` 192 → 195 roots (+3 proofs); the C2 ratchet's
recursive scan 291 → 295 files (the LemLib copy at the new pin); the
generated model 170 files carry 147 derived `lemSize` definitions — all
`termination_by structural` defs, so `check_exec_totality` (22 modules)
stays `CLEAN` with the empty allowlist and the derived sizes contain no
fuel shape (`check_no_fuel_numerals` green on them: their numerals are
`0`/`1 + …`, not fuel).

## 8. Not done, and why

- The mem-scale sweep (`tests/mem-scale-probes/run_all.sh`, Tier C) and
  the csmith shards were not run (the brief did not ask; the previous
  bump's record ran them as extra measurement). The micro instrument was
  rebuilt (`Build completed successfully (136 jobs).`) but not timed.
- `refined-cerberus` was not touched (the manifest is theirs to consume).
- The upstream tray entry for F-C1-2 (Lean 4.32.2 div/mod folding) was
  not drafted — recorded here for the tray keeper.
- The remaining 35 `fuel_measure` rows, the hand-written `CerbMem`
  workers' measured forms, the absorbing-payload check for the (B)
  family and fuel monotonicity are C2 / the typed-failure pass, as
  scoped.

## 9. Decisions for the operator (nothing here was decided by me)

- **D-C1-1 (pass 1, the four D2 sites): CLOSED** by the operator's lem-lean
  D2-enablers slice (`ecf75b4`); this record keeps the measurement (§2.3)
  as history.
- **D-C1-3 — `CERB_TEST_FUEL` (a shell constant, 10^8, scripts/common.sh)
  as the test suites' fuel** for the speclab gate binaries, the immaculate
  in-Lean probe and the micro instrument: a test-suite choice under the
  ruling's own exception ("Defaults that are chosen eg. in test suites are
  fine"), outside the scanned Lean text. Confirm, or name a different
  source.
- **D-C1-4 — F-C1-2 for the upstream tray (Lean core):** a candidate
  report ("`Nat.div`/`Nat.mod` literal folding does not whnf its
  arguments, unlike `+ - *` and `Nat.beq`"; §4.3 has the minimal
  reproducer); C2 makes the exemplar's workaround unnecessary once the
  layout family is measured.
- **D-C1-5 — the two-repo invariant at merge:** this branch's Lake pin,
  the opam pin and `deps/lem-pinned` are all `ecf75b4` = lem-lean
  `mdd/lean-backend`; the arc closes when this branch merges ff-only.
  The pre-merge audit ask is unconditional (working practices): proposed
  scope = the full range `1b57bcf26..HEAD` (5 commits), with the three
  obligation proofs and the exemplar's symbolic route as the
  proof-bearing surface and the `CerbMem`/`mem.lem` fuel-consumer
  closure as the mirror-doctrine surface.

## 10. Worktree state at close

Branch `arc/fuel-parameter-cerberus`, five commits on top of mainline
`1b57bcf26` (§12), working tree clean apart from the gitignored `.tmp/`
(ephemeral: `prebump/` — the pre-arc OCaml snapshot + the refusal log;
`scratch/` — the pass-1 scratch frontend and generators, every build and
lane log quoted here; deleted at slice end) and the gitignored generated
trees/stamps. `wip/fuel-parameter-C1-scratch` (`b0f718eda`) is kept as the
pass-1 record. `lean_frontend/generated/` is the REAL tree (lem-sync
stamped: `src 03c17693…`, `gen d1931404…`); both driver binaries fresh
(`check_driver_fresh --check`: oracle OK, lean OK).

## 12. Commits (coherent groups, each on the green battery of §5)

| # | Commit | Content |
|---|---|---|
| 1/5 | `509698371` | pin LemLib → `ecf75b4` (lakefile + the three lake-manifests; the three proof roots ride the roots hunk); the five numeric fuel-budget declares deleted; 19 `fuel_consumer` + 3 `fuel_measure` declares — Lean-only, OCaml byte-identical |
| 2/5 | `bed02f577` | seams + driver: `driverFuel`/`ndDefaultFuel`/`drive_lemFuel` + budget pins deleted; `[LemFuel]` on the runners, `CerbCall`, the `CerbMem` closure, `Main`; `--fuel N`; speclab/immaculate/micro fuel arguments; `CERB_TEST_FUEL` |
| 3/5 | `20655ae7b` | the three `fuel_measure` sufficiency proofs + `handwritten_copy.manifest` |
| 4/5 | `f436dba72` | gates + tests: `check_no_fuel_numerals.sh`, `check_lakefile_roots.sh`, the axiom gate's FUEL leg, `test_unit.sh` wiring, `test_fuel_plant.sh`'s real-driver leg, `TotalityProofTest`/`EffectsProofTest`/`FuelExemplar` |
| 5/5 | (this commit) | docs: `VALIDATION.md`, `CLAUDE.md`, `DESIGN.md`, `TODO.md`, this record, the change manifest |

Every commit was made after the battery of §5 on the tree these five
commits produce together (the intermediate trees are not individually
buildable: 1/5 references the proof roots of 3/5 and 2/5's seams need
the regenerated tree of 1/5 — the groups follow the brief's grouping, not
bisectability).
