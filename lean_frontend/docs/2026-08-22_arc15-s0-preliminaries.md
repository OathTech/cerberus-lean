# Arc 15 / S0 — preliminaries + scaffold (record)

Date: 2026-08-22. Provenance: [AGENT:arc15-laneA-S0] throughout.
Charter: `2026-08-22_arc15-spec-lab-charter.md` (S0 slice). Grounding:
`notes/2026-08-22_harness-statement-template.md` (container repo).
Worktree: `worktrees/cerberus-lean-spec-lab`, branch `spec-lab`. All
builds via `scripts/ce` + `scripts/capped`.

## Probe (a) — golean structure-parameterization (read-only)

Sources read: `deps/golean/CLAUDE.md`,
`docs/2026-08-12_verified-examples-arc-charter.md`,
`docs/2026-08-12_example-spec-form.md` (§11, the harness ruling),
`docs/verified-examples.md` (the gallery, incl. the
`reverse_harness_v` copy-relational entry).

What golean does:

* **The harness ruling (user-ruled 2026-08-13, final form):** every
  example ships ONE fixed three-phase Go harness (`setup_*_state` from
  scalar parameters → the call under test → `test_*_state` folding
  memory analysis into return values). The Lean statement is over the
  machine's native entry: ∀ well-typed argument values,
  ∃N-∀fuel≥N-∀choices, the run returns `.ok` with the specified
  values. Three properties are RULINGS: no AST splicing/program
  families; no Lean-side heap readback in headlines ("we do not have
  any memory reasoning at all" at top level); no frame clauses
  (implicit framing inherent in the empty-heap entry). CBMC parallel
  drawn explicitly.
* **Structure parameterization:** structures are built by the setup
  phase from SCALAR parameters — e.g. `reverse_harness_v(n, seed)`
  builds `s[i] = seed + i` of length `n`, saves a pre-copy `t` (a
  history ghost materialized as real Go, "ghost ladder rung 0"), and
  the test phase checks `s[i] == t[n-1-i]`. The gallery states input
  honesty per entry: these are input FAMILIES (`n`, `seed`), honestly
  weaker than ∀-data.
* **The ∀-data mechanism was DESIGNED, NOT BUILT** (§11
  "Variable-size inputs"): a choice-consuming input pick (CBMC
  `nondet_*` pattern) putting input data under the headline's ∀ch,
  with a recorded DIFFERENTIAL OBLIGATION — the pick needs a go-run
  counterpart so the oracle can witness picked inputs.
* Also load-bearing for us: enumeration banned as a proof method
  corpus-wide (symbolic in inputs); domain conditions are part of the
  claim (four kinds, incl. "machine idealization" — said out loud);
  harnesses printed in full as a rendering rule; automation strictly
  untrusted-method zone with FROZEN headline vocabulary.

Adopt / differ (the attribution now lives in
`speclab/README.md` § "Attribution — the golean idiom lineage" and
the `SpecLab/MkHarness.lean` header): we adopt the three-phase shape,
observables-only statements, copy-relational checks, claim-honesty
rules, and the CBMC framing. We differ on the input channel — our
mechanism A compiles the choice stream INTO the program (`choices[]`),
resolving choice before the program exists, which discharges golean's
recorded differential obligation (each instance is a closed program
the oracle runs natively) and upgrades input families to genuine
model-∀ via `decode∘encode = id`; and we deliberately accept the
program FAMILY golean bans, because our oracle consumes C text (the
shared channel) and the symbolic-initializer lemma route collapses the
family back to one parametric theorem.

## Probe (b) — argv parity (mechanism B go/no-go)

Mechanics found by inspection first:

* Oracle: `backend/driver/main.ml:512-514` defines `--args
  "ARG1 ARG2 ..."`; `main.ml:111-113` splits on whitespace;
  `backend/common/pipeline.ml:598,602` passes `("cmdname" :: args)` to
  `D.batch_drive`/`D.drive`.
* Lean: the generated semantics FULLY supports argv —
  `generated/Driver.lean:470` `prepare_main_args` allocates and
  initializes the objects pointed to by `argv[]` (incl. the
  `argv[argc]` null per the STD) from an `arg_strs : List String`.
  BUT the driver CLI hardcodes the list: `Main.lean:866`
  `drive (CerbTags.tagDefs ()) false runFile ["cmdname"]` — there is
  NO flag to supply additional args. (`--call`/`--call-args` is the
  arc-7 symbolic-call harness entry, a different mechanism.)

Probe programs (committed inline here; run from the worktree, oracle =
`_build/install/default/bin/cerberus --runtime=_build/install/default
--nolibc --exec --batch --mode=exhaustive`, Lean = `--cabs-json` +
`cerberus-lean --batch`):

```c
/* argv1.c */ int main(int argc, char* argv[]) { return argc; }
/* argv2.c */ int main(int argc, char* argv[]) {
  if (argc < 2) return 100;
  return argv[1][0];
}
/* argv3.c */ int main(int argc, char* argv[]) {
  int n = 0;
  for (int i = 0; i < argc; i++)
    for (int j = 0; argv[i][j]; j++) n++;
  return n;
}
```

Oracle outputs, VERBATIM (timing lines elided as marked):

```
== argv1 (oracle, no --args) ==
Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
exit=0
== argv1 (oracle, --args "ab cd") ==
Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
exit=0
== argv2 (oracle, no --args) ==
Defined {value: "Specified(100)", stdout: "", stderr: "", blocked: "false"}
exit=0
== argv2 (oracle, --args "ab cd") ==
Defined {value: "Specified(97)", stdout: "", stderr: "", blocked: "false"}
exit=0
== argv3 (oracle, no --args) ==
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
exit=0
== argv3 (oracle, --args "ab cd") ==
Defined {value: "Specified(11)", stdout: "", stderr: "", blocked: "false"}
exit=0
```

(each preceded in the transcript by `Time spent: ... seconds`, elided;
values check out by hand: argc 1→3; `argv[1][0]` = 'a' = 97; total
argv chars 7 = len("cmdname"), 11 = 7+2+2.)

Lean outputs, VERBATIM:

```
== argv1 (lean, --batch) ==
Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
exit=0
== argv2 (lean, --batch) ==
Defined {value: "Specified(100)", stdout: "", stderr: "", blocked: "false"}
exit=0
== argv3 (lean, --batch) ==
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
exit=0
```

Verdict: at the only comparable point (no driver args → both sides
`["cmdname"]`) the pipelines agree BYTE-IDENTICALLY on all three
probes, including argv3's walk over actual argv string memory — the
`prepare_main_args` machinery (allocation, init, null-termination) is
live and in agreement on both sides.

**Mechanism-B recommendation: GO-PENDING-ONE-SMALL-DRIVER-FLAG.** The
semantic substrate is present and verified in agreement on both sides;
what is missing is ONLY a Lean driver CLI flag (an `--args` equivalent
threading a `List String` into the `drive` call at `Main.lean:866`,
mirroring `main.ml:111-113`'s whitespace split + `pipeline.ml:598`'s
`"cmdname" ::` composition). Est. S (one flag parse + one plumbing
line + a differential probe re-run with args on both sides). NOT
implemented at S0 (park-don't-improvise; the template stays on
mechanism A regardless — charter: B is an upgrade, not a dependency).
If a rung wants B, the flag is a registered small work item.

## Probe (c) — CN magic-comment filtering in cabs-json

Mechanism (inspection): `parsers/c/c_lexer.mll:11-12,270-283,459-515`
— `/*@ ... @*/` lexes as a magic token ONLY when
`at_magic_comments` is set; that flag is the `--switches=at_magic_comments`
switch (`ocaml_frontend/switches.ml:96-99`), OFF by default. Neither
`test_exec.sh` nor `test_cn_coverage.sh` nor our probe invocations
pass it, so CN annotations are ordinary comments in the cabs-json
path.

Probe files (deps/cn/tests/cn, three annotation shapes: top-level
`/*@ function ... @*/` block, statement-level `/*@ assert ... @*/`,
loop `/*@ inv ... @*/`, and `/*@ trusted; @*/` on main):
`builtin_ctz.c`, `bitwise_and.c`, `forloop_with_decl.c`.

Outputs, VERBATIM (oracle timing lines elided; "magic residue" =
grep count of annotation-body tokens in the emitted cabs-json):

```
== builtin_ctz (oracle exec) ==
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
exit=0
cabs-json exit=0
== builtin_ctz (lean --batch) ==
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
exit=0
magic residue in json: 0
== bitwise_and (oracle exec) ==
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
exit=0
cabs-json exit=0
== bitwise_and (lean --batch) ==
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
exit=0
magic residue in json: 0
== forloop_with_decl (oracle exec) ==
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
exit=0
cabs-json exit=0
== forloop_with_decl (lean --batch) ==
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
exit=0
magic residue in json: 0
```

Verdict: CONFIRMED — CN magic comments are filtered (treated as
ordinary comments) on the cabs-json path; zero annotation residue in
the JSON; zero divergence oracle-vs-Lean on all three files. (Redundant
belt: the branch's cn_coverage lane already sweeps the full 213-file
corpus at 213/213 — this probe pins the MECHANISM and the flag
default.)

## Scaffold (what landed)

* **`lean_frontend/speclab/`** — new Lake package (Lean 4.32.2, relsem
  package-rehearsal model: requires `CerberusLean` by path, shared
  `packagesDir = "../.lake/packages"`, offline-safe). One-way
  dependency direction per the two-part-design constraint (nothing
  under the semantics/relsem references speclab).
* **`SpecLab/Codec.lean`** — self-delimiting codecs first cut with
  KERNEL-CHECKED round-trip lemmas (checked by the package's plain
  capped `lake build`): `decode_encode_u8`, `decode_encode_u16le`,
  `decode_encode_u32le`, `decode_encode_u64le` (wider scalars compose
  from narrower — each proof is the previous lemma + one omega step),
  `decodeElems_encodeElems` (parametric in the element codec's
  round-trip proof), `decode_encode_arrayU16` (u16-length-prefixed
  arrays, `length < 65536` side condition).
* **`SpecLab/MkHarness.lean`** — `mkHarness` v1: `HarnessTemplate` =
  three literal string parts, splice = four-way concatenation with
  `renderByteArrayLiteral` for the two byte arrays (the single trust
  point — no search/replace/escaping); the v1 IDENTITY reference
  template (byte-blaster builder, identity subject, generic
  mismatch-index comparator: 0 / 1+i / 255-on-length-divergence),
  nolibc-clean.
* **`test/Unit/SpecLabTest.lean`** — executable sanity layer (labeled
  TEST, never proof): 10 checks ALL PASSED (codec spot checks incl.
  all 256 u8 values + wire-endianness pin `0x1234 → [52,18]` +
  underrun-is-none; renderer parse-back round trip; splice
  decomposition exactness) + the `--emit-identity`/`--emit-plant`
  emitters.
* **`scripts/test_speclab.sh`** — plant-test runner skeleton
  (test_exec.sh invocation pattern, both pipelines, fail-closed;
  NOT wired into test_unit — lane non-gating until a rung stabilizes).
  Live S0 runs, VERBATIM (tails):

  ```
  test_speclab [selftest] .../identity.c
    oracle: exit=0 verdict=Specified(0)
    lean:   exit=0 verdict=Specified(0)
    expect: Specified(0)
  test_speclab: PASS (both pipelines agree on Specified(0))
  ```
  ```
  test_speclab [plant] .../plant.c
    oracle: exit=0 verdict=Specified(2)
    lean:   exit=0 verdict=Specified(2)
    expect: Specified(2)
  test_speclab: PASS (both pipelines agree on Specified(2))
  ```

  The plant lane is live end-to-end at S0: a corrupted `expected[1]`
  comes back as mismatch-index verdict `Specified(2) = 1 + 1` on BOTH
  pipelines — the comparator's anti-vacuity story demonstrated on the
  first day.
* **`scripts/check_speclab_statements.sh`** — the statement-TCB grep
  extension (Iris/iProp/RelSem/native_decide/bv_decide/sorry ban over
  `speclab/SpecLab/`), mirroring check_theorem_axioms.sh's D14 grep
  leg; fail-closed on missing dir; run up front by test_speclab.sh.
  PLANT-TESTED both directions: a planted `-- plant: open Iris` line
  → `FAIL — banned statement vocabulary` exit 1; removed →
  OK exit 0, package rebuilt green after the revert
  (certification-integrity rule 2: rebuild-after-revert).
  Additive only — no shared gate script touched; the in-build Audit
  twin is due with S1's first semantics-facing theorems.
* **Register stubs**: `2026-08-22_arc15-spec-register.md`,
  `2026-08-22_arc15-proof-register.md` (headers only, entries at S1);
  the charter committed to the branch.

## Parked / notes

* Mechanism-B Lean driver flag (`--args` equivalent): registered
  above, priced S, not built (park-don't-improvise).
* Empty byte arrays render as `{ }` — invalid C before C23; v1
  templates keep both arrays nonempty (codec length prefixes guarantee
  nonemptiness for encoded values); documented in
  `renderByteArrayLiteral`'s docstring, emitter refuses empty CSV.
* The in-build statement-TCB/axiom Audit twin for speclab (relsem
  pattern) is deliberately deferred to S1 (first semantics-facing
  theorems) — at S0 the package has no semantics imports and the grep
  floor covers the vocabulary invariant.
* Sandbox note: `/tmp` is write-only under the current nono profile;
  probe scratch ran under the worktree (`.s0-probes/`, deleted before
  commit).
