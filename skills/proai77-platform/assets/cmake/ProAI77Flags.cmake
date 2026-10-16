# ProAI77 / RK3588 Standard Compiler Flags CMake Module
# Target: 4x Cortex-A76 + 4x Cortex-A55, Armv8.2-A, Mali-G610, MPP, RGA

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Baseline Optimization Flags
# Using -mcpu=cortex-a76.cortex-a55 enables tuning for DynamIQ big.LITTLE
# +dotprod enables INT8 dot product (vdotq_s32)
# +fp16 enables native IEEE 754 half-precision FP16 SIMD
# +lse enables native hardware atomic instructions (LDADD, STADD, SWP)
set(PROAI77_ARCH_FLAGS "-mcpu=cortex-a76.cortex-a55+dotprod+fp16 -moutline-atomics")
set(PROAI77_WARN_FLAGS "-Wall -Wextra -Wformat=2 -Wshadow -Wnon-virtual-dtor -Werror")

# Global flags (safe for entire project)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 ${PROAI77_ARCH_FLAGS} ${PROAI77_WARN_FLAGS} -pthread")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 ${PROAI77_ARCH_FLAGS} -Wall -Wextra -Werror -pthread")

# Hot-loop / Vectorization flags (applied to specific performance-critical translation units)
set(PROAI77_HOT_FLAGS "-O3 -ffp-contract=fast -fopt-info-vec-optimized")

function(proai77_optimize_hot_source TARGET_SOURCE)
    set_source_files_properties(${TARGET_SOURCE} PROPERTIES COMPILE_FLAGS "${PROAI77_HOT_FLAGS}")
endfunction()
