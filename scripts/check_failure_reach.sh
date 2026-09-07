#!/usr/bin/env bash
# check_failure_reach.sh — the failure-reach REGISTER gate (Tier B; fuel-pending
# close-out 2026-09-08 — option C of the pure-failure reachability census,
# lean_frontend/docs/2026-09-07_pure-failure-reachability-census.md; the TRIPWIRE
# the parked twin design docs/2026-09-07_pure-failure-correspondence-design.md
# names for its flip conditions).
#
# What it does, fail-closed at every step:
#   1. builds the declaration-dependency instrument tests/failure-probes/
#      FailureReach.lean as a fresh scratch Lake package requiring lean_frontend
#      by PATH (the run_failure_census.py recipe without the cold provider; a
#      fresh scratch dir so the probe module is always elaborated — ~6 s and
#      ~1.8 GB when the semantics is built; under scripts/capped, CERB_MEM_MAX
#      default 32G) -> reach.log (FAILURE_REACH / FAILURE_RANGE rows);
#   2. runs scripts/failure_census.py over THIS tree with that log -> census.json;
#   3. runs scripts/check_failure_reach.py: every PURE failure site in the exec
#      dependency closure (+ every pure site with an unresolved owner) must equal
#      a row of scripts/failure_reach_register.txt — same position class (the
#      census's Q1 classifier, scripts/failure_position.py), no DISCARDABLE
#      generated let-binding (the F1 shape), reviewed reach class, sealed row —
#      both directions; any NEW site, stale row, class move, DISCARDABLE position
#      or unsealed edit is RED with the rows named.
# --selftest: plants on SCRATCH COPIES (nothing in the tree is touched): a new
#   failwithI planted into a generated exec-closure definition -> RED naming it;
#   a DEAD `let _plant := (failwithI …)` planted into a generated definition ->
#   RED DISCARDABLE; a register row's reach class edited without re-seal -> RED
#   SEAL MISMATCH naming the row; a phantom (re-sealed) row -> RED STALE; the
#   tally line edited -> RED; the unplanted register -> the OK line.
# --emit [SEED]: print a fresh register seeded from SEED (default: the current
#   register; the first emission was seeded from the census evidence TSV
#   sites231_classified.tsv) — new rows UNREVIEWED; review, then
#   `check_failure_reach.py --reseal <file>`.
set -uo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$SCRIPT_DIR/.."
LF="$ROOT/lean_frontend"
REGISTER="$SCRIPT_DIR/failure_reach_register.txt"
CAPPED="$SCRIPT_DIR/capped"
PROBE="$ROOT/tests/failure-probes/FailureReach.lean"

MODE=gate
case "${1:-}" in
  "") ;;
  --selftest) MODE=selftest ;;
  --emit) MODE=emit; EMIT_SEED="${2:-}" ;;
  *) echo "check_failure_reach: usage: $0 [--selftest | --emit [SEED]]" >&2; exit 2 ;;
esac

for f in "$PROBE" "$LF/lean-toolchain" "$SCRIPT_DIR/failure_census.py" "$SCRIPT_DIR/failure_position.py" "$SCRIPT_DIR/check_failure_reach.py"; do
  [[ -f "$f" ]] || { echo "check_failure_reach: FAIL — missing $f (fail-closed)"; exit 1; }
done
[[ -d "$LF/generated" ]] || { echo "check_failure_reach: FAIL — $LF/generated missing (run make lean-prelude-src; fail-closed)"; exit 1; }
if [[ "$MODE" != emit && ! -f "$REGISTER" ]]; then echo "check_failure_reach: FAIL — register missing: $REGISTER (fail-closed)"; exit 1; fi

SCRATCH=$(mktemp -d); trap 'rm -rf "$SCRATCH"' EXIT
PKG="$SCRATCH/pkg"; mkdir -p "$PKG"
cp "$PROBE" "$PKG/FailureReach.lean"
cp "$LF/lean-toolchain" "$PKG/lean-toolchain"
cat > "$PKG/lakefile.toml" <<TOML
name = "FailureCensus"
defaultTargets = ["FailureReach"]
packagesDir = "$LF/.lake/packages"
[[require]]
name = "CerberusLean"
path = "$LF"
[[lean_lib]]
name = "FailureReach"
TOML
t0=$(date +%s)
if ! (cd "$PKG" && CERB_MEM_MAX="${CERB_MEM_MAX:-32G}" "$CAPPED" lake build > "$SCRATCH/reach.log" 2>&1); then
  echo "check_failure_reach: FAIL — the reach instrument build failed (fail-closed); log tail:"; tail -20 "$SCRATCH/reach.log"; exit 1
