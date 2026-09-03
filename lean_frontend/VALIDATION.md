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
| `test_gcc_oracle.sh --check-baseline` | tests/minimal + debug + float + immaculate/nolibc + the staged csmith tier (1,953 rows) | gcc SECOND oracle (oracle-independent): native `gcc -O0` exit status vs the Lean verdict set, `-O2` spot tier, fail-closed triage ledger; at the pinned skip ledger `scripts/gcc_oracle_baseline.txt` (regressions fatal; improvements printed at rc 0). Tier B GATE since 2026-09-02 [USER]. Load caveat: the TIMEOUT-class rows are wall-clock sensitive (TIMEOUT_SECS=30; the slowest csmith rows hand-time at ~17 s on a quiet box, and a busy box — load ≈12 at the 2026-09-02 audit — pushed one over) — a REGRESSION whose only movement is into SKIP_LEAN_TIMEOUT is re-run on a quiet box before it is read as red; no code change. |
| `test_verify.sh` | `tests/verify` + `corpus/` | pin provenance (oracle `--pp=core` re-derivation byte-identical / content-hash) + main-mode differentials + per-function call-point differentials (Lean `--call` vs oracle wrapper TU vs recorded pin) — currently 117 checks |
| `test_speclab*.sh` (6 scripts) | rendered harness families | five families (scalar/bytes/list/tree/CN-seed): sweeps, deterministic fuzz with byte-wise shrinking, plant tests, pinned-term gates — ~2,000 recorded differential executions, all agreeing |
| `test_csmith_corpus.sh` | 1,669 in-tree csmith programs | classified pinned baseline (sharded; reporting tier full-pass) |
| `test_ci_sweep.sh` | 2,186-file upstream CI suite | reporting instrument; recorded sweep: zero mismatches among 1,316 comparable files, 1 new defect found (recorded) |
| `fuzz_csmith.sh` | generated csmith programs | deterministic seeded fuzz kit (reporting tier) |

Lane semantics worth knowing:

- **Baselines fail closed in both directions** — with one audited,
  deliberate exception. In the oracle-differential exec lanes
  (`test_exec.sh --check-baseline` and friends) a regression fails
  AND an unexplained improvement fails (silent movement is how errors
  hide). The gcc SECOND-oracle lane (`test_gcc_oracle.sh`) fails on
  regressions only and surfaces improvements loudly at rc 0 (by the
  lane's own audited design: its rows classify oracle-INDEPENDENT
  gcc-agreement, where an improvement is a skip-class row starting to
  agree with gcc — e.g. after an unrelated fix lands on mainline —
  and blocking every commit on re-recording that scoreboard would
  make the gate fire on good news; the improvement is still printed,
  and re-records remain dedicated instrument commits). Since
  2026-09-02 [USER] the lane is a Tier B GATE on that asymmetric
  contract: rc must be 0 at slice boundaries / pre-merge. Baseline
  updates are instrument changes: dedicated commit, justification in
  the header.
- **Plant tests.** Gates and lanes are themselves tested by
  deliberate sabotage: break the thing the gate should catch, watch
  it go red, revert, re-verify green. A gate that has never caught a
  plant is treated as untested code.
- **The oracle guards itself.** The single-supply backstop
  (`CERB_FRESH_FLOOR_VIOLATION`, exit 70) makes a mis-built oracle
  refuse loudly rather than compare wrongly, and the lem-sync
  content-hash gate makes a stale generated tree a build failure on
  both the OCaml and Lean sides.
