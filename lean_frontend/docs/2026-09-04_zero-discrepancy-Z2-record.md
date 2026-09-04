# ZERO-DISCREPANCY — slice Z2 record (FIX PHASE), 2026-09-03/04

Branch `arc/zero-discrepancy-z2` (worktree `worktrees/cerberus-lean-arc/zero-discrepancy`),
base `cc4d42dd6` = mainline `mdd/cerberus-lean` @ `de2fbf1bd` + the two Z2 docs
commits (the READ-PHASE audit `docs/2026-09-03_zero-discrepancy-Z2-audit.md` with
`tests/z2-probes/`, and `docs/2026-09-03_typed-failure-outcomes-ruling.md`).
Work order: the audit's §5, the charter's §3 Z2 mandate and §2.2/§2.7 rows
(`docs/2026-09-03_zero-discrepancy-design.md`), the Z1 record's §7 hand-offs and
§10 Z-01 Pos row (`docs/2026-09-03_zero-discrepancy-Z1-record.md`). Author: the
Z2 fix-phase worker [AGENT]; every ruling cited is [USER 2026-09-03] as
recorded in the charter §1/§7 and the typed-failure ruling; every
classification, measurement and text here is [AGENT]. Quoted engine lines
are verbatim from this worktree's runs; tallies are labelled derived.

THE RULE applied throughout ([USER 2026-09-03], charter §1.1): every
Lean-vs-oracle EXECUTION difference on a program both engines run in matched
mode is a bug → mirror the OCaml with a `file:line` cite; exceptions only (a)
failure message text, (b) resource limits where the oracle also fails / fuel,
(c) missing features behind a LOUD attributed refusal, (d) the ISO-fix
register. "Unreachable today" is not a class: every divergence in the Lean
text is either MIRRORED or DECLARED IN CODE with its reachability argument
next to it. Q4 / the typed-failure INTERIM RULE: a one-sided oracle crash is
mirrored as a `panic!` carrying the OCaml text, never as a typed `Error` —
NARROWED mid-slice by [USER 2026-09-03] ("ocaml limits that are hardcoded
thanks to ocaml-level execution issues are also forbidden, the real thing
is the logical semantics", `docs/2026-09-03_logical-semantics-referent-ruling.md`,
branch `docs/no-magic-values`): KIND 1, a `failwith`/`assert` the MODEL
writes deliberately → still mirrored (Q4); KIND 2, an OCaml-execution
artifact (`Z.Overflow`/`Failure` from host-int conversions,
`Division_by_zero` from a missing guard, `Stack_overflow`) → NOT
mirrored — Lean implements the model's logical meaning at that point, the
case gets a tray note and a visible immaculate pin; an ambiguous case goes
to the decisions list, not a guess. Fix group 1 had landed one KIND-2
mirror (Z2-M-01) before the update arrived; it is REVERTED in fix group 2
and every landed fail-stop is classified by kind in §2.10.

Binaries. Start of slice: `check_driver_fresh: oracle OK (bin 0a7728ed83d010f16962957c658ed47761648d4dede13bc75ad218787495973d, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)` /
`check_driver_fresh: lean OK (bin ba5a7ec0229f9a9c9d0964add550e14eeb289ec5a5ee2d03ee67c78daaf20b80, src 9e8574f24e59a6e94cdfa4921fa6e49490a1ee6397ff0c0f30382ae0c96008cc)`
(the mainline tree's binaries; every pre-fix measurement below is on them).
Fix group 1 build: `lean OK (bin 4acbd33af626ad46ab3631551d98772736b090be1228f06b710b2386555803e9, src 5f38e981608b58659302d61952fc596c5bd8dd56851afd88b4c33ddcbc42e8e5)`.
Fix group 2 build: `lean OK (bin 880011fe009e700e3ae6a5d756ee3d483550c8277c816f3f30853ffca1e99bc0, src 011faa8bc52090b1f2607e3f1c45eba5186587caebeee75276b1f3efc0320d41)`;
the oracle's SOURCE hash is `c9c1a706…` throughout (the oracle binary was
re-linked by the lanes' `build_cerberus`, bin hashes `04bf8163…`/`d815e53c…`,
same sources). Every Lean/lake invocation through `scripts/capped`,
`CERB_MEM_MAX=32G`; lanes SERIAL; box load 1.9–3.4 at the measurements
(≈ 8–16 earlier in the session, other agents).

Third engine: un-forked `deps/cerberus-upstream` @ `b9aeedcb4`, read-only,
via `tests/z2-probes/run_z2.sh` (fork / upstream / Lean). Findings are
claims: every row's probe was re-run on the stamped pre-fix binaries before
any code changed (§1); one audit row's Lean side had MOVED (§1, Z2-F-01).

## 0. Headline (derived)

* Commits on the branch above `cc4d42dd6`: §9.
* Rows disposed IN CODE: every Z2 audit row (§2.1–§2.17: Z2-M-01…M-20,
  Z2-N-01…N-04, Z2-P-01…P-08, Z2-L-01…L-03, Z2-C-01…C-05, Z2-F-01…F-07,
  Z2-D-01, Z2-U-01/02, Z2-G-01/02, Z2-I-01…I-04, Z2-FL-01…FL-03, Z2-DC-01,
  Z2-T-01, Z2-CP-00…CP-20, Z2-J-01/02, Z2-Q-01/02) and the charter's Z2
  assignments (Z-13…Z-23, Z-59…Z-66, Z-70, Z-71, the Z-01 Pos row) — each
  MIRRORED with a `file:line` cite or DECLARED in code with its
  reachability argument (§2). One NEW row found by the fix phase:
  Z2-CP-21 (§2).
* Confirmed Lean≠oracle rows fixed: Z2-CP-01 (+ Z2-CP-21, found by the fix
  phase on the same path), Z2-I-01, Z2-F-01, Z2-C-01, Z2-C-02 — each pinned
  RED at the current Lean value before its fix and MATCH after (§6).
  Z2-M-01 (×3 witnesses) is a KIND-2 oracle crash under the mid-slice
  [USER 2026-09-03] logical-semantics ruling: its fix-group-1 mirror is
  REVERTED, the rows stay pinned as visible ORACLE_CRASH / both-crash
  pairs, and the logical meaning is an operator decision (§2.1, §10.1).
* Probe integration: all 34 audit probes evaluated (§5): 6 immaculate pins
  from the confirmed rows + 4 new immaculate pins (2 MATCH, 2 MATCH|CRASH),
  10 nolibc exec rows (`tests/coverage/z2/`), 4 libc_exec rows, 2 verify
  fixtures (6 call-point rows), 8 reporting-only (both-reject / not
  settled / duplicates of standing pins).
* API-visible changes for the in-process consumer: §7.
* Decisions for the operator: §10. Errata candidates: §8.

## 1. Findings are claims — the pre-fix measurements (stamped mainline binaries)

`tests/z2-probes/run_z2.sh` (fork oracle `--exec --batch --mode=exhaustive`,
upstream likewise, Lean `--batch` [+ `--libc`]); backtraces cut to the
exception line.

```
##### tests/z2-probes/mem/aligned_alloc_zero.c (libc)
--- FORK-ORACLE exit=125   cerberus: internal error, uncaught exception: Division_by_zero
                           Raised at Z.rem in file "z.ml", line 96 … Called from Cerb_frontend__Impl_mem.Concrete.op_ival in file "memory/concrete/impl_mem.ml", line 2482
--- UPSTREAM exit=125      (identical)
--- LEAN exit=1            Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<8:28--8:47>"}
##### tests/z2-probes/mem/aligned_alloc_zero_zero.c (libc)
--- FORK-ORACLE / UPSTREAM exit=125  Division_by_zero (same site)
--- LEAN exit=0            Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
##### tests/z2-probes/mem/aligned_alloc_zero_nolibc.c (nolibc)
--- FORK-ORACLE / UPSTREAM exit=125  Division_by_zero
--- LEAN exit=1            Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<4:28--4:47>"}
##### tests/z2-probes/coreparser/strtod_inf.c (libc)
--- FORK-ORACLE exit=0     EXECUTION 0..9: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"} (×10)
--- UPSTREAM exit=0        (identical)
--- LEAN exit=0            EXECUTION 0..9: Error {msg: "Unresolved_symbol: Symbol(_, 13557763317115745599, _) at unknown location"} (×10)
=== strtod_inf.c: LEAN!=ORACLE
##### tests/z2-probes/impl/cerbty_int32_uac.c (nolibc)
--- FORK-ORACLE / UPSTREAM exit=0  Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
--- LEAN exit=134          PANIC at _private.LemLib.0.failwithIImpl LemLib:158:2: AilTypesAux.le_integer_range: internal error
##### tests/z2-probes/fs/lseek_whence.c (libc)
--- FORK-ORACLE / UPSTREAM exit=0  Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
--- LEAN exit=134          PANIC at CerbFS.fs_lseek CerbFS:475:8: CerbFS refusal (fail-closed fs-model boundary): lseek on fd 3 with whence 7 — SibylFS answers EINVAL for an invalid whence; this model silently kept the offset; answering would differ from the oracle's SibylFS (CerbFS.lean header; mover: real per-fd offset semantics)
--- LEAN --call f --call-args 2 (bool_param)     Undefined {ub: "UB012_lvalue_read_trap_representation", stderr: "", loc: "<6:25--6:26>"}   rc=1
--- ORACLE wrapper (bool_param_wrapper.c)         Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
--- LEAN --call f --call-args 1 (errno_order)    Defined {value: "Specified(65528)", stdout: "", stderr: "", blocked: "false"}   rc=0
--- ORACLE wrapper (errno_order_wrapper.c)        Defined {value: "Specified(65524)", stdout: "", stderr: "", blocked: "false"}
```

