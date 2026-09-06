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
| spec-lab families | Complete observations/statuses in the shared `speclab_pair`; sequence retained | Each existing model prediction still requires exactly one value/UB outcome. Libc form2 also checks the complete printed result against the model's output prediction. |
| libc-exec, libxml2 URI/chvalid | Validate full observations/statuses before exact printed-output/baseline comparison | These existing baselines additionally pin the printer spelling. Full captures/statuses remain available. |
| bytes | Validate full observations/statuses before the reference check | Committed numeric exit-byte expectations require empty semantic stdout and a single Defined result; negative pins require a completed Error at the specified input line. |
| immaculate | Validate full semantic observations/statuses before historical token/baseline comparison | Existing negative pins distinguish inherited differences. `MATCH | L=CRASH` is only a legacy coarse failure-class pin, not semantic success or exact diagnostic equivalence; only recognized internal-failure forms at 125/134 with no batch prefix qualify. Timeouts, arbitrary exits and malformed records cannot use that exception. |
| GCC | Decode the complete Lean observation and check completion first | Native integer exit membership, modulo 256, under the existing native-side applicability/triage contract; raw semantic bytes retained even when this projection does not compare them. |
| litmus engine parity | Set of complete verdicts, explicitly unordered and duplicate-insensitive like exhaustive exploration | The independent reference uses a second, coarser value/UB set projection. Failure messages stay exact in engine parity. Sequence/multiplicity are retained in the raw/full record, but not asserted equal across the two schedulers. |
| pristine vs fork | Complete verdict comparison under each input's declared mode | Intentional shared-model/interface changes require a named manifest entry, never automatic rebaselining. |

Internal JSON evidence represents bytes as hex/base64 with an explicit schema
version. Canonical display tokens re-escape decoded bytes deterministically.
Canonicalization changes spelling only; it never drops or rewrites a byte.

## Caller and wrapper inventory

The executable-source inventory covers `scripts/` and `tests/` in the owned
mainline tree. `fuzz_csmith.sh`, `test_csmith_corpus.sh` and
`creduce_interestingness.sh` invoke `test_exec.sh`, so they inherit its codec;
none has a second verdict extractor. The csmith campaigns remain excluded
from execution under the user's ownership instruction. The owned future
`csmith_explore.sh` oracle-only yield classifier now uses the same saved
capture/status decoder, replacing its hand-copied expected-exit guess; no
campaign was run to validate it.

`tests/parity-probes/run_probe.sh`, a separate non-gating instrument copied
from the CI extractor, now uses shared full captures/statuses and checks
driver freshness. It retains reporting-only exit semantics and can print
AGREE only for complete equal observations. The six `test_speclab*.sh`
legacy extractors and the three libc form2 paths now share
`speclab_observations.sh`. Bytes, libc-exec, immaculate and both libxml2
execution lanes validate their complete saved streams before their narrower
reference/baseline checks. Parse/core/elab lanes compare different artifacts
(frontend acceptance or syntax dumps), not plain batch verdicts; they do
not use this decoder. Their status handling remains a separate ladder check.

`test_unit.sh` calls the hermetic codec/release/independent-oracle tests and
the historical `test_exec.sh --selftest`. Hang/kill/fuel plants invoke the
real classifying lanes. The old `extract_verdict_seq`/`expected_exit_for`
names remain solely for historical extractor selftests; no production lane
calls them. Documentation mentions and the selftest's deliberately broken
pre-repair extractor are historical examples, not execution paths.

The initial six actual-entry plant sets passed 27/27. Additional actual-entry
plants cover bytes, libc-exec, URI, immaculate and every spec-lab family:
40/40 passed across the first run and corrected fixture reruns. The fixture
corrections made byte injection cover nonempty stdout and made the bytes
lane's oracle-status plant target its actual Cabs bridge. Final Tier B runs
all 67 cases together using the latest fixture implementation.

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
