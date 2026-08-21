/-
  RelSem.Kit.Mem — arc-9 S2 (2026-08-20): L1 kit, the memory-op block
  layer at MemState level (design docs/2026-08-20_arc9-s1-design.md
  §1.2 Kit/Mem; gap G4; brick-B1/B3 shapes).

  Generalized from the T1/T3/T4 fixture lemmas (allocErr_eq /
  storeErr_eq / loadX_eq / createS / storeU / loadV classes): each
  block is COMPUTED-RHS with the brick-B3 named-hypothesis convention
  — every `h*` is a small closed fact the fixture discharges by
  `rfl`/`decide` (or, over recursive iteration families, by the
  fixture's induction lemmas). The success paths only (the slate's
  value routes); the UB paths stay per-fixture (T2 pattern).

  Import discipline (design §6): no Iris, no fixtures.

  House rules: no sorry, no axioms declared here. Pins in Kit/Audit.
-/

import RelSem.Machine
import RelSem.Cerberus
import RelSem.Tactics.AppEqAttr

set_option autoImplicit false

namespace RelSem.Kit

open RelSem

/-- ALLOCATE (create), fresh-object success path: the address is
    computed from the pre-state (hypothesis-pinned so fixtures
    discharge the arithmetic by `decide`); the post-state appends the
    allocation and writes `sz` uninitialized bytes. -/
@[app_eq]
theorem mem_alloc_block {tid : Nat} {pref : prefix0} {pv : CerbMem.Provenance}
    {alignN : Int} {ty : ctype} {mem : CerbMem.MemState}
    {addrOpt : Option Int} {sz : Nat} {a : Int}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (mem.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = a)
    (hnz : (a == (0 : Int)) = false) :
    app (CerbMem.allocateObject tid pref (.IV pv alignN) ty addrOpt none) mem
      = (NDactive (.PV (.Prov_some mem.nextAllocId) (.PVconcrete none a)),
         CerbMem.writeBytesTo
           { mem with
             nextAllocId := mem.nextAllocId + 1,
             lastAddress := a,
             allocations := mem.allocations.insert mem.nextAllocId
               { base := a, size := sz, ty := some ty, prefix_ := pref } }
           a (List.replicate sz
               { prov := .Prov_none, copyOffset := none, value := none })) := by
  -- arc-9 S4 rebase note (2026-08-21): arc-10 finding-11 gave
  -- allocateObject a real readonly status (impl_mem.ml:1304-1333
  -- mirror). At this block's `initOpt = none` it reduces to
  -- `.IsWritable` = the structure default, so the STATED post-state is
  -- unchanged — the proof just reduces the new call.
  simp only [CerbMem.allocateObject, app, hsz, haddr, hnz,
    CerbMem.readonlyStatusForAlloc_none,
    Bool.false_eq_true, if_false, reduceIte]

/-- STORE, success path (positive/negative alike — the polarity lives
    at the driver layer): non-union concrete pointer, writable
    allocation, compatible value; the post-state is the byte write
    with the funptrmap threaded (integers: unchanged). -/
@[app_eq]
theorem mem_store_block {loc : CerbLocation.Loc} {ty : ctype}
    {allocId : Int} {addr : Int} {alloc : CerbMem.Allocation}
    {mem : CerbMem.MemState} {mv : CerbMem.MemValue}
    {fpm : CerbMem.Funptrmap} {bytes : List CerbMem.AbsByte}
    (hcompat : CerbMem.ctypeMemCompatible ty (CerbMem.typeofMval mv) = true)
    (hget : mem.allocations.get? allocId = some alloc)
    (hbounds : CerbMem.isInBounds alloc addr (CerbMem.sizeofCtype ty) = true)
    (hro : alloc.isReadonly = .IsWritable)
    (hatomic : CerbMem.isAtomicMemberAccess alloc ty addr = false)
    (hbytes : CerbMem.memValueToBytes mem.funptrmap mv = (fpm, bytes)) :
    app (CerbMem.storeM loc ty false
          (.PV (.Prov_some allocId) (.PVconcrete none addr)) mv) mem
      = (NDactive (.FP .W addr (CerbMem.sizeofCtype ty)),
         CerbMem.writeBytesTo { mem with funptrmap := fpm } addr bytes) := by
  simp only [CerbMem.storeM, app, hcompat, hget, hbounds, hro, hatomic,
    hbytes, Bool.not_true, Bool.false_eq_true, if_false, if_true,
    reduceIte, Bool.not_false]

