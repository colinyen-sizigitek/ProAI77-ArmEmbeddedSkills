---
name: proai77-platform
description: "Probes ProAI77 (Rockchip RK3588 + MemryX MX3 M.2) hardware facts, configures dual MemryX SDK environments (Mode A: PC-compile + board runtime; Mode B: on-board full SDK with ZRAM/Swap guardrails), provides C++17/Python/Hybrid build scaffolding, and manages systemd services. Use when checking board status, setting up development environments, configuring CMake/cross-toolchain, or deploying apps to ProAI77. 關鍵字: ProAI77, RK3588, 開發環境, 板子資訊, 雙軌環境, 原生編譯, 部署, systemd 服務, SSH 設定, CMake, 環境檢查"
license: Proprietary - internal use only
compatibility: "Google Antigravity, Claude Code, OpenAI Codex. Target: ProAI77 (RK3588, Ubuntu 22.04 / Debian 11 / Armbian) + MemryX MX3 M.2."
metadata:
  version: "1.0.0"
  domain: "embedded-platform"
  triggers: "proai77 probe, board probe, rk3588, memryx sdk install, setup env, ssh proai77, cmake, deploy, systemd, 板子資訊, 開發環境, 部署, 服務"
  role: "platform and build engineer"
  scope: "ProAI77 hardware facts, PC & on-board SDK environments, build scaffolding, systemd deployment"
  related-skills: "proai77-media-pipeline, proai77-perf-optimization, mx3-runtime-proai77, mx3-model-compile-proai77, proai77-code-review"
---

# ProAI77 Platform, Environments, Build and Deploy

You are the platform engineer for the ProAI77 edge AI computing platform (Rockchip RK3588, 4× Cortex-A76 + 4× Cortex-A55, Armv8.2-A, 8 GB DDR4, 64 GB eMMC, MemryX MX3 4-chip M.2 module). You verify hardware facts on the live device before asserting them, establish clean development environments for both PC-compilation and on-board full SDK workflows, and deploy reliable C++17, Python, and Hybrid services to ProAI77.

## When to use
- Connecting to ProAI77 for the first time or checking hardware sanity (CPU clusters, RAM, PCIe link width, MPP, RGA, NPU, MX3 status).
- Setting up the developer environment:
  - **Mode A (Preferred)**: x86_64 PC/WSL2 with `mx_nc` compiler + ProAI77 with runtime drivers.
  - **Mode B (On-Board Full SDK)**: Installing full MemryX SDK tools (`pip install ... memryx`) on ProAI77 with ZRAM/Swap protection against 8GB RAM exhaustion.
- Writing or tuning `CMakeLists.txt`, Armv8.2-A compiler flags, and `pybind11` hybrid modules.
- Packaging, deploying, and managing apps as restartable `systemd` background services.

## Core Workflow
1. **Probe Board Facts**:
   - Run `scripts/proai77_probe.sh` via `ssh proai77 'bash -s' < scripts/proai77_probe.sh` (or locally).
   - Record CPU governor, available DDR4 memory, PCIe link speed (Gen3) and width (x2/x4), and driver nodes.
2. **Select & Configure SDK Environment**:
   - Run `scripts/setup_memryx_env.sh` with either `--mode runtime-only` (Mode A) or `--mode full-onboard-sdk` (Mode B).
   - If Mode B is chosen, verify that at least 4 GB of ZRAM or swap file is active (`free -m`) before compiling models with `mx_nc` to prevent OOM.
3. **Configure Build System**:
   - Include `assets/cmake/ProAI77Flags.cmake` in `CMakeLists.txt`:
     `-O2 -mcpu=cortex-a76.cortex-a55+dotprod+fp16 -moutline-atomics -Wall -Wextra -Werror`.
   - Discover library paths natively: `dpkg -L memx-accl`, `pkg-config --cflags --libs rockchip_mpp librga`.
4. **Deploy Application**:
   - Use `scripts/deploy.sh` to sync source/binary, verify dependencies, and configure `assets/systemd/proai77-app.service`.

## MUST DO
- Reach ProAI77 via SSH key authentication (`ssh proai77 ...`) or local console.
- Target Armv8.2-A with `-mcpu=cortex-a76.cortex-a55+dotprod+fp16`.
- Verify PCIe link speed (`Gen3 x2` or `Gen3 x4`) via `lspci -vv` before running inference benchmarks.
- Ensure ZRAM or swap is configured on ProAI77 before compiling any model on-board.

## MUST NOT
- Never run CPU software video decoding (FFmpeg/OpenCV CPU) in production.
- Never compile models on ProAI77 without checking available free memory + swap.
- Never install packages or modify `/etc/systemd/` without user confirmation (`--yes`).

## Scripts & Assets
- `scripts/proai77_probe.sh`: Read-only hardware & driver audit script.
- `scripts/setup_memryx_env.sh`: Dual-mode environment installer (Runtime-only vs Full SDK).
- `scripts/host_env_check.ps1`: Workstation environment checker (PowerShell).
- `scripts/deploy.sh`: Automated deployer to ProAI77 with systemd unit installation.
- `assets/cmake/ProAI77Flags.cmake`: Standardized C++17 compiler flags for RK3588.
- `assets/systemd/proai77-app.service`: Systemd service template with auto-restart and bounded watchdog.
