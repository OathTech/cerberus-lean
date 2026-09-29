# SC MVP scope: deliver the semantics; defer Iris integration

Date: 2026-09-25. [USER] after the independent re-review:

> we do not try to land an Iris integration, but instead focus on an MVP which just builds a coherent and correct SC model

This direction adopts RR1 of the [re-review](2026-09-25_sc-concurrency-plan-rereview.md)
at `8391bf19e894550e08b9a998cbd46f3c8afdc753`, which reviewed
`a740c48aea28852d9ed2e334c9bcb49eefaba17b`. The re-review is retained verbatim.
The [master plan](../../SC-CONCURRENCY.md) and technical design are updated
with the following boundary; earlier reviews and responses remain historical.

## MVP boundary

Deliver coherent, correct and usefully executable SC semantics over existing
Core and concrete memory, available from Lean. Keep the actual configuration,
transition choices and observations, semantic atomicity boundaries, bounded
runner, initialization/finalization and failure/resource laws. Production
execution, replay and V1/extended validation cases consume this interface.
A justified whole-machine relation is sufficient; the interface need not
have the shape of any particular reasoning framework.

The existing ordinary-object, source-order/race, atomic-operation, scale and
reference-correspondence requirements remain. This is a reduction in consumer
integration work, not adoption of the first review's narrower C profile or a
weaker correctness claim. WP-C still tests and justifies the connection to
the precisely stated reference domain. There is no Iris prerequisite at WP1,
V1 or public SC delivery, and no claim of demonstrated Iris compatibility.

## Deferred Iris task

The later task owns the Iris `Language` instance, mapping to its thread pool,
values/stuckness and observations, consumer-specific scheduling correspondence,
package/pin adoption, and the external fork/join or publication proof example.
Resource algebras, WP rules, adequacy and application proofs remain there too.
No generic adapter framework is needed in this MVP merely to prepare for it.

This later integration may require adapters or additional lemmas. That cost
is not established by the semantics release. Exposing the real definitions
and proving runner/semantic laws preserves a useful basis for future work
without adding a second integration project to the MVP. The historical
consumer inspection is recorded in the re-review; this revision neither
inspects nor changes the consumer checkout.

## Re-review follow-through

The reviewer accepts the finite WP0 and bounded WP1 work order. There is no
new planning phase and no new requirement for a plan-only review before WP0.
Existing independent audit and mainline landing requirements remain in force.

**RR2 is the first focused primitive-state check in WP0.** Source inspection
agrees with the review: OCaml `load` updates `last_used` before a `_Bool` trap
failure; Lean `loadM`'s trap path uses a failure helper that returns the input
state. Test matching live one-byte states (address 100, allocation 7, byte 2,
incoming last-used identity 99), exact kill/post-state, byte 0/1 controls and
failure before `do_load`. Execute the actual primitives before observations.
This record does not claim that reproducer has run. If confirmed, isolate the
small sequential repair with regression evidence, then establish observer
erasure against the corrected primitive. Do not omit the field or replace
the test with a successful operation followed by an explicit kill.

**WP1 must test proof risk with a substantive general lemma.** Identify the
riskiest link from actual Core transitions to the reference invariant or
linearization argument, demonstrate one general result about it using the
experiment's production definitions, and report the hardest unresolved
obligation. A wrapper theorem or assumed reference predicate does not do
this. Keep the fragment bounded; full correspondence is not required before
WP0 or V1, but broad feature expansion cannot substitute for this evidence.

These are targeted follow-through items within the adopted packages. Current
status stays in the master plan. This commit changes documentation only;
it makes no runtime correctness claim, changes no consumer code, and does
not merge to mainline or push.
