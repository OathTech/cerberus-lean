#!/bin/bash
# check_fork_drift.sh — standing fork-drift gate (arc-10 audit follow-up,
# [USER] mandate; spec: lean_frontend/docs/2026-08-21_fork-drift-review.md §6;
# P0 instrument repair 2026-09-05: lean_frontend/docs/2026-09-05_p0-instruments-record.md
# §F4 — locale-fixed canonicalization, duplicate detection, fail-closed
# prerequisites, --selftest plants).
#
# THE POINT: every fork-side change that could affect the OCaml oracle
# must be a REVIEWED, MANIFESTED fact, never an accident. The F-D family
# (fork oracle corruption, arc-10 S4 root-cause) entered through exactly
# this surface under a commit message that wrongly claimed OCaml
# neutrality — this gate makes any future member of that class loud.
#
# Layer 1 (name-level, <1 s): the SET of files on `git diff upstream/master
#   --name-only` over the oracle surfaces must equal the SET named by the
#   committed manifest's [files] section (both canonicalized with
#   LC_ALL=C sort — the whole-project audit F4 found the gate passing under
#   en_US.UTF-8 and failing under LC_ALL=C because the manifest was in
#   locale collation order while the live list was byte-sorted; the
#   comparison is now ORDER-INSENSITIVE and locale-independent). A
#   duplicate manifest entry is a FAIL (a set with a repeated name is not a
#   reviewed set). Any new/removed file on the oracle surface fails loud
#   and forces a manifest update whose commit states the justification.
#   Also pins the merge-base: if upstream/master or the fork history moves
#   so the merge-base leaves the manifested commit, the gate fails (the
#   whole manifest is relative to it). upstream/master only LOCATES the
#   merge-base; every comparison is against the pinned merge-base commit,
#   so upstream advancing past it is not drift (2026-09-25). [meta] lem-pin records the lem-lean
#   commit BOTH generated trees were derived with; when `lem` is on PATH
#   its `lem -v` must agree (a stale pin was the audit's F4 finding (c)).
#
# Layer 2 (content-level, <1 s when both trees exist): diff of the
#   upstream-pristine generated-OCaml tree (deps/cerberus-upstream/
#   ocaml_frontend/generated, built at the merge-base with the pinned
#   lem) vs this repo's ocaml_frontend/generated (build output of
#   `make prelude-src`). Differing files must be exactly the manifest's
#   [expected-semantic] + [expected-cosmetic] entries, each with a
#   pinned sha256 of its unified diff — semantic drift INSIDE an
#   already-excused file flips the hash and is loud too. Cosmetic
#   entries were verified comment/blank-line-only at manifest time
#   (strip check in the refresh recipe); the hash pin subsumes the
#   check at gate time.
# Layer 3: [source-content] pins every layer-1 file's bytes and git-style
#   mode, including .lem sources, handwritten fresh supply/renumbering,
#   driver changes and build/runtime helpers. An edit inside an already
#   listed file fails. These pins supplement the reviewed historical deltas;
#   a checksum is not itself a semantic review or an independent oracle.
#
# PREREQUISITES ARE FAIL-CLOSED (P0 repair; was a loud rc-0 SKIP, which the
#   unit caller consumed as success — audit F4): a missing upstream ref, a
#   missing generated tree (either side) or a missing/malformed manifest is
#   rc 1. The ONLY way to run without the prerequisites is the explicit
#   development opt-in CERB_FORK_DRIFT_DEV_SKIP=1, which prints a LOUD
#   banner and exits 0 for the skipped layer(s); scripts/test_unit.sh
#   runs this gate with that variable explicitly UNSET (env -u), so the
#   opt-in cannot reach the unit gate from the ambient environment.
#
# Refresh recipe (pin move / deliberate model change / merge-base move —
# Tier B, deliberate commit with justification):
#   1. regenerate the fork tree: `opam exec --switch=. -- make prelude-src`
#   2. regenerate the upstream tree at the (new) merge-base with the SAME
#      pinned lem (see the review note §3/§6 — operator action; the tree
#      lives outside this repo)
#   3. set [meta] lem-pin to the reviewed full 40-hex commit, then run
#      ./scripts/check_fork_drift.sh --refresh   # preserves that full pin
#   4. review the manifest diff hunk-by-hunk (every new [files] entry and
#      every changed hash is a claim about the oracle), commit with the
#      justification in the message.
#
# --selftest: plants on scratch copies of the manifest and on fake
#   prerequisites (a manifest in en_US collation order under LC_ALL=C and
#   vice versa → OK; a reversed manifest → OK; one name changed → FAIL;
#   a duplicated name → FAIL; a missing upstream ref → FAIL; a missing
#   upstream tree → FAIL; the dev opt-in on a missing ref → rc 0 WITH the
#   banner; a stale/missing lem-pin → FAIL). Nothing in the tree is
#   touched; every expected verdict is checked by its message, not only
#   by rc.
#
# Env: CERB_UPSTREAM_TREE names the required upstream generated-tree path.
#      CERB_FORK_DRIFT_DEV_SKIP=1 — the development opt-in described above.

