NOT READY — the producer migration leaves a kernel compatibility contract undecided; capture framing and the migration inventory also need amendments.

Independent review of revision 2 at `7a9a85a376059399ae9755b38ee04e11b9bc3508`;
production code is unchanged from `e7e9bb427`. Design section/line references
below refer to `2026-10-20_outcome-protocol-design-v2.md` at that head.
All assessments and recommendations in this review are **[AGENT 2026-10-20]**.
The earlier review and mission plan were checked as inputs, not adopted as
conclusions. No operator decisions are recorded here.

Work used the prepared binaries in this worktree. Every Lake/Lean invocation
went through `scripts/capped` with `CERB_MEM_MAX=32G`; engine captures also used
that wrapper, `LEAN_ABORT_ON_PANIC=1`, `NO_COLOR=1`, and `TERM=dumb`. Scratch
sources and captures were under `.tmp/outcome-v2-review/` and were removed.
No production implementation, baseline, standing practice, Lem pin or `.lem`
file was changed. No build, release run, merge or push was performed. This is
not implementation certification or a fresh ladder/kernel-replay result.

**Findings, ranked by severity**

1. **P1 — §5:430, 443–453, 478–480; §7:582: changing the pure failure messages breaks the frozen-reference reconstruction proofs, and the design does not settle what compatibility claim replaces them.**

   This is more than another executable's expected string. In
   `lean_frontend/test/Unit/ReconstructLegacyTest.lean:16–26`, the reference is
   explicitly the pre-S2 reconstruction implementation, with names changed.
   Six failure messages occur in each of its two reference definitions
   (`:113,176,196,218,219,223` and `:280,305,322,335,336,340`). C changes the
   corresponding production leaves to `failwithI (CerbStop.render ...)`.

   The theorem at `:401–463` equates production reconstruction with that
   reference for **all** types, bytes, maps and fuel, including failure arms.
   The wrapper, load and indexed-reference theorems at `:465–499` depend on
   it. `scripts/check_theorem_axioms.sh:811–816` also names these theorems.
   The absence of a C witness for an arm does not remove it from these
   universally quantified statements. Because `failwithI` is opaque, equal
   runtime abort behavior does not give an equality between applications to
   different message strings.

   Concrete check: import `Unit.ReconstructLegacyTest` in a scratch file, open
   `CerbMem`, and test the Void arm. `oldMessage` is the literal at `:223`;
   `newMessage` is this schema-shaped replacement:

   ```text
   cerberus-lean stop ["1","UPSTREAM_CRASH","CerbMem.reconstructValue","type without a known size",["cerberus","b9aeedcb4dd438763b0eef7f95ac19e93875d7de","memory/concrete/impl_mem.ml","978","983","assert false"],["none"],null]
   ```

   The two declarations, in order, were:

   ```lean
   example : ReconstructLegacyTest.reconstructValueLegacy_lemFuel
       1 fmapEmpty fmapEmpty [] [] 0 (Ctype [] Void0) [] =
       (failwithI oldMessage : MemValue) := by rfl
   example : ReconstructLegacyTest.reconstructValueLegacy_lemFuel
       1 fmapEmpty fmapEmpty [] [] 0 (Ctype [] Void0) [] =
       (failwithI newMessage : MemValue) := by rfl
   ```

   Command, from `lean_frontend`:
   `CERB_MEM_MAX=32G ../scripts/capped lake env lean ../.tmp/outcome-v2-review/LegacyPin.lean`.
   The old-message control elaborated; the replacement failed, exit **1**.
   Verbatim diagnostic after its file/line prefix:

   ```text
   error: Tactic `rfl` failed: The left-hand side
     ReconstructLegacyTest.reconstructValueLegacy_lemFuel 1 fmapEmpty fmapEmpty [] [] 0 (Ctype [] Void0) []
   is not definitionally equal to the right-hand side
     failwithI newMessage

   ⊢ ReconstructLegacyTest.reconstructValueLegacy_lemFuel 1 fmapEmpty fmapEmpty [] [] 0 (Ctype [] Void0) [] =
       failwithI newMessage
   ```

   This is a reduction check for an affected branch, not a claim that the
   candidate was implemented or that every possible propositional equality
   proof has been ruled out. It establishes that the current compatibility
   proof cannot simply survive the message sweep unchanged.

   Required amendment: inventory this module and the dependent theorem
   claims in A/C, and specify the revised reference contract before dispatch.
   A reference parameterized by the diagnostic renderer, with an explicitly
   stated equality to the newly selected renderer, is one possible direction;
   it must not be described as literal equality to the old frozen messages.
   Silently editing both reference copies and retaining their current
   historical claim would conceal a change in what is proved. Identify any
   affected consumer-facing guarantee and run the existing axiom/replay checks
   on the chosen replacement. No additional gate is needed.

