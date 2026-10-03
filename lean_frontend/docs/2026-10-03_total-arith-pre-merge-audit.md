# Total arithmetic and bookkeeping: pre-merge audit, 2026-10-03

Range `621caf996..34fab1dd0` (5 commits) on `fix/total-arith-and-bookkeeping`;
slice record `docs/2026-10-03_total-arith-and-bookkeeping-record.md`.
Auditor: [AGENT] Claude, a fresh reviewer with no part in the slice, working on
branch `audit/total-arith-20261003`. Scope, verbatim, [USER 2026-10-03] "(3) go
ahead", on: "a fresh reviewer of the five commits for mirror fidelity, register
correctness, and the sweep's unreachable claims".

Upstream cites are to `deps/cerberus-upstream` @ `b9aeedcb4` unless marked
"fork". Probes ran with the slice worktree's built binaries: the oracle with
`--exec --batch --nolibc`, and Lean with `--batch --first` on the oracle's
`--cabs-json`, with `CERB_INSTALL_PREFIX=<slice>/_build/install/default` and
`LEAN_ABORT_ON_PANIC=1` as `scripts/common.sh` sets them. They ran one at a
time under `cerberus-lean/scripts/capped` (`CERB_MEM_MAX=8G`). There were no
builds, and the slice worktree was not modified. The ladder in it
(`.tmp/ta-full.log`) was still at B7 (gcc lane) when this audit ended. The audit
does not rely on that ladder.

## Verdict: MERGEABLE WITH FIXES

The code changes mirror upstream faithfully. Every new stop fires where zarith
or OCaml raises, and nowhere else that I could find. The boundary values match
OCaml's native-int range, which I measured. The register rows are correct and
sealed. None of the 16 unreachable claims could be reached. No new semantics was
invented, and nothing silently answers.

The required fixes are documentation and status text (F2, F3). F1 is a
classification question that the post-slice synthesis ruling raises. It needs
the operator's word. It does not block the merge: the code is on the
fail-closed side in either reading.

## Findings (ranked)

### F1 (MEDIUM, operator classification): the `Z.Overflow` stops have not been classified under the 2026-10-03 synthesis

The slice was written before the synthesis ruling. Its §2.3 O-3 raised the
tension as open. The ruling [USER 2026-10-03] "(1) agree" now gives the test.
Where upstream's own semantics defines the answer and only OCaml machinery
crashes on the way, Lean computes it (R3). Otherwise Lean stops loudly.

- **The `Division_by_zero` stops (`integerRem_t`/`integerRem_f`/`integerDiv_t`)
  pass this test cleanly.** Upstream defines no quotient or remainder by zero.
  Its only answer is the raise, and Lean's former `DUMMY(align_alloc)` was a
  value upstream never chooses.
- **The three `Z.to_int al_n` stops (`zToInt`) are arguable either way.**
  - *For a stop:* `Concrete.alignof` is hand-written OCaml whose result type is
    `int` (`impl_mem.ml:248`/`:267`). There is no TODO at those lines.
  - *For R3-style computation:*
    - The Lem-level signature is unbounded:
      `val alignof_ty: map AilSyntax.ail_identifier (list (maybe Ctype.alignment * Ctype.ctype)) ->  Ctype.ctype -> maybe nat`
      (`frontend/model/implementation.lem:27`). The `nat`→`int` mapping is
      target machinery.
    - The memory interface returns `integer_value` (`mem.lem:191`,
      `alignof_ival`).
    - `impl_mem.ml` itself labels the same conversion class a known limitation,
      not a meaning. For example, `:1063`:
      `(* TODO: the Z.to_int on the sizeof() will raise Overflow on huge structs *)`.
      `:1143`, `:1216`, `:1558` and `:2810` carry the same comment.
  - *Lean's former answers:*
    - `Specified(0)` for `sizeof` and for union `_Alignof`: (int) of 2^63 and
      2^62, wrapped.
    - `Error {msg: "desugaring failed …"}` for the desugarer witness: the §6.7.5
      less-strict-alignment refusal of an unbounded alignment.

    These are the unbounded semantics' answers, not garbage.

