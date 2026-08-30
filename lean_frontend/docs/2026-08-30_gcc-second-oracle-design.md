# gcc second-oracle differential lane — design note (2026-08-30)

Status: design for `scripts/test_gcc_oracle.sh` (reporting-tier lane,
NOT wired into any gating battery — gating status is an operator
decision at merge). Written BEFORE implementation, per the slice
charter. Decisions herein are [AGENT] unless marked otherwise.

## 1. Why a second oracle

Every existing differential lane (VALIDATION.md §1-2) compares the
Lean port against the OCaml Cerberus built from the SAME `.lem`
sources. That is the deliberate design — it validates the port — but
it has a known blind spot: a bug in the shared Lem model is invisible
to every lane, because both sides inherit it (single-oracle
circularity; the upstream three-way instrument narrows but does not
close this, since upstream is still the same model family).

This lane adds the first witness that is independent of the entire
Cerberus lineage: **gcc 13.3.0 (x86-64 linux-gnu) compiled native
execution**. For a program whose behaviour is fully determined by the
C standard plus implementation-defined choices on which Cerberus and
gcc agree, the native exit status and the Lean semantics' verdict
must coincide. A confirmed disagreement is either a shared-source
semantics bug (the headline class this lane exists to catch), a gcc
bug, or a comparability-criteria violation — never routine noise.

## 2. Comparability criteria — when is the check meaningful?

### 2.1 The observation channel

The lane's sole comparison observable is the **process exit status**:
the low byte of `main`'s return value (C11 §7.22.4.4/5 via the
implicit `exit(main(...))`; POSIX truncates to 8 bits). The Lean side
reports `Specified(n)`; the expected native exit is
`((n mod 256) + 256) mod 256`.

Consequences, all deliberate:

- **stdout is NOT compared.** The standing exec corpora are `--nolibc`
  (no printing is possible on the Lean side — test_exec.sh header),
  while a native binary links real glibc. A program that produces
  native stdout is outside the modeled observable and is skipped
  (`SKIP_GCC_STDOUT`), not silently accepted.
- **mod-256 aliasing.** Two differing values congruent mod 256 compare
  equal. This is a sensitivity limitation, not a soundness one: it can
  hide a disagreement, never fabricate one. (The csmith checksum is
  already reduced to its low byte by `platform_main_end` in
  `tests/csmith/csmith_cerberus.h`, so nothing is lost there.)
- **argv is aligned to the modeled convention**: Cerberus supplies
  `argv = ["cmdname"]` when no `--args` are given; the native binary
  is invoked via `exec -a cmdname` so argv[0]-observing programs
  compare meaningfully instead of diverging on environment input
  (found during triage of `tests/minimal/076-main-argv-access.c`:
  native argv[0] is otherwise the binary path). No further env,
  locale, signals, or filesystem: programs exercising those are
  outside the lane (they surface as skips or triaged rows, never as
  silent passes).

### 2.2 Determinism / definedness requirements

A comparison point is **meaningful** iff:

1. **No UB in the semantics' verdict.** If any enumerated execution is
   `Undefined`, native execution is unconstrained by the standard —
   the file is `SKIP_UB` (UB-in-test). The lane therefore says nothing
   about the UB-detection half of the semantics (§6).
2. **No unspecified values.** `Unspecified(_)` verdicts → `SKIP_UNSPEC`.
3. **Order-independence of the outcome.** The Lean `--batch` runner is
   exhaustive over unsequenced-evaluation interleavings. If all
   enumerated executions yield one value, any conforming
   implementation must produce it (strong check, `AGREE`). If the
   enumerated values differ, gcc's result must be a **member** of the
   set (weaker check, `AGREE_ND`, counted separately). For the csmith
   tier the Lean side runs single-trace `--first` (§5.2) and
   order-independence is assumed from csmith's by-construction
   guarantee; a violation surfaces as a DISAGREE and is triaged D4.
