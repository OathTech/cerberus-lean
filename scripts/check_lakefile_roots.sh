#!/bin/bash
# check_lakefile_roots.sh — GATE: the Lake roots of the semantics library are
# exactly the generated modules (fuel-parameter arc, 2026-09-04; lem-lean
# fuel-measure record §6.4 item 8 / pre-merge audit M5 for the cerberus half).
#
# WHY: lem emits, for every module M, a companion `M_auxiliary.lean` that
# carries the prover-side obligations (lemma statements, and — from the
# fuel-measure slice on — the `f_measure_sufficient` theorems whose proofs
# live in hand-written `<Module>_lemMeasureProofs`). Lake builds ONLY the
# modules reachable from `lakefile.toml`'s `roots`; an auxiliary module
# dropped from the roots silently un-builds its obligations (the auditor's
# plant P5: green with the obligations unbuilt). So: every
# `lean_frontend/generated/*.lean` must be a root of the `CerberusLean`
# library (the driver root `Main` is the exe's root instead), and every
# listed root must exist as a generated file — both directions, fail-closed.
#
# --selftest: drop one `_auxiliary` root from a scratch COPY of the lakefile
# and assert red; add a phantom root and assert red; unmodified copy green.
set -uo pipefail
# Sorting and set comparison must use the same collation on every host.
export LC_ALL=C
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LF="$ROOT/lean_frontend"
MIN_ROOTS=150

