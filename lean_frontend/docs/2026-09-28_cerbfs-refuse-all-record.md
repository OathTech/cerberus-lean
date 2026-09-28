# Contract D2 — the filesystem is refused in full (2026-09-28)

Orchestrator [AGENT]. Branch `arc/contract-enforcement` off `mdd/cerberus-lean` a7dc36e2f. Part of enforcing the draft
contract (`docs/contract-draft-20260928:lean_frontend/CONTRACT.md`), which lands only after the enforcement it describes
([USER 2026-09-28] "We can't merge the contract doc, it's not correct yet!! We actually have to enforce it!").

[USER 2026-09-28] decision D2: "refuse FS for now, this seems safer".

## Change

`CerbFS.lean`: all 25 filesystem OPERATIONS (`fs_open` … `fs_closedir`) are unconditional feature-attributed refusals
(`CerbFS refusal (fail-closed fs-model boundary): <op and arguments> — the filesystem is not modelled by this port …`).
The pure parts the driver references stay (state type, `fs_initial_state`, stat accessors, `fs_string_of_error`,
`string_of_fs_state`). Standard output and error are unaffected: `driver.lem` `driver_fs_step` routes `write` on fds 1/2
to the stdout/stderr records and never calls CerbFS (fd 0 is the driver's own error). The served implementation, incl.
the 2026-09-28 plain-name guard, remains in history at a7dc36e2f.

Why refuse rather than keep the served subset: that subset was believed to match SibylFS op by op, and an external
report (`docs/2026-09-28_cerbfs-path-hotfix-record.md`) showed one answer was wrong; the upstream corpora never
exercised this surface, so a served subset is only as trustworthy as adversarial testing nobody has done.

## Registers and baselines

- Failure-reach register: the 41 CerbFS rows of the served model replaced by 25 rows (one unconditional refusal per
  operation, class (c) REACHABLE), resealed; 244 -> 228 sites, no other row changed.
- Immaculate lane, re-pinned by hand with a dated note: `zd-f1-truncate-negative-length` (was MATCH Specified(1)),
  `zd-z2f01-lseek-whence` (was MATCH Specified(9)), `zd-fs-path-plain-control` (was MATCH Specified(3)) -> DIFF | L=CRASH,
  pinned refusals like the two pathleak rows.
- Tier A: row 1 16/16; minimal, multi-TU, tray, address space, libc (12/12 — no libc lane program uses files), bytes,
  float, debug, coverage all at baseline; row 13 PASS. Tier B: full ladder below.

## Full-ladder gate (orchestrator, 2026-09-28)

`scripts/release.py --mode full` on `835c230b1`, clean tree (0 tracked
changes), run 07:16:34Z–08:47:16Z. Verdict lines, verbatim:

```
full: passed; 40/40 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
=== RELEASE EXIT=0 2026-09-28T08:47:16Z ===
```

The "incomplete" line is the standard release-certification caveat: the
reporting, adoption and audit exits sit outside the ladder.
