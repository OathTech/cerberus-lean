#!/bin/bash
# check_fork_drift.sh — standing fork-drift gate (arc-10 audit follow-up,
# [USER] mandate; spec: notes/2026-08-21_fork-drift-review.md §6).
#
# THE POINT: every fork-side change that could affect the OCaml oracle
# must be a REVIEWED, MANIFESTED fact, never an accident. The F-D family
# (fork oracle corruption, arc-10 S4 root-cause) entered through exactly
# this surface under a commit message that wrongly claimed OCaml
# neutrality — this gate makes any future member of that class loud.
#
# Layer 1 (name-level, <1 s): `git diff upstream/master --name-only`
#   over the oracle surfaces must equal the committed manifest's [files]
#   section byte-for-byte (sorted). Any new/removed file on the oracle
#   surface fails loud and forces a manifest update whose commit states
#   the justification. Also pins the merge-base: if upstream/master or
#   the fork history moves so the merge-base leaves the manifested
#   commit, the gate fails (the whole manifest is relative to it).
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
#
# SKIP semantics (loud, rc 0 — never silent): missing upstream remote/
#   ref (fresh clone without the fetch-only local-mirror remote) skips
#   the whole gate; a missing generated tree (either side) skips layer 2
#   only. Everything else is fail-closed rc 1.
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
# Env: CERB_UPSTREAM_TREE overrides the upstream generated-tree path.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/scripts/fork_drift_manifest.txt"
SURFACES=(frontend backend/common backend/driver backend/lean_export
          ocaml_frontend memory util parsers sibylfs runtime
          cerberus.opam cerberus-lib.opam)
FORK_TREE="$ROOT/ocaml_frontend/generated"

REFRESH=0
[[ "${1:-}" == "--refresh" ]] && REFRESH=1

fail() { echo "check_fork_drift: FAIL — $*" >&2; exit 1; }

# --- upstream ref (repo-level remote; visible from worktrees) ---------------
if ! git -C "$ROOT" rev-parse --verify -q upstream/master >/dev/null; then
    echo "check_fork_drift: SKIP (LOUD) — no 'upstream/master' ref in this checkout." >&2
    echo "  The fork-drift gate needs the fetch-only local-mirror remote:" >&2
    echo "    git remote add upstream /home/dev/projects/cerberus-lean-proj/deps/mirrors/cerberus.git" >&2
    echo "    git remote set-url --push upstream no-push-fetch-only && git fetch upstream" >&2
    echo "  Skipping is NOT a pass — restore the remote and re-run." >&2
    exit 0
fi

