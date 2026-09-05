# Upstream report drafts — index

> Cerberus developers: start with [README.md](README.md), the reader's guide to this directory.

Drafts of issue reports for `rems-project/cerberus`, from this project's
recorded findings. All cited file:line references verified against
upstream `master` @ `b9aeedcb4` (the merge base of our tree; every cited
OCaml file is byte-identical to it). **Filing is the operator's call** —
it needs a networked window and a GitHub account; nothing here has been
submitted. Report 07 is drafted for the record by default (see below).

Per operator directive [USER, 2026-08-19]: every report carries a
concrete proposed remedy and a classification (TRUE BUG / INTENDED GAP /
UNCLEAR) with justification; this ranking puts true bugs first and
questions last.

## Ranking (by upstream value)

1. **01-float-mul-is-addition.md** — TRUE BUG. `Cerb_floating.mul` is
   literally `(+.)` (util/cerb_floating.ml:5): every OCaml-side use of
   Lem-level float multiplication (defacto memory model) computes x+y.
   One-line fix proposed. **FILED as
   https://github.com/rems-project/cerberus/issues/1009** (operator,
   2026-08-19; open as of 2026-08-23, unfixed on master).
2. **02-pp-core-unparseable-forms.md** — TRUE BUG (conditional on
   round-trip intent). `--pp core` prints bodyless `proc` declarations
   the grammar cannot parse (and drops their return type), and
   `Cfunction(f)` values re-parse to null pointers (grammar TODO punt).
   Grammar production + `fun_ptrval` fix proposed.
3. **03-pp-core-ambiguous-output.md** — TRUE BUG (same conditionality).
   Unparenthesised `PEif` operands and layout-only `;`-sequences make
   `--pp core` output re-parse to a *different* tree, silently.
   Printer parenthesisation rules proposed.
4. **04-null-pointer-arith-crash.md** — INTENDED GAP (literal TODO), but
   crash-severity: `p + 1` on a null pointer crashes the tool with an
   uncaught `Failure` (impl_mem.ml:2217) instead of a UB verdict; the
   effectful sibling already does the right thing (`fail ~loc
   MerrArrayShift`, :2252). 6-line reproducer; interface-level remedy
   proposed.
5. **05-va-arg-missing-type-check.md** — INTENDED GAP (TODO at
   impl_mem.ml:2731), confirmed observable: our differential port shows
   the missing `va_arg` type check is load-bearing (adding it changes
   verdicts on programs that currently run). Check proposed, guarded or
   with a changelog note.
6. **06-funinfo-has-proto-question.md** — UNCLEAR / minor, framed as a
   question: `funinfo.has_proto` diverges between decl-TU and def-TU
   entries yet all 221 `cfunction`-tuple bindings in the libc dump bind
   it dead. Normalise or drop — upstream's call.
7. **07-symbol-identity-fragility.md** — UNCLEAR, question / **for the
   record only** by default: symbol equality ignores names and
   uniqueness rests on an implicit shared-global-counter invariant. Our
   observed collision required our own modification (0-based desugar
   supply), so unmodified upstream is not shown to misbehave — the draft
   says so explicitly and proposes documentation / a debug assertion /
   stream offsets (our 2^20 fix as evidence). File only if the operator
   wants the design question raised. [arc-12 update: the fork-side
   consequences are now measured at scale (margin 483, fork libc
   beyond it) and repaired by fail-stop — see cerberus-lean
   lean_frontend/docs/2026-08-21_arc12-renumbering-case.md; the
   upstream-facing question is unchanged.]

Added 2026-08-21 (arc-12 S3 — the F-A/F-B campaign findings, un-forked
repros re-verified against deps/cerberus-upstream @ b9aeedcb4 on this
date; slots between 01 and 04 in bug-value):

8. **08-desugar-nested-init-internal-error.md** — TRUE BUG. Nested
   braced initializers (3-D scalar arrays; a struct-nesting class)
   desugar to AilEinvalid and die as an uncaught internal-error
   exception (exit 125, OCaml backtrace) instead of a diagnostic;
   killed ~52% of csmith default-config programs in our campaign.
   Two minimized native-verified reproducers + two-level remedy.
