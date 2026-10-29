# Consumer note for cerberus-caesium: the compound-assignment refusal (2026-10-29)

From: the `fix/compound-assignment-refusal` worker [AGENT]. Occasion: the upstream-uncertainty
survey of 2026-10-20 (`docs/2026-10-20_upstream-uncertainty-survey-record.md`, cluster B;
upstream-tray draft 61) found that upstream Cerberus elaborates `E1 op= E2` as `E1 = E1 op E2`
with `E1` elaborated twice, under its own `TODO: this elaboration is wrong because it duplicates
any side-effect in E1` (`frontend/model/translation.lem`, pristine b9aeedcb4 :2506). With an
increment, a call or a comma inside the lvalue the second copy is a second side effect: `a[g()]
+= 4` calls `g` twice (24 where gcc gives 14) and `a[i++] += 5` is reported as
`UB035_unsequenced_race` (false: C17 6.5.16#3 sequences the update after both value
computations, 6.5.16.2#3 evaluates the lvalue once). [USER 2026-10-20] ruled that such a
compound assignment is refused in the shared Lem and the one-binding elaboration proposed
upstream, under the standing rule that where upstream left a case under its own TODO the fork
leaves it as-is or REFUSES LOUDLY and never answers silently wrong; [USER 2026-10-29] dispatched
the slice. Contract entry D13; witnesses `scripts/check_compound_assignment_refusal.sh` (ladder
row 1); record `docs/2026-10-29_compound-assignment-refusal-record.md`.

Status: on branch `fix/compound-assignment-refusal`, implemented and witnessed on both engines,
focused gates green; Tier A and the full battery per the record; the merge is the orchestrator's.
The behaviour below is what the next re-pin that includes the branch carries.

## What now refuses

A compound assignment (`+= -= *= /= %= &= |= ^= <<= >>=`, and the prefix `++`/`--`, which the
desugarer turns into `+= 1`/`-= 1`) whose LEFT operand contains, anywhere inside it — in a
subscript, a member access, a dereference, a cast, a conditional, a `_Generic` — any of: a
postfix increment/decrement, an assignment, a compound assignment (so a prefix `++`/`--`), a
comma, a function call (pure or not), an assert, a `va_arg`/`va_start`/`va_copy`/`va_end`, a GNU
statement expression, a compound literal:

```c
a[i++] += 5;          /* refuses (a false UB035 before) */
*p++ += 7;            /* refuses */
*g() += 3;            /* refuses (g ran twice before; the call need not have a side effect) */
a[g()] += 4;          /* refuses (24 before, gcc 14) */
a[--i] += 6;          /* refuses */
(p++)->v += 5;        /* refuses */
s.a[(n++, 0)] /= 2;   /* refuses (a comma) */
a[++i] -= 5;          /* refuses (a prefix increment is a compound assignment) */
*(int*)(p = q) &= 3;  /* refuses (an assignment in a cast's operand) */
((int[2]){7, 1})[0] %= 4;  /* refuses (a compound literal lvalue) */
*va_arg(ap, int*) += 1;    /* refuses */
while ((*--ptr += 1) > '9') *ptr = '0';   /* refuses: gcc-torture 990222-1.c, a false UB035 before */
```

The refusal fires at elaboration (after desugaring and typing, before Core typing and
execution), at the compound assignment's own location (the cursor on the operator), on every
path including the constant-expression mini-run (a `case (a[i++] += 1):` label refuses with the
same text; it used to die with an unrelated driver error).

Now the SHARED elaborator's arm is a Lem `error`, so the text is one string by generation
(`Cerb_debug.error` in the oracle, `failwithI` in Lean); the location prefix is the translation
layer's own rendering (`<file>:<line>:<col>:: `, as the GNU `?:` arm prints it):

```text
w.c:1:53:: Translation.translate_expression: refused - compound assignment whose left operand contains a side effect (an increment or decrement, an assignment, a function call, a comma, a va_arg, a statement expression or a compound literal anywhere inside the lvalue; C17 6.5.16#3 sequences the update after both value computations and 6.5.16.2#3 evaluates the lvalue E1 only once); upstream elaborates E1 op= E2 as E1 = E1 op E2 with E1 elaborated twice, under its own 'TODO: this elaboration is wrong because it duplicates any side-effect in E1' (translation.lem b9aeedcb4 :2506), so the lvalue's side effect runs twice (a call in the lvalue is called twice, a wrong value) or a false UB035_unsequenced_race is reported (the ++/--/comma forms) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)
```

On the wire — the same shape as D11 and D12:

- the oracle prints `internal error: <text>` on stderr and dies on the uncaught exception
  `Failure("internal error: <text>")` with an OCaml backtrace, **exit 125**; in `--batch` no
  verdict line is printed;
- the Lean engine aborts under `LEAN_ABORT_ON_PANIC=1` with
  `PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: <text>` on stderr, **exit 134**
  (`--batch` prints nothing else; without the abort flag the driver refuses to start, exit 2);
- `--cabs-json` succeeds: the refusal is in the elaborator, after Cabs, desugaring and typing,
  so a consumer that imports Cabs JSON and runs the Lean pipeline sees the panic at `translate`,
  before Core typing and execution.

**Stop class under the outcome protocol** (`docs/2026-10-20_consumer-note-cerberus-caesium-outcome-protocol.md`):
a LEGACY stop, origin unattributed — NOT a frontend-refusal `Error` record and NOT a migrated
`CerbStop` `REFUSAL`. The validated panic frame decodes as legacy/unattributed, exactly as the
D11 and D12 stops do; the migration map (`docs/2026-10-20_outcome-protocol-register-migration.tsv`)
lists the site as UNMIGRATED under the same shared-model mapping mover (structural-outcome WP2).
Why `error` and not the arm's neighbour `E.record_error_at` (the GNU `?:` precedent, which
prints `unsupported: <loc>:: <text>` and then raises): measured, a recorded error is DISCARDED by
the constant-expression mini-run (`mini_pipeline.lem:157` runs the elaboration with plain
`runStateM`), so a `?:` in an enum, a `case` label, a `_Static_assert` or an array size dies
with an unrelated text on both engines, and a `case (a[i++] += 1):` label reaches that run
point; `error` stops on every path with the attributed text [AGENT 2026-10-29, orchestrator
ruling]. Why not `E.fail loc (Desugar_NotYetSupported …)`: as for D12, the port's batch record
carries no reason text (TODO.md's batch-rendering option).

Lean site: the generated `Translation.translate_expression` (the `AilEcompoundAssign` arm),
`Translation.compound_assign_lhs_has_side_effect` (the walker; a fuel'd worker in the same
declared form as `translate_expression`, `failwithI CerbFuel.fuelExhaustedMsg` at fuel zero) and
`Translation.compound_assign_refusal` (the text) in `lean_frontend/generated/Translation.lean`;
oracle site: the generated `ocaml_frontend/generated/translation.ml`, both from the one `.lem`.
No hand-written seam changed; no proof module changed.

## What does not change

Agreeing with the oracle, witnessed as controls: a side effect in the RIGHT operand only (`x +=
g()`, evaluated once as before), plain `=` with a post-incremented subscript (`a[i++] = 5`), `++`
on the lvalue itself (`a[i++]++`), a plain subscript, `*p += 1`, `s.v |= 4`, `a[f] <<= 2` with
`f` a variable, a VOLATILE object as the lvalue (`volatile int v; v += 2`: the Core loads `v`
once, in the rvalue copy, and stores once), and a volatile read inside the address computation
(`volatile int i; a[i] += 2`): NOT counted — Cerberus gives `volatile` no semantics beyond the
qualifier, the duplicated read is value-identical and verdict-neutral; this is a declared
under-approximation against C17 5.1.2.3#2, stated in CONTRACT D13 and SUPPORTED, and the strict
reading would have refused every csmith program (1669/1669 use `volatile`). Over-approximations,
also declared: every call counts (the second copy calls it again, so `*g() += 3` refuses even
when `g` is pure), and a `_Generic`'s controlling expression and every association, selected or not, are walked though C evaluates only the selected one (`a[_Generic(i++, int: 0)] += 1` and `a[_Generic(0, long: i++, default: 1)] += 3` both refuse); a `sizeof` operand does not survive typing
(`a[sizeof(i++)] += 1` answers as before). The bit-field case (`s[i++].bf += 2`) stays the
pre-existing `feature not yet supported: bit-fields` rejection, exit 1 on both engines.

## Kernel reach; measurement (what moved)

- **Kernel-reach warning, which is the point:** `*p++ |= x`, `buf[len++] += v`, `tbl[hash(k)] +=
  1`, `(*--ptr += 1)` are everyday C; every one now refuses on both engines at elaboration. A
  consumer whose C uses the idiom gets the stop above at the operator, not a doubled call or a
  false `UB035_unsequenced_race`. Hoisting the lvalue (`int *q = &a[i++]; *q += 5;`) is the only
  way through until upstream adopts the one-binding elaboration (tray 61's "Expected"); the fork
  does not implement it.
- Every corpus the lanes walk was run on the new oracle through elaboration (`--pp=core`; 5591
  files under `tests/`, `lean_frontend/corpus` and the CN corpus, 1669 csmith programs through the
  lane's materialization, the libxml2 and pKVM TUs with their lanes' arguments; the libc restaged
  by `dune build cerberus.install`): exactly one program outside the survey's own probe directory
  refuses — the ci-sweep scoreboard row `tests/gcc-torture/breakdown/success/990222-1.c`
  (`torture_success.tsv:509`, `UB_MATCH UB:UB035_unsequenced_race`: a false UB both engines
  agreed on), which moves to the refusal class at the scoreboard's next deliberate re-record. No
  baselined row moves; csmith 0; the libc, CN, libxml2 and pKVM sources 0.
