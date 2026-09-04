# ZERO-DISCREPANCY — slice Z2 PRE-MERGE AUDIT (2026-09-04)

Auditor [AGENT] (independent of the Z2 worker and orchestrator). Object:
branch `arc/zero-discrepancy-z2`, head `a751e748e`, 10 commits above
mainline `mdd/cerberus-lean` @ `de2fbf1bd`. Worktree read and probed (not
edited): `worktrees/cerberus-lean-arc/zero-discrepancy`. This document is
the only artefact written, on branch `audit/z2-premerge` (worktree
`worktrees/cerberus-lean-audit/z2-premerge`). Every grading below is
[AGENT]; every quoted engine/lane line is verbatim from this session's
runs on the stamped binaries; derived tallies are labelled. Every Lean
binary run went through `scripts/capped` at `CERB_MEM_MAX=16G`
(`ulimit -c 0`), lanes serially; the probe runner `tests/z2-probes/run_z2.sh`
wraps its three engines in `capped` at 4G. Nothing merged or pushed; `deps/`
read-only; the arc worktree is left as found (`git status` clean; the
`.tmp/z2` scratch the probe runner created was removed).

Binaries (the arc worktree, before anything ran):

```
check_driver_fresh: oracle OK (bin b05790f2eceefe7f53678eab3e73a3ace848a4b3b976bed41662c68dba8e0023, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)
check_driver_fresh: lean OK (bin b87125fa07d8c30ab5d083903fc2555319f10775d0e06891392e6023ebc6bd99, src 4873fc528a80e091fd08efa1ec7b165cd0f2473668eeda022b46fdc23da03985)
```

= the record §11 worker stamp and the §13 orchestrator stamp (same Lean
binary bit-for-bit). The verify lane's own `build_lean` re-recorded the
identical stamp (`recorded lean stamp (bin b87125fa07d8…, src 4873fc528a…)`).

## 0. Verdict

**MERGE-WITH-FIXES.** No MAJOR finding. The product hunks mirror the cited
OCaml (checked hunk by hunk against `impl_mem.ml`, `ocaml_implementation.ml`,
`core_parser.mly`/`core_lexer.mll`, `translation.lem`, `fs_spec.lem`,
`pp_errors.ml`, `cerb_location.ml`, `decode.ml`, `pp_symbol.ml`); the
kind-1/kind-2 partition of every landed fail-stop is consistent with the
logical-semantics ruling and with the code; the instrument pins have the
RED-then-MATCH history they claim; the two re-run lanes and 12 three-engine
probes reproduce the record's quoted lines byte for byte. The fixes are
record/manifest/cite errors (one consumer-facing) and two small parser
corners; each is listed with its remedy in §1. The operator may trim.

