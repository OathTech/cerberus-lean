# WP-O record — the pristine-oracle instrument (2026-09-16)

**Status:** RECORD of the chartered slice
[`2026-09-16_charter-pristine-oracle-instrument.md`](2026-09-16_charter-pristine-oracle-instrument.md),
executed by one Claude Fable subagent worker on branch `arc/pristine-oracle-instrument`
(worktree `worktrees/cerberus-lean-arc/pristine-oracle-instrument`, base mainline `0c78635cb`,
charter commit `1770e112d`). Four deliverable commits + this record; the orchestrator
re-verifies every gate independently (worker-claimed green is never accepted). Evidence:
[`2026-09-16_pristine-oracle-instrument-record-evidence/`](2026-09-16_pristine-oracle-instrument-record-evidence/)
(every quoted verdict line is in a file there; paths below are relative to it). Nothing here
was pushed; nothing was merged; no mainline was touched.

## 0. Rulings (by pointer) and the reading applied

- [USER 2026-09-16] ("… we're also changing it. There's some danger there!" / "add improving
  the upstream oracle as a thing to do before we execute on further work" / "execute on WP-O as
  proposed"), [USER 2026-09-11] (Fable subagents), [USER 2026-09-08] (nothing new out of policy —
  this slice adds NO semantics and NO proofs; it is an instrument), [USER 2026-09-03] (the four
  aims; the zero-execution-discrepancy rule): charter §0 verbatim. Standing constraints (no
  machine-global state, no push, no mainline commits, fail-closed/fail-noisy, provenance, capped
  Lean, one heavy job, the grind tripwire): charter §0, applied throughout.
- Every decision below is [AGENT] unless quoted as [USER]. Reading conflicts are raised in §7.

## 1. Commits (all on `arc/pristine-oracle-instrument`; one per deliverable; green only)

| commit | deliverable | files |
|---|---|---|
| `0ce67f2b6` | O3 — `scripts/ensure_independent_oracle.py`, the standing build | + evidence `o3-*` |
| `3debab120` | O1 — corpus widening, register schema 2, plants | `scripts/test_upstream_oracle.py`, `scripts/upstream_oracle_differences.json`, evidence `o1-*` |
| `57a0e4ee0` | O2 — `--with-lean` three-engine column; LADDER Tier C row C5 | `scripts/test_upstream_oracle.py`, `scripts/LADDER.md`, evidence `o2-*` |
| `664f9d0a7` | O4 — doctrine: VALIDATION §0/§3/§4/§5/§8, LADDER row 10/6b/12/C6/C7 | `lean_frontend/VALIDATION.md`, `scripts/LADDER.md`, evidence `o4-*` |
| `419c572a1` | the record + evidence dir (first version) | this file, `…-record-evidence/` |
| `9cbd9b86f` | **O5** — the two [USER 2026-09-17] rulings: `matching_incomplete`, backtrace-position normalisation; register = 3 tray rows | `scripts/test_upstream_oracle.py`, the register, `VALIDATION.md`, `LADDER.md`, `tests/multi_tu_tray/README.md`, evidence `o5-*` |
| (this) | the record amendment (§1, §3.3, §7) | this file |

Fence check: only fenced files were edited (`test_upstream_oracle.py`, the register, the new
ensure-script, `LADDER.md`, `VALIDATION.md`, the record + evidence, the container hook).
`build_independent_oracle.py`, `release.py`, `test_observation_lanes.py`, `README.md` were NOT
edited (reasons in §7). No `.lem`/`.ml`/`.lean`/Makefile/lakefile/dune file, no other lane's
baseline or register, no pin moved.

## 2. O3 — the standing pristine build (`0ce67f2b6`)

**Built:** `scripts/ensure_independent_oracle.py` — one entry point. (a) validates the manifest at
the lane's default path (`.validation-foundations/independent-oracle-v2/manifest.json`, or the
parent of `CERB_INDEPENDENT_MANIFEST`) by IMPORTING `test_upstream_oracle.validate_build` — no
second validator; (b) if the directory is ABSENT, runs `build_independent_oracle.py --lem-repo …
--cerberus-repo … --out <new dir>`, discovering the lem checkout (`CERB_LEM_REPO`, else the first
container sibling `lem-lean` / `deps/lem-pinned` whose object store holds `LEM_REV`) and defaulting
`--cerberus-repo` to the checkout itself (which holds `CERBERUS_REV`; `git cat-file -e <rev>^{commit}`
is the test), with a `SystemExit` naming every candidate tried otherwise; (c) if PRESENT but the
manifest is missing or invalid, REFUSES with the validator's reason and names the directory for the
operator — it never deletes or overwrites. `--no-build` = validate only. The lane and `release.py`
keep their PREREQUISITE stance (unchanged; negative control rerun before the build: `INDEPENDENT
ORACLE INCOMPLETE: [Errno 2] No such file or directory: …/manifest.json`). `CERBERUS_REV`/`LEM_REV`
untouched; `build_independent_oracle.py` untouched (its argument defaults did not need changing:
the ensure-script supplies them).

**Build (first consumer), verbatim (`o3-ensure-build.txt`; 41.5 s wall, load 0.05):**
```
ensure_independent_oracle: ABSENT — building the pristine oracle into …/.validation-foundations/independent-oracle-v2
  lem-repo:      /home/dev/projects/cerberus-lean-proj/lem-lean
  cerberus-repo: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pristine-oracle-instrument
lem-compiler: passed (6.627s)
lem-libraries: passed (1.166s)
lem-runtime-build: passed (4.193s)
lem-runtime-install: passed (0.146s)
cerberus-generation: passed (17.75s)
cerberus-build: passed (9.378s)
Independent upstream oracle: …/.validation-foundations/independent-oracle-v2/manifest.json
ensure_independent_oracle: BUILT+VALID standing build: …/manifest.json (cerberus b9aeedcb4, lem 3802cb0)
```
**Plants (`o3-ensure-plants.txt`, exit codes re-verified without a pipe):** rerun → `VALID` rc 0 (no
rebuild); garbage manifest / manifest-less directory / doctored-pin manifest / `CERB_INDEPENDENT_
MANIFEST` → garbage: all `REFUSED` rc 1, files left in place; `--no-build` on an absent path →
`ABSENT` rc 1, no directory created; bad `--lem-repo` → rc 1 before any `mkdir`.

