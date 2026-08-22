# Diagnosis: post-merge libc-mode certification failure — the oracle never loaded the fresh libc.co, because nothing staged it

**Worker record, 2026-08-22.** Investigation on the PRIMARY checkout
(mainline @ `2069d492e`, post arc-13-hotfix merge). No tracked files
modified; this note is the only file written (untracked; the fix branch
commits it). Diagnostic scratch lived under `_build/` and was removed,
EXCEPT one deliberate build-state repair (see §5: `dune build
cerberus.install` was run in the primary as the confirming experiment and
its staging output was left in place — both failing lanes are green on
the primary as of this note).

## 0. Verdict in three sentences

The oracle's libc mode resolves `libc.co` from the **install-staging tree**
(`--runtime` prefix + `lib/cerberus/runtime/libc/libc.co` — the `cerberus`
PACKAGE's staging, not `cerberus-lib`'s), and this morning's cache-disabled
certification rebuild recreated `_build` staging **only for `cerberus-lib`**
(the documented recipe: `dune build backend/driver/main.exe
cerberus-lib.install`), so the path the exec lanes load did not exist and
every libc-mode oracle invocation died at startup with
`Failure("file libc.co not found")` (exit 125 — the uri lane's
"timeout/crash (exit 125)" verbatim). The freshly rebuilt `.co` itself is
**correct**: `libc_prep.sh --check` verifies the *build-tree* copy
(`_build/default/runtime/libc/libc.co`) — a *different path* from what the
lanes load — and once the `cerberus` package is staged (`dune build
cerberus.install`, which creates the missing directory as symlinks into the
build tree), `test_libc_exec.sh` is 7/7 MATCH and `test_libxml2_uri.sh` is
GATE PASS 16/16 with zero other changes. The hotfix worktree's greens were
**real, not a stale-install illusion**: worktree priming copies the
primary's `_build` including the staging tree, whose `libc.co` entry is a
*relative symlink* into the worktree's own `_build/default`, so its lanes
loaded exactly the `.co` its validation had freshly rebuilt — a present
staging entry can never serve stale content; the only failure mode is a
**missing** entry, which is what the primary's post-merge wipe produced.

## 1. The real errors (investigation item 1)

Direct run of the 006 oracle invocation (the exact flags from
`test_libc_exec.sh`), verbatim:

```
$ opam exec --switch=. -- _build/default/backend/driver/main.exe \
      --runtime=_build/install/default --exec --batch tests/libc_exec/006-strlen-snprintf.c
cerberus: internal error, uncaught exception:
          Failure("file libc.co not found")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Dune__exe__Main.core_libraries.(fun) in file "backend/driver/main.ml", line 76, characters 16-62
          ...
EXIT=125
```

So the diverging side is the **ORACLE**, and it diverges by *not running at
all*: stdout is empty, the harness's `head -1` gives an empty `ocaml_line`,
and every fixture records DIFF (the `-n "$ocaml_line"` guard forces DIFF
even where the Lean line alone would look plausible). The Lean side is
healthy — in the failing run its lines were the exact baseline values
(`Specified(42)`, `Specified(18)`, `Specified(16)`, ...).

Observed full-lane state at diagnosis time (derived tally, my re-run):
`test_libc_exec.sh` → `SUMMARY: match=0 diff=7`, all seven `O:` lines
empty. The tasking's symptom quote (`+006 ... DIFF`, `+007 ... DIFF`) is
consistent with this state — the baseline-drift diff in the missing-`.co`
state literally contains those `+` lines (among all seven); a
5-MATCH/2-DIFF state was **not reproducible in any state I could
reconstruct** (see §4: every loadable-`.co` configuration, fresh OR stale,
gives 7/7 MATCH; the missing-`.co` configuration gives 0/7).

The uri lane's `FAIL: ORACLE_LIBC timeout/crash (exit 125)` is the same
event: `run_capped` propagates cerberus's internal-error exit code 125,
and the script's `[[ $rc -lt 124 ]]` guard misreads 125 as
timeout-adjacent. It is neither a timeout nor a crash mid-execution — it
is the startup failwith above. (Secondary finding: cerberus uses exit 125
for internal errors, which collides with the `timeout`-tool convention the
guard assumes.)

### The load-path trace (investigation item 3, first half)

