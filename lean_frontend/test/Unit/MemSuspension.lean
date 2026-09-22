import CerbMemSuspension
import CerbNDFuelProofs

private def pointer (owner address : Int) : CerbMem.PointerValue :=
  .PV (.Prov_some owner) (.PVconcrete none address)
private def base (top : Int) : CerbMem.MemState :=
  { lastAddress := top,
    allocations := ((Std.TreeMap.empty : Std.TreeMap Int CerbMem.Allocation).insert
      20 {base := 200, size := 2}).insert 30 {base := 300, size := 2},
    bytemap := ([ (200,7), (201,9), (300,0), (301,0) ] : List (Int × UInt8)).foldl
      (fun bytes (address,value) => bytes.insert address {value := some value}) Std.TreeMap.empty }
private def byteAt (s : CerbMem.MemState) (address : Int) : Option UInt8 :=
  (s.bytemap.get? address).bind (·.value)
private def observed (s : CerbMem.MemState) := s.observations.getD []

private def controls (fuel : Nat) (top : Int) : List (String × Bool) :=
  letI := LemFuel.mk fuel
  Id.run do
    let tags : CerbTags.TagDefsMap := default
    let loc := CerbLocation.other "memory suspension control"
    let .some observing := CerbMem.beginObserving (base top) | return [("observer setup",false)]
    let .some enabled := CerbMem.setSuspending true observing | return [("suspension setup",false)]
    let copy := CerbMem.memcpyM tags loc (pointer 30 300) (pointer 20 200) (CerbMem.integerIval 2)
    let ordinary := CerbMemSuspension.node copy observing
    let phase1 := CerbMemSuspension.node copy enabled
    let NDsuspend continue1 := phase1.1 | return [("copy exposes its first pause", false)]
    let .some external := CerbMem.setSuspending false phase1.2 | return [("external mode setup",false)]
    let store := fun ptr n => CerbMem.storeM tags loc unsigned_char false ptr
      (.MVinteger (Unsigned Ichar) (CerbMem.integerIval n))
    let externalWrites := CerbMemSuspension.node (nd_bind (store (pointer 20 200) 21)
      (fun _ => store (pointer 20 201) 22)) external
    let NDactive _ := externalWrites.1 | return [("intervening checked stores",false)]
    let .some resumed1 := CerbMem.setSuspending true externalWrites.2 | return [("first resume mode",false)]
    let phase2 := CerbMemSuspension.node continue1 resumed1
    let NDsuspend continue2 := phase2.1 | return [("copy pauses before its second read",false)]
    let .some resumed2 := CerbMem.setSuspending true phase2.2 | return [("second resume mode",false)]
    let phase3 := CerbMemSuspension.node continue2 resumed2
    let NDsuspend continue3 := phase3.1 | return [("copy pauses before its second write",false)]
    let .some resumed3 := CerbMem.setSuspending true phase3.2 | return [("third resume mode",false)]
    let finished := CerbMemSuspension.node continue3 resumed3
    let .some killReady := CerbMem.setSuspending false phase3.2 | return [("lifetime control mode",false)]
    let killed := CerbMemSuspension.node (CerbMem.killM loc false (pointer 30 300)) killReady
    let NDactive () := killed.1 | return [("intervening lifetime end",false)]
    let directFailure := CerbMemSuspension.node (store (pointer 30 301) 22) killed.2
    let .some resumeDead := CerbMem.setSuspending true killed.2 | return [("dead storage resume mode",false)]
    let lifetimeFailure := CerbMemSuspension.node continue3 resumeDead
    let started := CerbMemSuspension.node (CerbMem.vaStart [(unsigned_char,pointer 20 200)]) enabled
    let NDactive va := started.1 | return [("varargs setup",false)]
    let .some vaReady := CerbMem.setSuspending true started.2 | return [("varargs new service",false)]
    let copiedVa := CerbMemSuspension.node (CerbMem.vaCopy va) vaReady
    let zero := CerbMemSuspension.node
      (CerbMem.memcpyM tags loc (pointer 30 300) (pointer 20 200) (CerbMem.integerIval 0)) enabled
    let initializedValue := CerbMem.MemValue.MVinteger (Unsigned Ichar) (CerbMem.integerIval 42)
    let allocated := CerbMemSuspension.node
      (CerbMem.allocateObject tags 0 (PrefOther "initialized primitive") (CerbMem.integerIval 1)
        unsigned_char none (some initializedValue)) enabled
    return [
      ("observer-only copy still completes one original memory node", (observed ordinary.2).length == 4 &&
        byteAt ordinary.2 300 == some 7 && byteAt ordinary.2 301 == some 9 &&
        match ordinary.1 with | NDactive _ => true | _ => false),
      ("first pause preserves its read before any destination write", (observed phase1.2).length == 1 &&
        byteAt phase1.2 300 == some 0 && byteAt phase1.2 301 == some 0),
      ("resumed store uses its captured read despite an intervening source write",
        byteAt phase2.2 200 == some 21 && byteAt phase2.2 300 == some 7 && byteAt phase2.2 301 == some 0),
      ("next read uses current memory and completion adds no extra pause",
        (observed finished.2).length == 6 && byteAt finished.2 300 == some 7 && byteAt finished.2 301 == some 22 &&
        match finished.1 with | NDactive p => p == pointer 30 300 | _ => false),
      ("resumed write rechecks lifetime and keeps all completed effects",
        observed lifetimeFailure.2 == observed killed.2 &&
        match lifetimeFailure.1,directFailure.1 with
        | NDkilled reason, NDkilled expected => reason == expected
        | _, _ => false),
      ("va_copy keeps metadata read and creation in one primitive", (observed copiedVa.2).length == 3 &&
        match copiedVa.1 with | NDactive _ => true | _ => false),
      ("zero-length copy has no invented memory pause or effect", (observed zero.2).isEmpty &&
        match zero.1 with | NDactive _ => true | _ => false),
      ("allocation installs its initialization before returning without an internal pause",
        match allocated.1, observed allocated.2 with
        | NDactive (.PV _ (.PVconcrete _ address)),
          [Observe_allocation _ _ _ _ _ (some value) bytes] =>
            value == initializedValue && bytes.map CerbMem.representationBits == [some 42] &&
            byteAt allocated.2 address == some 42
        | _, _ => false)]

def main (args : List String) : IO UInt32 := do
  let [arg, topArg] := args | return 2
  let .some fuel := arg.toNat? | return 2
  let .some top := topArg.toInt? | return 2
  let mut good := true
  for (label, pass) in controls fuel top do
    IO.println s!"{label}: {pass}"
    good := good && pass
  return if good then 0 else 1
