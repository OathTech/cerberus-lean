# gcc second-oracle lane — slice record (2026-08-30)

Branch: `lane/gcc-oracle` (based on mainline a8f86112d). Worker:
gcc-second-oracle. Design decisions in this slice are [AGENT] unless
marked; quoted outputs are verbatim; tallies marked *derived* are
computed from the recorded runs.

## What was built

The first **oracle-independent** differential lane: gcc 13.3.0
(x86-64 linux-gnu) compiled native execution vs the Lean semantics,
breaking the single-oracle circularity (every prior lane compares two
artifacts generated from the same `.lem` sources; a shared-source bug
is invisible to all of them). Deliverables:

- `lean_frontend/docs/2026-08-30_gcc-second-oracle-design.md` —
  design note (written before implementation): comparability
  criteria, the implementation-profile alignment table, divergence
  taxonomy D1-D4 with triage procedures, corpus selection, the skip
  ledger rule, honest scoping.
- `scripts/test_gcc_oracle.sh` — the lane (reporting-tier; NOT wired
  into test_unit.sh or any gating battery — gating is an operator
  decision at merge).
- `scripts/gcc_oracle_baseline.txt` — baseline + skip ledger,
  1,953 rows (one per corpus file, no silent skips).
- `scripts/gcc_oracle_triage.txt` — the fail-closed divergence
  ledger (9 justified D2/ADDR entries).

## Headline numbers (the recorded baseline run)

Verbatim machine summary of the baseline-writing run:

```
SUMMARY: total=1953 compared=1879 agree=1870 agree_nd=0 triaged=9 disagree=0 o2_agree=187 skip_lean_crash=10 skip_lean_fail=7 skip_lean_timeout=11 skip_oracle=3 skip_ub=43 triaged_addr=9
```

- Corpus: 284 exhaustive-tier files (tests/minimal 106, tests/debug
  90, tests/float 69, tests/immaculate/nolibc 19) + 1,669 staged
  in-tree csmith programs (Lean `--batch --first`) = **1,953**.
- **1,879 comparison points; 1,870 AGREE, 0 DISAGREE.** The 9
  non-agreeing comparisons are all triage class D2/ADDR
  (address-observing tests/debug programs; per-file rationale in the
  triage ledger). *Derived:* 1,870/1,870 agreement on every program
  not observing addresses.
- -O2 spot tier (`gcc -O2 -fno-strict-aliasing`, stride 10):
  **187/187 O2_AGREE, 0 O2_DISAGREE**.
- tests/float: all 69 files compared AGREE — the float-width
  divergence rows of the alignment table (design note §2.3) did not
  produce an observable divergence on this corpus
  (exact-representable-value tests).
