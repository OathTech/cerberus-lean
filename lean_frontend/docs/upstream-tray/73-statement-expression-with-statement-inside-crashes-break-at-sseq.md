# A GNU statement expression whose block contains an assignment, `++` or `if` statement dies with `internal error: break_at_sseq, Cbound`

**Affected:** `frontend/model/core_reduction.lem` @ `c3ff8c53f`, `break_at_sseq` (`:804-…`), the arm `:837-838`
`| Cbound annots ctx' -> error "break_at_sseq, Cbound"`. The shared model: the OCaml backend and our Lean port stop
with the same text.

## Description

Statement expressions (`({ … })`) are a GNU extension, not ISO C; the front end accepts them and elaborates them.
A statement expression whose block is only declarations initialised from expressions and a final expression runs. One
whose block contains an expression statement with a side effect on a local (an assignment, `n++`) or an `if`
statement stops the execution with an uncaught `Failure` raised in `break_at_sseq`, the function that splits an
evaluation context at its innermost strong sequencing: its arm for a `Cbound` context is an `error`.

## Reproducers

```c
int main(void){ int n = 0; int x = ({ n = n + 1; n + 10; }); return x*10 + n; }
```

```
$ cerberus --nolibc --exec --batch sx-01-assign-stmt.c
internal error: break_at_sseq, Cbound
cerberus: internal error, uncaught exception:
          Failure("internal error: break_at_sseq, Cbound")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Core_reduction.break_at_sseq in file "ocaml_frontend/generated/core_reduction.ml", line 872, characters 15-33
```

(exit 125; verbatim, 2026-11-10, un-forked upstream binary + runtime @ `c3ff8c53f`.) The same first line and exit code
for each of:

```c
int main(void){ int n = 0; int x = ({ n++; n + 10; }); return x*10 + n; }
int main(void){ int n = 1; int x = ({ if (n) n = 2; n; }); return x*10 + n; }
int main(void){ int n = 0; int x = ({ n++; 5; }); return x*10 + n; }
int main(void){ int n = 0; int x = ({ int y = 1; n++; y + n; }); return x*10 + n; }
int main(void){ int n = 0; ({ n++; n++; }); return n; }
```

gcc 13.3.0 (`gcc -std=c11 -w -O0 f.c && ./a.out; echo $?`, 2026-11-10) exits 111, 111, 22, 51, 21 and 2 for the six
programs in the order shown. Controls that run on pristine today and agree with gcc (`se-01-basic` 6, `se-03-void` 7,
`se-04-min-macro` 2, `sx-02-call-stmt` 51, `sx-03-decl-from-call` 11, `sx-08-in-loop` 6): blocks made of declarations,
calls and a final expression. The twelve programs are `tests/parity-probes/uncertainty/P-statement-expressions/` in
this repository.

## Observed vs expected

- Observed: an internal error (exit 125) on a program gcc and clang accept and that the front end has already
  desugared, typed and elaborated.
- Expected: the value (gcc's), or a "not supported" diagnostic for the construct.

## Impact

Statement expressions with statements inside are the body of most `MIN`/`MAX`/`container_of`-style macros in Linux and
similar code bases; the failure is a crash late in execution, with a message that names no source construct.

## Proposed remedy (prose; no patch is attached)

Either give `break_at_sseq` a `Cbound` arm that recurses as the other context arms do (that arm is in the file,
commented out, at `:839-846`, directly under the `error`), or reject the statement forms it cannot run at desugaring with a
located "not supported" diagnostic.

## Fork status (2026-11-10)

Unchanged in both engines (the Lean port stops with the same text, exit 134). Reported, not refused in code.

## Classification

**TRUE BUG** as a crash (an internal error where a value or a diagnostic belongs). The construct is an extension, so
which of the two belongs is upstream's call.

## Provenance

Found by the fork's upstream-uncertainty survey (2026-10-20, cluster P; failure-register row 183). Re-run on pristine
upstream at `c3ff8c53f`, both fork engines and gcc on 2026-11-10. This draft by Claude (Fable 5.2) under operator
direction; the filed issue carries an AI-provenance note per the tray's policy.
