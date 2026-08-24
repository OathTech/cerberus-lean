# Arc 16 — the Iris refounding, part 1 (language, heap, laws, acceptance)

STATUS: direction BLESSED [USER 2026-08-24]: "we are building an
Iris-based program verifier for C because that is what will scale" —
this charter executes phases 0–3 of the whole-project audit's
remediation plan; part 2 (T5-by-invariant, spec-lab exec endpoints,
THE PURGE, docs) is the named follow-on arc. Companion:
`2026-08-24_chase-era-postmortem.md`. Statement doctrine, adequacy,
and the fuel-opsem TCB are NOT under review — boring executable specs
in front, unchanged; this arc rebuilds the back of the house.

## Canon-first compliance (lineage sentence per mechanism, per doctrine)

- **Language instance** — Iris (Ectx)Language over Core-driver
  configurations with per-step structure. *Lineage: the Iris
  program-logic canon; the pinned iris-lean's HeapLang instantiation
  is the worked end-to-end template.*
- **Heap resource over CerbMem** — alloc/byte-range fractional
  points-to with typed views above. *Lineage: separation logic /
  GenHeap+HeapView; Caesium (deps/refinedc) is the design donor for
  provenance-carrying C memory. Abstraction sentence: separation at
  footprint granularity buys framing — a function's proof touches
  only its footprint, so the next function is free of this one.*
- **Primitive WP laws + decompilation layer** — one proved lemma per
  Core construct/memory action; derived source-shaped rules over
  elaboration's stereotyped compiled-C patterns, taking LOGICAL loop
  invariants. *Lineage: Floyd–Hoare/WP; Myreen's decompilation into
  logic; the construct inventory is finite (spec-lab measured
  vocabulary saturation). Sentence: each law proved once fires for
  every program containing its construct — program N+1 pays only its
  own structure.*
- **Automation** — IPM (already in the dep) + per-construct
  wp-tactics (HeapLang Tactic.lean template) + brick-wp-shaped
  packaged steps; Lithium-style goal-directed search deferred to when
  the lemma library stabilizes. *Lineage: brick-wp (deps/brick-wp),
  Lithium (deps/refinedc), the 2026-08-21 automation survey's "import
  the automation shape, not a second semantics."*
- **Side-condition reflection** — kernel `decide` for layout/offset
  arithmetic. *Lineage: proof by reflection; ban-compliant (kernel
  computation, no ofReduce*).*

## Slices

- **S0 — freeze + probes + supersessions.** (a) Additive gate: no NEW
  imports of `Tactics.AppWalk`/chase surfaces outside the enumerated
  legacy list (plant-tested). (b) THE PERF PROBE: measure iris-lean
  IPM elaboration cost at our state sizes early (typeclass-heavy;
  unmeasured) — budget pressure is a DESIGN INPUT, never a bump
  (heartbeat doctrine unchanged). (c) The docs-side supersessions
  land with this charter's branch.
- **S1 — the language instance.** Per-step Core-driver steps replace
  the whole-run atomic shell; allocator ND enters as language steps
  (deterministic per resolved choice; cmm schedules slot here later —
  forward-design constraint honored). Adequacy re-derived; statements
  and cones unchanged.
- **S2 — the CerbMem heap RA (THE RISK ITEM).** Byte/alloc points-to
  + framing lemmas first; typed views may trail into part 2. The
  state interpretation anticipates effect-state threading (supply +
  tagDefs per the temporal-boundary ruling — nothing here may make
  that harder). EXIT RAMP: if the RA's interaction with
  provenance/byte granularity exceeds price by S2's midpoint
  checkpoint, STOP AND REPORT with the measured obstacle — a precise
  wall report is a successful outcome.
- **S3 — primitive laws + wp-tactics** for the exec-relevant Core
  inventory; laws pinned Kit/Audit-style; tactics exercised on
  straight-line micro-programs.
- **S4 — THE ACCEPTANCE TEST: re-prove T1–T4** through S1–S3 — **AT
  THE THREADED STATE** ([USER 2026-08-24] amendment: the effect-state
  elimination folds in here; recipe = the parked spike branch
  effect-spike @ 7f4100a5c). Statements restated at the
  seed-parametric initial state (∀-seed — STRONGER than the ambient
  originals; T4's `fresh = 1048577` conjunct dissolves); success
  criterion: cones EXACTLY the classical trio
  {propext, Classical.choice, Quot.sound} — no runEffectful.
  `with_tagDefs`/`forceIO` (the digest/tagDefs seam, S–M) attempted
  in the same pass; if it spreads, parked with a price for part 2.
  Recorded hazard: whole-stage rfl requires CLOSED states —
  seed-quantified proofs route memory ops through the kit (the
  spike's finding, hardened to necessity). Boundary-list and
  cone-gate tightening ride the same commits.
  Success bar: proof text per fixture on the order of TENS OF LINES
  (today: ~464K of round chains across the AppEq files). [Audit
  clause, verbatim spirit]: if it is not cheap, the machinery is
  wrong again — stop, report, re-design; do not grind.

## Doctrine resolutions (flagged by the audit, resolved here)

- **Certificate-emitter doctrine** reworded, not weakened: every proof
  step is kernel-checked — under IPM the steps land inside ordinary
  theorem terms rather than as separate emitted declarations; the
  doctrine's enforceable content (non-kernel ban + exact cone pins)
  is unchanged and stays gated.
- **Proof-size gate**: untouched this arc (chase-era registrations
  stay as-is until the purge); re-registered wholesale in part 2's
  purge commit. The mega-lemma-counter concept survives.
- **Heartbeat doctrine**: unchanged; S0's probe exists so any
  pressure is met with structure, not budgets.

## Validation

Standard battery green throughout (unit, verify, exec zero-movement,
speclab lanes, cn baseline); the S0 freeze gate; no new
axioms/sorries — cones exactly the classical trio + the (temporal)
effect boundary; workers commit on green; checkpoints on concrete
objects are the operator's; pre-merge audit ask unconditional.

## Success criteria

1. S4 passes: T1–T4 re-proved cheaply through S1–S3 — per the
   [USER] S4 amendment, AT THE THREADED ∀-seed STATE with cones
   exactly the classical trio (the ambient family untouched,
   bridged by labeled lemmas). [Outcome: T1–T3 landed; T4 stopped
   at the kernel-witnessed apartness diagnosis — the stop clause's
   defined success; see the S4 record.]
2. The heap RA supports framing (demonstrated: one two-function
   proof where the second function's proof does not mention the
   first's footprint).
3. Zero new chase-surface imports; all lineage sentences in this
   charter still true of what was built (audit checks them).
4. Part-2 charter drafted from measured S1–S4 prices (T5 by loop
   invariant; spec-lab exec endpoints; the purge; docs).
