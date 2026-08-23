# Make `--pp core` output round-trip through the Core parser

*(draft PR description — this file is not part of the commit series)*

## Problem

`cerberus --pp core` output is mostly accepted by the Core parser, but a
number of printed forms either do not re-parse at all or — worse —
re-parse silently to a *different* program. Anyone who consumes `.core`
text (dumping and reloading programs, external analyses, differential
testing against the printed Core) currently hits these. Observable
symptoms, all reproducible from `tests/ci` with `--nolibc --pp=core`:

**Rejected forms** (re-parse fails loudly):

* bodyless `proc` declarations print as `proc f (bTy1, ..., bTyN)` —
  no return type (unrecoverable from the text) and no grammar
  production for the form;
* `error("assert() failure", e)` — the grammar only accepted the
  `<<<NAME>>>` spelling of the message;
* variadic function types in ctype literals, `'signed int (char*, ...)*'`
  — a menhir shift/reduce conflict ("arbitrarily resolved", reported at
  every build) made the `, ...` suffix unreachable, and the parsed
  `is_variadic` flag was hardcoded `false`;
* `memberof(tag, member, pe)` — printed by `pp_core`, no production,
  and a `failwith "WIP"` stub in the symbolification;
* ctype *values* printed in the Ail declarator dialect
  (`'signed int (*)(signed int)'`, `'long long'`) while the grammar
  reads the Core dialect (`'signed int (signed int)*'`, `'long_long'`);
