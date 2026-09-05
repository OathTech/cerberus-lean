# Four more `--pp core` ↔ Core-parser mismatches: the parser drops `seq_rmw`'s second operand; the printer spells `Cfvfromint`/`Civfromfloat`, `wrapI_div`/`wrapI_rem_t`, `pcall(f, )`, `builtin f (…)` and `PtrMemberShift[s, m]` in forms the grammar rejects

**Affected:** `parsers/core/core_parser.mly:767-774` (symbolification of
`SeqRMW`: `Eff.return (SeqRMW (b, pe1, pe3, sym, pe3))` — the parsed
`pe2` is discarded and `pe3` duplicated); `ocaml_frontend/pprinters/pp_core.ml:367-370`
(`Cfvfromint`/`Civfromfloat`) vs `parsers/core/core_lexer.mll:83-84`
(keywords `Fvfromint`/`Ivfromfloat`); `pp_core.ml:411-419`
(`wrapI_div`/`wrapI_rem_t` spellings) vs `core_lexer.mll:119-128` (only
`wrapI_{add,sub,mul,shl,shr}` are keywords); `pp_core.ml:636` (`pcall(nm,
<args>)` prints `pcall(f, )` for a zero-argument call) vs
`core_parser.mly:1656-1659` (`pcall(f)` or `pcall(f, e, …)`);
`pp_core.ml:786-788` (`builtin sym (bTys)`) vs `core_parser.mly:1812`
(`BUILTIN SYM (bTys) COLON EFF bTy` required); `pp_mem.ml:70-71`
(`PtrMemberShift[tag, member]`) vs `core_parser.mly:1635` (`PTRMEMBERSHIFT
[SYM, DOT cabs_id]`). Checked against `master` @ `b9aeedcb4`: all four
files byte-identical.

Same conditionality as reports 02 and 03: these matter if `--pp core`
output is meant to be re-readable by the Core parser (our pinned libc
dump is produced exactly that way). Item 1 is a parser defect
independent of that intent.

## 1. The Core parser drops `seq_rmw`'s second operand (parser bug)

`core_parser.mly:1727-1730` parses `seq_rmw(pe1, pe2, sym => pe3)` into
`SeqRMW (false, _pe1, _pe2, _sym, _pe3)`; the symbolification pass then
builds

```
 | SeqRMW (b, _pe1, _pe2, _sym, _pe3) ->
     symbolify_pexpr _pe1 >>= fun pe1 ->
     symbolify_pexpr _pe2 >>= fun pe2 ->
     under_scope (
       register_sym _sym    >>= fun sym ->
       symbolify_pexpr _pe3 >>= fun pe3 ->
       Eff.return (SeqRMW (b, pe1, pe3, sym, pe3))
     )
```

(`:767-774`, verbatim) — `pe2` is computed and thrown away; `pe3` takes
its place. In the printer's argument order (`pp_core.ml:705-712`:
`seq_rmw(ty, ptr, sym => e)`) the field lost is the POINTER operand.

Witness, hand-written (`seq_rmw('signed int', p, x => Specified(7))`),
re-printed by the upstream binary's own `--pp=core` after parsing,
verbatim 2026-09-05:

```
    seq_rmw('signed int', Specified(7), x => Specified(7)) in
```

Witness from C — postfix increment elaborates to `seq_rmw` (`translation.lem`
`Caux.seq_rmw` in the postfix-operator arm; the oracle's own libc dump
contains 199 of them):

```c
int main(void) { int x = 1; x++; return x; }
```

```
$ cerberus --nolibc --pp=core x.c > x.core          # dump contains, verbatim:
      seq_rmw('signed int', a_508, a_509 => case a_509 of
$ cerberus --nolibc --pp=core x.core | grep seq_rmw   # re-read and re-print:
      seq_rmw('signed int', case a_509 of
$ cerberus --nolibc --exec --batch x.core
Error {msg: "unresolved symbol: a_509 at x.core:7:7-15:11"}
$ cerberus --nolibc --exec --batch x.c
Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```

(all verbatim, 2026-09-05, un-forked upstream binary + runtime @
`b9aeedcb4`; the pointer `a_508` is replaced by the `case` expression,
whose bound variable then has no binder.) Remedy: `Eff.return (SeqRMW (b,
pe1, pe2, sym, pe3))`.

## 2. `Cfvfromint` / `Civfromfloat` (printer) vs `Fvfromint` / `Ivfromfloat` (lexer)

`pp_core.ml:367-370` prints the constructors as `Cfvfromint`/`Civfromfloat`;
the lexer's keyword table (`core_lexer.mll:83-84`) knows only
`Fvfromint`/`Ivfromfloat` (the spellings `std.core` itself uses, e.g.
`:73` `Fvfromint(n)`, `:82` `Ivfromfloat(ty, f)`). The printer's spelling
lexes as an ordinary symbol:

