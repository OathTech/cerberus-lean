# 2026-10-04 — failure-reach register: key groups disambiguated (audit A3)

Branch `fix/failure-reach-key-groups` from mainline `ae48126e5`. Register/instrument
change only; no semantics change.

## Authority

[USER 2026-10-04] "agree 1-4" and "Great, do it as proposed", on the proposal from the
lem re-pin 4e70bb5 pre-merge audit's finding A3
(`docs/2026-10-04_lem-repin-4e70bb5-pre-merge-audit.md`; re-pin record §9): inside
multi-row key groups only, lengthen the message window until the rows' keys differ; seal
formula unchanged; at most those 12 rows resealed.

## The hole (A3)

The register key is file/owner/token/msg/scope, msg = the first 60 whitespace-collapsed
characters after the failure token, matched as a multiset. Six keys had two rows each
(12 rows). Within such a group the check could not tell which row belongs to which site,
so swapping the two `Formatted.convert` `* prec` rows' reach classes (REACHABLE for the
`:874` arm, UNREACHABLE-BY-INVARIANT for `:1063`) together with their seals passed every
check. [AGENT] measured: with the pre-change checker and register the swap gives
`check_failure_reach: OK (233 …)`, rc 0. The same weakness applied to the position check,
which accepted a live class if ANY row of the group had it. Four of the six groups held
byte-identical row pairs (same seal).

## The change [AGENT implementation of the [USER]-approved proposal]

`scripts/check_failure_reach.py`, `disambiguate_key_groups` (called at the end of
`live_sites`):

- sites are grouped on the unchanged 60-char key. A single-site group keeps its key
  unchanged;
- a group of two or more takes the minimum window W > 60 at which every site's
  whitespace-collapsed `following_source` (the 240 source characters the census
  records) differs, and keys each site with its first W characters. W depends only on
  the group's messages, so the result is deterministic;
- fail-closed: if a group's sites are identical even on the full recorded window, it
  raises `check_failure_reach: FAIL — key group cannot be disambiguated even by the full
  recorded message window (fail-closed): <file> <owner> <token> «<msg>» scope=… ×n at
  lines …` (exit nonzero, no OK line).

The seal formula is unchanged: msg is already a sealed column. `--emit` seeding now
prefers a seed row whose msg equals the site's full key before falling back to the
existing order tie-break. This keeps future re-emissions one-to-one inside groups. The
register header and the OK line now describe the key form.

## Re-key

Done with `--emit --seed scripts/failure_reach_register.txt`, then `--reseal`. The diff
covers exactly 12 data rows, and in each one only `msg` and `seal` changed (measured
column-by-column against the pre-change register). The other 221 rows, the column header
and the tally line are byte-identical. The only other change is a three-line edit to the
header comment describing the key. The one-to-one carry-over was checked against the
review fields:

- Decode: `:121` holds the witness and `:151` says "same route as :121".
- `sizeof_ity`: live ARGUMENT/TAIL equal the reviewed NON-TAIL/ARGUMENT and TAIL.
- `convert`: `none => 1` (`:874`) is REACHABLE; `none => /- STD §7.21.6.1#8 -/ 6`
  (`:1063`) is UNREACHABLE-BY-INVARIANT.

| owner | before (60) | after |
|---|---|---|
| decode_character_constant_aux ×2 | `s!"decode_character_constant: invalid char constant ==> {str` | `…{str} (decode.ml:199-200)" e` / `…" /` |
| CerbMem.sizeofCtype_lemFuel ×2 | `"CerbMem.sizeofCtype: the concrete memory model requires a c` | `…complete implementation sizeof I` / `…sizeof F` |
| CerbMem.alignofCtype_lemFuel ×2 | `"CerbMem.alignofCtype: the concrete memory model requires a ` | `…complete implementation alignof I` / `…alignof F` |
| CerbMem.memValueToBytes_lemFuel ×2 | `"CerbMem.memValueToBytes: the concrete memory model requires` | `… a complete implementation sizeof I` / `…sizeof F` |
| CerberusImpl.sizeof_ity ×2 | `"assert false: DefaultImpl.sizeof_ity reached an un-normalis` | `…un-normalised b` / `…un-normalised t` |
| convert ×2 | `"TODO: Formatted.convert, * prec" : Nat) /- TODO -/ \| none =` | `…\| none => 1` / `…\| none => /` |

Known trade-off: a lengthened key now includes source text after the message (e.g. the
next arm, a trailing comment). Editing that text moves the key, which shows up as
STALE+NEW, RED and loud. That is the fail-closed direction, and it was already true of
the 60-char window for short messages.

## Plants

- **P8** (new, in `check_failure_reach.sh --selftest`): swaps the two
  `Formatted.convert` `* prec` rows' reach classes together with their seals. Premise
  asserts: exactly 2 such rows with different reach classes. The plant goes RED with
  SEAL MISMATCH. Vacuity witness ([AGENT], measured): the same swap on the pre-change
  checker and register is green (rc 0).
- **K1** (new witness): synthetic sites through `disambiguate_key_groups`. A two-site
  group whose messages differ only after the 60th character gets the minimal full-length
  keys; a single site is unchanged; two sites identical after whitespace collapse raise
  the FAIL naming the group at lines 1, 2.
- P1–P7 and C1–C7 remain green.

## Gate (row 1, `scripts/test_unit.sh`, rc=0)

The worktree's copied generated trees and driver were stale, so the following were
re-derived before the gate:

- `make lean-prelude-src` and `make clean-prelude-src prelude-src`;
- `lake build cerberus-lean` (capped);
- `dune build backend/driver/main.exe cerberus-lib.install cerberus.install`, then the
  worktree-local install.

Verbatim lines:

```
  PLANT OK   [P8 the two Formatted.convert rows' reach classes swapped WITH their seals (audit A3)] rc=1 ->   SEAL MISMATCH (row edited without --reseal; a class change is a review change): lean_frontend/generated/Formatted.lean convert «"TODO: Formatted.convert, * prec" : Nat) /- TODO -/ | none => 1» position=LET-BOUND reviewed=NON-T
  WITNESS OK   [K1 an undisambiguable key group -> FAIL naming it; a disambiguable one keyed minimally, a single site unchanged] check_failure_reach: FAIL — key group cannot be disambiguated even by the full recorded message window (fail-closed): F.lean d failwithI «"same" rest» scope
check_failure_reach: SELFTEST OK (8 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation, a same-owner reach+seal swap (A3) — 7 classifier witnesses (lem_if arms/condition, lemSeq continuation, controls), the key-group witness K1 and the unplanted register green)
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=172 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
```

(The PLANT/WITNESS lines are cut at the selftest's own 160/230-column display limit.)

LADDER row 11 (which still said "plants five cases", already stale before this change at
7 plants) was corrected in the follow-up commit 44c81506b on this branch ([USER 2026-10-04]
"approve (1) / (2)"), with the current reach counts 172/40/21; the VALIDATION gate row's
counts were corrected to match in the audit-fix commit.

Pre-merge audit (fresh read-only reviewer, range ae48126e5..44c81506b, 2026-10-04): no
correctness or trust findings; all seven checks CONFIRMED-OK (12-row mapping re-derived from
the generated sources; diff scope; key-lengthening logic incl. StopIteration and collision
analysis; --emit seeding; P8/K1 non-vacuous; no fail-open). Documentation findings 1–2 (this
paragraph; the VALIDATION counts) fixed. Informational, not fixed here [AGENT]: the
need/cite/note columns are outside the seal (pre-existing; a text-only swap is not gated),
and the TODO(2) need text cites the stale line :490 (now Formatted.lean:874).
