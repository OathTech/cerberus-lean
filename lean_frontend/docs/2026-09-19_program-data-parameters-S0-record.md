# Program-data parameters — S0 record: the multi-reader probe and the inventory (2026-09-19)

**Status:** S0 RECORD by the S0 worker [AGENT], executing
`2026-09-19_charter-program-data-parameters-S0.md` (the charter) for the
arc designed in `2026-09-18_program-data-parameters-design-note.md`.
Branch `arc/program-data-parameters`, worktree
`worktrees/cerberus-lean-arc/program-data-parameters`, base mainline
`b7e45d55e`, charter commit `a36382579`. S0 changed NO repository code:
this record + `2026-09-19_program-data-parameters-S0-evidence/` are the
only tree changes; the probe ran in the ephemeral `.tmp/pdp-s0/`
(gitignored, deleted at slice end). Pinned lem (verbatim `lem -v`):
`Lem f6542f8` at `cerberus-lean/_opam/bin/lem` (opam pin
`git+file:///…/deps/lem-pinned#cerberus-pin`); LemLib = `deps/lem-pinned`
`f6542f8:lean-lib` (git archive), toolchain `leanprover/lean4:v4.28.0`
(lean-lib's own). Every `lake` invocation ran through `scripts/capped`
(`CERB_MEM_MAX=16G`). This record ENDS the slice.

**One-paragraph verdict.** P1: **NEEDS A LEM-LEAN FIX — one guard.**
Three readers + `reader_consumer` + `supply` + `[Inhabited]` compose
exactly as `DESIGN.md` says and the generated code, kernel pins and all
negative controls are as the design note assumed — EXCEPT that
`reader_seed` is refused whenever more than one reader is declared
(`lean_backend.ml:4459-4464`, verbatim error in §1.5), and the model has
one `reader_seed` (`mini_pipeline.lem:78`, `run_const_expr_driver`) that
the arc cannot drop (§1.5). The paired lem-lean slice is named in §1.6
(N-ary `reader_seed`: with N readers the seed def's first N parameters
seed them in the global sorted order). P3: both engines mint the run's
symbols with the digest of the LAST translation unit the frontend
processed; no finding. P4: ten errata to the design note / charter
cites (plus one addition, E9), the largest being the READER ORDER — it is `digest,
enum_definitions, tagDefs` (sorted by name), not "`tagDefs`,
`enum_definitions`, `digest`" as the design note §3.2 wrote.

## 0. Rulings honoured (verbatim, from the charter)

- [USER 2026-09-19]: *"I'm interested in making decisions that are
  consequential in some way but for the other kinds of decisions, which
  are really more implementation-focused, I think you can make the
  calls."*; on Q2: *"yeah, I agree on Q2, let's roll it together"*.
- [USER 2026-09-08]: *"we should \*NOT\* be building anything new
  out-of-policy"* — S0 built probe files and this record only.
- Charter §3 fence: record + evidence dir + `.tmp/` scratch. `git
  status` at the end of the slice: only the record and the evidence
  dir are new (§7).

## 1. P1 — the multi-reader probe

### 1.1 What the backend does (read at the pin, `deps/lem-pinned/src/lean_backend.ml`, 8521 lines)

- **Reader list and ORDER** — `lean_reader_get_params` (`:586-601`):
  every constant in the WHOLE constant environment carrying
  `{lean} reader` (`lean_reader_is_reader`, `:485-487`) is paired with
  its binder name `"_lemReader_" ^ <unqualified name>`
  (`lean_reader_param_name`, `:493-495`), then
  `List.sort (fun (_, a) (_, b) -> String.compare a b)` — i.e. the
  GLOBAL order is **alphabetical (byte order) by the reader's
  unqualified name**, not declaration or module order; the prefix is
  constant, so `String.compare` on the binder name = byte order on the
  name (`'A'..'Z' < '_' < 'a'..'z'`). Duplicate unqualified names across
  modules fail closed (`lean_param_dup_check`, `:575-584`). The list is
  cached per INVOCATION (`St.reader_params_cache`, `:346-349`, reset in
  `St.reset_invocation`, `:430`), computed from `c_env_all_consts` —
  all typechecked modules of the invocation, so a reader declared in a
  later module is seen by an earlier module's lifting (confirmed by the
  two-module probe, §1.3).
- **Lifting fixpoint** — `lean_reader_prepass` (`:1169-1213`): per
  module, `Val_def` granularity; a def is lifted if it uses a reader,
  a `reader_consumer`, or an already-lifted def; instances are skipped
  (fail closed at emission); `reader_seed` defs are never lifted
  (`:1189-1191`).
- **Binder emission** — `reader_binder_output` (`:5221-5227`) emits
  ` (<pname> : <T>)` for every entry of the sorted list, in that order;
  the def-assembly line (`:5218`) is
  `fuel_binder_output (); inhabited_binder_output (); reader_binder_output (); supply_binder_output ()`
  — the fixed order the fuel wrapper comment states verbatim
  (`:4712-4714`): *"fixed order: [LemFuel], [Inhabited], fuel counter,
  readers, supply, original arguments"*.
- **Injection** — `reader_args_output` (`:3175-3178`) appends every
  reader's injection name in list order; `reader_inject_name pname`
  (`:3169-3172`) returns the SEED name when `St.reader_seed_param` is
  set, else the binder name — ONE seed name for EVERY reader, which is
  why the guard below exists. Consumer heads render as
  `(<rep> <all reader args>)` (`:5938-5946`, applied and bare/HOF
  alike); bare lifted-def references likewise (`:5948-5951`).
