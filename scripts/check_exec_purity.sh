#!/usr/bin/env bash
# Purity gate for the execution slice (arc 2, S0).
#
# Asserts that the generated execution-slice modules — the fuel-opsem TCB —
# contain no unsafe-extern effect machinery. Exists because a hand-run grep
# census failed exactly here (design note §10: whitespace-defeated pattern,
# sites-vs-callers confusion); this script is the mechanized, gate-wired
# replacement. Patterns are deliberately whitespace-robust.
#
# Modes:
#   reporting (default until S2): print findings, exit 0.
#   enforcing (CERB_PURITY_ENFORCE=1, default after S2 flips it below):
#     any non-allowlisted finding fails the gate.
#
# BOUNDARY HONESTY (arc-4 S5f, audit G3; amended arc-7 S2 + S5b): the
# 11-module list below covers GENERATED modules only, and is the PURITY
# scope — note the totality gate (check_exec_totality.sh) scans a
# 16-generated-module SUPERSET since arc-7 S5a (this 11-module list is
# its prefix). The hand-written seams those modules call into are
# OUTSIDE this gate's scan: nothing here inspects them. Their state as
# of arc-7:
#   CerbND.lean  — TOTALIZED (arc-7 S2), partial-free, covered by
#     check_exec_totality.sh's hand-written clause; still outside THIS
#     purity scan.
#   CerbMem.lean — exec-path TOTALIZED (arc-7 S4: the nine layout/
#     byte-codec functions are fuel'd); ONE partial def remains
#     (stringFromMemValue, pp-only) plus panic! sites; outside both
#     scans (extending the totality scanner over it is a priced item).
#   CerbTags.lean — shrunk to the TagDefsMap TYPE + a fail-closed
#     coverage stub (effect-retirement C1: the global, its BaseIO
#     externs, and the with_tagDefs opaque are DELETED — the linked
#     table is passed by value; charter section 4);
#   CerberusFresh.lean — the digest read is a KERNEL-CHECKED OPAQUE
#     since effect-retirement C2 (2026-09-01, the Q4 promoted
#     deliverable): unsafe extern opaque digestPure (explicit witness)
#     + impl + implemented_by on `opaque digest := fun _ => ""`; ZERO
#     unsafeBaseIO left in the file. The full surviving seam list is
#     MACHINE-PINNED: scripts/unsafebaseio_allowlist.txt PIN rows,
#     enforced both-directions by check_theorem_axioms.sh's C2 ratchet
#     leg 3 (any new implemented_by/unsafe/unsafeBaseIO site fails
#     naming itself).
#   CerbFloat/CerbUtils/... — unchanged (CerbUtils boundedIntegerImpl
#     stub: permanent-declared, Q4).
#   CerberusImpl.lean — ZERO seams since program-data parameters E-A
#     (2026-09-20, docs/2026-09-20_program-data-parameters-EA-DA-record.md):
#     the enum registry (IO.Ref + implemented_by opaques, the ONE kept
#     `panic!`) is DELETED — the enum's compatible type is PROGRAM DATA
#     (the lem reader `enum_definitions`, carried in the sigma and the Core
#     file), `normalise_integerType enumDefs tagDefs` the lookup with a
#     `failwithI` leaf, `register_enum` the pure `true`.
#   CerbGlobal.lean — plain `def`s of the default configuration since
#     2026-09-05 (the never-written refs and their opaque readers are
#     DELETED; docs/2026-09-05_cerbglobal-defs-record.md); zero seams.
# Declared-boundary records: 2026-08-19_arc4-results.md, updated by
# 2026-08-20_arc7-results.md (CerbND left the boundary; CerbMem's leg
# partially discharged), and the effect-retirement charter section 7.2
# (docs/2026-08-31_effect-retirement-design.md) + the C2 ratchet
# record (docs/2026-09-01_C2-ratchet-record.md). Expanding this purity
# gate to the hand-written seams remains a priced next-arc item.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
GEN=lean_frontend/generated

# The execution slice (fuel-opsem TCB) per the effects design note.
EXEC_MODULES=(Core_run Core_reduction Core_eval Driver Core_run_aux
              Core_aux Defacto_memory Defacto_memory_aux Ctype_aux
              Nondeterminism Mem_aux)

