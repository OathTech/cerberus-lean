# CerbFS path hotfix — the "pathleak" external report (2026-09-28)

Orchestrator [AGENT]. Hotfix branch `fix/cerbfs-plain-paths` off `mdd/cerberus-lean` 5ecc0aa33.

## Attribution

Reported by **Kiran** — gist "cerberus-lean semantics use raw-string path comparison",
<https://gist.github.com/kiranandcode/bcd1e8190d29e238e8becf797c2bb80a> (C witness `0-pathleak2.c`, a reification of
cerberus-lean's frontend output, and a kernel-checked proof over `drive` at `cfc275d`), announced on X as
<https://x.com/kirancodes/status/2104306363195134423>. Thank you: the report is exact, reproducible and correct, and it
came with a proof that every execution of the witness exits 0 with empty stdout. The witness is in the tree verbatim
(`tests/immaculate/libc/zd-fs-pathleak-dot-slash.c`) with this attribution.

[USER 2026-09-28] on the report: "In one way I take this report as kind of positive because this problem is based on
CerbFS, which is a feature that we haven't really tried to clone. The reporter wasn't able to find … any discrepancies in
the core semantics. I wonder if what we should do now is obviously apply a hotfix on a branch and push it. Really the
correct fix here is to much more explicitly define the contract that Cerberus Lean is trying to establish and then for
the features that are well-built, make sure that they're supported. For the ones that are not very well-built, make sure
that they're appropriately rejected." / "bug reports should be attributed with appropriate citations and thanks".

## The defect

`CerbFS` (the in-memory stand-in for the OCaml oracle's SibylFS) used the raw path string as the file key
(`lookupFile st path = st.files.lookup path`). `./secret.txt` and `secret.txt` were therefore different files, so the
witness's access check (refuse exactly `secret.txt`) was bypassed without reading anything. Reproduced on 5ecc0aa33,
verbatim:

    native gcc:     hunter2pl: pathleak2.c:21: serve: Assertion `n == 0' failed.   [exit 134]
    OCaml oracle:   Error {msg: "assert() failure"}                                [exit 1]
    cerberus-lean:  Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}   [exit 0]

This violated CerbFS's own contract (header; VALIDATION.md): serve exactly what SibylFS answers, REFUSE everything else
loudly. It served a wrong answer. No differential corpus used a non-canonical path the model serves, so no lane caught it.

## The fix (fail-closed, not the full model)

The model has no directories and no current-directory state, so the only paths it can answer exactly as SibylFS are
plain, non-empty entry names: no `/`, not `.` or `..`. `plainName` + an inline `if … then failwithI (pathRefusal …) else` guard every SERVED path operation —
`fs_open`, `fs_rename` (both paths), `fs_truncate` (after its negative-length EINVAL, which SibylFS checks first) and
`fs_unlink`; every other path operation already refused. A non-plain path is now a loud `CerbFS refusal (fail-closed
fs-model boundary)` naming the path and the mover (SibylFS path resolution). This is a class-(c) missing feature — an
allowed, declared deviation — not a mirror; the full fix is modelling SibylFS resolution, deferred to the contract work.

After the fix the witness stops with `PANIC … CerbFS refusal (fail-closed fs-model boundary): open of the path
'./secret.txt' — …`. Witnesses in the immaculate lane (baseline note cites the report): `zd-fs-pathleak-dot-slash`
(DIFF | L=CRASH: the intended refusal), `zd-fs-path-subdir-create` (`open("sub/f", O_CREAT)`: oracle ENOENT →
Specified(2); before the fix Lean created a file named `sub/f`; now DIFF | L=CRASH), `zd-fs-path-plain-control`
(plain names — create, write, reopen, read, unlink — MATCH Specified(3)). Failure-reach register: five new rows (one per new refusal site, class (c) REACHABLE, citing this report), resealed; 239 → 244 sites, no existing row or position class changed. No corpus program used a served non-plain path
(grep: only `/dev/zero` opens without O_CREAT, already refused), so no other baseline moves.

## Landing (2026-09-28)

[USER 2026-09-28] verbatim: "Agreed on both, we can waive the audit, merge, and kick off the drafting" — the pre-merge
audit (proposed: a short fresh review of the one commit) was WAIVED by the operator; merge and push authorised.
`mdd/cerberus-lean` 5ecc0aa33 -> this commit, ff-only. Gates on the hotfix tree (orchestrator, verbatim):
`Total: 16 passed, 0 failed`; `check_failure_reach: OK (244 pure failure sites = the 244 register rows exactly …`;
`check_fork_drift: OK — layer 1: 86 … layer 2: 31 …`; immaculate `OK: lane matches the committed baseline …` with the three
new rows; minimal `SUMMARY: total=113 match=90 ub_match=18 … cerb_skip=5 …` `Baseline check: 0 regression(s), 0 improvement(s)`;
multi-TU 2/2 and 7/7; address space 18; libc 12/12; bytes 9 + 5; float 93/93; debug 90; coverage 212; row 13 PASS.
The contract design pass the operator asked for (support what is well built, reject the rest) follows on its own branch.
