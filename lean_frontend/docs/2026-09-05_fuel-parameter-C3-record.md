# Fuel-parameter arc, cerberus half — slice C3 record (2026-09-05)

Branch `arc/fuel-parameter-C3` (worktree `worktrees/cerberus-lean-arc/zero-discrepancy`),
from mainline `mdd/cerberus-lean` @ `a910f097c` (the merged C2). Charter (the
orchestrator's brief): the Lake pin bump to lem-lean `d4ba548` (the
tails-and-pmap-laws slice, lem-lean `doc/lean-backend/2026-09-05_tails-and-pmap-laws-record.md`)
and the six point-free-tail `fuel_measure` rows it enables. Worker [AGENT];
rulings quoted with [USER] provenance; every quoted output is verbatim from
this worktree (`.tmp/c3/` logs, ephemeral, deleted at slice end); tallies
marked "derived" are derived. Nothing merged, nothing pushed; lem-lean,
`deps/`, the primary checkout and the other worktrees untouched.

## 0. Summary — READ THIS FIRST

- **Pin bump** (commit 1/n, alone): LemLib `ecf75b4` → `d4ba548` in
  `lakefile.toml` + the three `lake-manifest.json`. Regenerated from
  re-derived trees: the OCaml generated tree BYTE-IDENTICAL (86/86, `diff -rq`
  0 lines, lem-sync `gen 295e4f82…` unchanged), sibylfs identical, and the
  LEAN tree BYTE-IDENTICAL too (204/204, 0 lines, `gen 76d138a3…` unchanged):
  the hoist rule fires only on `fuel_measure`d/`structural` definitions with
  a trailing lambda, of which the C2 tree has none. The driver binary from
  `build_lean` is C2's byte-for-byte (`bin 797d1383ba69…`). Tier A green (§6.1).
- **Six measures** (commit 2/n): the six point-free `function` tails are
  MEASURED — declares in `core_reduction.lem` / `ail/ailTypesAux.lem`
  (Lean-only; OCaml tree still byte-identical), proofs in
  `Core_reduction_lemMeasureProofs.lean` (extended) and the new
  `AilTypesAux_lemMeasureProofs.lean`; every obligation's cone
  `[propext, Classical.choice, Quot.sound]`, no option bump, no `sorry`
  (§3). For the two shared-counter mutual blocks the lem dry run's
  measures were NOT taken as given: the aux members' measures are the
  derived size of the WHOLE walked structure (`generic_expr_.lemSize_aux2
  lemTail + 1`, `ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1
  lemTail.2 + 1`), and `are_compatible_params` is `+ 2` (it calls the aux at
  fuel − 1 on the same lists) — each derived from the code and PROVED
  sufficient (§3.2). `List.length` alone is insufficient for both aux rows
  (the lem record's own caveat, confirmed).
- **Register** `scripts/fuel_forms_pending.txt`: 21 → 15 (the point-free
  block deleted); the gate: `check_fuel_forms: OK (81 fuel'd workers: 47
  MEASURED …, 13 ABSORBING, 15 reachable-AMBIENT = the 15 rows …, 6 ambient
  unreachable …)` (§5). `[LemFuel]` binders in the generated model
  (derived, comment-stripped `grep`, seam copies excluded): 298 → 251;
  ambient generated wrappers 29 → 23 (parametricity pins regenerated with
  the committed generator; 23 = 23).
- **Battery** at the default fuel on fresh stamped binaries: §6 — ZERO
  movement.
- **Decisions for the operator**: §8. **Commits**: §9.

## 1. Rulings in force

[USER 2026-09-04] (lem fuel-measure record §1): "sticking to our principle
that we don't change the lem structure for ocaml is a very good design
rule" — the tails are NOT eta-expanded in the `.lem`; the Lean EMISSION is
(lem `d4ba548`). [USER 2026-09-03] no magic values: every measure here is an
expression over the parameters. Zero Lean-vs-OCaml discrepancies: the OCaml
generated tree is byte-identical at every step (§2.2, §4).

## 2. Pin bump (commit `d0b5319fc`)

### 2.1 Pin evidence

- opam (done by the orchestrator before the slice): `opam exec --switch=.
  -- lem -v` → `Lem d4ba548`; `opam show --switch=. lem -f source-hash` →
  `d4ba548d084ff393126f04d90f18a72c3000aa88`; `deps/lem-pinned` HEAD the same.
- Lake: `lean_frontend/lakefile.toml` `rev` → `d4ba548d084ff393126f04d90f18a72c3000aa88`
  (comment records the bump); `lake update LemLib` (capped, `CERB_MEM_MAX=32G`)
  in `lean_frontend`, verbatim: `info: LemLib: URL has changed; deleting
  '…/lean_frontend/.lake/packages/LemLib' and cloning again` / `info: LemLib:
  cloning https://github.com/OathTech/lem-lean` / `info: LemLib: checking out
  revision 'd4ba548d084ff393126f04d90f18a72c3000aa88'`; then `speclab` and
  `tests/mem-scale-probes/micro` (`rc=0`, `info: toolchain not updated;
  already up-to-date`). All three manifests: `"rev": "d4ba548d084ff393126f04d90f18a72c3000aa88"` /
  `"inputRev": …` the same.

### 2.2 The two trees at the bump — both byte-identical

Snapshots of the C2 head's `lean_frontend/generated/` (204 files),
`ocaml_frontend/generated/` (86) and `sibylfs/generated/` taken to
`.tmp/c3/pre/` BEFORE regenerating. Then `rm -rf lean_frontend/generated &&
make clean-prelude-src prelude-src && make lean-prelude-src && make
lean-native-obj` (`rc=0` each), verbatim stamps:

```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 928a08cd72f10e899385191821266f915008a499c4033de8b44893b9fcac2e8a, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_handwritten_sync: OK (34 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 928a08cd72f10e899385191821266f915008a499c4033de8b44893b9fcac2e8a, gen 76d138a3a8e6f5866edaebfc9725d265812de4fdaab908a650fbdb567f279f35)
```

— both `gen` hashes are the C2 head's. The diffs, verbatim (my runner's
lines around `diff -rq`):

