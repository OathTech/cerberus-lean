# Run-digest review corrections and landing — 2026-09-22

[USER] “Run-digest review landed”, followed by “Great, then you can rebase off
main and land ff”. [AGENT] This authorizes the review corrections and the
fast-forward onto `mdd/cerberus-lean`; it does not authorize a push.

The independent [audit](2026-09-22_run-digest-audit.md) reviewed
`df85e95b7..24f19d6f5` and found no implementation blocker. Its one required
correction is D1 (P3, documentation); it also names two nonblocking source-comment
cleanups. Audit commit `97c98bcce` was copied as received to this branch as
`38af16c21`, including its independently verifiable evidence bundle.

## Corrections

D1 is corrected in the design note §3.5, charter §1/D3, original delivery's
consumer note §3, TODO, and `CabsImport.runDigest`'s comment. The S0 record §3
gains a dated erratum: its original OCaml source inventory already distinguished
Core text from objects, but its cross-engine conclusion needed an explicit
Cabs-domain qualification. The later design/charter statement grouping `.co`
and `.core` was false.

The rules are now explicit:

- Lean's Cabs execution entry selects the last program Cabs TU's digest, or
  `""` for an empty list. Library/metadata units do not select it.
- OCaml `.core` inputs call `core_frontend`, which sets the file digest, including
  when Core text follows C. `.co`/`.o` inputs preserve the prior global, empty
  only if nothing has set it. The dispatch is `backend/driver/main.ml:26–32`,
  setter `backend/common/pipeline.ml:279–280` and `util/cerb_fresh.ml:88–95`,
  object reader `backend/common/pipeline.ml:668`.
- Consumers carry the actual entry value for other paths. Absence of Cabs TUs
  does not determine those paths' digests. Lean's `--parse-core` does not execute
  Core text. Nonempty digest remains a per-program freshness hypothesis.

`runDigest [] = ""` and every implementation body are unchanged. The inherited
comments in `implementation.lem` now name only `enumDefs`/`tagDefs`, and
`core_run_aux.lem` describes the explicitly threaded Lean supply. Two existing
source-content pins and two existing generated-OCaml diff pins move, with a
dated manifest note; the manifest sets are unchanged, with no refresh.

## Validation and provenance

The final corrections are documentation/comments and their content pins. The
comment comparison checks all three edited source files against the audited
head, and all 305 generated files against a pre-correction snapshot. It preserves
string contents and compares the code tokens after removing nested comments.
The exact changed-file list, derived counts, pin movements, regeneration log,
and comparison script are retained in
`2026-09-22_run-digest-review-fixes-evidence/`.

The audit bundle verifier checks 12 files, all archive members and 5,367 capture
records, including its independent 39/39 full battery, stable recorded identities,
26 native assertions, and pristine/three-engine counts. Those reports certify
`24f19d6f5`; they are not relabelled as runs at the later documentation head.

Tier A is repeated on the frozen corrected tree, with polling before every lane.
Its final `report.json` and `summary.txt` are copied into the evidence directory
after completion. The comparison above justifies retaining the independent Tier B
and C5 results for the unchanged implementation; no baseline, fixture, failure
register, allowlist, or test instrument is changed. All original evidence is
preserved. Consumer re-pin and proof/corpus adoption remain the consumer's next
step, separate from the provider landing.

An overlapping orchestrator was discovered running landing gates in this same
worktree. This turn stopped its own regeneration (exit -15, after 60.1 s waiting
and 21.2 s running) to avoid further overlap. That interrupted attempt is not
validation evidence. The successful repeat and coordination waits are retained
separately.
