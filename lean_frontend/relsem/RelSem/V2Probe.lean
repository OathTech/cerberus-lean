/-
  RelSem.V2Probe — V2 scratch instrument (NOT part of the build; run
  via scripts/lean_probe.sh). Round-inventory discovery for P01:
  replays the callND stage spine by app-chaining, then walks the dnms
  rounds one at a time printing (class, arena head, env keys, supplies).
  Untrusted-evaluator grade (test ledger); deleted at slice close.
-/
import RelSem.Threaded
import RelSem.CorpusFiles
import RelSem.ConstructLaws
import RelSem.PerStepCall
import RelSem.SlateFiles
import RelSem.T2Threaded
import RelSem.T3Threaded

set_option autoImplicit false

open RelSem RelSem.Cerb RelSem.Corpus

namespace V2Probe

def tagDefs0 : Fmap sym (CerbLocation.Loc × tag_definition) := p01File.tagDefs
abbrev aU : List annot := [Aloc CerbLocation.Loc.unknown]
def intCtyP : ctype := Ctype [] (Basic (Integer (Signed Int_)))
def convIntP : sym := Symbol "" 15837442492999787586 (SD_Id "conv_int")
def symA535P : sym := Symbol "" 15754218577363027919 (SD_Id "a_535")
def symA536P : sym := Symbol "" 6464411467923874555 (SD_Id "a_536")
def symA529P : sym := Symbol "" 1680278659536745755 (SD_Id "a_529")
def symA530P : sym := Symbol "" 4915778119994869450 (SD_Id "a_530")

def symStr : sym → String
  | Symbol _ n sd =>
    match sd with
    | SD_Id name => s!"{name}#{n % 1000}"
    | _ => s!"?#{n}"