`backend/driver/main.ml:55-77` (`core_libraries`): the libc search path is
`Cerb_runtime.in_runtime ~pkg:"cerberus" "libc"` and the file it demands is
`libc.co` (or `libc_inner_arg_temps.co` under `SW_inner_arg_temps`).
`util/cerb_runtime.ml:41-48`: with `--runtime=PREFIX` (`SPECIFIED`), the
pkg runtime is `PREFIX/lib/<pkg>/runtime` and sourceroot detection is
DISABLED. Hence the lanes load exactly:

```
_build/install/default/lib/cerberus/runtime/libc/libc.co
```

That path is created only by the **`cerberus`** (and `cerberus-bmc`)
install stanzas — `runtime/libc/dune:159-173`:
`(libc.co as runtime/libc/libc.co) (section lib) (package cerberus)`.
The `cerberus-lib` package installs the libc *headers* only
(`lib/cerberus-lib/runtime/libc/include/…`), never the `.co`.

State found on the primary: the whole `_build` was recreated this morning
(everything in `_build/default` mtime 09:15-09:16; `_build/install`
created 09:16 containing **only** `lib/cerberus-lib` and `lib/stublibs`).
`_build/default` contains only `cerberus-lib.install`; neither
`_build/install/default/lib/cerberus` nor `_opam/lib/cerberus` exists.
`_build/default/runtime/libc/libc.co` (mtime 09:15:34, the cache-disabled
fresh rebuild, header `ocaml:5.4.0+cerb:git-cn-pin-315-g2069d492e+mem:concrete`)
is exactly the artifact `libc_prep.sh` verifies — and exactly the artifact
the lanes could not see.

Why the lanes were ever green on the primary: some earlier full
`dune build` (pre-arc-13 era) had staged `lib/cerberus`, and dune stages
the `.co` as a **relative symlink** into `_build/default` (46-byte link
`../../../../../../default/runtime/libc/libc.co` — verified in the
surviving 08-18-primed worktrees), so staging, once present, always serves
the *current* build-tree `.co`. The wipe destroyed the symlink; nothing in
the documented rebuild/reinstall recipe (`dune build
backend/driver/main.exe cerberus-lib.install && dune install cerberus-lib`)
recreates it.

## 2. The .co-content hypothesis (investigation item 2) — REFUTED

What the marshalled `.co` actually contains — `backend/common/pipeline.ml`
`core_dump` (:629-638) and `write_core_object` (:682-700): a version text
line + `Marshal` of `{dump_main; dump_calling_convention; dump_tagDefs;
dump_globs; dump_funs; dump_extern; dump_funinfo}`. **There is no
fresh-counter snapshot, no symbol-supply state, no digest table.** Loading
(`read_core_object`, :656-680) rebuilds the maps and touches no ambient
counter — `Cerb_fresh` is never read or written on the load path, so the
F-D-class question ("does loading reinitialize the counter?") is answered
NO by construction. The version line is compared and produces a WARNING
only (`:660-663`), never a failure — a stale `.co` loads.

The `.co` does embed exec-relevant state *beyond the pp dump* — the pp
omits extern map, funinfo, `main`, and non-main-file tagDefs (the known
`show_include=false` limitation, documented in `libc_prep.sh`) — so
"dump-hash-verified" is genuinely weaker than ".co-verified". But
empirically that gap is NOT the failure here: I ran the oracle (fresh
binary, `2069d492e`) against the **pre-arc-13** `.co` (header
`ocaml:5.4.0+cerb:git-24c3314c0+mem:concrete`, taken from the 08-18-primed
spike worktree, old numbering — note `tests/libc/libc.core` WAS re-pinned
at arc-13 `0ca08d695`, so old and fresh `.co` differ in content) via a
dereferenced scratch runtime, and 001/005/006/007 all produced the exact
baseline lines (`Specified(42)/(15)/(18)/(16)`, exit 0). No
stale-content divergence exists on this corpus; numbering is internally
consistent per `.co` and linking is by identifier/digest.

## 3. Was the hotfix worktree's green real? (investigation item 3, second half) — REAL

`scripts/new-worktree.sh` primes a worktree by `cp -a` of the primary's
entire `_build` — *including* `_build/install/default/lib/cerberus` as it
existed at priming time, with `libc.co` as a **relative symlink** that
resolves inside the worktree's own `_build/default` (verified on both
surviving worktrees: link target
`../../../../../../default/runtime/libc/libc.co`). The hotfix worktree's
validation sequence (its record, §Validation) rebuilt
`runtime/libc/libc.co` cache-disabled — i.e. rewrote the symlink's
TARGET — then ran the lanes. Its ORACLE_LIBC therefore loaded exactly the
freshly rebuilt `.co`. The greens were honest measurements of the fresh
artifact; nothing stale was served.

