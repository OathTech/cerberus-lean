# ctl/ — control flow and evaluation-order probes (nolibc mode)

All 15 probes AGREE oracle==Lean==gcc (`results.log`), including the
two-outcome unsequenced set (`ctl_unseq_set_two_calls.c`: exactly {"0 1",
"1 0"} on both engines, 2 traces each). All gate-worthy: exec-minimal
MATCH; return-value probes (`ctl_loop_10k.c`) also gcc-lane AGREE.

| Probe | Corner (ISO C11) | Result |
|---|---|---|
| ctl_shortcircuit.c | && / \|\| sequence points and skipped side effects (6.5.13-14) | AGREE |
| ctl_comma.c | comma sequencing incl. `i = (i++, i)` (6.5.17) | AGREE |
| ctl_switch_edges.c | negative/char cases, default mid-body, fallthrough, nested switch (6.8.4.2) | AGREE |
| ctl_goto_into_block.c | goto into block past a declaration; label namespace (6.8.6.1, 6.2.3) | AGREE |
| ctl_deep_nesting_shadow.c | 12 nested shadowing scopes (6.2.1p4) | AGREE |
| ctl_recursion_frames.c | 500-deep recursion with per-frame arrays | AGREE |
| ctl_loop_10k.c | 10,000-iteration loop under the fuel onset | AGREE 67 |
| ctl_unseq_set_two_calls.c | indeterminately sequenced calls: outcome SET (6.5.2.2p10) | AGREE, 2 traces |
| ctl_unseq_modify_ub.c | `a[i] = i++` UB035 (6.5p2) | AGREE UB035 |
| ctl_compound_literal.c | compound literal pointers, sizeof, member access (6.5.2.5) | AGREE |
| ctl_float_in_condition.c | 0.5 in if/!/&&/?:/while is TRUE (6.8.4.1p2) — NOT the tray-15 _Bool conversion | AGREE (Cerberus correct here) |
| ctl_do_while_continue.c | continue in do-while, break out of nested loops (6.8.5-6) | AGREE |
| ctl_main_fallthrough.c | reaching } of main returns 0 (5.1.2.2.3) | AGREE |
| ctl_bool_arith.c | _Bool promotion in arithmetic (6.3.1.1p2) | AGREE |
| ctl_static_local_recursion.c | block-scope static across recursive activations (6.2.4p3) | AGREE |
