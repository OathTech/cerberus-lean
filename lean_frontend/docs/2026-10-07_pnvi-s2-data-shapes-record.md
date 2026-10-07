# PNVI arc S2: the PNVI data shapes and the `reconstructValue` compatibility wrapper — slice record (2026-10-07)

Branch `arc/pnvi-ae-udi`, from mainline `mdd/cerberus-lean` = `47348c07e` plus the three
design-record commits (`3a9ebfd8e`, `f463b2c69`, `bafe19351`). Worker: Claude Opus 5.5
(agent). Every judgement that no operator quote covers is marked [AGENT]. Quoted gate
output is verbatim; counts marked "derived" are mine. The lem used is the shared
`2d3a492` (the pin; `lem -v` = `Lem lean-backend-v0.1.0-alpha.1-65-g2d3a492`); no private
lem was built.

**Gated tree:** commit `842720565` (the S2 code commit), clean worktree. This record is a
separate docs-only commit on top of it; no Lean, script, lakefile or register byte
differs between the two (§8).

## 0. Rulings in force (verbatim) and governing documents

- [USER 2026-10-03], no innovation: "… we should fall back to loudly rejecting (either as
  unsupported, or matching upstream)".
- [USER 2026-09-30], no magic modes: "… we should not fix deviations with special 'magic
  mode' paths that work exclusively in one situation …".
- [USER 2026-10-05]: "Re PNVI - agree on your recs except for mirroring crashes / obviously wrong
  behavior. These should be refusals surely?"
- [USER 2026-10-07], on gates: "… we don't want our gates to be adversarially robust unless
  they are trust surfaces".
- Design record `docs/2026-10-04_pnvi-ae-udi-design.md` §0, §A (§A.3), §B.0, §B.7, §E row
  S2, §G, §H (whose verbatim [USER 2026-10-05] answer accepts the §F.15 refusal of
  `:840-842` and, for §F.16, "for now (a) is fine" — the `CerbFS` refusal shape).
- S1 record `docs/2026-10-05_pnvi-s1-switch-parameter-record.md` (the `[CerbGlobal.Switches]`
  threading; §14, rule W1).

The slice is an internals refactor with ZERO default-mode behaviour change (§6).

## 1. New definitions, with their OCaml cites

All in `lean_frontend/CerbMem.lean` unless stated; OCaml = `memory/concrete/impl_mem.ml`
of this tree. Line numbers are this commit's.

**Superseded by S3 D-S3-1** (`docs/2026-10-07_pnvi-s3-arms-record.md` §9): the monadic iota-helper signatures below (`exposeAllocation(s)`, `addIota`, `lookupIota`, `resolveIota`) are now state functions; this table stays the S2 record (pointer added by arc-end audit F5).

