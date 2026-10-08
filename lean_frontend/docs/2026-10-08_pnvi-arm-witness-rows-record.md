# PNVI lane: arm-witness rows for the arms only unit witnesses covered (arc-end audit F4) — record (2026-10-08)

Branch `lane/pnvi-symbolic-rows`, cut from mainline `c4284b08f`. Worker: Claude Opus 5.5 (agent). Every
judgement no operator quote covers is marked [AGENT]. Quoted tool output is verbatim; counts marked
"derived" are mine. No semantics change: no `.lem`, no hand-written Lean file and no OCaml file changed.
Line numbers `impl_mem.ml:N` are `memory/concrete/impl_mem.ml` in THIS tree.

Companion of the S4 lane record `docs/2026-10-07_pnvi-s4-lane-record.md` (the lane's design, row classes,
plants); this record adds one section to that lane and changes nothing else in it.

## 1. The finding

The PNVI arc-end audit (`47348c07e..b4e7a136f`, landing note `fd110ea30`) follow-up F4: these arms had no
oracle-compared lane row, only unit witnesses (`test/Unit/PnviArmsTest.lean`):

- the symbolic `kill` resolve path (`kill`'s `Prov_symbolic` arm, :1519-1553, via `resolve_iota`, :917-942);
- `eq_ptrval` symbolic/symbolic (:1905-1914, then the `msum "pointer equality"` fork, :1917-1923);
- both `diff_ptrval` symbolic arms: mixed (:2032-2060) and symbolic/symbolic (:2063-2105);
- the `Prov_none` bounds arm of `eff_array_shift_ptrval` (:2392-2397).

## 2. What changed

| File | Change |
|---|---|
| `tests/pnvi_arms/a01…a13-*.c` | NEW: 13 witness programs, each with a header naming its arm (`impl_mem.ml` lines), the reach argument and the expected answer |
| `scripts/test_pnvi.sh` | a new section `arm/` over `tests/pnvi_arms/*.c`, libc mode, EXHAUSTIVE on both sides — exactly the `witness/` row recipe (`libc_row`); an empty corpus fails closed (`die "empty arm-witness corpus …"`); header comment |
| `tests/pnvi_lane/baseline.txt` | re-recorded (`--record-baseline`): +13 `arm/` rows, all `AGREE`; a header paragraph for them |
| `lean_frontend/VALIDATION.md`, `scripts/LADDER.md`, `lean_frontend/CLAUDE.md` | the lane's row: the new corpus, 177 rows / 165 AGREE, `arm 5/8` default split |
| `lean_frontend/docs/2026-10-07_pnvi-s4-lane-record.md` | §14 addendum: pointer to this record |
| this record | NEW |

[AGENT] A new corpus and section rather than extending `tests/pnvi_refusals/`: that directory's rows are
the CONTRACT §4.1 refusal witnesses (each a registered `REFUSAL` row); these rows are agreement rows, and the
section prefix keeps the two populations separately countable in the SUMMARY line.

## 3. The rows

Oracle answers under `--switches=PNVI_ae_udi` (verbatim, from the kept capture of the selection run before
recording; Lean's capture was identical on every row — the lane's AGREE is token-sequence equality of the
`full` projection):

| Row | Arm (impl_mem.ml) | Oracle (verbatim, executions in order) | Class | default |
|---|---|---|---|---|
| `a01-kill-symbolic-first-candidate` | `kill` symbolic arm, dynamic; `resolve_iota` `Double`, FIRST precondition `OK` (:926-929) | `Defined {value: "Specified(17)", …}` / `Defined {value: "Specified(7)", …}` | AGREE | changed |
| `a02-kill-symbolic-both-candidates-fail` | same arm; `resolve_iota` `Double`, BOTH preconditions fail (:930-935), the second's error reported | `Error {msg: "MerrUndefinedFree Free_out_of_bound"}` ×2 | AGREE | same |
| `a03-kill-symbolic-collapsed-single` | same arm; `resolve_iota` `Single`, `OK` (:919-922) after the store collapses the iota | `Defined {value: "Specified(157)", …}` / `Defined {value: "Specified(57)", …}` | AGREE | changed |
| `a04-kill-symbolic-collapsed-single-fail` | same arm; `resolve_iota` `Single`, `FAIL` (:923-924) after `r - a` collapses the iota to `a` | `Error {msg: "MerrUndefinedFree Free_out_of_bound"}` ×2 | AGREE | same |
| `a05-kill-symbolic-not-dynamic` | same arm; the dynamic-check prefix (:1530-1537, `Free_non_matching`) | `Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<16:3--16:10>"}` ×2 | AGREE | same |
| `a06-eq-diff-symbolic-double-double` | `eq_ptrval` sym/sym `Double`/`Double` (`_ -> false`) + fork; `diff_ptrval` sym/sym intersection `Double`, addr1 = addr2 (:2100-2102) | `Defined {value: "Specified(1)", …}` / `Defined {value: "Specified(0)", …}` | AGREE | changed |
| `a07-eq-diff-symbolic-single-collapse` | `diff_ptrval` sym/sym intersection `Single` (:2094-2099, both collapse); then `eq_ptrval` sym/sym `Single`/`Single` equal (no fork) | `Defined {value: "Specified(201)", …}` (one execution) | AGREE | changed |
| `a08-eq-symbolic-single-double-fork` | `eq_ptrval` sym/sym `Single`/`Double` (`_ -> false`) + fork — a07's control | `Defined {value: "Specified(201)", …}` / `Defined {value: "Specified(200)", …}` | AGREE | changed |
| `a09-diff-mixed-symbolic-collapse` | `diff_ptrval` mixed arm, BOTH patterns (sym,some) and (some,sym); `Double` collapse (:2048-2055) then `Single` match (:2039-2043) | `Defined {value: "Specified(1013)", …}` | AGREE | changed |
| `a10-diff-mixed-symbolic-single-mismatch` | `diff_ptrval` mixed arm, `Single` NON-matching (:2046-2047) after a collapse | `Undefined {ub: "UB048_disjoint_array_pointers_subtraction", stderr: "", loc: "<14:17--14:25>"}` | AGREE | same |
| `a11-diff-symbolic-disjoint-singles` | `diff_ptrval` sym/sym, two `Single`s naming different allocations → `None` (:2070-2074, :2092-2093) | `Undefined {ub: "UB048_disjoint_array_pointers_subtraction", stderr: "", loc: "<17:15--17:22>"}` | AGREE | changed |
| `a12-diff-symbolic-double-double-positional` | `diff_ptrval` sym/sym, `Double`/`Double` with no POSITIONAL match → `None` (:2081-2090) | `Undefined {ub: "UB048_disjoint_array_pointers_subtraction", stderr: "", loc: "<18:15--18:22>"}` | AGREE | same |
| `a13-array-shift-prov-none` | `eff_array_shift_ptrval` `(Prov_none, PVconcrete)`, the PNVI bounds branch (:2393-2395) | `Error {msg: "MerrOther "out-of-bound pointer arithmetic (Prov_none)""}` | AGREE | changed |

(`…` = `stdout: "", stderr: "", blocked: "false"`, elided here only.) Every UB location was checked against
the source line it names: a05 line 16 `free(r);`, a10 line 14 `&y - r`, a11 line 17 and a12 line 18 `r - s`.

### 3.1 How reach was checked [AGENT]

Not by an instrumented build: the Lean memory model has no per-arm trace, and an instrumented `CerbMem.lean`
would rebuild every downstream module of the exec closure for evidence that the observables already give.
Reach is argued from the OCaml arms and Core (each program's header carries its argument) and made
OBSERVABLE wherever a cheap discriminator exists, so that Lean producing the same answer is evidence that
Lean took the same arm:

- **The pointer is symbolic at the operation.** a01-a05 compare `r` against the allocation it would
  otherwise carry (`r == b`, `r == &y`): `eq_ptrval` on `(Prov_symbolic, Prov_some)` is its `_ -> false`
  case (:1915-1916), hence a two-execution fork, which excludes `r` carrying that allocation's provenance
  (an equal comparison, one execution). In a01 and a03 the Defined answers also exclude `Prov_some(a)` (the
  free, resp. the store, would fail) and `Prov_none` (the kill fails), leaving `Prov_symbolic`. a02/a04
  mint `r` by the same prefix as a01.
- **Which `resolve_iota` case.** a02: precondition(b) fails with `Free_dead_allocation` (UB179b),
  precondition(a) with `Free_out_of_bound`; the answer is the SECOND failure, so the candidate order is
  pinned (trying `a` first would report UB179b). a04: after the collapse to `a` the free fails; the
  uncollapsed `Double` would resolve to `b` and succeed (a01) — the Error is the `Single` path.
- **`eq_ptrval` sym/sym.** The fork (a06, a08) versus no fork (a07) separates `_ -> false` from the
  `Single`/`Single` equal case; a07 vs a08 differ only by the subtraction, so a07's single execution is the
  `diff_ptrval` `Single`-intersection collapse made visible.
- **`diff_ptrval`.** a09's 1013 needs `r` x-compatible AND `s` y-compatible from the same cast (no
  `Prov_some` assignment gives both); a10's UB048 at `&y - r` is the collapse made visible (without it the
  `Double` case answers 0).
