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
| `ub010_dead_object_reduced.c` | **F-D: exec-driver allocation-state corruption, declaration-layout-sensitive** (= the wireguard scoping survey's can_advance defect, `notes/2026-08-20_wireguard-target-scoping.md` §2a addendum — CROSS-REFERENCED, now csmith-forced with small deterministic repros). This artifact (creduce 750→242 lines, gcc-validity-guarded) makes the oracle report `UB010_pointer_to_dead_object` on a live object; adding ONE unused declaration morphs it into `internal error: can_advance: Step_error2 ==> ...`. NOTE: replacing the `#include` by equivalent typedefs (a 1-declaration layout change) makes it pass — itself the fingerprint. Reduction predicate: gcc `-std=c11 -S -O1 -Werror=return-type` valid AND oracle `--nolibc --exec --batch` output contains `UB010_pointer_to_dead_object` | campaign record §corpus-lane |
| `csmith_6000018.c` | F-D witness (spurious UB): oracle `UB:UB_CERB002b_out_of_bound_store`, Lean+gcc `Specified(100)`; +1 decl → `can_advance: Step_error2 ==> Store`. Regen: csmith seed 6000018, lane-P5 flags | campaign record §round-1 triage |
| `csmith_6000098.c` | **F-D witness (SILENT VALUE CORRUPTION)**: oracle `Specified(187)`, +1 decl → `Specified(138)`; Lean+gcc stable at `Specified(117)`. The oracle's defined result is a function of top-level declaration count | same |
| `csmith_6000038.c` | F-D witness (value corruption + Lean perf note): oracle 2240 executions all `Specified(218)` (6.2s), +1 decl → 134; Lean 2240 all `Specified(13)` (= gcc; 86s — perf-gap registered) | same |

F-D family in-tree witnesses beyond these: `tests/csmith/small_arrays/`
csmith_120/149/168/19/218 (and more — full list in the corpus-lane
baseline) show the spurious-UB manifestation (UB010/UB009 DIFFs) as
plain in-tree files; exploration seeds 3016022/3016044/3016049/3016051/
3016058/3016074/3016082/3016099 (B1 flags) show the internal-error
manifestation.

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
