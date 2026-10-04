# Supporting `--switches=PNVI_ae_udi`: design record (2026-10-04)

**Status:** DESIGN PASS — one record, nothing implemented. Branch `design/pnvi-ae-udi-20261004` over mainline
`ae48126e5`. Author: the design-pass agent [AGENT]. Every claim below is marked **[AGENT]** (this agent's reading or
judgement) or **MEASURED** (a command run in this pass, output quoted verbatim). The only [USER] items are the three
quotes in §1; the consumer's position is a *consumer statement* (§1.3), not a ruling. No build of any kind was run; the
oracle probes used the census worktree's already-built binary (§C.0). Scratch lived under this worktree's `.tmp/` and
was deleted before the commit.

Occasion: the real-C reach census (`docs/2026-10-04_real-c-reach-census.md` §4.1, §6 item 2): the pKVM buddy
allocator — the north-star target class — runs to native gcc's values on the oracle only under `PNVI_ae_udi`, because
in the default (PVI) model `copy_alloc_id` (`memory/concrete/impl_mem.ml:2810-2814`) keeps only the integer's own
provenance, which page arithmetic never carries; cerberus-lean refuses every switch (Z-24). Scope ([USER 2026-10-04],
relayed by the orchestrator): mirror upstream's `PNVI_ae_udi` behaviour exactly; only `PNVI_ae_udi` becomes supported;
the switch set becomes an explicit parameter of the semantics in the address-space-top style; cerberus-sl's relied-upon
signatures must not break without its agreement.

## 0. Summary — read this first

