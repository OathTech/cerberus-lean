# Independent SC project-scope review

Date: 2026-09-24. Reviewer: `/root/sc_project_scope_review`, a fresh subagent
started with no inherited conversation context. It was briefed on the overall
project goals, correctness and utility standards, source locations, read-only
customer constraint, and the requirement to identify drift and a completion path.
The implementing agent's proposed answer was not included in that briefing.

Reviewed source tip: `631382a9d23a709112f38add53357d4cbe6fc108`.
Review base: `5407597d9eeba0259d65b728e86a860ad4614ab3`.

[USER] After commissioning the review, the user requested that it be committed
at this branch's tip with a detailed inventory, in preparation for a new agent
and a new branch that carefully migrates working pieces. The implementing
agent's separate [branch inventory](2026-09-24_sc-branch-inventory.md) is not
part of this independent review. Review recommendations are not approvals or
proofs of correctness. No implementation change accompanies this handoff.

The reviewer's final report follows verbatim. Its absolute source links refer
to the reviewed worktree and line numbers at the source tip above.

---

**Verdict: keep the execution machinery, but change the completion strategy.** This is a substantial, connected SC implementation, not merely scaffolding. Its central remaining problem is treating a scalar Cmm representation as the universal admission test for concrete object-memory execution. Continuing to add exceptions to that representation will prolong the work and obscure the semantics.

I reviewed clean HEAD `631382a9d23a709112f38add53357d4cbe6fc108` against the specified base and confirmed the pristine reference pin. I changed no files and performed no builds. Three bounded executions independently confirmed: native whole-aggregate copying returns `0`; native ordered byte update refuses; Lean initialized-member reads refuse. Current binary hashes match the recorded evidence. The broader test results below remain existing evidence, not independently rerun coverage.

1. **The scalar adapter is the principal abstraction mismatch.**

   The actual interpreter already performs byte composition. The adapter nevertheless requires every read’s bytes to originate from one writer, with exactly the same range and logical value. See [sc_candidate.lem:288](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/frontend/model/sc_candidate.lem:288). Its separate coverage check rejects overlapping views except for a special unspecified-array-initialization case. See [sc_candidate.lem:148](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/frontend/model/sc_candidate.lem:148).

   Consequently, these ordinary, ordered programs remain unsupported:

   - Initialize an `unsigned int`, modify its first byte through `unsigned char *`, then read the integer.
   - Initialize `struct pair { int x; int y; }`, then read `p.x + p.y`.

   These are implementation limitations. They are not evidence of an unresolved upstream meaning for ordinary ordered accesses. N1570 distinguishes scalar memory locations, expressly permits character access, and describes the SC interleaving interpretation for the appropriate race-free domain. See [N1570:1009](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/tools/n1570.html:1009), [N1570:4580](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/tools/n1570.html:4580), and [N1570:1825](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/tools/n1570.html:1825).

   **Change:** retain concrete memory as the authority for executed values, provenance, lifetime checks and completed effects. Interpret footprints, contributing writes and source ordering around those transitions. Keep pinned Cmm predicates for their justified scalar and atomic/fence domain. Check the full occurrence history for remaining conflicts, sequencing and interpretation obligations.

   This requires a precise composition contract; simply dropping problematic non-atomic actions from the candidate would be unsound. In particular, that could lose G07 witnesses, library obligations and races. The roadmap’s proposed direction is reasonable, but its two successful ordered examples would demonstrate only the beginning of the construction.

2. **Fail-closed handling is too global: an unrelated gap suppresses new independent race findings.**

   `sc_classify_candidate_with` produces **no** data-race or unsequenced-race findings whenever *any* interpretation issue exists. This also suppresses abstract varargs conflicts. See [sc_candidate.lem:497](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/frontend/model/sc_candidate.lem:497).

   The retention accumulator correctly preserves findings discovered *before* a gap. It does not solve discovery *after* a gap. A concrete distinguishing acceptance case is an ordered, private struct-member access followed by two unsynchronized writes to a separate scalar, then a loop. There is no atomic or library synchronization ambiguity connecting those operations, yet the earlier subobject issue disables subsequent race discovery. This conclusion follows from the implementation; I did not execute that combined reproducer.

   **Change:** distinguish uncertainty that can affect a particular conflict or ordering argument from unrelated uncertainty. Do not merely remove the global check: unresolved synchronization can indeed make an apparent race spurious. Keep independently justified findings alongside unsupported/incomplete results.

