# PNVI arc S3: the PNVI-ae-udi arms and the §G refusals — slice record (2026-10-07)

Branch `arc/pnvi-ae-udi`. Base: `64c6724f0` (S2 record), then `bdd94f57a` (the S2 review fixes,
Part 1 of this slice; dispositions in `docs/2026-10-07_pnvi-s2-data-shapes-record.md` §10).
Worker: Claude Opus 5.5 (agent). Every judgement that no operator quote covers is marked
[AGENT]. Quoted gate output is verbatim; counts marked "derived" are mine. The lem used is the
shared `2d3a492` (the pin); no `.lem` file changed in this slice.

S3 is the arc's one forced semantics change (design record §E row S3). It stays behind the CLI
refusal: `--switches=PNVI_ae_udi` is still refused, so no lane can reach a new arm (§5).

**Gated tree:** the working tree that became the S3 code commit `4e43ed295` (row 1 and Tier A both ran on it; no Lean, script, lakefile or register byte differs between that tree and the commit). This record is a docs-only commit on top.

## 0. Rulings in force (verbatim) and governing documents

- [USER 2026-10-03]: "we should fall back to loudly rejecting (either as unsupported, or matching
  upstream)".
- [USER 2026-09-30]: "we should not fix deviations with special 'magic mode' paths that work
  exclusively in one situation".
- [USER 2026-10-05]: "agree on your recs except for mirroring crashes / obviously wrong behavior.
  These should be refusals surely?"
- [USER 2026-10-05], on §F.14–§F.16 (design record §H): "1 - agree. 2 - I think in the end we
  should make this consistent, but it's fairly minor. 3 - if we do (b) it should be a global
  policy. I don't think it necessarily needs to be a refusal, but it shouldn't be an uncontrolled
  crash. And for now (a) is fine". As recorded in §H: MIRROR the (D) sites `:2191`, `:2293`,
  `:2308`/`:2379`, `:2399`; REFUSE `:840-842`; default-path look-alikes UNCHANGED in this arc; the
  refusal shape is the `CerbFS` `failwithI`-with-prefix shape.
- [USER 2026-10-07]: "we don't want our gates to be adversarially robust unless they are trust
  surfaces".
- Design record `docs/2026-10-04_pnvi-ae-udi-design.md` §A.3, §C, §D, §E S3, §G (authoritative for
  every flagged site), §H. S2 record `docs/2026-10-07_pnvi-s2-data-shapes-record.md`. S1 record §14.

## 1. The arms written (OCaml = `memory/concrete/impl_mem.ml`, THIS tree's lines)

Each arm is written in upstream's evaluation order, with its cite in-code. Lean lines are this
commit's `lean_frontend/CerbMem.lean`.

