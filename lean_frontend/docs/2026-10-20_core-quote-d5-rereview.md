# Re-review of feature/core-quote after D5 (f69504b2a)

Reviewer: independent (Claude), [AGENT 2026-10-20, reviewer]. Worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-feature/core-quote`
treated as read-only: no edit, no lake/dune/make, no git state change. Only the
already-built binaries were run, on scratch inputs under
`/home/dev/projects/cerberus-lean-proj/.tmp/review-d5/`.

## Scope and what I ran

Read, in order: both CLAUDE.md files; the branch record (D2b and D5 sections in
full); the 2026-10-20 pre-merge audit; `git show db86bf7b6` (all 16 files);
the consumer note diff; VALIDATION.md entries on the guard, Z-67 and the Core
quotation boundary; `scripts/check_runtime_resolution.sh` (whole file);
`test/CoreQuote/CoreQuoteRoundTrip.py` (diff + libc branch),
`test/CoreQuote/CoreQuoteCompare.lean` (whole), `test/Unit/CoreQuoteTest.lean`
(diff); `CerbLocation.lean:231-300`; `Main.lean:596-640, 786-840, 1160-1262,
1826-1925`; `util/cerb_location.ml:512-523`; `util/cerb_runtime.ml:36-78`;
`frontend/model/core_run.lem:772-790`; upstream-tray draft 58 + INDEX;
`scripts/LADDER.md` rows 1 and 13; `git log --oneline 4644721ba..f69504b2a`
(two commits: D5 and an INDEX reorder).

Commands run (verbatim; scripts are in the scratch directory):

```sh
mkdir -p /home/dev/projects/cerberus-lean-proj/.tmp/review-d5
# served-divergence probe: four #line plants (dot, nodot, abs, core), both engines,
# relative runtime, from the worktree root
bash /home/dev/projects/cerberus-lean-proj/.tmp/review-d5/plant.sh
# quotation-path probes: absolute-label json, absolute runtime, divergent plant, no --libc-tu
bash /home/dev/projects/cerberus-lean-proj/.tmp/review-d5/quote.sh
# the oracle classifier itself, compiled against the built cerb_util.cmxa (as the D5 witness does)
cd /home/dev/projects/cerberus-lean-proj/.tmp/review-d5 && \
  /home/dev/projects/cerberus-lean-proj/scripts/ce ocamlfind ocamlopt -package unix,str,lem,pprint,yojson -linkpkg \
  -I "$WT/_build/default/util/.cerb_util.objs/byte" -I "$WT/_build/default/util/.cerb_util.objs/native" \
  -I "$WT/_build/default/util" "$WT/_build/default/util/cerb_util.cmxa" location.ml -o location
# oracle control under an ABSOLUTE runtime for the absolute-label plant
env -u CERB_INSTALL_PREFIX scripts/ce _build/default/backend/driver/main.exe \
  --runtime="$PWD/_build/install/default" --exec --batch --nolibc .tmp/review-d5/abs.c
python3 scripts/release.py --list          # B13 = ./scripts/test_unit.sh --core-quote-libc; 19 A rows, 24 B rows
cmp lean_frontend/CerbLocation.lean lean_frontend/generated/CerbLocation.lean   # synced
cmp lean_frontend/Main.lean lean_frontend/generated/Main.lean                   # synced
/usr/bin/time --version                   # GNU time 1.9 prints to stdout: probe matches here
```

Probe results, verbatim (`plant.sh`; each plant is `#line 1 "<DIR>/plant.h"`,
`int f(int x) { return x + 1; }`, `#line 10 "<name>.c"`, `int main(void) { return f(2147483647); }`;
both engines at `--runtime=_build/install/default` from the worktree root):

```text
== dot      (DIR = ./_build/install/default/lib/cerberus-lib/runtime/libc/include)
oracle: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<2:10--2:15>"}
port  : rc=1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}
== nodot    (DIR = _build/install/default/lib/cerberus-lib/runtime/libc/include)
oracle: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}
port  : rc=1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}
== abs      (DIR = <worktree>/_build/install/default/lib/cerberus-lib/runtime/libc/include)
oracle: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<2:10--2:15>"}
port  : rc=1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}
== core     (DIR = ./_build/install/default/lib/cerberus-lib/runtime/libcore)
oracle: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<2:10--2:15>"}
port  : rc=1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<11:10--11:23>"}
```

Oracle classifier (`location` probe, runtime `_build/install/default`):
`./_build/.../builtins.h -> false`, `_build/.../builtins.h -> true`,
`<worktree>/_build/.../builtins.h -> false`. Under an absolute runtime the
`abs` plant gives `loc: "<11:10--11:23>"` on the oracle (agreement).

Quotation-path probes (`quote.sh`, all from the worktree root):

