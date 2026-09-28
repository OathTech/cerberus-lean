# Four corpus cases complete without a UB diagnostic

We ran 30 intentional C vulnerability fixtures through the fork's OCaml and
Lean engines after rebuilding `mdd/cerberus-lean` at
`a7dc36e2fd278af983dc38054d671c5f4652a4db` on 2026-09-28 in WSL Ubuntu.
Both engines reported UB in 25 cases, completed four cases with `Defined`,
and could not complete one case because of unsupported variable-length arrays.

This report includes standalone reproducers for the four completed cases and
asks which should be diagnosed or documented as model limitations. It does
not propose a semantics change. These are deliberately unsafe local fixtures,
not newly discovered vulnerabilities in an application.

## Cases and questions

All four reproducers were rerun independently of the original input-loading
adapter. Both engines exit 0 and report `Specified(0)` with empty modeled
stderr and `blocked: "false"`. The complete captured observations and source
hashes are in [observed.json](observed.json).

| Reproducer | Operation | Modeled stdout, both engines | Question |
|---|---|---|---|
| [overlapping_memcpy.c](overlapping_memcpy.c) | `memcpy(b + 2, b, 10)`, through the fixture's volatile function pointer | `value=a\n` | Should overlapping ranges produce a UB diagnostic? |
| [intra_object_overflow.c](intra_object_overflow.c) | `object.left[8] = 42`, with `left[8]` followed by `right[8]` | `right=42\n` | Should bounds be checked against the array subobject, or is this outside the concrete model's intended scope? |
| [uninitialized_heap_read.c](uninitialized_heap_read.c) | Read byte 3 of an uninitialized eight-byte `malloc` allocation and pass it to `printf` | `value=UNSPEC\n` | Is propagating an unspecified value into this library call intentional? |
| [uninitialized_stack_read.c](uninitialized_stack_read.c) | Read byte 3 of an uninitialized `volatile unsigned char[8]` and pass it to `printf` | `value=UNSPEC\n` | Is this the same intended treatment, or should automatic storage be handled differently here? |

### Overlapping `memcpy`: an acknowledged missing check

The source range `[b, b + 10)` overlaps the destination range
`[b + 2, b + 12)`. C11 draft N1570, section 7.24.2.1 paragraph 2, specifies UB
for overlapping `memcpy` ranges. This case has a clear ISO C expectation.
[N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)

The concrete implementation already has an explicit overlap-UB TODO in
[`memory/concrete/impl_mem.ml`](../../../memory/concrete/impl_mem.ml)
(`memcpy`, line 2679 at the tested revision).
[`CerbMem.lean`](../../CerbMem.lean) (`memcpyM`, line 2936) explicitly inherits
that TODO. This looks like an acknowledged shared-model limitation rather
than an OCaml/Lean disagreement. Is implementing this check planned, and
should the limitation be stated in the supported profile in the meantime?

### Array subobject bounds: ISO expectation versus model scope

The index is exactly one past `left`, even though the resulting address is
inside the enclosing struct allocation. N1570 section 6.5.6 paragraph 8
prohibits dereferencing a one-past pointer; Annex J.2 also lists out-of-range
subscripts as UB even when an adjacent object appears accessible.
[N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)

The observed `right=42` confirms that the store was reached. The concrete
model's `is_within_bound` checks the enclosing allocation's base and size
(`memory/concrete/impl_mem.ml`, line 712 at this revision). Is subobject-bounds
checking intended for this model, or should this outcome be documented as
an intentional difference from strict ISO array bounds?

### Uninitialized bytes: clarification requested

These two fixtures read `unsigned char` values and then cast them to
`unsigned` for `printf`. We are not assuming that every uninitialized
character load must produce UB. The treatment of indeterminate values,
including their use by library functions, is discussed in
[WG14 DR451](https://www.open-std.org/jtc1/sc22/wg14/www/docs/dr_451.htm).
Does the model deliberately allow these complete programs to return
`Defined` while printing `UNSPEC`, or should either use be rejected?

## Reproduce

After the repository's normal build and smoke-test setup, run from its root:

```sh
opam exec --switch=. -- bash lean_frontend/docs/2026-09-28_ub-detection/run.sh
```

The script checks both driver freshness stamps and the libc pin, loads the
project libc in both engines, and runs each case with a 60-second timeout
under `scripts/capped` (8 GiB by default). OCaml uses `--mode=random`; Lean
uses `--first`. It records stdout, stderr, exit statuses, commands and hashes
in a new `.tmp/ub-detection.*` directory, validates the observations with
`scripts/observations.py`, and compares their full contents. Agreement is
not an assertion that the C program is defined.

For this report the reproducers were in a feature worktree and the binaries
were the existing freshly rebuilt main-workspace binaries. The script's
optional first argument selects that build checkout; the recorded engine
revision is the commit above. No engine sources changed for this report.

## Scope of the original run

The original `testing-data` corpus required file inputs. For Lean, we kept
each C fixture unchanged and replaced only its private `load_input` helper
with an allocator/copy of the supplied bytes. The four cases here used
`abcdefghij`, `8`, `3` and `3`, respectively. The attached reproducers remove
that loading code and fix the same copy length or index directly.

The original file-reading programs also ran unchanged in OCaml. All 29
completed observations matched their corresponding OCaml adapted runs.
Of the 30 primary OCaml/Lean comparisons, 25 matched fully, four differed
only in UB source locations, and the VLA case was incomplete. Separately,
29 safe controls completed with matching return value 0; the VLA control
was unsupported. These controls are distinct from the four reproducers
included here.

These results cover the supplied inputs and the selected execution traces,
not all possible inputs or schedules. No current pristine-upstream build
was tested for this report. `Defined` is an execution result of this model,
not a proof of ISO C conformance or absence of UB.

## Provenance

The fixtures originated in the local test corpus. OpenAI Codex assisted
with reducing the four reproducers, executing them, and preparing this
report. The attached observations were captured from the actual programs.
