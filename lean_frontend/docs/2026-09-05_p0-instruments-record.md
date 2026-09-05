# P0 instruments — three gate defects from the whole-project audit, repaired (2026-09-05)

Branch `arc/p0-instruments` off mainline `9a7f7ad31`. Scope: the
whole-project release-gate audit's F2, F3, F4
(`docs/2026-09-05_whole-project-release-gate-audit.md`; evidence in
`docs/2026-09-05_whole-project-audit-evidence/`). Approval: [USER
2026-09-05] "yes on the two other items" covers exactly this slice; the
orchestrator independently re-measured all three premises TRUE before
dispatch. No `.lem` edit, no semantics edit; instruments and their
documentation only. Every quoted output below is verbatim; tallies marked
"derived" are derived.

Commits (one per finding, each on a green relevant gate):

| commit | finding | gate that was green |
|---|---|---|
| `e1ea5719e` | F4 fork-drift gate | full `test_unit.sh` (`Total: 6 passed, 0 failed` … `test_unit rc=0`) |
| `db1f9cec2` | F2 fuel-forms classifier | full `test_unit.sh` (same) |
| (this record's commit) | F3 Defined-line widening + record + docs | the four Tier A `test_exec.sh` lanes (§F3.3) + full `test_unit.sh` (§F3.5) |

No F3 re-baseline commit exists: nothing moved (§F3.3).

## F4 — `scripts/check_fork_drift.sh`

### F4.1 Premise, re-reproduced before the fix

HEAD's script and HEAD's manifest (scratch copies, `ROOT`/`MANIFEST`
pointed at them), this worktree, this box:

```
$ LC_ALL=C .tmp/scripts/old/check_fork_drift.sh
check_fork_drift: FAIL — oracle-surface file set drifted from the manifest.
--- files on the live diff but not in the manifest (NEW DRIFT):
comm: file 2 is not in sorted order
comm: input is not in sorted order
    frontend/model/cabs_to_ail.lem
    frontend/model/core.lem
$ env -u LC_ALL LANG=en_US.UTF-8 .tmp/scripts/old/check_fork_drift.sh
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
$ LC_ALL=C.utf8 .tmp/scripts/old/check_fork_drift.sh
check_fork_drift: FAIL — oracle-surface file set drifted from the manifest.
```

(`git rev-parse upstream/master` = `b9aeedcb4…` = the manifested merge-base.)

### F4.2 What changed

`scripts/check_fork_drift.sh` (rewritten around a `gate()` function; same
two layers, same manifest format):

* (a) `export LC_ALL=C` at script level AND inside `gate()`; layer 1 compares
  the manifest's `[files]` and the live `git diff --name-only` as SETS (both
  `sort`ed in the C locale) — order-insensitive, locale-independent.
  Duplicate `[files]` entries FAIL ("a set with a repeated name is not a
  reviewed set").
* (b) Missing upstream ref and missing generated tree (either side) are
  rc 1 (were `exit 0` "loud SKIPs" that `test_unit.sh` consumed as success).
  The only skip is the explicit development opt-in
  `CERB_FORK_DRIFT_DEV_SKIP=1`: a five-line `#####` banner ("This is NOT a
  pass"), exit 0 for the skipped layer(s). `test_unit.sh` runs the gate under
  `env -u CERB_FORK_DRIFT_DEV_SKIP`, so the opt-in cannot reach the unit gate
  from the ambient environment.
* (c) `[meta] lem-pin`: nothing read it (grep: only the `--refresh` writer,
  which wrote `lem -v 2>/dev/null || echo unknown`). [AGENT] decision: keep
  it, document it, and CHECK it — the manifest now says what it records (the
  lem-lean commit both generated trees were derived with; the layer-2 hashes
  are relative to it), the value is `f6542f8` (= `lem -v` = `deps/lem-pinned`
  HEAD = the Lake pin), the gate FAILs on a mismatch with `lem -v` when `lem`
  is on PATH and says "(lem not on PATH: not cross-checked)" otherwise; a
  missing `lem-pin=` line FAILs; `--refresh` requires `lem` on PATH.
* (d) `--selftest` (run first by `test_unit.sh`), each plant checked by rc
  AND message, with vacuity guards (S1's en_US/C orders must differ, S3's
  reversed order must differ from sorted, S4's name must exist):

```
check_fork_drift: SELFTEST — plants on scratch copies of the manifest and fake prerequisites (loud plant banner; nothing in the tree is touched)
  PLANT OK   [S1 en_US-ordered [files] under LC_ALL=C (the pre-repair failing configuration)] rc=0 -> check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef
  PLANT OK   [S2 C-ordered [files] under LC_ALL=en_US.UTF-8] rc=0 -> check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef
  PLANT OK   [S3 reversed [files] order (set unchanged)] rc=0 -> check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef
  PLANT OK   [S4 one [files] name changed -> set drift] rc=1 -> check_fork_drift: FAIL — oracle-surface file set drifted from the manifest.
  PLANT OK   [S4 detail] both the live-only name (util/cerb_fresh.ml) and the manifest-only name (util/cerb_fresh_planted.ml) are listed
  PLANT OK   [S5 duplicate [files] entry] rc=1 -> check_fork_drift: FAIL — duplicate [files] entries in the manifest (a set with a repeated name is not a reviewed set):
  PLANT OK   [S6 missing upstream ref -> FAIL (not a skip)] rc=1 -> check_fork_drift: FAIL — missing upstream ref 'plant/no-such-ref' (fail-closed; the development opt-in is CERB_FORK_DRIFT_DEV_SKIP=1)
  PLANT OK   [S7 missing upstream generated tree -> FAIL (not a skip)] rc=1 -> check_fork_drift: FAIL — layer 2 prerequisite missing (fail-closed; the development opt-in is CERB_FORK_DRIFT_DEV_SKIP=1): upstream pristine tree not found (deps/cerberus-upstream/ocaml_frontend/gen
  PLANT OK   [S8 CERB_FORK_DRIFT_DEV_SKIP=1 on a missing ref -> rc 0 with the DEV SKIP banner] rc=0 -> # check_fork_drift: DEV SKIP (CERB_FORK_DRIFT_DEV_SKIP=1 is set) — missing upstream ref 'plant/no-such-ref'; layers 1 and 2 NOT checked
  PLANT OK   [S9 stale [meta] lem-pin vs lem -v] rc=1 -> check_fork_drift: FAIL — lem-pin stale: manifest records lem-pin=f6542f8, '/home/dev/projects/cerberus-lean-proj/.tmp/tmp.CXRn4rr7J7/lem-stale -v' says deadbee — both generated trees must be re-de
  PLANT OK   [S10 [meta] lem-pin line missing] rc=1 -> check_fork_drift: FAIL — manifest has no [meta] lem-pin= line (the lem-lean commit both generated trees were derived with)
  UNPLANTED:
    check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
check_fork_drift: SELFTEST OK (10 plants with the declared verdict and message: S1-S3 order/locale OK, S4 name-drift FAIL (+ both-sides listing), S5 duplicate FAIL, S6 missing-ref FAIL, S7 missing-tree FAIL, S8 dev-opt-in rc 0 with banner, S9/S10 lem-pin FAILs; unplanted gate green)
```

The missing-ref plant uses a nonexistent ref name passed to `gate()` (no
temp clone); the missing-tree plant passes a nonexistent directory; the
lem-pin plants pass fake `lem` executables.

`scripts/fork_drift_manifest.txt`: `[files]` re-sorted ORDER-ONLY into C
byte order — 71 names before, 71 after, same multiset: the C-sorted set's
sha256 is `4b1daa403c8405f99eda86169e4f879bb7cfbd66216e9a2d638f85acd7c9509f`
both at HEAD and after the edit (awk `[files]` extraction | `LC_ALL=C sort`
| `sha256sum`). `[meta] lem-pin` `af5df71` → `f6542f8` with the explanatory
comment. No `[expected-*]` hash moved.

### F4.3 Verified

Standalone, after the fix: `LC_ALL=C` with env.sh sourced →
`check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)`;
`LANG=en_US.UTF-8` without env.sh → the same line ending
`lem-pin f6542f8 (lem not on PATH: not cross-checked))`. Full `test_unit.sh`
(the F4 commit gate): `Total: 6 passed, 0 failed`, the SELFTEST OK and OK
lines above, `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)`, `test_unit rc=0`.

### F4.4 Not done here (by instruction)

Layer 1 still pins NAMES only for the hand-written oracle files
(`util/cerb_fresh.ml`, `ocaml_frontend/fork_renumber.ml`,
`backend/driver/main.ml`, …): a behaviour change inside an already-listed
hand file moves neither list. Content pins for that surface are the audit's
F5 task (the script header says so).

## F2 — `lean_frontend/test/Unit/FuelFormsTool.lean` + `scripts/check_fuel_forms.sh`

### F2.1 The real shapes (looked at before coding)

Generated shells (45): `theorem f_measure_sufficient {implicits…}
[instances…] (xs…) [(lemHyp : H)] (lemFuel : Nat) (lemMeasureLe : μ ≤
lemFuel) : f_lemFuel lemFuel xs… = f xs…`, wrapper `def f xs… := f_lemFuel μ
xs…` (e.g. `Defacto_memory_aux.lean:174` `tmp_AND_aux nbits n1 n2 :=
tmp_AND_aux_lemFuel (nbits + 1) nbits n1 n2`). At the `Expr` level the
implicit/instance arguments precede `lemFuel` on the worker side
(`@find_labeled_continuation_lemFuel a b c inst lemFuel sym1 g`), so "lemFuel
first" is not literally true — the invariant that IS true is "the worker's
arguments minus the `lemFuel` binder = the wrapper's arguments". Hand-written
`CerbMem` seams (9): the same shape, except the four layout seams pass a
binder TWICE (`alignofCtype_lemFuel lemFuel ambient ambient cty =
alignofCtype ambient cty`, wrapper `CerbMem.lean:572`
`alignofCtype_lemFuel (envBound ambient cty) ambient ambient cty`).
`_zero` lemmas: `worker … 0 … = <absorbing>` with the literal at the fuel
parameter, which is not always first (`runND1TraceFuel showInfo 0 m st0`),
and `CerbND.runND1TraceFuel_zero`'s auto-bound implicits `{a info err cs st}`
are PERMUTED relative to the worker's (`info` first there).

### F2.2 What changed

`obligationShape` now runs in MetaM under the statement's own telescope and,
after the C4 checks (heads by name; `lemFuel : Nat` by name; a `μ ≤ lemFuel`
binder on it; `lemHyp` immediately before `lemFuel`; every non-reserved
binder a wrapper argument), requires in this order:

1. the wrapper side is the wrapper applied to exactly the statement's
   non-reserved binders, in order;
2. `lemFuel` occurs exactly once on the worker side; every other worker
   argument is one of the wrapper's input binders (no literal, no other
   term) — this is where the audit's decoy 2 fails;
3. `lemFuel` sits at the worker's own parameter named `lemFuel`
   (`workerFuelIndex`) — "wrong fuel position" has its own message;
4. the wrapper's own body (`instantiateValueLevelParams!` + `Expr.beta` on
   the statement's binders, `headBeta`, `consumeMData`) is a call of the
   worker with the same argument count, whose arguments equal the worker
   side's position by position, and whose argument at the fuel position is
   the hypothesis' μ (syntactically, else `isDefEq` at reducible
   transparency; reported `measure=syntactic|defeq`). The detail also reports
   `args=positional` (worker args minus `lemFuel` == wrapper args) or
   `args=wrapper-body` (the diagonal seams). So the lower bound IS the
   wrapper's measure and the equation relates the worker to the wrapper on
   the wrapper's own inputs.

ABSORBING (`zeroShape`, MetaM): LHS head IS the worker constant; exactly one
literal `0` (`OfNat.ofNat Nat 0 _` / `Nat.zero` / raw literal) at a `Nat`
parameter of the worker; the remaining arguments are the lemma's binders,
each once, as a SET ([AGENT] a permutation of distinct universally
quantified binders is fully general; positional would wrongly reject
`runND1TraceFuel_zero`); RHS head/atom/sentinel checks kept; the lemma's
axiom cone reported (`axioms=ok`). A same-named lemma of another shape is
`MALFORMED-ZERO` (AMBIENT for the census, RED for the policy). Every AMBIENT
row (MALFORMED included) is counted once in `FUEL_FORMS_SUMMARY` (MALFORMED
rows were previously uncounted there).

Relabel (d): tool header and a `FUEL_FORMS_LEGEND` stdout line; the gate's
OK line says `ABSORBING = kill at zero (… propagation NOT proved — lem TODO
13)`; VALIDATION.md's (B) row says the propagation claim is NOT proved by
this gate (lem-lean `doc/lean-backend/TODO.md` row 13, fuel monotonicity).

Policy additions: RED on `MALFORMED-ZERO`; RED on an ABSORBING row whose
cone is not `axioms=ok`.

### F2.3 Census — unchanged

```
FUEL_FORMS_SUMMARY	workers=81	measured=54	measured_under_hyp=7	absorbing=13	ambient_reachable=8	ambient_unreachable=6	closure_size=10433
```

Derived from the table: the 54 MEASURED rows are 50 `args=positional
measure=syntactic` + 4 `args=wrapper-body measure=syntactic`
(`CerbMem.alignofCtype/memberAlign/offsetsofMembers/sizeofCtype_lemFuel`);
0 MALFORMED rows. (A first draft with positional `_zero` binders reported
`absorbing=12`, `MALFORMED-ZERO … runND1TraceFuel`; the set rule above
restored 13 — noted so the choice is visible.)

### F2.4 Plants (`--selftest`, run by `test_unit.sh`)

The audit's two decoys are compiled VERBATIM (module
`FuelFormsPlantAudit`, from the evidence dir's `ReviewFuelDecoy.lean.txt`)
plus fresh decoy workers/wrappers for the listed extra plants; each table row
is checked for its own message:

```
  PLANT OK   [P12 audit decoy 1: _zero lemma about CerbND.runNDFuel, not the worker] -> review_bad_lemFuel AMBIENT: MALFORMED-ZERO zero=review_bad_lemFuel_zero: left-hand head `CerbND.runNDFuel` is not the worker `review_bad_lemFuel`
  PLANT OK   [P12 policy: a MALFORMED-ZERO lemma is RED] -> check_fuel_forms: FAIL — lemma(s) named <worker>_zero whose statement is not `worker … 0 … = <absorbing element>` on the worker's own binders — never ABSORBING:
  PLANT OK   [P13 audit decoy 2: worker at literal 0, wrapper input x never passed] -> review_shift_lemFuel AMBIENT: MALFORMED obligation=review_shift_measure_sufficient: worker argument #1 is `0`, not one of the wrapper's input binders — the obligation must relate the worker to the wrapper on the SAME inputs
  PLANT OK   [P14 wrong fuel position] -> pl_pos_lemFuel AMBIENT: MALFORMED obligation=pl_pos_measure_sufficient: wrong fuel position: `lemFuel` is passed as worker argument #1 (`a`), but the worker's `lemFuel` parameter is #0
  PLANT OK   [P15 swapped arguments on the worker side] -> pl_swap_lemFuel AMBIENT: MALFORMED obligation=pl_swap_measure_sufficient: worker argument #1: the obligation passes `b`, but the wrapper `pl_swap` passes `a` — the equation does not relate the worker to the wrapper on the same inputs
  PLANT OK   [P16 swapped arguments on the wrapper side] -> pl_swapw_lemFuel AMBIENT: MALFORMED obligation=pl_swapw_measure_sufficient: wrapper argument #0 is `b`, not the binder `a` — the wrapper side must be the wrapper applied to the statement's own binders, in order
  PLANT OK   [P17 changed measure (lower bound a vs the wrapper's a + 1)] -> pl_mu_lemFuel AMBIENT: MALFORMED obligation=pl_mu_measure_sufficient: the lower bound `a` of the `≤ lemFuel` hypothesis is not the wrapper's measure: `pl_mu` calls the worker at fuel `a + 1`
  PLANT OK   [P18 renamed worker: the wrapper calls pl_rhs_other_lemFuel] -> pl_rhs_lemFuel AMBIENT: MALFORMED obligation=pl_rhs_measure_sufficient: the wrapper `pl_rhs` does not call the worker `pl_rhs_lemFuel`: on these inputs its body is a call of `pl_rhs_other_lemFuel`
  PLANT OK   [P19 hidden extra premise inside the ≤ binder] -> pl_prem_lemFuel AMBIENT: MALFORMED obligation=pl_prem_measure_sufficient: no hypothesis `_ ≤ lemFuel` on the `lemFuel` binder
  PLANT OK   [P20 POSITIVE CONTROL: well-formed _zero lemma on a decoy worker] -> pl_zt_lemFuel ABSORBING: zero=pl_zt_lemFuel_zero heads=[nd_status.Killed, CerbND.fuelExhaustedKill] axioms=ok
  PLANT OK   [P21 _zero lemma with a term (st0 + 1) where a binder must be] -> pl_ztb_lemFuel AMBIENT: MALFORMED-ZERO zero=pl_ztb_lemFuel_zero: worker argument `st0 + 1` is not one of the lemma's binders (the lemma must state the worker at fuel 0 on universally quantified inputs)
  PLANT OK   [P22 _zero lemma at fuel 1, not 0] -> pl_ztc_lemFuel AMBIENT: MALFORMED-ZERO zero=pl_ztc_lemFuel_zero: no literal `0` among the worker's arguments (the lemma must state the worker at fuel 0)
  PLANT OK   [P23 ABSORBING _zero lemma with sorryAx in its cone (nd_bind)] -> check_fuel_forms: FAIL — ABSORBING _zero lemma(s) with an axiom cone outside [propext, Classical.choice, Quot.sound] (or no cone reported):
```

P10 (C4) had to change: its `hack` decoy under `0 ≤ lemFuel` is now
correctly MALFORMED (`hack`'s wrapper calls it at `LemFuel.fuel`, not at a
measure: `the lower bound `0` of the `≤ lemFuel` hypothesis is not the
wrapper's measure: `hack` calls the worker at fuel `LemFuel.fuel``) — the
register was never reached. The contradictory-hypothesis plant is now the
real `CerbMem.alignofCtype` obligation restated under `cty ≠ cty` in the P11
run (where `CerbMem_lemMeasureProofs` is excluded): the tool reports
`CerbMem.alignofCtype_lemFuel MEASURED … args=wrapper-body measure=syntactic
hyp=cty ≠ cty` and the register turns it RED (`no reviewed register row`).

```
check_fuel_forms: SELFTEST OK (24 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: the C4 four (type True / wrong worker / contradictory hypothesis caught by the register / extra binder), the whole-project audit's two decoys verbatim (review_bad _zero about runNDFuel; review_shift at literal 0), wrong fuel position, swapped worker-side and wrapper-side arguments, changed measure, wrapper calling another worker, hidden premise, and three _zero decoys (a POSITIVE control ABSORBING, a term for a binder, fuel 1) — each rejected with its own message; unplanted table green)
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
```

Full `test_unit.sh` (the F2 commit gate): `Total: 6 passed, 0 failed`, the
two lines above, the F4 lines, `test_unit rc=0`.

### F2.5 What the gate still does not claim

Propagation of exhaustion through successor cases (fuel monotonicity) —
lem-lean TODO row 13, unchanged by this slice; the label now says so. The
audit's further asks (typed metadata emitted with each worker; a registered
typed contract for hand-written workers; reachability independent of the
`_lemFuel` naming convention) are not done here.

