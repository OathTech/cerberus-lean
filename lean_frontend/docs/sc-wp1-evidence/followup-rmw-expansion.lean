import Unit.SCWP1Stepping

namespace SCWP1RMWExpansion
open SCWP1Stepping CerbMem

/-- Candidate only: non-forwarding byte RMW expressed with a positive load and
    negative store. It deliberately uses the actual existing Core reductions. -/
def expanded (p : PointerValue) (update : pexpr) : expr core_run_annotation :=
  let ty := mk_value_pe (Vctype unsigned_char)
  let ptr := mk_value_pe (Vobject (OVpointer p))
  let read := Expr [] (Eaction (Paction Pos (Action loc default (Load0 ty ptr NA))))
  let write := Expr [] (Eaction (Paction polarity.Neg0 (Action loc default (Store0 false ty ptr update NA))))
  Expr [] (Ewseq (mk_sym_pat globSym (BTy_loaded OTy_integer)) read
    (Expr [] (Ewseq (mk_empty_pat BTy_unit) write (mk_pure_e (mk_sym_pe globSym)))))

def findKind (cfg : experiment_config) (f : expr core_run_annotation → Bool) : IO Nat := do
  let some n := (experiment_runnable cfg.experiment_state.core_state0).findIdx? (fun (_,_,(_,e)) => f e)
    | throw (IO.userError "missing chosen context")
  return n

def check (fuel : Nat) (memoryDependent : Bool) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "rmw") (iv 1) (iv 1))
        (initialMemState 65536) | throw (IO.userError "p")
    let (.NDactive q, mem) := evalND (allocateRegion 0 (PrefOther "sibling") (iv 8) (iv 8)) mem
      | throw (IO.userError "q")
    let (.NDactive _, mem) := evalND (storeM fmapEmpty fmapEmpty loc unsigned_char false p
        (.MVinteger (.Unsigned .Ichar) (iv 0))) mem | throw (IO.userError "init")
    let fn := Symbol "wp1-memory" 77 (SD_Id "metadata")
    let fnTy := Ctype [] (.Function (no_qualifiers, signed_int) [] false)
    let ptrTy := Ctype [] (.Pointer no_qualifiers fnTy)
    let fnPtr := PointerValue.PV .Prov_none (.PVfunction fn)
    let concretePtr := PointerValue.PV .Prov_none (.PVconcrete none 77)
    let metadata := Pexpr [] () (PEcfunction (mk_value_pe (Vloaded (LVspecified (OVpointer concretePtr)))))
    let pat := mk_tuple_pat (List.map mk_empty_pat [BTy_ctype, BTy_list BTy_ctype, BTy_boolean, BTy_boolean])
    let one := mk_value_pe (Vloaded (LVspecified (OVinteger (iv 1))))
    let update := if memoryDependent then Pexpr [] () (PElet pat metadata one) else one
    let sibling := if memoryDependent then Expr [] (Eaction (Paction Pos (Action loc default
      (Store0 false (mk_value_pe (Vctype ptrTy)) (mk_value_pe (Vobject (OVpointer q)))
        (mk_value_pe (Vloaded (LVspecified (OVpointer fnPtr)))) NA)))) else storeArena q
    let group := Expr [] (Ebound (Expr [] (Eunseq [expanded p update, sibling])))
    let arena := Expr [] (Ewseq (mk_tuple_pat [mk_sym_pat spinSym (BTy_loaded OTy_integer), mk_empty_pat BTy_unit])
      group (mk_pure_e (mk_sym_pe spinSym)))
    let f := { fileFor arena with funinfo := symMap [(fn, (loc, default, signed_int, [], false, true))] }
    let st := { initial f with layout_state := { mem with observations := some [] } }
    let cfg := step 0 (experiment_start fmapEmpty fmapEmpty f [] st)
    require (receiptCount cfg.experiment_state == 1) "startup"
    let loadIndex ← findKind cfg (fun e => match e with
      | Expr _ (Eaction (Paction _ (Action _ _ (.Load0 ..)))) => true | _ => false)
    let cfg := step loadIndex cfg
    require (receiptCount cfg.experiment_state == 2) "load boundary"
    let storeIndex ← findKind cfg (fun e => match e with
      | Expr _ (Eaction (Paction _ (Action _ _ (.Store0 ..)))) => true | _ => false)
    let cfg := step storeIndex cfg
    require (receiptCount cfg.experiment_state == 3) "sibling boundary"
    let (cfg, _) := run (List.replicate 60 0) cfg
    require (match cfg.experiment_phase0 with | .Exp_done r => r.dres_core_value == Vloaded (LVspecified (OVinteger (iv 0))) | _ => false) "candidate did not finish"
    require (receiptCount cfg.experiment_state == 4) "lost or duplicated effect"
    let (.NDactive (_, .MVinteger _ (.IV _ n)), _) := evalND (loadM fmapEmpty fmapEmpty loc unsigned_char p)
      (stopObserving cfg.experiment_state.layout_state) | throw (IO.userError "readback")
    require (n == 1) "candidate wrong stored value"
    IO.println s!"candidate existing-Core expansion (memory-dependent={memoryDependent}): load, completed sibling, one deferred write; returned old value 0; one startup plus three access receipts"

#eval check 64 false
#eval check 128 false
#eval check 64 true
#eval check 128 true
end SCWP1RMWExpansion
