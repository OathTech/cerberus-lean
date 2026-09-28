# Test-depth map — which trust surfaces are thinly tested (2026-09-28)

[AGENT — fresh skeptical reviewer, Claude subagent, 2026-09-28]. Branch `audit/test-depth-20260928`, one commit, no
push. Read-only measurement: no build, no lane run, no code/baseline/other-doc change.

**Why this exists.** [USER 2026-09-28]: "we identify trust surfaces which are less well-tested than others, if any
exist. That's the real miss wrt the bug, we knew that SybllFS wasn't a well-tested mirror, but that wasn't clearly
documented". The CerbFS path defect (`docs/2026-09-28_cerbfs-path-hotfix-record.md`) was served by a surface that no
lane exercised; nobody had written that down. This record writes it down for every other surface.

**Tree measured.** `23ee2d23f` (head of `arc/contract-enforcement`: mainline `a7dc36e2f` + the D2 filesystem refusal
`835c230b1`, the function-pointer-to-integer refusal `45a53c421`, the class-(e) register entry N1 `51d95068e`, and the
draft `CONTRACT.md`). Mainline `mdd/cerberus-lean` is `d62f52121`, which does NOT yet contain those enforcement commits;
the ratings below describe the enforcement branch. The corpora, baselines and seams are read at this commit; the CN
corpus is read at `/home/dev/projects/cerberus-lean-proj/deps/cn/tests/cn` (the path `test_cn_coverage.sh` uses).

**Builds on.** The 2026-09-07 risk map (`docs/2026-09-07_risk-map-baseline.md`) measured gate *movement* (what
changed, whether ruled); it did not measure per-surface *exercise*. Today's served-surface audit
(`worktrees/cerberus-lean-audit/served-surface-20260928/lean_frontend/docs/2026-09-28_served-surface-audit.md`, 45-row
ledger) classified every default arm of the seams as mirror/refuse/unreachable, and probed 72 adversarial programs;
its probes are NOT lane rows, so they are evidence of today's agreement, not of a regression guard. This record asks
the complementary question: for each surface, how many committed, gated lane programs actually exercise it?

## 0. Summary

- **Denominator** (measured, §A.1). The gating Lean-vs-fork lanes hold **872 agreement programs** (baseline
  `MATCH`/`UB_MATCH`, or an agreeing fixed-reference lane): 795 compared exhaustively in `--nolibc` mode, 45 in
  `--first` `--nolibc` mode (immaculate, chvalid), and **32 in libc mode — all of them `--first`**. The Tier C corpora
  (csmith 1,161 MATCH, `tests/ci` 132) are reporting-only and are not counted as gate evidence.
- **The core is deep.** Everything every program touches — Cabs import, the shared-Lem frontend and Core dynamics,
  load/store and allocation in `CerbMem`, integer arithmetic, the exhaustive runner, the batch printer — is exercised by
  hundreds of gated programs, a pristine-upstream gate (855 cases), and for integers/floats an independent gcc second
  oracle (263 corpus + 1,654 csmith programs `AGREE`, measured from `scripts/gcc_oracle_baseline.txt`).
- **Depth falls off sharply at the edges, in hand-written code.** Measured gated agreement programs per surface:
  `printf("%f")` (hand-written glibc `%.Nf` mirror `CerbFloat.formatFixed`) **0** (the printer function alone has
  13 unit cases against a recorded OCaml transcript in `pp-test`); `errno` **1**; `memcmp` value
  path **1**; `memset` **1**; `snprintf`/`vsnprintf` **2**; `realloc` **4**; `memcpy` **5**; C-level `argv` **5**;
  user multi-TU programs **8**; C-program stdin **0**; `getenv` **0**; libc functions called directly by any libc-mode
  lane program **11 of 188** defined in `runtime/libc/src` (14 counting the libxml2 TUs, derived).
- **Three interface surfaces nobody compares:** the non-batch CLI output (always exits 0, human format), `--pp-core`
  output (placeholder printer, signature-level check only), and the CLI refusals of `--concurrency`/`--switches`
  (no lane witness, contrary to CONTRACT §4.1).
- **Two statements in the draft CONTRACT are overtaken by this measurement** (§2 items 7 and 14): stdin is listed
  "partially SUPPORTED" but every C-level stdin read now reaches `CerbFS.fs_read` and refuses (derived from code, not
  run); `.core` text input is listed SUPPORTED but the driver has no mode that executes user Core text — `--parse-core`
  only reports declaration counts.

Rating rubric [AGENT]: **STRONG** — shared-Lem code exercised by hundreds of gated agreement programs, or a
hand-written seam exercised by ≳50 across ≥2 independent corpora, or a kernel theorem covering the property.
**MODERATE** — a hand-written seam with roughly 10–50 gated programs or a designed battery plus adversarial pins; or
shared code with few programs. **THIN** — a hand-written seam with <10 gated agreement programs, or a served channel
no lane observes. Where a rating sits on a boundary the row says which way it leans and why. Hand-written seams are
weighted down relative to generated code: generated Lem is structurally shared with the oracle (a bug there is
usually in both engines and only the gcc second oracle, the committed `.exec` references or ISO review can see it);
a hand-written seam is an independent re-implementation and diverges silently unless a lane observes it.

## 1. The map

Legend for "Reference": **SHARED** = generated from the shared `.lem` (structurally identical to the oracle's
generated OCaml); **SEAM** = hand-written Lean mirroring OCaml (file:line cites in the seam); **LEAN-ONLY** = Lean
mechanism with no OCaml counterpart (its "oracle" is a wrapper or a harness convention); **OCAML-SHARED** = the fork's
OCaml runs it for both engines. Counts are gated agreement programs unless stated; "m" = measured by the census
(§A), "d" = derived (classification, filename heuristic, or code reading).

### 1.1 Front end and Core input

