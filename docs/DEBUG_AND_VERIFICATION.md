# ProAI77 Debugging and Verification Framework

A systematic guide and verification toolkit for developers deploying on the ProAI77 platform.

---

## 1. Multi-Stage Verification Pipeline

```
[ Stage 1: Build & Static Audit ]
  - Run python scripts/validate.py
  - Verify compiler flags: -mcpu=cortex-a76.cortex-a55+dotprod+fp16
  - Check vectorization logs: -fopt-info-vec-missed
          |
          v
[ Stage 2: Hardware & Driver Sanity Probe ]
  - bash scripts/proai77_probe.sh (CPU, DDR, PCIe link, MX3 driver, VPU, RGA, NPU)
  - bash scripts/mpp_rga_check.sh (MPP DMA-BUF compatibility, RGA driver version)
  - bash scripts/mx3_diag.sh (/sys/memx0/verinfo, temperatures, mxa-manager)
          |
          v
[ Stage 3: Runtime Performance & PMU Profiling ]
  - bash scripts/perf_rk3588.sh (PMUv3: CPI, Cache Misses, Branch Mispredictions)
  - bash scripts/ddr_bw_probe.sh (DDR4 bus load during concurrent MPP + MX3 + RKNPU)
  - Arm Streamline / Gator profiling (optional system-wide trace)
          |
          v
[ Stage 4: Soak & Power Stability Burn-In ]
  - bash scripts/mx3_stability_power_test.sh (10-minute continuous power <= 9000 mW check)
  - bash scripts/soak_test.sh (Multi-stream FPS, latency p50/p99, frame drops)
```

---

## 2. Hardware Sanity Probe (`proai77_probe.sh`)
Run on the ProAI77 board:
```bash
bash scripts/proai77_probe.sh
```
Checks:
- **CPU**: Cluster topology (4× A55 `cpu0-3`, 4× A76 `cpu4-7`), CPU frequency scaling governors (`scaling_cur_freq`).
- **RAM**: Available DDR4 capacity and swap/zram status (at least 8 GB total).
- **PCIe**: MemryX MX3 M.2 link status (`lspci -vv -s <bdf>`, verifying link speed Gen3 and width x2/x4).
- **Driver Nodes**:
  - MemryX: `/sys/memx0/verinfo`, `/dev/memx*`
  - Rockchip MPP: `/dev/mpp_service`, `/proc/mpp_service`
  - Rockchip RGA: `/dev/rga`, `/sys/kernel/debug/rkrga/driver_version`
  - Rockchip NPU: `/sys/kernel/debug/rknpu/version`, `/dev/rknpu`

---

## 3. Power Compliance & Thermal Burn-In (`mx3_stability_power_test.sh`)
To verify that a selected model and frequency comply with the **M.2 ≤ 9000 mW** rule:
```bash
bash skills/mx3-runtime-proai77/scripts/mx3_stability_power_test.sh \
    --dfp ~/models/yolo26n_c4.dfp \
    --freq 400 \
    --minutes 10 \
    --output stability_log.csv
```
The test continuously queries `get_power()` and chip temperatures at 1 Hz:
- **PASS**: Power stays ≤ 9000 mW for 10 minutes, temperature ≤ 80°C, zero runtime errors.
- **FAIL**: Power exceeds 9000 mW or temperature exceeds 85°C. The test automatically steps down frequency to 300 MHz and logs the fault.

---

## 4. Hardware PMU Profiling with `perf` (`perf_rk3588.sh`)
Profiles the big (A76) vs little (A55) cores using ARM PMUv3 counters:
```bash
bash skills/proai77-perf-optimization/scripts/perf_rk3588.sh --pid $(pgrep vision_app) --duration 10
```
Outputs:
- **Cycles Per Instruction (CPI)** and Instructions Per Cycle (IPC)
- **L1 Data Cache Miss Rate** (MPKI)
- **L2 Cache Misses** & DynamIQ interconnect transactions
- **Branch Misprediction Rate**
