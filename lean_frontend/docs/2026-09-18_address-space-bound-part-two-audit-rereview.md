# Re-review: address-space bound, part two — C4 fixes

**Verdict: the original F1–F4 are fixed; REQUEST CHANGES for one new P2 CLI mismatch in C4.** The new bound-quantified proof, genuine allocator discriminator, EOF handling, and corrected allocator-contract prose address the first audit. The added decimal-only CLI policy is not implemented identically by the two engines: Lean still accepts embedded underscore separators that the fork now rejects. This does not bypass the numeric upper bound or invalidate the proof.

**Review:** Codex, 2026-09-18. **Head:** `2f4898cf7803450965af785412ad657b25a08d6d`, `arc/address-space-bound-part-two`. **Repair range:** `b7e190f04..2f4898cf7` — implementation `dc035396a` and record `2f4898cf7`; `b7e190f04` records the [previous audit](2026-09-18_address-space-bound-part-two-audit-premerge.md) of `88c5a827b`. No implementation, expectations, register, or branch history was changed by this review. Evidence: [re-review evidence](2026-09-18_address-space-bound-part-two-rereview-evidence/).

## R1 — P2: the new fork digit check disagrees with Lean's numeral parser

**Locations:** `backend/driver/main.ml:557–562`, `lean_frontend/Main.lean:1315–1326`; missing regression case in `scripts/test_address_space.sh`'s P9–P11 CLI controls.

The fork now requires every character to be an ASCII digit before calling `Z.of_string`. Lean still calls `String.toNat?`, which accepts single underscore separators **between digits**. This creates an acceptance discrepancy for a valid address-space value:

| Supplied spelling | Fork | Lean |
|---|---|---|
| `64` | Exit 0, `Specified(28)` | Exit 0, `Specified(28)` |
| `6_4` | Exit 124, “not a decimal numeral” | **Exit 0, `Specified(28)`** |
| `00_64` | Exit 124, “not a decimal numeral” | **Exit 0, `Specified(28)`** |
| `1_8446744073709551615` | Exit 124, “not a decimal numeral” | **Exit 0, `Specified(216)`** |

All runs use the committed `tests/address_space/window-char-int7.c` and its generated Cabs JSON, with the actual rebuilt fork/Lean binaries. The last spelling denotes `2^64 - 1`. `1_8446744073709551616` is correctly refused by Lean's numeric range check, so this is a grammar/correspondence defect, not an oversized-pointer acceptance.

The ordinary `6_4` discrepancy is introduced on the fork side by C4: the previous converter passed that spelling to `Z.of_string`, which evaluates it to 64. I independently ran that parser as well. The new selftest checks a hexadecimal spelling but cannot detect the underscore case; it stays green alongside this discrepancy. The repair's stated goal of matching accepted CLI spellings therefore remains incomplete.

**Fix:** choose one grammar and enforce it on both sides. For the fork's current digit-only policy, validate Lean's input as nonempty ASCII digits before `toNat?`; alternatively, deliberately support the same separator grammar on both sides. Add paired acceptance/refusal controls for `6_4`, with `64` as the positive control. Keep malformed-separator examples such as `6__4` and `64_` distinct: Lean already rejects them.

**Reproduce:** run `cli_matrix.py` from the evidence directory through the repository environment wrapper, with the repository root as cwd. `cli-matrix.txt` retains the results of 33 inputs and `cli-results.json` the statuses, diagnostic text and accepted observation tokens.

## Original finding dispositions

| Original finding | Disposition and evidence |
|---|---|
| **F1: fixed-bound theorem / incorrect `run` claim** | **Closed.** `run n top` and `S₁ top` use the supplied top; `exemplarTop` is removed. `exemplar_certified_shipped_forall (fuel) (top) (h : 8 ≤ top)` proves the requested statement over the production runner/driver. `errnoAction_active` discharges allocation and store under the real startup hypothesis, and `drive_after_setup` checks the explicit post-setup state against generated `drive`. Fresh source re-elaboration and the independent direct-production theorem assertion passed; checked cones contain only `propext`, `Classical.choice`, `Quot.sound`. |
| **F2: fabricated pre-fix result / no discriminator** | **Closed.** `window-char-int7@32` reaches cursor 27 before requesting 28 bytes aligned to 4. The executed old body succeeds at address 2; the fixed body kills. The actual fixed-engine result is pinned, and P1 now substitutes the corresponding low-byte result `Specified(2)`. The old-body copy matches the cited pre-fix source byte-for-byte after renaming. The prior 15 expectation rows are unchanged; three new rows are added. |
| **F3: unterminated expectations row ignored** | **Closed.** Both loops process a nonempty EOF read. Independent controls reject phantom, duplicate and malformed records with and without final newlines, and accept the otherwise valid file without its final newline. P5–P8 exercise these cases through the committed selftest. |
| **F4: incorrect equivalence attributed to allocator soundness** | **Closed.** VALIDATION and the consumer note now distinguish below-request failure, aligned-address failure, and the necessary conditions on an ACTIVE result. They name `allocator_below_request_kills` for the correct direction. |

