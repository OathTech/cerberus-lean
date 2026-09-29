# SC WP1 — independent skeptical review (decision, package, plan update)

> **Mainline copy — decision record only (landed with the SC plan, L0).**
> [USER 2026-09-29] ruled that WP1's code does not land: this record lands as
> documentation, and S1 starts fresh from mainline with a single stepper in
> Lem. The code, tests, probes and `sc-wp1-evidence/` files this record cites
> are **not on mainline**; they remain at `arc/sc-wp1` `186392a53` (read them
> with `git show 186392a53:<path>`). The text below is unchanged from
> `review/sc-wp1-20260928` `1c7e52fad` except that links to files not on mainline are shown as plain paths.
> Current state and the 2026-09-29 rulings:
> [SC-CONCURRENCY.md](../../SC-CONCURRENCY.md) and
> [the 2026-09-29 assessment record](2026-09-29_sc-assessment-and-rulings.md).

[AGENT — independent skeptical review, Claude Fable subagent, 2026-09-28.]
Fresh reviewer: I authored none of the range. Charter (relayed by the
orchestrator): [USER 2026-09-28] "WP1 + plan update", "Targeted re-runs".

**Heads reviewed.**
- WP1 range `5ecc0aa33..af1342d32` on `arc/sc-wp1` = `73c1419ae`
  (docs: branch entry) + `5470b9c75` (boundary diagnostic) + `b52f9e660`
  (bounded stepping, shared-Lem factoring) + `af1342d32` (decision +
  evidence). 68 files, +7701/−30 (`git diff --stat`, derived).
