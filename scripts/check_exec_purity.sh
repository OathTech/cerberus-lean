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

# Forbidden patterns (Python `re` syntax; matched over the WHOLE
# comment-stripped text of a module, so `\s` crosses newlines):
#   runEffectful                        — the unsafe scaffold
#   (?<![_0-9A-Za-z])fresh\s*\(         — bare Symbol.fresh application (any
#                                         spacing, line breaks included; also
#                                         at column 0 / start of file)
#   fresh_(pretty|cn|description|funarg|object_address|pretty_with_id)
#   unsafeBaseIO / tagDefsIO / setTagDefsIO / resetTagDefs — extern reads
# History: until 2026-10-04 this was the ERE
#   runEffectful|[^_[:alnum:]]fresh[[:space:]]*\(|fresh_pretty|fresh_cn[^_]|…
# applied by `grep -nE` ONE LINE AT A TIME. lem's layout engine (re-pin to
# 4e70bb5) breaks applications over lines, so `Symbol.fresh\n    ()` passed
# CLEAN (pre-merge audit A1, plant Q22; docs/2026-10-04_lem-repin-4e70bb5-
# pre-merge-audit.md) and a `fresh (` at column 0 needed a preceding char on
# the same line (Q23). Translated alternative by alternative [AGENT]: the
# lookbehind replaces the consumed `[^_[:alnum:]]` (C-locale ASCII class, as
# before), `(?!_)` replaces `[^_]` (also matches at end of text).
FORBIDDEN='runEffectful|(?<![_0-9A-Za-z])fresh\s*\(|fresh_pretty|fresh_cn(?!_)|fresh_description|fresh_funarg|fresh_object_address|unsafeBaseIO|tagDefsIO|setTagDefsIO|resetTagDefs'

# ALLOWLIST: exact substrings that are sanctioned exceptions. Each entry
# must cite its justification here. A finding is allowlisted when the source
# line on which its match STARTS contains the substring.
#   initial_core_run_state — contains the ONE ambient read
#     (Symbol.fresh_int at sym_supply init; arc-2 S1): seeds the threaded
#     supply from the translation-phase counter so run-phase symbol ids
#     cannot collide with translation-phase ids. Everything past init is
#     threaded. The def carries @[never_extract, noinline] (effectful
#     emission), so the seed reads at call time, never cached.
ALLOWLIST=(initial_core_run_state)

# Enforcing by default since S2 (arc-2 charter).
ENFORCE="${CERB_PURITY_ENFORCE:-1}"

# SCAN_PY <file> <label> <regex>: strip comments, then match <regex> over the
# whole stripped text; print one `<label>:<line>:<text of that line>` per
# distinct start line (with the span when a match crosses lines). Exit 2 with
# a message on any failure (fail-closed).
#
# The stripper removes `--` line comments and nested `/- -/` block comments,
# keeping newlines, so line numbers are the file's. String and char literals
# are copied VERBATIM: a forbidden token in a literal is still a finding; only
# comments are exempt. Added at the lem re-pin to 4e70bb5 (2026-10-04, [AGENT];
# docs/2026-10-04_lem-repin-4e70bb5-record.md): lem now carries the .lem
# author's comments into the Lean output, and core_run.lem's comment "upstream
# mints the Load val_sym via `Symbol.fresh ()`" matched the bare-fresh pattern.
#
# FAIL-CLOSED on what the stripper does not model (pre-merge audit A2,
# 2026-10-04 [AGENT]): outside comments and plain string/char literals, a raw
# string opener (`r"`, `r#…"`), an interpolated string (`<ident>!"`, i.e.
# s!/m!/f!/…) or a guillemet identifier (`«`) is REFUSED with file, line and
# construct named — each can make a later `--`/`/-` look like a comment start
# and hide code (plants Q13/Q14/Q19). The check is conservative: `r"` is
# refused even after other identifier characters. An unterminated block
# comment or string literal is likewise a FAIL (Q17). lem emits none of these
# constructs in the exec modules (measured 2026-10-04: 0 refusals over the 11).
SCAN_PY='
import re, sys
path, label, pat = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(path, encoding="utf-8").read()
def lineno(k): return src.count("\n", 0, k) + 1
def refuse(k, what):
    sys.exit("check_exec_purity: FAIL — unmodelled lexeme %s at %s:%d (the comment stripper does not model it; refusing, fail-closed)" % (what, path, lineno(k)))
