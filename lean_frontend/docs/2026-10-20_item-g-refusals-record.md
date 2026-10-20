# Item G: two memory-model TODOs become loud refusals — slice record (2026-10-20)

Branch `fix/item-g-refusals`, from mainline `mdd/cerberus-lean` = `20d2162ed`.
Worker: Claude Fable 5.1 (agent). Every judgement below that no operator ruling covers
is marked [AGENT]. **Status: implemented, verified, Tier A green on the final tree (§6).**
The slice first stopped at the brief's STOP condition — two gated Tier A baseline rows were
literally the two refused cases (§6) — and reported; [USER 2026-10-20] then ruled the two
control programs retired from the lanes, the witness script carrying their purpose.

## 0. Ruling and standing rules

- [USER 2026-10-20]: where upstream Cerberus left a case deliberately with a TODO, the fork
  either leaves it as-is or REFUSES LOUDLY — the run dies with a declared "unsupported"
  outcome — and never invents a semantic outcome (no UB verdict, no error verdict) in its
  place, and never answers silently wrong. Two cases, from cerberus-caesium's note 2 (items
  G1/G2; upstream-tray drafts 56/57): `memcpy` on overlapping objects, and `aligned_alloc`
  with an invalid alignment. Both are to be refused in the MEMORY MODEL of both engines (the
  copy; the allocator), never in the shared `std.core` (Core text expresses only verdict-shaped
  errors), with the same attributed text on both engines; alignment zero (draft 34) is out of
  scope and must not change. The outcome-protocol work later migrates the texts into its
  envelope; no envelope is invented here.
- [USER 2026-10-20] (second ruling, relayed by the orchestrator after the STOP report): retire
  both control programs from the Tier A lanes — `tests/coverage/mem4/mem4-020-memcpy-overlap.c`
  and `tests/libc_exec/009-aligned-alloc-3.c`, with their baseline rows — because
  `scripts/check_item_g_refusals.sh` now carries their purpose (the refusal witnesses and the
  valid-alignment arithmetic controls).
- Mirror-OCaml doctrine: the Lean check mirrors the OCaml check with file:line cites; the two
  texts are identical. Fail-closed; `failwithI`, never `panic!`; no new opaque atom.
- Precedent for a mirrored fork-ahead refusal: inline assembly (contract D9,
  `docs/2026-10-05_asm-refusal-record.md`, `scripts/check_asm_refusal.sh`).

## 1. The two cases as they stood (measured on the branch base, both engines)

| | upstream site | pre-fix answer |
|---|---|---|
| G1 | `memory/concrete/impl_mem.ml` `memcpy` opens with `(* TODO: if ptrval1 and ptrval2 overlap ==> UB *)` (b9aeedcb4 :2636; fork :2680 before this change) and copies byte-wise, forward | draft 56's witness `memcpy(b, b + 1, 4)`: `Defined {value: "Specified(7)"}` on both engines |
| G2 | `runtime/libcore/std.core:385` `aligned_alloc_proxy`: the only check is `size rem_t align = 0`, then `alloc(align, size)`; the allocator's `quomod` (b9aeedcb4 :1253) rounds the cursor down to a multiple of ANY align | draft 57's witness `aligned_alloc(3, 9)`: `Defined {value: "Specified(42)"}` on both engines |

## 2. Design

