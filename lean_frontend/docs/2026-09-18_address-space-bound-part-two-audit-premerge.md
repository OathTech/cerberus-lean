# Pre-merge audit: address-space bound, part two

**Verdict: REQUEST CHANGES.** The production parameter threading looks correct, and the reported fast results reproduce. I found three medium-priority issues in delivery/validation and one documentation error. These do not establish a wrong runtime result from the new bound parameter. They do mean that “part two is complete” and the claimed regression protection are stronger than the delivered artifacts support.

**Auditor:** Codex, independent of the implementation. **Date:** 2026-09-18. **Head:** `88c5a827b1fc7195d85e923c9569e56fbefb4065`, branch `arc/address-space-bound-part-two`. **Base:** landed part one, `e64819de7`. The range has six commits including the charter `ea517c1f9`; the five subsequent worker commits are C0, the interim record, C2, C3, and the final record. The main checkout (`mdd/cerberus-lean`) remains at the base. Review artifacts are written in the part-two worktree; no implementation, baseline, pin, or branch history was changed.

Evidence is in [2026-09-18_address-space-bound-part-two-audit-evidence/](2026-09-18_address-space-bound-part-two-audit-evidence/). “Reproduced” below means my own run at the audited head. Arithmetic reconstructions and checks of the implementer's retained reports are identified separately.

## Findings

### F1 — P2: the chartered bound-quantified execution theorem is missing; the record also misstates `run`'s signature

**Locations:** `lean_frontend/test/Unit/FuelExemplar.lean:126–150`, `:428`, `:482`; charter C2(e); final record E12 (`:91–98`), C2 implementation summary, and open item 2 (`:385–387`).

The charter explicitly requires the FuelExemplar theorem to quantify the bound. The delivered `dst₀ sup top` accepts it, but:

```lean
def run (n : Nat) :=
  ... (@dst₀ ⟨n⟩ 0 exemplarTop)
```

`S₁` and `exemplar_certified_shipped_forall (fuel : Nat)` likewise remain at the fixed `exemplarTop = 0x10000`. This is a valid theorem at 64 KiB, not the required theorem over address-space bounds. A green build and the existing axiom-cone check cannot detect this missing quantifier.

The omission is candidly disclosed as OWED in the source, VALIDATION, and record. That disclosure is useful, but it does not satisfy C2(e), and the provided ruling chain contains no acceptance of that deferral. Moreover, the record says both `dst₀` **and `run`** already take `top` (E12, the C2 summary, and open item 2); `run` does not. Merely adding a theorem binder without changing `run` would still prove only the fixed-bound proposition.

**Required correction:** parameterize `run`, the setup state and supporting lemmas; prove the promised execution statement with the appropriate bound hypothesis, such as `8 ≤ top`, or explicitly handle insufficient space in its postcondition. Correct the signature claims and completion status. If the proof is intentionally deferred, explicitly amend the deliverable rather than presenting the original charter as complete.

**Scope:** the actual memory/driver/desugar entry definitions are parametrized correctly. The audit's small universal projection lemmas check that they retain the supplied cursor. Those lemmas are not substitutes for the missing execution theorem.

### F2 — P2: the purported pre-fix negative control is not a pre-fix outcome of its selected case

**Locations:** `scripts/test_address_space.sh:178–192`; `tests/address_space/three-ints-then-array.c:7–16`; `tests/address_space/expectations.txt`; LADDER A12 and VALIDATION §5's description of the selftest.

P1 changes `three-ints-then-array@32` from out-of-memory to `Specified(6)` and calls that a pre-fix ACTIVE verdict. For this program, errno and the three `int` objects leave cursor 16. The next request is a 16-byte character array, aligned to 1:

```text
z = 16 - 16 = 0
q = 0, remainder = 0
old aligned address = 0
old allocator result = out of memory
```

The old allocator also kills here. `Specified(6)` is the program's successful result at a larger bound; it is not evidence of the old allocator's behavior at 32. The draft-44 arithmetic producing address 6 requires, for example, `z = -1`, alignment 8.

