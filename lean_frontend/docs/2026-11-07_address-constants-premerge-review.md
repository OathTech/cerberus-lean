# Pre-merge review: fix/address-constants (d40239e2b, three commits over 1e5f2cbca)

Reviewer: fresh, independent [AGENT 2026-11-07, reviewer]. Worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/address-constants` (built by the worker; not rebuilt);
merge-base upstream `c3ff8c53f`; pristine oracle `deps/cerberus-upstream/_build/default/backend/driver/main.exe`
(read-only); gcc 13.3.0 `-std=c11 -pedantic-errors -O0` the referee. Nothing tracked was edited except this file; no
build, lane, sweep or `release.py` run; scratch `.tmp/review/` (deleted at the end of the review). Reviewed against
the container doc's working practices (upstream's judgement stands; fixes stay semantically uncontroversial; gates
plant-tested; record integrity and provenance), `CONTRACT.md`, `VALIDATION.md`, `scripts/LADDER.md`, the charter and the
record, with the rank review of 2026-11-04 as the shape.

## Verdict

**MERGEABLE AFTER FIXES.** One finding needs an operator ruling plus a document change (P1-1: the fix accepts a
handful of C17 6.6#10 forms that pristine did not accept, and the record and contract D17 say the opposite); two are
pin/record/comment fixes (P2-1, P2-2). No baseline, register, seam, proof or fuel change is needed; the code change is
optional under P1-1 and small if chosen.

What holds up, measured: every arm of the three predicates is one of the forms C17 6.6#3-#9 lists or an unchanged
upstream arm, with the exceptions named in P1-1; every newly REJECTED form (the comma, `&local`/`&param`, `*&g`, a
pointer variable under `*`/`[]`/`->`, `(int *)g`, `(long)g`, `gs.b`, `&tls`) is a 6.7.9#4 constraint violation gcc
rejects, and none is a case upstream decided (upstream's arms carried `TODO: not sure`); the mutual block is well-founded
(every recursive call is on a strict subexpression except the chain `is_address_constant e` → `is_decayed_static_lvalue
e` → `is_lvalue_to_static_object e`, whose next step is a strict subexpression); the generated delta is confined to
`cabs_to_ail.ml` / `Cabs_to_ail.lean` (`diff -rq` of both generated trees against the primary checkout at `1e5f2cbca`:
no other file); `Cabs_to_ail` is outside the totality gate's 22 `EXEC_MODULES` and the allowlist is empty, so the two new
`partial def`s (`is_address_constant`, now recursive, and `is_decayed_static_lvalue`) are not gated; the tray-09 patch
applies to pristine and IS the fork's fix (applied to a copy of pristine's `cabs_to_ail.lem`, the residual difference
from the fork's file is exactly the fork's 24 pre-existing hunks, same shapes, shifted by the fix); the 234 gcc pins are
reproduced byte for byte by an independent gcc run; the 234 pristine pins are reproduced by an independent pristine run;
the witness's five plants fire at their derived counts (35.4 s with the self-test); fork-drift, pin-sites and
failure-reach are green; on all 20 of my own probes the Lean engine prints the oracle's line; no operator quote appears
in the new documents; every judgement carries a tag.

## Findings

### P1-1 — Newly accepted 6.6#10 forms, undisclosed and attributed to upstream (operator ruling + document fix; code change optional)

The charter's M1: accept exactly the forms 6.6#3-#9 list; where a form's status is a judgement call (6.6#10) do NOT
accept it, leave upstream's rejection and record the question. The record §0 (d) states that 6.6#10 forms "keep
upstream's answer in BOTH directions"; CONTRACT D17 lists "the `offsetof` idiom and `(int *)16` accepted as before"
under "Deliberately unchanged, as upstream's judgement under 6.6#10". The tree says otherwise:

| program | pristine `c3ff8c53f` | fork tip | gcc | 6.6 status |
|---|---|---|---|---|
| `tests/address_constants/ac_cast_int_of_addr.c`: `static int *q = (int *)(long)&g;` | `UB055_invalid_integer_constant_expression` | `Specified(3)` (class `gcc`) | 3 | `(long)` is not a pointer cast and `(long)&g` is not an integer constant: not a 6.6#9 form; 6.6#10 |
| `tests/address_constants/ar_offsetof_idiom.c`: `(int)(unsigned long)&((struct S *)0)->x - 1` | `UB055` | `Specified(3)` (class `gcc`) | 3 | an address operand inside an arithmetic constant expression (6.6#8 lists none); 6.6#10 |
| probe `&g ? 3 : 4` | rejected (6.7.9#4) | `Specified(3)` | 3 | as above, reached by the new `?:` arm composed with the retained `&` arm |
| probe `_Generic(1, int: (long)&g, default: 2)` | rejected | `Specified(3)` | 3 | as above, through the new `_Generic` arm |

The record's own §3.2 says "6 UB055 → accepted (`(char *)&g + 4` and the cast chains, the `offsetof` idiom)", so the
move is known; what is wrong is its description: a UB055 verdict was not an acceptance, so "accepted as before" is
false for these two witness rows, and the two probe forms are not in the table at all. The decision to accept them was
the worker's (the `AilEcast` arm of `is_address_constant` recurses without examining the target type; the `?:` and
`_Generic` arms recurse with the arithmetic predicate whose `&` arm now means "any address constant is an arithmetic
operand"), not upstream's — presenting it as upstream's judgement kept is a provenance error on a contract entry.

The values are gcc's and nothing is silently wrong, so I do not ask for a code change, but the charter reserved this
to the operator. Two resolutions, either acceptable to me: (i) **declare**: D17, the record §0 (d)/§2.4 and the filing
state these as the fork's acceptance of 6.6#10 forms gcc accepts, tagged [AGENT] with the operator's ruling [USER]
beside it, the two witness rows moved to `FORK_PINNED` (or a new declared sub-class for "accepted, gcc agrees, 6.6#10")
and the composition forms added as rows; (ii) **narrow**: the `AilEcast` arm recurses only through pointer-typed casts
(a non-pointer cast of an address constant then answers `false` there), which turns `(int *)(long)&g` and the integer
round-trips into the 6.7.9#4 diagnostic — note this also rejects pristine's `(long)ga` unless that top-level form is
kept, and the `?:`/`_Generic` compositions cannot be narrowed without touching upstream's `&` arm. I lean to (i): the
forms are universally accepted and the fork's run is gcc's, but it must be said in the fork's own voice.

### P2-1 — `ac_ctx_int_of_addr` is a fork acceptance masked by an execution UB, pinned in the `reject` class (pin + record fix)

`static int x = (int)&g;` (`tests/address_constants/ac_ctx_int_of_addr.c`): gcc rejects (`initializer element is not
constant`); the fork's predicate ACCEPTS it (the record §2.4 says so: upstream's 6.6#10 acceptance kept) and the
memory model then reports `Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", …}` at execution. The
row is pinned as class `reject`, whose definition in the script header is "both engines reject where gcc rejects: the
oracle exits 1 and its first error line is the pinned diagnostic" — this pin is an execution verdict, not a diagnostic,
and the constraint was not what refused the program. Consequences: the sentence "40 rejections pinned as both engines'
diagnostics where gcc rejects too" (CONTRACT §4.1, VALIDATION §3(c) and §6, LADDER row 1, `test_unit.sh`, the M2
commit message) is off by one; the record's F7 line "(`(int)&g` returns 3 on both and gcc)" is false (gcc rejects,
both engines report UB024 — the program that returns 3 is `ac_cast_int_of_addr`, `(int *)(long)&g`); and the `reject`
class's check (`$po != Defined* && $pl != Defined*`) admits ANY non-`Defined` verdict, so a `reject` row cannot tell a
constraint rejection from a program that passed the constraint and died later — the `_Static_assert` UB204 rows are
declared as that exception in the header, this one is not. Fix: move the row to a declared class (`FORK_PINNED`, with
its reason: upstream's 6.6#10 acceptance, gcc rejects, UB024 at execution) and re-pin the counts (182/39/12/1), or add
a `reject` sub-check that the pin is a `REJECT(rc=1)` or UB204 line; correct F7 and the "40" sentences.

### P2-2 — The comma in an unevaluated `?:` branch is the one form 6.6#3 excuses by name, and it is rejected with a wrong comment (comment + declaration fix)

Probe `static int a = 1 ? 3 : (1, 2);`: gcc 3; fork and pristine `constraint violation: initializer element is not a
compile-time constant`. 6.6#3 forbids the comma "except when they are contained within a subexpression that is not
evaluated", and 6.5.15#4 makes the unselected branch exactly that. The rejection is loud and pristine's (no regression),
and it falls under the record's F5 ("an unevaluated `?:` branch that is not a constant expression is rejected"), but the
new comma arm's comment in `cabs_to_ail.lem` says "an unevaluated operand never reaches here: sizeof's operand is typed
away and _Generic's controlling expression is not walked" — false for a dead `?:` branch (and for an unselected
`_Generic` association: probe `_Generic(1, int: 3, default: (1, 2))`, gcc 3, fork rejected). Fix: the comment says the
dead-branch case is reached and rejected as F5; a witness row in the declared class; the filing's open questions name it
(it is the strongest instance of the "too strict" TODO upstream carries on its own `?:` arms).