- **The tolerated renumbering class (upstream divergence, declared).**
  The effect-retirement arc replaced the ambient fresh-symbol counter
  with explicit supply threading; the oracle's dynamic draw SEQUENCE
  moved on affected inputs (eager-batch dispersal — statement lists,
  call-argument batches, elaboration prefixes), so the fork's oracle
  Core dumps diverge from un-forked upstream **textually,
  up-to-renaming of symbol ids, on affected inputs** — same term,
  bijectively renamed, verdicts everywhere unmoved. Ruled TOLERATED
  [USER 2026-08-31, re-affirmed over the enlarged class 2026-09-01]
  with a standing operator principle: output depending on symbol
  numbering beyond binding identity is itself a defect (registered
  finding + upstream candidate, never accommodated). The affected pin
  set and its one-time rebaseline: every moved artifact was admitted
  only on machine-checked same-draw-count + permutation-only
  equivalence (`scripts/check_renumber_only.py`, itself plant-tested
  by `scripts/test_renumber_plants.sh`); the enumeration lives in the
  C1/C2 rebaseline commits and `scripts/fork_drift_manifest.txt`'s
  header note. One numbering-dependent output site was found and
  registered (finding C1-F2: a libxml2-uri diagnostic embedding a raw
  symbol id — upstream candidate; the oracle's own diagnostic does
  the same). Records: `docs/2026-08-31_effect-retirement-design.md`
  §3.6/§9, `docs/2026-09-01_C1-adoption-record.md`,
  `docs/2026-09-01_C2-ratchet-record.md`.

**Per-test resource limits (all differential harnesses).** Every
oracle, cabs-json and Lean invocation runs under `timeout` (lane-
specific, 15–30 s) and — since mem-scale S2 (2026-09-02, Q2 [USER
2026-09-02]) — under a per-test cgroup RESIDENT-memory cap,
`scripts/common.sh` `CAPPED_TEST` → `scripts/capped` with
`CERB_TEST_MEM_MAX` (default 4G), replacing the arc-5 `ulimit -v 4000000`
(a virtual-address-space cap that killed Lean at ~1.7 GB RSS while the
oracle ran to 3.1 GB — record `docs/2026-09-01_mem-scale-profile.md` §2).
The two failure classes are LOUD and distinct in every lane: exit 124 with
CPU/wall < 0.1 is `HANG` (S0); a cap breach is exit 137 WITH capped's
OOM-KILLED witness banner (the cgroup's `memory.events oom_kill`
counter) and is the lane's KILL class (`LEAN_KILL`/`CERB_KILL`, `KILL`,
`SKIP_GCC_KILL`, "FAIL: … OOM-KILLED") — never agreement, never a skip;
a bare 137 without the witness keeps its crash/compare class. Plants:
`scripts/test_hang_plant.sh`, `scripts/test_kill_plant.sh`.

## 3. The build-time gates (`scripts/test_unit.sh`)

Unit executables (parser tests, pretty-printer mirrors vs recorded
OCaml output, fresh-symbol/native-extern probes, and the compile-time
totality/reader-lifting exemplars `effects-proof-test` /
`totality-proof-test`: every fuel'd wrapper rfl-defeq to its worker at
`lemDefaultFuel`, symbolic equations on the total layout defs,
`tagDefs` an honest parameter — properties of the exec cone as built;
and `fuel-exemplar-test`, the FUEL arc's consumer-shaped ∀-fuel theorem
over the shipped fuel-parametric pipeline `CerbND.drive_lemFuel`, §5),
then the gate scripts — all fail-closed:

