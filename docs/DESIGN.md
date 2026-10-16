# ProAI77 System Design Specification

## 1. Architecture Overview
The ProAI77 Edge AI Platform integrates the Rockchip RK3588 heterogeneous SoC with the MemryX Cascade 100M (4× MX3) M.2 AI accelerator module.

### Hardware Block Diagram & Data Flow
```
   +----------------------------------------------------------------------------------------+
   |                                 ProAI77 (RK3588 SoC)                                   |
   |                                                                                        |
   |  [Video In: 2.5GbE / USB 3.0]                                                          |
   |         |                                                                              |
   |         v (Compressed H.264/H.265/MJPEG)                                               |
   |  +---------------+        Zero-Copy DMA-BUF        +-----------------+                 |
   |  | Rockchip MPP  | ------------------------------> |  Rockchip RGA   |                 |
   |  | Hardware VPU  |   (NV12 / YUV420 Decoded)       |   (im2d API)    |                 |
   |  +---------------+                                 +-----------------+                 |
   |                                                              |                         |
   |                                             Letterbox / Crop / NV12->RGB888 / Resize   |
   |                                                              v                         |
   |                                                    +-------------------+               |
   |                                                    | Shared 8GB DDR4   | <---------+   |
   |                                                    | Pinned Ring Buffer|           |   |
   |                                                    +-------------------+           |   |
   |                                                              |                     |   |
   |                             +--------------------------------+                     |   |
   |                             | PCIe Gen3 DMA                                        |   |
   |                             v                                                      |   |
   |            +---------------------------------+                                     |   |
   |            |   MemryX MX3 M.2 (4x Chips)     |                                     |   |
   |            |   Primary Vision Inference      |                                     |   |
   |            |   42M Weights on Chip / <= 9W   |                                     |   |
   |            +---------------------------------+                                     |   |
   |                             |                                                      |   |
   |                             v Detections (Tensors)                                 |   |
   |  +-------------------------------------------------------------+                  |   |
   |  |                     CPU Clusters                            |                  |   |
   |  |  [Cortex-A76 Big Cores (4-7)]: Hot NEON v8.2 Post-Process   |                  |   |
   |  |  [Cortex-A55 Little (0-3)]: I/O, Network, System Control    |                  |   |
   |  +-------------------------------------------------------------+                  |   |
   |         |                                                                          |   |
   |         +-----------------------+                                                  |   |
   |         | ROI / Secondary Task  v (Triggered)                                      |   |
   |         |          +----------------------------+                                  |   |
   |         |          | RK3588 NPU (6 TOPS)        | ---------------------------------+   |
   |         |          | RKNPU2 (OCR/LPR/Audio)     | Fetches Weights & Activations        |
   |         |          | RKLLM (LLM/VLM / >80M par) | (Carefully Budget DDR4 Bandwidth)    |
   |         |          +----------------------------+                                      |
   |         v                                                                              |
   |  [Video & Metadata Output]                                                             |
   |  -> HDMI Local Display (DRM/KMS / Wayland)                                             |
   |  -> MPP H.264/H.265 HW Encode -> RTSP / WebRTC Remote Restream                         |
   |  -> WebSocket / MQTT / REST Metadata                                                   |
   +----------------------------------------------------------------------------------------+
```

---

## 2. Shared Memory Architecture & DDR4 Bandwidth Budgeting
In RK3588, the VPU (MPP), 2D Engine (RGA), Mali GPU, PCIe Controller (connecting MX3), RK NPU, and CPU all access the same **unified 64-bit LPDDR4/DDR4 memory controller** (~25–34 GB/s peak theoretical bandwidth).

### Bandwidth Budget Breakdown:
1. **MPP Multi-Stream Decode (e.g. 4× 1080p30 H.264)**:
   - Compressed read: ~20 MB/s.
   - Raw NV12 write: ~1.2 GB/s.
2. **RGA 2D Preprocess (NV12 -> RGB888 640×640)**:
   - NV12 read + RGB write: ~1.5 GB/s.
3. **PCIe Gen3 DMA to MemryX MX3**:
   - 4 streams @ 640×640×3 (FP32 or INT8): ~150–500 MB/s.
4. **MemryX Advantage**:
   - **Zero Weight Fetching**: All weights reside inside the 4 MX3 chips' on-chip SRAM. MX3 does **NOT** consume DDR4 bandwidth for weights.
5. **RK3588 NPU Co-Execution Warning**:
   - Unlike MX3, the RK NPU **reads both model weights and intermediate feature maps from system DDR4** on every inference pass.
   - Running a heavy 2B/7B LLM or large CNN on the RK NPU simultaneously with 8-stream video decoding will cause DDR4 bus saturation, increasing video frame-drop and latency jitter.
   - **Guideline**: When co-executing with RKNPU, keep NPU models quantized (INT8/INT4), use zero-copy `rknn_create_mem_from_fd`, and monitor DDR frequency via `/sys/class/devfreq/dmc/`.

---

## 3. M.2 9W Power Ceiling & Frequency Rule
The M.2 2280 M-Key socket on ProAI77 supplies 3.3V power, rated for **up to 9W (`9000 mW`)** sustained:
1. **Filtering Criterion**:
   - Only rows with `status == PASS` and `power_mw <= 9000` in `proai77-freq-power-matrix.csv` are legal.
2. **Clock Selection**:
   - Evaluate across **300 MHz, 400 MHz, 450 MHz, and 500 MHz**.
   - Pick the **lowest clock** that achieves `fps >= target_fps * 1.5`.
   - Clocks at 450 MHz or 500 MHz must be validated with a 10-minute on-board stability burn-in test (`mx3_stability_power_test.sh`). If transient power spikes exceed 9000 mW, the system must throttle or drop down to 400 MHz.

---

## 4. Multi-Stream Video I/O & Latency Targets
- **Sustained FPS**: 30 fps per active channel (tested over 10 minutes).
- **Latency Budget**:
  - RTSP Ingress & MPP Decode: ≤ 15 ms
  - RGA Crop/Resize & Zero-Copy DMA: ≤ 5 ms
  - MX3 PCIe Transfer & Inference: ≤ 25 ms
  - Post-Process (NEON Box Decode / Top-K): ≤ 5 ms
  - Output Packing & Transmission: ≤ 10 ms
  - **Total ProAI77 Internal Latency (Ingress to Output): p99 ≤ 60 ms**.