```
OCAML diff -rq rc=0 lines=0 files=86
SIBYLFS diff -rq rc=0 lines=0
LEAN diff -rq rc=0 lines=0 files=204
```

**The Lean tree at the pin bump is EMPTY-diff**: no hoisted heads yet,
because the general rule applies only to `fuel_measure`d/`structural`
definitions and none of C2's 41 measured rows has a trailing lambda (the
lem record's §2.7 prediction, "byte-identical without the new declares",
holds on the real tree). No other difference — nothing to report.

Oracle rebuilt `DUNE_CACHE=disabled build_cerberus` → `check_driver_fresh:
recorded oracle stamp (bin 4925895b56515c881d1894756e85f80ce0a0e8e411ecc4a7898db4d0c5b643c1,
src 754ef1e991debf6bffb4d03bdc38928f686295441ce149d0cddfe2f06f11e768)`
(the `src` is C2's exactly — no `.lem` changed; the `bin` moves on every
cache-disabled relink, C1 record §2.5). `build_lean` → `Build completed
successfully (271 jobs).` / `check_driver_fresh: recorded lean stamp (bin
797d1383ba69f288f1b936c31060667e56f27c7347136e2c3ea5127b13e66993, src
f5dbd36dccad86b9a25c6ed7a47d2f9e5dffa4e20c74dd4f8bc392d800c7b9bb)` — the
BINARY is C2's byte-for-byte (C2 record §6: `bin 797d1383ba69…`); the `src`
stamp moved with the manifests.

## 3. The six measures (commit 2/n)

### 3.1 Declares (Lean-only, each block after its sentinel declares)

`frontend/model/core_reduction.lem` (after line 1516, the `get_ctx_unseq_aux`
sentinel; comment swallowed by the following `{lean}` declare on OCaml):

```
declare {lean} fuel_measure val one_step_unseq_aux = `List.length lemTail + 1`
declare {lean} fuel_measure val get_ctx = `lemSize g + 1`
declare {lean} fuel_measure val get_ctx_unseq_aux = `generic_expr_.lemSize_aux2 lemTail + 1`
```

`frontend/model/ail/ailTypesAux.lem` (after line 1338, the
`are_compatible_params` sentinel):

```
declare {lean} fuel_measure val are_compatible = `ctype.lemSize p.2 + ctype.lemSize p0.2 + 1`
declare {lean} fuel_measure val are_compatible_params_aux = `ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1 lemTail.2 + 1`
declare {lean} fuel_measure val are_compatible_params = `ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2`
```

(`lemSize p.2` is refused by the renderer — `lemSize x` takes a bare
parameter — so the qualified global `ctype.lemSize p.2` is written, as in
the lem dry run. `generic_expr_.lemSize_aux2` / `ctype_.lemSize_aux1` are the
backend-derived list helpers, named as qualified globals per the lem record
§7 decision 3.)

### 3.2 Why these measures (derived from the code; the lem dry run's rows corrected)

