# Record — hotfix: the fuel-forms gate builds its carrier modules; the memory-model measure proofs after seam-hygiene H1 (2026-09-20)

**Status: DELIVERED — one commit on `fix/fuel-forms-carriers`** (worktree
`worktrees/cerberus-lean-fix/fuel-forms-carriers`, base mainline `e283bed77`, charter `faec26faf` =
`docs/2026-09-20_charter-fuel-forms-carriers-hotfix.md`). Worker [AGENT Claude Fable].

**How the slice went, in order.** H1 and H2 were done and the H3 probes run; H3 showed row 6
(`CerbMem.reconstructValue_measure_sufficient`, `scripts/fuel_hypotheses.txt:65`) is NOT provable under
`CerbTagsWf.Acyclic ambient` after seam-hygiene H1 (§3.1 — measured), so the worker STOPPED at rule S1
with nothing committed and reported the options priced (§3.5). **Ruling [AGENT orchestrator 2026-09-20,
under the operator's delegation, flagged to the operator]: option (d)** — restate the two arms of
`reconstructValue_lemFuel` so the recursion never enters a failure value's projections (the leaf is the
WHOLE result, at tail position: the seam-hygiene doctrine applied consistently, and the better mirror —
the OCaml RAISES at `Pmap.find`/`assert false`, impl_mem.ml:1067/1073 and :1090, so nothing downstream
is computed); row 6 stays MEASURED under its reviewed hypothesis, the register untouched. Fence
extended for this commit to `lean_frontend/CerbMem.lean` (the two arms only, in both twins),
`scripts/failure_reach_register.txt` (via the gate's recipe), `scripts/check_lakefile_roots.sh` (one
honest line) and the restored `Reconstruct` proof section. §3.6 has what landed under the ruling. `build_lean` is option (b) — (a) was taken and then
reverted when the discovery Tier A run showed the fork-drift manifest pins `common.sh`'s content (§1.3).

**Pre-merge audit and the fix commit (2026-09-20, later the same day).** The combined audit
`docs/2026-09-20_s15-and-fuel-forms-hotfix-audit-premerge.md` (commit `3d614bcda` on
`audit/fuel-forms-carriers`) read the hotfix range MERGE-WITH-FIXES: two MINOR (M2 — the option-(b)
residual is not empty: `CerbConcurrency` is a Lake root imported by nothing and built by no gate or
exe; M3 — §5 described `CLAUDE.md` rows the commit did not contain) + notes N1 (register cites in the
base frame), N2 (a type-punning witness would make the recorded-member row REACHABLE), N3 (the
DEFINITION of the arms changed — re-pin-visible), N6 (`test_unit.sh:224` "24 plants"). Rulings [AGENT
orchestrator]: REBASE onto `8c712657f` (S1.5 lands first); ONE fix commit — M2 → **option (a) after
all** with the `common.sh` manifest row re-pinned as a single-row edit + dated NOTE, M3, N1, N3, N6, N2
as a recorded follow-up; ONE full re-gate. §8 has the rebase evidence, the fix commit's contents and
the re-gate. Section text below that the fix commit superseded is marked "(superseded — §8)" rather
than rewritten, except §5, which the audit's M3 required to state what the docs actually say.

Every quoted block below is verbatim from a log under `.tmp/ffc/` (ephemeral; the lines are copied
here). Derived tallies are labelled DERIVED.

## 0. The finding (F-1)

**The orchestrator's reproduction** on the mainline checkout is quoted in the charter §0 (the two
`rewrite` failures at `generated/CerbMem_lemMeasureProofs.lean:921:8` and `:1016:18`).