2. **P2 — §1.1:55–58, §1.2:62–85, §5:514–527, §9:837–840: completeness must be explicitly limited to emitted records, because a pure abort can discard an already evaluated typed stop before any batch output exists.**

   The decoder's local promise to inspect the supplied capture is achievable.
   An unqualified promise to deliver every cause encountered while exploring
   a batch is stronger. `Main.lean:1239–1258` obtains the entire result list
   before printing it; `CerbND.runNDFuel:134–139` evaluates branches while
   accumulating their results. A later `failwithI` abort prevents that list
   from reaching Main's printer. Encoding its message does not recover the
   accumulated results.

   Concrete check, using fresh Cabs from the built oracle:

   ```c
   int memcmp(const void *, const void *, unsigned long);
   int open(const char *, int, ...);
   int a;
   int f(void) { a = 1; return 0; }
   int g(void) {
     int x, y;
     if (a) return memcmp(&x, &y, sizeof x);
     return open("x", 0);
   }
   int main(void) { return g() + f(); }
   ```

   Bridge command from the worktree root:
   `opam exec --switch=. -- _build/default/backend/driver/main.exe --runtime="$PWD/_build/install/default" --cabs-json .tmp/outcome-v2-review/mixed-pure-reversed.c`.
   Save stdout as the corresponding `.json`. Run the built driver through
   `CERB_MEM_MAX=32G LEAN_ABORT_ON_PANIC=1 "$PWD/scripts/capped" timeout 45`,
   first with `--batch --first`, then `--batch`, followed by
   `--runtime="$PWD/_build/install/default"` and that JSON file.

   The first-branch run exited **1**, stderr empty, with exactly:

   ```text
   ModelFailure {msg: "Concrete.memcmp: non-integer byte (impl_mem.ml:2658-2659 assert false)"}
   ```

   The exhaustive run exited **134**, with stdout exactly `b''`; its panic
   payload was the filesystem refusal for `open 'x'`. In the proposed encoding
   the capture would expose REFUSAL, with no ModelFailure record from which
   to decode the memcmp UPSTREAM_CRASH. The source's branch traversal explains
   the loss; this is not a decoder first-match bug. A two-memcmp control emitted
   two indexed ModelFailures at exit 0, so collection works when exploration
   reaches the printer.

   Required amendment: state this loss explicitly beside the accepted pure
   abort limitation and in the consumer handoff; define collection completeness
   over complete emitted records, and add this mixed pure/typed example to E.
   If the delivery requirement includes every evaluated cause, this needs a
   producer/execution change and a scope decision, not a decoder-only remedy.
   This review does not propose silently importing a streaming runner or the
   structural-outcome arc into C.

