#!/usr/bin/env bash
# check_switches_instance.sh — GATE: no hidden default switch set (PNVI arc S1, 2026-10-05;
# design lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §B.3 + §D.2 P5/P8; record
# lean_frontend/docs/2026-10-05_pnvi-s1-switch-parameter-record.md §4; hardened by the
# pre-merge audit's L1, 2026-10-06, record §4.1a).
#
# THE PROPERTY: the switch set is the instance-implicit parameter `[CerbGlobal.Switches]`
# (the `[LemFuel]` shape). It must never be supplied by an INSTANCE DECLARATION inside this
# repository — a global instance would be a hidden default that every lifted definition
# silently resolves to, so a theorem that "quantifies over the switch set" would in fact be
# about that one value. The entry point supplies the run's instance once: Main.lean's
#     let code ← (letI : LemFuel := ⟨fuel⟩; letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩; runPipeline …
#
# SCOPE — THIS REPOSITORY ONLY (consumer statement §1.5 item 2, adopted [AGENT] in design §B.3).
#   The scan ROOTS (printed by SWITCHES_GATE_LIST=1):
#   lean_frontend/*.lean (the seams, Main.lean included), lean_frontend/generated/*.lean,
#   lean_frontend/speclab/*.lean + speclab/SpecLab/** (PRODUCTION);
#   lean_frontend/test/**, lean_frontend/speclab/test/** and tests/**/*.lean (TEST);
#   the LemLib copy the build consumes (lean_frontend/.lake/packages/LemLib/lean-lib);
#   .lake trees excluded everywhere else. A CONSUMER's tree is never scanned: a consumer
#   declaring its own instance (cerberus-sl: one, at `defaultSwitches`, in one layer module)
#   is the intended way to state default-mode facts by `rfl`. The selftest's P8b plant tests
#   that scoping rule for real (below).
#
# Forbidden (comment-stripped text; string literals are NOT stripped, so a name spelled in a
# string is seen and, outside the whitelist, RED):
#   S1  an `instance` declaration (any modifiers/name/priority/binders) whose head names
#       `Switches` — `instance : CerbGlobal.Switches := …`, `scoped instance foo : Switches where …`
#   S2  an instance ATTRIBUTE (`@[… instance …]`, `attribute [… instance …]`) in a file that
#       mentions `Switches`, or ANYWHERE naming an S4/S5 alias or a declared switch-set value
#   S3  in PRODUCTION text: a value or local instance of the class — the token in a typed-value
#       position `… : (CerbGlobal.)Switches` followed by `:=`, `where` or `|` (any of
#       `letI`/`haveI`/`let`/`have`/`def`/`abbrev`/`theorem`/`opaque`/`example`, single- or
#       multi-line header) — except Main.lean's allowlisted line above. PRODUCTION vs TEST is
#       the root split above. Tests MAY build an explicit value (`letI : CerbGlobal.Switches :=
#       ⟨CerbGlobal.defaultSwitches⟩` in a test's entry, `def sw₀ : CerbGlobal.Switches := …`,
#       `@f ⟨n⟩ sw₀`) — design D4: a visible choice at the use, the way the tests choose their
#       fuel, not a default anything resolves to (S2/S6 stop such a value becoming an instance).
#   S4  an ALIAS: a declaration/notation/macro (`abbrev`/`def`/`@[reducible] def`/`opaque`/
#       `notation`/`macro`/`syntax`/`macro_rules`/`elab`) whose BODY names `Switches`
#       (`abbrev MySw := CerbGlobal.Switches`, `notation "S" => CerbGlobal.Switches`)
#   S5  a `class`/`structure … extends … Switches`
#   S6  an `instance` whose head or body names an S4/S5 alias or a declared switch-set value
#       (`instance : MySw := ⟨[]⟩`, `instance := sw₀`) — the names are collected repo-wide
#   S7  ANY OTHER occurrence of the token `Switches`: every occurrence must sit in one of the
#       whitelisted positions W1 `[(x :) (CerbGlobal.)Switches]` (instance-implicit binder),
#       W2 `(x … : (CerbGlobal.)Switches)` (explicit binder), W3 `(CerbGlobal.)Switches.switches`
#       (the projection), W4 `class Switches where` (CerbGlobal.lean, the definition), W5 the
#       typed-value position (S3 in production, allowed in tests); anything else — an
#       `extends`/alias body not caught above, a type ascription `(v : Switches)`, `type_of%`,
#       a `` ``CerbGlobal.Switches `` name literal, a string, `«Switches»` — is RED.
# RESIDUAL LIMIT (stated, not closable textually): the gate reads text, so it cannot see the
#   class reached WITHOUT spelling the token `Switches` — a name assembled from strings at
#   meta-level (`Name.mkStr … ("Swit" ++ "ches")`), a type recovered by elaboration from a
#   definition's signature (`type_of% @CerbGlobal.has_switch` and projections thereof), an
#   untyped `instance := e` whose `e` is not a collected name (e.g. `instance := @id _ ⟨[]⟩`
#   elaborated against nothing), or any of these in files outside the scan roots. Those are
#   review discipline; the BACKSTOP is the typing (a lifted definition with no instance in
#   scope does not elaborate) and the consumer-facing statement form `@f ⟨sw⟩`.
# Vacuity guards: ≥ MIN_FILES files scanned; the class `class Switches` present in
#   CerbGlobal.lean (exactly one W4 occurrence in it and in its generated copy); Main.lean's allowlisted line present
#   (hand-written AND generated copy); ≥ one `[CerbGlobal.Switches]` binder in the generated
#   tree; the LemLib copy present.
#
# --selftest: plants on scratch COPIES of the scan set — each must be RED with its label(s);
#   the unplanted copy must be GREEN; then P8b (the consumer direction, a real test): a
#   consumer-style package with its own instance in a scratch copy's `.tmp/` (outside the
#   roots) leaves the copy GREEN, the SAME file placed under a scanned root is RED (S1), and
#   the gate's root/file list (SWITCHES_GATE_LIST=1) is asserted to exclude it; then the real
#   tree. Nothing in the tree is touched (all scratch under .tmp/, deleted).
set -uo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

