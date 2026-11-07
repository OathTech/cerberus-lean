# The desugarer's constant-expression predicates reject §6.6 forms that conforming static initializers use (`&arr[i].field`, `?:`, `_Generic`, `"hello" + 1`, `(char *)&g + 4`, the decay of a member array), accept the comma operator and `&local`, and crash on `_Generic` in an integer constant expression

**Status (cerberus-lean fork):** fixed in the fork on 2026-11-07 as a fork-ahead delta (both engines by
generation; record `lean_frontend/docs/2026-11-07_address-constants-record.md`; witness
`scripts/check_address_constants.sh`, 244 programs); Draft for upstream, to be filed. Reports 28
(`?:` in a static initializer) and 29 (`"hello" + 1`) are merged into this one: the three share the
mechanism and the patch below, which is against `rems-project/cerberus` at `c3ff8c53f`.

**Affected:** `frontend/model/cabs_to_ail.lem` at `c3ff8c53f` — `is_integer_constant_expression`
(:585-790; the wildcard arm `| _ -> error ("TODO: Cabs_to_ail.is_integer_constant_expression, wildcard …")`
at :786), `is_arithmetic_constant_expression` (:821-877), `is_lvalue_to_static_object` (:879-917),
`is_address_constant` (:921-957) and their caller `is_initializer_constant_expression_or_string_literal`
(:962-989), which decides C17 6.7.9#4 for every static- or thread-storage initializer expression
(`desugaring_init.lem` :486-490 and `cabs_to_ail.lem` :3489-3491 raise
`Constraint.IllegalStorageClassStaticOrThreadInitializer`, printed as `initializer element is not a
compile-time constant`). The fork's copies of these regions were byte-identical to `c3ff8c53f` before
the fix.

## Description

C17 6.6#7 says an initializer constant expression "shall be, or evaluate to" an arithmetic constant
expression, a null pointer constant, an address constant, or an address constant for a complete object
type plus or minus an integer constant expression; 6.6#9 says an address constant is created by unary
`&` of an lvalue designating an object of static storage duration or a function designator, by an
integer constant cast to pointer type, or implicitly by an expression of array or function type, and
that `[]`, `.`, `->`, `&`, `*` and pointer casts may be used in its creation as long as no object's
value is accessed; 6.6#3 forbids assignment, increment, decrement, function-call and comma operators
except inside an unevaluated subexpression. The predicates cover only part of this:

