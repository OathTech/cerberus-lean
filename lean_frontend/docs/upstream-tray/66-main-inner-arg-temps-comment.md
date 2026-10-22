# Main uses inner_arg_temps despite the exclusion comment

Draft, 2026-10-22. Report only; no shared-model change or submission.
Checked on the fork based on upstream `b9aeedcb4`, with the upstream
`f10329b44` and `3230aa494` backports. AI provenance: Codex.

In `frontend/model/translation.lem`, the `Decl_function` arm assigns
`is_using_inner_arg_temps` solely from `Global.has_switch
Global.SW_inner_arg_temps`. The adjacent comment (charter reference
`:4331`, now `:4326` after backports) says main is excluded because the
driver allocates argc/argv objects. There is no main-name test in that
condition. The same arm gives main loaded-value parameters and allocates
their objects in its prelude. `driver.lem:1725-1728` supplies values under
`Inner_arg_callconv`, which is consistent with the code.

Reproduce from the repository root after the documented build:

```sh
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --nolibc --switches=inner_arg_temps \
  --pp=core tests/inner_arg_temps/main-args.c
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --nolibc --switches=inner_arg_temps \
  --exec --batch --mode=exhaustive --args "ab cd" \
  tests/inner_arg_temps/main-args.c
```

The Core header has loaded integer/pointer formals for argc/argv; the
fork printer's tray-65 suffix makes their value names visibly distinct
from their object names. The witness checks argc, all argument strings
and the terminating null pointer, and returns `Specified(0)`. Both modes
on both engines agree in the focused witness checks; the new lane keeps
that four-way comparison and independently checks the Core convention.

Classification: misleading comment, not a demonstrated execution defect.
Proposed remedy: update the comment to describe callee allocation for
main too, consistent with the calling convention selected by the driver.
The fork follows the code and makes no semantic exception for main.
This is separate from [tray 64](64-recursive-main-guard-bypassed.md), which
reports the bypassed recursive-main guard. No external duplicate search
has been performed.
