# Armv8.2-A NEON Optimization Patterns for RK3588

## 1. Detection Post-Processing: Fast Bounding-Box Decoding
Detection heads from models like YOLOv10 / YOLO26 output raw bounding boxes: `[x_center, y_center, width, height]`.

### Armv8.2-A NEON Vectorized Box Decode:
```cpp
#include <arm_neon.h>

void neon_box_decode(
    const float* restrict raw_boxes, // [N, 4]
    float* restrict decoded_boxes,   // [N, 4] -> [x1, y1, x2, y2]
    size_t count,
    float scale_w,
    float scale_h)
{
    float32x4_t vhalf = vdupq_n_f32(0.5f);
    float32x4_t vscale = {scale_w, scale_h, scale_w, scale_h};

    for (size_t i = 0; i < count; ++i) {
        // Load [cx, cy, w, h]
        float32x4_t raw = vld1q_f32(raw_boxes + i * 4);
        
        float cx = vgetq_lane_f32(raw, 0);
        float cy = vgetq_lane_f32(raw, 1);
        float w  = vgetq_lane_f32(raw, 2);
        float h  = vgetq_lane_f32(raw, 3);

        float hw = w * 0.5f;
        float hh = h * 0.5f;

        float32x4_t box = {
            (cx - hw) * scale_w,
            (cy - hh) * scale_h,
            (cx + hw) * scale_w,
            (cy + hh) * scale_h
        };
        vst1q_f32(decoded_boxes + i * 4, box);
    }
}
```

---

## 2. Threshold Filtering Without Conditional Branches
Avoid `if (score > threshold)` branches that cause pipeline flushes on in-order Cortex-A55 cores:

```cpp
void neon_score_filter(
    const float* restrict scores,
    const int* restrict class_ids,
    uint32_t* restrict keep_indices,
    size_t count,
    float threshold,
    size_t& kept_count)
{
    float32x4_t vthresh = vdupq_n_f32(threshold);
    kept_count = 0;

    for (size_t i = 0; i < count; i += 4) {
        float32x4_t s = vld1q_f32(scores + i);
        uint32x4_t mask = vcgtq_f32(s, vthresh);

        // Extract mask lanes directly without branch stall
        uint32_t m0 = vgetq_lane_u32(mask, 0);
        uint32_t m1 = vgetq_lane_u32(mask, 1);
        uint32_t m2 = vgetq_lane_u32(mask, 2);
        uint32_t m3 = vgetq_lane_u32(mask, 3);

        if (m0) keep_indices[kept_count++] = i + 0;
        if (m1) keep_indices[kept_count++] = i + 1;
        if (m2) keep_indices[kept_count++] = i + 2;
        if (m3) keep_indices[kept_count++] = i + 3;
    }
}
```
