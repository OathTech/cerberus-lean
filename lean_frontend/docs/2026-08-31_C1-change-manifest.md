# C1 Lean-side change manifest (recipient: refined-cerberus)

Date: 2026-08-31. Branch `arc/effect-retirement`, C1 adoption slice
(charter `2026-08-31_effect-retirement-design.md` R3.1 §8.1 —
"the LEAN-SIDE CHANGE MANIFEST at the adoption pin"). Lem pin:
LemLib @ `af5df71` (L0+L1 features). Provenance [AGENT]; signatures
below are quoted from the generated/hand-written tree at the C1
adoption commit. Finalized again at C2 for the deletion-slice deltas.

STATUS: finding C1-F1 was ADJUDICATED and the rebaseline EXECUTED
([USER 2026-09-01]: Q1b re-affirmed over the enlarged class, O6(v)
re-ruled, admission basis = re-derive-and-verify via the committed
`scripts/check_renumber_only.py` instrument — 70/70 moved rows
admitted, 0 findings among them; record §§10-12). One registered
gate-(a) finding stands: C1-F2, the libxml2-uri LEAN_NOLIBC
diagnostic embedding a raw symbol id (re-pinned as an instrument
change; upstream candidate). Consumer-relevant addendum: the enlarged
renumbering class means ORACLE-side symbol ids in pinned Core dumps
moved on most multi-draw TUs (call-argument batches included), all
permutation-only — consumer-invisible per non-goal 3 (§1.4), but any
consumer artifact caching oracle dump text should re-derive.

## 1. The headline: `runEffectful` is out of the generated tree

- Applied `runEffectful` sites in `generated/`: **0** (was 9). The
  axiom itself still exists in LemLib (dies in L2); no cerberus-lean
  constant's compiled path reaches it any more.
- `declare {lean} effectful` sites in the model: **0** (was 3).
- The `@[never_extract, noinline]` armour class disappears from
  generated defs with the mechanism; the digest boundary
  (`CerberusFresh.digest`/`forceIO`) keeps its armour verbatim
  (conversion to kernel-checked opaque is C2).

## 2. Entry constructors (the shape-(b) supply-parameterized entries)

Every supply-lifted entry takes the current supply as a leading `Nat`
(after reader binders) and returns the advanced supply paired with its
result. The consumer's theorems gain a ∀-supply quantifier (the
consumer-ratified strengthening; charter §1.3 entry-shape decision).

