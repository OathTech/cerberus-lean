# VALIDATION — why you should trust this semantics

An executable semantics is trusted for what it has been *checked*
against, and this document is the honest inventory: what is compared,
against what, how often, and what the gates guarantee. There is no
proof that the Lean port equals the OCaml implementation — the OCaml
side cannot be reasoned about, only compared against — so the
validation story is (a) **structural**: both implementations are
generated from one Lem model, and the hand-written residue mirrors
its OCaml counterpart line-by-line; and (b) **empirical**: an
industrialized differential-testing surface with pinned, fail-closed
baselines. A green build is never the signal; the differential
baselines are.

## 1. What is compared, against what

**The oracle.** The OCaml Cerberus in this repository, built from the
same `.lem` sources (`make prelude-src` + dune). It is an *immovable
object* on the trust boundary: every differential lane runs a program
through both implementations and compares **full verdict lines** —
`Defined` values, exact undefined-behaviour codes, errors, stdout/
stderr where applicable — over the exhaustive nondeterministic
enumeration (or matched single traces, where a lane says so).

**Upstream, as a third point.** An un-forked upstream checkout
(`deps/cerberus-upstream` in the working layout, pinned at the fork's
merge-base) separates "our fork's behaviour" from "upstream's
behaviour": fork regressions and upstream bugs are attributed, not
conflated. Several oracle-wrong findings (Lean-right, upstream-filed)
came out of exactly this three-way instrument.

**Recorded expectations, where the oracle can't reach.** A few legs
are oracle-independent by design: the `tests/bytes` micro-lane
compares against committed upstream `.exec` records, and the
expectation files under `tests/verify`/`tests/corpus` pin previously
recorded verdicts as drift detection *on top of* the live
oracle-differential run.

## 2. The differential lanes

Normative tiers (what runs when) live in `scripts/LADDER.md`. The
lanes, with their recorded states:

| Lane | Corpus | Bar |
|---|---|---|
| `test_exec.sh --check-baseline` | upstream `tests/minimal` | 106/106 at the pinned baseline |
| `test_exec.sh` (coverage/debug/float baselines) | upstream suites | rc 0 at pinned baselines (recorded DIFFs unchanged) |
| `test_bytes.sh` | `tests/bytes` | 9/9 at committed upstream `.exec` records + 5/5 reject pins (oracle-independent) |
| `test_parse.sh` | tests/minimal + tests/ci | Cabs-JSON bridge, 234 files, 100% |
| `test_core.sh` | tests/minimal (+ tests/ci) | Core text parser vs oracle `--pp=core`, 106/106 minimal |
| `test_elab.sh` | elaboration corpus | recorded same/diff state, rc 0 |
| `test_multi_tu.sh` | `tests/multi_tu` | multi-TU linking differential, all entries |
| `test_libc_exec.sh` | `tests/libc_exec` | libc-linked execution at the committed baseline |
| `test_libxml2_uri.sh` | 16 URIs, 5 TUs, libc | **16/16 byte-identical** lean+libc vs oracle+libc, pinned per-lane expectations |
| `test_libxml2.sh` | libxml2 `chvalid` battery | 4 slices × 1,354 points, byte-equal verdicts (slow tier) |
| `test_cn_coverage.sh` | `deps/cn/tests/cn` | **213/213** at the exact-match baseline (multi-TU drivers, reject lane, manifest bijection) |
| `test_immaculate.sh` | curated pin suite | at baseline (incl. adversarial pins, e.g. the symbol-hash-collision tripwire) |
| `test_verify.sh` | `tests/verify` + `corpus/` | pin provenance (oracle `--pp=core` re-derivation byte-identical / content-hash) + main-mode differentials + per-function call-point differentials (Lean `--call` vs oracle wrapper TU vs recorded pin) — currently 117 checks |
| `test_speclab*.sh` (6 scripts) | rendered harness families | five families (scalar/bytes/list/tree/CN-seed): sweeps, deterministic fuzz with byte-wise shrinking, plant tests, pinned-term gates — ~2,000 recorded differential executions, all agreeing |
| `test_csmith_corpus.sh` | 1,669 in-tree csmith programs | classified pinned baseline (sharded; reporting tier full-pass) |
| `test_ci_sweep.sh` | 2,186-file upstream CI suite | reporting instrument; recorded sweep: zero mismatches among 1,316 comparable files, 1 new defect found (recorded) |
| `fuzz_csmith.sh` | generated csmith programs | deterministic seeded fuzz kit (reporting tier) |