- The two oracle-wrong immaculate pins reachable by this lane now
  have a mechanical referee: `g5-decode-question` (`'\?'` = 63,
  upstream-tray #10) is `AGREE gcc=63 lean={63}` — gcc sides with the
  Lean semantics against the OCaml oracle, by instrument rather than
  by hand.

## No semantics finding

No real disagreement (class D1) between gcc and the Lean semantics
was found on this corpus. Three would-be disagreements during
bring-up were triaged to harness/comparability causes and fixed in
the harness (below); the 9 residual divergences are the documented
impl-defined address class.

## Skip ledger summary (all enumerated per-file in the baseline)

| Class | n | Account |
|---|---|---|
| SKIP_UB | 43 | deliberate UB probes (`*.undef.c`, alias/trap/lock rows) — UB-in-test, native run unconstrained |
| SKIP_LEAN_TIMEOUT | 11 | csmith files; all are `CERB_SKIP` (both-sides-slow) in the committed `exec_csmith_corpus_baseline.txt` — checked, no new class |
| SKIP_LEAN_CRASH | 10 | known fail-stop pins: immaculate g4-bswap64 (tray #12), g5-decode-multichar, offsetof pair, 097-null-ptr-arith; csmith sia_477/769 (`lem: fuel exhausted` = the committed LEAN_CRASH rows), sa_002/003/005 (translation failwithI; `CERB_SKIP` upstream-baseline class) |
| SKIP_LEAN_FAIL | 7 | libc-calling programs (073/074/libc-01/libc-02/valid-04, the known unknown-procedure class) + the g1 pointer-relational `Memory WIP` pair |
| SKIP_ORACLE | 3 | cabs-json refusals (ub-inconsistent, ub-static-reject, smx_csmith_6 — all pre-existing oracle-side classes) |
| TRIAGED_ADDR | 9 | D2 impl-divergence, per-file rationale in `scripts/gcc_oracle_triage.txt` |

Cross-checks performed: every SKIP_LEAN/SKIP_ORACLE row was matched
against the committed exec/csmith/immaculate baselines — all
correspond to already-recorded classes; none is a new Lean-side
finding. One residual worth naming: `offsetof-nested-struct.c` panics
under exhaustive `--batch` (`CerbMem.offsetsof: unknown tag`) while
`--first` returns `Specified(0)` (the immaculate baseline's pinned
row) — a mode-dependent fail-stop, enumerated here, no gcc comparison
lost (the immaculate pin already records the class).

## Triage outcomes during bring-up (all harness-side, each fixed + designed in)

1. **argv[0] convention** (`tests/minimal/076-main-argv-access.c`,
   initially `gcc=147 lean={17}`): native argv[0] was the binary
   path; Cerberus models `argv = ["cmdname"]`. Fixed by running the
   native binary via `exec -a cmdname` — the file now AGREEs
   (`gcc=17`). Environment-input alignment, not a semantics issue.
2. **ASLR flappiness**: raw-address-observing programs were only
   luck-deterministic natively, oscillating between nondet-skip and
   disagree across runs. Fixed with `setarch -R` (ADDR_NO_RANDOMIZE,
   process-scoped — no global state), making the D2/ADDR class
   stably deterministic; double-run check retained as backstop.
3. **exit(124)/timeout collision**: four csmith programs
   legitimately `exit(124)` (checksum byte
   `(0xAE355683 ^ 0xFFFFFFFF) & 0xFF = 124`), which `timeout(1)`'s
   kill convention shadows — they surfaced as impossible "native
   timeouts" on programs both Cerberus implementations complete in
   milliseconds. Root-caused via strace (the binary exits
   immediately: `exit_group(124)`); fixed with an elapsed-time
   discriminator whose residual edge degrades to a *visible* skip,
   never a silent misclassification. All four now AGREE at
   `gcc=124 lean={124}`.

## Instrument certification

- DISAGREE fatality: witnessed live (the 7 pre-triage DISAGREE rows
  → `FAILED: 7 unresolved DISAGREE row(s)`, rc 1).
- Stale-triage fatality: witnessed live (3 entries went stale after
  the argv fix → `FAILED: 3 stale triage-ledger entr(ies)`, rc 1).
- Vacuity plant: an all-skip corpus (single `.undef.c`) →
  `FAILED: zero comparisons happened — vacuous run`, rc 1.
- Regression plant: full check against a tampered baseline copy (one
  SKIP_UB row flipped to AGREE) → REGRESSION reported, rc 1.
- Committed-baseline round-trip: `--check-baseline` full run green
  (rc 0).

## What this does and does not establish

Per the design note §6: on 1,879 programs the Lean semantics'
defined-value verdict coincides (mod 256, argv/ASLR-aligned, exit
status only) with gcc-compiled native execution — a witness
independent of the `.lem` model, the OCaml oracle, lem, and the Lean
toolchain. It says nothing about UB verdicts (43 UB rows are skips by
construction), full values, or stdout; gcc is itself fallible;
csmith-tier order-independence is assumed. The lane is
reporting-tier; wiring it into any battery (and any VALIDATION.md
mention) is an operator decision at merge.

## Operational notes

- Full run ≈ 18 min single-threaded (deliberately modest parallelism;
  another worker was active on the box). `TIMEOUT_SECS=30` Lean-side,
  `GCC_RUN_TIMEOUT=5` native, per-run logs kept during the slice
  under `.tmp/` (ephemeral).
- `--check-baseline` is full-default-corpus only by design; partial
  runs (`--max`, explicit dirs) are smoke instruments and will also
  trip the (global) stale-triage check when the triaged files are out
  of corpus — loud, not silent.

## Addendum (2026-08-30): pre-merge audit response

Worker: gcc-oracle follow-up, on the branch rebased onto mainline
`8fb380c9c` (parity-detective; purely additive, clean rebase, no
conflicts). Quoted outputs are verbatim.

**Audit verdict**: professor-class audit returned MERGE-SAFE-WITH-NOTES
with two minor findings, both fixed here:

1. **Triage ledger now pins values** (audit finding 1): each entry
   carries machine-checked `gcc=<exit>` / `lean={<byte-set>}` fields;
   an entry applies only when the observed pair equals the pins, and
   on drift the row surfaces as an unresolved DISAGREE (rc 1, row
   named). Design note §4 updated.
2. **Signal/exit-conflation caveat stated at the soundness claim**
   (audit finding 2): design note §2.1/§3.1 now state, where the
   "can hide a disagreement, never fabricate one" claim is made, that
   a native signal-`k` death whose `128+k` collides with the expected
   exit byte counts AGREE — the lane's one false-AGREE channel (rare,
   real, recorded, not defended).

Also from audit notes: `timeout -k 1s` on native runs (a
SIGTERM-ignoring program can no longer hang the lane; the resulting
exit-137-past-deadline is folded into the elapsed-time timeout
discriminator), and the same-rank skip-class-churn rc-0 behavior is
now acknowledged in the design note §6 (deliberate test_exec.sh
mirror, unchanged).

**The determinism defect chain the pinning fix exposed** (two
stop-and-reports, each ruled on before proceeding):

- *Env byte-size* (stop-and-report 1): the first post-fix full run
  failed — 5 stack-local-address pins drifted (e.g.
  `intfromptr-05-to-long.c: gcc=52` vs pinned `gcc=20`) because, even
  with ASLR off, the kernel places environ+argv at the stack top;
  probe: same binary, exits 212/180/164 under three environment
  sizes. The lane had been reproducible only while harness
  invocations carried byte-identical environments.
- *AT_EXECFN* (stop-and-report 2): env normalization alone left the
  pins checkout-path-dependent — the kernel also copies the execve
  path string onto the stack and bash's `exec` absolutizes it; probe:
  same binary, normalized env, exits 148 (short path) vs 116 (long
  path). Full byte-stable recipe (env `SHLVL=0` only, argv
  `cmdname`, exec via `/proc/self/fd/9`): probe exit 244 invariant
  across outer envs, cwds and path lengths. Design note §2.1 records
  the full account.

**Rulings** (provenance):

- [AGENT] orchestrator ruling 1 (after stop-and-report 1): adopt the
  normalized native-run environment — the only fail-closed option,
  and it brings the code into conformance with the design note's
  existing §2.1 "no further env" claim (code-satisfies-committed-
  design, not a comparability-criteria change). Operator may override
  at the merge gate.
- [AGENT] orchestrator ruling 2 (after stop-and-report 2): adopt the
  fully byte-stable exec chain; AMEND triage to BY-FILE semantics — a
  ledger entry declares the file a divergence-class observer, always
  `TRIAGED_*` even when values coincide (a layout coincidence is not
  agreement; counting it AGREE would inflate the metric and arm a
  flip-to-DISAGREE trap), with the pin check unchanged; re-key the O2
  spot tier on `cksum(row key) mod stride` (phase-stable under status
  flips and corpus insertions), with ONE sanctioned baseline
  regeneration whose diff must be O2-columns only. Operator may
  override at the merge gate. Under the normalized stack, three
  entries (align-04, intfromptr-05, intfromptr-10) coincide at
  `gcc=244 lean={244}` and remain triaged per the by-file rule; all
  9 pins re-captured under the byte-stable recipe.

**Baseline regeneration check** (the sanctioned rewrite; mechanical
status-column identity against the previously committed baseline):

```
=== status-column identity check (committed vs regenerated):
STATUS COLUMNS BYTE-IDENTICAL
```

(`diff` of `awk '{print $1,$2}'` over both files, comments stripped —
zero status changes; the delta is O2-column-only, 333 rows re-phased,
sampled tier 187 -> 190, all `O2_AGREE`, zero `O2_SKIP_*`, zero
`O2_DISAGREE` — no new finding among the newly sampled files.)

**Plant tests** (instrument certification of the pin mechanism):

- Pin drift: doctored `align-02` pin `gcc=64`→`65` → run fails rc 1
  naming the row: `DISAGREE tests/debug/align-02-print-addr.c:
  gcc=64 lean={223} (TRIAGE PIN MISMATCH: ledger pins gcc=65 …)`;
  ledger restored byte-identical, clean run confirmed.
- By-file precedence: doctored `align-04` pin `gcc=244`→`245` — the
  observed value 244 lies inside `lean={244}`, yet the row correctly
  fails instead of falling back to AGREE: rc 1,
  `DISAGREE tests/debug/align-04-no-globals.c: gcc=244 lean={244}
  (TRIAGE PIN MISMATCH: ledger pins gcc=245 …)`. Restored, clean.
- Pin-mismatch fatality was additionally witnessed live (not
  planted) on real drift during the defect chain above.

**Final gate** — two consecutive full `--check-baseline` runs against
the regenerated baseline, both rc 0, `0 regression(s), 0
improvement(s)`, per-file output identical line-for-line across the
two runs (all 1,953 rows — the determinism demonstration), plus two
consecutive tests/debug runs likewise identical. Both full-run
summary lines, verbatim:

```
SUMMARY: total=1953 compared=1879 agree=1870 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=10 skip_lean_fail=7 skip_lean_timeout=11 skip_oracle=3 skip_ub=43 triaged_addr=9
SUMMARY: total=1953 compared=1879 agree=1870 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=10 skip_lean_fail=7 skip_lean_timeout=11 skip_oracle=3 skip_ub=43 triaged_addr=9
```

Status-column numbers are unchanged from the original slice
(`compared=1879 agree=1870 triaged=9 disagree=0`); `o2_agree` is 190
under the name-keyed sample (was 187 under the compared-index
stride). Gating status remains an operator decision at merge.