| Constant | OLD signature | NEW signature |
|---|---|---|
| `initial_driver_state` | `file' → fs_state → driver_state` | `Nat → generic_file Unit core_run_annotation → CerbFS.FsState → driver_state × Nat` |
| `initial_core_run_state` | `Fmap sym (labeled_continuations …) → core_run_state` | `Nat → Fmap sym (labeled_continuations …) → core_run_state × Nat` |
| `initial_core_run_state_given` (NEW, pure) | — | `Nat → Fmap sym (labeled_continuations …) → core_run_state` (explicit seed, `sym_supply := sup`, no draw) |
| `initial_driver_state_with` (NEW, pure) | — | `core_run_state → file' → fs_state → driver_state` (the record builder, factored) |
| `initial_driver_state_given` (NEW, pure) | — | `Nat → file' → fs_state → driver_state × Nat` (explicit seed; consumes exactly one draw — the mini-run's builder) |
| `Symbol.fresh` (family) | `Unit → sym` | `Nat → Unit → sym × Nat` (likewise `fresh_pretty`, `fresh_cn`, `fresh_pretty_with_id`, `fresh_fancy`, `fresh_object_address`, `fresh_funarg`, `fresh_description`) |
| `Symbol.fresh_given_int` | unchanged | `Nat → sym` (pure, still the explicit-seed builder) |

The full supply-lifted set is exactly these 10 generated defs
(8 `Symbol.fresh*` + the two init constructors) — enumerated by the
gate-item-(b) check: **no supply-lifted `Let_def`-bound top-level
VALUE exists in the adopted cone** (zero `lemLetRhs_*` in the tree;
every lifted def is a `Fun_def`).

`drive` is **unchanged**:
`drive : Fmap sym (Loc × tag_definition) → Bool → generic_file Unit core_run_annotation → List String → ndM driver_result …`
(its one reader binder predates this arc). `driver2`, `hack`,
`finalize` signatures unchanged (reader binder as before).

## 3. The tagDefs argument's fate (the load→seed loop, closed)

- The CerbTags GLOBAL is deleted (externs, `native/tags.c`, the
  `with_tagDefs` kernel-checked opaque + witness machinery, and the
  Main set/reset writes). `CerbTags.lean` = the `TagDefsMap` type + a
  fail-closed coverage stub.
- `drive`/`RelSem.Cerb.callND` are seeded `runFile.tagDefs` directly
  (the value in hand — Main.lean).
- The boundary-opaque expectation list shrinks: `with_tagDefs` LEAVES;
  `forceIO` stays exactly-once (`check_theorem_axioms.sh` updated).
- `Ctype_aux.with_tagDefs` on Lean is now the plain application
  (lem body `f ()`); on OCaml it keeps the `Tags.with_tagDefs`
  whole-extent redirect.

## 4. The memory ops (reader_consumer; mem.lem §4.2)

16 mem.lem vals are `declare {lean} reader_consumer`: their generated
call sites pass the reader parameter (`_lemReader_tagDefs`) as an
extra LEADING argument, and the CerbMem implementations take it
explicitly. The set (= the measured CerbMem global-read closure):

`allocate_object, load, store, diff_ptrval, validForDeref_ptrval,
isWellAligned_ptrval, array_shift_ptrval, member_shift_ptrval,
eff_array_shift_ptrval, eff_member_shift_ptrval, memcpy, memcmp,
realloc, sizeof_ival, alignof_ival, offsetof_ival`

New hand-written signatures (leading param first):

- `CerbMem.loadM : TagDefs → Loc → ctype → PointerValue → memM (Footprint × MemValue)`
- `CerbMem.storeM : TagDefs → Loc → ctype → Bool → PointerValue → MemValue → memM Footprint`
- `CerbMem.allocateObject : TagDefs → Nat → prefix0 → IntegerValue → ctype → Option Int → Option MemValue → memM PointerValue`
- `CerbMem.sizeofIval/alignofIval : TagDefs → ctype → IntegerValue`
- `CerbMem.offsetofIval : TagDefs → TagDefsMap → sym → identifier → IntegerValue`
  (first = the ambient/global role; second = the lem-side threaded map
  argument, as before)
- shifts/memcpy/memcmp/realloc/deref/align: same pattern.

Internal layout family: the `*_lemFuel` workers gain an
`(ambient : TagDefs)` parameter used at EXACTLY the former global-read
sites (the union arms of sizeof/alignof + the byte-codec/offsetsof
reads); the threaded `tagDefs` parameter (upstream's `~tagDefs`) is
untouched — the upstream union-arm asymmetry is preserved
member-for-member. The default wrappers
(`sizeofCtype`/`alignofCtype`/`offsetsofMembers`/`memberAlign`/
`offsetsof`/`memValueToBytes`/`reconstructValue`) take the ambient
value instead of reading a global.

Phase-appropriateness: `desugar` and `translate` are now reader-lifted
(their cones reach the consumer ival entries); Main seeds their reader
argument EMPTY — the oracle's reset-then-elaborate global state — so
the pinned elaboration-time union-arm crash pair
(`offsetof-union-member`) keeps its behavior. At execution, the reader
value is the linked table.

## 5. The frontend entries (supply + reader threading)

| Constant | NEW signature (leading binders) |
|---|---|
| `desugar` | `TagDefsMap → Nat → coreEvalStuff → init_scope → String → translation_unit → exceptM (fin_markers_env × ail_program Unit × Nat) Errors.error` |
| `translate` | `TagDefsMap → Nat → (Fmap String sym × fun_map Unit) → calling_convention → impl → ail_program genTypeCategory → (file Unit × Nat)` |
| `annotate_program`, `link`, `convert_file` | **unchanged** |
| `Mini_pipeline.evalConstantExpressionAux` | `TagDefsMap → Nat → Loc → … → exceptM (value × Nat) Errors.error` |
| `Mini_pipeline.evalIntegerConstantExpression` | `TagDefsMap → Nat → Loc → … → exceptM (integer × Nat) Errors.error` |

Main threads ONE supply (S1 single stream, seeded 0): per-TU
desugar → (typing) → translate → … → `initial_driver_state`. The
former 2^20 desugar/ambient stratification, `native/fresh_int.c`, and
the startup floor probe are deleted — collision-impossibility is
structural (one stream).

## 6. step_ctx cone, driver round path, finalize/Driver.hack

- `step_ctx`, `advance_step`, `process_core_step2`,
  `drive_nonmemory_steps_aux2`, `driver2`, `finalize`, `hack`: NO
  signature changes in this slice (their reader binders predate the
  arc; no supply reaches them — run-time minting was already threaded
  through `core_run_state` since arc-2/13).
- The driver round path (`Driver.lean` drive → driver2 →
  drive_nonmemory_steps_aux2) is textually re-emitted by the new lem
  (whitespace/paren normalization from the L0/L1 emitter work) but
  semantically identical; the only cone-visible change is
  `initial_driver_state` (§2).
- `Core_linking` change: `setChoose` now takes `setElemCompare`
  (the L0 M4 comparator-minimum fix; one hunk, `Core_linking.lean`).

## 7. RelSem (the statement layer the consumer re-exports)

- `RelSem.Cerb.initConfig`, `HarnessAdequate`, `HarnessAdequateM`,
  `HarnessUBFree`, `DriveReaches` gain a `(supply : Nat)` parameter
  (immediately after `tagDefs`) and build the state via
  `(initial_driver_state supply file1 fs).1` — the ∀-supply
  quantifier the consumer review pre-ratified as a strengthening.
- `RelSem.Cerb.callND` signature UNCHANGED (its `tagDefs` argument was
  already explicit); internally its allocateObject/storeM/alignofIval
  uses pass that argument through.

## 8. The fuel side-condition statement (gate item d)

> **ERRATUM (2026-09-03, FUEL arc; two independent verifications).**
> The apply-condition statement below — "**zero** current lane
> baselines contain a fuel-exhaustion row (measured: grep over every
> `exec_*baseline*.txt` + expectations — no fuel classification
> exists)" — was FALSE when written. At the C1 commit `c7cb5380d` the
> committed baselines already carried fuel-death rows:
> `scripts/gcc_oracle_baseline.txt:1145` (`csmith/sia_csmith_477.c
> SKIP_LEAN_CRASH`) and `:1437` (`csmith/sia_csmith_769.c
> SKIP_LEAN_CRASH`), and `scripts/exec_csmith_corpus_baseline.txt:1177`
> / `:1469` (the same two files, `LEAN_CRASH`), whose fuel attribution
> predates C1 (`docs/2026-08-21_arc10-results.md:365`,
> `docs/2026-08-20_arc10-s4-csmith-campaign.md:434`,
> `docs/2026-08-30_gcc-oracle-lane-record.md:71`). The measurement was
> VACUOUS: no fuel class existed to grep for, and the glob
> `exec_*baseline*.txt` excluded `gcc_oracle_baseline.txt`.
> Verification 1: the FUEL-arc design note's author, at `2c7c9347b`
> (`docs/2026-09-02_fuel-arc-design.md` §0.4/§0.5). Verification 2:
> the R1 reviewer, re-run via `git show c7cb5380d:scripts/…` (same
> note, §0.5). The deferral decision itself is superseded: the budget
> is applied by the FUEL arc (design note §4); the rows above move to
> the FUEL class (§3.3). The text below is kept verbatim as the record
> of what was decided at the time.

Per-declaration fuel budgets (L1 feature `declare {lean} fuel val f =
N`) are **NOT applied in C1** — decision RECORD-AND-DEFER, [AGENT]:

- Sizing decision, justified against
  `docs/2026-08-31_stack-ceiling-design.md`: the correct application
  is a **10^8 budget on the whole coupled family** —
  `drive_nonmemory_steps_aux2`, `driver2`, `print_eval_conv_aux`,
  `hack` (driver.lem quartet) **plus** the substrate `nd_bind`
  (nondeterminism.lem) and the hand-written `CerbND.ndDefaultFuel` —
  because the family is coupled at 10^6 (raising one member is
  vacuous; stack-ceiling §4). 10^8 puts the loud edge at ~7-50 min of
  single-invocation stepping (below the grind horizon); 10^9+ would
  not be.
- Application deferred because the brief's apply-condition is not
  met in the improving direction: **zero** current lane baselines
  contain a fuel-exhaustion row (measured: grep over every
  `exec_*baseline*.txt` + expectations — no fuel classification
  exists), so applying budgets moves NO lane row oracle-ward; the
  benefit is headroom only, while the consumer-visible cost is
  re-stating the exported fuel side conditions (today uniformly
  `lemDefaultFuel`) against per-declaration constants — churn that
  should not ride the same re-certification as the entry-shape change.
- CONSUMER IMPACT STATEMENT: as of C1 every exported statement's fuel
  side condition remains exactly `lemDefaultFuel` (= 10^6),
  byte-unchanged. When the deferred budget lands (follow-up slice),
  the family above moves to its own constant and the consumer's
  side conditions for the drive cone re-state against it; all other
  declarations keep `lemDefaultFuel` verbatim (the L1 opt-in
  guarantee, held structurally).

## 9. What the consumer must re-certify (scoped)

1. The entry re-exports: `initial_driver_state` (new shape, §2) and
   the RelSem statement wrappers (§7) — mechanical ∀-supply
   quantification.
2. Any lemma naming `CerbMem.loadM/storeM/allocateObject` (or the
   other 14 consumer entries): one new leading argument (§4).
3. Nothing else in the exec cone changed shape; `drive`/`driver2`/
   step relation signatures are stable.
4. Axiom-cone expectation: `initial_driver_state` and `translate` are
   now clean of `runEffectful` (kernel cone ⊆ the standard three);
   the LemLib axiom deletion itself is L2/C2.

## C2 finalization addendum (2026-09-01, the deletion-slice deltas)

Lem pin: LemLib @ `045dcb0` (L2 deletion head). Provenance [AGENT]
(C2 worker). The C2 slice changes NOTHING the consumer quantifies
over — the full delta, enumerated:

1. **Generated Lean tree: byte-identical** under the L2 lem (verified
   by clean re-derivation + diff at the C2 pin bump). No definition
   in the exec cone changed name, type, or body. The C1 signatures
   quoted above are final for the arc.
2. **LemLib now declares ZERO axioms** — `runEffectful` and its
   scaffold are deleted (L2 `faa9fe4` + `045dcb0`); the universal
   contract form (charter §1.3) holds and is gate-enforced
   consumer-side: every constant in this repo and in LemLib has axiom
   cone ⊆ [propext, Classical.choice, Quot.sound]
   (check_theorem_axioms.sh C2 ratchet — recursive LemLib census,
   runEffectful token ban, seam-population pin, 9-entry exact
   census). `LemLib.supplySplit` is unchanged.
3. **`CerberusFresh.digest` is now a kernel-checked opaque** (was
   opaque + unsafeBaseIO impl): name and type unchanged
   (`digest : Unit → String`), explicit witness `fun _ => ""`;
   compiled behavior verified byte-identical (differential spot-run,
   C2 record §2). Consumer proofs cannot unfold it — same as before;
   nothing postulated — same as before (it was never an axiom).
4. **`declare {lean} effectful` is a lem generation-time refusal**
   (the L2 refusal decision) — reintroduction of the deleted
   mechanism is structurally impossible without a conscious lem-side
   revert.
5. The rebaseline-admission instrument was hardened (string/comment
   aware; scripts/check_renumber_only.py) with all 70 C1-admitted
   rows re-verified verdict-unchanged — no pinned artifact moved at
   C2.

Acceptance: the §1.3 customer contract is declared MET at this pin
(VALIDATION.md §5 item 4 is the standing statement; the gate is its
enforcement).
