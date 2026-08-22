# Arc 13 charter: the symbol-id rebase + fixture re-pin ("clean numbering")

Date: 2026-08-22. Mode: long-cycle autonomous under the orchestrator/
worker doctrine. BLESSED by operator via launch, 2026-08-22 ("Launch the renumbering"). Branch:
`arc/renumbering` (cerberus-lean; lem NOT expected — any lem change =
tripwire + replan). Preconditions MET: arcs 11+12 merged 2026-08-22;
[USER 2026-08-21] parked-for-immediate ruling executes now.

## Objective

Give the fork's oracle a COLLISION-FREE symbol-id scheme (the real
F-D fix, replacing margin-plus-floor with impossibility-by-
construction), re-derive every oracle-produced pinned artifact under
it, and dissolve the grandfather register — closing the arc-12
asterisks. Inputs: `2026-08-21_arc12-renumbering-case.md` (the
measured margins, R1-R3 design space, the re-pin inventory),
`2026-08-21_arc12-s0-floor-design.md` (draw-site enumeration),
`2026-08-21_arc12-results.md` (grandfather register G1-G4 + movers).
The floor STAYS as the permanent backstop (post-rebase it should
never fire on any in-tree input — that becomes its acceptance
property).

## S0 — the scheme decision (the arc's one design fork)

Price and decide between: (R-A) a fork-private disjoint base for the
threaded desugar supply (the Lean side's 2^20 pattern — maximally
simple, but fork `--pp core` output diverges numerically from
upstream forever); (R-B) re-convergence on upstream's ambient
numbering (restore the ocaml target_rep for the desugar helpers —
makes fork-vs-upstream oracle outputs directly comparable,
strengthening the three-way instrument, at the cost of depending on
upstream's draw order and a larger .lem-adjacent change); (R-C)
anything the renumbering-case doc's design space adds. Decide on
evidence (incl. a probe of each candidate's actual output diff on
the pinned fixtures + the comparability value for the upstream
filings); the decision is a D-entry with full rationale. NOTE the
.lem-token-neutrality question changes per option — R-B is a model
.lem change (generated-OCaml moves BY DESIGN; the drift gate's
layer-2 hashes re-pin with justification; generated-LEAN must still
be verified unchanged or the change priced + validated at cerberus
scale per the standing lessons).

## S1 — implement + the re-pin cascade

The scheme lands; then the inventory-driven re-derivation: all
pinned .core dumps (tests/verify fixtures, tests/libc/libc.core, the
uri corpus expectations, libxml2 config artifacts), the emitted
slate terms (emit-lean-core drift gate re-baselined), expectations
rows, the drift-gate layer-2 hashes, every exec baseline whose rows
carried FLOOR statuses (the 516 corpus rows + the exploration
lanes' yield RESTORED — measure and report the recovered
differential surface). The T1-T4 proofs re-elaborate against the
re-pinned terms — the workbench trace/replay is the tool (re-record
+ checked replay; measure the actual cost, it is the first
real-world test of the renumbering-replay economics the arc-11
records predicted). GRANDFATHER DISSOLUTION: G1-G4's movers execute
— libc.co + uri artifacts re-derived CLEAN (zero collisions,
scanner-verified), the grandfather CLI flag becomes dead code and
is REMOVED with its uri-lane invocations, the honesty addenda gain
closure notes (asterisks off).

## S2 — validation at full breadth

The complete lane battery (every Tier-A gate + coverage/ci/debug/
float/bytes/multi_tu/libc/uri/chvalid + the FULL csmith corpus
uncapped-by-floor + a fresh exploration batch measuring the restored
yield) with the THREE-WAY instrument on a witness sample
(fork-rebased ≍ upstream ≍ Lean); the floor's silence on every
in-tree input verified (its plant tests still fire on synthetic
beyond-margin shapes ONLY if the scheme still has a margin — R-A
has none by construction; adapt the floor's checks to the scheme
and re-plant); pin-provenance gates green against the NEW pins;
statement-TCB + axiom sweeps + the T5-family pins all green
(RE-BASELINED counts recorded).

## S3 — close-out

Results (the re-pin inventory as-executed; the replay-economics
measurement; the restored-surface numbers; register: F-D
CLOSED-BY-CONSTRUCTION, floor = backstop, grandfather DISSOLVED),
decision log, docs de-stale (the arc-12 records gain closure
addenda; the renumbering TEMPORAL entry retires), 2-agent
adversarial audit — mandatory scopes: (a) scheme soundness (no new
collision class; the S0 decision's evidence); (b) re-pin
completeness (any artifact still carrying old-scheme ids = finding;
the inventory cross-checked against a tree-wide sweep); (c) baseline
honesty (every restored row justified; the recovered-yield numbers
recompute); (d) upstream-comparability claims (per the S0 choice).
Fix-or-record; merge checklist. Stop. Do not merge.

## Success conditions (machine-checkable)

1. Zero symbol collisions possible by construction (scheme-dependent
   proof obligation stated + discharged in the results doc); the
   floor never fires on any in-tree input; scanner-verified clean
   re-derivations for every G1-G4 artifact.
2. The full lane battery green with the corpus FLOOR rows restored
   to real verdicts (movement fully justified, three-way-checked on
   the sample); exploration yield measurably recovered.
3. T1-T4 (and the T5-family theorems) green against re-pinned terms
   with cones exactly the clean quartet; the replay-economics cost
   measured and recorded.
4. Grandfather register dissolved; flag code removed; addenda
   closed; the renumbering TEMPORAL entry retired.
5. Zero lem-tool changes; .lem changes only per the S0 decision's
   validated path; records complete; branch gate-green; merge
   checklist ready.

## Risks / tripwires

- R-B's .lem surface: any generated-LEAN movement is a full
  cerberus-scale validation event (the April lesson) — priced in S0
  before choosing.
- The re-pin cascade misses an artifact: the S3 audit's tree-wide
  old-scheme-id sweep is the net; the inventory is the plan, the
  sweep is the check.
- Replay economics disappoint (traces invalidate on fixture
  fingerprints — re-record cost is the honest number): measure,
  report, never grind silently; if T1-T4 re-proving exceeds the
  workbench's predicted costs materially, that is a workbench
  finding for the T5-landing arc, recorded not hidden.
- The workbench-v2 worktree's probe scratch must SURVIVE this arc
  untouched (R-S2-1 material).

## Autonomy protocol

Standing doctrines all apply (orchestrator/worker, full bar per
commit incl. both Lake packages, capped 40G, verbatim records,
park-don't-improvise, per-merge ask). EMERGENCY EXIT always
permitted. Tripwires: lem-tool changes; a scheme choice whose
validation cannot close in-arc; any gate keepable-green only by
weakening.
