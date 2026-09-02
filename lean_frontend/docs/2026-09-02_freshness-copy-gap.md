# Hotfix record: the driver-freshness copy gap (2026-09-02)

STATUS: hotfix worker record; branch `fix/freshness-copy-gap`, base
mainline `4cb8c4ee9`. Addendum to the trust-basket record
(`docs/2026-08-31_trust-basket.md` §1, item (a) — the driver-binary
freshness stamp). Provenance: defect found by the orchestrator
[AGENT 2026-09-02] on the primary checkout; fix design and plants
[AGENT] (this worker) per the orchestrator's brief. Quoted outputs are
verbatim; the copy-set count is measured.

## 1. The defect (fail-open in a trust gate)

Lake compiles the Lean driver from `lean_frontend/generated/`
(`lakefile.toml` `srcDir = "generated"`). The hand-written
`lean_frontend/*.lean` files reach that tree only as COPIES made by
the `make lean-prelude-src` recipe (Makefile `LEAN_HANDWRITTEN`).

Observed on the primary checkout after a mainline merge changed the
hand-written `lean_frontend/CerbMem.lean` (the mem-scale C3 text):
`scripts/common.sh build_lean` was run WITHOUT `make lean-prelude-src`.
Lake built from the stale `generated/CerbMem.lean` (pre-C3), so the
binary hash was unchanged (`91c805fb…`), while `check_driver_fresh.sh
--record-lean` stamped the NEW source hash over it. Consequently:

- `check_driver_fresh.sh --check` → `lean OK` (bin and src both
  matched the stamp — the stamp was recorded over the stale binary);
- `check_lem_sync.sh --check-lean` → OK (its Lean stamp hashes only the
  .lem-derived files, excluding the hand-written copies by design).

Two green gates attesting a binary that did not correspond to its
sources: the exact class item (a) was built to close. Root cause: the
lean source hash covered BOTH `lean_frontend/X.lean` and
`generated/X.lean`, but a hash cannot see that the two DIFFER. The only
comparison of the pair was `test_unit.sh`'s sync gate — which is not
on the build_lean / record / SKIP_BUILD path, and parsed the Makefile
with its own awk (a second, drift-prone reader of the list).

Reproduced here: `scripts/new-worktree.sh` primed this worktree's
`generated/` from the primary checkout; `generated/CerbMem.lean`
differed from the hand-written file at byte 32742 (line 654, the C3
fold rewrite) — the natural stale state, used as the first plant.

## 2. The fix

1. **One authority for the copy set.** New file
   `lean_frontend/handwritten_copy.manifest` (one basename per line,
   `#` comments). The Makefile reads it —
   `LEAN_HANDWRITTEN := $(strip $(shell sed -n '/^[A-Za-z]/p' …))` —
   and `$(error …)`s at parse time if it is missing or empty. The
   recipe's `[COPY]` line names the count and runs the gate (below)
   immediately after copying. The previous ad-hoc list in the Makefile
   and the awk parse in `test_unit.sh` are gone.
   **Copy set: 21 files** (derived: the manifest's entries; verified
   equal to the old Makefile list AND to `ls lean_frontend/*.lean`
   before the switch — the set is exactly the top-level hand-written
   files).
2. **The gate: `tools/check_handwritten_sync.sh`** (no stamp — a direct
   `cmp` of every listed file against its `generated/` copy). Fails
   closed on: missing/empty manifest (vacuity is loud), a missing
   source, a missing copy, any byte drift (naming the file), and any
   `lean_frontend/*.lean` NOT listed (the manifest cannot silently
   drift from the tree). Token `CERB_DRIVER_STALE`.
3. **Wiring** (every path that builds, records or trusts the Lean
   driver):
   - `tools/check_driver_fresh.sh`: `--record-lean` and every lean
     `--check` first require the copy-set gate — no stamp is recorded,
     and no check passes, over a drifted copy set. The manifest joins
     the lean source hash.
   - `scripts/common.sh build_lean`: precondition — REFUSES to build.
   - `scripts/test_unit.sh`: the sync gate is now this tool.
   - `Makefile lean-prelude-src`: post-copy self-check.
   - `tools/check_lem_sync.sh`: unchanged behaviour; header states why
     the copies stay OUT of its stamp (a stamp is for a derivation
     whose input is not directly comparable to its output; here the
     source sits next to the copy, so `cmp` is strictly stronger than
     any recorded hash and has no stamp state that can itself go
     stale).
4. **Refuse-only, not auto-propagate** (brief item 4; [AGENT] choice):
   (i) the copy step keeps exactly one authority, the Makefile recipe —
   a second `cp` path in common.sh would be a mirror that can drift
   from it; (ii) a stale copy set is the SYMPTOM of a skipped
   regeneration, and the lem-derived files may be stale with it — the
   right remedy is the whole recipe, which every refusal names. Cost
   when in sync: 21 `cmp` calls.

