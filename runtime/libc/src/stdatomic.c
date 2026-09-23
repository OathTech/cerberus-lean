#include <__cerb_atomic_flag.h>

/* The pinned memory_order enum is compatible with unsigned int. Use that
   compatible type in these definitions, so serialized Core bodies do not
   depend on a translation-unit-local enum registration. Do not include the
   public enum declaration here: its composite type would reintroduce that
   dependency. Callers still use the compatible public memory_order prototype.

   Public fence functions remain callable through function pointers. The typed
   internal operations perform argument-order validation when executed. */
void atomic_thread_fence(unsigned int order)
{
  __cerbvar_atomic_thread_fence(order);
}

void atomic_signal_fence(unsigned int order)
{
  __cerbvar_atomic_signal_fence(order);
}

_Bool atomic_flag_test_and_set(volatile atomic_flag *object)
{
  return __cerbvar_atomic_exchange_explicit(&object->_Value, 1,
                                           __cerbvar_memory_order_seq_cst);
}

_Bool atomic_flag_test_and_set_explicit(volatile atomic_flag *object,
                                       unsigned int order)
{
  return __cerbvar_atomic_exchange_explicit(&object->_Value, 1, order);
}

void atomic_flag_clear(volatile atomic_flag *object)
{
  __cerbvar_atomic_store_explicit(&object->_Value, 0,
                                 __cerbvar_memory_order_seq_cst);
}

void atomic_flag_clear_explicit(volatile atomic_flag *object, unsigned int order)
{
  __cerbvar_atomic_store_explicit(&object->_Value, 0, order);
}