1. `is_lvalue_to_static_object` has no `Indirection` arm. The desugarer rewrites `a[i]` to `*(a + i)`
   (`CabsEsubscript` → `AilEunary Indirection (AilEbinary … Add …)`, :2418), so `&g_arr[1].b` reaches
   `is_address_constant`'s `&` arm as `AilEmemberof (AilEunary Indirection (g_arr + 1)) b`, the
   `AilEmemberof` arm recurses into the `Indirection` node, and the predicate answers `false`.
   `&g_arr[1]` alone is accepted — but only through `is_arithmetic_constant_expression`'s `AilEunary
   Address e -> is_arithmetic_constant_expression true e`, whose `is_lvalue = true` makes the
   `AilEident _ -> E.return is_lvalue` arm accept ANY identifier: `&local` and `&param` in a block-scope
   `static` initializer pass the constraint too (gcc: `initializer element is not constant`), and so do
   `(long)g` and `&gsp->b` (a static pointer VARIABLE's value, through `is_lvalue_to_static_object`'s
   `AilEmemberofptr e _ -> is_lvalue_to_static_object e`).
2. `is_arithmetic_constant_expression` has no `AilEcond` or `AilEgeneric` arm: `?:` and `_Generic` in a
   static initializer fall to `| _ -> E.return false` (report 28; `is_integer_constant_expression`, used
   for enumerators, case labels, array bounds and `_Static_assert`, HAS the `?:` arms, so `?:` works
   there and not in initializers). Its generic `AilEbinary e1 _ e2` arm accepts the COMMA operator
   (`static int a = (1, 2);` runs on both engines; 6.6#3 forbids it, gcc `-pedantic-errors` rejects it),
   and its `AilEunary _ e` arm accepts `*&g` (a value read, 6.6#9) and the increment operators.
3. `is_address_constant` has no `AilEstr` arm, so `"hello" + 1` is not an address constant plus an
   integer constant expression (report 29; upstream `6b65dc04f` added `AilEstr -> true` to
   `is_lvalue_to_static_object` only, and the caller's bare-literal arm covers `"hello"` alone); no
   arm for `address constant ± integer constant expression` below the top level, so `(char *)&g + 4`
   reaches the caller's `Add` arm, which calls `is_integer_constant_expression false` on BOTH operands —
   on the cast operand `(char *)&g` that is 6.6#6's "shall" failure outside a Constraint, reported as
   `UB055_invalid_integer_constant_expression` on a conforming program; no decay of a member array or
   a matrix row (`gs.arr`, `gs.arr + 1`, `gsa[1].arr`, `g2[1]`), since `AilEmemberof`/`Indirection`
   lvalues are not examined; no `?:`/`_Generic` over address constants (`1 ? &a : &b`).
4. `is_integer_constant_expression` has no `AilEgeneric` (or `AilEcompound`) arm: `enum { E =
   _Generic(1, int: 3, default: 4) }`, `case _Generic(…):`, `int a[_Generic(…)]` and `_Static_assert(
   _Generic(…) == 3, "")` raise the wildcard `internal error` — a crash on a conforming program (and on
   a compound literal there, which gcc diagnoses).

## Reproducers (every program returns a small int; `cerberus --nolibc --exec --batch`)

```c
/* 09: & of an array element's member */
struct S { int a; int b; }; static struct S g[2] = {{1,2},{5,3}}; static int *q = &g[1].b; int main(void) { return *q; }
/* 28: the conditional operator in a static initializer */
static int a = (3 > 2) ? 10 : 20; int main(void) { return a; }
/* 29: a string literal plus an integer constant expression */
static const char *s = "hello" + 1; int main(void) { return *s; }
/* item 7: the decay of a member array plus an integer constant expression */
struct T { int a[3]; }; static struct T gs = {{1,2,3}}; static int *q2 = gs.a + 1; int main(void) { return *q2; }
/* item 7: a char * cast plus an offset */
static int g2[2] = {3, 4}; static char *q3 = (char *)&g2 + 4; int main(void) { return *q3; }
/* item 17: _Generic in an integer constant expression (an enumerator; the same in a case label, an array bound, a _Static_assert) */
enum E { E0 = _Generic(1, int: 3, default: 4) }; int main(void) { return E0; }
/* item 16: the comma operator (6.6#3) is accepted */
static int c = (1, 3); int main(void) { return c; }
/* & of an automatic object in a block-scope static initializer is accepted */
int main(void) { int l = 3; static int *q4 = &l; return *q4; }
```

Verbatim at pristine `c3ff8c53f` (2026-11-07; the fork's Lean engine, running the same desugarer,
printed `Error {msg: "desugaring failed at <file>:<loc>"}` on every rejected one):

```text
09:  r1.c:1:83: error: constraint violation: initializer element is not a compile-time constant        (exit 1)    gcc 3
28:  r2.c:1:16: error: constraint violation: initializer element is not a compile-time constant        (exit 1)    gcc 10
29:  r3.c:1:24: error: constraint violation: initializer element is not a compile-time constant        (exit 1)    gcc 101
gs.a + 1:         r4.c:1:74: error: constraint violation: initializer element is not a compile-time constant   (exit 1)    gcc 2
(char *)&g2 + 4:  Undefined {ub: "UB055_invalid_integer_constant_expression", stderr: "", loc: "<1:46--1:57>"}   (exit 1)    gcc 4
_Generic (enum):  internal error: TODO: Cabs_to_ail.is_integer_constant_expression, wildcard ==> _Generic(1, signed int: 3, default: 4)   (exit 125)   gcc 3
(1, 3):           Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}   (exit 0)    gcc: error: initializer element is not constant [-Wpedantic]
&l:               internal error: gentpying.annotate_expression: AilEident symbol couldn't be resolved => Symbol(504, SD_ObjectAddress"l")   (exit 125)   gcc: error: initializer element is not constant
```

(gcc 13.3.0, `gcc -std=c11 -pedantic-errors -O0`; `[-Wpedantic]`: without `-pedantic-errors` gcc accepts
the comma as an extension.)

## Observed vs expected

- Observed: conforming static initializers rejected with the 6.7.9#4 diagnostic (the `&arr[i].member`,
  `?:`, `_Generic`, `"literal" + k`, member-array and matrix-row decays), a UB055 verdict on `(char *)&g
  + 4`, an internal error on `_Generic` in every integer-constant context; and no diagnostic for the
  comma operator or for `&` of an automatic object in a static initializer.
- Expected: the listed forms accepted (6.6#7, #9; 6.3.2.1#3) and evaluated — 3, 10, 101, 2, 4, 3 as
  gcc —, the comma and the non-static `&` refused as 6.7.9#4 constraint violations (6.6#3, 6.6#9).

## Impact

Device and parser tables (`&table[i].field`), macro-generated initializers (`#define MAX(a,b) ((a)>(b)?(a):(b))`),
string tables (`"prefix-" + N`), `offsetof`-style idioms through `char *` casts, and any `_Generic`-based
constant in an enumerator or case label refuse the translation unit before execution; the comma and
`&local` cases run where a diagnostic is required.

## Proposed remedy (the fork's fix, a patch against `c3ff8c53f`)