* list literals printed as bare `[e1, e2]` where the grammar requires
  `[e1, e2] : [bTy]` (and `[] : bTy` printed the *element* type, which
  trips the parser's `ensure_list_core_base_type` failwith);
* a `builtin` declaration in a `.core` file crashed the parser with
  `assert false` (its symbol was never registered in file mode).

**Silent mis-parses** (re-parse succeeds with a different tree/values):

* `Cfunction(f)` pointer values were parsed to `null_ptrval void`
  (the `(*TODO*)` in `core_parser.mly`), turning every reloaded
  function pointer into NULL;
* a pure `if`/`let` printed as an operand of a binary operator gets no
  parentheses, so `(if c then a else b) + x` prints exactly like
  `if c then a else (b + x)`; the elaborator produces this shape
  routinely (integer-promotion wrappers);
* a unit-pattern `Esseq` prints `e1 ; e2` with no delimiters, so when
  `e1` ends in an open-ended construct (`if`/`let`/`save`) the `; e2`
  sequel is swallowed into `e1` on re-parse — the elaboration of an
  else-less C `if` produces exactly this shape, so it is pervasive;
* re-parsed `seq_rmw(ty, obj, x => upd)` dropped `obj` and used `upd`
  twice (a typo in `symbolify_action_`), corrupting every `++`/`--`;
* struct/union tags in object types printed via `Pp_symbol.to_string`
  (`name_num`) while their definitions print pretty names, so the
  reference matched no printed definition (and re-printing grew the
  name by `_0` per cycle);
* top-level symbols were registered in *reverse* file order (a
  `foldrM`), so the fun map — printed in symbol order — flipped its
  order on every print/parse cycle and printing never reached a
  fixpoint.

## What this PR does

For each form the default was to make the **printer** emit what the
**parser** already accepts (printers are the lower-risk surface); the
parser is extended only where the printed form is clearly the right
syntax and the grammar simply has a gap or a bug.

| Form | Fix | Side |
|---|---|---|
| bodyless `proc` decl: no return type | print `: eff bTy` | printer |
| bodyless `proc` decl: no production | accept it, map to `ProcDecl` | parser |
| `builtin` decl printed without its type | print `: eff bTy` (grammar already requires it) | printer |
| `builtin` decl in file mode: `assert false` | register its symbol | parser |
| `Cfunction(f)` → NULL punt | resolve the name, build `fun_ptrval` | parser |
| `seq_rmw` object argument dropped | fix the symbolify typo | parser |
| `error("...")` rejected | also accept the string-literal form | parser |
| variadic ctypes rejected (grammar conflict) | conflict-free `params`, plumb `is_variadic` | parser |
| `memberof(...)` unparseable | add keyword/production/symbolify | parser |
| `if`/`let` as operator operand ambiguous | give them a precedence, parenthesise | printer |
| `;`-sequence swallows into open-ended lhs | parenthesise open-ended lhs | printer |
| ctype values in Ail dialect | print the Core dialect (`Pp_core_ctype`) | printer |
| list literals without type annotation | print `: [bTy]` | printer |
| struct/union tags as `name_num` | print pretty names like the definitions | printer |
| declaration order flips per cycle | register names in file order | parser |

The grammar refactorings (`proc_param`, `nonempty_params`) keep the
grammar LR(1); the `params` change *removes* the one shift/reduce
conflict menhir used to warn about for the Core parser (the
reduce/reduce conflicts in the ctype rules are untouched).

## Test

`tests/run-roundtrip.sh` (same idiom as `run-ci.sh`): for every ci
test that elaborates under `--nolibc` and has a `main`, it checks

1. `--pp=core` output re-parses (the driver's `.core` path),
2. printing is a fixpoint: with `t2 = pp(parse(pp(elab)))` and
   `t3 = pp(parse(t2))`, `t2 == t3` byte-for-byte,

and additionally reports how many cases are byte-stable already at the
first re-parse (`pp(elab) == t2`).

Results on the 113 ci tests that elaborate (and have `main`):

|  | passed | byte-stable | failed |
|---|---|---|---|
| master (b9aeedcb4) | 59 | 43 | 54 |
| this branch | **110** | **104** | **3** |

(The fixpoint check is necessary, not sufficient — a silent mis-parse
can itself be print-stable — so the byte-stable count is the stronger
signal.)

The 3 remaining failures are all one class: distinct symbols whose
*pretty-printed* names collide, e.g. shadowed struct tags both printed
as `T1`, a re-declared extern printed twice as `proc printf ...`, or a
C identifier that is a Core keyword (`glob`). Fixing those needs a
disambiguation scheme in the symbol printer (or accepting keyword-named
symbols), which seemed worth discussing before attempting; the same
applies to printing `Function`/`FunctionNoParams` distinctly and to
associativity of same-precedence operator chains (`a - b - c` re-parses
left-associated regardless of the original tree — invisible to the
fixpoint test since both trees print alike).

One further pre-existing gap became *reachable* with these fixes: the
dump does not serialise `funinfo` (the `-- C function types` section is
only printed with `show_include` and has no grammar), so *executing* a
reloaded dump fails with "does not point to a function (cfunction)" as
soon as the program calls one of its own C functions. Textual
round-tripping is unaffected; fixing execution-after-reload needs a
serialisation for funinfo and seemed worth a separate discussion.

## Validation

* `cd tests && ./run-ci.sh`: **188 passed / 0 failed** on this branch
  (same as master).
* `tests/diff-prog.py cerberus bytes/elab.json` (14 tests) and
  `bytes/exec.json` (9 tests): all pass.
* `tests/run-roundtrip.sh`: table above.
* The core-parser menhir warnings drop from "1 shift/reduce + 3
  reduce/reduce arbitrarily resolved" to the 3 reduce/reduce only.
* Spot check of semantic fidelity: `--exec --batch` on a reloaded dump
  matches `--exec --batch` on the original `.c` for programs that do
  not call their own C functions (see the funinfo note above for those
  that do).

To run the new test: build (`make cerberus`), then
`cd tests && ./run-roundtrip.sh` (or `./run-roundtrip.sh <name>.c` for
a single ci test).

## Provenance

These defects were found, and this patch (code, tests, and this
description) was written, by an AI assistant (Anthropic's Claude) under
human direction, as part of a project that differentially tests
Cerberus against a Lean port of its semantics. It is submitted after
review and validation by the human author.
