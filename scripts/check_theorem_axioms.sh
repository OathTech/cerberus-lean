#!/usr/bin/env bash
# Axiom-cone gate for the exec cone (arc 2, S5a tripwire): zero axiom
# declarations anywhere + every exec entry's #print axioms cone inside the
# standard three.
#
# Asserts the axiom dependencies of the exec entries and of the unit-test
# exemplars via #print axioms, so any change to the inhabitation/effect
# machinery is measured, not narrated. (History: installed guardrail-first before the arc-2 S5
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
# probes are the generated-exemplar + driver2 legs. 2026-09-02 RelSem
# prune: the last reasoning-era package, relsemcore/, is gone too; the
# D14 grep leg scans lean_frontend/test + the hand-written
# lean_frontend/*.lean seams.)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Hand-written axiom census (arc-5 audit 2, F3; end state arc-17 S2b):
# C2-audit note (registered, kept as-is): this line-anchored '^axiom'
# grep is REDUNDANT with the C2 ratchet leg 1 below (comment-stripped
# \baxiom\b over a superset surface); it stays as an independent cheap
# tripwire, but the ratchet leg is the load-bearing census.
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
    # C2 audit MAJOR-1 fix: match the KEYWORD alone — the old name
    # class [A-Za-z_0-9α-ω.'] required >=1 matching char, so a
    # non-ASCII declaration name (axiom «evil» : False) made the whole
    # match fail and the axiom INVISIBLE (fail-open). The name capture
    # is now report-only (\S+, optional).
    for m in re.finditer(r'\baxiom\b(?:\s+(\S+))?', clean):
        line = clean.count('\n', 0, m.start()) + 1
        print(f"AXIOM {base}:{line}:{m.group(1) or '<unnamed>'}")
    # FUEL arc (2026-09-03): EVERY opaque declaration is reported (the
    # keyword alone fires; modifiers tolerated; wide name class so a
    # non-ASCII name still produces a row) — the boundary-opaque census
    # below is a POPULATION PIN, both directions.
    for m in re.finditer(r'\b(?:private\s+|protected\s+|noncomputable\s+|unsafe\s+)*opaque\s+([^\s\]\[,:(){}]+)', clean):
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
# BOUNDARY-OPAQUE CENSUS — a POPULATION PIN, both directions (FUEL arc,
# 2026-09-03; was the single forceIO liveness row). Every `opaque` in the
# build tree is a constant with NO equations — an abstraction barrier the
# kernel cannot see through — so each one is a declared-boundary decision
# registered HERE with its class, exactly once in its build copy:
#   * a registered opaque found 0 times = copy pipeline / scanner drift, or
#     someone turned it into a `def` (for fuelExhaustedLoc that would
#     silently break the FUEL arc's parametricity argument — design note
#     §1.3/§2 "the residual risk, named");
#   * found 2+ times = duplicated in place;
#   * an opaque NOT registered here = FAIL naming itself (a new barrier
#     must be consciously registered, never absorbed).
# Classes: [seam] = a native/IO binding behind @[implemented_by]/@[extern]
# (ALSO pinned by the C2 ratchet leg 3 population, scripts/
# unsafebaseio_allowlist.txt); [pure] = a value-carrying opaque with NO
# native binding, existing only to be unforgeable/unfoldable.
# (History: with_tagDefs LEFT the list at effect-retirement C1 — charter
# section 7.2 "boundary-opaque expectation list shrinks"; the digest
# opaque conversion was C2.)
OPAQUE_WANT=(
  # CerberusFresh — the digest boundary (VALIDATION.md §4), [seam]
  'CerberusFresh.lean:md5Hex' 'CerberusFresh.lean:digestIO' 'CerberusFresh.lean:setDigestIO'
  'CerberusFresh.lean:digestPure' 'CerberusFresh.lean:digest' 'CerberusFresh.lean:forceThunkIO'
  'CerberusFresh.lean:forceIO'
  # CerbGlobal — config/switch refs, temporal (mover: parameter plumbing), [seam]
  'CerbGlobal.lean:backend_name' 'CerbGlobal.lean:current_execution_mode'
  'CerbGlobal.lean:using_concurrency' 'CerbGlobal.lean:isDefacto' 'CerbGlobal.lean:isPermissive'
  'CerbGlobal.lean:isAgnostic' 'CerbGlobal.lean:isIgnoreBitfields' 'CerbGlobal.lean:has_switch'
  'CerbGlobal.lean:is_CHERI' 'CerbGlobal.lean:is_PNVI' 'CerbGlobal.lean:has_strict_pointer_arith'
  # CerbUtils — no-op timing/log refs + boundedIntegerImpl stub, permanent-declared, [seam]
  'CerbUtils.lean:begin_timing' 'CerbUtils.lean:end_timing' 'CerbUtils.lean:STD_'
  'CerbUtils.lean:bounded_integer'
  # CerberusImpl — enum registry, temporal (mover: reader/supply follow-up), [seam]
  'CerberusImpl.lean:typeof_enum' 'CerberusImpl.lean:register_enum'
  # CerbMem — the safe structural BEq on MemValue (implemented_by), [seam]
  'CerbMem.lean:beqMemValueSafe'
  # CerbFuel — the fuel-exhaustion atom (FUEL arc, docs/2026-09-02_fuel-arc-
  # design.md §1.1/§2): [pure] — value-carrying, NO native binding, no
  # unsafe/implemented_by/extern; exists to be unforgeable, not to hide an
  # effect. Its presence-AS-OPAQUE is what the arc's soundness rests on.
  'CerbFuel.lean:fuelExhaustedLoc'
)
OPAQUE_FOUND=$(sed -E 's/^OPAQUE ([^:]+):[0-9]+:(.*)$/\1:\2/' <<<"$GEN_OPAQUES" | grep . | sort | uniq -c | awk '{print $2" "$1}' || true)
OPAQUE_BAD=0
for want in "${OPAQUE_WANT[@]}"; do
  cnt=$(awk -v w="$want" '$1==w {print $2}' <<<"$OPAQUE_FOUND")
  cnt=${cnt:-0}
  if [[ "$cnt" -ne 1 ]]; then
    echo "check_theorem_axioms: FAIL — boundary-opaque census: registered opaque $want found $cnt time(s) in the build copy, expected exactly 1 (0 = copy-pipeline/scanner drift or opaque->def; 2+ = duplicated; fail-closed)"
    OPAQUE_BAD=1
  fi
