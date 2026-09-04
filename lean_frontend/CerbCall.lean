/-
  CerbCall — the driver's FUNCTION-CALL ENTRY (`--call <f> [--call-args
  <ints>]`), a port-side harness entry over the generated driver.

  Given a linked Core file and a designated function name, `driveCall`
  builds the driver computation that runs the globals and then runs THE
  ELABORATED CALL SITE of `f(<ints>)` — the Core the shared elaborator
  emits for a C call under the Normal calling convention — with `f`'s
  body reached through the same `Eccall` step the oracle's wrapper
  `main` takes. It is `drive` (driver.lem:1727 / generated Driver.lean)
  with the startup symbol resolved by NAME instead of `file.main` and
  `main`'s body replaced by that rendered call site. Main.lean runs
  `CerbND.runND` on this computation exactly as it runs it on `drive`;
  the fixture lanes (scripts/test_verify.sh) use it to compare
  individual functions against the oracle point-by-point.

  MIRROR-OCAML NOTE: the OCaml driver (backend/driver/main.ml,
  backend/common/pipeline.ml) has NO call-a-function-by-name mode — it
  only runs `main`. This module is a PORT-SIDE HARNESS ENTRY, so its
  oracle twin is the WRAPPER TU the lane renders and runs on the oracle
  (`int main(void) { return f(<args>); }`, scripts/test_verify.sh
  `render_wrapper`), and the mirror obligation is to compute what that
  wrapper computes. Zero-discrepancy Z2 (audit rows Z2-C-01…C-05,
  charter Z-60) made that literal:

  * THE CALL SITE IS RENDERED, NOT IMITATED (Z2-C-01 / Z-60). The
    previous text stored each injected integer RAW into a fresh object
    and bound `f`'s parameters by hand — "the call-site `conv_int` range
    conversion is NOT reproduced" was a fail-OPEN contract (probe
    tests/z2-probes/call/bool_param.c: `--call f --call-args 2` on
    `int f(_Bool b)` trapped UB012 where the wrapper answers
    `Specified(1)`). Now `mkCallSite` builds exactly what
    translation.lem's `translate_call` emits for `f(<int literal>…)`
    under `Normal_callconv` (translation.lem:940-975, :1126-1155 — the
    NON-variadic branch; pre-merge audit F3):
    per argument `create` of the parameter's C type at its alignment
    with a `PrefFunArg` prefix, then `store` of
    `conv_loaded_int('T', n)` — the SAME std.core function the oracle
    calls (stdlib.mkcall_conv_loaded_int_, translation_aux.lem:347-348;
    `_Bool` → 0/1, representable → identity, unsigned → wrapI, signed
    non-representable → the impl constant) — the pointer bound by
    `wseq`; then `sseq` the creates, `Eccall` the function-pointer value
    with the argument pointers, kill the temporaries, return the call's
    value. Out-of-range integers are therefore converted exactly as the
    wrapper converts them; nothing is refused that the wrapper accepts.
  * ERRNO IS ALLOCATED FIRST (Z2-C-02): `drive` allocates errno before
    `main`'s body runs (driver.lem:1860-1868) and the argument
    temporaries are `create`d INSIDE that body, so the parameter objects
    sit below errno on the oracle; the previous text allocated errno
    after the arguments (probe errno_order.c: 65528 vs the wrapper's
    65524).
  * WHAT IS REFUSED, LOUDLY AND ATTRIBUTED (Z2-C-03/C-05): a parameter
    whose C type is not an integer type, a return type other than
    `signed int` (the wrapper's `int main` returns the value unconverted
    only then), an argument-count mismatch, an ambiguous/unknown name —
    each an explicit `kill` naming this entry and the rule; never a
    silent coercion or default.
  * DECLARED: the actions' location is `other "CerbCall.driveCall"`
    where the wrapper's carry the wrapper TU's call-site region — a UB
    raised BY the create/store of a fresh temporary (none exists) would
    print a different `loc`; UBs inside `f`'s body carry the fixture's
    own locations on both sides. The `PrefFunArg` digest is the TU's
    (`Symbol.digest ()` mirror, translation.lem:965) — observable only
    through `prefix_of_pointer` (trace-only, CerbMem Z2-M-06). The
    binder symbols of the argument pointers are `f`'s OWN parameter
    symbols (the elaborator draws fresh ones): the caller's env frame
    binds them to the pointers, `Eccall` pushes a fresh frame for `f`'s
    parameters, so no lookup is ambiguous; the call result is bound to
    `f`'s symbol (dead after the final `pure`). The wrapper's `main`
    also carries the `cfunction`-derived UB038/UB041 checks
    (translation.lem:1041-1064) — constant-true for a prototype-matching
    direct call, not rendered.

  HISTORY: born 2026-08-20 as `RelSem.Cerb.callND` in the reasoning-era
  `relsemcore/` package; relocated here verbatim-in-semantics on
  2026-09-02 when that package was removed from mainline ([USER
  2026-09-02]: the only canonical semantics is the Cerberus opsem).
  Record: docs/2026-09-02_relsem-prune-record.md; the reasoning-era
  version lives on branch arc/segment-ladder (tag
  park/reasoning-era-20260831). Rewritten to the rendered call site in
  zero-discrepancy Z2 (docs/2026-09-04_zero-discrepancy-Z2-record.md).

  House rules: no sorry, no axioms, no `partial`.
-/

import Driver
import Core_aux
import AilTypesAux

set_option autoImplicit false

open Lem_Basic_classes (ordCompare)

namespace CerbCall

/-! ## Argument values (the Lean-value → Core-value boundary) -/

/-- A C `int`-shaped Core argument value: the loaded specified integer
    carrying `n` — what the wrapper's integer literal evaluates to
    (`Vloaded (LVspecified (OVinteger n))`). -/
def intValue (n : Int) : value :=
  Vloaded (LVspecified (OVinteger (CerbMem.integerIval n)))

/-- All function symbols of a fun map carrying the C-level name `fname`
    (the `SD_Id` description). Mirrors the generated driver's name-based
    symbol lookup (Driver.lean `struct_sym` pattern), total (non-`SD_Id`
    symbols simply don't match). `funs` for the program's functions;
    `stdlib` for the std.core functions the elaborator calls by name
    (`conv_loaded_int`). -/
def funSymsNamedIn (funs : generic_fun_map Unit core_run_annotation)
    (fname : String) : List sym :=
  let dom := fmapDomainBy (fun (s1 s2 : sym) => ordCompare s1 s2) funs
  -- pin-bump 2026-09-03 (LemLib 3c88f0d): `set 'a` is `Pset` and lem's
  -- `Set.filter` is comparator-keyed `setFilterBy` (pset.ml `filter`);
  -- the same `Ord0 sym` comparator keys the domain set above. Ascending
  -- symbol order, as the OCaml `Pset.elements` would give.
  setToList (setFilterBy (fun (s1 s2 : sym) => ordCompare s1 s2) (fun (s : sym) =>
    match s with
    | Symbol _ _ (SD_Id n) => n == fname
    | _ => false) dom)

