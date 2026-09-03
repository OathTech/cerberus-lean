# float/ — floating-point probes (nolibc mode)

Oracle==Lean on every probe (`results.log`). Two ORACLE-SUSPECT classes
and one crash pair surfaced; see the record §F.

| Probe | Corner (ISO C11) | Result | Integration |
|---|---|---|---|
| float_single_precision.c | float must round to single precision (5.2.4.2.2; 6.3.1.5 on store/cast) | oracle==Lean `0 100000000 1 16777217 1 0 1 0`, gcc `1 100000001 0 16777216 0 0 1 1` — ORACLE-SUSPECT F1 (float evaluated/stored as double) | exec MATCH (both engines); gcc-lane pinned DISAGREE pair (triage class: impl float=double) |
| float_int_to_float_rounding.c | int->float rounding at 2^24 (6.3.1.4p2) | oracle==Lean, gcc differs on the float columns — F1 | exec MATCH; gcc-lane pinned pair |
| float_mixed_arith.c | int/float UAC (6.3.1.8) | oracle==Lean, gcc differs on `u + f == 4294967296.0f` — F1 | exec MATCH; gcc-lane pinned pair |
| float_constants.c | hex floats, suffixes, denormals, sizeof (6.4.4.2) | oracle==Lean; gcc differs on sizeof(1.0f)=8 (F1) and sizeof(1.0L)=8 (declared long double impl) | exec MATCH |
| float_long_double_value.c | long double VALUE semantics (impl) | oracle==Lean `1 1 8 1`, gcc `0 0 16 1` — declared impl divergence observer | exec MATCH; gcc-lane pinned pair |
| float_to_int_conv.c | float->int truncation at boundaries, unsigned targets (6.3.1.4p1) | AGREE 3-way | exec MATCH, gate-worthy |
| float_compound_assign_int.c | int lvalue op= floating rhs (6.5.16.2p3) | AGREE 3-way | exec MATCH, gate-worthy |
| float_specials.c | inf/NaN from overflow and inf-inf; -0.0 comparisons (Annex F, 6.5.8/9) | AGREE 3-way | exec MATCH, gate-worthy |
| float_inf_to_int_ub.c | (int)1e300 -> UB017 (6.3.1.4p1) | AGREE UB017 — but Lean `loc: "unknown location"` vs oracle `<5:11--5:19>`: DISCREPANCY D1 | exec UB_MATCH (harness strips loc); the D1 reproducer |
| float_neg_to_unsigned_ub.c | (unsigned)-1.5 -> UB017 (6.3.1.4p1) | AGREE UB017; D1 loc divergence again | exec UB_MATCH; D1 reproducer |
| float_nan_to_int_ub.c | (int)NaN is UB (6.3.1.4p1) | BOTH CRASH: oracle `Z.Overflow` at impl_mem.ml:2554 (exit 125), Lean PANIC CerbFloat.truncToInt (exit 134) — message-level parity; EXCLUDED-KNOWN (tray 15's non-finite crash class) | immaculate crash-pair candidate (both fail-stop) |
