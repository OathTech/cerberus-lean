# Inline assembly: a loud refusal — slice record (2026-10-05)

Branch `fix/asm-refusal`, from mainline `mdd/cerberus-lean` = `1001f3f2b`.
Worker: Claude Opus 5.5 (agent). Every judgement below that no operator quote
covers is marked [AGENT].

## 0. Ruling and standing rules (verbatim)

- [USER 2026-10-05]: "Re inline asm, this should be a loud refusal".
- No innovation versus upstream, [USER 2026-10-03]: "we should fall back to
  loudly rejecting (either as unsupported, or matching upstream)". A refusal
  invents no semantics.
- No magic modes, [USER 2026-09-30]: "we should not fix deviations with special
  'magic mode' paths that work exclusively in one situation". The refusal sits
  on the GENERAL path: the shared `.lem` desugarer and the shared C parser, which
  every program and both engines go through. There is no flag and no Lean-only
  arm.
- Fail-closed, fail-noisy throughout.

Origin: the real-C census audit M1 (`docs/2026-10-04_real-c-reach-census.md`
§0 and §4.5). Upstream erases inline assembly, and so did both fork engines. On a
census probe the oracle and Lean both gave `Specified(1)` where gcc gives 5.

## 1. Survey: every asm form the front end accepts, and how it reaches desugar

The lexer (`parsers/c/c_lexer.mll:120-122`) maps `asm` and `__asm__` to `ASM`,
and `__volatile__` to `ASM_VOLATILE`. `__asm` (no trailing underscores) is NOT a
keyword.

| # | Form | Grammar | Upstream behaviour (pristine `b9aeedcb4`, measured) | Now |
|---|---|---|---|---|
| F1 | basic asm statement `asm("nop");` | `asm_statement`, first production (`c_parser.mly:1534-1544` after this commit; `:1527-1537` before) → `CabsSasm` | `cabs_to_ail.lem` `CabsSasm` arm: `E.return AilSskip` ("TODO: erasing inline assembly for now"). `Specified(1)` on the `basic.c` probe | REFUSED in the shared desugarer |
| F2 | extended asm `__asm__ __volatile__ ("…" : outputs : inputs : clobbers)` | second production (`:1545-1555` after this commit) → `CabsSasm` (the operands are parsed and DISCARDED by the parser; only the template strings reach Cabs) | erased as F1. `Specified(1)` on the census shape (gcc 5) | REFUSED in the shared desugarer |
| F3 | `asm goto ("…" : : : : label)` | second production, `asm_with_labels` → `CabsSasm` | erased as F1. `Specified(1)` (gcc 0) | REFUSED in the shared desugarer |
| F4 | asm label on a declarator: `int y asm("sym") = 3;`, `int f(void) __asm__("sym");`, `register int r asm("eax") = 2;` | `init_declarator`'s `ioption(asm_register)` (`:893-899`); `asm_register` returned `()` — the label is DROPPED IN THE PARSER and never reaches Cabs | silently ignored. `Specified(3)`, `Specified(0)`, `Specified(2)` | REFUSED in the shared parser |
| F5 | file-scope `asm(".globl foo");` | not in the grammar | syntax error: `unexpected token after ';' and before 'asm'` (exit 1) | unchanged: already loud, not attributed |
| F6 | `__asm("nop")` | an ordinary identifier | `use of undeclared identifier '__asm'` (exit 1) | unchanged: already loud, not attributed |
| F7 | a string with an encoding prefix inside `asm(…)` | `asm_statement`'s `failwith "encoding prefix found inside a __asm__ ()"` | the parser driver re-raises the `Failure`: uncaught, loud | unchanged: already loud, not attributed |

Other places checked [AGENT]: an asm label written on a function DEFINITION
(`int f(void) asm("g") { … }`) is also refused with the F4 message — the label is
reduced before the `{` (pre-merge audit INFO-4 corrected this sentence, which
said it was a syntax error). Also loud but NOT attributed, left unchanged (audit
INFO-5): `asm volatile("" ::: "memory")` (`::` lexes as one token → parser
syntax error, "state 109" — a very common real-code shape), and asm labels on
struct members (state 501) and parameters (state 352), both syntax errors. `CabsSasm` has one other consumer, `register_labels`
(`cabs_to_ail.lem`, returns `()`). It is untouched, because desugaring now fails
at the statement itself. The Cabs JSON exporter carries `CabsSasm` unchanged.
The Lean engine has no C parser: its only input is that JSON.

F5–F7 were already loud refusals upstream: nonzero exit, no answer. They are
listed, not changed. Attributing F5 would need a new grammar production, which
moves the parser's error-message states (`c_parser_error.messages`). That is more
drift for a form that is already loud [AGENT].

## 2. Blast radius, measured before any change