def funSymsNamed (file1 : file core_run_annotation) (fname : String) : List sym :=
  funSymsNamedIn file1.funs fname

/-! ## The rendered call site (translation.lem `translate_call`, Normal_callconv) -/

private abbrev PE := generic_pexpr Unit sym
private abbrev CE := generic_expr core_run_annotation Unit sym

/-- `Pexpr [] () _` — the elaborator's pexpr shape (core_aux.lem `mk_*_pe`). -/
private def mkPE (pe_ : generic_pexpr_ Unit sym) : PE := Pexpr [] () pe_
/-- `Expr [] _` — the elaborator's expr shape (core_aux.lem `mk_*_e`). -/
private def mkE (e_ : generic_expr_ core_run_annotation Unit sym) : CE := Expr [] e_

/-- The location every rendered action carries (declared, header). -/
def callLoc : CerbLocation.Loc := CerbLocation.other "CerbCall.driveCall"

/-- ONE argument's temporary — translation.lem:958-968:
    `mk_wseq_e arg_ptr_pat (pcreate loc (mk_alignof_pe ty_pe) ty_pe (PrefFunArg
    loc digest n)) (mk_wseq_e (mk_empty_pat BTy_unit) (pstore loc ty_pe
    arg_ptr_pe conv_value mo) (mk_pure_e arg_ptr_pe))` with
    `conv_value = conv_loaded_int(ty_pe, arg)` for an integer parameter
    (:948-953) and `mo = Seq_cst` iff the parameter type is atomic
    (:954-958, STD §6.2.6.1#9). Helper shapes: `pcreate`/`pstore`
    core_aux.lem:521-530, `mk_alignof_pe` :367-368, `mk_ail_ctype_pe`
    :328-329, `mk_wseq_e` :2098-2099, `mk_pure_e` :2077-2078,
    `mk_sym_pat`/`mk_sym_pe` :227/:280-281, `mk_empty_pat` :219-220. -/
def argCreate (convSym psym : sym) (ty : ctype) (v : value) (n : Int) : CE :=
  let tyPe : PE := mkPE (PEval (Vctype ty))
  let convValue : PE := mkPE (PEcall (Sym convSym) [tyPe, mkPE (PEval v)])
  let mo : memory_order := if is_atomic ty then Seq_cst else NA
  let ptrPat : generic_pattern sym := Pattern [] (CaseBase (some psym, BTy_object OTy_pointer))
  let unitPat : generic_pattern sym := Pattern [] (CaseBase (none, BTy_unit))
  let create : CE := mkE (Eaction (Paction Pos (Action callLoc default
    (Create (mkPE (PEctor Civalignof [tyPe])) tyPe
      (PrefFunArg callLoc (CerberusFresh.digest ()) n)))))
  let store : CE := mkE (Eaction (Paction Pos (Action callLoc default
    (Store0 false tyPe (mkPE (PEsym psym)) convValue mo))))
  mkE (Ewseq ptrPat create (mkE (Ewseq unitPat store (mkE (Epure (mkPE (PEsym psym)))))))

/-- `mk_sseqs` — core_aux.lem:758-765. -/
def mkSseqs : List (generic_pattern sym × CE) → CE → CE
  | [], z => z
  | (pat, e) :: rest, z => mkE (Esseq pat e (mkSseqs rest z))

/-- `mk_unseq` — core_aux.lem:788-792. -/
def mkUnseq : List CE → CE
  | [] => mkE (Epure (mkPE (PEval Vunit)))
  | [e] => e
  | es => mkE (Eunseq es)

/-- THE CALL SITE for `f(args)` — translation.lem:1126-1155 (Normal_callconv,
    the non-variadic branch of `if expect_is_variadic` :1035; the variadic
    branch :1082-1108 appends a varargs list — not rendered):
    `mk_sseqs (zip arg_ptr_pats creates) (mk_sseq_e call_ret_pat (mk_ccall_e_
    annots ret_ty_pe fun_pe arg_ptr_pes) (mk_sseq_e killall_pat (mk_unseq
    kills) (mk_pure_e call_ret_pe)))`, where `fun_pe` is the loaded
    function-pointer value the designator evaluates to (core_run.lem:944
    matches `Vloaded (LVspecified (OVpointer pv))`), `killall_pat` is a
    unit pattern for < 2 arguments else a tuple of units (:1008-1013), and
    each kill is `pkill loc (Static ty) arg_ptr_pe` (:1103-1106). -/
def mkCallSite (convSym fsym : sym) (params : List (sym × ctype)) (args : List value)
    (retTy : ctype) : CE :=
  let creates : List (generic_pattern sym × CE) :=
    (List.zip params args).zipIdx.map fun (pv : ((sym × ctype) × value) × Nat) =>
      let (((psym, ty), v), i) := pv
      (Pattern [] (CaseBase (some psym, BTy_object OTy_pointer)), argCreate convSym psym ty v i)
  let argPes : List PE := params.map fun (p : sym × ctype) => mkPE (PEsym p.1)
  let funPe : PE := mkPE (PEval (Vloaded (LVspecified (OVpointer (CerbMem.funPtrval fsym)))))
  let retPat : generic_pattern sym := Pattern [] (CaseBase (some fsym, BTy_loaded OTy_integer))
  let killallPat : generic_pattern sym :=
    if params.length < 2 then Pattern [] (CaseBase (none, BTy_unit))
    else Pattern [] (CaseBase (none, BTy_tuple (List.replicate params.length BTy_unit)))
  let kills : CE := mkUnseq (params.map fun (p : sym × ctype) =>
    mkE (Eaction (Paction Pos (Action callLoc default (Kill (Static0 p.2) (mkPE (PEsym p.1)))))))
  mkSseqs creates
    (mkE (Esseq retPat
      (mkE (Eccall default (mkPE (PEval (Vctype retTy))) funPe argPes))
      (mkE (Esseq killallPat kills (mkE (Epure (mkPE (PEsym fsym))))))))

/-! ## The call computation, in named stages -/

/-- Stage: resolve a name to its unique function symbol in a fun map (no
    match / ambiguity are explicit `kill`s, never silent picks). -/
def resolveSymIn (funs : generic_fun_map Unit core_run_annotation)
    (what fname : String) : driverM sym :=
  match funSymsNamedIn funs fname with
  | [fsym] => nd_return fsym
  | [] => kill (Other (DErr_other
      (String.append (String.append "driveCall: no " what) (String.append " named " fname))))
  | _ :: _ :: _ => kill (Other (DErr_other
      (String.append (String.append "driveCall: ambiguous " what) (String.append " name " fname))))

def resolveFunSym (file1 : file core_run_annotation) (fname : String) : driverM sym :=
  resolveSymIn file1.funs "function" fname

/-- Stage: the designated function's parameter list (drive's startup-decl
    dispatch, driver.lem:1743-1756, verbatim semantics; only the params
    are needed — the body is reached through `Eccall`). -/
