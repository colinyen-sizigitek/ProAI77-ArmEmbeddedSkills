# Rockchip RGA 2D & Mali GPU Zero-Copy Preprocessing Reference

## 1. Rockchip RGA (Raster Graphic Acceleration)
RGA is an independent hardware 2D accelerator in the RK3588 that offloads scaling, rotation, color conversion, and letterboxing from the CPU.

- **Header Files**: `<rga/im2d.h>`, `<rga/RgaApi.h>`.
- **Shared Library**: `librga.so`.
- **Key Capabilities**:
  - Format Conversion: NV12 / YUV420SP → RGB888 / BGR888.
  - Arbitrary Scaling & Letterbox Padding with zero CPU cost.
  - Direct DMA-BUF integration (`wrapbuffer_fd`).

### C++ RGA Zero-Copy Letterbox Example:
```cpp
#include <rga/im2d.h>
#include <rga/RgaApi.h>

// 1. Wrap source decoded frame from MPP DMA-BUF FD
rga_buffer_t src_buf = wrapbuffer_fd(
    src_dma_fd, 
    src_width, 
    src_height, 
    RK_FORMAT_YCbCr_420_SP // NV12
);

// 2. Wrap destination inference buffer (e.g., 640x640 RGB888 in pinned memory)
rga_buffer_t dst_buf = wrapbuffer_fd(
    dst_dma_fd_or_vaddr, 
    640, 
    640, 
    RK_FORMAT_RGB_888
);

// 3. Define letterbox regions
im_rect src_rect = {0, 0, (int)src_width, (int)src_height};
im_rect dst_rect = {pad_x, pad_y, target_w, target_h};

// 4. Fill background with black (letterboxing)
imfill(dst_buf, {0, 0, 640, 640}, 0x000000);

// 5. Execute hardware scaling and color-space conversion in one pass!
IM_STATUS status = improcess(src_buf, dst_buf, {}, src_rect, dst_rect, {}, IM_SYNC);
if (status != IM_STATUS_SUCCESS) {
    // Handle error
}
```

---

## 2. Mali-G610 OpenCL Preprocessing (Float32 Scaling)
When a MemryX DFP model requires Float32 inputs normalized to `[0.0, 1.0]` or standard ImageNet mean/std `(x - mean) / std`, RGA can output `RGB888` bytes, and the **Mali-G610 MP4 GPU** executes a single OpenCL NDRange kernel:

```c
__kernel void normalize_rgb888_to_fp32(
    __global const uchar* restrict src_rgb,
    __global float* restrict dst_tensor,
    const int width,
    const int height)
{
    int gid = get_global_id(0);
    int total_pixels = width * height;
    if (gid >= total_pixels) return;

    // Normalizing directly into NHWC float32 tensor
    dst_tensor[gid * 3 + 0] = (float)src_rgb[gid * 3 + 0] * 0.00392156862f; // / 255.0f
    dst_tensor[gid * 3 + 1] = (float)src_rgb[gid * 3 + 1] * 0.00392156862f;
    dst_tensor[gid * 3 + 2] = (float)src_rgb[gid * 3 + 2] * 0.00392156862f;
}
```
This offloads floating-point conversion completely from Cortex-A76 cores.
