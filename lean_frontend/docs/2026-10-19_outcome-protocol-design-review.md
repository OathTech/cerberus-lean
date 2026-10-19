NOT READY — the classification boundary is forgeable, several admission rules contradict their acceptance cases, and the migration omits required test changes.

Independent review at `a93dec536201b63e6392fd3d9ae390be68b93d5e` (code at
`e7e9bb427`, plus the two design-document commits). Section/line references below
refer to `2026-10-17_outcome-protocol-design.md` at that revision. Assessments and
proposed dispositions are **[AGENT 2026-10-19]**; this review records no operator
rulings. No implementation was changed. The recommendations in §6 and the errata
in §8 were checked against source and probes, not treated as established findings.

Probes used the existing binaries and `CERB_MEM_MAX=32G scripts/capped`; Lean
scratch programs used `lake env lean --run` from `lean_frontend`. Scratch was
under `.tmp/outcome-review/` and removed after recording the conclusions and
reproduction recipes here. No rebuild, release run, merge, or push was performed.
This is a design review, not a fresh ladder or kernel-replay certification.

**Findings, ranked by severity**

1. **P1 — §1.3:72–91, §2.1:148–166, §3.2:233–244: the envelope has no encoding rule for input-derived strings, allowing diagnostic data to forge resource evidence and preventing a lossless round trip.**

   Check: run this scratch program through
   `CERB_MEM_MAX=32G LEAN_ABORT_ON_PANIC=1 ../scripts/capped lake env lean --run ../.tmp/outcome-review/FsFuel.lean`
   from `lean_frontend`:

   ```lean
   import CerbFS
   def main : IO Unit := do
     let result := CerbFS.fs_open CerbFS.fs_initial_state "\nlem: fuel exhausted\n" 0 none
     match result.2 with
     | .inl _ => IO.println "error"
     | .inr n => IO.println n
   ```

   Exit **134**, stdout empty. The first two stderr lines were:

   ```text
   PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: CerbFS refusal (fail-closed fs-model boundary): open '
   lem: fuel exhausted
   ```

   Applying the real `observations.FUEL_RECORD` to the capture printed
   `fs-fuel: CAP_OOM=False FUEL_RECORD=True`. This is a filesystem refusal;
   replacing its prefix with the proposed builder leaves the injection intact.
   Rule 3 then chooses RESOURCE before examining the refusal. The path is ordinary
   semantic input to `fs_open`, not output embedded safely inside a Defined record.

   A second check passed the single argv string
   `"--bad\ncapped: OOM-KILLED (fabricated)\n"` to the built driver, under the same
   cap. It exited **2**, stdout empty, and printed the injected banner on its own
   stderr line; `CAP_OOM.search(stderr)` was **True**. Rule 1 would falsely report
   a cap breach even after applying §8's exit-137 correction.

   There are non-adversarial failures too. Applying §3.2's literal head regex gave:

   ```text
   head b'cerberus-lean stop REFUSAL cli/--bad flag: x -- mover: model' => None
   ```

   `--bad flag` is a valid single argv value that the current driver refuses.
   Also, `(detail="a -- mover: b", mover="c")` and
   `(detail="a", mover="b -- mover: c")` have the identical specified rendering:

   ```text
   cerberus-lean stop REFUSAL fs/open: a -- mover: b -- mover: c
   ```

   No parser can recover both inputs. The source-text separator census does not
   constrain runtime strings. Specify an injective encoding for items, details
   and fields, including newline, CR, ESC, Unicode and the field delimiter, on
   every channel. Separately specify the provenance of host evidence: shared
   model diagnostics remain unmigrated and cannot simply be assumed incapable of
   emitting banner-shaped data. Extend the plants to diagnostic interpolation,
   not only escaped program stdout/stderr fields.

