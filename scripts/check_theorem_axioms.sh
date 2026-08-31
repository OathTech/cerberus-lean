#!/usr/bin/env bash
# Axiom-cone gate for the proof-test theorems (arc 2, S5a tripwire).
#
# Asserts the axiom dependencies of the exemplar definitions/theorems via
# #print axioms, so any change to the inhabitation machinery is measured,
# not narrated. (History: installed guardrail-first before the arc-2 S5
# failwith change with an EXPECT staging toggle; since arc-8 S3 the
# DAEMON axiom family is DELETED from LemLib and the toggle is gone —
# DAEMON is unconditionally fatal in every probed cone.)
#
# BOUNDARY HONESTY (arc-4 S5f, audit G3; updated arc-5 audit 2, F3;
# END STATE arc-17 S2b, 2026-08-25): the probes below measure GENERATED
# exemplar cones + driver2 ONLY. Hand-written seams are outside every
# probe here. ZERO hand-written axioms exist in this repository: the
# two former declared-boundary axioms were DELETED (arc-17 S2b, the
# [USER 2026-08-24] temporal-mover execution):
#   1. CerbTags.with_tagDefs — was an `axiom` (arc-4 S1r), then an
#      `opaque` with a kernel-checked witness (arc-17 S2b), now
#      DELETED OUTRIGHT (effect-retirement C1, charter section 4): the
#      CerbTags global is gone; the linked table is passed as a value
#      (reader_consumer) and with_tagDefs's Lean meaning is the plain
#      application, a lem body in ctype_aux.lem.
#   2. CerberusFresh.forceIO — was an `axiom` (arc-5 S2), now an
#      `opaque` with witness `fun f => pure (f ())`. @[implemented_by]
#      still binds native/md5.c cerb_force_thunk — re-verified by
#      test/Unit/FreshIntTest.lean testDigestGlobal.
# Neither constant can appear in ANY axiom cone anymore (opaque
# definitions are not axioms).
# A cheap CENSUS below counts '^axiom' across the hand-written .lean
# files and fails if the count differs from 0 (fail-closed: any new
# axiom must be consciously registered here). sorryAx remains forbidden
# everywhere probed. Records: 2026-08-19_arc4-results.md,
# 2026-08-19_arc5-results.md, 2026-08-20_arc7-results.md,
# 2026-08-25_arc17-s2b-axiom-endgame.md (the deletion).
#
# (2026-08-31 semantics-first split: the proof packages and their
# in-build audit gates left with the reasoning layer — this script's
# probes are the generated-exemplar + driver2 legs, and its D14 grep
# leg scans lean_frontend/test + lean_frontend/relsemcore.)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Hand-written axiom census (arc-5 audit 2, F3; end state arc-17 S2b):
# everything under lean_frontend/ EXCEPT generated/ and the build dir
# is hand-written. ZERO axioms may exist (the former two
# declared-boundary axioms are now kernel-checked opaques — header
# above); any new '^axiom' fails until this gate is deliberately
# updated with a registered justification.
AXIOM_COUNT=$(find lean_frontend -name '*.lean' \
                -not -path 'lean_frontend/generated/*' \
                -not -path 'lean_frontend/.lake/*' -print0 \
              | xargs -0 grep -h '^axiom' | wc -l || true)
if [[ "$AXIOM_COUNT" -ne 0 ]]; then
  echo "check_theorem_axioms: FAIL — hand-written axiom census: found $AXIOM_COUNT '^axiom' declarations, expected exactly 0 (the boundary axioms were deleted in arc-17 S2b — with_tagDefs/forceIO are opaques now). Register any new axiom in the BOUNDARY HONESTY header deliberately."
  find lean_frontend -name '*.lean' \
    -not -path 'lean_frontend/generated/*' \
    -not -path 'lean_frontend/.lake/*' -print0 \
    | xargs -0 grep -n '^axiom' || true
  exit 1
fi
echo "check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)"