Grep `\b(__asm__|asm|__asm)\b` over `*.c`, `*.h`, `*.core` in `tests/`,
`runtime/`, `lean_frontend/{corpus,test,speclab}`: 125 files.

- `runtime/` (libc headers and sources, libcore): **1 hit, a comment**
  (`runtime/libc/include/posix/fcntl.h:5`, "taken from Linux include/uapi/asm-generic/fcntl.h").
  No runtime file uses asm. libc.co was rebuilt under the change (§5).
- `tests/census/linux/config-src/{autoconf.h,asm-offsets.h}`: comments only.
  The census is a dated measurement, not a lane.
- `tests/gcc-torture/execute/` (61 files): no lane reads this directory.
- `tests/gcc-torture/breakdown/` (61 files): only `test_ci_sweep.sh` reads it.
  That is LADDER Tier C row C4, a scoreboard with NO baseline; its committed TSVs
  move only by a deliberate re-record. In `tests/ci_sweep/results/torture_*.tsv`,
  55 of the 61 are already `CERB_REJECT` and stay rejects (a refusal only adds
  failures). The six `MATCH` rows, re-run with the new oracle:

  | row | old TSV | new oracle |
  |---|---|---|
  | `not_std_compliant/asm/pr49218.c` | MATCH `Specified(0)` | `16:2: error: feature not yet supported: inline assembly (asm statement) is unsupported` |
  | `not_std_compliant/asm/pr52286.c` | MATCH | `14:3: …` same refusal |
  | `not_std_compliant/asm/20020107-1.c` | MATCH | `20:3: …` same refusal |
  | `not_std_compliant/asm/pr69320-2.c` | MATCH | `12:6: …` same refusal |
  | `not_std_compliant/asm/20080122-1.c` | MATCH | `13:5: …` same refusal |
  | `not_std_compliant/asm/pr56866.c` | MATCH `Specified(0)` | unchanged `Specified(0)`: its asm sits inside `#if __CHAR_BIT__ == 8 && …`, which Cerberus's preprocessing makes false, so no asm reaches the parser |

  **Five scoreboard rows move MATCH → reject, all to the refusal class, none to
  agreement.** The TSVs are not re-recorded in this slice. The scoreboard has no
  baseline to break, and a re-record is a deliberate Tier C campaign [AGENT].
- Every GATED corpus has zero asm: `tests/{minimal,coverage,debug,float,bytes,
  libc_exec,multi_tu,multi_tu_tray,immaculate,verify,ci,csmith}`,
  `lean_frontend/corpus`, the CN corpus (`deps/cn/tests/cn`, 512 files, grep
  read-only), and the libxml2 TUs (`deps/libxml2/*.c` and its headers, grep
  read-only). A second grep for the call shape `asm|__asm__ [qualifier] (`
  outside gcc-torture: zero files. **No gated lane row moves.**

So the move is a handful of rows (5), on no gated lane, and no runtime file uses
asm. No STOP condition held.

## 3. Design

[AGENT orchestrator] preferred design, followed: change the shared sources so
both fork engines refuse identically.

- **Statement forms F1–F3** — `frontend/model/cabs_to_ail.lem`, the `CabsSasm`
  arm of `desugar_statement_aux`:
  `E.fail loc (Errors.Desugar_NotYetSupported "inline assembly (asm statement) is unsupported")`.
  This is the existing vocabulary: the same constructor reports `bit-fields`, VLAs
  and similar features. `NotYetSupported` (not `NeverSupported`) is the neutral
  claim [AGENT]. Both engines are generated from this `.lem`:
  - Oracle: exit 1, `<file>:<l>:<c>: error: feature not yet supported: inline assembly (asm statement) is unsupported`.
  - Lean `--batch`: exit 1, `Error {msg: "desugaring failed at <file>:<l>:<c>-<c'>"}`.
    This is Main.lean's existing batch rendering of every desugar failure.
  - Lean without `--batch`: `cause: DESUGAR NotYetSupported: inline assembly (asm statement) is unsupported`.
  The refusal does not depend on reachability: desugaring covers every function
  (witness `uncalled.c`).
- **Declarator label F4** — `parsers/c/c_parser.mly`, the `asm_register` action:
  `raise (C_lexer.Error (Errors.Cparser_unimplemented_keyword "asm (inline assembly label on a declarator is unsupported)"))`.
  The parser driver's existing handler (`c_parser_driver.ml:23-25`) turns it into
  `Exception.fail (loc, CPARSER …)`, rendered as
  `error: unimplemented keyword 'asm (inline assembly label on a declarator is unsupported)'`, exit 1.
  The label exists ONLY in the parser (it is discarded before Cabs), so the parser
  is the one general place to refuse it. Lean cannot see it: `--cabs-json` fails
  identically and writes no JSON.
  - Only the semantic action changes; the grammar does not (menhir's
    `--compare-errors` completeness check passes unchanged). A `: unit` type
    annotation keeps the nonterminal's type fixed.
  - The location is the point where the parser reduces the label, i.e. the token
    after its `)` (`d1.c:1:20` is the `=`). [AGENT] This is accepted: the message
    names the feature, and the line is right.