Lane semantics worth knowing:

- **Baselines fail closed in both directions.** A regression fails;
  an unexplained improvement also fails (silent movement is how
  errors hide). Baseline updates are instrument changes: dedicated
  commit, justification in the header.
- **Plant tests.** Gates and lanes are themselves tested by
  deliberate sabotage: break the thing the gate should catch, watch
  it go red, revert, re-verify green. A gate that has never caught a
  plant is treated as untested code.
- **The oracle guards itself.** The single-supply backstop
  (`CERB_FRESH_FLOOR_VIOLATION`, exit 70) makes a mis-built oracle
  refuse loudly rather than compare wrongly, and the lem-sync
  content-hash gate makes a stale generated tree a build failure on
  both the OCaml and Lean sides.

## 3. The build-time gates (`scripts/test_unit.sh`)

Unit executables (parser tests, pretty-printer mirrors vs recorded
OCaml output, fresh-symbol/native-extern probes, effect/totality
proof exemplars), then the gate scripts — all fail-closed:

| Gate | Guarantee |
|---|---|
| sync gate | every hand-written file byte-identical to its compiled `generated/` copy (the binary corresponds to the sources) |
| `check_exec_purity.sh` | the execution slice is free of unsanctioned IO/effects |
| `check_theorem_axioms.sh` | hand-written axiom census **zero**; generated-tree census: zero axioms, the two boundary opaques (`with_tagDefs`/`forceIO` — kernel-checked inhabitants with native `@[implemented_by]` bindings) present exactly once, zero `unsafeCast`; exemplar + `driver2` axiom cones free of `sorryAx`/`ofReduce*`/DAEMON; non-kernel decision procedures (`native_decide`/`bv_decide`) grep-banned |
| `check_exec_totality.sh` | zero `partial` definitions on the execution path (empty allowlist; fuel-totalized recursion with loud exhaustion) |
| lem-sync gate | generated trees content-in-sync with the `.lem` sources (stamped; also wired into the dune graph for the libc `.co` artifacts) |
| `check_fork_drift.sh` | the fork's oracle-side surface equals a reviewed manifest, and generated-OCaml fork-vs-upstream deltas match pinned hashes |
| `check_fixture_freeze.sh` | the `corpus/` differential-fixture set matches its hash manifest exactly (additions included) |

Certification-integrity rules ride the gates: validation of
build-rule-affecting changes is cache-disabled from re-derived
generated trees; audits check the artifact the consumer actually
loads (the libc.co staging pattern); quoted outputs are verbatim.

## 4. How often

Per `scripts/LADDER.md`: Tier A (every commit) = `test_unit.sh` +
the exec baselines + bytes + libc_exec + multi_tu + parse + core +
elab + the uri gate + cn_coverage; Tier B (slice boundaries,
pre-merge) adds the full libxml2 battery and the tests/ci suites;
Tier C are the committed reporting instruments (ci sweep, csmith
full pass, fuzz). `test_verify.sh` and the speclab lanes run with
the full battery at boundary claims.

## 5. What this does and does not establish

Differential testing samples behaviour; it never proves equivalence.
The claims this validation surface supports are exactly:

1. On every corpus above, the Lean port and the OCaml implementation
   produce **identical verdicts** (to the recorded baseline
   exceptions, each classified and pinned).
2. The artifact you tested is the artifact you built: sync,
   lem-sync, staging, and fork-drift gates close the
   "verified-vs-loaded" gaps.
3. The execution path is total, effect-honest, and axiom-clean as a
   Lean artifact (§3) — properties of this port, checked by the
   build, independent of the oracle.

What remains on the trust boundary: the OCaml oracle itself (and
upstream's correctness), the C parser (shared, upstream), the Lem
compiler and its Lean backend (attacked structurally by the shared
model + the mirror discipline + these differentials), the Lean
toolchain, and the native externs behind the two boundary opaques.
Known limitations are tracked in [TODO.md](TODO.md) (e.g. the
step-runner stack ceiling; concurrency is a stubbed, documented
boundary).