3. **Library handling remains a broad implementation refusal, and G06 still has a real fail-open path.**

   The production library check assigns a protection obligation to every observed effect under a non-Core library scope except a narrowly recognized private parameter read. It does not yet identify missing stream locks or shared internal objects. This is why ordinary buffer accesses, private library writes, and ordered calls can still be refused. See [driver.lem:185](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/frontend/model/driver.lem:185).

   **Change:** use the existing actual call/link/storage information to implement the specific G03/G08 producers. Ordered calls and ordinary caller buffers must work; a reached dependence on omitted stream/internal protection must remain unsupported rather than becoming caller UB. Avoid a catalogue or authentication framework.

   G06 is different: the header still expands lock-free properties to unresolved identifiers, which numeric preprocessing can consume as zero before either semantic frontend sees the program. See [stdatomic.h:8](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/runtime/libc/include/stdatomic.h:8). Runtime refusal does not close that path. Preprocessing usability is an actual requirement, not optional diagnostic polish. [WG14 DR458](https://www.open-std.org/jtc1/sc22/wg14/www/docs/dr_458.htm)

   The unavailable GCC SDK blocks the chosen observer experiment. It does not block the object adapter or establish that a GCC plugin is the only possible implementation. Resolve that capability separately and keep the experiment bounded.

4. **The public C acceptance machinery has not caught up with the agreed scope.**

   The committed litmus runner still hardcodes exhaustive execution and `--nolibc`. See [test_litmus.sh:50](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/scripts/test_litmus.sh:50). Therefore it cannot run the actual callable-fence case correctly, while several other seeds exceed practical exhaustive bounds. The useful selected-execution results principally live in scratch reports.

   The finite Python reference is honest about being a hand transcription, but checking its expected sets is not a connection to the production executor. Paired ports share most of their implementation; their agreement cannot establish that connection either.

   **Change:** adapt the existing runner to the approved distinction: tiny exhaustive C probes, selected/prefix checks for larger C cases, and complete comparisons on the bounded semantic/reference domain. Use independent allowed outcomes when two selected schedules differ. Complete the promised production-checker disconnection control. This is modest runner work, not an exploration subsystem.

5. **The provider interface is valuable and sufficiently direct; its demonstration and reporting claims need restraint.**

   `sc_program` retains the actual driver computation and state, including outer initialization and saved services. `sc_program_node` exposes the underlying ND node. This avoids a second evaluator and fixes the important mistake of treating `driver_state` alone as a resumable whole program. See [driver.lem:2716](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/frontend/model/driver.lem:2716).

   Explicit semantic fuel and exploration budget are appropriate. A customer can build a whole-machine reasoning interface over this substrate without the provider implementing Iris rules. The customer’s existing mirror-language construction does not justify restricting this executor.

   However, the external example mainly proves definitional connections. Its “fault retains assertion” theorem assumes the assertion already holds in the reported state. See [SCConsumer.lean:25](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/lean_frontend/examples/sc_consumer/SCConsumer.lean:25). That is useful API smoke coverage, not a concurrency preservation or adequacy result.

   Also, batch rendering discards the retained findings and interpretation information carried by failure states. A race followed by exhaustion is printed as exhaustion alone. See [Main.lean:1072](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/lean_frontend/Main.lean:1072).

   **Keep the API.** Add a small SC observation projection from the same state so public probes can inspect the primary result, retained findings, remaining obligations and incomplete status together. One meaningful offered-step/retained-observation example is enough; do not reopen a generic proof project.

6. **Prefix checking still repeats substantial work even on a selected execution.**

   Every recorded effect calls `sc_note_prefix`, which reconstructs the candidate, scans the accumulated history and computes relations again. See [driver.lem:219](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/frontend/model/driver.lem:219) and [sc_candidate.lem:369](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/frontend/model/sc_candidate.lem:369).

   The ancestry optimization is useful, but it is recomputed for each prefix. Multiple pairwise scans per prefix imply at least cubic accumulated work in straightforward growing executions. Thus abandoning exhaustive exploration does not by itself make mid-size selected runs practical.

   **Change only measured repeated work:** share interpretation/order computations and incrementally retain the information needed for prefix findings. Preserve the journal and failure-before-loop behavior. Do not raise bounds or add a general optimization campaign.

7. **The remaining roadmap still contains avoidable scope expansion.**

   Keep the filesystem failure-state repairs already made: they preserve real effects and prevent fictitious successes. But completing directories, links, inode retention, permissions and directory streams is a substantial general filesystem port. The live inventory currently makes that look like part of SC closure. See [effect inventory:185](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/lean_frontend/docs/2026-09-21_sc-effect-inventory.md:185).

   My recommendation is to separate that inherited capability backlog from SC composition. Preserve and disclose its precise port limitations; do not rename them upstream semantic uncertainty. If the user retains full filesystem completion within this milestone, the remaining work is materially larger than the SC adapter and cannot honestly be described as finishing a few guards.

   Likewise, examine actual allocator reachability before building a general reuse-order mechanism. Ordinary positive-size allocations use a descending cursor; freeing does not recycle it. See [impl_mem.ml:1331](/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/sc-prototype/memory/concrete/impl_mem.ml:1331). DR403 supplies the rule for actual reuse; it does not require inventing allocator choices absent from the selected concrete model. Zero-size and requested-address cases need separate treatment. [WG14 DR403](https://www.open-std.org/jtc1/sc22/wg14/www/docs/dr_403.htm)

8. **Pruning was worthwhile, but some duplicate preparatory infrastructure remains.**

   Keep the shared scheduler, continuation-scoped sequencing, effect capture, suspension/current-state restoration, atomic phase distinctions, representation-preserving values, source-location transport and mechanically derived reference predicates.

   Consolidate or remove the test-only alternative routes through `Sc_atomic_sources`, `Sc_synchronization` and `Sc_access_sequencing` if the final production adapter continues to implement those tasks elsewhere. Their tests should exercise the canonical production interpretation. Keep global attribution only to the extent its imminent G03/G08 producer actually consumes it.

   Do not spend another phase deleting harmless small equations. The remaining harmful complexity is duplicate semantic interpretation and work justified by anticipated consumers. Condense the roadmap’s completed pruning/checkpoint history after the direction is settled; its current bulk makes outstanding obligations harder to see.

The shortest credible completion path is:

| Order | Work and relative size | Concrete acceptance |
|---|---|---|
| 1 | **Object/atomic composition — largest remaining semantic task.** Replace universal single-writer scalar admission with the explicit operational composition. | Ordered byte update, initialized members, heap/array subobjects and byte copy work; distinct members stay distinct; genuinely unresolved unordered representation remains unsupported; actual atomic RF/RMW/fence rules remain checked. |
| 2 | **Findings and runtime boundaries — substantial integration.** Fix unrelated-gap suppression, finish G03/G08 and reached lifetime/metadata handling. Resolve G06 capability independently. | Gap-before-independent-race retains both; publication suppresses false races; ordered/private library operations work; shared missing protection produces a specific gap; faults retain completed effects. |
| 3 | **Usable public checks — relatively small, begun immediately.** Update the existing runner and observation projection; retain bounded reference controls. | SB/publication/CAS/fences, mixed alternatives, fault-before-loop, blocking and exhaustion are reproducible through the real API. Disconnecting the production classifier fails a relevant test. |
| 4 | **Measured prefix cost and final integration — bounded follow-through.** Remove demonstrated repeated work, rerun invalidated checks, then the existing final release checks once. | Representative selected helper/runtime executions complete at justified bounds; the external example uses the final observation contract; sequential changes remain accounted for. |

The existing G01/G02/G04/G05/G07 boundaries can remain explicit where their precise unresolved triggers occur. Representation comparison itself is settled; unspecified-byte composition is the remaining boundary, consistent with the adopted DR431 correction. [WG14 issue 0431](https://www.open-std.org/jtc1/sc22/wg14/issues/c11c17/issue0431.html)

There is no standards decision needed to make ordinary ordered byte and member accesses work. The material user decision is whether this SC milestone also owns the inherited full filesystem port. The other immediate dependency is the preprocessing capability question. Everything else above is implementation and focused validation toward the already stated goal.