def lookupFunParams (file1 : file core_run_annotation) (fsym : sym) :
    driverM (List (sym × core_base_type)) :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) fsym
      file1.funs with
  | some (Fun _ params _) => nd_return params
  | some (Proc _ _ _ params _) => nd_return params
  | some (ProcDecl _ _ _) => kill (Other (DErr_other
      "driveCall: the designated function has no definition"))
  | some (BuiltinDecl _ _ _) => kill (Other (DErr_other
      "driveCall: the designated function has no definition"))
  | none => kill (Other (DErr_other
      "driveCall: designated function not found"))

/-- Stage: the funinfo-declared C signature (return type, parameter C
    types) — the elaborated call site allocates the temporaries at the
    parameter types and the wrapper's `int main` returns the value. -/
def lookupSignature (file1 : file core_run_annotation) (fsym : sym) :
    driverM (ctype × List ctype) :=
  match fmapLookupBy (fun (s1 s2 : sym) => ordCompare s1 s2) fsym
      file1.funinfo with
  | some (_, _, retTy, ptys, _, _) => nd_return (retTy, List.map Prod.snd ptys)
  | none => kill (Other (DErr_other
      "driveCall: no funinfo for the designated function"))

/-- Stage: the refusals (header) — integer parameters and a `signed int`
    return only; count must match. Attributed, never a coercion. -/
