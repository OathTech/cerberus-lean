#!/usr/bin/env bash
# check_pin_sites.sh — every site that names the lem-lean pin must agree (fail-closed).
#
# Sites (all must equal scripts/fork_drift_manifest.txt's [meta] lem-pin, a full 40-hex commit):
#   lean_frontend/lakefile.toml                     [[require]] LemLib rev = "<hash>"
#   lean_frontend/lake-manifest.json                LemLib "rev" and "inputRev"
#   lean_frontend/speclab/lake-manifest.json        LemLib "rev" and "inputRev"
#   tests/mem-scale-probes/micro/lake-manifest.json LemLib "rev" and "inputRev"
#   lean_frontend/README.md                         every `lem-lean.git#<hash>` (the newcomer's opam pin command)
#
# Why (public-readiness M9 fresh-clone test, 2026-09-25): the sweep re-pinned the five machine-read sites but not the
# README's pin command, so a newcomer installed lem 67ec5de against a c2a68e79 pin and row 1's fork-drift gate went
# red. This leg makes the README a pin site the gate reads.
#
# Usage: scripts/check_pin_sites.sh [--root DIR]     (default: the repository root above this script)
#        scripts/check_pin_sites.sh --selftest        (plants on scratch copies; nothing in the tree is touched)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DEFAULT="$(cd "$HERE/.." && pwd)"

check() {  # <root> -> 0 OK / 1 FAIL (messages on stdout/stderr)
    local root="$1" pin rc=0 f
    local manifest="$root/scripts/fork_drift_manifest.txt"
    [[ -f "$manifest" ]] || { echo "check_pin_sites: FAIL — manifest missing: $manifest" >&2; return 1; }
    pin=$(awk '/^\[meta\]/{s=1;next} /^\[/{s=0} s && /^lem-pin=/{sub(/^lem-pin=/,""); print}' "$manifest")
    [[ "$pin" =~ ^[0-9a-f]{40}$ ]] || { echo "check_pin_sites: FAIL — manifest [meta] lem-pin is not one full 40-hex commit: '$pin'" >&2; return 1; }
    # lakefile.toml: the LemLib require's rev
    f="$root/lean_frontend/lakefile.toml"
    local lakerev
    lakerev=$(awk '/^\[\[require\]\]/{r=1} r && /^name = "LemLib"/{n=1} r && n && /^rev = "/{gsub(/^rev = "|"$/,""); print; exit}' "$f" 2>&1)
    [[ -n "$lakerev" ]] || { echo "check_pin_sites: FAIL — no LemLib rev found in $f" >&2; rc=1; }
    [[ -z "$lakerev" || "$lakerev" == "$pin" ]] || { echo "check_pin_sites: FAIL — $f LemLib rev = $lakerev ≠ lem-pin $pin" >&2; rc=1; }
    # the three lake-manifests: LemLib rev + inputRev
    for f in lean_frontend/lake-manifest.json lean_frontend/speclab/lake-manifest.json tests/mem-scale-probes/micro/lake-manifest.json; do
        [[ -f "$root/$f" ]] || { echo "check_pin_sites: FAIL — missing $f" >&2; rc=1; continue; }
        local revs
        revs=$(python3 - "$root/$f" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for p in m.get("packages",[]):
    if p.get("name")=="LemLib":
        print(p.get("rev","<none>")); print(p.get("inputRev","<none>"))
PY
)
        [[ -n "$revs" ]] || { echo "check_pin_sites: FAIL — no LemLib package in $f" >&2; rc=1; continue; }
        while read -r r; do
            [[ "$r" == "$pin" ]] || { echo "check_pin_sites: FAIL — $f LemLib rev/inputRev = $r ≠ lem-pin $pin" >&2; rc=1; }
        done <<<"$revs"
    done
    # README: every opam pin command's hash
    f="$root/lean_frontend/README.md"
    local readme_hashes
    readme_hashes=$(grep -o 'lem-lean\.git#[0-9a-f]*' "$f" | sed 's/.*#//' | sort -u)
    [[ -n "$readme_hashes" ]] || { echo "check_pin_sites: FAIL — $f has no 'lem-lean.git#<hash>' pin command" >&2; rc=1; }
    while read -r h; do
        [[ -z "$h" ]] && continue
        [[ "$h" == "$pin" ]] || { echo "check_pin_sites: FAIL — $f pins lem-lean.git#$h ≠ lem-pin $pin (the README's own rule: equal to lean_frontend/lakefile.toml)" >&2; rc=1; }
    done <<<"$readme_hashes"
    (( rc == 0 )) && echo "check_pin_sites: OK — lem-pin $pin at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)"
    return $rc
}