| Gate | Guarantee |
|---|---|
| sync gate (`tools/check_handwritten_sync.sh`) | every hand-written file byte-identical to its compiled `generated/` copy (the binary corresponds to the sources); copy set enumerated from `lean_frontend/handwritten_copy.manifest`, the same list the Makefile copies from; every `lean_frontend/*.lean` must be listed; empty set = FAIL. Also a precondition of `build_lean` and of the driver-freshness stamp's Lean record/check (2026-09-02 gap: a green stamp over a stale-copy binary) |
| `check_exec_purity.sh` | the execution slice is free of unsanctioned IO/effects |
| `check_theorem_axioms.sh` | **zero `axiom` declarations anywhere** — hand-written census, generated-tree census, and the recursive census of the consumed LemLib package copy (the effect-retirement end state: `runEffectful` is deleted, `declare {lean} effectful` is refused by lem itself); `runEffectful` token-banned (comment-stripped) across all three trees; the `@[implemented_by]`/`unsafe`/`unsafeBaseIO` seam population pinned to `scripts/unsafebaseio_allowlist.txt`'s PIN rows exactly, both directions (a new seam fails naming itself — this bans an axiom-free reintroduction of the effect projection); the boundary-OPAQUE POPULATION pinned exactly-once, both directions (26 registered rows — the digest/config/util/enum/MemValue seams and the FUEL arc's pure `CerbFuel.fuelExhaustedLoc`; an unregistered `opaque` fails naming itself); zero `unsafeCast`; exemplar + `driver2` cones free of `sorryAx`/`ofReduce*`/DAEMON; the FUEL arc's contract lemmas (`CerbND.*_lemFuel_zero`, runner leaves, wrapper `rfl`s, `drive_wrapper_defeq`) and the exemplar theorem at the exact allowlist; the full exec-entry set (`driver2`, `drive`, `initial_driver_state`, `desugar`, `annotate_program`, `translate`, `link`, `convert_file`, `CerbCall.driveCall`) at the **exact** axiom allowlist `[propext, Classical.choice, Quot.sound]`; non-kernel decision procedures (`native_decide`/`bv_decide`) grep-banned. Source-scan legs are the primary evidence; the `#print axioms` probes are end-to-end spot checks (they underreport across `partial def` boundaries) |
| `check_sorry_token.sh` | zero `sorry` TOKENS in source text — comment- and string-stripped — over `generated/`, the hand-written seams + tests, and the consumed LemLib copy (the axiom gate probes `sorryAx` in cones only; the tree's last `sorry`, cmm_op.lem's target_rep, was closed by the FUEL arc). Empty scan set = FAIL |
| `test_fuel_classifier.sh` | the one FUEL classifier (`scripts/fuel_classify.sh classify_fuel_outcome`) reads its fixture captures correctly: both fuel forms positive; a genuine `Error` kill, a PANIC without the marker, and program stdout carrying the words all negative (§5) |
| `check_exec_totality.sh` | zero `partial` definitions on the execution path (empty allowlist; fuel-totalized recursion with the distinguished fuel-exhaustion outcome, §5) |
| lem-sync gate | generated trees content-in-sync with the `.lem` sources (stamped; also wired into the dune graph for the libc `.co` artifacts) |
| `check_fork_drift.sh` | the fork's oracle-side surface equals a reviewed manifest, and generated-OCaml fork-vs-upstream deltas match pinned hashes |
| `check_fixture_freeze.sh` | the `corpus/` differential-fixture set matches its hash manifest exactly (additions included) |
| `test_renumber_plants.sh` | the rebaseline-admission instrument (`check_renumber_only.py`) refuses what it must: committed adversarial pairs (string-content/comment-boundary holes + count/token/order plants) fail, positive controls admit with their declared class |

Certification-integrity rules ride the gates: validation of
build-rule-affecting changes is cache-disabled from re-derived
generated trees; audits check the artifact the consumer actually
loads (the libc.co staging pattern); quoted outputs are verbatim.

## 4. How often

Per `scripts/LADDER.md`: Tier A (every commit) = `test_unit.sh` +
the exec baselines + bytes + libc_exec + multi_tu + parse + core +
elab + the uri gate + cn_coverage; Tier B (slice boundaries,
pre-merge) adds the full libxml2 battery, the tests/ci suites,
`test_verify.sh`, `test_immaculate.sh`, the speclab gate lanes, the
gcc second-oracle lane (`test_gcc_oracle.sh --check-baseline` — a
GATE since 2026-09-02 [USER]) and the harness plant batteries
(`test_hang_plant.sh`, `test_kill_plant.sh`; `test_renumber_plants.sh`
rides `test_unit.sh`); Tier C are the committed reporting
instruments (`test_ci_sweep.sh`, the csmith full pass, fuzz). Probe
corpora that are neither gates nor scoreboards (`tests/parity-probes`,
`tests/mem-scale-probes` incl. its `micro/` Lake package,
`tests/csmith_findings`) are enumerated in LADDER.md as instruments.
No ladder/battery runner script exists: Tier A/B membership is operator procedure at boundaries (`test_unit.sh` bundles a few Tier A gates); every Tier B row — the gcc row included — has exactly that enforcement level.

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
4. **The customer contract (effect retirement, universal form) is
   MET, with the §3 gate as its standing enforcement**: every
   constant elaborated from this repository and from LemLib has axiom
   cone ⊆ `[propext, Classical.choice, Quot.sound]`. This is derived,
   not sampled — zero `axiom` declarations exist anywhere on the
   scanned surface (hand-written, generated, and the LemLib package,
   recursively), and the standing bans exclude the tactic-introduced
   axioms — with the exec-entry probes as end-to-end spot checks.
   `runEffectful` does not exist under any name; reintroducing
   `declare {lean} effectful` is a lem generation-time refusal.
   (Charter: `docs/2026-08-31_effect-retirement-design.md` §1.3.)

