# Explicit comparison profiles

`scripts/coreb-diff.py` defaults to `--comparison exact`: all emitted event
records and terminal node counts must match. This remains the frozen generated
campaign's profile. `--comparison stutter` permits additional singleton ND
nodes and repartitioning of observation batches inside a genuine-choice
interval. It is infrastructure for later Nice experiments, not a Nice AST,
checkpoint implementation or equivalence theorem.

The stutter profile first validates each lane independently: observation
boundary numbers must name the next ND node; node numbers must be consecutive;
each branching node must match its full tape entry; visited/choice counts and
terminal placement must agree with the emitted log. Known Core step-info,
driver-effect and memory-receipt shapes are checked before any erasure. Unknown
channels, event tags, fields or ND kinds refuse comparison. In particular, no
future checkpoint is silently erased: its actual AST/semantics and a subsequent
explicit observation profile must define that behavior first.

The projection accumulates observations into ordered segments. Each genuine
multi-successor ND node ends a segment and retains its full parent, ordered
alternatives, selected index, kind and choice ordinal. The final segment ends
at the actual active/killed terminal node. Within a segment:

* Driver and memory event lists retain every payload and their respective order.
* Stdout and stderr deltas concatenate separately, preserving their byte order
  as represented by the model's strings.
* Singleton and trivial-guard ND bookkeeping and boundary numbers are erased.

The source observation schema does not provide interleaving between different
channels within a segment, so this profile asserts only their separate orders.
It retains the known before/after relationship to genuine choices: moving a
store or output delta across a choice barrier is a mismatch. Global flattening
of all effects is not this projection.

Header configuration and binary/input identities remain exact (only recording
origin is ignored). Full choice entries, terminal outcome, completion flag,
terminal kind and choice count remain exact. The visited-node count can differ
between lanes after each lane has passed its own consistency check. Resource
failure, absent completion, refusal and unsupported observation schemas never
become successful comparisons through this profile.

For example, after building the normal entrypoints:

```sh
python3 scripts/coreb-diff.py tests/z2-probes/nd/order3.c \
  --comparison stutter --choices 1 --summary-json
python3 -m unittest discover -s tests/coreb -p 'test_*.py'
```

Focused controls cover extra singleton nodes, same-segment repartitioning,
cross-choice store movement, changed memory/output/order, branch metadata,
outcome/header drift, malformed logs and unknown checkpoint channels. The
unchanged real `order3.c` and a generated pointer/loop case also complete in
both directions under the profile. A real CoreB-only singleton insertion is
a separate source-mutation control still to be run against this profile; these
JSON-only examples do not replace that execution-path test.