done
while read -r key cnt; do
  [[ -z "$key" ]] && continue
  registered=0
  for want in "${OPAQUE_WANT[@]}"; do [[ "$want" == "$key" ]] && { registered=1; break; }; done
  if [[ $registered -eq 0 ]]; then
    echo "check_theorem_axioms: FAIL — boundary-opaque census: UNREGISTERED opaque $key (x$cnt) in the build tree — every opaque is a declared-boundary decision; register it in OPAQUE_WANT with its class, or remove it"
    OPAQUE_BAD=1
  fi
done <<<"$OPAQUE_FOUND"
if [[ $OPAQUE_BAD -ne 0 ]]; then
  echo "$GEN_OPAQUES"
  exit 1
fi
if [[ -n "$GEN_UNSAFE" ]]; then
  echo "check_theorem_axioms: FAIL — generated-tree census: unsafeCast in generated code (banned, no allowlist):"
  echo "$GEN_UNSAFE"
  exit 1
fi
echo "check_theorem_axioms: generated-tree census OK ($GEN_SCANNED files: 0 axioms, boundary-opaque population = the ${#OPAQUE_WANT[@]} registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)"

# ---------------------------------------------------------------------------
# EFFECT-RETIREMENT C2 RATCHET (charter section 7.2 as amended by the
# accepted L2-audit ratchet legs; 2026-09-01). SOURCE-SCAN census is the
# PRIMARY evidence that the effect machinery is gone — the kernel-cone
# probes below are SECONDARY spot checks only (#print axioms
# UNDERREPORTS across partial-def/opaque boundaries: S0 measured
# desugar's kernel cone clean while its COMPILED path reached
# runEffectful; charter 7.2 caveat). Four legs, each fail-closed on
# missing dirs / empty inputs:
#   (1) LemLib recursive zero-axiom census — the consumed package copy
#       (.lake/packages/LemLib/lean-lib/**/*.lean, RECURSIVE per
#       charter A3: the subdirectory sources LemLib/Num.lean etc. are
#       in scope, and their presence in the file list is asserted so a
#       flat-glob regression is loud), comment-stripped (the L2
#       HISTORY comment naming the deleted axiom must NOT trip — the
#       DAEMON-precedent adjudication the L2 record flagged).
#   (2) runEffectful token ban, comment-stripped, over the LemLib copy
#       + generated/ + ALL hand-written lean_frontend sources
#       (test/speclab included; .lake trees excluded).
#   (3) @[implemented_by]/unsafe/unsafeBaseIO POPULATION pin: the
#       comment-stripped census of implemented_by targets, unsafe
#       declarations, and unsafeBaseIO occurrences (keyed by enclosing
#       declaration) must EQUAL the PIN rows of
#       scripts/unsafebaseio_allowlist.txt exactly, both directions —
#       any NEW site fails naming itself; any missing pinned row fails
#       as scanner/copy drift. This is the leg that bans an AXIOM-FREE
#       reintroduction of the effect projection via
#       opaque + implemented_by + unsafeBaseIO (the L2 audit's
#       accepted proposal). LemLib survivors: failwithIImpl +
#       fuelExhaustedWithImpl; cerberus survivors: the Q4-classified
#       allowlist (digest converted at C2 — zero unsafeBaseIO in
#       CerberusFresh).
#   (4) ban-surface assertion: the lem-lean tests/ scaffolds are
#       OUTSIDE the surface DELIBERATELY (they hand-write unsafe
#       externs by design — TupleLetTick.lean, the m7 pin). Asserted,
#       not assumed: the package clone must contain the scaffold tree
#       WITH at least one would-trip token, and the scan list must
#       contain nothing under the package outside lean-lib/.
# ---------------------------------------------------------------------------
LEMLIB_PKG=lean_frontend/.lake/packages/LemLib
LEMLIB_LIB="$LEMLIB_PKG/lean-lib"
ALLOWLIST=scripts/unsafebaseio_allowlist.txt

