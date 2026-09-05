#!/usr/bin/env bash
# check_fuel_forms.sh — the consumer's (A)/(B)/(C) requirement made mechanical
# (fuel-parameter arc C2, 2026-09-04; refined-cerberus
# docs/2026-09-04_review-of-fuel-parameter-design.md §2).
#
# Every fuel'd worker in the compiled environment is CLASSIFIED by the Lean tool
# lean_frontend/test/Unit/FuelFormsTool.lean (run under `lake env`, importing
# the exec entries, every generated *_auxiliary module and every
# *_lemMeasureProofs module — the obligation carriers):
#   MEASURED   — its `<f>_measure_sufficient` obligation exists AND has the
#                contract's SHAPE (∀ …, [lemHyp : H →] μ ≤ lemFuel → worker lemFuel …
#                = wrapper …, heads compared by constant name — audit M1; the fuel
#                binder pinned by its NAME `lemFuel` and the optional hypothesis by
#                its reserved NAME `lemHyp` immediately before it — lem audit N1 /
#                C4; and — P0 audit F2, 2026-09-05 — the ARGUMENT CORRESPONDENCE:
#                the wrapper side is the wrapper on exactly the statement's
#                binders in order, the worker side passes `lemFuel` once at the
#                worker's own `lemFuel` parameter and otherwise only the
#                wrapper's input binders, and the WRAPPER'S OWN BODY unfolds on
#                those binders to the worker on those very arguments with the
#                hypothesis' μ at the fuel position — so the audit's decoy
#                `review_shift_lemFuel lemFuel 0 = review_shift x` is rejected
#                for its literal `0`; a same-named constant of another shape is
#                MALFORMED and RED here); this script additionally requires the reported axiom cones
#                (obligation AND proof) to be ⊆ [propext, Classical.choice, Quot.sound],
#                AND, for every row measured UNDER A HYPOTHESIS (the tool's `hyp`
#                column = the `lemHyp` binder's type, pretty-printed), a row of the
#                REVIEWED register scripts/fuel_hypotheses.txt naming that worker
#                and that exact hypothesis with the frontend invariant it rests on
#                (`.lem:<line>` cite) and a reviewer — BOTH directions (a stale
#                register row is RED too). Why (lem-lean measure-hypothesis record
#                §2.3/§10, its pre-merge audit F1): a CONTRADICTORY hypothesis
#                (`b < b`, `x ≠ x`) passes generation and makes the obligation
#                vacuously provable while the fuel-free wrapper ships MEASURED;
#                satisfiability is undecidable at the gate, so the register is the
#                closure — --selftest's P10 compiles exactly such a decoy (the real
#                CerbMem.alignofCtype obligation under `cty ≠ cty`) and shows the
#                register turning it RED;
#   ABSORBING  — "kill at zero" (P0 relabel, 2026-09-05: propagation of exhaustion
#                through the successor cases is NOT proved — lem-lean TODO row 13,
#                fuel monotonicity): its `_zero` lemma states the WORKER (left-hand
#                head by name) at the literal fuel 0 on its own binders (each once;
#                P0 audit F2 — the audit's decoy `review_bad_lemFuel_zero` stated a
#                fact about CerbND.runNDFuel and was counted ABSORBING), and the
#                RHS is the monad's absorbing element at the fuel atom (ND kill /
#                runner Killed / undefined-monad Error) with no value sentinel;
#                this script additionally requires the lemma's axiom cone ⊆ the
#                standard three (same standard as MEASURED). A same-named lemma of
#                another shape is MALFORMED-ZERO and RED;
#   AMBIENT    — neither; RED iff reachable from the drive cone (kernel constant
#                closure of drive/initial_driver_state/the CerbND runners/
#                CerbCall.driveCall, closed under mutual blocks) and NOT a row of
#                scripts/fuel_forms_pending.txt; a pending row that is no longer
#                reachable-ambient is RED too (stale pin) — the register moves
#                only by explicit edit, both directions.
# Vacuity guards: ≥ 60 workers, ≥ 30 measured, ≥ 10 absorbing, the tool's
# summary line present, and the four forms PARTITION the table (their counts
# sum to the worker count — audit M2). `--selftest` plants on a scratch copy
# of the table (a new reachable ambient worker, a stale pending pin, a
# measured obligation with a bad axiom cone, an ABSORBING lemma with a bad
# cone, a truncated table, a phantom pending-register row), on a scratch copy
# of the HYPOTHESIS register (a measured-under-hypothesis worker whose row is
# deleted; a stale row; a row without a `.lem:` cite), and COMPILES decoy
# modules in a scratch dir outside the tree: the C4 four (right name / type
# True; right shape / wrong worker constant; a real obligation restated under
# the CONTRADICTORY hypothesis `cty ≠ cty` — counted MEASURED, the REGISTER
# turns RED; a decoy of a real obligation with an extra Prop binder) and the
# P0 audit-F2 battery (the audit's two decoys verbatim, wrong fuel position,
# swapped arguments either side, changed measure, wrapper calling another
# worker, hidden premise, three _zero decoys incl. a POSITIVE control) — every
# decoy's table row must carry ITS OWN rejection message. Nothing in the tree is touched. The
# tool itself fails closed if an entry constant is missing or the table is
# vacuous. Reachability is the KERNEL constant closure: it stops at
# opaque/implemented_by/extern seams — the population of those is pinned by
# the axiom census (scripts/unsafebaseio_allowlist.txt, both directions), and
# none of them calls a fuel'd worker (C2 audit §2); `partial` is banned on the
# exec cone's generated modules by check_exec_totality.sh.
set -uo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$SCRIPT_DIR/.."
LF="$ROOT/lean_frontend"
PENDING="$SCRIPT_DIR/fuel_forms_pending.txt"
HYPREG="$SCRIPT_DIR/fuel_hypotheses.txt"
CAPPED="$SCRIPT_DIR/capped"