### P3-1 — Residual fail-open vs gcc outside the 446-table (pre-existing; record residual)

`static long l = (long)&g - (long)&ga[0];` → fork and pristine `Specified(3)`, gcc rejects (not computable at load
time); `static int *q = &g + (int)&g;` → the constraint passes on fork and pristine, `UB024` at execution, gcc rejects.
Both come from the arithmetic predicate's retained `&` arm (any address constant as an arithmetic operand). Not
regressions; the record's "0 fail-open after" is relative to its table. Add to §7 and TODO as residuals.

### P3-2 — The UB055 path remains for non-address cast operands (pre-existing; note)

`(int *)(long)(int *)g`, `(long)&g + g`, `(int *)(double)3` → `UB055_invalid_integer_constant_expression` on fork and
pristine where gcc gives a constraint diagnostic: the caller's bullet-4 tail still runs `is_integer_constant_expression`
on both operands, and the `AilEcast` arm's integer test runs on a non-arithmetic operand. The §2.6 re-sequencing fixed
only the address-constant-operand case. A TODO item, not this slice's.

### P3-3 — Record and filing nits

(a) The record §0 and the consumer notes say "the three predicates were `partial def`s before": `is_address_constant`
was a plain `def` (not recursive); the module's partials go 50 → 52 (`is_address_constant`, `is_decayed_static_lvalue`).
(b) Tray 09 "Classification" says "two fail-open acceptances"; the record counts three in the table and the vicinity
closed more. (c) The `_Generic` arm of `is_integer_constant_expression` is described as "the arm is the standard's
text": C17 6.6#6's operand list does not name generic selections; the basis is 6.5.1.1#3 ("identical type and value")
plus universal practice (and C2x's direction). Upstream left this as a TODO crash, so under the TODO rule the fork's
acceptance is a reading, defensible but to be labelled as one in the record and kept as a question in the filing.
(d) The tray's INDEX row and the record say "fixed in the fork 2026-11-07" while status stays Draft: consistent, fine.

### P3-4 — One conforming program moved from a clean (wrong) refusal to an internal error (disclosed; note)

`tests/csmith_findings/oracle/init_addr_const.c` now reaches draft 08's `Translation called on Ail program with an
invalid node` where the over-strict rejection stopped it earlier. A crash is a worse class than a refusal for that one
program; disclosed in the record §4.3, TODO and the filing; walked by no lane; draft 08 is the remover.

### P3-5 — Diagnostic-text changes beyond `ci/0268` (note)

Ill-typed decay-shaped initializers now report the typing's own error at desugaring: probe `static int *q = gs.nope;`
→ fork `constraint violation: no member named 'nope' in 'struct S'`, pristine `initializer element is not a compile-time
constant` (gcc: `has no member named`). Same class as the ci/0268 register row; in no walked corpus; the record's
§2.3 sentence covers it, the §4.3 inventory could name the class.

### P3-6 — Cost

The witness adds 35.4 s to row 1 with its self-test (measured here; the record's 35.29 s). Acceptable; row 1's witness
block (ranks, stdio, this) is now several minutes, worth watching.

## What I ran (verbatim last lines)

Tray patch against pristine (read-only `--check`, then applied to a scratch copy):

```text
Checking patch frontend/model/cabs_to_ail.lem...
apply --check rc=0
patching file frontend/model/cabs_to_ail.lem
p/frontend/model/cabs_to_ail.lem ../../frontend/model/cabs_to_ail.lem differ: byte 47551, line 1373
```

(the 24 residual hunks are the fork's pre-existing deltas: `diff` hunk list against the patched copy `1372a1373,1378
1375c1381,1386 1595a1607,1614 1792a1812,1832 …` = the pristine-vs-base list `1159a1160,1165 1162c1168,1173
1382a1394,1401 1579a1599,1619 …` shifted by the fix's 213 added lines; the `+ end` placement difference between the
tray's diff and `git diff` is a diff-algorithm artefact.)

gcc and pristine re-run over all 234 witness programs, rendered in the pin files' encodings and sorted:

```text
gcc rows: pinned 234 mine 234; diff lines: 0
pristine rows: pinned 234 mine 234; diff lines: 4
144c144
< ice_case_cond_gnu	PEcase, mismatched
---
> ice_case_cond_gnu	CRASH(rc=125): unsupported: ice_case_cond_gnu.c:2:38:: TODO: elaboration of ?: operator
```

(the one pristine difference is my instrument's: pristine prints `unsupported: … TODO: elaboration of ?: operator` and
then `internal error: PEcase, mismatched ==> …`, exit 125, and my renderer took the first line; the worker pinned the
second. Verified by running pristine, the fork oracle, the base oracle and the Lean engine on the file directly: all
four print `PEcase, mismatched ==> [ice_case_cond_gnu.c:2:36-42 (cursor: 2:38)]Unit`; not a finding.)

Witness self-test and the row-1 gates on the tip:

```text
check_address_constants: selftest plant 'pristine-pair' caught: 14 failing check(s) (= expected 14; incl. the required programs)
check_address_constants: selftest plant 'lean-pristine' caught: 7 failing check(s) (= expected 7; incl. the required programs)
check_address_constants: selftest plant 'lean-fixed' caught: 14 failing check(s) (= expected 14; incl. the required programs)
check_address_constants: selftest plant 'oracle-rc' caught: 9 failing check(s) (= expected 9; incl. the required programs)
check_address_constants: selftest plant 'expect-tamper' caught: 3 failing check(s) (= expected 3; incl. the required programs)
check_address_constants: OK (234 programs, nolibc: 182 batch lines of both engines = gcc 13's pinned line, exit 0 on both — …
selftest wall 35.38 s
rc=0
check_fork_content: OK — 95 source files content/mode-pinned
check_fork_drift: OK — layer 1: 95 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.…
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-f…
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=175 REACHABLE=…
```

Derived: moved rows from `pristine.txt` to `expected.txt` (gap excluded) = 112 (the record's 112); `partial def`
names in `Cabs_to_ail.lean`, primary checkout vs tip: `+ is_address_constant`, `+ is_decayed_static_lvalue`; generated
trees `diff -rq` against the primary checkout: `ocaml_frontend/generated/cabs_to_ail.ml` and
`lean_frontend/generated/Cabs_to_ail.lean` only.

Probes (gcc exit / fork oracle / Lean engine on the oracle's Cabs JSON / pristine; `--nolibc --exec --batch`; the
Lean line equalled the oracle's on every row, so one column):

| probe | gcc | fork = Lean | pristine |
|---|---|---|---|
| `static int a = 1 ? 3 : (1, 2);` | 3 | rejected (6.7.9#4) | rejected |
| `static int a = sizeof((1, 2)) - 1;` | 3 | 3 | 3 |
| `static int *q = (int *)(long)(int *)g;` | reject | `UB055` | `UB055` |
| `static int *q = &g + (int)&g;` | reject | `UB024` (constraint passed) | `UB024` |
| `_Thread_local int *tp = &g;` | 3 | 3 | 3 |
| `_Thread_local int t = 3; _Thread_local int *tp = &t;` | reject | rejected | 3 (fail-open, now closed) |
| `extern int ea[3]; static int *q = ea + 1; int ea[3] = {1, 3, 5};` | 3 | 3 | 3 |
| `static int a = _Generic(1, int: 3, default: (1, 2));` | 3 | rejected | rejected |
| `static int *q = gs.nope;` | `has no member named` | `no member named 'nope' in 'struct S'` | `not a compile-time constant` |
| `static long l = (long)&g - (long)&ga[0];` | reject | 3 | 3 |
| `static int a = &g ? 3 : 4;` | 3 | 3 (NEW) | rejected |
| `static int *q = 1 ? _Generic(1, int: &g, default: &ga[0]) : &ga[1];` | 3 | 3 (NEW) | rejected |
| `int a[sizeof((1, 2))];` | 3 | 3 | 3 |
| `static int a = sizeof(g++) - 1;` | 3 | 3 | 3 |
| `static int *q = &(gsa + 1)->b;` | 3 | 3 | 3 |
| `static int a = _Generic((1, 2), int: 3, default: 4);` | 3 | 3 (NEW) | rejected |
| `static int *q = 2 + ga - 1;` | 2 | 2 (NEW) | rejected |
| `static int *q = (int *)(double)3;` | `cannot convert to a pointer type` | `UB055` | `UB055` |
| `static long l = (long)&g + g;` | reject | `UB055` | `UB055` |
| `static long l = _Generic(1, int: (long)&g, default: 2);` | 3 | 3 (NEW) | rejected |

Not run here (the orchestrator's): Tier A, the full battery, the pristine lane tier-b, the 7413-file corpus sweep
(its instrument is deleted; the 234-program witness is what the tree carries). Kernel replay is not owed (no proof
module, seam or fuel form changed; verified by the diffstat and the generated-delta check).

## Disposition requested

Before landing: P1-1 (the operator's ruling recorded with provenance; D17, the record and the filing corrected; the two
witness rows reclassed or the arm narrowed), P2-1 (reclass + counts + F7 + the "40" sentences), P2-2 (the comment, a
declared row, the open question). P3-1 to P3-6 are for the record's §7/TODO at the worker's or orchestrator's
convenience. Scratch `.tmp/review/` removed after this file was written.

## Dispositions [AGENT 2026-11-07, the worker, applying the orchestrator's rulings; commits `a5fc0fcd9` (code and pins) and the docs commit that carries this section]

- **P1-1 — ruled: option (ii)** ([AGENT 2026-11-07, orchestrator] under the charter's explicit M1 instruction and the standing
  [USER 2026-11-04] bar: 6.6#10 latitude is a judgement call the fork does not take). FIXED in the Lem, by matching
  upstream's arms: (1) the conditional and generic-selection arms of `is_arithmetic_constant_expression` test their
  operands in 6.6#8's own terms (a `no_address` mode under which the unary `&` arm answers false), so `&g ? 3 : 4` and
  `_Generic(1, int: (long)&g, default: 2)` keep upstream's rejection while the top-level entry keeps upstream's
  acceptance of `(long)&g` and `&g == &g`; the same mode tests the condition of `is_address_constant`'s `?:` arm. (2)
  The cast arm of `is_address_constant`: a pointer target keeps the 6.6#9 reading (a pointer cast of an address
  constant; an integer constant cast to pointer type, tested one level up as upstream tested it); a NON-pointer target
  keeps upstream's arm in shape — the operand an lvalue to a static object, the target type not examined — with the
  lvalue required to be of array type (`is_static_array_lvalue`, the decay 6.6#9 names). That is the arm that keeps
  the reviewer's `(long)ga` (and `(long)gs.arr`, `(long)"s"`) accepted, and it lets `(int *)(long)&g` fall to
  upstream's integer test and its UB055; upstream's integer-constant clause under a non-pointer cast is not taken (no
  conforming program needs it: the arithmetic predicate accepts `(long)5`; `(int *)(double)3` keeps upstream's UB055).
  (3) The base of `*` and `->` must designate an object (`designates_object`: no null pointer constant, no integer
  cast to pointer type), so the offsetof idiom through an integer cast keeps upstream's UB055 and `&*(int *)16`
  upstream's rejection, while `&((struct S *)&gs)->b` stays accepted. Proved both directions on the 472-program table
  (the review's probes added; gcc 13 `-std=c11 -pedantic-errors`, pristine, the fork oracle, the Lean engine): 94 rows
  the fork accepts and pristine does not, every one gcc-accepted and a 6.6#3-#9 form (the record §3.2 lists them by
  clause); 12 rows pristine accepts and the fork does not, every one gcc-rejected; 15 rows where neither accepts and a
  crash or an execution UB became the constraint diagnostic; the four P1-1 forms at pristine's answers; Lean = oracle on
  all 472. The witness re-pinned: `ac_cast_int_of_addr` and `ar_offsetof_idiom` are declared rows at pristine's UB055
  (gcc's line beside), `ice_init_cond_addr_cond` and `ar_generic_long_addr` declared rows at pristine's rejection; the
  compositions the reviewer found NEW and that are listed forms (`1 ? _Generic(…) : &ga[1]`, `2 + ga - 1`,
  `_Generic((1, 2), int: 3, default: 4)`) are `gcc` rows. D17, the record (§0 (d), §2.4, §2.7) and the filing now say
  this in the fork's own voice.
- **P2-1 — FIXED.** `ac_ctx_int_of_addr` (`(int)&g`: the constraint passes as upstream's does, `UB024` at execution, gcc
  rejects) is a declared row; the `reject` class check admits only a constraint rejection on both engines (`REJECT(rc=1):
  error: constraint violation: …` with the Lean `Error {msg: "desugaring failed at …` line), or upstream's `UB204` verdict
  in a `_Static_assert`, or its `feature not yet supported: variable length array type` refusal in a file-scope array
  bound (the second exception, found by the tightened check on `ice_arr_comma`), each declared in the header; the
  "40 rejections" sentences are the re-pinned counts everywhere (CONTRACT §4.1, VALIDATION §3(c) and §6, LADDER row 1,
  `test_unit.sh`, the record); the record's F7 no longer claims `(int)&g` returns 3 (it is UB024 on both engines, gcc
  rejects; the program that returns 3 was `(int *)(long)&g`, now UB055 under P1-1).
- **P2-2 — FIXED.** The comma arm's comment says the dead-branch case is reached and rejected as the declared
  over-strictness (6.6#3's own exception and 6.5.15#4 not taken: upstream's rejection kept — the strongest instance of
  the "too strict" TODO on its `?:` arms); `ice_init_cond_dead_comma` and `ice_init_generic_dead_comma` are declared
  rows (gcc 3 beside); the filing's open questions name the case; the declared-list wording in the script header,
  CONTRACT D17, VALIDATION and the record says the fork keeps pristine's rejection there.
- **P3-1 — recorded** as residuals in the record §7 and TODO, and in the filing where they are upstream's (the
  arithmetic predicate's retained `&` arm): `(long)&g - (long)&ga[0]` runs (`ar_addr_diff_long`, a declared row: the
  table's one fail-open after, pristine's acceptance kept by the P1-1 rule) and `&g + (int)&g` passes the constraint and
  is `UB024` (`ac_addr_plus_int_addr`, a declared row).
- **P3-2 — recorded** in the record §7, TODO and the filing: the UB055 path for a non-arithmetic cast operand is
  upstream's (`(int *)(double)3`, `ac_cast_double_ptr`, a declared row at upstream's UB055; `(int *)(long)(int *)g`,
  `(long)&g + g`); not this slice's.
