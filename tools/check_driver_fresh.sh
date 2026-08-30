#!/bin/bash
# check_driver_fresh.sh — driver-binary freshness stamps (trust-basket
# item a, 2026-08-31; the lem-sync stamp's sibling for the two DRIVER
# BINARIES).
#
# THE HAZARD (parity-detective report §1, docs/2026-08-30_parity-
# detective-report.md): a primed worktree carries driver binaries that
# silently LAG the checkout they sit next to — the detective found BOTH
# primed binaries stale vs mainline sources (missing --args, missing
# --batch-alloc-census, pre-offsetof-fix). A differential sweep against
# a stale binary FABRICATES results. "The worktree is primed" is not
# evidence.
#
# MECHANISM: at build time a stamp records, per binary,
#   commit <git HEAD sha>[ +dirty]      (informational ONLY — content-
#                                        identical worktrees on different
#                                        commits are legitimately fresh;
#                                        the hashes are the comparison)
#   bin <sha256 of the binary itself>
#   src <sha256 over the source set that feeds the binary>
# A check recomputes both hashes: bin mismatch = a binary this tree's
# build did not record (foreign/primed/manually rebuilt without
# re-recording); src mismatch = sources changed since the record (the
# binary is STALE). Either way the answer is a loud refusal, never a
# silent sweep.
#
# STAMPS (gitignored, like the lem-sync stamps):
#   $ROOT/driver_fresh.oracle.sha256     — _build/default/backend/driver/main.exe
#   $ROOT/driver_fresh.lean.sha256       — lean_frontend/.lake/build/bin/cerberus-lean
# Deliberate divergence from "next to each binary": foreign files under
# _build are the documented dune-tamper hazard (lean_frontend/CLAUDE.md
# Build caveat) and lake/dune clean would silently delete the stamp;
# root placement mirrors ocaml_frontend/lem_sync.sha256.
#
# SOURCE SETS (over-approximations are deliberate — a comment edit makes
# the binary stale by definition until a rebuild re-records):
#   oracle: dune-project + all dune/*.ml{,i,l,y}/*.lem/*.c/*.h under
#           backend/ frontend/ memory/ ocaml_frontend/ parsers/
#           sibylfs/ util/ (includes the lem-generated OCaml tree).
#   lean:   lean_frontend/lean-toolchain + lean_frontend/{lakefile.toml,
#           lake-manifest.json} + lean_frontend/*.lean (hand-written) +
#           generated/**.lean + relsemcore/**.lean + native/*.{c,o}
#           (the untracked-.o gotcha: a native/*.c edit or a rebuilt .o
#           changes the hash and demands a relink+re-record).
# Declared non-goals (same class as the lem-sync stamp's): the opam
# switch / Lean toolchain binaries and the Lake packages tree are not
# hashed (the manifest pin is the identity); runtime files staged under
# _build/install are covered indirectly via their sources.
#
# WIRING (scripts/common.sh): build_cerberus/build_lean --record-* on
# every successful build; when a lane is invoked with SKIP_BUILD=1,
# common.sh runs --check at source time for every present binary
# (a missing binary is left to the lane's own existence checks — it
# cannot fabricate results). Override for INTENTIONAL cross-version
# runs: CERB_DRIVER_FRESH_OVERRIDE=1 — loud on every use, never quiet.
#
# Usage: tools/check_driver_fresh.sh [--root DIR] \
#          --record-oracle|--record-lean|--check[-oracle|-lean]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    --record-oracle|--record-lean|--check|--check-oracle|--check-lean) MODE="${1#--}"; shift ;;
    *) echo "check_driver_fresh: unknown argument '$1'" >&2; exit 2 ;;
  esac
done
[[ -n "$MODE" ]] || { echo "usage: check_driver_fresh.sh [--root DIR] --record-oracle|--record-lean|--check[-oracle|-lean]" >&2; exit 2; }

ORACLE_BIN="$ROOT/_build/default/backend/driver/main.exe"
LEAN_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
ORACLE_STAMP="$ROOT/driver_fresh.oracle.sha256"
LEAN_STAMP="$ROOT/driver_fresh.lean.sha256"

# Hash a NUL-sorted, path-labeled file set (same shape as
# tools/check_lem_sync.sh hash_set: relative paths => location-
# independent, so content-identical worktrees agree).
hash_files() {  # stdin: NUL-separated relative paths; cwd $ROOT
  LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1
}

oracle_src_hash() {
  (cd "$ROOT" && { printf 'dune-project\0'; \
    find backend frontend memory ocaml_frontend parsers sibylfs util \
      -type f \( -name dune -o -name '*.ml' -o -name '*.mli' \
      -o -name '*.mll' -o -name '*.mly' -o -name '*.lem' \
      -o -name '*.c' -o -name '*.h' \) -print0; } | hash_files)
}

