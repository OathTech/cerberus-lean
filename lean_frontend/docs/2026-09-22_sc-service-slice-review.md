# SC helper services and typed faults

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


[AGENT] Implementation review, 2026-09-22. Governing scope and fidelity policy:
[charter](2026-09-21_charter-sc-prototype.md) and
[operational contract](2026-09-21_sc-operational-contract.md).
The production unit suite, external import example, all 39 required integration
lanes and the 864-row three-engine comparison pass. The latter retains the
preceding checkpoint's exact per-case classifications and decoded results.
These checks do not establish completion of the SC prototype.

## Why the driver needs saved services

The original ND bind runs through successive active nodes in one invocation.
Recording every access in a helper's final journal therefore does not expose
its intermediate memory states to another thread. Reconstructing those states
from final bytes would also lose equal-valued writes, captured reads and prefix
failures.

The shared ND carrier now has an explicit `NDsuspend` continuation. Bind,
lifting, checked observation and the ordinary runners preserve or resume it.
The concrete memory implementations enable suspension separately from passive
observation. Before the next observable primitive, an enabled helper returns
its continuation; that continuation runs the original primitive against the
state supplied at resumption. The first primitive runs immediately. Primitive
failure remains a failure, with all preceding effects retained.

Ten paired public primitive bodies are wrapped: access, allocation, lifetime
and varargs operations. An independent source comparison checks that all twenty
original OCaml/Lean bodies remain identical after removing the new wrapper and
its indentation. Allocation with initialization, and each varargs primitive's
metadata operations, remain within their original primitive. Passive observation
and the ordinary sequential path leave suspension disabled.

## Complete machine and selection

`Driver.sc_machine_state` contains the current driver state, saved services,
and filesystem ownership. A saved service carries the actual request, accumulated
receipt and a `driverM` continuation over the existing driver state. This avoids
recursion through the new machine's own state-function argument.

`sc_step` is the complete-machine interface. For each installed thread,
`sc_machine_choices` offers its saved service first, then an existing owned
Core request, then its current Core alternatives. A saved thread's old Core
arena is not evaluated and discarded during choice construction. Other eligible
threads remain available. Lookup compares thread identifiers; it does not
compare or deduplicate continuations.

`sc_capture_service` interprets the selected service before binding the outer
scheduler loop. It saves only that service's continuation. Ordinary ND branches,
guards, labels and duplicate alternatives survive. Resumption restores only
the saved request and receipt into the current state, retaining the current
memory, global journal, supplies and other threads' updates.

The existing batch entry uses `sc_project`. Every returned ND continuation
carries the service state produced by its preceding node. Reinitializing it at
each node loses paused work. Direct machine transitions, including failures,
retain the complete configuration; the batch interface projects driver state.
Fuel and exploration bounds remain explicit experimental parameters.

## Filesystem ownership and source order

The existing `drive_fs_step_with` computes results using a captured filesystem
state, performs memory work, then commits its filesystem result. Allowing a
competing filesystem operation to commit during that memory work can overwrite
its updates. Moving the original commit earlier changes prefix-failure state.

The machine preserves each existing abstract filesystem transaction against
competing filesystem services, while permitting intervening Core and memory
operations. Its owner is an operational scheduling field. It emits no C lock,
stream identity, synchronizes-with edge or happens-before edge. ISO stream-lock
coverage remains a separate source/adapter issue. This mechanism preserves the
current filesystem transaction; it is not a new claim about the granularity of
every ISO library implementation.

Completion uses the current driver state, current thread map and current step
counter. Only the owning thread's result and its filesystem transaction are
retained across suspension. A resumed failure keeps its written prefix and the
original uncommitted completion state.

`sc_internal_annotation` carries earlier effects of the same helper request
into later observations, following the serial concrete helper body. It adds
no order between distinct requests merely because the scheduler ran them in
that order. The eventual Cmm adapter must still account for its action/location
domain; these helper laws do not establish a universal ISO library ordering rule.

The existing diagnostic counter is asymmetric: Core and filesystem completion
increment it, while `perform_memop_with` and `action_request_with` do not.
A draft test incorrectly expected the latter to increment it. The retained
failure was resolved by checking the existing source rule, without changing
the handlers.

## Fault identities and reasoning interface

Twenty-one existing SC diagnostics now have shared `sc_fault` identities.
Rejected orders retain the actual request kind. Descriptive categories separate
representation, observation, protocol, order and unfinished implementation
cases; they introduce no new UB or coverage policy. The OCaml and Lean renderers
preserve the diagnostic text. Unspecified CAS bytes remain an explicit failure
with preceding effects retained. The public entry still explicitly reports its
pending race/consistency checker after execution.

