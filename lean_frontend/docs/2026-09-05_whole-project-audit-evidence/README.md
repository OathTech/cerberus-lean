# Whole-project audit evidence — artifact accounting

2026-09-06 [AGENT]. The 2026-09-05 archive named 22 artifacts. Ten original
files are present and match their recorded hashes; twelve historical logs
are missing. The documented local producer directory is absent. The legacy
csmith worktree was excluded from recovery searches. No missing log was
recreated, and no current release claim may rely on it.

[The inventory](artifact-inventory.json) records each original name, expected
hash and availability. [The original checksum list](SHA256SUMS.historical)
is preserved as historical evidence; it is not a passing integrity check.
[The original README](README.historical.md) is retained byte-for-byte,
including its dated claims and references to unavailable logs.

The current [SHA256SUMS](SHA256SUMS) checks the actual durable files in this
directory. A passing checksum check establishes their integrity, not the
truth of unavailable historical test results. Missing historical files are:

- `cerberus-lanes-summary.log`
- `cerberus-unit-tail.log`
- `fork-manifest-order.log`
- `fuel-decoy-policy.log`
- `fuel-decoy-table.log`
- `lem-comprehensive-summary.log`
- `lem-nonlean-after-build.log`
- `strict-lean-run.log`
- `strict-native-build.log`
- `strict-native-run.log`
- `strict-ocaml-run.log`
- `verdict-extractor-plant.log`

The strictness source reproducers and generated source snapshots remain
available here. New validation-foundations builds, probes and comparisons
are dated new evidence, separately archived in
[the execution record](../2026-09-05_validation-foundations-execution.md).
The independent oracle now has a cold upstream-Lem build and actual
execution comparisons; that evidence does not retrospectively certify the
historical archive.