| Arm | Lean | OCaml | Behaviour (mirrored) |
|---|---|---|---|
| `ptrfromint`, `is_PNVI` arm | `ptrfromint` :3332 | :2190-2205 | after wrapI: `n = 0` → `PVnull`; else `find_overlaping st n`: `NoAlloc` → `Prov_none`, `SingleAlloc id` → `Prov_some id`, `DoubleAlloc` → `add_iota` → `Prov_symbolic iota`. The integer's own provenance is ignored. `(* TODO: device memory? *)` (:2191) MIRRORED: no device range under PNVI (§G R7, §H) |
| `intfromptr`: exposure + `mk_ival` | `intfromptr` :3368 | :2483-2505 | `mk_ival` at all three results (:2486, :2488, :2505); `has_switch (PNVI AE) ∨ (PNVI AE_UDI)` → `expose_allocation` of a `Prov_some` BEFORE the range check (:2490-2498) — the exact upstream test, so `PNVI PLAIN` does not expose (was: one loud kill guarded by the coarser `is_PNVI`) |
| load's `expose_allocations` | `exposeOnLoad` :2776, `loadM` :2803 | :1600-1609 | the taint `reconstructValueAbst` returns is exposed under `AE ∨ AE_UDI`, before the receipt; then `last_used`, the trap check and `strict_reads` as before (S2 review F3). Placement detail: deviation D-S3-2 |
| kill, `Prov_symbolic` | `killM` :2591 | :1518-1553 | `is_dynamic addr` first (:1531-1539), then `resolve_iota` with the precondition :1520-1529 (dead → `Free_dead_allocation` whatever `is_dyn`; `get_allocation`; `addr = base` or `Free_out_of_bound`), then the retirement :1545-1549 and the zap switch (refused set, loud, as in the `Prov_some` arm) |
| load, `Prov_symbolic` | `loadM` :2803 | :1662-1684 | `resolve_iota` with the precondition dead → `DeadPtr`, `is_within_bound` (its `get_allocation` may fail) → `OutOfBoundPtr`, `is_atomic_member_access` → `AtomicMemberof`; then `do_load (Some id)` on the post-resolution state |
| store, `Prov_symbolic` | `storeM` :2894 | :1771-1804 | `resolve_iota` with the precondition `is_within_bound` → `OutOfBoundPtr` (no dead check on the store path), read-only → `MerrWriteOnReadOnly`, atomic member → `MerrAccess (LoadAccess, AtomicMemberof)` (upstream's `LoadAccess` on a store, :1787 — the `Prov_some` arm's quirk, mirrored; §G R18); then `do_store (Some id)` and the `is_locking` update |
| `validForDeref`, `Prov_symbolic` | `validForDerefPtrval` :3276 | :2152-2163 | `lookup_iota`: `Single a` → `do_test a`; `Double (a, b)` → `do_test a`, if false `do_test b` |
| `eq_ptrval`, `(Prov_symbolic, Prov_symbolic)` | `eqPtrval` :3040 | :1905-1914, tail :1916-1923 | `lookup_iota` both; `Single a, Single b` → `a = b`; otherwise `false`; `true` → address equality, `false` → `msum "pointer equality"` |
| `diff_ptrval`, `(symbolic, Prov_some)` / `(Prov_some, symbolic)` | `diffPtrval` :3160 | :2032-2060 | `Single a` → `a = id'` ∧ precond on `a`'s allocation; `Double (a, b)` → `id' ∈ {a, b}` ∧ precond on `id'`'s allocation, collapsing the iota to `Single id'` |
| `diff_ptrval`, `(symbolic, symbolic)` | `diffPtrval` :3160 | :2063-2105 | intersection: none → `MerrPtrdiff`; `Single i` → both iotas collapse (`IntMap.add iota1 … (IntMap.add iota2 …)`), valid with NO precond (as upstream); `Double` with `addr1 = addr2` → 0; with `addr1 ≠ addr2` → refusal R-PNVI-08 (§2) |
| `eff_array_shift`, bounds arms | `effArrayShiftPtrval` :3447 | :2378-2395 | the `is_PNVI ∧ ¬PERMISSIVE` disjunct of the guard is LIVE: `Prov_some` → `get_allocation` then `base ≤ shifted ∧ shifted + sizeof ty ≤ base + size + sizeof ty` (one past allowed) else `MerrArrayShift` (UB046); `Prov_none` → `MerrOther "out-of-bound pointer arithmetic (Prov_none)"`. `(* TODO: is it correct to use the "ty" as the lvalue_ty? *)` (:2308/:2379) MIRRORED (§G R15, §H). The `STRICT` disjunct stays the loud kill (refused switch). `Prov_device` shifts freely (:2396-2400, `(* TODO: check *)` MIRRORED, R17). The null arm (:2293-2296) is unchanged: the live UB046 arm, upstream's TODO-failwith is commented out (R14 MIRROR) |
| `eff_array_shift`, `Prov_symbolic` | `effArrayShiftPtrval` :3447 | :2301-2376 | `precond z` = the same bounds check under `is_PNVI ∧ ¬PERMISSIVE`, else `true`; `Double`, `ival ≠ 0`: both → refusal R-PNVI-10 (or no collapse under PERMISSIVE, mirrored); a only → collapse to a; b only → collapse to b; neither → `MerrArrayShift`; `ival = 0`: a ∨ b else `MerrArrayShift`; `Single a`: precond a else `MerrArrayShift` |

The state machinery S2 added is now written as state functions (deviation D-S3-1): `exposeAllocation`
:2296, `exposeAllocations` :2301, `addIota` :2310, `lookupIota` :2321, `IotaPrecondFn` :2337,
`resolveIota` :2346, `getAllocationE` :2370.

New lemmas in `CerbMem.lean` for a consumer (all `rfl` or short kernel proofs):
`findOverlapping_lastUsed` (:911), `resolveIota_lastUsed` (:2380), `exposeOnLoad_default`,
`exposeOnLoad_of_default`, `exposeOnLoad_lastUsed` (:2782-2801).

## 2. The refusals placed in S3 (the `CerbFS` shape ruled in §H)

Each is `failwithI (pnviRefusal "R-PNVI-nn: <site> — impl_mem.ml:<lines> <upstream text> …")`; the
message ends "refused, not mirrored (… design record … §G/§H)".