```text
canonical quote (committed fixture, relative runtime): rc=0   Canon001.lean 393625 bytes, 0 absolute labels
Q1 absolute-label json, relative runtime:               rc=0   Abs001.lean   400305 bytes, 86 absolute labels
Q2 committed fixture, absolute runtime:                 rc=0   AbsRt001.lean 439633 bytes, 568 absolute labels
Q3 quote dot.json (divergent class):                    rc=0
P  --quote-core --libc without --libc-tu:               rc=1 "cerberus-lean: --libc requires at least one --libc-tu"; no output file
```

## Findings

### P2-1. The admitted divergence class is stated too narrowly, and no run in the battery shows a served verdict differing

Files: `lean_frontend/Main.lean:618-623`; `lean_frontend/CerbLocation.lean:274-282`;
`lean_frontend/VALIDATION.md:541-550` and `:627-636`; `lean_frontend/README.md:220-223`;
consumer note `:52-58`; `docs/upstream-tray/58-relative-runtime-library-location.md:1-6, 44-50`;
`scripts/check_runtime_resolution.sh:163-218`.

Claim. Every D5 entry describes the re-opened class as "cpp's `./`-prefixed
header positions under `--runtime=_build/install/default`". The class the
resolved guard admits is every stored label whose directory `realPath`s to a
runtime library directory but is not literally
`<runtime-as-given>/lib/cerberus-lib/runtime/{libc/include,libcore,libcore/impls}`:
absolute labels under the relative runtime (`abs`), `./`/relative labels under an
absolute runtime, `#line` aliases, symlinked spellings, and `libcore` as much as
`libc/include` (`core`). On all of them the driver serves a different UB
location than the oracle (table above), and all of them are quotable (Q3,
exit 0). The D5 witness pins only classifier outputs (false/true/true) and an
execution control on a program with no UB; the sentence "served UB-location
selection can differ" rests on reading `core_eval.lem:602` / `core_run.lem:477,782`,
not on a run.

Evidence. `plant.sh` output above: `dot`, `abs`, `core` diverge; `nodot`
agrees. The oracle probe confirms the rule is literal equality with the
runtime argument as spelled (`cerb_runtime.ml:49` `wrap \`SPECIFIED path`,
`cerb_location.ml:512-523`). Tray 58's title and remedy section speak only of
cpp's `./`.

Fix (documentation + witness, no design change):
1. In the five doc sites and tray 58, state the class as "any label spelling
   that resolves to a runtime library directory but differs literally from the
   oracle's `<runtime>/<dir>` key", with `./` under the relative convention as
   the instance every canonical export carries.
2. Append the `dot`/`nodot` pair to `check_runtime_resolution.sh` as a
   served-divergence pin: oracle `<2:10--2:15>` vs port `<11:10--11:23>` for
   `dot`, both `<11:10--11:23>` for `nodot`. It is eight lines of C, runs in
   under a second, goes red if either engine's rule moves, and the existing
   `ignore-runtime`/`refuse-all` plants already cover it.
3. For the operator: the project rule for overriding an upstream mistake is
   "mirrored in both engines and registered as a fork-ahead delta". D5 leaves
   the override one-sided (port resolved, fork OCaml literal) under the
   [USER 2026-10-19] D2b ruling. If that ruling was about the port's guard only
   and not about leaving the fork oracle divergent, mirroring the resolved
   rule into `util/cerb_location.ml` (tray 58 already drafts the remedy) would
   restore zero behavioural discrepancy on accepted inputs and make the
   witness a plain agreement check. This is a question, not a demand.

### P3-1. The driver does not enforce the quotation convention it documents: non-portable literals are emitted silently

Files: `lean_frontend/Main.lean:624-637` (guard refuses only unresolvable or
foreign directories); `lean_frontend/CerbQuote.lean:10-28, 1102` (refusals are
NaN and comparator provenance only); consumer note `:36-50`; README `:214-223`.