- **`Prov_none` shift.** a13's message text occurs at exactly one code site on each side
  (`impl_mem.ml:2395`; `CerbMem.lean:3545` — `:3442` is that definition's doc comment).

## 4. Unreachable from C (with evidence) [AGENT]

The audit expected the kill arm's full `resolve_iota` path to be unreachable because adjacent `malloc`
blocks could not be produced. That premise is narrower than it looked: two `malloc`s are never adjacent
(the callee's 8-byte argument temporary, `runtime/libcore/std.core:350` `malloc_proxy (size_ptr: pointer)`,
is allocated between them — the 24-byte spacing the audit saw), but a block-scope object created right
AFTER a `malloc` is (`a01`: `a + 16 == b`, MEASURED by the row's own `i != j` guard — the program returns 2
otherwise; an `_Alignas(16)` variant missed by 8 bytes, the region being 8-aligned). So `Double` OK (a01),
`Double` FAIL/FAIL (a02), `Single` OK (a03), `Single` FAIL (a04) are all reached. What remains:

1. **`resolve_iota` `Double`, first FAIL then second OK (:930-933) in `kill`.** Argument: the allocator
   (:1282-1305) only moves `last_address` down, so for ids i < j, `j.end <= i.base`; `find_overlaping`'s
   ascending fold (:796-875) puts the lower id first. The second candidate `j` must satisfy
   `j.base = A` (the precondition, :1526-1527) and the first `i` must contain or end at `A`
   (`i.base <= A <= i.end`), so `j.base = A <= i.base - j.size` forces `j.size = 0`, `A = i.base`, and NO
   positive-size allocation between `i` and `j`. C objects have positive size; a zero-size region comes
   only from `malloc(0)` / `aligned_alloc(a, 0)` / `realloc(p, 0)`, whose proxies (`std.core:350`, `:360`,
   `:380`) all take their arguments through caller-allocated temporaries (positive size) created after `i`
   and before the region. Hence unreachable from C (argued, not measured; it assumes no
   `allocator_with_address` placement, which no C construct requests).
2. **`kill`'s symbolic arm with `is_dyn = false` (:1538-1539).** Static kills (end of lifetime) are
   issued on the pointer `create` returned, always `Prov_some`. Unreachable from C (argued).
3. **`diff_ptrval` sym/sym, intersection `Double` with addr1 ≠ addr2 (:2103-2104; Lean's R-PNVI-08
   refusal).** A `Double {p, q}` iota is minted only at the single address where one allocation ends and
   the other begins; `eff_array_shift` on a `Double` iota either keeps the address (offset 0) or collapses
   it (a non-zero shift cannot satisfy both preconditions: one needs offset >= 0, the other <= 0;
   `PERMISSIVE` is not this switch set). So two `Double` iotas over the same pair always carry the same
   address. Unreachable from C (argued) — consistent with CONTRACT's "no C witness found" for -08.

Reachable sub-cases left without a row (low value, same code paths as rows above) [AGENT]: `eq_ptrval`
`Single`/`Single` naming different allocations; `diff_ptrval` sym/sym `Single`/`Single` equal; the mixed
arm's `Double` case with a non-member allocation or a failing precondition.

## 5. An upstream observation (mirrored, not judged) [AGENT]

`a12`: with three adjacent exposed globals `y > x > z`, `r` minted at `x`'s end (`{y, x}`) and `s` at
`x`'s base (`{x, z}`) both admit `x`, but upstream's `Double`/`Double` intersection is POSITIONAL
(`x1 = y1`, `x2 = y2`, :2081-2090), finds nothing and makes `r - s` UB048. Lean mirrors it ([USER
2026-10-03]: no innovation vs upstream). A candidate upstream-tray report; not filed here.

## 6. Baseline diff (existing rows unchanged)

`git diff --stat tests/pnvi_lane/baseline.txt` before the header paragraph was added (verbatim):

```
 tests/pnvi_lane/baseline.txt | 13 +++++++++++++
 1 file changed, 13 insertions(+)
```

Zero `-` lines in the diff; `comm -23` of the sorted non-comment rows (old minus new) is empty (`0`) — every
one of the 164 existing rows keeps its class, oracle hash, `lean=` hash and `default=` flag. The 13 added
rows (verbatim):

```
+arm/a01-kill-symbolic-first-candidate AGREE oracle=181d22509af4 default=changed
+arm/a02-kill-symbolic-both-candidates-fail AGREE oracle=b56794acbf32 default=same
+arm/a03-kill-symbolic-collapsed-single AGREE oracle=9c28118899ea default=changed
+arm/a04-kill-symbolic-collapsed-single-fail AGREE oracle=b56794acbf32 default=same
+arm/a05-kill-symbolic-not-dynamic AGREE oracle=2d75d8dd6407 default=same
+arm/a06-eq-diff-symbolic-double-double AGREE oracle=1d436dcdfdc5 default=changed
+arm/a07-eq-diff-symbolic-single-collapse AGREE oracle=4678b3cb5087 default=changed
+arm/a08-eq-symbolic-single-double-fork AGREE oracle=56fba29670eb default=changed
+arm/a09-diff-mixed-symbolic-collapse AGREE oracle=eced1cf1d816 default=changed
+arm/a10-diff-mixed-symbolic-single-mismatch AGREE oracle=e2c9ede88799 default=same
+arm/a11-diff-symbolic-disjoint-singles AGREE oracle=96636f4edcc4 default=changed
+arm/a12-diff-symbolic-double-double-positional AGREE oracle=64d9c89c17cd default=same
+arm/a13-array-shift-prov-none AGREE oracle=7af5c2ff27e6 default=changed
```

(a02 and a04 share an oracle hash: the same two-execution Error answer.) No new row disagreed; no STOP.

## 7. Gates

**Gated tree:** branch `lane/pnvi-symbolic-rows` at HEAD `c4284b08f` plus the working-tree change set of this
slice's commit (release evidence `source_before` = `source_after`: tracked-diff sha256
`61db5b71fe751ac4ae9aee6c747a2e248bdebddb9d927c7b94ab3375e15d9e57`, this record's sha256 at the run
`1ad05248cb6669d2b3bed94b142fe717601b4f78415ab5b475449d2a70f2a8fe`). The ONLY edit after the run is this §7
(the gate lines below) — docs-only; no gate reads this file. Generated trees were re-derived in the worktree
before building (`make clean-prelude-src prelude-src`, `make lean-prelude-src`; `check_lem_sync: OK`), and
both engines were built by the lanes' own `build_cerberus`/`build_lean`. All runs via `scripts/ce`.