2. **P1 — §1.2:60, §3.2:238, §3.4:268–270: the existing ModelFailure channel does not authenticate a fail-stop producer, so the protocol inherits a forgeable attribution boundary.**

   Check: a scratch Lean program imported `CabsImport` and `CerbFail`, constructed
   `loc := CerbLocation.Loc.other "model fail-stop"`, then constructed an ordinary
   `reason : kill_reason Unit := .Error0 loc msg`. It used exactly Main's printer
   branch (`if l == CerbFail.modelFailStopLoc then CerbFail.batchRecord m`).
   The same capped `lake env lean --run` recipe exited **0**, printing:

   ```text
   ordinary location equals sentinel: true
   ModelFailure {msg: "cerberus-lean stop UPSTREAM_CRASH forged: data -- upstream: fake.ml:1"}
   ```

   This needs no `failStopKill` call. `CabsImport.lean:177–181` admits `Loc_other`
   with an arbitrary string; `Main.lean:1278–1281` uses this runtime equality;
   `CerbFail.lean:11` defines the opaque sentinel's runtime value. The probe is a
   boundary counterexample, not a claim that an unmodified C source was run to
   this exact kill. The earlier R1 scoping note §1 already identifies this problem.

   Adding a valid envelope to the ordinary Error0 supplies everything rule 6
   requires. A grammar change cannot make that location a reserved constructor.
   State the input/trust restriction explicitly and obtain a ruling on the
   residual, or bring forward the structural distinction. Do not promise
   producer authenticity for arbitrary in-process/Core/Cabs values until then.

   Existing trusted-runtime finding: pure stops also retain LemLib's
   `implemented_by` attachment to the unsafe `failwithIImpl` implementation.
   An observed runtime abort does not establish a kernel-visible distinguished
   outcome. The note acknowledges the pure-failure limitation; this review does
   not certify that boundary away or infer an axioms/replay result from a probe.

3. **P1 — §3.2:233 and §8:413–418: exit 137 is not evidence of RESOURCE/cap; erratum 1 is confirmed independently.**

   Checks: ran `scripts/capped python3 -c 'raise SystemExit(137)'` and a separately
   started Python process which sent SIGKILL to its own PID, both with
   `CERB_MEM_MAX=32G`. The recorded summaries were:

   ```text
   exit137 exit= 137 seconds= 0.02 stdout= b'' CAP_OOM= False
   sigkill exit= 137 seconds= 0.02 stdout= b'' CAP_OOM= False
   ```

   In each case capped reported `memory.events oom_kill=0`. The real Python codec,
   called as `parse(b'', b'', 137, 'model-failure')`, produced:

   ```text
   ProtocolError: engine killed or exited 137; no completed observation
   ```

   This agrees with `scripts/LADDER.md:144–150`, not rule 1. Require positive,
   trustworthy cap evidence, including descendant OOM at parent exit 0/1; keep
   unexplained termination RED. Finding 1 is an additional problem with the
   provenance of that evidence, which erratum 1 alone does not solve.

4. **P1 — §3.2:236–244 versus §3.5:282–289: the ordered procedure admits captures its own plants require to be RED, while erratum 2 addresses only the Error-payload inconsistency.**

   Check: the real `parse(..., 'model-failure')` accepted a valid Defined at exit
   0 and an ordinary Error at exit 1, each accompanied by a raw stderr envelope
   `cerberus-lean stop REFUSAL cli/x: test -- mover: model`:

   ```text
   stderr-envelope status 0 => ['Defined']
   stderr-envelope status 1 => ['Error']
   ```

   Rule 6 returns those observations before rule 7 can reject them. The existing
   parser deliberately permits ordinary stderr diagnostics; delegating to it
   does not enforce the new channel exclusion. Similarly, calling the real
   `failure_message` on a LemLib PANIC whose envelope detail contains an ANSI
   escape returned that payload, without error. The ANSI rejection lives in
   `parse`, which rule 5 does not call.

   Applying the proposed head regex to `cerberus-lean stop RESOURCE fuel: x` and
   `cerberus-lean stop SHARED_CRASH x: x` returned **None** in both cases. Rule 5's
   no-envelope fallback would call those SHARED_CRASH, contrary to the required
   RED plants. An `imaginary/x` refusal boundary also matched successfully;
   no enumeration validation appears in the stated parser procedure.

   Erratum 2 is independently confirmed: an envelope **inside** an ordinary
   Error message parsed as `['Error']`, and rule 6 already returns VERDICT for it;
   rule 7 nevertheless explicitly lists it as RED. Preserve the data-position
   rule. Specify whole-capture validation before successful return, distinguish
   absent envelopes from malformed/reserved-prefix envelopes, and validate the
   closed boundary vocabulary. These are requirements of this protocol, not
   guarantees supplied automatically by today's codec.

