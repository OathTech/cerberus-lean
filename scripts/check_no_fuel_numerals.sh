#!/bin/bash
# check_no_fuel_numerals.sh — GATE: no fuel numeral anywhere in the Lean text
# a consumer reasons against (fuel-parameter arc, 2026-09-04; [USER 2026-09-03]
# "Any and all magic values that are hardcoded and can't be quantified over
# are definitionally bugs"; lean_frontend/DESIGN.md §4 "No magic values").
#
# Scanned (comment-stripped): lean_frontend/*.lean (the hand-written seams,
# Main.lean included), lean_frontend/generated/*.lean (the lem output + the
# seam copies), lean_frontend/test/**/*.lean (the unit gates and the ∀-fuel
# exemplar), lean_frontend/speclab/**/*.lean (the harness-family package,
# its gate tests included) and tests/**/*.lean (the in-Lean immaculate
# probes, the mem-scale micro instrument) — .lake trees excluded. Unlike lem-lean's own gate
# (tests/comprehensive/check_no_fuel_numerals.sh, whose F1–F5 patterns this
# ports), the TEST trees are scanned too: here the tests are the consumer's
# pinned-lemma gate and the differential harnesses' exec legs, and a fuel
# they choose must arrive from OUTSIDE the Lean text (`--fuel N` on the
# gate binaries' command line, scripts/common.sh CERB_TEST_FUEL).
#
# THE ONE ALLOWED SITE — Main.lean, allowlisted by exact line content (the
# harness default and the single instantiation that consumes it):
#   def defaultFuel : Nat := 100000000  -- FUEL-DEFAULT (the one allowed fuel numeral)
#   let code ← (letI : LemFuel := ⟨fuel⟩; runPipeline …
# Any other occurrence of the shapes below fails, naming file:line.
#
# Forbidden shapes (each a hardcoded fuel no context could quantify over):
#   F1  lemDefaultFuel                       the deleted LemLib default (and
#                                            cerberus's deleted driverFuel /
#                                            ndDefaultFuel)
#   F2  instance … : LemFuel                 a global instance = a hidden default
#   F3  <worker>_lemFuel <positive numeral>  a worker run at a literal fuel
#                                            (`_lemFuel 0` is the exhaustion
#                                            lemma's statement, permitted; a
#                                            measured wrapper's `_lemFuel (1 + n)`
#                                            is a data measure, permitted)
#   F4  LemFuel := ⟨…⟩ / LemFuel.mk <num>    an instance built from a literal
#                                            (Main.lean's letI is the allowlisted
#                                            exception)
#   F5  ⟨<numeral>⟩                          an anonymous-constructor literal —
#                                            the entry idiom `@f ⟨n⟩` pasted with
#                                            a number (`⟨n⟩` with a variable is
#                                            legal)
#   F6  a fuel-named constant defined as a numeral
#       (def|abbrev|let|letI) …[Ff]uel… := <numeral>   (Main.lean's
#                                            defaultFuel is the allowlisted
#                                            exception)
# Vacuity guards: ≥ MIN_FILES files scanned and ≥ one `_lemFuel` worker seen,
# else FAIL (not scanning real generated code is a failure, not a pass).
#
# --selftest: plant each shape (F1–F6) into a scratch COPY of the scan set,
# assert red with the right label, then assert the unplanted set is green
# (loud plant banner; the test_unit.sh wiring runs the gate AND the selftest).
set -u
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIN_FILES=150

# Allowlist: exact (whitespace-trimmed) code lines permitted in Main.lean only.
ALLOW_MAIN=(
  'def defaultFuel : Nat := 100000000'
  'let code ← (letI : LemFuel := ⟨fuel⟩; runPipeline runtimeDir batchMode ppCoreMode firstTrace'
)

