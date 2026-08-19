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
