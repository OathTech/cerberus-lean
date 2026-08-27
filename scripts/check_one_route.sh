#!/bin/bash
# check_one_route.sh — arc-18 C2 (2026-08-25): THE SINGLE-INTERPRETATION
# GATE (closes register row R2 of
# lean_frontend/docs/2026-08-25_reasoning-layer-contracts.md §6; the
# arc-16 S2 record's §2.5 coexistence hazard, mechanized).
#
# THE CONTRACT (charter Q2 FULL, executed at C2): `CerbMemInterp` (the
# heap RA) is the ONE state interpretation of the live route. The
# whole-state OwnP interpretation survives only on the TRANSITIONAL
# surface (RelSem/PerStepOwnP.lean, C5-bound) consumed by the arc-7
# shell, the ambient family, the arc-16 smokes (retirement register
# entry 4).
#
# Semantics (fail-closed):
#   * LIVE-ROUTE MODULES (the contracts doc §7 non-retirements + the
#     migrated threaded walks) must not (a) import the transitional
#     OwnP surface or the arc-7 shell, nor (b) mention any OwnP
#     binding token (CerbGS / CerbGpreS / stateIs / OwnPGS / ownP /
#     CerbS) outside comments. Comment text is stripped before the
#     token scan (line comments and block comments) so design notes
#     may still NAME the retired interpretation.
#   * THE COEXISTENCE HAZARD: no .lean file anywhere in the proof
#     packages may bind BOTH `[CerbGS` and `[CerbHeapGS` (one WP
#     statement must select exactly one interpretation route).
#   * A listed live module that is MISSING is fatal (the list is the
#     gate's own registration; renames re-point it, never drop it).
#
# (The C2-era labeled T6 exemption is CLEARED — arc-18 R1, 2026-08-26:
#   T6Probe migrated to the heap route via the RoundEval OPEN-MEMORY
#   MINTING MODE, the exemption's named mover; T6Probe is now a
#   LIVE-ROUTE module below. Record:
#   lean_frontend/docs/2026-08-26_arc18-r1-open-memory.md.)
#   (PerStepSmoke/PerStepTacSmoke/the arc-7 shell/the ambient family
#   are NOT live-route modules — they are retirement-register entries
#   1/3/4, deleted at C5 with the transitional surface.)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT/lean_frontend"

LIVE_MODULES=(
  relsem/RelSem/PerStep.lean
  relsem/RelSem/PerStepIris.lean
  relsem/RelSem/PerStepCall.lean
  relsem/RelSem/PerStepTactics.lean
  relsem/RelSem/WpGround.lean
  relsem/RelSem/DeriveState.lean
  relsem/RelSem/RoundEval.lean
  relsem/RelSem/RoundEval/Core.lean
  relsem/RelSem/RoundEval/Hyp.lean
  relsem/RelSem/RoundEval/Mint.lean
  relsem/RelSem/RoundEval/Classify.lean
  relsem/RelSem/RoundEval/Arith.lean
  relsem/RelSem/RoundEval/Lanes.lean
  relsem/RelSem/RoundEval/Rounds.lean
  relsem/RelSem/RoundEval/Assembly.lean
  relsem/RelSem/ConstructLaws.lean
  relsem/RelSem/LawRegistry.lean
  relsem/RelSem/Kit/AppEq.lean
  relsem/RelSem/Kit/Audit.lean
  relsem/RelSem/Kit/Env.lean
  relsem/RelSem/Kit/Eval.lean
  relsem/RelSem/Kit/Loop.lean
  relsem/RelSem/Kit/Map.lean
  relsem/RelSem/Kit/Mem.lean
  relsem/RelSem/Kit/Round.lean
  relsem/RelSem/MemLocal.lean
  relsem/RelSem/CerbHeapRA.lean
  relsem/RelSem/CerbHeapWP.lean
  relsem/RelSem/CerbHeapWalk.lean
  relsem/RelSem/CerbHeapDemo.lean
  relsem/RelSem/Segment.lean
  relsem/RelSem/SegmentFaces.lean
  relsemcore/RelSem/Threaded.lean
  relsem/RelSem/T1Threaded.lean
  relsem/RelSem/T2Threaded.lean
  relsem/RelSem/T3Threaded.lean
  relsem/RelSem/T6Probe.lean
  relsem/RelSem/T7Walks.lean
  relsem/RelSem/T7.lean
)

BANNED_IMPORTS='^import[[:space:]]+RelSem\.(PerStepOwnP|IrisState|IrisLang|IrisRules|IrisAdequacy|SlateWP)([[:space:]]|$)'
# OwnP binding tokens (word-boundary; scanned on comment-stripped text)
BANNED_TOKENS='(CerbGS|CerbGpreS|stateIs|OwnPGS|OwnPGpreS|\bownP\b|\bCerbS\b)'

fail=0