Tier A (`python3 scripts/release.py --mode fast`, evidence `.tmp/release/20261008T080020.917183Z`, 25:03 wall,
verbatim, the PASSED lines and the summary):

```
PASSED A1 (572.1s)
PASSED A2 (41.1s)
PASSED A3 (103.0s)
PASSED A4 (29.6s)
PASSED A4b (33.1s)
PASSED A4c (6.0s)
PASSED A5 (144.0s)
PASSED A6 (6.4s)
PASSED A6b (6.6s)
PASSED A7 (18.0s)
PASSED A8 (13.0s)
PASSED A9 (20.3s)
PASSED A10 (22.5s)
PASSED A11 (79.8s)
PASSED A12.1 (9.5s)
PASSED A12.2 (6.6s)
PASSED A13 (1.3s)
PASSED A14.1 (179.3s)
PASSED A14.2 (207.7s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

(The third line is the standing release-certification note for a fast run, as in the S4 record §8.2.)

Row 1 (`scripts/test_unit.sh`, A1 of that run, verbatim):

```
PnviArmsTest: 37/37 runtime witnesses passed
✓ pnvi-arms-test PASSED
Total: 18 passed, 0 failed
```

Row 14 (A14.1 / A14.2 of that run, verbatim):

```
test_pnvi: SELFTEST OK (control green; 10 engine plants RED — P1 flag ignored, P6 refuse-everything, P7a unnamed crash, P7b mirrored crash, P8a oracle crash vs Lean Error, P8b Error/Error failure class differs, P8c BOTH_FAIL Lean side moved, PO oracle ignores the switch, missing engine, empty selection; 7 baseline plants RED — deleted, phantom, relabelled refusal, oracle hash, default flag, malformed class, BOTH_FAIL lean hash missing)
```

```
test_pnvi: 177 row(s) run
SUMMARY: rows=177 AGREE=165 AGREE-FIRST=3 BOTH_FAIL=2 REFUSAL=7 | switch vs default (oracle): arm:same=5,changed=8 litmus:same=27,changed=17 minimal:same=111,changed=2 pkvm:same=1,changed=3 witness:same=0,changed=3
pnvi_lane: BASELINE OK (177 rows = the baseline, classes, oracle hashes and BOTH_FAIL/RESOURCE lean hashes exact)
```

The standalone runs before Tier A (same non-doc tree; `--selftest` then the lane, 3:08 wall for the lane)
gave the same SELFTEST OK, SUMMARY and BASELINE OK lines. An earlier Tier A run on that tree passed 19/19 but
reported `fast: incomplete` / `Source unchanged: False` because this record and the S4 addendum were edited
during it; it is superseded by the run above.

Cost [AGENT]: the lane pass is now 3:28 inside Tier A (MEASURED, A14.2) against 2:49 at S4; the 13 rows add
about 3 x 13 short engine runs. The LADDER row's Tier A rationale ("a few minutes") still holds.
