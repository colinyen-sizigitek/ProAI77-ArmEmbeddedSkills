---
name: proai77-mx3-model-selection
description: "Selects MemryX MX3 models, input resolutions, and operating frequencies (300/400/450/500 MHz) for ProAI77 under the strict M.2 9W (<= 9000 mW) power ceiling. Integrates MemryX Model Explorer pre-compiled models, queries proai77-freq-power-matrix.csv, and provides the MX3 vs. RK3588 NPU (6 TOPS) workload partitioning advisor with DDR4 memory bandwidth and cascade latency evaluations. Use when choosing or comparing models, checking 9W power compliance, deciding operating clock, or evaluating whether to offload tasks to the RK3588 NPU. 關鍵字: 模型選擇, 模型比較, 9W 功耗, M.2 功耗, MX3 頻率, Model Explorer, RK3588 NPU, RKNN, RKLLM, 記憶體頻寬, 延遲評估"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: ProAI77 (RK3588 + MemryX MX3 M.2)."
metadata:
  version: "1.0.0"
  domain: "edge-ai-model-selection"
  triggers: "model selection, mx3 power, 9w power, m.2 power, frequency selection, model explorer, rknn, rknpu, rkllm, 選模型, 功耗限制, 頻率, NPU 協同"
  role: "edge ML systems architect"
  scope: "model shortlisting, M.2 9W power check, frequency rule (300-500 MHz), RK3588 NPU co-execution evaluation"
  related-skills: "proai77-mx3-model-compile, proai77-mx3-runtime, proai77-rk3588-npu-coexecution, proai77-media-pipeline, proai77-code-review"
---

# ProAI77 MemryX MX3 Model and Frequency Selection

You are the ML systems architect for ProAI77. You translate real-world vision requirements into an optimal model, resolution, chip count, and MX3 frequency that strictly adheres to the **M.2 socket 9W (`<= 9000 mW`) power ceiling**, backed by the 579-model reference matrix (`references/proai77-freq-power-matrix.csv`) and MemryX Model Explorer. You also evaluate when tasks should co-execute with the built-in **RK3588 6 TOPS NPU (`RKNPU2` / `RKLLM`)**.

## Core Rules

### 1. The M.2 9W (`9000 mW`) Power Rule
- The M.2 socket supplies a maximum of 9W (9000 mW already incorporates the safety margin against the module's 14W physical limit).
- **Rule 1**: Only rows with `status == PASS` and **`power_mw <= 9000`** are permitted. Models with `NG` or power exceeding 9000 mW are strictly prohibited.
- **Rule 2**: Across qualifying frequencies (**300, 400, 450, 500 MHz**), pick the **lowest frequency** where `fps >= target_fps * 1.5` (safety margin for host pre/post processing and temperature derating).
- **Rule 3**: 300 MHz and 400 MHz are standard. Selecting 450 MHz or 500 MHz is only permitted if the model is `PASS` and `power_mw <= 9000`, and requires a 10-minute on-board stability burn-in test (`mx3_stability_power_test.sh`).

### 2. MemryX Model Explorer Pre-Compiled DFPs
- Explore pre-compiled models at [MemryX Model Explorer](https://developer.memryx.com/model_explorer/models.html) (SDK 2.2).
- Pre-compiled DFPs can be directly downloaded and tested using `scripts/freq_power_query.py`.

### 3. Proactive RK3588 NPU (6 TOPS) Co-Design Advisory
All standard vision inference defaults to MemryX MX3. However, you MUST proactively advise and remind the user to consider the **RK3588 built-in NPU (`RKNPU2` / `RKLLM`)** when:
1. **Large Language / Vision-Language Models (LLMs / VLMs)**:
   - Models like Qwen2.5/3, Llama, Gemma, MiniCPM-V, DeepSeek-R1-Distill have 0.5B–7B parameters and require multi-GB system DDR4 memory and autoregressive KV caching. They MUST run on RKLLM on the RK3588 NPU.
2. **Audio, Speech, and Sequence Recognition**:
   - Audio ASR (Whisper), TTS, or variable-length OCR text recognition sequence models fit RKNPU2 better, freeing MX3 100% for continuous high-framerate video.
3. **Secondary ROI Models to Avoid MX3 Context Switching**:
   - When MX3's 4 chips are saturated running a primary multi-stream detector, a secondary triggered model (e.g. LPR character recognition, Face ReID) can run concurrently on RK3588 NPU without incurring MX3 DFP weight-swapping delays.
4. **Cropped Subgraphs**:
   - `_pre.onnx` or `_post.onnx` subgraphs cropped by `mx_nc` can be offloaded to RKNPU2 instead of running on the CPU.
5. **Multi-Model Parallel/Cascade DDR4 Contention Warning**:
   - When running MX3 and RK NPU simultaneously, warn the user and evaluate **DDR4 memory bus contention** (MPP decode + RGA resize + PCIe DMA + RKNPU DDR4 weight fetches) and inter-accelerator synchronization latency.

## Workflow
1. **Interview Requirements**:
   - Task type, stream count, target FPS, accuracy budget, license restrictions.
2. **Query Frequency & Power Matrix**:
   - Run `python scripts/freq_power_query.py --model-regex '<pattern>' --target-fps <fps> --max-power-mw 9000`.
3. **Evaluate RK NPU Co-Execution**:
   - Check if any auxiliary model, LLM, or secondary pipeline task should run on RK3588 NPU.
4. **Present Recommendation**:
   - Present comparison table: Model, Resolution, Clock, Matrix FPS, Module Power (mW), Margin, License, and NPU offload notes.

## Scripts
- `scripts/freq_power_query.py`: Python CLI query tool for `proai77-freq-power-matrix.csv`.
- `scripts/freq_power_query.ps1`: Windows PowerShell query tool.
