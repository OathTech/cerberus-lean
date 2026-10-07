#!/bin/bash
# check_no_fuel_numerals.sh — GATE: no fuel numeral — and, since the address-space-
# bound slice (2026-09-17), no ADDRESS-SPACE-TOP numeral — anywhere in the Lean text
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
# THE ALLOWED SITES — Main.lean, allowlisted by exact line content (the
# harness defaults and the single fuel instantiation that consumes one):
#   def defaultFuel : Nat := 100000000  -- FUEL-DEFAULT (the one allowed fuel numeral)
#   let code ← (letI : LemFuel := ⟨fuel⟩; letI : CerbGlobal.Switches := ⟨…⟩; runPipeline …
#     (the switch-set instance joined the line in PNVI arc S1, 2026-10-05)
#   def defaultAddressSpaceTop : Int := 0xFFFFFFFFFFFF  -- ADDRESS-SPACE-DEFAULT
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
#
# Address-space-top shapes (address-space-bound slice, 2026-09-17; [USER 2026-09-16]
# the bound is a quantified parameter whose matched-mode instance is upstream's
# 0xFFFFFFFFFFFF = 281474976710655; the allocator's initial cursor enters the run
# ONLY from `--address-space-top` via `initialMemState top` / `desugar … top …`):
#   A1  0xFFFFFFFFFFFF / 0xffffffffffff    the default's hex spelling (exactly 12
#                                            hex digits — CerbFloat's 13-digit mantissa
#                                            masks are not hits)
#   A2  281474976710655                    the default in decimal
#   A3  lastAddress := <numeral> /          a cursor literal in a MemState literal or a
#       last_address= <numeral>              pasted OCaml record (tests choose a NAMED
#                                            value, exactly as they do for fuel)
# Switch-set shape (PNVI arc S1, 2026-10-05; proportionality revision 2026-10-07,
# record docs/2026-10-05_pnvi-s1-switch-parameter-record.md §14):
#   W1  instance … : … Switches              an `instance` declaration whose header (on
#                                            its own line) names `Switches` —
#                                            `instance : CerbGlobal.Switches := …`,
#                                            `instance foo : Switches where …`; a global
#                                            switch-set instance would be a hidden default
#                                            (the same concern as F2 for `LemFuel`).
#                                            Main.lean's `letI : CerbGlobal.Switches := …`
#                                            is not an `instance` declaration and is
#                                            allowlisted anyway.
#   W1 SCOPE, plainly: a SPEEDBUMP against ACCIDENTAL default `CerbGlobal.Switches`
#   instances in this repository's scanned Lean text — NOT adversarially robust (a
#   header split across lines, an alias, an `extends`, an `instance` attribute, an
#   untyped instance or a raw-string desync all pass it, by design). The backstop is
#   that Main.lean's LOCAL instance (`letI`) wins over any global one for every lane,
#   plus review. A consumer's own instance (outside this repository) is the intended use.
#   Known edges (PNVI arc S2, 2026-10-07): an instance with a `[CerbGlobal.Switches]`
#   binder AFTER a binder with a colon (`instance foo (x : T) [CerbGlobal.Switches] : C`)
#   trips W1 — an accepted false positive; the one-line `instance (priority := …) :
#   Switches` form is NOT caught (`[^:]*` stops at the `:=`) — speedbump scope.
# Default-reconstruct shape (PNVI arc S2, 2026-10-07; record
# docs/2026-10-07_pnvi-s2-data-shapes-record.md; design record §B.7 condition (b)):
#   W2  reconstructValue / reconstructValue_lemFuel   a mention (bare or `CerbMem.`-qualified)
#                                            of the DEFAULT-PINNED compatibility wrappers in
#                                            PRODUCTION Lean text — the hand-written seams
#                                            (lean_frontend/*.lean) and the generated tree
#                                            (lean_frontend/generated/*.lean), comments AND
#                                            string literals stripped, the `*_lemMeasureProofs`
#                                            proof carriers excluded — other than the wrappers'
#                                            own two definition lines and the fuel-free
#                                            wrapper's body line in CerbMem.lean (allowlisted by
#                                            exact content, both copies). Production must call
#                                            `reconstructValueAbst(_lemFuel)` with the AMBIENT
#                                            switch set (as `loadM` does); the old names are
#                                            pinned at `⟨CerbGlobal.defaultSwitches⟩` for the
#                                            consumer and would silently run default-mode
#                                            reconstruction under any other set.
#   W2 SCOPE, plainly: a SPEEDBUMP (not a trust surface: in default mode the wrapper and
#   the full function agree — kernel theorem `reconstructValueAbst_default_snd_eq_legacy`,
#   test/Unit/ReconstructLegacyTest.lean — so a stray call changes no lane today; it
#   matters only once a PNVI set is accepted, S4). It catches a plain textual call in the
#   scanned production text; it is NOT adversarially robust — an alias (`abbrev`,
#   `export`, `open … renaming`), a call from a test/speclab file, or a mention split by
#   a raw string pass it, by design. Backstops: review, and the S3/S4 PNVI lane, where a
#   default-pinned reconstruction would diverge from the oracle.
# Vacuity guards: ≥ MIN_FILES files scanned, ≥ one `_lemFuel` worker seen the
# `lastAddress` field seen and `class Switches` seen, ≥ one W2-allowlisted wrapper
# line seen, else FAIL (not scanning real code is a failure, not a pass).
#
# WHAT THIS GATE IS (pre-merge audit M2, 2026-09-04): a plant-tested
# SPEEDBUMP over the enumerated idiomatic shapes above (bare/hex/ascribed/
# parenthesised numerals, the instance-carrying worker form `f_lemFuel ⟨i⟩ 5`,
# `{ fuel := N }`, `LemFuel.mk (…)`). It is NOT a proof that no fuel numeral
# exists: arithmetic (`⟨10^8⟩`, `LemFuel.mk (10^8)` is caught only by its
# `mk (` shape) and indirection through a non-fuel-named constant
# (`def budget := 100000000; @f ⟨budget⟩`) are not regex-closable and remain
# review discipline. The BACKSTOP is the typing: every fuel'd function
# demands a `[LemFuel]` instance, no instance exists in library/generated/
# seam code, and a measured wrapper carries its sufficiency obligation — a
# numeral can only enter where a human writes an instance.
#
# --selftest: plant each shape (F1–F6, A1–A3, W1, W2) into a scratch COPY of the scan set,
# assert red with the right label, then assert the unplanted set is green
# (loud plant banner; the test_unit.sh wiring runs the gate AND the selftest).
set -u
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIN_FILES=150

