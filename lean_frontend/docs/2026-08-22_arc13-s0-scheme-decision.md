# Arc-13 S0: the scheme decision — R-B (upstream re-convergence), evidence-backed

Date: 2026-08-22. Worker: arc-13 S0 (charter:
`2026-08-22_arc13-renumbering-charter.md`). Worktree `arc/renumbering`
@ `de68a4839` (fork oracle `--version` verbatim:
`git-cn-pin-305-gde68a4839`); upstream oracle
`deps/cerberus-upstream/_build/default/backend/driver/main.exe`
(`git-cn-pin-18-gb9aeedcb4`, the merge-base build,
`notes/2026-08-21_upstream-oracle-build.md`). Inputs:
`2026-08-21_arc12-renumbering-case.md` (R1–R3 design space),
`2026-08-21_arc12-s0-floor-design.md` (+S1 addendum, draw-site
enumeration), `2026-08-21_arc12-results.md` (grandfather register
G1–G4), `notes/2026-08-21_fork-drift-review.md` §4 (the S1/S2/S3
suspect anatomy), commit `8923d6436` (the April desugar threading).

Slice discipline: docs-only commit; all probe builds were scratch
(sources reverted, generated trees regenerated pristine and
diff-verified byte-identical to pre-probe snapshots, `git status`
clean). Probe artifacts live in `_build/s0probe/` (gitignored;
capture script + fixtures inlined/derivable from §1.1). The
`workbench-v2` worktree, lem-lean, and `deps/lem-pinned` were not
touched.

Inherited fast gate BEFORE probing (verbatim): `./scripts/test_unit.sh`
exit 0; `SKIP_BUILD=1 ./scripts/test_exec.sh tests/minimal` exit 0:

```
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
```

Post-cleanup (restored tree): test_unit exit 0; `test_verify: 29
passed, 0 failed`; exec-minimal SUMMARY identical to the above; the
probe-rebuilt `_build/default/runtime/libc/{libc,libm,libc_inner_arg_temps}.co`
restored from the primary checkout and re-verified (`--pp=core` dump of
the restored libc.co byte-equal to `tests/libc/libc.core`; whole
`_build/default/runtime` tree diff vs the primary checkout: empty).

## 0. Executive summary

1. **RECOMMENDATION: R-B, upstream re-convergence, in its FULL form**
   (desugar supply AND run supply un-threaded on the OCaml target via
   three ocaml-only `declare ocaml target_rep` seams + one small hand
   shim). Evidence: the probe oracle's output is **byte-identical to
   the un-forked upstream oracle on 11/11 fixtures** — including the
   9.8 MB uri.c `--pp core`, the 1.1 MB libc stdio.c TU, the F-D
   witness csmith_6000098 (pp AND exec: `Specified(117)`), and both
   margin-edge synthetics — and a **probe-rebuilt libc.co whose 89,609-
   line Core dump is byte-identical to upstream's own libc.co dump**.
   Fork-vs-upstream comparison collapses to `cmp`.
2. **The .lem surface is exactly token-neutral on the Lean side**:
   the three declares are ocaml-target-only; regenerating with the
   forked lem produced an **EMPTY `lean_frontend/generated/` diff**
   (measured, not assumed — no comment echoes; the drift-review §3
   comment-echo concern does not apply to this declare form). Zero
   .lem *body* changes; the arc's "generated-LEAN movement =
   cerberus-scale validation event" tripwire does not fire.
3. Collision impossibility under R-B is **upstream's own invariant**:
   one counter, every symbol id is a distinct draw — there is no
   second stream to collide with. The arc-12 O1 residual (run-vs-
   ambient) CLOSES on the OCaml side outright.
4. Both R-A instantiations were probed and are REJECTED (§5): R-A1
   (ambient base 2^20, the literal Lean mirror) costs the same full
   re-pin as R-B with none of the comparability payoff; R-A2 (desugar
   supply at 2^20) is nearly re-pin-free but preserves the accidental
   fork-private numbering, leaks desugar ids into pp surfaces anyway
   (tag-suffix + glob-order diffs, measured), and re-opens a run-supply
   growth hazard that pushes its fix toward R-B's .lem surface size.
