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

### 1.3 `build_lean`: the measurement and the choice — (b), for a fence reason

`lake build CerberusLean cerberus-lean` (every Lake root + the exe) on the warm primed tree, after H2
(`.tmp/ffc/build-all-roots-{1,2}.log`):

    RUN 1  09:12:38 → 09:12:55   Build completed successfully (395 jobs).   [DERIVED: 17 s; 58 targets "Built" — 55 stale :c.o objects + the exe relink + CerbMemAllocatorProofs, CerbFailProofs, CerbNDFuelProofs]
    RUN 2  09:12:55 → 09:12:56   Build completed successfully (395 jobs).   [DERIVED: 1 s; 0 "Built", all replayed]

Seconds, not minutes — so (a) was taken first and `scripts/common.sh build_lean` ran `lake build
CerberusLean cerberus-lean` through the discovery Tier A run (§4.2 run 1). That run's A1 showed the
COST the charter did not price: `scripts/fork_drift_manifest.txt:423` pins `scripts/common.sh`'s
CONTENT (`[source-content]` row `100755 77f5ab3a… scripts/common.sh`), so the fork-drift gate's
content layer reads any `common.sh` edit as drift —

    check_fork_content: FAIL — source-content drift inside reviewed file(s):
    scripts/common.sh: expected ('100755', '77f5ab3a841446962926185d3db8c0e3853fada26ff7708fdd3b47dcab0c3413'), actual ('100755', 'dccc92117e296446995e1dcbceb9ce35e70f3344e910f95ea29e9014586dd2bb')

— and re-pinning that row is a manifest edit outside both the charter's fence and the ruling's
extension (the charter's forbidden list names "the pin files"). Rule conflict → fail-closed with the
minimum change: **(b) taken** — `common.sh` reverted to base (`git checkout -- scripts/common.sh`;
the file is untouched in this commit), the gate's own carrier build (H1) is the protection for the
class F-1 belongs to (every module the gate certifies is built from source by the gate). What (b)
leaves open: a Lake root that NO gate imports (today the `Cerb*Proofs` modules the unit exes import —
they are built by `test_unit.sh`'s `lake build <exe>` — and nothing else; DERIVED from the roots
list) could still go stale unnoticed by `build_lean`'s consumers. The (a) follow-up is two hunks and
is recorded in §6 for the orchestrator.

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

**`Closed` HAS a frontend invariant.** The load is `loadM tagDefs loc ty pv` (`CerbMem.lean:2389`),
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

**`UnionMapOk` has NONE.** `unionmap` is `st.lastUsedUnionMembers` (`CerbMem.lean:2404`), the
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
    impl_mem.ml:1061-1073/1085-1090 for the reshaped arms. No register move, no new hypothesis, no
    consumer-visible change. [AGENT] assessment: the least-cost route that keeps row 6 MEASURED under
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
  BEFORE `reconstructValue` (`CerbMem.lean:2398-2404`), whose `offsetsof` leaf fires first on the same
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

## 5. Errata and doc rows — APPLIED in this commit

**`docs/2026-09-18_seam-hygiene-record.md`** — a dated §12 erratum appended after §11 (history not
rewritten; the paragraph as committed says the same as this draft, plus the option-(d) repair):

> **Erratum [AGENT 2026-09-20]** (`docs/2026-09-20_fuel-forms-carriers-hotfix-record.md` §0): the
> `test_unit.sh` verdicts quoted in §2.6, §4.4, §5.5, §5.6 (A1) and §10.3 (A1) were VACUOUS on nine
> obligations. H1 (`fce1de9f8`) made two failure leaves opaque that
> `lean_frontend/CerbMem_lemMeasureProofs.lean` rewrote with `panic_eq_default`; the module has not
> compiled since, but no build in row 1 rebuilt it (it is a Lake root nothing imports) and
> `check_fuel_forms.sh` imported its pre-H1 `.olean` as found — so `check_fuel_forms: OK (81 fuel'd
> workers: 62 MEASURED …)` certified the six `CerbMem` rows of `scripts/fuel_hypotheses.txt` and the
> three seam obligations from an artifact that no longer corresponded to its source. Every other line
> of those verdicts stands. The gate now builds every module it imports (hotfix
> `fix/fuel-forms-carriers`); row 6's hypothesis is under the operator's ruling.

**`VALIDATION.md:729`, the `check_fuel_forms.sh` row** — inserted after "the classifier is
`lean_frontend/test/Unit/FuelFormsTool.lean` (runtime `importModules`, no source regex; …)":

> ; **the gate BUILDS every module it imports before importing it** (hotfix 2026-09-20, F-1: the exec
> entries and every carrier by `lake build`, the selftest's scratch decoys from source — fail-closed,
> the FAIL naming the module; until then a carrier's stale `.olean` was imported as found and
> `CerbMem_lemMeasureProofs`' pre-seam-hygiene artifact certified nine obligations vacuously for a
> day), and `--selftest` P24 plants that state (a stale-valid `.olean` over a source that no longer
> compiles) and asserts the FAIL names the module with the `.olean` untouched

and "15 COMPILED decoys" → "15 COMPILED decoys + the F-1 stale-carrier plant (P24)".

**`lean_frontend/CLAUDE.md`** — applied: the `fuel-forms-tool` bullet gains: "the gate `lake build`s the exec
entries and every carrier module and compiles its scratch decoys from source before the tool imports
anything (hotfix 2026-09-20, F-1); P24 plants a stale-valid `.olean` over an uncompilable source";
the `CerbMem_lemMeasureProofs.lean` row becomes: "The hand-written MEASURED seams' sufficiency
theorems (`typeofMval`/`unqualifyAndUnatomic`/`memValueToBytes` and the five layout obligations under
`CerbTagsWf.Acyclic`/`AcyclicPair`, same shape and namespace rule as the generated ones — the
fuel-forms gate classifies them by the same rule). A Lake root nothing imports: built by `build_lean`
(every root, 2026-09-20) and by the fuel-forms gate itself. `reconstructValue`'s obligation (register
row 6): needs no equation about the opaque leaves — the arms guard/select before recursing (option (d))".
The `common.sh` row: "`build_lean` builds EVERY Lake root + the exe"; the testing section's plant count
"24 plants" → "25 plants … and the F-1 stale-carrier plant P24".

