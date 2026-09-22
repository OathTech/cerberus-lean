# Primary-source follow-up during S1 drafting

2026-09-21. These notes amend the pending S0/S3 source map; no new atomic
implementation or ISO correspondence theorem is claimed.

- **Compare-exchange representation:** the old `www/docs/dr_431.htm` snapshot
  stops before the final resolution and must not be used to call DR431 open.
  The current [WG14 issue 0431](https://open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0431.html)
  records it fixed in C17, adopting the April 2015 change in
  [N1906](https://open-std.org/jtc1/sc22/wg14/www/docs/n1906.htm): compare bit
  representations. This is a C correction, not an import of newer C++ rules.
  `MemValue` equality is therefore not a general implementation (signed floating
  zeros, NaNs, padding, unspecified bytes and pointer provenance need separate
  treatment). Current BMC compares symbolic scalar values and explicitly asserts
  one flattened component; it is not a full representation CAS oracle.
- **Child errno:** [N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)
  7.5p3 explicitly gives other threads an indeterminate initial errno value.
  The existing Core comment saying not to store zero is correct; do not apply
  the general thread-storage initialization rule to this exception.
- **C-call ordering:** N1570 6.5.2.2p10 supports indeterminate sequencing with
  caller evaluations. The new protocol tests cover both scheduling orders;
  ordinary Core procedure calls retain their different source-order behavior.
- **Fences:** N1570 7.17.3p6 and pp9–12, 7.17.4.1, plus upstream's
  `sc_fenced_memory_model` and `release_acquire_fenced_relations`, remain the
  basis for the all-SC fence integration. Total SC order is not itself hb.
- **Object/concurrency composition:** [Cerberus-BMC, CAV 2019](https://www.cl.cam.ac.uk/~pes20/cerberus/bmc-cerberus.pdf),
  pp2–3, explicitly identifies unsettled interactions among data races,
  uninitialized memory and padding; its supported object model excludes
  manipulation of byte representations and dynamic allocation. The draft's raw
  byte journal does not, by itself, settle that reference gap. Runtime coverage,
  chosen operational composition and axiomatic-checker domains stay distinct.

The prototype still needs the explicit cross-thread conflict/location and
lifetime composition. The existing sequential `Mem.overlapping` is useful
source evidence, but is not a universal range-intersection API or a complete
C memory-location definition.