# Forbidden patterns (extended regex, whitespace-robust):
#   runEffectful            — the unsafe scaffold
#   \bfresh[[:space:]]*\(   — bare Symbol.fresh application (any spacing)
#   fresh_(pretty|cn|description|funarg|object_address|pretty_with_id)\b
#   unsafeBaseIO / tagDefsIO / setTagDefsIO / resetTagDefs — extern reads
FORBIDDEN='runEffectful|[^_[:alnum:]]fresh[[:space:]]*\(|fresh_pretty|fresh_cn[^_]|fresh_description|fresh_funarg|fresh_object_address|unsafeBaseIO|tagDefsIO|setTagDefsIO|resetTagDefs'

# ALLOWLIST: exact substrings that are sanctioned exceptions. Each entry
# must cite its justification here.
#   initial_core_run_state — contains the ONE ambient read
#     (Symbol.fresh_int at sym_supply init; arc-2 S1): seeds the threaded
#     supply from the translation-phase counter so run-phase symbol ids
#     cannot collide with translation-phase ids. Everything past init is
#     threaded. The def carries @[never_extract, noinline] (effectful
#     emission), so the seed reads at call time, never cached.
ALLOWLIST=(initial_core_run_state)

# Enforcing by default since S2 (arc-2 charter).
ENFORCE="${CERB_PURITY_ENFORCE:-1}"

# strip_comments <file>: the file with `--` line comments and nested `/- -/`
# block comments removed and newlines kept, so grep's line numbers are the
# file's. String and char literals are copied VERBATIM: a forbidden token in a
# literal is still a finding; only comments are exempt. Added at the lem
# re-pin to 4e70bb5 (2026-10-04, [AGENT]; docs/2026-10-04_lem-repin-4e70bb5-record.md):
# lem now carries the .lem author's comments into the Lean output, and
# core_run.lem's comment "upstream mints the Load val_sym via `Symbol.fresh ()`"
# matched the bare-fresh pattern. An unterminated block comment or any
# stripper failure fails the gate (fail-closed). Plant-tested (record §5).
strip_comments() {
  python3 -c '
import sys
src = open(sys.argv[1], encoding="utf-8").read()
out = []; depth = 0; i = 0; n = len(src)
while i < n:
    two = src[i:i+2]
    if depth > 0:
        if two == "/-": depth += 1; i += 2; continue
        if two == "-/": depth -= 1; i += 2; continue
        if src[i] == "\n": out.append("\n")
        i += 1; continue
    if two == "/-": depth += 1; i += 2; continue
    if two == "--":
        j = src.find("\n", i); i = n if j == -1 else j; continue
    c = src[i]
    if c == "\"":
        j = i + 1
        while j < n and src[j] != "\"":
            j += 2 if src[j] == "\\" else 1
        out.append(src[i:j+1]); i = j + 1; continue
    if c == "\x27" and i + 2 < n and (src[i+1] == "\\" or src[i+2] == "\x27"):
        j = src.find("\x27", i + 3 if src[i+1] == "\\" else i + 2)
        j = n - 1 if j == -1 else j
        out.append(src[i:j+1]); i = j + 1; continue
    out.append(c); i += 1
if depth != 0:
    sys.exit("unterminated block comment in " + sys.argv[1])
sys.stdout.write("".join(out))
' "$1"
}

stripped=$(mktemp)
findings=0
for m in "${EXEC_MODULES[@]}"; do
  f="$GEN/$m.lean"
  # missing module = finding, not skip (fail-closed; arc-3 audit note —
  # the totality gate already counts MISSING and the two must agree)
  [[ -f "$f" ]] || { echo "check_exec_purity: MISSING $f"; findings=$((findings+1)); continue; }
  strip_comments "$f" > "$stripped" || { echo "check_exec_purity: FAIL — comment stripper failed on $f (fail-closed)"; rm -f "$stripped"; exit 1; }
  while IFS= read -r line; do
    allowed=0
    for a in "${ALLOWLIST[@]}"; do
      [[ "$line" == *"$a"* ]] && allowed=1 && break
    done
    if [[ $allowed -eq 0 ]]; then
      echo "PURITY: ${line:0:160}"
      findings=$((findings + 1))
    fi
  done < <(grep -nE "$FORBIDDEN" "$stripped" | sed "s|^|$m.lean:|" || true)
done
rm -f "$stripped"

if [[ $findings -eq 0 ]]; then
  echo "check_exec_purity: CLEAN (${#EXEC_MODULES[@]} modules)"
  exit 0
fi

echo "check_exec_purity: $findings finding(s) in the execution slice"
if [[ "$ENFORCE" == "1" ]]; then
  echo "check_exec_purity: FAIL (enforcing mode)"
  exit 1
else
  echo "check_exec_purity: reporting mode (known state pre-S2; see arc-2 charter)"
  exit 0
fi