# --- manifest parsing -------------------------------------------------------
[[ -f "$MANIFEST" ]] || fail "manifest missing: $MANIFEST (fail-closed)"
section() {  # <name> -> the section's non-comment lines
    awk -v s="[$1]" '
        $0 == s { insec=1; next }
        /^\[/   { insec=0 }
        insec && !/^[[:space:]]*(#|$)/ { print }
    ' "$MANIFEST"
}
pinned_mb=$(section meta | sed -n 's/^merge-base=//p')
[[ -n "$pinned_mb" ]] || fail "manifest has no [meta] merge-base= line"

live_mb=$(git -C "$ROOT" merge-base upstream/master HEAD) || fail "git merge-base failed"
if [[ "$live_mb" != "$pinned_mb" ]]; then
    fail "merge-base moved: manifest pins $pinned_mb, live is $live_mb — upstream/master or the fork history changed; run the refresh recipe (deliberate commit) after re-review"
fi

# --- layer 1: name-level ----------------------------------------------------
live_files=$(git -C "$ROOT" diff upstream/master --name-only -- "${SURFACES[@]}" | sort)

if [[ $REFRESH -eq 0 ]]; then
    manifest_files=$(section files)
    if [[ "$live_files" != "$manifest_files" ]]; then
        echo "check_fork_drift: FAIL — oracle-surface file set drifted from the manifest." >&2
        echo "--- files on the live diff but not in the manifest (NEW DRIFT):" >&2
        comm -23 <(printf '%s\n' "$live_files") <(printf '%s\n' "$manifest_files") | sed 's/^/    /' >&2
        echo "--- files in the manifest but no longer on the live diff:" >&2
        comm -13 <(printf '%s\n' "$live_files") <(printf '%s\n' "$manifest_files") | sed 's/^/    /' >&2
        echo "Every entry is a reviewed claim about the oracle: re-review the change" >&2
        echo "against notes/2026-08-21_fork-drift-review.md, then run the refresh recipe." >&2
        exit 1
    fi
fi

# --- layer 2: generated-tree content ----------------------------------------
UP_TREE="${CERB_UPSTREAM_TREE:-}"
if [[ -z "$UP_TREE" ]]; then
    for c in "$ROOT/../deps/cerberus-upstream/ocaml_frontend/generated" \
             "$ROOT/../../../deps/cerberus-upstream/ocaml_frontend/generated" \
             /home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/ocaml_frontend/generated; do
        [[ -d "$c" ]] && { UP_TREE="$c"; break; }
    done
fi

layer2_skip=""
[[ -d "$UP_TREE" ]] || layer2_skip="upstream pristine tree not found (deps/cerberus-upstream/ocaml_frontend/generated; CERB_UPSTREAM_TREE overrides)"
[[ -d "$FORK_TREE" ]] || layer2_skip="fork generated tree missing: $FORK_TREE (run 'make prelude-src')"
if [[ -n "$layer2_skip" ]]; then
    if [[ $REFRESH -eq 1 ]]; then fail "--refresh needs both generated trees: $layer2_skip"; fi
    echo "check_fork_drift: layer 1 OK ($(printf '%s\n' "$live_files" | wc -l) manifested oracle-surface files); layer 2 SKIPPED (LOUD) — $layer2_skip" >&2
    exit 0
fi

diff_hash() {  # <basename> -> sha256 of the label-normalized unified diff
    diff -u --label "upstream/$1" --label "fork/$1" "$UP_TREE/$1" "$FORK_TREE/$1" \
        | sha256sum | awk '{print $1}'
}

# differing/extra files, basenames (fail on Only-in: tree shape must match)
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
    old_cosmetic=$(section expected-cosmetic | awk '{print $2}')
    {
        echo "# fork-drift manifest — regenerated by check_fork_drift.sh --refresh."
        echo "# Every entry is a reviewed claim (notes/2026-08-21_fork-drift-review.md):"
        echo "# [files] = oracle-surface files allowed to differ from upstream/master;"
        echo "# [expected-semantic]/[expected-cosmetic] = generated .ml allowed to"
        echo "# differ, pinned by sha256 of their label-normalized unified diff."
        echo "# Cosmetic = verified comment/blank-line-only at review time."
        echo "[meta]"
        echo "merge-base=$live_mb"
        echo "lem-pin=$(command -v lem >/dev/null && lem -v 2>/dev/null | awk '{print $2}' || echo unknown)"
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
bad=0
while read -r want_hash f; do
    [[ -n "$f" ]] || continue
    have_hash=$(diff_hash "$f")
    if [[ "$have_hash" != "$want_hash" ]]; then
        echo "check_fork_drift: FAIL — $f: excused-diff hash moved (manifest $want_hash, live $have_hash) — the fork-vs-upstream delta of this generated file CHANGED; re-review the .lem change (stale-build caveat as above), then refresh deliberately" >&2
        bad=1
    fi
done <<<"$expected"
[[ $bad -eq 0 ]] || exit 1

echo "check_fork_drift: OK — layer 1: $(printf '%s\n' "$live_files" | wc -l) oracle-surface files = manifest; layer 2: $(printf '%s\n' "$live_diff_files" | wc -l) differing generated files, all hash-pinned (merge-base $pinned_mb)"
