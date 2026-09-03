# main/ — Main.lean batch renderers vs driver_ocaml.ml probes (Z2, 2026-09-03)

Engines and binaries as in `../mem/README.md`. Lines VERBATIM (`cat -v` view of
the Lean lines, since Lean emits raw control bytes). Classes are [AGENT].

| Probe | Mode | What it tests | fork oracle | upstream | Lean (`cat -v`) | Class | Proposed lane |
|---|---|---|---|---|---|---|---|
| `stdout_escape.c` | libc | `Main.lean:366-373 batchEscape` (escapes only `"` `\` `\n` `\t` `\r`) vs `driver_ocaml.ml:101` `String.escaped stdout` (OCaml `Bytes.escaped`: `\b` → `\b`; other non-printables and EVERY byte ≥ 0x7F → decimal `\ddd`) | `Defined {value: "Specified(0)", stdout: "a\bb\007\127\195\169\011\012\027\|\n", stderr: "", blocked: "false"}` | same | `Defined {value: "Specified(0)", stdout: "a^Hb^G^?M-CM-^CM-BM-)^K^L^[\|\n", stderr: "", blocked: "false"}` — raw control bytes, and the two program bytes `C3 A9` emitted as FOUR bytes `C3 83 C2 A9` (each byte-char re-encoded as UTF-8 on output) | **BUG-FIX** (stdout bytes are verdict content; the `Defined` line differs byte-wise) | libc_exec / exec nolibc pinned MATCH after the fix (`printf` is a Core builtin, so both modes) |
| `stderr_escape.c` | libc | same for the `stderr:` field | `Defined {value: "Specified(0)", stdout: "", stderr: "E\b\007\255\|", blocked: "false"}` | same | `Defined {value: "Specified(0)", stdout: "", stderr: "E^H^GM-CM-?\|", blocked: "false"}` | **BUG-FIX** (same row) | same |

Both rows are classified `AGREE-TOKENS LINE-DIFF` by `../run_z2.sh` (the
`value:` token agrees; the line does not). Fix (S): escape by CHARACTER CODE
over the string's chars (each char is one program byte 0..255 in the Lean
io model — the double-encoding shows the chars ARE the bytes): `"`→`\"`,
`\`→`\\`, `\n`/`\t`/`\r`/`\b`, printable 0x20..0x7E verbatim, everything
else `\` + 3-digit decimal — `_opam/lib/ocaml/bytes.ml` `unsafe_escape`
classes, cite them in-code.
