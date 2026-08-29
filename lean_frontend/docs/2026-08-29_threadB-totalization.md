# Thread-B lem totalization — are_compatible + the V0 E-slice family, runEffectful census item 1

STATUS: worker record (thread-B lem worker, operator-approved parallel
lane; branch `lem-totalization`, worktree
`worktrees/cerberus-lean-lem-totalization`, base `arc/segment-ladder` @
`6aaed9152`). Provenance: [AGENT] build throughout; the totalization
ruling is [USER] (V2 close, 2026-08-28: "We'll need to make the model
total in the proper way", signed off as LEM-SIDE FUEL). Merges into the
arc branch later via the standard rebase+re-gate — NOT merged by this
worker.

## 1. What and why

`AilTypesAux.are_compatible` was a generated **`partial def`** —
kernel-opaque: no whnf, no rfl, no provable law (the V2/R6 root cause,
`docs/2026-08-27_arc18-r6-breadth-campaign.md` §4.2). Every internal
function call in Core crosses this check (`PEare_compatible`), so no
two-function program could be minted until it was totalized; it heads
the V0 exec-cone opaque census
(`docs/2026-08-27_v0-statements-and-ban.md` §5.1, "THE totalization
order", component E). This slice totalizes the census E-slice family
the PROPER way — in the .lem model, Lean-target-only, OCaml output
byte-identical — and lands the runEffectful census (§5.2) item-1 seed
threading as a GENERATED def.

## 2. The .lem diff (all Lean-target-only; OCaml generated tree verified byte-identical)

| File | Change | Mechanism |
|---|---|---|
| `frontend/model/ail/ailTypesAux.lem` | `are_compatible` + `are_compatible_params_aux` + `are_compatible_params` (the truly-mutual 3-cycle) | `declare {lean} fuel val` (all-or-none per mutual block, backend requirement). Sentinels `fuelExhausted false` / `fuelExhausted (fun _ => false)` — exhaustion is LOUD (fuelExhaustedWith panics; fail-closed, never a silent default). Bound: `lemDefaultFuel` = 10^6, consumed one unit per constructor descent / param-list element — dominates any real ctype depth by orders of magnitude. Fuel not `automatic` because the family recurses through ctype subterms carried in pairs and pair-lists (the arc-3 pair-list finding, see core_run_aux.lem's convert_pexpr note); precedent: `ctypeEqual` (ctype.lem:428), the family's closest cousin. |
| `frontend/model/state.lem` | `foldlM`, `foldrM` | `declare {lean} termination_argument … = automatic` (list-structural; Lean derives termination). |
| `frontend/model/state_exception.lem` | `stExcept_foldlM`, `foldrM` (generated `foldrM0`) | same |
| `frontend/model/translation_aux.lem` | `mk_stdcall_aux`, `fetch_stdlib_symbol_aux`, `combine_params_args` | same (combine_params_args decreases on its second list in every call) |
| `frontend/model/cerb_attributes.lem` | `get_with_address` | same. Declare placed INLINE after the def: the file's EOF is byte-unterminated and an EOF append changes the generated .ml by one trailing newline (caught by the baseline hash check, first regen; fixed by inline placement). |
| `frontend/model/core_run_aux.lem` | NEW `initial_core_run_state_seeded (seed : nat) xs` | `let ~{ocaml}` + no val spec ⇒ the OCaml backend emits NOTHING (verified byte-identical; a val or an ocaml-visible body would emit comment text). The ambient `initial_core_run_state` is UNTOUCHED (its body is emitted as an OCaml comment — any body edit would change bytes; and it remains the executable face's one ambient read). |

Scope note (census fidelity): the E-slice work order executed =
are_compatible family + monadic folds + call plumbing, exactly the V0
§5.1 recommendation, plus the same-class list-structural neighbors
(`foldrM`, `fetch_stdlib_symbol_aux`, `combine_params_args`) that free
their modules for the totality gate. The printf/parser family
(`printf_aux`, `store_chars_in_array` [Formatted]; `many`, `many1`,
`string0` [Monadic_parsing]) is PARKED per the census's own
disposition ("NO corpus row exercises printf — totalize
opportunistically or park behind a documented boundary"): most are
list-structural `automatic` candidates, `many`/`many1` need mutual
fuel with a parserM witness; priced S, one regen+battery cycle,
whenever a V-rung first crosses formatted IO.

## 3. Generated-tree diff review (per-file sha256 vs pre-slice baseline)

Round 1 (totality declares) — exactly 5 modules changed:

- `AilTypesAux.lean`: the mutual block becomes `mutual def
  are_compatible_lemFuel (lemFuel : Nat) … / are_compatible_params_aux_lemFuel
  / are_compatible_params_lemFuel end` (fuel-0 arm = loud sentinel;
  cross-member calls rewritten to `(worker lemFuel)`) + three plain-def
  wrappers `are_compatible := are_compatible_lemFuel lemDefaultFuel` etc.
- `State.lean`, `State_exception.lean`, `Cerb_attributes.lean`,
  `Translation_aux.lean`: `partial def` → `def`, bodies byte-unchanged
  (8 defs; Lean accepted structural termination first try).

Round 2 (runEffectful item 1) — exactly 1 module changed:

- `Core_run_aux.lean`: + `def initial_core_run_state_seeded (seed :
  Nat) (xs : Fmap sym (labeled_continuations core_run_annotation)) :
  core_run_state` — pure, total, no runEffectful, no effectful
  attribute; the ambient `initial_core_run_state` (line 395) is
  byte-unchanged.

OCaml generated tree: byte-identical to baseline after BOTH rounds
(sha256 over all 86 files; `.threadB-logs/baseline-ocaml-gen.sha256`).

## 4. The proof-layer smoke (`relsem/RelSem/TotalizationSmoke.lean`, new module, registered in relsem roots)

All by `rfl`; measured cones EXACTLY {propext, Classical.choice,
Quot.sound}:

- `are_compatible_eq_fuel` — the wrapper is kernel-transparent over
  the fuel worker (was: no equations at all).
- `are_compatible_pointer_peel` — the QUANTIFIED unfolding law (∀ fuel,
  qualifiers, annotations, referenced types): pointer compatibility
  peels to referenced-type compatibility at one fuel step. The
  previously-unprovable class; the equation shape V4's call rule
  consumes.
- `are_compatible_signed_int_ground`, `are_compatible_params_ground` —
  ground kernel-computation points (labeled machinery smoke, NOT
  verification results; catechism §III.1 compliance note in-file).
- `initial_core_run_state_threaded_eq_seeded` — the hand twin
  (relsemcore `RelSem/Threaded.lean`) equals the generated seeded def:
  the mirror-agreement is now a THEOREM (no-internal-trust-gaps).

V4 proper (call rules) is the main lane's; nothing more was built.

## 5. Totality gate extension + plant test

`scripts/check_exec_totality.sh` EXEC_MODULES extended over the four
modules this slice frees: `State`, `State_exception`,
`Translation_aux`, `Cerb_attributes` (16 + 4 = 20 generated modules +
CerbND; allowlist still empty). `AilTypesAux` is NOT gate-listed — it
retains 7 unrelated partials (make_composite family,
has_flexible_array_member, is_complete, has_pointer_at_leafs,
agnostic_alignment_requirement_ord; S-priced follow-on, same moves).
Plant test executed both directions:

```
  PARTIAL State.plant_probe_threadB  (line 122)
check_exec_totality: 1 non-allowlisted partial(s), 0 stale allowlist entr(ies)
check_exec_totality: FAIL (enforcing mode)
plant-exit=1
check_exec_totality: CLEAN (20 generated modules + hand-written CerbND, 0 allowlisted)
restore-exit=0
```

## 6. runEffectful census item 1 — outcome

Route: the effect-spike (branch `effect-spike` @ `7f4100a5c`) proved
the seeded-statement side with ZERO lem-backend changes; this slice
lands the seeded constructor as a GENERATED def
(`initial_core_run_state_seeded`, §2/§3) with the twin-agreement
theorem (§4). Zero lem-backend (lem-lean) changes were needed —
confirming the spike's record; the opam/Lake lem pin is untouched.
The ambient wrapper remains the executable/differential face's one
ambient read (OCaml-parity; census sites 2–9 are the elaboration
pipeline's, explicitly NOT this slice's). The runEffectful no-cone
gate stands at carrier set 0 throughout.

## 7. Gate outcomes (verbatim lines; full logs in container `.threadB-logs/`)

`./scripts/test_unit.sh` (test_unit-4.log, exit 0, zero FAIL lines):

```
test_unit: sync gate OK (21 hand-written files byte-identical to generated/)
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (195 files: 0 axioms, boundary opaques present, 0 unsafeCast)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 2 tree(s) + LemLibTest.lean)
check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)
check_exec_totality: CLEAN (20 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 9105135ef8a9f41cf7aafc398407a341194cc458f81b393407c4cb5ddd698cdc, gen 50b87c916a110d01d86b05580aafda8f78761a614ac4305d963541758bf31029)
check_fork_drift: OK — layer 1: 63 oracle-surface files = manifest; layer 2: 20 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_proof_size: Kit + ConstructLaws files fixture-free OK (8 files)
check_engine_size: OK (reporting instrument; enforcement lives in the R3 register row)
```

(check_engine_size WARN on SegmentFaces.lean 656→698 is the arc
branch's pre-existing watched metric, untouched by this slice.)

`./scripts/test_exec.sh --check-baseline` (test_exec-baseline.log,
exit 0):

```
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

`./scripts/test_core.sh` (test_core-1.log, exit 0):

```
Cerberus --pp:  106 ok, 0 failed
Lean parse:     106 ok, 0 failed
Success rate:   100% (of cerberus successes)

ALL PASSED
```

`./scripts/test_verify.sh` (test_verify-1.log, exit 0):

```
test_verify: 118 passed, 0 failed (23 fixtures, 22 harness points, 14 corpus fixtures, 21 corpus points)
```

Smoke-lemma cones (lean_probe, verbatim):

```
'RelSem.TotalizationSmoke.are_compatible_eq_fuel' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.TotalizationSmoke.are_compatible_pointer_peel' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.TotalizationSmoke.are_compatible_signed_int_ground' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.TotalizationSmoke.are_compatible_params_ground' depends on axioms: [propext, Classical.choice, Quot.sound]
```

(The bridge theorem `initial_core_run_state_threaded_eq_seeded` was
added after that probe; it closes by the same `rfl` and builds under
the relsem in-build audit.)

Semantics-invisibility claim: the totalization + seeded-def slice
moved NO differential outcome (mismatch=0, 0 regressions, 0
improvements, floor=0) — as required (any movement was the STOP
condition).

## 8. Walls / findings

1. **EOF-newline mirror hazard** (§2, cerb_attributes row): appending
   declares to a .lem file with unterminated EOF changes the generated
   OCaml by one byte. Caught by the baseline-hash discipline; worth
   knowing for any future declares sweep.
2. **`~{ocaml}` + no-val emits nothing** into the OCaml tree (measured
   here; the target_rep'd-def path emits comments instead) — the clean
   pattern for Lean-target-only model additions.
3. **Lean accepted structural termination first-try for all 8
   `automatic` defs** — including recursion under returned lambdas
   (`foldlM`-style) and the two-list `combine_params_args`. The fuel
   fallback was needed only for the genuinely nested/mutual
   are_compatible family, as predicted by the arc-3 pair-list finding.
4. **Mid-battery .lem edit trips lem-sync** (self-inflicted, first
   test_unit run): the gate fail-closed exactly as designed
   (`CERB_LEM_SYNC_STALE`); re-regenerated and re-ran clean. Lesson:
   freeze .lem edits while a battery is in flight.
5. **The purity gate greps generated COMMENTS too** (deliberately dumb,
   fail-closed): a .lem comment naming the effect wrapper tripped
   `check_exec_purity` on Core_run_aux.lean. Fixed by rewording the
   comment (never by allowlisting comment lines); the .lem comment now
   says why the name is absent.
6. **Fork-drift manifest ordering is locale-collated**: the gate's
   `sort` runs under the ambient locale, where `state_exception.lem`
   precedes `state.lem` (punctuation-weak collation). New [files]
   entries must match that order or `comm` fails the gate. (A
   hardening candidate for the gate: `LC_ALL=C` both sides — NOT done
   here, it would invalidate the existing committed order; registered
   as an observation only.)
