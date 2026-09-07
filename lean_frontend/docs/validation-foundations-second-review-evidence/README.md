# Validation-foundations second-review evidence

> **Landing note, 2026-09-06 [AGENT, orchestrator-directed].** The
> archives and large inventories listed below are NOT in the repository.
> They were dropped at the landing replay (`arc/validation-foundations-land`
> replays `arc/validation-foundations` commit by commit without them) under
> the operator ruling [USER 2026-09-06], verbatim:
>
> > "Agree on all points, and particularly on cleaning up the evidence
> > archives. These should not be git committed, and will not be pushed. I
> > don't actually hold strong value in such data which could be recreated,
> > so I am fine dropping large files like this. The important thing is
> > that runs can be reconstructed. Re ordering of concurrency, I think we
> > should stabilize the core semantics before this, so we should revert to
> > our previous ordering. Re master plan revisions dropping rulings - yes,
> > this should be retained."
>
> Drop rule: every `.tar.gz`/`.tar.zst` under `lean_frontend/docs/` and
> every file there of 1 MiB (1,048,576 bytes) or more. Dropped from this
> directory (2 files; bytes derived from the source-branch blobs, total
> 343,254): `documentation-checkpoint.tar.gz` (266,601), `review-checks.tar.gz` (76,653).
>
> Their SHA-256 identities are kept, line for line and unchanged, in
> [SHA256SUMS.dropped](SHA256SUMS.dropped). [SHA256SUMS](SHA256SUMS) lists
> present files only, so `sha256sum -c SHA256SUMS` passes in this directory.
> Each dropped line was checked against the source-branch blob before the
> split. The original bytes exist only on the local, never-pushed source
> branch `arc/validation-foundations` (head `d607409f9`) until it is pruned.
>
> This README's own line in `SHA256SUMS` was re-hashed after this note was added; the pre-note README hashed `cbd57aea1924dd028efe87d4843f2676c96ad1fdfbf0df9abb50ab91a238183c`.

> **Reconstruction.** Load the project environment first (`source scripts/env.sh`, or prefix each command with `scripts/ce`); run from the repo root; the checkpoints of record ran with `CERB_MEM_MAX=32G` and `DUNE_CACHE=disabled` (document-review record) — use the same. Commit column: source SHA on `arc/validation-foundations`, then the byte-identical replayed commit on the landing branch in parentheses. Reconstructed runs reproduce verdicts/classifications; timings, version-bearing artifact hashes and process identifiers differ, as the records themselves note. Both dropped archives keep their full member
> inventories here: [review-checks.json](review-checks.json) for
> `review-checks.tar.gz` and [documentation-checkpoint.json](documentation-checkpoint.json)
> for `documentation-checkpoint.tar.gz`.
>
> | Dropped | Commit | Recipe |
> |---|---|---|
> | `documentation-checkpoint.tar.gz`: Tier A 13/13 on the review's documentation checkpoint | `df40f6aa1` (`297e20a44`), subject `05278ae95` (`5317bc5ac`) | `python3 scripts/release.py --mode fast --out .validation-foundations/second-review/documentation-checkpoint`; [checkpoint-summary.json](checkpoint-summary.json) is retained |
> | `review-checks.tar.gz`: the review's fresh checks (incl. the initial dispatch error) | `05278ae95` (`5317bc5ac`) | the checks are enumerated in [summary.json](summary.json) `checks`/`fresh_checks` and in [the review](../2026-09-06_validation-foundations-second-review.md); each is a Tier A/B lane or hermetic test named there |

2026-09-06 [AGENT]. See the [review](../2026-09-06_validation-foundations-second-review.md).

Subject: `05278ae9537a0212d18a3ca587f79a67e5d9ceaf`; private companion:
`86a2aea547804b78eb7f1eae633bb9c24c713b7f`. No functional changes were made.

- [summary.json](summary.json): fresh checks, retained-evidence verification and measured gate cost.
- [review-checks.json](review-checks.json): inventory and archive hash for
  `review-checks.tar.gz` (dropped; identity in [SHA256SUMS.dropped](SHA256SUMS.dropped)), including the initial dispatch error.
- [checkpoint-summary.json](checkpoint-summary.json): Tier A 13/13,
  412.823 summed seconds, exact tested snapshot and publication scope.
- [documentation-checkpoint.json](documentation-checkpoint.json): inventory
  for `documentation-checkpoint.tar.gz` (dropped; identity in [SHA256SUMS.dropped](SHA256SUMS.dropped)),
  containing complete command logs and runner/scope reports, tested document
  snapshots and the residual prose findings. Successful per-program captures
  are not duplicated in this documentation package.
- [publication.json](publication.json): final documentation/source boundary.

Every archive member was read back and verified. Paths are relative to the
subject checkout. The earlier full/cold/reporting archives remain at their
original locations; this package does not duplicate those campaigns. The
review used their hashes and specific retained raw logs/captures as stated
in the report. The documentation checkpoint is published separately.
The record is the repairing agent's second pass. The standing fresh-reviewer
requirement for major core documents remains a separate review obligation.
