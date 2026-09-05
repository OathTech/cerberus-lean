# Pre-merge audit — fuel-parameter arc, cerberus slice C3 (2026-09-05)

Auditor [AGENT] (independent of the C3 worker and of the orchestrator).
Range audited: mainline `mdd/cerberus-lean` @ `a910f097c` (the merged C2) →
`arc/fuel-parameter-C3` @ `d127cfa9b`, three commits: `d0b5319fc` (Lake
pin bump LemLib `ecf75b4` → `d4ba548`), `642c2181a` (six `fuel_measure`
declares + kernel proofs; register 21 → 15; pins 29 → 23), `d127cfa9b`
(record + change manifest + `VALIDATION.md`/`TODO.md`). Record audited:
`2026-09-05_fuel-parameter-C3-record.md`; manifest:
`2026-09-05_fuel-parameter-C3-change-manifest.md`.

Method: the worker's worktree (`worktrees/cerberus-lean-arc/zero-discrepancy`,
built and stamped, read + probe only) for the generated tree, the gates and
the lanes; this document written on branch `audit/c3-premerge` in a separate
worktree (`worktrees/cerberus-lean-audit/c3-premerge` @ `d127cfa9b`). No
lane or build was started until the orchestrator's battery in the worker's
worktree printed `=== DONE` (`.tmp/c3-reverify.log`); after it, only the
three lanes named in the brief plus one `lake env lean` probe, serially,
`CERB_MEM_MAX=16G`, `ulimit -c 0`. Every quoted output is verbatim; tallies
marked "derived" are derived. Nothing merged, nothing pushed; `deps/`,
lem-lean, the primary checkout and the other worktrees untouched.

Grading frame (the brief): MAJOR = a `.lem` body change / an OCaml change /
an obligation not the contract's or a proof not for all inputs / an
insufficient measure that the obligation somehow admits / a register row
removed without its theorem / a gate that cannot go red / a battery claim
not reproduced. MINOR; NOTE.

## 0. Verdict

**MERGEABLE — no MAJOR; no code change asked. Conditional on ONE owed
lane re-run (M2: the orchestrator's B7 gcc lane came back `rc=1` in the
LADDER load-caveat class — one row into `SKIP_LEAN_TIMEOUT`, `disagree=0`,
box load 33 during the lane — and must be re-run on a quiet box and read
`rc=0` before the merge ask, exactly as the ladder prescribes) and two
docs-only fixes (M1, N7).** Every MAJOR criterion was checked and none
fires:

- the `.lem` diff is six `declare {lean} fuel_measure val` lines plus two
  comment blocks — no body, type or `val` changed (§1); the OCaml generated
  tree's lem-sync `gen` stamp is the pre-arc `295e4f82…` on the built head
  (§1);
- commit 1/n touches exactly the four pin files (§2); the record's "Lean
  tree byte-identical at the pin bump" is REPRODUCED by content hash —
  regenerating the C2 `.lem` sources with the NEW lem `d4ba548` in my
  worktree gives `gen 76d138a3…`, the C2 head's stamp under the OLD lem
  (C2 record §14) — and is what the hoist rule predicts: none of C2's 38
  `fuel_measure` declares (and there are no `structural` declares) sits on
  a definition whose clause body is a trailing lambda (§2, all 38
  enumerated);