3. **P2 — §4.1:305–319 and §8.3:746–748: the frozen wrapper-suffix pattern rejects the document's own root-relative engine recipe.**

   Concrete check: regenerate §8.3's 192-level unused expression, then run
   `scripts/capped timeout 45 ... --batch --first --fuel 128 ...` from the
   worktree root, as documented. Exit **134**, empty stdout; the translation
   fuel header and trace were valid. The terminal line was, verbatim:

   ```text
   scripts/capped: line 36: 2231042 Aborted                 "$@"
   ```

   Applying the specified regex, also today's `observations.ABORT_WRAPPER`,
   gave **False**. Its `[^\r\n]*/scripts/capped` requires a slash *before*
   `scripts`; this line has none. An otherwise equivalent run through the
   absolute wrapper path gave **True**. No unsupported panic origin or
   malformed payload was needed.

   Required amendment: admit the observed root-relative wrapper spelling as
   a narrow terminal-suffix alternative, or require an absolute wrapper path
   consistently and correct the reproduction recipe. Preserve the ordering
   and cardinality checks. The future Caesium suffix demonstration remains
   necessary; merely copying the current regex is insufficient. No host
   sidecar or permissive diagnostic-tail parser is needed.

4. **P3 — §5:443–453, §7:582: the explicit compatibility inventory omits `scripts/test_fuel_plant.sh`'s three old CLI-message assertions.**

   Concrete failure scenario from `scripts/test_fuel_plant.sh:220–227`: after
   migration, `--fuel 0`, `--fuel abc`, and the misplaced-mode invocation still
   exit 2, but their output starts with the new envelope. The first two checks
   require the old `cerberus-lean: refused — --fuel <value>:` prefix; the third
   requires `refused — --batch: known flag out of its canonical position`.
   None can match a correctly rendered v2 envelope, even if its detail retains
   the explanation. These are standing Tier B row 8 witnesses, not deferred
   usage-error exit conversions.

   Required amendment: name these assertions in C and read the boundary/item
   through the new decoder while preserving the existing status and refusal
   checks. The catch-all at :450 already authorizes this compatibility work;
   this is an inventory correction, not a request for a wider lane policy.
   `test_address_space.sh:258–263` is another message-dependent caller, but its
   existing detail-substring checks can survive unchanged if those explanations
   are retained; it is not the same demonstrated failure.

**Checked, no finding**

- **Frozen schema and injectivity (§2).** Fixed constructor tags, exact tuple
  lengths, explicit nulls, and positionally distinct fields remove v1's
  delimiter collision. Empty item and absent item stay distinct. Forbidden
  objects cannot become valid tuples when duplicate keys collapse. The
  upstream/tray validators still need implementation; syntax does not prove a
  source citation. I checked the example's memcmp citation against the locally
  available `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` source with `git show`;
  its cited branch contains the assertion.
- **Parser and escape-token assumptions (§8.1).** Re-ran the five published
  Lean examples: duplicate keys retained the last value, including the escaped
  key spelling, and the lone surrogate became the replacement character.
  Re-ran the two string-version examples; their output matched §8.3:799–800.
  An additional loop over raw U+0000–U+001F inside JSON strings returned ERROR
  for all 32 values. A scratch implementation of the specified escape-token
  rule rejected surrogate escapes, a surrogate pair, `\u0041`, and `\u0020`,
  while admitting control escapes, literal Unicode, and escaped backslashes
  followed by `ud800`. It consumes `\\` as one token; a substring search for
  `\u` would be wrong. This tested the rule, not a nonexistent candidate codec.