The two register rationales now correctly say the exhausted request exceeds the cursor by **1 byte**, and the record corrects the historical claim that `run` already accepted `top`. Pristine register signatures and classifications are unchanged.

The F1 theorem is a **successful-start** theorem: it assumes `8 ≤ top`. It does not claim to prove the startup-OOM case for all smaller bounds. That limitation is now explicit and satisfies the previous audit's requested theorem shape. The new LP64 restriction is enforced by the CLIs; the pure semantic constructors still accept an `Int`, and consumer invariant theorems must carry their own domain assumptions. The exemplar theorem itself needs no upper bound and is consequently stronger in that respect. I also read the cited consumer review's R2 discussion; this review does not certify the consumer's separate whole-driver adequacy work.

## Small documentation corrections

1. **The second-object claim is stale.** `scripts/test_address_space.sh:16–18` and LADDER A12 still say the second object of every program exhausts at top 8. In the newly added case, errno occupies address 4, `char c` successfully occupies address 3, and the **third** object (`int a[7]`) exhausts. The program comment and old-body transcript already describe this correctly. Update the lane summary to distinguish the original five cases from the new case.
2. **Distinguish an executed allocator schedule from a complete old C run.** The old-body probe executes allocation steps and prints address 2; it does not execute the C frontend, return-expression conversion, or batch printer. The complete pre-fix `Specified(2)` token is inferred from that address and the program's return expression. This is sufficient to establish the missing allocator discriminator here, but LADDER A12's wording that the pre-fix *observation* was “EXECUTED” by the probe overstates the experiment. Say “old allocation result executed; C result derived.”

These are documentation corrections, not reopened F2 failures.

## Verification

| Check | Fresh re-review result |
|---|---|
| Fast gate at `2f4898cf7` | **16/16 passed**, complete fast selection, source unchanged, no artifact issues. |
| Tiny-bound lane and selftest (included above) | **18/18 cases agree and match pins; all 11 plants/controls pass.** |
| Full exemplar source plus independent production-run assertion | **Re-elaborated successfully** through the capped probe recipe; all five inspected axiom cones contain only the standard trio. |
| Pre-fix allocator probe | **Source identity verified; rerun passed.** Old/fixed outcomes distinguish `window-char-int7@32`. |
| Independent EOF controls | **8/8 expected outcomes**, including valid input without a final newline. |
| Paired CLI matrix | **33 inputs checked; three separator spellings expose R1.** Ordinary domain boundaries and digit-only spellings agree. |
| Pristine oracle, B10.1 | **Passed, 859 rows:** 822 semantic agreements, 28 matching failures, 7 reviewed differences, 2 interface agreements. |
| Oracle plants, B10.2 | **Passed:** 1 agreement, 1 deliberately rejected verdict, 51 successful plant checks. |

Both fresh release invocations ran against the clean reviewed head and report unchanged source. The B10 invocation deliberately selected only B10.1 and B10.2 from `--mode full`: its overall release status is **incomplete**, with **2/2 selected commands passed**, not a complete full-tier certification. See `release-summary.json`, `oracle-summary.json`, and the retained command transcripts in the evidence directory.

The fresh fast run checks synchronization/freshness, the proof/axiom gates, drift pins, the 18-case tiny-bound lane and all eleven existing selftest plants. The CLI matrix independently checks absent/default, lower/upper boundaries, leading zeros, prefixes, signs, whitespace and separators. Valid digit-only values, including `2^64 - 1`, agree through the full observation codec. Both engines reject ordinary `0`, `2^64`, larger values, prefixes and whitespace; R1 records the separator discrepancy.

**Historical full-run evidence:** `.tmp/c4-release-full/report.json` identifies `dc035396a`, 39/39 passed, complete selection, unchanged source, and no artifact issues. All 78 retained stdout/stderr hashes match that report. This was an integrity check of the implementer's full run, not a fresh repetition of the roughly 80-minute battery. The follow-up record commit changes documentation/evidence only. Optional backends and the full three-engine report were not re-audited here.

## Merge recommendation

Accept the original four fixes. Close R1 with an explicit shared spelling policy and a plant that rejects the current mismatch, then rerun the tiny-bound normal/selftest lane and the fast gate at the final unchanged tree. Apply the two documentation corrections alongside that small change. No further proof redesign or allocator-body change is indicated by this re-review.
