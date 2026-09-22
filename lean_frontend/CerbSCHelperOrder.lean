import Sc_runtime

namespace CerbSCHelperOrder

theorem memop_annotation operation (predecessors : sc_predecessors) annotation :
    sc_internal_annotation (SC_memop operation) predecessors annotation =
      sc_before_annotation (sc_promote predecessors) annotation := rfl

theorem runtime_annotation operation (predecessors : sc_predecessors) annotation :
    sc_internal_annotation (SC_runtime operation) predecessors annotation =
      sc_before_annotation (sc_promote predecessors) annotation := rfl

theorem access_annotation order polarity (predecessors : sc_predecessors) annotation :
    sc_internal_annotation (SC_access order polarity) predecessors annotation = annotation := rfl

theorem no_owner aid observed (state : sc_state) (h : state.sc_current_request = none) :
    sc_record_effect aid observed state = none := by simp only [sc_record_effect, h]

end CerbSCHelperOrder