## 6. Observations outside the fence (for the orchestrator; follow-ups, not changed here)

- FOLLOW-UP (a) for the orchestrator — `build_lean` builds every root: two hunks, both outside this
  commit's fence once the manifest is involved. (1) `scripts/common.sh` `build_lean`: `lake build
  cerberus-lean` → `lake build CerberusLean cerberus-lean` (the hunk as it ran in the discovery Tier A
  run is in `.tmp/ffc/working-tree.patch`; comment text: "EVERY Lake root, not just the exe's closure
  … measured 17 s first pass / 1 s steady"). (2) `scripts/fork_drift_manifest.txt:423`: re-pin the
  `[source-content]` row for `scripts/common.sh` to the new sha256 — a deliberate manifest refresh,
  reviewed. Cost when done: every lane refuses on any stale root; ~1 s steady-state.
- (FIXED under the extended fence, §3.6) `scripts/check_lakefile_roots.sh`'s "all built" wording.
- `scripts/test_unit.sh:224`, a COMMENT: "`--selftest (24 plants incl. …)`" is now 25 — the file is in
  the fence only if the invocation changes (it did not), so the one-token comment is left for the next
  slice that touches it.
- `scripts/test_unit.sh` builds each unit exe with `lake build "$test"` and never the carriers; with
  H1 the fuel-forms gate builds them, and with (a) `build_lean` does too — but `test_unit.sh` itself
  does not call `build_lean`, so the gate's own build is the load-bearing one there.
- FOLLOW-UP for `scripts/new-worktree.sh` (container): the primed `.lake` copied from the parking
  checkout was stale for Main's closure (§0) — priming from a checkout that is not built at its own HEAD
  carries the F-1 hazard into every worktree; a `lake build CerberusLean cerberus-lean` on the primary
  after each merge, or a first-thing build in `new-worktree.sh`, removes it.
- `Core_unstruct_auxiliary.olean` is an orphan artifact in `.lake` (no source since effect-retirement
  C1); never imported; harmless; `lake clean` territory.
