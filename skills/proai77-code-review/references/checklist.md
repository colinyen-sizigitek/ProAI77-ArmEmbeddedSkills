# ProAI77 Code Review Checklist

Review any C++17 or Python PR against this checklist:

## 1. Power & Accelerator Compliance
- [ ] Model and frequency in `proai77-freq-power-matrix.csv` has `status == PASS` and `power_mw <= 9000`.
- [ ] Frequency is set explicitly using `set_operating_frequency()` before streaming.
- [ ] Runtime health query checks `/sys/memx0/power` and `/sys/memx0/temperature` at ≤ 1 Hz.
- [ ] Automatic clock step-down is implemented if power > 8800 mW or temp > 80°C.

## 2. Hardware Video Acceleration (MPP & RGA)
- [ ] Video decoding uses `librockchip_mpp` or GStreamer `mppvideodec`. No CPU FFmpeg software decoding.
- [ ] Frame transformation (resize, letterbox, color-space conversion) uses `librga` `im2d`. No CPU `cv2.resize()`.
- [ ] MPP frames pass to RGA as DMA-BUF file descriptors (`mpp_buffer_get_fd` / `wrapbuffer_fd`). Zero CPU `memcpy`.

## 3. Arm big.LITTLE & NEON Guidelines
- [ ] Compute/post-processing threads are pinned to Cortex-A76 cores (4–7).
- [ ] Network and I/O threads are pinned to Cortex-A55 cores (0–3).
- [ ] Shared inter-thread ring buffer structures are 64-byte aligned (`alignas(64)`).
- [ ] NEON kernels use 128-bit `Q` vector registers (`float32x4_t`, `int8x16_t`, `float16x8_t`).
- [ ] Threshold filtering uses branchless vector masks (`vcgtq_f32`), no conditional branch stalls.
- [ ] Compiled with `-O2 -mcpu=cortex-a76.cortex-a55+dotprod+fp16 -moutline-atomics`.

## 4. Stability & Memory Safety
- [ ] Zero dynamic heap allocations (`malloc`/`new`/`std::vector::push_back`) in the per-frame hot loop.
- [ ] All queues are bounded SPSC/MPMC with drop-oldest policy and drop counters.
- [ ] Every queue pop, lock acquisition, and accelerator read has a finite timeout.
- [ ] Frame timestamps (`CLOCK_MONOTONIC_RAW`) are carried end-to-end for p99 latency accounting.