fi
if ! grep -q 'Build completed successfully' "$SCRATCH/reach.log"; then
  echo "check_failure_reach: FAIL — reach build did not complete (no 'Build completed successfully'); log tail:"; tail -20 "$SCRATCH/reach.log"; exit 1
fi
n_reach=$(grep -c $'FAILURE_REACH\t' "$SCRATCH/reach.log")
n_range=$(grep -c $'FAILURE_RANGE\t' "$SCRATCH/reach.log")
if ! python3 "$SCRIPT_DIR/failure_census.py" --root "$ROOT" --reach-log "$SCRATCH/reach.log" --out "$SCRATCH/census.json" > "$SCRATCH/census.counts" 2> "$SCRATCH/census.err"; then
  echo "check_failure_reach: FAIL — failure_census.py failed (fail-closed):"; cat "$SCRATCH/census.err"; exit 1
fi
t1=$(date +%s)
# FAILURE_REACH_KEEP=<dir>: keep reach.log + census.json there (evidence for a record)
if [[ -n "${FAILURE_REACH_KEEP:-}" ]]; then mkdir -p "$FAILURE_REACH_KEEP" && cp "$SCRATCH/reach.log" "$SCRATCH/census.json" "$FAILURE_REACH_KEEP/"; fi
echo "check_failure_reach: instrument built + census taken in $((t1-t0)) s (FAILURE_REACH rows $n_reach, FAILURE_RANGE rows $n_range; counts: $(tr -d ' \n' < "$SCRATCH/census.counts"))"

if [[ "$MODE" == emit ]]; then
  seed=(); if [[ -n "${EMIT_SEED:-}" ]]; then seed=(--seed "$EMIT_SEED"); elif [[ -f "$REGISTER" ]]; then seed=(--seed "$REGISTER"); fi
  python3 "$SCRIPT_DIR/check_failure_reach.py" --root "$ROOT" --census "$SCRATCH/census.json" --emit "${seed[@]}"
  exit $?
fi

if [[ "$MODE" == gate ]]; then
  python3 "$SCRIPT_DIR/check_failure_reach.py" --root "$ROOT" --census "$SCRATCH/census.json" --register "$REGISTER"
  exit $?
fi

