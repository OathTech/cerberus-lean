#!/usr/bin/env bash
# Matched inner_arg_temps lane. --gate runs the plants then the whole lane.
# --selftest, --rows REGEX, --observe and --record-baseline are focused tools;
# only --gate / an unselected baseline check certify the complete population.
# The Python instrument documents observations, limits and baseline classes.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
if [[ "${SKIP_BUILD:-0}" != 1 && -z "${CERB_ORACLE_BIN_OVERRIDE:-}" && -z "${CERB_LEAN_BIN_OVERRIDE:-}" ]]; then
    build_cerberus
    build_lean
fi
cd "$PROJECT_ROOT"
python3 scripts/inner_arg_temps_lane.py --oracle "$CERBERUS_BIN" \
    --lean "$CERBERUS_LEAN_BIN" --out "$OBSERVATION_RUN_DIR" "$@"
