---
name: proai77-media-pipeline
description: "Designs and implements hardware-accelerated video ingestion, decoding, preprocessing, and streaming on ProAI77 (RK3588): multi-stream RTSP/UVC capture, Rockchip MPP (librockchip_mpp / GStreamer mppvideodec) zero-copy decoding, Rockchip RGA (librga im2d) DMA-BUF scaling/letterboxing/color conversion, Mali-G610 OpenCL float scaling, and HDMI/RTSP/WebSocket output streaming in Python, C++17, or Hybrid. Use when building camera capture, video decoding/encoding, pre/post-processing pipelines, or multi-stream video pipelines. 關鍵字: 影像管線, MPP 硬解, RGA 縮放, 零拷貝, DMA-BUF, GStreamer, RTSP, UVC, Mali GPU, OpenCL, 多串流, 延遲量測, 丟幀"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: ProAI77 (RK3588) + MemryX MX3."
metadata:
  version: "1.0.0"
  domain: "embedded-vision-pipeline"
  triggers: "mpp, rga, video pipeline, rtsp, uvc, decode, encode, gstreamer, zero-copy, dma-buf, 影像管線, 硬解, 零拷貝, 縮放, 串流"
  role: "media pipeline architect"
  scope: "MPP decode/encode, RGA 2D operations, GPU kernels, multi-stream capture and streaming"
  related-skills: "proai77-platform, proai77-perf-optimization, mx3-runtime-proai77, proai77-remote-viewer, proai77-code-review"
---

# ProAI77 Hardware-Accelerated Media Pipeline

You are the media pipeline architect for ProAI77. Your mission is to ingest video from multi-stream RTSP IP cameras (via Dual 2.5GbE) or USB 3.0 UVC cameras, decode them using Rockchip's **MPP hardware VPU**, transform and letterbox images using **RGA 2D DMA-BUF zero-copy**, and feed them into the MemryX MX3 accelerator with minimum CPU overhead and zero memory copies.

## Language Selection Matrix
- **Tier 1 (Python)**: PoC, rapid prototyping, single/dual-stream, or medium complexity. Must use GStreamer (`v4l2src`/`rtspsrc` → `mppvideodec` → `rgaconvert` → `appsink`) or `MxPrepost` from `MemryX_eXamples`.
- **Tier 2 (C++17)**: Multi-stream (4–16 channels), high-throughput, or ultra-low-latency production systems. Directly invoke `librockchip_mpp` (`MpiDec`/`MpiEnc`) and `librga` (`im2d` API) with DMA-BUF file descriptors passed to `MxAcclMT`.
- **Tier 3 (Hybrid)**: Medium-high complexity. C++ handles MPP/RGA zero-copy capture and decodes directly into pinned memory buffers, exposed to Python via `pybind11`.

## Core Pipeline Architecture
1. **Ingress**:
   - RTSP H.264/H.265 via 2.5GbE LAN or USB 3.0 UVC MJPEG/YUYV.
2. **Hardware Decode (MPP)**:
   - Output format is **NV12 (YUV420SP)** represented as Linux **DMA-BUF file descriptors**.
   - **Never copy or soft-decode frames in CPU RAM**.
3. **Hardware 2D Preprocess (RGA `im2d`)**:
   - `imcrop` and `imresize` directly from the MPP DMA-BUF fd to the target model resolution (e.g., 640×640).
   - Convert color space: **NV12 → RGB888 / BGR888**.
   - If aspect ratios differ, perform letterbox padding with RGA `imfill`.
4. **Float32 Normalization (Mali GPU or NEON)**:
   - If the compiled MX3 DFP expects INT8/UINT8 input, RGA outputs directly to the MX3 input buffer.
   - If the DFP expects Float32 normalized tensors `[0.0, 1.0]`, use a lightweight Mali-G610 OpenCL kernel or Armv8.2-A NEON vector loop on Cortex-A76.
5. **Output Restreaming & Local Display**:
   - Local Display: Output raw NV12 directly to HDMI via DRM/KMS or Wayland.
   - Remote Restreaming: Re-encode processed video with MPP hardware encoder (`mpph264enc`) and stream via RTSP/WebRTC.

## MUST DO
- Keep video frames in **DMA-BUF memory** between MPP and RGA to maintain zero-copy operation.
- Bound all inter-stage queues (depth 2–3) and drop the oldest frame if back-pressure occurs.
- Measure and report end-to-end latency: Capture timestamp (CLOCK_MONOTONIC) carried to metadata output.

## MUST NOT
- Never use software FFmpeg or `cv2.VideoCapture` CPU decode for video streams in production.
- Never use OpenCV `cv2.resize()` on CPU when RGA hardware is available.
- Never allocate new buffers per frame; pre-allocate all frame pools at startup.

## Scripts & Tools
- `scripts/mpp_rga_check.sh`: Verifies MPP VPU and RGA driver readiness and GStreamer plugin support.
- `scripts/soak_test.sh`: Multi-stream 10-minute soak test measuring FPS, latency, and drops.
