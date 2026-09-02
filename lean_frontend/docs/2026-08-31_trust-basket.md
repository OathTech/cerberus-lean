# Trust-basket slice record (2026-08-31)

Branch `fix/trust-basket` @ base mainline `07a7fca29`. Worker:
TRUST-BASKET. Charge ([USER], via orchestrator brief): five priced
fixes from the parity-detective report and the gcc-oracle-lane audit
notes — (a) driver-binary freshness stamp, (b) CerbFS fail-closed,
(c) `--cabs-json` stop-after-parse, (d) `build_lean` success gating,
(e) triage-parser glob hygiene. One commit per item; quoted outputs
are verbatim; tallies marked *derived* are computed from recorded
runs. All design choices below are [AGENT] unless marked.

## 0. Preconditions (the brief's mandatory first step)

Both driver binaries rebuilt fresh before any differential claim
(the detective was bitten by primed-stale binaries):

- oracle: `make prelude-src` + `DUNE_CACHE=disabled dune build
  backend/driver/main.exe cerberus-lib.install` + `dune install
  cerberus-lib` + `dune build cerberus.install`, rc 0; binary mtime
  19:01 vs worktree checkout 18:59 (2026-08-30 UTC).
- Lean: `make lean-prelude-src` + `capped lake build`
  (CERB_MEM_MAX=32G), rc 0; binary mtime 19:03.

## 1. Item (a) — driver-binary freshness stamp (commit `51e5d7461`)

Mechanism (the lem-sync stamp's sibling; pattern studied from commit
`8545eb8a7`): `tools/check_driver_fresh.sh` records, per driver
binary, a gitignored repo-root stamp

    commit <HEAD sha>[ +dirty]   (informational only — content-
                                  identical worktrees are fresh)
    bin <sha256 of the binary>
    src <sha256 over the source set feeding that binary>

Source sets (over-approximations deliberate): oracle = dune-project +
dune/`*.ml*`/`*.lem`/`*.c`/`*.h` under backend/ frontend/ memory/
ocaml_frontend/ parsers/ sibylfs/ util/; lean = hand-written +
generated/ + relsemcore/ `.lean`, lakefile.toml, lake-manifest.json,
lean-toolchain, native/`*.{c,o}` (the untracked-`.o` gotcha is inside
the hash). Check cost ~0.1 s (232 lean-side files; measured).

