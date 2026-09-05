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
#   whole manifest is relative to it). [meta] lem-pin records the lem-lean
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
#   NOT in scope of layer 1 (audit F4/F5, open): the CONTENT of the
#   hand-written [files] entries (util/cerb_fresh.ml, ocaml_frontend/
#   fork_renumber.ml, backend/driver/main.ml, …) is name-manifested and
#   review-defended only — a behaviour change inside an already-listed
#   hand file moves neither list. Content pins for that surface are the
#   separate F5 task.
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
#   3. ./scripts/check_fork_drift.sh --refresh   # rewrites the manifest
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
# Env: CERB_UPSTREAM_TREE overrides the upstream generated-tree path.
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
          cerberus.opam cerberus-lib.opam)
FORK_TREE_DEFAULT="$ROOT/ocaml_frontend/generated"
UPSTREAM_REF_DEFAULT=upstream/master

MODE=gate
case "${1:-}" in
    "") ;;
    --refresh) MODE=refresh ;;
    --selftest) MODE=selftest ;;
    *) echo "check_fork_drift: usage: $0 [--refresh | --selftest]" >&2; exit 2 ;;
esac

# resolve_upstream_tree: the pristine tree's path (CERB_UPSTREAM_TREE or the
# container-relative candidates); empty when none exists
resolve_upstream_tree() {
    local c
    if [[ -n "${CERB_UPSTREAM_TREE:-}" ]]; then echo "$CERB_UPSTREAM_TREE"; return; fi
    for c in "$ROOT/../deps/cerberus-upstream/ocaml_frontend/generated" \
             "$ROOT/../../../deps/cerberus-upstream/ocaml_frontend/generated" \
             /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/ocaml_frontend/generated; do
        if [[ -d "$c" ]]; then echo "$c"; return; fi
    done
    echo ""
}

