# Pre-merge review: fix/macro-type-ranks (ab6295a01, four commits over a126c9f39)

Reviewer: fresh, independent [AGENT 2026-11-04, reviewer]. Budget ~1 h. Worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/macro-type-ranks`; merge-base upstream
`c3ff8c53f`; pristine oracle `deps/cerberus-upstream/_build/default/backend/driver/main.exe`; gcc 13.3.0 the referee.
Nothing tracked was edited, no build/lane/release run, no git state changed. Scratch: this directory
(`probes/`, `out/`, `patch/`, `run_probe.sh`, `sample_check.sh`).

## Verdict

**MERGEABLE WITH FIXES** (documentation-only fixes; no code, pin, baseline or register change needed).

The Lem change is exactly the standard's rule (a typedef'd/enum type has the rank of the type it aliases, C17
6.3.1.1#1, 7.19#2, 6.7.2.2#4), nothing more: both engines now agree with gcc byte for byte on every value and every
`_Generic` type code I probed, including cases the slice's own witness does not cover (macro type against macro type;
self-referential enumerator definitions; pointer differences against `size_t`; shifts; mixed `?:`). The CHERI carve-out
is observably exact (the elaborated Core under `--switches=CHERI` is identical to pristine's on four probes). The loud
catch-all is unreachable outside CHERI (`Ptraddr_t` errors earlier with "ptraddr_t is CHERI-specific" on all three
engines; `__cerbty_int128_t` crashes earlier in the alias table). The two libc bug attributions for 015/016 are right
and verified against pristine and gcc. The register rows, baselines, manifest rows and pins are what the record says.

Two factual errors in the prose must be fixed before the filing is sent and before the consumer reads its note:
(P2-1) `strspn` is named as a victim of the narrowing in the upstream filing, CONTRACT D14, SUPPORTED, the record and
both consumer notes, but the shipped `strspn` uses `*c && BITOP(...)`, and `&&` is not elaborated through the usual
arithmetic conversions — pristine's `strspn` already matched gcc (measured below); (P2-2) the cerberus-caesium consumer
note says the Ail typing is unchanged and only the Core moved; the Ail type of every binary expression with a
`ptrdiff_t`, `wchar_t`, `intmax_t` or enum operand against a standard type DID change (to the standard's) — measured
with `_Generic`.

## Scope and what I ran

Read: the four commit messages; `git diff a126c9f39..ab6295a01` (the Lem, the witness script and corpus, the manifest,
the register, the libc pins and dumps, the baselines/dispositions, CONTRACT/VALIDATION/SUPPORTED/TODO/LADDER/INDEX, the
survey record, the migration tsv, the record, the charter, tray 20, both consumer notes); the post-fix
`frontend/model/ail/ailTypesAux.lem` (rank functions, `le_integer_range`, `integer_promotion`,
`usual_arithmetic_integer_*`), `frontend/model/implementation.lem`, `ocaml_frontend/ocaml_implementation.ml` (alias
table, `is_signed_ity`, `register_enum`), `lean_frontend/CerberusImpl.lean` (the Lean alias table),
`lean_frontend/generated/AilTypesAux.lean` (the generated rank functions), `frontend/model/translation.lem`
(`usual_arithmetic_conversion_aux` :1528-1591, the `!` arm :1668), `frontend/model/builtins.lem`,
`frontend/model/ctype.lem:402-407`, `runtime/libc/include/stddef.h`, `runtime/libc/src/string.c` (strcspn :120, strspn
:159, twoway_strstr :212-265), `lem-lean/lean-lib/LemLib.lean:225` (`failwithI` = `panic!`), the pristine
`ailTypesAux.lem` and `translation.lem` at the cited lines, `scripts/check_failure_reach.sh` header.

Run (all under `scripts/ce`; the fork oracle `--exec --batch --nolibc`, pristine likewise with its own `--runtime`,
Lean from the fork oracle's `--cabs-json` under `LEAN_ABORT_ON_PANIC=1`, gcc `-std=c11 -w -O0`):

```
cd /home/dev/projects/cerberus-lean-proj/.tmp/review-ranks
./run_probe.sh probes/r01_sizet_int_edges.c      # size_t vs int/unsigned/_Bool/char/short/long/long long/ull, op=, ?:, switch, !
./run_probe.sh probes/r02_macro_vs_macro.c       # size_t/ptrdiff_t/intptr_t/uintptr_t/intmax_t/uintmax_t/wchar_t pairwise (no witness covers this)
./run_probe.sh probes/r03_ail_typing_generic.c   # _Generic codes of i+d, w+l, eu+ul, es+i, +w, ~w, ?: mixes (the Ail typing)
./run_probe.sh probes/r04_enum_defs.c            # self-referential enumerators, switch on enum, enum _Generic
./run_probe.sh probes/r05_wchar_unsigned_partners.c
./run_probe.sh probes/r06_ptraddr.c              # __cerbty_ptraddr_t outside CHERI
./run_probe.sh probes/r07_int128.c               # __cerbty_int128_t
./run_probe.sh probes/r09_direct_cerbty.c        # __cerbty_int8_t/uint16_t/int64_t/uint32_t/intmax_t/uintptr_t
./run_probe.sh probes/r10_long_long_pairs.c      # the two new long long rows; enum pairs; _Bool+char
./run_probe.sh probes/r11_std_rule_misc.c        # shifts, pointer differences vs size_t, ?: with enum/wchar_t, sizeof
./run_probe.sh <worktree>/tests/noodle-probes/int/int_size_t_uac_rank.c
./run_probe.sh <worktree>/tests/parity-probes/uncertainty/E-wchar_t/wt-06-sizeof-signedness.c
# libc mode (fork and pristine oracles with their own --runtime, no --nolibc; gcc):
probes/r08_strspn_libc.c ; probes/r08b_strspn_only_libc.c
# the witness pins, sampled (gcc vs expected.txt; pristine binary vs pristine.txt; fork and Lean vs expected.txt):
./sample_check.sh dense_size_t_pos dense_size_t_bneg dense_ptrdiff_t_aneg dense_wchar_t_bneg dense_enumS_aneg dense_enumU_pos dense_s_int8_pos dense_u_least64_pos dense_intptr_t_bneg promo_wchar_t promo_enumU audit_rank_ptrdiff_unsigned audit_rank_wchar p_enum_int st-03-generic st-09-rank-long-longlong tray20_int_size_t_uac_rank consumer_combined residual_size_t_llong_typing
# sweeps: tests/libc_exec/*.c (41 files) fork vs pristine in libc batch mode; tests/{minimal,coverage,debug} files
# mentioning size_t/ptrdiff_t/wchar_t/enum (12 files) fork vs pristine nolibc
# CHERI: --exec under --switches=CHERI (both oracles assert in impl_mem.ml, cannot execute) and --pp=core under
# --switches=CHERI vs default, fork vs pristine, symbols normalised, on r01/r02/r03/r10
# the filing's patch: extracted from tray 20, `patch -p1 --dry-run` against a copy of pristine's ailTypesAux.lem
# census: all_values_representable_in pairs in the old and new tests/libc/libc.core; the libc.core diff by shape
```

Key measurements (verbatim stdout, gcc first):

- r01: gcc `4294967300 18446744069414584315 4294967300 0 0 0 1 8589934596 8589934596 1 4294967302 4294967300 0 4294967299 0 4294967300 0 4294967300 0 4294967302 1|1 18446744069414584314 18446744073709551615 4294967301 0 1 4294967300 4294967302 4294967301 10 0 5 4294967304 4294967301 18446744073709551615 1 0|sw1 0 1 2147483650`; fork and Lean identical; pristine `4294967300 21474836475 4 0 0 0 1 8589934596 4294967300 0 6 …`.
- r02 (macro vs macro): gcc `4294967300 4294967300 0 0 4294967302 10 4294967296 0 1 18446744052234715111 10 4294967300 0 4294967302 10 2 0 18446744073709551613 10 4294967304 1 4294967298 10 2 0 18446744073709551613 9 4294967296 0 10 4294967300 0 10`; fork and Lean identical; pristine `Undefined {ub: "UB036_exceptional_condition", … loc: "<13:50--13:57>"}`.
- r03 (Ail typing via `_Generic`): gcc `9 9 7 7 7 7 10 7 8 7 9 9 7 / 7 7 7 7 8`; fork and Lean identical; pristine `7 9 7 7 7 7 8 7 8 7 9 7 7 / 7 7 7 7 7` (so `i + d` was typed `int`, now `long`; `eu + ul` was `unsigned`, now `unsigned long`; `w + l` was `int`, now `long`; `eu ? es : eu` was `int`, now `unsigned`).
- r04, r05, r09, r10, r11: fork = Lean = gcc byte for byte (r09 has no gcc: `__cerbty_*` spellings; fork = Lean `7 7 9 8 10 9 7 7 0 4294967293 0 1 0`, checked by hand against the standard); pristine differs on r05 (false UB036), r10 (`T(e + s)` 7), r11 (`(q - p) < n` 1, `d < n` 1, two typing codes).
- r06: all three engines `ptraddr_t is CHERI-specific` (oracle rc 125, Lean rc 134). r07: all three crash in the alias table (`Option.get` / `CerberusImpl.aliasMissing`).
- r08b (libc mode): gcc `9 9 5 16 16 21 16`; fork `9 9 5 16 16 21 16`; pristine `9 9 5 17 16 21 17` — the first three are `strspn` (unchanged, right on pristine), then `strcspn(h,"yx")` 17→16, `strcspn(h,"xy")` 16 (right by luck), `strcspn(h,"AB")` 21, `strpbrk(h,"yx")-h` 17→16. r08 with `strstr(h,"abcde")`: pristine `UB_CERB002a_out_of_bound_load … <265:22--265:26>`, fork `… 10` = gcc.
- sample_check: 19 programs — `gcc=pin | fork=pin | lean=pin | pristine=pristine.txt` on every row; 13 MOVED, 6 same; the declared residual pinned to the fork (`10 10 9 9 9`, gcc `12 12 10 11 12`) as its header says.
- libc_exec sweep: `41 files, 2 differ (fork vs pristine, libc batch)` — 015 (`… 15 16` vs `… 15 17`) and 016 (`Specified(10)` vs the UB at 265). nolibc spot sweep: `12 files, 2 differ` — `minimal/112`, `minimal/113` (pre-existing allocator rows already in the register, lines 23/41; not this slice).
- CHERI `--pp=core`, fork vs pristine, diff lines: r01 0 (default 351), r02 0 (default 174), r03 0 (default 8), r10 0 (default 2); `all_values_representable_in` count equal under CHERI (72/2/34/0).
- The filing's patch: `patch -p1 --dry-run` against pristine `c3ff8c53f` → `checking file frontend/model/ail/ailTypesAux.lem`, rc 0, no offset/fuzz. Cited lines (:455-457, :459-541, :527-529; translation.lem :1414-1477, :1466-1472; :673-722, :676) all check at pristine.
- libc.core census: old `all_values_representable_in('size_t','signed int')` 61 lines, `('size_t','ptrdiff_t')` 10, `('size_t','signed long')` 6; new: 0 of any pair. Diff-by-shape: every removed hunk is the conditional, every added line a `conv_int('size_t', …)`.
- float-literal register: after stripping line numbers every row pairs off; only the header comment is new.

## Findings

### P1 — none.

### P2-1. `strspn` is wrongly named as a victim of the narrowing (filing, D14, SUPPORTED, record, consumer notes)

- Where: `lean_frontend/docs/upstream-tray/20-size-t-integer-rank-uac.md:1` (title), `:98-100`
  ("musl's `strcspn`/`strspn`/`strpbrk` build their byte set with `if (!BITOP(byteset, *c, |=)) break;`"), `:114-116`
  ("string searching with a multi-character set (`strcspn`, `strspn`, `strpbrk`) returns the wrong index");
  `lean_frontend/CONTRACT.md:330` ("`strcspn`/`strspn`/`strpbrk` kept only the first character of their set");
  `lean_frontend/SUPPORTED.md` Domain row ("the shipped libc's `strcspn`/`strspn`/`strpbrk`/two-way `strstr` behave as
  glibc's" — implies a move); `lean_frontend/docs/2026-11-04_macro-type-ranks-record.md:223` (F6) and `:282`
  ("`strspn`'s `for (; *c && BITOP(…, |=); c++)` likewise");
  `docs/2026-11-04_consumer-note-cerberus-caesium-macro-type-ranks.md:41,68`;
  `docs/2026-11-04_consumer-note-cerberus-sl-macro-type-ranks.md:19`.
- Claim: `strspn` kept only the first character of its set before the fix.
- Evidence: the shipped `runtime/libc/src/string.c:170` is `for (; *c && BITOP(byteset, *(unsigned char *)c, |=); c++);`
  — the `&&` form, not the `!` form (`strcspn` :129 is the `if (!BITOP(...)) break;` form). `&&` is not elaborated through
  the usual arithmetic conversions (the record's own §1 row shows `v ? 1 : 0` and `w && 1` right where `!v` was wrong).
  Measured on pristine in libc mode (r08b): `strspn(h,"abc")`, `strspn(h,"cba")`, `strspn("xyzzyabc","zyx")` = `9 9 5` =
  gcc, while `strcspn(h,"yx")` = 17 (gcc 16) and `strpbrk` 17 (gcc 16). The slice's own 015 row confirms it: its
  pre-fix stdout `… 1 9 15 17` has `strspn(h, "abc")` = 9 before and after.
- Why it matters: tray 20 is the filing the operator sends upstream; a wrong library claim in it is a record-integrity
  failure and would be caught by upstream in a minute. D14 and SUPPORTED state the fork's contract.
- Fix: in every site above, name `strcspn` and `strpbrk` (which calls `strcspn`) only, and say that `strspn`'s `&&` form
  was not affected; the filing's title and §Description/§Impact likewise. Docs-only.

### P2-2. The cerberus-caesium consumer note claims the Ail typing is unchanged; it moved for every non-`size_t` macro type

- Where: `lean_frontend/docs/2026-11-04_consumer-note-cerberus-caesium-macro-type-ranks.md:61-62`: "The typing of a
  comparison (`int`) and the operands' types are unchanged on the Ail side, so your port of RefinedC's frontend
  (`AilToCoq.lean:738-748`) sees the same Ail as before; only the driver's Core moved."
- Claim: Ail unchanged, Core only.
- Evidence: `usual_arithmetic_integer_default` (the Ail type checker) calls `lt_integer_rank`/`ge_integer_rank` after
  its NON-STD `Size_t`/`Intptr_t` arms, so every pair with a `ptrdiff_t`, `wchar_t`, `intmax_t`/`uintmax_t`, `IntN_t`-
  family or enum operand is now TYPED by the standard's bullets where it was typed by the first operand before
  (`lt` always false). Measured (r03, `_Generic` codes, pristine → fork): `i + d` 7 → 9 (int → long), `eu + ul` 8 → 10,
  `w + l` 7 → 9, `eu ? es : eu` 7 → 8; also `integer_promotion` now promotes `wchar_t` and enums (`+w`: the record's own
  consequence). Only `size_t`-involving pairs keep their old Ail type (the NON-STD arm), which is the consumer's
  w24/w25 case — but their libxml2 TUs use `ptrdiff_t`/enums too, and a RefinedC-parity consumer relying on this
  sentence would be misled.
- Fix: rewrite the bullet: the Ail type of a comparison is still `int`; the Ail type of `size_t op X` is still
  `size_t` (NON-STD arm); the Ail type of arithmetic with a `ptrdiff_t`/`wchar_t`/`intmax_t`/`uintmax_t`/enum
  operand and of the promotion of `wchar_t`/enums DID move to the standard's (with the `_Generic` codes above as the
  witness), so AilToCoq sees those types change. Docs-only; CONTRACT D14 already says "wchar_t and enums promote …",
  so only the note is wrong.

### P3-1. No witness pairs two macro types (the libc's own `(size_t, ptrdiff_t)` conditionals were the second-largest class)

- Where: `tests/macro_type_ranks/` (every dense program pairs ONE macro type with the standard types and the two
  enums; `grep -c 'ptrdiff_t\|intptr_t\|intmax_t\|wchar_t' dense_size_t_pos.c` = 0; the only file mentioning both
  `size_t` and `ptrdiff_t`, `audit_rank_cmp_neg1.c`, compares each against `int`); the record §3.1 (the 483 matrix has
  the same partner set).
- Evidence that it matters: the old `tests/libc/libc.core` carried 10 `all_values_representable_in('size_t',
  'ptrdiff_t')` conditionals (and 6 with `'signed long'`), i.e. `(ptrdiff_t, size_t)` was a live pair in the library;
  before the fix `make_corresponding_unsigned Ptrdiff_t` is `Ptrdiff_t` itself, so both branches converted to
  `ptrdiff_t` and `d < n` with `d = -1`, `n = 1` answered 1 (gcc 0; r11 pristine). After the fix r02/r11 are right
  on both engines (`(Unsigned Long, Signed Long)` is an `eq_integer_rank_base` row), but nothing in row 1 would catch a
  regression there.
- Fix: add one dense program (or two: a positive and a negative variant) pairing `size_t`, `ptrdiff_t`, `intptr_t`,
  `uintptr_t`, `intmax_t`, `uintmax_t` and `wchar_t` with each other through the same operator set, pinned to gcc's
  line, pristine's line as the negative control (pristine answers a false UB036 on the comparison forms, so the
  pristine line is the UB line). Cheap; can land as a follow-up if the orchestrator prefers not to re-run row 1 now.

### P3-2. Stale header comment in `tests/libc_exec/016-strstr-twoway-oob.c`

- Where: `tests/libc_exec/016-strstr-twoway-oob.c:1-4` (unchanged by the slice): "the concrete model reports an
  out-of-bounds load in both engines. Recorded as the observed behaviour".
- Evidence: the row is `MATCH` with `Specified(10)` on both engines now (baseline.txt, my sweep).
- Fix: one dated line saying the read was tray 20's narrowing and the row answers 10 since 2026-11-04 (the file name
  can stay; it is referenced by baselines and the register).

### P3-3. The witness's OK line overstates "every batch line of both engines = gcc 13's pinned line"

- Where: `scripts/check_macro_type_ranks.sh:212` (the final echo) and the same sentence in the record §3.4, the
  commit message, VALIDATION's gate-table row.
- Evidence: `expected.txt` header lines 4-7 declare two rows pinned to the FORK's line (`gap_intptr_t_unsigned_false_ub036`
  — a false UB; `residual_size_t_llong_typing` — gcc `12 12 10 11 12`), and the OK line only names them at its end as
  "pinned as the declared residuals".
- Fix: "102 of 104 lines = gcc 13's; 2 pinned to the fork's declared residual" in the OK line (or keep the sentence and
  move the residual clause before "every"). Cosmetic; the pins themselves are honest.

### P3-4. The filing's hunk headers carry the fork's new-side line numbers

- Where: `lean_frontend/docs/upstream-tray/20-size-t-integer-rank-uac.md` diff block: `@@ -451,9 +453,33 @@`,
  `@@ -523,10 +549,31 @@`, `@@ -535,10 +582,10 @@`.
- Evidence: the old-side numbers are pristine's (verified), the new-side ones are the fork file's (which has two extra
  Lean-target lines above). `patch -p1 --dry-run` applies cleanly (context-driven), so this is cosmetic; a maintainer
  reading the headers will see a two-line discrepancy.
- Fix: regenerate the three headers as `+451,33`, `+547,31`, `+580,10` (or state under the block that the headers are
  the fork's).

## Items of interest, dispositioned

- Exactly the standard's rule: yes. `rank_operand` is the alias table the layout/range functions already used
  (`le_integer_range` normalises unconditionally even under CHERI, upstream's own code); the two `long long` rows answer
  what the catch-all answered for every pair reaching them (I enumerated the table: every first operand in
  `{Bool, Char, Ichar, Short, Int_, Long}` is caught by an earlier `true` row; the rest were catch-all `false`), under
  CHERI included. No other arm moved. All callers of the four rank functions are `integer_promotion`,
  `usual_arithmetic_integer_*` and `translation.lem`'s three sites (grep) — the blast radius is promotion and the UAC.
- Residual (`size_t`/`intptr_t` against `long long`/`unsigned long` typed by the NON-STD arms): honestly stated; the
  value is computed in the standard's type and re-wrapped in a 64-bit type of the same signedness for `size_t`
  (values equal), and the only verdict difference is the pre-existing false UB036 of a signed `intptr_t` result
  (F4, pinned, filed). `intptr_t a = -5; unsigned u = 3; a + u` = -2 on all sides (r05).
- CHERI: `rank_operand` is the identity, the special case stays on the bare `ity1`, the catch-all is `false`; the two
  `long long` rows are value-identical to the old catch-all. Observable check: `--pp=core` under `--switches=CHERI`
  is byte-identical to pristine (symbols normalised) on four probes; execution under CHERI asserts in
  `impl_mem.ml` on both builds (the concrete model), so no lane could ever have exercised it.
- Loud catch-all: reachable outside CHERI only by `Ptraddr_t` (which never exists outside CHERI: `ctype.lem:403-407`
  errors; verified r06 on all three engines) or a future constructor; `Signed (IntN_t 128)` crashes in the alias table
  before any rank comparison (r07). On Lean the site is `failwithI` = `panic!` → abort 134 under
  `LEAN_ABORT_ON_PANIC=1`, which the driver requires; `lem_if` elaborates to Lean's `if` (lazy), so the arm is not
  evaluated eagerly.
- Libc attributions: `strcspn` (string.c:129 `if (!BITOP(...)) break;`) — `!` is elaborated with the UAC against `int`
  0 (record §1 row: `!v` 1 for `v = 1<<57`), set collapsed to its first character; 015's last value 17→16 = gcc.
  Two-way `strstr` (string.c:261 `if (ip+1 > ms+1) ms = ip;` with `size_t ip = -1`): `ip+1` narrowed its operands to
  `unsigned int` but `wrapI_add('size_t', …)` summed them at 64 bits → 4294967296; 016 UB at :265 → 10 = gcc. Both
  confirmed with pristine and gcc. (`strspn`: see P2-1.)
- Register rows: pristine's wrong values quoted verbatim and re-measured here (015 `… 15 17`; 016 the UB at
  `<265:22--265:26>`).
- Witness script: both engines compared byte for byte to the pin, exit codes equal, streams captured separately, five
  plants with derived counts on a 10-program subset, then the real run; `expected.txt` is gcc's on every sampled row
  (19/19), `pristine.txt` is the pristine binary's on every sampled row. Sound.
- "Nothing else moved": libc_exec 41 files → exactly 015/016; the two non-gated rows (noodle probe, wt-06) move
  exactly as recorded; a nolibc spot sweep of the small gated corpora shows only the pre-registered allocator rows.
- Manifest: `[source-content]` ailTypesAux.lem re-pinned, `[expected-semantic]` ailTypesAux.ml ENTERED, dated NOTE;
  the libc dumps/sha256, the CoreQuote sha256 pair, the float-literal register (relocation only), the inner_arg_temps
  and libc_exec baselines, dispositions.txt (016 retired as a dated comment, 042 added), `test_unit.sh` row 1. Nothing
  else re-pinned.
- Filing: accurate at `c3ff8c53f` (every cited line checked), the patch minimal (the two functions and the two rows)
  and applies cleanly; cerberus-caesium credited; CHERI left to upstream. Except P2-1 and P3-4.
- D14 / VALIDATION / SUPPORTED: no overclaim beyond P2-1 (strspn) and P3-3 (wording). The migration tsv's "outside
  the exec dependency closure" matches the gate's definition (the closure is rooted at Core execution; Ail typing
  panics decode as legacy/unattributed, as the tsv says).
- Fork-fix bar and vicinity rule: honoured — the standard leaves no latitude, a consumer was blocked, the typing's
  judgement calls were left and filed rather than decided, the mechanism's neighbours were probed (483 + 104) with the
  one coverage gap of P3-1.

## Residual uncertainty

- I did not regenerate the trees; the record's "no other generated file differs" rests on the worker's `diff -rq` and
  the fork-drift/handwritten-sync gates (green in the record). The CoreQuote sha256 pins were not re-derived by me.
- The Lean driver was exercised in nolibc mode only; Lean = oracle in libc mode (015/016/042) is the A5/A15 lanes'
  evidence (Tier A green on 5dd549e54 per the record) and the full battery now running.
- CHERI is checked by reading plus Core-text equality on four probes; execution under CHERI is impossible on either
  build (concrete model assertion), so nothing stronger exists.
- The 483-program matrix and the 7204-file Core-diff sweep were the worker's instruments (deleted); I re-measured a
  41-file libc sweep, a 12-file nolibc spot sweep and 11 probe programs, not the full sweeps.