What the worktree could not and did not certify is the **primary's**
post-merge state: the primary's staging tree was destroyed by the
certification wipe, and the record's operator follow-up ("the primary
needs one `make clean-prelude-src prelude-src`") was incomplete — the
primary also needed the `cerberus` package staged. The illusion, such as
it was, is in the *transfer* of the green (worktree ⇒ primary), not in the
worktree's own run.

## 4. Upstream cross-check (investigation item 4) — superseded

The planned upstream disambiguation ("does upstream-fresh also fail?") was
designed to separate a `.co`-path defect from a build-sequence issue. That
separation was obtained directly and more strongly on the fork itself:
the fork's fresh `.co`, once actually loadable, passes both lanes 7/7 and
16/16 (§5), and even the stale pre-arc-13 `.co` executes the corpus
correctly (§2). The failure is a build/staging-sequence issue with no
`.co`-content component; a fresh upstream build would add nothing to that
conclusion (and the hotfix record already established fork-dump ==
upstream-dump byte-identity on a true rebuild). Not run.

## 5. The confirming experiment (and current primary state)

On the primary, single change: `dune build cerberus.install` (staging
only — populates `_build/install/default/lib/cerberus/runtime/libc/` with
the three `.co` symlinks; no opam install involved; `check_lem_sync: OK`
in its log). Then, unmodified harnesses:

- `./scripts/test_libc_exec.sh` → `SUMMARY: match=7 diff=0` /
  `ALL MATCH RECORDED BASELINE` (rc=0)
- `./scripts/test_libxml2_uri.sh` →
  `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` /
  `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` (rc=0)

The staging output was left in place, so the primary's lanes are green as
of this note. (This is `_build` state, not a tracked-file change; a
re-wipe would reintroduce the failure until the fix below lands.)

## 6. Fix design (goes to a branch off `2069d492e`)

The defect class is a **trust gap between the verified artifact and the
loaded artifact**: `libc_prep.sh` pins/verifies
`_build/default/runtime/libc/libc.co`, the lanes load
`_build/install/default/lib/cerberus/runtime/libc/libc.co`, and nothing
asserted the second path exists or agrees with the first. Fail-closed at
least (the oracle dies loudly rather than running something stale), but
the failure surfaced as two misleading lane verdicts.

Proposed, minimal and mechanism-scoped:

1. **`scripts/common.sh` `build_cerberus`**: add
   `dune build cerberus.install` next to the existing
   `dune build backend/driver/main.exe` + `dune install cerberus-lib`.
   Every libc-mode lane sources `common.sh`, so the staging tree the
   oracle needs is (re)created before any lane runs, and it is symlinks —
   permanently in sync with the build tree by construction.
2. **`scripts/libc_prep.sh`**: close the trust gap explicitly — after the
   existing content-hash check of `$LIBC_CO`, verify the *lane-loaded
   path* `_build/install/default/lib/cerberus/runtime/libc/libc.co`
   exists and resolves/content-hashes to the same bytes as `$LIBC_CO`;
   die with remediation `dune build cerberus.install` otherwise. Then
   `--check` finally certifies the artifact the lanes load, not a sibling
   path. (Both failing lanes call `libc_prep.sh` before the oracle runs,
   so this alone would also have converted both symptoms into one honest
   error message.)
3. **`test_libxml2_uri.sh` cosmetic honesty**: the `[[ $rc -lt 124 ]]`
   guard labels cerberus's internal-error exit 125 as "timeout/crash";
   either widen the message ("timeout/crash/internal-error") or check
   stderr. Small, optional.
4. **Docs**: project CLAUDE.md / cerberus-lean build recipe gains the
   `cerberus.install` staging step (the current recipe stages
   `cerberus-lib` only and is exactly how this state arose).

Rejected alternatives: copying `.co` files into staging by hand (drifts);
pointing the lanes at `_build/default` directly (fights `cerb_runtime`'s
layout and diverges from how users run the oracle).

## 7. Honest trust scope

- **`tests/libc/libc.core` pin: trustworthy.** The pin (and its sha256
  companion) verifies the build-tree `.co`'s pp content; the fresh `.co`
  behind it passes both differential lanes end-to-end (§5), and the
  hotfix record separately established byte-identity of the dump against
  upstream's own `.co` on a true rebuild. The pin was never wrong at any
  point in this incident.