The generated block shares ONE `lemFuel`, decremented at every hop
(`(get_ctx_unseq_aux_lemFuel lemFuel) annot1 [] [] es` inside
`get_ctx_lemFuel (Nat.succ lemFuel)`, and back). A member's measure must
therefore bound the depth of the WHOLE block's recursion from that entry;
the proof obligation for the stability lemma is exactly: every cross-call's
callee measure is `<` the caller's (so it fits in `fuel − 1`). Sizes:
`generic_expr.lemSize (Expr _ e_) = 1 + generic_expr_.lemSize e_`,
`generic_expr_.lemSize_aux2 (e :: es) = 1 + lemSize e + lemSize_aux2 es`;
`ctype.lemSize (Ctype _ t) = 1 + ctype_.lemSize t`, `ctype_.lemSize (Function
(_, r) ps _) = 1 + lemSize r + lemSize_aux1 ps`, `ctype_.lemSize_aux1 ((_, t,
_) :: ps) = 1 + lemSize t + lemSize_aux1 ps`, `[] ↦ 0` (generated
`Core.lean:1792`, `Ctype.lean:294-311`).

| Row | Function | Measure μ | Cross-calls (all at fuel − 1) and why each callee's μ < μ |
|---|---|---|---|
| 37 | `one_step_unseq_aux` | `List.length lemTail + 1` | self on the tail `xs`: `len xs + 1 < len (x :: xs) + 1`. (The lem dry run's measure, sufficient as is.) |
| 39 | `get_ctx g` | `lemSize g + 1` | `get_ctx e1` on a direct child (`Ewseq`/`Esseq`/`Ebound`/`Eannot`): `lemSize e1 < lemSize g`; `get_ctx_unseq_aux … es` on the `Eunseq` operands: `lemSize_aux2 es + 1 < 1 + (1 + lemSize_aux2 es) + 1`. (Dry-run measure, sufficient.) |
| 40 | `get_ctx_unseq_aux … lemTail` | `generic_expr_.lemSize_aux2 lemTail + 1` — **not** the dry run's `List.length lemTail + 1` | on `e :: es2`: `get_ctx e` needs `lemSize e + 1 < 1 + lemSize e + lemSize_aux2 es2 + 1` ✓; self on `es2`: `lemSize_aux2 es2 + 1 < …` ✓. With `List.length` the `get_ctx e` hop has no bound at all (an element's own recursion depth is unbounded by the list's length). |
| 64 | `are_compatible p p0` | `ctype.lemSize p.2 + ctype.lemSize p0.2 + 1` | on `Array0`/`Pointer`/`Atomic`/`FunctionNoParams`/`Function` children `(u1, u2)`: `lemSize u1 + lemSize u2 + 1 <` the parents' (each parent ≥ 2 + child); `are_compatible_params ps1 ps2` from `Function/Function`: `lemSize_aux1 ps1 + lemSize_aux1 ps2 + 2 < (2 + lemSize r1 + aux1 ps1) + (2 + lemSize r2 + aux1 ps2) + 1` ✓ (slack 2 + the return types). (Dry-run measure, sufficient.) |
| 65 | `are_compatible_params_aux acc lemTail` | `ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1 lemTail.2 + 1` — **not** the dry run's `List.length lemTail.1 + 1` | on `((_, t1, _) :: ps1, (_, t2, _) :: ps2)`: `are_compatible (nq, t1) (nq, t2)` needs `lemSize t1 + lemSize t2 + 1 < (1 + lemSize t1 + aux1 ps1) + (1 + lemSize t2 + aux1 ps2) + 1` ✓; self on `(ps1, ps2)`: `aux1 ps1 + aux1 ps2 + 1 < …` ✓. With `List.length` the `are_compatible` hop is unbounded (the lem record §7 decision 3's own caveat, confirmed). |
| 66 | `are_compatible_params ps1 ps2` | `ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2` — **not** the dry run's `List.length params1 + 1` | its only body is `are_compatible_params_aux true (params1, params2)` at fuel − 1, whose μ is `aux1 ps1 + aux1 ps2 + 1`; hence exactly one more: `+ 2`. |

### 3.3 The proofs (kernel-only; no `set_option`; no `sorry`)

- `lean_frontend/Core_reduction_lemMeasureProofs.lean` (extended; the module
  already carried `has_ccall`): `one_step_unseq_aux_stable` by induction on
  the hoisted list — the nested list-head patterns (`Expr _ (Epure (Pexpr _ _
  (PEval cval))) :: xs`, the `Eannot` form, the catch-all) are opened by
  `split`, whose generalized discriminant equation (`heq : x :: xs = … ::
  xs✝`) is closed by `cases heq` before the `key` rewrite (the C2 idiom
  needed this one extra step — recorded for the next writer);
  `get_ctx_stable_aux` — ONE joint statement (`∧`) for the mutual pair by
  strong induction on the bound `k`, each part with `key1`/`key2` rewrites
  whose side conditions (`callee μ < this entry's μ`) `size_lt` discharges;
  the `Eannot _ (Expr _ (Eannot _ e))` nested pattern is opened by
  destructuring the inner expression (18 more arms, all closed by the same
  `simp`).