## F3 — `scripts/test_exec.sh` Defined-line widening

### F3.1 Premise (audit evidence `verdict-extractor-plant.log`, reproduced in-plant as E0)

The pre-repair `extract_verdict_seq` kept `^Defined \{value: "[^"]*"` only:
`Defined {value: "Specified(0)", stdout: "GOOD", stderr: ""}` and
`Defined {value: "Specified(0)", stdout: "BAD", stderr: "WRONG"}` both →
`VAL:Specified(0)`.

### F3.2 What changed

`extract_verdict_seq` keeps the WHOLE `Defined {…}` line body as the VAL
token (`VAL:{value: "…", stdout: "…", stderr: "…", blocked: "…"}`), mirroring
the Z1 UB token; grep/sed run under `LC_ALL=C` (both printers escape with
OCaml `String.escaped` semantics — `driver_ocaml.ml:99`, `Main.lean`
`batchEscape` — so the payload is ASCII and byte-exact). Undefined handling
unchanged. The comparison logic is untouched: identical sequences → MATCH /
UB_MATCH; UB_DIFF still requires identical VAL tokens (now whole lines). The
header's FULL-SEQUENCE and spoofing-caveat paragraphs and the Z-72 comment
block are rewritten to say exactly this; the ^-anchoring argument in the
caveat still holds (E5 pins it). Baseline FILES record statuses only and did
not change format; ROWS could move (same-value stdout/stderr difference →
MISMATCH).