scan_files() {  # <repo root>
  local r="$1" lf="$1/lean_frontend"
  { ls "$lf"/*.lean 2>/dev/null
    ls "$lf"/generated/*.lean 2>/dev/null
    find "$lf/test" "$lf/speclab" "$r/tests" -name '*.lean' -not -path '*/.lake/*' 2>/dev/null
  } | LC_ALL=C sort
}

strip_comments() { # file -> rows "<file>:<lineno>: <code-without-comments>"
  perl -e '
    my $f = shift; open(my $fh, "<", $f) or die; local $/; my $t = <$fh>;
    $t =~ s{/-.*?-/}{ join("", map { "\n" } 1..(() = $& =~ /\n/g)) }gse;   # keep line count
    my $n = 0; for my $l (split /\n/, $t, -1) { $n++; $l =~ s/--.*$//; print "$f:$n: $l\n" if $l =~ /\S/; }
  ' "$1"
}

run_gate() {  # <repo root>; prints verdict lines; returns 0/1
  local r="$1"
  local files n rows status=0
  files=$(scan_files "$r")
  n=$(echo "$files" | grep -c .)
  if [[ "$n" -lt "$MIN_FILES" ]]; then echo "check_no_fuel_numerals: FAIL (vacuous): only $n files to scan (< $MIN_FILES) — regenerate lean_frontend/generated first"; return 1; fi
  if ! echo "$files" | xargs grep -l '_lemFuel' > /dev/null 2>&1; then echo "check_no_fuel_numerals: FAIL (vacuous): no fuel worker (_lemFuel) in the scanned files"; return 1; fi
  rows=$(for f in $files; do strip_comments "$f"; done)
  # drop the allowlisted Main.lean lines (exact trimmed content, Main.lean only —
  # the hand-written file AND its generated/ copy)
  local allowed_re=''
  for a in "${ALLOW_MAIN[@]}"; do
    local esc; esc=$(printf '%s' "$a" | sed -e 's/[][\.*^$/|(){}+?]/\\&/g')
    allowed_re+="${allowed_re:+|}^[^:]*/Main\.lean:[0-9]+:[[:space:]]*${esc}[[:space:]]*\$"
  done
  local filtered; filtered=$(echo "$rows" | grep -Ev "$allowed_re")
  local allowed_hits; allowed_hits=$(echo "$rows" | grep -Ec "$allowed_re")
  report() { # label pattern
    local hits; hits=$(echo "$filtered" | grep -E "$2")
    if [[ -n "$hits" ]]; then echo "check_no_fuel_numerals: FAIL ($1): fuel numeral shape found:"; echo "$hits" | head -20; status=1; fi
  }
  report F1 'lemDefaultFuel|driverFuel|ndDefaultFuel'
  report F2 ':[[:space:]]*(@\[[^]]*\][[:space:]]*)?(scoped |local )?instance[^:]*:[[:space:]]*LemFuel\b'
  report F3 '_lemFuel[[:space:]]+[1-9][0-9]*([^0-9A-Za-z_.'"'"']|$)|_lemFuel[[:space:]]*\([[:space:]]*[1-9][0-9]*[[:space:]]*\)'
  report F4 'LemFuel[[:space:]]*:=[[:space:]]*⟨|LemFuel\.mk[[:space:]]+[0-9]'
  report F5 '⟨[[:space:]]*[1-9][0-9]*[[:space:]]*⟩'
  report F6 '^[^:]*:[0-9]+:[[:space:]]*(private[[:space:]]+|protected[[:space:]]+|noncomputable[[:space:]]+)*(def|abbrev|let|letI)[[:space:]]+[^:=]*[Ff]uel[^:=]*(:[^=]*)?:=[[:space:]]*[0-9]+[[:space:]]*$'
  if [[ $status -eq 0 ]]; then
    echo "check_no_fuel_numerals: OK ($n files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: $allowed_hits of $((2 * ${#ALLOW_MAIN[@]})) (hand-written + generated copy))"
  fi
  return $status
}

if [[ "${1:-}" == "--selftest" ]]; then
  echo "check_no_fuel_numerals: SELFTEST — planting F1-F6 into a scratch copy of the scan set (loud plant banner; nothing in the tree is touched)"
  W=$(mktemp -d "${TMPDIR:-/tmp}/nofuel-plant.XXXXXX") || exit 1
  trap 'rm -rf "$W"' EXIT
  R="$W/root"; LF="$R/lean_frontend"; mkdir -p "$LF/generated" "$LF/test/Unit" "$LF/speclab/test/SLUnit" "$R/tests/immaculate"
  # a faithful copy of the real scan set (paths preserved under $R)
  for f in $(scan_files "$ROOT"); do
    rel="${f#"$ROOT/"}"; mkdir -p "$R/$(dirname "$rel")"; cp "$f" "$R/$rel"
  done
  fail=0
  plant() {  # <label> <expected-label> <relfile (under lean_frontend/, or ../tests/…)> <line>
    cp "$LF/$3" "$W/saved"; printf '%s\n' "$4" >> "$LF/$3"
    out=$(run_gate "$R"); rc=$?
    cp "$W/saved" "$LF/$3"
    if [[ $rc -ne 0 ]] && grep -q "FAIL ($2)" <<<"$out"; then echo "  PLANT OK   [$1] -> $(grep -m1 "FAIL ($2)" <<<"$out")"
    else echo "  PLANT FAIL [$1]: expected FAIL ($2), got rc=$rc: $(head -3 <<<"$out")" >&2; fail=1; fi
  }
  plant "F1 deleted default named in code" F1 generated/Utils.lean 'def plant1 : Nat := lemDefaultFuel'
  plant "F1 deleted driverFuel in a seam" F1 CerbND.lean 'def plant1b : Nat := CerbFuel.driverFuel'
  plant "F2 global instance"              F2 generated/Utils.lean 'instance : LemFuel := ⟨plantK⟩'
  plant "F2 global instance (where)"      F2 speclab/test/SLUnit/Fuel.lean 'instance : LemFuel where fuel := 5'
  plant "F3 worker at a literal fuel"     F3 test/Unit/TotalityProofTest.lean 'def plant3 : Nat := mkListN_aux_lemFuel 5 0 0 [] |>.length'
  plant "F3 parenthesised literal"        F3 generated/Utils.lean 'def plant3b := replicate_list__lemFuel (5) 0 3 []'
  plant "F4 LemFuel.mk numeral"           F4 generated/Driver.lean 'def plantInst : LemFuel := LemFuel.mk 5'
  plant "F4 letI outside Main"            F4 CerbND.lean 'def plant4 := (letI : LemFuel := ⟨fuelVar⟩; 0)'
  plant "F5 anonymous-constructor literal" F5 test/Unit/FuelExemplar.lean 'def plant5 := @driver2 ⟨100000000⟩'
  plant "F6 fuel-named numeral constant"  F6 CerbMem.lean 'def memFuel : Nat := 1000000'
  plant "F6 in a speclab gate test"       F6 speclab/test/SLUnit/CoreGateTest.lean 'def gateFuel := 500'
  plant "F6 in a generated copy of Main"  F6 generated/Main.lean 'def defaultFuel2 : Nat := 100000000'
  plant "F5 in an immaculate Lean probe"  F5 ../tests/immaculate/illtyped-store.lean 'def plant5b := @runStore ⟨1000000⟩'
  echo "  REVERTED (unplanted scratch copy):"
  out=$(run_gate "$R"); rc=$?; echo "  $out"
  if [[ $rc -ne 0 ]]; then echo "  PLANT FAIL [green baseline]: the unplanted scan set is not green" >&2; fail=1; fi
  if [[ $fail -eq 0 ]]; then echo "check_no_fuel_numerals: SELFTEST OK (13 plants red with the declared label; unplanted set green)"; else echo "check_no_fuel_numerals: SELFTEST FAILED" >&2; fi
  exit $fail
fi

run_gate "$ROOT"