/-- Crash-loud active-app extraction. -/
def stepA {α : Type} [Inhabited α]
    (m : ndM α step_kind driver_error mem_iv_constraint driver_state)
    (σ : driver_state) : α × driver_state :=
  match app m σ with
  | (NDactive v, σ') => (v, σ')
  | (NDkilled _, σ') => panic! "probe: killed"
  | _ => panic! "probe: nondeterministic node"

def exprHead : generic_expr core_run_annotation Unit sym → String
  | Expr _ e =>
    match e with
    | Epure (Pexpr _ _ pe) =>
      match pe with
      | PEsym s => s!"Epure(PEsym {symStr s})"
      | PEval _ => "Epure(PEval _)"
      | PEcall _ _ => "Epure(PEcall …)"
      | PEcase _ _ => "Epure(PEcase …)"
      | PEif _ _ _ => "Epure(PEif …)"
      | PEop _ _ _ => "Epure(PEop …)"
      | PEctor _ _ => "Epure(PEctor …)"
      | _ => "Epure(other)"
    | Eaction (Paction _ (Action _ _ act)) =>
      match act with
      | Create _ _ _ => "Eaction(Create)"
      | Store0 _ _ _ _ _ => "Eaction(Store)"
      | Load0 _ _ _ => "Eaction(Load)"
      | Kill _ _ => "Eaction(Kill)"
      | _ => "Eaction(other)"
    | Ecase _ _ => "Ecase"
    | Eif _ _ _ => "Eif"
    | Eunseq _ => "Eunseq"
    | Ewseq _ _ _ => "Ewseq"
    | Esseq _ _ _ => "Esseq"
    | Ebound _ => "Ebound"
    | Esave _ _ _ => "Esave"
    | Erun _ _ _ => "Erun"
    | Eannot _ _ => "Eannot"
    | _ => "other-expr"

def stepClass : core_step2 → String
  | Step_ccall2 _ _ => "CCALL"
  | Step_with_runstate2 (RSK_eval d) _ => s!"RS_EVAL[{d}]"
  | Step_with_runstate2 (RSK_tau d _) _ => s!"RS_TAU[{d}]"
  | Step_tau2 d _ _ => s!"TAU[{d}]"
  | Step_action_request2 d _ _ u _ => s!"ACTION[{d},uc={u}]"
  | Step_memop_request2 _ _ _ _ _ _ => "MEMOP"
  | Step_blocked2 => "BLOCKED"
  | Step_error2 s => s!"ERROR[{s}]"
  | Step_thread_done2 _ _ => "THREAD_DONE"
  | Step_done2 _ => "DONE"
  | Step_spawn_threads2 _ _ => "SPAWN"
  | Step_fs2 _ _ _ => "FS"
  | Step_nd2 _ => "ND"

def thInfo (σ : driver_state) : String :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ =>
    let envKeys := match th.env with
      | f :: _ => (fmapElements f).map (fun (p : sym × value) => symStr p.1)
      | [] => []
    s!"arena={exprHead th.arena} envTop={envKeys}"
  | [] => "NO-THREAD"

def supInfo (σ : driver_state) : String :=
  s!"sym={σ.core_run_state0.sym_supply} aid={σ.core_run_state0.aid_supply} exc={σ.core_run_state0.excluded_supply} ctr={σ.dr_step_counter} mem[next={σ.layout_state.nextAllocId},last={σ.layout_state.lastAddress}]"

partial def walkRounds (σ : driver_state) (i : Nat) (acc : List String) :
    List String × driver_state :=
  if i > 200 then ((("...OVERFLOW" : String) :: acc).reverse, σ)
  else
    let s := RelSem.Laws.stepAt tagDefs0 0 σ
    if can_advance s then
      let (_, σ') := stepA (advance_step tagDefs0 0 s) σ
      walkRounds σ' (i+1) (s!"[{i}] {stepClass s} | {thInfo σ} | {supInfo σ}" :: acc)
    else
      ((s!"[{i}] STOP class={stepClass s} | {thInfo σ} | {supInfo σ}" :: acc).reverse, σ)

def probe (x : Int) (seed : Nat) : List String := Id.run do
  let σ0 := initial_driver_state_threaded seed p01File corpusFs
  -- callK stage spine (PerStepCall.callK, transcribed)
  let (tid0, σ1) := stepA (driver_globals tagDefs0 false p01File) σ0
  let (fsym, σ2) := stepA (resolveFunSym σ1.core_file "clamp0") σ1
  let (pb, σ3) := stepA (lookupFunBody σ2.core_file fsym) σ2
  let (ptys, σ4) := stepA (lookupParamTys σ3.core_file fsym) σ3
  let (bound, σ5) := stepA (injectArgs tagDefs0 tid0 pb.1 ptys [intValue x]) σ4
  let (ths, σ6) := stepA (get_thread_states :
      ndM (List (Nat × (Option thread_id × thread_state))) step_kind
        driver_error mem_iv_constraint driver_state) σ5
  match ths with
  | [(_, (_, th_st))] =>
    let env' : List (Fmap sym value) :=
      match th_st.env with
      | [] => [Lem_Map.fromList bound]
      | xs :: xs' =>
        (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
          fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
            pv.1 pv.2 m) xs bound) :: xs'
    let (errno_ptr, σ7) := stepA (liftMem (nd_bind
        (CerbMem.allocateObject tid0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun ptr_val =>
          nd_bind (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val
              (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0)))
            (fun _ => nd_return ptr_val)))) σ6
    let (_, σ8) := stepA (driver_update_thread_state tid0
      ({ arena := pb.2, stack0 := Stack_empty, errno := errno_ptr,
         current_loc := CerbLocation.other "RelSem.callND",
         exec_loc := ELoc_normal [(fsym, CerbLocation.other "RelSem.callND")],
         env := env', current_proc_opt := some fsym } : thread_state)) σ7
    let hdr := [
      s!"post-globals thread env spine: {th_st.env.length} frames, top keys: {(match th_st.env with | f :: _ => (fmapElements f).map (fun (p : sym × value) => symStr p.1) | [] => [])}",
      s!"bound = {bound.map (fun p => symStr p.1)}",
      s!"post-setup: {thInfo σ8} | {supInfo σ8}"]
    let (lines, σend) := walkRounds σ8 0 []
    let offers := RelSem.Laws.stepAt tagDefs0 0 σend
    return hdr ++ lines ++ [s!"final offered step: {stepClass offers}", s!"final: {supInfo σend}"]
  | _ => return ["probe: thread-count surprise"]


/-! ## THE LEAN-SOURCE PRINTER (P01 round transcription instrument):
    prints per-round arena/env/trace terms AS LEAN SOURCE, ready to
    paste into P01Rounds. Loud fallbacks («?...») on any constructor
    outside the corpus vocabulary. -/

namespace LeanPrint

def pLoc : CerbLocation.Loc → String
  | .unknown => "L0"
  | .other s => s!"(CerbLocation.other \"{s}\")"
  | _ => "«?LOC»"

def pAnnots (as_ : List annot) : String :=
  match as_ with
  | [] => "[]"
  | [Aloc l] => s!"[(Aloc {pLoc l})]"
  | [Aloc l, Auid u] => s!"[(Aloc {pLoc l}), (Auid \"{u}\")]"
  | _ => s!"«?ANNOTS:{as_.length}»"

def pSym : sym → String
  | Symbol d n sd =>
    match sd with
    | SD_Id name => s!"(Symbol \"{d}\" {n} (SD_Id \"{name}\"))"
    | SD_None => s!"(Symbol \"{d}\" {n} SD_None)"
    | _ => "«?SYMDESC»"

def pIty : integerType → String
  | Bool0 => "Bool0"
  | Signed Int_ => "(Signed Int_)"
  | Unsigned Int_ => "(Unsigned Int_)"
  | Signed Long => "(Signed Long)"
  | Unsigned Long => "(Unsigned Long)"
  | _ => "«?ITY»"

def pCty : ctype → String
  | Ctype [] (Basic (Integer it)) => s!"(Ctype [] (Basic (Integer {pIty it})))"
  | Ctype [] Void0 => "(Ctype [] Void0)"
  | _ => "«?CTY»"

def pProv : CerbMem.Provenance → String
  | .Prov_none => ".Prov_none"
  | .Prov_some i => s!"(.Prov_some {i})"
  | _ => "«?PROV»"

def pIV : CerbMem.IntegerValue → String
  | .IV pv n => s!"(.IV {pProv pv} ({n}))"

def pPV : CerbMem.PointerValue → String
  | .PV pv (.PVconcrete none a) => s!"(.PV {pProv pv} (.PVconcrete none {a}))"
  | .PV pv (.PVnull ct) => s!"(.PV {pProv pv} (.PVnull {pCty ct}))"
  | _ => "«?PV»"

def pOV : object_value → String
  | OVinteger iv => s!"(OVinteger {pIV iv})"
  | OVpointer pv => s!"(OVpointer {pPV pv})"
  | _ => "«?OV»"

partial def pBty : core_base_type → String
  | BTy_unit => "BTy_unit"
  | BTy_boolean => "BTy_boolean"
  | BTy_ctype => "BTy_ctype"
  | BTy_loaded OTy_integer => "(BTy_loaded OTy_integer)"
  | BTy_loaded OTy_pointer => "(BTy_loaded OTy_pointer)"
  | BTy_object OTy_integer => "(BTy_object OTy_integer)"
  | BTy_object OTy_pointer => "(BTy_object OTy_pointer)"
  | BTy_storable => "BTy_storable"
  | BTy_tuple btys => s!"(BTy_tuple [{String.intercalate ", " (btys.map pBty)}])"
  | BTy_list b => s!"(BTy_list {pBty b})"
  | _ => "«?BTY»"

partial def pV : value → String
  | Vobject ov => s!"(Vobject {pOV ov})"
  | Vloaded (LVspecified ov) => s!"(Vloaded (LVspecified {pOV ov}))"
  | Vloaded (LVunspecified ct) => s!"(Vloaded (LVunspecified {pCty ct}))"
  | Vunit => "Vunit"
  | Vtrue => "Vtrue"
  | Vfalse => "Vfalse"
  | Vctype ct => s!"(Vctype {pCty ct})"
  | Vtuple vs => s!"(Vtuple [{String.intercalate ", " (vs.map pV)}])"
  | Vlist bty vs => s!"(Vlist {pBty bty} [{String.intercalate ", " (vs.map pV)}])"

partial def pPat : generic_pattern sym → String
  | Pattern as_ (CaseBase (os, bty)) =>
    let osS := match os with
      | some z => s!"(some {pSym z})"
      | none => "none"
    s!"(Pattern {pAnnots as_} (CaseBase ({osS}, {pBty bty})))"
  | Pattern as_ (CaseCtor c pats) =>
    let cS := match c with
      | Ctuple => "Ctuple"
      | Cspecified => "Cspecified"
      | Cunspecified => "Cunspecified"
      | _ => "«?CTOR»"
    s!"(Pattern {pAnnots as_} (CaseCtor {cS} [{String.intercalate ", " (pats.map pPat)}]))"

def pBinop : binop → String
  | OpAdd => "OpAdd" | OpSub => "OpSub" | OpMul => "OpMul"
  | OpDiv => "OpDiv" | OpRem_t => "OpRem_t" | OpRem_f => "OpRem_f"
  | OpExp => "OpExp" | OpEq => "OpEq" | OpGt => "OpGt"
  | OpLt => "OpLt" | OpGe => "OpGe" | OpLe => "OpLe"
  | OpAnd => "OpAnd" | OpOr => "OpOr"

def pIop : iop → String
  | IOpAdd => "IOpAdd" | IOpSub => "IOpSub" | IOpMul => "IOpMul"
  | IOpShl => "IOpShl" | IOpShr => "IOpShr" | IOpDiv => "IOpDiv"
  | IOpRem_t => "IOpRem_t"

partial def pPe : generic_pexpr Unit sym → String
  | Pexpr as_ () pe =>
    let inner := match pe with
      | PEsym z => s!"(PEsym {pSym z})"
      | PEval v => s!"(PEval {pV v})"
      | PEop op e1 e2 => s!"(PEop {pBinop op} {pPe e1} {pPe e2})"
      | PEcall (Sym z) args =>
        s!"(PEcall (Sym {pSym z}) [{String.intercalate ", " (args.map pPe)}])"
      | PEcall (Impl ic) args =>
        let icS := match ic with
          | Integer__conv_nonrepresentable_signed_integer =>
            "Integer__conv_nonrepresentable_signed_integer"
          | _ => "«?IC»"
        s!"(PEcall (Impl {icS}) [{String.intercalate ", " (args.map pPe)}])"
      | PEcase scr arms =>
        let armS := arms.map (fun (pa, e) => s!"({pPat pa}, {pPe e})")
        s!"(PEcase {pPe scr} [{String.intercalate ", " armS}])"
      | PEif g e1 e2 => s!"(PEif {pPe g} {pPe e1} {pPe e2})"
      | PEctor c args =>
        let cS := match c with
          | Ctuple => "Ctuple" | Cspecified => "Cspecified"
          | Cunspecified => "Cunspecified"
          | Civmin => "Civmin" | Civmax => "Civmax"
          | Civsizeof => "Civsizeof" | Civalignof => "Civalignof"
          | _ => "«?CTOR»"
        s!"(PEctor {cS} [{String.intercalate ", " (args.map pPe)}])"
      | PEundef l ub =>
        let ubS := match ub with
          | UB036_exceptional_condition => "UB036_exceptional_condition"
          | UB038_number_of_args => "UB038_number_of_args"
          | UB041_function_not_compatible => "UB041_function_not_compatible"
          | UB043_indirection_invalid_value => "UB043_indirection_invalid_value"
          | UB088_reached_end_of_function => "UB088_reached_end_of_function"
          | UB_CERB004_unspecified ck =>
            let ckS := match ck with
              | UB_unspec_conditional => "UB_unspec_conditional"
              | _ => "«?UNSPEC»"
            s!"(UB_CERB004_unspecified {ckS})"
          | _ => "«?UB»"
        s!"(PEundef {pLoc l} {ubS})"
      | PEerror msg e => s!"(PEerror \"{msg}\" {pPe e})"
      | PEnot e => s!"(PEnot {pPe e})"
      | PEis_integer e => s!"(PEis_integer {pPe e})"
      | PEis_unsigned e => s!"(PEis_unsigned {pPe e})"
      | PEis_signed e => s!"(PEis_signed {pPe e})"
      | PEare_compatible e1 e2 => s!"(PEare_compatible {pPe e1} {pPe e2})"
      | PEstruct _ _ => "«?PEstruct»"
      | PElet pa e1 e2 => s!"(PElet {pPat pa} {pPe e1} {pPe e2})"
      | PEwrapI ity iop1 e1 e2 =>
        s!"(PEwrapI {pIty ity} {pIop iop1} {pPe e1} {pPe e2})"
      | PEcatch_exceptional_condition ity iop1 e1 e2 =>
        s!"(PEcatch_exceptional_condition {pIty ity} {pIop iop1} {pPe e1} {pPe e2})"
      | PEconv_int ity e => s!"(PEconv_int {pIty ity} {pPe e})"
      | PEmemop _ args => s!"(PEmemop «?MOP» [{String.intercalate ", " (args.map pPe)}])"
      | _ => "«?PE»"
    s!"(Pexpr {pAnnots as_} () {inner})"

def pMo : polarity → String
  | .Pos => "Pos"
  | .Neg0 => "Neg0"

def pAct : generic_action_ Unit sym → String
  | Create e1 e2 pref =>
    let prefS := match pref with
      | PrefSource l syms => s!"(PrefSource {pLoc l} [{String.intercalate ", " (syms.map pSym)}])"
      | PrefOther str => s!"(PrefOther \"{str}\")"
      | _ => "«?PREF»"
    s!"(Create {pPe e1} {pPe e2} {prefS})"
  | Store0 lk e1 e2 e3 mo => s!"(Store0 {lk} {pPe e1} {pPe e2} {pPe e3} NA)"
  | Load0 e1 e2 mo => s!"(Load0 {pPe e1} {pPe e2} NA)"
  | Kill kind e =>
    let kS := match kind with
      | kill_kind.Dynamic0 => "Dynamic0"
      | kill_kind.Static0 ct => s!"(Static0 {pCty ct})"
    s!"(Kill {kS} {pPe e})"
  | _ => "«?ACT»"

partial def pE : generic_expr core_run_annotation Unit sym → String
  | Expr as_ body =>
    let inner := match body with
      | Epure pe => s!"(Epure {pPe pe})"
      | Eaction (Paction pol (Action l _a act)) =>
        s!"(Eaction (Paction {pMo pol} (Action {pLoc l} empty_annotation {pAct act})))"
      | Ecase scr arms =>
        let armS := arms.map (fun (pa, e) => s!"({pPat pa}, {pE e})")
        s!"(Ecase {pPe scr} [{String.intercalate ", " armS}])"
      | Eif g e1 e2 => s!"(Eif {pPe g} {pE e1} {pE e2})"
      | Eunseq es => s!"(Eunseq [{String.intercalate ", " (es.map pE)}])"
      | Ewseq pa e1 e2 => s!"(Ewseq {pPat pa} {pE e1} {pE e2})"
      | Esseq pa e1 e2 => s!"(Esseq {pPat pa} {pE e1} {pE e2})"
      | Ebound e => s!"(Ebound {pE e})"
      | Esave (z, bty) params e =>
        let pS := params.map (fun (q : sym ×
            ((core_base_type × Option (ctype × pass_by_value_or_pointer))
              × generic_pexpr Unit sym)) =>
          let octyS : String := if q.2.1.2.isSome then "«?OCTY»" else "none"
          s!"({pSym q.1}, (({pBty q.2.1.1}, {octyS}), {pPe q.2.2}))")
        s!"(Esave ({pSym z}, {pBty bty}) [{String.intercalate ", " pS}] {pE e})"
      | Erun _a z pes => s!"(Erun empty_annotation {pSym z} [{String.intercalate ", " (pes.map pPe)}])"
      | Ememop _ pes => s!"(Ememop «?MEMOP» [{String.intercalate ", " (pes.map pPe)}])"
      | Eccall _a pe1 pe2 pes => s!"(Eccall empty_annotation {pPe pe1} {pPe pe2} [{String.intercalate ", " (pes.map pPe)}])"
      | Eproc _a _n pes => s!"(Eproc empty_annotation «?NAME» [{String.intercalate ", " (pes.map pPe)}])"
      | End es => s!"(End [{String.intercalate ", " (es.map pE)}])"
      | Eannot dyns e =>
        let dS := dyns.map (fun d => match d with
          | DA_pos excl (CerbMem.Footprint.FP k a n) =>
            let kS := match k with
              | .R => ".R" | .W => ".W"
            s!"(DA_pos [{String.intercalate ", " (excl.map toString)}] (CerbMem.Footprint.FP {kS} {a} {n}))"
          | DA_neg i excl (CerbMem.Footprint.FP k a n) =>
            let kS := match k with
              | .R => ".R" | .W => ".W"
            s!"(DA_neg {i} [{String.intercalate ", " (excl.map toString)}] (CerbMem.Footprint.FP {kS} {a} {n}))")
        s!"(Eannot [{String.intercalate ", " dS}] {pE e})"
      | _ => "«?E»"
    s!"(Expr {pAnnots as_} {inner})"

def pTe : trace_event → String
  | ME_load l pref ct pv mv =>
    let prefS := match pref with
      | none => "none"
      | some str => s!"(some \"{str}\")"
    s!"(ME_load {pLoc l} {prefS} {pCty ct} {pPV pv} «MV:{match mv with | CerbMem.MemValue.MVinteger it iv => s!"MVinteger {pIty it} {pIV iv}" | _ => "?"}»)"
  | ME_store l pref ct lk pv mv =>
    let prefS := match pref with
      | none => "none"
      | some str => s!"(some \"{str}\")"
    s!"(ME_store {pLoc l} {prefS} {pCty ct} {lk} {pPV pv} «MV:{match mv with | CerbMem.MemValue.MVinteger it iv => s!"MVinteger {pIty it} {pIV iv}" | _ => "?"}»)"
  | ME_allocate_object tid pref alignIv cty init pv =>
    let prefS := match pref with
      | PrefOther str => s!"(PrefOther \"{str}\")"
      | PrefSource l syms =>
        s!"(PrefSource {pLoc l} [{String.intercalate ", " (syms.map pSym)}])"
      | _ => "«?PREF»"
    let initS := match init with
      | none => "none" | some _ => "«?SOMEINIT»"
    s!"(ME_allocate_object {tid} {prefS} {pIV alignIv} {pCty cty} {initS} {pPV pv})"
  | ME_kill l b pv => s!"(ME_kill {pLoc l} {b} {pPV pv})"
  | _ => "«?TE»"

def envTopLean (σ : driver_state) : String :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ =>
    match th.env with
    | f :: _ =>
      let es := (fmapElements f).map (fun (p : sym × value) =>
        s!"    {pSym p.1} ↦ {pV p.2}")
      String.intercalate "\n" es
    | [] => "    (no frame)"
  | [] => "    (no thread)"

def arenaLean (σ : driver_state) : String :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ => pE th.arena
  | [] => "(no thread)"

partial def walkRoundsLean (tagDefs0 : Fmap sym (CerbLocation.Loc × tag_definition)) (σ : driver_state) (i : Nat)
    (acc : List String) : List String × driver_state :=
  if i > 60 then ((("...OVERFLOW" : String) :: acc).reverse, σ)
  else
    let s := RelSem.Laws.stepAt tagDefs0 0 σ
    let line := s!"===== ROUND [{i}] {stepClass s} | {supInfo σ}\nARENA := {arenaLean σ}\nENV:\n{envTopLean σ}\nTRACE({σ.trace.length}) := [{String.intercalate ", " (σ.trace.map pTe)}]"
    if can_advance s then
      let (_, σ') := stepA (advance_step tagDefs0 0 s) σ
      walkRoundsLean tagDefs0 σ' (i+1) (line :: acc)
    else
      ((s!"{line}\n===== STOP" :: acc).reverse, σ)

end LeanPrint

def probeLeanG (file1 : file core_run_annotation) (fname : String)
    (args : List value) (seed : Nat) : List String := Id.run do
  let tagDefs0 := file1.tagDefs
  let σ0 := initial_driver_state_threaded seed file1 corpusFs
  let (tid0, σ1) := stepA (driver_globals tagDefs0 false file1) σ0
  let (fsym, σ2) := stepA (resolveFunSym σ1.core_file fname) σ1
  let (pb, σ3) := stepA (lookupFunBody σ2.core_file fsym) σ2
  let (ptys, σ4) := stepA (lookupParamTys σ3.core_file fsym) σ3
  let (bound, σ5) := stepA (injectArgs tagDefs0 tid0 pb.1 ptys args) σ4
  let (ths, σ6) := stepA (get_thread_states :
      ndM (List (Nat × (Option thread_id × thread_state))) step_kind
        driver_error mem_iv_constraint driver_state) σ5
  match ths with
  | [(_, (_, th_st))] =>
    let env' : List (Fmap sym value) :=
      match th_st.env with
      | [] => [Lem_Map.fromList bound]
      | xs :: xs' =>
        (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
          fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
            pv.1 pv.2 m) xs bound) :: xs'
    let (errno_ptr, σ7) := stepA (liftMem (nd_bind
        (CerbMem.allocateObject tid0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun ptr_val =>
          nd_bind (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val
              (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0)))
            (fun _ => nd_return ptr_val)))) σ6
    let (_, σ8) := stepA (driver_update_thread_state tid0
      ({ arena := pb.2, stack0 := Stack_empty, errno := errno_ptr,
         current_loc := CerbLocation.other "RelSem.callND",
         exec_loc := ELoc_normal [(fsym, CerbLocation.other "RelSem.callND")],
         env := env', current_proc_opt := some fsym } : thread_state)) σ7
    let hdr := [
      s!"bound = {bound.map (fun p => LeanPrint.pSym p.1)} vals {bound.map (fun p => LeanPrint.pV p.2)}",
      s!"errno_ptr = {LeanPrint.pPV errno_ptr}",
      s!"post-setup mem: next={σ8.layout_state.nextAllocId} last={σ8.layout_state.lastAddress}"]
    let (lines, σend) := LeanPrint.walkRoundsLean tagDefs0 σ8 0 []
    return hdr ++ lines ++ [s!"final: {supInfo σend}"]
  | _ => return ["probe: thread-count surprise"]


/-! ## THE AUX2 CHAIN PROBE: per-eval-round step_eval intermediates
    as Lean source (the z-chain discovery instrument). -/

def chainProbe (env : List (Fmap sym value))
    (memo : Option CerbMem.MemState)
    (pe : generic_pexpr Unit sym) : List String := Id.run do
  let ext := create_extern_symmap p01File
  let mut cur := pe
  let mut out : List String := []
  for i in [0:12] do
    let pulled := pull_constrained 0 cur
    out := out ++ [s!"-- step {i} PULLED: {LeanPrint.pPe pulled}"]
    match pulled with
    | Pexpr _ _ (PEval v) =>
      out := out ++ [s!"-- DONE value: {LeanPrint.pV v}"]
      return out
    | _ => pure ()
    match step_eval_pexpr tagDefs0 0 CerbLocation.Loc.unknown
        (some (CerbLocation.other "RelSem.callND")) ext env memo
        p01File false pulled with
    | Result (Defined pe') =>
      out := out ++ [s!"   STEP => {LeanPrint.pPe pe'}"]
      cur := pe'
    | Result (Undef _ _) => return out ++ ["-- UNDEF"]
    | Result (Error _ _) => return out ++ ["-- ERROR"]
    | Exception _ => return out ++ ["-- EXC"]
  return out ++ ["-- ...chain overflow"]

def r10pe (x : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEif (Pexpr aU () (PEop OpLt
      (Pexpr aU () (PEcall (Sym convIntP)
        [Pexpr aU () (PEval (Vctype intCtyP)),
         Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none x))))]))
      (Pexpr aU () (PEcall (Sym convIntP)
        [Pexpr aU () (PEval (Vctype intCtyP)),
         Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 0))))]))))
    (Pexpr aU () (PEctor Cspecified
      [Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 1))))]))
    (Pexpr aU () (PEctor Cspecified
      [Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 0))))])))