The extraction block (extractor, `expected_exit_for`, `join_seq`) moved
ahead of the build section so `--selftest` is hermetic (no binaries, no
oracle); `test_unit.sh` runs it:

```
test_exec: SELFTEST — extract_verdict_seq plants (loud plant banner; no binaries run)
  PLANT OK   [E0 pre-repair extractor collapses the audit pair to one token: VAL:Specified(0) == VAL:Specified(0)]
  PLANT OK   [E1a audit line 1 -> whole-line token] -> VAL:{value: "Specified(0)", stdout: "GOOD", stderr: ""}
  PLANT OK   [E1b audit line 2 -> whole-line token] -> VAL:{value: "Specified(0)", stdout: "BAD", stderr: "WRONG"}
  PLANT OK   [E1 same-value/different-stdout+stderr lines yield DIFFERENT tokens]
  PLANT OK   [E2a] -> VAL:{value: "Specified(3)", stdout: "x", stderr: "", blocked: "false"}
  PLANT OK   [E2b] -> VAL:{value: "Specified(3)", stdout: "x", stderr: "warn: y", blocked: "false"}
  PLANT OK   [E2 same-value/different-stderr lines yield DIFFERENT tokens]
  PLANT OK   [E3 escaped-quote/backslash/octal payload preserved byte-exactly] -> VAL:{value: "Specified(1)", stdout: "say \"hi\"\n\\ tab\t \255\000 end", stderr: "", blocked: "false"}
  PLANT OK   [E4 multi-outcome: 3 tokens in order (Defined a / Undefined / Defined b)] -> VAL:{value: "Specified(0)", stdout: "a", stderr: "", blocked: "false"}|UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<file.c:3:5>"}|VAL:{value: "Specified(0)", stdout: "b", stderr: "", blocked: "false"}
  PLANT OK   [E5 embedded escaped Defined text is payload, not a token] -> VAL:{value: "Specified(0)", stdout: "Defined {value: \"Specified(9)\"}", stderr: "", blocked: "false"}
  PLANT OK   [E6 Undefined whole-line token unchanged] -> UB:{ub: "UB036_exceptional_condition", stderr: "", loc: "<t.c:2:10>"}
  PLANT OK   [E7 no token from a truncated Defined line] -> 
test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: same-value/different-stdout and different-stderr yield distinct whole-line tokens, escaped payload byte-exact, multi-outcome order kept, embedded text is payload, Undefined unchanged, truncated line is no token)
```