if [[ "${1:-}" == "--selftest" ]]; then
    echo "check_pin_sites: SELFTEST — plants on scratch copies (loud plant banner; nothing in the tree is touched)"
    S=$(mktemp -d); trap 'rm -rf "$S"' EXIT
    fails=0
    mk() {  # <dst-root>: copy the five pin-site files + manifest
        mkdir -p "$1/scripts" "$1/lean_frontend/speclab" "$1/tests/mem-scale-probes/micro"
        cp "$ROOT_DEFAULT/scripts/fork_drift_manifest.txt" "$1/scripts/"
        cp "$ROOT_DEFAULT/lean_frontend/lakefile.toml" "$ROOT_DEFAULT/lean_frontend/lake-manifest.json" "$ROOT_DEFAULT/lean_frontend/README.md" "$1/lean_frontend/"
        cp "$ROOT_DEFAULT/lean_frontend/speclab/lake-manifest.json" "$1/lean_frontend/speclab/"
        cp "$ROOT_DEFAULT/tests/mem-scale-probes/micro/lake-manifest.json" "$1/tests/mem-scale-probes/micro/"
    }
    plant() {  # <label> <want: 0|nonzero> <substring> <root>
        local out rc ok=1
        out=$(check "$4" 2>&1); rc=$?
        if [[ "$2" == 0 ]]; then (( rc == 0 )) || ok=0; else (( rc != 0 )) || ok=0; fi
        grep -qF -- "$3" <<<"$out" || ok=0
        if (( ok )); then echo "  PLANT OK   [$1] rc=$rc -> $(grep -m1 -F -- "$3" <<<"$out" | cut -c1-160)"
        else echo "  PLANT FAIL [$1]: rc=$rc (wanted $2), message '$3' $(grep -qF -- "$3" <<<"$out" && echo present || echo ABSENT):"; sed 's/^/      /' <<<"$out"; fails=$((fails+1)); fi
    }
    pin=$(awk '/^\[meta\]/{s=1;next} /^\[/{s=0} s && /^lem-pin=/{sub(/^lem-pin=/,""); print}' "$ROOT_DEFAULT/scripts/fork_drift_manifest.txt")
    stale="67ec5de70e02e280bb348a4ba826696b76116732"; [[ "$stale" == "$pin" ]] && stale="0000000000000000000000000000000000000000"
    mk "$S/ok";       plant "P0 unplanted copies" 0 "check_pin_sites: OK" "$S/ok"
    mk "$S/readme";   sed -i "s/lem-lean\.git#$pin/lem-lean.git#$stale/" "$S/readme/lean_frontend/README.md"
                      plant "P1 README pin command names another commit (the 2026-09-25 fresh-clone defect)" nonzero "README.md pins lem-lean.git#$stale" "$S/readme"
    mk "$S/lakefile"; sed -i "s/^rev = \"$pin\"/rev = \"$stale\"/" "$S/lakefile/lean_frontend/lakefile.toml"
                      plant "P2 lakefile LemLib rev differs" nonzero "lakefile.toml LemLib rev = $stale" "$S/lakefile"
    mk "$S/manifest"; sed -i "0,/\"inputRev\": \"$pin\"/s//\"inputRev\": \"$stale\"/" "$S/manifest/lean_frontend/speclab/lake-manifest.json"
                      plant "P3 one lake-manifest inputRev differs" nonzero "speclab/lake-manifest.json LemLib rev/inputRev = $stale" "$S/manifest"
    mk "$S/nopin";    sed -i '/^lem-pin=/d' "$S/nopin/scripts/fork_drift_manifest.txt"
                      plant "P4 manifest lem-pin missing" nonzero "lem-pin is not one full 40-hex commit" "$S/nopin"
    mk "$S/noreadme"; sed -i 's/lem-lean\.git#[0-9a-f]*/lem-lean.git/' "$S/noreadme/lean_frontend/README.md"
                      plant "P5 README has no pin command at all" nonzero "has no 'lem-lean.git#<hash>' pin command" "$S/noreadme"
    if (( fails == 0 )); then echo "check_pin_sites: SELFTEST OK (5 plants red with the declared message, unplanted copies green)"; exit 0
    else echo "check_pin_sites: SELFTEST FAILED ($fails)"; exit 1; fi
fi
ROOT="$ROOT_DEFAULT"
if [[ "${1:-}" == "--root" ]]; then ROOT="$(cd "$2" && pwd)"; fi
check "$ROOT"
