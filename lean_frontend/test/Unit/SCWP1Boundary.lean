import Driver

/-! WP1 diagnostic of the existing production boundary, not a new executor.
    Run with caller-selected generated-call fuel. No scheduler budget is claimed. -/
namespace SCWP1Boundary
open CerbMem

def loc := CerbLocation.Loc.other "wp1-boundary"
def top : Int := 65536
def iv := IntegerValue.IV .Prov_none
def emptyFile : file core_run_annotation :=
  { main := none, calling_convention0 := default,
    tagDefs := fmapEmpty, enumDefs := fmapEmpty, stdlib := fmapEmpty,
    impl0 := fmapEmpty, globs := [], funs := fmapEmpty, extern := fmapEmpty,
    funinfo := fmapEmpty, loop_attributes1 := fmapEmpty, visible_objects_env0 := fmapEmpty }
def done : expr core_run_annotation := Expr [] (Epure (mk_value_pe Vunit))
def bounds : Nat → expr core_run_annotation
  | 0 => done
  | n + 1 => Expr [] (Ebound (bounds n))
def th (arena : expr core_run_annotation) : thread_state :=
  { (default : thread_state) with arena := arena, stack0 := Stack_empty, env := [fmapEmpty] }
def initial (arena : expr core_run_annotation) : driver_state :=
  let st := (initial_driver_state 0 top "wp1-boundary" emptyFile CerbFS.fs_initial_state).1
  { st with core_state0 := { st.core_state0 with thread_states := [(0, (none, th arena))] } }
def storeArena (p : PointerValue) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action loc default
    (Store0 false (mk_value_pe (Vctype unsigned_char))
      (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vobject (OVinteger (iv 42)))) NA))))
def runND {α i e c s : Type} (m : ndM α i e c s) (st : s) :=
  match m with | .ND f => f st
def require (b : Bool) (msg : String) : IO Unit :=
  unless b do throw (IO.userError msg)

def check [LemFuel] : IO Unit := do
  -- A singleton pick and its continuation run in the same observed ND node.
  let pickOne : ndM Nat String Unit Unit Nat := pick "singleton" [7]
  let chained := nd_bind pickOne (fun n => nd_bind (nd_put n) (fun _ => nd_return n))
  let (.NDactive n, st) := runND chained 0 | throw (IO.userError "singleton did not return active")
  require (n == 7 && st == 7) "singleton continuation control"
  IO.println "singleton: active; continuation already changed state to 7"

  -- This enters production step_ctx and the production driver, not a mock list of steps.
  for count in [0, 1, 3] do
    let st := initial (bounds count)
    let steps := step_ctx fmapEmpty fmapEmpty st.layout_state emptyFile fmapEmpty 0 (none, th (bounds count))
    require (steps.length == 1) "expected exactly one Core choice"
    let (.NDactive choices, post) := runND (new_drive_core_threads fmapEmpty fmapEmpty ()) st
      | throw (IO.userError "production discovery did not complete")
    require (post.dr_step_counter == count) "wrong number of eager tau steps"
    require (match choices with | [(0, some (.Step_done2 .Vunit))] => true | _ => false)
      "discovery did not reach program done"
    IO.println s!"bounds {count}: one discovery call executed {post.dr_step_counter} tau steps"

  let (.NDactive p, mem) := runND (allocateRegion 0 (PrefOther "wp1") (iv 1) (iv 1))
      (initialMemState top) | throw (IO.userError "fixture allocation")
  let (.NDactive _, mem) := runND
      (storeM fmapEmpty fmapEmpty loc unsigned_char false p (.MVinteger (.Unsigned .Ichar) (iv 0))) mem
    | throw (IO.userError "fixture initialization")
  let some mem := beginObserving mem | throw (IO.userError "fixture capture")
  let st := { initial (storeArena p) with layout_state := mem }
  let steps := step_ctx fmapEmpty fmapEmpty mem emptyFile fmapEmpty 0 (none, th (storeArena p))
  let [request@(.Step_action_request2 _ _ _ _ _)] := steps
    | throw (IO.userError "Core store did not expose one request")
  require (can_advance request) "store was not eagerly eligible"
  let (.NDactive choices, post) := runND (new_drive_core_threads fmapEmpty fmapEmpty ()) st
    | throw (IO.userError "store discovery did not complete")
  require (match choices with | [(0, some (.Step_done2 .Vunit))] => true | _ => false)
    "store discovery did not reach done"
  let some (receipts, _) := takeObservations post.layout_state
    | throw (IO.userError "capture lost")
  require (match receipts with
    | [.Access_receipt l .StoreAccess _ _ _ _ [_] (.MVinteger _ (.IV _ 42)) (some false)] => l == loc
    | _ => false) "missing actual store receipt"
  let (.NDactive (_, .MVinteger _ (.IV _ value)), _) := runND
      (loadM fmapEmpty fmapEmpty loc unsigned_char p) (stopObserving post.layout_state)
    | throw (IO.userError "store readback failed")
  require (value == 42) "store discovery did not write memory"
  IO.println "Core store: discovery executed write 0 -> 42; one receipt; returned program done"

def checkAt (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    IO.println s!"generated-call fuel {fuel}"
    check

-- Two test-selected call-fuel values; neither is a scheduler budget.
#eval checkAt 64
#eval checkAt 128

end SCWP1Boundary
