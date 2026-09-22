# Item-7 second-review evidence

[AGENT — independent reviewer, 2026-09-22]

Reviewed source: `b85f5bc83ed79554af3bd3bb4f4a16582917ccb5`, based on `df85e95b7b37826dfb3f2ac97a41473580f1e0b9`. The sibling audit document gives the findings, limits and proposed closure. No implementation or baseline changes are in this audit commit.

Verify this directory without the original worktree:

```sh
python3 verify_evidence.py
```

The verifier checks the complete file inventory against `SHA256SUMS`, every regular archive member, the release status/source identity, all 39 lane receipts against the report's hashes, all retained pristine capture hashes/statuses, oracle counts, native-assertion count and focused capture hashes. It does not rerun the models or turn reviewed source invariants into proofs.

Contents:

- `release-report.json`, `release-summary.txt`: unedited full-run report and summary. The report retains its original absolute invocation paths.
- `lane-receipts.tar.gz`: the exact stdout/stderr for each of the 39 commands.
- `pristine-reports.tar.gz`: B10.1, B10.2, B12 and the separate three-engine report; the latter's summary is the final three console lines, copied verbatim.
- `pristine-captures.tar.gz`: stdout/stderr/status and invocation JSON where present for each capture referenced by those reports. Synthetic plant captures need not have an invocation JSON.
- `focused-evidence.tar.gz`: regeneration/build recipe, logs and queue receipt; the native Lean package, successful logs and earlier probe-authoring failures; Core inputs, commands, raw stdout/stderr and result JSON for all three focused batches; derived summaries, diff and rebase analysis; full/three-engine console logs and the retention recipe.
- `reviewed-files.json`: base/head and SHA-256 of every changed file in the reviewed range.
- `worker-evidence-review.json`: derived analysis of the worker's committed rebased full-run report. Worker evidence is supplementary; the independent clean-head report above is authoritative for this audit run.
- `three-engine-reference.json`, `expected-lean-differences.json`: historical comparison with the independently reviewed run-digest head, audit commit `97c98bcce`. This is not a newly run A/B comparison against the exact item-7 base. The actual item-7 C5 report is in `pristine-reports.tar.gz`.

The focused Core collector is an evidence recorder, not a gate: its own exit 0 means collection completed. There are **380 valid invocations on 38 inputs** and **40 additional retained parser errors from reviewer-authored `==` syntax**. Those original four `run-*.core` files are superseded by `run-fixed-*.core`, which use `<`. `core-results.json` contains the original 300 invocations (260 valid, 40 instrument syntax errors); `core-results-run-fixed.json` contains the corrected 40; `adjacent-results.json` contains another 80. Eight valid invocations intentionally hit a bounded continuation-loop timeout; this is not counted as a successful model result. `summarize-focused.py` validates the historical batch layout and the claimed observations.

To inspect/reproduce focused witnesses in a separately rebuilt checkout of the reviewed source, extract `focused-evidence.tar.gz` under `.tmp/item7-audit/`. Use the commands recorded in each result row, adjusting the checkout/runtime prefix, or the CLI recipe in the audit. `core-probes.py` is the corrected collector: rerunning it replaces the historical first result file with the corrected 300-invocation batch, so preserve the recorded JSON before replaying; the historical summarizer's batch accounting must not be applied blindly to overwritten files.

To rebuild the native probe after rebuilding the reviewed semantics, from `.tmp/item7-audit/native/`:

```sh
CERB_MEM_MAX=8G /home/dev/projects/cerberus-lean-proj/scripts/ce \
  ../../../scripts/capped lake build
CERB_MEM_MAX=8G /home/dev/projects/cerberus-lean-proj/scripts/ce \
  ../../../scripts/capped .lake/build/bin/item7-audit
```

It prints 459 passing assertions, four call-typing diagnostics and its completion line. The diagnostics describe the inherited defect; they are not pass assertions. Its four extra kernel facts are printed during compilation. Earlier compile errors and the initially wrong empty-unseq expectation are retained as instrument development history, not product failures.

The full independent run used:

```sh
DUNE_CACHE=disabled CERB_MEM_MAX=32G \
  /home/dev/projects/cerberus-lean-proj/scripts/ce \
  python3 scripts/release.py --mode full --out .tmp/item7-audit/full
DUNE_CACHE=disabled CERB_MEM_MAX=32G \
  /home/dev/projects/cerberus-lean-proj/scripts/ce \
  python3 scripts/test_upstream_oracle.py --with-lean \
  --out .tmp/item7-audit/three-engine
```

These were sequential, on unchanged source. The approximately 85–90-minute full corpus/failure-injection sweep was justified in writing before launch under the project's grind tripwire. `release_certification` remains the runner's exact `incomplete: reporting/adoption/audit exits require separate evidence`; neither green lanes nor this review authorize a merge.