- `lean_frontend/AilTypesAux_lemMeasureProofs.lean` (NEW; added to
  `handwritten_copy.manifest` and to the lakefile roots list; imports
  `AilTypesAux` only — a local `csize` discharger unfolds the three ctype
  sizes then `omega`): `are_compatible_stable_aux` — one joint statement for
  the three members; part 1 opens both ctypes with the Ctype_lemMeasureProofs
  `rcases` pattern (10 × 10 arms, tuple patterns destructured before the
  matcher reduces; all but the 7 recursive arms close by `rfl`), then `simp
  (disch := csize) only [key1, key3]`; part 2 `rcases` both lists (the
  `([], [])`/mismatch arms close by unfolding); part 3 is the single hop.
- Two slips caught by the checker on the way (recorded, not hidden): (i) my
  first `key` statements bounded the callee's measure by `k` (unprovable:
  `μ ≤ k+1` and `μ ≤ f+1` give no `k ≤ f`) — the template's form is
  "callee μ < THIS entry's μ"; (ii) in the aux part a `∀ … l` binder
  shadowed the outer `l` in the bound, making `key2` vacuous (`unsolved
  goals` at the one hop it should have closed) — renamed. Neither needed
  a measure change.

The obligations, `#print axioms` verbatim (`lake env lean` on a scratch file
importing both auxiliaries; the generated obligation AND its hand-written
proof):

```
'one_step_unseq_aux_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'get_ctx_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'get_ctx_unseq_aux_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'are_compatible_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'are_compatible_params_aux_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'are_compatible_params_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
```

(and identically the six `Core_reduction_lemMeasureProofs.*` /
`AilTypesAux_lemMeasureProofs.*` proof constants). Build of the two
auxiliaries: `Build completed successfully (105 jobs).`; no warning in
either proof module.

## 4. OCaml byte identity and the Lean tree after the declares

After the `.lem` edits, `make prelude-src` then `diff -rq` vs the C2
snapshot, verbatim: `check_lem_sync: recorded ocaml_frontend/lem_sync.sha256
(src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen
295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)` /
`OCAML diff -rq rc=0 lines=0 files=86` — **BYTE-IDENTICAL** (the `gen`
hash is the pre-arc one; `src` moves with the `.lem` text by construction).
Oracle re-stamped `DUNE_CACHE=disabled`: `check_driver_fresh: recorded
oracle stamp (bin 3274370595e9b7b3c7f54c76db471a94979a7627c6d36516314adc8ea49e2e6a,
src 7f1a0c0afb84d4a2bac8e240197ae9d72d194985237aeb35ae16afa5cce912bf)`.

Lean: `check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src
35721b02…, gen e48450a7c3ef435844a6de36180fa1a473126c3bf0a5a8a1e1f23b0bea740218)`;
`diff -rq` vs the snapshot: 13 entries (205 files) — `AilTypesAux.lean`,
`AilTypesAux_auxiliary.lean`, `Core_reduction.lean`,
`Core_reduction_auxiliary.lean` (the declared modules: hoisted heads, measured
wrappers, obligation shells), the proofs copies
(`Core_reduction_lemMeasureProofs.lean`, new `AilTypesAux_lemMeasureProofs.lean`),
and the seven callers that lose `[LemFuel]`: `Cabs_to_ail_aux`,
`Cabs_to_ail_effect`, `Cabs_to_ail`, `Ctype_aux`, `GenTypesAux`, `GenTyping`,
`Mini_pipeline` (diff line counts 2/6/2/12/8/34/2). The 59 changed heads are
enumerated in the change manifest §2 (derived: `diff` filtered to
`def`/`partial def`/`theorem` lines); every one of the 53 caller heads only
drops `[LemFuel]`. The six wrappers, verbatim:

```
def one_step_unseq_aux {a : Type} {b : Type} (p : (List (dyn_annotation) ×List (value))) (lemTail : List (generic_expr b a (sym))) : Option ((List (dyn_annotation) ×List (value))) := one_step_unseq_aux_lemFuel (List.length lemTail + 1) p lemTail
def get_ctx (g : generic_expr (core_run_annotation) (Unit) (sym)) : List ((context ×expr (core_run_annotation))) := get_ctx_lemFuel (generic_expr.lemSize g + 1) g
def get_ctx_unseq_aux (annot1 : List (annot)) (acc : List ((context ×generic_expr (core_run_annotation) (Unit) (sym)))) (es1 : List (generic_expr (core_run_annotation) (Unit) (sym))) (lemTail : List (generic_expr (core_run_annotation) (Unit) (sym))) : List ((context ×generic_expr (core_run_annotation) (Unit) (sym))) := get_ctx_unseq_aux_lemFuel (generic_expr_.lemSize_aux2 lemTail + 1) annot1 acc es1 lemTail
def are_compatible (p : (qualifiers ×ctype)) (p0 : (qualifiers ×ctype)) : Bool := are_compatible_lemFuel (ctype.lemSize p.2 + ctype.lemSize p0.2 + 1) p p0
def are_compatible_params_aux (acc : Bool) (lemTail : (List ((qualifiers ×ctype ×Bool)) ×List ((qualifiers ×ctype ×Bool)))) : Bool := are_compatible_params_aux_lemFuel (ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1 lemTail.2 + 1) acc lemTail
def are_compatible_params (params1 : List ((qualifiers ×ctype ×Bool))) (params2 : List ((qualifiers ×ctype ×Bool))) : Bool := are_compatible_params_lemFuel (ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2) params1 params2
```

