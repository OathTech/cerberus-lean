# MEMORY-SCALE arc — consumer change manifest for refined-cerberus (S1)

Date: 2026-09-02. Branch `arc/mem-scale`. Charter
`2026-09-01_mem-scale-design.md` §5.4 ("Change manifest for
refined-cerberus … delivered before the merge ask") and §6.2. Consumer:
`refined-cerberus` (`cerberus-heaplang/CerberusHeapLang/*.lean`), which
builds against a PINNED semantics workspace (`.cerberus-ws`,
`scripts/semantics-pin.env` → `CERBERUS_LEAN_COMMIT=58ec50779`).

## 1. What S1 changes in `lean_frontend/CerbMem.lean`

| Symbol | Change | Consumer impact |
|---|---|---|
| `CerbMem.reconstructValue_lemFuel` | ARRAY arm only: one linear `chunksOf` pass instead of per-index `drop (i*e) |>.take e`. Every other arm textually unchanged. | `unfold` sites hit pointer/struct arms → unchanged text; see §3 |
| `CerbMem.reconstructValue` | unchanged wrapper (`rfl`-defeq to the worker at `lemDefaultFuel`) | none |
| `CerbMem.chunksOf` (NEW) + `chunksOf_eq_range_map` (NEW theorem) | the linear chunking helper and its index-slice characterisation | none (new names) |
| `CerbMem.reconstructValue_indexed_lemFuel` (NEW) | the pre-C1 text, kept as the reference form (not executed) | none |
| `CerbMem.reconstructValue_lemFuel_eq_indexed`, `reconstructValue_eq_indexed` (NEW theorems) | live = reference at every fuel / at `lemDefaultFuel` | available to consumers that want the index-slice view |
| `CerbMem.memValueToBytes_lemFuel` | STRUCT arm only: reversed-chunk accumulation + one `flatten` instead of `accBs ++ pad ++ bs` in the left fold. Every other arm textually unchanged. | consumer uses are on scalar values (`sevenMval`, `longMval`) and go through `.2`/`.length` lemmas → the struct arm is not reached; see §3 |
| `CerbMem.memValueToBytes` | unchanged wrapper | none |
| `CerbMem.memValueToBytes_append_lemFuel` (NEW) | the pre-C3 text, kept as the reference form (not executed) | none |
| `CerbMem.foldl_append_eq_flatten_reverse{,_aux}`, `memValueToBytes_lemFuel_eq_append`, `memValueToBytes_eq_append` (NEW theorems) | live = reference | available |

NOT changed by this arc (charter §1 invariant): `MemState`, `AbsByte`,
`PointerValue`, `MemValue`, `readBytesFrom`, `writeBytesTo`, `storeM`,
`loadM`, `allocateObject`, `allocateRegion`, `killM`, `memcpyM`,
`memcmpM`, `reallocM`, pointer ops, varargs — no text change anywhere
in these.

## 2. Every consumer site the charter §5.4 names (re-verified 2026-09-02 against refined-cerberus @ `e9bcaef`)

| Consumer file:line | What it does | S1 effect |
|---|---|---|
| `cerberus-heaplang/CerberusHeapLang/Exhibit.lean:121` | `unfold CerbMem.readBytesFrom` | none (untouched) |
| `ProdExhibit.lean:86` | `unfold CerbMem.readBytesFrom` | none |
| `ProdEntry.lean:168` | `unfold CerbMem.readBytesFrom` | none |
| `ProdLoopExhibit.lean:428` | `unfold CerbMem.readBytesFrom` | none |
| `Heap.lean:377` | `unfold CerbMem.readBytesFrom` | none |
| `Heap.lean:324` | `unfold CerbMem.storeM` | none (untouched) |
| `TreeRotExhibit.lean:145-149` | `rw [show reconstructValue = reconstructValue_lemFuel lemDefaultFuel from rfl, show lemDefaultFuel = 999999 + 1 from rfl]; unfold CerbMem.reconstructValue_lemFuel treePtrTy treeTy; dsimp only; rw [hb] …` on a POINTER-typed node | arm hit = Pointer, text unchanged; the same tactic prefix re-run on the S1 body in this tree elaborates (§3) |
| `ListRevExhibit.lean:257-261` | same shape at `nodePtrTy` | same |
| `TreeRotExhibit.lean:84-85, 131-133`, `ListRevExhibit.lean:300-301`, `StructExhibit.lean:54-55` | `reconstructValue … = reconstructValue [] [] … := rfl`; null round trip `:= rfl` | pointer/struct arms; `rfl` at `lemDefaultFuel` unchanged in kind (the array arm is never reduced on these types) |
| `ProdExhibit.lean:103,153`, `Heap.lean:122-134` (and by-name uses elsewhere) | `CerbMem.memValueToBytes` on scalar values via `.2`/`.length` lemmas | struct arm not reached; name and wrapper unchanged |
| `Exhibit.lean:40,43`, `ProdEntry.lean:142,155`, `ProdExhibit.lean:47-64`, `ProdLoopExhibit.lean:370-387` | `CerbMem.allocateObject` by name | none (untouched) |
| `ArrayExhibit.lean:429,448,662`, `Wps.lean:1740,1962`, `Wpt.lean:1312,1524`, `Heap.lean:82,133,269,340,427,596,769,819,1254`, `ListRevExhibit.lean:232,253,322,371,377,1653`, `TreeRotExhibit.lean:175,721,772` | `CerbMem.reconstructValue` on int/long/pointer-typed cells (`intTy`, `longTy`, `nodePtrTy`, …) — never on an array type | the array arm is not selected on any of these types; equalities stated over the wrapper are unaffected |

## 3. Verification status of the two `unfold` sites — and the pre-existing pin delta

- refined-cerberus is NOT buildable against this worktree here: it
  builds against the pinned workspace clone `.cerberus-ws` @
  `58ec50779` (its own iris-lean/batteries pins; a primed 789 MB
  `.lake`). Re-pointing that pin at `arc/mem-scale` is the consumer's
  pin dance (their `scripts/setup-cerberus-dep.sh` + re-gate), not this
  arc's business, and swapping files inside their primed clone would
  doctor their instrument.
- PRE-EXISTING DELTA, found while re-verifying (not caused by this
  arc): the consumer's pin predates the effect-retirement arc's
  `ambient : TagDefs` parameter — the pinned `CerbMem.reconstructValue`
  takes 5 arguments (`lum fpm addr ty bytes`), the current one takes 6
  (`ambient` first; likewise `memValueToBytes ambient funptrmap val`).
  So EVERY reconstructValue/memValueToBytes call site listed in §2
  needs the extra argument at the next pin bump regardless of S1. S1
  adds no further signature change.
- What WAS verified in this tree (record §S1, "consumer-shape probe"):
  the consumer's exact tactic prefix — `rw [show … from rfl, show
  lemDefaultFuel = 999999 + 1 from rfl]; unfold
  CerbMem.reconstructValue_lemFuel <ptrTy> <ty>; dsimp only; rw [hb];
  rcases … splitBytesProv …; split …` — on a pointer-typed node against
  the S1 body elaborates, and the null round trip closes by `rfl`, as
  the consumer states them. The array arm's text is not reachable from
  a pointer- or struct-typed unfold once `dsimp only` selects the arm.

## 4. What the consumer should do at its next pin bump

1. Add the `ambient : TagDefs` argument at every `reconstructValue` /
   `memValueToBytes` call (pre-existing delta, §3).
2. Nothing further for S1: the two `unfold` sites and every by-name
   use are unaffected in kind; if a proof does depend on the array
   arm's text (none found), `CerbMem.reconstructValue_lemFuel_eq_indexed`
   restores the index-slice view as a rewrite.