set -uo pipefail
# Every sort/comm/uniq below runs in the C locale: byte order, no collation
# surprises (audit F4). Exported so child processes inherit it too; gate()
# re-exports it so the production path is locale-fixed whatever the caller's
# environment.
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_DEFAULT="$ROOT/scripts/fork_drift_manifest.txt"
SURFACES=(frontend backend/common backend/driver backend/lean_export
          ocaml_frontend memory util parsers sibylfs runtime
          cerberus.opam cerberus-lib.opam Makefile dune dune-project
          tools/check_lem_sync.sh tools/check_driver_fresh.sh
          tools/check_handwritten_sync.sh tools/gen_version.ml scripts/common.sh)
FORK_TREE_DEFAULT="$ROOT/ocaml_frontend/generated"
UPSTREAM_REF_DEFAULT=upstream/master

MODE=gate
case "${1:-}" in
    "") ;;
    --refresh) MODE=refresh ;;
    --selftest) MODE=selftest ;;
    *) echo "check_fork_drift: usage: $0 [--refresh | --selftest]" >&2; exit 2 ;;
esac

# The independent generated tree is explicitly provisioned by the caller.
# See lean_frontend/VALIDATION.md, "Provisioning the fork-drift oracle".
resolve_upstream_tree() {
    printf '%s\n' "${CERB_UPSTREAM_TREE:-}"
}