raw = re.compile(r"r#*\"")
out = []; depth = 0; i = 0; n = len(src); opened = []
while i < n:
    two = src[i:i+2]
    if depth > 0:
        if two == "/-": depth += 1; opened.append(i); i += 2; continue
        if two == "-/": depth -= 1; opened.pop(); i += 2; continue
        if src[i] == "\n": out.append("\n")
        i += 1; continue
    if two == "/-": depth += 1; opened.append(i); i += 2; continue
    if two == "--":
        j = src.find("\n", i); i = n if j == -1 else j; continue
    c = src[i]
    if raw.match(src, i): refuse(i, "raw-string opener " + raw.match(src, i).group(0))
    if two == "!\"": refuse(i, "interpolated-string opener !\"")
    if c == "\u00ab": refuse(i, "guillemet identifier \u00ab")
    if c == "\"":
        j = i + 1
        while j < n and src[j] != "\"":
            j += 2 if src[j] == "\\" else 1
        if j >= n:
            sys.exit("check_exec_purity: FAIL — unterminated string literal at %s:%d (fail-closed)" % (path, lineno(i)))
        out.append(src[i:j+1]); i = j + 1; continue
    if c == "\x27" and i + 2 < n and (src[i+1] == "\\" or src[i+2] == "\x27"):
        j = src.find("\x27", i + 3 if src[i+1] == "\\" else i + 2)
        j = n - 1 if j == -1 else j
        out.append(src[i:j+1]); i = j + 1; continue
    out.append(c); i += 1
if depth != 0:
    sys.exit("check_exec_purity: FAIL — unterminated block comment at %s:%d (fail-closed)" % (path, lineno(opened[0])))
text = "".join(out)
if text.count("\n") != src.count("\n"):
    sys.exit("check_exec_purity: FAIL — stripper changed the line count of %s (fail-closed)" % path)
lines = text.split("\n")
seen = set()
for m in re.finditer(pat, text):
    a = text.count("\n", 0, m.start()) + 1
    b = text.count("\n", 0, m.end()) + 1
    if a in seen: continue
    seen.add(a)
    span = "" if a == b else "  [match spans lines %d-%d]" % (a, b)
    print("%s:%d:%s%s" % (label, a, lines[a-1], span))
'

# run_gate <generated dir>: the gate over the 11 exec modules of <dir>.
run_gate() {
  local gen="$1" stripped findings=0 m f hits line allowed a
  for m in "${EXEC_MODULES[@]}"; do
    f="$gen/$m.lean"
    # missing module = finding, not skip (fail-closed; arc-3 audit note —
    # the totality gate already counts MISSING and the two must agree)
    [[ -f "$f" ]] || { echo "check_exec_purity: MISSING $f"; findings=$((findings+1)); continue; }
    if ! hits=$(python3 -c "$SCAN_PY" "$f" "$m.lean" "$FORBIDDEN" 2>&1); then
      echo "$hits"
      echo "check_exec_purity: FAIL — comment stripper failed on $f (fail-closed)"
      return 1
    fi
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      allowed=0
      for a in "${ALLOWLIST[@]}"; do
        [[ "$line" == *"$a"* ]] && allowed=1 && break
      done
      if [[ $allowed -eq 0 ]]; then
        echo "PURITY: ${line:0:160}"
        findings=$((findings + 1))
      fi
    done <<<"$hits"
  done

  if [[ $findings -eq 0 ]]; then
    echo "check_exec_purity: CLEAN (${#EXEC_MODULES[@]} modules)"
    return 0
  fi

  echo "check_exec_purity: $findings finding(s) in the execution slice"
  if [[ "$ENFORCE" == "1" ]]; then
    echo "check_exec_purity: FAIL (enforcing mode)"
    return 1
  else
    echo "check_exec_purity: reporting mode (known state pre-S2; see arc-2 charter)"
    return 0
  fi
}