### F3.3 The four Tier A lanes, re-run with the widened extractor

Movement was EXPECTED by the brief. Result: NONE. Verbatim (each lane
`--check-baseline`, LADDER Tier A rows 2, 3, 4, 4b; env.sh sourced;
`CERB_MEM_MAX=48G`; sequential):

```
tests/minimal  SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
               Baseline check: 0 regression(s), 0 improvement(s)
               BASELINE OK
tests/coverage SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
               Baseline check: 0 regression(s), 0 improvement(s)
               BASELINE OK
tests/debug    SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
               Baseline check: 0 regression(s), 0 improvement(s)
               BASELINE OK
tests/float    SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
               Baseline check: 0 regression(s), 0 improvement(s)
               BASELINE OK
```

All four `lane rc=0`. No row moved, so no re-baseline commit exists and no
new pending row is registered from these lanes.

Why zero movement is what these lanes CAN show, and what they did exercise:
the lanes run `--nolibc` on the execution side, so almost every `Defined`
line has `stdout: "", stderr: ""` — the widening can only move a row whose
output bytes differ. The widened token WAS in effect (the MATCH lines carry
it, e.g. `[1/212] MATCH arith3-001-unsigned-div: VAL:{value: "Specified(0)",
stdout: "", stderr: "", blocked: "false"}`) and WAS exercised on real output
bytes in exactly four rows, all whole-line MATCH (derived: grep of the lane
logs for a non-empty `stdout:` field):