- Rejected alternatives [AGENT]:
  - A Lean-only arm: forbidden by the ruling's design note and by no-magic-modes.
  - Carrying the label into Cabs so that desugar refuses it: this changes the
    Cabs type, the JSON exporter and the Lean importer, to transport something
    whose only use is to be refused.
  - A new error constructor: the brief asked for the existing vocabulary.

## 4. Register entries

- `scripts/fork_drift_manifest.txt`: a dated header NOTE "fix/asm-refusal,
  2026-10-05", plus single-row edits, never `--refresh`:
  - `[source-content]` `frontend/model/cabs_to_ail.lem` `d16c0201…` → `2117fd83…`.
  - NEW `[files]` and `[source-content]` row `parsers/c/c_parser.mly` `dbc59122…`
    (the file was byte-identical to upstream before).
  - `[expected-semantic]` `cabs_to_ail.ml` `18f2c651…` → `406d97ee…`.
  - The generated parser is built by dune, outside layer 2.
  - Gate: 87 oracle-surface files, 30 differing generated files (§6).
- `scripts/upstream_oracle_differences.json`: **no row**. No program on Tier B
  row 10's walked corpora contains asm (§2). VALIDATION's fork ≠ pristine
  inventory lists the deliberate difference anyway ("Fork refusal — inline
  assembly (0 register rows)"), as that section requires for every deliberate
  shared-model delta.
- `lean_frontend/CONTRACT.md`:
  - a new §3 row "Inline assembly — REFUSED (D9)" with its witness;
  - the refused-parts sentence and §4.1's witness list;
  - a §5 decision **D9** carrying the [USER 2026-10-05] quote.
- `lean_frontend/VALIDATION.md`:
  - a §3(c) missing-feature bullet "*Inline assembly*", explicitly a refusal and
    NOT an ISO fix (§2's ISO-fix register is untouched);
  - the fork ≠ pristine inventory entry;
  - a §6 gate-table row for `check_asm_refusal.sh --selftest`.
- `lean_frontend/SUPPORTED.md`: the Domain row's limit names the refusal.
- `scripts/LADDER.md` row 1: names the new witness.
- `scripts/test_unit.sh`: runs `check_asm_refusal.sh --selftest`.

## 5. Witnesses and plants — `scripts/check_asm_refusal.sh`

The script follows the style of `check_cabs_json_utf8.sh`. Nine cases, all
fail-closed:

- **4 statement witnesses**:
  - `ext.c` is the census §4.5 shape, extended with an output operand.
  - `basic.c`.
  - `goto.c` (`asm goto` with a label).
  - `uncalled.c` (asm in a never-called static function).

  For each, the oracle `--exec` must exit 1 with the exact message at the asm's
  `line:col`. `--cabs-json` must succeed. Lean `--batch` must exit 1 with
  `Error {msg: "desugaring failed at <file>:<line:col>…`, and Lean without
  `--batch` must print the attributed cause at that location.
- **3 label witnesses** (`lab_obj.c`, `lab_fun.c`, `lab_reg.c`): the oracle must
  exit 1 with the exact message at the pinned position, for both `--exec` and
  `--cabs-json`. `--cabs-json` must also write no JSON.
- **2 controls**: `ctl.c` (asm-free) and `ctl_text.c` (asm only in a comment and
  a string). Each must give the oracle `Defined … Specified(5)` and Lean
  byte-identical, exit 0.
- **Plants (`--selftest`)**. Each must make the witnesses fail. They are checked
  by count — each plant asserts its EXACT expected failure count, and the
  `lean-erase` / `refuse-all` plants additionally assert that both CONTROL
  witnesses are among the failures (pre-merge audit LOW-1/LOW-2: before the fix
  the count was printed, not asserted, and `refuse-all` would have stayed
  "caught" with a no-op `control()`; re-planted 2026-10-05: with `control()`
  made a no-op the selftest now fails, `lean-erase caught 8 …, expected exactly
  10`):
  - `erase` reproduces the pre-fix behaviour of BOTH engines. An oracle stub
    strips every asm form from the C file and runs the real oracle, so the real
    Lean engine runs the erased Cabs. It caught 18: 4×3 statement checks plus 3×2
    label checks. Both controls pass under it.
  - `lean-erase` pairs the real oracle with a Lean stub that answers
    `Specified(1)`. It caught 10.
  - `refuse-all` refuses everything on both sides with the right words. It caught
    16.

## 6. Gates (verbatim lines)

Build:
- `make prelude-src` and `make lean-prelude-src` were run, regenerating both
  trees.
- OCaml was rebuilt with `DUNE_CACHE=disabled dune build --force
  backend/driver/main.exe cerberus-lib.install`. libc.co, libm.co and
  libc_inner_arg_temps.co were rebuilt under the new desugarer, from libc sources
  that contain no asm.
- Then `dune install --prefix "$PWD/_build/local-install" cerberus-lib`, and
  `DUNE_CACHE=disabled dune build --force cerberus.install`.
- Lean: `scripts/capped lake build`: `Build completed successfully (395 jobs).`
  (4 min 04 s).

Pristine upstream on the same probes (the independent oracle at `b9aeedcb4`,
read-only):
- statement forms: `Defined {value: "Specified(1)", …}` (basic, extended,
  `asm goto`);
- labels: `Specified(3)`, `Specified(0)`, `Specified(2)`;
- file-scope: `t1.c:1:1: error: unexpected token after ';' and before 'asm'`.

These differences are the deliberate fork ≠ pristine differences of §4.

Row 1 (`scripts/test_unit.sh`, 7 min 59 s, rc 0):

```
Total: 16 passed, 0 failed
check_fork_drift: OK — layer 1: 87 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 4e70bb506d962355b7120260d4d176aa2850dcc3 matches lem -v lean-backend-v0.1.0-alpha.1-63-g4e70bb5 (hex prefix))
check_asm_refusal: selftest plant 'erase' caught: 18 failing witness(es)
check_asm_refusal: selftest plant 'lean-erase' caught: 10 failing witness(es)
check_asm_refusal: selftest plant 'refuse-all' caught: 16 failing witness(es)
check_asm_refusal: OK (9 cases: 4 asm statements (basic, extended, asm goto, uncalled function) refused by the oracle and the Lean engine with the attributed desugar message; 3 declarator asm labels (object, function, register) refused by the shared parser for --exec and --cabs-json; 2 controls agree with the oracle)
check_libc_float_literals: OK (24 float literals in tests/libc/libc.core = the register exactly; 1 LOSSY-N3)
```

Tier A (`python3 scripts/release.py --mode fast`):

First run (on the uncommitted tree; evidence `.tmp/release/20261005T033737.585415Z`, local):
all 17 rows PASSED (A1 387.8 s … A13 1.6 s), verbatim:

```
fast: incomplete; 17/17 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
```

The run was `incomplete` only because the tree changed during it. This record
was created, and two documentation-only corrections were made (the Tier C count
"six" → "five", in a manifest NOTE comment and in VALIDATION), so `report.json`
`source_after` differs from `source_before`. HEAD stayed `1001f3f2b`.

Clean rerun on the committed tree. Provisional commit `c896c3e95`, whose tree
differs from this commit's only in this record's Tier A paragraph; evidence
`.tmp/release/20261005T035925.230476Z`, local. All 17 rows PASSED (A1 308.1 s
… A13 1.6 s), verbatim:

```
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```

The orchestrator runs the full ladder.

## 7. Not done / open

- The Tier C scoreboard TSVs are not re-recorded. Five rows will move MATCH →
  reject at the next deliberate re-record (§2).
- Forms F5–F7 stay as upstream left them: loud, but not attributed (§1).
- The dated census record (`docs/2026-10-04_real-c-reach-census.md` §0/§4.5)
  still says the refusal is "a separate queued slice". It is a dated record and
  is left unedited; this record is its follow-up.
- Upstream tray: no draft. The refusal is the fork's contract, not a fix for
  upstream to take [AGENT].

## Pre-merge audit (2026-10-05, fresh read-only reviewer) — dispositions [AGENT]

No blocking findings; nothing fail-open; items 1–8 OK on substance, including the
host-header check (every lane preprocesses `-nostdinc -undef` with only the runtime
libc include dirs, so glibc's `__REDIRECT` `__asm__` labels never reach the parser).
- LOW-1 / LOW-2 (plants not asserting count / controls): FIXED in the witness
  script (exact counts; required control failures), re-planted as above.
- LOW-3 (Lean `--batch` names the location, not the feature): NOT CHANGED — it is
  the existing rendering for every desugar failure; the feature-attributed cause
  is printed without `--batch` and the oracle names it; CONTRACT D9 and VALIDATION
  §3(c) state this. A uniform attributed `--batch` refusal line belongs to the
  queued global controlled-outcome question ([USER 2026-10-05] on refusal shape).
- INFO-4, INFO-5, INFO-7: record corrected above. INFO-6: CONTRACT §4.1 wording fixed.