# ---------------------------------------------------------------------------
# Tree-wide generated/ axiom census (arc-8 audit fix, auditor B F1;
# end state arc-17 S2b).
# NAME-INDEPENDENT and file-complete: the in-build Audit.lean sweep sees
# the import closure of the audited roots + the probed cones above, but a
# generated file OUTSIDE that closure (e.g. Core_indet.lean) could carry
# an axiom no other gate would meet. This census scans EVERY
# lean_frontend/generated/*.lean with a lexer-grade scanner (same
# stripping discipline as check_exec_totality.sh: strings, char
# literals, `--` line comments, nested /- -/ block comments removed
# before matching) for:
#   * `axiom` declarations — the allowlist is EMPTY since arc-17 S2b
#     (the two former boundary axioms are opaques now): ANY axiom in
#     ANY generated file = FAIL.
#   * scanner/copy-pipeline LIVENESS (fail-closed replacement for the
#     old "each allowlisted axiom found exactly once" leg): the two
#     converted opaques must each be found exactly once in their build
#     copies (CerbTags.lean `opaque with_tagDefs`, CerberusFresh.lean
#     `opaque forceIO`) — their absence means the copy pipeline or the
#     scanner broke.
#   * `unsafeCast` — banned outright in generated code (no allowlist;
#     count is 0 as of the arc-8 audits).
# Missing directory or an empty scan = FAIL (fail-closed).
# ---------------------------------------------------------------------------
GEN_DIR=lean_frontend/generated
if [[ ! -d "$GEN_DIR" ]]; then
  echo "check_theorem_axioms: FAIL — generated-tree census: $GEN_DIR missing (fail-closed)"
  exit 1
fi
GEN_CENSUS=$(python3 - "$GEN_DIR" <<'PYEOF'
import glob, os, re, sys
gen_dir = sys.argv[1]
files = sorted(glob.glob(os.path.join(gen_dir, '*.lean')))
if not files:
    print("SCANEMPTY")
    sys.exit(0)
print(f"SCANNED {len(files)}")
for path in files:
    src = open(path).read()
    cur = []
    depth = 0
    i = 0
    n = len(src)
    while i < n:
        two = src[i:i+2]
        if depth > 0:
            if two == '/-': depth += 1; i += 2; continue
            if two == '-/': depth -= 1; i += 2; continue
            if src[i] == '\n': cur.append('\n')
            i += 1; continue
        if two == '/-':
            depth += 1; i += 2; continue
        if two == '--':
            j = src.find('\n', i)
            i = n if j == -1 else j
            continue
        c = src[i]
        if c == '"':
            cur.append(' '); i += 1
            while i < n:
                if src[i] == '\\': i += 2; continue
                if src[i] == '"': i += 1; break
                if src[i] == '\n': cur.append('\n')
                i += 1
            continue
        if c == '\'' and i + 1 < n and (src[i+1] == '\\' or (i + 2 < n and src[i+2] == '\'')):
            # char literal 'x' or '\n'
            j = src.find('\'', i + 2 if src[i+1] != '\\' else i + 3)
            i = (j + 1) if j != -1 else n
            cur.append(' ')
            continue
        cur.append(c); i += 1
    clean = ''.join(cur)
    base = os.path.basename(path)
    for m in re.finditer(r'\baxiom\s+([A-Za-z_0-9α-ω.\']+)', clean):
        line = clean.count('\n', 0, m.start()) + 1
        print(f"AXIOM {base}:{line}:{m.group(1)}")
    for m in re.finditer(r'\bopaque\s+(forceIO)\b', clean):
        line = clean.count('\n', 0, m.start()) + 1
        print(f"OPAQUE {base}:{line}:{m.group(1)}")
    for m in re.finditer(r'\bunsafeCast\b', clean):
        line = clean.count('\n', 0, m.start()) + 1
        print(f"UNSAFECAST {base}:{line}")
PYEOF
) || {
  echo "check_theorem_axioms: FAIL — generated-tree census: scanner failed (fail-closed)"
  exit 1
}
if grep -q '^SCANEMPTY$' <<<"$GEN_CENSUS"; then
  echo "check_theorem_axioms: FAIL — generated-tree census: no .lean files under $GEN_DIR (fail-closed)"
  exit 1
fi
if ! grep -q '^SCANNED ' <<<"$GEN_CENSUS"; then
  echo "check_theorem_axioms: FAIL — generated-tree census: scanner produced no SCANNED marker (fail-closed)"
  exit 1