```
[93/212] MATCH io-001-printf-basic.libc: VAL:{value: "Specified(0)", stdout: "hello\n", stderr: "", blocked: "false"}
[94/212] MATCH io-002-printf-int.libc: VAL:{value: "Specified(0)", stdout: "42\n", stderr: "", blocked: "false"}
[95/212] MATCH io-003-printf-string.libc: VAL:{value: "Specified(0)", stdout: "world\n", stderr: "", blocked: "false"}
[97/212] MATCH io-005-printf-multi.libc: VAL:{value: "Specified(0)", stdout: "1 2 3\n", stderr: "", blocked: "false"}
```

No other row in the four lanes has a non-empty stdout or stderr field
(minimal 0, coverage 4, debug 0, float 0 — derived). The lanes where output
bytes really flow are the libc-mode ones, not in this slice's scope (§F3.4).

### F3.4 Findings exposed while doing F3 (none from the lane runs; two from reading)

1. **Duplicated value-only extractors** (out of scope here, listed for the
   orchestrator): the pre-repair `^Defined \{value: "[^"]*"` extractor is
   copied verbatim in `scripts/test_gcc_oracle.sh:308`,
   `scripts/test_ci_sweep.sh:172` (its libc leg has a separate whole-Defined-
   line `STDOUT_DIFF` channel, `extract_defined_lines`; the nolibc token is
   value-only), `scripts/test_cn_coverage.sh:243`,
   `scripts/test_multi_tu.sh:114`; and `scripts/test_verify.sh:72`
   `verdict_of` is value-only for the recorded-pin comparison (its live
   main-mode comparison at :129-135 is already whole-line). Each is an F3
   instance of its own; the audit's "shared structured verdict codec" is the
   structural fix. `test_libc_exec.sh` compares whole lines already (:115),
   `test_libxml2_uri.sh` compares oracle lines directly.
