#!/usr/bin/env bash
# check_fuel_forms.sh — the consumer's (A)/(B)/(C) requirement made mechanical
# (fuel-parameter arc C2, 2026-09-04; refined-cerberus
# docs/2026-09-04_review-of-fuel-parameter-design.md §2).
#
# Every fuel'd worker in the compiled environment is CLASSIFIED by the Lean tool
# lean_frontend/test/Unit/FuelFormsTool.lean (run under `lake env`, importing
# the exec entries and every generated *_auxiliary module):
#   MEASURED   — its `<f>_measure_sufficient` obligation exists (generated
#                statement, hand-written proof); this script additionally
#                requires the reported axiom cones (obligation AND proof) to be
#                ⊆ [propext, Classical.choice, Quot.sound];
#   ABSORBING  — its `_zero` lemma's RHS is the monad's absorbing element at the
#                fuel atom (ND kill / runner Killed / undefined-monad Error) with
#                no value sentinel;
#   AMBIENT    — neither; RED iff reachable from the drive cone (kernel constant
#                closure of drive/initial_driver_state/the CerbND runners/
#                CerbCall.driveCall, closed under mutual blocks) and NOT a row of
#                scripts/fuel_forms_pending.txt; a pending row that is no longer
#                reachable-ambient is RED too (stale pin) — the register moves
#                only by explicit edit, both directions.
# Vacuity guards: ≥ 60 workers, ≥ 30 measured, ≥ 10 absorbing, the tool's
# summary line present. `--selftest` plants on a scratch copy of the table
# (nothing in the tree is touched): a new reachable ambient worker, a stale
# pending pin, a measured obligation with a bad axiom cone, a truncated table.
# The tool itself fails closed if an entry constant is missing or the table is
# vacuous.
set -uo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$SCRIPT_DIR/.."
LF="$ROOT/lean_frontend"
PENDING="$SCRIPT_DIR/fuel_forms_pending.txt"
CAPPED="$SCRIPT_DIR/capped"

table_of_tree() {
  local aux
  aux=$(cd "$LF" && ls generated/*_auxiliary.lean | xargs -n1 basename | sed 's/\.lean$//')
  (cd "$LF" && "$CAPPED" lake build fuel-forms-tool >/dev/null 2>&1) || { echo "check_fuel_forms: FAIL — could not build fuel-forms-tool"; return 1; }
  # shellcheck disable=SC2086
  (cd "$LF" && "$CAPPED" lake env ./.lake/build/bin/fuel-forms-tool Driver CerbCall CerbND Main $aux 2>/dev/null)
}

# policy <table-file> <pending-file>: prints verdict lines, returns 0/1
policy() {
  local tbl="$1" pend="$2"
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
  # (A delegated `proof=` constant is reported where one exists — the generated
  # obligations delegate to <Module>_lemMeasureProofs — but is not required: the
  # hand-written seam obligations in CerbMem_lemMeasureProofs ARE their own
  # proof, and the obligation's axiom cone covers its proof transitively.)
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
    echo "check_fuel_forms: OK ($n_all fuel'd workers: $n_meas MEASURED (every obligation + proof cone ⊆ the standard three), $n_abs ABSORBING, $n_pend reachable-AMBIENT = the $n_pend rows of fuel_forms_pending.txt exactly, $n_unr ambient unreachable from the drive cone)"
  fi
  return $rc
}

TBL=$(mktemp); trap 'rm -f "$TBL" "${TBL}.p" "${TBL}.pend"' EXIT
if ! table_of_tree > "$TBL"; then echo "check_fuel_forms: FAIL — the classifier tool failed (fail-closed)"; cat "$TBL" | tail -5; exit 1; fi

if [[ "${1:-}" == "--selftest" ]]; then
  echo "check_fuel_forms: SELFTEST — plants on a scratch copy of the classification table (loud plant banner; nothing in the tree is touched)"
  fails=0
  plant() { # <label> <expected-substring> <table-file> <pending-file>
    local out; out=$(policy "$3" "$4" 2>&1); local rc=$?
    if (( rc != 0 )) && grep -q -- "$2" <<<"$out"; then echo "  PLANT OK   [$1] -> $(grep -m1 -- "$2" <<<"$out")"; else echo "  PLANT FAIL [$1]: rc=$rc"; echo "$out" | sed 's/^/      /'; fails=$((fails+1)); fi
  }
  # P1: a measured, reachable worker flipped to ambient -> new reachable ambient
  sed 's/^\(FUEL_FORM\tstep_eval_pexpr_lemFuel\t\)MEASURED\t/\1AMBIENT\t/' "$TBL" > "${TBL}.p"; plant "P1 measured->ambient reachable (step_eval_pexpr)" "REACHABLE from drive with an opaque" "${TBL}.p" "$PENDING"
  # P2: a pending row vanishes from the table (e.g. it became measured) -> stale pin
  grep -v $'^FUEL_FORM\thack_lemFuel\t' "$TBL" > "${TBL}.p"; plant "P2 stale pending pin (hack removed from the table)" "stale pin" "${TBL}.p" "$PENDING"
  # P3: a measured obligation with sorryAx in its cone
  sed 's/^\(FUEL_FORM\tin_pattern_lemFuel\tMEASURED\t[^\t]*\t\)obligation=\([^ ]*\) axioms=ok/\1obligation=\2 axioms=BAD[[sorryAx]]/' "$TBL" > "${TBL}.p"; plant "P3 measured obligation with sorryAx in its cone" "axiom cone outside" "${TBL}.p" "$PENDING"
  # P4: truncated table (no summary)
  grep -v '^FUEL_FORMS_SUMMARY' "$TBL" > "${TBL}.p"; plant "P4 truncated table" "no FUEL_FORMS_SUMMARY" "${TBL}.p" "$PENDING"
  # P5: a phantom register row
  { cat "$PENDING"; echo "phantom_lemFuel pure-loop planted"; } > "${TBL}.pend"; plant "P5 phantom register row" "stale pin" "$TBL" "${TBL}.pend"
  echo "  UNPLANTED:"; policy "$TBL" "$PENDING" | sed 's/^/    /' || fails=$((fails+1))
  if (( fails == 0 )); then echo "check_fuel_forms: SELFTEST OK (5 plants red with the declared label; unplanted table green)"; exit 0; else echo "check_fuel_forms: SELFTEST FAILED ($fails)"; exit 1; fi
fi

policy "$TBL" "$PENDING"
