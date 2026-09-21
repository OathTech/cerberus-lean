# VALIDATION — why you should trust this semantics

An executable semantics is trusted for what it has been *checked*
against, and this document is the honest inventory: the rule the port is
held to, the exceptions and how each is tested, the register of
deliberate deviations, every known difference and its class, then what
is compared against what, how often, and what the gates guarantee. There
is no delivered proof that the Lean port equals the compiled OCaml
implementation. That compiler/runtime correspondence remains an external
reference boundary, so the validation story is (a) **structural**: both
implementations are generated from one Lem model, and the hand-written residue mirrors its
OCaml counterpart line-by-line; and (b) **empirical**: an industrialized
differential-testing surface with pinned, fail-closed baselines. A green
build is never the signal; the differential baselines are.

The current [supported profile](docs/2026-09-06_supported-profile.md)
separates shared-source, logical-definition, native-execution and consumer
claims. Validation-foundations adds an independently compiled pristine
oracle, a shared byte observation contract, an executable LADDER runner,
and a cold provider client. The
[audit repair record](docs/2026-09-06_validation-foundations-audit-repairs.md)
identifies the corrected 32/32 Tier A+B pass, C1/C4 reporting, cold build/proof
and failure measurements. The original delivery and first audit remain dated
history. The [fresh document review](docs/2026-09-06_validation-foundations-document-review.md)
corrects a material fuel-correspondence overclaim and three minor issues;
landing acceptance, C2/C3 and customer adoption remain outstanding.
Missing historical logs are
explicitly inventoried; they are not evidence of a current pass. See
[the observation contract](docs/2026-09-05_observation-contract.md)
for sequence/set projections and the printer's observational limits.

## 0. The aims and the rule

The four aims, in priority order — [USER 2026-09-03], verbatim:

> "(1) match cerberus-ocaml exactly in cases where we do not have STRONG
> evidence it is incorrect wrt ISO-C, (2) if cerberus-ocaml appears
> clearly incorrect, do the correct thing and log it cleanly for an
> upstream fix, (3) design so that consumers, eg. refined-cerberus get
> the most useful version of the semantics, (4) within the remaining
> design latitude, try to fail-closed i.e default to safe behavior wrt
> correctness for executable semantics and downstream customers"

**The rule** — [USER 2026-09-03], verbatim (charter
`docs/2026-09-03_zero-discrepancy-design.md` §1.1):

> "All *execution* discrepancies are definitionally bugs (other
> machinery intended to support proof is allowed but should have no
> semantic / execution effect whatsoever and all legacy permission
> revoked"

For cerberus-lean: **Lean ≠ oracle (matched mode) on a program both run
= bug.** The oracle's own deviations from ISO C are MIRRORED faithfully
and filed upstream (`docs/upstream-tray/`) — the rule is Lean ≠ oracle,
not Lean ≠ ISO. Every previously "declared", "documented-deliberate",
"unobservable" or "temporal-boundary" divergence was re-classified on
2026-09-03 into the classes of §1; the label is not a class, and this
document no longer uses those words for anything but history.

**The referent is the logical semantics** — [USER 2026-09-03], verbatim
(`docs/2026-09-03_logical-semantics-referent-ruling.md`): "ocaml limits
that are hardcoded thanks to ocaml-level execution issues are also
forbidden, the real thing is the logical semantics". What the port
mirrors is the lem model, the Core stdlib and ISO C where the model is
silent — not the OCaml runtime's execution accidents (`Z.Overflow` from
a host-int conversion, `Division_by_zero` from a missing guard,
`Stack_overflow`, 63-bit `int` wrap). A one-sided oracle failure is
therefore of one of two KINDS: (1) a `failwith`/`assert` the model writes
deliberately — a design choice, mirrored as a fail-stop carrying the
OCaml text; (2) an OCaml-execution artifact — NOT mirrored: Lean
implements the logical meaning at that point, the case is logged (tray)
and pinned (immaculate Lean-right/oracle-wrong pair), and it is admitted
to the register (§2) BY CLASS.

**UB location is behaviour** — [USER 2026-09-03] "(1) agree": the `loc`
field of an `Undefined` line (and the `stderr` bytes) are part of the
verdict the semantics reports; every lane compares whole `Undefined
{…}` lines since Z1 (`docs/2026-09-03_zero-discrepancy-Z1-record.md` §4).
**Successful output bytes are behaviour too**: since the P0 instrument
repair (2026-09-05, whole-project audit F3;
`docs/2026-09-05_p0-instruments-record.md` §F3) `test_exec.sh` — the
main lane and everything built on it — compares the WHOLE `Defined {…}`
line (value, the program's captured stdout and stderr, blocked) as one
token; before it only the `value: "…"` field was compared, so two
`Defined` lines with the same value and different stdout/stderr read
MATCH. Validation foundations migrated the six required lanes and inventoried
older callers to the shared byte codec and actual-status capture. The
[observation contract](docs/2026-09-05_observation-contract.md) defines the
fields and each lane's sequence/set projection. GCC native exit comparison
and the independent litmus reference remain explicitly weaker projections;
the initial candidate had 67 actual-entry plants, and the repaired candidate
passed all 90 in its identified full run (see the audit repair record).

Terminology. **oracle** = the OCaml Cerberus built from this
repository's `.lem` + OCaml sources, run in the MATCHED MODE (same
`--nolibc`/libc linkage, `--mode=exhaustive` or `--first` ≙ single trace,
default switches, no `--concurrency`, the default address-space top — neither
engine passes `--address-space-top`, §7). **upstream** / **pristine** =
un-forked Cerberus @ `b9aeedcb4` — as source, `deps/cerberus-upstream`; as an
ENGINE, the independently compiled build (pristine source + upstream Lem
`3802cb0`, git archives, `DUNE_CACHE=disabled`, hash-pinned manifest) that
`scripts/ensure_independent_oracle.py` keeps standing at
`.validation-foundations/independent-oracle-v2`. **execution discrepancy** = on a
program both engines run, a difference in the outcome class
(`Defined`/`Undefined`/`Error`/tool failure), the value, the UB code, the
UB location, stdout/stderr bytes, or the trace set. **mirror** = make the
Lean text compute what the OCaml text computes, with a `file:line` cite.

**The reference doctrine** (WP-O, 2026-09-16 — [USER 2026-09-16]: *"right
now we have the ocaml-cerberus as an oracle, but we're also changing it.
There's some danger there!"*; record
`docs/2026-09-16_pristine-oracle-instrument-record.md`). Pristine upstream
`b9aeedcb4` is THE reference. The fork's OCaml is the shared model's
**mirror twin**: it is built from the same `.lem` the Lean port is generated
from, so a shared-model edit moves the fork oracle and Lean TOGETHER and every
fork-vs-Lean lane is blind to it by construction. The fork's deviations from
pristine are therefore a separately gated inventory: the register
`scripts/upstream_oracle_differences.json` (schema 2 — every row classed
`diagnostic-text` | `resource` | `missing-feature` | `shared-model-fix`,
cited to an upstream-tray draft, an ISO-fix register id or a dated record,
with a rationale and both engines' full signatures) is the ONLY permitted
list of fork≠pristine behaviours OBSERVED on the walked corpora; the fork's
source-level deltas from upstream are the reviewed
`scripts/fork_drift_manifest.txt` (§6, `check_fork_drift.sh`), of which the
register is the behavioural projection — a delta with no register row is
either unobservable on the corpora or a missing case, and the S1 charter's
three-way report is how a slice shows which. LADDER Tier B row 10
(`scripts/test_upstream_oracle.py`) is the register's gate: pristine vs fork
over every corpus the fork-vs-Lean lanes GATE on (the Tier A/B baselines)
plus the `tests/ci` and csmith reporting corpora — `test_ci_sweep.sh`'s
fourteen other suites (Tier C row C4, a scoreboard with no baseline) are not
walked and are named as such in the lane's report — every unexplained
difference RED, a pristine-side non-termination admitted only through a
cited `resource`/`shared-model-fix` row (never the fork side), stale rows
RED, and a REGISTERED case always judged by its row: a registered case whose
fork side times out, or a both-sides timeout on a registered case, is RED —
the pin moved.
Today the inventory is exactly 5 `shared-model-fix` rows (the three cross-TU
struct-value cases of upstream-tray drafts 37/38/39, where the fork answers
`Specified(7)` and pristine loops or rejects; and the two allocator
exhausted-regime witnesses of draft 44, `minimal/112-…`/`113-…`, where
pristine returns an overlapping, misaligned allocation and the fork kills out
of memory — §3); `diagnostic-text` is a
permitted class with zero rows — [USER 2026-09-17] ("(2) agree"): the lane's
diagnostic projection normalises source positions inside OCaml backtrace
frames — and, since the allocator-soundness slice's C1b (2026-09-17; the
[USER 2026-09-17] ruling quoted in §3), the position in the exception HEADER
line `File "…", line N, characters A-B: <text>`, path and text compared raw —
so a both-crash pair whose frames or header differ only there is a
`matching_failure`, not a row; and [USER 2026-09-17] ("(1) agree"): a
BOTH-sides timeout at the lane's own bound is the counted, non-failing
`matching_incomplete` class, never a row (one-sided timeouts and signal kills
stay fatal). A
SHARED-MODEL SLICE runs the three-way `pristine | fork | lean` report
(`test_upstream_oracle.py --with-lean`, LADDER Tier C row C5) over the full
pristine corpus and may add register rows only with a citation; a
fork≠pristine difference no existing citation explains is a finding for the
operator, never a row the slice writes itself.

## 1. The exception classes and their operational tests

Exactly four classes are not bugs. Each has a test a lane or a reader can
apply; anything that fails every test is a BUG-FIX row (mirror + tray).

**(a) Failure-path MESSAGE TEXT** may differ; the failure-vs-success
classification must be identical. *Test:* both engines fail on the input
(both `Error`, or both tool crashes — exit 125 uncaught exception on the
oracle, exit 134 `PANIC` under `LEAN_ABORT_ON_PANIC=1` on Lean), and only
the text differs. A crash on one side and a verdict on the other is NOT
(a). *Standing members:* the `Illformed_program` text (`Main.lean`
`driverErrorBatchMsg` vs `pp_errors.ml:501`; the libxml2-uri lane pins
it modulo the embedded symbol id, tray 17); the both-crash immaculate
pairs (`MATCH | L=CRASH`: `g2-memcmp-uninit`, `g4-bswap64-overflow`,
`g5-decode-multichar`, `offsetof-union-member`, the `zd-z2*` pairs);
front-end rejections reported on stderr by the oracle and as an `Error
{msg: …}` line on stdout by Lean (exit class identical — measured on 112
reject rows, Z1 record §2). Quoted PANIC texts carry build-relative line
numbers (`CerbMem:2075:6` today) — never compare them byte-wise. Since C-TF1 (2026-09-08, `docs/2026-09-08_monadic-failstop-record.md`) the
seven hand-written memory-model fail-stops are TYPED kills
(`Error0 CerbFail.modelFailStopLoc msg`) printed as the batch record
`ModelFailure {msg: "…"}` with exit 1, where the oracle dies with an
uncaught exception (exit 125): a both-fail pair, class (a) — the immaculate
pin label `L=CRASH` covers it under the lane's reviewed coarse crash
policy; the codec never lets a `ModelFailure` count as semantic agreement.

**(b) RESOURCE LIMITS** — Lean must not fail where the oracle succeeds;
the converse is acceptable. *Test:* the oracle completes the input
(within the lane bound) and Lean does not → a **(b)-VIOLATION**, i.e. a
BUG carrying a named mover, not a tolerated limit; loudness (`HANG`,
`KILL`, `TIMEOUT` classes) is necessary, not sufficient. A wall-clock
row is tolerated ONLY per row with measured completion at a larger bound
(charter Q5). *Standing members:* §3 lists them with their movers.
**(b)/fuel** — fuel exhaustion is accepted under (b), [USER 2026-09-03]
verbatim: "fuel is a reasonable exception because we could always just
run the semantics with more fuel"; the bound is a PARAMETER (`--fuel N`,
§7), and a FUEL row is never counted as agreement.

