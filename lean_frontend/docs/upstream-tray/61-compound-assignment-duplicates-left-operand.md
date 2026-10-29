# Compound assignment is elaborated with the left operand duplicated: a side effect in the lvalue runs twice, and `a[i++] += v` is reported as UB035

**Affected:** `frontend/model/translation.lem:2505-2531` (`| A.AilEcompoundAssign e1 aop e2 ->`, under the
comment `(* TODO: this elaboration is wrong because it duplicates any side-effect in E1 *)` at :2506: the arm rewrites the
expression to `AilEassign e1 (AilEbinary (AilErvalue e1) aop e2)`, so `e1` is elaborated twice, once as the
lvalue and once as the rvalue). Checked at the fork's merge-base `b9aeedcb4` (the pristine binary answers the
same); the Lean port is generated from the same `.lem`.

## Description

C17 §6.5.16#3 sequences the update of the left operand after the value computations of both operands, and
§6.5.16.2#3 says the lvalue `E1` is evaluated only once. With an increment, a call or a comma inside the lvalue
the second elaborated copy is a second side effect. Measured 2026-10-20 on the fork @ `3ac3ff336`
(`scripts/test_exec.sh`, both engines agree; gcc 13 gives the standard's answer):

```c
static int n; static int g(void){ n++; return 0; }
int main(void){ int a[2] = {0, 0}; a[g()] += 4; return n*10 + a[0]; }   /* gcc 14: g runs once */
```
```text
[1/1] MATCH cb-02-lhs-call-index: VAL:{value: "Specified(24)", stdout: "", stderr: "", blocked: "false"}
```
(every one of the five exhaustive executions answers 24: `g` ran twice.)

```c
int main(void){ int a[4]={0,0,0,0}; int i=0; a[i++] += 5; return i*10 + a[0]; }   /* gcc 15; defined: i modified once */
```
```text
[1/1] UB_MATCH ca-02-idx-postinc: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:46--1:57>"}
```

The same false `UB035_unsequenced_race` for `*p++ += 7`, `u[i++] <<= 2`, `s[i++].v |= 4`, `a[--i] += 6`,
`(p++)->v += 5` and a comma in the subscript; a side effect in the RIGHT operand is evaluated once (`x += g()`),
and plain `=` is unaffected. Witnesses: `tests/parity-probes/uncertainty/B-compound-assignment/` in the fork.

## Expected

Bind the lvalue once and use it twice: elaborate `E1 op= E2` as (in Ail terms) `let p = &E1 in *p = *p op E2`,
the way `AilEassign` and `AilErvalue` already elaborate the pointer and the load separately. The TODO at
`translation.lem:2506` records the intent.

## Origin

Found by the fork's upstream-uncertainty survey (2026-10-20, `lean_frontend/docs/2026-10-20_upstream-uncertainty-survey-record.md`,
cluster B). Classification: TRUE BUG (a wrong value when the lvalue contains a call; a wrong UB verdict for the
`++`/`--`/comma forms, which are everyday C: `*p++ |= x`, `buf[len++] += v`). Fork plan ([USER 2026-10-20]):
refuse a compound assignment whose left operand has a side effect (a syntactic predicate on the Ail, both engines
through the shared `.lem`); the one-binding elaboration is this report's proposal to upstream, to be adopted on
re-pin. The report above describes upstream as it stands.

## Fork-ahead refusal (2026-10-29)

REFUSED in the fork since 2026-10-29 (contract D13, record
`lean_frontend/docs/2026-10-29_compound-assignment-refusal-record.md`; witnesses
`scripts/check_compound_assignment_refusal.sh`): a syntactic walk over the left operand in the shared
`translation.lem` arm (a postfix `++`/`--`, an assignment, a compound assignment — the prefix forms —, a comma, a
call, an assert, a `va_*` builtin, a statement expression or a compound literal anywhere inside it) and a Lem
`error` whose text carries the location. Not a fix for upstream: the report above stands and asks for the
one-binding elaboration. Of the corpora the fork's lanes walk, one gcc-torture program meets the refusal,
`gcc.c-torture/execute/990222-1.c` (`while ((*--ptr += 1) > '9') *ptr = '0';`), which upstream reports as
`UB035_unsequenced_race` — a second, real-code witness for the "Description" above.

## Related finding, not fixed in the fork: the GNU `?:` arm's `record_error_at` is discarded by the mini-run

`translation.lem` :2318-2321 (the `AilEcond e1 Nothing e3` arm) refuses the GNU `?:` operator through
`E.record_error_at loc "TODO: elaboration of ?: operator"` and returns a `skip` placeholder; the recorded error is
raised by `runStateM_errors` at the end of `translate`. The constant-expression mini-run
(`mini_pipeline.lem:157`, `evalIntegerConstantExpression`) runs the elaboration with plain `runStateM`, so there the
error is discarded and the placeholder executed. Measured at `b9aeedcb4`'s behaviour on the fork (2026-10-29, both
engines): `enum { E = 3 ?: 4 }`, `case (3 ?: 4):` and `int b[(3 ?: 4)]` die with `internal error: PEcase,
mismatched ==> […]Unit`, `_Static_assert((3 ?: 4) == 3, "")` with `TODO error: the driver found less/more than one
active execution` — unattributed crashes after the `unsupported:` line, not the declared refusal. The fork's
compound-assignment refusal uses a pure `error` for this reason; the `?:` arm is left as upstream has it.