# gate <manifest> <upstream-ref> <upstream-tree> <fork-tree> <lem-cmd> <refresh 0/1>
#   The whole gate; run in a subshell (it exits). <lem-cmd> is the command
#   whose `-v` output's 2nd word is the lem version (`lem` in production;
#   the selftest passes fakes); "" = not on PATH.
gate() {
    local MANIFEST="$1" UPSTREAM_REF="$2" UP_TREE="$3" FORK_TREE="$4" LEM_CMD="$5" REFRESH="$6"
    local CONTENT_ROOT="${7:-$ROOT}"
    local dev_skip="${CERB_FORK_DRIFT_DEV_SKIP:-}"
    export LC_ALL=C   # the gate's own sort/comm/uniq are byte-ordered whatever the caller's locale

    fail() { echo "check_fork_drift: FAIL — $*" >&2; exit 1; }
    dev_skip_banner() {  # <what>
        echo "##########################################################################" >&2
        echo "# check_fork_drift: DEV SKIP (CERB_FORK_DRIFT_DEV_SKIP=1 is set) — $1" >&2
        echo "# This is NOT a pass. The fork-drift gate did not run to completion. Unset" >&2
        echo "# CERB_FORK_DRIFT_DEV_SKIP and restore the prerequisite for a real verdict." >&2
        echo "##########################################################################" >&2
    }

    # --- upstream ref (repo-level remote; visible from worktrees) -----------
    if ! git -C "$ROOT" rev-parse --verify -q "$UPSTREAM_REF" >/dev/null; then
        echo "check_fork_drift: no '$UPSTREAM_REF' ref in this checkout." >&2
        echo "  The fork-drift gate needs an upstream ref fetched from the public repository:" >&2
        echo "    git remote add upstream https://github.com/rems-project/cerberus.git" >&2
        echo "    git fetch upstream master:refs/remotes/upstream/master" >&2
        if [[ "$dev_skip" == "1" ]]; then
            dev_skip_banner "missing upstream ref '$UPSTREAM_REF'; layers 1 and 2 NOT checked"
            exit 0
        fi
        fail "missing upstream ref '$UPSTREAM_REF' (fail-closed; the development opt-in is CERB_FORK_DRIFT_DEV_SKIP=1)"
    fi

    # --- manifest parsing ---------------------------------------------------
    [[ -f "$MANIFEST" ]] || fail "manifest missing: $MANIFEST (fail-closed)"
    section() {  # <name> -> the section's non-comment lines
        awk -v s="[$1]" '
            $0 == s { insec=1; next }
            /^\[/   { insec=0 }
            insec && !/^[[:space:]]*(#|$)/ { print }
        ' "$MANIFEST"
    }
    local pinned_mb live_mb pinned_lem live_lem live_prefix
    pinned_mb=$(section meta | sed -n 's/^merge-base=//p')
    [[ -n "$pinned_mb" ]] || fail "manifest has no [meta] merge-base= line"
    pinned_lem=$(section meta | sed -n 's/^lem-pin=//p')
    [[ -n "$pinned_lem" ]] || fail "manifest has no [meta] lem-pin= line (the lem-lean commit both generated trees were derived with)"
    [[ "$pinned_lem" =~ ^[0-9a-f]{40}$ ]] || fail "manifest [meta] lem-pin must be exactly one full 40-hex commit"

    live_mb=$(git -C "$ROOT" merge-base "$UPSTREAM_REF" HEAD) || fail "git merge-base failed"
    if [[ "$live_mb" != "$pinned_mb" ]]; then
        fail "merge-base moved: manifest pins $pinned_mb, live is $live_mb — $UPSTREAM_REF or the fork history changed; run the refresh recipe (deliberate commit) after re-review"
    fi

    # --- lem-pin cross-check (audit F4 (c)) ----------------------------------
    local lem_note
    if [[ -n "$LEM_CMD" ]]; then
        live_lem=$("$LEM_CMD" -v | awk '{print $2}') || fail "'$LEM_CMD -v' failed"
        [[ -n "$live_lem" ]] || fail "'$LEM_CMD -v' printed no version"
        # Closure F1 (2026-09-24; reviewed base 0a6d59eed): git describe's
        # abbreviation length depends on the clone. Accept a 7–40 hex prefix,
        # bare or in a hash-bearing tag-distance-gHASH form. A dirty suffix
        # does not identify a different commit; this is not a clean-tree check.
        live_prefix=${live_lem%-dirty}
        if [[ "$live_prefix" =~ ^[0-9a-f]{7,40}$ ]]; then
            :
        elif [[ "$live_prefix" =~ ^[^[:space:]]+-[0-9]+-g([0-9a-f]{7,40})$ ]]; then
            live_prefix=${BASH_REMATCH[1]}
        else
            fail "malformed lem version: '$live_lem' (need 7–40 hex digits or a hash-bearing git describe version)"
        fi
        if [[ "$pinned_lem" != "$live_prefix"* ]]; then
            fail "lem-pin stale: manifest records lem-pin=$pinned_lem, '$LEM_CMD -v' says $live_lem — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately"
        fi
        lem_note="lem-pin $pinned_lem matches lem -v $live_lem (hex prefix)"
    else
        lem_note="lem-pin $pinned_lem (lem not on PATH: not cross-checked)"
    fi

    # --- layer 1: name-level (SET comparison, C-locale canonical) -----------
    local live_files manifest_raw manifest_files dups
    # The comparison base is the PINNED merge-base (validated equal to the live one above), never the
    # upstream ref itself: upstream advancing past the merge-base is not fork drift (public-readiness M9
    # fresh-clone finding, 2026-09-25 — a newcomer's `git fetch upstream master` made 12 upstream-only
    # changes read as NEW DRIFT; the container's stale upstream/master had masked it).
    live_files=$( { git -C "$ROOT" diff "$live_mb" --name-only -- "${SURFACES[@]}";
                   git -C "$ROOT" ls-files --others --exclude-standard -- "${SURFACES[@]}"; } | sort -u)

    if [[ $REFRESH -eq 0 ]]; then
        manifest_raw=$(section files)
        dups=$(printf '%s\n' "$manifest_raw" | sort | uniq -d)
        if [[ -n "$dups" ]]; then
            echo "check_fork_drift: FAIL — duplicate [files] entries in the manifest (a set with a repeated name is not a reviewed set):" >&2
            printf '%s\n' "$dups" | sed 's/^/    /' >&2
            exit 1
        fi
        manifest_files=$(printf '%s\n' "$manifest_raw" | sort)
        if [[ "$live_files" != "$manifest_files" ]]; then
            echo "check_fork_drift: FAIL — oracle-surface file set drifted from the manifest." >&2
            echo "--- files on the live diff but not in the manifest (NEW DRIFT):" >&2
            comm -23 <(printf '%s\n' "$live_files") <(printf '%s\n' "$manifest_files") | sed 's/^/    /' >&2
            echo "--- files in the manifest but no longer on the live diff:" >&2
            comm -13 <(printf '%s\n' "$live_files") <(printf '%s\n' "$manifest_files") | sed 's/^/    /' >&2
            echo "Every entry is a reviewed claim about the oracle: re-review the change" >&2
            echo "against lean_frontend/docs/2026-08-21_fork-drift-review.md, then run the refresh recipe." >&2
            exit 1
        fi
    fi

    # The selftest can supply a scratch content root; the production gate
    # always checks this worktree's actual files. No ambient bypass exists.
    if [[ $REFRESH -eq 0 ]]; then
        printf '%s\n' "$live_files" | python3 "$ROOT/scripts/check_fork_content.py" \
            --root "$CONTENT_ROOT" --manifest "$MANIFEST" || fail "source-content check failed"
    fi

    # --- layer 2: generated-tree content -------------------------------------
    local layer2_missing=""
    [[ -n "$UP_TREE" && -d "$UP_TREE" ]] || layer2_missing="upstream pristine tree not found (set CERB_UPSTREAM_TREE; see lean_frontend/VALIDATION.md provisioning instructions)"
    [[ -d "$FORK_TREE" ]] || layer2_missing="fork generated tree missing: $FORK_TREE (run 'make prelude-src')"
    if [[ -n "$layer2_missing" ]]; then
        if [[ $REFRESH -eq 1 ]]; then fail "--refresh needs both generated trees: $layer2_missing"; fi
        echo "check_fork_drift: layer 1 OK ($(printf '%s\n' "$live_files" | wc -l) manifested oracle-surface files); layer 2 NOT CHECKED — $layer2_missing" >&2
        if [[ "$dev_skip" == "1" ]]; then
            dev_skip_banner "layer 2 skipped: $layer2_missing"
            exit 0
        fi
        fail "layer 2 prerequisite missing (fail-closed; the development opt-in is CERB_FORK_DRIFT_DEV_SKIP=1): $layer2_missing"
    fi

    diff_hash() {  # <basename> -> sha256 of the label-normalized unified diff
        diff -u --label "upstream/$1" --label "fork/$1" "$UP_TREE/$1" "$FORK_TREE/$1" \
            | sha256sum | awk '{print $1}'
    }

    # differing/extra files, basenames (fail on Only-in: tree shape must match)
    local raw live_diff_files
    raw=$(diff -rq "$UP_TREE" "$FORK_TREE" | sort)
    if grep -q '^Only in' <<<"$raw"; then
        echo "check_fork_drift: FAIL — generated trees differ in FILE SET:" >&2
        grep '^Only in' <<<"$raw" | sed 's/^/    /' >&2
        exit 1
    fi
    live_diff_files=$(sed -n 's/^Files .*\/\([^ /]*\) and .* differ$/\1/p' <<<"$raw" | sort)

    if [[ $REFRESH -eq 1 ]]; then
        # Rewrite the manifest from live state, preserving the section split
        # (a file changing category is itself reviewable in the manifest diff;
        # NEW differing files land in [expected-semantic] pending review).
        [[ -n "$LEM_CMD" ]] || fail "--refresh needs lem on PATH to record [meta] lem-pin (run under `opam exec --switch=. --` with the fork lem installed)"
        local old_cosmetic f
        old_cosmetic=$(section expected-cosmetic | awk '{print $2}')
        {
            echo "# fork-drift manifest — regenerated by check_fork_drift.sh --refresh."
            echo "# Every entry is a reviewed claim (lean_frontend/docs/2026-08-21_fork-drift-review.md):"
            echo "# [files] = oracle-surface files allowed to differ from upstream/master"
            echo "#   (a SET: compared order-insensitively in the C locale; duplicates FAIL);"
            echo "# [expected-semantic]/[expected-cosmetic] = generated .ml allowed to"
            echo "# differ, pinned by sha256 of their label-normalized unified diff."
            echo "# Cosmetic = verified comment/blank-line-only at review time."
            echo "# [meta] lem-pin = the full 40-hex lem-lean commit both generated trees"
            echo "#   were derived with; prefix-checked against \`lem -v\` when lem is on PATH."
            echo "[meta]"
            echo "merge-base=$live_mb"
            echo "lem-pin=$pinned_lem"
            echo "[files]"
            printf '%s\n' "$live_files"
            echo "[source-content]"
            printf '%s\n' "$live_files" | python3 "$ROOT/scripts/check_fork_content.py" \
                --root "$CONTENT_ROOT" --manifest "$MANIFEST" --emit || exit 1
            echo "[expected-semantic]"
            while IFS= read -r f; do
                [[ -n "$f" ]] || continue
                grep -qx "$f" <<<"$old_cosmetic" || echo "$(diff_hash "$f") $f"
            done <<<"$live_diff_files"
            echo "[expected-cosmetic]"
            while IFS= read -r f; do
                [[ -n "$f" ]] || continue
                grep -qx "$f" <<<"$old_cosmetic" && echo "$(diff_hash "$f") $f"
            done <<<"$live_diff_files"
        } > "$MANIFEST"
        echo "check_fork_drift: manifest REFRESHED at $MANIFEST — review the git diff hunk-by-hunk and commit with justification (this is a Tier-B deliberate act, not a gate pass)."
        exit 0
    fi

    local expected expected_names bad=0 want_hash have_hash f
    expected=$( { section expected-semantic; section expected-cosmetic; } | sort -k2)
    expected_names=$(awk '{print $2}' <<<"$expected" | sort)
    if [[ "$live_diff_files" != "$expected_names" ]]; then
        echo "check_fork_drift: FAIL — generated-tree differing-file set drifted from the manifest." >&2
        echo "--- differing now but not excused (NEW OCaml-token drift):" >&2
        comm -23 <(printf '%s\n' "$live_diff_files") <(printf '%s\n' "$expected_names") | sed 's/^/    /' >&2
        echo "--- excused in the manifest but byte-identical now (stale manifest or stale build):" >&2
        comm -13 <(printf '%s\n' "$live_diff_files") <(printf '%s\n' "$expected_names") | sed 's/^/    /' >&2
        echo "If ocaml_frontend/generated might be stale, regenerate with the pinned" >&2
        echo "lem ('opam exec --switch=. -- make prelude-src') before concluding drift." >&2
        exit 1
    fi
    while read -r want_hash f; do
        [[ -n "$f" ]] || continue
        have_hash=$(diff_hash "$f")
        if [[ "$have_hash" != "$want_hash" ]]; then
            echo "check_fork_drift: FAIL — $f: excused-diff hash moved (manifest $want_hash, live $have_hash) — the fork-vs-upstream delta of this generated file CHANGED; re-review the .lem change (stale-build caveat as above), then refresh deliberately" >&2
            bad=1
        fi
    done <<<"$expected"
    [[ $bad -eq 0 ]] || exit 1

    echo "check_fork_drift: OK — layer 1: $(printf '%s\n' "$live_files" | wc -l) oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: $(printf '%s\n' "$live_diff_files" | wc -l) differing generated files, all hash-pinned (merge-base $pinned_mb; $lem_note)"
}

LEM_ON_PATH=""
if command -v lem >/dev/null; then LEM_ON_PATH=lem; fi

case "$MODE" in
    gate)
        ( gate "$MANIFEST_DEFAULT" "$UPSTREAM_REF_DEFAULT" "$(resolve_upstream_tree)" "$FORK_TREE_DEFAULT" "$LEM_ON_PATH" 0 )
        exit $?
        ;;
    refresh)
        ( gate "$MANIFEST_DEFAULT" "$UPSTREAM_REF_DEFAULT" "$(resolve_upstream_tree)" "$FORK_TREE_DEFAULT" "$LEM_ON_PATH" 1 )
        exit $?
        ;;
