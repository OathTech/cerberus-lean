# Concurrency Phase 0 — slice S5 record: the reasoning surface (2026-09-05)

Charter: `2026-09-04_concurrency-phase0-sc-charter.md` §4.7 / §6 row S5
(APPROVED [USER 2026-09-04]; "okay, can we go ahead?" [USER 2026-09-05]
after the S4 report listed this slice's content). Branch
`feature/concurrency` on mainline `a910f097c`; S4 head `9b1b3ff6d`. Author
[AGENT]. Gate: FULL.

## 0. What landed (charter §4.7, item by item)

1. **`using_concurrency` deleted** (global.lem `val` + its three
   target_reps; `CerbGlobal.lean` `using_concurrency_impl` + the opaque +
   the never-set `concurrency` config field; the two
   `unsafebaseio_allowlist.txt` pins; the `OPAQUE_WANT` entry of
   `check_theorem_axioms.sh`). Measured first: zero readers on any target
   (the model is threaded from `drive` since S1; the OCaml backend keeps
   `Cerb_global.concurrency_mode` for its own conf). The opaque census
   shrinks by one; the boundary-opaque expectation list says why.
2. **`CerbConcurrency.lean` (`statically_satisfied := true`) DELETED with
   its declare.** Measured: `statically_satisfied` is referenced only by
   `{hol; isabelle; tex}` theorems (cmm_csem.lem §16 meta-theory) — the SC
   path never reaches it; no emitted Lean mentions it. Copy manifest and
   lakefile root removed; `check_handwritten_sync` at 33 files.
3. **The 23 `sorry` target_reps** (cmm_csem.lem's `observable_filter`,
   `behaviour`, `rf_behaviour`, the 19 per-model `*_behaviour`, the `_fp`
   pair, `overlap_behaviour`): all have `{hol; isabelle; tex}` bodies only,
   and NO Lean-emitted code referenced them (grep of the generated tree:
   0 for every name; the one textual hit is inside a lem comment). The
   declares were dead text — REMOVED; the vals are now excluded from the
   Lean target exactly as they are from OCaml (which emits the commented
   signature). One live inline referenced one of them for the Lean target
   (`cmm_op.lem:49` `axBehaviour = standard_behaviour`, `~{ocaml}`): it
   joins the file's own `~{ocaml;lean}` exclusion idiom (used at :115,
   :150, :154, :282 by the original porters). No lem change was needed —
   the charter's "whichever the backend supports today".
4. **The Cmm modules join the totality slice** (`check_exec_totality.sh`
   EXEC_MODULES + `Cmm_aux Cmm_csem Cmm_op`) at ZERO partials: the two
   `apply_tree` partials are totalized (§2). Linux.lean (not on the SC
   path) already had zero partials; not added (charter names the Cmm
   modules). The 75 `failwithI` residuals of Cmm_csem stay: none is
   reached on the litmus corpus (the lane would report the internal error).
5. **DESIGN.md §4 "The concurrency model is a parameter"**: the selector,
   both instances, the bridge and the DRF-SC citation, sb = execution
   order, and the §4.6 boundary entry (value at issue; mover Phase 1).
   **VALIDATION.md**: the litmus lane row in §2; §5 claim 5 (the SC
   instance is a checked member of the model family — sampled, with the
   theorem targets named, not claimed); the model-boundary passage
   corrected (the concurrency model is a parameter, not a boundary; the
   stub is gone). **README.md**: the capability bullet and the headline
   number.
6. **Upstream tray drafts 20–22** (+ INDEX): the `_Atomic` qualifier form
   (§3 — the S0/S4 finding NARROWED by a six-shape sweep), the driver's
   duplicate blocked-step branching, `--concurrency` broken upstream with
   the fork's instance offered as the restoration.

## 1. FINDING: two of the charter's totalization routes do not exist for this shape

