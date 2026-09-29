# The concrete model's function-pointer map is keyed by symbol number alone; in libc mode a user function can take over a libc static's entry

**Affected (for orientation):** `memory/concrete/impl_mem.ml:1206` (`IntMap.add (Z.of_int n) (file_dig, name)
funptrmap` when a function pointer is stored) and `:1044` (`abst` rebuilds the pointer from that one entry, under the
existing FIXME "A function pointer with the same id in different files might exist"). Checked against the fork's oracle
at `mdd/cerberus-lean` 2026-09-29; not re-checked against upstream `master`.

**Status note:** found by a differential bug hunt on our Lean port, which numbers symbols from a single supply and so
does not hit it. This is the FIXME's scenario made concrete.

## What happens

In libc mode the precompiled `libc.co` carries symbol numbers drawn when it was compiled, while the user program's
numbers come from a fresh counter that starts low, so the two ranges overlap. Storing a user function pointer whose
number equals a libc static's replaces that static's funptrmap entry. With `--exec --batch` (libc loaded), a program
that pads its symbol count with 1212 globals so that `g` draws 1868, the number of `__stdout_write`, then stores
`fp = g` and calls `fputs(…, stdout)`:

```
Undefined {ub: "UB041_function_not_compatible", stderr: "", loc: "<295:18--295:35>"}
```

`fputs` loads `stdout->write` (`runtime/libc/src/stdio.c:295`), gets `g`, and the call is reported as UB041. The same
program without the padding line gives `Defined {value: "Specified(1)", stdout: "via fputs\n", …}`. With compatible
signatures the wrong function would be called silently.

## Question / suggestion

Key the map by the full symbol (digest and number), or give libc and the program disjoint number ranges. The witness
program is `tests/immaculate/libc/zd-funptr-libc-conflate.c` in our repository.