/-- Is a ctype the `_Bool` type (the load trap-representation
    discriminator)? -/
def isBoolTy : ctype → Bool
  | Ctype _ (Basic (Integer Bool0)) => true
  | _ => false

/-- LOAD, success path: non-Bool type (no trap-representation branch),
    live allocation, in bounds; state unchanged. -/
@[app_eq]
theorem mem_load_block {loc : CerbLocation.Loc} {ty : ctype}
    {allocId : Int} {addr : Int} {um : Option identifier}
    {alloc : CerbMem.Allocation} {mem : CerbMem.MemState}
    {bytes : List CerbMem.AbsByte} {mv : CerbMem.MemValue}
    (hdead : mem.deadAllocations.contains allocId = false)
    (hget : mem.allocations.get? allocId = some alloc)
    (hbounds : CerbMem.isInBounds alloc addr (CerbMem.sizeofCtype ty) = true)
    (hatomic : CerbMem.isAtomicMemberAccess alloc ty addr = false)
    (hbytes : CerbMem.readBytesFrom mem addr (CerbMem.sizeofCtype ty) = bytes)
    (hrecon : CerbMem.reconstructValue mem.lastUsedUnionMembers
        mem.funptrmap addr ty bytes = mv)
    (hnotbool : isBoolTy ty = false) :
    app (CerbMem.loadM loc ty
          (.PV (.Prov_some allocId) (.PVconcrete um addr))) mem
      = (NDactive (.FP .R addr (CerbMem.sizeofCtype ty), mv), mem) := by
  simp only [CerbMem.loadM, app, hdead, hget, hbounds, hatomic, hbytes,
    hrecon, Bool.not_true, Bool.false_eq_true, if_false,
    if_true, reduceIte, Bool.not_false, Bool.false_and]
  exact if_neg (fun hx => Bool.noConfusion
    (hnotbool.symm.trans ((Bool.and_eq_true _ _).mp hx).1))

/-- Pointer prefix (a placeholder in the concrete model: always
    `none`; the trace events' pref field). -/
@[app_eq]
theorem mem_prefix_block {ptr : CerbMem.PointerValue}
    {mem : CerbMem.MemState} :
    app (CerbMem.prefixOfPointer ptr) mem = (NDactive none, mem) := rfl

/-- KILL (object deallocation), success path: live allocation, at the
    base address, non-dynamic. -/
@[app_eq]
theorem mem_kill_block {loc : CerbLocation.Loc}
    {allocId : Int} {addr : Int} {um : Option identifier}
    {alloc : CerbMem.Allocation} {mem : CerbMem.MemState}
    (hdead : mem.deadAllocations.contains allocId = false)
    (hget : mem.allocations.get? allocId = some alloc)
    (hbase : (addr != alloc.base) = false) :
    app (CerbMem.killM loc false
          (.PV (.Prov_some allocId) (.PVconcrete um addr))) mem
      = (NDactive (),
         { mem with
           deadAllocations := allocId :: mem.deadAllocations,
           allocations := mem.allocations.erase allocId }) := by
  simp only [CerbMem.killM, app, hdead, hget, hbase, Bool.not_true,
    Bool.false_eq_true, if_false, if_true, reduceIte, Bool.not_false,
    Bool.false_and, Bool.and_false]

end RelSem.Kit
