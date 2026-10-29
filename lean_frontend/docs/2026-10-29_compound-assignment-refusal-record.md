# Compound assignment with a side-effecting left operand becomes a loud refusal (survey cluster B, tray 61) — slice record (2026-10-29)

Branch `fix/compound-assignment-refusal`, worktree `worktrees/cerberus-lean-fix/compound-assignment-refusal`,
from mainline `mdd/cerberus-lean` = `b4a48f635` (Lean 4.35.0, lem `e6d8db5`); charter
`docs/2026-10-29_worker-charter-compound-assignment-refusal.md` (commit `d9eb54a18`). Worker: Claude Fable 5.1
(agent). Every judgement below that no operator ruling covers is marked [AGENT]. Status: **implemented, witnessed on
both engines, the focused gates of §6 green on the M1 tree; Tier A and the full battery are the orchestrator's (§6.1,
§6.2 appended after the runs).** The charter's premises held with the corrections of §2.2 (the mechanism) and §2.1 (the
Ail's increment forms; a `sizeof` operand does not reach the walker).

## 0. Rulings and standing rules

- [USER 2026-10-20] (the upstream-uncertainty survey, `docs/2026-10-20_upstream-uncertainty-survey-record.md` §2.2
  cluster B, §3 slice 2): a compound assignment whose left operand has a side effect is REFUSED in the shared Lem and
  the one-binding elaboration filed upstream (tray 61). The standing rule behind it (contract D10/D11/D12): where
  upstream left a case under its own TODO the fork leaves it as-is or REFUSES LOUDLY, never answers silently wrong.
- [USER 2026-10-29] dispatched the slice with the ride-alongs of §8.
- [AGENT 2026-10-29, orchestrator] rulings on the worker's first report (the four questions of §2.2-§2.4): the
  mechanism is a pure Lem `error` with the attributed text (the D11/D12 mechanism), not the `?:` arm's
  `E.record_error_at`; the walker takes the same declared fuel form as its caller (no measure proof, no replay); a
  volatile read inside the lvalue's address computation is not counted; the charter corrections (a)/(d)/(e) and the
  text as proposed.
- Mirror doctrine holds by construction (one `.lem` arm, both engines generated from it; the generated texts are
  checked byte for byte, §4). Fail-closed; no new opaque atom; no `set_option`; no hand edit of `generated/`; no
  hand-written seam or proof module changed (so the kernel-replay gate of [USER 2026-10-18] does not apply).
- Precedents followed: D12 (`docs/2026-10-26_anonymous-members-refusal-record.md`) and D11
  (`docs/2026-10-20_union-init-refusal-record.md`).

## 1. The defect, as it stood (both engines; pristine `b9aeedcb4` agrees — survey §2.2)