`apply_tree` (cmm_csem.lem:560) recurses through `List.all (fun (name,
branch) -> apply_tree branch X) l` on the nested inductive
`named_predicate_tree = Leaf of (candidate_execution -> bool) | Node of
list (string * named_predicate_tree)`. Charter §4.7: "`declare {lean}
termination_argument … = automatic` if the backend accepts it, else the
fuel mechanism". The backend accepts the declare (it emits a plain `def`)
and Lean rejects the result; verbatim from the first S5 build
(`.tmp/lake-s5.log`, deleted at slice end — this is its record):

```
error: Lean exited with code 1
Some required targets logged failures:
- Cmm_csem
```

Reproduced in a standalone three-shape file (`.tmp/term/shapes.lean`, same
type shape), verbatim:

```
shapes.lean:6:4: error: fail to show termination for
  applyA
with errors
failed to infer structural recursion:
Not considering parameter X of applyA:
  it is unchanged in the recursive calls
Cannot use parameter t:
  failed to eliminate recursive application
    applyA branch X

failed to prove termination, possible solutions:
  - Use `have`-expressions to prove the remaining goals
  - Use `termination_by` to specify a different well-founded relation
  - Use `decreasing_by` to specify your own tactic for discharging this kind of goal
l : List (String × T)
branch : T
⊢ sizeOf branch < 1 + sizeOf l
shapes.lean:24:0: error: failed to infer structural recursion:
Cannot use parameter t:
  failed to eliminate recursive application
    applyC branch X
