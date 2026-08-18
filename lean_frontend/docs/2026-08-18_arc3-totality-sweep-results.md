# Arc 3 results: the execution slice is total

Companion to the charter (`2026-08-18_arc3-totality-sweep-charter.md`), the
decision log (`2026-08-18_arc3-decision-log.md`), and the lem-side design
note (lem-lean `doc/notes/2026-08-18_arc3-totality-mechanisms.md`).

## Headline

`check_exec_totality: CLEAN (11 modules, 0 allowlisted)` — ENFORCING in
`test_unit.sh`. Every definition in the execution slice is a total `def`;
the allowlist is EMPTY (charter target was ≤5, hard cap 10). 96 formerly
`partial` definitions were totalized; the 97th census entry
(`easy_update_mem_value_aux`) is a sorry-target_rep'd def whose generated
body sits inside a block comment — excluded by the (comment-aware) gate
and recorded as pre-existing C-tier debt.

## Census → disposition (97 defs)

| disposition | count | note |
|---|---|---|
| structural/WF flip (`termination_argument = automatic`) | 39 | incl. two mutual structural pairs |
| de-mutualized to plain defs (backend, no declare needed) | ~11 | DAG rec-and members that were never recursive |
| fuel (`fuel val` + witness sentinel) | 45 | incl. 3 fuel'd mutual families (B2) and the reader-lifted spine (B1) |
| soft sentinel | 1 | `simplify_integer_value_base` returns its input unsimplified |
| excluded (block-commented sorry stub) | 1 | `easy_update_mem_value_aux` |

Fuel-vs-flip is decided by Lean's checker, not by hand: `automatic` was
attempted first everywhere plausible; the recurring beyond-automatic shapes
(pair-list nesting, point-free HOF self-reference, rewritten-term
recursion, Bool-guarded Nat subtraction, stored-function application) are
recorded in the decision log (D6) with the probe evidence.

## Lem-side mechanisms added (all probe-first, `tests/comprehensive/`)

1. fuel × reader composition (worker binder order: fuel, readers, args).
2. fuel × mutual (block-level worker plan, all-or-none, wrappers after
   `end`); fuel'd-mutual × reader stays fail-closed.
3. `LemLib.fuelExhausted[With]` witness-based opaque panic sentinels (no
   [Inhabited] propagation, clean cones, honest-loud at runtime).
4. Acyclic de-mutualization of rec-and blocks (stable topo order,
   per-member keywords).
5. Fixes surfaced by the sweep: fuel wrapper re-emits class-constraint
   binders; fuel worker's succ-arm body parenthesized.
Negative-test lane added: `tests/comprehensive/negative/` — rejects must
fail WITH the declared message (wired into `make lean`).

## Theorem surface (S3)

`test/Unit/TotalityProofTest.lean`, in the unit gate:
- 52 wrapper-defeq examples — one per fuel'd def: the point-free wrapper
  is definitionally the worker at `lemDefaultFuel`.
- 8 symbolic execution theorems over the newly-total slice (pattern
  matching wildcard/binder, conversion erasure, substitution-on-values,
  ccall analysis via worker AND wrapper, pattern occurrence, env lookup)
  — all `rfl`, all impossible over `partial def`s.
Axiom gate exemplars grew by four CLEAN new cones: `match_pattern`,
`convert_pexpr`, `nd_bind`, `subst_sym_pexpr`.

## Newly visible debt (recorded, deliberately NOT gated this arc)

Totality makes cones inspectable for the first time:
- `step_eval_pexpr`: DAEMON in cone (legacy failwith at type-variable
  sites; generated-instance fallbacks — the known C-tier debt).
- `driver2`: DAEMON + sorryAx (via the sorry-target_rep'd
  `easy_update_mem_value_aux` and BEq sorry stubs in Ctype).
Next-arc candidates: eliminate sorry stubs from the driver cone, then
extend the clean-cone exemplar list downward into the spine.

## Behavior notes

- OCaml artifact: untouched by construction — every model edit is a
  `declare {lean}` line (lean-target only); OCaml prelude regen + dune
  build + suites verified green per batch. The .lem files still parse
  with the pre-arc lem (d25f982): arc 3 added no new declare grammar.
- Runtime: `lemDefaultFuel = 1000000` per fuel'd function (not global);
  `test_core.sh` stayed at the 104/105 baseline throughout — no
  fuel-exhaustion regressions. Fuel exhaustion is honest-loud (opaque
  panic) except the one soft sentinel noted above.