**Container-side hook (the container is not a repo; diff verbatim, `o3-new-worktree-hook.diff`):**
```diff
--- .tmp/new-worktree.sh.orig	2026-09-16 21:45:45.322280810 +0000
+++ /home/dev/projects/cerberus-lean-proj/scripts/new-worktree.sh	2026-09-16 21:45:45.335884750 +0000
@@ -83,6 +83,11 @@
       cp -a "$SRC/$d/." "$DST/$d/"
     fi
   done
+  # Standing pristine oracle (WP-O 2026-09-16, charter O3): validate-or-build LADDER Tier B row 10's
+  # prerequisite at the worktree's default path (~1 min); the lane itself never builds. Opt out:
+  # CERB_SKIP_INDEPENDENT_ORACLE=1. Fail-noisy: a refused/failed build (or a branch predating the
+  # script) exits nonzero here AFTER the worktree exists — rerun the ensure-script by hand or opt out.
+  [[ -n "${CERB_SKIP_INDEPENDENT_ORACLE:-}" ]] || "$PROJ/scripts/ce" python3 "$DST/scripts/ensure_independent_oracle.py"
 fi
 
 echo
```
[AGENT] The hook is fail-noisy by design: on a branch that predates the script, `python3` fails
loudly after the worktree exists and the operator either runs the script by hand or opts out; a
silent skip would be the fail-open shape. `bash -n` passes. The hook was NOT exercised end to end
(creating a worktree is outside the fence); the script it calls was.

**FAST-GATE at O3, verbatim (`o3-gate-full.txt`, `o3-gate-plant.txt`; 1:03.26 wall):**
```
Independent oracle: passed; {'semantic_agreement': 738, 'reviewed_difference': 1, 'matching_failure': 11, 'interface_agreement': 2}; …/.tmp/o3-gate/full/report.json
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1}; …/.tmp/o3-gate/plant/report.json
```
(identical to the last recorded verdict, `2026-09-11_semantics-audit-repairs-record.md:1776`).

## 3. O1 — corpus and register (`3debab120`)

### 3.1 The measurement table (charter O1: measure FIRST, then adopt)

`--only` per added corpus against the O3 build, one process at a time, load ≤ 1.1; "pristine s" /
"fork s" are the SUMS of per-case engine wall-clocks from `report.json` (derived), "wall" the run's
own `seconds` (`o1-measure-*.txt`; `o1-measure-table-partial.txt`, `o1-measure-csmith-shard-table.txt`).

