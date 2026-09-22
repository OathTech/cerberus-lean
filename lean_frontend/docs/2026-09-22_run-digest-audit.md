# Run-digest pre-merge audit — 2026-09-22

[AGENT] Independent review requested by the operator. Reviewed range:
`df85e95b7b37826dfb3f2ac97a41473580f1e0b9..24f19d6f5a63204afff1991e3fc1fcf5b28ad420`
(`arc/run-digest`: three design/charter commits and implementation commit
`24f19d6f5`). Base is the landed enum branch. Review takes place in
`audit/run-digest-20260922`; no changes to the feature worktree, mainline, or
other workers' sources.

## Verdict

[AGENT] The state-data design meets the stated provider-side goal. No implementation
blocker was identified. The independent full battery and focused checks pass.
Correct D1's entry-rule documentation before landing; no code repair is requested.
The inherited source-comment cleanup below is nonblocking. Consumer adoption and
its proof obligations remain a separate step, as the charter requires.

## D1 — P3: distinguish Core text from Core object inputs in the digest rule

The new [design note](2026-09-20_run-digest-as-state-design-note.md) §3.5 and
[charter](2026-09-22_charter-run-digest-as-state.md) §1 say `.co` and `.core`
inputs set no digest. These are different OCaml entry paths:

- `backend/driver/main.ml:26–32` dispatches `.co`/`.o` to
  `read_core_object`, and `.core` to `core_frontend`.
- `backend/common/pipeline.ml:279–280` begins `core_frontend` with
  `Cerb_fresh.set_digest filename`.
- `util/cerb_fresh.ml:88–95` sets the global to `Digest.file filename`.
- `backend/common/pipeline.ml:668`'s object reader does not set that global.

Consequently an OCaml run of `p.core` mints with that Core file's digest, and a
later Core-text input replaces an earlier C TU's digest. An object-file input
preserves the preceding ambient digest (empty only if nothing previously set
it). The same process may already have processed a prior input.

This is a documentation finding, not a demonstrated regression of either
engine: the changed OCaml entry still passes the current global, and Lean's
`runDigest` selects a list of Cabs inputs; Lean's `--parse-core` does not execute
Core text. The “last program TU / empty without one” migration wording in the
[delivery record](2026-09-22_run-digest-as-state-record.md) §3 should explicitly
identify the Cabs pipeline's domain. Carry the actual entry
value when consuming another entry; do not infer it from absence of Cabs TUs.

Requested correction: amend the design note §3.5 and charter's factual inventory,
and qualify the migration/empty-input rule. The underlying
[S0 record](2026-09-19_program-data-parameters-S0-record.md)'s source claim is
inherited and should receive an erratum too. No change to the new
`runDigest [] = ""` definition is requested.

## Design and implementation assessment

The change makes the run's minting identity part of the run state beside its
counter. `fresh_given_int d n` is a transparent symbol constructor;
`fresh_symbol'` reads `sym_digest` and advances only `sym_supply`. The two core
constructors, both driver entries, constant-expression mini-run seed, Main entry,
and `--call` argument-prefix path were reviewed together. The field is initialized
once; the runtime's state primitives preserve it via record updates.

Choosing the last Cabs TU rather than `main`'s TU mirrors the C frontend's ordered
processing, including reversed-cons linking. The frontend's own digest installation
and evaluation barriers remain. All five elaboration arity fixes retain their
ambient reads inside the existing computation; they are outside the consumer's
pure runtime claim.

The OCaml runtime continues to use its global mint. The shim deliberately ignores
the explicit argument and seeds from the global, whereas the Lean constructors
honor the argument. Every production OCaml caller supplies that same global value.
This preserves existing driver behavior; it is not a general guarantee that an
arbitrary OCaml API argument controls minting or that OCaml runs are reentrant.
The record discloses this target difference. No equivalence for independently
chosen OCaml state/global digests is claimed by this audit.

For cerberus-sl, the change supports the requested definitional mint equation and
removal of `MintDigestC` once the consumer carries and preserves
`rs.sym_digest = P.digest`. Nonempty digest remains a per-program freshness
hypothesis. The fixed fixture is evidence about that fixture, not proof that
arbitrary callers supply valid MD5 strings. The source signature intentionally
allows every string. Adoption, capture integrity, and the consumer's full proof
check still belong to its re-pin; this review does not certify them.

The exemplar statement remains quantified over fuel and address-space top and
now additionally quantifies over digest. Its proof continues to use the actual
shipped driver. No native proof method or new semantic axiom was introduced.
Optional backend call sites were changed; isolated type checks should be described
as checks of those calls, not full optional-backend builds.

## Inherited documentation cleanup (nonblocking)

Two source comments still describe superseded mechanisms. These predate D-S and
are not new implementation defects: `frontend/model/implementation.lem:25,65`
includes `digest` in the reader order and `normalise_integerType` signature,
although the actual readers are only enumDefs and tagDefs;
`frontend/model/core_run_aux.lem:240–242` says the Lean supply is seeded from an
ambient counter, while its actual entry is supply-threaded. The new delivery's
migration note is correct on both points. Update these comments alongside the
digest documentation to avoid contradictory guidance at the source interface.

## Independent validation