2. **Escaping divergence class, not exercised by any row** ([AGENT], by
   reading, not by measurement): `Main.lean:353` `batchEscape` folds over
   `Char`s (Unicode codepoints) and emits `\ddd` from the CODEPOINT (`48 +
   a / 100` …), while `driver_ocaml.ml:99` uses OCaml `String.escaped`,
   which escapes per BYTE. On any non-ASCII output byte the two printers
   diverge (`é` U+00E9: OCaml `\195\169`, Lean `\233`; a codepoint ≥ 256
   makes Lean emit non-digit characters). No current row prints non-ASCII,
   so no lane moved; with the widened token, the first such row will be a
   MISMATCH — a real discrepancy of the Lean printer (mirror doctrine:
   escape per UTF-8 byte). Registered in `TODO.md` (Small items) with this
   record as the cite; the mover is a probe + the one-line fix, not this
   slice.

### F3.5 Verified

The four lane runs above; `test_exec.sh --selftest` above; and the full
`test_unit.sh` after wiring the selftest in (env.sh sourced,
`CERB_MEM_MAX=48G`):

```
Total: 6 passed, 0 failed
test_exec: SELFTEST OK (E0 pre-repair collapse reproduced; E1-E7: same-value/different-stdout and different-stderr yield distinct whole-line tokens, escaped payload byte-exact, multi-outcome order kept, embedded text is payload, Undefined unchanged, truncated line is no token)
check_fuel_forms: SELFTEST OK (24 plants with the declared label — …; unplanted table green)
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (…), 13 ABSORBING = kill at zero (…), 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_fork_drift: SELFTEST OK (10 plants with the declared verdict and message: …; unplanted gate green)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
test_unit rc=0
```

