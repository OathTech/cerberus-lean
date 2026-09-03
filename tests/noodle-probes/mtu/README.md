# mtu/ — multi-TU linking probes (nolibc; `test_multi_tu.sh` shape)

Run as: oracle `--nolibc --exec --batch --mode=exhaustive tu1.c tu2.c`;
Lean `--batch tu1.json tu2.json` (per-file cabs-json). `results.log` is
the verbatim three-engine output. All three AGREE oracle==Lean.

| Dir | Corner | Result | Integration |
|---|---|---|---|
| static_dup | same-named internal-linkage object+function in two TUs (6.2.2p3) | AGREE 3-way 102 | tests/multi_tu MATCH, gate-worthy |
| tentative_common | tentative def in tu1 + initialised def in tu2 (6.9p5 UB, no diagnostic required) | oracle==Lean `43 43`; gcc >= 10 link error (-fno-common) | tests/multi_tu MATCH (reporting; gcc rejects) |
| extern_const_fn | extern const array, const fn-pointer table, string literal across TUs | AGREE 3-way 37 | tests/multi_tu MATCH, gate-worthy |