Wiring (`scripts/common.sh`): `build_cerberus`/`build_lean` record on
every successful build; under `SKIP_BUILD=1` — the only common.sh
path that uses a binary without rebuilding it — every PRESENT binary
is verified at source time, fail-closed (a missing binary is left to
the lane's own existence checks: it cannot fabricate results).
Override for intentional cross-version runs:
`CERB_DRIVER_FRESH_OVERRIDE=1`, loud on every use.

Deliberate divergence from the brief's "stamp next to each binary"
(the brief allowed adjusting to the existing pattern): foreign files
under `_build`/`.lake` are the documented dune-tamper hazard and
`clean` would silently delete them; root placement mirrors
`ocaml_frontend/lem_sync.sha256`.

Plant evidence (verbatim key lines):

- Missing stamp, `SKIP_BUILD=1 ./scripts/test_cabs_json.sh`:

      CERB_DRIVER_STALE: oracle driver binary failed the freshness check: stamp driver_fresh.oracle.sha256 missing — binary provenance unknown (primed tree or build outside scripts/common.sh; a missing stamp is a FAIL, not a pass)

  rc 1 — missing stamp is a FAIL, not a pass (vacuity direction).
- Stale source (comment appended to `backend/driver/main.ml`):

      CERB_DRIVER_STALE: oracle driver binary failed the freshness check: source tree changed since the binary was recorded (stamp src 3a858134…, tree cdfc654a…) — the binary is STALE

  restore → `check_driver_fresh: oracle OK`.
- Doctored stamp `bin` field (foreign/primed-binary simulation):

      CERB_DRIVER_STALE: lean driver binary failed the freshness check: binary is not the recorded build (stamp bin 00000000…, actual df22f415…) — foreign/primed binary, or rebuilt without re-recording

- Stale lean generated tree (line appended to `generated/Main.lean`):

      CERB_DRIVER_STALE: lean driver binary failed the freshness check: source tree changed since the binary was recorded (stamp src 70d7ba20…, tree 839e49b6…) — the binary is STALE

  restore → `check_driver_fresh: lean OK`.
- Override on a staled state:

      CERB_DRIVER_FRESH_OVERRIDE ACTIVE: skipping oracle driver freshness check — results are only meaningful for a deliberate cross-version run

  (proceeds, rc 0 — loud, never quiet).
- Positive control: full `test_cabs_json.sh` lane green with
  build+record wiring.

Declared non-goals (same class as the lem-sync stamp's): opam
switch/Lean toolchain binaries and the Lake packages tree are not
hashed (the manifest pin is the identity); direct binary use outside
common.sh (e.g. `tests/parity-probes/run_probe.sh`) is not covered —
the gate's chokepoint is the lane surface. Container-side:
`scripts/new-worktree.sh` priming can carry the stamps (they are
content-addressed — a carried stamp from a content-identical tree
legitimately passes; a diverged tree fails, the detective's exact
scenario). Not versionable here.

## 2. Item (b) — CerbFS fail-closed (commit `7c4888d7b`)

The detective's S-priced half-fix, exactly (the M-priced real-offset
implementation deliberately NOT attempted). `CerbFS.lean` now tracks
per-fd offsets honestly; the served set at this commit was: read at
offset 0 (whole prefix, advances offset) or at EOF (empty);
write/pwrite as pure append at end-of-file; pread at 0/EOF.
Everything else panics with a named `CerbFS refusal (fail-closed
fs-model boundary)` message. **Precision correction (audit F1, §7):
"serves only patterns it answers correctly" was an overstatement at
this commit — flag-blind `fs_open` left truncate-on-reopen serving
stale data with no refused op on the path. Closed by the §7
audit-response commit; the precise served/refused/known-divergent
partition now lives in the CerbFS.lean header and §7.** `panic!` rather than an `FsError` is
deliberate and documented in-code: `driver.lem`'s `store_error`
(~:211) turns an FsError into errno + −1, which the C program can
absorb into a *different* wrong answer; `panic!` is the house
fail-stop sentinel (LEAN_ABORT_ON_PANIC=1 in `run_cerberus_lean`).

Probe evidence (fresh binaries, `run_probe.sh`, values verbatim):

| Probe | Oracle | Lean before | Lean after |
|---|---|---|---|
| `probes/fgetc_eof.c` | `Specified(2)` | `Specified(10)` (loop cap) | `Specified(2)` **AGREE** |
| `probes/fseek_read.c` | `Specified(42)` | `Specified(119)` | refusal, exit 134 |
| `probes/fread_seq.c` | `Specified(22)` | `Specified(1)` | refusal, exit 134 |
| `tests/tcc/40_stdio.c` | `Specified(0)` | LEAN_TIMEOUT (exit 124 @15 s) | refusal, exit 134, immediate |

fgetc_eof turning CORRECT (not merely refused) is the honest-offset
subset at work: the buffered whole-file read is a whole-prefix read
followed by an at-EOF read, both inside the correct-answer set.
Refusal line shape (verbatim, fseek_read):

    PANIC at CerbFS.fs_read CerbFS:183:8: CerbFS refusal (fail-closed fs-model boundary): read on fd 4 at offset 2 of 4-byte file 'v.txt' — the minimal fs model can only serve whole-prefix (offset 0) or at-EOF reads; answering would return WRONG data (CerbFS.lean header; mover: real per-fd offset semantics)

Unchanged, out of this item's scope: `tests/freebsd/cat.c` (its own
`assert()` fires before any offset-sensitive read — pre-existing
LEAN_FAIL class, not a silent wrong answer; verified post-change) and
`tests/suite/fs/stat.c` (zeroed-stat-fields STDOUT_DIFF — not
offset-dependent; still a declared divergence with the same mover).

"Nothing in the passing corpus exercises the refused paths" was
VERIFIED, not assumed: full Tier A ladder green post-change (13/13
lanes, §6).

## 3. Item (c) — `--cabs-json` stop-after-parse (commit `39427278c`)

Oracle-side driver fix in `backend/driver/main.ml` (fork-local flag —
no upstream-tray entry): the path now mirrors the in-file
`cn_spec_json` parse-only precedent (`Cerb_fresh.set_digest` + cpp +
parse + serialize; set_digest cite `backend/common/pipeline.ml:181`)
instead of running the full `c_frontend` and discarding everything
but the parse tree. Certification-integrity: oracle rebuilt
`DUNE_CACHE=disabled` for all validation below.

- (i) The 43 sweep-recorded `CERB_INCONSISTENT` files (list derived
  from `tests/parity-probes/sweep-2026-08-30/*.tsv`; 17 cheri-ci,
  18 ci, 3 gcc-torture, 5 suite): pre-change 0/43 emitted JSON,
  post-change **43/43**.
