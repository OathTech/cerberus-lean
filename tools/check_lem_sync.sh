#!/bin/bash
# check_lem_sync.sh — lem-generated-OCaml content-sync gate
# (hotfix arc/hotfix-libc-floor, 2026-08-22; record:
# lean_frontend/docs/2026-08-22_arc13-hotfix-libc-floor.md).
#
# THE HAZARD: ocaml_frontend/generated/ is a gitignored build product of
# `make prelude-src` (frontend .lem -> OCaml via lem). The .lem sources
# live OUTSIDE the dune workspace (the root `dune` (dirs ...) stanza
# excludes frontend/), so `dune build` cannot see them and happily
# compiles a STALE generated tree into the oracle binary. Make's own
# .lem -> .ml dependency is mtime-based and can no-op on stale CONTENT
# (worktree priming copies generated/ with fresh mtimes). Observed at
# the arc-13 post-merge certification: a checkout carrying a pre-arc-13
# generated/ copy built a cerberus whose desugar minted symbols off the
# dead threaded fresh_sym_supply (the F-D-era split stream); the arc-13
# single-supply backstop correctly refused EVERY C compile
# (CERB_FRESH_FLOOR_VIOLATION window-nodraw), presenting as "the
# runtime/libc/libc.co dune rule is broken".
#
# THE MECHANISM (content-hash stamp, fail-closed):
#   --record  called ONLY by the Makefile generation recipe, immediately
#             after lem + the sed patch-ups have run. Writes
#             ocaml_frontend/lem_sync.sha256 (NEXT TO lem.log, outside
#             generated/ so the fork-drift layer-2 tree comparison never
#             sees it) with two lines:
#               src <sha256 over all frontend/{model,concurrency} .lem>
#               gen <sha256 over all ocaml_frontend/generated/*.ml>
#             The stamp is trustworthy because it is written only by the
#             recipe that just ran lem on exactly those sources.
#   --check   recomputes both and compares. Any mismatch, missing stamp,
#             or missing tree is a LOUD failure (token
#             CERB_LEM_SYNC_STALE, exit 1) with the remediation.
#
# Wired into:
#   (a) the dune graph — ocaml_frontend/dune rule `lem_sync_checked`
#       ((deps (universe)) => re-verified on every build, never cached;
#       the version.ml precedent) which runtime/libc's libc.co/libm.co
#       rules depend on, so a true rebuild of the shipped core objects
#       can never silently use a stale frontend;
#   (b) scripts/test_unit.sh (standing gate, fail-closed).
# Complementary to scripts/check_fork_drift.sh layer 2, which pins the
# generated-vs-upstream diffs but loudly SKIPs when the upstream tree is
# absent; this stamp is self-contained and never skips.
#
# Documented residuals (hotfix record §residuals): the Makefile's
# LEM_SRC list and its sed patch-ups are not hashed (a structural
# Makefile edit without regeneration is not caught — arc-reviewed
# surface); the lem binary version is not hashed (a lem re-pin without
# regeneration is not caught — the playbook's rebuild-lem discipline
# plus the runtime backstop cover that); sibylfs/generated carries no
# stamp (different failure surface, own gates).
#
# LEAN-SIDE STAMP (S-basket item 6, 2026-09-01; closes the residual the
# semantics-first split hit — record: docs/2026-08-31_semantics-first-
# split.md finding 6: a worktree primed with a pre-threadB
# lean_frontend/generated tree ran differential lanes against STALE
# semantics, masking a real debug-lane movement until exec-totality
# tripped over it): --record-lean is called by the Makefile's
# lean-prelude-src recipe; --check-lean rides test_unit.sh next to
# --check. Stamp lean_frontend/lem_sync.sha256:
#   src <same .lem-source hash as the OCaml stamp>
#   gen <sha256 over lean_frontend/generated/*.lean EXCLUDING the
#        hand-written copies (files whose basename exists at
#        lean_frontend/<base>.lean — those may legitimately be
#        re-copied by hand between regenerations and are byte-pinned
#        by test_unit's sync gate instead)>
#
# Usage: tools/check_lem_sync.sh [--root DIR] --record|--check|--record-lean|--check-lean

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    --record|--check|--record-lean|--check-lean) MODE="${1#--}"; shift ;;
    *) echo "check_lem_sync: unknown argument '$1'" >&2; exit 2 ;;
  esac
done
[[ -n "$MODE" ]] || { echo "usage: check_lem_sync.sh [--root DIR] --record|--check|--record-lean|--check-lean" >&2; exit 2; }

STAMP_REL="ocaml_frontend/lem_sync.sha256"
STAMP="$ROOT/$STAMP_REL"
LEAN_STAMP_REL="lean_frontend/lem_sync.sha256"
LEAN_STAMP="$ROOT/$LEAN_STAMP_REL"

