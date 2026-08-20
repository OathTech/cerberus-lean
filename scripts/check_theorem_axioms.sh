#!/usr/bin/env bash
# Axiom-cone gate for the proof-test theorems (arc 2, S5a tripwire).
#
# Asserts the axiom dependencies of the exemplar definitions/theorems via
# #print axioms, so any change to the inhabitation machinery is measured,
# not narrated. Installed BEFORE the S5 failwith change (guardrail-first):
# starts by pinning the CURRENT known-tainted state; S5 flips EXPECT below
# to the clean state and the gate then enforces it forever.
#
# BOUNDARY HONESTY (arc-4 S5f, audit G3; updated arc-5 audit 2, F3): the
# probes below measure GENERATED exemplar cones + driver2 ONLY.
# Hand-written seams are outside every probe here. TWO hand-written
# AXIOMS exist on the pipeline and are part of the DECLARED boundary, not
# findings:
#   1. CerbTags.with_tagDefs (CerbTags.lean:70) — an `axiom` with
#      @[implemented_by] binding the C-side set/restore extent
#      (native/tags.c cerb_tags_with; the axiom form survives the DCE
#      that erased the opaque form, arc-4 S1r). Sits in the
#      Mini_pipeline (const-expr mini-run) cone, which no probe below
#      covers.
#   2. CerberusFresh.forceIO (CerberusFresh.lean:113) — an `axiom` with
#      @[implemented_by] pinning thunk evaluation to an IO position
#      (native/md5.c cerb_force_thunk; arc-5 S2 digest/fresh barrier).
#      Used from Main.lean and the unit tests — also outside every probe
#      below.
# A cheap CENSUS below counts '^axiom' across the hand-written .lean
# files and fails if the count differs from 2 (fail-closed: a third
# axiom must be consciously registered here). sorryAx remains forbidden
# everywhere probed. Declared-boundary records: 2026-08-19_arc4-results.md,
# 2026-08-19_arc5-results.md, 2026-08-20_arc7-results.md.
#
# SCOPE COMPANION (arc-7): the RelSem/proof-layer cones (slate theorems
# T1-T4, adequacy, the coupling) are NOT probed here — they are covered
# by the IN-BUILD audit lean_frontend/relsem/RelSem/Audit.lean (golean
# pattern: exhaustive sweep + exact #guard_msgs pins, build-failing,
# runs on plain `lake build` via defaultTargets) plus the in-build
# statement-TCB gate in the same file. This script's probes remain the
# generated-exemplar + driver2 legs, and its D14 grep leg scans
# lean_frontend/relsem/ (below).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Hand-written axiom census (arc-5 audit 2, F3): everything under
# lean_frontend/ EXCEPT generated/ and the build dir is hand-written.
# Exactly the two declared-boundary axioms may exist; any drift (third
# axiom, or a removal) fails until this gate is deliberately updated.
AXIOM_COUNT=$(find lean_frontend -name '*.lean' \
                -not -path 'lean_frontend/generated/*' \
                -not -path 'lean_frontend/.lake/*' -print0 \
              | xargs -0 grep -h '^axiom' | wc -l || true)
if [[ "$AXIOM_COUNT" -ne 2 ]]; then
  echo "check_theorem_axioms: FAIL — hand-written axiom census: found $AXIOM_COUNT '^axiom' declarations, expected exactly 2 (CerbTags.with_tagDefs, CerberusFresh.forceIO). Register any new axiom in the BOUNDARY HONESTY header deliberately."
  find lean_frontend -name '*.lean' \
    -not -path 'lean_frontend/generated/*' \
    -not -path 'lean_frontend/.lake/*' -print0 \
    | xargs -0 grep -n '^axiom' || true
  exit 1
fi
echo "check_theorem_axioms: hand-written axiom census OK (2 declared-boundary axioms)"

# ---------------------------------------------------------------------------
# D14 ban (arc-6): non-kernel proof methods (native_decide / bv_decide).
# Two legs, both fail-closed:
#   * grep leg (here): the banned tactics may not occur in the test/proof
#     sources — lean_frontend/test/**, lean_frontend/relsem/** (if that
#     tree exists on this branch), and the LemLib package's
#     lean-lib/LemLibTest.lean (the copy the build actually compiles).
#     Mandatory paths missing = FAIL, not skip.
#   * axiom leg (with the cone probes below): Lean.ofReduceBool /
#     Lean.ofReduceNat — the axioms those tactics introduce — are
#     ALWAYS-FATAL in every probed cone, alongside sorryAx.
# ---------------------------------------------------------------------------
D14_ROOT="$(pwd)"
D14_SCAN_PATHS=()
if [[ ! -d "$D14_ROOT/lean_frontend/test" ]]; then
  echo "check_theorem_axioms: FAIL — D14 grep-ban: $D14_ROOT/lean_frontend/test missing (fail-closed)"
  exit 1
