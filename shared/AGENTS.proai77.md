# ProAI77 + MemryX MX3 Project Rules (Always-On Source)

<!-- proai77-skills:begin — managed by ProAI77 Embedded Skills; source in shared/AGENTS.proai77.md -->

These rules apply to every task in this repository and on the ProAI77 edge device. Detailed workflows live in the specialized skills (`proai77-platform`, `proai77-media-pipeline`, `proai77-perf-optimization`, `mx3-model-selection-proai77`, `mx3-model-compile-proai77`, `mx3-runtime-proai77`, `rk3588-npu-coexecution`, `proai77-remote-viewer`, `proai77-code-review`). Load the matching skill before non-trivial work in its area.

## Platform Facts (ProAI77 / ProAIBox77 V1.6)
- **SoC**: Rockchip **RK3588** (8nm):
  - **CPU**: 8-core DynamIQ big.LITTLE: **4× Cortex-A76 @ 2.4 GHz (Big, OOO)** + **4× Cortex-A55 @ 1.8 GHz (Little, In-Order)**.
  - **Architecture**: **Armv8.2-A AArch64** (`+fp16`, `+dotprod`, `+lse`, `+rcpc`, `+crypto`).
  - **Memory & Storage**: **8 GB DDR4/LPDDR4** (unified bus), **64 GB eMMC**, 32 KB I/D per core, shared L3 / System cache.
  - **Multimedia Accelerators**:
    - **MPP (Media Process Platform)**: Hardware Video Decoder (H.264/H.265/VP9 up to 8K@60, AV1 4K@60, MJPEG) and Encoder (H.264/H.265 up to 8K@30).
    - **RGA (`librga` im2d)**: 2D HW accelerator for zero-copy DMA-BUF crop, resize, letterbox, and color-space conversion (NV12 ↔ RGB888).
    - **GPU**: Arm **Mali-G610 MP4** (OpenGL ES 3.2, OpenCL 2.2, Vulkan 1.2).
    - **Built-in NPU**: **6 TOPS** (3× 2 TOPS cores, `RKNPU2` + `RKLLM`).
- **Primary AI Accelerator**: **MemryX MX3 M.2 2280 Module** (`MX3-2280-M-4`, 4× MX3 chips, PCIe Gen3 x2/x4, up to 24 TFLOPS, ~42M INT8 / ~80M INT4 on-chip weight SRAM, no off-chip DRAM).
- **Power Budget**: **M.2 socket maximum power is capped at 9W (`<= 9000 mW`)**. System power: 12V/3A (36W) USB-PD.
- **I/O & Topology**: Dual 2.5GbE LAN (LAN1/LAN2), 1× HDMI Out, 1× USB 3.0, 1× USB 2.0, 1× Type-C, TF slot, RS232/UART/GPIO.
- **Access**: Remote SSH via key authentication (`ssh proai77` or local bash console).

## Non-Negotiable Rules
1. **Facts First**: Probe the board (`ssh proai77 ...` or local console) before asserting hardware status, link width, kernel module versions, or temperatures. Never guess sysfs paths or library signatures.
2. **Priority: Reliability > Performance > Power > Code Simplicity**.
3. **M.2 9W Power Limit**: The M.2 socket maximum power is 9W. Only select model/frequency combinations with `status == PASS` and **`power_mw <= 9000`** in `proai77-freq-power-matrix.csv`. 9000 mW incorporates the safety margin. Models with `NG` or power > 9000 mW are strictly prohibited.
4. **Frequency Policy**: Pick the lowest qualifying clock among 300 / 400 / 450 / 500 MHz that achieves `fps >= target_fps * 1.5`. Prioritize 300 and 400 MHz; 450/500 MHz requires passing an on-board 10-minute stability & thermal check.
5. **Language Selection by Complexity**:
   - **Python**: Allowed for PoC, tools, single-stream, or medium complexity. Must use GStreamer (`mppvideodec`/`rgaconvert`) or `MxPrepost` to prevent CPU bottleneck.
   - **C++17**: Mandatory for high-throughput, multi-stream, or low-latency production pipelines (`librockchip_mpp` + `librga` DMA-BUF zero-copy + `MxAcclMT`).
   - **Hybrid**: C++ zero-copy data-plane wrapped via `pybind11` for Python orchestration.
6. **Mandatory Hardware Decode/Preprocess (Never Software Decode in Hot Path)**:
   - Always use **MPP** for video decoding and **RGA (`librga` im2d)** for resize/color conversion.
   - Never use CPU FFmpeg soft-decode or `cv2.resize()` in per-frame hot loops.
7. **All Vision Inference Defaults to MemryX MX3**:
   - All standard image/video inference is executed on MX3.
8. **Proactive RK3588 NPU (6 TOPS) Advisory & Bandwidth Check**:
   - Proactively remind and advise the user to use **RK3588 NPU (`RKNPU2` / `RKLLM`)** when:
     1. Running LLM / VLM / Generative AI (`rknn-llm`: Qwen, Llama, Gemma, DeepSeek, MiniCPM-V) requiring system DDR4.
     2. Running audio ASR/TTS or dynamic-length OCR text sequence recognition.
     3. Running secondary ROI models (e.g., LPR, Face ReID) concurrently with a saturated primary MX3 detector to avoid Multi-DFP swapping latency.
     4. Subgraphs (`_pre.onnx`/`_post.onnx`) or models exceed MX3 on-chip SRAM (~42M INT8) or 9W M.2 power.
     5. **Multi-Model Parallel/Cascade Execution**: When running **MX3 + RK3588 NPU** simultaneously, evaluate **shared 8GB DDR4 bus contention** and pipeline synchronization latency.
9. **Arm Coding & big.LITTLE Optimization**:
   - Pin latency-critical threads (MX3 feed/receive, NEON post-processing) to **Cortex-A76 (cores 4–7)**.
   - Pin I/O, network communication, logging to **Cortex-A55 (cores 0–3)**.
   - Align shared multi-threaded structures to 64 bytes (`alignas(64)`) to prevent false sharing.
   - Use Armv8.2-A NEON 128-bit vectors (`+dotprod`, `+fp16`); avoid horizontal reductions in inner loops.
10. **Dual SDK Support**:
    - Support both **Mode A** (Train & Compile on PC/WSL2 -> deploy `.dfp` to ProAI77) and **Mode B** (On-board full `memryx` SDK in `~/mx` venv with ZRAM/Swap guardrails).
11. **Production Quality**: No unbounded queues, pre-allocate frame pools at startup, zero allocations in per-frame hot loops, non-blocking callbacks, finite timeouts on every wait.

<!-- proai77-skills:end -->
