# RKNPU2 C/C++ and Python API Integration Reference

## 1. C/C++ API (`librknnrt.so`)
Include header: `<rknn_api.h>`.

### Key Functions:
- `rknn_init(rknn_context *ctx, void *model, uint32_t size, uint32_t flag, rknn_init_extend *extend)`
- `rknn_set_core_mask(rknn_context ctx, rknn_core_mask core_mask)`:
  - `RKNN_NPU_CORE_AUTO`: System auto-schedules.
  - `RKNN_NPU_CORE_0`: Lock to core 0 (2 TOPS).
  - `RKNN_NPU_CORE_1`: Lock to core 1 (2 TOPS).
  - `RKNN_NPU_CORE_2`: Lock to core 2 (2 TOPS).
  - `RKNN_NPU_CORE_0_1_2`: Lock across all 3 cores (6 TOPS).
- `rknn_create_mem_from_fd(...)`: **Zero-Copy DMA-BUF** input integration. Connects directly to RGA output without CPU buffer copying!
- `rknn_run(rknn_context ctx, rknn_run_extend *extend)`
- `rknn_outputs_get(...)` & `rknn_outputs_release(...)`

---

## 2. Python API (`rknn.api` / `rknpu2`)
For quick testing and validation:
```python
from rknnlite.api import RKNNLite

rknn = RKNNLite()
ret = rknn.load_rknn('secondary_ocr_model.rknn')
ret = rknn.init_runtime(core_mask=RKNNLite.NPU_CORE_0)

outputs = rknn.inference(inputs=[cropped_roi_np])
```