roots_of() {  # <lakefile.toml> -> root names, one per line (the CerberusLean lib's `roots = [...]`)
  awk '
    /^\[\[lean_lib\]\]/ { inlib=1; name=""; next }
    /^\[\[/ { inlib=0; inroots=0 }
    inlib && /^name *= *"CerberusLean"/ { name="CerberusLean" }
    inlib && name=="CerberusLean" && /^roots *= *\[/ { inroots=1; sub(/^roots *= *\[/, ""); }
    inroots { line=$0; gsub(/#.*/, "", line); if (line ~ /\]/) { inroots=0; sub(/\].*/, "", line) }
              n=split(line, parts, ","); for (i=1;i<=n;i++) { p=parts[i]; gsub(/[[:space:]"]/, "", p); if (p!="") print p } }
  ' "$1" | LC_ALL=C sort
}

run_gate() {  # <lakefile.toml> <generated dir>
  local lake="$1" gen="$2" status=0
  local roots gens n
  roots=$(roots_of "$lake") || { echo "check_lakefile_roots: FAIL — cannot parse/sort roots"; return 1; }
  n=$(echo "$roots" | grep -c .)
  if [[ "$n" -lt "$MIN_ROOTS" ]]; then echo "check_lakefile_roots: FAIL (vacuous): only $n roots parsed from $lake (< $MIN_ROOTS)"; return 1; fi
  [[ -d "$gen" ]] || { echo "check_lakefile_roots: FAIL — missing generated directory $gen"; return 1; }
  gens=$(find "$gen" -maxdepth 1 -name '*.lean' ! -name 'Main.lean' -printf '%f\n' | sed 's/\.lean$//' | sort) || {
    echo "check_lakefile_roots: FAIL — cannot enumerate/sort generated modules"; return 1;
  }
  if [[ -z "$gens" ]]; then echo "check_lakefile_roots: FAIL (vacuous): no generated modules under $gen — regenerate first"; return 1; fi
  local missing extra
  missing=$(comm -13 <(echo "$roots") <(echo "$gens")) || { echo "check_lakefile_roots: FAIL — comm comparison failed"; return 1; }
  extra=$(comm -23 <(echo "$roots") <(echo "$gens")) || { echo "check_lakefile_roots: FAIL — comm comparison failed"; return 1; }
  if [[ -n "$missing" ]]; then echo "check_lakefile_roots: FAIL — generated module(s) NOT a Lake root (their obligations would never build):"; echo "$missing" | sed 's/^/  /'; status=1; fi
  if [[ -n "$extra" ]]; then echo "check_lakefile_roots: FAIL — Lake root(s) with no generated module:"; echo "$extra" | sed 's/^/  /'; status=1; fi
  local naux; naux=$(echo "$gens" | grep -c '_auxiliary$')
  # (NAME check only — this gate builds nothing; "all built" was an unbacked
  # claim until hotfix fix/fuel-forms-carriers 2026-09-20. check_fuel_forms.sh
  # builds every carrier it imports; build_lean builds the exe's closure.)
  [[ $status -eq 0 ]] && echo "check_lakefile_roots: OK ($n roots = $(echo "$gens" | grep -c .) generated modules + the exe root Main; $naux auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)"
  return $status
}

if [[ "${1:-}" == "--selftest" ]]; then
  echo "check_lakefile_roots: SELFTEST — planting on a scratch copy of lakefile.toml (loud plant banner; nothing in the tree is touched)"
  W=$(mktemp -d "${TMPDIR:-/tmp}/roots-plant.XXXXXX") || exit 1; trap 'rm -rf "$W"' EXIT
  fail=0
  # plant 1: drop one auxiliary root
  sed 's/"Core_aux_auxiliary", //' "$LF/lakefile.toml" > "$W/lakefile.toml"
  grep -q 'Core_aux_auxiliary' "$W/lakefile.toml" && { echo "  PLANT FAIL [drop]: sed did not remove the root" >&2; fail=1; }
  out=$(run_gate "$W/lakefile.toml" "$LF/generated"); rc=$?
  if [[ $rc -ne 0 ]] && grep -q "Core_aux_auxiliary" <<<"$out"; then echo "  PLANT OK   [dropped root Core_aux_auxiliary] -> $(head -1 <<<"$out")"; else echo "  PLANT FAIL [dropped root]: rc=$rc $out" >&2; fail=1; fi
  # plant 2: phantom root
  sed 's/"Core_aux_auxiliary", /"Core_aux_auxiliary", "Phantom_auxiliary", /' "$LF/lakefile.toml" > "$W/lakefile.toml"
  out=$(run_gate "$W/lakefile.toml" "$LF/generated"); rc=$?
  if [[ $rc -ne 0 ]] && grep -q "Phantom_auxiliary" <<<"$out"; then echo "  PLANT OK   [phantom root Phantom_auxiliary] -> $(head -1 <<<"$out")"; else echo "  PLANT FAIL [phantom root]: rc=$rc $out" >&2; fail=1; fi
  # plant 3: a generated module with no root (scratch copy of generated/)
  mkdir -p "$W/gen"; for f in "$LF"/generated/*.lean; do ln -s "$f" "$W/gen/"; done; : > "$W/gen/Orphan_auxiliary.lean"
  out=$(run_gate "$LF/lakefile.toml" "$W/gen"); rc=$?
  if [[ $rc -ne 0 ]] && grep -q "Orphan_auxiliary" <<<"$out"; then echo "  PLANT OK   [unrooted generated Orphan_auxiliary] -> $(head -1 <<<"$out")"; else echo "  PLANT FAIL [orphan]: rc=$rc $out" >&2; fail=1; fi
  # Plant 4: a broken comparison utility must never become an empty diff.
  mkdir "$W/bin"
  printf '#!/bin/sh\necho "planted comm failure" >&2\nexit 2\n' > "$W/bin/comm"
  chmod +x "$W/bin/comm"
  out=$(PATH="$W/bin:$PATH" run_gate "$LF/lakefile.toml" "$LF/generated" 2>&1); rc=$?
  if [[ $rc -ne 0 ]] && grep -q 'comm comparison failed' <<<"$out"; then echo '  PLANT OK   [failed comm]'; else echo "  PLANT FAIL [comm]: rc=$rc $out" >&2; fail=1; fi
  echo "  REVERTED (real lakefile + generated):"
  out=$(run_gate "$LF/lakefile.toml" "$LF/generated"); rc=$?; echo "  $out"
  [[ $rc -eq 0 ]] || { echo "  PLANT FAIL [green baseline]" >&2; fail=1; }
  [[ $fail -eq 0 ]] && echo "check_lakefile_roots: SELFTEST OK (4 plants red, baseline green)" || echo "check_lakefile_roots: SELFTEST FAILED" >&2
  exit $fail
fi
run_gate "$LF/lakefile.toml" "$LF/generated"