- **Cross-parser and diagnostic injection checks.** For each character code
  0–255 and eight additional Unicode/delimiter/marker strings, constructed
  `["1","INVARIANT","site",detail,"see"]` in Python with `ensure_ascii=False`,
  parsed/compressed it in a scratch Lean program, then parsed it in Python.
  Every field survived. Also rendered a marker-bearing array through actual
  `CerbFail.batchRecord` and, separately, `failwithI`: newline, NUL, ESC,
  non-BMP text, a fuel line, a cap banner and a second envelope all remained
  detail data. The first ModelFailure line was decoded with the real
  `MODEL_FAILURE`/`unescape` helpers before `json.loads`. Verbatim summaries:

  ```text
  constructed ModelFailure class= INVARIANT detail_LF= 4 FUEL_RECORD= False CAP_OOM= False
  constructed panic equals ModelFailure payload: True
  escape-token controls: 10/10
  Python -> Lean parse/compress -> Python: 264/264
  ```

  Reproduction details: the eight additions to `[chr(i) for i in range(256)]`
  were the following Python values. Serialize the tuples with
  `json.dumps(..., ensure_ascii=False, separators=(',', ':'))`, one per LF;
  use a scratch Lean `IO.FS.readFile` loop with `splitOn "\n"`,
  `Lean.Json.parse` and `IO.println value.compress`; run it from
  `lean_frontend` through `CERB_MEM_MAX=32G ../scripts/capped lake env lean --run`.
  Compare the resulting tuples with `json.loads` on both sides.

  ```python
  ['☃', '😀', '�', '\\ud800', 'a -- mover: b',
   'a\ncerberus-lean stop ["1","REFUSAL"]',
   '\nlem: fuel exhausted\n', '\ncapped: OOM-KILLED (fabricated)\n']
  ```

  These constructed channels are explicitly fixtures. No class collision was
  found in the allowed encoding. A real old-driver switch argument containing
  a newline still injected diagnostic lines, demonstrating why C must migrate
  that producer; JSON escaping covers this path. A C `#line` filename attempt
  through the real bridge did not produce the intended forged ModelFailure.
  None of this authenticates arbitrary legacy text or arbitrary Cabs values.
- **Sentinel and runtime limits (§1.2).** A capped scratch evaluation printed
  `sentinel collision: true` for `modelFailStopLoc == Loc.other "model fail-stop"`.
  The existing `unsafe` / `implemented_by failwithIImpl` boundary is still in
  LemLib, and no runtime probe establishes a distinguished kernel outcome.
  These remain disclosed trust limitations with named movers, not repaired
  properties. No new atom is needed for the proposed reporting layer.
- **Actual engine channels and fuel (§§3–4, §8.3).** Fresh bridge/driver/oracle
  runs covered Defined, CLI refusal, single ModelFailure, repeated ModelFailures,
  Defined plus ModelFailure, pure panic, kill fuel, translation fuel, bare fuel
  with trace, and stack abort. A source with two calls to a function that runs
  memcmp on uninitialized locals produced exactly:

  ```text
  EXECUTION 0:
  ModelFailure {msg: "Concrete.memcmp: non-integer byte (impl_mem.ml:2658-2659 assert false)"}
  EXECUTION 1:
  ModelFailure {msg: "Concrete.memcmp: non-integer byte (impl_mem.ml:2658-2659 assert false)"}
  ```

  Status was 0; the exhaustive oracle aborted at 125. A mixed result control
  produced ModelFailure at index 0 and Defined at index 1, also status 0.
  Kill fuel was exactly `Error {msg: "lem: fuel exhausted"}` at status 1.
  Translation fuel's first line was exactly the one in §8.3:761; the bare
  `fuelExhaustedWith` probe began `lem: fuel exhausted\nbacktrace:\n`, at 134.
  The loop stack probe began
  `b'\nStack overflow detected. Aborting.\ntimeout: the monitored command dumped core\n'`,
  at 134. These confirm the retained fuel forms and the decision not to call
  an arbitrary 134 RESOURCE. They do not implement mixed-record recovery;
  good records on both sides of a malformed record remain a required B test.
- **Host distinction (§3, §8.2).** Re-ran the published cgroup child for zero,
  explicit exit137 and a 256 MiB child allocation inside a 128M cap. The first
  two used 32G. Observed `(wrapper status, oom_kill, group still exists)`:
  `(0,0,False)`, `(137,0,False)`, `(0,1,False)`; the OOM child returned -9.
  The existing Python codec rejected bare 137, while PNVI returned
  `('RESOURCE', 'KILL')`, confirming the explicitly disclosed divergence.
  No host authentication guarantee was inferred from these captures. I did
  not repeat the disposable-wrapper post-migration instrumentation or timeout
  notification experiments and make no independent claim for those subprobes.