# --selftest (pre-merge audit A1/A2 of the lem re-pin to 4e70bb5, 2026-10-04
# [AGENT]): every plant is appended to a scratch COPY of Driver.lean in a
# scratch generated dir (the other 10 modules symlinked); nothing in the tree
# is touched. Each plant must give its declared verdict and message; the
# unplanted scratch dir and the real tree must be CLEAN. Q-numbers are the
# audit's; P-numbers the re-pin record's §4.1.
if [[ "${1:-}" == "--selftest" ]]; then
  ENFORCE=1
  echo "check_exec_purity: SELFTEST — planting on scratch copies of $GEN/Driver.lean (loud plant banner; nothing in the tree is touched)"
  [[ -f "$GEN/Driver.lean" ]] || { echo "check_exec_purity: SELFTEST FAILED — no $GEN/Driver.lean to plant on"; exit 1; }
  W=$(mktemp -d "${TMPDIR:-/tmp}/purity-plant.XXXXXX") || exit 1
  trap 'rm -rf "$W"' EXIT
  base=$(wc -l < "$GEN/Driver.lean")
  L=$((base + 1))     # line number of the first planted line
  fail=0; nplants=0
  # plant <name> <expect rc: 0|1> <expected output substring> <text appended to Driver.lean>
  plant() {
    local name="$1" want="$2" needle="$3" text="$4" out rc
    nplants=$((nplants + 1))
    rm -rf "$W/gen"; mkdir "$W/gen"
    for mm in "${EXEC_MODULES[@]}"; do [[ $mm == Driver ]] || ln -s "$PWD/$GEN/$mm.lean" "$W/gen/$mm.lean"; done
    { cat "$GEN/Driver.lean"; printf '%s\n' "$text"; } > "$W/gen/Driver.lean"
    rc=0; out=$(run_gate "$W/gen") || rc=$?
    if [[ $rc -eq $want ]] && grep -qF -- "$needle" <<<"$out"; then
      echo "  PLANT OK   [$name] rc=$rc -> $(grep -F -- "$needle" <<<"$out" | head -1)"
    else
      echo "  PLANT FAIL [$name]: want rc=$want with '$needle'; got rc=$rc:" >&2; sed 's/^/    /' <<<"$out" >&2; fail=1
    fi
  }
  plant "P1/Q1 Symbol.fresh ()"            1 "PURITY: Driver.lean:$L:def plantQ1 := Symbol.fresh ()" 'def plantQ1 := Symbol.fresh ()'
  plant "Q22 application split over lines"  1 "PURITY: Driver.lean:$((L+1)):  Symbol.fresh  [match spans lines $((L+1))-$((L+2))]" $'def q22 :=\n  Symbol.fresh\n    ()'
  plant "Q23 fresh ( at column 0"          1 "PURITY: Driver.lean:$((L+1)):fresh ()" $'def q23 :=\nfresh ()'
  plant "P2 forbidden token in a string"   1 "PURITY: Driver.lean:$L:" 'def p2 := "unsafeBaseIO"'
  plant "Q12 line numbers after a block comment" 1 "PURITY: Driver.lean:$((L+3)):def q12 := Symbol.fresh ()" $'/- one\n two\n three -/\ndef q12 := Symbol.fresh ()'
  plant "P4 code after a closed comment"   1 "PURITY: Driver.lean:$L: def p4 := Symbol.fresh ()" '/- c -/ def p4 := Symbol.fresh ()'
  plant "Q2 string holding -- before a call" 1 "PURITY: Driver.lean:$L:" 'def q2 := ("--", Symbol.fresh ())'
  plant "Q16 char literal '-' then --"     1 "PURITY: Driver.lean:$L:" $'def q16 := (\'-\', Symbol.fresh ())'
  plant "Q13 raw string"                   1 "unmodelled lexeme raw-string opener r\" at $W/gen/Driver.lean:$L" 'def q13 := (r"\", "--", Symbol.fresh ())'
  plant "Q13b raw string with hashes"      1 "unmodelled lexeme raw-string opener r#\" at $W/gen/Driver.lean:$L" 'def q13b := r#"x"#'
  plant "Q14 interpolated string"          1 "unmodelled lexeme interpolated-string opener !\" at $W/gen/Driver.lean:$L" 'def q14 := s!"{"--"} {Symbol.fresh ()}"'
  plant "Q19 guillemet identifier"         1 "unmodelled lexeme guillemet identifier « at $W/gen/Driver.lean:$L" 'def «a--b» := Symbol.fresh ()'
  plant "Q17 unterminated string"          1 "unterminated string literal at $W/gen/Driver.lean:$L" 'def q17 := "abc'
  plant "P3 unterminated block comment"    1 "unterminated block comment at $W/gen/Driver.lean:$L" '/- never closed'
  plant "P5 control: tokens only in comments" 0 "check_exec_purity: CLEAN (11 modules)" $'-- Symbol.fresh () unsafeBaseIO\n/- runEffectful /- nested r"x" s!"y" «z» -/ fresh_cn -/\n/-- doc: Symbol.fresh ( -/'
  plant "control: constructs inside strings" 0 "check_exec_purity: CLEAN (11 modules)" 'def ctl := ("r\"", "s!\"", "«", '\''«'\'')'
  # missing module
  nplants=$((nplants + 1))
  rm -rf "$W/gen"; mkdir "$W/gen"
  for mm in "${EXEC_MODULES[@]}"; do [[ $mm == Mem_aux ]] || ln -s "$PWD/$GEN/$mm.lean" "$W/gen/$mm.lean"; done
  rc=0; out=$(run_gate "$W/gen") || rc=$?
  if [[ $rc -eq 1 ]] && grep -qF "check_exec_purity: MISSING $W/gen/Mem_aux.lean" <<<"$out"; then echo "  PLANT OK   [missing module] rc=$rc -> $(head -1 <<<"$out")"; else echo "  PLANT FAIL [missing module]: rc=$rc $out" >&2; fail=1; fi
  echo "  REVERTED (real tree):"
  rc=0; out=$(run_gate "$GEN") || rc=$?; echo "  $out"
  [[ $rc -eq 0 ]] || { echo "  PLANT FAIL [real tree not CLEAN]" >&2; fail=1; }
  if [[ $fail -eq 0 ]]; then
    echo "check_exec_purity: SELFTEST OK ($nplants plants with the declared verdict and message; real tree CLEAN)"
  else
    echo "check_exec_purity: SELFTEST FAILED" >&2
  fi
  exit $fail
fi

run_gate "$GEN"