5. **P1 — §1.1:35, §3.1:227–229, §3.2:238: returning one Stop is undefined for a valid batch containing different stop classes.**

   Check: fed the current codec this capture at exit 0:

   ```text
   EXECUTION 0:
   ModelFailure {msg: "cerberus-lean stop UPSTREAM_CRASH first: test -- upstream: impl_mem.ml:1"}
   EXECUTION 1:
   ModelFailure {msg: "cerberus-lean stop INVARIANT second: test -- see: test"}
   ```

   Verbatim probe output:

   ```text
   mixed-stop kinds: ['ModelFailure', 'ModelFailure'] expected_exit= 0
   ```

   Main emits each nondeterministic execution and exits 0 for multiple results
   (`Main.lean:1254–1291`). The mixed Defined/ModelFailure case in the note does
   not settle this two-stop case. Choosing the first record discards a port
   invariant failure; choosing the last makes attribution depend on ordering.
   Fuel precedence can likewise conceal other stops in a batch. Specify whether
   the result contains all stops or a documented aggregate with retained causes;
   never discard a later malformed record or INVARIANT. Add mixed-class and
   mixed-validity plants. This requires a new §6 ruling, not an implementer's
   arbitrary selection of a record.

6. **P1 — §3.3:250–251: mapping INVARIANT and every STOP to the coarse crash class conflicts with the protocol's own defect/resource policy.**

   Check: after applying the proposed PNVI wrapper mapping, the current
   `pnvi_lane.classify_row('exhaustive', ('CRASH', 'unlisted oracle crash'),
   ('CRASH', 'cerberus-lean stop INVARIANT CerbMem.storeM: broken -- see: facts'))`
   returned:

   ```text
   ('BOTH_FAIL', "both CRASH: oracle 'unlisted oracle crash' / lean 'cerberus-lean stop INVARIANT CerbMem.storeM: broken -- see: '")
   ```

   That is an eligible baseline class, although §1.1 says every INVARIANT is a
   finding. The immaculate proposal is broader still: **every** STOP would pair
   with oracle CRASH as MATCH, including RESOURCE/stack or RESOURCE/fuel. Today's
   immaculate decoder rejects fuel and arbitrary abnormal exits before its coarse
   crash projection (`test_immaculate.sh:105–115`). Existing label/hash pins may
   detect a changed row; this is not a claim that those pins automatically go
   green. The proposed classification policy itself admits the wrong category.

   Give each class a lane disposition. Preserve expected refusal/mirrored-crash
   pins where intended, keep resource exhaustion incomplete, and surface
   INVARIANT as a defect regardless of what the oracle did. Do not use unchanged
   status counts as a reason to preserve a classification the new information
   disproves. No new standalone gate is needed.

7. **P1 — §3.3:254, §4.1:304–307, §4.2:318–324: the listed slices cannot pass their existing tests with only the budgeted edits.**

   Concrete failure scenarios established by source inspection:

   - S1 changes all seven existing mirrored typed-kill messages.
     `test/Unit/MonadicFailstop.lean:9–11` checks `text == msg`; lines 37, 60–80
     pin those seven old messages, and line 84 reuses the memcmp text in the
     continuation check. For example its `Concrete.memcmp: non-integer byte
     (impl_mem.ml:2658-2659 assert false)` cannot equal the new envelope.
     This executable is explicitly run at fuels 2 and 17 in row 1
     (`scripts/test_unit.sh:102`). It must be migrated in S1, not just the new
     round-trip executable and the producers.
   - S4 adopts the strict classifier but §3.3 says `test_observation_lanes.py`
     stays unchanged. Its line 61 emits the envelope-less positive control
     `ModelFailure {msg: "Concrete.memcmp: non-integer byte"}`; lines 132 and 177
     require `crash-model` to remain accepted by immaculate. New rule 6 expressly
     rejects that capture. The positive control needs an envelope, while a
     separate envelope-less negative control should remain.

   Amend the slice contents, prices and charter file fence. The S1–S2 charter's
   requirement to stop on an out-of-fence change makes the omitted unit-test file
   a dispatch problem, not something the worker can silently absorb. The message
   migration itself need not alter semantic baselines.