**G1 — overlap, in `memcpy` of both engines.** The check runs at the head of `memcpy`, before
any byte moves (the oracle's `failwith` is raised when `memcpy` is applied; `memcpyM`'s
`failwithI` likewise, Lean being strict). Overlap = `[a1, a1+n)` ∩ `[a2, a2+n)` ≠ ∅ with
`n > 0`, i.e. `a1 < a2 + n ∧ a2 < a1 + n`, and either (a) both pointers `PV (Prov_some id,
PVconcrete (_, a))` with the SAME `id` (region text `allocation ID`) or (b) both
`PV (Prov_device, PVconcrete (_, a))` (region text `device memory`: `ptrfromint` mints it for
an integer in the model's fixed `device_ranges`, impl_mem.ml:2226-2227 — `[0x40000000,
0x40000004)` and `[0xABC, 0xAC0)`; `load`/`store` serve it, :1669/:1778; the pure
`array_shift_ptrval` passes it through, :2414-2416). [AGENT] decisions, with reasons:

- Completeness, as the pre-merge audit (P2-1) made me state it exactly. The first version
  tested shape (a) only and claimed it was the only shape a copy could complete with; that
  was false: the audit's probes `dev_overlap.c` (`(char*)0xABC`, `memcpy(p, p + 1, 2)`) and
  `dev_overlap2.c` (`(char*)0x40000000`, `memcpy(p + 1, p, 3)`) answered `Specified(5)` /
  `Specified(111)` on BOTH engines (reproduced here before the fix; refused after it, §6).
  Shape (b) is the orchestrator's disposition. The remaining shapes cannot complete a copy: a
  `Prov_none` concrete pointer fails at the first byte (`load`'s arm :1667, `store`'s :1776;
  the audit's `none_overlap.c` → `UB_CERB002a_out_of_bound_load` on both), a `Prov_symbolic`
  argument dies in the pure `array_shift_ptrval` first (R-PNVI-06, draft 53),
  `PVnull`/`PVfunction` fail in `load` — EXCEPT one named residual, found while probing for
  the fix: the mixed `Prov_some`/`Prov_device` pair, reachable only when an allocation lies
  inside a device range, i.e. under the fork-only `--address-space-top` (outside CONTRACT §2's
  promise): `mixed.c` (`memcpy(a + 4, d, 2)`, `d = (char*)0xABC`, `a` at 0xAB8 under top 2756,
  where errno takes `[0xAC0, 0xAC4)`) answers `Specified(56)` on both engines, before and after
  the fix. [AGENT 2026-10-20] it is NOT refused, and the reason is instructive: I first widened
  the predicate to every served pair with intersecting addresses (dropping the same-`id`
  requirement), and the witness script's own control `ctl_memcpy_oob.c` caught it — a source
  range running out of `b` into the neighbouring allocation `a` was refused as "overlapping
  objects", where it is the loop's `UB_CERB002a` (an out-of-bounds access, not an overlap).
  The ranges are the C-level objects and `memcpy` never consults the allocation's bounds, so
  without them an allocation genuinely inside device memory cannot be told from an
  out-of-bounds run into it; the predicate needs data the model's `memcpy` does not have, and
  the brief says to report that rather than guess. Reported here for the operator's ruling
  (§7); CONTRACT D10, VALIDATION §3(c) and the consumer note name it.
- Two allocations never intersect: `allocator_active_sound` places each strictly below the
  cursor, and an address is never reused (a dead allocation's pointer fails at the first
  load anyway); so shape (a)'s same-`id` test is exactly "the same object".
- The ranges are the C-level objects (`n` bytes each), NOT clipped to the allocation, and the
  refusal fires at application, BEFORE ANY ACCESS CHECK: a copy that is also out of bounds,
  or whose object is dead, is refused rather than reported as that UB (the audit's
  `dead_overlap.c`, `malloc`/`free`/`memcpy(p, p + 1, 2)`, is refused on both engines with
  the allocation text; the DeadPtr UB is not reported). A refusal is a permitted outcome; the
  out-of-bound UB is still reported for a non-overlapping out-of-bounds copy (control
  `ctl_memcpy_oob.c`).
- `memcpy(p, p, n)` overlaps (the same object); `n = 0` never does. `realloc`'s copy is
  new ← old, two allocations — unaffected (control `ctl_memcpy_realloc.c`).

**G2 — alignment validity, in the `allocator` of both engines.** Predicate: "not a positive
power of two", written as the oracle's `not (equal align zero) && not (gt align zero && equal
(logand align (pred align)) zero)`; the Lean `alignmentRefused` is the same test on
`Int.toNat` (this toolchain has no `Int.land`; for `align > 0` the two agree; it reduces by
`decide`, `rfl` and `simp [alignmentRefused]` on a literal — probed on the toolchain). [AGENT]:

- Placement: in `allocator` (shared by `create` and `alloc`), AFTER the `z < 0`
  out-of-memory kill and BEFORE the remainder — where the alignment is consumed and where
  the align-0 `Division_by_zero` sits. Consequence: `aligned_alloc(3, N)` with `N` above the
  cursor still kills out-of-memory first, exactly as before; and `allocator_below_request_kills`
  is untouched.
- Alignment ZERO is excluded by the first conjunct: `aligned_alloc(0, n)` still dies at
  `std.core:385`'s `rem_t` (both engines, draft 34) before reaching the allocator, and the
  allocator's own `align = 0` arm is unchanged (crash control `ctl_alloc_zero.c`).
- Negative alignments are refused (`size_t` never yields one; a hand-written Core `alloc`
  could).
- Not in `std.core`: per the ruling (Core text only expresses verdicts; std.core is shared with
  upstream) — the layer-2 fork-drift pins did not move (§5).

**The Lean leaf in the allocator — why it is `failStopKill (failwithI …)`.** `CerbMem.allocator`
is the subject of the kernel theorem `allocator_active_sound`, stated WITHOUT hypotheses on
`align` ("`align = 0` is the refusal arm, never active"), and the consumer cerberus-sl unfolds
`allocator` directly (`CerberusIris/Adequacy.lean`). A `failwithI` at the arm's pair type is
opaque to the kernel: the theorem could say nothing about that arm and would need an
alignment hypothesis (a weaker, consumer-visible statement). Carrying the `failwithI` as the
MESSAGE of a `failStopKill` makes the arm a kill in the kernel — never active, the theorem's
proof gains one `split`/`simp` line and keeps its statement — while at run time Lean's strict
evaluation of the message fires the same loud fail-stop every refusal uses (abort under
`LEAN_ABORT_ON_PANIC`, exit 134, the text on stderr). Without the abort the arm is still a
kill (an empty message), never an answer. [AGENT 2026-10-20]; alternatives considered: a
plain typed kill (`failStopMem`: `ModelFailure`, exit 1 — the brief asked for the refusal
shape, exit 134 with the text) and the hypothesis on the theorem (rejected as above).
`memcpyM` has no theorem over it; its leaf is the plain `failwithI` ascribed at `memM`, as
`pnviRefuseM` is.

**Texts** (ASCII only, so the oracle's `Failure("…")` rendering and Lean's PANIC line carry
them byte-identically; the numbers are the same on both engines because the allocators
mirror):

```text
Concrete.memcpy: refused - memcpy on overlapping objects (allocation ID: destination [A1, A1+N) and source [A2, A2+N), n = N); C17 7.24.2.1#2 undefined behaviour; upstream copies byte-wise under impl_mem.ml memcpy 'TODO: if ptrval1 and ptrval2 overlap ==> UB' (b9aeedcb4 :2636) - the fork refuses rather than decides (item G1, 2026-10-20)
Concrete.allocator: refused - allocation with an invalid alignment ALIGN (not a positive power of two; size SZ); C17 7.22.3.1#2-3 requires aligned_alloc to fail by returning a null pointer (C11: undefined behaviour); upstream allocates under runtime/libcore/std.core:385 aligned_alloc_proxy, whose only check is 'size rem_t align = 0', and impl_mem.ml allocator's quomod (b9aeedcb4 :1253) - the fork refuses rather than decides (item G2, 2026-10-20)
```

Sites: `memory/concrete/impl_mem.ml` `allocator` (:1292-1308 in this tree) and `memcpy`
(:2695-2734: the comment, `overlap_refusal`, `region_of`, the match); `lean_frontend/CerbMem.lean` `alignmentRefused`/`alignmentRefusal`/`allocator`
and `memcpyOverlap`/`memcpyOverlapRefusal`/`memcpyM`; `CerbMemAllocatorProofs.lean`
(one more `split at h` arm, statement unchanged); `test/Unit/FuelExemplar.lean`
`allocator_errno` (`simp [h1, CerbMem.alignmentRefused]`, the literal arm reduces).

## 3. Measurement: what reaches the allocator and `memcpy` in the lanes

Before choosing the predicate, a TEMPORARY, env-gated file-logging instrument (never
committed; reverted before the real change) was placed in the oracle's `allocator` and
`memcpy`, and every exec-type lane of the ladder was run through it on the branch base: Tier A
rows 2, 3, 4, 4b, 4c, 5, 6, 6b, 10, 11, 12, 14 and Tier B rows 4 (verify) and 5 (immaculate)
— every corpus the Tier B pristine lane walks except the three run as their own rows. All 14
lanes rc 0 under the instrument.

Alignments reaching the allocator (derived tallies over the log):

| align | calls | lanes |
|---|---|---|
| 1 | 14586 | all |
| 2 | 20 | A3, A5, A11, A14, B5 |
| 3 | **1** | A5 — `tests/libc_exec/009-aligned-alloc-3.c`, `aligned_alloc(3, 9)` |
| 4 | 35625 | all |
| 8 | 18055 | all (malloc's `IvMaxAlignment` is 8) |
| 16 | 4 | A3 (2), B5 (2) |
| 0 | 0 | — (the `zd-z2m01-aligned-alloc-zero*` rows die at `std.core:385` before the allocator) |

So the predicate "positive power of two" refuses exactly ONE lane allocation, the row that is
draft 57's own case. `_Alignas(3)` and `_Alignas(6)` (object and struct-member forms) were
probed on the oracle: `error: constraint violation: alignment specifier … does not evaluate to a
valid fundamental alignment` (§6.7.5#3) — `create` never carries an invalid alignment.

`memcpy` calls: 97. 77 between two allocations; 18 inside one allocation, non-overlapping;
**1 overlapping** (A3: `tests/coverage/mem4/mem4-020-memcpy-overlap.c`, `memcpy(a + 1, a, 4)`,
allocation 1, `a1 = …641`, `a2 = …640`, `n = 4`); 1 with an operand outside the
`Prov_some`/`PVconcrete` shape (A14, the PNVI lane; the check does not apply there, and that
program's own R-PNVI-06 refusal is unchanged — row 14 is green, §6).

## 4. Witnesses and plants — `scripts/check_item_g_refusals.sh` (row 1, wired into `test_unit.sh`)

19 cases (16 in the first version; the two device witnesses and the device control were
added at the pre-merge audit's P2-1), nolibc with prototypes (the tray drafts' shape),
fail-closed. A witness requires: the
oracle exits 125 with `uncaught exception` + `Failure("<head>…<tail>")`; `--cabs-json` succeeds;
Lean exits 134 with a `PANIC` line carrying `<head>…<tail>`; and the two texts, extracted from
their head to the end of the line, are byte-identical. A control requires Lean = oracle on the
exit code and the first verdict line. The crash control requires both engines' pre-existing
texts.

- 6 G1 witnesses: draft 56's program; the mem4-020 backward shape; an object onto itself; an
  overlap inside a `malloc`'d object; the audit's two device-memory overlaps (`(char*)0xABC`
  forward, `(char*)0x40000000` backward).
- 3 G2 witnesses: `aligned_alloc(3, 9)` (draft 57), `(6, 12)`, `(1000, 2000)`.
- 9 controls: adjacent halves of one object (`Specified(13)`); two objects (`Specified(9)`);
  length 0 of a pointer onto itself (`Specified(22)`); `realloc`'s copy (`Specified(34)`); an
  out-of-bounds non-overlapping copy (`UB_CERB002a_out_of_bound_load` on both, exit 1); a
  non-overlapping copy inside device memory (`Specified(34)`);
  `aligned_alloc(16, 32)` (`Specified(42)`); ONE allocation at EACH alignment the lanes use —
  `aligned_alloc(1,1)…(16,16)`, `malloc`, and `create` of `char`/`short`/`int`/`long`/`long
  double` objects (`Specified(78)`); `aligned_alloc(16, 8)` (`DUMMY(align_alloc)` UB, unchanged).
- 1 crash control: `aligned_alloc(0, 8)` dies as before on both (oracle `Division_by_zero`,
  Lean `CerbMem.integerRem_t: Division_by_zero (…)`).
- Plants (`--selftest`), each asserting its EXACT failure count and the required cases: `answer`
  (both engines answer `Specified(7)` on every witness program; controls run the real engines):
  18 = 9 × 2; `lean-answer` (Lean answers on everything): 19 = 9 + 10; `refuse-all` (both
  engines refuse everything with the two texts): 10 = the controls; `lean-no-abort` (the real
  Lean output, exit 0 — a message without a death is not a refusal): 12 = 9 + the 2 UB controls
  + the crash control; `lean-other-text` (the real Lean, its text altered, exit kept): 9 = the
  text cross-check. All five counts were derived before each run and matched it (the first
  version's 14/16/9/10/7 likewise). The wider predicate tried in between (§2) failed the
  `answer` plant with 21 ≠ 20: its extra failure was the OOB control on the real oracle.

Verbatim, draft 56's witness (`ov.c`) and draft 57's (`aa.c`), from `.tmp` runs on the branch:

```text
$ main.exe --runtime=… --exec --batch --nolibc ov.c ; rc=125
cerberus: internal error, uncaught exception:
          Failure("Concrete.memcpy: refused - memcpy on overlapping objects (allocation 1: destination [281474976710640, 281474976710644) and source [281474976710641, 281474976710645), n = 4); C17 7.24.2.1#2 undefined behaviour; upstream copies byte-wise under impl_mem.ml memcpy 'TODO: if ptrval1 and ptrval2 overlap ==> UB' (b9aeedcb4 :2636) - the fork refuses rather than decides (item G1, 2026-10-20)")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
$ LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --runtime=… ov.json ; rc=134
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Concrete.memcpy: refused - memcpy on overlapping objects (allocation 1: destination [281474976710640, 281474976710644) and source [281474976710641, 281474976710645), n = 4); C17 7.24.2.1#2 undefined behaviour; upstream copies byte-wise under impl_mem.ml memcpy 'TODO: if ptrval1 and ptrval2 overlap ==> UB' (b9aeedcb4 :2636) - the fork refuses rather than decides (item G1, 2026-10-20)
$ main.exe --runtime=… --exec --batch --nolibc aa.c ; rc=125
cerberus: internal error, uncaught exception:
          Failure("Concrete.allocator: refused - allocation with an invalid alignment 3 (not a positive power of two; size 9); C17 7.22.3.1#2-3 requires aligned_alloc to fail by returning a null pointer (C11: undefined behaviour); upstream allocates under runtime/libcore/std.core:385 aligned_alloc_proxy, whose only check is 'size rem_t align = 0', and impl_mem.ml allocator's quomod (b9aeedcb4 :1253) - the fork refuses rather than decides (item G2, 2026-10-20)")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
$ LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --runtime=… aa.json ; rc=134
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Concrete.allocator: refused - allocation with an invalid alignment 3 (not a positive power of two; size 9); C17 7.22.3.1#2-3 requires aligned_alloc to fail by returning a null pointer (C11: undefined behaviour); upstream allocates under runtime/libcore/std.core:385 aligned_alloc_proxy, whose only check is 'size rem_t align = 0', and impl_mem.ml allocator's quomod (b9aeedcb4 :1253) - the fork refuses rather than decides (item G2, 2026-10-20)
```

(The oracle's `uncaught exception` header carries ANSI colour bytes; omitted here.) Script
result, verbatim:

```text
check_item_g_refusals: selftest plant 'answer' caught: 14 failing witness(es) (= expected 14; incl. the required witnesses)
check_item_g_refusals: selftest plant 'lean-answer' caught: 16 failing witness(es) (= expected 16; incl. the required witnesses)
check_item_g_refusals: selftest plant 'refuse-all' caught: 9 failing witness(es) (= expected 9; incl. the required witnesses)
check_item_g_refusals: selftest plant 'lean-no-abort' caught: 10 failing witness(es) (= expected 10; incl. the required witnesses)
check_item_g_refusals: selftest plant 'lean-other-text' caught: 7 failing witness(es) (= expected 7; incl. the required witnesses)
check_item_g_refusals: OK (16 cases: 4 overlapping memcpy programs and 3 invalid-alignment allocations refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 8 controls agree with the oracle (5 non-overlapping copies incl. realloc and an out-of-bounds UB, aligned_alloc(16, 32), one allocation at each alignment the lanes use, the unchanged size-clause UB); the zero-alignment crash is unchanged on both)
```

## 5. Register entries

- **Failure-reach register (`scripts/failure_reach_register.txt`): no new row.** Both new
  `failwithI` sites sit in declarations typed at `memM` (`CerbMem.allocator`,
  `CerbMem.memcpyM`), which the census classes `monadic_ascribed` (channel
  `NDkilled_Error0_loc`), exactly as `pnviRefuseM`'s sites are; the register gate covers the
  PURE group only. The gate was run on the changed tree, verbatim:
  `check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the
  exec dependency closure + 2 unresolved-owner; …); position classes unchanged; 0 DISCARDABLE;
  reach UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22; every row sealed; tally line
  consistent)` — the hand-written `monadic_ascribed` count went 1 → 3 (`pnviRefuseM` before;
  now also `CerbMem.allocator`'s leaf and `CerbMem.memcpyM`'s — both new sites counted; the
  pre-merge audit's P3-2 corrected the first version's "2 → 3") and the pure count stayed
  239. The brief expected
  sealed rows for new pure sites; there are none, by the gate's own classification, and the
  reachability of both sites is witnessed by the script instead (both REACHABLE from C:
  `w_memcpy_*.c`, `w_alloc_*.c`).
- **Fork-drift manifest (`scripts/fork_drift_manifest.txt`):** the single `[source-content]`
  row for `memory/concrete/impl_mem.ml` moved `534d25dd… → 65f60137…` (→ `f179bb8e…` at the
  pre-merge audit fix, the NOTE amended), with a dated header
  NOTE (`fix/item-g-refusals, 2026-10-20`), no `--refresh`; `[expected-semantic]` untouched
  (no `.lem`, parser, `std.core` or generated-OCaml change). Gate + `--selftest`, verbatim:
  `check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical,
  no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base
  b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130
  matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))`;
  `check_fork_drift: SELFTEST OK (31 plants …; unplanted gate green)`.
- **`scripts/upstream_oracle_differences.json`: no row** — the only two walked-corpus programs
  that would differ from pristine are the retired controls (§6); as for inline assembly, the
  register has nothing to carry (Tier B is the orchestrator's).
- **Retired corpus controls** (the second ruling, §0): `tests/coverage/mem4/mem4-020-memcpy-overlap.c`
  (its row in `scripts/exec_coverage_baseline.txt`; the header count annotated 27 → 26) and
  `tests/libc_exec/009-aligned-alloc-3.c` (its row in `tests/libc_exec/baseline.txt`). Cites
  fixed in the current-state docs (VALIDATION §3(c), the inventory entry, the gate table;
  CONTRACT D10; the manifest NOTE; the consumer note; the witness script's labels). Dated
  records that describe history are left as they are: the Z2 record
  (`docs/2026-09-04_zero-discrepancy-Z2-record.md`, its probe-integration table: "LIBC `009-aligned-alloc-3.c` MATCH"), the
  Z2 probe README (`tests/z2-probes/mem/README.md`, "Proposed lane: libc_exec MATCH" — the
  probe `aligned_alloc_3.c` itself stays, not a lane), the thin-surface tests record
  (`docs/2026-09-28_thin-surface-tests-record.md`, `mem4-020`), and the evidence directories
  that list `009-aligned-alloc-3` in lane tails. No fixture or coverage manifest names either
  file (`scripts/fixture_corpus.sha256` covers `lean_frontend/corpus` only).
- `lean_frontend/CONTRACT.md`: a §3 row "item G … REFUSED (D10)", the refused-parts sentence,
  §4.1's witness list, decision **D10**. `VALIDATION.md`: §3(c) bullet, the fork ≠ pristine
  inventory entry, the §6 gate-table row. `SUPPORTED.md` Domain row; `scripts/LADDER.md` row 1;
  `scripts/test_unit.sh` runs `check_item_g_refusals.sh --selftest`; the tray INDEX rows 56/57
  and the "Added since" paragraph; drafts 56/57 gain a "Fork-ahead refusal" paragraph in their
  Origin sections (status stays Draft). `lean_frontend/TODO.md` has no item-G entry (searched
  "item G", "memcpy", "aligned", "caesium"): nothing to update. Consumer note:
  `docs/2026-10-20_consumer-note-cerberus-caesium-item-g-refusals.md`.

## 6. Gates: the STOP, the retirement, and the final run

Builds: OCaml `DUNE_CACHE=disabled dune build --force backend/driver/main.exe
cerberus-lib.install`, `dune install --prefix _build/local-install cerberus-lib`,
`DUNE_CACHE=disabled dune build --force cerberus.install` (all rc 0); `make lean-prelude-src`
(sync gate OK, 52 files); Lean `capped lake build`: `Build completed successfully (400 jobs).`

**The STOP (first pass).** Two gated Tier A baseline rows were literally the refused cases
and moved, measured by re-running the lanes on the changed engines: row 3
(`test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage`) gave
`[171/280] CERB_SKIP mem4-020-memcpy-overlap (exit 125)` → `REGRESSION:
mem4-020-memcpy-overlap.c baseline=MATCH current=CERB_SKIP` (the program is `memcpy(a + 1, a,
4)` with the comment "the observable is what each engine reports"); row 5 (`test_libc_exec.sh`)
gave `OBSERVATION ERROR: fatal engine diagnostic; no completed observation` / `DIFF
009-aligned-alloc-3:` (both engines die; the lane has no both-crash class — the program is
`aligned_alloc(3, 9)`, the "Z2 CONTROL: non-power-of-two alignment through the allocator
arithmetic", zero-discrepancy Z2-M-05). Tier A on that tree: `fast: failed; 17/19 selected
commands completed successfully. Source unchanged: True. Complete tier selection: True.` — A3
and A5 each on exactly that one row, every other row green (`Total: 19 passed, 0 failed` on
row 1). Per the brief the rows were reported, not re-baselined, and the work was parked as
WIP commit `09bcd9de3` by the orchestrator.

**The retirement (second ruling, §0).** Both programs were deliberate controls of the stance
the ruling supersedes (that an overlapping copy / an invalid alignment is served and the
engines merely compared); the witness script carries what they checked — the refusal on both
engines, and the allocator arithmetic at every alignment the lanes use. Both were deleted
with their baseline rows (`git rm`; §5 lists the cites). No other lane program overlaps or
uses an invalid alignment (§3).

**The final run (retired controls, final tree).** Row 1 (`scripts/test_unit.sh`, as A1,
499.7 s, PASSED), verbatim lines:

```text
Total: 19 passed, 0 failed
allocator-soundness-test: OK (4/4 states; kernel theorem CerbMem.allocator_active_sound compiled)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_item_g_refusals: OK (16 cases: 4 overlapping memcpy programs and 3 invalid-alignment allocations refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 8 controls agree with the oracle (5 non-overlapping copies incl. realloc and an out-of-bounds UB, aligned_alloc(16, 32), one allocation at each alignment the lanes use, the unchanged size-clause UB); the zero-alignment crash is unchanged on both)
```

Tier A (`python3 scripts/release.py --mode fast` through `scripts/ce`, `CERB_MEM_MAX=32G`;
evidence `.tmp/release/20261020T061609.520009Z`, deleted after reading; ~25 min): all 19
commands PASSED (A1 499.7 s, A2 28.7 s, A3 91.8 s, A4 23.5 s, A4b 25.2 s, A4c 3.2 s, A5 110.3 s,
A6 4.5 s, A6b 3.9 s, A7 14.8 s, A8 13.4 s, A9 20.7 s, A10 20.2 s, A11 61.6 s, A12.1 5.2 s, A12.2
5.1 s, A13 1.6 s, A14.1 151.9 s, A14.2 232.8 s), verbatim:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```