- all six generated obligations are the contract's statement (`∀ params,
  ∀ lemFuel, μ ≤ lemFuel → f_lemFuel lemFuel … = f …`), applied at the
  exact type to a hand-written constant; the six proofs are universally
  quantified over every input, by strong induction on the bound with a
  strict-decrease `key` at every hop — the hop arithmetic was re-derived
  by hand from the generated workers and the derived `lemSize` equations,
  and holds for all 14 cross-calls (§3); cones ⊆ the standard three (§3,
  the probe of §7); no `sorry`/`native_decide`/`bv_decide`/`decide`/
  option bump (the only `set_option` is `autoImplicit false`);
- the six register rows deleted are exactly the six measured, each with
  its obligation and proof (§4); `check_fuel_forms.sh` and
  `gen_fuel_parametricity.py --check` are green on the head and the
  fuel-forms selftest's seven plants go red (§7);
- the change manifest reproduces EXACTLY: the C2 and C3 Lean trees
  regenerated in my worktree differ in 11 lem-emitted files and 59
  distinct definition/theorem heads — the 18 own-family heads of the six
  (wrappers, obligations, the three hoisted workers and their `_zero`
  lemmas) + the 41 caller heads the manifest lists by name; after
  stripping `[LemFuel]` no caller head differs (§5); the derived counts
  (251 binders, 23 ambient wrappers, 47 obligations) also reproduce (§5);
- Tier A + Tier B on the head: the orchestrator's battery, 24 lanes
  `rc=0`, B7 in the caveat class (§7.1); the three lanes I re-ran myself
  `rc=0` (§7.2); the 12 axiom cones (§7.3).

Findings are §9: no MAJOR; two MINOR (M1 a completeness gap in the F-C3-4
decision options, docs; M2 the owed B7 re-run); NOTEs incl. N7 (a
derived-tally slip: "53 caller heads" is 41).

## 1. `.lem` discipline and OCaml byte identity

`git diff a910f097c..d127cfa9b -- frontend/model/` (verbatim, filtered to
non-comment `+` lines):

```
+declare {lean} fuel_measure val are_compatible = `ctype.lemSize p.2 + ctype.lemSize p0.2 + 1`
+declare {lean} fuel_measure val are_compatible_params_aux = `ctype_.lemSize_aux1 lemTail.1 + ctype_.lemSize_aux1 lemTail.2 + 1`
+declare {lean} fuel_measure val are_compatible_params = `ctype_.lemSize_aux1 params1 + ctype_.lemSize_aux1 params2 + 2`
+declare {lean} fuel_measure val one_step_unseq_aux = `List.length lemTail + 1`
+declare {lean} fuel_measure val get_ctx = `lemSize g + 1`
+declare {lean} fuel_measure val get_ctx_unseq_aux = `generic_expr_.lemSize_aux2 lemTail + 1`
```

plus one 9-line `(* FUEL MEASURE … *)` comment block before each trio
(`ailTypesAux.lem` +12 lines, `core_reduction.lem` +12 lines; `git diff
--stat`). No `-` lines in either file. The existing `declare {lean} fuel
val …` sentinel declares for the same six stay (the payload is still
needed for the worker's exhaustion arm; the tails record §7 decision 5:
the payload written at the original function codomain is applied to the
hoisted binder — visible in the generated `_zero` lemmas, §5). The brief's
"six declare lines ONLY" holds up to the two comment blocks, which are
non-semantic for every target.

OCaml byte identity on the built head (the worker's worktree,
`ocaml_frontend/lem_sync.sha256`, verbatim):

```
src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8
gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100
```

— the `gen` hash is the C2 head's (C3 record §2.2 quotes the same value
before any `.lem` edit; the `src` moved with the declare text by
construction). The record's `diff -rq` lines (`OCAML diff -rq rc=0 lines=0
files=86`) were not re-run — the stamp is the mechanical equivalent.

## 2. Pin bump isolation and the "byte-identical Lean tree" claim

`git show --stat d0b5319fc`: `lean_frontend/lake-manifest.json` (4 lines),
`lean_frontend/lakefile.toml` (9: the `rev` + a 7-line comment),
`lean_frontend/speclab/lake-manifest.json` (4),
`tests/mem-scale-probes/micro/lake-manifest.json` (4); nothing else. All
four `rev`/`inputRev` values `d4ba548d084ff393126f04d90f18a72c3000aa88`.

Pin consistency, verbatim: lem-lean `git log --oneline -1 mdd/lean-backend`
→ `d4ba548 tails-and-pmap-laws slice: orchestrator boundary review (two
independent re-runs; final head green; audit document on the branch)`;
`git -C deps/lem-pinned rev-parse HEAD` → `d4ba548d084ff393126f04d90f18a72c3000aa88`;
the worker worktree's `.lake/packages/LemLib` HEAD → the same; `opam exec
--switch=. -- lem -v` → `Lem d4ba548`. Branch head = opam pin = Lake pin =
lem mainline.

**The Lean-identity claim, verified by reasoning from the rule.** The tails
record §2.2: the hoist fires ONLY on a definition carrying `fuel_measure`
or `structural`, and hoists a trailing lambda of the clause body (the
`function` scrutinee's compiler lambda, or a user `fun k ->`, through a
`Paren` or the single-arm destructuring match). At `a910f097c`, `git grep
'declare {lean} \(fuel_measure\|structural\) val'` over every `.lem`
yields 38 `fuel_measure` declares and 0 `structural` declares (the gate's
"41 MEASURED" = these 38 generated + the 3 hand-written `CerbMem` rows,
which lem never sees). I printed each of the 38 definitions' head line and
body start (`let rec f … =` + the first code line): every body begins with
`match …`, `if …`, `let … in`, or a constructor application (`Expr annot
match …`), none with `function` or `fun`. The two `let ord = function`
occurrences (`eq_core_base_type`, `ctypeEqual`) are `let`-bound lambdas
inside the body, not the clause body's trailing lambda. Hence the rule has
no trigger on the C2 tree, and a byte-identical Lean tree at the pin bump
is what the rule predicts.

**Reproduced by content hash.** In this audit worktree (`git checkout
a910f097c -- frontend/model`, then `scripts/ce make lean-prelude-src`
with the pinned lem `d4ba548`; no Lean build), verbatim:

```
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 928a08cd72f10e899385191821266f915008a499c4033de8b44893b9fcac2e8a, gen 76d138a3a8e6f5866edaebfc9725d265812de4fdaab908a650fbdb567f279f35)
```

— `gen 76d138a3…` is the C2 head's Lean stamp as generated under the OLD
lem `ecf75b4` (C2 record §14, the orchestrator's boundary review quotes
it; the C3 record §2.2 quotes the same value before regenerating). Same
sources, two lems, one content hash: the pin bump is a Lean no-op on the
C2 tree, independently of the worker's `diff -rq`. Then `git checkout
d127cfa9b -- frontend/model` and regenerate: `gen e48450a7c3ef43584…`,
and `diff -rq` of that tree against the worker's built
`lean_frontend/generated/` is EMPTY (rc 0) — the built head is the
regenerated head. (The old lem itself was not rebuilt; the hash equality
makes that unnecessary.)

**The C3 head's tree.** `lemTail` occurs in exactly six generated files —
`Core_reduction.lean` (12), `Core_reduction_auxiliary.lean` (8),
`Core_reduction_lemMeasureProofs.lean` (15), `AilTypesAux.lean` (6),
`AilTypesAux_auxiliary.lean` (4), `AilTypesAux_lemMeasureProofs.lean` (8)
(derived, `grep -c`) — i.e. only the three hoisted functions' workers,
wrappers, `_zero` lemmas, obligations and proofs; no other hoist happened.

## 3. The six measures and their proofs

### 3.1 Obligation statements (generated, verbatim heads)

`Core_reduction_auxiliary.lean:44,54,59` and `AilTypesAux_auxiliary.lean:37,42,47`
— each `theorem f_measure_sufficient <params> (lemFuel : Nat) (lemMeasureLe :
(<μ>) ≤ lemFuel) : f_lemFuel lemFuel <params> = f <params> :=
<Module>_lemMeasureProofs.f_measure_sufficient <params> lemFuel lemMeasureLe`,
with `<μ>` the declared measure, e.g.

```
theorem get_ctx_unseq_aux_measure_sufficient (annot1 : List (annot)) (acc : List ((context ×generic_expr (core_run_annotation) (Unit) (sym)))) (es1 : List (generic_expr (core_run_annotation) (Unit) (sym))) (lemTail : List (generic_expr (core_run_annotation) (Unit) (sym))) (lemFuel : Nat) (lemMeasureLe : (generic_expr_.lemSize_aux2 lemTail + 1) ≤ lemFuel) :
    get_ctx_unseq_aux_lemFuel lemFuel annot1 acc es1 lemTail = get_ctx_unseq_aux annot1 acc es1 lemTail :=
  Core_reduction_lemMeasureProofs.get_ctx_unseq_aux_measure_sufficient annot1 acc es1 lemTail lemFuel lemMeasureLe