esac

# --------------------------------------------------------------------------
# --selftest: plants on scratch manifests / fake prerequisites. Each plant
# states its expected rc AND a message substring the verdict must carry
# (vacuity loud: an expected FAIL that passes, or a FAIL for the wrong
# reason, is a plant failure). The real manifest and tree are never touched.
# --------------------------------------------------------------------------
echo "check_fork_drift: SELFTEST — plants on scratch copies of the manifest and fake prerequisites (loud plant banner; nothing in the tree is touched)"
UP_TREE_REAL="$(resolve_upstream_tree)"
PLANTDIR=$(mktemp -d)
ADV_REF=refs/plant/advanced-upstream
trap 'rm -rf "$PLANTDIR"; if git -C "$ROOT" show-ref --verify -q "$ADV_REF"; then git -C "$ROOT" update-ref -d "$ADV_REF"; fi' EXIT
fails=0
# fake lem commands: one agreeing with the manifest's pin, one stale
pinned_lem_real=$(awk '/^\[meta\]/{s=1;next} /^\[/{s=0} s && /^lem-pin=/{sub(/^lem-pin=/,""); print}' "$MANIFEST_DEFAULT")
printf '#!/bin/sh\necho "Lem %s"\n' "$pinned_lem_real" > "$PLANTDIR/lem-ok"; chmod +x "$PLANTDIR/lem-ok"
printf '#!/bin/sh\necho "Lem deadbee"\n' > "$PLANTDIR/lem-stale"; chmod +x "$PLANTDIR/lem-stale"
n_files_real=$(awk '/^\[files\]/{s=1;next} /^\[/{s=0} s && !/^[[:space:]]*(#|$)/' "$MANIFEST_DEFAULT" | wc -l)

