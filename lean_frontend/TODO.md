# TODO — semantics roadmap and backlog

Grouped by horizon. One line per item; depth lives in the pointed-at
records. (Verification-layer work is out of scope for this branch —
the semantics is the product here; a verification layer consumes it
downstream.)

## Queued larger work

- **Concurrency (cmm) instantiation** — concurrency is currently
  stubbed (a declared, documented boundary); this is the work that
  removes the stub and instantiates Cerberus's concurrency model on
  the Lean side.
- **A-road polish basket** — backend/semantics cleanups (pure-render
  emission split, remaining audit L-slice gaps, ott finish);
  itemized with prices in the latest `docs/*-results.md`;
  deliberately parked behind the substantive track.

## Small items (independent; can ride along with any fix batch)

- `pr44468.c` offsetof unknown-tag panic (the CI sweep's one new
  defect): `docs/2026-08-22_ci-sweep-results.md`.
- CoreParser `enum TAG` ctype-literal arm — a parser-completeness
  hole worth closing on its own merits (reproducers in
  `tests/speclab/`).
- Step-runner stack-ceiling guard (known limitation: loops of a few
  thousand iterations can overflow the process stack in the step/ND
  recursion; `docs/2026-08-19_arc6-s0-survey.md`).
- Oracle `--batch` allocation-census line — would give the speclab
  leak checks an oracle-differential leg (today they are in-Lean
  only); a candidate patch for upstream Cerberus.

## Needs maintainer action or network access

- **Upstream filing tray** — drafted bug reports and prepared PR
  branches from the differential campaigns (several oracle-wrong
  findings pinned Lean-right), maintained operator-side and filed as
  network windows allow.
- Decide the fate of the earlier prototype interpreter (reduce to a
  test oracle vs archive) — open decision.
- **Kill the residual effect axiom** — `with_tagDefs`/`forceIO` are
  already kernel-checked opaques (zero axioms in this repository);
  the residual is `runEffectful` (LemLib, temporal — its deletion is
  lem-side surgery; end state is the fresh-symbol supply threaded
  through the machine state, natural alongside the cmm work).