- Plan update `8730055b7` on `arc/sc-concurrency` (`SC-CONCURRENCY.md`
  and `lean_frontend/docs/2026-09-24_sc-concurrency-design.md`;
  `git show --stat`, verbatim: "2 files changed, 140 insertions(+), 54
  deletions(-)"), read against its parent `a735382c6` and against the WP0
  landing `5ecc0aa33`.
- Review worktree `review/sc-wp1-20260928` at `af1342d32`; the plan update
  was read via `git show`/`git diff` only; `arc/sc-concurrency`,
  `arc/sc-wp1` and other worktrees were not checked out or modified. The
  mainline checkout `cerberus-lean/` (`d62f52121`) was used READ-ONLY as
  the pre-WP1 oracle binary (§2.3); its `driver.lem` equals `5ecc0aa33`'s
  (`git diff --stat 5ecc0aa33 d62f52121 -- frontend/model/driver.lem`
  empty).

**What I did.** Read every non-evidence file of both ranges in full and
the production Lem/OCaml the tests and proofs claim to be about
(`step_ctx`, `driver2`, `driver_globals`, `process_core_step2`,
`advance_step`, `do_race`, `one_step_unseq_aux`, `add_exclusion`,
`subst_wait_stack`, `nondeterminism.lem`, `smt2.ml`). Regenerated both
generated trees from the committed `.lem` with the pinned lem and rebuilt
OCaml + Lean (cache-disabled). Re-ran WP1's three gates, the fork-drift
gate, the fuel-numerals gate, Tier A rows 1 and 2, all 21 axiom cones
(my own probe), the orphaned boundary probe, a pre-WP1-vs-WP1 oracle
debug-output differential, an OCaml micro-probe against the built
library, and four plants (three Lean-side, one shared-Lem regenerated
into both targets), each followed by revert + rebuild + re-gate.
Cross-checked every recorded source hash in the 9 evidence JSONs against
the committed blobs at the heads they name; byte-compared every fresh
transcript against the committed `sc-wp1-evidence/*.txt`.

**What I did NOT do.** No full A+B battery, no 872-case three-engine
report (landing's job, per charter); no par-block (`{-{ … ||| … }-}`)
oracle run (M1's observability question is stated as unmeasured); no
build of `backend/web` (N9). The three-engine counts in the records are
the records' claims (raw reports are uncommitted; same limit as the WP0
review).

**Grades.** BLOCKER · MUST (fix before the thing it names lands) · SHOULD
· NOTE. Each finding says whether its premise was verified by measurement.
"Derived" marks tallies I computed; quoted verdict lines are verbatim.

---

## 0. Review-setup finding (read first)

The "build-primed" review worktree carried BOTH generated trees from the
base, not from `af1342d32`. Before any regeneration, on the pristine
worktree (verbatim):

```
check_fork_drift: FAIL — core_reduction.ml: excused-diff hash moved (manifest f76425e20820468aad186a6369f1ce4528f4b662641e1dbaa7209a2b59b8160c, live bad2eba7e2838b9a7c224bbbd2b1569ecf9f93a09760630a57f751539ee37e47) — the fork-vs-upstream delta of this generated file CHANGED; re-review the .lem change (stale-build caveat as above), then refresh deliberately
check_fork_drift: FAIL — driver.ml: excused-diff hash moved (manifest 82bc7996e052cac67ee7b83ca135b2059e83c06ef638cc57c4e9d1badc1affa4, live 7f4a46468889d03e9b0ad984967babbd664174124e428526230cdffb67400e92) — the fork-vs-upstream delta of this generated file CHANGED; re-review the .lem change (stale-build caveat as above), then refresh deliberately
CERB_LEM_SYNC_STALE: frontend .lem sources changed since Lean generation (stamp src ea7c8e8524f09709dc8f178275a41264ff1145b0c64a55837a78d1cb1beeb4a7, tree 9828df10065f3606bf8e55e861b938fc5a28448fa20b45c29af99385b506d451) — lean_frontend/generated is STALE
CERB_DRIVER_STALE: hand-written source lean_frontend/CerbFS.lean not propagated to generated/ (run make lean-prelude-src) — 1 drift(s), 0 unlisted file(s)
```

`lean_frontend/generated/Driver.lean` was `72d0d25f…` (the WP0-era
identity recorded in `boundary-identities.json`), with 0 occurrences of
`experiment_step`. A reviewer who "re-ran the gates" without first
noticing this would have gated the WP0 semantics against WP1's manifest
and tests. This is a provisioning/process finding (N1), not a WP1 defect;
every measurement below was taken AFTER `make prelude-src
lean-prelude-src` + OCaml + Lean rebuild. The regeneration reproduced the
recorded generated-file identities byte-for-byte (§4.2) — good
reproducibility evidence for the package.

---

## 1. Findings, most severe first

No BLOCKER.

### M1 — MUST (plan update `8730055b7`) — S1's "shared-Lem repairs" are upstream behaviours and the plan does not carry the process the zero-discrepancy doctrine requires for changing them

The plan update commits S1 to "Repair positional fork results and
modern-stack wait substitution in shared Lem" (`SC-CONCURRENCY.md` S1 row;
"S1 must also repair the measured inherited fork-result reversal, missing
modern-stack wait substitution …"; design doc S1 row likewise). The
decision record §5 item 1 says the same ("Shared-Lem fork-result order and
modern-stack wait substitution repairs"). Verified by source reading:

- The tid accumulation is byte-identical in pristine upstream:
  `deps/cerberus-upstream/frontend/model/driver.lem:570-573`
  `State.foldlM (fun (th_tids_, core_st_) th_st -> … (tid :: th_tids_, …)) ([], …) spawn_th_sts`
  = fork `driver.lem:83-86`.
- "Missing" modern-stack substitution is an EXPLICIT upstream refusal, not
  an omission: `deps/cerberus-upstream/frontend/model/core_run_aux.lem:101-102`
  `| Stack_cons2 _ _ _ -> error "subst_wait_stack ==> Stack_cons2"`
  = fork `core_run_aux.lem:101-102`.
- `Epar` IS reachable from the C front end, but only through Cerberus's
  non-ISO par-block extension: `frontend/model/translation.lem:4203-4209`
  `| A.AilSpar ss -> … (C.Expr [] (C.Epar core_ss)) …` with an empty
  pattern over `BTy_tuple (replicate … BTy_unit)` — the Epar VALUE order is
  unobservable from C (all units); the child-tid assignment order may be
  observable through traces/scheduling. NOT measured (no par program run).

Consequences: both "repairs" are fork-vs-PRISTINE shared-model changes on
a C-reachable path. The repo's rule for those is a
`scripts/upstream_oracle_differences.json` `shared-model-fix` row with an
upstream-tray draft and an explicit [USER] adjudication (four-aims
tie-breaker: fix+log only on STRONG evidence — and "ISO evidence" does not
apply to an extension construct). The plan names none of this; it reads as
an already-adjudicated obligation ("must repair"). Failure scenario: S1
lands a `subst_wait_stack` `Stack_cons2` arm and a reversed tid list in
shared Lem; the pristine lane (Tier B row 10) or a par-block corpus case
goes `difference` with no register row, or — worse — the change is admitted
as "a repair" without the operator ever ruling on a fork-vs-upstream
semantic divergence. Fix (docs-only, one paragraph in `SC-CONCURRENCY.md`
"WP1 decision: constraints" and the S1 rows): state that these are
upstream behaviours; that any change is a `shared-model-fix` register row
+ tray draft + [USER] ruling BEFORE implementation; and replace "missing
modern-stack wait substitution" by "upstream's explicit
`subst_wait_stack ==> Stack_cons2` refusal". The candidate Lean-side
adapters (`SCWP1Decision.lean:138-141` `tids.reverse`, `:94-105`
`substContext`/`substStack`) are fine as experiments and disclosed as
such.

### M2 — MUST before the Lem factoring lands on mainline (code package) — experiment code and a `step_kind` constructor in the shared production model, placed there to avoid a gate, with no reconciliation to [USER 2026-09-04]

`frontend/model/driver.lem` gains +247 lines: `SK_core_boundary` (a new
constructor of the shared `step_kind`, rendered by `backend/web/instance.ml`),
`driver_globals_with`/`drive_with`, and the `experiment_*` types and
functions (54 `experiment_` identifiers generated into
`ocaml_frontend/generated/driver.ml`, derived grep). `core_reduction.lem`'s
hot `step_ctx` is refactored to continuation-passing (`forall 'a … -> 'a`)
with `step_ctx_at`/`step_contexts` consumers. All of it is compiled into
the OCaml oracle; the sequential entry never calls the experiment. The
bounded-stepping record's stated reason for co-locating the experiment in
`driver.lem` (verbatim): "The fork-drift gate requires the generated
module set to match upstream, so this instrument stays with its driver
integration rather than changing the gate for a new experimental module."
That is gate avoidance offered as design rationale. The standing ruling
[USER 2026-09-04] "we don't change the lem structure for ocaml"
(`docs/2026-09-05_typed-failure-outcomes-design.md:41`, "`.lem` bodies and
the OCaml output are not touched") is cited by NONE of the four WP1
records (`grep -i 'lem structure\|2026-09-04'` over `SC-WP1.md` and the
three dated records: 0 hits). The WP0 review raised the same class as F5
for a 21-line type; here it is an order of magnitude larger, on the
reducer's hot path, and the decision record contemplates landing it
("Its small default-driver factoring and diagnostic seeds can be reviewed
on their own merits"). Sequential behaviour: preserved by reading (§2.1)
and by measurement (§2.3, rows 1–2, the package's own 40/40 and 872-case
runs) — with the one observable movement S1 records. Fix: a reconciliation
paragraph citing the ruling and its exception argument (the 2026-09-04
ruling targeted Lean-motivated restructuring; here the change is
target-symmetric and the experiment is dead code for the oracle), plus
operator confirmation; or move the experiment to its own lem module and
refresh the fork-drift manifest deliberately (the gate has a documented
refresh path). Verified by reading and grep.

### S1 — SHOULD — The lifecycle factoring changes the oracle's debug-level ≥ 2 stderr and no record says so

Measured on the clean rebuilt WP1 oracle vs the pre-WP1 mainline oracle
(read-only), same wrapper, same two programs (`int g = 1; int main(void)
{ int x = g; return x + 41; }` and a 20-iteration loop), `--exec --batch
-d 2` / `-d 3`:

| program | binary | `ENTERING Driver.driver2` | `driver.process_core_step ==> Step_done2` | `ND2.pick` | stdout |
|---|---|---:|---:|---:|---|
| dbg.c | pre-WP1 `d62f52121` | 70 | 70 | 140 | `Defined {value: "Specified(<@empty>:42)"…` |
| dbg.c | WP1 `af1342d32` | 1 | 70 | 140 | IDENTICAL (`cmp`) |
| loop20.c | pre-WP1 | 69 | 69 | 138 | `…Specified(<@empty>:190)…` |
| loop20.c | WP1 | 1 | 69 | 138 | IDENTICAL (`cmp`) |

The full stderr diff, timings/paths normalised, is exactly the missing
`ENTERING` lines (68/69) and nothing else (derived `uniq -c` over the
diff). Mechanism, verified by source + an OCaml micro-probe: `driver2`'s
head `let () = Debug.print_debug 2 [] (fun () -> "ENTERING Driver.driver2")`
runs at APPLICATION time (the probe applied `Driver.driver2 false` twice in
the WP1 build and printed twice); `driver_globals_with` runs `ND.mapM_`
over every global definition (this linked program has 69 — the 70
`REQUEST CREATE` lines and 70 `Step_done2` completions are 69 globals +
`main`, derived) and calls `run_threads` inside the per-global body
(`driver.lem`, "(* evaluation of the initialisation *) run_threads >>= fun () ->").
Pre-WP1 that site was a fresh application `driver2 with_concurrency` per
global; now it is the ONE ND value constructed at `drive` entry
(`drive_with (driver2 with_concurrency) …`), re-run per global. The ND
value is pure (`bind (ND m) f = ND (fun st -> nd_action_bind (m st) …)`,
`nondeterminism.lem:333-338`), so execution is unchanged; the debug print
is the only construction-time effect. Lean is unaffected (`CerbDebug`
stubs). No lane runs at `-d ≥ 2`, so the three-engine report cannot see
it. It is nonetheless an unrecorded, measurable change to a documented
oracle output, and the bounded-stepping record's "Reviewed bookkeeping
changes" section is where it belongs. Fix: one sentence there (deliberate,
diagnostic-only, mechanism above), or pass a thunk
(`unit -> driverM unit`) to keep the trace identical. Verified by
measurement.

### S2 — SHOULD — All three harnesses put `timeout=180` OUTSIDE `capped`; a timeout orphans the Lean probe (measured)

`scripts/test_sc_wp1.py:28-29`, `test_sc_wp1_decision.py:41-42`,
`test_sc_wp1_source.py:43-44`: `subprocess.run(['../scripts/capped', …],
timeout=180)`. On expiry Python SIGKILLs its direct child — `capped` — so
`lean_probe.sh`'s EXIT trap and `capped`'s cleanup never run. Measured in
plant P2 (§6.2): the gate went red with
```
subprocess.TimeoutExpired: Command '['../scripts/capped', '../scripts/lean_probe.sh', 'test/SCWP1DecisionChecks.lean']' timed out after 180 seconds
```
and left `lean_probe.sh` → `capped` → `lean … --setup .lean_probe.OToQmO.json
test/SCWP1DecisionChecks.lean` running (PIDs 1979433/1979513/1979523,
`pgrep`), plus a leaked `lean_frontend/.lean_probe.OToQmO.json`; I killed
them by hand. This is the WP0 review's S1 shape, now with a measured
consequence on a shared box. Fix: `[capped, 'timeout', '--kill-after=5',
'170', …]` inside the cap (the `common.sh:398` pattern) and a larger outer
Python backstop. Not a standing gate today, so SHOULD; fix before any of
these become one.

### S3 — SHOULD — `test_sc_wp1_decision.py` checks only stdout LINE COUNTS; the committed transcripts are not gate-checked

`test_sc_wp1_decision.py:56`: `if result.stderr or len(result.stdout.decode().splitlines()) != lines`.
Unlike `test_sc_wp1.py:57` (`r.stdout != expected.encode()`, byte-exact),
nothing compares the six probes' output to the committed
`decision-*.txt`. The in-probe `require`s carry the real checks, but
several numbers the decision record quotes are print-only: `steps=`,
`peak-threads=`, `next-tid=` in `SCWP1RetentionChecks.lean:86` (the
`require`s bound `n ≤ 6`, `envs == 0`, allocations, thread count,
`accesses == 2*rounds` — not steps/peak/next-tid), and the schedule
MULTIPLICITIES in `followup-source-order.lean:76-78` (only the key set and
its length are required). A future change could move "8192 rounds …
peak three live threads … 16384 children" silently. Fix: byte-compare
modulo `elapsed-ms=` against the committed transcripts (as I did: all six
IDENTICAL, §6.1) or add `require`s for the quoted fields. Verified by
reading and by the P2 run (the only exit path taken was the timeout).

### S4 — SHOULD — `SCWP1Boundary.lean` is an orphan: run by nothing, compiled by nothing, modified after its recorded run

`boundary-identities.json` pins `SCWP1Boundary.lean` = `95dbf270…` = the
blob at `5470b9c75`; `b52f9e660` renamed its two `step_ctx` calls to
`step_contexts` (current identity `25cfca19…`). No script runs it
(`test_sc_wp1*.py`: 0 references); the `CerberusLeanTest` lib (`globs =
["Unit.+"]`) is built by no ladder target (`grep CerberusLeanTest
scripts/ tools/`: 0). So the first WP1 record's instrument has never been
re-executed at the package head by any gate. I ran it: `rc=0`, transcript
IDENTICAL to `sc-wp1-evidence/boundary.txt` (modulo the env banner). Fix:
add it to `test_sc_wp1.py`'s positive list, or mark the boundary record's
probe historical-at-`5470b9c75`. Verified by hashes and by running it.

### S5 — SHOULD — Plan wording overstates what the summary/source proofs establish

`SC-CONCURRENCY.md:98` (update): "WP1 fixes the source-frontier and
retained-endpoint contracts". What exists: prose contracts + an abstract
interface (`SCWP1Summary.Runtime`: `emit`/`copy`/`discard`/`precedes`) +
four theorems over an ARBITRARY relation `R` on a Boolean matrix
(`project_correct`, `extend_correct`, `extended_transitive`,
`dominated_read`). Nothing relates roots or parents to Core order; the
observers that feed the interface are fixture-specific by construction
(`SCWP1RacePrefixChecks.lean:26-27` "Domain-specific source observer: these
are two different operands of this actual Eunseq"). The decision record
says this plainly ("Exact retained-root baseline, not a proof of the
complete monitor, source instrumentation, or sparse representation"; "not
a general automatic source-frontier extractor"). Likewise the WP-C
checkpoint's "substantive general lemma about the riskiest link from
actual Core transitions to the chosen reference invariant": the delivered
`unseq_pairwise`/`hoisting_excludes_prior` are general and about
production definitions, but they link Core's OWN race predicate to a
relational contract, not Core to `cmm_csem`; the record concedes ("The
relation of all reachable annotations to source `sb` is still S2's
obligation"). Fix: "states"/"proposes" for the contracts; say the
checkpoint lemma is local (Core-internal), as the WP1 row's "general local
production lemmas" already does. Verified by reading the theorem
statements (§5).

### N1 — NOTE — Review-worktree provisioning (§0)

`new-worktree.sh` copies `generated/` from the primary checkout; for a
branch that changes `.lem` the copy is stale by construction. Suggest the
review brief (or the script) make `check_lem_sync.sh --check-lean` +
`check_fork_drift.sh` the first commands, or regenerate on creation.

### N2 — NOTE — Three renderings of one [USER] instruction; one in quotation marks

Decision record: `[USER, 2026-09-27] "Push forward to the end of WP1."`;
`SC-WP1.md`: `[USER, 2026-09-27] Push through the end of WP1; WP0 has
landed on main.`; plan: `[USER] Push to the end of WP1.` Record-integrity
rule: quotes are verbatim. I cannot tell which is; mark the two paraphrases
as paraphrases.

### N3 — NOTE — `scripts/lean_probe.sh:39` silences a build step (pre-existing)

`lake setup-file "$FILE" 2>/dev/null | tail -1` — the house probe recipe,
used by all WP1 harnesses, discards `setup-file`'s stderr (its non-zero
exit and an empty JSON are still fatal). Pre-dates WP1; noted because
every WP1 transcript flows through it.

### N4 — NOTE — Instrument bounds are numerals, correctly fail-closed

`SCWP1RetentionChecks.lean:45` `rounds * 28 + 10` (commented "instrument
failure threshold"), enumeration depths 32/36/40 in the check probes:
exhaustion prints `INCOMPLETE:` keys that fail the `require`s. These are
test-suite bounds under the [USER 2026-09-03] carve-out, not semantics
fuel; `check_no_fuel_numerals` passes (`347 files scanned`).

### N5 — NOTE — Candidate Lean-only adapters differ from the shared model by design

`SCWP1Decision.lean` reverses spawn tids, adds a `Stack_cons2`
substitution case, executes `Seq_cst` loads/stores through the sequential
`perform_action_request2`, and refuses ND alternatives inside pending
primitives. All disclosed in-file and in the record as experiment
restrictions; they are the seed of M1, not a defect here.

### N6 — NOTE — `backend/web/instance.ml` arm not compile-verified here

The only other exhaustive `step_kind` match (`grep -rn SK_done backend
util`) is the web renderer, updated. Whether any lane compiles
`backend/web` I did not verify; the fork's default dune build succeeded.

### N7 — NOTE — Retention instrument streams the inherited trace out per step

`SCWP1RetentionChecks.lean:77-78` resets `trace := []` and
`observations := some []` after every step, so its "bounded" counts
exclude the inherited driver trace by construction; the record says so
("It does **not** prune semantic environments …"; "streams diagnostic
receipts and ordinary driver trace output after each step"). Fine, as
long as no later document quotes the counts without that clause.

---

## 2. Semantic changes to shared Lem/OCaml

### 2.1 Sequential-behaviour equivalence, by reading

- `core_reduction.lem`: `step_ctx … use = … use (function … end)` with
  `step_contexts … th_info = step_ctx … th_info (fun interpret -> List.map interpret (get_ctx (snd th_info).arena))`.
  `th_info = (parent_tid_opt, th_st)`, so `(snd th_info).arena = th_st.arena`;
  the `eval_pexpr`/`full_eval_pexpr'` closures are constructed before `use`
  exactly as before; the interpreter lambda is textually unchanged (the
  generated OCaml keeps the `Core_reduction.step_ctx.(fun)` frame, which
  is why the record reports six legacy backtraces preserved). Every
  production call site (`drive_nonmemory_steps_aux{,2}`, `driver2`'s
  filter, the commented alternatives) now names `step_contexts`. Pure;
  equivalent.
- `driver.lem`: `driver_globals with_concurrency file = driver_globals_with (driver2 with_concurrency) file`;
  `drive with_concurrency file arg_strs = drive_with (driver2 with_concurrency) with_concurrency file arg_strs`.
  The two lifecycle sites that applied `driver2 with_concurrency` now use
  the shared value `run_threads`. Equivalent as ND values (pure state
  functions); the construction-time debug print moves (S1).
- The `experiment_*` section has NO failure leaves: `grep 'error\|failwith'`
  over it returns only the `Exp_killed of ND.kill_reason driver_error`
  type and the `Step_error2 why -> ND.return (Exp_refuse why)` pass-through.
  `experiment_program`'s `NDstep SK_core_boundary [(_, continuation)]`
  arm is guarded by a total fallthrough. Nothing in the sequential path
  references it (`drive`/`driver_globals` call graph unchanged; the only
  callers are the tests and `sc_step_probe.ml`).
- `experiment_at`/`experiment_run` carry `termination_argument = automatic`
  (structural on lists); no new fuel'd worker, no fuel numeral.

### 2.2 Gate evidence on the rebuilt tree (this review)

```
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 matches lem -v c2a68e7 (hex prefix))
```
Tier A row 1 (`./scripts/test_unit.sh`, rc 0): `Total: 16 passed, 0 failed`
and, verbatim, `check_failure_reach: OK (239 pure failure sites = the 239
register rows exactly …`, `check_fuel_forms: OK (81 fuel'd workers: 62
MEASURED …`, `check_theorem_axioms: OK (effect-retirement C2 bar: zero
axiom declarations anywhere; entry cones ⊆ the standard three)`,
`check_sorry_token: OK (340 files scanned comment-stripped — generated
219, hand-written+test 86, LemLib 35; 0 sorry tokens)`,
`check_lakefile_roots: OK (218 roots = 218 generated modules + the exe
root Main; …`, `check_pin_sites: OK — lem-pin
c2a68e79b6369e19f099dfa48767319c1daf19b3 at every site …`,
`check_handwritten_sync: OK (49 hand-written files byte-identical …)`,
`check_lem_sync: OK (src 9828df100…, gen 62afebe1e…)`.
Tier A row 2 (`./scripts/test_exec.sh --check-baseline`, rc 0):
```
SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### 2.3 Oracle differential at debug levels (S1)

See S1's table. Command shape (both checkouts' own wrapper):
`./scripts/cerberus --exec --batch -d 2 <file.c>` and `-d 3`. Mechanism
probe (ephemeral `backend/memory_probe/review_driver2_probe.ml`, dune
stanza reverted, file deleted): with `Cerb_debug.debug_level := 2`,
`ignore (Driver.driver2 false)` twice printed `(debug 2): ENTERING
Driver.driver2` twice.

---

## 3. The execution decision

### 3.1 Is the construction supported?

Yes, at the level the record claims. The chain is: (i) the boundary
diagnostic shows the existing driver executes effects during "discovery"
(`new_drive_core_threads` runs the store; verbatim transcript re-produced
here, S4); (ii) the shared-Lem stepper shows a selected reduction can be
taken with structural discovery, an explicit schedule, and the real
lifecycle (paired native/Lean transcripts byte-identical, §6.1);
(iii) two production-callback counterexamples (`SCWP1RMWContinuation`)
kill "save the callback and resume anywhere"; (iv) the Lean-only
candidate shows an owned pending RMW interleaving with another thread,
current-memory update, sibling exactly once, call indivisibility,
publication with read-dependent control, first conflict before a looping
operand, and 8192-round churn with fixed retained counts. The alternatives
table (§4 of the record) is fair: each rejection cites a measured
counterexample or the plan's fixed constraint 1; "bare expansion" is kept
as a comparison with its gap (no call-indivisibility mechanism) named.
Two candid limits matter for landing: the candidate refuses ND
alternatives inside pending primitives (`observe`, `SCWP1Decision.lean:78`)
and executes SC accesses through the sequential handler; both are declared
S1/S3 work.

### 3.2 WP1 exit criteria (`SC-CONCURRENCY.md` §3, WP1 row)

| Criterion | What exists | Met? |
|---|---|---|
| Independently derived source relations / first conflicts | Nine finite fixtures with hand-specified expected trace SETS from stated declarative rules (unseq adds no edge; weak orders positive; strong orders both), all-choice enumeration, fail-closed `INCOMPLETE`; publication traces derived from `d<p` + read value; first-conflict via a fixture-specific observer | Met for the finite fragment. Independence is genuine (expectations are not recorded runs). Not a general relation; the record says so. |
| Substantive summary invariant | `extend_correct`/`project_correct` (materialised induced-reachability matrix stays `Correct` under extension/projection), `extended_transitive`, `dominated_read` — over an abstract `R`; executable `Runtime` adapter | Met NOMINALLY: correct and non-trivial as representation laws (I checked a 2-root non-trivial instance elaborates), but not an invariant of the machine — no connection to Core order (S5). |
| Repeated fixed-width split/join + bounded-live-thread churn with coordinate/reference accounting | `decision-retention.txt`: 16/1024/8192 rounds, unseq and fork; `retained-roots=6 … matrix-bools=36 root-refs=6 env-bindings=0 allocations=3`, `peak-threads=3`, `next-tid=16385` (transcript IDENTICAL on re-run modulo `elapsed-ms`) | Met, with the disclosed exclusions (N7; negative-hoisting env growth unfixed and stated). |
| Singleton-step yield, pure discovery, step/run agreement | Paired native/Lean stepping incl. budgets 1/2/7/4096 and zero-budget passivity; kernel `run_append`/`run_budget`/`core_discovery` (+ `SCWP1DecisionProofs` variants); plant P3 shows `step_count` is sensitive to the shared semantics | Met. |
| WP-C checkpoint: substantive general lemma about the riskiest link | `unseq_pairwise`: production `one_step_unseq_aux` succeeds iff no cross-operand `Conflict` (any operands/footprints/exclusions); `hoisting_excludes_prior`: production `add_exclusion` excludes the hoisted negative from its path | Met in the LOCAL sense (Core race predicate ⇄ relational spec); the Core→`cmm_csem` link is open and named as S2's (S5). |

Verdict on the decision itself: the evidence supports choosing this
construction over the alternatives; it does not (and does not claim to)
establish the S1–S4 contracts.

---

## 4. Evidence integrity

### 4.1 Recorded source hashes vs committed blobs (python3 over `git show`)

Every non-generated `sources`/`tested_sources_sha256` entry in
`decision-focused.json` (19), `decision-validation.json` (40),
`stepping-validation.json` (20), `decision-paired.json`,
`decision-source.json`, `stepping-paired.json`, `stepping-source.json`,
`followup-probes.json` MATCHES the committed blob at the head each record
names: decision-era files MATCH at `af1342d32` and are ABSENT at
`b52f9e660` (the record's "parent `b52f9e660` plus staged diff
`84586e21…`" is exactly what `decision-validation.json.full_A_B.source_before`
shows: `head b52f9e6602…`, `diff_sha256 84586e21…`, `status "M SC-WP1.md\nA
lean_frontend/docs/2026-09-27_…"`, `source_unchanged: true`); stepping-era
files MATCH at both. Historical pre-rebase records (`stepping-source.json`,
`followup-probes.json`) carry `CerbMem.lean 075f4ebc…` (pre-WP0-landing)
and are labelled historical in the records. `boundary-identities.json`
pins the 5470b9c75 probe (S4). `stepping-validation.json`'s two manifest
hashes are pre-rebase identities: `eda62603…` (the tested working tree on
the `88904d8cf`-based run) and `201af051…` (after the comment-only repair,
`active_sections_byte_identical: true`, gate re-run recorded) = the
manifest committed at pre-rebase `171e06df5` (measured); the post-rebase
manifest at `b52f9e660`/`af1342d32` is `fbe63875…`, exactly what
`decision-validation.json` records — consistent with the record's
"Historical September 26 reports keep their original identities". `decision-validation.json`: `mode full`, `status
passed`, 40 lanes selected, `selection_complete true`, `artifact_issues []`,
`DUNE_CACHE=disabled`, `CERB_MEM_MAX=32G`; three-engine `counts
{"interface_agreement": 2, "matching_failure": 28, "reviewed_difference":
7, "semantic_agreement": 835}`, `lean_counts {"lean_agreement": 830,
"lean_both_undecodable": 12, "lean_difference": 28, "lean_not_applicable": 2}`,
`historical_lean_difference_ids_identical: true` — the record's numbers,
not recomputed (raw reports uncommitted). `earlier_attempts` retains the
deliberately interrupted 17/40 run with its reason — honest.

### 4.2 Reproducibility of the generated identities (measured)

After `make prelude-src lean-prelude-src` from the committed `.lem` with
`lem -v c2a68e7`, all seven recorded generated-file hashes reproduced
byte-for-byte: `Driver.lean c8310e2c1d0e`, `Core_reduction.lean
502f697a81f8`, `driver.ml 85ba87a29ef4`, `core_reduction.ml 3a35d0b81a76`,
`Core_run.lean c2cda9b97025`, `Core_run_aux.lean f4eccb2720c2`,
`Cmm_csem.lean 604cc2e8438a`.

### 4.3 Transcripts (fresh vs committed, `cmp`)

IDENTICAL: `decision-{operations,publication,race-prefix,reference,source-orders}.txt`,
`decision-SCWP1{Summary,SourceProofs,DecisionProofs}-axioms.txt`,
`stepping-{native,lean,rmw-continuations,source}.txt`, `boundary.txt`
(modulo env banner); `decision-retention.txt` IDENTICAL modulo
`elapsed-ms=` (fresh: 8/359/2962 ms unseq, 9/512/4096 ms fork, 9 ms — vs
recorded 7/335/2716, 8/472/3743, 8; timing only). The committed
`stepping-native-selected-fault.txt` is stdout+stderr; the fresh stderr
matches its tail verbatim (`Fatal error: exception Failure("internal error:
Core_reduction ==> Erun outside of a proc")`, frames
`Core_reduction.step_ctx.(fun) … line 1508` / `Driver.experiment_step …
line 2504` / `Sc_step_probe … line 119`).

### 4.4 Provenance and labelling

`[AGENT]`/`[USER]` present on every decision paragraph I checked; derived
tallies in the records are labelled ("derived, about 82 minutes"). N2 is
the one provenance gap. The fork-drift manifest NOTE header is `[AGENT]`
with a record pointer — correct.

---

## 5. Proofs

### 5.1 Axiom cones (my probe, all 21 public + auxiliary theorems; verbatim)

```
'SCWP1SteppingProofs.run_terminal' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1SteppingProofs.step_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1SteppingProofs.run_append' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1SteppingProofs.run_budget' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1SteppingProofs.core_discovery' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1Context.contexts_rebuild' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1Context.selected_context_rebuilds' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1Summary.project_correct' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1Summary.extend_correct' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1Summary.extended_transitive' does not depend on any axioms
'SCWP1Summary.dominated_read' does not depend on any axioms
'SCWP1SourceProofs.race_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1SourceProofs.safe_pairwise' depends on axioms: [propext, Quot.sound]
'SCWP1SourceProofs.unseq_success' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1SourceProofs.unseq_pairwise' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1SourceProofs.hoisting_ancestors' depends on axioms: [propext, Quot.sound]
'SCWP1SourceProofs.hoisting_excludes_prior' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1DecisionProofs.run_terminal' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1DecisionProofs.step_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1DecisionProofs.run_append' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCWP1DecisionProofs.choices_core_discovery' depends on axioms: [propext, Classical.choice, Quot.sound]
```
(derived: 17 standard-three, 2 `[propext, Quot.sound]`, 2 axiom-free; the
ten cones the record names are the last 15 lines' subset and equal the
committed transcripts). `grep -rnE 'native_decide|bv_decide|ofReduce|sorry|maxRecDepth|maxHeartbeats|set_option'`
over every new `.lean`/`.lean.in`: 0 hits. No `axiom`, `partial`,
`unsafe`, `implemented_by`. `check_theorem_axioms` and `check_sorry_token`
pass (§2.2). No option bumps anywhere.

### 5.2 Substance / vacuity

- `race_iff`, `unseq_success`, `unseq_pairwise`: about the production
  `do_race` (`core_reduction.lem:221-246`) and the measured fold
  `one_step_unseq_aux` (`:264-281`, the one `one_step` uses for `Eunseq`,
  `:400`), quantified over arbitrary operand lists, footprints, values and
  exclusion sets; `Safe`/`Races` are order-independent (`safe_pairwise`).
  Non-vacuous: both truth values of `Races` are inhabited (two `example`s
  in my probe elaborated), and the runtime `finite-conflict` control shows
  `do_race` true on a real case (`UNSEQUENCED:ab/ba`). Substantive, local.
- `hoisting_excludes_prior`/`hoisting_ancestors`: about production
  `add_exclusion` (`:978-997`); the `ancestors` projection of a context is
  the reviewer-chosen vocabulary, stated in-file. Substantive, local.
- `selected_context_rebuilds`: every `(ctx, focus) ∈ get_ctx e` satisfies
  `apply_ctx ctx focus = e`, by strong induction on `getCtxBound` over the
  production fuelled `get_ctx_lemFuel`/`get_ctx_unseq_aux_lemFuel`
  (kernel-only tactics). Substantive; it is what licenses fresh selection.
- `run_append`/`run_budget`/`step_count`/`core_discovery` (both
  variants): real composition/accounting laws over the generated
  `experiment_run`/`experiment_step`; `core_discovery` is "by definition"
  in the sense that discovery only reads `thread_states`, which is exactly
  the property (a memory read added to `experiment_runnable` would break
  it). P3 (§6.2) shows `step_count` fails when the shared semantics moves.
- `SCWP1Summary.*`: correct representation laws over an abstract `R`;
  `Extended` is defined to be what `extend` computes, so `extend_correct`
  is a faithful-materialisation statement, not a summary invariant of the
  machine (S5). `dominated_read` is a two-line propositional fact. Neither
  is vacuous (2-root instance elaborated).
- `SCWP1Contracts`: `def`s (Props), no theorems; `scalarWitness` is
  executable-checked by `SCWP1ReferenceChecks` against the generated
  `cmm_csem` predicates (defined + three rejections + the consistent-but-
  undefined racy control). Stated as schemas; nothing is claimed.

---

## 6. Gates and plants

### 6.1 WP1's own gates on the rebuilt tree (verbatim final lines)

```
WP1 decision: operations, publication, first-race prefix, source orders, retention, finite reference and ten axiom cones passed
WP1 stepping: native + Lean fuels 64/128 passed; both selected-fault controls detected; both SeqRMW suspension counterexamples reproduced
WP1 source stepping: seven C fixtures at fuels 256/512 passed; loop budgets 1/2/7/4096
check_no_fuel_numerals: OK (347 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
```
All run under `scripts/ce` (env.sh), `LEAN_ABORT_ON_PANIC=1` (set by the
scripts), `DUNE_CACHE=disabled`, capped Lean (`CERB_MEM_MAX=48G` for the
library rebuild). Selected-fault controls: native `rc=2`, Lean `rc=134`
(`PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: Core_reduction ==>
Erun outside of a proc`). Fail-closed review of the scripts: nonzero rc,
non-empty stderr, wrong stdout (byte-exact in `test_sc_wp1.py`, line-count
in the decision script — S3) each raise; no `2>/dev/null`; no silently
absorbing default. S2 is the one fail-closed weakness (resource leak on
the timeout path, verdict still red).

### 6.2 Plants (each: plant → gate → revert → rebuild → gate)

| Plant | Where | Gate verdict, verbatim | After revert |
|---|---|---|---|
| P1 `exact Or.inr` → `exact sorry` in `SCWP1Summary.dominated_read` | Lean test file | `RuntimeError: SCWP1Summary: axiom-cone transcript changed; inspect …` with `'SCWP1Summary.dominated_read' depends on axioms: [sorryAx]` | decision gate green (line above) |
| P2 `if owned c.pending tid then none` → `if false then none` in `SCWP1Decision.choices` | Lean test file | `subprocess.TimeoutExpired: … 'test/SCWP1DecisionChecks.lean' … timed out after 180 seconds` (rc 1). The later `#eval`s' all-choice enumerations blew up with the RMW context re-selectable; I could not confirm the intended `"owner still runnable"` `require` fired because stdout was lost with the kill. Gate red, via the timeout path → S2 | green |
| P4 `some "Specified(42)"` → `"Specified(41)"` in `SCWP1SourceChecks.lean.in` | source fixture expectation | `RuntimeError: execute failed: see …`; stderr `uncaught exception: return: wrong result` | source gate green |
| P3 `experiment_steps= cfg.experiment_steps + 1` → `+ 2` in `frontend/model/driver.lem`, regenerated into BOTH targets, OCaml + Lean rebuilt | shared Lem | fork-drift: `check_fork_content: FAIL — source-content drift inside reviewed file(s):` / `check_fork_drift: FAIL — source-content check failed`; paired: `RuntimeError: native positive probe failed; see …` with `Fatal error: exception Failure("errno init")`; kernel law: `error: test/Unit/SCWP1SteppingProofs.lean:19:77: unsolved goals … ⊢ c.experiment_steps + 2 = c.experiment_steps + 1` | regenerated (`Driver.lean c8310e2c1d0e`, `driver.ml 85ba87a29ef4` again), rebuilt, `check_fork_drift: OK …`, all three WP1 gates green, rows 1–2 green (§2.2) |

---

## 7. Policy fences

- [USER 2026-09-08] no new enumeration/literal/semantics-evaluation
  program proofs or artefact surface: the range adds no program proofs; it
  adds instruments under the later, specific SC direction ([USER
  2026-09-24/25] in `SC-CONCURRENCY.md:11-24`) and the plan's own WP1 row
  ("actual Core continuation/source-order experiments, an explicit
  step/yield and resource experiment"). Within policy; M2 is the
  lem-structure question, not this one.
- [USER 2026-09-03] no magic values: no fuel numeral outside the allowed
  sites (gate green); fixture values (65536 top, `supply 5`, budgets) are
  test-chosen; N4.
- No public SC mode: `Main.lean` unchanged (hash `7163e47a…` MATCH at
  every head), `drive`'s signature and the `with_concurrency` path
  unchanged; the experiment is reachable only from tests and
  `sc_step_probe.ml`.
- "No donor scheduler adopted by default": nothing from the failed branch
  is imported; the record says the branch remains a quarry.
- Mirror doctrine: no hand-written Lean seam changed; `sc_step_probe.ml`
  hand-mirrors `SCWP1Stepping.lean`'s fixtures and says so in its header.

## 8. `scripts/fork_drift_manifest.txt`

Header NOTE `[AGENT]` with record pointer; four rows moved (two
`[source-content]`, two layer-2). Source rows recomputed:
`7138170222f1… frontend/model/core_reduction.lem`,
`15565f50210f… frontend/model/driver.lem` — equal. Layer-2 rows verified
by the gate's own formula on the regenerated tree (`check_fork_drift: OK
… 31 differing generated files, all hash-pinned`), and shown to MOVE under
P3. Correctly scoped; the justification is the record (M2 is about the
content, not the pin).

## 9. The plan update `8730055b7`

Consistent with the WP1 record on every fact I checked: heads
(`5ecc0aa33`, `af1342d32`, `b52f9e660`), the rebased identities table,
40/40 + 872-case claims, "ten axiom cones", the S1–S4 obligations
(pending-operation ownership, current-memory update, no invented order,
deferred child completion, per-owner ND alternatives, trace streaming +
lexical reclamation, `SC_memory_model`/`SC_condition` with
`each_empty … undefined`, fenced restriction for S3, S4 lifetime
conservativity, no `true` stubs / no automatic `bigthm`). Status table
rows for WP0 (landed `5ecc0aa33`, `_Bool` repair `d61dcb9c4`) match the
mainline log. The WP1 row's exit column is carried forward unchanged and
the row now says "Complete at `af1342d32`, ready for independent review" —
accurate as a status. Defects: M1 (obligations that need the register/
tray/ruling process), S5 ("fixes the … contracts"). Residual stale
phrasing: none found (`grep 'to be decided\|leading strategy\|not yet
adopted'` over the updated files: 0; the design doc's line 9 "Open
proposals below remain proposals" is still true generically).

## 10. What I could not check, and why

- Observability of the spawn-tid order for C par blocks (M1): no par
  program run; unit-typed results make the VALUE order unobservable, tid
  order in traces not measured.
- The 40/40 A+B and 872-case three-engine runs: not re-run (charter);
  their JSON identity fields and lane statuses were inspected, not the raw
  reports.
- Whether the P2 plant's intended `require` fires before the enumeration
  blow-up (stdout lost at kill).
- `backend/web` compilation (N6).
- Which of the three renderings of the 2026-09-27 [USER] instruction is
  verbatim (N2).

## 11. Verdicts

(a) **WP1 decision — ACCEPT.** The evidence supports "selected bounded
Core steps + owned pending primitives + explicit source-causality
contracts" over the compared alternatives; the alternatives are fairly
compared with measured counterexamples; the exit criteria are met at the
feasibility-instrument level with the limits stated candidly in the record
itself (§3.2). Nothing here is SC support, and the record does not say it
is.

(b) **Code/evidence package — ACCEPT-WITH-FIXES.** Evidence integrity is
excellent (every hash matches, every transcript reproduces, generated
identities re-derive byte-for-byte, plants bite loudly incl. through the
kernel law). Fix before landing the Lem factoring on mainline: M2
(reconcile with [USER 2026-09-04] / operator confirmation, or a separate
module). Fix soon: S1 (record the debug-output movement or thunk it),
S2 (timeout inside `capped` — measured orphan), S3 (transcript check), S4
(orphaned boundary probe).

(c) **Plan update — ACCEPT-WITH-FIXES.** Faithful to the WP1 record and
carries the S1–S4 obligations forward; MUST fix M1 (the shared-Lem
"repairs" are upstream behaviours and need the register/tray/[USER]
process named), SHOULD fix S5 (wording). Docs-only; no runtime effect.

Merge/landing authority rests with the operator; nothing here is a
sign-off. [AGENT] calls throughout.

---

## Appendix — commands (from the worktree root unless noted; `CE=/home/dev/projects/cerberus-lean-proj/scripts/ce`)

```
$CE make prelude-src lean-prelude-src
$CE dune build --root . backend/driver/main.exe cerberus-lib.install backend/memory_probe/sc_step_probe.exe   # DUNE_CACHE=disabled
$CE dune install --root . --prefix "$PWD/_build/local-install" cerberus-lib ; $CE dune build --root . cerberus.install
(cd lean_frontend && CERB_MEM_MAX=48G $CE ../scripts/capped lake build CerberusLean cerberus-lean)   # "Build completed successfully (395 jobs)."
$CE ./scripts/check_fork_drift.sh ; $CE ./tools/check_lem_sync.sh --check-lean ; $CE ./tools/check_handwritten_sync.sh
$CE python3 scripts/test_sc_wp1_decision.py ; $CE python3 scripts/test_sc_wp1.py ; $CE python3 scripts/test_sc_wp1_source.py
$CE ./scripts/check_no_fuel_numerals.sh ; $CE ./scripts/test_unit.sh ; $CE ./scripts/test_exec.sh --check-baseline
(cd lean_frontend && LEAN_ABORT_ON_PANIC=1 $CE ../scripts/capped ../scripts/lean_probe.sh <probe>.lean)   # AxiomCones probe, SCWP1Boundary
./scripts/cerberus --exec --batch -d 2 <file.c>   # in this worktree and, read-only, in cerberus-lean/ (d62f52121)
```
Scratch (`.tmp/`, `lean_frontend/.tmp/`, the ephemeral OCaml probe and its
dune stanza) was deleted/reverted before commit; the worktree is clean but
for this record.