## ISO-fix register

The zero-discrepancy rule ([USER 2026-09-03], charter
`docs/2026-09-03_zero-discrepancy-design.md` §1.1): every Lean-vs-oracle
EXECUTION discrepancy on a program both engines run in matched mode is a
bug — mirror the OCaml. The ONE licence for a deliberate Lean deviation
TOWARD ISO C is this register ([USER 2026-09-03]: "a short listed set of
fixes is in keeping for the purpose of cerberus-lean but the bar for such
a fix must be extremely high"; criteria (i)–(vii) and the tightened (ii′)
RATIFIED, charter §1.4/§7 Q2/Q3). Each entry: an unambiguous oracle bug
against a cited ISO clause, a second independent oracle agreeing with
Lean, filed upstream, pinned in the immaculate lane as a Lean-right/
oracle-wrong pair that flips to MATCH — retiring the entry — when upstream
fixes it, individually [USER]-ruled, soft cap ≤ 10, and a grep-able code
marker `-- ISO-fix register R<n>` at the Lean site. Anything not listed
here is a BUG-FIX (mirror + tray), whatever a comment used to call it.

| entry | oracle behaviour (site) | ISO clause | 2nd oracle | tray | immaculate pin(s) | Lean code site | ruling |
|---|---|---|---|---|---|---|---|
| **R1** | `'\?'` / `"\?"` make `decode_character_constant` FAILWITH (decode.ml has no `\?` arm; `translation.ml:3032` for the string-literal form): uncaught exception, exit 125 | C11 §6.4.4.4#1 (`\?` is a simple escape sequence), #4 (value = `'?'` = 63) | gcc exit 63; `"a\?b"` → bytes `97 63 98 0`; `ptr_string_literals.c` output = gcc byte-for-byte | 10 (+ string-literal addendum, noodle E2) | `g5-decode-question` ORACLE_CRASH / L=Specified(63); `zd-e2-ptr-string-literals` ORACLE_CRASH / L=Specified(0) + the gcc byte string | `CerbDecode.lean` `| "\\?" => 63` (marker `-- ISO-fix register R1`) | **ADMITTED** [USER 2026-09-03] |
| **R2** | `%c`-stored char round-trips through `Decode.escaped_char` (= `Char.escaped`, decimal `\ddd`, decode.ml:221-222) then the OCTAL reader (decode.ml:184-197) inside `formatted.lem:769-771` `store_chars_in_array`: 127 is stored as 87 | C11 §7.21.6.1#8 (`%c`: the `int` argument converted to `unsigned char` is written) | gcc 127 | 11 | `g5-escape-roundtrip` DIFF / L=Specified(127) | `CerbDecode.escaped_char` (hex `\xNN`, exact round-trip; marker `-- ISO-fix register R2`) | **ADMITTED** [USER 2026-09-03] |
| **R3** | `memcmp` with a huge size: uncaught `Z.Overflow` at `impl_mem.ml:2660` `Z.to_int` — a host-int conversion raised BEFORE the semantic path | (ii′) shape: no ISO answer for a UB program; the semantics' own checked per-byte load yields `UB_CERB002a` | pending: the oracle itself with tray 13's Z-native remedy on a scratch build ((ii′)(3), produced by Z4) | 13 | `s4b-memcmp-hugesize` ORACLE_CRASH / L=UB_CERB002a (stays as recorded) | `CerbMem.lean` memcmp (line-mirror minus the conversion; marker added when (3) lands) | **ADMITTED CONDITIONAL** on Z4's (ii′)(3) evidence [USER 2026-09-03] |

R4 (`dynamic_addrs`, tray 19) is DEFERRED [USER 2026-09-03] — mirrored,
not admitted (charter §2.6). Every other former "deliberate divergence" /
"never fix-to-match" label in this repository was revoked on 2026-09-03
and either mirrored (the Z1 slice: `docs/2026-09-03_zero-discrepancy-Z1-record.md`)
or is a census row awaiting its slice (charter §2).

