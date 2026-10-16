# ProAI77 Pipeline Architecture, Bounded Queues, and Latency Accounting

## 1. Stage-by-Stage Thread Mapping
To prevent CPU pipeline bubbles and jitter on the big.LITTLE architecture:

```
[ Thread 1: Ingress & Network/V4L2 ]
  - Pinned to: Cortex-A55 (Core 0)
  - Role: Socket recv, RTSP demux, V4L2 DQBUF
  - Queue 1 (Capacity = 3, Drop Oldest)
        |
        v
[ Thread 2: MPP Hardware VPU Decode ]
  - Pinned to: Cortex-A55 (Core 1)
  - Role: Packet feed -> DMA-BUF frame retrieval
  - Queue 2 (Capacity = 2, Drop Oldest)
        |
        v
[ Thread 3: RGA 2D Transform / Color Convert ]
  - Pinned to: Cortex-A76 (Core 4)
  - Role: imcrop, imresize, letterbox into pinned host memory
  - Queue 3 (Capacity = 2, Drop Oldest)
        |
        v
[ Thread 4: MemryX MX3 Driver Feed / Receive ]
  - Pinned to: Cortex-A76 (Core 5)
  - Role: send_input, receive_output (MxAcclMT / AsyncAccl)
  - Queue 4 (Capacity = 2, Drop Oldest)
        |
        v
[ Thread 5: NEON v8.2 Post-Processing ]
  - Pinned to: Cortex-A76 (Core 6)
  - Role: Box decode, thresholding, top-K selection
  - Queue 5 (Capacity = 4)
        |
        v
[ Thread 6: Output & Streaming / REST / WebSocket ]
  - Pinned to: Cortex-A55 (Core 2)
  - Role: JSON/Binary packing, WebSocket broadcast, HDMI DRM
```

---

## 2. Bounded SPSC Queue Policy
- **Drop-Oldest Strategy**: If the pipeline experiences temporary downstream back-pressure (e.g. transient network burst or complex post-processing), the ingress stage drops the oldest unconsumed frame.
- **Timestamp Tracking**: Every frame carries its initial `CLOCK_MONOTONIC_RAW` ingress timestamp. Every drop is tracked in a dedicated atomic counter and reported in system health metrics.

---

## 3. End-to-End Latency Instrumentation
Fixed-bucket histogram buckets: `<20ms`, `20-40ms`, `40-60ms`, `60-80ms`, `>80ms`.
Target on ProAI77: **p99 latency ≤ 60 ms** (from camera arrival to metadata transmitted).