**Needed:**
- The operator rules which way these three sites go.
- The record gets a dated addendum classifying each stop under the synthesis.
- O-3 (record §2.3, lines 234-248) and the VALIDATION §0 pointer note
  (`VALIDATION.md:86-93`, "is an open operator item") are updated. The ruling
  has answered the question they leave open.
- If the operator chooses R3-style, the three `zd-ta-alignas-huge-*` pins become
  ORACLE_CRASH register rows (as R3 is).

### F2 (LOW, doc fix): the `zToInt` docstring claims more than the code does

`lean_frontend/CerberusImpl.lean:24-25`:
"Every mirrored `Z.to_int` that can see an unbounded `Z` goes through `zToInt`".
This is false at three places:

- memcmp's `Z.to_int size_n` (`impl_mem.ml:2660-2661`) is
  `getBytes pv1 [] size_n.toNat` (`CerbMem.lean:3043-3044`). It is deliberately
  not routed: R3.
- `IntExp`'s `Z.pow n1 (Z.to_int n2)` (`impl_mem.ml:2490`) is
  `n1 ^ n2.toNat` (`CerbMem.lean:1668`). This is U-6.
- The object-size conversions are U-4.

The record's §2.2 has it right. Fix: change "Every … can see an unbounded `Z`"
to "the reachable ones (record §2.2 lists the rest and why)".

### F3 (LOW, must change with the ruling): R6 is still marked PROPOSED

The operator has since ruled `floatMul` [USER 2026-10-03] "yes this is the
canonical 'obviously a mistake, no semantic ambiguity, just fix'". These places
must change:

- `lean_frontend/CerbFloat.lean:41`: "ISO-fix register R6 — PROPOSED, awaiting
  the [USER] ruling".
- `lean_frontend/CerbFloat.lean:55`: the marker comment "(PROPOSED; not admitted
  until the [USER] ruling)". The marker itself stays.
- `lean_frontend/VALIDATION.md:289`:
  - the row label "**R6** (PROPOSED)";
  - the status cell "**PROPOSED [AGENT] 2026-10-03, NOT ADMITTED** … the
    alternative is to mirror `(+.)`" (record the verbatim ruling instead).
- `lean_frontend/VALIDATION.md:295`: "and the PROPOSED R6".
- `lean_frontend/VALIDATION.md:455`: "(R1, R2, R3, R5; R6 proposed, not
  admitted)".
- The record §4 (lines 315-338) and the commit-message wording are history.
  Supersede them with a dated addendum, not a rewrite.

The VALIDATION §0 note and O-3 (F1) belong in the same pass.

### F4 (INFO): stale wording the slice left in place

- `CerbMem.lean:1658-1667`: the `IntExp` negative-exponent comment and message
  still say "a KIND-2 OCaml-execution artifact … NOT mirrored (the
  logical-semantics referent ruling)" and "an OCaml-execution artifact, not the
  referent". The behaviour (loud stop) fits the synthesis ("no answer
  defined"), but the wording now contradicts the neighbouring `allocator`
  message, which the slice re-worded to "mirrored as a fail-stop". Changing the
  message's tail leaves the register key (the first 60 characters) as it is.
  Changing the first 60 characters moves the key and needs a reseal.
- `tests/z2-probes/README.md:28-31`: "except the `aligned_alloc(0,·)` rows,
  which stay ORACLE_CRASH as PENDING rows …". This is a dated integration
  paragraph, now stale. An optional pointer would fix it.
- `docs/upstream-tray/34-…md:114-117`: "the total-remainder divergence and the
  pending decision are recorded there". This is in a draft. Fix it when filing.

### F5 (INFO): unreachable sites were guarded unevenly