```
$ cerberus --nolibc --exec --batch w.core      # pure(Specified(Civfromfloat('signed int', Cfvfromint(3))))
w.core:2:18: error: unresolved symbol 'Civfromfloat'
  pure(Specified(Civfromfloat('signed int', Cfvfromint(3))))
                 ^~~~~~~~~~~~ 
$ cerberus --nolibc --exec --batch w_ok.core   # same with Ivfromfloat / Fvfromint
Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, upstream binary.) The form is reachable: the
oracle's own `--pp=core` dump of its libc (`--sequentialise --rewrite`
over the 12 libc TUs, our pinned `tests/libc/libc.core`) contains 29
occurrences, e.g. `Specified(Cfvfromint(a_32626) * a_32627)`. Remedy:
print the lexer's spellings (or add the `C`-prefixed ones as keyword
aliases).

## 3. `wrapI_div` / `wrapI_rem_t` (printer) vs the lexer's five `wrapI_` keywords

`pp_core.ml:411-419` can spell `wrapI_div`/`wrapI_rem_t` (and the
`catch_exceptional_condition_` twins) for `IOpDiv`/`IOpRem_t`;
`core_lexer.mll:119-128` recognises only `_add _sub _mul _shl _shr`, so
the two spellings lex as symbols:

```
$ cerberus --nolibc --exec --batch d.core      # pure(Specified(wrapI_div('unsigned int', 7, 2)))
d.core:2:18: error: unresolved symbol 'wrapI_div'
  pure(Specified(wrapI_div('unsigned int', 7, 2)))
                 ^~~~~~~~~ 
$ cerberus --nolibc --exec --batch a.core      # same with wrapI_add
Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05.) `IOpDiv`/`IOpRem_t` are constructed by the
elaboration (`translation.lem`, `translate_div_mod_operator`) so the
printer arm is live in principle; we did not find a C program whose dump
contains the two spellings (unsigned `/` and `%` print as explicit
`is_representable_integer` cases in the dumps we made). Remedy: add the
two keywords to the lexer (`T.(WRAPI Core.IOpDiv)`, `T.(WRAPI
Core.IOpRem_t)` and the `CATCH_EXCEPTIONAL_CONDITION` twins).

## 4. Three declaration/expression forms the printer emits and the grammar rejects

- `pcall(f, )` — `pp_core.ml:636` prints `pcall(nm, ` followed by the
  comma-separated arguments, so a zero-argument procedure call prints a
  trailing `, )`; the grammar (`core_parser.mly:1656-1659`) has `pcall(f)`
  and `pcall(f, e, …)` only:

  ```
  w_pcall.core:5:43: error: unexpected token ')'
    let strong r: loaded integer = pcall(f, ) in
                                            ^ 
  ```

  (verbatim, 2026-09-05; the same file with `pcall(f)` runs:
  `Defined {value: "Specified(3)", …}`.)

- `builtin f (bTys)` — `pp_core.ml:786-788` prints a `BuiltinDecl`
  without its return type; `core_parser.mly:1812` requires `: eff bTy`,
  so the declaration is unparseable and the error surfaces at the next
  token (`unexpected token 'proc'` on the following declaration, verbatim
  2026-09-05). While checking the grammar form we also hit an internal
  assertion: `builtin g (integer) : eff integer` in a user file →
  `internal error in the Core parser: [uncaught exception] 'File
  "parsers/core/core_parser.mly", line 961, characters 16-22: Assertion
  failed'` (the `lookup_sym` of a `Builtin_decl` returning `None`,
  `:956-962`) — reported here as an observation.

- `PtrMemberShift[tag, member]` — `pp_mem.ml:70-71` prints the member
  identifier bare; `core_parser.mly:1635` requires the dot form
  `PtrMemberShift[tag, .member]`. (Printer/grammar text only; we did not
  construct an executable witness — in the C-derived dumps we made,
  member access appears as the pure `member_shift(p, S, .b)` form, not as
  this memop.)

Also observed while preparing these witnesses (each already in the
round-trip class of reports 02/03, listed so the maintainers see the
full set from one C-derived dump): a floating literal `Specified(2.5)`
(`pp_core.ml` prints `string_of_float`; the grammar has no floating
literal, `unexpected token '.'`), and the C-type spelling `'void (*)
(void)'` inside `ccall` (`unexpected token '*'`).

## Impact

Re-reading a `--pp core` dump silently changes its meaning (item 1) or
fails to parse (items 2-4). Anyone using the text form as an interchange
format — as our project does for the libc — must patch the reader; item 1
corrupts every `x++`/`x--`/compound-assignment site on re-read.

## Classification

Item 1: **TRUE BUG** (parser; independent of round-trip intent). Items
2-4: **TRUE BUG conditional on round-trip intent**, as for reports 02/03
— each is a one-line spelling or production fix.

## Provenance

Found by the 2026-09-03 line-by-line audit of our Lean port's Core text
parser against `core_parser.mly`/`core_lexer.mll`/`pp_core.ml` (record
`lean_frontend/docs/2026-09-03_zero-discrepancy-Z2-audit.md` §2.14, rows
CP-09/CP-10/CP-15/CP-21; our reader accepts both spellings where the dump
is the only input and mirrors the grammar otherwise). All witnesses above
were produced 2026-09-05 on the un-forked upstream binary + runtime @
`b9aeedcb4` (verbatim). Localisation and this draft by Claude (Fable 5.1)
under operator direction; the filed issue carries an AI-provenance note
per the tray's policy.
