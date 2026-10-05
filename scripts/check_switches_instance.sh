#!/usr/bin/env bash
# check_switches_instance.sh — GATE: no hidden default switch set (PNVI arc S1, 2026-10-05;
# design lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §B.3 + §D.2 P5/P8; record
# lean_frontend/docs/2026-10-05_pnvi-s1-switch-parameter-record.md §4).
#
# THE PROPERTY: the switch set is the instance-implicit parameter `[CerbGlobal.Switches]`
# (the `[LemFuel]` shape). It must never be supplied by an INSTANCE DECLARATION inside this
# repository — a global instance would be a hidden default that every lifted definition
# silently resolves to, so a theorem that "quantifies over the switch set" would in fact be
# about that one value. The entry point supplies the run's instance once: Main.lean's
#     let code ← (letI : LemFuel := ⟨fuel⟩; letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩; runPipeline …
#
# SCOPE — THIS REPOSITORY ONLY (consumer statement §1.5 item 2, adopted [AGENT] in design §B.3):
#   lean_frontend/*.lean (the seams, Main.lean included), lean_frontend/generated/*.lean,
#   lean_frontend/test/**, lean_frontend/speclab/** and tests/**/*.lean (.lake trees excluded),
#   plus the LemLib copy the build consumes (lean_frontend/.lake/packages/LemLib/lean-lib).
#   A CONSUMER's tree is never scanned: a consumer declaring its own instance (cerberus-sl: one,
#   at `defaultSwitches`, in one layer module) is the intended way to state default-mode facts
#   by `rfl`. The selftest's P8b plant checks that direction: a consumer-style Lake package in
#   the repository's scratch `.tmp/` that declares an instance leaves the gate GREEN.
#
# Forbidden (comment-stripped text):
#   S1  an `instance` declaration (any modifiers/name/priority/binders) whose head names
#       `Switches` — `instance : CerbGlobal.Switches := …`, `scoped instance foo : Switches where …`
#   S2  an instance ATTRIBUTE (`@[… instance …]`, `attribute [… instance …]`) in a file that
#       mentions `Switches` (none exists today; any is RED until reviewed)
#   S3  in PRODUCTION text (seams, generated, speclab/SpecLab — not the tests): a local
#       instance or named value of the class — `letI`/`haveI`/`let`/`have`/`def`/`abbrev`
#       `… : (CerbGlobal.)Switches :=` — except Main.lean's allowlisted line above. Tests MAY
#       build an explicit value (`letI : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩`
#       in a test's entry, `@f ⟨n⟩ sw₀`): that is a visible choice at the use, the way the
#       tests choose their fuel, not a default anything resolves to.
# Vacuity guards: ≥ MIN_FILES files scanned; the class `class Switches` present in
#   CerbGlobal.lean; Main.lean's allowlisted line present (hand-written AND generated copy);
#   ≥ one `[CerbGlobal.Switches]` binder in the generated tree; the LemLib copy present.
#
# --selftest: plants on scratch COPIES of the scan set (an instance in a seam, in generated/,
#   in test/, in speclab/; an attribute; a production letI) — each must be RED with its label;
#   the unplanted copy must be GREEN; then P8b (the consumer direction) on the real tree; then
#   the real tree. Nothing in the tree is touched (P8b's scratch package is created under
#   .tmp/ and deleted).
set -uo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIN_FILES=150

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
prod = sorted(glob.glob(os.path.join(lf, '*.lean')) + glob.glob(os.path.join(lf, 'generated', '*.lean'))
              + tree(os.path.join(lf, 'speclab', 'SpecLab')))
tests = sorted(tree(os.path.join(lf, 'test')) + tree(os.path.join(lf, 'speclab', 'test'))
               + tree(os.path.join(root, 'tests')))