The exported laws cover the actual machine's offered choices, exact saved
continuation and receipt, preservation of current state on restoration,
failure-time machine state, duplicate service alternatives, and every case of
the batch action projection. Fault laws preserve constructor identity, separate
faults from UB, and state the uninitialized-step behavior at zero and positive
fuel. They do not supply a customer logic or a whole-program ISO theorem.

## Validation boundary

The composed candidate freshly compiles seventy-five affected Lean modules,
including the main entry, and both complete Lem target generations. Native
Lean and fresh OCaml controls exercise thirteen service cases and six fault
cases. These include an actual Core batch program with another thread's store
between a copy's read and write, current lifetime checks, filesystem prefix
failure, duplicate branches, and all twenty-one diagnostic renderings.

Four isolated source disconnections each produce their designated failing
control: disabling pauses, losing the saved receipt, removing filesystem
ownership, and erasing projected service state. Each uses freshly generated
and compiled OCaml sources; none counts a crash or timeout as detection.
Original failed build, proof and test attempts remain in the evidence.

The production unit suite includes these Lean targets and the actual OCaml
control executable against this checkout's generated modules. Fresh production
builds, register/manifest reviews, the required sequential integration gates,
the mandatory three-engine report and durable evidence retention are complete.
Location interpretation, race/consistency checking and the remaining C entry
work remain in the prototype's scope.

The first production fuel-form gate identified a missing certificate for
`sc_driver_machine_lemFuel`. Its generated zero branch already returns the
explicit fuel failure, but Lem skips the automatic theorem for a destructuring
unit argument. `sc_driver_machine_lemFuel_zero` is supplied
at the generated worker's root name in the existing imported obligation carrier,
with a kernel `rfl` proof. This changes no executor body or exhaustion policy.

The targeted production runtime suite passed nine entries, but its later axiom
import rejected a stale `Unit.FuelExemplar` artifact. Fresh compilation then
identified two old proof steps that unfolded memory allocation/store without
accounting for the new primitive wrapper. They now use the general disabled
suspension law, connected to the exemplar's local observer by a constructor
case proof. The original forall-fuel, forall-address-space theorem statement
is unchanged. Fresh `fuel-exemplar-test` compilation passes at the existing
limits (the successful Lean module took 1.2 seconds). The incomplete unit
attempts and the intervening failed proof attempts remain retained.

A later full unit attempt passed all twenty-five runtime entries and kernel
checks, then the parameterization selftest rejected a literal address cursor
in the new memory-suspension fixture (A3). The fixture now takes its address
space bound from the harness, just like its fuel. The parameterization scan
passes; this changes no executable semantic bound. The following attempt then
correctly rejected three new ambient fuel wrappers without their universal-fuel
pins. Part 1 of `TotalityProofTest.lean` was regenerated from the actual worker
heads: nineteen wrappers now equal nineteen kernel `rfl` pins, including
`sc_capture_service`, `sc_driver_machine` and `sc_project`. Original failed
attempts are retained; no gate or proof limit was relaxed.

The fifth production unit run passes all twenty-five runtime entries and every
included gate. Both current driver freshness checks pass after building all
423 provider jobs. The external package at `examples/sc_consumer` freshly builds
its six statements in 234 ms using the existing freshly built provider. Explicit
axiom queries find only Lean's standard three axioms, with the fault-distinction
statement requiring none. Its own toolchain is 4.32.2 and its inherited LemLib
revision is the provider's `38f87d5`. This is an external import check, not a
cold rebuild of the provider or a build of the customer repository.

The frozen `services-full-20260922-r2` run passes all 39 selected Tier A/B lanes,
with source unchanged and no artifact issues. GCC reports no baseline regression;
all 93 observation-failure plants pass. The mandatory three-engine run passes
864 rows. Its 40 Lean discrepancy IDs, every case's classification and every
decoded three-engine result are unchanged from the RMW/byte-source checkpoint.
Reviewed differences and both-undecodable rows remain explicitly classified.

The first full attempt was interrupted after the source inventory exposed the
external example's unignored `.lake` artifacts. The runner was stopped before
adding the example's `.gitignore`; the fresh run used a new evidence directory.
The original incomplete attempt is retained. No semantic source was changed
during the successful frozen full and three-engine runs.

The [evidence index](2026-09-21_sc-prototype-evidence/services/README.md) retains
verified archives, raw observations, source identities, all failed/interrupted
attempts and the successful checks. A read-only customer source review found
direct memory-step equations that will need the sequential observer/suspension
invariant when adopting this richer state. The provider supplies disabled-mode
and erasure laws; preserving an old proof statement does not justify restricting
SC scheduling. Customer compatibility was not built or certified.

Separate [reference investigations](2026-09-21_sc-prototype-evidence/reference-followup/README.md)
record the pending mixed-size choice and concrete stdio/value-adapter findings.
No new runtime exclusion or reference replacement was implemented by those
investigations. The public checker remains explicitly unfinished.
