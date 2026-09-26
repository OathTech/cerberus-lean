# WP1 follow-up probes during the bounded-stepping regression run

[AGENT, 2026-09-26] These exploratory probes use the current production
experiment and existing Core rules. They do not accept an SC strategy or
discharge WP1's source-summary, retention or correspondence obligations.
The production source stayed frozen during the A+B and three-engine runs.

## Actual Core order sets

[`followup-source-order.lean`](sc-wp1-evidence/followup-source-order.lean) enumerates every context/local
choice for nine finite store-only fixtures, with 40 scheduler entries and
call fuel 64/128. All leaves terminate before the budget; there is no
state-merging or schedule pruning. Trace labels come from actual WP0 receipts.
Different numbers of administrative schedules can have the same access trace.
The independent expectations use these rules: unsequenced operands add no
edge, weak sequencing orders positive effects, and strong sequencing also
orders negative effects. All addresses in the positive fixtures are distinct.

| Fixture | Expected access traces |
|---|---|
| unseq(a+, b+) | ab, ba |
| weak(a+, b+) | ab |
| strong(a+, b+) | ab |
| weak(a-, b+) | ab, ba |
| strong(a-, b+) | ab |
| weak(strong(a-, pure(unit)), b+) | ab |
| weak(unseq(a+, b+), c+) | abc, bac |
| weak(weak(a-, b+), c+) | abc, bac, bca |
| strong(weak(a-, b+), c+) | abc, bac |

The expectations distinguish invented order (forcing a- before b+ across
weak) and missing order (permitting b+ before a- across strong). They are
finite fixture evidence, not a proof of the general source relation. No
atomic accesses, C-call indeterminate sequencing, fork/join or synchronization
are claimed. The historical explanation is Memarian's *The Cerberus C
semantics*, §§4.3 and 6.2 (printed pp. 65–68, 101–111):
[Cambridge technical report](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-981.pdf).

The nested strong-then-weak case is significant: an action's original negative
polarity cannot by itself determine what a later weak boundary exports. The
inner strong boundary has completed the action. A candidate source algebra
therefore needs to track the causal frontier of value completion separately
from the full set of side effects, including the effect of strong joins on
that frontier. Merely filtering the initial syntax for positive actions loses
this order.

The same-address two-store control reports exactly UB035_unsequenced_race in
both access orders. A separate selected Core prefix performs both writes,
then enters an Eproc whose Esave/Erun loop never returns. It is still
incomplete after 1,000 further steps, with no extra memory receipts. This
demonstrates delayed detection in the inherited Core checker: the enclosing
unseq never becomes a value. The fixture is hand-built Core using Eproc;
it is not a claim about C lowering or Eccall support. This is an obligation
for the proposed first-conflict monitor, not a new race algorithm.

## SeqRMW expansion candidate

[`followup-rmw-expansion.lean`](sc-wp1-evidence/followup-rmw-expansion.lean) expresses a non-forwarding byte
operation using a positive load, a negative store and the saved load value.
It is hand-built Core, not a rewrite of SeqRMW or new support in the executor.
An intervening sibling store completes once, the deferred store completes
once, and the program returns the old value. A second fixture uses the same
function-pointer metadata dependency as the stale-updater counterexample:
the update sees the sibling's publication. Both pass at call fuel 64/128.

This candidate still needs forwarding, evaluation timing, types, error
prefixes and source-order treatment. In particular, historical SeqRMW is
indivisible relative to indeterminately sequenced C calls in the same thread
(thesis §4.3, printed pp. 68–69), while the concurrency instance needs its
load/store to be non-atomic relative to other threads. A bare expansion does
not establish both properties. The experiment currently refuses actions
unsequenced with C calls, so these examples cannot certify that boundary.

## Inherited retained state

[`followup-retention.lean`](sc-wp1-evidence/followup-retention.lean) repeatedly executes a fixed-width
two-store unseq inside a bound, followed by an Erun backedge. Three allocations
(including errno), one thread and disabled receipts stay fixed. Selecting
context zero gives the following derived retained counts:

| Negative action? | Scheduler entries | Driver trace entries | Environment bindings | Next fresh symbol |
|---|---:|---:|---:|---:|
| no | 128 | 42 | 0 | 5 |
| no | 1024 | 342 | 0 | 5 |
| no | 8192 | 2730 | 0 | 5 |
| yes | 128 | 26 | 13 | 18 |
| yes | 1024 | 205 | 102 | 108 |
| yes | 8192 | 1638 | 819 | 824 |

These are retained field counts, not RSS or a complexity theorem. Positive
and negative fixtures take different administrative steps per iteration;
their equal-budget rows are not equal-work timing comparisons. The fresh
symbol counter itself is expected to increase; the problematic retained
objects are the environment bindings and inherited trace. Negative hoisting
allocates temporary binders, update_env inserts them, and Erun retains the
current environment. No reclamation or trace-policy change is implemented.
The future scale experiment must separately attribute these inherited costs
and the new scheduler/monitor/receipt costs; it cannot claim the whole
machine is bounded merely because causal summaries are compact.

## Next proof/domain work

Do not infer `sb` from scheduler order. Derive a relation against actual
Core positive/negative, weak/strong, call and fork/join rules before selecting
a clock representation. Keep source `sb` and synchronization `hb` separate.
Reference-counted endpoints, vector summaries and dynamic clock schemes need
precise reclamation invariants; older atomic publications can retain causal
information after the publishing strand retires.

The actual pinned reference requires explicit hypotheses: `SC_condition`
excludes fences and allocation/deallocation actions, and
`well_formed_threads` requires `indeterminate_sequencing`. `tot_condition`
additionally requires atomic initialization before all accesses to that
location and globally bounded executions (its executable implementation of
the bound is a stub). A finite-prefix/current-memory construction does not
automatically establish these program-level hypotheses or Core receptiveness.
The WP-C statements, accepted scalar domain, fence extension, source-summary
invariant and substantive Core-to-reference lemma remain to be built.

These standalone evidence files were added after the frozen regression run
and checked separately against the same generated implementation. Their
commands, source/output hashes and results are recorded in
`sc-wp1-evidence/followup-probes.json`. They are outside the Unit library
globs and add no standing gate. The regression record identifies the exact
production, test and proof sources used by the full run.
