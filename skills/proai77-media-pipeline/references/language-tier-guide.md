# Language Selection Matrix: Python vs. C++17 vs. Hybrid

Choosing the right programming language and architecture on ProAI77 depends on project complexity, stream count, and latency requirements.

---

## Decision Matrix

| Dimension | Tier 1: Python | Tier 2: C++17 | Tier 3: Hybrid (C++ + pybind11) |
|---|---|---|---|
| **Target Use Case** | PoC, Tools, Single/Dual Stream, Quick Prototyping | Multi-Stream (4–16ch), Ultra-Low Latency, Industrial Edge | Complex Logic, Python AI ecosystem + C++ High-Speed I/O |
| **Stream Count** | 1 – 2 streams (1080p30) | 4 – 16 streams (1080p30) | 2 – 8 streams (1080p30) |
| **Video Ingress** | GStreamer `rtspsrc` / `v4l2src` | Native V4L2 / RTSP socket | Native C++ MPP VPU |
| **Hardware Decode** | GStreamer `mppvideodec` | `librockchip_mpp` (MpiDec) | `librockchip_mpp` |
| **2D Preprocess** | GStreamer `rgaconvert` or `MxPrepost` | `librga` (`im2d` DMA-BUF zero-copy) | `librga` (`im2d`) |
| **MemryX API** | `memryx.AsyncAccl` / `MultiStreamAsyncAccl` | `MX::Runtime::MxAcclMT` | `MX::Runtime::MxAcclMT` or `AsyncAccl` |
| **Memory Copies** | Low (if using appsink DMABUF) | **Zero (True DMA-BUF)** | **Zero** in C++ layer |
| **Latency Budget (p99)** | ≤ 80–100 ms | **≤ 40–60 ms** | ≤ 60–75 ms |
| **CPU Utilization** | Moderate (GIL + Python overhead) | **Lowest (Direct big.LITTLE pinning)** | Low-to-Moderate |

---

## Detailed Tier Guidelines

### Tier 1: Python Best Practices
When writing Python applications on ProAI77:
1. **Never use standard CPU OpenCV**:
   ```python
   # PROHIBITED (Slow, uses CPU software FFmpeg decode & CPU resize)
   cap = cv2.VideoCapture("rtsp://...")
   ret, frame = cap.read()
   resized = cv2.resize(frame, (640, 640))
   ```
2. **Always use GStreamer hardware pipeline**:
   ```python
   # RECOMMENDED: Hardware decoded via MPP, resized via RGA
   gst_pipeline = (
       "rtspsrc location=rtsp://192.168.1.100:554/live latency=0 ! "
       "rtph264depay ! h264parse ! mppvideodec ! "
       "rgaconvert ! video/x-raw,format=RGB,width=640,height=640 ! "
       "appsink drop=1 sync=false"
   )
   cap = cv2.VideoCapture(gst_pipeline, cv2.CAP_GSTREAMER)
   ```
3. **MemryX MultiStream in Python**:
   Use `memryx.MultiStreamAsyncAccl` to feed multiple camera feeds into MX3 asynchronously without blocking the main event loop.

---

### Tier 2: C++17 Best Practices
When writing C++17 applications on ProAI77:
1. Decode via `mpp_create` & `mpi->decode_put_packet` / `mpi->decode_get_frame`.
2. Extract the decoded frame's DMA-BUF file descriptor: `mpp_buffer_get_fd(frame)`.
3. Wrap in `rga_buffer_t` and call `imresize` / `imcvtcolor` directly into the pre-allocated MX3 input buffer.
4. Stream using `MxAcclMT::send_input` with finite timeouts.

---

### Tier 3: Hybrid Architecture
Ideal when you need Python's web/cloud connectivity (Flask/FastAPI, MQTT, cloud databases) but cannot afford Python video decoding overhead. C++ handles VPU/RGA and yields pre-processed NumPy arrays (via zero-copy `py::array`) or detection bounding-box dictionaries.
