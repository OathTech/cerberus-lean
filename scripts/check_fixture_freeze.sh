#!/bin/bash
# check_fixture_freeze.sh — the differential-fixture-set integrity
# gate (2026-08-31 semantics-first split; formerly the corpus-freeze
# leg of check_proof_size.sh — the proof-layer legs of that gate left
# with the proof packages).
#
# lean_frontend/corpus/ is a pinned differential fixture set (see its
# README.md): test_verify.sh's pin-provenance, main-mode-differential,
# and --call expectation rows are all derived from these exact
# sources. This gate pins the set:
#   * every file in scripts/target_corpus.sha256 must hash-match;
#   * the directory's name set must be EXACTLY the manifest's files
#     + README.md (`ls -A`, so dotfiles and subdirectories count) —
#     additions are the same failure as modifications (the
#     addition-blindness closure, pre-merge audit 2026-08-29 obs (b)).
# Changing a fixture invalidates its tests/corpus/ pins and
# expectation rows — update manifest + pins + expectations together,
# in one commit, with rationale.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORPUS_DIR="$SCRIPT_DIR/../lean_frontend/corpus"

if ! (cd "$CORPUS_DIR" 2>/dev/null && sha256sum -c "$SCRIPT_DIR/target_corpus.sha256" --quiet 2>/dev/null); then
  echo "check_fixture_freeze: FAIL — fixture hash mismatch vs scripts/target_corpus.sha256 (see lean_frontend/corpus/README.md)"
  exit 1
fi
expected_names=$( { awk '{print $2}' "$SCRIPT_DIR/target_corpus.sha256"; echo "README.md"; } | LC_ALL=C sort)
actual_names=$(cd "$CORPUS_DIR" && ls -A | LC_ALL=C sort)
if [[ "$expected_names" != "$actual_names" ]]; then
  echo "check_fixture_freeze: FAIL — corpus/ name set differs from scripts/target_corpus.sha256 + README.md (see lean_frontend/corpus/README.md)"
  diff <(echo "$expected_names") <(echo "$actual_names") | sed 's/^/check_fixture_freeze:   /'
  exit 1
fi
echo "check_fixture_freeze: OK ($(awk 'END{print NR}' "$SCRIPT_DIR/target_corpus.sha256") fixture files match the pinned manifest; name set exact)"
