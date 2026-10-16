# Arm Best-Performance Coding Guidelines (RK3588 / ProAI77)

Derived from official Arm Developer documentation ([developer.arm.com/edge-ai](https://developer.arm.com/edge-ai), [support.arm.com](https://support.arm.com/), *Cortex-A76 Software Optimization Guide*, and *Cortex-A55 Software Optimization Guide*).

---

## 1. Heterogeneous big.LITTLE / DynamIQ Scheduling

The RK3588 features a DynamIQ cluster containing:
- **4× Cortex-A76 Cores (CPUs 4, 5, 6, 7)**: 4-wide out-of-order superscalar, speculative execution, dual-issue NEON pipelines.
- **4× Cortex-A55 Cores (CPUs 0, 1, 2, 3)**: 2-wide in-order execution pipeline, power-efficient, highly sensitive to memory stalls.

### Guidelines:
1. **Thread Affinity Pinning**:
   - **Inference & SIMD Threads**: Must be pinned to Cortex-A76 cores (`CPU 4–7`) using `pthread_setaffinity_np` or `taskset -c 4-7`.
   - **I/O, Network, Video Capture, Logging**: Pin to Cortex-A55 cores (`CPU 0–3`).
2. **Avoid False Sharing Across Clusters**:
   - Shared data structures accessed concurrently by threads running on different clusters must be cache-line aligned and padded to **64 bytes**:
     ```cpp
     struct alignas(64) FrameBufferSlot {
         int frame_id;
         uint64_t timestamp_us;
         // Padding ensuring sizeof is a multiple of 64
         uint8_t padding[48];
     };
     ```
3. **Lock-Free SPSC Ring Buffers**:
   - Use `std::atomic` with explicit `std::memory_order_acquire` and `std::memory_order_release`. On Armv8.2-A, these compile directly into native single-instruction `LDAR` and `STLR` instructions.

---

## 2. Armv8.2-A NEON SIMD Optimization

Both Cortex-A76 and Cortex-A55 on RK3588 implement **Armv8.2-A with Advanced SIMD**:
- `+dotprod` (INT8 dot product instructions `SDOT`, `UDOT`)
- `+fp16` (native half-precision IEEE 754-2008 vector arithmetic)
- `+lse` (Large System Extensions: hardware atomic instructions)

### Vectorization Rules:
1. **Maximize 128-bit Register Utilization**:
   - Always prefer 128-bit `Q` vector registers (`float32x4_t`, `int8x16_t`, `float16x8_t`) over 64-bit `D` registers to double computation per cycle.
2. **Eliminate Cross-Lane Reductions**:
   - Avoid operations like `vaddvq_f32` inside inner loops. Keep independent accumulator lanes vertical, and only reduce across lanes once after the loop finishes:
     ```cpp
     float32x4_t acc0 = vdupq_n_f32(0.0f);
     float32x4_t acc1 = vdupq_n_f32(0.0f);
     for (size_t i = 0; i < count; i += 8) {
         acc0 = vfmaq_f32(acc0, vld1q_f32(a + i), vld1q_f32(b + i));
         acc1 = vfmaq_f32(acc1, vld1q_f32(a + i + 4), vld1q_f32(b + i + 4));
     }
     float32x4_t sum = vaddq_f32(acc0, acc1);
     float total = vaddvq_f32(sum); // Only at the very end!
     ```
3. **Use Dot Product for INT8 Tensors**:
   - Use `vdotq_s32` / `vdotq_u32` for quantized operations. One instruction performs four 8-bit multiply-accumulate operations into a 32-bit destination vector.
4. **Native FP16 Operations**:
   - If using FP16 post-processing, use `float16x8_t` and `vaddq_f16`/`vfmaq_f16` (`-march=armv8.2-a+fp16`).

---

## 3. Branching & Instruction Cache Best Practices

- **Align Subroutine Targets**: Subroutines and tight loop heads should be 32-byte aligned.
- **Predication / Branchless Masks**: In detection post-processing (threshold filtering), avoid conditional branches that cause branch mispredictions on Cortex-A55. Use vector comparison and bitwise masking:
  ```cpp
  uint32x4_t mask = vcgtq_f32(scores, thresh_vec);
  // Branchless filtering
  ```

---

## 4. Compiler Flags for GCC 11 / Clang on RK3588

### Baseline Global Flags:
```cmake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "-O2 -mcpu=cortex-a76.cortex-a55+dotprod+fp16 -moutline-atomics -Wall -Wextra -Werror")
```

### Hot Computational Kernels (NEON post-processing):
```cmake
set_source_files_properties(neon_postprocess.cpp PROPERTIES COMPILE_FLAGS "-O3 -fopt-info-vec-optimized -fopt-info-vec-missed")
```