PLANT_OUT=""
# plant <label> <expected-rc: 0|nonzero> <expected-substring> <LC_ALL> <dev-skip 0/1> <gate args...>
plant() {
    local label="$1" want_rc="$2" want_msg="$3" lc="$4" ds="$5"; shift 5
    local rc ok=1
    PLANT_OUT=$( ( export LC_ALL="$lc"
                   if [[ "$ds" == 1 ]]; then export CERB_FORK_DRIFT_DEV_SKIP=1; else unset CERB_FORK_DRIFT_DEV_SKIP; fi
                   gate "$@" ) 2>&1 ); rc=$?
    if [[ "$want_rc" == "0" ]]; then (( rc == 0 )) || ok=0; else (( rc != 0 )) || ok=0; fi
    grep -qF -- "$want_msg" <<<"$PLANT_OUT" || ok=0
    if (( ok )); then
        echo "  PLANT OK   [$label] rc=$rc -> $(grep -m1 -F -- "$want_msg" <<<"$PLANT_OUT" | cut -c1-200)"
    else
        echo "  PLANT FAIL [$label]: rc=$rc (wanted $want_rc), message '$want_msg' $(grep -qF -- "$want_msg" <<<"$PLANT_OUT" && echo present || echo ABSENT):"
        sed 's/^/      /' <<<"$PLANT_OUT"; fails=$((fails+1))
    fi
}

