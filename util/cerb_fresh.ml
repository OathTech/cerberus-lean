(* Fork F-D fail-stop floor (arc-12).
   Design + probe evidence: lean_frontend/docs/2026-08-21_arc12-s0-floor-design.md.

   Since commit 8923d6436 the desugar stage mints symbol ids from its own
   0-based threaded supply (cabs_to_ail_effect.lem fresh_sym_supply) and no
   longer advances this ambient counter, so a translation unit whose desugar
   mints more ids than the counter's current value creates two DISTINCT
   symbols with equal (digest, num) — which compare EQUAL (symbol.lem
   symbolEqual ignores the description) and silently corrupt the Esave/Erun
   label machinery, environments and substitutions (finding F-D,
   tests/csmith_findings/README.md).

   This mirrors the Lean side's protection (lean_frontend/native/fresh_int.c:
   collision floor semantics) WITHOUT the 2^20 base displacement — the
   numbering of every in-margin program is bit-for-bit unchanged; the floor
   is a pair of pure comparisons:

     forward  — every ambient id handed out under the current digest must lie
                strictly above the desugar high-water mark M (set once per TU
                by the post-desugar pipeline hook, set_desugar_hwm);
     backward — at hook time, M must lie strictly below the FIRST ambient id
                drawn for this TU (tu_first): a mid-desugar ambient draw
                (mini_pipeline const-expr run seeds and their translation
                temporaries) at or below M means a collision already
                happened.

   A violation is a LOUD, distinguishable failure: one stderr line carrying
   the CERB_FRESH_FLOOR_VIOLATION token, exit code 70 (EX_SOFTWARE — chosen
   so harnesses can never fold it into the timeout/signal buckets).
   Renumbering (re-unifying the supplies) is deferred upstream-coordinated
   work; see the design note.

   TWO NARROW WARN-ONLY MODES (arc-12 D2 ruling; never silent — each prints
   one greppable stderr warning per TU instead of exiting):

   1. EXPORT MODE (`export_only_mode`, set ONLY by the driver's --cabs-json
      branch, backend/driver/main.ml). SOUNDNESS (D2 condition, verified):
      the exported artifact is the PRE-DESUGAR Cabs tree — main.ml:246
      destructures `(cabs_tunit, _)`, discarding the desugar+typing result;
      pipeline.ml:242-246 produces cabs_tunit from `parse` BEFORE `desugar`
      runs; the serializer (backend/lean_export/cabs_json.ml) is a pure
      function of that tree whose identifiers are (loc, string) pairs — no
      symbol numbers, no mutable state, no Tags/Cerb_fresh reads. A
      desugar-time collision therefore CANNOT alter the emitted JSON bytes
      (empirically confirmed: byte-identical export of a beyond-margin TU
      under counter base 0 vs base 2^20 — the S2 record). Residual, on
      record: a collision-corrupted const-expr could still flip the
      export's ERROR VERDICT (desugar hard-error class) — refusal-shaped,
      never wrong bytes.
   2. GRANDFATHER MODE (`grandfather_mode`, opt-in via the environment
      variable CERB_FRESH_FLOOR_GRANDFATHER=1). D2 Option-C mechanics for
      the two grandfathered gate lanes ONLY (test_libxml2_uri.sh
      ORACLE_LIBC; libc artifacts) — surfaces whose beyond-margin oracle
      elaboration is validated-by-agreement against the protected Lean
      side (uri 16/16, libc 7/7; register entries + record addenda carry
      the exposure numbers). Any other use is a finding. *)

let cur_filename = ref ""

(* D2 warn-only modes (see header). *)
let export_only_mode = ref false
let grandfather_mode =
  ref (match Sys.getenv_opt "CERB_FRESH_FLOOR_GRANDFATHER" with
       | Some "1" -> true | _ -> false)
(* one warning per TU, not per draw (the forward check fires on every
   ambient draw below the hwm — thousands per TU) *)
let warned_this_tu = ref false

(* desugar high-water mark + 1 for the current digest; 0 = no floor (never
   set, or a non-desugared input such as a .co file) *)
let floor = ref 0

(* first ambient id drawn since the last set_digest; -1 = none yet *)
let tu_first = ref (-1)

let floor_fail which n m =
  if !export_only_mode then begin
    if not !warned_this_tu then begin
      warned_this_tu := true;
      prerr_endline (Printf.sprintf
        "CERB_FRESH_FLOOR_WARNING (cabs-json export, %s): beyond-margin TU \
         '%s' (ambient id %d vs desugar range [0..%d]); export permitted — \
         the emitted artifact is the pre-desugar Cabs tree and cannot carry \
         the collision (verified sound, D2; see this file's header). The \
         exec/elaboration pipeline for this TU remains floored."
        which !cur_filename n m)
    end
  end else if !grandfather_mode then begin
    if not !warned_this_tu then begin
      warned_this_tu := true;
      prerr_endline (Printf.sprintf
        "CERB_FRESH_FLOOR_WARNING (grandfathered lane, %s): beyond-margin \
         TU '%s' (ambient id %d vs desugar range [0..%d]); proceeding \
         UN-FLOORED under the D2 grandfather ruling — this elaboration is \
         collision-EXPOSED and is trusted only via byte-agreement with the \
         protected Lean side (register entries + record addenda; mover: \
         renumbering-era re-derivation)."
        which !cur_filename n m)
    end
  end else begin
    prerr_endline (Printf.sprintf
      "CERB_FRESH_FLOOR_VIOLATION (%s): ambient symbol id %d collides with \
       the desugar-threaded id range [0..%d] of '%s' — this translation unit \
       exceeds the fork oracle's symbol-id margin; refusing to continue (the \
       un-floored oracle would silently corrupt symbol identity: finding F-D, \
       tests/csmith_findings/README.md; design: \
       lean_frontend/docs/2026-08-21_arc12-s0-floor-design.md)."
      which n m !cur_filename);
    exit 70
  end

let int : unit -> int =
  let counter = ref (-1) in
  fun () ->
    assert (!counter <> max_int);
    incr counter;
    let n = !counter in
    if !tu_first < 0 then tu_first := n;
    if n < !floor then floor_fail "forward" n (!floor - 1);
    n

let digest, set_digest =
  let digest = ref "" in
  (fun () -> !digest),
  (fun filename ->
    digest := Digest.file filename;
    cur_filename := filename;
    floor := 0;
    tu_first := (-1);
    warned_this_tu := false)

(* Post-desugar pipeline hook (backend/common/pipeline.ml c_frontend):
   m = max symbol id occurring in the desugared Ail program
   (Ail_sym_hwm.max_sym_program; -1 when the program contains no ids). *)
let set_desugar_hwm m =
  if !tu_first >= 0 && m >= !tu_first then floor_fail "backward" !tu_first m;
  floor := m + 1
