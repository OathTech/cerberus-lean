# Composition witness: typed AIL, CoreNice cuts and Caesium residuals

This is the concrete mapping for
[`composition.c`](../../../tests/corenice/breakpoints/composition.c), supporting
the [breakpoint charter](breakpoints-charter.md). It identifies useful endpoints
for a future simulation sequence rule. It does **not** prove the mapping, a
sequence rule, heap ownership, lexical scope, or Core/CoreNice equivalence.

The witness initializes `x` to zero, calls `bump(&x)`, adds two, calls `bump(&x)`
in a loop until `x == 6`, then returns `x`. The
[executable demo](../../test/CoreNice/BreakpointDemo.lean) reads `x` from each
actual main-procedure suspension and resumes that suspension. Its assertion at
`x == 1` also checks that the translated right operand is structurally present
in the suspended thread's arena. These are in-memory assertions, without
serializing the machine state.

## What was inspected

The AIL tree below was inspected from `Prepared.typed` after
[`Prepared.prepare`](../../differential/Prepared.lean), using the same Cabs JSON
and runtime as the demo. This is the shared typed input used by both target
lowerings, not a reconstruction from the C text. The probe traversed
`typed.2.function_definitions`, the statement nodes and their annotated
expressions; it printed only constructor summaries and source-symbol names.

The source symbols in this fixture are `bump@20`, `main@22`, object-address
`p@19` and object-address `x@24`. Numbers are local producer identities, not a
stable source interface. In particular, `x` has description `SD_ObjectAddress
"x"`, not `SD_Id "x"`.

```text
bump(p):
  AilSblock []
    AilSexpr (assign (indirection (rvalue p))
                    (add (rvalue (indirection (rvalue p))) 1))

main():
  AilSblock [x]
    AilSdeclaration [(x, Some 0)]
    AilSexpr (call (function_decay bump) [address x])
    AilSexpr (assign x (add (rvalue x) 2))
    AilSwhile (less_than (rvalue x) 6)
      (AilSblock []
        [AilSexpr (call (function_decay bump) [address x])])
    AilSreturn (rvalue x)
```

The annotations distinguish lvalues for `x`, `p` and the dereferenced target,
pointer rvalues for `&x` and loaded `p`, basic rvalues for arithmetic and the
condition, and void rvalues for calls to `bump`. The extra `rvalue` and
`function_decay` nodes matter: a source boundary after a call includes its
argument evaluation and return; a boundary after a condition includes its
loads and conversions. A statement's printed source line alone cannot establish
that phase.

The owned [translation](../../../frontend/corenice/model/translation.lem)
calls `erase_loop_control` before `translate_stmt`. Its normalized AIL retains
the while node but inserts these blocks and labels:

```text
outer block []:                         -- occurrence 5
  while (x < 6):                        -- occurrence 6
    inner block []:                     -- occurrence 7
      original source body block
      generated continue label: skip
  generated break label: skip
```

Consequently, the generated inner and outer block joins below are joins in
**normalized AIL**, not adjacent original C statements. The source body itself
contains only one statement and contributes no direct statement-to-statement
join. This distinction is relevant to a future lifting theorem: it needs to
account for `erase_loop_control` as well as `translate_stmt`.

## Reached sites and concrete midpoint values

The demo reaches **15 main-procedure encounters at eight static sites**, then
returns six. It identifies the unique live four-byte allocation whose source
prefix includes `SD_ObjectAddress "x"` and decodes its actual bytes. The values
below are those observed at suspension, not values calculated from the source.

`origin` is the typed object
`{"stage":"normalized-ail","occurrence":n,"slot":k}` minted by
[`fresh_nice_site`](../../../frontend/corenice/model/translation_effect.lem).
It is not a literal ancestry path through the original typed AIL tree.
The AST carries `NiceNormalizedAil n k`; internal cuts carry `NiceInternal`.
Statement visits and site construction
share a separate provenance counter; site numbers can change when lowering
changes. They do not consume the semantic fresh-symbol supply.

| Site / origin | Role and completed prefix | Observed `x` | Candidate Caesium residual |
| --- | --- | --- | --- |
| 22 / `[1,0]` | Statement join: initialization complete | 0 | `#0`, before the first call |
| 21 / `[1,1]` | Statement join: first call has returned | 1 | `#0`, before `x = x + 2` |
| 20 / `[1,2]` | Statement join: addition/store complete | 3 | End of `#0`, before entering the loop guard |
| 13 / `[6,0]` | Condition ready: guard evaluated and converted to a boolean | 3, 4, 5, 6 | Inside `#1`, with the guard value available and branch selection pending |
| 12 / `[7,0]` | Normalized block join: original loop body complete, generated continue label pending | 4, 5, 6 | End of `#2`, with the backedge pending, allowing administrative steps |
| 14 / `[6,1]` | While restart pending: generated continue wrapper complete | 4, 5, 6 | End of `#2`, before `Goto "#1"`, allowing administrative steps |
| 17 / `[5,0]` | Normalized block join: while has completed, generated break label pending | 6 | False-guard exit toward `#3`, allowing administrative steps |
| 19 / `[1,3]` | Statement join: whole normalized loop complete, source return pending | 6 | `#3`, before evaluating the return expression |

The condition-ready site does **not** correspond directly to entry at `#1`:
Caesium has not evaluated its guard at block entry. A matching configuration
would retain the evaluated condition in its expression context, or a simulation
would explicitly advance Caesium through those evaluations. Likewise sites 12
and 14 have equal visible `x` values but different remaining control work.

The complete first-choice encounter order is:

```text
22, 21, 20,
13, 12, 14,
13, 12, 14,
13, 12, 14,
13, 17, 19
```

