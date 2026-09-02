#!/bin/bash
# check_handwritten_sync.sh — hand-written -> generated/ copy-set gate
# (hotfix fix/freshness-copy-gap, 2026-09-02; record:
# lean_frontend/docs/2026-09-02_freshness-copy-gap.md).
#
# THE HAZARD: Lake compiles the Lean driver from lean_frontend/generated/
# (lakefile.toml srcDir), NOT from lean_frontend/. The hand-written
# lean_frontend/*.lean files reach the build only as COPIES made by the
# `make lean-prelude-src` recipe. A build after a source edit (or after a
# merge, or in a worktree primed with an older generated/ tree) that skips
# the recipe compiles the STALE copy. Observed 2026-09-02 on the primary
# checkout: a mainline merge changed lean_frontend/CerbMem.lean;
# scripts/common.sh build_lean ran WITHOUT lean-prelude-src; the binary
# hash was unchanged (built from the old generated/CerbMem.lean) while the
# driver-freshness stamp RECORDED the new source hash — so
# check_driver_fresh --check said `lean OK` and check_lem_sync
# --check-lean said OK (it hashes only the .lem-derived files). Two green
# gates over a binary that did not correspond to its sources: fail-open,
# the exact class the freshness stamps exist to close. The stamp hashed
# both the source and its copy but never COMPARED them.
#
# THE MECHANISM (no stamp — a direct comparison): the copy set is
# enumerated from lean_frontend/handwritten_copy.manifest, the SAME file
# the Makefile recipe reads (LEAN_HANDWRITTEN); nothing else lists it.
# Every listed file must exist on both sides and be byte-identical (cmp).
# Fail-closed in every direction:
#   - manifest missing/empty            -> FAIL (vacuity is loud)
#   - listed source missing              -> FAIL
#   - generated/ copy missing            -> FAIL
#   - byte drift                         -> FAIL, naming the file
#   - a lean_frontend/*.lean NOT listed  -> FAIL (the manifest cannot
#     silently drift from the tree: an unlisted file would never be
#     propagated, and the Makefile would not copy it either)
# Why not fold this into the lem-sync stamp (check_lem_sync --*-lean):
# that stamp records a derivation whose input (.lem) is not directly
# comparable to its output; here the source IS present next to the copy,
# so a byte comparison is strictly stronger than any recorded hash and
# has no stamp state that can itself go stale. The lem-sync Lean stamp
# therefore keeps EXCLUDING these copies (see its header).
#
# Token on failure: CERB_DRIVER_STALE (the driver-freshness family — the
# consequence is a driver binary that does not correspond to its sources).
#
# Wired into: Makefile lean-prelude-src (post-copy self-check);
# tools/check_driver_fresh.sh --record-lean / --check[-lean] (no stamp is
# recorded, and no check passes, over a drifted copy set);
# scripts/common.sh build_lean (precondition — refuses to build; see the
# refuse-only rationale there); scripts/test_unit.sh (sync gate).
#
# Usage: tools/check_handwritten_sync.sh [--root DIR] [--quiet]
#   exit 0: every copy byte-identical (prints the count unless --quiet)
#   exit 1: CERB_DRIVER_STALE (details on stderr)
#   exit 2: usage

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUIET=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "check_handwritten_sync: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

MANIFEST_REL="lean_frontend/handwritten_copy.manifest"
MANIFEST="$ROOT/$MANIFEST_REL"
SRC_DIR="$ROOT/lean_frontend"
GEN_DIR="$ROOT/lean_frontend/generated"

fail() {
  echo "CERB_DRIVER_STALE: $1" >&2
  cat >&2 <<'MSG'
CERB_DRIVER_STALE: lean_frontend/generated/ does not carry the current
hand-written sources. Lake compiles from generated/, so a cerberus-lean
built from this tree would NOT correspond to lean_frontend/*.lean (the
2026-09-02 fail-open: a green freshness stamp over a stale-copy binary).
Remediate by running the copy recipe, then rebuild:
    source scripts/env.sh   # or scripts/ce
    make lean-prelude-src
    cd lean_frontend && ../scripts/capped lake build
Copy set: lean_frontend/handwritten_copy.manifest (the Makefile reads the
same file). Record: lean_frontend/docs/2026-09-02_freshness-copy-gap.md.
MSG
  exit 1
}

[[ -f "$MANIFEST" ]] || fail "copy-set manifest $MANIFEST_REL missing — the hand-written->generated/ copy set cannot be enumerated (an unknown copy set is a FAIL, not an empty pass)"

# Entries: lines starting with a letter (same rule as the Makefile's
# `sed -n '/^[A-Za-z]/p'` — keep the two readers identical).
mapfile -t entries < <(sed -n '/^[A-Za-z]/p' "$MANIFEST" | sed -e 's/\r$//' -e 's/[[:space:]]*$//' | grep .) || true
[[ ${#entries[@]} -gt 0 ]] || fail "copy-set manifest $MANIFEST_REL lists no files — an empty copy set is a FAIL, not a vacuous pass"

drift=0
for f in "${entries[@]}"; do
  case "$f" in
    *.lean) ;;
    *) echo "  SYNC: manifest entry '$f' is not a .lean basename" >&2; drift=$((drift + 1)); continue ;;
  esac
  src="$SRC_DIR/$f"; gen="$GEN_DIR/$f"
  if [[ ! -f "$src" ]]; then
    echo "  SYNC: hand-written source missing: lean_frontend/$f (listed in $MANIFEST_REL)" >&2
    drift=$((drift + 1))
  elif [[ ! -f "$gen" ]]; then
    echo "  SYNC: generated copy missing: lean_frontend/generated/$f (run make lean-prelude-src)" >&2
    drift=$((drift + 1))
  elif ! cmp -s "$src" "$gen"; then
    echo "  SYNC: hand-written source lean_frontend/$f not propagated to generated/ (run make lean-prelude-src)" >&2
    drift=$((drift + 1))
  fi
done

# Reverse direction: every top-level hand-written .lean must be listed.
unlisted=0
while IFS= read -r -d '' p; do
  b="${p##*/}"
  listed=0
  for f in "${entries[@]}"; do [[ "$f" == "$b" ]] && { listed=1; break; }; done
  if [[ $listed -eq 0 ]]; then
    echo "  SYNC: lean_frontend/$b exists but is NOT in $MANIFEST_REL — it would never be propagated to generated/" >&2
    unlisted=$((unlisted + 1))
  fi
done < <(find "$SRC_DIR" -maxdepth 1 -type f -name '*.lean' -print0 | LC_ALL=C sort -z)

if [[ $drift -gt 0 || $unlisted -gt 0 ]]; then
  first="$(for f in "${entries[@]}"; do
             [[ -f "$SRC_DIR/$f" && -f "$GEN_DIR/$f" ]] && cmp -s "$SRC_DIR/$f" "$GEN_DIR/$f" && continue
             echo "$f"; break; done)"
  if [[ -n "$first" ]]; then
    fail "hand-written source lean_frontend/$first not propagated to generated/ (run make lean-prelude-src) — $drift drift(s), $unlisted unlisted file(s)"
  else
    fail "$unlisted hand-written lean_frontend/*.lean file(s) not listed in $MANIFEST_REL (manifest drifted from the tree)"
  fi
fi

[[ $QUIET -eq 1 ]] || echo "check_handwritten_sync: OK (${#entries[@]} hand-written files byte-identical to lean_frontend/generated/; manifest $MANIFEST_REL)"
