# TODO — roadmap and backlog

Grouped by horizon. One line per item; depth lives in the pointed-at
records. Status that moves fast (proof-round counts, in-flight work)
is deliberately not pinned here — follow the pointers.

## In flight

- **Arc 18 — the coherence consolidation**: one reasoning route
  survives (the law-driven round evaluator minting equations, the
  per-step WP layer consuming them, `CerbMemInterp` as the sole state
  interpretation, one attribute-indexed law registry as the public
  interface), the superseded routes are purged, and a playbook makes
  the layer explainable to a fresh agent. Charter (slice ladder
  C0–C6, operator-blessed):
  `docs/2026-08-25_arc18-coherence-charter.md`; layer contracts:
  `docs/2026-08-25_reasoning-layer-contracts.md`. T4-threaded and T5
  (the first bounded-loop theorem) complete on the consolidated
  substrate at C3. (The previously headlined in-chase sealing/stepper
  plan was falsified and superseded — post-mortem:
  `docs/2026-08-24_chase-era-postmortem.md`; the design note
  `docs/2026-08-23_stepper-arc-design.md` is superseded history.)

## Next, in sequence

- **Family-∀ spec-lab endpoints** (arc-18 C4) — kernel proofs that
  the compiled spec harnesses execute to their verdicts: upgrades the
  spec lab's finite sample-∀ statements to family-∀ and makes the
  plant-refutation schemas unconditional. Benchmark: the five parked
  spec-lab campaigns (`docs/2026-08-23_arc15-results.md`, parked
  inventory).
- **The libxml2 rung** — `uri.c` under the consolidated layer (the
  differential corpus + 16/16 gate already stand); its memory
  reasoning runs under `CerbMemInterp` and produces the
  Lithium-parity-distance table.
- **Arc 19 — goal-directed search** over the arc-18 registry (the
  Lithium parity floor; charter to be written against the post-arc-18
  tree).

## Targets (once the automation framework sets the proof economics)

- **WireGuard ladder** — `docs/2026-08-20_wireguard-target-scoping.md`.
- **pKVM buddy allocator** — reference: the CN pKVM buddy-allocator
  case study (github.com/rems-project/CN-pKVM-buddy-allocator-case-study);
  GPL-derived fixtures stay out of this repository (they go in a
  separate example repository, for licence separation).

## Queued larger work

- **Concurrency (cmm) instantiation** — choice streams become
  schedules. Concurrency is currently stubbed (a declared, documented
  boundary); this is the work that removes the stub.
- **The repo split** — "the semantics" vs "the verification layer" as
  separate repositories; the package structure already rehearses it
  (DESIGN.md §6).

## Small items (independent; can ride along with any fix batch)

- `pr44468.c` offsetof unknown-tag panic (the CI sweep's one new
  defect): `docs/2026-08-22_ci-sweep-results.md`.
- CoreParser `enum TAG` ctype-literal arm (unblocks a parked spec-lab
  statement layer; reproducers in `tests/speclab/`).
- Oracle `--batch` allocation-census line (unlocks the leak
  conjunct's differential leg; a candidate patch for upstream
  Cerberus).
- Lean driver `--args` flag (argv parity already verified; unlocks
  the ∀-inputs statement form).
- DivMod local-canonicity consolidation into `Codec.Canonical`
  (noted in `speclab/SpecLab/Codec.lean`).
- Step-runner stack-ceiling guard (known limitation: loops of a few
  thousand iterations can overflow the process stack in the step/ND
  recursion; `docs/2026-08-19_arc6-s0-survey.md`).

## Deferred polish

- Backend/semantics cleanups (pure-render emission split, remaining
  audit gaps) — itemized in the latest `docs/*-results.md`;
  deliberately parked behind the substantive track.

## Needs maintainer action or network access

- Patches queued for upstream Cerberus: a tray of drafted bug
  reports and prepared PR branches, maintained operator-side and
  filed as network windows allow (several findings from the
  differential campaigns; two already have ready branches).
- Decide the fate of the earlier prototype interpreter (reduce to a
  test oracle vs archive) — open decision.
- **Elaboration-in-statement probe** — start theorem statements from
  the pinned parsed C AST with elaboration inside the kernel-checked
  claim (shrinks the trusted C-to-Core link to the parser alone;
  PROOF.md §3). Unpriced until the kernel-side elaboration cost is
  probed; natural once the consolidated automation layer (arc 18) is
  in place.
- **Kill the effect axioms** — LARGELY DONE (arc-17 S2b):
  `with_tagDefs`/`forceIO` are DELETED as axioms (kernel-checked
  opaques, boundary-opaque gate); the threaded theorem family is
  trio-exact. Residual: `runEffectful` (LemLib, temporal — its
  deletion is lem-side surgery; carrier set pinned by the
  no-cone-entry gate, the ambient family retires at the arc-18 C5
  purge), and the spec-lab statement substrate still quotes the
  ambient initial state (re-landed threaded at arc-18 C4). Full
  machine-state threading of the supply remains the cmm-arc-adjacent
  end state (PROOF.md §1).
