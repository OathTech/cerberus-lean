(* Fork single-supply symbol-id backstop (arc-13; supersedes the arc-12
   two-check floor). Design + probe evidence:
   lean_frontend/docs/2026-08-22_arc13-s0-scheme-decision.md.

   HISTORY. Commit 8923d6436 (April 2026) threaded the desugar stage's
   symbol supply through desugM for the Lean target's sake and — contrary
   to its own commit message — also moved the OCAML oracle's desugar
   draws off this counter, splitting symbol minting into two 0-based-vs-
   ambient streams whose overlap was finding F-D: two DISTINCT symbols
   with equal (digest, num) compare EQUAL (symbol.lem symbolEqual ignores
   the description) and silently corrupt the Esave/Erun label machinery,
   environments and substitutions (tests/csmith_findings/README.md).
   Arc-12 made the overlap FAIL-STOP (the two-check dynamic floor).
   Arc-13 D1 removed the second stream entirely: the ocaml target_reps in
   cabs_to_ail_effect.lem / core_run.lem / core_run_aux.lem
   (ocaml_frontend/fork_renumber.ml) route desugar and run-time minting
   back through this single counter, exactly as un-forked upstream.
   Collisions are impossible by construction — one supply, every id a
   distinct draw — and oracle numbering is byte-identical to upstream's
   (S0 probe: 11/11 fixtures incl. the libc.co dump).

   THE BACKSTOP (this file + backend/common/ail_sym_hwm.ml +
   backend/common/pipeline.ml): the single-supply invariant is checked
   at the DESUGAR seam, never assumed there. SCOPE (narrowed at the
   arc-13 audit, finding A-F1): this is a check of the desugar-stage
   supply (Cabs_to_ail_effect.fresh_sym_int) in both directions; the
   RUN-seam shims (Core_run.fresh_symbol',
   Core_run_aux.initial_core_run_state) have no dynamic check — run
   symbols pass no hand chokepoint outside the shims themselves. The
   run seams' defense is the fork-drift gate: re-threading them at the
   source level changes the generated OCaml call sites and trips the
   layer-2 hash pins (scripts/check_fork_drift.sh,
   scripts/fork_drift_manifest.txt notes). At the post-desugar hook,
   every symbol carrying the CURRENT TU's digest in the desugared Ail
   program must have been minted by this counter inside this TU's
   window:

       tu_first <= num <= last_issued

   - a symbol BELOW the window means a supply was re-threaded 0-based
     (the F-D-era scheme; the plant test simulates exactly that);
   - a symbol ABOVE the window means ids minted from nowhere;
   - a post-hook draw at or below the recorded Ail maximum (forward
     check) means the counter went backwards (re-init regression).

   All three fail LOUD: one stderr line carrying the
   CERB_FRESH_FLOOR_VIOLATION token, exit 70 (EX_SOFTWARE — never
   foldable into the harness timeout/signal buckets; harness class
   CERB_FLOOR). Acceptance property (arc-13 charter): the backstop NEVER
   fires on any in-tree input — the arc-12 refusal class is gone, and
   with it the arc-12 warn-only modes (cabs-json export, grandfather):
   both DELETED as dead code, grandfather register G1-G4 dissolved. *)

let cur_filename = ref ""

(* first id drawn since the last set_digest; -1 = none yet *)
let tu_first = ref (-1)

(* last id issued (process-global, monotone); -1 = none yet *)
let last_issued = ref (-1)

(* forward backstop: current TU's max Ail symbol num + 1 (0 = unset /
   non-desugared input such as a .co file) *)
let floor = ref 0

let floor_fail which n lo hi =
  prerr_endline (Printf.sprintf
    "CERB_FRESH_FLOOR_VIOLATION (%s): symbol id %d is outside the \
     single-supply window [%d..%d] of '%s' — a symbol supply has been \
     re-threaded off Cerb_fresh.int (the F-D-era split-stream scheme, \
     finding F-D: tests/csmith_findings/README.md) or the counter was \
     re-initialized; refusing to continue. Scheme + backstop design: \
     lean_frontend/docs/2026-08-22_arc13-s0-scheme-decision.md."
    which n lo hi !cur_filename);
  exit 70

let int : unit -> int =
  let counter = ref (-1) in
  fun () ->
    assert (!counter <> max_int);
    incr counter;
    let n = !counter in
    if !tu_first < 0 then tu_first := n;
    if n < !floor then floor_fail "forward" n !floor !last_issued;
    last_issued := n;
    n

let digest, set_digest =
  let digest = ref "" in
  (fun () -> !digest),
  (fun filename ->
    digest := Digest.file filename;
    cur_filename := filename;
    floor := 0;
    tu_first := (-1))

(* Post-desugar pipeline hook (backend/common/pipeline.ml c_frontend):
   (min_sym, max_sym) = the min/max symbol num of the CURRENT TU digest
   occurring in the desugared Ail program (Ail_sym_hwm.sym_window_program;
   (-1, -1) when the program carries no current-digest symbols — then the
   window check is vacuous and only the forward backstop arms). *)
let check_ail_window ~min_sym ~max_sym =
  if min_sym >= 0 then begin
    if !tu_first < 0 then
      (* current-digest symbols exist but nothing was ever drawn: a
         fully off-counter supply *)
      floor_fail "window-nodraw" min_sym 0 (-1)
    else begin
      if min_sym < !tu_first then
        floor_fail "window-low" min_sym !tu_first !last_issued;
      if max_sym > !last_issued then
        floor_fail "window-high" max_sym !tu_first !last_issued
    end
  end;
  floor := max_sym + 1