The three predicates become one mutual block that implements 6.6#3-#9 arm by arm (every arm cites its
clause): `is_lvalue_to_static_object` gains `AilEunary Indirection e -> is_address_constant e` and tests
the base of `->` as an address constant; `is_address_constant` gains `AilEstr`, the `±` arms (the pointer
operand found first, so the UB055-raising integer test runs only on the other one), the recursive pointer
cast, `?:` and `_Generic` over address constants, and the decay of an lvalue of array or function type
built from a static object (`gs.arr`, `g2[1]`, `*f`: typed in `GenTyping.CTXsizeof`, where neither the
lvalue conversion nor the decay is performed — the same desugar-time typing the `sizeof` desugaring uses);
`is_arithmetic_constant_expression` gains `?:` and `_Generic`, whose operands it tests in 6.6#8's own terms
(a `no_address` mode: no address operand, so `&g ? 3 : 4` keeps your rejection while the top-level entry keeps
your acceptance of `(long)&g` and `&g == &g`), rejects the comma, the increment operators and the indirection
operator, and hands the operand of `&` to `is_lvalue_to_static_object` (or the function-designator test) instead
of accepting any identifier; the cast arm of `is_address_constant` keeps your arm for a non-pointer target (the
operand an lvalue to a static object, the target type not examined) with that lvalue required to be of ARRAY type
(the decay 6.6#9 names: `(long)ga` as before, `(long)g` a violation; `(int *)(long)&g` falls to your integer test
and its UB055 as before), and the base of `*`/`->` must designate an object (no null pointer constant, no integer
cast to pointer type: the offsetof idiom through `&((struct S *)0)->x` keeps your UB055);
`is_integer_constant_expression` gains the `_Generic` arm (every association, since the association is selected
during the Ail typing — the fork's reading of 6.5.1.1#3, since 6.6#6 does not name generic selections) and a `false`
for a compound literal; the caller tests 6.6#7's bullets in order. The accepted set is exactly your accepted set
plus the 6.6#3-#9 forms, nothing else, proved both directions on the 472-program table below. Deliberately NOT
changed: what 6.6#10 leaves to the implementation keeps your answer in both directions (`(long)&g`, `(long)ga`,
`(int *)16`, `&g == &g` accepted as before; `(int)&g` passing the constraint and UB024 at execution as before;
`&(int){3}`, `"hello"[1]` and a `const` object's value rejected as before; `(int *)(long)&g` and the offsetof idiom
UB055 as before); an unevaluated `?:` branch or an unselected `_Generic` association that is not a constant
expression is rejected (too strict, as `is_integer_constant_expression`'s own TODO says; never fail-open) — the
comma there included, although 6.6#3's own exception excuses it; the GNU `?:` keeps its rejection in the new arms
(accepting it would route it to the mini-run's known crash).

Applied to `c3ff8c53f` with `patch -p1` (dry run clean, no offsets):

```diff
--- a/frontend/model/cabs_to_ail.lem
+++ b/frontend/model/cabs_to_ail.lem
@@ -578,6 +578,28 @@
 
 
 (* BEGIN predicates on Ail syntax *)
+(* FORK (address-constants slice, 2026-11-07; upstream-tray reports 09, 28, 29; record
+   lean_frontend/docs/2026-11-07_address-constants-record.md): the constant-expression predicates
+   of this block accept the forms STD §6.6#3-#9 list and reject the operators §6.6#3 forbids. The
+   two helpers serve the generic-selection arms and the function-designator case of unary &. *)
+val expression_of_generic_association: generic_association unit -> expression unit
+let expression_of_generic_association ga =
+  match ga with
+    | AilGAtype _ _ e -> e
+    | AilGAdefault e -> e
+  end
+
+(* STD §6.6#9: "a pointer to a function designator" (an identifier declared as a function;
+   §6.5.1#2, §6.3.2.1#4) *)
+val is_function_designator_expression: expression unit -> E.desugM bool
+let is_function_designator_expression (AnnotatedExpression () _ _ expr) =
+  match expr with
+    | AilEident sym ->
+        E.is_function_designator sym
+    | _ ->
+        E.return false
+  end
+
 (* see §6.6#6 *)
 (* The is_constraint boolean informs whether the expression is specified to be an integer constant
  * expression by a Constraint section in standard. If not, "shall" failures from §6.6#6 are to be
@@ -780,6 +802,28 @@
     | AilEident _ ->
         E.return false
     
+    | AilEgeneric _ _ gas ->
+        (* STD §6.6#6 does not name generic selections among the operands of an integer constant
+           expression; this arm reads §6.5.1.1#3 (the result is the selected association's
+           expression, of identical type and value) as making the selection transparent -- the
+           fork's reading, universal practice, tray 09's open question for upstream. The controlling
+           expression is not evaluated (and is not walked); the association is selected during the
+           Ail typing, after this predicate runs, so every association's expression must be an
+           integer constant expression (too strict for an unselected one; never fail-open).
+           Upstream's wildcard arm raised an internal error on `int a[_Generic(1, int: 3, default: 4)]`
+           -- a crash on a conforming program (address-constants slice, 2026-11-07). *)
+        E.foldlM (fun acc ga ->
+          if not acc then
+            E.return false
+          else
+            is_integer_constant_expression (expression_of_generic_association ga)
+        ) true gas
+    | AilEcompound _ _ _ ->
+        (* STD §6.6#6: a compound literal is not among the operands of an integer constant
+           expression (upstream's wildcard arm raised an internal error on `case (int){3}:`;
+           address-constants slice, 2026-11-07) *)
+        E.return false
+
     | AilEgcc_statement _ _ ->
         E.fail loc (Errors.Desugar_NotYetSupported "GNU statement as expression in constant expression")
     
@@ -818,8 +862,30 @@
 (* STD §6.6#8 *)
 (* TODO: this is super partial and hackish *)
 (* TODO: I assume from the "shall only have operands" that arithmetic operations are allowed *)
+(* FORK (address-constants slice, 2026-11-07; upstream-tray reports 09, 28, 29; the pre-merge review's P1-1 ruling,
+   option (ii)): the predicates below are one mutual block whose accepted set is upstream's accepted set plus the
+   forms §6.6#3-#9 list and nothing else. is_arithmetic_constant_expression gains the conditional operator and the
+   generic selection (§6.6#3 forbids neither), whose operands are tested in §6.6#8's own terms (no address operand:
+   `&g ? 3 : 4` keeps upstream's rejection, while the top-level entry keeps upstream's acceptance of `(long)&g` and
+   `&g == &g`), rejects the comma and the increment operators (§6.6#3) and the indirection operator (§6.6#9: the
+   value of an object shall not be accessed), and hands the operand of unary & to is_lvalue_to_static_object instead
+   of accepting ANY identifier under it (`is_lvalue = true`), which let `&local` in a block-scope static initializer
+   through the §6.7.9#4 constraint. is_lvalue_to_static_object gains the indirection arm (`*p`, and `p[i]` desugared
+   to `*(p + i)`: §6.6#9 lists the subscript and the indirection operators) and tests the base of -> as an address
+   constant that designates an object. is_address_constant gains the string literal, the conditional operator, the
+   generic selection, `plus or minus an integer constant expression` (§6.6#7), the pointer cast of an address constant
+   and the decay of a static array or function lvalue (§6.3.2.1#3-#4; typed in the sizeof context, where neither the
+   lvalue conversion nor the decay is performed); a cast to a non-pointer type keeps upstream's arm. Every arm cites
+   its clause; where §6.6#10 leaves a form to the implementation, the answer is upstream's in both directions. *)
+val     is_arithmetic_constant_expression_: bool -> bool -> expression unit -> E.desugM bool
 val     is_arithmetic_constant_expression: bool -> expression unit -> E.desugM bool
-let rec is_arithmetic_constant_expression is_lvalue ((AnnotatedExpression () _ loc expr)) =
+val     is_lvalue_to_static_object: expression unit -> E.desugM bool
+val     is_address_constant_: bool -> expression unit -> E.desugM bool
+val     is_address_constant: expression unit -> E.desugM bool
+val     static_lvalue_type: expression unit -> E.desugM (maybe Ctype.ctype)
+val     is_decayed_static_lvalue: expression unit -> E.desugM bool
+val     is_static_array_lvalue: expression unit -> E.desugM bool
+let rec is_arithmetic_constant_expression_ no_address is_lvalue ((AnnotatedExpression () _ loc expr)) =
   match expr with
     | AilEconst (ConstantInteger _) ->
         E.return true
@@ -842,18 +908,86 @@
 
     (* TODO: not sure about this! but I want to include enumerations *)
     | AilEannot _ e ->
-        is_arithmetic_constant_expression true e
+        is_arithmetic_constant_expression_ no_address true e
 
     | AilEunary Address e ->
-        is_arithmetic_constant_expression true e
+        (* STD §6.6#9: the operand of & is an lvalue designating an object of static storage
+           duration, or a function designator. An arithmetic constant expression has no & operand
+           (§6.6#8): under no_address (the operands of a conditional or a generic selection, below)
+           the arm answers false -- upstream's predicate had no arm to compose an address with, so
+           `&g ? 3 : 4` and `_Generic(1, int: (long)&g, default: 2)` keep upstream's rejection. At the
+           top level the arm keeps upstream's acceptance of an address constant inside an
+           arithmetic-typed expression (`(long)&g`, `&g == &g`: §6.6#10 forms gcc accepts as well).
+           Upstream recursed with is_lvalue = true, accepting ANY identifier under &: `&local` in a
+           block-scope static initializer passed the §6.7.9#4 constraint (gcc: a violation). *)
+        if no_address then
+          E.return false
+        else
+          is_lvalue_to_static_object e >>= function
+            | true ->
+                E.return true
+            | false ->
+                is_function_designator_expression e
+          end
+    | AilEunary Indirection _ ->
+        (* STD §6.6#9: the value of an object shall not be accessed by use of the indirection
+           operator -- `*&g` is not a constant expression (gcc rejects it); upstream recursed into
+           the operand. An address constant under * (`*(g2 + 1)`, a row of a static matrix) is
+           is_address_constant's decay arm. *)
+        E.return false
+    | AilEunary PostfixIncr _ ->
+        (* STD §6.6#3 *)
+        E.return false
+    | AilEunary PostfixDecr _ ->
+        (* STD §6.6#3 *)
+        E.return false
     | AilEunary _ e ->
-        is_arithmetic_constant_expression is_lvalue e
+        is_arithmetic_constant_expression_ no_address is_lvalue e
 
+    | AilEbinary _ Comma _ ->
+        (* STD §6.6#3: constant expressions shall not contain comma operators, except when they
+           are contained within a subexpression that is not evaluated. The exception is not taken
+           here: a comma in an unevaluated branch of ?: or in an unselected _Generic association
+           (`1 ? 3 : (1, 2)`) reaches this arm and is rejected -- upstream's own rejection, kept as a
+           declared over-strictness (the record's F5; filed in tray 09). sizeof's operand is typed
+           away and _Generic's controlling expression is not walked. Upstream's binary arm accepted
+           `static int a = (1, 2);` (gcc: a violation). *)
+        E.return false
     | AilEbinary e1 _ e2 ->
-        is_arithmetic_constant_expression is_lvalue e1 >>= fun b1 ->
-        is_arithmetic_constant_expression is_lvalue e2 >>= fun b2 ->
+        is_arithmetic_constant_expression_ no_address is_lvalue e1 >>= fun b1 ->
+        is_arithmetic_constant_expression_ no_address is_lvalue e2 >>= fun b2 ->
         E.return (b1 && b2)
 
+    | AilEcond e1 e2_opt e3 ->
+        (* STD §6.6#3 does not forbid the conditional operator (tray 28). Every branch must be a
+           constant expression in §6.6#8's own terms (no address operand), as in
+           is_integer_constant_expression's arms: an unevaluated branch that is not (`1 ? 3 : f()`)
+           is rejected -- too strict (that arm's own TODO), never fail-open. The GNU form `e1 ?: e3`
+           (no middle operand) is not a C constant expression (gcc -pedantic-errors rejects it) and
+           keeps upstream's rejection here: accepting it would send it to the mini-run's known crash
+           (TODO: GNU ?: in a constant-expression position). *)
+        (match e2_opt with
+          | Just e2 ->
+              is_arithmetic_constant_expression_ true is_lvalue e1 >>= fun b1 ->
+              is_arithmetic_constant_expression_ true is_lvalue e2 >>= fun b2 ->
+              is_arithmetic_constant_expression_ true is_lvalue e3 >>= fun b3 ->
+              E.return (b1 && b2 && b3)
+          | Nothing ->
+              E.return false
+        end)
+    | AilEgeneric _ _ gas ->
+        (* STD §6.5.1.1#3: the value is the selected association's expression; the controlling
+           expression is not evaluated (and is not walked). The association is selected during the
+           Ail typing, after this predicate runs, so every association's expression must be a
+           constant expression in §6.6#8's own terms (too strict for an unselected one; never
+           fail-open). *)
+        E.foldlM (fun acc ga ->
+          if not acc then
+            E.return false
+          else
+            is_arithmetic_constant_expression_ true is_lvalue (expression_of_generic_association ga)
+        ) true gas
+
     | AilEsizeof _ ty ->
         (* TODO: sizeof expressions whose results are integer constants *)
         E.return (not (AilTypesAux.is_vla ty))
@@ -866,7 +1000,7 @@
           E.print_debugM 2 (fun () -> "WARNING[Cabs_to_ail.is_arithmetic_constant_expression] AilEcast: annoying ==> need to typecheck e...") >>
 (*          E.return true *)
           (* TODO: is_lvalue might be wrong depending on the type of e? *)
-          is_arithmetic_constant_expression is_lvalue e
+          is_arithmetic_constant_expression_ no_address is_lvalue e
     | AilEoffsetof _ _ ->
         (* STD §7.19#3 *)
         E.return true
@@ -875,59 +1009,62 @@
 
   end
 
+(* the top-level entry (the caller and the condition tests): upstream's arms as they were, the
+   conditional and the generic selection added *)
+and is_arithmetic_constant_expression is_lvalue a_expr =
+  is_arithmetic_constant_expression_ false is_lvalue a_expr
 
-val     is_lvalue_to_static_object: expression unit -> E.desugM bool
-let rec is_lvalue_to_static_object (AnnotatedExpression () _ loc expr) =
+
+and is_lvalue_to_static_object (AnnotatedExpression () _ loc expr) =
   match expr with
     | AilEident sym ->
         E.is_static_object_identifier sym
 (* The array-subscript [] and member-access . and -> operators, the address & and indirection * unary operators, and pointer casts may be used in the creation of an address constant, but the value of an object shall not be accessed by use of these operators. *)
-    | AilEbinary e1 (Arithmetic Add) e2 ->
-        (* NOTE: this case corresponds to array-subcript *)
-        is_lvalue_to_static_object e1        >>= fun b11 ->
-        is_arithmetic_constant_expression false (* TODO check *) e1 >>= fun b12 ->
-        is_lvalue_to_static_object e2        >>= fun b21 ->
-        is_arithmetic_constant_expression false (* TODO check *) e2 >>= fun b22 ->
-        E.return (b11 && b22 || b12 && b21)
+    | AilEunary Indirection e ->
+        (* STD §6.6#9: `*p` for an address constant p that designates an object; `p[i]` is
+           `*(p + i)` (§6.5.2.1#2), so `&g_arr[1].b` reaches this arm as
+           AilEmemberof (AilEunary Indirection (g_arr + 1)) b (tray 09; upstream had no arm and
+           rejected it). No value is accessed: the result is an lvalue the caller takes the address
+           of, selects a member of, or decays. *)
+        is_address_constant_ true e
     | AilEmemberof e _ ->
-        (* TODO: not sure *)
+        (* STD §6.6#9: `.` on an lvalue designating a static object *)
         is_lvalue_to_static_object e
     | AilEmemberofptr e _ ->
-        (* TODO: not sure *)
-        is_lvalue_to_static_object e
-    | AilEcast _ ty e ->
-        (* TODO: check *)
-        if not (AilTypesAux.is_pointer ty) then
-          E.return false
-        else
-          is_lvalue_to_static_object e
-
+        (* STD §6.6#9 with §6.5.2.3#4 (`p->m` is `( *p).m`): the base is an address constant that
+           designates an object -- `&((struct S * )&gs)->b` -- and never a pointer OBJECT whose value
+           would be read: `&gsp->b` with gsp a static pointer variable is not a constant (gcc rejects
+           it). Upstream tested the base as an lvalue to a static object: the opposite pair of
+           answers. *)
+        is_address_constant_ true e
     | AilEstr _ ->
         (* String literals decay to a pointer to the start of an array of
            static storage duration (except when directly initialising an array,
            but this is not relevant here) *)
         E.return true
-
-(* TODO
-    | AilEmemberof e ident ->
-*)
     | _ ->
+        (* a sum (upstream's approximation of the subscript, now the * arm) and a cast (§6.5.4#5)
+           are not lvalues *)
         E.return false
   end
 
 
-
 (* STD §6.6#9 *)
-val is_address_constant: expression unit -> E.desugM bool
-let is_address_constant a_expr =
+(* designates_object: the base of * or -> must designate an object of static storage duration
+   (§6.6#9: "a pointer to an lvalue designating an object"). A null pointer constant and an integer
+   constant cast to pointer type are address constants but designate none, so under the flag they
+   answer false: `&((struct S * )0)->x` (the offsetof idiom) keeps upstream's UB055 verdict and
+   `&*(int * )16` upstream's rejection, while `&((struct S * )&gs)->b` is accepted. At the top level
+   (the flag false) both are address constants, as upstream had them. *)
+and is_address_constant_ designates_object (AnnotatedExpression () _ _ expr as a_expr) =
   (* TODO: not sure is_null_pointer_constant is the right predicate *)
   (* An address constant (...) *)
-  if AilSyntaxAux.is_null_pointer_constant a_expr then
+  if (not designates_object) && AilSyntaxAux.is_null_pointer_constant a_expr then
     (* (...) is a null pointer, *)
     E.return true
   
-  else match a_expr with
-    | AnnotatedExpression () _ _ (AilEident sym) ->
+  else match expr with
+    | AilEident sym ->
         E.is_function_designator sym >>= function
           | true ->
               E.return true
@@ -940,14 +1077,180 @@
                     E.return false
               end
         end
-    | AnnotatedExpression () _ _ (AilEunary Address expr) ->
-        is_lvalue_to_static_object expr
-    | AnnotatedExpression () _ _ (AilEcast _ _ expr) ->
-        is_lvalue_to_static_object expr >>= function
+    | AilEstr _ ->
+        (* STD §6.6#9 with §6.4.5#6: a string literal is an array object of static storage
+           duration; used as a pointer it decays (§6.3.2.1#3) to an address constant, so
+           `"hello" + 1` is an address constant plus an integer constant expression (tray 29).
+           Upstream 6b65dc04f gave is_lvalue_to_static_object this arm; this predicate lacked it. *)
+        E.return true
+    | AilEunary Address e ->
+        (* STD §6.6#9: created explicitly using the unary & operator, of an lvalue designating an
+           object of static storage duration or of a function designator *)
+        is_lvalue_to_static_object e >>= function
           | true ->
               E.return true
           | false ->
-              is_integer_constant_expression false(*not Constraint *) expr
+              is_function_designator_expression e
+        end
+    | AilEcast _ ty e ->
+        if AilTypesAux.is_pointer ty then
+          (* STD §6.6#9: a pointer cast of an address constant (`(int * )(char * )&g`,
+             `(void * )&gs.b`), or an integer constant cast to pointer type (`(int * )16`; it
+             designates no object: not under the flag). The address test comes first:
+             is_integer_constant_expression raises UB055 on a cast operand that is not arithmetic
+             (§6.6#6's "shall" is not a constraint). *)
+          is_address_constant_ designates_object e >>= function
+            | true ->
+                E.return true
+            | false ->
+                if designates_object then
+                  E.return false
+                else
+                  is_integer_constant_expression false(*not Constraint *) e
+          end
+        else
+          (* A cast to a non-pointer type: upstream's arm kept in shape -- the operand an lvalue to a
+             static object, the target type not examined -- with the lvalue required to be of array
+             type (the decay §6.6#9 names), so `(long)ga`, `(long)gs.arr` and `(long)"s"` stay accepted
+             as upstream accepted them while `(long)g` (a value read) is the §6.7.9#4 violation gcc
+             reports. Upstream's arm also took an integer constant expression here (`(long)5` as an
+             "address constant"), which no conforming program needs (the arithmetic predicate accepts
+             it; under a pointer cast the test above applies one level up, as upstream applied it):
+             not taken, so that `(int * )(double)3` keeps upstream's UB055 verdict. An address constant
+             under such a cast is not an address constant: `(int * )(long)&g` keeps upstream's UB055
+             (the integer test above, §6.6#6's "shall" outside a Constraint). *)
+          is_static_array_lvalue e
+    | AilEbinary e1 (Arithmetic Add) e2 ->
+        (* STD §6.6#7, fourth bullet, with §6.6#9: an address constant for an object type plus an
+           integer constant expression, in either operand order (§6.5.6#2); the pointer operand is
+           found first so that the integer test only runs on the other one *)
+        is_address_constant_ designates_object e1 >>= function
+          | true ->
+              is_integer_constant_expression false(*not Constraint *) e2
+          | false ->
+              is_address_constant_ designates_object e2 >>= function
+                | true ->
+                    is_integer_constant_expression false(*not Constraint *) e1
+                | false ->
+                    E.return false
+              end
+        end
+    | AilEbinary e1 (Arithmetic Sub) e2 ->
+        (* STD §6.6#7, fourth bullet: minus an integer constant expression (§6.5.6#3: the pointer
+           is the left operand) *)
+        is_address_constant_ designates_object e1 >>= function
+          | true ->
+              is_integer_constant_expression false(*not Constraint *) e2
+          | false ->
+              E.return false
+        end
+    | AilEcond e1 e2_opt e3 ->
+        (* STD §6.6#7 ("shall be, or evaluate to"): a conditional over address constants evaluates
+           to one of them (`1 ? &a : &b`); the condition is an arithmetic constant expression in
+           §6.6#8's own terms (`&g ? &a : &b` keeps upstream's rejection) and every branch an address
+           constant (an unevaluated branch that is not is rejected: too strict, never fail-open).
+           The GNU form `e1 ?: e3` keeps upstream's rejection (see the arithmetic predicate's arm). *)
+        (match e2_opt with
+          | Just e2 ->
+              is_arithmetic_constant_expression_ true false e1 >>= fun b1 ->
+              is_address_constant_ designates_object e2 >>= fun b2 ->
+              is_address_constant_ designates_object e3 >>= fun b3 ->
+              E.return (b1 && b2 && b3)
+          | Nothing ->
+              E.return false
+        end)
+    | AilEgeneric _ _ gas ->
+        (* STD §6.5.1.1#3 with §6.6#7: the selected association's expression; selected during the
+           Ail typing, so every association must be an address constant (too strict for an
+           unselected one) *)
+        E.foldlM (fun acc ga ->
+          if not acc then
+            E.return false
+          else
+            is_address_constant_ designates_object (expression_of_generic_association ga)
+        ) true gas
+    | AilEmemberof _ _ ->
+        is_decayed_static_lvalue a_expr
+    | AilEmemberofptr _ _ ->
+        is_decayed_static_lvalue a_expr
+    | AilEunary Indirection _ ->
+        is_decayed_static_lvalue a_expr
+    | _ ->
+        E.return false
+  end
+
+(* the top-level entry: the initializer itself, an operand of +/- and a branch of ?: or _Generic *)
+and is_address_constant a_expr =
+  is_address_constant_ false a_expr
+
+
+(* The un-decayed type of an lvalue built with [], ., -> and * from a static object (or from an
+   address constant under the indirection operator): Nothing when it is not such an lvalue, else the
+   type the sizeof desugaring reads -- the expression annotated in GenTyping.CTXsizeof, where neither
+   the lvalue conversion nor the decay is performed (genTyping.lem, the CTXsizeof guards of both). A
+   typing error is the program's own and is reported as such (the Ail typing would raise it next). *)
+and static_lvalue_type (AnnotatedExpression () _ _ _ as a_expr) =
+  is_lvalue_to_static_object a_expr >>= function
+    | false ->
+        E.return Nothing
+    | true ->
+        E.get_sigma_sofar >>= fun sigm ->
+        E.get_gamma_sofar >>= fun gamm ->
+        match ErrorMonad.runErrorMonad (Mini_pipeline.annotate_expression_seeded (Map.fromList sigm.enum_definitions) E.desugar_time_tagDefs Nothing sigm gamm GenTyping.CTXsizeof a_expr) with
+          | Left (loc, err) ->
+              E.fail_ailtyping loc err
+          | Right an_expr ->
+              let (_, ty) = Mini_pipeline.qualified_ctype_of_seeded (Map.fromList sigm.enum_definitions) E.desugar_time_tagDefs an_expr in
+              E.return (Just ty)
+        end
+  end
+
+(* STD §6.6#9, "implicitly by the use of an expression of array or function type", with
+   §6.3.2.1#3-#4: such an lvalue is itself an address constant when its type is an array or a
+   function type (`gs.arr`, `gsa[1].arr`, `g2[1]`, `*(g2 + 1)`, `*f`): it decays without accessing
+   any object. Any other such lvalue (`gs.b`, `gq.p`, `*&g`) would be read. *)
+and is_decayed_static_lvalue a_expr =
+  static_lvalue_type a_expr >>= function
+    | Nothing ->
+        E.return false
+    | Just ty ->
+        E.return (AilTypesAux.is_array ty || AilTypesAux.is_function ty)
+  end
+
+(* The operand of a cast to a non-pointer type (is_address_constant's cast arm): a static lvalue of
+   array type -- an identifier declared as a static array (read from its declaration, as upstream's
+   ident arm does), a string literal, or a member or row lvalue whose un-decayed type is an array. *)
+and is_static_array_lvalue (AnnotatedExpression () _ _ expr as a_expr) =
+  match expr with
+    | AilEident sym ->
+        E.is_function_designator sym >>= function
+          | true ->
+              E.return false
+          | false ->
+              E.fetch_object_declaration sym >>= fun (_, _, dur, _, _, _, ty) ->
+              match dur with
+                | Static ->
+                    E.return (AilTypesAux.is_array ty)
+                | _ ->
+                    E.return false
+              end
+        end
+    | AilEstr _ ->
+        E.return true
+    | AilEmemberof _ _ ->
+        static_lvalue_type a_expr >>= function
+          | Nothing -> E.return false
+          | Just ty -> E.return (AilTypesAux.is_array ty)
+        end
+    | AilEmemberofptr _ _ ->
+        static_lvalue_type a_expr >>= function
+          | Nothing -> E.return false
+          | Just ty -> E.return (AilTypesAux.is_array ty)
+        end
+    | AilEunary Indirection _ ->
+        static_lvalue_type a_expr >>= function
+          | Nothing -> E.return false
+          | Just ty -> E.return (AilTypesAux.is_array ty)
         end
     | _ ->
         E.return false
@@ -963,7 +1266,13 @@
 let is_initializer_constant_expression_or_string_literal (AnnotatedExpression () _ loc expr as a_expr) =
   let is_integer_constant_expression = is_integer_constant_expression false(*not Constraint *) in
   is_arithmetic_constant_expression false (* TODO check *) a_expr >>= fun b1 ->
-  is_address_constant a_expr               >>= fun b2 ->
+  (* FORK (address-constants slice, 2026-11-07): the bullets in order -- is_address_constant is
+     consulted only when the expression is not an arithmetic constant expression. Upstream ran both
+     predicates and or'ed them; with is_address_constant's `plus or minus` arms that would run
+     is_integer_constant_expression (UB055 on a cast of a non-arithmetic operand) on the integer
+     operand of an address-shaped sum whose whole is already an arithmetic constant expression
+     (`(int)(long)&g - (int)(long)&g + 3`, a §6.6#10 form upstream and gcc accept). *)
+  (if b1 then E.return true else is_address_constant a_expr) >>= fun b2 ->
   (* STD §6.6#7, bullets 1 - 3 *)
   if b1 || AilSyntaxAux.is_null_pointer_constant a_expr || b2 then
     E.return true
```

Measured in the fork (both engines by generation, 472 programs over gcc 13.3.0 `-std=c11 -pedantic-errors`,
pristine `c3ff8c53f` and both engines; `lean_frontend/docs/2026-11-07_address-constants-record.md` §3): before,
77 conforming programs rejected, 3 constraint violations accepted, 84 crashes (the `_Generic`/compound-literal
wildcard, the `&local` typing crash, and a preamble shape of the probe generator's own); after, 94 programs the
fork accepts and pristine does not — every one gcc-accepted and a 6.6#3-#9 form —, 12 programs pristine accepts
and the fork does not — every one gcc-rejected —, 0 engine disagreements, 26 declared over-strict rejections,
one residual fail-open of yours (`(long)&g - (long)&ga[0]`, below), the 4 GNU-`?:` crashes of a separate finding.
No gated corpus row moved; the comma case and the closed fail-opens are the only accepted-to-rejected moves
(the record §4).

## Open questions for upstream (the fork keeps your answer on each)

- The comma in an unevaluated `?:` branch or an unselected `_Generic` association (`static int a = 1 ? 3 : (1,
  2);`, `_Generic(1, int: 3, default: (1, 2))`; gcc 3): 6.6#3's own exception ("except when they are contained
  within a subexpression that is not evaluated") with 6.5.15#4 excuses it; your `?:` arms in
  `is_integer_constant_expression` reject any non-constant branch under their "too strict" TODO, and the fork
  keeps that reading in the new arms.
- `_Generic` in an integer constant expression (`enum { E = _Generic(1, int: 3, default: 4) }`, a case label, an
  array bound, a `_Static_assert`): 6.6#6 does not name generic selections; the fork reads 6.5.1.1#3 (the result is
  the selected association's expression, of identical type and value) as making the selection transparent, and
  requires every association to be an ICE since the selection happens in the Ail typing; your wildcard arm crashes.
- The 6.6#10 forms, kept at your answers: `&(int){3}` (a compound literal has static storage duration at file
  scope, 6.5.2.5#5; gcc accepts), the values `"hello"[1]` / `*"hello"` and a `const` object's value (gcc folds
  them), `(int)&g` (passes the constraint, UB024 at execution; gcc: not computable at load time), `(int
  *)(long)&g` and the offsetof idiom `(int)(unsigned long)&((struct S *)0)->x` (UB055 verdicts; gcc accepts), `&g ?
  3 : 4` and `_Generic(1, int: (long)&g, default: 2)` (rejected; gcc accepts).
- Residuals through the arithmetic predicate's retained `&` arm (any address constant as an arithmetic operand):
  `static long l = (long)&g - (long)&ga[0];` runs and `static int *q = &g + (int)&g;` passes the constraint and is
  UB024 at execution; gcc rejects both.
- Your UB055 path for a non-arithmetic cast operand: `(int *)(double)3`, `(int *)(long)(int *)g`, `(long)&g + g`
  are `UB055_invalid_integer_constant_expression` verdicts where gcc gives a constraint diagnostic (the caller's
  bullet-4 tail runs `is_integer_constant_expression` on both operands; the cast arm's integer test on a
  non-arithmetic operand).

## Related findings (not this mechanism)

- An ill-typed decay-shaped initializer (`static int *q = gs.nope;`) now reports the typing's own error at
  desugaring (`no member named 'nope' in 'struct S'`) where you said `initializer element is not a compile-time
  constant`: the fix types such operands in the sizeof context.

- `enum { E = 3 ?: 4 }`, `case (3 ?: 4):`, `int b[(3 ?: 4)]`, `_Static_assert((3 ?: 4) == 3, "")`: the
  GNU conditional in an integer-constant context dies with `PEcase, mismatched` / `the driver found
  less/more …` (an `E.record_error_at` the mini-run discards; the fork's TODO item), unchanged here.
- A braced initializer of an array of structs whose members include an array (`static struct S gsa[2] =
  {{0, 0, {0, 0, 0}, {0}}, …}`) yields `Translation called on Ail program with an invalid node` (report
  08's nested-initializer class); the fix's witnesses fill such an array in `main` instead.

## Classification

**TRUE BUG** (over-strict rejections of conforming programs with the checker's own 6.7.9#4 diagnostic;
fail-open acceptances of constraint violations — three in the first table, twelve closed by the vicinity: the
comma in three shapes, `*&g`, the pointer-variable chains, `(long)g`, `(int *)g`, `&local`, `&tls`; crashes on
conforming `_Generic` uses). The fork fixes
it as a fork-ahead delta; the patch is offered as is.

## Provenance

Reports 09 (2026-08-21, arc-12 S3), 28 and 29 (2026-09-03, the semantic-discrepancy probe campaign,
findings E3/E5) were found over the fork's Lean port and verified un-forked at `b9aeedcb4`; the
true-bug audit of 2026-11-04 (base `c3ff8c53f`) added the sibling forms (its §4 items 7, 16, 17) and
localised the mechanism; the fix, the §6.6 probe table and this merged report are the
`fix/address-constants` slice of 2026-11-07 by Claude (Fable 5.1) under operator direction; the filed
issue carries an AI-provenance note per the tray's policy.
