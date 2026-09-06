# Validation foundations audit evidence

2026-09-06 [AGENT]. Evidence for the
[pre-merge audit](../2026-09-06_validation-foundations-premerge-audit.md).
**Result: HOLD; four P1 and seven P2 findings remain open.**
The subject primary is `6d6cfa858109a42561878db3d939024c5756ad4f`, private
`eb926f8d37187490c34a74bd4ffe74c80acdc77b`. These are audit measurements and
controlled instrument adversaries, not a corrected release candidate.

| Record | Contents |
|---|---|
| [observations.md](observations.md) | Fresh full primary codec/caller review, three P1 findings and controls. |
| [private-concurrency.md](private-concurrency.md) | Fresh full private instrumentation/reference review, shared P1 and three private P2 findings, source preservation. |
| [release-oracle.md](release-oracle.md) | Fresh release/oracle/pin review, process-tree and disappearing-inventory findings. |
| [provider-docs.md](provider-docs.md) | Fresh provider/proof/failure/core-document review and three P2 findings. |
| [audit.tar.gz](audit.tar.gz) | Reviewer and coordinator reproducers, command records, raw observations, cold logs/manifest/client and selected hash-verified historical inputs. |
| [audit-files.json](audit-files.json) | Every archived member's path, length and SHA-256. |
| [checkpoint-summary.json](checkpoint-summary.json) | Final documentation Tier A: 13/13 pass, 429.371 summed lane seconds; source/external inputs unchanged, no missing/lost artifact entries. |
| [checkpoint-fast.tar.gz](checkpoint-fast.tar.gz) | All checkpoint lane logs/captures, before/after inventories and the exact tested document patch/bytes. |
| [checkpoint-files.json](checkpoint-files.json) | Every checkpoint archive member's path, length and SHA-256. |
| [SHA256SUMS](SHA256SUMS) | Archive, inventory, reviewer-copy and checkpoint-file hashes. |

Extract `audit.tar.gz` into an owned primary checkout to restore paths under
`.validation-foundations/premerge-audit-20260906/`. Absolute command paths
identify the original workspace; adjust them when reproducing elsewhere.
The archived `archive_audit.py` documents selection and exclusions. Compiled
products, cold checkout trees, `.git` administration and Python caches are
excluded. The cold manifest records source, generated-file, compiler,
runtime, native-object and package hashes. Its three external client source
files and all 20 command log pairs are retained. Rebuild compiled products
from those pinned sources using the shipped cold recipe.

Fresh normal checks include all 20 cold provider steps, the immaculate lane
after removing its controlled override and rebuilding, all 30 private litmus
rows plus the sequential-refusal leg, the private whole-lane corruption/empty
plants and 26 supplied observation plants. The original four abnormal-status
plants, 13 codec tests, 11 runner tests, five oracle-instrument tests and
14 real content-gate plants also pass. These supplied tests miss the new
audit adversaries; their green status does not close the findings.

Coordinator confirmations are in `descendant-oom/`, `actual-exec-ubdiff/`,
`observations/entry-immaculate.*`, `coordinator-timeout-group/`,
`coordinator-missing-inventory/`, `coordinator-private/` and
`coordinator-census-verification.json`. The cold verification checked all
20 log pairs, 1,769 present artifact/tool hashes, and equality of all 207
generated Lean/86 OCaml files with the subject. Expected cold-only absence
of two release freshness stamps is explicitly recorded.

The first coordinator row-parser extraction omitted associative-array
declarations and was invalid; `concurrency/row-parser-probe-v1.sh` is retained
as superseded evidence. Use `row-parser-probe-v2.sh`, its v2 results and the
independent private review/coordinator controls. Two exploratory cold-checker
assertions used incorrect stamp/path assumptions; the final retained checker
and verification explicitly correct them. No subject code was changed to
make these measurements pass.

The historical 32-command A+B and C1/C4 reports are separately preserved in
the [delivery evidence](../validation-foundations-evidence/README.md).
This audit verifies those records and makes targeted new measurements; it
does not claim a newly run full A+B or reporting campaign. The legacy run,
C2/C3 and customer adoption remain outside this execution.

The final checkpoint archive retains 5,804 verified members, alongside the
audit archive's 4,038. Its passing Tier A result is a documentation checkpoint
over the audited functional code. Twenty-nine version/build/library/stamp
artifact entries changed while rebuilding; both inventories of 1,775 entries
are retained. After the test, only checkpoint result statements, archive
records and links were added. All audit findings remain open.