| Id | Site (Lean) | Upstream (§G row, class) | Reachable at `⟨[]⟩`? | Register |
|---|---|---|---|---|
| R-PNVI-01 | `combineProv`, both symbolic arms :377-378 | `:390-394` `failwith "Concrete.combine_prov: found a Prov_symbolic"` (R1, A) | no — needs a `Prov_symbolic` byte | 2 rows replaced (key changed), reviewed TAIL, UNREACHABLE-BY-INVARIANT |
| R-PNVI-04 | `lookupIota` :2325 | `:912-914` `IntMap.find` raises `Not_found` (R5, A) | no — called only on a symbolic pointer's iota | NEW row (pure since S3), TAIL, UNREACHABLE-BY-INVARIANT |
| R-PNVI-06 | `arrayShiftPtrval`, symbolic arm :1973 | `:2254-2255` `failwith "Concrete.array_shift_ptrval found a Prov_symbolic"` (R8, A) | no | row replaced (key changed), TAIL, UNREACHABLE-BY-INVARIANT |
| R-PNVI-07 | `casePtrval`, the `Prov_symbolic` half :1606 | `:1858` `| _ -> failwith "case_ptrval"` (R11 split) | no; the `Prov_device` half is a separate, UNCHANGED arm (default path, §G.3) | NEW row, TAIL, UNREACHABLE-BY-INVARIANT; the device row (REACHABLE) unchanged |
| R-PNVI-08 | `diffPtrval`, `Double ∩ Double`, `addr1 ≠ addr2` :3234 | `:2104` `fail (MerrOther "in `diff_ptrval` invariant of PNVI-ae-udi failed: …")` (R12, A′) | no | none: a `failwithI` inside a `memM` definition is the census's `monadic_ascribed` group, outside the pure-site register by its design (S2's monadic `lookupIota` was the same, D8 there) |
| R-PNVI-10 | `effArrayShiftPtrval`, symbolic, `Double`, `ival ≠ 0`, both preconditions, not PERMISSIVE :3480 | `:2331-2334` `Printf.printf "id1= …"` to STDOUT, then `fail (MerrOther "(PNVI-ae-uid) ambiguous non-zero array shift")` (R16, B) | no | none (monadic, as R-PNVI-08). Nothing is written to stdout |

Placed in S2 and unchanged: R-PNVI-01b (`provsOfBytes`), -02, -03 (`findOverlapping`), -05
(`reconstructValueAbst_lemFuel`). R-PNVI-11/12 are S1's CLI refusals.

**NOT placed: R-PNVI-09** (`eff_array_shift_ptrval`, `PVfunction`, `:2298` `failwith
"Concrete.eff_array_shift_ptrval, PVfunction"`). This is a stop-and-report item, §6.

**Register** (`scripts/failure_reach_register.txt`): re-emitted with `check_failure_reach.sh
--emit` (seeded from the S2 register), the 5 UNREVIEWED rows reviewed as in the table, the 3 stale
rows dropped, and `--reseal` run. The stale reason text "ptrfromint's PNVI arm is a loud kill" in
the `provsOfBytes` row and the R-PNVI-03 row's "applied only in reconstructValueAbst's is_PNVI
branch" were rewritten (need column, not sealed). Tally `sites=237` → `sites=239 exec=237
unresolved-owner=2 reviewed-TAIL=176 reviewed-NON-TAIL=63 UNREACHABLE-BY-INVARIANT=178 REACHABLE=40
UNKNOWN=21 discardable=0`. No new check; the register gate is the existing trust gate.

## 3. Unit pins (`lean_frontend/test/Unit/PnviArmsTest.lean`, row-1 exe `pnvi-arms-test`)

**Runtime witnesses** (36; output verbatim in §8.1). Hand-built states: id 0 = [100, 108), id 1 =
[108, 116), taints chosen per check; iota maps set explicitly. Every arm has a characteristic
witness under `⟨[.PNVI .AE_UDI]⟩`, and each group has a control at `⟨CerbGlobal.defaultSwitches⟩`:

- exposure on cast: `intfromptr` exposes allocation 0 and returns `IV Prov_none 104`; under PLAIN it
  strips the provenance without exposing; DEFAULT returns `IV (Prov_some 0) 104`, no exposure;
- `ptrfromint` after that exposure → `Prov_some 0`; without it → `Prov_none`; it ignores the
  integer's provenance; DEFAULT keeps the integer's provenance (PVI arm);
- iota minting at the ambiguous address 108 (one past exposed 0, inside exposed 1) →
  `Prov_symbolic 0`, `iotaMap[0] = Double 0 1`, `nextIota = 1`; DEFAULT → `Prov_none`, no iota;
  `ptrfromint 0` → `PVnull`;
- `resolve_iota` narrowing: a load through iota 0 at 108 resolves to 1 (0 is out of bounds),
  collapses the iota and sets `last_used`; at 116 both preconditions fail and the reported error is
  the SECOND (`OutOfBoundPtr`); a kill at 112 with 0 dead reports the second failure
  (`Free_out_of_bound`, not `Free_dead_allocation`);
- the symbolic kill, store and `validForDeref` arms; `eq_ptrval` across iotas (`Single 1`/`Single 1`
  → true; `Single 0`/`Single 1` and a `Double` → the `msum` fork); `diff_ptrval`'s mixed collapse,
  the symbolic/symbolic `Single` intersection, disjoint iotas → `MerrPtrdiff`, `Double ∩ Double` at
  one address → 0;
- `eff_array_shift`: one past allowed, one beyond → UB046, `Prov_none` → the `MerrOther`, the symbolic
  collapse, `ival = 0` without collapse, the `Single` failure; DEFAULT shifts freely;
- load's exposure: loading a stored `&obj1` as `unsigned long` exposes allocation 1 and yields `IV
  Prov_none 108`; DEFAULT keeps `Prov_some 1` and exposes nothing.

**Refusal pins** (compile time; the module does not build if one fails): each refusal reachable by a
closed term is reduced by `whnf` and must be `failwithI (pnviRefusal d)` with `d` starting
`R-PNVI-nn:` — R-PNVI-01 (both arms), -03 (three candidates at one address, a zero-size allocation
in the middle), -04, -05, -06, -07, -08, -10; fuel'd terms are pinned for EVERY fuel (`fun k => …`,
no fuel numeral). Two negative controls: a mirrored default arm and `casePtrval`'s `Prov_device`
half must NOT reduce to a PNVI refusal. The pure sites also carry kernel facts `∃ d, … = failwithI
(pnviRefusal d) := ⟨_, rfl⟩`. Not pinnable by a closed term: -01b (its failure sits inside a fold
whose result is then matched), -02 (structurally unreachable).
**Plant check** of the pins [AGENT, scratch, not committed]: a copy of the module with the R-PNVI-08
pin relabelled -09, a mirror term pinned as R-PNVI-01, and a refusal used as a negative control
failed to elaborate with the three expected messages (verbatim, first 160 characters):

```
.tmp/PlantPins.lean:293:0: error: PnviArmsTest: expected refusal R-PNVI-09, got detail R-PNVI-08: diff_ptrval, (Prov_symbolic, Prov_symbolic), ambiguous intersection with addr1 <> addr2 — impl_mem.ml:2104 `fail ~loc (M
.tmp/PlantPins.lean:295:0: error: PnviArmsTest: R-PNVI-01 — the term does not reduce to `failwithI (pnviRefusal …)` (a mirror or a bare crash?)
.tmp/PlantPins.lean:296:0: error: PnviArmsTest: a negative control reduced to a PNVI refusal: R-PNVI-04: lookup_iota, iota
```