speclab_top = sorted(glob.glob(os.path.join(lf, 'speclab', '*.lean')))
prod += speclab_top
lemlib_dir = os.path.join(lf, '.lake', 'packages', 'LemLib', 'lean-lib')
lemlib = sorted(tree(lemlib_dir)) if os.path.isdir(lemlib_dir) else []
fail = []
if not lemlib:
    fail.append(f"vacuous: the LemLib copy {os.path.relpath(lemlib_dir, root)} is absent (build lean_frontend first)")
files = prod + tests + lemlib
if len(files) < MIN_FILES:
    fail.append(f"vacuous: only {len(files)} files to scan (< {MIN_FILES}) — regenerate lean_frontend/generated first")
rel = lambda p: os.path.relpath(p, root)
INST = re.compile(r"(?<![\w.'])instance(?![\w'])")
ATTR = re.compile(r"@\[[^\]]*(?<![\w.'])instance(?![\w'])[^\]]*\]|attribute\s*\[[^\]]*(?<![\w.'])instance(?![\w'])[^\]]*\]")
SW = re.compile(r"(?<![\w'])Switches(?![\w'])")
LOCAL = re.compile(r"(?<![\w'])(letI|haveI|let|have|def|abbrev|theorem|opaque)\b[^\n]*?:\s*(CerbGlobal\.)?Switches\s*:=")
binders = 0; allow_seen = []
for f in files:
    try:
        t = strip_comments(open(f, encoding='utf-8').read())
    except ValueError as e:
        fail.append(f"{rel(f)}: comment stripper: {e} (fail-closed)"); continue
    line = lambda k: t.count('\n', 0, k) + 1
    for m in INST.finditer(t):
        # the declaration head: up to a `:=` or `where` OUTSIDE brackets (so
        # `(priority := low)` does not end it), or a blank line (max 400 chars)
        rest = t[m.end():m.end() + 400]
        cut, depth, k = len(rest), 0, 0
        while k < len(rest):
            c = rest[k]
            if c in '([{⟨': depth += 1
            elif c in ')]}⟩': depth = max(0, depth - 1)
            elif depth == 0 and (rest.startswith(':=', k) or rest.startswith('\n\n', k)
                                 or re.match(r"(?<![\w'])where(?![\w'])", rest[k:]) and (k == 0 or not (rest[k-1].isalnum() or rest[k-1] in "_'"))):
                cut = k; break
            k += 1
        if SW.search(rest[:cut]):
            fail.append(f"S1 {rel(f)}:{line(m.start())}: an instance declaration of the switch-set class (a hidden default)")
    if SW.search(t):
        for m in ATTR.finditer(t):
            fail.append(f"S2 {rel(f)}:{line(m.start())}: an instance attribute in a file that names Switches")
    if f in prod:
        for m in LOCAL.finditer(t):
            ln = t[t.rfind('\n', 0, m.start()) + 1: t.find('\n', m.start())].strip()
            if os.path.basename(f) == 'Main.lean' and ln == ALLOW:
                allow_seen.append(rel(f)); continue
            fail.append(f"S3 {rel(f)}:{line(m.start())}: a production value/local instance of the switch-set class outside Main.lean's entry: {ln[:120]}")
    if f.startswith(os.path.join(lf, 'generated') + os.sep):
        binders += t.count('[CerbGlobal.Switches]')
cg = os.path.join(lf, 'CerbGlobal.lean')
if not (os.path.isfile(cg) and re.search(r'^class Switches where', open(cg).read(), re.M)):
    fail.append("vacuous: `class Switches where` not found in lean_frontend/CerbGlobal.lean")
want = {'lean_frontend/Main.lean', 'lean_frontend/generated/Main.lean'}
if set(allow_seen) != want:
    fail.append(f"vacuous: Main.lean's allowlisted entry instance seen in {sorted(set(allow_seen))}, expected {sorted(want)}")
if binders < 1:
    fail.append("vacuous: no `[CerbGlobal.Switches]` binder in lean_frontend/generated (the lifting is absent?)")
if fail:
    print("check_switches_instance: FAIL"); [print("  " + x) for x in fail[:40]]; sys.exit(1)
