# The constant-expression predicates accept every §6.6 form the standard lists (tray 09, 28, 29; audit §4 items 7, 16, 17) — slice record (2026-11-07)

Branch `fix/address-constants`, worktree `worktrees/cerberus-lean-fix/address-constants`, from mainline
`mdd/cerberus-lean` = `1e5f2cbca` (merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`); charter
`docs/2026-11-07_worker-charter-address-constants.md` (commit `b58eabf4d`). Worker: Claude Fable 5.1 (agent). Every
judgement below that no operator ruling covers is marked [AGENT]. Status: **fixed in the shared Lem (both engines by
generation), witnessed in row 1 (244 programs), every moved row dispositioned with gcc 13 `-std=c11 -pedantic-errors`
as the referee; the focused gates of §6 green on the M1, M2 and review-fix trees; Tier A and the full battery are the
orchestrator's (§6.3, a marked placeholder).** The charter's premises held with two corrections (§2.6: the caller's
sequencing, and the GNU `?:`); the pre-merge review (`docs/2026-11-07_address-constants-premerge-review.md`, with its
Dispositions section) found the fix accepting four 6.6#10 forms pristine did not (P1-1) and ruled the accepted set back
to upstream's plus the 6.6#3-#9 forms (§2.7).

## 0. Rulings and standing rules

- [USER 2026-11-04] agreed the fix pass in the audited order under the standing bar: a fork fix only where the
  standard's intent is very clear or a consumer is blocked, no invented semantics, the vicinity rule (a true bug is a
  symptom of an under-developed feature: the fix covers the mechanism, the neighbouring cases are probed and fixed
  under the same clear-standard reading, refused, or filed). [USER 2026-11-07] dispatched this slice in parallel
  with two others; nothing outside this slice's mechanism is touched, every shared-document edit is an appended entry.
- The charter's M1 text (orchestrator [AGENT 2026-11-07]): extend the three predicates with exactly the forms
  C17 6.6#3-#9 list and nothing else; the comma operator REJECTED as the constraint violation with upstream's
  diagnostic; every arm cites its clause; where a form's status under 6.6 is a judgement call (6.6#10) do not
  accept it — leave upstream's rejection and record the question; the predicate must not accept what the standard
  rejects, gcc's `-pedantic-errors` verdicts measured and pinned, a form gcc accepts under 6.6#10 only not a model.
- [AGENT 2026-11-07] decisions inside the charter, each with its reason in §2: (a) the over-acceptances the vicinity
  found (`&local`, `*&g`, `&gsp->b`, `(long)g`, `(int *)g`, `gs.b`) are closed like the comma — the same fail-open
  class on the same constraint (6.7.9#4 is a Constraint; 6.6#9's forms are explicit), gcc rejects each; (b) the decay
  forms (`gs.arr`, `g2[1]`, `*f`) are decided by the desugar-time typing in the sizeof context, the mechanism the
  `sizeof` desugaring already uses, because shape alone cannot tell `gs.arr` from `gs.b`; (c) an unevaluated `?:`
  branch or an unselected `_Generic` association that is not a constant expression is REJECTED (too strict, never
  fail-open: the association is selected during the Ail typing, after the predicate; upstream's own `?:` arms in
  `is_integer_constant_expression` carry the same "too strict" TODO); (d) 6.6#10 forms keep upstream's answer in
  BOTH directions — accepted as before (`(long)&g`, `(long)ga`, `(int *)16`, `&g == &g`, `&ga[1] - &ga[0]`; `(int)&g`
  passes the constraint as upstream's does and is UB024 at execution), rejected or UB055 as before (`&(int){3}`,
  `"hello"[1]`, a `const` object's value; `(int *)(long)&g` and the offsetof idiom through an integer cast UB055,
  `&g ? 3 : 4` and `_Generic(1, int: (long)&g, default: 2)` rejected) — each pinned and listed in the filing's open
  questions. The first build accepted the last four (the pre-merge review's P1-1); the orchestrator ruled option (ii)
  [AGENT 2026-11-07, orchestrator]: the accepted set is upstream's accepted set plus the 6.6#3-#9 forms and nothing
  else, proved both directions on the table (§2.7, §3.2); (e) `_Generic` and a compound literal in `is_integer_constant_expression`, where the
  wildcard arm crashed on conforming programs, get an arm (a crash on valid C is never a judgement; the arm is the
  standard's text); (f) the GNU `?:` keeps upstream's rejection in the new arms (accepting it routes the program to
  the mini-run's known crash, TODO's item).
- Mirror doctrine holds by construction (one `.lem` change, both engines generated from it; the generated texts read
  against pristine and the mainline's generated trees, §2.5). Fail-closed: every new arm answers `false` or raises
  the program's own typing error; no `failwithI`/`error` site was added. No hand-written seam or proof module
  changed, no fuel form (the predicates are `partial def`s of a module outside the totality gate), so neither the
  kernel-replay gate of [USER 2026-10-18] nor the fuel-parametricity pin set moves.
- Precedents followed: the rank record (`docs/2026-11-04_macro-type-ranks-record.md`) and the stdio record
  (`docs/2026-11-05_stdio-exit-flush-record.md`) for the slice shape and the witness; D13
  (`docs/2026-10-29_compound-assignment-refusal-record.md`) for the rejection pins; the `_Alignas` record for a
  desugarer predicate change.

## 1. The defect, as it stood (both engines; pristine `c3ff8c53f` agrees — the three predicates were byte-identical)

`frontend/model/cabs_to_ail.lem` at `c3ff8c53f`: `is_integer_constant_expression` (:585-790), `is_arithmetic_
constant_expression` (:821-877), `is_lvalue_to_static_object` (:879-917), `is_address_constant` (:921-957) and the
caller `is_initializer_constant_expression_or_string_literal` (:962-989) decide C17 6.7.9#4 for every static- or
thread-storage initializer (the raise sites `desugaring_init.lem:486-490`, `cabs_to_ail.lem:3489-3491`:
`Constraint.IllegalStorageClassStaticOrThreadInitializer`, printed `initializer element is not a compile-time
constant`). What was missing and what was wrong, by mechanism (every item measured, §3):

- `is_lvalue_to_static_object` had no `Indirection` arm: `a[i]` desugars to `*(a + i)` (`CabsEsubscript` →
  `AilEunary Indirection (AilEbinary … Add …)`, :2418), so `&g_arr[1].b` = `AilEmemberof (Indirection (g_arr + 1))
  b` answered `false` (tray 09). `&g_arr[1]` alone was accepted — but only through the next item.
- `is_arithmetic_constant_expression`'s `AilEunary Address e -> is_arithmetic_constant_expression true e` set
  `is_lvalue`, whose only consumer `AilEident _ -> E.return is_lvalue` then accepted ANY identifier: `&local`,
  `&param` (then a typing crash: `gentpying.annotate_expression: AilEident symbol couldn't be resolved`), `&tls`
  passed the constraint; `(long)g` passed through `is_address_constant`'s cast arm (`is_lvalue_to_static_object g`:
  a static object, whatever its type); `&gsp->b` with `gsp` a static pointer variable passed through
  `AilEmemberofptr e _ -> is_lvalue_to_static_object e`; `*&g` passed through `AilEunary _ e` (a value read). The
  predicate had no `AilEcond`/`AilEgeneric` arm (tray 28; audit item 17) and its catch-all `AilEbinary` arm
  accepted the comma (audit item 16; gcc `-pedantic-errors`: `initializer element is not constant [-Wpedantic]`).