fi
D14_SCAN_PATHS+=("$D14_ROOT/lean_frontend/test")
# relsem/ is optional per-branch; scan it iff present (absence is not a skip
# of a mandatory path — the tree simply doesn't exist on this branch).
if [[ -d "$D14_ROOT/lean_frontend/relsem" ]]; then
  D14_SCAN_PATHS+=("$D14_ROOT/lean_frontend/relsem")
fi
D14_LEMLIB_TEST="$D14_ROOT/lean_frontend/.lake/packages/LemLib/lean-lib/LemLibTest.lean"
if [[ ! -f "$D14_LEMLIB_TEST" ]]; then
  echo "check_theorem_axioms: FAIL — D14 grep-ban: $D14_LEMLIB_TEST missing (fail-closed)"
  exit 1
fi
D14_HITS=$(grep -rnE 'native_decide|bv_decide' "${D14_SCAN_PATHS[@]}" "$D14_LEMLIB_TEST" || true)
if [[ -n "$D14_HITS" ]]; then
  echo "check_theorem_axioms: FAIL — D14 ban: native_decide/bv_decide found in test/proof sources:"
  echo "$D14_HITS"
  exit 1
fi
echo "check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in ${#D14_SCAN_PATHS[@]} tree(s) + LemLibTest.lean)"

# EXPECT: default 'clean' since S5c landed (the merge-bar condition);
# 'daemon' documented the pre-S5 pinned state.
EXPECT="${CERB_AXIOM_EXPECT:-clean}"

PROBE=lean_frontend/.axiom-probe.lean
EXEMPLARS=(core_object_type_of_ctype get_membersDefs zeros_aux
           "fresh_symbol'" match_pattern convert_pexpr nd_bind
           subst_sym_pexpr)
{
  cat <<'EOF'
import Core_aux
import Ctype_aux
import Core_run
import Core_run_aux
import Nondeterminism
EOF
  for name in "${EXEMPLARS[@]}"; do
    echo "#print axioms $name"
  done
} > "$PROBE"
OUT=$(cd lean_frontend && "$SCRIPT_DIR/capped" lake env lean .axiom-probe.lean 2>&1 | grep -v -i warning || true)
rm -f "$PROBE"
echo "$OUT"

# Fail-closed (arc-4 S5f, audit G1 — same shape as the driver2 probe
# below): every probed exemplar must produce exactly one
# "depends on axioms"/"does not depend" line. A probe error (unknown
# constant, import failure, elaboration error) produces no such line for
# the name and FAILS the gate rather than silently passing the
# daemon/sorry greps against partial output.
for name in "${EXEMPLARS[@]}"; do
  n=$(grep -cE "'([A-Za-z0-9_.']*\.)?${name}' (depends on axioms|does not depend on any axioms)" <<<"$OUT" || true)
  if [[ "$n" -ne 1 ]]; then
    echo "check_theorem_axioms: FAIL — exemplar probe for '$name' did not run cleanly (matched $n lines; fail-closed)"
    exit 1
  fi
done

has_daemon=0
grep -q "DAEMON" <<<"$OUT" && has_daemon=1
# sorryAx anywhere in these cones is always a failure (no expectation
# under which the exemplar defs may depend on sorry).
if grep -q "sorryAx" <<<"$OUT"; then
  echo "check_theorem_axioms: FAIL — sorryAx in an exemplar cone"
  exit 1
fi
# D14 axiom leg: Lean.ofReduceBool / Lean.ofReduceNat (native_decide's
# axioms) are always fatal in every probed cone. Matched on the bare
# names so both qualified ('Lean.ofReduceBool') and unqualified probe
# spellings are caught.
if grep -qE 'ofReduce(Bool|Nat)' <<<"$OUT"; then
  echo "check_theorem_axioms: FAIL — ofReduceBool/ofReduceNat in an exemplar cone (D14 non-kernel proof-method ban)"
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
OUT2=$(cd lean_frontend && "$SCRIPT_DIR/capped" lake env lean .axiom-probe-driver2.lean 2>&1 | grep -v -i warning || true)
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
# D14 axiom leg, driver2 cone: same always-fatal ban as the exemplar set.
if grep -qE 'ofReduce(Bool|Nat)' <<<"$OUT2"; then
  echo "check_theorem_axioms: FAIL — ofReduceBool/ofReduceNat in driver2's kernel cone (D14 non-kernel proof-method ban)"
  exit 1
fi
echo "check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free (DAEMON allowed there, per arc-3 D9)"

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
