# Arc-13 hotfix: the libc.co "floor" — stale generated frontend, cache-masked

**Branch** `arc/hotfix-libc-floor` off mainline `50a200b20` (post-arc-13
merge). Worker record; orchestrator diagnosis CORRECTED below.

## The reported bug (reproduced verbatim)

Post-merge certification, cache-disabled true rebuild of the libc core
object:

```
$ DUNE_CACHE=disabled opam exec --switch=<...>/cerberus-lean -- \
      dune build --force runtime/libc/libc.co
CERB_FRESH_FLOOR_VIOLATION (window-nodraw): symbol id 1 is outside the single-supply window [0..-1] of 'src/ctype.c' — a symbol supply has been re-threaded off Cerb_fresh.int (the F-D-era split-stream scheme, finding F-D: tests/csmith_findings/README.md) or the counter was re-initialized; refusing to continue. Scheme + backstop design: lean_frontend/docs/2026-08-22_arc13-s0-scheme-decision.md.
```

## Root cause — CORRECTED

The working hypothesis ("the multi-file `--rewrite -o libc.co` path does
not run the post-desugar hwm hook") is **refuted**: that path desugars
every TU through `Pipeline.c_frontend` (backend/driver/main.ml `frontend`
→ `c_frontend_and_elaboration` → `c_frontend`), which is exactly where
the hook lives (backend/common/pipeline.ml:204-211, `set_digest` at
:181). The hook RAN — `window-nodraw` is one of its own verdicts. And
the failure was never .co-path-specific: with the same binary, EVERY C
compile floored, single-file modes included (`--syntax-only`, `-c`, a
one-function tiny.c — all `window-nodraw`, all exit 70).

The actual root cause: **the binary had been compiled from a STALE
`ocaml_frontend/generated/` tree.** That directory is gitignored `make
prelude-src` output (frontend `.lem` → OCaml via lem), and:

- the arc-13 D1 re-route (the `declare ocaml target_rep function
  fresh_sym_int = Fork_renumber.fresh_sym_int` in
  frontend/model/cabs_to_ail_effect.lem:631, plus the core_run /
  core_run_aux seams) lives in the `.lem` and takes effect only on
  regeneration;
- the certification checkout's generated tree predated arc-13: zero
  occurrences of `Fork_renumber` in generated code (verified in both
  this worktree as primed AND the primary checkout,
  `grep -c Fork_renumber .../generated/cabs_to_ail_effect.ml` → 0), so
  its `fresh_sym_int` still bumped the dead threaded
  `fresh_sym_supply` — a 0-based supply drawing nothing from
  `Cerb_fresh.int`;
- `dune build` cannot see the `.lem` sources at all (the root `dune`
  `(dirs ...)` stanza excludes `frontend/`), so it silently compiled the
  stale tree into the oracle;
- make's own `.lem → .ml` dependency is mtime-based and can no-op on
  stale CONTENT (worktree priming copies `generated/` with fresh
  mtimes).

So the binary genuinely minted desugar symbols off a re-threaded
0-based supply — **the arc-13 backstop fired CORRECTLY on the exact
hazard class it was built for** (its message is literally accurate:
"a symbol supply has been re-threaded off Cerb_fresh.int — the F-D-era
split-stream scheme"). Nothing on the .co path was ever missing a hook;
what was missing was any enforcement that the generated tree matches
the `.lem` sources at build time.

Why arc-13's validation missed it: the arc worktree HAD regenerated
(its gates were honest); post-merge, the primary checkout / freshly
primed worktrees had not, and dune's cache + already-installed
artifacts (including the correct committed dump pin — the pin was
never wrong) masked the difference until the first cache-disabled true
rebuild.

## The lesson (standing-rule candidate — FLAG FOR THE ORCHESTRATOR)

**Validation of build-rule-affecting changes must be cache-disabled**:
any arc that changes what a build rule PRODUCES (or what its inputs
mean) must include one `DUNE_CACHE=disabled ... --force` rebuild of the
affected artifacts in its gate, from a checkout whose generated trees
were re-derived, not inherited. A cache or a primed copy can serve a
pre-change artifact and turn a broken (or wrong-input) rule green.
Corollary (this incident): **generated-code staleness is a build-input
integrity problem and needs a content gate, not an mtime convention.**

## The fix

A content-hash lem-sync gate, fail-closed, wired into both the dune
graph and the standing unit gate:

- `tools/check_lem_sync.sh` (dune-visible dir; `scripts/` is outside
  the dune workspace): `--record` writes
  `ocaml_frontend/lem_sync.sha256` (next to lem.log, outside
  `generated/` so fork-drift layer 2 never sees it) with two lines —
  `src` = sha256 over all `frontend/{model,concurrency}` `.lem`
  (path-labeled, sorted), `gen` = sha256 over all
  `ocaml_frontend/generated/*.ml`. `--check` recomputes and compares;
  any mismatch / missing stamp / missing tree fails loud (token
  `CERB_LEM_SYNC_STALE`, exit 1) with the forced-regeneration
  remediation (`make clean-prelude-src prelude-src` — plain
  `prelude-src` may mtime-no-op).
- Makefile: the stamp is a grouped target of the lem generation recipe
  and is written ONLY there, immediately after lem+sed — that is what
  makes it trustworthy (`--record` after the fact would launder
  staleness). `clean-prelude-src` removes it.
- `ocaml_frontend/dune`: rule `lem_sync_checked` — `(deps (universe)
  (sandbox none))`, i.e. re-verified on EVERY build, never cached (the
  `version.ml` precedent), reading the source tree via the
  `%{workspace_root}/../..` escape (default build context only, the
  only context this project uses).
- `runtime/libc/dune`: both .co rules (libc.co/libc_inner_arg_temps.co
  and libm.co) depend on the witness — a true rebuild of the shipped
  core objects can never use a stale frontend.
- `scripts/test_unit.sh`: standing lem-sync gate, before fork-drift
  (complementary: fork-drift layer 2 pins generated-vs-upstream diffs
  but loudly SKIPs without the upstream tree; this stamp is
  self-contained and never skips).
- `scripts/fork_drift_manifest.txt`: `ocaml_frontend/dune` +
  `runtime/libc/dune` added to `[files]` (hand-edited minimal delta —
  NOTE: `--refresh` REWRITES the curated header commentary and the
  lem-pin/renumber meta; restored from git and applied by hand. That
  refresh behavior is itself a small finding for a future arc.)

No change to `util/cerb_fresh.ml`, `backend/common/pipeline.ml`,
`backend/common/ail_sym_hwm.ml`, or the driver: the backstop and its
hook coverage were verified correct as-is on every path (the check was
NOT exempted or bypassed anywhere).

## Validation (all builds cache-disabled where dune is involved)

1. **Repro now builds.** After forced regeneration
   (`make clean-prelude-src prelude-src`, recipe records the stamp):
   `DUNE_CACHE=disabled dune build --force runtime/libc/libc.co` →
   success, artifact produced, `grep -c CERB_FRESH_FLOOR_VIOLATION` = 0;
   gate visible in the log:
   `check_lem_sync: OK (src 5824238b..., gen 4f02b439...)`.
2. **Gate plant (staleness must fail-stop).** One comment line appended
   to cabs_to_ail_effect.lem, no regeneration → `dune build
   runtime/libc/libc.co` rc=1:
   `CERB_LEM_SYNC_STALE: frontend .lem sources changed since generation (stamp src 5824238b..., tree 6b536997...) — generated/ is STALE`
   Revert content-verified (git clean), rebuild rc=0, zero gate lines.
3. **Dump byte-identity (arc-13 acceptance, re-verified on a TRUE
   rebuild for the first time).** From the fresh artifact:
   `libc_prep: OK (content hash verified: pin + regenerated dump == bb0560d94f6383cb8057b8c810f6253ff6cd451c10b29a9e0fcd105c3de62197, 4188542 bytes)`
   and against upstream's own dump (upstream oracle
   deps/cerberus-upstream, its own libc.co, same pp recipe): both 89,609
   lines, `cmp` clean — fork=upstream byte-identical; fresh dump sha256
   == committed pin `tests/libc/libc.core.sha256`.
4. **Backstop plant on THIS path (the arc-13 audit-A recipe).**
   `fresh_sym_int` in ocaml_frontend/fork_renumber.ml temporarily
   re-pointed at a private 0-based counter (literally the F-D-era
   scheme; a hand file, so the sync gate stays green and the RUNTIME
   backstop must do the work): `DUNE_CACHE=disabled dune build --force
   runtime/libc/libc.co` rc=1 with
   `CERB_FRESH_FLOOR_VIOLATION (window-nodraw): symbol id 1 is outside the single-supply window [0..-1] of 'src/ctype.c' ...`
   and zero `CERB_LEM_SYNC_STALE` lines — the protection on the
   .co-generation path is real, not the new gate masking. Revert
   content-verified; binaries rebuilt before further measurement
   (B-F7).
5. **Normal-path regression** (fresh post-revert binaries):
   - `test_unit.sh` rc=0 — all unit tests (incl. relsem package) +
     purity, axiom-cone (driver2 sorryAx/DAEMON-free), totality
     (CLEAN, 0 allowlisted), NEW lem-sync gate OK, fork-drift OK
     (layer 1: 58 files = manifest; layer 2: 20 pinned), proof-size OK.
   - `test_exec.sh` rc=0 — `SUMMARY: total=106 match=85 ub_match=18
     ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0
     cerb_skip=3 cerb_floor=0` (baseline, zero movement).
   - `test_libc_exec.sh` rc=0 — `SUMMARY: match=7 diff=0` /
     `ALL MATCH RECORDED BASELINE`.
   - `test_libxml2_uri.sh` rc=0 —
     `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` /
     `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)`.
   - `libc_prep.sh --check` re-run from the POST-REVERT rebuilt
     artifact: same `libc_prep: OK` line, same content hash (B-F7:
     measurement from rebuilt binaries).
   - decl463/decl464 margin synthetics (regenerated per the arc-12
     §1.2 recipe): `decl463 rc=0 floor-lines=0`,
     `decl464 rc=0 floor-lines=0`.
   - csmith witness `csmith_6000098` exec:
     `Defined {value: "Specified(117)", stdout: "", stderr: "", blocked: "false"}`,
     rc=0, floor-lines=0 — the arc-13/upstream value.

   NOTE (expectation correction): the tasking's "decl463/decl464
   (pass/floor)" and "one csmith witness floors" are ARC-12-era
   expectations. Under the merged arc-13 scheme the backstop never
   fires on any in-tree input (acceptance property; results doc §1.2);
   the correct arc-13 baselines are pass/pass and Specified(117), which
   is what was measured.

## Residuals (documented, not silent)

- The stamp does not hash the Makefile's LEM_SRC list or its sed
  patch-ups (a structural Makefile edit without regeneration is not
  caught), nor the lem binary version (a lem re-pin without
  regeneration is not caught — the playbook's rebuild-lem discipline
  plus the runtime backstop cover that path).
- `sibylfs/generated` and `lean_frontend/generated` carry no stamp
  (different failure surfaces; the lean side has its own hand-written
  sync gate).
- `check_fork_drift.sh --refresh` rewrites the manifest's curated
  commentary (observed this hotfix; hand-restored) — future-arc fix
  candidate.

## Operator/orchestrator follow-ups

- **The PRIMARY checkout (`cerberus-lean/`) is confirmed stale** the
  same way (no `Fork_renumber` in its generated tree). After this
  hotfix merges it will fail the new gate LOUDLY instead of building a
  wrong oracle; it needs one `make clean-prelude-src prelude-src` (and
  `scripts/new-worktree.sh` priming then copies a stamped, in-sync
  tree).
- Standing-rule candidate above (cache-disabled validation of
  build-rule-affecting changes) — needs the operator's blessing.