- `is_address_constant` had no `AilEstr` arm (tray 29; upstream `6b65dc04f` gave the OTHER predicate the arm), no
  `±` arm below the top level — `(char *)&g + 4` reached the caller's `Add` arm, which ran `is_integer_constant_
  expression false` on BOTH operands, and on the cast operand that is 6.6#6's "shall" failure outside a Constraint,
  reported as `UB055_invalid_integer_constant_expression` —, no decay of a member array or a matrix row (`gs.arr`,
  `gs.arr + 1`, `gsa[1].arr`, `g2[1]`, `*(g2 + 1)`), no `?:`/`_Generic` over address constants (`1 ? &a : &b`), and
  a cast arm that handed the operand to the LVALUE predicate (so `(int *)g` with `g` a static int passed, and
  `(int *)(char *)&g` failed).
- `is_integer_constant_expression` had no `AilEgeneric` (or `AilEcompound`) arm: a generic selection in an
  enumerator, a case label, a file-scope array bound or a `_Static_assert` raised the wildcard `internal error:
  TODO: Cabs_to_ail.is_integer_constant_expression, wildcard ==> _Generic(…)` (exit 125 / Lean PANIC 134): a crash
  on a conforming program; a compound literal there crashed the same way where gcc diagnoses it.

Measured before the change on 446 programs (§3.1; gcc 13.3.0 `-std=c11 -pedantic-errors -O0` the referee; pristine
= fork, Lean = oracle on every row): 202 agree-accept, 80 agree-reject, **77 over-strict rejections of conforming
programs, 3 fail-open acceptances** (`static int a = (1, 3);`, `static double d = (1.0, 3.0);`, `static int a =
*&g;`), **84 crashes** (28 wildcard, 2 typing, 4 GNU `?:`, and 50 of the generator's first preamble: a braced array
of structs with an array member is draft 08's invalid-node class, unrelated, the preamble was changed).

## 2. Design (`frontend/model/cabs_to_ail.lem`; the patch is in the filing, tray 09)

### 2.1 The block

The three predicates are one mutual block (`let rec is_arithmetic_constant_expression … and is_lvalue_to_static_
object … and is_address_constant … and is_decayed_static_lvalue`), with two helpers before `is_integer_constant_
expression`: `expression_of_generic_association` (the expression of an `AilGAtype`/`AilGAdefault`) and
`is_function_designator_expression` (an identifier registered as a function: `E.is_function_designator`). Every
arm cites its clause in the source; the table:

| predicate | arm | clause | before |
|---|---|---|---|
| `is_lvalue_to_static_object` | `AilEunary Indirection e -> is_address_constant_ true e` (the designates-object mode: no null pointer constant, no integer cast to pointer type) | 6.6#9 (`*`, and `[]` as `*(p + i)`, 6.5.2.1#2; "a pointer to an lvalue designating an object": the offsetof idiom through `&((struct S *)0)->x` keeps upstream's UB055, `&*(int *)16` upstream's rejection) | no arm (tray 09) |
| | `AilEmemberofptr e _ -> is_address_constant_ true e` | 6.6#9 with 6.5.2.3#4 (`p->m` is `(*p).m`: the base is a pointer constant, never a pointer object read) | `is_lvalue_to_static_object e` (`&gsp->b` passed, `&((struct S *)&gs)->b` failed) |
| | `AilEident`, `AilEmemberof`, `AilEstr` | 6.6#9, 6.4.5#6 | unchanged |
| | the `AilEbinary Add` and `AilEcast` arms removed | a sum and a cast are not lvalues (6.5.6, 6.5.4#5); the sum was upstream's approximation of the subscript, now the `*` arm | reachable only on ill-typed programs after the change |
| `is_address_constant` | `AilEstr _ -> true` | 6.6#9 with 6.4.5#6, 6.3.2.1#3 (tray 29) | no arm |
| | `AilEunary Address e` → `is_lvalue_to_static_object e` or `is_function_designator_expression e` | 6.6#9 (`&` of a static lvalue or of a function designator) | the lvalue test only; `&f` was accepted by the arithmetic predicate's hack |
| | `AilEcast _ ty e`, `ty` a pointer → `is_address_constant_ e`, else `is_integer_constant_expression false e` (one level up, as upstream tested it; not in the designates-object mode) | 6.6#9 (a pointer cast of an address constant; an integer constant cast to pointer type); the address test first because the integer test raises UB055 on a non-arithmetic cast operand | `is_lvalue_to_static_object e \|\| is_integer_constant_expression false e`, target type ignored |
| | `AilEcast _ ty e`, `ty` not a pointer → `is_static_array_lvalue e` | upstream's arm in shape (an lvalue to a static object, the target type not examined), the lvalue required to be of array type — the decay 6.6#9 names: `(long)ga`, `(long)gs.arr`, `(long)"s"` as upstream accepted them, `(long)g` a value read; an address constant under it is none (`(int *)(long)&g`: upstream's UB055); upstream's integer-constant clause not taken (`(int *)(double)3`: upstream's UB055) — §2.7 | the same arm, with any static lvalue (`(long)g` passed) and an ICE |
| | `AilEbinary e1 (Arithmetic Add) e2`, `Sub` | 6.6#7 fourth bullet, 6.6#9, 6.5.6#2-#3; the pointer operand found first | no arm (the caller's top-level arms only) |
| | `AilEcond e1 (Just e2) e3` → the condition an arithmetic constant expression in 6.6#8's own terms (`no_address`), both branches address constants; `Nothing` → `false` | 6.6#7 "shall be, or evaluate to"; 6.6#3 does not forbid `?:`; `&g ? &a : &b` keeps upstream's rejection; the GNU form keeps its rejection | no arm |
| | `AilEgeneric _ _ gas` → every association an address constant | 6.5.1.1#3 with 6.6#7 (the association is selected during the Ail typing) | no arm |
| | `AilEmemberof`, `AilEmemberofptr`, `AilEunary Indirection` → `is_decayed_static_lvalue` | 6.6#9 "implicitly by the use of an expression of array or function type", 6.3.2.1#3-#4 | no arm |
| `static_lvalue_type` / `is_decayed_static_lvalue` | `is_lvalue_to_static_object a_expr` and the type of `a_expr` annotated in `GenTyping.CTXsizeof` (`Mini_pipeline.annotate_expression_seeded`, `qualified_ctype_of_seeded`, the two calls the `sizeof` desugaring makes at :2485) is an array or function type; a typing error is `E.fail_ailtyping` (the program's own) | in `CTXsizeof` neither the lvalue conversion nor the decay is performed (`genTyping.lem:1821-1836`), so `gs.arr` types `int[3]`, `gs.b` `int`, `gq.p` `int *`, `*f` a function type | new |
| `is_arithmetic_constant_expression` | `AilEunary Address e` → `is_lvalue_to_static_object e` or the function-designator test; `false` in the `no_address` mode | 6.6#9; the top-level entry keeps upstream's acceptance of an address constant inside an arithmetic-typed expression (`(long)&g`, `&g == &g`: 6.6#10 forms gcc accepts); the operands of `?:` and `_Generic` are tested in the `no_address` mode (6.6#8's own operands), so `&g ? 3 : 4` keeps upstream's rejection | `is_arithmetic_constant_expression true e` (any identifier) |
| | `AilEunary Indirection _ -> false` | 6.6#9 (no object's value is accessed) | recursed (`*&g` passed) |
| | `AilEunary PostfixIncr/PostfixDecr _ -> false` | 6.6#3 | recursed |
| | `AilEbinary _ Comma _ -> false` | 6.6#3 (audit item 16) | the catch-all binary arm accepted it |
| | `AilEcond e1 (Just e2) e3` → all three constant in the `no_address` mode; `Nothing` → `false` | 6.6#3, 6.6#8 (tray 28); the GNU form keeps its rejection | no arm |
| | `AilEgeneric _ _ gas` → every association constant in the `no_address` mode | 6.5.1.1#3 (audit item 17) | no arm |
| `is_integer_constant_expression` | `AilEgeneric _ _ gas` → every association an ICE | the fork's READING: 6.6#6 does not name generic selections among an ICE's operands; the arm reads 6.5.1.1#3 (the selected association's expression, of identical type and value) as making the selection transparent — universal practice, the filing's open question (review P3-3c) | the wildcard `error` (a crash on a conforming program: a TODO) |
| | `AilEcompound _ _ _ -> false` | 6.6#6 (not an operand of an ICE) | the wildcard `error` (a crash) |
| the caller | `is_address_constant` consulted only when the arithmetic test failed | 6.6#7's bullets in order; see §2.6 | both run, or'ed |

The `is_lvalue` parameter of `is_arithmetic_constant_expression` is kept (upstream's signature; its only remaining
setter is the `AilEannot` arm, whose operand is an enumeration constant's `AilEconst`), so the `AilEident ->
is_lvalue` arm now answers `false` on every reachable path.

### 2.2 Why the over-acceptances are closed [AGENT 2026-11-07]

The comma is the charter's; `&local`/`&param`, `*&g`, `&gsp->b`/`&*gp`/`&gp[0]`/`gsp->arr + 2`, `(int *)g`,
`(long)g`, `gs.b`/`gq.p` and `&tls` are the same class on the same constraint: 6.7.9#4 is a Constraint, and the
expression is none of 6.6#7's four forms — not an arithmetic constant expression (6.6#8 lists its operands), not an
address constant (6.6#9: static storage duration; "the value of an object shall not be accessed"; 6.2.4#4 gives
thread storage duration its own name). gcc 13 rejects every one of them with `initializer element is not constant`.
Closing them is the diagnostic gcc gives, not a semantics; the risk of rejecting a conforming program is the
measurement's to catch (§3, §4: none).

### 2.3 Why the decay arm types [AGENT 2026-11-07]

`gs.arr` (an array member: decays to an address constant) and `gs.b` (an int member: its value would be read) have
the same shape, `AilEmemberof gs _`; `g2[1]` (a row: decays) and `ga[1]` (an element: a read) likewise. Upstream's
predicates never type and so could not have these arms; the desugarer already types expressions at desugar time
in exactly two places — `is_integer_constant_expression`'s cast arm (`typecheckAil_seeded`) and the `sizeof`
desugaring (`annotate_expression_seeded … CTXsizeof`) — and the sizeof context is the one in which an array or
function lvalue keeps its type. The arm runs only for a `Memberof`/`Memberofptr`/`Indirection`-shaped expression
that the lvalue test accepted, in a static-initializer position; a program for which that typing fails is
ill-typed and would get the same error from the Ail typing next.

### 2.4 Deliberately unchanged: 6.6#10 forms, the dead branches, the GNU `?:`

- `(long)&g`, `(long)ga`, `&g == &g`, `(int)(&ga[2] - &ga[0])`, `(int *)16`: 6.6#10 forms upstream accepted (through its
  arithmetic cast arm or its address cast arm) and gcc accepts; kept. `(int)&g`: upstream's predicate passes it and the
  execution reports `UB024_out_of_range_pointer_to_integer_conversion` (gcc: not computable at load time); kept as
  upstream's, a declared row (review P2-1). `(int *)(long)&g`, the `offsetof` idiom `(int)(unsigned long)&((struct S
  *)0)->x` (an address cast to integer; an address through a null pointer's `->`), `&g ? 3 : 4`, `_Generic(1, int:
  (long)&g, default: 2)`: 6.6#10 forms upstream did NOT accept (UB055 or the constraint) and gcc accepts; the first
  build accepted them, the review's P1-1 ruling returned them to upstream's answers (§2.7). `(long)&g - (long)&ga[0]`
  runs and `&g + (int)&g` is UB024 on upstream and the fork where gcc rejects: the arithmetic predicate's retained
  `&` arm (review P3-1, residuals); `(int *)(double)3` is upstream's UB055 path (review P3-2).
- `&(int){3}` (a compound literal has static storage duration at file scope, 6.5.2.5#5, so `&` of it is arguably
  an address constant), `"hello"[1]` and `*"hello"` (reads of a string literal element), `static const int k = 3;
  static int a = k;` (a `const` object is not a constant expression in C; gcc folds it): upstream rejected, gcc
  accepts; kept as upstream's rejection, listed as the filing's open questions ([AGENT]: the compound literal is
  the charter's named judgement area; the other two are 6.6#10 extensions of gcc's).
- An unevaluated `?:` branch or an unselected `_Generic` association that is not a constant expression (`1 ? 3 :
  f()`, `1 ? 3 : g`, `_Generic(1, int: 3, default: g)`, `1 ? &g : gp`), the comma there included (`1 ? 3 : (1, 2)`,
  `_Generic(1, int: 3, default: (1, 2))`: 6.6#3's own exception, 6.5.15#4 — the strongest instance of the "too strict"
  TODO upstream carries on its `?:` arms; review P2-2): rejected, upstream's rejection kept as a declared
  over-strictness (§0 (c)); the comma in `_Generic`'s unevaluated CONTROLLING expression is not walked and so accepted.
- `3 ?: 4` (GNU): a constraint violation in the initializer context as before; in the enumerator, case-label,
  array-bound and `_Static_assert` contexts upstream's `is_integer_constant_expression` arm accepts it and the
  mini-run crashes (`PEcase, mismatched` / `the driver found less/more …`): TODO's item, untouched, one gap row.

### 2.5 The generated delta (read against `CERB_UPSTREAM_TREE` and the mainline primary checkout's generated trees)

OCaml: `ocaml_frontend/generated/cabs_to_ail.ml` only (279 changed lines: the two helpers, the ICE arms, the mutual
block, the caller's sequencing; `Mini_pipeline.annotate_expression_seeded`/`qualified_ctype_of_seeded` and
`fail_ailtyping` as at the `sizeof` site). Lean: `lean_frontend/generated/Cabs_to_ail.lean` only (366 lines): the
block is a `mutual … end` of `partial def`s with the `_lemReader_enum_definitions` parameter lifted by lem
(`Cabs_to_ail` is outside the totality gate's 22 modules; `is_arithmetic_constant_expression` and
`is_lvalue_to_static_object` were `partial def`s before and `is_address_constant` a plain `def`; the module's
`partial def`s: 50 at the base, 52 at the reviewed tip, 56 after the narrowing's helpers — review P3-3a). `diff -rq` over both trees against the mainline's: no other file. The build's warnings for the module
are upstream's own unused `loc` binders (the two defs that had them before; one new binder of mine was removed
before M1). Lem-sync stamp re-recorded by `make lean-prelude-src`.

### 2.6 Two corrections found by the probe table before M1 [AGENT 2026-11-07]

- `(int)(long)&g - (int)(long)&g + 3` (a 6.6#10 form, accepted before, gcc 3) became `UB055` on the first build:
  upstream's caller ran BOTH predicates and or'ed them, and the new `±` arm of `is_address_constant` then ran
  `is_integer_constant_expression` on the cast-of-address operand of a sum whose whole was already an arithmetic
  constant expression. The caller now tests 6.6#7's bullets in order (`is_address_constant` only when the
  arithmetic test failed) — semantically a no-op except for raised failures, which is the point.
- `static int a = 3 ?: 4;` was a clean constraint violation before and became the mini-run's crash on the first
  build (the new cond arms accepted the GNU form); the arms now reject the form (`Nothing -> false`).

### 2.7 The narrowing (the pre-merge review's P1-1, option (ii)) [AGENT 2026-11-07, orchestrator ruling; the worker's arms]

The first build accepted four 6.6#10 forms pristine did not (`(int *)(long)&g` and the offsetof idiom through an
integer cast: UB055 on pristine; `&g ? 3 : 4` and `_Generic(1, int: (long)&g, default: 2)`: rejected on pristine) —
through the cast arm's recursion regardless of the target type, and through the new `?:`/`_Generic` arms composed with
the retained `&` arm — and the record attributed them to upstream. The ruling: the accepted set is exactly upstream's
accepted set plus the 6.6#3-#9 forms, nothing else, and no form upstream accepted may become rejected (the reviewer's
`(long)ga`). The narrowing, by matching upstream's arms rather than special-casing: (1) a `no_address` mode of the
arithmetic predicate under which the `&` arm answers false, used for the operands of `?:` and `_Generic` (upstream had
no such arms to compose an address with) and for the condition of `is_address_constant`'s `?:` arm, while the top-level
entry keeps upstream's `(long)&g`/`&g == &g`; (2) the cast arm split by the target type: a pointer target is 6.6#9's
(a pointer cast of an address constant; an integer constant cast to pointer type, tested one level up as upstream
tested it), a non-pointer target is UPSTREAM'S ARM in shape — the operand an lvalue to a static object, the target
type not examined — with the lvalue required to be of array type (`is_static_array_lvalue`: the decay 6.6#9 names),
which keeps `(long)ga`, `(long)gs.arr` and `(long)"s"` and lets `(int *)(long)&g` fall to upstream's integer test and
its UB055; upstream's integer-constant clause under a non-pointer cast is not taken (no conforming program needs it:
`(long)5` is an arithmetic constant expression; `(int *)(double)3` keeps upstream's UB055); (3) a designates-object
mode of `is_address_constant` for the base of `*` and `->` (no null pointer constant, no integer cast to pointer
type: 6.6#9's "a pointer to an lvalue designating an object"), so the offsetof idiom keeps upstream's UB055 and
`&*(int *)16` upstream's rejection while `&((struct S *)&gs)->b` is accepted. Proved both directions on the
472-program table (§3.2). The reviewer's compositions that are listed forms stay accepted (`1 ? _Generic(1, int: &g,
default: &ga[0]) : &ga[1]`, 6.6#7 "evaluate to"; `2 + ga - 1`, 6.6#7's fourth bullet twice; `_Generic((1, 2), int: 3,
default: 4)`, the controlling expression unevaluated).

## 3. The vicinity

### 3.1 The table (the instrument `.tmp/ac/gen.py` + `run.sh`, deleted at slice end)

472 programs (446 at M1; the pre-merge review's probe forms added at the review fix: the comma in a dead `?:`
branch, in an unselected `_Generic` association and in the unevaluated controlling expression, `&g ? 3 : 4`, `_Generic`
over `(long)&g`, `?:` over `_Generic` over address constants, `2 + ga - 1`, `(long)&g - (long)&ga[0]`, `&g + (int)&g`,
`(int *)(double)3`), every one returning a small int: the integer-constant-expression forms (62: literals, character and
enumeration constants, `sizeof`/`_Alignof`, cast floating constants, every binary and unary operator, casts, `?:`
in seven shapes incl. dead branches with a division by zero, a negative shift, a signed overflow, a call or a
variable, the GNU `?:`, `_Generic` in six shapes incl. a variable or a call as the unevaluated controlling
expression, and the forbidden or non-constant forms: comma, assignment, increments, compound assignment, call, a
variable, `*&g`, uncast floating constants, pointer comparisons/casts/differences, a compound literal) × five
contexts (a static initializer, an enumerator, a case label, a file-scope array bound, `_Static_assert`); 13
arithmetic forms (floating arithmetic, comparisons, `?:`/`_Generic` over floating, `_Bool`, unsigned wrap, the
`offsetof` idiom and macro, a floating comma); 69 address-constant forms (every chain shape over a static int, a
static array, a 2-D array, a struct with a nested struct and an array member, an array of such structs filled in
`main`, a static pointer variable, a function, an enumeration constant; string literals in twelve shapes; function
designators in eight; casts, `?:`, `_Generic`, null pointer constants, integer-to-pointer casts, a compound literal;
the non-constant forms: pointer variables under `*`, `[]`, `->`, a variable or a comma in a subscript, a comma
yielding an address, `(int *)g`) in an `int *`, `const char *` or function-pointer static; 29 contexts (array,
struct, designated and nested initializers, an external-linkage object, block-scope statics, `&` of an automatic
object or a parameter, a braced scalar, `_Thread_local`, a `const` object, casts of addresses to `long`/`int`,
pointer differences and comparisons, a cast chain, a bit-field width, member values, `*&` of an array and of a
function, a mixed `_Generic`, `?:` over an address constant and `0`). Referees: gcc 13.3.0 (`-std=c11
-pedantic-errors -O0`; a rejection recorded as its first error line), pristine `c3ff8c53f`, the pre-change fork
oracle and Lean engine (a snapshot of the binaries and the dereferenced install tree; retired after M2 — the review's
26 added programs have pristine's lines and the final engines' only), the rebuilt oracle, the rebuilt Lean engine on
the rebuilt oracle's Cabs JSON.

### 3.2 Results (derived from `before.tsv`, `after-fl.tsv` (M2), `after2.tsv`/`after2-fl.tsv` (the review fix))

| | before, 446 (pristine = fork; Lean = oracle) | M2, 446 (Lean = oracle) | review fix, 472 (Lean = oracle) |
|---|---|---|---|
| agree with gcc, accepted | 202 | 330 | 335 |
| agree with gcc, rejected | 80 | 100 | 106 |
| over-strict (gcc runs, both engines reject) | 77 | 12 (every one declared, §2.4; incl. the bit-field gap) | 26 (every one declared: §2.4's, the four P1-1 forms at upstream's answers, the ten dead-branch-comma rows of the five contexts) |
| fail-open (gcc rejects, both engines run) | 3 | 0 | 1 (`(long)&g - (long)&ga[0]`: upstream's acceptance kept by the P1-1 rule, review P3-1) |
| crash | 84 (28 wildcard, 2 typing, 4 GNU `?:`, 50 preamble) | 4 (the GNU `?:` in the four ICE contexts, TODO's) | 4 (the same) |
| Lean ≠ oracle, or a value ≠ gcc's on an accepted row | 0 | 0 | 0 |

The accepted-set rule, both directions, on the 472 rows (the review fix against pristine): **94 rows the fork accepts
and pristine does not** — every one gcc-accepted and a 6.6#3-#9 form: `?:` over constants in a static initializer (6
shapes) and `_Generic` over constants in all five contexts (6 shapes each, 30, where pristine crashed in four contexts),
`?:`/`_Generic` over floating constants (2), `±` an integer constant expression (`(ga + 1) + 1`, `2 + ga - 1`, `gs.arr
+ 2`, `gsa[1].arr + 2`, `g2[1] + 0`, `"hello" + k` in 8 shapes), the `[]`/`.`/`->`/`*`/pointer-cast chains (`&gs.arr[2]`,
`&gsa[1].b`, `&gsa[1].i.x`, `&gsa[1].arr[2]`, `&ga[1 ? 2 : 0]`, `(int *)&g`, `(int *)(char *)&g`, `(int *)((char *)&ga +
8)`, `(void *)&g`, `(void *)&gsa[1].b`, `(int *)(void *)(char *)&g`, `&((struct S *)&gs)->b`, `&(*(struct S *)&gs).b`,
`((struct S *)&gs)->arr + 2`, `&(*(gsa + 1)).b`, `&"hello"[1]`, `(const char *)&"hello"[1]`), the decays (`gs.arr`,
`g2[1]`, `*(g2 + 1)`), `?:`/`_Generic` over address constants and their compositions (7), function designators under
`*`, `?:` and a pointer cast (4), and the same forms in the aggregate, external, block-scope and braced contexts (12).
**12 rows pristine accepts and the fork does not** — every one gcc-rejected: `(1, 3)`, `(1.0, 3.0)`, `(0, &g)`, `*&g`,
`*&gp`, `&*gp`, `&gp[0]`, `&gsp->b`, `&ga[g - 1]`, `&ga[(1, 2)]`, `&t` of a `_Thread_local`, `(long)g`. **15 rows where
neither accepts and the verdict moved** — a crash or an execution UB became the constraint diagnostic (the
`_Generic`-with-a-non-constant-association and compound-literal rows in the four integer-constant contexts, `(int *)g`
from UB043, `&local`/`&param` from the typing crash). The four P1-1 forms (`ac_cast_int_of_addr`, `ar_offsetof_idiom`,
`ice_init_cond_addr_cond`, `ar_generic_long_addr`) are at pristine's answers. Lean = oracle on all 472.

At M2 (446 rows), 112 moved on the fork, every one in the intended direction: 63 rejected → accepted (gcc accepts), 20
crash → accepted (the `_Generic` contexts), 6 UB055 → accepted (`(char *)&g + 4` and the cast chains, the
`offsetof` idiom), 12 accepted → rejected (gcc rejects: `(1, 3)`, `(1.0, 3.0)`, `(0, &g)`, `*&g`, `*&gp`,
`&*gp`, `&gp[0]`, `&gsp->b`, `&ga[g - 1]`, `&ga[(1, 2)]`, `(int *)g`, `(long)g`, `&t` of a `_Thread_local`),
5 crash → rejected (gcc rejects: a compound literal in the ICE contexts, `&local`/`&param`), 1 UB055 → rejected
(`(int *)g`), 3 crash → declared rejections (`_Generic` with an unselected non-constant association in the
enumerator/case/array contexts; gcc accepts), 1 crash → declared UB204 (the same in `_Static_assert`). The `ice_
*_cond_gnu` rows did not move (§2.4).

### 3.3 Findings

| # | finding | class | disposition |
|---|---|---|---|
| F1 | the §6.6 forms rejected: `&arr[i].m` and every `*`/`[]`/`.`/`->`/cast chain, `?:` and `_Generic` in a static initializer, `"s" + k` and `&"s"[k]`, member-array and matrix-row decays, `(char *)&g + 4` (UB055), `1 ? &a : &b`, `*f`/`**f`/`*&f` | over-strict on conforming input; the clear-standard reading | FIXED (§2); witnessed (§3.4) |
| F2 | the comma (int, double, address), `*&g`, `&local`/`&param`, pointer variables under `*`/`[]`/`->`, `(int *)g`, `(long)g`, `gs.b`, `&tls` accepted in a static initializer | fail-open on the 6.7.9#4 constraint; gcc rejects each | FIXED (§2.2); the rejections pinned |
| F3 | `_Generic` in an enumerator, a case label, a file-scope array bound, a `_Static_assert` crashes both engines (the wildcard arm); a compound literal there likewise | crash on conforming input (gcc: a diagnostic for the literal) | FIXED: the two arms (§2.1); 24 + 4 rows |
| F4 | `&local` in a block-scope static crashed the Ail typing after the hack let it through | crash on invalid input | closed by F2 (the constraint violation now) |
| F5 | an unevaluated `?:` branch / an unselected `_Generic` association that is not constant is rejected — the comma there included (6.6#3's own exception, review P2-2) | declared over-strict (§0 (c)): upstream's rejection kept | pinned `fork` rows; the filing's open question |
| F6 | `&(int){3}`, `"hello"[1]`, a `const` object's value: upstream rejects, gcc accepts (6.6#10) | judgement areas | kept; pinned `fork` rows; the filing's open questions |
| F7 | `(long)&g`, `(long)ga`, `&g == &g`, pointer differences, `(int *)16`: accepted (6.6#10) | upstream's answers kept | pinned `gcc` rows (gcc agrees on each); `(int)&g` passes the constraint and is UB024 at execution on both engines, gcc rejects: a declared row (review P2-1) |
| F10 | `(int *)(long)&g`, the offsetof idiom through an integer cast, `&g ? 3 : 4`, `_Generic(1, int: (long)&g, default: 2)`: accepted by the first build, not by upstream (UB055 / rejected); gcc accepts | 6.6#10 forms the fork must not take (review P1-1, option (ii)) | returned to upstream's answers (§2.7); declared rows |
| F11 | `(long)&g - (long)&ga[0]` runs, `&g + (int)&g` passes the constraint (UB024) on upstream and the fork; gcc rejects | residual fail-open through the arithmetic predicate's retained `&` arm (review P3-1) | upstream's, kept; declared rows; TODO and the filing |
| F12 | `(int *)(double)3`, `(int *)(long)(int *)g`, `(long)&g + g`: UB055 where gcc gives a constraint diagnostic | upstream's UB055 path for a non-arithmetic cast operand (review P3-2) | upstream's, kept; one declared row; TODO and the filing |
| F13 | an ill-typed decay-shaped initializer (`static int *q = gs.nope;`) reports the typing's error at desugaring where pristine said `not a compile-time constant` (gcc: `has no member named`) | diagnostic-text class, as `ci/0268` (review P3-5) | in no walked corpus; §7 |
| F8 | the GNU `?:` in the four ICE contexts crashes (TODO's item) | pre-existing, another mechanism | one gap row; the filing's related finding |
| F9 | a braced initializer of an array of structs with an array member is an invalid node at translation (draft 08) | pre-existing, another mechanism | the probes fill the array in `main`; the filing's related finding |

### 3.4 The witness (`scripts/check_address_constants.sh`, row 1 via `test_unit.sh`; `tests/address_constants/`, 244 programs)

The table's programs in the initializer context in full (`ac_*` 126, `ar_*` 15, `ice_init_*` 66) and the slice's
forms in the other four contexts (`lit`, `cond`, `comma`, `compound`, the six `generic*`: 40) plus the gap row
(244; the bit-field width excluded: unsupported, another mechanism). Pins (`expected.txt`: name, class, the oracle's
line, the Lean engine's line): 183 `gcc` rows — both engines print gcc 13's batch line byte for byte, exit 0; 39
`reject` rows — the oracle exits 1 with the pinned `constraint violation` line (file prefix stripped), the Lean engine
exits 1 with the pinned `Error {msg: "desugaring failed at <name>.c:<loc>"}` line (the location included; the programs
run under their bare names in the scratch directory), gcc's rejection beside in `gcc.txt`; the class check admits
only such a pair — or upstream's `UB204_illtyped_Static_assert` verdict in a `_Static_assert` and its `feature not yet
supported: variable length array type` refusal in a file-scope array bound, both declared in the header — so a program
that passed the constraint and died at execution cannot sit in the class (review P2-1); 21 `fork` rows — the declared
verdicts of F5/F6/F7/F10/F11/F12, each named in `FORK_PINNED`, gcc's line beside; 1 `gap` row (F8: `PEcase,
mismatched`, rc 125 / 134). The class of every row is checked against `gcc.txt` and the declared lists in both
directions; the total and the class counts are pinned (244 = 183 + 39 + 21 + 1); `pristine.txt` carries pristine's
lines (113 moved; for the three review-added rows that moved the Lean column is pristine's oracle line standing in,
stated in its header — the base engine was retired after M2). Five plants on a
14-program subset, counts derived in the script (5 moved and 3 unmoved `gcc` rows, 2 moved and 1 unmoved `reject`
rows, 2 `fork` rows, the gap row): `pristine-pair` 14, `lean-pristine` 7, `lean-fixed` 14, `oracle-rc` 9 (the
gap row's rc 125 included), `expect-tamper` 3 (the altered pin also fails the class check — the stdio precedent's
count). Verbatim (the review-fix tree; the M2 run, 234 programs, had the same plant counts and `OK (234 programs …
182 … 40 … 11 … 1 gap control … 112 rows moved …)`):

```text
check_address_constants: selftest plant 'pristine-pair' caught: 14 failing check(s) (= expected 14; incl. the required programs)
check_address_constants: selftest plant 'lean-pristine' caught: 7 failing check(s) (= expected 7; incl. the required programs)
check_address_constants: selftest plant 'lean-fixed' caught: 14 failing check(s) (= expected 14; incl. the required programs)
check_address_constants: selftest plant 'oracle-rc' caught: 9 failing check(s) (= expected 9; incl. the required programs)
check_address_constants: selftest plant 'expect-tamper' caught: 3 failing check(s) (= expected 3; incl. the required programs)
check_address_constants: OK (244 programs, nolibc: 183 batch lines of both engines = gcc 13's pinned line, exit 0 on both — every integer-constant-expression form (literals, character and enumeration constants, sizeof and _Alignof, cast floating constants, every operator, ?: incl. dead branches with a division by zero, a negative shift or an overflow, _Generic incl. a variable, a call or a comma as the unevaluated controlling expression) in a static initializer and the slice's forms in enumerators, case labels, array bounds and _Static_assert; the arithmetic forms; every address-constant shape (& of static objects, array and 2-D elements, members, nested and array-element members, member arrays and their decay, &*&g, string literals plus an offset and their elements, function designators under &, * and casts, pointer casts and chains, ?: and _Generic over address constants and their compositions, null pointer constants, integer-to-pointer casts, (long)&g and (long)ga as upstream accepts them) in file-scope, external, block-scope, struct, array, designated and nested initializers; 39 rejected by both engines with the pinned constraint diagnostic where gcc rejects too (the comma, assignment, increment and call operators, a variable, value reads through *, [] and ->, pointer variables, & of an automatic object or a parameter, (int *)g, (long)g, & of a _Thread_local, a compound literal or a non-constant in the integer-constant contexts); 21 pinned to the fork's declared verdict with gcc's beside it in gcc.txt (an unevaluated ?: branch or an unselected _Generic association that is not constant, the comma there included; & of a compound literal, the value of a string literal element or of a const object; the 6.6#10 forms kept at upstream's answer: (int *)(long)&g and the offsetof idiom UB055, &g ? 3 : 4 and _Generic over (long)&g rejected, (int)&g UB024 at execution, (long)&g - (long)&ga[0] running and &g + (int)&g UB024, (int *)(double)3 UB055); 1 gap control: the GNU ?: in a case label still crashes both engines (TODO); 113 rows moved from pristine c3ff8c53f's lines)
```

The first self-test run caught the tamper plant at 3, not the 2 I had derived (the altered pin fails the class check
as well as the two engine checks): the derivation was corrected, the script's own plant found the worker's miscount.
Cost (measured standalone, `/usr/bin/time`, the M2 tree): the real run 27.14 s, the self-test with the real run 35.29 s.

## 4. Moved rows and pins (gcc the referee)

### 4.1 Pins that did not move

The libc Core dumps and their pins (`scripts/libc_prep.sh`: `libc` and `libc_inner_arg_temps` both `pin + regenerated
dump ==`; the predicates only decide the constraint, the elaboration is untouched), the CoreQuote libc digests, the
float-literal register, every lane baseline (`tests/libc_exec`, `tests/inner_arg_temps`, `tests/pnvi_lane`,
`tests/immaculate`, the exec baselines of row 2-4b, csmith, CN, the libxml2 URI pins): a 7413-file `--nolibc --pp=core`
sweep (§4.3) found no gated corpus row whose desugaring verdict or Core text changed.

### 4.2 The manifest

`scripts/fork_drift_manifest.txt`: `[source-content]` `frontend/model/cabs_to_ail.lem` `b0ffbe9e…` → `8d932c93…`;
`[expected-semantic]` `cabs_to_ail.ml`'s excused-diff hash `19624373…` → `094ccc70…` (an already-differing file: the
fork's supply/top parameters and D3 seeds); a dated header NOTE; no `--refresh`; layer 2 unchanged at 33 differing
files. Gate + self-test, verbatim: `check_fork_drift: OK — layer 1: 95 oracle-surface files = manifest (set, C-locale
canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base
c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v
lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))`; `check_fork_drift: SELFTEST OK (31 plants with declared
verdict/message: …)`; `check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile
rev, 3 lake-manifests rev+inputRev, README pin command)`.

### 4.3 The sweep (the instrument `.tmp/ac/sweep.sh`, deleted at slice end) and its table

The pre-change oracle (a snapshot of the base's binary and its dereferenced install tree) against the rebuilt one,
`--nolibc --pp=core` (the desugarer runs before linking; the exit status, the first error line and a hash of the Core
text compared) over every `.c` the lanes walk: `tests/` apart from csmith and libxml2 (5515), the CN corpus (213),
`lean_frontend/corpus` (16), the 1669 csmith programs materialised as the lane does — 7413 files, 11 moved (14 rows
differed; three only in the runtime's include path inside a 160-character-clipped error line, same exit status and
same Core hash: an instrument artefact). Every moved row, both engines run on it afterwards (`--exec --batch`; gcc
13.3.0 `-O0`):

| row | lane | before | after (oracle = Lean) | gcc | disposition |
|---|---|---|---|---|---|
| `tests/gcc-torture/breakdown/success/921019-1.c` | ci-sweep scoreboard `torture_success.tsv:357` (`CERB_REJECT`; Tier C) | the 6.7.9#4 constraint violation | `Specified(0)` in libc mode (the suite's mode; `--nolibc`: an unknown `exit`) | 0 | the fix; the scoreboard row changes class at its next deliberate re-record |
| `…/success/980223.c` | `torture_success.tsv:483` | the same | `Specified(0)` | 0 | the fix; likewise |
| `…/success/pr53084.c` | `torture_success.tsv:769` | the same | `Specified(0)` | 0 | the fix; likewise |
| `tests/gcc-torture/execute/const-addr-expr-1.c` (= `breakdown/fail/desugaring/const-addr-expr-1.c`, `torture_fail.tsv:3`) | the scoreboard | the same | `Specified(0)` | 0 | the fix; the "fail/desugaring" class row moves |
| `tests/noodle-probes/elab/elab_addr_const_string_plus.c` | none (tray 29's reproducer) | the same | `Specified(101)` | 101 | the fix |
| `tests/noodle-probes/elab/elab_const_expr_ternary_init.c` | none (tray 28's reproducer) | the same | `Specified(10)` | 10 | the fix |
| `tests/parity-probes/uncertainty/G-constant-expressions/si-09-string-ptr-arith.c` | the survey's cluster G (`NOISY WRONG`) | `CERB_SKIP` (the rejection) | `Specified(98)` | 98 | the fix; the survey row annotated |
| `…/si-10-cond-const.c` | cluster G (`UNCLEAR`) | `CERB_SKIP` | `Specified(4)` | 4 | the fix (the dead branch's `1/0` is not evaluated); annotated |
| `tests/ci/0268-address-invalid-type.error.c` (and `tests/cheri-ci/0268…`) | `test_parse.sh`/`test_core.sh tests/ci` (a parse/`.error.c` row), the pristine lane's `ci` reporting row | `constraint violation: cannot take address of an rvalue of type 'signed int'` (the Ail typing, after the desugarer's hack passed `&1`) | `constraint violation: initializer element is not a compile-time constant` (the desugarer, 6.7.9#4 first) | `lvalue required as unary '&' operand` | both reject, exit 1, empty stdout; a `diagnostic-text` register row (§5) |
| `tests/csmith_findings/oracle/init_addr_const.c` | none (a findings archive; walked by no lane) | the 6.7.9#4 constraint violation on `&g_arr[1][0].f3` | `internal error: Translation called on Ail program with an invalid node` (exit 125; Lean the mirrored stop) | 7 | draft 08's class: a 2-D array of structs with a braced initializer; pristine crashes on the program with the formerly rejected line removed (measured), so the crash predates the slice and the over-strict rejection merely stopped the unit before translation. Not fixed here (another mechanism); named in the filing's related findings and TODO |

The gcc second-oracle lane (Tier B row 7) walks `tests/minimal`, `debug`, `float`, `immaculate/nolibc` and csmith: none
of the moved rows. The 4 gcc-torture rows are a Tier C scoreboard with no baseline.

Re-run on the review-fix tree (`a5fc0fcd9`, the narrowing of §2.7) against the same before pass: the same 14 differing
rows, the same 9 real moves; 0 rows moved between the M2 oracle and the narrowed one (no walked corpus program used a
6.6#10 form the first build had accepted).

## 5. Register entries

- **Fork-drift manifest:** §4.2. **Pristine-difference register** (`scripts/upstream_oracle_differences.json`): one
  `diagnostic-text` row, `ci/0268-address-invalid-type.error.c`, 24 → 25 rows; signatures from the lane's own report
  (`--corpus ci --only 0268-address-invalid-type`: `Independent oracle: subset_passed; {'reviewed_difference': 1}`);
  the citations are this record, the tray-09 filing and the charter (the lane requires tracked files; the record was
  added once committed). Re-checked on the review-fix tree: `subset_passed; {'reviewed_difference': 1}`.
- **Failure-reach register:** no new row (`check_failure_reach: OK (238 pure failure sites = the 238 register rows
  exactly (236 in the exec dependency closure + 2 unresolved-owner; …); position classes unchanged; 0 DISCARDABLE; reach
  UNREACHABLE-BY-INVARIANT=175 REACHABLE=42 UNKNOWN=21; every row sealed; tally line consistent)`): the new arms add
  no `failwithI`/`error` site; `E.fail_ailtyping` is the typing's existing monadic failure. **Fuel forms, pins,
  hypotheses, kernel replay:** unchanged, not owed (§0).
- **Baselines:** none moved (§4.1). **Scoreboard:** the four gcc-torture rows (§4.3) at the next re-record.
- `CONTRACT.md` (D17 and the §4.1 witness list), `VALIDATION.md` (the §3(c) bullet, the fork ≠ pristine inventory
  entry, the §6 gate-table row), `SUPPORTED.md`'s Domain row, `scripts/LADDER.md` row 1, `TODO.md`, tray 09 rewritten
  as the filing with 28 and 29 merged (their files are merge stubs), the INDEX rows, the survey record's `si-09`/`si-10`
  rows, the consumer notes `docs/2026-11-07_consumer-note-cerberus-caesium-address-constants.md` and
  `…-cerberus-sl-….md`: M3. The outcome-protocol migration map: no new site to inventory.

## 6. Gates

### 6.1 M1 (`1c21272e7`): the focused gates (§4.2 and the following, verbatim)

```text
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src d9331c51777adc6e0261a3ed57058b07ffe4a6ef76eb870801b360ba9c778a5d, gen 993b54668c0db302ddb9290723105cd06572981fb5bc0ff0d60ebf6413fe5d16)   (the first regeneration; re-recorded at each of the three regenerations)
Build completed successfully (413 jobs).                                   (capped lake build CerberusLean cerberus-lean stop-test)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=175 REACHABLE=42 UNKNOWN=21; every row sealed; tally line consistent)
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
libc_prep: OK (libc_inner_arg_temps: pin + regenerated dump == dcd0499f5463ea0dd12a10ecb23a889ec9c366ab3133c0928c6d95329fb3481d, 4011125 bytes)   (and the libc pin, OK)
Ran 26 tests in 2.496s / OK                                                (test_stops.py --lean-bin …/stop-test)
[1/1] MATCH ac_arr_elem_member: VAL:{value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}   (test_exec.sh, the tray 09 reproducer; ce_ternary_init 10, ac_string_plus 101, ce_generic 3 likewise; ce_comma_init cerb_skip=1: the oracle's rejection)
```

plus the fork-drift gate and its self-test (§4.2). The driver-freshness stamps were recorded after the direct `dune`/`lake`
builds (`tools/check_driver_fresh.sh --record-oracle` / `--record-lean`; the lanes refuse without them).

### 6.2 M2: the witness (§3.4), the lanes, the sweep (§4.3)

```text
Independent oracle scope: tier-b; 1001 rows in 195.6s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 945, 'reviewed_difference': 24, 'matching_failure': 30, 'interface_agreement': 2}
Independent oracle scope: subset (--only); 1 rows in 1.4s; source unchanged: True                                    (--corpus ci --only 0268-address-invalid-type)
Independent oracle: subset_passed; {'reviewed_difference': 1}
```

(A first tier-b run during which the documents were being edited reported `source unchanged: False` and was repeated
with the tree held; a first `--only` run before the row existed reported `difference: 1`, and one with the row citing
this then-untracked record was refused by the lane's citation check — the row cites the tracked filing and charter.)
### 6.3 The review fix (`a5fc0fcd9`): the focused gates re-run (verbatim)

```text
make rc=0 / dune build rc=0 / dune install rc=0 / cerberus.install rc=0 / Build completed successfully (413 jobs).
check_fork_drift: OK — layer 1: 95 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: …)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; …); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=175 REACHABLE=42 UNKNOWN=21; every row sealed; tally line consistent)
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
OK                                                           (test_stops.py, 26 tests)
libc_prep: OK (libc: pin + regenerated dump == 519d7c927cca883da2a004c101e064ffd52c352cb4d037d38ac589a29077f210, 4156776 bytes)   (and libc_inner_arg_temps OK)
[1/1] MATCH ac_arr_elem_member: VAL:{value: "Specified(3)", …}   (ce_ternary_init 10, ac_string_plus 101, ce_generic 3 MATCH; ce_comma_init cerb_skip=1)
check_address_constants: selftest plants 14 / 7 / 14 / 9 / 3 (= expected); OK (244 programs … 183 … 39 … 21 … 1 gap control … 113 rows moved …)   (§3.4 verbatim)
Independent oracle scope: tier-b; 1001 rows in 230.9s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 945, 'reviewed_difference': 24, 'matching_failure': 30, 'interface_agreement': 2}
Independent oracle: subset_passed; {'reviewed_difference': 1}          (--corpus ci --only 0268-address-invalid-type)
```

### 6.4 PLACEHOLDER — Tier A on `1c21272e7` and the full battery on the review-fix tip (orchestrator-run): to be appended after the runs

## 7. Not done / open

- The judgement areas kept as upstream (§2.4): `&(int){3}`, the values `"hello"[1]` / `*"hello"`, a `const` object's
  value (rejected; gcc folds them), `(int)&g` (the constraint passes, UB024 at execution; gcc: not computable at load
  time), `(int *)(long)&g` and the offsetof idiom through an integer cast (UB055), `&g ? 3 : 4` and `_Generic` over
  `(long)&g` (rejected) — the filing's open questions for upstream (review P1-1, option (ii)).
- Residual fail-open vs gcc through the arithmetic predicate's retained `&` arm, upstream's (review P3-1): `(long)&g -
  (long)&ga[0]` runs (the table's one fail-open), `&g + (int)&g` passes the constraint and is UB024 at execution.
- Upstream's UB055 path for a non-arithmetic cast operand (review P3-2): `(int *)(double)3`, `(int *)(long)(int *)g`,
  `(long)&g + g` — UB055 where gcc gives a constraint diagnostic; the caller's bullet-4 tail and the cast arm's integer
  test are upstream's; a TODO item.
- Diagnostic-text class (review P3-5): an ill-typed decay-shaped initializer (`static int *q = gs.nope;`) reports the
  typing's own error at desugaring (`no member named 'nope' in 'struct S'`) where pristine said `not a compile-time
  constant`; as `ci/0268`; in no walked corpus.
- The `_Generic` arm of `is_integer_constant_expression` is the fork's reading of 6.5.1.1#3 (review P3-3c): 6.6#6 does
  not name generic selections; upstream's TODO crash is what it replaced; a question in the filing.
- An unevaluated `?:` branch or an unselected `_Generic` association that is not itself a constant expression is
  rejected (declared); selecting the association at desugar time would re-implement the typing's selection.
- The GNU `?:` in the enumerator, case-label, array-bound and `_Static_assert` contexts still crashes both engines
  (TODO's item; one gap row); in an initializer it is a constraint violation as before.
- Draft 08's nested-initializer class is reachable from `csmith_findings/oracle/init_addr_const.c` one stop earlier
  (§4.3); the witness programs fill their array of structs in `main` for that reason.
- `_Thread_local`: `&tls` is rejected (6.2.4#4; gcc rejects too); a thread-local's own initializer is decided by the
  same predicates (6.7.9#4 names thread storage duration) and was not probed beyond that one row.
- Bit-field widths are unsupported (`feature not yet supported: bit-fields`): the one probe excluded from the witness.
- The ci-sweep scoreboard TSVs: four rows change class at the next deliberate re-record (§4.3).
- Tray 09 stays Draft (fixed in the fork; the filing is the operator's network window).

## 8. Scratch, deleted at close-out

`.tmp/ac/` (the generator, the runner, the 446 programs and their four-engine lines before and after, the pre-change
engine snapshot — 288 M —, the corpus sweep's instrument, list and two result sets, the filing's patch derivations,
the pristine-lane runs), `.tmp/scripts/` run directories.