def r8pe : generic_pexpr Unit sym :=
  Pexpr aU () (PEctor Ctuple
    [Pexpr aU () (PEsym symA535P), Pexpr aU () (PEsym symA536P)])

def r13pe : generic_pexpr Unit sym :=
  Pexpr aU () (PEcase
    (Pexpr aU () (PEctor Ctuple
      [Pexpr aU () (PEsym symA529P), Pexpr aU () (PEsym symA530P)]))
    [(Pattern aU (CaseCtor Ctuple
        [Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase ((some (Symbol "" 17653705816563834534 (SD_Id "a_531"))), BTy_object OTy_integer))]),
         Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase ((some (Symbol "" 1342427191597093029 (SD_Id "a_532"))), BTy_object OTy_integer))])]),
      Pexpr aU () (PEif (Pexpr aU () (PEop OpEq
          (Pexpr aU () (PEcall (Sym convIntP)
            [Pexpr aU () (PEval (Vctype intCtyP)),
             Pexpr aU () (PEsym (Symbol "" 17653705816563834534 (SD_Id "a_531")))]))
          (Pexpr aU () (PEcall (Sym convIntP)
            [Pexpr aU () (PEval (Vctype intCtyP)),
             Pexpr aU () (PEsym (Symbol "" 1342427191597093029 (SD_Id "a_532")))]))))
        (Pexpr aU () (PEctor Cspecified [Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 1))))]))
        (Pexpr aU () (PEctor Cspecified [Pexpr aU () (PEval (Vobject (OVinteger (.IV .Prov_none 0))))]))))]
    )

