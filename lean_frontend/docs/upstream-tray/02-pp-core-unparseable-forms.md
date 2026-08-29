# `--pp core` emits forms its own Core parser rejects or mis-values

**Affected:** `ocaml_frontend/pprinters/pp_core.ml:783-785`,
`parsers/core/core_parser.mly` (no matching production; cf. :1803-1809),
`memory/concrete/impl_mem.ml:567-568` vs `core_parser.mly:1540-1541`
(checked against `master` @ `b9aeedcb4`; files unchanged there).

Two independent print/parse asymmetries, reported together because both
break round-tripping `--pp core` output through the Core parser.

## 1. Bodyless `proc` declarations are unparseable

`pp_core.ml:783-785` prints a `ProcDecl` (declared-but-undefined
procedure) as:

```
proc f (bTy1, ..., bTyN)
```

i.e. parameter base types only — no parameter names, no `: eff bTy`
return type, no body. `core_parser.mly` has no production for this form:
`proc_declaration` (:1803-1809) requires named parameters and a body
(`proc f (x: bTy, ...) : eff bTy := e`). Note also that the printer drops
the declaration's return base type entirely, so the form is not even
reconstructible in principle from the text.

**Reproducer:** pretty-print any Core program containing a procedure
declaration without a definition (e.g. `--pp core --pp_core_out=out.core`
on a translation unit that declares but does not define a function that
is nevertheless referenced), then feed `out.core` back to the Core
parser. The parse fails at the `proc` line.

## 2. `Cfunction(...)` pointer values parse to null pointers

`pp_pointer_value` (`impl_mem.ml:567-568`) prints function-pointer values
as `Cfunction(name)`. The grammar accepts the token (`CFUNCTION_VALUE`,
`core_parser.mly:1540-1541`) but discards the name and builds a null
pointer:

```
| CFUNCTION_VALUE _nm= delimited(LPAREN, name, RPAREN)
  { (*TODO*) Vobject (OVpointer (Impl_mem.null_ptrval Ctype.void)) }
```

**Observed vs expected:** re-parsing a dump silently turns every printed
function-pointer value into `NULL`; expected is the function pointer for
the named symbol.

## Impact

`--pp core` output is not a faithful serialisation: dumps containing
either form cannot be reloaded (case 1) or reload to a semantically
different program (case 2 — worse, because it is silent). In our
downstream use, a differential harness that re-parses `--pp core` output
carried a long-standing unexplained failure that turned out to be exactly
the bodyless-`proc` form; the `Cfunction` punt bites any dump of code
that stores or passes function pointers (e.g. the shipped C library,
where internal calls go through `Specified(Cfunction(f))` values).

## Proposed remedy

1. Print the declaration in a form the grammar can accept and extend the
   grammar to match, e.g. print `proc f (bTy1, ..., bTyN) : eff bTy` and
   add a production alongside `proc_declaration`:

   ```
   proc_forward_declaration:
   | PROC _sym= SYM bTys= delimited(LPAREN, separated_list(COMMA, core_base_type), RPAREN)
     COLON EFF bTy= core_base_type
       { Proc_fwd_decl (_sym, (bTy, bTys)) }
   ```

   mapping to `ProcDecl` in the resulting `fun_map`. (Our port's text
   parser implements the currently printed form — types-only parameter
   list — and it is sufficient to reload the shipped C library's dump;
   adding the return type as above removes the information loss too.)

2. Build the real function pointer instead of the null punt; the memory
   interface already exposes what is needed (`Impl_mem.fun_ptrval`,
   `impl_mem.ml:1802`):

   ```
   | CFUNCTION_VALUE _nm= delimited(LPAREN, name, RPAREN)
     { Vobject (OVpointer (Impl_mem.fun_ptrval <resolved sym>)) }
   ```

   resolving `name` through the parser's symbol registration as for other
   name uses.

## Classification

**TRUE BUG**, conditional on intent: the Core parser exists to consume
`.core` text and `--pp core` output is otherwise accepted, so we read
round-tripping as an intended property; on that reading both asymmetries
are defects (the `Cfunction` one is author-acknowledged — the `(*TODO*)`
— but its failure mode is silent value corruption rather than a rejected
parse). If round-tripping is explicitly not a goal, this reduces to a
documentation issue; we could not determine that intent from the code.

<!-- internal provenance:
  worktrees/cerberus-lean-arc/libc-load/lean_frontend/docs/
  2026-08-19_arc6-s1-libc-load.md ("CoreParser extensions", items 1 and 6;
  "Baseline improvement": the long-standing test_core.sh 078-float-special
  red was exactly the bodyless ProcDecl form, green once implemented);
  arc-6 decision log D10 (test_core parse-success-only blind spot).
  Our parser records the unprintable ProcDecl return type as BTy_unit
  (unread: call_proc rejects non-Proc entries, core_run.lem:46-51).
-->