5. The standing differential surface is id-insensitive: with the R-B
   probe oracle in place, `test_exec.sh tests/minimal` and
   `test_multi_tu.sh` (Lean side UNTOUCHED vs renumbered oracle)
   returned SUMMARY lines identical to baseline (verbatim §1.6).
   Predicted baseline movement under R-B is therefore confined to the
   516 corpus `CERB_FLOOR` restorations plus the enumerated pinned
   .core artifacts (§6 pricing table).

## 1. Probe evidence

### 1.1 Method

Fixture battery (per oracle variant, `_build/s0probe/capture.sh`):
- `tests/verify/t{1..5}*.c` — `--nolibc --pp=core` (the pinned T1-T5
  fixtures; in-margin);
- `decl463.c` / `decl464.c` — the arc-12 §1.2 synthetic margin
  boundary (N scalar globals + main), regenerated per that recipe;
- `csmith_6000098.c` (committed F-D witness, headers staged) —
  `--pp=core` and `--exec --batch --mode=exhaustive`;
- `uri.c` — libxml2_prep args + `--nolibc --pp=core` (beyond-margin,
  hwm 1798, 252 live collisions under grandfather);
- `src/stdio.c` — libc cpp surface (`-I include -I include/posix`),
  `--nolibc --pp=core` (beyond-margin, hwm 856, 214 live collisions).

Variants: `current` (pristine fork; beyond-margin rows exit 70),
`current_gf` (pristine + `--fresh-floor-grandfather` — the pinned-
artifact-equivalent numbering), `upstream`, and per-candidate scratch
oracles. Scratch edits per candidate (all reverted):
- **R-B probe**: generated `cabs_to_ail_effect.ml` `fresh_sym_int` →
  `Cerb_fresh.int`; `core_run.ml` `fresh_symbol'` → `Symbol.fresh ()`;
  `core_run_aux.ml` run-seed draw → `0`; floor hook no-op'd.
- **R-B .lem-route** (the implementable shape, §2): three
  `declare ocaml target_rep` + `ocaml_frontend/fork_renumber.ml` shim,
  regenerated with the pinned lem via `make prelude-src` /
  `make lean-prelude-src`.
- **R-A1**: `util/cerb_fresh.ml` counter base `(1 lsl 20)`; floor
  untouched (its checks go structurally silent).
- **R-A2**: `fresh_sym_int` → private per-TU counter at base 2^20
  (reset in `set_digest`); ambient ceiling check; hook no-op'd.

### 1.2 R-B headline: byte-identity with upstream — 11/11

Desugar-only un-threading got 8/11 (residual: a constant ambient-id
offset on the three const-expr-carrying fixtures — the arc-2 run-seed
draws one ambient id per mini_pipeline const-expr run that upstream
does not, e.g. csmith98 `a_7308` vs upstream `a_7271`, +37 = its
const-expr run count). With the run supply also un-threaded (R-B-full):

```
t1_id IDENTICAL / t2_add IDENTICAL / t3_roundtrip IDENTICAL /
t4_struct_member IDENTICAL / t5_sum IDENTICAL / decl463 IDENTICAL /
decl464 IDENTICAL / csmith98_pp IDENTICAL / csmith98_exec IDENTICAL /
stdio IDENTICAL / uri IDENTICAL          -> identical=11/11
```

(cmp, byte-level; uri = 9,862,429 bytes, stdio = 1,116,759 bytes.)
The .lem-route rebuild reproduced the same 11/11 (`rb_lem` captures).

Witness execs under the R-B probe oracle (verbatim):

```
csmith_6000098: Defined {value: "Specified(117)", stdout: "", stderr: "", blocked: "false"}   (upstream: identical line)
csmith_6000018: Defined {value: "Specified(100)", stdout: "", stderr: "", blocked: "false"}   (upstream: identical line)
```

— the F-D corruptions (fork 187 / spurious UB) are GONE and land
exactly on the upstream/gcc/Lean values.

### 1.3 R-B at libc scale: the G1 artifact re-derives onto upstream

`dune build cerberus.install` under the R-B probe oracle rebuilt
libc.co (the build the arc-12 floor REFUSES on the pristine fork —
stdio/stdlib/internal/vfscanf beyond-margin). Its `--pp=core
--pp_core_out` dump (the libc_prep pin recipe):

```
rb_lem/libc_dump.core   89609 lines
upstream/libc_dump.core 89609 lines
cmp: LIBC DUMP: RB=UPSTREAM byte-identical
```

