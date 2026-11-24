#!/usr/bin/env bash
# check_impl_profile.sh -- the implementation-profile witness lane (contract D20; ladder
# row 1 via test_unit.sh; record lean_frontend/docs/2026-11-22_impl-profile-record.md).
#
# PREREQUISITE: gcc on the path (the pinned lines are gcc's and are re-derived on every run;
# the lane FAILS without gcc, it never skips), and `dune build cerberus.install` (the VIP
# driver is one of its witnesses).
#
# The implementation profile is a property of the RUN, selected on each engine by
# `--impl-profile=default|hafnium`, and read by the desugarer's constant evaluation, typing,
# elaboration, Core's signedness tests, the ranges and store/load -- not by the preprocessor
# or the parser. This lane is the ONLY validation of the hafnium profile (plain char
# unsigned): 28 programs under BOTH profiles, both engines exhaustive; 26 pinned to gcc under
# -funsigned-char / -fsigned-char; one bit-field refusal row; one preprocessor row (the
# engines agree with each other, gcc's line the declared difference); every Cabs export
# identical under the two profiles; the selector's refusals, the VIP driver's included;
# pristine upstream's recorded answers under HafniumImpl as the negative control; the libc
# sources' Core identical under both profiles. Engine and format: scripts/impl_profile_witness.py.
#
#   check_impl_profile.sh                         the run
#   check_impl_profile.sh --selftest              the plants, then the run's verdict
#   check_impl_profile.sh --pristine-live PREFIX  also re-derive tests/impl_profile/pristine_hafnium.tsv from a
#                                                 pristine upstream installation (optional instrument; needs ocamlfind)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_cerberus
[[ -n "${GCC_BIN:-}" && -x "${GCC_BIN:-}" ]] || command -v gcc > /dev/null 2>&1 || { echo "check_impl_profile: FAIL -- gcc not found on the path (a prerequisite of this lane, never skipped)" >&2; exit 1; }
exec python3 -I "$PROJECT_ROOT/scripts/impl_profile_witness.py" "$@"