def t2r10pe : generic_pexpr Unit sym :=
  Pexpr aU () (PEcase
    (Pexpr aU () (PEctor Ctuple
      [Pexpr aU () (PEsym (Symbol "" 4915778119994869450 (SD_Id "a_530"))),
       Pexpr aU () (PEsym (Symbol "" 17653705816563834534 (SD_Id "a_531")))]))
    [(Pattern aU (CaseCtor Ctuple
        [Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase ((some (Symbol "" 1342427191597093029 (SD_Id "a_532"))), BTy_object OTy_integer))]),
         Pattern aU (CaseCtor Cspecified
          [Pattern aU (CaseBase ((some (Symbol "" 18213349194842787190 (SD_Id "a_533"))), BTy_object OTy_integer))])]),
      Pexpr aU () (PEctor Cspecified
        [Pexpr aU () (PEcatch_exceptional_condition (Signed Int_) IOpAdd
          (Pexpr aU () (PEconv_int (Signed Int_)
            (Pexpr aU () (PEsym (Symbol "" 1342427191597093029 (SD_Id "a_532"))))))
          (Pexpr aU () (PEconv_int (Signed Int_)
            (Pexpr aU () (PEsym (Symbol "" 18213349194842787190 (SD_Id "a_533")))))))])),
     (Pattern aU (CaseBase (none,
        BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
      Pexpr aU () (PEundef CerbLocation.Loc.unknown UB036_exceptional_condition))])

