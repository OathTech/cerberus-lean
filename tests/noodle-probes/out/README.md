# out/ — verdict/output-surface probes (libc mode)

All four AGREE oracle==Lean (`results.log`).

| Probe | Corner | Result | Integration |
|---|---|---|---|
| out_return_negative.c | main returns -1 | oracle==Lean `Specified(-1)`; gcc 255 (OS truncation, expected) | exec MATCH; gcc lane compares mod 256 |
| out_return_256.c | main returns 256 | oracle==Lean `Specified(256)`; gcc 0 | exec MATCH |
| out_stdout_no_newline.c | proxy stdout without trailing newline | AGREE 3-way "abc"/2 | exec MATCH, gate-worthy |
| out_unspecified_return.c | indeterminate return value | oracle==Lean `Unspecified('signed int')` | exec MATCH; gcc SKIP_UNSPEC |