What remains on the trust boundary: the OCaml oracle itself (and
upstream's correctness), the C parser (shared, upstream), the Lem
compiler and its Lean backend (attacked structurally by the shared
model + the mirror discipline + these differentials), the Lean
toolchain, and the declared RUNTIME seams — not axioms, enumerated
and machine-pinned (`scripts/unsafebaseio_allowlist.txt`, gate-
enforced both directions), each with its ruled classification
[USER 2026-08-31]:

- the digest boundary (`CerberusFresh.digest`/`forceIO`/`md5Hex`) —
  kernel-checked opaques with native `@[implemented_by]`/`@[extern]`
  bindings (the C2 conversion; nothing postulated, no proof can
  unfold them);
- `CerbGlobal` config/switch refs — temporal; mover: a post-arc
  parameter-plumbing slice;
- `CerberusImpl`'s enum registry — temporal; mover: the arc's
  reader/supply machinery in a follow-up slice;
- `CerbUtils` no-op timing/log refs + the `boundedIntegerImpl` stub —
  permanent-declared (OCaml module-shape parity);
- LemLib's `failwithIImpl`/`fuelExhaustedWithImpl` panic bindings
  (runtime behavior of the axiom-free failure/fuel constants).

The remaining declared MODEL boundary: the in-memory filesystem model
(`CerbFS`), the debug no-op stubs (`CerbDebug` — the model returns
values, the driver prints), and the concurrency stubs (temporal, the
cmm instantiation is the mover). Known limitations are tracked in
[TODO.md](TODO.md) (e.g. the step-runner stack ceiling).

**Known, LOUD limits of the Lean driver** (all reported by the lanes,
never absorbed as a skip; none is a memory-model limit):

- **Refused command-line flags** (zero-discrepancy Z-24/Z-25, exception
  class (c), [USER 2026-09-03] Q7 "REFUSE now … plumbing … is not wanted"):
  `cerberus-lean` accepts exactly `--batch | --pp-core | --parse-core`
  (argv[0]), `--first`, `--stdin`, `--libc`/`--libc-tu`, `--call`/
  `--call-args`, `--args`, `--trace-nodes`. Any other `--` token — the
  oracle's `--switches=…` (semantics switches: PVI/PNVI/strict/CHERI;
  matched default-switch mode is the harness contract), `--concurrency`
  (not supported; the oracle's own mode is non-functional at `b9aeedcb4`,
  `CONCURRENCY IS BROKEN`), an unknown flag, or a KNOWN flag out of its
  canonical position — is refused loudly: `cerberus-lean: refused — <flag>:
  <feature> … (see VALIDATION.md, zero-discrepancy Z-24)`, exit 2, never
  treated as a file name (it used to be).
- **`LEAN_ABORT_ON_PANIC` is required** (Z2 audit row Z2-FL-03): the driver
  refuses to start (exit 2) unless the variable is set, because a Lean
  `panic!` — the port's fail-stop mirror of every OCaml failwith/assert/
  uncaught exception — would otherwise print and CONTINUE with a default
  value (a crash-to-value conversion). Every harness sets it
  (`scripts/common.sh run_cerberus_lean`).
- **Zero executions from `runND`** (zero-discrepancy Z-73, RULED [USER
  2026-09-03] Q8 = A): the driver prints `Error {msg: "cerberus-lean: runND
  returned no executions"}` and exits 1 where the oracle prints nothing and
  exits 0 — a DECLARED loud boundary (a silent success with no verdict is
  the fail-open shape the working practices ban; the oracle's behaviour is
  a tray candidate). The fuel arc's exhaustion leaf has the same shape and
  inherits the classification.

