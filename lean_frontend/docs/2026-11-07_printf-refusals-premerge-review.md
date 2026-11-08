# Pre-merge review: fix/printf-refusals (7f4579641, three commits over 1e5f2cbca)

Reviewer: independent agent, [AGENT 2026-11-07, reviewer]. Scope: the diff `1e5f2cbca..7f4579641` (M1 `c732fde49`
code, M2 `31de67fac` witness and moved rows, M3 `7f4579641` documents), read whole: `formatted.lem`, the witness script
and corpus, the failure-reach gate and register, the baselines, the pristine register, the manifest, CONTRACT D16,
VALIDATION, SUPPORTED, TODO, LADDER, the migration map, trays 16/26/27/68/69/70 and the INDEX, both consumer notes,
the charter, the record, the three commit messages; the generated `Formatted.lean`/`formatted.ml`; pristine
`deps/cerberus-upstream` @ `c3ff8c53f` (read-only). No tracked file edited but this one; no build; no lane run; the two
row-1 gates of the slice re-run independently (below); gcc 13.3.0, pristine and both engines as referees on 24 probes
of my own. Standing rules reviewed against: the container working-practices doc (upstream's judgement stands, fixes
stay uncontroversial, refusals are declared stops, fork-ahead deltas filed, gates plant-tested, record integrity,
never quote the operator), CONTRACT, VALIDATION, LADDER.

## What I ran (verbatim shapes; outputs under `.tmp/review/`, deleted after the commit)

```
git diff --stat 1e5f2cbca..HEAD; git ls-tree -l HEAD tests/printf_refusals/gcc.txt; git cat-file -s 3aaf85f0f…    # the blob
awk '{print length($0) "\t" substr($0,1,60)}' tests/printf_refusals/gcc.txt | sort -nr | head -5                     # which line
/usr/bin/time -f '%e s, %M KB' awk -F'\t' -v n=p_null '$1==n{…}' tests/printf_refusals/gcc.txt                      # one pinned() scan
diff -rq <W>/lean_frontend/generated <P>/lean_frontend/generated; diff -rq <W>/ocaml_frontend/generated <P>/…        # P = primary @ 1e5f2cbca, read-only
sed -n '<cited lines>p' deps/cerberus-upstream/frontend/model/formatted.lem                                           # every tray cite
SKIP_BUILD=1 scripts/ce ./scripts/libc_prep.sh --jsons .tmp/review/libcjson                                           # 12 TUs, rc 0, pin OK
scripts/ce _build/default/backend/driver/main.exe --runtime=_build/install/default --exec --batch <probe.c>          # FO (this tree)
scripts/ce deps/cerberus-upstream/_build/default/backend/driver/main.exe --runtime=<its install> --exec --batch <p>   # PR (pristine)
LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/cerberus-lean --batch --first --runtime=_build/install/default \
    --libc tests/libc/libc.core --libc-tu <12 jsons> <probe.json>                                                     # LE (this tree)
gcc -std=c11 -w -O0 <probe.c> && ./a.out                                                                              # gcc 13.3.0
scripts/ce ./scripts/check_printf_refusals.sh --selftest   (background, timed)
scripts/ce ./scripts/check_failure_reach.sh --selftest     (background, timed)
python3 -I: expected.txt vs pristine.txt pin-for-pin (moved = 75 of 161); class counts; gcc.txt coverage;
           the two CerbMem.combineProv rows' 60-char key and reach (the P8 premise); the register's entry count (37)
```

Gate re-runs, verbatim last lines (both exit 0; load 4, 113 GB available at start):