Validation was run in a separate worktree at the reviewed head, with a clean
tracked tree. Both generated trees were re-derived; the fork OCaml driver was
rebuilt with `DUNE_CACHE=disabled` and `--force`, and the Lean driver rebuilt under
the 32 GiB cap. This build took 271 seconds. The worktree-local pristine oracle
was separately built/validated from Cerberus `b9aeedcb4` and upstream Lem
`3802cb0`. The fork's Lem pin remains `38f87d5`.

The rebuilt Lean binary is byte-identical to the worker's final Lean binary;
both generated-tree stamps and both driver source fingerprints also match.
The OCaml binary differs, consistently with the changed version/build identity;
its source fingerprint matches. Exact values are retained in `preflight.json`.

The independent focused probe adds these checks without modifying product tests:

- Six kernel facts: the complete mint result/state equation for arbitrary run
  state, digest initialization for both driver entries, and preservation by
  action-id allocation, thread creation, and excluded-id allocation. The axiom
  output is retained: mint/action/excluded need none, spawn needs `propext`, and
  the two entries expose only the standard `propext`, `Classical.choice`,
  `Quot.sound` set.
- Nine runtime roots' conservative kernel dependency closures exclude the
  ambient digest getter/setter seams. Five frontend roots are positive controls
  that still reach the getter. This is a kernel dependency check, not a compiled
  call-graph theorem; source/generated-code review and native execution
  complement it.
- Twenty-six native assertions: interleaved independent run states remain
  stable across three different ambient digest settings, repeated minting keeps
  the run's digest, call argument prefixes use their explicit input, frontend
  mint closures reused across writes follow the current TU, and constructor/TU
  selection checks cover arbitrary and empty digest strings.
- Both optional backend entry expressions typecheck against the freshly rebuilt
  OCaml modules; an integer in the digest slot is rejected. These are isolated
  call-site checks, not full web/runtime backend builds.

Two initial compilations of the reviewer probe failed on reviewer-authored Lean
syntax/type-inference mistakes (`when` and an under-typed record update). The
corrected probe built and ran successfully. Both failed build logs are retained;
neither failure is a product finding.

The independent full battery ran from 18:29:04 to 19:53:39 UTC (approximately
85 minutes), at the clean reviewed head. Its summary, verbatim:

```text
full: passed; 39/39 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The source, external-input, and every recorded artifact identity agree before and
after. The runner's final line deliberately distinguishes a completed battery
from a complete customer release; the consumer adoption obligation remains.

[AGENT] Derived summary of the retained outputs (the 85 GCC skips are the sum
of its six skip categories):

| Check | Observed result |
| --- | --- |
| Unit executables | 14 passed, 0 failed |
| GCC differential corpus | 2,014 total; 1,917 agreements; 12 triaged; 85 skips; zero regressions or improvements |
| Observation-lane failure plants | 93/93 passed |
| Pristine versus fork, Tier B row 10 | 835 semantic agreements, 28 matching failures, 7 reviewed differences, 2 interface agreements |
| Pristine register/compare plants | `plants_passed` |
| Pristine versus fork, chvalid | 4 semantic agreements |

The mandatory C5 three-engine report also passed, on the same clean source, in
264.8 seconds. Its pristine-versus-fork counts equal row 10 above. The Lean column
reports 830 agreements, 28 differences, 12 both-undecodable rows, and 2 not
applicable rows. All 872 row IDs, Lean classifications, and three-engine verdict
summaries match the worker's final report; the 40 difference/undecodable IDs and
classes are unchanged. These 40 rows are not semantic agreements. The owning
Lean-versus-fork lanes gate their baselines; C5's Lean column is report-only.

No baseline, expectation, exception register, or shipped validation instrument
was changed. The failure-reach population remains 238, the unsafe boundary
allowlist remains 19 rows, and the pinned opaque population remains 10. No Lem
change or new semantic axiom was introduced.

Advance runtime justification [AGENT]: the full battery's roughly 90 minutes are
required corpus measurement and harness failure-injection work, not proof search.
Build and focused probes have separate bounds. Two already-running batteries
delayed the rebuild; queue/process logs are retained. Shared opam and other
worktrees remain untouched.

## Worker evidence review

The committed final report contains 39 successful commands and equal source and
external-input identities before/after. Its recorded artifacts are not all equal
before/after (version-dependent OCaml build artifacts and freshness stamps change).
This does not contradict its stated source-stability result. It must not be
paraphrased as an artifact-immutable battery. Independent validation above
identifies the audited commit directly, without relying on a dirty pre-commit hash.

The interrupted pre-rebase run and preliminary source-unstable three-engine report
are explicitly labeled incomplete/superseded in the delivery. They are not used
as final certification by this audit.

## Retained evidence

The [evidence bundle](2026-09-22_run-digest-audit-evidence/README.md) contains the
unmodified release report, every command's raw stdout/stderr, pristine and
three-engine reports with their referenced captures, focused probe sources and
logs, source fingerprints, and the supplied-evidence review. Its standalone
`verify_evidence.py` checks hashes, command results, frozen identities, native
assertions, oracle counts, and the exact historical Lean difference ID/class set.
The review diff is inventoried by base/head and SHA-256 for all 60 changed files.

[AGENT] The implementation, feature branch, and mainline were not modified by this
review. The audit record is committed separately on `audit/run-digest-20260922`;
no merge or push is part of this review.