`integerDiv_t` is registered UNREACHABLE-BY-INVARIANT, yet it gained the
mirrored zero guard. The layout family's `Z.modulus … 0` sites (`impl_mem.ml:123`,
`:169-171`, `:189-191`) stay Lean's Nat `% 0` = identity, under the Z2-M-11
"unreachable by construction" declaration (`CerbMem.lean:358-373`;
`offsetsofMembers_lemFuel`'s `lastOffset % align`, `sizeofCtype_lemFuel`'s
`maxOffset % align` / `maxSize % maxAlign`). Both are defensible, since neither
is reachable (U-1, re-probed below). The fail-closed doctrine would favour the
same guard. This is the operator's choice, not a defect.

### F6 (INFO): gcc ledger confirmed, full lane not observed

- The four `zd-ta-*` rows and the `zd-z2m01-…-nolibc` SKIP_UB → SKIP_LEAN_CRASH
  row are consistent with the fixtures and the record's partial runs. The
  record's header notes are present (`scripts/gcc_oracle_baseline.txt:17-23`).
- The pre-existing gap O-2 is confirmed. A scan of every
  `tests/immaculate/nolibc/*.c` against the ledger gives exactly one missing
  row: `MISSING tests/immaculate/nolibc/zd-invalid-format-utf8-payload.c`
  (65 fixtures, 64 rows).
- The full gcc lane (ladder B7) had not finished when this audit ended.

## What I verified

### 1. Mirror fidelity

- **zarith behaviour, measured** in the cerberus-lean switch's OCaml with
  zarith, verbatim:
  ```
  4611686018427387904 -> Overflow
  4611686018427387903 -> 4611686018427387903
  -4611686018427387904 -> -4611686018427387904
  -4611686018427387905 -> Overflow
  max_int=4611686018427387903 min_int=-4611686018427387904
  rem: Division_by_zero
  mod_big_int: Division_by_zero
  div: Division_by_zero
  ediv_rem: Division_by_zero
  ```
  `zToInt`'s test `n < -(2^62) || 2^62 - 1 < n` (`CerberusImpl.lean:38-41`) is
  exactly `Z.to_int`'s domain. With the sign table for divisors ±2 (OCaml
  `rem`/`mod_big_int`/`div` against Lean `tmod`/`emod`/`tdiv`), the nonzero
  arms agree on all four sign combinations:
  OCaml `rem=1,-1,1,-1 modbig=1,1,1,1 div=3,-3,-3,3`, and Lean
  `[(1, 1, 3), (-1, 1, -3), (1, 1, -3), (-1, 1, 3)]`.
- **Raise sites.**
  - Upstream `impl_mem.ml:2479-2484`: `IntDiv` has
    `Z.(if equal n2 zero then zero else div n1 n2)`; `IntRem_t`/`IntRem_f` are
    unguarded (`:11-12` `integerRem_t = (mod)`,
    `integerRem_f = Big_int_Z.mod_big_int`).
  - Fork `:2523-2528` has the same lines.
  - Lean keeps the `IntDiv` guard (`CerbMem.lean:1652`) and moves the
    zero-check into the helpers.
  - The helpers' only callers are `opIval` (`:1652`, `:1655-1656`) and
    `diffPtrval` (`:2802`). There are none in the generated tree: `grep` over
    `generated/` finds only `CerbMem`.
  - `Core_eval` reaches remainders only through `CerbMem.opIval`
    (`generated/Core_eval.lean:77`, `:96`, `:143`).