```

The wrappers (`Core_reduction.lean:351,387,392`; `AilTypesAux.lean:281,286,291`)
are `f <params> := f_lemFuel (<μ>) <params>`, so the obligation is exactly
the fuel-measure record §2.2 contract (stability at and above μ; wrapper =
worker-at-μ by `rfl` — the probe of §7 checks four of these by `rfl`).

### 3.2 The hop arithmetic, re-derived from the generated workers

Derived sizes (generated `Core.lean:1764-1792`, `Ctype.lean:294-311`):
`generic_expr.lemSize (Expr _ e) = 1 + generic_expr_.lemSize e`;
`Eunseq es ↦ 1 + aux2 es`; `Ewseq _ e1 e2 / Esseq _ e1 e2 ↦ 1 + lemSize e1 +
lemSize e2`; `Ebound e / Eannot _ e ↦ 1 + lemSize e`; `aux2 (e :: es) = 1 +
lemSize e + aux2 es`, `aux2 [] = 0`. `ctype.lemSize (Ctype _ t) = 1 +
ctype_.lemSize t`; `Array0 t _ / Pointer _ t / Atomic t ↦ 1 + lemSize t`;
`Function (_, r) ps _ ↦ 1 + lemSize r + aux1 ps`; `FunctionNoParams (_, r) ↦
1 + lemSize r`; `aux1 ((_, t, _) :: ps) = 1 + lemSize t + aux1 ps`.

The block shares one counter: a member entered at `Nat.succ k` makes every
cross-call at `k`. Writing μ for the entry's measure and the hypothesis
`μ ≤ k + 1`:

| Entry (worker) | μ | Hop at fuel k | Needed: callee μ ≤ k | Holds because |
|---|---|---|---|---|
| `get_ctx (Expr a e_)` | `lemSize g + 1` | `Ewseq/Esseq _ e1 e2`: `get_ctx e1` | `lemSize e1 + 1 ≤ k` | `lemSize g = 2 + lemSize e1 + lemSize e2 ≥ 2 + lemSize e1` |
| | | `Ebound e`, `Eannot xs e`: `get_ctx e` | `lemSize e + 1 ≤ k` | `lemSize g = 2 + lemSize e` |
| | | `Eunseq es`: aux on `es` | `aux2 es + 1 ≤ k` | `lemSize g = 2 + aux2 es` |
| `get_ctx_unseq_aux … (e :: es2)` | `aux2 (e::es2) + 1 = lemSize e + aux2 es2 + 2` | `get_ctx e` | `lemSize e + 1 ≤ k` | slack `aux2 es2 + 1` |
| | | self on `es2` | `aux2 es2 + 1 ≤ k` | slack `lemSize e + 1` |
| `one_step_unseq_aux p (x :: xs)` | `len (x::xs) + 1` | self on `xs` (both recursive arms) | `len xs + 1 ≤ k` | exactly one less |
| `are_compatible (qs1, Ctype _ t1) (qs2, Ctype _ t2)` | `size t1 + size t2 + 3` (`ctype.lemSize` unfolded) | `Array0/Array0`, `Pointer/Pointer`, `Atomic/Atomic`: children `u1,u2` | `lemSize u1 + lemSize u2 + 1 ≤ k` | each `size ti = 1 + lemSize ui` |
| | | `Function/Function`: returns `r1, r2` | `lemSize r1 + lemSize r2 + 1 ≤ k` | `size ti ≥ 1 + lemSize ri` |
| | | `Function/Function`: `are_compatible_params ps1 ps2` | `aux1 ps1 + aux1 ps2 + 2 ≤ k` | `size t1 + size t2 + 2 = (1 + lemSize r1 + aux1 ps1) + (1 + lemSize r2 + aux1 ps2) + 2 ≥ aux1 ps1 + aux1 ps2 + 4` |
| | | `Function/FunctionNoParams`, `FunctionNoParams/Function`, `FunctionNoParams/FunctionNoParams`: returns | `lemSize r1 + lemSize r2 + 1 ≤ k` | as above |
| `are_compatible_params_aux acc ((_,t1,_)::ps1, (_,t2,_)::ps2)` | `(1 + lemSize t1 + aux1 ps1) + (1 + lemSize t2 + aux1 ps2) + 1` | `are_compatible (nq, t1) (nq, t2)` | `lemSize t1 + lemSize t2 + 1 ≤ k` | slack `aux1 ps1 + aux1 ps2 + 1` |
| | | self on `(ps1, ps2)` | `aux1 ps1 + aux1 ps2 + 1 ≤ k` | slack `lemSize t1 + lemSize t2 + 1` |
| `are_compatible_params ps1 ps2` | `aux1 ps1 + aux1 ps2 + 2` | aux on `(ps1, ps2)` at k | `aux1 ps1 + aux1 ps2 + 1 ≤ k` | exactly one less — the record's "+2" is right, and tight |

Every hop holds. The record's §3.2 table states the same inequalities; the
lem dry run's `List.length` measures for the two `aux` rows are indeed
insufficient (`get_ctx e` / `are_compatible (nq,t1) (nq,t2)` hops are
unbounded by a list length) — the record's F-C3-1 is correct.

### 3.3 The proofs (`Core_reduction_lemMeasureProofs.lean` +132 lines; `AilTypesAux_lemMeasureProofs.lean` NEW, 153 lines)

- Statements universally quantified over every parameter (`{a b : Type}`
  for `one_step_unseq_aux`, matching the generated obligation's implicit
  type binders); bound `k` by strong induction, `f g` arbitrary fuels ≥ μ;
  the obligation theorems instantiate `k = g = μ` and are exactly the
  auxiliary's applied types (the auxiliary compiles, so the types agree by
  construction — the fuel-measure record §2.2 gate).
- `key` lemmas are "callee μ < THIS entry's μ → worker f = worker g",
  discharged by `omega` from the induction hypothesis; the side conditions
  are closed by `size_lt` (the existing `CerbMeasureLemmas` discharger) /
  the new local `csize` macro (`simp only [ctype.lemSize, ctype_.lemSize,
  ctype_.lemSize_aux1] at *; omega`). No `decide` anywhere.
- Forbidden tokens: `grep -n 'set_option\|sorry\|native_decide\|bv_decide\|ofReduce\|axiom\|decide\b\|maxHeartbeats\|maxRecDepth\|unsafe\|partial'`
  over both files → only `set_option autoImplicit false` (line 37 / line
  19) — a hygiene option, the repo's standard, not a resource bump.
- The hand-written file and its `generated/` copy are byte-identical (`cmp`
  in the worker's worktree; `check_handwritten_sync` counts 35).

Axiom cones: §7 (my probe, 12 lines + four `rfl` identities).

## 4. Register and pins

`scripts/fuel_forms_pending.txt` diff: the 3 comment lines of the
"point-free `function` tails" block and its 6 rows deleted —
`are_compatible_lemFuel`, `are_compatible_params_aux_lemFuel`,
`are_compatible_params_lemFuel`, `one_step_unseq_aux_lemFuel`,
`get_ctx_lemFuel`, `get_ctx_unseq_aux_lemFuel` — exactly the six measured
(§3), each with its generated obligation and hand-written proof; the header's
record pointer extended; no other row touched (`hack`, `to_pure`… and the
nine tag-lookup rows unchanged). 21 → 15 rows.

`TotalityProofTest.lean` Part 1: the six pins for the same six wrappers
deleted; the three `ctype_aux` pins rewritten `@f ⟨n⟩ = @f_lemFuel ⟨n⟩ n` →
`@f ⟨n⟩ = @f_lemFuel n` (their workers lost `[LemFuel]` because the callee
`are_compatible` is now fuel-free; the wrappers stay ambient — the
tag-lookup rows, still registered); header comment 29 → 23. The generated
tree has exactly 23 lines `def … [LemFuel] … := f_lemFuel LemFuel.fuel`
(derived, `grep -c`), = the pin count.

## 5. Change manifest — reproduced

- `[LemFuel]` in the generated model, comment-stripped (`sed 's/--.*$//'`),
  excluding the 35 `handwritten_copy.manifest` seam copies: **251**
  (derived; the manifest says 298 → 251). Including the seam copies: 316.
- Ambient wrappers: **23** (above). Obligations: 44 `theorem
  *_measure_sufficient` in `generated/*_auxiliary.lean` + 3 in
  `CerbMem_lemMeasureProofs.lean` (`typeofMval`, `unqualifyAndUnatomic`,
  `memValueToBytes`) = **47** = the gate's MEASURED count and
  `VALIDATION.md`'s "44 generated + …".
- 13 of the 53 caller heads spot-checked in the built tree, every one
  without `[LemFuel]`: `make_composite_params`, `typecheckAil`,
  `annotate_program`, `composite_pointer`, `one_step0`,
  `are_compatible_aux_lemFuel`, `find_compatible_generic_association`
  (partial), `make_composite_fdecl`, `register_function_declaration`,
  `well_typed_assignment`, `annotate_expression` (partial),
  `find_generic_association`, `are_pointers_to_compatible_types`.
- The arity change described in manifest §2 matches the tree: the three
  hoisted wrappers/workers take `lemTail` as a named last parameter; the
  `_zero` lemmas are applied to it, verbatim
  `one_step_unseq_aux_lemFuel 0 p lemTail = ((fuelExhausted (fun _ => none)) lemTail) := rfl`,
  `get_ctx_unseq_aux_lemFuel 0 annot1 acc es1 lemTail = ((fuelExhausted (fun _ => acc)) lemTail) := rfl`,
  `are_compatible_params_aux_lemFuel 0 acc lemTail = ((fuelExhausted (fun _ => false)) lemTail) := rfl`.
- **The 59 heads, reproduced exactly** from the two regenerated trees
  (§2): `diff -rq` → 11 lem-emitted files differ (`AilTypesAux`,
  `AilTypesAux_auxiliary`, `Cabs_to_ail_aux`, `Cabs_to_ail_effect`,
  `Cabs_to_ail`, `Core_reduction`, `Core_reduction_auxiliary`,
  `Ctype_aux`, `GenTypesAux`, `GenTyping`, `Mini_pipeline`) — the record
  §4's 13 entries minus the two proofs-module copies (hand-written, not
  lem output). Filtering each file's diff to `def`/`partial def`/`theorem`
  lines: **59 distinct names** (derived) = **18 own-family heads** (the six
  wrappers; the six `_measure_sufficient` obligations; the three hoisted
  workers `one_step_unseq_aux_lemFuel`, `get_ctx_unseq_aux_lemFuel`,
  `are_compatible_params_aux_lemFuel` and their three `_zero` lemmas —
  `get_ctx_lemFuel`, `are_compatible_lemFuel`, `are_compatible_params_lemFuel`
  keep their heads) + **41 caller heads**: AilTypesAux 7, Cabs_to_ail_aux
  1, Cabs_to_ail_effect 3, Cabs_to_ail 1, Core_reduction 1 (`one_step0`),
  Ctype_aux 6 (three workers + three `_zero` lemmas), GenTypesAux 4,
  GenTyping 17, Mini_pipeline 1 — name for name the manifest §2 list.
  Then with `[LemFuel]` stripped and whitespace squeezed on both sides, the
  head diff restricted to non-own-family names is EMPTY: every caller head
  changes ONLY by dropping the binder. (The record §4 / commit 2/n's "53
  caller heads" is a derived-tally slip — 59 − 6 — for what is 41 callers
  + 12 further own-family heads; the manifest's list is right: N7.)

## 6. F-C3-4 — the measured wrapper's eager measure on `get_ctx`

Mechanism, read from the sources: `step_ctx` (`core_reduction.lem:1489`,
`… end) (get_ctx th_st.arena)`) calls `get_ctx` on the thread's whole
arena once per driver step (every `Core_reduction.step_ctx` call in
`driver.lem` is one step). The C3 wrapper is `get_ctx g := get_ctx_lemFuel
(generic_expr.lemSize g + 1) g`; `generic_expr.lemSize` is a full
structural traversal of `g` — Θ(|arena|) per step, evaluated eagerly
before the walk. `get_ctx` itself descends only the redex path (each arm
recurses into ONE child, or maps over the `Eunseq` operands after an
O(|es|) `List.all es is_irreducible`; `is_irreducible` is a constant-depth
pattern match), i.e. O(depth + Σ operand-list lengths along the path). At
C2 the wrapper passed the ambient constant — no traversal. So the added
cost is exactly one size traversal per step: **O(steps × |arena|)** total,
a constant-factor change where the step already substitutes into the
continuation (`Esseq`/`Elet` rest-of-arena, O(|rest|)), and a new linear
term where it did not. The record's +7 % CPU on one arena-heavy csmith
row is the expected magnitude class; memory unchanged is expected (the
size is a `Nat`, no allocation retained).

Timeout class: the gcc lane's `TIMEOUT_SECS=30` (`test_gcc_oracle.sh:130`)
against the record's hand-timed 17.2 s → 18.4 s on the slowest row: the
class does not change; the headroom on that row shrinks from ~12.8 s to
~11.6 s, so the lane's documented load caveat (LADDER.md row 7) is
slightly more likely to fire under load — the record's B7 first run under
load ~39 is that caveat, and its quiet-box re-run (`compared=1885 …
disagree=0` / `Baseline check: 0 regression(s)`) and the orchestrator's
run (§7) are the evidence it is not a regression. The A/B was not
reproduced here: the record's scratch C2 package (`.tmp/c3/c2pkg`) is
gone with the slice's ephemeral dir and rebuilding a C2 tree + binary is a
full Lean build (N3).

Statement honesty: the finding names one row, gives six interleaved runs
with CPU times, states the load at the time (48.88) and why CPU time is
the robust column, labels the mean as derived, and says "one row". Fair.
The mechanism paragraph is correct (above). Decision options: (a) accept,
(b) a cheaper sufficient measure (with the honest caveat that a depth
measure is O(|arena|) too unless memoized), (c) a lazy measure lem-side.
Memoization appears only as a clause inside (b); and one route is absent
— see M1 (§9).

## 7. Gates and lanes after the battery (verbatim)

### 7.1 The orchestrator's battery (`.tmp/c3-reverify.log`, read only)

Head lines:

```
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen e48450a7c3ef435844a6de36180fa1a473126c3bf0a5a8a1e1f23b0bea740218)
check_driver_fresh: oracle OK (bin 28fb21989deaf0c1d09978620a9cc5769195c6d34244d55872a73bdac4e4cfc3, src 7f1a0c0afb84d4a2bac8e240197ae9d72d194985237aeb35ae16afa5cce912bf)
check_driver_fresh: lean OK (bin fbd8e397944f350b4024507ea888735db18dd7ab3daeec86e554d47ec89d557c, src caa6f8b8d0bd9839d68682acd6b28b9963a85919dc2ecc2b5fb25d7e060c6bc4)
```

— the Lean `gen` stamp and the Lean driver binary hash are the record's
(§4 there: `gen e48450a7…`, `bin fbd8e397…`): the Lean build is
bit-reproducible on this head. The oracle `bin` differs from the record's
(`32743705…` there, `28fb2198…` here) at the same `src 7f1a0c0a…` — the
known non-reproducibility of the cache-disabled OCaml relink (C2 audit N5,
C1 record §2.5); not a finding.

The battery's `=== DONE` at 05:47; 25 lanes serially, `--- rc=` per lane
in the log. Verbatim verdict lines (my `awk` over the log; the lane name
is the log's `===` line):

| Lane (log) | rc | Verbatim |
|---|---|---|
| `test_unit.sh` | 0 | (gate lines identical to §7.2's re-run) |
| `test_exec.sh --check-baseline` | 0 | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| `test_exec.sh … tests/coverage` | 0 | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `BASELINE OK` |
| `test_exec.sh … tests/debug` | 0 | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `BASELINE OK` |
| `test_exec.sh … tests/float` | 0 | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `BASELINE OK` |
| `test_bytes.sh` | 0 | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| `test_libc_exec.sh` | 0 | `SUMMARY: match=11 diff=0` / `ALL MATCH RECORDED BASELINE` |
| `test_multi_tu.sh` | 0 | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| `test_parse.sh` | 0 | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| `test_core.sh` | 0 | `Total:          106` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| `test_elab.sh` | 0 | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` |
| `test_libxml2_uri.sh` | 0 | `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| `test_cn_coverage.sh --check-baseline` | 0 | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |
| `test_parse.sh tests/ci` | 0 | `ALL PASSED` |
| `test_core.sh tests/ci` | 0 | `Total:          250` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| `test_verify.sh` | 0 | `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)` |
| `test_immaculate.sh` | 0 | `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).` |
| `test_speclab.sh --selftest` | 0 | `test_speclab: PASS (both pipelines agree on Specified(0))` |
| `test_speclab.sh --plant` | 0 | `test_speclab: PASS (both pipelines agree on Specified(2))` |
| `test_hang_plant.sh` | 0 | `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)` |
| `test_kill_plant.sh` | 0 | `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)` |
| `test_fuel_plant.sh` | 0 | `test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)` |
| `test_libxml2.sh` | 0 | `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED` |
| `test_gcc_oracle.sh --check-baseline` | **1** | `SUMMARY: total=1963 compared=1884 agree=1872 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=12 skip_ub=47 triaged_addr=11 triaged_ub=1` / `REGRESSION: csmith/sia_csmith_477.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-` / `Baseline check: 1 regression(s), 0 improvement(s)` |

**B7 as run is in LADDER.md row 7's load-caveat class, not a red**: the
only movement is one row AGREE → `SKIP_LEAN_TIMEOUT` (`compared` 1885 →
1884, `skip_lean_timeout` 11 → 12, `disagree=0`), and the box was loaded
during the lane — the log's `uptime` before the lane read `load average:
2.98, 3.13, 5.77` (05:24); my `uptime` at 05:46, mid-lane, read `load
average: 32.98, 27.30, 17.16`, with `ps` showing another agent's `golean`
at 98 % CPU alongside the lane's `cerberus-lean` at 200 %. The ladder's
rule is a quiet-box re-run before the lane is read either way; that re-run
is OWED and was not done here (24 min, outside my brief's lane list): M2.
The row differs from the record's first-run row (`sa_csmith_85.c`) — two
different slow csmith rows have now crossed 30 s wall under load on this
head; see §6 on the headroom.

The orchestrator's battery did not include the five speclab `--gate`
lanes (B6c–B6g, `test_speclab_{divmod,bytearr,list,tree,seed}.sh --gate`)
that the record §6.2 ran (`rc=0` there); not re-run here either (N8).

### 7.2 Lanes re-run by the auditor (worker worktree, serial, after `=== DONE`)

All three `SKIP_BUILD=1`, `CERB_MEM_MAX=16G`, `ulimit -c 0`, via
`scripts/ce`, one after another, starting 05:48 (load 11.9 falling to
3.7); logs in this worktree's git-ignored `.tmp/audit-test_*.log`.

`./scripts/test_unit.sh` → `rc=0`. The gate lines, verbatim:

```
check_handwritten_sync: OK (35 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
✓ totality-proof-test PASSED
Total: 6 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (282 files scanned comment-stripped — generated 205, hand-written+test 42, LemLib 35; 0 sorry tokens)
gen_fuel_parametricity: OK (23 ambient fuel wrappers in the generated tree = the 23 pins of TotalityProofTest.lean Part 1, both directions)
check_lakefile_roots: SELFTEST OK (3 plants red, baseline green)
check_lakefile_roots: OK (204 roots = 204 generated modules + the exe root Main; 85 auxiliary modules all built)
check_fuel_forms: SELFTEST — plants on a scratch copy of the classification table (loud plant banner; nothing in the tree is touched)
  PLANT OK   [P1 measured->ambient reachable (step_eval_pexpr)] -> check_fuel_forms: FAIL — fuel'd worker(s) REACHABLE from drive with an opaque (fail-open) exhaustion, not in /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/zero-discrepancy/scripts/fuel_forms_pending.txt:
  PLANT OK   [P2 stale pending pin (hack removed from the table)] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
  PLANT OK   [P3 measured obligation with sorryAx in its cone] -> check_fuel_forms: FAIL — measured obligation(s) with an axiom cone outside [propext, Classical.choice, Quot.sound] (or no proof constant):
  PLANT OK   [P4 truncated table] -> check_fuel_forms: FAIL — no FUEL_FORMS_SUMMARY line (the tool did not complete; fail-closed)
  PLANT OK   [P5 phantom register row] -> check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):
  PLANT OK   [P6 decoy obligation of type True (CerbMem.sizeofCtype)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …) — never MEASURED:
  PLANT OK   [P7 decoy obligation with the wrong worker constant (CerbMem.alignofCtype)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …) — never MEASURED:
check_fuel_forms: SELFTEST OK (7 plants red with the declared label — 5 on the table, 2 compiled decoy obligations; unplanted table green)
check_fuel_forms: forms partition OK (47 MEASURED + 13 ABSORBING + 15 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 47 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 15 reachable-AMBIENT = the 15 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
```

(plus the 20 `check_no_fuel_numerals` plants `PLANT OK`, the classifier's
18 fixtures, `check_exec_purity`/`check_exec_totality` CLEAN, the two
`check_lem_sync` OK lines, fork-drift, fixture-freeze, renumber plants —
all as the record §5 quotes them.) The gate can go red: the fuel-forms
selftest's P1–P7 and the roots selftest's three plants all red with their
labels on this head; P2/P5 are exactly the "register row removed without
its theorem" / "phantom row" directions.

`./scripts/test_verify.sh` → `rc=0`, verbatim:

```
check_driver_fresh: lean OK (bin fbd8e397944f350b4024507ea888735db18dd7ab3daeec86e554d47ec89d557c, src caa6f8b8d0bd9839d68682acd6b28b9963a85919dc2ecc2b5fb25d7e060c6bc4)
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
```

`./scripts/test_immaculate.sh` → `rc=0`, verbatim:

```
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

### 7.3 Axiom-cone probe

A scratch file in this worktree's `.tmp/` (`import Core_reduction_auxiliary`,
`import AilTypesAux_auxiliary`; twelve `#print axioms`; four `example … :=
rfl` for wrapper = worker-at-measure), run against the worker's built tree
with `../scripts/capped lake env lean <file>` (`CERB_MEM_MAX=16G`). Output,
verbatim (line-wrapped by Lean):

```
'one_step_unseq_aux_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'get_ctx_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'get_ctx_unseq_aux_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'are_compatible_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'are_compatible_params_aux_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'are_compatible_params_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Core_reduction_lemMeasureProofs.one_step_unseq_aux_measure_sufficient' depends on axioms: [propext,
 Classical.choice,
 Quot.sound]
'Core_reduction_lemMeasureProofs.get_ctx_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'Core_reduction_lemMeasureProofs.get_ctx_unseq_aux_measure_sufficient' depends on axioms: [propext,
 Classical.choice,
 Quot.sound]
'AilTypesAux_lemMeasureProofs.are_compatible_measure_sufficient' depends on axioms: [propext,
 Classical.choice,
 Quot.sound]
'AilTypesAux_lemMeasureProofs.are_compatible_params_aux_measure_sufficient' depends on axioms: [propext,
 Classical.choice,
 Quot.sound]
'AilTypesAux_lemMeasureProofs.are_compatible_params_measure_sufficient' depends on axioms: [propext,
 Classical.choice,
 Quot.sound]
```

— 12 of 12 within the standard three; the four `rfl` examples
(`one_step_unseq_aux p l = one_step_unseq_aux_lemFuel (List.length l + 1) p l`,
`get_ctx g = get_ctx_lemFuel (generic_expr.lemSize g + 1) g`,
`are_compatible p p0 = are_compatible_lemFuel (ctype.lemSize p.2 + ctype.lemSize p0.2 + 1) p p0`,
`are_compatible_params ps1 ps2 = are_compatible_params_lemFuel (ctype_.lemSize_aux1 ps1 + ctype_.lemSize_aux1 ps2 + 2) ps1 ps2`)
elaborated with no diagnostic.

## 8. Commit discipline

Commit 1/n: pin files only; its message's verification claims (regeneration
+ byte-identity + Tier A rows 2–11) are things a pin-only tree can run, and
the record §6.1 carries their lines. Commit 2/n: declares + proofs + manifest
+ lakefile root + register + pins in ONE commit — the record §9 explains why
(the gate is red both ways on a split: stale register pins / stale
parametricity pins), which is the C2 audit's F-C2-8 lesson applied
correctly; its message quotes the head's `check_fuel_forms` line, which
matches the orchestrator's run. Commit 3/n: docs only (`VALIDATION.md`
counts 41 → 47 / 21 → 15, `TODO.md` row struck through with the record
pointer, record, manifest). No red commit in the range.

## 9. Findings

No MAJOR.

**MINOR**

- **M1 — F-C3-4's decision list omits the route the arc built for exactly
  this case.** §8.4 offers accept / cheaper measure / lazy measure. Two
  options are missing or folded: (i) **`structural`** — with `lemTail`
  hoisted, `get_ctx`/`get_ctx_unseq_aux` is a mutual recursion whose every
  hop is on a strict subterm (a child expression, or the `Eunseq` operand
  list and its elements/tail); the arc-3 comment in `core_reduction.lem`
  (~line 1499) records `termination_argument automatic` as REJECTED for
  this pair ("genuinely mutual pair over expr/list with an accumulator"),
  but the D2 `structural` declare and the hoist change the premise (the
  list is now a named parameter); if lem's structural analysis accepts the
  nested `expr`/`List expr` block, the fuel counter — and the eager
  measure — disappear entirely (no runtime cost, and a stronger artifact
  for the consumer). It may still be refused (Lean's structural recursion
  over the nested inductive is the risk); the point is that it is the
  first thing to try, not an absent option. (ii) **memoized/cached size**
  is mentioned only as a clause inside (b); the manifest tells the
  consumer a `decide`/`rfl` over a large arena pays the traversal too, so
  the option deserves its own line. Fix: docs-only — add the two options
  to §8.4 (or record why (i) was already excluded). Grade MINOR because the
  decision is the operator's and an incomplete option list steers it.
- **M2 — B7 is not green as run in the orchestrator's battery; a quiet-box
  re-run is owed before the merge ask.** §7.1: `rc=1`, one row
  `csmith/sia_csmith_477.c` AGREE → `SKIP_LEAN_TIMEOUT`, `disagree=0`,
  under load 33 from another agent's processes. This is LADDER row 7's
  caveat class by its own definition, so it is not read as red — but it
  is not read as green either until the re-run prescribed there is done
  and its `rc=0` recorded (the record's §6.2 did exactly this for its own
  first run). It is also the second distinct slow csmith row to cross the
  30 s wall clock under load on this head (the record's was
  `sa_csmith_85.c`), which is the F-C3-4 headroom question in the wild
  (§6): the merge is not blocked by it, but §8.4 should be decided with
  this observation in front of the operator. Fix: re-run
  `./scripts/test_gcc_oracle.sh --check-baseline` on a quiet box, quote
  its `rc` and summary line in the record §6 (or the orchestrator's
  boundary review), no code change.

**NOTE**

- **N1 — the `.lem` diff is six declares plus two 9-line comment blocks**,
  not "six declare lines only"; the comments are non-semantic on every
  target and the OCaml `gen` stamp is unchanged. Recorded for precision.
- **N2 — the 59-head enumeration is not independently reproducible from
  what is on disk**: the C2 generated tree is ephemeral (the primary
  checkout's `generated/` is at a pre-C2 stamp `d1931404…`). Reproduced
  instead: 251 / 23 / 47 counts and 13 spot-checked heads (§5). Same class
  as C2 audit N1; a committed `gen` stamp per record (already the case,
  `76d138a3…` → `e48450a7…`) is the durable comparand.
- **N3 — the +7 % A/B has one data point (one row, one box, six runs)**
  and its comparand binary no longer exists. The record says so; the
  mem-scale/timing lane over the csmith tier is the right instrument if
  the operator wants the number before deciding §8.4.
- **N4 — sentinel declares coexist with the measure declares** for all
  six (the `fuel val … = fuelExhausted …` lines stay). This is the design
  (the worker's exhaustion arm still needs a payload; tails record §7
  decision 5) and the obligation proves the arm unreachable at ≥ μ; noted
  so a reader does not take the pair for a leftover.
- **N5 — the record's claim that the renderer refuses `lemSize p.2`**
  (§3.1) was not re-tested (it is a statement about lem's FM-free rule; the
  qualified form written is the one the fuel-measure record §2.1 documents).
- **N6 — the gate's MEASURED count (47) includes 3 hand-written `CerbMem`
  rows lem never sees**, so "41 measured at C2 ⇒ 41 hoist candidates" would
  be the wrong count for the §2 reasoning; the right one is the 38
  `fuel_measure` declares (+ 0 `structural`), which is what was enumerated.
- **N7 — "53 caller heads" is a derived-tally slip; the number is 41.**
  Record §4 ("every one of the 53 caller heads only drops `[LemFuel]`") and
  commit 2/n's message ("the six + 53 callers") compute 59 − 6; the 59
  changed heads are 18 own-family (6 wrappers + 6 obligations + 3 hoisted
  workers + 3 `_zero` lemmas) + 41 callers (§5, reproduced from the
  regenerated trees). The consumer-facing manifest §2 lists the 41 by name
  and is correct; the record's claim about them (binder-drop only) is TRUE
  of all 41 — only the count is wrong. Fix the two numbers (docs).
- **N8 — the orchestrator's battery omitted the five speclab `--gate`
  lanes** (B6c–B6g) that the record's §6.2 ran green; the gate lanes build
  the `speclab` package (its manifest is one of the three pinned). Not
  re-run here; for the boundary review to note or run.
- **N9 — the oracle binary hash moves between cache-disabled relinks**
  (`32743705…` record / `28fb2198…` orchestrator, same `src`), as C2 audit
  N5 already recorded; the Lean binary (`fbd8e397…`) is bit-reproducible.
  Not a C3 finding.

## 10. Not checked

- The old lem `ecf75b4` was not rebuilt; the pin-bump Lean identity rests
  on the content-hash equality of §2 (new lem on C2 sources = the C2
  head's recorded stamp) plus the rule-trigger enumeration.
- The record's `diff -rq` runs (`OCAML … files=86`, `LEAN … files=204`)
  were not re-run as such; the lem-sync `gen` stamps and my regenerated
  trees are the equivalents used.
- The F-C3-4 A/B (N3); the owed B7 quiet-box re-run (M2); the speclab
  `--gate` lanes (N8).
- The lem side of the pin (`d4ba548`): the tails record's gates and its
  pre-merge audit were read, not re-run.
- Tier A/B lanes other than `test_unit.sh` / `test_verify.sh` /
  `test_immaculate.sh` were taken from the orchestrator's battery log
  (§7.1), not re-run.
- The six proofs' tactic scripts were read for shape, binders, forbidden
  tokens and the `key` side conditions, and the hop arithmetic re-derived
  by hand (§3.2); the kernel check is the build (the auxiliary applies
  each constant at the exact stated type) and the `#print axioms` probe.
- refined-cerberus's consumption of the manifest (theirs).

## 11. Provenance

[AGENT] (this auditor): every reading, derivation, probe, tally and grade
above. [USER 2026-09-04] "we don't change the lem structure for ocaml",
[USER 2026-09-03] no magic values / zero Lean-vs-OCaml discrepancies /
"profile before optimizing", as relayed in the brief and the record §1,
were the grading frame; no ruling was made or altered here. Nothing
merged, nothing pushed; the worker's worktree was not edited — the three
lanes and the probe ran there read-only on its built tree (`SKIP_BUILD=1`;
the lanes write only their own scratch). In THIS audit worktree the two
regenerated trees (`.tmp/gen-c2`, `.tmp/gen-c3`), the lane logs and the
probe file live in the git-ignored `.tmp/` and are ephemeral;
`frontend/model` was checked out at `a910f097c` for the C2 regeneration
and restored to `d127cfa9b` (the tree is clean apart from this document).
The orchestrator's battery log `.tmp/c3-reverify.log` (container-level,
ephemeral) was read, never written; its load-bearing lines are quoted
above verbatim.
