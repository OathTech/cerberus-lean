#!/usr/bin/env bash
# check_attribute_carriage.sh — row-1 witness that every attribute the grammar accepts is CARRIED to Ail
# (contract D19; record lean_frontend/docs/2026-11-20_attribute-preservation-record.md; census
# lean_frontend/docs/2026-11-20_discarded-constructs-census.md section 1).
#
# Upstream's parser dropped the attribute specifier sequence in 19 of the 37 productions that accept one and
# its desugarer dropped it at 12 more sites, so a consumer that reads attributes got nothing for a contract
# written there. Since 2026-11-20 each attribute reaches the Ail slot of the entity it appertains to, or the
# sigma's carried_attributes table with its placement and declared identifier; no attribute is given a meaning.
#
# Witnesses: tests/attribute_carriage/*.c (419 programs), pinned in expected.txt:
#   t01-t10   the consumer's ten placements of [[rc::ensures("{False}")]] (refinedc-lean's
#             scripts/probes/discarded-contracts.py): the attribute reaches Ail at every one;
#   a*-s*     the census matrix: one program per grammar site and declared entity, the attribute's own syntax
#             (lists, repeated specifiers, namespaces, argument forms), the standard attributes, GNU syntax;
#   u_*       cerb::byte applies at both typedef placements (equal verdicts); the attribute declaration in a
#             for-init clause is refused; the u_addr_* rows are cerb::with_address rows (see y_*);
#   v01-v26   an object, function, typedef or tag declared more than once keeps the attributes of every
#             declaration; an attribute argument that
#             is not a plain string literal arrives as its tokens joined by single spaces, whatever its layout
#             (multi-line, with a comment, through a macro, with a prefix, with digraph brackets);
#   w07-w10   a clause with a bracket group is one argument, the tokens the source has;
#   x10-x17   the other attributes the model interprets (cerb::byte, cerb::hidden, cerb::magic) on every path
#             the slice newly delivers attributes on: the verdict equals pristine's, except the declared
#             cerb::byte typedef placement and the forms pristine rejected;
#   y_*       cerb::with_address is REFUSED at ONE point, the parser's `attribute` production (c_parser.mly),
#             wherever it is written and whatever its arguments: 32 placements x 5 argument shapes (none, one,
#             two, a bracket group, a prefixed literal), every one pinned to the same refusal text (a `parse`
#             row: the oracle parser's stop; no Cabs JSON exists for the Lean engine to read), with pristine's
#             verdict (it ran, or crashed in upstream's TODO) in the control; the earlier with_address rows
#             (u_addr_*, v19, v20, w01-w06, x01-x09) are pinned to the same text. Three controls must NOT be
#             refused: another namespace's with_address, the bare name, cerb::hidden.
# Both engines must print the same pinned `attribute:` lines (the Lem definition show_attribute_carriage: the
# oracle under --pp=ail --ast=ail, the Lean engine in its staged output), the pinned diagnostic for a stop,
# and the WHOLE refusal text for a refusal. Negative control: pristine.txt (what pristine upstream carried);
# every row it lists must differ from the pin, and the `pristine` plant must fail exactly those rows.
#
# Usage: check_attribute_carriage.sh              the row-1 cut (core.txt: 147 programs)
#        check_attribute_carriage.sh --selftest   plants, then the row-1 cut
#        check_attribute_carriage.sh --full       the whole matrix (Tier B)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
args=(--core)
for a in "$@"; do
    case "$a" in
        --selftest) args+=(--selftest --require-plants=pristine,lean-drops-carried,oracle-drops-carried,args-truncated,lean-fixed,refusal-truncated,parse-accepted) ;;
        --full) args=("${args[@]/--core}") ;;
        *) echo "check_attribute_carriage: unknown argument $a" >&2; exit 2 ;;
    esac
done
exec python3 "$ROOT/scripts/discard_witness.py" "$ROOT/tests/attribute_carriage" ${args[@]}
