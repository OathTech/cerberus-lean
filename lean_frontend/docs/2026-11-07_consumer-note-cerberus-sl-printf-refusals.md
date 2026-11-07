# Consumer note for cerberus-sl: the formatter refuses what it does not implement; `*`, `%jd`, `snprintf`'s length and the `0`/`#` flags follow the standard (2026-11-07)

From: the `fix/printf-refusals` worker [AGENT]. Record `docs/2026-11-07_printf-refusals-record.md`; witness
`scripts/check_printf_refusals.sh` (ladder row 1); trays 26, 16 (fixed), 68, 69, 70 (new), 27 (kept); contract D16.

What moved, in one paragraph: the SHARED `formatted.lem` (the Core builtins `printf`/`vprintf`/`vsnprintf` run it on
both engines) now parses the full C17 7.21.6.1#7-#8 conversion syntax and REFUSES — a pure `error`, one attributed text
per class, oracle `internal error: <text>` + uncaught `Failure` (exit 125), Lean `failwithI` abort (exit 134), the
texts byte-identical — every floating conversion other than `%f`/`%lf` and the `L` modifier (`%e %E %g %G %a %A %F`,
`%Lf`, …: upstream reported them as `Invalid_format` UB), `%n`, `%ls`, `%lc` (upstream crashed) and a `*` argument
whose value is unspecified; it reads a `*` field width or precision from an `int` argument (7.21.6.1#5), tests the
`j`/`z`/`t` modifiers through the implementation's alias table on both sides (7.21.6.1#7), returns `snprintf`'s
would-be length, formats at `n = 0` and passes a format's UB verdict through (7.21.6.5#2-#3), pads the `0` flag's zeros
after the sign / `0x` base and spaces an infinity, keeps `#`'s decimal point on `%f` (7.21.6.1#6), and treats a non-`l`
modifier with `%s` as UB158 (7.21.6.1#7). The libc C text is untouched (no `libc.core` re-pin). No proof module changed.

What this means for a pin of the fork at or after this branch:

- Any program whose format string reaches `%e`, `%E`, `%g`, `%G`, `%a`, `%A`, `%F`, `%L…`, `%n`, `%ls`, `%lc` or `%*%` (a `%%`
  with a `*` width: UB, upstream crashed) now
  REFUSES on both engines (a loud stop, never a verdict) where it was reported as `Undefined {ub: "Invalid_format…"}`
  or died with upstream's `TODO`/`WIP` text. A recorded UB verdict or crash of such a program becomes the refusal;
  the text names the conversion (`Formatted.convert: refused - the %e conversion is not implemented (C17 7.21.6.1#8: …)
  … (upstream-tray report 68, 2026-11-07)`). The refusal is envelope-less at this delivery (a legacy stop under the
  outcome protocol, as D11/D12/D13): the generic decoder cannot attribute it as REFUSAL; the migration map names the
  mover.
- `printf("%*d", w, x)`, `%.*s`, `%-*d`, `%*.*f` and every other `*` form now PRINT (gcc's text) where they crashed; a
  negative width is the `-` flag and the magnitude, a negative precision is omitted; a non-`int` width argument is
  `UB153b`, a missing one `UB153a`.
- `%jd`/`%ju`/`%ji`/`%jo`/`%jx`/`%jX` of `intmax_t`/`uintmax_t` (and `long`), `%zd` of a `long`, `%tu` of an `unsigned long`
  now print where they were `UB153b_illtyped_argument_for_format`; `%jd` of a `long long` and `%zd` of an `int` stay UB153b.
- `snprintf`/`vsnprintf` return the would-be length: `snprintf(b, 4, "%d", 123456)` returns 6 (was 3),
  `snprintf(NULL, 0, …)` the length (was 0), `snprintf(b, 1, …)` the length (was 0); a format UB inside `snprintf` is now
  the same `Undefined` verdict `printf` gives (was an `internal error: TODO: snprintf()` crash). Three `tests/libc_exec`
  rows moved to gcc's values (026, 027, 028).
- `%05d` of -5 prints `-0005` (was `000-5`), `%#05x` of 255 `0x0ff` (was `00xff`), `%010.3f` of -3.14159 `-00003.142`,
  `%010f` of an infinity `       inf` (was `0000000inf`), `%#.0f` of 3.0 `3.` (was `3`).
- Unchanged, upstream's judgement (pinned, filed): `%x`/`%X`/`%o`/`%u` with an `int` argument and `%d` with an
  `unsigned`/`long` stay `UB153b` (tray 27); `+` on an unsigned conversion and a modifier other than `l` on `%c` stay the
  `DUMMY` verdicts; `%5%` prints a padded `%`; the space flag on `%u` prints a space; `%s` of a non-pointer still crashes
  (UB input). `%f` of a NaN stays the Lean refusal; `%f` of `-0.0` prints `0.000000` on both engines (the negation's
  doing, not the formatter's; TODO names it).
- In libc mode a format UB is located inside the library's `vfprintf` on the oracle and at `<unknown location>` on the
  Lean engine (N4, as since D15); the witness projects the location on its UB rows.

Nothing to re-pin on the consumer's side unless a recorded expectation falls in the moved classes above; the fork-drift
manifest's `formatted` rows carry the delta (leaves when upstream absorbs the fixes; the refusals stay until the
conversions are implemented — queued in TODO with a size).