8. **P2 — §1.2:58, §2.1:160–162, §2.2:186 and §3.2:236: the CLI protocol promises one line, retains a multi-line producer, and provides an adapter that exits before that producer can finish.**

   Check: the built driver with `--switches=bad,other` exited **2**, with empty
   stdout and **two** refusal lines, one naming each element. `Main.lean:1457–1468`
   implements this as a loop of prints followed by one exit. Calling the proposed
   `refuseIO` inside that loop exits after the first element. Keeping the loop
   instead violates the one-envelope channel table; reading only the first line
   loses the second item's attribution and permits unchecked trailing material.

   Choose a single envelope containing the collection, or specify a validated
   collection of CLI stops and separate rendering from the terminating adapter.
   Test mixed/duplicate/empty switch lists and both argv spellings. Also correct
   §0:20 and §1.2:54: migrating the five usage errors from exit 1 to exit 2 is an
   explicit protocol change. The live `--switches`-without-argument check exited
   **1**, not 2.

9. **P2 — §1.2:61–63, §3.2:235–237, §4.1:304 and §6 Q9: the resource-channel table is stale and the specified stack framing rejects the actual runtime capture.**

   Check: generated Cabs JSON with the built oracle for
   `int main(void) { while (1) {} }`, then ran the built driver with `--batch`,
   its explicit `_build/install/default` runtime prefix and default fuel, under
   `CERB_MEM_MAX=32G scripts/capped timeout 45`. It exited **134** after 25.24 s,
   stdout empty. The beginning of stderr, shown as bytes to preserve the leading
   blank line, was:

   ```text
   b'\nStack overflow detected. Aborting.\ntimeout: the monitored command dumped core\n'
   ```

   It then contained capped's normal `Aborted` wrapper line. Rule 5 requires the
   **first line** to be the stack text; that line is empty. Pin the complete known
   framing, including the leading newline and allowed wrappers, rather than a
   substring. The earlier 25-second, `--first` run timed out at **124** with stack
   text in its capture; it is not a successful stack-class control.

   Translation-fuel check: used an uncalled function with the expression
   `'1 + (' * 192 + '0' + ')' * 192`, beside a returning main, via the same bridge;
   ran `--batch --first --fuel 128`. It exited **134**, stdout empty, first line:

   ```text
   PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted
   ```

   The real shell classifier returned `FUEL:panic` and Python `FUEL_RECORD`
   matched. The simple main control at fuel 128 exited 0 with Defined Specified(0).
   Thus the new implementation is already classifiable by rule 3, but §1.2 must
   include this form, and its acceptance cases must retain it. Finally, the charter
   §0 defers stack support to a stack-ceiling slice, while this note puts it in
   S1. Settle that delivery boundary before dispatch; measurement/classification
   does not require solving the recursion problem.

10. **P2 — §3.4:260–272, §4.1:309–314 and §8:423–425: S1 does not deliver the advertised consumer mapping; erratum 3 is confirmed, and the transitional table needs to include refusals accurately.**

    Check: current `CerbFloat.lean:356` emits the old formatFixed refusal text;
    `:438` emits the old truncToInt mirror text. Neither is an envelope. By the
    specified classifier both are SHARED_CRASH at S1; only formatFixed moves in
    S2, while truncToInt waits for S3. The same staging applies to CerbFS/PNVI
    refusals and the other hand-written pure mirrors. Old CLI refusals are RED
    under the new strict classifier until S2. The charter correctly moves the
    pure-mirror promise to S3, but its refusal row describes the old observable
    prefix, not what the **new classifier** returns at S1.

    Publish a family/channel table of the classifier's actual result at every
    consumer-facing landing. Distinguish observable text, temporary
    misattribution and an accurate class. “Semantics failure” must not suggest a
    diagnosed semantic defect merely because an envelope is absent.

    Consumer check: read cerberus-sl at `68832d914227a29c37df381d3e83ad274147e24c`
    and cerberus-caesium at `32d88b8b3fd30aba8cd5b26bc009b3a0e5115f45`, without
    modifying either. Caesium's actual binary-driver consumer is
    `scripts/differential.py:524–561,721–752`: it maps ModelFailure into an Error
    with a textual prefix, and its fuel recognizer misses the translation PANIC
    form. `check-caesium-exec.sh` instead launches the Caesium stepper's harness;
    it is not the W3 batch decoder. Name the former as the integration target and
    demonstrate its use of the new classifier; providing a function alone does
    not change the consumer's classification.

