# Validation observation contract, version 1

2026-09-05 [AGENT], implementation contract for validation-foundations G1.
This specifies the existing plain batch protocol, not a new semantic API.

## Capture and parsing

Capture engine stdout, engine stderr and the original process status before
any filtering or shell negation. Keep raw files, including empty files and
partial output, for every attempted run. Engine stderr is diagnostic output;
the `stderr` field inside a batch verdict is the modeled C program's output.
They are different channels. A status-only scoreboard cannot replace them.

Parse stdout as bytes. Do not pass raw observations through shell variables
before saving them: shells cannot represent NUL and strip trailing newlines.
The parser recognizes these exact records:

- `Defined`: `value`, `stdout`, `stderr`, `blocked` (true or false).
- `Undefined`: `ub`, `stderr`, `loc`.
- `Error`: the entire `msg` payload, including any literal quotes.
- `EXECUTION n:` framing for multiple results, with contiguous indices from
  zero and exactly one verdict per header. The legacy annotated header
  `EXECUTION n (exit = ...):` is accepted only as framing, not as another value.

The Defined stdout/stderr and Undefined stderr fields use OCaml
`String.escaped`: quote/backslash, n/t/r/b short escapes and three **decimal**
digits per other byte. Decode them to bytes, never Unicode scalars; reject
invalid escapes and decimal values above 255. Value, UB and location are
printed directly by the existing drivers. Error messages are also printed
directly, not String.escaped; preserve the bytes instead of interpreting
backslashes as an encoding. Unknown fields/variants, missing fields, malformed
framing, unknown stdout lines and truncated records are protocol failures.

Source: `backend/common/driver_ocaml.ml:string_of_batch_output` and
`lean_frontend/Main.lean:runPipeline`. Neither plain batch format includes
the killed state's stdout, nor does Error expose its internal stderr field.
The codec cannot recover absent observations; this is an explicit printer
boundary, not permission to claim full final-state equivalence. The protocol
also has no announced total outcome count: a complete-record suffix removed
by a faulty transport with a forged successful status is undetectable here.

## Completion and failure

`backend/driver/main.ml:runM` and Lean's batch runner return 0 for a single
Defined record, 1 for a single Undefined/Error, and 0 for multiple results.
The Specified C return value is payload, not the engine process status.
Require the actual status to agree with that protocol. Timeout, signal,
cap kill, malformed/empty output, fuel exhaustion and partial exploration
never become agreement because a preceding verdict parsed successfully.

For native GCC execution, exit status is the C result modulo 256. In
particular 137 alone is not an OOM witness. Retain the existing elapsed-time
and cap-witness classification in that separate native protocol.

Concurrency's existing internal-failure comparison is a separate, explicit
policy: recognize the oracle's `internal error:` and Lean's `failwithIImpl`
panic forms only with their actual failure statuses and no successful batch
records. Preserve the complete failure message. Never accept a valid verdict
followed by either failure form. Fuel failures stay incomplete exploration.

## Comparison matrix

| Lane | Primary comparison | Additional projection/boundary |
|---|---|---|
| exec, CI sweep, CN, multi-TU | Ordered sequence of complete decoded verdicts; multiplicity retained | UB mismatch classification may erase UB payload to classify a difference, never to call it agreement. Existing explicit refusal exceptions require separate accounting. |
| verify main/call | Complete observations and valid process completion | The committed call-point pin projects the single return value/UB payload; it cannot replace the full engine comparison. |
| GCC | Decode the complete Lean observation and check completion first | Native integer exit membership, modulo 256, under the existing native-side applicability/triage contract; raw semantic bytes retained even when this projection does not compare them. |
| litmus engine parity | Set of complete verdicts, explicitly unordered and duplicate-insensitive like exhaustive exploration | The independent reference uses a second, coarser value/UB set projection. Failure messages stay exact in engine parity. Sequence/multiplicity are retained in the raw/full record, but not asserted equal across the two schedulers. |
| pristine vs fork | Complete verdict comparison under each input's declared mode | Intentional shared-model/interface changes require a named manifest entry, never automatic rebaselining. |

Internal JSON evidence represents bytes as hex/base64 with an explicit schema
version. Canonical display tokens re-escape decoded bytes deterministically.
Canonicalization changes spelling only; it never drops or rewrites a byte.

## Main.batchEscape producer trace

`Main.runPipeline` renders `dres_stdout`/`dres_stderr`, populated by
`Driver.finalize` from the IO dlist. `driver_fs_step.update_stdout` and
`update_stderr` append `String.ofList out_chars`; FS_WRITE and printf-family
results provide those character lists. Thus this path is intended to encode
one model byte per Char, explaining the printer's decimal-byte implementation.
The generic Lem String representation and other uses of `batchEscape` (for
example a frontend JSON parse error) are different producers. Their byte
correctness is not established by the IO trace. Record any out-of-range
escape as a source/printer finding; do not add Unicode normalization to hide
it. G6 and the later byte-representation work own the deeper semantics.