- **The guard** — `:4459-4464` (verbatim):
  ```
  | Some _ when List.length (get_reader_params ()) <> 1 ->
    (* The seed name overrides EVERY injected reader
       parameter — with more than one reader that would
       silently conflate them (audit finding). *)
    raise (Reporting_basic.err_general true (locn_of_clause_group g)
      "Lean backend: reader_seed requires exactly one declared reader")
  ```
  It is deliberate and correct as a fail-closed stop for the
  one-seed-name design; it is NOT covered by any negative probe in
  `tests/comprehensive/negative/` (the reader/rc probes there:
  `neg_reader_dupname`, `neg_reader_shadow{,_body}`, `neg_rc_indreln`,
  `neg_rc_infixrep`, `neg_rc_instance`, `neg_rc_mix{,_supply}`,
  `neg_rc_norep`, `neg_rc_paramrep`, `neg_fuel_reader_seed`,
  `neg_supply_mix_{seed,reader}` — none exercises two readers), and NO
  test at the pin declares two or more readers (`grep -c 'declare
  {lean} reader val'` over `tests/comprehensive`: every file 1;
  `test_target_reps.lem`'s 2 is one declare + one comment).
- **Other reader_seed guards** (`:4442-4475`): first argument must be a
  simple variable; multi-clause/mutual refused; instance refused; fuel
  refused; "reader_seed def unexpectedly reader-lifted" (`:4555-4558`).
- **Consumer guards** — `lean_reader_consumer_check` (`:537-573`):
  RC-mix, RC-rep (identifier-form rep only); scope guard
  `reader_consumer_scope_check` (`:3161-3166`); infix rejection
  (`:5487`, `:6178-6182`).

### 1.2 The probe programs (evidence `probe/`)

[AGENT] Because the guard was READ in source before running, the
positive program (`probe_readers.lem`) carries no `reader_seed`; the
seed is probed separately with three readers (`probe_seed3.lem`, the
expected refusal) and with one (`probe_seed1.lem`, today's model shape,
the control). [AGENT] The readers' Lean target_reps point at
never-emitted stubs (`ProbeImpl.*Unreachable`), the `ctype_aux.lem:36`
shape. [AGENT] LemLib was taken as a `git archive` of
`deps/lem-pinned f6542f8:lean-lib` into `.tmp/` (with lem-lean's built
`.lake` copied beside it, so nothing was written under the read-only
`lem-lean/`), and the scratch package pins toolchain 4.28.0 = lean-lib's.

| File | Content |
|---|---|
| `probe_readers.lem` | readers `tagDefs : unit -> map nat nat`, `digest : unit -> string`, `enum_defs : unit -> map nat nat`; `reader_consumer val consume` → `ProbeImpl.consume`; `supply val counter`; lifted `uses_one` (tagDefs), `uses_two` (+digest via callee), `uses_three` (+enum_defs +consumer), `maps_consume` (consumer as HOF argument), `draw_and_read` (supply + readers), `all_binders : forall 'a. list 'a -> 'a` (failwith at a tyvar + reader + supply) |
| `probe_seed3.lem` | the three readers + consumer + `reader_seed val seed_entry` (`seed_entry tds x = uses_three x`) |
| `probe_seed1.lem` | ONE reader + consumer + seed (`seed_entry1 tds x`, `via_seed1 x = seed_entry1 {1 ↦ 5} x`) |
| `pm_readers.lem` + `pm_use.lem` | the arc's MODULE shape: readers + consumer + supply declared in module 1, lifted defs (`uses_all`, `draw_all`) in module 2 importing it; ONE lem invocation on both files |
| `neg_nonlifted_instance.lem` | a reader read inside an instance method |
| `neg_nonlifted_assert.lem` | a lifted def referenced from an `assert` |
| `neg_consumer_in_assert.lem` | the consumer called from an `assert` |
| `ProbeImpl.lean` | the stub: `consume (digest : String) (enum_defs : Fmap Nat Nat) (tagDefs : Fmap Nat Nat) (x : Nat)` = `x + 100·|tagDefs| + 10000·Σ(values of enum_defs) + 1000000·|digest|` — the two same-typed maps are distinguishable (count vs value sum) |
| `ProbeImplWrong.lean.txt` | the same stub with `(tagDefs) (digest) (enum_defs)` — the wrong-order negative |
| `ProbeCheck.lean`, `PmCheck.lean`, `Seed1Check.lean` | signature pins, value pins by `decide`, the swap witness, `#print axioms` |
| `lakefile.lean`, `lean-toolchain` | the scratch package (`require LemLib from "../lean-lib"`; a non-default `NegAssert` lib for the assert negative) |

Generation command (each file; `pm_*` jointly): `scripts/ce lem -wl ign
-wl_rename warn -wl_pat_red err -wl_pat_exh warn -outdir . -lean <files>`
(the `Makefile:352-354` flags minus `-cerberus_pp`). Exit statuses
(logs `logs/gen_*.log`): `probe_readers` 0, `probe_seed3` 1,
`probe_seed1` 0, `neg_nonlifted_instance` 1, `neg_nonlifted_assert` 0
(refused later, at the Lean build), `neg_consumer_in_assert` 1,
`pm_readers+pm_use` 0. (A first `probe_readers` run failed on MY
`failwith` without `open import Assert_extra` — fixed in the source;
not a backend event.)

### 1.3 The generated code (evidence `generated/`; verbatim lines)

**Binder order and consumer call sites** (`Probe_readers.lean:44-53`):
```
def  uses_one (_lemReader_digest : String) (_lemReader_enum_defs : Fmap (Nat) (Nat)) (_lemReader_tagDefs : Fmap (Nat) (Nat))  (x : Nat)  : Nat :=  x  +  getD  (_lemReader_tagDefs) (  1)
def  uses_two (_lemReader_digest : String) (_lemReader_enum_defs : Fmap (Nat) (Nat)) (_lemReader_tagDefs : Fmap (Nat) (Nat))  (x : Nat)  : Nat := ( uses_one _lemReader_digest _lemReader_enum_defs _lemReader_tagDefs)  x  +  String.length  (_lemReader_digest)
def  uses_three (_lemReader_digest : String) (_lemReader_enum_defs : Fmap (Nat) (Nat)) (_lemReader_tagDefs : Fmap (Nat) (Nat))  (x : Nat)  : Nat :=  ((uses_two _lemReader_digest _lemReader_enum_defs _lemReader_tagDefs)  x  +  getD  (_lemReader_enum_defs) (  1))  + ( ProbeImpl.consume _lemReader_digest _lemReader_enum_defs _lemReader_tagDefs)  x
def  maps_consume (_lemReader_digest : String) (_lemReader_enum_defs : Fmap (Nat) (Nat)) (_lemReader_tagDefs : Fmap (Nat) (Nat))  (l : List (Nat))  : List (Nat) :=  List.map ( ProbeImpl.consume _lemReader_digest _lemReader_enum_defs _lemReader_tagDefs)  l
```
So: readers in the order `digest, enum_defs, tagDefs` — the sorted
order of §1.1 — as leading binders of EVERY lifted def, whether it
reads one, two or three of them (a def gets ALL readers, never a
subset); the consumer receives all three, in that order, at applied
sites and as a partially-applied HOF argument.

**Supply after the readers** (`:56-58`):
```
def  draw_and_read (_lemReader_digest : String) (_lemReader_enum_defs : Fmap (Nat) (Nat)) (_lemReader_tagDefs : Fmap (Nat) (Nat)) (_lemSupply_counter : Nat)  (x : Nat)  : ((Nat) × Nat) :=
  let (_lemSupplyV0, _lemSupplyS1) := LemLib.supplySplit _lemSupply_counter;
  ((_lemSupplyV0  + ( uses_three _lemReader_digest _lemReader_enum_defs _lemReader_tagDefs)  x), _lemSupplyS1)
```
**`[Inhabited]`, readers, supply** (`:61`):
```
def  all_binders  {a : Type} [Inhabited a] (_lemReader_digest : String) (_lemReader_enum_defs : Fmap (Nat) (Nat)) (_lemReader_tagDefs : Fmap (Nat) (Nat)) (_lemSupply_counter : Nat)  (l : List a)  : ((a) × Nat) :=
```
**Cross-module** (`Pm_use.lean:31,34`): `uses_all` and `draw_all` carry
the same three binders in the same order and inject
`Pm_readers.uses_one`/`ProbeImpl.consume` with all three — the reader
list is invocation-global, as §1.1 says.

**One-reader seed control** (`Probe_seed1.lean:36-42`):
```
def  uses_one (_lemReader_tagDefs : Fmap (Nat) (Nat))  (x : Nat)  : Nat :=  (x  +  getD  (_lemReader_tagDefs) (  1))  + ( ProbeImpl.consume1 _lemReader_tagDefs)  x
def  seed_entry1  (tds : Fmap (Nat) (Nat)) (x : Nat)  : Nat := ( uses_one tds)  x  + ( ProbeImpl.consume1 tds)  x
def  via_seed1  (x : Nat)  : Nat :=  seed_entry1  ((fmapAddBy  defaultCompare (  1) (  5)  fmapEmpty))  x
```
— the seed def is NOT lifted, its first argument `tds` replaces the
binder at the lifted callee AND at the consumer (the `reader_inject_name`
route), exactly the suite's `test_reader_consumer.lem` behaviour.

### 1.4 Kernel pins and axioms (evidence `logs/build_positive.log`, `build_positive_regreen.log`)

`ProbeCheck.lean` pins (all by `decide`, kernel-checked; `t1 = {1 ↦ 7}`,
`e1 = {1 ↦ 3, 2 ↦ 4}`, `d1 = "ab"`): `uses_one d1 e1 t1 5 = 12`,
`uses_two … = 14`, `ProbeImpl.consume d1 e1 t1 5 = 2070105`,
`uses_three … = 2070122`, `maps_consume d1 e1 t1 [1, 2] = [2070101,
2070102]`, `draw_and_read d1 e1 t1 10 5 = (2070132, 11)`,
`all_binders d1 e1 t1 10 [42] = (42, 11)`; the SWAP WITNESS
`ProbeImpl.consume d1 t1 e1 5 = 2070205` and `consume d1 e1 t1 5 ≠
consume d1 t1 e1 5` (the two same-typed map positions are not
interchangeable — a stub with the two maps swapped would compile and
compute the wrong value, which is what the value pins are for).
`PmCheck.lean`: `uses_all d1 e1 t1 5 = 2070122`, `draw_all d1 e1 t1 10 5
= (2070132, 11)`. `Seed1Check.lean`: `via_seed1 5 = 220`. Signature pins
as in §1.3. Build tail (verbatim):
```
ℹ [36/45] Replayed ProbeCheck
info: ProbeCheck.lean:33:0: 'uses_three' depends on axioms: [propext, Classical.choice, Quot.sound]
info: ProbeCheck.lean:34:0: 'maps_consume' depends on axioms: [propext, Classical.choice, Quot.sound]
info: ProbeCheck.lean:35:0: 'draw_and_read' depends on axioms: [propext, Classical.choice, Quot.sound]
info: ProbeCheck.lean:36:0: 'all_binders' depends on axioms: [propext]
ℹ [43/45] Built Seed1Check (161ms)
info: Seed1Check.lean:9:0: 'via_seed1' does not depend on any axioms
ℹ [44/45] Built PmCheck (296ms)
info: PmCheck.lean:15:0: 'uses_all' depends on axioms: [propext, Classical.choice, Quot.sound]
info: PmCheck.lean:16:0: 'draw_all' depends on axioms: [propext, Classical.choice, Quot.sound]
Build completed successfully (45 jobs).
```
Gate §4 of the charter (the trio or fewer): MET. LemLib was REPLAYED
from the copied `.lake` (no rebuild). (Harness note: a first check file
imported `Pm_use` and `Probe_seed1` together and failed on `import
Probe_seed1 failed, environment already contains 'getD' from
Pm_readers` — two of MY generated modules both define a top-level
`getD`; split into `PmCheck`/`Seed1Check`. A harness artifact, not a
backend event; that log was overwritten by the rebuild.)

### 1.5 Negative controls (verbatim errors)

**(N0) `reader_seed` with three readers — THE FINDING** (`logs/gen_probe_seed3.log`):
```
File "probe_seed3.lem", line 32, character 24 to line 32, character 35
  Error: Lean backend: reader_seed requires exactly one declared reader
  original input: "uses_three x"
```
**(N1) a reader read in a non-lifted position, instance method** (`logs/gen_neg_nonlifted_instance.log`):
```
File "neg_nonlifted_instance.lem", line 27, character 18 to line 27, character 40 processed by: inline_exp_macro, inline_exp
  Error: Lean backend: reader-lifted call inside an instance method (unsupported: instance fields cannot take extra parameters)
  original input: "x + getD (tagDefs ()) 0"
```
**(N2) the consumer called from an `assert`** (`logs/gen_neg_consumer_in_assert.log`):
```
File "neg_consumer_in_assert.lem", line 22, character 30 to line 22, character 36
  Error: Lean backend: reader_consumer call outside a reader-injection scope (unsupported: indreln rules, lemmas/asserts, and other non-lifted contexts have no reader value to pass — RC-rel/RC-scope)
  original input: "consume"
```
**(N3) a LIFTED def referenced from an `assert`** — generation SUCCEEDS
(exit 0) and the auxiliary file's assert runner applies the def to the
unbound binder names; the Lean build refuses
(`logs/build_neg_assert.log`, `lake build NegAssert`):
```
error: Neg_nonlifted_assert_auxiliary.lean:28:18: Unknown identifier `_lemReader_digest`
error: Neg_nonlifted_assert_auxiliary.lean:28:36: Unknown identifier `_lemReader_enum_defs`
error: Neg_nonlifted_assert_auxiliary.lean:28:57: Unknown identifier `_lemReader_tagDefs`
error: Lean exited with code 1
```
— fail-closed as `lean_reader_prepass`'s comment promises ("fails
visibly at the Lean build", `:1181-1182`), one step later than the
consumer case; a lem `assert` on a lifted def is not a usable test
vehicle (the suite's pins live in hand-written Lean for this reason).

**(N4) the consumer stub with the readers in the WRONG order**
(`ProbeImplWrong.lean.txt` swapped in; `logs/build_neg_wrong_order.log`):
```
error: Probe_readers.lean:50:285: Application type mismatch: The argument
  _lemReader_digest
has type
  String
but is expected to have type
  Fmap Nat Nat
in the application
  ProbeImpl.consume _lemReader_digest
error: Probe_readers.lean:53:194: Application type mismatch: The argument
  _lemReader_digest
has type
  String
but is expected to have type
  Fmap Nat Nat
in the application
  ProbeImpl.consume _lemReader_digest
error: Lean exited with code 1
```
The build fails as required — by TYPE, at the `String`/`Fmap` position.
A swap of the two SAME-typed maps (`tagDefs`/`enum_defs`) would NOT be
caught by the type checker: the arc's stubs must carry a value pin per
consumer (the §1.4 swap witness is the template). The correct stub was
restored and the package re-greened (`build_positive_regreen.log`:
`Build completed successfully (45 jobs).`).

**Why the model cannot simply drop its one `reader_seed`.**
`mini_pipeline.lem:70-78` `run_const_expr_driver tds dr_st` builds and
runs the constant-expression mini-driver under `with_tagDefs tds`;
on Lean the seed passes `tds` = `Translation.translate_tag_definitions
sigm.A.tag_definitions` (`mini_pipeline.lem:185-187`, the definitions
translated SO FAR) to every lifted callee. Were the def lifted instead,
its callees would receive the ENCLOSING binder — the desugarer's
`tagDefs` reader value, which the entry seeds with `fmapEmpty`
(`Main.lean:521`, mirroring the oracle's empty `Tags` global at
desugar time) — so `sizeof`/`offsetof` inside a constant expression
would see no tags: the split-read divergence the seed was introduced to
close (`ctype_aux.lem:19-30`, `mini_pipeline.lem:60-69`). Under E-A the
mini-run needs its OWN `enum_definitions` value as well (the enums
registered so far, from the desugar state), so the seed must carry two
of the three readers at least; §5 Q-A.

### 1.6 Verdict and the paired lem-lean slice

**Verdict: NEEDS A LEM-LEAN FIX** — a single guard; everything else is
SUPPORTED AS-IS with the rules below. The fix is NOT made here
(lem-lean is read-only for S0); it is a paired slice under the
two-repo pin dance, BEFORE E-A (design note §4 last bullet; §8 Q3).

**The failing case, verbatim:** §1.5 (N0) — `probe_seed3.lem:32`
(`let seed_entry tds x = uses_three x` + `declare {lean} reader_seed
val seed_entry` with three declared readers) →
`Lean backend: reader_seed requires exactly one declared reader`. In
the model: `mini_pipeline.lem:78` will fail identically the moment a
second `declare {lean} reader val` lands (`make lean-prelude-src`
red).

**The smallest fix (named, [AGENT]): N-ary `reader_seed`.** With N
declared readers, a `reader_seed` def's first N parameters are the
seeds, positionally in the GLOBAL SORTED reader order (the same order
the binders and the consumer stubs use — one rule everywhere).
Backend: `St.reader_seed_param : string option ref` (`:346`) becomes a
per-reader association `(reader binder name × seed variable) list
option`; `seed_info` (`:4441-4457`) takes the first `List.length
(get_reader_params ())` patterns (each `P_var`/`P_var_annot`, else
the existing "must be a simple variable" error; too few → a new
"reader_seed def must take N seed arguments (one per declared reader,
in the global sorted reader order: …)" error naming the order);
`reader_inject_name pname` (`:3169-3172`) looks `pname` up; the `<> 1`
guard (`:4459-4464`) is deleted (its purpose — no conflation — is met
by the per-reader map); the reserved-binder check (`:4478-4515`) and
the "unexpectedly reader-lifted" check stay. Tests: a three-reader
seed section (or `test_reader_multi.lem`) + `TestReaderMultiCheck.lean`
pins in the style of §1.4 + an Exec leg; `negative/neg_seed_arity.lem`
(too few seed parameters — the successor of the deleted guard, which
today has NO probe); an invariance witness `inv_reader_multi.lem` (the
`{lean}` declares stay no-ops for ocaml/hol/isa/coq). Docs: `DESIGN.md`
`reader_seed` row (`:505`) and the readers paragraph; a dated
`doc/lean-backend/` record. Size: ~40 backend lines + tests/docs; one
lem-lean commit; then the pin dance (`deps/lem-pinned` reset, `make
rebuild-lem`, `lake update LemLib`, regenerate both trees, lem-sync
stamps).

Alternative considered and NOT recommended [AGENT]: a partial seed
naming which readers are seeded (`declare {lean} reader_seed val f =
tagDefs enum_definitions`, the rest lifted through binders) — more
machinery (a def both lifted and seeded) for the same model need,
since `run_const_expr_driver` must seed two readers anyway and its
`digest` can be passed from the caller's own binder as an ordinary
argument (`Symbol.digest ()` in the lem source renders as the caller's
`_lemReader_digest` on Lean and reads the global on OCaml).
Consequence for the MODEL under the N-ary fix: `run_const_expr_driver`
gains two leading parameters in the `.lem` (`digest_v enum_v tds
dr_st`), DEAD on the OCaml target — the `evalConstantExpressionAux sup
…` precedent ("On the OCaml target the threaded values are DEAD",
`mini_pipeline.lem:80-86`); the generated OCaml moves at one function
and its one caller, so `scripts/fork_drift_manifest.txt`'s hash pins
are re-pinned in E-A. This is a lem-source change motivated by the Lean
target — flagged for the operator in §5 Q-B under the [USER 2026-09-04]
"we don't change the lem structure for ocaml" rule (the supply
threading was accepted under the same rule).

**Rules the E-A/D-A charter must follow (SUPPORTED AS-IS part):**
1. **Order = sorted by reader NAME.** Fix the names first: with
   `digest`, `enum_definitions`, `tagDefs` the binder/argument order is
   `(_lemReader_digest : String) (_lemReader_enum_definitions : Fmap sym integerType) (_lemReader_tagDefs : Fmap sym (Loc × tag_definition))`
   everywhere — every lifted def, every consumer stub's leading
   parameters, every seed def's leading parameters (after the fix),
   every entry call (`drive`, `initial_driver_state`, `desugar`,
   `translate`, `CerbCall.driveCall`, the test/speclab sites of §2(b)).
   Renaming a reader reorders every binder in the tree (byte order:
   uppercase < `_` < lowercase — `Digest` would sort before `digest`).
   The design note's "`tagDefs`, `enum_definitions`, `digest`" (§3.2)
   is WRONG; §4 erratum E1.
2. **Every lifted def takes ALL readers**, whether it reads one or
   three (§1.3): the consumer re-pin is "+2 leading arguments" on
   every reader-taking signature they use, not per-reader.
3. **Consumer stubs**: identifier-form rep (RC-rep), leading
   parameters in rule-1 order, and a VALUE pin per stub for the two
   same-typed maps (a `tagDefs`/`enum_definitions` swap type-checks —
   §1.5 N4); the `handwritten_copy.manifest`/sync gate covers the
   copies as today.
4. **Seeds**: after the lem-lean fix, the seed def's first N parameters
   in rule-1 order; the seed's callers pass values, never binders, for
   the seeded readers — the mini-run passes (its caller's `digest`, the
   desugar-state-derived enum map, `translate_tag_definitions …`).
5. **Supply and fuel compose unchanged**: `[LemFuel]`, `[Inhabited]`,
   readers, supply, own args (§1.3); `fresh_int`'s supply binder
   follows the three readers in every signature.
6. **Non-lifted positions** (instances, indreln, `assert`/lemma) stay
   fail-closed — at generation for consumers/instances, at the Lean
   build for a lifted def in an `assert` (§1.5 N3); no lem `assert`
   may mention a lifted def.
7. **Names**: no user binder or constant may render as `_lemReader_*`
   (`:4478-4515`, `lean_reserved_capture_check`); no two readers may
   share an unqualified name (`:575-584`).

## 2. P2 — the inventory at the base `b7e45d55e`

**(a) `reader`/`reader_consumer`/`reader_seed`/`supply` declares in `frontend/model/*.lem`** (`grep -n 'declare {lean} reader\|declare {lean} supply'`, 19 lines):

| Kind | Site(s) |
|---|---|
| `reader` (1) | `ctype_aux.lem:36` `tagDefs` (val `:11`) |
| `reader_seed` (1) | `mini_pipeline.lem:78` `run_const_expr_driver` (def `:70-77`; caller `:185-187`) |
| `reader_consumer` (16) | `mem.lem:96` `allocate_object`, `:97` `load`, `:98` `store`, `:163` `diff_ptrval`, `:176` `validForDeref_ptrval`, `:182` `isWellAligned_ptrval`, `:213` `array_shift_ptrval`, `:217` `member_shift_ptrval`, `:225` `eff_array_shift_ptrval`, `:229` `eff_member_shift_ptrval`, `:239` `memcpy`, `:243` `memcmp`, `:247` `realloc`, `:306` `offsetof_ival`, `:310` `sizeof_ival`, `:327` `alignof_ival` (the block comment `:86-95` says "16 vals") |
| `supply` (1) | `symbol.lem:242` `fresh_int` |

Charter §1 listed consumers at `mem.lem:89-91,156,169` (five): the
lines moved (+7) and there are SIXTEEN — erratum E2. Every consumer's
`CerbMem.lean` implementation gains two leading parameters in E-A/D-A
(16 signatures) and every generated call site passes three readers.

**(b) Lean sites passing the reader today** (non-comment lines; the
value in the reader position is the thing that becomes THREE):

| File:line | Call | Reader value today |
|---|---|---|
| `Main.lean:521` | `desugar fmapEmpty supply addressSpaceTop …` (inside `frontendTU`, per TU, under `forceIO`) | `fmapEmpty` |
| `Main.lean:563` | `translate fmapEmpty supplyAfterDesugar …` (inside `frontendTU`, under `forceIO`) | `fmapEmpty` |
| `Main.lean:1025` | `initial_driver_state supply addressSpaceTop runFile fsState` | (none today; under D-A this def LIFTS — it draws a symbol via `fresh_given_int`, §4 E11) |
| `Main.lean:1037` | `drive runFile.tagDefs false runFile ("cmdname" :: progArgs)` | `runFile.tagDefs` |
| `Main.lean:1039` | `CerbCall.driveCall runFile.tagDefs runFile fname …` | `runFile.tagDefs` |
| `CerbCall.lean:258,274,302` | `allocErrno`/`callFinish`/`driveCall` take `(tagDefs : Fmap sym (Loc × tag_definition))` | binder |
| `CerbCall.lean:261,262,267` | `CerbMem.allocateObject tagDefs …`, `CerbMem.alignofIval tagDefs signed_int`, `CerbMem.storeM tagDefs …` | `tagDefs` |
| `CerbCall.lean:290,292,305,316,318` | `driver2 tagDefs false`, `finalize tagDefs …`, `driver_globals tagDefs false file1`, `allocErrno tagDefs tid0`, `callFinish tagDefs …` | `tagDefs` |
| `CerbCall.lean:156` | `PrefFunArg callLoc (CerberusFresh.digest ()) n` | (the hand-written digest READ — becomes the reader binder under D-A) |
| `test/Unit/FuelExemplar.lean:146,318,364,391,425,428,443,455,473,499,504,520,546,548,550,580,584` | `@drive ⟨n⟩ fmapEmpty …`, `driver2_lemFuel … tds false`, `finalize … tds`, `CerbMem.alignofIval … fmapEmpty`, `CerbMem.allocateObject fmapEmpty …`, `CerbMem.storeM fmapEmpty …`, `driver_globals fmapEmpty …`, `driver2 … fmapEmpty false`, `driver2_done … fmapEmpty` | `fmapEmpty` / `tds` (17 sites; the shipped exemplar theorem's statement changes shape — a consumer-visible signature) |
| `test/Unit/MonadicFailstop.lean:41,43` | `allocateObject tags 0 …` | `tags` |
| `test/Unit/TotalityProofTest.lean:64` | `@driver2 ⟨n⟩ = @driver2_lemFuel ⟨n⟩ n` (binder-free equation; unchanged in shape, the binders ride) | — |
| `speclab/test/SLUnit/{ByteArrGateTest:47, CoreGateTest:45, ListGateTest:55, SeedGateTest:46, TreeGateTest:53}.lean` | `CerbND.runND (drive f.tagDefs false f ["cmdname"]) ((initial_driver_state 0 gateAddressSpaceTop f CerbFS.fs_initial_state).1)` | `f.tagDefs` (5 files, 1 site each; `initial_driver_state` there lifts too) |
| `tests/immaculate/illtyped-store.lean:49` | `storeM fmapEmpty (CerbLocation.other "illtyped-store probe") …` | `fmapEmpty` |
| `tests/immaculate/g6-hash-collision.lean`, `tests/mem-scale-probes/micro/Micro.lean` | no reader-taking call | — |

Derived tally [derived]: 2 hand-written entry files (Main 4 sites incl.
the two lifting entries, CerbCall 11 sites + 1 digest read), 3 unit-test
files (FuelExemplar 17, MonadicFailstop 2, TotalityProofTest 0 changes),
5 speclab gate tests (5 sites + 5 `initial_driver_state`), 1 immaculate
probe. The allocator part-two record's "nine Lean callers" of
`drive`/`initial_driver_state` = Main(2) + CerbCall(1) + FuelExemplar(1)
+ the five speclab tests — consistent.

**(c) Generated reads** (over `lean_frontend/generated/*.lean`; `grep -o
'CerberusFresh\.digest *( *)'`, distinguished from the 92 `digest_compare`
mentions and from type uses — there are none: `type digest` renders as
`String`):

| Module | `CerberusFresh.digest ()` reads | lem source |
|---|---|---|
| `Symbol.lean` | 8 | `symbol.lem:249,253,257,262` (`fresh`, `fresh_pretty`, `fresh_cn`, `fresh_pretty_with_id`), `:278` (`fresh_given_int`), `:281` (`fresh_object_address`) — 6 lem sites (`grep -n 'digest()'`); 8 emitted occurrences |
| `Cabs_to_ail_effect.lean` | 5 | `cabs_to_ail_effect.lem:657,662,667,672,677` (`fresh_sym*` desugM mints) |
| `Translation.lean` | 2 | `translation.lem:942,4435` (`PrefFunArg loc (Symbol.digest ()) …`) |
| `CerbCall.lean` (copy of the hand-written seam) | 1 | `CerbCall.lean:156` |
| `CerberusFresh.lean` (the seam's own copy) | 1 | comment text at `CerberusFresh.lean:82-101` (not a read) |
| **total lem-generated** | **15** | |

Charter §1 said `Symbol 8, Cabs_to_ail_effect 5, Translation 2,
CerbCall 2` at `e64819de7`: CerbCall is 1 at the base — erratum E3.
`CerberusImpl.typeof_enum`: generated `CerbMem.lean` 3 (the copy of
the hand-written `CerbMem.lean:1411` comment, `:1424`, `:1447`);
NO lem-generated module reads `typeof_enum` directly — every generated
route goes through `CerberusImpl.normalise_integerType` (`:153`,
`.Enum0 tag_sym => typeof_enum tag_sym`) and the `sizeof_ity`/…
target_reps. Hand-written mentions: `CerberusImpl.lean` 16,
`CerbMem.lean` 6 (design note's counts hold). `register_enum`:
generated `Cabs_to_ail_effect.lean` 3, `Cabs_to_ail.lean` 2,
`CerberusImpl.lean` 8 (the seam).

**(d) Allowlist / register rows that retire.** `scripts/unsafebaseio_allowlist.txt`:
- E-A: the two KEEP rows `:32-33` (`typeof_enum_impl`, `register_enum_impl`,
  class `temporal(reader/supply-machinery-follow-up-slice …)`) and SIX
  PIN rows `:132-137` (`IMPLBY`×2, `UNSAFEBASEIO`×2, `UNSAFEDECL`×2 for
  `register_enum_impl`/`typeof_enum_impl`, COUNT 2 each). Charter §1
  said "the enum rows `:29-30`": they are `:32-33` — erratum E4.
- D-A: TEN PIN rows `:121-123,125-131` — `EXTERN digestIO`, `EXTERN
  digestPure`, `EXTERN forceThunkIO`, `EXTERN setDigestIO`, `IMPLBY
  digest_impl`, `IMPLBY forceIO_impl`, `UNSAFEDECL digest_impl`,
  `UNSAFEDECL digestPure`, `UNSAFEDECL forceIO_impl`, `UNSAFEDECL
  forceThunkIO`; `EXTERN md5Hex` (`:124`) STAYS (§3: the libc dump's
  digest is computed from the dump text, `Main.lean:616`, and
  `FreshIntTest.lean:73-104` pins it against RFC 1321).
- `OPAQUE_WANT` (`scripts/check_theorem_axioms.sh:209-233`, population
  12): E-A retires `CerberusImpl.lean:typeof_enum`,
  `CerberusImpl.lean:register_enum` (2); D-A retires
  `CerberusFresh.lean:digestIO`, `:setDigestIO`, `:digestPure`,
  `:digest`, `:forceThunkIO`, `:forceIO` (6); `CerberusFresh.lean:md5Hex`
  stays. Population 12 → 10 (E-A) → 4 (D-A): `md5Hex`,
  `CerbUtils.lean:bounded_integer`, `CerbFuel.lean:fuelExhaustedLoc`,
  `CerbFail.lean:modelFailStopLoc` [derived]. The "forceIO question"
  (charter P4): `forceIO`'s ONLY users are `Main.lean:520,533,562` (the
  per-TU stage barriers whose only purpose is the digest global — their
  header `:496-499` says so) and `test/Unit/FreshIntTest.lean:134-141`
  (`testDigestGlobal`, `:113-145`, which also uses `digestIO`/
  `setDigestIO`); D-A deletes all of them together. The effect-erasure
  page `docs/2026-08-22_arc14-effect-erasure-invariant.md` becomes
  history at D-A.

**(e) OCaml sites that would change.** NONE for the layout functions:
`ocaml_implementation.ml:130-142` `register_enum` (GCC rule `:130-136`:
`Signed Int_` iff some enumerator `< 0`, else `Unsigned Int_`; duplicate
→ `false`; push) and `:144-150` `typeof_enum` (lookup or `failwith
"Ocaml_implementation.typeof_enum: '…' was not registered"`) keep
their bodies; E-A adds ONE target_rep function beside them
(`enum_definitions () = List.fold_left (fun m (s, ity) -> Pmap.add s
ity m) (Pmap.empty Symbol.symbol_compare) !registered_enums`-shaped,
two lines) and re-points `typeof_enum`'s SHARED lem body at it (the
OCaml failure text preserved). `cerb_fresh.ml:88-95` (`digest`,
`set_digest`) is untouched by D-A (the target_rep `Cerb_fresh.digest`
stays). The ~101 non-generated OCaml references to
`sizeof_ity/alignof_ity/is_signed_ity/precision_ity/typeof_enum`
re-counted [derived]: 157 total, 56 in `ocaml_frontend/generated/`,
**101 non-generated across 12 files** (`ocaml_implementation.ml` 54,
`.mli` 5, `memory/concrete/impl_mem.ml` 10, `memory/vip/common.ml` 8,
`memory/symbolic/mem_simplify.ml` 8, `backend/bmc/bmc_sorts.ml` 4,
`bmc_common.ml` 4, `bmc_incremental.ml` 2, `decode.ml` 2,
`memory/vip/impl_mem.ml` 2, `memory/symbolic/impl_mem.ml` 1,
`backend/common/smt.ml` 1) — the design note's "~101 across 12 files"
holds exactly.

## 3. P3 — the multi-TU digest, pinned from source

**Erratum [AGENT 2026-09-22, run-digest audit D1]:** the OCaml inventory below
correctly distinguishes `.core` text (sets the digest) from `.co`/`.o` objects
(preserve it); the later D-S design note and charter accidentally grouped them.
The shared last-program-TU conclusion applies to the Cabs execution pipeline
and the C-input differential lanes. It does not define an arbitrary entry from
the absence of Cabs TUs: OCaml Core text sets `Digest.file filename`, even after
a C input, while objects retain whichever digest was previously installed.
That retained global is empty only if no prior input set it. Lean's
`--parse-core` does not execute Core text. D-S's pure `runDigest [] = ""` is
specifically the Cabs entry's empty-list rule; consumers of other entries carry
the actual entry value. The historical D-A reader proposal below was superseded
by D-S run-state data; its probe transcripts remain historical evidence.

**OCaml.** `Cerb_fresh.set_digest filename` (`util/cerb_fresh.ml:88-95`:
`digest := Digest.file filename`, resets the TU window) is called at
exactly three sites: `backend/common/pipeline.ml:185` (top of
`c_frontend`, per `.c` TU), `:280` (top of `core_frontend`, per `.core`
TU), `backend/driver/main.ml:270` (the `--cabs-json` export path, per
file — this is how each cabs-json carries its TU's digest).
`read_core_object` (`pipeline.ml:666`, `.co`/`.o` inputs — libc.co in
libc mode) sets NO digest. The driver's `main` (`main.ml:156-160`) folds
`frontend` over `core_libraries … @ files` — libraries FIRST, then the
input files in ARGUMENT order — then `Core_linking.link` (`:318-322`)
and, under `exec`, `interp_backend` (`:323-328`) with no `set_digest`
between link and run. Run-time minting is `Fork_renumber.fresh_symbol'`
(`ocaml_frontend/fork_renumber.ml:49`) = `Symbol.fresh ()` =
`Symbol (digest()) (fresh_int ()) SD_None` (`symbol.lem:247-249`) =
the global's CURRENT value. **Therefore for `cerberus a.c b.c` the
sequence is `set_digest "a.c"; set_digest "b.c"` and every run-minted
symbol carries `Digest.file "b.c"` — the LAST TU processed.**

**Lean.** `Main.lean` sets the global at three sites: `:616` (libc mode:
`setDigestIO (md5Hex dumpContent)` before parsing the pinned libc dump),
`:637` (each of the 12 libc METADATA TUs, from its cabs-json), `:961`
(each PROGRAM TU, in `tunits` = command-line order, from its cabs-json =
the oracle's `Digest.file` of the C source), each before that TU's
`frontendTU`; libc loading (`:940-945`) precedes the program loop
(`:946-964`); then `link coreFiles` (`:975`), `initial_driver_state`
(`:1025`), `drive`/`driveCall` (`:1037/:1039`) with no set between.
**For a nonempty program Cabs list, the value in force at `drive` is the
digest of its LAST TU — the same TU as OCaml in the C-input lanes.**

**The rule proposed for D-A (historical; domain clarified by the erratum):**
OCaml's run receives the current global after processing all inputs: the last
`.c`/`.core` input sets it, and `.co`/`.o` objects preserve it. In the C-input
lanes, Lean's nonempty Cabs list selects that same last program TU; both engines
receive the TUs in the same order (`scripts/test_multi_tu.sh:7,139` links "in
SORTED name order, both sides"). Library/metadata digests are installed earlier
and do not win when program Cabs TUs are present. The old D-A proposal replaced
each per-TU installation with a reader seed; D-S instead keeps those frontend
installations and carries the run entry's digest as state data. The original
C-input-lane source comparison found agreement; it did not establish a common
empty-input rule for all entry paths.

**What is observable.** No printer prints a digest: `pp_symbol.ml:5,12,38`
destructure `Symbol (_, n, sd)`; `symbol.lem:203-205` `show_symbol`
ignores `d`; `show_raw` (`:213`) has no non-generated user. `--pp=core`
therefore cannot show a wrong choice. The digest IS behaviour only
through `symbolEqual`/`symbol_compare` (`symbol.lem:136-160`: digest
first, then number): (i) `Core_linking.merge_globs`' tie-break orders
the linked globals by `(digest, number)` (`Main.lean:111-126`, Z-28) —
frontend symbols only, unaffected by the RUN digest; (ii) run-time
symbol maps/sets keyed by `symbol_compare` — a wrong run digest could
reorder a run-minted symbol relative to frontend symbols only where an
iteration order is observable, and the single supply makes equal
`(digest, number)` pairs impossible across the choice. The
`CERB_FRESH_FLOOR_VIOLATION` backstop (`cerb_fresh.ml:22-31`) checks the
DESUGAR window only ("the RUN-seam shims … have no dynamic check") and
so would not see a wrong run digest either. Consequence for D-A's
verification plan: the kernel-visibility test is the instrument —
`(fresh_given_int d n).1 = d` by `rfl` and an entry-level pin that the
value `drive` receives equals the last TU's digest; plus the standing
zero-movement lanes.

## 4. P4 — errata to the design note §2 / charter §1 at `b7e45d55e`, and sizing

| # | Cite as written | At the base |
|---|---|---|
| E1 | design note §3.2: "THREE leading arguments: `tagDefs`, `enum_definitions`, `digest` in the global sorted order" | the sorted order is **`digest`, `enum_definitions`, `tagDefs`** (§1.1, §1.3) |
| E2 | charter §1 / note §1: `reader_consumer` at `mem.lem:89-91,156,169` | `mem.lem:96-98,163,176` + 11 more = 16 (§2a) |
| E3 | `CerbCall.lean` 2 digest reads | 1 (`CerbCall.lean:156`); lem-generated total 15 (§2c) |
| E4 | allowlist "enum rows `:29-30`" | KEEP rows `:32-33`; PIN rows `:132-137` (§2d) |
| E5 | `cabs_to_ail_effect.lem:1762-1788` `register_tag_definition` | `:1775-1800` (val `:1775`; the `Enum_definition` arm `:1787-1794`; the `tag_definitions` insert `:1798-1800`) |
| E6 | `cabs_to_ail_effect.lem:2518-2528` sigma construction, `Enum_definition _ -> acc` | `mk_current_ail_sigma` `:2522-2548`; the arm `:2538-2539` |
| E7 | `translation.lem:4505-4511` "the assembly" of `tagDefs` | `:4505-4511` is a CHERI globals fold; the assembly is `:4245` (`core_tagDefs = translate_tag_definitions sigm.A.tag_definitions`), returned `:4543`, placed `:4578` (`C.tagDefs= core_tagDefs`) |
| E8 | `core_linking.lem` "merged" (no line) | `:294` `tagDefs= f1.tagDefs union f2.tagDefs` |
| E9 | `symbol.lem:276-278` `fresh_given_int` | HOLDS (`val :276`, `let :277`, the read `:278`) — listed because the note's "five" minting sites miss `fresh_object_address` `:280-281`, a SIXTH `digest()` read (D-A lifts it too; no consumer impact) |
| E10 | `CerbMem.lean:1410/1433` `maxIval`/`minIval` | `:1424/:1447` (comment `:1411`, failwith arms `:1437/:1458`) |
| E11 | design note §3.2/§5: "`drive`/`initial_driver_state` gain reader arguments (as `tagDefs` did)" — but `initial_driver_state` takes no reader today | correct as a PREDICTION: `initial_driver_state` (`Main.lean:1025`, the speclab tests) draws via `fresh_given_int` (`core_run_aux.lem`) and so LIFTS under D-A — one more consumer-visible signature (§2b) |
| — | `core_reduction.lem:1246/1317` | hold (`E.fresh_symbol`, the `SEU.runS Core_run.fresh_symbol'` wrapper `:40-41`) |
| — | `DESIGN.md:240-274` | the readers/seed/supply sentence is `:238-241`, the `reader_consumer` paragraph `:250-275`; declare rows `:504-507` |
| — | `implementation.lem:12-13,30-33`; `symbol.lem:40-46,130-131,153-160,247-262`; `core.lem:420`; `cabs_to_ail_aux.lem:12`; `ctype_aux.lem:11,36`; `mini_pipeline.lem:78`; `core_run.lem:115-119`; `translation_effect.lem:68-77`; `ocaml_implementation.ml:124-150,130-136`; `cerb_fresh.ml:77-86,88-95`; `pipeline.ml:185/280`; `main.ml:270`; `fork_renumber.ml:49`; `CerberusFresh.lean:110-121`; `Main.lean:521,616,637,961`; `CerberusImpl.lean:55-75,153,264-285`; `CoreParser.lean:242`; `unsafebaseio_allowlist.txt` digest rows | all HOLD |

**Sizing (from P1–P3), the arc's slices [AGENT]:**

- **S0.5 — lem-lean: N-ary `reader_seed`** (paired slice, BEFORE E-A):
  §1.6. Then the pin dance. Gate: the lem-lean suite (`make lean` in
  `tests/comprehensive` incl. the new negative), cerberus regenerated
  at the new pin with ZERO generated-tree movement (no reader added
  yet), lem-sync stamps.
- **E-A — the enum's compatible type as data.** lem: `implementation.lem`
  — `val enum_compatible_type : list integer -> Ctype.integerType`
  with the GCC body (cite `ocaml_implementation.ml:130-136`), `val
  enum_definitions : unit -> map Symbol.sym Ctype.integerType` +
  `declare {lean} reader val enum_definitions` + OCaml target_rep,
  `typeof_enum`'s body SHARED (lookup, OCaml failure text kept),
  `register_enum` a Lean `true` (OCaml rep unchanged); the sigma/Core
  file field (`ailSyntax.lem` `A.sigma` or `core.lem:420` beside
  `tagDefs`), `cabs_to_ail_effect.lem:2538-2539` one arm →
  `(ident, enum_compatible_type ns)`, `translation.lem:4245/4543/4578`
  (carry it), `core_linking.lem:294` (merge as `tagDefs`),
  `mini_pipeline.lem:70-78,185-187` (the seed gains the enum map and
  the digest argument — after S0.5; the enum map for the mini-run is
  computed from the desugar state, §5 Q-A). Lean: `CerberusImpl.lean`
  — delete `enumRegistryRef`/`typeof_enum_impl`/`register_enum_impl`/
  `initialize` (`:55-75,264-285`), make the 16 mentions functions of
  the map (`normalise_integerType :153` becomes a lookup taking the
  map — the layout functions `sizeof_ity`/`alignof_ity`/
  `is_signed_ity`/`precision_ity` are target_reps of lem vals whose
  callers are lifted, so the hand-written functions gain the map as a
  parameter and the lem vals become `reader_consumer`s, OR
  `normalise_integerType` is written in lem — a design choice for the
  E-A charter, §5 Q-D); `CerbMem.lean:1424,1447` (+ the 16 consumer
  signatures gain `enum_definitions`); the §2(b) seeding sites (+1
  argument each: `Main.lean:521,563,1037,1039`, `CerbCall.lean` 11,
  `FuelExemplar` 17, `MonadicFailstop` 2, speclab 5, immaculate 1);
  `scripts/unsafebaseio_allowlist.txt` −2 KEEP −6 PIN; `OPAQUE_WANT`
  −2; `check_fork_drift.sh` manifest re-pin (the generated OCaml moves
  at `implementation.ml`, `cabs_to_ail_effect.ml`, `mini_pipeline.ml`,
  `translation.ml`, `core_linking.ml`, `ailSyntax`/`core`); kernel
  tests (`sizeof_ity`/`alignof_ity` at a registered enum reduce by
  `rfl`/`decide` given the map entry; `register_enum` no longer
  exists as an effect). Gates: Tier A/B zero movement; census counts.
- **D-A — the digest as data.** lem: `symbol.lem:44-46` +1 line
  (`declare {lean} reader val digest`). Lean: `Main.lean` — per-TU
  seeding replaces `:616/:637/:961` `setDigestIO` (the value passed to
  `frontendTU` → `desugar`/`translate`; `:520,533,562` `forceIO`
  barriers deleted), the run's value = the LAST program TU's digest
  (§3) passed to `initial_driver_state` (now lifted, E11) and
  `drive`/`driveCall`; `CerbCall.lean:156` reads the binder;
  `CerberusFresh.lean:71-121,161-167` — delete `digestPure`,
  `digest_impl`, `digest`, `setDigestIO`, `digestIO`, `forceThunkIO`,
  `forceIO_impl`, `forceIO` (keep `md5Hex`; `native/md5.c` keeps the
  hash, drops `cerb_digest_get`/`cerb_force_thunk`/the digest global);
  `test/Unit/FreshIntTest.lean:113-145` `testDigestGlobal` → a
  kernel-visibility test (`(fresh_given_int d n).1 = d` by `rfl`; the
  entry passes a 32-hex-digit MD5, never `""`); allowlist −10 PIN;
  `OPAQUE_WANT` −6; the seeding sites of §2(b) (+1 argument each,
  FIRST position); the effect-erasure page → history. Gates: zero
  movement on every lane (libc-mode lanes are the digest-sensitive
  ones: Z-28); the census counts; `check_theorem_axioms.sh` population
  4.
- **Consumer re-pin** (one, at the arc's end): every reader-taking
  signature they use gains two leading arguments in the order
  `digest, enum_definitions, tagDefs`; `initial_driver_state` and
  `desugar`/`translate` gain readers for the first time (E11); the
  exemplar theorem's statement (`FuelExemplar.lean:146`) changes shape.

## 5. Open questions for the E-A/D-A charter

- **Q-A (E-A design detail, [AGENT] to decide in the charter unless the
  operator wants it):** the const-expr mini-run's `enum_definitions`
  seed. The OCaml `typeof_enum` inside a constant expression reads the
  registry AS OF THAT MOMENT (the enums registered so far). Under E-A
  the Lean mini-run must be seeded with the same content: the map
  derived from `st.tag_definitions` (`Enum_definition ns ↦
  enum_compatible_type ns`) at `mini_pipeline.lem:185`, computed in the
  lem body (both engines compute it; on OCaml the value is dead as
  `typeof_enum` reads the registry). Equal content is guaranteed
  because `register_tag_definition` inserts into `tag_definitions`
  right after `register_enum` (`cabs_to_ail_effect.lem:1790-1800`) and
  nothing else registers.
- **Q-B (consequential — for the operator):** the N-ary seed makes
  `run_const_expr_driver` take two more leading parameters in the
  `.lem`, dead on the OCaml target (generated OCaml moves at one
  function + one caller; fork-drift manifest re-pin). Precedent: the
  supply threading of `evalConstantExpressionAux sup …`
  (`mini_pipeline.lem:80-86`). Acceptable under [USER 2026-09-04] "we
  don't change the lem structure for ocaml", or should the paired
  slice implement the partial-seed alternative (§1.6) so the `.lem`
  head stays `run_const_expr_driver tds dr_st`? [AGENT] recommendation:
  N-ary (smaller, one rule).
- **Q-C:** the seeded `digest` inside the mini-run — pass the caller's
  `Symbol.digest ()` (renders as the desugarer's binder on Lean, the
  global on OCaml): identical values by §3's per-TU rule.
- **Q-D (E-A shape of the hand-written layout functions):** whether
  `CerberusImpl.sizeof_ity`/… take the map as a leading parameter with
  the lem vals declared `reader_consumer` (16 more consumers; every
  generated caller lifts — most already are, via `tagDefs`), or
  `normalise_integerType`/`typeof_enum` move INTO lem (shared body,
  `enum_definitions ()` read → lifted automatically; the target_reps
  for the four `*_ity` functions then need the normalised type passed
  — an OCaml-side signature change the design note forbids). The
  charter must choose; the consumer-count gate depends on it.
- **Q-E:** `CoreParser.mkSym`'s `""` digest (`CoreParser.lean:242-243`)
  is untouched (item 6 of the consumer's note); the theorem `"" ≠ d`
  for the entry's `d` is the D-A payoff — the entry-shape pin ("32 hex
  digits") is the test to write.
- **Q-F:** the libc dump's digest value under D-A: today
  `md5Hex dumpContent` (`Main.lean:616`), a provenance-only value
  (`:611-613`); it becomes the reader value for the dump-parsing stage
  — `md5Hex` stays a pure extern (the one `EXTERN` row that survives).

## 6. Evidence

`lean_frontend/docs/2026-09-19_program-data-parameters-S0-evidence/`
(`INDEX.txt` = sha256 of every file): `probe/` (the 8 `.lem` programs,
`ProbeImpl.lean`, `ProbeImplWrong.lean.txt`, the three check files,
`lakefile.lean`, `lean-toolchain`), `generated/` (the 10 generated
`.lean` files exactly as lem emitted them), `logs/` (`lem_version.txt`;
`gen_*.log` per program; `build_positive.log` (the green build),
`build_neg_assert.log`, `build_neg_wrong_order.log`,
`build_positive_regreen.log`). Reproduce: copy `probe/` beside a
`lean-lib/` = `git archive f6542f8 lean-lib` from `deps/lem-pinned`,
generate with the §1.2 command, `scripts/capped lake build` in the
probe dir (toolchain 4.28.0).

## 7. Gates (charter §4)

- The scratch package compiles the generated Lean: `Build completed
  successfully (45 jobs).` (§1.4); `#print axioms` on the lifted defs =
  the trio or fewer (verbatim in §1.4).
- `git status` before the commit: only the record and the evidence dir
  are untracked; no tracked file modified (verified after every build).
- No lane was run (none chartered). No repository code, lem, OCaml,
  script, test, baseline, allowlist, register or lakefile was touched;
  `lem-lean`/`deps/lem-pinned` untouched (the LemLib copy was a `git
  archive` into `.tmp/`).

**Slice ends here.** Next: the paired lem-lean slice S0.5 (§1.6), then
the E-A/D-A charter with §1.6's rules and §5's questions.