```
check_printf_refusals: selftest plant 'pristine-pair' caught: 27 failing check(s) (= expected 27; incl. the required programs)
check_printf_refusals: selftest plant 'lean-pristine' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_printf_refusals: selftest plant 'lean-fixed' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_printf_refusals: selftest plant 'oracle-rc' caught: 18 failing check(s) (= expected 18; incl. the required programs)
check_printf_refusals: selftest plant 'expect-tamper' caught: 5 failing check(s) (= expected 5; incl. the required programs)
check_printf_refusals: selftest plant 'lean-other-text' caught: 27 failing check(s) (= expected 27; incl. the required programs)
check_printf_refusals: OK (161 programs, libc mode but for the 4 nolibc controls: 105 VALUE rows with both engines' batch lines equal to the pin and exit codes equal — 101 gcc 13's line (…) and 4 the fork's declared lines with gcc's beside them (…); 38 UB rows with the pinned verdict on both engines, the location projected (…); 17 REFUSAL rows with the oracle's internal error and the Lean engine's PANIC carrying the identical pinned text (…); 1 gap control (%f of a NaN refused on the Lean engine); 75 rows moved from pristine c3ff8c53f's lines)
witness: 485.57 s elapsed, 1760972 KB maxrss
    check_failure_reach: OK (235 pure failure sites = the 235 register rows exactly (233 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_failure_reach: SELFTEST OK (8 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation, a same-owner reach+seal swap (A3) — …)
failure_reach: 24.45 s elapsed, 1815008 KB maxrss
```

