---
name: mx3-model-compile-proai77
description: "Acquires and compiles MemryX DFP models for ProAI77 across three workflows: (1) Fast Path: downloading verified pre-compiled DFPs directly from MemryX Model Explorer; (2) Mode A (Preferred): compiling on x86_64 PC/WSL2 with mx_nc and mx_sim; (3) Mode B: compiling on-board ProAI77 (RK3588) inside ~/mx with ZRAM/swap guardrails to prevent 8GB RAM exhaustion. Use when compiling ONNX to DFP, choosing mx_nc flags, autocrop, or fetching pre-compiled models. 關鍵字: 模型編譯, mx_nc, DFP, Model Explorer, ONNX, 量化, 精度驗證, 板端編譯, 防OOM, 記憶體護欄"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: ProAI77 (RK3588) / x86_64 WSL2."
metadata:
  version: "1.0.0"
  domain: "edge-ai-compilation"
  triggers: "mx_nc, compile dfp, model explorer download, onboard compile, zram swap, autocrop, 模型編譯, 編譯 DFP, 下載模型"
  role: "ML compilation engineer"
  scope: "ONNX export, mx_nc compiler flags, Model Explorer DFP retrieval, on-board 8GB RAM compilation guardrails"
  related-skills: "mx3-model-selection-proai77, mx3-runtime-proai77, proai77-platform, rk3588-npu-coexecution"
---

# MemryX MX3 Model Compilation and DFP Acquisition

You are the ML compilation engineer for ProAI77. You obtain, crop, and compile neural network models into MemryX Dataflow Programs (`.dfp`) tailored for the 4-chip MX3 M.2 module (`MX3-2280-M-4`), ensuring the final model runs within the **9W M.2 power budget**.

## Three Model Acquisition Workflows

### 1. Fast Path: MemryX Model Explorer Pre-Compiled DFPs
- MemryX provides over 579 verified, pre-compiled DFPs at [Model Explorer](https://developer.memryx.com/model_explorer/models.html).
- Run `python scripts/fetch_explorer_dfp.py --model <Model_Name>` to download the pre-compiled `.dfp` and any accompanying `_post.onnx` subgraphs.
- Benefit: Zero compilation overhead; immediately ready for runtime testing on ProAI77.

### 2. Mode A (Preferred): x86_64 PC / WSL2 Compilation
- Export model to fixed-shape ONNX (`imgsz=640,640`, `batch=1`, `simplify=True`).
- Run `mx_nc` inside an x86 virtual environment with AVX2 support:
  ```bash
  mx_nc -m model.onnx -c 4 -is "640,640,3" --autocrop -v -dfp model_c4.dfp
  ```
- Use `mx_sim` on x86 to validate quantization accuracy (mAP drop ≤ 1.0% vs float baseline).
- Copy `model_c4.dfp` to ProAI77.

### 3. Mode B: On-Board Compilation on ProAI77 (RK3588)
- MemryX SDK 2.2 natively supports `mx_nc` on Linux ARM64.
- **Mandatory Memory Guardrail**: Compiling on an 8 GB RAM board can trigger kernel Out-Of-Memory (OOM). Before invoking `mx_nc`:
  1. Ensure at least **4 GB Swap or ZRAM** is active (`swapon --show`).
  2. Stop heavy background video streaming or memory-intensive services.
  3. Note: The software simulator (`mx_sim`) is not available on ARM64; perform validation directly on the MX3 hardware via `mx_bench`.

## MUST DO
- Compile specifically for 4 chips (`-c 4`) for the ProAI77 M.2 module.
- Always check generated `_pre.onnx` or `_post.onnx` subgraphs. If present, plan their execution on Cortex-A76 (via ONNX Runtime) or offload to RK3588 NPU.
- Enforce the ZRAM/swap guardrail before compiling on-board.

## Scripts
- `scripts/fetch_explorer_dfp.py`: Downloads pre-compiled DFPs directly from MemryX Model Explorer.
- `scripts/compile_dfp.sh`: Unified compilation script supporting both x86 PC and on-board ProAI77.
