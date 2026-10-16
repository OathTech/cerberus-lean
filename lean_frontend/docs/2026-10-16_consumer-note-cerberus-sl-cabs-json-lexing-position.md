# Consumer note for cerberus-sl: the Cabs JSON position gains the lexing pair (2026-10-16)

Status: NOTE for the consumer cerberus-sl, written at the landing of
`feature/cabs-json-pp-position` ([USER 2026-10-16] approved the slice, filed by
the consumer cerberus-caesium; its own note is
`2026-10-16_consumer-note-cerberus-caesium-cabs-json-pp-position.md`). Nothing
here changes before cerberus-sl re-pins.

## What changed

Every position in the Cabs JSON export (`--cabs-json`, `backend/lean_export/cabs_json.ml`
`json_of_pos`) carries two more fields beside the unchanged source triple:

| field | value | OCaml origin |
|---|---|---|
| `file`, `line`, `col` | unchanged: the source file and line after cpp's `#line` mapping, and the column | `Cerb_position.file`/`line`/`column` |
| `lexing_file` | the input path the driver handed the C lexer, constant across a translation unit | `(Cerb_position.to_file_lexing p).pos_fname` |
| `lexing_line` | the line in the preprocessed stream the lexer read | `(Cerb_position.to_file_lexing p).pos_lnum` |

The Lean importer (`lean_frontend/CabsImport.lean` `jsonToPos`) REQUIRES all five
fields; `CerbLocation.Pos` gains `lexingFile : String` and `lexingLine : Nat`.
No printer, lane verdict or order changes (the Tier A rows at the landing are the
witness); `Pos` equality now compares the lexing pair too, as OCaml structural
equality on `Cerb_position.t` always did.

## What it means for cerberus-sl at its next re-pin

1. The 114 committed artefacts under `corpus/cabs/*.cabs.json` carry the
   three-field positions. The importer at the new pin refuses each with
   `getField: missing field 'lexing_file' in …` (fail-closed by design; there
   is no compatibility mode, because the exporter and the importer move
   together under one pin). Regenerate them with the pinned oracle's
   `--cabs-json` as part of the re-pin, the way the pin's own
   `tests/fixtures/*/cabs.json` were regenerated in this slice.
2. Quoted `Pos` literals of the shape `{ file := …, line := …, col := … }`
   (about 300 files under `Corpus/`) no longer elaborate: the structure has
   five fields. Extend them with `lexingFile`/`lexingLine` taken from the
   regenerated JSON, or derive the captures from the JSON instead of quoting
   them.
3. Nothing else: the JSON schema is otherwise unchanged, `file`/`line`/`col`
   are byte-identical to the previous export for the same input, and the
   driver's behaviour is unchanged.

Provenance: [AGENT] note; the slice's decisions are recorded in its commit.