The fork's own libc, rebuilt under R-B, is **bit-for-bit upstream's
libc elaboration**. Against the current pin `tests/libc/libc.core`
(89,582 lines, grandfathered numbering): 42,661/42,688 changed lines
(diff `<`/`>`) — the G1 re-pin size.

### 1.4 R-A1 probe (ambient base 2^20 — the literal Lean mirror)

One hand-OCaml line; everything runs (no floors), csmith98 exec =
`Specified(117)` (correct). Movement decomposition: after subtracting
2^20 from every ambient token (`a_/ret_/break_/continue_/while_/do_N`)
and normalizing whitespace, **all 10 pp fixtures are OFFSET-EXACT** —
but NOT byte-predictable: the 7-digit ids re-wrap the pretty-printer
(line breaks + intra-group spacing move), so every pinned artifact
changes by both id tokens AND layout. Diff sizes ≈ R-B's plus ~5-25%
wrap churn (§6 table).

### 1.5 R-A2 probe (desugar supply at base 2^20)

csmith98 exec = `Specified(117)` (correct). pp is **byte-identical to
the current pins on 8/10 fixtures** (all of tests/verify, decl463/464,
uri) — desugar sym numbers are mostly invisible in `--pp core`. The
two exceptions expose exactly where they are NOT invisible:

```
csmith98_pp: 282 diff lines vs current_gf; stdio: 25/28 lines
  multiset analysis: pure glob-block MOVES (glob emission order sorts
  by symbol num — string-literal ambient globs now sort before
  2^20-based desugar syms) + tag-name disambiguation suffixes that
  EMBED the desugar num:  union U0_369 -> U0_1048945,
  struct _IO_FILE_331 -> _IO_FILE_1048907  (upstream: _IO_FILE_822)
```

So R-A2 is *nearly* but not actually numbering-invisible, and every
beyond-margin artifact still re-derives (the G-entries force that
anyway).

### 1.6 The standing differential surface is id-insensitive (R-B oracle)

With the R-B probe oracle in `_build` and the UNTOUCHED Lean pipeline
(verbatim):

```
test_exec.sh tests/minimal : SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0   (exit 0; identical to baseline)
test_multi_tu.sh           : SUMMARY: total=2 match=2 fail=0            (exit 0)
```

Lean-vs-oracle verdict comparison never sees symbol ids; renumbering
the oracle moves no verdict row outside the FLOOR restorations.

### 1.7 Token-neutrality: the generated-Lean diff is EMPTY (measured)

The .lem-route probe added exactly (scratch wording; S1 lands reviewed
comments):

```
cabs_to_ail_effect.lem: declare ocaml target_rep function fresh_sym_int = `Fork_renumber.fresh_sym_int`
core_run.lem:           declare ocaml target_rep function fresh_symbol' = `Fork_renumber.fresh_symbol'`
core_run_aux.lem:       declare ocaml target_rep function initial_core_run_state = `Fork_renumber.initial_core_run_state`
```

plus `ocaml_frontend/fork_renumber.ml` (13 lines of code: ambient
`fresh_sym_int`, ambient `fresh_symbol'`, and a cited mirror of
core_run_aux.lem:282-289 `initial_core_run_state` with
`sym_supply = 0` — dead on this target). Regeneration results:
- `make prelude-src`: 6 generated .ml files move (cabs_to_ail_effect,
  cabs_to_ail, core_reduction, core_run, core_run_aux, driver) — defs
  replaced by comment echoes, call sites rewritten to `Fork_renumber.*`;
- `make lean-prelude-src`: **`diff -rq` vs the pristine snapshot:
  EMPTY**. Zero movement, not even comments. The Lean pipeline, its
  threaded supplies, its 2^20 native counter, and all its theorems are
  untouched by construction AND by measurement.

## 2. The R-B implementation shape (what S1 lands)

- `ocaml_frontend/fork_renumber.ml` (hand, same `cerb_frontend`
  library — the decode.ml precedent; `include_subdirs unqualified`).
  Mirror-OCaml citations: upstream core_run.ml Load site mints
  `Symbol.fresh ()` (generated upstream core_run.ml:612); upstream has
  no run seed and no desugar supply. No module cycles (checked:
  nothing in Core_run_aux/Symbol references the shimmed names;
  `Core_run2`/`interactive_driver` are build-excluded dead code).
- The three declares above, placed beside the .lem definitions they
  override, with permanent comments citing this document and
  `8923d6436` (whose "OCaml path unchanged" claim this change finally
  makes true — the drift-review O6 finding retires).