(The two `…`-elided lines are quoted in full in §F2.4 / §F4.2; they are
byte-identical in this run.)

### F3.6 Not done here (by instruction)

The csmith, gcc-oracle and libxml2 lanes were NOT re-run; the orchestrator
re-runs them. Their own extractors are the duplicated value-only copies of
finding 1 above (csmith rides `test_exec.sh` and inherits the widening;
gcc-oracle does not).

## Doc updates in this slice

`lean_frontend/VALIDATION.md` (§0 "UB location is behaviour" gains the
successful-output-bytes paragraph naming the value-only copies; §4 and claim
1 no longer say every lane compares stdout; the fuel-forms gate row, the (B)
row and the RED-conditions paragraph), `lean_frontend/CLAUDE.md` (unit-test
and gate-list entries for the classifier, the fork-drift gate's fail-closed
prerequisites via the test_unit text, and the new extractor selftest),
`scripts/test_unit.sh` comments, `lean_frontend/TODO.md` (the escaping
finding). No `.lem`, no semantics, no baseline file changed.

## F3.7 Orchestrator boundary finding: the `test_fuel_plant.sh` words stub (fixed here)

The orchestrator's independent full battery on `caa03c9bf` returned
`test_fuel_plant.sh` rc=1 — the one lane the slice did not run:

```
PLANT FAIL [exec/words is a verdict row]: expected /^\[1/1\] (MATCH|MISMATCH|LEAN_ERROR) 001-return-literal/; got:
…
HARNESS ERROR: Lean verdict pattern matched but no tokens extracted for 001-return-literal
```

Cause (measured): the `stub_words` plant is a `#!/bin/sh` script using
`echo` on a line containing the escaped `\n` of the stdout field;
`/bin/sh` is dash (`readlink -f /bin/sh` → `/usr/bin/dash`), whose `echo`
interprets `\n` (`sh -c 'echo "a\nb"' | wc -l` → 2), so the stub emitted
the Defined line SPLIT over two lines. The pre-repair value-only extractor
matched the first fragment and never noticed; the whole-line extractor
refuses a truncated Defined line (plant E7) and the harness fails closed.
A plant defect, not an extractor defect: the real drivers escape and
never emit a raw newline inside a verdict line. Fix: the stub uses
`printf '%s\n'`. Re-run (env.sh sourced, this worktree):

```
PLANT OK   [exec/words no FUEL row]: no /^\[1/1\] FUEL /
PLANT OK   [exec/words is a verdict row]: [1/1] MISMATCH 001-return-literal: Lean=VAL:{value: "Specified(0)", stdout: "lem: fuel exhausted\n", stderr: "", blocked: "false"} Cerberus=VAL:{value: "Specified(42)", stdout: "", stderr: "", blocked
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
```

(The words row is now a MISMATCH on the stdout field — the widened
comparison at work; before, the same two lines compared MATCH-by-value.)