Class [AGENT, per [USER 2026-10-07]]: the pins are unit tests of this slice's arms, not a new gate.

## 4. Test-proof maintenance

`test/Unit/MemoryAccessProofs.lean` (SC WP0's erasure theorems `load_erasure`/`store_erasure`,
statements unchanged) timed out at `whnf` (200000 heartbeats) after the S3 arms. Cause [AGENT,
measured on the goals]: the old proofs unfold `stopObserving` over the whole result state, and a
record update of a non-variable source copies that state into each of the 15 fields — with the new
`resolveIota` branches the goal grew past the budget. The new proofs push the erasure through with
`rfl` field lemmas (`stop_dead`, `stop_allocs`, …, `stop_fo` via `findOverlapping_congr`),
`stop_exposeOnLoad`, `recordAccess_off`, and `stop_resolve` (resolveIota commutes with erasing the
buffer, side condition `rfl`), splitting on the pointer first. No option bump. Axiom cones
(build output): `load_erasure`, `store_erasure` `[propext, Classical.choice, Quot.sound]`. The load
exposure's placement (D-S3-2) came out of the same measurement.

## 5. Zero default-mode change: evidence

1. **No `.lem` file changed** (`git diff --stat 64c6724f0..HEAD -- frontend/` is empty), so the
   generated OCaml and the generated Lean are unchanged; row 1's `check_lem_sync` prints the same gen
   hashes as S1/S2 (`c1bb429a…` OCaml, `aa49e3bf…` Lean) and the fork-drift layer 2 is unchanged
   (§8.1).
2. **Every new arm is unreachable at `⟨[]⟩`**: each sits behind `is_PNVI ()`, `has_switch (PNVI AE) ∨
   (PNVI AE_UDI)` or `is_PNVI ∧ ¬PERMISSIVE` (each `false` by `rfl` at the default instance:
   `CerbGlobal.is_PNVI_default`, `has_switch_PNVI_default`, `exposeOnLoad_default`), or behind a
   `Prov_symbolic` pointer, which only ptrfromint's `is_PNVI` arm mints. The default-instance
   controls of §3 run the default arms.
3. **No signature changed**: `killM`, `loadM`, `storeM`, `eqPtrval`, `diffPtrval`,
   `validForDerefPtrval`, `ptrfromint`, `intfromptr`, `effArrayShiftPtrval` keep their binders
   (`storeM` still binds no `[CerbGlobal.Switches]`; `killM`, `ptrfromint`, `intfromptr`, `eqPtrval` no
   `[LemFuel]`) — D-S3-1.
4. **`PNVI_ae_udi` stays CLI-refused**: `check_cli_refusals: OK (23 refusals pinned …` (§8.1).
5. **Lanes**: Tier A on the S3 code commit, every row at its committed baseline; A9 (C→Core) at its
   recorded `same=108 diff=5` (§8.2).
6. **Default-path look-alikes unchanged** (§H, §G.3): `arrayShiftPtrval`'s `PVnull`/`PVfunction`
   failwiths, `casePtrval`'s `Prov_device` half, the store's ill-typed print-then-kill, and
   `effArrayShiftPtrval`'s `PVfunction` fail-stop (§6) keep their pre-S3 text and behaviour.

## 6. Stopped on: R-PNVI-09's premise (not decided here)