This particular run is a useful midpoint witness, not evidence that every
program or nondeterministic execution reaches these sites. The
[focused differential suite](../../../scripts/corenice-breakpoints.py) tests
other control paths and host pause policies separately.

## What the Caesium producer emitted

The existing `refinedc-lean` `ail-to-caesium --lean` executable, from provider
commit `b6ce9de608e741cd9b8c5c116a5b93200d677554`, emitted the following control
shape. This was inspection of its generated code, not a Caesium execution or
consumer proof build.

```text
impl_main(global_bump), locals: x : i32, entry: #0
  #0: x := 0; call global_bump(&x); x := x + 2; goto #1
  #1: if x < 6 then goto #2 else goto #3
  #2: call global_bump(&x); goto #1
  #3: return x

impl_bump(p : void*), entry: #0
  #0: *p := *p + 1; return VOID
```

Source-location wrappers surround these operations. In the inspected output
they refer to lines 54–62 because of preprocessing; the original fixture uses
lines 3–11. Source locations, generated labels, provenance occurrences and
CoreNice sites are different identifiers. The table relates operations and
residual phases; it does not equate those identifiers.

## Candidate relations for a sequence proof

The first useful cut is site 21. A candidate `Q_call` should relate a Caesium
configuration with the remaining `#0` suffix to a CoreNice suspension with
`x == 1`. It must include substantially more than that numerical fact:

- **Memory and source environment.** Relate Caesium's location for local `x`
  to the live Nice allocation, including its extent, alignment, initialized
  integer value, lifetime and the relevant memory history. The call has used
  a pointer to this same object and returned. The demo's unique-allocation
  lookup does not establish ownership, non-aliasing or a general heap relation.
- **Residual program and temporaries.** Relate the pending addition and later
  loop/return to the actual suspended arena. Nice may represent already-bound
  variables through substitution and generated temporaries; Caesium uses its
  local environment and expression contexts. Require the appropriate value
  relation, not syntactic equality of environments or a claim that all
  temporaries have disappeared.
- **Ambient continuation.** Retain the outer sequence context, saved labels,
  call/control frames, pending cleanup and eventual return destination. A
  returned `bump` call and a still-active `main` frame are distinct facts.
  For a general rule, also retain pending unsequenced siblings and the current
  thread's place in the scheduler.
- **Execution phase and observations.** The model suspension carries its
  configuration, thread, phase, remaining driver budget and complete state.
  The host runner additionally retains the choice cursor or RNG, observation
  prefix and remaining runner fuel. They must not reset when a suffix starts.
  A semantic theorem would state which resource components are administrative
  and how observable prefixes concatenate; the finite demo alone does not do so.

The intended local obligations would show that the initialization/call prefix
establishes `Q_call`, and that **every** related midpoint can execute the suffix
with the intended matching observations and exits. The current demo checks one
concrete midpoint and its continuation, rather than quantifying over all states
satisfying `Q_call`.

For the loop, useful candidates are `Q_guard(n, b)`, where `x == n` and the
already-computed guard boolean is `b = (n < 6)`, and `Q_backedge(n)`, where a
normally completing body has left `x == n` with its restart pending. The witness
suggests a loop invariant such as `3 <= n <= 6`, together with the memory and
control relations above. The condition temporary must relate to the boolean
decision, even though Nice obtains it through its test-expression and
specified-value conversion. A general formulation would account for arithmetic
bounds, invalid/unspecified values, and non-normal outcomes explicitly.

These phase cuts do not supply a dominance, source-normal completion or scope
theorem. Shared Cabs-to-AIL normalization can already route `continue` through
the body wrapper; the owned normalization adds another wrapper. A source
`continue` can therefore reach a normalized join and the while-restart cut.
A break can target the generated label after site 17. A jump into a suffix
need not traverse its preceding breakpoint. A
sequence theorem therefore needs separate exit relations and entry-sensitive
contracts for multi-entry regions. The focused abrupt-control fixtures test
such behavior, but this example itself has no abrupt loop exit.

## Reproduce the concrete observations

From this repository root after the normal frontend provisioning and focused
executable build, use the same Cabs artifact for both tools. `REFINEDC_ROOT`
below names a separately provisioned checkout of the stated provider revision;
it is needed only for the Caesium output inspection.

```bash
mkdir -p .tmp/breakpoint-mapping
_build/default/backend/driver/main.exe --runtime=_build/install/default \
  --cabs-json tests/corenice/breakpoints/composition.c \
  > .tmp/breakpoint-mapping/composition.json
env LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/corenice-breakpoint-demo \
  _build/install/default .tmp/breakpoint-mapping/composition.json

cc -E -C -undef tests/corenice/breakpoints/composition.c \
  > .tmp/breakpoint-mapping/composition.i
env LEAN_ABORT_ON_PANIC=1 \
  "$REFINEDC_ROOT/AilToCaesium/.lake/build/bin/ail-to-caesium" \
  --runtime _build/install/default/lib/cerberus-lib/runtime \
  --root . --source tests/corenice/breakpoints/composition.c \
  --cpp .tmp/breakpoint-mapping/composition.i --coq-root breakpoint_demo \
  --out .tmp/breakpoint-mapping/caesium --lean \
  .tmp/breakpoint-mapping/composition.json
```

Use the repository's optional memory-cap wrapper where required by the host.
The demo checks live heap values, pending-suffix containment and whole-artifact
breakpoint erasure, and detects injected repeated-left, skipped-suffix,
extra-choice and missing-site controls. Its compact samples are reproducible
diagnostics, not a persistent state format. The typed-AIL inspection above can
be repeated at `Prepared.prepare`'s return boundary before either lowering;
the source of `erase_loop_control` explains the subsequent generated labels.
The demo also checks and prints the main block's actual binding/statement
constructor sequence and the original singleton loop-body shape before lowering.