#eval do
  IO.println "##### t2 r10 chain (3,5) #####"
  for l in chainProbe [Lem_Map.fromList
      [((Symbol "" 4915778119994869450 (SD_Id "a_530")),
        Vloaded (LVspecified (OVinteger (.IV .Prov_none 3)))),
       ((Symbol "" 17653705816563834534 (SD_Id "a_531")),
        Vloaded (LVspecified (OVinteger (.IV .Prov_none 5))))]]
      (some CerbMem.initialMemState) t2r10pe do IO.println l
  IO.println "@@@@@ T2 add(3,5) @@@@@"
  for l in probeLeanG RelSem.Slate.t2File "add" [intValue 3, intValue 5] 0 do IO.println l
  IO.println "@@@@@ T2 add(-4,7) @@@@@"
  for l in probeLeanG RelSem.Slate.t2File "add" [intValue (-4), intValue 7] 0 do IO.println l
  IO.println "@@@@@ T3 roundtrip(7) @@@@@"
  for l in probeLeanG RelSem.Slate.t3File "roundtrip" [intValue 7] 0 do IO.println l
  IO.println "@@@@@ T3 roundtrip(-4) @@@@@"
  for l in probeLeanG RelSem.Slate.t3File "roundtrip" [intValue (-4)] 0 do IO.println l

end V2Probe
