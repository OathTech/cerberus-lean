#!/usr/bin/env bash
# check_external_pin.sh — an external corpus checkout must be at its pinned commit (fail-closed).
#
# The ladder's lanes read three corpora that are not in this repository (the CN test suite,
# libxml2, the pKVM buddy-allocator case study). Until 2026-11-24 nothing recorded which
# revision a lane's baseline was taken against: the CN lane compared file NAMES with its
# manifest, and a checkout at another revision passed whenever the verdicts happened to agree.
# The revisions are now scripts/external_pins.txt, and each lane calls this on the directory
# it is about to read.
#
#   check_external_pin.sh <name> <dir>   exit 0 iff <dir> is inside a git checkout whose HEAD
#                                        is the commit pinned for <name> and which has no
#                                        modified, added or deleted tracked file
#   check_external_pin.sh --selftest     plants on scratch repositories
#
# Any other state exits 1 with the reason: an unknown name, a malformed or duplicated pin, a
# directory that is not a git checkout (a tarball cannot be verified), another commit, local
# modifications, files hidden from git status. Untracked files are ignored (build output of the
# corpus itself), so an untracked file on a lane's include path is NOT seen by this check.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The pins file is fixed. No environment variable selects another one: the selftest passes its
# scratch pins through the internal --selftest-check form below, which real lanes never use.
PINS="$SCRIPT_DIR/external_pins.txt"
fail() { echo "check_external_pin: FAIL — $*" >&2; exit 1; }