`frontend/model/translation.lem` `| A.AilEcompoundAssign e1 aop e2 ->` (pristine `b9aeedcb4` :2505-2531; the fork's
tree had the same numbers before this change; tray 61's `:2510-2535`/`:2511` were stale and are corrected), under
upstream's own `(* TODO: this elaboration is wrong because it duplicates any side-effect in E1 *)` (:2506): the arm
rewrites `e1 op= e2` to `AilEassign e1 (AilEbinary (AilErvalue e1) aop e2)`, so `e1` is elaborated twice — once as
the lvalue (its address computation) and once as the rvalue (the same address computation, then a load). With an
increment, a call or a comma inside the lvalue the second copy is a second side effect. The lane on the 14 survey
probes before the change, verbatim (`scripts/test_exec.sh`, both engines agreeing):

```text
[1/14] MATCH ca-01-ctl: VAL:{value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}
[2/14] UB_MATCH ca-02-idx-postinc: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:46--1:57>"}
[3/14] UB_MATCH ca-03-ptr-postinc: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:49--1:58>"}
[4/14] MATCH ca-04-call-lvalue: VAL:{value: "Specified(23)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(23)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(23)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(23)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(23)", stdout: "", stderr: "", blocked: "false"}
[5/14] UB_MATCH ca-05-shift-postinc: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:47--1:59>"}
[6/14] UB_MATCH ca-06-member-postinc: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:72--1:78>"}
[7/14] MATCH cb-01-rhs-call-once: VAL:{value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}
[8/14] MATCH cb-02-lhs-call-index: VAL:{value: "Specified(24)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(24)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(24)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(24)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(24)", stdout: "", stderr: "", blocked: "false"}
[9/14] UB_MATCH cb-03-predec: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:47--1:58>"}
[10/14] UB_MATCH cb-04-ptr-deref-postinc-struct: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:82--1:87>"}
[11/14] CERB_SKIP cb-05-bitfield-postinc (exit 1)
[12/14] MATCH cb-06-plain-eq-postinc-ctl: VAL:{value: "Specified(15)", stdout: "", stderr: "", blocked: "false"}
[13/14] MATCH cb-07-postinc-on-lvalue-ctl: VAL:{value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}
[14/14] UB_MATCH cb-08-comma-lhs: UB:{ub: "UB035_unsequenced_race", stderr: "", loc: "<1:50--1:61>"}
SUMMARY: total=14 match=6 ub_match=7 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=1 cerb_floor=0 cerb_inconsistent=0
```

gcc 13 (`-std=c11 -w`, the survey's table): ca-02 15, ca-03 17, ca-04 13, ca-05 14, ca-06 15, cb-02 14, cb-03 6,
cb-04 16, cb-08 13 — a false `UB035_unsequenced_race` on the `++`/`--`/comma forms (C17 6.5.16#3 sequences the
update after both value computations; 6.5.16.2#3 evaluates the lvalue E1 only once) and a doubled call on the call
forms (24 against 14; 23 against 13).

## 2. Design

### 2.1 The predicate (`compound_assign_lhs_has_side_effect`, translation.lem, before `translate_expression`)

A syntactic walk over `e1`, exhaustive over the 37 constructors of `AilSyntax.expression_` (no wildcard: a new Ail
constructor is a Lem build error, never a silent "pure"):

- **true (a side effect, or a node whose second elaboration changes meaning):** `AilEunary (PostfixIncr|PostfixDecr)`,
  `AilEassign`, `AilEcompoundAssign` (which is also how the desugarer represents the prefix forms: `cabs_to_ail.lem`
  :2405-2414 turns `++e`/`--e` into `AilEcompoundAssign e Add/Sub 1` — the charter's "four `AilEunary` forms" are two
  `AilEunary` constructors plus this one), `AilEbinary _ Comma _`, every `AilEcall`, `AilEassert`, `AilEva_start`,
  `AilEva_arg`, `AilEva_copy`, `AilEva_end`, `AilEgcc_statement`, `AilEcompound` (a compound literal creates an object
  per evaluation);
- **walked:** unary (other operators), binary (other operators), cond (all three operands), cast, generic (the
  controlling expression and every association), array/struct/union element expressions, memberof, memberofptr,
  `sizeof_expr`, annot, print_type, bmc_assume, rvalue, array_decay, function_decay, atomic;
- **leaves (false):** offsetof, builtin, str, const, ident, sizeof(type), alignof, reg_load, invalid.

Over-approximations, declared ("refuse until it hurts"): every call counts whether or not it has a side effect — the
second elaborated copy calls it again (`ca-04`, `*g() += 3` with `g` pure of side effects on `a`, refuses); a
`_Generic` controlling expression is walked though C does not evaluate it (measured: `a[_Generic(i++, int: 0)] += 1`
refuses, `:1:67`). A `sizeof` operand is walked too but never reaches the walker: the desugarer types the operand and
emits `AilEsizeof qs ty` (`cabs_to_ail.lem` :2425-2440, `AilEsizeof_expr` survives only for a VLA operand, which is
refused earlier); measured: `a[sizeof(i++)] += 1` answers `Specified(1)` on both engines, a control of §4.

Under-approximation, decided [AGENT 2026-10-29] and accepted by the orchestrator: a read of a VOLATILE object inside
the lvalue is NOT counted. Measured on the oracle's Core (`--pp=core`) before deciding: for `volatile int v; v += 2`
the lvalue copy elaborates to `pure(v)` — an address, no access — and only the rvalue copy loads (one
`load('signed int', a_514)`), then one `store`; so the volatile object itself is read once and written once as
6.5.16.2#3 requires. The duplication bites only on loads inside the address computation: for `volatile int i; a[i] +=
2` the Core loads `i` twice (lines 28 and 60 of `proc main`) and `a[i]` once (line 81). Cerberus gives `volatile` no
semantics beyond the qualifier (outside `ctype.lem` it appears only in UB 6.7.3#6 and an implementation-defined
placeholder; no memory-model arm, no event, no concurrency), so the second read is value-identical and verdict-neutral
(two reads never race; a store inside `e1` is refused). Against C17 5.1.2.3#2, which makes a volatile access a side
effect, this is a declared under-approximation (CONTRACT D13, SUPPORTED); the one observable is the WP0 load/store
receipt instrument. The strict reading would have refused every csmith program (derived: 1669 of 1669 contain
`volatile`), which is the operator's standing reason not to refuse where a refusal kills a lot of code
([USER 2026-10-20], paraphrased by the orchestrator).

### 2.2 The mechanism — `error` with the attributed text, not the `?:` arm's `E.record_error_at` [AGENT 2026-10-29, orchestrator ruling]

The charter named the arm's neighbour `E.record_error_at loc "…"` (the GNU `?:` arm, translation.lem :2318-2321;
`translation_effect.lem` :250-257) and asked for its batch rendering to be measured first. Measured on this tree
(`int main(void){ int x = 3; return x ?: 7; }`, `NO_COLOR=1 TERM=dumb`), verbatim:

```text
$ main.exe --runtime=… --exec --batch --nolibc gnu_cond.c ; rc=125
unsupported: .tmp/probe/gnu_cond.c:1:37:: TODO: elaboration of ?: operator
internal error: .tmp/probe/gnu_cond.c:1:37:: TODO: elaboration of ?: operator
cerberus: internal error, uncaught exception:
          Failure("internal error: .tmp/probe/gnu_cond.c:1:37:: TODO: elaboration of ?: operator")
$ LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --runtime=… gnu_cond.json ; rc=134
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: .tmp/probe/gnu_cond.c:1:37:: TODO: elaboration of ?: operator
```

The text after the location prefix is byte-identical on both engines (the prefix is `Loc.stringFromLocation
(Loc.with_cursor loc)` followed by `": "`, hence the `::`); the oracle alone prints the `unsupported:` line
(`CerbDebug.print_unsupported` is the declared no-op, Z2-U-01); `scripts/test_exec.sh` classes the row `CERB_SKIP
(exit 125)`. So far the charter's measurement. But the mechanism has a hole the charter did not weigh, which this
file's own 2026-10-18 fuel declares record (translation.lem :4601-4605): the constant-expression mini-run
(`mini_pipeline.lem:157`) runs the elaboration with plain `runStateM`, not `runStateM_errors`, so a recorded error is
DISCARDED there and the arm's placeholder Core executed. Measured on the `?:` precedent in constant-expression
positions (oracle `--exec --batch --nolibc`; the Lean engine prints the same `PANIC … <text>` for each, exit 134):

```text
enum { E = 3 ?: 4 }:               unsupported: …h1_enum_gnu_cond.c:1:14:: TODO: elaboration of ?: operator
                                   internal error: PEcase, mismatched ==> [.tmp/probe/hole/h1_enum_gnu_cond.c:1:12-18 (cursor: 1:14)]Unit      rc=125
case (3 ?: 4):                     unsupported: …h2_case_gnu_cond.c:1:35:: TODO: elaboration of ?: operator
                                   internal error: PEcase, mismatched ==> [.tmp/probe/hole/h2_case_gnu_cond.c:1:35-43]Unit                    rc=125
_Static_assert((3 ?: 4) == 3, ""): unsupported: …h3_static_assert_gnu_cond.c:1:16:: TODO: elaboration of ?: operator
                                   internal error: TODO error: the driver found less/more than one active execution     rc=125
int b[(3 ?: 4)]:                   unsupported: …h5_array_size_gnu_cond.c:1:23:: TODO: elaboration of ?: operator
                                   internal error: PEcase, mismatched ==> [.tmp/probe/hole/h5_array_size_gnu_cond.c:1:21-32]Unit             rc=125
```

(a `static int g = (3 ?: 4);` initializer is a 6.7.9#4 constraint violation before it, exit 1.) The refusal is
recorded, discarded, and an unrelated secondary crash is raised: a crash on both engines, never a silent answer, but
not the declared stop. A compound assignment reaches that run point: with globals `int a[2]; int i;`, the label
`case (a[i++] += 1):` died before this change with `internal error: TODO error: the driver found less/more than one
active execution` (rc 125) — the duplicated elaboration raced inside the mini-run (the enum, static-initializer,
`_Static_assert` and VLA positions are rejected before it: `expression is not an integer constant expression`,
`UB204_illtyped_Static_assert`, `variable length array type`). The orchestrator ruled for the D11/D12 mechanism: a
pure Lem `error` whose text carries the same location prefix, undiscardable on every path (the 2026-10-18 declares in
this file chose "refuse directly, independently of the run point" for the same reason). After the change the label
refuses with the attributed text: `internal error: …h10_case_compound_globals.c:2:35:: Translation.translate_expression:
refused - compound assignment …`. The `?:` hole itself is not fixed here (an upstream finding; TODO.md, tray 61 note).

Consequence for `scripts/observations.py`: with `error` the oracle's stderr begins with `internal error: <text>`, the
form `failure_message` already recognises (`InternalError` under the litmus/immaculate policies, symmetric with the
Lean PANIC), so no admission and no plant are needed. Under `record_error_at` they would have been: the `unsupported:`
line comes first and `failure_message` returns None for it, so the PNVI and immaculate lanes would have read the
oracle capture as `INVALID` (`fatal engine diagnostic; no completed observation`) against a Lean legacy `CRASH` — nothing
admits that line today and no lane corpus contains a GNU `?:` (grep over `tests/` minus csmith/gcc-torture/parity-probes
and `lean_frontend/corpus`: comments only, in `tests/noodle-probes`).

### 2.3 The arm and the text

```lem
      | A.AilEcompoundAssign e1 aop e2 ->
          (* TODO: this elaboration is wrong because it duplicates any side-effect in E1 *)
          (* TODO: and this is duplicating facts about the typing of Ail arithmetic binary operators *)
          (* FORK REFUSAL (survey cluster B, tray 61, 2026-10-29): a side effect inside e1 would
             run twice below; see compound_assign_lhs_has_side_effect. *)
          if compound_assign_lhs_has_side_effect e1 then
            error (compound_assign_refusal loc)
          else
          let (e1_rvalue, arith_gty) = match (e1, e2) with …   (* upstream's arm, untouched *)
```

`compound_assign_refusal loc` = `Loc.stringFromLocation (Loc.with_cursor loc) ^ ": " ^ <text>`; the cursor of a
compound assignment is its operator (`a[i++] += 5` at column 46 refuses at `:1:53`, the `+=`). The text (ASCII, one
line; both engines carry it byte for byte after the `internal error: ` / `PANIC at …: ` prefix):

```text
<file>:<line>:<col>:: Translation.translate_expression: refused - compound assignment whose left operand contains a side effect (an increment or decrement, an assignment, a function call, a comma, a va_arg, a statement expression or a compound literal anywhere inside the lvalue; C17 6.5.16#3 sequences the update after both value computations and 6.5.16.2#3 evaluates the lvalue E1 only once); upstream elaborates E1 op= E2 as E1 = E1 op E2 with E1 elaborated twice, under its own 'TODO: this elaboration is wrong because it duplicates any side-effect in E1' (translation.lem b9aeedcb4 :2506), so the lvalue's side effect runs twice (a call in the lvalue is called twice, a wrong value) or a false UB035_unsequenced_race is reported (the ++/--/comma forms) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)
```

Generated: OCaml `Cerb_debug.error (compound_assign_refusal loc1)` (`ocaml_frontend/generated/translation.ml`, the arm
hunk at :2629; `internal error: <text>` on stderr, then `Failure("internal error: <text>")` uncaught, exit 125); Lean
`(failwithI (compound_assign_refusal loc1) : elab_state → (generic_expr Unit Unit sym × elab_state))`
(`lean_frontend/generated/Translation.lean`, the arm at :3671; Lean is strict, the arm's value is the saturated
`failwithI`, it panics when the arm is taken; abort under `LEAN_ABORT_ON_PANIC=1`, exit 134). The generated trees
differ from the mainline's in exactly `translation.ml` (two hunks: the walker/helper, 108 lines; the arm, 5 lines) and
`Translation.lean` (three hunks: the walker, its wrapper and `_zero` lemma and the text helper; the arm; the fuel
declare's comment).

### 2.4 The walker's Lean form [AGENT 2026-10-29, accepted]

The generated `Translation` module is partial-free by design (`docs/2026-10-18_translation-fuel-record.md`: zero
`partial def`), so a bare `let rec` — which the backend would emit `partial` — is not acceptable; the walker carries
`declare {lean} fuel val compound_assign_lhs_has_side_effect = \`failwithI CerbFuel.fuelExhaustedMsg\``, the declared
form of its caller `translate_expression`. No measure, no obligation in `Translation_lemMeasureProofs.lean`, no proof
module touched, no kernel replay owed. The fuel-forms census (`scripts/check_fuel_forms.sh`, run on the M1 tree)
classes it as its caller is classed — the instrument's rows, verbatim (`rhs-consts` truncated):

```text
FUEL_FORM	compound_assign_lhs_has_side_effect_lemFuel	AMBIENT	no/front	zero=compound_assign_lhs_has_side_effect_lemFuel_zero rhs-consts=[failwithI, Bool, instInhabitedBool, CerbFuel.fuelExhaustedMsg]
FUEL_FORM	translate_expression_lemFuel	AMBIENT	no/front	zero=translate_expression_lemFuel_zero rhs-consts=[failwithI, elab_state, Prod, generic_expr, Unit, sym, Pi.instInhabited, instInhabitedProd, in…
FUEL_FORMS_SUMMARY	workers=88	measured=67	measured_under_hyp=13	absorbing=13	ambient_reachable=0	ambient_unreachable=8	closure_size=11538
check_fuel_forms: forms partition OK (67 MEASURED + 13 ABSORBING + 0 ambient-reachable + 8 ambient-unreachable = 88 fuel'd workers)
```

The move, as measured: workers 87 → 88, ambient-unreachable 7 → 8, ABSORBING 13 → 13 — the ruling's "absorbing" named
the declare's form (kill at fuel zero); the gate files that form, for a frontend worker outside the drive cone, as
AMBIENT/unreachable, exactly as `translate_expression` and `translate_stmt`.

## 3. Measurement before committing (every corpus the lanes walk, on the new oracle)

### 3.1 The exact run (the new oracle through elaboration: `--pp=core`, one process per file)

The refusal fires in `translate`, which `--pp=core` runs (checked: `ca-02` under `--pp=core` prints the `internal
error:` line and the `Failure`). The instrument (`.tmp/sweep/run_sweep.sh`, deleted at slice end) ran every `.c`
under `tests/` (csmith apart), `lean_frontend/corpus` and the CN corpus `deps/cn/tests/cn` with `--nolibc --pp=core`,
then the 1669 csmith programs through the lane's own materialization (`tests/csmith/{small_int_arith,small_arrays,
small_mix}` prefixed into a stage with the `csmith_cerberus.h` shim, as `scripts/test_csmith_corpus.sh` does), then
the files that had exited 1 again WITHOUT `--nolibc` (the ci-sweep's libc mode), verbatim:

```text
MAIN (tests/ + lean_frontend/corpus + deps/cn/tests/cn): files=5591 refused=10 exits: 0=3423 1=2094 124=2 125=72
CSMITH (materialized): files=1669 refused=0 exits: 0=1665 1=1 125=3
LIBC-MODE RE-RUN of the --nolibc exit-1 files: files=2094 refused=0 exits: 1=2094
```

The ten: the nine side-effecting survey probes (`tests/parity-probes/uncertainty/B-compound-assignment/`, not a gate)
and `tests/gcc-torture/breakdown/success/990222-1.c`. The 2094 exit-1 files fail identically in libc mode, and the
first diagnostic of every one is a PRE-translation failure (derived classes of the 2094, libc mode): 1033 `error:
unexpected token` (GNU syntax), 314 `use of undeclared identifier` (`abort`, `exit`, …), 277 `constraint violation`,
137 `fatal error: cerberus.h` (the header is beside the file only in `tests/gcc-torture/` and
`breakdown/success/`; the lanes meet the same failure), 122 `feature not yet supported`, 69 `fatal error: linux.h`
(`tests/bmc`), 49 desugar-time `undefined behaviour`, 35 K&R declarations, the rest other missing headers and
preprocessor `#error`s — so no refusal can hide behind them. The 65 exit-125 files other than the ten are
pre-existing crash classes (39 of them D12's anonymous-member refusals — the survey's cluster-A probes and the retired
shapes —, 12 bare uncaught exceptions, 7 `Translation called on Ail program with an invalid node`, 2
`Desugaring_init.lookup_struct_members`, 2 `get_current_return_type Nothing`, 2 `AilTypesAux.is_complete`, 1
`annotate_definition: symbol not found`); a crash class is `CERB_SKIP`/`CRASH` in every lane whatever its text, so a
refusal behind one of them could move no row. The two exit-124s are the mem-scale probes
`tests/mem-scale-probes/probes/{a_zero_global,b_zero_local}_10000000.c` (not a gate).

The deps corpora with their lanes' own arguments (the same instrument, one process per TU), verbatim:

```text
libxml2 uri_harness.c            rc=0   - (0s)
libxml2 uri.c                    rc=1   - (1s)
    /home/dev/projects/cerberus-lean-proj/deps/libxml2/include/libxml/uri.h:66:3: error: duplicate external symbol: xmlBuildRelativeURI
libxml2 xmlstring.c              rc=0   - (0s)
libxml2 xmlmemory.c              rc=0   - (0s)
libxml2 globals.c                rc=0   - (1s)
libxml2 chvalid.c                rc=0   - (0s)
pkvm pkvm_alloc.c             rc=0   - (0s)
pkvm pkvm_free.c              rc=0   - (0s)
pkvm pkvm_init.c              rc=0   - (0s)
pkvm pkvm_split_merge.c       rc=0   - (0s)
pkvm page_alloc_census.c      rc=0   - (1s)
uri lane 5-TU --pp=core rc=0
```

(libxml2 with `scripts/libxml2_prep.sh uri.c`'s arguments — `-I tests/libxml2/config -I <libxml2>/include -I
<libxml2> -D__inline=inline`; `uri.c` alone trips a link-stage duplicate when run standalone, so the uri lane's own
five-TU invocation `uri_harness.c uri.c xmlstring.c xmlmemory.c globals.c` was run through elaboration: rc 0, no
refusal; pKVM with the PNVI lane's `--nostdinc -I <case study> -I tests/census/pkvm`, `page_alloc_census.c` derived
by `tests/census/pkvm/derive_pool_init.py`.) `dune build cerberus.install` restaged `libc.co` under the new
elaborator (rc 0): the libc has no refused form.

### 3.2 Where the one program outside the probe directory lives

| program | lane | disposition |
|---|---|---|
| `tests/gcc-torture/breakdown/success/990222-1.c` — `while ((*--ptr += 1) > '9') *ptr = '0';`, a pre-decrement inside the lvalue | `test_ci_sweep.sh` `torture_success` (Tier C scoreboard; NO baseline; committed TSV `tests/ci_sweep/results/torture_success.tsv:509`, verbatim: `torture_success	tests/gcc-torture/breakdown/success/990222-1.c	UB_MATCH	UB:UB035_unsequenced_race` — a false UB both engines agreed on) | moves UB_MATCH → both engines refuse at the scoreboard's next deliberate re-record (LADDER: the TSVs move only by a deliberate re-record); named in TODO.md; its `execute/` twin is walked by no lane |

The survey's expectation (0 gated rows move) holds: no baselined row of Tier A rows 3/4/4b/4c/5, Tier B, the
immaculate, PNVI, verify, multi-TU, CN, libxml2 or csmith lanes meets the refusal, so nothing is retired and
`scripts/upstream_oracle_differences.json` gains NO row (the pristine lane, Tier B row 10, walks none of the
affected files: D12 §3.2's list). The survey's "2 gcc-torture files in the pristine lanes" (its §3 table names
`920428-1.c` — `a[*s++]|=1` — and `pr37573.c` — `*p++ ^= foo (&s)` — with their breakdown copies) were a grep
estimate over scoreboard rows (the pristine lane never walks gcc-torture): in the exact run neither reaches the arm
in either mode — the `execute/` copies fail to parse (`error: unexpected token`, GNU/K&R syntax) and the
`breakdown/fail/{compound_assigments,stack-overflow}/` copies have no `cerberus.h` beside them (`fatal error:
cerberus.h`), and both scoreboard rows already read `CERB_REJECT` (`torture_fail.tsv:2`, `:21`) — while `990222-1.c`,
which the grep missed (`*--ptr += 1`, a pre-decrement rather than a post-increment), is the one gcc-torture program
that reaches elaboration.

## 4. Witnesses and plants — `scripts/check_compound_assignment_refusal.sh` (row 1, wired into `test_unit.sh`)

30 cases, nolibc, fail-closed, the D12 shape with one strengthening: every witness pins its WHOLE text INCLUDING the
location — the script carries each witness's `line:col` (`WITNESS_LOCS`, the cursor on the operator), and the oracle
must die with exactly `Failure("internal error: <file>:<line>:<col>:: <HEAD><TAIL>")` (exit 125, `uncaught
exception`), `--cabs-json` must succeed, Lean must abort (exit 134) with a `PANIC` line carrying the same whole text,
and the two texts (from the file name to the end of the line) must be byte-identical. A control requires Lean = oracle
(exit code, first verdict line); the gap control both engines' pre-existing rejection (exit 1, their own texts).

- 18 witnesses: the survey's `ca-02/03/04/05/06`, `cb-02/03/04/08` (their texts verbatim; gcc's value and the
  engines' pre-refusal answer in the label); this slice's own shapes — a pre-increment in the subscript (`-=`), a call
  two levels deep (`*=`), a comma in a member's subscript (`/=`), a compound literal lvalue (`%=`), an assignment in a
  cast's operand (`&=`), `va_arg` inside the lvalue, a `_Generic` controlling expression (walked: the
  over-approximation), the `^=` and `>>=` operators — so every `op=` appears at least once.
- 11 controls: `ca-01` (5), `cb-01` (11, a side effect in the RIGHT operand only), `cb-06` (15, plain `=`), `cb-07`
  (11, `++` on the lvalue itself), `*p += 1` (2), `s.v |= 4` (5), `a[f] <<= 2` with `f` a variable (4), a side effect
  only in e2 (12), a VOLATILE object as the lvalue (3), a volatile read inside the address computation (2; NOT counted,
  §2.1), a `sizeof` operand (1; does not survive typing, §2.1).
- 1 gap control: the survey's `cb-05` (`s[i++].bf += 2` on a bit-field): oracle `feature not yet supported: bit-fields`,
  Lean `Error {msg: "desugaring failed at …"}`, both exit 1, unchanged.
- Plants (`--selftest`), each asserting its EXACT failure count and the required cases, derived before the run:
  `answer` (both engines answer `Specified(24)` — cb-02's pre-fix doubled-call value, chosen because no control
  expects it — on every `w_*` program) 36 = 18 × 2; `lean-answer` 30 = 18 + 11 + 1; `refuse-all` (both stubs refuse
  everything with the text, each stub looking its location up from the file name as the engines read it from the
  Ail; a control gets `1:1` and fails anyway) 12 = 11 + 1; `lean-no-abort` 19 = 18 + 1; `lean-other-text` 18. The
  first derivation said 12 controls and 31/13 — the first selftest run caught it (`lean-answer` caught 30, expected
  exactly 31): the script's own plant found the worker's miscount; corrected to 11 controls before the commit.

Verbatim, `w_ca02_idx_postinc.c` (the survey's ca-02) on this tree's engines, run from the script's scratch directory
(the oracle's backtrace and the Lean backtrace lines omitted):

```text
$ main.exe --runtime=… --exec --batch --nolibc w_ca02_idx_postinc.c ; rc=125
internal error: w_ca02_idx_postinc.c:1:53:: Translation.translate_expression: refused - compound assignment whose left operand contains a side effect (an increment or decrement, an assignment, a function call, a comma, a va_arg, a statement expression or a compound literal anywhere inside the lvalue; C17 6.5.16#3 sequences the update after both value computations and 6.5.16.2#3 evaluates the lvalue E1 only once); upstream elaborates E1 op= E2 as E1 = E1 op E2 with E1 elaborated twice, under its own 'TODO: this elaboration is wrong because it duplicates any side-effect in E1' (translation.lem b9aeedcb4 :2506), so the lvalue's side effect runs twice (a call in the lvalue is called twice, a wrong value) or a false UB035_unsequenced_race is reported (the ++/--/comma forms) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)
cerberus: internal error, uncaught exception:
          Failure("internal error: w_ca02_idx_postinc.c:1:53:: Translation.translate_expression: refused - compound assignment whose left operand contains a side effect (…) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)")
$ LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --runtime=… w_ca02_idx_postinc.c.json ; rc=134
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: w_ca02_idx_postinc.c:1:53:: Translation.translate_expression: refused - compound assignment whose left operand contains a side effect (…) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)
```

(the `(…)` elisions in the two shorter lines stand for the same text as the first; the script compares the whole
lines.) Script result, verbatim:

```text
check_compound_assignment_refusal: selftest plant 'answer' caught: 36 failing witness(es) (= expected 36; incl. the required witnesses)
check_compound_assignment_refusal: selftest plant 'lean-answer' caught: 30 failing witness(es) (= expected 30; incl. the required witnesses)
check_compound_assignment_refusal: selftest plant 'refuse-all' caught: 12 failing witness(es) (= expected 12; incl. the required witnesses)
check_compound_assignment_refusal: selftest plant 'lean-no-abort' caught: 19 failing witness(es) (= expected 19; incl. the required witnesses)
check_compound_assignment_refusal: selftest plant 'lean-other-text' caught: 18 failing witness(es) (= expected 18; incl. the required witnesses)
check_compound_assignment_refusal: OK (30 cases: 18 compound assignments whose left operand contains a side effect (the survey's post-increment, pointer post-increment, call-as-lvalue, shifted and or'ed member, call-in-subscript, pre-decrement, post-incremented pointer member and comma-in-subscript shapes; a pre-increment, a call two levels deep, a comma in a member's subscript, a compound literal lvalue, an assignment in a cast's operand, va_arg, a _Generic controlling expression, and the ^= and >>= operators — every op= at least once) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts pinned whole, location included; 11 controls agree with the oracle (a plain subscript, a side effect in the right operand only, plain = and ++ with a post-incremented subscript, *p += 1, s.v |= 4, a[f] <<= 2, a side effect only in e2, a volatile object, a volatile read in the address computation (not counted), a sizeof operand); the bit-field rejection cb-05 is unchanged on both)
```

## 5. Register entries

- **Fork-drift manifest (`scripts/fork_drift_manifest.txt`):** exactly the two charter rows moved — `[source-content]`
  `frontend/model/translation.lem` `e99043b7… → 366ce0ab…`, `[expected-semantic]` `translation.ml` `32d184cc… →
  aec7ba96…` — single-row edits with a dated header NOTE (`fix/compound-assignment-refusal, 2026-10-29`), no
  `--refresh`. Gate + self-test, verbatim: `check_fork_content: OK — 93 source files content/mode-pinned`;
  `check_fork_drift: OK — layer 1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2:
  32 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin
  e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))`;
  `check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls;
  S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14
  duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate
  green)`; `check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3
  lake-manifests rev+inputRev, README pin command)`. The 32 differing files are the same 32 as before
  (`translation.ml` was already a delta; its hash moved).
- **Failure-reach register (`scripts/failure_reach_register.txt`): no new row.** The new `failwithI` site is in the
  generated `Translation.translate_expression`, a frontend declaration outside the register's closure (the drive
  cone's `exec_dependency`; `translate` is in `frontEntries` — the D11/D12 classification). The gate on the changed
  tree, verbatim: `check_failure_reach: OK (240 pure failure sites = the 240 register rows exactly (238 in the exec
  dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions);
  position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=44 UNKNOWN=22; every row
  sealed; tally line consistent)`. Reachability from C is witnessed by the script (18 programs).
- **Fuel forms:** §2.4 (workers 87 → 88, ambient-unreachable 7 → 8; `scripts/fuel_forms_pending.txt` and
  `scripts/fuel_hypotheses.txt` untouched).
- **lem-sync stamps** re-derived by `make prelude-src lean-prelude-src` (`lean_frontend/lem_sync.sha256`: src
  `e94e03a7…`, gen `6ec817b6…`); `check_handwritten_sync: OK (56 hand-written files byte-identical to
  lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)`.
- **`scripts/upstream_oracle_differences.json`: no row** (§3.2). **No corpus control retired**; no baseline touched.
- **Outcome-protocol migration map** (`docs/2026-10-20_outcome-protocol-register-migration.tsv`): one UNMIGRATED
  inventory line for the new site under the same shared-model mapping mover as D11/D12's (protocol status, not a
  register row); its summary line counts five.
- `lean_frontend/CONTRACT.md`: a §3 row, the three-unmigrated-sites sentence, §4.1's witness list, decision **D13**,
  D6's floating-profile sentence (§8). `VALIDATION.md`: §3(c) bullet, the fork ≠ pristine inventory entry, the §6
  gate-table row, the outcome-protocol sentence. `SUPPORTED.md` Domain row (the refusal, the volatile clause, the
  floating profile). `scripts/LADDER.md` row 1. `scripts/test_unit.sh` runs
  `check_compound_assignment_refusal.sh --selftest` after the anonymous-members script. Tray 61 ("Fork-ahead
  refusal" paragraph, the stale line numbers corrected, the `?:` related-finding note; status Draft stays — it
  reports upstream and proposes the one-binding elaboration), the INDEX row. Consumer note
  `docs/2026-10-29_consumer-note-cerberus-caesium-compound-assignment-refusal.md`. `TODO.md`: this item DONE with
  the scoreboard row named and its TSV line quoted; the `_Bool`-from-fractional-float item DONE (§8); the `?:`
  mini-run hole as a new follow-up line; the survey section's header no longer says the items are queued. The D12
  record's §8 corrected (§8 here).

## 6. Gates

Builds (worktree primed on Lean 4.35.0 / lem `e6d8db5`; `scripts/ce`, `CERB_MEM_MAX=32G`): after the `.lem` edit
`make prelude-src lean-prelude-src` (rc 0; stamps `check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src
e94e03a7…, gen 6ec817b6…)`), `dune build backend/driver/main.exe cerberus-lib.install`, `dune install --prefix
_build/local-install cerberus-lib`, `dune build cerberus.install` (rc 0 each; `libc.co` restaged), `capped lake build
CerberusLean cerberus-lean`: `Build completed successfully (408 jobs).`; freshness stamps `check_driver_fresh:
recorded oracle stamp (bin 4eb1babb…, src 3e5af216…)`, `… recorded lean stamp (bin dc87ba1c…, src c1ba674a…)`.

Focused gates on the M1 tree (`0991eb840`): §5 (sync, fork-drift + self-test, pin sites, failure reach), §2.4 (fuel
forms), §3 (the measurement), the one-file differentials on the 14 probes (rc 0), verbatim:

```text
[1/14] MATCH ca-01-ctl: VAL:{value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}
[2/14] CERB_SKIP ca-02-idx-postinc (exit 125)
[3/14] CERB_SKIP ca-03-ptr-postinc (exit 125)
[4/14] CERB_SKIP ca-04-call-lvalue (exit 125)
[5/14] CERB_SKIP ca-05-shift-postinc (exit 125)
[6/14] CERB_SKIP ca-06-member-postinc (exit 125)
[7/14] MATCH cb-01-rhs-call-once: VAL:{value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}|VAL:{value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}
[8/14] CERB_SKIP cb-02-lhs-call-index (exit 125)
[9/14] CERB_SKIP cb-03-predec (exit 125)
[10/14] CERB_SKIP cb-04-ptr-deref-postinc-struct (exit 125)
[11/14] CERB_SKIP cb-05-bitfield-postinc (exit 1)
[12/14] MATCH cb-06-plain-eq-postinc-ctl: VAL:{value: "Specified(15)", stdout: "", stderr: "", blocked: "false"}
[13/14] MATCH cb-07-postinc-on-lvalue-ctl: VAL:{value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}
[14/14] CERB_SKIP cb-08-comma-lhs (exit 125)
SUMMARY: total=14 match=4 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=10 cerb_floor=0 cerb_inconsistent=0
```

(the nine side-effecting probes refuse on both engines, oracle exit 125 / Lean abort 134, hence `CERB_SKIP`; the
four controls `MATCH`; `cb-05` unchanged.) The outcome codec and the stop-policy plant batteries, unchanged by this
slice but run as the charter asks (last lines verbatim): `python3 scripts/test_stops.py --lean-bin
lean_frontend/.lake/build/bin/stop-test`: `Ran 26 tests in 2.421s` / `OK`; `python3 scripts/test_observations.py`:
`Ran 26 tests in 0.283s` / `OK`; `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both
lanes; missing record→harness error)`; `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED
witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap
class; native exit(137) still compared; no MATCH anywhere)`; `test_fuel_plant: ALL PLANTS OK (FUEL classification
live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; real translation at --fuel 1 reads FUEL:panic,
real execution at --fuel 128 reads FUEL:kill, both at the default MATCH; --fuel 0/non-numeral/out-of-position/missing
refused)`; `test_failstop_plant: PASS (11 class and rejection checks)`. (A first `test_stops.py` run against the
`cerberus-lean` driver instead of row 1's `stop-test` executable reported 7 failures — the driver refusing without a
runtime — a harness-invocation error of the worker's, not a finding.)

### 6.1 Tier A on the M1 tree (orchestrator-run) — RED on one gate, fixed by M1b

Run by the orchestrator on `0991eb840` (`scripts/ce python3 scripts/release.py --mode fast`, evidence
`.tmp/release/ca-fast-m1-20261029T010804Z`, 01:08:04 to 01:35:14 UTC, start load 2.33), verbatim:

```text
fast: failed; 19/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
release rc=1
```

A2 to A15 PASSED; A1 (574.2 s) FAILED in `test_unit.sh`'s fuel-parametricity pin set, verbatim from A1/stdout:

```text
gen_fuel_parametricity: FAIL — fuel'd wrapper(s) in the tree with NO parametricity pin in TotalityProofTest.lean: compound_assign_lhs_has_side_effect
  regenerate Part 1: scripts/gen_fuel_parametricity.py --emit