9. **09-address-constant-member-rejected.md** — TRUE BUG. C11 §6.6p9
   address constants combining array subscript + member designator
   (`&arr[i].field` on static storage) rejected as "not a compile-time
   constant" while each designator ALONE is accepted (`&arr[i]` and
   `&obj.field` both run); clean 1-D fixture + two accepted controls
   isolating the composition boundary (revised per the arc-12 audit
   B-F3 — the earlier 2-D witness kept only as a secondary note, its
   nested initializer being near draft 08's class); remedy proposed.

10. **10-decode-rejects-question-escape.md** — TRUE BUG (arc-14). The
    C11 simple-escape `'\?'` (§6.4.4.4#4, value 63; gcc agrees) has no
    arm in `decode_character_constant_aux`, falls into the octal
    validator, and the tool dies on an uncaught `Failure` — a crash on
    strictly-conforming input. One-line remedy (+ the octal validator's
    `'8'` off-by-one noted). Repro verbatim 2026-08-22; decode.ml
    byte-identical to master @ b9aeedcb4.
11. **11-escaped-char-octal-roundtrip-corruption.md** — TRUE BUG
    (arc-14). `store_chars_in_array` round-trips every printf-stored
    char through `decode_character_constant (escaped_char c)`, but
    `Char.escaped`'s DECIMAL `\ddd` is read back by the OCTAL decoder:
    `snprintf("%c", 127)` stores 87 ('W'). Silent formatted-path data
    corruption; gcc (and our Lean port) return 127. Octal-emitting
    `escaped_char` remedy proposed. Repro verbatim 2026-08-22.

12. **12-bswap64-overflow-crash.md** — TRUE BUG (arc-14 re-mark).
    `__builtin_bswap64` starts with `Z.to_int64`, which RAISES
    `Z.Overflow` for every argument >= 2^63 — half the uint64_t domain,
    legal C — killing the tool with an internal error (gcc returns the
    swapped value). Z-native remedy proposed (also removes the signed
    Z.of_int64 result wart). Repro verbatim 2026-08-22; file
    byte-identical to master @ b9aeedcb4.

13. **13-memcmp-hugesize-overflow-crash.md** — TRUE BUG (arc-14 S4b,
    professor B'). `Concrete.memcmp` converts the C-controlled size with
    `Z.to_int` (impl_mem.ml:2660), which raises uncaught `Z.Overflow`
    for e.g. `memcmp(a, b, (size_t)-1)` — a tool crash where a UB
    verdict belongs (the checked per-byte load right below already
    produces the correct out-of-bound UB; our Lean port reports it).
    Z-native loop remedy + a `Z.to_int` family audit suggested (cf. 12).
    Repro verbatim 2026-08-22.

Added 2026-08-22 (arc/cn-differential — CN-tutorial warm-up lane S0):

14. **14-ailname-proxy-shadows-user-functions.md** — TRUE BUG. The Core
    stdlib claims plain C names via `[ailname = ...]` proxies (`read`,
    `write`, `open`, `stat`, ...) and translation.lem:245/:4317
    redirect ANY identifier of that name to the proxy WITHOUT checking
    whether the program defines its own function — a program-defined
    `read` is silently hijacked: ill-formed-program refusal under
    --nolibc, spurious UB038 wrong-arity with libc (gcc runs it fine;
    2-line repro). Hit 6/106 cn-tutorial exercises. Guarded-lookup
    remedy proposed. Repro verbatim 2026-08-22 vs upstream @ b9aeedcb4.

Added 2026-08-30 (parity-detective beyond-testset probe campaign +
gcc second-oracle lane — `lean_frontend/docs/2026-08-30_parity-detective-report.md`,
`…_gcc-oracle-lane-record.md`; repros re-verified against
deps/cerberus-upstream binary + runtime @ b9aeedcb4 on this date; NOT
covered by the 2026-08-23 duplicate search — search at filing time):

15. **15-bool-float-conversion-truncation.md** — TRUE BUG. Floating→
    `_Bool` conversion truncates BEFORE the §6.3.1.2#1
    compare-to-zero test (std.core:83 guards on the truncated `n`,
    not the floating value): `_Bool b = 0.5` yields 0 where every
    conforming compiler gives 1; non-finite operands crash the tool
    (uncaught `Z.Overflow` at impl_mem.ml:2554, exit 125) on
    defined-behavior C. Both our Lean port and the oracle agree
    (deliberately mirrored — the defect is in the shared Core
    stdlib); gcc gives the ISO value. One-branch std.core remedy.
    Repro `tests/parity-probes/probes/bool_conv.c`, verbatim
    2026-08-30.
16. **16-snprintf-truncation-return-length.md** — TRUE BUG.
    `snprintf` on truncation returns the truncated length
    (formatted.lem:799-801 returns `length cs'`, the `List.take
    (n-1)` list) instead of §7.21.6.5#3's would-have-been length;
    the `n = 0` path returns 0 without formatting. Inverts the
    standard's completeness test (`ret < n`) and breaks the
    two-pass sizing idiom; stored bytes + NUL are correct — return
    value only. Mirrored by our Lean port (both return 9 on the
    probe; gcc: 15). Repro
    `tests/parity-probes/probes/snprintf_trunc.c`, verbatim
    2026-08-30.

Added 2026-09-01 (effect-retirement arc close-out — the C1-F2
finding registered per the standing numbering-independence principle
[USER 2026-08-31]):

17. **17-diagnostic-embeds-symbol-id.md** — TRUE BUG (minor,
    diagnostic quality). The unknown-procedure diagnostic
    (core_run.lem:69) embeds the raw fresh-symbol counter value
    (`show psym`), making user-facing error text depend on symbol
    allocation history — non-reproducible under semantically-neutral
    renumbering (our libxml2-uri lane pins it modulo the id;
    upstream's own value differs from every fork's). Remedy: render
    the symbol description only in user-facing diagnostics.

Amended 2026-08-30: draft 08 gains reproducer 3 (2-D array of
struct, 3 lines, `probes/oracle_2d_struct_init.c` — the scalar 2-D
control works; measured as 58% of 320 fresh-seed csmith programs,
the dominant oracle-skip cause); draft 10 gains the gcc-lane
mechanical confirmation of the `\?` = 63 pin (`AGREE gcc=63
lean={63}` — the first oracle-independent referee for an
oracle-wrong pin).

## Other upstreams — `lean4/` subdirectory (added 2026-09-02, arc/mem-scale S0)

The tray above targets `rems-project/cerberus`. Reports for OTHER
upstreams live in per-target subdirectories with their own numbering,
same draft format (classification, verbatim evidence, remedy,
provenance note), same filing checklist and labeling policy:

- **lean4/01-stack-overflow-handler-deadlock.md** — target
  `leanprover/lean4` (runtime, `src/runtime/stack_overflow.cpp`). TRUE
  BUG, NOT FIXED as of nightly-2026-08-02: the stack-overflow `SIGSEGV`
  handler calls `pthread_getattr_np` (which mallocs / takes locks) before
  it writes anything, so an overflow whose deepest frame is inside glibc
  `malloc`/`realloc`/`free` — every Lean bignum operation — blocks the
  handler on the arena mutex forever: no "Stack overflow detected"
  line, no exit. STANDALONE REPRODUCER (2026-09-03): `lean4/repro/
  OverflowInMalloc.lean`, 28 lines, no dependencies, `lean -c` + `leanc`;
  control `PlainRecursion.lean` aborts loudly. Hangs on v4.28.0, v4.32.2,
  v4.33.0 and the nightly (matrix in the draft); mechanism first-hand from
  `strace -f -k` (`segv_handler → pthread_getattr_np → malloc →
  __lll_lock_wait_private` on `arena->mutex`), the same on our driver's
  original trigger (`tests/mem-scale-probes/probes/a_zero_global_10000000.c`,
  now secondary evidence). Remedy: record stack bounds per thread outside
  signal context; handler = loads + `write(2)` + `abort()`. Records:
  `docs/2026-09-03_lean4-runtime-repro-record.md` (experiments incl.
  negatives); `docs/2026-09-01_mem-scale-profile.md` §6.2–6.3 (original
  observation).

- **lean4/02-nat-div-mod-literal-folding.md** — target `leanprover/lean4`
  (elaborator/`Meta` literal folding). UNCLEAR, question with a standalone
  reproducer (`lean4/repro/DivModLiteralFold.lean`, no imports): `rfl`
  fails on `8 / f (k+1)` and `8 % f (k+1)` (and the `Int` division)
  although `f (k+1)` reduces to the literal `4` by `rfl` and `- * +`/
  `Nat.beq` fold on the same input — the `Nat.div`/`Nat.mod` literal fast
  path does not normalise its arguments first. Identical four errors on
  v4.28.0, v4.32.2, v4.33.0 and nightly-2026-08-02 (verbatim matrix in
  the draft). Found while proving a fuel-parametric theorem
  (`docs/2026-09-04_fuel-parameter-C1-record.md` §4.3); worked around by
  rewriting the divisor first. Added 2026-09-05.

Added 2026-09-02 (arc/mem-scale S1' — cerberus-side, upstream-facing):

18. **18-monadic-list-combinators-non-tail.md** — TRUE BUG
    (robustness). `ailErr_mapM` (`ail/errorMonad.lem:86-92`),
    `state_exception.lem` `sequence`/`foldrM`, `undefined.lem`
    `sequence` (and the same shape across the sibling monad modules,
    listed) recurse in NON-tail position of a function-typed monad:
    one stack frame per list element, reached from an N-element
    zero-initialised static aggregate via `cabs_to_ail_aux.lem:124` →
    `genTyping.lem:484`. Loud on OCaml with a bounded stack (exit 125,
    `Lem_list.replicate` backtrace), a silent hang on our Lean target.
    Suggested remedy: accumulate-and-reverse (effect order,
    short-circuit and result preserved — argued in the draft). Our
    fork PROTOTYPED and MEASURED it (8 M completes; 10 M still hangs —
    the residual frame is the Lean runtime's `lean_apply_*` entering
    closures by call) and REVERTED it [USER 2026-09-02] as poor ROI
    against trust-surface stability; the fork does NOT carry it.
    (Erratum 2026-09-02 [AGENT], audit M1: an earlier entry said
    "our fork carries it" — corrected.)

Added 2026-09-03 (probe/dynamic-addrs — the refined-cerberus consumer's
note `refined-cerberus/docs/2026-09-03_upstream-note-dynamic-addrs.md`,
reproduced on deps/cerberus-upstream @ b9aeedcb4 and on the fork; record
`lean_frontend/docs/2026-09-03_dynamic-addrs-investigation.md`):

19. **19-dynamic-addrs-never-cleaned.md** — TRUE BUG (memory-model
    soundness gap; low C exposure). The concrete model records dynamic
    allocations by ADDRESS (`dynamic_addrs`, impl_mem.ml:497; prepended
    :1433, never removed; `is_dynamic` = `List.mem` :661-663) and
    admits zero-size regions, so a `alloc(8, 0)` issued at the base of
    a live created object lets `free` of that AUTOMATIC object pass the
    dynamic check: no UB179a, `Specified(0)`; the object's later
    scope-exit kill then dies on an internal `failwith`. Core-level
    reproducer (both oracles verbatim, 2026-09-03); NOT reachable from C
    through malloc/aligned_alloc/realloc on any engine (argument
    temporaries, translation.lem:4435 — the draft says so). Our Lean
    port mirrors it (libc-injection instrument). Remedy: track dynamic
    allocations by allocation ID, not address (the note's two fixes
    assessed and shown not verdict-preserving as stated). Probes:
    `tests/noodle-probes/dynamic-addrs/`.

Added 2026-09-05 (the 2026-09-03 semantic-discrepancy probe campaign's
oracle-side findings — record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
probes `tests/noodle-probes/` — plus two findings of the 2026-09-03/04
seam audits; every reproducer re-run 2026-09-05 on deps/cerberus-upstream
@ b9aeedcb4, the fork's oracle @ 928aa1e76 and the Lean port, lines
verbatim in each draft; slice record
`lean_frontend/docs/2026-09-05_zero-discrepancy-Z4-docs-record.md`).
Unless a draft says otherwise, both Cerberus engines agree with each other
and gcc disagrees — the defect is in the shared model, not in our port:

20. **20-size-t-integer-rank-uac.md** — TRUE BUG. `size_t` (a macro
    `integerType` constructor) has no rank in `lt_integer_rank_ISO`
    (ailTypesAux.lem:527-529, the code's own "probably wrong for macro
    types" TODO), so the usual arithmetic conversions with `int`/`char`/
    `short`/`unsigned int` convert BOTH operands to `unsigned int`: values
    ≥ 2^32 are truncated (`n + 1` = 705032705 for n = 5000000000;
    `n == 705032704` is TRUE). Silent wrong values AND control flow; the
    largest class found. Remedy: rank the macro types through the
    implementation's alias table.
21. **21-provenance-lost-through-arithmetic-pvi.md** — TRUE BUG relative
    to the PVI model's evident intent / UNCLEAR if intended (framed as a
    question). `mk_conv_int`/`mk_wrapI` (core_eval.lem:29-46, :61-80)
    rebuild every arithmetic result as a provenance-free integer, so
    `(int*)((unsigned long)p + 4)` is UB043 under the default model
    although `op_ival` propagates provenance. Two-line remedy if intended.
22. **22-ptrdiff-strips-array-layer.md** — TRUE BUG. `diff_ptrval`
    (impl_mem.ml:1961-1967) strips one `Array` layer off the pointee type
    before dividing: `&a[2] - &a[0]` on `int a[3][4]` is 8, not 2. One
    `match` to delete (the elaboration already passes the pointee type).
23. **23-string-literal-init-of-char-array-members.md** — TRUE BUG. A
    string literal initialising a `char`-array ELEMENT or MEMBER
    (`char a[2][3] = {"ab","cd"}`, `struct{char c[3];} w = {{"ab"}}`) is a
    constraint violation: desugaring_init.lem:461-462 has the sub-aggregate
    case stubbed (`if false (* … string literal *) then internal_error
    "TODO: explode the elements"`). Ubiquitous idiom; remedy = the TODO.
24. **24-stdio-buffer-not-flushed-at-exit.md** — TRUE BUG. Neither return
    from `main` (driver.lem:1328-1333 `Step_done2` → `prepare_exit`, libc
    `exit` never entered) nor the shipped libc's `exit` (stdlib.c:223-227,
    no stream flush) flushes `FILE` buffers: `fputs("out", stdout);
    return 0;` prints nothing; `printf` proxies bypass the buffer (order);
    a `puts`-after-`putchar` loss recorded, not localised.
25. **25-atexit-not-run-on-main-return.md** — TRUE BUG. Same driver
    path: `atexit` handlers run on `exit()` but not on return from `main`
    (§5.1.2.2.3). Remedy: route main-return through libc `exit` when the
    libc is linked.
26. **26-printf-star-width-crash.md** — TRUE BUG (crash on legal input).
    `%*d`: the format parser accepts `*` (formatted.lem:113/119) but every
    consumer is a placeholder — `error "TODO: formatted.lem 6"` (:741-742),
    `assert_false "TODO: FW_asterisk"` (:253) — uncaught `Failure`, exit
    125. Remedy: consume the `int` argument.
27. **27-printf-hex-int-argument-ub153b.md** — TRUE BUG (over-strict).
    `%x`/`%X`/`%o` with an `int` argument → UB153b: the no-length-modifier
    arm demands exact type equality with `unsigned int`
    (formatted.lem:515-538) while the `l`/`ll`/`j` arms already accept
    either signedness. Remedy: accept the same-representation counterpart,
    then check representability by value (`%u` with -1 stays UB).
28. **28-conditional-in-static-initializer.md** — TRUE BUG. `static int
    a = (3 > 2) ? 10 : 20;` rejected "not a compile-time constant":
    `is_arithmetic_constant_expression` (cabs_to_ail.lem:794-843) has no
    `AilEcond` arm although `is_integer_constant_expression` (:727-740)
    does — so `?:` works in enum/array-size/case contexts and not in
    initialisers. One arm to add.
29. **29-string-literal-address-constant.md** — TRUE BUG (tray-09-
    adjacent). `static const char *s = "hello" + 1;` rejected:
    `is_address_constant` (cabs_to_ail.lem:894-925) has no string-literal
    arm; a bare literal is special-cased by the caller (:934-960), the
    literal-plus-offset form is not. One arm to add.
30. **30-strncmp-zero-length.md** — TRUE BUG (libc). `strncmp(s1, s2, 0)`
    compares one character (string.c:85-90: the `--n > 0` test follows the
    first compare); musl's ancestor has the check.
31. **31-calloc-overflow-check.md** — TRUE BUG (libc, minor). `calloc`
    has no `nmemb * size` overflow check (stdlib.c:125-134); C17 §7.22.3.2
    requires NULL. **ON HOLD before filing** [AGENT 2026-09-05]: the
    upstream evidence is re-verified, but our own three-engine record for
    the probe moved since it was first taken (the Lean column: out of
    memory → agrees with the oracle), so the draft is held for the
    operator's second look per the slice rule; the hold is stated in the
    draft's header.
32. **32-float-evaluated-as-double.md** — INTENDED GAP (literal
    `TODO:hack ==> 4`, ocaml_implementation.ml:206-208; permitted by
    §6.2.5#10) with a TRUE BUG on the consistency side: the shipped
    `runtime/libc/include/float.h:4` declares `FLT_MANT_DIG 24` for a
    `float` that has 53 bits and `sizeof(float) == 8`. Remedy: a binary32
    arm (M) or a consistent `float.h` (S).
33. **33-unspecified-operand-exceptional-condition-question.md** —
    UNCLEAR, question. `(x & 0) + 3` with indeterminate `x` is
    `UB036_exceptional_condition` at the `+` (translation.lem:2165-2171's
    signed catch-all "since the addition may overflow") while the `&`
    yields `Unspecified`; asks which reading (§6.3.2.1#2 UB at the read,
    or propagating unspecified values) is intended.
34. **34-aligned-alloc-zero-alignment-division-by-zero.md** — TRUE BUG
    (tool crash). `aligned_alloc(0, n)`: std.core:385 evaluates `size
    rem_t align` with no alignment check; `Concrete.op_ival IntRem_t` is
    `Z.rem` (impl_mem.ml:11, :2481-2482), unguarded where `IntDiv`
    (:2479-2480) is guarded — uncaught `Division_by_zero`, exit 125, on
    both oracles. Remedy: validate `align` in the proxy (C17: NULL) AND
    make Core `rem_t`/`rem_f` by zero a UB verdict. Found by the 2026-09-03
    memory-model seam audit (`docs/2026-09-04_zero-discrepancy-Z2-record.md`
    §2.1/§10.1; our port's total remainder diverges here and the divergence
    is held open pending the meaning being fixed upstream).
35. **35-pp-core-grammar-mismatches.md** — item 1 TRUE BUG (parser:
    `core_parser.mly:767-774` drops `seq_rmw`'s second operand on
    symbolification — re-reading a dump of `x++` turns the pointer into a
    dangling `case` expression; C-reachable witness verbatim); items 2-4
    TRUE BUG conditional on round-trip intent (as 02/03): the printer
    spells `Cfvfromint`/`Civfromfloat` (lexer: `Fvfromint`/`Ivfromfloat`;
    29 occurrences in the oracle's own libc dump), `wrapI_div`/`wrapI_rem_t`
    (not lexer keywords), `pcall(f, )`, `builtin f (bTys)` without `: eff`,
    `PtrMemberShift[s, m]` without the dot. Found by the 2026-09-03 Core
    text-parser seam audit (`docs/2026-09-03_zero-discrepancy-Z2-audit.md`
    §2.14, rows CP-09/10/15/21). Also notes a parser assertion failure on
    a user-file `builtin` declaration (core_parser.mly:961).

Amended 2026-09-05: draft 10 gains an addendum for the STRING-LITERAL
form of `\?` (`"\?"` reaches the same decoder from translation.ml:3029;
`tests/noodle-probes/ptr/ptr_string_literals.c`, upstream exit 125
verbatim; gcc and our port agree byte for byte) — the one-arm remedy
covers both entry points.

## Filed / duplicate-search status (2026-08-23, read-only gh session)

- **01 → FILED as issues/1009** (operator, 2026-08-19, open). Also filed
  outside this tray: **issues/1010** "Core binary-expression checker
  ignores the expected result type" (core_typing.lem:1025; operator,
  2026-08-19, open — no tray draft; finding predates the tray format).
- **Duplicate search (drafts 02-14): NO duplicates found** — 2-4 keyword
  variants each, issues + PRs, open + closed. Near-misses checked and
  ruled distinct: #198 (pointer-byte repro, not 04), #97 (fn-ptr struct
  init, not 08), CN memcmp/multidim issues (not 13/08).
- **Related, cite when filing:** #154 (open, 2020) — escape-sequence
  char-constant VALUE semantics; same code region as 10/11, different
  defect. #370 (closed) — lexer crash on `\e`; precedent that
  crash-instead-of-diagnostic on escapes is bug-classed upstream.
- **Master spot-check (2026-08-23):** cerb_floating.ml mul still `(+.)`,
  bswap64 still `Z.to_int64`-first, decode.ml still missing the `'\?'`
  arm and still using `escaped_char` — drafts 01/10/11/12 all still live
  on current master.
- Caveat: GitHub search is text-match; a very differently-worded
  duplicate could hide. Re-run step (2) at actual filing time.
- **Drafts 15–35 and lean4/02 have NOT been duplicate-searched** (no
  network window since 2026-08-23); step (2) is mandatory for each at
  filing time. Likely neighbours to check: anything on `size_t`/integer
  rank (20), `aligned_alloc` (34), `atexit`/stdio flushing (24/25),
  `printf` format checking (26/27), and the Core parser (35).

## Near-at-hand audit around the PR branches (2026-08-23)

Each PR branch's code neighborhood was audited for adjacent defects
that should roll into the same PR. Result: all three branches are
complete as scoped; the audits are recorded in each branch's
PR-DESCRIPTION.md. Specifics (probes run against the local
deps/cerberus-upstream build @ b9aeedcb4):

- ocaml_gcc_builtins.ml (bswap64 PR): `ctz` has the same `Z.to_int64`
  opening but is UNREACHABLE with 64-bit args — only `__builtin_ctz`
  (unsigned int, zero-guarded in the std.core proxy) maps to it; no
  `__builtin_ctzl/ctzll` exists upstream. bswap16/32 args pre-bounded
  (asserts intentional); generic_ffs pure-Z. No rollups.
- decode.ml (char-escapes PR): all other C11 simple escapes have arms;
  hex validator correct; `encode_character_constant`'s `Z.to_int` gets
  only char-range values (callers checked: formatted.lem:375/:617,
  core_run.lem:1017, core_reduction_aux.lem:49). No rollups.
  NEW FIND: upstream OPEN issue #154 ('\xFF' should be -1, signed
  char) appears ALREADY FIXED by the current wrapI — probe
  `('\xFF' == -1)` returns Specified(42)=true at b9aeedcb4. Courtesy
  note drafted into the PR description; #154 may be closable.
- impl_mem.ml (memcmp draft 13, future PR): REFUTED the IntExp
  suspicion — `Z.pow n1 (Z.to_int n2)` at :2490 ("TODO: fail properly
  when y is too big?") is defended: shifts by 64 and by 2^62 both give
  `Undefined {ub: "UB51b_shift_too_large"}` BEFORE IntExp evaluates
  (verbatim probe outputs, 2026-08-23). The remaining Z.to_int sites
  are sizeof-driven and carry upstream's own TODO comments (known
  gap). memcmp stays the only C-value-controlled crash site → draft 13
  remains a correctly-scoped standalone PR.

## Standard-citation validation pass (2026-08-23, trust-surface grade)

Every semantically relevant claim on the three PR branches was
validated against primary evidence. Authority: Cerberus's own embedded
N1570 text (`tools/n1570.json` — the copy the tool's UB machinery
cites), cross-checked with gcc 's actual behavior and the GCC/Zarith
documentation online. VERIFIED (evidence in parentheses):
- `\?` accepted by the C lexer (c_lexer.mll:417); value 63 (gcc run:
  exit 63); simple-escape grammar §6.4.4.4#1; representability #3-4.
- Octal escapes: ≤3 digits + maximal munch (#1 grammar, #7); all 0344
  boundary expectations pass under gcc -std=c11 -Wall; `'\377' ==
  (char)0xff` matches #10's char-object-converted-to-int rule.
- `%c` stores the int arg converted to unsigned char (§7.21.6.1#8);
  0343 compiles AS WRITTEN under gcc (builtin declaration included)
  and passes; `Char.escaped` decimal rendering confirmed empirically
  ("\\127", "\\129"), 0o127=87 corruption arithmetic checked.
- bswap64: GCC docs give `uint64_t __builtin_bswap64(uint64_t)`, NO
  domain restriction (full-domain-legal claim exact); repro exit 8
  under gcc; all 5 test vectors verified by independent computation;
  Zarith `signed_extract`/`extract`/`to_int64` semantics verified
  from docs AND empirically via the project switch (the fixed
  pipeline reproduces every expected value). `__builtin_ctz(0)`
  documented undefined by GCC — proxy undef verdict correct.
- pp-roundtrip: no ISO citations; semantic-preservation evidence is
  the differential lanes already in its PR description.
DEFECTS FOUND AND FIXED (2 citations, char-escapes): "#4 lists the
simple escapes" (the list is #1's grammar) and "octal-digit ...
(§6.4.4.4#1)" (production is §6.4.4.1#1). Fixed in PR-DESCRIPTION.md,
the decode.ml comment, and the 0342/0344 headers; the octal commit's
message reworded in the same pass. Surgery (autosquash + reword)
operator-approved and executed 2026-08-23 — final tree verified
byte-identical at each step, trailers intact — and force-pushed
(--force-with-lease) to OathTech. char-escapes head: da993e5a0.

## Provenance labeling policy ([USER 2026-08-23])

The Cerberus team requires AI-derived code to be labeled as such. For
everything filed from this tray:
- ISSUE and PR bodies carry an explicit AI-provenance note (pattern:
  the "Provenance" section now in each PR-DESCRIPTION.md; issue-side
  precedent: #1009's "Bug detected by Claude Fable" line).
- COMMITS carry `Co-Authored-By: Claude ... <noreply@anthropic.com>`
  trailers. Status: ALL THREE branches conform. pp-roundtrip's 14 code
  commits were rewritten 2026-08-23 with operator approval (never
  pushed, so safe) to add generic `Claude` trailers — generic because
  the authoring model session is not attestable; commits whose
  authoring session is known use the specific model name.
- The CODE ITSELF stays clean and idiomatic to the surrounding style —
  no AI-generation residue in comments or structure. (Audited
  2026-08-23: all three branches' diffs conform.)

## Filing checklist (operator; needs network + GitHub)

For each draft, in ranking order (10, 11, 12, 13, 14, 15, 16, 20, 23, 22,
24, 25, 27, 28, 30, 26, 34, 19, 18, 08, 09, 29, 31 [ON HOLD, see above],
17, 02, 03, 35, 04, 05, 32, 21, 33, 06; 07 on request; 01 done — 20–35
slotted 2026-09-05 [AGENT]: the silent-wrong-value bugs on common idioms
(20, 23, 22, 24, 25, 27, 28, 30) and the two crashes on legal input (26,
34) with the true-bug tier ahead of the Core-level 19; 29 and 31 with the
minor true bugs; 35 with the pp-round-trip pair 02/03; 32 (intended gap)
and the two questions 21/33 with the question tier; 17 and 18 slotted
2026-09-02 [AGENT]: 18 (true bug, robustness) with the true-bug tier,
17 (minor, diagnostic quality) with the minor tier; 19 slotted 2026-09-03
[AGENT] with the true-bug tier after 16 — a soundness gap, but Core-level
only, so behind the C-reachable ones): (1) re-verify the repro against CURRENT upstream master
(ours is pinned at b9aeedcb4); (2) search the upstream issue tracker
for duplicates; (3) file with the draft's title, repro, verbatim
output, classification and remedy sections; (4) record the issue URL
back into the draft's header and this index; (5) apply the provenance
labeling policy above (AI note in the body; trailers on commits). F-D (symbol collisions)
is NOT filed — fork-side, repaired by fail-stop; the upstream-facing
design question stays draft 07.

## Evidencing caveats (honesty notes)

- 01: found by code audit; not executed through an upstream
  defacto-model build (data flow is direct and unconditional).
- 05: the "adding the check would change behaviour" claim rests on the
  arc-6 decision-log D11 record and the S2 mirror-port corpus results,
  not on a preserved side-by-side run with the check enabled.
- 07: reclassified during drafting from "upstream-reportable" (arc-4 D6)
  to record-only/question after verifying the colliding stream was
  introduced by our commit 8923d6436 — see the provenance footer there.