- **The `zToInt` placement matches upstream line by line.**
  - `Z.to_int al_n` appears only at `impl_mem.ml:248` and `:267` (alignof's
    folds) and at `ocaml_implementation.ml:483` and `:501` (fork also
    `impl_mem.ml:248/:267`).
  - offsetsof (`:117-118`) and union sizeof (`:182-183`) use `al_n` as a `Z`.
  - Lean wraps only alignofCtype's two folds (`CerbMem.lean:599`, `:609`) and
    `alignof_ty` (`CerberusImpl.lean:313`). `memberAlign_lemFuel`, which
    offsetsof and union sizeof use, is unchanged.
  - Struct sizeof calls `alignofCtype` (`CerbMem.lean:539`), as upstream's
    `:169` calls `alignof`, so it raises on both engines. Union sizeof does not
    call `alignofCtype`, on either side.
- **Probes (both engines, verbatim head lines):**
  - The union-sizeof non-raise is confirmed. `sizeof(union u) >> 60` with a
    2^62-aligned member gives:
    `ORACLE rc=0: Defined {value: "Specified(4)", …}` and
    `LEAN rc=0: Defined {value: "Specified(4)", …}`.
  - A new route to the alignof raise: the pointer cast `(union u *)buf`
    (isWellAligned → alignof) gives oracle `rc=125 … Z.Overflow` and Lean
    `rc=134 … Z.to_int: Z.Overflow … at Concrete alignof (impl_mem.ml:248/:267)`.
  - `_Alignas(struct big) char g;` crashes on both at the same site. The oracle
    backtrace shows `Impl_mem.alignof … line 248 … Concrete.alignof_ival`, and
    Lean's message names `Concrete alignof`.
  - A nested struct holding a huge-aligned struct, used only through a null
    pointer comparison, gives `Specified(1)` on both. No raise, as upstream.
  - `_Alignas(2^62)` on objects, global and local: both
    `Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}`.
  - `x %= y` with `y == 0` (a control the record lacks): both
    `Undefined {ub: "UB045b_modulo_by_zero", …, loc: "<1:40--1:46>"}`.
- **The Lean-side evaluation-order caveat is out of scope.**
  `CerberusImpl.alignof_ty`'s fold evaluates `al_opt` in a pure `let`. Whether
  the compiler could skip it when `acc_opt = none` depends on an earlier member
  having no alignment. That is Z2-I-04 / tray 47 territory (incomplete types,
  owned by `fix/alignas-p2d3`). My probe there
  (`extern _Alignas(struct big) struct inc g;`) shows the pre-existing
  divergence (oracle `Not_found` at `Pmap.find`; Lean `desugaring failed`),
  which the slice did not touch.

### 2. Registers

- **Failure-reach seals.** I recomputed every row's seal with the script's own
  `seal_of`: `rows 234 bad seals 0`.
- **New rows.**
  - `integerDiv_t` UNREACHABLE: its callers are as stated.
  - `integerRem_t` REACHABLE: its witnesses re-read.
  - `integerRem_f` UNREACHABLE: `translation.lem` emits only `OpRem_t`
    (`:369`, `:1721`); `rem_f` appears only at `std.core:59`, `:164`, `:238`
    and `core_eval.lem:34`, each with a nonzero divisor.
  - `zToInt` REACHABLE.
- **Tally arithmetic.** 172 + 41 + 21 = 234, TAIL 181 + NON-TAIL 53 = 234, and
  the movement from 230 is +2 UNREACHABLE, +2 REACHABLE.
- **Immaculate baseline.**
  - The two `zd-z2m01` rows were `ORACLE_CRASH | L=UB:DUMMY…` and are now
    `MATCH | L=CRASH`.
  - There are four `zd-ta-*` rows.
  - The header note and the `--record` template agree.
  - The fixture rewrites kept the program lines: `main` is on line 8 in the
    nolibc fixture and line 12 in the libc fixture, matching the old pinned
    locations `<8:28…>` and `<12:28…>`.
- **VALIDATION.**
  - The R3 row now names the marker, and the marker exists
    (`CerbMem.lean:3036`).
  - The marker and row sets are in bijection: R1/R2 in `CerbDecode`, R3 in
    `CerbMem`, R5/R6 in `CerbFloat`.
  - §3 (d) now lists R5, which was admitted [USER 2026-09-15] and had been
    missing: a correct repair.
  - §3 replaces the Z2-M-01 "still open" bullet.
