#ifndef MachCompat_h
#define MachCompat_h

#include <mach/mach.h>

static inline mach_port_t mv_mach_task_self(void) {
    return mach_task_self();
}

#endif
