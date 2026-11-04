# The macro integer types get their implementation rank (tray 20; cerberus-caesium filing 05) — slice record (2026-11-04)

Branch `fix/macro-type-ranks`, worktree `worktrees/cerberus-lean-fix/macro-type-ranks`, from mainline
`mdd/cerberus-lean` = `a126c9f39` (merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`); charter
`docs/2026-11-04_worker-charter-macro-type-ranks.md` (commit `05db564bc`). Worker: Claude Fable 5.1 (agent). Every
judgement below that no operator ruling covers is marked [AGENT]. Status: **fixed in the shared Lem (both engines by
generation), witnessed in row 1, every moved row dispositioned with gcc as the referee; Tier A green on M1 (after the
two libc rows of §4.3 were dispositioned) and on M2 (§6.2); the full battery at close-out is the orchestrator's (§6.3,
appended after the run).** The charter's premises held with the corrections of §0 (the `long long` rows, CHERI, the
manifest row, reachability, the pins, the register).

## 0. Rulings and standing rules

- [USER 2026-11-04] approved the fix as proposed: a fork fix of an upstream mistake, mirrored on both engines by
  generation, registered as a fork-ahead delta of the first kind (the fork's own fix, filed upstream — tray 20), the
  filing for the operator to send. The bar for fork fixes (the container's working-practices doc): only where the
  standard's intent is very clear or a consumer is genuinely blocked; here both hold (C17 6.3.1.1#1: a typedef has the
  rank of its type; 7.19#2: `size_t` is an unsigned integer type; cerberus-caesium's libxml2 `xmlBufShrink` refinement
  blocked, their filing 05 at `e416f83f4`). The fork invents no semantics: every judgement call in the mechanism is
  refused or filed, not decided. The vicinity rule [USER 2026-11-04]: a true bug is a symptom of an under-developed
  feature; the fix covers the mechanism, the neighbouring cases are probed and fixed under the same clear-standard
  reading, refused, or filed.
- [AGENT 2026-11-04, orchestrator] rulings on the worker's first report, each applied: (1) the two `long long` rows are
  added to the ISO table (the standard's top rank; they answer exactly what the catch-all answered for the `long long`
  pairs, which reach it — `usual_arithmetic_integer`'s bullets call `lt_integer_rank` on EQUAL promoted types, and
  `(Enum e, Enum e)` in the typing — so a loud catch-all without them would have crashed `long long + long long`); (2)
  the normalisation and the loud catch-all apply OUTSIDE CHERI only; upstream's CHERI path keeps its bare constructors
  and its silent `false` (`intptr_t` is a capability type there, its rank rule is upstream's, CHERI is unexercised in
  this fork); (3) `ailTypesAux.ml` ENTERS the fork-drift manifest's `[expected-semantic]` section (it was byte-identical
  to pristine before: the fork's earlier edits to that lem file were Lean-target declares outside the OCaml output),
  layer 2 moving 32 → 33; (4)-(7) the matrix split by reachability, every Core-text re-pin recorded with old/new hash and
  the diff summarised, the failure-reach register as the gate decides, the `size_t op long long` typing residual
  recorded as upstream's judgement and not fixed. The true-bug audit's Set A probes (`.tmp/truebug-audit/`, 2026-11-04,
  read-only) joined the matrix as required witnesses (the `ptrdiff_t` asymmetry, the compound assignments).
- [AGENT 2026-11-04, orchestrator] M1 accepted as read, the libc re-pin pulled forward into M1 included (§4.1); the 21
  negative-`wchar_t` store crashes belong to filing 62's crash-to-refusal slice, named here, not touched; the `intptr_t`
  typing finding (§3.3 F4) is filed, not fixed. M2 accepted as read: the replacement N4 witness (the unterminated
  `strlen`) accepted; the two register rows cite this record.
- Mirror doctrine holds by construction (one `.lem` change, both engines generated from it; the generated texts read
  against the pristine tree and the mainline's generated trees, §2.4). Fail-closed: the catch-all is a loud `error`
  where upstream answered `false`. No hand-written seam or proof module changed, no fuel form, so neither the
  kernel-replay gate of [USER 2026-10-18] nor the fuel-parametricity pin set moves.
- Precedents followed for the witness and the record: D12 (`docs/2026-10-26_anonymous-members-refusal-record.md`) and
  D13 (`docs/2026-10-29_compound-assignment-refusal-record.md`); for the libc re-pin and the pristine register, the
  merge-base bump stage 1 record (§2b.4, §5.3).

## 1. The defect, as it stood (both engines; pristine `c3ff8c53f` agrees)

`frontend/model/ail/ailTypesAux.lem` at pristine `c3ff8c53f`: `eq_integer_rank` (:455-457, structural equality or
`eq_integer_rank_base`), `lt_integer_rank` (:459-541) whose `lt_integer_rank_ISO` ranks `_Bool`, the chars, `short`,
`int` and `long` and ends in `| _ -> (* TODO: this is probably wrong for macro types *) false` (:527-529). Cerberus keeps
`Size_t`, `Ptrdiff_t`, `Wchar_t`, `Wint_t`, the `Intptr_t`/`Intmax_t`/`IntN_t`/`Int_leastN_t`/`Int_fastN_t` families and
`Enum` as their own `integerType` constructors, so a macro-typed operand matched no rank arm and both comparisons said
"not less, not equal". In the Core translation's `usual_arithmetic_conversion_aux` (`translation.lem` :1414-1477) the
pair (`size_t`, `int`) therefore failed every rank bullet and reached the last resort (:1466-1472), which converts both
operands to `unsigned int` whenever `all_values_representable_in(size_t, int)` is false: `size_t` arithmetic and
comparisons against the `int` family computed at 32 bits, and so did every other macro type's. The Ail type checker's
own `usual_arithmetic_integer_default` (:673-722) has NON-STD `Size_t`-wins and `Intptr_t` arms ahead of the bullets
(:676 prints `NON STD: usual_arithmetic_integer ==> if any operand is of type size_t, then the common type is size_t`
under `-d`), so the typing said `size_t` while the translation narrowed — which is why cerberus-caesium's clone
(RefinedC's typing) and the driver disagreed. `Implementation.normalise_integerType` (`implementation.lem`; OCaml
`Ocaml_implementation.normalise_integerType`, Lean `CerberusImpl.normalise_integerType`, a reader consumer over the enum
map) already knew the aliases; `le_integer_range` and `are_compatible` used it, the rank functions did not.

Measured on this tree before the change (`--nolibc --exec --batch`, the fork oracle and pristine identical; gcc 13.3.0
`-std=c11 -w -O0` the referee), verbatim stdout:

```text
tray 20's tests/noodle-probes/int/int_size_t_uac_rank.c:
  cerberus 705032705 1410065408 352516353 5000000001 705032705 705032705 1 705032705 705032705   gcc 5000000001 10000000000 2500000001 5000000001 5000000001 5000000001 0 5000000001 5000000001
the consumer's three (return values):  x == 0 -> 1 (gcc 0);  0 != x -> 0 (gcc 1);  (x > 0) + 2*(x + 0 == x) + 4*(x * 1 == x) -> 0 (gcc 7)
int + ptrdiff_t, ptrdiff_t + int, int < ptrdiff_t, ptrdiff_t > int (d = 2^33, i = 1):  cerberus 1 8589934593 0 1   gcc 8589934593 8589934593 1 1
wchar_t + long, long + wchar_t, wchar_t < long (w = 1, l = 2^33):                     cerberus 1 8589934593 0     gcc 8589934593 8589934593 1
ptrdiff_t < unsigned long, unsigned long > ptrdiff_t, d + u (d = -1, u = 1):          cerberus 1 1 0             gcc 0 0 0
enum + unsigned long (e = 2, ul = 2^33), _Generic(+e, int:1, unsigned:2):             cerberus 2 2               gcc 8589934594 2
size_t ip = -1; ip+1 > 5; ip+1; l-ms-1; l|63 (l = 7, ms = 5):                         cerberus 1 4294967296 1 63  gcc 0 0 1 63
size_t v = 1<<57; !v, v == 0, v != 0, v ? 1 : 0, !w, w && 1 (w = 5):                  cerberus 1 1 0 1 0 1       gcc 0 0 1 1 0 1
```

The last two rows are the shapes the C library trips on (§4.3): `SIZE_MAX + 1` was `2^32`, not 0, and `!x` on a
`size_t` — elaborated as `x == 0` under the usual arithmetic conversions with `int` 0 — was true whenever the low 32
bits were zero. The audit's six differing Set A probes (`rank_size_t_int`, `rank_size_t_ops`, `rank_size_t_compound`,
`rank_ptrdiff_t_int`, `rank_ptrdiff_unsigned`, `rank_wchar`) are in the witness set with their gcc lines.

## 2. Design

### 2.1 The Lem (`frontend/model/ail/ailTypesAux.lem`; the two rank functions only)

```lem
val rank_operand: integerType -> integerType
let rank_operand ity =
  if Global.is_CHERI () then ity else Implementation.normalise_integerType ity

let eq_integer_rank ity1 ity2 =
  let ity1 = rank_operand ity1 in
  let ity2 = rank_operand ity2 in
  ity1 = ity2 || eq_integer_rank_base ity1 ity2

let lt_integer_rank ity1 ity2 =
  let lt_integer_rank_ISO ity1 ity2 =
    match (ity1, ity2) with
    (* … upstream's rows through (Unsigned Long, Unsigned _) -> true, untouched … *)
    | (_, Signed LongLong) -> false
    | (_, Unsigned LongLong) -> false
    | _ ->
        if Global.is_CHERI () then false   (* upstream's TODO reading, kept for CHERI only *)
        else error "AilTypesAux.lt_integer_rank: unranked integer type after normalisation"
    end in
  let ity1' = rank_operand ity1 in
  let ity2' = rank_operand ity2 in
  if Global.is_CHERI () then
    match ity1 with
    | Signed Intptr_t -> false | Unsigned Intptr_t -> false   (* upstream's CHERI special case, bare constructor *)
    | _ -> lt_integer_rank_ISO ity1' ity2'
    end
  else
    lt_integer_rank_ISO ity1' ity2'
```

`le_integer_rank`, `ge_integer_rank`, `eq_integer_rank_base`, `integer_promotion`, `usual_arithmetic_integer_*`,
`le_integer_range` and `translation.lem` are untouched. Normalisation maps `Size_t → Unsigned Long`, `Ptrdiff_t → Signed
Long`, `Wchar_t`/`Wint_t → Signed Int_`, `Intptr_t`/`Intmax_t → Long`, the `IntN_t` families by width (8/16/32/64 only;
`__cerbty_int128_t` is the pre-existing `Option.get` crash on both engines, Z2-I-03), an `Enum` to its compatible type
(6.7.2.2#4, through the enum map), and leaves `Char`, `Bool` and `Ptraddr_t` fixed; `eq_integer_rank_base`'s `Char`
rows therefore still hold. Consequences by construction: `integer_promotion` now promotes `wchar_t` to `int` and an
enum to its compatible type (6.3.1.1#2; `_Generic(+w, int: 1)` is 1 on gcc too); the `__cerbty_int8_t`-style direct
spellings promote to `int`; `ptrdiff_t`, `size_t` and the `Intptr_t` constructors keep their explicit arms.

### 2.2 Why the two `long long` rows (orchestrator ruling (1))

The charter said that after normalisation only the standard types reach the catch-all; `long long` and `unsigned long
long` reached it already — the table had no `LongLong` rows, and `(long long, long long)`, `(unsigned long long, long
long)`, `(long long, unsigned long long)` answered the correct `false` by falling through. `usual_arithmetic_integer_
default` calls `lt_integer_rank` on equal promoted types without an equality test (so does `(Enum e, Enum e)`), and the
translation's `ty1' = ty2'` test is before the bullets only there. The two rows say what the standard says (6.3.1.1#1:
`long long` has the greatest rank) and answer exactly what the catch-all answered for those pairs; after them the
catch-all is reached outside CHERI only by `Ptraddr_t` (CHERI-specific, not an alias; `le_integer_range` already
`error`s on it) and by a future constructor — hence loud.

### 2.3 CHERI (orchestrator ruling (2))

Normalising unconditionally would change CHERI answers: `Intptr_t` as the second operand would rank as its Morello
alias (`LongLong`), `eq_integer_rank (intptr_t, unsigned long long)` would become true, `unsigned long long + intptr_t`
would convert to `unsigned long long` instead of `uintptr_t`; keeping bare constructors under CHERI with a loud
catch-all would crash `e + e` (two enums). So under CHERI `rank_operand` is the identity, the special case stays on the
bare `ity1`, and the catch-all stays `false`: every CHERI answer is upstream's. The fork never runs CHERI (Lean
`CerbGlobal.is_CHERI` is the build constant `false`; the oracle's `SW_CHERI` is never passed by a lane and the Lean
driver refuses every switch but `PNVI_ae_udi`). The filing says so and leaves `intptr_t`'s CHERI rank to upstream.

### 2.4 The generated delta (read against `CERB_UPSTREAM_TREE` and the mainline primary checkout's generated trees)

OCaml: `ocaml_frontend/generated/ailTypesAux.ml` only — `rank_operand`, the two bodies (`Switches.is_CHERI ()`,
`Ocaml_implementation.normalise_integerType (Ocaml_implementation.get())`, `Cerb_debug.error`), the two rows; no
signature change, no other file. Lean: `AilTypesAux.lean` — `rank_operand` is a new reader consumer, so lem's lifting
gives it, `eq_integer_rank`, `lt_integer_rank`, `le_integer_rank` and `ge_integer_rank` the two leading parameters
`_lemReader_enum_definitions _lemReader_tagDefs`; their callers already hold them, so the rest is argument passing at
the 1 + 3 + 3 call sites of `integer_promotion` / `usual_arithmetic_integer_CHERI` / `_default`; the catch-all renders
`lem_if CerbGlobal.is_CHERI () then false else (failwithI "…" : Bool)`; `Translation.lean` — the three call sites of
`usual_arithmetic_conversion_aux` inside `translate_expression_lemFuel` (binders confirmed at :2176). `diff -rq` over
both trees: no other file. Lem-sync stamps re-recorded (src `3095f9e7…`, gen `744879c1…`).

### 2.5 What is deliberately left: the typing's NON-STD arms

`usual_arithmetic_integer_default`'s `(Size_t, _) -> Size_t` and `Intptr_t` arms are upstream's deliberate reading
(commented `NON-std`, under the TODO "we need to add a type alias mechanism"), and the consumer's RefinedC parity rests
on the typing as it is; they are untouched. Two consequences remain, both measured and filed in tray 20's related
findings, neither a value error of the rank mechanism: (a) `size_t op long long` / `unsigned long long` is TYPED
`size_t` where gcc says `unsigned long long`, and `intptr_t op unsigned long` / `long long` is typed `intptr_t` — the
values agree at 64 bits, only `_Generic` sees it (11 of 483 matrix programs; the witness pins the fork's codes as a
declared residual, `residual_size_t_llong_typing`); (b) with a signed `Intptr_t` arm the sum is typed `intptr_t` but
computed unsigned, so `intptr_t a = 5; unsigned long b = 2^64-6; a + b` is `UB036_exceptional_condition` on pristine,
before and after (gcc `18446744073709551615`): a pre-existing false UB, unchanged by the fix (`gap_intptr_t_unsigned_
false_ub036`, pinned). The consumer's alternative (copying the typing's `Size_t`-wins arms into the translation) was
not adopted: it fixes the `int` case but hard-codes a non-standard rule for `size_t` against `long long`, where the
standard's answer (`unsigned long long`) is what the normalised bullets now give.

## 3. The vicinity

### 3.1 The matrix (the instrument `.tmp/vicinity/gen.py` + `run.py`, deleted at slice end)

483 programs, each UB-free by construction, every value printed as `%llu` of `(unsigned long long)` so a 32-bit
narrowing shows, plus `_Generic` type codes (typing findings, not pinned): one program per (macro type, partner,
order, variant) for the primary macro types reachable through the shipped headers (`size_t`, `ptrdiff_t`, `wchar_t`
from `<stddef.h>`; `intptr_t`, `uintptr_t`, `intmax_t`, `uintmax_t` from `<stdint.h>`) and the two enums (compatible
`unsigned int` / `int`) against `_Bool`, `char`, `signed char`, `unsigned char`, `short`, `unsigned short`, `int`,
`unsigned`, `long`, `unsigned long`, `long long`, `unsigned long long` and the two enums, variants `pos` (the macro
operand at `2^32+5`, or `2^31`-safe for 32-bit types; partner 3), `bneg` (partner `-3`), `aneg` (macro operand `-5`),
through `+ - * / % & | ^ == != < <= > >= << >>` (both positions), the conditional operator and every `op=` in both
directions; the direct `__cerbty_*` spellings (the `IntN_t`/`Int_leastN_t`/`Int_fastN_t` families at 8/16/32/64,
unreachable through `<stdint.h>`, which `#define`s `FIXED_STDINT` and typedefs `int8_t`… as standard types; `wint_t`
is `short` in the shipped `<wchar.h>`, so `Wint_t` is unreachable from C) against a reduced partner set; promotion
probes (`+x -x ~x`, shifts, `sizeof`); 47 controls (the cluster K probes, tray 20's reproducer, the consumer's three,
the audit's 30 Set A probes, the four measured siblings). Referees: gcc 13.3.0, pristine `c3ff8c53f`, the pre-change
fork oracle (a snapshot of the binary and the runtime taken before the rebuild; its `libc.co`/`libc_inner_arg_temps.co`
rebuilt with that binary from `runtime/libc` and verified — their dumps equal the committed pre-fix pins
`f8560811…`/`06a1f84c…` exactly), the rebuilt oracle, the rebuilt Lean engine on the rebuilt oracle's Cabs JSON.

### 3.2 Results (derived from `results.json`)

- Values disagreeing with gcc: pristine and before 196 of 483; after **0 on every program both sides complete**; Lean
  equal to the oracle on every row (the 21 rows where their canonical lines differ are both-crash rows rendered
  differently, `CRASH(125)` vs `CRASH(-6)`).
- Non-`Defined` after: 21 rows — every `wchar_t` row with a negative value stored into a `wchar_t` object (`aneg`, and
  `bneg`'s `t *= b`-style stores) — both engines crash at the store (`bytes_of_int(signed), i= 4294967291, nbits= 32`,
  the oracle's `impl_mem.ml` assert, the mirrored `CerbMem.intToBytes` stop): filing 62's class (the implementation's
  unsigned range against a signed representation), pre-existing, unchanged; the `bneg` rows moved there from a false
  `UB036_exceptional_condition` because the arithmetic is now done in `int`. 2 rows: F4 (§2.5(b)).
- Typing-only disagreements (values equal): 11 rows, all §2.5(a).
- Two instrument defects found by the sweep and fixed before these numbers: the snapshot's `cp -a` had copied the
  install tree's relative symlinks (every `before` run rejected); the generator's `t <<= 3` on a 32-bit left operand
  was a genuine UB052b that gcc merely wraps, and gcc cannot compile the `__cerbty_*` spellings (a `#ifndef __cerb__`
  typedef block).

### 3.3 Findings

| # | finding | class | disposition |
|---|---|---|---|
| F1 | the rank mechanism: `size_t`, `ptrdiff_t` (asymmetric before: `n + i` right, `i + n` narrowed), `wchar_t`, the enums, the `Intptr_t`/`Intmax_t` families and the `__cerbty_*` spellings, in both orders, every operator and `op=`, `%`, `|`, `^`, `?:`, the comparisons, `SIZE_MAX + 1`, `!x` / `x == 0` on a `size_t` | silently wrong (values and control flow); the same clear-standard reading | FIXED (§2); witnessed (§3.4) |
| F2 | a negative value stored into a `wchar_t` object crashes both engines (21 matrix rows; `wchar_t w = -1`) | crash on legal input, filing 62 | not this mechanism; the queued crash-to-refusal slice ([AGENT 2026-11-04, orchestrator]); gap control pinned |
| F3 | `size_t`/`intptr_t` against `long long`/`unsigned long`/`unsigned long long` typed by the NON-STD arms | typing residual, values equal | upstream's judgement, left; filed as tray 20's related finding; the fork's codes pinned |
| F4 | `intptr_t` against an unsigned 64-bit partner: a false UB036 when the unsigned result exceeds `INTPTR_MAX` (`intptr_t a = 5; unsigned long b = 2^64-6; a + b`; `-5 * 3ul`), pristine/before/after identical, gcc defined | false UB from the NON-STD `Signed Intptr_t` typing arm against the (now standard) conversion | filed (tray 20 related finding; TODO); pinned as a gap control |
| F5 | `tests/parity-probes/uncertainty/E-wchar_t/wt-06-sizeof-signedness.c`: `(wchar_t)-1 < 0` was 0, is 1 (14 = gcc) | the survey's IMPL-DEF row now agrees with gcc (`wchar_t` promotes to `int`, its alias) | survey table annotated; not gated |
| F6 | inside the C library: two-way `strstr`'s `ip+1` (§4.3), `strcspn`/`strspn`/`strpbrk`'s set loop `!BITOP(…)` (§4.3) | the same mechanism, through libc | fixed by generation; rows 016/015 moved |

### 3.4 The witness (`scripts/check_macro_type_ranks.sh`, row 1; `tests/macro_type_ranks/`, 104 programs)

One DENSE program per (macro type, variant) covering every partner in sequence (45: the 9 primary types' `pos`/`bneg`
and the signed ones' `aneg` — `wchar_t`'s `aneg` excluded, a negative store, F2 —, the 24 `__cerbty_*` families'
`pos`), 9 promotion probes, the 47 controls, the gap control `gap_wchar_t_negative_store` (both engines crash, tray 62),
the F4 gap control `gap_intptr_t_unsigned_false_ub036` (both engines `UB036`, rc 1) and the typing-residual control
`residual_size_t_llong_typing` (the fork's `_Generic` codes `10 10 9 9 9`; gcc `12 12 10 11 12` in the comment). Every
other row is pinned to gcc 13's line (`expected.txt`, derived 2026-11-04) and both engines must print it byte for byte
with equal exit codes (the oracle's exit is 0 for `Defined`, 1 for `Undefined`); `pristine.txt` carries pristine's
pre-fix lines (52 of 104 differ: the negative control). Five plants on a 10-program subset, counts derived in the
script: `pristine-pair` 16, `lean-pristine` 8, `lean-fixed` 10, `oracle-rc` 17, `expect-tamper` 2. Cost: a dense
program 0.97 s on Lean, 0.29 s on the oracle; the self-test and real run together ≈ 60 s. Verbatim:

```text
check_macro_type_ranks: selftest plant 'pristine-pair' caught: 16 failing check(s) (= expected 16; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-pristine' caught: 8 failing check(s) (= expected 8; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-fixed' caught: 10 failing check(s) (= expected 10; incl. the required programs)
check_macro_type_ranks: selftest plant 'oracle-rc' caught: 17 failing check(s) (= expected 17; incl. the required programs)
check_macro_type_ranks: selftest plant 'expect-tamper' caught: 2 failing check(s) (= expected 2; incl. the required programs)
check_macro_type_ranks: OK (104 programs: every batch line of both engines = gcc 13's pinned line, exit codes equal — the dense per-type matrices (every standard partner and both enums, both operand orders, every operator and op=, positive and negative values) for size_t, ptrdiff_t, wchar_t, intptr_t, uintptr_t, intmax_t, uintmax_t and the two enums, the promotion probes, the direct __cerbty_* families, tray 20's reproducer, the consumer's three programs, the audit's Set A probes, the four measured siblings and the cluster K controls; 52 of them moved from pristine's pre-fix lines; the negative wchar_t store still crashes both engines (tray 62, unchanged); the intptr_t-against-unsigned false UB036 (the upstream NON-STD typing arm, filed) and the size_t/intptr_t-against-long-long typing codes are pinned as the declared residuals)
```

Two script defects the self-test caught before the counts above held: an exit-forcing plant that also broke the
`--cabs-json` export (now delegated, as the refusal scripts' stubs do), and a merged `2>&1` capture — the Lean driver's
stdout is block-buffered, and its stderr line (`cerberus-lean switches: []`) landed inside batch lines longer than 4096
bytes (the dense programs'); the engines' two streams are captured separately now.

## 4. Moved rows and pins (gcc the referee)

### 4.1 The libc Core and the pins it carries (pulled into M1: Tier A row A5 checks the libc pin — the bump's §2b.4 precedent [AGENT 2026-11-04])

`dune build cerberus.install` restaged both libc objects under the new elaborator; `scripts/libc_prep.sh --record`
re-derived the dumps: `tests/libc/libc.core` `f8560811…` → `fae6ce64…` (89639 → 88739 lines, 1352 raw changed lines),
`libc_inner_arg_temps.core` `06a1f84c…` → `45eaac23…`; every change is one shape — the 247 `if
all_values_representable_in('size_t', 'signed int') then conv_int('signed int', a) else conv_int('unsigned int', a)`
conditionals on a `size_t` operand → 0, each collapsed to `conv_int('size_t', a)` (the sample hunk: `wrapI_sub('size_t',
conv_int('size_t', a_5004), conv_int('size_t', a_5005))`); the bare-name census registers unchanged. The float-literal
register `scripts/libc_float_literals.txt` re-derived by line with the script's own census (every literal relocated by
−571/−598 lines; the 24-literal multiset and order unchanged). CoreQuote libc pins `core-quote-libc.sha256` `90d09e84…`
→ `dc09e554…`, `-inner-arg-temps` `b7e2711e…` → `4c9f5e69…` (`test_unit.sh --core-quote-libc`: `Total: 2 passed, 0
failed`, every leanchecker leg exit 0). `tests/verify` and `tests/corpus` Core pins: 0 of 41 move (measured).

### 4.2 The manifest

`scripts/fork_drift_manifest.txt`: `[source-content]` `ailTypesAux.lem` `e1ac560d…` → `e278a3f6…`;
`[expected-semantic]` `ailTypesAux.ml` ENTERED at `52804c6c…` (22 → 23 rows; layer 2: 32 → 33 differing files); a dated
header NOTE registering the fork-ahead delta; no `--refresh`. Gate + self-test, verbatim: `check_fork_drift: OK — layer
1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files,
all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f
matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))`; `check_fork_drift: SELFTEST OK (31 plants …)`;
`check_pin_sites: OK — lem-pin … at every site`.

### 4.3 The table (both engines agree before and after; pristine `c3ff8c53f` gives the before-lines)

| row | lanes | before | after | gcc/glibc | disposition |
|---|---|---|---|---|---|
| `tests/libc_exec/016-strstr-twoway-oob.c` | A5 (`LOC_ONLY` → `MATCH`), A15 (`LOC_ONLY-FIRST` → `AGREE-FIRST`), Tier B row 10 (new difference) | `Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<265:22--265:26>"}`; Lean the same UB at `<unknown location>` | `Defined {value: "Specified(10)", stdout: "", stderr: "", blocked: "false"}` | 10 | **mechanism:** `twoway_strstr`'s `size_t ip = -1; … if (ip+1 > ms+1) ms = ip;` — `ip+1` is a (`size_t`, `int`) pair the old table narrowed to `unsigned int`: `SIZE_MAX + 1` came out as 4294967296 (probed; gcc 0), the test held, `ms` became `SIZE_MAX`, and `memcmp(n, n+p, ms+1)` read 2^32 bytes past the needle (the proc's Core: 23 hunks, 46 conditionals removed). Baseline `MATCH`; its `dispositions.txt` line retired as a dated comment; the inner_arg_temps row re-recorded (`lean`/`oracle` `2d38bc36310e`); register row `shared-model-fix` with pristine's UB quoted |
| `tests/libc_exec/015-strchr-strstr.c` | A15 (hash `90bcc96c53cc` → `e6f41a22018b`, both engines), Tier B row 10 (new difference); A5 `MATCH` unchanged (its baseline pins classes only) | stdout `2 21 10 0 9 9 18 15 1 9 15 17` | `… 15 16` | `… 15 16` | **mechanism:** `strpbrk(h, "yx") - h` → `strcspn` builds its byte set with `do { if (!BITOP(byteset, *c, |=)) break; c++; } while (*c);` and `!` on the `size_t` value is `== 0` under the usual arithmetic conversions with `int` 0, narrowed: `!((size_t)1 << 57)` was 1 (probed; gcc 0), so the loop stopped after the set's FIRST character — `"yx"` became `{y}` (found at 17), `"xy"` `{x}` (right by luck), `"-y"` `{-}` (right by luck); `strspn`'s `for (; *c && BITOP(…, |=); c++)` likewise. A silently wrong value both engines agreed on. The inner_arg_temps row re-recorded from a whole-lane `--record-baseline` into scratch (exactly the three rows of this table moved; the lane's file applied); register row with pristine's stdout quoted |
| N4's witness | A5, A15 | 016 carried `LOC_ONLY` / `LOC_ONLY-FIRST` | 016 is `MATCH` | — | **replacement:** `tests/libc_exec/042-strlen-unterminated-loc.c` (`char a[4] = "abcd"; strlen(a)`): oracle `UB_CERB002a … loc: "<357:9--357:11>"` (the load in musl's `strlen` loop), Lean `<unknown location>`; `LOC_ONLY` with a dated `dispositions.txt` line, inner_arg_temps `LOC_ONLY-FIRST` with the lane's own disposition text; VALIDATION N4 and TODO's transport item point at it. [AGENT 2026-11-04], accepted: an over-long `memcmp` was tried first and does not exercise N4 (a memory-model builtin carries the call's own location) |
| `tests/noodle-probes/int/int_size_t_uac_rank.c` | none (tray 20's probe) | tray 20's line | gcc's line | — | not gated |
| `tests/parity-probes/uncertainty/E-wchar_t/wt-06-sizeof-signedness.c` | none (survey cluster E) | `Specified(4)` | `Specified(14)` | 14 | F5; the survey row annotated |

### 4.4 The sweeps (the instrument `.tmp/sweep/sweep.py`, deleted at slice end)

- Core-diff sweep: every `.c` of every corpus a lane walks (7204 files: `tests/` apart from csmith, the 1669 csmith
  programs materialised as the lane does, `lean_frontend/corpus`, the CN corpus `deps/cn/tests/cn`, the pKVM census
  TUs with the PNVI lane's flags), `--nolibc --pp=core` before/after → 160 candidates whose own Core changed → executed
  before/after in their lane's mode: `SUMMARY files=7204 candidates=160 moved=2` (the two non-gated rows of §4.3;
  csmith 0 candidates; `libc_exec`, `immaculate/libc` 0 candidates — their programs' own Core is unchanged).
- libc-mode exec sweep (the library's change is invisible to a Core diff of the program): every file of the libc-mode
  corpora executed before/after with the rebuilt pre-change `libc.co` under the snapshot (3457 files: gcc-torture 2858,
  tcc, suite, hacl-star, freebsd, examples, cheri-ci, `immaculate/libc`, the PNVI litmus suite, `libc_exec`):
  `moved=1` (016). Limitation: the sweep ran `--mode=exhaustive`, under which 015 exceeds the 60-second bound on both
  sides (`RC124` both, so unseen there); the lanes run it in batch mode, where it moved (§4.3). The ci-sweep scoreboard
  suites: 0 rows move (so nothing is named for the next deliberate re-record).

### 4.5 The lanes run on the M2 tree (verbatim last lines)

```text
SUMMARY: match=42 loc_only=1 diff=0 / ALL MATCH RECORDED BASELINE                                   (test_libc_exec.sh; --selftest: SELFTEST OK (8 plants))
SUMMARY: inner_arg_temps rows=187 AGREE=138 AGREE-FIRST=41 BOTH_FAIL=5 LOC_ONLY-FIRST=1 RESOURCE oracle:KILL=2 failures=0   (test_inner_arg_temps.sh --gate; SELFTEST OK)
Independent oracle scope: tier-b; 1000 rows in 192.0s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 952, 'reviewed_difference': 16, 'matching_failure': 30, 'interface_agreement': 2}
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
Independent oracle scope: libxml2_chvalid; 4 rows in 406.8s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 4}
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each) / ALL PASSED                      (test_libxml2.sh, Tier B row 1)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH …)   (test_immaculate.sh, Tier B row 5)
```

(The first tier-b run, before the two register rows existed, reported `difference: 2` — exactly 015 and 016; a
chvalid run during which the inner_arg_temps baseline was edited reported `source unchanged: False` and was repeated
with the tree held.)

## 5. Register entries

- **Fork-drift manifest:** §4.2. **Pristine-difference register** (`scripts/upstream_oracle_differences.json`): two
  `shared-model-fix` rows, `libc_exec/015-strchr-strstr.c` and `libc_exec/016-strstr-twoway-oob.c`, pristine's wrong
  stdout / UB quoted, signatures computed with the lane's own diagnostic projection; 14 → 16 reviewed rows.
- **Failure-reach register:** no new row — the new `failwithI` in generated `AilTypesAux.lt_integer_rank` is outside the
  exec dependency closure (the gate: `check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly
  …)`, the mainline's count). **Fuel forms:** unchanged (88 workers); **fuel-parametricity pins:** unchanged (17).
- **Pins:** §4.1. **Baselines:** `tests/libc_exec/baseline.txt` (016 `MATCH`, 042 `LOC_ONLY`), `dispositions.txt`
  (016 retired as a comment, 042 added), `tests/inner_arg_temps/baseline.json` (015, 016, 042).
- `CONTRACT.md`: D14 and the §4.1 witness list; `VALIDATION.md`: the §3(c) bullet, the fork ≠ pristine inventory entry
  (2 register rows), the §6 gate-table row, N4's row; `SUPPORTED.md`'s Domain row; `scripts/LADDER.md` row 1;
  `TODO.md`; tray 20 rewritten as the filing (the patch of §2.1 against `c3ff8c53f`, cerberus-caesium's translation-side
  analysis merged and credited), the INDEX row; the survey record's cluster K and wt-06 rows annotated; the
  outcome-protocol migration map's inventory line for the new `error` site; the consumer notes
  `docs/2026-11-04_consumer-note-cerberus-caesium-macro-type-ranks.md` and `…-cerberus-sl-….md`.

## 6. Gates

### 6.1 M1 (`9b15a1f69`): the focused gates (§4.1, §4.2 and the following, verbatim)

```text
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=175 REACHABLE=42 UNKNOWN=21; every row sealed; tally line consistent)
gen_fuel_parametricity: OK (17 ambient fuel wrappers in the generated tree = the 17 pins of TotalityProofTest.lean Part 1, both directions)
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (…), 13 ABSORBING = kill at zero (…), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 8 ambient unreachable from the drive cone)
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_exec_purity: CLEAN (11 modules)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lakefile_roots: OK (228 roots = 228 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
libc_prep: OK (libc: pin + regenerated dump == fae6ce64003959c9d58456fcaedf1a294d4038cbf2b4b3a82fd3d118dba3acd0, 4149038 bytes)
libc_prep: OK (libc_inner_arg_temps: pin + regenerated dump == 45eaac239cb319b89d0b24fdd6c4745ec90bc23578bb3b18c553430804054e07, 4004859 bytes)
check_libc_float_literals: OK (24 float literals in tests/libc/libc.core = the register exactly; 1 LOSSY-N3)
Ran 26 tests in 2.419s / OK                                  (test_stops.py --lean-bin …/stop-test)
SUMMARY: total=9 match=9 … mismatch=0 fail=0 crash=0 …      (test_exec.sh, the cluster K probes)
SUMMARY: total=47 match=47 … mismatch=0 fail=0 crash=0 …    (test_exec.sh, the 47 controls — every value gcc's)
Build completed successfully (413 jobs). / Build completed successfully (150 jobs).   (capped lake build CerberusLean cerberus-lean stop-test; speclab)
```

Tier A on `9b15a1f69` (orchestrator-run, evidence `.tmp/release/ranks-fast-m1-20261104T202609Z`, 20:26:09 to 20:58:43
UTC, start load 0.26), verbatim: `fast: failed; 18/20 selected commands completed successfully.` / `Source unchanged:
True. Complete tier selection: True.` / `release rc=1` — A5 `DRIFT from recorded baseline` with the one row
`-016-strstr-twoway-oob LOC_ONLY` / `+016-strstr-twoway-oob MATCH`; A15 `inner_arg_temps: FAIL — libc/015-strchr-strstr:
baseline changed: {'class': 'AGREE-FIRST', … 'oracle': '90bcc96c53cc'} -> {'class': 'AGREE-FIRST', … 'oracle':
'e6f41a22018b', …}`; every other row PASSED. Both are the C library's own `size_t` arithmetic moving (§4.3), dispositioned
in M2.

### 6.2 M2 (`5dd549e54`): §3.4, §4.5; Tier A (orchestrator-run) — appended after the run

Run by the orchestrator on `5dd549e54` (`scripts/ce python3 scripts/release.py --mode fast`, evidence
`.tmp/release/ranks-fast-m2-20261104T221415Z`, 22:14:15 to 22:47:40 UTC, start load 0.20), verbatim:

```text
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
release rc=0
```

All 20 commands PASSED (A5 and A15 included, on the re-recorded rows of §4.3). The full battery on the M3 tip (§6.3)
is the orchestrator's, with a fresh reviewer in parallel; its lines are appended by the close-out commit after the run.

### 6.3 The full battery at close-out (appended after the run)

Run by the orchestrator on the M3 tip; its lines are appended by the close-out commit after the run.

## 7. Not done / open

- The typing's NON-STD `Size_t`/`Intptr_t` arms (§2.5): the residual type codes and the false UB036 are filed in tray
  20's related findings and named in TODO; not fixed here (upstream's judgement; the consumer's RefinedC parity).
- A negative value stored into a `wchar_t` object (F2): filing 62's queued refusal; the 21 matrix rows and the gap
  control document the boundary.
- CHERI: upstream's rank reading kept verbatim (§2.3); whether `intptr_t` should normalise there is upstream's call
  (the filing asks).
- The declared limitation N4 keeps its statement with a new witness (042); the Core-text transport slice stays queued.
- `test_gcc_oracle.sh --check-baseline` (Tier B row 7) was not run by the worker; it is the full battery's.
- The ci-sweep scoreboard TSVs: nothing moves (§4.4), so no re-record is pending from this slice.
- The vicinity sweep's exhaustive-mode bound (60 s) hid 015 from the libc-mode sweep (§4.4); the lanes saw it.
- Tray 20 stays Draft (fixed in the fork; the filing is the operator's network window).

## 8. Scratch, deleted at close-out

`.tmp/oracle-before/` (the pre-change oracle, its runtime with the rebuilt libc objects, the two pre-fix dumps),
`.tmp/vicinity/` (the generator, the runner, 483 + 102 programs and their outputs), `.tmp/sweep/` (the instrument, the
csmith stage, the two result sets), `.tmp/rows/`, `.tmp/wit/`, `.tmp/iat/`, `.tmp/drafts/`, `.tmp/probe0/`,
`.tmp/logs/`, 423 M (304 M of it the pre-change oracle snapshot) — deleted by the close-out commit's author after it was applied; the lanes' capture scratch
under `.tmp/scripts/observations` is the orchestrator's.
