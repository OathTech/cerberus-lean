# Anonymous struct/union members become a loud refusal (survey cluster A, tray 60) — slice record (2026-10-26)

Branch `fix/anonymous-members-refusal`, worktree `worktrees/cerberus-lean-fix/anonymous-members-refusal`,
from mainline `mdd/cerberus-lean` = `704c4e697` (Lean 4.35.0, lem `e6d8db5`); charter
`docs/2026-10-26_worker-charter-anonymous-members-refusal.md` (commit `4c653b1b9`). Worker: Claude
Fable 5.1 (agent). Every judgement below that no operator ruling covers is marked [AGENT]. Status:
**implemented, witnessed on both engines, the gates of §6 green on the final tree.** The charter's
premises held with two corrections stated where they bit (§2.2: the stop form; §3.3: a row-1 control
the charter did not name).

## 0. Rulings and standing rules

- [USER 2026-10-20] (the upstream-uncertainty survey, `docs/2026-10-20_upstream-uncertainty-survey-record.md`
  §0 ruling 2, §2.1 cluster A, §3 slice 1): anonymous struct/union members are REFUSED in the shared Lem and the
  upstream report filed (tray 60). The standing rule behind it (the item-G and union-initializer rulings, contract
  D10/D11): where upstream left a case under its own TODO or doubt, the fork leaves it as-is or REFUSES LOUDLY —
  never invents a semantic outcome, never answers silently wrong. Upstream's judgement stands: this is a
  TODO-marked doubt upstream itself prints (`this may be WRONG ==> anonymous Struct/Union`), so the fork refuses
  rather than implements the feature.
