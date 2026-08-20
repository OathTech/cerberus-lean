# Arc 7 decision log (the bridge)

Provenance tagging per the goal directive: [USER] = operator-made or
operator-directed (with the directing statement); [AGENT] = autonomous
(orchestrator or [AGENT:worker-slice]). Mislabeling agent decisions as
user-decided is a critical trust failure.

**D1 [USER]** — Charter blessed via goal launch. Charter-embedded [USER]
directives (from the drafting exchange, recorded there verbatim):
quantified-over-inputs theorems, interpreter-only statements, the
verification slate T1-T5, the proof-infra discipline / no hacking
campaigns / check-what-iris-offers, survey+.gitignore as an early arc
commit, totalize-CerbND (the Q1 ruling), non-kernel proof-method ban.

**D2 [AGENT]** — Lane: branch `arc/layer2`, worktree
`worktrees/cerberus-lean-arc/layer2`. Slice-order call: S1 (branch
assembly incl. spike/relsem) runs BEFORE the S0 toolchain probe — the
probe must validate the ASSEMBLED stack (RelSem included), so assembly
first; the charter's "S0 before anything" intent (no Layer-2/3 work on
an undecided toolchain) is preserved since assembly adds no new proof
work. Spike integration method: REBASE the 5 spike commits onto
arc/layer2 (linear history, one lakefile conflict resolution), spike
branch left intact as the historical record.

**D3 [AGENT]** — S1/S0 boundary passed (verified under 4.32.2: RelSem
audit builds, unit 4/4, minimal baseline rc 0; the cabs_to_ail_effect
reindent proven TOKEN-NEUTRAL by whitespace-stripped hash equality).
TOOLCHAIN BUMP ADOPTED [AGENT:S1S0 endorsed]: 4.29.0 → 4.32.2 on full
gate evidence, zero movement; batteries → v4.32.0 (the iris-lean-vendored
rev, resolved offline); one compiler delta registered (column-0
continuation parse change; principled fix = lem backend never emits
column-0 continuations — lem-lean follow-on). Option (ii) fallback on
record: iris-lean v4.29.1 exists but lacks GenHeap — degraded, moot.
In-build RelSem axiom audit LIVE with exact pins; runEffectful added to
the declared boundary on probe evidence (the arcs-1/2 barrier — LemLib
half of the boundary; census note). ARC-BLOCKING FINDING registered:
sorryAx in initial_driver_state's cone via the sorried generated
instSetTypeGeneric_fun_map_decl — 5 RelSem defs inherit (incl.
initConfig, which the exit theorem mentions); pinned as a fail-closed
exception list; EVICTION is a mandatory S2 item (arc-4 S1a
priority-override precedent). Audit-file lesson encoded: declarations
after the sweep are unswept — sweep is the file's last element.