Claim. Q1 and Q2 show that a cabs-json exported under an absolute runtime, or
the committed fixture quoted under an absolute `--runtime`, both quote with
exit 0 and produce literals with 86 and 568 machine-absolute labels. The
literal is still a faithful quotation (the round-trip relation does not depend
on spelling), so this is portability, not soundness. But the only guard is the
test's `absolute-position` census (`CoreQuoteCompare.lean:60`), which a consumer
who runs only the driver never sees. The docs are honest ("not promises of
invariance"), so this is not an overclaim; it is a fail-open seam by the
project's own standard.

Fix. Either refuse on the quotation path when any emitted `Pos` filename is
absolute (the printer already visits every `Pos`; name the convention in the
message, as `refuseLibraryLocations` does), or add one sentence to README and
the consumer note saying the driver does not check portability and the
`core-quote-test` census is the only check.

### P3-2. The linked population is one trivial TU; three of the nine comparator-vector positions are asserted by reading only

Files: `test/CoreQuote/CoreQuoteRoundTrip.py:220-224` (linked input is fixture
001 only); `test/Unit/CoreQuoteTest.lean:1170-1176` (vector L,S,S,I,L,E,L,N,N);
record `:1395-1410`; `tests/fixtures/001-return-literal/source.c` (`return 42`).

Claim. Fixture 001 has no enum, no loop and no global, so `enumDefs`,
`loop_attributes1` and `visible_objects_env0` are `.empty` on both the libc and
the TU side; the check "skips only a literal `.empty`" there. The claim that
"TU S/N wins when present" over libc's `.empty` is not exercised by any linked
input. The L-over-S/O half (tagDefs/funs/funinfo) is exercised.

Fix. Add one linked input that has an enum, a loop and a file-scope object
(any such corpus file), accepting roughly +150 s in row 13; or state in the
record and consumer note that those three positions are unexercised in linked
mode.

### P3-3. "Differential lanes use absolute spellings where both agree" is true by absence, not by spelling

Files: `scripts/libc_prep.sh:200-203` (metadata exported with
`--runtime=_build/install/default`); `scripts/common.sh:340`
(`CERB_INSTALL_PREFIX` absolute); VALIDATION `:546`, consumer note `:55`.

Claim. The lanes run the port on relative-spelled metadata under an absolute
prefix: the port classifies those header positions as library, the oracle never
sees those files. Agreement holds because the metadata positions carry only
declarations (no UB can be located there), not because the spellings match.

Fix. Reword to "the lanes' user TUs are exported and run under the same
absolute spelling; the libc metadata positions carry no behaviour-bearing
code".

### P3-4. Minor notes

- `--quote-core --libc` without `--libc-tu` exits 1 with a message lacking the
  `refused —` prefix (`Main.lean`, pre-existing), while the new library-only
  refusal beside it exits 2 with the prefix. Harmonise.
- The new witness compiles against dune-internal paths
  (`_build/default/util/.cerb_util.objs/{byte,native}`) and runs `lake env lean
  --run` three times under `--selftest` (twice under driver plants where the
  classifier half is irrelevant). It fails loudly, so acceptable; the plant
  runs could skip the classifier half under `CERB_LEAN_BIN_OVERRIDE`.
- GNU time detection reads `--version` from stdout; GNU time 1.9 (this box)
  prints there, 1.7 prints to stderr. The failure is named, which is the
  intended behaviour, but a note in the consumer note would save a clone an
  hour.

## Checked, no finding

- P2-2 is closed in substance. `CoreQuoteCompare.original` "linked" mode
  rebuilds library-first with the library's returned supply, conses each TU,
  then `link`/`convert_file`, mirroring `Main.lean:1163-1205`; no printer code
  participates. The comparator vector is pinned per field. B13 is in the ladder
  (`release.py --list`) and `--libc` without `--module` runs both the standalone
  and the linked case by default (`RoundTrip.py:208-224`), elaborating the
  literal to a `.olean` and importing it into the checker, then
  `leanchecker LinkedLiteral`. The consumer interface `--libc --module --input`
  takes the linked path. The no-user-TU refusal is tested there (exit 2, no
  output).
- The new witness is a real two-sided pin: it goes red if the oracle starts
  classifying `./` (OCLASS), if the port's suffix test changes (LCLASS), if the
  no-dot control fails (OCONTROL), or if the fixture's 154 labels change
  spelling. Its execution control is caught by both selftest plants. I
  reproduced the oracle half independently (false/true).
- The `convention()` control: the alias symlink is unlinked in `finally` (F11
  fix), both modes run alias byte-equality and the wrong-cwd refusal.
- Hand-written `CerbLocation.lean`/`Main.lean` are byte-identical to their
  `generated/` copies.
- P3-1/P3-2/P3-3 of the audit are dispositioned: rebase map at record `:3-24`
  with the dangling snapshot explained; GNU time probed by name; the indexing
  exemption is declared in VALIDATION §3 with its invariants and the
  `LEAN_ABORT_ON_PANIC=1` recipe, and F12 explains why the wrapper route was
  dropped.
- No claim in the record, consumer note, VALIDATION or LADDER overstates what
  is checked, beyond the class wording in P2-1. The consumer note separates
  D4's full A+B from D5's Tier A + row 13 explicitly.

## Verdict

READY WITH NOTES. D5 closes P2-2 properly and closes P2-1 exactly as the audit
asked, but the audit's ask was too narrow: the driver admits and quotes a wider
class of oracle-divergent inputs than the five doc sites describe, and the
battery contains no run in which the served verdict actually differs. The
remedy is wording in known places plus an eight-line addition to an existing
witness; neither touches the model, the printer, the pins or any baseline, so
it can land before or immediately after the merge at the operator's choice.
Whether the one-sided override should instead be mirrored into the fork oracle
is a rule question for the operator (P2-1 item 3).

## Residual uncertainty

- I could not run row 1 or row 13 (lake is off-limits here); the pass/fail of
  the test machinery rests on the battery running in the worktree. I verified
  the machinery by reading and by driving the binaries.
- I did not re-derive the comparator fold beyond checking `original` against
  `Main.lean`; the L/S/O/E/N provenance reasoning is the audit's and the
  record's.
- The F12 indexing invariants and the `leanchecker` replays were not re-run.
- The `abs` plant under an absolute runtime agrees; I did not probe symlinked
  runtime spellings, which the realPath guard also accepts.