- **Z2 record addendum** (`2026-09-04_zero-discrepancy-Z2-record.md`, end): it
  is appended only and rewrites nothing above it. It withdraws §10.1 with the
  rulings quoted.
- **R6 reachability.**
  - In the generated tree, `CerbFloat.floatMul`'s only references are
    `generated/Float.lean:91` (`numMult := CerbFloat.floatMul`) and
    `Defacto_memory`'s `impl_op_fval`. This is consistent with the record's
    closure measurement, which I did not rebuild.
- **Contradictions between registers.** None beyond F1, F3 and F4: the §0 note
  and O-3 are left open by the later ruling.

### 3. The sweep's unreachable claims (record §2.2)

I read the code paths for U-1, U-2, U-3, U-4, U-6, U-8, U-9, U-10 and U-12,
probed four of them on both engines, and tried to reach U-1, U-2 and U-4. None
was reached.

- **U-1 (alignment 0).** `union u { };`: both `UB061_no_named_members`. A struct
  whose only member is an anonymous empty struct: both `UB061`.
- **U-2 (negative array size).** A VLA `int a[n]` with `n = -1`: the oracle says
  `feature not yet supported: variable length array type 2`, and Lean refuses
  in the front end (`desugaring failed`).
- **U-3.** The `aligned_alloc` proxy (`std.core:380-392`) is the only
  alignment-taking allocation route: there is no `posix_memalign`/`memalign` in
  `runtime/libc`. Every `create` takes `Ivalignof`.
- **U-4 (sizes of at least 2^62).** I tried a struct of size exactly 2^62 via a
  2^61-aligned member, through four paths:
  - local copy: both `allocator: failed (out of memory)`;
  - global: both OOM;
  - `*p = *p` over an `int`: both `UB025_misaligned_pointer_conversion`, since
    the alignment check dominates;
  - `*p = *p` through `(struct s *)0x2000000000000000UL`: both
    `UB043_indirection_invalid_value`.

  In `load` (`:1555-1559`), `Z.to_int (sizeof ty)` sits inside `do_load`, after
  the checks.
- **U-6.** `^` is emitted only by the shift elaborations
  (`translation.lem:1721`, `:1745`, `:1803`) and in std.core/impl at `2^width`
  and `2^m`. All of these sit behind the UB051a/UB51b guards.
- **U-8.** Read in `formatted.lem:609-618`: `%c` requires `signed_int`, `%s`
  requires a character `ref_ty` (`:632`), and `step_fs_proc` is in
  `core_reduction_aux.lem:46-49`.
- **U-9.** Read in `ocaml_gcc_builtins.ml:3-11` and `CerbUtils.lean:105-108`.
- **U-10.** The `diffPtrval` divisor is `sizeofCtype` of the element (Lean
  `CerbMem.lean:2802`; upstream `:1962-1967`).

## What I could not verify

- I did not rebuild the failure-reach instrument, so the R6 closure measurement
  (`FAILURE_REACH CerbFloat.floatMul false false`) is taken from the record.
  Static greps agree with it.
- `check_failure_reach.sh` itself was not run, because it needs a build. The
  seal and tally checks above use the script's own seal function.
- The full gcc lane (ladder B7) and the rest of Tier B had not finished in the
  slice worktree during this audit.
- The pristine-oracle classifications of the new fixtures are taken from the
  record's §5 verbatim lines. I did not re-run them.
- U-5, U-7, U-11, U-13, U-14, U-15 and U-16 were not independently re-read
  beyond the cites (U-14 is owned elsewhere).

## Provenance

All findings and classifications here are [AGENT] (this auditor). The quoted
rulings are [USER 2026-10-03] as given in the audit brief. Probe scratch lived
in this worktree's `.tmp/` and was deleted before the commit.