- **The 16/16 uri pins: trustworthy.** Re-verified green on the primary
  with the fresh `.co` actually loaded (§5); the worktree's 16/16 was also
  a genuine fresh-`.co` measurement (§3).
- **Affected surface**: every harness whose oracle runs `--exec` WITHOUT
  `--nolibc` against `--runtime=_build/install/default` —
  `test_libc_exec.sh`, `test_libxml2_uri.sh`, `test_libxml2.sh` (Tier B
  chvalid; not re-run here, same mechanism, expected green after staging),
  and any ad-hoc `run_cerberus` libc-mode use. NOT affected: all
  `--nolibc` lanes (`test_exec.sh`, coverage, debug, test_core — their
  green baselines never involved the staging tree), the Lean side
  (loads the pinned dump, never the `.co`), and `libc_prep.sh`'s regen
  (its input is the build-tree `.co` by explicit path).
- **Residual (pre-existing, unchanged)**: the pp dump structurally omits
  extern/funinfo/main/included tagDefs, so dump-hash identity remains
  weaker than `.co` identity. Today's incident gives no evidence of a
  live gap there (§2's stale-`.co` probe ran clean), but fix item 2's
  loaded-path == verified-path assertion is deliberately on `.co` bytes,
  not dump bytes, which retires the distinction for the lanes.
- **Unreproduced detail**: the symptom report's implied 5-MATCH/2-DIFF
  pattern. Every reconstructable configuration yields 7/7 (loadable `.co`,
  fresh or stale) or 0/7 (missing `.co`); the quoted `+006`/`+007` drift
  lines exist verbatim in the 0/7 state's drift diff, which I take to be
  their source. If an actual 5/2 run output surfaces, it should be
  re-examined against this diagnosis.

## 8. Fix implementation record (HOTFIX-2 worker, 2026-08-22, branch `arc/hotfix-libc-staging` off `2069d492e`)

§6's design implemented, plus two adjacent gaps found during plant
testing. Changed files: `scripts/common.sh`, `scripts/libc_prep.sh`,
`scripts/test_libxml2_uri.sh`, `lean_frontend/CLAUDE.md`, this note
(committed as the record).

1. **`common.sh` `build_cerberus`** now runs
   `dune build backend/driver/main.exe cerberus-lib.install` +
   `dune install cerberus-lib` (loud-fail, see finding B) +
   `dune build cerberus.install`, then asserts the staged
   `lib/cerberus/runtime/libc/libc.co` exists (fail-closed).
2. **`libc_prep.sh`** (--check and --jsons): after the content-hash pin
   check, asserts the lane-loaded path
   `_build/install/default/lib/cerberus/runtime/libc/libc.co` exists AND
   byte-matches (`cmp`) the build-tree `$LIBC_CO`; refuses with
   remediation `dune build cerberus.install` (missing) or
   `dune clean` + full recipe (mismatch — see finding A).
3. **`test_libxml2_uri.sh`**: `rc_label` helper distinguishes 124
   (timeout) / 125 (cerberus internal error — the incident's actual
   class, previously mislabeled "timeout/crash") / 137 (SIGKILL) /
   other, in all four lane guards, with stderr tail included.
4. **`lean_frontend/CLAUDE.md` Build**: recipe now includes
   `cerberus-lib.install` in the dune build line and the
   `dune build cerberus.install` staging step, with the load-path
   rationale and the tamper caveat.

### Finding A (plant-tested): dune trusts its incremental db over the filesystem

In a settled tree, manual deletion/alteration of ANYTHING under
`_build` — including regular `_build/default` targets, not just install
staging — is NOT repaired by any incremental `dune build` invocation
tried (`cerberus.install`, `@install`, `--force cerberus.install`,
explicit staged-path target; dune 3.23.1). `_build` is dune's private
area; only `dune clean` + rebuild recovers a tampered tree. The §6.2
remediation `dune build cerberus.install` is therefore correct exactly
for the INCIDENT class (fresh `_build` whose db never ran the staging
rules — verified below) and cannot repair the tamper class; both
refusal messages say so explicitly.

### Finding B: `dune install cerberus-lib` does not build `cerberus-lib.install`

Post-`dune clean`, `dune install cerberus-lib` fails
(`Error: The following <package>.install are missing:
- _build/default/cerberus-lib.install`) — and `build_cerberus`'s old
`2>/dev/null` swallowed it, and the old `lean_frontend/CLAUDE.md` recipe
(`dune build backend/driver/main.exe` only) hit it too. Building
`cerberus-lib.install` explicitly is also what stages
`_build/install/default/lib/cerberus-lib` (std.core etc.), which every
`--runtime=_build/install/default` invocation (including this script's
own dump regen) needs. Fixed in both places; the install is now
loud-fail.

### Plant tests (all verbatim)

**P1a — incident replay.** `dune clean`; old recipe
(`dune build backend/driver/main.exe cerberus-lib.install`,
`dune install cerberus-lib`, `dune build runtime/libc/libc.co`);
then `./scripts/libc_prep.sh --check`:

```
libc_prep: ERROR: lane-loaded staging path missing: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/hotfix-libc-staging/_build/install/default/lib/cerberus/runtime/libc/libc.co
  The libc-mode oracle loads libc.co from the cerberus package's
  install staging, which is NOT created by the cerberus-lib-only
  build recipe. Refusing to proceed.
  Remediation: (cd /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/hotfix-libc-staging && opam exec --switch=. -- dune build cerberus.install)
  (If the path is still missing afterwards, _build was manually
  altered — dune trusts its incremental db over the filesystem and
  will not re-stage; run dune clean and rebuild per the documented
  recipe, lean_frontend/CLAUDE.md Build.)
RC=1
```

**P1b — the remediation command, verbatim, then re-check:**
`dune build cerberus.install` recreated the three `.co` symlinks;
`--check` then printed:

```
libc_prep: OK (content hash verified: pin + regenerated dump == bb0560d94f6383cb8057b8c810f6253ff6cd451c10b29a9e0fcd105c3de62197, 4188542 bytes)
libc_prep: OK (lane-loaded staging verified: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/hotfix-libc-staging/_build/install/default/lib/cerberus/runtime/libc/libc.co byte-matches build-tree libc.co)
libc_prep: libc.co version (informational): ocaml:5.4.0+cerb:git-cn-pin-315-g2069d492e-dirty+mem:concrete
RC=0
```

**P2 — mismatched staging.** Replaced the staged symlink with a
scratch copy of the `.co` + 10 appended bytes:

```
libc_prep: ERROR: lane-loaded staging libc.co does not byte-match the verified build-tree libc.co.
  staged (lane-loaded): /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/hotfix-libc-staging/_build/install/default/lib/cerberus/runtime/libc/libc.co (1cbd149d99e8eb85c6b959d8e58040a2245ad464d3e26dc429868baa0c936ee9)
  build tree (verified): /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/hotfix-libc-staging/_build/default/runtime/libc/libc.co (3eca54ed9aad8b9498b389fee0e9c2e0c2fae82f92ac0b39b270a5311750845c)
  The lanes would load an artifact other than the one this check
  verified. Refusing to proceed.
  A mismatch here means _build/install was manually altered (dune
  stages this entry as a symlink into _build/default, which cannot
  go stale) — and dune trusts its incremental db over the
  filesystem, so 'dune build cerberus.install' will NOT repair it.
  Remediation: (cd /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/hotfix-libc-staging && opam exec --switch=. -- dune clean)
  then rebuild per the documented recipe (lean_frontend/CLAUDE.md
  Build), which ends with: dune build cerberus.install
RC=1
```

### Validation at head (from `dune clean`, documented full recipe, worktree)

Recipe run: `dune clean` → `dune build backend/driver/main.exe
cerberus-lib.install` → `dune install cerberus-lib` →
`dune build cerberus.install` → all steps rc=0, then:

- `libc_prep.sh --check` → both OK lines above (content hash + lane-loaded
  staging), rc=0.
- `test_libc_exec.sh` → `SUMMARY: match=7 diff=0` /
  `ALL MATCH RECORDED BASELINE`, rc=0.
- `test_libxml2_uri.sh` →
  `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` /
  `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)`,
  rc=0.
- `test_unit.sh` → `Total: 7 passed, 0 failed`; all gates OK incl.
  `check_lem_sync: OK`, `check_exec_purity: CLEAN (11 modules)`,
  `check_exec_totality: CLEAN`, theorem-axiom cones OK,
  `check_fork_drift: OK`, `check_proof_size: OK`; rc=0.
- `test_exec.sh` (exec-minimal) → `SUMMARY: total=106 match=85
  ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0
  cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` — zero movement, rc=0.

(The `-dirty` in the informational version line reflects this branch's
uncommitted script/doc edits at validation time; the pin is a content
hash and is version-line-independent by design.)
