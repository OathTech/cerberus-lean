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
#                C4; a same-named constant of another type is MALFORMED and RED
#                here); this script additionally requires the reported axiom cones
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
#                closure — --selftest's P10 compiles exactly such a decoy and shows
#                the register turning it RED;
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
# summary line present, and the four forms PARTITION the table (their counts
# sum to the worker count — audit M2). `--selftest` plants on a scratch copy
# of the table (a new reachable ambient worker, a stale pending pin, a
# measured obligation with a bad axiom cone, a truncated table, a phantom
# pending-register row), on a scratch copy of the HYPOTHESIS register (a
# measured-under-hypothesis worker whose row is deleted; a stale row; a row
# without a `.lem:` cite), and COMPILES three decoy obligations in a scratch
# dir outside the tree (right name / type True; right shape / wrong worker
# constant; right shape under the CONTRADICTORY hypothesis `env1 ≠ env1`) —
# the first two the tool must refuse to count as MEASURED, the third it
# counts MEASURED and the REGISTER must turn RED. Nothing in the tree is touched. The
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
  # (A delegated `proof=` constant is reported where one exists — the generated
  # obligations delegate to <Module>_lemMeasureProofs — but is not required: the
  # hand-written seam obligations in CerbMem_lemMeasureProofs ARE their own
  # proof, and the obligation's axiom cone covers its proof transitively.)
  # M1: a same-named constant that is NOT the contract's statement
  local malformed
  malformed=$(awk -F'\t' '$1=="FUEL_FORM" && $5 ~ /^MALFORMED/ {print $2" :: "$5}' "$tbl")
  if [[ -n "$malformed" ]]; then
    echo "check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …) — never MEASURED:"; echo "$malformed" | sed 's/^/  /'; rc=1
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
    echo "check_fuel_forms: OK ($n_all fuel'd workers: $n_meas MEASURED (every obligation + proof cone ⊆ the standard three; $n_hyp of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), $n_abs ABSORBING, $n_pend reachable-AMBIENT = the $n_pend rows of fuel_forms_pending.txt exactly, $n_unr ambient unreachable from the drive cone)"
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
  # under the CONTRADICTORY hypothesis `env1 ≠ env1` (hack) — the tool counts it
  # MEASURED with `hyp=env1 ≠ env1` (the gate cannot decide satisfiability);
  # the REGISTER has no row for it, so the policy is RED: this is the
  # consumer-side closure of the lem slice's F1.
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
  cat > "$PLANTDIR/FuelFormsPlantContra.lean" <<'LEAN'