| Surface | What checks it | Reference | Depth | Known gaps |
|---|---|---|---|---|
| C preprocessing + parsing | Oracle's own parser feeds both engines (`--cabs-json` bridge); `test_parse.sh` 234 files (Tier A 7 / B 2) | OCAML-SHARED | STRONG — not a Lean surface; a parser bug is in both engines | fork-only JSON exporter is compared only indirectly (fork executes its in-memory Cabs, Lean the JSON) — which the exec lanes do on every program |
| Cabs JSON import (`CabsImport.lean`, 829 lines) | Every program: 872 m; `test_cabs_bytes_probe.py`, f3 raw-high-byte immaculate rows (3, both-crash/MATCH d) | SEAM (decoder of the fork's exporter) | STRONG — fail-closed decoder (`\| _ => err`), exercised on every run | Cabs constructors absent from all corpora are unmeasured (would refuse, not mis-decode — served-surface ledger); byte content of non-ASCII string literals rests on 3 f3 rows + `zd-z2p01-*` (2) |
| Desugar (`Cabs_to_ail`), typing (`GenTyping`), elaboration (`Translation`) | Every program; pristine gate 855 cases (Tier B 10); 112 front-end reject rows measured in the Z1 record (VALIDATION §1(a)); `tests/bytes` 5 reject pins; `test_elab.sh` signature-level only | SHARED | STRONG | `test_elab.sh` compares signatures, not bodies (script header); exec lanes carry the body evidence |
| Integer/char constant decoding (`CerbDecode.lean`, 196 lines) | Integer constants: every program; char/string escapes 7 m; immaculate R1/R2 register rows, `g5-decode-multichar` both-crash; argv backslash failure-probe witness | SEAM | MODERATE — integers strong, escapes thin | `%c`/escape round trip is pinned only as the R2 DIFF row; multichar/`\x` long escapes few rows |
| Frontend symbol supply + TU digests (`CerberusFresh.lean`, native MD5) | Every run; `RunDigestTest` (14 theorems m); `g6-hash-collision` tripwire; `zd-z28-addr-layout-{a,b}` digest-order rows | SEAM + native | MODERATE — the one surface already known to diverge: the symbol-number offset (oracle = Lean + 483 nolibc, served-surface P1-1) now refused on the int-cast channel and registered N1 on the byte/`%p` channel | any other channel that leaks a symbol number (Error text is class (a) under `failure-class`) — unmeasured beyond the served-surface probes |
| Core text parser on the runtime files (`CoreParser.lean`, 2,990 lines: `std.core`, the impl file, `libc.core`) | Parsed on every one of the 872 runs; `libc.core` hash-pinned (`tests/libc/libc.core.sha256`); `CoreParserTest` + 280 parser unit tests (row 1) | SEAM | STRONG for these three fixed inputs | numbering is by name hash, not by the oracle's supply (root of N1) |
| Core text as user input (`--parse-core`) | `test_core.sh`: tests/minimal 111 + tests/ci — **parse success only** (Main.lean prints declaration counts; nothing executes) | SEAM | THIN as a semantic surface — no execution path exists for user `.core` (derived from Main.lean `readInputs` → `CabsImport.parseJson`) | CONTRACT §3 row "`.core` text input … SUPPORTED" overstates: only parse acceptance is checked |

### 1.2 Dynamics and runners

| Surface | What checks it | Reference | Depth | Known gaps |
|---|---|---|---|---|
| Core dynamics (driver, `Core_reduction`, `Core_eval`) | Every program; pristine gate; gcc second oracle 263 corpus + 1,654 csmith AGREE (m); csmith corpus 1,161 MATCH (Tier C) | SHARED | STRONG | the one place the external report found nothing |
| Exhaustive ND runner (`CerbND.runND`) | 795 exhaustive agreement programs (m); full verdict-set comparison; trace order probes (seam header: 6-way, 8/8, 40/40, 67650/67650); fuel-stability theorems (`CerbNDFuelProofs`, 30 m) | SEAM | STRONG | how many lane programs actually have >1 execution is **unmeasured** (needs a run) |
| `--first` single trace (`CerbND.runND1`, branch 0 always) | 77 agreement programs run it (45 nolibc + 32 libc, m) — but only against the oracle's time-seeded `--mode=random`, so agreement is meaningful only for trace-independent programs | LEAN-ONLY (oracle picks randomly) | MODERATE (leans THIN as a user mode) | no theorem or gate that the first trace is a member of the exhaustive set (the proofs file relates fuels only, `run1_refines`); libc mode is NEVER compared exhaustively in any gated lane; README advertises `--first` as a user feature |
| Unsequenced evaluation / `Eunseq` / UB035 | 29 designed rows by filename (`tests/debug/unseq-*` 16, `tests/minimal/08x-09x-unseq*` 13, d) | SHARED + runner | STRONG | — |
| Default-mode atomics, `{-{…\|\|\|…}-}` par | 1 lane row (`coverage/z2-004-atomic-member-ub042`, m); served-surface probes agree (not lane rows) | SHARED | THIN (by count; lower divergence risk because shared) | CAS/fence mirrored `TODO` crashes; par statement 0 lane rows |
| `CerbConcurrency` stub | none needed | — | n/a — unreachable (served-surface §4: zero generated callers) | — |

### 1.3 Concrete memory model (`CerbMem.lean`, 3,237 lines, 93 lem target_reps m)

| Surface | What checks it | Reference | Depth | Known gaps |
|---|---|---|---|---|
| Allocation, lifetime, allocator, address layout | Every program; `test_address_space.sh` 6 programs × 3 tops (one genuine discriminator); allocator soundness theorems (`CerbMemAllocatorProofs`, `AllocatorSoundnessTest`); `zd-z28-addr-layout-*`, `012-global-alloc-order` | SEAM | STRONG | — |
| Load/store, byte representation | Every program; `tests/bytes` 9 at committed upstream `.exec` references (oracle-independent); Tier A row 13 with kernel erasure theorems (`MemoryAccessProofs`, 5 m) | SEAM | STRONG | — |
| Unspecified values, trap representations, uninitialised reads | 7 designed rows by filename (d: `mem-006`, `mem3-001/002`, …); immaculate UB012 ×2 (m) | SEAM | MODERATE (leans THIN) | padding-byte and partially-initialised-struct reads: few rows |
| Pointer arithmetic (`array_shift`, `member_shift`, `eff_*`), `ptrdiff` | `coverage/ptr2-006…010`, `mem3-008`, `ptr3-004/005`, `ptr-001` (d); CN corpus 213 (pointer-heavy); speclab byte arrays/lists | SEAM | STRONG for in-bounds use; MODERATE for edges | one-past-end/negative shifts: single designed rows |
| Pointer comparison, provenance, int↔ptr | 19 designed rows by filename (d); `(u)intptr_t` 17 m; `zd-z28-*` provenance rows (5); `ptr3-002/003` int→ptr | SEAM | MODERATE | relational comparison across allocations: 1–2 designed rows; the two-execution pnvi programs are not pinnable in the single-trace lane (test_immaculate.sh note) |
| Function pointers | 19 designed rows by filename (d: `ptr2-011…015`, `ptr-007`, `d3-s7-callback-*` 6); int cast REFUSED with 2 witnesses (`zd-funptr-int-*`); bytes/`%p` = register N1 (2 witnesses) | SEAM | MODERATE | numeric identity deliberately not served (refused) or registered (N1) |
| `malloc`/`calloc`/`aligned_alloc`/`free` (std.core proxies → CerbMem) | alloc 39, free 37 (m; 16 of each from speclab list/tree harnesses); UB rows `g3-*`, `zd-d6/d7-*`, `zd-z2m0x-*` | SEAM | MODERATE | `aligned_alloc(0,·)` is an oracle-crash pending row |
| `realloc` | **4 m** (`coverage/libc-003`, `mem3-007` value; `g3-realloc-dead`, `g3-realloc-non-heap` UB) | SEAM | **THIN** | grow/shrink with content preservation of interior data, `realloc(p,0)`, libc-mode realloc: 0 rows |
| `memcpy` | **5 m** (coverage 2, immaculate `g2-memcpy-{ok,oob,readonly}`) | SEAM | **THIN** | overlapping ranges, pointer-carrying copies (provenance through memcpy — `zd-d4-copy-alloc-id` is adjacent), unaligned sizes |
| `memcmp` | **1 value row m** (`coverage/libc-010`) + `g2-memcmp-uninit` both-crash + `s4b-memcmp-hugesize` (register R3) + 1 provenance use | SEAM | **THIN** | sign of the result for bytes ≥ 0x80, partial-length compares, pointer bytes |
| `va_start`/`va_arg`/`va_copy`/`va_end` | 7 direct m; plus every libc-mode `printf` goes through `vfprintf` → `__builtin_vprintf` with a `va_list` (~10 more, d) | SEAM | MODERATE (leans THIN) | `va_arg` of `double`/struct/pointer types: few rows; `long double` 1 |
| `memset` (libc C function; libc mode only) | 1 m (libc_exec `004-memset`; the two nolibc rows are oracle `CERB_SKIP`) | libc C over SHARED | THIN | — |

### 1.4 Implementation choices, numbers, output

| Surface | What checks it | Reference | Depth | Known gaps |
|---|---|---|---|---|
| Integer ops (`CerbMem` `op_ival` etc.), LP64 layout (`CerberusImpl.lean`) | Every program; csmith 1,161 MATCH (Tier C); gcc AGREE 263 + 1,654 (m); speclab divmod | SEAM | STRONG | `__int128`, `_Complex`, wide chars: 0 programs (m) — not declared supported either; bit-fields: the only real bit-field row is an oracle `CERB_SKIP` (m; the other regex hit is a false positive, §A.3) |
| Float arithmetic, conversions, literals (`CerbFloat.lean`, 439 lines) | 109 programs use `float`/`double` m (tests/float 72 + 24 hex literals); gcc AGREE all 93 tests/float (m); `FloatLiteralTest`; register R5 | SEAM | STRONG for arithmetic and literal parsing | `long double` 1 program m; float→int out-of-range: UB017 rows few |
| Formatted output core (`Formatted`, printf/vprintf/vsnprintf builtins) | 18 printf programs m (coverage `io-*` 4, immaculate 6, libc_exec 3, uri, chvalid 4); conversions in gated agreement rows: `%d` 11, `%u` 6, `%s` 5, `%ld` 3, `%llu` 1, `%p` 2 (m) | SHARED with SEAM leaves | MODERATE | **no width, precision, flag, `%o`, `%c`, `%e/%g/%a` in any gated agreement row, and `%x` only once (as `%lx` via `PRIxPTR`, `zd-z28-provenance_equality_uintptr_t_global_yx`)** (measured list of all format strings, §A.4); `%n` is `WIP` on both |
| `printf` `%f` (`CerbPP.format_string_of_float` → `CerbFloat.formatFixed`, a hand-written exact-decimal mirror of glibc `%.Nf`) | **0 programs m** in any lane (targeted regex over every corpus, §A.4); `pp-test` (row 1) checks `formatFixed` on 12 `%.*f` cases + `%f inf` against a recorded OCaml 5.4.0 transcript (`test/Unit/PPTest.lean` `ffCases`, m); served-surface probes agreed on 7 inputs (not lane rows) | SEAM | **THIN** — the printer has unit cases, but no program exercises the end-to-end path (conversion parse → default precision → width/flags padding → stdout) | rounding ties, huge magnitudes, precision > 17, negative zero, NaN/inf printing |
| `printf` `%p` of object pointers (`CerbPP.stringFromPointerValue`) | 2 m (`zd-z28-provenance_lost_escape_1`, `zd-z28-pointer_from_integer_2g`) | SEAM | THIN (borderline MODERATE: small, cited mirror) | `%p` of NULL / one-past-end: probes only |
| `snprintf`/`vsnprintf` (libc `snprintf` → `__builtin_vsnprintf`) | **2 m** (libc_exec 006, 007) | SHARED + libc C | **THIN** | size 0, NULL buffer, truncation return value: probes only (served-surface `p2_snprintf`) |
| Stdout/stderr escaping in verdicts (`CerbEscape`, batch printer) | Every stdout-producing row (~20 d); `zd-z2p01-{stdout,stderr}_escape`; `BatchEscapeTest` | SEAM | MODERATE | bytes ≥ 0x80 in program output: 2 rows (Lean strings are Unicode scalars, OCaml bytes — VALIDATION known difference) |
| UB detection + location rendering (`CerbLocation`, CerbMem's 14 `Merr*` kinds at 93 sites m) | 60 exec-lane `UB_MATCH` rows (18+16+20+6, m) compared on the full payload incl. `loc`; immaculate 12 UB rows, 10 distinct codes (m) | SHARED for most UB; SEAM for memory UB and `loc` text | MODERATE | the model has 365 UB constructors (m, `undefined.lem`); how many distinct codes the exec lanes exercise is **unmeasured** (baselines record only `UB_MATCH`) |
| Batch verdict printer + exit code (`Main.lean` batch branch) | Every gated row (observation contract, shared codec `full`) | SEAM | STRONG | — |
| **Non-batch CLI output** (`Main.lean`, no `--batch`) | **none** | LEAN-ONLY format | **THIN — uncompared** | prints a human summary and `return 0` for every outcome incl. UB (Main.lean after the batch branch); memory errors collapse through a `\| _ => "memory error"` arm; the oracle's non-batch path exits with the status its pipeline returns (`backend/driver/main.ml:232-233`, `Either.Right n -> epilogue n`; I read that as the program's return value, not confirmed by a run). Not documented as supported, but not refused |
| `--pp-core` output | `test_elab.sh` signature-level (reporting); `test_parse.sh` uses it as a no-exec front-end run | SEAM (placeholder `CerbPP`) | THIN as an output surface | the printer is a placeholder (test_elab.sh header); fine as long as nobody consumes the text |

### 1.5 Builtins, libc, environment

| Surface | What checks it | Reference | Depth | Known gaps |
|---|---|---|---|---|
| std.core `errno` | **1 m** (`coverage/ctrl2-003-errno.libc.c`) | SHARED + CerbMem | **THIN** | errno set by libc functions (`strtol` ERANGE etc.): 0 rows; served-surface `p2_errno_*` probes only |
| std.core `exit` (+ libc `abort`/`atexit`) | 7 m (debug 5 nolibc, libc_exec 001, immaculate `pr44468`) | SHARED | MODERATE (leans THIN) | `exit` codes <0 / >255, `atexit` ordering: probes only |
| GCC bit builtins (`CerbUtils` ffs/ctz/bswap) | 14 m (coverage 5, immaculate 4, CN 5) | SEAM | MODERATE | — |
| `any_bounded_int` | 0 m | SHARED (mirrored `TODO` crash) | THIN, not served (both engines crash — served-surface P3-1); VALIDATION Z2-U-02 text is stale | no pin that it stays a crash |
| `write` on fds 1/2 (driver-routed) | every libc-mode stdout program (`puts`/`fwrite` → `writev` → `write`, ~10 d) | SHARED | MODERATE | direct `write(1, …)` from user code: 0 agreement rows |
| Filesystem builtins (25 ops, `CerbFS`) | REFUSED (D2); witnesses: 5 DIFF rows + `zd-z2f04-closedir` both-crash (m) | refusal | n/a — refused with witnesses | — |
| C-program **stdin** (`getchar`/`fgets`/`read(0,…)`) | **0 m** | libc C → `read` builtin → `CerbFS.fs_read` | **THIN — unwitnessed** | Derived from code (`stdio.c` `__stdio_read` → `read(f->fd…)` → `driver.lem` `FS_READ` → `Fs.fs_read`): since D2 every stdin read REFUSES. No row pins that refusal; CONTRACT §3 still says "partially SUPPORTED" |
| **Environment** (`getenv`) | **0 m** | libc C | **THIN** | served-surface probe: NULL on both (not a lane row) |
| **argv** (`--args`, `prepare_main_args`) | **5 m** (`minimal/075`, `076` without args; immaculate `argv1-3-args` with `--args "ab cd"`); backslash failure-probe (both crash) | SHARED driver + SEAM splitter (mirrors `Str.split "[ \t]+"`) | **THIN** | non-ASCII argv bytes (Lean chars vs OCaml bytes) — **unmeasured**; many/long arguments |
| libc functions written in C (`runtime/libc/src`, 188 definitions d) | libc-mode lanes: libc_exec 12, immaculate/libc (agreeing subset), uri — 32 agreement programs m, **all `--first`**; direct calls cover **11** functions m (`printf` 10, `strlen` 3, `fprintf` 2, `abort`, `calloc`, `exit`, `memset`, `puts`, `snprintf`, `strtod`, `vsnprintf` 1 each); the uri TUs add `strchr`, `strcmp`, `strncmp` (d) | libc C over SHARED semantics | **THIN by breadth** | D4's "SUPPORTED by inheritance" is a structural argument (same Core semantics), not test evidence; `qsort`, `strcpy`/`strcat`, `strtol`, `sprintf`, `ctype`, `math`, `time`: 0 lane rows |
| libc loading "stitch" (`Main.lean` `loadLibc`: rename the dump onto the 12 metadata TUs — tags by name, functions by name, globals by position) | every libc-mode run: 32 m | LEAN-ONLY (the oracle loads `libc.co` directly) | MODERATE — exercised on every libc run, mis-stitch would fail loudly in most cases | exhaustive libc-mode runs: never gated |
| Multi-TU linking (`Core_linking` SHARED; per-TU fold, digests, supply threading in `Main.lean` SEAM) | user multi-TU agreement programs **8 m** (`tests/multi_tu` 2, CN multi-file dirs 4, uri 5 TUs, chvalid 2 TUs); tray 7 under the weaker `failure-class` projection; the 12 libc metadata TUs on every libc run | SHARED + SEAM | THIN (borderline MODERATE: the fold is also driven by every libc run) | `static` same-name symbols in two user TUs (only `multi_tu/basic` has `static`), cross-TU function pointers, extern arrays, tentative definitions (1 dir) |
| `--call` (`CerbCall.lean`, 320 lines) | `test_verify.sh`: 49 call points over 15 functions (tests/verify 28 rows / 8 fixtures, tests/corpus 21 / 7, m) vs the rendered oracle wrapper TU | LEAN-ONLY (oracle twin = wrapper TU) | MODERATE | integer arguments only (by design); pointer/struct parameters not callable |
| Address-space parameter (`--address-space-top`) | Tier A row 12: 18 cases + 14 selftest plants | SEAM + fork-only oracle flag | MODERATE — one discriminator, but the plants are thorough | — |
| Fuel parameter and exhaustion | `check_fuel_forms.sh` (81 workers), fuel plants, FUEL classifier selftest, `FuelExemplar` (28 theorems m) | SEAM + kernel | STRONG | — |
| SC WP0 receipt buffer (disabled by default) | Tier A row 13, kernel erasure laws | SEAM | STRONG within its (diagnostic) scope | — |
| CLI refusal of non-default semantics (`--concurrency`, `--switches…`) | **no lane witness** (grep of `scripts/` and `lean_frontend/test`: only `test_fuel_plant.sh` checks a positional-flag refusal) | SEAM (`refuseFlag`) | THIN — refusal present in code, unwitnessed | CONTRACT §4.1 requires every REFUSED area to have a witness |

## 2. Ranked THIN list (and borderline MODERATE)

Ranked by [AGENT] judgement of (chance a user hits it) × (chance a hand-written seam silently differs). "Cheapest
action" is a proposal for the operator, not a decision.

1. **libc breadth, and libc mode only ever `--first`** — 11 of 188 libc functions directly called by a libc-mode lane
   program; all 32 libc-mode agreement programs are single-trace against a random oracle trace; the libc stitch is
   Lean-only. *User hit:* `strcpy`, `strtol`, `qsort`, `sprintf`, `ctype.h`, … in any real program. *Action:*
   document in CONTRACT/SUPPORTED that "libc SUPPORTED" (D4) is by mechanism, with the measured breadth; add a small
   libc_exec battery over the commonest functions; add at least one exhaustive libc-mode row.
2. **`printf("%f")`** — 0 lane programs; `CerbFloat.formatFixed` is a hand-written exact-decimal reimplementation of
   glibc's `%.Nf`, the most arithmetic-heavy printer in the tree; only its 13 unit cases in `pp-test` check it. *User hit:* any program printing a double.
   *Action:* add the served-surface `p2_printf_f`/`p2_printf_f2` probes (they agree today) as immaculate rows; add
   ties/precision/negative-zero/inf cases. Cheap; no code change.
3. **`realloc` (4), `memcpy` (5), `memcmp` (1 value row)** — hand-written `CerbMem` routines. *User hit:* growing
   buffers, struct copies, byte compares with high bytes. *Action:* add immaculate rows (grow/shrink with data check,
   overlapping `memcpy` UB, `memcmp` sign on 0x80+ bytes, pointer-carrying `memcpy`).
4. **`snprintf`/`vsnprintf` (2), `errno` (1), `exit` edge codes / `atexit` (probes only)** — *User hit:* truncation
   return values, `strtol` error handling, exit status. *Action:* promote served-surface `p2_snprintf`,
   `p2_errno_basic`, `p2_exit_codes`, `p2_exit_256`, `p2_exit_atexit` to immaculate rows.
5. **printf conversions beyond plain `%d/%u/%s/%ld/%p`** — no width, precision, flags or `%c` in any agreement
   row, `%x` once (via `PRIxPTR`). Shared `Formatted` lowers divergence risk, but `%c` passes through `CerbDecode.encode_character_constant`
   and escaping. *Action:* promote `p2_printf_specs_ok`, `p2_printf_c_edge`, `p2_printf_s_nonul`.
6. **stdin and environment** — 0 rows. stdin now refuses (derived, not run); `getenv` is served by libc C code.
   *Action:* add one pinned stdin-refusal witness and one `getenv` row; correct CONTRACT §3's stdin row to "REFUSED
   (via D2)" once a run confirms the derivation.
7. **argv (5)** — *User hit:* non-ASCII arguments, where Lean's Unicode-scalar strings and OCaml's bytes may differ
   (unmeasured). *Action:* run one UTF-8 `--args` probe; pin the result either way (agreement row or refusal).
8. **User multi-TU programs (8)** — *User hit:* two TUs with the same `static` name, cross-TU function pointers.
   *Action:* add 3–4 `tests/multi_tu` cases.
9. **Non-batch CLI output** — exits 0 for every outcome, human format, never compared. *Action:* either refuse
   non-batch runs (make `--batch` mandatory) or state in README/CONTRACT that only `--batch` output is the compared
   interface.
10. **`--first` membership** — no proof or gate that its trace is one of the exhaustive set. *Action:* a small kernel
    lemma (`runND1Fuel` result ⊆ `runNDFuel` result) or a lane check on the exhaustive corpora; name `--first` as a
    projection in CONTRACT §2 (served-surface P2-1 already asked for this).
11. **CLI refusal witnesses** for `--concurrency`/`--switches`. *Action:* two plant lines in `test_fuel_plant.sh`-style
    (contract §4.1).
12. **Default-mode atomics / par (1 row)** — shared code, lower risk. *Action:* promote `p1_par`, `p1_at_store`,
    `p1_at_load` (served-surface recommendation 6).
13. **`any_bounded_int` (0)**, **`--pp-core` text**, **`--parse-core`** — not served semantics. *Action:* pin the
    mirrored crash (or make `bounded_integer` a `failwithI`, served-surface P3-1); document that `--pp-core`/
    `--parse-core` are diagnostics, and restate CONTRACT's `.core` row as "the runtime's own Core files".

Borderline MODERATE, leaning THIN (watch list): `va_*` (7 direct), unspecified/trap values (7 designed rows), `%p`
(2), function pointers (19 designed rows, but numeric identity refused/registered), UB-code breadth (unmeasured),
`--call` (integer-only).

## 3. Open items (need a run; not settled here)

- Whether C-level stdin reads now refuse (derived from code reading only; `getchar` → `read(0,…)` → `fs_read`).
- UTF-8 `--args` behaviour on both engines.
- How many exhaustive-lane programs actually have more than one execution (the exhaustive runner's real exercise).
- Which distinct UB codes the exec lanes' `UB_MATCH` rows exercise (baselines record only the class).
- Transitive libc coverage (which `runtime/libc/src` functions execute under the 32 libc-mode programs).
- Cabs constructor coverage of `CabsImport` across the corpora (needs the JSON, i.e. the oracle bridge).
- Seam-function dynamic coverage in general: every count here is a static proxy (a program that mentions `realloc`
  exercises `CerbMem.realloc`); no coverage instrumentation exists for the Lean executable.

## A. Method and evidence

All commands ran read-only in this worktree; the census script lived at `.tmp/count.py` (deleted before the commit;
its full text is §A.5 so every number can be regenerated). "Measured" (m) = printed by a command over committed
files. "Derived" (d) = my classification on top (filename heuristics, code reading, or a sum). Where a regex has a
known false positive it is named.

### A.1 Denominator (measured, census output verbatim)

The census enumerates each gating corpus with the owning lane's committed baseline status. Agreement =
`MATCH`/`UB_MATCH`, or `AGREE` for lanes with no per-row baseline whose bar is all-pass (bytes `.exec`, address
space, verify, uri, chvalid, speclab pinned gates). Immaculate `MATCH | L=CRASH` rows are counted as
`MATCH_BOTHCRASH` (matching failure, not served agreement); the multi-TU tray as `MATCH_TRAY` (weaker projection) —
both excluded from agreement. Tier C corpora are listed but excluded from `GATING_agree`.

```text
$ python3 .tmp/count.py   (verbatim; program lines)
minimal: total=113 agree=108 statuses={'MATCH': 90, 'UB_MATCH': 18, 'CERB_SKIP': 5}
coverage: total=212 agree=198 statuses={'MATCH': 182, 'CERB_SKIP': 13, 'UB_MATCH': 16, 'UNSUPPORTED': 1}
debug: total=90 agree=86 statuses={'UB_MATCH': 20, 'MATCH': 66, 'CERB_SKIP': 4}
float: total=93 agree=93 statuses={'MATCH': 93}
bytes: total=9 agree=9 statuses={'AGREE': 9}
immaculate: total=87 agree=60 statuses={'MATCH': 60, 'MATCH_BOTHCRASH': 11, 'ORACLE_CRASH': 5, 'DIFF': 11}
libc_exec: total=12 agree=12 statuses={'MATCH': 12}
multi_tu: total=2 agree=2 statuses={'MATCH': 2}
multi_tu_tray: total=7 agree=0 statuses={'MATCH_TRAY': 7}
address_space: total=6 agree=6 statuses={'AGREE': 6}
verify: total=41 agree=41 statuses={'AGREE': 41}
cn: total=213 agree=213 statuses={'MATCH': 207, 'UB_MATCH': 6}
uri: total=1 agree=1 statuses={'AGREE': 1}
chvalid: total=4 agree=4 statuses={'AGREE': 4}
csmith(TierC): total=1669 agree=1161 statuses={'MATCH': 1161, 'CERB_SKIP': 499, 'TIMEOUT': 9}
speclab: total=39 agree=39 statuses={'AGREE': 39}
ci(TierC): total=250 agree=132 statuses={'MATCH': 91, 'NOROW': 8, 'UB_MATCH': 41, 'CERB_SKIP': 110}
gating agreement programs by mode: {'nolibc-exh': 795, 'nolibc-first': 45, 'libc-first': 32} total 872
```

### A.2 Feature census (measured, verbatim)

Each cell is `programs whose comment-stripped source matches / of those, agreement rows`. `GATING_agree` sums the
agreement column over the non-Tier-C corpora; `libc_agree` is the libc-mode subset. A match means the program
*mentions* the construct (static proxy for exercising the seam), not that the run reached it.

```text
feature | minimal | coverage | debug | float | bytes | immaculate | libc_exec | multi_tu | multi_tu_tray | address_space | verify | cn | uri | chvalid | speclab | csmith(TierC) | ci(TierC) | GATING_agree | libc_agree
heap malloc/calloc/aligned_alloc | 2/0 | 11/10 | 0/0 | 0/0 | 0/0 | 10/7 | 3/3 | 0/0 | 0/0 | 1/1 | 1/1 | 1/1 | 0/0 | 0/0 | 16/16 | 0/0 | 1/1 | 39 | 5
free | 0/0 | 15/14 | 0/0 | 0/0 | 0/0 | 5/5 | 1/1 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 16/16 | 0/0 | 0/0 | 37 | 5
realloc | 0/0 | 2/2 | 0/0 | 0/0 | 0/0 | 2/2 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 4 | 0
memcpy/memmove | 0/0 | 2/2 | 0/0 | 0/0 | 0/0 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 5 | 3
memcmp | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 3/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 2 | 1
memset | 0/0 | 1/0 | 1/0 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1 | 1
(u)intptr_t | 2/0 | 3/2 | 0/0 | 0/0 | 0/0 | 10/8 | 1/1 | 0/0 | 0/0 | 1/1 | 0/0 | 5/5 | 0/0 | 0/0 | 0/0 | 0/0 | 2/2 | 17 | 5
funptr declarator | 1/1 | 5/4 | 1/1 | 1/1 | 0/0 | 5/2 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 6/3 | 9 | 0
union | 3/3 | 10/8 | 0/0 | 0/0 | 0/0 | 1/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 3/2 | 2/1 | 13 | 1
bit-field | 0/0 | 2/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1 | 0
_Alignas/_Alignof/offsetof | 0/0 | 3/3 | 0/0 | 0/0 | 0/0 | 6/5 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 2/0 | 9 | 1
float/double | 2/2 | 17/17 | 11/11 | 72/72 | 0/0 | 6/5 | 2/2 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 8/2 | 109 | 6
long double | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1 | 0
hex float literal | 0/0 | 1/1 | 0/0 | 23/23 | 0/0 | 1/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 24 | 0
_Bool | 3/3 | 7/7 | 0/0 | 0/0 | 0/0 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 2/2 | 15 | 1
_Atomic/stdatomic | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 4/3 | 1 | 0
goto | 1/1 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 2/2 | 0/0 | 0/0 | 0/0 | 656/215 | 12/8 | 6 | 0
switch | 2/2 | 2/2 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 5/5 | 0/0 | 0/0 | 5/5 | 0/0 | 2/1 | 15 | 0
variadic user fn / va_* | 0/0 | 5/5 | 1/1 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/0 | 7 | 1
char/string literal escapes | 4/4 | 0/0 | 0/0 | 0/0 | 0/0 | 4/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 7 | 2
wide/char16 literals | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0 | 0
_Generic | 0/0 | 2/2 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 3 | 0
printf | 0/0 | 4/4 | 0/0 | 0/0 | 0/0 | 8/6 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 4/4 | 0/0 | 382/119 | 13/13 | 18 | 10
snprintf/sprintf/vsnprintf | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/0 | 2/2 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 2 | 2
fprintf/vprintf/vfprintf | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 2/2 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 2 | 2
puts/putchar/fputs | 0/0 | 1/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1 | 1
exit/abort/atexit/_Exit | 2/0 | 1/0 | 6/5 | 0/0 | 0/0 | 1/1 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 7 | 2
errno | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1 | 0
__builtin_ffs/ctz/clz/bswap/popcount | 0/0 | 5/5 | 0/0 | 0/0 | 0/0 | 5/4 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 5/5 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 14 | 0
stdin read (getchar/scanf/fgets/read) | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 2/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0 | 0
getenv | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0 | 0
main(argc, argv) | 2/2 | 0/0 | 0/0 | 0/0 | 0/0 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1291/847 | 1/1 | 5 | 0
file ops (fopen/open/stat/...) | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 6/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0 | 0
strto*/ato* | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1/1 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1 | 1
string.h (strlen/strcmp/strcpy/...) | 0/0 | 1/0 | 1/0 | 0/0 | 0/0 | 0/0 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 1291/847 | 0/0 | 3 | 3
any_bounded_int | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0 | 0
setjmp/signal | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0 | 0
printf conversions (gating, agree rows):
  F {'uri': 1, 'total': 1}
  d {'coverage': 2, 'immaculate': 4, 'libc_exec': 4, 'uri': 1, 'total': 11}
  f {'uri': 1, 'total': 1}
  float-conv {'uri': 1, 'total': 1}
  len:l {'immaculate': 2, 'libc_exec': 1, 'total': 3}
  len:ll {'libc_exec': 1, 'total': 1}
  p {'immaculate': 2, 'total': 2}
  s {'coverage': 1, 'immaculate': 1, 'libc_exec': 2, 'uri': 1, 'total': 5}
  u {'libc_exec': 1, 'uri': 1, 'chvalid': 4, 'total': 6}
libc src function definitions (derived by regex): 188
libc-mode gating programs: 43 agree: 32
distinct libc fns called directly by libc-mode agreement programs: 11 {'abort': 1, 'calloc': 1, 'exit': 1, 'fprintf': 2, 'memset': 1, 'printf': 10, 'puts': 1, 'snprintf': 1, 'strlen': 3, 'strtod': 1, 'vsnprintf': 1}
... by any libc-mode program: 11
```

### A.3 Known regex artefacts (derived, by inspecting the hits)

- `bit-field`: of the 2 coverage hits, `expr-003-nested-ternary.c` is a false positive (`a ? b : 3;`); the real
  bit-field row `expr-007-bitfield-ops.c` is `CERB_SKIP` (oracle-side). So the measured bit-field agreement count is 0.
- printf conversions `F`/`f`/`float-conv` for `uri` are false positives: they come from percent-encoded URI test
  strings (`"/a%2Fb%2fc"`), not format strings; the targeted printf-with-float-conversion grep in §A.4 is the
  authoritative `%f` count (0 everywhere).
- `stdin read`: the 2 immaculate hits are filesystem rows mentioning `read(` on a file fd (both refused DIFF rows); no
  program reads fd 0.
- `main(argc, argv)` and `string.h` in csmith (1,291) are csmith's generated `main(int argc, char *argv[])` and its
  `strcmp(argv[1], "1")` test; Tier C only, not counted.
- The libc definition count (188) is a regex over `runtime/libc/src/*.c` function heads, so it is approximate
  (derived); the direct-call count intersects called identifiers with it.
- Filename-based "designed rows" counts in §1 (e.g. 19 pointer-provenance rows, 7 unspecified-value rows, 29 unseq
  rows) come from `find … -name '*.c' | grep -Ei '<pattern>'` over minimal/coverage/debug/immaculate/libc_exec/bytes
  and are derived (a filename is a claim about intent, not about what runs).

### A.4 Supplementary measurements (verbatim)

The last block lists every format-bearing string literal in the printf-bearing gated programs; it includes
non-format strings (URI test inputs such as `"%zz"`, `"%41"`), which are not conversions. `"%c"` is the R2 register
row `g5-escape-roundtrip` (DIFF, not agreement); `"Addresses: p=%"` / `" q=%"` are the two halves around `PRIxPTR`.

```text
$ grep -v "^#" scripts/gcc_oracle_baseline.txt | awk '{print $2}' | sort | uniq -c | sort -rn
   1917 AGREE
     47 SKIP_UB
     13 SKIP_LEAN_FAIL
     12 SKIP_LEAN_CRASH
     11 TRIAGED_ADDR
     11 SKIP_LEAN_TIMEOUT
      1 TRIAGED_UB
      1 SKIP_GCC_STDOUT
      1 SKIP_GCC_COMPILE
$ ... AGREE rows by corpus prefix
   1654 csmith
     57 tests/debug
     93 tests/float
     23 tests/immaculate
     90 tests/minimal
$ grep -cE "^\s*\|\s*UB[0-9]" frontend/model/undefined.lem
365
$ immaculate agreeing UB rows / distinct codes
12
10
$ lem target_reps per hand-written Lean module (frontend/)
     93 CerbMem
     43 CerbFS
     38 CerbPP
     23 LemUnsupported
     23 CerbGlobal
     14 CerbUtils
     11 CerbFloat
     11 CerberusImpl
     10 CerbLocation
      5 CerbDebug
      3 CerberusFresh
      3 CerbDecode
      1 CerbTags
      1 CerbND
      1 CerbConcurrency
$ grep -oE "Merr[A-Za-z]+" lean_frontend/CerbMem.lean | sort | uniq -c   (kinds, sites)
14
93
$ --call rows: tests/verify/expectations.txt (rows, fixtures); tests/corpus/expectations.txt (rows, fixtures)
28
8
21
7
$ CN multi-file baseline rows / dirs
10
accesses_on_spec multifile mutual_rec tree16 
$ speclab pinned harnesses / with malloc-free
39
16
$ lanes pinning --concurrency / --switches refusal
0
$ printf with a float conversion, every corpus (targeted regex)
minimal 0
coverage 0
debug 0
float 0
bytes 0
immaculate 0
libc_exec 0
multi_tu 0
multi_tu_tray 0
address_space 0
verify 0
libxml2 0
speclab 0
ci 0
csmith 0
cn 0
lean_frontend/corpus 0
$ every format-bearing string literal in the libc/printf-bearing gated programs
"/a%2Fb%2fc"
"a/b/../c?x=%41"
"Addresses: p=%"
"Addresses: p=%p\n"
"%c"
"chvalid_battery n=%u h=%u\n"
"%d %d %d "
"%d %d %d %d "
"%d %d %d %d %d %d "
"%d %d %d\n"
"%d %d\n"
"%d\n"
"http://%zz/"
"j=%d &j=%p\n"
"%llu\n"
"loc=%ld\n"
"%p\n"
"(p==q) = %s\n"
" q=%"
"s1=%ld c1=%ld i1=%ld p1=%ld l1=%ld optind=%ld\n"
"s1=%ld c1=%ld i1=%ld p1=%ld\n"
" scheme=%s server=%s port=%d path=%s query_raw=%s fragment=%s"
"%s\n"
"uri_harness n=%u h=%u\n"
"uri %u rc=%d"
"v=%d s=%s"
"x=%d *p=%d *q=%d\n"
"x=%d y=%s"
```

Other measured facts cited in §1, with their commands:

- libc-mode reads: `runtime/libc/src/stdio.c:184-193` (`__stdio_read` → `read(f->fd, …)`), `:798-800` (`getchar` →
  `do_getc(stdin)`), `frontend/model/driver.lem:366-367` (`FS_READ` → `Fs.fs_read`), `lean_frontend/CerbFS.lean`
  (`fs_read` = `failwithI (fsRefusal …)`) — read, not run.
- libc `printf` path: `runtime/libc/src/stdio.c:658` (`printf`), `:708-712` (`vfprintf` → `__builtin_vprintf` with the
  `va_list`).
- Lanes using `--first`: `grep -n -- '--first' scripts/test_{libc_exec,immaculate,libxml2,libxml2_uri,gcc_oracle}.sh`
  (libc_exec :104, immaculate :168, libxml2 :214, libxml2_uri :193/:221, gcc_oracle :439 csmith tier); exhaustive:
  test_exec.sh :443, test_multi_tu.sh :150, test_cn_coverage.sh :231, test_verify.sh :76-77, test_address_space.sh :126.
- `test_core.sh` checks parse success only: `scripts/test_core.sh:113` runs `--parse-core`; `Main.lean` `--parse-core`
  branch prints declaration counts and exits.
- Non-batch output: `lean_frontend/Main.lean` non-batch branch ends `return 0`; its memory-error printer has
  `| _ => IO.println s!"  result: Killed (memory error)"`.
- Multi-TU `static` usage: `tests/multi_tu/basic` 11 `static` lines; `tests/multi_tu/tentative` and the three CN
  multi-file dirs with `.c` files 0 (grep -c).
- Seam sizes: `wc -l lean_frontend/*.lean` (CerbMem 3,237; CoreParser 2,990; Main 1,458; CabsImport 829; CerbFloat 439;
  CerbND 418; CerberusImpl 324; CerbCall 320; CerbDecode 196; CerbUtils 172).
- `formatFixed` unit cases: `lean_frontend/test/Unit/PPTest.lean` `ffCases` (12 `(precision, value, expected)` rows from an
  OCaml 5.4.0 `Printf.sprintf "%.*f"` transcript) + one `%f inf` check (`:146`); `sfCases` (18 rows) cover
  `string_of_float`.
- Theorem counts quoted in §1: `grep -c theorem` over `lean_frontend/CerbNDFuelProofs.lean` (30),
  `test/Unit/RunDigestTest.lean` (14), `test/Unit/FuelExemplar.lean` (28), `test/Unit/MemoryAccessProofs.lean` (5).

Where I could not measure: see §3. In addition, I did not re-run any lane, so every "agreement" count is the
committed baseline's claim at `23ee2d23f`, re-verified only by the D2 full-ladder record
(`docs/2026-09-28_cerbfs-refuse-all-record.md`: `full: passed; 40/40 selected commands completed successfully.` on
`835c230b1`) and, for the later function-pointer commits, by the Tier A blast-radius claim in
`docs/2026-09-28_funptr-int-refusal-record.md` (its Tier B run is stated as pending "at the enforcement claim point") —
not by me.

### A.5 The census script (verbatim; run from the worktree root as `.tmp/count.py`)

```python
#!/usr/bin/env python3
"""Feature-exercise census over the gating corpora (test-depth map 2026-09-28).
Counts programs whose comment-stripped source matches a feature regex, split by
whether the owning lane's committed baseline records agreement (MATCH/UB_MATCH)."""
import re, os, sys, glob, json, collections
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CN = '/home/dev/projects/cerberus-lean-proj/deps/cn/tests/cn'
def strip(src):
    src = re.sub(r'/\*.*?\*/', ' ', src, flags=re.S)
    src = re.sub(r'//[^\n]*', ' ', src)
    return src
def base(path):
    d = {}
    for l in open(path, errors='replace'):
        if l.startswith('#') or not l.strip(): continue
        p = l.split()
        d[p[0]] = (p[1], l.strip())
    return d
progs = []  # (corpus, mode, id, [files], status, agree)
def add(corpus, mode, pid, files, status):
    agree = status in ('MATCH', 'UB_MATCH', 'AGREE')
    progs.append(dict(corpus=corpus, mode=mode, id=pid, files=files, status=status, agree=agree))
for corpus, bl in [('minimal','exec_baseline'),('coverage','exec_coverage_baseline'),('debug','exec_debug_baseline'),('float','exec_float_baseline')]:
    b = base(f'{R}/scripts/{bl}.txt')
    for f in sorted(glob.glob(f'{R}/tests/{corpus}/**/*.c', recursive=True)):
        k = os.path.basename(f)
        add(corpus, 'nolibc-exh', k, [f], b.get(k, ('NOROW',))[0])
for f in sorted(glob.glob(f'{R}/tests/bytes/*.exec.c')):
    add('bytes', 'nolibc-exh(.exec ref)', os.path.basename(f), [f], 'AGREE')
ib = base(f'{R}/tests/immaculate/baseline.txt')
for sub, mode in [('nolibc','nolibc-first'),('libc','libc-first'),('argv','nolibc-first+args')]:
    for f in sorted(glob.glob(f'{R}/tests/immaculate/{sub}/*.c')):
        stem = os.path.basename(f)[:-2]
        rows = [(k,v) for k,v in ib.items() if k == stem or k.startswith(stem + '-args')]
        if not rows: add('immaculate', mode, stem, [f], 'NOROW'); continue
        for k,(st,line) in rows:
            s = st
            if st == 'MATCH' and 'L=CRASH' in line: s = 'MATCH_BOTHCRASH'
            add('immaculate', mode, k, [f], s if s!='MATCH_BOTHCRASH' else 'MATCH_BOTHCRASH')
lb = base(f'{R}/tests/libc_exec/baseline.txt')
for f in sorted(glob.glob(f'{R}/tests/libc_exec/*.c')):
    stem = os.path.basename(f)[:-2]; add('libc_exec', 'libc-first', stem, [f], lb.get(stem, ('NOROW',))[0])
for d in sorted(glob.glob(f'{R}/tests/multi_tu/*/')):
    add('multi_tu', 'nolibc-exh', os.path.basename(d.rstrip('/')), sorted(glob.glob(d+'*.c')), 'MATCH')
for d in sorted(glob.glob(f'{R}/tests/multi_tu_tray/*/')):
    add('multi_tu_tray', 'nolibc-exh(failure-class)', os.path.basename(d.rstrip('/')), sorted(glob.glob(d+'*.c')), 'MATCH_TRAY')
for f in sorted(glob.glob(f'{R}/tests/address_space/*.c')):
    add('address_space', 'nolibc-exh(tops)', os.path.basename(f), [f], 'AGREE')
for f in sorted(glob.glob(f'{R}/tests/verify/*.c')) + sorted(glob.glob(f'{R}/lean_frontend/corpus/*.c')):
    add('verify', 'nolibc-exh+call', os.path.basename(f), [f], 'AGREE')
cb = base(f'{R}/tests/cn_coverage/baseline.txt')
for k,(st,_) in cb.items():
    f = f'{CN}/{k}'
    add('cn', 'nolibc-exh', k, [f] if os.path.exists(f) else [], st)
add('uri', 'libc-first', 'uri_harness(+4 libxml2 TUs)', [f'{R}/tests/libxml2/uri_harness.c'], 'AGREE')
for f in sorted(glob.glob(f'{R}/tests/libxml2/battery/*.c')):
    add('chvalid', 'nolibc-first', os.path.basename(f), [f], 'AGREE')
csb = base(f'{R}/scripts/exec_csmith_corpus_baseline.txt')
pref = {'sa':'small_arrays','sia':'small_int_arith','smx':'small_mix'}
for k,(st,_) in csb.items():
    m = re.match(r'(sa|sia|smx)_(csmith_\d+\.c)', k)
    f = f'{R}/tests/csmith/{pref[m.group(1)]}/{m.group(2)}' if m else ''
    add('csmith(TierC)', 'nolibc-exh', k, [f] if os.path.exists(f) else [], st)
for f in sorted(glob.glob(f'{R}/tests/speclab/*.c')):
    add('speclab', 'nolibc-exh(pinned)', os.path.basename(f), [f], 'AGREE')
cib = base(f'{R}/scripts/exec_ci_baseline.txt')
for f in sorted(glob.glob(f'{R}/tests/ci/*.c')):
    k = os.path.basename(f); add('ci(TierC)', 'nolibc-exh', k, [f], cib.get(k, ('NOROW',))[0])

FEAT = collections.OrderedDict([
 ('heap malloc/calloc/aligned_alloc', r'\b(malloc|calloc|aligned_alloc)\s*\('),
 ('free', r'\bfree\s*\('),
 ('realloc', r'\brealloc\s*\('),
 ('memcpy/memmove', r'\b(memcpy|memmove)\s*\('),
 ('memcmp', r'\bmemcmp\s*\('),
 ('memset', r'\bmemset\s*\('),
 ('(u)intptr_t', r'\bu?intptr_t\b'),
 ('funptr declarator', r'\(\s*\*\s*\w*\s*\)\s*\('),
 ('union', r'\bunion\b'),
 ('bit-field', r'\b(int|unsigned|signed|_Bool|char|short|long)\b[^;{}()]*\b\w+\s*:\s*\d+\s*[;,]'),
 ('_Alignas/_Alignof/offsetof', r'\b(_Alignas|_Alignof|alignof|offsetof)\b'),
 ('float/double', r'\b(float|double)\b'),
 ('long double', r'\blong\s+double\b'),
 ('hex float literal', r'\b0[xX][0-9a-fA-F]*\.?[0-9a-fA-F]*[pP][+-]?\d'),
 ('_Bool', r'\b(_Bool|bool)\b'),
 ('_Atomic/stdatomic', r'\b_Atomic\b|stdatomic'),
 ('goto', r'\bgoto\b'),
 ('switch', r'\bswitch\s*\('),
 ('variadic user fn / va_*', r'\bva_(start|arg|end|copy)\b'),
 ('char/string literal escapes', r"'\\[0-7xX]|\"[^\"\n]*\\[0-7xX]"),
 ('wide/char16 literals', r'\b[LuU]\'|\b[LuU]8?"'),
 ('_Generic', r'\b_Generic\b'),
 ('printf', r'\bprintf\s*\('),
 ('snprintf/sprintf/vsnprintf', r'\b(v?snprintf|sprintf)\s*\('),
 ('fprintf/vprintf/vfprintf', r'\b(fprintf|vprintf|vfprintf)\s*\('),
 ('puts/putchar/fputs', r'\b(puts|putchar|fputs|fputc|putc)\s*\('),
 ('exit/abort/atexit/_Exit', r'\b(exit|abort|atexit|_Exit)\s*\('),
 ('errno', r'\berrno\b'),
 ('__builtin_ffs/ctz/clz/bswap/popcount', r'__builtin_(ffs|ctz|clz|bswap|popcount)'),
 ('stdin read (getchar/scanf/fgets/read)', r'\b(getchar|scanf|fgets|fgetc|getc|fread|read)\s*\(|\bstdin\b'),
 ('getenv', r'\bgetenv\s*\('),
 ('main(argc, argv)', r'\bmain\s*\(\s*int\s+\w+\s*,'),
 ('file ops (fopen/open/stat/...)', r'\b(fopen|open|close|stat|lstat|mkdir|unlink|rename|opendir|lseek|truncate)\s*\('),
 ('strto*/ato*', r'\b(strto[ld]|strtou?ll?|strtod|strtof|atoi|atol|atof)\s*\('),
 ('string.h (strlen/strcmp/strcpy/...)', r'\b(strlen|strcmp|strncmp|strcpy|strncpy|strcat|strchr|strstr)\s*\('),
 ('any_bounded_int', r'any_bounded_int'),
 ('setjmp/signal', r'\b(setjmp|longjmp|signal|raise)\s*\('),
])
FMT = r'%[-+ #0]*(\d+|\*)?(\.(\d+|\*))?(hh|h|ll|l|L|z|j|t)?([diouxXfFeEgGaAcspn%])'
def conv_set(src):
    s = set()
    for lit in re.findall(r'"((?:[^"\\\n]|\\.)*)"', src):
        for m in re.finditer(FMT, lit):
            c = m.group(5); lm = m.group(4) or ''
            s.add(c)
            if c in 'fFeEgGaA': s.add('float-conv')
            if lm: s.add('len:'+lm)
    return s
text = {}
for p in progs:
    t = ''
    for f in p['files']:
        try: t += strip(open(f, errors='replace').read())
        except Exception: pass
    p['src'] = t
corpora = list(dict.fromkeys(p['corpus'] for p in progs))
out = collections.OrderedDict()
out['programs'] = {c: dict(total=sum(1 for p in progs if p['corpus']==c), agree=sum(1 for p in progs if p['corpus']==c and p['agree']), nosrc=sum(1 for p in progs if p['corpus']==c and not p['src']), statuses=dict(collections.Counter(p['status'] for p in progs if p['corpus']==c))) for c in corpora}
out['features'] = {}
GATING = [c for c in corpora if 'TierC' not in c]
for name, rx in FEAT.items():
    r = re.compile(rx)
    row = {}
    for c in corpora:
        hit = [p for p in progs if p['corpus']==c and r.search(p['src'])]
        row[c] = [len(hit), sum(1 for p in hit if p['agree'])]
    row['GATING_agree'] = sum(row[c][1] for c in GATING)
    row['GATING_libc_agree'] = sum(1 for p in progs if p['corpus'] in GATING and p['mode'].startswith('libc') and p['agree'] and r.search(p['src']))
    out['features'][name] = row
conv = collections.Counter(); convg = collections.defaultdict(lambda: collections.Counter())
for p in progs:
    if p['corpus'] in GATING and p['agree']:
        for c in conv_set(p['src']): convg[c][p['corpus']] += 1
out['printf_conversions_gating_agree'] = {k: dict(v, total=sum(v.values())) for k,v in sorted(convg.items())}
json.dump(out, open(os.path.join(R, '.tmp/census.json'), 'w'), indent=1)
for c,v in out['programs'].items(): print(f"{c}: total={v['total']} agree={v['agree']} statuses={v['statuses']}")
cs = GATING + [c for c in corpora if 'TierC' in c]
print('feature | ' + ' | '.join(cs) + ' | GATING_agree | libc_agree')
for n,row in out['features'].items():
    print(n + ' | ' + ' | '.join(f'{row[c][0]}/{row[c][1]}' for c in cs) + f" | {row['GATING_agree']} | {row['GATING_libc_agree']}")
modes=collections.Counter((p['mode'].split('(')[0].split('+')[0]) for p in progs if p['corpus'] in GATING and p['agree'])
print('gating agreement programs by mode:', dict(modes), 'total', sum(modes.values()))
print('printf conversions (gating, agree rows):')
for k,v in out['printf_conversions_gating_agree'].items(): print(' ', k, dict(v))

# ---- libc function census (libc-mode agreement programs) ----
defs = set()
for f in glob.glob(f'{R}/runtime/libc/src/*.c'):
    s = strip(open(f, errors='replace').read())
    for m in re.finditer(r'^[A-Za-z_][\w \*]*?\b([a-z_][a-z0-9_]*)\s*\([^;{]*\)\s*\{', s, flags=re.M):
        defs.add(m.group(1))
defs -= {'if','while','for','switch','return','sizeof'}
calls = collections.Counter(); callsall = collections.Counter()
for p in progs:
    if p['corpus'] in GATING and p['mode'].startswith('libc'):
        names = set(re.findall(r'\b([a-z_][a-z0-9_]*)\s*\(', p['src'])) & defs
        for n in names:
            callsall[n] += 1
            if p['agree']: calls[n] += 1
print('libc src function definitions (derived by regex):', len(defs))
print('libc-mode gating programs:', sum(1 for p in progs if p['corpus'] in GATING and p['mode'].startswith('libc')), 'agree:', sum(1 for p in progs if p['corpus'] in GATING and p['mode'].startswith('libc') and p['agree']))
print('distinct libc fns called directly by libc-mode agreement programs:', len(calls), dict(sorted(calls.items())))
print('... by any libc-mode program:', len(callsall))
```
