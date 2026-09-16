-- S0.1(b) companion: must FAIL to elaborate if the candidate holds
-- ("failed to synthesize Inhabited interp_stop"); its failure is the evidence.
import Nondeterminism
set_option autoImplicit false
#synth Inhabited interp_stop