# ---------------------------------------------------------------- --selftest
echo "check_failure_reach: SELFTEST — plants on scratch copies of the scanned sources and the register (loud plant banner; nothing in the tree is touched)"
fails=0
P="$SCRATCH/plant"; mkdir -p "$P/lean_frontend/generated"
cp "$LF"/*.lean "$P/lean_frontend/"; cp "$LF"/generated/*.lean "$P/lean_frontend/generated/"
# plant <label> <expected-substring>... : runs the census on $P + the check against $PLANT_REG; expects RED with every substring
plant() {
  local label="$1"; shift
  local out rc
  if ! python3 "$SCRIPT_DIR/failure_census.py" --root "$P" --reach-log "$SCRATCH/reach.log" --out "$SCRATCH/plant.json" > /dev/null 2> "$SCRATCH/plant.err"; then
    echo "  PLANT FAIL [$label]: the census on the planted copy failed:"; cat "$SCRATCH/plant.err"; fails=$((fails+1)); return
  fi
  out=$(python3 "$SCRIPT_DIR/check_failure_reach.py" --root "$P" --census "$SCRATCH/plant.json" --register "$PLANT_REG" 2>&1); rc=$?
  local ok=1 s
  (( rc != 0 )) || ok=0
  for s in "$@"; do grep -qF -- "$s" <<<"$out" || ok=0; done
  if (( ok )); then echo "  PLANT OK   [$label] rc=$rc -> $(grep -m1 -F -- "$1" <<<"$out" | cut -c1-230)"
  else echo "  PLANT FAIL [$label]: rc=$rc (wanted nonzero) with all of: $*"; sed 's/^/      /' <<<"$out"; fails=$((fails+1)); fi
}
restore() { cp "$LF/generated/Core_aux.lean" "$P/lean_frontend/generated/Core_aux.lean"; }
PLANT_REG="$REGISTER"
# P1: a NEW failwithI inside a generated exec-closure definition (valueFromPexpr's catch-all arm),
#     same line count so the compiler ranges of the real reach log still apply
ln=$(grep -n '^def  valueFromPexpr ' "$P/lean_frontend/generated/Core_aux.lean" | head -1 | cut -d: -f1)
[[ -n "$ln" ]] || { echo "  PLANT FAIL [P1 premise]: no 'def  valueFromPexpr ' line in generated/Core_aux.lean"; fails=$((fails+1)); }
python3 - "$P/lean_frontend/generated/Core_aux.lean" "$ln" <<'PY'
import sys; p, ln = sys.argv[1], int(sys.argv[2]); L = open(p).read().split('\n')
old = '|  _ =>        none'; assert old in L[ln-1], L[ln-1][:200]
L[ln-1] = L[ln-1].replace(old, '|  _ => (failwithI  "PLANT-NEW-SITE" : Option (value))', 1); open(p, 'w').write('\n'.join(L))
PY
plant "P1 a new failwithI planted into generated valueFromPexpr" "NEW pure exec-closure site" "PLANT-NEW-SITE" "valueFromPexpr"
restore
# P2: a DEAD let-binding of a failure in a generated definition (the F1 shape) -> DISCARDABLE
ln=$(grep -n '^def  valueFromPexprs ' "$P/lean_frontend/generated/Core_aux.lean" | head -1 | cut -d: -f1)
python3 - "$P/lean_frontend/generated/Core_aux.lean" "$ln" <<'PY'
import sys; p, ln = sys.argv[1], int(sys.argv[2]); L = open(p).read().split('\n')
assert L[ln-1].rstrip().endswith(':='), L[ln-1][-60:]
L[ln-1] = L[ln-1].rstrip() + ' let _plant := (failwithI  "PLANT-DEAD" : Nat);'; open(p, 'w').write('\n'.join(L))
PY
plant "P2 a DEAD let-bound failwithI planted into generated valueFromPexprs (the F1 shape)" "DISCARDABLE position" "PLANT-DEAD"
restore
# P3: a register row's reach class edited without re-seal
cp "$REGISTER" "$SCRATCH/reg.p3"
python3 - "$SCRATCH/reg.p3" <<'PY'
import sys; p = sys.argv[1]; L = open(p).read().split('\n'); done = False
for i, l in enumerate(L):
    f = l.split('\t')
    if len(f) == 12 and f[7] == 'REACHABLE' and not done:
        f[7] = 'UNKNOWN'; L[i] = '\t'.join(f); done = True; print('edited:', f[0], f[1], f[3][:40])
assert done
open(p, 'w').write('\n'.join(L))
PY
PLANT_REG="$SCRATCH/reg.p3"; plant "P3 a REACHABLE row's reach class edited to UNKNOWN without --reseal" "SEAL MISMATCH"
# P4: a phantom row, properly re-sealed -> STALE
cp "$REGISTER" "$SCRATCH/reg.p4"
printf 'lean_frontend/generated/Core_aux.lean\tphantom_def\tfailwithI\t"phantom"\tEXEC\tTAIL\tTAIL\tUNKNOWN\tplanted\t-\t-\t0000000000000000\n' >> "$SCRATCH/reg.p4"
python3 "$SCRIPT_DIR/check_failure_reach.py" --reseal "$SCRATCH/reg.p4" > /dev/null || { echo "  PLANT FAIL [P4 premise]: reseal failed"; fails=$((fails+1)); }
PLANT_REG="$SCRATCH/reg.p4"; plant "P4 a phantom register row (re-sealed) -> stale" "STALE register row" "phantom_def"
# P5: the tally line edited
sed 's/^# tally: sites=\([0-9]*\)/# tally: sites=0/' "$REGISTER" > "$SCRATCH/reg.p5"
cmp -s "$REGISTER" "$SCRATCH/reg.p5" && { echo "  PLANT FAIL [P5 premise]: the sed did not alter the tally line (vacuous plant)"; fails=$((fails+1)); }
PLANT_REG="$SCRATCH/reg.p5"; plant "P5 the tally line edited" "tally"
# unplanted: the real register against the real census
echo "  UNPLANTED:"
if out=$(python3 "$SCRIPT_DIR/check_failure_reach.py" --root "$ROOT" --census "$SCRATCH/census.json" --register "$REGISTER" 2>&1); then
  sed 's/^/    /' <<<"$out"
else
  echo "  PLANT FAIL [unplanted register is not green]:"; sed 's/^/      /' <<<"$out"; fails=$((fails+1))
fi
if (( fails == 0 )); then
  echo "check_failure_reach: SELFTEST OK (5 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally — and the unplanted register green)"; exit 0
else
  echo "check_failure_reach: SELFTEST FAILED ($fails)"; exit 1
fi
