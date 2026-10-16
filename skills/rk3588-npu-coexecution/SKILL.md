---
name: rk3588-npu-coexecution
description: "Co-executes neural network workloads on ProAI77's built-in Rockchip RK3588 6 TOPS NPU (RKNPU2 / RKLLM) alongside the MemryX MX3 accelerator: deploying LLMs/VLMs with RKLLM, running secondary ROI models (OCR, LPR, Face ReID) to avoid MX3 weight swapping, executing cropped _post.onnx subgraphs, and managing shared DDR4 memory bandwidth contention and pipeline latency. Use when integrating RKNPU2, deploying RKLLM models, or building hybrid MX3 + RK NPU pipelines. 關鍵字: RK3588 NPU, RKNPU, RKLLM, 協同推論, 混合管線, 多模型並行, 記憶體頻寬, 延遲評估, 次要模型, OCR, LLM"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: ProAI77 (RK3588 NPU + MemryX MX3)."
metadata:
  version: "1.0.0"
  domain: "edge-heterogeneous-ai"
  triggers: "rknpu, rkllm, rknn, npu coexecution, hybrid pipeline, llm edge, ocr rknn, secondary model, NPU 協同, 混合推論, 雙AI"
  role: "heterogeneous AI systems engineer"
  scope: "RK3588 NPU runtime integration, RKLLM deployment, MX3 + RKNPU co-execution, DDR4 memory bandwidth budgeting"
  related-skills: "mx3-model-selection-proai77, mx3-runtime-proai77, proai77-media-pipeline, proai77-perf-optimization"
---

# RK3588 NPU Co-Execution & Hybrid AI Pipeline

You are the heterogeneous AI systems engineer for ProAI77. While all standard primary vision detection runs on the MemryX MX3 M.2 accelerator by default, you utilize the **RK3588 built-in 6 TOPS NPU** (3 cores, `RKNPU2` + `RKLLM`) for specialized workloads, secondary ROI cascades, or large language models, while carefully preventing **shared DDR4 memory bus congestion**.

## When to Trigger RK3588 NPU Co-Execution

1. **Large Language Models & Vision-Language Models (`rknn-llm`)**:
   - Models like Qwen2.5/Qwen3, Llama, Gemma, DeepSeek-R1-Distill, MiniCPM-V exceed MX3's ~42M on-chip weight SRAM.
   - Use RKLLM runtime on the NPU to run models using system 8GB DDR4 RAM.
   - **Pattern**: MemryX MX3 detects objects/events at 30 fps → sends keyframe crops or event prompts to RKLLM on RK3588 NPU for natural language reasoning or alert generation.
2. **Audio, Speech, & Dynamic Sequence Models**:
   - Whisper ASR, TTS, or variable-length sequence OCR models.
3. **Secondary ROI Tasks (Avoiding MX3 Context Switching)**:
   - When MX3 is fully loaded running a 4-channel primary detector (e.g. YOLOv10), a secondary model (e.g. LPR character recognition, Face feature embedding) runs on RK3588 NPU.
   - Benefit: Completely avoids MX3 multi-DFP weight-swapping delays.
4. **Subgraphs Cropped by `mx_nc`**:
   - If `mx_nc` autocrop outputs a `_post.onnx` or `_pre.onnx`, it can be compiled to `.rknn` to run on the NPU rather than bogging down Cortex-A76 cores.

## Shared DDR4 Bandwidth & Latency Guidelines

> [!WARNING]
> Unlike the MemryX MX3 (which keeps all weights on-chip), the RK3588 NPU **reads weights and feature maps from system DDR4 memory** on every single inference pass.

1. **DDR4 Bandwidth Budgeting**:
   - Quantize all RKNPU models to **INT8 or INT4** using `rknn-toolkit2` to minimize memory bus transactions.
   - Monitor bus load with `scripts/ddr_bw_probe.sh`. If DDR frequency stays pegged at maximum or frames drop in MPP, reduce the NPU query rate.
2. **Zero-Copy RGA to RKNPU DMA-BUF**:
   - Never copy cropped bounding-box images in CPU RAM. Use `librga` to crop directly into a DMA-BUF and pass the file descriptor to RKNPU via `rknn_create_mem_from_fd`.
3. **Asynchronous Decoupling**:
   - The primary MX3 vision pipeline must NEVER wait synchronously for an NPU result. Use bounded SPSC queues (capacity = 4) between MX3 detection and RKNPU classification.

## Scripts & Diagnostic Tools
- `scripts/rknpu_status.sh`: Probes NPU driver version, core load, and runtime library status.
- References:
  - `references/rknpu2-c-and-python-api.md`: C++ and Python RKNPU2 integration patterns.
  - `references/rkllm-integration.md`: RKLLM model deployment and query flow.
  - `references/mx3-rknpu-hybrid-pipeline.md`: Complete asynchronous multi-model cascade pattern.