```

Shape A = lem's `automatic` emission (well-founded recursion loses the
list membership because the lambda destructures the pair by `match`);
shape C = `termination_by structural` (structural recursion cannot pass
through the higher-order `List.all`); shape B — MUTUAL structural
recursion with an explicit list walker (`apply_tree_list`) — compiled
with no clause at all.

Decision [AGENT]: restate the pair in the shared `.lem` as shape B
(`apply_tree`/`apply_tree_list`, `apply_tree_fp_aux`/`apply_tree_fp_aux_
list`), NOT the fuel mechanism. Reasons: (i) `List.all` IS the
left-to-right short-circuit conjunction the walker spells out — the
function is unchanged, on every target, by inspection (the OCaml diff is
`List.for_all (fun (name1, branch) -> apply_tree branch x0) l` →
`apply_tree_list l x0` with the walker beside it); (ii) structural
recursion is the reasoning-friendliest form (a consumer unfolds it; the
fuel form would add a stability obligation and a fuel'd definition to the
reasoning surface for no gain — the reasoning-artifact lens, [USER
2026-09-03]); (iii) the charter's own preference order puts structural
first and reaches for fuel only when structural is unavailable — it is
available in this form. The fork-drift pin for cmm_csem.ml moves with an
[expected-semantic] NOTE (text change, behaviour-equal); both engines run
the restated functions in every SC bridge check of the litmus lane.

## 2. Measurements behind the deletions (verbatim greps, this worktree)

```
using_concurrency (non-generated, non-docs): global.lem:38-41 (the val + 3 declares), CerbGlobal.lean:96,133-134, unsafebaseio_allowlist.txt:124,142, check_theorem_axioms.sh:213, core_run_aux.lem:29 (comment); backend/ util/: none
generated Lean refs of the 24 meta-theory names: observable_filter 0, behaviour 2 (both inside a lem comment, Cmm_csem.lean:2162/2189), rf_observable_filter 0, rf_behaviour 0, single_thread_behaviour 0, … standard_behaviour 0 … overlap_behaviour 0, statically_satisfied 0 (outside its own stub)
Cmm partials before: Cmm_csem.lean:792 apply_tree, :2392 apply_tree_fp_aux (2); after: 0 / 0 / 0 (Cmm_aux, Cmm_op, Cmm_csem); Linux.lean 0
failwithI residuals: Cmm_aux 0, Cmm_op 1, Cmm_csem 75 (unchanged)
```

## 3. FINDING (tray 20): the `_Atomic` qualifier finding, narrowed

S0 recorded "`_Atomic int x` is rejected by the front end". A six-shape
oracle sweep (this slice) shows it is two specific positions, and the
S0/S4 wording was too broad. Verbatim verdicts (`--nolibc --exec --batch`):

```
_Atomic int x;  (file scope)                    Defined {value: "Specified(1)", …}
_Atomic int x = 0;  (file scope)                Defined {value: "Specified(1)", …}
static _Atomic int x;                           Defined {value: "Specified(1)", …}
int _Atomic x;  (file scope, postfix)           Defined {value: "Specified(1)", …}
int main(void){ _Atomic int x; … }              Defined {value: "Specified(1)", …}
int main(void){ _Atomic int x = 0; … }          error: constraint violation: address argument to atomic operation must be a pointer to _Atomic type ('signed int' invalid)
int f(_Atomic int *p){ … }                      error: constraint violation: address argument to atomic operation must be a pointer to _Atomic type ('signed int' invalid)
```

`--pp=ail`: `signed int x = 0;` (block scope + initializer: qualifier
DROPPED — `desugar_declaration_base` :3540-3553 registers the un-wrapped
type via the self-labelled `desugar_init_declarator_BROKEN`) and
`signed int f(_Atomic(signed int*) p)` (parameter: qualifier applied to
the declarator's result, :2168/:2189). Both engines, by generation. The
litmus corpus's specifier-form respelling was the right workaround; the
README/S0/S4 texts are not rewritten (records), the tray draft and this
section carry the precise shape.

## 4. NOT done, recorded as the consumer's theorem targets ([AGENT] scoping, within the charter)

The S3/S4 commit messages queued two theorems for S5 that the charter's
§4.7 does not list; the S4 report flagged them as trimmable and the
operator said "go ahead" on the list as given. They are NOT attempted
here; statements for the consumer:

- **Agreement.** For every Core file `f` with `epar_free f = true` (no
  `par`), `drive tds CM_sequential f args` and `drive tds CM_sc f args`
  yield the same verdict set. Sketch: with one thread `can_advance`
  agrees, every sb/asw walker and annotation is the identity on the
  verdict (they touch annotations the sequential verdict never reads), the
  recording is dead state, and the tail's `data_races` is empty for a
  single thread (no cross-thread pair) while `sc_failing_leaves` is empty
  because a single-thread execution with rf = the last write is SC-
  consistent. The last two are the substance — a consistency theorem for
  single-thread candidate executions over cmm_csem's tree — and the whole
  statement is a proof over the ND trace monad: reasoning-era-scale, not a
  Phase-0 slice (the grind ban applies; the cheap parts alone prove
  nothing a consumer needs).
- **The bridge invariant as a lemma.** Every race-free `CM_sc` trace's
  recorded candidate execution satisfies `sc_accesses_consistent_
  execution`. Today checked at RUNTIME per trace (S3), plant-tested.
- **`sc_fragment_ok_iff`.** `sc_fragment_ok f = true ↔ ` every action's
  memory orders are `seq_cst`/non-atomic and `f` has no fence, Linux
  action or `wait`. A definitional restatement of the scan; low value
  until a consumer states a rule over the fragment — theirs to request.

What IS theorem-shaped in this slice: the sequential identity facts as
lemmas in `test/Unit/SCBridgeTest.lean` (§5): the four walkers are the
identity under `CM_sequential`, by `rfl`/`simp` — the S3/S4 manifests'
"what is unchanged for a sequential statement" as statements, not prose.

## 5. Gates

The chain (`.tmp/chain9.sh`, serial, `CERB_MEM_MAX=32G`, every lean run
via `scripts/capped`; the scratch dir is deleted at slice end, this
section is its record). A first launch was aborted after 2 minutes: the
D14 token ban tripped on the WORD in the new lemmas' doc-comment
(`check_theorem_axioms: FAIL — D14 ban: native_decide/bv_decide found in
test/proof sources`) — the same trip as S4, reworded, the target rebuilt,
the chain relaunched from the start (07:02:39 UTC; box load 13).

**Tier A row 1 — `./scripts/test_unit.sh`**, rc 0, verbatim key lines:

```
✓ core-parser-test PASSED   (292 passed, 0 failed)
✓ pp-test PASSED
✓ fuel-exemplar-test PASSED
✓ effects-proof-test PASSED
✓ fresh-int-test PASSED
✓ totality-proof-test PASSED
✓ sc-bridge-test PASSED     (5 passed, 0 failed; the six SequentialIdentity theorems compile in this target)
Total: 7 passed, 0 failed
check_sorry_token: OK (278 files scanned comment-stripped — generated 203, hand-written+test 41, LemLib 34; 0 sorry tokens)
check_exec_totality: CLEAN (25 generated modules + hand-written CerbND, 0 allowlisted)
check_fuel_forms: OK (81 fuel'd workers: 41 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 21 reachable-AMBIENT = the 21 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_theorem_axioms: generated-tree census OK (203 files: 0 axioms, boundary-opaque population = the 25 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 33 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_handwritten_sync: OK (33 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: OK (src 13981c2d33a9a3705ebe835a489368dd3d15148624322697c797e10da08fa8aa, gen 1570c4b8d3952aa0916727a52b58c649e7863f90c92e25aa5d778525b46f7a06)
check_lem_sync: lean OK (src 13981c2d33a9a3705ebe835a489368dd3d15148624322697c797e10da08fa8aa, gen 97c39b07181cb01157060fa3d7b55ede5331c320208897f531f3e5153e9b6f32)
check_fork_drift: OK — layer 1: 72 oracle-surface files = manifest; layer 2: 24 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
### LANE A1-test_unit rc=0 | end 07:04:52
```

Movement against S4, each explained: totality 22 → 25 modules (the Cmm
trio, 0 partials); boundary-opaque population 26 → 25 rows
(`using_concurrency` gone); hand-written copy set 34 → 33 files
(`CerbConcurrency.lean` gone); fork-drift 22 → 24 differing generated
files (lem_global.ml, cmm_csem.ml — both pinned with the S5 NOTE); the
`sorry`-token census at 0 as before (the 24 removed declares never
reached the Lean tree).

**Litmus lane**, verbatim (no row moves in S5; the restated tree walkers
run on both engines in every bridge check):

```
SUMMARY: mode=before programs=24 engine_disagreements=0 baseline_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT baseline
rc=0
SUMMARY: mode=check programs=24 engine_disagreements=0 target_mismatches=0 seq_leg_fail=0 red_classes=none
ALL ROWS AT target
rc=0
### litmus --plant
plant (a) corrupted row 'coherence+init+sc_sc.c': mismatches=1 (want >=1)
plant (b) empty corpus: failures=25 (want >=1)
PLANTS TRIPPED (lane is not vacuous)
rc=0
```

**The sequential battery (FULL gate):** Tier A rows 2–11 + Tier B rows
1–8, serial, 2026-09-05 07:09–08:02 UTC; box load at each lane's start in
the fourth column (other agents' work: 24 at the start, a spike to 70–72
during the libxml2 and gcc lanes, 6 between), verbatim per-lane return
codes:

| row | lane | start | load | rc / end |
|---|---|---|---|---|
| A2 | `test_exec minimal` | 07:09:00 | 23.80 | rc=0 07:09:13 |
| A3 | `test_exec coverage` | 07:09:13 | 20.61 | rc=0 07:09:37 |
| A4 | `test_exec debug` | 07:09:37 | 14.70 | rc=0 07:09:49 |
| A4b | `test_exec float` | 07:09:49 | 12.63 | rc=0 07:09:58 |
| A4c | `test_bytes` | 07:09:58 | 12.35 | rc=0 07:10:03 |
| A5 | `test_libc_exec` | 07:10:03 | 11.68 | rc=0 07:10:25 |
| A6 | `test_multi_tu` | 07:10:25 | 9.92 | rc=0 07:10:27 |
| A7 | `test_parse minimal` | 07:10:27 | 9.92 | rc=0 07:10:36 |
| A8 | `test_core minimal` | 07:10:36 | 9.16 | rc=0 07:10:45 |
| A9 | `test_elab` | 07:10:45 | 8.37 | rc=0 07:11:01 |
| A10 | `test_libxml2_uri` | 07:11:01 | 7.39 | rc=0 07:11:12 |
| A11 | `test_cn_coverage` | 07:11:12 | 7.08 | rc=0 07:11:40 |
| B1 | `test_libxml2` | 07:11:40 | 6.13 | rc=0 07:28:46 |
| B2 | `test_parse ci` | 07:28:46 | 11.11 | rc=0 07:29:11 |
| B3 | `test_core ci` | 07:29:11 | 9.60 | rc=0 07:29:27 |
| B4 | `test_verify` | 07:29:27 | 8.49 | rc=0 07:30:10 |
| B5 | `test_immaculate` | 07:30:10 | 7.70 | rc=0 07:31:04 |
| B6a | `speclab selftest` | 07:31:04 | 6.47 | rc=0 07:32:41 |
| B6b | `speclab plant` | 07:32:41 | 6.10 | rc=0 07:32:43 |
| B6 | `speclab divmod` | 07:32:43 | 6.02 | rc=0 07:32:49 |
| B6 | `speclab bytearr` | 07:32:49 | 5.93 | rc=0 07:32:54 |
| B6 | `speclab list` | 07:32:54 | 6.02 | rc=0 07:33:00 |
| B6 | `speclab tree` | 07:33:00 | 5.94 | rc=0 07:33:06 |
| B6 | `speclab seed` | 07:33:06 | 5.86 | rc=0 07:33:11 |
| B7 | `test_gcc_oracle` | 07:33:11 | 5.87 | rc=0 07:56:46 |
| B8a | `hang plant` | 07:56:46 | 10.91 | rc=0 07:56:59 |
| B8b | `kill plant` | 07:56:59 | 10.52 | rc=0 08:02:02 |
| B8c | `fuel plant` | 08:02:02 | 24.61 | rc=0 08:02:07 |

Every lane at rc 0 on the FIRST pass of the relaunched chain (29 of 29
incl. row 1). Verbatim tails:

```
SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0            (A9)
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)   (A10)
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)   (B4)
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK                                              (B7 — through the load-70 spike; no TIMEOUT-class movement)
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; …)     (B8b)
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; …)   (B8c)
```

ZERO movement on every sequential lane (charter E3): S5 deletes dead
declarations, restates two functions no sequential program reaches, and
extends gates.

## 5.1 Exit-criteria status after S5

E1 met (S4, re-confirmed above). E2 holds on the corpus (the bridge check
per trace; plant trips). E3 zero movement at every slice. E4: the totality
slice includes the Cmm modules at zero partials; axiom census zero; sorry
census zero; the opaque census reduced by `using_concurrency` with the
re-pin reason; NDguard/NDbranch unreachability is the standing FUEL/ND
plant surface (unchanged by this arc). E5: DESIGN/VALIDATION/README carry
the model section, F_SC, the §4.6 boundary entry and the DRF-SC citation;
per-slice manifests exist (the cumulative one and the consumer note are
S6); tray drafts 20–22 exist. E6: no `2>/dev/null` added, 0 `partial` in
the exec cone (now incl. Cmm), no heartbeat/maxRecDepth bumps, no
numerals as budgets; longest pass this slice: the 24-minute gcc lane.

## 6. Provenance

[USER 2026-09-04]: the charter (§4.7 the item list). [USER 2026-09-05]:
"okay, can we go ahead?" on the S5 list as reported. [AGENT]: the
totalization route (§1), the theorem scoping (§4), the tray drafts, the
sweep (§3); quoted blocks verbatim from this worktree.