- The Lean target keeps ALL of it: the threaded desugar supply (the
  April CSE-safety reason stands), the threaded run supply (arc-2
  purity), the 2^20 native base + trap. Nothing on the Lean side moves.

## 3. Collision-impossibility arguments (task 2)

**R-B (chosen): one supply, no second stream.** On the OCaml target
every symbol id — core-parse registrations, desugar mints, translation
temps/labels, run-time Load/RMW symbols — is a distinct draw from the
single monotone `Cerb_fresh.int` (the §3.3 arc-12 enumeration plus the
two re-unified streams; `fresh_given_int`'s only OCaml consumer was
`fresh_symbol'`, now shimmed). Two symbols with equal `(digest, num)`
can only be two references to the SAME draw. This is upstream's own
architecture, carried by upstream for the project's lifetime; the
arc-12 O1 residual (run ids vs post-init ambient ids) closes outright
on the OCaml side (run ids ARE ambient draws). The S3 SeqRMW
draw-time hoist remains a draw-ORDER divergence only (atomics path;
order cannot create equal ids under a single counter) — recorded as
the one remaining numbering caveat for three-way EXEC traces on
atomics inputs; `--pp core` is unaffected.
What the April threading was FOR: Lean CSE-safety (pure-typed
`Symbol.fresh` collapsed under CSE). Un-threading the OCAML target
only cannot disturb that — verified by the empty generated-Lean diff
(§1.7) and by the unchanged Lean-vs-oracle differential (§1.6).

**Floor adaptation (stays as the permanent backstop).** The two
arc-12 checks are keyed to stream disjointness and MUST be reworked
(under R-B the backward check would fire on every TU — desugar ids are
now ambient, `m >= tu_first` is the healthy state). The single-supply
invariant is: every symbol of the CURRENT TU's digest has
`num ∈ [tu_first, counter_next)` — i.e. minted by this TU's own
counter window. `ail_sym_hwm.ml` extends its fold to (min, max) over
current-digest symbols; the hook checks both ends; token
`CERB_FRESH_FLOOR_VIOLATION` + exit 70 stay. A regression that
re-threads any supply (0-based ids below `tu_first`, or ids above the
counter) fails loud. Acceptance: never fires on any in-tree input;
plant test: simulate a re-threaded supply (locally re-point one shim
at a 0-based counter) → fires. The warn-only modes (export +
grandfather) and the `--fresh-floor-grandfather` flag become dead code
and are REMOVED with the uri-lane invocations (charter S1).

**R-A1 (rejected): the Lean scheme verbatim.** Ambient/run ids
≥ 2^20 and ascending; desugar `[0, N_d)` per TU with `N_d < 2^20`
enforced by the hook (a >1M-identifier TU refuses — same shape the
accepted Lean scheme has carried since arc-4). Bounded stream below,
unbounded streams above: sound, simple, one hand-OCaml line. Its
argument is fine; its price/payoff is not (§5).