check() {
    local name="$1" dir="$2" rows pin head dirty own theirs hidden listed
    [[ -f "$PINS" ]] || fail "pins file $PINS missing"
    rows=$(awk -v n="$name" '!/^[[:space:]]*(#|$)/ && $1 == n' "$PINS")
    [[ -n "$rows" ]] || fail "no pin named '$name' in $PINS"
    [[ $(printf '%s\n' "$rows" | wc -l) -eq 1 ]] || fail "more than one pin named '$name' in $PINS"
    pin=$(printf '%s\n' "$rows" | awk '{print $2}')
    [[ "$pin" =~ ^[0-9a-f]{40}$ ]] || fail "the pin for '$name' is not a full 40-hex commit: '$pin'"
    [[ -d "$dir" ]] || fail "$name: $dir is not a directory"
    head=$(git -C "$dir" rev-parse --verify -q 'HEAD^{commit}' 2>/dev/null) \
        || fail "$name: $dir is not inside a git checkout, so its revision cannot be verified (pin $pin)"
    # A plain directory under this repository (an unpacked tarball in deps/) resolves to THIS
    # repository's checkout; its HEAD says nothing about the corpus.
    own=$(cd "$SCRIPT_DIR" && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || own=""
    theirs=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || theirs=""
    [[ -n "$theirs" && "$theirs" != "$own" ]] \
        || fail "$name: $dir is not its own git checkout (it resolves to this repository), so its revision cannot be verified (pin $pin)"
    [[ "$head" == "$pin" ]] \
        || fail "$name: $dir is at $head, the pin is $pin ($PINS). Check out the pinned commit, or move the pin together with the baseline"
    dirty=$(git -C "$dir" status --porcelain --untracked-files=no 2>&1) \
        || fail "$name: git status failed in $dir: $dirty"
    [[ -z "$dirty" ]] || fail "$name: $dir has local modifications to tracked files at the pinned commit:
$dirty"
    # assume-unchanged / skip-worktree files are hidden from `git status`: refuse them.
    # Listed from the TOP of the checkout, like the status check above (a lane may pass a
    # subdirectory), and with git's own exit status checked before anything is filtered.
    listed=$(git -C "$dir" ls-files -v --full-name -- ':/' 2>&1) \
        || fail "$name: git ls-files failed in $dir: $listed"
    hidden=$(grep -E '^([a-z]|S) ' <<<"$listed" || true)
    [[ -z "$hidden" ]] || fail "$name: $dir has tracked files flagged assume-unchanged or skip-worktree, which git status cannot vouch for:
$hidden"
    echo "check_external_pin: OK — $name at $pin ($dir)"
}

selftest() {
    # Always under this repository, whatever TMPDIR says: plant S7 needs a plain directory INSIDE
    # this checkout (the case it guards), and S7b walls the same directory off with a ceiling.
    local base="$SCRIPT_DIR/../.tmp" rc=0 c out
    mkdir -p "$base" || fail "cannot create $base"
    S=$(mktemp -d "$base/external-pin-selftest.XXXXXXXXXX") || fail "mktemp failed"
    trap 'rm -rf "$S"' EXIT
    git init -q "$S/repo" && printf 'int x;\n' > "$S/repo/a.c" && mkdir "$S/repo/sub" && printf 'y\n' > "$S/repo/sub/b.c" \
        && git -C "$S/repo" add -A \
        && git -C "$S/repo" -c user.name=selftest -c user.email=selftest@example.invalid commit -q -m one \
        || fail "selftest: cannot build the scratch repository"
    c=$(git -C "$S/repo" rev-parse HEAD)
    mkdir "$S/plain" && printf 'int x;\n' > "$S/plain/a.c"
    plant() {  # <label> <expected rc> <expected substring> <pins text> <name> <dir>
        printf '%s' "$4" > "$S/pins.txt"
        out=$("${BASH_SOURCE[0]}" --selftest-check "$S/pins.txt" "$5" "$6" 2>&1); local got=$?
        if [[ $got -eq $2 && "$out" == *"$3"* ]]; then echo "  PLANT OK   [$1] rc=$got"
        else echo "  PLANT FAIL [$1] rc=$got (wanted $2 and '$3'): $out"; rc=1; fi
    }
    echo "check_external_pin: SELFTEST — scratch repositories under $S (nothing in the tree is touched)"
    plant "S1 at the pin" 0 "OK — t at $c" "t $c u"$'\n' t "$S/repo"
    plant "S2 a subdirectory of a checkout at the pin" 0 "OK — t at $c" "t $c u"$'\n' t "$S/repo/sub"
    plant "S3 another commit" 1 "the pin is 0000000000000000000000000000000000000000" "t 0000000000000000000000000000000000000000 u"$'\n' t "$S/repo"
    plant "S4 unknown name" 1 "no pin named 'other'" "t $c u"$'\n' other "$S/repo"
    plant "S5 abbreviated pin" 1 "not a full 40-hex commit" "t ${c:0:12} u"$'\n' t "$S/repo"
    plant "S6 duplicated pin" 1 "more than one pin named 't'" "t $c u"$'\n'"t $c u"$'\n' t "$S/repo"
    plant "S7 a plain directory under this repository" 1 "is not its own git checkout" "t $c u"$'\n' t "$S/plain"
    out=$(printf 't %s u\n' "$c" > "$S/pins.txt"; GIT_CEILING_DIRECTORIES="$S" "${BASH_SOURCE[0]}" --selftest-check "$S/pins.txt" t "$S/plain" 2>&1); local got=$?
    if [[ $got -eq 1 && "$out" == *"is not inside a git checkout"* ]]; then echo "  PLANT OK   [S7b a plain directory outside any repository] rc=$got"
    else echo "  PLANT FAIL [S7b] rc=$got: $out"; rc=1; fi
    plant "S8 missing directory" 1 "is not a directory" "t $c u"$'\n' t "$S/nowhere"
    printf 'int x = 1;\n' > "$S/repo/a.c"
    plant "S9 a tracked file modified at the pin" 1 "local modifications to tracked files" "t $c u"$'\n' t "$S/repo/sub"
    git -C "$S/repo" checkout -q -- a.c && git -C "$S/repo" update-index --assume-unchanged a.c
    plant "S11 a tracked file flagged assume-unchanged" 1 "assume-unchanged or skip-worktree" "t $c u"$'\n' t "$S/repo"
    printf 'int x = 2;\n' > "$S/repo/a.c"
    plant "S12 a flagged and modified file at the root, checked from a subdirectory" 1 "assume-unchanged or skip-worktree" "t $c u"$'\n' t "$S/repo/sub"
    git -C "$S/repo" update-index --no-assume-unchanged a.c && git -C "$S/repo" checkout -q -- a.c && git -C "$S/repo" update-index --assume-unchanged a.c
    git -C "$S/repo" update-index --no-assume-unchanged a.c && printf 'z\n' > "$S/repo/untracked.o"
    plant "S10 an untracked file only" 0 "OK — t at $c" "t $c u"$'\n' t "$S/repo"
    [[ $rc -eq 0 ]] && echo "check_external_pin: SELFTEST OK (13 plants with the declared verdict and message)" \
        || echo "check_external_pin: SELFTEST FAILED"
    return $rc
}

case "${1:-}" in
    --selftest) [[ $# -eq 1 ]] || fail "usage: check_external_pin.sh --selftest"; selftest; exit $? ;;
    --selftest-check)  # internal: <pins file> <name> <dir>, refused unless the pins file is selftest scratch
        [[ $# -eq 4 && "$2" == */external-pin-selftest.*/pins.txt ]] || fail "--selftest-check is the selftest's internal form"
        PINS="$2"; check "$3" "$4" ;;
    ""|-*) fail "usage: check_external_pin.sh <name> <dir> | --selftest" ;;
    *) [[ $# -eq 2 ]] || fail "usage: check_external_pin.sh <name> <dir> | --selftest"; check "$1" "$2" ;;
esac