# Allowlist: exact (whitespace-trimmed) code lines permitted in Main.lean only.
ALLOW_MAIN=(
  'def defaultFuel : Nat := 100000000'
  'let code ← (letI : LemFuel := ⟨fuel⟩; letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩; runPipeline runtimeDir batchMode ppCoreMode firstTrace'
  'def defaultAddressSpaceTop : Int := 0xFFFFFFFFFFFF'
)

# W2 allowlist: exact (whitespace-trimmed) code lines permitted in CerbMem.lean only (the
# hand-written file and its generated/ copy) — the default-pinned wrappers' own definitions.
ALLOW_W2=(
  'def reconstructValue_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs)'
  'def reconstructValue (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))'
  'reconstructValue_lemFuel (CerbTagsWf.envBound ambient ty) enumDefs ambient unionmap funptrmap addr ty bytes'
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
  if ! echo "$files" | xargs grep -l 'lastAddress' > /dev/null 2>&1; then echo "check_no_fuel_numerals: FAIL (vacuous): no MemState.lastAddress field in the scanned files (CerbMem.lean missing from the scan set)"; return 1; fi
  if ! echo "$files" | xargs grep -l '^class Switches' > /dev/null 2>&1; then echo "check_no_fuel_numerals: FAIL (vacuous): no \`class Switches\` in the scanned files (CerbGlobal.lean missing from the scan set)"; return 1; fi
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
    if [[ -n "$hits" ]]; then echo "check_no_fuel_numerals: FAIL ($1): forbidden shape found:"; echo "$hits" | head -20; status=1; fi
  }
  report F1 'lemDefaultFuel|driverFuel|ndDefaultFuel'
  report F2 ':[[:space:]]*(@\[[^]]*\][[:space:]]*)?(scoped |local )?instance[^:]*:[[:space:]]*LemFuel\b'
  # F3: a worker applied to a literal counter — bare, parenthesised, hex, and
  # the instance-carrying shape `f_lemFuel ⟨inst⟩ 5 …` (pre-merge audit M2)
  report F3 '_lemFuel[[:space:]]+(0x[0-9a-fA-F]+|[1-9][0-9]*)([^0-9A-Za-z_.'"'"']|$)|_lemFuel[[:space:]]*\([[:space:]]*(0x[0-9a-fA-F]+|[1-9][0-9]*)[[:space:]]*\)|_lemFuel[[:space:]]*⟨[^⟩]*⟩[[:space:]]+(\(?[[:space:]]*)?(0x[0-9a-fA-F]+|[1-9][0-9]*)'
  # F4: an instance built from a literal — `⟨…⟩`, `{ fuel := … }`, `LemFuel.mk N`,
  # `LemFuel.mk (…)` (audit M2: the structure-instance and parenthesised forms)
  report F4 'LemFuel[[:space:]]*:=[[:space:]]*⟨|LemFuel[[:space:]]*:=[[:space:]]*\{|LemFuel\.mk[[:space:]]*\(|LemFuel\.mk[[:space:]]+(0x[0-9a-fA-F]+|[0-9])'
  # F5: an anonymous constructor whose payload STARTS with a numeral — `⟨N⟩`,
  # `⟨(N : Nat)⟩`, `⟨0x…⟩`, `⟨10^8⟩` (audit M2 E1–E3) — SINGLE-component only
  # (no top-level comma), so a numeral-led tuple `⟨7, 2⟩` (speclab's Input
  # literals) is not a hit; `LemFuel` has one field, so a fuel instance is
  # always single-component
  report F5 '⟨[[:space:]]*(\([[:space:]]*)?(0x[0-9a-fA-F]+|[1-9][0-9]*)[^,⟩]*⟩'
  report F6 '^[^:]*:[0-9]+:[[:space:]]*(private[[:space:]]+|protected[[:space:]]+|noncomputable[[:space:]]+)*(def|abbrev|let|letI)[[:space:]]+[^:=]*[Ff]uel[^:=]*(:[^=]*)?:=[[:space:]]*[0-9]+[[:space:]]*$'
  # A1-A3: the address-space top (2026-09-17). A1 = exactly twelve hex f's after 0x, not
  # preceded by a hex digit/x and not followed by one (the 13-digit mantissa masks in
  # CerbFloat.lean are not hits); A2 = the decimal; A3 = a cursor literal in a record.
  report A1 '(^|[^0-9a-fA-Fx])0[xX][fF]{12}([^0-9a-fA-F]|$)'
  report A2 '(^|[^0-9])281474976710655([^0-9]|$)'
  report A3 '(lastAddress[[:space:]]*:=|last_address[[:space:]]*=)[[:space:]]*\(?[[:space:]]*(0[xX][0-9a-fA-F]+|[0-9]+)'
  # W1: an `instance` declaration whose same-line header names `Switches` (PNVI arc S1;
  # a plain-text speedbump, see the header's W1 SCOPE)
  report W1 '(^|[^A-Za-z0-9_.])instance\b[^:]*:[^=]*\bSwitches\b'
  # W2: the default-pinned reconstruct wrappers named in production text (PNVI arc S2; a
  # plain-text speedbump, see the header's W2 SCOPE). Rows of the seams and the generated
  # tree only, proof carriers excluded, string literals blanked.
  local w2rows; w2rows=$(echo "$rows" | grep -E '^[^:]*/lean_frontend/(generated/)?[^/:]+\.lean:' | grep -Ev '_lemMeasureProofs\.lean:' | perl -pe 's/"(?:[^"\\]|\\.)*"/""/g')
  local w2allowed_re=''
  for a in "${ALLOW_W2[@]}"; do
    local esc2; esc2=$(printf '%s' "$a" | sed -e 's/[][\.*^$/|(){}+?]/\\&/g')
    w2allowed_re+="${w2allowed_re:+|}^[^:]*/CerbMem\.lean:[0-9]+:[[:space:]]*${esc2}[[:space:]]*\$"
  done
  local w2allowed_hits; w2allowed_hits=$(echo "$w2rows" | grep -Ec "$w2allowed_re")
  if [[ "$w2allowed_hits" -lt 1 ]]; then echo "check_no_fuel_numerals: FAIL (vacuous): no W2-allowlisted reconstructValue wrapper line seen (CerbMem.lean missing from the scan set, or the wrappers were rewritten — update ALLOW_W2)"; status=1; fi
  local w2hits; w2hits=$(echo "$w2rows" | grep -Ev "$w2allowed_re" | grep -E "(^|[^A-Za-z0-9_'])reconstructValue(_lemFuel)?([^A-Za-z0-9_'!?]|\$)")
  if [[ -n "$w2hits" ]]; then echo "check_no_fuel_numerals: FAIL (W2): forbidden shape found:"; echo "$w2hits" | head -20; status=1; fi
  if [[ $status -eq 0 ]]; then
    echo "check_no_fuel_numerals: OK ($n files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3), no switch-set instance declaration (W1), no production call of the default-pinned reconstructValue wrappers (W2); allowed Main.lean sites seen: $allowed_hits of $((2 * ${#ALLOW_MAIN[@]})) (hand-written + generated copy); W2 wrapper lines seen: $w2allowed_hits of $((2 * ${#ALLOW_W2[@]})))"
  fi
  return $status
}

