# csmith campaign findings — reproducer manifest (arc-10 S4)

Committed reproducer artifacts for the arc-10 S4 csmith campaign
(record: `lean_frontend/docs/2026-08-20_arc10-s4-csmith-campaign.md`,
which carries the verbatim evidence; this manifest is the artifact
index). NOT wired into any harness — these document findings, all of
which are ORACLE-side. Deterministic regeneration recipes are given
where the artifact is generated.

**ATTRIBUTION UPDATE (root-cause poking, 2026-08-21, [USER]-directed;
full evidence in the campaign record §root-cause):** the F-D family is
NOT upstream — the un-forked upstream cerberus (prototype checkout)
returns the correct gcc/Lean-agreeing values on every tested witness
(6000098→117, 6000018→100, sa_csmith_168→28). F-D is a cerberus-lean
FORK regression, prime suspect the arc-2 S1 threaded symbol supply
(core_run_aux.lem:233-247,287; its own invariant comment concedes the
undischarged non-escape obligation) via description-insensitive symbol
equality into the Esave/Erun machinery. F-A and F-B ARE upstream
(reproduced verbatim on upstream). F-E dissolves into (a) an
upstream-shared UB081 initializer class surfaced through two different
channels (deferred exec verdict vs hard cabs-json error — the channel
split is fork-side, cosmetic) and (b) a trivial stage difference
(cabs-json never runs translation, so F-A cannot fire there).

Running an artifact: `scripts/test_exec.sh tests/csmith_findings/oracle/<f>.c`
(files that `#include "csmith_cerberus.h"` need
`tests/csmith/{csmith_cerberus.h,safe_math.h}` copied next to them —
the creduce predicate and fuzz kit do this automatically).

## oracle/ — oracle-side defects (the OCaml reference implementation)

All verified at cerberus-lean `arc/robustness` (oracle built from this
tree). None is Lean-side; where noted the shared .lem model is
implicated (both sides fail identically → invisible to the
differential).

