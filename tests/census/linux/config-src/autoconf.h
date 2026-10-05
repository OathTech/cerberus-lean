/* Census (P1f-2, 2026-10-04) minimal hand-written kernel config [AGENT].
 * No kernel build, no generated Kconfig output: every CONFIG_ option is
 * unset except the ones listed here, each with its reason. */
#define CONFIG_X86_64 1        /* LP64 target matching Cerberus's default impl */
#define CONFIG_64BIT 1
#define CONFIG_X86 1
#define CONFIG_PAGE_SHIFT 12
#define CONFIG_PGTABLE_LEVELS 5   /* arch/x86/Kconfig:430 default for X86_64; asm/pgtable_types.h needs a value */
#define CONFIG_ARCH_HAS_CACHE_LINE_SIZE 1   /* selected by X86 (arch/x86/Kconfig:76) */
#define CONFIG_TINY_RCU 1   /* kernel/rcu/Kconfig: the RCU flavour for !SMP (this config has no CONFIG_SMP); rcupdate.h #errors without one */
#define CONFIG_HZ 250   /* kernel/Kconfig.hz default (HZ_250); needed to generate timeconst.h */
#define CONFIG_TINY_SRCU 1   /* kernel/rcu/Kconfig: SRCU flavour paired with TINY_RCU; srcu.h #errors without one */