A3: `SUMMARY: total=279 match=224 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0
lean_error=0 timeout=0 hang=0 cerb_skip=16 cerb_floor=0 cerb_inconsistent=0` / `BASELINE OK`
(280 → 279 rows). A5: every row MATCH at the recorded baseline (the `009` row gone).

**The pre-merge audit fix (`docs/2026-10-20_item-g-refusals-premerge-audit.md`; the fix
commit on top of it).** Dispositions P2-1 (the device arm, §2), P2-2 (the replay below),
P3-1 (§7 and the consumer note), P3-2 (§5's tally), the "before any access check" note (§2).
Both engines rebuilt as above (OCaml cache-disabled; `make lean-prelude-src`; `capped lake
build`: `Build completed successfully (400 jobs).`). The device witnesses on the final
engines, verbatim (oracle rc 125 / Lean rc 134, the text identical):

```text
Failure("Concrete.memcpy: refused - memcpy on overlapping objects (device memory: destination [2748, 2750) and source [2749, 2751), n = 2); C17 7.24.2.1#2 undefined behaviour; upstream copies byte-wise under impl_mem.ml memcpy 'TODO: if ptrval1 and ptrval2 overlap ==> UB' (b9aeedcb4 :2636) - the fork refuses rather than decides (item G1, 2026-10-20)")
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Concrete.memcpy: refused - memcpy on overlapping objects (device memory: destination [2748, 2750) and source [2749, 2751), n = 2); …
Failure("Concrete.memcpy: refused - memcpy on overlapping objects (device memory: destination [1073741825, 1073741828) and source [1073741824, 1073741827), n = 3); …")
```

Witness script on the final engines, verbatim: `check_item_g_refusals: selftest plant
'answer' caught: 18 …`, `'lean-answer' … 19`, `'refuse-all' … 10`, `'lean-no-abort' … 12`,
`'lean-other-text' … 9` (each `= expected`), then `check_item_g_refusals: OK (19 cases: 6
overlapping memcpy programs (4 in allocations, 2 in device memory) and 3 invalid-alignment
allocations refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort,
exit 134) with byte-identical texts; 9 controls agree with the oracle (6 non-overlapping copies
incl. realloc, an out-of-bounds UB and device memory, aligned_alloc(16, 32), one allocation at
each alignment the lanes use, the unchanged size-clause UB); the zero-alignment crash is
unchanged on both)`. Fork-drift gate and self-test green on the re-pinned row.

**Kernel replay (the named trust gate, [USER 2026-10-18]), on the final tree**, from
`lean_frontend/`, through `scripts/ce` and `../scripts/capped`, `CERB_MEM_MAX=32G`:

```text
$ lake env leanchecker CerbMemAllocatorProofs Unit.FuelExemplar
(no output)
rc=0
$ lake env leanchecker NoSuchModuleXYZ        (negative control)
uncaught exception: Could not find any oleans for: NoSuchModuleXYZ
rc=1
```

`#print axioms`, same tree (`lake env lean` on a scratch file importing
`CerbMemAllocatorProofs` and `Unit.FuelExemplar`):

```text
'CerbMem.allocator_active_sound' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.allocator_below_request_kills' depends on axioms: [propext, Classical.choice, Quot.sound]
'FuelExemplar.allocator_errno' depends on axioms: [propext, Classical.choice, Quot.sound]
'FuelExemplar.exemplar_certified_shipped_forall' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Tier A on the fix tree (`python3 scripts/release.py --mode fast` through `scripts/ce`,
`CERB_MEM_MAX=32G`; evidence `.tmp/release/20261020T071835.222186Z`, deleted after reading;
~24 min): all 19 commands PASSED (A1 516.5 s — row 1: `Total: 19 passed, 0 failed`,
`check_item_g_refusals: OK (19 cases: …)`, `check_failure_reach: OK (239 …)`,
`allocator-soundness-test: OK (4/4 states; kernel theorem CerbMem.allocator_active_sound
compiled)`, axiom census 0 — A2 30.0 s, A3 75.6 s, A4 23.8 s, A4b 25.5 s, A4c 3.4 s, A5 109.3 s,
A6 4.0 s, A6b 3.7 s, A7 10.9 s, A8 9.1 s, A9 17.5 s, A10 19.7 s, A11 60.5 s, A12.1 5.1 s, A12.2
4.7 s, A13 1.6 s, A14.1 114.1 s, A14.2 170.5 s), verbatim:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```

A3: `SUMMARY: total=279 match=224 ub_match=37 … cerb_skip=16 …` / `BASELINE OK`; A5 at its
baseline.


## 7. Not done / open

- The named residual of §2: the mixed allocation/device overlapping copy under the fork-only
  `--address-space-top` is still served by both engines (`Specified(56)` at top 2756). Outside
  CONTRACT §2's promise; refusing it needs the allocation's bounds in `memcpy` (a state read
  both engines would add, beyond upstream's loop) — for the operator's ruling.
- Tier B not run (the orchestrator's). Its pristine lane walks neither retired program, so no
  `upstream_oracle_differences.json` row is expected from this slice.
- The texts are pre-envelope; the outcome-protocol work migrates them.
- cerberus-sl at the re-pin (consumer note, pre-merge audit P3-1): its general theorem
  `CerberusIris/HeapModelAlloc.lean:59` `allocator_cases` (active-or-`oomKill` disjunction over
  `allocator`) becomes FALSE for a refused alignment — the new arm is a third kill — and needs
  the hypothesis `CerbMem.alignmentRefused align = false` or a third disjunct; the
  `allocatorSound`/`allocator_cases` chain and `Adequacy.lean:336` depend on it. The two
  literal-alignment unfoldings (`Adequacy.lean:339`, `HeapModelAlloc.lean:45`) only gain an
  arm that `CerbMem.alignmentRefused` in the simp set (or `decide`) closes.
- The Z2 probe `tests/z2-probes/mem/aligned_alloc_3.c` (not a lane) now refuses on both
  engines; its dated README still records the 2026-09-03 AGREE result.

## 8. Process note (killing processes)

During the first pass a Tier A rerun of my own had to be stopped after a comment-only cite
fix invalidated its source identity. I located the candidates with a pattern match on the
command text (`pgrep -f`), then verified each PID's working directory was this worktree and
killed only those — my `release.py` and, as it turned out, my own polling shells, whose
command text matched the pattern. No other agent's process was touched. The practice this
box asks for is stricter and simpler: kill only PIDs you started, recorded at launch; a
pattern match is not a safe way to find them, and I should have captured the PID when
launching the run. Noted here so the next worker does not repeat it [AGENT 2026-10-20].