- [USER 2026-10-26]: run the slice now, in parallel with the quotation-hygiene slice (the charter's box rules).
- Charter rulings carried out as written: retire `tests/coverage/struct/struct-008-anon-struct.c` with its baseline
  row (the item-G / union3-003 precedent [USER 2026-10-20]: a MATCH on a case the fork now refuses is not
  evidence), keep its shape as a witness; register exactly, never blindly; any OTHER baseline movement is a park.
- Mirror doctrine holds by construction (one `.lem` arm, both engines generated from it; the generated texts are
  checked byte for byte, §4). Fail-closed; no new opaque atom; no `set_option`; no hand edit of `generated/`; no
  hand-written seam or proof module changed (so the kernel-replay gate of [USER 2026-10-18] does not apply).
- Precedents followed: item G (D10, `docs/2026-10-20_item-g-refusals-record.md`) and the union-initializer refusal
  (D11, `docs/2026-10-20_union-init-refusal-record.md`, its review `docs/2026-10-21_union-init-premerge-review.md`).

## 1. The defect, as it stood (both engines; pristine `b9aeedcb4` agrees — survey §2.1)

`desugar_struct_declaration` (`frontend/model/cabs_to_ail.lem`; pristine :2697, this tree :2708-2721 before the
change): for a struct-declaration with no declarators it calls `E.get_anonymous_struct_or_union base_ty` and on
`Just membrs` returns `membrs` — the anonymous member's members spliced flat into the containing aggregate's member
list. The splice site is exactly where the survey says (charter STOP condition 1 did not fire). Consequences (the
survey's table, gcc 13 = the standard): `sizeof(struct { union { int b; char c; }; })` 8 (gcc 4); no aliasing
between `b` and `c` (`s.b = 0x01020304; return s.c` Unspecified, gcc 4); `{1, 2, 3}` over `int a; union { int b;
char c; }; int d;` giving a=1, c=2... d=0 (21, gcc 321); an anonymous struct more aligned than its predecessor at
`sizeof` 8 (gcc 12); false UB081/UB036/pointer-equality verdicts; 25 silent-wrong probes under
`tests/parity-probes/uncertainty/A-anonymous-members/`. Designated initializers naming the members answered right
(by name lookup alone), which is why `tests/coverage/struct/struct-008-anon-struct.c` was a MATCH.
Precision (the pre-merge review's P3-2): the four `this may be WRONG ==> anonymous Struct/Union` prints the refusal
text cites are guarded by the TAG's `isAnonymous` flag (pristine :142-147, :164-169, :192-197, :3242-3247), i.e.
they fire for every tagless specifier at the initializer-path layer — named members of tagless type included,
which answer right and are controls here — while the splice arm itself (:2697) carries no TODO: it is a deliberate
upstream reading, refused under the same ruling (a deliberate reading is kept or refused loudly, never
re-decided). The text overstates the link and is not changed (it is pinned byte for byte in both generated engines
and four documents; a nuance is not worth a regeneration and a manifest re-pin) [AGENT 2026-10-27].

## 2. Design

### 2.1 The predicate and the arm

The arm itself: `List.null sdecltors` with `get_anonymous_struct_or_union base_ty = Just _`, i.e. a
struct-declaration declaring no member whose type specifier is a struct/union whose definition is anonymous
(C17 6.7.2.1#13). `Just _` replaces `E.return membrs` with `error (anonymous_member_refusal base_ty)`; the helper
(defined before the `let rec desugar_type_specifiers … and …` chain) builds the text from the member's own type:

```lem
let anonymous_member_refusal base_ty =
  let kind = match base_ty with
    | Ctype.Ctype _ (Ctype.Struct _) -> "struct" | Ctype.Ctype _ (Ctype.Union _) -> "union" | _ -> "struct/union" end in
  "Cabs_to_ail.desugar_struct_declaration: refused - anonymous " ^ kind ^ " member (" ^ … ^ "(survey cluster A, tray 60, 2026-10-26)"
```

The text (ASCII only; the kind word varies, the rest is fixed):

```text
Cabs_to_ail.desugar_struct_declaration: refused - anonymous union member (a struct-declaration with no declarator whose type specifier is a tagless union; C17 6.7.2.1#13); upstream splices its members into the containing aggregate's member list ('STD 6.7.2.1#13 ... E.return membrs' b9aeedcb4 :2697, under its own 'this may be WRONG ==> anonymous Struct/Union' :144/:166/:194/:3244), which changes layout, aliasing and initialisation (wrong sizeof and offsets, no aliasing between an anonymous union's members, brace-elided initializers one slot late, false UB verdicts) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)
```

Generated: OCaml `Cerb_debug.error (anonymous_member_refusal base_ty)` (`ocaml_frontend/generated/cabs_to_ail.ml`
:2795 — `internal error: <text>` on stderr, then `Failure("internal error: <text>")` uncaught, exit 125); Lean
`(failwithI (anonymous_member_refusal base_ty) : state_with_markers → exceptM …)`
(`lean_frontend/generated/Cabs_to_ail.lean` :1975 — Lean is strict, the arm's value is the saturated `failwithI`,
it panics when the arm is taken; abort under `LEAN_ABORT_ON_PANIC=1`, exit 134). The generated trees differ from the
mainline's in exactly `cabs_to_ail.ml` (33 lines: the helper, the comment, the arm) and `Cabs_to_ail.lean` (42).

Why the refusal is at the DECLARATION and not at a use: the splice happens when the aggregate's member list is
built, so every consequence (layout, aliasing, the initializer cursor, `PEmemberof`) descends from that one arm;
refusing there is complete by construction and needs no second predicate. A type that is declared and never used
refuses too (witness `w_u_unused_type.c`) — a refusal is a permitted outcome; this is the cheapest point at which
nothing wrong can be built.

### 2.2 The stop form — (b) `error`, not the charter's preferred (a) [AGENT 2026-10-26]

The charter prefers (a) `E.fail loc (Errors.Desugar_NotYetSupported "…")` IF both engines render it identically
in batch and the lanes classify it as a matched frontend refusal, otherwise (b). Measured on the existing (a)
site (a VLA, `int a[n]`), on this tree's engines:

```text
$ main.exe --exec --batch --nolibc vla.c ; rc=1
vla.c:1:32: error: feature not yet supported: variable length array type 2
$ LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch vla.json ; rc=1
Error {msg: "desugaring failed at vla.c:1:32-36"}
```

The oracle carries the reason on stderr with no verdict line; the port's batch `Error` record carries only the
location (Main.lean prints the cause text only in its non-batch mode). So (a) is loud on both engines but attributed
on one, the two renderings are not identical, and `scripts/test_exec.sh` classes an exit-1 oracle with no verdict
as `CERB_SKIP` — not a matched refusal. The charter's own rule then selects (b): a pure Lem `error`, the D11 shape,
whose text both engines carry byte for byte (and which escapes `wip_desugar_initializer_`'s `E.catch` with
certainty, cabs_to_ail.lem:3555-3572 on the committed tree — that catch re-raises anything but an
`Internal_error_desugaring` (:3560, :3571), so (a) would have escaped it too; the point is the rendering). Consequence for the consumer: a LEGACY stop under the
outcome protocol, origin unattributed, like D10/D11 (the migration map gains an UNMIGRATED line); the consumer note
says so and why.

### 2.3 Bypass probes (both engines, §4's harness)

Refused: nested anonymous members (`struct { union { … }; int c; };` inside a struct — the innermost is desugared
first and names the kind word), an anonymous struct inside a union (au-08), a typedef'd TAGLESS specifier used
bare (`typedef struct { … } T; struct S { T; }` — the specifier is then a typedef name resolving to a tagless
struct, which the text's parenthetical does not distinguish (review P3-5); upstream spliced that too; gcc warns
"declaration does not declare anything"; refusing it is safe), `sizeof` only, block scope, a compound literal of such a struct in the
initializer position (through the `E.catch`), `_Alignas(16)` on the member, a type never used. NOT refused,
unchanged: a TAGGED struct with no declarator (`struct S { struct T { int x; }; }`) and a typedef'd TAGGED
specifier used bare — `get_anonymous_struct_or_union` returns `Nothing` for a named tag and the pre-existing
`constraint violation: non-anonymous struct/union must contain a declarator list` (6.7.2.1#2) fires, exit 1 on
both engines (Lean `Error {msg: "desugaring failed at …"}`); likewise `int;`. `__attribute__((packed))` between
`}` and `;` is a pre-existing parse error (`unexpected token after '('`), unchanged and not a gap this slice
owns. There is no second splice site: the predicate has one arm, and the five corpus programs that refuse (§3) are
exactly the five the syntactic scan predicted.

## 3. Measurement before committing (every corpus the lanes walk, on the new oracle)

### 3.1 Syntactic scan, then the exact run

A brace-matching scan (comments, strings and preprocessor lines stripped; a tagless `struct`/`union` specifier
nested in an aggregate body whose `}` is followed by `;`) over `tests/`, `lean_frontend/corpus`, `runtime/libc`,
`deps/cn/tests/cn`, `deps/libxml2` and the pKVM case study flagged, outside the survey's own probe directory, 7
files: `coverage/struct/struct-008-anon-struct.c`, `parity-probes/probes/anon_struct_union.c`,
`gcc-torture/execute/anon-1.c` + `breakdown/success/anon-1.c`, `gcc-torture/execute/20030714-1.c` +
`breakdown/not_supported/bitfields/20030714-1.c`, `suite/desugaring/13-non_anonymous_empty_sdecltors.error.c`;
csmith 0; libc, CN, libxml2, pKVM 0. The exact run (the new oracle, `--nolibc --pp=ail`, one process per file):

```text
REFUSED tests/coverage/struct/struct-008-anon-struct.c
REFUSED tests/gcc-torture/breakdown/success/anon-1.c
REFUSED tests/gcc-torture/execute/anon-1.c
REFUSED tests/parity-probes/probes/anon_struct_union.c
REFUSED tests/suite/desugaring/13-non_anonymous_empty_sdecltors.error.c
NON-CSMITH files=5567 refused=5 exits: 1=2094 0=3443 124=2 125=28
CSMITH files=1669 refused=0 exits: 1=1 0=1665 125=3
```

(`20030714-1.c` dies on the bit-fields refusal first, as before. The 28 non-csmith and 3 csmith exit-125 runs
other than the five are pre-existing: the three csmith ones — `small_arrays_csmith_00{2,3,5}.c`, `Translation
called on Ail program with an invalid node` under `--pp=ail` — and the one exit-1 were re-run on the mainline
primary checkout's oracle with identical exit codes and texts.) `dune build cerberus.install` restaged `libc.co`
under the new desugarer (rc 0): the libc has no anonymous member.

### 3.2 Where each refusing program lives

| program | lane | disposition |
|---|---|---|
| `tests/coverage/struct/struct-008-anon-struct.c` | Tier A row 3 (`exec_coverage_baseline.txt`, MATCH 12); walked by the pristine lane (Tier B row 10) | RETIRED with its baseline row per the charter; its shape is witness `w_s_coverage_struct_008_shape.c` (§4) |
| `tests/gcc-torture/breakdown/success/anon-1.c` | `test_ci_sweep.sh` `torture_success` (Tier C scoreboard; NO baseline; committed TSV `tests/ci_sweep/results/torture_success.tsv:537` `MATCH VAL:Specified(0)`) | moves MATCH → both engines refuse at the scoreboard's next deliberate re-record (LADDER: the TSVs move only by a deliberate re-record); registered in TODO.md's closed entry |
| `tests/gcc-torture/execute/anon-1.c` | no lane walks `execute/` | — |
| `tests/suite/desugaring/13-non_anonymous_empty_sdecltors.error.c` | `test_ci_sweep.sh` `suite` (scoreboard; `suite.tsv:21` `CERB_REJECT exit 1: … constraint violation: non-…`) | its FIRST line `struct T1 { struct{int x;}; }; // OK` is an anonymous member, so the refusal now fires before line 2's constraint violation: CERB_REJECT → the refusal class at the next re-record; its second line's rejection is gap control `gap_int_no_declarator.c` |
| `tests/parity-probes/probes/anon_struct_union.c` | not a gate (the parity-detective corpus) | its shape is witness `w_s_parity_probe_shape.c`; the corpus README notes the change |

The pristine-oracle lane (`scripts/test_upstream_oracle.py`, Tier B row 10 + the ci/csmith reporting rows) walks
`tests/{minimal,coverage,debug,float,bytes,libc_exec}`, multi-TU, CN, libxml2 uri, CLI, immaculate, verify,
`lean_frontend/corpus`, `tests/ci` and csmith — never gcc-torture or `tests/suite` (named in its `not_applicable`).
Of its corpora only `coverage/struct-008` refuses, and it is retired, so `scripts/upstream_oracle_differences.json`
gains NO row (as for D9/D10/D11); the B10.1 precedent (an exact `diagnostic-text` registration) applies to nothing
here. `tests/ci/0308-struct_global_with_dep.c`'s anonymous FILE-SCOPE union is an object with a declarator, not a
member: unaffected (control `ctl_tagless_file_scope_object.c`).

### 3.3 A row-1 control the charter did not name [AGENT 2026-10-26]

`scripts/check_union_init_refusals.sh` carried `ctl_anonymous.c` — `struct S { int k; union { int i; unsigned
char c[4]; }; } s = { .c = {1,2,3,4}, .k = 7 }`, `Specified(74)` on both engines — as a CONTROL of D11 ("the
anonymous-union-in-struct path, unaffected"), and D11's SUPPORTED sentence named that path as the carve-out this
slice was to close. After M1 that control fails (`oracle: expected [Defined {value: "Specified(74)", …}]; got
rc=125`), i.e. row 1 would be red. It is not a baseline row and not a corpus program; it is a control of the
stance this slice supersedes, exactly the item-G / union3-003 shape, so it is retired from that script (its plant
counts re-derived: 28/26/12/15/14; its shape is witness `w_u_union_init_ctl_anonymous_shape.c` here) and D11's
texts (CONTRACT row, VALIDATION bullet and gate row, LADDER, SUPPORTED) say the path is refused by D12. Reported
here rather than parked: the charter's own "update the union-initializer SUPPORTED carve-out sentence" names the
gap, the fix is the precedent's, and no baseline moved. Movement on the M1 tree, verbatim (the two lanes run with
struct-008 and the control temporarily restored):

```text
[255/278] CERB_SKIP struct-008-anon-struct (exit 125)
SUMMARY: total=278 match=222 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=17 cerb_floor=0 cerb_inconsistent=0
REGRESSION: struct-008-anon-struct.c baseline=MATCH current=CERB_SKIP
check_union_init_refusals: FAIL — anonymous union member inside a struct, designated through the struct: oracle: expected [Defined {value: "Specified(74)", stdout: "", stderr: "", blocked: "false"}]; got rc=125 []
check_union_init_refusals: 1 witness failure(s) over 27 cases
```

No other row of either lane moved. [AGENT 2026-10-26] Tier A was run on the M2 tree (§6) rather than on the M1
tree, which is red on exactly those two pre-authorized rows by the charter's own design; the two lane runs above
are the verbatim measurement of the M1 tree, and M1's commit message says so.

## 4. Witnesses and plants — `scripts/check_anonymous_members_refusal.sh` (row 1, wired into `test_unit.sh`)

42 cases, nolibc, fail-closed, the item-G/D11 shape with one strengthening: every witness pins its WHOLE text —
the file name says the kind word (`w_s_*` struct, `w_u_*` union), and the oracle must die with exactly
`Failure("internal error: <HEAD><kind> member (…tagless <kind>; C17 6.7.2.1#13); <TAIL>")` (exit 125, `uncaught
exception`), `--cabs-json` must succeed, Lean must abort (exit 134) with a `PANIC` line carrying the same whole
text, and the two texts (head to end of line) must be byte-identical. A control requires Lean = oracle (exit code,
first verdict line); a gap control both engines' pre-existing rejection (exit 1, their own texts).

- 29 witnesses: the survey's an-01/02/03/04/08, un-03/06/11/12, au-01/02/04/07/08/10, ax-01/03/06, ac-01 (each
  with gcc's value and the engines' pre-refusal answer in its comment); the retired coverage control struct-008's
  shape; the union-initializer script's retired control's shape; the parity-detective probe's shape; nested
  members; a typedef'd tagless specifier; block scope; a compound literal in the initializer position; `_Alignas`;
  an unused type; sizeof only.
- 10 controls (named members): un-01/02/08, au-05/06, a named struct inside a struct (4321), a union with named
  members only as a named struct member (21), a plain union (5), a tagless type WITH a declarator (21), a tagless
  file-scope union object (9).
- 3 gap controls: a tagged struct with no declarator, a typedef'd tagged specifier, `int;`.
- Plants (`--selftest`), each asserting its EXACT failure count and the required cases, derived before the run:
  `answer` (both engines answer `Specified(12)`, the retired control's value, on every `w_*` program) 58 = 29 × 2;
  `lean-answer` 42 = 29 + 10 + 3; `refuse-all` (both stubs refuse everything, the kind word read from the file name
  so the witnesses pass and every control fails) 13 = 10 + 3; `lean-no-abort` 32 = 29 + 3; `lean-other-text` 29.

Verbatim, an-01 on this tree's engines (the oracle's backtrace and the Lean backtrace line omitted; the oracle's
`uncaught exception` header carries ANSI colour bytes under a terminal):

```text
$ main.exe --runtime=… --exec --batch --nolibc an-01-ctl.c ; rc=125
internal error: Cabs_to_ail.desugar_struct_declaration: refused - anonymous union member (a struct-declaration with no declarator whose type specifier is a tagless union; C17 6.7.2.1#13); upstream splices its members into the containing aggregate's member list ('STD 6.7.2.1#13 ... E.return membrs' b9aeedcb4 :2697, under its own 'this may be WRONG ==> anonymous Struct/Union' :144/:166/:194/:3244), which changes layout, aliasing and initialisation (wrong sizeof and offsets, no aliasing between an anonymous union's members, brace-elided initializers one slot late, false UB verdicts) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)
cerberus: internal error, uncaught exception:
          Failure("internal error: Cabs_to_ail.desugar_struct_declaration: refused - anonymous union member (a struct-declaration with no declarator whose type specifier is a tagless union; C17 6.7.2.1#13); upstream splices its members into the containing aggregate's member list ('STD 6.7.2.1#13 ... E.return membrs' b9aeedcb4 :2697, under its own 'this may be WRONG ==> anonymous Struct/Union' :144/:166/:194/:3244), which changes layout, aliasing and initialisation (wrong sizeof and offsets, no aliasing between an anonymous union's members, brace-elided initializers one slot late, false UB verdicts) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)")
$ LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --runtime=… an-01-ctl.c.json ; rc=134
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Cabs_to_ail.desugar_struct_declaration: refused - anonymous union member (a struct-declaration with no declarator whose type specifier is a tagless union; C17 6.7.2.1#13); upstream splices its members into the containing aggregate's member list ('STD 6.7.2.1#13 ... E.return membrs' b9aeedcb4 :2697, under its own 'this may be WRONG ==> anonymous Struct/Union' :144/:166/:194/:3244), which changes layout, aliasing and initialisation (wrong sizeof and offsets, no aliasing between an anonymous union's members, brace-elided initializers one slot late, false UB verdicts) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)
```

an-04 (an anonymous struct) differs only in the kind word: `… refused - anonymous struct member (a
struct-declaration with no declarator whose type specifier is a tagless struct; C17 6.7.2.1#13); …`. All 35
anonymous-member programs of the survey directory plus the bypass set refused on both engines with TEXT-EQUAL
texts in the development harness; every named-member control agreed. Script result, verbatim:

```text
check_anonymous_members_refusal: selftest plant 'answer' caught: 58 failing witness(es) (= expected 58; incl. the required witnesses)
check_anonymous_members_refusal: selftest plant 'lean-answer' caught: 42 failing witness(es) (= expected 42; incl. the required witnesses)
check_anonymous_members_refusal: selftest plant 'refuse-all' caught: 13 failing witness(es) (= expected 13; incl. the required witnesses)
check_anonymous_members_refusal: selftest plant 'lean-no-abort' caught: 32 failing witness(es) (= expected 32; incl. the required witnesses)
check_anonymous_members_refusal: selftest plant 'lean-other-text' caught: 29 failing witness(es) (= expected 29; incl. the required witnesses)
check_anonymous_members_refusal: OK (42 cases: 29 anonymous struct/union members (the survey's brace-elision, anonymous-first, array, sizeof/offsetof/aliasing/copy, anonymous-struct-in-union, padding and false-UB shapes; the designated, anonymous-struct-sizeof, retired coverage control struct-008, retired union-initializer control and parity-probe shapes that answered right by name lookup alone; nested members, a typedef'd tagless specifier, block scope, a compound literal, _Alignas, an unused type, sizeof only) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts naming the member's kind; 10 controls with NAMED members agree with the oracle (a named union elided/braced/sizeof/aliased, a named single-member union, a named struct inside a struct, a union with named members only, a plain union, a tagless type with a declarator, a tagless file-scope object); the tagged-no-declarator, typedef'd-tagged and int; constraint violations are unchanged on both)
```

The union-initializer script after its control's retirement (§3.3), verbatim:

```text
check_union_init_refusals: selftest plant 'answer' caught: 28 failing witness(es) (= expected 28; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-answer' caught: 26 failing witness(es) (= expected 26; incl. the required witnesses)
check_union_init_refusals: selftest plant 'refuse-all' caught: 12 failing witness(es) (= expected 12; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-no-abort' caught: 15 failing witness(es) (= expected 15; incl. the required witnesses)
check_union_init_refusals: selftest plant 'lean-other-text' caught: 14 failing witness(es) (= expected 14; incl. the required witnesses)
check_union_init_refusals: OK (26 cases: 14 union initializers designating a member other than the first (…) refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 11 controls agree with the oracle (…; the anonymous-union control was retired 2026-10-26, that class now refused); the struct-from-struct-variable rejection is unchanged on both)
```

## 5. Register entries

- **Fork-drift manifest (`scripts/fork_drift_manifest.txt`):** exactly the two charter rows moved — `[source-content]`
  `frontend/model/cabs_to_ail.lem` `39acb8c3… → fcc8ce5b…`, `[expected-semantic]` `cabs_to_ail.ml` `0691b548… →
  74b272fa…` — single-row edits with a dated header NOTE (`fix/anonymous-members-refusal, 2026-10-26`), no
  `--refresh`. Gate + self-test, verbatim: `check_fork_drift: OK — layer 1: 92 oracle-surface files = manifest (set,
  C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned (merge-base
  b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v
  lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))`; `check_fork_drift: SELFTEST OK (31 plants with declared
  verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11
  copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version
  forms, full-pin validation and refresh retention; unplanted gate green)`; `check_pin_sites: OK — lem-pin
  e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin
  command)`. The 32 differing files are the same 32 as before (`cabs_to_ail.ml` was already a delta; its hash moved).
- **Failure-reach register (`scripts/failure_reach_register.txt`): no new row.** The new `failwithI` site is in the
  generated `Cabs_to_ail.desugar_struct_declaration`, a frontend declaration outside the register's closure (the
  drive cone's `exec_dependency`; `desugar` is in `frontEntries` — the D11 classification, its review P3-4). The
  gate on the changed tree, verbatim: `check_failure_reach: OK (240 pure failure sites = the 240 register rows exactly
  (238 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened,
  both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=44
  UNKNOWN=22; every row sealed; tally line consistent)`. Reachability from C is witnessed by the script (29 programs).
- **lem-sync stamps** re-derived by `make prelude-src lean-prelude-src` (`lean_frontend/lem_sync.sha256`: src
  `f82aeb62…`, gen `0a48dc20…`); `check_handwritten_sync: OK (56 hand-written files byte-identical to
  lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)`.
- **`scripts/upstream_oracle_differences.json`: no row** (§3.2).
- **Retired corpus control:** `tests/coverage/struct/struct-008-anon-struct.c` (`git rm`) with its row in
  `scripts/exec_coverage_baseline.txt`, the `struct` inventory line annotated (n=10 → 9, MATCH 10 → 9). Retired
  script control: `ctl_anonymous.c` of `scripts/check_union_init_refusals.sh` (§3.3). No fixture or coverage
  manifest names either (`scripts/fixture_corpus.sha256` covers `lean_frontend/corpus` only).
- **Outcome-protocol migration map** (`docs/2026-10-20_outcome-protocol-register-migration.tsv`): one UNMIGRATED
  inventory line for the new site under the same shared-desugarer mapping mover as D11's (protocol status, not a
  register row).
- `lean_frontend/CONTRACT.md`: a §3 row, the refused-parts sentence, §4.1's witness list, decision **D12**, D11's
  row/decision no longer naming the anonymous-union path as unreached, the unmigrated-site count. `VALIDATION.md`:
  §3(c) bullet, the fork ≠ pristine inventory entry, the §6 gate-table row, D11's bullet and gate row, the
  outcome-protocol sentence. `SUPPORTED.md` Domain row (the D11 carve-out replaced by the refusal). `scripts/LADDER.md`
  row 1. `scripts/test_unit.sh` runs `check_anonymous_members_refusal.sh --selftest` after the union-initializer
  script. Tray 60 ("Fork-ahead refusal" paragraph; status Draft stays — it reports upstream and asks for the
  feature), the INDEX row and paragraph. Consumer note
  `docs/2026-10-26_consumer-note-cerberus-caesium-anonymous-members-refusal.md`. `TODO.md`'s queued entry closed
  (with the pending ci-sweep re-record named). The uncertainty corpus README notes that cluster A's probes refuse.

## 6. Gates

Builds (worktree primed on Lean 4.35.0 / lem `e6d8db5`; `scripts/ce`, `CERB_MEM_MAX=32G`): the charter's first
build (dune `main.exe cerberus-lib.install`, `dune install --prefix _build/local-install cerberus-lib`, `dune build
cerberus.install`, `capped make lean-native-obj`, `capped lake build CerberusLean cerberus-lean`, speclab `capped
lake build`: `Build completed successfully (150 jobs).`), then after the `.lem` edit `make prelude-src
lean-prelude-src`, the three dune steps again (rc 0, `libc.co` restaged) and `capped lake build CerberusLean
cerberus-lean`: `Build completed successfully (408 jobs).`; freshness stamps recorded (`check_driver_fresh: recorded
oracle stamp (bin e316c150…)`, `… recorded lean stamp (bin 649cf724…)`).

Focused gates on the M1 tree: §5 (sync, fork-drift + self-test, pin sites, failure reach), §4 (the probes on both
engines), §3 (the measurement), §3.3 (the two lane movements). Focused re-checks on the M2 tree: the witness script
and its self-test (§4), the union-initializer script and its self-test (§4), Tier A row 3's command
`./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage` (rc 0):

```text
SUMMARY: total=277 match=222 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
```

(278 → 277 rows; `cerb_skip=16` as at the D11 landing: the one moved row is gone with its baseline row.)

**Tier A on the M2 tree** (`python3 scripts/release.py --mode fast` through `scripts/ce`, `CERB_MEM_MAX=32G`;
evidence `.tmp/release/20261026T195921.182532Z`, deleted after reading; 33 min). Box rule as amended by the
orchestrator during the slice (`[AGENT 2026-10-26, relayed by the operator]`: the 1-minute load threshold is 12,
not 8, because part of this box's load is external — cerberus-caesium's Lean and Rocq jobs — and the other half,
no other `release.py` on the box, stands): the run started at 1-minute load 11.07 with no other release run (above
8, noted as the amendment asks). All 20 commands PASSED (A1 938.1 s, A2 30.1 s, A3 76.1 s, A4 25.0 s, A4b 26.3 s,
A4c 3.2 s, A5 98.8 s, A6 4.1 s, A6b 3.7 s, A7 10.3 s, A8 8.6 s, A9 16.5 s, A10 18.3 s, A11 62.3 s, A12.1 5.0 s,
A12.2 4.6 s, A13 1.7 s, A14.1 116.3 s, A14.2 167.6 s, A15 399.7 s), verbatim:

```text
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```

A1 (row 1), verbatim lines: `Total: 21 passed, 0 failed`; `check_theorem_axioms: hand-written axiom census OK (0
axioms — the arc-17 S2b end state)`; `check_failure_reach: OK (240 pure failure sites = the 240 register rows exactly
(238 in the exec dependency closure + 2 unresolved-owner; …)`; `check_fork_drift: OK — layer 1: 92 oracle-surface
files = manifest (set, C-locale canonical, no duplicates); layer 2: 32 differing generated files, all hash-pinned
(…)`; `check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)`;
`check_item_g_refusals: OK (19 cases: …)`; `check_union_init_refusals: OK (26 cases: …; 11 controls agree with the
oracle (…; the anonymous-union control was retired 2026-10-26, that class now refused); …)`;
`check_anonymous_members_refusal: OK (42 cases: 29 anonymous struct/union members (…) refused by the oracle
(uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts naming the
member's kind; 10 controls with NAMED members agree with the oracle (…); the tagged-no-declarator,
typedef'd-tagged and int; constraint violations are unchanged on both)`. A3: `SUMMARY: total=277 match=222
ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0
cerb_inconsistent=0` / `BASELINE OK`. No proof module changed, so no kernel replay is owed ([USER 2026-10-18]'s
gate applies to proof-changing slices).

The M3 commit is documentation (this record, the consumer note, CONTRACT/VALIDATION/SUPPORTED/LADDER/TODO, the
tray and its INDEX, the migration map's inventory line, the corpus README): no lane input changes; the full
battery of the close-out (§6.1, appended after the run) covers the final tree.

### 6.1 The full battery at close-out (appended after the run)

Run by the orchestrator on this branch's tip `5badfe250` (`scripts/ce python3 scripts/release.py --mode full`,
started 2026-10-27 05:45:10 UTC at 1-minute load 2.31, ended 07:59:56 UTC; evidence
`.tmp/release/am-full-20261027T054510Z`, log `.tmp/am-full.log`, both the orchestrator's) after the box's external
proof campaign kept the amended load rule unmet for hours; my own 15-minute waiter of the previous evening never
launched it — its process was gone by morning, cause unknown, noted in §8. Verbatim: the log's header line, every
per-command line and the summary lines (all 44 PASSED; the slow rows B9 2282.7 s, B7 1518.6 s, A1 862.5 s,
B1 560.4 s):

```text
HEAD=5badfe250 start=05:45:10 load=2.31 out=/home/dev/projects/cerberus-lean-proj/.tmp/release/am-full-20261027T054510Z
PASSED A1 (862.5s)
PASSED A2 (30.6s)
PASSED A3 (76.9s)
PASSED A4 (24.7s)
PASSED A4b (26.3s)
PASSED A4c (3.2s)
PASSED A5 (91.2s)
PASSED A6 (4.1s)
PASSED A6b (3.7s)
PASSED A7 (10.4s)
PASSED A8 (8.8s)
PASSED A9 (16.7s)
PASSED A10 (17.0s)
PASSED A11 (62.9s)
PASSED A12.1 (5.0s)
PASSED A12.2 (4.5s)
PASSED A13 (1.7s)
PASSED A14.1 (112.3s)
PASSED A14.2 (151.4s)
PASSED A15 (366.0s)
PASSED B1 (560.4s)
PASSED B2 (23.2s)
PASSED B3 (15.0s)
PASSED B4 (45.9s)
PASSED B5 (106.4s)
PASSED B6.1 (60.1s)
PASSED B6.2 (2.3s)
PASSED B6.3 (9.4s)
PASSED B6.4 (8.8s)
PASSED B6.5 (9.3s)
PASSED B6.6 (9.9s)
PASSED B6.7 (8.8s)
PASSED B7 (1518.6s)
PASSED B8.1 (16.1s)
PASSED B8.2 (418.4s)
PASSED B8.3 (9.6s)
PASSED B8.4 (16.4s)
PASSED B9 (2282.7s)
PASSED B10.1 (185.2s)
PASSED B10.2 (1.7s)
PASSED B11.1 (23.0s)
PASSED B11.2 (7.3s)
PASSED B12 (402.3s)
PASSED B13 (463.8s)
full: passed; 44/44 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
release rc=0 end=07:59:56
```

## 7. Not done / open

- The ci-sweep scoreboard TSVs (`tests/ci_sweep/results/torture_success.tsv`, `suite.tsv`) are not re-recorded here
  (LADDER: they move only by a deliberate re-record); the two rows that will move are named in §3.2 and TODO.md.
- The texts are pre-envelope (a legacy stop under the outcome protocol); the shared-desugarer mapping mover of
  structural-outcome WP2 migrates D11 and D12 together.
- Follow-up option, not taken here (the pre-merge review's P2-1, [AGENT 2026-10-27]): the defect that ruled out
  stop form (a) is in the PORT's batch rendering — `Main.lean` prints a desugar failure as `Error {msg:
  "desugaring failed at <loc>"}` without the cause text. A Main.lean batch-rendering slice that carries the
  `Desugar_NotYetSupported` reason in the record would make D9-style frontend refusals (exit 1, attributed on
  both engines, a real `Error` record for the consumer) satisfy the charter's rule, after which D12 — and D11 —
  could move from `error` to `E.fail loc (Desugar_NotYetSupported …)` with only the one arm changing. That
  record's `msg` field is consumer-visible wire (CONTRACT §3: `--batch` is the compared interface), so the change
  belongs with the outcome protocol's WP2 mover, not this slice; registered in TODO.md.
- Tray 60 stays Draft, with its "Fork-ahead refusal" paragraph; no submission (the operator's network window).
- `__attribute__` after an anonymous member's `}` is a pre-existing parse error (§2.3), not touched.
- The survey record's cluster-A table (dated 2026-10-20) is left as the pre-refusal measurement; the corpus README
  says so.

## 8. Process notes (the box-rule wait that counted itself; the waiter that vanished)

The charter's box rule counts other `release.py` runs by a pattern over `ps` command texts. My first waits were
shell loops whose own text contained the word (in their report line), so each wait counted itself and could never
clear — the trap the item-G record's §8 describes from the other direction (a pattern matching one's own polling
shells). Found after ~50 minutes when the matches were listed with context: one was my own stale loop (killed by
its PID, verified by its text; no other process touched), the others the parallel worker's genuine Tier A. Later
waits build the pattern from pieces so their text never contains it. Noted so the next worker lists the matches
before trusting the count [AGENT 2026-10-26].

The single 15-minute waiter the orchestrator then asked for (a script in `.tmp`, polling the amended rule and
launching the battery itself) never launched it: by the next morning its sleep processes were gone with no
runner, no evidence directory and no log line after its first blocked poll. The cause is unknown (the session's
background command was presumably reaped); the orchestrator ran the battery (§6.1). Next time: a waiter that
must outlive the session is started with `nohup`/`setsid` and writes a heartbeat line per poll, so a vanished
waiter is visible as a stopped heartbeat rather than as silence [AGENT 2026-10-27].

## 10. Pre-merge review (2026-10-27, fresh independent reviewer; `docs/2026-10-27_anonymous-members-premerge-review.md`) — dispositions [AGENT 2026-10-27]

Verdict MERGEABLE WITH FIXES, documentation only; the code, generated trees, gates and baselines are untouched by
the close-out commit. One by one:

- **P2-1** (the stop form is the crash-shaped wire class; the third option — attributed `Desugar_NotYetSupported`
  rendering in the port's `--batch` path — was not weighed in §2.2): ANSWERED and recorded as a follow-up option
  (§7, TODO.md), not implemented here (the orchestrator's instruction): the port's batch `Error {msg: …}` record is
  the consumer-visible wire, so changing what it carries is the outcome protocol's WP2 mover's business.
- **P3-1** (the consumer note mixed the an-01 shape's figure into the `union`-first shape): FIXED — both shapes
  stated with their own figures.
- **P3-2** (the refusal text's attribution to the `this may be WRONG` prints overstates the link): ANSWERED, no text
  change; the precision sentence is in §1 (the prints fire on the tag's `isAnonymous` flag for every tagless
  specifier; the splice arm is a deliberate upstream reading, refused under the same ruling). Re-pinning a
  byte-identical text in two engines and four documents for a nuance is not worth a regeneration.
- **P3-3** (the uncertainty README's grep claim went stale): FIXED.
- **P3-4** (§2.2 cited the `E.catch` at pre-edit line numbers): FIXED (`:3555-3572`).
- **P3-5** (the text's parenthetical does not distinguish a typedef name resolving to a tagless struct): ANSWERED,
  no text change; the clause is in §2.3.
- The review file is committed beside this record (the union-initializer precedent).
