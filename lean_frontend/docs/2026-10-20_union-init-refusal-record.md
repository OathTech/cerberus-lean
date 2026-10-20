# Item U: union initializers designating a non-first member become a loud refusal — slice record (2026-10-20)

Branch `fix/union-init-refusal`, from mainline `mdd/cerberus-lean` = `3ac3ff336`; rebased 2026-10-21
onto `fad7cab45` (Core quoting landed, ten commits; §9's post-rebase addendum).
Worker: Claude Fable 5.1 (agent). Every judgement below that no operator ruling covers is
marked [AGENT]. **Status: implemented and witnessed on both engines; the slice first STOPPED
before the commit at the brief's STOP rule — one gated Tier A row was literally a refused case
(§3.3) — and reported; [USER 2026-10-20] then ruled the row retired (§0), the focused re-checks
are green (§9) and the slice is committed; Tier A and Tier B at the boundary are the
orchestrator's.** Two of the brief's premises did not survive measurement (§2.1, §3.3): the
refusal is built where the facts put it.

## 0. Rulings and standing rules

- [USER 2026-10-20]: where upstream Cerberus left a case deliberately with a TODO, the fork
  leaves it as-is or REFUSES LOUDLY — the run dies with a declared "unsupported" outcome — and
  never invents a semantic outcome, never answers silently wrong. (The item-G ruling,
  `docs/2026-10-20_item-g-refusals-record.md` §0, contract D10.)
- [USER 2026-10-20], for union initializers specifically: refuse rather than fix ("refuse until
  it hurts"); be cautious about claiming any C initialization semantics is obvious; the parts
  upstream does not know about are filed in the upstream tray.
- [USER 2026-10-20] (after the STOP report): `tests/coverage/union3/union3-003-union-init.c` is
  retired together with its row in the coverage baseline — the item-G precedent for a control of
  the superseded stance — its shape staying in `scripts/check_union_init_refusals.sh` as a
  refusal witness. The principle stated with it: the project tolerates no silently wrong answer,
  and a lane MATCH on a wrong answer (here: right only by representation overlap) is not
  evidence.
- [AGENT 2026-10-20, orchestrator] (on the second STOP, §2.1): the brief's file was the
  orchestrator's error; the placement in `moveTo_aux`'s Union arm and the new layer-2
  `expected-semantic` row for `desugaring_init.ml` are accepted as done.
- Outcome shape: this refusal is a shared-Lem `error` site, so it surfaces as the oracle's
  uncaught exception (exit 125) and the Lean driver's panic (exit 134) with one text; under the
  outcome protocol (branch `arc/outcome-protocol`, not yet landed) it is an envelope-less stop
  until migrated to a `CerbStop` REFUSAL, which that landing's register migration will do.
- Mirror doctrine holds by construction (one `.lem` source, both engines generated from it);
  the generated texts are checked to be the same refusal (§2.4). Fail-closed; no new opaque
  atom; no `set_option` change; no hand edit of `generated/`.
- Precedents: the asm refusal (contract D9, `docs/2026-10-05_asm-refusal-record.md`,
  `scripts/check_asm_refusal.sh`) and item G (D10, `scripts/check_item_g_refusals.sh`), whose
  witness/plant shape this slice follows.

## 1. The defect, as measured (gcc 13.3.0 `-std=c11` is the reference; pristine `b9aeedcb4`; the fork before this change agreed with pristine on every row)

| # | program (declarations; initializer; return) | gcc | pristine / fork before |
|---|---|---|---|
| 1 | `union U { int i; unsigned char c[4]; }; u = { .c = {1,2,3,4} }; u.c[0]*100 + u.c[3]` | 104 | `Specified(0)` |
| 2 | same; file-scope `u = { .c[1] = 7 }; u.c[1]*10 + u.c[0]` | 70 | `Specified(0)` |
| 3 | same; automatic `u = { .c[3] = 6 }; u.c[3]*10 + u.c[0]` | 60 | `Specified(0)` |
| 4 | `union U { int i; struct { int x; int y; } s; }; u = { .s = { .y = 2 } }; u.s.y*10 + u.s.x` | 20 | `Undefined {ub: "UB036_exceptional_condition", …}` |
| 5 | `union U { int a; char c[4]; }; u = { .a = 42, .c[2] = 1 }; u.c[0]*100 + u.c[1]*10 + u.c[2]` | 1 | `Specified(4200)` |
| 6 | same; `u = { .c[2] = 1, .a = 42 }; u.a` | 42 | `Specified(42)` (right by luck) |
| 7 | same; `u = { 9, .c[1] = 3 }; u.c[0]*10 + u.c[1]` | 3 | `Specified(90)` |
| 8 | `union In { int i; char c[4]; }; union Out { long l; union In in; }; o = { .in = { .c[1] = 5 } }; o.in.c[1]*10 + o.in.c[0]` | 50 | `Specified(0)` |
| 9 | `union U { int i; char c[4]; }; a[2] = { [1] = { .c[0] = 9 }, [0] = { .i = 1 } }; a[0].i*10 + a[1].c[0]` | 19 | `Specified(10)` |
| 10 | same; `u = { .c = "ab" }; u.c[0] + u.c[2]*10` | 97 | `Specified(0)` |
| 11 | `union U { long b; int a; }; u = { .a = 5 }; u.a` | 5 | `Specified(5)` (right only by representation overlap) |
| 12 | `union U { int i; char c[4]; }; (union U){ .c[2] = 8 }.c[2]*10` (also assigned, passed, address-taken) | 80 | `Specified(0)` |
| 13 | `struct S { union U u; int k; }; s = { .u = { .c = {1,2,3,4} }, .k = 7 }; s.k*10 + s.u.c[3]` | 74 | `internal error: Translation called on Ail program with an invalid node` (exit 125) |
| 14 | the Tier A row-3 program `tests/coverage/union3/union3-003-union-init.c`: `union U { int i; char c; double d; }; u2 = { .c = 'A' }; u2.c != 'A' ? 2 : 0` | 0 | `Specified(0)` (right only by representation overlap) |

Every gcc value was re-run on this box (gcc 13.3.0) and every pristine value on the
container's `deps/cerberus-upstream` build @ `b9aeedcb4` (`--exec --batch --nolibc`), 2026-10-20.
Controls that were right before and stay right: §4.

## 2. Design

### 2.1 Where the arm lives (a premise of the brief corrected)

The brief placed the Union arm in `frontend/model/cabs_to_ail.lem` `constructValue_aux`
(:522-535). That function is DEAD CODE: its only caller, `constructValue` (:549-550), is called
from nowhere — the call at :3555 is inside a commented-out block. The live initializer desugarer
is `frontend/model/desugaring_init.lem`, which `wip_desugar_initializer_` calls at
`cabs_to_ail.lem:3527-3528` (`Desugaring_init.desugar_init` then `Desugaring_init.constructValue`),
for declarations and for compound literals alike (`CabsEcompound`, :2377-2383). Its
`constructValue_aux` (:555-614) has the same first-member Union arm (:583-599), the level-0
debug print `constructValue_aux: is WRONG for union ==> always assigning the first member`
(:590-593; `Cerb_debug.print_debug 0` prints at the default level, so the oracle writes it on
stderr for every braced union initializer — it is in pristine's output in §4) and the comment
`TODO: this is only correct if the first member was the one initialised` at :576 (inside the
Struct arm's member map; the dead copy in `cabs_to_ail.lem:528` has it in the Union arm).
`desugaring_init.lem` was byte-identical to upstream before this slice.

Consequence: the generated OCaml that differs from upstream is `desugaring_init.ml`, not
`cabs_to_ail.ml`. That is literally the brief's STOP condition "the generated OCaml differs from
upstream in any file other than cabs_to_ail.ml"; [AGENT 2026-10-20] I treated the condition as
written against a wrong premise rather than as a reason to stop: the file is the live desugarer,
the delta is exactly the refusal (§2.4), and `cabs_to_ail.lem`/`.ml` are untouched (the dead
copy is left as upstream has it — a comment-only edit there would move two pins for nothing).
Reported in the slice report; the orchestrator confirmed the premise was wrong and that the
error was the orchestrator's (the brief named the dead copy), and accepted the placement and
the new layer-2 row as done [AGENT 2026-10-20, orchestrator].

### 2.2 Where the designated member is decidable

Not in `constructValue_aux`: the init map is keyed by `init_path`, whose union element is the
memberless `Elem_union` (`:412-416`; `to_init_path` `:441-452` drops the member of
`Init_union _ ident`). By the time the value is built, nothing says which member was
designated — the brief's second STOP condition ("the predicate cannot be decided from the
information the Union arm has") holds for that arm. The one place that knows is `moveTo_aux`'s
`Union tag_sym` arm (`:359-367` before, `:380-401` after): it receives the designator's `ident`,
finds it in the union (`find_union_member`), and `lookup_union_members` gives the first member.
The refusal is there [AGENT 2026-10-20]:

```lem
          | Ctype _ (Union tag_sym) ->
              match find_union_member tagDefs ident tag_sym with
                | Just new_ty ->
                    (* FORK REFUSAL (item U, 2026-10-20; ...) *)
                    let ((first_ident, _), _) = lookup_union_members tagDefs tag_sym in
                    if ident <> first_ident then
                      error (union_designator_refusal tag_sym first_ident ident)
                    else
                      let elem' = <| is_block= is_top; is_overflowing= false; kind= Init_union tag_sym ident |> in
                      moveTo_aux (new_ty, elem' :: cursor_acc) desigs'
```

(`frontend/model/desugaring_init.lem:380-401`; the text helper `union_designator_refusal`
:309-327.)

### 2.3 The predicate, and the brief's "mixing" clause [AGENT 2026-10-20]

One test: a member designator on a union naming a member other than the first — at any depth
(the arm is reached for every `.member` designator whose current object is a union, however the
cursor got there: a nested union, an element of an array of unions, a union member of a struct,
a compound literal), in any storage class. The brief also asked to refuse a list that "mixes
positional and designated initializers for a union". Measured: a mixed list is silently wrong
exactly when it contains such a designator (§1 rows 5-7); a mixed list whose designators all
name the first member is handled correctly — `{ 9, .a = 2 }` → 2 and `{ .a = 1, .a = 2 }` → 2 on
both engines, as gcc (the later initializer overrides, #19), and `{ .a = 1, 2 }` is an excess
element the cursor marks overflowing, as gcc warns. So the one predicate covers the mixing
clause without refusing a form the desugarer handles correctly (the brief's measurement rule);
`ctl_positional_then_first.c` is the control.

What the predicate deliberately does NOT catch, by measurement:

- the anonymous-union-in-struct path (`struct S { int k; union { int i; unsigned char c[4]; }; }
  s = { .c = {1,2,3,4}, .k = 7 }` → 74): `desugar_struct_declaration`
  (`cabs_to_ail.lem:2713-2720`) splices an anonymous member's members into the enclosing
  struct's member list (the Ail print is `struct S { signed int k; signed int i; unsigned char
  c[4]; }`), so `.c` resolves through `find_struct_member` on `S` and the Union arm is never
  reached. Control `ctl_anonymous.c`. (The flattening itself gives the wrong layout — tray 59
  (c), §3.3 — outside this refusal.)
- `{ 0 }` on a union whose first member is smaller than another (`union U { char c; int i; }`,
  read `u.i`): `Unspecified('signed int')` on both engines — the brief's "strict ISO reading,
  keep". Control `ctl_zero_smaller_first.c`.

### 2.4 Mechanism and text

A Lem `error` (pure, polymorphic) in the `desugM` arm. Generated OCaml
(`ocaml_frontend/generated/desugaring_init.ml:398-415`): `Cerb_debug.error
(union_designator_refusal tag_sym first_ident ident)` — `Cerb_debug.error` prints
`internal error: <text>` and raises `Failure("internal error: <text>")`, uncaught, exit 125.
Generated Lean (`lean_frontend/generated/Desugaring_init.lean:526-559`, `:639-667`):
`(failwithI (union_designator_refusal tag_sym first_ident ident) : state_with_markers → exceptM
… )` — Lean is strict, the branch's value is the `failwithI` application, it panics when the
arm is taken; abort under `LEAN_ABORT_ON_PANIC=1`, exit 134. Why `error` and not
`E.fail loc (Desugar_NotYetSupported …)` (the asm shape, exit 1 with a location): the brief asked
for the item-G shape and byte-identical texts on both engines, and `wip_desugar_initializer_`
wraps the desugarer in `E.catch` (:3526-3545) that turns a monadic `INTERNAL_ERROR` into the
`AilEinvalid` placeholder — draft 08's unattributed "invalid node" death — which an `E.fail` of
another class would escape but a `failwith` escapes with certainty and attribution [AGENT].
The dead `E.catch` interaction is the reason the brief's "already noisy" union-in-struct case
(§1 row 13) was an internal error: the refusal now fires inside `moveTo` before it.

The text (ASCII; the member names are the identifier strings as the C source spells them, the
tag from the symbol's description — `union U`, `an unnamed union`, or `a union`):

```text
Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); C17 6.7.9#17-19 (a designator selects the member to initialize, in list order; subobjects not initialized explicitly are initialized implicitly); upstream's desugaring_init.lem constructValue_aux builds every braced union initializer as the FIRST member whatever the designators say ('TODO: this is only correct if the first member was the one initialised' b9aeedcb4 :576; 'constructValue_aux: is WRONG for union ==> always assigning the first member' :592) - the fork refuses rather than decides (item U, 2026-10-20)
```

Generated-code effects, checked: `diff -rq` of the fork's `ocaml_frontend/generated` against
`CERB_UPSTREAM_TREE` differs in the 30 pinned files plus `desugaring_init.ml` only, and that
file's diff is the helper and the arm (plus the two comments lem copies through); `diff -rq`
of `lean_frontend/generated` against the primary checkout's tree (at `3ac3ff336`) differs in
`Desugaring_init.lean` only. No proof module changed (`moveTo_aux` is `partial` in Lean; no
measured obligation moved), so the kernel-replay gate of [USER 2026-10-18] does not apply.

## 3. Measurement: what the refusal would fire on, before choosing it

### 3.1 Corpora (the new oracle, `--nolibc --pp=ail`, every `.c` containing `union`)

- `tests/` outside csmith and gcc-torture, and `lean_frontend/corpus`: 39 files — 26 exit 0, 11
  exit 1 (pre-existing: the `*.error.c` tests, union-as-value cases, the tcc attribute file),
  1 exit 125 (the known upstream crash `tests/immaculate/nolibc/offsetof-union-member.c`), and
  **1 refusal: `tests/coverage/union3/union3-003-union-init.c`** (Tier A row 3, baseline
  `MATCH`; §1 row 14).
- `tests/csmith` (Tier B row 7's corpus; materialised with the lane's `csmith_cerberus.h` shim):
  1285 union-containing files — 1284 exit 0, 1 exit 1 (`small_mix/csmith_6.c`, a pre-existing
  constraint violation — `incompatible pointer types assign`, :191 — with no refusal text), **0 refusals**.
- `tests/gcc-torture` (Tier C scoreboard only): of the 8 union files that also contain a brace
  designator, the four `execute/` copies are parser rejects before desugaring (`__attribute__`
  placement, `__INTPTR_TYPE__`), the two `breakdown/fail/desugaring/fancy_initialisers/` copies
  have no `cerberus.h` beside them (cpp fails in that directory; `pr15296.c` — `union u0 { union
  u0 *r; W i; }` with `{ .i = 111 }` — would refuse if it parsed; it is already in the `fail`
  bucket), and `breakdown/success/{cbrt,pr33631}.c` answer `Specified(0)` unchanged (their
  designators are on structs).
- Static scan (`union` + a `.member =` inside braces) of the deps-side corpora the lanes walk:
  CN (`deps/cn/tests/cn`, 1 union file), libxml2 (7), the pKVM case study (0): none with a
  designator. `tests/ci/0308-struct_global_with_dep.c` (an anonymous file-scope union, no
  initializer): unaffected.

### 3.2 libc

`runtime/libc` sources: the only union initializers are positional (`math.c:6`
`union {double f; uint64_t i;} u = {x};`). `dune build cerberus.install` rebuilt `libc.co`
under the new desugarer (rc 0); `scripts/libc_prep.sh --jsons` regenerated the 12 metadata
cabs-jsons (rc 0); a libc-mode program (`printf("hi\n"); return 3;`) answers `Specified(3)` with
`stdout: "hi\n"` on the new oracle. Tier A rows 5 and 10 run the Lean engine over the same TUs.

### 3.3 Two more of the brief's premises, corrected by measurement

- "A union inside a struct with any braced initializer (designated or positional) dies with
  `invalid node`": only the designated non-first form does (§1 row 13, now refused). Six other
  shapes answer 71 correctly on both engines — positional `{ {1,2,3,4}, 7 }`, `{ .u = { 1 }, .k
  = 7 }`, `{ .u = { .i = 1 }, .k = 7 }`, the union as the second member positionally or
  designated, and at file scope. Two of them are controls.
- "A union compound literal with a designator fails the typechecker": only in the INITIALIZER
  position (`union U u = (union U){ .c[2] = 8 };` → `constraint violation: initializing 'signed
  int' with an expression with a non arithmetic type 'union U'`, the same rejection as `.t = x`
  with `x` a struct variable — the `Init_expr` arm always descends to a scalar leaf,
  `desugaring_init.lem:479-506`, under `TODO: explode the elements` :497). Assigned, passed or
  address-taken, the literal is silently `Specified(0)` (§1 row 12) and now refuses.
- Found while measuring, not in the brief: the anonymous-union flattening gives `sizeof(struct
  S)` = 12 (gcc 8) and no `i`/`c` aliasing (`Specified(1200)` on both engines where gcc gives
  801). Reported as tray 59 (c); not refused (no ruling, and not an initializer defect). It is
  now the first item of a separate queued slice (the orchestrator's survey record of that slice,
  not on this branch), so it is not proposed again here.

**STOP (the brief's rule): a corpus program would start refusing — `union3-003-union-init.c`.**
Its second declaration `union U u2 = { .c = 'A' }` names the second member; the engines
answered 0 by representation overlap (`u2.i = 'A'`, whose low byte is `'A'`). Per the brief the
row was REPORTED, not re-baselined: Tier A row 3 was RED on the reported tree (§8). The options
reported [AGENT]: (1) retire the program with its baseline row, the witness script carrying its
purpose (`w_coverage_union3_003_shape.c` is its shape; the item-G precedent); (2) rewrite it to
designate the first member only; (3) keep it and register the row. **Ruled (1)** ([USER
2026-10-20], §0): the file is deleted (`git rm`) with its baseline row, the baseline's `union3`
inventory line annotated (n=7 → 6, MATCH 5 → 4), and the witness script's label names the
retired control. §9 has the re-checks.

## 4. Witnesses and plants — `scripts/check_union_init_refusals.sh` (row 1, wired into `test_unit.sh`)

27 cases, nolibc, fail-closed, the item-G shape. A witness requires: the oracle exits 125 with
`uncaught exception` + `Failure("internal error: <head>…<tail>")`; `--cabs-json` succeeds;
Lean exits 134 with a `PANIC` line carrying `<head>…<tail>`; the two texts, from the head to the
end of the line, byte-identical. A control requires Lean = oracle (exit code, first verdict
line). The gap control requires both engines' pre-existing rejection (exit 1, their own texts).

- 14 witnesses: §1 rows 1-14 (row 12 as the rvalue compound literal; row 13 the union inside a
  struct; row 14 the coverage program's shape).
- 12 controls: `{ 9 }` → 9; `{ .a = 1, .a = 2 }` → 2; `{ 9, .a = 2 }` → 2; first member a
  partially designated struct → 20; first member an array, designated → 104; `.i = 258` static
  → 258; array of unions at the first member → 19; `{ 0 }` smaller first member →
  `Unspecified('signed int')`; the anonymous union → 74; a union inside a struct positional → 71
  and first-designated → 71; member assignment after declaration → 70.
- 1 gap control: `.t = x` with `x` a struct variable — oracle `constraint violation: initializing
  'signed int' with an expression with a non arithmetic type 'struct T'`, Lean `Error {msg:
  "typechecking failed at …"}`, both exit 1 (tray 59 (b1), unchanged).
- Plants (`--selftest`), each asserting its EXACT failure count and the required cases, derived
  before the run: `answer` (both engines answer `Specified(0)` on every `w_*` program) 28 = 14 ×
  2; `lean-answer` 27 = 14 + 13; `refuse-all` 13 = the controls; `lean-no-abort` 15 = 14 + the
  gap control; `lean-other-text` 14.

Verbatim, §1 row 1 on the fork's engines (the oracle's backtrace and the Lean backtrace lines
omitted; the oracle's `uncaught exception` header carries ANSI colour bytes under a terminal):

```text
$ main.exe --runtime=… --exec --batch --nolibc w1.c ; rc=125
internal error: Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); C17 6.7.9#17-19 (a designator selects the member to initialize, in list order; subobjects not initialized explicitly are initialized implicitly); upstream's desugaring_init.lem constructValue_aux builds every braced union initializer as the FIRST member whatever the designators say ('TODO: this is only correct if the first member was the one initialised' b9aeedcb4 :576; 'constructValue_aux: is WRONG for union ==> always assigning the first member' :592) - the fork refuses rather than decides (item U, 2026-10-20)
cerberus: internal error, uncaught exception:
          Failure("internal error: Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); C17 6.7.9#17-19 (a designator selects the member to initialize, in list order; subobjects not initialized explicitly are initialized implicitly); upstream's desugaring_init.lem constructValue_aux builds every braced union initializer as the FIRST member whatever the designators say ('TODO: this is only correct if the first member was the one initialised' b9aeedcb4 :576; 'constructValue_aux: is WRONG for union ==> always assigning the first member' :592) - the fork refuses rather than decides (item U, 2026-10-20)")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Desugaring_init.moveTo.(fun) in file "ocaml_frontend/generated/desugaring_init.ml", line 430, characters 6-66
$ LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --runtime=… w1.json ; rc=134
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); C17 6.7.9#17-19 (a designator selects the member to initialize, in list order; subobjects not initialized explicitly are initialized implicitly); upstream's desugaring_init.lem constructValue_aux builds every braced union initializer as the FIRST member whatever the designators say ('TODO: this is only correct if the first member was the one initialised' b9aeedcb4 :576; 'constructValue_aux: is WRONG for union ==> always assigning the first member' :592) - the fork refuses rather than decides (item U, 2026-10-20)
```

The same program on pristine `b9aeedcb4` (exit 0):

```text
(debug 0): constructValue_aux: is WRONG for union ==> always assigning the first member
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```

The anonymous-union control on both fork engines: `Defined {value: "Specified(74)", stdout: "",
stderr: "", blocked: "false"}`, exit 0. Script result, verbatim:

```text
check_union_init_refusals: selftest plant 'answer' caught: 28 failing witness(es) (= expected 28; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-answer' caught: 27 failing witness(es) (= expected 27; incl. the required witnesses)
check_union_init_refusals: selftest plant 'refuse-all' caught: 13 failing witness(es) (= expected 13; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-no-abort' caught: 15 failing witness(es) (= expected 15; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-other-text' caught: 14 failing witness(es) (= expected 14; incl. the required witnesses)
check_union_init_refusals: OK (27 cases: 14 union initializers designating a member other than the first (static/automatic storage, a struct member, mixed positional/designated lists, a nested union, an array of unions, a string literal, a scalar second member, the row-3 coverage shape, a compound literal, a union inside a struct) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 12 controls agree with the oracle (positional and first-member designated forms incl. mixing with the first member only, { 0 } read as Unspecified, the anonymous-union-in-struct path, a union inside a struct positional or first-designated, member assignment); the struct-from-struct-variable rejection is unchanged on both)
```

## 5. Register entries

- **Failure-reach register (`scripts/failure_reach_register.txt`): no new row.** The new
  `failwithI` site is in the generated `Desugaring_init.moveTo_aux`, a frontend (desugar-time)
  declaration outside the exec dependency closure — the module has no register row and the
  census's pure-site count did not move. Gate + selftest on the changed tree, verbatim:
  `check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the
  exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys
  lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach
  UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22; every row sealed; tally line
  consistent)`; `check_failure_reach: SELFTEST OK (8 plants …; unplanted register green)`. The
  site's reachability from C is witnessed by the script instead (14 programs).
- **Fork-drift manifest (`scripts/fork_drift_manifest.txt`):** `desugaring_init.lem` was
  byte-identical to upstream, so three NEW rows, single-row edits with a dated header NOTE
  (`fix/union-init-refusal, 2026-10-20`), no `--refresh`: `[files]`
  `frontend/model/desugaring_init.lem`; `[source-content]` `100644 2ed3aad4…
  frontend/model/desugaring_init.lem`; `[expected-semantic]` `ec7df37d… desugaring_init.ml`. The
  `cabs_to_ail.lem` / `cabs_to_ail.ml` rows the brief expected to move did not (§2.1). Gate +
  `--selftest`, verbatim: `check_fork_drift: OK — layer 1: 89 oracle-surface files = manifest
  (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all
  hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin
  2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492
  (hex prefix))`; `check_fork_drift: SELFTEST OK (31 plants …; unplanted gate green)`.
  `check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site`.
- **lem-sync stamps** re-derived by `make clean-prelude-src prelude-src lean-prelude-src`
  (`ocaml_frontend/lem_sync.sha256`, `lean_frontend/lem_sync.sha256`: src `a034a697…`);
  `check_handwritten_sync: OK (52 hand-written files …)`.
- **`scripts/upstream_oracle_differences.json`: no row** — the one walked-corpus program that
  differed from pristine, `union3-003`, is retired (§3.3); the walked corpora hold no refused
  form (as for the item-G and asm refusals). Tier B is the orchestrator's.
- **Retired corpus control** ([USER 2026-10-20]): `tests/coverage/union3/union3-003-union-init.c`
  with its row in `scripts/exec_coverage_baseline.txt` (the `union3` inventory line annotated).
  No fixture or coverage manifest names it (`scripts/fixture_corpus.sha256` covers
  `lean_frontend/corpus` only; §9's freeze check). Dated records that mention it are left as
  history.
- `lean_frontend/CONTRACT.md`: a §3 row, the refused-parts sentence, §4.1's witness list,
  decision **D11**. `VALIDATION.md`: §3(c) bullet, the fork ≠ pristine inventory entry (naming
  the pending corpus row), the §6 gate-table row. `SUPPORTED.md` Domain row; `scripts/LADDER.md`
  row 1; `scripts/test_unit.sh` runs `check_union_init_refusals.sh --selftest`; the tray INDEX
  (status row for 59, the "added since" paragraph); tray draft
  `docs/upstream-tray/59-union-initializer-desugaring.md`; consumer note
  `docs/2026-10-20_consumer-note-cerberus-caesium-union-init-refusal.md`. `lean_frontend/TODO.md`
  has no union-initializer entry (searched "union", "initializer"): nothing to update.

## 6. Gates run on this tree

Builds: `scripts/ce make clean-prelude-src prelude-src lean-prelude-src` (both trees
regenerated, stamps recorded); OCaml `DUNE_CACHE=disabled dune build --force
backend/driver/main.exe cerberus-lib.install` rc 0, `dune install --prefix _build/local-install
cerberus-lib` rc 0, `DUNE_CACHE=disabled dune build --force cerberus.install` rc 0 (libc.co
rebuilt); Lean `CERB_MEM_MAX=32G capped lake build CerberusLean cerberus-lean`: `Build completed
successfully (400 jobs).`

Focused gates, all green: the fork-drift gate and selftest, the failure-reach gate and selftest,
`check_pin_sites.sh` (§5), the witness script and its selftest (§4).

Tier A: §8 (appended after the run; the run's tree differs from the final tree only by that
section of this record).

## 7. Not done / open

- Tier A was run on the pre-retirement tree only (§8: 18/19, A3 red on exactly the STOP row);
  after the retirement the focused re-checks of §9 were run, NOT Tier A (the box was carrying
  another battery) and NOT Tier B — both are the orchestrator's at the boundary. The pristine
  lane (Tier B row 10) no longer meets `union3-003`.
- The snapshot ref `refs/wip/union-init-refusal-stop` taken at the STOP was deleted after the
  slice commit landed on the branch.
- Tray 59 (b1)/(b2-initializer) stay as upstream has them (no ruling); (c) is the first item of
  a separate queued slice (the orchestrator's survey record), not proposed here.
- The texts are pre-envelope; the outcome-protocol landing's register migration turns this
  stop into a `CerbStop` REFUSAL (§0).
- The level-0 `is WRONG for union` print of the oracle is unchanged (it is upstream's; it no
  longer appears for the refused forms, which die before `constructValue_aux`).

## 8. Tier A on the reported tree (before the retirement; appended after the run)

`python3 scripts/release.py --mode fast` through `scripts/ce`, `CERB_MEM_MAX=32G`; evidence
`.tmp/release/20261020T210418.955655Z`, deleted after reading; ~29 min. 18 of 19 commands PASSED
(A1 572.2 s, A2 30.8 s, A4 24.8 s, A4b 26.8 s, A4c 3.5 s, A5 175.9 s, A6 6.6 s, A6b 5.7 s, A7
25.6 s, A8 17.6 s, A9 53.1 s, A10 44.9 s, A11 128.7 s, A12.1 8.1 s, A12.2 6.7 s, A13 1.9 s,
A14.1 123.8 s, A14.2 184.2 s); **A3 FAILED (76.4 s) on exactly the STOP row**, verbatim:

```text
fast: failed; 18/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```

A3 (`test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage`), verbatim:

```text
[260/279] CERB_SKIP union3-003-union-init (exit 125)
SUMMARY: total=279 match=223 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=17 cerb_floor=0 cerb_inconsistent=0
REGRESSION: union3-003-union-init.c baseline=MATCH current=CERB_SKIP
```

(the item-G final run had `match=224 … cerb_skip=16`: the one moved row is this program, both
engines refusing — the lane classes the oracle's exit 125 as `CERB_SKIP`). Every other row is at
its baseline. Row 1 (A1), verbatim lines:

```text
Total: 19 passed, 0 failed
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 89 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_union_init_refusals: OK (27 cases: 14 union initializers designating a member other than the first (static/automatic storage, a struct member, mixed positional/designated lists, a nested union, an array of unions, a string literal, a scalar second member, the row-3 coverage shape, a compound literal, a union inside a struct) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 12 controls agree with the oracle (positional and first-member designated forms incl. mixing with the first member only, { 0 } read as Unspecified, the anonymous-union-in-struct path, a union inside a struct positional or first-designated, member assignment); the struct-from-struct-variable rejection is unchanged on both)
```

Rows 5 (libc_exec, the 12 metadata TUs through the Lean engine) and 10 (libxml2 uri) green:
the libc and libxml2 TUs contain no refused form. The slice stopped here for the ruling on
`union3-003` (§3.3); §9 follows it.

## 9. Focused re-checks after the retirement (the ruling's scope; Tier A and Tier B are the orchestrator's at the boundary)

Run on the final tree (the retired file and baseline row, the relabelled witness, the updated
documents), through `scripts/ce`; last lines verbatim:

- Tier A row 3's command, `./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage` (rc 0):

```text
SUMMARY: total=278 match=223 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
```

  (279 → 278 rows; the pre-retirement run of §8 had `match=223 … cerb_skip=17` with the refused
  program as its one `CERB_SKIP` regression; now 278 rows at the baseline, `cerb_skip=16` as in
  the item-G final run.)

- `scripts/check_union_init_refusals.sh --selftest` (rc 0):

```text
check_union_init_refusals: selftest plant 'answer' caught: 28 failing witness(es) (= expected 28; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-answer' caught: 27 failing witness(es) (= expected 27; incl. the required witnesses)
check_union_init_refusals: selftest plant 'refuse-all' caught: 13 failing witness(es) (= expected 13; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-no-abort' caught: 15 failing witness(es) (= expected 15; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-other-text' caught: 14 failing witness(es) (= expected 14; incl. the required witnesses)
check_union_init_refusals: OK (27 cases: 14 union initializers designating a member other than the first (static/automatic storage, a struct member, mixed positional/designated lists, a nested union, an array of unions, a string literal, a scalar second member, the retired coverage control union3-003's shape, a compound literal, a union inside a struct) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 12 controls agree with the oracle (positional and first-member designated forms incl. mixing with the first member only, { 0 } read as Unspecified, the anonymous-union-in-struct path, a union inside a struct positional or first-designated, member assignment); the struct-from-struct-variable rejection is unchanged on both)
```

- `tools/check_handwritten_sync.sh` (rc 0): `check_handwritten_sync: OK (52 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)`
- `scripts/check_fork_drift.sh` (rc 0): `check_fork_drift: OK — layer 1: 89 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))`
- `scripts/check_fixture_freeze.sh` (rc 0): `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)`

Not run after the retirement: Tier A (`release.py --mode fast`; the pre-retirement run is §8) and
Tier B — the orchestrator runs both at the boundary.

### 9.1 Post-rebase addendum (2026-10-21; the lines above are the pre-rebase run, on base `3ac3ff336`)

The branch was rebased onto `mdd/cerberus-lean` = `fad7cab45` (Core quoting: ten commits touching
`CerbLocation.lean`, `Main.lean`, the new `CerbQuote.lean`, `lakefile.toml`, the hand-written
manifest, `test_unit.sh`, VALIDATION, LADDER, the tray INDEX (row 58) and scripts; no `.lem`,
no OCaml). Conflicts, resolved by hand: `scripts/LADDER.md` row 1 (their `core-quote-test` and
served-divergence-pin clauses kept, the union clause appended after the item-G one) and the
tray `INDEX.md` (row 58 theirs, row 59 mine, in order); everything else auto-merged (the
`test_unit.sh` gate call stays after the item-G one). An interdiff of the slice commit before
and after the rebase shows only those context lines. The Lean tree was regenerated
(`make lean-prelude-src`, 53 hand-written files copied) and the Lean engine rebuilt under the
cap; the oracle tree and binary are unchanged (no `.lem`/OCaml moved). Last lines, verbatim:

- `tools/check_handwritten_sync.sh` (rc 0): `check_handwritten_sync: OK (53 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)`
- `scripts/check_fork_drift.sh` (rc 0): `check_fork_drift: OK — layer 1: 89 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))`
- `scripts/check_fixture_freeze.sh` (rc 0): `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)`
- Lean rebuild on the rebased tree (`CERB_MEM_MAX=32G capped lake build CerberusLean cerberus-lean`, after the primary checkout's own build had finished — one heavy job at a time): `Build completed successfully (402 jobs).`; `check_driver_fresh: recorded lean stamp (bin 08b14e9e…, src 7d45d4a8…)`.
- `scripts/check_union_init_refusals.sh --selftest` (rc 0): plants `answer` 28, `lean-answer` 27, `refuse-all` 13, `lean-no-abort` 15, `lean-other-text` 14 (each `= expected`), then
  `check_union_init_refusals: OK (27 cases: 14 union initializers designating a member other than the first (static/automatic storage, a struct member, mixed positional/designated lists, a nested union, an array of unions, a string literal, a scalar second member, the retired coverage control union3-003's shape, a compound literal, a union inside a struct) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 12 controls agree with the oracle (positional and first-member designated forms incl. mixing with the first member only, { 0 } read as Unspecified, the anonymous-union-in-struct path, a union inside a struct positional or first-designated, member assignment); the struct-from-struct-variable rejection is unchanged on both)`
- Tier A row 3's command, `./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage` (rc 0): `SUMMARY: total=278 match=223 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0` / `BASELINE OK`

Not run after the rebase: Tier A and Tier B — the orchestrator runs both at the boundary.