(whitespace squeezed). `build_lean`: `Build completed successfully (271 jobs).`
/ `check_driver_fresh: recorded lean stamp (bin fbd8e397944f350b4024507ea888735db18dd7ab3daeec86e554d47ec89d557c,
src caa6f8b8d0bd9839d68682acd6b28b9963a85919dc2ecc2b5fb25d7e060c6bc4)`.

## 5. The register and the gates

`scripts/fuel_forms_pending.txt`: the point-free block (3 comment lines + 6
rows) deleted; header pointer extended to this record; 21 → 15 rows. Pins:
`TotalityProofTest.lean` Part 1 regenerated with `scripts/gen_fuel_parametricity.py
--emit` (29 → 23 ambient wrappers; the `ctype_aux` trio's workers lost
their `[LemFuel]` so their pins read `@f ⟨n⟩ = f_lemFuel n`). `test_unit.sh`
on the six-measure tree — the gate lines verbatim:

```
check_handwritten_sync: OK (35 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
✓ effects-proof-test PASSED
TotalityProofTest: all proofs kernel-checked at compile time (fuel parametricity of every fuel'd def + symbolic execution)
✓ totality-proof-test PASSED
✓ core-parser-test PASSED
✓ fresh-int-test PASSED
✓ pp-test PASSED
✓ fuel-exemplar-test PASSED
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (205 files: 0 axioms, boundary-opaque population = the 26 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (321 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 35 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: FUEL arc leg OK (34 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 fuel_measure sufficiency obligations (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (282 files scanned comment-stripped — generated 205, hand-written+test 42, LemLib 35; 0 sorry tokens)
test_fuel_classifier: 18 fixtures, ALL OK
check_no_fuel_numerals: SELFTEST — planting F1-F6 into a scratch copy of the scan set (loud plant banner; nothing in the tree is touched)
check_no_fuel_numerals: SELFTEST OK (20 plants red with the declared label; E5 indirection a recorded known gap; unplanted set green)
check_no_fuel_numerals: OK (286 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
gen_fuel_parametricity: OK (23 ambient fuel wrappers in the generated tree = the 23 pins of TotalityProofTest.lean Part 1, both directions)
check_lakefile_roots: SELFTEST — planting on a scratch copy of lakefile.toml (loud plant banner; nothing in the tree is touched)
check_lakefile_roots: SELFTEST OK (3 plants red, baseline green)
check_lakefile_roots: OK (204 roots = 204 generated modules + the exe root Main; 85 auxiliary modules all built)
check_fuel_forms: SELFTEST — plants on a scratch copy of the classification table (loud plant banner; nothing in the tree is touched)
check_fuel_forms: SELFTEST OK (7 plants red with the declared label — 5 on the table, 2 compiled decoy obligations; unplanted table green)
check_fuel_forms: forms partition OK (47 MEASURED + 13 ABSORBING + 15 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 47 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 15 reachable-AMBIENT = the 15 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: lean OK (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen e48450a7c3ef435844a6de36180fa1a473126c3bf0a5a8a1e1f23b0bea740218)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
```

