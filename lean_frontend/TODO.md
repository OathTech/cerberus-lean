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

- Step-runner execution ceiling (RE-CHARACTERIZED 2026-08-30: the
  old process-stack overflow no longer reproduces — stack use is now
  iteration-independent down to a 1 MB limit; the binding ceiling is
  the `lemDefaultFuel` = 10^6 totalization budget of
  `drive_nonmemory_steps_aux2`, loud + fail-closed, onset ~1.7e4
  plain loop iterations / ~6e4 C-recursion depth. Correct raise is
  lem-side (per-declaration fuel budgets, or a deliberate constant
  move) → next lem arc; full evidence + design space:
  `docs/2026-08-31_stack-ceiling-design.md`; history:
  `docs/2026-08-19_arc6-s0-survey.md`).
- KNOWN HANG — stack-depth ceiling with a SILENT overflow (found
  2026-09-01, arc/mem-scale P0; profile
  `docs/2026-09-01_mem-scale-profile.md` §6.2-6.3): the Lean driver
  neither completes nor fails on a zero-initialised static aggregate
  of more than ~7-8 million ELEMENTS
  (`tests/mem-scale-probes/probes/a_zero_global_10000000.c`;
  `char g[8000000]` hangs, `char g[7000000]` and `int g[2500000]`
  complete) — all threads futex-blocked after ~4 s CPU at a constant
  ~2.7 GB, deterministic. `LEAN_STACK_SIZE_KB=4194304` makes the 8 M
  case complete (22.5 s), so a non-tail recursion over the element
  list overflows the `lean_run_main` thread stack and the runtime
  hangs instead of printing "Stack overflow detected. Aborting.".
  The oracle completes the 10 M case (246 s / 7.7 GB). Two items:
  locate + tail-recursive rewrite with an equality proof (charter C9,
  `docs/2026-09-01_mem-scale-design.md`); the silent overflow is a
  Lean-runtime report. Fail-open-by-silence until fixed.
- Harness memory limits use `ulimit -v` (virtual address space):
  `scripts/test_ci_sweep.sh:222,252,258`, `scripts/test_libc_exec.sh:
  82,90,97`, `tests/parity-probes/run_probe.sh:43,51`. Lean's virtual
  footprint is ~2-3.6x its RSS, so a 4 GB `-v` kills Lean at ~1.7 GB
  RSS while the oracle runs to 3.1 GB — the detective's two "OOM" rows
  were this artefact (profile §2). Replace with `scripts/capped` (RSS,
  cgroup) — charter C2; then re-run the class-(b) rows.
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
- ~~**Kill the residual effect axiom**~~ — DONE (effect-retirement
  arc, 2026-09-01 C2): `runEffectful` is deleted from LemLib, the
  fresh-symbol supply is threaded explicitly (single stream), the
  digest read is a kernel-checked opaque, and zero `axiom`
  declarations exist anywhere (this repo + LemLib, recursively,
  gate-enforced). Remaining temporal seams with named movers (Q4
  ruling, machine-pinned in `scripts/unsafebaseio_allowlist.txt`):
  CerbGlobal config/switch refs (mover: a parameter-plumbing slice)
  and CerberusImpl's enum registry (mover: the arc's reader/supply
  machinery, follow-up slice).
- **Pin the Lake dependency SET** (C2 audit follow-up, registered
  2026-09-01): no gate asserts the lake-manifest package set, so a
  future `require` would join the built surface outside every census
  (the C2 ratchet scans the LemLib copy because it KNOWS about it);
  relatedly, `.lake/packages` can carry stale non-manifest package
  dirs (worktree-priming leftovers) that a path-glob gate could
  mistake for consumed code. Wanted: a leg that reads
  `lake-manifest.json` (both packages), asserts the package set is
  exactly the reviewed list, and fails on non-manifest directories in
  the shared packagesDir.
- **Raw-string awareness for the census stripper** (C2 delta-audit
  note, registered 2026-09-01): the shared comment/string stripper in
  `check_theorem_axioms.sh` does not know Lean raw string literals
  (`r#"..."#`) — a banned token inside one would be treated as code
  (over-trip, safe) but a `"` inside one could desync the string
  lexer. Zero raw strings exist on the scanned surface today
  (grep-verified at registration). Wanted: stripper hardening, or a
  cheap raw-string ban probe (`r#"` fails until the stripper learns
  the form).