**R-A2 (rejected): inverted layout is the wrong direction.** Desugar
`[2^20, 2^20+N_d)` per TU above, ambient `[0, 2^20)` ceiling-checked
below — but the arc-2 run supply seeds from an ambient draw
(~0.5-9k) and grows +1 per run-minted symbol WITHOUT bound: one run
minting ~2^20 Load symbols walks into the desugar window
(same-digest collision returns). 2^20 mints in a single run is
physically plausible for the corpus's long-loop/timeout-class
programs. Repair requires a bigger base (physics, not construction)
or a guarded `fresh_given_int` — i.e. another ocaml declare + shim,
converging on R-B's surface size while keeping the accident-shaped
numbering. The bounded-below/unbounded-above layout (Lean's, R-A1's,
and trivially R-B's) is the only construction-grade direction.

## 4. Was 2^20 the right constant? (work-order question)

For R-B the question dissolves — there is no base. For the record
(and for the Lean side's standing scheme): the measured ambient
draw counts are ~483 (std.core+impl parse) + ~1-8/TU-const-expr +
per-TU translation draws; the largest measured single-process consumer
is the 12-TU libc build at ~10.8k total draws — 2^20 has ~97x
headroom, and the Lean native counter's trap plus (post-S1) the
adapted floor make any approach loud, never silent. No per-mode
analysis is needed under R-B; the Lean side's 2^20 stays as-is.

## 5. The losers' rejection rationale

**R-A1** — same cascade, no payoff. Measured diff sizes vs the
current pins are R-B's plus wrap churn (§6). It buys disjointness
only; numbering becomes fork-private-forever with a permanent
documented divergence, upstream filings stay non-comparable, the
drift surface stays at arc-12 size. Its one real advantage over R-B —
zero .lem involvement — was neutralized by measurement: the R-B .lem
surface produces an EMPTY generated-Lean diff and zero .lem body
changes.

**R-A2** — cheapest today, wrong asymptote. 8/10 fixtures re-pin-free
is genuinely attractive, and it would leave pin-provenance and the
T1-T4 pins untouched. Rejected because: (i) the run-supply growth
hazard makes its impossibility argument physics-grade, not
construction-grade, and the fix grows its surface to R-B's; (ii) it
is not actually invisible (glob-order + tag-suffix leaks measured;
every grandfathered artifact re-derives non-identically anyway);
(iii) it preserves the historically-accidental numbering and the full
fork-drift delta the arc exists to shrink; (iv) grandfather
"dissolution" would move almost no bytes — closure would rest on the
scanner alone rather than on clean re-derivation; (v) upstream
comparability — the three-way instrument's strongest possible form,
byte-equality — is permanently forfeited.

**R-C (partitioned/high-bit tags, upstream-coordinated R3):** no new
evidence; R3 remains the long-term upstream conversation
(notes/upstream/07), and R-B is its best on-ramp — a fork whose
numbering IS upstream's makes any future upstream scheme change a
byte-diffable event on our side.

## 6. Downstream pricing (task 3)

Measured diff sizes (`diff` changed-line counts `(<, >)` vs the
current pinned/grandfathered outputs):

| artifact (lines) | R-B (=upstream) | R-A1 | R-A2 |
|---|---|---|---|
| t1_id.core (49) | 27,27 | 27,29 | 0 |
| t2_add.core (76) | 39,39 | 39,43 | 0 |
| t3_roundtrip.core (59) | 31,31 | 31,32 | 0 |
| t4_struct_member.core (90) | 41,41 | 41,45 | 0 |
| t5_sum.core (172) | 75,75 | 75,82 | 0 |
| decl463 (2846) | 1881,1881 | 1881,2345 | 0 |
| decl464 (2852) | 1885,1885 | 1885,2350 | 0 |
| csmith98 pp (23155) | 9626,9633 | 9697,10186 | 282,282 |
| uri pp (124174) | 50843,50887 | 50872,52146 | 0 |
| stdio pp (25725) | 12074,12085 | 12086,12743 | 25,28 |
| tests/libc/libc.core (89582) | 42661,42688 | (not rebuilt) | (not rebuilt) |

R-B re-pin inventory (S1 execution order, §7): the movement is LARGE
in bytes but SMALL in artifact classes, every new pin is
upstream-byte-identical (self-checking via `cmp` against the upstream
oracle), and the id-free surfaces provably do not move:
- **moves**: tests/verify/t*.core (5), tests/libc/libc.core, the
  emit-lean-core drift-gate slate terms (T1Core/SlateCore re-emitted
  from the new dumps) → T1-T4 re-elaboration via workbench
  record/replay (the charter's economics measurement), drift-manifest
  [expected-semantic] hashes for cabs_to_ail.ml, cabs_to_ail_effect.ml,
  core_reduction.ml, core_run.ml, core_run_aux.ml + driver.ml
  reclassified cosmetic→semantic (all six ALREADY manifest-listed;
  five are the review's F-D suspect family — the deltas SHRINK toward
  upstream) [CORRECTED at the S3 audit, B-F4 → decision-log C1: the
  "deltas SHRINK" prediction was WRONG — what went to zero is the
  OUTPUT/numbering divergence (byte-identity); the seam-code
  manifest deltas did not shrink. Measured at S1 and re-measured at
  the audit fix (changed-line counts vs upstream): cabs_to_ail
  24→24, cabs_to_ail_effect 85→85, core_reduction 30→30, core_run
  17→17 unchanged; core_run_aux 16→20 and driver 1→3 GREW — all six
  are the justified target_rep call-site rewrites], manifest [files]
  + fork_renumber.ml, csmith corpus
  baseline (516 CERB_FLOOR rows → real verdicts, three-way-checked
  sample), exploration-lane yield (restored, measured at S2).
- **predicted no-move** (each verified at S1): tests/verify
  expectations.txt (id-free, checked), the 12 libc metadata cabs-jsons
  (pre-desugar Cabs, id-free — D2/D3 evidence), uri/chvalid/float/
  bytes/ci/coverage/debug/minimal/multi_tu/libc_exec verdict baselines
  (id-insensitive; minimal + multi_tu already measured identical,
  §1.6), tests/libxml2 config pins (inputs, not oracle outputs),
  generated-Lean tree (measured EMPTY), lem-lean (zero changes).
- **.lem-edit neutrality**: verified empirically — EMPTY generated-Lean
  diff (§1.7); zero .lem body edits; 6 generated-OCaml files move by
  design with hashes re-pinned under this justification.
- **upstream-filing value**: F-A/F-B repros and every future finding
  become runnable on a fork oracle whose artifacts byte-match
  upstream's — fork-vs-upstream triage drops from "id-insensitive
  judgment call" to `cmp`; the notes/upstream/07 fragility filing
  gains the strongest possible demonstration (we re-converged; the
  single-counter invariant is load-bearing and now floor-checked).
- **long-term maintenance**: the fork's numbering-divergence surface
  vs upstream shrinks to: S3 SeqRMW draw-order (atomics, recorded) +
  the Lean-target-only threading (invisible to the oracle). The
  grandfather flag, warn modes, and their uri-lane plumbing DELETE.

## 7. THE DECISION (D-entry-ready) + S1 plan

**D1 (arc-13): the renumbering scheme is R-B — upstream
re-convergence, full form.** The fork oracle's desugar and run symbol
supplies return to the single ambient `Cerb_fresh.int` on the OCaml
target via three ocaml-only target_rep declares + the
`fork_renumber.ml` shim; the Lean target keeps its threaded supplies
and 2^20 protection unchanged. Rationale: collision impossibility by
single-supply construction (upstream's own invariant, O1 closed);
byte-identity with the upstream oracle measured 11/11 including
libc-scale (the three-way instrument's maximal form); EMPTY
generated-Lean diff (measured); the re-pin cascade is one honest,
self-checking event whose every new pin equals an upstream byte-diff
witness. R-A1/R-A2 rejected per §5. Risks accepted: upstream
draw-order dependence (that is the point — we pin artifacts, and
changes arrive as byte-diffs), S3 atomics draw-order caveat
(recorded), T1-T4 re-elaboration cost (the charter's intended
replay-economics measurement).

S1 execution order:
1. Land shim + declares (reviewed comments, citations); regenerate;
   gates: generated-Lean diff EMPTY, hand↔generated sync green.
2. Floor rework (§3): single-supply window check
   `[tu_first, counter_next)` via the extended ail_sym_hwm (min,max)
   fold; DELETE export/grandfather warn modes + `--fresh-floor-grandfather`
   + main.ml wiring + the two uri-lane usages; re-plant both
   directions (re-threaded-supply sim fires; pristine silent).
3. Rebuild oracle; margin smoke (decl463/decl464 both run; both
   byte-equal upstream); witness battery (35 F-D witnesses + sia_976:
   correct upstream-matching verdicts, scanner-verified zero
   duplicate (digest,num) pairs).
4. Re-pin tests/verify dumps (byte-check vs upstream oracle);
   re-emit slate terms; T1-T4 re-elaboration via workbench
   record/replay — MEASURE and record the cost.
5. `dune build cerberus.install`; re-pin tests/libc/libc.core
   (scanner-verified; byte-check vs upstream's dump); libc metadata
   jsons re-derived (expect byte-identical, verify).
6. Lane ladder in tier order (minimal→ci→coverage→float/bytes→
   multi_tu→libc_exec→uri (grandfather-free)→chvalid→csmith full):
   zero movement outside the FLOOR-restoration rows; every restored
   row three-way-spot-checked per the S2 sample plan.
7. Drift-manifest refresh (6 hash re-pins + files entries +
   `renumber=arc13` meta) with this doc as justification;
   check_fork_drift green.
8. Records: G1-G4 closure notes (clean re-derivations, byte-equal
   upstream), attribution addendum (8923d6436's message now true),
   arc-12 record closure addenda; hand S2 the movement list.

Probe scratch retained in `_build/s0probe/` (gitignored) for the S3
audit's re-derivation; regenerable from §1.1.