- (ii) All 43 through the differential probe runner (sweep modes: ci
  → nolibc, others → libc): **43/43 AGREE** on translation-time UB
  codes (UB004a–d, UB059, UB060, UB081, UB084, UB086, UB089, UB097,
  UB204, `UB204_illtyped_Static_assert`, …; per-file rows preserved in
  the run log). **No divergence finding**: no file where Lean accepts
  what the oracle's desugar rejects. Distribution (derived from the
  43 verdicts): 15 distinct UB codes, all message-level AGREE.
- (iii) Byte-identity for previously-succeeding files: 126-file
  sample (tests/minimal ×106 + tests/ci ×20), pre/post JSON
  `cmp`-identical **126/126, diff=0**; plus the full battery (§6).

Lane consequence, anticipated by the lane's own fail-closed design:
`test_bytes.sh`'s NEG leg pinned "`--cabs-json` must FAIL" for its 5
desugar-level byte-typing rejects and instructed, in its own header,
to "extend the leg to Lean-side desugar rejection" if the oracle ever
emitted JSON there. The first post-change Tier A run tripped exactly
that pin (verbatim):

    [FAIL] byte_is_not_char.c: oracle now EMITS Cabs-JSON for an expected-reject file — extend the NEG leg to Lean-side desugar rejection

Extended exactly as instructed, which *closes the leg's recorded
arc-10 S3b residual* (the Lean byte-typing rules were unreachable):
the Lean pipeline must now REJECT each JSON with rc 1 (the committed
`.elab` rc) and a desugaring/typechecking `Error` at the committed
diagnostic line; the no-JSON direction is now pinned as a failure too
(fail-closed both ways). Result: all five reject at the committed
lines (e.g. `Error {msg: "typechecking failed at
tests/bytes/byte_is_not_char.c:4:14-17"}` vs committed
`byte_is_not_char.c:4:14: error: constraint violation: initializing
'byte' …`). Plant: doctored pin line 8→9 for `no_add.c` →

    [FAIL] no_add.c: JSON emitted but the Lean pipeline did not reject as pinned (rc=1, wanted rc 1 + Error at line 9): Error {msg: "typechecking failed at …/tests/bytes/no_add.c:8:5-10"}

restore → `SUMMARY: exec_match=9 neg_pinned=5 fail=0`.

### (c) interaction finding: gcc-lane SKIP_ORACLE rows

The gcc lane's committed baseline carries 3 `SKIP_ORACLE` rows whose
cause was "cabs-json refusal" (`tests/debug/ub-inconsistent.c`,
`tests/debug/ub-static-reject.c`, `csmith/smx_csmith_6.c`). Parse-only
`--cabs-json` now emits JSON for at least the two debug files
(verified), so these rows move in the first full post-(c) gcc run —
an anticipated, (c)-explained instrument-coverage expansion, not a
regression. Disposition in §5. (The csmith corpus baseline is
structurally unaffected: its `CERB_SKIP` rows come from oracle EXEC
failures, and `test_exec.sh`'s `CERB_INCONSISTENT` is a different,
exit-code-consistency class — both checked, not assumed.)

## 4. Item (d) — build success gating (commits `6dfc9a88d`, `8a90d9c28`)

`build_lean` (audit note 6): the old `capped lake build … | tail -3`
swallowed lake's exit status and gated on binary existence only — a
broken incremental build over a pre-existing binary ran stale. Now
the build's own rc is the gate (output log-captured; success prints
the same tail −3; failure prints the last 40 lines and exits 1).
Plant (verbatim key lines): broken `generated/CerbFS.lean` →
`test_cabs_json.sh` rc 1 with

    Error: cerberus-lean build FAILED (lake build exit nonzero); last 40 lines:
    error: generated/CerbFS.lean:311:0: unexpected end of input; expected ')', '_' or identifier

restore → lane green (`Results: 1 passed, 0 failed`).

Follow-up commit (found while writing the item-d disposition, fixed
rather than recorded): with the item-a recorder at the end of
`build_cerberus`, the same rc-swallowing shape on the two `dune
build` invocations was no longer merely a stale-run defect — a
swallowed dune failure would have let the recorder bind the OLD
binary to the NEW tree, i.e. FABRICATE a freshness witness. Both dune
invocations now gate on rc. Plant: broken `backend/driver/main.ml` →
rc 1, `Error: cerberus build FAILED (dune exit nonzero)` +
`Error: Syntax error: operator expected.`; restore → green. (The
worker also hit this live during the slice: a CerbFS build failure
behind `| tail -2` let a manual `--record-lean` run on a failed
build — the defect shape witnessed in the wild before it was fixed.)