(`test_unit rc=0`, checked explicitly; `check_theorem_axioms`' FUEL leg names C1's three obligations by design — the (A) coverage of all 47 is the fuel-forms gate's.)

## 6. Battery (fresh stamped binaries; default fuel; serial, `SKIP_BUILD=1`)

### 6.1 Tier A at the pin bump (commit 1/n), rows 2–11 — every lane rc 0

Stamps: oracle `bin 4925895b…`/`src 754ef1e9…`, lean `bin 797d1383ba69…` (§2.2); `test_unit.sh` rc 0 (its `check_fuel_forms` line: `OK (81 fuel'd workers: 41 MEASURED …, 13 ABSORBING, 21 reachable-AMBIENT = the 21 rows …, 6 …)`, `gen_fuel_parametricity: OK (29 … = the 29 pins …)`, `check_lakefile_roots: OK (203 roots …)`, `check_sorry_token: OK (280 files … LemLib 35 …)` — the one moved number vs C2 is LemLib's file count, `LemLibPmapLaws.lean`). Rows 2–11 (`.tmp/c3/battery-pinbump/rc.txt`, every `rc=0`), the summary lines verbatim:

| Row | Verbatim |
|---|---|
| A2_minimal (rc=0) | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A3_coverage (rc=0) | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4_debug (rc=0) | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4b_float (rc=0) | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4c_bytes (rc=0) | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| A5_libc_exec (rc=0) | `SUMMARY: match=11 diff=0` / `ALL MATCH RECORDED BASELINE` |
| A6_multi_tu (rc=0) | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| A7_parse (rc=0) | `Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A8_core (rc=0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A9_elab (rc=0) | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` |
| A10_uri (rc=0) | `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| A11_cn (rc=0) | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |

### 6.2 Tier A + Tier B on the six-measure head — per-lane rc and summary lines

Stamps: oracle `bin 32743705…`/`src 7f1a0c0a…` (§4), lean `bin fbd8e397…`/`src caa6f8b8…` (§4); `test_unit.sh` rc 0 (§5). 28 lanes serially (`.tmp/c3/battery.sh six AB`, `.tmp/c3/battery-six/rc.txt`): 27 × `rc=0`, and **B7_gcc `rc=1` on its first run** — one row moved into `SKIP_LEAN_TIMEOUT` (`compared` 1885 → 1884, `skip_lean_timeout` 11 → 12, `disagree=0`), verbatim `REGRESSION: csmith/sa_csmith_85.c baseline=AGREE/O2_AGREE current=SKIP_LEAN_TIMEOUT/-`. That is exactly LADDER.md's B7 load caveat class (the box's load average read `38.93` / `46.42` at that time — another agent's `go`/`golean` processes at 200–400 % CPU each); per the ladder the lane was RE-RUN on the quiet box (load `2.05` → `0.38` across the run), `.tmp/c3/battery-six-rerun/`, verbatim:

```
B7_gcc rc=0
 04:44:29 up 12 days, 14:15,  ? user,  load average: 2.05, 10.59, 15.59
[748/1963] AGREE O2_AGREE csmith/sa_csmith_85.c: gcc=248 lean={248}
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

— row-for-row the C2 result (C2 record §6.2: `compared=1885 agree=1873 … disagree=0`). The row hand-times at ~18 s CPU (§7 F-C3-4), inside the caveat's "slowest csmith rows hand-time at ~17 s". No code change; no instrument commit; ZERO baseline movement in all 28 lanes. The per-lane lines of the first run (B7's line is that run's), verbatim:

| Row | Verbatim |
|---|---|
| A2_minimal (rc=0) | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A3_coverage (rc=0) | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4_debug (rc=0) | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4b_float (rc=0) | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4c_bytes (rc=0) | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| A5_libc_exec (rc=0) | `SUMMARY: match=11 diff=0` / `ALL MATCH RECORDED BASELINE` |
| A6_multi_tu (rc=0) | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| A7_parse (rc=0) | `Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A8_core (rc=0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A9_elab (rc=0) | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` |
| A10_uri (rc=0) | `[ocaml-nolibc] exit=1: Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(1451, SD_Id("memset"))'"}` / `[lean-nolibc] exit=1 wall=0:01.12 maxRSS=236428kB: Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(968, SD_Id("memset"))'"}` / `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| A11_cn (rc=0) | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |
| B1_libxml2 (rc=0) | `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED` |
| B2_parse_ci (rc=0) | `Lean front end: 117 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 2 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   51% (of cerberus successes)` / `ALL PASSED` |
| B3_core_ci (rc=0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| B4_verify (rc=0) | `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)` |
| B5_immaculate (rc=0) | `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).` |
| B6a_speclab_self (rc=0) | `test_speclab: PASS (both pipelines agree on Specified(0))` |
| B6b_speclab_plant (rc=0) | `test_speclab: PASS (both pipelines agree on Specified(2))` |
| B6c_divmod (rc=0) | `CoreGateTest: ALL PASSED` / `test_speclab_divmod: PASS (--gate)` |
| B6d_bytearr (rc=0) | `ByteArrGateTest: ALL PASSED` / `test_speclab_bytearr: PASS (--gate)` |
| B6e_list (rc=0) | `ListGateTest: ALL PASSED` / `test_speclab_list: PASS (--gate)` |
| B6f_tree (rc=0) | `TreeGateTest: ALL PASSED` / `test_speclab_tree: PASS (--gate)` |
| B6g_seed (rc=0) | `SeedGateTest: ALL PASSED` / `test_speclab_seed: PASS (--gate)` |
| B7_gcc (rc=1) | `SUMMARY: total=1963 compared=1884 agree=1872 agree_nd=0 triaged=12 disagree=0 o2_agree=189 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=12 skip_ub=47 triaged_addr=11 triaged_ub=1` / `REGRESSION: csmith/sa_csmith_85.c baseline=AGREE/O2_AGREE current=SKIP_LEAN_TIMEOUT/-` / `Baseline check: 1 regression(s), 0 improvement(s)` |
| B8a_hang (rc=0) | `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)` |
| B8b_kill (rc=0) | `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)` |
| B8c_fuel (rc=0) | `test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)` |

## 7. Findings

- **F-C3-1 (the dry-run measures for the shared-counter blocks were
  insufficient, as the lem record cautioned).** `List.length lemTail + 1`
  for `get_ctx_unseq_aux` / `List.length lemTail.1 + 1` for
  `are_compatible_params_aux` / `List.length params1 + 1` for
  `are_compatible_params` bound only the list walk, not the element hops; the
  measures of §3.2 are the derived sizes of the whole structure and are
  proved. No lem change needed: the renderer accepts qualified globals
  (`generic_expr_.lemSize_aux2`, `ctype_.lemSize_aux1`) as the lem record
  §7 decision 3 anticipated.
- **F-C3-2 (the pin bump is a Lean no-op on the C2 tree).** Byte-identical
  Lean tree and byte-identical driver binary — the general hoist rule (F3 of
  the lem audit) has zero effect until a trailing-lambda definition is
  measured. Nothing to adjust.
- **F-C3-3 (`split` generalizes the discriminant).** On a `match` over a
  cons with nested head patterns, `split`'s arms carry `heq : x :: xs = … ::
  xs✝` with a FRESH tail — the induction hypothesis about `xs` does not apply
  until `cases heq`. Tactic-level; recorded for the proofs template.

- **F-C3-4 (B7 first run: one row into `SKIP_LEAN_TIMEOUT` under load 39; re-run
  green; the measured-wrapper cost is a real mechanism to watch).** §6.2 has the
  verbatim lines. Hand-timing the row (`tests/csmith/small_arrays/csmith_85.c`
  staged as the lane does, cabs-json from the fresh oracle, `--batch --first`,
  `/usr/bin/time`, quiet box load 2.9–4.7, two runs each): this head's driver
  `fbd8e397…` user `18.10` / `18.17` s; the primary checkout's driver (hash
  `444f1c28…`, NOT C2's `797d1383…` — provenance unknown, read-only execution)
  user `16.86` / `16.72` s; both `Defined {value: "Specified(248)", …}`. The
  clean A/B against C2's binary, rebuilt from this slice's own C2 snapshot of
  `generated/` in a scratch Lake package under `.tmp/c3/c2pkg` (Lake pin
  `d4ba548`; the pin-bump proved that tree's binary is C2's byte-for-byte):
  the scratch build reproduced C2's binary EXACTLY (`797d1383ba69f288f1b936c31060667e56f27c7347136e2c3ea5127b13e66993  .lake/build/bin/cerberus-lean`, `Build completed successfully (271 jobs).`); interleaved runs, same json, `--batch --first`, verbatim (`/usr/bin/time`; the box's load average was `48.88` at the start of this series — CPU time is the robust column):

  ```
  797d1383 run1 wall=17.77 user=17.72 sys=0.04 maxrss=128192kB exit=0
  fbd8e397 run1 wall=18.32 user=18.29 sys=0.03 maxrss=127708kB exit=0
  797d1383 run2 wall=17.00 user=16.95 sys=0.04 maxrss=128964kB exit=0
  fbd8e397 run2 wall=18.26 user=18.22 sys=0.03 maxrss=126876kB exit=0
  797d1383 run3 wall=16.98 user=16.94 sys=0.04 maxrss=129532kB exit=0
  fbd8e397 run3 wall=18.77 user=18.72 sys=0.05 maxrss=128440kB exit=0
  ```

  — every run `Defined {value: "Specified(248)", …}`; derived: C2 mean user
  17.20 s, C3 mean 18.41 s, **+7.0 % CPU on this row** (one row; a second,
  small row `small_mix/csmith_1.c` reads `0.18` vs `0.19` s — noise). Memory
  unchanged (maxrss ≈ 128 MB both).
  Mechanism to name (PL terms): a MEASURED wrapper evaluates its measure
  EAGERLY at every call — `get_ctx g` is called once per step of the driver
  loop on the thread's arena (`core_reduction.lem:1489`), and its measure
  `generic_expr.lemSize g + 1` is a full traversal of the arena, where
  `get_ctx` itself walks only the redex path (O(depth)); a program with a
  large arena and many steps pays O(|arena|) extra per step. The other five
  measures are cheap (`List.length` of a short operand list; ctype sizes on
  the type checker's path). This is a perf observation, not a correctness
  one; per "profile before optimizing" nothing was changed — decision §8.4.

## 8. Decisions for the operator (nothing here was decided by me)

1. [AGENT] **`lemTail` measures name backend-derived helpers as qualified
   globals** (`generic_expr_.lemSize_aux2`, `ctype_.lemSize_aux1`). These
   names are deterministic from the type definitions but are the backend's
   (the `_auxN` index follows the order of list-typed constructor fields);
   a future lem change to the helper naming would refuse the declare loudly
   (FM-free) rather than mis-measure. Alternative not taken: asking lem for a
   `lemSize`-style keyword for the derived helper of a list parameter (new
   declare vocabulary under the consolidation freeze, lem TODO 18). Operator's
   call whether to request it.
2. [AGENT] **The consumer-visible arity change** of the three hoisted-tail
   wrappers and workers (manifest §2) is accepted as the cost of the measured
   form — the lem record's F3 (general rule) makes it uniform. No shim
   (`funext`-recoverable) was added.
3. [AGENT] The remaining 15 PENDING rows keep their C2 routes (D-C2-1..4);
   nothing in this slice touched them.
4. [AGENT] **`get_ctx`'s eager arena-size measure (F-C3-4).** Options, none
   taken here: (a) accept — the semantics is a reasoning artifact
   ([USER 2026-09-03]); the differential lanes are green and the lane timeout
   caveat already covers load; (b) a cheaper sufficient measure — the recursion
   depth of `get_ctx` is bounded by the arena's DEPTH (plus, at each `Eunseq`,
   the operand list's length), so a backend-derived `lemDepth` (or a
   hand-written depth function named as a qualified global) would be
   O(|arena|) too unless memoized — no free lunch without changing the
   wrapper's evaluation strategy; (c) a lem-side change: let the measured
   wrapper pass the measure LAZILY (e.g. compute the fuel only when the
   counter would otherwise exhaust) — a design change to the fuel scheme,
   for the lem side and the consumer to weigh. Measure first: the A/B above
   is the only number; the mem-scale/timing lane on the csmith tier would
   quantify it across the corpus.

## 9. Commits

| # | Commit | Content | Verified before commit |
|---|---|---|---|
| 1/n | `d0b5319fc` | Lake pin bump `ecf75b4` → `d4ba548` (lakefile + 3 manifests), nothing else | trees regenerated from re-derived sources: OCaml/sibylfs/Lean all BYTE-IDENTICAL to the C2 head (§2.2); `DUNE_CACHE=disabled build_cerberus`, `build_lean` (binary = C2's); `test_unit.sh` rc 0; Tier A rows 2–11 rc 0 (§6.1) |
| 2/n | `642c2181a` | the six `fuel_measure` declares (Lean-only), `Core_reduction_lemMeasureProofs` extended, NEW `AilTypesAux_lemMeasureProofs` (+ manifest, lakefile root), register 21 → 15, pins 29 → 23 | OCaml byte-identical (§4); auxiliaries build (105 jobs), 12 `#print axioms` lines standard-three (§3.3); `build_cerberus` cache-disabled + `build_lean` stamped; `test_unit.sh` rc 0 with the gate lines of §5; A2/A3 `BASELINE OK` (the full battery §6.2 ran on this head afterwards: 27 × rc 0 + B7 re-run rc 0) |
| 3/n | (this commit) | this record, the change manifest, `VALIDATION.md` ((A)/(B)/(C) counts 47/13/15/6), `TODO.md` (row resolved) | docs-only; the battery of §6.2 on the 2/n head |

Why 2/n is one commit and not "declares+proofs" then "register": the gate is
fail-closed BOTH ways — with the six measured, their register rows are STALE
PINS and `check_fuel_forms` is RED until they are deleted, and
`gen_fuel_parametricity --check` is RED until the pins are regenerated; a
declares-only commit would have been a RED tree (C2's F-C2-8 lesson: never
commit a red gate). The docs are separate because they carry the battery's
verbatim lines, which exist only after the 2/n head was built and run.

## 10. Not done, and why

- Nothing of the charter is left pending: six of six rows are MEASURED.
- refined-cerberus untouched (the manifest is theirs); lem-lean untouched
  (no lem change was needed).
- The mem-scale sweep, the csmith shards and the Tier C instruments were not
  run (not asked; Tier B in full is §6.2).

## 11. Worktree state at close

Branch `arc/fuel-parameter-C3`; `lean_frontend/generated/` and
`ocaml_frontend/generated/` are the REAL trees (lem-sync stamped, §4); both
driver binaries fresh (`check_driver_fresh --check`); `.tmp/c3/` (the C2
snapshots, lane logs, probes, drafts) is ephemeral and deleted at slice end;
everything load-bearing is quoted here.
