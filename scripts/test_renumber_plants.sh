#!/usr/bin/env bash
# test_renumber_plants.sh — plant battery for check_renumber_only.py
# (effect-retirement C2 step 3; C1 audit minor-1 remediation).
#
# Runs every fixture pair in tests/renumber_plants/ against the
# adjudication instrument and asserts the MANIFEST-declared verdict:
#   FAIL         — the pair must be REFUSED (exit 1): these are the
#                  adversarial pairs (s5/l1/l3/l4 string/comment holes,
#                  reconstructed [AGENT] from the audit's hole
#                  descriptions) + the re-committed C1-era plants
#                  (count mismatch, appended line, token change,
#                  section reorder).
#   ADMIT-STRICT / ADMIT-LAYOUT — the positive controls must be
#                  admitted with exactly that class (vacuity guard: a
#                  gate that refuses everything is as broken as one
#                  that admits everything).
# Fail-closed: missing fixture dir, empty manifest, or a missing pair
# file is an error, never a skip.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
PLANTS=tests/renumber_plants
CHECK=scripts/check_renumber_only.py

[[ -d "$PLANTS" ]] || { echo "test_renumber_plants: FAIL — $PLANTS missing (fail-closed)"; exit 1; }
[[ -f "$PLANTS/MANIFEST" ]] || { echo "test_renumber_plants: FAIL — $PLANTS/MANIFEST missing (fail-closed)"; exit 1; }

ROWS=$(grep -vE '^\s*(#|$)' "$PLANTS/MANIFEST" || true)
if [[ -z "$ROWS" ]]; then
  echo "test_renumber_plants: FAIL — MANIFEST has no fixture rows (fail-closed)"
  exit 1
fi

fails=0
total=0
while read -r name expected; do
  total=$((total + 1))
  old="$PLANTS/$name.old"; new="$PLANTS/$name.new"
  if [[ ! -f "$old" || ! -f "$new" ]]; then
    echo "test_renumber_plants: FAIL — fixture pair '$name' missing ($old / $new)"
    exit 1
  fi
  set +e
  out=$(python3 "$CHECK" "$old" "$new" --label "plant/$name" 2>&1)
  rc=$?
  set -e
  case "$expected" in
    FAIL)
      if [[ "$rc" -eq 1 && "$out" == *"RENUMBER-ONLY"* && "$out" != *" ADMIT "* ]]; then
        echo "  OK (refused as declared): $name"
      else
        echo "  PLANT FAILURE: $name expected FAIL, got rc=$rc: $out"
        fails=$((fails + 1))
      fi
      ;;
    ADMIT-STRICT|ADMIT-LAYOUT)
      cls=${expected#ADMIT-}
      if [[ "$rc" -eq 0 && "$out" == *"RENUMBER-ONLY ADMIT plant/$name class=$cls "* ]]; then
        echo "  OK (admitted as declared): $name [$out]"
      else
        echo "  PLANT FAILURE: $name expected $expected, got rc=$rc: $out"
        fails=$((fails + 1))
      fi
      ;;
    *)
      echo "test_renumber_plants: FAIL — unknown expectation '$expected' for '$name'"
      exit 1
      ;;
  esac
done <<<"$ROWS"

if [[ "$fails" -ne 0 ]]; then
  echo "test_renumber_plants: FAIL ($fails of $total plants misbehaved)"
  exit 1
fi
echo "test_renumber_plants: OK ($total plants: refusals refuse, admits admit with declared class)"