print(f"check_switches_instance: OK ({len(files)} files scanned: {len(prod)} production, {len(tests)} test, {len(lemlib)} LemLib; "
      f"no instance of CerbGlobal.Switches; the one entry instance is Main.lean's letI; {binders} generated [CerbGlobal.Switches] binders)")
PY
}

selftest() {
    echo "check_switches_instance: SELFTEST — planting on scratch copies (loud plant banner; nothing in the tree is touched)"
    local work fail=0
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
    plant() {  # <label> <expected tag> <file relative to lean_frontend> <text>
        mk; printf '\n%s\n' "$4" >> "$work/r/lean_frontend/$3"
        local out rc; out=$(gate "$work/r"); rc=$?
        if [[ $rc -eq 1 && "$out" == *"$2 lean_frontend/$3"* ]]; then
            echo "  PLANT OK   [$1] -> $(echo "$out" | grep -m1 "$2 ")"
        else
            echo "  PLANT FAIL [$1] rc=$rc: $out"; fail=1
        fi
    }
    plant "P5/P8a instance in a seam" S1 CerbND.lean 'instance : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩'
    plant "P8a instance in generated/" S1 generated/Driver.lean 'instance (priority := low) plantSw : CerbGlobal.Switches where switches := []'
    plant "P8a instance in test/" S1 test/Unit/OpaqueFailureTest.lean 'instance : Switches := ⟨[]⟩'
    plant "P8a instance in speclab/" S1 speclab/test/SLUnit/CoreGateTest.lean 'scoped instance plantSw2 :
    CerbGlobal.Switches := ⟨[]⟩'
    plant "S2 instance attribute" S2 CerbMem.lean '@[instance] def plantSw3 : CerbGlobal.Switches := ⟨[]⟩'
    plant "S3 production letI outside Main" S3 CerbCall.lean 'def plantSw4 := (letI : CerbGlobal.Switches := ⟨[]⟩; (0 : Nat))'
    plant "S3 production named default" S3 generated/Translation.lean 'def plantSw5 : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩'
    mk; local out rc; out=$(gate "$work/r"); rc=$?
    if [[ $rc -eq 0 ]]; then echo "  CONTROL OK [unplanted scratch copy] -> $out"; else echo "  CONTROL FAIL [unplanted scratch copy] rc=$rc: $out"; fail=1; fi
    # P8b — the consumer direction: a consumer-style Lake package (path dependency on
    # lean_frontend, its own instance) in the repository's scratch .tmp/ is NOT scanned.
    local cons; cons=$(mktemp -d "$ROOT/.tmp/consumer-plant.XXXXXX")
    printf '%s\n' 'name = "consumerPlant"' '[[require]]' 'name = "CerberusLean"' 'path = "../../lean_frontend"' '[[lean_lib]]' 'name = "ConsumerPlant"' > "$cons/lakefile.toml"
    printf '%s\n' 'import CerbGlobal' 'instance : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩' 'example : CerbGlobal.has_switch .strict_reads = false := rfl' > "$cons/ConsumerPlant.lean"
    out=$(gate "$ROOT"); rc=$?
    rm -rf "$cons"
    if [[ $rc -eq 0 ]]; then echo "  PLANT OK   [P8b consumer-style package with its own instance under .tmp/: not scanned, gate GREEN] -> $out"
    else echo "  PLANT FAIL [P8b consumer direction] rc=$rc: $out"; fail=1; fi
    rm -rf "$work"
    echo "  REVERTED (real tree):"
    gate "$ROOT" || fail=1
    if [[ $fail -ne 0 ]]; then echo "check_switches_instance: SELFTEST FAILED"; return 1; fi
    echo "check_switches_instance: SELFTEST OK (7 plants RED with their labels, unplanted control GREEN, consumer-direction plant GREEN, real tree GREEN)"
}

case "${1:-}" in
    "") gate "$ROOT" ;;
    --selftest) mkdir -p "$ROOT/.tmp"; selftest ;;
    *) echo "usage: $0 [--selftest]" >&2; exit 2 ;;
esac