if [[ "${1:-}" == "--selftest" ]]; then
  echo "check_no_fuel_numerals: SELFTEST — planting F1-F6, A1-A3, W1 and W2 into a scratch copy of the scan set (loud plant banner; nothing in the tree is touched)"
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
  # pre-merge audit M2: the instance-carrying worker literal + the six evasion spellings
  plant "M2 F3 instance-carrying worker literal" F3 CerbND.lean 'def auditP1 := @driver2_lemFuel ⟨fuelVar⟩ 5 fmapEmpty false'
  plant "M2 E1 hex literal ⟨0x5F5E100⟩"          F5 CerbND.lean 'def auditE1 := @driver2 ⟨0x5F5E100⟩ fmapEmpty false'
  plant "M2 E2 ascribed literal ⟨(N : Nat)⟩"     F5 CerbND.lean 'def auditE2 := @driver2 ⟨(100000000 : Nat)⟩ fmapEmpty false'
  plant "M2 E4 structure instance { fuel := N }" F4 CerbND.lean 'def auditE4 := (letI : LemFuel := { fuel := 100000000 }; 0)'
  plant "M2 E6 LemFuel.mk (expr)"                F4 CerbND.lean 'def auditE6 : LemFuel := LemFuel.mk (10^8)'
  plant "M2 E7 worker at a hex literal"          F3 CerbND.lean 'def auditE7 := @driver2_lemFuel ⟨fuelVar⟩ 0x5F5E100 fmapEmpty false'
  plant "M2 E3 arithmetic ⟨10^8⟩"                F5 CerbND.lean 'def auditE3 := @driver2 ⟨10^8⟩ fmapEmpty false'
  # address-space-bound slice (2026-09-17): the A-shapes — the default's hex (upper/lower)
  # and decimal spellings and a cursor literal — in a seam, in the generated tree, in a
  # unit test, in speclab and in an in-Lean probe; plus the allowlisted CONTENT in a
  # file that is not Main.lean (the allowlist is Main.lean-only). The unplanted set's
  # green run below is the check that Main.lean's own allowlisted line is ACCEPTED
  # (`allowed Main.lean sites seen: 6 of 6`).
  plant "A1 the default hex in a seam"              A1 CerbMem.lean 'def plantTop : Int := 0xFFFFFFFFFFFF'
  plant "A1 lowercase hex in the generated tree"    A1 generated/Driver.lean 'def plantTop2 : Int := 0xffffffffffff'
  plant "A1 allowlist-shaped line outside Main"     A1 CerbND.lean 'def defaultAddressSpaceTop : Int := 0xFFFFFFFFFFFF'
  plant "A2 the default in decimal in a unit test"  A2 test/Unit/MonadicFailstop.lean 'def plantTop3 := initialMemState 281474976710655'
  plant "A3 lastAddress literal in speclab"         A3 speclab/test/SLUnit/CoreGateTest.lean 'def plantSt : MemState := { lastAddress := 4096 }'
  plant "A3 last_address= literal in a probe"       A3 ../tests/immaculate/illtyped-store.lean 'def plantSt2 := last_address= 0x1000'
  # W1 (PNVI arc S1; proportionality revision 2026-10-07): an accidental switch-set
  # instance in a seam, in the generated tree and in a unit test
  plant "W1 switch-set instance in a seam"           W1 CerbND.lean 'instance : CerbGlobal.Switches := ⟨[]⟩'
  plant "W1 switch-set instance in the generated tree" W1 generated/Utils.lean 'instance plantSw : Switches where switches := []'
  plant "W1 local switch-set instance in a unit test" W1 test/Unit/FuelExemplar.lean 'local instance : CerbGlobal.Switches := sw₀'
  # W2 (PNVI arc S2, 2026-10-07): a production call of the default-pinned wrapper — a
  # loadM-shaped call in the seam, and a qualified worker call in the generated tree
  plant "W2 default-pinned wrapper called in a seam"  W2 CerbMem.lean 'def plantLoad (st : MemState) := reconstructValue fmapEmpty default st.lastUsedUnionMembers st.funptrmap 0 plantTy []'
  plant "W2 qualified old worker in the generated tree" W2 generated/Driver.lean 'def plantW2 := CerbMem.reconstructValue_lemFuel plantN fmapEmpty default [] [] 0 plantTy []'
  # E5 — indirection through a non-fuel-named constant — is NOT regex-closable
  # (no shape distinguishes `budget` from any other Nat); the selftest records
  # that the gate stays GREEN on it, so the limit is visible, never silent
  cp "$LF/CerbND.lean" "$W/saved"; printf '%s\n' 'def auditBudget : Nat := 100000000' 'def auditE5 := @driver2 ⟨auditBudget⟩ fmapEmpty false' >> "$LF/CerbND.lean"
  out=$(run_gate "$R"); rc=$?; cp "$W/saved" "$LF/CerbND.lean"
  if [[ $rc -eq 0 ]]; then echo "  KNOWN GAP  [M2 E5 indirection via a non-fuel-named constant] -> stays GREEN (not regex-closable; review discipline + the [LemFuel] typing backstop)"
  else echo "  PLANT NOTE [M2 E5]: the gate went red on the indirection plant (rc=$rc) — a regex now catches it; update this note" ; fi
  echo "  REVERTED (unplanted scratch copy):"
  out=$(run_gate "$R"); rc=$?; echo "  $out"
  if [[ $rc -ne 0 ]]; then echo "  PLANT FAIL [green baseline]: the unplanted scan set is not green" >&2; fail=1; fi
  if [[ $fail -eq 0 ]]; then echo "check_no_fuel_numerals: SELFTEST OK (31 plants red with the declared label — F1-F6, A1-A3, W1 and W2; E5 indirection a recorded known gap; unplanted set green)"; else echo "check_no_fuel_numerals: SELFTEST FAILED" >&2; fi
  exit $fail
fi

run_gate "$ROOT"