Verdict per row: Z2-M-01 CONFIRMED (three witnesses; the Lean loc now
carries the C site since Z1's Z-01 — the audit quoted `unknown location`);
Z2-CP-01 CONFIRMED; Z2-I-01 CONFIRMED; Z2-C-01/C-02 CONFIRMED;
**Z2-F-01: the Lean side MOVED since the audit** — the audit recorded
`Specified(13)` (the `| _ => entry.offset` arm); Z1's Z-27 commit had turned
that arm into a loud attributed REFUSAL before Z2 started, so the pre-fix
state pinned here is `DIFF | L=CRASH`, not the audit's `DIFF | L=VAL`. Not
an erratum of the audit (it measured `046e5cdd4`, pre-Z1), but the row's
"Lean" column is stale on the current tree — recorded as §8.1. The EINVAL
mirror is the right fix either way (a refusal is class (c); the SibylFS
answer is cheaply mirrorable).

## 2. The rows, in order of execution impact (reproducer · oracle · Lean before · mirror · Lean after)

Line cites: Lean = this branch after the fix commits; OCaml = this tree
(impl_mem.ml byte-identical to upstream through :2998).

### 2.1 Z2-M-01 — `aligned_alloc(0, n)`: `op_ival IntRem_t` on a zero divisor — KIND 2, NOT mirrored; operator decision (§10.1)

Reproducer: `void *p = aligned_alloc(0, 8); return p != 0;` (libc and
nolibc; `aligned_alloc(0, 0)` the third witness). Oracle (fork AND
upstream): uncaught `Division_by_zero` raised at `Z.rem` from
`Concrete.op_ival` (impl_mem.ml:2482), exit 125. Mechanism:
`runtime/libcore/std.core:385` `if size rem_t align = 0` in
`aligned_alloc_proxy` has NO UB045 guard; `impl_mem.ml:11 let integerRem_t
= (mod)` = `Z.rem`, `:12 integerRem_f = Big_int_Z.mod_big_int`, both raise
on 0; `:2481-2484` call them unguarded (`IntDiv` alone has the explicit
zero guard, `:2479-2480`). The CerbMem doc that claimed the zero divisor
"unreachable behind Core's division-by-zero UB guards (UB045)" was FALSE
and is rewritten either way.
History inside this slice: fix group 1 (`3744e8503`) mirrored the crash
as `panic! "Division_by_zero"` (three witnesses both-crash, immaculate
`MATCH | L=CRASH`). The [USER 2026-09-03] logical-semantics ruling then
classified this crash as KIND 2 (a missing guard = an OCaml-execution
artifact) and the orchestrator directed: do NOT land the mirror, leave the
code as is, decide the logical meaning with the operator, pin the current
behaviour visibly. Fix group 2 REVERTS the three helpers to the total
`Int.tdiv`/`Int.tmod`/`Int.emod` of the mainline, with the KIND-2 note and
the pins cited in code. Current Lean behaviour (re-measured, §1 lines +
post-revert):

```
aligned_alloc(0, 8)   libc    oracle Division_by_zero exit 125 | Lean Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<8:28--8:47>"}   (0 rem_t 8 ≠ 0 → the proxy's DUMMY UB)
aligned_alloc(0, 8)   nolibc  oracle Division_by_zero exit 125 | Lean Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<4:28--4:47>"}
aligned_alloc(0, 0)   libc    oracle Division_by_zero exit 125 | Lean PANIC at CerbMem.allocator CerbMem:2035:6: CerbMem.allocator: alignment 0 has no meaning in the model (impl_mem.ml:1252 quomod raises Division_by_zero — an OCaml-execution artifact, not the referent); operator decision pending, zero-discrepancy Z2 record §10   exit 134
```

(`0 tmod 0 = 0` passes the proxy's test and `alloc(0, 0)` reaches the new
`allocator`, whose alignment-0 arm is a loud PENDING-DECISION refusal —
`quomod` raising there is kind 2 too, and the `.max 1` clamp that stood
there was the fail-open shape — so the third witness is a both-crash of
DIFFERENT causes, recorded as such.) Pins: `zd-z2m01-aligned-alloc-zero`,
`-nolibc` ORACLE_CRASH | L=UB:DUMMY(align_alloc); `-zero-zero` MATCH |
L=CRASH — the pin headers and the immaculate header template say the row is
pending. Tray candidate for Z4 (the missing UB045 guard at std.core:385).
The decision itself: §10.1.

### 2.2 Z2-CP-01 (+ Z2-CP-21, NEW) — `inf` and `Cfvfromint` in the pinned libc dump — commit `3744e8503`

Reproducer: `double d = strtod("1e5000", 0); return d > 1e308;` (libc).
Oracle: 10 × `Defined {value: "Specified(1)", …}`; Lean before: 10 ×
`Error {msg: "Unresolved_symbol: …"}` (§1). Mechanism: `pp_core.ml:279-282`
prints an `OVfloating` with `string_of_float`, which renders +∞ as the
identifier-shaped `inf` (`tests/libc/libc.core:53897/53906/64081/64090`
`pure(Specified(inf))`, proc `decfloat`'s overflow path); the OCaml Core
grammar has no float literal at all (`core_lexer.mll:290-291`) and the
oracle never re-reads its dump (it runs the in-memory `libc.co`), so
`CoreParser.lean` lexed `inf` as a symbol.
Mirror (`CoreParser.lean` `pPexprAtom`, `pPexprMinus`): `inf`/`nan` in atom
position → `PEval (Vobject (OVfloating ±∞/NaN))`; `-inf`/`-nan` in
`pPexprMinus` → the negative value (not `0 - inf`); `lexSymId` refuses a
BINDER named `inf`/`nan` (tripwire). NaN sign/payload are not recoverable
from the text (declared in the comment).
After the `inf` fix the same probe moved to `Error {msg: "Illformed_program:
calling an unknown function"}`: **Z2-CP-21 (new row)** — the pp spells the
ctors `Cfvfromint`/`Civfromfloat` (`pp_core.ml:367-370 pp_datactor`) where
the lexer's keywords are `Fvfromint`/`Ivfromfloat` (`core_lexer.mll:83-84`);
the dump carries the pp spelling at 29 sites (`:53901 Specified(Cfvfromint(a_26866) * a_26867)`),
which the parser read as a call to an unknown function. Mirror: the ctor
arms accept both spellings (`pCtorName`, `pPexprAtom`) — the oracle's AST
holds `PEctor Cfvfromint`. Upstream pp/lexer mismatch: tray candidate. The
whole `pp_ctor` table was compared against the keyword table: only these
two differ.
Lean after: `=== strtod_inf.c: AGREE` (10/10 `Specified(1)`); immaculate
`zd-z2cp01-strtod-inf` DIFF → MATCH.

### 2.3 Z2-I-01 / I-02 / I-03 / I-04 — `CerberusImpl.normalise_integerType` — commit `3744e8503`

Reproducer: `__cerbty_int32_t s = -1; unsigned int u = 1; return (s + u) == 0;`
(nolibc). Oracle (both): `Specified(1)`; Lean before: `PANIC … AilTypesAux.le_integer_range: internal error`
(§1). Mechanism: `ocaml_implementation.ml:37-66 Common.normalise_integerType_`
aliases `IntN_t/Int_leastN_t/Int_fastN_t` through `type_alias_map`
(`:154-171`: 8→Ichar, 16→Short, 32→Int_, 64→Long, `_ → None` then
`Option.get` raises) and `Intmax_t/Intptr_t → Long`; the Lean had no such
arm, so `ailTypesAux.lem:302-303`'s `(Signed (IntN_t _), _) -> fail ()`
arms became reachable on Lean through the direct `__cerbty_*` spellings
(the shared `<stdint.h>` aliases `int32_t` to plain `signed int`, so
ordinary C was unaffected — the three header-route probes AGREE).
Mirror (`CerberusImpl.lean`): `n_t_aliases`, `aux_ibty` (`Option.get None`
→ fail-stop, Z2-I-03 — KIND ambiguous, §10.2), `normalise_integerType` arm for arm (:52-66,
`Ptraddr_t` kept as `| ity -> ity` — Z2-I-02: the old `.Ptraddr_t → Unsigned
Long` arm computed where the oracle's shared model then errors);
`sizeof_ity`/`alignof_ity` normalise FIRST (`:172-201`/`:214-243`) with the
`assert false` arms as fail-stops; the per-width `sizeof_integerBaseType`
(a fail-open size for EVERY width) is deleted. Z2-I-04: `alignof_ty`'s
`none` fail paths DECLARED (Ail typing rejects the shapes; the `none` is
consumed by CerbMem's own panics).
Lean after: `=== cerbty_int32_uac.c: AGREE`; immaculate `zd-z2i01-cerbty-int32-uac` DIFF|L=CRASH → MATCH.

### 2.4 Z2-C-01 / C-02 / C-03 / C-04 / C-05 (charter Z-60) — the `--call` harness entry — commit `3744e8503`

Reproducers: `int f(_Bool b) { return b; }` with `--call f --call-args 2`
(wrapper `int main(void) { return f(2); }`); `int f(int x) { return (int)((long)&x & 0xffff); }`
with `--call-args 1`. Oracle wrapper: `Specified(1)` / `Specified(65524)`;
Lean before: UB012 trap / `Specified(65528)` (§1).
Disposition ([USER] Z-60 rule "refuse loudly or convert exactly as the
elaborated call site does"; the orchestrator's brief: "read translation.lem's
call-site elaboration"): `CerbCall.lean` is REWRITTEN to RENDER the
elaborated call site — `mkCallSite` builds what `translate_call` emits for
`f(<int literals>)` under `Normal_callconv` (translation.lem:940-975 the
per-argument `create` at `alignof` with a `PrefFunArg` prefix + `store` of
`conv_loaded_int('T', n)` — the SAME std.core function the oracle calls,
`stdlib.mkcall_conv_loaded_int_` translation_aux.lem:347-348, resolved in
the linked file's `stdlib` — bound by `wseq`; `:1126-1155` (the NON-variadic `Normal_callconv` branch of `if expect_is_variadic` :1035; the variadic branch :1082-1108 appends a varargs list — pre-merge audit F3 corrected the cite) `mk_sseqs` of the
creates, `mk_sseq_e` of the `Eccall` on the LOADED function-pointer value
(core_run.lem:944 matches `Vloaded (LVspecified (OVpointer pv))`), the
`killall` unit/tuple pattern, `mk_unseq` of the `pkill (Static ty)`s,
`mk_pure_e` of the result), with `errno` allocated FIRST as `drive` does
(driver.lem:1860-1868; Z2-C-02). Helper shapes cited from core_aux.lem
(`pcreate`/`pstore` :521-530, `mk_alignof_pe` :367-368, `mk_ail_ctype_pe`
:328-329, `mk_wseq_e` :2098, `mk_sseqs` :758-765, `mk_unseq` :788-792).
Refusals (Z2-C-03/C-05, attributed `kill`s): a non-integer parameter type,
a return type other than `signed int` (the wrapper's `int main` returns the
value unconverted only then), an argument-count mismatch. Declared: the
actions' location is `other "CerbCall.driveCall"` (the wrapper's is the
wrapper TU's call site — visible only on a UB raised BY the create/store of
a fresh temporary, i.e. never); `PrefFunArg`'s digest is the TU's (Z2-C-04:
prefix observable only through the trace-only `prefix_of_pointer`); the
argument-pointer binders are `f`'s own parameter symbols (the elaborator
draws fresh ones — `Eccall` pushes a fresh env frame, so no lookup is
ambiguous) and the result binder is `f`'s symbol (dead after the final
`pure`); the wrapper's constant-true `cfunction` UB038/UB041 checks
(translation.lem:1041-1064) are not rendered.
Lean after: `Defined {value: "Specified(1)", …}` and `Defined {value: "Specified(65524)", …}`
= the wrappers; `test_verify.sh` stays **117 passed, 0 failed** on the
existing 43 call-point rows under the new protocol (§6), and gains the two
fixtures `tests/verify/z2_bool_param.c`, `z2_errno_order.c` (oracle-derived
`.core` pins; rows `f 0/1/2/-7 → Specified(0/1/1/1)`, `f 1/-7 → Specified(65524)`,
oracle values measured on the rendered wrappers before pinning).

### 2.5 Z2-F-01 (+ F-02…F-07 cross-check) — `CerbFS.fs_lseek` invalid whence — commit `3744e8503`

Reproducer: `lseek(fd, 0, 7) + 10` (libc). Oracle: `Specified(9)` (EINVAL,
−1); Lean before: the Z1 refusal (§1; the audit's `Specified(13)`).
Mirror: `fs_spec.lem:5084 | Nothing -> Error EINVAL (* posix/lseek.md
EINVAL:1 *)` — whence ∉ {0,1,2} (SEEK_DATA/SEEK_HOLE have no int code,
`:5100`) is EINVAL right after the fd lookup (`:5075` EBADF) and BEFORE any
size/offset work; the `CerbFS.lean` header table row is split accordingly.
Lean after: `=== lseek_whence.c: AGREE`; immaculate `zd-z2f01-lseek-whence` DIFF|L=CRASH → MATCH.
Cross-check of the audit's residual list against Z1's table: F-02 (SEEK_END
with the fd's file gone) — Z1 REFUSES (kept); F-03 (`getD []` in
`fs_write`/`fs_pwrite`) — the path cannot vanish under an open fd since Z1's
unlink/rename refusals, so the `getD` defaults are replaced by REFUSALS
(fail-closed, never a default); F-04 `closedir` — both-crash, pinned
`zd-z2f04-closedir` MATCH|L=CRASH (§5); F-05 (`fs_write` ignoring `size`)
— already mirrored by Z1 (`abs size` bytes, refusal past the buffer); F-06
literals — `umask := 0o022` VERIFIED = SibylFS's initial
`pps_file_creation_mask= File_perm 0O022` (fs_spec.lem:5716); `mode`/`nlink`
are unobservable (stat/lstat refused); F-07 (`unlink` of a missing path →
0) — already ENOENT since Z1.

### 2.6 The CerbMem §2.2 rows Z-13…Z-23 and the Z2-M-* dispositions — commit `3744e8503`

All in `CerbMem.lean`; each hunk cites its impl_mem.ml lines.

| row | disposition |
|---|---|
| Z-13 / Z2-M-05 | MIRRORED: new `allocator` = impl_mem.ml:1247-1262 verbatim on Int (`z = last_address - sz`; `quomod = ediv_rem` :9 — Lean's Int `/`/`%`; `z' ≤ 0` → the OOM Error; `next_alloc_id`, `last_used`, `last_address`); the `.max 1` clamps and the `.toNat` negative→0 are gone (`Allocation.size` is `Int`, a negative size flows through as in OCaml). `align = 0`: `quomod` raises `Division_by_zero` on the oracle — KIND 2, NOT mirrored; the model gives alignment 0 no meaning → a loud PENDING-DECISION refusal (§10.1), never the fail-open clamp |
| Z-14 | MIRRORED: `req_addr_opt = Some _` → `panic! "TODO: cerb::with_address() is yet implemented"` (:1293-1295); reachability: fork-only attribute |
| Z-15 | MIRRORED: `allocate_region` records `PrefMalloc` unconditionally (:1429, the `pref` argument unused per `:1428`) |
| Z-16 | MIRRORED: `bytes_of_int`'s range/`nbits > 128` assert (:1105-1109) as a fail-stop — `intToBytes` gains the OCaml's signedness argument (call sites :1147 `is_signed_ity ity`, :1153 `true` on the signed int64 reading of the float bits, :1183/:1189 `false`); `int_of_bytes`'s `[]`/`> 16` asserts (:742-745) likewise |
| Z-17 | MIRRORED: `effArrayShiftPtrval` PORTED (:2244-2356 default-switch arms: null → `fail ~loc MerrArrayShift` UB046, PVfunction → failwith fail-stop, concrete → `PVconcrete (None, addr + sizeof ty * ival)` — the union-member tag DROPPED, no GNU void arm); the pure `arrayShiftPtrval` gets the OCaml failwith texts and the `Prov_symbolic` arm (:2203-2221). Evaluation-order note declared (`sizeof void` before the null match) |
| Z-18 | MIRRORED: the zero-sized-element `MVarray []` short-circuit removed (:986-994 builds n elements) — in the live AND the indexed reference form (the C1 equality theorem still closes) |
| Z-19 | MIRRORED: unspecified pointer → `MVunspecified (Ctype [] (Pointer no_qualifiers ref_ty))` (:1056-1057) |
| Z-20 | MIRRORED: realloc's `get_allocation ~loc:(other "Concrete.realloc")` (:2683) |
| Z-21 / Z2-M-09 / Z2-M-10 | MIRRORED: one MerrOther message (:2067-2069); `FunctionNoParams` falls to the `_` arm (null → `true`; concrete → `alignof` = `assert false` :216-218 → alignofCtype's panic); no `.max 1` (:2080) |
| Z-22 | MIRRORED: `derive_cap`/`cap_assign_value`/`null_cap`/`ptr_t_int_value`/`get_intrinsic_type_spec`/`call_intrinsic` → `assert false (* CHERI only *)` fail-stops (:2175-2191); `cheriPointerHashPrintf` (no concrete-model body) likewise |
| Z-23 | RE-CITED: `padding_byte` :1200 → :1202 (the other five sites were already correct in-tree) |
| Z2-M-02 | landed in Z1 (`c61b78f70`); re-witnessed both-crash (§1 nolibc run: `PANIC at CerbMem.casePtrval CerbMem:1313:4: case_ptrval`) |
| Z2-M-03 | MIRRORED: OOM text `"Concrete.allocator: failed (out of memory)"` (:1255) |
| Z2-M-04 | MIRRORED: `allocateRegion` writes NO bytemap bytes (:1420-1435; `fetch_bytes` :708-722 defaults absent bytes exactly as `readBytesFrom`) — `malloc_oom_msg.c` now RUNS on Lean and AGREES: `Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}` on both (pinned) |
| Z2-M-06 | DECLARED: `prefix_of_pointer` not ported — callers driver.lem:689/702/714 store into the trace only |
| Z2-M-07 | MIRRORED: `concurRead_ival` → `panic! "TODO: concurRead_ival"` (:2361-2362) |
| Z2-M-08 | MIRRORED: bitwise ops = pure two's-complement on unbounded Z (:2497-2511; `zLogand/zLogor/zLogxor` on Nat with the standard identities, `decide`-checked on signed examples; Lean 4.32 core has no `Int.land`); the `| none => 4` defaults deleted (literal census #3) |
| Z2-M-11 | DECLARED: the layout family's Nat arithmetic vs Z (alignment 0 / negative sizes unreachable: alignof ≥ 1, `_Alignas` front-end validated, `empty_struct.c` UB061 on all engines) |
| Z2-M-12 | MIRRORED: `va_list`'s `assert (n = 0)` (:2760) → fail-stop (was a typed MerrOther kill) |
| Z2-M-13 | DECLARED: memcmp's `toNat` on a negative size (OCaml non-terminates, :2652-2660); memcpy runs zero iterations on both |
| Z2-M-14 / M-15 | doc integrity: the stale "typeof_enum stub" text rewritten; the false "device ranges empty" comments were already deleted by Z1 |
| Z2-M-16 | MIRRORED: `last_used` written at allocator (:1260), kill (:1541), load (:1567), store (:1687) (Z1 audit N2) |
| Z2-M-17 | DECLARED: `is_atomic_member_access`'s two TOOL-stderr printfs (:698-702) |
| Z2-M-18 | already declared (ill-typed store printfs) |
| Z2-M-19 / Z-59 | TRIPWIRE: theorems `eqIval_isSome`/`ltIval_isSome`/`leIval_isSome` (`cases; rfl`) — the premise of CerbND's no-`NDguard` argument |
| Z2-M-20 | DECLARED: the seven switch-conditioned arms + the `is_PNVI` arms, with the audit §2.9 default table |
| IntExp | KIND 2 (`Z.to_int n2` + `Z.pow`'s `Invalid_argument` on a negative exponent, impl_mem.ml:2490): NOT mirrored as such; the model gives `^` no meaning at a negative exponent, so the fail-open `.toNat` clamp is replaced by a loud refusal; unreachable behind the shift guards (declared) |

### 2.7 CoreParser rows Z2-CP-02…CP-20 and the Z-01 Pos row — commit `5ed6c4a0a`

| row | disposition |
|---|---|
| Z-01 Pos row (Z1 §10) | MIRRORED for the two behaviour-bearing node classes: `PEundef` (core_parser.mly:1571) and `Action` (:1744/:1746) carry the OCaml's exact `region ($startpos, $endpos)` line/column — byte-offset markers captured at parse time (`getByte`, `lastTokenEndByte`, `markerLoc`), resolved in `stampLibraryFile` against the input's newline table (`lineTable`/`resolveByte`: line = `pos_lnum`, column = `1 + pos_cnum - pos_bol`, util/cerb_position.ml:23-25, BYTES) — and ERASED back to `unknown` by `parseFile` (the `--libc` dump keeps the recorded Z1-A1 behaviour). Verified by an in-Lean probe over std.core: `undef ../runtime/libcore/std.core:201:15--201:52 (in rev_listFromStr_aux)` = line 201 `        pure (undef(<<DUMMY(rev_listFromStr_aux)>>))` (undef at column 15, `$endpos` 52), `undef 263:13--263:46 (any_bounded_int)`, `action 245:25--245:50 (create_and_store)`, … 140 marked nodes; `parseFile`: 138 nodes, all `unknown`. DECLARED residual: every OTHER node's region stays `⟨file, 0, 0⟩` (file-only) — only its FILE component is consulted (`is_library_location`); the edge where a std.core position itself would print (a library-located UB whose context carries no C location) is now exactly covered; no C-reachable instance exists (the driver runs no std.core code before main's first C-located node — `prepare_main_args`/globals/errno are memory actions with `Loc.other` locs, not std.core procs) |
| Z2-CP-02 | DECLARED INSTRUMENT boundary at `lexNumLit`: `%.12g` lossiness of the pin (Z4 measurement / `libc_prep.sh` exact printer) |
| Z2-CP-03 | MIRRORED: unary minus operand at the precedence of `MINUS` (`pPexprPrec 5`; .mly:1192-1197) |
| Z2-CP-04 | MIRRORED (fail-closed): chained `^` refused (`%nonassoc CARET` :1195) |
| Z2-CP-05 / CP-06 | DECLARED with the grammar contrast (`%nonassoc ELSE` :1118; `%right SEMICOLON` :1134 — layout-blind) |
| Z2-CP-07 | MIRRORED: string literals keep escapes VERBATIM, only the mll escape set, newline refused (core_lexer.mll:257-274, :296-297) |
| Z2-CP-08 | MIRRORED (fail-closed): `pImplConstant` = `scan_impl` (mll:209-219) over the GENERATED `Implementation.impl_map` + the `builtin_` rule, `Except` error otherwise; the hand table's fail-open tail is gone (literal census #19); `Main.loadCoreImpl` consumes the `Except` |
| Z2-CP-09 | MIRRORED (fail-closed): exact `_add/_sub/_mul/_shl/_shr` suffixes (mll:119-128); `_div`/`_rem_t` (pp-printable, pp_core.ml:418-419, lexer-unknown — upstream mismatch) refused |
| Z2-CP-10 | DECLARED, NO CHANGE: the GRAMMAR is the mirror target — `pcall(f)`/`pcall(f, pe…)` (.mly:1656-1659, no empty-list-with-comma form), `builtin sym (bTys) : eff bTy` (:1812), `PtrMemberShift[sym, .cid]` (:1635) — the Lean already mirrors it; the pp forms (`pcall(f, )` :636, `builtin sym (bTys)` :786-788, no dot :70-71) are upstream pp/grammar mismatches (tray candidates), absent from every corpus |
| Z2-CP-11 | MIRRORED (fail-closed): union keeps a trailing `T x[]` member (.mly:1775-1777); `def_fields` non-empty (:1759-1761); empty file refused (:1215-1217); bare `_` in pexpr position refused (mll:328); `ensureListBTy` DECLARED (the pp's `[]: <elem>` form, pp_core.ml:464, ×3 in the dump) |
| Z2-CP-12 / CP-20 | DECLARED in the G6 section (by-name interning, no scoping; binder uniqueness probed on the dump) |
| Z2-CP-13 | MIRRORED (after a Tier B finding): fix group 2 first landed a TRIPWIRE refusing the `a_<digits>` spelling in OTy position ("no Core text this parser loads has one") — `test_core.sh tests/ci` then went RED on `0042-struct_namespace.c` and `0308-struct_global_with_dep.c`: the oracle's `--pp core` dump of a C TU with an anonymous aggregate prints the tag `a_504` in object-type position (`let strong a_516: loaded struct a_504 = …`) and `__cerbty_unnamed_tag_504` in ctype/member_shift position (`pp_symbol.ml:5-10 to_string` vs `to_string_pretty`) — ONE symbol in the oracle's AST. `resolveOTyTag` now interns an OTy `a_N` as the file's declared `__cerbty_unnamed_tag_N` when that name occurs in the input (every dump declares its aggregates first), else as the named tag `a` via the ordinary suffix strip — the two spellings become the same symbol, as on the oracle; the pre-Z2 parser conflated every anonymous tag to `a` and split it from its ctype-position symbol (wrong AST, never executed: the parse-only lane is the sole consumer of C-TU dumps). Commit `096d8930e` |
| Z2-CP-14 | = Z-01 (Z1) |
| Z2-CP-15 | DECLARED + tray candidate: the ORACLE's grammar action drops `pe2` of `seq_rmw` (.mly:767-774); the Lean is the faithful form; unreachable (the dump's 199 seq_rmw are pp → Lean, matching the oracle's in-memory AST) |
| Z2-CP-16 | MIRRORED: the missing `translate_builtin_typenames` spellings (builtins.lem:11-69 via .mly:1331-1338): `int128_t`, `int_least/fast{8,16,32,64}_t` (+u), `wchar_t`, `wint_t`, `ptraddr_t`; `byte` (pp_core_ctype.ml:89-90) |
| Z2-CP-17 | TRIPWIRE, NARROWED: only the VALUE keywords `True`/`False`/`Unit` are refused as binder names — the full keyword table would refuse the libc pin (the pp prints symbols plain: the dump has `glob builtin` and 57 parameters named `alloc`), and only the value keywords change a program's meaning silently in atom position |
| Z2-CP-18 | DELETED: the dead `Cfunction_value` and `Ivmax_alignment` (= 16) value arms |
| Z2-CP-19 | confirmed declared (`Cfunction(sym)` → real function pointer; the oracle's action punts to null) |
| Z2-CP-21 (NEW) | MIRRORED: `Cfvfromint`/`Civfromfloat` (§2.2) |

### 2.8 The remaining seams — commit `5ed6c4a0a`

| row | seam | disposition |
|---|---|---|
| Z-59 / Z2-N-03 | `CerbND.lean` | header and the `NDguard`/`NDbranch` comments rewritten: "unreachable by construction" with the corrected argument (addConstraints ← PEconstrained ← `Nothing` from eq/lt/le_ival, total `Some` :2556-2562; the NDbranch producer's empty constraints) and the CerbMem tripwire theorems; the "recorded divergence — survey finding 23" REVOKED |
| Z2-N-01 | — | trace ORDER verified identical (order3/order2/order_ptreq re-run AGREE, §5); pinned as coverage rows |
| Z2-N-02 | `CerbND.lean` | already documented (`--first` = branch 0 = the LAST printed execution; the oracle's default mode is Random) — INSTRUMENT note; the lanes' single-verdict precondition is stated in the record (§10 decision 3) |
| Z2-N-04 / Z-73 | — | declared by Z1 (RULED Q8 = A) |
| Z2-P-04 / Z2-L-01 | `CerbLocation.lean` | MIRRORED: the `" (cursor: …)"` suffix of `location_to_string` (cerb_location.ml:219-223, `~shrink:true` = `line:col`) |
| Z2-P-05 | `Main.lean` | MIRRORED: `driverErrorBatchMsg` = `Pp_errors.string_of_core_run_cause` (pp_errors.ml:499-509) text for text (`ill-formed program: \`…'`, `found an empty stack: \`…'`, `reached the end of a procedure`, `unknown implementation constant`, `unresolved symbol: <to_string_pretty sym> at <location_to_string loc>`) — the embedded symbol NUMBER differs by construction (Z-04/tray 17). EXPECTED MOVEMENT: the uri lane's pinned `LEAN_NOLIBC` line (§6) |
| Z2-P-06 / Z-74 | — | declared by Z1 |
| Z2-P-08 | `Main.lean` | DECLARED: the oracle's `Time spent:` tool-stderr line |
| Z2-L-02 | `CerbLocation.lean` | DECLARED (`posLt` column vs `pos_cnum`); `outer_bbox []` → fail-stop (assert false :109-110); `CabsImport.jsonToLoc` refuses an empty `Loc_regions` (Cerb_location.regions failwith :33-36) |
| Z2-L-03 | — | already declared (structural `Ord Loc`) |
| Z2-G-01 | `CerbGlobal.lean` | DECLARED (`execMode := none` vs `Some Exhaustive/Random`; one live read, equivalent; mode flags refused) |
| Z2-G-02 | `CerbGlobal.lean` | DECLARED INSTRUMENT: the dead `no_integer_provenance` constructor KEPT (it is the lem target_rep of global.lem:82, whose OCaml twin names a constructor absent from switches.ml — lem-side inconsistency, tray candidate); no generated reference |
| Z2-U-01 | `CerbDebug.lean` | DECLARED EXC(a): `print_unsupported` (cerb_debug.ml:43-45) — tool stderr on both-crash paths |
| Z2-U-02 | `CerbUtils.lean` | DECLARED: `bounded_integer` returns `lo`; the oracle's own value is a `Random.self_init` draw (cerb_any.ml:1-9) — no matchable oracle value exists |
| Z-62 | `CerbFloat.lean` | DECLARED unreachable by construction (`Ord Float` referenced only from the unlinked defacto/Float modules; no float-keyed set in the exec cone) |
| Z-63 | `CerbDecode.lean` | disposed by the audit (caller set); Z2-DC-01: the empty-constant `str.[0]` raise (decode.ml:7-8, the author's own "TODO: this explodes") is KIND 2 — NOT mirrored as such; an empty constant has no meaning in the model → loud refusal (was the fail-open `(Decimal, 0)`), fork-only reachability, listed §10.3; literal census #8: `wrapChar`'s char range now READ from `CerberusImpl.is_signed_ity .Char0` (decode.ml:204-210) |
| Z-64 / Z2-D-01 | — | grep audit of the exec-cone `.lem` (driver, core_run, core_run_aux, core_eval, core_reduction, core_linking, mem, core_aux, translation, cabs_to_ail) for `Map.fold/bindings/toList/domain`, `Set.toList/elements/fold`: two hits, both order-INSENSITIVE set membership tests (core_linking.lem:276 `Set.null (Set.intersection (Map.domain m1) (Map.domain m2))`, driver.lem:277 `Map.domain dr_st.core_file.tagDefs`); the digest-VALUE difference (cabs-json vs .c) therefore reaches no order-sensitive iteration on the exec path. Declared in the CerberusFresh header's terms (unchanged) |
| Z-65 | `CerberusImpl.lean` | entry-by-entry table committed in-code as the §2.3 mirror (`n_t_aliases`, `normalise_integerType`, `sizeof_ity`/`alignof_ity`, `sizeof_pointer`/`alignof_pointer`, `is_signed_ity ~char_is_signed:true`, `sizeof_fty`/`alignof_fty` 8/8/8, the enum registry) — every arm cites its ocaml_implementation.ml line |
| Z-66 | — | confirmed by the audit (debug level 0 in matched mode); literal census #9 declared at `CerbDebug.get_level` (unchanged) |
| Z-70 | `CabsImport.lean` | holds (audit); Z2-J-01/J-02 DECLARED in the header (fork-side OCaml bridge — the `failwith`/escape remedies are oracle-surface changes for Z4/tray) |
| Z-71 / Z2-Q-01 | `CerbStepInstances.lean` | MIRRORED: `ctype.beq_derived` named explicitly for the two ctype comparisons (OCaml poly `=` is structural); unreachable (driver.lem:1376/1410 compare only against `Step_blocked2`) |
| Z2-Q-02 | `CerbFunMapInstances.lean` | SETTLED + DECLARED: `Core_typing.typecheck_program` iterates fun maps by KEY (`Lem_Map_extra.fold`/`mapMapM`), never builds a (key, value) set — no value comparator resolved there |
| Z2-T-01 | `Main.lean` | SETTLED + DECLARED: lem `union` (`fmapUnionBy` → `Pmap.union`, pmap.ml:290-294, mirrored by LemLib.lean:981) keeps the SECOND map's datum on a duplicate key; Lean's libc name-join REFUSES on disagreement — equal on the pinned 12 TUs (the lane loads), a loud load failure where the oracle would silently pick |
| Z2-FL-01 / FL-02 | — | refuted / not evidenced by the audit; pinned as coverage/libc_exec rows (§5) |
| Z2-FL-03 | — | landed in Z1; the both-crash pin `zd-z2fl03-nan-to-int` added (§5) |

### 2.9 Literal census (audit §3, 22 sites)

| # | site | disposition |
|---|---|---|
| 1 | `CoreParser` IvMaxAlignment | fixed by Z1 (Z-76); the dead `Ivmax_alignment` = 16 arm deleted here (CP-18) |
| 2 | `CerbMem.targetPtrSize` | ROUTED: reads `CerberusImpl.sizeof_pointer` (new mirror of ocaml_implementation.ml:117-121), `none` → the impl_mem.ml:153-158 failwith text |
| 3 | `CerbMem` bitwise `| none => 4` | DELETED (Z2-M-08: the OCaml is width-free) |
| 4 | `CerbMem` OOM text | MIRRORED (Z2-M-03) |
| 5 | `CerberusImpl.max_alignment` | agrees; cite added (:151-152) |
| 6 | `CerberusImpl` size/align literals | the IntN_t aliasing MIRRORED (Z2-I-01); every arm cites its line |
| 7 | `CerberusImpl.is_signed_ity Char0 => true` | agrees (`~char_is_signed:true`, :257); unchanged |
| 8 | `CerbDecode.wrapChar` char range | ROUTED through `CerberusImpl.is_signed_ity .Char0` (decode.ml:204-210) |
| 9 | `CerbDebug.get_level := 0` | DECLARED (matched mode; `-d` is a refused flag) |
| 10 | `CerbGlobal` config/switch literals | DECLARED (Z-24 refusal; Z2-G-01/G-02 notes) |
| 11–15 | `Main.lean` impl path / `std.core` / `Normal_callconv` / concurrency `false` / `fs_initial_state` | DECLARED at the batch header (each is the oracle's default under the refused flag set: `--impl` default main.ml:350, `SW_inner_arg_temps` pipeline.ml:32-35, pipeline.ml:266-267, main.ml:308, pipeline.ml:597-599) — no change; the refusal (Z-24) is the guard |
| 16 | `Main.lean` `stderr: ""` on desugar/typing UB | same literal as main.ml:170/177 — agrees |
| 17 | `CerbFS` literals | `umask 0o022` VERIFIED = fs_spec.lem:5716; `nextFd := 3` embedded only in a both-crash text (closedir pin, EXC(a)); `mode`/`nlink` unobservable (stat refused); O_* bits verified by the audit |
| 18 | `CerbCall` errno literals | the ORDER mirrored (Z2-C-02); same literals as driver.lem:1860-1868 |
| 19 | `CoreParser` hand tables | `<impl>` names → the generated `impl_map` (CP-08); `wrapI_*` suffixes exact (CP-09); operator precedence table unchanged (verified = .mly:1189-1195) |
| 20 | `CoreParser` `loc0`/`annots0` | Z-01 (Z1) + the Pos row (§2.7): PEundef/Action positions exact, the rest file-only, declared |
| 21 | fuel budgets | EXC(b), unchanged |
| 22 | `CerbConcurrency.statically_satisfied := true` | Z-25 (EXC(c)), unchanged |

### 2.10 Every fail-stop this slice landed, classified by KIND (the logical-semantics ruling)

| site | OCaml failure | kind | disposition |
|---|---|---|---|
| `integerDiv_t/Rem_t/Rem_f` zero divisor | `Division_by_zero` from a missing guard (impl_mem.ml:2481-2484 via std.core:385) | 2 | REVERTED to total; pins visible; decision §10.1 |
| `allocator` `align = 0` | `Division_by_zero` in `quomod` (:1252) | 2 | pending-decision refusal (no meaning); §10.1 |
| `opIval IntExp` negative exponent | `Z.to_int` + `Z.pow` `Invalid_argument` (:2490) | 2 | refusal (no meaning; unreachable) |
| `decode_integer_constant ""` | `str.[0]` `Invalid_argument` (decode.ml:7-8, "TODO: this explodes") | 2 | refusal (no meaning; fork-only reach); §10.3 |
| `aux_ibty` width ∉ {8,16,32,64} | `Option.get None` on the model's own alias table (ocaml_implementation.ml:39-44) | ambiguous | fail-stop kept, neutrally worded; §10.2 |
| `allocateObject` `req_addr_opt = Some _` (Z-14) | `failwith "TODO: cerb::with_address() is yet implemented"` (:1293-1295) | 1 | mirrored |
| `intToBytes` range / `nbits > 128`; `bytesToInt` `[]`/`> 16` (Z-16) | `assert false` (:1105-1109; :742-745) | 1 (per the orchestrator's update) | mirrored |
| CHERI intrinsics (Z-22) | `assert false (* CHERI only *)` (:2175-2191) | 1 | mirrored |
| `concurReadIval` (Z2-M-07) | `failwith "TODO: concurRead_ival"` (:2361-2362) | 1 | mirrored |
| `vaList` index ≠ 0 (Z2-M-12) | `assert (n = 0)` (:2760) | 1 | mirrored |
| `effArrayShiftPtrval` PVfunction; pure `arrayShiftPtrval` null/PVfunction/Prov_symbolic (Z-17) | `failwith` (:2252-2253; :2211-2219) | 1 | mirrored |
| `sizeof_ity`/`alignof_ity` un-normalised arms | `assert false` (ocaml_implementation.ml:188-200) | 1 (unreachable after normalisation) | mirrored |
| `outerBbox []`; `Loc_regions []` | `assert false` (cerb_location.ml:109-110); `failwith` (:33-36) | 1 | mirrored (Lean side refuses at construction) |
| `casePtrval`, dead-allocation free (Z1) | `failwith` (:1814; :1532) | 1 | mirrored (Z1) |
| memcmp `Z.to_int size_n` (R3) | `Z.Overflow` (:2660) | 2 | not mirrored (declared by Z1/audit; register R3 "admitted by class" per the ruling — VALIDATION.md text is Z4's) |

## 3. Z1 §7 hand-offs (cross-reference only)

§7.1 libc-body UB locations (mover S–M, Z4/follow-up): untouched; note
that `parseFile` now ERASES the position markers for the dump, so the
libc bodies print exactly as before. §7.2/§7.5/§7.6 instrument widenings:
Z4. §7.3/§7.4 charter errata: recorded by Z1. §7.7: same-hunk rows — the
remaining §2.2 rows are disposed here (§2.6).

## 4. In-code declarations added by this slice (the grep-able set)

`-- DECLARED (zero-discrepancy Z2-…)` / `DECLARED (zero-discrepancy Z-…)`
markers: CerbMem (Z2-M-06, M-11, M-13, M-20), CoreParser (Z2-CP-02, CP-05,
CP-06, CP-11 ensureListBTy, CP-12/CP-20, CP-15, the Z-01 residual),
CerbLocation (Z2-L-02), CerbGlobal (Z2-G-01, G-02), CerbUtils (Z2-U-02),
CerbDebug (Z2-U-01), CerbFloat (Z-62), CerbStepInstances (Z2-Q-01 note),
CerbFunMapInstances (Z2-Q-02), Main (Z2-T-01, Z2-P-08), CerberusImpl
(Z2-I-04), CabsImport (Z2-J-01/J-02). `grep -n "zero-discrepancy Z2-" lean_frontend/*.lean`
enumerates every row's in-code disposition.

## 5. Probe integration table (all 34 audit probes)

Lanes: IMM = `tests/immaculate` (`--first` vs oracle single run, whole-payload
tokens), COV = `tests/coverage/z2` (nolibc exec lane, `scripts/exec_coverage_baseline.txt`),
LIBC = `tests/libc_exec`, VERIFY = `tests/verify` call-point rows, REPORT =
stays in `tests/z2-probes/` only.

| probe | audit class | lane | recorded class | pinned? |
|---|---|---|---|---|
| mem/aligned_alloc_zero.c | Z2-M-01, KIND 2 (ruling) | IMM libc `zd-z2m01-aligned-alloc-zero` | ORACLE_CRASH \| L=UB:DUMMY(align_alloc) — PENDING (§10.1) | yes |
| mem/aligned_alloc_zero_zero.c | Z2-M-01, KIND 2 | IMM libc `zd-z2m01-aligned-alloc-zero-zero` | MATCH \| L=CRASH — both-crash of different causes (oracle artifact / Lean pending refusal), PENDING | yes |
| mem/aligned_alloc_zero_nolibc.c | Z2-M-01, KIND 2 | IMM nolibc `zd-z2m01-aligned-alloc-zero-nolibc` | ORACLE_CRASH \| L=UB:DUMMY(align_alloc) — PENDING | yes (+ gcc ledger row) |
| mem/aligned_alloc_bad_size.c | AGREE (control) | LIBC `008-aligned-alloc-bad-size.c` | MATCH (Undefined line byte-equal) | yes |
| mem/aligned_alloc_3.c | AGREE (control) | LIBC `009-aligned-alloc-3.c` | MATCH | yes |
| mem/free_funptr.c | Z-07 re-witness | IMM libc `zd-z2-free-funptr` | MATCH (Error class) | yes |
| mem/device_funptr_call.c | Z2-M-02 | IMM nolibc `zd-z2m02-device-funptr-call` (Z1) | MATCH \| L=CRASH | yes (Z1) |
| mem/empty_struct.c | refutation (UB061) | COV `z2-001-empty-struct-ub061.c` | UB_MATCH | yes |
| mem/funptr_noparams_deref.c | both-reject | REPORT | — | no (Z-74 evidence row) |
| mem/funptr_noparams_deref2.c | both-reject | REPORT | — | no |
| mem/enum_underlying.c | both-reject | REPORT | — | no |
| mem/enum_conv.c | AGREE | COV `z2-002-enum-conv-registry.c` | MATCH | yes |
| mem/unspec_const_ptr.c | AGREE (Z-19 route) | COV `z2-003-unspec-const-ptr.c` | MATCH | yes |
| mem/atomic_member_stderr.c | AGREE (Z2-M-17) | COV `z2-004-atomic-member-ub042.c` | UB_MATCH | yes |
| mem/ptr_lt_null.c | AGREE (control) | REPORT — duplicate of the standing pin `g1-lt-null` (same Error line) | — | covered |
| mem/malloc_oom_msg.c | EXC(a) Z2-M-03 (oracle-only at the audit) | IMM libc `zd-z2m03-malloc-oom-msg` | MATCH (Lean now runs it: Z2-M-04) | yes |
| nd/order3.c | AGREE (order) | COV `z2-005-nd-order3.c` | MATCH (6-verdict sequence) | yes |
| nd/order2.c | AGREE | COV `z2-006-nd-order2.c` | MATCH | yes |
| nd/order_ptreq.c | AGREE | COV `z2-007-nd-order-ptreq.c` | MATCH | yes |
| main/stdout_escape.c | Z2-P-01 | IMM libc `zd-z2p01-stdout_escape` (Z1) | MATCH | yes (Z1) |
| main/stderr_escape.c | Z2-P-01 | IMM libc `zd-z2p01-stderr_escape` (Z1) | MATCH | yes (Z1) |
| coreparser/strtod_inf.c | BUG-FIX Z2-CP-01/CP-21 | IMM libc `zd-z2cp01-strtod-inf` | DIFF → MATCH | yes |
| coreparser/strtof_fltmax.c | not settled (Z2-CP-02) | REPORT (Z4 measurement lane) | — | no |
| impl/int32_uac.c | AGREE (header route) | COV `z2-008-int32-uac-header-route.c` | MATCH | yes |
| impl/int32_compat.c | AGREE | COV `z2-009-int32-compat.c` | MATCH | yes |
| impl/int32_printf.c | AGREE | LIBC `010-int32-printf.c` | MATCH | yes |
| impl/cerbty_int32_uac.c | BUG-FIX Z2-I-01 | IMM nolibc `zd-z2i01-cerbty-int32-uac` | DIFF \| L=CRASH → MATCH | yes (+ gcc ledger row) |
| float/hexfloat_round.c | refutation Z2-FL-01 | COV `z2-010-hexfloat-round.c` | MATCH | yes |
| float/decimal_sweep.c | not evidenced Z2-FL-02 | LIBC `011-decimal-sweep.c` | MATCH (200 stdout lines) | yes |
| float/nan_to_int_nopanicflag.c | both-crash (Z2-FL-03 / Z-58) | IMM nolibc `zd-z2fl03-nan-to-int` | MATCH \| L=CRASH | yes (+ gcc ledger row) |
| fs/lseek_whence.c | BUG-FIX Z2-F-01 | IMM libc `zd-z2f01-lseek-whence` | DIFF \| L=CRASH → MATCH | yes |
| fs/closedir.c | both-crash Z2-F-04 | IMM libc `zd-z2f04-closedir` | MATCH \| L=CRASH | yes |
| call/bool_param.c (+ wrapper) | BUG-FIX Z2-C-01 | VERIFY `z2_bool_param` rows f 0/1/2/-7 | pass (Lean = wrapper = pin) | yes |
| call/errno_order.c (+ wrapper) | BUG-FIX Z2-C-02 | VERIFY `z2_errno_order` rows f 1/-7 | pass | yes |

Derived tallies (recounted, pre-merge audit F5): 34 probe rows (36 probe
files = 34 + the 2 `call/*_wrapper.c`, the oracle side of the two VERIFY
rows, not separate probes); 26 integrated into gate lanes = 13 IMM (of which
3 are Z1's: device_funptr_call, stdout_escape, stderr_escape — Z2's own IMM
pins are 10: 6 in `112c0e98b` + 4 in `bef08dcf4`) + 10 COV + 4 LIBC + 2
VERIFY; 5 REPORT (3 both-reject + 1 not-settled + 1 duplicate); 13 + 10 +
4 + 2 + 5 = 34; and every confirmed Lean≠oracle probe (9 distinct findings) is
pinned: 6 findings RED→MATCH, the Z-07 re-witness MATCH, and the Z2-M-01
witnesses as visible PENDING pairs (§10.1).

## 6. Baseline movement table (every recorded movement, with its commit)

| baseline | row(s) | from → to | commit / cause |
|---|---|---|---|
| tests/immaculate | 6 new `zd-z2*` pins | (new) ORACLE_CRASH ×3 (zd-z2m01-*), DIFF ×3 (zd-z2cp01-strtod-inf L=ERR, zd-z2i01-cerbty-int32-uac L=CRASH, zd-z2f01-lseek-whence L=CRASH) | `112c0e98b` pin commit (RED before the fixes) |
| tests/immaculate | zd-z2cp01-strtod-inf, zd-z2i01-cerbty-int32-uac, zd-z2f01-lseek-whence | DIFF → MATCH | `3744e8503` (Z2-CP-01/CP-21, Z2-I-01, Z2-F-01) |
| tests/immaculate | zd-z2m01-aligned-alloc-zero, -nolibc, -zero-zero | ORACLE_CRASH → MATCH \| L=CRASH (the kind-2 mirror, `3744e8503`) → back to ORACLE_CRASH \| L=UB:DUMMY(align_alloc) ×2 and MATCH \| L=CRASH (the pending refusal) in fix group 2 | `5ed6c4a0a` — the [USER 2026-09-03] logical-semantics ruling; §2.1, §10.1 |
| tests/immaculate | zd-z2-free-funptr MATCH (ERR), zd-z2m03-malloc-oom-msg MATCH (ERR), zd-z2fl03-nan-to-int MATCH \| L=CRASH, zd-z2f04-closedir MATCH \| L=CRASH | (new) | `bef08dcf4` (§5) |
| tests/immaculate | every pre-existing row | — | no movement |
| scripts/exec_coverage_baseline.txt | 10 new `tests/coverage/z2/z2-0NN-*.c` rows | (new) 8 MATCH, 2 UB_MATCH (z2-001 UB061, z2-004 UB042) — as measured `SUMMARY: total=10 match=8 ub_match=2` | `bef08dcf4` (hand-inserted with header) |
| tests/libc_exec/baseline.txt | 008-aligned-alloc-bad-size, 009-aligned-alloc-3, 010-int32-printf, 011-decimal-sweep | (new) MATCH ×4 (`SUMMARY: match=11 diff=0`) | `bef08dcf4` |
| tests/verify/expectations.txt (+ z2_bool_param/z2_errno_order .c/.core) | 6 new call-point rows, 2 fixtures | 117 → 127 checks, 0 failed (`25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points`) | `bef08dcf4`; the 43 pre-existing call-point rows unmoved under the rendered call site |
| tests/libxml2/uri_baseline.txt | `LEAN_NOLIBC:` line | `Error {msg: "Illformed_program: calling an unknown procedure: Symbol(968, SD_Id("memset"))"}` → `Error {msg: "ill-formed program: \`calling an unknown procedure: Symbol(968, SD_Id("memset"))'"}` (= the oracle's wording modulo the symbol id, Z-04/tray 17) | `5ed6c4a0a` (Z2-P-05) — EXPECTED |
| scripts/gcc_oracle_baseline.txt | 3 new tests/immaculate/nolibc rows: zd-z2fl03-nan-to-int SKIP_LEAN_CRASH, zd-z2i01-cerbty-int32-uac SKIP_GCC_COMPILE, zd-z2m01-aligned-alloc-zero-nolibc SKIP_UB | (new rows) | `589e3d726` |
| every other Tier A/B baseline (exec minimal/debug/float, bytes, multi_tu, parse/core/elab, cn_coverage, speclab gates, libxml2 chvalid; every pre-existing gcc-lane row) | — | no movement (§11) | — |


## 7. API-visible changes (for the refined-cerberus change manifest)

`drive`'s signature and the `CerbND` runners are UNCHANGED. Namespace-level
changes in the hand-written seams (the in-process consumer imports these):

| module | change |
|---|---|
| `CerbMem` | `intToBytes` gains a leading `(signed : Bool)` parameter (`intToBytes signed val size`); NEW public `allocator : Int → Int → memM (StorageInstanceId × Address)`, `zLogand/zLogor/zLogxor : Int → Int → Int`, theorems `eqIval_isSome`/`ltIval_isSome`/`leIval_isSome`; `allocateObject`'s 6th parameter (`reqAddrOpt : Option Int`) is now consumed (fail-stop on `some`); `allocateRegion`'s `pref` argument is ignored (PrefMalloc recorded); `integerDiv_t`/`integerRem_t`/`integerRem_f` are TOTAL (unchanged from mainline — the fix-group-1 panics were reverted; a zero divisor is the pending §10.1 decision); `effArrayShiftPtrval` now uses its `loc`; `bitwise*Ival` ignore their `integerType` (same types); `deriveCap`/`capAssignValue`/`nullCap`/`ptrTIntValue`/`cheriPointerHashPrintf`/`getIntrinsicTypeSpec`/`callIntrinsic`/`concurReadIval` panic (same types); `targetPtrSize` reads `CerberusImpl.sizeof_pointer` (value 8 unchanged); private `toUnsigned`/`toSigned` deleted |
| `CerberusImpl` | NEW `n_t_aliases`, `aux_ibty`, `sizeof_pointer`, `alignof_pointer`; `sizeof_integerBaseType` DELETED; `normalise_integerType` moved before `sizeof_ity` (same type, new arms); `sizeof_ity`/`alignof_ity` same types, panic on un-normalisable arms |
| `CoreParser` | `pImplConstant : String → Except String implementation_constant` (was `→ implementation_constant`); `stampLibraryFile (file input : String) (cf : CoreFile)` (was `(file) (cf)`); NEW `RelocCtx`, `relocFile`, `lineTable`, `resolveByte`; `parseFile`/`parseLibraryFile`/`internSym` signatures unchanged (the parsed `PEundef`/`Action` locations of LIBRARY files now carry line/column; an OTy `a_N` anonymous tag now interns to the same symbol as its `__cerbty_unnamed_tag_N` ctype spelling — Z2-CP-13); `pIopFromStr`, `resolveOTyTag`, `anonymousTagDigits` private |
| `CerbCall` | `driveCall` signature UNCHANGED; NEW `funSymsNamedIn`, `resolveSymIn`, `argCreate`, `mkSseqs`, `mkUnseq`, `mkCallSite`, `lookupFunParams`, `lookupSignature`, `checkSignature`, `allocErrno`, `callLoc`; DELETED `injectArg`, `injectArgs`, `lookupFunBody`, `lookupParamTys`; `callFinish` re-typed (`(tagDefs) (tid0) (fsym) (callExpr) (errno_ptr)`) |
| `CerbLocation` | `stringFromLocation` output gains the cursor suffix (same type); `outerBbox` (private) panics on `[]` |
| `CerbDecode` | imports `CerberusImpl` (import-graph change); `decode_integer_constant ""` panics |
| `CerbFS` | `fs_lseek` same type (EINVAL on whence ∉ {0,1,2}); `fs_write`/`fs_pwrite` panic-refuse a vanished path |
| `Main` | `driverErrorBatchMsg` texts changed (pp_errors mirror); `loadCoreImpl` panics on an invalid impl name (unreachable, see the code) |
| `CerbStepInstances` | uses `ctype.beq_derived` (behaviour identical off the unreachable arm) |

## 8. Errata candidates

1. Z2 audit §2.5 row Z2-F-01 (and `tests/z2-probes/fs/README.md`): the
   Lean column `Specified(13)` is the pre-Z1 state; on the tree Z2 started
   from, Z1's Z-27 commit (`deb2338a8`) had already made the arm a loud
   refusal (`PANIC … CerbFS refusal … lseek on fd 3 with whence 7`,
   exit 134). The row's CLASS (BUG-FIX) and remedy (EINVAL) are unaffected.
2. Z2 audit §0/§2.1 "Z2-M-02 … MUST land in the same commit as Z-06": it
   did (Z1 `c61b78f70`) — the audit's work-order item 4 was already done
   when the fix phase started (as were items 2 and 7, Z2-P-01 and
   Z2-FL-03).
3. Z2 audit §2.14: the pp/lexer keyword mismatch `Cfvfromint`/`Civfromfloat`
   (Z2-CP-21) was not in the CoreParser candidate list although it sits on
   the same `strtod_inf.c` path as Z2-CP-01 (masked by the earlier
   `Unresolved_symbol`).
4. Z2 audit §2.14 Z2-CP-13 "libc.core: all tags named — impact UNSETTLED (needs an anonymous-struct libc-mode run)": the shape IS reachable, not in libc mode but in the `test_core.sh tests/ci` parse lane (two ci dumps) — found when the tripwire landed there (§2.7); resolved by the symbol mirror.
5. Z2 audit Z2-CP-17's remedy as written ("fail if any parsed
   binder/param/proc is a keyword") would refuse the libc pin (`glob
   builtin`, `alloc:` parameters) — the tripwire is narrowed here to the
   three value keywords, with the argument in-code.
7. (pre-merge audit N4) `scripts/test_verify.sh:130/289` discard the Lean
   binary's stderr (`2>/dev/null`) — PRE-EXISTING, not a Z2 change; the
   lane classifies by rc and verdict token, so no fail-open today; a Z4
   instrument candidate (surface the stderr in the FAIL line).
6. Charter §2.7 Z-61: the audit verified (by reading) that no residual
   printer reaches a batch verdict; no code change was needed here.

## 9. Commits on `arc/zero-discrepancy-z2` above `cc4d42dd6` (`git log --oneline cc4d42dd6..HEAD`)

```
(this record + charter census updates: the docs commit closing the slice)
096d8930e zero-discrepancy Z2: CoreParser Z2-CP-13 — anonymous aggregate tags resolve to ONE symbol (the oracle's AST); test_core.sh tests/ci back to 128/128
589e3d726 zero-discrepancy Z2 instrument: gcc second-oracle ledger — 3 rows for the new tests/immaculate/nolibc/zd-z2*.c pins
bef08dcf4 zero-discrepancy Z2 instrument: probe integration — 4 immaculate pins, 10 coverage/z2 exec rows, 4 libc_exec rows, 2 verify call-point fixtures (34/34 audit probes evaluated, record §5)
5ed6c4a0a zero-discrepancy Z2 fix group 2: CoreParser fail-closed grammar mirrors + Z-01 exact PEundef/Action positions, pp_errors/cursor text mirrors, the remaining seam declarations; Z2-M-01 kind-2 mirror REVERTED per the logical-semantics ruling
3744e8503 zero-discrepancy Z2 fix group 1: aligned_alloc(0,·) crash mirror, IntN_t aliasing, libc.core `inf`/Cfvfromint, SibylFS lseek EINVAL, --call renders the elaborated call site; the CerbMem §2.2 rows mirrored (Z-13..Z-22) + Z2-M-* dispositions
112c0e98b zero-discrepancy Z2 instrument: pin the Z2 audit's confirmed Lean!=oracle reproducers RED before the fixes (immaculate)
```

Note on `3744e8503`: its Z2-M-01 hunk (the `Division_by_zero` panics) is superseded by
`5ed6c4a0a` under the mid-slice ruling; the history is kept (the record is the record).

## 10. Decisions for the operator

0. (numbering: the kind-2 items first, per the ruling update)

**10.1 — The logical meaning of `aligned_alloc(0, n)` (Z2-M-01 / Z2-M-05).**
Three-engine lines (§1, §2.1): oracle fork AND upstream `Division_by_zero`
exit 125 for `(0, 8)` and `(0, 0)` (`aligned_alloc(alignment, size)`);
Lean `Undefined {ub: "DUMMY(align_alloc)", …}` for `(0, 8)` — std.core:385
tests `size rem_t align = 0`, i.e. `8 rem_t 0`, which the total `Int.tmod`
answers as 8 (x tmod 0 = x), so the proxy's own UB for a size that is not
a multiple of the alignment fires; for `(0, 0)` the test is `0 rem_t 0 =
0`, passes, and `alloc(0, 0)` reaches the allocator's pending refusal.
Neither is principled. Candidates: (a) **Core-level division by zero is UB045** — give
the Core operators `rem_t`/`rem_f`/`div` the meaning the elaborator gives
C's `%`/`/` (std.core's arithmetic procs guard with `undef(<<UB045b_division_by_zero>>)`),
so `aligned_alloc(0, n)` → `Undefined UB045b` on Lean; this is a
SHARED-MODEL change (`Mem.op_ival` is pure — the UB must be raised in
core_eval.lem's `PEop` evaluation or std.core:385 must gain the guard),
i.e. a lem/std.core edit plus the tray, not a hand-written-seam edit; (b)
**ISO C17 7.22.3.1p2/p3**: an alignment the implementation does not
support → the function "shall fail by returning a null pointer" — a
std.core:385 guard `if align = 0 \/ not(power of two) then NULL`, also a
shared-model change; (c) keep the current Lean answers and only pin
(status quo, unprincipled). Recommendation [AGENT]: (a) for the Core
operators (a total definition of the operators' meaning at zero, matching
the elaborator's own treatment of C division) AND the std.core:385 guard
for the alignment validity (b's shape, the model's own DUMMY UB or ISO's
NULL — the operator's call), both filed upstream (tray) and landed in the
shared `.lem`/std.core through the normal pin dance; until then the pins
stay as recorded. What this slice did: reverted the mirror, refusal on
alignment 0, pins, this row.

**10.2 — Z2-I-03 kind classification.** `Common.normalise_integerType_`
applies `Option.get` to `type_alias_map.intN_t_alias n`
(ocaml_implementation.ml:39-44); DefaultImpl's table (:155-160) has no
entry for widths outside {8, 16, 32, 64}, so `__cerbty_int128_t`
(builtins.lem:19/53) raises `Invalid_argument "option is None"`. Kind 1
reading: the model author wrote the `Option.get` as "an aliased width is
required" (a deliberate assertion); kind 2 reading: a host exception where
the implementation simply lacks a 128-bit alias. Under either reading the
implementation defines no size for the type; the code keeps a fail-stop
worded neutrally. Recommendation: kind 1 (mirrored fail-stop); if kind 2,
the logical meaning ("no such type in this implementation") is a
front-end rejection, which would be a shared-model change.

**10.3 — Z2-DC-01 (`decode_integer_constant ""`).** decode.ml:7-8 `str.[0]`
raises on an empty constant (the author's "TODO: this explodes") — kind 2
by its own comment. Reachable only via the fork-only
`[[cerb::with_address("")]]`; the code refuses loudly (was `(Decimal, 0)`).
No decision strictly needed; listed because the pre-Z2 default was the
fail-open shape and the refusal is not a mirror.

1. **Z2-CP-15 / Z2-CP-10 / Z2-CP-21 / Z2-CP-09 — four upstream pp↔grammar
   mismatches** found or confirmed by this slice (the `seq_rmw` action
   dropping `pe2`; `pcall(f, )`, `builtin` without `: eff`, `PtrMemberShift`
   without the dot; `Cfvfromint`/`Civfromfloat`; `wrapI_div`/`_rem_t`): each
   is a tray candidate for Z4. No Lean decision needed — the Lean mirrors
   the GRAMMAR where the oracle would parse, and the PP where the dump is
   the only input (CP-21, CP-11's `[]: <elem>`) — but the operator may want
   the dump-side accommodations enumerated in the VALIDATION rewrite.
2. **Z2-J-01 (bridge `filter_map` of CN declarations) and Z2-J-02
   (non-UTF-8 string bytes)**: the fail-closed remedies live in the fork's
   OCaml bridge (`backend/lean_export/cabs_json.ml`, a fork-drift-manifest
   surface). Out of the Lean slice; propose for Z4 with the manifest re-pin.
3. **Z2-N-02 / Z2-G-01**: `test_immaculate.sh` and `test_libc_exec.sh` run
   the oracle without `--mode` (its default is `Random`) against Lean
   `--first`; sound only on single-verdict programs (every current row).
   Options: leave (documented here), or add an exhaustive single-verdict
   spot-check to the two lanes (S, Z4 instrument).
4. **The Z-01 residual**: positions are exact on `PEundef`/`Action` nodes
   and file-only elsewhere. A per-node position mirror (every `mkPE`/`mkE`)
   is M and buys nothing observable; recommend closing the row as
   MIRRORED-where-behaviour-bearing + DECLARED (this record §2.7).
5. **Z2-T-01**: Lean's libc name-join refuses where the oracle's `union`
   silently picks the later TU's definition. Keep the refusal (fail-closed,
   class-(c)-shaped; equal on every current input) or mirror the pick? —
   recommend keep.

## 11. The final battery — Tier A + Tier B on the final head (`096d8930e`), fresh stamps, serial, capped 32G

Binaries: `check_driver_fresh --check` → `lean OK (bin b87125fa07d8c30ab5d083903fc2555319f10775d0e06891392e6023ebc6bd99, src 4873fc528a80e091fd08efa1ec7b165cd0f2473668eeda022b46fdc23da03985)`,
oracle source `c9c1a706…`. Each lane's `### <cmd> rc=<rc> (<secs>s) ::` line and its
SUMMARY/BASELINE/OK lines, verbatim (`.tmp/z2/lanes.sh`; the per-lane logs are
ephemeral scratch):

```
### ./scripts/test_unit.sh rc=0 (14s) ::
Done: 288 passed, 0 failed
4 passed, 0 failed
All PP tests passed
Total: 6 passed, 0 failed
### ./scripts/test_exec.sh --check-baseline rc=0 (13s) ::
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
### ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage rc=0 (24s) ::
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
### ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug rc=0 (11s) ::
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
### ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float rc=0 (9s) ::
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
### ./scripts/test_bytes.sh rc=0 (3s) ::
SUMMARY: exec_match=9 neg_pinned=5 fail=0
### ./scripts/test_libc_exec.sh rc=0 (23s) ::
SUMMARY: match=11 diff=0
ALL MATCH RECORDED BASELINE
### ./scripts/test_multi_tu.sh rc=0 (1s) ::
SUMMARY: total=2 match=2 fail=0
### ./scripts/test_parse.sh rc=0 (21s) ::
Total:          106
### ./scripts/test_core.sh rc=0 (18s) ::
Total:          106
### ./scripts/test_elab.sh rc=0 (32s) ::
SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
### ./scripts/test_libxml2_uri.sh rc=0 (19s) ::
### ./scripts/test_cn_coverage.sh --check-baseline rc=0 (60s) ::
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0
BASELINE OK (213 entries, exact match)
### ./scripts/test_libxml2.sh rc=0 (727s) ::
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
### ./scripts/test_parse.sh tests/ci rc=0 (46s) ::
Total:          250
### ./scripts/test_core.sh tests/ci rc=0 (33s) ::
Total:          250
### ./scripts/test_verify.sh rc=0 (73s) ::
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
### ./scripts/test_immaculate.sh rc=0 (63s) ::
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
### ./scripts/test_speclab.sh --selftest rc=0 (3s) ::
### ./scripts/test_speclab.sh --plant rc=0 (3s) ::
### ./scripts/test_speclab_divmod.sh --gate rc=0 (4s) ::
### ./scripts/test_speclab_bytearr.sh --gate rc=0 (4s) ::
### ./scripts/test_speclab_list.sh --gate rc=0 (4s) ::
### ./scripts/test_speclab_tree.sh --gate rc=0 (5s) ::
### ./scripts/test_speclab_seed.sh --gate rc=0 (4s) ::
### ./scripts/test_gcc_oracle.sh --check-baseline rc=0 (1463s) ::
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
### ./scripts/test_hang_plant.sh rc=0 (13s) ::
### ./scripts/test_kill_plant.sh rc=0 (201s) ::
PLANT OK   [libc_exec no MATCH]: SUMMARY: match=0 diff=11
PLANT OK   [libc_exec SIGKILL stub -> DIFF (not KILL)]: SUMMARY: match=0 diff=11
### ./scripts/test_fuel_plant.sh rc=0 (4s) ::
PLANT OK   [exec/kill summary fuel=1]: SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=1 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
```

An earlier Tier B pass on `589e3d726` (the head BEFORE the CP-13 fix) had every
row green — libxml2 `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22
observations each)`; gcc `SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0
triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1
skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47
triaged_addr=11 triaged_ub=1` / `Baseline check: 0 regression(s), 0
improvement(s)` / `gcc second-oracle lane OK` (run at box load 35–59, no
load-induced TIMEOUT movement) — EXCEPT `./scripts/test_core.sh tests/ci rc=1`:
`Lean parse: 126 ok, 2 failed` (`0042-struct_namespace`,
`0308-struct_global_with_dep`: `expected 'builtin', got 'glob'`) — the CP-13
tripwire finding, understood and fixed in `096d8930e` (§2.7); the battery above
is the re-run on the fixed head.

## 12. Provenance

[USER 2026-09-03]: the rule and exception classes (charter §1), the Q4 /
typed-failure interim rule, the Z-60 fail-closed rule, UB location is
behaviour (§1.3), the R1–R3 register rulings. [AGENT] (orchestrator):
the work order and its ordering, the Z-01 Pos row assignment. [AGENT]
(this worker): every mirror, declaration, classification, probe run,
tally and text here; every quoted engine/gate line is verbatim from this
worktree's runs; derived tallies are labelled. Nothing merged or pushed;
the primary checkout, `deps/`, `lem-lean/`, other worktrees and global
state untouched; `.tmp/z2/` is ephemeral scratch.


## 13. Orchestrator boundary review [AGENT, orchestrator, 2026-09-04]

Independent re-verification at the slice boundary (worker-claimed green
is never accepted). Head `811e4ac59`. In this worktree: `make
lean-prelude-src`; `DUNE_CACHE=disabled build_cerberus` → oracle stamp bin
`b05790f2ecee…`; `CERB_MEM_MAX=32G build_lean` → lean stamp bin
`b87125fa07d8…` (IDENTICAL to the worker's final stamp — the gated Lean
binary is bit-for-bit the same); `check_driver_fresh --check` OK. Then 25
lanes SERIALLY, every one rc 0, no baseline movement: Tier A in full
(unit, exec minimal/coverage/debug/float, bytes, libc_exec, multi_tu,
parse, core, elab, uri, cn_coverage), parse/core over `tests/ci`, verify,
immaculate, speclab selftest + plant, hang/kill/fuel plants, libxml2, gcc
lane. Box load at the gcc lane's start `load average: 10.09, 19.95,
17.31` (moderate; no TIMEOUT movement). Verbatim:

```
gcc lane:  SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
           Baseline check: 0 regression(s), 0 improvement(s)
           gcc second-oracle lane OK
verify:    test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
```

Consumer change manifest for this slice:
`docs/2026-09-04_zero-discrepancy-Z2-change-manifest.md`. The §10
decisions go to the operator with the merge ask; the pre-merge audit
follows this review (its document is cherry-picked onto the branch
before the merge, as for Z1).

## 14. Audit response (pre-merge audit `docs/2026-09-04_zero-discrepancy-Z2-audit-premerge.md` @ `audit/z2-premerge` `0bac11267`: MERGE-WITH-FIXES, 0 MAJOR / 7 MINOR / 5 NOTE)

One audit-response commit on top of the orchestrator's `a751e748e`. Binary
after the code fixes: `check_driver_fresh: lean OK (bin 99912f86b9e98dfb415af071138058e0f004b26e760c5a99941475e055332d83, src f3d5b4b4fb5503daea6da931b6c73cf61bd0f3bf2fc412c698f9a53333e855bd)`.

- **F1** (consumer-facing): record §7 and the manifest §1 no longer list
  `integerDiv_t`/`integerRem_t`/`integerRem_f` as kind-1 panics — they are
  TOTAL (the code at `CerbMem.lean`, reverted in `5ed6c4a0a`); both now say
  so and point at §10.1.
- **F2**: `pDefDecl` and `pFunDecl` now run `pImplConstant` on the `<name>`
  lexeme (the mirror of `scan_impl`, which validates every `<…>` lexeme at
  the lexer, `core_lexer.mll:209-218`); `Main.loadCoreImpl`'s comment states
  the true argument. Probe (a copy of the gcc impl with `def <bogus>: integer
  := 0` appended, placed as `impls/bogus_z2.impl` for the oracle run only,
  then deleted), verbatim:
  `ORACLE --impl=bogus_z2 tests/minimal/001-return-literal.c → ERROR: while parsing the Core impl, the parser didn't recognise it as an impl .` rc=1;
  `LEAN --parse-core bogus_z2.impl → ERROR: parse error: offset 1584: expected 'builtin', got 'def'` (nonzero exit) — same failure class, refused at
  the declaration on both. Unit cases added: `impl decl <bogus> refused`,
  `impl decl <sizeof> accepted`.
- **F3**: `CerbCall.lean` header and `mkCallSite` doc, record §2.4 and the
  charter §2.4c row cite `translation.lem:1126-1155` (the non-variadic
  `Normal_callconv` branch; `:1082-1108` is the variadic one).
- **F4**: charter §2.4c CP-13 row now cites `096d8930e` (+ this commit).
- **F5**: §5 tallies recounted and labelled derived: 13 IMM (3 Z1's; Z2's
  own 10 = 6 + 4), 10 COV, 4 LIBC, 2 VERIFY, 5 REPORT (3 both-reject + 1
  not-settled + 1 duplicate); 36 files = 34 rows + 2 wrappers.
- **F6**: the neg-action region now spans `neg ( … )` (`$startpos` before
  `neg`, `$endpos` after `)`), cited `.mly:1745-1746`; `grep -n "neg(" runtime/libcore/std.core runtime/libcore/impls/*.impl`
  → no match (verified here), so no library node carried the old span.
- **F7**: `resolveOTyTag` matches the declared anonymous tag as a WHOLE
  token (`mentionsAnonymousTag`: an occurrence not continued by a digit) —
  `__cerbty_unnamed_tag_5` no longer matches inside `…tag_50`; unit case
  `CP-13 tags 5/50`: a named `struct a` (`a_5` in OTy position) coexisting
  with anonymous tag 50 interns to `internSym "a"` and `a_50` to
  `internSym "__cerbty_unnamed_tag_50"`.
- **N1–N5**: no action; N4 recorded in §8.7 for Z4.

Gates after the code fixes (serial, capped 32G), verbatim:

```
### ./scripts/test_unit.sh                       first run rc=1: Done: 290 passed, 1 failed (✗ CP-13 tags 5/50: unexpected AST shape — the test pattern
                                                 said Ewseq for a `let strong`, which is Esseq; test pattern corrected, binary unchanged) →
                                                 rc=0: Done: 292 passed, 0 failed / 4 passed, 0 failed / All PP tests passed / Total: 6 passed, 0 failed
### ./scripts/test_core.sh rc=0 (14s) ::          Total: 106 / Lean parse: 106 ok, 0 failed
### ./scripts/test_core.sh tests/ci rc=0 (15s) :: Total: 250 / Lean parse: 128 ok, 0 failed
### ./scripts/test_parse.sh rc=0 (10s) ::         Total: 106 / Lean parse: 106 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal)
### ./scripts/test_exec.sh --check-baseline rc=0 (12s) ::
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
### ./scripts/test_verify.sh rc=0 (41s) ::        test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
### ./scripts/test_immaculate.sh rc=0 (54s) ::    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

