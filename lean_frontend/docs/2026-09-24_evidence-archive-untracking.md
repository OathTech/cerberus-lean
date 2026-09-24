# Evidence archive removal from the tracked tree

Recorded 2026-09-24 against Cerberus `e9f9d049ffaaf005c392495b0f6418d21f4df29f`.
M10 removes these archives from the cleanup branch's index only. Their
working files and previous commits remain available; history is unchanged.
The operator reports that they were already pushed. Publication cannot be
undone by untracking them, and this cleanup makes no such claim.

The existing evidence-directory READMEs and checksum inventories are retained
verbatim. Use their recorded commands to reconstruct runs; label any rerun
with its new date and source pin. To recover an exact original archive:

```bash
git show e9f9d049ffaaf005c392495b0f6418d21f4df29f:PATH_FROM_TABLE > recovered.tar.gz
sha256sum recovered.tar.gz
```

The following inventory is derived from tracked files at that pin:
**21 archives; 21,888,265 bytes**.

| Path | Bytes | SHA256 |
|---|---:|---|
| `lean_frontend/docs/2026-09-19_concurrency-design-assessment-evidence/raw-captures.tar.gz` | 594006 | `f45581b3f646cbd89d0ae53dfaa1d19a215ab8ba34f4ae6ee62fc729a254c086` |
| `lean_frontend/docs/2026-09-20_enum-premerge-audit-evidence/focused-captures.tar.gz` | 147436 | `eee3155a27bf03aa314d17c76d911290e70b724f74a76df728fe72b72a2a973d` |
| `lean_frontend/docs/2026-09-20_enum-premerge-audit-evidence/formatting-originals.tar.gz` | 2874 | `8b9c9f8684eea7c22330c022276f00ddd9a9eba16dbd77310251fde695e5b3e3` |
| `lean_frontend/docs/2026-09-20_enum-premerge-audit-evidence/pristine-reports.tar.gz` | 382697 | `c80af7f83aded2a941f2e5327639ab71ad8f9e02cc5248a16721553aa4b11c5f` |
| `lean_frontend/docs/2026-09-20_enum-premerge-audit-evidence/release-lane-receipts.tar.gz` | 131960 | `d55e2107b3640f4c438265b9a87c16ab1157464dc5cd477943300dc457621136` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/arity/build-log.tar.gz` | 1437 | `6a4d557fe4da2bde1f7daecebd7da7a656b408a939091335527d8d093a22e331` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/arity/focused-captures.tar.gz` | 13854 | `e0af3a91239a6f753ef646a7788e79c0b1fea51bd802c3257ee13f072e6abc27` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/arity/lane-receipts.tar.gz` | 135105 | `ef7faad14cfc3e0c1d6444aa36404ff9cfabe217173d8e14302d0f0b02d93dae` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/arity/pristine-reports.tar.gz` | 542906 | `aef798f84c3821ae5afc7e6a2074927905f3db6fa95470af31e1ef669acd454f` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/enum/build-log.tar.gz` | 1439 | `00c19edc85e968d50b5b8748c7249964e6684e6c18fc10ec3da8728bfcd804b0` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/enum/focused-captures.tar.gz` | 151167 | `4447c88f73c648c9850e71561f1a0d1a9dd39a2b10ade9261671f3216d85700f` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/enum/lane-receipts.tar.gz` | 135118 | `3a436740a2cbc379af3c983753b23823083efcef0ffd51768ce3845e3bc79331` |
| `lean_frontend/docs/2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/enum/pristine-reports.tar.gz` | 545849 | `458ac31a1f21b897b725d8e949670062a8aaaa865fc52011bc499e3a8d4a4947` |
| `lean_frontend/docs/2026-09-22_match-pattern-arity-rereview-evidence/focused-evidence.tar.gz` | 147285 | `13221440a5b807429c09fca7242cc2aff775b54b27bbf9d5e0f2e5dfaef4d8b3` |
| `lean_frontend/docs/2026-09-22_match-pattern-arity-rereview-evidence/lane-receipts.tar.gz` | 129928 | `1830b27fa63906f50f3fe6adf4fa06f1424a7332d3bd9cafc17e4784296ade6c` |
| `lean_frontend/docs/2026-09-22_match-pattern-arity-rereview-evidence/pristine-captures.tar.gz` | 8384640 | `3e5b4e89f4c602618c5c525cc8e5a85cfc13cf55647a3d4e9370f43f0ad86493` |
| `lean_frontend/docs/2026-09-22_match-pattern-arity-rereview-evidence/pristine-reports.tar.gz` | 933659 | `b9120071cb54da87fb0578760a05f694ba00aeaac9b182e5d1851adf8d12183c` |
| `lean_frontend/docs/2026-09-22_run-digest-audit-evidence/focused-evidence.tar.gz` | 65393 | `79f26d6dcc212eba9ebe3616e9ba480b85281e63603e7c164916f6fa3863fd7d` |
| `lean_frontend/docs/2026-09-22_run-digest-audit-evidence/lane-receipts.tar.gz` | 128800 | `2b26b13694a1ddcbaeb425ee4e4b038443a28198499b44d019ed3807e4389e00` |
| `lean_frontend/docs/2026-09-22_run-digest-audit-evidence/pristine-captures.tar.gz` | 8380976 | `79edefc618dc42dbad6eddce2eba6bb2f1127500bbe3956b5ffd03502b5be2f5` |
| `lean_frontend/docs/2026-09-22_run-digest-audit-evidence/pristine-reports.tar.gz` | 931736 | `248905cf4378dcc8b7bd56d5fcc908a1488c5a93aacfb7fe02b291a67f97a8d5` |

## Closure addendum — provenance (2026-09-24)

[AGENT] Closure F2, checked against the first cleanup head `0a6d59eed`.
The inventory above is an agent-derived tally: 21 tracked archives totalling
21,888,265 bytes at pre-cleanup mainline `e9f9d049f`. The operation removed
only their HEAD tracking entries; the local files and historical Git blobs
remain. This addendum preserves the original inventory and record.

[USER 2026-09-06], verbatim excerpt of the retention ruling:

> Agree on all points, and particularly on cleaning up the evidence archives. These should not be git committed, and will not be pushed. I don't actually hold strong value in such data which could be recreated, so I am fine dropping large files like this. The important thing is that runs can be reconstructed.

Source: [master-plan ruling](2026-09-05_master-plan.md), present at
`e9f9d049f`. The later operator verification reported that mainline equalled
origin and the archives had already been pushed. [AGENT] Untracking at HEAD
does not retract that publication: already-pushed mainline and its history
have not been rewritten. Public remote state was not independently checked
from this offline review environment.
