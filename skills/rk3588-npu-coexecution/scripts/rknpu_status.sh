#!/usr/bin/env bash
# ProAI77 Rockchip RK3588 NPU Status & Load Probe Script
set -euo pipefail

echo "=========================================================="
echo "          ProAI77 RK3588 Built-In NPU Diagnostics         "
echo "=========================================================="

echo "--- 1. RKNPU Kernel Driver ---"
if [ -e "/dev/rknpu" ]; then
    echo "[PASS] /dev/rknpu device node exists."
else
    echo "[FAIL] /dev/rknpu device node missing!"
    exit 1
fi

if [ -f "/sys/kernel/debug/rknpu/version" ]; then
    echo "Driver Version: $(cat /sys/kernel/debug/rknpu/version)"
fi

echo ""
echo "--- 2. NPU Core Load & Frequency ---"
if [ -f "/sys/kernel/debug/rknpu/load" ]; then
    echo "NPU Load (Core 0 / 1 / 2):"
    cat /sys/kernel/debug/rknpu/load
fi

NPU_DEVFREQ="/sys/class/devfreq/fdab0000.npu"
if [ -d "$NPU_DEVFREQ" ]; then
    cur_khz=$(cat "$NPU_DEVFREQ/cur_freq" 2>/dev/null || echo "0")
    cur_gov=$(cat "$NPU_DEVFREQ/governor" 2>/dev/null || echo "unknown")
    echo "NPU Current Freq: $((cur_khz / 1000)) MHz | Governor: $cur_gov"
fi

echo ""
echo "--- 3. Installed RKNPU2 / RKLLM Libraries ---"
ldconfig -p 2>/dev/null | grep -E "rknn|rkllm" || echo "No rknn runtime libraries found in system linker cache."
dpkg -l | grep -E "rknn|rkllm" || true

echo ""
echo "NPU diagnostics complete."