| file | finding | evidence (verbatim outputs in the campaign record) |
|---|---|---|
| `init_array_3d.c` | **F-A: Desugaring_init fails on a class of nested braced initializers.** 3-D scalar-array initializer → `internal error: Translation called on Ail program with an invalid node` (AilEinvalid via the cabs_to_ail.lem:3488-3505 catch). 2-D works. SHARED-MODEL: the Lean pipeline panics with the identical message. At csmith defaults (`--max-array-dim 3`) this killed ~52% of all generated programs (A0: 105/105 SKIP_INTERNAL correlated); the portfolio uses `--max-array-dim 2` | campaign record §skip-cause |
| `init_struct_depth3.c` | F-A struct flavor: struct-in-struct-in-struct braced initializer fails the same way (depth-2 nesting works; note the failure class is NOT simple depth — see F-E witness which is depth-4 and exec-accepted) | same |
| `init_addr_const.c` | **F-B: ISO-legal address-constant initializer rejected**: `static int *g_q = &g_arr[1][0].f3;` → `error: constraint violation: initializer element is not a compile-time constant` (C11 6.6p9 address constant; gcc accepts, native result correct). Same oracle-strictness family as the libxml2 probe #1 / wireguard edit-2 | campaign record §skip-cause |
| `cabsjson_vs_exec_init.c` | **F-E: `--cabs-json` vs `--exec` initializer-checker inconsistency, BOTH directions**: this file is exec-REJECTED (F-A class) but cabs-json-ACCEPTED; sweep seeds 1000011/1000042 (recipe below) are exec-ACCEPTED but cabs-json-rejected with `undefined behaviour: the initializer for a scalar shall be a single expression`. The two frontends disagree on which initializers are valid | campaign record §round-1 triage |
| `ub010_dead_object_reduced.c` | **F-D: exec-driver allocation-state corruption, declaration-layout-sensitive** (= the wireguard scoping survey's can_advance defect, the wireguard target-scoping note §2a addendum — PARKED, not restored: tag `park/reasoning-era-20260831`, `lean_frontend/docs/reasoning-era/2026-08-20_wireguard-target-scoping.md` — CROSS-REFERENCED, now csmith-forced with small deterministic repros). This artifact (creduce 750→242 lines, gcc-validity-guarded) makes the oracle report `UB010_pointer_to_dead_object` on a live object. **PLACEMENT-DEPENDENCE QUALIFIER (2026-08-21 audit correction):** the "+1 unused declaration → `internal error: can_advance: Step_error2 ==> ...`" morph fingerprint does NOT reproduce on THIS artifact — auditor B tested four `int __extra_decl(int);` placements (fork stays UB010 at each), consistent with the upstream-probe note's two placements (`lean_frontend/docs/2026-08-21_upstream-oracle-build.md` — flagged there as caveat (b): the fingerprint presumably needs the specific decl/placement used during reduction). The fingerprint sentence holds on OTHER witnesses (csmith_6000018/6000098, sa_csmith_168). The artifact remains **fork-vs-truth DISCRIMINATING**: upstream at the merge-base does not report UB010 (it runs on, observationally non-terminating exactly like native gcc), so the fork's 0.05 s UB verdict is the anomaly (same note). NOTE: replacing the `#include` by equivalent typedefs (a 1-declaration layout change) makes it pass — itself layout sensitivity. Reduction predicate: gcc `-std=c11 -S -O1 -Werror=return-type` valid AND oracle `--nolibc --exec --batch` output contains `UB010_pointer_to_dead_object` | campaign record §corpus-lane + `lean_frontend/docs/2026-08-21_upstream-oracle-build.md` |
| `csmith_6000018.c` | F-D witness (spurious UB): oracle `UB:UB_CERB002b_out_of_bound_store`, Lean+gcc `Specified(100)`; +1 decl → `can_advance: Step_error2 ==> Store`. Regen: csmith seed 6000018, lane-P5 flags | campaign record §round-1 triage |
| `csmith_6000098.c` | **F-D witness (SILENT VALUE CORRUPTION)**: oracle `Specified(187)`, +1 decl → `Specified(138)`; Lean+gcc stable at `Specified(117)`. The oracle's defined result is a function of top-level declaration count | same |
| `csmith_6000038.c` | F-D witness (value corruption + Lean perf note): oracle 2240 executions all `Specified(218)` (6.2s), +1 decl → 134; Lean 2240 all `Specified(13)` (= gcc; 86s — perf-gap registered) | same |

F-D family witnesses beyond these (all deterministic; campaign record
has the per-witness gcc/upstream/morph evidence):
- in-tree corpus (spurious-UB manifestation, plain files): small_arrays
  csmith_19/28/95/120/149/168/218/317/350/369/371 + csmith_190 (under
  a Lean perf-timeout); small_int_arith csmith_081/136/1168/897 —
  the 15 DIFF rows + 1 TIMEOUT row of
  scripts/exec_csmith_corpus_baseline.txt.
- generated (silent value corruption + spurious UB; regenerate with the
  lane flags in the campaign record): P1 seed 1000139, 1000299; P2
  2000129, 2000239, 2000287; P3 4000250; P4 5000125; P5 6000018,
  6000038, 6000098, 6000245.
- exploration seeds 3016022/3016044/3016049/3016051/3016058/3016074/
  3016082/3016099 (B1 flags): the internal-error manifestation
  (`can_advance: Step_error2 ==> Load/Store`).

Lane-P5 flag set (for the seed-regeneration recipes):
`--no-argc --no-bitfields --max-funcs 3 --max-block-depth 3
--max-block-size 4 --max-expr-complexity 3 --max-array-len-per-dim 8
--max-array-dim 2 --no-pointers` + the kit's csmith.h→csmith_cerberus.h
substitution (scripts/fuzz_csmith.sh with CSMITH_FLAGS, CSMITH_SEED_START
= seed-1).

## Lean-side findings

Round 1 of the generated lanes (500 programs, 5 lanes) plus the
in-tree-corpus lane produced ZERO Lean-side semantic defects (register
finding 8 — eqPtrval msum provenance fork — was found by the S0
shakedown and FIXED before the sweep, commit bdb9f1967; the sweep
re-confirms it closed). Lean-side perf-gaps (TIMEOUT_LEAN_PERF bucket)
are registered in the campaign record, not defects. Later-round
findings, if any, are appended here.

## ARC-12 STATUS UPDATE (2026-08-21): F-D REPAIRED — FAIL-STOP; attribution corrected

**Repair.** The F-D family is now IMPOSSIBLE-SILENTLY on the fork
oracle: the arc-12 fail-stop floor (util/cerb_fresh.ml two-check
per-TU dynamic floor + backend/common/ail_sym_hwm.ml desugar
high-water fold; design `lean_frontend/docs/
2026-08-21_arc12-s0-floor-design.md`, evidence `..._arc12-s1-floor-
record.md`) refuses any TU whose desugar-threaded symbol ids can
overlap ambient ids — one `CERB_FRESH_FLOOR_VIOLATION` stderr line,
exit 70, harness bucket `CERB_FLOOR`. All 35 witnesses in this
manifest (+ sia_csmith_976, reclassified latent F-D) now fail LOUD;
none silently wrong. Symbol numbering of in-margin programs is
bit-for-bit unchanged (pin-provenance + generated-tree gates).
RENUMBERING (removing the refusal class) is deferred:
`lean_frontend/docs/2026-08-21_arc12-renumbering-case.md`.

**Attribution correction (addendum — the 2026-08-21 attribution
paragraph above is superseded on the mechanism, not on the
upstream/fork split).** Arc-12 S0 probing (20/20 witnesses
duplicate-scan-positive in `--pp core -d5`; upstream 0/2 control;
11,206 run-time suspicious-equality hits on one witness) established
that the family's mechanism is the APRIL DESUGAR THREADING (commit
`8923d6436`: desugM `fresh_sym_supply = 0` — desugar ids [0,N) no
longer advance the ambient counter) colliding with TRANSLATION-minted
ambient label/temp symbols (`ret_/break_/continue_/while_N`, `a_N`)
via description-insensitive symbol equality. The arc-2 S1 threaded
run supply (`core_run_aux.lem:287`, named "prime suspect" above) is
EXONERATED for every probed witness: run-supply ids seed above the
whole program-symbol range (~5,000-8,700 measured). Its conceded
non-escape obligation remains open but narrowed (arc-12 S1 record
§5.3). F-A/F-B/F-E dispositions are unchanged.

