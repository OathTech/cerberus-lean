#!/usr/bin/env bash
# Axiom-cone gate for the proof-test theorems (arc 2, S5a tripwire).
#
# Asserts the axiom dependencies of the exemplar definitions/theorems via
# #print axioms, so any change to the inhabitation machinery is measured,
# not narrated. Installed BEFORE the S5 failwith change (guardrail-first):
# starts by pinning the CURRENT known-tainted state; S5 flips EXPECT below
# to the clean state and the gate then enforces it forever.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# EXPECT: default 'clean' since S5c landed (the merge-bar condition);
# 'daemon' documented the pre-S5 pinned state.
EXPECT="${CERB_AXIOM_EXPECT:-clean}"

PROBE=lean_frontend/.axiom-probe.lean
cat > "$PROBE" <<'EOF'
import Core_aux
import Ctype_aux
import Core_run
import Core_run_aux
import Nondeterminism
#print axioms core_object_type_of_ctype
#print axioms get_membersDefs
#print axioms zeros_aux
#print axioms fresh_symbol'
#print axioms match_pattern
#print axioms convert_pexpr
#print axioms nd_bind
#print axioms subst_sym_pexpr
EOF
OUT=$(cd lean_frontend && lake env lean .axiom-probe.lean 2>&1 | grep -v -i warning || true)
rm -f "$PROBE"
echo "$OUT"

has_daemon=0
grep -q "DAEMON" <<<"$OUT" && has_daemon=1
# sorryAx anywhere in these cones is always a failure (no expectation
# under which the exemplar defs may depend on sorry).
if grep -q "sorryAx" <<<"$OUT"; then
  echo "check_theorem_axioms: FAIL — sorryAx in an exemplar cone"
  exit 1
fi

# driver2 kernel-cone probe (arc 4, success condition 2): the execution
# driver's cone must be sorryAx-FREE. DAEMON is ALLOWED here (driver2 is
# NOT part of the DAEMON-clean exemplar set above — recorded per arc-3 D9);
# only sorry taints fail. Separate probe so driver2's DAEMON cannot leak
# into the clean-set check. Fails closed: a probe error (e.g. unknown
# constant) produces no "depends on axioms"/"does not depend" line and
# fails the assertion below.
PROBE2=lean_frontend/.axiom-probe-driver2.lean
cat > "$PROBE2" <<'EOF'
import Driver
#print axioms driver2
EOF
OUT2=$(cd lean_frontend && lake env lean .axiom-probe-driver2.lean 2>&1 | grep -v -i warning || true)
rm -f "$PROBE2"
echo "$OUT2"
if ! grep -q "'driver2' \(depends on axioms\|does not depend on any axioms\)" <<<"$OUT2"; then
  echo "check_theorem_axioms: FAIL — driver2 probe did not run (fail-closed)"
  exit 1
fi
if grep -q "sorryAx" <<<"$OUT2"; then
  echo "check_theorem_axioms: FAIL — sorryAx in driver2's kernel cone (arc-4 success condition 2)"
  exit 1
fi
echo "check_theorem_axioms: driver2 cone sorryAx-free (DAEMON allowed there, per arc-3 D9)"

case "$EXPECT" in
  daemon)
    if [[ $has_daemon -eq 1 ]]; then
      echo "check_theorem_axioms: OK (pinned pre-S5 state: DAEMON present, as recorded)"
    else
      echo "check_theorem_axioms: state CHANGED (DAEMON gone) — flip EXPECT to 'clean' deliberately, with a commit explaining why"
      exit 1
    fi ;;
  clean)
    if [[ $has_daemon -eq 0 ]]; then
      echo "check_theorem_axioms: OK (post-S5 bar: DAEMON-clean cones)"
    else
      echo "check_theorem_axioms: FAIL — DAEMON re-entered a theorem cone"
      exit 1
    fi ;;
  *) echo "check_theorem_axioms: bad EXPECT '$EXPECT'"; exit 2 ;;
esac