OKMSG="check_fork_drift: OK — layer 1: $n_files_real oracle-surface files = manifest"
files_section() { awk '/^\[files\]/{s=1;next} /^\[/{s=0} s && !/^[[:space:]]*(#|$)/' "$1"; }
rewrite_files() {  # <src-manifest> <new-files-body-file> <dst>
    awk -v body="$2" '
        /^\[files\]/ { print; while ((getline l < body) > 0) print l; skip=1; next }
        /^\[/ { skip=0 }
        !skip { print }
    ' "$1" > "$3"
}
# S1/S2 — locale independence, exercised in the audit's failure mode: a
# manifest whose [files] section is in en_US collation order under LC_ALL=C
# (the configuration that failed before the repair), and one in C byte
# order under LC_ALL=en_US.UTF-8.
files_section "$MANIFEST_DEFAULT" | LC_ALL=en_US.UTF-8 sort > "$PLANTDIR/files.enus"
files_section "$MANIFEST_DEFAULT" | LC_ALL=C sort > "$PLANTDIR/files.c"
if cmp -s "$PLANTDIR/files.enus" "$PLANTDIR/files.c"; then
    echo "  PLANT FAIL [S1 premise]: en_US and C orders coincide on this manifest — the locale plant would be vacuous"; fails=$((fails+1))
fi
rewrite_files "$MANIFEST_DEFAULT" "$PLANTDIR/files.enus" "$PLANTDIR/m.enus"
rewrite_files "$MANIFEST_DEFAULT" "$PLANTDIR/files.c" "$PLANTDIR/m.c"
plant "S1 en_US-ordered [files] under LC_ALL=C (the pre-repair failing configuration)" 0 "$OKMSG" C 0 "$PLANTDIR/m.enus" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
plant "S2 C-ordered [files] under LC_ALL=en_US.UTF-8" 0 "$OKMSG" en_US.UTF-8 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S3 — order-insensitivity: the [files] section reversed
files_section "$MANIFEST_DEFAULT" | tac > "$PLANTDIR/files.rev"
rewrite_files "$MANIFEST_DEFAULT" "$PLANTDIR/files.rev" "$PLANTDIR/m.rev"
if cmp -s "$PLANTDIR/files.rev" "$PLANTDIR/files.c"; then echo "  PLANT FAIL [S3 premise]: the reversed section equals the sorted one (vacuous plant)"; fails=$((fails+1)); fi
plant "S3 reversed [files] order (set unchanged)" 0 "$OKMSG" C 0 "$PLANTDIR/m.rev" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S4 — one name changed: util/cerb_fresh.ml -> util/cerb_fresh_planted.ml
grep -qx 'util/cerb_fresh.ml' "$PLANTDIR/files.c" || { echo "  PLANT FAIL [S4 premise]: util/cerb_fresh.ml not in the manifest"; fails=$((fails+1)); }
sed 's#^util/cerb_fresh\.ml$#util/cerb_fresh_planted.ml#' "$PLANTDIR/files.c" > "$PLANTDIR/files.one"
rewrite_files "$MANIFEST_DEFAULT" "$PLANTDIR/files.one" "$PLANTDIR/m.one"
plant "S4 one [files] name changed -> set drift" nonzero "oracle-surface file set drifted" C 0 "$PLANTDIR/m.one" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
if grep -qx '    util/cerb_fresh.ml' <<<"$PLANT_OUT" && grep -qx '    util/cerb_fresh_planted.ml' <<<"$PLANT_OUT"; then
    echo "  PLANT OK   [S4 detail] both the live-only name (util/cerb_fresh.ml) and the manifest-only name (util/cerb_fresh_planted.ml) are listed"
else
    echo "  PLANT FAIL [S4 detail]: the drift listing does not name both sides:"; sed 's/^/      /' <<<"$PLANT_OUT"; fails=$((fails+1))
fi
# S5 — a duplicated entry
{ cat "$PLANTDIR/files.c"; echo 'util/cerb_fresh.ml'; } > "$PLANTDIR/files.dup"
rewrite_files "$MANIFEST_DEFAULT" "$PLANTDIR/files.dup" "$PLANTDIR/m.dup"
plant "S5 duplicate [files] entry" nonzero "duplicate [files] entries" C 0 "$PLANTDIR/m.dup" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S6 — missing upstream ref (a ref name that does not exist)
plant "S6 missing upstream ref -> FAIL (not a skip)" nonzero "FAIL — missing upstream ref 'plant/no-such-ref'" C 0 "$PLANTDIR/m.c" plant/no-such-ref "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S31 — the upstream ref ADVANCED past the pinned merge-base (public-readiness M9 fresh-clone
#   finding, 2026-09-25): a synthetic commit on top of the merge-base changing a surface file the
#   fork does not touch, reached through a TEMPORARY ref (deleted below and by the EXIT trap). The
#   gate compares against the pinned merge-base, so this must be OK, not drift.
adv_mb=$(awk '/^\[meta\]/{s=1;next} /^\[/{s=0} s && /^merge-base=/{sub(/^merge-base=/,""); print}' "$MANIFEST_DEFAULT")
adv_blob=$(printf 'plant S31: upstream advanced past the merge-base\n' | git -C "$ROOT" hash-object -w --stdin)
adv_tree=$(GIT_INDEX_FILE="$PLANTDIR/adv.idx" git -C "$ROOT" read-tree "$adv_mb" \
           && GIT_INDEX_FILE="$PLANTDIR/adv.idx" git -C "$ROOT" update-index --add --cacheinfo "100644,$adv_blob,frontend/model/cabs.lem" \
           && GIT_INDEX_FILE="$PLANTDIR/adv.idx" git -C "$ROOT" write-tree)
adv_commit=$(GIT_AUTHOR_NAME=plant GIT_AUTHOR_EMAIL=plant@localhost GIT_COMMITTER_NAME=plant GIT_COMMITTER_EMAIL=plant@localhost \
             git -C "$ROOT" commit-tree "$adv_tree" -p "$adv_mb" -m "plant S31: upstream advanced past the merge-base")
git -C "$ROOT" update-ref "$ADV_REF" "$adv_commit"
plant "S31 upstream ref advanced past the pinned merge-base -> OK (not drift)" 0 "$OKMSG" C 0 "$PLANTDIR/m.c" "$ADV_REF" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
git -C "$ROOT" update-ref -d "$ADV_REF"
# S7 — missing upstream generated tree
plant "S7 missing upstream generated tree -> FAIL (not a skip)" nonzero "FAIL — layer 2 prerequisite missing" C 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$PLANTDIR/no-such-tree" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S8 — the development opt-in on a missing ref: rc 0 WITH the loud banner
plant "S8 CERB_FORK_DRIFT_DEV_SKIP=1 on a missing ref -> rc 0 with the DEV SKIP banner" 0 "DEV SKIP (CERB_FORK_DRIFT_DEV_SKIP=1 is set)" C 1 "$PLANTDIR/m.c" plant/no-such-ref "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S9 — stale lem-pin vs `lem -v`
plant "S9 stale [meta] lem-pin vs lem -v" nonzero "lem-pin stale" C 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-stale" 0
# S10 — lem-pin line removed
grep -v '^lem-pin=' "$PLANTDIR/m.c" > "$PLANTDIR/m.nolem"
plant "S10 [meta] lem-pin line missing" nonzero "no [meta] lem-pin= line" C 0 "$PLANTDIR/m.nolem" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S11/S12: same manifested names, but fresh supply's handwritten bytes move.
# The positive control uses a copied tree; only that owned copy is mutated.
mkdir "$PLANTDIR/content"
while read -r mode digest path; do
    [[ -n "$path" && "$mode" != 000000 ]] || continue
    mkdir -p "$PLANTDIR/content/$(dirname "$path")"
    cp -pP "$ROOT/$path" "$PLANTDIR/content/$path" || exit 1
done < <(awk '/^\[source-content\]/{s=1;next} /^\[/{s=0} s && !/^[[:space:]]*(#|$)/' "$MANIFEST_DEFAULT")
plant "S11 unmodified copied source contents" 0 "$OKMSG" C 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0 "$PLANTDIR/content"
printf '\nlet validation_foundations_content_plant = 1\n' >> "$PLANTDIR/content/util/cerb_fresh.ml"
plant "S12 content change inside already-listed fresh supply" nonzero "source-content drift inside reviewed file(s)" C 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0 "$PLANTDIR/content"
# S13/S14: duplicated or missing content pins must fail independently of names.
awk '1; /^100[67][45][45] [0-9a-f]+ util\/cerb_fresh.ml$/{print}' "$PLANTDIR/m.c" > "$PLANTDIR/m.content-dup"
plant "S13 duplicate source-content pin" nonzero "duplicate [source-content] entry" C 0 "$PLANTDIR/m.content-dup" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
sed '/^100[67][45][45] [0-9a-f]* util\/cerb_fresh.ml$/d' "$PLANTDIR/m.c" > "$PLANTDIR/m.content-missing"
plant "S14 missing source-content pin" nonzero "source-content path set differs" C 0 "$PLANTDIR/m.content-missing" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# Closure F1: version normalization, malformed inputs and refresh retention.
version_plant() {  # <label> <version> <expected-rc> <expected-message>
    printf '#!/bin/sh\necho "Lem %s"\n' "$2" > "$PLANTDIR/lem-version"
    chmod +x "$PLANTDIR/lem-version"
    plant "$1" "$3" "$4" C 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-version" 0
}
version_plant "S15 seven hex" "${pinned_lem_real:0:7}" 0 "$OKMSG"
version_plant "S16 eight hex" "${pinned_lem_real:0:8}" 0 "$OKMSG"
version_plant "S17 hash-bearing describe" "lean-backend-v0.1.0-alpha.1-12-g${pinned_lem_real:0:9}" 0 "$OKMSG"
version_plant "S18 dirty hash" "${pinned_lem_real:0:7}-dirty" 0 "$OKMSG"
version_plant "S19 dirty describe" "v0.1-0-g${pinned_lem_real}-dirty" 0 "$OKMSG"
version_plant "S20 nonhex version" "2026-09-24" nonzero "malformed lem version"
version_plant "S21 bare tag" "lean-backend-v0.1.0-alpha.1" nonzero "malformed lem version"
version_plant "S22 short hash" "${pinned_lem_real:0:6}" nonzero "malformed lem version"
version_plant "S23 long hash" "${pinned_lem_real}0" nonzero "malformed lem version"
version_plant "S24 malformed describe" "v0.1-nope-g${pinned_lem_real:0:7}" nonzero "malformed lem version"
version_plant "S25 wrong describe hash" "v0.1-1-gdeadbee" nonzero "lem-pin stale"
sed "s/^lem-pin=.*/lem-pin=${pinned_lem_real:0:8}/" "$PLANTDIR/m.c" > "$PLANTDIR/m.short-pin"
plant "S26 abbreviated manifest pin" nonzero "lem-pin must be exactly one full 40-hex commit" C 0 "$PLANTDIR/m.short-pin" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
sed 's/^lem-pin=.*/lem-pin=not-a-commit/' "$PLANTDIR/m.c" > "$PLANTDIR/m.bad-pin"
plant "S27 nonhex manifest pin" nonzero "lem-pin must be exactly one full 40-hex commit" C 0 "$PLANTDIR/m.bad-pin" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
sed '/^lem-pin=/p' "$PLANTDIR/m.c" > "$PLANTDIR/m.dup-pin"
plant "S28 duplicate manifest pin" nonzero "lem-pin must be exactly one full 40-hex commit" C 0 "$PLANTDIR/m.dup-pin" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
cp "$PLANTDIR/m.c" "$PLANTDIR/m.refresh"
printf '#!/bin/sh\necho "Lem %s"\n' "${pinned_lem_real:0:7}" > "$PLANTDIR/lem-short"; chmod +x "$PLANTDIR/lem-short"
plant "S29 refresh with abbreviated version" 0 "manifest REFRESHED" C 0 "$PLANTDIR/m.refresh" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-short" 1
if [[ $(sed -n 's/^lem-pin=//p' "$PLANTDIR/m.refresh") == "$pinned_lem_real" ]]; then
    echo "  PLANT OK   [S29 detail] refresh preserved the full manifest pin"
else
    echo "  PLANT FAIL [S29 detail] refresh lost the full manifest pin"; fails=$((fails+1))
fi
plant "S30 refresh refuses wrong version" nonzero "lem-pin stale" C 0 "$PLANTDIR/m.refresh" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-stale" 1
# unplanted: the real manifest, the real prerequisites, lem as found on PATH
echo "  UNPLANTED:"
if out=$( ( unset CERB_FORK_DRIFT_DEV_SKIP; gate "$MANIFEST_DEFAULT" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$LEM_ON_PATH" 0 ) 2>&1 ); then
    sed 's/^/    /' <<<"$out"
else
    echo "  PLANT FAIL [unplanted gate is not green]:"; sed 's/^/      /' <<<"$out"; fails=$((fails+1))
fi
if (( fails == 0 )); then
    echo "check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)"
    exit 0
else
    echo "check_fork_drift: SELFTEST FAILED ($fails)"; exit 1
fi