## ARC-13 STATUS UPDATE (2026-08-22): F-D CLOSED-BY-CONSTRUCTION — the witnesses land on upstream

The renumbering the arc-12 update deferred is DONE (arc-13 D1, scheme
R-B "upstream re-convergence": desugar + run symbol supplies
re-unified onto the single ambient `Cerb_fresh.int` on the OCaml
target via three ocaml-only target_reps +
`ocaml_frontend/fork_renumber.ml`; decision + probe evidence
`lean_frontend/docs/2026-08-22_arc13-s0-scheme-decision.md`, build
record `..._arc13-s1-build.md`). Consequences for this manifest:

- **The F-D mechanism no longer exists** (one supply, nothing to
  collide with); the floor is now a single-supply window BACKSTOP
  (fires only if the split-stream scheme is ever re-introduced —
  plant-tested) and the `CERB_FLOOR` refusal class is gone from every
  lane.
- **Witness verdicts, fork (renumbered) vs un-forked upstream
  (b9aeedcb4), verbatim:** csmith_6000018 `Specified(100)` ==
  upstream; csmith_6000038 `Specified(13)` == upstream on ALL
  exhaustive executions (the manifest's old-oracle 218/134 rows above
  describe the pre-renumbering corruption); csmith_6000098
  `Specified(117)` == upstream; ub010_dead_object_reduced: exit 124
  timeout == upstream's honest non-termination (the spurious UB010 is
  gone). Fork `--pp core` output is byte-identical to upstream's on
  every S0-probed fixture, so fork-vs-upstream triage on any future
  finding is a byte-diff.
- The 15 corpus DIFF rows + sa_csmith_190 + sia_csmith_976 + the
  34-row coincidentally-correct class: restored to real verdicts in
  the arc-13 corpus re-baseline (close-out record).
- The arc-2 run supply's narrowed non-escape obligation (O1) is
  CLOSED on the OCaml side (run symbols are ambient draws again);
  it remains a Lean-side-only note.