11. **P2 — §3.1:222–224 versus §3.4:262–267: the documented classifier CLI drops the upstream cite and mover that the consumer is promised.**

    Concrete scenario: classify the note's memcmp example. Its CLI format yields
    `STOP UPSTREAM_CRASH model-failure CerbMem.memcmp: non-integer byte`.
    `upstream: impl_mem.ml:2658-2659`, `tray: none`, and `text: assert false` are
    in `Stop.fields`, which the specified output never prints. The analogous
    refusal drops its mover; `_malformed` is invisible to a CLI-only caller too.
    The text at line 262 promises the cite in that very line.

    Specify a lossless CLI rendering of the parsed envelope/fields and expose
    malformed metadata, or define a machine-readable action for consumers.
    Preserve the Python and Lean APIs' information consistently. The one-line
    guarantee must use the escaping rule from finding 1, including for legacy
    multi-line SHARED_CRASH payloads.

12. **P2 — §5:339–352: the promised signature-preserving WP2 conversion lacks the data required by the proposed structural constructors.**

    Concrete type check by inspection: the call at §2.1:159 is
    `refuseM (CerbStop.refusal b item detail mover ...)`; the builder returns only
    String. The resulting `refuseM : String → memM a` has no `b` to put in the
    proposed `Unsupported b s`. Likewise `failStopMem : String → memM a` has no
    `stop_origin` for the suggested `FailStop of stop_origin * string`. Either
    adapter must parse and validate text, with a specified failure outcome, or
    the builder/adapter interface must carry structured data and change type.

    This is not prohibited work, but it is not merely changing the two bodies
    as claimed. R1 also places `unsupported_feature` in a low-level Lem module;
    the thirteen-case Lean Boundary needs an explicit mapping/alias plan. The
    suggested eventual `FailStop (Upstream <lem cite>)` for SHARED_CRASH further
    needs a rule preserving that class if unchanged class identity is promised.
    Amend the future-work claim or choose structured builders now, while leaving
    current message rendering and leaf mechanisms separate.

**Assessment of every §6 recommendation**

These are reviewer recommendations, **[AGENT 2026-10-19]**, not settled choices.

| Question | Assessment |
|---|---|
| Q1 names | Useful provenance vocabulary, but “semantics failure” is not established by a missing envelope. Require the malformed-envelope distinction and explicit transitional attribution (findings 4, 10); do not imply an oracle-correspondence proof. |
| Q2 allocator OOM | Agree: retain the semantic kill and consumer alias. This is different from a host cgroup kill. |
| Q3 usage errors | Agree with attributed exit-2 admission refusals, but disclose the exit-code change and cover all five sites. |
| Q4 switch kills | The existing memM-level panic mechanism can be reused. Describe the runtime abort requirement for library callers as well as the CLI; config-deadness is a statement about Main's accepted configurations, not arbitrary Switches instances. |
| Q5 thirteen boundaries | No objection to the current wire vocabulary. Separate admission categories from semantic Unsupported categories, or explicitly rule their shared enumeration and later low-level mapping (finding 12). |
| Q6 Q-A sweep | Consistent attribution is a reason to migrate all listed mirrors, including unreachable ones. Keeping the print-then-kill/defined arms is consistent with the stated mirror policy. Their separate inventory rulings remain necessary. |
| Q7 unsupported filenames | Agree: a filename must not turn an unrelated crash into a refusal. The two existing coverage rows really are formatFixed refusals. |
| Q8 register speedbump | A cheap lexical report is reasonable; it is not proof that every runtime panic has a trusted origin. Keep it nonblocking as proposed, and do not describe the exec-closure register as a census of every possible host/front-end failure. |
| Q9 stack | Agree with reporting a measured, well-framed stack failure as RESOURCE; use the observed complete capture and settle S1 versus later delivery (finding 9). |
| Q10 trays | Citing known reports and drafting missing ones is sound. Distinguish new drafts from updates to an existing draft such as bswap64's 12; filing remains separate. |
| Q11 invariant exit | Exit 2 is sufficient if the whole capture and class are validated. A new numeric code would not fix the attribution defects. |