## 5. Item (e) — triage-parser glob hygiene (commit `9cd0429e2`)

`scripts/test_gcc_oracle.sh:193` (triage-ledger parser) split lines
with unquoted `set -- $line`; a glob character in the free-text
rationale would expand against the cwd. Fixed with `set -f`/`set +f`
scoped around exactly the split; the two sibling `set -- $line`
parsers (baseline + status files, lines ~595/605) got the same
one-line guard (same defect class, controlled 3-field inputs).

Hazard micro-repro (verbatim; a rationale containing `*`, run in
`scripts/`):

    WITHOUT set -f: nf=61 f5=address f6=canonicalize_ids.py
    WITH set -f:    nf=7 f5=address f6=*

— without the guard the `*` splices the directory listing into the
parsed fields; with it, 7 fields and the literal `*`.

Baseline reproduction after the change — full run,
`--check-baseline`, rc 0, `gcc second-oracle lane OK`, all 9 triage
entries parsed and applied. SUMMARY (verbatim):

    SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9

The deltas vs the brief's expected summary (`compared=1879 agree=1870
skip_lean_crash=10 skip_lean_fail=7 skip_oracle=3 skip_ub=43`) are
NOT from the glob guard (expansion-behavior-only); each row is
attributed:

- `tests/debug/ub-inconsistent.c` SKIP_ORACLE → SKIP_UB
  (`UB:UB061_no_named_members`), `tests/debug/ub-static-reject.c`
  SKIP_ORACLE → SKIP_LEAN_FAIL (Lean desugar reject),
  `csmith/smx_csmith_6.c` SKIP_ORACLE → SKIP_LEAN_FAIL (Lean
  typechecking reject): the §3 item-c coverage expansion, reported by
  the lane as same-rank skip churn (`changed (same rank)`) — rc-0 by
  the lane's documented design (design note §6).
- `tests/immaculate/nolibc/offsetof-nested-struct.c`
  SKIP_LEAN_CRASH → AGREE (`gcc=0 lean={0}`): improvement, rc-0 by
  design. FINDING (root-caused as far as reconstructible): the
  committed crash pin ("panics under exhaustive --batch,
  CerbMem.offsetsof: unknown tag") does NOT reproduce on fresh
  binaries. Bisection: cabs JSON byte-identical pre/post item-c
  (checked at the exact commits); a Lean binary rebuilt with the
  PRE-item-b CerbFS also answers `Specified(0)`; native/*.o rebuilt
  (`make lean-native-obj`) + relink — still `Specified(0)`. Neither
  this slice's changes nor the native-obj layer explains it; the
  recorded crash is attributable only to the recording-era binaries,
  whose provenance cannot be reconstructed — i.e. exactly the
  stale/foreign-binary class item (a) now gates. Its pair
  `offsetof-union-member.c` remains SKIP_LEAN_CRASH (verbatim:
  `PANIC at CerbMem.sizeofCtype_lemFuel CerbMem:415:15:
  CerbMem.sizeofCtype: Union tag not a UnionDef`). The immaculate
  lane (which pins nested-struct under `--first` at `Specified(0)`)
  is green at its committed baseline.
- Baseline deliberately NOT regenerated [AGENT]: the check is rc 0 as
  committed, the movement stays visible on every run, and
  re-recording is an operator decision at merge.

## 6. Close-out battery

Run at the final HEAD with freshly rebuilt+stamped binaries (native
objs re-derived via `make lean-native-obj` during the §5 bisection).
One sequential pass, fail-fast, per-step logs kept for the slice:

- **Tier A (13/13 PASS)**: test_unit (all gates incl. the new
  lem-sync-lean and the item-a stamps' recording path), exec
  minimal/coverage/debug/float baselines, bytes (extended NEG leg:
  `SUMMARY: exec_match=9 neg_pinned=5 fail=0`), libc_exec, multi_tu,
  parse, core, elab, libxml2_uri, cn_coverage
  (`BASELINE OK (213 entries, exact match)`).
- **Tier B extras (12/12 PASS)**: libxml2 full battery (4 slices,
  MATCH), parse tests/ci, core tests/ci, verify, immaculate (verbatim
  closing line: `OK: lane matches the committed post-S1 baseline …`),
  speclab `--selftest` + `--plant`, speclab divmod/bytearr/list/tree/
  seed `--gate`.
- **gcc lane (PASS, second consecutive full run)**: rc 0,
  `gcc second-oracle lane OK`; SUMMARY line-identical to the §5 run
  (verbatim):

      SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9

  (two consecutive identical full summaries — the lane's determinism
  bar, now at the post-basket numbers).
- **csmith corpus full pass (6 sequential shards, all PASS at the
  committed baseline, shard-aware fail-closed check)**. Per-shard
  SUMMARY lines (verbatim):

      SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=1 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0
      SUMMARY: total=279 match=159 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=3 cerb_skip=117 cerb_floor=0 cerb_inconsistent=0
      SUMMARY: total=279 match=144 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=2 cerb_skip=133 cerb_floor=0 cerb_inconsistent=0
      SUMMARY: total=279 match=234 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=45 cerb_floor=0 cerb_inconsistent=0
      SUMMARY: total=279 match=268 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=1 lean_error=0 timeout=0 cerb_skip=10 cerb_floor=0 cerb_inconsistent=0
      SUMMARY: total=274 match=228 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=1 lean_error=0 timeout=2 cerb_skip=43 cerb_floor=0 cerb_inconsistent=0

  *Derived:* 1,669 files total, 1,160 MATCH, mismatch=0, ub_diff=0,
  cerb_floor=0, cerb_inconsistent=0 across all shards; the 2 crash
  rows and all skip/timeout rows are at their baseline classes (each
  shard's fail-closed check passed). Operational note: the shard
  campaign was externally interrupted twice mid-run (background-task
  kills at ~53-55 min wall each; box memory verified healthy at
  114 G available — NOT an OOM); resumed at the shard checkpoint
  each time (shards 2 and 3 rerun from their starts), then run one
  shard per task. No result in this record comes from a partial
  shard.

Tier A was additionally run green in full at the item-(b) and
item-(c) commit boundaries (13/13 each; the (c) first attempt tripped
the bytes NEG pin exactly as designed — §3).

### Advance justification: csmith full pass (written before launch)

The csmith corpus full pass (~2.7 h total) runs SHARDED
(`--shard K/6`, six sequential ~27-min legs, checkpoint between legs
— no single opaque >1 h wait), per the grind-tripwire rule's
measurement-sweep allowance: it is a differential-corpus measurement
demanded by LADDER close-out ("Tier C artifacts current"), not a
proof/build grind. Expected zero movement ((b) touches only fs-op
paths csmith programs never take; (c) is JSON-byte-identical on
succeeding files and the lane's `CERB_SKIP` classes derive from
oracle exec, not cabs-json); any movement is a finding.

## 7. Audit response addendum (2026-08-31)

Pre-merge audit verdict: **MERGE-SAFE-WITH-NOTES**; one moderate
finding (F1) required this audit-response pass before the merge ask.
Ruling provenance: [AGENT] orchestrator ruling (fail-closed doctrine;
operator can override at the merge gate).

### F1 (MODERATE) — flag-blind fs_open left a silent wrong-answer path

Auditor's finding: `fs_open` ignored open flags, so truncate-on-reopen
(write → close → `fopen("w")` on the existing file → close → reopen
"r" → read) served STALE contents with no refused op on the path —
exactly the class item (b) claimed closed — and the item-(b) header's
"serves ONLY the patterns it can answer CORRECTLY" was false as an
absolute. Reproduced pre-fix with the auditor's probe (now committed
as `tests/parity-probes/probes/fopen_trunc_reopen.c`), verbatim:

    === ORACLE (exit 0) ===
    Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}
    === LEAN (exit 0) ===
    Defined {value: "Specified(97)", stdout: "", stderr: "", blocked: "false"}

Fix, both ruled halves:

1. **Refusal widened**: `fs_open` is now flag-aware enough to refuse
   opening an ALREADY-EXISTING file with write or truncate intent
   (O_WRONLY=0o4 / O_RDWR=0o10 / O_TRUNC=0o400; encoding is SibylFS
   `fs_spec.lem`'s, mirrored by
   `runtime/libc/include/posix/fcntl.h:27-45`, cited in-code with the
   deliberate-divergence note — SibylFS models open flags faithfully).
   Read-only reopen of an existing file stays served
   (content-correct). O_APPEND reopen is refused, not served. The
   M-priced real-implementation mover stays registered.
2. **Overstatement fixed**: the CerbFS.lean header now states the
   exact served / refused / KNOWN-DIVERGENT-AND-STILL-SERVED
   partition (the named residuals: missing-file open without O_CREAT
   mis-creates instead of ENOENT; O_EXCL ignored; zeroed stat
   fields), and §2 of this record carries the precision correction.

Post-fix probe evidence (verbatim):

    ##### fopen_trunc_reopen.c
    === ORACLE (exit 0) ===
    Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}
    === LEAN (exit 134) ===
    PANIC at CerbFS.fs_open CerbFS:166:6: CerbFS refusal (fail-closed fs-model boundary): open of existing 2-byte file 't.txt' with write/truncate intent (oflag 292) — the minimal fs model cannot track the resulting content state (O_TRUNC/write modes ignored); serving this fd would answer with WRONG data (CerbFS.lean header; mover: real open-flag semantics)

Re-verified unchanged (verbatim one-liners): the auditor's
seek-then-write shape refuses at the write
(`PANIC at CerbFS.fs_write CerbFS:200:6: … write on fd 3 at offset 1
of 4-byte file 's.txt' …`); `fgetc_eof.c` `AGREE VAL:Specified(2)`;
`fseek_read.c` / `fread_seq.c` refuse at `CerbFS.fs_read` as recorded;
`tests/tcc/40_stdio.c` terminates immediately with the read refusal
(exit 134).

### Re-run battery (fresh stamped binaries)

Tier A in full (13/13 PASS, bytes included: `SUMMARY: exec_match=9
neg_pinned=5 fail=0`) + immaculate (PASS at committed baseline) + gcc
lane `--check-baseline` PASS rc 0, SUMMARY (verbatim, unchanged from
§6 — the ruling's expected line):

    SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9

(`Baseline check: 0 regression(s), 1 improvement(s)` — the §5
offsetof improvement line reappears every run by design, un-regenerated.)

### Other audit notes (recorded, no action this pass)

- **F2**: the refusal's fail-closure is conditional on
  `LEAN_ABORT_ON_PANIC=1` (a bare `panic!` prints and continues with
  the Inhabited default). All harness paths set it
  (`common.sh run_cerberus_lean`); documented, no action.
- **F3**: served-subset positive coverage is thin (zero corpus files
  exercise file ops — which is also why the lanes could not catch
  F1). Registered as an S-priced candidate: a small served-pattern
  probe family (create-write-close-reopen-read, full-read-then-EOF,
  rewind-reread, read-only reopen) under `tests/parity-probes/`.
- **F5**: worker-era `.tmp/scripts/` csmith staging residue (167M
  measured at deletion, 8 staging dirs + smoke files) deleted —
  ephemeral discipline at slice end.
- The item-(e) 4-row baseline-regeneration diff remains enumerated
  and UN-applied, awaiting operator sanction at the merge gate.

## 8. Provenance

- [USER via brief] the basket itself, item order, the S-not-M scoping
  of (b), the no-tray ruling on (c).
- [AGENT] stamp placement at repo root + content-addressed comparison
  semantics (item a); the correct-subset-else-panic design and the
  panic!-not-errno refusal channel (item b); the test_bytes NEG-leg
  extension per the lane's own in-header instruction (item c); the
  build_cerberus follow-up fix (item d); extending set -f to the two
  sibling parsers (item e); all pricing/derived tallies, labeled.
- Run logs for this slice lived under `.tmp/tb/` (ephemeral,
  container discipline); everything load-bearing is quoted verbatim
  above or committed.

## 9. Closing note (2026-09-02, release-hygiene G7)

The §5 disposition ("baseline deliberately NOT regenerated [AGENT] …
re-recording is an operator decision at merge") and the §7 line ("the
item-(e) 4-row baseline-regeneration diff remains enumerated and
UN-applied, awaiting operator sanction at the merge gate") are CLOSED:
the regeneration was sanctioned [USER 2026-08-31] ("baseline regen
approved") and APPLIED on mainline as `df63018e3` ("gcc lane:
sanctioned baseline regeneration — the four adjudicated rows";
`scripts/gcc_oracle_baseline.txt`, 4 insertions / 4 deletions — the
exact enumerated set: 3× SKIP_ORACLE reclassified by the `--cabs-json`
parse-only fix, `offsetof-nested-struct` SKIP_LEAN_CRASH → AGREE; the
`offsetof-union-member` pair still crashes as pinned). The lane has
since been ruled a Tier B GATE [USER 2026-09-02] (`scripts/LADDER.md`
Tier B row 7). Note appended by the release-hygiene worker [AGENT];
the body above is unchanged.
