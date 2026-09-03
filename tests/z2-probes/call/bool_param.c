/* Z2 probe (CerbCall.lean:36-40 header: "the call-site conv_int range
   conversion is NOT reproduced — an injected integer must fit the parameter
   type"; unenforced). Lean: --call f --call-args 2. Oracle twin: the
   test_verify.sh render_wrapper TU (bool_param_wrapper.c) whose call site
   converts 2 -> _Bool 1 (translation.lem:948-953, std.core conv_int). */
int f(_Bool b) { return b; }
