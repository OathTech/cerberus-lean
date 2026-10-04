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
#   tally line edited -> RED; a registered lem_if arm / lemSeq continuation with its head mis-shaped
#   -> RED POSITION CLASS CHANGED (P6/P7, lem re-pin 2026-09-30); the two Formatted.convert rows'
#   reach classes swapped together with their seals -> RED SEAL MISMATCH (P8, key groups 2026-10-04);
#   classifier witnesses C1-C7 on synthetic sources; key-group witness K1 (an undisambiguable group
#   -> loud FAIL); the unplanted register -> the OK line.
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
#     same line count so the compiler ranges of the real reach log still apply. Since the lem re-pin
#     to 4e70bb5 (2026-10-04, [AGENT]; docs/2026-10-04_lem-repin-4e70bb5-record.md) the generated
#     definitions are laid out over several lines: the arm is the one `| _ => none` line within the
#     definition (the next 8 lines), asserted; the head match is whitespace-robust.
ln=$(grep -nE '^def +valueFromPexpr ' "$P/lean_frontend/generated/Core_aux.lean" | head -1 | cut -d: -f1)
[[ -n "$ln" ]] || { echo "  PLANT FAIL [P1 premise]: no 'def valueFromPexpr ' line in generated/Core_aux.lean"; fails=$((fails+1)); }
python3 - "$P/lean_frontend/generated/Core_aux.lean" "$ln" <<'PY'
import re, sys; p, ln = sys.argv[1], int(sys.argv[2]); L = open(p).read().split('\n')
arm = [i for i in range(ln - 1, min(ln + 8, len(L))) if re.fullmatch(r'\s*\|\s*_\s*=>\s*none\s*', L[i])]
assert len(arm) == 1, 'P1 premise: the catch-all arm `| _ => none` of valueFromPexpr not found exactly once'
L[arm[0]] = re.sub(r'none\s*$', '(failwithI  "PLANT-NEW-SITE" : Option (value))', L[arm[0]]); open(p, 'w').write('\n'.join(L))
PY
plant "P1 a new failwithI planted into generated valueFromPexpr" "NEW pure exec-closure site" "PLANT-NEW-SITE" "valueFromPexpr"
restore
# P2: a DEAD let-binding of a failure in a generated definition (the F1 shape) -> DISCARDABLE
ln=$(grep -nE '^def +valueFromPexprs ' "$P/lean_frontend/generated/Core_aux.lean" | head -1 | cut -d: -f1)
[[ -n "$ln" ]] || { echo "  PLANT FAIL [P2 premise]: no 'def valueFromPexprs ' line in generated/Core_aux.lean"; fails=$((fails+1)); }
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
# P6/P7 (lem re-pin 77ad4fa, 2026-09-30; record lean_frontend/docs/2026-09-30_lem-repin-77ad4fa-record.md):
#   the classifier's lem_if (B13) and lemSeq (B15/B15b) shapes are LOAD-BEARING — mis-shape the real
#   registered sites and the gate must go RED on the position class.
restore_f() { cp "$LF/generated/$1" "$P/lean_frontend/generated/$1"; }
PLANT_REG="$REGISTER"
# P6: showNonNegativeWithBasis's failure is the `then` arm of a `lem_if` (register: TAIL); with EVERY
#     `lem_if` of the file mis-shaped to `lem_iff` it must read OTHER-IF. (Every one, not just this
#     site's: the classifier's then/else walk-back does not stop at declaration headers, so an earlier
#     `lem_if` in the file would satisfy it — measured; the premise also asserts the file has no plain
#     `if`, so the plant cannot be satisfied by one.)
if python3 - "$SCRIPT_DIR" "$P/lean_frontend/generated/Formatted.lean" <<'PY'
import re, sys; sys.path.insert(0, sys.argv[1]); import failure_census as fc
p = sys.argv[2]; s = open(p).read()
assert len(re.findall(r'lem_if\s+natLtb\s+n\s+(?:\(\s*0\)|0)\s+then\s+\(failwithI\s+"showNonNegativeWithBasis expects', s)) == 1, 'P6 premise: the lem_if arm of showNonNegativeWithBasis not found exactly once'
assert not re.search(r'(?<![\w.])if\s', fc.strip_comments(s)), 'P6 premise: Formatted.lean has a plain `if` token (the plant would be satisfiable by it)'
open(p, 'w').write(re.sub(r'\blem_if\b', 'lem_iff', s))
PY
then
  plant "P6 the lem_if heads of Formatted.lean mis-shaped (lem_iff): a registered TAIL arm" "POSITION CLASS CHANGED" "showNonNegativeWithBasis" "live=OTHER-IF register=TAIL"