4. **Native reproducibility.** Native runs execute with ASLR disabled
   (`setarch -R`, ADDR_NO_RANDOMIZE — process-scoped, no global
   state): address-observing programs are otherwise only
   luck-deterministic, which would make their rows oscillate between
   nondet-skip and disagree across runs. With ASLR off they produce a
   stable deterministic value that still differs from Cerberus's
   abstract allocator addresses — landing them stably in triage class
   D2/ADDR. The binary is additionally run twice as a backstop; a
   residual exit-status difference is `SKIP_NATIVE_NONDET`.
5. **Implementation-defined choices aligned** — per the table below;
   programs whose result flows through a DIVERGENT row are expected
   D2 triage cases, not agreements.

### 2.3 Implementation-profile alignment table

Cerberus side: `DefaultImpl` in
`ocaml_frontend/ocaml_implementation.ml` (the driver default; the
Lean mirror is `lean_frontend/CerberusImpl.lean`) plus the Core-level
profile `runtime/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl`
(the driver's default `--impl`, backend/driver/main.ml:359). gcc
side: gcc 13.3.0, x86-64 linux-gnu, default flags (no `-funsigned-char`,
no `-fshort-enums`).

| Choice | Cerberus (cite) | gcc 13.3 x86-64 linux | Aligned? |
|---|---|---|---|
| `char` signedness | signed (`char_is_signed:true`, ocaml_implementation.ml:257) | signed | YES |
| short/int/long/long long | 2/4/8/8 (ocaml_implementation.ml:173-196) | 2/4/8/8 (LP64) | YES |
| pointer size/align | 8/8 (:104-122) | 8/8 | YES |
| `size_t` / `ptrdiff_t` | `unsigned long` / `signed long` (:169-170) | same | YES |
| `wchar_t` / `wint_t` | `signed int` (:167-168) | `int` (width 4) | YES |
| `intptr_t`/`intmax_t` | `long` (:165-166) | `long` | YES |
| enum underlying type | gcc rule: `int` iff a negative enumerator, else `unsigned int`; no `-fshort-enums` (:128-142) | same | YES |
| integer representation | two's complement, no padding (.impl:7) | same | YES |
| signed narrowing conversion | reduce mod 2^N, no signal (`wrapI`, .impl:15-19) | same (gcc docs: "reduced modulo 2^N") | YES |
| `>>` on negative signed | sign extension (.impl:38-41) | sign extension | YES |
| `~` on signed | two's complement (.impl:43-46) | same | YES |
| `sizeof(float)` | **8** ("TODO:hack ==> 4", ocaml_implementation.ml:206-208); float arithmetic modeled at binary64 | 4; binary32 arithmetic | **DIVERGENT** |
| `sizeof(long double)` | **8** (:211-212) | 16 (x87 80-bit) | **DIVERGENT** |
| `max_alignment` | **8** (:151-152) | 16 (`max_align_t`) | **DIVERGENT** |
| allocation addresses / object layout | abstract concrete-allocator addresses | native layout + ASLR | **DIVERGENT by nature** |

The three DIVERGENT width rows mean: programs whose observable result
depends on `float`-width arithmetic precision, `long double`, or
`max_align_t` may disagree without indicting anyone. They are not
pre-filtered (pre-filtering by grep is fail-open guesswork); they run,
and a disagreement is triaged D2 with a per-file justified ledger
entry (§4). tests/float is included deliberately: its 62 `float`-typed
programs are exact-representable-value tests that should agree anyway,
and any that don't become documented D2/FLOAT rows.

## 3. Mechanism

Per program (all inside the worktree; scratch under `.tmp/`):

1. **Native side.** `gcc -O0 -w -o <bin> <file.c>` (csmith tier adds
   `-I <stage>`), compile timeout enforced. Run under `timeout`
   (default 5 s) + `ulimit -v`, twice (§2.2.4), capturing exit status
   and stdout. `timeout`'s kill report (exit 124) collides with a
   program legitimately calling `exit(124)` — found live on the csmith
   corpus (checksum byte 124); the harness disambiguates by elapsed
   time, and the residual edge degrades to a visible skip, never a
   silent misclassification. Compile failure → `SKIP_GCC_COMPILE`; run timeout →
   `SKIP_GCC_TIMEOUT`; nonempty stdout → `SKIP_GCC_STDOUT`. A native
   **signal** death (exit ≥ 128) while the Lean side says `Defined`
   is NOT a skip — it is a DISAGREE (a defined program must not
   crash).
2. **Lean side.** Cabs JSON via the in-repo OCaml frontend
   (`--cabs-json`, exactly as test_exec.sh — the C parser is on the
   declared trust boundary, VALIDATION.md §5), then
   `cerberus-lean --batch` (exhaustive) or `--batch --first` (csmith
   tier), `LEAN_ABORT_ON_PANIC=1`, per-side timeout. Verdict-token
   extraction and exit/verdict-consistency checking mirror
   test_exec.sh (S5f hardening); any Lean-side failure is
   `SKIP_LEAN_{FAIL,CRASH,TIMEOUT,EXIT}` — enumerated, never compared.
3. **Compare.** Expected-byte set from the `Specified(n)` tokens vs
   the native exit status: singleton+equal → `AGREE`; member of a
   larger set → `AGREE_ND`; else → `DISAGREE` (fatal in default mode
   unless carried by the triage ledger, §4).
4. **-O2 spot tier.** Every Nth file (default stride 10) that compared
   at -O0 is additionally compiled `gcc -O2 -fno-strict-aliasing -w`
   and re-compared (recorded as a third baseline column). Rationale
   for `-fno-strict-aliasing`: the Cerberus concrete memory model does
   not implement effective-type (TBAA) restrictions, so the UB filter
   cannot exclude aliasing-UB programs; letting gcc exploit TBAA would
   produce disagreements attributable only to UB the semantics cannot
   see. Restricting -O2 to the intersection both sides model keeps the
   tier meaningful. No `-fwrapv`: signed-overflow UB IS flagged by the
   semantics (exhaustive tier) or excluded by csmith's `safe_math`.

Exit-code discipline (house rules): no `set -e`, every failure path
explicit; a processed-files/status-lines count mismatch is a harness
error; **zero comparisons is a failure, not a vacuous pass**;
`--write-baseline`/`--check-baseline` with rank-based regression
semantics mirroring test_exec.sh.

## 4. Divergence taxonomy and triage

Any `DISAGREE` triggers this procedure (STOP-on-first-confirmed for
class D1 during baseline establishment — report prominently, do not
keep accumulating):

- **D1 — real semantics bug** (headline class). Established by
  elimination: reproduce; minimize (creduce or by hand); run the
  OCaml oracle on the reproducer (three-way attribution: OCaml
  agreeing with Lean ⇒ shared-source candidate — the class this lane
  exists for; OCaml agreeing with gcc ⇒ Lean-port bug, which the
  standing lanes should have caught — check them); verify the
  reproducer is UBSan/ASan-clean (`gcc -O0 -fsanitize=undefined,address`)
  and gcc-consistent at -O0/-O2; then read the reproducer against
  C11. Confirmed ⇒ stop, report, file.
- **D2 — implementation-defined divergence.** The differing value is
  traced to a DIVERGENT row of §2.3 (float width, long double,
  max_alignment, address/layout observation). Triage: name the row,
  show the dependence, record a `TRIAGED_ADDR`/`TRIAGED_FLOAT`
  ledger entry with the rationale. Neither side is wrong.
- **D3 — UB in the test that the verdict did not flag.** UBSan/ASan
  or manual reading finds UB, yet the semantics said `Defined`.
  Sub-triage matters: (a) UB the Cerberus memory model *deliberately*
  defines (documented model choices) → `TRIAGED_UB` with the cite;
  (b) UB the semantics *should* flag but missed → that is itself a
  semantics finding (a UB-detection gap) — report it like D1, do not
  ledger it away.
- **D4 — unspecified-evaluation-order dependence** (csmith `--first`
  tier only; the exhaustive tier enumerates all orders, so D4 there
  would mean incomplete enumeration = D1). Triage: rerun the file
  through exhaustive `--batch` with a generous timeout; if the gcc
  value is a member of the full set → `TRIAGED_ORDER` (and note the
  csmith order-independence assumption failed for this file).

**The triage ledger** (`scripts/gcc_oracle_triage.txt`) is fail-closed
in both directions: every entry names its class and rationale; the
harness applies an entry only to a file whose *current* status is
DISAGREE (a stale entry — listed but no longer disagreeing — is a
fatal error, so fixed divergences force ledger cleanup); an unlisted
DISAGREE stays fatal.

## 5. Corpus selection

Target: several hundred meaningful comparison points from
deterministic-by-construction programs, zero generation variance
(fully reproducible lane).

### 5.1 Exhaustive tier (Lean `--batch`, full ND enumeration)

| Corpus | Files | Why |
|---|---|---|
| `tests/minimal` | 106 | the canonical exec lane (85 MATCH / 18 UB_MATCH vs oracle) — UB rows become SKIP_UB honestly |
| `tests/debug` | 90 | alignment/alias/compat probes — the expected D2/ADDR triage exercisers |
| `tests/float` | 69 | float lane (69/69 MATCH vs oracle); exercises the DIVERGENT float rows deliberately |
| `tests/immaculate/nolibc` | 19 | the grumpy-audit pins, incl. rows where gcc already served as informal referee (g5 `\?` = 63, escape-roundtrip 127 — baseline header cites); this lane makes that referee mechanical |

(`tests/immaculate/{argv,libc}` are out: argv injection and libc
linkage are outside the v1 observable — corpus-level exclusion,
documented here, not per-file ledger rows.)

### 5.2 csmith tier (Lean `--batch --first`, single trace)

The 1,669 in-tree csmith programs (`tests/csmith/small_int_arith` +
`small_arrays` + `small_mix`), staged with the standard
`CSMITH_MINIMAL`/`csmith_cerberus.h` substitution and `sia_`/`sa_`/
`smx_` prefixes exactly as `test_csmith_corpus.sh`. Csmith programs
are UB-free and order-independent by construction — the classic
instrument for exactly this differential — and the corpus is in-tree
(deterministic, no generation variance; a fresh-generation tier is
deliberately omitted from v1 for that reason).

`--first` instead of exhaustive is a measured necessity: exhaustive
interleaving enumeration on csmith-sized expressions blows up (spike:
`sia_csmith_001` >60 s exhaustive vs **0.078 s** `--first`, verdict
`Specified(18)` = the gcc exit). Cost of `--first`: single-trace UB
filtering and the D4 assumption (§2.2.3, §4). Runs sharded with
checkpoint logs (box courtesy + grind discipline).

## 6. What this lane does and does NOT establish

Mirroring VALIDATION.md §5 — the claims supported are exactly:

1. On every `AGREE`/`AGREE_ND` row, the Lean semantics' defined-value
   verdict coincides (mod 256) with gcc-compiled native execution —
   a witness **independent of the shared `.lem` model, the OCaml
   oracle, the Lem compiler, and the Lean toolchain**. This is the
   first lane for which "both sides inherited the same bug" is not a
   possible explanation of agreement.
2. Every non-compared file is enumerated with a classified reason
   (the baseline is the skip ledger; no silent skips), and every
   tolerated disagreement carries a per-file justified triage entry.

It does NOT establish:

- **Anything about UB verdicts.** UB rows are skipped by
  construction; the lane validates only the defined-behaviour half of
  the semantics. (The oracle-differential lanes remain the instrument
  for UB-code agreement.)
- Full-value agreement — the observable is one byte (mod-256
  aliasing, §2.1); nor stdout/IO behaviour (not modeled here).
- Conformance of either side: gcc is itself a fallible artifact
  (miscompilations exist); a disagreement indicts *someone*, and the
  D1 triage's three-way + sanitizer + standard-reading steps do the
  attribution. Agreement is evidence, not proof.
- Coverage beyond the corpus: differential testing samples; it never
  proves equivalence.
- csmith-tier order-independence is assumed (by csmith's design
  guarantee), not enumerated.

The lane is **reporting-first**: its baseline is a committed
scoreboard (Tier-C style, scripts/LADDER.md), and wiring it into any
gating battery is an operator decision at merge, not this slice's.