More broadly, reconstructing the allocation schedules of all five programs at 64/32/8 gives identical old/fixed allocator decisions in **all 15 cases**. The four-byte/eight-byte requests and aligned bounds, and the character arrays' alignment 1, avoid the defective negative-remainder window. This reconstruction uses the pristine allocator source and Euclidean division; it is not represented as a second old-engine execution. The reproduction script and every schedule are retained in `allocator_arithmetic.py` / `allocator-arithmetic.txt`.

Consequently, P1 proves that changing an expectation string is rejected. It does not demonstrate rejection of a genuine pre-fix observation for this corpus. The 15 cases remain useful tests of exhaustion and parameter threading, but they do not test the particular allocator defect invoked by the selftest's description.

**Required correction:** include an actual tiny-bound discriminator and pin its real old/fixed outcomes, then plant that case's verified pre-fix outcome. One candidate is the existing `malloc-one` shape with `malloc(9)` at top 32: the derived allocation sequence leaves cursor 8 before the 9-byte/alignment-8 request; old arithmetic returns address 6, while remedy 1 kills. Validate the complete program outcome before using it as an expectation. No second oracle build is required to establish the relevant arithmetic witness.

**Scope:** C0's default-bound witnesses and part one's allocator theorem/unit test independently protect the original fix. This finding is about the new tiny-bound lane and its claimed negative control, not the absence of regression protection throughout the project.

### F3 — P2: an unterminated final expectations row is silently ignored

**Location:** `scripts/test_address_space.sh:130–135`.

The expectations reader uses `while ... read ...; do` without processing a nonempty final read when EOF arrives before a newline. Starting with the committed 15-row expectations file:

| Mutation | Actual result |
|---|---|
| Append phantom row with newline | Rejects |
| Append the same phantom row without newline | **Accepts** |
| Append duplicate row without newline | **Accepts** |
| Append malformed row without newline | **Accepts** |
| Remove the final newline from the otherwise valid file | Rejects as a missing observed case |

These were reproduced using the script's exact `check_expectations` function, with an unchanged observation table. The phantom-row acceptance was also checked through the real lane's `--expectations` entry point. The checker prints `15 pinned rows = 15 observed cases` while ignoring the extra data. This violates the promised rejection of extra/malformed rows and makes the result depend on the editor's final-newline behavior.

**Required correction:** either process the final unterminated record (`read ... || ...`) or explicitly reject nonempty unterminated input before parsing. Add EOF variants of the phantom, duplicate, malformed, and valid-row controls to the selftest. Handle the observation-table loop consistently if that function is intended to accept arbitrary observation files too.

### F4 — P3: the new allocator-contract explanation incorrectly states an equivalence

**Locations:** `lean_frontend/VALIDATION.md:900–902`; final record's consumer note `:215–218`.

The new prose says the allocator kills “exactly where” the cursor is below the request and attributes that fact to `allocator_active_sound`. That is false. Below-request is sufficient for the early kill, but the second check also kills when rounding produces a nonpositive address. Cursor 4, request 4, alignment 4 kills with equal cursor/request; cursor 5, request 4, alignment 4 also kills despite the cursor being larger. The new corpus already contains the equality example (`three-ints-then-array@32`).

`allocator_active_sound` is a necessary condition on an ACTIVE result, not an if-and-only-if characterization of failure. `allocator_below_request_kills` is the theorem for the early-kill direction.

**Required correction:** state the two checks accurately: `cursor - size < 0`, or the aligned-down candidate address is nonpositive. Attribute each theorem only the direction it proves. The required `8 ≤ top` hypothesis for the four-byte errno allocation is consistent with these checks.

## Other corrections and limits