gate() {  # <repo root> -> prints verdict, returns 0/1
    python3 - "$1" "$SCRIPT_DIR" <<'PY'
import os, re, sys, glob
root, sd = sys.argv[1], sys.argv[2]
sys.path.insert(0, sd)
from failure_census import strip_comments
MIN_FILES = 150
ALLOW = 'let code ← (letI : LemFuel := ⟨fuel⟩; letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩; runPipeline runtimeDir batchMode ppCoreMode firstTrace'
lf = os.path.join(root, 'lean_frontend')
def tree(d):
    out = []
    for dp, dns, fns in os.walk(d):
        dns[:] = [x for x in dns if x != '.lake']
        out += [os.path.join(dp, f) for f in fns if f.endswith('.lean')]
    return out
# the scan roots: (label, path, kind, how) — the ONE place the scope is defined
lemlib_dir = os.path.join(lf, '.lake', 'packages', 'LemLib', 'lean-lib')
ROOTS = [('seams', os.path.join(lf, '*.lean'), 'prod', 'glob'),
         ('generated', os.path.join(lf, 'generated', '*.lean'), 'prod', 'glob'),
         ('speclab-top', os.path.join(lf, 'speclab', '*.lean'), 'prod', 'glob'),
         ('speclab-lib', os.path.join(lf, 'speclab', 'SpecLab'), 'prod', 'tree'),
         ('test', os.path.join(lf, 'test'), 'test', 'tree'),
         ('speclab-test', os.path.join(lf, 'speclab', 'test'), 'test', 'tree'),
         ('tests', os.path.join(root, 'tests'), 'test', 'tree'),
         ('lemlib', lemlib_dir, 'lemlib', 'tree')]
kinds = {'prod': [], 'test': [], 'lemlib': []}
for _, p, kind, how in ROOTS:
    kinds[kind] += glob.glob(p) if how == 'glob' else (tree(p) if os.path.isdir(p) else [])
prod, tests, lemlib = (sorted(set(kinds[k])) for k in ('prod', 'test', 'lemlib'))
files = prod + tests + lemlib
prodset = set(prod)
if os.environ.get('SWITCHES_GATE_LIST') == '1':
    for lab, p, kind, how in ROOTS: print(f"ROOT {kind} {how} {os.path.relpath(p, root)}")
    for f in files: print(f"FILE {os.path.relpath(f, root)}")
    sys.exit(0)
fail = []
if not lemlib:
    fail.append(f"vacuous: the LemLib copy {os.path.relpath(lemlib_dir, root)} is absent (build lean_frontend first)")
if len(files) < MIN_FILES:
    fail.append(f"vacuous: only {len(files)} files to scan (< {MIN_FILES}) — regenerate lean_frontend/generated first")
rel = lambda p: os.path.relpath(p, root)
INST = re.compile(r"(?<![\w.'])instance(?![\w'])")
ATTR = re.compile(r"@\[[^\]]*(?<![\w.'])instance(?![\w'])[^\]]*\]|attribute\s*\[[^\]]*(?<![\w.'])instance(?![\w'])[^\]]*\]")
SW = re.compile(r"(?<![\w'])Switches(?![\w'])")
CMD = re.compile(r"(?m)^\S")
DECL = re.compile(r"(?:@\[[^\]]*\]\s*)*(?:(?:private|protected|noncomputable|partial|unsafe|scoped|local)\s+)*"
                  r"(abbrev|def|opaque|notation|macro|syntax|macro_rules|elab|class|structure|theorem|example|instance|axiom)(?![\w'])\s*(?:\(priority\s*:=[^)]*\)\s*)?([^\s:(\[{⟨]*)")
ALIAS_KW = {'abbrev', 'def', 'opaque', 'notation', 'macro', 'syntax', 'macro_rules', 'elab'}
texts = {}
for f in files:
    try:
        texts[f] = strip_comments(open(f, encoding='utf-8').read())
    except ValueError as e:
        fail.append(f"{rel(f)}: comment stripper: {e} (fail-closed)")
def lineno(t, k): return t.count('\n', 0, k) + 1
def command(t, k):  # the top-level command containing offset k: (start, header match or None)
    st = 0
    for m in CMD.finditer(t, 0, k + 1):
        st = m.start()
    return st, DECL.match(t, st)
def head_cut(t, k):  # an instance head from offset k: up to `:=`/`where` outside brackets or a blank line
    rest = t[k:k + 400]
    cut, depth, j = len(rest), 0, 0
    while j < len(rest):
        c = rest[j]
        if c in '([{⟨': depth += 1
        elif c in ')]}⟩': depth = max(0, depth - 1)
        elif depth == 0 and (rest.startswith(':=', j) or rest.startswith('\n\n', j)
                             or re.match(r"where(?![\w'])", rest[j:]) and (j == 0 or not (rest[j-1].isalnum() or rest[j-1] in "_'"))):
            cut = j; break
        j += 1
    return rest[:cut]
def clean_name(n): return n.strip('"').strip('«»').split('.')[-1]
names = {}  # collected alias / value names -> provenance
binders = 0; allow_seen = []; w4 = []
# pass 1: classify every `Switches` token
for f, t in texts.items():
    for m in SW.finditer(t):
        s, e = m.start(), m.end()
        pre, post = t[max(0, s - 200):s], t[e:e + 200]
        core = pre[:-len('CerbGlobal.')] if pre.endswith('CerbGlobal.') else pre
        where = f"{rel(f)}:{lineno(t, s)}"
        if re.search(r"\[\s*(?:[\w']+\s*:\s*)?$", core) and re.match(r"\s*\]", post): continue          # W1
        if re.search(r"\(\s*(?:[\w']+\s+)*[\w']+\s*:\s*$", core) and re.match(r"\s*\)", post): continue  # W2
        if re.match(r"\.switches(?![\w'])", post): continue                                              # W3
        if (os.path.basename(f) == 'CerbGlobal.lean' and f in prodset and re.search(r"(?:^|\n)class\s+$", core)
                and core is pre and re.match(r"\s+where(?![\w'])", post)):
            w4.append(where); continue                                                                   # W4
        st, dm = command(t, s)
        kw = dm.group(1) if dm else None
        nm = clean_name(dm.group(2)) if dm and dm.group(2) else ''
        if re.search(r"(?<![:=]):\s*$", core) and re.match(r"\s*(?::=|where(?![\w'])|\|)", post):          # W5
            # a NAMED value only when the token is the declaration's own type (its header,
            # before any `:=`/`where`/local binder) — a `letI` inside `def main` names nothing
            if (kw in ('def', 'abbrev', 'opaque', 'theorem') and nm and not re.search(
                    r":=|(?<![\w'])(?:where|let|letI|have|haveI|fun|do)(?![\w'])", t[st:s])):
                names.setdefault(nm, f"switch-set value `{nm}` ({where})")
            if f in prodset:
                ln = t[t.rfind('\n', 0, s) + 1: t.find('\n', s)].strip()
                if os.path.basename(f) == 'Main.lean' and ln == ALLOW:
                    allow_seen.append(rel(f)); continue
                fail.append(f"S3 {where}: a production value/local instance of the switch-set class outside Main.lean's entry: {ln[:120]}")
            continue
        between = t[st:s]
        if kw in ('class', 'structure') and re.search(r"(?<![\w'])extends(?![\w'])", between):
            if nm: names.setdefault(nm, f"class `{nm}` extending Switches ({where})")
            fail.append(f"S5 {where}: `{kw} {nm} extends … Switches` — an extension of the switch-set class")
        elif kw in ALIAS_KW and re.search(r":=|=>|`\(", between):
            if nm: names.setdefault(nm, f"alias `{nm}` ({where})")
            fail.append(f"S4 {where}: `{kw} {nm}` — an alias of the switch-set class (its body names Switches)")
        else:
            snip = t[max(0, s - 40):e + 20].replace('\n', '⏎')
            fail.append(f"S7 {where}: an unrecognised use of the switch-set class (not a binder/projection/typed value): …{snip}…")
# pass 2: instances and instance attributes
if names:
    NAMES = re.compile(r"(?<![\w'])(?:[\w'.«»]*\.)?«?(" + "|".join(re.escape(n) for n in sorted(names, key=len, reverse=True)) + r")»?(?![\w'])")
else:
    NAMES = None
for f, t in texts.items():
    for m in INST.finditer(t):
        head = head_cut(t, m.end())
        if SW.search(head):
            fail.append(f"S1 {rel(f)}:{lineno(t, m.start())}: an instance declaration of the switch-set class (a hidden default)")
        if NAMES:
            nxt = CMD.search(t, m.end())
            seg = t[m.end(): nxt.start() if nxt else len(t)][:2000]
            for n in sorted(set(x.group(1) for x in NAMES.finditer(seg))):
                fail.append(f"S6 {rel(f)}:{lineno(t, m.start())}: an instance naming {names[n]}")
    for m in ATTR.finditer(t):
        nxt = CMD.search(t, m.end())
        seg = t[m.start(): nxt.start() if nxt else len(t)][:2000]
        if SW.search(t):
            fail.append(f"S2 {rel(f)}:{lineno(t, m.start())}: an instance attribute in a file that names Switches")
        elif NAMES and NAMES.search(seg):
            n = NAMES.search(seg).group(1)
            fail.append(f"S2 {rel(f)}:{lineno(t, m.start())}: an instance attribute naming {names[n]}")
    if f.startswith(os.path.join(lf, 'generated') + os.sep):
        binders += t.count('[CerbGlobal.Switches]')
cg = os.path.join(lf, 'CerbGlobal.lean')
if not (os.path.isfile(cg) and re.search(r'^class Switches where', open(cg).read(), re.M)):
    fail.append("vacuous: `class Switches where` not found in lean_frontend/CerbGlobal.lean")
w4want = ['lean_frontend/CerbGlobal.lean', 'lean_frontend/generated/CerbGlobal.lean']
if sorted(w.rsplit(':', 1)[0] for w in w4) != w4want:
    fail.append(f"vacuous/duplicate: expected exactly one `class Switches where` (W4) in each of {w4want}, saw {w4}")
want = {'lean_frontend/Main.lean', 'lean_frontend/generated/Main.lean'}
if set(allow_seen) != want:
    fail.append(f"vacuous: Main.lean's allowlisted entry instance seen in {sorted(set(allow_seen))}, expected {sorted(want)}")
if binders < 1:
    fail.append("vacuous: no `[CerbGlobal.Switches]` binder in lean_frontend/generated (the lifting is absent?)")
if fail:
    print("check_switches_instance: FAIL"); [print("  " + x) for x in fail[:40]]; sys.exit(1)
print(f"check_switches_instance: OK ({len(files)} files scanned: {len(prod)} production, {len(tests)} test, {len(lemlib)} LemLib; "
      f"no instance/alias/extension of CerbGlobal.Switches, every use whitelisted; {len(names)} test-side named value(s); "
      f"the one entry instance is Main.lean's letI; {binders} generated [CerbGlobal.Switches] binders)")
PY
}

