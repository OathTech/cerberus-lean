#!/usr/bin/env bash
# check_impl_profile.sh -- the implementation-profile witness lane (contract D20; ladder
# row 1 via test_unit.sh; record lean_frontend/docs/2026-11-22_impl-profile-record.md).
#
# The implementation profile is selected once on each engine (`--impl-profile=default|hafnium`)
# and read by every phase. This lane is the ONLY validation of the hafnium profile (plain char
# unsigned): 22 programs under BOTH profiles, both engines exhaustive, each verdict equal byte
# for byte to gcc's under -funsigned-char / -fsigned-char; the mixed-configuration refusals;
# pristine upstream's recorded answers under HafniumImpl as the negative control; the libc
# sources' Core identical under both profiles. Engine and format: scripts/impl_profile_witness.py.
#
#   check_impl_profile.sh                         the run
#   check_impl_profile.sh --selftest              the plants on the recorded observations, then the run's verdict
#   check_impl_profile.sh --pristine-live PREFIX  also re-derive tests/impl_profile/pristine_hafnium.tsv from a
#                                                 pristine upstream installation (optional instrument; needs ocamlfind)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_cerberus
exec python3 -I "$PROJECT_ROOT/scripts/impl_profile_witness.py" "$@"