§G.1 row R13 classifies `eff_array_shift_ptrval`'s `PVfunction` arm (`:2298`, `failwith
"Concrete.eff_array_shift_ptrval, PVfunction"`) as (A) → REFUSE `R-PNVI-09`, with "Also default
path? **no** (`PtrArrayShift` is not emitted in default mode)". That premise does not hold
(MEASURED, grep): `runtime/libcore/std.core:188, :196, :212, :217` contain live `memop(PtrArrayShift,
…)` in `rev_listFromStr_aux`/`rev_listFromArray_aux`, and `std.core:293` (`printf_proxy`) calls
`listFromStr` on every `--nolibc` `printf` format string — so `effArrayShiftPtrval` runs in default
mode. Whether its `PVfunction` arm is C-reachable in default mode is UNKNOWN: the one route tried
(`printf((const char *)main)`, `--nolibc`) stops earlier on the oracle at the cast's alignment check,
`Error {msg: "MerrOther "called isWellAligned_ptrval on function pointer""}` (MEASURED), the same
domination the register records for the pure `array_shift_ptrval`'s `PVfunction` row (UNKNOWN).

So R13 has the shape of R10 (the pure shift's `PVfunction` arm, "also default path: YES → NOT
DECIDED HERE"). Under §1.4/§H (default mode stays bit-identical; default-path look-alikes unchanged)
the site was left exactly as it was — the mirrored fail-stop with upstream's text — and is reported
for the operator's classification [AGENT: leaving it unchanged is the not-deciding, minimum-change
option; refusing it only under a PNVI set would be a mode-split path]. The design record's §G.1 R13
"no" and the §A.3 #31 sentence "reachable ONLY under strict/PNVI/CHERI" are the two places to amend
once decided. Nothing else in S3 depends on it.

No other flagged site or TODO/FIXME outside §G's classification was met. MEASURED: the design
appendix's `awk 'NR>=277 && NR<=2830' … | grep -n -E 'FIXME|HACK|TODO|assert false|failwith|Printf\.printf|print_endline|…'`,
restricted to the OCaml ranges of the arms written, lists only §G rows (R1, R7, R8, R11's wildcard,
R13, R14–R17, R19 at :1542/:1663/:1772/:2303/:2323/:2356), default-path lines this slice leaves
unchanged (:1515, :1572, :1576, :1593, :1598, :1613, :1619, :1695, :1710, :1716-1721, :2173, :2182,
:2209, :2259-2263 — §G.3/§G.4), and three COMMENTED-OUT debug prints with no TODO text and no
behaviour (`(* KKK print_endline ("HELLO …") *)` :2289, :2302; the `Printf.printf "validForDeref: …"`
inside the comment block :2131-2136) [AGENT: inert; nothing to classify].

## 7. Informal litmus comparison (NOT a gate; scratch, deleted)

A scratch build of the driver with Main's instance set to `⟨[.PNVI .AE_UDI]⟩` (a temporary edit of
`Main.lean`, built, the binary copied to `.tmp/`, the edit reverted and the tree rebuilt — `git
diff` of `Main.lean` empty before any gate) ran 11 litmus files of `tests/pnvi_testsuite/` in libc
mode (`--batch`, exhaustive, the pinned `tests/libc/libc.core` + 12 metadata TUs), against this
worktree's oracle with `--exec --batch --mode=exhaustive --switches=PNVI_ae_udi`. Byte comparison of
the two stdouts: 10 identical verdict streams; 1 registered-refusal row. Verbatim (first lines):

```
=== pointer_from_int_disambiguation_1
ORACLE rc=0: Defined {value: "Specified(0)", stdout: "x=1 y=11 *q=11 *r=11\n", stderr: "", blocked: "false"}
LEAN   rc=0: Defined {value: "Specified(0)", stdout: "x=1 y=11 *q=11 *r=11\n", stderr: "", blocked: "false"}
=== pointer_from_int_disambiguation_3
ORACLE rc=1: Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<20:7--20:10>"}
LEAN   rc=1: Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<20:7--20:10>"}
=== cheri_03_ii
ORACLE rc=1: Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<6:12--6:18>"}
LEAN   rc=1: Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<6:12--6:18>"}
=== pointer_offset_xor_auto
ORACLE rc=0: Defined {value: "Specified(0)", stdout: "x=1 y=11 *r=11 (r==p)=true\n", stderr: "", blocked: "false"}
LEAN   rc=0: Defined {value: "Specified(0)", stdout: "x=1 y=11 *r=11 (r==p)=true\n", stderr: "", blocked: "false"}
=== provenance_basic_using_uintptr_t_global_yx
ORACLE rc=125:
Failure("Concrete.combine_prov: found a Prov_symbolic")
LEAN   rc=134:
PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: PNVI_ae_udi refusal (unsupported upstream arm): R-PNVI-01: combine_prov, a Prov_symbolic provenance (first argument) — impl_mem.ml:390-394 `(* TODO: this is improvised, need to check with P *)` … `failwith "Concrete.combine_prov: found a Prov_symbolic"` — refused, not mirrored (upstream crashes, debug-print arms and self-declared-wrong arms on the PNVI path are loud refusals: design record docs/2026-10-04_pnvi-ae-udi-design.md §G/§H) backtrace: …
=== pointer_from_int_disambiguation_2
ORACLE rc=0: Defined {value: "Specified(0)", stdout: "x=11 y=2 *q=2 *r=11\n", stderr: "", blocked: "false"}
LEAN   rc=0: Defined {value: "Specified(0)", stdout: "x=11 y=2 *q=2 *r=11\n", stderr: "", blocked: "false"}
=== provenance_union_punning_2_auto_yx
ORACLE rc=1: Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<16:5--16:12>"}
LEAN   rc=1: Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<16:5--16:12>"}
=== pointer_arith_algebraic_properties_2_global
ORACLE rc=0: Defined {value: "Specified(0)", stdout: "x[1]=11 *p=11\n", stderr: "", blocked: "false"}
LEAN   rc=0: Defined {value: "Specified(0)", stdout: "x[1]=11 *p=11\n", stderr: "", blocked: "false"}
=== pointer_copy_user_ctrlflow_bitwise
ORACLE rc=0: Defined {value: "Specified(0)", stdout: "*p=11  *q=11\n", stderr: "", blocked: "false"}
LEAN   rc=0: Defined {value: "Specified(0)", stdout: "*p=11  *q=11\n", stderr: "", blocked: "false"}
=== pointer_offset_from_int_subtraction_global_xy
ORACLE rc=0: Defined {value: "Specified(0)", stdout: "Addresses: &x=281474976707772 &y=281474976707768 offset=18446744073709551612 \nx=1 y=11 *p=11 *q=11\n", stderr: "", blocked: "false"}
LEAN   rc=0: Defined {value: "Specified(0)", stdout: "Addresses: &x=281474976707772 &y=281474976707768 offset=18446744073709551612 \nx=1 y=11 *p=11 *q=11\n", stderr: "", blocked: "false"}
=== provenance_equality_auto_yx
ORACLE rc=0: EXECUTION 0: Defined {… "(p==q) = true\n" …} EXECUTION 1: Defined {… "(p==q) = fa…
LEAN   rc=0: EXECUTION 0: Defined {… "(p==q) = true\n" …} EXECUTION 1: Defined {… "(p==q) = fa…
```

(The last pair is abbreviated with "…" by me; the two files are byte-identical. The
`provenance_basic_using_uintptr_t_global_yx` pair compares equal only because both stdouts are
empty: it is the registered refusal row `R-PNVI-01: ORACLE_CRASH / UNSUPPORTED` of design §D.5,
never agreement.) Early signal for S4 [AGENT]: the iota machinery (`disambiguation_1/2/3`, measured
§C.6 as the files that load and store through symbolic pointers), the PNVI bounds arm
(`cheri_03_ii`, `disambiguation_3`), the exposure-driven UB→Defined rows and the union-punning
kind/location move all agree with the oracle on these files. Nothing was tuned to them. The 6561-
execution file and the pKVM drivers were not run.

## 8. Gates

### 8.1 Row 1 (`scripts/test_unit.sh`, via `scripts/ce`)

Verbatim selected lines (each distinct line once, in this order; the `rc=0` line is my wrapper's),
run on the working tree that became the S3 code commit (Lean rebuilt capped, `Build completed
successfully (398 jobs).`):

```
✓ memory-access-test PASSED
✓ pnvi-arms-test PASSED
PnviArmsTest: 36/36 runtime witnesses passed
Total: 18 passed, 0 failed
check_handwritten_sync: OK (50 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_theorem_axioms: mem-scale S1 leg OK (11 C1/C3 + PNVI-S2 wrapper equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_sorry_token: OK (329 files scanned comment-stripped — generated 222, hand-written+test 72, LemLib 35; 0 sorry tokens)
check_no_fuel_numerals: SELFTEST OK (31 plants red with the declared label — F1-F6, A1-A3, W1 and W2; E5 indirection a recorded known gap; unplanted set green)
check_no_fuel_numerals: OK (336 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3), no switch-set instance declaration (W1), no production call of the default-pinned reconstructValue wrappers (W2); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy); W2 wrapper lines seen: 6 of 6)
check_lakefile_roots: OK (221 roots = 221 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
check_fuel_forms: OK (81 fuel'd workers: 63 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 5 ambient unreachable from the drive cone)
check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=178 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_pin_sites: OK — lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
rc=0
```

`pnvi-arms-test`'s 36 `ok` lines are the §3 witnesses, one per line; none printed `FAIL`.

### 8.2 Tier A (`python3 scripts/release.py --mode fast`, via `scripts/ce`)

Verbatim row verdicts (the 17 per-row `PASSED` lines joined onto one line; the joining is mine)
and the tail; `rc=0` is my wrapper's. Same working tree as row 1:

```
PASSED A1 (466.4s) PASSED A2 (35.0s) PASSED A3 (73.5s) PASSED A4 (23.4s) PASSED A4b (25.2s) PASSED A4c (3.3s) PASSED A5 (105.0s) PASSED A6 (4.1s) PASSED A6b (3.7s) PASSED A7 (10.7s) PASSED A8 (9.1s) PASSED A9 (17.5s) PASSED A10 (18.9s) PASSED A11 (60.0s) PASSED A12.1 (5.0s) PASSED A12.2 (4.6s) PASSED A13 (1.6s)
fast: passed; 17/17 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

The lanes' own last lines, verbatim from the run's evidence directory (scratch, deleted at slice
end; the row labels and the `/` joins are mine):

```
A2   Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A3   Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A4   Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A4b  Baseline check: 0 regression(s), 0 improvement(s)/BASELINE OK
A4c  SUMMARY: exec_match=9 neg_pinned=5 fail=0/ALL AT COMMITTED EXPECTEDS
A5   SUMMARY: match=43 diff=0/ALL MATCH RECORDED BASELINE
A6   SUMMARY: total=8 match=8 fail=0/ALL PASSED
A6b  SUMMARY: total=7 match=7 fail=0/ALL PASSED
A7   cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)/ALL PASSED
A8   Success rate:   100% (of cerberus successes)/ALL PASSED
A9     LEAN_FAIL:  0/SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
A10  GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
A11  BASELINE OK (213 entries, exact match)
A12.2  EXPECT OK    18 pinned rows = 18 observed cases, every token identical/test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
A13  PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls
```

A9's five DIFF rows are the recorded ones (`073-exit.libc`, `074-abort.libc`,
`098-cross-alloc-ptrdiff.undef`, `112-allocator-exhausted-single-request`,
`113-allocator-exhausted-single-request-overlap`; S1 record §7.1, S2 record §6.2): the default-mode
C→Core elaboration did not move.

## 9. Deviations

- **D-S3-1 [AGENT] — S2's monadic iota helpers became state functions.** `exposeAllocation(s)`,
  `addIota`, `lookupIota` and `resolveIota` (with the precondition type `IotaPrecondFn` returning an
  `Except`) are functions of the state. Four callers (`killM`, `ptrfromint`, `intfromptr`,
  `eqPtrval`) bind no `[LemFuel]`; a monadic form over the fuel'd `nd_bind` would add that binder to
  their signatures, a lem `fuel_consumer` declaration, generated-Lean movement and consumer term
  changes, for no behavioural gain. Upstream's helpers only read/update the state; a precondition's
  own `fail` (`get_allocation`) is the `.error`, which aborts the resolution exactly as upstream's
  kill does. Consumer mentions of the S2 names: 0 (MEASURED grep, §10).
- **D-S3-2 [AGENT] — load's exposure is applied after `last_used`.** Upstream exposes, then sets
  `last_used` (:1602-1609). Here `exposeOnLoad taint { st0 with lastUsed := … }`: the two touch
  disjoint fields, proved by `exposeOnLoad_lastUsed`; the receipt still follows the exposure. Reason:
  the upstream order puts a non-variable source under a record update, which copies the whole
  exposure term into every field when `loadM` is unfolded — the measured cause of the erasure proofs'
  timeout (§4). Documented in-code as a deliberate placement divergence.
- **D-S3-3 [AGENT] — an unreachable store branch is a fail-stop.** After `resolveIota` succeeds,
  `storeM`'s symbolic arm reads the resolved allocation to pass it to `doStore`; its absence is
  impossible (the precondition's `get_allocation` found it in the same map; resolution writes only
  `iotaMap`). That branch is a loud `failStopKill`, where upstream's `IntMap.update` would no-op.
- **D-S3-4 [AGENT] — `STRICT` stays a loud kill in the symbolic `eff_array_shift` arm too**, consistent
  with the other arms (design §A.6: only the `is_PNVI` disjunct becomes real); the precondition's
  test is then `is_PNVI ∧ ¬PERMISSIVE`, equivalent to upstream's once `STRICT` is excluded. The
  `PERMISSIVE` effects (no collapse; `precond = true`) are mirrored.
- **D-S3-5 [AGENT] — two unreachable fallbacks in `eff_array_shift`'s bounds arms.** Inside the
  guarded branch `prov` cannot be `Prov_device` (excluded by the guard) or `Prov_symbolic` (matched
  earlier); the former mirrors :2396-2400's arm, the latter is a `failStopMem`, never absorbed.
- **D-S3-6 — R-PNVI-09 not placed** (§6).
- **D-S3-7 [AGENT] — R-PNVI-08 and -10 have no register row** (monadic definitions; §2).
- **D-S3-8 [AGENT] — refusal messages and evaluation order.** Where two lookups are discriminants of
  one Lean `match` (`eqPtrval`, `diffPtrval`), the order in which an R-PNVI-04 could fire is the
  compiler's; only the message could differ, and it is unreachable.
- **D-S3-9 — test proofs rewritten** (§4), statements unchanged.
- **D-S3-10 [AGENT] — Part 1's bridges live in a new seam** `CerbMemDefaultFacts.lean`, excluded
  from W2 by name (S2 record §10, F1).

## 10. Consumer-visible changes for S5 (cerberus-sl)

**Method.** Read-only greps of cerberus-sl at `7a2f9a2`, `.lake/` and `.tmp/` excluded; scratch
replicas of their proof SHAPES elaborated against this tree in this worktree's `.tmp/` (their
`ndRun` restated, a local instance at `defaultSwitches`), then deleted. Their tree was not built.

**Signatures: none changed** (§5 item 3). Changed TERMS (bodies): `killM`, `loadM`, `storeM`,
`eqPtrval`, `diffPtrval`, `validForDerefPtrval`, `ptrfromint`, `intfromptr`, `effArrayShiftPtrval`,
`combineProv`, `arrayShiftPtrval`, `casePtrval`; their frozen fingerprints that cover terms may drift
(S5 measures). Consumer mention counts (MEASURED grep): `killM` 46, `eqPtrval` 174,
`validForDerefPtrval` 27, `storeM` 98, `loadM` 123; `diffPtrval`, `ptrfromint`, `intfromptr`,
`effArrayShiftPtrval` 0; the S2 iota helpers 0.

**Shapes they will meet when unfolding:**
- `loadM`: `doLoad` takes its state; the receipt's state is `exposeOnLoad (…).1 { st0 with lastUsed
  := … }` — rewrite with `exposeOnLoad_of_default rfl` (their instance) or `exposeOnLoad_default`;
  the value with `loadM_reconstruct_eq_reconstructValue rfl` (`CerbMemDefaultFacts`).
- `loadM`/`storeM`/`killM`: a `Prov_symbolic` arm with `resolveIota` (more `split` levels in their
  fixed-depth `split` chains).
- `eqPtrval`: the concrete arm is `match prov1, prov2 with | .Prov_symbolic …, .Prov_symbolic … =>
  … | _, _ => eqResult sameProv` with `eqResult` a local `let`.
- `diffPtrval`: `precond`/`validPostcond` are local functions.

**MEASURED on scratch replicas** (verbatim class of failure; S2-state results in the S2 record §10):
- `UnseqReads.lean:167` `loadM_result_lastUsed`: S3 → `(deterministic) timeout at whnf` (S2: unsolved
  goals, fixed by one `findOverlapping_congr` rewrite; that fix no longer suffices). A variant adding
  `findOverlapping_lastUsed` and `resolveIota_lastUsed` (new in this slice) to the same 9-deep
  `split` chain still timed out. Prediction: the proof needs the structured shape this slice used for
  `load_erasure` (§4: split on the pointer first, `resolveIota_lastUsed` by `rw`, field lemmas, no
  blind chain) — feasibility shown by `load_erasure` itself.
- `MemLoc.lean:15` `killM_loc_indep`: S3 → unsolved goals. Cause [AGENT]: the symbolic kill arm's
  precondition carries `loc` inside `FAIL`/`get_allocation`, so the two runs' `resolveIota` calls are
  different terms; a loc-insensitivity argument about the resolution's success is needed.
- `ExecInv.lean:355` `loadM_fp_read`: elaborates unchanged.
- `UnseqReads.lean:154`, `MemLoc.lean:27`: fail for the pre-existing SC WP0 reason (S2 record §10).
- Not replicated: `HeapModel.lean:365-397/:425` (`loadM_active_nontrap`): predicted edit [AGENT] —
  after `unfold loadM`, `rw [loadM_reconstruct_eq_reconstructValue rfl, exposeOnLoad_of_default
  rfl]` (or `simp only` with them) before their `generalize hmv : reconstructValue …`, plus S1's
  switch facts; `PtrEqModel.lean`: see the next item.
- `PtrEqModel.lean:35-90` (`eqPtrval_loc_indep`, `_null_null`, `_concrete_null`, `_same_prov`,
  `_diff_prov`, the last two `simp only [eqPtrval, …]; rfl`): all five elaborate unchanged against
  this tree (MEASURED on a replica, with local stand-ins for their `int_beq_refl` /
  `lem_int_beq_iff` helpers and S1's local instance).

**New names in `CerbMem`**: `exposeOnLoad` (+ `_default`, `_of_default`, `_lastUsed`),
`IotaPrecondFn`, `getAllocationE`, `findOverlapping_lastUsed`, `resolveIota_lastUsed`; changed types:
`exposeAllocation`, `exposeAllocations`, `addIota`, `lookupIota`, `resolveIota` (D-S3-1). New module
`CerbMemDefaultFacts` (Part 1).

## 11. Not done (S3 scope)

- The S4 lane (`scripts/test_pnvi.sh`), the CLI acceptance, plants P1–P8, CONTRACT/VALIDATION §3(c)/
  SUPPORTED/LADDER rows, the upstream-tray drafts (R1's crash, R16's debug print, the CLI fail-open).
- R-PNVI-09 (operator classification, §6).
- The S5 scratch build of cerberus-sl.
- Tier B (arc end / pre-merge).