if [[ ! -d "$LEMLIB_LIB" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet: $LEMLIB_LIB missing (fail-closed; is the LemLib package materialized?)"
  exit 1
fi
if [[ ! -f "$ALLOWLIST" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet: $ALLOWLIST missing (fail-closed; leg 3 has no pin input)"
  exit 1
fi

# file lists (fail-closed on empty; NUL-separated for the scanner)
LEMLIB_LIST=$(find "$LEMLIB_LIB" -name '*.lean' | sort)
HW_LIST=$(find lean_frontend -name '*.lean' -not -path '*/.lake/*' | sort)
if [[ -z "$LEMLIB_LIST" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet: recursive LemLib file list is EMPTY (fail-closed)"
  exit 1
fi
if [[ -z "$HW_LIST" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet: lean_frontend file list is EMPTY (fail-closed)"
  exit 1
fi
# recursive-glob liveness (charter A3 / plant P3): the LemLib list must
# reach the subdirectory sources, or the census is silently flat.
if ! grep -q "lean-lib/LemLib/" <<<"$LEMLIB_LIST"; then
  echo "check_theorem_axioms: FAIL — C2 ratchet: LemLib file list has NO lean-lib/LemLib/ subdirectory entries (recursive glob broken — a flat glob would miss subdirectory axioms; fail-closed)"
  exit 1
fi
# leg (4): the scaffold exclusion is deliberate and non-vacuous.
if [[ ! -d "$LEMLIB_PKG/tests/comprehensive" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 4: $LEMLIB_PKG/tests/comprehensive missing (the asserted-outside-the-surface scaffold tree is gone; re-adjudicate the surface, don't skip)"
  exit 1
fi
if ! grep -rq "unsafeBaseIO" "$LEMLIB_PKG/tests/" 2>/dev/null; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 4: lem tests/ contain no would-trip token (the exclusion assertion is VACUOUS — re-verify the surface)"
  exit 1
fi
# (C2-audit note, registered: this third assertion is tautological
# TODAY — the list is built by find over lean-lib/ — it guards future
# edits to the list construction, not the present one.)
if grep -v "^$LEMLIB_PKG/lean-lib/" <<<"$LEMLIB_LIST" | grep -q .; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 4: scan list reaches package paths outside lean-lib/:"
  grep -v "^$LEMLIB_PKG/lean-lib/" <<<"$LEMLIB_LIST"
  exit 1
fi

RATCHET_LIST_FILE=$(mktemp)
printf '%s\n%s\n' "$LEMLIB_LIST" "$HW_LIST" > "$RATCHET_LIST_FILE"
RATCHET_SCAN=$(python3 - "$RATCHET_LIST_FILE" <<'PYEOF'
import os, re, sys

# comment/string/char-literal stripper — same discipline as the
# generated-tree census scanner above (newlines preserved for line nos)
def strip(src):
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
            j = src.find('\'', i + 2 if src[i+1] != '\\' else i + 3)
            i = (j + 1) if j != -1 else n
            cur.append(' ')
            continue
        cur.append(c); i += 1
    return ''.join(cur)

# C2 audit MAJOR-1 fix (name classes): every load-bearing keyword match
# fires on the KEYWORD alone; name captures use a wide class
# ([^\s\]\[,:(){}]+) so a non-ASCII name («evil») still produces a row
# (which then mismatches the ASCII pin set and FAILS) instead of
# silently defeating the regex (fail-open).
NAME = r"([^\s\]\[,:(){}]+)"
DECL = re.compile(r"\b(?:def|opaque|abbrev|theorem|instance)\s+" + NAME)
UNSAFEDECL = re.compile(r"\bunsafe\s+(?:def|opaque|abbrev|instance|inductive|structure)\s+" + NAME)
# C2 audit MAJOR-2 fix: the bare-@[extern] class joins the pinned
# population — a pure-signature extern is exactly as much a native
# seam as an unsafeBaseIO impl (the digestIO/setDigestIO/md5Hex
# shape). The regex tolerates further attributes in the same block,
# stacked attribute blocks, and modifier prefixes.
EXTERNDECL = re.compile(
    r"@\[[^\]]*\bextern\b[^\]]*\]\s*(?:@\[[^\]]*\]\s*)*"
    r"(?:private\s+|protected\s+|noncomputable\s+|partial\s+|unsafe\s+)*"
    r"(?:def|opaque|abbrev)\s+" + NAME)

def norm(path):
    # minor-1 fix: PATH-QUALIFIED pin keys (a pinned pair reused from a
    # different directory must be visible). The generated/ copy of a
    # hand-written file normalizes onto its source (byte-identity is
    # the sync gate's job; the pin carries the occurrence COUNT, 2 for
    # mirrored files); the consumed LemLib copy normalizes onto its
    # repo-side path.
    lem = 'lean_frontend/.lake/packages/LemLib/lean-lib/'
    gen = 'lean_frontend/generated/'
    if path.startswith(lem):
        return 'lem-lean/lean-lib/' + path[len(lem):]
    if path.startswith(gen):
        return 'lean_frontend/' + path[len(gen):]
    return path

files = [l for l in open(sys.argv[1]).read().splitlines() if l]
print(f"SCANNED {len(files)}")
for path in sorted(files):
    clean = strip(open(path).read())
    key = norm(path)
    def line(pos): return clean.count('\n', 0, pos) + 1
    for m in re.finditer(r"\baxiom\b(?:\s+(\S+))?", clean):
        print(f"AXIOM {path}:{line(m.start())}:{m.group(1) or '<unnamed>'}")
    for m in re.finditer(r"\brunEffectful\b", clean):
        print(f"RUNEFF {path}:{line(m.start())}")
    # delta-audit MAJOR fix (04dffcc9d was asymmetric): the old \s+
    # required whitespace after the keyword, so @[implemented_by«x»]
    # — live Lean, a working behavior redirect — escaped the census.
    # Emission now takes OPTIONAL whitespace, and an attribute-position
    # catch-all (mirroring EXTERNOTHER) fails any implemented_by
    # attribute occurrence not consumed by a pinnable IMPLBY match
    # (covers the 'attribute [implemented_by ...]' spelling — which
    # elaborates on 4.32.2, behaviorally inert post-hoc, still banned).
    implby_spans = []
    for m in re.finditer(r"\bimplemented_by\b\s*" + NAME, clean):
        implby_spans.append(m.span())
        print(f"IMPLBY {key} {m.group(1)} {path}:{line(m.start())}")
    for m in re.finditer(r"(?:@|attribute\s*)\[[^\]]*\bimplemented_by\b[^\]]*\]", clean):
        if not any(m.start() <= s < m.end() for s, e in implby_spans):
            print(f"IMPLBYOTHER {key} - {path}:{line(m.start())}")
    unsafedecl_spans = []
    for m in UNSAFEDECL.finditer(clean):
        unsafedecl_spans.append(m.span())
        print(f"UNSAFEDECL {key} {m.group(1)} {path}:{line(m.start())}")
    extern_spans = []
    for m in EXTERNDECL.finditer(clean):
        extern_spans.append(m.span())
        print(f"EXTERN {key} {m.group(1)} {path}:{line(m.start())}")
    # catch-all restricted to ATTRIBUTE-position extern ('extern' is
    # also a legitimate model identifier — the Core file record's
    # extern field — which the bare-token form would false-positive
    # on): any @[...extern...] / attribute [...extern...] block not
    # consumed by a pinnable EXTERNDECL match fails (this covers the
    # 'attribute [extern ...]' spelling and externs on declaration
    # kinds outside def/opaque/abbrev).
    for m in re.finditer(r"(?:@|attribute\s*)\[[^\]]*\bextern\b[^\]]*\]", clean):
        if not any(s <= m.start() < e for s, e in extern_spans):
            print(f"EXTERNOTHER {key} - {path}:{line(m.start())}")
    for m in re.finditer(r"\bunsafe\b", clean):
        if not any(s <= m.start() < e for s, e in unsafedecl_spans) \
           and not any(s <= m.start() < e for s, e in extern_spans):
            print(f"UNSAFEOTHER {key} - {path}:{line(m.start())}")
    for m in re.finditer(r"\bunsafeBaseIO\b", clean):
        decls = [d for d in DECL.finditer(clean) if d.start() < m.start()]
        encl = decls[-1].group(1) if decls else '<none>'
        print(f"UNSAFEBASEIO {key} {encl} {path}:{line(m.start())}")
PYEOF
) || {
  echo "check_theorem_axioms: FAIL — C2 ratchet: scanner failed (fail-closed)"
  rm -f "$RATCHET_LIST_FILE"
  exit 1
}
rm -f "$RATCHET_LIST_FILE"
if ! grep -q '^SCANNED ' <<<"$RATCHET_SCAN"; then
  echo "check_theorem_axioms: FAIL — C2 ratchet: scanner produced no SCANNED marker (fail-closed)"
  exit 1
fi
RATCHET_NSCANNED=$(grep '^SCANNED ' <<<"$RATCHET_SCAN" | awk '{print $2}')

# leg (1): zero axiom declarations anywhere on the surface (LemLib copy
# recursive + all hand-written/generated lean_frontend sources).
RATCHET_AXIOMS=$(grep '^AXIOM ' <<<"$RATCHET_SCAN" || true)
if [[ -n "$RATCHET_AXIOMS" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 1: axiom declaration(s) on the zero-axiom surface (LemLib declares ZERO axioms since L2; cerberus since arc-17 S2b):"
  echo "$RATCHET_AXIOMS"
  exit 1
fi

# leg (2): runEffectful is a banned token (comment-stripped, so the L2
# HISTORY comment does not trip; a live reintroduction under the same
# name does).
RATCHET_RUNEFF=$(grep '^RUNEFF ' <<<"$RATCHET_SCAN" || true)
if [[ -n "$RATCHET_RUNEFF" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 2: runEffectful token in non-comment position (the effect projection was DELETED by the effect-retirement arc; charter section 7):"
  echo "$RATCHET_RUNEFF"
  exit 1
fi

# leg (3): population pin, both directions, PATH-QUALIFIED + COUNTED
# (C2 audit minor-1: basename+set keying let a pinned pair reappear
# from a different directory invisibly; keys are now normalized paths
# — generated/ copies fold onto their hand-written source, the LemLib
# copy onto its repo path — and every row pins its occurrence COUNT,
# so duplication in place is visible too). C2 audit MAJOR-2: the
# EXTERN kind (bare pure/BaseIO @[extern] declarations) joins the pin.
PIN_EXPECTED=$(grep -E '^PIN (IMPLBY|UNSAFEDECL|UNSAFEBASEIO|EXTERN) ' "$ALLOWLIST" | awk '{print $2" "$3" "$4" "$5}' | sort -u || true)
if [[ -z "$PIN_EXPECTED" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 3: no PIN rows in $ALLOWLIST (fail-closed; the population pin has no input)"
  exit 1
fi
if grep -Ev '^[A-Z]+ [^ ]+ [^ ]+ [0-9]+$' <<<"$PIN_EXPECTED" | grep -q .; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 3: malformed PIN row(s) in $ALLOWLIST (expected: PIN KIND PATH NAME COUNT):"
  grep -Ev '^[A-Z]+ [^ ]+ [^ ]+ [0-9]+$' <<<"$PIN_EXPECTED"
  exit 1
fi
RATCHET_UNSAFEOTHER=$(grep '^UNSAFEOTHER ' <<<"$RATCHET_SCAN" || true)
if [[ -n "$RATCHET_UNSAFEOTHER" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 3: 'unsafe' token outside a pinnable declaration form (extend the scanner/pin consciously, never ignore):"
  echo "$RATCHET_UNSAFEOTHER"
  exit 1
fi
RATCHET_EXTERNOTHER=$(grep '^EXTERNOTHER ' <<<"$RATCHET_SCAN" || true)
if [[ -n "$RATCHET_EXTERNOTHER" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 3: 'extern' token outside a pinnable @[extern] declaration form (e.g. the 'attribute [extern ...]' spelling — extend the scanner/pin consciously, never ignore):"
  echo "$RATCHET_EXTERNOTHER"
  exit 1
fi
RATCHET_IMPLBYOTHER=$(grep '^IMPLBYOTHER ' <<<"$RATCHET_SCAN" || true)
if [[ -n "$RATCHET_IMPLBYOTHER" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 3: 'implemented_by' attribute occurrence outside a pinnable IMPLBY census form (e.g. the 'attribute [implemented_by ...]' spelling — extend the scanner/pin consciously, never ignore):"
  echo "$RATCHET_IMPLBYOTHER"
  exit 1
fi
PIN_FOUND=$(grep -E '^(IMPLBY|UNSAFEDECL|UNSAFEBASEIO|EXTERN) ' <<<"$RATCHET_SCAN" | awk '{print $1" "$2" "$3}' | sort | uniq -c | awk '{print $2" "$3" "$4" "$1}' || true)
PIN_NEW=$(comm -13 <(echo "$PIN_EXPECTED") <(echo "$PIN_FOUND"))
PIN_MISSING=$(comm -23 <(echo "$PIN_EXPECTED") <(echo "$PIN_FOUND"))
if [[ -n "$PIN_NEW" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 3: implemented_by/unsafe/unsafeBaseIO/extern census row(s) not matching the pinned population ($ALLOWLIST PIN rows; format KIND PATH NAME COUNT). Every such seam is a declared-boundary decision — register it there with its Q4 class, or remove it:"
  echo "$PIN_NEW"
  grep -E '^(IMPLBY|UNSAFEDECL|UNSAFEBASEIO|EXTERN) ' <<<"$RATCHET_SCAN" | awk -v new="$PIN_NEW" 'BEGIN{split(new,a,"\n"); for(i in a){ n=split(a[i],b," "); if(n>=3) want[b[1]" "b[2]" "b[3]]=1 }} { key=$1" "$2" "$3; if (key in want) print "  at "$4 }'
  exit 1
fi
if [[ -n "$PIN_MISSING" ]]; then
  echo "check_theorem_axioms: FAIL — C2 ratchet leg 3: pinned population row(s) NOT FOUND at their pinned count (scanner or copy-pipeline drift, or a survivor deleted/duplicated without updating the pin — update $ALLOWLIST consciously):"
  echo "$PIN_MISSING"
  exit 1
fi
PIN_COUNT=$(wc -l <<<"$PIN_EXPECTED")
echo "check_theorem_axioms: C2 ratchet OK ($RATCHET_NSCANNED files scanned recursively: 0 axioms, 0 runEffectful, seam population = the $PIN_COUNT pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)"

# ---------------------------------------------------------------------------
# D14 ban (arc-6): non-kernel proof methods (native_decide / bv_decide).
# Two legs, both fail-closed:
#   * grep leg (here): the banned tactics may not occur in the test
#     sources — lean_frontend/test/**, the hand-written top-level
#     lean_frontend/*.lean seams (where the mem-scale S1 theorems
#     live; formerly lean_frontend/relsemcore/**, removed 2026-09-02),
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
# The hand-written seams (top level only — generated/ carries copies of
# these plus the lem output, and .lake is not source). Fail-closed on an
# empty set: an empty glob would make this leg vacuous.
D14_HW=()
while IFS= read -r -d '' f; do D14_HW+=("$f"); done \
  < <(find "$D14_ROOT/lean_frontend" -maxdepth 1 -type f -name '*.lean' -print0 | LC_ALL=C sort -z)
if [[ ${#D14_HW[@]} -eq 0 ]]; then
  echo "check_theorem_axioms: FAIL — D14 grep-ban: no hand-written lean_frontend/*.lean found (fail-closed; vacuous scan)"
  exit 1
fi
D14_LEMLIB_TEST="$D14_ROOT/lean_frontend/.lake/packages/LemLib/lean-lib/LemLibTest.lean"
if [[ ! -f "$D14_LEMLIB_TEST" ]]; then
  echo "check_theorem_axioms: FAIL — D14 grep-ban: $D14_LEMLIB_TEST missing (fail-closed)"
  exit 1
fi
D14_HITS=$(grep -rnE 'native_decide|bv_decide' "${D14_SCAN_PATHS[@]}" "${D14_HW[@]}" "$D14_LEMLIB_TEST" || true)
if [[ -n "$D14_HITS" ]]; then
  echo "check_theorem_axioms: FAIL — D14 ban: native_decide/bv_decide found in test/proof sources:"
  echo "$D14_HITS"
  exit 1
fi
echo "check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in ${#D14_SCAN_PATHS[@]} tree(s) + ${#D14_HW[@]} hand-written seam files + LemLibTest.lean)"

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

# ---------------------------------------------------------------------------
# C2 ratchet leg (5): exec-entry EXACT axiom census (charter sections
# 1.3/7.2). The full customer-contract entry set, tightened from
# ban-lists to an exact allowlist: every reported axiom must be one of
# propext / Classical.choice / Quot.sound; anything else fails with the
# constant named. These probes are END-TO-END SPOT CHECKS of the
# census-derived universal claim, NOT primary evidence (#print axioms
# underreports across partial-def/opaque boundaries — the source-scan
# legs above are the load-bearing gate; charter 7.2 caveat). Fail-closed:
# each entry must produce exactly one probe line.
# ---------------------------------------------------------------------------
PROBE3=lean_frontend/.axiom-probe-entries.lean
ENTRIES=(driver2 drive initial_driver_state desugar annotate_program
         translate link convert_file CerbCall.driveCall)
{
  cat <<'EOF'
import Driver
import Cabs_to_ail
import GenTyping
import Translation
import Core_linking
import Core_run_aux
import CerbCall
EOF
  for name in "${ENTRIES[@]}"; do
    echo "#print axioms $name"
  done
} > "$PROBE3"
OUT3=$(cd lean_frontend && "$SCRIPT_DIR/capped" lake env lean .axiom-probe-entries.lean 2>&1 | grep -v -i warning || true)
rm -f "$PROBE3"
echo "$OUT3"
for name in "${ENTRIES[@]}"; do
  esc=${name//./\\.}
  n=$(grep -cE "'${esc}' (depends on axioms|does not depend on any axioms)" <<<"$OUT3" || true)
  if [[ "$n" -ne 1 ]]; then
    echo "check_theorem_axioms: FAIL — C2 entry census: probe for '$name' did not run cleanly (matched $n lines; fail-closed)"
    exit 1
  fi
done
# exact allowlist: parse each axiom list; any member outside the three
# standard axioms fails naming the entry and the axiom.
ENTRY_BAD=$(python3 - <<PYEOF
import re, sys
out = """$OUT3"""
ok = {"propext", "Classical.choice", "Quot.sound"}
bad = []
for m in re.finditer(r"'([^']+)' depends on axioms: \[([^\]]*)\]", out):
    entry, axs = m.group(1), [a.strip() for a in m.group(2).split(',') if a.strip()]
    for a in axs:
        if a not in ok:
            bad.append(f"{entry}: {a}")
print("\n".join(bad))
PYEOF
)
if [[ -n "$ENTRY_BAD" ]]; then
  echo "check_theorem_axioms: FAIL — C2 entry census: axiom outside the exact allowlist [propext, Classical.choice, Quot.sound]:"
  echo "$ENTRY_BAD"
  exit 1
fi
echo "check_theorem_axioms: C2 entry census OK (${#ENTRIES[@]} entries, every cone ⊆ [propext, Classical.choice, Quot.sound])"

# ---------------------------------------------------------------------------
# mem-scale S1 leg (2026-09-02; charter 2026-09-01_mem-scale-design.md
# §1 carve-out [R1/F5], §6.2): the hand-written memory model's two
# documented algorithmic divergences (C1 linear `reconstructValue` array
# arm, C3 linear `memValueToBytes` struct arm) are admitted ONLY as
# kernel-checked equalities with their pre-change reference forms. The
# theorems live in CerbMem.lean next to the definitions; this leg asserts
# they exist, elaborate, and sit in the clean cone — exact allowlist
# [propext, Classical.choice, Quot.sound]; sorryAx / ofReduce* / DAEMON
# fatal as everywhere. Fail-closed: each name must produce exactly one
# probe line (a renamed or deleted theorem fails here, not silently).
# ---------------------------------------------------------------------------
PROBE4=lean_frontend/.axiom-probe-memscale.lean
MEMSCALE_THMS=(CerbMem.chunksOf_eq_range_map
               CerbMem.reconstructValue_lemFuel_eq_indexed
               CerbMem.reconstructValue_eq_indexed
               CerbMem.foldl_append_eq_flatten_reverse
               CerbMem.memValueToBytes_lemFuel_eq_append
               CerbMem.memValueToBytes_eq_append)
{
  echo "import CerbMem"
  for name in "${MEMSCALE_THMS[@]}"; do
    echo "#print axioms $name"
  done
} > "$PROBE4"
OUT4=$(cd lean_frontend && "$SCRIPT_DIR/capped" lake env lean .axiom-probe-memscale.lean 2>&1 | grep -v -i warning || true)
rm -f "$PROBE4"
echo "$OUT4"
for name in "${MEMSCALE_THMS[@]}"; do
  esc=${name//./\\.}
  n=$(grep -cE "'${esc}' (depends on axioms|does not depend on any axioms)" <<<"$OUT4" || true)
  if [[ "$n" -ne 1 ]]; then
    echo "check_theorem_axioms: FAIL — mem-scale S1 leg: probe for '$name' did not run cleanly (matched $n lines; fail-closed)"
    exit 1
  fi
done
MEMSCALE_BAD=$(python3 - <<PYEOF
import re
out = """$OUT4"""
ok = {"propext", "Classical.choice", "Quot.sound"}
bad = []
for m in re.finditer(r"'([^']+)' depends on axioms: \[([^\]]*)\]", out):
    entry, axs = m.group(1), [a.strip() for a in m.group(2).split(',') if a.strip()]
    for a in axs:
        if a not in ok:
            bad.append(f"{entry}: {a}")
print("\n".join(bad))
PYEOF
)
if [[ -n "$MEMSCALE_BAD" ]]; then
  echo "check_theorem_axioms: FAIL — mem-scale S1 leg: axiom outside the exact allowlist [propext, Classical.choice, Quot.sound]:"
  echo "$MEMSCALE_BAD"
  exit 1
fi
echo "check_theorem_axioms: mem-scale S1 leg OK (${#MEMSCALE_THMS[@]} C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])"

# ---------------------------------------------------------------------------
# FUEL arc leg (2026-09-03; design docs/2026-09-02_fuel-arc-design.md §1.2,
# §6 "pinned-lemma gate"): the customer contract shipped in the hand-
# written CerbND.lean — the nine worker `_zero` lemmas, the three runner
# leaves, the two constructor-disjointness lemmas, the wrapper/budget
# `rfl`s and the SYNC GUARANTEE `drive_wrapper_defeq` — plus the exemplar
# instances over the shipped pipeline (test/Unit/FuelExemplar.lean: the
# consumer shape at fuel 0 and at fuel 1; the ∀-fuel statement is the
# slice's STOP-AND-REPORT item, see that file's header), each
# in the clean cone: exact allowlist [propext, Classical.choice,
# Quot.sound]; sorryAx / ofReduce* / DAEMON fatal as everywhere. That the
# lemmas ELABORATE at all is the pinned-lemma gate (a renamed generated
# binder or a regenerated `drive` body fails our build first); this leg
# additionally pins their axiom cones. Fail-closed: each name must
# produce exactly one probe line.
# ---------------------------------------------------------------------------
PROBE5=lean_frontend/.axiom-probe-fuel.lean
FUEL_THMS=(CerbND.nd_bind_lemFuel_zero CerbND.liftND_lemFuel_zero CerbND.liftAction_lemFuel_zero
           CerbND.print_eval_conv_aux_lemFuel_zero CerbND.drive_nonmemory_steps_aux2_lemFuel_zero
           CerbND.driver2_lemFuel_zero CerbND.find_array_index_lemFuel_zero
           CerbND.easy_update_mem_value_aux_lemFuel_zero CerbND.memcmp_load_aux_lemFuel_zero
           CerbND.runNDFuel_zero CerbND.runND1Fuel_zero CerbND.runND1TraceFuel_zero
           CerbND.fuelExhaustedKill_ne_Undef0 CerbND.fuelExhaustedKill_ne_Other
           CerbND.driverFuel_eq CerbND.driver2_wrapper_defeq CerbND.nd_bind_wrapper_defeq
           CerbND.runND_eq CerbND.drive_wrapper_defeq CerbND.drive_lemFuel
           FuelExemplar.exemplar_certified_shipped_zero FuelExemplar.exemplar_run_one_kernel
           FuelExemplar.exemplar_certified_shipped_one)
{
  echo "import CerbND"
  echo "import Unit.FuelExemplar"
  for name in "${FUEL_THMS[@]}"; do
    echo "#print axioms $name"
  done
} > "$PROBE5"
OUT5=$(cd lean_frontend && "$SCRIPT_DIR/capped" lake env lean .axiom-probe-fuel.lean 2>&1 | grep -v -i warning || true)
rm -f "$PROBE5"
echo "$OUT5"
for name in "${FUEL_THMS[@]}"; do
  esc=${name//./\\.}
  n=$(grep -cE "'${esc}' (depends on axioms|does not depend on any axioms)" <<<"$OUT5" || true)
  if [[ "$n" -ne 1 ]]; then
    echo "check_theorem_axioms: FAIL — FUEL arc leg: probe for '$name' did not run cleanly (matched $n lines; fail-closed)"
    exit 1
  fi
done
FUEL_BAD=$(python3 - <<PYEOF
import re
out = """$OUT5"""
ok = {"propext", "Classical.choice", "Quot.sound"}
bad = []
for m in re.finditer(r"'([^']+)' depends on axioms: \[([^\]]*)\]", out):
    entry, axs = m.group(1), [a.strip() for a in m.group(2).split(',') if a.strip()]
    for a in axs:
        if a not in ok:
            bad.append(f"{entry}: {a}")
print("\n".join(bad))
PYEOF
)
if [[ -n "$FUEL_BAD" ]]; then
  echo "check_theorem_axioms: FAIL — FUEL arc leg: axiom outside the exact allowlist [propext, Classical.choice, Quot.sound]:"
  echo "$FUEL_BAD"
  exit 1
fi
echo "check_theorem_axioms: FUEL arc leg OK (${#FUEL_THMS[@]} contract lemmas + drive_lemFuel + the exemplar instances, every cone ⊆ [propext, Classical.choice, Quot.sound])"

echo "check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)"
