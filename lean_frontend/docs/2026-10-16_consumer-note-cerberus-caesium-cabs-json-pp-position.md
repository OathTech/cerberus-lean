# Consumer note for cerberus-caesium: the Cabs JSON position carries the lexing position (2026-10-16)

From: the `feature/cabs-json-pp-position` worker [AGENT]. Slice approved by the operator
[USER 2026-10-16]; it answers filing 2 of cerberus-caesium's plan
(`docs/2026-10-15_caesium-target.md`, addendum 2026-10-16): the port had been reconstructing
the preprocessed-file position from cpp's line map itself; the bridge now carries it.

## 1. What changed

A Cabs JSON position object (`backend/lean_export/cabs_json.ml` `json_of_pos`) was
`{"file", "line", "col"}`: the SOURCE file and line after cpp's `#line` mapping
(`Cerb_position.file`/`line`) and the column (`Cerb_position.column`). It now also carries
the LEXING position — the position in the preprocessed stream the C lexer read
(`Cerb_position.to_file_lexing`, util/cerb_position.ml:27; the `file : Lexing.position`
field of `Cerb_position.t`, :7-11):

| key | OCaml value | meaning |
|-----|-------------|---------|
| `"file"` | `Cerb_position.file p` | source file (unchanged) |
| `"line"` | `Cerb_position.line p` | source line, 1-based (unchanged) |
| `"col"` | `Cerb_position.column p` | column, 1-based = `1 + pos_cnum - pos_bol` of the lexing position (unchanged; one column serves both views) |
| `"lexing_file"` | `(to_file_lexing p).pos_fname` | NEW — the lexer's file name (the input file the driver was given; the preprocessed stream is attributed to it) |
| `"lexing_line"` | `(to_file_lexing p).pos_lnum` | NEW — the line in the preprocessed stream |

Example. For the input `ex.c`

```c
#line 100 "orig.c"
int main(void) {
  return 0;
}
```

the identifier `main` is exported as (the builtins prelude cpp prepends puts the
function at preprocessed line 21):

```json
{"file": "orig.c", "line": 100, "col": 5, "lexing_file": "ex.c", "lexing_line": 21}
```

Before this slice the same position was `{"file": "orig.c", "line": 100, "col": 5}`.
Positions without a `#line` mapping carry the same file in both fields and the same line
in both fields (`Cerb_position.from_lexing`).

Key order within the object is as in the table; consumers must not depend on it (the Lean
importer does not).

## 2. The Lean side

- `CerbLocation.Pos` (lean_frontend/CerbLocation.lean) gains `lexingFile : String` and
  `lexingLine : Nat` after `file`, `line`, `col`. Anonymous-constructor patterns and
  structure literals over `Pos` need the two extra fields; field-name access is unaffected.
- `CabsImport.jsonToPos` reads all five fields FAIL-CLOSED: a missing or ill-typed
  `lexing_file`/`lexing_line` is an error exactly as a missing `col` is. There is no
  compatibility mode — the exporter and the importer move under one pin, so a document
  exported by an older oracle is refused as a stale bridge artefact (the `digest`-field
  rule of 2026-09-22 has the same shape). Regenerate every Cabs JSON you keep with the
  re-pinned oracle; the ten committed goldens `tests/fixtures/*/cabs.json` were.
- Positions the Core text parser stamps (`CoreParser.lean`) mirror
  `Cerb_position.from_lexing`, as the OCaml Core lexer/parser do (parsers/core/core_lexer.mll:205,
  core_parser.mly:18): lexing file/line = source file/line.
- Unit test `cabs-import-test` (`test/Unit/CabsImportTest.lean`, Tier A row 1): the
  five-field import, the refusals (missing field, wrong type, negative, non-integer, the
  old three-field shape), a lossless cursor-bearing region, printer invariance, the equality
  pins below, and a walk of the committed fixture.

## 3. No behaviour change otherwise

- Every location printer reads the source triple, as the OCaml's do (`location_to_string`
  util/cerb_location.ml:188-237, `simple_location` :476-491): the text the differential
  lanes compare is byte-identical. `getFilename`, `isLibraryLocation` and the bounding-box
  order `posLt` read the source triple too; `Main.refuseLibraryLocations` still collects the
  SOURCE file names only, because the oracle's `is_library_location` tests `get_filename` =
  `Cerb_position.file` (:512-523) and never the lexing file name.
- Equality. The derived `BEq Pos` now compares all five fields. This is the OCaml mirror,
  not a divergence: lem's `Loc.t` declares no `Eq` instance (frontend/model/loc.lem), so lem
  `=` on a location is OCaml's structural `(=)` over the whole `Cerb_position.t` record,
  lexing position included; within one lexing of a preprocessed stream the lexing
  (file, line) and the column determine `pos_bol`/`pos_cnum`, so two `Pos` are equal iff
  the OCaml positions are. (Before, Lean identified positions that differ only in the
  preprocessed line — one source line reached through two `#line` regions — which the
  OCaml distinguishes.) `Ord Pos` compares in field order (source triple, then the lexing
  pair); OCaml's `compare` orders by the lexing position first — a field-order difference
  inside the already declared cosmetic `Ord Loc` divergence (no differential output
  enumerates a Loc-keyed set). Both are documented on `Pos`.
- Field names [AGENT]: `lexing_file`/`lexing_line` (Lean `lexingFile`/`lexingLine`) mirror
  `Cerb_position.to_file_lexing` and `Lexing.position`'s `pos_fname`/`pos_lnum`; `pp_*` was
  not used because "pp" means pretty-printing throughout this repository (`--pp-core`,
  `CerbPP.lean`).

## 4. When you see it

At your next re-pin of cerberus-lean (the landing commit of `feature/cabs-json-pp-position`
onto `mdd/cerberus-lean`): the oracle you build from that commit exports the two fields and
the Lean engine of the same commit requires them. Until then your `LineMap.lean`
reconstruction stays as it is; after it, `Pos.lexingFile`/`Pos.lexingLine` carry the values
directly, and the fail-closed-on-ambiguity reconstruction can be retired or kept as a
cross-check.
