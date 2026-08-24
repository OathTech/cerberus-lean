# TODO — roadmap and backlog

Grouped by horizon. One line per item; depth lives in the pointed-at
records. Status that moves fast (proof-round counts, in-flight work)
is deliberately not pinned here — follow the pointers.

## In flight

- **In-chase sealing + landing T5, the first bounded-loop theorem**
  (the next rung after the T1–T4 slate, PROOF.md §3). A new
  engine capability keeps every kernel obligation shallow inside long
  symbolic-execution chases (the Lean kernel's recursion depth is the
  binding limit, not proof content). Mechanism + current state:
  `docs/2026-08-22_arc15-t5-resumption-record.md`, seals section of
  `docs/2026-08-23_stepper-arc-design.md`.

## Next, in sequence

- **The exec-equation campaign** — kernel proofs that the compiled
  spec harnesses execute to their verdicts. The binding constraint on
  proof capability: upgrades the spec lab's finite sample-∀ statements
  to family-∀ and makes the plant-refutation schemas unconditional.
  Benchmark: the five parked spec-lab campaigns
  (`docs/2026-08-23_arc15-results.md`, parked inventory).
- **The compositional stepper** — a certificate-emitting symbolic
  executor: proved-rewrite laws + in-chase seals + typed residuals +
  per-function summary **overrides** at call sites (whole-state
  summaries first, separation-logic footprints second). Design:
  `docs/2026-08-23_stepper-arc-design.md`.

## Targets (once the stepper sets the proof economics)

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
  probed; natural once the sealing/stepper machinery lands.
- **Kill the effect axioms** — thread the effect state (fresh-symbol
  supply, tag-definition table) into the modeled machine state,
  Lean-side only, retiring `runEffectful`/`forceIO`/`with_tagDefs`
  from every theorem cone; end state = exactly the three standard
  Lean axioms (PROOF.md §1). Sooner rather than later; the
  concurrency work (which needs explicit machine state anyway) is
  the natural vehicle if nothing earlier takes it.