# Hash a NUL-sorted, path-labeled file set (relative paths => location-
# independent, identical from the source tree and from dune's _build
# escape). Fails loud on an empty set (a missing tree must never hash
# as "empty and equal").
hash_set() {  # args: find args, relative to $ROOT
  local files
  files="$(cd "$ROOT" && find "$@" -type f -print0 2>/dev/null | LC_ALL=C sort -z | tr '\0' '\n')" || true
  if [[ -z "$files" ]]; then
    echo "EMPTY"
    return 0
  fi
  (cd "$ROOT" && printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
}

src_hash() { hash_set frontend/model frontend/concurrency -name '*.lem'; }
gen_hash() { hash_set ocaml_frontend/generated -maxdepth 1 -name '*.ml'; }

# Lean generated tree, hand-written copies excluded (see header note):
# a .lean under lean_frontend/generated whose basename exists at
# lean_frontend/<base>.lean is a hand-written copy, byte-pinned by the
# test_unit sync gate; everything else is lem output.
lean_gen_hash() {
  local files
  files="$(cd "$ROOT" && find lean_frontend/generated -maxdepth 1 -name '*.lean' -type f -print0 2>/dev/null \
    | LC_ALL=C sort -z | tr '\0' '\n')" || true
  if [[ -z "$files" ]]; then
    echo "EMPTY"
    return 0
  fi
  local kept=""
  while IFS= read -r f; do
    local base="${f##*/}"
    [[ -f "$ROOT/lean_frontend/$base" ]] && continue
    kept+="$f"$'\n'
  done <<< "$files"
  if [[ -z "$kept" ]]; then
    echo "EMPTY"
    return 0
  fi
  (cd "$ROOT" && printf '%s' "$kept" | tr '\n' '\0' | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
}

fail() {
  echo "CERB_LEM_SYNC_STALE: $1" >&2
  cat >&2 <<'EOF'
CERB_LEM_SYNC_STALE: ocaml_frontend/generated/ is not content-in-sync with
the frontend .lem sources. A binary built from this tree is a WRONG oracle
(the arc-13 single-supply backstop will floor every C compile). Remediate
with a forced regeneration under the project switch, e.g.:
    source scripts/env.sh   # or scripts/ce
    opam exec --switch=. -- make clean-prelude-src prelude-src
(plain `make prelude-src` may no-op on mtimes). Design + incident record:
lean_frontend/docs/2026-08-22_arc13-hotfix-libc-floor.md.
EOF
  exit 1
}

fail_lean() {
  echo "CERB_LEM_SYNC_STALE: $1" >&2
  cat >&2 <<'EOF'
CERB_LEM_SYNC_STALE: lean_frontend/generated/ is not content-in-sync with
the frontend .lem sources. A cerberus-lean built from this tree runs STALE
semantics — differential lanes would compare the oracle against the wrong
model (the semantics-first split's finding 6: a stale primed tree masked a
real debug-lane movement). Remediate with a forced regeneration:
    source scripts/env.sh   # or scripts/ce
    make lean-prelude-src
then rebuild (cd lean_frontend && ../scripts/capped lake build).
EOF
  exit 1
}

SRC="$(src_hash)"
GEN="$(gen_hash)"
[[ "$SRC" != "EMPTY" ]] || fail "no .lem sources found under $ROOT/frontend/{model,concurrency}"

case "$MODE" in
  record)
    [[ "$GEN" != "EMPTY" ]] || fail "--record with no generated .ml files under $ROOT/ocaml_frontend/generated"
    printf 'src %s\ngen %s\n' "$SRC" "$GEN" > "$STAMP"
    echo "check_lem_sync: recorded $STAMP_REL (src $SRC, gen $GEN)"
    ;;
  check)
    [[ "$GEN" != "EMPTY" ]] || fail "no generated .ml files under $ROOT/ocaml_frontend/generated (run the regeneration)"
    [[ -f "$STAMP" ]] || fail "stamp $STAMP_REL missing (generated tree predates this gate, or was never regenerated here)"
    WANT_SRC="$(awk '$1=="src"{print $2}' "$STAMP")"
    WANT_GEN="$(awk '$1=="gen"{print $2}' "$STAMP")"
    [[ -n "$WANT_SRC" && -n "$WANT_GEN" ]] || fail "stamp $STAMP_REL is malformed"
    [[ "$SRC" == "$WANT_SRC" ]] || fail "frontend .lem sources changed since generation (stamp src $WANT_SRC, tree $SRC) — generated/ is STALE"
    [[ "$GEN" == "$WANT_GEN" ]] || fail "generated .ml files differ from what the recipe produced (stamp gen $WANT_GEN, tree $GEN) — hand-edited, partial, or foreign generated tree"
    echo "check_lem_sync: OK (src $SRC, gen $GEN)"
    ;;
  record-lean)
    LGEN="$(lean_gen_hash)"
    [[ "$LGEN" != "EMPTY" ]] || fail_lean "--record-lean with no lem-generated .lean files under $ROOT/lean_frontend/generated"
    printf 'src %s\ngen %s\n' "$SRC" "$LGEN" > "$LEAN_STAMP"
    echo "check_lem_sync: recorded $LEAN_STAMP_REL (src $SRC, gen $LGEN)"
    ;;
  check-lean)
    LGEN="$(lean_gen_hash)"
    [[ "$LGEN" != "EMPTY" ]] || fail_lean "no lem-generated .lean files under $ROOT/lean_frontend/generated (run the regeneration)"
    [[ -f "$LEAN_STAMP" ]] || fail_lean "stamp $LEAN_STAMP_REL missing (generated tree predates this gate, or was never regenerated here)"
    WANT_SRC="$(awk '$1=="src"{print $2}' "$LEAN_STAMP")"
    WANT_GEN="$(awk '$1=="gen"{print $2}' "$LEAN_STAMP")"
    [[ -n "$WANT_SRC" && -n "$WANT_GEN" ]] || fail_lean "stamp $LEAN_STAMP_REL is malformed"
    [[ "$SRC" == "$WANT_SRC" ]] || fail_lean "frontend .lem sources changed since Lean generation (stamp src $WANT_SRC, tree $SRC) — lean_frontend/generated is STALE"
    [[ "$LGEN" == "$WANT_GEN" ]] || fail_lean "lem-generated .lean files differ from what the recipe produced (stamp gen $WANT_GEN, tree $LGEN) — hand-edited, partial, or foreign generated tree"
    echo "check_lem_sync: lean OK (src $SRC, gen $LGEN)"
    ;;
esac