The list is incomplete: the operator must also settle mixed-stop aggregation,
the inherited ModelFailure trust restriction, and which lane dispositions are
permitted for INVARIANT/RESOURCE. Encoding and complete admission validation are
implementation requirements needed to satisfy the stated protocol, not optional
relaxations to be selected by the worker.

**Checked, no finding**

- **Register mechanics and §8's final clarification:** using the actual
  `check_failure_reach.read_register` and `seal_of` yielded
  `register rows: 239 seals valid: True`, `handwritten rows: 111`,
  `generated rows: 128`, `current refusal keys: 35`. Changing a message changes
  its key and seal (`SEALED` includes `msg`); the remaining hand-written rows
  number 76. Key-group extension is already implemented. This supports the two
  planned re-seal populations, not a guarantee that an arbitrary source rewrite
  preserves each token-level position class. That must be checked after edits.
- **Baseline counts remeasured at the review base:** excluding comments,
  immaculate has 18 MATCH and 6 DIFF rows with `L=CRASH`, plus 7 ORACLE_CRASH rows;
  gcc has 21 SKIP_LEAN_CRASH mentions. Coverage has precisely
  `fmt-007-f-nan-sign.unsupported.c UNSUPPORTED` and
  `fmt-007b-f-nan-negated.unsupported.c UNSUPPORTED`. PNVI has 7 REFUSAL and 2
  BOTH_FAIL rows; the latter are `minimal/073-exit.libc` and
  `minimal/074-abort.libc`. `minimal/097-null-ptr-arith.undef` is AGREE.
  These support label-only baseline expectations for the enumerated migrated
  producers, subject to the policy and test corrections above.
- **Consumer constants:** cerberus-sl's `Interface.oomOutcome:177–178` retains
  the allocator's Other/DErr_memory/MerrOther kill. `PrimOutcome.liftKill:355–358`
  has Undef0/Error0/Other arms and passes Error0's location and string unchanged.
  S1–S4 need not change those types or the `fuelExhaustedKill` alias. WP1/WP2 will
  require consumer work; no theorem-rebuild claim is made here.
- **Leaf and proof mechanism:** the lexical census recognizes failwithI,
  panic!, panic and panicCore; preserving the failwithI head is compatible with
  it. `CerbFailProofs` propagation contracts quantify over the message, so changing
  message text does not itself require new propagation proofs. This is a source
  compatibility check; the existing runtime trust findings are recorded in
  finding 2.
- **Cabs position update:** source inspection of `CabsImport.jsonToPos` and its
  unit test confirms the five-field source/lexing shape. Fresh Cabs JSON from
  this worktree's oracle passed the actual driver control. The position change
  did not require different stop-class reasoning or alter the register counts.
- **Ordinary data and existing tests:** `PYTHONDONTWRITEBYTECODE=1 python3
  scripts/test_observations.py` exited 0 with `Ran 25 tests in 0.253s` and `OK`.
  `bash scripts/test_fuel_classifier.sh` exited 0 with
  `test_fuel_classifier: 23 fixtures, ALL OK`. Escaped Defined fields and ordinary
  Error payloads retain their existing data treatment. Passing those tests does
  not cover the newly demonstrated diagnostic interpolation cases.
- **Existing commitments outside the message protocol:** leaving allocator OOM,
  ordinary Error, asm rejection, and the pure-versus-monadic mechanisms alone
  is consistent with the cited contract and queued structural work. No new
  opaque atom or value-producing fallback is needed for a message builder.

Record-hygiene observation: the older R1 scoping note's opening/provenance text
(`2026-09-16_lean-only-outcomes-scoping-note.md:9–15`) contains passages presented
as direct operator quotations. They were not copied here or edited; any cleanup
of that existing record is for the operator to direct.
