#ifndef MachCompat_h
#define MachCompat_h

#include <mach/mach.h>
#include <stdint.h>

static inline mach_port_t mv_mach_task_self(void) {
    return mach_task_self();
}

// SMC data types — must match kernel driver layout (80 bytes total)
typedef uint8_t SMCBytes_t[32];

typedef struct {
    char     major;
    char     minor;
    char     build;
    char     reserved[1];
    uint16_t release;
} SMCKeyData_vers_t;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
} SMCKeyData_pLimitData_t;

typedef struct {
    uint32_t dataSize;
    uint32_t dataType;
    char     dataAttributes;
} SMCKeyData_keyInfo_t;

typedef struct {
    uint32_t                key;
    SMCKeyData_vers_t       vers;
    SMCKeyData_pLimitData_t pLimitData;
    SMCKeyData_keyInfo_t    keyInfo;
    char                    result;
    char                    status;
    char                    data8;
    uint32_t                data32;
    SMCBytes_t              bytes;
} SMCKeyData_t;

#endif
