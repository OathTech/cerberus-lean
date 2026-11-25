#!/usr/bin/env bash
# preflight.sh — is this checkout ready to run the test ladder? A REPORT, in seconds.
#
# The ladder (scripts/LADDER.md) needs things that are not in the repository: a local opam
# switch with the fork's Lem, external corpora at pinned commits, two builds of upstream
# Cerberus, both engines built from fresh generated trees, a delegated cgroup. Each lane
# fails closed without its prerequisite, but only when it is reached, which can be hours
# into a run. This script checks all of them up front and prints, for each one that is
# missing, the command that provides it (scripts/bootstrap.sh).
#
#   scripts/preflight.sh               everything Tier A + Tier B needs
#   scripts/preflight.sh --tier fast   Tier A only (leaves out the independent oracle)
#
# It reads and reports; it never builds, downloads, installs or changes a prerequisite, and it
# creates no file (git may refresh a corpus checkout's index while its status is read). It is NOT a gate and proves nothing about the semantics: a clean
# report means the lanes can start, not that they pass. Exit 0 iff nothing is MISSING.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2
TIER=full
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tier) [[ $# -ge 2 ]] || { echo "preflight: --tier needs a value (fast or full)" >&2; exit 2; }; TIER="$2"; shift 2 ;;
        --tier=*) TIER="${1#--tier=}"; shift ;;
        -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "preflight: unknown argument '$1' (see --help)" >&2; exit 2 ;;
    esac
done
[[ "$TIER" == fast || "$TIER" == full ]] || { echo "preflight: --tier must be fast or full" >&2; exit 2; }

missing=0; warned=0
ok()   { printf '  ok       %s\n' "$1"; }
miss() { printf '  MISSING  %s\n' "$1"; [[ -n "${2:-}" ]] && printf '           fix: %s\n' "$2"; missing=$((missing + 1)); }
warn() { printf '  warn     %s\n' "$1"; warned=$((warned + 1)); }
section() { printf '\n%s\n' "$1"; }
in_switch() { opam exec --switch="$ROOT" -- "$@"; }
# A corpus directory AS ITS LANE FINDS IT: the environment override, else deps/<rel> in this
# directory or the nearest ancestor that has it (the CN and libxml2 lanes) ...
find_dep() {  # <env override value> <relative path under deps/>
    if [[ -n "$1" ]]; then printf '%s\n' "$1"; return; fi
    local d="$ROOT"
    while [[ "$d" != / ]]; do
        [[ -d "$d/deps/$2" ]] && { printf '%s\n' "$d/deps/$2"; return; }
        d="$(dirname "$d")"
    done
}
# ... or, for the pKVM case study, under the nearest deps/ directory of ANY content
# (scripts/test_pnvi.sh stops at the first deps/ it meets, whether or not the corpus is in it).
find_dep_nearest_deps() {  # <env override value> <name under deps/>
    if [[ -n "$1" ]]; then printf '%s\n' "$1"; return; fi
    local d="$ROOT"
    while [[ "$d" != / ]]; do
        [[ -d "$d/deps" ]] && { printf '%s\n' "$d/deps/$2"; return; }
        d="$(dirname "$d")"
    done
}

echo "preflight: $ROOT at $(git rev-parse --short HEAD 2>/dev/null || echo '?') (tier: $TIER)"

section "Tools"
for t in git python3 opam make timeout setarch; do
    command -v "$t" > /dev/null 2>&1 && ok "$t" || miss "$t not on the path" "install $t"
done
[[ -x /usr/bin/time ]] && ok "/usr/bin/time (GNU time)" || miss "/usr/bin/time" "install GNU time"
if command -v setarch > /dev/null 2>&1; then
    setarch -R true 2>/dev/null && ok "setarch -R permitted (the gcc lanes disable address randomization)" \
        || miss "setarch -R is not permitted here" "run where the personality syscall is allowed"
fi
gcc_bin=$(command -v "${GCC_BIN:-gcc}" 2>/dev/null || true)
if [[ -n "$gcc_bin" ]]; then ok "gcc: $gcc_bin ($("$gcc_bin" -dumpfullversion 2>/dev/null || echo '?'))"
else miss "gcc (GCC_BIN='${GCC_BIN:-}', else gcc on the path)" "install gcc"; fi
want_lean=$(sed 's/.*://' lean_frontend/lean-toolchain 2>/dev/null)
if command -v lake > /dev/null 2>&1 && command -v elan > /dev/null 2>&1; then
    # `elan toolchain list`, not `elan which`: the latter may install a missing toolchain.
    toolchains=$(elan toolchain list 2>/dev/null)
    if [[ "$toolchains" =~ (^|[^0-9A-Za-z.])"$want_lean"([^0-9A-Za-z.-]|$) ]]; then ok "Lean toolchain $want_lean (elan)"
    else miss "Lean toolchain $want_lean is not installed" "elan toolchain install $(cat lean_frontend/lean-toolchain)"; fi
else miss "elan / lake not on the path" "install elan (https://lean-lang.org), then: elan toolchain install $(cat lean_frontend/lean-toolchain)"; fi

section "OCaml switch"
lem_pin=$(sed -n 's/^lem-pin=//p' scripts/fork_drift_manifest.txt | head -1)
if [[ -d _opam ]]; then
    ok "local switch ./_opam"
    for t in dune ocamlfind menhir; do
        in_switch sh -c "command -v $t" > /dev/null 2>&1 && ok "$t in the switch" \
            || miss "$t is not in the switch" "scripts/bootstrap.sh switch"
    done
    lem_v=$(in_switch lem -v 2>/dev/null | head -1)
    lem_hex=$(sed -n 's/.*-g\([0-9a-f]\{7,40\}\)$/\1/p' <<<"$lem_v")
    if [[ -z "$lem_v" ]]; then miss "lem is not in the switch" "scripts/bootstrap.sh switch"
    elif [[ -n "$lem_hex" && -n "$lem_pin" && "$lem_pin" == "$lem_hex"* ]]; then ok "lem at the pin ($lem_v)"
    else miss "lem is '$lem_v', the pin is $lem_pin (scripts/fork_drift_manifest.txt)" "scripts/bootstrap.sh switch"; fi
else
    miss "no local opam switch at ./_opam" "scripts/bootstrap.sh switch"
fi

section "Containment (scripts/release.py runs each lane in its own cgroup)"
cg=$(sed -n 's/^0:://p' /proc/self/cgroup 2>/dev/null)
if [[ -z "$cg" || "$cg" == / ]]; then
    miss "not inside a delegated cgroup v2 hierarchy" "run from a systemd user session, e.g. systemd-run --user --scope -p Delegate=yes -- <shell>"
else
    parent="/sys/fs/cgroup$(dirname "$cg")"
    if grep -qw memory "$parent/cgroup.subtree_control" 2>/dev/null && [[ -w "$parent" ]]; then
        ok "delegated cgroup parent with the memory controller ($parent)"
    else
        miss "the cgroup parent $parent is not writable or has no memory controller" "systemd-run --user --scope -p Delegate=yes -- <shell>"
    fi
fi

section "Upstream references (fork-drift gate, row A1)"
mb=$(sed -n 's/^merge-base=//p' scripts/fork_drift_manifest.txt | head -1)
if git rev-parse --verify -q upstream/master > /dev/null; then
    live=$(git merge-base upstream/master HEAD 2>/dev/null)
    [[ "$live" == "$mb" ]] && ok "upstream/master present; merge-base ${mb:0:12} as pinned" \
        || miss "merge-base with upstream/master is ${live:0:12}, the manifest pins ${mb:0:12}" "see scripts/check_fork_drift.sh (a deliberate refresh, not a setup step)"
else
    miss "no upstream/master ref" "scripts/bootstrap.sh sources   (needs the network)"
fi
default_tree="$ROOT/.validation-foundations/fork-drift-upstream/ocaml_frontend/generated"
if [[ -n "${CERB_UPSTREAM_TREE:-}" ]]; then
    # A directory is not enough: the generation recipe creates it before Lem runs.
    if [[ -d "$CERB_UPSTREAM_TREE" ]] && compgen -G "$CERB_UPSTREAM_TREE/*.ml" > /dev/null; then ok "CERB_UPSTREAM_TREE=$CERB_UPSTREAM_TREE"
    else miss "CERB_UPSTREAM_TREE=$CERB_UPSTREAM_TREE is not a generated OCaml tree (no .ml files)" "scripts/bootstrap.sh oracles"; fi
elif compgen -G "$default_tree/*.ml" > /dev/null; then
    miss "CERB_UPSTREAM_TREE is not set (the pristine generated tree exists)" "export CERB_UPSTREAM_TREE=$default_tree"
else
    miss "no pristine upstream generated tree" "scripts/bootstrap.sh oracles, then export CERB_UPSTREAM_TREE=$default_tree"
fi
if [[ "$TIER" == full ]]; then
    out=$(PYTHONDONTWRITEBYTECODE=1 python3 scripts/ensure_independent_oracle.py --no-build 2>&1 | tail -1)
    [[ "$out" == *"VALID standing build"* ]] && ok "independent upstream oracle (rows B10, B12)" \
        || miss "independent upstream oracle: ${out:-not standing}" "scripts/bootstrap.sh oracles"
fi

section "External corpora (pinned in scripts/external_pins.txt)"
corpus() {  # <pin name> <rows> <dir or empty> <bootstrap hint>
    if [[ -z "$3" || ! -d "$3" ]]; then miss "$1 corpus not found (rows $2)" "$4"; return; fi
    local out; out=$(scripts/check_external_pin.sh "$1" "$3" 2>&1)
    if [[ $? -eq 0 ]]; then ok "$1 at its pin: $3 (rows $2)"; else miss "$1 (rows $2): ${out#check_external_pin: FAIL — }" "$4"; fi
}
corpus cn "A11, B10" "$(find_dep "${CN_CORPUS_DIR:-}" cn/tests/cn)" "scripts/bootstrap.sh sources   (needs the network)"
corpus libxml2 "A10, B1, B12" "$(find_dep "${LIBXML2_DIR:-}" libxml2)" "scripts/bootstrap.sh sources   (needs the network)"
corpus pkvm "A14" "$(find_dep_nearest_deps "${PKVM_CASE_STUDY:-}" CN-pKVM-buddy-allocator-case-study)" "scripts/bootstrap.sh sources   (needs the network)"

section "Build state"
have() { [[ -e "$1" ]] && ok "$2" || miss "$2 ($1)" "$3"; }
if tools/check_lem_sync.sh --check > /dev/null 2>&1; then ok "generated OCaml tree in sync with the .lem sources"
else miss "generated OCaml tree missing or stale" "scripts/bootstrap.sh build"; fi
if tools/check_lem_sync.sh --check-lean > /dev/null 2>&1; then ok "generated Lean tree in sync with the .lem sources"
else miss "generated Lean tree missing or stale" "scripts/bootstrap.sh build"; fi
if tools/check_handwritten_sync.sh > /dev/null 2>&1; then ok "hand-written Lean files copied into generated/"
else miss "hand-written Lean files differ from their generated/ copies" "opam exec --switch=. -- make lean-prelude-src"; fi
have _build/default/backend/driver/main.exe "OCaml oracle built" "scripts/bootstrap.sh build"
have _build/install/default/lib/cerberus-lib/runtime/libcore/std.core "runtime staged (std.core)" "scripts/bootstrap.sh build"
have _build/install/default/lib/cerberus/runtime/libc/libc.co "libc staged (libc.co)" "scripts/bootstrap.sh build"
have lean_frontend/.lake/packages/LemLib "LemLib Lake package" "scripts/bootstrap.sh build   (first fetch needs the network)"
have lean_frontend/.lake/build/bin/cerberus-lean "Lean driver built" "scripts/bootstrap.sh build"
have lean_frontend/speclab/.lake/build "speclab built" "scripts/bootstrap.sh build"
# The lanes rebuild what is stale; this only says whether binaries exist, not that they are fresh.

section "Environment"
set_vars=()
for v in TIMEOUT_SECS CERB_TEST_MEM_MAX CERB_TEST_FUEL GCC_RUN_TIMEOUT GCC_BIN SKIP_BUILD DUNE_CACHE \
         CERB_ORACLE_BIN_OVERRIDE CERB_LEAN_BIN_OVERRIDE CERB_DRIVER_FRESH_OVERRIDE CERB_FORK_DRIFT_DEV_SKIP; do
    [[ -n "${!v:-}" ]] && set_vars+=("$v=${!v}")
done
if [[ ${#set_vars[@]} -eq 0 ]]; then ok "no variable that changes lane outcomes is set"
else warn "set in this shell and read by the lanes (a run for landing evidence should state or unset them): ${set_vars[*]}"; fi
[[ -n "${CERB_MEM_MAX:-}" ]] && ok "CERB_MEM_MAX=$CERB_MEM_MAX" || warn "CERB_MEM_MAX is not set: scripts/capped defaults to 64G per capped command"

echo
if [[ $missing -eq 0 ]]; then
    echo "preflight: READY for tier $TIER ($warned warning(s)). Next: opam exec --switch=. -- ./scripts/ci_lean.sh$([[ $TIER == fast ]] && echo ' --mode fast')"
    exit 0
fi
echo "preflight: NOT READY — $missing prerequisite(s) missing, $warned warning(s). scripts/bootstrap.sh --help lists the setup steps."
exit 1
