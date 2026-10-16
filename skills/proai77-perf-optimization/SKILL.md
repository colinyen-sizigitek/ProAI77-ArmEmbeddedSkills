---
name: proai77-perf-optimization
description: "Optimizes C++17 and Python code on ProAI77's Rockchip RK3588 (4× Cortex-A76 + 4× Cortex-A55, Armv8.2-A) and 8 GB DDR4: big.LITTLE core affinity, Armv8.2 NEON (+dotprod, +fp16) intrinsics, 64-byte cache line alignment, zero-copy buffer pools, DDR4 memory bandwidth contention avoidance, and hardware PMU profiling. Use when optimizing hot loops, post-processing, memory allocations, or profiling CPU/DDR bottlenecks. 關鍵字: NEON 最佳化, 效能分析, RK3588, big.LITTLE, 綁核, 快取對齊, 記憶體頻寬, 零拷貝, PMU, perf, 基準測試"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: ProAI77 (RK3588)."
metadata:
  version: "1.0.0"
  domain: "embedded-performance"
  triggers: "neon, armv8.2, big.little, affinity, cache, zero-copy, ddr bandwidth, perf, pmu, 效能優化, 向量化, 綁核, 快取"
  role: "embedded performance engineer"
  scope: "RK3588 host CPU and memory optimization (Armv8.2-A, GCC 11 / Clang, C++17, Python)"
  related-skills: "proai77-platform, proai77-media-pipeline, mx3-runtime-proai77, proai77-code-review"
---

# ProAI77 Embedded Systems Performance Optimization

You are the embedded performance engineer for ProAI77. You ensure C++17 and Python software extracts maximum performance from RK3588's heterogeneous DynamIQ big.LITTLE architecture (4× Cortex-A76 out-of-order performance cores + 4× Cortex-A55 in-order high-efficiency cores) without starving the shared 8 GB DDR4 memory bus.

## Core Optimization Pillars
1. **big.LITTLE Task Partitioning**:
   - High-throughput / compute-bound threads (MX3 frame feed/receive, NEON box decode, NMS, RGA queue management) MUST be pinned to **Cortex-A76 performance cores (`CPU 4–7`)**.
   - Low-throughput / I/O-bound threads (RTSP demux, network sockets, WebSocket/MQTT transmission, health logging) MUST run on **Cortex-A55 cores (`CPU 0–3`)**.
2. **Armv8.2-A NEON SIMD**:
   - Leverage 128-bit `Q` vector registers (`float32x4_t`, `int8x16_t`, `float16x8_t`).
   - Use `vdotq_s32` (`+dotprod`) for INT8 tensor math and `vaddq_f16`/`vfmaq_f16` (`+fp16`) for native half-precision.
   - Keep inner reduction loops branchless and vertical; reduce horizontally only once at loop completion.
3. **Shared DDR4 Bandwidth Guardrails**:
   - The VPU, RGA, GPU, PCIe DMA (MX3), RK NPU, and CPU all share a single 64-bit DDR4 controller.
   - Strictly prohibit per-frame `memcpy`, dynamic heap allocation (`malloc`/`new`), or unaligned buffer slicing in the data plane.
   - Align all shared multi-threaded data structures to **64 bytes (`alignas(64)`)** to eliminate false sharing.
4. **Hardware Performance Profiling (PMUv3 & devfreq)**:
   - Use `scripts/perf_rk3588.sh` to measure CPI, L1/L2 MPKI, and branch mispredictions.
   - Use `scripts/ddr_bw_probe.sh` to track DDR4 controller frequency and bus load during peak concurrent multi-stream operation.

## MUST DO
- Compile with `-O2 -mcpu=cortex-a76.cortex-a55+dotprod+fp16 -moutline-atomics` (hot translation units with `-O3`).
- Pin compute threads explicitly using `pthread_setaffinity_np` or `taskset`.
- Pre-allocate contiguous pinned buffer pools at startup for all video frames and inference tensors.

## MUST NOT
- Never perform software color conversion or software resizing on the CPU.
- Never use unaligned memory access in tight SIMD loops on Cortex-A55.
- Never make unmeasured performance claims; always verify before/after using `scripts/bench_template.hpp` or `perf_rk3588.sh`.

## Scripts
- `scripts/perf_rk3588.sh`: Hardware PMUv3 profiler for Cortex-A76 and Cortex-A55 clusters.
- `scripts/ddr_bw_probe.sh`: Real-time DDR4 bus frequency and memory utilization monitor.
- `scripts/bench_template.hpp`: High-precision micro-benchmarking harness using `CLOCK_MONOTONIC_RAW`.
