# THE TARGET CORPUS — FROZEN

STATUS: FROZEN AND CANONIZED [USER 2026-08-27 sign-off: "the corpus
as proposed looks good"]. Per the restart plan step 4: ALL CHANGES TO
THIS CORPUS ARE FORBIDDEN WITHOUT USER-LEVEL SIGN-OFF. The freeze is
enforced by the hash manifest scripts/target_corpus.sha256, checked
in-gate (check_proof_size.sh); updating the manifest is itself a
corpus change and carries the same sign-off requirement.

These 15 programs (+ 1 marked alternate, p10alt) define SUCCESS for
the verification framework: each carries a canonical-property theorem
(∀ init, args — see the catechism §II) that today's substrate cannot
prove; the infrastructure build (restart step 5) is judged against
them. Specification + coverage matrix + theorem statements:
docs/2026-08-27_target-corpus.md. Adversarial review + freeze
conditions: docs/2026-08-27_target-corpus-review.md. The normative
doctrine: docs/2026-08-27_design-catechism.md.

P10 = p10_gcd_rec (operator-confirmed recommended form);
p10alt_rsum_rec is the retained ALTERNATE (not part of the frozen 15;
its model is the natural warm-up instance during the build).
