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

- Step-runner stack-ceiling guard (known limitation: loops of a few
  thousand iterations can overflow the process stack in the step/ND
  recursion; `docs/2026-08-19_arc6-s0-survey.md`).
- Speclab leak checks' oracle-differential leg: wire the new oracle
  `--batch-alloc-census` line (landed 2026-09-01,
  `docs/2026-09-01_s-basket.md`) into the speclab lanes.
- Upstream-tray candidate (found 2026-09-01, S-basket item 1): the
  sizeof/alignof Union arms read the Tags GLOBAL (impl_mem.ml:173,
  :255) while the rest of the layout family threads ~tagDefs —
  elaboration-time offsetof over a union-containing struct crashes
  upstream (probed, exit 125); pinned as a crash pair
  (tests/immaculate/nolibc/offsetof-union-member.c).

(2026-09-01: the pr44468 offsetof panic, the CoreParser `enum TAG`
arm, the `--args` flag, the allocation-census line, the DivMod
canonicity consolidation, the printf/Monadic_parsing totalization
tail, and the Lean-side lem-sync freshness stamp all closed in the
S-basket slice — `docs/2026-09-01_s-basket.md`.)

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