- **Register arithmetic:** the new `immaculate/nolibc/tray44-allocator-exhausted-single-request` rationale says the request exceeds the cursor “by 7 bytes.” With request `a - 7` and cursor `a - 8`, it exceeds it by **1** byte. The equation `z = -1`, program, and observed signatures are correct. This wording was copied from the older minimal-row rationale; correct both descriptions together.
- **Mini-run coverage:** the source and generated-code review confirms that the supplied value reaches `evalConstantExpressionAux` through desugar state and `initial_driver_state_given`. The audit projection lemmas also check the state constructors for arbitrary `top`. The 15 C cases do not establish that an allocation-sensitive constant-expression mini-run responds to a changed top; ordinary arithmetic constant expressions can produce identical results under every top. A future behavioral regression test for that entry would strengthen the evidence. I did not find a threading error there.
- **CLI grammar:** Lean deliberately accepts positive decimal naturals; the fork converter additionally accepts prefixed bases. Thus `0x40` is accepted by the fork and refused by Lean. The charter asks for Lean's existing fuel-parser shape and the record discloses the differing converter behavior; I do not count this as a defect. Shared invocation scripts should use decimal values.
- **Unbuilt backends:** concrete is covered by the normal build, and `dune build @memory/vip/all` also succeeded in this audit. The web/BMC/OCaml-runtime edits were inspected. The record correctly discloses that these backends are not ladder-built and that the commented-out OCaml-runtime Dune stanza would need a `cerb_backend` dependency. I do not certify those optional backends as compiling. Symbolic/CHERI accept and ignore the parameter as chartered.
- `git diff --check` reports trailing spaces and an extra final blank line in retained verbatim evidence files only. I did not alter historical transcripts to make that cosmetic check green.

## What was verified

| Check | Fresh audit result |
|---|---|
| `release.py --mode fast` | **16/16 passed**; source unchanged; complete tier selection |
| A12 normal and selftest (within fast) | **15/15 agree**, all four existing plants rejected |
| `release.py --mode full --lane B5 --lane B10` | **3/3 selected commands passed**; source unchanged; **partial selection**, not a full certification |
| Immaculate lane (B5) | Baseline unchanged, including both new witness Error rows |
| Pristine oracle (B10.1) | **822 semantic agreement, 28 matching failure, 7 reviewed difference, 2 interface agreement** |
| Pristine-oracle plants (B10.2) | `plants_passed`; 1 semantic agreement, 1 plant rejected, 51 plant OK |
| Extra differential sweep | **40/40** equal full codec tokens; 20 bounds from 1 through `2^64 + 9`, two programs |
| CLI matrix | Both reject zero/garbage/negative; decimal 64 accepted; prefixed-base asymmetry confirmed |
| Universal entry projection lemmas | Compile; each axiom cone is `[propext, Classical.choice, Quot.sound]` |
| Expectations EOF plants | **Bug reproduced**, including acceptance through the real lane |
| VIP library build | Exit 0 |

The additional C sweep includes `malloc(9)`, confirming the proposed discriminator's
fixed-engine out-of-memory result at top 32 and successful result with ample space.
Its pre-fix address is an arithmetic reconstruction, not an old-engine C observation.


The implementation review traced the whole parameter path: `main.ml` supplies the same converter value to both configurations; `pipeline.ml` carries it into desugar state, the getter and mini-pipeline; both OCaml driver modes pass it to the execution entry. Lean carries the same parsed value through ordinary translation units, libc translation units, and execution. The concrete/VIP constructors use the parameter, and `MemState.lastAddress` has no structure default. The executable defaults remain equal. `drive` and the allocator bodies are unchanged in this range.

C0 adds exactly two immaculate baseline rows without moving existing rows, two register entries, and four GCC ledger rows. The witness bodies match the minimal twins. The fresh immaculate run checks both engines' complete Error payloads, and the pristine gate checks the registered signatures.

The six new A1–A3 numeral plants pass their intended rejection checks through the fresh unit suite. This remains the documented syntactic tripwire, not a proof against all arithmetic/indirection spellings. The synchronization, freshness, drift, purity, totality, and axiom checks bundled in the fresh fast run passed.

**Historical full-run evidence:** I inspected `.tmp/c3-release-full/report.json`: head `9a8caddc1`, 39/39 passed, complete selection, unchanged source, no artifact issues. All 78 retained stdout/stderr hashes match the report. The difference from that C3 head to the audited head is confined to the record and two evidence files. This supports the provenance of the implementer's full-run claim; it is not a fresh audit run of all 39 commands. In particular, I did not rerun the approximately 77-minute full battery, the full GCC lane, or the full three-engine report.

## Merge conditions

Fix F2 and F3 and rerun A12's normal/selftest commands; correct F4 and the record's signature/arithmetic statements. Complete F1 or explicitly revise its scope and completion claim. Then rerun the relevant unit/proof checks and the fast gate at the final unchanged tree. The existing green checks are compatible with all four findings, so simply repeating them without these corrections does not close the review.