**This worker's reproduction**, first action of the slice, from `lean_frontend/` of the worktree
(`scripts/ce ../scripts/capped lake build CerbMem_lemMeasureProofs`; `.tmp/ffc/repro-F1.log`,
wall 08:47:33 → 08:47:37 — the 80 dependencies replayed, only this module built):

    ✖ [81/81] Building CerbMem_lemMeasureProofs (2.9s)
    error: generated/CerbMem_lemMeasureProofs.lean:921:8: Tactic `rewrite` failed: Did not find an occurrence of the pattern
      panicWithPosWithDecl ?m ?d ?l ?c ?msg
    in the target expression
      x ∈ (failwithI "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)").fst

    error: generated/CerbMem_lemMeasureProofs.lean:1016:18: Tactic `rewrite` failed: Did not find an occurrence of the pattern
      panicWithPosWithDecl ?m ?d ?l ?c ?msg
    in the target expression
      MemValue.MVunion t
          (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").fst
          (reconstructValue_lemFuel f ambient unionmap funptrmap addr
            (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").snd

    error: Lean exited with code 1
    Some required targets logged failures:
    - CerbMem_lemMeasureProofs
    error: build failed
    EXIT=1

**The mechanism**, verified in this tree: `CerbMem_lemMeasureProofs.lean` is a root of the `CerberusLean`
library (`lakefile.toml:178`) imported by no module (`grep -rn "import CerbMem_lemMeasureProofs"
lean_frontend` → nothing); its last edit is `49e98d9cf` 2026-09-05; `scripts/common.sh build_lean`
built only the `cerberus-lean` exe (Main's closure); `scripts/check_lakefile_roots.sh` compares root
NAMES to generated file names and builds nothing (its OK line's words "auxiliary modules all built"
are unbacked — §6); `scripts/check_fuel_forms.sh` built only `fuel-forms-tool` and then
`importModules`'d the carriers (`test/Unit/FuelFormsTool.lean:376`) as found. Seam-hygiene H1
`fce1de9f8` (2026-09-19 01:34 UTC) replaced the two leaves these proofs rewrote with LemLib's opaque
`failwithI`; nothing rebuilt the module; the primary checkout's `.olean` dated 2026-09-15 18:25 stood in
for it. The primed worktree here had NO `CerbMem_lemMeasureProofs.olean` (the orchestrator's
reproduction had deleted the primary's), and its primed `.lake` was stale more widely: the first
`lake build Main Driver CerbCall CerbND` REBUILT `Driver`, `Translation`, `Mini_pipeline`,
`Cabs_to_ail`, `Main` (25 s), and the first all-roots build rebuilt three proof roots outside Main's
closure (`CerbMemAllocatorProofs`, `CerbFailProofs`, `CerbNDFuelProofs`) plus 55 stale `:c.o`
objects (§1.3); one orphan artifact, `Core_unstruct_auxiliary.olean`, has no source (the module left
the build at effect-retirement C1) and is never imported.

**The window and the vacuous runs.** From `fce1de9f8` (2026-09-19) to this slice, every Tier A row 1
that reported `check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …)` certified the six `CerbMem`
rows of `scripts/fuel_hypotheses.txt:60-65` and the three hand-written seam obligations
(`typeofMval`, `unqualifyAndUnatomic`, `memValueToBytes`) from a pre-H1 compiled artifact. Records in
this tree whose row-1 claims rest on it: `docs/2026-09-18_seam-hygiene-record.md` §2.6 (H1 head),
§4.4 (H2 head), §5.5/§5.6 (H3 head, the FULL battery), §10.3 (H4 head `cef347c6c`, `PASSED A1
(296.4s)`), §11 (landing); `docs/2026-09-19_seam-hygiene-audit-premerge.md` §"A1 (test_unit.sh) —
selected lines" (`Total: 12 passed, 0 failed`); `docs/2026-09-19_program-data-parameters-S0.5-record.md`
§7.4 (`check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED …)`, quoted at its line 340) and
`docs/2026-09-20_program-data-parameters-S0.5-audit-premerge.md` N5 (the orchestrator's Part B re-run
of row 1). The S1.5 Part B record is on its own branch, not in this tree (the charter names it). What
was NOT vacuous in those runs: the register's shape/argument-correspondence checks ran on the stale
constants (they exist in the stale `.olean`), so the F2-class failure is "certified from an artifact
that no longer corresponds to its source", the class the working practice names ("verified-vs-loaded
artifact gaps are findings").

## 1. H1 — the gate builds what it loads

### 1.1 The change (`scripts/check_fuel_forms.sh`, working tree)

- `ENTRY_MODULES="Driver CerbCall CerbND Main"` — the tool's exec entries, one definition used for
  both the build and the tool's argument list (bare `Main` resolves as a Lake module target; checked).
- `table_of_tree` now, BEFORE building/running the tool: `lake build $ENTRY_MODULES $aux` under
  `scripts/capped` into `${log}.build`; on failure the FAIL names the module(s) Lake lists under
  `Some required targets logged failures:` and prints the build log's tail; then every
  `FUELFORMS_EXTRA_MODULES` scratch decoy is compiled from source by `lake env lean --root=
  FUELFORMS_EXTRA_PATH -o …` — the same rule for the selftest's modules (they were compiled by the
  selftest before; the gate is now the single authority, so a decoy that does not compile fails the
  run that lists it, loudly); then the tool build and run as before. All three FAIL diagnostics go to
  stderr (the caller redirects the function's stdout into the table file — the pre-existing
  tool-build FAIL had the same latent shape; fixed alongside).
- `--selftest` gains **P24**: a scratch carrier `FuelFormsPlantStaleCarrier` is compiled from a
  correct source (a valid `.olean` results — its size and mtime are recorded), then its SOURCE is
  overwritten with one that does not compile (`theorem … : (1 : Nat) = 2 := rfl`), and the gate is
  run with it as an extra module. The plant passes only if the gate FAILS with the line naming the
  module AND the stale `.olean` is byte-for-byte untouched (same size and mtime) — the verdict came
  from the source, not the artifact. This is F-1's state (stale-valid `.olean`, uncompilable source)
  reproduced in-plant. The SELFTEST OK line now says 25 plants.
- Header paragraph "THE GATE BUILDS WHAT IT LOADS" added; the trap cleans `${LOG}.build`.

### 1.2 Evidence

**The hardened gate on the UNREPAIRED tree** (before H2; `.tmp/ffc/gate-unrepaired.log`,
09:04:45 → 09:04:48, exit 1) — the tree-path proof that a carrier which does not compile now fails
the gate by name:

    check_fuel_forms: FAIL — obligation carrier / entry module(s) did not compile from source: CerbMem_lemMeasureProofs (the gate imports nothing it has not just built — F-1, 2026-09-20; log tail follows)
    …
    Some required targets logged failures:
    - CerbMem_lemMeasureProofs
    check_fuel_forms: FAIL — the classifier tool failed (fail-closed); diagnostics tail:
    …
    EXIT=1

**The selftest on the interim tree** (§2; `.tmp/ffc/selftest.log`, 09:13:31 → 09:13:42): all 25
plants `PLANT OK` — P1–P5, P6, P7, P12 (×2), P13–P23, P11 (+premise), P10 (+premise), P8, P9, P9b —
and P24 verbatim as printed (the script's own `cut` truncated the quoted message at 200 columns in
this run; widened to 320 afterwards):

    PLANT OK   [P24 carrier with a stale-valid .olean and a source that no longer compiles (F-1 in-plant): the gate FAILS naming the module; the stale .olean untouched] -> check_fuel_forms: FAIL — extra module `FuelFormsPlantStaleCarrier` (FUELFORMS_EXTRA_PATH=/home/dev/projects/cerberus-lean-proj/.tmp/tmp.JclFyCTjM0) did not compile from source (the gate imports noth

The selftest's final UNPLANTED policy check is RED for the row-6 reason (§2, §3) — `SELFTEST FAILED
(1)`; the 25 plants are independent of it.

### 1.3 `build_lean`: the measurement and the choice — (a), taken on the audit's M2

`lake build CerberusLean cerberus-lean` (every Lake root + the exe) on the warm primed tree, after H2
(`.tmp/ffc/build-all-roots-{1,2}.log`):

    RUN 1  09:12:38 → 09:12:55   Build completed successfully (395 jobs).   [DERIVED: 17 s; 58 targets "Built" — 55 stale :c.o objects + the exe relink + CerbMemAllocatorProofs, CerbFailProofs, CerbNDFuelProofs]
    RUN 2  09:12:55 → 09:12:56   Build completed successfully (395 jobs).   [DERIVED: 1 s; 0 "Built", all replayed]

Seconds, not minutes. The history of the choice, honestly: (a) was taken first; the discovery Tier A
run (§4.2 run 1) then showed `scripts/fork_drift_manifest.txt` pins `scripts/common.sh`'s CONTENT
(`[source-content]` row `100755 77f5ab3a… scripts/common.sh`), so the fork-drift content layer read
the hunk as drift —

    check_fork_content: FAIL — source-content drift inside reviewed file(s):
    scripts/common.sh: expected ('100755', '77f5ab3a841446962926185d3db8c0e3853fada26ff7708fdd3b47dcab0c3413'), actual ('100755', 'dccc92117e296446995e1dcbceb9ce35e70f3344e910f95ea29e9014586dd2bb')

— and a manifest re-pin was outside the fence, so the first commit took (b) and recorded (a) as a
follow-up. The pre-merge audit's **M2** measured the residual (b) leaves and found it is NOT the
"`Cerb*Proofs` modules the unit exes build, and nothing else" the first record claimed: of the 123
comment-stripped `CerberusLean` roots, minus every module some `.lean` under `generated/`, `test/`,
`speclab/` imports, minus the gate's four entries and its 100 carriers, ONE root remains —
**`CerbConcurrency`** (the hand-written concurrency-stub seam; `.olean` dated 2026-08-22; up to date by
Lake's traces today, but nothing would notice if it were not) — and **`Cabs_to_ail_auxiliary`** is
unimported too (a carrier, so the hardened gate builds it; `build_lean`'s consumers did not). Exactly
the F-1 shape. Ruling [AGENT orchestrator, on M2]: **(a) after all**, with the manifest row re-pinned
as a deliberate single-row edit + dated NOTE (never `--refresh`). The fix commit (§8): `build_lean`
runs `lake build CerberusLean cerberus-lean`; `scripts/fork_drift_manifest.txt`'s `[source-content]`
row for `scripts/common.sh` → sha256 `008b5ade8b923f9d7ae0fe6fce837dee3e7a75ef2c414dde8791a78633545744`
with a NOTE naming the hunk and the three roots. Consequence: every lane that calls `build_lean`
refuses, by name, on ANY root that does not compile; the gate additionally builds its own imports
(H1), so the two protections are independent. Under (a) every root compiled on the rebased tree
(§8.3) — no new finding of the "a root fails under (a)" class.

## 2. H2 — the mechanical repairs (`lean_frontend/CerbMem_lemMeasureProofs.lean`, working tree)

What the charter's H2 asks: repairs WITHOUT a hypothesis change; the eight obligations
`alignofCtype`, `sizeofCtype`, `memberAlign`, `offsetsofMembers`, `offsetsof`, `memValueToBytes`,
`typeofMval`, `unqualifyAndUnatomic` must compile with their statements unchanged; delete
`panic_eq_default` if nothing needs it.

- The eight obligations were never broken: F-1's two errors are the only ones, both in the
  `Reconstruct` section (the five layout obligations close their unknown-tag arms by `rfl` — the
  leaf is fuel-independent — `layout_stable_aux`'s `offsetsof` part, unchanged). Their statements are
  untouched (the diff to the file is deletions in `section Reconstruct` plus one added doc block).
- `panic_eq_default` (`:883`) deleted: nothing else used it, and no kernel equation for the opaque
  `failwithI` can replace it.
- The `Reconstruct` section (`offsetsof_types`, `pot_default`, `reconstructValue_stable_aux`,
  `reconstructValue_measure_sufficient`) is REPLACED, in the working tree, by a doc block that states
  row 6 is pending the operator's ruling and points here — the module compiles with the eight:

      ✔ [81/81] Built CerbMem_lemMeasureProofs (2.0s)
      Build completed successfully (81 jobs).
      EXIT=0                                     (09:12:18 → 09:12:22; .tmp/ffc/build-h2.log)

  This interim shape is NOT the committed deliverable: it makes `CerbMem.reconstructValue_lemFuel`
  AMBIENT, and the gate says so (§4 — the honest RED). It exists so the plant and the population could
  be measured; the ruling decides what replaces it (§3.5).
- **The committed shape (after the ruling, §3.6):** the `Reconstruct` section is RESTORED as a real
  proof under `Acyclic ambient` ALONE — `foldl_offs_mem` and `offsetsofMembers_types` unchanged;
  `offsetsof_types` now takes `(v : Entry) (hl : lookup tagDefs t = some v)` and its unknown-tag arm
  is excluded by `simp [lookup, heq] at hl` (Probe B's `offsetsof_types'`); `pot_default` deleted (its
  only use was the deleted union-leaf reasoning); `reconstructValue_stable_aux`'s Struct arm `split`s
  on the new guard (`rfl` on the leaf; the `some` arm has `lookup ambient t = some v` in scope for
  `offsetsof_types` and `pot_member`), its union arm's recorded-member-not-found case is `rfl`; the
  OBLIGATION `reconstructValue_measure_sufficient` is textually the pre-hotfix statement. All nine
  statements unchanged; kernel-only tactics; no option bumps.
- **S1 as it was found, precisely:** `offsetsof_types`' unknown-tag arm and the union arm's recorded-member leaf are
  NOT excluded by `Acyclic`/`AcyclicPair` — `CerbTagsWf.Ranked` (`CerbTagsWf.lean:135-137`)
  constrains only references that RESOLVE (`(lookS t' = some v' ∨ lookU t' = some v') → R v' < R v`);
  an unknown tag is unconstrained, and the union leaf is a `unionmap` fact, not a tag fact. The
  charter's H2 "check: does `Ranked`/`lookup` give `lookup tagDefs t ≠ none` …?" answers NO, so its
  "if not, this is exactly the H3 question" applies to the whole row-6 cone (§3).

## 3. H3 — the row-6 probe (scratch `.tmp/ffc/probe/`, NOT committed; evidence for the operator)

Method: each probe is the module's compiling prefix (lines 1–879) plus a replaced `Reconstruct`
section, compiled with `scripts/ce ../scripts/capped lake env lean -DautoImplicit=false --root=… -o …`
from `lean_frontend/`. Leaves left OPEN on purpose make Lean print the residual goal verbatim.

### 3.1 Under `CerbTagsWf.Acyclic ambient` ALONE (Probe A, exit 1, exactly two errors)

Residual A1 — `offsetsof_types`, the unknown-tag arm:

    ProbeA.lean:922:2: error: unsolved goals
    case h_1
    n : Nat
    ambient tagDefs : CerbTags.TagDefsMap
    t : sym
    flag : Bool
    x : identifier × ctype × Nat
    x✝ : Option (sym × Entry)
    heq : lookupEntry tagDefs t = none
    hx : x ∈ (failwithI "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)").fst
    ⊢ ∃ v, lookup tagDefs t = some v ∧ x.snd.fst ∈ memberTypes v.snd

Residual A2 — `reconstructValue_stable_aux`, the union arm's recorded-member-not-in-UnionDef leaf
(context abridged to the operative hypotheses; the full state is in `.tmp/ffc/probe/ProbeA.log`):

    ProbeA.lean:1014:12: error: unsolved goals
    case h_2
    …
    hl : lookup ambient t = some (l, UnionDef ((firstIdent, at_, al, q, firstTy) :: rest))
    heq2 : List.find? (fun x => x.fst == addr) unionmap = some (a, membr)
    heq3 : List.find? (fun x => idEqual x.fst membr) ((firstIdent, at_, al, q, firstTy) :: rest) = none
    ⊢ MemValue.MVunion t
          (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").fst
          (reconstructValue_lemFuel f ambient unionmap funptrmap addr
            (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").snd
            (List.take
              (sizeofCtype ambient
                (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").snd)
              bytes)) =
        MemValue.MVunion t
          (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").fst
          (reconstructValue_lemFuel g ambient unionmap funptrmap addr
            (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").snd
            (List.take
              (sizeofCtype ambient
                (failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)").snd)
              bytes))

Both goals equate two computations that differ ONLY in the fuel they pass (`f` vs `g`) to a recursion
whose input is a component of an opaque value. Why no proof exists (argument, not a probe): a Lean
`opaque` constant is never unfolded by the kernel, so a proof term that type-checks with `failwithI`
type-checks with any other closed term of its type substituted — a provable statement holds in every
interpretation. Interpret `failwithI` at `List (identifier × ctype × Nat) × Nat` as a one-member list
whose type is an array nested deeper than `envBound ambient (Struct t) = 2 + defsWeight ambient + 1`
(`CerbTagsWf.lean:184`), and `fuelExhaustedWith` by its own body (`LemLib.lean:191`: `witness`):
`reconstructValue_lemFuel` at fuel `envBound - 1` on that member exhausts to `MVunspecified` while at
`lemFuel = envBound + depth` it returns an `MVarray` — different constructors, the equation is false,
hence unprovable. Probe A's side lemma `struct_unknown_enters_opaque` (compiled, no error) pins the
first half: at an unknown struct tag the recursion IS the fold over `(failwithI …).fst`. The union
leaf is the same shape on `(failwithI …).snd`. **Row 6 is not provable under `Acyclic ambient` after
H1** — the E-A worker's analysis is confirmed by measurement.

### 3.2 Under `Acyclic ambient ∧ Closed ambient ty` (Probe B, exit 1, exactly one error)

`Closed` as defined in the probe (least fixed point; `refsOf`/`memberTypes` are `CerbTagsWf.lean:93-125`):

    inductive Closed (m : CerbTags.TagDefsMap) : ctype → Prop
      | intro (ty : ctype)
          (hres : ∀ t ∈ refsOf ty, ∃ v : Entry, lookup m t = some v)
          (hsub : ∀ t ∈ refsOf ty, ∀ v : Entry, lookup m t = some v → ∀ y ∈ memberTypes v.2, Closed m y) :
          Closed m ty

With it: `offsetsof_types'` takes `hl : lookup tagDefs t = some v` and its unknown-tag arm is
excluded by `simp [lookup, heq] at hl` (no `panic_eq_default`); the Struct arm of
`reconstructValue_stable_aux'` closes (`hC.struct_lookup`, `hC.struct_member`), Array/Atomic descend
(`hC.array`, `hC.atomic`), the union arm's first-member and found-member cases close
(`hC.union_member`). The recorded-member-not-found leaf does NOT: Probe B's one error is the A2 goal
again, now with `hC : Closed ambient (Ctype an (Union0 t))` in context and nothing to use it on —
`Closed` speaks about tags, the leaf is about `unionmap`. **Row 6 does not prove under
`Acyclic ∧ Closed`.** Size of the change if it did: +5 small lemmas, one added binder threaded through
`key`, ~15 lines.

### 3.3 Under `Acyclic ∧ Closed ∧ UnionMapOk` (Probe C, exit 0)

    def UnionMapOk (m : CerbTags.TagDefsMap) (unionmap : List (Int × identifier)) : Prop :=
      ∀ (t : sym) (l : CerbLocation.Loc) (membrs : List Member), lookup m t = some (l, UnionDef membrs) →
        ∀ (a : Int) (i : identifier), (a, i) ∈ unionmap →
          ∃ (j : identifier) (e : attributes × Option alignment × qualifiers × ctype), (j, e) ∈ membrs ∧ idEqual j i = true

    theorem reconstructValue_measure_sufficient' … (lemHyp : CerbTagsWf.Acyclic ambient ∧ Closed ambient ty ∧ UnionMapOk ambient unionmap) (lemFuel : Nat)
        (lemMeasureLe : CerbTagsWf.envBound ambient ty ≤ lemFuel) :
        reconstructValue_lemFuel lemFuel ambient unionmap funptrmap addr ty bytes = reconstructValue ambient unionmap funptrmap addr ty bytes

    'CerbMem.reconstructValue_measure_sufficient'' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CerbMem.offsetsof_types'' depends on axioms: [propext, Classical.choice, Quot.sound]

Complete, kernel-only tactics, standard axioms. The register text the gate would require:
`CerbTagsWf.Acyclic ambient ∧ CerbMem.Closed ambient ty ∧ CerbMem.UnionMapOk ambient unionmap`
(with `Closed`/`UnionMapOk` moved to `CerbTagsWf.lean`).

### 3.4 What the load site can cite — the two hypotheses are not alike

**`Closed` HAS a frontend invariant.** The load is `loadM tagDefs loc ty pv` (`CerbMem.lean:2419` at the sealed head; `:2389` in the base tree — audit N1),
`ty` the Core `load` action's ctype; every rvalue use of an lvalue outside
`sizeof`/`&`/`++`/`--`/`.`/`=` performs the lvalue conversion at `genTyping.lem:1819-1826`, and an
INCOMPLETE non-array type there is `UB020_nonarray_incomplete_lvalue_conversion` (STD §6.3.2.1#2,
sentence 3) — the typing pass halts, no Core is produced. `is_complete` (`ailTypesAux.lem:222-262`)
makes a `Struct sym`/`Union sym` complete only when `List.lookup sym sigm.tag_definitions` is
`Just (_, _, StructDef _ _)` / `UnionDef`; members are completeness-checked at definition
(`cabs_to_ail.lem:1512 check_members` — the register's existing cite), so every tag reachable from a
defined tag is defined; the frontend's `tag_definitions` become the Core program's `core_tagDefs`
(`translation.lem:4245`) = the Lean `tagDefs`. So `Closed tagDefs ty` holds at every load of every
program the frontend accepts; the caveats are the register's existing ones (hand-authored Core; the
F-A2 `_Alignas` class is about acyclicity, not closure).

**`UnionMapOk` has NONE.** `unionmap` is `st.lastUsedUnionMembers` (`CerbMem.lean:2434` at the head), the
identifier recorded per ADDRESS by the last union-member store there (impl_mem.ml
`last_used_union_members`, :1080-1090); the strong form above demands that identifier be a member of
EVERY union in the table — false as soon as two unions with different member names have both been
stored. The honest form is address- and type-indexed ("the identifier recorded at `a` names a member
of the union stored at `a`"), which (i) is not a property of `(ambient, ty)` at all but of the memory
state, (ii) through the struct arm's mirrored `addr + pad` quirk (`CerbMem.lean:1111-1120`) is not
even cleanly address-indexed, and (iii) is FALSE under type punning (store a member of `union U1` at
`a`, load `union U2` at `a`): upstream's own reaction there is `assert false` (impl_mem.ml:1085-1090)
— an oracle-CRASH class, not an invariant. A register row for it could not carry a `.lem:<line>`
invariant cite; the hypothesis would be honest only in the weak sense the register already tolerates
for F-A2 ("the wrapper fails loudly outside it").

### 3.5 The options, priced (for the ruling — [AGENT] analysis, no recommendation is binding)

(a) **Strengthen to `Acyclic ∧ Closed ∧ UnionMapOk`** — proves today (Probe C); `Closed` is
    invariant-backed (§3.4), `UnionMapOk` is not; register row 6 changes; +~60 lines in
    `CerbTagsWf.lean`/the module; consumers keep the parametric equation but under a hypothesis they
    cannot discharge at a load without a state invariant they do not have.
(b) **Reclassify ABSORBING** — NOT available under the (B) form as it stands:
    `reconstructValue_lemFuel 0 … = fuelExhaustedWith "…" (.MVunspecified ty)` holds by `rfl`, but
    `FuelFormsTool.lean:308,436` REJECT any `_zero` RHS mentioning a value sentinel
    (`fuelExhaustedWith` is one) and require an absorbing head from `[nd_action.NDkilled,
    nd_status.Killed, t0.Error]` — a pure `MemValue`-valued worker has no monadic kill (P0
    2026-09-05's relabel is exactly that a value sentinel is not a kill). Making it fit = reversing
    that rule, and consumers lose the parametric fuel-independence of every load.
(c) **A reviewed `fuel_forms_pending.txt` row** (reachable-AMBIENT, the (C) form fits as is): register
    row 6 deleted, one pending row added; consumers lose the kernel equation `reconstructValue … =
    reconstructValue_lemFuel n …` for `n ≥ envBound`; the runtime exhaustion is the loud
    `fuelExhaustedWith` panic (`LEAN_ABORT_ON_PANIC`), which the gate's own wording calls "an opaque
    (fail-open) exhaustion" — the register for such rows was emptied 2026-09-15 and re-opening it is
    a step backwards on the fuel-parameter arc.
(d) **Restate the two arms in `CerbMem.lean` so the recursion never ENTERS a failure leaf**, row 6
    stays `Acyclic ambient`, the register is untouched: struct arm — `match CerbTagsWf.lookupEntry
    ambient tagSym with | none => failwithI "…unknown tag…" | some _ => <the fold over offsetsof as
    today>`; union arm — `match membrs.find? … with | some (i, (_, _, _, t)) => .MVunion tagSym i
    (reconstructValue_lemFuel … t …) | none => failwithI "…recorded union member not in UnionDef…"`
    (the whole `MVunion` is the leaf, no recursion on `(failwithI …).snd`). Then both arms are
    `rfl`/hypothesis-free like the five layout obligations' unknown-tag arms today, and the current
    proof shape closes under `Acyclic` alone (the struct arm's `lookup = some v` is in scope, so
    `offsetsof_types'` of §3.2 applies with no `Closed`). Runtime behaviour on the defined domain is
    identical; on the failing inputs the same `failwithI` panics, forced by the load one frame
    earlier (the struct-arm message may be kept as `offsetsof`'s text or given its own — "failure
    text" is an allowed discrepancy class). Costs: a `CerbMem.lean` edit (a seam file — FORBIDDEN in
    this slice's fence, so a fence extension or a follow-up slice), `scripts/failure_reach_register.txt`
    moves (one new/moved site, the union leaf's position class), the mirror-OCaml note cites
    impl_mem.ml:1061-1073/1085-1090 for the reshaped arms. No register move, no new hypothesis; the DEFINITION of the two arms changes (a
    re-pin-visible change for any consumer that unfolds them — audit N3, §7), behaviour on the defined domain does not. [AGENT] assessment: the least-cost route that keeps row 6 MEASURED under
    its reviewed hypothesis — not prototyped (it needs the forbidden file), the argument is the
    structural one above.
(e) **Make the two leaves transparent again** — reverses seam-hygiene H1 for two of its 98 sites;
    `panic_eq_default` returns; the kernel again sees a default value where the OCaml raises. The
    charter lists it; nothing here recommends it.

### 3.6 What landed under the ruling — option (d)

`lean_frontend/CerbMem.lean`, both twins (`reconstructValue_lemFuel` and the pre-C1 reference form
`reconstructValue_indexed_lemFuel`, restated IDENTICALLY so `reconstructValue_lemFuel_eq_indexed` still
closes by `rfl` on these arms):

- **Struct arm** — `match CerbTagsWf.lookupEntry ambient tagSym with | none => failwithI
  "CerbMem.reconstructValue: unknown struct tag (OCaml: Pmap.find Not_found in sizeof/offsetsof,
  impl_mem.ml:1067/1073)" | some _ => <the fold over offsetsof, as before>`. Mirror: the OCaml's
  `sizeof cty` (:1067) and `offsetsof … tag_sym` (:1073) both raise `Not_found` at an unknown tag —
  the exception escapes, nothing of the struct is computed; the Lean leaf is now likewise the whole
  result. `offsetsof`'s own leaf (`CerbMem.lean:430`) is untouched. Runtime on the defined domain:
  identical (the guard re-reads a lookup `offsetsof` performs anyway). On the failing input: the same
  kill one frame earlier; the failure TEXT differs from the oracle's exception text (an allowed
  discrepancy class) — and at the load site it is shadowed: `doLoad` computes `sizeofCtype tagDefs ty`
  BEFORE `reconstructValue` (`CerbMem.lean:2428-2434` at the head — `size` :2429, the call :2434; audit N1), whose `offsetsof` leaf fires first on the same
  unknown tag.
- **Union arm** — the `membrs.find?` match moved OUTWARD: the `.MVunion tagSym <ident>
  (reconstructValue_lemFuel … <ty> (bytes.take (sizeofCtype ambient <ty>)))` result is built in the two
  `some`-shaped cases (no recorded member → the first declared member, impl_mem.ml:1084-1086; recorded
  member found → that member, :1088) and the `none` arm IS the leaf `failwithI
  "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)"` (:1090) —
  no recursion on `(failwithI …).snd`. Message unchanged; the empty-UnionDef and not-a-UnionDef leaves
  unchanged. The arm's pre-existing impl_mem.ml cites (1074-1095 / 1085-1090) were re-pinned to THIS
  tree's lines (1076-1096 / 1088-1090; the struct arm's 1061-1073 → 1065-1075).
- The twin's header sentence notes the restatement (it is no longer "the pre-C1 text verbatim" in
  these two arms).

**Rebase note for the E-A arc's uncommitted `enumDefs` threading through `CerbMem.lean`** (asked for by
the orchestrator): at the base `faec26faf` the two hunks are `def reconstructValue_lemFuel` clauses
`| Ctype _ (.Struct tagSym) =>` lines **1104–1121** and `| Ctype _ (.Union0 tagSym) =>` lines
**1122–1143**, and `def reconstructValue_indexed_lemFuel` clauses **1222–1233** (Struct) and
**1234–1250** (Union0); nothing else in the file moves except the twin's header comment (1180-1182 at
base). At this head they are `reconstructValue_lemFuel` Struct **1104–1135**, Union0 **1136–1166**;
`reconstructValue_indexed_lemFuel` Struct **1247–1261**, Union0 **1262–1280**. The recursive call
sites keep their argument lists (`lemFuel ambient unionmap funptrmap addr …`); an `enumDefs` parameter
threaded through them rebases by re-applying the same insertion in the three recursive calls per twin
(struct fold: 1, union: 2).

`scripts/failure_reach_register.txt` (the gate's recipe: RED → `--emit --seed <register>` → review →
`--reseal` → OK; §4): one NEW row (the struct-arm leaf, `TAIL`, `UNREACHABLE-BY-INVARIANT` with the
`offsetsof: unknown tag` row's typing justification — `genTyping.lem:1819-1826` UB020 on an incomplete
lvalue conversion + `ailTypesAux.lem:222-262` `is_complete` — plus the load-site shadowing), two MOVED
rows (the recorded-member leaf: live class `LET-BOUND → STMT-NEWLINE`, reviewed `NON-TAIL/LET-BOUND →
TAIL`, reach `UNKNOWN` UNCHANGED with its justification — the site fires iff the recorded identifier
names no member, exactly as before; the not-a-UnionDef leaf: live class `LET-BOUND → STMT-NEWLINE`
only, reviewed `TAIL`/`UNREACHABLE-BY-INVARIANT` unchanged, its "classifier picked the inner match"
note retired). Tally `sites=233 → 234`, `reviewed-TAIL 179 → 181`, `reviewed-NON-TAIL 54 → 53`,
`UNREACHABLE-BY-INVARIANT 166 → 167`, `discardable=0`.

`scripts/check_lakefile_roots.sh`: the OK line's "`N auxiliary modules all built`" (an unbacked claim —
the gate compares names and builds nothing) is now "`N auxiliary modules listed as roots — names only;
every carrier is built by check_fuel_forms.sh`", with the comment saying why.

## 4. Gates (verbatim tails)

### 4.0 The stop-point runs (H1/H2 before the ruling; the interim tree with the row-6 cone removed)

- F-1 reproduction: §0 (exit 1, 08:47:33 → 08:47:37).
- Hardened gate on the unrepaired tree: §1.2 (exit 1, 09:04:45 → 09:04:48).
- `CerbMem_lemMeasureProofs` after H2: §2 (exit 0, 09:12:18 → 09:12:22).
- `lake build CerberusLean cerberus-lean` ×2: §1.3.
- `scripts/ce ./scripts/check_fuel_forms.sh --selftest` (09:13:31 → 09:13:42): 25 × `PLANT OK` (§1.2),
  then

      UNPLANTED:
        check_fuel_forms: FAIL — hypothesis register row(s) whose worker is not MEASURED under that exact hypothesis (stale register row; edit the register):
          CerbMem.reconstructValue_lemFuel	CerbTagsWf.Acyclic ambient
        check_fuel_forms: forms partition OK (61 MEASURED + 13 ABSORBING + 1 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
        check_fuel_forms: FAIL — fuel'd worker(s) REACHABLE from drive with an opaque (fail-open) exhaustion, not in /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/fuel-forms-carriers/scripts/fuel_forms_pending.txt:
          CerbMem.reconstructValue_lemFuel
    check_fuel_forms: SELFTEST FAILED (1)

- `scripts/ce ./scripts/check_fuel_forms.sh` (09:14:19 → 09:14:21, exit 1): the same two FAIL lines
  and the same partition line — the population is the honest change from the reviewed 81/62/13/0/6 to
  **81/61/13/1/6**: the one MEASURED row lost is row 6, the one reachable-AMBIENT worker is
  `CerbMem.reconstructValue_lemFuel`. Nothing else moved.
- Tier A row 1 (`scripts/ce ./scripts/test_unit.sh`): §4.1 below.
- Tier A rows 2–12: NOT RUN. No commit is proposed, so no tier claim is made; no semantics or seam
  file changed (the three touched files are two scripts and a proof module), so rows 2–12 have no
  mechanism to move — that is a statement about the diff, not a measurement.

### 4.0.1 Row 1 on the interim tree (pre-ruling)

`scripts/ce ./scripts/test_unit.sh` (`.tmp/ffc/test_unit-interim.log`, 09:14:36 → 09:18:00, exit 1):

    check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    …
    Total: 12 passed, 0 failed
    check_exec_purity: CLEAN (11 modules)
    check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (398 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
    check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 49 hand-written seam files + LemLibTest.lean)
    check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])
    check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
    check_sorry_token: OK (318 files scanned comment-stripped — generated 219, hand-written+test 64, LemLib 35; 0 sorry tokens)
    test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: same-value/different-stdout and different-stderr yield distinct whole-line tokens, escaped payload byte-exact, multi-outcome order kept, embedded text is payload, Undefined unchanged, truncated line is no token)
    check_no_fuel_numerals: SELFTEST OK (26 plants red with the declared label — F1-F6 and A1-A3; E5 indirection a recorded known gap; unplanted set green)
    check_no_fuel_numerals: OK (325 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
    check_lakefile_roots: SELFTEST OK (3 plants red, baseline green)
    check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules all built)
    check_fuel_forms: SELFTEST — plants on a scratch copy of the classification table (loud plant banner; nothing in the tree is touched)
    …  [DERIVED: 28 lines `PLANT OK` = the 25 plants P1–P24 (P12 prints a row line and a policy line) + the P10/P11 premise lines — every plant of the hardened selftest]
      UNPLANTED:
        check_fuel_forms: FAIL — hypothesis register row(s) whose worker is not MEASURED under that exact hypothesis (stale register row; edit the register):
          CerbMem.reconstructValue_lemFuel	CerbTagsWf.Acyclic ambient
        check_fuel_forms: forms partition OK (61 MEASURED + 13 ABSORBING + 1 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
        check_fuel_forms: FAIL — fuel'd worker(s) REACHABLE from drive with an opaque (fail-open) exhaustion, not in /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/fuel-forms-carriers/scripts/fuel_forms_pending.txt:
          CerbMem.reconstructValue_lemFuel
    check_fuel_forms: SELFTEST FAILED (1)
    test_unit: fuel-forms gate SELFTEST FAILED
    EXIT=1

`test_unit.sh` exits at the first red gate, so the gates after the fuel-forms gate (failure-reach,
fork-drift, fixture-freeze, lem-sync) did not run in this invocation; they are untouched by the diff.
The one red line is the row-6 pair of §4 — the honest state of the interim tree, which is why nothing
is committed.

### 4.1 The option-(d) tree — builds and gates

`lake build CerberusLean cerberus-lean` after the arms + proof (`.tmp/ffc/build-d.log`; the sync gate
OK first — `check_handwritten_sync.sh --quiet` rc 0):

    09:28:35
    ⚠ [253/395] Built CerbMem (1.7s)
    ✔ [336/395] Built CerbMem_lemMeasureProofs (3.0s)
    Build completed successfully (395 jobs).
    EXIT=0
    09:29:09

[DERIVED: 100 targets Built, the rest replayed; the two `CerbMem.lean` warnings in the log are at
`:1308` (the `simp only [hp]` argument of `reconstructValue_lemFuel_eq_indexed`, unused since H1) and
`:1738` (`onConcurRead`), both outside the restated arms — pre-existing.]

`scripts/ce ./scripts/check_failure_reach.sh` BEFORE the register review (`.tmp/ffc/failure-reach-1.log`,
09:29:29 → 09:29:36):

    check_failure_reach: instrument built + census taken in 6 s (FAILURE_REACH rows 21249, FAILURE_RANGE rows 11307; counts: {"generated:monadic_ascribed":263,"generated:pure_or_unresolved":1253,"handwritten:pure_or_unresolved":123})
    check_failure_reach: FAIL —
      NEW pure exec-closure site (no register row — review it): lean_frontend/CerbMem.lean:1123 CerbMem.reconstructValue_lemFuel failwithI «"CerbMem.reconstructValue: unknown struct tag (OCaml: Pmap.f» position=STMT-NEWLINE scope=EXEC
      POSITION CLASS CHANGED: lean_frontend/CerbMem.lean:1165 CerbMem.reconstructValue_lemFuel «"CerbMem.reconstructValue: recorded union member not in Unio» live=STMT-NEWLINE register=LET-BOUND
      POSITION CLASS CHANGED: lean_frontend/CerbMem.lean:1166 CerbMem.reconstructValue_lemFuel «"CerbMem.reconstructValue: Union tag not a UnionDef (OCaml: » live=STMT-NEWLINE register=LET-BOUND
    EXIT=1

`--emit scripts/failure_reach_register.txt` → 3 rows differ (the diff is exactly the three sites above;
the NEW row arrived `UNREVIEWED UNREVIEWED NEW SITE (line 1123): needs review`); reviewed as §3.6 says;
`check_failure_reach.py --reseal` → `resealed 234 rows`; the gate AFTER (`.tmp/ffc/failure-reach-2.log`,
09:30:59 → 09:31:05):

    check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=167 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
    EXIT=0

`scripts/ce ./scripts/check_fuel_forms.sh` (`.tmp/ffc/gate-d.log`, 09:31:53 → 09:31:55) — the reviewed
population **81/62/13/0/6** restored:

    check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
    check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
    EXIT=0

### 4.2 Tier A rows 1–12 incl. 4b/4c/6b (`release.py --mode fast`)

**Run 1 — DISCOVERY (with option (a) in `common.sh`; docs were edited during the run, so the runner's
own identity check reads `Source unchanged: False`; evidence `.tmp/ffc/release-fast/`):**

    09:32:12
    FAILED A1 (220.7s)
    PASSED A2 (35.1s)
    PASSED A3 (51.2s)
    PASSED A4 (22.6s)
    PASSED A4b (24.0s)
    PASSED A4c (3.1s)
    PASSED A5 (22.3s)
    PASSED A6 (2.2s)
    PASSED A6b (3.6s)
    PASSED A7 (10.3s)
    PASSED A8 (8.8s)
    PASSED A9 (16.7s)
    PASSED A10 (16.6s)
    PASSED A11 (57.7s)
    PASSED A12.1 (4.9s)
    PASSED A12.2 (4.4s)
    fast: failed; 15/16 selected commands completed successfully.
    Source unchanged: False. Complete tier selection: True.
    09:40:38

A1's stdout: every gate up to the fork-drift gate green — `Total: 12 passed, 0 failed`; the axiom
censuses; `check_fuel_forms: SELFTEST OK (25 plants …)` and the OK line of §4.1; `check_failure_reach:
SELFTEST OK (5 plants …)` + `check_failure_reach: OK (234 …)`; `check_exec_totality: CLEAN (22
generated modules + hand-written CerbND, 0 allowlisted)`; `check_lem_sync: OK` / `lean OK` — then

    check_fork_drift: SELFTEST FAILED (6)
    test_unit: fork-drift gate SELFTEST FAILED

for TWO reasons: the `common.sh` content pin (§1.3 — mine, removed by taking (b)) and

    check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=4307dc5, 'lem -v' says 38f87d5 — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately

which is the ENVIRONMENT: the shared switch's lem is S1.5's `38f87d5` (the brief: "not yet on the
mainline … do NOT run `make rebuild-lem` or touch `deps/lem-pinned`"), the mainline manifest records
`4307dc5`. Not this diff's (it touches no OCaml, no generated tree, no manifest) and not this slice's
to fix; it clears when S1.5 lands its manifest refresh. The two row-1 gates AFTER fork-drift, run
directly on the final tree (`test_unit.sh` exits at the first red gate):

    check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
    test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)

and the fork-drift gate alone on the final tree (`common.sh` reverted): ONLY the lem-pin line above,
`EXIT=1` — the content layer is clean again.

**Run 2 — FINAL (option (b), content frozen during the run; evidence `.tmp/ffc/release-fast-final/`):**

    09:43:48
    FAILED A1 (213.8s)
    PASSED A2 (27.7s)
    PASSED A3 (50.9s)
    PASSED A4 (22.4s)
    PASSED A4b (24.0s)
    PASSED A4c (3.1s)
    PASSED A5 (21.6s)
    PASSED A6 (2.1s)
    PASSED A6b (3.5s)
    PASSED A7 (10.3s)
    PASSED A8 (8.8s)
    PASSED A9 (16.6s)
    PASSED A10 (16.4s)
    PASSED A11 (57.5s)
    PASSED A12.1 (4.7s)
    PASSED A12.2 (4.4s)
    fast: failed; 15/16 selected commands completed successfully.
    Source unchanged: True. Complete tier selection: True.

**Row 1** (`A1/stdout`) — every gate green up to the fork-drift gate, which is red on the ENVIRONMENT's
lem pin alone (its five content plants that run 1 failed on `common.sh` are `PLANT OK` now):

    check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    Total: 12 passed, 0 failed
    check_exec_purity: CLEAN (11 modules)
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (398 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
    check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
    check_sorry_token: OK (318 files scanned comment-stripped — generated 219, hand-written+test 64, LemLib 35; 0 sorry tokens)
    test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: …)
    check_no_fuel_numerals: OK (325 files scanned comment-stripped; …; allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
    check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
    check_fuel_forms: SELFTEST OK (25 plants with the declared label — …)
    check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (…; 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (…), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
    check_failure_reach: SELFTEST OK (5 plants with the declared message — …)
    check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=167 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
    check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
    check_lem_sync: OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
    check_lem_sync: lean OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
    check_fork_drift: SELFTEST — plants on scratch copies of the manifest and fake prerequisites (loud plant banner; nothing in the tree is touched)
      PLANT OK   [S1 en_US-ordered [files] under LC_ALL=C (the pre-repair failing configuration)] rc=0 -> check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest
      …
      PLANT OK   [S11 unmodified copied source contents] rc=0 -> check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest
      PLANT FAIL [unplanted gate is not green]:
          check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=4307dc5, 'lem -v' says 38f87d5 — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately
    check_fork_drift: SELFTEST FAILED (1)
    test_unit: fork-drift gate SELFTEST FAILED

(the ellipses above shorten lines quoted in full in §4.1 or in `A1/stdout`; nothing is paraphrased.)
The two gates after it, run directly on this exact tree: `check_fixture_freeze: OK (16 fixture files
match the pinned manifest; name set exact)`, `test_renumber_plants: OK (12 plants: refusals refuse,
admits admit with declared class)`. So row 1 is green on every gate this slice can affect and red on
one environment condition outside its fence (the lem pin, §4.2 run 1) — **not** "fully green" as the
charter's gate list asks; the orchestrator's brief foresaw the pin state and the record says so
plainly rather than claiming otherwise.

**Rows 2–12, every tail verbatim** (each lane's `stdout` under `.tmp/ffc/release-fast-final/<lane>/`):

    A2   SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A3   SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A4   SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A4b  SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A4c  SUMMARY: exec_match=9 neg_pinned=5 fail=0
         ALL AT COMMITTED EXPECTEDS
    A5   SUMMARY: match=12 diff=0
         ALL MATCH RECORDED BASELINE
    A6   SUMMARY: total=2 match=2 fail=0
         ALL PASSED
    A6b  SUMMARY: total=7 match=7 fail=0
         ALL PASSED
    A7   batch diagnostic producers: 8/8 passed
         cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
         ALL PASSED
    A8   Success rate:   100% (of cerberus successes)
         ALL PASSED
    A9   LEAN_FAIL:  0
         SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
    A10  GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
    A11  Checking against baseline (exact match, fail-closed both directions): …/tests/cn_coverage/baseline.txt
         BASELINE OK (213 entries, exact match)
    A12.1  EXPECT OK    18 pinned rows = 18 observed cases, every token identical
           test_address_space: SELFTEST OK (14 plants — …)
    A12.2  EXPECT OK    18 pinned rows = 18 observed cases, every token identical
           test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)

Zero lane movement (the SUMMARY lines equal the seam-hygiene record's §2.6/§10.3 quotes and A9's
recorded `same=108 diff=5`) — stop rule S2 not triggered; nothing re-baselined.

## 5. Errata and doc rows — as COMMITTED (rewritten on the audit's M3 to the committed text)

**`docs/2026-09-18_seam-hygiene-record.md`** — a dated `## 12. Erratum [AGENT 2026-09-20]` appended after
§11 (18 lines; nothing above it changed): the row-1 verdicts of §2.6/§4.4/§5.5/§5.6/§10.3 were vacuous
on nine obligations; the mechanism; "Every other line of those verdicts stands"; the repair (the gate
builds every module it imports — P24, `build_lean` builds every root, option (d)).

**`VALIDATION.md`, the `check_fuel_forms.sh` row** — two insertions, verbatim:

> ; **the gate BUILDS every module it imports before importing it** (hotfix `fix/fuel-forms-carriers` 2026-09-20, finding F-1 — `docs/2026-09-20_fuel-forms-carriers-hotfix-record.md`: `lake build` of the exec entries and every `*_auxiliary`/`*_lemMeasureProofs` carrier, and the selftest's scratch decoys compiled from source — fail-closed, the FAIL naming the module; until then a carrier's `.olean` was imported AS FOUND, and `CerbMem_lemMeasureProofs`' pre-seam-hygiene artifact certified nine obligations vacuously from 2026-09-19 to 2026-09-20).

> `--selftest` plants six doctored tables, three doctored registers, the F-1 stale-carrier plant P24 (a stale-valid `.olean` over a source that no longer compiles: the gate must FAIL naming the module with the `.olean` untouched) and 15 COMPILED decoys (

**`lean_frontend/CLAUDE.md`** — four rows, verbatim as committed:

> - `fuel-forms-tool` (not a pass/fail exe: the INSTRUMENT of `scripts/check_fuel_forms.sh`) — `test/Unit/FuelFormsTool.lean` imports the compiled environment at runtime and classifies every fuel'd worker MEASURED/ABSORBING/AMBIENT with its drive-cone reachability (C2; P0 2026-09-05: MEASURED checks the argument correspondence against the wrapper's own body in MetaM, ABSORBING = "kill at zero" checks the `_zero` lemma's left-hand side and cone); the gate `lake build`s the exec entries and every carrier module and compiles its scratch decoys from source BEFORE the tool imports anything (hotfix `fix/fuel-forms-carriers` 2026-09-20, F-1: a carrier's stale `.olean` had been imported as found), and its `--selftest` P24 plants a stale-valid `.olean` over an uncompilable source

> literal 0 on its own binders; 25 plants incl. 15 compiled decoys and the F-1 stale-carrier plant P24 (2026-09-20) — the

> | `CerbMem_lemMeasureProofs.lean` | The hand-written MEASURED seams' sufficiency theorems: `CerbMem.typeofMval/unqualifyAndUnatomic/memValueToBytes_measure_sufficient` and the six layout/reconstruct obligations under `CerbTagsWf.Acyclic`/`AcyclicPair` (rows 1–6 of `scripts/fuel_hypotheses.txt`), same shape and namespace rule as the generated ones — the fuel-forms gate classifies them by the same rule. A Lake root NOTHING imports: built by `build_lean` (every root, 2026-09-20) and by the fuel-forms gate itself (H1, every carrier it imports) — it did not compile from seam-hygiene H1 to 2026-09-20 while its stale `.olean` was imported (hotfix `fix/fuel-forms-carriers`, `docs/2026-09-20_fuel-forms-carriers-hotfix-record.md`). The reconstruct proof needs no equation about the opaque failure leaves: `reconstructValue_lemFuel`'s struct/union arms guard the tag lookup / select the union member BEFORE recursing (option (d)), so every leaf is a whole, fuel-independent result |

> | `scripts/common.sh` | Shared helpers (build, run, paths). `build_lean` builds EVERY Lake root + the exe (`lake build CerberusLean cerberus-lean`, hotfix 2026-09-20 on the audit's M2: a root nothing imports — `CerbMem_lemMeasureProofs`, `CerbConcurrency`, `Cabs_to_ail_auxiliary` — can no longer go stale unnoticed; measured 17 s first pass / 1 s steady on a warm tree; its content is pinned in `scripts/fork_drift_manifest.txt`, re-pinned with a dated NOTE) |

## 6. Observations outside the fence (for the orchestrator; follow-ups, not changed here)

- (DONE in the fix commit, §8 — was a follow-up) `build_lean` builds every root, option (a).
- FOLLOW-UP (audit N2): a type-punning witness under `tests/failure-probes/reach/` — store a member of
  `union U1` at `a`, load `union U2` at `a` — would move the recorded-member row from `UNKNOWN` to
  `REACHABLE` (both crash: the oracle's `assert false`, Lean's `failwithI`), the more informative
  class; §3.4 (iii) states the route. Outside every fence here.
- (DONE in the fix commit, §8 — was left for fence reasons) `scripts/test_unit.sh:224` "24 plants" → 25.
- (FIXED under the extended fence, §3.6) `scripts/check_lakefile_roots.sh`'s "all built" wording.
- `scripts/test_unit.sh` builds each unit exe with `lake build "$test"` and never the carriers; with
  H1 the fuel-forms gate builds them, and with (a) `build_lean` does too — but `test_unit.sh` itself
  does not call `build_lean`, so the gate's own build is the load-bearing one there.
- FOLLOW-UP for `scripts/new-worktree.sh` (container): the primed `.lake` copied from the parking
  checkout was stale for Main's closure (§0) — priming from a checkout that is not built at its own HEAD
  carries the F-1 hazard into every worktree; a `lake build CerberusLean cerberus-lean` on the primary
  after each merge, or a first-thing build in `new-worktree.sh`, removes it.
- `Core_unstruct_auxiliary.olean` is an orphan artifact in `.lake` (no source since effect-retirement
  C1); never imported; harmless; `lake clean` territory.

## 7. Consumer note (cerberus-sl) — audit N3

The DEFINITION of `CerbMem.reconstructValue_lemFuel` changed shape in its `Struct`/`Union0` arms (the
tag-lookup guard; the member selection moved outside the recursion — §3.6); behaviour on the defined
domain is identical, but any proof that UNFOLDS those arms sees the new term. cerberus-sl unfolds
`reconstructValue_lemFuel` in six proofs (`Repr.lean:246,383,406,412,464,574`, per the audit's
read-only grep), all on the Integer/pointer arms, which a `match` on a concrete ctype constructor
reduces past the struct/union arms — nothing breaks at their pin; it is a re-pin-visible change and is
named here for their re-pin notes. The twin `reconstructValue_indexed_lemFuel` moved identically.

## 8. Rebase, the fix commit and the re-gate (2026-09-20, after the pre-merge audit)

### 8.1 The rebase onto `8c712657f`

`git rebase 8c712657f` on `fix/fuel-forms-carriers` (working tree clean): `Successfully rebased and
updated refs/heads/fix/fuel-forms-carriers`. The two commits re-applied without conflict (the S1.5
range `e283bed77..8c712657f` touches `lakefile.toml`/three `lake-manifest.json`/`fork_drift_manifest.txt`
/ three docs — disjoint from the hotfix's nine files). Evidence that the diff is unchanged:

    $ git range-diff e283bed77..5a5579209 8c712657f..HEAD
    1:  faec26faf = 1:  b89a010ab docs(charter): hotfix — the fuel-forms gate builds its carrier modules; CerbMem_lemMeasureProofs repaired after seam-hygiene H1 …
    2:  5a5579209 = 2:  5d462da86 hotfix fix/fuel-forms-carriers: the fuel-forms gate builds every module it imports (F-1 plant P24); reconstructValue's struct/union arms …
    $ git diff --stat 5a5579209 HEAD -- <the hotfix commit's nine files>
    (empty)

(`=` in `range-diff` = identical patch text.) Rebased heads: charter `b89a010ab`, hotfix `5d462da86`.
After the rebase the fork-drift manifest's `lem-pin=38f87d5` equals the switch's `lem -v`, so row 1's
fork-drift gate can pass (§8.4).

### 8.2 The fix commit (the audit's rulings, one commit)

- **M2 → option (a):** `scripts/common.sh` `build_lean` runs `lake build CerberusLean cerberus-lean`
  (the measured hunk, §1.3; comment names F-1, `CerbConcurrency`, `Cabs_to_ail_auxiliary`);
  `scripts/fork_drift_manifest.txt` `[source-content]` row for `scripts/common.sh` re-pinned
  `77f5ab3a… → 008b5ade8b923f9d7ae0fe6fce837dee3e7a75ef2c414dde8791a78633545744` as a single-row edit
  + one dated NOTE (no `--refresh`; the oracle surface untouched). Standalone check before the tier
  run: `check_fork_content: OK — 76 source files content/mode-pinned` / `check_fork_drift: OK — layer
  1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing
  generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin
  38f87d5 = lem -v)`.
- **M3:** §5 rewritten to quote the committed `VALIDATION.md`/`CLAUDE.md` rows verbatim; the
  `CLAUDE.md` `CerbMem_lemMeasureProofs.lean` and `common.sh` rows now carry the option-(a) wording
  (true again); the seam-hygiene §12 sentence says "`build_lean` builds every root" again.
- **N1:** the register's new row cites the load site at head numbers (`CerbMem.lean:2428-2434`: `size`
  :2429, the call :2434; `def loadM` :2419); §3.4 likewise. The `need` field is outside the seal, so
  no reseal was needed; the gate re-ran green (§8.4).
- **N3:** §7 (the consumer note) + §3.5 (d) reworded ("the DEFINITION of the two arms changes").
- **N6:** `scripts/test_unit.sh:224` "24 plants" → "25 plants … and the F-1 stale-carrier plant P24".
- **N2:** recorded as a follow-up in §6 (a type-punning witness; outside every fence here).
- Nothing else moved; `scripts/fuel_hypotheses.txt` untouched.

### 8.3 The whole-tree build on the rebased tree (option (a)'s own command)

`lake build CerberusLean cerberus-lean` from `lean_frontend/` (`.tmp/ffc/build-rebased.log`):

    19:24:46
    info: LemLib: URL has changed; deleting '…/lean_frontend/.lake/packages/LemLib' and cloning again
    info: LemLib: checking out revision '38f87d5fa6b29ec90edfa457faba8a309e32c118'
    Build completed successfully (395 jobs).
    EXIT=0
    19:27:10

[DERIVED: 2 min 24 s wall, 277 targets Built, 0 Replayed — the LemLib pin move rebuilt everything;
every Lake root compiled, `CerbConcurrency` and `Cabs_to_ail_auxiliary` included — no new finding of
the "a root fails under (a)" class.]

### 8.4 The re-gate — Tier A rows 1–12 incl. 4b/4c/6b on this content

`release.py --mode fast` twice on the fix content, BEFORE the commit (the run certifies this tree; the
commit adds only this section): a first run (`.tmp/ffc/release-fast-rebased/`, 19:29 →) passed all 16
lanes but read `Source unchanged: False` because §8.1–8.3 of this record were written while it ran —
so it was re-run with nothing touched in the worktree. The FINAL run (`.tmp/ffc/release-fast-rebased-final/`):

    19:38:33
    PASSED A1 (219.1s)
    PASSED A2 (27.9s)
    PASSED A3 (51.4s)
    PASSED A4 (22.5s)
    PASSED A4b (24.0s)
    PASSED A4c (3.1s)
    PASSED A5 (22.0s)
    PASSED A6 (2.2s)
    PASSED A6b (3.6s)
    PASSED A7 (10.7s)
    PASSED A8 (9.0s)
    PASSED A9 (17.0s)
    PASSED A10 (17.9s)
    PASSED A11 (59.4s)
    PASSED A12.1 (5.1s)
    PASSED A12.2 (4.6s)
    fast: passed; 16/16 selected commands completed successfully.
    Source unchanged: True. Complete tier selection: True.

**Row 1 FULLY GREEN** (`A1/stdout`; every gate, in order; long lines quoted in full in §4.1 are shortened
with `…` here, nothing paraphrased):

    check_handwritten_sync: OK (49 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    Total: 12 passed, 0 failed
    check_exec_purity: CLEAN (11 modules)
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (398 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
    check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
    check_sorry_token: OK (318 files scanned comment-stripped — generated 219, hand-written+test 64, LemLib 35; 0 sorry tokens)
    test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: …)
    check_no_fuel_numerals: OK (325 files scanned comment-stripped; …; allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
    check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
    check_fuel_forms: SELFTEST OK (25 plants with the declared label — …)
    check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (…; 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (…), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
    check_failure_reach: SELFTEST OK (5 plants with the declared message — …)
    check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=167 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)
    check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
    check_lem_sync: OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen 08b84774381fd86eeb1a658efa47a9b372ebb438085530b5ab6ba045da3eec8d)
    check_lem_sync: lean OK (src 037dee26c6472b1bf7f8d628bec1b7e64d2f9d12d67c81bd37b55e634fd34b2d, gen cd499eab48146463197f60b35a9fb26c31337bab7d06b2f1d9af43047c2619b5)
    check_fork_drift: SELFTEST OK (14 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; unplanted gate green)
    check_fork_content: OK — 76 source files content/mode-pinned
    check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)
    check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
    test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)

**Rows 2–12, every tail verbatim:**

    A2   SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A3   SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A4   SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A4b  SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
         Baseline check: 0 regression(s), 0 improvement(s)
    A4c  SUMMARY: exec_match=9 neg_pinned=5 fail=0
         ALL AT COMMITTED EXPECTEDS
    A5   SUMMARY: match=12 diff=0
         ALL MATCH RECORDED BASELINE
    A6   SUMMARY: total=2 match=2 fail=0
         ALL PASSED
    A6b  SUMMARY: total=7 match=7 fail=0
         ALL PASSED
    A7   cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
         ALL PASSED
    A8   ALL PASSED
    A9   SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
    A10  GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
    A11  BASELINE OK (213 entries, exact match)
    A12.1  EXPECT OK    18 pinned rows = 18 observed cases, every token identical
           test_address_space: SELFTEST OK (14 plants — …)
    A12.2  EXPECT OK    18 pinned rows = 18 observed cases, every token identical
           test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)

Zero lane movement against §4.2 run 2 and the seam-hygiene record's quotes — stop rule S2 not
triggered; nothing re-baselined. Every lane that calls `build_lean` ran the option-(a) command.