| Definition | Lean | OCaml | Note |
|---|---|---|---|
| `inductive IotaEntry` (`Single id` / `Double id1 id2`) | :144 | :490 | `deriving BEq, Inhabited, Repr` |
| `inductive ProvTaint` (`NoTaint` / `NewTaint ids`) | :154 | :951 (abst's result), :462-479 | named so as not to clash with the existing allocation flag `Taint` (deviation D2) |
| `inductive OverlapResult` (`NoAlloc` / `SingleAlloc` / `DoubleAlloc`) | :162 | :796-798 | |
| `MemState.iotaMap : Std.TreeMap Int IotaEntry := Std.TreeMap.empty` | :200 | :490, :513 | was `List (Int × Int) := []`; same representation as `allocations`/`bytemap` (arc-6 S3, `IntMap = Map.Make(Z)`, :93) [AGENT: the map type the rest of the state already uses for `IntMap`s; ordered keys, `get?`/`insert`/`modify` are the OCaml `find`/`add`/`update`] |
| `splitBytesProv` (status component fixed) | :760 | :432-453 | `.2` = `ValidPtrProv` iff all provenances equal AND offsets consecutive from 0 (:449-453); the `INVALID` case used to give `true`; `.1` and its text unchanged (deviation D5) |
| `pnviRefusal (detail)` | :780 | — | the one refusal message: prefix `PNVI_ae_udi refusal (unsupported upstream arm): `, then the row/site/upstream text, then `— refused, not mirrored (… design record …§G/§H)` (review fix F6 removed a `[USER 2026-10-05]` tag that stood on a paraphrase) |
| `provsOfBytes` | :794 | :462-479 | fold that conses (last byte's id first); `Prov_symbolic` arm refused (R-PNVI-01b, §2) |
| `mergeTaint` | :807 | :967-975 | |
| `mkIval [Switches]` | :817 | :670-677 | `is_PNVI` → `IV Prov_none n`, else `IV prov n` |
| `mkIval_default`, `mkIval_defaultSwitches`, `is_PNVI_defaultSwitches` | :820-829 | — | `rfl` at `⟨[]⟩` and at the wrappers' instance `⟨CerbGlobal.defaultSwitches⟩` (no `@[simp]`) |
| `findOverlapping [Switches] (st) (addr)` | :859 | :795-875 | the variant table :799-813 (first `SW_PNVI _` of the list: `has_switch_pred` = `List.find_opt`, switches.ml:58-59); fold :814-842; R-PNVI-02 and R-PNVI-03 refused (§2) |
| `allocations_foldl_ascending` (theorem) | :887 | — | the order argument (below) |
| `reconstructValueAbst_lemFuel [Switches] (lemFuel) (enumDefs) (ambient) (findOverlapping : Address → OverlapResult) (unionmap) (funptrmap) (addr) (ty) (bytes) : ProvTaint × MemValue` | :1252 | :945-1128 (`abst`) | the full `abst`: switch set, closure, taint; the `is_PNVI` pointer arm :1057-1088 (R-PNVI-05 refused) |
| `reconstructValueAbst` (measured wrapper, `envBound`) | :1449 | — | |
| `noOverlapping : Address → OverlapResult := fun _ => .NoAlloc` | :1460 | — | the closure the default-pinned wrappers fix; never consulted there |
| `reconstructValue_lemFuel`, `reconstructValue` (OLD names, OLD types) | :1475, :1485 | — | the compatibility wrappers (§3) |
| `exposeAllocation` | :2251 | :877-886 | `Std.TreeMap.modify` = `IntMap.update` with `None -> None` |
| `exposeAllocations` | :2257 | :887-901 | |
| `addIota` | :2267 | :903-909 | |
| `lookupIota` | :2279 | :911-914 | missing iota refused (R-PNVI-04, §2) |
| `inductive IotaPrecond` (`OK` / `FAIL loc err`) | :2289 | :917-942 | the precondition outcome |
| `resolveIota [LemFuel] (precond : StorageInstanceId → memM IotaPrecond) (iota)` | :2298 | :916-942 | `Single` → precond; `Double` → first, else second, else the SECOND failure; then collapse to `Single`; `FAIL (loc, err)` = `memFail err loc` (`fail`, :575; corrected from ":540-546" by review fix F5) |

`CerbMem_lemMeasureProofs.lean`: `reconstructValueAbst_stable_aux` (:949) and
`reconstructValueAbst_measure_sufficient` (:1040) — the old proof restated over the new
worker (the instance and the closure are fixed through the induction, the taint rides
along); `reconstructValue_measure_sufficient` (:1058, statement unchanged) is now
`congrArg Prod.snd` of the new obligation at `⟨CerbGlobal.defaultSwitches⟩`/`noOverlapping`.
The old `reconstructValue_stable_aux` is gone (replaced). New row of
`scripts/fuel_hypotheses.txt`: `CerbMem.reconstructValueAbst_lemFuel` under
`CerbTagsWf.Acyclic ambient`, same invariant and cites as the `reconstructValue_lemFuel`
row, reviewer `[AGENT worker 2026-10-07, PNVI arc S2] … ; [USER] sign-off at merge`.

**`loadM`** (CerbMem.lean :2686, the only production caller) now runs
`(reconstructValueAbst enumDefs tagDefs (findOverlapping st) st.lastUsedUnionMembers
st.funptrmap addr ty bytes).2` — the ambient switch set, the `find_overlaping st` closure
(:1600). The taint is discarded: load's `expose_allocations` (:1602-1606) is an S3 arm,
and at the default set the OCaml arm is `return ()`.

**The order argument (findOverlapping).** OCaml folds with `IntMap.fold`, which visits
keys in increasing order (`Map.S.fold`; `IntMap = Map.Make(Z)`, `Z.compare`). Lean folds
with `Std.TreeMap.foldl`. `allocations_foldl_ascending` proves two facts:
`st.allocations.foldl f init = st.allocations.toList.foldl (fun a b => f a b.1 b.2) init`
(`Std.TreeMap.foldl_eq_foldl_toList`), and `toList` is pairwise strictly ascending under
`compare` on `Int` (`Std.TreeMap.ordered_keys_toList`). So both folds visit the same
allocations in the same order, and `DoubleAlloc (first, second)` is the same pair.
`resolveIota` tries `first` first. A runtime control pins `DoubleAlloc 0 1` on a two-allocation
state (§5).

## 2. The §G refusals placed in S2

The shape is `failwithI (pnviRefusal "<R-PNVI-nn>: <site> — impl_mem.ml:<lines> <upstream text> …")`,
the `CerbFS` shape ruled in §H. Each refusal is in a definition S2 adds. Each is unreachable at
`⟨[]⟩` (the reasons are in the failure-reach register rows below).

| Row | Site | Lean | Upstream text | §G class | Register row |
|---|---|---|---|---|---|
| R-PNVI-01b | `provsOfBytes`, `Prov_symbolic` byte | :794ff | `:470-471` `Prov_symbolic iota -> acc (* TODO(iota) *)` | R2, shadowed-(A) | NEW, `NON-TAIL/LAMBDA-BODY`, UNREACHABLE-BY-INVARIANT (config: no `Prov_symbolic` minted at the default set) |
| R-PNVI-02 | `findOverlapping`, non-PNVI switch matched | :859ff | `:810-811` `Some _ -> assert false` | R3, (A) | NEW, `NON-TAIL/LET-BOUND`, UNREACHABLE-BY-INVARIANT (structural: `find?`'s predicate admits only `.PNVI _`) |
| R-PNVI-03 | `findOverlapping`, a third candidate | :859ff | `:839-842` `DoubleAlloc _, Some _ -> (* TODO: I guess there is an invariant … *) acc` | R4, (D), ruled REFUSE §H | NEW, `NON-TAIL/LAMBDA-BODY`, UNREACHABLE-BY-INVARIANT (config: the closure is applied only in the `is_PNVI` branch) |
| R-PNVI-04 | `lookupIota`, iota absent | :2279ff | `:912-914` `IntMap.find iota st.iota_map` (raises `Not_found`) | R5, (A) | none yet: `lookupIota` is outside the exec dependency closure in S2 (nothing calls it). It gets a row in S3 when the arms call it |
| R-PNVI-05 | `reconstructValueAbst_lemFuel`, pointer arm, `NotValidPtrProv`, `DoubleAlloc` | :1252ff | `:1079-1082` `(* FIXME/HACK(VICTOR): This is wrong, … *) Prov_some alloc_id1` | R6, (C) | NEW, `NON-TAIL/LET-BOUND`, UNREACHABLE-BY-INVARIANT (config: inside `if CerbGlobal.is_PNVI () then`) |

**Not placed in S2** (S3 places them with their arms): R-PNVI-01 (`combineProv`: the
existing `failwithI` keeps its OCaml text in S2; the site predates S2), -06 (pure
`array_shift_ptrval`), -07 (`case_ptrval` symbolic half), -08 (`diff_ptrval` invariant),
-09 (`eff_array_shift_ptrval` PVfunction) and -10 (the debug-print arm). R-PNVI-11/12 (the CLI)
are already S1's `--switches` refusals.

**Failure-reach register** (`scripts/failure_reach_register.txt`, resealed with
`check_failure_reach.py --reseal`):
- the six `reconstructValue_lemFuel` rows are re-keyed to their new owner
  `CerbMem.reconstructValueAbst_lemFuel`. Their reach class, need and cite are carried over
  unchanged.
- Five of them moved from live `STMT-NEWLINE`/reviewed `TAIL` to live `TUPLE-OR-LIST`. The
  funptr row stays live `STMT-NEWLINE`. All six are reviewed `NON-TAIL/TUPLE-OR-LIST`, with a
  dated note. The reason [AGENT]: the leaf is now the VALUE component of the returned pair. The
  pair is built strictly, and every consumer takes that component (`loadM`'s `.2`, the array
  arm's `rs.map Prod.snd`, the struct/union arms' `r.2`, the wrappers' `.2`).
- four new refusal rows were added (above).
- The tally moved from `sites=233 … reviewed-TAIL=180 reviewed-NON-TAIL=53
  UNREACHABLE-BY-INVARIANT=172` to `sites=237 exec=235 unresolved-owner=2 reviewed-TAIL=174
  reviewed-NON-TAIL=63 UNREACHABLE-BY-INVARIANT=176 REACHABLE=40 UNKNOWN=21 discardable=0`.

## 3. The consumer compatibility wrapper (design §B.7) and its equality theorem

```lean
def reconstructValue_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int)
    (ty : ctype) (bytes : List AbsByte) : MemValue :=
  (@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient noOverlapping unionmap funptrmap addr ty bytes).2

def reconstructValue (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int)
    (ty : ctype) (bytes : List AbsByte) : MemValue :=
  reconstructValue_lemFuel (CerbTagsWf.envBound ambient ty) enumDefs ambient unionmap funptrmap addr ty bytes
```

How the design's three conditions are met:
- **(a) the pin is EXPLICIT:** `⟨CerbGlobal.defaultSwitches⟩`, never the ambient instance.
  The old names take no `[Switches]` binder; their types are unchanged.
- **(b) no production caller:** checked by speedbump W2 (§4).
- **(c) proved equal to today's value, kernel-checked:** the test module
  `lean_frontend/test/Unit/ReconstructLegacyTest.lean` (row-1 exe `reconstruct-legacy-test`)
  keeps the pre-S2 text as `reconstructValueLegacy_lemFuel` / `reconstructValueLegacy`.
  - MEASURED: the 337-line pre-S2 block of `CerbMem.lean` at `47348c07e`, with the renames
    applied mechanically, occurs verbatim in the test module. The check printed
    `VERBATIM_AFTER_RENAME 337`.

The theorems (all in namespace `ReconstructLegacyTest`):

```lean
theorem reconstructValueAbst_default_snd_eq_legacy (fo : Address → OverlapResult) :
    ∀ (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
      (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte),
      (@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient fo unionmap funptrmap addr ty bytes).2 =
        reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes

theorem reconstructValue_lemFuel_eq_legacy (lemFuel …) :
    CerbMem.reconstructValue_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes =
      reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes

theorem reconstructValue_eq_legacy (…) :
    CerbMem.reconstructValue enumDefs ambient unionmap funptrmap addr ty bytes =
      reconstructValueLegacy enumDefs ambient unionmap funptrmap addr ty bytes

theorem loadM_reconstruct_default (st : MemState) (…) :
    (@reconstructValueAbst ⟨CerbGlobal.defaultSwitches⟩ enumDefs ambient (@findOverlapping ⟨CerbGlobal.defaultSwitches⟩ st)
        st.lastUsedUnionMembers st.funptrmap addr ty bytes).2 =
      reconstructValueLegacy enumDefs ambient st.lastUsedUnionMembers st.funptrmap addr ty bytes
```

- **What they say.** The first theorem holds for EVERY closure: at the default set the closure is
  never consulted and the taint is discarded. The last one is about the reconstruction SUBTERM
  that `loadM`'s `doLoad` builds (`(reconstructValueAbst … (findOverlapping st) …).2`), at the
  default set, for every state — not a statement about `loadM` itself (wording corrected by review
  fix F2).
- **Proof.**
  - Fuel induction, following the template of the retired `reconstructValue_lemFuel_eq_indexed`.
  - Scalar and pointer arms: `rfl`. The pointer arm's `if is_PNVI ()` reduces at the instance.
  - Array arm: `List.map_map` plus the induction hypothesis.
  - Struct arm: a fold-fusion lemma `foldl_snd_eq`.
  - Union arm: `cases` on each discriminant.
- **Axiom cones** (`#print axioms`, from the build): each is `[propext, Classical.choice, Quot.sound]`.
- **The axiom gate.** Its mem-scale leg now pins these four theorems plus the retired C1
  equalities (§4).

**The C1 reference form is retired** (design §B.7, recommended "retire into the test
module (production carries one implementation)").
- `reconstructValue_indexed_lemFuel` and its two equalities left `CerbMem.lean`.
- In the test module they are restated over the legacy copy as
  `reconstructValueLegacy_indexed_lemFuel` and `reconstructValueLegacy_lemFuel_eq_indexed` /
  `_eq_indexed` (the old proof verbatim).
- They are chained to the production wrapper as `reconstructValue_lemFuel_eq_indexed` /
  `reconstructValue_eq_indexed`, with their pre-S2 statements.
- Consumer uses of the retired names: 0 (MEASURED grep of cerberus-sl, §7).

**The fuel-forms classifier** accepted the non-recursive `_lemFuel` wrapper as MEASURED.
- The design's fallback (drop the `_lemFuel` old name, §B.7 "The fuel-forms gate") was NOT needed.
- MEASURED: `check_fuel_forms: OK (81 fuel'd workers: 63 MEASURED … 13 of them under a hypothesis …`.
  The S1 figures were 62 MEASURED, 12 under a hypothesis, and 6 ambient unreachable.
- Now 5 ambient unreachable. The retired C1 worker, an ambient reference form, left the
  environment the tool imports (derived).

## 4. The speedbump check (rule W2) and its class

`scripts/check_no_fuel_numerals.sh` rule **W2** (one rule in an existing script, next to W1):
- **What it flags.** A mention of `reconstructValue` / `reconstructValue_lemFuel`, bare or
  `CerbMem.`-qualified, in PRODUCTION Lean text is RED. Production text means the hand-written seams
  `lean_frontend/*.lean` and the generated tree `lean_frontend/generated/*.lean`.
  - Comments AND string literals are stripped.
  - The `*_lemMeasureProofs` proof carriers are excluded.
  - Exception: the wrappers' own two definition lines and the fuel-free wrapper's body line in
    `CerbMem.lean`, allowlisted by exact content in both copies.
- **Vacuity guard.** At least one allowlisted line must be seen. The OK line reports
  `W2 wrapper lines seen: 6 of 6`.
- **Selftest plants**, each RED with the label W2:
  - a `loadM`-shaped call in the seam `CerbMem.lean`;
  - a qualified `CerbMem.reconstructValue_lemFuel` call in `generated/Driver.lean`.
  - The selftest total is now 31.
- **No false positives on the real tree.** The real tree passes, although it contains
  `reconstructValueAbst…` names and the failure strings `"CerbMem.reconstructValue: …"`.

**Class: SPEEDBUMP, not a trust surface** [AGENT, under [USER 2026-10-07] "… we don't want our
gates to be adversarially robust unless they are trust surfaces"].
- **Reason.** At the default set the two functions agree: kernel theorem
  `reconstructValueAbst_default_snd_eq_legacy`. So a stray call moves no lane today. It matters
  only once a PNVI set is accepted (S4).
- **Scope**, stated in the script header and the VALIDATION.md row:
  - It catches a plain textual call.
  - It is not robust against an alias (`abbrev`, `export`, `open … renaming`), a call from
    `test/`/`speclab/`, or a raw-string desync.
  - Backstops: review, and the S4 PNVI lane, where a default-pinned reconstruction would
    diverge from the oracle.

**W1 housekeeping (deferred from S1).** One line was added to the W1 scope header:
- An instance with a `[CerbGlobal.Switches]` binder after a binder with a colon trips W1. This
  is an accepted false positive.
- The one-line `instance (priority := …) : Switches` form is not caught. This is speedbump scope.

**S1 record pointers.** "superseded by §14" was added at the S1 record's §2 bullet on
`check_switches_instance.sh` and at its "instance gate's count is 109" line.

## 5. Unreachability at `⟨[]⟩` and positive controls

**Kernel facts (`rfl`):**
- `mkIval_default`, `mkIval_defaultSwitches`, `is_PNVI_defaultSwitches`. The S1 lemmas
  `is_PNVI_default` etc. stand.
- `reconstructValueAbst_default_snd_eq_legacy` (∀ closure) is the strong form. Neither the
  `is_PNVI` pointer branch nor `findOverlapping` contributes to the default-mode value.

Which helpers can run at the default set:
- `provsOfBytes` / `mergeTaint` DO run at the default set. They compute the taint, which is
  then discarded. They have no switch dependence. Their one refusal needs a `Prov_symbolic`
  byte, which nothing mints.
- `exposeAllocation(s)` / `addIota` / `lookupIota` / `resolveIota` have no caller in S2.

**Runtime positive controls** (`reconstruct-legacy-test`, 18 checks; output verbatim in §6.2).
They show the PNVI branches are LIVE under a PNVI set, so the default facts are not vacuous:
- `findOverlapping`: the variant table (default / PLAIN / AE / AE_UDI on a two-allocation
  state), the one-past rule, exposure, and the ascending `DoubleAlloc 0 1`.
- `provsOfBytes` order; `mergeTaint`.
- `splitBytesProv`'s fixed status.
- `mkIval` under AE_UDI and at the default set.
- The pointer arm: under AE_UDI it consults the closure (`Prov_some 7`); at the default set it
  does not (`Prov_none`).
- The integer-leaf taint.
- The wrapper at the default set.

No refusal is exercised at runtime: each aborts the process. Their pins belong to S3/S4 (design §D.4).

## 6. Zero-change evidence

1. **No `.lem` file changed** (`git diff --stat 47348c07e..842720565` lists none). So the
   generated OCaml is unchanged by construction.
   - MEASURED: after `make clean-prelude-src prelude-src` in this worktree the OCaml lem-sync gen
     hash is `c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3`. That is the
     value S1 recorded (S1 record §4.3 and §14).
   - MEASURED: the Lean lem-sync gen hash is `aa49e3bf…`, also S1's value. So the Lean lem output
     is unchanged too; only hand-written copies differ.
   - Fork-drift layer 2 did not move ("30 differing generated files, all hash-pinned", §6.1).
2. **OCaml oracle rebuild in this worktree**, cache-disabled:
   - `DUNE_CACHE=disabled dune build --force backend/driver/main.exe cerberus-lib.install`;
   - `dune install --prefix _build/local-install cerberus-lib`;
   - `DUNE_CACHE=disabled dune build --force cerberus.install`;
   - rc 0. The worktree's primed OCaml and Lean generated trees were stale (copied 2026-09-27).
     Both were regenerated with the shared lem before any gate.
3. **Kernel:** the default-mode reconstruction equals the pre-S2 text (§3). The reconstruction
   subterm of `loadM`'s `doLoad` has the pre-S2 value at the default set for every state
   (`loadM_reconstruct_default` — a statement about that subterm, not about `loadM`; wording
   corrected by review fix F2). Every other `loadM` path is textually unchanged.
4. **Lanes:** Tier A on `842720565` (§6.2).
   - Every lane is at its committed baseline.
   - A9 (the C→Core reporting differential) shows the recorded `same=108 diff=5`, so the
     default-mode elaboration is unchanged. The C→Core path is not touched by S2 at all
     (`CerbMem` is the run's memory model).
5. **`PNVI_ae_udi` stays CLI-refused.** `check_cli_refusals: OK (23 refusals pinned …)`. The S3
   arms (`ptrfromint`/`intfromptr`/the `Prov_symbolic` load/store/kill/… arms, load's expose) are
   NOT written. Each remains the loud kill it was.
6. **One test proof needed adjusting.** The SC WP0 erasure theorem
   `MemoryAccessProofs.load_erasure`:
   - Why: `loadM` now passes `findOverlapping st`, a function of the whole state.
   - Symptom: the proof's `simp`/`split` sweep hit `(deterministic) timeout at whnf` (200000
     heartbeats).
   - Fix [AGENT]: one `rfl` lemma, `findOverlapping_observations : findOverlapping { s with
     observations := o } = findOverlapping s`, added to the proof's first `simp only`.
   - The statement is unchanged and no heartbeat option was touched.
   - Its axiom cone is now `[propext, Classical.choice, Quot.sound]` (standard three; earlier
     prints in this tree's docs show both this cone and none).
   - `MemoryAccess.lean`'s explicit state comparison compares `iotaMap.toList` (the TreeMap has no
     `BEq`).

### 6.1 Row 1 (`scripts/test_unit.sh`, via `scripts/ce`, on `842720565`), rc 0

Verbatim selected verdict lines (each distinct line once; the `rc=0` line is my wrapper's).
The fork-drift line also appears indented inside its selftest's plant output; it is quoted
once here:

```
✓ reconstruct-legacy-test PASSED
Total: 17 passed, 0 failed
check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_theorem_axioms: mem-scale S1 leg OK (11 C1/C3 + PNVI-S2 wrapper equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_sorry_token: OK (326 files scanned comment-stripped — generated 221, hand-written+test 70, LemLib 35; 0 sorry tokens)
check_no_fuel_numerals: SELFTEST OK (31 plants red with the declared label — F1-F6, A1-A3, W1 and W2; E5 indirection a recorded known gap; unplanted set green)
check_no_fuel_numerals: OK (333 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3), no switch-set instance declaration (W1), no production call of the default-pinned reconstructValue wrappers (W2); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy); W2 wrapper lines seen: 6 of 6)
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
check_lakefile_roots: OK (220 roots = 220 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
check_fuel_forms: OK (81 fuel'd workers: 63 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 5 ambient unreachable from the drive cone)
check_failure_reach: OK (237 pure failure sites = the 237 register rows exactly (235 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=176 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
ReconstructLegacyTest: 18/18 runtime positive controls passed
rc=0
```

The selftests of the gates S2 touched also passed: `check_fuel_forms: SELFTEST OK (25 plants …`,
`check_failure_reach: SELFTEST OK (8 plants …` and `check_pin_sites: SELFTEST OK (8 plants …`
(their full lines are in the run log, which is scratch).

### 6.2 Tier A (`python3 scripts/release.py --mode fast`, via `scripts/ce`, on `842720565`)

Verbatim row verdicts (the 17 per-row `PASSED` lines joined onto one line; the joining is
mine) and the tail. `rc=0` is my wrapper's:

```
PASSED A1 (638.9s) PASSED A2 (76.6s) PASSED A3 (166.2s) PASSED A4 (66.1s) PASSED A4b (61.3s) PASSED A4c (6.8s) PASSED A5 (187.8s) PASSED A6 (10.9s) PASSED A6b (9.9s) PASSED A7 (20.6s) PASSED A8 (13.5s) PASSED A9 (24.3s) PASSED A10 (24.3s) PASSED A11 (144.7s) PASSED A12.1 (22.8s) PASSED A12.2 (17.8s) PASSED A13 (4.8s)
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

The lanes' own last two output lines, verbatim from the run's evidence directory (scratch,
deleted at slice end). The row labels and the `/` joins are mine:

```
A2   Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A3   Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A4   Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A4b  Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A4c  SUMMARY: exec_match=9 neg_pinned=5 fail=0/ALL AT COMMITTED EXPECTEDS
A5   SUMMARY: match=43 diff=0/ALL MATCH RECORDED BASELINE
A6   SUMMARY: total=8 match=8 fail=0/ALL PASSED
A6b  SUMMARY: total=7 match=7 fail=0/ALL PASSED
A7   cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)/ALL PASSED
A8   Success rate:   100% (of cerberus successes)/ALL PASSED
A9     LEAN_FAIL:  0/SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
A10  GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
A11  BASELINE OK (213 entries, exact match)
A12.2  EXPECT OK    18 pinned rows = 18 observed cases, every token identical/test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
A13  PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls/Evidence: …/.tmp/memory-access/report.json
```

- **A9 DIFF rows.** They are `073-exit.libc`, `074-abort.libc`, `098-cross-alloc-ptrdiff.undef`,
  `112-allocator-exhausted-single-request` and `113-allocator-exhausted-single-request-overlap`.
  These are the five recorded rows (S1 record §7.1: 073, 074, 098, 112, 113).
- **Per-row durations are about 1.8–2.2× S1's** (derived: A1 638.9 s vs 358.1 s; A3 166.2 s vs
  75.1 s). The box was shared: `uptime` printed load averages `24.65, 30.00, 33.00` during the run
  and `41.62, 38.15, 35.27` after it (32 cores).

**A/B timing of the load path** [AGENT sanity check; not a gate]:
- Setup: a C program doing about 14 000 integer loads and 800 struct loads (`.tmp/ab/loads.c`,
  scratch), exported once to cabs-json, then run alternately on the pre-S2 binary
  (`lean_frontend/.lake/build/bin/cerberus-lean` copied at the baseline build of the base tree)
  and the S2 binary. Command: `--batch --runtime=<abs>`, `LEAN_ABORT_ON_PANIC=1`.
- Wall seconds, base/S2 pairs: 9.63/9.88, 9.35/9.31, 9.80/9.92, 7.76/7.78, plus one outlier
  pair each way (10.12/17.11 and 11.94/7.83).
- Both printed `Defined {value: "Specified(160)", stdout: "", stderr: "", blocked: "false"}`.
  The oracle printed the same verdict.
- So there is no slowdown discernible above this box's noise.
- **The W2 rule's own cost.** One gate run took 17.9 s against 13.3 s for the pre-S2 script, timed
  back to back on the same tree. The selftest runs the gate 33 times.

## 7. Deviations from the brief and the design

- **D1 [AGENT] — the new function is `reconstructValueAbst(_lemFuel)`, not the design's
  working name `reconstructValuePNVI`.**
  - It is the GENERAL reconstruction, OCaml's full `abst`, at every switch set. A "PNVI" name
    would read as a mode-specific path ([USER 2026-09-30], no magic modes).
  - The design gave the name as a working name ("S2 fixes them").
- **D2 [AGENT] — the taint type is `ProvTaint`.** `Taint` already names the allocation's
  exposure flag (OCaml uses "taint" for both).
- **D3 [AGENT] — abst's PNVI pointer arm is written in S2**, with its R-PNVI-05 refusal.
  - The switch binder and the closure exist only for that arm. Without it they would be dead
    parameters.
  - §E S3's list does not include the arm; §A.3 #20 lists it among the missing pieces of
    `abst`. It is unreachable at `⟨[]⟩` (kernel, §3).
  - load's `expose_allocations` (#24) stays S3.
- **D4 [AGENT] — failure leaves are `(.NoTaint, failwithI …)`, not a bare `failwithI` at pair
  type.**
  - Why: `failwithI` is opaque, so `(failwithI m : ProvTaint × MemValue).2 = failwithI m` is not
    provable. The kernel equality with the pre-S2 text forces the value-component placement.
  - The pointer arm's taint is outside its match, which is OCaml's own shape (`` `NoTaint (*
    PNVI-ae-udi *) `` before the match, :1034). So the unknown-function-pointer leaf is a bare
    leaf of the value.
  - Runtime: the strict pair evaluates the failing component and aborts as before.
  - Consequence: the six re-keyed register rows are reviewed `NON-TAIL/TUPLE-OR-LIST` (§2).
- **D5 [AGENT] — `splitBytesProv`'s second component now mirrors `:449-453`** (it ignored the
  `INVALID` case).
  - It had no consumer before S2. The PNVI pointer arm is its first.
  - `.1` and its text are unchanged (the consumer's `splitBytesProv_ptrImage` states `.1`).
- **D6 [AGENT] — `mkIval` is used in the reconstruction only.** `intfromptr`'s sites (`:2486/:2488/:2505`)
  get it in S3 together with their PNVI arm, which is still the loud kill.
- **D7 [AGENT] — `resolveIota` takes `[LemFuel]`** (the ND `nd_bind` is fuel'd in this port). Its
  precondition is a `memM IotaPrecond`: upstream's preconditions can themselves `fail` (e.g.
  `get_allocation`).
- **D8 [AGENT] — `lookupIota`'s refusal is a `failwithI` inside `ND fun st => …`.** This is shape (a) in a
  monadic context. Its register row comes with its first caller (S3).
- **D9 [AGENT] — evaluation order in the integer/byte arms.**
  - OCaml evaluates `pvi_split_bytes` (R-PNVI-01's crash) before `provs_of_bytes` (R-PNVI-01b).
  - The Lean compiler may evaluate the pair's components in either order.
  - Both are refusals of the same family on the same bytes, so only the message could differ.
    This is not reachable before S3.
- **D10 [AGENT] — the struct arm's fold reads its accumulator by projection** (`acc.1`, `acc.2.1`,
  `acc.2.2`) instead of destructuring. It is the same computation, chosen for the proofs.
- **D11 [AGENT] — `reconstructValue_stable_aux` is replaced by `reconstructValueAbst_stable_aux`.**
  - The old lemma's proof unfolded the old recursive worker.
  - Consumer uses: 0.
- **D12 [AGENT] — the C1 reference form is retired into the test module** (design recommendation).
  The axiom gate's mem-scale leg now imports `Unit.ReconstructLegacyTest`. The precedent is
  the FUEL leg's `Unit.FuelExemplar`; `test_unit.sh` builds the module before the gate.
- **D13 [AGENT] — `lean_frontend/CLAUDE.md` and `VALIDATION.md` were updated** for the new unit test, the
  W2 row, the fuel census (63/13/5) and the register tally.

## 8. Consumer-visible changes for S5 (cerberus-sl)

**Method.** The cerberus-sl tree was grepped read-only at `9dc2305` on 2026-10-07, with
`.lake/` excluded. No scratch build was done; that is S5's job (design §E S5).

**Signatures that change:**
- `CerbMem.MemState.iotaMap : Std.TreeMap Int IotaEntry := Std.TreeMap.empty`. It was
  `List (Int × Int) := []`. cerberus-sl mentions: 0.

**Same name and same type, but a different body or term:**
- `CerbMem.reconstructValue_lemFuel` is NO LONGER RECURSIVE. Its body is
  `(@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient
  noOverlapping unionmap funptrmap addr ty bytes).2`.
- Statements stay textually and type-identical: every `reconstructValue …` /
  `reconstructValue_lemFuel 1 …` statement, including `S2Closures.lean:85`.
- **The 11 proof lines that unfold the worker are affected.** Each is a
  `simp only [reconstructValue, CerbTagsWf.envBound, reconstructValue_lemFuel, …]`, MEASURED at:
  - `CerberusIris/CerberusIris/PtrRepr.lean:105, :183`;
  - `CerberusIris/CerberusIris/Repr.lean:251, :506, :529, :535, :588, :743, :887, :900`;
  - `CerberusIris/CerberusIris/HeapModel.lean:314`.
- What those lines now reach: the `.2` of the new worker. To reach the arms, the predicted edit
  [AGENT, to be MEASURED in S5] adds `reconstructValueAbst_lemFuel` to each simp set, plus the
  default-instance facts where an arm consults them:
  - `CerbMem.mkIval_defaultSwitches` for the integer and byte arms;
  - `CerbMem.is_PNVI_defaultSwitches` for the object-pointer arm, where `Repr.lean:887` also
    rewrites `splitBytesProv … = (p, x)`;
  - possibly `ite_false`/`Bool.false_eq_true`.
- `CerbMem.reconstructValue`: the text is unchanged, but its unfolding goes through the above.
- `CerbMem.reconstructValue_measure_sufficient`: the statement is unchanged; the proof is new.
- `CerbMem.splitBytesProv`: `.1` and its text are unchanged. `.2`'s text is now
  `bytes.all (fun b' => b'.prov == b.prov) && (bytes.zipIdx.all …)`.
  - `Repr.lean:836` `splitBytesProv_ptrImage` states `.1` only.
  - `Repr.lean:882` existentially quantifies `.2`.
  - Predicted impact: none, unless their proof reduces the whole pair [AGENT, S5 to measure].
- `CerbMem.loadM`: the signature is unchanged; its elaborated term now contains
  `reconstructValueAbst`, `findOverlapping st` and a `.2`. Frozen declarations whose
  fingerprints cover terms that unfold `loadM` may drift. This is S5's MEASURED drift set.
- `CerbMem.splitBytesProv`, `CerbMem.MemState`: their terms changed as above.

**Removed from `CerbMem`** (moved to the test exe or replaced; cerberus-sl mentions: 0):
- `reconstructValue_indexed_lemFuel`;
- `reconstructValue_lemFuel_eq_indexed`;
- `reconstructValue_eq_indexed`;
- `reconstructValue_stable_aux`.

**New, in `CerbMem`:**
- types `IotaEntry`, `ProvTaint`, `OverlapResult`, `IotaPrecond`;
- `pnviRefusal`, `provsOfBytes`, `mergeTaint`, `mkIval`, `findOverlapping`,
  `reconstructValueAbst_lemFuel`, `reconstructValueAbst`, `noOverlapping`;
- `exposeAllocation`, `exposeAllocations`, `addIota`, `lookupIota`, `resolveIota`;
- theorems `mkIval_default`, `mkIval_defaultSwitches`, `is_PNVI_defaultSwitches`,
  `allocations_foldl_ascending`, and (in `CerbMem_lemMeasureProofs`)
  `reconstructValueAbst_stable_aux`, `reconstructValueAbst_measure_sufficient`.

**Generated tree:** unchanged.

## 9. Not done (S2 scope)

- The S3 arms and the remaining refusals R-PNVI-01, -06…-10.
- Unit pins of each refusal, and the register row for R-PNVI-04.
- `mkIval` at `intfromptr`.
- The S4 lane, and the S5 scratch build of cerberus-sl.
- The orchestrator's reviews and the full ladder (Tier B) at the arc's end.

## 10. Review fixes (2026-10-07, after the orchestrator's S2 review; S3 worker)

The S2 review found nothing blocking. Its six items, with dispositions (all [AGENT] unless quoted):

- **F1 (consumer proofs equate the reconstruction to `reconstructValue`).** PRODUCTION lemmas in a
  new theorem-only seam `lean_frontend/CerbMemDefaultFacts.lean` (a Lake root and a hand-written-copy
  manifest entry; a consumer imports it beside `CerbMem`), kernel-checked when it builds (cones are the
  standard three in the scratch probe that preceded them). They are not in `CerbMem.lean` because their
  STATEMENTS name the default-pinned wrappers, which speedbump W2 keeps out of production text: the
  first row-1 run with the lemmas in `CerbMem.lean` went RED on W2 (`check_no_fuel_numerals: FAIL (W2):
  forbidden shape found:` — the theorem statements), so W2 now excludes this one file by name, as it
  excludes the `*_lemMeasureProofs` carriers [AGENT]. `findOverlapping_congr` names no wrapper and
  stays in `CerbMem.lean`.
  - `reconstructValue_lemFuel_unfold` (the wrapper equation design §B.7 promised; `rfl`);
  - `reconstructValueAbst_lemFuel_default_closure fo fo'` — at `⟨CerbGlobal.defaultSwitches⟩` the WHOLE
    result (taint and value) is the same for any two closures (the test module's induction template);
  - `reconstructValueAbst_lemFuel_default_snd fo`, `reconstructValueAbst_default_snd fo` — value
    component = `reconstructValue_lemFuel` / `reconstructValue`, for every closure;
  - `reconstructValueAbst_snd_of_default (h : inst.switches = CerbGlobal.defaultSwitches)` — the same at
    ANY instance whose list is the default (a consumer's own instance, `h := rfl`);
  - `loadM_reconstruct_eq_reconstructValue h st …` — the `loadM`-facing form: the exact subterm
    `doLoad` builds, `(reconstructValueAbst … (findOverlapping st) st.lastUsedUnionMembers
    st.funptrmap …).2`, rewritten to `reconstructValue …`;
  - `findOverlapping_congr` — `findOverlapping` reads only `allocations` and `deadAllocations`, so
    `findOverlapping_congr rfl rfl : findOverlapping { s with lastUsed := u } = findOverlapping s`.
  The test pin (`reconstructValueAbst_default_snd_eq_legacy`, `loadM_reconstruct_default`) stays in
  the test module.
  **Measurement for S5** (read-only at cerberus-sl `7a2f9a2`; their tree was not built). Their four
  `{σ with lastUsed := u}`-style proofs were COPIED into a scratch probe in this worktree's `.tmp/`
  (consumer-style local instance at `defaultSwitches`, their `ndRun` restated) and elaborated against
  this tree (S2 + these lemmas). The probe was deleted afterwards. Results (MEASURED):
  - `UnseqReads.lean:167` `loadM_result_lastUsed`: FAILS with unsolved goals, NOT a whnf timeout (the
    whole probe elaborated in about 11 s). Cause: the two sides now carry
    `findOverlapping { σ with lastUsed := u }` and `findOverlapping σ`, so `split` cases the two
    reconstructions separately. Adding `simp only [findOverlapping_congr (s := { σ with lastUsed := u })
    (t := σ) rfl rfl]` after their `simp only`, plus the S1 fact `CerbGlobal.has_switch .strict_reads =
    false := rfl` (their instance is a named constant that `simp_all` does not unfold — an S1 effect),
    makes the copied proof elaborate. With the switch fact alone it still fails — so the closure is the
    S2 cause.
  - `UnseqReads.lean:154` `loadM_lastUsed_only` and `MemLoc.lean:27` `loadM_loc_indep`: FAIL, but for
    a reason that predates S2 and is not PNVI: SC WP0's `recordAccess` (landed after their pin
    `2b51d2a57`) puts `loc` and the receipt buffer into the result state.
  - `ExecInv.lean:355` `loadM_fp_read`: elaborates unchanged.
  - Prediction for S5: the whnf blow-up that `load_erasure` hit does NOT reproduce in these shapes;
    the S2-specific edit is one `findOverlapping_congr` rewrite in `loadM_result_lastUsed`. S3 changes
    `loadM` again (exposure); the S3 record re-measures.
- **F2.** §3 and §6 item 3 now say that `loadM_reconstruct_default` is about the reconstruction
  subterm of `doLoad`, not about `loadM`. (F1's `loadM_reconstruct_eq_reconstructValue` is likewise a
  subterm statement, named for where the subterm occurs.)
- **F3.** Implemented by S3 (load's `expose_allocations`, `docs/2026-10-07_pnvi-s3-arms-record.md`).
- **F4.** `scripts/fuel_hypotheses.txt`: the header's invariant paragraph covers rows 1-7, and a
  header note records that rows 6 (proof restated by S2) and 7 (new in S2) await the auditor's
  signature at the arc-end pre-merge audit. The worker did not sign.
- **F5.** Cites: `resolveIota`'s `fail` is `impl_mem.ml:575` (doc comment and §1 table); VALIDATION.md's
  `check_failure_reach` row says 235 exec-closure sites (was 231); `loadM`'s reconstruction comment
  cites `:1600` only; the two re-keyed register rows no longer carry the stale `CerbMem.lean:2428-2434` /
  `CerbMem:1045:18` positions (they name the owner and the local `doLoad` instead). Only the `need`
  column changed, which the seal does not cover; `check_failure_reach.py --reseal` was run and moved
  no seal (diff: those two rows only).
- **F6.** D6–D13 are tagged [AGENT] (§7). `pnviRefusal`'s runtime text no longer puts a
  `[USER 2026-10-05]` tag on a paraphrase; it cites "design record … §G/§H".

**Gate for these fixes** (row 1, `scripts/test_unit.sh` via `scripts/ce`, on the working tree that
became the review-fix commit; Lean rebuilt capped first, `Build completed successfully (398 jobs).`).
Verbatim selected lines (the `rc=0` line is the wrapper's):

```
check_handwritten_sync: OK (50 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
ReconstructLegacyTest: 18/18 runtime positive controls passed
Total: 17 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (328 files scanned comment-stripped — generated 222, hand-written+test 71, LemLib 35; 0 sorry tokens)
check_no_fuel_numerals: SELFTEST OK (31 plants red with the declared label — F1-F6, A1-A3, W1 and W2; E5 indirection a recorded known gap; unplanted set green)
check_lakefile_roots: OK (221 roots = 221 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
check_failure_reach: OK (237 pure failure sites = the 237 register rows exactly (235 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=176 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
rc=0
```

The `check_no_fuel_numerals: OK (335 files …` line ends `W2 wrapper lines seen: 6 of 6`. These fixes
change no executable definition: `CerbMem.lean` gains one theorem (`findOverlapping_congr`), comments
and the `pnviRefusal` message text (reached only at a refusal); no lane can move, so Tier A was not run
for this commit [AGENT; two-tier gating — the S3 commit runs Tier A].