## 3. Plants (verbatim)

Worktree: `worktrees/cerberus-lean-fix/freshness-copy-gap`, all via
`scripts/ce`, Lean builds under `CERB_MEM_MAX=32G` through
`scripts/capped`.

**(a-natural) the primed stale tree, before any regeneration** —
`bash -c 'source scripts/common.sh; build_lean'`:

    Building cerberus-lean (Lean)...
      SYNC: hand-written source lean_frontend/CerbMem.lean not propagated to generated/ (run make lean-prelude-src)
    CERB_DRIVER_STALE: hand-written source lean_frontend/CerbMem.lean not propagated to generated/ (run make lean-prelude-src) — 1 drift(s), 0 unlisted file(s)
    …
    Error: build_lean REFUSED — hand-written lean_frontend/*.lean not propagated to lean_frontend/generated/ (run: make lean-prelude-src, then build_lean); building now would produce a binary that does not correspond to its sources
    rc=1

`--check-lean` and `--record-lean` on the same tree: same
`CERB_DRIVER_STALE … CerbMem.lean` lines, rc 1, no
`driver_fresh.lean.sha256` written.

Remedy: `make lean-prelude-src` (16.9 s wall):

    [COPY] 21 hand-written Lean files (lean_frontend/handwritten_copy.manifest) into [lean_frontend/generated]
    check_handwritten_sync: OK (21 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    [STAMP] recording Lean lem-sync content stamp
    check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src f4c0096697fb68c508acbe35423ed0fce77c6988ceafcaffe772924358e8a624, gen 6c2ae2041cceb0aed61cae04917144131fe96940e2aec6213d43b13b9d8fd5e7)

then `DUNE_CACHE=disabled build_cerberus` + `CERB_MEM_MAX=32G build_lean`
(15:21:07 → 15:21:43 UTC; 42 oleans newer than build start,
`CerbMem.olean` 15:21:15 → `Main.olean` 15:21:42 — Lake really
recompiled the chain):

    check_driver_fresh: recorded oracle stamp (bin 376e3c46128781d7e32a726df3a5888e85f6978ac0f5c2412c0da34fdf96be8a, src a54c0b1f9930ab521fd3ddd5d187fa2684ed757acd4d6e08e92557f4461fe745)
    ✔ [271/271] Built «cerberus-lean»:exe (528ms)
    Build completed successfully (271 jobs).
    check_driver_fresh: recorded lean stamp (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src 7349cc5839386c12015f4ed2b3f6f29deed0269dd5667cc2370ac52f6e039f1b)

Cross-check: `406960e9…` is byte-identical to the primary checkout's
current `cerberus-lean` (the orchestrator's post-discovery rebuild from
propagated sources) — content-identical trees, identical binary.

**(b) green after regeneration** — `tools/check_driver_fresh.sh --check`:

    check_driver_fresh: oracle OK (bin 376e3c46128781d7e32a726df3a5888e85f6978ac0f5c2412c0da34fdf96be8a, src a54c0b1f9930ab521fd3ddd5d187fa2684ed757acd4d6e08e92557f4461fe745)
    check_driver_fresh: lean OK (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src 7349cc5839386c12015f4ed2b3f6f29deed0269dd5667cc2370ac52f6e039f1b)
    rc=0

**(a) the brief's plant: comment appended to `lean_frontend/CerbMem.lean`,
no lean-prelude-src** (script `.tmp/plant_a.sh`, log kept only for the
slice):

    --- (a1) check_driver_fresh --check (stamp + binary unchanged from the green state)
    check_driver_fresh: oracle OK (bin 376e3c46…, src a54c0b1f…)
      SYNC: hand-written source lean_frontend/CerbMem.lean not propagated to generated/ (run make lean-prelude-src)
    CERB_DRIVER_STALE: hand-written source lean_frontend/CerbMem.lean not propagated to generated/ (run make lean-prelude-src) — 1 drift(s), 0 unlisted file(s)
    …
    CERB_DRIVER_STALE: lean driver check refused — hand-written sources not propagated to lean_frontend/generated/ (no stamp is recorded over a stale copy set; run make lean-prelude-src, then rebuild)
    rc=1

    --- (a2) check_driver_fresh --record-lean (the defect's exact shape: re-record over the unchanged binary)
    …
    CERB_DRIVER_STALE: lean driver record refused — hand-written sources not propagated to lean_frontend/generated/ (no stamp is recorded over a stale copy set; run make lean-prelude-src, then rebuild)
    rc=1
    stamp after refused record:
    commit 4cb8c4ee9f138ae474a08ad5d6b2c38db823ded4 +dirty
    bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7
    src 7349cc5839386c12015f4ed2b3f6f29deed0269dd5667cc2370ac52f6e039f1b

    --- (a3) build_lean (the orchestrator's exact command)
    Building cerberus-lean (Lean)...
      SYNC: hand-written source lean_frontend/CerbMem.lean not propagated to generated/ (run make lean-prelude-src)
    …
    Error: build_lean REFUSED — hand-written lean_frontend/*.lean not propagated to lean_frontend/generated/ (run: make lean-prelude-src, then build_lean); building now would produce a binary that does not correspond to its sources
    rc=1
    binary after refused build: 406960e92de44c2f

(a2) is the fail-open shape itself: under the old script this call
would have written a stamp with the new src hash over the unchanged
binary. The stamp is untouched.

**(b) again, after `make lean-prelude-src` with the plant comment:**

    [COPY] 21 hand-written Lean files (lean_frontend/handwritten_copy.manifest) into [lean_frontend/generated]
    check_handwritten_sync: OK (21 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    --- --check with copies propagated but binary not yet rebuilt (must be red on the src leg, not the copy leg)
    CERB_DRIVER_STALE: lean driver binary failed the freshness check: source tree changed since the binary was recorded (stamp src 7349cc58…, tree bad6bcd8…) — the binary is STALE
    --- build_lean
    Build completed successfully (271 jobs).
    check_driver_fresh: recorded lean stamp (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src bad6bcd81327e235a979687edb235e06fa2239ef3e02cbbe79c93643245c30ef)
    rc=0
    --- --check
    check_driver_fresh: lean OK (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src bad6bcd81327e235a979687edb235e06fa2239ef3e02cbbe79c93643245c30ef)
    rc=0

Note the binary hash is UNCHANGED by a comment-only edit (`406960e9…`
before and after) — exactly the property that made the bin-hash leg
blind to the original defect; the layered legs (copy set → src hash →
bin hash) now each refuse their own class. Restore (`git checkout --
lean_frontend/CerbMem.lean`): the gate flips red in the other direction
(`generated/` carries the plant, the source does not); `make
lean-prelude-src` + `build_lean` → `--check` green, stamp back to
`src 7349cc58…`, binary `406960e9…` (== baseline). Two rc=141 lines in
the plant log are SIGPIPE from the script's `| head -1`, not the tool's
exit; every un-piped invocation above shows rc=1.

**(c) vacuity** — manifest reduced to its comment lines / removed:

    === PLANT (c1): comment-only (empty) manifest -> check_driver_fresh --check-lean ===
    rc=1
    CERB_DRIVER_STALE: copy-set manifest lean_frontend/handwritten_copy.manifest lists no files — an empty copy set is a FAIL, not a vacuous pass
    (stamp untouched)
    === PLANT (c2): manifest missing -> check_handwritten_sync ===
    rc=1
    CERB_DRIVER_STALE: copy-set manifest lean_frontend/handwritten_copy.manifest missing — the hand-written->generated/ copy set cannot be enumerated (an unknown copy set is a FAIL, not an empty pass)
    === PLANT (c2b): manifest missing -> build_lean ===
    rc=1
    Error: build_lean REFUSED — …
    === PLANT (c3): empty manifest at Makefile parse time ===
    Makefile:324: *** "lean_frontend: hand-written copy manifest lean_frontend/handwritten_copy.manifest missing or empty (fail-closed; nothing would be copied into generated/)".  Stop.
    rc=2

Manifest restored byte-identical (`cmp` against the saved copy);
`check_handwritten_sync: OK (21 …)`.

## 4. Gates at the commit

(The gate change must not move any baseline — it is a gate, not a
lane.)

`./scripts/test_unit.sh` (Tier A #1), rc 0 — first line and totals:

    check_handwritten_sync: OK (21 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
    Done: 282 passed, 0 failed
    Total: 5 passed, 0 failed
    === test_unit rc=0 ===

`./scripts/test_exec.sh --check-baseline` (Tier A #2, `exec_minimal`),
rc 0 — both drivers rebuilt+re-recorded by the lane, then:

    SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    BASELINE OK
    === exec_minimal rc=0 ===

No baseline moved. Stamps at the commit: oracle bin `376e3c46…`,
lean bin `406960e9…` (`--check` green, §3(b)).

## 5. Residuals / non-goals

- Direct `lake build` outside `common.sh`/the Makefile still bypasses
  the precondition (same declared chokepoint as item (a): the lane
  surface). The stamp's `--check` catches it afterwards on the copy
  leg, and `test_unit` on the sync gate.
- `check_lem_sync --check-lean` deliberately keeps excluding the
  copies (§2.3); its residuals are unchanged.
- Container-side: `scripts/new-worktree.sh` priming can still carry a
  stale `generated/` tree (it did here) — that is now a loud refusal
  on the first `build_lean`, with the remedy named. Not versionable in
  this repo.
- Doc pointers updated: `lean_frontend/CLAUDE.md` (the copy-step
  section), `lean_frontend/VALIDATION.md` (sync-gate row); the
  trust-basket record §1 is addended by this file rather than edited
  (record integrity).