fi
GEN_SCANNED=$(grep '^SCANNED ' <<<"$GEN_CENSUS" | awk '{print $2}')
GEN_AXIOMS=$(grep '^AXIOM ' <<<"$GEN_CENSUS" || true)
GEN_OPAQUES=$(grep '^OPAQUE ' <<<"$GEN_CENSUS" || true)
GEN_UNSAFE=$(grep '^UNSAFECAST ' <<<"$GEN_CENSUS" || true)
if [[ -n "$GEN_AXIOMS" ]]; then
  echo "check_theorem_axioms: FAIL — generated-tree census: axiom declaration(s) found (allowlist is EMPTY since arc-17 S2b — with_tagDefs/forceIO are opaques now; any axiom must be deliberately registered here):"
  echo "$GEN_AXIOMS"
  exit 1
fi
# Scanner/copy-pipeline liveness (fail-closed): the surviving converted
# opaque must be present exactly once in its build copy.
# (Effect-retirement C1: with_tagDefs LEFT the boundary list — the
# CerbTags global and its whole-extent opaque are deleted; charter
# section 7.2 "boundary-opaque expectation list shrinks". forceIO
# stays exactly-once; the digest opaque conversion is C2.)
for want in 'CerberusFresh\.lean:[0-9]+:forceIO'; do
  cnt=$(grep -cE "^OPAQUE ${want}$" <<<"$GEN_OPAQUES" || true)
  if [[ "$cnt" -ne 1 ]]; then
    echo "check_theorem_axioms: FAIL — generated-tree census: converted boundary opaque /${want}/ found $cnt times, expected exactly 1 (copy pipeline or scanner drift; fail-closed)"
    echo "$GEN_OPAQUES"
    exit 1
  fi
done
if [[ -n "$GEN_UNSAFE" ]]; then
  echo "check_theorem_axioms: FAIL — generated-tree census: unsafeCast in generated code (banned, no allowlist):"
  echo "$GEN_UNSAFE"
  exit 1
fi
echo "check_theorem_axioms: generated-tree census OK ($GEN_SCANNED files: 0 axioms, boundary opaques present, 0 unsafeCast)"

# ---------------------------------------------------------------------------
# D14 ban (arc-6): non-kernel proof methods (native_decide / bv_decide).
# Two legs, both fail-closed:
#   * grep leg (here): the banned tactics may not occur in the test
#     sources — lean_frontend/test/**, lean_frontend/relsemcore/**,
#     and the LemLib package's lean-lib/LemLibTest.lean (the copy the
#     build actually compiles). Mandatory paths missing = FAIL, not skip.
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
D14_SCAN_PATHS+=("$D14_ROOT/lean_frontend/relsemcore")
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

# DAEMON is DELETED (arc-8 S3): lem's DAEMON axiom family was removed
# from LemLib (it was logically inconsistent as declared — arc-7
# audit-1 F1) after the arc-8 S1/S2 backend passes (derived real
# Inhabited instances + failwithI threading) made it unreferenced.
# DAEMON is therefore FORBIDDEN in EVERY probed cone below, driver2
# included (the old arc-3 D9 "DAEMON allowed in driver2" allowance is
# removed, and the pre-arc-8 CERB_AXIOM_EXPECT staging toggle is gone —
# there is no expectation under which DAEMON may appear). Fail-closed:
# any DAEMON anywhere in any probed cone fails this gate.

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

# DAEMON anywhere in these cones is always a failure (arc-8 S3: the
# axiom family is deleted; reintroduction = build/gate failure forever).
if grep -q "DAEMON" <<<"$OUT"; then
  echo "check_theorem_axioms: FAIL — DAEMON in an exemplar cone (the DAEMON axiom family was DELETED in arc-8; it is forbidden everywhere)"
  exit 1
fi
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
# driver's cone must be sorryAx-FREE and — since arc-8 S3 — DAEMON-FREE
# like every other probed cone (the arc-3 D9 allowance is removed; the
# S2 boundary verified driver2's cone was already DAEMON-free before
# the deletion). Fails closed: a probe error (e.g. unknown constant)
# produces no "depends on axioms"/"does not depend" line and fails the
# assertion below.
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
# DAEMON leg, driver2 cone (arc-8 S3): forbidden like every other cone.
if grep -q "DAEMON" <<<"$OUT2"; then
  echo "check_theorem_axioms: FAIL — DAEMON in driver2's kernel cone (the DAEMON axiom family was DELETED in arc-8; the arc-3 D9 allowance is removed)"
  exit 1
fi
echo "check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)"

echo "check_theorem_axioms: OK (arc-8 S3 bar: DAEMON-free cones everywhere)"
