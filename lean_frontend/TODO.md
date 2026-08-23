# TODO — roadmap and backlog

Grouped by horizon. One line per item; depth lives in the pointed-at
records. Status that moves fast (proof-round counts, in-flight work)
is deliberately not pinned here — follow the pointers.

## In flight

- **In-chase sealing + landing the bounded-loop theorem (T5).** A new
  engine capability keeps every kernel obligation shallow inside long
  symbolic-execution chases (the Lean kernel's recursion depth is the
  binding limit, not proof content). Mechanism + current state:
  `docs/2026-08-22_arc15-t5-resumption-record.md`, seals section of
  `../../notes/2026-08-23_stepper-arc-design.md`.

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
  `../../notes/2026-08-23_stepper-arc-design.md`.

## Targets (once the stepper sets the proof economics)

- **WireGuard ladder** — `../../notes/2026-08-20_wireguard-target-scoping.md`.
- **pKVM buddy allocator** — `../../deps/CN-pKVM-buddy-allocator-case-study/`;
  GPL-derived fixtures live in a separate example repo per the
  recorded ruling (container CLAUDE.md, layout table).

## Queued larger work

- **Concurrency (cmm) instantiation** — choice streams become
  schedules; the current semantics keeps concurrency stubbed as a
  declared temporal boundary with this arc as its mover.
- **The repo split** — "the semantics" vs "the verification layer" as
  separate repositories; the package structure already rehearses it
  (DESIGN.md §6).

## Small priced items (S each — can ride any fix batch)

- `pr44468.c` offsetof unknown-tag panic (the CI sweep's one new
  defect): `docs/2026-08-22_ci-sweep-results.md`.
- CoreParser `enum TAG` ctype-literal arm (unblocks a parked spec-lab
  pinned layer; reproducers in `tests/speclab/`).
- Oracle `--batch` allocation-census line (unlocks the leak
  conjunct's differential leg; upstream-tray candidate).
- Lean driver `--args` flag (argv parity already verified; unlocks
  the ∀-inputs statement form).
- DivMod local-canonicity consolidation into `Codec.Canonical`
  (noted in `speclab/SpecLab/Codec.lean`).
- Step-runner stack-ceiling guard (long-known residual; registered).

## Deferred polish

- The backend/semantics polish basket (pure-render emission split,
  remaining audit gaps) — registered with prices in the latest
  `docs/*-results.md`; deliberately parked behind the substantive
  track.

## Operator / network-window

- Upstream filing tray: `../../notes/upstream/` + the prepared PR
  branches (worktrees at the container level).
- Prototype disposition (reduce `cerberus-lean-prototype` to a test
  oracle vs archive) — open decision, container `ROADMAP.md`.
