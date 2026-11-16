# CoreNice resumable driver interface

This describes the implementation in the owned
[driver model](../../../frontend/corenice/model/driver.lem). It supports the
[breakpoint charter](breakpoints-charter.md); the integrated
[checkpoint](breakpoints-checkpoint.md) records initial executable validation;
the [repair assessment](checkpoint-semantics-repair.md) records current phase
names and the separate legacy-evaluator limitation. Both driver entries here
use the optimized reducer.

`drive_until_breakpoint with_concurrency file argv budget` starts a run and
returns a `nice_run_result` through the existing `driverM`:

* `NiceCompleted result` is genuine program completion.
* `NiceSuspended suspension` is a successful strong-tail encounter. The record
  contains the static site, executing thread, full driver state, configuration,
  remaining budget and the explicit phase to execute next.
* `NiceBudgetExhausted` is incomplete execution. It must not satisfy successful
  coverage or trigger an end-of-tape check.

Existing ND failure outcomes retain their existing channels.
`resume_breakpoint suspension` restores its saved state and continues its saved
phase. It accepts no replacement program, arguments or budget. Its contract is
over suspensions produced by the machine, not arbitrary fabricated records.
The generated Lean functions also take the existing `enumDefs`/`tagDefs`
reader parameters. The host adapter always obtains them from the suspension's
retained file; the intended resume contract requires these same readers.

## What the phase retains

`NiceNonmemory after accumulator pending_threads` retains exactly the loop's
pending work. The accumulator contains deferred per-thread steps, including
their existing action callbacks; it is not recomputed on resume. After an
ordinary tau step the executing thread is placed back at the front, as in the
original driver. Wakeup insertion order is likewise unchanged.

`after` identifies either main execution or the current global initializer.
The latter retains its thread, symbol, type and remaining definitions. A cut in
an initializer therefore neither binds its unfinished result nor repeats its
initialization on resume. On true completion, the existing global binding code
runs once before the next initializer. Main argument, errno and entry-frame
setup also run once.

`NiceRound` begins a fresh scheduler round; `NiceNextGlobal` begins the next
initializer or prepares main. A suspended run retains the actual
`NiceNonmemory` continuation rather than returning to either earlier phase.

The ordinary `drive` entry remains available as an automatic-continuation
reference. Both routes share global setup/completion, startup setup,
per-thread choice construction, scheduler selection and action dispatch.
`process_core_step2` takes a polymorphic terminal action so the resumable route
can preserve its enclosing global/main continuation without copying action,
memory, call, filesystem or exit-routing semantics.

## Accounting and runner obligations

Each entered explicit phase consumes one control-budget unit. A pause stores
the budget after its phase, so resume enters the same next phase with the same
remaining budget as immediate continuation. The generated Lem and ND helper
fuel limits still apply independently. Resetting their wrappers cannot reset
the explicit cumulative budget.

The runner must distinguish the three active results before treating `NDactive`
as terminal. It retains its own tape position, RNG, observations and remaining
traversal budget across a suspension, and observes the state delta leading to
the breakpoint. No pending choice is selected again. Only `NiceCompleted` or
a genuine semantic failure permits final tape-consumption checks.

`BreakpointDriverTests` exercises a cut in a global initializer followed by
another initializer and main, a retained deferred-call frontier under both
competing choices, and insufficient cumulative budgets. `BreakpointTests`
executes nonempty annotation transport and negative-action/RMW reconstruction.
The C suite compares ordinary automatic `drive` against Core and the resumable
route under explicit pause policies, including repeated loop encounters.
