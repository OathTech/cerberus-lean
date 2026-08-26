#!/bin/bash
# check_speclab_statements.sh — arc-15 S0: the statement-TCB gate's
# grep-level extension to the speclab package (charter standing
# invariant 1: statements stay executable/first-order — Iris/RelSem
# vocabulary in a speclab statement file fails the check).
#
# Pattern source: the D14 grep leg of scripts/check_theorem_axioms.sh
# (fail-closed on missing scan dir; literal grep ban; loud offender
# listing). The AUTHORITATIVE statement-TCB gate remains the in-build
# environment-walking checker (relsem/RelSem/Audit.lean); an in-build
# twin for speclab lands with its first semantics-facing theorems (S1)
# — this grep leg is the S0 floor and stays as defense in depth.
#
# Scope: lean_frontend/speclab/SpecLab/ — the STATEMENT/library
# surface. speclab/test/ is deliberately out of scope (tests are
# untrusted-evaluator territory; the D14 tactic ban below still covers
# them via the shared check_theorem_axioms.sh once speclab is wired
# into the unit gate at rung stabilization).
#
# Banned vocabulary (grep-level, word-boundary):
#   * Iris / iProp / WP-vocabulary  — proof-layer names; "Iris party in
#     the back" never reaches a statement file ([USER 2026-08-22]).
#   * RelSem                        — the relational/proof layer.
#   * native_decide / bv_decide     — D14 non-kernel proof methods
#     (mirrored here so the ban holds before speclab joins the shared
#     gate).
#   * sorry / sorryAx               — no sorry in hand-written code
#     (house rule), speclab included.
#
# Escape hatch: THE GOVERNED ONE ONLY — an allowlist amendment here
# without a logged operator decision is a finding (container CLAUDE.md,
# the-escape-hatch-is-governed block).
#
# ALLOWLIST AMENDMENT (arc-18 C4, register row R6 — logged operator
# decision: the BLESSED arc-18 charter [USER 2026-08-25] mandates the
# threaded statement vocabulary homed SEMANTICS-SIDE at
# relsemcore/RelSem/Threaded.lean, quoted by speclab statements):
# exactly TWO line forms carrying the `RelSem` token are legal in the
# statement surface —
#   import RelSem.Threaded
#   open RelSem.Cerb (HarnessRunsToThr specifiedInt initial_driver_state_threaded)
# (the canonical open line, byte-exact). They are STRIPPED before the
# ban scan; any other RelSem token (including any other `open
# RelSem.*` form) still fails. The AUTHORITATIVE closure-level check
# is the in-build SpecLabAudit gate (exact-name allowlist
# `slAllowedSemanticsSide`, walked through).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCAN_DIR="$PROJECT_ROOT/lean_frontend/speclab/SpecLab"
ROOT_MOD="$PROJECT_ROOT/lean_frontend/speclab/SpecLab.lean"

if [[ ! -d "$SCAN_DIR" || ! -f "$ROOT_MOD" ]]; then
    echo "check_speclab_statements: FAIL — $SCAN_DIR or SpecLab.lean missing (fail-closed)"
    exit 1
fi

BAN_REGEX='\bIris\b|\biProp\b|\bRelSem\b|\bnative_decide\b|\bbv_decide\b|\bsorry\b|\bsorryAx\b'
# The two allowed line forms (see header; byte-exact match, anchored)
ALLOW_LINE_1='^import RelSem\.Threaded$'
ALLOW_LINE_2='^open RelSem\.Cerb \(HarnessRunsToThr specifiedInt initial_driver_state_threaded\)$'

offenders=$(grep -rEn "$BAN_REGEX" "$SCAN_DIR" "$ROOT_MOD" 2>/dev/null \
    | grep -vE ":[0-9]+:${ALLOW_LINE_1#^}" \
    | grep -vE ":[0-9]+:${ALLOW_LINE_2#^}" || true)
if [[ -n "$offenders" ]]; then
    echo "check_speclab_statements: FAIL — banned statement vocabulary in speclab:"
    echo "$offenders"
    exit 1
fi

nfiles=$( (find "$SCAN_DIR" -name '*.lean'; echo "$ROOT_MOD") | wc -l)
echo "check_speclab_statements: OK — $nfiles speclab statement file(s) clean (Iris/RelSem/native_decide/bv_decide/sorry ban)"
exit 0
