# SC prototype litmus seeds

These C programs and the scalar transcription were salvaged from
`arc/validation-foundations-concurrency` at
`86a2aea547804b78eb7f1eae633bb9c24c713b7f`. Program headers retain their
historical provenance; references to the September 4 charter and its support
claims are historical. The current authority is
[the September 21 charter](../../lean_frontend/docs/2026-09-21_charter-sc-prototype.md).

`scripts/test_litmus.sh --check` executes both fork engines exhaustively with
`--concurrency=sc`. It compares complete observations (values, output bytes,
blocked state, UB locations and error payloads) using the current shared codec,
then compares the weaker reference projection in `expectations.txt`. Original
exit statuses are preserved. A crash or incomplete exploration cannot become a
successful execution merely by printing a verdict first. A deliberately matched
internal model failure is recognizable by the codec, but none of the current
support targets accepts an internal failure.

The lane is expected to be red until the implementation and unresolved targets
are completed. It does not rewrite expectations from engine output. Pristine
upstream's broken concurrency driver is not described as an execution oracle;
"oracle" in capture filenames means the fork OCaml side of the differential.

`sc_reference.py` is an independently coded finite scalar interleaving
enumerator with hand-transcribed programs. It derives only the `SC` rows.
Its result contains return values for race-free schedules and a race token
when a schedule races. A mixed set is **not** a claim that the program is
defined: upstream `behaviour` quantifies over all consistent executions. This
enumerator is neither a C parser nor a mechanized equivalence to Cmm or ISO C.
It covers no byte/provenance composition, allocation/lifetime integration,
fences, arbitrary expressions, or infinite executions. Those limitations belong
to this instrument, not the executable language.

`RMW` rows retain upstream compare-exchange expectations recorded in their C
headers. `NONSC` rows require refusal of weak orders, avoiding silent
strengthening in SC mode. `PENDING` rows always fail the lane and give no support
credit. In particular, the old blanket refusal of the all-SC fence example is
not accepted as completed implementation. The fence example with relaxed
accesses remains outside the SC mode for those accesses.

`--selftest` runs hermetic plants against the actual lane helpers and codec
without builds or an SC engine. Controls must pass; malformed output, status
124/137, duplicate rows (including identical duplicates), unterminated orphan
rows, missing files, unknown classes and pending targets must fail. `--plant`
also requires a green execution control before corrupting a target and testing
an empty corpus through both execution and comparison paths. These are harness
tests, not concurrency semantics evidence.

The old sequential spawn-refusal check was deliberately not ported. Current
sequential behavior remains the conservativity reference. The old
`before_baseline.txt` and automatic rerecording mode were also not ported: prior
measurements remain in the donor history, and new support expectations require
an independently justified change.