- **Inventory (§A).** 37 `impl_mem.ml` rows depend on the PNVI switch family (§A.1–A.5, derived count), plus 14
  generated read sites outside `CerbMem` (excluding the 32 `is_CHERI` constants), 3 of which — the elaborator's
  `is_PNVI` sites — change value under the switch. Of the 37: **9 PRESENT** in `CerbMem.lean` as faithful default arms
  or data (types, `Prov_symbolic`, `taint`, `nextIota`, `splitBytesProv`'s `ValidPtrProv`, the receipt view,
  `copy_alloc_id`, the relationals, `op_ival`); **1 present with the wrong type** (`MemState.iotaMap : List (Int × Int)`
  for OCaml's `Single | Double` map); **1 present as a constant** (`is_PNVI () := false`); **7 PRESENT as loud stops** at
  the exact arm position (the H2 `if has_switch … then <loud kill> else <default>` shape and the `Prov_symbolic` kills)
  that must become real arms (kill/load/store/validForDeref/eff_array_shift symbolic arms, `ptrfromint`, `intfromptr`);
  **1 unchanged stop** (`zero_initialised`, a refused switch); **11 MISSING** (`find_overlaping`, the exposure machinery
  ×2, the iota machinery ×2, `provs_of_bytes`, `mk_ival`'s PNVI branch, `abst`'s PNVI pointer arm and taint, load's
  `expose_allocations` arm, `eq_ptrval`'s and `diff_ptrval`'s iota arms); **3 upstream `failwith`s that stay stops**
  (`combine_prov` on a symbolic byte — which the oracle itself hits on 4 of its own 44 litmus files under the switch,
  §C.2; `array_shift_ptrval` on a symbolic pointer; `case_ptrval`'s wildcard); **2 new `failwithI` mirrors** (an
  `assert false` and an `IntMap.find`); **2 defined arms carrying a TODO/debug** (`abst`'s commented-out `failwith`; the
  stdout `Printf.printf` before a kill). The failure-reach register's reason text for the three `Prov_symbolic` stops
  is wrong ("symbolic execution mode") and those rows become reachable (§A.6).
- **Threading (§B).** Three options. **Option 3 — the switch set as an instance-implicit ambient parameter in the
  fuel-arc shape (`[LemFuel]`)** is recommended: one mechanism for the frontend, the run and the hand-written memory
  model; no positional signature changes (`initial_driver_state`, `drive`, `runNDFuel`, `eqPtrval`, `loadM`… are
  textually unchanged); default facts by `rfl` at the default instance; quantify by binding the instance; reasoning
  under the switch later needs no second signature change. Its cost is one lem-lean mechanism slice (the reader fixpoint
  emitting an instance binder instead of an explicit one — the fuel lifting already does exactly this for `[LemFuel]`).
  Option 1 (the explicit reader the project planned as "step 2") is the fallback: zero backend work, but the consumer's
  (c)-class churn (~900 textual sites, the `drive` family and every memory op gain leading arguments). Option 2 (the
  consumer's preferred state field) is **not recommended**: the elaborator consults the switch during C→Core (MEASURED
  §C.4: `--pp core` differs), so a memory-state field cannot be the only carrier — it needs a second and a third carrier
  (translation state, core-run state) plus a "copies agree" invariant for any reasoning under the switch, and it still
  changes `translate`/`desugar`/`initial_driver_state`. In **every** option `reconstructValue` must change (OCaml's
  `abst` takes a `find_overlaping` closure over the state): 11 consumer sites.
- **Measured (§C).** Litmus suite, 44 `.c` files, exhaustive on the oracle: 27 unchanged, 17 changed by the switch
  (9 UB→Defined; 2 UB→a different UB kind at a different location; 1 UB→UB046 at a different location; 1
  Defined→UB046; 4 **oracle crashes** rc 125 `Failure("Concrete.combine_prov: found a Prov_symbolic")` where default
  mode gives UB043). pKVM: the three drivers
  reach gcc's values; `pkvm_init`'s UB088 keeps its code but its **location changes** (`<715:2--715:17>` →
  `<715:2--715:6>`) — the elaboration differs under the switch. The oracle **ignores** an unknown or duplicate switch
  name with a stderr note and runs anyway (fail-open on the oracle); Lean should refuse.
- **Validation (§D).** A new differential lane under the switch (litmus 44 + pKVM 4 in `--first` + a default-corpus
  sample), harness-level plants (a wrapper that strips the flag must turn the lane red; a build that treats the switch
  as default must turn it red), `check_cli_refusals.sh` flips `PNVI_ae_udi` to an acceptance control and adds every
  other switch spelling as a refusal, the failure-reach register is re-classified, and the default-mode ladder (Tier A+B)
  must show zero movement at every slice.
- **Slices (§E).** S0 lem-lean mechanism (option 3 only) → S1 parameter plumbing (zero movement) → S2 PNVI data shapes
  (zero movement) → S3 the PNVI arms (the forced semantics change; still CLI-refused, zero movement) → S4 the lane,
  the CLI acceptance, docs → S5 consumer note. Roughly M, M, M, L, M, S.
- **Open questions (§F):** 13, each with a recommendation; §F.11 lists what a future reasoning effort under the switch
  would need that this implementation does not provide.

## 1. Rules and inputs this design obeys

### 1.1 Rulings (verbatim, from the orchestrator's brief)

- **[USER 2026-10-03], no innovation:** "Generally, our rule is that we don't innovate wrt Cerberus-upstream, unless
  something is very very very obviously a bug. We're poorly placed to resolve semantic discrepancies, so we don't. ...
  we should fall back to loudly rejecting (either as unsupported, or matching upstream)." Also: "We do not resolve
  Cerberus TODO cases unless the answer is extremely obvious or if there's a similarly obvious bug". Applied: every arm
  below mirrors `memory/concrete/impl_mem.ml` with a file:line cite; every upstream `TODO`-as-`failwith`, `failwith`,
  `assert false` or debug arm on the PNVI-ae-udi path stays a loud stop that mirrors upstream (§A.5). A `TODO`/`FIXME`
  *comment* attached to a *defined* arm is mirrored as the defined arm (making it a stop would be a divergence from
  upstream, which continues) and cited in-code (§A.5, §F.7).
- **[USER 2026-09-30], no magic modes:** "we should not fix deviations with special 'magic mode' paths that work
  exclusively in one situation". Applied: there is ONE switch-set parameter read by every site; no PNVI-only code path
  that bypasses the general one; the default is the general path instantiated at `[]`.
- **[USER 2026-10-04], the design target** (relayed by the coordinator; supersedes the consumer's Q2 answer):
  "speaking as the user for both cerberus-lean and cerberus-sl, we will probably eventually want to reason under
  PNVI_ae_udi but it will be a little bit of time before we get to it". Applied: §B rates each option on stating and
  proving facts under the switch (quantifying over the set, unfolding the ae-udi arms, stating facts about the
  iota/exposure state); §F.11 lists the reasoning needs this implementation would not provide.

### 1.2 Standing rules applied

Zero execution discrepancies against the oracle in matched mode, UB kind and location both count (CONTRACT §1);
fail-closed, fail-noisy; fuel, bounds and choices neither OCaml nor ISO forces are quantified parameters, never numerals
(the default `[]` IS forced: `ocaml_frontend/switches.ml:47-48` `internal_ref = ref []`); the semantics is a reasoning
artifact — prefer designs where a consumer quantifies over the switch choice, unfolds the definitions, and states
`has_switch … = false` by `rfl` in default mode; gratuitous Lean↔OCaml divergence in hand-written seams is a defect, a
deliberate divergence is documented in-code (the mechanism divergence "global on OCaml, parameter on Lean" is the
`tagDefs`/`enum_definitions` precedent, `docs/2026-09-18_program-data-parameters-design-note.md` §1).

### 1.3 Consumer statement (cerberus-sl dev #1, 2026-10-04, relayed by the coordinator; NOT a ruling)

Pinned at `2b51d2a57` (LemLib `38f87d5f`) with an ENFORCED freeze of about 1100 declarations touching cerberus-lean's
signatures (`cerberus-sl/docs/freeze/s7-rows.txt`, MEASURED 1100 lines); any signature change costs a re-pin decision
plus a freeze amendment, "so it should be done once, with an exact list". Threading preference: (a) PREFERRED — the
switch set as a FIELD of the state the memory functions already receive, set once by `initial_driver_state`, with a
named default constant, so `CerbMem.eqPtrval`, load/store/create/kill and the ND runner keep their signatures, and at the
concrete default state `has_switch … = false` closes by `rfl` or `simp [has_switch, defaultSwitches]`; (b) ACCEPTABLE —
one explicit parameter APPENDED to `initial_driver_state` (called positionally as
`initial_driver_state supply top digest file fs`; do not reorder or bundle); (c) COSTLY — a parameter threaded through
every memory-model function or through `runNDFuel` (~76 layer files + ~15 outcome-lemma files). In every option:
default mode bit-identical in the driver AND in the C→Core output (their corpus check recompares the `file` fields of
60+ programs); the `has_switch … = false` facts by `rfl` in the default. They want the exact signature list once the
record exists (§B.5).

## A. Inventory

Conventions: line numbers are THIS tree's (`ae48126e5`); `CerbMem.lean`'s in-code `:NNNN` comments cite older
numbering (the file says so at its load/store header) and are not repeated here. "Default" = the empty switch set;
"ae_udi" = `[SW_PNVI `AE_UDI]`. Lean status: **PRESENT** (default arm or data faithfully mirrored), **STOP** (present as a
loud kill in the H2 shape, must become the real arm), **MISSING** (no counterpart), **STAYS-STOP** (an upstream
`failwith`/`assert`, mirrored as a fail-stop, never resolved). MEASURED greps: §A.7.

### A.1 The switch readers and the provenance data that exists only under the switch

| # | OCaml site | Under default | Under ae_udi | Lean counterpart | Note |
|---|---|---|---|---|---|
| 1 | `switches.ml:20` `SW_PNVI of [`PLAIN|`AE|`AE_UDI]`; `:78-83` the three spellings; `:110-114` "would override" (one PNVI variant at a time); `:156-157` `is_PNVI` | absent from the list | present | `CerbGlobal.CerbSwitch` has NO `PNVI` constructor (lem's `global.lem:60-67` subset lacks it; `is_PNVI` is written as its value `false`, `CerbGlobal.lean:200-203`) | MISSING: a `PNVI (v : PNVIVariant)` constructor with `PNVIVariant := PLAIN | AE | AE_UDI` |
| 2 | `switches.ml:144-151` `set_iso_switches` (`--iso` = strict_pointer_arith, strict_reads, zap_dead_pointers, strict_pointer_equality, strict_pointer_relationals, **PNVI_ae_udi**) | — | — | `Main.refuseFlag` refuses `--iso` as an unknown flag | stays refused: it sets five refused switches |
| 3 | `switches.ml:133-142` `set`: unknown name → `prerr_endline "failed to parse switch '…' --> ignoring."`; a second PNVI variant → "would override a previous switch --> ignoring." — and the run proceeds | — | — | none | fail-OPEN on the oracle (MEASURED §C.5); Lean must refuse, not mirror (class (c)) — §F.4 |
| 4 | `impl_mem.ml:280-281` `symbolic_storage_instance_id`; `:290` `Prov_symbolic` | never minted | minted by `ptrfromint` on a two-allocation address | `CerbMem.lean:40-41, 50` | PRESENT |
| 5 | `:409` `allocation.taint : [`Unexposed|`Exposed]`; `:1346/:1373/:1469` every allocation born `Unexposed` | never read | read by `find_overlaping` (require_exposed) | `Allocation.taint : Taint := .Unexposed` (`:133-147`) | PRESENT, never written today |
| 6 | `:486` `next_iota`; `:511` `= 0` | unused | bumped by `add_iota` | `MemState.nextIota` (`:155`) | PRESENT, never written today |
| 7 | `:490` `iota_map : [`Single of id | `Double of id*id] IntMap.t`; `:513` empty | unused | written by `add_iota`, `resolve_iota`, `diff_ptrval`, `eff_array_shift_ptrval` | `MemState.iotaMap : List (Int × Int) := []` (`:166`, "simplified from OCaml's polymorphic variant") | PRESENT WITH THE WRONG TYPE: must become `Std.TreeMap Int IotaEntry`, `inductive IotaEntry | Single (id) | Double (id1 id2)` |
| 8 | `:432-453` `AbsByte.split_bytes` → `(prov, `ValidPtrProv|`NotValidPtrProv, values)` (`:443-447` consecutive `copy_offset`s from 0) | status unused | status selects `abst`'s pointer-arm policy (#20) | `splitBytesProv : List AbsByte → Provenance × Bool` (`:722-734`, doc `:716-721`); the `Bool` is computed and discarded (`_validPtrProv`, `:1116` and `:1288`) | PRESENT (data), consumer MISSING (#20) |
| 9 | `:455-460` `pvi_split_bytes` (fold `combine_prov` over the bytes) | integer-load provenance | same fold; a `Prov_symbolic` byte → `combine_prov` `failwith` (#35) | `provFromIntegerBytes` (`:708-709`) over `combineProv` (`:312`) | PRESENT; the crash path is the oracle's (§C.2) |
| 10 | `:462-479` `provs_of_bytes` → `` `NoTaint | `NewTaint ids ``; `:470-471` `Prov_symbolic iota -> acc (* TODO(iota) *)` | result discarded by `load` (#24 takes the default branch) | the `NewTaint` ids are EXPOSED by `load` (#24) | none | MISSING; the `TODO(iota)` is a comment on a *defined* arm (symbolic bytes contribute no taint) — mirror the arm, cite the TODO (§F.7) |
| 11 | `:543` `view_byte` `Prov_symbolic id -> Observed_symbolic_provenance id`; `:590-591` `string_of_provenance` `"@iota(n)"` | — | — | `viewByte` (`:198-204`); `:2036` | PRESENT |
| 12 | `:2978-2990` `serialise_prov` `"iota"` JSON with the map entry | UI only | UI only | none | OUT OF SCOPE (the UI dump; no batch-path reader) |
| 13 | `:662-668` `Concrete.is_PNVI ()` (own definition via `has_switch_pred`) | `false` | `true` | `CerbGlobal.is_PNVI () := false` with `is_PNVI_eq : … = false := rfl` | must become a function of the parameter (§B) |
| 14 | `:672-677` `mk_ival prov n`: under `is_PNVI` → `IV (Prov_none, n)` — **integers carry no provenance under any PNVI variant** | `IV (prov, n)` | `IV (Prov_none, n)` | no function; the non-PNVI branch is inlined at `reconstructValue` (`:1090` and the second occurrence `:1275`, `.IV (provFromIntegerBytes bytes) n`) and `intfromptr` (`:2894, :2899, :2918`) — callers in OCaml: `:992, :1005, :2486, :2488, :2505` (MEASURED) | MISSING branch; introduce `mkIval sws prov n` and use it at the mirror sites |

### A.2 `find_overlaping`, exposure, iota — the machinery (all MISSING)

| # | OCaml site | Under default | Under ae_udi | Lean | Note |
|---|---|---|---|---|---|
| 15 | `:796-842` `find_overlaping st addr`: `(require_exposed, allow_one_past)` = PLAIN `(false,false)`, AE `(true,false)`, **AE_UDI `(true,true)`**, no PNVI `(false,false)` (`:799-813`); fold over `allocations` in key order: a live allocation containing `addr` (exposed, if required) → candidate; else if `allow_one_past` and `addr = base+size` (exposed, if required) → candidate; `NoAlloc → SingleAlloc → DoubleAlloc (first, second)`; a third candidate is DROPPED (`:839-842` "TODO: I guess there is an invariant…") | callers only under `is_PNVI` (#20 is guarded; #26 is guarded) — never reached | the provenance oracle for `ptrfromint` and `abst` | none | MISSING. `Std.TreeMap.foldl` iterates in ascending key order = OCaml `Map.fold` (ascending) — the `(first, second)` ORDER matters (`resolve_iota` tries `first` first, #19). `:811 Some _ -> assert false` (a non-PNVI switch matched the PNVI predicate) is unreachable by construction; mirror as `failwithI`. The dropped-third-candidate TODO is a comment on a defined arm: mirror (§F.7) |
| 16 | `:877-886` `expose_allocation id` (taint := Exposed; absent id → no-op) | never called | `intfromptr` (#27) | none | MISSING |
| 17 | `:887-901` `expose_allocations taint` (`NoTaint` → nothing; `NewTaint ids` → each exposed) | never called | `load` (#24) | none | MISSING |
| 18 | `:903-909` `add_iota (id1,id2)` → fresh iota, `iota_map[iota] := Double` | never | `ptrfromint` (#26) | none | MISSING |
| 19 | `:911-914` `lookup_iota` (`IntMap.find`: `Not_found` on a missing iota — an uncaught exception); `:916-942` `resolve_iota precond iota`: `Single id` → precond or `fail`; `Double (a,b)` → precond a, else precond b, else the SECOND failure; then `iota_map[iota] := Single id` | never | load/store/kill (#22-24) | none | MISSING; a missing iota is `failwithI` (mirrors the exception); the "second failure" is the error the oracle reports — mirror exactly |

### A.3 The memory operations' PNVI arms

| # | OCaml site | Under default | Under ae_udi | Lean | Status |
|---|---|---|---|---|---|
| 20 | `:951-1128` `abst` (= `reconstructValue`): integer/byte arms return `provs_of_bytes` taint (`:988, :1001`) and `mk_ival` (#14); pointer arm `:1056-1088`: `if is_PNVI ()` then `NotValidPtrProv` → `find_overlaping n`: `NoAlloc → Prov_none`, `Single → Prov_some`, `Double (a,_) → Prov_some a` (`:1079-1082` "FIXME/HACK(VICTOR): This is wrong…"; the `failwith "TODO(iota): abst => make a iota?"` is commented OUT), `ValidPtrProv → prov`; else `prov` | the `else prov` branch; taint discarded | the PNVI branch | `reconstructValue_lemFuel` (`:1074-1130`; a second occurrence of the same arms at `:1275-1288`) uses `splitBytesProv …).1` unconditionally; returns no taint; has no `find_overlaping` | MISSING. Signature must gain the switch set, a `findOverlapping : Int → OverlapResult` closure (mirroring OCaml's closure argument exactly) and return the taint. The `Double → Prov_some a` arm is a *defined* arm with a FIXME: mirror it, cite it (§F.7). The measure proof in `CerbMem_lemMeasureProofs.lean` restates |
| 21 | `:1350` `allocate_object` `SW_zero_initialised` | repr of unspecified | same (not PNVI) | `:2301` | STOP, unchanged by this design (refused switch) |
| 22 | `:1504-1590` `kill`: `:1506` forbid_nullptr_free; **`:1519-1553` `Prov_symbolic` arm**: precondition = `is_dead z` → `Free_dead_allocation` (regardless of `is_dyn` — unlike the `Prov_some` arm's `:1572 failwith` for a static kill of a dead object), else `addr ≠ base` → `Free_out_of_bound`; `is_dyn` → `is_dynamic addr` else `Free_non_matching`; `resolve_iota`; retire the allocation; zap if switched | `Prov_symbolic` never minted | live | `:2361` forbid (STOP, unchanged); `:2369-2372` "killM: Prov_symbolic in concrete model" | MISSING (the arm); `:2406` zap stays STOP |
| 23 | `:1592-1706` `load` **`:1662-1684` `Prov_symbolic` arm**: precondition = dead → `DeadPtr`; `¬within_bound` → `OutOfBoundPtr`; atomic member → `AtomicMemberof`; `resolve_iota` → `do_load (Some id)` | never | live | `:2540-2542` "loadM: Prov_symbolic in concrete model" | MISSING |
| 24 | `:1602-1606` `load`/`do_load`: `if has_switch (PNVI AE) ∨ (PNVI AE_UDI) then expose_allocations taint` — BEFORE `record_access`/`last_used` (`:1607-1609`) | `return ()` | exposes every allocation whose id appears in the loaded bytes' provenances | NO guard at all (`:2502-2506` says "DECLARED (refused set, Z-24; not one of the eight explicit arms)") | MISSING; note the ORDER: expose, then the receipt/`last_used` update, then the trap check |
| 25 | `:1709-1833` `store` **`:1771-1804` `Prov_symbolic` arm**: precondition = `¬within_bound` → `OutOfBoundPtr`; readonly → `MerrWriteOnReadOnly kind`; atomic member → `MerrAccess (LoadAccess, AtomicMemberof)` (upstream's `LoadAccess` tag on a store — mirror verbatim; the `Prov_some` arm `:1818` has the same quirk, already mirrored); `resolve_iota`; `do_store`; locking | never | live | `:2614-2616` "storeM: Prov_symbolic in concrete model" | MISSING |
| 26 | `:2170-2217` `ptrfromint` **`:2190-2205` `is_PNVI` arm**: `(* TODO: device memory? *)`; `n = 0 → PVnull`; else `find_overlaping st n`: `NoAlloc → Prov_none`, `Single → Prov_some`, `Double → add_iota → Prov_symbolic`; `PV (prov, PVconcrete (None, n))`. NOTE: `device_ranges` are NOT consulted under PNVI, and the integer's own provenance is IGNORED | the PVI arm `:2207-2217` | the PNVI arm | `:2878-2879` loud kill "ptrfromint: the PNVI arm … is not ported" | STOP → real arm. The device TODO is a comment on a defined arm: mirror (no device check under PNVI) |
| 27 | `:2483-2505` `intfromptr`: `:2490-2498` `if has_switch (PNVI AE) ∨ (PNVI AE_UDI)` then `Prov_some id → expose_allocation id`; `:2486/:2488/:2505` `mk_ival` | no exposure; `IV (prov, …)` | exposure; `IV (Prov_none, …)` | `:2907-2908` loud kill (guarded by `is_PNVI`) | STOP → real arm; `mk_ival` (#14) |
| 28 | `:1874-1924` `eq_ptrval`: `:1896` strict_pointer_equality; **`:1905-1914` `(Prov_symbolic i1, Prov_symbolic i2)`**: `lookup_iota` both; `(Single a, Single b) → a = b`; else `false`; then `true → addr eq`, `false → msum "pointer equality" [provenance false; ignoring addr eq]` | never | live | `:2691` strict (STOP, unchanged); `sameProv`'s `_, _ => false` folds the symbolic pair into the mismatch arm (`:2683-2687`) — WRONG for `Single/Single` equal ids | MISSING arm (today's fold is unreachable, hence harmless) |
| 29 | `:1998-2107` `diff_ptrval`: `:2014` PERMISSIVE; **`:2032-2060` `(symbolic, some)` and `(some, symbolic)`**: `Single a → a = id' ∧ precond`; `Double (a,b) → id' ∈ {a,b} ∧ precond → collapse to `Single id'``; **`:2063-2105` `(symbolic, symbolic)`**: intersection `None → MerrPtrdiff`; `Single → collapse both, valid`; `Double → addr1 = addr2 → valid (zero) else fail (MerrOther "in `diff_ptrval` invariant of PNVI-ae-udi failed: ambiguous iotas with addr1 <> addr2")` (a `fail`, i.e. a kill with that text, not a `failwith`) | the `Prov_some/Prov_some` arm | live | `:2773` PERMISSIVE (STOP, unchanged); no symbolic arms (fall into `errorPostcond`) | MISSING arms |
| 30 | `:2130-2167` `validForDeref_ptrval` **`:2152-2163` `Prov_symbolic`**: `Single → do_test`; `Double → do_test a ∨ do_test b` | never | live | `:2850-2852` loud kill | MISSING arm |
| 31 | `:2288-2400` `eff_array_shift_ptrval` — reachable ONLY under strict/PNVI/CHERI (the elaborator emits `PtrArrayShift` there, `translation.lem:2112, 2249, 3178`; MEASURED §C.4): **`:2301-2376` `Prov_symbolic` arm** with `precond` = `STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE)` → `base ≤ shifted ∧ shifted + sizeof ≤ base + size + sizeof` (one-past allowed) else `true`; `Double`: `ival ≠ 0` → precond a: `true` → precond b: `true` → PERMISSIVE ? `NoCollapse` : **`Printf.printf "id1= %s, id2= %s ==> addr= %s\n"` to STDOUT then `fail (MerrOther "(PNVI-ae-uid) ambiguous non-zero array shift")`**; `false → Collapse a`; a `false` → precond b `true → Collapse b`, `false → MerrArrayShift`; `ival = 0` → precond a ∨ precond b else `MerrArrayShift`; `Single → precond ∨ MerrArrayShift`; **`:2381-2382` `Prov_some`** bounds arm → in-bounds-or-one-past else `MerrArrayShift` (UB046); **`:2393-2394` `Prov_none`** → `fail (MerrOther "out-of-bound pointer arithmetic (Prov_none)")`; `Prov_device` unguarded | unreachable (no `PtrArrayShift` emitted) | every pointer `+`/`-`/array decay | `:2949-2950` symbolic loud kill; `:2956-2960` ONE loud kill for the `STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE)` guard | STOP → real arms (MISSING symbolic arm). The debug `Printf.printf` is a "debug arm" on the oracle's PROCESS stdout — §F.5 |

### A.4 Sites with no switch read whose behaviour the switch exposes

| # | OCaml site | Lean | Status |
|---|---|---|---|
| 32 | `:2810-2814` `copy_alloc_id` = `intfromptr` (range check only) then `ptrfromint ival` | `copyAllocId` (`:3236-3237`) | PRESENT; correct once #26/#27 are |
| 33 | `:1930-1995` lt/gt/le/ge: provenance ignored off-strict | `:2718-2751` | PRESENT (STOP arms for strict stay) |
| 34 | `:2508-2555` `op_ival`/bitwise with `(* NOTE: for PNVI we assume prov = Prov_none *)` | `opIval` etc. | PRESENT; the assumption HOLDS because `mk_ival` (#14) strips provenance from every integer — except integers read from a symbolic pointer's BYTES (#9/#30) |

### A.5 Upstream `failwith`/`assert false`/debug arms on the path — STAY STOPS (mirror upstream, never resolve)

| # | OCaml site | Reached how under ae_udi | Lean today | Rule |
|---|---|---|---|---|
| 35 | `:390-394` `combine_prov` `(Prov_symbolic, _) | (_, Prov_symbolic) → failwith "Concrete.combine_prov: found a Prov_symbolic"` ("TODO: this is improvised, need to check with P") | reading the bytes of a stored `Prov_symbolic` pointer as an integer (`pvi_split_bytes`, #9): MEASURED on 4 of upstream's own litmus files (§C.2) | `combineProv` `:323-325` `failwithI` with the OCaml text | STAYS-STOP (both engines crash alike; class (a) text). Tray candidate (§F.6) |
| 36 | `:2247-2265` `array_shift_ptrval` (PURE) `Prov_symbolic → failwith "Concrete.array_shift_ptrval found a Prov_symbolic"` | the pure `array_shift` is still emitted in Core elaborated WITHOUT the switch — `runtime/libcore/std.core` (4 sites) and the libc dump `tests/libc/libc.core` (685 sites, MEASURED) — and the oracle's own `libc.co` is default-elaborated too (`pipeline.ml:34` switches only the `inner_arg_temps` variant); also `core_eval.lem:752`, `formatted.lem:391/:419` | `arrayShiftPtrval` `:1847` `failwithI` | STAYS-STOP |
| 37 | `:1852-1858` `case_ptrval` `| _ → failwith "case_ptrval"` (a `Prov_symbolic` or `Prov_device` concrete pointer) | `core_run.lem:1010`, `core_reduction.lem:1408`, `core_eval.lem:920` | `casePtrval` `:1480-1500` `failwithI` | STAYS-STOP |
| 38 | `:811` `find_overlaping` `Some _ → assert false` | unreachable by construction | — | mirror as `failwithI` |
| 39 | `:914` `lookup_iota` `IntMap.find` → `Not_found` | an iota absent from the map — unreachable while every `Prov_symbolic` is minted by `add_iota` | — | mirror as `failwithI` |
| 40 | `:2331-2334` the `Printf.printf "id1= …"` + `fail` arm (#31) | two live exposed allocations both admitting a non-zero shift | — | the kill is mirrored; the stdout print is the oracle's tool stream — §F.5 |
| 41 | `:1082` `(* failwith "TODO(iota): abst => make a iota?" *)` — COMMENTED OUT; the live arm is `Prov_some alloc_id1` | `abst` on a two-allocation address with non-pointer-shaped bytes | — | the DEFINED arm is mirrored (§F.7); this is NOT a stop in upstream |

### A.6 Switch-gated stops already in `CerbMem` (seam-hygiene H2) and the register

The eight H2 arms (`CerbMem.lean:2440-2462` header): `strict_pointer_equality` (`:2691`), `strict_pointer_relationals`
(`:2718/:2730/:2740/:2750`), `pointer_arith PERMISSIVE` (`:2773`), `pointer_arith STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE)`
(`:2956-2960`), `forbid_nullptr_free` (`:2361`), `zap_dead_pointers` (`:2406`), `zero_initialised` (`:2301`),
`strict_reads` (`:2529`); plus the two PNVI guards `ptrfromint` (`:2878`) and `intfromptr` (`:2907`). After this design:
the two PNVI guards and the `is_PNVI` disjunct of the array-shift guard become REAL arms; the other seven stay loud kills
for CLI-refused switches, now reading the parameter (so they remain honest, never a second notion of "the switch set").
The `Prov_symbolic` kills (`killM :2369`, `loadM :2540`, `storeM :2614`, `validForDerefPtrval :2850`,
`effArrayShiftPtrval :2949`) become real arms.

**The failure-reach register is wrong about why these are unreachable** (`scripts/failure_reach_register.txt` rows 64,
65, 103, MEASURED): `UNREACHABLE-BY-INVARIANT … config: Prov_symbolic arises only in the symbolic execution mode; the
default mode is none` — `Prov_symbolic` arises under `PNVI_ae_udi` in the CONCRETE model (`impl_mem.ml:290`), not in a
"symbolic execution mode". The reason text must be corrected in S1 regardless of the rest, and rows 64/65/103 become
REACHABLE-under-the-switch rows with the §C.2 crashes as witnesses in S4.

### A.7 The non-memory switch reads (shared lem model) — MEASURED (`grep` over `frontend/model/*.lem` and the census
tree's `lean_frontend/generated/*.lean`)

| Site | Switch | Lean generated | Changes under ae_udi? |
|---|---|---|---|
| `translation.lem:2112, 2249, 3178` `has_strict_pointer_arith () ∨ is_CHERI () ∨ is_PNVI ()` → emit `memop(PtrArrayShift, …)` instead of the pure `array_shift` (pointer `+`, `-`, array decay) | **PNVI** | `Translation.lean:3012-3015, 3219-3222, 4270-4271` read `CerbGlobal.is_PNVI ()` | **YES** (MEASURED §C.4) — the elaborator MUST see the parameter |
| `translation.lem:4333, 4369, 4384`; `core_run.lem:967, 977`; `mini_pipeline.lem:152` | `inner_arg_temps` | `Translation.lean` 3 sites, `Core_run.lean:1732, 1771`, `Mini_pipeline.lean:167` | no (refused switch) |
| `formatted.lem:718` | `permissive_printf` | `Formatted.lean:1181` | no (refused) |
| `ctype.lem`, `ailTypesAux.lem`, `translation.lem`, `formatted.lem` | `is_CHERI` ×32 (`Ctype.lean` 1, `AilTypesAux.lean` 2, `Formatted.lean` 4, `Translation.lean` 25) | — | no; §B.4 argues `is_CHERI` is a BUILD constant |
| `driver.lem:1791` | commented out | `Driver.lean:2700` comment | no |
| OCaml-only: `backend/common/pipeline.ml:34` (`std_inner_arg_temps.core`), `:271` (callconv), `:579` (`rm_unspecs = strict_reads ∧ ¬CHERI`, a Core rewrite pass with NO Lean counterpart), `backend/driver/main.ml:59-66` (lib names), `parsers/c/c_lexer.mll:700` (`at_magic_comments`) | not PNVI | — | no; `pipeline.ml:579` is one more reason `strict_reads`/`--iso` stay refused |

Hand-written Lean readers of `CerbGlobal.*` (MEASURED): `CerbMem.lean` only — `has_switch` 13, `is_PNVI` 3; `Main.lean`,
`CerbCall.lean` and every other seam: 0. Generated: `is_PNVI` 3, `has_strict_pointer_arith` 4, `has_switch` 7 (all
`inner_arg_temps`/`permissive_printf`), `is_CHERI` 32. Consumer (cerberus-sl, MEASURED): `CerbGlobal.has_switch` 6,
`CerbGlobal.switches` 5, `CerbGlobal.current_execution_mode` 1 (a probe), `CerbGlobal.CerbSwitch` 1.

**Total read sites that must become parametric: 30** (16 in `CerbMem`, 14 generated), excluding the 32 `is_CHERI` sites.

## B. Parameter threading

### B.0 Facts every option rests on

- **The elaborator reads the switch set.** `translation.lem:2112/2249/3178` emit `PtrArrayShift` memops under
  `is_PNVI ()` — MEASURED §C.4 (`--pp core` differs). So the parameter must reach `translate` (and, through the
  const-expression mini-run, `desugar`: `cabs_to_ail.lem:1136-1141` → `mini_pipeline.lem:152, 178` →
  `Driver.initial_driver_state_given` → the driver → memory ops). A carrier that exists only at run time (a memory-state
  field) cannot serve the frontend.
- **Upstream mixes elaboration sets within one run.** The oracle's `libc.co` and `std.core` are elaborated with the
  default set (`pipeline.ml:34` selects an alternative only for `inner_arg_temps`) and run under whatever `--switches`
  the user passes; Lean's `tests/libc/libc.core` dump is the same default-elaborated text. Therefore the run's switch set
  is a RUN parameter independent of how each TU was elaborated, and "store the set in the Core `file`" (the `enumDefs`
  carrier) is NOT a faithful carrier — rejected [AGENT].
- **The lem reader mechanism** (`lem-lean/doc/lean-backend/DESIGN.md`, "reader" paragraphs; the N-ary seed record
  `2026-09-19_nary-reader-seed-record.md`): `declare {lean} reader val r` for `r : unit -> T` lifts every def that
  transitively reads `r ()` by an explicit LEADING binder `_lemReader_r : T`, readers in GLOBAL SORTED NAME ORDER
  (today `enum_definitions`, `tagDefs`; a reader named `switches` sorts between them), binder order
  `[Inhabited]`, readers, supply, own args; `reader_consumer` target_rep'd vals receive ALL declared readers as extra
  leading arguments at every call site; `reader_seed` defs supply all N positionally. The fuel lifting is "the same
  fixpoint as the reader lifting, with an instance-implicit binder, so call sites are textually unchanged".
- **`reconstructValue` changes in every option.** OCaml's `abst` takes `find_overlaping st` as a closure argument
  (`:951, :1600`); the Lean twin must take the switch set and a `findOverlapping : Int → OverlapResult` closure (or the
  state), and return the taint. Consumer sites: `CerbMem.reconstructValue` 9 + `reconstructValue_lemFuel` 2 (MEASURED).

### B.1 Option 1 — the explicit reader (the plan recorded in `CerbGlobal.lean:46-54` as "STEP 2")

`global.lem`: `val switches: unit -> list cerb_switch`, `declare {lean} reader val switches`, OCaml target_rep
`Switches.get_switches`; `has_switch sw = List.elem sw (switches ())`, `is_PNVI`, `has_strict_pointer_arith` become
SHARED lem bodies (one body, both targets; `is_CHERI` stays a constant, §B.4); `cerb_switch` gains `SW_PNVI of
pnvi_variant`. `mem.lem`: every memory val that reads a switch is a `reader_consumer` (today's 20 consumers
`allocate_object … alignof_ival`, MEASURED list in `mem.lem:96-234`, plus the ones that read no global today:
`kill`, `eq_ptrval`, `ne_ptrval`, `lt/gt/le/ge_ptrval`, `ptrfromint`). The CLI passes the parsed list to every lifted
entry (`desugar`, `translate`, `drive`, `driver2`, …).

- Default by `rfl`: `has_switch [] sw = false := rfl`; consumer facts become `has_switch [] .strict_reads = false`.
- Reasoning: the best possible — a free variable `sws`; no state invariant; unfold the arms at `[.PNVI .AE_UDI]`.
- Performance: an extra leading argument through the lifted cone; the reader mechanism is in production (two readers).
- Backend work: none (the mechanism exists; the E-A arc exercised two readers + N-ary seeds).
- Consumer impact: (c)-class. Exact list §B.5 column 1. The insertion is in the MIDDLE of the reader block (sorted
  name), so every positional call fails to typecheck — loud, mechanical, ~900 textual sites (MEASURED counts) in ~90
  files; the freeze amendment lists every changed signature.
- Mirror doctrine: the OCaml is untouched (target_reps stay the global reads); generated OCaml byte-identical → the
  fork-drift gate's pinned hashes do not move.

### B.2 Option 2 — the consumer's (a): a field of the memory state (+ carriers for the frontend and the core run)

`MemState.switches : List CerbSwitch := defaultSwitches`; `initialMemState top` unchanged; lem
`Driver.initial_driver_state address_space_top digest file fs_state switches` (APPENDED, their (b)) sets
`layout_state := Mem.initial_mem_state top switches` (the OCaml rep `Impl_mem.initial_mem_state top sws` keeps reading
the global and ASSERTS `sws = Switches.get_switches ()` — fail-noisy, the address-space-top precedent of a fork-only
parameter) and `core_run_state.switches` (for `core_run.lem:967/977`); `CerbMem` arms read `st.switches`. The
frontend still needs the set: either the reader (then `translate`/`desugar` lift and their signatures change anyway)
or a hand-threaded field of the translation effect state with monadic reads at the 7 `translation.lem` sites and an
explicit parameter on `translate`/`Formatted.printf` — a lem STRUCTURE change for OCaml's benefit of nothing (dead
parameters, permitted by the E-A precedent, but a larger edit).

- Default: `(initialMemState top).switches = [] := rfl`; but a fact about `eqPtrval` on a state `σ` needs
  `σ.switches = []` — a new clause of the consumer's `MemWF`-style invariants, plus a PRESERVATION lemma
  `((op …) σ).2.switches = σ.switches` for every memory op (new proof work on their side; they accepted that in (a)).
- Reasoning under the switch (the [USER 2026-10-04] target): three carriers of one datum (memory state, core-run state,
  the frontend's reader/translation state) → a "copies agree" invariant must be stated and carried; the switch set is
  mutable state in principle (nothing prevents a future op from writing it) — a weaker artifact than a parameter.
- Consumer impact: `initial_driver_state` +1 appended (307 sites, mechanical) or a 5-arg default shim (zero edits, one
  more name — §F.2); `translate`/`desugar` (8 sites); `reconstructValue` (11); MemState literals (0 with the default;
  12 `{ lastAddress := … }` literals compile); the four switch-fact files (`HeapModel.lean:381`,
  `HeapModelKill.lean:31`, `Memory/Transitions.lean:62`, `PtrEqModel.lean:34`) rewritten to the state form; preservation
  lemmas (new).
- Mirror doctrine: a fork-oracle code change (the assert) or an ignored parameter; generated OCaml changes
  (`initial_driver_state`'s arity) → fork-drift re-pin.
- Verdict [AGENT]: NOT recommended — it does not avoid the consumer's re-pin, it multiplies carriers, and it makes the
  future reasoning target harder.

### B.3 Option 3 — the instance-implicit ambient parameter (the fuel-arc shape) — RECOMMENDED

`class CerbGlobal.Switches where switches : List CerbSwitch` (name to be chosen; `[LemFuel]` is the model). The
backend lifts exactly the set option 1 lifts, but emits `[CerbGlobal.Switches]` instead of `(_lemReader_switches : …)`
and `Switches.switches` at the read sites; hand-written reps (`CerbMem.loadM [LemFuel] [Switches] …`) declare the binder
themselves and mark their callers (`declare {lean} switches_consumer val load`, the `fuel_consumer` role — no call-site
argument, the instance is passed implicitly). No instance exists in the library or the generated tree, by design (the
fuel rule: "the entry point supplies it once"); `Main.lean` does `letI : Switches := ⟨parsed⟩` beside its `LemFuel`
instance; a gate bans any other `instance : Switches` (plant-tested).

- Default by `rfl`: `@has_switch ⟨[]⟩ sw = false := rfl` (`List.any [] p = false` is definitional). The consumer
  declares ONE local `instance : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩` and every statement elaborates
  as today; `@drive ⟨[]⟩ …` IS the pre-change `drive` definitionally once the default arms reduce; their
  `simp [CerbGlobal.has_switch, CerbGlobal.switches, List.any_nil]` becomes `simp [CerbGlobal.has_switch,
  CerbGlobal.Switches.switches]` or `rfl`. Their C→Core corpus check: `translate` at `⟨[]⟩` takes the `else` branch at
  every `is_PNVI` site — bit-identical output.
- Reasoning: quantify by binding `[Switches]` in a theorem (as `[LemFuel]` is bound today) or instantiate
  `@f ⟨[.PNVI .AE_UDI]⟩`; one parameter, one notion, for the frontend AND the run AND the memory model; the iota map and
  the exposure flags stay honest STATE (they are state in OCaml). A future reasoning effort binds the instance and
  unfolds — no signature change (the [USER 2026-10-04] preference).
- Performance: instance-implicit arguments are ordinary arguments after elaboration; the fuel binder has the same cost
  and is already everywhere.
- Backend work: ONE lem-lean slice — the reader fixpoint with an instance binder kind (a flag on `reader val`, e.g.
  `declare {lean} reader_binder switches = instance `CerbGlobal.Switches``), the `*_consumer` role, and the interaction
  with `reader_seed` (the D3 seeds cut EXPLICIT readers; an instance reader must propagate through a seed def — the
  seed def itself binds `[Switches]`), mutual blocks (the fuel/reader composition exists:
  `2026-09-20_fuel-mutual-reader-record.md`), tests/comprehensive + a kernel pin + the invariance witness (no `.lem`
  change for OCaml). Risk: a NEW mechanism; mitigated by being the fuel lifting's twin.
- Consumer impact: NO positional signature changes to `initial_driver_state`, `drive`, `driver_globals`, `driver2`,
  `drive_nonmemory_steps_aux2_lemFuel`, `desugar`, `translate`, `runNDFuel`, `eqPtrval`, `loadM`, `storeM`,
  `allocateObject`, `killM`, …; changes: `reconstructValue`(+_lemFuel) 11 sites (B.0); `CerbGlobal.switches` renamed
  `defaultSwitches` 5 sites; the four switch-fact files; one local instance declaration. Freeze fingerprints of frozen
  declarations whose TERMS now contain the instance change (a re-pin + amendment is unavoidable in every option; this
  one has the shortest list).
- Mirror doctrine: OCaml untouched; generated OCaml byte-identical.
- "Canon-first" check: this is a classic ambient/implicit parameter (a reader monad in the type class), the project's
  own precedent for ambient configuration ([USER 2026-09-04] on the fuel measure: "we maintain the lem structure, and
  we get additional properties we want without any trust decrease"); not a house trick.

### B.4 Two scoping decisions common to all options [AGENT]

1. **`is_CHERI` stays a build constant** (`def is_CHERI (_ : Unit) : Bool := false`), not a function of the parameter:
   CHERI is a memory-MODEL selection upstream (a separate executable, `cerberus-cheri`; `main.ml:133-140` injects
   "CHERI" only in the CHERI build; `is_cheri_memory ()`), cerberus-lean has the concrete model alone and one ABI
   (CONTRACT D6), and its 32 sites sit in `Ctype`/`AilTypesAux` — lifting them would put the binder on `sizeofCtype`
   (314 consumer sites) for a constant. The `.cheri` constructor stays (refused at the CLI); an invariant lemma
   `AcceptedSwitches sws → .cheri ∉ sws` documents the gap. The `translation.lem` disjunction then reads
   `parameter ∨ constant ∨ parameter`. Documented in-code as a deliberate divergence of MECHANISM, results identical.
2. **The whole `List CerbSwitch` domain is implemented where impl_mem shares the code** (the `(require_exposed,
   allow_one_past)` table for PLAIN/AE/AE_UDI is six lines, `:800-813`; the `AE ∨ AE_UDI` exposure guards are shared),
   but the CLI accepts exactly `[]` and `[.PNVI .AE_UDI]` until a lane validates another set (§F.3). The seven refused
   switches' arms stay the H2 loud kills, reading the parameter.

### B.5 The exact signature list (what cerberus-sl uses, MEASURED by grep over its tree, `.lake/` excluded)

| cerberus-lean name | cerberus-sl uses (textual) | Option 1 (explicit reader) | Option 2 (state field) | Option 3 (instance) |
|---|---|---|---|---|
| `initial_driver_state supply top digest file fs` | 307 | unchanged (reads no switch) | **+1 appended** `switches` (or a 5-arg default shim) | unchanged |
| `initial_driver_state_with`, `initial_core_run_state_given` | 1, 1 | unchanged | +1 each | unchanged |
| `drive enumDefs tagDefs false file args` | 329 | **reader inserted** → `drive enumDefs switches tagDefs …` | unchanged (reads run state) only if `core_run.lem:967/977` are restructured to read `core_run_state`; else as option 1 | `[Switches]` binder, textually unchanged |
| `driver_globals`, `driver2`, `drive_nonmemory_steps_aux2_lemFuel` | 48, 142, 24 | reader inserted | as `drive` | binder, unchanged |
| `desugar fmapEmpty fmapEmpty supply top …` (Corpus/Capture) | 5 | reader inserted | reader inserted (or +1 explicit) | binder, unchanged |
| `translate enumDefs fmapEmpty supply …` | 3 | reader inserted | reader inserted (or +1 explicit) | binder, unchanged |
| `annotate_program`, `link`, `convert_file` | 2, 1, 996 | unchanged | unchanged | unchanged |
| `CerbND.runNDFuel`, `CerbND.fuelExhaustedKill` | 308, 325 | unchanged | unchanged | unchanged |
| `CerbMem.eqPtrval loc p q` / `nePtrval` | 71 / 35 | **+3 leading** (all readers) | unchanged | binder, unchanged |
| `CerbMem.loadM eds tds loc τ pv` / `storeM` / `allocateObject` | 42 / 44 / 53 | **+1 leading** (`switches` between the two readers) | unchanged | binder, unchanged |
| `CerbMem.killM loc dyn pv` / `validForDerefPtrval` | 19 / 19 | +3 / +1 | unchanged | binder, unchanged |
| `CerbMem.ptrfromint`, `intfromptr`, `diffPtrval`, `effArrayShiftPtrval`, `copyAllocId`, `lt/gt/le/gePtrval` | <5 each | +3 / +1 | unchanged | binder, unchanged |
| `CerbMem.reconstructValue eds tds unionmap funptrmap addr τ bytes` (+`_lemFuel`) | 9 (+2) | **+switches, +`findOverlapping` closure, returns taint** | same | same (binder + closure + taint) |
| `CerbMem.initialMemState top` | 94 | unchanged | unchanged (default field) | unchanged |
| `CerbMem.MemState` literals `{ lastAddress := … }` / `with` updates | 12 / 16 | unchanged | unchanged if `switches` has the default | unchanged |
| `MemState.iotaMap` (type changes to `TreeMap Int IotaEntry`) | 0 | — | — | — |
| `CerbGlobal.switches` | 5 | renamed `defaultSwitches` | kept as the default constant | renamed `defaultSwitches` |
| `CerbGlobal.has_switch sw` (6) and the facts at `HeapModel.lean:381`, `HeapModelKill.lean:31`, `Memory/Transitions.lean:62`, `PtrEqModel.lean:34` | 6 | `has_switch sws sw`; facts at `[]` by `rfl` | `has_switch σ.switches sw`; facts need `σ.switches = []` | `@has_switch ⟨[]⟩ sw`; facts by `rfl` under their local instance |
| `CerbGlobal.current_execution_mode`, `CerbConf` | 1 | unchanged (out of scope) | unchanged | unchanged |
| `Interface.AdmittedTop`, `oomOutcome`, `mkGS`, the run digest (`rs.sym_digest`), the enum reader (`P.enumDefs`), the fail-closed matcher (`match_pattern`/`typecheck_pattern`) | many | unchanged | unchanged | unchanged |

Derived totals (textual sites): option 1 ≈ 900 in ~90 files; option 2 ≈ 330 (307 of them the appended argument) +
new preservation lemmas; option 3 ≈ 27 + one instance declaration + freeze-fingerprint drift of the frozen terms.

### B.6 Recommendation [AGENT]

**Option 3**, with **option 1 as the fallback** if the operator declines the lem-lean mechanism slice. Reasons, in the
project's order of tie-breakers: (i) mirror — one honest parameter at every site, OCaml untouched; (ii) the reasoning
target — quantification by a binder, default facts by `rfl`, the ae-udi arms unfoldable at `⟨[.PNVI .AE_UDI]⟩`, and no
second signature change when reasoning under the switch begins; (iii) consumer — the shortest exact list, and the
mechanism they already live with for fuel; (iv) fail-closed — no default instance anywhere (gate-enforced). Option 2 is
declined for the three-carrier problem (§B.2). If option 1 is chosen, name the reader so that its sorted position is
documented in the consumer note (a name sorting after `tagDefs` would APPEND rather than insert — but choosing a name
for its sort order is a house trick; prefer the honest `switches` and the loud middle insertion).

## C. Measured oracle behaviour

### C.0 Instrument

The census worktree's fresh oracle at `ae48126e5` (`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-census/real-c-20261004`,
`_build/default/backend/driver/main.exe`, `--runtime=_build/install/default`), invoked under
`CERB_MEM_MAX=4G scripts/capped timeout 60` (120 for pKVM), via `scripts/ce opam exec --switch=. --`, by a 60-line
probe script (deleted with `.tmp/`). Litmus: `--exec --batch --mode=exhaustive FILE` (libc mode, as `test_ci_sweep.sh`
registers the suite) with and without `--switches=PNVI_ae_udi`. pKVM: the census flags verbatim
(`--nolibc --nostdinc -I <case-study> -I tests/census/pkvm`, driver TU then `page_alloc.c`), `--exec --batch`
(default `--mode=random`, one trace) with and without the switch; exhaustive under the switch was NOT re-run (the census
measured it breaching the 4G cap, §4.1 there). Every quote below is verbatim from the captures; tallies are derived.

### C.1 The litmus suite: 44 `.c` files (plus `refinedc.h`, `charon_address_guesses.h`), exhaustive

Derived tally (stdout+rc identical?): **27 unchanged, 17 changed.** The 17, verbatim first lines (`default | ae_udi`):

```
cheri_03_ii                                   Defined {value: "Specified(0)", stdout: "x[1]=1  *q=1\n", stderr: "", blocked: "false"} | Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<6:12--6:18>"}
pointer_arith_algebraic_properties_2_global   Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<17:3--17:5>"} | Defined {value: "Specified(0)", stdout: "x[1]=11 *p=11\n", stderr: "", blocked: "false"}
pointer_arith_algebraic_properties_3_global   Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<18:3--18:5>"} | Defined {value: "Specified(0)", stdout: "x[1]=11 *p=11\n", stderr: "", blocked: "false"}
pointer_copy_user_ctrlflow_bitwise            Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<26:3--26:5>"} | Defined {value: "Specified(0)", stdout: "*p=11  *q=11\n", stderr: "", blocked: "false"}
pointer_copy_user_ctrlflow_bytewise           6561 executions, all Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<282:3--282:5>"} | 6561 executions, all Defined {value: "Specified(0)", stdout: "*p=11  *q=11\n", stderr: "", blocked: "false"}
pointer_from_int_disambiguation_1             Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<19:5--19:10>"} | Defined {value: "Specified(0)", stdout: "x=1 y=11 *q=11 *r=11\n", stderr: "", blocked: "false"}
pointer_from_int_disambiguation_3             Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<19:5--19:10>"} | Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<20:7--20:10>"}
pointer_offset_from_int_subtraction_auto_xy   Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<21:5--21:7>"} | Defined {value: "Specified(0)", stdout: "Addresses: &x=281474976705976 &y=281474976705972 offset=18446744073709551612 \nx=1 y=11 *p=11 *q=11\n", stderr: "", blocked: "false"}
pointer_offset_from_int_subtraction_auto_yx   Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<21:5--21:7>"} | rc=125 (crash, §C.2)
pointer_offset_from_int_subtraction_global_xy Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<21:5--21:7>"} | Defined {value: "Specified(0)", stdout: "Addresses: &x=281474976707772 &y=281474976707768 offset=18446744073709551612 \nx=1 y=11 *p=11 *q=11\n", stderr: "", blocked: "false"}
pointer_offset_from_int_subtraction_global_yx Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<21:5--21:7>"} | rc=125 (crash)
pointer_offset_xor_auto                       Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<19:3--19:10>"} | Defined {value: "Specified(0)", stdout: "x=1 y=11 *r=11 (r==p)=true\n", stderr: "", blocked: "false"}
pointer_offset_xor_global                     Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<20:3--20:10>"} | Defined {value: "Specified(0)", stdout: "x=1 y=11 *r=11 (r==p)=true\n", stderr: "", blocked: "false"}
provenance_basic_using_uintptr_t_auto_yx      Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<22:5--22:7>"} | rc=125 (crash)
provenance_basic_using_uintptr_t_global_yx    Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<22:5--22:7>"} | rc=125 (crash)
provenance_union_punning_2_auto_yx            Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<16:5--16:7>"} | Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<16:5--16:12>"}
provenance_union_punning_2_global_yx          Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<16:5--16:7>"} | Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<16:5--16:12>"}
```

Derived classes: 9 UB→Defined; 2 UB→a different UB kind AND location (`provenance_union_punning_2_*`: UB043 at
`<16:5--16:7>` → UB_CERB002b at `<16:5--16:12>`); 1 UB_CERB002b→UB046 at a different location
(`pointer_from_int_disambiguation_3`); 1 Defined→UB046 (`cheri_03_ii`: the PNVI bounds check on `PtrArrayShift`, #31);
4 crashes (§C.2). 9 + 2 + 1 + 1 + 4 = 17. Reading [AGENT]: the UB043→Defined rows are exactly `ptrfromint`'s PNVI arm (#26) giving an
integer-derived pointer a provenance; the UB046 rows are `eff_array_shift_ptrval`'s now-live bounds arms (#31); the
two `union_punning_2` rows show that under PNVI the store fails LATER (out-of-bound store on a `Prov_some`/symbolic
pointer) rather than at the indirection — kind and location both move, both are behaviour.

The 27 unchanged include four multi-execution rows that agree in count AND content (`pointer_from_integer_1ig`/`1pg`: 2
executions; `provenance_equality_auto_yx`/`global_yx`/`global_fn_yx`: 2 executions each, the `(p==q) = true/false`
pair — the `msum "pointer equality"` fork is present in BOTH modes, i.e. provenance-mismatched equality forks are not a
PNVI artefact). `pointer_copy_user_ctrlflow_bytewise` has 6561 (= 3^8) executions in both modes — a cost note for the
lane (0.66 MB of batch output per engine).

### C.2 Oracle crashes under the switch (4 of 44) — the `combine_prov` TODO

Verbatim stderr head (`pointer_offset_from_int_subtraction_auto_yx`; the other three are identical except the file):

```
cerberus: internal error, uncaught exception:
          Failure("Concrete.combine_prov: found a Prov_symbolic")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Impl_mem.Concrete.AbsByte.pvi_split_bytes.(fun) in file "memory/concrete/impl_mem.ml", line 458, characters 11-39
          Called from Stdlib__List.fold_left in file "list.ml", line 125, characters 24-34
```

(rc 125; the escape sequences around "uncaught exception" are the oracle's colouring.) Reading [AGENT]: the program
stores a `Prov_symbolic` pointer and then reads its bytes back as `uintptr_t` (`provenance_basic_using_uintptr_t_global_yx`
lines 9-12: `ux = (uintptr_t)&x; … ux = ux + offset; p = (int*)ux; … memcmp(&p, &q, …)` — the `memcmp` in libc loads
the pointer's bytes as integers), so `abst`'s integer arm folds `combine_prov` over symbolic bytes (#9, #35). This is
upstream's own `TODO: this is improvised, need to check with P` (`:391`). Design: Lean's `combineProv` already carries
the `failwithI` with the same text; both engines crash alike (contract outcome 2/class (a) text). Tray candidate (§F.6).

### C.3 pKVM drivers, one trace (`--mode` default), MEASURED

```
pkvm_alloc         default Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<27:2--27:21>"} | ae_udi Defined {value: "Specified(61728)", stdout: "", stderr: "", blocked: "false"}
pkvm_free          default Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<27:2--27:21>"} | ae_udi Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
pkvm_split_merge   default Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<27:2--27:21>"} | ae_udi Defined {value: "Specified(4508)", stdout: "", stderr: "", blocked: "false"}
pkvm_init          default Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<715:2--715:17>"} | ae_udi Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<715:2--715:6>"}
```

The three values equal the census's (§4.1 there, and native gcc's). **`pkvm_init`'s UB location differs under the
switch** although the UB kind is the same: the elaboration of `page_alloc.c:715` differs (`PtrArrayShift` memops
change the expression's Core shape and the location the UB is attributed to). UB location is behaviour; the Lean side
reproduces it only if its ELABORATOR sees the switch — the frontend requirement of §B.0 measured on the target program.
Exhaustive mode under the switch: not re-run; the census's verbatim finding stands (`capped: OOM-KILLED (exit 137 —
cgroup memory cap CERB_MEM_MAX=4G breached; memory.events oom_kill=1; NOT a pass)`, `wall=139.79 maxrss=4203580kB`).
Reading [AGENT]: with page pointers carrying `Prov_some` or `Prov_symbolic` provenances, every list-pointer comparison
between different objects takes the `msum "pointer equality"` fork (#28), doubling the trace set per comparison; the
Lean exhaustive runner would blow up identically (§D.1 uses `--first` for pKVM, labelled outside §1).

### C.4 The elaborated Core depends on the switch, MEASURED (`--nolibc --pp core`, `int main(void) { int a[2] = {1, 2}; int *p = a; p = p + 1; return *p; }`)

```
17c17,18
<       pure(Specified(array_shift(a_514, 'signed int', 0)))
---
>       let weak a_515: pointer = memop(PtrArrayShift, a_514, 'signed int', 0) in
>       pure(Specified(a_515))
35c36,38
<                 pure(Specified(array_shift(a_518, 'signed int', a_520)))
---
>                 let weak a_521: pointer =
>                   memop(PtrArrayShift, a_518, 'signed int', a_520) in
>                 pure(Specified(a_521))
```

Both runs `Defined {value: "Specified(2)", …}`. This is `translation.lem:2112/3178` (#A.7 row 1).

### C.5 The oracle's switch parsing is fail-open, MEASURED (same program, `--exec --batch --mode=exhaustive`)

```
--switches=bogus            stderr: failed to parse switch 'bogus' --> ignoring.            stdout: Defined {value: "Specified(2)", …}  rc=0
--switches=PNVI_ae_udi,PNVI stderr: switch 'PNVI' would override a previous switch --> ignoring.  stdout: Defined {value: "Specified(2)", …}  rc=0
--iso                       stderr: (only "Time spent: …")                                stdout: Defined {value: "Specified(2)", …}  rc=0
```

(`Time spent:` is the oracle's tool-stream line on every run.) An unknown or overriding switch name is IGNORED and the
run proceeds in the mode the remaining list selects — a silent absorption the contract forbids on our side. Lean must
refuse these (class (c)); §F.4.

## D. Validation plan

### D.1 A differential lane under the switch — `scripts/test_pnvi.sh` (new; Tier A if it stays under ~2 min, else B)

Both engines receive `--switches=PNVI_ae_udi`; the oracle's cabs-json export needs no switch (no PNVI site in the
lexer/parser, §A.7). Rows and comparison (the lanes' codec, `scripts/observations.py`, `full` projection; UB loc and
stderr are part of the token):

1. **Litmus:** the 44 `tests/pnvi_testsuite/*.c`, libc mode (they include `<stdio.h>`/`<string.h>`), oracle
   `--exec --batch --mode=exhaustive` vs Lean `--batch --libc … --libc-tu …`, pinned baseline
   `tests/pnvi_testsuite/baseline.txt` fail-closed both directions (the `test_immaculate.sh` discipline). Expected
   classes: MATCH on 40; `BOTH_CRASH` on the 4 `combine_prov` rows (the oracle's rc 125 `Failure(…)` vs Lean's
   `failwithI` panic — class (a) text, pinned as a crash CLASS per CONTRACT §4.1's limit); the 6561-execution row is
   MATCH on the full sequence (cost noted). The default-elaborated libc is the same on both sides (the oracle's
   `libc.co`, Lean's `tests/libc/libc.core` dump) — the mixing of §B.0 is reproduced, not worked around.
2. **pKVM:** the four census drivers (`tests/census/pkvm/*.c` + `page_alloc.c`, the census flags), `--first` vs the
   oracle's one trace, pinned on the three values and the `pkvm_init` UB088 token WITH its ae-udi location
   `<715:2--715:6>`. Labelled OUTSIDE the §1 promise (`--first`, CONTRACT §2) with the exhaustive resource-limit
   recorded; if the oracle's one trace is non-deterministic on a row (the census saw `pkvm_init`'s differ), that row is
   compared on the exhaustive set or dropped — never loosened.
3. **Undisturbed ordinary programs:** `tests/minimal` (106) under the switch on both engines, pinned baseline
   `scripts/exec_pnvi_minimal_baseline.txt`; Tier B adds `tests/ci` (128) and `tests/libc_exec`. Expectation: identical
   to the default baselines on most rows; every DIFF against the default baseline is a reviewed row (the switch changes
   semantics on purpose), every DIFF between engines is a bug.
4. **Default-mode ladder, unchanged:** every Tier A row and Tier B row must show ZERO movement at every slice
   boundary (§E); the exec baselines, the gcc second-oracle ledger, the immaculate baseline, the libxml2 gates, the
   address-space lane, the memory-access lane. This is the bit-identity evidence the consumer asks for; the frontend's
   bit-identity is additionally pinned by `test_elab.sh` (row 9) and by the consumer's own corpus check at re-pin.

### D.2 Plants (vacuity must be loud)

- **P1 — the flag is ignored at the CLI.** A wrapper stub that strips `--switches=…` and execs the real Lean driver
  (the HANG/KILL plant pattern, `test_hang_plant.sh`): the lane must go RED on the 17 changed litmus rows and the
  three pKVM values.
- **P2 — the elaborator ignores the switch.** A build with the `is_PNVI` reads in `Translation` forced to `false`
  (one-line scratch plant, one Lean rebuild at landing time — recorded in the slice record, not run per gate): RED on
  `cheri_03_ii`, `pointer_from_int_disambiguation_3` (UB046 rows) and the `pkvm_init` location row.
- **P3 — the memory model treats ae_udi as default.** A build with `find_overlaping`'s table forced to
  `(false, false)`: RED on the 11 UB→Defined rows.
- **P4 — the inverse.** A build whose default instance is `⟨[.PNVI .AE_UDI]⟩` (or Main passing it unconditionally):
  the DEFAULT exec baseline (Tier A row 2) must go RED — proves the default lanes see the parameter.
- **P5 — no hidden default instance.** The gate that bans `instance : CerbGlobal.Switches` outside Main's `letI`
  (option 3) is plant-tested with a scratch instance in a seam file (the `check_no_fuel_numerals.sh` F-plant shape).
- **P6 — the refusal control.** `check_cli_refusals.sh` keeps its control (an accepted argv must NOT be refused).

### D.3 `scripts/check_cli_refusals.sh`

- `expect_refused "--switches=PNVI_ae_udi" …` becomes an ACCEPTANCE control: with `--runtime` given and the probe
  input path, the driver must NOT print `cerberus-lean: refused` and must fail at the input read (as the existing
  control does).
- Stay/added refusals, each naming the switch and its boundary: `--switches=PNVI`, `--switches=PNVI_ae` (unvalidated
  PNVI variants), `--switches=strict_pointer_arith` (kept), `--switches=permissive_pointer_arith`,
  `--switches=strict_reads`, `--switches=zero_initialised`, `--switches=inner_arg_temps`, `--switches=CHERI`,
  `--switches=PNVI_ae_udi,strict_reads` (a mixed set), `--switches=bogus` (unknown name — where the oracle ignores),
  `--switches=PNVI_ae_udi,PNVI` (an override — where the oracle ignores), `--iso`, and a repeated `--switches`
  (cmdliner's "cannot be repeated"). The exit code stays 2; the message names the feature and VALIDATION's row.
- The OK line's count moves from "3 refused flags pinned" to the new tally.

### D.4 Other gates and documents

- **Unit pins** (`test/Unit/OpaqueFailureTest.lean:85-97`): the eight `has_switch … = false := rfl` examples at the
  default instance; ADD `@is_PNVI ⟨[.PNVI .AE_UDI]⟩ () = true := rfl`, the `find_overlaping` table at AE_UDI `=
  (true, true)` by `rfl`, and one arm-reduction example under the switch (e.g. `ptrfromint` at `n = 0` reduces to
  `PVnull`).
- **Failure-reach register:** rows 64/65/103 re-classified (reason text fixed in S1; reachability + §C.2 witness in
  S4); new rows for `findOverlapping`'s `assert false` mirror, `lookupIota`'s `Not_found` mirror; `--selftest` plants.
- **Fuel-forms gate:** `reconstructValue_lemFuel`'s sufficiency theorem restated in `CerbMem_lemMeasureProofs.lean`
  (new arguments; the measure is unchanged); `findOverlapping` is a `Std.TreeMap.foldl` — structural, no fuel.
- **Fork-drift gate:** options 1/3 change no generated OCaml (declares only) — pins unmoved; option 2 re-pins.
- **CONTRACT.md:** §2 "Every non-default semantics switch is refused at the CLI today" → "every switch but
  `PNVI_ae_udi`, which is SUPPORTED under its own lane"; §3 the switches row splits: `PNVI_ae_udi` SUPPORTED (witness:
  `test_pnvi.sh`; open: the 4 shared crashes, the pKVM exhaustive cost); every other switch and `--iso` REFUSED
  (`check_cli_refusals.sh`). **VALIDATION.md** §3(c) "Semantics switches" rewritten (the "permanently empty" sentence
  goes); a new gate row for the lane; the Z-24 citations in `CerbMem.lean` (15 sites) and `Main.refuseFlag`'s message
  rewritten. **SUPPORTED.md** gains the row with its date. **LADDER.md** gains the row. **The upstream tray** gains the
  §C.2 crash and the §C.5 fail-open as report drafts (operator network window).
- **Consumer note:** `docs/<date>_consumer-note-cerberus-sl-pnvi-ae-udi.md` with §B.5's column for the chosen option,
  verbatim signatures, and the default-instance recipe.

## E. Slicing and size

Each slice is exactly one of: forced semantics change / spec addition / internals refactor. Every slice ends on the
full Tier A ladder at zero movement (Tier B at S3/S4 and before merge); FULL gate only at claim points. Sizes are
[AGENT] estimates in person-days of a chartered worker, excluding audits.

| # | Slice | Kind | Content | Size | Risks |
|---|---|---|---|---|---|
| S0 | lem-lean: instance-binder readers (option 3 only) | internals refactor (backend) | `reader_binder … = instance` on `reader val`; `*_consumer` role; seed/mutual interaction; `tests/comprehensive` + kernel pin + invariance witness; record; the two-repo pin dance (opam pin, Lake rev, manifests, `fork_drift_manifest.txt` `lem-pin`) | M (3–5 d) | seeds through an instance reader; a NEW mechanism needs its own adversarial review; if refused, fall back to option 1 and skip S0 |
| S1 | the switch set becomes the parameter | internals refactor (zero behaviour change) | `CerbSwitch.PNVI (v)`, `PNVIVariant`; `global.lem` shared bodies for `has_switch`/`is_PNVI`/`has_strict_pointer_arith`; the reader (option 1) or the instance (option 3) threaded; every one of the 30 read sites reads it; `Main` parses `--switches` (comma list, `=`/space forms as cmdliner) but REFUSES every value, passing `[]`; `defaultSwitches`; the `has_switch_*_eq` lemmas at the default; register reason text fixed (§A.6); consumer note draft | M (2–4 d) | the lifted cone's exact extent (measure it as E-A1(a) did, by token closure over the generated tree); `CerbMem_lemMeasureProofs` binders |
| S2 | PNVI data shapes | internals refactor (zero behaviour change) | `IotaEntry`, `iotaMap : TreeMap Int IotaEntry`; `findOverlapping` with the three-variant table (ascending key order argued against `IntMap.fold`); `exposeAllocation(s)`, `addIota`, `lookupIota`, `resolveIota`; `provsOfBytes`/`mergeTaint`; `mkIval`; `reconstructValue` gains the switch set, the closure and the taint result (default: taint discarded, closure unused — provably today's value); the 11 consumer sites listed | M (3–4 d) | the measure proof restatement; `TreeMap.foldl` order lemma for the `Double (first, second)` pair |
| S3 | the ae-udi arms | **forced semantics change** (still CLI-refused → zero movement on every lane) | every MISSING/STOP row of §A.3 as the real arm, with impl_mem cites in the order upstream evaluates them: `ptrfromint` PNVI arm (no device check), `intfromptr` exposure + `mkIval`, load's expose-then-receipt order, the five `Prov_symbolic` arms (kill/load/store/validForDeref/eff_array_shift incl. the printf-arm kill), `eq_ptrval` iota arm, `diff_ptrval` two iota arms, the bounds arms; the three STAYS-STOP mirrors confirmed; unit pins under `⟨[.PNVI .AE_UDI]⟩` | L (5–8 d) | exactness of error kinds/locations (`LoadAccess` on the store arm; the "second failure" of `resolve_iota`); the stdout debug arm (§F.5); hidden ordering (expose before `last_used`) |
| S4 | the lane, the acceptance, the docs | spec addition | `Main` accepts exactly `PNVI_ae_udi`; `check_cli_refusals.sh` (D.3); `scripts/test_pnvi.sh` + baselines + plants P1–P6; register rows; LADDER/VALIDATION/CONTRACT/SUPPORTED; tray drafts | M (3–4 d) | the 4 both-crash rows' class pinning; the 6561-execution row's wall time; pKVM exhaustive is a resource limit on both engines (label, do not loosen) |
| S5 | consumer re-pin note | spec addition | the exact list for the chosen option, the default-instance recipe, the `reconstructValue` change, the facts that moved from `rfl`-on-a-constant to `rfl`-at-the-instance | S (1 d) | none |

Order: S0 → S1 → S2 → S3 → S4 → S5 (S2 may precede S1; S3 must follow both). Total [AGENT]: roughly 17–26 person-days
with option 3, 14–21 with option 1. Grind tripwire: none of these is a proof grind; the one long computation is the
6561-execution litmus row and the pKVM exhaustive breach, both measurement, both labelled.

## F. Open questions for the operator (each with a recommendation [AGENT])

1. **Threading option.** Option 3 (instance-implicit ambient parameter, one lem-lean slice) — recommended; option 1
   (explicit reader, no backend work, ~900 consumer sites) — fallback; option 2 — decline (§B.2).
2. **`initial_driver_state` under option 2 only:** append the parameter (307 mechanical consumer edits, one entry) vs a
   5-arg default shim (zero edits, a second name). Moot under options 1/3 (unchanged). If option 2 is nonetheless
   chosen: append.
3. **PLAIN / AE arms:** mirror the shared six-line table and the shared `AE ∨ AE_UDI` guards (so the Lean model is
   impl_mem's whole switch domain), but accept only `[]` and `[PNVI_ae_udi]` at the CLI until a lane validates another
   set — recommended. Alternative: loud kills for `is_PNVI ∧ ¬AE_UDI` inside `CerbMem` (more stops, less mirror).
4. **The oracle's fail-open switch parser** (§C.5: unknown or overriding names are ignored): Lean refuses (class (c)),
   each with its own message — recommended; file a tray report ("`--switches` typo runs the default semantics").
5. **The `Printf.printf "id1= …"` debug arm** (`:2331-2334`) prints to the oracle's PROCESS stdout before killing: in
   batch mode that line precedes the `Error {…}` verdict and would reach the codec. Recommendation: Lean mirrors the
   kill only (never writes a non-verdict line to stdout); S4 constructs a witness program (two adjacent exposed objects,
   a non-zero shift admitted by both) and pins the row as a crash-class/text-class difference with the codec's actual
   behaviour recorded; tray report ("debug print in a semantics arm"). Never a Lean stdout print.
6. **The four `combine_prov` crashes on upstream's own litmus suite** (§C.2): both engines crash alike (fail-stop with
   the OCaml text) — recommended, per the no-innovation rule; tray report quoting the `TODO: this is improvised, need
   to check with P`. Not a Lean fix.
7. **`TODO`/`FIXME` comments on DEFINED arms** (`provs_of_bytes`'s `TODO(iota)` drop, `abst`'s `DoubleAlloc →
   Prov_some alloc_id1` "FIXME/HACK(VICTOR): This is wrong", `find_overlaping`'s dropped third candidate, `ptrfromint`'s
   `TODO: device memory?`): mirror the defined arm with the comment cited in-code — recommended (a stop there would
   DIVERGE from an oracle that continues). The brief's rule ("every upstream TODO … stays a loud stop") is read as
   applying to TODO-shaped FAILURE sites; confirm this reading.
8. **pKVM exhaustive under the switch breaches 4G on the oracle** (§C.3): the lane compares `--first`/one trace,
   labelled outside §1, and records the exhaustive resource limit on both engines — recommended; no trace-set pruning,
   no fork-count tuning (that would be innovation).
9. **`is_CHERI` as a build constant** (§B.4.1) — recommended; alternative: lift its 32 sites too (puts the binder on
   `sizeofCtype`, 314 consumer sites, for a value that can never be true in this executable).
10. **The failure-reach register's wrong reason text** (rows 64/65/103, §A.6): fix in S1 regardless of the rest —
    recommended.
11. **What a future reasoning effort under `PNVI_ae_udi` would need that this implementation does not provide**
    ([USER 2026-10-04]): (a) well-formedness of the iota map as an invariant (every key `< nextIota`; `Double (a,b)`
    with `a ≠ b`, both live when minted; `resolve_iota` only narrows) — the data shape (`TreeMap Int IotaEntry`) is
    proof-friendly (the consumer already proves over `Std.TreeMap`), the invariant is not stated here; (b) exposure
    monotonicity (`taint` only moves `Unexposed → Exposed`) — not stated; (c) a specification of `findOverlapping`
    (the set of live/exposed allocations containing or one-past `addr`, with the ORDER-DEPENDENT truncation at two —
    any spec must mention key order); (d) the `msum "pointer equality"` fork on provenance-mismatched comparisons —
    the consumer's own disclosed limitation (`PtrEqModel.lean:21-26`: no `NDactive` mirror step, "UNPROVABLE at the
    classic surface") — becomes PERVASIVE under PNVI (every cross-object `==`, and `Prov_symbolic` vs `Prov_some`
    pairs), and is the reason the pKVM exhaustive set explodes: reasoning under the switch needs a treatment of that
    fork FIRST, and this design does not change it (mirror); (e) `reconstructValue` now depends on the state through
    the closure — their load lemmas (`HeapModel.lean:381` quotes it with `σ.lastUsedUnionMembers σ.funptrmap`) carry
    one more argument; (f) the Core shape differs under the switch (`PtrArrayShift` memops instead of pure
    `array_shift`, §C.4) — their reconstruction IR (`CerberusIris.Recon.*`) has no node view for that shape;
    (g) integers carry `Prov_none` under PNVI (`mk_ival`) — any integer-provenance fact simplifies, none breaks.
12. **`--iso`**: stays refused (it sets five refused switches; `pipeline.ml:579`'s `rm_unspecs` pass has no Lean
    counterpart) — recommended.
13. **Switch syntax mirroring:** accept the oracle's `--switches=A,B` and `--switches A,B` forms; refuse a repeated
    option as cmdliner does ("cannot be repeated", the `--args` precedent) — recommended.

## Appendix — probe commands (MEASURED, for reproduction)

From the census worktree, with `scripts/ce opam exec --switch=. --` and `CERB_MEM_MAX=4G scripts/capped timeout 60`:

```
main.exe --runtime=_build/install/default --exec --batch --mode=exhaustive [--switches=PNVI_ae_udi] tests/pnvi_testsuite/<f>.c
main.exe --runtime=_build/install/default --nolibc --exec --batch [--switches=PNVI_ae_udi] --nostdinc -I <case-study> -I tests/census/pkvm tests/census/pkvm/<d>.c <case-study>/page_alloc.c
main.exe --runtime=_build/install/default --nolibc --pp core [--switches=PNVI_ae_udi] shift.c
main.exe --runtime=_build/install/default --nolibc --exec --batch --mode=exhaustive --switches=bogus shift.c        (and PNVI_ae_udi,PNVI; --iso)
```

Static greps (this worktree): `grep -n -E 'SW_PNVI|is_PNVI|AE_UDI|Prov_symbolic|iota|has_switch' memory/concrete/impl_mem.ml`;
the generated-tree counts over the census worktree's `lean_frontend/generated/*.lean` (built at the same commit);
the consumer counts over `/home/dev/projects/cerberus-sl` with `.lake/` excluded.
