# Rockchip MPP Hardware Video Decode and Encode Reference

## 1. Overview of Rockchip MPP (Media Process Platform)
Rockchip MPP is the official hardware multimedia framework for RK3588, providing unified C/C++ APIs to control the hardware VPU (Video Processing Unit).

- **Header Files**: `<rockchip/rk_mpi.h>`, `<rockchip/mpp_buffer.h>`, `<rockchip/mpp_frame.h>`, `<rockchip/mpp_packet.h>`.
- **Shared Library**: `librockchip_mpp.so`.
- **Supported Decode Formats**: H.264 (AVC), H.265 (HEVC), VP9, AV1, MJPEG up to 8K@60fps.
- **Supported Encode Formats**: H.264, H.265 up to 8K@30fps.

---

## 2. Zero-Copy Hardware Decoding Workflow (C++)

```cpp
#include <rockchip/rk_mpi.h>
#include <rockchip/mpp_buffer.h>

// 1. Initialize MPP Context & MPI Interface
MppCtx ctx = nullptr;
MppApi *mpi = nullptr;
mpp_create(&ctx, &mpi);
mpp_init(ctx, MPP_CTX_DEC, MPP_VIDEO_CodingAVC); // or MPP_VIDEO_CodingHEVC

// 2. Configure Split Mode (for stream demuxing)
MppParam param = nullptr;
RK_U32 need_split = 1;
param = &need_split;
mpi->control(ctx, MPP_DEC_SET_PARSER_SPLIT_MODE, param);

// 3. Feeding Encoded Packet
MppPacket packet = nullptr;
mpp_packet_init(&packet, stream_data, stream_size);
mpi->decode_put_packet(ctx, packet);

// 4. Retrieving Decoded Frame & DMA-BUF File Descriptor
MppFrame frame = nullptr;
MPP_RET ret = mpi->decode_get_frame(ctx, &frame);
if (ret == MPP_OK && frame) {
    if (!mpp_frame_get_info_change(frame)) {
        MppBuffer buf = mpp_frame_get_buffer(frame);
        int dma_fd = mpp_buffer_get_fd(buf); // <--- Zero-copy DMA-BUF FD!
        uint32_t width = mpp_frame_get_width(frame);
        uint32_t height = mpp_frame_get_height(frame);
        
        // Pass dma_fd directly to RGA for resizing & color conversion!
    }
    mpp_frame_deinit(&frame);
}
mpp_packet_deinit(&packet);
```

---

## 3. GStreamer MPP Pipelines (Python & C++)

### RTSP Ingestion Pipeline:
```bash
gst-launch-1.0 rtspsrc location=rtsp://192.168.1.100:554/live latency=0 ! \
    rtph264depay ! h264parse ! mppvideodec ! \
    rgaconvert ! video/x-raw,format=RGB,width=640,height=640 ! \
    appsink
```

### Hardware Re-Encoding & Streaming (RTSP Restreaming):
```bash
gst-launch-1.0 appsrc ! video/x-raw,format=NV12,width=1920,height=1080 ! \
    mpph264enc bps=4000000 rc_mode=cbr ! \
    h264parse ! rtph264pay ! udpsink host=192.168.1.50 port=5004
```