else echo "  PLANT FAIL [P6 premise]: the plant could not be applied (see above)"; fails=$((fails+1)); fi
restore_f Formatted.lean
# P7: hack_lemFuel's failure sits in the continuation (second) lambda of `lemSeq` (register: TAIL); an
#     unknown head `lemSeqX` in its place must read LAMBDA-BODY
if python3 - "$P/lean_frontend/generated/Driver.lean" <<'PY'
import re, sys; p = sys.argv[1]; s = open(p).read()
# whitespace/parenthesis-robust since the lem re-pin to 4e70bb5 (multi-line layout, atoms unparenthesised)
pat = r'\(lemSeq(?=\s+\(fun _ =>\s+CerbDebug\.print_debug_pure\s+(?:\(\s*2\)|2)\s+\(\[\] : List (?:\(domain\)|domain)\)\s+\(fun \(u : Unit\) =>\s+match u with\s*\|\s*\(\) =>\s+"ENTERING Driver\.hack")'
assert len(re.findall(pat, s)) == 1, 'P7 premise: the lemSeq head of hack_lemFuel not found exactly once'
open(p, 'w').write(re.sub(pat, '(lemSeqX', s))
PY
then
  plant "P7 the lemSeq head of a registered TAIL continuation mis-shaped (lemSeqX)" "POSITION CLASS CHANGED" "hack_lemFuel" "live=LAMBDA-BODY register=TAIL"
else echo "  PLANT FAIL [P7 premise]: the plant could not be applied (see above)"; fails=$((fails+1)); fi
restore_f Driver.lean
# P8 (fix/failure-reach-key-groups 2026-10-04, [USER 2026-10-04] "agree 1-4" / "Great, do it as
#     proposed" on the lem re-pin 4e70bb5 pre-merge audit's A3; record
#     lean_frontend/docs/2026-10-04_failure-reach-key-groups-record.md): the two Formatted.convert
#     `* prec` rows (REACHABLE for the :874 arm, UNREACHABLE-BY-INVARIANT for :1063) shared one
#     60-char key, so swapping their reach classes TOGETHER WITH their seals passed every check. Key
#     groups now carry a lengthened message window; the same swap must be RED SEAL MISMATCH.
cp "$REGISTER" "$SCRATCH/reg.p8"
if python3 - "$SCRATCH/reg.p8" <<'PY8'
import sys; p = sys.argv[1]; L = open(p).read().split('\n')
ix = [i for i, l in enumerate(L) if len(f := l.split('\t')) == 12 and f[0] == 'lean_frontend/generated/Formatted.lean'
      and f[1] == 'convert' and f[3].startswith('"TODO: Formatted.convert, * prec"')]
assert len(ix) == 2, f'P8 premise: {len(ix)} Formatted.convert `* prec` rows, expected 2'
a, b = L[ix[0]].split('\t'), L[ix[1]].split('\t')
assert a[7] != b[7], f'P8 premise: both rows have reach {a[7]} (the swap would be vacuous)'
for c in (7, 11): a[c], b[c] = b[c], a[c]   # reach class and seal, together
L[ix[0]], L[ix[1]] = '\t'.join(a), '\t'.join(b); open(p, 'w').write('\n'.join(L))
PY8
then
  PLANT_REG="$SCRATCH/reg.p8"; plant "P8 the two Formatted.convert rows' reach classes swapped WITH their seals (audit A3)" "SEAL MISMATCH" "Formatted.convert, * prec"
else echo "  PLANT FAIL [P8 premise]: the plant could not be applied (see above)"; fails=$((fails+1)); fi
PLANT_REG="$REGISTER"
# K1: a key group whose sites agree even on the full recorded message window cannot be keyed
#     one-to-one -> loud FAIL naming the group (synthetic sites; the check's own function)
if out=$(python3 - "$SCRIPT_DIR" <<'PYK' 2>&1
import sys; sys.path.insert(0, sys.argv[1]); import check_failure_reach as c
s = lambda line, fol: {'file': 'F.lean', 'definition': 'd', 'token': 'failwithI', 'scope': 'EXEC', 'line': line,
                       'following': fol, 'msg': c.msg_key(fol)}
ok = c.disambiguate_key_groups([s(1, '"x' * 40 + ' A'), s(2, '"x' * 40 + ' B'), s(3, '"solo"')])
assert [x['msg'] for x in ok] == ['"x' * 40 + ' A', '"x' * 40 + ' B', '"solo"'], [x['msg'] for x in ok]
try: c.disambiguate_key_groups([s(1, '"same" rest'), s(2, '"same"   rest')])
except SystemExit as e: print(e); sys.exit(0)
print('no FAIL raised'); sys.exit(1)
PYK
) && grep -qF 'key group cannot be disambiguated' <<<"$out" && grep -qF 'at lines 1, 2' <<<"$out"; then
  echo "  WITNESS OK   [K1 an undisambiguable key group -> FAIL naming it; a disambiguable one keyed minimally, a single site unchanged] $(cut -c1-160 <<<"$out")"
