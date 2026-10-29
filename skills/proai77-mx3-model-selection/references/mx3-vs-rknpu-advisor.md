# MX3 vs. RK3588 NPU Co-Design Advisor

A structured guide for deciding whether a task belongs on the **MemryX MX3 M.2 Accelerator** or the **Rockchip RK3588 6 TOPS NPU (`RKNPU2` / `RKLLM`)**, and how to safely co-execute them.

---

## 1. Technical Comparison

| Feature | MemryX MX3 M.2 (4× MX3 Chips) | Rockchip RK3588 Built-In NPU |
|---|---|---|
| **Architecture** | Spatial Dataflow, On-Chip Weight Memory | Vector / Matrix Tensor Processing Core |
| **Compute Power** | Up to **24 TFLOPS** (@ 1 GHz) | **6 TOPS** (INT4/INT8/INT16/FP16/BF16) |
| **Weight Storage** | **40M–42M INT8** (~80M INT4) on-chip SRAM | **Shares 8 GB System DDR4 RAM** |
| **DRAM Bandwidth Usage**| **Zero for model weights** (activations only) | **Continuous DDR4 weight & feature fetching** |
| **Power Constraint** | Hard cap: **M.2 socket ≤ 9W** (`9000 mW`) | Integrated in SoC thermal/power envelope |
| **Software Stack** | MemryX SDK (`mx_nc`, `memx-accl`, Python `memryx`) | `rknn-toolkit2` / `rknpu2` / `rknn-llm` |
| **Best-Fit Tasks** | High-throughput, fixed-resolution vision streams (YOLO) | LLMs/VLMs, audio, OCR, dynamic length, secondary ROI |

---

## 2. Decision Tree

```
                       [ Incoming AI Workload ]
                                  |
            Is it an LLM / VLM (e.g. Qwen, Llama, MiniCPM)?
             /                                          \
          YES                                            NO
           |                                              |
     [ RK3588 NPU ]                     Is it Audio / Speech / Dynamic OCR?
  (Use rknn-llm with                              /              \
  system 8GB DDR4 RAM)                          YES               NO
                                                 |                 |
                                          [ RK3588 NPU ]    Is MX3 4-chip saturated with
                                         (Use rknn-toolkit2) primary multi-stream vision?
                                                              /             \
                                                            YES              NO
                                                             |                |
                                                      Is this task a    [ MemryX MX3 ]
                                                      secondary ROI?     (Primary Vision
                                                        /         \      Inference Engine)
                                                      YES          NO
                                                       |            |
                                                [ RK3588 NPU ]  [ Re-evaluate
                                                (Avoids MX3      stream count
                                                DFP swapping)    or model size]
```

---

## 3. Co-Execution Rules (MX3 + RK3588 NPU)

When running **MX3 (Primary Detector)** and **RK3588 NPU (Secondary Classifier/OCR or LLM)** concurrently:
1. **DDR4 Bandwidth Budgeting**:
   - Keep RKNPU models strictly quantized (INT8/INT4) to minimize memory bus transactions.
   - Use `rknn_create_mem_from_fd` to share decoded RGA DMA-BUF buffers directly with RKNPU without CPU `memcpy`.
2. **Decoupled Asynchronous Queues**:
   - The MX3 primary detection pipeline must NEVER block waiting for the RK NPU. Put detected ROIs into an asynchronous bounded queue (capacity 4). If the NPU cannot keep up, drop the oldest ROI.
3. **Continuous Bus Load Monitoring**:
   - Periodically monitor `/sys/class/devfreq/dmc/cur_freq` to ensure the DDR controller is not throttling.