**D4 [AGENT]** — S2 boundary passed (verified: totality gate "CLEAN (11
generated modules + hand-written CerbND, 0 allowlisted)", unit 4/4,
minimal baseline rc 0). Endorsed [AGENT:S2] calls: (a) runNDT DELETED —
the executable IS the proof object (Q1 AMENDED's whole point); spike
history preserves the prototype. (b) The exhaustion-marker TRANSPARENCY
asymmetry, endorsed as principled and recorded so audits don't flag an
inconsistency with fuelExhaustedWith's OPACITY doctrine: sentinel
VALUES that could be mistaken for answers must be opaque (a fake value
provable equal to something is a lie); an exhausted runner yielding the
EMPTY BEHAVIOR SET is safe transparent — [] claims nothing, soundness
is vacuous there, completeness is never asserted (fuel discipline), and
the runtime panic keeps it loud. Two different honesty mechanisms for
two different failure shapes. (c) Bonus: arc-2's declared
RunNDActiveSound seam is now PROVED — a standing IOU closed.
Register: arc-4 G3 results-language update due at close (CerbND left
the declared boundary).

**D5 [AGENT]** — S3 boundary passed (verified: test_verify 23/23, unit
4/4, minimal baseline rc 0). Endorsed: the caller-protocol discovery
(int params by pointer — read off the real elaborated Core, not
assumed); quantification as statement data; the app-equation finding
(Step was node-kind-complete; coverage-by-need meant equations, not
arms). RULING for S5 [AGENT, per the charter's exit criterion]: slate
theorems go through the IRIS WP ROUTE (callHarnessAdequate_of_adequate);
the direct route (…_of_app_active) is cross-check scaffolding only — an
exit theorem proved by the direct route would not exercise the bridge
and does not satisfy the charter. T5's loop-invariant rule is a WP-level
item (S4). Zero proof-fight escalations in S3 — the infra-first
discipline held.

**D6 [AGENT]** — S4 boundary passed (verified: 584-job build with the
iris dep, unit 5/5, baselines rc 0, test_verify 23/23). THE ADEQUACY
THEOREM proved, fallback NOT taken; iris-lean adds ZERO axioms to the
pure coupling layer; statement-TCB held. Endorsed [AGENT:S4] calls:
(a) StateInterp = full-driver-state ghost_var at driver-node granularity
(probe-argued: one-step runs mean the interp must determine the app
equation; gen_heap catalogued as the Q4-refinement fill when
granularity refines; slot stays parameterized). (b) The inventory's
bind/PureExec N/A findings + T5 re-priced as fuel-induction (D5's
"WP-level loop rule" REVISED on trace evidence — [AGENT] revision of an
[AGENT] call, both logged). (c) Escalation event 1: CerbMem exec-path
totalization (9 partials) — an arc-4 G3 expansion item landed as
infrastructure-first discipline; zero movement. S5 GATING ITEM
[registered]: T1AppEq blocked on the arc-3 F8 call-graph escapees on
T1's path (~8 fuel declares + regen — declares-only, the arc-3
pattern); when landed, T1 UNCONDITIONAL falls out of t1_of_app_eq
unchanged. Infra: iris-lean pinned 79dab15; deps/gitconfig gained its
redirect; MIRROR NEEDED next network window (deps/mirrors lacks
iris-lean.git).

**D7 [USER-prompted / AGENT-implemented]** — SESSION OOM KILL during S5a's
T1AppEq probe (a whole-driver-run rfl with maxHeartbeats 8000000 — the
kernel reducing the entire concrete execution as one defeq check ate the
125G box; golean's exact failure shape: kernel grinding on an
unevaluated/huge proposition). Operator directed: adopt golean's
mitigations. Landed: `scripts/capped` (cgroup MemoryMax via systemd-run
--user --scope, default 64G, CERB_MEM_MAX override, =none loud opt-out;
breach-kill verified rc 137 in-scope). RULES now standing (container
CLAUDE.md): (1) NEVER run lake/lean uncapped — every worker brief
carries it; (2) the #eval-first habit — evaluate the Bool/shape cheaply
before asking the kernel to prove it; (3) monolithic whole-run
rfl/decide on driver executions is BANNED as a proof method — the
escalation rule applies: build the compositional equation-lemma chain
through the staged combinators instead. S5a state: commit 1 (F8 sweep +
totality gate over 5 more modules) landed pre-crash; T1Probe.lean
untracked scratch preserved as evidence.

**D8 [USER]** — Heartbeat-hacking doctrine (operator, near-verbatim):
raising elaborator budgets "usually means we are brute forcing something
that should be done more intelligently — typically we want something
more compositional or clever to support scalability"; increases are
"allowed only as a temporary measure, they are by-definition a defect
(unless investigated and agreed with the user to be unavoidable)".
Codified in container CLAUDE.md (audits now grep proof files for budget
bumps; un-registered = finding). Relayed to the running S5a worker.
Note: the crashed probe's maxHeartbeats-8000000 was this smell at
maximum volume — the doctrine names what D7's rules already punished.

**D9 [AGENT]** — S5a boundary passed (verified: 595-job capped build,
unit 5/5 incl. "12 slate statements fuel-opsem-clean", baselines rc 0,
test_verify 23/23, ZERO budget bumps in relsem/ by grep — D8-clean).
THE EXIT CRITERION IS PROVED: T1-T4 ∀-quantified interpreter-only
theorems through the full WP route; T5 parked with a one-session price
(charter-legal). Endorsed: the T4EnvHyp pattern (process globals as
explicit hypotheses = the census boundary made visible in the
statement; the standing pattern for future struct/fresh-drawing
fixtures); the fuel-k sentinel state-discovery trick; the
fixture-generic SlateWP bridge. Register items accepted: expr-family
sorried BEq (C-tier lem item); the Lake lib-root wiring gotcha (a
false-positive green until imported — recipe note). S5b = close-out:
results, de-stale, twin audits, checklist. Lem-lean UNTOUCHED this arc
(single-repo merge; pins stay bd7e2eb); iris-lean mirror needed next
network window (D6).

**S5c correction notes (2026-08-20, audit-response — appended per the
never-rewrite-history rule) [AGENT:S5c]**
- D2 correction (audit-2): D2 says "REBASE the 5 spike commits onto
  arc/layer2"; the spike branch carried NINE commits, all nine rebased
  (verified 2026-08-20: `git log --oneline mdd/cerberus-lean..spike/relsem`
  lists 9). The results doc's "9 commits" figure is correct; D2's "5"
  was a miscount at writing time. D2's text stands unedited above; this
  note is the correction of record.
- D9 quote relabeled DERIVED (audit-2 F2): D9's verification line
  quotes the statement gate as `12 slate statements fuel-opsem-clean`.
  The LITERAL build output at the time was
  `RelSem statement gate: 12 slate statements     fuel-opsem-clean (negative test: t1_wp correctly rejected)`
  (five-space run — a wrapped string literal in Audit.lean). Per the
  verbatim-transcript rule the D9 quote is hereby relabeled DERIVED
  (whitespace-normalized), not verbatim. S5c fixed the literal (string
  gaps); the gate line as of the S5c rebuild reads, verbatim:
  `RelSem statement gate: 16 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)`.

**D10 [AGENT]** — S5c boundary passed (verified: unit 5/5 incl. census,
test_verify 29/29, minimal baseline rc 0). Arc CLOSED. THE DAEMON
DISPOSITION, stated for the merge ask: audit-1 proved the DAEMON axiom
inconsistent (∀{α:Type},α ⊢ False at Empty — in the boundary since
arc 2, exposed by the first-theorems audit); S5c evicted 8/10 slate-cone
entry vectors (real instances arc-2 had built but never wired — a
lesson in itself); the 2 structural residues (poly-site failwith =
DAEMON by value, on every driver cone via pick; one same-module
instance) are immovable without the C-tier lem redesign, now filed as
lembugs/2026-08-20_daemon-inconsistent-axiom.md with the design sketch.
CONSEQUENCE, honestly stated everywhere it matters: T1-T4 are
kernel-checked MODULO the DAEMON meta-assumption (unreachable-inhabitant
marker) — proofs read-verified genuine by the auditor, cones pinned
exact, entry vectors census-enforced in-build. The TOP item for the
next lem arc. All other audit findings FIXED (strongest options:
CerbND-shaped ubFree restatements, enforced census, T4EnvHyp truth,
capped-everywhere, provenance gate, singleton companions).