test_unit: fuel-parametricity pin-set SELFTEST FAILED
```

Why: M1's walker is a new AMBIENT fuel'd wrapper (§2.4), and every such wrapper carries a kernel-checked
`@f ⟨n⟩ = f_lemFuel n` pin in `lean_frontend/test/Unit/TotalityProofTest.lean` Part 1, which `gen_fuel_parametricity.py
--check` pins as a SET both directions; the worker's focused gates had not included that check. **M1b** (`9832fe79d`,
one concern per commit): the Part 1 block regenerated with `--emit` — the diff is the one new pin
`example {a : Type} (n : Nat) : @compound_assign_lhs_has_side_effect a ⟨n⟩ = @compound_assign_lhs_has_side_effect_lemFuel a n := rfl`
plus the block's count comment (16 → 17) and the header's running count — and the selftest's two unplanted-control
literals in `gen_fuel_parametricity.py` moved 16 → 17 (the precedent `17eeb7708` did the same for 14 → 16; without
it the controls fail at rc 0 on a correct `OK (17 …)`). Verified, verbatim: `capped lake build totality-proof-test`:
`Build completed successfully (271 jobs).`; the executable: `TotalityProofTest: all proofs kernel-checked at compile
time (fuel parametricity of every fuel'd def + symbolic execution)`; `gen_fuel_parametricity: OK (17 ambient fuel
wrappers in the generated tree = the 17 pins of TotalityProofTest.lean Part 1, both directions)`;
`gen_fuel_parametricity: SELFTEST OK (6 --check plants + 1 --emit plant with the declared FAIL, both unplanted
controls OK, real tree OK)` (G1 new multi-line wrapper, G2/G3/G6/G7 strict-pattern shapes, G8 block comment, E1
instance binder, each with its declared FAIL; both controls rc 0 at 17). The kernel-replay gate of [USER 2026-10-18]
still does not apply: the pin is an `example` in a test executable, not a proof module of the semantics.

Also checked on request: A1/stderr line 115, `OBSERVATION ERROR: unknown or malformed stdout record: b'Defined
{value: "Specified(0)", stdout: "'`, is `test_exec.sh --selftest`'s own plant E7 ("no token from a truncated Defined
line", `scripts/test_exec.sh:335`: the verdict extractor is fed exactly that truncated line and must yield no token;
the extractor's complaint is printed on every run of the selftest, green runs included). Not produced by this slice.

Focused re-checks on the M2 tree: the witness script and its self-test (§4).

### 6.2 Tier A on the M2 tree (orchestrator-run)

Run by the orchestrator on `cd6047f43` (`scripts/ce python3 scripts/release.py --mode fast`, evidence
`.tmp/release/ca-fast-m2-20261029T014156Z`, 01:41:56 to 02:15:32 UTC, start load 1.67). `summary.txt`, verbatim:

```text
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

All 20 commands PASSED (the evidence's `report.json` lanes: A1 passed 960.589 s; A2 passed 30.476 s; A3 passed 77.514 s; A4 passed 24.616 s; A4b passed 26.219 s; A4c passed 3.132 s; A5 passed 94.243 s; A6 passed 4.085 s; A6b passed 3.684 s; A7 passed 10.395 s; A8 passed 8.793 s; A9 passed 16.654 s; A10 passed 17.053 s; A11 passed 62.472 s; A12.1 passed 5.187 s; A12.2 passed 4.686 s; A13 passed 1.681 s; A14.1 passed 116.755 s; A14.2 passed 151.092 s; A15 passed 395.675 s). A1 (row 1), verbatim lines from `A1/stdout`:

```text
Total: 21 passed, 0 failed
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
gen_fuel_parametricity: OK (17 ambient fuel wrappers in the generated tree = the 17 pins of TotalityProofTest.lean Part 1, both directions)
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 8 ambient unreachable from the drive cone)
check_failure_reach: OK (240 pure failure sites = the 240 register rows exactly (238 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 93 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_anonymous_members_refusal: OK (42 cases: 29 anonymous struct/union members (the survey's brace-elision, anonymous-first, array, sizeof/offsetof/aliasing/copy, anonymous-struct-in-union, padding and false-UB shapes; the designated, anonymous-struct-sizeof, retired coverage control struct-008, retired union-initializer control and parity-probe shapes that answered right by name lookup alone; nested members, a typedef'd tagless specifier, block scope, a compound literal, _Alignas, an unused type, sizeof only) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts naming the member's kind; 10 controls with NAMED members agree with the oracle (a named union elided/braced/sizeof/aliased, a named single-member union, a named struct inside a struct, a union with named members only, a plain union, a tagless type with a declarator, a tagless file-scope object); the tagged-no-declarator, typedef'd-tagged and int; constraint violations are unchanged on both)
check_compound_assignment_refusal: OK (30 cases: 18 compound assignments whose left operand contains a side effect (the survey's post-increment, pointer post-increment, call-as-lvalue, shifted and or'ed member, call-in-subscript, pre-decrement, post-incremented pointer member and comma-in-subscript shapes; a pre-increment, a call two levels deep, a comma in a member's subscript, a compound literal lvalue, an assignment in a cast's operand, va_arg, a _Generic controlling expression, and the ^= and >>= operators — every op= at least once) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts pinned whole, location included; 11 controls agree with the oracle (a plain subscript, a side effect in the right operand only, plain = and ++ with a post-incremented subscript, *p += 1, s.v |= 4, a[f] <<= 2, a side effect only in e2, a volatile object, a volatile read in the address computation (not counted), a sizeof operand); the bit-field rejection cb-05 is unchanged on both)
```

(A1's `Total: 21 passed, 0 failed` is the 21 unit executables; the gate lines above include the pin set at 17, the
fuel-forms census at 88, the failure-reach register unchanged at 240, the fork-drift layers, and the new witness
script's OK line.) The full battery on the M3 tip (§6.3) is the orchestrator's; its lines are appended by the close-out
commit after the run.

### 6.3 The full battery at close-out (appended after the run)

Not yet run at this commit: the orchestrator runs Tier A and then the full battery on the M3 tip; their verbatim
lines are appended here by the close-out commit, which touches this section only.


## 7. Not done / open

- The ci-sweep scoreboard TSV (`tests/ci_sweep/results/torture_success.tsv:509`) is not re-recorded here (LADDER: the
  TSVs move only by a deliberate re-record); the row is named in §3.2 and TODO.md.
- The GNU `?:` arm's own `record_error_at` is left as upstream has it: in a constant-expression position the mini-run
  discards it and both engines crash with an unrelated text (§2.2; measured, never a wrong answer). Registered as a
  TODO follow-up (a one-arm `error`, or `runStateM_errors` in the mini-run) and as a related note in tray 61.
- The text is pre-envelope (a legacy stop under the outcome protocol, UNMIGRATED beside D11/D12); the shared-model
  mapping mover of structural-outcome WP2 migrates the three together. The batch-rendering follow-up option of the
  D12 record (§7 there) applies to D13 equally.
- Tray 61 stays Draft, with its "Fork-ahead refusal" paragraph; no submission (the operator's network window).
- The survey record's cluster-B table (dated 2026-10-20) is left as the pre-refusal measurement.
- Not refused, by decision (§2.1): a volatile read inside the lvalue's address computation. Not reachable (§2.1): a
  `sizeof` operand's side effect.

## 8. Ride-alongs

### 8.1 Ride-along (a): the floating profile stated (survey §2.4, tray 32; documentation only, no code)

Measured 2026-10-29 on both engines (`--exec --batch --nolibc`; the Lean engine on the exported Cabs JSON), identical
lines. `.tmp/float/profile.c` (each digit one fact; `sf*1000000 + sd*100000 + sl*10000 + al*1000 + f53*100 + l53*10
+ d53`, plus 5000000 if `_Alignof(double)` or `_Alignof(float)` is not 8):

```text
Defined {value: "Specified(8888111)", stdout: "", stderr: "", blocked: "false"}
```

i.e. `sizeof(float) == sizeof(double) == sizeof(long double) == 8`, `_Alignof(long double) == 8` (and `_Alignof(double)
== _Alignof(float) == 8`), `(int)(float)16777217 == 16777217` (a `float` carries 53 bits), `1.0L + 1e-17L == 1.0L` (no
64-bit significand: `long double` is binary64 too), `1.0 + 1e-17 == 1.0`. The shipped `runtime/libc/include/float.h`
(`#include <float.h>`; `FLT_MANT_DIG*10000 + DBL_MANT_DIG*100 + LDBL_MANT_DIG`):

```text
Defined {value: "Specified(245364)", stdout: "", stderr: "", blocked: "false"}
```

i.e. `FLT_MANT_DIG 24`, `DBL_MANT_DIG 53`, `LDBL_MANT_DIG 64` against 53-bit values; and `FLT_EPSILON` is not defined
(`#ifdef FLT_EPSILON` → `Specified(0)` on both). Stated in SUPPORTED.md's Domain row and CONTRACT D6; tray 32 already
carries the `FLT_MANT_DIG` contradiction and gains the `LDBL_MANT_DIG 64` / absent `FLT_EPSILON` facts; the header is
NOT edited (an intended gap, the operator's call).

### 8.2 Ride-along (b): the D12 record's §8, corrected

`docs/2026-10-26_anonymous-members-refusal-record.md` §8 said the 15-minute battery waiter's processes were gone by
morning and presumed the session's background command had been reaped. It had not: the waiter stayed alive for 26
hours, blocked, because its running-battery check counted any shell whose command text contained the runner's name
(its own wrapper, the other slice's gate shells, later the orchestrator's runs), and it was killed on 2026-10-28. The
paragraph now says so, tagged [AGENT 2026-10-28, orchestrator].

### 8.3 TODO closures carried here

The `_Bool`-from-fractional-float item (survey §2.3, tray 15) is marked DONE: upstream `3230aa494` was backported as
checkpoint I0b of the inner_arg_temps arc ([USER 2026-10-21]; `docs/2026-10-21_inner-arg-temps-i0b-record.md`; mainline
`1e7df2ac2`, closed by `9756f6a60`, CI witness `tests/ci/0343-subzero-floating-to-_Bool.c`). Re-measured 2026-10-29 on
both engines: `_Bool b = 0.5; _Bool c = -0.25; return b*10 + c;` → `Defined {value: "Specified(11)", …}` (C17
6.3.1.2#1), where the survey measured 0. The survey section's header no longer says the items are queued behind the
cerberus-caesium deliveries (all three have landed).