strip_comments() {
  # Remove Lean block comments (incl. docstrings) and line comments.
  # Crude but monotone: it only ever REMOVES text, so a token hit on
  # the stripped output is a real (non-comment) hit.
  python3 - "$1" <<'PYEOF'
import re, sys
src = open(sys.argv[1]).read()
# strip nested block comments
out = []
depth = 0
i = 0
n = len(src)
while i < n:
    if src.startswith('/-', i):
        depth += 1
        i += 2
    elif src.startswith('-/', i) and depth > 0:
        depth -= 1
        i += 2
    else:
        if depth == 0:
            out.append(src[i])
        i += 1
text = ''.join(out)
text = re.sub(r'--.*', '', text)
sys.stdout.write(text)
PYEOF
}

for f in "${LIVE_MODULES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "check_one_route: FATAL — registered live module MISSING: $f"
    echo "  (renamed? re-point the gate in the same commit)"
    fail=1
    continue
  fi
  imp_hits=$(grep -nE "$BANNED_IMPORTS" "$f" || true)
  if [[ -n "$imp_hits" ]]; then
    echo "check_one_route: FAIL — live-route module imports an OwnP/arc-7 surface: $f"
    echo "$imp_hits" | sed 's/^/    /'
    fail=1
  fi
  tok_hits=$(strip_comments "$f" | grep -nE "$BANNED_TOKENS" || true)
  if [[ -n "$tok_hits" ]]; then
    echo "check_one_route: FAIL — live-route module mentions an OwnP binding token (outside comments): $f"
    echo "$tok_hits" | sed 's/^/    /'
    fail=1
  fi
done

# The coexistence hazard: no file binds both interpretation classes
# (comment-stripped; PerStepTacSmoke is the LABELED exception — the
# retirement-register entry-4 smoke file hosts one OwnP smoke and one
# heap smoke in SEPARATE theorems, never one WP statement; it deletes
# at C5).
both=""
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  [[ "$f" == "relsem/RelSem/PerStepTacSmoke.lean" ]] && continue
  stripped=$(strip_comments "$f")
  if grep -qE '\[CerbGS ' <<< "$stripped" \
      && grep -qE '\[CerbHeapGS' <<< "$stripped"; then
    both+="$f"$'\n'
  fi
done < <(git ls-files 'relsem/*.lean' 'speclab/*.lean' 2>/dev/null; \
         find relsem speclab -name '*.lean' -not -path '*/.lake/*' 2>/dev/null | sort -u)
both=$(echo "$both" | sort -u | grep -v '^$' || true)
if [[ -n "$both" ]]; then
  echo "check_one_route: FAIL — file(s) bind BOTH interpretation classes (the S2 coexistence hazard):"
  echo "$both" | sed 's/^/    /'
  fail=1
fi

# OwnP binders must stay confined to the retirement-register surfaces
# (drift check: a NEW OwnP-binding file is a finding even outside the
# live list; the C2-era T6 exemption is CLEARED — R1).
OWNP_ALLOWED=(
  relsem/RelSem/PerStepOwnP.lean
  relsem/RelSem/IrisState.lean
  relsem/RelSem/IrisLang.lean
  relsem/RelSem/IrisRules.lean
  relsem/RelSem/IrisAdequacy.lean
  relsem/RelSem/IrisCoupling.lean
  relsem/RelSem/SlateWP.lean
  relsem/RelSem/PerStepSmoke.lean
  relsem/RelSem/PerStepTacSmoke.lean
  relsem/RelSem/T1.lean
  relsem/RelSem/T2.lean
  relsem/RelSem/T3.lean
  relsem/RelSem/T4.lean
  relsem/RelSem/T4Defs.lean
  relsem/RelSem/T5Prefix.lean
  relsem/RelSem/T5Iter.lean
  relsem/RelSem/Audit.lean
)
ownp_binders=""
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if strip_comments "$f" | grep -qE '\[CerbGS |CerbGpreS'; then
    ownp_binders+="$f"$'\n'
  fi
done < <(find relsem/RelSem relsem/test relsem/bench speclab -name '*.lean' -not -path '*/.lake/*' 2>/dev/null | sort -u)
ownp_binders=$(echo "$ownp_binders" | grep -v '^$' || true)
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  ok=0
  for a in "${OWNP_ALLOWED[@]}"; do
    [[ "$f" == "$a" ]] && ok=1 && break
  done
  if [[ $ok -eq 0 ]]; then
    echo "check_one_route: FAIL — NEW OwnP-binding file outside the retirement register + labeled exemption: $f"
    fail=1
  fi
done <<< "$ownp_binders"

if [[ $fail -ne 0 ]]; then
  echo "check_one_route: FAILED"
  exit 1
fi
echo "check_one_route: OK — one state interpretation on the live route (${#LIVE_MODULES[@]} modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register)"
