# RKLLM: Large Language Models on ProAI77 (RK3588 6 TOPS NPU)

## 1. Overview
RKLLM allows LLMs and VLMs (0.5B to 7B parameters) to run directly on the RK3588 NPU using the shared 8 GB DDR4 system memory.
- Repository: [airockchip/rknn-llm](https://github.com/airockchip/rknn-llm).
- Supported Models: **Qwen2.5 / Qwen3, Llama 3.2, Gemma 2, MiniCPM-V, DeepSeek-R1-Distill, Janus-Pro-1B**.

---

## 2. MemryX MX3 + RKLLM Edge Multimodal Pattern

```
  [ Camera Video Feed (1080p30) ]
                 |
                 v
     [ Rockchip MPP + RGA ]
                 |
                 v Zero-Copy DMA
     [ MemryX MX3 M.2 Accelerator ]  <--- Runs 30 fps Real-Time Detection (e.g. YOLOv10)
                 |
       Detection Event Triggered!
       (e.g., "Unauthorized intruder detected at loading dock")
                 |
                 v Async Event Queue
     [ RK3588 NPU (RKLLM Runtime) ]   <--- Runs Qwen2.5-1.5B or MiniCPM-V
                 |                         Takes high-res cropped frame + prompt
                 v
     [ Natural Language Scene Report ] -> Transmitted via MQTT / WebSocket to GCS
```

### C++ RKLLM Initialization:
```cpp
#include <rkllm.h>

LLMHandle handle = nullptr;
RKLLMParam param;
param.model_path = "/opt/proai77/models/qwen2.5_1.5b.rkllm";
param.max_context_len = 1024;
param.max_new_tokens = 256;
param.top_p = 0.9f;
param.temperature = 0.7f;

rkllm_init(&handle, &param, llm_callback);
rkllm_run(handle, &input_prompt, nullptr);
```
