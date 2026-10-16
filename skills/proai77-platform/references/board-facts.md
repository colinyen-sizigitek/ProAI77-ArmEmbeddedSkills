# ProAI77 Board Facts and Hardware Probing Reference

## 1. System-on-Chip (SoC) Facts
- **Processor**: Rockchip RK3588 (8nm HKMG process).
- **Core Configuration**:
  - **Cluster 0**: 4× Arm Cortex-A55 @ up to 1.8 GHz (`cpu0`, `cpu1`, `cpu2`, `cpu3`), in-order dual-issue, 32KB L1I/D per core, 128KB private L2 per core.
  - **Cluster 1**: 2× Arm Cortex-A76 @ up to 2.4 GHz (`cpu4`, `cpu5`), out-of-order 4-wide superscalar, 64KB L1I/D, 512KB private L2 per core.
  - **Cluster 2**: 2× Arm Cortex-A76 @ up to 2.4 GHz (`cpu6`, `cpu7`), out-of-order 4-wide superscalar, 64KB L1I/D, 512KB private L2 per core.
- **Shared Cache**: 3 MB unified L3 cache across all 8 cores.
- **ISA Extensions**: Armv8.2-A AArch64 with NEON, `dotprod`, `fp16`, `lse`, `rcpc`, and `crypto`.

## 2. Memory & Bus Topology
- **DDR4/LPDDR4**: 8 GB unified memory on 64-bit multi-channel memory bus.
- **DMC / Memory Frequency**: Controlled via devfreq: `/sys/class/devfreq/dmc/`. Max frequency ~2112 MHz (LPDDR4X) / 1600 MHz (DDR4).
- **eMMC**: 64 GB high-speed onboard storage on `/dev/mmcblk0`.

## 3. Hardware Accelerators
- **Video Processing Unit (MPP)**:
  - Hardware decoder supports H.264, H.265 (HEVC), VP9, AVS2 up to 8K@60fps; AV1 up to 4K@60fps; MJPEG up to 4K@60fps.
  - Hardware encoder supports H.264 and H.265 up to 8K@30fps.
  - Driver node: `/dev/mpp_service`, runtime version info at `/proc/mpp_service/version`.
- **2D Hardware Graphics Accelerator (RGA)**:
  - RGA3 / RGA2 multi-core unit (`/dev/rga`).
  - Supports zero-copy scaling, clipping, format conversion (YUV420SP/NV12 ↔ RGB888/BGR888), alpha blending, and rotation.
  - Direct DMA-BUF integration via `librga` `im2d` API.
- **GPU**:
  - Arm Mali-G610 MP4 (4-core shader), supports OpenCL 2.2, OpenGL ES 3.2, Vulkan 1.2.
- **NPU**:
  - 3-core neural processing unit totaling 6 TOPS (`/dev/rknpu`). Supports INT4/INT8/INT16/FP16. Managed via `rknn-toolkit2` and `rknn-llm`.

## 4. MemryX MX3 M.2 AI Accelerator
- **Module**: MemryX MX3 M.2 2280 M-Key Module (`MX3-2280-M-4`).
- **IC Count**: 4× MemryX MX3 Edge AI Accelerators.
- **Interface**: PCIe Gen3 (2×2-lanes or 4-lane, up to 4 GB/s bandwidth).
- **On-Chip Weights**: Up to 42M 8-bit weight parameters (~80M 4-bit) stored in on-chip SRAM. No external DRAM required.
- **Power Cap**: M.2 socket supplies maximum **9W (`<= 9000 mW`)**.
- **Driver Node**: `/sys/memx0/` (`verinfo`, `temperature`, `frequency`, `power`).