else echo "  PLANT FAIL [K1 key-group witness]:"; sed 's/^/    /' <<<"$out"; fails=$((fails+1)); fi
# C1-C7: classifier witnesses on synthetic generated-shaped sources (positive shapes and controls)
mkdir -p "$SCRATCH/syn/lean_frontend/generated"
if out=$(python3 - "$SCRIPT_DIR" "$SCRATCH/syn" <<'PY'
import sys; sys.path.insert(0, sys.argv[1]); import failure_position as fp
from pathlib import Path
cases = [  # (label, source, expected class of the single failwithI)
  ('C1 lem_if then-arm', 'def  f  (c : Bool)  : Nat := \n  lem_if  c then (failwithI  "x" : Nat) else  0\n', 'TAIL'),
  ('C2 lem_if else-arm', 'def  f  (c : Bool)  : Nat := \n  lem_if  c then  0 else (failwithI  "x" : Nat)\n', 'TAIL'),
  ('C3 lem_if condition', 'def  f  (c : Bool)  : Nat := \n  lem_if (failwithI  "x" : Bool) then  0 else  1\n', 'SCRUTINEE'),
  ('C4 lemSeq continuation', 'def  f  (n : Nat)  : Nat := \n  (lemSeq (fun _ =>  dbg  n) (fun _ =>  (failwithI  "x" : Nat)))\n', 'TAIL'),
  ('C5 lemSeq continuation inside a lem_if arm', 'def  f  (c : Bool)  : Nat := \n  lem_if  c then (lemSeq (fun _ =>  dbg  0) (fun _ =>  (failwithI  "x" : Nat))) else  0\n', 'TAIL'),
  ('C6 control: lemSeq DISCARDED side is not tail', 'def  f  (n : Nat)  : Nat := \n  (lemSeq (fun _ =>  (failwithI  "x" : Nat)) (fun _ =>  n))\n', 'LAMBDA-BODY'),
  ('C7 control: another head is not lemSeq', 'def  f  (n : Nat)  : Nat := \n  (other (fun _ =>  dbg  n) (fun _ =>  (failwithI  "x" : Nat)))\n', 'LAMBDA-BODY'),
]
root = Path(sys.argv[2]); bad = 0
for i, (label, src, want) in enumerate(cases):
    rel = f'lean_frontend/generated/Syn{i}.lean'; (root / rel).write_text(src)
    got = fp.Classifier(root).classify(rel, src.index('failwithI'))['cls']
    ok = got == want; bad += not ok
    print(f"  {'WITNESS OK  ' if ok else 'WITNESS FAIL'} [{label}] {got}" + ('' if ok else f' (wanted {want})'))
sys.exit(1 if bad else 0)
PY
); then echo "$out"; else echo "  PLANT FAIL [classifier witnesses C1-C7]:"; sed 's/^/    /' <<<"$out"; fails=$((fails+1)); fi
# unplanted: the real register against the real census
echo "  UNPLANTED:"
if out=$(python3 "$SCRIPT_DIR/check_failure_reach.py" --root "$ROOT" --census "$SCRATCH/census.json" --register "$REGISTER" 2>&1); then
  sed 's/^/    /' <<<"$out"
else
  echo "  PLANT FAIL [unplanted register is not green]:"; sed 's/^/      /' <<<"$out"; fails=$((fails+1))
fi
if (( fails == 0 )); then
  echo "check_failure_reach: SELFTEST OK (8 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation, a same-owner reach+seal swap (A3) — 7 classifier witnesses (lem_if arms/condition, lemSeq continuation, controls), the key-group witness K1 and the unplanted register green)"; exit 0
else
  echo "check_failure_reach: SELFTEST FAILED ($fails)"; exit 1
fi