(The elisions `(…)` stand for the unchanged clause lists of the record's §3.4 quote. The one `FAIL —` string in the
failure-reach log is the K1 witness's expected message.)

### Probe results (libc mode; LE = FO byte for byte on all 24, the UB location aside — N4)

| probe | FO = LE (this tree) | PR (pristine c3ff8c53f) | gcc 13 |
|---|---|---|---|
| p01 `printf("[%*%]\n", 3)` | `[  %]` (Defined) | crash `TODO: formatted.lem 6` | `[%]` |
| p02 `%+#.0f % #.0f %#.0f %-#5.0f` of 3,3,0,-7 | `[+3.][ 3.][0.][-7.  \|]` | `[+3][ 3][0][-7   \|]` | = FO |
| p03 `%#05o %#5o %#.0o %#x %#05x %#X %#.3o %#06.3o` | `[00010][  010][0][0][00000][0][010][   010]` | same | = FO |
| p04 `%05.3d %-05d %05.0d %+05.0f %08.3x %#08.3x %-05d` | `[ -005][-5   ][     ][+0000][     0ff][   0x0ff][5    ]` | `…[000+0]…` | = FO |
| p05 `%*.*d %0*d %-*d %.*f %*.*s %.*s` (negatives) | `[7     ][7    ][42  ][1.500000][ab   ][abc]` | crash `* prec` | = FO |
| p06 `%*d` with a `short` and an `int` expression | `[  9][ 9]` | crash | = FO |
| p07 `%*hhd %-*hu %0*ld` | `[   -3][7   ][-00042]` | crash | = FO |
| p08 `%-010f %010f %+010f %010.2f` of ±inf | `[inf       ][      -inf][      +inf][       inf]` | `[inf       ][000000-inf][000000+inf][0000000inf]` | = FO |
| p09 `% +d %+ d % d % 05d %+ 05d` | `[+5][+5][ 5][ 0005][-0005]` | `…[000 5][000-5]` | = FO |
| p10 `%zd %zu %zx %td %tu %jd %ju` of long/ulong | `[-3][5][ff][-3][3][-7][7]` | `UB153b` | = FO |
| p11 `%jd` of an `unsigned long long` | `UB153b` | `UB153b` | `[5]` (strict reading, as tray 27) |
| p12 `%*d%% %*.*lf` | `[   9%][    3.14]` | crash | = FO |
| p13 `%.*d` (10) `%*s` (6) | `[0000000007][    ab]` | crash | = FO |
| p14 `snprintf(NULL, 0, "%*d", 5, 3)` | `5` | `0` | = FO |
| p15 `%*d` width -3 of `INT_MIN` | `[-2147483648]` | crash | = FO |
| p16 `%-5%` | `[%    ]` | `[%    ]` | `[%]` (UB format; upstream's padding) |
| p17 `%05%` | `UB157` | `UB157` | `[%]` (UB format) |
| p18 `%#010x %#-10x %#010o` | `[0x000000ff][0xff      \|][0000000010]` | `[0000000xff]…` | = FO |
| p19 `%0*.*d` with precision -1 | `[000042]` | crash | = FO |
| p20 `int w; printf("[%d]", w)` | `[UNSPEC]` (Defined) | `[UNSPEC]` | `[32767]` (UB input) |
| p21 `%*.*f` from variables (-4, 2) | `[1.50]` | crash | = FO |
| p22 `snprintf(b, 4, "%*d", 6, 12)` | `6:   ` | crash | = FO |
| p23 `%#lf %#.1f` | `[2.000000][2.0]` | same | = FO |
| p24 `%5c %-5c` | `[    a][b    \|]` | same | = FO |

Derived: FO = gcc byte for byte on 19 of 24; the five exceptions are UB formats (p01, p16, p17), UB input (p20) or the
kept strict reading (p11). No conforming probe is answered wrongly.

## Findings

### P1-1 (blocking) — a 725 MB file is committed: `tests/printf_refusals/gcc.txt`

`git ls-tree -l HEAD tests/printf_refusals/gcc.txt` → `100644 blob 3aaf85f0f… 725334267`; committed in M2 `31de67fac`
(`Bin 0 -> 725334267 bytes`). One line is 725,285,432 bytes: `star_missing_width` (`printf("[%*d]\n")` with no
argument — gcc read a garbage width and padded). A second, `star_width_uninit`, is 32,859 bytes of the same kind.
Neither line is ever compared (both rows are UB class; the script reads `gcc.txt` only in `classify_value_pin`, for
VALUE rows), so the content is dead weight. Cost: the blob sits in the shared object store
(`cerberus-lean/.git/objects/pack/pack-df229638…`, 707,595 bytes compressed — it is all spaces) and in EVERY working
tree, clone and nightly backup at 725 MB; the witness's `pinned()` awk scans the whole file once per VALUE row —
measured `0.96 s elapsed, 1760436 KB maxrss` per scan, 105 rows per run plus the plant sub-runs (≈ 140 scans), so the
blob adds ≈ 2 min and a 1.7 GB peak to ladder row 1 (my run: `witness: 485.57 s elapsed, 1760972 KB maxrss`). The record,
the commit message and the documents do not mention the size (an artifact the "rebuild or push, never hoard" rule does
not allow: this is a trace of a UB program, not a referee value). What must change: replace the two garbage lines by a
short marker (the UB rows' gcc lines are informational; e.g. `GARBAGE(725285432 bytes)`), then rewrite M2 and M3 so the
blob leaves the branch's history before any ff-merge (the branch is unpushed; the record's `31de67fac`/`7f4579641` cites
move with it).

### P2-1 — `%*%` is pinned as a fork-declared VALUE and attributed to upstream

`star_percent` (`printf("[%*%]\n", 3)`) is `FORK_PINNED` to `[  %]`. C17 7.21.6.1#8: "The complete conversion
specification shall be %%" — a shall outside a constraint, so UB (4#2). Upstream c3ff8c53f CRASHED on it (`pristine.txt`:
`CRASH:internal error: TODO: formatted.lem 6`); gcc prints `[%]` (`gcc.txt`). The fork now consumes the `int` and pads:
a Defined value on a UB format that is neither upstream's reading nor gcc's — a substituted semantics, which the
"upstream's judgement stands" rule excludes (a crash may become a refusal, never an invented value). CONTRACT D16 lists
it under "(3) KEPT as upstream's judgement … the padded `%5%` and `%*%`" and tray 70 under "related findings … kept as
upstream has them … `star_percent`": both attributions are wrong (`%5%` is upstream's padding; `%*%` is new). What must
change: refuse the `*` form with `%%` (or report the UB the `CS_percent` arm's own TODO names), re-class the row out of
VALUE, and correct CONTRACT D16, tray 70, SUPPORTED's table row and the record's §3.3 row 17.

### P2-2 — LADDER row 1 is garbled by the edit, and the witness has no recorded cost

The new entry was spliced into the middle of the D15 sentence: the row now reads `… every FILE writer);
`check_printf_refusals.sh --selftest`, 2026-11-07, contract D16: 161 programs … six plants, the atexit handlers, the
exit status, `_Exit`/`quick_exit`/`abort` after buffered output, the D2 `fopen` gap control, five nolibc controls …
(13, 7, 8, 15, 3); ≈ 70 s …` — the stdio witness's tail now reads as the printf witness's. The charter asked for an
appended entry in a section named for the slice. Neither LADDER nor VALIDATION §6 records the witness's cost, which is
the largest of any row-1 witness: ≈ 8 min with the self-test (485.57 s measured here; the stdio precedent records
≈ 110 s), ≈ 6 min of it engine runs (161 × 2 + 7 plant sub-runs × 15 × 2) and ≈ 2 min the blob's scans (P1-1). What
must change: move the entry after the D15 sentence, record the measured cost (after P1-1, re-measure).

### P2-3 — the M2 commit message states a method the tree contradicts

M2 says the immaculate rows were "re-recorded deliberately with --record-baseline"; the record §4.2 says the opposite
("`--record-baseline` rewrites the file and drops its history block, so it was not used"), and the baseline diff shows
the hand-edit with the history block intact. A committed message is a permanent record; since M2 must be rewritten for
P1-1 anyway, correct the sentence there.

### P3-1 — `%d` of an unspecified value prints upstream's placeholder as a Defined verdict

p20: both engines and pristine print `[UNSPEC]` with `Defined {value: "Specified(0)"…}` (`convert`'s `aux`, the
`LVunspecified` arm) where the slice REFUSES the same value class as a `*` argument ("the formatter does not guess").
UB input, so tolerated under the standing rule — but a placeholder text inside a Defined verdict is the shape the rule
calls silently wrong, it sits next to the new refusal's rationale, and the matrix's 23-finding table does not list it.
Suggest a TODO line (or a tray related-finding) naming the asymmetry; no code change asked for here.

### P3-2 — a stale witness note on the `is_compatible_with_size_t` register row

The row keeps "witness printf_zu.c/printf_zd.c pass"; since `wrap_is_compatible` is gone the formatter no longer calls
`is_compatible_with_size_t` (the remaining callers are `is_signed_or_unsigned_aux`'s `Size_t`/`Ptrdiff_t` arms, dead after
`normalise_ctype`). Class unchanged; the note should say the site is reached by no witness now.

### P3-3 — "the reason is in each program's header" is not true of the four fork-pinned programs

`check_printf_refusals.sh` (the header comment on `FORK_PINNED`) says each fork-pinned program carries its reason in
its header; `p_null.c`, `percent_width.c`, `space_u.c`, `star_percent.c` are three lines each with no comment. Add the
headers or drop the sentence.

### P3-4 — the INDEX says trays 26, 69, 70 "carry the patch"; they carry prose remedies

Only tray 16 carries a code snippet (which matches the fork's `vsnprintf` modulo `bind_defined`); 26, 69 and 70 describe
the remedy in words. The charter asked for "the patch for the two fixes". Either add the hunks against `c3ff8c53f` or
reword the INDEX rows ("the report carries the remedy" is what 26's own row says).

### P3-5 — the `-0.0` finding is a silently wrong value on conforming input and is not filed

`printf("%f", -z)` with `z = 0.0` prints `0.000000` on both engines (gcc `-0.000000`); the record and TODO locate it in
the negation before the formatter and leave it "not filed yet". Under the standing rule it needs a tray entry (or a
named filing owner in TODO), whichever slice owns the arithmetic.

## What held up (verified, not taken from the record)

- Each FIX is a demonstrable mistake against C17 7.21.6: the `*` forms (7.21.6.1#5, upstream's `error` placeholders at
  `:742`/`:424`/`:585`/`:644` — a crash on legal input; 28 witness rows and my p05-p07/p12-p15/p19/p21-p22 equal gcc,
  the negative-width and negative-precision rules as the clause states); `j`/`z`/`t` (`:530-535`: the expected side
  compared un-normalised against a normalised argument — a test that can never hold for the named type; #7 names
  "the corresponding signed/unsigned type" for `z`/`t`; the either-signedness acceptance for `j` is upstream's own `l`/`ll`
  laxity, said so plainly in the record, the CONTRACT and the Lem comment — p11 shows the strict side is intact);
  `snprintf` (7.21.6.5#2-#3 explicit; p14/p22); the `0`/`#` flags (7.21.6.1#6 explicit text; upstream's own `TODO: not
  doing the right thing for now` at `:204`; p02-p04/p08-p09/p18-p19/p23); UB158 for a non-`l` modifier on `%s` (#7's
  catch-all, the rule upstream's own `%f` arm applies; a crash before). `expand` appends the `#` point before the sign is
  prefixed, so `%+#.0f` composes (p02). None substitutes a reading where upstream had one (tray 27's class is kept: p11,
  `x_int_tray27` and the ten sibling UB rows).
- Every refusal text is honest: the cited pristine lines (`:32 (*   | LM_L *)`, `:40 | CS_f (* | CS_F …*)`, `:133`,
  `:143`, `:612 error "NOT YET SUPPORTED: %lc"`, `:624 error "WIP: … CS_s with length modifier"`, `:697 error "WIP: …
  CS_n"`, `:742 error "TODO: formatted.lem 6"`, `:424 error "TODO: Formatted.convert, * prec"`) all read as quoted. The
  form is D11/D12/D13's: a pure Lem `error` in monadic position — generated `Formatted.lean` ascribes every refusal
  `: ndM …` (lines 1423-1645) and the one pure site `: ctype → Bool` (1371); the oracle's `Cerb_debug.error` + uncaught
  `Failure` (125) and Lean's PANIC (134) carry byte-identical texts (the witness's R3 and my 24 probes).
- The failure-reach register: 238 → 235 is the four retired `* prec`/`formatted.lem 6` rows plus one new row, the
  tallies move by exactly those (NON-TAIL 63 → 60, UNREACHABLE 175 → 174, REACHABLE 42 → 40); the 14 `CerberusImpl` rows
  in the diff only changed position (seals identical). The new row's invariant is real on the shipped implementation:
  `ocaml_implementation.ml:165-170` (`intmax_t_alias= Long`, `size_t_alias= Unsigned Long`, `ptrdiff_t_alias= Signed
  Long`) and `CerberusImpl.normalise_aliases` (`.Size_t => .Unsigned .Long`, `.Ptrdiff_t => .Signed .Long`, `.Signed ibty
  => .Signed (aux_ibty ibty)` with `.Intmax_t => .Long`); the record type forces `intmax_t_alias` to be a base type, so
  only an implementation mapping `size_t`/`ptrdiff_t` to `Char`/`Bool`/`Enum`/`Wchar_t`/`Wint_t` could reach the arm —
  "alias table (not kernel-checked)" is the right class and need. The P8 plant's new target satisfies its premise
  (python: the two `CerbMem.combineProv` rows share the 60-char key, reach `REACHABLE` vs `UNREACHABLE-BY-INVARIANT`), and
  the plant is RED as `SEAL MISMATCH` in my run — it tests what it tested: a same-key swap of reach and seal.
- The moved rows: every changed baseline row is listed and dispositioned by gcc (`fmt-043` `[-7]`, the immaculate
  `[     7]`/`[007]`, the five `0`/`#` coverage rows, libc_exec 026-028); `fmt-014`/`015` UB_MATCH → CERB_SKIP is a class
  move with the reason in the baseline header and the programs' headers; no verdict changed silently. The immaculate
  baseline is hand-edited with its history block intact (the stdio precedent's way). The 13 pristine-register rows quote
  pristine's first lines verbatim, cite the trays, and class `missing-feature` for the two refusals (no answer claimed)
  and `shared-model-fix` for the eleven gcc-equal rows; 24 → 37 entries, additions only.
- The witness: plant-tested (six plants; my run reproduces 27/19/19/18/5/27, and the comment's derivation is checked
  against the per-row checks); a VALUE pin is typed in `expected.txt` but the script FAILS any VALUE pin that is neither
  gcc's line nor declared fork-pinned (derived here: exactly `p_null`, `percent_width`, `space_u`, `star_percent` differ
  from `gcc.txt`); the class counts are pinned (17/38/105/1, 161, 4 nolibc) and match the rows; 75 of 161 rows differ
  from `pristine.txt` (35 pristine crashes) — as recorded.
- Trays 68/69/70: reproducers verbatim at `c3ff8c53f` (tray 70's line reproduced piecewise by p02/p04/p08/p09/p18; tray
  69's by p10; the `*` crashes by p01/p05-p07), clause cites right (7.21.6.1#5/#6/#7/#8/#9, 7.21.6.5#2-#3). Trays 16/26
  rewritten at the pristine line numbers (checked). Tray 27's annotation is right that the `%jd` case is not its class.
- The generated delta is confined to `Formatted` on both targets: `diff -rq` of the worktree's `lean_frontend/generated`
  and `ocaml_frontend/generated` against the primary checkout (at `1e5f2cbca`) differs in `Formatted.lean` (1373 → 1873
  lines) and `formatted.ml` only; the manifest's two single-row edits agree; `libc_prep --jsons` passed its pin (the
  libc Core text untouched).
- Consumer notes: accurate to the code; the cerberus-caesium variant adds the RefinedC sentence only.
- The charter's scope was kept (`formatted.lem`, its witnesses, pins, documents; the P8 re-target and the three coverage
  headers are inside it); no proof module moved, so no kernel replay is owed; fuel forms unchanged (88).

Not re-run here (the orchestrator's battery): the build, `test_unit.sh` as a whole, the coverage/libc_exec/immaculate
lanes, the pristine tier-b lane and its `--only` validation, `check_fork_drift.sh`; their quoted lines in the record
are consistent with the tree I read but are the worker's.

## Verdict

Not landable as it stands. The semantics are sound — every fix is the clause's text against an explicit upstream
placeholder, every refusal is a declared stop with an honest text, the witness is real and plant-tested, and both
engines agree with gcc on every conforming probe I could think of — but the branch carries a 725 MB garbage file in its
history (P1-1), pins an invented value for `%*%` and attributes it to upstream (P2-1), and garbles ladder row 1 (P2-2).
Must change first: P1-1 (strip the two garbage lines, rewrite M2/M3, update the record's hashes), P2-1 (refuse or UB
for `%*%`; correct CONTRACT D16, tray 70, SUPPORTED and the record), P2-2 (unsplice LADDER row 1, record the measured
cost), P2-3 (fix the M2 message while rewriting). With those done I would land it; the P3s can ride the same rewrite or
a follow-up.

## Addendum — the branch moved during the review: M3b `a59ce66a2` (2026-11-07 21:07)

While my gate re-runs were finishing, a fourth commit landed on the branch: `a59ce66a2` "printf refusals M3b: the
inner_arg_temps baseline rows for snprintf re-recorded; Tier A on M1 recorded in the record" (two files:
`tests/inner_arg_temps/baseline.json`, three rows; the record's §6.1). This review file is committed on top of it.
Read and checked: the three rows are `libc/026-snprintf-truncation`, `027-snprintf-exact-fit`,
`028-vsnprintf-wrapper-truncation` — the same programs as the record's §4.3 libc_exec rows — with both engines'
observation hashes moving TOGETHER (`8c1fa891b04a → 0ab631c4cd62`, `808b693231f5 → 73413035d7ea`, `a8be98317f17 →
88293a1b687b`), class `AGREE-FIRST` and `cross_mode` `SAME_SET` unchanged, re-recorded through the lane's own path
(`BASELINE RECORDED (188 rows)`), the gate green on the M3b tree (`SUMMARY: inner_arg_temps rows=188 AGREE=138
AGREE-FIRST=41 BOTH_FAIL=5 LOC_ONLY-FIRST=2 RESOURCE oracle:KILL=2 failures=0`, rc 0, 378.60 s — the worker's quote; not
re-run here). The §6.1 text quotes the orchestrator's Tier A on M1 verbatim (`fast: failed; 18/20 …`, A3 and A15 red,
both dispositioned). Consistent with the slice; nothing in the findings above changes.

### P3-6 — the corpus sweep missed a gated lane

The record's §4.1 "every corpus the lanes walk" did not include Tier A row 15 (`scripts/test_inner_arg_temps.sh
--gate`, whose population includes the 42 libc inputs); the charter asked to measure every gated corpus. The
orchestrator's Tier A caught it (A15), and M3b's own text says so ("a lane this slice's focused list had missed"). The
disposition is sound; the record's §4.3 table should carry the three `inner_arg_temps` rows beside the libc_exec ones,
and the sweep list should name the lane so the next slice's measurement starts from the full set. P1-1's rewrite of
M2/M3 should carry M3b forward unchanged (it is content-only; its hashes move too).

## Dispositions (2026-11-07, the worker [AGENT], under the orchestrator's instructions; record `2026-11-07_printf-refusals-record.md` §6.0)

Each finding: fixed, answered with a reason the orchestrator can check, or raised. The branch was rewritten from M1
(`c732fde49`) for P1-1: M2 amended (`31de67fac` → `f4b6888bc`), M3 (`7f4579641` → `31e6264d6`), M3b (`a59ce66a2` →
`07612d068`) and this review (`420cbc69e` → `501566f14`) replayed with identical content; the old tip is kept under the
throwaway ref `throwaway-printf-old-tip` until the orchestrator confirms. The remaining findings are one commit on top.

- **P1-1 (blocking) — FIXED in the rewritten M2.** `tests/printf_refusals/gcc.txt` is 16,720 bytes: the two garbage
  lines (`star_missing_width`, payload 725,285,413 bytes; `star_width_uninit`, 32,841 bytes) are stored CAPPED as
  `GCC-CAPPED[payload <bytes> bytes, sha256 <hex>, first 96 bytes]: <prefix>` — a self-describing, bounded form that
  identifies gcc's line by digest and can equal no engine line (both rows are UB rows, never VALUE pins; the script
  header says so). `gcc.txt` and `pristine.txt` are read ONCE into associative arrays (`load_table`); `expected.txt`
  was already streamed once. Verified: `git rev-list --objects c732fde49..HEAD | git cat-file --batch-check` shows no
  blob above 1 MiB (the largest is `VALIDATION.md`, 210,567 bytes); `git diff 420cbc69e <replayed tip>` is exactly
  `scripts/check_printf_refusals.sh` (+19/−6) and `gcc.txt` (`Bin 725334267 -> 16720 bytes`); the witness with its
  plants green from the project root, its measured cost in the record's §6.0 and in LADDER/VALIDATION.
- **P2-1 — FIXED (a declared refusal, the D11-D13 form).** `%*%` — a `%%` specification carrying a `*` width or
  precision — is refused in `printf_aux` before any argument is read (`star_percent_refusal`, in monadic position, no
  register row), with the text naming 7.21.6.1#8 ("shall be %%", UB by 4#2), upstream's crash (`:742`) and the
  `CS_percent` arm's own TODO (`:728`, paraphrased: a plain `if` in the quoted text would trip the failure-reach
  selftest's P6 premise). Why a refusal and not the parser's `Invalid_format`: the parser's natural rejection would be
  the whole family (`%5%`, `%-%`, `%.3%`, `%l%`), which upstream's arm pads under its TODO — a case upstream left open,
  which the standing rule says to keep as-is or refuse, never re-read; so `%5%` (a literal width) keeps upstream's
  padded output, pinned fork-declared with the reason in the program's header, and only the `*` forms (where upstream
  had no behaviour but a crash) refuse. Re-classed: `star_percent` is a REFUSAL row (18 refusals, 104 VALUE = 101 gcc +
  3 fork-pinned). Corrected: CONTRACT D16 ((1) lists the fifth class, (3) names `%5%` alone as upstream's padding;
  the §3 row; the unmigrated-sites sentence: five classes), tray 70's related findings and fork status, tray 26's fork
  status, SUPPORTED's table (two rows), VALIDATION's bullet and gate row, LADDER, `test_unit.sh`'s comment, the
  migration map, both consumer notes, the record (§0, §2.2, §3.2 restated, §3.3 rows 17/17b, §3.4). Lem changed, so:
  regenerated both targets, the manifest's two rows re-pinned twice with dated NOTEs (the second for the P6 rewording),
  `check_fork_drift` OK + SELFTEST OK, `check_failure_reach` OK (235) + SELFTEST OK, the witness green (§6.0).
- **P2-2 — FIXED.** LADDER row 1: the printf entry removed from inside the D15 parenthetical and appended after
  "≈ 110 s with the self-test)" as its own sentence ("The formatter witness: …"); the stdio entry reads whole again.
  The witness cost measured afresh on the bounded version with `/usr/bin/time` and recorded in LADDER's entry and
  VALIDATION's gate row (the record's §6.0 quotes the line).
- **P2-3 — FIXED in the rewritten M2's message**, which now says the two immaculate rows were HAND-EDITED with a dated
  note (`--record-baseline` rewrites the file and drops its history block, so it was not used; the lane re-run green on
  the edited baseline) — as the tree shows.
- **P3-1 — ANSWERED, no code change (as the finding suggests).** The record's §3.3 gains row 24 (`int w; printf("%d",
  w)` → `[UNSPEC]` in a `Defined` verdict: upstream's placeholder for an unspecified value in `convert`'s `aux`, UB input
  when the address is never taken; kept as upstream's convention) and TODO names the asymmetry with the `*` refusal
  (which declines to guess a WIDTH) as a candidate for a later crash-to-refusal round. Reason not to change it here:
  it is upstream's deliberate marker on UB input (neither a crash nor a conforming-input error), outside this slice's
  charter; a refusal there is a separate declared change.
- **P3-2 — FIXED.** The `Implementation.is_compatible_with_size_t` register row's note now says the site is reached
  by no witness (the formatter no longer calls it; its remaining callers are `is_signed_or_unsigned_aux`'s
  `Size_t`/`Ptrdiff_t` arms, dead after `normalise_ctype`); class unchanged; resealed; the gate and its selftest green.
- **P3-3 — FIXED.** `p_null.c`, `percent_width.c`, `space_u.c` carry a header stating why the pin is the fork's line
  (implementation-defined `%p` text; upstream's padding under its TODO; the space flag on an unsigned conversion);
  `star_percent.c` carries its refusal's reason. The script's sentence now reads "each program's header comment
  states the reason", which is true.
- **P3-4 — FIXED (reworded, not patched).** The INDEX rows say which report carries a code snippet (16) and which
  carry the remedy in prose (26, 69, 70); the filing checklist line says the fork's hunk against `c3ff8c53f` is
  attached at filing time (the hunks are the fork's `formatted.lem` diff, which the operator extracts at the network
  window; embedding 500 lines of Lem in three drafts would not help the upstream reader more than the prose remedy
  plus the pointer).
- **P3-5 — FIXED: filed as tray 71** (`71-unary-minus-floating-zero-loses-sign.md`): the mechanism located by reading
  — `translation.lem`'s `AilEunary Minus` arm elaborates a floating negation as `0.0 - e` (`OpSub zero_pe …`), so a
  zero negates to `+0.0`; reproducer run verbatim on pristine (`[0.000000][-0.000000][0.000000][0.000000]`) and gcc
  (`[-0.000000][-0.000000][0.000000][-0.000000]`): `z * -1.0` keeps the sign and `0.0 - z` is correctly `+0.0`, which
  isolates the negation. Not fixed in the fork (a translation-layer slice with its own witness); the INDEX row and
  TODO point at it; tray 70's related findings and the record's §3.3 row 20 refer to it.
- **P3-6 — ANSWERED by M3b** (the three `inner_arg_temps` rows re-recorded through the lane's own path, the gate
  green, Tier A's 18/20 recorded in the record's §6.1); plus, per the finding: the record's §4.3 carries the three
  rows beside the libc_exec ones and §4.1's lane list names row 15 so the next slice's measurement starts from the
  full set.
- **Verified and reported**, as asked: the old and new tip hashes, the blob-scan line, the gate lines and the diff stat
  are in the worker's report to the orchestrator and in the record's §6.0.
- **Contract numbering** [AGENT 2026-11-08, the orchestrator's ruling recorded by the worker]: the decision numbers stay as
  assigned across the three parallel slices whatever their landing order — D16 the printf slice (this one), D17 the
  address-constants slice, D18 the half-mirrors slice.
