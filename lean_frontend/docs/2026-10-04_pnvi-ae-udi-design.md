# Supporting `--switches=PNVI_ae_udi`: design record (2026-10-04)

**Status:** DESIGN PASS — one record, nothing implemented. Branch `design/pnvi-ae-udi-20261004` over mainline
`ae48126e5`. Author: the design-pass agent [AGENT]. Every claim below is marked **[AGENT]** (this agent's reading or
judgement) or **MEASURED** (a command run in this pass, output quoted verbatim). The only [USER] items are the four
quotes in §1 (three from the brief, the 2026-10-05 ruling in §1.4); the consumer's positions are *consumer statements*
(§1.3, §1.5), not rulings. No build of any kind was run; the oracle probes used the census worktree's already-built
binary (§C.0). Scratch lived under this worktree's `.tmp/` and was deleted before each commit.

**Amended 2026-10-05** (second commit): the operator ruled on the record (§1.4) — the recommendations stand except that
upstream crashes and obviously wrong upstream arms become LOUD REFUSALS, never mirrored; §G classifies every flagged
site on the PNVI-ae-udi path with its measured reach; §B.7 evaluates the consumer's `reconstructValue` wrapper
request (§1.5); §C.6 adds the reach probe; §D, §E, §F are updated accordingly. The 2026-10-04 text is kept where it
still holds; superseded sentences are marked.

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
  `expose_allocations` arm, `eq_ptrval`'s and `diff_ptrval`'s iota arms); **3 upstream `failwith`s** (`combine_prov` on a
  symbolic byte — which the oracle itself hits on 4 of its own 44 litmus files under the switch, §C.2;
  `array_shift_ptrval` on a symbolic pointer; `case_ptrval`'s wildcard) — the 2026-10-04 text said these "stay stops";
  under [USER 2026-10-05] they are REFUSALS (§G); **2 `assert false`/`IntMap.find` sites** (refusals too); **2 defined
  arms carrying a FIXME/debug print** (`abst`'s "This is wrong" arm → (C) refusal; the stdout `Printf.printf` before a
  kill → (B) refusal). The failure-reach register's reason text for the three `Prov_symbolic` stops is wrong
  ("symbolic execution mode") and those rows become reachable (§A.6).
- **Threading (§B).** Three options. **Option 3 — the switch set as an instance-implicit ambient parameter in the
  fuel-arc shape (`[LemFuel]`)** is recommended (ACCEPTED [USER 2026-10-05], §1.4; the consumer's 2026-10-05 statement
  accepts it with a `reconstructValue` old-name wrapper, evaluated FEASIBLE in §B.7): one mechanism for the frontend, the run and the hand-written memory
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
- **Ruling and refusals (§1.4, §G) — 2026-10-05.** [USER 2026-10-05] accepted §F 1–4 and 8–13 as recommended (option
  3 with S0 in lem-lean included) and reversed §F 5–7: upstream crashes and obviously wrong upstream arms on the PNVI
  path are LOUD REFUSALS in Lean. §G classifies 20 flagged sites on the PNVI-ae-udi path: **(A) 6** upstream
  `failwith`/`assert` → refuse (plus 1 invariant-failure kill treated as (A), and 1 arm shadowed by an (A) crash);
  **(B) 1** debug-print-then-kill → refuse; **(C) 1** arm upstream calls wrong → refuse when reached; **(D) 5** arms
  whose TODO is a question — 4 proposed MIRROR, 1 proposed REFUSE; **2 CLI** fail-open parses → refuse (already
  accepted); 2 (A)-shaped sites are ALSO on the default path (plus `case_ptrval`'s device half) and are NOT decided here
  (§G.3, §F.14). **MEASURED reach:** the (A) crash `combine_prov` is hit by 4 of the 44 litmus files (the oracle crashes
  there); no other refusal is reached by any litmus file or by any pKVM driver — the three pKVM drivers run 1212/2138/
  1330 loads under the switch with ZERO symbolic pointers minted and end as the census recorded; **no refusal stops a
  pKVM driver.** The one PNVI-path TODO every pKVM driver DOES hit is a (D) site (`:2308/:2379` "is it correct to use the
  ty as the lvalue_ty?") — proposed MIRROR; refusing it would kill pKVM (§G.2).
- **Validation (§D).** A new differential lane under the switch (litmus 44 + pKVM 4 in `--first` + a default-corpus
  sample); its oracle-crash-vs-Lean-refuse and oracle-runs-vs-Lean-refuse rows are REGISTERED REFUSAL ROWS, each named
  `R-PNVI-nn`, never agreement (§D.5); harness-level plants (a wrapper that strips the flag must turn the lane red; a
  build that treats the switch as default must turn it red; a refusal silently turned into a mirror must turn it red);
  `check_cli_refusals.sh` flips `PNVI_ae_udi` to an acceptance control and adds every other switch spelling as a
  refusal; the instance gate's scope is THIS repository only, plant-tested both directions (§D.2); the failure-reach
  register is re-classified; the default-mode ladder (Tier A+B) must show zero movement at every slice.
- **Slices (§E).** S0 lem-lean mechanism → S1 parameter plumbing (zero movement) → S2 PNVI data shapes + the
  consumer's `reconstructValue` wrapper with its kernel equality (zero movement) → S3 the PNVI arms AND the §G refusals
  (the forced semantics change; still CLI-refused, zero movement) → S4 the lane with the named refusal rows, the CLI
  acceptance, docs → S5 the consumer re-pin note with a line-for-line prediction (needs a scratch build of their tree).
  Roughly M, M, M–L, L, M, M.
- **Open questions (§F):** 1–4 and 8–13 ACCEPTED [USER 2026-10-05]; 5–7 superseded by §G; new: §F.14 the default-path
  (A)/(B)/(C)-shaped sites (not decided here), §F.15 the four (D) MIRROR proposals and the one (D) REFUSE proposal,
  §F.16 the refusal mechanism's shape. §F.11 lists what a future reasoning effort under the switch would need that this
  implementation does not provide.

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

### 1.4 Operator ruling on this record, verbatim ([USER 2026-10-05], relayed by the coordinator)

"Re PNVI - agree on your recs except for mirroring crashes / obviously wrong behavior. These should be refusals
surely?"

Reading, as relayed: §F 1, 2, 3, 4, 8, 9, 10, 11, 12 and 13 are accepted as recommended — including OPTION 3 (the
instance-implicit ambient parameter) with S0 in lem-lean. §F 5, 6 and 7 change: upstream crashes and obviously wrong
upstream behaviour on the PNVI-ae-udi path become LOUD REFUSALS in Lean, not mirrored crashes and not mirrored wrong
arms. The ruling is about the PNVI work and must not silently change default behaviour: a flagged site that is also
reached in default mode is a separate operator question (§G.3, §F.14), not decided here.

### 1.5 Consumer statement (cerberus-sl dev #1, 2026-10-05, relayed by the coordinator; NOT a ruling)

(1) `reconstructValue`: keep the OLD name and type as a default-shaped function, with the new closure-taking,
taint-returning function under a NEW name; the old one is the new one at the default, closure fixed, taint discarded,
proved equal to today's value — so their sites and frozen statements stay textually unchanged (their
`saveR`/`saveRH` precedent, `CerberusIris/Recon/Lower.lean:175-184`). Orchestrator position [AGENT]: acceptable under
three conditions — (a) the old-name wrapper is pinned EXPLICITLY at `⟨defaultSwitches⟩`, never at the ambient instance;
(b) NO production path in this tree calls the old name, enforced by a check; (c) the equality theorem is stated and
kernel-checked. Evaluated in §B.7. (2) The instance gate's ban on `instance : CerbGlobal.Switches` covers ONLY this
repository's library, seams, generated tree, tests and speclab; consumers declare their own (cerberus-sl: exactly one,
at `defaultSwitches`, in one layer module); plant-tested both directions. (3) Accepted by the consumer: the
`defaultSwitches` rename, the four fact files under their local instance, `iotaMap`'s type, the positionally unchanged
call sites, default bit-identity (their corpus check re-verifies 72 programs), and the fingerprint drift as ONE freeze
amendment at re-pin. (4) The S5 re-pin note must PREDICT, line for line, the exact before/after text of each of their
changed sites (file:line against their tree at that time) and the set of their declarations whose elaborated terms
change (§E S5).

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
| 10 | `:462-479` `provs_of_bytes` → `` `NoTaint | `NewTaint ids ``; `:470-471` `Prov_symbolic iota -> acc (* TODO(iota) *)` | result discarded by `load` (#24 takes the default branch) | the `NewTaint` ids are EXPOSED by `load` (#24) | none | MISSING; the `Prov_symbolic` arm is SHADOWED by the `combine_prov` crash that `pvi_split_bytes` raises first on the same bytes (`:986`/`:999` run before `:988`/`:1001`) — §G row R2: REFUSE (unreachable, fail-closed) |
| 11 | `:543` `view_byte` `Prov_symbolic id -> Observed_symbolic_provenance id`; `:590-591` `string_of_provenance` `"@iota(n)"` | — | — | `viewByte` (`:198-204`); `:2036` | PRESENT |
| 12 | `:2978-2990` `serialise_prov` `"iota"` JSON with the map entry | UI only | UI only | none | OUT OF SCOPE (the UI dump; no batch-path reader) |
| 13 | `:662-668` `Concrete.is_PNVI ()` (own definition via `has_switch_pred`) | `false` | `true` | `CerbGlobal.is_PNVI () := false` with `is_PNVI_eq : … = false := rfl` | must become a function of the parameter (§B) |
| 14 | `:672-677` `mk_ival prov n`: under `is_PNVI` → `IV (Prov_none, n)` — **integers carry no provenance under any PNVI variant** | `IV (prov, n)` | `IV (Prov_none, n)` | no function; the non-PNVI branch is inlined at `reconstructValue` (`:1090` and the second occurrence `:1275`, `.IV (provFromIntegerBytes bytes) n`) and `intfromptr` (`:2894, :2899, :2918`) — callers in OCaml: `:992, :1005, :2486, :2488, :2505` (MEASURED) | MISSING branch; introduce `mkIval sws prov n` and use it at the mirror sites |

### A.2 `find_overlaping`, exposure, iota — the machinery (all MISSING)

| # | OCaml site | Under default | Under ae_udi | Lean | Note |
|---|---|---|---|---|---|
| 15 | `:796-842` `find_overlaping st addr`: `(require_exposed, allow_one_past)` = PLAIN `(false,false)`, AE `(true,false)`, **AE_UDI `(true,true)`**, no PNVI `(false,false)` (`:799-813`); fold over `allocations` in key order: a live allocation containing `addr` (exposed, if required) → candidate; else if `allow_one_past` and `addr = base+size` (exposed, if required) → candidate; `NoAlloc → SingleAlloc → DoubleAlloc (first, second)`; a third candidate is DROPPED (`:839-842` "TODO: I guess there is an invariant…") | callers only under `is_PNVI` (#20 is guarded; #26 is guarded) — never reached | the provenance oracle for `ptrfromint` and `abst` | none | MISSING. `Std.TreeMap.foldl` iterates in ascending key order = OCaml `Map.fold` (ascending) — the `(first, second)` ORDER matters (`resolve_iota` tries `first` first, #19). `:811 Some _ -> assert false` → §G row R3, REFUSE (`R-PNVI-02`). The dropped third candidate → §G row R4, class (D), proposed REFUSE (`R-PNVI-03`) |
| 16 | `:877-886` `expose_allocation id` (taint := Exposed; absent id → no-op) | never called | `intfromptr` (#27) | none | MISSING |
| 17 | `:887-901` `expose_allocations taint` (`NoTaint` → nothing; `NewTaint ids` → each exposed) | never called | `load` (#24) | none | MISSING |
| 18 | `:903-909` `add_iota (id1,id2)` → fresh iota, `iota_map[iota] := Double` | never | `ptrfromint` (#26) | none | MISSING |
| 19 | `:911-914` `lookup_iota` (`IntMap.find`: `Not_found` on a missing iota — an uncaught exception); `:916-942` `resolve_iota precond iota`: `Single id` → precond or `fail`; `Double (a,b)` → precond a, else precond b, else the SECOND failure; then `iota_map[iota] := Single id` | never | load/store/kill (#22-24) | none | MISSING; a missing iota is `failwithI` (mirrors the exception); the "second failure" is the error the oracle reports — mirror exactly |

### A.3 The memory operations' PNVI arms

| # | OCaml site | Under default | Under ae_udi | Lean | Status |
|---|---|---|---|---|---|
| 20 | `:951-1128` `abst` (= `reconstructValue`): integer/byte arms return `provs_of_bytes` taint (`:988, :1001`) and `mk_ival` (#14); pointer arm `:1056-1088`: `if is_PNVI ()` then `NotValidPtrProv` → `find_overlaping n`: `NoAlloc → Prov_none`, `Single → Prov_some`, `Double (a,_) → Prov_some a` (`:1079-1082` "FIXME/HACK(VICTOR): This is wrong…"; the `failwith "TODO(iota): abst => make a iota?"` is commented OUT), `ValidPtrProv → prov`; else `prov` | the `else prov` branch; taint discarded | the PNVI branch | `reconstructValue_lemFuel` (`:1074-1130`; a second occurrence of the same arms at `:1275-1288`) uses `splitBytesProv …).1` unconditionally; returns no taint; has no `find_overlaping` | MISSING. The NEW function (§B.7) gains the switch instance, a `findOverlapping : Int → OverlapResult` closure (mirroring OCaml's closure argument exactly) and returns the taint; the old names stay as default-pinned wrappers. The `Double → Prov_some a` arm → §G row R6, class (C): REFUSE when reached (`R-PNVI-05`). The measure proof in `CerbMem_lemMeasureProofs.lean` restates |
| 21 | `:1350` `allocate_object` `SW_zero_initialised` | repr of unspecified | same (not PNVI) | `:2301` | STOP, unchanged by this design (refused switch) |
| 22 | `:1504-1590` `kill`: `:1506` forbid_nullptr_free; **`:1519-1553` `Prov_symbolic` arm**: precondition = `is_dead z` → `Free_dead_allocation` (regardless of `is_dyn` — unlike the `Prov_some` arm's `:1572 failwith` for a static kill of a dead object), else `addr ≠ base` → `Free_out_of_bound`; `is_dyn` → `is_dynamic addr` else `Free_non_matching`; `resolve_iota`; retire the allocation; zap if switched | `Prov_symbolic` never minted | live | `:2361` forbid (STOP, unchanged); `:2369-2372` "killM: Prov_symbolic in concrete model" | MISSING (the arm); `:2406` zap stays STOP |
| 23 | `:1592-1706` `load` **`:1662-1684` `Prov_symbolic` arm**: precondition = dead → `DeadPtr`; `¬within_bound` → `OutOfBoundPtr`; atomic member → `AtomicMemberof`; `resolve_iota` → `do_load (Some id)` | never | live | `:2540-2542` "loadM: Prov_symbolic in concrete model" | MISSING |
| 24 | `:1602-1606` `load`/`do_load`: `if has_switch (PNVI AE) ∨ (PNVI AE_UDI) then expose_allocations taint` — BEFORE `record_access`/`last_used` (`:1607-1609`) | `return ()` | exposes every allocation whose id appears in the loaded bytes' provenances | NO guard at all (`:2502-2506` says "DECLARED (refused set, Z-24; not one of the eight explicit arms)") | MISSING; note the ORDER: expose, then the receipt/`last_used` update, then the trap check |
| 25 | `:1709-1833` `store` **`:1771-1804` `Prov_symbolic` arm**: precondition = `¬within_bound` → `OutOfBoundPtr`; readonly → `MerrWriteOnReadOnly kind`; atomic member → `MerrAccess (LoadAccess, AtomicMemberof)` (upstream's `LoadAccess` tag on a store — mirror verbatim; the `Prov_some` arm `:1818` has the same quirk, already mirrored); `resolve_iota`; `do_store`; locking | never | live | `:2614-2616` "storeM: Prov_symbolic in concrete model" | MISSING |
| 26 | `:2170-2217` `ptrfromint` **`:2190-2205` `is_PNVI` arm**: `(* TODO: device memory? *)`; `n = 0 → PVnull`; else `find_overlaping st n`: `NoAlloc → Prov_none`, `Single → Prov_some`, `Double → add_iota → Prov_symbolic`; `PV (prov, PVconcrete (None, n))`. NOTE: `device_ranges` are NOT consulted under PNVI, and the integer's own provenance is IGNORED | the PVI arm `:2207-2217` | the PNVI arm | `:2878-2879` loud kill "ptrfromint: the PNVI arm … is not ported" | STOP → real arm. The device TODO → §G row R7, class (D), proposed MIRROR (no device check under PNVI) |
| 27 | `:2483-2505` `intfromptr`: `:2490-2498` `if has_switch (PNVI AE) ∨ (PNVI AE_UDI)` then `Prov_some id → expose_allocation id`; `:2486/:2488/:2505` `mk_ival` | no exposure; `IV (prov, …)` | exposure; `IV (Prov_none, …)` | `:2907-2908` loud kill (guarded by `is_PNVI`) | STOP → real arm; `mk_ival` (#14) |
| 28 | `:1874-1924` `eq_ptrval`: `:1896` strict_pointer_equality; **`:1905-1914` `(Prov_symbolic i1, Prov_symbolic i2)`**: `lookup_iota` both; `(Single a, Single b) → a = b`; else `false`; then `true → addr eq`, `false → msum "pointer equality" [provenance false; ignoring addr eq]` | never | live | `:2691` strict (STOP, unchanged); `sameProv`'s `_, _ => false` folds the symbolic pair into the mismatch arm (`:2683-2687`) — WRONG for `Single/Single` equal ids | MISSING arm (today's fold is unreachable, hence harmless) |
| 29 | `:1998-2107` `diff_ptrval`: `:2014` PERMISSIVE; **`:2032-2060` `(symbolic, some)` and `(some, symbolic)`**: `Single a → a = id' ∧ precond`; `Double (a,b) → id' ∈ {a,b} ∧ precond → collapse to `Single id'``; **`:2063-2105` `(symbolic, symbolic)`**: intersection `None → MerrPtrdiff`; `Single → collapse both, valid`; `Double → addr1 = addr2 → valid (zero) else fail (MerrOther "in `diff_ptrval` invariant of PNVI-ae-udi failed: ambiguous iotas with addr1 <> addr2")` (a `fail`, i.e. a kill with that text, not a `failwith`) | the `Prov_some/Prov_some` arm | live | `:2773` PERMISSIVE (STOP, unchanged); no symbolic arms (fall into `errorPostcond`) | MISSING arms |
| 30 | `:2130-2167` `validForDeref_ptrval` **`:2152-2163` `Prov_symbolic`**: `Single → do_test`; `Double → do_test a ∨ do_test b` | never | live | `:2850-2852` loud kill | MISSING arm |
| 31 | `:2288-2400` `eff_array_shift_ptrval` — reachable ONLY under strict/PNVI/CHERI (the elaborator emits `PtrArrayShift` there, `translation.lem:2112, 2249, 3178`; MEASURED §C.4): **`:2301-2376` `Prov_symbolic` arm** with `precond` = `STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE)` → `base ≤ shifted ∧ shifted + sizeof ≤ base + size + sizeof` (one-past allowed) else `true`; `Double`: `ival ≠ 0` → precond a: `true` → precond b: `true` → PERMISSIVE ? `NoCollapse` : **`Printf.printf "id1= %s, id2= %s ==> addr= %s\n"` to STDOUT then `fail (MerrOther "(PNVI-ae-uid) ambiguous non-zero array shift")`**; `false → Collapse a`; a `false` → precond b `true → Collapse b`, `false → MerrArrayShift`; `ival = 0` → precond a ∨ precond b else `MerrArrayShift`; `Single → precond ∨ MerrArrayShift`; **`:2381-2382` `Prov_some`** bounds arm → in-bounds-or-one-past else `MerrArrayShift` (UB046); **`:2393-2394` `Prov_none`** → `fail (MerrOther "out-of-bound pointer arithmetic (Prov_none)")`; `Prov_device` unguarded | unreachable (no `PtrArrayShift` emitted) | every pointer `+`/`-`/array decay | `:2949-2950` symbolic loud kill; `:2956-2960` ONE loud kill for the `STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE)` guard | STOP → real arms (MISSING symbolic arm). The `Printf.printf`-then-`fail` arm → §G row R16, class (B): REFUSE (`R-PNVI-10`); the PVfunction `failwith` → R13 (A), REFUSE (`R-PNVI-09`); the two "is it correct to use the ty" TODOs → R15 (D), proposed MIRROR (every pKVM pointer shift passes here) |

### A.4 Sites with no switch read whose behaviour the switch exposes

| # | OCaml site | Lean | Status |
|---|---|---|---|
| 32 | `:2810-2814` `copy_alloc_id` = `intfromptr` (range check only) then `ptrfromint ival` | `copyAllocId` (`:3236-3237`) | PRESENT; correct once #26/#27 are |
| 33 | `:1930-1995` lt/gt/le/ge: provenance ignored off-strict | `:2718-2751` | PRESENT (STOP arms for strict stay) |
| 34 | `:2508-2555` `op_ival`/bitwise with `(* NOTE: for PNVI we assume prov = Prov_none *)` | `opIval` etc. | PRESENT; the assumption HOLDS because `mk_ival` (#14) strips provenance from every integer — except integers read from a symbolic pointer's BYTES (#9/#30) |

### A.5 Upstream `failwith`/`assert false`/debug arms on the path — SUPERSEDED by §G ([USER 2026-10-05]: refusals)

The 2026-10-04 text of this table said "STAY STOPS (mirror upstream, never resolve)". Under §1.4 every row below is a
LOUD REFUSAL in Lean (class and reach in §G.1); the rows are kept for the site list and the reach notes.

| # | OCaml site | Reached how under ae_udi | Lean today | Disposition (§G) |
|---|---|---|---|---|
| 35 | `:390-394` `combine_prov` `(Prov_symbolic, _) | (_, Prov_symbolic) → failwith "Concrete.combine_prov: found a Prov_symbolic"` ("TODO: this is improvised, need to check with P") | reading the bytes of a stored `Prov_symbolic` pointer as an integer (`pvi_split_bytes`, #9): MEASURED on 4 of upstream's own litmus files (§C.2) | `combineProv` `:323-325` `failwithI` with the OCaml text | §G R1, (A): REFUSE `R-PNVI-01` (the oracle crashes; the lane row is a registered refusal, never agreement). Tray candidate (§F.6, superseded wording) |
| 36 | `:2247-2265` `array_shift_ptrval` (PURE) `Prov_symbolic → failwith "Concrete.array_shift_ptrval found a Prov_symbolic"` | the pure `array_shift` is still emitted in Core elaborated WITHOUT the switch — the libc dump `tests/libc/libc.core` (685 sites, MEASURED; `runtime/libcore/std.core`'s 4 occurrences are comment lines, MEASURED) — and the oracle's own `libc.co` is default-elaborated too (`pipeline.ml:34` switches only the `inner_arg_temps` variant); also `core_eval.lem:752`, `formatted.lem:391/:419` (`%s`) | `arrayShiftPtrval` `:1847` `failwithI` | §G R8, (A): REFUSE `R-PNVI-06` |
| 37 | `:1852-1858` `case_ptrval` `| _ → failwith "case_ptrval"` (a `Prov_symbolic` or `Prov_device` concrete pointer) | `core_run.lem:1010`, `core_reduction.lem:1408`, `core_eval.lem:920` — calls THROUGH a pointer value | `casePtrval` `:1480-1500` `failwithI` | §G R11: the `Prov_symbolic` half (A) REFUSE `R-PNVI-07`; the `Prov_device` half is on the DEFAULT path (Z2-M-02) — §G.3, not decided |
| 38 | `:811` `find_overlaping` `Some _ → assert false` | unreachable by construction | — | §G R3, (A): REFUSE `R-PNVI-02` |
| 39 | `:914` `lookup_iota` `IntMap.find` → `Not_found` | an iota absent from the map — unreachable while every `Prov_symbolic` is minted by `add_iota` | — | §G R5, (A): REFUSE `R-PNVI-04` |
| 40 | `:2331-2334` the `Printf.printf "id1= …"` + `fail` arm (#31) | two live exposed allocations both admitting a non-zero shift | — | §G R16, (B): REFUSE `R-PNVI-10` (MEASURED: never printed on any litmus or pKVM trace) |
| 41 | `:1079-1082` `(* FIXME/HACK(VICTOR): This is wrong, but when serialising the memory in the UI, I get this failwith. *)` `Prov_some alloc_id1` `(* failwith "TODO(iota): abst => make a iota?" *)` | `abst` on a two-allocation address with non-pointer-shaped bytes | — | §G R6, (C): REFUSE when reached `R-PNVI-05` |

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
  state), and return the taint. Consumer sites (MEASURED grep, qualified AND unqualified, `.lake/`/probes/docs
  excluded): about 40 textual sites in 9 files — statements at `HeapModel.lean:238, 312-313, 327-330, 352, 371-375,
  434`, `HeapNeg.lean:1087-1124` (5), `HeapLK.lean:348, 354`, `Memory/SourceViews.lean:66`, `MixedPick.lean:412, 418`,
  `Repr.lean:242, 265, 286, 301, 878, 895, 913, 925`, `CerberusSL/S2Closures.lean:81, 85, 92` (`:85` states the WORKER
  `reconstructValue_lemFuel 1 …` directly); proof scripts that unfold the worker at `PtrRepr.lean:105, 183`,
  `HeapModel.lean:314`, `Repr.lean:251, 506, 529, 535, 588, 743, 887, 900` (11). The 2026-10-04 text's "11 sites"
  counted the qualified `CerbMem.`-prefixed mentions only — corrected here. The consumer's old-name-wrapper request
  (§1.5) keeps every STATEMENT textually unchanged; §B.7.

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
instance; a gate bans any other `instance : Switches` (plant-tested). **Scope of that gate (consumer statement §1.5
item 2, adopted [AGENT]):** it scans ONLY this repository — `lean_frontend/*.lean` (the seams), `generated/`, `test/`,
`speclab/` and the LemLib copy it consumes — never a consumer's tree. Consumers declare their own instances (cerberus-sl:
exactly one, at `defaultSwitches`, in one layer module); a consumer instance is the intended way to state default-mode
facts by `rfl`. Plants in both directions: an `instance : CerbGlobal.Switches` planted in any scanned root is RED; a
scratch consumer-style package outside the roots (a `.tmp/` Lake package that depends on `lean_frontend` by path and
declares an instance) is NOT scanned and the gate stays green (§D.2 P8).

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
| `CerbMem.reconstructValue eds tds unionmap funptrmap addr τ bytes` (+`_lemFuel`) | ≈40 textual sites in 9 files (statements + 11 proof scripts; §B.0) | NEW name carries +switches, +`findOverlapping` closure, returns taint; OLD names kept as default-pinned wrappers (§B.7): statements unchanged, the 11 proof scripts add one unfolding lemma | same | same |
| `CerbMem.initialMemState top` | 94 | unchanged | unchanged (default field) | unchanged |
| `CerbMem.MemState` literals `{ lastAddress := … }` / `with` updates | 12 / 16 | unchanged | unchanged if `switches` has the default | unchanged |
| `MemState.iotaMap` (type changes to `TreeMap Int IotaEntry`) | 0 | — | — | — |
| `CerbGlobal.switches` | 5 | renamed `defaultSwitches` | kept as the default constant | renamed `defaultSwitches` |
| `CerbGlobal.has_switch sw` (6) and the facts at `HeapModel.lean:381`, `HeapModelKill.lean:31`, `Memory/Transitions.lean:62`, `PtrEqModel.lean:34` | 6 | `has_switch sws sw`; facts at `[]` by `rfl` | `has_switch σ.switches sw`; facts need `σ.switches = []` | `@has_switch ⟨[]⟩ sw`; facts by `rfl` under their local instance |
| `CerbGlobal.current_execution_mode`, `CerbConf` | 1 | unchanged (out of scope) | unchanged | unchanged |
| `Interface.AdmittedTop`, `oomOutcome`, `mkGS`, the run digest (`rs.sym_digest`), the enum reader (`P.enumDefs`), the fail-closed matcher (`match_pattern`/`typecheck_pattern`) | many | unchanged | unchanged | unchanged |

Derived totals (textual sites): option 1 ≈ 900 in ~90 files; option 2 ≈ 330 (307 of them the appended argument) +
new preservation lemmas; option 3 ≈ 27 + one instance declaration + freeze-fingerprint drift of the frozen terms (with
the §B.7 wrapper the `reconstructValue` statements drop out of the 27; 11 proof scripts remain).

### B.6 Recommendation [AGENT] — ACCEPTED [USER 2026-10-05] (§1.4)

**Option 3**, with **option 1 as the fallback** if the operator declines the lem-lean mechanism slice. Reasons, in the
project's order of tie-breakers: (i) mirror — one honest parameter at every site, OCaml untouched; (ii) the reasoning
target — quantification by a binder, default facts by `rfl`, the ae-udi arms unfoldable at `⟨[.PNVI .AE_UDI]⟩`, and no
second signature change when reasoning under the switch begins; (iii) consumer — the shortest exact list, and the
mechanism they already live with for fuel; (iv) fail-closed — no default instance anywhere (gate-enforced). Option 2 is
declined for the three-carrier problem (§B.2). If option 1 is chosen, name the reader so that its sorted position is
documented in the consumer note (a name sorting after `tagDefs` would APPEND rather than insert — but choosing a name
for its sort order is a house trick; prefer the honest `switches` and the loud middle insertion).

### B.7 The consumer's `reconstructValue` old-name wrapper (consumer statement §1.5 item 1) — feasibility [AGENT]

**Today's shape (MEASURED, `CerbMem.lean`):** the fuel'd worker `reconstructValue_lemFuel (lemFuel) (enumDefs)
(ambient) (unionmap) (funptrmap) (addr) (ty) (bytes) : MemValue` (`:1074`), the fuel-FREE wrapper `reconstructValue …
:= reconstructValue_lemFuel (CerbTagsWf.envBound ambient ty) …` (`:1242-1245`), the sufficiency theorem
`reconstructValue_measure_sufficient` under `CerbTagsWf.Acyclic ambient` (`CerbMem_lemMeasureProofs.lean:1032-1041`;
`scripts/fuel_hypotheses.txt:65`), and — the precedent the consumer's request needs — a VERBATIM TWIN kept for a
kernel-checked shape equality: `reconstructValue_indexed_lemFuel` (`:1250-1356`, "NOT executed by the driver; it
exists so that the C1 shape change is a kernel-checked equality") with `reconstructValue_lemFuel_eq_indexed` and
`reconstructValue_eq_indexed` (`:1361-1400`). The only production caller of the old name is `loadM` (`:2513`,
MEASURED grep; the other mentions are the worker's own recursion, the twin and the proofs).

**The proposed shape.** New names (working names; S2 fixes them): `reconstructValuePNVI_lemFuel [Switches] (lemFuel)
(enumDefs) (ambient) (findOverlapping : Int → OverlapResult) (unionmap) (funptrmap) (addr) (ty) (bytes) : Taint ×
MemValue` and its `envBound` wrapper `reconstructValuePNVI`, with their own sufficiency theorem (the existing proof
restated: the closure is never recursed on, the taint pair rides along) and a new `fuel_hypotheses.txt` row. Old
names kept with their exact types as wrappers pinned at the default: `reconstructValue_lemFuel n … :=
(@reconstructValuePNVI_lemFuel ⟨defaultSwitches⟩ n enumDefs ambient noOverlap unionmap funptrmap addr ty bytes).2`
(where `noOverlap := fun _ => .NoAlloc`, the value the default arm never consults) and `reconstructValue … :=
reconstructValue_lemFuel (envBound ambient ty) …` — the wrapper's TEXT is unchanged.

**The three conditions.** (a) The pin is the explicit instance `⟨defaultSwitches⟩` in the definition, never the
ambient one — the old names are honestly "the default-mode reconstruct" and can never run under a PNVI instance with
the wrong closure: ✓ by construction. (b) No production path calls the old names: `loadM` (and the indexed twin, if
kept) call `reconstructValuePNVI`; a check (`scripts/check_default_reconstruct_unused.sh`, or a row of the exec-purity
gate) requires that the only mentions of `reconstructValue`/`reconstructValue_lemFuel` in `lean_frontend/*.lean` +
`generated/` are their two definitions, the equality theorems and doc comments; plant: a scratch copy of `loadM` calling
the old name is RED. (c) "Proved equal to today's value": a statement needs today's body as a named reference, so
today's `reconstructValue_lemFuel` text is retained VERBATIM as `reconstructValueLegacy_lemFuel` in a TEST module
(`test/Unit/ReconstructLegacyTest.lean`, compiled by row 1 — the indexed twin's role, moved out of production), and
`theorem reconstructValue_lemFuel_eq_legacy : reconstructValue_lemFuel n … = reconstructValueLegacy_lemFuel n …` is
proved by the SAME induction as `reconstructValue_lemFuel_eq_indexed` (fuel induction, `cases ty`, the arms' `if
is_PNVI …` guards reduce at `⟨[]⟩` by `rfl`/`simp`, the taint pair projects away); the old sufficiency theorem
`reconstructValue_measure_sufficient` follows from the new pair's by `congrArg Prod.snd` and keeps its statement.
Feasibility: **feasible** — the indexed-twin proof is the template; estimated +1–2 person-days inside S2.

**The fuel-forms gate.** The old pair stays MEASURED: the wrapper passes `envBound` to a `_lemFuel` worker (its text is
unchanged, so the P0 argument-correspondence check sees what it sees today); the gate classifies by wrapper↔worker
shape and does not require the worker to recurse [AGENT reading of the gate's description, `lean_frontend/CLAUDE.md`;
to be confirmed when S2 runs it — if the classifier refuses a non-recursive worker, the fallback is to drop the
`_lemFuel` old name and keep only `reconstructValue`, which changes ONE consumer statement, `S2Closures.lean:85`]. The
new pair is MEASURED with its own theorem and register row. The failure-reach register rows for the sites inside
(`unknown function pointer`, the union/struct asserts) are re-keyed to the new worker's name.

**The indexed twin** (`reconstructValue_indexed_lemFuel`, mem-scale S1's C1 shape witness): either re-derive it from
the new worker (keeping its equality) or retire it into the same test module beside the legacy copy — recommended
[AGENT]: retire into the test module (production carries one implementation; the C1 equality remains kernel-checked in
row 1). The twin has no user outside `CerbMem.lean` (MEASURED grep).

**What changes for the consumer.** Statements: none (every `reconstructValue …` / `reconstructValue_lemFuel 1 …`
statement is textually and type-identical). Proofs: the 11 scripts that `simp only [reconstructValue,
CerbTagsWf.envBound, reconstructValue_lemFuel]` (§B.0 list) now reach `(reconstructValuePNVI_lemFuel ⟨[]⟩ …).2` and need
one more lemma in the simp set — this tree exports `reconstructValue_lemFuel_unfold` (the wrapper equation) and the
new worker's equation lemmas, so the edit is one identifier per site; S5 predicts each line (§E S5). Freeze: the frozen
STATEMENTS' terms keep their heads; whether their fingerprints move depends on the consumer's fingerprint (value or
type) — S5 measures it on the scratch build rather than predicting it [AGENT].

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
switch** on this trace although the UB kind is the same: the elaboration of `page_alloc.c:715` differs (`PtrArrayShift`
memops change the expression's Core shape and the location the UB is attributed to). UB location is behaviour; the Lean
side reproduces it only if its ELABORATOR sees the switch — the frontend requirement of §B.0 measured on the target
program. (2026-10-05 caveat, §C.6: the re-measure with the census's current TU set showed `<715:2--715:17>` under the
switch on its one trace — the location is trace-dependent within the exhaustive set, and the oracle's `--mode` default
is random; the lane pins the exhaustive set, §D.1 row 2.)
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

### C.6 Reach probe for §G (MEASURED 2026-10-05): which traces mint or touch a `Prov_symbolic` pointer

Instrument: the same oracle binary with `-d 10` (`backend/driver/main.ml:362-364`, `Cerb_debug.debug_level`), whose
level-10 prints (`impl_mem.ml:1593, :1613, :1710`) render every load's and store's pointer and value through
`pp_pointer_value`/`pp_mem_value` — a symbolic provenance prints as `@iota(n)` (`:590-591`) — and the `Printf.printf
"id1= …"` arm (`:2331`) writes to stdout; one trace per file (default `--mode`), under the switch. The debug stream
goes to stderr (`util/cerb_debug.ml:36-38`); at level ≥ 3 the batch VALUE also prints its provenance
(`Specified(<@empty>:0)`) and three `EMPTY CONSTRAINTS` lines reach stdout — the verdicts were unchanged against §C.1
(checked per file), so the perturbation is cosmetic. Litmus stderr volumes were 54–89 MB per file; grep counts below are
derived from them.

**Litmus (44 files).** `@iota` appears in exactly 7 files; the other 37 (including every `_xor_`, `_bytewise`,
`repr_byte`, `roundtrip`, `union_punning` and `ptr_subtraction` file) show no symbolic provenance anywhere on the trace.
Per file (derived counts of debug lines):

```
pointer_from_int_disambiguation_1              iota lines 67: store THROUGH a symbolic pointer 1; load THROUGH one 1; symbolic value stored 1, loaded 2   → Defined (collapse to y)
pointer_from_int_disambiguation_2              iota lines 80: store THROUGH 1; load THROUGH 1; symbolic value stored 2, loaded 3                        → Defined
pointer_from_int_disambiguation_3              iota lines 26: store THROUGH 1; symbolic value stored 1, loaded 2                                         → UB046 at `r=r-1` (eff_array_shift, Single arm after the collapse)
pointer_offset_from_int_subtraction_auto_yx    iota lines 41: symbolic value stored 1; no load/store through it                                           → crash R1 (memcmp reads its bytes)
pointer_offset_from_int_subtraction_global_yx  iota lines 41: likewise                                                                                    → crash R1
provenance_basic_using_uintptr_t_auto_yx       iota lines 118: symbolic value stored 2, loaded 2; no load/store through it                               → crash R1
provenance_basic_using_uintptr_t_global_yx     iota lines 118: likewise                                                                                   → crash R1
```

Verbatim sample (`pointer_from_int_disambiguation_1`): `(debug 10): ENTERING STORE: ty=signed int* -> @(@79,
0xffffffffed98), mval= ptr((@iota(0), 0xfffffffffff8))`. `id1=` appears in NO file (0 lines over all 44 stdout+stderr
captures). So: the symbolic LOAD and STORE arms (#23, #25) and `resolve_iota` (#19) are MEASURED-reached by
`disambiguation_1/2/3`; the symbolic `eff_array_shift` arm (#31) by `disambiguation_3`; `ptrfromint`'s `DoubleAlloc →
add_iota` arm (#26) by all 7; the (B) arm (R16) by none; the kill/eq/diff/validForDeref symbolic arms show no trace
(no debug print exists for them — [AGENT]: the 7 files free nothing, compare pointers only through `memcmp` of their
bytes, and subtract no pointers, so none is reached).

**pKVM (the census units at the census worktree's CURRENT head `1de57e8f2`).** The census worktree moved under this
pass (its fix worker's re-run): the three allocator drivers now link a GENERATED TU, `@G@/page_alloc_census.c`
(`tests/census/units.txt`; produced by `tests/census/pkvm/derive_pool_init.py <case-study> <out-dir>`, GPL-2.0 text never
committed). It was derived into this worktree's scratch (114 lines) and nothing was written to the census tree. Three
runs per unit, all with the current TU set:

```
unit               default (control)                                                        PNVI_ae_udi (plain)                                        PNVI_ae_udi -d 10: loads / stores / `@iota` / `id1=`
pkvm-init          Undefined {ub: "UB088_reached_end_of_function", …, loc: "<715:2--715:17>"}   Undefined {ub: "UB088_reached_end_of_function", …, loc: "<715:2--715:17>"}   2 / 18 / 0 / 0
pkvm-alloc         Undefined {ub: "UB_CERB002b_out_of_bound_store", …, loc: "<27:2--27:21>"}   Defined {value: "Specified(61728)", stdout: "", stderr: "", blocked: "false"}   1212 / 510 / 0 / 0
pkvm-free          Undefined {ub: "UB_CERB002b_out_of_bound_store", …, loc: "<27:2--27:21>"}   Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}       2138 / 895 / 0 / 0
pkvm-split-merge   Undefined {ub: "UB_CERB002b_out_of_bound_store", …, loc: "<27:2--27:21>"}   Defined {value: "Specified(4508)", stdout: "", stderr: "", blocked: "false"}    1330 / 573 / 0 / 0
```

The three values equal §C.3's and the census's. **No `Prov_symbolic` pointer is minted, stored, loaded or dereferenced
on any pKVM trace, and the (B) line is never printed.** One difference from §C.3: with the current TU set `pkvm-init`'s
UB088 location under the switch is `<715:2--715:17>` on this trace (§C.3 measured `<715:2--715:6>` with yesterday's TU
set) — the location depends on the elaborated shape AND the trace; the lane pins whatever the oracle's EXHAUSTIVE set
shows (§D.1 row 2). Limit of the instrument: the (C) arm R6 and the (D) arms print nothing; their pKVM reach is [AGENT]
in §G.1 (every pKVM pointer load reads bytes written by whole-pointer stores — `ValidPtrProv` — and every
integer→pointer cast resolves inside the single `mem` allocation; the zero `@iota` count confirms that `find_overlaping`
never returned `DoubleAlloc` to `ptrfromint`).

## D. Validation plan

### D.1 A differential lane under the switch — `scripts/test_pnvi.sh` (new; Tier A if it stays under ~2 min, else B)

Both engines receive `--switches=PNVI_ae_udi`; the oracle's cabs-json export needs no switch (no PNVI site in the
lexer/parser, §A.7). Rows and comparison (the lanes' codec, `scripts/observations.py`, `full` projection; UB loc and
stderr are part of the token):

1. **Litmus:** the 44 `tests/pnvi_testsuite/*.c`, libc mode (they include `<stdio.h>`/`<string.h>`), oracle
   `--exec --batch --mode=exhaustive` vs Lean `--batch --libc … --libc-tu …`, pinned baseline
   `tests/pnvi_testsuite/baseline.txt` fail-closed both directions (the `test_immaculate.sh` discipline). Expected
   classes: MATCH on 40; the 4 `combine_prov` rows are REGISTERED REFUSAL ROWS `R-PNVI-01` (oracle `ORACLE_CRASH` rc
   125 vs Lean `UNSUPPORTED` refusal — §D.5; never agreement, never "both crash alike"; the 2026-10-04 text's
   `BOTH_CRASH` wording is superseded); the 6561-execution row is MATCH on the full sequence (cost noted). The
   default-elaborated libc is the same on both sides (the oracle's `libc.co`, Lean's `tests/libc/libc.core` dump) — the
   mixing of §B.0 is reproduced, not worked around.
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
- **P7 — a refusal silently turned into a mirror.** A build in which `R-PNVI-01` (`combineProv`'s symbolic arm) is
  the plain `failwithI` fail-stop again (today's text) must turn the 4 registered refusal rows RED (the lane requires
  the `UNSUPPORTED` class with the `R-PNVI-01` name, not a generic crash); and a build in which R6 (the abst hack) is
  MIRRORED as `Prov_some alloc_id1` must fail the unit pin that states the refusal (§D.4).
- **P8 — the instance gate, both directions.** An `instance : CerbGlobal.Switches` planted in a seam, in `generated/`,
  in `test/` or in `speclab/` is RED; a scratch Lake package under `.tmp/` that depends on `lean_frontend` by path and
  declares an instance is NOT scanned and the gate stays green (the consumer's own instance is the intended use,
  §B.3).

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
- **Failure-reach register:** rows 64/65/103 re-classified (reason text fixed in S1): under §G they become REFUSAL
  rows (a new reach class or the existing refusal class CerbFS's rows use), keyed by their `R-PNVI-nn` name, with the
  §C.2 crash files as witnesses; new REFUSAL rows for `R-PNVI-02…10`; the rows inside `reconstructValue` re-keyed to the
  new worker (§B.7); `--selftest` plants.
- **Unit pins for the refusals:** `test/Unit/OpaqueFailureTest.lean` gains, under `⟨[.PNVI .AE_UDI]⟩`, one pin per
  refusal that is reachable by a closed term (R1: `combineProv (.Prov_symbolic 0) .Prov_none` is the refusal, by
  `#guard_msgs`/the opaque-leaf probe shape; R6: `reconstructValuePNVI` on a `NotValidPtrProv` byte list with a closure
  returning `DoubleAlloc` is the refusal; R3/R5/R12/R13/R16 likewise on hand-built states).
- **The default-reconstruct gate** (§B.7 condition (b)): `scripts/check_default_reconstruct_unused.sh` (or a row of
  `check_exec_purity.sh`) — the old names appear in production only at their definitions; plant: a `loadM` calling the
  old name is RED.

### D.5 Registered refusal rows — how the lane and the contract record them

Each §G refusal has a NAME (`R-PNVI-01` … `R-PNVI-12`), a cite, and a contract class:

- **CONTRACT §1 outcome 2** ("a loud refusal — a nonzero exit and a message that names the unsupported feature and the
  boundary it belongs to"); **CONTRACT §3** state REFUSED for "the PNVI-ae-udi arms upstream itself leaves as crashes,
  debug prints or self-declared wrong code", with the lane rows as witnesses (**§4.1**: "every REFUSED area has at least
  one witness in a lane that pins the refusal" — R1 has four natural witnesses, §C.2; the unreachable ones have the unit
  pins above); **VALIDATION §3(c)** "missing features — loud, attributed refusals (not bugs)".
- **Lane token:** the Lean side is `UNSUPPORTED` carrying the refusal name in its message; the oracle side is whatever
  the oracle does — `ORACLE_CRASH` (rc 125) for the (A) rows, a `Defined`/`Undefined`/`Error` verdict for a (B)/(C)/(D)
  row the oracle runs through. The baseline records the PAIR with the name (`R-PNVI-01: ORACLE_CRASH / UNSUPPORTED`),
  the lane is fail-closed both directions on it, and NO such row is ever counted as agreement, MATCH, or "both crash
  alike". A Lean refusal where the baseline expects agreement is RED (a regression); an agreement where the baseline
  expects a refusal is RED too (a refusal silently turned into a mirror, P7).
- **Mechanism (proposed, §F.16):** the `CerbFS` shape — `failwithI (pnviRefusal "<R-PNVI-nn>: <site> — impl_mem.ml:<line>
  <upstream text> — <why>")` with the fixed prefix `PNVI_ae_udi refusal (unsupported upstream arm)` (`CerbFS.lean:105-108`
  is the precedent: "The one refusal message of this module"); exit 134 under `LEAN_ABORT_ON_PANIC`, which every lane
  sets; the census and the lanes already classify by the message. The alternative — a dedicated kill constructor mapped
  by `Main` to exit 2 `cerberus-lean: refused — …`, uniform with the CLI refusals — is a small mechanism change left to
  the operator (§F.16).
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
| S2 | PNVI data shapes + the `reconstructValue` wrapper | internals refactor (zero behaviour change) | `IotaEntry`, `iotaMap : TreeMap Int IotaEntry`; `findOverlapping` with the three-variant table (ascending key order argued against `IntMap.fold`); `exposeAllocation(s)`, `addIota`, `lookupIota`, `resolveIota`; `provsOfBytes`/`mergeTaint`; `mkIval`; the NEW `reconstructValuePNVI(_lemFuel)` with the switch instance, the closure and the taint result; the OLD names as default-pinned wrappers (§B.7 (a)), `loadM` moved to the new name, the default-reconstruct gate (§B.7 (b)), the legacy copy in the test module and the kernel equality `reconstructValue_lemFuel_eq_legacy` (§B.7 (c)); the indexed twin retired into the test module; the new `fuel_hypotheses.txt` row | M–L (4–6 d) | the measure proof restatement; `TreeMap.foldl` order lemma for the `Double (first, second)` pair; the fuel-forms classifier on a non-recursive `_lemFuel` wrapper (fallback in §B.7) |
| S3 | the ae-udi arms AND the §G refusals | **forced semantics change** (still CLI-refused → zero movement on every lane) | every MISSING/STOP row of §A.3 as the real arm, with impl_mem cites in the order upstream evaluates them: `ptrfromint` PNVI arm (no device check, R7 mirrored), `intfromptr` exposure + `mkIval`, load's expose-then-receipt order, the five `Prov_symbolic` arms (kill/load/store/validForDeref/eff_array_shift), `eq_ptrval` iota arm, `diff_ptrval` two iota arms, the bounds arms (R15 mirrored); **the twelve refusals `R-PNVI-01…12` of §G.1** (`pnviRefusal`, one message shape; R11 split so the `Prov_device` half keeps today's default-mode fail-stop); unit pins under `⟨[.PNVI .AE_UDI]⟩` for the arms AND for each closed-term-reachable refusal (§D.4); the failure-reach register rows | L (6–9 d) | exactness of error kinds/locations (`LoadAccess` on the store arm; the "second failure" of `resolve_iota`); hidden ordering (expose before `last_used`); keeping the refusals OUT of default mode (R9/R10/R11-device untouched, §G.3) |
| S4 | the lane, the acceptance, the docs | spec addition | `Main` accepts exactly `PNVI_ae_udi`; `check_cli_refusals.sh` (D.3, incl. `R-PNVI-11/12`); `scripts/test_pnvi.sh` + baselines with the NAMED registered refusal rows (D.5) + plants P1–P8; LADDER/VALIDATION/CONTRACT/SUPPORTED (the REFUSED row for the §G arms with its witnesses); tray drafts (R1's crash, R16's debug print, the CLI fail-open) | M (3–4 d) | the 6561-execution row's wall time; pKVM exhaustive is a resource limit on both engines (label, do not loosen); the location pinning of `pkvm-init`'s UB088 (§C.6: trace-dependent — pin the exhaustive set) |
| S5 | consumer re-pin note, PREDICTIVE (consumer statement §1.5 item 4) | spec addition | the exact signature list for option 3 (§B.5) with, line for line, the before/after text of every changed cerberus-sl site against their tree at that time — the 11 `simp only` proof lines (§B.0), the 5 `CerbGlobal.switches` → `defaultSwitches` sites, the 4 fact files' `rfl`/`simp` lines, the one instance declaration — and the SET of their declarations whose elaborated terms change (the freeze fingerprint drift); the default-instance recipe; the facts that moved from `rfl`-on-a-constant to `rfl`-at-the-instance. Method: a SCRATCH workspace of cerberus-sl (their `scripts/setup-cerberus-dep.sh` shape, under this project's scratch, their repo read-only) built against the candidate commit, their `scripts/check-freeze.sh --mode reference` run there to list the drift verbatim, each diff proposed as text | M (2–3 d) | the scratch build of their tree is a BUILD (Lean, capped) — scheduled, not a design-pass act; the drift set is MEASURED there, not predicted by reading |

Order: S0 → S1 → S2 → S3 → S4 → S5 (S2 may precede S1; S3 must follow both). Total [AGENT]: roughly 21–31 person-days
with option 3 (the 2026-10-04 estimate was 17–26; the refusals, the wrapper and the predictive S5 add ~4–5). Grind tripwire: none of these is a proof grind; the one long computation is the
6561-execution litmus row and the pKVM exhaustive breach, both measurement, both labelled.

## F. Open questions for the operator (each with a recommendation [AGENT])

**Status after [USER 2026-10-05] (§1.4):** items 1, 2, 3, 4, 8, 9, 10, 11, 12, 13 are ACCEPTED as recommended; items 5,
6, 7 are SUPERSEDED by §G (refusals, not mirrors) and kept below struck in prose for the record; items 14–16 are NEW.

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
5. **SUPERSEDED by §G R16 — [USER 2026-10-05]: a refusal.** (2026-10-04 text: the `Printf.printf "id1= …"` debug arm
   `:2331-2334` — "Lean mirrors the kill only … pins the row as a crash-class/text-class difference". Now: `R-PNVI-10`,
   REFUSE; the tray report "debug print in a semantics arm" stands; MEASURED never reached on any litmus or pKVM trace.)
6. **SUPERSEDED by §G R1 — [USER 2026-10-05]: a refusal.** (2026-10-04 text: the four `combine_prov` crashes — "both
   engines crash alike". Now: `R-PNVI-01`, REFUSE, the four litmus files are registered refusal rows `ORACLE_CRASH /
   UNSUPPORTED`, never agreement; the tray report quoting `TODO: this is improvised, need to check with P` stands.)
7. **SUPERSEDED by §G — [USER 2026-10-05]: wrong-by-upstream's-own-admission arms are refusals; question-TODOs are
   decided per site.** (2026-10-04 text: "mirror the defined arm with the comment cited in-code" for `provs_of_bytes`,
   the `abst` hack, the dropped third candidate and the device TODO. Now: the `abst` hack is (C) `R-PNVI-05` REFUSE;
   `provs_of_bytes`'s arm is shadowed by R1 and refused with it; the third candidate is (D) with a REFUSE proposal
   `R-PNVI-03`; the device TODO is (D) with a MIRROR proposal — the (D) proposals are §F.15.)
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
    option as cmdliner does ("cannot be repeated", the `--args` precedent) — recommended. ACCEPTED.
14. **NEW — the (A)/(B)/(C)-shaped sites that are ALSO on the default path (§G.3): not decided here.** The ruling is
    about the PNVI work; applying "crash → refusal" to a default-path site would move default-mode baselines (today those
    sites are mirrored fail-stops or kill-without-print, pinned by the immaculate lane as crash CLASSES). The list:
    `:2259-2261` (TODO-`failwith` on a pure shift of NULL), `:2263` (pure shift of a function pointer), `:1858`'s
    `Prov_device` half (`case_ptrval`; Z2-M-02 probe), `:1141-1144` (`Printf.printf "failed: bytes_of_int…"` then
    `assert false` — a (B)-shaped print-then-crash on the DEFAULT path), `:1716-1723` (four `Printf.printf "STORE …"`
    then `fail (MerrOther "store with an ill-typed memory value")` — (B)-shaped, today mirrored as the kill WITHOUT the
    print, the existing precedent for (B) in default mode), `:734-737` (`Printf.fprintf stderr` then the AtomicMemberof
    UB; Z2-M-17), `:1044`/`:1864` ("FIXME: This is wrong. A function pointer with the same id in different files might
    exist." — (C)-shaped on the default path, mirrored today), `:1335`, `:1572`, `:1049`, `:2284`, `:2245`, `:965`,
    `:983`/`:1122`/`:1128`/`:1162` (default-path `failwith`/`assert` mirrors). Recommendation [AGENT]: leave every one
    as it is today in THIS arc (zero default movement is the arc's invariant), and open a separate "default-path
    crash-vs-refusal" question with its own slice if the operator wants the (A)/(B)/(C) rule applied to default mode;
    `:1716` shows the project already treats a default-path (B) as kill-without-print.
15. **NEW — the five (D) proposals (§G.1):** MIRROR `:2191` ("TODO: device memory?" — a defined arm; device ranges
    are themselves an upstream hack; a refusal would add a Lean-only rule), MIRROR `:2293-2295` (the live arm IS the
    ISO answer, UB046), **MIRROR `:2308`/`:2379`** ("is it correct to use the ty as the lvalue_ty?" — every
    `PtrArrayShift` under PNVI, i.e. every pointer `+`/`-` in every pKVM driver, passes here: a refusal would stop pKVM,
    the arc's point), MIRROR `:2399` ("TODO: check" on the device-pointer shift), and REFUSE `:840-842` (the dropped
    third `find_overlaping` candidate — upstream believes it impossible; refusing never fires on a conforming run and
    is fail-closed if it does: `R-PNVI-03`). Confirm or reverse each.
16. **NEW — the refusal mechanism's shape (§D.5):** the `CerbFS` shape (`failwithI` with a fixed refusal prefix; exit
    134 under `LEAN_ABORT_ON_PANIC`; lanes classify by message) — recommended now, zero new mechanism; the alternative is
    a dedicated kill constructor that `Main` maps to exit 2 `cerberus-lean: refused — …`, uniform with the CLI refusals,
    a small later QoL slice that would also cover CerbFS.

## G. Refusal classification ([USER 2026-10-05]) — every flagged site on the PNVI-ae-udi path

### G.0 The rule applied

[USER 2026-10-05]: "Re PNVI - agree on your recs except for mirroring crashes / obviously wrong behavior. These should
be refusals surely?" Classes as relayed: **(A)** upstream crash / `failwith` / `assert` → REFUSE with a named
"unsupported" message; **(B)** debug-print-then-kill → REFUSE; **(C)** a defined arm upstream itself says is wrong →
REFUSE when reached; **(D)** a defined arm whose TODO is only uncertainty or a question → this agent's proposal (mirror
or refuse) with the reason. A site that is ALSO reached in default mode is flagged, not decided (§G.3, §F.14): the
default-mode behaviour does not change in this arc.

"Refuse" means: the Lean model stops with the §D.5 refusal message naming the row (`R-PNVI-nn`), the site and the
upstream text; the lane records the row as a registered refusal (oracle class / `UNSUPPORTED`), never as agreement;
CONTRACT §1 outcome 2, §3 REFUSED-with-witness, VALIDATION §3(c). "Mirror" means the defined arm is implemented as
upstream has it, with the comment cited in-code. Reach columns: **MEASURED** = §C.1/§C.2/§C.6 (the oracle's own
behaviour on the 44 litmus files and the 4 pKVM drivers, one trace each; exhaustive for §C.1); **[AGENT]** = reasoned
from the Core and the measured outcomes where no instrument shows the arm.

### G.1 The table

| # | Site | Upstream text (verbatim) | Class | Also default path? | Reach: litmus (44) | Reach: pKVM (4) | Disposition |
|---|---|---|---|---|---|---|---|
| R1 | `impl_mem.ml:391-394` `combine_prov` | `(* TODO: this is improvised, need to check with P *)` … `failwith "Concrete.combine_prov: found a Prov_symbolic"` | (A) | function yes; THIS ARM no (`Prov_symbolic` is never minted in default mode) | **MEASURED 4**: `pointer_offset_from_int_subtraction_{auto,global}_yx`, `provenance_basic_using_uintptr_t_{auto,global}_yx` (oracle rc 125, §C.2; via `pvi_split_bytes` on the bytes of a stored symbolic pointer read by libc's `memcmp`) | MEASURED none (0 `@iota` on every trace; all four end as §C.6) | **REFUSE `R-PNVI-01`**; the 4 files are registered refusal rows; tray report |
| R2 | `:470-471` `provs_of_bytes` | `| Prov_symbolic iota -> acc (* TODO(iota) *)` | shadowed-(A): a defined arm that can only be reached AFTER `pvi_split_bytes` (`:986`/`:999`, evaluated first) has raised R1 on the same bytes [AGENT] | no | none (every path into it is an R1 crash first) | none | **REFUSE with R1** (`R-PNVI-01b`; fail-closed, unreachable) |
| R3 | `:811` `find_overlaping` | `| Some _ -> assert false` | (A) | no (`find_overlaping` is called only under `is_PNVI`) | none (unreachable by construction: the predicate matched a non-PNVI switch) | none | **REFUSE `R-PNVI-02`** |
| R4 | `:839-842` `find_overlaping` | `| `DoubleAlloc _, Some _ -> (* TODO: I guess there is an invariant that the new_alloc is either of the `DoubleAlloc *) acc` (a third candidate is dropped) | (D) — the TODO states a believed invariant | no | none [AGENT]: a third live allocation containing-or-one-past one address needs a zero-size allocation at a boundary; none in the suite | none [AGENT]: the buddy allocator's objects are page-sized or larger | **proposed REFUSE `R-PNVI-03`** when a third candidate appears (never fires on a conforming run; fail-closed) — §F.15 |
| R5 | `:914` `lookup_iota` | `IntMap.find iota st.iota_map` (raises `Not_found`) | (A) | no | none [AGENT]: every `Prov_symbolic` is minted by `add_iota`, which inserts the key | none | **REFUSE `R-PNVI-04`** |
| R6 | `:1079-1082` `abst`, pointer arm, `NotValidPtrProv`, `DoubleAlloc` | `(* FIXME/HACK(VICTOR): This is wrong, but when serialising the memory in the UI, I get this failwith. *)` `Prov_some alloc_id1` `(* failwith "TODO(iota): abst => make a iota?" *)` | **(C)** — upstream says "This is wrong" | **no** — inside `if is_PNVI () then` (`:1057`) | none [AGENT]: needs a pointer load whose bytes are NOT a whole-pointer copy (`NotValidPtrProv`) at an address with two live exposed candidates; the byte-wise copy tests (`pointer_copy_user_*_bytewise`, `provenance_tag_bits_via_repr_byte_1`) reconstruct an address strictly inside ONE exposed object (MEASURED: Defined with the expected values; 0 `@iota`) | none [AGENT]: every pKVM pointer load reads bytes written by whole-pointer stores (`ValidPtrProv`); integer→pointer casts go through `ptrfromint`, not `abst`; MEASURED 0 `@iota` | **REFUSE when reached `R-PNVI-05`**; unit pin on a hand-built byte list |
| R7 | `:2191` `ptrfromint`, PNVI arm | `(* TODO: device memory? *)` (no `device_ranges` check under PNVI) | (D) — a question about a feature upstream does not model under PNVI | no (the PNVI arm) | none (no device address in any litmus file; MEASURED grep for `0xABC`/`0x40000000`) | none (every cast resolves inside `mem`) | **proposed MIRROR** (a defined, total arm; refusing would add a Lean-only rule; device ranges are themselves "TODO: this is stupid", `:653-659`) — §F.15 |
| R8 | `:2255` `array_shift_ptrval` (PURE) | `| Prov_symbolic iota -> failwith "Concrete.array_shift_ptrval found a Prov_symbolic"` | (A) | function yes; THIS ARM no | none [AGENT]: pure shifts under PNVI come only from the default-elaborated libc (`libc.core`, 685 sites), `formatted.lem:391/:419` (`%s`), `core_eval.lem:752`; no litmus passes a symbolic pointer BY POINTER into libc (`memcmp` gets `&p`) and none prints `%s` of one; MEASURED: the 7 iota files crash at R1 or end Defined/UB046, never here | none (`--nolibc`; `std.core`'s four `array_shift` lines are comments, MEASURED) | **REFUSE `R-PNVI-06`** |
| R9 | `:2259-2261` `array_shift_ptrval`, `PVnull` | `(* TODO: this seems to be undefined in ISO C *)` … `failwith ("TODO(pure shift a null pointer should be undefined behaviour), offset:" ^ …)` | (A)-shaped TODO-`failwith` | **YES** — the pure `array_shift` of NULL in default mode (Lean mirrors it as a fail-stop today) | none under PNVI (user code emits no pure shift) | none | **NOT DECIDED HERE** — §G.3 / §F.14 |
| R10 | `:2263` `array_shift_ptrval`, `PVfunction` | `failwith "Concrete.array_shift_ptrval, PVfunction"` | (A)-shaped | **YES** (default path) | none | none | **NOT DECIDED HERE** — §G.3 / §F.14 |
| R11 | `:1858` `case_ptrval` | `| _ -> failwith "case_ptrval"` — ONE wildcard for `Prov_symbolic` AND `Prov_device` concrete pointers | (A) for the `Prov_symbolic` half | the `Prov_device` half **YES** (Z2-M-02: `tests/z2-probes/mem/device_funptr_call.c` reaches it in default mode) | none [AGENT]: reached only by a CALL through a pointer value (`core_run.lem:1010`, `core_reduction.lem:1408`, `core_eval.lem:920`); no litmus calls through a symbolic pointer | none | **SPLIT**: `Prov_symbolic` → **REFUSE `R-PNVI-07`**; `Prov_device` → unchanged today, §G.3 |
| R12 | `:2104` `diff_ptrval`, `(symbolic, symbolic)`, `Double ∩ Double` with `addr1 ≠ addr2` | `fail ~loc (MerrOther "in `diff_ptrval` invariant of PNVI-ae-udi failed: ambiguous iotas with addr1 <> addr2")` | (A′) — upstream's own "invariant failed", surfaced as an `Error` verdict rather than a crash | no | none [AGENT]: needs two Double iotas over the same two allocations at different addresses and their subtraction; the `ptr_subtraction` files mint no iota (MEASURED) | none | **REFUSE `R-PNVI-08`** (an invariant failure is not a verdict about the program) |
| R13 | `:2298` `eff_array_shift_ptrval`, `PVfunction` | `failwith "Concrete.eff_array_shift_ptrval, PVfunction"` | (A) | no (`PtrArrayShift` is not emitted in default mode) | none [AGENT]: function-pointer arithmetic | none | **REFUSE `R-PNVI-09`** |
| R14 | `:2293-2296` `eff_array_shift_ptrval`, `PVnull` | `(* TODO: this seems to be undefined in ISO C *)` `(* failwith (… "TODO(eff shift a null pointer …") *)` (commented out) → live `fail ~loc MerrArrayShift` | (D) — the live arm IS the ISO answer (UB046) | no | none | none | **proposed MIRROR** — §F.15 |
| R15 | `:2308` (symbolic arm) and `:2379` (`Prov_some` arm) `eff_array_shift_ptrval` | `(* TODO: is it correct to use the "ty" as the lvalue_ty? *)` — the bounds check `base ≤ shifted ∧ shifted + sizeof ty ≤ base + size + sizeof ty` | (D) — a modelling-fidelity doubt about a defined check | no | **MEASURED: every file with pointer arithmetic**; its UB046 branch is taken by `cheri_03_ii` and `pointer_from_int_disambiguation_3` | **MEASURED: all three allocator drivers** — every `p + n` under PNVI is a `PtrArrayShift` through this check (1212/2138/1330 loads' addresses come from it) | **proposed MIRROR** — **a refusal here would stop pKVM** — §F.15 |
| R16 | `:2331-2334` `eff_array_shift_ptrval`, `Double`, `ival ≠ 0`, both preconditions true, not PERMISSIVE | `Printf.printf "id1= %s, id2= %s ==> addr= %s\n" …; fail ~loc (MerrOther "(PNVI-ae-uid) ambiguous non-zero array shift")` | **(B)** | no | **MEASURED none** (0 `id1=` lines over 44 files) | **MEASURED none** (0 lines) | **REFUSE `R-PNVI-10`**; tray report ("debug print in a semantics arm") |
| R17 | `:2398-2400` `eff_array_shift_ptrval`, `Prov_device` | `(* TODO: check *)` → shift freely | (D) | no | none (no device pointers) | none | **proposed MIRROR** — §F.15 |
| R18 | `:1787` `store`, symbolic arm, atomic member | `return (`FAIL (loc, MerrAccess (LoadAccess, AtomicMemberof)))` — a `LoadAccess` tag on a STORE (no comment) | not a flagged class — the same quirk as the default `Prov_some` arm `:1818`, already mirrored | the quirk itself YES (`:1818`) | none | none | MIRROR (consistency with the default arm); listed for completeness |
| R19 | `:795`, `:1542-1544`, `:1663-1665`, `:1772-1774`, `:2303-2305`, `:2323`, `:2356` | `(* TODO: maybe move somewhere else *)`, `(* TODO: this is duplicated code from the Prov_some case … *)`, `(* TODO: this is yucky *)` | code-organisation comments on defined arms — not semantic | — | — | — | no class; mirror the arms |
| R20 | `ocaml_frontend/switches.ml:139`, `:141` | `"switch '…' would override a previous switch --> ignoring."`, `"failed to parse switch '…' --> ignoring."` (the run proceeds) | CLI fail-open — (A)-like (a silent absorption) | the CLI, both modes | n/a (MEASURED §C.5: the oracle runs the default semantics) | n/a | **REFUSE `R-PNVI-11`** (override) **and `R-PNVI-12`** (unknown name) — accepted §F.4 |

Counts (derived): **(A) 6** (R1, R3, R5, R8, R11-symbolic, R13) + **(A′) 1** (R12) + **shadowed 1** (R2) → 8 refusals;
**(B) 1** (R16) → 1 refusal; **(C) 1** (R6) → 1 refusal; **(D) 5** (R4, R7, R14, R15, R17) → 1 proposed refusal (R4),
4 proposed mirrors; **CLI 2** (R20) → 2 refusals; **also-default, not decided: 2 + 1 half** (R9, R10, R11-device); **not
a class: 2** (R18, R19). Named refusals: `R-PNVI-01…12` (twelve, with `01b` folded into `01`).

### G.2 Reach summary and how each pKVM driver ends

- **Litmus (44, MEASURED):** the only refusal any file reaches is **R1** (4 files; the oracle crashes there). The 7
  iota-minting files otherwise run the symbolic LOAD/STORE/`resolve_iota`/`eff_array_shift` arms, all of which are
  MIRRORED arms (not refusals). Under the refusal regime the lane's expected state is: 40 MATCH + 4 registered refusal
  rows `R-PNVI-01: ORACLE_CRASH / UNSUPPORTED`.
- **pKVM (MEASURED on the current census TU set, §C.6):** `pkvm_alloc` → `Defined {value: "Specified(61728)", …}`;
  `pkvm_free` → `Defined {value: "Specified(0)", …}`; `pkvm_split_merge` → `Defined {value: "Specified(4508)", …}`;
  `pkvm_init` → `Undefined {ub: "UB088_reached_end_of_function", …}` (the program's own `get_order` stub, as in default
  mode). Zero `Prov_symbolic` pointers are minted on any trace, no `id1=` line is printed, no refusal (A)/(B)/(C) is
  reached, and the only PNVI-path TODO every driver passes through is the (D) site R15, proposed MIRROR. **No refusal
  in §G.1 stops a pKVM driver.** The one way to break pKVM from this table is to REFUSE R15 — flagged in §F.15.
- **Caveat on traces:** both corpora were measured one trace per program (the litmus set also exhaustively in §C.1,
  with the same verdicts); pKVM's exhaustive set under the switch breaches the 4G cap on the oracle (§C.3), so a
  refusal on an unexplored pKVM trace cannot be excluded by measurement — [AGENT]: none is expected, since minting an
  iota needs a one-past cast at an exposed boundary that the allocator's range check (`addr >= range_end → NULL`)
  prevents on every trace, not just the explored one.

### G.3 Flagged sites ALSO on the default path — operator questions, NOT decided here (§F.14)

| Site | Text | Shape | Today (default mode) |
|---|---|---|---|
| `:2259-2261` | `failwith ("TODO(pure shift a null pointer should be undefined behaviour), offset:" …)` | (A) TODO-`failwith` | mirrored fail-stop (`arrayShiftPtrval`) |
| `:2263` | `failwith "Concrete.array_shift_ptrval, PVfunction"` | (A) | mirrored fail-stop |
| `:1858` (`Prov_device` half) | `failwith "case_ptrval"` | (A) | mirrored fail-stop (`casePtrval`; Z2-M-02 probe) |
| `:1141-1144` | `Printf.printf "failed: bytes_of_int(%s), i= %s, nbits= %d, [%s ... %s]\n" …; assert false` | (B) print-then-crash | mirrored as a fail-stop (`intToBytes` assert mirror) |
| `:1716-1723` | `Printf.printf "STORE ty …" …` ×4 then `fail ~loc (MerrOther "store with an ill-typed memory value")` | (B) print-then-kill | mirrored as the KILL without the print (`storeM`: "OCaml's diagnostic printfs … are not mirrored, the failure is") — the project's existing treatment of a default-path (B) |
| `:734-737` | `Printf.fprintf stderr "addr: %s <--> alloc.base: %s\n" …` then `return true` (AtomicMemberof UB) | (B)-shaped print-then-UB | UB mirrored, print not (Z2-M-17) |
| `:1044` / `:1864` | `(* FIXME: This is wrong. A function pointer with the same id in different files might exist. *)` | (C) | mirrored defined arm (`reconstructValue` / `caseFunsymOpt`, with the FIXME cited) |
| `:1049`, `:1335`, `:1572`, `:2245`, `:2284`, `:965`, `:983`, `:1122`, `:1128`, `:1162` | `failwith "unknown function pointer: …"`, `failwith "TODO: cerb::with_address() is yet implemented"`, `failwith "Concrete: FREE was called on a dead allocation"`, `failwith "Concrete.offsetof_ival: invalid memb_ident"`, `failwith "Concrete.member_shift_ptrval, PVfunction"`, `failwith "abst, |bs| < sizeof(ty)"`, `assert false` ×4 | (A) | mirrored fail-stops (several with reachability notes in `CerbMem.lean`) |
| `:2209`, `:1515`, `:1041`/`:1053`, `:1619`, `:2110`, `:2277`, `:2482` | `(* TODO: check (… device pointers …) *)`, `(* TODO: should that be an error ?? *)`, `(* TODO: check *)`, `(* TODO: might be nicer … *)`, `(* TODO: catch builtin function types *)`, `(* TODO: unsure, this might just be undefined … *)`, `(* TODO: conversion? *)` | (D)-shaped questions on default arms | mirrored defined arms |

Recommendation [AGENT] (§F.14): unchanged in this arc; a separate decision if the operator wants the §G rule applied to
default mode. S3 keeps every row above exactly as it is today and its zero-default-movement gate proves it.

### G.4 Flagged comments on the shared path that the switch does not change

`:307` ("TODO: hack hack hack ==> OCaml's float are 64bits"), `:406`, `:557`, `:574`, `:606`, `:622`, `:1032`/`:1095`
(level-1 debug prints with TODO text, no kill), `:1098`/`:1101`/`:1178`/`:1251` (`Z.to_int` overflow TODOs), `:1106`,
`:1164`, `:1189`, `:1204`, `:1234`, `:1241`, `:1281`, `:1310`, `:1374`, `:1418`, `:1468`, `:1485`/`:1497`/`:1111` (zap,
a refused switch), `:1938`/`:1956`/`:1972`/`:1989` ("TODO: one past case", the strict relationals — a refused switch),
`:2173` (`Cerb_debug.warn "implementation defined cast from integer to pointer"` — a warning, not a kill; both modes).
Out of this ruling's scope; listed so the table is complete.

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

Reach probe (2026-10-05, §C.6), same binary and capping:

```
main.exe --runtime=_build/install/default -d 10 --exec --batch --switches=PNVI_ae_udi tests/pnvi_testsuite/<f>.c      (stderr: grep -c 'iota', 'ENTERING LOAD'/'EXITING LOAD'/'ENTERING STORE'; stdout+stderr: grep -c 'id1=')
python3 tests/census/pkvm/derive_pool_init.py <case-study> <own-scratch-dir>                                            (→ <own-scratch-dir>/page_alloc_census.c; nothing written to the census tree)
main.exe --runtime=_build/install/default [-d 10] --nolibc --exec --batch [--switches=PNVI_ae_udi] --nostdinc -I <case-study> -I tests/census/pkvm tests/census/pkvm/<d>.c <own-scratch-dir>/page_alloc_census.c   (pkvm_init links <case-study>/page_alloc.c instead, per units.txt)
```

The §G flagged-site list comes from `awk 'NR>=277 && NR<=2830' memory/concrete/impl_mem.ml | grep -n -E 'FIXME|HACK|TODO|assert false|failwith|Printf\.printf|print_endline|prerr_endline|Cerb_debug\.warn|print_debug'`
(line numbers re-based), read against the function bodies quoted in §A.

## H. Operator rulings on §F.14–§F.16 (2026-10-05)

Asked by the orchestrator with the reasoning given in chat (the four-class line: refuse where upstream
silently does something it is unsure of, mirror where the arm is defined and the TODO is a question).
Verbatim [USER 2026-10-05]: "1 - agree. 2 - I think in the end we should make this consistent, but it's
fairly minor. 3 - if we do (b) it should be a global policy. I don't think it necessarily needs to be a
refusal, but it shouldn't be an uncontrolled crash. And for now (a) is fine"

- **§F.15 (the (D) sites): accepted.** MIRROR `:2191`, `:2293`, `:2308`/`:2379`, `:2399`; REFUSE `:840-842`
  (the silently dropped third `find_overlaping` candidate becomes a loud check).
- **§F.14 (the (A)/(B)/(C)-shaped sites also on the default path): unchanged in this arc**, default mode
  stays bit-identical. The operator's direction is that this should EVENTUALLY be made consistent ("fairly
  minor") — queued as a separate small review after the PNVI arc, listing every default-path crash /
  "this is wrong" arm and its proposed treatment; it moves the consumer only by its own recorded re-pin.
- **§F.16 (refusal shape): (a) for this arc** — the `CerbFS` `failwithI`-with-`refused — ` prefix shape.
  Option (b), a dedicated controlled outcome, would be a GLOBAL policy over every such stop (CerbFS, PNVI,
  asm, …), not a PNVI-local mechanism; per the operator it need not be a "refusal" as such, but it must
  not be an uncontrolled crash. Queued as its own design question, to be agreed with cerberus-sl (whose
  adequacy statements name the run outcomes).

### H.1 Addendum (2026-10-07): R-PNVI-09 reclassified as a default-path look-alike [AGENT]

The S3 worker stopped on §G R13 / R-PNVI-09 (`eff_array_shift_ptrval`'s `PVfunction` arm,
`impl_mem.ml:2296-2297`, `failwith "Concrete.eff_array_shift_ptrval, PVfunction"`): §G called it
PNVI-path only, but it is on the DEFAULT path (std.core:188/196/212/217 emit `PtrArrayShift` in default
mode; reachability from C unmeasured — the one route tried stops earlier on the oracle). It is therefore a
§F.14 default-path look-alike, and the operator's §H ruling 2 already covers that category verbatim —
"2 - I think in the end we should make this consistent, but it's fairly minor" — with the agreed
treatment "unchanged in this arc". Applied by the orchestrator: the arm stays EXACTLY as it is (the
existing mirror), and it joins the queued default-path consistency review. No new semantics decided.