import Driver
theorem hack_measure_sufficient [LemFuel] (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (core_extern1 : Fmap sym sym) (env1 : List (Fmap sym value)) (mem_st : CerbMem.MemState)
    (core_file1 : generic_file Unit core_run_annotation) (concur_sym_map : Fmap sym object_value)
    (pexpr1 : generic_pexpr Unit sym) (lemHyp : env1 ≠ env1) (lemFuel : Nat) (_lemMeasureLe : 0 ≤ lemFuel) :
    hack_lemFuel lemFuel _lemReader_tagDefs core_extern1 env1 mem_st core_file1 concur_sym_map pexpr1 =
      hack _lemReader_tagDefs core_extern1 env1 mem_st core_file1 concur_sym_map pexpr1 :=
  absurd rfl lemHyp
LEAN
  for m in FuelFormsPlantTrue FuelFormsPlantWorker FuelFormsPlantContra; do
    if ! (cd "$LF" && "$CAPPED" lake env lean --root="$PLANTDIR" -o "$PLANTDIR/$m.olean" "$PLANTDIR/$m.lean" >> "$LOG" 2>&1); then
      echo "  PLANT FAIL [compiling $m]"; tail -20 "$LOG"; fails=$((fails+1))
    fi
  done
  if FUELFORMS_EXTRA_PATH="$PLANTDIR" FUELFORMS_EXTRA_MODULES="FuelFormsPlantTrue FuelFormsPlantWorker FuelFormsPlantContra" table_of_tree "$LOG" > "${TBL}.p"; then
    grep -E $'^FUEL_FORM\t(to_pure_lemFuel|to_pures_lemFuel|hack_lemFuel)\t' "${TBL}.p" | cut -c1-220 | sed 's/^/    plant table: /'
    plant "P6 decoy obligation of type True (to_pure)" "not the contract's shape" "${TBL}.p" "$PENDING" "$HYPREG"
    plant "P7 decoy obligation with the wrong worker constant (to_pures)" "not the contract's shape" "${TBL}.p" "$PENDING" "$HYPREG"
    plant "P10 decoy obligation under the CONTRADICTORY hypothesis env1 ≠ env1 (hack): MEASURED by shape, RED by the register" "no reviewed register row" "${TBL}.p" "$PENDING" "$HYPREG"
    if ! grep -qE $'^FUEL_FORM\thack_lemFuel\tMEASURED\t[^\t]*\t[^\t]*\tenv1 ≠ env1$' "${TBL}.p"; then
      echo "  PLANT FAIL [P10: the tool did not report hack MEASURED with hyp=env1 ≠ env1 — the plant is not testing what it claims]"; fails=$((fails+1))
    else
      echo "  PLANT OK   [P10 premise] -> the tool reports hack_lemFuel MEASURED hyp=env1 ≠ env1 (shape alone cannot see the contradiction)"
    fi
  else
    echo "  PLANT FAIL [tool with the decoy modules]"; tail -20 "$LOG"; fails=$((fails+3))
  fi
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
  if FUELFORMS_EXTRA_PATH="$PLANTDIR" FUELFORMS_EXTRA_MODULES="FuelFormsPlantExtra" FUELFORMS_EXCLUDE_MODULES="CerbMem_lemMeasureProofs" table_of_tree "$LOG" > "${TBL}.p"; then
    grep -E $'^FUEL_FORM\tCerbMem\.sizeofCtype_lemFuel\t' "${TBL}.p" | cut -c1-260 | sed 's/^/    plant table: /'
    plant "P11 decoy of a REAL obligation with an EXTRA Prop binder and the register's exact hypothesis (CerbMem.sizeofCtype): MALFORMED by the binder check" "not the contract's shape" "${TBL}.p" "$PENDING" "$HYPREG"
    if ! grep -qE $'^FUEL_FORM\tCerbMem\.sizeofCtype_lemFuel\tAMBIENT\t[^\t]*\tMALFORMED [^\t]*binder `extra`' "${TBL}.p"; then
      echo "  PLANT FAIL [P11: the tool did not report the extra binder as the shape mismatch]"; fails=$((fails+1))
    else
      echo "  PLANT OK   [P11 premise] -> the tool reports CerbMem.sizeofCtype_lemFuel MALFORMED: binder \`extra\` is neither reserved nor a wrapper argument"
    fi
  else
    echo "  PLANT FAIL [tool with the extra-binder decoy]"; tail -20 "$LOG"; fails=$((fails+1))
  fi
  # P8/P9/P9b (C4): the hypothesis register, both directions + format
  grep -v $'^CerbMem\.sizeofCtype_lemFuel\t' "$HYPREG" > "${TBL}.hreg"; plant "P8 register row of a measured-under-hypothesis worker deleted (CerbMem.sizeofCtype)" "no reviewed register row" "$TBL" "$PENDING" "${TBL}.hreg"
  { cat "$HYPREG"; printf 'hack_lemFuel\t0 < k\tdriver.lem:1 planted\t[PLANT]\n'; } > "${TBL}.hreg"; plant "P9 stale register row (hack under 0 < k)" "stale register row" "$TBL" "$PENDING" "${TBL}.hreg"
  { cat "$HYPREG"; printf 'phantom_lemFuel\tTrue\tno cite here\t[PLANT]\n'; } > "${TBL}.hreg"; plant "P9b register row without a .lem:<line> cite" "not of the form" "$TBL" "$PENDING" "${TBL}.hreg"
  echo "  UNPLANTED:"; policy "$TBL" "$PENDING" "$HYPREG" | sed 's/^/    /' || fails=$((fails+1))
  if (( fails == 0 )); then echo "check_fuel_forms: SELFTEST OK (12 plants red with the declared label — 5 on the table, 3 on the hypothesis register, 4 compiled decoy obligations incl. the contradictory-hypothesis decoy caught by the register and the extra-binder decoy caught by the shape check; unplanted table green)"; exit 0; else echo "check_fuel_forms: SELFTEST FAILED ($fails)"; exit 1; fi
fi

policy "$TBL" "$PENDING" "$HYPREG"