- **Fuel exhaustion is a typed, distinguished outcome** for the ND
  monad's fueled workers (the driver loop family, the memory-model ND
  workers, and the `CerbND` runners): the fuel-zero arm is `NDkilled
  CerbND.fuelExhaustedKill` = `Error0 CerbFuel.fuelExhaustedLoc "lem:
  fuel exhausted"`, where `fuelExhaustedLoc` is a pure, kernel-checked
  `opaque` constant on the boundary-opaque census (present exactly
  once; no native binding). Every proof is uniform in the opaque
  atom; the sentinel is a fresh location for every provable statement
  — a theorem "every outcome is `Killed _ fuelExhaustedKill` or good"
  holds under the reading where the atom is a location no model term
  denotes, and a program that genuinely kills makes it unprovable, not
  false; so no distinctness lemma is needed (corollary: no `.lem`
  term, Core text, or JSON input can denote the atom). `_zero` lemmas
  hold by `rfl`; the fuel-parametric pipeline `CerbND.drive_lemFuel`
  is pinned to the generated `drive` by `drive = drive_lemFuel
  driverFuel := rfl`. Budgets: the coupled driver family
  (`driver2`, `drive_nonmemory_steps_aux2`, `print_eval_conv_aux`,
  `hack`, `nd_bind`, `CerbND.ndDefaultFuel`) runs at
  `CerbFuel.driverFuel` = 10^8 (the ceiling was ~1.7e4 plain loop
  iterations / ~6e4 C-recursion depth at the former 10^6); every other
  fueled declaration keeps `lemDefaultFuel` = 10^6 (the L1 opt-in
  guarantee). Pure-return workers keep the opaque panicking sentinel
  (exit 134, `lem: fuel exhausted` on stderr). The classifying lanes
  (`test_exec.sh` and its csmith wrapper, `test_gcc_oracle.sh`,
  `test_ci_sweep.sh`, `test_cn_coverage.sh`,
  `tests/mem-scale-probes/measure.sh`) assign the FUEL class to both
  forms by the printed message (fail-noisy, never agreement;
  reporting-only, no soundness rests on it); the byte-compare lanes
  (`test_libc_exec.sh`, `test_multi_tu.sh`, `test_verify.sh`,
  `test_immaculate.sh`, `test_libxml2_uri.sh`, `test_bytes.sh`) report
  DIFF/FAIL. A 10^8 budget is unreachable inside any gate lane's
  timeout (15-30 s ⇒ ≤ 7×10^6 fuel per invocation); it is exercised
  only by `measure.sh` (600 s) and unbounded single probes. Why a
  fuel row is an accepted Lean-vs-oracle discrepancy at all — [USER
  2026-09-03]: "fuel is a reasonable exception because we could always
  just run the semantics with more fuel." That ruling's frame: ALL
  Lean-vs-oracle execution discrepancies are bugs, with exactly two
  accepted exception classes — (a) failure-path message text may
  differ (failure-vs-success classification must match), (b) resource
  limits: Lean must not fail where the oracle succeeds. Fuel
  exhaustion is accepted under (b) with the rationale that the bound
  is a PARAMETER of the port, not a semantic limit: for any oracle-
  terminating run there is a fuel at which Lean agrees. This is the
  design rationale, not a shipped theorem — fuel monotonicity for the
  driver workers is NOT provided (design note §1.5), and a FUEL row
  is never counted as agreement. Record:
  `docs/2026-09-02_fuel-arc-design.md`.
- Zero-initialised static aggregates above ~8 × 10^6 ELEMENTS
  (element-count driven: `char g[8000000]` completes, `char g[10000000]`
  does not; `int g[2500000]` completes) overflow the 1 GiB runtime-
  thread stack in the Ail typing stage. Mechanism, located first-hand
  (record `docs/2026-09-02_mem-scale-record.md` §S1'): each per-element
  closure application in a function-typed monad's run loop costs one
  Lean-runtime `lean_apply_*` frame (~110 B) because the runtime enters
  closures by CALL, not tail jump — the cost is in the Lean runtime, not
  in our C or the `.lem`; a source-level tail rewrite only moved the
  onset from ~7 M to ~9 M and was reverted [USER 2026-09-02]. The
  runtime's overflow handler then deadlocks (upstream report drafted:
  `docs/upstream-tray/lean4/01-…`), so this limit surfaces as a HANG:
  exit 124 with CPU/wall < 0.1, classified `HANG` by `test_exec.sh` /
  `LEAN_HANG` by `test_ci_sweep.sh` (mem-scale S0), fatal. The oracle
  completes these inputs (10 M: ~76–246 s, 7.7 GB). Not a knob to
  turn: a bigger stack only moves the silent onset; the fallback design
  (lem-backend run-loop rendering) is registered in TODO.md.
