#!/usr/bin/env bash
# check_discarded_constructs.sh — row-1 witness for the constructs outside attributes that the front end
# accepted and silently discarded or misapplied (contract D19; record
# lean_frontend/docs/2026-11-20_attribute-preservation-record.md; census
# lean_frontend/docs/2026-11-20_discarded-constructs-census.md section 2).
#
# Witnesses: tests/discarded_constructs/*.c, pinned in expected.txt (gcc 13's answers in gcc.txt):
#   alignas_for_init*    FIXED: an alignment specifier on a for-init declaration is applied (C17 6.8.5#3; both
#                        engines answer gcc's 0), with the register and weaker-alignment constraints;
#   alignas_sizeof, _alignof, _cast, _atomic_typename
#                        the constraint violation of C17 6.7.5#2 (gcc rejects each);
#   alignas_compound_literal   REFUSED (Ail's compound literal has no alignment); the plain literal runs;
#   noreturn_*           FIXED: the operand of `return` in a _Noreturn function is evaluated before UB071
#                        (C17 6.7.4#8): an operand that is itself undefined reports ITS undefined behaviour, a
#                        function that really returns is still UB071 (the libc witness at gcc's exit status
#                        is tests/libc_exec/044-noreturn-return-operand-exits.c, Tier A row 5);
#   atomic_*             REFUSED: the _Atomic qualifier on a parameter of a function definition, and in the
#                        specifiers of a block-scope or parameter declaration with a derived declarator; the
#                        specifier form _Atomic(T), the plain object, the file-scope pointer and a pointer's
#                        own _Atomic qualifier keep answering as gcc does;
#   array_param_*        REFUSED: qualifiers inside the brackets of an array parameter of a function
#                        declaration; the qualified-pointer spelling answers as gcc does;
#   builtin_expect_*     FIXED: the forced header's macro parenthesises its parameter
#                        (runtime/libc/include/builtins.h; `__builtin_expect(u + 1, 0)` was `(long)u + 1`);
#   knr_*                the old-style definition with a wrapped declarator and a declaration list after a
#                        prototype stop with upstream's K&R diagnostic; the forms upstream supports run.
# Both engines; a refusal's text is pinned WHOLE. Negative control: pristine.txt (pristine upstream's measured
# line for every moved row); the `pristine` plant must fail exactly those rows.
#
# Usage: check_discarded_constructs.sh [--selftest]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
args=()
for a in "$@"; do
    case "$a" in
        --selftest) args+=(--selftest --require-plants=pristine,lean-fixed,refusal-truncated) ;;
        *) echo "check_discarded_constructs: unknown argument $a" >&2; exit 2 ;;
    esac
done
exec python3 "$ROOT/scripts/discard_witness.py" "$ROOT/tests/discarded_constructs" ${args[@]+"${args[@]}"}