**(c) MISSING FEATURES** — [USER 2026-09-03], verbatim: "*missing
features* are allowed deviations if they are cleanly identified. CerbFS
is kind of an obscure feature as is concurrency, it's unclear if we'll
support it". *Test:* the Lean side REFUSES — non-zero exit AND a message
that names the missing feature and the boundary (not a symptom: a
file-not-found error for a flag is loud but not attributed) — where the
oracle answers. A different answer, or a silent absorption (an errno, a
default, a zero) is never (c). *Standing members:* §3.

**(d) ISO-CORRECTNESS FIXES — the register (§2).** [USER 2026-09-03],
verbatim: "I think that a short listed set of fixes is in keeping for
the purpose of cerberus-lean but the bar for such a fix must be
extremely high." *Test:* the deviation is an enumerated register entry
meeting criteria (i)–(vii) (or admitted BY CLASS as a kind-2 artifact,
§0), individually [USER]-ruled, pinned as a Lean-right/oracle-wrong
immaculate pair, with the `-- ISO-fix register R<n>` code marker. Nothing
else may deviate toward ISO.

Two further dispositions are not exceptions but are named here so no
reader mistakes them for one: **kind-1 fail-stops** are mirrored
(`panic!` with the OCaml text; the typed-failure pass — scheduled,
`docs/2026-09-03_typed-failure-outcomes-ruling.md` — will turn them into
a distinguished outcome so in-process consumers see the oracle's failure
class rather than a default value); **instrument artefacts** (a
pretty-printer filter, a stale scoreboard snapshot, a lane's extractor)
have no execution content and are fixed as instruments.

## 2. The ISO-fix register (class (d))

The ONE licence for a deliberate Lean deviation TOWARD ISO C (criteria
(i)–(vii) and the tightened (ii′) RATIFIED [USER 2026-09-03], charter
§1.4/§7 Q2/Q3). Each entry: an unambiguous oracle bug against a cited ISO
clause, a second independent oracle agreeing with Lean, filed upstream,
pinned in the immaculate lane as a Lean-right/oracle-wrong pair that
flips to MATCH — retiring the entry — when upstream fixes it,
individually [USER]-ruled, soft cap ≤ 10, and a grep-able code marker
`-- ISO-fix register R<n>` at the Lean site. Kind-2 OCaml-execution
artifacts (§0) are admitted BY CLASS under the referent ruling; the
register still lists them for visibility, the pin and the tray
cross-reference. Anything not listed here is a BUG-FIX (mirror + tray),
whatever a comment used to call it.

| entry | oracle behaviour (site) | ISO clause | 2nd oracle | tray | immaculate pin(s) | Lean code site | ruling |
|---|---|---|---|---|---|---|---|
| **R1** | `'\?'` / `"\?"` make `decode_character_constant` FAILWITH (decode.ml has no `\?` arm; `translation.ml:3032` for the string-literal form): uncaught exception, exit 125 | C11 §6.4.4.4#1 (`\?` is a simple escape sequence), #4 (value = `'?'` = 63) | gcc exit 63; `"a\?b"` → bytes `97 63 98 0`; `ptr_string_literals.c` output = gcc byte-for-byte | 10 (+ string-literal addendum, noodle E2) | `g5-decode-question` ORACLE_CRASH / L=Specified(63); `zd-e2-ptr-string-literals` ORACLE_CRASH / L=Specified(0) + the gcc byte string | `CerbDecode.lean` `| "\\?" => 63` (marker `-- ISO-fix register R1`) | **ADMITTED** [USER 2026-09-03] |
| **R2** | `%c`-stored char round-trips through `Decode.escaped_char` (= `Char.escaped`, decimal `\ddd`, decode.ml:221-222) then the OCTAL reader (decode.ml:184-197) inside `formatted.lem:769-771` `store_chars_in_array`: 127 is stored as 87 | C11 §7.21.6.1#8 (`%c`: the `int` argument converted to `unsigned char` is written) | gcc 127 | 11 | `g5-escape-roundtrip` DIFF / L=Specified(127) | `CerbDecode.escaped_char` (hex `\xNN`, exact round-trip; marker `-- ISO-fix register R2`) | **ADMITTED** [USER 2026-09-03] |
| **R3** | `memcmp` with a huge size: uncaught `Z.Overflow` at `impl_mem.ml:2660` `Z.to_int` — a host-int conversion raised BEFORE the semantic path (a KIND-2 OCaml-execution artifact, §1(d)) | (ii′) shape: no ISO answer for a UB program; the semantics' own checked per-byte load yields `UB_CERB002a` | the class ruling stands in for (ii′)(3): the referent is the logical semantics, and a host-language exception is not part of it ([USER 2026-09-03], `docs/2026-09-03_logical-semantics-referent-ruling.md`); tray 13's Z-native remedy on a scratch oracle build remains the check to run when the draft is filed, not a condition of admission | 13 | `s4b-memcmp-hugesize` ORACLE_CRASH / L=UB_CERB002a (stays as recorded) | `CerbMem.lean` memcmp (line-mirror minus the conversion; the (vii) marker `-- ISO-fix register R3` is owed by the code half of Z4) | **ADMITTED BY CLASS (kind 2)** — the referent ruling [USER 2026-09-03] as read by the orchestrator (`docs/2026-09-03_logical-semantics-referent-ruling.md`, consequences list), CONFIRMED by the operator [USER 2026-09-05: "(2) agree"]; supersedes the Z1 entry's "ADMITTED CONDITIONAL on Z4's (ii′)(3)" |
| **R5** | `float_of_string` (`Impl_mem.str_fval`, `memory/concrete/impl_mem.ml:2523-2524`; the Lem-level `Cerb_floating.of_string`, `util/cerb_floating.ml:8-16`, reaches the same routine) → `caml_float_of_hex` (OCaml 5.4.0 `runtime/floats.c:355` `f = (double)(int64_t) m;`, `:369` `f = ldexp(f, exp);`) rounds TWICE for a subnormal result (the ≤64-bit mantissa → 53 bits → the subnormal's shorter precision): `0x8000000000000BFp-1082` reads as `0x1p-1023`, one quantum below the correctly rounded `0x1.0000000000002p-1023`. Scope: hexadecimal literals with more than 53 significant bits whose value is subnormal and whose 53-bit pre-rounding lands on a tie. The defect is the OCaml RUNTIME's, no Cerberus source involved (also R3's host-artifact class under the referent ruling [USER 2026-09-03]) | C11 §6.4.4.2#3, last sentence: "For hexadecimal floating constants when FLT_RADIX is a power of 2, the result is correctly rounded." (`tools/n1570.json`; the decimal/non-power-of-2 latitude in the same paragraph does not apply) | gcc exit 1 on the pin program (`return 0x8000000000000BFp-1082 == 0x1.0000000000002p-1023;`); Python 3 `float.fromhex` → equal, bits `0x0008000000000001` | `ocaml/01-float-of-hex-double-rounding-subnormal.md` (OCaml-target draft, TRUE BUG) + 40 (Cerberus-facing, INHERITED / minor) | `r5-hex-subnormal-double-rounding` DIFF / `L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}` (oracle `Specified(0)`); flips to MATCH and retires the entry when the OCaml runtime is fixed | `CerbFloat.lean` `roundToBinary64Bits` — the single exact rounding (marker `-- ISO-fix register R5`); the correctly rounded bits are also pinned in `test/Unit/FloatLiteralTest.lean` | **ADMITTED** [USER 2026-09-15] ("Great, agree on your recommendation. Go ahead with the worker" — on the orchestrator's recommendation to admit the row as R5 and keep the correctly rounded conversion; charter `docs/2026-09-11_codex-charter-semantics-audit-repairs.md` §6) |

R4 (`dynamic_addrs`, tray 19) is DEFERRED [USER 2026-09-03] — mirrored,
not admitted (charter §2.6). The gate that asserts the register and the
marker set are in bijection is owed (charter §1.4 (vii)); today the
markers are `CerbDecode.lean` R1/R2 and `CerbFloat.lean` R5 (`grep "ISO-fix register R"`), R3's
is owed with the code half of Z4.

## 3. Every known Lean-vs-oracle difference, by class

The enumeration is the census — charter
`docs/2026-09-03_zero-discrepancy-design.md` §2 (77 rows at birth + the
Z1/Z2 additions §2.4b/§2.4c), one row per known difference with its
class, evidence and disposition; rows change class only by a commit that
cites its evidence. This section is the standing summary of what is NOT
a bug today and what is a bug still open, in the class vocabulary.

**(a) message text** — the members listed in §1(a). Nothing else.

**(b) resource — VIOLATIONS with named movers (bugs, not limits):**

- *Zero-initialised static aggregates above ~8 × 10^6 elements* HANG
  (exit 124, CPU/wall < 0.1; `char g[10000000]` does not complete,
  `char g[8000000]` does; the oracle completes 10 M in ~76–246 s). The
  mechanism is the Lean runtime entering closures by call in a
  function-typed monad's run loop (one `lean_apply_*` frame per element)
  plus the runtime's overflow-handler deadlock (tray `lean4/01`); record
  `docs/2026-09-02_mem-scale-record.md` §S1'. Movers: a lem-backend
  run-loop rendering of the monadic list combinators (lem-lean; TODO.md)
  and the upstream `.lem` accumulate-and-reverse shape (tray 18). Not a
  stack-size knob (a bigger stack only moves the silent onset).
- *Byte-list memory representation* — a large or program-computed
  allocation the oracle never touches is materialised on Lean
  (`tests/suite/parsing/array.c` out-of-memory panic; `pr20621-1.c`;
  `mem_malloc_4gb_lazy.c` OOM-KILLED at 6G). Mover: the representation
  change (chunked/sparse bytes with a compact unspecified-region form —
  `CerbMem.lean` byte path; profile first). Z2-M-04 already made
  `allocate_region` lazy for the untouched case, which moved
  `mem_calloc_overflow.c` from OOM-KILLED to agreement (Z4 docs record
  §2).
- *Exhaustive-mode wall-clock margins* — Lean is ~15–20× slower on
  recursion-heavy shapes with the same verdicts at a larger bound.
  Tolerated ONLY per row with measured completion: `pr63209.c`,
  `pr69320-4.c` have it (AGREE at 60–90 s); the 9 csmith `TIMEOUT` rows
  and the 11 gcc-lane `SKIP_LEAN_TIMEOUT` rows do NOT yet — each is a
  (b)-VIOLATION pending evidence until measured once (the code half of
  Z4).
- *(b)/fuel*: fuel exhaustion (`lem: fuel exhausted`, the FUEL class in
  every classifying lane; `sia_csmith_477/769` at the lane bound) — the
  accepted class, with the parameter (§7).

- *Non-UTF-8 bytes in a TEXT field of the Cabs JSON* (magic-comment text,
  `EDecl_magic`, `cabs_json.ml:657`; attribute-argument strings, `:600/602` —
  WHOLE strings, `c_parser.mly:1771-1775` concatenates the literal's fragments
  before the exporter sees them, so they stay TEXT): the exporter's
  `json_of_string` copies bytes ≥ 0x80 raw, the JSON is not UTF-8, and the
  bridge REFUSES the file loudly (`IO.FS.readFile`: "containing non UTF-8
  data") where the oracle proceeds — a fail-noisy class-(b) residual on
  non-UTF-8 SOURCE TEXT, not on literals (string-literal fragments and
  character-constant bodies are byte-carriers since the 2026-09-11 fix:
  `docs/2026-09-11_semantics-audit-repairs-record.md` §D2; row added per its
  charter §8 item 6). Mover: an encoder decision for the text fields, a
  separate slice.

**(c) missing features — loud, attributed refusals (not bugs):**

- *Semantics switches* (`--switches=PVI|PNVI|strict_pointer_arith|CHERI…`):
  REFUSED (`Main.refuseFlag`, exit 2, attributed; [USER 2026-09-03] Q7
  "REFUSE now … plumbing … is not wanted"). Matched default-switch mode
  is the harness contract; since 2026-09-05 the `CerbGlobal`
  config/switch surface is eleven plain `def`s of the driver's DEFAULT
  configuration (kernel-transparent, `rfl` lemmas — no opaque boundary
  row remains; `docs/2026-09-05_cerbglobal-defs-record.md`), so every
  `Switches.has_switch` read in the exec cone evaluates as the oracle's
  default by definition;
  since the seam-hygiene slice (2026-09-19, `docs/2026-09-18_seam-hygiene-record.md`
  §4) every switch-conditioned arm of `impl_mem.ml` is written in `CerbMem` in the
  explicit `if has_switch … then <loud kill> else <default>` shape — `CerbSwitch`
  carries the four switches those arms test (`strict_pointer_equality`,
  `strict_pointer_relationals`, `pointer_arith PERMISSIVE|STRICT`,
  `zero_initialised`, mirroring `switches.ml`), so the specialisation to the empty
  set is kernel-visible (`CerbGlobal.has_switch_*_eq`, by `rfl`) and greppable, and
  the Z2 record's formerly DECLARED row Z2-M-20 is closed; `using_concurrency` is `def … := false` with
  `using_concurrency_eq : using_concurrency () = false := rfl`, its
  parameterisation (step 2) owned by the concurrency feature branch.
  The oracle's `--switches=PNVI` CHANGES the answer (an integer→pointer
  UB043 becomes a value), so this is a feature we do not have, not a
  difference we hide.
- *Concurrency* (`--concurrency`): REFUSED, attributed — "not supported;
  the oracle's own mode is non-functional at `b9aeedcb4`" (`internal
  error: CONCURRENCY IS BROKEN`, `nondeterminism.ml:64` via `smt2.ml:38`).
  In matched mode atomics run sequentially and AGREE on both engines
  (`elab_atomic_qualifier_seq.c`, 8 traces each). A concurrency line of
  work exists on the branch `feature/concurrency` (a parametric model
  selector with an SC instance first); until it lands and is validated,
  the refusal is the contract.
- *CerbFS*: an in-memory file-system model that SERVES exactly the
  operations it can answer as SibylFS does and REFUSES every other,
  loudly (`PANIC … CerbFS refusal (fail-closed fs-model boundary): <op>
  …`, exit 134): the op-by-op served/refused table for all 25 `fs_*`
  entry points is the `CerbFS.lean` header and Z1 record §6 (refused:
  missing-file open without `O_CREAT`, any `O_EXCL`, write/truncate/append
  intent, reads/writes at non-prefix offsets, `lseek` past EOF or with an
  invalid whence, `stat`/`lstat`, every directory op, the link trio, …).
  No silently-divergent answer remains (Z-27 closed, Z1 `deb2338a8`;
  Z2-F-01 `lseek` EINVAL mirrored). The real-fs mover is OPTIONAL
  ([USER 2026-09-03] Q10).
- *`LEAN_ABORT_ON_PANIC` required* (Z2-FL-03): the driver refuses to
  start (exit 2) without it, because a Lean `panic!` — the fail-stop
  mirror of every OCaml failwith/assert/uncaught exception — would
  otherwise print and CONTINUE with a default value. Every harness sets
  it (`scripts/common.sh run_cerberus_lean`).
- *Zero executions from `runND`* (Z-73, [USER 2026-09-03] Q8 = A): Lean
  prints `Error {msg: "cerberus-lean: runND returned no executions"}` and
  exits 1 where the oracle prints nothing and exits 0 — a DECLARED loud
  boundary (a silent success with no verdict is the fail-open shape the
  working practices ban; the oracle's behaviour is a tray candidate).
- *Accepted command line:* `--batch | --pp-core | --parse-core` (argv[0]),
  `--first`, `--stdin`, `--libc <core>`/`--libc-tu <json>`, `--call <f>`
  [`--call-args`], `--args <str>`, `--trace-nodes`, `--fuel <N>`, `--address-space-top <N>`
  (address-space-bound slice, 2026-09-17: the run's address-space top, a positive
  integer; absent = upstream's value; 0 or a non-numeral refused, exit 2 — §7); any
  other `--` token, or a known flag out of its canonical position, is
  refused (Z-24; it used to be treated as a file name).

**(d)** — the register, §2 (R1, R2, R3).

The libc-mode allocation-address ordering defect **Z-28 is fixed** by the
Z3 mirror (`2ddc1300c`, already in mainline). The
[Z3 record](docs/2026-09-05_zero-discrepancy-Z3-record.md) records the source
repair and the address-printing programs' agreement. The old committed
sweep's STDOUT_DIFF rows are historical, not an outstanding Z3 implementation
task; current measurements are in the CI reporting record.

**Still open (bugs by the rule; each with its owner):**

- *libc-body UB locations* (Z1-A1): a UB raised INSIDE a libc C body
  carries the libc source location on the oracle and `<unknown
  location>` on Lean (the `--libc` pin is the oracle's Core TEXT dump,
  which has no locations). BUG-FIX with a named mover: a libc pin vehicle
  that carries locations. Surfaces as `UB_DIFF` rows in the sweep
  re-record.
- *`aligned_alloc(0, n)`* (Z2-M-01): the oracle's `Division_by_zero` is a
  KIND-2 artifact and is NOT mirrored; Lean's total remainder answers
  `Undefined {ub: "DUMMY(align_alloc)"}` for `(0, 8)` and a loud refusal
  for `(0, 0)` — neither principled. Pinned (`zd-z2m01-*`), tray 34
  drafted; the logical meaning is an operator decision (Z2 record
  §10.1: Core-level UB045 and/or the ISO 7.22.3.1 guard in `std.core:385`,
  both shared-model changes).
- *In-process consumers and kind-1 fail-stops*: no universal `drive`
  conformance theorem follows from avoiding known failure sites; byte,
  runtime-state and other obligations also remain. `failwithI` has an
  opaque logical definition with a default-valued implementation and a
  native panic override. When a result is discarded, even the native
  executable can erase the failure. Kernel reduction can also discard a
  mapped projection whose native execution aborts. The measured probes and
  strict-result correspondence proposal are in the
  [failure census](docs/2026-09-06_failure-census-and-correspondence.md).
  The earlier typed-failure ruling remains recorded; implementation beyond
  this charter's census/proposal awaits the final design discussion.
- *Instruments, not semantics:* `test_elab.sh`'s 3 recorded DIFF rows are
  a pretty-printer main-file filter difference (Z-40; `Main.lean
  ppCoreSignature` should mirror `pp_cond`); the committed
  `tests/ci_sweep/results/*.tsv` are a 2026-08-22 snapshot whose 43
  `CERB_INCONSISTENT` rows and `pr44468.c` row are stale (Z-42/Z-75) — a
  row that SURVIVES the re-record as `CERB_INCONSISTENT` is a
  bridge-attribution question, never INSTRUMENT by default. Both are the
  code half of Z4.
- *Oracle-suspect rows* (Lean == oracle ≠ ISO/gcc) are CORRECT under the
  rule and are NOT open bugs here: each is mirrored, pinned so a future
  "fix" toward ISO trips the exec lane, and filed as a tray draft (INDEX
  20–35). The gcc lane records them as `TRIAGED_*` today; the distinct
  `PINNED_TRAY_<n>` class (a confirmed shared-source oracle bug with a
  draft; the pin flips to AGREE on the upstream fix, any other movement
  is a regression) is owed by the code half of Z4 (charter §4.2).

**Fork ≠ pristine — the register (`scripts/upstream_oracle_differences.json`,
schema 2; gate: LADDER Tier B row 10).** These are not Lean-vs-oracle rows:
they are the fork OCaml's reviewed deviations from pristine upstream
`b9aeedcb4` as OBSERVED on row 10's corpora — the mirror twin's own exception
list (§0, the reference doctrine). Source-level fork≠upstream deltas that no
walked corpus witnesses are recorded as content pins in
`scripts/fork_drift_manifest.txt` (§6) and become register rows only once a
corpus observes them — a deliberate shared-model FIX the fork takes ahead of
upstream is nevertheless listed BELOW the moment it lands, with its citation
and pins, so the inventory here is complete even where the register is
silent; and "unobserved on the corpora" is a CLAIM to be tested by seeking a
witness, never assumed — the allocator fix of 2026-09-16 was first labelled
UNOBSERVABLE here and the label was FALSE (a 13-line program witnesses it;
its rows are below, added by the part-one pre-merge audit's finding M1). Every row binds both engines' signatures (exit status, stdout
sha256, stderr sha256 under the lane's diagnostic projection) and moves only
by a cited re-record.

- **`shared-model-fix` (3 rows; citations upstream-tray drafts 37/38/39,
  `tests/multi_tu_tray/README.md`):** `multi_tu_tray/node` — pristine does
  not terminate (`Ctype_aux.are_compatible` recurses forever on a
  self-referential struct defined in two TUs, draft 37; rc 124 at the lane's
  30 s bound — the ONLY pristine-side incomplete the register admits), the
  fork answers `Defined {value: "Specified(7)", …}`; `multi_tu_tray/
  arr-2-2-return` and `multi_tu_tray/arr-incomplete-ptr-return` — pristine
  rejects the compatible cross-TU struct value at `PEmemberof(struct)`'s
  exact-tag guard (`Error {msg: "ill-formed program: \`PEmemberof(struct)
  ==> mismatched tags: …"}` rc 1, draft 38), the fork (`dbe633ec5`: the
  compatibility consult + draft 39's one-token array-bound fix) answers
  `Specified(7)` — ISO C11 §6.2.7#1's value, gcc's exit. The rows retire
  (the cases move into `tests/multi_tu/`) when upstream fixes the drafts.
  Row 6b pins fork OCaml == Lean on the same inputs.
- **`shared-model-fix` — the allocator's EXHAUSTED regime (2 rows, added 2026-09-17
  by C1c; citations upstream-tray draft 44 +
  `docs/2026-09-16_allocator-soundness-address-bound-record.md`; TRUE BUG / model
  soundness; [USER 2026-09-16] *"unambiguously wrong … allowed to fix ahead of
  upstream"*):** `minimal/112-allocator-exhausted-single-request` and
  `minimal/113-allocator-exhausted-single-request-overlap`. Pristine `b9aeedcb4`
  `memory/concrete/impl_mem.ml:1254` (VIP twin `:209`) aligns the new base with
  the truncating-division idiom `z - (if q < 0 then -m else m)` over the
  EUCLIDEAN `quomod = ediv_rem` (`:9`), so once the cursor is below the request
  (`z = last_address - sz < 0`, within `-align/2 < z`) the allocation SUCCEEDS at
  an address in `(0, align)` — overlapping the live object at the cursor,
  misaligned. OBSERVABLE at upstream's own bound by ONE request larger than the
  cursor: the program reads its cursor as `(uintptr_t)malloc(1)` and requests
  `a - 7` bytes (`malloc_proxy`'s 8-byte argument temporary puts the cursor at
  `a - 8`; `z = -1`, `IvMaxAlignment` 8) — pristine `Defined {value:
  "Specified(6)", stdout: "", stderr: "", blocked: "false"}` rc 0 (112) and
  `"Specified(106)"` (113: address 6, + 100 "ends above the cursor", + 0 "not
  8-aligned"); the fork AND Lean `Error {msg: "MerrOther "Concrete.allocator:
  failed (out of memory)""}` rc 1. Found by the part-one pre-merge audit
  (`docs/2026-09-17_allocator-part-one-audit-premerge.md` M1, branch
  `audit/allocator-part-one`); UNOBSERVED by every previously walked corpus (no
  corpus program requested within `align/2` of its cursor) — the §0 doctrine's
  missing-case disjunct, now closed: both witnesses are `tests/minimal` rows
  (`scripts/exec_baseline.txt`, class `CERB_SKIP`: the exec lane does not sample Lean after an oracle `Error {` line, so these two rows GATE nothing on the Lean side — fork = Lean on them is evidenced by the kernel theorem, the unit witness's exact kill text and the three-engine report's `lean_agreement`, not by a pinned baseline; a gating pin is `tests/immaculate/nolibc` rows, part two's first instrument commit) and register rows. The C1
  text of this entry called the deviation "UNOBSERVABLE at upstream's bound
  (~2^48 bytes of cumulative allocation needed)" — FALSE; one request suffices.
  The fork takes remedy 1 in BOTH OCaml models (`memory/concrete/impl_mem.ml:
  1255-1263`, `memory/vip/impl_mem.ml:210-218`: the existing out-of-memory kill
  BEFORE rounding, then a plain align-down; the dead branch deleted) and in the
  Lean mirror (`CerbMem.lean` `allocator`, line by line), with the GENERAL kernel
  theorem `CerbMem.allocator_active_sound` (`CerbMemAllocatorProofs.lean`: an
  ACTIVE allocation is `align`-aligned, strictly positive, its end `a + sz` at or
  below the cursor — disjoint from everything at or above it, for `sz ≥ 0` — and
  becomes the cursor; no hypothesis on `sz`/`align`; axioms `propext`,
  `Classical.choice`, `Quot.sound`) and `allocator_below_request_kills` (remedy 1
  in kernel terms), plus the runtime witness `allocator-soundness-test` (the four
  draft-44 states on the actual `CerbMem.allocator`, the pre-fix values as the
  negative control). Fork engines AGREE with each other (Tier A rows 1–4b unmoved;
  the two new exec rows are `CERB_SKIP`, see above — the agreement on them is the theorem + witness + three-engine report); both files' content pins moved
  (`scripts/fork_drift_manifest.txt`, header notes "allocator-soundness C1"/"C1c").
  The rows retire when upstream takes the fix. A tiny address-space bound (the
  charter's part two, C2/C3) widens the witness set; it does not create it.
- **`diagnostic-text` (0 rows; a permitted class).** RESOLVED [USER
  2026-09-17] ("(2) agree", on the orchestrator's question — record §7): the
  lane's diagnostic projection — the one `matching_failure` and the
  register's stderr signature already used (the `Time spent` trailer removed)
  — additionally normalises `line N[-M], characters A-B` positions inside
  OCaml backtrace frames (`Raised at` / `Raised by primitive operation at` /
  `Called from` / `Re-raised at … in file "…"`) in BOTH engines' stderr, and —
  allocator-soundness C1b, 2026-09-17; [USER 2026-09-17], verbatim: *"yes,
  agreed regarding landing C1 as-is and then working on C2/C3 separately"*,
  given on the orchestrator's proposal that this projection be extended to the
  header (the proposal's text is quoted verbatim in record §S1,
  `docs/2026-09-16_allocator-soundness-address-bound-record.md`) — the same
  position in an OCaml exception HEADER line `File "<path>",
  line N[-M], characters A-B: <text>` (the `Assert_failure`/`Match_failure`
  printers; a fork edit ABOVE an assert site shifts it exactly as it shifts
  frames: C1's +5 lines moved `impl_mem.ml`'s `memcmp` assert 2659 → 2664,
  `immaculate/libc/g2-memcmp-uninit`, record
  `docs/2026-09-16_allocator-soundness-address-bound-record.md` §S1), the path
  and the text after the colon still byte-compared; the exception text, the
  frames' function and file names, non-frame lines (a Cerberus diagnostic
  quoting `line N, characters A-B` included) and every stdout byte (a
  header-shaped stdout line included) are compared untouched, and the raw
  stderr is retained in every capture. A both-crash pair whose frames differ only in positions
  (generated `.ml` line numbers shifted by the fork's `.lem` edits,
  `lem_list.ml` frames from the different Lem runtime, `pipeline.ml`/`main.ml`
  frames from the fork's driver additions) is therefore a `matching_failure`
  — `minimal/097`, the 16 `tests/immaculate` both-crash pins and the 4
  `tests/ci` `.error.c` rows all read so (row 10 `matching_failure` 11 → 28,
  C6 102 → 106) and the 21 rows that had pinned them were DELETED. A genuine
  exception-TEXT difference still needs a cited row of this class
  (plant-tested: an exception-text, frame-function or non-frame-position
  difference stays `difference`).
- **`matching_incomplete` — a REPORTED class, never a register row.** RESOLVED
  [USER 2026-09-17] ("(1) agree"): when BOTH engines exceed the owning lane's
  own bound (status 124 on both sides) the case is counted
  `matching_incomplete` — never agreement, not a failure; any ONE-sided
  timeout (either side) and any 137 stay `incomplete` and fatal exactly as
  before, and no register row is written for a matching timeout (the loader
  still refuses fork-side 124/137). The class is for UNREGISTERED cases: a
  registered case is always judged by its row, so a both-sides timeout (or a
  fork timeout) on a registered case is `difference` — the pin moved
  (pre-merge audit M1, [AGENT] reading flagged to the operator). Standing members: `tests/ci`
  `0023-jump1.c`/`0025-jump3.c` (30 s) and 21 of the first csmith shard's 50
  programs (15 s) — the fork lanes' own `CERB_SKIP` rows. `--corpus ci` and
  `--corpus csmith --shard K/34` are Tier C reporting rows that now exit 0
  (C6: 134 agree / 2 `matching_incomplete` / 106 `matching_failure`; shard
  1/34: 26 / 21 / 3).

## 4. What is compared, against what

**The oracle.** The OCaml Cerberus in this repository, built from the
same `.lem` sources (`make prelude-src` + dune). It is an *immovable
object* on the trust boundary. Plain-batch lanes decode complete verdicts
and validate process completion through the shared
[observation contract](docs/2026-09-05_observation-contract.md). `Defined`
includes value, stdout/stderr bytes and blocked state; `Undefined` includes
UB code, stderr and location; `Error` retains its full printed message.
The contract's matrix names each lane's ordering and projection: GCC uses
native exit membership, call-point pins project a single value/UB, and
legacy printer/reference checks retain their documented narrower purpose.
An acknowledged baseline difference or refusal is not observation agreement.

**Pristine upstream, the reference (§0).** The independently compiled
pristine engine (`b9aeedcb4` + upstream Lem `3802cb0`; kept standing by
`scripts/ensure_independent_oracle.py`, which reuses the lane's own
fail-closed manifest validator and never deletes or overwrites a build) is
compared with the fork OCaml by LADDER Tier B row 10 over every corpus the
fork-vs-Lean lanes GATE on — `tests/{minimal,coverage,debug,float,bytes,
libc_exec}`, `tests/multi_tu` + `tests/multi_tu_tray`, the 213 CN rows, the
libxml2 `uri` harness (libc and nolibc), `tests/immaculate` (nolibc/argv/
libc), `tests/verify` + the `lean_frontend/corpus` main-mode fixtures, and
two legacy CLI modes (855 cases, ~2 min warm); libxml2 `chvalid` is its own
Tier B row (4 slices, ~7 min); `tests/ci` and the csmith corpus are
reporting rows; `test_ci_sweep.sh`'s fourteen other suites (Tier C row C4,
`tests/gcc-torture/breakdown/*`, `tests/tcc`, `tests/suite`,
`tests/pnvi_testsuite`, `tests/hacl-star`, `tests/freebsd`, `tests/examples`,
`tests/cheri-ci` — a scoreboard with no baseline) are not walked and are
named in the report's `not_applicable`. Each corpus runs with the flags,
exclusions and per-case timeout of the lane that owns it (cited in
`corpus()`; `libc_exec` and `uri` at their lanes' 300 s, `immaculate` 60 s,
csmith 15 s, the rest 30 s; the three CLI rows, which no lane owns, at the
lane's default 30 s); the fork-only
interfaces (`--cabs-json`, `--call` and the wrapper TUs that mirror it,
`--pp=core` pin derivations, `--batch-alloc-census`) are named as not
applicable. The register (§3) is the exception list; everything else must
agree — semantically through the shared codec, or as the same failure under
the diagnostic projection (the `Time spent` trailer removed; OCaml backtrace
frame positions normalised, [USER 2026-09-17]); a both-sides timeout at the
lane's own bound is counted `matching_incomplete` ([USER 2026-09-17]) — never
agreement, not a failure — while one-sided timeouts and signal kills stay
fatal. This separates "our fork's
behaviour" from "upstream's behaviour": fork regressions and upstream bugs
are attributed, not conflated, and a shared-model change cannot move the
oracle and Lean together unnoticed. **Three engines on one input:**
`test_upstream_oracle.py --with-lean` (Tier C row C5) adds the Lean engine
through the fork's `--cabs-json` bridge exactly as each owning lane runs it
(bridge and driver under the lane's per-test memory cap `CAPPED_TEST` where
that lane caps: libc_exec, immaculate, uri, chvalid) and reports `pristine |
fork | lean` per case — report-only here (Lean vs
fork is gated by its own lanes); at WP-O's landing every one of its 40
Lean≠fork rows was a recorded pin of the owning lane (record §O2).

**Recorded expectations, where the oracle can't reach.** A few legs
are oracle-independent by design: the `tests/bytes` micro-lane
compares against committed upstream `.exec` records, and the
expectation files under `tests/verify`/`tests/corpus` pin previously
recorded verdicts as drift detection *on top of* the live
oracle-differential run.

## 5. The differential lanes

Normative tiers (what runs when) live in `scripts/LADDER.md`. The
lanes, with their recorded states:

| Lane | Corpus | Bar |
|---|---|---|
| `test_exec.sh --check-baseline` | upstream `tests/minimal` | 111/111 at the pinned baseline (106 + the five byte-bridge rows 107–111, 2026-09-11) |
| `test_exec.sh` (coverage/debug/float baselines) | upstream suites | rc 0 at pinned baselines (recorded DIFFs unchanged) |
| `test_bytes.sh` | `tests/bytes` | 9/9 at committed upstream `.exec` records + 5/5 reject pins (oracle-independent) |
| `test_address_space.sh` (+ `--selftest`) | `tests/address_space` (6 programs × tops 64/32/8; LADDER Tier A row 12, address-space-bound part two C3/C4/C5, 2026-09-17/18) | both engines at TINY address-space tops (the fork's FORK-ONLY `--address-space-top N`, cerberus-lean's `--address-space-top N` — the parameter of §7 instantiated where the allocator's exhausted regime is reached by ordinary programs): 18/18 LEAN = FORK complete observations through the shared codec (any difference fatal — the S4 class) AND every fork observation = its pinned row in `tests/address_space/expectations.txt`, fail-closed both directions (an unterminated final row is read — audit F3); the corpus holds ONE genuine discriminator of the draft-44 defect, `window-char-int7@32` (the pre-fix ALLOCATION at address 2 executed by the old-body probe, the C observation `Specified(2)` derived from it; fixed: the kill), and `--selftest` rejects that case forged to its pre-fix observation, a missing/truncated file, phantom/duplicate/malformed rows with and without a final newline, accepts the valid file without its final newline, and checks both CLIs refuse `2^64`, `0x40`, `6_4` and `1_8446744073709551615`, and accept `64` and `2^64 − 1` |
| `test_parse.sh` | tests/minimal + tests/ci | Cabs-JSON bridge, 234 files, 100% |
| `test_core.sh` | tests/minimal (+ tests/ci) | Core text parser vs oracle `--pp=core`, 111/111 minimal |
| `test_elab.sh` | elaboration corpus | recorded same/diff state, rc 0 |
| `test_multi_tu.sh` | `tests/multi_tu` | multi-TU linking differential, all entries |
| `test_multi_tu.sh --failure-class-projection tests/multi_tu_tray` | `tests/multi_tu_tray` (7 cross-TU struct-value cases; LADDER Tier A row 6b, 2026-09-15) | the same differential under the LABELLED WEAKER projection `failure-class` — `Symbol(<digits>, ` elided in Error/Undefined payloads only (the engines number symbols differently); 7/7 MATCH; the ONLY row not on `full`; two rows are OBSERVED MODELLING-LIMIT pins (`tests/multi_tu_tray/README.md`) |
| `test_libc_exec.sh` | `tests/libc_exec` | libc-linked execution at the committed baseline |
| `test_libxml2_uri.sh` | 16 URIs, 5 TUs, libc | **16/16 byte-identical** lean+libc vs oracle+libc, pinned per-lane expectations |
| `test_libxml2.sh` | libxml2 `chvalid` battery | 4 slices × 1,354 points, byte-equal verdicts (slow tier) |
| `test_cn_coverage.sh` | `deps/cn/tests/cn` | **213/213** at the exact-match baseline (multi-TU drivers, reject lane, manifest bijection) |
| `test_immaculate.sh` | curated pin suite | at baseline (incl. adversarial pins, e.g. the symbol-hash-collision tripwire) |
| `test_gcc_oracle.sh --check-baseline` | tests/minimal + debug + float + immaculate/nolibc + the staged csmith tier (1,997 final-candidate rows: 1,963 + the 34 rows added 2026-09-11/15) | gcc SECOND oracle (oracle-independent): native `gcc -O0` exit status vs the Lean verdict set, `-O2` spot tier, fail-closed triage ledger; at the pinned skip ledger `scripts/gcc_oracle_baseline.txt` (regressions fatal; improvements printed at rc 0). Tier B GATE since 2026-09-02 [USER]. Load caveat: the TIMEOUT-class rows are wall-clock sensitive (TIMEOUT_SECS=30; the slowest csmith rows hand-time at ~17 s on a quiet box, and a busy box — load ≈12 at the 2026-09-02 audit — pushed one over) — a REGRESSION whose only movement is into SKIP_LEAN_TIMEOUT is re-run on a quiet box before it is read as red; no code change. |
| `test_verify.sh` | `tests/verify` + `corpus/` | pin provenance (oracle `--pp=core` re-derivation byte-identical / content-hash) + main-mode differentials + per-function call-point differentials (Lean `--call` vs oracle wrapper TU vs recorded pin) — 127 checks at the Z2 close (record §14) |
| `test_speclab*.sh` (6 scripts) | rendered harness families | five families (scalar/bytes/list/tree/CN-seed): sweeps, deterministic fuzz with byte-wise shrinking, plant tests, pinned-term gates — ~2,000 recorded differential executions, all agreeing |
| `test_csmith_corpus.sh` | 1,669 in-tree csmith programs | classified pinned baseline (sharded; reporting tier full-pass): 0 MISMATCH/DIFF rows; the non-MATCH rows are 499 `CERB_SKIP` (oracle-side) + 9 `TIMEOUT` (derived from `scripts/exec_csmith_corpus_baseline.txt` at `928aa1e76`; the header's per-row narrative is the arc-13 record) |
| `test_ci_sweep.sh` | 2,186-file upstream CI suite | [Repaired candidate measurement](docs/2026-09-06_ci-reporting-results.md): 1,359 matching observations, one UB-location difference, three filesystem refusals, three Lean timeouts and 820 oracle-side non-comparisons. All 15 fresh TSVs/raw records are archived. The default TSVs under `tests/ci_sweep/results/` remain historical (14 from August 22, TCC from September 2); no automatic baseline adoption. |
| `fuzz_csmith.sh` | generated csmith programs | deterministic seeded fuzz kit (reporting tier) |
| `test_upstream_oracle.py` (+ `--plant`) | pristine upstream `b9aeedcb4` vs fork OCaml over the Tier B row-10 corpus (855 cases: the six Tier A exec corpora, both multi-TU roots, 213 CN rows, uri ×2, immaculate, verify + corpus, 3 CLI rows) | **Tier B row 10 GATE**: `passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 3, 'interface_agreement': 2}` at WP-O O5 (2026-09-17; before the two rulings: 822 / 11 / 20 / 2); the 3 reviewed rows are the register's (§3); plants: 19 doctored registers rejected at load (incl. untracked-file, out-of-range-line and `..` citations) and the committed register loads, the compare() timeout/kill/stale matrix (unregistered both-sides 124 → `matching_incomplete`; a registered case judged by its row — its fork timing out or a both-sides timeout is `difference`; one-sided and 137 fatal), the projection plants (frame positions only → `matching_failure`; exception text / frame function / non-frame position → `difference`), a fork-verdict mutation and a REAL registered difference with its row withheld → RED |
| `test_upstream_oracle.py --corpus libxml2_chvalid` | pristine vs fork on the 4 chvalid slices (the fork lane's flags and 300 s bound) | **Tier B GATE**: 4/4 `semantic_agreement` (~7 min) |
| `test_upstream_oracle.py --with-lean` | the same corpus, three engines | Tier C row C5, report-only Lean column: 813 agree / 28 difference / 12 both-undecodable / 2 n/a at WP-O, all 40 Lean≠fork rows recorded pins (§4) |
| `test_upstream_oracle.py --corpus ci` / `--corpus csmith --shard K/34` | `tests/ci` (242 cases) / the 1669 staged csmith programs | Tier C reporting rows, rc 0 since [USER 2026-09-17]: ci `passed; {'semantic_agreement': 134, 'matching_incomplete': 2, 'matching_failure': 106}`; csmith shard 1/34 `subset_passed; {'semantic_agreement': 26, 'matching_failure': 3, 'matching_incomplete': 21}`, ~11 min per shard (~6 h for the corpus — never one step) |

Lane semantics worth knowing:

- **Baselines fail closed in both directions** — with one audited,
  deliberate exception. In the oracle-differential exec lanes
  (`test_exec.sh --check-baseline` and friends) a regression fails
  AND an unexplained improvement fails (silent movement is how errors
  hide). The gcc SECOND-oracle lane (`test_gcc_oracle.sh`) fails on
  regressions only and surfaces improvements loudly at rc 0 (by the
  lane's own audited design: its rows classify oracle-INDEPENDENT
  gcc-agreement, where an improvement is a skip-class row starting to
  agree with gcc — e.g. after an unrelated fix lands on mainline —
  and blocking every commit on re-recording that scoreboard would
  make the gate fire on good news; the improvement is still printed,
  and re-records remain dedicated instrument commits). Since
  2026-09-02 [USER] the lane is a Tier B GATE on that asymmetric
  contract: rc must be 0 at slice boundaries / pre-merge. Baseline
  updates are instrument changes: dedicated commit, justification in
  the header.
- **Plant tests.** Gates and lanes are themselves tested by
  deliberate sabotage: break the thing the gate should catch, watch
  it go red, revert, re-verify green. A gate that has never caught a
  plant is treated as untested code.
- **The oracle guards itself.** The single-supply backstop
  (`CERB_FRESH_FLOOR_VIOLATION`, exit 70) makes a mis-built oracle
  refuse loudly rather than compare wrongly, and the lem-sync
  content-hash gate makes a stale generated tree a build failure on
  both the OCaml and Lean sides.
- **The tolerated renumbering class (upstream divergence, declared).**
  The effect-retirement arc replaced the ambient fresh-symbol counter
  with explicit supply threading; the oracle's dynamic draw SEQUENCE
  moved on affected inputs (eager-batch dispersal — statement lists,
  call-argument batches, elaboration prefixes), so the fork's oracle
  Core dumps diverge from un-forked upstream **textually,
  up-to-renaming of symbol ids, on affected inputs** — same term,
  bijectively renamed, verdicts everywhere unmoved. Ruled TOLERATED
  [USER 2026-08-31, re-affirmed over the enlarged class 2026-09-01]
  with a standing operator principle: output depending on symbol
  numbering beyond binding identity is itself a defect (registered
  finding + upstream candidate, never accommodated). The affected pin
  set and its one-time rebaseline: every moved artifact was admitted
  only on machine-checked same-draw-count + permutation-only
  equivalence (`scripts/check_renumber_only.py`, itself plant-tested
  by `scripts/test_renumber_plants.sh`); the enumeration lives in the
  C1/C2 rebaseline commits and `scripts/fork_drift_manifest.txt`'s
  header note. One numbering-dependent output site was found and
  registered (finding C1-F2: a libxml2-uri diagnostic embedding a raw
  symbol id — upstream candidate; the oracle's own diagnostic does
  the same). Records: `docs/2026-08-31_effect-retirement-design.md`
  §3.6/§9, `docs/2026-09-01_C1-adoption-record.md`,
  `docs/2026-09-01_C2-ratchet-record.md`.

**Per-test resource limits.** Execution lanes use `timeout` with
lane-specific bounds. The seven larger-input harnesses listed in
`scripts/LADDER.md`'s resource-cap convention additionally use a per-test
cgroup RESIDENT-memory cap since mem-scale S2 (2026-09-02, Q2 [USER
2026-09-02]):
`scripts/common.sh` `CAPPED_TEST` → `scripts/capped` with
`CERB_TEST_MEM_MAX` (default 4G), replacing the arc-5 `ulimit -v 4000000`
(a virtual-address-space cap that killed Lean at ~1.7 GB RSS while the
oracle ran to 3.1 GB — record `docs/2026-09-01_mem-scale-profile.md` §2).
The cap does not cover every direct invocation in every script; for example,
`test_exec.sh`'s small-corpus helpers use timeout without `CAPPED_TEST`.
The classifying lanes distinguish a low-CPU timeout (`HANG`, S0) from a cap
breach. A positive capped OOM witness, derived from `memory.events oom_kill`,
identifies a breach at any surviving parent status, including 0 and 1.
It produces the lane's KILL class and never observation agreement. Native
GCC's `SKIP_GCC_KILL`/`O2_SKIP_KILL` are explicit applicability exclusions.
A bare 137 without the witness follows the relevant engine/native protocol,
not an assumed OOM classification. Plants:
`scripts/test_hang_plant.sh`, `scripts/test_kill_plant.sh`.

## 6. The build-time gates (`scripts/test_unit.sh`)

Unit executables (parser tests, pretty-printer mirrors vs recorded
OCaml output, fresh-symbol/native-extern probes, and the compile-time
totality/reader-lifting exemplars `effects-proof-test` /
`totality-proof-test`: every fuel'd wrapper FUEL-PARAMETRIC — `@f ⟨n⟩ =
f_lemFuel n` for every `n`, by rfl —, symbolic equations on the total
layout defs, `tagDefs` an honest parameter — properties of the exec cone
as built; and `fuel-exemplar-test`, the FUEL arc's consumer-shaped ∀-fuel
theorem over the shipped pipeline `@drive ⟨fuel⟩` at the ambient
`[LemFuel]` instance, §7), then the gate scripts — all fail-closed:

| Gate | Guarantee |
|---|---|
| sync gate (`tools/check_handwritten_sync.sh`) | every hand-written file byte-identical to its compiled `generated/` copy (the binary corresponds to the sources); copy set enumerated from `lean_frontend/handwritten_copy.manifest`, the same list the Makefile copies from; every `lean_frontend/*.lean` must be listed; empty set = FAIL. Also a precondition of `build_lean` and of the driver-freshness stamp's Lean record/check (2026-09-02 gap: a green stamp over a stale-copy binary) |
| `check_exec_purity.sh` | the execution slice is free of unsanctioned IO/effects |
| `check_theorem_axioms.sh` | **zero `axiom` declarations anywhere** — hand-written census, generated-tree census, and the recursive census of the consumed LemLib package copy (the effect-retirement end state: `runEffectful` is deleted, `declare {lean} effectful` is refused by lem itself); `runEffectful` token-banned (comment-stripped) across all three trees; the `@[implemented_by]`/`unsafe`/`unsafeBaseIO` seam population pinned to `scripts/unsafebaseio_allowlist.txt`'s PIN rows exactly, both directions (a new seam fails naming itself — this bans an axiom-free reintroduction of the effect projection); the boundary-OPAQUE POPULATION pinned exactly-once, both directions (12 registered rows since seam-hygiene H3, 2026-09-19 — the digest boundary, the enum registry, `bounded_integer`, and the pure atoms `CerbFuel.fuelExhaustedLoc`/`CerbFail.modelFailStopLoc`; history: 15 from 2026-09-05 when the 11 `CerbGlobal` config/switch opaques became plain `def`s (`docs/2026-09-05_cerbglobal-defs-record.md`), 16 with C-TF1's `modelFailStopLoc`, 12 when the CerbUtils timing/log trio and `CerbMem.beqMemValueSafe` became plain defs (`docs/2026-09-18_seam-hygiene-record.md` §5.4); an unregistered `opaque` fails naming itself); zero `unsafeCast`; exemplar + `driver2` cones free of `sorryAx`/`ofReduce*`/DAEMON; the FUEL arc's contract lemmas (the nine GENERATED `*_lemFuel_zero`, the `CerbND` runner leaves, the fuel-parametricity `rfl`s `@X ⟨n⟩ = X_lemFuel n`) and the exemplar theorems at the exact allowlist; the full exec-entry set (`driver2`, `drive`, `initial_driver_state`, `desugar`, `annotate_program`, `translate`, `link`, `convert_file`, `CerbCall.driveCall`) at the **exact** axiom allowlist `[propext, Classical.choice, Quot.sound]`; non-kernel decision procedures (`native_decide`/`bv_decide`) grep-banned. Source-scan legs are the primary evidence; the `#print axioms` probes are end-to-end spot checks (they underreport across `partial def` boundaries) |
| `check_sorry_token.sh` | zero `sorry` TOKENS in source text — comment- and string-stripped — over `generated/`, the hand-written seams + tests, and the consumed LemLib copy (the axiom gate probes `sorryAx` in cones only; the tree's last `sorry`, cmm_op.lem's target_rep, was closed by the FUEL arc). Empty scan set = FAIL |
| `test_fuel_classifier.sh` | the one FUEL classifier (`scripts/fuel_classify.sh classify_fuel_outcome`) reads its fixture captures correctly: both fuel forms positive; a genuine `Error` kill, a PANIC without the marker, and program stdout carrying the words all negative (§7) |
| `check_no_fuel_numerals.sh` | **a plant-tested SPEEDBUMP against fuel numerals in the Lean text a consumer reasons against** (fuel-parameter arc, 2026-09-04; [USER 2026-09-03] "any and all magic values that are hardcoded and can't be quantified over are definitionally bugs"): seams, `generated/`, `test/`, `speclab/`, `tests/**/*.lean` scanned comment-stripped for the enumerated idiomatic shapes F1–F6 (the deleted `lemDefaultFuel`/`driverFuel`/`ndDefaultFuel`; a global `instance : LemFuel`; a worker at a literal counter — bare, parenthesised, hex, or after a carried instance `f_lemFuel ⟨i⟩ 5`; `LemFuel := ⟨…⟩`/`LemFuel := { fuel := … }`/`LemFuel.mk N`/`LemFuel.mk (…)`; a single-component anonymous constructor led by a numeral `⟨N⟩`/`⟨(N : Nat)⟩`/`⟨0x…⟩`/`⟨10^8⟩`; a fuel-named constant defined as a numeral) — the ONE allowed site is Main.lean's `defaultFuel` (+ the `letI` that consumes it), allowlisted by exact line; vacuity-guarded; its `--selftest` plants 20 shapes red and the unplanted set green on every `test_unit.sh` run. What it does NOT guarantee (pre-merge audit M2): indirection through a non-fuel-named constant (`def budget := 100000000; @f ⟨budget⟩`) and arithmetic spellings not led by a numeral are not regex-closable — the selftest records that gap as a KNOWN GAP line; they are review discipline. The BACKSTOP is the typing, not the grep: every fuel'd function demands a `[LemFuel]` instance, no instance exists in library/generated/seam code, and a measured wrapper carries its sufficiency obligation — a numeral can only enter where a human writes an instance |
| `gen_fuel_parametricity.py --check` | the generated tree's ambient fuel-wrapper SET equals the set pinned by `TotalityProofTest.lean` Part 1's `∀ n, @f ⟨n⟩ = f_lemFuel n` examples, both directions (a new fuel'd function without a pin is RED; `--emit` regenerates the list) — pre-merge audit M1 |
| `check_lakefile_roots.sh` | every `generated/*.lean` — the `_auxiliary` obligation carriers and the `*_lemMeasureProofs` modules included — is a Lake root of the semantics library and every root exists, both directions (lem-lean fuel-measure record §6.4 item 8: an auxiliary module dropped from the roots would silently un-build its obligations); `--selftest` plants a dropped root, a phantom root and an unrooted module |
| `check_exec_totality.sh` | zero `partial` definitions on the execution path (empty allowlist; fuel-totalized recursion with the distinguished fuel-exhaustion outcome, §7) |
| `check_fuel_forms.sh` | **the (A)/(B)/(C) fuel-forms gate** (fuel-parameter arc C2, 2026-09-04; hypotheses C4, 2026-09-05; contract repair P0, 2026-09-05 — `docs/2026-09-05_p0-instruments-record.md` §F2): every fuel'd worker in the compiled environment is MEASURED (obligation of the contract's shape — heads by name, `lemFuel`/`lemHyp` binders, and the ARGUMENT CORRESPONDENCE: the wrapper side is the wrapper on the statement's binders in order, the worker side passes `lemFuel` once at the worker's own `lemFuel` parameter and otherwise only wrapper inputs, and the wrapper's own body unfolds to the worker on those very arguments with the hypothesis' μ at the fuel position; obligation + proof cones ⊆ the standard three), ABSORBING = kill at zero (its `_zero` lemma states THE worker at literal 0 on its own binders and its RHS is the monad's absorbing element; cone ⊆ the standard three; propagation of exhaustion through successor cases is NOT proved — lem-lean TODO row 13), or AMBIENT and then either unreachable from the drive cone (kernel constant closure incl. mutual blocks) or a reviewed row of `scripts/fuel_forms_pending.txt` — both directions; the classifier is `lean_frontend/test/Unit/FuelFormsTool.lean` (runtime `importModules`, no source regex; the fuel binder pinned by its NAME `lemFuel`, the hypothesis-carrying form by its reserved binder `lemHyp` immediately before it, whose type is reported as the `hyp` column); **the gate BUILDS every module it imports before importing it** (hotfix `fix/fuel-forms-carriers` 2026-09-20, finding F-1 — `docs/2026-09-20_fuel-forms-carriers-hotfix-record.md`: `lake build` of the exec entries and every `*_auxiliary`/`*_lemMeasureProofs` carrier, and the selftest's scratch decoys compiled from source — fail-closed, the FAIL naming the module; until then a carrier's `.olean` was imported AS FOUND, and `CerbMem_lemMeasureProofs`' pre-seam-hygiene artifact certified nine obligations vacuously from 2026-09-19 to 2026-09-20). Every MEASURED-under-hypothesis row must equal a row of the REVIEWED register `scripts/fuel_hypotheses.txt` (worker, exact hypothesis text, the frontend invariant with a `.lem:<line>` cite, a reviewer) — both directions, because a CONTRADICTORY hypothesis (`x ≠ x`) passes generation and proves its obligation vacuously (lem-lean measure-hypothesis audit F1). `--selftest` plants six doctored tables, three doctored registers, the F-1 stale-carrier plant P24 (a stale-valid `.olean` over a source that no longer compiles: the gate must FAIL naming the module with the `.olean` untouched) and 15 COMPILED decoys (a same-named theorem of type `True`; the right shape with the wrong worker constant; the real `CerbMem.alignofCtype` obligation under `cty ≠ cty` — MEASURED by shape, RED by the register; a real registered obligation with an EXTRA Prop binder — audit F-A4; the whole-project audit's two decoys verbatim — a `_zero` lemma about `CerbND.runNDFuel` under another worker's name, and `review_shift_lemFuel lemFuel 0 = review_shift x`; wrong fuel position; swapped arguments on either side; a changed measure; a wrapper calling another worker; a premise hidden in the `≤` binder; a well-formed `_zero` positive control; a `_zero` at a term; a `_zero` at fuel 1) — each rejected with its own message; MEASURED/ABSORBING are decided by the fully-qualified name AND the statement's shape against the worker and wrapper definitions (§7, the (A)/(B)/(C) table) |
| lem-sync gate | generated trees content-in-sync with the `.lem` sources (stamped; also wired into the dune graph for the libc `.co` artifacts) |
| `check_fork_drift.sh` | the fork's oracle-side surface equals a reviewed manifest, and generated-OCaml fork-vs-upstream deltas match pinned hashes |
| `check_fixture_freeze.sh` | the `corpus/` differential-fixture set matches its hash manifest exactly (additions included) |
| `check_failure_reach.sh` | **the failure-reach register gate** (fuel-pending close-out 2026-09-08 — option C of the pure-failure reachability census `docs/2026-09-07_pure-failure-reachability-census.md`; the TRIPWIRE the parked twin design `docs/2026-09-07_pure-failure-correspondence-design.md` names): rebuilds the one-module declaration-dependency instrument `tests/failure-probes/FailureReach.lean` (fresh scratch Lake package, ~6 s), takes the lexical census (`scripts/failure_census.py`) and requires every PURE `failwithI`/`panic!` site of the exec dependency closure (231) + every pure site with an unresolved kernel owner (2) to equal a row of `scripts/failure_reach_register.txt` — same position class (the census's token-level classifier `scripts/failure_position.py`), the census's reviewed reach class (166 UNREACHABLE-BY-INVARIANT / 48 REACHABLE / 17 UNKNOWN; the 2 unresolved rows UNKNOWN), sealed rows — both directions; RED naming the rows on a NEW site, a stale row, a moved position class, a DISCARDABLE generated let-binding (the F1 shape: a dead binding of a failure — today 0) or an unsealed class edit. Reach classes are reviewed claims (an invariant NAME with a cite, or a witness under `tests/failure-probes/reach/`), not theorems; the closure is a kernel constant-dependency closure, not a path. `--selftest` plants five cases on scratch copies (a new site in a generated exec-closure definition, a dead let, an unsealed class edit, a phantom row, an edited tally) |
| `test_renumber_plants.sh` | the rebaseline-admission instrument (`check_renumber_only.py`) refuses what it must: committed adversarial pairs (string-content/comment-boundary holes + count/token/order plants) fail, positive controls admit with their declared class |

Certification-integrity rules ride the gates: validation of
build-rule-affecting changes is cache-disabled from re-derived
generated trees; audits check the artifact the consumer actually
loads (the libc.co staging pattern); quoted outputs are verbatim.

## 7. Fuel — the parameter, the exhaustion outcome, the (A)/(B)/(C) forms

**Fuel is a PARAMETER of the semantics; fuel exhaustion is a typed,
distinguished outcome.** Every fuel'd generated function (67 sentinel
declares at the C1 slice; the `declare {lean} fuel val f = \`sentinel\``
form) is a total worker `f_lemFuel (lemFuel : Nat) …` whose wrapper
starts the counter from the LemLib class instance `[LemFuel]` (`def f
[LemFuel] := f_lemFuel LemFuel.fuel`) — or, for a `declare {lean}
fuel_measure val f = \`lemSize x\`` function, from the backend-derived
structural size of its argument (`def ctypeEqual (c c0) := ctypeEqual_lemFuel
(ctype.lemSize c) c c0`: no fuel binder, kernel-computable, with the
generated sufficiency obligation `ctypeEqual_measure_sufficient` proved
in the hand-written `Ctype_lemMeasureProofs.lean`; three such at C1:
`ctypeEqual`, `eq_core_base_type`, `fake_mem_value_eq`, the `Eq`
instance methods) — and every definition that
reaches one takes the same instance-implicit binder (the backend's fuel
lifting; the hand-written seams that reach fuel — the `CerbMem` layout
and (de)serialisation entries, `runND`/`runND1`/`runND1Trace`,
`CerbCall.driveCall`, `Main.runPipeline` — take it too, and the 19
`mem.lem` reps whose implementations read it are `declare {lean}
fuel_consumer`). So the whole run has ONE fuel, instantiated exactly
once at the executable's entry: `cerberus-lean … --fuel N` (default
`Main.lean` `defaultFuel` = 10^8, THE ONLY fuel numeral permitted in
the repository's Lean text — `check_no_fuel_numerals.sh`; 0 or a
non-numeral is refused, exit 2), and a theorem quantifies over it
(`∀ n, @f ⟨n⟩ = f_lemFuel n` by rfl is the parametricity pin for every
wrapper — `totality-proof-test`, `CerbND.*_wrapper_defeq`; the
consumer's hypotheses become `∀ [LemFuel], potential e ≤ LemFuel.fuel →
…`). This is the fuel-parameter arc ([USER 2026-09-03]: fuel "is an
execution parameter that 'doesn't matter' … a parameter which can be
chosen as 10^8 or any other value when calling the interpreter"; "Any
and all magic values that are hardcoded and can't be quantified over
are definitionally bugs"); the former constants `CerbFuel.driverFuel`
(10^8, the driver family), `CerbND.ndDefaultFuel` and LemLib's
`lemDefaultFuel` (10^6, everything else) and the per-declaration numeric
budget form are DELETED (lem-lean
`doc/lean-backend/2026-09-03_fuel-parameter-design.md` R1–R3;
`docs/2026-09-04_fuel-parameter-C1-record.md`). Every fuel'd callee
starts from the FULL ambient, never from its caller's remaining
counter.

The exhaustion outcome: for the ND monad's fueled workers (the driver
loop family, the memory-model ND workers, and the `CerbND` runners) the
fuel-zero arm is `NDkilled CerbND.fuelExhaustedKill` = `Error0
CerbFuel.fuelExhaustedLoc "lem: fuel exhausted"`, where
`fuelExhaustedLoc` is a pure, kernel-checked `opaque` constant on the
boundary-opaque census (present exactly once; no native binding). Every
proof is uniform in the opaque atom; the sentinel is a fresh location
for every provable statement — a theorem "every outcome is `Killed _
fuelExhaustedKill` or good" holds under the reading where the atom is a
location no model term denotes, and a program that genuinely kills makes
it unprovable, not false; so no distinctness lemma is needed (corollary:
no `.lem` term, Core text, or JSON input can denote the atom). The
`_zero` lemmas are GENERATED by lem beside each wrapper
(`f_lemFuel_zero … : f_lemFuel 0 … = <sentinel> := rfl`; the nine
ND-typed ones are gate-probed).

**The (A)/(B)/(C) classification (C2, 2026-09-04; counts as of the
parser-progress-measure slice, 2026-09-15 — `docs/2026-09-11_parser-progress-measure-record.md`; before it the fuel-pending close-out, 2026-09-08 — `docs/2026-09-08_fuel-pending-closeout-record.md`) — the consumer's truth condition, gate-checked by
`scripts/check_fuel_forms.sh` from the kernel environment
(`lean_frontend/test/Unit/FuelFormsTool.lean`; records
`docs/2026-09-04_fuel-parameter-C2-record.md`,
`docs/2026-09-05_fuel-parameter-C3-record.md`,
`docs/2026-09-05_fuel-parameter-C4-record.md`):** every fuel'd worker
(81: 67 generated + 14 hand-written) is

| form | count | meaning | for the consumer |
|---|---|---|---|
| (A) MEASURED | 62 (12 under a hypothesis) | `def f xs := f_lemFuel (<data measure>) xs`; theorem `f_measure_sufficient : [H →] measure ≤ n → f_lemFuel n xs = f xs`, cone ⊆ the standard three (53 generated + 9 `CerbMem` seams by hand: `typeofMval`/`unqualifyAndUnatomic`/`memValueToBytes` unconditional, and — C4 — the layout oracle `sizeofCtype`/`alignofCtype`/`memberAlign`/`offsetsofMembers`/`offsetsof` and `reconstructValue` under `CerbTagsWf.Acyclic ambient` (`AcyclicPair ambient tagDefs` for `offsetsof`): a rank on tag-environment entries descends along every by-VALUE reference — a theorem hypothesis, not an established frontend invariant, `scripts/fuel_hypotheses.txt`; measures `CerbTagsWf.envBound` & co. = structural size + the environment's weight; plus `showNonNegativeWithBasis_aux` under `2 ≤ b` (lem `assuming`, the first generated hypothesis-carrying row); and — the fuel-pending close-out, 2026-09-08 — the three always-on-path sentinels `hack` (`lemSize pexpr1` under `CerbCoreShape.IsValuePexpr pexpr1`), `to_pure` (`lemSize g` under `CerbCoreShape.IsPureExpr g`) and `to_pures` (`List.length l + 1` under `CerbCoreShape.AllPureExprs l`): the arena is `Epure` of a `PEval` value after `prepare_exit` (driver.lem:1309-1316), the only exit of `driver2`, so each needs ONE hop at `finalize`/`driver_globals`; `CerbCoreShape.lean` is the shape vocabulary, `Driver_lemMeasureProofs.lean` / `Core_aux_lemMeasureProofs.lean` the proofs; and — the parser-progress-measure slice, 2026-09-15 — the two parser workers `many_run`/`many1_run` (`2 * List.length cs + 2` / `+ 1` under `CerbParserProgress.Consumes p`: every result of `parse p cs` leaves a strictly shorter rest; `many`/`many1` were restated as input-indexed recursion so the input IS a parameter — the same parsers on every input, kernel-related to the old workers in `test/Unit/ManyRestatementTest.lean`; the hypothesis is a THEOREM at every printf call site, `CerbParserProgress.callSites_consume`; proofs `Monadic_parsing_lemMeasureProofs.lean`). The six point-free `function` tails joined at C3 — lem d4ba548 hoists the scrutinee into the head as `lemTail`; the two mutual blocks share one counter, so each member's measure bounds the whole block) | fuel-FREE: no `[LemFuel]` in statements (four keep the binder for an ambient callee: `memValueFromValue`, `step_eval_pexpr`, `easy_update_mem_value_aux`, `memcmp_load_aux`; `CerbMem.memValueToBytes` lost its binder at C4 with the layout oracle it read) |
| (B) ABSORBING ("kill at zero") | 13 | `f_lemFuel_zero` states `f_lemFuel 0 xs…` — the worker itself, at literal 0, on the lemma's own binders (P0 gate check) — and its RHS is the monad's absorbing element at the fuel atom: the ND kill (`nd_bind`, `liftND`, `liftAction`, `driver2`, `drive_nonmemory_steps_aux2`, `print_eval_conv_aux`, `load_character_array_aux`), `Result (Error fuelExhaustedLoc fuelExhaustedMsg)` in the undefined monad (`full_eval_pexpr`, `eval_pexpr_aux2`, `eval_pexpr_aux_broken`), the runners' `Killed` | at fuel 0 the result IS the kill; that exhaustion at a deeper fuel propagates through every successor case ("never continues as a value") is NOT proved by this gate — it is lem-lean TODO row 13 (fuel monotonicity), pending |
| (C) OUTSIDE EXEC DEPENDENCY CLOSURE | 6 ambient | not in the kernel constant closure of `drive`/`initial_driver_state`/the runners/`CerbCall.driveCall` (mutual blocks closed): the DEFACTO memory model's `mkUnspec`/`simplify_integer_value_base` (not the wired model), `zeros_aux` (front end), `list_unfoldr_aux`, two `CerbMem` reference forms | absent from this dependency closure; no general API unreachability claim |
| PENDING | 0 | reachable AND ambient, each a reviewed row of `scripts/fuel_forms_pending.txt` with its reason — the register is EMPTY (header-only; the gate accepts an empty register and any new reachable ambient worker is RED). History: the 6 point-free tails left the register at C3, the 6 `CerbMem` layout rows and `showNonNegativeWithBasis_aux` at C4, `hack`/`to_pure`/`to_pures` at the 2026-09-08 close-out, and the `ctype_aux` compatibility trio `are_compatible_aux`/`are_compatible_params_aux0`/`are_compatible_params0` on 2026-09-10 — not by a hypothesis but by the shared-model change that makes the block total (a path-local assumed-compatible list of tag pairs, C11 §6.2.7#1's device; `docs/2026-09-10_are-compatible-assumed-set-record.md`, upstream-tray draft 37), measured WITHOUT a hypothesis (`CerbCtypeMeasure`), and `many`/`many1` on 2026-09-15 — by the input-indexed restatement (`many_run`/`many1_run` on the input; `docs/2026-09-11_parser-progress-measure-record.md`, upstream-tray draft 43), measured under `CerbParserProgress.Consumes p`; exhaustion = the opaque panicking sentinel | (none left; statements about a future pending worker would need a depth hypothesis, C2 record §9) |

The fuel-measure-cost change (Codex D3 `6ce040f06`, landed 2026-09-08 as a
named structural measure — [record](docs/2026-09-07_fuel-measure-cost-record.md)
§D3 and "Landing improvements") keeps this census and all obligation shapes.
`get_ctx` and `get_ctx_unseq_aux` now instantiate their shared counter with
the proved conservative context CALL-DEPTH bound `CerbCoreMeasure.getCtxBound`
on the expression/list state (`Sum.inl g` / `Sum.inr lemTail`) instead of the
whole-arena `lemSize + 1`. The bound is an ordinary structural definition
(`lean_frontend/CerbCoreMeasure.lean`, imported by the generated
`Core_reduction` via `declare {lean} extra_import`; no `WellFounded.fix`, no
erased rank, no macro — the qualified-helper form lem's FM-free validator was
written to accept): one unit per worker frame plus the maximum over the
possible children (`Ewseq`/`Esseq` left operand, `Ebound`/`Eannot` body,
`Eunseq` operand list; a nonempty list its head and tail). The two
sufficiency cones and the seam's lemmas are within the standard three, and
two kernel-checked equalities relate the previous measures' worker results to
the new wrappers. The six environment measures and their acyclicity
hypotheses are unchanged. No frontend acyclicity invariant is newly claimed.

The gate is RED on a NEW reachable ambient worker and on a stale register
row (both directions), on a same-named obligation whose TYPE is not the
contract's shape, on a measured cone outside the standard three, on a
truncated table or a non-partitioning form count, and — C4 — on a worker
MEASURED under a hypothesis with no row of the reviewed register
`scripts/fuel_hypotheses.txt` naming that exact hypothesis (or a stale or
cite-less register row), on an obligation with a binder that is neither
reserved nor a wrapper argument (audit F-A4), and — P0 2026-09-05 — on an
obligation whose argument correspondence fails (a literal or foreign term on
the worker side, `lemFuel` at the wrong position, arguments swapped on either
side, a lower bound that is not the wrapper's measure, a wrapper that does
not call the worker) or a `_zero` lemma not about the worker at literal 0 on
its own binders, or with a cone outside the standard three; `--selftest`
plants six doctored tables, three doctored registers and 15 compiled decoys
(the table row of each carries its own rejection message). The ambient
panic form: exit 134, `lem: fuel exhausted` on stderr — at a tiny fuel
the FRONT END's pure workers exhaust first (measured at C1: `--fuel 1`
on `tests/minimal/001-return-literal.c` is the panic form).
The classifying lanes (`test_exec.sh` and its csmith wrapper,
`test_gcc_oracle.sh`, `test_ci_sweep.sh`, `test_cn_coverage.sh`,
`tests/mem-scale-probes/measure.sh`) assign the FUEL class to both
forms by the printed message (fail-noisy, never agreement;
reporting-only, no soundness rests on it); the byte-compare lanes
(`test_libc_exec.sh`, `test_multi_tu.sh`, `test_verify.sh`,
`test_immaculate.sh`, `test_libxml2_uri.sh`, `test_bytes.sh`) report
DIFF/FAIL; `test_fuel_plant.sh` runs the real driver at `--fuel 1`
(FUEL) and at the default (MATCH). The harness default 10^8 is
unreachable inside any gate lane's timeout (15-30 s ⇒ ≤ 7×10^6 fuel per
invocation); it is exercised only by `measure.sh` (600 s) and unbounded
single probes. Why a fuel row is an accepted Lean-vs-oracle discrepancy
at all — [USER 2026-09-03]: "fuel is a reasonable exception because we
could always just run the semantics with more fuel." That ruling's
frame is §0/§1 of this document: every Lean-vs-oracle execution
discrepancy is a bug; fuel exhaustion is accepted under class (b) with
the rationale that the bound is a PARAMETER of the port rather than a
fixed semantic limit. General sufficient-fuel completion and observation
agreement are not established; they require explicit domain, failure,
state and runtime assumptions. Increasing fuel does not repair known
non-fuel discrepancies, such as the libc UB-location loss in the
[current CI record](docs/2026-09-06_ci-reporting-results.md).
Fuel STABILITY is delivered for the ND infrastructure only (2026-09-09,
`CerbNDFuelProofs.lean`, record `docs/2026-09-08_nd-fuel-stability-record.md`):
for the three runners `runNDFuel`/`runND1Fuel`/`runND1TraceFuel` and for
`nd_bind`/`liftND`/`liftAction`, if the earlier observation contains no
fuel-exhaustion outcome (`NoFuel`), every larger budget yields the SAME
observation — exact order, multiplicity, failure reasons, states and trace
labels — with operands fixed and worker/observer budgets quantified
independently. Fuel monotonicity for the seven driver-level absorbing
workers (`driver2`, `full_eval_pexpr`, …) and whole-interpreter stability
under a larger AMBIENT fuel captured inside operands are NOT provided: they
depend on how each body consumes exhaustion (lem-lean fuel-parameter record
§5) and need composition proofs. A FUEL row is never counted as agreement.
Records: `docs/2026-09-02_fuel-arc-design.md`,
`docs/2026-09-04_fuel-parameter-C1-record.md`.
**The address-space top is a parameter too** (address-space-bound slice,
2026-09-17; [USER 2026-09-16] *"the semantics should be quantified over such
bounds"*; record `docs/2026-09-17_address-space-bound-part-two-record.md`,
design DESIGN.md §4). The concrete allocator's initial cursor — upstream's
`last_address = 0xFFFFFFFFFFFF` = 281474976710655 — is no longer a literal in
`memory/concrete/impl_mem.ml`/`memory/vip/impl_mem.ml` or a field default in
`CerbMem.lean`: `Mem.initial_mem_state : integer -> mem_state`
(`CerbMem.initialMemState top`) takes it, `initial_driver_state sup top file fs`
and `Cabs_to_ail.desugar sup top …` (the desugar state carries it for the
const-expr mini-run's own driver state) thread it, and each executable
instantiates it ONCE at its entry: `cerberus-lean … --address-space-top N`
(default `Main.lean` `defaultAddressSpaceTop`, THE ONLY address-space numeral
permitted in the repository's Lean text — `check_no_fuel_numerals.sh`'s A1–A3
shapes, plant-tested; 0 or a non-numeral is refused, exit 2) and the fork
oracle's `Driver_ocaml.address_space_top_default` (the fork-only
`--address-space-top N` flag of C3; pristine upstream has no such parameter).
Matched mode passes the flag on neither engine, so every baseline row is
unmoved; the tests choose their own values (`MonadicFailstop.testAddressSpaceTop`,
the speclab gates' `gateAddressSpaceTop`, …) as the ruling allows. **The DOMAIN**
(C4, 2026-09-18 — the pre-merge audit and the consumer's review
`cerberus-sl/docs/2026-09-18_s3-checkpoint-review.md`: their invariant
`MemWF.la_wf` needs `lastAddress ≤ 2^64` and `la_pos` positivity): an address
must fit an LP64 pointer, so `0 < top < 2^64` — `2^(8 · sizeof_pointer)`,
derived on both engines from the implementation's `sizeof_pointer = 8`
(`CerberusImpl.sizeof_pointer`, `ocaml_implementation.ml DefaultImpl`), and
both CLIs refuse anything else — non-decimal spellings included — with the
same sentence (`the address-space top must fit an LP64 pointer: 0 < top <
2^64`; only the exit code is the CLI library's). **The shared grammar** (C5,
re-review R1; [AGENT orchestrator], mirror doctrine): the flag's argument is
"nonempty ASCII decimal digits, `0 < value < 2^64`" on BOTH engines — Lean
validates the digits BEFORE `String.toNat?` (which alone accepts `6_4`), the
fork's converter is digit-only; `18446744073709551615` (= 2^64 − 1) is the
last accepted value on both (LADDER A12 plants P12–P14). A consumer theorem quantifies
`∀ top` under that domain, alongside `∀ fuel`; the driver's SETUP needs
`8 ≤ top` — its errno `int` (4 bytes, align 4) is the first object, and a
smaller top kills out of memory BEFORE `main` runs (the consumer review's
second fact: a small top OOMs on errno before the program's own state exists),
so a startup theorem carries that room hypothesis while a client-facing
result may fold the OOM into its admitted outcomes. The exemplar's theorem IS
that startup theorem in miniature: `FuelExemplar.exemplar_certified_shipped_forall
(fuel : Nat) (top : Int) (h : 8 ≤ top)` — ∀ fuel, ∀ top with room for errno —
by the symbolic errno lemma `errnoAction_active` (C4, 2026-09-18; the errno
allocation and store discharged from `8 ≤ top` by the allocator's arithmetic and
the store's guards, the post-setup state `S₁ top` stated explicitly), axioms the
standard trio. A tiny top is a legitimate instance. The allocator's two kills, stated
exactly: it kills when `cursor − size < 0` (`CerbMem.allocator_below_request_kills`,
remedy 1 in kernel terms) and when the aligned-down candidate address is `≤ 0`
(cursor 4, request 4, align 4 kills with cursor = request; cursor 5 kills too);
an ACTIVE result satisfies `CerbMem.allocator_active_sound` — a NECESSARY
condition on active allocations (aligned, positive, ending at or below the
cursor), not a characterisation of failure.

## 8. How often

Per `scripts/LADDER.md`: Tier A (every commit) = `test_unit.sh` +
the exec baselines + bytes + libc_exec + multi_tu + parse + core +
elab + the uri gate + cn_coverage; Tier B (slice boundaries,
pre-merge) adds the full libxml2 battery, the tests/ci suites,
`test_verify.sh`, `test_immaculate.sh`, the speclab gate lanes, the
gcc second-oracle lane (`test_gcc_oracle.sh --check-baseline` — a
GATE since 2026-09-02 [USER]), the pristine-oracle lane (row 10, widened
2026-09-16, + its chvalid row 12) and the harness plant batteries
(`test_hang_plant.sh`, `test_kill_plant.sh`; `test_renumber_plants.sh`
rides `test_unit.sh`); Tier C are the committed reporting
instruments (`test_ci_sweep.sh`, the csmith full pass, fuzz). Probe
corpora that are neither gates nor scoreboards (`tests/parity-probes`,
`tests/mem-scale-probes` incl. its `micro/` Lake package,
`tests/csmith_findings`) are enumerated in LADDER.md as instruments.
`scripts/release.py` reads executable membership from `scripts/LADDER.md`:
`--mode fast` selects Tier A, and `--mode full` selects A+B. It records source,
artifact and external-input identities, complete lane logs and completion.
A selected subset is not a complete release. Each command runs in a fresh,
owned cgroup v2 subtree; nested caps stay inside it. Timeout, interruption,
surviving descendants or missing final artifacts prevent certification. A
pipe guardian cleans the subtree after supervisor death. This requires a
writable delegated cgroup v2 parent with memory enabled and `cgroup.kill`;
unavailable containment fails before dispatch. The repaired candidate's
[fresh document review](docs/2026-09-06_validation-foundations-document-review.md)
is complete; its corrections require a renewed landing decision because
the user's merge authorization was conditional on no major findings.

## 9. What this does and does not establish

Differential testing samples behaviour; it never proves equivalence.
The claims this validation surface supports are exactly:

1. The measured MATCH/UB_MATCH rows agree under each lane's documented
   observation comparison. The shared decoder covers the former value-only
   batch extractors; narrower reference/model projections remain explicit
   in its matrix. Baseline stability additionally checks recorded exclusions,
   inherited failures, known differences and open bugs. Those categories,
   including UB_DIFF, refusal, fuel and timeout, never count as agreement.
   The [delivery record](docs/2026-09-06_validation-foundations-delivery.md)
   identifies the historical measurements; the repair record identifies the
   candidate's reruns. No csmith campaign was run by this charter.
2. The artifact you tested is the artifact you built: sync,
   lem-sync, staging, and fork-drift gates close the
   "verified-vs-loaded" gaps.
3. The execution path is total, effect-honest, and axiom-clean as a
   Lean artifact (§6) — properties of this port, checked by the
   build, independent of the oracle.
4. **The customer contract (effect retirement, universal form) is
   MET, with the §6 gate as its standing enforcement**: every
   constant elaborated from this repository and from LemLib has axiom
   cone ⊆ `[propext, Classical.choice, Quot.sound]`. This is derived,
   not sampled — zero `axiom` declarations exist anywhere on the
   scanned surface (hand-written, generated, and the LemLib package,
   recursively), and the standing bans exclude the tactic-introduced
   axioms — with the exec-entry probes as end-to-end spot checks.
   `runEffectful` does not exist under any name; reintroducing
   `declare {lean} effectful` is a lem generation-time refusal.
   (Charter: `docs/2026-08-31_effect-retirement-design.md` §1.3.)
5. Fuel is a quantified parameter (§7). Wrapper equations, measured
   sufficiency lemmas and zero-case lemmas establish their stated local
   contracts; the ND runners and `nd_bind`/`liftND`/`liftAction` carry
   kernel-checked completed-observation STABILITY theorems (§7). General
   completion, driver-level propagation and whole-interpreter stability
   remain obligations under explicit hypotheses; these local results do not
   establish universal agreement with oracle-terminating runs.

Sampling has blind spots, and they are closed by dated records, never
quietly: literal-level adversarial inputs (long hexadecimal mantissas, raw
high bytes in string literals and character constants) were untested before
2026-09-11 — `docs/2026-09-11_semantics-audit-repairs-record.md` (findings
3/4 of the whole-project semantics audit; the corpora had one 21-character
hexadecimal literal and no executed non-ASCII literal).

What remains on the trust boundary: the OCaml oracle itself (and
upstream's correctness — the tray is the log of where we believe it is
wrong), the C parser (shared, upstream), the Lem compiler and its Lean
backend (attacked structurally by the shared model + the mirror
discipline + these differentials), the Lean toolchain, and the RUNTIME
seams — not axioms, enumerated and machine-pinned
(`scripts/unsafebaseio_allowlist.txt`, gate-enforced both directions),
each with its ruled classification [USER 2026-08-31] (`CerbGlobal`
left the list 2026-09-05, see below):

- the digest boundary (`CerberusFresh.digest`/`forceIO`/`md5Hex`) —
  kernel-checked opaques with native `@[implemented_by]`/`@[extern]`
  bindings (the C2 conversion; nothing postulated, no proof can
  unfold them);
- (`CerbMem.beqMemValueSafe` — LEFT the boundary 2026-09-19, seam-hygiene
  H3: `BEq MemValue` is the structural, kernel-transparent
  `CerbMem.beqMemValue`; the retired unsafe impl's agreement with it was
  witnessed on 23 pinned pairs (`docs/2026-09-18_seam-hygiene-record.md`
  §5.3), so the supported profile's VF-3 correspondence obligation for this
  row is CLOSED — the row is history;)
- (`CerbGlobal` config/switch surface — LEFT the boundary 2026-09-05:
  the refs were never written, so the eleven reads are now plain `def`s
  of the driver's default configuration, kernel-transparent, with `rfl`
  lemmas (`docs/2026-09-05_cerbglobal-defs-record.md`); the switch
  FEATURE stays class (c) — flags refused, plumbing not wanted ([USER
  2026-09-03] Q7, §3). Step 2 — the configuration as a reader-lifted
  parameter — is a separate slice; `using_concurrency`'s step 2 belongs
  to the concurrency feature branch;)
- `CerberusImpl`'s enum registry — LEFT the boundary 2026-09-20
  (program-data parameters E-A, `docs/2026-09-20_program-data-parameters-
  EA-DA-record.md`): the enum's compatible type is program data (the lem
  reader `enum_definitions`); no registry, no opaque, no `implemented_by`
  remains in `CerberusImpl.lean`. The DIGEST seam stays on this list (its
  D-A route is an open operator decision, record §3.1);
- `CerbUtils` no-op timing/log refs + the `boundedIntegerImpl` stub —
  permanent-declared (OCaml module-shape parity);
- LemLib's `failwithIImpl`/`fuelExhaustedWithImpl` panic bindings
  (runtime behavior of the axiom-free failure/fuel constants).

Separately from the runtime seams, the boundary-opaque census (the axiom
gate's exactly-once population, 16 rows since 2026-09-08) carries two PURE
value-carrying opaques with no native binding: `CerbFuel.fuelExhaustedLoc`
(§7) and `CerbFail.modelFailStopLoc` (C-TF1: the kill location of the seven
memory-model fail-stops; proofs are uniform in the atom, no inequality between
the two atoms is claimed — a transparent `def` alternative is a TODO item).

There is no other declared boundary. The debug no-op stubs (`CerbDebug`,
`CerbUtils`) are off every differential path (the oracle's debug level
is 0 in matched mode); `CerbFS` and concurrency are class (c) as stated
in §3; the fuel bound is class (b)/fuel with its parameter. Known
limitations with owners are in §3 and [TODO.md](TODO.md).