lean_src_hash() {
  (cd "$ROOT" && { printf 'lean_frontend/lean-toolchain\0'; \
    printf 'lean_frontend/lakefile.toml\0'; \
    printf 'lean_frontend/lake-manifest.json\0'; \
    find lean_frontend -maxdepth 1 -type f -name '*.lean' -print0; \
    find lean_frontend/generated lean_frontend/relsemcore \
      -type f -name '*.lean' -print0 2>/dev/null; \
    find lean_frontend/native -type f \( -name '*.c' -o -name '*.o' \) \
      -print0 2>/dev/null; } | hash_files)
}

bin_hash() { sha256sum "$1" | cut -d' ' -f1; }

commit_id() {
  local c dirty=""
  c="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  [[ -z "$(git -C "$ROOT" status --porcelain 2>/dev/null | head -1)" ]] || dirty=" +dirty"
  echo "$c$dirty"
}

record() {  # <side> <bin> <stamp> <src_hash_fn>
  local side="$1" bin="$2" stamp="$3" srcfn="$4"
  [[ -f "$bin" ]] || { echo "check_driver_fresh: cannot record $side — binary missing: $bin" >&2; exit 1; }
  local b s
  b="$(bin_hash "$bin")"
  s="$($srcfn)"
  printf 'commit %s\nbin %s\nsrc %s\n' "$(commit_id)" "$b" "$s" > "$stamp"
  echo "check_driver_fresh: recorded $side stamp (bin $b, src $s)"
}

fail_stale() {  # <side> <reason>
  echo "CERB_DRIVER_STALE: $1 driver binary failed the freshness check: $2" >&2
  cat >&2 <<'EOF'
CERB_DRIVER_STALE: a driver binary is not the product of this source tree.
Running a differential lane against it would FABRICATE results (the
parity-detective's §1 finding: primed worktree binaries silently lag
their checkout). Remediate by rebuilding the stale side:
    scripts/ce bash -c 'source scripts/env.sh; :'   # env, then:
    oracle: opam exec --switch=. -- dune build backend/driver/main.exe \
              cerberus-lib.install && opam exec --switch=. -- dune install \
              cerberus-lib && opam exec --switch=. -- dune build cerberus.install
    lean:   make lean-prelude-src && cd lean_frontend && ../scripts/capped lake build
then re-record: tools/check_driver_fresh.sh --record-oracle / --record-lean
(scripts/common.sh build_cerberus/build_lean do build+record in one step).
For an INTENTIONAL cross-version run only: CERB_DRIVER_FRESH_OVERRIDE=1
(loud on every use).
EOF
  exit 1
}

check_side() {  # <side> <bin> <stamp> <src_hash_fn>
  local side="$1" bin="$2" stamp="$3" srcfn="$4"
  if [[ "${CERB_DRIVER_FRESH_OVERRIDE:-0}" == "1" ]]; then
    echo "CERB_DRIVER_FRESH_OVERRIDE ACTIVE: skipping $side driver freshness check — results are only meaningful for a deliberate cross-version run" >&2
    return 0
  fi
  [[ -f "$bin" ]] || fail_stale "$side" "binary missing: $bin"
  [[ -f "$stamp" ]] || fail_stale "$side" "stamp $(basename "$stamp") missing — binary provenance unknown (primed tree or build outside scripts/common.sh; a missing stamp is a FAIL, not a pass)"
  local want_bin want_src have_bin have_src
  want_bin="$(awk '$1=="bin"{print $2}' "$stamp")"
  want_src="$(awk '$1=="src"{print $2}' "$stamp")"
  [[ -n "$want_bin" && -n "$want_src" ]] || fail_stale "$side" "stamp $(basename "$stamp") is malformed"
  have_bin="$(bin_hash "$bin")"
  [[ "$have_bin" == "$want_bin" ]] || fail_stale "$side" "binary is not the recorded build (stamp bin $want_bin, actual $have_bin) — foreign/primed binary, or rebuilt without re-recording"
  have_src="$($srcfn)"
  [[ "$have_src" == "$want_src" ]] || fail_stale "$side" "source tree changed since the binary was recorded (stamp src $want_src, tree $have_src) — the binary is STALE"
  echo "check_driver_fresh: $side OK (bin $have_bin, src $have_src)"
}

case "$MODE" in
  record-oracle) record oracle "$ORACLE_BIN" "$ORACLE_STAMP" oracle_src_hash ;;
  record-lean)   record lean   "$LEAN_BIN"   "$LEAN_STAMP"   lean_src_hash ;;
  check-oracle)  check_side oracle "$ORACLE_BIN" "$ORACLE_STAMP" oracle_src_hash ;;
  check-lean)    check_side lean   "$LEAN_BIN"   "$LEAN_STAMP"   lean_src_hash ;;
  check)
    check_side oracle "$ORACLE_BIN" "$ORACLE_STAMP" oracle_src_hash
    check_side lean   "$LEAN_BIN"   "$LEAN_STAMP"   lean_src_hash
    ;;
esac