- **P3-3 — corrected.** (a) `is_address_constant` was a plain `def`; the module's `partial def`s went 50 → 52 at the
  reviewed tip and are 56 after the narrowing (the block's eight: the two arithmetic entries, the lvalue predicate, the
  two address entries, `static_lvalue_type`, `is_decayed_static_lvalue`, `is_static_array_lvalue`); the record §0/§2.5 and
  the consumer notes say so. (b) The filing's Classification counts the fail-open acceptances as measured
  (three in the first table, twelve closed by the vicinity). (c) The `_Generic` arm of `is_integer_constant_expression`
  is labelled the fork's reading of 6.5.1.1#3 (universal practice) in the Lem comment, the record and the filing's
  open questions, where upstream's TODO crash is what it replaced. (d) nothing to do.
- **P3-4 — kept** as disclosed (record §4.3/§7, TODO, the filing's related findings); the TODO entry names draft 08 as
  the remover and the program as its new reproducer.
- **P3-5 — recorded** (record §4.3 and §7, TODO, the filing's related findings): an ill-typed decay-shaped initializer
  reports the typing's own error at desugaring (`gs.nope`: `no member named 'nope' in 'struct S'` where pristine said
  `not a compile-time constant`), the same class as the `ci/0268` register row; in no walked corpus.
- **P3-6 — none** (the witness: 27 s the run, 35 s with the self-test).
- **Contract numbering** [AGENT 2026-11-08, orchestrator]: the numbers stay as assigned across the three parallel slices
  whatever the landing order — D16 the printf refusals, D17 the address constants (this slice), D18 the half-mirrors.
