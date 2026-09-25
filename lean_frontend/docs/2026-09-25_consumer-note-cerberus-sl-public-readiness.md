# Consumer note for cerberus-sl — the public-readiness cleanup landed (2026-09-25)

Author: the orchestrator [AGENT]. Addressed to cerberus-sl (`scripts/semantics-pin.env`; your final S3.5 pin was
`2b51d2a57`, per `2026-09-23_consumer-repin-note-cerberus-sl.md`).

## What changed for you since `2b51d2a57`

- **No semantics change.** The public-readiness cleanup (MUST + SHOULD blocks, records `2026-09-24_public-readiness-*`,
  `2026-09-25_public-readiness-followup.md`) changed documentation, scripts/gates, the shipped stdlib comment, and the
  concurrency model's Lean target reps (`cmm_csem.lem`: 23 `sorry` reps → `LemUnsupported.Cmm.*` markers — never
  rendered to Lean; that model is outside the supported profile). Both generated trees are byte-identical to
  `2b51d2a57`'s: OCaml except one comment in `cmm_csem.ml`, Lean identical (lem-sync gen `f4893e95…`).
- **The Lem RUNTIME changed** (lem-lean `6b20bfd` → `67ec5de` → `c2a68e7`): `lean-lib/LemLib.lean` gained
  `@[never_extract]` on the public `fuelExhausted` wrapper (S13: without it a closed `fuelExhausted w` was lifted to a
  module-init constant and evaluated eagerly; exposed by the strict native parity probe `p_lem_size` under
  `LEAN_ABORT_ON_PANIC=1`). If you link LemLib, move your Lake `LemLib` rev with the pin. No API change.
- **The lem TOOL changed** (refuses `sorry` target representations — function, applied, parameterised, declared and
  inline type reps; a repository-local `scripts/capped`; `git describe --long` version strings; a qualified-core-name
  import heuristic). Regenerating your own Lem sources with the new lem is unaffected unless they carry a `sorry` rep.
- **Pins now:** cerberus-lean `mdd/cerberus-lean` = the sweep landing commit that carries this note; lem-lean
  `mdd/lean-backend` = `c2a68e79b6369e19f099dfa48767319c1daf19b3`; every cerberus pin site (Lake rev, three
  lake-manifests, `fork_drift_manifest.txt` `lem-pin`) = that hash. The fork-drift gate compares `lem -v` as a hex
  PREFIX of the full pin, so a 7- or 8-character abbreviation both pass.
- **Gates you may re-run at the pin:** `scripts/test_unit.sh` (15 exes; now also `test_version.sh`,
  `test_exec_totality.py`), the differential lanes as in `lean_frontend/SUPPORTED.md` and `scripts/LADDER.md`.
  `check_fork_drift.sh` now REQUIRES `CERB_UPSTREAM_TREE` (the pristine upstream generated tree) — provisioning
  recipe in `lean_frontend/VALIDATION.md`; in this container `scripts/env.sh` exports it.

## Recommendation

Take ONE re-pin at the announcement tag rather than at this commit: the operator intends annotated prerelease tags
(`cerberus-lean-v0.1.0-alpha.1`, `lean-backend-v0.1.0-alpha.1`) after the external M9 checks; the tagged commit will be
this mainline or a docs-only descendant. Until then your `2b51d2a57` pin remains semantically current.