# table_of_tree <log>: builds the tool and runs it; the table on stdout, the
# build's and the tool's diagnostics captured in <log> (never discarded —
# "never 2>/dev/null an install/build step"; the caller prints the tail on
# failure). Extra module names/dirs for the selftest's plants via
# FUELFORMS_EXTRA_MODULES / FUELFORMS_EXTRA_PATH.
table_of_tree() {
  local log="$1" aux
  # every obligation carrier: the generated *_auxiliary modules AND every
  # *_lemMeasureProofs module (the hand-written seam obligations of
  # CerbMem_lemMeasureProofs are imported by nothing else)
  aux=$(cd "$LF" && ls generated/*_auxiliary.lean generated/*_lemMeasureProofs.lean | xargs -n1 basename | sed 's/\.lean$//')
  # FUELFORMS_EXCLUDE_MODULES (selftest only): drop a carrier so a decoy of a
  # REAL obligation can be compiled in its place (P11)
  for ex in ${FUELFORMS_EXCLUDE_MODULES:-}; do aux=$(echo "$aux" | grep -vx "$ex"); done
  if ! (cd "$LF" && "$CAPPED" lake build fuel-forms-tool >> "$log" 2>&1); then
    echo "check_fuel_forms: FAIL — could not build fuel-forms-tool (log tail follows)"; tail -20 "$log"; return 1
  fi
  # shellcheck disable=SC2086
  (cd "$LF" && "$CAPPED" lake env bash -c 'LEAN_PATH="${FUELFORMS_EXTRA_PATH:+$FUELFORMS_EXTRA_PATH:}$LEAN_PATH" exec ./.lake/build/bin/fuel-forms-tool "$@"' _ Driver CerbCall CerbND Main $aux ${FUELFORMS_EXTRA_MODULES:-} 2>> "$log")
}

# policy <table-file> <pending-file> <hypotheses-register>: prints verdict lines, returns 0/1
policy() {
  local tbl="$1" pend="$2" hreg="$3"
  local rc=0
  if ! grep -q '^FUEL_FORMS_SUMMARY' "$tbl"; then
    echo "check_fuel_forms: FAIL — no FUEL_FORMS_SUMMARY line (the tool did not complete; fail-closed)"; return 1
  fi
  local n_all n_meas n_abs
  n_all=$(grep -c '^FUEL_FORM	' "$tbl"); n_meas=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="MEASURED"' "$tbl" | wc -l); n_abs=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="ABSORBING"' "$tbl" | wc -l)
  if (( n_all < 60 || n_meas < 30 || n_abs < 10 )); then
    echo "check_fuel_forms: FAIL — vacuity guard: workers=$n_all measured=$n_meas absorbing=$n_abs (expected ≥60/≥30/≥10)"; return 1
  fi
  # measured rows: every axiom verdict must be ok
  local badax
  badax=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="MEASURED" && $5 !~ /axioms=ok/ {print $2" :: "$5} $1=="FUEL_FORM" && $3=="MEASURED" && $5 ~ /BAD\[/ {print $2" :: "$5}' "$tbl" | sort -u)
  if [[ -n "$badax" ]]; then
    echo "check_fuel_forms: FAIL — measured obligation(s) with an axiom cone outside [propext, Classical.choice, Quot.sound] (or no proof constant):"; echo "$badax" | sed 's/^/  /'; rc=1
  fi
  # ABSORBING rows: the _zero lemma's cone, same standard (P0 audit F2)
  local badzax
  badzax=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="ABSORBING" && $5 !~ /axioms=ok/ {print $2" :: "$5}' "$tbl" | sort -u)
  if [[ -n "$badzax" ]]; then
    echo "check_fuel_forms: FAIL — ABSORBING _zero lemma(s) with an axiom cone outside [propext, Classical.choice, Quot.sound] (or no cone reported):"; echo "$badzax" | sed 's/^/  /'; rc=1
  fi
  # (A delegated `proof=` constant is reported where one exists — the generated
  # obligations delegate to <Module>_lemMeasureProofs — but is not required: the
  # hand-written seam obligations in CerbMem_lemMeasureProofs ARE their own
  # proof, and the obligation's axiom cone covers its proof transitively.)
  # M1: a same-named constant that is NOT the contract's statement
  local malformed
  malformed=$(awk -F'\t' '$1=="FUEL_FORM" && $5 ~ /^MALFORMED obligation/ {print $2" :: "$5}' "$tbl")
  if [[ -n "$malformed" ]]; then
    echo "check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …, argument correspondence against the wrapper's body) — never MEASURED:"; echo "$malformed" | sed 's/^/  /'; rc=1
  fi
  # P0 audit F2: a same-named _zero lemma that is NOT the worker at literal 0 on its own binders
  local malzero
  malzero=$(awk -F'\t' '$1=="FUEL_FORM" && $5 ~ /^MALFORMED-ZERO/ {print $2" :: "$5}' "$tbl")
  if [[ -n "$malzero" ]]; then
    echo "check_fuel_forms: FAIL — lemma(s) named <worker>_zero whose statement is not \`worker … 0 … = <absorbing element>\` on the worker's own binders — never ABSORBING:"; echo "$malzero" | sed 's/^/  /'; rc=1
  fi
  # C4: the hypotheses in force vs the reviewed register, both directions.
  # Table side: (worker, hyp) of every MEASURED row with a non-empty hyp column.
  # Register side: (worker, hyp) of every data row, hyp whitespace-normalized;
  # a data row must have 4 TAB fields, a `.lem:<line>` cite in field 3 and a
  # non-blank reviewer in field 4.
  if [[ ! -f "$hreg" ]]; then echo "check_fuel_forms: FAIL — hypothesis register $hreg missing (fail-closed)"; return 1; fi
  local hyps_tbl hyps_reg badreg
  hyps_tbl=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="MEASURED" && NF>=6 && $6!="" {print $2"\t"$6}' "$tbl" | sort -u)
  hyps_reg=$(grep -v '^\s*#' "$hreg" | awk -F'\t' 'NF>=2 {h=$2; gsub(/[ \t]+/," ",h); sub(/^ /,"",h); sub(/ $/,"",h); print $1"\t"h}' | sort -u)
  badreg=$(grep -v '^\s*#' "$hreg" | awk -F'\t' 'NF>0 && (NF!=4 || $3 !~ /\.lem:[0-9]/ || $4 ~ /^[ \t]*$/) {print $1}')
  if [[ -n "$badreg" ]]; then
    echo "check_fuel_forms: FAIL — hypothesis register row(s) not of the form <worker> TAB <hyp> TAB <invariant with a .lem:<line> cite> TAB <reviewer>:"; echo "$badreg" | sed 's/^/  /'; rc=1
  fi
  local hnew hstale
  hnew=$(comm -23 <(echo "$hyps_tbl" | grep .) <(echo "$hyps_reg" | grep .))
  hstale=$(comm -13 <(echo "$hyps_tbl" | grep .) <(echo "$hyps_reg" | grep .))
  if [[ -n "$hnew" ]]; then
    echo "check_fuel_forms: FAIL — worker(s) MEASURED under a hypothesis with no reviewed register row for that exact hypothesis in $HYPREG (worker TAB hypothesis):"; echo "$hnew" | sed 's/^/  /'; rc=1
  fi
  if [[ -n "$hstale" ]]; then
    echo "check_fuel_forms: FAIL — hypothesis register row(s) whose worker is not MEASURED under that exact hypothesis (stale register row; edit the register):"; echo "$hstale" | sed 's/^/  /'; rc=1
  fi
  local n_hyp
  n_hyp=$(echo "$hyps_tbl" | grep -c .)
  # M2: the four forms partition the table
  local n_amb_yes n_amb_no
  n_amb_yes=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="AMBIENT" && $4 ~ /^yes/' "$tbl" | wc -l); n_amb_no=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="AMBIENT" && $4 ~ /^no/' "$tbl" | wc -l)
  if (( n_meas + n_abs + n_amb_yes + n_amb_no != n_all )); then
    echo "check_fuel_forms: FAIL — the forms do not partition the table: $n_meas MEASURED + $n_abs ABSORBING + $n_amb_yes ambient-reachable + $n_amb_no ambient-unreachable ≠ $n_all workers (an unexpected form/reach string; fail-closed)"; rc=1
  else
    echo "check_fuel_forms: forms partition OK ($n_meas MEASURED + $n_abs ABSORBING + $n_amb_yes ambient-reachable + $n_amb_no ambient-unreachable = $n_all fuel'd workers)"
  fi
  local reach_amb pinned
  reach_amb=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="AMBIENT" && $4 ~ /^yes/ {print $2}' "$tbl" | sort -u)
  pinned=$(grep -v '^\s*#' "$pend" | awk 'NF>0 {print $1}' | sort -u)
  local new stale
  new=$(comm -23 <(echo "$reach_amb") <(echo "$pinned"))
  stale=$(comm -13 <(echo "$reach_amb") <(echo "$pinned"))
  if [[ -n "$new" ]]; then
    echo "check_fuel_forms: FAIL — fuel'd worker(s) REACHABLE from drive with an opaque (fail-open) exhaustion, not in $PENDING:"; echo "$new" | sed 's/^/  /'; rc=1
  fi
  if [[ -n "$stale" ]]; then
    echo "check_fuel_forms: FAIL — pending register row(s) no longer a reachable ambient worker (stale pin; edit the register):"; echo "$stale" | sed 's/^/  /'; rc=1
  fi
  if (( rc == 0 )); then
    local n_pend n_unr
    n_pend=$(echo "$reach_amb" | grep -c .); n_unr=$(awk -F'\t' '$1=="FUEL_FORM" && $3=="AMBIENT" && $4 ~ /^no/' "$tbl" | wc -l)
    echo "check_fuel_forms: OK ($n_all fuel'd workers: $n_meas MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; $n_hyp of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), $n_abs ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), $n_pend reachable-AMBIENT = the $n_pend rows of fuel_forms_pending.txt exactly, $n_unr ambient unreachable from the drive cone)"
  fi
  return $rc
}

TBL=$(mktemp); LOG="${TBL}.log"; PLANTDIR=$(mktemp -d); trap 'rm -rf "$TBL" "${TBL}.p" "${TBL}.pend" "${TBL}.hreg" "$LOG" "$PLANTDIR"' EXIT
if ! table_of_tree "$LOG" > "$TBL"; then echo "check_fuel_forms: FAIL — the classifier tool failed (fail-closed); diagnostics tail:"; tail -20 "$LOG"; exit 1; fi

if [[ "${1:-}" == "--selftest" ]]; then
  echo "check_fuel_forms: SELFTEST — plants on a scratch copy of the classification table (loud plant banner; nothing in the tree is touched)"
  fails=0
  plant() { # <label> <expected-substring> <table-file> <pending-file> <hypotheses-register>
    local out; out=$(policy "$3" "$4" "$5" 2>&1); local rc=$?
    if (( rc != 0 )) && grep -q -- "$2" <<<"$out"; then echo "  PLANT OK   [$1] -> $(grep -m1 -- "$2" <<<"$out")"; else echo "  PLANT FAIL [$1]: rc=$rc"; echo "$out" | sed 's/^/      /'; fails=$((fails+1)); fi
  }
  # P1: a measured, reachable worker flipped to ambient -> new reachable ambient
  sed 's/^\(FUEL_FORM\tstep_eval_pexpr_lemFuel\t\)MEASURED\t/\1AMBIENT\t/' "$TBL" > "${TBL}.p"; plant "P1 measured->ambient reachable (step_eval_pexpr)" "REACHABLE from drive with an opaque" "${TBL}.p" "$PENDING" "$HYPREG"
  # P2: a pending row vanishes from the table (e.g. it became measured) -> stale pin
  grep -v $'^FUEL_FORM\thack_lemFuel\t' "$TBL" > "${TBL}.p"; plant "P2 stale pending pin (hack removed from the table)" "stale pin" "${TBL}.p" "$PENDING" "$HYPREG"
  # P3: a measured obligation with sorryAx in its cone
  sed 's/^\(FUEL_FORM\tin_pattern_lemFuel\tMEASURED\t[^\t]*\t\)obligation=\([^ ]*\) axioms=ok/\1obligation=\2 axioms=BAD[[sorryAx]]/' "$TBL" > "${TBL}.p"; plant "P3 measured obligation with sorryAx in its cone" "axiom cone outside" "${TBL}.p" "$PENDING" "$HYPREG"
  # P4: truncated table (no summary)
  grep -v '^FUEL_FORMS_SUMMARY' "$TBL" > "${TBL}.p"; plant "P4 truncated table" "no FUEL_FORMS_SUMMARY" "${TBL}.p" "$PENDING" "$HYPREG"
  # P5: a phantom register row
  { cat "$PENDING"; echo "phantom_lemFuel pure-loop planted"; } > "${TBL}.pend"; plant "P5 phantom pending-register row" "stale pin" "$TBL" "${TBL}.pend" "$HYPREG"
  # P6/P7 (audit M1): decoy obligations COMPILED into scratch modules outside the
  # tree and appended to the tool's imports — the tool must classify by SHAPE.
  # P6: right NAME, type `True` (to_pure). P7: right name, right shape (Eq,
  # `_ ≤ lemFuel` hypothesis, right wrapper) but the WRONG worker constant on
  # the left (to_pures). (Until C4 these decoys used CerbMem.sizeofCtype /
  # alignofCtype, which are real measured obligations now — a decoy of a real
  # obligation would be a duplicate constant, not a plant.)
  # P10 (C4; lem audit F1): right name, right SHAPE, the hypothesis-carrying form
  # under a CONTRADICTORY hypothesis — the tool counts it MEASURED (the gate
  # cannot decide satisfiability); the REGISTER has no row for it, so the
  # policy is RED: the consumer-side closure of the lem slice's F1. Since the
  # P0 repair it is the real CerbMem.alignofCtype obligation under `cty ≠ cty`,
  # compiled in the P11 run below (see the note there).
  cat > "$PLANTDIR/FuelFormsPlantTrue.lean" <<'LEAN'
import Core_aux
theorem to_pure_measure_sufficient : True := trivial
LEAN
  cat > "$PLANTDIR/FuelFormsPlantWorker.lean" <<'LEAN'
import Core_aux
theorem to_pures_measure_sufficient {a : Type} [LemFuel] (l : List (expr a)) (lemFuel : Nat)
    (_lemMeasureLe : List.length l ≤ lemFuel) :
    to_pures l = to_pures l := rfl
LEAN
  # (P0 2026-09-05: the C4-era P10 decoy stated `hack` — an AMBIENT worker whose
  # wrapper calls it at `LemFuel.fuel` — under `0 ≤ lemFuel`; the argument/
  # measure correspondence check now rejects that as MALFORMED before the
  # register is consulted, which is right. P10 therefore restates the REAL
  # CerbMem.alignofCtype obligation — shape-correct, μ = the wrapper's measure —
  # under the CONTRADICTORY hypothesis `cty ≠ cty`, compiled in the P11 run
  # where CerbMem_lemMeasureProofs is excluded.)
  cat > "$PLANTDIR/FuelFormsPlantContra.lean" <<'LEAN'
import CerbMem
theorem CerbMem.alignofCtype_measure_sufficient (ambient : CerbTags.TagDefsMap) (cty : ctype)
    (lemHyp : cty ≠ cty) (lemFuel : Nat)
    (_lemMeasureLe : CerbTagsWf.envBound ambient cty ≤ lemFuel) :
    CerbMem.alignofCtype_lemFuel lemFuel ambient ambient cty = CerbMem.alignofCtype ambient cty :=
  absurd rfl lemHyp
LEAN
  # P12–P22 (P0 audit F2, 2026-09-05; record docs/2026-09-05_p0-instruments-record.md
  # §F2): the audit's two decoys VERBATIM (ReviewFuelDecoy.lean in the audit's
  # evidence dir) plus the audit's listed extra plants, as fresh decoy
  # workers/wrappers so no real row is disturbed. Each must be MALFORMED (never
  # MEASURED/ABSORBING) for ITS OWN reason — the table row's detail is checked
  # for the specific message, not just the policy's rc. pl_zt is a POSITIVE
  # control: a correctly shaped _zero lemma on a decoy worker must be ABSORBING
  # with axioms=ok (else the negative _zero plants prove nothing).
  cat > "$PLANTDIR/FuelFormsPlantAudit.lean" <<'LEAN'
import CerbND

-- audit decoy 1 (verbatim): a _zero lemma about a DIFFERENT constant
def review_bad_lemFuel (fuel : Nat) : Nat := fuel
theorem review_bad_lemFuel_zero {a info err cs st : Type}
    (m : ndM a info err cs st) (st0 : st) :
    CerbND.runNDFuel 0 m st0 =
      [(nd_status.Killed st0 CerbND.fuelExhaustedKill, [], st0)] := rfl

-- audit decoy 2 (verbatim): the worker at a literal `0`, the wrapper's input `x` never reaches it
def review_shift_lemFuel (fuel x : Nat) : Nat := x - fuel
def review_shift (x : Nat) : Nat := 0 * x
theorem review_shift_measure_sufficient (x : Nat) (lemFuel : Nat)
    (_lemMeasureLe : 0 ≤ lemFuel) :
    review_shift_lemFuel lemFuel 0 = review_shift x := by
  simp [review_shift_lemFuel, review_shift]

-- P14 wrong fuel position: lemFuel passed where the worker takes `a`
def pl_pos_lemFuel (lemFuel : Nat) (a : Nat) (b : Int) : Int := b
def pl_pos (a : Nat) (b : Int) : Int := pl_pos_lemFuel (a + 1) a b
theorem pl_pos_measure_sufficient (a : Nat) (b : Int) (lemFuel : Nat) (_lemMeasureLe : a + 1 ≤ lemFuel) :
    pl_pos_lemFuel a lemFuel b = pl_pos a b := rfl

-- P15 swapped arguments on the worker side (the wrapper passes a b; the obligation passes b a)
def pl_swap_lemFuel (lemFuel : Nat) (a b : Nat) : Nat := 0
def pl_swap (a b : Nat) : Nat := pl_swap_lemFuel (a + b) a b
theorem pl_swap_measure_sufficient (a b : Nat) (lemFuel : Nat) (_lemMeasureLe : a + b ≤ lemFuel) :
    pl_swap_lemFuel lemFuel b a = pl_swap a b := rfl

-- P16 swapped arguments on the wrapper side
def pl_swapw_lemFuel (lemFuel : Nat) (a b : Nat) : Nat := 0
def pl_swapw (a b : Nat) : Nat := pl_swapw_lemFuel (a + b) a b
theorem pl_swapw_measure_sufficient (a b : Nat) (lemFuel : Nat) (_lemMeasureLe : a + b ≤ lemFuel) :
    pl_swapw_lemFuel lemFuel a b = pl_swapw b a := rfl

-- P17 changed measure: the hypothesis' lower bound `a` is not the wrapper's `a + 1`
def pl_mu_lemFuel (lemFuel : Nat) (a : Nat) : Nat := 0
def pl_mu (a : Nat) : Nat := pl_mu_lemFuel (a + 1) a
theorem pl_mu_measure_sufficient (a : Nat) (lemFuel : Nat) (_lemMeasureLe : a ≤ lemFuel) :
    pl_mu_lemFuel lemFuel a = pl_mu a := rfl

-- P18 renamed worker / changed wrapper RHS: the wrapper calls a DIFFERENT worker
def pl_rhs_lemFuel (lemFuel : Nat) (a : Nat) : Nat := 0
def pl_rhs_other_lemFuel (lemFuel : Nat) (a : Nat) : Nat := 0
def pl_rhs (a : Nat) : Nat := pl_rhs_other_lemFuel (a + 1) a
theorem pl_rhs_measure_sufficient (a : Nat) (lemFuel : Nat) (_lemMeasureLe : a + 1 ≤ lemFuel) :
    pl_rhs_lemFuel lemFuel a = pl_rhs a := rfl

-- P19 hidden extra premise inside the `≤ lemFuel` binder
def pl_prem_lemFuel (lemFuel : Nat) (a : Nat) : Nat := 0
def pl_prem (a : Nat) : Nat := pl_prem_lemFuel (a + 1) a
theorem pl_prem_measure_sufficient (a : Nat) (lemFuel : Nat) (_lemMeasureLe : a + 1 ≤ lemFuel ∧ a = 0) :
    pl_prem_lemFuel lemFuel a = pl_prem a := rfl

-- P20 POSITIVE CONTROL: a correctly shaped _zero lemma on a decoy worker (ABSORBING)
def pl_zt_lemFuel {a info err cs st : Type} (lemFuel : Nat) (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) := CerbND.runNDFuel lemFuel m st0
theorem pl_zt_lemFuel_zero {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    pl_zt_lemFuel 0 m st0 = [(nd_status.Killed st0 CerbND.fuelExhaustedKill, [], st0)] := rfl

-- P21 _zero lemma with a TERM (st0 + 1) where a binder must be
def pl_ztb_lemFuel {a info err cs : Type} (lemFuel : Nat) (m : ndM a info err cs Nat) (st0 : Nat) :
    List (nd_status a err Nat × List String × Nat) := CerbND.runNDFuel lemFuel m st0
theorem pl_ztb_lemFuel_zero {a info err cs : Type} (m : ndM a info err cs Nat) (st0 : Nat) :
    pl_ztb_lemFuel 0 m (st0 + 1) = [(nd_status.Killed (st0 + 1) CerbND.fuelExhaustedKill, [], st0 + 1)] := rfl

-- P22 _zero lemma not at fuel 0 (the worker ignores its fuel, so the equation holds at 1)
def pl_ztc_lemFuel {a info err cs st : Type} (lemFuel : Nat) (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) := CerbND.runNDFuel 0 m st0
theorem pl_ztc_lemFuel_zero {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    pl_ztc_lemFuel 1 m st0 = [(nd_status.Killed st0 CerbND.fuelExhaustedKill, [], st0)] := rfl
LEAN
  for m in FuelFormsPlantTrue FuelFormsPlantWorker FuelFormsPlantContra FuelFormsPlantAudit; do
    if ! (cd "$LF" && "$CAPPED" lake env lean --root="$PLANTDIR" -o "$PLANTDIR/$m.olean" "$PLANTDIR/$m.lean" >> "$LOG" 2>&1); then
      echo "  PLANT FAIL [compiling $m]"; tail -20 "$LOG"; fails=$((fails+1))
    fi
  done
  # row_detail <label> <worker> <form> <detail-substring> <table>: the tool's row for
  # <worker> has the declared form AND its detail carries the specific message
  row_detail() {
    local row; row=$(grep -E "^FUEL_FORM	$2	" "$5")
    if [[ -n "$row" ]] && [[ "$(cut -f3 <<<"$row")" == "$3" ]] && grep -qF -- "$4" <<<"$(cut -f5 <<<"$row")"; then
      echo "  PLANT OK   [$1] -> $2 $3: $(cut -f5 <<<"$row" | cut -c1-230)"
    else
      echo "  PLANT FAIL [$1]: wanted $2 $3 with detail containing '$4'; row: ${row:-<none>}"; fails=$((fails+1))
    fi
  }
  if FUELFORMS_EXTRA_PATH="$PLANTDIR" FUELFORMS_EXTRA_MODULES="FuelFormsPlantTrue FuelFormsPlantWorker FuelFormsPlantAudit" table_of_tree "$LOG" > "${TBL}.p"; then
    grep -E $'^FUEL_FORM\t(to_pure_lemFuel|to_pures_lemFuel)\t' "${TBL}.p" | cut -c1-220 | sed 's/^/    plant table: /'
    plant "P6 decoy obligation of type True (to_pure)" "not the contract's shape" "${TBL}.p" "$PENDING" "$HYPREG"
    plant "P7 decoy obligation with the wrong worker constant (to_pures)" "not the contract's shape" "${TBL}.p" "$PENDING" "$HYPREG"
    row_detail "P12 audit decoy 1: _zero lemma about CerbND.runNDFuel, not the worker" review_bad_lemFuel AMBIENT "MALFORMED-ZERO zero=review_bad_lemFuel_zero: left-hand head \`CerbND.runNDFuel\` is not the worker \`review_bad_lemFuel\`" "${TBL}.p"
    plant "P12 policy: a MALFORMED-ZERO lemma is RED" "named <worker>_zero whose statement is not" "${TBL}.p" "$PENDING" "$HYPREG"
    row_detail "P13 audit decoy 2: worker at literal 0, wrapper input x never passed" review_shift_lemFuel AMBIENT "worker argument #1 is \`0\`, not one of the wrapper's input binders" "${TBL}.p"
    row_detail "P14 wrong fuel position" pl_pos_lemFuel AMBIENT "wrong fuel position: \`lemFuel\` is passed as worker argument #1 (\`a\`), but the worker's \`lemFuel\` parameter is #0" "${TBL}.p"
    row_detail "P15 swapped arguments on the worker side" pl_swap_lemFuel AMBIENT "worker argument #1: the obligation passes \`b\`, but the wrapper \`pl_swap\` passes \`a\`" "${TBL}.p"
    row_detail "P16 swapped arguments on the wrapper side" pl_swapw_lemFuel AMBIENT "wrapper argument #0 is \`b\`, not the binder \`a\`" "${TBL}.p"
    row_detail "P17 changed measure (lower bound a vs the wrapper's a + 1)" pl_mu_lemFuel AMBIENT "the lower bound \`a\` of the \`≤ lemFuel\` hypothesis is not the wrapper's measure: \`pl_mu\` calls the worker at fuel \`a + 1\`" "${TBL}.p"
    row_detail "P18 renamed worker: the wrapper calls pl_rhs_other_lemFuel" pl_rhs_lemFuel AMBIENT "the wrapper \`pl_rhs\` does not call the worker \`pl_rhs_lemFuel\`: on these inputs its body is a call of \`pl_rhs_other_lemFuel\`" "${TBL}.p"
    row_detail "P19 hidden extra premise inside the ≤ binder" pl_prem_lemFuel AMBIENT "no hypothesis \`_ ≤ lemFuel\` on the \`lemFuel\` binder" "${TBL}.p"
    row_detail "P20 POSITIVE CONTROL: well-formed _zero lemma on a decoy worker" pl_zt_lemFuel ABSORBING "zero=pl_zt_lemFuel_zero heads=[nd_status.Killed, CerbND.fuelExhaustedKill] axioms=ok" "${TBL}.p"
    row_detail "P21 _zero lemma with a term (st0 + 1) where a binder must be" pl_ztb_lemFuel AMBIENT "worker argument \`st0 + 1\` is not one of the lemma's binders" "${TBL}.p"
    row_detail "P22 _zero lemma at fuel 1, not 0" pl_ztc_lemFuel AMBIENT "no literal \`0\` among the worker's arguments" "${TBL}.p"
  else
    echo "  PLANT FAIL [tool with the decoy modules]"; tail -20 "$LOG"; fails=$((fails+13))
  fi
  # P23: an ABSORBING row whose _zero lemma's cone carries sorryAx (table plant)
  sed 's/^\(FUEL_FORM\tnd_bind_lemFuel\tABSORBING\t[^\t]*\tzero=[^ ]* heads=[^\t]*\) axioms=ok/\1 axioms=BAD[[sorryAx]]/' "$TBL" > "${TBL}.p"
  if cmp -s "$TBL" "${TBL}.p"; then echo "  PLANT FAIL [P23 premise]: the sed did not alter the nd_bind row (vacuous plant)"; fails=$((fails+1)); fi
  plant "P23 ABSORBING _zero lemma with sorryAx in its cone (nd_bind)" "ABSORBING _zero lemma(s) with an axiom cone outside" "${TBL}.p" "$PENDING" "$HYPREG"
  # P11 (C4 audit F-A4): a decoy of a REAL registered obligation with an EXTRA
  # unnamed Prop binder before `lemHyp` and the register's exact hypothesis
  # (`CerbTagsWf.Acyclic ambient`) — compiled with the real CerbMem proofs module
  # EXCLUDED from the import list (else a duplicate constant). Without the
  # binder check the tool would count it MEASURED and the register would match:
  # the shape check must report it MALFORMED.
  # (the decoy needs a real PROOF, no `sorry`: it is stated with a contradictory
  # extra binder — the SHAPE is what the plant tests, the proof is irrelevant)
  cat > "$PLANTDIR/FuelFormsPlantExtra.lean" <<'LEAN'
import CerbMem
theorem CerbMem.sizeofCtype_measure_sufficient (ambient : CerbTags.TagDefsMap) (cty : ctype)
    (extra : cty ≠ cty) (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (_lemMeasureLe : CerbTagsWf.envBound ambient cty ≤ lemFuel) :
    CerbMem.sizeofCtype_lemFuel lemFuel ambient ambient cty = CerbMem.sizeofCtype ambient cty :=
  absurd rfl extra
LEAN
  if ! (cd "$LF" && "$CAPPED" lake env lean --root="$PLANTDIR" -o "$PLANTDIR/FuelFormsPlantExtra.olean" "$PLANTDIR/FuelFormsPlantExtra.lean" >> "$LOG" 2>&1); then
    echo "  PLANT FAIL [compiling FuelFormsPlantExtra]"; tail -20 "$LOG"; fails=$((fails+1))
  fi
  if FUELFORMS_EXTRA_PATH="$PLANTDIR" FUELFORMS_EXTRA_MODULES="FuelFormsPlantExtra FuelFormsPlantContra" FUELFORMS_EXCLUDE_MODULES="CerbMem_lemMeasureProofs" table_of_tree "$LOG" > "${TBL}.p"; then
    grep -E $'^FUEL_FORM\tCerbMem\.(sizeofCtype|alignofCtype)_lemFuel\t' "${TBL}.p" | cut -c1-260 | sed 's/^/    plant table: /'
    plant "P11 decoy of a REAL obligation with an EXTRA Prop binder and the register's exact hypothesis (CerbMem.sizeofCtype): MALFORMED by the binder check" "not the contract's shape" "${TBL}.p" "$PENDING" "$HYPREG"
    if ! grep -qE $'^FUEL_FORM\tCerbMem\.sizeofCtype_lemFuel\tAMBIENT\t[^\t]*\tMALFORMED [^\t]*binder `extra`' "${TBL}.p"; then
      echo "  PLANT FAIL [P11: the tool did not report the extra binder as the shape mismatch]"; fails=$((fails+1))
    else
      echo "  PLANT OK   [P11 premise] -> the tool reports CerbMem.sizeofCtype_lemFuel MALFORMED: binder \`extra\` is neither reserved nor a wrapper argument"
    fi
    plant "P10 the REAL CerbMem.alignofCtype obligation restated under the CONTRADICTORY hypothesis cty ≠ cty: MEASURED by shape, RED by the register" "no reviewed register row" "${TBL}.p" "$PENDING" "$HYPREG"
    if ! grep -qE $'^FUEL_FORM\tCerbMem\.alignofCtype_lemFuel\tMEASURED\t[^\t]*\t[^\t]*\tcty ≠ cty$' "${TBL}.p"; then
      echo "  PLANT FAIL [P10: the tool did not report CerbMem.alignofCtype_lemFuel MEASURED with hyp=cty ≠ cty — the plant is not testing what it claims]"; fails=$((fails+1))
    else
      echo "  PLANT OK   [P10 premise] -> the tool reports CerbMem.alignofCtype_lemFuel MEASURED hyp=cty ≠ cty (shape alone cannot see the contradiction; the register is the closure)"
    fi
  else
    echo "  PLANT FAIL [tool with the extra-binder + contradictory-hypothesis decoys]"; tail -20 "$LOG"; fails=$((fails+3))
  fi
  # P8/P9/P9b (C4): the hypothesis register, both directions + format
  grep -v $'^CerbMem\.sizeofCtype_lemFuel\t' "$HYPREG" > "${TBL}.hreg"; plant "P8 register row of a measured-under-hypothesis worker deleted (CerbMem.sizeofCtype)" "no reviewed register row" "$TBL" "$PENDING" "${TBL}.hreg"
  { cat "$HYPREG"; printf 'hack_lemFuel\t0 < k\tdriver.lem:1 planted\t[PLANT]\n'; } > "${TBL}.hreg"; plant "P9 stale register row (hack under 0 < k)" "stale register row" "$TBL" "$PENDING" "${TBL}.hreg"
  { cat "$HYPREG"; printf 'phantom_lemFuel\tTrue\tno cite here\t[PLANT]\n'; } > "${TBL}.hreg"; plant "P9b register row without a .lem:<line> cite" "not of the form" "$TBL" "$PENDING" "${TBL}.hreg"
  echo "  UNPLANTED:"; policy "$TBL" "$PENDING" "$HYPREG" | sed 's/^/    /' || fails=$((fails+1))
  if (( fails == 0 )); then echo "check_fuel_forms: SELFTEST OK (24 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: the C4 four (type True / wrong worker / contradictory hypothesis caught by the register / extra binder), the whole-project audit's two decoys verbatim (review_bad _zero about runNDFuel; review_shift at literal 0), wrong fuel position, swapped worker-side and wrapper-side arguments, changed measure, wrapper calling another worker, hidden premise, and three _zero decoys (a POSITIVE control ABSORBING, a term for a binder, fuel 1) — each rejected with its own message; unplanted table green)"; exit 0; else echo "check_fuel_forms: SELFTEST FAILED ($fails)"; exit 1; fi
fi

policy "$TBL" "$PENDING" "$HYPREG"