def checkSignature (fname : String) (retTy : ctype) (ptys : List ctype) (nargs : Nat) :
    driverM Unit :=
  if ptys.length != nargs then
    kill (Other (DErr_other s!"driveCall: refused — {fname} declares {ptys.length} parameter(s) but {nargs} --call-args value(s) were given"))
  else if !(ptys.all is_integer) then
    kill (Other (DErr_other s!"driveCall: refused — {fname} has a non-integer parameter type; this harness entry renders the elaborated call site for INTEGER parameters only (translation.lem:948-953 conv_loaded_int); pointer/floating/aggregate arguments are not supported"))
  else if !(retTy == signed_int) then
    kill (Other (DErr_other s!"driveCall: refused — {fname} does not return signed int; the oracle twin (the rendered wrapper TU `int main(void) ... return f(...);`, scripts/test_verify.sh render_wrapper) returns the value unconverted only for int-returning functions"))
  else nd_return ()

/-- Stage: allocate and initialise errno — verbatim `drive`
    (driver.lem:1860-1868), BEFORE the call site runs (Z2-C-02). -/
def allocErrno [LemFuel] (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) (tid0 : Nat) :
    driverM CerbMem.PointerValue :=
  liftMem (nd_bind
    (CerbMem.allocateObject tagDefs tid0 (PrefOther "errno")
      (CerbMem.alignofIval tagDefs signed_int) signed_int none none)
    (fun (ptr_val : CerbMem.PointerValue) =>
      let zero := CerbMem.integerValueMval (Signed Int_)
        (CerbMem.integerIval (0 : Int))
      nd_bind
        (CerbMem.storeM tagDefs (CerbLocation.other "errno init")
          signed_int false ptr_val zero)
        (fun (_ : CerbMem.Footprint) => nd_return ptr_val)))

