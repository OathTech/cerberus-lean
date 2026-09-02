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
- KNOWN HANG — FRONT-END stack-depth ceiling with a SILENT overflow
  (found 2026-09-01, arc/mem-scale P0; re-scoped R1 2026-09-02;
  profile `docs/2026-09-01_mem-scale-profile.md` §6.2-6.3): the Lean
  driver neither completes nor fails on a zero-initialised static
  aggregate of more than ~7-8 million ELEMENTS
  (`tests/mem-scale-probes/probes/a_zero_global_10000000.c`;
  `char g[8000000]` hangs, `char g[7000000]` and `int g[2500000]`
  complete; `--pp-core` ALONE hangs, so it is the front end, not
  CerbMem). strace: the working thread takes SIGSEGV SEGV_ACCERR
  (stack guard page of the runtime thread's 1 GiB stack) and then
  blocks forever in `futex(FUTEX_WAIT_PRIVATE)` inside the handler —
  no "Stack overflow detected. Aborting." Prime candidate:
  `cabs_to_ail_aux.lem:124` N-element ConstantArray →
  `ail/genTyping.lem:484` `E.mapM` → `ail/errorMonad.lem:86-92`
  non-tail `ailErr_mapM` (`generated/ErrorMonad.lean:121`, partial
  def; same shape `state_exception.lem:79` foldrM, `Undefined.lean:
  1390` sequence0). Oracle contrast: `OCAMLRUNPARAM=l=200000` fails
  LOUDLY in 0.03 s (exit 125). Three items: (a) fix = .lem
  accumulate-and-reverse (tray) or lem-backend tail rendering — a
  TWO-REPO slice; no equality theorem possible (partial def), gate =
  completion + battery; (b) Lean upstream bug report (signal-handler
  deadlock after guard-page SIGSEGV) with the strace excerpt; (c)
  interim LOUDNESS: HANG classification (exit 124 with CPU/wall <
  0.1) — DONE in S0 (2026-09-02): `scripts/common.sh classify_exit124`
  shared by `scripts/test_exec.sh` (status `HANG`, fatal) and
  `scripts/test_ci_sweep.sh` (`LEAN_HANG`/`CERB_HANG`); plant
  `scripts/test_hang_plant.sh` (sleep→HANG, busy→TIMEOUT, both lanes);
  the 10 M probe reads `HANG(cpu 3.29s of 400.12s wall)` in
  test_exec.sh; no committed row changed class. Item (b) drafted:
  `docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`.
  Never a stack-size knob (charter C9, `docs/2026-09-01_mem-scale-design.md`).
  RULED [AGENT 2026-09-02, orchestrator, operator-informed] (Q5): fix
  at source in the cerberus `.lem` (accumulate-and-reverse mapM; NOT a
  lem-backend change unless the completion gate shows the tail call
  is not realised — charter §6.0/§6.3); plant-tested completion gate
  = a_zero_global_10000000 Lean --first completes with the oracle's
  verdict, asserted as status, never timing.
  OUTCOME (mem-scale S1', 2026-09-02; record
  `docs/2026-09-02_mem-scale-record.md` §S1'): the `.lem`
  accumulate-and-reverse rewrite was built and measured — it moved the
  onset (8 M elements now COMPLETE with the oracle's verdict; 10 M
  still hang) — and then REVERTED per [USER 2026-09-02] ("revert S1'
  I think - poor roi for a change to the trust surface"). Mechanism
  located first-hand: our emitted C is tail-shaped (`jmp lean_apply_*`),
  but the Lean 4.32.2 RUNTIME's `lean_apply_1/2` enter the closure by
  indirect CALL on 22 of 24 arity paths, so every per-element closure
  application in a function-typed monad's run loop costs one
  `lean_apply_*` frame (~110 B/element; 1 GiB thread stack ⇒ ~8 M
  elements). STANDING CEILING, now LOUD (S0 HANG class); registered in
  VALIDATION.md §5. FALLBACK CANDIDATE for the next lem arc (class 0,
  Lean-emission-only, needs its own ruling): a lem-backend RUN-LOOP
  rendering of the monadic list combinators (`mapM`/`sequence`/`foldrM`)
  for function-typed monads — interpret the list inside the `run`
  function directly, no per-element closure application — so the
  OCaml text is untouched and the Lean side stops paying the runtime
  frame. Companion (runtime-side, upstream): make `lean_apply_*`'s
  exact-arity paths tail calls — noted in
  `docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`.
  Upstream-facing source fix drafted regardless: tray draft 18.
- ~~Harness memory limits use `ulimit -v`~~ — DONE (mem-scale S2,
  2026-09-02: `e02d4105a` migration of all 20 code sites + 2 header
  comments to per-test `scripts/capped` at `CERB_TEST_MEM_MAX=4G`;
  `e866357c6` OOM-witness classification; `de574fbc8` baseline
  instrument; record `docs/2026-09-02_mem-scale-record.md` §S2). The
  original item, for the record: `ulimit -v` (virtual address space) in
  SEVEN harnesses: `scripts/test_ci_sweep.sh:222,252,258`,
  `scripts/test_libc_exec.sh:82,90,97`, `tests/parity-probes/
  run_probe.sh:43,51,56`, `scripts/test_gcc_oracle.sh:361,368`,
  `scripts/test_libxml2.sh:141,159,191,201`, `scripts/
  test_libxml2_uri.sh:104,174`, `scripts/test_immaculate.sh:116,123,
  131` — and `scripts/LADDER.md:73` makes it normative (operator
  directive, arc 5). Lean's virtual footprint is ~2-3.6x its RSS, so
  a 4 GB `-v` kills Lean at ~1.7 GB RSS while the oracle runs to
  3.1 GB — the detective's two "OOM" rows were this artefact (profile
  §2); the libxml2 lanes are biased against Lean today. RULED [USER
  2026-09-02] ("Q2 agree"): superseded by per-test `scripts/capped`
  with `CERB_MEM_MAX=4G`; LADDER.md:73 text updated; migration of the
  seven harnesses + dedicated baseline-instrument commit = mem-scale
  S2 (charter §6.4); then re-run the class-(b) rows.
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