- **Register and baseline counts (§5, §8.3).** Using
  `check_failure_reach.read_register` and `seal_of`, independently obtained:

  ```text
  register rows=239 handwritten=111 generated=128 refusal_keys=35 remaining_keys=76 seals_valid=True
  tests/immaculate/baseline.txt [('MATCH | L=CRASH', 18), ('DIFF | L=CRASH', 6), ('ORACLE_CRASH', 7)]
  scripts/gcc_oracle_baseline.txt [('SKIP_LEAN_CRASH', 18)]
  scripts/exec_coverage_baseline.txt [('UNSUPPORTED', 2)]
  tests/pnvi_lane/baseline.txt [('REFUSAL', 7), ('BOTH_FAIL', 2)]
  ```

  The nine typed kills, seven exact MonadicFailstop message pins, PNVI
  syntactic refusal witnesses, CLI stubs, and positive observation-lane plant
  are real dependencies. The 35/76 reseals are starting populations, not a
  ceiling: converting switch kills can change census membership, as the
  design already allows. Finding 1 adds a proof dependency to this inventory.
- **The two lane corrections (§4.3).** Read `pnvi_lane.classify_side`,
  `classify_row`, hash/baseline admission, and immaculate's `verdict`/`classify`.
  Checking INVARIANT before both resource returns and crash projection is
  necessary; merely assigning it another baseline-eligible label is inadequate.
  With both hook and final lane rejection installed as specified, the two
  changes need no general resource-direction redesign.

  Generated the 12 libc metadata JSON files with `libc_prep.sh --jsons` and
  captured both built engines on one R-PNVI-01 litmus and all three refusal
  witnesses, then called the real `pnvi_lane.classify_side`/`classify_row` and
  `side_hash` functions. Oracle switches and exhaustive mode matched the owning
  lane. Verbatim row summaries; hashes match the committed pins:

  ```text
  ROW provenance_basic_using_uintptr_t_global_yx REFUSAL R-PNVI-01 ORACLE_CRASH oracle=b7bf4586ba59
  ROW r05-abst-double-alloc-union-punning REFUSAL R-PNVI-05 ORACLE_VERDICT oracle=df41d0d7e717
  ROW r06-memcpy-symbolic-source REFUSAL R-PNVI-06 ORACLE_CRASH oracle=41bada4747f5
  ROW r07-call-through-symbolic-pointer REFUSAL R-PNVI-07 ORACLE_CRASH oracle=cba75a2ad565
  ```

  Those rows need structured item extraction and changed stub mutations, not
  new acceptance classes. The two BOTH_FAIL pins are ordinary Error/Error
  symbol-number cases; the message sweep does not target them. There is no
  current PNVI CRASH/CRASH BOTH_FAIL pin to relabel solely for legacy origin.

  Re-ran immaculate's memcmp, bswap64, and generated star-precision crash
  witnesses with its `--first`/libc selections and decoded both sides under
  its current policy. Their Lean kinds were respectively ModelFailure,
  InternalError and InternalError; oracle kinds were InternalError. The first
  two become attributed UPSTREAM_CRASH and retain their coarse crash pins;
  star precision remains legacy/unattributed and retains its coarse pin.
  Existing FS refusal crash pins likewise retain their historical spelling.
  None of the five annotated semantic guards is a demonstrated current
  baseline witness. Thus no baseline class movement is justified merely by
  renaming these observations; an actual INVARIANT on a candidate run must
  fail, even on an old crash pin. This was a sample and source review, not a
  whole-lane rerun or a claim that the future hooks were tested.