Findings, MAJOR → MINOR → NOTE (numbering is this document's):

| # | grade | one line |
|---|---|---|
| F1 | MINOR (must fix before merge — consumer-facing) | Record §7 and manifest §1 state `integerDiv_t`/`integerRem_t`/`integerRem_f` PANIC on a zero divisor (kind 1); the code is TOTAL (reverted in `5ed6c4a0a`), as the record's own §2.1/§2.10 say |
| F2 | MINOR | `Main.loadCoreImpl`'s in-code reachability argument ("validated in `pDefDecl → pImplConstant`") is false: `pDefDecl`/the ifun arm store the raw `<name>` without `pImplConstant`; the panic is reachable on an invalid `.impl` name (the oracle: lexer error — same failure class, wrong declaration) |
| F3 | MINOR | `CerbCall` cites `translation.lem:1082-1112` = the VARIADIC branch; the rendered shape is the non-variadic Normal_callconv branch `:1126-1155` (no trailing varargs list). Shape correct, cite wrong |
| F4 | MINOR | Charter §2.4c attributes the Z2-CP-13 mirror to `3744e8503`/`5ed6c4a0a`; it landed in `096d8930e` (record §2.7, §8.4) |
| F5 | MINOR | Record §5 derived tallies: "14 IMM incl. Z1's 4" is 13 incl. Z1's 3; "5 both-reject/not-settled + 1 duplicate + 2 wrappers" is 4 + 1 + 2 (the totals 34 / 26 / 7 hold) |
| F6 | MINOR | `CoreParser` neg-action region: `.mly:1745-1746` spans `neg ( … )`; the Lean spans the inner action only, and its comments cite the Pos arm `:1744`. Unreachable (no `neg(` in std.core/impls — grep) |
| F7 | MINOR | `CoreParser.resolveOTyTag` (CP-13) tests `__cerbty_unnamed_tag_N` by raw substring (`splitOn`) over the whole input: `…tag_5` matches inside `…tag_50`; a NAMED tag `a` (printed `a_5`) coexisting with anonymous tag 50 would intern to a non-existent symbol silently (parse-only lane; low-probability trigger) |
| N1 | NOTE | `Eccall`'s ctype pexpr is `retTy` in `mkCallSite`; the oracle's is `ctype_of e` (the fixture shows `'signed int (*) (_Bool)'`); core_run.lem:943-1017 never reads it |
| N2 | NOTE | Cite drift: record/CerberusImpl say `sizeof_ity :172-201` / `alignof_ity :214-243`; the tree has :173-204 / :214-245 |
| N3 | NOTE | `intToBytes signed val 0`: `half = 1 <<< (0-1) = 1` gives `lo = -1`; OCaml `Z.pow 2 (-1)` raises. Unreachable (sizeof ≥ 1) |
| N4 | NOTE | `test_verify.sh:130/289` discard the Lean binary's stderr (`2>/dev/null`) — PRE-EXISTING, not introduced by Z2; the rc-based crash classification stands; a Z4 instrument candidate |
| N5 | NOTE | gcc lane not re-run by the auditor (≈24 min, outside the budget); the stamped binary is bit-identical to the one the orchestrator's §13 re-run gated |

## 1. Findings in full

### F1 — record §7 / manifest §1 misstate the zero-divisor helpers (MINOR, must fix)

Record §7 `CerbMem` row: "`integerDiv_t`/`integerRem_t`/`integerRem_f`
panic on a zero divisor (same types)". Manifest §1, second bullet, lists
them under "Deliberate model fail-stops are now `panic!` where they were
values (kind 1)". The code on `a751e748e` (`lean_frontend/CerbMem.lean:1436-1443`):

```
def integerDiv_t (a b : Int) : Int := Int.tdiv a b
def integerRem_t (a b : Int) : Int := Int.tmod a b
def integerRem_f (a b : Int) : Int := Int.emod a b
```

— total, with the kind-2 note above them; the record's own §2.1 ("Fix
group 2 REVERTS the three helpers to the total `Int.tdiv`/`Int.tmod`/
`Int.emod`") and §2.10 row 1 ("REVERTED to total") agree with the code.
Re-measured this session (below, §3): `aligned_alloc(0, 8)` → `Undefined
{ub: "DUMMY(align_alloc)", …}` on Lean, i.e. the total `rem_t`. Impact: no
execution answer changes; but the consumer manifest tells refined-cerberus
a kind-1 crash exists where the definition is total and the row is a
PENDING kind-2 decision. Fix: strike the three from §7's panic list and the
manifest's kind-1 bullet; add to both "`integerDiv_t/Rem_t/Rem_f`: total
(unchanged); zero divisor is the pending §10.1 decision".

### F2 — `Main.loadCoreImpl`: false reachability argument (MINOR)

`Main.lean` (diff hunk at `loadCoreImpl`): "the name was already validated
against Implementation.impl_map when the `def <name>` declaration was
parsed (CoreParser.pDefDecl → pImplConstant, Z2-CP-08), so the error arm is
unreachable here". `CoreParser.lean:2210-2221` (`pDefDecl`):

```
  | some '<' =>
    let iCst ← lexImpl
    lexSym ":"
    …
    return (Decl.implDecl iCst (Def bTy body))
```

and the ifun arm `:2115-2121` likewise — `lexImpl` returns the raw name and
`pImplConstant` is never called on the DECLARATION path (its callers are
`pName` :914 and `pPexprAtom` :1247, the USE sites). An `.impl` file with
`def <bogus>: integer := 0` parses on Lean and reaches `panic! e` in
`loadCoreImpl`; on the oracle the lexer raises `Core_lexer_invalid_implname`
(`core_lexer.mll:218`) — both fail closed (same class), so no execution
discrepancy on the shipped impl, but the in-code argument is false. Fix:
run `pImplConstant` in `pDefDecl`/the ifun arm (the true mirror of
`scan_impl`, which validates at the LEXER for every `<…>` lexeme) and keep
`loadCoreImpl`'s arm as the now-genuinely-unreachable fail-stop; or correct
the comment.

### F3 — `CerbCall` cites the variadic branch (MINOR)

`translation.lem:1035` opens `begin if expect_is_variadic then` and the
cited `:1082-1108` is its `Normal_callconv` arm, whose `Eccall` passes
`arg_pes ++ [mk_list_pe varargs_ty_pes_type varargs_ty_pes]`. The non-variadic
arm (`:1112` `else` … `:1126-1155`) passes `arg_pes` only (`:1141-1144`),
which is what `mkCallSite` renders and what the oracle-derived fixture shows
(`tests/verify/z2_bool_param.core`: `ccall('signed int (*) (_Bool)', a_510, a_515)`;
`call_proc` core_run.lem:55 requires `|params| = |cvals|`). Shape verified
equal to `:1128-1153` (creates `mk_sseqs`, `mk_sseq_e call_ret_pat (mk_ccall_e_ …)`,
`mk_sseq_e killall_pat (mk_unseq kills) (mk_pure_e ret)`); the per-argument
create/store `:940-948` and `conv_value :915-933` (`is_integer expect_param_ty
&& is_integer arg_ty → mkcall_conv_loaded_int_`) match `argCreate`. Fix the
cite (header and `mkCallSite` doc) to `:1126-1155`.

### F4 — charter §2.4c CP-13 commit cite (MINOR)

The charter diff cites only `3744e8503` (19×) and `5ed6c4a0a` (8×); the row
"Z2-M-03/…/Z2-CP-13/… MIRRORED — Z2 `3744e8503`/`5ed6c4a0a`" covers CP-13,
whose mirror is commit `096d8930e` (`git log`: "CoreParser Z2-CP-13 —
anonymous aggregate tags resolve to ONE symbol"; record §2.7 says so).
Every other re-classed census row cites a Z2 commit that exists on the
branch (verified: 3744e8503, 5ed6c4a0a, 096d8930e, 112c0e98b, bef08dcf4,
589e3d726). Fix: add `096d8930e` to that row.

### F5 — record §5 derived tallies (MINOR)

Counted from the §5 table (lines 444-477, 34 data rows; 36 probe files =
34 + the 2 wrappers): IMM 13 (of which `(Z1)` 3: device_funptr_call,
stdout_escape, stderr_escape), COV 10, LIBC 4, VERIFY 2, REPORT 5 (3
both-reject + 1 not-settled + 1 duplicate). The text says "14 IMM incl.
Z1's 4" and "7 REPORT (5 both-reject/not-settled + 1 duplicate + the 2
wrappers)". Z2's own IMM pins are 10 (6 in `112c0e98b` + 4 in `bef08dcf4`),
so "26 integrated" = 10 + 10 + 4 + 2 holds, as does 34 = 13 + 10 + 4 + 2 + 5.
Fix the two phrases.

### F6 — neg-action region (MINOR, unreachable)

`core_parser.mly:1745-1746`: `| NEG _act= delimited(LPAREN, action, RPAREN)
{ Paction (Neg, Action (region ($startpos, $endpos) NoCursor, (), _act)) }`
— the region spans from `neg` to `)`. `CoreParser.lean` `pPaction` (neg arm)
and `pExprNeg` take `startB ← getByte` AFTER `lexKw "neg"; lexSym "("` and
`endB ← lastTokenEndByte` BEFORE `)`, i.e. the inner action's extent, and
both comments cite `.mly:1744` (the Pos arm). `grep -n "neg(" runtime/libcore/std.core
runtime/libcore/impls/*.impl` → no match, so no library node carries the
wrong region today. Fix: capture `startB` before `neg` and `endB` after `)`
(as the `undef` arm does), cite `:1745-1746`.

### F7 — `resolveOTyTag` substring test (MINOR)

`CoreParser.lean` (Z2-CP-13): `if (it.1.splitOn anon).length > 1 then
.success it (mkSym anon)` with `anon = "__cerbty_unnamed_tag_" ++ digits`.
The test is a raw substring search over the whole input: `__cerbty_unnamed_tag_5`
is a substring of `__cerbty_unnamed_tag_50`. A dump declaring anonymous tag
50 and ALSO a named `struct a` (whose OTy spelling is `a_5`, `pp_symbol.ml:5-8`)
would intern `a_5` as the undeclared `__cerbty_unnamed_tag_5` — a wrong AST
produced silently (the fail-open shape), where the fallback `stripRawSymSuffix`
would have been right. The mirror's PREMISE is verified correct
(`pp_symbol.ml:9-10` `to_string` prints every non-`SD_Id` symbol `a_N`;
`:25-29` `to_string_pretty` prints `SD_unnamed_tag` as `__cerbty_unnamed_tag_N`;
one symbol, two spellings). Reach: the parse-only `test_core.sh` C-TU dumps.
Fix: match the declaration form (`def struct __cerbty_unnamed_tag_N :=` /
`def union …`, or the already-parsed `tagDefs` names) instead of a substring;
this also removes the O(|input|) scan per struct OTy.

### Notes N1–N5

N1 `mkCallSite`: `Eccall default (PEval (Vctype retTy)) …` — the oracle's
first argument is `mk_ail_ctype_pe (ctype_of e)` (translation.lem:1131; the
fixture prints `'signed int (*) (_Bool)'`). `core_run.lem:943-1017` binds
`ty` and never reads it; `Core_typing` is not run on the rendered arena.
Unobservable; record as declared or render `ctype_of e`.
N2 cite drift in `CerberusImpl.lean`/record §2.3 (`:172-201` → `:173-204`;
`:214-243` → `:214-245`).
N3 `intToBytes` size 0 corner (above). N4 pre-existing `2>/dev/null` in
`test_verify.sh` (not a Z2 change; the lane classifies by rc). N5 gcc lane
skipped (§3).

## 2. What was checked, with evidence

### 2.1 Mirror fidelity (question 1)

`CerbMem` (every hunk read against `impl_mem.ml` at the cited lines):

* `allocator` = `:1247-1262` verbatim: `z = last_address - sz`; `(q, m) =
  quomod z align` with `quomod = ediv_rem` (`:9`) — Lean's Int `/`/`%` are
  `ediv`/`emod`; `z' = z - (if q < 0 then -m else m)` (`:1253`); `z' <= 0 →
  fail (MerrOther "Concrete.allocator: failed (out of memory)")` (`:1254-1255`,
  text mirrored); `next_alloc_id`, `last_used = Some alloc_id`,
  `last_address = addr` (`:1259-1262`). The `.max 1` clamps and the `.toNat`
  are gone (Z-13). `align = 0` → PENDING refusal (kind 2, §2.3 below).
* `allocate_object` `:1288-1347`: `size = sizeof ty` computed BEFORE the
  `req_addr_opt` match (`:1289`) ✓; `Some _ → failwith "TODO:
  cerb::with_address() is yet implemented"` (`:1293-1295`) ✓ Z-14;
  `init_opt = None` → `IsWritable` (`:1306`; `readonlyStatusForAlloc pref none
  = .IsWritable` by the simp theorem) and bytemap ← `repr (MVunspecified ty)`
  (`:1318`, funptrmap result discarded ✓); `Some mval` → readonly kind by
  prefix + `repr` threading (`:1325-1344`) ✓.
* `allocate_region` `:1420-1435`: `allocator size_n align_n`; record with
  `prefix= Symbol.PrefMalloc` unconditionally (`:1429`, the `pref` argument
  unused per `:1428`'s own TODO) ✓ Z-15; `ty= None`, `IsWritable`,
  `dynamic_addrs` prepended (`:1433`); NO bytemap write ✓ Z2-M-04 —
  `fetch_bytes :708-722` defaults an absent byte to `AbsByte.v Prov_none None`,
  which is `readBytesFrom`'s default.
* `bytes_of_int` `:1096-1113`: range `[-2^(nbits-1), 2^(nbits-1)-1]` /
  `[0, 2^nbits-1]`, `nbits > 128`, `assert false` ✓ Z-16; the Lean call
  sites pass the OCaml's signedness: `:1147 is_signed_ity ity` ✓, `:1153
  bytes_of_int true 8 (Z.of_int64 (Int64.bits_of_float fval))` → `fv.toBits.toInt64.toInt`
  with `true` ✓, `:1183`/`:1189` `false` ✓. `int_of_bytes` `:742-745` `[]`
  and `> 16` asserts ✓ (the `none`-first order matches `abst`'s
  `extract_unspec` precondition).
* `eff_array_shift_ptrval` `:2244-2356`: null → `fail ~loc MerrArrayShift`
  (`:2247-2251`, UB046 with the LOC — Z-20-style loc plumbing ✓); PVfunction
  → `failwith` (`:2252-2253`) ✓; `Prov_some`/`Prov_none`/`Prov_device`
  default arms → `PV (prov, PVconcrete (None, addr + offset))` (`:2336`,
  `:2343`, `:2346`; the union-member tag DROPPED ✓); `offset = sizeof ty *
  ival` (`:2246`, no GNU void arm — `sizeof Void` is `assert false` `:134-135`)
  ✓; the strict/PNVI arms are switch-conditioned (declared Z2-M-20 ✓). The
  evaluation-order corner (null pointer with a void element type: OCaml
  asserts, Lean UB046) is declared in-code ✓. The pure `array_shift_ptrval`
  `:2203-2221` failwith texts and the `Prov_symbolic` arm ✓ (tag kept ✓
  `:2221`).
* Z-18 `:986-994` — `aux (Z.to_int n)` builds n elements regardless of
  element size ✓ (both the live and the indexed form; the C1 equality
  theorem still closes — the build is green).
* Z-19 `:1056-1057` `MVunspecified (Ctype ([], Pointer (no_qualifiers, ref_ty)))` ✓.
* Z-20 `:2683` `get_allocation ~loc:(Cerb_location.other "Concrete.realloc")` ✓.
* Z-21 `:2065-2083`: `Void | Function _ → MerrOther "called isWellAligned_ptrval
  on void or a function type"`; `FunctionNoParams _` is a DIFFERENT
  constructor and falls to `_` ✓ (null → true, concrete → `alignof` = assert
  false `:216-218` → the Lean alignofCtype panic ✓); `modulus addr (alignof
  ref_ty)` with no clamp (`:2080`) ✓.
* Z-22 `:2175-2191` six `assert false (* CHERI only *)` ✓; reachability:
  emitted only for `AilEbuiltin (AilBCHERI _)` calls (translation.lem:2581-2628)
  and the `CivNULLcap`/`DeriveCap`/`CapAssignValue`/`Ptr_tIntValue`
  ctor/memops (core_eval.lem:690-691, :772-782) — CHERI-mode only.
  `concurRead_ival` `:2361-2362` ✓ (only defacto_memory.lem:1016 names it).
* Z2-M-08 bitwise `:2497-2511`: `Z.(sub (neg n) (of_int 1))`, `Z.logand/logor/logxor`,
  integerType ignored ✓. `zLogand/zLogor/zLogxor` identities checked by
  hand (`m & ~n = m - (m & n)`, `~m & ~n = ~(m | n)`, `m | ~n = ~(n - (n & m))`,
  `~m | ~n = ~(m & n)`, `m ^ ~n = ~(m ^ n)`, `~m ^ ~n = m ^ n`) and by the
  in-file `decide` examples; three-engine probe `bitwise_neg.c` (ten
  signed cases) → `Specified(1023)` on fork, upstream and Lean (§3).
* Z2-M-12 `:2760 assert (n = 0)` → fail-stop (was a typed kill) ✓.
* Z2-M-16 `last_used` at `:1260/:1541/:1567/:1687` ✓ (read at each).
* `targetPtrSize` → `CerberusImpl.sizeof_pointer` with the `:153-158` text ✓
  (the OCaml text is "…sizeof POINTER"; the Lean drops "sizeof POINTER" —
  EXC(a) text on an unreachable arm, not graded).
* Z2-M-01 helpers: TOTAL (see F1); `opIval IntDiv` keeps the oracle's own
  zero guard (`:2479-2480`) ✓; `IntExp` negative exponent → refusal, kind 2 ✓.
* Z2-M-19 theorems `eqIval_isSome`/… vs `:2556-2562` `Some …` ✓.

`CerberusImpl` vs `ocaml_implementation.ml:37-66`, `:154-171`, `:173-204`,
`:214-245`: `n_t_aliases` 8/16/32/64 → Ichar/Short/Int_/Long, `_ → None`
✓; `aux_ibty` arm for arm (`Option.get` → fail-stop, neutrally worded —
§10.2 ambiguous, agreed) ✓; `normalise_integerType` arms `:52-66` ✓
(`Ptraddr_t` falls to `| ity -> ity` ✓ Z2-I-02); `sizeof_ity` normalises
FIRST and the un-normalised arms are `assert false` ✓; `alignof_ity` is
textually the same table ✓; `sizeof_pointer`/`alignof_pointer = Some 8`
(`:118-122`) ✓.

`CoreParser` vs `core_parser.mly`/`core_lexer.mll`: CP-03 `MINUS _pe= pexpr`
(`:1595`) takes MINUS's precedence, `%left PLUS MINUS :1192` below
`COLON_COLON :1193`, `STAR… :1194`, `CARET :1195` → the operand extends over
`::`, `* / rem`, `^` and stops at `+ -` = `pPexprPrec 5` in the Lean table
(`opPrecInfo` :934-942) ✓. CP-04 `%nonassoc CARET` ✓ (`OpExp => (7, 8)` then
a `^` peek → refusal — exactly the strings the oracle rejects). CP-07
`escape_sequence`/`s_char` (`:257-267`) — same 11 escapes, newline
excluded, verbatim concatenation (`:296`) ✓. CP-08 `scan_impl` (`:209-218`):
`impl_map` lookup FIRST, then `<builtin_` prefix, else error — same order
in `pImplConstant`; `impl_map` keys carry the angle brackets (28 entries,
generated/Implementation.lean:340) ✓. CP-09 the five `wrapI_*`/`catch_…_*`
keywords `:119-128` ✓. CP-11 `def_fields` non-empty `:1759-1761`, union
`xs @ [last]` `:1775-1777`, `start: nonempty_list(declaration)` `:1215-1217`,
`"_" → UNDERSCORE :328` ✓. CP-13 premise ✓ (pp_symbol.ml, F7 for the test).
CP-15 `:773 SeqRMW (b, pe1, pe3, sym, pe3)` drops pe2 ✓ (declared, tray).
CP-16/CP-21 `:83-84` `Fvfromint`/`Ivfromfloat` keywords vs the pp's `C…`
spellings ✓. CP-17 narrowing premise: `tests/libc/libc.core` has `glob
builtin` (1) and `alloc:` parameters (103 occurrences) — the full keyword
table would indeed refuse the pin ✓. None of CP-03/04/07/08/09/11/16/18 is
a refusal where the oracle would PARSE: each refused string is a
`Parser.Error`/lexer error on the oracle. Z-01 Pos row: `PEundef` at
`:1571` `region ($startpos, $endpos)` — Lean `getByte` before the `undef`
token, `$endpos` just after `)` ✓; Pos action `:1744` ✓; column = `1 +
pos_cnum - pos_bol` (`util/cerb_position.ml:23-25`) ✓; neg arm: F6. Probes
of std.core-raised UBs (§3: `1 / x` UB045a, `7 % x` UB045b, `1 << -1`
UB051a) print byte-identical C-site locs on all three engines and no
`std.core` position appears in any batch line.

`CerbCall`: F3/N1 for the cites; the rendered site performs
`conv_loaded_int('T', n)` exactly as `:922` (`stdlib.mkcall_conv_loaded_int_`
= `mk_call "conv_loaded_int"` translation_aux.lem:347-348, resolved in the
linked `stdlib`) ✓; errno first (`allocErrno` before `callFinish`, as
`drive` driver.lem:1860-1868) ✓; refusals attributed ✓. Evidence: the
verify lane (§3) `127 passed, 0 failed`, rows `z2_bool_param f 2 → Specified(1)`,
`z2_errno_order f 1 → Specified(65524)` = the oracle-run wrapper TUs.

`CerbFS` lseek: `fs_spec.lem:5075` EBADF, `:5084` EINVAL for an unmapped
int whence, checked before the offset computation (`:5105-5119`) ✓.
`CerbLocation` cursor suffix: `cerb_location.ml:219-223` (`~shrink:true` =
`line:col`, `:189-191`) ✓; `Loc_regions (xs, _)` prints NO cursor on the
oracle (`:224`) and the Lean `.regions` arm adds none ✓; `outer_bbox []`
`:105-106` assert ✓; `regions []` failwith `:33-36` ✓ (refused at
`CabsImport.jsonToLoc`). `Main.driverErrorBatchMsg` = `pp_errors.ml:499-509`
text for text ✓ (`pp_id` = `to_string_pretty` = `CerbMem.ppSymbol`).
`CerbDecode`: `decode.ml:7-8` (kind 2, refusal) ✓; `wrapChar` range from
`impl.is_signed_ity Ctype.Char` (`:206-210`) ✓. `CerbStepInstances`:
`driver.lem:1376/1410` compare only against `Step_blocked2` ✓ (unreachable,
mirrored anyway). Every `-- DECLARED (zero-discrepancy Z2-…)` reachability
argument read against its callers: Z2-M-06 (`driver.lem:689/702/714` store
into the trace) ✓; Z2-M-17 (`:698-702` tool stderr) ✓; Z2-M-20 switch arms
✓; Z2-F-03 (unlink/rename with an open fd REFUSE — CerbFS header rows) ✓;
Z2-Q-01 ✓; Z2-I-04 ✓; Z-14 (`cerb::with_address` is fork-only:
`cerb_attributes.lem:30`) ✓; the ONE false argument is F2.

### 2.2 Instrument integrity (question 2)

`git log -p de2fbf1bd..a751e748e -- tests/immaculate/baseline.txt`, rows
only (verbatim):

```
### 112c0e98b … pin the Z2 audit's confirmed Lean!=oracle reproducers RED before the fixes
+zd-z2cp01-strtod-inf DIFF | L=ERR:{msg: "Unresolved_symbol: Symbol(_, 13557763317115745599, _) at unknown location"}
+zd-z2f01-lseek-whence DIFF | L=CRASH
+zd-z2i01-cerbty-int32-uac DIFF | L=CRASH
+zd-z2m01-aligned-alloc-zero-nolibc ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", stderr: "", loc: "<7:28--7:47>"}
+zd-z2m01-aligned-alloc-zero ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", stderr: "", loc: "<9:28--9:47>"}
+zd-z2m01-aligned-alloc-zero-zero ORACLE_CRASH | L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
### 3744e8503 … fix group 1
+zd-z2cp01-strtod-inf MATCH | L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
+zd-z2f01-lseek-whence MATCH | L=VAL:{value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
+zd-z2i01-cerbty-int32-uac MATCH | L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
+zd-z2m01-aligned-alloc-zero MATCH | L=CRASH
+zd-z2m01-aligned-alloc-zero-nolibc MATCH | L=CRASH
+zd-z2m01-aligned-alloc-zero-zero MATCH | L=CRASH
### 5ed6c4a0a … Z2-M-01 kind-2 mirror REVERTED
+zd-z2m01-aligned-alloc-zero-nolibc ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", stderr: "", loc: "<8:28--8:47>"}
+zd-z2m01-aligned-alloc-zero ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", stderr: "", loc: "<12:28--12:47>"}
### bef08dcf4 … probe integration
+zd-z2f04-closedir MATCH | L=CRASH
+zd-z2fl03-nan-to-int MATCH | L=CRASH
+zd-z2-free-funptr MATCH | L=ERR:{msg: "MerrOther "attempted to kill with a pointer lacking a provenance""}
+zd-z2m03-malloc-oom-msg MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
```

RED-then-MATCH holds for the three fixed rows; the Z2-M-01 trio moves
exactly as record §6 says (the `-zero-zero` row stays `MATCH | L=CRASH`
from `3744e8503` — same token, different cause after the revert; its pin
header says so verbatim: "a coincidence of failure class, not agreement").
The third pair is honest under §1.2(a): a Lean refusal (exit 134) where the
oracle crashes (exit 125) is the same failure class, and the header names
the refusal's pending status. The pinned locs differ from the record's
probe locs (`<12:28>` vs `<8:28>`, `<8:28>` vs `<4:28>`) because the pin
files carry longer headers — not a discrepancy. Coverage rows (10, 8 MATCH
+ 2 UB_MATCH), libc_exec rows (4 MATCH), verify fixtures (oracle-derived
`.core`, 6 rows — the lane re-run below is the check that the pins equal
the wrapper TU), gcc ledger rows (SKIP_LEAN_CRASH / SKIP_GCC_COMPILE /
SKIP_UB — plausible classes for a both-crash, a `__cerbty_*` spelling gcc
does not know, and a DUMMY-UB Lean verdict), uri baseline (the
`LEAN_NOLIBC:` line changes text only, `Error` → `Error`, exit 1 → 1;
verdict class unmoved) — all as recorded. Changed scripts: the only
addition to a gate script is the comment block in `test_immaculate.sh`'s
`--record-baseline` header; `grep` of the Z2 diff of `scripts/` and
`tests/z2-probes/run_z2.sh` for `2>/dev/null`/`|| true` finds only two
`grep … || true` in the non-gating probe runner (`run_z2.sh:91-92`), whose
verdict logic reports empties as `*-NONE`, never `AGREE`.

### 2.3 Kind classification (question 3)

Every `panic!` ADDED by the slice (grep of the diffs) with its OCaml and
kind [AGENT]:

| site | OCaml | kind | disposition | agree? |
|---|---|---|---|---|
| `allocateObject` `reqAddrOpt = some` | `failwith "TODO: cerb::with_address()…"` :1293-1295 | 1 | mirrored | yes |
| `intToBytes` range/`> 128`; `bytesToInt` `[]`/`> 16` | `assert false` :1105-1109; :742-745 | 1 | mirrored | yes |
| CHERI ×6 + `cheriPointerHashPrintf` | `assert false (* CHERI only *)` :2175-2191 | 1 | mirrored | yes |
| `concurReadIval` | `failwith "TODO: concurRead_ival"` :2361-2362 | 1 | mirrored | yes |
| `vaList` n ≠ 0 | `assert (n = 0)` :2760 | 1 | mirrored (was a typed kill — the correct direction under Q4) | yes |
| pure `arrayShiftPtrval` Prov_symbolic/null/PVfunction; `effArrayShiftPtrval` PVfunction | `failwith` :2209-2219; :2252-2253 | 1 | mirrored | yes |
| `sizeof_ity`/`alignof_ity` un-normalised arms | `assert false` :188-202/:231-243 | 1 (unreachable after normalisation) | mirrored | yes |
| `aux_ibty` width ∉ {8,16,32,64} | `Option.get None` :40-44 | ambiguous → §10.2 | fail-stop, neutral text | yes (either reading gives no meaning; a value here would be the MAJOR shape) |
| `outerBbox []`; `Loc_regions []` (CabsImport `err`) | `assert false` :105-106; `failwith` :33-36 | 1 | mirrored | yes |
| `targetPtrSize` `none` | `failwith` :153-158 | 1 | mirrored (impossible on DefaultImpl) | yes |
| `Main.loadCoreImpl` `.error` | `Core_lexer_invalid_implname` (lexer error) | 1-shaped (parse rejection) | fail-stop | yes; F2 for the reachability text |
| `allocator` `align = 0` | `Division_by_zero` in `quomod` :1252 | 2 | NOT mirrored — refusal "no meaning", pending §10.1 | yes |
| `opIval IntExp` n2 < 0 | `Z.to_int` + `Z.pow` `Invalid_argument` :2490 | 2 | NOT mirrored — refusal (was the fail-open `.toNat`) | yes |
| `decode_integer_constant ""` | `str.[0]` `Invalid_argument` :7-8, 18 | 2 | NOT mirrored — refusal (was `(Decimal, 0)`) | yes |
| `CerbFS.fs_write`/`fs_pwrite` vanished path | (no SibylFS twin; model invariant) | — | refusal replacing `getD []` (fail-closed) | yes |

Kind-2 sites the slice did NOT mirror and left total: `integerDiv_t/Rem_t/Rem_f`
on 0 (`Division_by_zero` via std.core:385 — pinned ORACLE_CRASH, §10.1);
memcmp negative size (`Z.to_int` :2660, declared Z2-M-13, R3 admitted by
class). No kind-2 panic mirror remains in the seams; no kind-1 crash became
a value (Z1's `casePtrval`/dead-free panics untouched; the pre-Z2 value
stubs for CHERI/concurRead/`va_list` all became fail-stops).

### 2.4 Record integrity (question 4)

Re-run quoted lines (§3): all 8 record-quoted engine lines reproduce (§1
rows for aligned_alloc ×3 incl. the `PANIC at CerbMem.allocator CerbMem:2035:6`
text, strtod_inf 10×, cerbty_int32_uac, lseek_whence; §2.6 malloc_oom_msg).
§6 movements = `git log -p` (above). §0/§5 tallies: F5. Charter cites: F4;
every other re-classed row cites an existing Z2 commit; the two rows without
a commit cite (Z2-FL-01/…, Z-61) are verification/doc rows with no code
change. Manifest vs §7: consistent with each other and both wrong on the
same point (F1); otherwise the manifest's signature table matches §7 and
the diffs (`intToBytes signed`, `pImplConstant : … → Except`, `stampLibraryFile
(file input) cf`, `callFinish` re-typed, deletions as listed). §8 errata:
#1 (F-01 Lean column) consistent with Z1's Z-27 commit; #3 (CP-21) and #4
(CP-13) verified by reading the pp/lexer and `test_core.sh tests/ci`; #5
(CP-17) premise verified (`glob builtin`, `alloc:` ×103 in the dump); #2,
#6 are statements about prior work, not re-verified beyond the Z1 record.

## 3. Lane re-runs and probes (verbatim)

```
### CERB_MEM_MAX=16G ./scripts/capped ./scripts/test_verify.sh START 2026-09-04T02:49:13Z load=17.76 5.86 5.32
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
### ./scripts/test_verify.sh rc=0 (81s)
### CERB_MEM_MAX=16G ./scripts/capped ./scripts/test_immaculate.sh …
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
### ./scripts/test_immaculate.sh rc=0 (58s)
```

(An earlier attempt to run `test_verify.sh` WITHOUT `capped` was refused by
the lane itself — `env not loaded: run via scripts/ce or source scripts/env.sh`,
rc 2 — fail-closed as designed; the run above is the capped one.)

`tests/z2-probes/run_z2.sh` (fork / upstream `deps/cerberus-upstream`, read-only
/ Lean; backtraces cut; the 12 libc metadata jsons regenerated by
`scripts/libc_prep.sh --jsons` into the audit worktree's scratch, 1 s):

```
##### tests/z2-probes/mem/aligned_alloc_zero_nolibc.c (nolibc)
--- FORK-ORACLE exit=125   cerberus: internal error, uncaught exception: Division_by_zero … Called from Cerb_frontend__Impl_mem.Concrete.op_ival in file "memory/concrete/impl_mem.ml", line 2482
--- UPSTREAM exit=125      (identical)
--- LEAN exit=1            Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<4:28--4:47>"}
##### tests/z2-probes/impl/cerbty_int32_uac.c (nolibc)
--- FORK-ORACLE / UPSTREAM / LEAN exit=0   Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
=== cerbty_int32_uac.c: AGREE
##### tests/z2-probes/mem/aligned_alloc_zero.c (libc)
--- FORK-ORACLE / UPSTREAM exit=125  Division_by_zero
--- LEAN exit=1            Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<8:28--8:47>"}
##### tests/z2-probes/mem/aligned_alloc_zero_zero.c (libc)
--- FORK-ORACLE / UPSTREAM exit=125  Division_by_zero
--- LEAN exit=134          PANIC at CerbMem.allocator CerbMem:2035:6: CerbMem.allocator: alignment 0 has no meaning in the model (impl_mem.ml:1252 quomod raises Division_by_zero — an OCaml-execution artifact, not the referent); operator decision pending, zero-discrepancy Z2 record §10
##### tests/z2-probes/coreparser/strtod_inf.c (libc)
--- FORK-ORACLE / UPSTREAM / LEAN exit=0   EXECUTION 0..9: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"} (×10 each)
=== strtod_inf.c: AGREE
##### tests/z2-probes/fs/lseek_whence.c (libc)
--- FORK-ORACLE / UPSTREAM / LEAN exit=0   Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
=== lseek_whence.c: AGREE
##### tests/z2-probes/mem/malloc_oom_msg.c (libc)
--- FORK-ORACLE / UPSTREAM / LEAN exit=1   Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
=== malloc_oom_msg.c: AGREE
```

Auditor probes (nolibc; sources in this document's scratch, reproduced here):

```
bitwise_neg.c   int main(void) { int a = -6, b = 3, c = -3, d = 5;
                  return ((a & b) == 2) + ((a & c) == -8) * 2 + ((d & -1) == 5) * 4
                       + ((a | b) == -5) * 8 + ((a | c) == -1) * 16 + ((d | -8) == -3) * 32
                       + ((a ^ b) == -7) * 64 + ((a ^ c) == 7) * 128 + ((d ^ -1) == -6) * 256
                       + ((~a) == 5) * 512; }
--- FORK-ORACLE / UPSTREAM / LEAN exit=0   Defined {value: "Specified(1023)", stdout: "", stderr: "", blocked: "false"}   === AGREE
float_signbyte.c  union { double d; unsigned char c[8]; } u; u.d = -1.5; int x = -1; unsigned char *p = (unsigned char*)&x; return u.c[7] * 1000 + p[0];
--- FORK-ORACLE / UPSTREAM / LEAN exit=0   Defined {value: "Specified(191255)", stdout: "", stderr: "", blocked: "false"}   === AGREE
div_zero_loc.c    int main(void) { int x = 0; return 1 / x; }
--- FORK-ORACLE / UPSTREAM / LEAN exit=1   Undefined {ub: "UB045a_division_by_zero", stderr: "", loc: "<1:36--1:41>"}   === AGREE
rem_zero_loc.c    int main(void) { int x = 0; return 7 % x; }
--- FORK-ORACLE / UPSTREAM / LEAN exit=1   Undefined {ub: "UB045b_modulo_by_zero", stderr: "", loc: "<1:36--1:41>"}   === AGREE
shl_neg_loc.c     int main(void) { int s = -1; return 1 << s; }
--- FORK-ORACLE / UPSTREAM / LEAN exit=1   Undefined {ub: "UB051a_negative_shift", stderr: "", loc: "<1:37--1:43>"}   === AGREE
```

The three UB probes are raised inside std.core procedures (the elaborated
`/`, `%`, `<<` guards) and print the substituted C-site loc on every engine;
no `std.core` position appears in any batch line.

gcc second-oracle lane: NOT re-run by the auditor (≈24 min, over the ~1 h
budget). The gated binary is bit-identical (stamp `b87125fa07d8…`) to the
one the orchestrator re-ran in record §13 (`SUMMARY: total=1963 … disagree=0`,
`Baseline check: 0 regression(s), 0 improvement(s)`, `gcc second-oracle lane OK`).

## 4. Not checked

* The gcc lane (above). Tier A exec/coverage/debug/float, bytes, libc_exec,
  multi_tu, parse/core/elab, uri, cn_coverage, libxml2, speclab and plant
  lanes — not re-run here (the worker's §11 and the orchestrator's §13 on
  the same binary stand; the audit re-ran the two lanes the slice's fixes
  bear on most directly).
* `CerbCall`'s refusal texts were not exercised (no fixture has a non-integer
  parameter or a non-`int` return).
* The `Z2-N-02` single-verdict precondition of the immaculate/libc_exec
  lanes (oracle default `Random` vs Lean `--first`) — a standing instrument
  note, not a Z2 change.
* `CerberusFresh` digest ORDER claim (Z-64) taken from the record's grep
  argument; not re-grepped.
* Whether `AilBCHERI` builtins can be desugared outside CHERI mode (the
  Z-22 reachability rests on the frontend gating those names); read only
  to the `translate_expr` arms.
* Every probe run was under 10 minutes; none was killed.

## 5. Provenance

[AGENT] (auditor): every grading, reading, probe, tally and text here.
[USER 2026-09-03]: the rule and exception classes, the Q4 interim rule and
the kind-1/kind-2 referent ruling that the gradings apply (quoted from the
charter and the two ruling documents, not restated). Quoted outputs are
verbatim from this session (`.tmp/audit/lanes/*.log` in the audit worktree,
ephemeral); derived tallies are labelled. Nothing merged or pushed; the arc
worktree, `deps/`, the primary checkouts and global state untouched.
