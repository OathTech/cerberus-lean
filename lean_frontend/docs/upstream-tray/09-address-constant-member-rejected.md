# The desugarer's constant-expression predicates reject §6.6 forms that conforming static initializers use (`&arr[i].field`, `?:`, `_Generic`, `"hello" + 1`, `(char *)&g + 4`, the decay of a member array), accept the comma operator and `&local`, and crash on `_Generic` in an integer constant expression

**Status (cerberus-lean fork):** fixed in the fork on 2026-11-07 as a fork-ahead delta (both engines by
generation; record `lean_frontend/docs/2026-11-07_address-constants-record.md`; witness
`scripts/check_address_constants.sh`, 234 programs); Draft for upstream, to be filed. Reports 28
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
`is_arithmetic_constant_expression` gains `?:` and `_Generic`, rejects the comma, the increment operators
and the indirection operator, and hands the operand of `&` to `is_lvalue_to_static_object` (or the
function-designator test) instead of accepting any identifier; `is_integer_constant_expression` gains the
`_Generic` arm (every association, since the association is selected during the Ail typing) and a
`false` for a compound literal; the caller tests 6.6#7's bullets in order. Deliberately NOT changed: what
6.6#10 leaves to the implementation keeps upstream's answer (`(long)&g`, `(int *)16`, `&g == &g` accepted
as before; `&(int){3}`, `"hello"[1]` and a `const` object's value rejected as before); an unevaluated
`?:` branch or an unselected `_Generic` association that is not a constant expression is rejected (too
strict, as `is_integer_constant_expression`'s own TODO says; never fail-open); the GNU `?:` keeps its
rejection in the new arms (accepting it would route it to the mini-run's known crash).

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
@@ -780,6 +802,25 @@
     | AilEident _ ->
         E.return false
     
+    | AilEgeneric _ _ gas ->
+        (* STD §6.5.1.1#3: the value is the selected association's expression; the controlling
+           expression is not evaluated (and is not walked). The association is selected during the
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
     
@@ -818,7 +859,25 @@
 (* STD §6.6#8 *)
 (* TODO: this is super partial and hackish *)
 (* TODO: I assume from the "shall only have operands" that arithmetic operations are allowed *)
+(* FORK (address-constants slice, 2026-11-07; upstream-tray reports 09, 28, 29): the three
+   predicates below are one mutual block (is_lvalue_to_static_object's indirection arm and
+   is_address_constant's & arm call each other). is_arithmetic_constant_expression gains the
+   conditional operator and the generic selection (§6.6#3 forbids neither), rejects the comma and
+   the increment operators (§6.6#3) and the indirection operator (§6.6#9: the value of an object
+   shall not be accessed), and hands the operand of unary & to is_lvalue_to_static_object instead
+   of accepting ANY identifier under it (`is_lvalue = true`), which let `&local` in a block-scope
+   static initializer and `(long)g` through the §6.7.9#4 constraint. is_lvalue_to_static_object
+   gains the indirection arm (`*p`, and `p[i]` desugared to `*(p + i)`: §6.6#9 lists the subscript and the indirection operators) and
+   tests the base of -> as an address constant. is_address_constant gains the string literal, the
+   conditional operator, the generic selection, `plus or minus an integer constant expression`
+   (§6.6#7), the recursive pointer cast and the decay of a static array or function lvalue
+   (§6.3.2.1#3-#4; typed in the sizeof context, where neither the lvalue conversion nor the decay is
+   performed). Every arm cites its clause; where §6.6#10 leaves a form to the implementation, the
+   answer is upstream's. *)
 val     is_arithmetic_constant_expression: bool -> expression unit -> E.desugM bool
+val     is_lvalue_to_static_object: expression unit -> E.desugM bool
+val     is_address_constant: expression unit -> E.desugM bool
+val     is_decayed_static_lvalue: expression unit -> E.desugM bool
 let rec is_arithmetic_constant_expression is_lvalue ((AnnotatedExpression () _ loc expr)) =
   match expr with
     | AilEconst (ConstantInteger _) ->
@@ -845,15 +904,72 @@
         is_arithmetic_constant_expression true e
 
     | AilEunary Address e ->
-        is_arithmetic_constant_expression true e
+        (* STD §6.6#9: the operand of & is an lvalue designating an object of static storage
+           duration, or a function designator. An arithmetic constant expression has no & operand
+           (§6.6#8); this arm keeps upstream's acceptance of an address constant inside an
+           arithmetic-typed expression (`(long)&g`, `&g == &g`: §6.6#10 forms gcc accepts as well).
+           Upstream recursed with is_lvalue = true, accepting ANY identifier under &: `&local` in a
+           block-scope static initializer passed the §6.7.9#4 constraint (gcc: a violation). *)
+        is_lvalue_to_static_object e >>= function
+          | true ->
+              E.return true
+          | false ->
+              is_function_designator_expression e
+        end
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
         is_arithmetic_constant_expression is_lvalue e
 
+    | AilEbinary _ Comma _ ->
+        (* STD §6.6#3: constant expressions shall not contain comma operators (an unevaluated
+           operand never reaches here: sizeof's operand is typed away and _Generic's controlling
+           expression is not walked). Upstream's binary arm accepted `static int a = (1, 2);`
+           (gcc: a violation). *)
+        E.return false
     | AilEbinary e1 _ e2 ->
         is_arithmetic_constant_expression is_lvalue e1 >>= fun b1 ->
         is_arithmetic_constant_expression is_lvalue e2 >>= fun b2 ->
         E.return (b1 && b2)
 
+    | AilEcond e1 e2_opt e3 ->
+        (* STD §6.6#3 does not forbid the conditional operator (tray 28). Every branch must be a
+           constant expression, as in is_integer_constant_expression's arms: an unevaluated branch
+           that is not (`1 ? 3 : f()`) is rejected -- too strict (that arm's own TODO), never
+           fail-open. The GNU form `e1 ?: e3` (no middle operand) is not a C constant expression
+           (gcc -pedantic-errors rejects it) and keeps upstream's rejection here: accepting it would
+           send it to the mini-run's known crash (TODO: GNU ?: in a constant-expression position). *)
+        (match e2_opt with
+          | Just e2 ->
+              is_arithmetic_constant_expression is_lvalue e1 >>= fun b1 ->
+              is_arithmetic_constant_expression is_lvalue e2 >>= fun b2 ->
+              is_arithmetic_constant_expression is_lvalue e3 >>= fun b3 ->
+              E.return (b1 && b2 && b3)
+          | Nothing ->
+              E.return false
+        end)
+    | AilEgeneric _ _ gas ->
+        (* STD §6.5.1.1#3: the value is the selected association's expression; the controlling
+           expression is not evaluated (and is not walked). The association is selected during the
+           Ail typing, after this predicate runs, so every association's expression must be a
+           constant expression (too strict for an unselected one; never fail-open). *)
+        E.foldlM (fun acc ga ->
+          if not acc then
+            E.return false
+          else
+            is_arithmetic_constant_expression is_lvalue (expression_of_generic_association ga)
+        ) true gas
+
     | AilEsizeof _ ty ->
         (* TODO: sizeof expressions whose results are integer constants *)
         E.return (not (AilTypesAux.is_vla ty))
@@ -876,58 +992,48 @@
   end
 
 
-val     is_lvalue_to_static_object: expression unit -> E.desugM bool
-let rec is_lvalue_to_static_object (AnnotatedExpression () _ loc expr) =
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
+        (* STD §6.6#9: `*p` for an address constant p; `p[i]` is `*(p + i)` (§6.5.2.1#2), so
+           `&g_arr[1].b` reaches this arm as AilEmemberof (AilEunary Indirection (g_arr + 1)) b
+           (tray 09; upstream had no arm and rejected it). No value is accessed: the result is an
+           lvalue the caller takes the address of, selects a member of, or decays. *)
+        is_address_constant e
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
+        (* STD §6.6#9 with §6.5.2.3#4 (`p->m` is `( *p).m`): the base is an address constant --
+           `&((struct S * )&gs)->b` -- and never a pointer OBJECT whose value would be read:
+           `&gsp->b` with gsp a static pointer variable is not a constant (gcc rejects it).
+           Upstream tested the base as an lvalue to a static object: the opposite pair of answers. *)
+        is_address_constant e
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
+and is_address_constant (AnnotatedExpression () _ _ expr as a_expr) =
   (* TODO: not sure is_null_pointer_constant is the right predicate *)
   (* An address constant (...) *)
   if AilSyntaxAux.is_null_pointer_constant a_expr then
     (* (...) is a null pointer, *)
     E.return true
   
-  else match a_expr with
-    | AnnotatedExpression () _ _ (AilEident sym) ->
+  else match expr with
+    | AilEident sym ->
         E.is_function_designator sym >>= function
           | true ->
               E.return true
@@ -940,20 +1046,121 @@
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
         end
+    | AilEcast _ ty e ->
+        (* STD §6.6#9: a pointer cast of an address constant, or an integer constant cast to
+           pointer type. The target type of a cast of an address constant is not examined
+           (upstream's reading: `(long)ga` passes as before, a §6.6#10 form gcc accepts too).
+           The address test comes first: is_integer_constant_expression raises UB055 on a cast
+           operand that is not arithmetic (§6.6#6's "shall" is not a constraint). *)
+        is_address_constant e >>= function
+          | true ->
+              E.return true
+          | false ->
+              if AilTypesAux.is_pointer ty then
+                is_integer_constant_expression false(*not Constraint *) e
+              else
+                E.return false
+        end
+    | AilEbinary e1 (Arithmetic Add) e2 ->
+        (* STD §6.6#7, fourth bullet, with §6.6#9: an address constant for an object type plus an
+           integer constant expression, in either operand order (§6.5.6#2); the pointer operand is
+           found first so that the integer test only runs on the other one *)
+        is_address_constant e1 >>= function
+          | true ->
+              is_integer_constant_expression false(*not Constraint *) e2
+          | false ->
+              is_address_constant e2 >>= function
+                | true ->
+                    is_integer_constant_expression false(*not Constraint *) e1
+                | false ->
+                    E.return false
+              end
+        end
+    | AilEbinary e1 (Arithmetic Sub) e2 ->
+        (* STD §6.6#7, fourth bullet: minus an integer constant expression (§6.5.6#3: the pointer
+           is the left operand) *)
+        is_address_constant e1 >>= function
+          | true ->
+              is_integer_constant_expression false(*not Constraint *) e2
+          | false ->
+              E.return false
+        end
+    | AilEcond e1 e2_opt e3 ->
+        (* STD §6.6#7 ("shall be, or evaluate to"): a conditional over address constants evaluates
+           to one of them (`1 ? &a : &b`); the condition is an arithmetic constant expression and
+           every branch an address constant (an unevaluated branch that is not is rejected: too
+           strict, never fail-open). The GNU form `e1 ?: e3` keeps upstream's rejection (see the
+           arithmetic predicate's arm). *)
+        (match e2_opt with
+          | Just e2 ->
+              is_arithmetic_constant_expression false e1 >>= fun b1 ->
+              is_address_constant e2 >>= fun b2 ->
+              is_address_constant e3 >>= fun b3 ->
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
+            is_address_constant (expression_of_generic_association ga)
+        ) true gas
+    | AilEmemberof _ _ ->
+        is_decayed_static_lvalue a_expr
+    | AilEmemberofptr _ _ ->
+        is_decayed_static_lvalue a_expr
+    | AilEunary Indirection _ ->
+        is_decayed_static_lvalue a_expr
     | _ ->
         E.return false
   end
 
 
+(* STD §6.6#9, "implicitly by the use of an expression of array or function type", with
+   §6.3.2.1#3-#4: an lvalue built with [], ., -> and * from a static object (or from an address
+   constant under the indirection operator) is itself an address constant when its type is an array or a function type
+   (`gs.arr`, `gsa[1].arr`, `g2[1]`, `*(g2 + 1)`, `*f`): it decays without accessing any object.
+   Any other such lvalue (`gs.b`, `gq.p`, `*&g`) would be read. The type is the one the sizeof
+   desugaring reads: the expression annotated in GenTyping.CTXsizeof, where neither the lvalue
+   conversion nor the decay is performed (genTyping.lem, the CTXsizeof guards of both). A typing
+   error is the program's own and is reported as such (the Ail typing would raise it next). *)
+and is_decayed_static_lvalue (AnnotatedExpression () _ _ _ as a_expr) =
+  is_lvalue_to_static_object a_expr >>= function
+    | false ->
+        E.return false
+    | true ->
+        E.get_sigma_sofar >>= fun sigm ->
+        E.get_gamma_sofar >>= fun gamm ->
+        match ErrorMonad.runErrorMonad (Mini_pipeline.annotate_expression_seeded (Map.fromList sigm.enum_definitions) E.desugar_time_tagDefs Nothing sigm gamm GenTyping.CTXsizeof a_expr) with
+          | Left (loc, err) ->
+              E.fail_ailtyping loc err
+          | Right an_expr ->
+              let (_, ty) = Mini_pipeline.qualified_ctype_of_seeded (Map.fromList sigm.enum_definitions) E.desugar_time_tagDefs an_expr in
+              E.return (AilTypesAux.is_array ty || AilTypesAux.is_function ty)
+        end
+  end
+
+
 
 
 (* As defined in STD §6.6#7, in the context of initializers, "constant expressions" 
@@ -963,7 +1170,13 @@
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

Measured in the fork (both engines by generation, 446 programs over gcc 13.3.0, pristine and both
engines; `lean_frontend/docs/2026-11-07_address-constants-record.md` §3): before, 77 conforming programs
rejected, 3 constraint violations accepted, 84 crashes (the `_Generic`/compound-literal wildcard, the
`&local` typing crash, and a preamble shape of the probe generator's own); after, 0 accepted against
the standard, 0 engine disagreements, 12 declared over-strict rejections, the 4 GNU-`?:` crashes of a
separate report. No gated corpus row moved except the comma case (the record §4).

## Related findings (not this mechanism)

- `enum { E = 3 ?: 4 }`, `case (3 ?: 4):`, `int b[(3 ?: 4)]`, `_Static_assert((3 ?: 4) == 3, "")`: the
  GNU conditional in an integer-constant context dies with `PEcase, mismatched` / `the driver found
  less/more …` (an `E.record_error_at` the mini-run discards; the fork's TODO item), unchanged here.
- A braced initializer of an array of structs whose members include an array (`static struct S gsa[2] =
  {{0, 0, {0, 0, 0}, {0}}, …}`) yields `Translation called on Ail program with an invalid node` (report
  08's nested-initializer class); the fix's witnesses fill such an array in `main` instead.

## Classification

**TRUE BUG** (over-strict rejections of conforming programs with the checker's own 6.7.9#4 diagnostic;
two fail-open acceptances of constraint violations; crashes on conforming `_Generic` uses). The fork fixes
it as a fork-ahead delta; the patch is offered as is.

## Provenance

Reports 09 (2026-08-21, arc-12 S3), 28 and 29 (2026-09-03, the semantic-discrepancy probe campaign,
findings E3/E5) were found over the fork's Lean port and verified un-forked at `b9aeedcb4`; the
true-bug audit of 2026-11-04 (base `c3ff8c53f`) added the sibling forms (its §4 items 7, 16, 17) and
localised the mechanism; the fix, the §6.6 probe table and this merged report are the
`fix/address-constants` slice of 2026-11-07 by Claude (Fable 5.1) under operator direction; the filed
issue carries an AI-provenance note per the tray's policy.