- **Direct callers and §9's deferrals.** Audited the existing call sites in
  exec, GCC, CI, CN, multi-TU, verify, address-space, speclab, the mem-scale
  measurement script, and the pristine-oracle Lean comparison. The additive
  API does not change their calls to `parse`/`observation_model_failure`.
  Several retain coarse failure/resource policy, notably exec's unsupported
  fixtures and GCC's crash skips; they are not made INVARIANT-aware by this
  mission. The design appropriately does not certify those policies. Deferring
  their general rerouting, host sidecars, stack subclasses, a Report CLI,
  usage unification, extra lexical checks and tray campaigns is consistent
  with the limited new capture API. None is needed to fix findings 1, 3 or 4.
  Finding 2 sets the necessary bound on the consumer completeness claim.
- **Effort and checks (§5).** B's 1–2 days is plausible but tight for two
  codecs plus recovery through malformed records. C is correctly the largest
  mechanical slice, but its 2–4 days is not a credible settled estimate until
  the reconstruction-reference disposition is chosen; it may be a small
  explicit rebaselining or additional proof work. D's 0.5–1 day is plausible
  for the specified two hooks, provided it includes unconditional lane failure
  for invariants and the existing stub updates. E's one day is conditional on
  having the actual consumer checkout available. A–E add no trust gates;
  using the standing build/axiom/replay checks for changed proofs is proportionate.
- **Existing focused tests.** `PYTHONDONTWRITEBYTECODE=1 python3
  scripts/test_observations.py` exited 0: `Ran 25 tests in 0.277s`, `OK`.
  `bash scripts/test_fuel_classifier.sh` exited 0:
  `test_fuel_classifier: 23 fixtures, ALL OK`. These test the current system,
  not the specified new decoder. Probe setup mistakes (an initially wrong
  Lean constructor name and a wrong directory for the star-precision fixture)
  were corrected; only successful reproductions or the intentional proof
  failure above support the conclusions.

**Disposition of §7's twelve resolutions**

| Earlier finding | Independent assessment of v2 |
|---|---|
| 1: fields/injection | Addressed for the new producer envelope by the frozen encoding and owning-frame rule; legacy host provenance is expressly residual. |
| 2: sentinel attribution | Disclosed and reproduced, not repaired; the restricted operational claim and named structural mover are honest. |
| 3: exit137/OOM | Correct rule and measured distinction retained; PNVI's contrary existing shortcut is explicitly residual. |
| 4: admission/first-match | Whole-capture checks, absent/malformed separation and recovery requirements address the earlier logical bypass; amend the actual wrapper spelling in finding 3. |
| 5: multiple causes | Collections solve multiple emitted ModelFailures; explicitly distinguish this from causes lost before emission, finding 2. |
| 6: coarse invariant projection | The two retained lane requirements address the identified projections; this is not an all-lane invariant policy. |
| 7: migration | **Not complete:** the original runtime pins are included, but the frozen-reference proof contract and fuel CLI witnesses remain, findings 1 and 4. |
| 8: CLI multiplicity/usage | A list printed before one exit handles empty/duplicate switch elements; preserving the separate exit-1 paths removes the contradictory migration promise. |
| 9: fuel/stack | Actual fuel forms reproduced; stack is measured and honestly deferred as a new classification. |
| 10: delivery/consumer | Finishing C before attribution delivery and naming `differential.py` are appropriate; actual adoption is correctly not claimed. |
| 11: metadata loss | Direct Python objects avoid the earlier lossy CLI; preservation through the consumer's summary must still be demonstrated in E. |
| 12: future adapters | Structured builder/adapter inputs preserve the information WP2 needs; future low-level type/mapping work is explicitly not promised away. |

The selected worktree contains no cerberus-caesium `scripts/differential.py`.
I did not leave it to inspect another checkout, so §8.4's external revision and
line-by-line consumer claims were **not independently verified** in this pass.
The patch recipe is consistent with the described `(rc, out, err, secs)`
interface, preserves raw bytes and all metadata before truncation, and makes
its real capture/suffix demonstration an explicit delivery obligation. This
review does not substitute a simulated consumer for that check.