| corpus (selection) | cases | pristine s | fork s | wall s | statuses (before register rows) | [AGENT] placement |
|---|---|---|---|---|---|---|
| existing row-10 corpus (O3 gate) | 752 | 26.2 | 25.4 | 63.3 | 738 agree / 1 reviewed / 11 matching_failure / 2 interface | Tier B row 10 (unchanged) |
| `tests/multi_tu_tray` | 7 | 30.3 | 0.2 | 31.7 | 4 agree / 2 difference / 1 incomplete (`node`, pristine 124 at 30 s) | **Tier B row 10** with 3 `shared-model-fix` rows (drafts 37/38/39) |
| `tests/immaculate` (nolibc 34 + argv 3 + libc 30; the 2 in-Lean probes excluded) | 64 | 7.0 | 6.9 | 15.6 | 48 agree / 16 difference (all both-crash, backtrace positions only) | **Tier B row 10** with 16 `diagnostic-text` rows |
| `tests/verify` + `lean_frontend/corpus` main mode | 32 | 0.9 | 0.9 | 3.2 | 32 agree | **Tier B row 10** |
| `tests/ci` (242 after test_exec.sh's exclusions) | 242 | 66.9 | 66.6 | 137.5 | 134 agree / 102 matching_failure / 4 difference (backtrace positions) / 2 incomplete (**both sides** 124 at 30 s: `0023-jump1.c`, `0025-jump3.c`) | **Tier C reporting row C6** (§7 S5) with 4 `diagnostic-text` rows |
| libxml2 `chvalid` (4 slices) | 4 | 204.9 | 200.6 | 406.7 | 4 agree (`failed` only on `source unchanged: False` — my own mid-run edits; the lane's identity check working) | **Tier B row 12** (own row: +6.8 min would make row 10 load-sensitive) |
| csmith shard 1/34 (50 of 1669) | 50 | 319.6 | 319.6 | 641.0 | 26 agree / 3 difference (backtrace positions) / 21 incomplete (**both sides** 124 at 15 s) | **Tier C reporting row C7**, sharded K/34; full corpus ≈ 6.1 h projected — never one step |
| **widened Tier B row 10 (O1 gate)** | **855** | — | — | **112.4** | 822 agree / 20 reviewed / 11 matching_failure / 2 interface | — |

The tripwire was not approached: the longest single step was the 641 s csmith shard; the projection
(≈ 6.1 h) is why csmith is sharded and reporting, as charter O1 anticipated (plan Q7).

### 3.2 What `corpus()` now walks and how (flags mirrored; cites are to the lane scripts at this head)

- Tier A exec corpora — unchanged (test_exec.sh:403-406 exclusions, :442-443 flags; libc_exec with
  libc, test_libc_exec.sh:87).
- `tests/multi_tu` + `tests/multi_tu_tray` — sorted `.c`, `--nolibc --exec --batch --mode=exhaustive`
  (test_multi_tu.sh:139, :149-150), 30 s (:66).
- CN rows, libxml2 `uri` ×2, the 3 CLI rows — unchanged (`cli/args` now duplicates
  `immaculate/argv/argv1-args`; both kept — the CLI row is the legacy-interface representative).
- `tests/immaculate` — `--exec --batch` [+ `--nolibc`] [+ `--args "ab cd"` for argv] with NO `--mode`
  flag (the oracle's default single-trace mode, paired in that lane with Lean `--first`;
  test_immaculate.sh:151-156), 60 s (:63); corpora :191-193/:201-203/:212-214; the in-Lean probes
  `g6-hash-collision.lean`/`illtyped-store.lean` have no oracle side.
- `tests/ci` — recursive, minus `.syntax-only.c`/`.exhaust.c` (test_exec.sh:403-406), test_exec flags,
  30 s (:169); `tests/ci/expected/` holds no `.c`.
- `tests/verify/*.c` main mode (test_verify.sh:75-77, 30 s) and the 7 `lean_frontend/corpus` stems
  test_verify.sh runs main-mode (:269). EXCLUDED, named in the report's `not_applicable`: the
  call-point rows — Lean `--call` (:160-163) and the oracle's rendered wrapper TUs (:57-65), which
  exist only to mirror `--call`, a fork-only interface (as the 2026-09-06 record `:101-102` names it);
  the `--pp=core` pin derivations (:105/:209/:238 — Core text, the tolerated renumbering class,
  VALIDATION §5, not an execution).
- libxml2 `chvalid` — `libxml2_prep.sh chvalid.c` FLAGS + TU (test_libxml2.sh:110-116), 4 sorted
  slices (:136), `--nolibc --exec --batch FLAGS <slice> <chvalid.c>` (:162-163), 300 s (:65). The
  battery-drift check (:121-124) is that lane's own; the committed slices are hashed as inputs here.
- csmith — materialised per test_csmith_corpus.sh:53-68 into `<out>/stage/csmith` (`csmith_cerberus.h`
  + `safe_math.h` beside prefixed `sia_/sa_/smx_` copies with `#include "csmith.h"` →
  `#define CSMITH_MINIMAL` + `#include "csmith_cerberus.h"`), exactly 1669 (checked), test_exec
  flags, 15 s (:51). `--shard K/M` = that lane's arithmetic (:88-95) over the staged names in
  CODEPOINT order. [AGENT] deliberate divergence: the lane's `find | sort` order is locale-dependent
  (measured: under the box's `en_US.UTF-8`, `sort` puts `sa_csmith_100.c` before `sa_csmith_10.c`;
  `LC_ALL=C` agrees with Python), so mirroring it would make shard boundaries non-portable — the
  defect class the 2026-09-05 audit named ("gates were locale-dependent"). Fixing the fork lane is
  outside the fence (§7 open items).
- Selection: `--corpus tier-b` (default; row 10) | `libxml2_chvalid` (row 12) | `ci`, `csmith`
  (C6/C7) | `all`; `--shard K/M`; `--only`. The register's case set is checked against the UNION of
  all corpora (both directions) whatever the selection; the library probe runs only for full
  `tier-b`/`all` runs. Per-case timeouts are the owning lane's; `--timeout` (30) covers cases whose
  lane sets none. Every row prints both engines' wall-clocks.

### 3.3 Register schema 2 (`scripts/upstream_oracle_differences.json`, 24 rows)

Row = `{class, citation, rationale, upstream, fork}` exactly; `class ∈ {diagnostic-text, resource,
missing-feature, shared-model-fix}`; `citation` = a string or list of strings, each an EXISTING
repo-relative file (optional `:lines`/`#anchor`) or an ISO-fix id `R<n>` present in VALIDATION §2's
table (checked at load); `rationale` non-empty; signature = `{status, stdout_sha256,
diagnostic_sha256}`. Load refuses: schema ≠ 2, unknown/missing keys, unknown class, missing/
nonexistent citation, empty rationale, malformed sha, identical signatures (no difference), fork
status 124/137 (never admissible), pristine 137, pristine 124 outside `resource`/`shared-model-fix`.
`compare()`: fork-side incompleteness and any kill → `incomplete`; pristine 124 → `reviewed_difference`
ONLY via an admitting row whose both signatures match, else `incomplete`; a row present but not
matching → `difference` ("pin moved"); a row naming an absent case → the run is INCOMPLETE. Both
stale directions are therefore RED, as the baseline lanes do.

[AGENT] **Signature change (schema 2):** the stderr component is the lane's DIAGNOSTIC projection
(`^Time spent: <decimal> seconds\n` removed — the projection `matching_failure` already used; raw
stderr retained in every capture). Schema 1 bound the RAW stderr sha, which no completing run can
reproduce (the trailer's decimal changes every run) — the 097 row only ever matched because a crash
prints no trailer. Without this no tray row could exist. Nothing new is admitted: the projection is
the one the lane already declared. For 097 the two shas coincide (verified against the O3 run).

**Rows added (raw diffs: `o1-raw-diffs-tray-immaculate.txt`, `o1-raw-diffs-ci.txt`; generator with
its machine checks: `o1-register-generator.py.txt`):**

| case | class | citation | pristine → fork (verbatim verdicts) |
|---|---|---|---|
| `multi_tu_tray/node` | `shared-model-fix` | drafts 37, 38; `tests/multi_tu_tray/README.md`; audit-repairs record `:1752` | pristine rc **124** at 30 s, empty stdout/stderr (draft 37's non-termination) → fork `Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}` rc 0 — THE one admitted pristine-side incomplete |
| `multi_tu_tray/arr-2-2-return` | `shared-model-fix` | drafts 38, 39; README; `:1752` | `Error {msg: "ill-formed program: \`PEmemberof(struct) ==> mismatched tags: Symbol(558, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}` rc 1 → `Defined {value: "Specified(7)", …}` rc 0 |
| `multi_tu_tray/arr-incomplete-ptr-return` | `shared-model-fix` | drafts 38, 39; README; `:1752` | `Error {msg: "… mismatched tags: Symbol(536, SD_Id("S")) vs Symbol(502, SD_Id("S"))'"}` rc 1 → `Defined {value: "Specified(7)", …}` rc 0 |
| `minimal/097-null-ptr-arith.undef.c` (migrated) | `diagnostic-text` | 2026-09-06 record `:85-93`; audit-repairs `:1752`; `d5-pristine-097-diagnostic-diff.txt` | both 125, same `Failure("TODO(pure shift a null pointer …), offset:4")`; frame positions only |
| 16 `immaculate/…` rows: `nolibc/{f3-raw-high-byte-char-const, f3-raw-high-byte-int, f3-raw-high-byte-uchar, g4-bswap64-overflow, g5-decode-multichar, g5-decode-question, offsetof-union-member, zd-e2-ptr-string-literals, zd-z2fl03-nan-to-int, zd-z2m01-aligned-alloc-zero-nolibc, zd-z2m02-device-funptr-call}`, `libc/{g2-memcmp-uninit, s4b-memcmp-hugesize, zd-z2f04-closedir, zd-z2m01-aligned-alloc-zero-zero, zd-z2m01-aligned-alloc-zero}` | `diagnostic-text` | 2026-09-06 record `:85-93`; `tests/immaculate/baseline.txt` (the row's own `MATCH \| L=CRASH` / `ORACLE_CRASH` pin); audit-repairs `:1752` | both 125, empty stdout, identical exception payload (`Z.Overflow`, `Failure("…")`, or the leading `internal error:` line), stderr line counts equal; only `line N`/`lines N-M`/`characters A-B` of `Called from`/`Raised …` frames differ (generated `.ml` shifted by the fork's `.lem` edits; `lem_list.ml` frames from the different Lem runtime; `pipeline.ml`/`main.ml` from the fork's driver additions) — each checked frame by frame by the generator |
| 4 `ci/…` rows: `0120-addition_null_pointer.error.c`, `0121-addition_null_pointer_zero.error.c`, `0258-array-function-type.error.c`, `0270-invalid-compound-literal.error.c` | `diagnostic-text` | 2026-09-06 record `:85-93`; `scripts/exec_ci_baseline.txt` (`CERB_SKIP`); `:1752` | same shape (0120's shas are literally 097's) |

The 4 tray rows that AGREE (`arr-1-2-return`, `fam-vs-array-return` — both `Error … mismatched tags`
with the SAME symbol numbers on both engines; `arr-1-2-arg`, `arr-2-2-arg` — `Specified(7)` on
both) need no row: the tray README's three-engine table is reproduced exactly.

**SUPERSEDED by O5 (§7, [USER 2026-09-17] ruling 2): the 21 `diagnostic-text` rows above (097 + 16 +
4) were DELETED at `9cbd9b86f` — the lane's diagnostic projection now normalises backtrace frame
positions and every one of those pairs reads `matching_failure`; the register is exactly the 3
`shared-model-fix` tray rows. The table stays as the record of what was measured.**

[AGENT] on the 20 diagnostic-text rows — the reading conflict, raised (§7) and now moot: charter O1's parenthetical
lists drafts 37/38/39 as THE example of "an existing citation"; §3 S1 defines the stop as a
difference "no EXISTING citation explains (a new semantics finding)". The backtrace-position class is
explained by the 2026-09-06 record's own table row and remedy ("pin both … with the reviewed
rationale") and by the 2026-09-15 re-pin precedent (`:1752`); none is a semantics finding (same
exception, same exit, empty stdout on both engines, checked mechanically). I wrote the rows so the
immaculate corpus could be ADOPTED green, and flag them for the orchestrator to strike if the
narrower reading is intended. Cost noted honestly: these pins move on every generated-line shift (a
mass re-pin per shared-model slice — 097 already needed one); the right instrument is the deferred
normalisation question of `:1752`, an operator decision because it changes what the lane admits.

### 3.4 Plants (`--plant`, `o1-gate-plant.txt`)

Hermetic (no processes): 16 doctored registers rejected at load — schema 1, missing/unknown class
(`failure-text`, the plan's old name), missing/empty/nonexistent citation, unknown ISO-fix id `R99`,
unknown key, empty rationale, identical signatures, fork 124, fork 137, pristine 137, pristine 124
under `diagnostic-text`, malformed sha — and the committed register loads (24 rows). `compare()`
matrix on synthetic records: pristine-timeout + admitting row → `reviewed_difference`; + diagnostic
row / no row / moved fork signature → `incomplete`; fork-timeout + row → `incomplete`; pristine-kill
+ row → `incomplete`; fork-kill → `incomplete`; a stale row whose pair now agrees → `difference`;
a moved pin → `difference`. Real: the control pair + the fork-verdict mutation → `plant_rejected`
(the pre-existing plant); a REAL registered fork≠pristine difference (`multi_tu_tray/arr-2-2-return`)
run once and compared twice — with its row → `reviewed_difference`, row WITHHELD → `difference`
(RED); a vacuity guard fails the plant if no completing `shared-model-fix` row exists to plant.

### 3.5 O1 FAST-GATE, verbatim (`o1-gate-full.txt`, `o1-gate-plant.txt`)
```
Independent oracle scope: tier-b; 855 rows in 112.4s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 822, 'reviewed_difference': 20, 'matching_failure': 11, 'interface_agreement': 2}; …/.tmp/o1-gate/full/report.json
Independent oracle scope: plant; 28 rows in 1.3s; source unchanged: True
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 26}; …/.tmp/o1-gate/plant/report.json
```
Zero movement of any pre-existing row (derived): 738 → 822 = 738 + 4 + 48 + 32; 1 → 20 = 1 + 3 + 16;
11 → 11; 2 → 2; library probe `passed`.

## 4. O2 — three engines (`57a0e4ee0`)

`--with-lean` runs the Lean engine per batch case through the fork's `--cabs-json` bridge exactly as
the owning fork-vs-Lean lane does, recipes carried per case in `corpus()` with cites: test_exec.sh:445-451
(`--cabs-json` → `--batch`), test_bytes.sh:79-81/:88 (`--nolibc --cabs-json`), test_libc_exec.sh:97/
:104-105 and test_immaculate.sh:163-173 (`--batch --first` [`--args "ab cd"`] + `--libc tests/libc/
libc.core --libc-tu` ×12 from `libc_prep.sh --jsons`, count checked = 12), test_multi_tu.sh:175/:192
(one bridge per TU; the tray under row 6b's `failure-class` projection), test_cn_coverage.sh:235/:239
(`-I <dir>` bridges), test_libxml2_uri.sh:186/:193/:221 (the nolibc row under `failure-class` — that
lane compares the `memset` Error modulo the symbol id, VALIDATION §1(a)/tray 17), test_verify.sh:128/
:78-79, test_libxml2.sh:144/:204/:214-215, csmith as test_exec. `LEAN_ABORT_ON_PANIC=1` (common.sh:319);
the Lean binary is a PREREQUISITE (never built by the lane — the lanes' `build_lean` runs under
`scripts/capped`; `check_driver_fresh.sh --check-lean` fail-closed). Decoding: `observations.py`
unchanged. Classes: `lean_agreement` | `lean_difference` | `lean_both_undecodable` |
`lean_incomplete` | `lean_bridge_failed` | `lean_not_applicable` (the 2 CLI rows). Per case the
report carries `three_engines: {pristine, fork, lean}` tokens; every Lean≠fork row is printed
`LEAN≠FORK` with the three tokens and listed in `report.json` `lean_differences`. GATING is
unchanged (pristine vs fork + register); the Lean column never gates. LADDER Tier C row **C5**.

**The report over the Tier B corpus, verbatim (`o2-with-lean-tier-b.txt`):**
```
Independent oracle scope: tier-b; 855 rows in 244.6s; source unchanged: True
Three-engine report (Lean column, NOT gating): {'lean_agreement': 813, 'lean_difference': 28, 'lean_both_undecodable': 12, 'lean_not_applicable': 2}; Lean≠fork rows: 40: minimal/073-exit.libc.c, minimal/074-abort.libc.c, minimal/097-null-ptr-arith.undef.c, coverage/builtin/builtin-006-exit.libc.c, coverage/expr/expr-007-bitfield-ops.c, coverage/io/io-004-puts.libc.unsupported.c, coverage/libc/libc-002-calloc.c, coverage/libc/libc-011-memset.c, coverage/libc/libc-012-strlen.c, coverage/mem/mem-007-zero-size-array.c, coverage/misc/misc-001-void-ptr-arith.c, coverage/union3/union3-004-union-copy.c, coverage/union3/union3-005-union-return.c, debug/libc-01-memset.libc.c, debug/libc-02-strlen.libc.c, debug/ub-static-reject.c, debug/valid-04-exit-before-oob.c, bytes/byte_is_not_char.c, bytes/no_add.c, bytes/no_shift_left.c, bytes/no_shift_right.c, bytes/only_unsigned_char.c, immaculate/nolibc/f3-raw-high-byte-char-const, immaculate/nolibc/f3-raw-high-byte-int, immaculate/nolibc/f3-raw-high-byte-uchar, immaculate/nolibc/g4-bswap64-overflow, immaculate/nolibc/g5-decode-multichar, immaculate/nolibc/g5-decode-question, immaculate/nolibc/offsetof-union-member, immaculate/nolibc/r5-hex-subnormal-double-rounding, immaculate/nolibc/zd-e2-ptr-string-literals, immaculate/nolibc/zd-z2fl03-nan-to-int, immaculate/nolibc/zd-z2m01-aligned-alloc-zero-nolibc, immaculate/nolibc/zd-z2m02-device-funptr-call, immaculate/libc/g2-memcmp-uninit, immaculate/libc/g5-escape-roundtrip, immaculate/libc/s4b-memcmp-hugesize, immaculate/libc/zd-z2f04-closedir, immaculate/libc/zd-z2m01-aligned-alloc-zero-zero, immaculate/libc/zd-z2m01-aligned-alloc-zero
Independent oracle: passed; {'semantic_agreement': 822, 'reviewed_difference': 20, 'matching_failure': 11, 'interface_agreement': 2}; …/.tmp/o2/full/report.json
```

**S2 screen — every Lean≠fork row against the owning lane's pin (`o2-lean-diffs-join.txt`, tool
`o2-lean-diffs-join-tool.py.txt`; the 12 "undecodable" rows read raw in
`o2-lean-diffs-undecodable-detail.txt`):** ZERO S2 findings — all 40 are recorded classes:
- 18 `tests/immaculate/baseline.txt` pins: `MATCH | L=CRASH` both-crash pairs (12, `lean_both_
  undecodable`: fork uncaught exception 125 vs Lean PANIC 134 / `ModelFailure` 1), `ORACLE_CRASH`
  pins (R1 `g5-decode-question` L=`Specified(63)`, R3 `s4b-memcmp-hugesize`, `zd-e2-ptr-string-
  literals`, `zd-z2m01-aligned-alloc-zero[-nolibc]`), `DIFF` pins (R2 `g5-escape-roundtrip` 87 vs 127,
  R5 `r5-hex-subnormal-double-rounding` 0 vs 1). Class (a)/(d), VALIDATION §1/§2.
- 10 exec-baseline `CERB_SKIP` rows whose Error texts agree under `failure-class` — the embedded
  symbol id is numbered differently by the two engines (§1(a), tray 17): the `.libc.c` rows
  (`calling an unknown procedure: Symbol(N, SD_Id("exit"))` …), `io-004-puts.libc.unsupported.c`,
  `libc-002/011/012`, `valid-04-exit-before-oob.c`.
- 11 front-end rejections: fork diagnostic on stderr, exit 1, empty stdout vs Lean `Error {msg:
  "desugaring/typechecking failed at <loc>"}`, exit 1 — the §1(a) standing member "front-end
  rejections reported on stderr by the oracle and as an `Error {msg: …}` line on stdout by Lean":
  6 exec-baseline `CERB_SKIP` rows (`expr-007-bitfield-ops`, `mem-007-zero-size-array`,
  `misc-001-void-ptr-arith`, `union3-004/005`, `ub-static-reject`) and the 5 `test_bytes.sh`
  front-end-reject pins (`byte_is_not_char`, `no_add`, `no_shift_left`, `no_shift_right`,
  `only_unsigned_char`).
- `minimal/097`: both-fail (fork `Failure("TODO(pure shift a null pointer …)")` 125 vs Lean
  `PANIC at CerbMem.arrayShiftPtrval … TODO(pure shift a null pointer …)` 134, same text).
Note: the `CERB_SKIP` rows are the FIRST Lean-vs-fork observation on those files — test_exec.sh
never samples Lean after an oracle skip ("both-sides-timeout invisibility" caveat) — recorded here,
not admitted anywhere.

**O2 FAST-GATE after the edit, verbatim (`o2-gate-*.txt`):**
```
Independent oracle scope: tier-b; 855 rows in 113.8s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 822, 'reviewed_difference': 20, 'matching_failure': 11, 'interface_agreement': 2}; …/.tmp/o2-gate/full/report.json
Independent oracle scope: plant; 28 rows in 1.4s; source unchanged: True
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 26}; …/.tmp/o2-gate/plant/report.json
```

## 5. O4 — doctrine (`664f9d0a7`)

Landed text: VALIDATION.md §0 "**The reference doctrine**" (quoted in full there; the operative
sentences): *Pristine upstream `b9aeedcb4` is THE reference. The fork's OCaml is the shared model's
mirror twin … a shared-model edit moves the fork oracle and Lean TOGETHER and every fork-vs-Lean
lane is blind to it by construction. … the register … is the ONLY permitted list of fork≠pristine
behaviours, and LADDER Tier B row 10 … is its gate … A SHARED-MODEL SLICE runs the three-way
`pristine | fork | lean` report … over the full pristine corpus and may add register rows only with
a citation; a fork≠pristine difference no existing citation explains is a finding for the operator,
never a row the slice writes itself.* §0 terminology names the pristine ENGINE beside the source;
§3 gains the fork≠pristine inventory (3 shared-model-fix, 21 diagnostic-text, the unregistered
both-sides timeouts); §4 "Pristine upstream, the reference" replaces the un-forked-checkout
paragraph; §5 gains four lane rows; §8 names rows 10 + 12. LADDER.md: row 10 rewritten; row 6b's
rationale updated (the tray is WALKED); Tier B row 12 (`--corpus libxml2_chvalid`); Tier C rows C5
(`--with-lean`), C6 (`--corpus ci`), C7 (`--corpus csmith --shard 1/34`) — C6/C7 carry the honest
"exit nonzero while both-sides timeouts stand" note (as C1's NOTE does). `release.py --list` parses
B10.1/B10.2 (unchanged), B12, C5-C7; `release.py` itself was not edited. `lean_frontend/README.md`
not edited (its only "oracle" is the build-section comment). The membership hash moves with LADDER.md.

**O4 FAST-GATE (docs-only change), verbatim (`o4-gate-*.txt`):**
```
Independent oracle scope: tier-b; 855 rows in 113.7s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 822, 'reviewed_difference': 20, 'matching_failure': 11, 'interface_agreement': 2}; …/.tmp/o4-gate/full/report.json
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 26}; …/.tmp/o4-gate/plant/report.json
```

## 6. The FULL gate — `python3 scripts/release.py --mode full` at `664f9d0a7`

Run once, at the O4 head, from the worktree, `scripts/ce python3 scripts/release.py --mode full --out
.tmp/release-full/evidence` (Tier A + B = 37 commands including the widened B10.1/B10.2 and the new B12;
started 2026-09-16T22:46:50Z, finished 2026-09-17T00:12:25Z, load 0.09 at start, nothing else of mine
running). Evidence: `full-gate-driver.txt` (the runner's transcript), `full-gate-summary.txt`,
`full-gate-per-lane-tails.txt` (this table), `full-gate-B7-tail.txt`.

**Runner summary, verbatim (`full-gate-summary.txt`):**
```
full: failed; 36/37 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

**Per-lane status and verdict tail (verbatim tails; `full-gate-per-lane-tails.txt`):**
```
release.py --mode full @ 664f9d0a7 branch arc/pristine-oracle-instrument; started 20260916T224650.588303Z finished 2026-09-17T00:12:25.615859+00:00; status failed; membership_sha256 4d7780bcd6d0394b…; source_unchanged True; selection_complete True
A1     PASSED      157.6s  test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
A2     PASSED       29.4s  BASELINE OK
A3     PASSED       50.5s  BASELINE OK
A4     PASSED       22.2s  BASELINE OK
A4b    PASSED       23.7s  BASELINE OK
A4c    PASSED        3.0s  SUMMARY: exec_match=9 neg_pinned=5 fail=0
A5     PASSED       21.8s  SUMMARY: match=12 diff=0
A6     PASSED        2.1s  SUMMARY: total=2 match=2 fail=0
A6b    PASSED        3.5s  SUMMARY: total=7 match=7 fail=0
A7     PASSED       10.0s  ALL PASSED
A8     PASSED        8.5s  ALL PASSED
A9     PASSED       16.1s  SUMMARY: total=111 same=108 diff=3 ocaml_fail=0 lean_fail=0
A10    PASSED       16.7s  GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
A11    PASSED       57.0s  BASELINE OK (213 entries, exact match)
B1     PASSED      603.3s  SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
B2     PASSED       22.7s  ALL PASSED
B3     PASSED       14.8s  ALL PASSED
B4     PASSED       46.0s  test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
B5     PASSED       70.8s  OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lea
B6.1   PASSED      166.8s  test_speclab: PASS (both pipelines agree on Specified(0))
B6.2   PASSED        2.3s  test_speclab: PASS (both pipelines agree on Specified(2))
B6.3   PASSED        9.0s  test_speclab_divmod: PASS (--gate)
B6.4   PASSED        8.9s  test_speclab_bytearr: PASS (--gate)
B6.5   PASSED        9.0s  test_speclab_list: PASS (--gate)
B6.6   PASSED       10.8s  test_speclab_tree: PASS (--gate)
B6.7   PASSED       19.5s  test_speclab_seed: PASS (--gate)
B7     FAILED     1476.7s  Baseline check: 1 regression(s), 0 improvement(s)
B8.1   PASSED       13.4s  test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
B8.2   PASSED      226.4s  test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
B8.3   PASSED        6.4s  test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
B8.4   PASSED       16.2s  test_failstop_plant: PASS (11 class and rejection checks)
B9     PASSED     1417.9s  observation lane plants: 93/93 passed
B10.1  PASSED      116.3s  Independent oracle scope: tier-b; 855 rows in 116.1s; source unchanged: True || Independent oracle: passed; {'semantic_agreement': 822, 'reviewed_difference': 20, 'matching_failure': 11, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pristine-oracle-inst
B10.2  PASSED        1.6s  Independent oracle scope: plant; 28 rows in 1.4s; source unchanged: True || Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 26}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pristine-oracle-instrument/.tmp/release-full/evidence/B10.2
B11.1  PASSED       15.3s  check_failure_reach: SELFTEST OK (5 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally — and the unplanted register green)
B11.2  PASSED        6.7s  check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row
B12    PASSED      430.7s  Independent oracle scope: libxml2_chvalid; 4 rows in 430.5s; source unchanged: True || Independent oracle: passed; {'semantic_agreement': 4}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pristine-oracle-instrument/.tmp/release-full/evidence/B12/independent-oracle/report.json
```

**The one red — B7, `./scripts/test_gcc_oracle.sh --check-baseline` (1476.7 s), verbatim tail
(`full-gate-B7-tail.txt`):**
```
gcc second-oracle summary
============================================
  Total files:  1997
  Compared:     1915  (agree=1903 agree_nd=0 triaged=12 DISAGREE=0)
  Skipped:      82  (every skip enumerated below and in the baseline rows)
    O2_AGREE: 196
    SKIP_GCC_COMPILE: 1
    SKIP_GCC_STDOUT: 1
    SKIP_LEAN_CRASH: 12
    SKIP_LEAN_FAIL: 9
    SKIP_LEAN_TIMEOUT: 12
    SKIP_UB: 47
    TRIAGED_ADDR: 11
    TRIAGED_UB: 1

SUMMARY: total=1997 compared=1915 agree=1903 agree_nd=0 triaged=12 disagree=0 o2_agree=196 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=12 skip_lean_fail=9 skip_lean_timeout=12 skip_ub=47 triaged_addr=11 triaged_ub=1

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pristine-oracle-instrument/scripts/gcc_oracle_baseline.txt
REGRESSION: csmith/sia_csmith_477.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-

Baseline check: 1 regression(s), 0 improvement(s)
```
Reading: the lane's only movement is `csmith/sia_csmith_477.c` `AGREE → SKIP_LEAN_TIMEOUT` —
`disagree=0`, every other row at its ledger. This is the WALL-CLOCK class LADDER Tier B row 7
documents verbatim: *"the TIMEOUT-class rows are wall-clock sensitive (TIMEOUT_SECS=30; the slowest
csmith rows hand-time at ~17 s on a quiet box …) — a REGRESSION whose only movement is into
SKIP_LEAN_TIMEOUT is re-run on a quiet box before it is read as red; no code change"*; VALIDATION
§3(b) names `sia_csmith_477/769` as rows "at the lane bound". Nothing in this slice can move a
Lean timing: no `.lem`/`.ml`/`.lean`/Makefile/lakefile edit, the Lean binary is the primed one
(`check_driver_fresh: lean OK (bin 5f6dfacf…)`), and B7's inputs are untouched. Per that rule the
lane was re-run alone on the quiet box through the same runner:

`scripts/ce python3 scripts/release.py --mode full --lane B7 --out .tmp/release-b7-rerun` (started
2026-09-17T00:19:07Z at load 0.43 — but the box did NOT stay quiet: other agents' work took the load
to `2.70, 6.65, 9.83` at 00:29:50 and `1.42, 10.13, 13.09` at 00:40:20, `0.43, 3.01, 8.54` at the end
00:47:51). The lane PASSED regardless — verbatim (`full-gate-B7-rerun-driver.txt`,
`full-gate-B7-rerun-tail.txt`):
```
=== B7 re-run START 2026-09-17T00:19:36Z head 664f9d0a7 load average: 44.34, 29.84, 15.77
Release evidence: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pristine-oracle-instrument/.tmp/release-b7-rerun
RUN B7: ./scripts/test_gcc_oracle.sh --check-baseline
PASSED B7 (1388.5s)
full: incomplete; 1/1 selected commands completed successfully.
Source unchanged: True. Complete tier selection: False.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```
```
gcc second-oracle summary
============================================
  Total files:  1997
  Compared:     1916  (agree=1904 agree_nd=0 triaged=12 DISAGREE=0)
  Skipped:      81  (every skip enumerated below and in the baseline rows)
    O2_AGREE: 196
    SKIP_GCC_COMPILE: 1
    SKIP_GCC_STDOUT: 1
    SKIP_LEAN_CRASH: 12
    SKIP_LEAN_FAIL: 9
    SKIP_LEAN_TIMEOUT: 11
    SKIP_UB: 47
    TRIAGED_ADDR: 11
    TRIAGED_UB: 1

SUMMARY: total=1997 compared=1916 agree=1904 agree_nd=0 triaged=12 disagree=0 o2_agree=196 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=12 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pristine-oracle-instrument/scripts/gcc_oracle_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```
So the FULL gate's single red is the documented wall-clock class and every one of the 37 Tier A+B
commands has passed at this head (36 in the full run + B7 in the re-run under a busier box). The
runner's `full: incomplete` for the re-run is its subset semantics ("Complete tier selection:
False"), not a lane failure. The orchestrator's independent re-verification on a quiet box is the
reading of record; `sia_csmith_477.c` stays what VALIDATION §3(b) already says it is — a row at the
lane bound, a (b)-VIOLATION pending completion evidence, not moved by this slice.

**Zero movement of any existing baseline row** (the charter's gate): every baseline lane (A2–A4c,
A5, A6, A6b, A9–A11, B1, B4, B5, B10.1) reports its committed state unchanged; B10.1's 20
`reviewed_difference` rows are exactly the register's 20 pinned cases (the 1 pre-existing + the
19 added here); B7's single movement is the documented wall-clock class above.


## 7. Errata, open items, stops raised, the rule handed on

**Errata to charter §1 (facts I found off; none changes a conclusion):**
1. "audit-repairs record `:128-133`" / "`:1776`" resolve to `lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md` (`:133`, `:1776`), not the 2026-09-06 validation-foundations audit-repairs record (198 lines).
2. In `2026-09-06_independent-oracle-and-fork-pins.md` the fail-rules sentence is at `:94-95` (charter `:89-91`) and the fork-only-flags sentence at `:101-102` (charter `:103-104`); the scope statement `:73-79` is right.
3. `scripts/test_observation_lanes.py` has NO row-10 plant (its `LANES` tuple never included the upstream lane), so the fence clause "only where its row-10 plant needs the new schema" has no referent; the file was not touched.
4. `build_independent_oracle.py:69-130`: `main()` runs to `:142`; the argument block is `:70-76`. Cosmetic.

**Stops raised for the orchestrator (the slice continued fail-closed; nothing was admitted):**
- **S5 — both-sides timeouts.** `tests/ci` `0023-jump1.c`/`0025-jump3.c` (30 s) and 21/50 csmith
  shard-1 programs (15 s) time out on BOTH engines at the owning lane's bound (the fork lanes record
  them `CERB_SKIP`/`CERB_TIMEOUT`). Charter O1 admits a pristine-side 124 only via a cited
  resource/shared-model-fix row and the fork side never, so no register class covers them; I did
  not invent one. Consequence: ci and csmith are reporting rows (C6/C7) whose exit is nonzero while
  these stand. Question: should a both-sides timeout be admissible through a `resource` row binding
  both 124 signatures (citing the fork lane's own skip row), or is "incomplete is never agreement"
  the intended permanent stance (then C6/C7 stay red by design)?
- **S5 — backtrace-position normalisation** (the `:1752` question): 21 diagnostic-text pins that
  move on every generated-line shift; csmith's both-crash rows (hundreds across the corpus) cannot
  sensibly be pinned. A diagnostic projection that normalises `line N`/`characters A-B` inside
  `Called from`/`Raised …` frames would turn them into `matching_failure` — a change to what the
  lane admits, hence the operator's.
- **Reading conflict (§3.3):** the 20 non-tray diagnostic-text rows — written under §3 S1's
  definition ("a new semantics finding"), flagged for striking under O1's narrower parenthetical.

**Open items (outside the fence or the charter):**
- `tests/multi_tu_tray/README.md` ("`scripts/upstream_oracle_differences.json` … untouched"; "kept
  OUT … because the pristine lane … cannot admit") is now stale: the tray IS walked by row 10 through
  its three rows. Not in the fence; one-paragraph fix for the orchestrator.
- `test_csmith_corpus.sh`'s shard order is locale-dependent (`find | sort`); this lane orders in
  codepoint order — a shard K/M here is not that lane's shard K/M. Fix belongs to that lane.
- The container hook's end-to-end exercise (creating a worktree) — not done here.
- `lean_frontend/TODO.md` was not edited (not in the fence); the two S5 questions and the README
  drift are candidates for it.
- No `release.py` change was needed; `reporting_result` marks C6/C7 `failed` in `--mode reporting`
  while their both-sides timeouts stand — honest, documented in LADDER.

### 7.1 Resolution — O5 (`9cbd9b86f`, 2026-09-17)

The orchestrator re-verified the slice independently (row 10 full + plant, `test_unit.sh`,
`release.py --mode fast` — all reproduced the lines above) and put the two S5 questions to the
operator as three questions: (1) both-sides timeouts → a REPORTED class `matching_incomplete`
(both sides status 124 at the lane's own bound), counted, NOT failing; any ONE-sided timeout
(either side) and any 137 stay `incomplete` and fatal; no register row for matching timeouts;
(2) backtrace-position normalisation → the diagnostic projection additionally normalises
`line N, characters A-B` inside OCaml backtrace frames in BOTH engines' stderr, so a both-crash
pair whose frames differ only in positions is a `matching_failure`; the 21 `diagnostic-text` rows
are DELETED and the register becomes exactly the 3 `shared-model-fix` tray rows, the class kept
with zero rows; (3) the reading conflict, moot given (2).

**[USER 2026-09-17], verbatim:** *"(1) agree, (2) agree, (3) redundant per 2. Agree wiht the audit
as proposed"*.

Applied at `9cbd9b86f` exactly as stated (nothing else changed): `compare()` — 137 on either side
→ `incomplete`; both 124 → `matching_incomplete` (a row is irrelevant; the loader still refuses
fork-side 124/137); fork-only 124 → `incomplete`; pristine-only 124 → admitted only through a
cited `resource`/`shared-model-fix` row, as before. `project_diagnostics()` — the `Time spent`
trailer removed, then `line N[-M], characters A-B` inside frames beginning `Raised at` / `Raised
by primitive operation at` / `Called from` / `Re-raised at` (… `in file "…"[ (inlined)]`) →
`line N, characters A-B`; exception text, frame function/file names, non-frame lines, stdout
untouched; raw stderr retained ([AGENT] reading: "Raised by primitive operation at" is the
OCaml frame form of "Raised at" and is included). Twelve hermetic plants added (the timeout/kill
matrix; frame-positions-only → `matching_failure`; exception-text, frame-function, non-frame-
position and stdout-beside-crash differences → `difference`; raw sha differs while the
diagnostic sha agrees). The 21 rows deleted (`o5-register-rows-deleted.txt`); `VALIDATION.md`
§0/§3/§4/§5, `LADDER.md` rows 10/C6/C7 and `tests/multi_tu_tray/README.md` updated.

**Gates at `9cbd9b86f`, verbatim (`o5-gate-full.txt`, `o5-gate-plant.txt`, `o5-gate-ci.txt`,
`o5-gate-csmith.txt`, `o5-gate-test_unit.txt`):**
```
Independent oracle scope: tier-b; 855 rows in 115.9s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 3, 'interface_agreement': 2}; …/.tmp/o5-gate/full/report.json
Independent oracle scope: plant; 40 rows in 1.4s; source unchanged: True
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 38}; …/.tmp/o5-gate/plant/report.json
--corpus ci:                Independent oracle: passed; {'semantic_agreement': 134, 'matching_incomplete': 2, 'matching_failure': 106}   (rc 0)
--corpus csmith --shard 1/34: Independent oracle: subset_passed; {'semantic_agreement': 26, 'matching_failure': 3, 'matching_incomplete': 21}   (rc 0; 641.2 s)
./scripts/test_unit.sh: rc 0
```
Row 10 reads `matching_failure` 28, not the 32 the orchestrator's expected shape named: the 4 ci
`.error.c` rows are in C6 (`--corpus ci`), not in row 10 — 11 + 17 = 28 there and 102 + 4 = 106
in C6 (derived). Every other count is unchanged from §3.5/§4 (822 / 2; C6 134 / 2; C7 26 / 21 /
3), i.e. the two rulings moved exactly the rows they name and nothing else; `test_unit.sh` is
green. The FULL gate of §6 was run at `664f9d0a7` and is not re-run here: O5 changes only this
lane, its register and documentation, and the orchestrator's re-verification is the reading of
record.

**The one-line rule handed to the S1 charter:** *a shared-model slice reports `pristine | fork |
lean` over the full pristine corpus (`python3 scripts/test_upstream_oracle.py --with-lean`, plus
`--corpus libxml2_chvalid`, and the C6/C7 selections where its change could reach) and may add
register rows only with a citation — every pristine≠fork difference no existing citation explains,
and every Lean≠fork row that is not already a recorded pin of the owning lane, is a STOP for the
operator, never a row the slice writes.*

## 8. Provenance

[USER] quotations only where marked and only from the charter. All measurements are this worker's,
2026-09-16 21:40 – 2026-09-17 00:48 UTC, on the worktree named above, load ≤ 1.2 throughout; quoted outputs are
verbatim from the evidence files; tallies marked derived are computed from `report.json` files kept
under the worktree's `.tmp/` (ephemeral) and summarised in the evidence dir.