# gate <manifest> <upstream-ref> <upstream-tree> <fork-tree> <lem-cmd> <refresh 0/1>
#   The whole gate; run in a subshell (it exits). <lem-cmd> is the command
#   whose `-v` output's 2nd word is the lem version (`lem` in production;
#   the selftest passes fakes); "" = not on PATH.
gate() {
    local MANIFEST="$1" UPSTREAM_REF="$2" UP_TREE="$3" FORK_TREE="$4" LEM_CMD="$5" REFRESH="$6"
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
        echo "  The fork-drift gate needs the fetch-only local-mirror remote:" >&2
        echo "    git remote add upstream /home/dev/projects/cerberus-lean-proj/deps/mirrors/cerberus.git" >&2
        echo "    git remote set-url --push upstream no-push-fetch-only && git fetch upstream" >&2
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
    local pinned_mb live_mb pinned_lem live_lem
    pinned_mb=$(section meta | sed -n 's/^merge-base=//p')
    [[ -n "$pinned_mb" ]] || fail "manifest has no [meta] merge-base= line"
    pinned_lem=$(section meta | sed -n 's/^lem-pin=//p')
    [[ -n "$pinned_lem" ]] || fail "manifest has no [meta] lem-pin= line (the lem-lean commit both generated trees were derived with)"

    live_mb=$(git -C "$ROOT" merge-base "$UPSTREAM_REF" HEAD) || fail "git merge-base failed"
    if [[ "$live_mb" != "$pinned_mb" ]]; then
        fail "merge-base moved: manifest pins $pinned_mb, live is $live_mb — $UPSTREAM_REF or the fork history changed; run the refresh recipe (deliberate commit) after re-review"
    fi

    # --- lem-pin cross-check (audit F4 (c)) ----------------------------------
    local lem_note
    if [[ -n "$LEM_CMD" ]]; then
        live_lem=$("$LEM_CMD" -v | awk '{print $2}') || fail "'$LEM_CMD -v' failed"
        [[ -n "$live_lem" ]] || fail "'$LEM_CMD -v' printed no version"
        if [[ $REFRESH -eq 0 && "$live_lem" != "$pinned_lem" ]]; then
            fail "lem-pin stale: manifest records lem-pin=$pinned_lem, '$LEM_CMD -v' says $live_lem — both generated trees must be re-derived with the pinned lem and the manifest refreshed deliberately"
        fi
        lem_note="lem-pin $pinned_lem = lem -v"
    else
        lem_note="lem-pin $pinned_lem (lem not on PATH: not cross-checked)"
    fi

    # --- layer 1: name-level (SET comparison, C-locale canonical) -----------
    local live_files manifest_raw manifest_files dups
    live_files=$(git -C "$ROOT" diff "$UPSTREAM_REF" --name-only -- "${SURFACES[@]}" | sort)

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

    # --- layer 2: generated-tree content -------------------------------------
    local layer2_missing=""
    [[ -n "$UP_TREE" && -d "$UP_TREE" ]] || layer2_missing="upstream pristine tree not found (deps/cerberus-upstream/ocaml_frontend/generated; CERB_UPSTREAM_TREE overrides)"
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
        [[ -n "$LEM_CMD" ]] || fail "--refresh needs lem on PATH to record [meta] lem-pin (source scripts/env.sh)"
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
            echo "# [meta] lem-pin = the lem-lean commit (\`lem -v\`) both generated trees"
            echo "#   were derived with; cross-checked against \`lem -v\` when lem is on PATH."
            echo "[meta]"
            echo "merge-base=$live_mb"
            echo "lem-pin=$live_lem"
            echo "[files]"
            printf '%s\n' "$live_files"
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
PLANTDIR=$(mktemp -d); trap 'rm -rf "$PLANTDIR"' EXIT
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
# S7 — missing upstream generated tree
plant "S7 missing upstream generated tree -> FAIL (not a skip)" nonzero "FAIL — layer 2 prerequisite missing" C 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$PLANTDIR/no-such-tree" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S8 — the development opt-in on a missing ref: rc 0 WITH the loud banner
plant "S8 CERB_FORK_DRIFT_DEV_SKIP=1 on a missing ref -> rc 0 with the DEV SKIP banner" 0 "DEV SKIP (CERB_FORK_DRIFT_DEV_SKIP=1 is set)" C 1 "$PLANTDIR/m.c" plant/no-such-ref "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# S9 — stale lem-pin vs `lem -v`
plant "S9 stale [meta] lem-pin vs lem -v" nonzero "lem-pin stale" C 0 "$PLANTDIR/m.c" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-stale" 0
# S10 — lem-pin line removed
grep -v '^lem-pin=' "$PLANTDIR/m.c" > "$PLANTDIR/m.nolem"
plant "S10 [meta] lem-pin line missing" nonzero "no [meta] lem-pin= line" C 0 "$PLANTDIR/m.nolem" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$PLANTDIR/lem-ok" 0
# unplanted: the real manifest, the real prerequisites, lem as found on PATH
echo "  UNPLANTED:"
if out=$( ( unset CERB_FORK_DRIFT_DEV_SKIP; gate "$MANIFEST_DEFAULT" "$UPSTREAM_REF_DEFAULT" "$UP_TREE_REAL" "$FORK_TREE_DEFAULT" "$LEM_ON_PATH" 0 ) 2>&1 ); then
    sed 's/^/    /' <<<"$out"
else
    echo "  PLANT FAIL [unplanted gate is not green]:"; sed 's/^/      /' <<<"$out"; fails=$((fails+1))
fi
if (( fails == 0 )); then
    echo "check_fork_drift: SELFTEST OK (10 plants with the declared verdict and message: S1-S3 order/locale OK, S4 name-drift FAIL (+ both-sides listing), S5 duplicate FAIL, S6 missing-ref FAIL, S7 missing-tree FAIL, S8 dev-opt-in rc 0 with banner, S9/S10 lem-pin FAILs; unplanted gate green)"
    exit 0
else
    echo "check_fork_drift: SELFTEST FAILED ($fails)"; exit 1
fi