/-- Stage: park the rendered call site in thread 0's arena (drive's
    thread-state update, driver.lem:1870-1880, with `main_sym` := `fsym`),
    run the driver loop, finalize. -/
def callFinish [LemFuel] (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid0 : Nat) (fsym : sym) (callExpr : CE) (errno_ptr_val : CerbMem.PointerValue) :
    driverM driver_result :=
  nd_bind get_thread_states
    (fun (ths : List (Nat × (Option thread_id × thread_state))) =>
    match ths with
    | [(_, (_, th_st))] =>
        nd_bind (driver_update_thread_state tid0
          ({ arena := callExpr,
             stack0 := Stack_empty,
             errno := errno_ptr_val,
             current_loc := callLoc,
             exec_loc := ELoc_normal [(fsym, callLoc)],
             env := th_st.env,
             current_proc_opt := some fsym } : thread_state))
          (fun (_ : Unit) =>
        nd_bind (driver2 tagDefs false) (fun (_ : Unit) =>
        nd_bind nd_get (fun (dr_st' : driver_state) =>
        nd_return (finalize tagDefs "driveCall" dr_st'))))
    | _ => kill (Other (DErr_other
        "driveCall: not exactly one thread after globals")))

/-- THE FUNCTION-CALL ENTRY at the ND-computation level: run the
    globals, resolve `fname` and `conv_loaded_int`, check the signature,
    allocate errno, render the elaborated call site `f(args)` into thread
    0's arena, run the driver loop, finalize. Structure is `drive`
    (driver.lem:1727) with the documented substitutions (header) — every
    combinator is the generated driver's own. -/
def driveCall [LemFuel] (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) : driverM driver_result :=
  nd_bind (driver_globals tagDefs false file1) (fun (tid0 : Nat) =>
  nd_bind nd_get (fun (post_globals_dr_st : driver_state) =>
  let cf := post_globals_dr_st.core_file
  nd_bind (resolveFunSym cf fname) (fun (fsym : sym) =>
  -- the std.core function the elaborator calls by name (translation_aux.lem:347-348
  -- `mk_call "conv_loaded_int"` resolves through the `std` map = the linked
  -- file's `stdlib`, core_linking.lem `stdlib= f1.stdlib`)
  nd_bind (resolveSymIn cf.stdlib "std.core function" "conv_loaded_int") (fun (convSym : sym) =>
  nd_bind (lookupFunParams cf fsym) (fun (params : List (sym × core_base_type)) =>
  nd_bind (lookupSignature cf fsym) (fun (sig : ctype × List ctype) =>
  nd_bind (checkSignature fname sig.1 sig.2 args.length) (fun (_ : Unit) =>
  nd_bind (allocErrno tagDefs tid0) (fun (errno_ptr_val : CerbMem.PointerValue) =>
  let callExpr := mkCallSite convSym fsym (List.zip (params.map Prod.fst) sig.2) args sig.1
  callFinish tagDefs tid0 fsym callExpr errno_ptr_val))))))))

end CerbCall