selftest() {
    echo "check_switches_instance: SELFTEST — planting on scratch copies (loud plant banner; nothing in the tree is touched)"
    local work fail=0 nplant=0
    work=$(mktemp -d "$ROOT/.tmp/switches-gate-plant.XXXXXX") || { echo "check_switches_instance: SELFTEST FAILED — no scratch dir under $ROOT/.tmp"; return 1; }
    mk() {  # fresh scratch copy of the scan set
        rm -rf "$work/r"; mkdir -p "$work/r/lean_frontend" "$work/r/scripts"
        cp "$ROOT"/lean_frontend/*.lean "$work/r/lean_frontend/"
        cp -r "$ROOT/lean_frontend/generated" "$ROOT/lean_frontend/test" "$work/r/lean_frontend/"
        mkdir -p "$work/r/lean_frontend/speclab"
        (cd "$ROOT/lean_frontend/speclab" && find . -name '*.lean' -not -path '*/.lake/*' | cpio -pdm --quiet "$work/r/lean_frontend/speclab")
        (cd "$ROOT" && find tests -name '*.lean' -not -path '*/.lake/*' | cpio -pdm --quiet "$work/r")
        mkdir -p "$work/r/lean_frontend/.lake/packages/LemLib"
        cp -r "$ROOT/lean_frontend/.lake/packages/LemLib/lean-lib" "$work/r/lean_frontend/.lake/packages/LemLib/"
        find "$work/r/lean_frontend/.lake/packages/LemLib/lean-lib" -name .lake -prune -exec rm -rf {} +
    }
    # plant <label> <expect: "TAG:file[,TAG:file…]"> <file> <text> [<file> <text>]…
    # every expected `TAG lean_frontend/<file>` must appear in the RED output
    plant() {
        local label=$1 expect=$2; shift 2
        mk
        while [[ $# -ge 2 ]]; do printf '\n%s\n' "$2" >> "$work/r/lean_frontend/$1"; shift 2; done
        local out rc ok=1 e tag file; out=$(gate "$work/r"); rc=$?
        nplant=$((nplant + 1))
        [[ $rc -eq 1 ]] || ok=0
        IFS=',' read -ra exps <<< "$expect"
        for e in "${exps[@]}"; do tag=${e%%:*}; file=${e#*:}
            [[ "$out" == *"$tag lean_frontend/$file"* ]] || ok=0; done
        if [[ $ok -eq 1 ]]; then
            echo "  PLANT OK   [$label] -> $(echo "$out" | grep -m1 "  ${exps[0]%%:*} lean_frontend/${exps[0]#*:}")"
            for e in "${exps[@]:1}"; do echo "               + $(echo "$out" | grep -m1 "  ${e%%:*} lean_frontend/${e#*:}")"; done
        else
            echo "  PLANT FAIL [$label] rc=$rc expected $expect: $out"; fail=1
        fi
    }
    plant "P5/P8a instance in a seam" S1:CerbND.lean CerbND.lean 'instance : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩'
    plant "P8a instance in generated/" S1:generated/Driver.lean generated/Driver.lean 'instance (priority := low) plantSw : CerbGlobal.Switches where switches := []'
    plant "P8a instance in test/" S1:test/Unit/OpaqueFailureTest.lean test/Unit/OpaqueFailureTest.lean 'instance : Switches := ⟨[]⟩'
    plant "P8a instance in speclab/" S1:speclab/test/SLUnit/CoreGateTest.lean speclab/test/SLUnit/CoreGateTest.lean 'scoped instance plantSw2 :
    CerbGlobal.Switches := ⟨[]⟩'
    plant "S2 instance attribute" S2:CerbMem.lean CerbMem.lean '@[instance] def plantSw3 : CerbGlobal.Switches := ⟨[]⟩'
    plant "S3 production letI outside Main" S3:CerbCall.lean CerbCall.lean 'def plantSw4 := (letI : CerbGlobal.Switches := ⟨[]⟩; (0 : Nat))'
    plant "S3 production named default" S3:generated/Translation.lean generated/Translation.lean 'def plantSw5 : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩'
    # L1 (pre-merge audit 2026-10-06): aliases, extensions, `where`/multi-line values, untyped instances, catch-all
    plant "L1a abbrev alias + instance at the alias" S4:CerbND.lean,S6:CerbND.lean CerbND.lean 'abbrev MySw := CerbGlobal.Switches
instance : MySw := ⟨[]⟩'
    plant "L1a @[reducible] def alias in test/ (aliases banned in tests too)" S4:test/Unit/OpaqueFailureTest.lean test/Unit/OpaqueFailureTest.lean '@[reducible] def MySw2 : Type := CerbGlobal.Switches'
    plant "L1a guillemet-spelled alias" S4:CerbMem.lean CerbMem.lean 'abbrev MySw3 := CerbGlobal.«Switches»'
    plant "L1a alias in one file, its instance in another (no Switches token there)" S4:CerbCall.lean,S6:generated/Driver.lean CerbCall.lean 'abbrev MySw4 := CerbGlobal.Switches' generated/Driver.lean 'instance plantI : CerbCall.MySw4 := ⟨[]⟩'
    plant "L1a notation alias" S4:CerbND.lean CerbND.lean 'notation "MySwN" => CerbGlobal.Switches'
    plant "L1b class extends Switches + instance" S5:CerbND.lean,S6:CerbND.lean CerbND.lean 'class MyCls extends CerbGlobal.Switches
instance : MyCls := ⟨⟨[]⟩⟩'
    plant "L1b structure extends Switches in test/" S5:test/Unit/OpaqueFailureTest.lean test/Unit/OpaqueFailureTest.lean 'structure MyStr extends Switches where
  extra : Nat'
    plant "L1c production def … where" S3:generated/Translation.lean generated/Translation.lean 'def plantSw6 : CerbGlobal.Switches where
  switches := []'
    plant "L1c production multi-line abbrev header" S3:CerbCall.lean CerbCall.lean 'abbrev plantSw7
    : CerbGlobal.Switches :=
  ⟨[]⟩'
    plant "L1c production value in speclab/SpecLab" S3:speclab/SpecLab/DivModHarness.lean speclab/SpecLab/DivModHarness.lean 'def plantSw8 : CerbGlobal.Switches := ⟨[]⟩'
    plant "S6 untyped instance of a (D4-allowed) test value" S6:test/Unit/TotalityProofTest.lean test/Unit/OpaqueFailureTest.lean 'def plantV : CerbGlobal.Switches := ⟨[]⟩' test/Unit/TotalityProofTest.lean 'instance := plantV'
    plant "S2 attribute on a test value from a file without the token" S2:test/Unit/AreCompatibleTest.lean test/Unit/OpaqueFailureTest.lean 'def plantV2 : CerbGlobal.Switches := ⟨[]⟩' test/Unit/AreCompatibleTest.lean 'attribute [local instance] plantV2'
    plant "S7 ascription-typed untyped instance" S7:CerbND.lean CerbND.lean 'instance := (⟨[]⟩ : CerbGlobal.Switches)'
    plant "S7 name literal in a macro body" S7:CerbND.lean CerbND.lean '#eval ``CerbGlobal.Switches'
    plant "S7 the token in a string" S7:test/Unit/OpaqueFailureTest.lean test/Unit/OpaqueFailureTest.lean '#eval IO.println "CerbGlobal.Switches"'
    plant "S7 a second class Switches outside CerbGlobal.lean (W4 is CerbGlobal-only)" S7:CerbND.lean CerbND.lean 'class Switches where
  switches : List Nat'
    mk; local out rc; out=$(gate "$work/r"); rc=$?
    if [[ $rc -eq 0 ]]; then echo "  CONTROL OK [unplanted scratch copy] -> $out"; else echo "  CONTROL FAIL [unplanted scratch copy] rc=$rc: $out"; fail=1; fi
    # P8b — the consumer direction (scoping rule), a REAL test on a scratch copy:
    #  (i) a consumer-style Lake package with its own instance under the copy's .tmp/ (outside
    #      every root) leaves the copy GREEN;
    # (ii) the gate's root and file list excludes that package (asserted, not assumed);
    #(iii) the SAME file placed under a scanned root is RED (S1) — so (i) is not vacuous.
    mk
    local cons="$work/r/.tmp/consumer-plant"; mkdir -p "$cons"
    printf '%s\n' 'name = "consumerPlant"' '[[require]]' 'name = "CerberusLean"' 'path = "../../lean_frontend"' '[[lean_lib]]' 'name = "ConsumerPlant"' > "$cons/lakefile.toml"
    printf '%s\n' 'import CerbGlobal' 'instance : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩' 'example : CerbGlobal.has_switch .strict_reads = false := rfl' > "$cons/ConsumerPlant.lean"
    local p8=1 lst; out=$(gate "$work/r"); rc=$?
    [[ $rc -eq 0 ]] || { p8=0; echo "  P8b (i) FAIL: the out-of-root consumer package turned the copy RED rc=$rc: $out"; }
    lst=$(SWITCHES_GATE_LIST=1 gate "$work/r")
    if ! grep -q '^ROOT ' <<< "$lst" || ! grep -q '^FILE ' <<< "$lst"; then p8=0; echo "  P8b (ii) FAIL: empty root/file list (vacuous)"; fi
    if grep -E '^(ROOT .* |FILE )\.tmp(/|$)' <<< "$lst" | grep -q .; then p8=0; echo "  P8b (ii) FAIL: the root/file list includes .tmp/: $(grep -E '\.tmp' <<< "$lst" | head -3)"; fi
    if grep -q 'consumer-plant' <<< "$lst"; then p8=0; echo "  P8b (ii) FAIL: the consumer package is in the scanned file list"; fi
    mkdir -p "$work/r/lean_frontend/test/ConsumerScoped"; cp "$cons/ConsumerPlant.lean" "$work/r/lean_frontend/test/ConsumerScoped/"
    local out3; out3=$(gate "$work/r"); rc=$?
    [[ $rc -eq 1 && "$out3" == *"S1 lean_frontend/test/ConsumerScoped/ConsumerPlant.lean"* ]] || { p8=0; echo "  P8b (iii) FAIL: the consumer file under a scanned root was not RED S1 rc=$rc: $out3"; }
    if [[ $p8 -eq 1 ]]; then
        echo "  PLANT OK   [P8b consumer direction] (i) out-of-root consumer package with its own instance: GREEN -> $out"
        echo "               (ii) root list excludes .tmp/: $(grep -c '^ROOT ' <<< "$lst") roots, $(grep -c '^FILE ' <<< "$lst") files, none under .tmp/"
        echo "               (iii) same file under lean_frontend/test/: RED -> $(echo "$out3" | grep -m1 '  S1 ')"
    else fail=1; fi
    rm -rf "$work"
    echo "  REVERTED (real tree):"
    gate "$ROOT" || fail=1
    if [[ $fail -ne 0 ]]; then echo "check_switches_instance: SELFTEST FAILED"; return 1; fi
    echo "check_switches_instance: SELFTEST OK ($nplant plants RED with their labels, unplanted control GREEN, consumer-direction plant P8b (i)-(iii) OK, real tree GREEN)"
}

case "${1:-}" in
    "") gate "$ROOT" ;;
    --selftest) mkdir -p "$ROOT/.tmp"; selftest ;;
    *) echo "usage: $0 [--selftest]" >&2; exit 2 ;;
esac
