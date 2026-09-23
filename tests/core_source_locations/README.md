These fixtures are printed by `parsers/core/location_controls/controls.ml`
with `Pp_core.WithSourceLocations`; their native print/parse/print check is
part of the Core parser unit lane. The Lean unit checks independently name
all expected location constructors, cursors, empty annotation lists, distinct
direct action/failure locations, list nodes and sequencing shape. The negative
fixtures must fail parsing in both implementations. Hex is UTF-8 JSON in the
existing Cabs location schema, enclosed in Core's literal-string delimiters.

This format transports expression-body source locations, not omitted file
metadata or preprocessor-internal Lexing offsets. Libc metadata still comes
from the original thirteen C translation units.
