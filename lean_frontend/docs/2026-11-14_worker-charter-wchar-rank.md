# Worker charter: `wchar_t` leaves the rank normalisation (the D14 regression); the micro probe package retired

Date 2026-11-14. Orchestrator [AGENT]. Branch `fix/wchar-rank`, worktree `worktrees/cerberus-lean-fix/wchar-rank`,
base = mainline `mdd/cerberus-lean` `06afa3ef7`. Roadmap `docs/2026-11-10_roadmap-maintenance-and-reporting.md`: a
silent wrong answer the fork itself introduced is in scope whatever else is parked.

## The defect

`#include <stdint.h>` / `int main(void) { return WCHAR_MAX > 0; }` answers `Specified(0)` on both fork engines and
`Specified(1)` on pristine upstream `c3ff8c53f` and gcc 13 (orchestrator's and two reviewers' runs, 2026-11-10; tray
62's 2026-11-10 section, tray 20's WARNING, TODO's top entry, the note under CONTRACT D14). Cause by reading, not yet
by a run: D14 (`9b15a1f69`, 2026-11-04) made `rank_operand` (`frontend/model/ail/ailTypesAux.lem:474-476`) normalise
every macro integer type through `Implementation.normalise_integerType`; `wchar_t` so takes `int`'s rank while the
model's `wchar_t` keeps an unsigned maximum (`impl_mem.ml`, tray 62: upstream's open inconsistency). The fork gave
an answer where upstream had left the question open.

## Rulings

[USER 2026-11-14] (1) `wchar_t` is taken OUT of the rank normalisation: its rank comparisons return to upstream's
behaviour exactly, defects included; every other macro type keeps D14. Not a refusal, not a repair of `wchar_t`'s
signedness. (2) `tests/mem-scale-probes/micro` is RETIRED (not built since 2026-09-20; no ladder row builds it).

## M1: the fix (shared Lem, both engines by generation)

- First ESTABLISH the cause by a run: build nothing old; instead show on this tree that excluding `Wchar_t` in
  `rank_operand` (and nowhere else) restores pristine's line on the reproducer, and find by probing whether any other
  D14 site (`:294-295` and the rest of `9b15a1f69`'s diff) also changed `wchar_t`'s behaviour. The target is stated
  as an equality: for every program whose only macro-typed operands are `wchar_t` (and `wint_t` if it shares the
  shape: measure), fork = pristine; for the other macro types, fork = the D14 witness's pins, unchanged.
- The vicinity: every limit macro of `<stdint.h>`/`<limits.h>`/`<stddef.h>`/`<wchar.h>` that the shipped headers
  define (`SIZE_MAX`, `PTRDIFF_MIN/MAX`, `INTPTR_*`, `UINTPTR_MAX`, `INTMAX_*`, `UINTMAX_MAX`, `WINT_MIN/MAX`,
  `WCHAR_MIN/MAX`, the exact-width, least and fast families, `SIG_ATOMIC_*` if declared) compared with 0, with each
  other, promoted, converted and in the usual arithmetic conversions against `int`, `unsigned`, `long`, `unsigned
  long`, on fork, pristine and gcc. Any other row where fork differs from BOTH pristine and gcc is a second
  regression: fix it the same way if it is the same mechanism, otherwise stop and report. Rows where pristine is
  wrong and the fork matches gcc are D14's intended fixes: unchanged.
- `scripts/check_macro_type_ranks.sh` gains the `wchar_t` rows pinned to PRISTINE's lines (declared: upstream's
  behaviour kept, gcc's beside) and the limit-macro rows; plants re-derived; total re-pinned.
- The usual: regenerate both targets, the generated delta confined to `AilTypesAux`, manifest single-row edits with
  a dated NOTE (never `--refresh`), failure-reach and fuel-forms as the gates decide (`rank_operand`'s callers are
  measured workers: if a measure proof changes, kernel replay is owed and quoted), moved corpus rows dispositioned
  (the libc lanes: musl uses `wchar_t`), the pristine register.

## M2: retire the micro package

Delete `tests/mem-scale-probes/micro/` and every reference: `scripts/check_pin_sites.sh` (the pin sites become the
lakefile rev, TWO manifests and the README; its plants and count re-derived, selftest green), `scripts/release.py:135-136`,
`scripts/build_provider_smoke.py` (and its hard-coded old lem revision at `:26`: read the pin from the manifest
instead, or delete the script if nothing runs it: say which and why), LADDER's Tier C row if one names it, TODO's
items (closed, not deleted), VALIDATION's coverage sentence, the container-doc wording is the orchestrator's.

## M3: documents

The record `docs/2026-11-14_wchar-rank-record.md`; CONTRACT D14 amended in place (the rule now excludes `wchar_t`,
with the reason; the "known defect" sentence replaced by the correction's date); tray 20: the WARNING replaced by the
corrected patch (dry-run against pristine quoted) and a section saying what the first patch got wrong; tray 62
updated; INDEX rows; TODO's top entry closed; consumer CORRECTION notes for cerberus-caesium and cerberus-sl (pins
from `bb6e8e9f9` up to this landing carry the defect; which programs are affected).

## Process

Focused gates only; never `scripts/release.py` (the orchestrator runs Tier A on M1 and the battery on the tip). All
make/dune through `/home/dev/projects/cerberus-lean-proj/scripts/ce`; lake/lean through `scripts/capped`,
`CERB_MEM_MAX=32G`; the build is under `-DwarningAsError=true` and stays so. Check `/proc/loadavg` (< 12) and
`free -g` before heavy jobs; long runs through the harness's background execution; no poller, watcher or sleep loop;
never `pgrep -f`/`pkill`. No network; `/tmp` unreadable; scratch under the worktree's `.tmp/`, deleted at the end.
Commits per milestone on green gates, provenance tags, never quote the operator, ending with
`Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Nothing pushed; no mainline commit. A blocker: a
committed park record and a stop. Report: hashes, the diff stat, gate lines verbatim, the vicinity table (fork /
pristine / gcc), moved rows, what was not done.
